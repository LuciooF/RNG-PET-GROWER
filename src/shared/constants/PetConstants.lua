-- Pet Constants
-- Centralized pet-related constants used across UI components
-- Consolidates pet emojis, rarity colors, and other pet-related data

local PetConstants = {}

-- Pet emoji mappings (comprehensive list based on PetConfig)
PetConstants.PET_EMOJIS = {
    -- Dogs
    ["4th Of July Doggy"] = "🐕",
    ["Acid Rain Doggy"] = "🐕", 
    ["Alien Doggy"] = "👽",
    ["Angel & Devil Doggy"] = "😇",
    ["Anime Doggy"] = "🐕",
    ["Arcade Doggy"] = "🎮",
    ["Baby Doggy"] = "🐶",
    ["Beach Doggy"] = "🏖️", 
    ["Blossom Doggy"] = "🌸",
    ["St' Patrics Doggy"] = "🍀",
    
    -- Ducks
    ["Mighty Duck"] = "🦆",
    ["Golden Duck"] = "🦆",
    ["Fire Duck"] = "🔥",
    ["Ice Duck"] = "🧊",
    ["Shadow Duck"] = "🌑",
    
    -- Generic fallback
    ["Unknown"] = "🐾"
}

-- Rarity colors (single colors for borders, gradients for backgrounds)
PetConstants.RARITY_COLORS = {
    [1] = {
        single = Color3.fromRGB(150, 150, 150), -- Gray
        gradient = {Color3.fromRGB(150, 150, 150), Color3.fromRGB(180, 180, 180)}
    },
    [2] = {
        single = Color3.fromRGB(100, 255, 100), -- Green
        gradient = {Color3.fromRGB(100, 255, 100), Color3.fromRGB(150, 255, 150)}
    },
    [3] = {
        single = Color3.fromRGB(100, 100, 255), -- Blue
        gradient = {Color3.fromRGB(100, 100, 255), Color3.fromRGB(150, 150, 255)}
    },
    [4] = {
        single = Color3.fromRGB(255, 100, 255), -- Purple
        gradient = {Color3.fromRGB(255, 100, 255), Color3.fromRGB(255, 150, 255)}
    },
    [5] = {
        single = Color3.fromRGB(255, 215, 0), -- Gold
        gradient = {Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 235, 50)}
    }
}

-- Rarity names
PetConstants.RARITY_NAMES = {
    [1] = "BASIC",
    [2] = "ADVANCED", 
    [3] = "PREMIUM",
    [4] = "ELITE",
    [5] = "MASTER"
}

-- Helper functions
function PetConstants.getPetEmoji(petName)
    return PetConstants.PET_EMOJIS[petName] or PetConstants.PET_EMOJIS["Unknown"]
end

function PetConstants.getRarityColor(rarity, useGradient)
    local rarityData = PetConstants.RARITY_COLORS[rarity]
    if not rarityData then
        return PetConstants.RARITY_COLORS[1].single -- Default to basic
    end
    
    if useGradient then
        return rarityData.gradient
    else
        return rarityData.single
    end
end

function PetConstants.getRarityName(rarity)
    return PetConstants.RARITY_NAMES[rarity] or "UNKNOWN"
end

-- Size-related constants (from PetConfig but commonly used in UI)
PetConstants.SIZE_COLORS = {
    [1] = Color3.fromRGB(150, 150, 150), -- Tiny - Gray
    [2] = Color3.fromRGB(100, 255, 100), -- Small - Light green
    [3] = Color3.fromRGB(100, 150, 255), -- Normal - Light blue
    [4] = Color3.fromRGB(255, 150, 100), -- Large - Light orange
    [5] = Color3.fromRGB(255, 100, 255), -- Huge - Light purple
    [6] = Color3.fromRGB(255, 215, 0)    -- Giant - Gold
}

-- Aura-related constants commonly used in UI
PetConstants.AURA_COLORS = {
    ["none"] = Color3.fromRGB(255, 255, 255),
    ["Diamond"] = Color3.fromRGB(185, 242, 255),
    ["Golden"] = Color3.fromRGB(255, 215, 0),
    ["Rainbow"] = Color3.fromRGB(255, 100, 255)
}

-- Common UI constants
PetConstants.DEFAULT_PET_ICON = "🐾"
PetConstants.DEFAULT_CARD_SIZE = UDim2.new(0, 120, 0, 140)
PetConstants.DEFAULT_ICON_SIZE = UDim2.new(0, 40, 0, 40)

return PetConstants