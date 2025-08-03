-- Pet system constants and enums
local PetConstants = {}

-- Pet Rarity Enum - 15 Different Rarities with Incremental Chances + OP
PetConstants.Rarity = {
    COMMON = "Common",              -- 1 in 5
    UNCOMMON = "Uncommon",          -- 1 in 10
    RARE = "Rare",                  -- 1 in 25
    EPIC = "Epic",                  -- 1 in 50
    LEGENDARY = "Legendary",        -- 1 in 100
    MYTHIC = "Mythic",              -- 1 in 250
    ANCIENT = "Ancient",            -- 1 in 500
    CELESTIAL = "Celestial",        -- 1 in 1,000
    TRANSCENDENT = "Transcendent",  -- 1 in 2,500
    OMNIPOTENT = "Omnipotent",      -- 1 in 5,000
    ETHEREAL = "Ethereal",          -- 1 in 10,000
    PRIMORDIAL = "Primordial",      -- 1 in 25,000
    COSMIC = "Cosmic",              -- 1 in 50,000
    INFINITE = "Infinite",          -- 1 in 100,000
    OMNISCIENT = "Omniscient",      -- 1 in 1,000,000
    OP = "OP"                       -- Dev Product Only
}

-- Pet Variation Enum (15 variations total + OP)
PetConstants.Variation = {
    BRONZE = "Bronze",
    SILVER = "Silver", 
    GOLD = "Gold",
    PLATINUM = "Platinum",
    DIAMOND = "Diamond",
    EMERALD = "Emerald",
    SAPPHIRE = "Sapphire",
    RUBY = "Ruby",
    TITANIUM = "Titanium",
    OBSIDIAN = "Obsidian",
    CRYSTAL = "Crystal",
    RAINBOW = "Rainbow",
    COSMIC = "Cosmic",
    VOID = "Void",
    DIVINE = "Divine",
    OP = "OP"                   -- Dev Product Only
}

-- Rarity Colors (for UI display) - 15 Different Colors
PetConstants.RarityColors = {
    [PetConstants.Rarity.COMMON] = Color3.fromRGB(150, 150, 150),      -- Gray
    [PetConstants.Rarity.UNCOMMON] = Color3.fromRGB(85, 170, 85),      -- Green
    [PetConstants.Rarity.RARE] = Color3.fromRGB(85, 85, 255),          -- Blue
    [PetConstants.Rarity.EPIC] = Color3.fromRGB(170, 0, 170),          -- Purple
    [PetConstants.Rarity.LEGENDARY] = Color3.fromRGB(255, 165, 0),     -- Orange
    [PetConstants.Rarity.MYTHIC] = Color3.fromRGB(255, 215, 0),        -- Gold
    [PetConstants.Rarity.ANCIENT] = Color3.fromRGB(139, 69, 19),       -- Saddle Brown
    [PetConstants.Rarity.CELESTIAL] = Color3.fromRGB(135, 206, 250),   -- Sky Blue
    [PetConstants.Rarity.TRANSCENDENT] = Color3.fromRGB(255, 20, 147), -- Deep Pink
    [PetConstants.Rarity.OMNIPOTENT] = Color3.fromRGB(255, 69, 0),     -- Red Orange
    [PetConstants.Rarity.ETHEREAL] = Color3.fromRGB(173, 216, 230),    -- Light Blue
    [PetConstants.Rarity.PRIMORDIAL] = Color3.fromRGB(128, 0, 128),    -- Purple
    [PetConstants.Rarity.COSMIC] = Color3.fromRGB(75, 0, 130),         -- Indigo
    [PetConstants.Rarity.INFINITE] = Color3.fromRGB(255, 255, 255),    -- White
    [PetConstants.Rarity.OMNISCIENT] = Color3.fromRGB(255, 255, 0),    -- Pure Yellow
    [PetConstants.Rarity.OP] = Color3.fromRGB(255, 0, 255)             -- Magenta/Rainbow
}

