-- DailyRewardsConfig - Configuration for daily login rewards (10 days of OP pets)
local DailyRewardsConfig = {}

-- Daily reward tiers (10 days of consecutive login rewards)
-- Each day gives better OP pets with higher boosts
DailyRewardsConfig.rewards = {
    {
        day = 1,
        type = "Pet", -- OP Pet reward
        petName = "Ruby Spider 2.0", -- Pet asset name (must match ReplicatedStorage.Pets)
        amount = 1, -- Number of pets to give
        boost = 10, -- Pet boost multiplier (10x)
        value = 1000, -- Pet base value
        title = "Day 1 Login",
        description = "Welcome back! Here's an OP pet!",
        icon = "🎁"
    },
    {
        day = 2,
        type = "Pet",
        petName = "Glacier",
        amount = 1,
        boost = 25, -- 25x boost
        value = 2500,
        title = "Day 2 Streak",
        description = "Keep it up! Even better pet!",
        icon = "🔥"
    },
    {
        day = 3,
        type = "Pet",
        petName = "Mystery Cat",
        amount = 1,
        boost = 50, -- 50x boost
        value = 5000,
        title = "Day 3 Streak",
        description = "You're on fire! Phoenix power!",
        icon = "🔥"
    },
    {
        day = 4,
        type = "Pet",
        petName = "Neptunian Hunter",
        amount = 1,
        boost = 100, -- 100x boost
        value = 10000,
        title = "Day 4 Streak",
        description = "Golden rewards await!",
        icon = "👑"
    },
    {
        day = 5,
        type = "Pet",
        petName = "Ice Cream Dominus",
        amount = 1,
        boost = 200, -- 200x boost
        value = 20000,
        title = "Day 5 Streak",
        description = "Crystal clear dedication!",
        icon = "💎"
    },
    {
        day = 6,
        type = "Pet",
        petName = "Puzzle Cube",
        amount = 1,
        boost = 400, -- 400x boost
        value = 40000,
        title = "Day 6 Streak",
        description = "Shadows bend to your will!",
        icon = "🌟"
    },
    {
        day = 7,
        type = "Pet",
        petName = "Crystal Lord",
        amount = 1,
        boost = 750, -- 750x boost
        value = 75000,
        title = "Week Complete!",
        description = "Lightning strikes loyalty!",
        icon = "⚡"
    },
    {
        day = 8,
        type = "Pet",
        petName = "Toucan",
        amount = 1,
        boost = 1500, -- 1500x boost
        value = 150000,
        title = "Day 8 Master",
        description = "Cosmic forces favor you!",
        icon = "🌌"
    },
    {
        day = 9,
        type = "Pet",
        petName = "Sapphire Dragon",
        amount = 1,
        boost = 3000, -- 3000x boost
        value = 300000,
        title = "Day 9 Legend",
        description = "The void acknowledges you!",
        icon = "🌀"
    },
    {
        day = 10,
        type = "Pet",
        petName = "Waffle Cone",
        amount = 1,
        boost = 5000, -- 5000x boost - ULTIMATE REWARD
        value = 500000,
        title = "Ultimate Loyalty!",
        description = "The ultimate reward for ultimate dedication!",
        icon = "🏆"
    }
}

-- Colors for different reward states
DailyRewardsConfig.colors = {
    available = Color3.fromRGB(85, 255, 85),    -- Green - can claim
    claimed = Color3.fromRGB(255, 215, 0),      -- Gold - already claimed  
    locked = Color3.fromRGB(255, 150, 150),     -- Light red - not yet available
    expired = Color3.fromRGB(150, 150, 150)     -- Gray - streak broken/expired
}

-- Get all rewards sorted by day
function DailyRewardsConfig.getAllRewards()
    local sortedRewards = {}
    for _, reward in ipairs(DailyRewardsConfig.rewards) do
        table.insert(sortedRewards, reward)
    end
    
    -- Sort by day ascending
    table.sort(sortedRewards, function(a, b)
        return a.day < b.day
    end)
    
    return sortedRewards
end

-- Get reward by day number
function DailyRewardsConfig.getRewardByDay(dayNumber)
    for _, reward in ipairs(DailyRewardsConfig.rewards) do
        if reward.day == dayNumber then
            return reward
        end
    end
    return nil
end

-- Check what rewards are available based on current streak
function DailyRewardsConfig.getAvailableRewards(currentStreak)
    local availableRewards = {}
    for _, reward in ipairs(DailyRewardsConfig.rewards) do
        if currentStreak >= reward.day then
            table.insert(availableRewards, reward)
        end
    end
    return availableRewards
end

-- Get the next claimable reward based on streak
function DailyRewardsConfig.getNextClaimableReward(currentStreak)
    -- Look for the first reward that matches the current streak
    for _, reward in ipairs(DailyRewardsConfig.rewards) do
        if reward.day == currentStreak then
            return reward
        end
    end
    return nil -- No reward for this streak level (beyond day 10)
end

-- Format day display (e.g., "Day 1", "Day 10")
function DailyRewardsConfig.formatDay(dayNumber)
    return "Day " .. dayNumber
end

-- Calculate streak status based on login times
function DailyRewardsConfig.calculateStreakStatus(lastLoginTime, claimedDays)
    local currentTime = os.time()
    local dayInSeconds = 24 * 60 * 60
    
    -- If never logged in, start at day 1 and allow immediate claim
    if not lastLoginTime then
        return {
            currentStreak = 1,
            canClaim = true,
            streakBroken = false,
            nextRewardDay = 1
        }
    end
    
    local timeSinceLastLogin = currentTime - lastLoginTime
    local daysSinceLastLogin = math.floor(timeSinceLastLogin / dayInSeconds)
    
    -- Check if this is a first-time user (no claimed days yet)
    local maxClaimedDay = 0
    for day, _ in pairs(claimedDays or {}) do
        maxClaimedDay = math.max(maxClaimedDay, day)
    end
    local isFirstTimeUser = (maxClaimedDay == 0)
    
    -- If more than 1 day since last login
    if daysSinceLastLogin > 1 then
        -- If it's a first-time user, don't show streak as broken
        return {
            currentStreak = 1, -- Start/Reset to day 1
            canClaim = true,
            streakBroken = not isFirstTimeUser, -- Don't show as broken for first-time users
            nextRewardDay = 1
        }
    end
    
    -- If same day, check if first-time user or already claimed
    if daysSinceLastLogin == 0 then        
        -- First-time users can claim day 1 on the same day they join
        if isFirstTimeUser then
            return {
                currentStreak = 1,
                canClaim = true,
                streakBroken = false,
                nextRewardDay = 1
            }
        else
            -- Existing users can't claim again on the same day
            return {
                currentStreak = math.max(maxClaimedDay, 1), -- Ensure minimum streak of 1
                canClaim = false, -- Already claimed today
                streakBroken = false,
                nextRewardDay = math.min(maxClaimedDay + 1, 10)
            }
        end
    end
    
    -- If exactly 1 day since last login, can continue streak
    local nextDay = math.min(maxClaimedDay + 1, 10)
    
    return {
        currentStreak = math.max(nextDay, 1), -- Ensure minimum streak of 1
        canClaim = true,
        streakBroken = false,
        nextRewardDay = nextDay
    }
end

return DailyRewardsConfig