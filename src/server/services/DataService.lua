local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Packages = ServerStorage:WaitForChild("Packages")
local ProfileStore = require(Packages.profilestore)
local RebirthConfig = require(ReplicatedStorage.Shared.config.RebirthConfig)

local DataService = {}
DataService.__index = DataService

-- Configuration
local PET_INVENTORY_CAP = 1000 -- Maximum pets a player can hold

local PROFILE_TEMPLATE = {
    resources = {
        money = 100, -- Start with some money for testing
        rebirths = 0,
        diamonds = 10, -- Start with some diamonds for testing
    },
    boughtPlots = {},
    boughtProductionPlots = {},
    ownedPets = {},
    discoveredCombinations = {},
    companionPets = {},
    activeBoosts = {},
    ownedGamepasses = {}, -- Store owned gamepasses with purchase info
    temporaryEffects = {}, -- Store temporary effects from developer products
    settings = {
        musicEnabled = true,
        sfxEnabled = true,
    },
    stats = {
        playtime = 0,
        joins = 0,
        totalPetsCollected = 0,
        totalRebirths = 0,
        totalMoneySpent = 0,
        totalDiamondsSpent = 0,
    },
    heavenQueue = {
        pets = {}, -- Array of pets waiting to be processed
        lastProcessTime = 0 -- Timestamp of last processing
    }
}

-- Create ProfileStore instance
local PlayerProfileStore = ProfileStore.New("PlayerData_v1", PROFILE_TEMPLATE)

local Profiles = {}

function DataService:GetProfile(player)
    return Profiles[player]
end

function DataService:GetAllProfiles()
    return Profiles
end

function DataService:LoadProfile(player)
    local profile = PlayerProfileStore:StartSessionAsync(tostring(player.UserId))
    
    if profile then
        Profiles[player] = profile
        
        -- Initialize stats
        profile.Data.stats.joins = profile.Data.stats.joins + 1
        
        -- Migrate existing pets to have unique IDs if they don't have them
        self:MigratePetUniqueIds(player)
        
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

-- Add money with rebirth multiplier applied
function DataService:AddMoney(player, baseAmount)
    local multipliedAmount = 0
    local result = self:UpdateData(player, "resources", function(resources)
        -- Apply rebirth multiplier to the base amount
        multipliedAmount = RebirthConfig:CalculateMoneyWithMultiplier(baseAmount, resources.rebirths or 0)
        resources.money = resources.money + multipliedAmount
        return resources
    end)
    return result
end

-- Add raw money without multiplier (for internal use only)
function DataService:AddRawMoney(player, amount)
    local result = self:UpdateData(player, "resources", function(resources)
        resources.money = resources.money + amount
        return resources
    end)
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
    return result
end

-- Perform a rebirth: increase rebirths by 1, reset money to starting amount, and reset purchased plots
function DataService:PerformRebirth(player)
    local profile = self:GetProfile(player)
    if not profile then
        return false
    end
    
    -- Update resources (rebirths and money)
    local resourceResult = self:UpdateData(player, "resources", function(resources)
        -- Increase rebirth count
        resources.rebirths = resources.rebirths + 1
        -- Reset money to rebirth amount
        resources.money = RebirthConfig.REBIRTH_MONEY_RESET
        return resources
    end)
    
    if resourceResult then
        -- Reset purchased plots so player can buy new rarity spawners
        profile.Data.boughtPlots = {}
        
        -- Also reset production plots if they exist
        profile.Data.boughtProductionPlots = {}
        
        print(string.format("DataService:PerformRebirth - %s rebirthed (rebirths: %d, money reset to %d, plots reset)", 
            player.Name, resourceResult.rebirths, resourceResult.money))
    end
    
    return resourceResult
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
        return profile.Data
    end
    return nil
end