-- Variation Colors (for UI display) - 15 variations
PetConstants.VariationColors = {
    [PetConstants.Variation.BRONZE] = Color3.fromRGB(205, 127, 50),     -- Bronze
    [PetConstants.Variation.SILVER] = Color3.fromRGB(192, 192, 192),    -- Silver
    [PetConstants.Variation.GOLD] = Color3.fromRGB(255, 215, 0),        -- Gold
    [PetConstants.Variation.PLATINUM] = Color3.fromRGB(229, 228, 226),  -- Platinum
    [PetConstants.Variation.DIAMOND] = Color3.fromRGB(185, 242, 255),   -- Diamond
    [PetConstants.Variation.EMERALD] = Color3.fromRGB(80, 200, 120),    -- Emerald
    [PetConstants.Variation.SAPPHIRE] = Color3.fromRGB(15, 82, 186),    -- Sapphire
    [PetConstants.Variation.RUBY] = Color3.fromRGB(224, 17, 95),        -- Ruby
    [PetConstants.Variation.TITANIUM] = Color3.fromRGB(135, 134, 129),  -- Titanium
    [PetConstants.Variation.OBSIDIAN] = Color3.fromRGB(60, 60, 70),     -- Obsidian
    [PetConstants.Variation.CRYSTAL] = Color3.fromRGB(255, 255, 255),   -- Crystal
    [PetConstants.Variation.RAINBOW] = Color3.fromRGB(255, 100, 255),   -- Rainbow
    [PetConstants.Variation.COSMIC] = Color3.fromRGB(138, 43, 226),     -- Cosmic
    [PetConstants.Variation.VOID] = Color3.fromRGB(25, 25, 25),         -- Void
    [PetConstants.Variation.DIVINE] = Color3.fromRGB(255, 255, 100),    -- Divine
    [PetConstants.Variation.OP] = Color3.fromRGB(255, 0, 255)           -- Magenta/Rainbow
}

