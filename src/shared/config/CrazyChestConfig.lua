-- CrazyChestConfig - Configuration for Crazy Chest rewards and pricing
local CrazyChestConfig = {}

-- Import rarity colors for consistent theming
local PetConstants = require(script.Parent.Parent.constants.PetConstants)

-- Cost calculation based on rebirths (scales with player progression)
function CrazyChestConfig.getCost(rebirthCount)
    local baseCost = 200 -- Base cost of 200 diamonds for 0 rebirths
    local rebirthMultiplier = 1.2 -- Increases by 20% per rebirth
    
    return math.floor(baseCost * (rebirthMultiplier ^ rebirthCount))
end

-- Reward tiers with proper rarity progression and ultra-rare items
-- Uses proper game rarity colors for visual consistency
CrazyChestConfig.REWARDS = {
    {
        money = 5000,
        chance = 40, -- 40% chance - COMMON
        color = PetConstants.RarityColors[PetConstants.Rarity.COMMON], -- Gray
        rarity = "COMMON",
        name = "Small Money",
        type = "money"
    },
    {
        diamonds = 250,
        chance = 25, -- 25% chance - UNCOMMON  
        color = PetConstants.RarityColors[PetConstants.Rarity.UNCOMMON], -- Green
        rarity = "UNCOMMON",
        name = "Diamonds",
        type = "diamonds"
    },
    {
        money = 20000,
        chance = 15, -- 15% chance - RARE
        color = PetConstants.RarityColors[PetConstants.Rarity.RARE], -- Blue
        rarity = "RARE",
        name = "Big Money",
        type = "money"
    },
    {
        potionId = "pet_magnet_10m",
        quantity = 1,
        chance = 10, -- 10% chance - EPIC
        color = PetConstants.RarityColors[PetConstants.Rarity.EPIC], -- Purple
        rarity = "EPIC", 
        name = "Pet Magnet Potion",
        type = "potion"
    },
    {
        petName = "Easter TV",
        boost = 15,
        value = 1000,
        amount = 1,
        chance = 4, -- 4% chance - LEGENDARY
        color = PetConstants.RarityColors[PetConstants.Rarity.LEGENDARY], -- Orange
        rarity = "LEGENDARY",
        name = "15X Easter TV",
        type = "pet"
    },
    {
        diamonds = 25000,
        chance = 0.9, -- 0.9% chance - MYTHIC (Ultra Rare!)
        color = PetConstants.RarityColors[PetConstants.Rarity.MYTHIC], -- Gold
        rarity = "MYTHIC",
        name = "MYTHIC DIAMONDS",
        type = "diamonds",
        special = "glow" -- Special effect indicator
    },
    {
        petName = "Sombrero Chihuahua",
        boost = 40,
        value = 10000,
        amount = 1,
        chance = 0.1, -- 0.1% chance - OMNISCIENT (Insanely Rare!)
        color = Color3.fromRGB(255, 255, 255), -- White base for rainbow gradient background
        rarity = "OMNISCIENT",
        name = "40X Sombrero Chihuahua",
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
    },
    {
        petName = "Cerulean Hunter", -- The actual pet model to load
        boost = 100000, -- 100K boost - ultimate power
        value = 1000000,
        amount = 1,
        chance = 0.005, -- 0.005% chance - 1 in 20,000!
        color = Color3.fromRGB(20, 20, 20), -- Very dark base for mysterious look
        rarity = "Chest", -- Custom rarity that won't affect calculations
        name = "100K\nBoost", -- Simple 100K boost text
        type = "pet",
        special = "black_market_rainbow_text", -- Special black market with rainbow text
        -- Dark gradient with subtle purple/red hints
        blackMarketGradient = {
            Color = {
                ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 20)),      -- Very dark
                ColorSequenceKeypoint.new(0.25, Color3.fromRGB(40, 20, 40)),   -- Dark purple
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 20, 20)),    -- Dark red
                ColorSequenceKeypoint.new(0.75, Color3.fromRGB(40, 20, 60)),   -- Dark purple-blue
                ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20))       -- Very dark
            },
            Rotation = 135 -- Different angle from rainbow
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