function DataService:AddPet(player, petData)
    return self:UpdateData(player, "ownedPets", function(ownedPets)
        -- Calculate actual inventory capacity (including gamepass bonuses)
        local actualCapacity = self:GetPlayerInventoryCapacity(player)
        
        -- Check if inventory is at capacity
        if #ownedPets >= actualCapacity then
            warn(string.format("DataService: Player %s inventory at capacity (%d/%d)", 
                player.Name, #ownedPets, actualCapacity))
            return ownedPets -- Don't add pet, inventory full
        end
        
        table.insert(ownedPets, petData)
        return ownedPets
    end)
end

-- Get player's actual inventory capacity (base + gamepass bonuses + temporary effects)
function DataService:GetPlayerInventoryCapacity(player)
    local baseCapacity = PET_INVENTORY_CAP
    local actualCapacity = baseCapacity
    
    local profile = self:GetProfile(player)
    if not profile then
        return baseCapacity
    end
    
    -- Check for gamepass bonuses (PetCollector doubles capacity)
    local ownedGamepasses = profile.Data.ownedGamepasses or {}
    if ownedGamepasses.PetCollector then
        actualCapacity = actualCapacity * 2 -- 2000 instead of 1000
    end
    
    -- Check for temporary effects (like max inventory dev product)
    local temporaryEffects = profile.Data.temporaryEffects or {}
    if temporaryEffects.expandedInventory then
        local expansion = temporaryEffects.expandedInventory
        if expansion.expirationTime > tick() then
            actualCapacity = actualCapacity + (expansion.additionalSpace or 0)
        else
            -- Effect expired, clean it up
            temporaryEffects.expandedInventory = nil
            profile.Data.temporaryEffects = temporaryEffects
        end
    end
    
    return actualCapacity
end

-- Get pet inventory count and capacity info
function DataService:GetPetInventoryInfo(player)
    local profile = self:GetProfile(player)
    if profile then
        local ownedPets = profile.Data.ownedPets or {}
        local actualCapacity = self:GetPlayerInventoryCapacity(player)
        return {
            count = #ownedPets,
            capacity = actualCapacity,
            baseCapacity = PET_INVENTORY_CAP,
            isFull = #ownedPets >= actualCapacity
        }
    end
    return {
        count = 0,
        capacity = PET_INVENTORY_CAP,
        baseCapacity = PET_INVENTORY_CAP,
        isFull = false
    }
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
        
        -- Update cache for faster future lookups
        local profile = self:GetProfile(player)
        if profile and profile.Data._discoveryCache then
            profile.Data._discoveryCache[combination] = true
        end
        
        return discovered
    end)
end

function DataService:HasDiscoveredCombination(player, combination)
    local profile = self:GetProfile(player)
    if not profile then return false end
    
    local discovered = profile.Data.discoveredCombinations or {}
    
    -- Convert to hash table lookup for O(1) performance instead of O(n)
    if not profile.Data._discoveryCache then
        profile.Data._discoveryCache = {}
        for _, combo in ipairs(discovered) do
            profile.Data._discoveryCache[combo] = true
        end
    end
    
    return profile.Data._discoveryCache[combination] == true
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

function DataService:AddProductionPlot(player, plotId)
    return self:UpdateData(player, "boughtProductionPlots", function(boughtProductionPlots)
        table.insert(boughtProductionPlots, plotId)
        return boughtProductionPlots
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

function DataService:AssignPet(player, petUniqueId)
    local profile = self:GetProfile(player)
    if not profile then return false end
    
    -- Check if player already has 3 assigned pets
    local companionPets = profile.Data.companionPets or {}
    if #companionPets >= 3 then
        return false -- Already at maximum
    end
    
    -- Find the pet in owned pets
    local ownedPets = profile.Data.ownedPets or {}
    local targetPet = nil
    
    for _, pet in ipairs(ownedPets) do
        if pet.uniqueId == petUniqueId then
            targetPet = pet
            break
        end
    end
    
    if not targetPet then
        return false -- Pet not found
    end
    
    -- Check if pet is already assigned
    for _, assignedPet in ipairs(companionPets) do
        if assignedPet.uniqueId == petUniqueId then
            return false -- Pet already assigned
        end
    end
    
    -- Add to companionPets
    table.insert(companionPets, targetPet)
    profile.Data.companionPets = companionPets
    
    return true
end

function DataService:UnassignPet(player, petUniqueId)
    local profile = self:GetProfile(player)
    if not profile then return false end
    
    local companionPets = profile.Data.companionPets or {}
    
    -- Find and remove the pet from companionPets
    for i, assignedPet in ipairs(companionPets) do
        if assignedPet.uniqueId == petUniqueId then
            table.remove(companionPets, i)
            profile.Data.companionPets = companionPets
            return true
        end
    end
    
    return false -- Pet not found in assigned pets
end

function DataService:MigratePetUniqueIds(player)
    local profile = self:GetProfile(player)
    if not profile then return end
    
    local ownedPets = profile.Data.ownedPets or {}
    local HttpService = game:GetService("HttpService")
    local needsUpdate = false
    
    -- Add unique IDs to pets that don't have them
    for _, pet in ipairs(ownedPets) do
        if not pet.uniqueId then
            pet.uniqueId = HttpService:GenerateGUID(false)
            needsUpdate = true
        end
    end
    
    if needsUpdate then
        print("DataService: Migrated", #ownedPets, "pets to have unique IDs for", player.Name)
    end
end

function DataService:SellUnassignedPets(player, petsToSell, expectedValue)
    local profile = self:GetProfile(player)
    if not profile then
        return false, 0
    end
    
    local PetConfig = require(ReplicatedStorage.Shared.config.PetConfig)
    local ownedPets = profile.Data.ownedPets or {}
    local companionPets = profile.Data.companionPets or {}
    
    -- Create lookup table for assigned pets
    local assignedPetIds = {}
    for _, assignedPet in ipairs(companionPets) do
        if assignedPet.uniqueId then
            assignedPetIds[assignedPet.uniqueId] = true
        end
    end
    
    -- Create lookup table for pets to sell
    local sellPetIds = {}
    for _, sellPet in ipairs(petsToSell) do
        if sellPet.uniqueId then
            sellPetIds[sellPet.uniqueId] = true
        end
    end
    
    -- Validate and calculate actual value
    local actualValue = 0
    local validPetsToSell = {}
    
    for _, pet in ipairs(ownedPets) do
        if pet.uniqueId and sellPetIds[pet.uniqueId] then
            -- Check that this pet is not assigned
            if not assignedPetIds[pet.uniqueId] then
                -- Calculate authoritative pet value
                local petValue = PetConfig:CalculatePetValue(pet.id or 1, pet.aura, pet.size)
                actualValue = actualValue + petValue
                table.insert(validPetsToSell, pet)
            else
                warn("DataService:SellUnassignedPets - Attempted to sell assigned pet:", pet.name, "from", player.Name)
                return false, 0 -- Reject entire transaction if trying to sell assigned pet
            end
        end
    end
    
    -- Security check: Verify expected value matches calculated value (within 10% tolerance)
    local tolerance = math.max(1, expectedValue * 0.1)
    if math.abs(actualValue - expectedValue) > tolerance then
        warn(string.format("DataService:SellUnassignedPets - Value mismatch for %s: expected %d, calculated %d", 
            player.Name, expectedValue, actualValue))
        return false, 0
    end
    
    if #validPetsToSell == 0 then
        print("DataService:SellUnassignedPets - No valid pets to sell for", player.Name)
        return false, 0
    end
    
    -- Remove sold pets from owned pets
    local remainingPets = {}
    for _, pet in ipairs(ownedPets) do
        if not (pet.uniqueId and sellPetIds[pet.uniqueId]) then
            table.insert(remainingPets, pet)
        end
    end
    
    -- Remove sold pets from owned pets
    profile.Data.ownedPets = remainingPets
    
    -- Add pets to heaven processing queue instead of giving money immediately
    if not profile.Data.heavenQueue then
        profile.Data.heavenQueue = {pets = {}, lastProcessTime = 0}
    end
    
    for _, pet in ipairs(validPetsToSell) do
        -- Get pet config for asset path
        local petData = PetConfig:GetPetData(pet.id or 1)
        local queuedPet = {
            uniqueId = pet.uniqueId,
            name = pet.name,
            value = PetConfig:CalculatePetValue(pet.id or 1, pet.aura, pet.size),
            id = pet.id,
            aura = pet.aura,
            size = pet.size,
            assetPath = petData and petData.assetPath or ("Pets/" .. (pet.name or "Unknown")),
            queuedAt = tick()
        }
        table.insert(profile.Data.heavenQueue.pets, queuedPet)
    end
    
    print(string.format("DataService:SellUnassignedPets - %s queued %d pets for processing (had %d, now has %d pets, queue size: %d)", 
        player.Name, #validPetsToSell, #ownedPets, #remainingPets, #profile.Data.heavenQueue.pets))
    
    return true, actualValue
end

return DataService