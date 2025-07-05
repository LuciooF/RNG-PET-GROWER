-- Rebirth Calculator Utility
-- Handles all rebirth-related calculations and predictions
-- Centralizes business logic for rebirth system

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RebirthConfig = require(ReplicatedStorage.Shared.config.RebirthConfig)

local RebirthCalculator = {}

-- Calculate progress towards next rebirth
function RebirthCalculator.calculateProgress(currentMoney, rebirthCost)
    if not currentMoney or not rebirthCost or rebirthCost <= 0 then
        return 0
    end
    return math.min((currentMoney / rebirthCost) * 100, 100)
end

-- Check if player can afford rebirth
function RebirthCalculator.canAffordRebirth(currentMoney, currentRebirths)
    local rebirthCost = RebirthConfig:GetRebirthCost(currentRebirths or 0)
    return currentMoney >= rebirthCost
end

-- Get rebirth cost for current rebirth level
function RebirthCalculator.getRebirthCost(currentRebirths)
    return RebirthConfig:GetRebirthCost(currentRebirths or 0)
end

-- Calculate multipliers
function RebirthCalculator.getCurrentMultiplier(rebirths)
    return RebirthConfig:GetMoneyMultiplier(rebirths or 0)
end

function RebirthCalculator.getNextMultiplier(rebirths)
    return RebirthConfig:GetMoneyMultiplier((rebirths or 0) + 1)
end

-- Smart date prediction based on progress
function RebirthCalculator.predictNextRebirthDate(currentMoney, rebirthCost, currentRebirths)
    local progress = RebirthCalculator.calculateProgress(currentMoney, rebirthCost)
    
    if RebirthCalculator.canAffordRebirth(currentMoney, currentRebirths) then
        return "Today!", "You can afford it now!"
    end
    
    if progress <= 0 then
        return "Tomorrow", "No progress yet, assuming 1 day"
    end
    
    -- Estimate based on current progress (assume linear progression)
    local remainingProgress = 100 - progress
    local estimatedDays = math.max(1, math.ceil(remainingProgress / math.max(progress, 1)))
    
    local explanation = string.format("Based on %.1f%% progress", progress)
    
    if estimatedDays == 1 then
        return "Tomorrow", explanation
    elseif estimatedDays <= 7 then
        return "In " .. estimatedDays .. " days", explanation
    else
        return "In 1 week+", "More than a week needed"
    end
end

-- Get achievement date (placeholder for now)
function RebirthCalculator.getAchievementDate(rebirths)
    if rebirths and rebirths > 0 then
        return os.date("%B %d, %Y")
    else
        return "Not achieved yet"
    end
end

return RebirthCalculator