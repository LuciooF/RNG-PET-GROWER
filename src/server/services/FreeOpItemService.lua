-- FreeOpItemService - Server-side logic for free OP item rewards based on playtime
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local FreeOpItemConfig = require(ReplicatedStorage.config.FreeOpItemConfig)
local DataService = require(script.Parent.DataService)
local PotionService = require(script.Parent.PotionService)

local FreeOpItemService = {}
FreeOpItemService.__index = FreeOpItemService

-- Track player sessions for free OP item progress
local playerSessions = {} -- [player] = { sessionStart = os.time(), lastClaimTime = 0, claimCount = 0 }

-- Remote events
local freeOpItemDataRemote = nil
local claimFreeOpItemRemote = nil

-- Update interval (seconds)
local UPDATE_INTERVAL = 10 -- Update every 10 seconds for smoother progress bar

-- Last update time
local lastUpdateTime = 0

function FreeOpItemService:Initialize()
    print("FreeOpItemService: Initializing")
    
    -- Create remote events
    freeOpItemDataRemote = Instance.new("RemoteFunction")
    freeOpItemDataRemote.Name = "GetFreeOpItemData"
    freeOpItemDataRemote.Parent = ReplicatedStorage
    
    claimFreeOpItemRemote = Instance.new("RemoteEvent")
    claimFreeOpItemRemote.Name = "ClaimFreeOpItem"
    claimFreeOpItemRemote.Parent = ReplicatedStorage
    
    -- Set up remote handlers
    freeOpItemDataRemote.OnServerInvoke = function(player)
        return self:GetPlayerFreeOpItemData(player)
    end
    
    claimFreeOpItemRemote.OnServerEvent:Connect(function(player, sessionPlaytime)
        self:HandleClaimRequest(player, sessionPlaytime)
    end)
    
    -- Handle players already in game
    for _, player in pairs(Players:GetPlayers()) do
        self:StartSession(player)
    end
    
    -- Handle new players joining
    Players.PlayerAdded:Connect(function(player)
        self:StartSession(player)
    end)
    
    -- Handle players leaving
    Players.PlayerRemoving:Connect(function(player)
        self:EndSession(player)
    end)
    
    -- No periodic updates needed - using client-side tracking
    
    print("FreeOpItemService: Initialized successfully")
end

function FreeOpItemService:StartSession(player)
    print("FreeOpItemService: Starting session for", player.Name)
    
    playerSessions[player] = {
        sessionStart = os.time(),
        lastClaimTime = 0,
        claimCount = 0
    }
end

function FreeOpItemService:EndSession(player)
    if playerSessions[player] then
        print("FreeOpItemService: Ending session for", player.Name)
        -- Just clean up the session data (no need to save - using client-side tracking)
        playerSessions[player] = nil
    end
end

function FreeOpItemService:UpdateAllSessions()
    -- No longer needed - using client-side tracking
end

function FreeOpItemService:GetPlayerFreeOpItemData(player)
    -- Simply return session data for client to handle
    local sessionData = playerSessions[player] or {
        sessionStart = os.time(),
        lastClaimTime = 0,
        claimCount = 0
    }
    
    return {
        sessionStart = sessionData.sessionStart,
        lastClaimTime = sessionData.lastClaimTime,
        claimCount = sessionData.claimCount
    }
end

function FreeOpItemService:HandleClaimRequest(player, sessionPlaytime)
    local sessionData = playerSessions[player]
    if not sessionData then
        warn("FreeOpItemService: No session data for", player.Name)
        return
    end
    
    -- Validate playtime (must be at least required time since last claim)
    local config = FreeOpItemConfig.GetConfig()
    local requiredMinutes = config.RequiredPlaytimeMinutes
    
    -- Check if enough time has passed since last claim
    local currentTime = os.time()
    local timeSinceLastClaim = sessionData.lastClaimTime > 0 and (currentTime - sessionData.lastClaimTime) / 60 or sessionPlaytime
    
    if timeSinceLastClaim < requiredMinutes then
        warn("FreeOpItemService: Player", player.Name, "tried to claim but hasn't played enough (", timeSinceLastClaim, "/", requiredMinutes, ")")
        return
    end
    
    -- Check max claims per session
    local maxClaims = FreeOpItemConfig.GetMaxClaimsPerSession()
    if maxClaims > 0 and sessionData.claimCount >= maxClaims then
        warn("FreeOpItemService: Player", player.Name, "reached max claims for this session")
        return
    end
    
    print("FreeOpItemService: Processing claim for", player.Name)
    
    -- Give the reward
    local config = FreeOpItemConfig.GetConfig()
    local potionReward = FreeOpItemConfig.GetPotionReward()
    
    local success = PotionService:GivePotionWithReward(
        player, 
        potionReward.potionId, 
        potionReward.quantity, 
        "Free OP Item Reward"
    )
    
    if success then
        -- Update session data for next claim
        sessionData.lastClaimTime = os.time()
        sessionData.claimCount = sessionData.claimCount + 1
        
        -- Update player data for persistence (optional)
        local playerData = DataService:GetPlayerData(player)
        if playerData then
            if not playerData.FreeOpItem then
                playerData.FreeOpItem = {}
            end
            playerData.FreeOpItem.totalClaims = (playerData.FreeOpItem.totalClaims or 0) + 1
            playerData.FreeOpItem.lastClaimTime = os.time()
            
            -- Sync data to client
            DataService:SyncPlayerDataToClient(player)
        end
        
        print("FreeOpItemService: Successfully gave reward to", player.Name, "- Claim #", sessionData.claimCount)
    else
        warn("FreeOpItemService: Failed to give reward to", player.Name)
    end
end

-- Singleton instance
local instance = FreeOpItemService
instance:Initialize()

return instance