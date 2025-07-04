-- Gamepass Service
-- Handles gamepass ownership detection, validation, and benefits
-- Ensures players get their gamepasses whether bought in-game or externally

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local GamepassConfig = require(ReplicatedStorage.Shared.config.GamepassConfig)
local DataService = require(script.Parent.DataService)

local GamepassService = {}
GamepassService.__index = GamepassService

-- Cache for gamepass ownership (reduces API calls)
local gamepassCache = {} -- [player][gamepassId] = {owned = boolean, lastCheck = timestamp}
local CACHE_DURATION = 300 -- Cache for 5 minutes
local BATCH_CHECK_SIZE = 3 -- Check 3 gamepasses per batch to avoid rate limits
local CHECK_INTERVAL = 2 -- Check every 2 seconds

-- Initialize service
function GamepassService:Initialize()
    print("GamepassService: Initializing...")
    
    -- Set up player connections
    Players.PlayerAdded:Connect(function(player)
        self:OnPlayerJoined(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:OnPlayerLeaving(player)
    end)
    
    -- Handle players already in game
    for _, player in pairs(Players:GetPlayers()) do
        self:OnPlayerJoined(player)
    end
    
    -- Set up periodic gamepass checks (catch external purchases)
    self:StartPeriodicChecks()
    
    print("GamepassService: Initialized successfully")
    return true
end

-- Handle player joining
function GamepassService:OnPlayerJoined(player)
    -- Initialize cache for player
    gamepassCache[player] = {}
    
    -- Start loading gamepasses after a brief delay (let data load first)
    task.spawn(function()
        task.wait(2) -- Give DataService time to load player data
        self:LoadPlayerGamepasses(player)
    end)
end

-- Handle player leaving
function GamepassService:OnPlayerLeaving(player)
    -- Clean up cache
    gamepassCache[player] = nil
end

-- Load all gamepasses for a player
function GamepassService:LoadPlayerGamepasses(player)
    print(string.format("GamepassService: Loading gamepasses for %s", player.Name))
    
    local ownedGamepasses = {}
    local totalGamepasses = 0
    local loadedCount = 0
    
    -- Count total gamepasses
    for _, _ in pairs(GamepassConfig.GAMEPASSES) do
        totalGamepasses = totalGamepasses + 1
    end
    
    -- Check each gamepass
    for _, gamepassData in pairs(GamepassConfig.GAMEPASSES) do
        task.spawn(function()
            local owned = self:CheckGamepassOwnership(player, gamepassData.id)
            if owned then
                ownedGamepasses[gamepassData.name] = {
                    id = gamepassData.id,
                    purchaseTime = tick(), -- Could be enhanced to track actual purchase time
                    benefits = gamepassData.benefits
                }
                print(string.format("GamepassService: %s owns %s", player.Name, gamepassData.name))
            end
            
            loadedCount = loadedCount + 1
            
            -- When all are loaded, save to database
            if loadedCount >= totalGamepasses then
                self:SaveGamepassesToDatabase(player, ownedGamepasses)
                self:SyncGamepassesToClient(player, ownedGamepasses)
            end
        end)
        
        -- Small delay between checks to avoid rate limiting
        task.wait(0.5)
    end
end

-- Check if player owns a specific gamepass (with caching)
function GamepassService:CheckGamepassOwnership(player, gamepassId)
    -- Check cache first
    local playerCache = gamepassCache[player]
    if playerCache and playerCache[gamepassId] then
        local cacheEntry = playerCache[gamepassId]
        if tick() - cacheEntry.lastCheck < CACHE_DURATION then
            return cacheEntry.owned
        end
    end
    
    -- Make API call
    local success, owned = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
    end)
    
    if not success then
        warn(string.format("GamepassService: Failed to check gamepass %d for %s: %s", 
            gamepassId, player.Name, tostring(owned)))
        return false
    end
    
    -- Update cache
    if not playerCache then
        playerCache = {}
        gamepassCache[player] = playerCache
    end
    
    playerCache[gamepassId] = {
        owned = owned,
        lastCheck = tick()
    }
    
    return owned
end

-- Save gamepasses to database
function GamepassService:SaveGamepassesToDatabase(player, ownedGamepasses)
    local success = DataService:SetData(player, "ownedGamepasses", ownedGamepasses)
    if success then
        print(string.format("GamepassService: Saved %d gamepasses for %s", 
            self:CountTable(ownedGamepasses), player.Name))
    else
        warn(string.format("GamepassService: Failed to save gamepasses for %s", player.Name))
    end
end

-- Sync gamepasses to client
function GamepassService:SyncGamepassesToClient(player, ownedGamepasses)
    local remoteEvent = ReplicatedStorage:FindFirstChild("GamepassSync")
    if remoteEvent then
        remoteEvent:FireClient(player, {
            ownedGamepasses = ownedGamepasses,
            effects = GamepassConfig:CalculateEffects(ownedGamepasses)
        })
        print(string.format("GamepassService: Synced gamepasses to %s", player.Name))
    else
        warn("GamepassService: GamepassSync RemoteEvent not found")
    end