-- Calculate luck-adjusted chances
-- Luck multiplier increases rare chances and decreases common chances
function CrazyChestConfig.getLuckAdjustedRewards(luckMultiplier)
    local adjustedRewards = {}
    local totalChance = 0
    
    -- First pass: calculate raw adjusted chances
    for i, reward in ipairs(CrazyChestConfig.REWARDS) do
        local baseChance = reward.chance
        local adjustedChance
        
        -- Apply luck scaling based on rarity
        -- Common/Uncommon items get reduced chances
        -- Rare/Epic/Legendary/Mythic/Omniscient get increased chances
        if reward.rarity == "COMMON" then
            -- Reduce common chances slightly with luck (much less impact)
            adjustedChance = baseChance / (1 + (luckMultiplier - 1) * 0.1)
        elseif reward.rarity == "UNCOMMON" then
            -- Reduce uncommon chances slightly with luck
            adjustedChance = baseChance / (1 + (luckMultiplier - 1) * 0.08)
        elseif reward.rarity == "RARE" then
            -- Very slightly increase rare chances
            adjustedChance = baseChance * (1 + (luckMultiplier - 1) * 0.05)
        elseif reward.rarity == "EPIC" then
            -- Slightly increase epic chances
            adjustedChance = baseChance * (1 + (luckMultiplier - 1) * 0.08)
        elseif reward.rarity == "LEGENDARY" then
            -- Moderately increase legendary chances
            adjustedChance = baseChance * (1 + (luckMultiplier - 1) * 0.12)
        elseif reward.rarity == "MYTHIC" then
            -- Increase mythic chances more noticeably
            adjustedChance = baseChance * (1 + (luckMultiplier - 1) * 0.15)
        elseif reward.rarity == "OMNISCIENT" then
            -- Increase omniscient chances (but still very gradual)
            adjustedChance = baseChance * (1 + (luckMultiplier - 1) * 0.2)
        elseif reward.rarity == "Chest" then
            -- Increase chest chances the most (but still extremely rare)
            adjustedChance = baseChance * (1 + (luckMultiplier - 1) * 0.25)
        else
            adjustedChance = baseChance
        end
        
        -- Create adjusted reward with new chance
        local adjustedReward = {}
        for k, v in pairs(reward) do
            adjustedReward[k] = v
        end
        adjustedReward.chance = adjustedChance
        adjustedReward.originalChance = baseChance -- Store original for comparison
        
        table.insert(adjustedRewards, adjustedReward)
        totalChance = totalChance + adjustedChance
    end
    
    -- Second pass: normalize chances to sum to 100 and round to clean numbers
    for _, reward in ipairs(adjustedRewards) do
        reward.chance = (reward.chance / totalChance) * 100
    end
    
    -- Third pass: round to max 2 decimal places and ensure they sum to 100
    local roundedRewards = {}
    local totalRounded = 0
    
    -- Round each chance to maximum 2 decimal places for clean display
    for _, reward in ipairs(adjustedRewards) do
        local adjustedReward = {}
        for k, v in pairs(reward) do
            adjustedReward[k] = v
        end
        
        -- Round to 2 decimal places maximum, but preserve ultra-rare chest visibility
        if adjustedReward.rarity == "Chest" then
            -- Special handling for ultra-rare chest - ensure it's always visible
            adjustedReward.chance = math.max(0.005, math.floor(reward.chance * 1000 + 0.5) / 1000)
        else
            -- Regular rounding to 2 decimal places
            adjustedReward.chance = math.floor(reward.chance * 100 + 0.5) / 100
        end
        totalRounded = totalRounded + adjustedReward.chance
        table.insert(roundedRewards, adjustedReward)
    end
    
    -- Adjust the largest chance to make the total exactly 100
    if totalRounded ~= 100 and #roundedRewards > 0 then
        local difference = 100 - totalRounded
        -- Find the reward with the largest chance and adjust it
        local largestIndex = 1
        local largestChance = roundedRewards[1].chance
        for i, reward in ipairs(roundedRewards) do
            if reward.chance > largestChance then
                largestChance = reward.chance
                largestIndex = i
            end
        end
        roundedRewards[largestIndex].chance = roundedRewards[largestIndex].chance + difference
    end
    
    adjustedRewards = roundedRewards
    
    return adjustedRewards
end

-- Get reward ranges with luck adjustment
function CrazyChestConfig.getLuckAdjustedRewardRanges(luckMultiplier)
    local adjustedRewards = CrazyChestConfig.getLuckAdjustedRewards(luckMultiplier)
    local ranges = {}
    local cumulativeChance = 0
    
    for i, reward in ipairs(adjustedRewards) do
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

-- Get reward based on roll with luck adjustment
function CrazyChestConfig.getLuckAdjustedRewardForRoll(roll, luckMultiplier)
    local ranges = CrazyChestConfig.getLuckAdjustedRewardRanges(luckMultiplier)
    
    for _, range in ipairs(ranges) do
        if roll >= range.startRange and roll <= range.endRange then
            return range.reward
        end
    end
    
    -- Fallback to first reward if something goes wrong
    return CrazyChestConfig.REWARDS[1]
end

return CrazyChestConfig