-- Base multipliers for variations (affects BaseValue and BaseBoost) - 15 variations with increasing rarity
-- BALANCED: Max 5x multiplier instead of 250x!
PetConstants.VariationMultipliers = {
    [PetConstants.Variation.BRONZE] = 1.0,      -- Most common
    [PetConstants.Variation.SILVER] = 1.1,
    [PetConstants.Variation.GOLD] = 1.25,
    [PetConstants.Variation.PLATINUM] = 1.4,
    [PetConstants.Variation.DIAMOND] = 1.6,
    [PetConstants.Variation.EMERALD] = 1.8,
    [PetConstants.Variation.SAPPHIRE] = 2.0,
    [PetConstants.Variation.RUBY] = 2.25,
    [PetConstants.Variation.TITANIUM] = 2.5,
    [PetConstants.Variation.OBSIDIAN] = 2.8,
    [PetConstants.Variation.CRYSTAL] = 3.2,
    [PetConstants.Variation.RAINBOW] = 3.6,
    [PetConstants.Variation.COSMIC] = 4.0,
    [PetConstants.Variation.VOID] = 4.5,
    [PetConstants.Variation.DIVINE] = 5.0,      -- Rarest (5x instead of 250x!)
    [PetConstants.Variation.OP] = 100.0         -- OP pets get 100x multiplier!
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

-- Get spawn chance for each rarity (1 in X format)
PetConstants.RarityChances = {
    [PetConstants.Rarity.COMMON] = 5,              -- 1 in 5
    [PetConstants.Rarity.UNCOMMON] = 10,           -- 1 in 10
    [PetConstants.Rarity.RARE] = 25,               -- 1 in 25
    [PetConstants.Rarity.EPIC] = 50,               -- 1 in 50
    [PetConstants.Rarity.LEGENDARY] = 100,         -- 1 in 100
    [PetConstants.Rarity.MYTHIC] = 250,            -- 1 in 250
    [PetConstants.Rarity.ANCIENT] = 500,           -- 1 in 500
    [PetConstants.Rarity.CELESTIAL] = 1000,        -- 1 in 1,000
    [PetConstants.Rarity.TRANSCENDENT] = 2500,     -- 1 in 2,500
    [PetConstants.Rarity.OMNIPOTENT] = 5000,       -- 1 in 5,000
    [PetConstants.Rarity.ETHEREAL] = 10000,        -- 1 in 10,000
    [PetConstants.Rarity.PRIMORDIAL] = 25000,      -- 1 in 25,000
    [PetConstants.Rarity.COSMIC] = 50000,          -- 1 in 50,000
    [PetConstants.Rarity.INFINITE] = 100000,       -- 1 in 100,000
    [PetConstants.Rarity.OMNISCIENT] = 1000000     -- 1 in 1,000,000
}

function PetConstants.getRarityChance(rarity)
    return PetConstants.RarityChances[rarity] or 1
end

-- Get variation chance percentage (for calculating combined rarity)
PetConstants.VariationChances = {
    [PetConstants.Variation.BRONZE] = 25.0,    -- 25%
    [PetConstants.Variation.SILVER] = 20.0,    -- 20% 
    [PetConstants.Variation.GOLD] = 15.0,      -- 15%
    [PetConstants.Variation.PLATINUM] = 12.0,  -- 12%
    [PetConstants.Variation.DIAMOND] = 10.0,   -- 10%
    [PetConstants.Variation.EMERALD] = 8.0,    -- 8%
    [PetConstants.Variation.SAPPHIRE] = 5.0,   -- 5%
    [PetConstants.Variation.RUBY] = 3.0,       -- 3%
    [PetConstants.Variation.TITANIUM] = 1.5,   -- 1.5%
    [PetConstants.Variation.OBSIDIAN] = 0.3,   -- 0.3%
    [PetConstants.Variation.CRYSTAL] = 0.1,    -- 0.1%
    [PetConstants.Variation.RAINBOW] = 0.05,   -- 0.05%
    [PetConstants.Variation.COSMIC] = 0.03,    -- 0.03%
    [PetConstants.Variation.VOID] = 0.015,     -- 0.015%
    [PetConstants.Variation.DIVINE] = 0.005    -- 0.005%
}

function PetConstants.getVariationChance(variation)
    return PetConstants.VariationChances[variation] or 25.0
end

-- Calculate combined rarity (pet rarity * variation rarity)
-- Example: 1 in 1M pet with Divine (0.005%) = 1 in 20 billion
function PetConstants.getCombinedRarityChance(rarity, variation)
    local rarityChance = PetConstants.getRarityChance(rarity) -- 1 in X
    local variationPercent = PetConstants.getVariationChance(variation) -- Y%
    
    -- Convert variation percent to decimal and calculate combined chance
    local variationDecimal = variationPercent / 100
    local combinedChance = math.floor(rarityChance / variationDecimal)
    
    return combinedChance
end

-- Get all rarities in order (Common -> Omniscient) - 15 Total
function PetConstants.getAllRarities()
    return {
        PetConstants.Rarity.COMMON,
        PetConstants.Rarity.UNCOMMON,
        PetConstants.Rarity.RARE,
        PetConstants.Rarity.EPIC,
        PetConstants.Rarity.LEGENDARY,
        PetConstants.Rarity.MYTHIC,
        PetConstants.Rarity.ANCIENT,
        PetConstants.Rarity.CELESTIAL,
        PetConstants.Rarity.TRANSCENDENT,
        PetConstants.Rarity.OMNIPOTENT,
        PetConstants.Rarity.ETHEREAL,
        PetConstants.Rarity.PRIMORDIAL,
        PetConstants.Rarity.COSMIC,
        PetConstants.Rarity.INFINITE,
        PetConstants.Rarity.OMNISCIENT
    }
end

-- Get all variations in order (Bronze -> Divine) - 15 total
function PetConstants.getAllVariations()
    return {
        PetConstants.Variation.BRONZE,
        PetConstants.Variation.SILVER,
        PetConstants.Variation.GOLD,
        PetConstants.Variation.PLATINUM,
        PetConstants.Variation.DIAMOND,
        PetConstants.Variation.EMERALD,
        PetConstants.Variation.SAPPHIRE,
        PetConstants.Variation.RUBY,
        PetConstants.Variation.TITANIUM,
        PetConstants.Variation.OBSIDIAN,
        PetConstants.Variation.CRYSTAL,
        PetConstants.Variation.RAINBOW,
        PetConstants.Variation.COSMIC,
        PetConstants.Variation.VOID,
        PetConstants.Variation.DIVINE
    }
end

return PetConstants