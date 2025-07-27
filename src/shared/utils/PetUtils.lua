-- Pet utility functions
local PetConstants = require(script.Parent.Parent.constants.PetConstants)
local PetConfig = require(script.Parent.Parent.config.PetConfig)

local PetUtils = {}

-- Format pet display name with variation
function PetUtils.getDisplayName(pet)
    if pet.Variation == PetConstants.Variation.BRONZE then
        return pet.Name
    else
        return pet.Variation .. " " .. pet.Name
    end
end

-- Get pet's display color (prioritize variation, fallback to rarity)
function PetUtils.getDisplayColor(pet)
    if pet.Variation ~= PetConstants.Variation.BRONZE then
        return PetConstants.getVariationColor(pet.Variation)
    else
        return PetConstants.getRarityColor(pet.Rarity)
    end
end

-- Calculate total boost from a list of pets
function PetUtils.calculateTotalBoost(pets)
    local totalBoost = 1.0
    
    for _, pet in pairs(pets) do
        if pet.FinalBoost then
            totalBoost = totalBoost * pet.FinalBoost
        end
    end
    
    return totalBoost
end

-- Calculate total value from a list of pets
function PetUtils.calculateTotalValue(pets)
    local totalValue = 0
    
    for _, pet in pairs(pets) do
        if pet.FinalValue then
            totalValue = totalValue + pet.FinalValue
        end
    end
    
    return totalValue
end

-- Sort pets by value (highest first)
function PetUtils.sortPetsByValue(pets)
    local sortedPets = {}
    for _, pet in pairs(pets) do
        table.insert(sortedPets, pet)
    end
    
    table.sort(sortedPets, function(a, b)
        return (a.FinalValue or 0) > (b.FinalValue or 0)
    end)
    
    return sortedPets
end

-- Sort pets by boost (highest first)
function PetUtils.sortPetsByBoost(pets)
    local sortedPets = {}
    for _, pet in pairs(pets) do
        table.insert(sortedPets, pet)
    end
    
    table.sort(sortedPets, function(a, b)
        return (a.FinalBoost or 0) > (b.FinalBoost or 0)
    end)
    
    return sortedPets
end

-- Sort pets by rarity and variation (rarest first)
function PetUtils.sortPetsByRarity(pets)
    local rarityOrder = {
        [PetConstants.Rarity.MYTHIC] = 6,
        [PetConstants.Rarity.LEGENDARY] = 5,
        [PetConstants.Rarity.EPIC] = 4,
        [PetConstants.Rarity.RARE] = 3,
        [PetConstants.Rarity.UNCOMMON] = 2,
        [PetConstants.Rarity.COMMON] = 1
    }
    
    local variationOrder = {
        [PetConstants.Variation.RAINBOW] = 6,
        [PetConstants.Variation.DIAMOND] = 5,
        [PetConstants.Variation.EMERALD] = 4,
        [PetConstants.Variation.GOLD] = 3,
        [PetConstants.Variation.SILVER] = 2,
        [PetConstants.Variation.BRONZE] = 1
    }
    
    local sortedPets = {}
    for _, pet in pairs(pets) do
        table.insert(sortedPets, pet)
    end
    
    table.sort(sortedPets, function(a, b)
        local aRarityScore = rarityOrder[a.Rarity] or 0
        local bRarityScore = rarityOrder[b.Rarity] or 0
        
        if aRarityScore ~= bRarityScore then
            return aRarityScore > bRarityScore
        end
        
        local aVariationScore = variationOrder[a.Variation] or 0
        local bVariationScore = variationOrder[b.Variation] or 0
        
        return aVariationScore > bVariationScore
    end)
    
    return sortedPets
end

-- Check if a pet is better than another (by value + boost combined)
function PetUtils.isPetBetter(petA, petB)
    local scoreA = (petA.FinalValue or 0) + ((petA.FinalBoost or 1) - 1) * 1000
    local scoreB = (petB.FinalValue or 0) + ((petB.FinalBoost or 1) - 1) * 1000
    
    return scoreA > scoreB
end

-- Get best pets from a collection (for auto-equip)
function PetUtils.getBestPets(pets, maxCount)
    local sortedPets = PetUtils.sortPetsByValue(pets)
    local bestPets = {}
    
    for i = 1, math.min(maxCount, #sortedPets) do
        table.insert(bestPets, sortedPets[i])
    end
    
    return bestPets
end

-- Validate pet data
function PetUtils.isValidPet(pet)
    if not pet or type(pet) ~= "table" then
        return false
    end
    
    local required = {"ID", "Name", "Rarity", "Variation", "BaseValue", "BaseBoost"}
    for _, field in pairs(required) do
        if pet[field] == nil then
            return false
        end
    end
    
    return true
end

-- Create a deep copy of a pet
function PetUtils.copyPet(pet)
    local copy = {}
    for key, value in pairs(pet) do
        copy[key] = value
    end
    return copy
end

return PetUtils