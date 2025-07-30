-- StateService - Manages state synchronization between server and client
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DataService = require(script.Parent.DataService)

local StateService = {}
StateService.__index = StateService

-- Remote events for client-server communication
local remoteEventNames = {
    "SyncPlayerData",
    "UpdateResource", 
    "RequestData"
}
local remoteEvents = {}

function StateService:Initialize()
    
    -- Check if remote events already exist directly in ReplicatedStorage
    local existingCount = 0
    for _, eventName in pairs(remoteEventNames) do
        local existing = ReplicatedStorage:FindFirstChild(eventName)
        if existing then
            remoteEvents[eventName] = existing
            existingCount = existingCount + 1
        end
    end
    
    if existingCount == #remoteEventNames then
        -- Use existing remote events
    else
        -- Create remote events folder
        local remotesFolder = Instance.new("Folder")
        remotesFolder.Name = "RemoteEvents"
        remotesFolder.Parent = ReplicatedStorage
        
        -- Create remote events
        self:CreateRemoteEvents(remotesFolder)
    end
    
    -- Set up remote event handlers
    self:SetupRemoteHandlers()
    
end

function StateService:CreateRemoteEvents(parent)
    for _, eventName in pairs(remoteEventNames) do
        local remoteEvent = Instance.new("RemoteEvent")
        remoteEvent.Name = eventName
        remoteEvent.Parent = parent
        remoteEvents[eventName] = remoteEvent
    end
end

function StateService:SetupRemoteHandlers()
    -- Handle client requests for data sync
    remoteEvents.RequestData.OnServerEvent:Connect(function(player)
        self:SyncPlayerDataToClient(player)
    end)
    
    -- Handle resource update requests from client (validation happens here)
    remoteEvents.UpdateResource.OnServerEvent:Connect(function(player, resourceType, amount)
        self:HandleResourceUpdateRequest(player, resourceType, amount)
    end)
end

function StateService:SyncPlayerDataToClient(player)
    local playerData = DataService:GetPlayerData(player)
    if playerData then
        remoteEvents.SyncPlayerData:FireClient(player, playerData)
    else
        -- Data not ready yet, wait and retry
        task.spawn(function()
            local attempts = 0
            while not playerData and attempts < 50 do -- 5 second max wait
                task.wait(0.1)
                playerData = DataService:GetPlayerData(player)
                attempts = attempts + 1
            end
            if playerData then
                remoteEvents.SyncPlayerData:FireClient(player, playerData)
            else
                warn("StateService: Player data not available after 5 seconds for", player.Name)
            end
        end)
    end
end

function StateService:HandleResourceUpdateRequest(player, resourceType, amount)
    -- Validate the request (add security checks here later)
    if resourceType and amount and type(amount) == "number" then
        local success = DataService:UpdatePlayerResources(player, resourceType, amount)
        if success then
            -- Sync updated data back to client
            self:SyncPlayerDataToClient(player)
        end
    else
        warn(string.format("StateService: Invalid resource update request from %s", player.Name))
    end
end

function StateService:BroadcastPlayerDataUpdate(player)
    -- Called when server updates player data and needs to sync to client
    self:SyncPlayerDataToClient(player)
end

-- Helper methods for common state updates
function StateService:UpdatePlayerResource(player, resourceType, amount)
    local success = DataService:UpdatePlayerResources(player, resourceType, amount)
    if success then
        self:SyncPlayerDataToClient(player)
    end
    return success
end

function StateService:SetPlayerResource(player, resourceType, amount)
    local success = DataService:SetPlayerResource(player, resourceType, amount)
    if success then
        self:SyncPlayerDataToClient(player)
    end
    return success
end

function StateService:AddPlayerPet(player, petData)
    local success = DataService:AddPet(player, petData)
    if success then
        self:SyncPlayerDataToClient(player)
    end
    return success
end

function StateService:EquipPlayerPet(player, petData)
    local success = DataService:EquipPet(player, petData)
    if success then
        self:SyncPlayerDataToClient(player)
    end
    return success
end

return StateService