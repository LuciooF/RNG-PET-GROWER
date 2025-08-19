-- CustomLeaderboardService - Server-side custom leaderboard tracking with fixes
-- - Uses FULL in-memory cache, only slices data when sending to clients
-- - Consistent identity (userId everywhere)
-- - UpdateAsync for safer writes with CROSS-SERVER MERGE (no more wipes)
-- - Real immediate updates for joins/leaves (force flag bypass)
-- - Weekly period uses configurable reset day/hour
-- - Load-before-write guarantees (per-key), dirty-key tracking to reduce churn

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

-- Services / utils
local DataService = require(script.Parent.DataService)
local AuthorizationUtils = require(ReplicatedStorage.utils.AuthorizationUtils)

local CustomLeaderboardService = {}
CustomLeaderboardService.__index = CustomLeaderboardService

-- DataStore
local LEADERBOARD_DATASTORE = DataStoreService:GetDataStore("CustomLeaderboardData")

-- Leaderboard config
local LEADERBOARD_TYPES = {
	MONEY = "Money",
	DIAMONDS = "Diamonds",
	REBIRTHS = "Rebirths",
	TIME_PLAYED = "TimePlayed",
	ROBUX_SPENT = "RobuxSpent",
}

local LEADERBOARD_PERIODS = {
	ALL_TIME = "AllTime",
	WEEKLY = "Weekly",
}

-- Performance / retention
local UPDATE_INTERVAL = 120 -- seconds
local MAX_LEADERBOARD_SIZE = 100 -- keep top N in persistent storage
local WEEKLY_RESET_DAY = 1      -- 1=Sunday, 2=Monday, ... 7=Saturday
local WEEKLY_RESET_HOUR = 12    -- 24h clock (server time)

-- Slim cache (top 20 + requesting player snapshot)
local leaderboardCache = {
	[LEADERBOARD_PERIODS.ALL_TIME] = {
		[LEADERBOARD_TYPES.MONEY] = {},
		[LEADERBOARD_TYPES.DIAMONDS] = {},
		[LEADERBOARD_TYPES.REBIRTHS] = {},
		[LEADERBOARD_TYPES.TIME_PLAYED] = {},
		[LEADERBOARD_TYPES.ROBUX_SPENT] = {},
	},
	[LEADERBOARD_PERIODS.WEEKLY] = {
		[LEADERBOARD_TYPES.MONEY] = {},
		[LEADERBOARD_TYPES.DIAMONDS] = {},
		[LEADERBOARD_TYPES.REBIRTHS] = {},
		[LEADERBOARD_TYPES.TIME_PLAYED] = {},
		[LEADERBOARD_TYPES.ROBUX_SPENT] = {},
	},
}

-- FULL cache (the authoritative list we persist)
local leaderboardFullCache = {
	[LEADERBOARD_PERIODS.ALL_TIME] = {
		[LEADERBOARD_TYPES.MONEY] = {},
		[LEADERBOARD_TYPES.DIAMONDS] = {},
		[LEADERBOARD_TYPES.REBIRTHS] = {},
		[LEADERBOARD_TYPES.TIME_PLAYED] = {},
		[LEADERBOARD_TYPES.ROBUX_SPENT] = {},
	},
	[LEADERBOARD_PERIODS.WEEKLY] = {
		[LEADERBOARD_TYPES.MONEY] = {},
		[LEADERBOARD_TYPES.DIAMONDS] = {},
		[LEADERBOARD_TYPES.REBIRTHS] = {},
		[LEADERBOARD_TYPES.TIME_PLAYED] = {},
		[LEADERBOARD_TYPES.ROBUX_SPENT] = {},
	},
}

-- Pending updates and timing
local playersToUpdate: {[number]: {player: Player, timestamp: number}} = {}
local lastUpdateTime = 0

-- Per-key load tracking: guarantees we always load from DS before saving
local loadedKeys: {[string]: boolean} = {}

-- Dirty-key tracking: only write keys that actually changed
local dirtyKeys: {[string]: boolean} = {}

-- ========= Time helpers =========

