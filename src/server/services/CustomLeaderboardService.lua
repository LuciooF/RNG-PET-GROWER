-- CustomLeaderboardService - Server-side custom leaderboard tracking with performance optimization
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

-- Get DataService for player data access
local DataService = require(script.Parent.DataService)

local CustomLeaderboardService = {}
CustomLeaderboardService.__index = CustomLeaderboardService

-- DataStore configuration
local LEADERBOARD_DATASTORE = DataStoreService:GetDataStore("CustomLeaderboardData")

-- Leaderboard configuration
local LEADERBOARD_TYPES = {
    MONEY = "Money",
    DIAMONDS = "Diamonds", 
    REBIRTHS = "Rebirths"
}

local LEADERBOARD_PERIODS = {
    ALL_TIME = "AllTime",
    WEEKLY = "Weekly"
}

-- Performance settings
local UPDATE_INTERVAL = 120 -- Update leaderboards every 2 minutes (120 seconds)
local MAX_LEADERBOARD_SIZE = 100 -- Store top 100 players
local WEEKLY_RESET_DAY = 1 -- Sunday (1 = Sunday, 2 = Monday, etc.)
local WEEKLY_RESET_HOUR = 12 -- 12 PM

-- Cache for leaderboard data to reduce DataStore calls
local leaderboardCache = {
    [LEADERBOARD_PERIODS.ALL_TIME] = {
        [LEADERBOARD_TYPES.MONEY] = {},
        [LEADERBOARD_TYPES.DIAMONDS] = {},
        [LEADERBOARD_TYPES.REBIRTHS] = {}
    },
    [LEADERBOARD_PERIODS.WEEKLY] = {
        [LEADERBOARD_TYPES.MONEY] = {},
        [LEADERBOARD_TYPES.DIAMONDS] = {},
        [LEADERBOARD_TYPES.REBIRTHS] = {}
    }
}

-- Track players that need leaderboard updates
local playersToUpdate = {}
local lastUpdateTime = 0

-- Get current week identifier for weekly reset
local function getCurrentWeekId()
    local currentTime = os.time()
    local currentDate = os.date("*t", currentTime)
    
    -- Calculate days since epoch Sunday
    local daysSinceEpoch = math.floor(currentTime / 86400) -- 86400 seconds in a day
    local daysSinceSunday = (daysSinceEpoch + 4) % 7 -- Epoch was Thursday, so +4 to get Sunday = 0
    
    -- Calculate the start of current week (Sunday at WEEKLY_RESET_HOUR)
    local startOfWeek = currentTime - (daysSinceSunday * 86400) - (currentDate.hour * 3600) - (currentDate.min * 60) - currentDate.sec + (WEEKLY_RESET_HOUR * 3600)
    
    -- If we're before the reset time this week, use previous week
    if currentTime < startOfWeek then
        startOfWeek = startOfWeek - (7 * 86400) -- Go back one week
    end
    
    return math.floor(startOfWeek / 86400) -- Return week ID as days since epoch
end

-- Safe DataStore operations with error handling
local function safeDataStoreGet(key, defaultValue)
    local success, result = pcall(function()
        return LEADERBOARD_DATASTORE:GetAsync(key)
    end)
    
    if success and result then
        return result
    else
        if not success then
            warn("CustomLeaderboardService: Failed to get data for key", key, "Error:", result)
        end
        return defaultValue or {}
    end
end

local function safeDataStoreSet(key, value)
    local success, error = pcall(function()
        LEADERBOARD_DATASTORE:SetAsync(key, value)
    end)
    
    if not success then
        warn("CustomLeaderboardService: Failed to set data for key", key, "Error:", error)
        return false
    end
    
    return true
end

