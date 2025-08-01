-- RebirthUtils - Shared utilities for rebirth cost calculations
local RebirthUtils = {}

-- BALANCED: Exponential rebirth cost scaling starting at 500
function RebirthUtils.getRebirthCost(currentRebirths)
    -- Exponential scaling: 500, 2500, 12500, 62500, 312500...
    return math.floor(500 * (5 ^ (currentRebirths or 0)))
end

return RebirthUtils