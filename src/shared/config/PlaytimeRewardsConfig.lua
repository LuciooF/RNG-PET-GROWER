-- PlaytimeRewardsConfig - Configuration for playtime milestone rewards
local PlaytimeRewardsConfig = {}

-- Playtime reward tiers (in minutes) - 15 rewards total
-- EASILY CONFIGURABLE: Change timeMinutes, type, amount, title as needed
-- Pattern: Alternates between Diamonds and Money for variety
PlaytimeRewardsConfig.rewards = {
    {
        timeMinutes = 30/60, -- 5 seconds - CONFIGURABLE: Change to any time
        type = "Diamonds", -- Reward 1: Diamonds
        amount = 50, -- CONFIGURABLE: Change amount as needed
        title = "Quick Start",
        description = "Play for 5 seconds",
        icon = "💎"
    },
    {
        timeMinutes = 2, -- 30 seconds - CONFIGURABLE: Change to any time
        type = "Potion", -- Reward 2: 2x Money Potion (moved from position 4)
        potionId = "money_2x_10m", -- 2x Money potion for 10 minutes
        quantity = 1, -- One potion
        title = "Money Booster",
        description = "2x Money for 10 minutes",
        icon = "🧪"
    },
    {
        timeMinutes = 2.5, -- 45 seconds - CONFIGURABLE: Change to any time
        type = "Diamonds", -- Reward 3: Diamonds (alternating pattern)
        amount = 150, -- CONFIGURABLE: Change amount as needed
        title = "Active Player",
        description = "Play for 45 seconds", 
        icon = "💎"
    },
    {
        timeMinutes = 5, -- 1 minute - CONFIGURABLE: Change to any time
        type = "Pet", -- Reward 4: Frosty Cat (moved from position 2)
        petName = "Frosty Cat", -- CONFIGURABLE: Pet asset name (must match asset)
        amount = 1, -- CONFIGURABLE: Number of pets to give
        boost = 5, -- CONFIGURABLE: Pet boost multiplier (5x)
        value = 500, -- CONFIGURABLE: Pet base value
        title = "Frosty Cat Reward",
        description = "Play for 1 minute",
        icon = "🔥",
        isOP = true -- Mark Frosty Cat as OP
    },
    {
        timeMinutes = 7.5, -- 1m 15s - CONFIGURABLE: Change to any time
        type = "Potion", -- Reward 5: 2x Diamond Potion
        potionId = "diamond_2x_10m", -- 2x Diamond potion for 10 minutes
        quantity = 1, -- One potion
        title = "Diamond Booster",
        description = "2x Diamonds for 10 minutes",
        icon = "🧪"
    },
    {
        timeMinutes = 10, -- 1m 30s - CONFIGURABLE: Change to any time
        type = "Money", -- Reward 6: Money (alternating pattern)
        amount = 10000, -- CONFIGURABLE: Change amount as needed
        title = "Dedicated Player",
        description = "Play for 1m 30s",
        icon = "💰"
    },
    {
        timeMinutes = 15, -- 15 minutes - CONFIGURABLE: Change to any time
        type = "Pet", -- Reward 7: Pet reward
        petName = "Chocolate Dragon", -- CONFIGURABLE: Pet asset name (must match asset)
        amount = 1, -- CONFIGURABLE: Number of pets to give
        boost = 20, -- CONFIGURABLE: Pet boost multiplier (20x)
        value = 500, -- CONFIGURABLE: Pet base value
        title = "Chocolate Dragon Reward",
        description = "Play for 15 minutes",
        icon = "🔥",
        isOP = true -- Mark Chocolate Dragon as OP (20x boost pet)
    },
    {
        timeMinutes = 20, -- Pet Magnet potion reward
        type = "Potion", -- Pet Magnet Potion
        potionId = "pet_magnet_10m", -- Pet Magnet potion for 10 minutes
        quantity = 1, -- One potion
        title = "Pet Magnet",
        description = "Auto-collect for 10 minutes",
        icon = "🧪"
    },
    {
        timeMinutes = 25, -- 5 minutes - CONFIGURABLE: Change to any time
        type = "Diamonds", -- Reward 9: Diamonds (alternating pattern)
        amount = 1500, -- CONFIGURABLE: Change amount as needed
        title = "Five Minutes",
        description = "Play for 5 minutes",
        icon = "💎"
    },
    {
        timeMinutes = 30, -- 10 minutes - CONFIGURABLE: Change to any time
        type = "Money", -- Reward 10: Money (alternating pattern)
        amount = 30000, -- CONFIGURABLE: Change amount as needed
        title = "Ten Minutes",
        description = "Play for 10 minutes",
        icon = "💰"
    },
    {
        timeMinutes = 35, -- 15 minutes - CONFIGURABLE: Change to any time
        type = "Diamonds", -- Reward 11: Diamonds (alternating pattern)
        amount = 5000, -- CONFIGURABLE: Change amount as needed
        title = "Quarter Hour",
        description = "Play for 15 minutes",
        icon = "💎"
    },
    {
        timeMinutes = 40, -- 30 minutes - CONFIGURABLE: Change to any time
        type = "Money", -- Reward 12: Money (alternating pattern)
        amount = 100000, -- CONFIGURABLE: Change amount as needed
        title = "Half Hour",
        description = "Play for 30 minutes",
        icon = "💰",
        isOP = true -- Mark this high-value money reward as OP
    },
    {
        timeMinutes = 45, -- 1 hour - CONFIGURABLE: Change to any time
        type = "Diamonds", -- Reward 13: Diamonds (alternating pattern)
        amount = 10000, -- CONFIGURABLE: Change amount as needed
        title = "One Hour",
        description = "Play for 1 hour",
        icon = "💎"
    },
    {
        timeMinutes = 50, -- 2 hours - CONFIGURABLE: Change to any time
        type = "Money", -- Reward 14: Money (alternating pattern)
        amount = 500000, -- CONFIGURABLE: Change amount as needed
        title = "Two Hours",
        description = "Play for 2 hours",
        icon = "💰"
    },
    {
        timeMinutes = 60, -- 3 hours - CONFIGURABLE: Change to any time
        type = "Diamonds", -- Reward 15: Diamonds (alternating pattern)
        amount = 20000, -- CONFIGURABLE: Change amount as needed
        title = "Three Hours",
        description = "Play for 3 hours",
        icon = "💎",
        isOP = true -- Mark this ultimate reward as OP
    }
}

