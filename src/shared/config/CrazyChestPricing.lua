-- CrazyChestPricing - Centralized pricing calculations for crazy chest upgrades
-- This ensures client and server use identical pricing logic
local CrazyChestPricing = {}

-- Calculate chest level upgrade cost (diamonds) - matches server's complex formula
function CrazyChestPricing.GetChestUpgradeCost(currentLevel)
    local level = currentLevel or 1
    
    -- Progressive scaling: starts gentle, gets steeper at higher levels
    -- Levels 1-5: ~500, 1000, 1750, 2750, 4000
    -- Levels 6-10: ~5500, 7500, 10000, 13000, 17000
    -- Levels 11+: Exponential growth
    
    if level <= 5 then
        -- Early levels: 500, 1000, 1750, 2750, 4000
        local costs = {500, 1000, 1750, 2750, 4000}
        return costs[level] or 4000
    elseif level <= 10 then
        -- Mid levels: more aggressive scaling
        local baseCost = 4000
        local levelOffset = level - 5
        return math.floor(baseCost + (levelOffset * levelOffset * 500) + (levelOffset * 1000))
    else
        -- High levels: exponential scaling
        local baseCost = 17000
        local levelOffset = level - 10
        return math.floor(baseCost * (1.4 ^ levelOffset))
    end
end

-- Calculate luck upgrade cost (diamonds) - complex progressive scaling
function CrazyChestPricing.GetLuckUpgradeCost(currentLuck)
    local luck = currentLuck or 1
    
    -- Progressive luck cost scaling: more expensive than chest levels
    if luck <= 3 then
        -- Early luck levels: 750, 1500, 2500
        return luck * 750
    elseif luck <= 7 then
        -- Mid luck levels: steeper increase
        local baseCost = 2500
        local levelOffset = luck - 3
        return math.floor(baseCost + (levelOffset * levelOffset * 750) + (levelOffset * 1500))
    else
        -- High luck levels: exponential
        local baseCost = 15000
        local levelOffset = luck - 7
        return math.floor(baseCost * (1.5 ^ levelOffset))
    end
end

-- Calculate chest reward multiplier
function CrazyChestPricing.GetChestRewardMultiplier(chestLevel)
    local level = chestLevel or 1
    return 1 + (level - 1) * 0.6 -- 60% increase per level (1x, 1.6x, 2.2x, 2.8x, etc.)
end

return CrazyChestPricing