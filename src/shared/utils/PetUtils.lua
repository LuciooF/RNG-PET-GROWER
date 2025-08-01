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
    -- Sort by BOOST not value for auto-equip!
    local sortedPets = PetUtils.sortPetsByBoost(pets)
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

-- Convert Color3 to RGB array for DataStore compatibility
function PetUtils.colorToArray(color)
    if not color then return nil end
    if type(color) == "table" then return color end -- Already an array
    
    -- Convert Color3 to RGB array
    return {
        math.floor(color.R * 255),
        math.floor(color.G * 255),
        math.floor(color.B * 255)
    }
end

-- Convert RGB array to Color3 for UI usage
function PetUtils.arrayToColor(colorArray)
    if not colorArray then return Color3.fromRGB(255, 255, 255) end
    if typeof(colorArray) == "Color3" then return colorArray end -- Already a Color3
    
    -- Convert RGB array to Color3
    if type(colorArray) == "table" and #colorArray >= 3 then
        return Color3.fromRGB(colorArray[1], colorArray[2], colorArray[3])
    end
    
    return Color3.fromRGB(255, 255, 255) -- Fallback
end

-- Sanitize pet data for DataStore (convert Color3 to RGB arrays)
function PetUtils.sanitizePetForStorage(pet)
    local sanitized = PetUtils.copyPet(pet)
    
    -- Sanitize rarity colors
    if sanitized.Rarity and sanitized.Rarity.RarityColor then
        sanitized.Rarity.RarityColor = PetUtils.colorToArray(sanitized.Rarity.RarityColor)
    end
    
    -- Sanitize variation colors
    if sanitized.Variation and sanitized.Variation.VariationColor then
        sanitized.Variation.VariationColor = PetUtils.colorToArray(sanitized.Variation.VariationColor)
    end
    
    return sanitized
end

-- Convert pet data from storage (convert RGB arrays to Color3)
function PetUtils.deserializePetFromStorage(pet)
    local deserialized = PetUtils.copyPet(pet)
    
    -- Convert rarity colors
    if deserialized.Rarity and deserialized.Rarity.RarityColor then
        deserialized.Rarity.RarityColor = PetUtils.arrayToColor(deserialized.Rarity.RarityColor)
    end
    
    -- Convert variation colors
    if deserialized.Variation and deserialized.Variation.VariationColor then
        deserialized.Variation.VariationColor = PetUtils.arrayToColor(deserialized.Variation.VariationColor)
    end
    
    return deserialized
end

return PetUtils