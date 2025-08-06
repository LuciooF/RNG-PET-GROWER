-- Main Server Script
-- Handles map creation, player assignment, and data management

local ServerScriptService = game:GetService("ServerScriptService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Initialize data services first
local DataService = require(ServerScriptService.services.DataService)
local PetService = require(ServerScriptService.services.PetService)
local PlotService = require(ServerScriptService.services.PlotService)
local GamepassService = require(ServerScriptService.services.GamepassService)
local PetMixerService = require(ServerScriptService.services.PetMixerService)
local LeaderboardService = require(ServerScriptService.services.LeaderboardService)
local OPPetService = require(ServerScriptService.services.OPPetService)
local AnnouncementService = require(ServerScriptService.services.AnnouncementService)
local PlaytimeTrackingService = require(ServerScriptService.services.PlaytimeTrackingService)
local PlaytimeRewardsService = require(ServerScriptService.services.PlaytimeRewardsService)
local CustomLeaderboardService = require(ServerScriptService.services.CustomLeaderboardService)
local AuthorizationUtils = require(ReplicatedStorage.utils.AuthorizationUtils)

DataService:Initialize()
PetService:Initialize()
GamepassService:Initialize()
PetMixerService:Initialize()
LeaderboardService:Initialize()
OPPetService:Initialize()
AnnouncementService:Initialize()
PlaytimeTrackingService:Initialize()
PlaytimeRewardsService:Initialize()
CustomLeaderboardService:Initialize()

-- Initialize Crazy Chest service
local CrazyChestService = require(ServerScriptService.services.CrazyChestService)
CrazyChestService:Initialize()

-- Rebirth function (shared by both money and Robux rebirth)
local function performRebirth(player, skipMoneyCheck)
    skipMoneyCheck = skipMoneyCheck or false
    
    -- Processing rebirth request
    
    -- Check if player has enough money (unless skipping for Robux purchase)
    local playerData = DataService:GetPlayerData(player)
    if not skipMoneyCheck then
        local RebirthUtils = require(ReplicatedStorage.utils.RebirthUtils)
        local currentRebirths = (playerData and playerData.Resources and playerData.Resources.Rebirths) or 0
        local rebirthCost = RebirthUtils.getRebirthCost(currentRebirths)
        
        if not playerData or not playerData.Resources or playerData.Resources.Money < rebirthCost then
            warn("Main: Player", player.Name, "does not have enough money for rebirth")
            return false
        end
    end
    
    -- Perform rebirth - reset everything except rebirths
    local profile = DataService:GetPlayerProfile(player)
    if not profile then
        warn("Main: No profile found for player", player.Name)
        return false
    end
    
    -- Increment rebirth count and reset everything else
    local currentRebirths = playerData.Resources.Rebirths or 0
    local currentDiamonds = playerData.Resources.Diamonds or 0 -- Keep diamonds
    local currentEquippedPets = playerData.EquippedPets or {} -- Keep equipped pets
    local currentOPPets = playerData.OPPets or {} -- Keep OP pets (premium purchases)
    
    profile.Data.Resources = {
        Diamonds = currentDiamonds, -- Keep diamonds through rebirth
        Money = 0, -- Reset money to 0
        Rebirths = currentRebirths + 1
    }
    profile.Data.Pets = currentEquippedPets -- Only keep equipped pets
    profile.Data.EquippedPets = currentEquippedPets -- Keep equipped pets
    profile.Data.OPPets = currentOPPets -- Keep OP pets (they're premium purchases)
    profile.Data.ProcessingPets = {} -- Clear processing pets
    profile.Data.OwnedTubes = {}
    profile.Data.OwnedPlots = {}
    
    -- Stop any active heaven processing
    PetService:StopHeavenProcessing(player)
    
    -- Clear spawned pet balls in player's area
    PlotService:ClearAllPetBallsInPlayerArea(player)
    
    -- Sync updated data to client Rodux store
    DataService:SyncPlayerDataToClient(player)
    
    -- Notify PlotService about the rebirth reset
    PlotService:OnPlayerDataReset(player)
    
    -- Re-initialize the player's area to update visuals
    PlotService:ReinitializePlayerArea(player)
    
    -- Update leaderboard with new rebirth count
    task.spawn(function()
        local updatedData = DataService:GetPlayerData(player)
        if updatedData then
            LeaderboardService:UpdateLeaderstats(player, updatedData)
        end
    end)
    
    -- Rebirth completed successfully
    return true
end

-- Set up MarketplaceService ProcessReceipt for developer products
local ROBUX_REBIRTH_DEV_PRODUCT_ID = 3353655412

MarketplaceService.ProcessReceipt = function(receiptInfo)
    -- Check if this is the rebirth dev product
    if receiptInfo.ProductId == ROBUX_REBIRTH_DEV_PRODUCT_ID then
        local player = game.Players:GetPlayerByUserId(receiptInfo.PlayerId)
        if player then
            -- Perform rebirth (skip money check since they paid Robux)
            local success = performRebirth(player, true)
            if success then
                return Enum.ProductPurchaseDecision.PurchaseGranted
            else
                return Enum.ProductPurchaseDecision.NotProcessedYet
            end
        end
    end
    
    -- Check if this is an OP pet purchase
    local result = OPPetService:ProcessReceipt(receiptInfo)
    if result ~= Enum.ProductPurchaseDecision.NotProcessedYet then
        return result
    end
    
    -- If we don't handle this product, don't grant it
    return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- Set up callback for when ProfileStore loads (DataService already auto-syncs)
DataService.OnPlayerDataLoaded = function(player)
    -- DataService:LoadPlayerProfile already syncs to client, no manual sync needed
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
    
    -- Resume pet processing if player has processing pets
    task.spawn(function()
        local playerData = DataService:GetPlayerData(player)
        if playerData and playerData.ProcessingPets and #playerData.ProcessingPets > 0 then
            print("Main: Resuming pet processing for", player.Name, "with", #playerData.ProcessingPets, "pets")
            -- Use StartHeavenProcessingLoop directly since pets are already in ProcessingPets
            PetService:StartHeavenProcessingLoop(player)
        end
    end)
    
    -- Update leaderboard with initial player data
    task.spawn(function()
        local playerData = DataService:GetPlayerData(player)
        if playerData then
            LeaderboardService:UpdateLeaderstats(player, playerData)
        end
    end)
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

-- Config files are automatically available in ReplicatedStorage.config from src/shared/config

-- Create or get remote event for pet collection
local collectPetRemote = ReplicatedStorage:FindFirstChild("CollectPet")
if not collectPetRemote then
    collectPetRemote = Instance.new("RemoteEvent")
    collectPetRemote.Name = "CollectPet"
    collectPetRemote.Parent = ReplicatedStorage
end

-- Create remote event for client-side pet ball spawning
local spawnPetBallRemote = ReplicatedStorage:FindFirstChild("SpawnPetBall")
if not spawnPetBallRemote then
    spawnPetBallRemote = Instance.new("RemoteEvent")
    spawnPetBallRemote.Name = "SpawnPetBall"
    spawnPetBallRemote.Parent = ReplicatedStorage
end

-- Create remote event for client-side pet ball clearing (for rebirth)
local clearPetBallsRemote = ReplicatedStorage:FindFirstChild("ClearPetBalls")
if not clearPetBallsRemote then
    clearPetBallsRemote = Instance.new("RemoteEvent")
    clearPetBallsRemote.Name = "ClearPetBalls"
    clearPetBallsRemote.Parent = ReplicatedStorage
end

-- Create remote event for client-side heaven pet ball spawning
local spawnHeavenPetBallRemote = ReplicatedStorage:FindFirstChild("SpawnHeavenPetBall")
if not spawnHeavenPetBallRemote then
    spawnHeavenPetBallRemote = Instance.new("RemoteEvent")
    spawnHeavenPetBallRemote.Name = "SpawnHeavenPetBall"
    spawnHeavenPetBallRemote.Parent = ReplicatedStorage
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

-- Create remote events for OP pet system
local purchaseOPPetRemote = ReplicatedStorage:FindFirstChild("PurchaseOPPet")
if not purchaseOPPetRemote then
    purchaseOPPetRemote = Instance.new("RemoteEvent")
    purchaseOPPetRemote.Name = "PurchaseOPPet"
    purchaseOPPetRemote.Parent = ReplicatedStorage
end

local opPetPurchaseSuccessRemote = ReplicatedStorage:FindFirstChild("OPPetPurchaseSuccess")
if not opPetPurchaseSuccessRemote then
    opPetPurchaseSuccessRemote = Instance.new("RemoteEvent")
    opPetPurchaseSuccessRemote.Name = "OPPetPurchaseSuccess"
    opPetPurchaseSuccessRemote.Parent = ReplicatedStorage
end

local opPetPurchaseErrorRemote = ReplicatedStorage:FindFirstChild("OPPetPurchaseError")
if not opPetPurchaseErrorRemote then
    opPetPurchaseErrorRemote = Instance.new("RemoteEvent")
    opPetPurchaseErrorRemote.Name = "OPPetPurchaseError"
    opPetPurchaseErrorRemote.Parent = ReplicatedStorage
end

local debugGrantOPPetRemote = ReplicatedStorage:FindFirstChild("DebugGrantOPPet")
if not debugGrantOPPetRemote then
    debugGrantOPPetRemote = Instance.new("RemoteEvent")
    debugGrantOPPetRemote.Name = "DebugGrantOPPet"
    debugGrantOPPetRemote.Parent = ReplicatedStorage
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

--- Create remote event for tutorial progress updates
local updateTutorialProgressRemote = ReplicatedStorage:FindFirstChild("UpdateTutorialProgress")
if not updateTutorialProgressRemote then
    updateTutorialProgressRemote = Instance.new("RemoteEvent")
    updateTutorialProgressRemote.Name = "UpdateTutorialProgress"
    updateTutorialProgressRemote.Parent = ReplicatedStorage
end

-- Create remote event for pet processing sound effects
local petProcessedRemote = ReplicatedStorage:FindFirstChild("PetProcessed")
if not petProcessedRemote then
    petProcessedRemote = Instance.new("RemoteEvent")
    petProcessedRemote.Name = "PetProcessed"
    petProcessedRemote.Parent = ReplicatedStorage
end

-- Create remote event for playtime rewards
local claimPlaytimeRewardRemote = ReplicatedStorage:FindFirstChild("ClaimPlaytimeReward")
if not claimPlaytimeRewardRemote then
    claimPlaytimeRewardRemote = Instance.new("RemoteEvent")
    claimPlaytimeRewardRemote.Name = "ClaimPlaytimeReward"
    claimPlaytimeRewardRemote.Parent = ReplicatedStorage
end

-- Create remote event for leaderboard data requests
local getLeaderboardDataRemote = ReplicatedStorage:FindFirstChild("GetLeaderboardData")
if not getLeaderboardDataRemote then
    getLeaderboardDataRemote = Instance.new("RemoteFunction")
    getLeaderboardDataRemote.Name = "GetLeaderboardData"
    getLeaderboardDataRemote.Parent = ReplicatedStorage
end

-- Create remote event for leaderboard manual refresh (authorized users only)
local refreshLeaderboardRemote = ReplicatedStorage:FindFirstChild("RefreshLeaderboard")
if not refreshLeaderboardRemote then
    refreshLeaderboardRemote = Instance.new("RemoteEvent")
    refreshLeaderboardRemote.Name = "RefreshLeaderboard"
    refreshLeaderboardRemote.Parent = ReplicatedStorage
end

-- Create remote event for debug commands
local debugCommandRemote = ReplicatedStorage:FindFirstChild("DebugCommand")
if not debugCommandRemote then
    debugCommandRemote = Instance.new("RemoteEvent")
    debugCommandRemote.Name = "DebugCommand"
    debugCommandRemote.Parent = ReplicatedStorage
end


-- Handle pet collection from client
collectPetRemote.OnServerEvent:Connect(function(player, petData)
    -- Validate the pet data
    if not petData or not petData.Name or not petData.Rarity then
        warn("Main: Invalid pet data received from", player.Name)
        return
    end
    
    -- Add pet to player's inventory (with inventory limit check and auto-equip)
    local success, result = DataService:AddPetToPlayer(player, petData)
    
    if success then
        -- Give player diamonds for collecting a pet ball (with gamepass multipliers)
        local baseDiamonds = 1
        local finalDiamonds = PetService:ApplyGamepassMultipliers(player, baseDiamonds, "Diamonds")
        DataService:UpdatePlayerResources(player, "Diamonds", finalDiamonds)
        
        -- DataService methods already auto-sync to client, no manual sync needed
    else
        -- Pet not added due to inventory limit or other issue
        -- Error message already sent by DataService:AddPetToPlayer
        print("Main: Failed to add pet for", player.Name, "- Reason:", result)
    end
    
end)

-- Handle reset player data from debug panel
resetPlayerDataRemote.OnServerEvent:Connect(function(player)
    -- Security check: Only allow authorized users
    if not AuthorizationUtils.isAuthorized(player) then
        AuthorizationUtils.logUnauthorizedAccess(player, "reset player data")
        return
    end
    
    print("Main: Reset data request from", player.Name)
    
    -- Reset player data to template
    local success = DataService:ResetPlayerData(player)
    if success then
        -- Clear spawned pet balls in player's area (same as rebirth)
        PlotService:ClearAllPetBallsInPlayerArea(player)
        
        -- Reset pet ball area data for this player
        PlotService:ResetPlayerAreaData(player)
        
        -- DataService:ResetPlayerData already auto-syncs, no manual sync needed
        
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
    -- Security check: Only allow authorized users
    if not AuthorizationUtils.isAuthorized(player) then
        AuthorizationUtils.logUnauthorizedAccess(player, "debug gamepass grant")
        return
    end
    
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
    -- Use the shared rebirth function (with money check)
    performRebirth(player, false)
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

-- Handle tutorial progress updates
updateTutorialProgressRemote.OnServerEvent:Connect(function(player, tutorialProgress)
    if not tutorialProgress or type(tutorialProgress) ~= "table" then
        warn("Main: Invalid tutorial progress received from", player.Name)
        return
    end
    
    -- Tutorial progress updated
    
    local profile = DataService:GetPlayerProfile(player)
    if not profile then
        warn("Main: No profile found for player", player.Name)
        return
    end
    
    -- Update tutorial progress in player data
    profile.Data.TutorialProgress = {
        currentStep = tutorialProgress.currentStep or 1,
        active = tutorialProgress.active or false
    }
    
    -- Mark tutorial as completed if finished
    if tutorialProgress.completed then
        profile.Data.TutorialCompleted = true
        profile.Data.TutorialProgress.active = false
    end
    
    -- Sync to client Rodux store
    DataService:SyncPlayerDataToClient(player)
end)

-- Handle OP pet purchase from client
purchaseOPPetRemote.OnServerEvent:Connect(function(player, opPetName)
    print("Main.server: Received OP pet purchase request from", player.Name, "for pet:", opPetName)
    
    if not opPetName then
        warn("Main.server: No OP pet name provided")
        return
    end
    
    -- Delegate to OP pet service
    print("Main.server: Delegating to OPPetService:PromptOPPetPurchase")
    OPPetService:PromptOPPetPurchase(player, opPetName)
end)

-- Handle debug OP pet grant from client (for testing)
debugGrantOPPetRemote.OnServerEvent:Connect(function(player, opPetName)
    -- Security check: Only allow authorized users
    if not AuthorizationUtils.isAuthorized(player) then
        AuthorizationUtils.logUnauthorizedAccess(player, "debug OP pet grant")
        return
    end
    
    if not opPetName then
        return
    end
    
    -- Get OP pet config
    local OPPetConfig = require(ReplicatedStorage.config.OPPetConfig)
    local opPetData = OPPetConfig.getOPPetByName(opPetName)
    if not opPetData then
        return
    end
    
    -- Create and grant the OP pet directly (bypassing payment)
    local opPet = OPPetConfig.createOPPet(opPetData, player.UserId)
    local success = OPPetService:AddOPPetToPlayer(player, opPet)
    
    if success then
        -- Send success notification to client
        local successRemote = ReplicatedStorage:FindFirstChild("OPPetPurchaseSuccess")
        if successRemote then
            successRemote:FireClient(player, opPet)
        end
    end
end)

-- Handle playtime reward claim from client
claimPlaytimeRewardRemote.OnServerEvent:Connect(function(player, timeMinutes, sessionTime)
    if not player or not timeMinutes then
        warn("Main: Invalid playtime reward claim parameters from", player.Name)
        return
    end
    
    print("Main: Playtime reward claim request from", player.Name, "for", timeMinutes, "minutes with session time", sessionTime or "nil")
    
    local success, message = PlaytimeRewardsService:ClaimReward(player, timeMinutes, sessionTime)
    
    if not success then
        -- Show error message to player
        local errorMessageRemote = ReplicatedStorage:FindFirstChild("ShowErrorMessage")
        if errorMessageRemote then
            errorMessageRemote:FireClient(player, message or "Failed to claim reward")
        end
    end
end)

-- Handle leaderboard data requests from client
getLeaderboardDataRemote.OnServerInvoke = function(player, period, leaderboardType)
    if not player or not period or not leaderboardType then
        warn("Main: Invalid leaderboard data request from", player and player.Name or "unknown")
        return {}
    end
    
    -- Leaderboard data requested
    
    -- Get leaderboard data from CustomLeaderboardService (with smart loading)
    local leaderboardData = CustomLeaderboardService:GetLeaderboard(period, leaderboardType, 50, player)
    
    return leaderboardData or {}
end

-- Notify CustomLeaderboardService when player data changes
local originalUpdatePlayerResources = DataService.UpdatePlayerResources
DataService.UpdatePlayerResources = function(self, player, resourceType, amount)
    local result = originalUpdatePlayerResources(self, player, resourceType, amount)
    
    -- Notify leaderboard service of the change
    if result and (resourceType == "Money" or resourceType == "Diamonds" or resourceType == "Rebirths") then
        CustomLeaderboardService:NotifyPlayerDataChanged(player)
    end
    
    return result
end

-- Handle leaderboard manual refresh from authorized users
refreshLeaderboardRemote.OnServerEvent:Connect(function(player)
    if not player then
        warn("Main: Invalid leaderboard refresh request")
        return
    end
    
    print("Main: Leaderboard refresh request from", player.Name)
    
    local success = CustomLeaderboardService:ForceRefresh(player)
    if success then
        print("Main: Leaderboard refresh completed for", player.Name)
    else
        warn("Main: Leaderboard refresh denied for", player.Name)
    end
end)

-- Handle debug commands from client (admin authorization required)
debugCommandRemote.OnServerEvent:Connect(function(player, commandType, ...)
    -- IMPORTANT: Only allow authorized players to use debug commands
    if not AuthorizationUtils.isAuthorized(player) then
        AuthorizationUtils.logUnauthorizedAccess(player, "Debug Commands")
        return
    end
    
    print("Main: Debug command", commandType, "from authorized player", player.Name)
    
    -- Handle different debug command types
    if commandType == "AddMoney" then
        local amount = ... -- First additional argument
        if type(amount) == "number" and amount > 0 then
            local success = DataService:UpdatePlayerResources(player, "Money", amount)
            if success then
                print("Main: Added", amount, "money to", player.Name)
            end
        else
            warn("Main: Invalid money amount for debug command:", amount)
        end
        
    elseif commandType == "AddDiamonds" then
        local amount = ...
        if type(amount) == "number" and amount > 0 then
            local success = DataService:UpdatePlayerResources(player, "Diamonds", amount)
            if success then
                print("Main: Added", amount, "diamonds to", player.Name)
            end
        else
            warn("Main: Invalid diamond amount for debug command:", amount)
        end
        
    elseif commandType == "ResetPlayerData" then
        local success = DataService:ResetPlayerData(player)
        if success then
            -- Clear spawned pet balls in player's area (same as rebirth)
            PlotService:ClearAllPetBallsInPlayerArea(player)
            
            -- Reset pet ball area data for this player
            PlotService:ResetPlayerAreaData(player)
            
            -- Re-initialize the player's area to update visuals
            PlotService:ReinitializePlayerArea(player)
            
            print("Main: Reset player data for", player.Name)
        else
            warn("Main: Failed to reset player data for", player.Name)
        end
        
    elseif commandType == "StartTutorial" then
        -- Start tutorial - this should be server-controlled for consistency
        local success = DataService:SetTutorialState(player, true, 1) -- Start at step 1
        if success then
            print("Main: Started tutorial for", player.Name)
            -- Tutorial state is synced via the DataService call
        else
            warn("Main: Failed to start tutorial for", player.Name)
        end
        
    elseif commandType == "StopTutorial" then
        -- Stop tutorial - this should be server-controlled for consistency  
        local success = DataService:SetTutorialState(player, false, nil) -- Stop tutorial
        if success then
            print("Main: Stopped tutorial for", player.Name)
            -- Tutorial state is synced via the DataService call
        else
            warn("Main: Failed to stop tutorial for", player.Name)
        end
        
    elseif commandType == "GiveRebirth" then
        -- Give instant rebirth without money check
        local success = performRebirth(player, true) -- Skip money check for debug
        if success then
            print("Main: Gave debug rebirth to", player.Name)
        else
            warn("Main: Failed to give debug rebirth to", player.Name)
        end
        
    elseif commandType == "CreateCustomPet" then
        -- Create custom pet with specified stats
        local petName, boost, value = ...
        if not petName or not boost or not value then
            warn("Main: Invalid custom pet parameters")
            return
        end
        
        -- Create custom pet data
        local HttpService = game:GetService("HttpService")
        local customPet = {
            ID = HttpService:GenerateGUID(false),
            Name = tostring(petName),
            Rarity = {
                RarityName = "Debug",
                RarityChance = 100,
                RarityColor = Color3.fromRGB(255, 255, 0) -- Yellow for debug pets
            },
            Variation = {
                VariationName = "Debug",
                VariationChance = 100,
                VariationColor = Color3.fromRGB(255, 255, 0), -- Yellow for debug pets
                VariationMultiplier = 1
            },
            BaseValue = tonumber(value) or 500,
            BaseBoost = tonumber(boost) or 1.5,
            FinalValue = tonumber(value) or 500,
            FinalBoost = tonumber(boost) or 1.5,
        }
        
        -- Add pet to player's inventory
        local success, result = DataService:AddPetToPlayer(player, customPet)
        if success then
            print("Main: Created custom pet for", player.Name, "- Name:", petName, "Boost:", boost, "Value:", value)
        else
            warn("Main: Failed to create custom pet for", player.Name, "- Reason:", result)
        end
        
    else
        warn("Main: Unknown debug command type:", commandType)
    end
end)

-- All remote events are now handled directly here with DataService auto-sync