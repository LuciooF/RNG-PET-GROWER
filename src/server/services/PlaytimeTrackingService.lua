-- PlaytimeTrackingService - Tracks player session time and manages playtime rewards
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PlaytimeTrackingService = {}
PlaytimeTrackingService.__index = PlaytimeTrackingService

-- Track active player sessions
local playerSessions = {} -- [player] = { joinTime = tick(), totalMinutes = 0 }

-- Update interval (seconds)
local UPDATE_INTERVAL = 60 -- Update every minute

-- Last update time for batch processing
local lastUpdateTime = 0

function PlaytimeTrackingService:Initialize()
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
    
    -- Set up periodic updates
    RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        if currentTime - lastUpdateTime >= UPDATE_INTERVAL then
            self:UpdateAllSessions()
            lastUpdateTime = currentTime
        end
    end)
    
    print("PlaytimeTrackingService: Initialized")
end

function PlaytimeTrackingService:StartSession(player)
    local DataService = require(script.Parent.DataService)
    local playerData = DataService:GetPlayerData(player)
    
    playerSessions[player] = {
        joinTime = tick(),
        totalMinutes = playerData and playerData.PlaytimeMinutes or 0,
        lastUpdateTime = tick()
    }
    
    print("PlaytimeTrackingService: Started session for", player.Name)
end

function PlaytimeTrackingService:EndSession(player)
    if playerSessions[player] then
        -- Update one final time before removing
        self:UpdatePlayerSession(player)
        playerSessions[player] = nil
        print("PlaytimeTrackingService: Ended session for", player.Name)
    end
end

function PlaytimeTrackingService:UpdatePlayerSession(player)
    local session = playerSessions[player]
    if not session then return end
    
    local currentTime = tick()
    local sessionMinutes = (currentTime - session.lastUpdateTime) / 60
    
    -- Only update if at least 30 seconds have passed (prevent micro-updates)
    if sessionMinutes >= 0.5 then
        local DataService = require(script.Parent.DataService)
        local profile = DataService:GetPlayerProfile(player)
        
        if profile then
            -- Update total playtime
            local newTotalMinutes = (profile.Data.PlaytimeMinutes or 0) + sessionMinutes
            profile.Data.PlaytimeMinutes = math.floor(newTotalMinutes * 10) / 10 -- Round to 1 decimal
            
            -- Initialize ClaimedPlaytimeRewards if it doesn't exist
            if not profile.Data.ClaimedPlaytimeRewards then
                profile.Data.ClaimedPlaytimeRewards = {}
            end
            
            -- Update session tracking
            session.totalMinutes = profile.Data.PlaytimeMinutes
            session.lastUpdateTime = currentTime
            
            -- Sync to client
            local StateService = require(script.Parent.StateService)
            StateService:BroadcastPlayerDataUpdate(player)
        end
    end
end

function PlaytimeTrackingService:UpdateAllSessions()
    for player, session in pairs(playerSessions) do
        if player.Parent == Players then
            self:UpdatePlayerSession(player)
        else
            -- Player left but wasn't properly cleaned up
            playerSessions[player] = nil
        end
    end
end

-- Get current session playtime for a player
function PlaytimeTrackingService:GetSessionTime(player)
    local session = playerSessions[player]
    if not session then return 0 end
    
    local currentTime = tick()
    local sessionMinutes = (currentTime - session.joinTime) / 60
    return sessionMinutes
end

-- Get total playtime for a player (including previous sessions)
function PlaytimeTrackingService:GetTotalPlaytime(player)
    local DataService = require(script.Parent.DataService)
    local playerData = DataService:GetPlayerData(player)
    
    if playerData and playerData.PlaytimeMinutes then
        return playerData.PlaytimeMinutes
    end
    
    return 0
end

-- Manual update for specific player (used when claiming rewards)
function PlaytimeTrackingService:ForceUpdatePlayer(player)
    self:UpdatePlayerSession(player)
end

return PlaytimeTrackingService