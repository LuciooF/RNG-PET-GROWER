-- Main Server Script
-- Handles map creation, player assignment, and data management

local ServerScriptService = game:GetService("ServerScriptService")

-- Initialize data services first
local DataService = require(ServerScriptService.services.DataService)
local StateService = require(ServerScriptService.services.StateService)
local PetService = require(ServerScriptService.services.PetService)
local PlotService = require(ServerScriptService.services.PlotService)

DataService:Initialize()
StateService:Initialize()
PetService:Initialize()

-- Set up callback so StateService syncs data when ProfileStore loads
DataService.OnPlayerDataLoaded = function(player)
    StateService:BroadcastPlayerDataUpdate(player)
    -- Initialize doors and tubes for owned plots when data loads
    PlotService:InitializePlayerDoors(player)
end

-- Initialize area service
local AreaService = require(ServerScriptService.services.AreaService)
AreaService:Initialize()

-- Initialize plot service after areas are created
PlotService:Initialize()

-- Set up remote event handlers
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create or get remote event for pet collection
local collectPetRemote = ReplicatedStorage:FindFirstChild("CollectPet")
if not collectPetRemote then
    collectPetRemote = Instance.new("RemoteEvent")
    collectPetRemote.Name = "CollectPet"
    collectPetRemote.Parent = ReplicatedStorage
end

-- Create remote events for data synchronization
local syncPlayerDataRemote = ReplicatedStorage:FindFirstChild("SyncPlayerData")
if not syncPlayerDataRemote then
    syncPlayerDataRemote = Instance.new("RemoteEvent")
    syncPlayerDataRemote.Name = "SyncPlayerData"
    syncPlayerDataRemote.Parent = ReplicatedStorage
end

local updateResourceRemote = ReplicatedStorage:FindFirstChild("UpdateResource")
if not updateResourceRemote then
    updateResourceRemote = Instance.new("RemoteEvent")
    updateResourceRemote.Name = "UpdateResource"
    updateResourceRemote.Parent = ReplicatedStorage
end

local requestDataRemote = ReplicatedStorage:FindFirstChild("RequestData")
if not requestDataRemote then
    requestDataRemote = Instance.new("RemoteEvent")
    requestDataRemote.Name = "RequestData"
    requestDataRemote.Parent = ReplicatedStorage
end

-- Create debug remote event for resetting player data
local resetPlayerDataRemote = ReplicatedStorage:FindFirstChild("ResetPlayerData")
if not resetPlayerDataRemote then
    resetPlayerDataRemote = Instance.new("RemoteEvent")
    resetPlayerDataRemote.Name = "ResetPlayerData"
    resetPlayerDataRemote.Parent = ReplicatedStorage
end

-- Create remote event for sending pets to heaven
local sendToHeavenRemote = ReplicatedStorage:FindFirstChild("SendToHeaven")
if not sendToHeavenRemote then
    sendToHeavenRemote = Instance.new("RemoteEvent")
    sendToHeavenRemote.Name = "SendToHeaven"
    sendToHeavenRemote.Parent = ReplicatedStorage
end

-- Create remote event for rebirth
local rebirthRemote = ReplicatedStorage:FindFirstChild("RebirthPlayer")
if not rebirthRemote then
    rebirthRemote = Instance.new("RemoteEvent")
    rebirthRemote.Name = "RebirthPlayer"
    rebirthRemote.Parent = ReplicatedStorage
end

-- Create remote event for error messages
local errorMessageRemote = ReplicatedStorage:FindFirstChild("ShowErrorMessage")
if not errorMessageRemote then
    errorMessageRemote = Instance.new("RemoteEvent")
    errorMessageRemote.Name = "ShowErrorMessage"
    errorMessageRemote.Parent = ReplicatedStorage
end

-- Create remote events for pet equipping
local equipPetRemote = ReplicatedStorage:FindFirstChild("EquipPet")
if not equipPetRemote then
    equipPetRemote = Instance.new("RemoteEvent")
    equipPetRemote.Name = "EquipPet"
    equipPetRemote.Parent = ReplicatedStorage
end