local function getLastWeeklyResetEpoch(now: number?): number
	now = now or os.time()
	local t = os.date("*t", now) -- t.wday: 1=Sunday .. 7=Saturday
	-- seconds since midnight
	local secondsToday = t.hour * 3600 + t.min * 60 + t.sec
	-- how many days we need to go back to the reset day
	local daysBack = (t.wday - WEEKLY_RESET_DAY) % 7
	-- reset time today (at reset hour)
	local resetToday = now - secondsToday + (WEEKLY_RESET_HOUR * 3600)
	-- go back daysBack days to the reset weekday
	local resetThisWeek = resetToday - (daysBack * 86400)
	-- if we're before today's reset moment, subtract a week
	if now < resetThisWeek then
		resetThisWeek -= 7 * 86400
	end
	return resetThisWeek
end

local function getCurrentWeekId(): number
	-- Use day count since epoch at the weekly reset boundary
	local resetEpoch = getLastWeeklyResetEpoch()
	return math.floor(resetEpoch / 86400)
end

-- ========= DataStore helpers =========

local function safeDataStoreGet(key: string, defaultValue)
	local success, result = pcall(function()
		return LEADERBOARD_DATASTORE:GetAsync(key)
	end)
	if success and result ~= nil then
		return result
	else
		if not success then
			warn("CustomLeaderboardService: GetAsync failed for key", key, "Error:", result)
		end
		return defaultValue or {}
	end
end

local function safeDataStoreUpdate(key: string, transform: (oldValue: any) -> any): boolean
	local success, err = pcall(function()
		LEADERBOARD_DATASTORE:UpdateAsync(key, function(old)
			old = old or {}
			return transform(old)
		end)
	end)
	if not success then
		warn("CustomLeaderboardService: UpdateAsync failed for key", key, "Error:", err)
		return false
	end
	return true
end

-- ========= Key helpers =========

local function makeKey(period: string, leaderboardType: string): string
	local weekId = (period == LEADERBOARD_PERIODS.WEEKLY) and getCurrentWeekId() or nil
	return period .. "_" .. leaderboardType .. (weekId and ("_" .. weekId) or "")
end

local function ensureTables(period: string, leaderboardType: string)
	if not leaderboardFullCache[period] then leaderboardFullCache[period] = {} end
	if not leaderboardFullCache[period][leaderboardType] then leaderboardFullCache[period][leaderboardType] = {} end
	if not leaderboardCache[period] then leaderboardCache[period] = {} end
	if not leaderboardCache[period][leaderboardType] then leaderboardCache[period][leaderboardType] = {} end
end

-- Ensure we have loaded the full list for a given key before any mutation/save
local function ensureLoaded(period: string, leaderboardType: string, targetPlayer: Player?)
	ensureTables(period, leaderboardType)
	local key = makeKey(period, leaderboardType)
	if not loadedKeys[key] then
		CustomLeaderboardService:LoadLeaderboardData(period, leaderboardType, targetPlayer)
		loadedKeys[key] = true
	end
end

-- ========= Value accessor =========

function CustomLeaderboardService:GetPlayerValue(player: Player?, leaderboardType: string): number
	if not player or not player.Parent then
		return 0
	end
	local playerData = DataService:GetPlayerData(player)
	if not playerData then
		-- Only warn for players that are actually still in-game
		if player.Parent then
			warn("CustomLeaderboardService: No player data for", player.Name)
		end
		return 0
	end

	if leaderboardType == LEADERBOARD_TYPES.MONEY then
		return (playerData.Resources and playerData.Resources.Money) or 0
	elseif leaderboardType == LEADERBOARD_TYPES.DIAMONDS then
		return (playerData.Resources and playerData.Resources.Diamonds) or 0
	elseif leaderboardType == LEADERBOARD_TYPES.REBIRTHS then
		return (playerData.Resources and playerData.Resources.Rebirths) or 0
	elseif leaderboardType == LEADERBOARD_TYPES.TIME_PLAYED then
		-- Get playtime in seconds (convert minutes to seconds for consistency)
		local playtimeMinutes = playerData.PlaytimeMinutes or 0
		return math.floor(playtimeMinutes * 60) -- Convert to seconds and round down
	elseif leaderboardType == LEADERBOARD_TYPES.ROBUX_SPENT then
		-- Get total robux spent by player
		return (playerData.Resources and playerData.Resources.RobuxSpent) or 0
	end
	return 0
