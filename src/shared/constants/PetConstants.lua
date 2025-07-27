-- Pet system constants and enums
local PetConstants = {}

-- Pet Rarity Enum
PetConstants.Rarity = {
    COMMON = "Common",
    UNCOMMON = "Uncommon", 
    RARE = "Rare",
    EPIC = "Epic",
    LEGENDARY = "Legendary",
    MYTHIC = "Mythic"
}

-- Pet Variation Enum
PetConstants.Variation = {
    BRONZE = "Bronze",
    SILVER = "Silver", 
    GOLD = "Gold"
}

-- Rarity Colors (for UI display)
PetConstants.RarityColors = {
    [PetConstants.Rarity.COMMON] = Color3.fromRGB(150, 150, 150),      -- Gray
    [PetConstants.Rarity.UNCOMMON] = Color3.fromRGB(85, 170, 85),      -- Green
    [PetConstants.Rarity.RARE] = Color3.fromRGB(85, 85, 255),          -- Blue
    [PetConstants.Rarity.EPIC] = Color3.fromRGB(170, 0, 170),          -- Purple
    [PetConstants.Rarity.LEGENDARY] = Color3.fromRGB(255, 165, 0),     -- Orange
    [PetConstants.Rarity.MYTHIC] = Color3.fromRGB(255, 215, 0)         -- Gold
}

-- Variation Colors (for UI display)
PetConstants.VariationColors = {
    [PetConstants.Variation.BRONZE] = Color3.fromRGB(205, 127, 50),    -- Bronze
    [PetConstants.Variation.SILVER] = Color3.fromRGB(192, 192, 192),   -- Silver
    [PetConstants.Variation.GOLD] = Color3.fromRGB(255, 215, 0)        -- Gold
}

-- Base multipliers for variations (affects BaseValue and BaseBoost)
PetConstants.VariationMultipliers = {
    [PetConstants.Variation.BRONZE] = 1.0,
    [PetConstants.Variation.SILVER] = 1.5,
    [PetConstants.Variation.GOLD] = 2.0
}

-- Helper functions
function PetConstants.getRarityColor(rarity)
    return PetConstants.RarityColors[rarity] or Color3.fromRGB(255, 255, 255)
end

function PetConstants.getVariationColor(variation)
    return PetConstants.VariationColors[variation] or Color3.fromRGB(255, 255, 255)
end

function PetConstants.getVariationMultiplier(variation)
    return PetConstants.VariationMultipliers[variation] or 1.0
end

-- Get all rarities in order (Common -> Mythic)
function PetConstants.getAllRarities()
    return {
        PetConstants.Rarity.COMMON,
        PetConstants.Rarity.UNCOMMON,
        PetConstants.Rarity.RARE,
        PetConstants.Rarity.EPIC,
        PetConstants.Rarity.LEGENDARY,
        PetConstants.Rarity.MYTHIC
    }
end

-- Get all variations in order (Bronze -> Gold)
function PetConstants.getAllVariations()
    return {
        PetConstants.Variation.BRONZE,
        PetConstants.Variation.SILVER,
        PetConstants.Variation.GOLD
    }
end

return PetConstants