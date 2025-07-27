-- DataService - Handles player data with ProfileStore
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ProfileService = require(game.ServerStorage.Packages:WaitForChild("profilestore"))

local DataService = {}
DataService.__index = DataService

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
    OwnedTubes = {}, -- Array of tube numbers
    OwnedPlots = {} -- Array of plot numbers
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
        table.insert(profile.Data.Pets, petData)
        return true
    end
    return false
end

function DataService:EquipPet(player, petData)
    local profile = Profiles[player]
    if profile then
        table.insert(profile.Data.EquippedPets, petData)
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

function DataService:AddPetToPlayer(player, petData)
    local profile = Profiles[player]
    if profile then
        -- Ensure pet has an ID
        if not petData.ID then
            petData.ID = game:GetService("HttpService"):GenerateGUID(false)
        end
        
        table.insert(profile.Data.Pets, petData)
        return true
    end
    return false
end

function DataService:ResetPlayerData(player)
    local profile = Profiles[player]
    if profile then
        -- Reset data to template values
        profile.Data.Resources = {
            Diamonds = 0,
            Money = 0, -- Starting money
            Rebirths = 0
        }
        profile.Data.Pets = {}
        profile.Data.EquippedPets = {}
        profile.Data.ProcessingPets = {}
        profile.Data.OwnedTubes = {}
        profile.Data.OwnedPlots = {}
        
        print("DataService: Reset player data for", player.Name)
        return true
    end
    return false
end

return DataService