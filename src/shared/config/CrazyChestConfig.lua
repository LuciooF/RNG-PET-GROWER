-- CrazyChestConfig - Configuration for Crazy Chest rewards and pricing
local CrazyChestConfig = {}

-- Import rarity colors for consistent theming
local PetConstants = require(script.Parent.Parent.constants.PetConstants)

-- Cost calculation based on rebirths (cheaper for new players)
function CrazyChestConfig.getCost(rebirthCount)
    local baseCost = 50 -- Base cost for 0 rebirths
    local rebirthMultiplier = 1.2 -- Increases by 20% per rebirth
    
    return math.floor(baseCost * (rebirthMultiplier ^ rebirthCount))
end

-- Reward tiers with proper rarity progression and ultra-rare items
-- Uses proper game rarity colors for visual consistency
CrazyChestConfig.REWARDS = {
    {
        money = 500,
        chance = 40, -- 40% chance - COMMON
        color = PetConstants.RarityColors[PetConstants.Rarity.COMMON], -- Gray
        rarity = "COMMON",
        name = "Small Money",
        type = "money"
    },
    {
        diamonds = 50,
        chance = 25, -- 25% chance - UNCOMMON  
        color = PetConstants.RarityColors[PetConstants.Rarity.UNCOMMON], -- Green
        rarity = "UNCOMMON",
        name = "Diamonds",
        type = "diamonds"
    },
    {
        money = 2000,
        chance = 15, -- 15% chance - RARE
        color = PetConstants.RarityColors[PetConstants.Rarity.RARE], -- Blue
        rarity = "RARE",
        name = "Big Money",
        type = "money"
    },
    {
        diamonds = 200,
        chance = 10, -- 10% chance - EPIC
        color = PetConstants.RarityColors[PetConstants.Rarity.EPIC], -- Purple
        rarity = "EPIC", 
        name = "Large Diamonds",
        type = "diamonds"
    },
    {
        petName = "Easter TV",
        boost = 5,
        value = 1000,
        amount = 1,
        chance = 4, -- 4% chance - LEGENDARY
        color = PetConstants.RarityColors[PetConstants.Rarity.LEGENDARY], -- Orange
        rarity = "LEGENDARY",
        name = "5X Easter TV",
        type = "pet"
    },
    {
        diamonds = 1000,
        chance = 0.9, -- 0.9% chance - MYTHIC (Ultra Rare!)
        color = PetConstants.RarityColors[PetConstants.Rarity.MYTHIC], -- Gold
        rarity = "MYTHIC",
        name = "MYTHIC DIAMONDS",
        type = "diamonds",
        special = "glow" -- Special effect indicator
    },
    {
        petName = "Sombrero Chihuahua",
        boost = 25,
        value = 10000,
        amount = 1,
        chance = 0.1, -- 0.1% chance - OMNISCIENT (Insanely Rare!)
        color = Color3.fromRGB(255, 255, 255), -- White base for rainbow gradient background
        rarity = "OMNISCIENT",
        name = "25X Sombrero Chihuahua",
        type = "pet",
        special = "rainbow", -- Rainbow effect indicator
        -- Rainbow gradient definition
        rainbowGradient = {
            Color = {
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),     -- Red
                ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 127, 0)), -- Orange
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)), -- Yellow
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),    -- Green
                ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),   -- Blue
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)),  -- Indigo
                ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 0, 211))     -- Violet
            },
            Rotation = 45 -- Diagonal gradient
        }
    }
}

-- Calculate cumulative ranges for rewards
function CrazyChestConfig.getRewardRanges()
    local ranges = {}
    local cumulativeChance = 0
    
    for i, reward in ipairs(CrazyChestConfig.REWARDS) do
        local startRange = cumulativeChance + 1
        local endRange = cumulativeChance + reward.chance
        
        ranges[i] = {
            startRange = startRange,
            endRange = endRange,
            reward = reward
        }
        
        cumulativeChance = endRange
    end
    
    return ranges
end

-- Get reward based on random number (1-100)
function CrazyChestConfig.getRewardForRoll(roll)
    local ranges = CrazyChestConfig.getRewardRanges()
    
    for _, range in ipairs(ranges) do
        if roll >= range.startRange and roll <= range.endRange then
            return range.reward
        end
    end
    
    -- Fallback to first reward if something goes wrong
    return CrazyChestConfig.REWARDS[1]
end

return CrazyChestConfig