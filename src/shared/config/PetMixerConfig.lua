-- PetMixerConfig - Configuration for pet mixing system
local PetMixerConfig = {}

-- Mixer structure template
-- {
--     id = "unique-mixer-id",
--     inputPets = {pet1, pet2, pet3...}, -- Array of pets being mixed (removed from inventory)
--     outputPet = {Name = "Dragon", Rarity = {...}, ...}, -- The resulting pet
--     startTime = 1234567890, -- Unix timestamp when mixing started
--     completionTime = 1234567920, -- Unix timestamp when mixing will complete
--     claimed = false -- Whether the output has been claimed
-- }

-- Base mixing times in seconds - 1 minute per pet
PetMixerConfig.BASE_MIX_TIME = 60 -- Base time for mixing 1 pet (60 seconds = 1 minute)
PetMixerConfig.TIME_PER_ADDITIONAL_PET = 60 -- 60 seconds per additional pet (1 minute each)
PetMixerConfig.MIN_PETS_PER_MIX = 2 -- Minimum pets required for mixing
PetMixerConfig.MAX_PETS_PER_MIX = 20 -- Maximum pets that can be mixed at once
PetMixerConfig.MAX_ACTIVE_MIXERS = 3 -- Maximum number of mixers running at once

-- Diamond costs for mixing - 100 diamonds per pet
PetMixerConfig.DIAMONDS_PER_PET = 100 -- 100 diamonds per pet (2 pets = 200, 10 pets = 1000, etc.)

-- Calculate mixing time based on number of pets
function PetMixerConfig.calculateMixTime(petCount)
    if petCount <= 0 then return 0 end
    if petCount > PetMixerConfig.MAX_PETS_PER_MIX then
        petCount = PetMixerConfig.MAX_PETS_PER_MIX
    end
    
    -- Simple calculation: 1 minute (60 seconds) per pet
    return petCount * 60
end

-- Calculate diamond cost based on number of pets
function PetMixerConfig.calculateDiamondCost(petCount)
    if petCount < PetMixerConfig.MIN_PETS_PER_MIX then return 0 end
    if petCount > PetMixerConfig.MAX_PETS_PER_MIX then
        petCount = PetMixerConfig.MAX_PETS_PER_MIX
    end
    
    -- Simple calculation: 100 diamonds per pet
    return petCount * PetMixerConfig.DIAMONDS_PER_PET
end

-- Rarity upgrade chances (when mixing same rarity pets)
PetMixerConfig.RARITY_UPGRADE_CHANCES = {
    Common = {
        upgradeChance = 0.8, -- 80% chance to upgrade to Uncommon
        bonusChancePerExtraPet = 0.02 -- +2% per additional pet
    },
    Uncommon = {
        upgradeChance = 0.6, -- 60% chance to upgrade to Rare
        bonusChancePerExtraPet = 0.03 -- +3% per additional pet
    },
    Rare = {
        upgradeChance = 0.4, -- 40% chance to upgrade to Epic
        bonusChancePerExtraPet = 0.04 -- +4% per additional pet
    },
    Epic = {
        upgradeChance = 0.2, -- 20% chance to upgrade to Legendary
        bonusChancePerExtraPet = 0.05 -- +5% per additional pet
    },
    Legendary = {
        upgradeChance = 0.1, -- 10% chance to upgrade to Mythic
        bonusChancePerExtraPet = 0.05 -- +5% per additional pet
    },
    Mythic = {
        upgradeChance = 0.05, -- 5% chance to get special variant
        bonusChancePerExtraPet = 0.025 -- +2.5% per additional pet
    }
}

-- Rarity progression order
PetMixerConfig.RARITY_ORDER = {
    "Common",
    "Uncommon", 
    "Rare",
    "Epic",
    "Legendary",
    "Mythic"
}

-- Get next rarity in progression
function PetMixerConfig.getNextRarity(currentRarity)
    for i, rarity in ipairs(PetMixerConfig.RARITY_ORDER) do
        if rarity == currentRarity and i < #PetMixerConfig.RARITY_ORDER then
            return PetMixerConfig.RARITY_ORDER[i + 1]
        end
    end
    return currentRarity -- Return same if at max
end

-- Calculate boost multiplier for mixed pet
function PetMixerConfig.calculateMixedPetBoost(inputPets)
    if #inputPets == 0 then return 1 end
    
    -- Get the BEST boost among input pets (not average)
    local bestBoost = 0
    for _, pet in ipairs(inputPets) do
        local petBoost = pet.FinalBoost or pet.BaseBoost or 1
        if petBoost > bestBoost then
            bestBoost = petBoost
        end
    end
    
    -- Add bonus based on number of pets mixed (10% per pet, compounding)
    -- This ensures boost ALWAYS increases with more pets
    local bonusMultiplier = math.pow(1.1, #inputPets) -- 1.1^n gives compounding bonus
    
    return math.floor(bestBoost * bonusMultiplier * 100) / 100 -- Round to 2 decimals
end

-- Calculate value multiplier for mixed pet (in diamonds, much cheaper)
function PetMixerConfig.calculateMixedPetValue(inputPets)
    if #inputPets == 0 then return 1 end
    
    -- Sum the values of all input pets and convert to diamonds (divide by 100)
    local totalValue = 0
    for _, pet in ipairs(inputPets) do
        totalValue = totalValue + (pet.FinalValue or pet.BaseValue or 1)
    end
    
    -- Convert to diamonds (much cheaper - divide by 50)
    local diamondValue = math.floor(totalValue / 50)
    
    -- Add bonus based on number of pets mixed (15% per pet)
    local bonusMultiplier = 1 + (#inputPets * 0.15)
    
    return math.max(1, math.floor(diamondValue * bonusMultiplier)) -- Minimum 1 diamond
end

-- Special mixing recipes (specific combinations that guarantee certain pets)
PetMixerConfig.SPECIAL_RECIPES = {
    -- Example: 3 Dogs + 2 Cats = Guaranteed Wolf
    {
        ingredients = {
            {name = "Dog", count = 3},
            {name = "Cat", count = 2}
        },
        result = "Wolf",
        resultRarity = "Epic"
    },
    -- Example: 5 of any same pet = Guaranteed next tier of that pet
    {
        ingredients = {
            {name = "ANY_SAME", count = 5}
        },
        result = "UPGRADE_SAME", -- Special flag to upgrade the same pet type
        resultRarity = "NEXT_TIER"
    }
}

-- Check if pets match a special recipe
function PetMixerConfig.checkSpecialRecipe(inputPets)
    -- Count pets by name
    local petCounts = {}
    for _, pet in ipairs(inputPets) do
        petCounts[pet.Name] = (petCounts[pet.Name] or 0) + 1
    end
    
    -- Check each recipe
    for _, recipe in ipairs(PetMixerConfig.SPECIAL_RECIPES) do
        local matches = true
        
        for _, ingredient in ipairs(recipe.ingredients) do
            if ingredient.name == "ANY_SAME" then
                -- Check if any pet type has the required count
                local foundMatch = false
                for petName, count in pairs(petCounts) do
                    if count >= ingredient.count then
                        foundMatch = true
                        break
                    end
                end
                if not foundMatch then
                    matches = false
                    break
                end
            else
                -- Check specific pet count
                if (petCounts[ingredient.name] or 0) < ingredient.count then
                    matches = false
                    break
                end
            end
        end
        
        if matches then
            return recipe
        end
    end
    
    return nil
end

return PetMixerConfig