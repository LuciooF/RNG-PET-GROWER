-- Pet Aura System Configuration
-- Extracted from PetConfig.lua following CLAUDE.md modular architecture patterns

local PetAuraSystem = {}

PetAuraSystem.AURAS = {
    none = {
        name = "Basic",
        color = Color3.fromRGB(200, 200, 200), -- Gray
        multiplier = 1.0, -- No bonus
        valueMultiplier = 1.0, -- No value bonus
        chance = 0.60, -- 60% chance
        rarity = "Common"
    },
    wood = {
        name = "Wood",
        color = Color3.fromRGB(139, 69, 19), -- Brown
        multiplier = 1.2,
        valueMultiplier = 1.2,
        chance = 0.20, -- 20% chance
        rarity = "Uncommon"
    },
    stone = {
        name = "Stone",
        color = Color3.fromRGB(128, 128, 128), -- Gray
        multiplier = 1.4,
        valueMultiplier = 1.3,
        chance = 0.10, -- 10% chance
        rarity = "Rare"
    },
    iron = {
        name = "Iron",
        color = Color3.fromRGB(192, 192, 192), -- Silver
        multiplier = 1.6,
        valueMultiplier = 1.5,
        chance = 0.05, -- 5% chance
        rarity = "Epic"
    },
    gold = {
        name = "Gold",
        color = Color3.fromRGB(255, 215, 0), -- Gold
        multiplier = 2.0,
        valueMultiplier = 1.8,
        chance = 0.025, -- 2.5% chance
        rarity = "Legendary"
    },
    diamond = {
        name = "Diamond",
        color = Color3.fromRGB(185, 242, 255), -- Light blue
        multiplier = 2.5,
        valueMultiplier = 2.2,
        chance = 0.015, -- 1.5% chance
        rarity = "Mythic"
    },
    emerald = {
        name = "Emerald",
        color = Color3.fromRGB(80, 200, 120), -- Green
        multiplier = 3.0,
        valueMultiplier = 2.5,
        chance = 0.008, -- 0.8% chance
        rarity = "Divine"
    },
    ruby = {
        name = "Ruby",
        color = Color3.fromRGB(224, 17, 95), -- Red
        multiplier = 3.5,
        valueMultiplier = 3.0,
        chance = 0.005, -- 0.5% chance
        rarity = "Celestial"
    },
    sapphire = {
        name = "Sapphire",
        color = Color3.fromRGB(15, 82, 186), -- Blue
        multiplier = 4.0,
        valueMultiplier = 3.5,
        chance = 0.003, -- 0.3% chance
        rarity = "Cosmic"
    },
    void = {
        name = "Void",
        color = Color3.fromRGB(25, 25, 25), -- Dark
        multiplier = 5.0,
        valueMultiplier = 4.0,
        chance = 0.001, -- 0.1% chance
        rarity = "Void"
    },
    rainbow = {
        name = "Rainbow",
        color = Color3.fromRGB(255, 0, 127), -- Pink
        multiplier = 10.0,
        valueMultiplier = 8.0,
        chance = 0.0001, -- 0.01% chance
        rarity = "Rainbow"
    }
}

return PetAuraSystem