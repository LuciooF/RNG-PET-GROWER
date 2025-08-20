-- RebirthUtils - Shared utilities for rebirth cost calculations
local RebirthUtils = {}

-- BALANCED: Exponential rebirth cost scaling with 7x multiplier
function RebirthUtils.getRebirthCost(currentRebirths)
    -- Exponential scaling: 500, 3500, 24500, 171500, 1200500...
    return math.floor(500 * (7 ^ (currentRebirths or 0)))
end

return RebirthUtils