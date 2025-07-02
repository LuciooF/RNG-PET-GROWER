local PetConfig = {}

-- Pet definitions with their properties
PetConfig.PETS = {
    [1] = {
        name = "Mighty Duck",
        assetId = 72905778529983,
        rarity = 1, -- Which plot rarity this pet can spawn from
        spawnChance = 1.0, -- 100% chance for now (single pet)
        value = 1, -- Base money value when collected
        description = "A fearless waterfowl with incredible determination. Known for its unwavering loyalty and surprising strength.",
        boosts = {
            moneyMultiplier = 1.1, -- 10% more money from all sources
            type = "money" -- Type of boost this pet provides
        }
    }
}

-- Aura system
PetConfig.AURAS = {
    none = {
        name = "None",
        color = Color3.fromRGB(255, 255, 255), -- White/default
        multiplier = 1.0, -- No bonus
        valueMultiplier = 1.0, -- No value bonus
        chance = 0.5 -- 50% chance
    },
    diamond = {
        name = "Diamond",
        color = Color3.fromRGB(100, 200, 255), -- Blue
        multiplier = 2.0, -- 2x boost multiplier
        valueMultiplier = 2.0, -- 2x value
        chance = 0.5 -- 50% chance
    }
}

-- Function to randomly select an aura
function PetConfig:GetRandomAura()
    local rand = math.random()
    local cumulativeChance = 0
    
    for auraId, auraData in pairs(self.AURAS) do
        cumulativeChance = cumulativeChance + auraData.chance
        if rand <= cumulativeChance then
            return auraId, auraData
        end
    end
    
    -- Fallback to none
    return "none", self.AURAS.none
end

-- Pet rarity configurations
PetConfig.RARITY_CONFIG = {
    [1] = {
        name = "Basic",
        color = Color3.fromRGB(255, 255, 255), -- White
        pets = {1} -- Pet IDs that can spawn from rarity 1 plots
    }
}

function PetConfig:GetPetData(petId)
    return self.PETS[petId]
end

function PetConfig:GetPetsForRarity(rarity)
    local rarityConfig = self.RARITY_CONFIG[rarity]
    if not rarityConfig then
        return {}
    end
    
    local pets = {}
    for _, petId in pairs(rarityConfig.pets) do
        local petData = self.PETS[petId]
        if petData then
            table.insert(pets, {
                id = petId,
                data = petData
            })
        end
    end
    
    return pets
end

function PetConfig:GetRandomPetForRarity(rarity)
    local availablePets = self:GetPetsForRarity(rarity)
    if #availablePets == 0 then
        return nil
    end
    
    -- For now, just return the first pet (since we only have one)
    -- Later we'll implement proper weighted random selection
    return availablePets[1]
end

function PetConfig:GetRarityConfig(rarity)
    return self.RARITY_CONFIG[rarity]
end

return PetConfig