end

-- Get player's gamepass data
function GamepassService:GetPlayerGamepasses(player)
    return DataService:GetData(player, "ownedGamepasses") or {}
end

-- Check if player owns specific gamepass
function GamepassService:PlayerOwnsGamepass(player, gamepassName)
    local ownedGamepasses = self:GetPlayerGamepasses(player)
    return ownedGamepasses[gamepassName] ~= nil
end

-- Get calculated effects for player
function GamepassService:GetPlayerEffects(player)
    local ownedGamepasses = self:GetPlayerGamepasses(player)
    return GamepassConfig:CalculateEffects(ownedGamepasses)
end

-- Handle gamepass purchase (called by external purchase handler)
function GamepassService:OnGamepassPurchased(player, gamepassId)
    print(string.format("GamepassService: Processing purchase of gamepass %d for %s", 
        gamepassId, player.Name))
    
    local gamepassData = GamepassConfig:GetGamepassData(gamepassId)
    if not gamepassData then
        warn(string.format("GamepassService: Unknown gamepass ID %d", gamepassId))
        return false
    end
    
    -- Add to owned gamepasses
    local ownedGamepasses = self:GetPlayerGamepasses(player)
    ownedGamepasses[gamepassData.name] = {
        id = gamepassId,
        purchaseTime = tick(),
        benefits = gamepassData.benefits
    }
    
    -- Save to database
    self:SaveGamepassesToDatabase(player, ownedGamepasses)
    
    -- Update cache
    local playerCache = gamepassCache[player]
    if playerCache then
        playerCache[gamepassId] = {
            owned = true,
            lastCheck = tick()
        }
    end
    
    -- Sync to client
    self:SyncGamepassesToClient(player, ownedGamepasses)
    
    -- Send purchase confirmation
    local remoteEvent = ReplicatedStorage:FindFirstChild("GamepassPurchased")
    if remoteEvent then
        remoteEvent:FireClient(player, {
            gamepassName = gamepassData.name,
            displayName = gamepassData.displayName,
            benefits = gamepassData.benefits
        })
    end
    
    print(string.format("GamepassService: Successfully processed %s purchase for %s", 
        gamepassData.name, player.Name))
    
    return true
end

-- Start periodic checks for external purchases
function GamepassService:StartPeriodicChecks()
    task.spawn(function()
        while true do
            task.wait(CHECK_INTERVAL)
            
            for player, _ in pairs(gamepassCache) do
                if player.Parent then -- Player still in game
                    self:PeriodicGamepassCheck(player)
                end
            end
        end
    end)
end

-- Check a few gamepasses for external purchases
function GamepassService:PeriodicGamepassCheck(player)
    local ownedGamepasses = self:GetPlayerGamepasses(player)
    local checkedCount = 0
    local hasChanges = false
    
    -- Check a few gamepasses per cycle
    for _, gamepassData in pairs(GamepassConfig.GAMEPASSES) do
        if checkedCount >= BATCH_CHECK_SIZE then
            break
        end
        
        -- Only check if we don't think they own it
        if not ownedGamepasses[gamepassData.name] then
            local owned = self:CheckGamepassOwnership(player, gamepassData.id)
            if owned then
                -- New gamepass detected!
                print(string.format("GamepassService: Detected external purchase of %s by %s", 
                    gamepassData.name, player.Name))
                
                ownedGamepasses[gamepassData.name] = {
                    id = gamepassData.id,
                    purchaseTime = tick(),
                    benefits = gamepassData.benefits
                }
                hasChanges = true
            end
            checkedCount = checkedCount + 1
        end
    end
    
    -- If changes detected, update everything
    if hasChanges then
        self:SaveGamepassesToDatabase(player, ownedGamepasses)
        self:SyncGamepassesToClient(player, ownedGamepasses)
    end
end

-- Utility function to count table entries
function GamepassService:CountTable(t)
    local count = 0
    for _, _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- Get gamepass benefit value (for specific benefit types)
function GamepassService:GetBenefitValue(player, benefitType)
    local effects = self:GetPlayerEffects(player)
    return effects[benefitType] or (benefitType:find("Multiplier") and 1.0 or false)
end

-- Debug function to list player's gamepasses
function GamepassService:DebugPlayerGamepasses(player)
    local ownedGamepasses = self:GetPlayerGamepasses(player)
    local effects = self:GetPlayerEffects(player)
    
    print(string.format("=== GAMEPASSES FOR %s ===", player.Name))
    for gamepassName, data in pairs(ownedGamepasses) do
        print(string.format("- %s (ID: %d)", gamepassName, data.id))
    end
    
    print("=== CALCULATED EFFECTS ===")
    for effect, value in pairs(effects) do
        print(string.format("- %s: %s", effect, tostring(value)))
    end
    print("========================")
end

return GamepassService