-- DataService - Handles player data with ProfileStore
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ProfileService = require(game.ServerStorage.Packages:WaitForChild("profilestore"))
local PetUtils = require(ReplicatedStorage.utils.PetUtils)
local AnnouncementService = require(script.Parent.AnnouncementService)

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
    }
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
    -- Player data initialized successfully
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
        profile.Data.Resources[resourceType] = profile.Data.Resources[resourceType] + amount
        return true
    end
    return false
end

function DataService:SetPlayerResource(player, resourceType, amount)
    local profile = Profiles[player]
    if profile and profile.Data.Resources[resourceType] then
        profile.Data.Resources[resourceType] = amount
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
        return true
    end
    return false
end

function DataService:AddOwnedTube(player, tubeNumber)
    local profile = Profiles[player]
    if profile then
        table.insert(profile.Data.OwnedTubes, tubeNumber)
        return true
    end
    return false
end

function DataService:AddOwnedPlot(player, plotNumber)
    local profile = Profiles[player]
    if profile then
        table.insert(profile.Data.OwnedPlots, plotNumber)
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
    
    -- Schedule new auto-equip after a short delay (0.1 seconds)
    autoEquipDebounceTimers[player] = task.delay(0.1, function()
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
            end
        end
    end)
end

function DataService:ResetPlayerData(player)
    -- Security check: Only allow authorized user
    if player.UserId ~= 7273741008 then
        warn("DataService: Unauthorized reset data request from", player.Name, "UserID:", player.UserId)
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
        
        print("DataService: Reset player data for", player.Name, "- including pet index, tutorial, and all progress")
        return true
    end
    return false
end

return DataService