-- DataService - Handles player data with ProfileStore
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ProfileService = require(game.ServerStorage.Packages:WaitForChild("profilestore"))
local PetUtils = require(ReplicatedStorage.utils.PetUtils)
local AnnouncementService = require(script.Parent.AnnouncementService)
local AuthorizationUtils = require(ReplicatedStorage.utils.AuthorizationUtils)

local DataService = {}
DataService.__index = DataService

-- Auto-equip debounce system to handle rapid pet additions
local autoEquipDebounceTimers = {} -- player -> timer

-- Configuration
local PROFILE_TEMPLATE = {
    Resources = {
        Diamonds = 0,
        Money = 0, -- Starting money
        Rebirths = 0
    },
    Pets = {}, -- Array of pet objects
    EquippedPets = {}, -- Array of equipped pets
    ProcessingPets = {}, -- Array of pets being processed (sent to heaven)
    OPPets = {}, -- Array of OP pets (premium pets bought with Robux)
    OwnedTubes = {}, -- Array of tube numbers
    OwnedPlots = {}, -- Array of plot numbers
    OwnedGamepasses = {}, -- Array of owned gamepass names (e.g., {"PetMagnet"})
    GamepassSettings = { -- Settings for gamepass features
        AutoHeavenEnabled = true, -- Whether Auto Heaven is enabled (when owned)
        PetMagnetEnabled = true -- Whether Pet Magnet is enabled (when owned)
    },
    Mixers = {}, -- Array of active pet mixers with offline timer support
    CollectedPets = {}, -- Dictionary of all pets ever collected: {["MouseNormal"] = {count = 5, firstCollected = tick(), lastCollected = tick()}}
    ProcessedPets = 0, -- Total number of pets processed through tubes
    TutorialCompleted = false, -- Whether the player has completed the tutorial
    TutorialProgress = { -- Tutorial progression tracking
        currentStep = 1,
        completedSteps = {},
        active = false
    },
    PlaytimeMinutes = 0, -- Total playtime in minutes
    ClaimedPlaytimeRewards = {}, -- Array of claimed playtime reward times (e.g., {5, 10, 15})
    CrazyChest = { -- Crazy chest reward system
        Level = 1, -- Chest level (starts at 1)
        Luck = 1, -- Luck multiplier (starts at 1)
        PendingReward = nil -- Stored pending reward from chest opening
    },
    Potions = {}, -- Dictionary of owned potions: {["diamond_2x_10m"] = 3, ["money_2x_10m"] = 1}
    ActivePotions = {} -- Array of currently active potions with timestamps
}

local DATASTORE_NAME = "PlayerData"

-- Create ProfileStore using the correct API
local ProfileStore = ProfileService.New(DATASTORE_NAME, PROFILE_TEMPLATE)


-- Store active profiles
local Profiles = {}

function DataService:Initialize()
    -- Handle players already in game
    for _, player in pairs(Players:GetPlayers()) do
        self:LoadPlayerProfile(player)
    end
    
    -- Handle new players joining
    Players.PlayerAdded:Connect(function(player)
        self:LoadPlayerProfile(player)
    end)
    
    -- Handle players leaving
    Players.PlayerRemoving:Connect(function(player)
        self:UnloadPlayerProfile(player)
    end)
end

function DataService:LoadPlayerProfile(player)
    local profileKey = "Player_" .. player.UserId
    
    
    local profile = ProfileStore:StartSessionAsync(profileKey, {
        Cancel = function()
            return player.Parent ~= Players
        end
    })
    
    if profile ~= nil then
        -- GDPR compliance and data reconciliation
        profile:Reconcile() -- Fill in missing template values
        
        if player.Parent == Players then
            Profiles[player] = profile
            
            -- Initialize player data
            self:InitializePlayerData(player, profile.Data)
            
            -- Send initial data to client Rodux store
            self:SyncPlayerDataToClient(player)
            
            -- Trigger initial data sync callback if set
            if self.OnPlayerDataLoaded then
                self.OnPlayerDataLoaded(player)
            end
        else
            -- Player left before profile loaded
            profile:EndSession()
        end
    else
        -- Profile couldn't be loaded (probably due to other Roblox servers)
        player:Kick("Failed to load data. Please rejoin.")
    end
