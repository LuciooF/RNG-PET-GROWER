-- Main Server Script
-- Handles map creation, player assignment, and data management

local ServerScriptService = game:GetService("ServerScriptService")

-- Initialize data services first
local DataService = require(ServerScriptService.services.DataService)
local StateService = require(ServerScriptService.services.StateService)
local PetService = require(ServerScriptService.services.PetService)
local PlotService = require(ServerScriptService.services.PlotService)
local GamepassService = require(ServerScriptService.services.GamepassService)
local PetMixerService = require(ServerScriptService.services.PetMixerService)

DataService:Initialize()
StateService:Initialize()
PetService:Initialize()
GamepassService:Initialize()
PetMixerService:Initialize()

-- Set up callback so StateService syncs data when ProfileStore loads
DataService.OnPlayerDataLoaded = function(player)
    StateService:BroadcastPlayerDataUpdate(player)
    -- Initialize doors and tubes for owned plots when data loads
    PlotService:InitializePlayerDoors(player)
    -- Validate gamepass ownership against Roblox (async, non-blocking)
    task.spawn(function()
        -- Wait for DataService to be ready instead of hardcoded delay
        while not DataService:GetPlayerData(player) do
            task.wait(0.1) -- Check every 100ms instead of blocking for 2 seconds
        end
        GamepassService:ValidatePlayerGamepasses(player)
    end)
    -- Check for completed mixers (offline progress)
    PetMixerService:OnPlayerJoined(player)
end

-- Setup AreaTemplate with static GUIs before creating player areas
local AreaTemplateSetupService = require(ServerScriptService.services.AreaTemplateSetupService)
AreaTemplateSetupService:Initialize()

-- Initialize area service
local AreaService = require(ServerScriptService.services.AreaService)
AreaService:Initialize()

-- Initialize plot service after areas are created
PlotService:Initialize()

-- Set up remote event handlers
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Copy config files to ReplicatedStorage for client access
local configFolder = ReplicatedStorage:FindFirstChild("config")
if not configFolder then
    configFolder = Instance.new("Folder")
    configFolder.Name = "config"
    configFolder.Parent = ReplicatedStorage
end

-- Copy config files from ServerStorage to ReplicatedStorage for client access
pcall(function()
    local serverConfigPath = ServerScriptService.Parent.ReplicatedStorage.Shared.config
    
    -- Copy PetSpawnConfig if it exists
    local petSpawnConfig = serverConfigPath:FindFirstChild("PetSpawnConfig")
    if petSpawnConfig then
        local copy = petSpawnConfig:Clone()
        copy.Parent = configFolder
        print("Main: Copied PetSpawnConfig to ReplicatedStorage.config")
    end
    
    -- Copy VariationConfig if it exists 
    local variationConfig = serverConfigPath:FindFirstChild("VariationConfig")
    if variationConfig then
        local copy = variationConfig:Clone()
        copy.Parent = configFolder
        print("Main: Copied VariationConfig to ReplicatedStorage.config")
    end
end)

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

-- Create remote events for gamepasses
local purchaseGamepassRemote = ReplicatedStorage:FindFirstChild("PurchaseGamepass")
if not purchaseGamepassRemote then
    purchaseGamepassRemote = Instance.new("RemoteEvent")
    purchaseGamepassRemote.Name = "PurchaseGamepass"
    purchaseGamepassRemote.Parent = ReplicatedStorage
end

local debugGrantGamepassRemote = ReplicatedStorage:FindFirstChild("DebugGrantGamepass")
if not debugGrantGamepassRemote then
    debugGrantGamepassRemote = Instance.new("RemoteEvent")
    debugGrantGamepassRemote.Name = "DebugGrantGamepass"
    debugGrantGamepassRemote.Parent = ReplicatedStorage
end

local toggleGamepassSettingRemote = ReplicatedStorage:FindFirstChild("ToggleGamepassSetting")
if not toggleGamepassSettingRemote then
    toggleGamepassSettingRemote = Instance.new("RemoteEvent")
    toggleGamepassSettingRemote.Name = "ToggleGamepassSetting"
    toggleGamepassSettingRemote.Parent = ReplicatedStorage
end

-- Create remote events for pet mixer
local startMixingRemote = ReplicatedStorage:FindFirstChild("StartMixing")
if not startMixingRemote then
    startMixingRemote = Instance.new("RemoteEvent")
    startMixingRemote.Name = "StartMixing"
    startMixingRemote.Parent = ReplicatedStorage
end