-- Colors for different reward states
PlaytimeRewardsConfig.colors = {
    available = Color3.fromRGB(85, 255, 85),    -- Green - can claim
    claimed = Color3.fromRGB(150, 150, 150),    -- Gray - already claimed
    locked = Color3.fromRGB(255, 150, 150),     -- Light red - not yet available
    opAvailable = Color3.fromRGB(255, 215, 0),  -- Gold - OP reward available
    opClaimed = Color3.fromRGB(200, 180, 0),    -- Darker gold - OP reward claimed
    opLocked = Color3.fromRGB(255, 200, 100)    -- Light gold - OP reward locked
}

-- Get all rewards sorted by time
function PlaytimeRewardsConfig.getAllRewards()
    local sortedRewards = {}
    for _, reward in ipairs(PlaytimeRewardsConfig.rewards) do
        table.insert(sortedRewards, reward)
    end
    
    -- Sort by time ascending
    table.sort(sortedRewards, function(a, b)
        return a.timeMinutes < b.timeMinutes
    end)
    
    return sortedRewards
end

-- Get reward by time minutes
function PlaytimeRewardsConfig.getRewardByTime(timeMinutes)
    for _, reward in ipairs(PlaytimeRewardsConfig.rewards) do
        if reward.timeMinutes == timeMinutes then
            return reward
        end
    end
    return nil
end

-- Check if player has reached a milestone
function PlaytimeRewardsConfig.getAvailableRewards(playtimeMinutes)
    local availableRewards = {}
    for _, reward in ipairs(PlaytimeRewardsConfig.rewards) do
        if playtimeMinutes >= reward.timeMinutes then
            table.insert(availableRewards, reward)
        end
    end
    return availableRewards
end

-- Format time display (e.g., "1m 30s", "2h 15m") - with spaces
function PlaytimeRewardsConfig.formatTime(minutes)
    if minutes < 1 then
        local seconds = math.floor(minutes * 60)
        return seconds .. "s"
    elseif minutes < 60 then
        local wholeMinutes = math.floor(minutes)
        local remainingSeconds = math.floor((minutes - wholeMinutes) * 60)
        return wholeMinutes .. "m " .. remainingSeconds .. "s" -- Always show seconds
    else
        local hours = math.floor(minutes / 60)
        local remainingMinutes = minutes % 60
        local remainingSeconds = math.floor((remainingMinutes % 1) * 60)
        remainingMinutes = math.floor(remainingMinutes)
        if remainingMinutes == 0 then
            return hours .. "h 0m " .. remainingSeconds .. "s" -- Always show minutes and seconds
        else
            return hours .. "h " .. remainingMinutes .. "m " .. remainingSeconds .. "s" -- Always show seconds
        end
    end
end

return PlaytimeRewardsConfig