end

function DataService:UnloadPlayerProfile(player)
    local profile = Profiles[player]
    if profile ~= nil then
        -- Clear any pending auto-equip timers
        if autoEquipDebounceTimers[player] then
            task.cancel(autoEquipDebounceTimers[player])
            autoEquipDebounceTimers[player] = nil
        end
        
        profile:EndSession()
        Profiles[player] = nil
    end
end

function DataService:InitializePlayerData(player, data)
    -- Check if this is a new player (no money, no pets, no rebirths)
    local isNewPlayer = (data.Resources.Money == 0 and 
                        data.Resources.Rebirths == 0 and 
                        #(data.Pets or {}) == 0 and
                        not data.Potions or 
                        next(data.Potions or {}) == nil)
    
    if isNewPlayer then
        -- Give starter potions to new players
        local PotionService = require(script.Parent.PotionService)
        task.spawn(function()
            -- Wait a moment for player to be fully loaded
            task.wait(2)
            
            -- Give 1x Diamond potion
            PotionService:GivePotion(player, "diamond_2x_10m", 1)
            
            -- Give 1x Money potion
            PotionService:GivePotion(player, "money_2x_10m", 1)
            
            -- Give 1x Pet Magnet potion
            PotionService:GivePotion(player, "pet_magnet_10m", 1)
            
            print("DataService: Gave starter potions to new player", player.Name)
        end)
    end
end

function DataService:GetPlayerProfile(player)
    return Profiles[player]
end

function DataService:GetPlayerData(player)
    local profile = Profiles[player]
    if profile then
        return profile.Data
    end
    return nil
end

-- Helper functions for common data operations
function DataService:UpdatePlayerResources(player, resourceType, amount)
    local profile = Profiles[player]
    if profile and profile.Data.Resources[resourceType] then
        local oldValue = profile.Data.Resources[resourceType]
        profile.Data.Resources[resourceType] = oldValue + amount
        -- Resource updated successfully
        
        -- Sync updated data to client immediately via Rodux
        self:SyncPlayerDataToClient(player)
        
        return true
    end
    return false
end

-- Sync player data to client via Rodux store
function DataService:SyncPlayerDataToClient(player)
    local profile = Profiles[player]
    if not profile then 
        warn("DataService: Cannot sync - no profile for", player.Name)
        return 
    end
    
    -- Find or create UpdatePlayerData remote event for Rodux
    local updateDataRemote = ReplicatedStorage:FindFirstChild("UpdatePlayerData")
    if not updateDataRemote then
        updateDataRemote = Instance.new("RemoteEvent")
        updateDataRemote.Name = "UpdatePlayerData"
        updateDataRemote.Parent = ReplicatedStorage
    end
    
    -- Syncing player data to client
    
    -- Send updated data to client Rodux store
    local success, error = pcall(function()
        updateDataRemote:FireClient(player, profile.Data)
    end)
    
    if not success then
        warn("DataService: Failed to sync to Rodux for", player.Name, "Error:", error)
    else
        -- Successfully synced to client
    end
end

function DataService:SetPlayerResource(player, resourceType, amount)
    local profile = Profiles[player]
    if profile and profile.Data.Resources[resourceType] then
        profile.Data.Resources[resourceType] = amount
        
        -- Sync updated data to client immediately
        self:SyncPlayerDataToClient(player)
        
        return true
    end
    return false
end

function DataService:AddPet(player, petData)
    local profile = Profiles[player]
    if profile then
        -- Sanitize pet data for DataStore compatibility
        local sanitizedPet = PetUtils.sanitizePetForStorage(petData)
        table.insert(profile.Data.Pets, sanitizedPet)
        
        -- Auto-sync to client Rodux store
        self:SyncPlayerDataToClient(player)
        
        return true
    end
    return false
