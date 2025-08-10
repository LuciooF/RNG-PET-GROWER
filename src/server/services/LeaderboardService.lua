-- LeaderboardService - Manages Roblox integrated leaderstats (online players).
-- Note: leaderstats only exist for players in the current server. For offline/global
-- leaderboards, use an OrderedDataStore and a custom UI.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)

local LeaderboardService = {}

-- Idempotent: create the folder/values if they don't exist yet.
function LeaderboardService:CreateLeaderstats(player: Player)
	if not player or not player.Parent then return end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local rebirths = leaderstats:FindFirstChild("Rebirths")
	if not rebirths then
		rebirths = Instance.new("IntValue")
		rebirths.Name = "Rebirths" -- primary sort in player list
		rebirths.Value = 0
		rebirths.Parent = leaderstats
	end

	local diamonds = leaderstats:FindFirstChild("Diamonds")
	if not diamonds then
		diamonds = Instance.new("StringValue") -- string so we can format (e.g., 1.2K)
		diamonds.Name = "Diamonds"
		diamonds.Value = "0"
		diamonds.Parent = leaderstats
	end

	local money = leaderstats:FindFirstChild("Money")
	if not money then
		money = Instance.new("StringValue") -- display only
		money.Name = "Money"
		money.Value = "0"
		money.Parent = leaderstats
	end

	return leaderstats, rebirths, diamonds, money
end

-- Safe formatter (prevents errors if formatter expects a number)
local function safeFormat(n)
	if typeof(n) == "number" then
		local ok, formatted = pcall(NumberFormatter.format, n)
		return ok and formatted or tostring(n)
	end
	return tostring(n or 0)
end

function LeaderboardService:UpdateLeaderstats(player: Player, playerData)
	if not player or not player.Parent or not playerData then return end

	-- Ensure leaderstats exist (handles odd timing/reloads)
	local leaderstats, rebirthsStat, diamondsStat, moneyStat = self:CreateLeaderstats(player)
	if not leaderstats then return end

	-- Rebirths (numeric for sorting)
	if rebirthsStat and playerData.Resources and typeof(playerData.Resources.Rebirths) == "number" then
		rebirthsStat.Value = playerData.Resources.Rebirths
	end

	-- Diamonds & Money are strings for display (formatted)
	if diamondsStat and playerData.Resources and playerData.Resources.Diamonds ~= nil then
		diamondsStat.Value = safeFormat(playerData.Resources.Diamonds)
	end
	if moneyStat and playerData.Resources and playerData.Resources.Money ~= nil then
		moneyStat.Value = safeFormat(playerData.Resources.Money)
	end
end

function LeaderboardService:OnPlayerAdded(player: Player)
	-- Create immediately; values will get populated when your data arrives
	self:CreateLeaderstats(player)
end

function LeaderboardService:OnPlayerRemoving(_player: Player)
	-- Nothing required; Roblox cleans up leaderstats automatically with the Player instance
end

function LeaderboardService:Initialize()
	Players.PlayerAdded:Connect(function(p) self:OnPlayerAdded(p) end)
	Players.PlayerRemoving:Connect(function(p) self:OnPlayerRemoving(p) end)

	-- Handle players already present (e.g., script re-run)
	for _, p in ipairs(Players:GetPlayers()) do
		self:CreateLeaderstats(p)
	end
end

-- Accepts either:
--   1) map<Player, playerData>
--   2) map<userId (number), playerData>
function LeaderboardService:UpdateAllLeaderstats(playerDataMap: table)
	for key, playerData in pairs(playerDataMap) do
		local player: Player? = nil

		if typeof(key) == "Instance" and key:IsA("Player") then
			player = key
		elseif typeof(key) == "number" then
			player = Players:GetPlayerByUserId(key)
		end

		if player and player.Parent then
			self:UpdateLeaderstats(player, playerData)
		end
	end
end

-- Debug helper: builds a snapshot of online players’ leaderstats
function LeaderboardService:GetLeaderboardData()
	local snapshot = {}

	for _, player in ipairs(Players:GetPlayers()) do
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local rebirths = leaderstats:FindFirstChild("Rebirths")
			local money = leaderstats:FindFirstChild("Money")
			table.insert(snapshot, {
				playerName = player.Name,
				rebirths = (rebirths and rebirths.Value) or 0,
				money = (money and money.Value) or "0",
			})
		end
	end

	table.sort(snapshot, function(a, b)
		return a.rebirths > b.rebirths
	end)

	return snapshot
end

-- Manual refresh: pull current data and push to leaderstats (online players)
function LeaderboardService:RefreshLeaderboard()
	print("LeaderboardService: Manual refresh requested")
	-- Require once (require caches anyway)
	local DataService = require(script.Parent.DataService)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			local ok, playerData = pcall(DataService.GetPlayerData, DataService, player)
			if ok and playerData then
				self:UpdateLeaderstats(player, playerData)
			end
		end)
	end
end

function LeaderboardService:FormatMoney(amount)
	return safeFormat(amount)
end

return LeaderboardService
