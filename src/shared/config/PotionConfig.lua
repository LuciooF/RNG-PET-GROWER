-- PotionConfig - Configuration for all available potions
-- Defines base potion properties, icons, boost types, and durations

local PotionConfig = {}

-- Boost types enum for consistency
PotionConfig.BoostTypes = {
    DIAMONDS = "Diamonds",
    MONEY = "Money",
    PET_DROP_RATE = "PetDropRate",
    LUCK = "Luck",
    REBIRTH_SPEED = "RebirthSpeed",
    PET_MAGNET = "PetMagnet"
}

-- Rarity levels for future expansion
PotionConfig.Rarities = {
    COMMON = "Common",
    UNCOMMON = "Uncommon", 
    RARE = "Rare",
    EPIC = "Epic",
    LEGENDARY = "Legendary"
}

-- Base potion definitions
PotionConfig.Potions = {
    -- Diamond Boost Potion (2x for 10 minutes)
    diamond_2x_10m = {
        PotionId = "diamond_2x_10m",
        Name = "2x Diamond Potion",
        Description = "Doubles all diamond earnings for 10 minutes",
        Icon = "rbxassetid://104089702525726",
        BoostType = PotionConfig.BoostTypes.DIAMONDS,
        BoostAmount = 2, -- 2x multiplier
        Duration = 600, -- 10 minutes in seconds
        Rarity = PotionConfig.Rarities.COMMON,
        StackLimit = 10, -- Max quantity player can hold
        SortOrder = 1 -- For UI ordering
    },
    
    -- Money Boost Potion (2x for 10 minutes)
    money_2x_10m = {
        PotionId = "money_2x_10m",
        Name = "2x Money Potion", 
        Description = "Doubles all money earnings for 10 minutes",
        Icon = "rbxassetid://80792880610063",
        BoostType = PotionConfig.BoostTypes.MONEY,
        BoostAmount = 2, -- 2x multiplier
        Duration = 600, -- 10 minutes in seconds
        Rarity = PotionConfig.Rarities.COMMON,
        StackLimit = 10, -- Max quantity player can hold
        SortOrder = 2 -- For UI ordering
    },
    
    -- Pet Magnet Potion (Pet Magnet effect for 10 minutes)
    pet_magnet_10m = {
        PotionId = "pet_magnet_10m",
        Name = "Pet Magnet Potion",
        Description = "Automatically collects pets and money for 10 minutes (same as Pet Magnet Gamepass)",
        Icon = "rbxassetid://118134400760699",
        BoostType = PotionConfig.BoostTypes.PET_MAGNET,
        BoostAmount = 1, -- Boolean effect (on/off)
        Duration = 600, -- 10 minutes in seconds
        Rarity = PotionConfig.Rarities.UNCOMMON,
        StackLimit = 5, -- Max quantity player can hold
        SortOrder = 3 -- For UI ordering
    }
}

-- Helper function to get potion data by ID
function PotionConfig.GetPotion(potionId)
    return PotionConfig.Potions[potionId]
end

-- Helper function to get all potions sorted by SortOrder
function PotionConfig.GetAllPotions()
    local potions = {}
    for _, potion in pairs(PotionConfig.Potions) do
        table.insert(potions, potion)
    end
    
    -- Sort by SortOrder
    table.sort(potions, function(a, b)
        return a.SortOrder < b.SortOrder
    end)
    
    return potions
end

-- Helper function to get potions by boost type
function PotionConfig.GetPotionsByBoostType(boostType)
    local potions = {}
    for _, potion in pairs(PotionConfig.Potions) do
        if potion.BoostType == boostType then
            table.insert(potions, potion)
        end
    end
    return potions
end

-- Helper function to format duration for display
function PotionConfig.FormatDuration(seconds)
    if seconds < 60 then
        return string.format("%ds", seconds)
    elseif seconds < 3600 then
        local minutes = math.floor(seconds / 60)
        local remainingSeconds = seconds % 60
        if remainingSeconds == 0 then
            return string.format("%dm", minutes)
        else
            return string.format("%dm %ds", minutes, remainingSeconds)
        end
    else
        local hours = math.floor(seconds / 3600)
        local remainingMinutes = math.floor((seconds % 3600) / 60)
        if remainingMinutes == 0 then
            return string.format("%dh", hours)
        else
            return string.format("%dh %dm", hours, remainingMinutes)
        end
    end
end

-- Helper function to format boost amount for display
function PotionConfig.FormatBoostAmount(amount, boostType)
    if boostType == PotionConfig.BoostTypes.PET_MAGNET then
        return ""
    else
        return string.format("%.1fx", amount)
    end
end

-- Get rarity color for UI display
function PotionConfig.GetRarityColor(rarity)
    local colors = {
        [PotionConfig.Rarities.COMMON] = Color3.fromRGB(200, 200, 200),    -- Light Gray
        [PotionConfig.Rarities.UNCOMMON] = Color3.fromRGB(50, 255, 50),    -- Green  
        [PotionConfig.Rarities.RARE] = Color3.fromRGB(50, 150, 255),       -- Blue
        [PotionConfig.Rarities.EPIC] = Color3.fromRGB(255, 50, 255),       -- Magenta
        [PotionConfig.Rarities.LEGENDARY] = Color3.fromRGB(255, 215, 0)    -- Gold
    }
    return colors[rarity] or colors[PotionConfig.Rarities.COMMON]
end

-- Validate potion configuration on load
local function validateConfig()
    for potionId, potion in pairs(PotionConfig.Potions) do
        -- Check required fields
        assert(potion.PotionId == potionId, "PotionId mismatch for " .. potionId)
        assert(potion.Name and potion.Name ~= "", "Missing Name for " .. potionId)
        assert(potion.Description and potion.Description ~= "", "Missing Description for " .. potionId)
        assert(potion.Icon and potion.Icon ~= "", "Missing Icon for " .. potionId)
        assert(potion.BoostType and potion.BoostType ~= "", "Missing BoostType for " .. potionId)
        assert(type(potion.BoostAmount) == "number" and potion.BoostAmount > 0, "Invalid BoostAmount for " .. potionId)
        assert(type(potion.Duration) == "number" and potion.Duration > 0, "Invalid Duration for " .. potionId)
        assert(potion.Rarity and potion.Rarity ~= "", "Missing Rarity for " .. potionId)
        assert(type(potion.StackLimit) == "number" and potion.StackLimit > 0, "Invalid StackLimit for " .. potionId)
        assert(type(potion.SortOrder) == "number", "Invalid SortOrder for " .. potionId)
    end
    print("PotionConfig: Configuration validated successfully")
end

-- Validate on load
validateConfig()

return PotionConfig