end

function DataService:EquipPet(player, petData)
    local profile = Profiles[player]
    if profile then
        -- Sanitize pet data for DataStore compatibility
        local sanitizedPet = PetUtils.sanitizePetForStorage(petData)
        table.insert(profile.Data.EquippedPets, sanitizedPet)
        
        -- Sync updated data to client Rodux store
        self:SyncPlayerDataToClient(player)
        
        return true
    end
    return false
end

function DataService:AddOwnedTube(player, tubeNumber)
    local profile = Profiles[player]
    if profile then
        table.insert(profile.Data.OwnedTubes, tubeNumber)
        -- Tube added successfully
        
        -- Sync to client Rodux store
        self:SyncPlayerDataToClient(player)
        
        return true
    end
    return false
end

function DataService:AddOwnedPlot(player, plotNumber)
    local profile = Profiles[player]
    if profile then
        table.insert(profile.Data.OwnedPlots, plotNumber)
        -- Plot added successfully
        
        -- Sync to client Rodux store
        self:SyncPlayerDataToClient(player)
        
        return true
    end
    return false
end

function DataService:TrackCollectedPet(player, petData)
    local profile = Profiles[player]
    if not profile then return end
    
    -- Create collection key from pet name and variation
    local petName = petData.Name or "Unknown"
    local variationName = "Bronze" -- Default to Bronze
    
    -- Handle both variation formats (string or object)
    if type(petData.Variation) == "string" then
        variationName = petData.Variation
    elseif petData.Variation and petData.Variation.VariationName then
        variationName = petData.Variation.VariationName
    end
    
    local collectionKey = petName .. variationName
    local currentTime = tick()
    
    -- Initialize CollectedPets if it doesn't exist (for backwards compatibility)
    if not profile.Data.CollectedPets then
        profile.Data.CollectedPets = {}
    end
    
    -- Update or create collection entry
    local isNewDiscovery = false
    if profile.Data.CollectedPets[collectionKey] then
        -- Update existing entry
        profile.Data.CollectedPets[collectionKey].count = profile.Data.CollectedPets[collectionKey].count + 1
        profile.Data.CollectedPets[collectionKey].lastCollected = currentTime
    else
        -- Create new entry - this is a first-time discovery!
        isNewDiscovery = true
        profile.Data.CollectedPets[collectionKey] = {
            petName = petName,
            variationName = variationName,
            count = 1,
            firstCollected = currentTime,
            lastCollected = currentTime
        }
    end
    
    return isNewDiscovery
end

function DataService:AddPetToPlayer(player, petData)
    local profile = Profiles[player]
    if profile then
        -- Check inventory limit (1000 pets maximum)
        local MAX_PET_INVENTORY = 1000
        if #profile.Data.Pets >= MAX_PET_INVENTORY then
            -- Send error message to player about inventory being full
            local PetService = require(script.Parent.PetService)
            PetService:ShowErrorMessage(player, "Your pet inventory is full! (" .. MAX_PET_INVENTORY .. " pets max). Send some pets to heaven to make space.")
            return false, "inventory_full"
        end
        
        -- Ensure pet has an ID
        if not petData.ID then
            petData.ID = game:GetService("HttpService"):GenerateGUID(false)
        end
        
        -- Track this pet in the collection dictionary and check if it's a new discovery
        local isNewDiscovery = self:TrackCollectedPet(player, petData)
        
        -- Only announce rare pet discoveries for first-time discoveries (same as popup)
        if isNewDiscovery then
            AnnouncementService:AnnouncePetDiscovery(player, petData)
        end
        
        -- Sanitize pet data for DataStore compatibility
        local sanitizedPet = PetUtils.sanitizePetForStorage(petData)
        table.insert(profile.Data.Pets, sanitizedPet)
        
        -- Schedule debounced auto-equip to handle rapid pet additions
        self:ScheduleDebouncedAutoEquip(player)
        
        -- Sync updated pet data to client Rodux store
        self:SyncPlayerDataToClient(player)
        
        return true, "success"
    end
    return false, "profile_not_found"
