-- RankUtils - Shared utility for player rank system based on rebirth count
local RankUtils = {}

-- Rank system based on rebirth count - COOLER early ranks for motivation!
local RANKS = {
    {minRebirths = 0, name = "Pet Rookie", emoji = "🌱"},
    {minRebirths = 1, name = "Pet Warrior", emoji = "⚔️"},
    {minRebirths = 2, name = "Pet Knight", emoji = "🛡️"},
    {minRebirths = 3, name = "Pet Champion", emoji = "🏆"},
    {minRebirths = 4, name = "Pet Guardian", emoji = "🛡️"},
    {minRebirths = 5, name = "Pet Master", emoji = "👑"},
    {minRebirths = 6, name = "Pet Legend", emoji = "🌟"},
    {minRebirths = 7, name = "Pet Hero", emoji = "🦸"},
    {minRebirths = 8, name = "Pet Titan", emoji = "⚡"},
    {minRebirths = 9, name = "Pet God", emoji = "🔥"},
    {minRebirths = 10, name = "Pet Overlord", emoji = "💎"},
    {minRebirths = 11, name = "Pet Emperor", emoji = "👑"},
    {minRebirths = 12, name = "Pet Deity", emoji = "🌌"},
    {minRebirths = 13, name = "Pet Cosmic", emoji = "🪐"},
    {minRebirths = 14, name = "Pet Eternal", emoji = "♾️"},
    {minRebirths = 15, name = "Pet Divine", emoji = "✨"},
    {minRebirths = 16, name = "Pet Celestial", emoji = "⭐"},
    {minRebirths = 17, name = "Pet Mythical", emoji = "🦄"},
    {minRebirths = 18, name = "Pet Legendary", emoji = "🔮"},
    {minRebirths = 19, name = "Pet Supreme", emoji = "👑"},
    {minRebirths = 20, name = "Pet Ultimate", emoji = "💫"},
    {minRebirths = 21, name = "Pet Transcendent", emoji = "🌈"},
    {minRebirths = 22, name = "Pet Omnipotent", emoji = "🔥"},
    {minRebirths = 23, name = "Pet Infinite", emoji = "∞"},
    {minRebirths = 24, name = "Pet Absolute", emoji = "⚡"},
    {minRebirths = 25, name = "Pet Primordial", emoji = "🌌"},
    {minRebirths = 30, name = "Pet Apex", emoji = "🔺"},
    {minRebirths = 35, name = "Pet Zenith", emoji = "🎯"},
    {minRebirths = 40, name = "Pet Quantum", emoji = "⚛️"},
    {minRebirths = 45, name = "Pet Singularity", emoji = "🕳️"},
    {minRebirths = 50, name = "Pet Multiverse", emoji = "🌍"},
    {minRebirths = 75, name = "Pet Reality", emoji = "👁️"},
    {minRebirths = 100, name = "Pet Existence", emoji = "🌟"},
    {minRebirths = 150, name = "Pet Creator", emoji = "🎨"},
    {minRebirths = 200, name = "Pet Architect", emoji = "🏗️"},
    {minRebirths = 300, name = "Pet Omniscient", emoji = "🧠"},
    {minRebirths = 500, name = "Pet Almighty", emoji = "⚡"},
    {minRebirths = 1000, name = "Pet Unfathomable", emoji = "🌀"},
}

-- Get rank info based on rebirth count
function RankUtils.getRankInfo(rebirthCount)
    local rankInfo = RANKS[1] -- Default to first rank
    
    for _, rank in ipairs(RANKS) do
        if rebirthCount >= rank.minRebirths then
            rankInfo = rank
        else
            break
        end
    end
    
    return rankInfo
end

-- Get current rank info
function RankUtils.getCurrentRank(rebirthCount)
    return RankUtils.getRankInfo(rebirthCount)
end

-- Get next rank info (for showing progression)
function RankUtils.getNextRank(rebirthCount)
    for _, rank in ipairs(RANKS) do
        if rebirthCount < rank.minRebirths then
            return rank
        end
    end
    return nil -- Already at max rank
end

-- Get progress to next rank (returns 0-1)
function RankUtils.getProgressToNextRank(rebirthCount)
    local currentRank = RankUtils.getCurrentRank(rebirthCount)
    local nextRank = RankUtils.getNextRank(rebirthCount)
    
    if not nextRank then
        return 1 -- Max rank reached
    end
    
    local currentThreshold = currentRank.minRebirths
    local nextThreshold = nextRank.minRebirths
    local progress = (rebirthCount - currentThreshold) / (nextThreshold - currentThreshold)
    
    return math.max(0, math.min(1, progress))
end

return RankUtils