end

-- ========= Load / Save =========

-- Load FULL list, then build a slim cache (top 20 + requesting player)
function CustomLeaderboardService:LoadLeaderboardData(period: string, leaderboardType: string, targetPlayer: Player?)
	ensureTables(period, leaderboardType)
	local key = makeKey(period, leaderboardType)

	local fullData = safeDataStoreGet(key, {})

	-- Normalize legacy key (playerId -> userId)
	for _, e in ipairs(fullData) do
		if e.playerId and not e.userId then
			e.userId = e.playerId
			e.playerId = nil
		end
		-- normalize numeric
		if e.value ~= nil then
			e.value = tonumber(e.value) or 0
		end
	end

	table.sort(fullData, function(a, b)
		return (a.value or 0) > (b.value or 0)
	end)

	leaderboardFullCache[period][leaderboardType] = fullData

	-- Build slim view
	local result = {}
	local playerRank: number? = nil
	local targetUserId = targetPlayer and targetPlayer.UserId or nil

	for i = 1, math.min(20, #fullData) do
		local e = fullData[i]
		result[i] = { rank = i, userId = e.userId, playerName = e.playerName, value = e.value }
		if targetUserId and e.userId == targetUserId then
			playerRank = i
		end
	end

	if targetUserId and not playerRank then
		for i = 21, #fullData do
			local e = fullData[i]
			if e.userId == targetUserId then
				table.insert(result, { rank = i, userId = e.userId, playerName = e.playerName, value = e.value })
				playerRank = i
				break
			end
		end
	end

	leaderboardCache[period][leaderboardType] = result
	return result, playerRank
end

-- Merge-saving: merges cache with DS contents by userId, sorts, trims, mirrors back to cache
function CustomLeaderboardService:SaveLeaderboardData(period: string, leaderboardType: string): boolean
	ensureTables(period, leaderboardType)
	ensureLoaded(period, leaderboardType)

	local key = makeKey(period, leaderboardType)
	local full = leaderboardFullCache[period][leaderboardType] or {}

	-- Local cap (server-side retention)
	while #full > MAX_LEADERBOARD_SIZE do
		table.remove(full)
	end

	return safeDataStoreUpdate(key, function(old)
		old = old or {}

		-- Map existing DS entries
		local byId = {}

		for _, e in ipairs(old) do
			if e.userId then
				byId[e.userId] = {
					userId = e.userId,
					playerName = e.playerName,
					value = tonumber(e.value) or 0,
					lastUpdate = e.lastUpdate or 0,
				}
			end
		end

		-- Merge current cache: prefer higher value; update name/timestamp if improved
		for _, e in ipairs(full) do
			if e.userId then
				local prev = byId[e.userId]
				local newValue = tonumber(e.value) or 0
				if not prev then
					byId[e.userId] = {
						userId = e.userId,
						playerName = e.playerName,
						value = newValue,
						lastUpdate = e.lastUpdate or os.time(),
					}
				else
					-- If values can only increase, keep max. If they can decrease, consider using lastUpdate newest.
					if newValue > (tonumber(prev.value) or 0) then
						prev.value = newValue
						prev.playerName = e.playerName or prev.playerName
						prev.lastUpdate = e.lastUpdate or os.time()
					end
				end
			end
		end

		-- Flatten, sort desc, cap
		local merged = {}
		for _, v in pairs(byId) do
			table.insert(merged, v)
		end

		table.sort(merged, function(a, b)
			return (a.value or 0) > (b.value or 0)
		end)

		while #merged > MAX_LEADERBOARD_SIZE do
			table.remove(merged)
		end

		-- Reflect back into this server's full cache so future reads are consistent
		leaderboardFullCache[period][leaderboardType] = merged

		return merged
	end)
end

-- ========= Mutation =========

function CustomLeaderboardService:UpdatePlayerInLeaderboard(player: Player, period: string, leaderboardType: string)
	ensureTables(period, leaderboardType)
	ensureLoaded(period, leaderboardType, player)

	local value = self:GetPlayerValue(player, leaderboardType)
	local full = leaderboardFullCache[period][leaderboardType]

	-- Remove existing entry
	for i = #full, 1, -1 do
		if full[i].userId == player.UserId then
			table.remove(full, i)
			break
		end
	end

	-- Insert in sorted position (desc)
	local inserted = false
	for i, e in ipairs(full) do
		if value > (e.value or 0) then
			table.insert(full, i, {
				userId = player.UserId,
				playerName = player.Name,
				value = value,
				lastUpdate = os.time(),
			})
			inserted = true
			break
		end
	end
	if not inserted then
		table.insert(full, {
			userId = player.UserId,
			playerName = player.Name,
			value = value,
			lastUpdate = os.time(),
		})
	end

	-- Trim full list
	while #full > MAX_LEADERBOARD_SIZE do
		table.remove(full)
	end

	-- Refresh slim cache top 20 (optional convenience)
	local slim = {}
	for i = 1, math.min(20, #full) do
		local e = full[i]
		slim[i] = { rank = i, userId = e.userId, playerName = e.playerName, value = e.value }
	end
	leaderboardCache[period][leaderboardType] = slim

	-- Mark dirty for persistence
	dirtyKeys[makeKey(period, leaderboardType)] = true
end

-- ========= Batch update / scheduling =========

function CustomLeaderboardService:MarkPlayerForUpdate(player: Player)
	playersToUpdate[player.UserId] = {
		player = player,
		timestamp = os.clock(),
	}
end

function CustomLeaderboardService:ProcessPendingUpdates(force: boolean?)
	local now = os.clock()
	if not force and (now - lastUpdateTime < UPDATE_INTERVAL) then
		return
	end
	lastUpdateTime = now

	-- Process all pending players
	for _userId, updateData in pairs(playersToUpdate) do
		local player = updateData.player
		if player and player.Parent then
			for _, period in pairs(LEADERBOARD_PERIODS) do
				for _, leaderboardType in pairs(LEADERBOARD_TYPES) do
					ensureLoaded(period, leaderboardType, player)
					self:UpdatePlayerInLeaderboard(player, period, leaderboardType)
				end
			end
		end
	end
	playersToUpdate = {}

	-- Persist only dirty lists
	for _, period in pairs(LEADERBOARD_PERIODS) do
		for _, leaderboardType in pairs(LEADERBOARD_TYPES) do
			local key = makeKey(period, leaderboardType)
			if dirtyKeys[key] then
				ensureLoaded(period, leaderboardType)
				self:SaveLeaderboardData(period, leaderboardType)
				dirtyKeys[key] = nil
			end
		end
	end
end

-- ========= Weekly reset =========

function CustomLeaderboardService:CheckWeeklyReset()
	local currentWeekId = getCurrentWeekId()
	local storedWeekId = safeDataStoreGet("CurrentWeekId", 0)

	if currentWeekId ~= storedWeekId then
		print(("CustomLeaderboardService: Weekly reset → %d (was %d)"):format(currentWeekId, storedWeekId))

		-- Clear weekly full & slim caches
		for _, leaderboardType in pairs(LEADERBOARD_TYPES) do
			leaderboardFullCache[LEADERBOARD_PERIODS.WEEKLY][leaderboardType] = {}
			leaderboardCache[LEADERBOARD_PERIODS.WEEKLY][leaderboardType] = {}
			loadedKeys[makeKey(LEADERBOARD_PERIODS.WEEKLY, leaderboardType)] = true -- prevent immediate reload of old week
			self:SaveLeaderboardData(LEADERBOARD_PERIODS.WEEKLY, leaderboardType)
			-- nothing to mark dirty; we intentionally wrote reset
		end

		safeDataStoreUpdate("CurrentWeekId", function(_old)
			return currentWeekId
		end)

		print("CustomLeaderboardService: Weekly leaderboards reset completed")
	end
end

-- ========= Public API =========

-- SMART LOADING for client
function CustomLeaderboardService:GetLeaderboard(period: string, leaderboardType: string, maxEntries: number?, requestingPlayer: Player?)
	maxEntries = maxEntries or 50

	-- Map friendly names if needed (kept identical)
	local serverPeriod = period
	if period == "All-Time" then serverPeriod = LEADERBOARD_PERIODS.ALL_TIME end
	if period == "Weekly"   then serverPeriod = LEADERBOARD_PERIODS.WEEKLY   end

	local serverType = leaderboardType
	if leaderboardType == "Money"      then serverType = LEADERBOARD_TYPES.MONEY      end
	if leaderboardType == "Diamonds"   then serverType = LEADERBOARD_TYPES.DIAMONDS   end
	if leaderboardType == "Rebirths"   then serverType = LEADERBOARD_TYPES.REBIRTHS   end
	if leaderboardType == "TimePlayed" then serverType = LEADERBOARD_TYPES.TIME_PLAYED end
	if leaderboardType == "RobuxSpent" then serverType = LEADERBOARD_TYPES.ROBUX_SPENT end

	ensureTables(serverPeriod, serverType)

	-- Load full list once if empty
	if (#leaderboardFullCache[serverPeriod][serverType] == 0) then
		self:LoadLeaderboardData(serverPeriod, serverType, requestingPlayer)
		loadedKeys[makeKey(serverPeriod, serverType)] = true
	end

	local full = leaderboardFullCache[serverPeriod][serverType]
	local result = {}
	for i = 1, math.min(maxEntries, #full) do
		local e = full[i]
		result[i] = { rank = i, userId = e.userId, playerName = e.playerName, value = e.value }
	end
	return result
end

function CustomLeaderboardService:GetPlayerRank(player: Player, period: string, leaderboardType: string): number?
	ensureTables(period, leaderboardType)
	local full = leaderboardFullCache[period][leaderboardType] or {}
	for i, e in ipairs(full) do
		if e.userId == player.UserId then
			return i
		end
	end
	return nil
end

function CustomLeaderboardService:NotifyPlayerDataChanged(player: Player)
	self:MarkPlayerForUpdate(player)
end

-- Manual refresh for testing/debugging (authorized)
function CustomLeaderboardService:ForceRefresh(requestingPlayer: Player?)
	if requestingPlayer and not AuthorizationUtils.isAuthorized(requestingPlayer) then
		AuthorizationUtils.logUnauthorizedAccess(requestingPlayer, "force leaderboard refresh")
		return false
	end

	print("CustomLeaderboardService: Force refresh requested by", requestingPlayer and requestingPlayer.Name or "SERVER")

	for _, p in ipairs(Players:GetPlayers()) do
		self:MarkPlayerForUpdate(p)
	end
	self:ProcessPendingUpdates(true)

	print("CustomLeaderboardService: Force refresh completed")
	return true
end

-- ========= Initialize =========

function CustomLeaderboardService:Initialize()
	-- Weekly reset check
	self:CheckWeeklyReset()

	-- Throttled processing on Heartbeat; separate force path for joins/leaves
	RunService.Heartbeat:Connect(function()
		self:ProcessPendingUpdates(false)
	end)

	Players.PlayerAdded:Connect(function(player)
		-- Give your data layer a moment to populate
		task.wait(5)
		self:MarkPlayerForUpdate(player)
		-- Force an immediate write so new players appear right away (safe: we load first)
		self:ProcessPendingUpdates(true)
	end)

	Players.PlayerRemoving:Connect(function(player)
		-- Final snapshot for the player
		self:MarkPlayerForUpdate(player)
		task.spawn(function()
			-- small delay to let DataService save, if applicable
			task.wait(1)
			for _, period in pairs(LEADERBOARD_PERIODS) do
				for _, leaderboardType in pairs(LEADERBOARD_TYPES) do
					ensureLoaded(period, leaderboardType, player)
					self:UpdatePlayerInLeaderboard(player, period, leaderboardType)
					self:SaveLeaderboardData(period, leaderboardType)
					-- no need to dirty here; we just saved
				end
			end
		end)
	end)

	-- Hourly weekly reset check
	task.spawn(function()
		while true do
			task.wait(3600)
			self:CheckWeeklyReset()
		end
	end)
end

return CustomLeaderboardService
