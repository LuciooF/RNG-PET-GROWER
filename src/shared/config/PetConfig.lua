-- Pet configuration and data
local PetConstants = require(script.Parent.Parent.constants.PetConstants)

local PetConfig = {}

-- Pet data structure template
PetConfig.PetTemplate = {
    Name = "",
    Rarity = PetConstants.Rarity.COMMON,
    Variation = PetConstants.Variation.BRONZE,
    BaseValue = 0,
    BaseBoost = 0,
    -- Runtime properties (added when pet is created)
    ID = nil,          -- Unique identifier
    FinalValue = 0,    -- BaseValue * VariationMultiplier
    FinalBoost = 0     -- BaseBoost * VariationMultiplier
}

-- Base pet definitions (3 pets, 3 rarities each)
PetConfig.BasePets = {
    -- Common Pets
    {
        Name = "Dog",
        Rarity = PetConstants.Rarity.COMMON,
        BaseValue = 100,
        BaseBoost = 1.1
    },
    {
        Name = "Cat",
        Rarity = PetConstants.Rarity.COMMON,
        BaseValue = 120,
        BaseBoost = 1.15
    },
    {
        Name = "Lizard",
        Rarity = PetConstants.Rarity.COMMON,
        BaseValue = 90,
        BaseBoost = 1.08
    },
    
    -- Uncommon Pets
    {
        Name = "Dog",
        Rarity = PetConstants.Rarity.UNCOMMON,
        BaseValue = 250,
        BaseBoost = 1.25
    },
    {
        Name = "Cat",
        Rarity = PetConstants.Rarity.UNCOMMON,
        BaseValue = 300,
        BaseBoost = 1.3
    },
    {
        Name = "Lizard",
        Rarity = PetConstants.Rarity.UNCOMMON,
        BaseValue = 200,
        BaseBoost = 1.2
    },
    
    -- Rare Pets
    {
        Name = "Dog",
        Rarity = PetConstants.Rarity.RARE,
        BaseValue = 500,
        BaseBoost = 1.5
    },
    {
        Name = "Cat",
        Rarity = PetConstants.Rarity.RARE,
        BaseValue = 600,
        BaseBoost = 1.6
    },
    {
        Name = "Lizard",
        Rarity = PetConstants.Rarity.RARE,
        BaseValue = 450,
        BaseBoost = 1.4
    }
}

-- Pet creation functions
function PetConfig.createPet(basePetData, variation, id)
    variation = variation or PetConstants.Variation.BRONZE
    id = id or game:GetService("HttpService"):GenerateGUID(false)
    
    local multiplier = PetConstants.getVariationMultiplier(variation)
    
    local pet = {
        ID = id,
        Name = basePetData.Name,
        Rarity = basePetData.Rarity,
        Variation = variation,
        BaseValue = basePetData.BaseValue,
        BaseBoost = basePetData.BaseBoost,
        FinalValue = math.floor(basePetData.BaseValue * multiplier),
        FinalBoost = basePetData.BaseBoost * multiplier
    }
    
    return pet
end

function PetConfig.createRandomPet(rarityWeights, variationWeights)
    -- Default weights if not provided
    rarityWeights = rarityWeights or {
        [PetConstants.Rarity.COMMON] = 60,
        [PetConstants.Rarity.UNCOMMON] = 30,
        [PetConstants.Rarity.RARE] = 10
    }
    
    variationWeights = variationWeights or {
        [PetConstants.Variation.BRONZE] = 50,
        [PetConstants.Variation.SILVER] = 35,
        [PetConstants.Variation.GOLD] = 15
    }
    
    -- Select random rarity
    local selectedRarity = PetConfig.weightedRandomSelect(rarityWeights)
    
    -- Get pets of selected rarity
    local petsOfRarity = {}
    for _, basePet in pairs(PetConfig.BasePets) do
        if basePet.Rarity == selectedRarity then
            table.insert(petsOfRarity, basePet)
        end
    end
    
    if #petsOfRarity == 0 then
        warn("No pets found for rarity: " .. selectedRarity)
        return nil
    end
    
    -- Select random pet from rarity
    local randomPet = petsOfRarity[math.random(1, #petsOfRarity)]
    
    -- Select random variation
    local selectedVariation = PetConfig.weightedRandomSelect(variationWeights)
    
    return PetConfig.createPet(randomPet, selectedVariation)
end

function PetConfig.weightedRandomSelect(weights)
    local totalWeight = 0
    for _, weight in pairs(weights) do
        totalWeight = totalWeight + weight
    end
    
    local randomValue = math.random() * totalWeight
    local currentWeight = 0
    
    for item, weight in pairs(weights) do
        currentWeight = currentWeight + weight
        if randomValue <= currentWeight then
            return item
        end
    end
    
    -- Fallback (should never reach here)
    local firstKey = next(weights)
    return firstKey
end

function PetConfig.getPetsByRarity(rarity)
    local pets = {}
    for _, basePet in pairs(PetConfig.BasePets) do
        if basePet.Rarity == rarity then
            table.insert(pets, basePet)
        end
    end
    return pets
end

function PetConfig.getBasePetByName(name)
    for _, basePet in pairs(PetConfig.BasePets) do
        if basePet.Name == name then
            return basePet
        end
    end
    return nil
end

return PetConfig