end

-- Debounced auto-equip system to prevent race conditions
function DataService:ScheduleDebouncedAutoEquip(player)
    -- Cancel existing timer if it exists
    if autoEquipDebounceTimers[player] then
        task.cancel(autoEquipDebounceTimers[player])
    end
    
    
    -- Schedule new auto-equip after a short delay (0.5 seconds for chest pets to ensure proper sync)
    autoEquipDebounceTimers[player] = task.delay(0.5, function()
        -- Clear the timer
        autoEquipDebounceTimers[player] = nil
        
        -- Perform auto-equip if player is still valid
        if player.Parent == game.Players then
            local PetService = require(script.Parent.PetService)
            local success, error = pcall(function()
                PetService:AutoEquipBestPets(player, 3) -- Max 3 equipped pets
            end)
            
            if not success then
                warn("DataService: Auto-equip failed for", player.Name, ":", error)
            else
            end
        end
    end)
end

function DataService:ResetPlayerData(player)
    -- Security check: Only allow authorized users
    if not AuthorizationUtils.isAuthorized(player) then
        AuthorizationUtils.logUnauthorizedAccess(player, "reset player data")
        return false
    end
    
    local profile = Profiles[player]
    if profile then
        -- Clear any pending auto-equip timers
        if autoEquipDebounceTimers[player] then
            task.cancel(autoEquipDebounceTimers[player])
            autoEquipDebounceTimers[player] = nil
        end
        
        -- Reset data to template values
        profile.Data.Resources = {
            Diamonds = 0,
            Money = 0, -- Starting money
            Rebirths = 0
        }
        profile.Data.Pets = {}
        profile.Data.EquippedPets = {}
        profile.Data.ProcessingPets = {}
        profile.Data.OPPets = {} -- Reset OP pets (they'll need to be repurchased)
        profile.Data.OwnedTubes = {}
        profile.Data.OwnedPlots = {}
        profile.Data.CollectedPets = {} -- Reset pet index/discovery data
        profile.Data.Mixers = {} -- Reset mixer data
        profile.Data.OwnedGamepasses = {} -- Reset gamepasses
        profile.Data.GamepassSettings = { -- Reset gamepass settings
            AutoHeavenEnabled = true,
            PetMagnetEnabled = true
        }
        profile.Data.ProcessedPets = 0 -- Reset processed pets counter
        profile.Data.TutorialCompleted = false -- Reset tutorial completion
        profile.Data.TutorialProgress = { -- Reset tutorial progress
            currentStep = 1,
            completedSteps = {},
            active = false
        }
        profile.Data.CrazyChest = { -- Reset crazy chest data
            Level = 1,
            Luck = 1,
            PendingReward = nil
        }
        profile.Data.Potions = {} -- Reset potion inventory
        profile.Data.ActivePotions = {} -- Reset active potions
        
        -- Clean up any active potion timers via PotionService
        local PotionService = require(script.Parent.PotionService)
        if PotionService then
            PotionService:CleanupPlayer(player)
        end
        
        -- Player data reset successfully
        
        -- IMPORTANT: Sync reset data to client Rodux store
        self:SyncPlayerDataToClient(player)
        
        -- Notify PlotService to reset door colors for this player
        local PlotService = require(script.Parent.PlotService)
        PlotService:OnPlayerDataReset(player)
        
        return true
    end
    return false
end

function DataService:SetTutorialState(player, isActive, currentStep)
    local profile = Profiles[player]
    if profile then
        profile.Data.TutorialProgress = profile.Data.TutorialProgress or {
            currentStep = 1,
            completedSteps = {},
            active = false
        }
        
        profile.Data.TutorialProgress.active = isActive
        if currentStep then
            profile.Data.TutorialProgress.currentStep = currentStep
        end
        
        -- Tutorial state updated
        
        -- Sync to client Rodux store
        self:SyncPlayerDataToClient(player)
        
        return true
    end
    return false
end

-- Enhanced pet management methods for proper architecture
function DataService:EquipPetById(player, petId, maxEquipped)
    local profile = Profiles[player]
    if not profile then
        return false, "Player profile not found"
    end
    
    -- Validation: Check max equipped limit
    if #(profile.Data.EquippedPets or {}) >= maxEquipped then
        return false, "Maximum equipped pets reached (" .. maxEquipped .. ")"
    end
    
    -- Find pet in inventory
    local petToEquip = nil
    for _, pet in pairs(profile.Data.Pets or {}) do
        if pet.ID == petId then
            petToEquip = pet
            break
        end
    end
    
    if not petToEquip then
        return false, "Pet not found in inventory"
    end
    
    -- Check if already equipped
    for _, equippedPet in pairs(profile.Data.EquippedPets or {}) do
        if equippedPet.ID == petId then
            return false, "Pet already equipped"
        end
    end
    
    -- Add to equipped pets
    table.insert(profile.Data.EquippedPets, petToEquip)
    
    -- Auto-sync to client Rodux store
    self:SyncPlayerDataToClient(player)
    
    return true, "Pet equipped successfully"
end

function DataService:UnequipPetById(player, petId)
    local profile = Profiles[player]
    if not profile then
        return false, "Player profile not found"
    end
    
    local newEquippedPets = {}
    local found = false
    
    for _, pet in pairs(profile.Data.EquippedPets or {}) do
        if pet.ID ~= petId then
            table.insert(newEquippedPets, pet)
        else
            found = true
        end
    end
    
    if not found then
        return false, "Pet not found in equipped pets"
    end
    
    profile.Data.EquippedPets = newEquippedPets
    
    -- Auto-sync to client Rodux store
    self:SyncPlayerDataToClient(player)
    
    return true, "Pet unequipped successfully"
end

function DataService:SetEquippedPets(player, newEquippedPets)
    local profile = Profiles[player]
    if not profile then
        return false, "Player profile not found"
    end
    
    -- Validate all pets exist in inventory
    local availablePets = {}
    for _, pet in pairs(profile.Data.Pets or {}) do
        availablePets[pet.ID] = pet
    end
    
    for _, equippedPet in pairs(newEquippedPets) do
        if not availablePets[equippedPet.ID] then
            return false, "Pet not found in inventory: " .. (equippedPet.Name or "Unknown")
        end
    end
    
    profile.Data.EquippedPets = newEquippedPets
    
    -- Auto-sync to client Rodux store
    self:SyncPlayerDataToClient(player)
    
    return true, "Equipped pets updated successfully"
end

function DataService:ProcessPetsToHeaven(player, petsToProcess)
    local profile = Profiles[player]
    if not profile then
        return false, "Player profile not found"
    end
    
    -- Create lookup for pets being processed
    local processedIds = {}
    for _, pet in pairs(petsToProcess) do
        processedIds[pet.ID] = true
    end
    
    -- Remove processed pets from inventory (keep equipped ones)
    local equippedPetIds = {}
    for _, pet in pairs(profile.Data.EquippedPets or {}) do
        equippedPetIds[pet.ID] = true
    end
    
    local newPetsArray = {}
    for _, pet in pairs(profile.Data.Pets or {}) do
        if not processedIds[pet.ID] or equippedPetIds[pet.ID] then
            table.insert(newPetsArray, pet)
        end
    end
    
    -- Update data
    profile.Data.Pets = newPetsArray
    profile.Data.ProcessingPets = petsToProcess
    
    -- Auto-sync to client Rodux store  
    self:SyncPlayerDataToClient(player)
    
    return true, {
        processedCount = #petsToProcess,
        newPetCount = #newPetsArray
    }
end

function DataService:CompleteHeavenProcessing(player, moneyReward)
    local profile = Profiles[player]
    if not profile then
        return false, "Player profile not found"
    end
    
    local processedCount = #(profile.Data.ProcessingPets or {})
    
    -- Clear processing pets and add money reward
    profile.Data.ProcessingPets = {}
    profile.Data.Resources.Money = profile.Data.Resources.Money + moneyReward
    profile.Data.ProcessedPets = (profile.Data.ProcessedPets or 0) + processedCount
    
    -- Auto-sync to client Rodux store
    self:SyncPlayerDataToClient(player)
    
    return true, {
        processedCount = processedCount,
        moneyReward = moneyReward,
        totalProcessed = profile.Data.ProcessedPets
    }
end

function DataService:RemovePetById(player, petId)
    local profile = Profiles[player]
    if not profile then
        return false, "Player profile not found"
    end
    
    -- Remove from pets collection
    local newPets = {}
    local found = false
    
    for _, pet in pairs(profile.Data.Pets) do
        if pet.ID ~= petId then
            table.insert(newPets, pet)
        else
            found = true
        end
    end
    
    if found then
        profile.Data.Pets = newPets
        
        -- Also remove from equipped pets if equipped
        self:UnequipPetById(player, petId)
        
        -- Auto-sync to client Rodux store
        self:SyncPlayerDataToClient(player)
        
        return true, "Pet removed successfully"
    end
    
    return false, "Pet not found"
end

function DataService:UpdateProcessingAndMoney(player, newProcessingPets, moneyToAdd, processedCount)
    local profile = Profiles[player]
    if not profile then
        return false, "Player profile not found"
    end
    
    -- Update processing pets
    profile.Data.ProcessingPets = newProcessingPets
    
    -- Add money reward
    if moneyToAdd > 0 then
        profile.Data.Resources.Money = profile.Data.Resources.Money + moneyToAdd
    end
    
    -- Update processed pets counter
    profile.Data.ProcessedPets = (profile.Data.ProcessedPets or 0) + processedCount
    
    -- Auto-sync to client Rodux store
    self:SyncPlayerDataToClient(player)
    
    return true, "Processing and money updated successfully"
end

-- Upgrade crazy chest level with diamond cost
function DataService:UpgradeCrazyChest(player)
    local profile = Profiles[player]
    if not profile then
        return false, "Player profile not found"
    end
    
    -- Get current chest data
    local currentLevel = profile.Data.CrazyChest.Level or 1
    local upgradeCost = currentLevel * 100 -- Cost increases by 100 diamonds per level (100, 200, 300, etc.)
    
    -- Check if player has enough diamonds
    if not profile.Data.Resources.Diamonds or profile.Data.Resources.Diamonds < upgradeCost then
        return false, "Not enough diamonds! Need " .. upgradeCost .. " diamonds."
    end
    
    -- Deduct diamonds and upgrade chest level
    profile.Data.Resources.Diamonds = profile.Data.Resources.Diamonds - upgradeCost
    profile.Data.CrazyChest.Level = currentLevel + 1
    
    -- Auto-sync to client Rodux store
    self:SyncPlayerDataToClient(player)
    
    return true, "Chest upgraded to level " .. (currentLevel + 1) .. "!"
end

-- Get crazy chest level multiplier for rewards
function DataService:GetChestRewardMultiplier(player)
    local profile = Profiles[player]
    if not profile then
        return 1
    end
    
    local chestLevel = profile.Data.CrazyChest.Level or 1
    return 1 + (chestLevel - 1) * 0.6 -- 60% increase per level (1x, 1.6x, 2.2x, 2.8x, etc.)
end

-- Get crazy chest upgrade cost
function DataService:GetChestUpgradeCost(player)
    local profile = Profiles[player]
    if not profile then
        return 250 -- Default cost for level 1
    end
    
    local currentLevel = profile.Data.CrazyChest.Level or 1
    local baseCost = 250 -- Starting cost in diamonds
    return math.floor(baseCost * (1.5 ^ (currentLevel - 1))) -- 50% increase per level
end

-- Upgrade crazy chest luck with diamond cost
function DataService:UpgradeCrazyChestLuck(player)
    local profile = Profiles[player]
    if not profile then
        return false, "Player profile not found"
    end
    
    -- Initialize luck if it doesn't exist (for existing saves)
    if not profile.Data.CrazyChest.Luck then
        profile.Data.CrazyChest.Luck = 1
    end
    
    -- Get current luck level
    local currentLuck = profile.Data.CrazyChest.Luck
    local upgradeCost = currentLuck * 500 -- Cost increases by 500 diamonds per luck level (more expensive than level upgrade)
    
    -- Check if player has enough diamonds
    if not profile.Data.Resources.Diamonds or profile.Data.Resources.Diamonds < upgradeCost then
        return false, "Not enough diamonds! Need " .. upgradeCost .. " diamonds."
    end
    
    -- Deduct diamonds and upgrade luck
    profile.Data.Resources.Diamonds = profile.Data.Resources.Diamonds - upgradeCost
    profile.Data.CrazyChest.Luck = currentLuck + 1
    
    -- Auto-sync to client Rodux store
    self:SyncPlayerDataToClient(player)
    
    return true, "Luck upgraded to level " .. (currentLuck + 1) .. "!"
end

-- Robux version of chest upgrade (no diamond cost)
function DataService:UpgradeCrazyChestRobux(player)
    local profile = Profiles[player]
    if not profile then
        return false, "Player profile not found"
    end
    
    -- Get current chest data
    local currentLevel = profile.Data.CrazyChest.Level or 1
    
    -- No diamond cost check - this is a robux purchase
    -- Upgrade chest level directly
    profile.Data.CrazyChest.Level = currentLevel + 1
    
    -- Auto-sync to client Rodux store
    self:SyncPlayerDataToClient(player)
    
    return true, "Chest upgraded to level " .. (currentLevel + 1) .. " via Robux!"
end

-- Robux version of luck upgrade (no diamond cost)
function DataService:UpgradeCrazyChestLuckRobux(player)
    local profile = Profiles[player]
    if not profile then
        return false, "Player profile not found"
    end
    
    -- Initialize luck if it doesn't exist (for existing saves)
    if not profile.Data.CrazyChest.Luck then
        profile.Data.CrazyChest.Luck = 1
    end
    
    -- Get current luck level
    local currentLuck = profile.Data.CrazyChest.Luck
    
    -- No diamond cost check - this is a robux purchase
    -- Upgrade luck directly
    profile.Data.CrazyChest.Luck = currentLuck + 1
    
    -- Auto-sync to client Rodux store
    self:SyncPlayerDataToClient(player)
    
    return true, "Luck upgraded to level " .. (currentLuck + 1) .. " via Robux!"
end

-- Get crazy chest luck multiplier
function DataService:GetChestLuckMultiplier(player)
    local profile = Profiles[player]
    if not profile then
        return 1
    end
    
    -- Initialize luck if it doesn't exist (for existing saves)
    if not profile.Data.CrazyChest.Luck then
        profile.Data.CrazyChest.Luck = 1
    end
    
    return profile.Data.CrazyChest.Luck
end

-- Get crazy chest luck upgrade cost
function DataService:GetChestLuckUpgradeCost(player)
    local profile = Profiles[player]
    if not profile then
        return 500 -- Default cost for level 1
    end
    
    -- Initialize luck if it doesn't exist
    if not profile.Data.CrazyChest.Luck then
        profile.Data.CrazyChest.Luck = 1
    end
    
    local currentLuck = profile.Data.CrazyChest.Luck
    return currentLuck * 500 -- Cost increases by 500 diamonds per luck level
end

return DataService