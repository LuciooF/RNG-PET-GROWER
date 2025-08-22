-- DataSyncService - Handles client-side data synchronization with server
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local store = require(ReplicatedStorage.store)
local Actions = require(ReplicatedStorage.store.actions)

local DataSyncService = {}
DataSyncService.__index = DataSyncService

local player = Players.LocalPlayer
local remoteEvents = {}

function DataSyncService:Initialize()
    -- Initializing DataSyncService
    
    -- Wait for remote events to be created by server (they might be directly in ReplicatedStorage)
    local remotesFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    
    -- Checking for RemoteEvents folder
    
    -- Scanning ReplicatedStorage for remotes
    
    if remotesFolder then
        -- Get remote event references from folder
        -- Looking in RemoteEvents folder
        remoteEvents.SyncPlayerData = remotesFolder:WaitForChild("SyncPlayerData", 5)
        remoteEvents.UpdateResource = remotesFolder:WaitForChild("UpdateResource", 5)  
        remoteEvents.RequestData = remotesFolder:WaitForChild("RequestData", 5)
    else
        -- Look for remote events directly in ReplicatedStorage
        -- Looking directly in ReplicatedStorage
        remoteEvents.SyncPlayerData = ReplicatedStorage:WaitForChild("SyncPlayerData", 5)
        remoteEvents.UpdateResource = ReplicatedStorage:WaitForChild("UpdateResource", 5)
        remoteEvents.RequestData = ReplicatedStorage:WaitForChild("RequestData", 5)
    end
    
    -- Checking for required remotes
    
    if not remoteEvents.SyncPlayerData then
        warn("DataSyncService: Required remote events not found!")
        return
    end
    
    -- Remote events found successfully
    
    -- Set up remote event handlers
    self:SetupRemoteHandlers()
    
    -- Request initial data since we found the remote events
    self:RequestDataFromServer()
    
end

function DataSyncService:SetupRemoteHandlers()
    -- Setting up remote handlers
    
    -- Handle data updates from server
    remoteEvents.SyncPlayerData.OnClientEvent:Connect(function(playerData)
        -- Received data sync from server
        self:UpdateClientState(playerData)
    end)
    
    -- Remote handlers connected
end

function DataSyncService:RequestDataFromServer()
    remoteEvents.RequestData:FireServer()
end

function DataSyncService:UpdateClientState(playerData)
    -- Updating Redux store
    -- Update Redux store with server data
    store:dispatch(Actions.setPlayerData(playerData))
    
    -- Verify the update
    local newState = store:getState()
    if newState.player and newState.player.Resources then
        -- Redux store updated successfully
    end
end

-- Client-side helper methods that sync with server
function DataSyncService:UpdateResource(resourceType, amount)
    -- Update local state immediately for responsive UI
    store:dispatch(Actions.updateResources(resourceType, amount))
    
    -- Send to server for persistence - find remote directly
    local updateResourceRemote = ReplicatedStorage:FindFirstChild("UpdateResource")
    if updateResourceRemote then
        updateResourceRemote:FireServer(resourceType, amount)
    else
        warn("DataSyncService: UpdateResource remote not found")
    end
end

function DataSyncService:GetPlayerData()
    local state = store:getState()
    return state.player
end

function DataSyncService:GetResource(resourceType)
    local playerData = self:GetPlayerData()
    return playerData.Resources[resourceType] or 0
end

function DataSyncService:GetPets()
    local playerData = self:GetPlayerData()
    return playerData.Pets or {}
end

function DataSyncService:GetEquippedPets()
    local playerData = self:GetPlayerData()
    return playerData.EquippedPets or {}
end

function DataSyncService:GetOwnedTubes()
    local playerData = self:GetPlayerData()
    return playerData.OwnedTubes or {}
end

function DataSyncService:GetOwnedPlots()
    local playerData = self:GetPlayerData()
    return playerData.OwnedPlots or {}
end

-- Update player settings and sync to server
function DataSyncService:UpdatePlayerSettings(settings)
    -- Update local state immediately for responsive UI
    store:dispatch(Actions.updatePlayerSettings(settings))
    
    -- Send to server for persistence
    local updateSettingsRemote = ReplicatedStorage:FindFirstChild("UpdatePlayerSettings")
    if updateSettingsRemote then
        updateSettingsRemote:FireServer(settings)
    else
        warn("DataSyncService: UpdatePlayerSettings remote not found")
    end
end

-- Subscribe to state changes
function DataSyncService:Subscribe(callback)
    -- Rodux uses the 'changed' signal for subscriptions
    if store.changed and store.changed.connect then
        return store.changed:connect(callback)
    elseif store.changed and store.changed.Connect then
        return store.changed:Connect(callback)
    else
        warn("DataSyncService: No valid subscription method found")
        -- Return a dummy unsubscribe function
        return function() end
    end
end

return DataSyncService