-- Load ONLY top entries + current player position (SMART LOADING)
function CustomLeaderboardService:LoadLeaderboardData(period, leaderboardType, targetPlayer)
    local weekId = period == LEADERBOARD_PERIODS.WEEKLY and getCurrentWeekId() or nil
    local key = period .. "_" .. leaderboardType .. (weekId and ("_" .. weekId) or "")
    
    -- Get full data (we still need it for now, but we'll optimize this later)
    local fullData = safeDataStoreGet(key, {})
    
    -- Sort to get accurate rankings
    table.sort(fullData, function(a, b)
        return a.value > b.value
    end)
    
    -- Build optimized result: Top 20 + Current Player
    local result = {}
    local playerFound = false
    local playerRank = nil
    local targetUserId = targetPlayer and targetPlayer.UserId
    
    -- Add top 20
    for i = 1, math.min(20, #fullData) do
        local entry = fullData[i]
        entry.rank = i -- Add rank info
        table.insert(result, entry)
        
        -- Check if current player is in top 20
        if targetUserId and entry.userId == targetUserId then
            playerFound = true
            playerRank = i
        end
    end
    
    -- If player not in top 20, find their position and add them
    if targetUserId and not playerFound then
        for i = 21, #fullData do
            if fullData[i].userId == targetUserId then
                local playerEntry = fullData[i]
                playerEntry.rank = i
                table.insert(result, playerEntry)
                playerRank = i
                break
            end
        end
    end
    
    -- Cache the optimized result
    leaderboardCache[period][leaderboardType] = result
    
    return result, playerRank
end

-- Save leaderboard data to DataStore
function CustomLeaderboardService:SaveLeaderboardData(period, leaderboardType)
    local weekId = period == LEADERBOARD_PERIODS.WEEKLY and getCurrentWeekId() or nil
    local key = period .. "_" .. leaderboardType .. (weekId and ("_" .. weekId) or "")
    
    local data = leaderboardCache[period][leaderboardType]
    return safeDataStoreSet(key, data)
end

-- Get player's current value for leaderboard type
function CustomLeaderboardService:GetPlayerValue(player, leaderboardType)
    -- Check if player is still in game before trying to get data
    if not player or not player.Parent then
        return 0 -- Player has left, return 0 silently
    end
    
    local playerData = DataService:GetPlayerData(player)
    if not playerData or not playerData.Resources then
        -- Only warn if player is still in game (avoid spam when players leave)
        if player.Parent then
            warn("CustomLeaderboardService: No player data found for", player.Name)
        end
        return 0
    end
    
    if leaderboardType == LEADERBOARD_TYPES.MONEY then
        return playerData.Resources.Money or 0
    elseif leaderboardType == LEADERBOARD_TYPES.DIAMONDS then  
        return playerData.Resources.Diamonds or 0
    elseif leaderboardType == LEADERBOARD_TYPES.REBIRTHS then
        return playerData.Resources.Rebirths or 0
    end
    
    return 0
end

-- Update player's position in leaderboard
function CustomLeaderboardService:UpdatePlayerInLeaderboard(player, period, leaderboardType)
    local playerValue = self:GetPlayerValue(player, leaderboardType)
    local leaderboard = leaderboardCache[period][leaderboardType]
    
    -- Remove existing entry for this player
    for i = #leaderboard, 1, -1 do
        if leaderboard[i].playerId == player.UserId then
            table.remove(leaderboard, i)
            break
        end
    end
    
    -- Add new entry
    local newEntry = {
        playerId = player.UserId,
        playerName = player.Name,
        value = playerValue,
        lastUpdate = os.time()
    }
    
    -- Insert in correct position (sorted by value descending)
    local inserted = false
    for i, entry in ipairs(leaderboard) do
        if playerValue > entry.value then
            table.insert(leaderboard, i, newEntry)
            inserted = true
            break
        end
    end
    
    -- If not inserted, add to end
    if not inserted then
        table.insert(leaderboard, newEntry)
    end
    
    -- Trim to max size
    while #leaderboard > MAX_LEADERBOARD_SIZE do
        table.remove(leaderboard, #leaderboard)
    end
end

-- Mark player for leaderboard update (performance optimization)
function CustomLeaderboardService:MarkPlayerForUpdate(player)
    playersToUpdate[player.UserId] = {
        player = player,
        timestamp = tick()
    }
end

-- Process pending player updates (called periodically)
function CustomLeaderboardService:ProcessPendingUpdates()
    local currentTime = tick()
    
    -- Only process if enough time has passed
    if currentTime - lastUpdateTime < UPDATE_INTERVAL then
        return
    end
    
    lastUpdateTime = currentTime
    
    -- Process all pending updates
    for playerId, updateData in pairs(playersToUpdate) do
        local player = updateData.player
        if player and player.Parent then -- Player still in game
            -- Update all leaderboards for this player
            for _, period in pairs(LEADERBOARD_PERIODS) do
                for _, leaderboardType in pairs(LEADERBOARD_TYPES) do
                    self:UpdatePlayerInLeaderboard(player, period, leaderboardType)
                end
            end
            
            print("CustomLeaderboardService: Updated leaderboards for", player.Name)
        end
    end
    
    -- Clear processed updates
    playersToUpdate = {}
    
    -- Save updated data to DataStore
    for _, period in pairs(LEADERBOARD_PERIODS) do
        for _, leaderboardType in pairs(LEADERBOARD_TYPES) do
            self:SaveLeaderboardData(period, leaderboardType)
        end
    end
end

-- Check and handle weekly reset
function CustomLeaderboardService:CheckWeeklyReset()
    local currentWeekId = getCurrentWeekId()
    local storedWeekId = safeDataStoreGet("CurrentWeekId", 0)
    
    if currentWeekId ~= storedWeekId then
        print("CustomLeaderboardService: Weekly reset detected! New week:", currentWeekId)
        
        -- Clear weekly leaderboards
        for _, leaderboardType in pairs(LEADERBOARD_TYPES) do
            leaderboardCache[LEADERBOARD_PERIODS.WEEKLY][leaderboardType] = {}
            self:SaveLeaderboardData(LEADERBOARD_PERIODS.WEEKLY, leaderboardType)
        end
        
        -- Update stored week ID
        safeDataStoreSet("CurrentWeekId", currentWeekId)
        
        print("CustomLeaderboardService: Weekly leaderboards reset completed")
    end
end

-- Get leaderboard data for client (SMART LOADING)
function CustomLeaderboardService:GetLeaderboard(period, leaderboardType, maxEntries, requestingPlayer)
    maxEntries = maxEntries or 50 -- Default to top 50
    
    -- Map client period names to server period names
    local serverPeriod = period
    if period == "All-Time" then
        serverPeriod = LEADERBOARD_PERIODS.ALL_TIME
    elseif period == "Weekly" then
        serverPeriod = LEADERBOARD_PERIODS.WEEKLY
    end
    
    -- Map client leaderboard type names to server type names
    local serverType = leaderboardType
    if leaderboardType == "Money" then
        serverType = LEADERBOARD_TYPES.MONEY
    elseif leaderboardType == "Diamonds" then
        serverType = LEADERBOARD_TYPES.DIAMONDS
    elseif leaderboardType == "Rebirths" then
        serverType = LEADERBOARD_TYPES.REBIRTHS
    end
    
    -- Initialize cache structure if needed
    if not leaderboardCache[serverPeriod] then
        leaderboardCache[serverPeriod] = {}
    end
    
    -- SMART LOADING: Load on-demand instead of at startup
    if not leaderboardCache[serverPeriod][serverType] or #leaderboardCache[serverPeriod][serverType] == 0 then
        -- Load top 20 + requesting player's position
        local loadedData, playerRank = self:LoadLeaderboardData(serverPeriod, serverType, requestingPlayer)
    end
    
    local leaderboard = leaderboardCache[serverPeriod][serverType] or {}
    local result = {}
    
    -- Return the smart-loaded data (already formatted with ranks)
    for i = 1, math.min(#leaderboard, maxEntries) do
        local entry = leaderboard[i]
        table.insert(result, {
            rank = entry.rank or i, -- Use pre-calculated rank
            playerId = entry.playerId,
            playerName = entry.playerName,
            value = entry.value
        })
    end
    
    return result
end

-- Initialize leaderboard service
function CustomLeaderboardService:Initialize()
    -- LAZY LOADING: Don't load all leaderboards on startup
    -- Only load when requested by GetLeaderboard() calls
    -- This reduces startup time from ~2 seconds to instant
    
    -- Check for weekly reset
    self:CheckWeeklyReset()
    
    -- Set up periodic update processing
    RunService.Heartbeat:Connect(function()
        -- Process updates every few seconds (throttled)
        if tick() - lastUpdateTime >= UPDATE_INTERVAL then
            self:ProcessPendingUpdates()
        end
    end)
    
    -- Set up hourly weekly reset check
    task.spawn(function()
        while true do
            task.wait(3600) -- Check every hour
            self:CheckWeeklyReset()
        end
    end)
    
    -- Handle player joining (add to leaderboards)
    Players.PlayerAdded:Connect(function(player)
        -- Wait for player data to load
        task.wait(5)
        self:MarkPlayerForUpdate(player)
        
        -- Force immediate update for new players so they appear on leaderboard right away
        task.wait(1)
        self:ProcessPendingUpdates()
    end)
    
    -- Handle player leaving (final update)
    Players.PlayerRemoving:Connect(function(player)
        self:MarkPlayerForUpdate(player)
        -- Force immediate update for leaving players
        task.spawn(function()
            task.wait(1) -- Small delay to ensure data is saved
            for _, period in pairs(LEADERBOARD_PERIODS) do
                for _, leaderboardType in pairs(LEADERBOARD_TYPES) do
                    self:UpdatePlayerInLeaderboard(player, period, leaderboardType)
                    self:SaveLeaderboardData(period, leaderboardType)
                end
            end
        end)
    end)
    
    -- Service initialized with lazy loading
end

-- Public API for other services to trigger updates
function CustomLeaderboardService:NotifyPlayerDataChanged(player)
    -- Only mark for update, don't process immediately for performance
    self:MarkPlayerForUpdate(player)
end

-- Get player's rank in a specific leaderboard
function CustomLeaderboardService:GetPlayerRank(player, period, leaderboardType)
    local leaderboard = leaderboardCache[period][leaderboardType] or {}
    
    for i, entry in ipairs(leaderboard) do
        if entry.playerId == player.UserId then
            return i
        end
    end
    
    return nil -- Player not in leaderboard
end

-- Manual refresh function for testing/debugging (authorized users only)
function CustomLeaderboardService:ForceRefresh(requestingPlayer)
    local AuthorizationUtils = require(ReplicatedStorage.utils.AuthorizationUtils)
    
    -- Security check: Only allow authorized users
    if requestingPlayer and not AuthorizationUtils.isAuthorized(requestingPlayer) then
        AuthorizationUtils.logUnauthorizedAccess(requestingPlayer, "force leaderboard refresh")
        return false
    end
    
    print("CustomLeaderboardService: Forcing immediate refresh of all leaderboards (requested by " .. (requestingPlayer and requestingPlayer.Name or "SERVER") .. ")")
    
    -- Update all players immediately
    for _, player in pairs(Players:GetPlayers()) do
        self:MarkPlayerForUpdate(player)
    end
    
    -- Process updates immediately
    self:ProcessPendingUpdates()
    
    print("CustomLeaderboardService: Force refresh completed")
    return true
end

return CustomLeaderboardService