local unequipPetRemote = ReplicatedStorage:FindFirstChild("UnequipPet")
if not unequipPetRemote then
    unequipPetRemote = Instance.new("RemoteEvent")
    unequipPetRemote.Name = "UnequipPet"
    unequipPetRemote.Parent = ReplicatedStorage
end

-- Handle pet collection from client
collectPetRemote.OnServerEvent:Connect(function(player, petData, ballPath)
    -- Validate the pet data
    if not petData or not petData.Name or not petData.Rarity then
        warn("Main: Invalid pet data received from", player.Name)
        return
    end
    
    -- Add pet to player's inventory
    DataService:AddPetToPlayer(player, petData)
    
    -- Give player 1 diamond for collecting a pet ball (non-scalable currency)
    DataService:UpdatePlayerResources(player, "Diamonds", 1)
    
    -- Notify PlotService that a ball was collected for counter update
    if ballPath then
        PlotService:OnPetBallCollected(ballPath)
    end
    
    -- Sync updated data to client
    StateService:BroadcastPlayerDataUpdate(player)
    
end)

-- Handle reset player data from debug panel
resetPlayerDataRemote.OnServerEvent:Connect(function(player)
    print("Main: Reset data request from", player.Name)
    
    -- Reset player data to template
    local success = DataService:ResetPlayerData(player)
    if success then
        -- Sync updated data to client
        StateService:BroadcastPlayerDataUpdate(player)
        
        -- Re-initialize the player's area to update visuals
        PlotService:ReinitializePlayerArea(player)
    end
end)

-- Handle send to heaven from client
sendToHeavenRemote.OnServerEvent:Connect(function(player)
    print("Main: Send to heaven request from", player.Name)
    
    -- Start heaven processing for this player
    PetService:StartHeavenProcessing(player)
end)

-- Handle equip pet from client
equipPetRemote.OnServerEvent:Connect(function(player, petId)
    if not petId then
        warn("Main: Invalid pet ID received for equip from", player.Name)
        return
    end
    
    local success, message = PetService:EquipPet(player, petId)
    if not success then
        -- Show error message to player
        errorMessageRemote:FireClient(player, message or "Failed to equip pet")
    end
end)

-- Handle unequip pet from client
unequipPetRemote.OnServerEvent:Connect(function(player, petId)
    if not petId then
        warn("Main: Invalid pet ID received for unequip from", player.Name)
        return
    end
    
    local success, message = PetService:UnequipPet(player, petId)
    if not success then
        -- Show error message to player
        errorMessageRemote:FireClient(player, message or "Failed to unequip pet")
    end
end)

-- Handle rebirth from client
rebirthRemote.OnServerEvent:Connect(function(player)
    print("Main: Rebirth request from", player.Name)
    
    -- Check if player has enough money (1000)
    local playerData = DataService:GetPlayerData(player)
    if not playerData or not playerData.Resources or playerData.Resources.Money < 1000 then
        warn("Main: Player", player.Name, "does not have enough money for rebirth")
        return
    end
    
    -- Perform rebirth - reset everything except rebirths
    local profile = DataService:GetPlayerProfile(player)
    if not profile then
        warn("Main: No profile found for player", player.Name)
        return
    end
    
    -- Increment rebirth count and reset everything else
    local currentRebirths = playerData.Resources.Rebirths or 0
    profile.Data.Resources = {
        Diamonds = 0,
        Money = 0, -- Starting money
        Rebirths = currentRebirths + 1
    }
    profile.Data.Pets = {}
    profile.Data.EquippedPets = {}
    profile.Data.ProcessingPets = {}
    profile.Data.OwnedTubes = {}
    profile.Data.OwnedPlots = {}
    
    -- Stop any active heaven processing
    PetService:StopHeavenProcessing(player)
    
    -- Clear spawned pet balls in player's area
    PlotService:ClearAllPetBallsInPlayerArea(player)
    
    -- Sync updated data to client
    StateService:BroadcastPlayerDataUpdate(player)
    
    -- Re-initialize the player's area to update visuals
    PlotService:ReinitializePlayerArea(player)
    
    print("Main: Rebirth completed for", player.Name, "- now has", currentRebirths + 1, "rebirths")
end)

-- StateService handles the other remote events, we just need pet collection here