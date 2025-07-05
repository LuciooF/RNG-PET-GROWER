-- Pet Size System Configuration
-- Extracted from PetConfig.lua following CLAUDE.md modular architecture patterns

local PetSizeSystem = {}

PetSizeSystem.SIZES = {
    [1] = {
        name = "Tiny",
        displayName = "Tiny",
        multiplier = 1.0, -- No bonus for smallest size
        color = Color3.fromRGB(150, 150, 150) -- Gray
    },
    [2] = {
        name = "Small",
        displayName = "Small", 
        multiplier = 1.2, -- 20% bonus
        color = Color3.fromRGB(100, 255, 100) -- Light green
    },
    [3] = {
        name = "Medium",
        displayName = "Medium",
        multiplier = 1.5, -- 50% bonus  
        color = Color3.fromRGB(100, 150, 255) -- Light blue
    },
    [4] = {
        name = "Large",
        displayName = "Large",
        multiplier = 2.0, -- 100% bonus
        color = Color3.fromRGB(255, 150, 100) -- Light orange
    },
    [5] = {
        name = "Gigantic",
        displayName = "Gigantic",
        multiplier = 3.0, -- 200% bonus
        color = Color3.fromRGB(255, 100, 255) -- Light purple
    }
}

return PetSizeSystem