local claimMixerRemote = ReplicatedStorage:FindFirstChild("ClaimMixer")
if not claimMixerRemote then
    claimMixerRemote = Instance.new("RemoteEvent")
    claimMixerRemote.Name = "ClaimMixer"
    claimMixerRemote.Parent = ReplicatedStorage
end

local cancelMixerRemote = ReplicatedStorage:FindFirstChild("CancelMixer")
if not cancelMixerRemote then
    cancelMixerRemote = Instance.new("RemoteEvent")
    cancelMixerRemote.Name = "CancelMixer"
    cancelMixerRemote.Parent = ReplicatedStorage
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
    
    -- Give player diamonds for collecting a pet ball (with gamepass multipliers)
    local baseDiamonds = 1
    local finalDiamonds = PetService:ApplyGamepassMultipliers(player, baseDiamonds, "Diamonds")
    DataService:UpdatePlayerResources(player, "Diamonds", finalDiamonds)
    
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

-- Handle error message requests from client
errorMessageRemote.OnServerEvent:Connect(function(player, message)
    print("Main: Error message request from", player.Name, ":", message)
    
    -- Fire the message back to the requesting client
    errorMessageRemote:FireClient(player, message)
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

-- Handle gamepass purchase from client
purchaseGamepassRemote.OnServerEvent:Connect(function(player, gamepassName)
    if not gamepassName then
        warn("Main: Invalid gamepass name received from", player.Name)
        return
    end
    
    print("Main: Gamepass purchase request from", player.Name, "for", gamepassName)
    GamepassService:PromptGamepassPurchase(player, gamepassName)
end)

-- Handle debug gamepass grant from client (for testing)
debugGrantGamepassRemote.OnServerEvent:Connect(function(player, gamepassName)
    if not gamepassName then
        warn("Main: Invalid gamepass name received for debug grant from", player.Name)
        return
    end
    
    print("Main: DEBUG gamepass grant request from", player.Name, "for", gamepassName)
    GamepassService:DebugGrantGamepass(player, gamepassName)
end)

-- Handle gamepass setting toggle from client
toggleGamepassSettingRemote.OnServerEvent:Connect(function(player, settingName)
    if not settingName then
        warn("Main: Invalid setting name received for toggle from", player.Name)
        return
    end
    
    print("Main: Gamepass setting toggle request from", player.Name, "for", settingName)
    GamepassService:ToggleGamepassSetting(player, settingName)
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
    local currentDiamonds = playerData.Resources.Diamonds or 0 -- Keep diamonds
    local currentEquippedPets = playerData.EquippedPets or {} -- Keep equipped pets
    
    profile.Data.Resources = {
        Diamonds = currentDiamonds, -- Keep diamonds through rebirth
        Money = 0, -- Reset money to 0
        Rebirths = currentRebirths + 1
    }
    profile.Data.Pets = currentEquippedPets -- Only keep equipped pets
    profile.Data.EquippedPets = currentEquippedPets -- Keep equipped pets
    profile.Data.ProcessingPets = {} -- Clear processing pets
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

-- Handle pet mixer events
startMixingRemote.OnServerEvent:Connect(function(player, petIds)
    if not petIds or type(petIds) ~= "table" then
        warn("Main: Invalid pet IDs received for mixing from", player.Name)
        return
    end
    
    print("Main: Start mixing request from", player.Name, "with", #petIds, "pets")
    local success, result = PetMixerService:StartMixing(player, petIds)
    
    if not success then
        -- Show error message to player
        errorMessageRemote:FireClient(player, result or "Failed to start mixing")
    end
end)

claimMixerRemote.OnServerEvent:Connect(function(player, mixerId)
    if not mixerId then
        warn("Main: Invalid mixer ID received for claim from", player.Name)
        return
    end
    
    print("Main: Claim mixer request from", player.Name, "for mixer", mixerId)
    local success, result = PetMixerService:ClaimMixer(player, mixerId)
    
    if not success then
        -- Show error message to player
        errorMessageRemote:FireClient(player, result or "Failed to claim mixer")
    end
end)

cancelMixerRemote.OnServerEvent:Connect(function(player, mixerId)
    if not mixerId then
        warn("Main: Invalid mixer ID received for cancel from", player.Name)
        return
    end
    
    print("Main: Cancel mixer request from", player.Name, "for mixer", mixerId)
    local success, result = PetMixerService:CancelMixer(player, mixerId)
    
    if not success then
        -- Show error message to player
        errorMessageRemote:FireClient(player, result or "Failed to cancel mixer")
    end
end)

-- StateService handles the other remote events, we just need pet collection here