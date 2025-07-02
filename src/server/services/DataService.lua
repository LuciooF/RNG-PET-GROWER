local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Packages = ServerStorage:WaitForChild("Packages")
local ProfileStore = require(Packages.profilestore)

local DataService = {}
DataService.__index = DataService

local PROFILE_TEMPLATE = {
    resources = {
        money = 100, -- Start with some money for testing
        rebirths = 0,
        diamonds = 10, -- Start with some diamonds for testing
    },
    boughtPlots = {},
    ownedPets = {},
    discoveredCombinations = {},
    companionPets = {},
    activeBoosts = {},
    settings = {
        musicEnabled = true,
        sfxEnabled = true,
    },
    stats = {
        playtime = 0,
        joins = 0,
        totalPetsCollected = 0,
        totalRebirths = 0,
    }
}

-- Create ProfileStore instance
local PlayerProfileStore = ProfileStore.New("PlayerData_v1", PROFILE_TEMPLATE)

local Profiles = {}

function DataService:GetProfile(player)
    return Profiles[player]
end

function DataService:LoadProfile(player)
    local profile = PlayerProfileStore:StartSessionAsync(tostring(player.UserId))
    
    if profile then
        Profiles[player] = profile
        
        -- Initialize stats
        profile.Data.stats.joins = profile.Data.stats.joins + 1
        
        self:CleanupExpiredBoosts(player)
        
        print("Loaded ProfileStore data for player:", player.Name, "Money:", profile.Data.resources.money)
        return profile
    else
        player:Kick("Failed to load data")
        return nil
    end
end

function DataService:ReleaseProfile(player)
    local profile = Profiles[player]
    if profile then
        print("Releasing ProfileStore data for player:", player.Name)
        -- Check what methods are available on the profile
        print("Profile methods:")
        for key, value in pairs(profile) do
            if type(value) == "function" then
                print("  " .. tostring(key) .. ": function")
            end
        end
        
        -- Try different release methods
        if profile.Release then
            profile:Release()
        elseif profile.EndSession then
            profile:EndSession()
        elseif profile.Close then
            profile:Close()
        else
            print("No known release method found")
        end
        
        Profiles[player] = nil
    end
end

function DataService:GetData(player, key)
    local profile = self:GetProfile(player)
    if profile then
        return profile.Data[key]
    end
    return nil
end

function DataService:GetPlayerData(player)
    local profile = self:GetProfile(player)
    if profile then
        return profile.Data
    end
    return nil
end

function DataService:SetData(player, key, value)
    local profile = self:GetProfile(player)
    if profile then
        profile.Data[key] = value
        return true
    end
    return false
end

function DataService:UpdateData(player, key, callback)
    local profile = self:GetProfile(player)
    if profile then
        local newValue = callback(profile.Data[key])
        profile.Data[key] = newValue
        return newValue
    end
    return nil
end

function DataService:AddMoney(player, amount)
    local result = self:UpdateData(player, "resources", function(resources)
        resources.money = resources.money + amount
        return resources
    end)
    if result then
        print("Added", amount, "money to", player.Name, "New total:", result.money)
    end
    return result
end

function DataService:SpendMoney(player, amount)
    return self:UpdateData(player, "resources", function(resources)
        if resources.money >= amount then
            resources.money = resources.money - amount
            return resources
        end
        return resources
    end)
end

function DataService:AddDiamonds(player, amount)
    local result = self:UpdateData(player, "resources", function(resources)
        resources.diamonds = resources.diamonds + amount
        return resources
    end)
    if result then
        print("Added", amount, "diamonds to", player.Name, "New total:", result.diamonds)
    end
    return result
end

function DataService:SpendDiamonds(player, amount)
    return self:UpdateData(player, "resources", function(resources)
        if resources.diamonds >= amount then
            resources.diamonds = resources.diamonds - amount
            return resources
        end
        return resources
    end)
end

function DataService:AddRebirths(player, amount)
    local result = self:UpdateData(player, "resources", function(resources)
        resources.rebirths = resources.rebirths + amount
        return resources
    end)
    if result then
        print("Added", amount, "rebirths to", player.Name, "New total:", result.rebirths)
    end
    return result
end

function DataService:ResetPlayerData(player)
    local profile = self:GetProfile(player)
    if profile then
        -- Reset to template data
        for key, value in pairs(PROFILE_TEMPLATE) do
            if type(value) == "table" then
                profile.Data[key] = {}
                for subKey, subValue in pairs(value) do
                    profile.Data[key][subKey] = subValue
                end
            else
                profile.Data[key] = value
            end
        end
        print("Reset data for player:", player.Name, "- discovered combinations cleared:", #(profile.Data.discoveredCombinations or {}))
        return profile.Data
    end
    return nil
end

function DataService:AddPet(player, petData)
    return self:UpdateData(player, "ownedPets", function(ownedPets)
        table.insert(ownedPets, petData)
        return ownedPets
    end)
end

function DataService:AddDiscoveredCombination(player, combination)
    return self:UpdateData(player, "discoveredCombinations", function(discovered)
        -- Check if already discovered
        for _, combo in ipairs(discovered) do
            if combo == combination then
                return discovered -- Already discovered, no change
            end
        end
        -- New discovery!
        table.insert(discovered, combination)
        return discovered
    end)
end

function DataService:HasDiscoveredCombination(player, combination)
    local profile = self:GetProfile(player)
    if not profile then return false end
    
    local discovered = profile.Data.discoveredCombinations or {}
    for _, combo in ipairs(discovered) do
        if combo == combination then
            return true
        end
    end
    return false
end

function DataService:RemovePet(player, petId)
    return self:UpdateData(player, "ownedPets", function(ownedPets)
        for i, pet in ipairs(ownedPets) do
            if pet.id == petId then
                table.remove(ownedPets, i)
                break
            end
        end
        return ownedPets
    end)
end

function DataService:AddPlot(player, plotId)
    return self:UpdateData(player, "boughtPlots", function(boughtPlots)
        table.insert(boughtPlots, plotId)
        return boughtPlots
    end)
end

function DataService:AddBoost(player, boostData)
    return self:UpdateData(player, "activeBoosts", function(activeBoosts)
        table.insert(activeBoosts, boostData)
        return activeBoosts
    end)
end

function DataService:CleanupExpiredBoosts(player)
    local currentTime = tick()
    return self:UpdateData(player, "activeBoosts", function(activeBoosts)
        local newBoosts = {}
        for _, boost in ipairs(activeBoosts) do
            if boost.endsAtTimeStamp > currentTime then
                table.insert(newBoosts, boost)
            end
        end
        return newBoosts
    end)
end

function DataService:UpdatePlaytime(player, deltaTime)
    return self:UpdateData(player, "stats", function(stats)
        stats.playtime = stats.playtime + deltaTime
        return stats
    end)
end

return DataService