local RebirthConfig = {}

-- Rebirth system configuration
-- Easily adjustable multipliers for game balance

-- Money multipliers for each rebirth level
-- 0 rebirths = 1.0x (no bonus)
-- 1 rebirth = 1.25x 
-- 2 rebirths = 1.5x
-- 3 rebirths = 1.75x, etc.
RebirthConfig.MONEY_MULTIPLIERS = {
    [0] = 1.0,    -- No rebirths, no bonus
    [1] = 1.25,   -- 25% bonus
    [2] = 1.5,    -- 50% bonus
    [3] = 1.75,   -- 75% bonus
    [4] = 2.0,    -- 100% bonus
    [5] = 2.25,   -- 125% bonus
    [6] = 2.5,    -- 150% bonus
    [7] = 2.75,   -- 175% bonus
    [8] = 3.0,    -- 200% bonus
    [9] = 3.25,   -- 225% bonus
    [10] = 3.5,   -- 250% bonus
}

-- Money reset amount when rebirthing
RebirthConfig.REBIRTH_MONEY_RESET = 100

-- Dynamic rebirth costs based on progression
RebirthConfig.REBIRTH_COSTS = {
    [0] = 300,      -- First rebirth - 300
    [1] = 3000,     -- Second rebirth - 3k
    [2] = 30000,    -- Third rebirth - 30k
    [3] = 100000,   -- Fourth rebirth - 100k
    [4] = 300000,   -- Fifth rebirth - 300k
    [5] = 600000,   -- Sixth rebirth - 600k
    [6] = 1000000,  -- Seventh rebirth - 1m
    [7] = 2000000   -- Eighth rebirth and beyond
}

-- Legacy support - use dynamic calculation
RebirthConfig.MINIMUM_MONEY_TO_REBIRTH = 1000

-- Get dynamic rebirth cost based on current rebirth count
function RebirthConfig:GetRebirthCost(currentRebirths)
    local rebirths = currentRebirths or 0
    
    -- If we have a specific cost defined, use it
    if self.REBIRTH_COSTS[rebirths] then
        return self.REBIRTH_COSTS[rebirths]
    end
    
    -- For very high rebirth counts, use exponential scaling
    -- Cost = 30,000,000 * (2.5 ^ (rebirths - 7))
    local baseCost = 30000000
    local multiplier = math.pow(2.5, rebirths - 7)
    return math.floor(baseCost * multiplier)
end

-- Get money multiplier for a given rebirth count
function RebirthConfig:GetMoneyMultiplier(rebirths)
    -- If we have a specific multiplier defined, use it
    if self.MONEY_MULTIPLIERS[rebirths] then
        return self.MONEY_MULTIPLIERS[rebirths]
    end
    
    -- For very high rebirth counts, use a formula
    -- Base 1.0 + (rebirths * 0.25) with a reasonable cap
    local multiplier = 1.0 + (rebirths * 0.25)
    
    -- Cap at 10x multiplier to prevent infinite scaling
    return math.min(multiplier, 10.0)
end

-- Calculate money with rebirth multiplier applied
function RebirthConfig:CalculateMoneyWithMultiplier(baseAmount, rebirths)
    local multiplier = self:GetMoneyMultiplier(rebirths)
    return math.floor(baseAmount * multiplier)
end

-- Get rebirth requirements (for future use)
function RebirthConfig:GetRebirthRequirements(currentRebirths)
    -- Could add requirements like "need X money" or "need Y pets" etc.
    return {
        moneyRequired = self.MINIMUM_MONEY_TO_REBIRTH,
        -- Could add more requirements here later
    }
end

return RebirthConfig