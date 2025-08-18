-- PlotConfig - Centralized configuration for plot pricing and requirements
local PlotConfig = {}

-- Constants
PlotConfig.TOTAL_PLOTS = 49  -- Server has 49 plots total
PlotConfig.TOTAL_TUBEPLOTS = 10

-- Plot pricing configuration
local PLOT_BASE_COST = 75 -- Set to 75
local PLOT_SCALING_FACTOR = 1.8 -- Set to 1.8 (80% increment per plot)

-- TubePlot pricing configuration  
local TUBEPLOT_BASE_COST = 50
local TUBEPLOT_SCALING_FACTOR = 3.5 -- Aggressive 3.5x scaling

-- Rebirth requirement functions
function PlotConfig.getPlotRebirthRequirement(plotNumber)
    if plotNumber >= 1 and plotNumber <= 5 then
        return 0
    elseif plotNumber >= 8 and plotNumber <= 14 then
        return 1
    elseif plotNumber >= 15 and plotNumber <= 21 then
        return 2
    elseif plotNumber >= 22 and plotNumber <= 28 then
        return 4 -- Skip rebirth 3
    elseif plotNumber >= 29 and plotNumber <= 35 then
        return 5
    elseif plotNumber >= 36 and plotNumber <= 42 then
        return 6
    elseif plotNumber >= 43 and plotNumber <= 49 then
        return 7
    else
        return 999 -- Invalid plot numbers (6, 7)
    end
end

function PlotConfig.getTubePlotRebirthRequirement(tubePlotNumber)
    return tubePlotNumber - 1
end

-- Plot cost calculation
function PlotConfig.getPlotCost(plotNumber, playerRebirths)
    -- First plot is free
    if plotNumber == 1 then
        return 0
    end
    
    -- Apply rebirth-based multipliers to the base cost
    playerRebirths = playerRebirths or 0
    local rebirthMultiplier = 1.0
    
    if playerRebirths == 0 then
        -- First rebirth slightly easier (20% cheaper)
        rebirthMultiplier = 0.8
    elseif playerRebirths <= 2 then
        -- Normal pricing for rebirths 1-2
        rebirthMultiplier = 1.0
    elseif playerRebirths <= 4 then
        -- Double cost for rebirths 3-4
        rebirthMultiplier = 2.0
    else
        -- Triple cost after rebirth 5+
        rebirthMultiplier = 3.0
    end
    
    local finalCost = PLOT_BASE_COST * (PLOT_SCALING_FACTOR ^ (plotNumber - 2)) * rebirthMultiplier
    return math.floor(finalCost)
end

-- TubePlot cost calculation
function PlotConfig.getTubePlotCost(tubePlotNumber, playerRebirths)
    -- First tubeplot is free
    if tubePlotNumber == 1 then
        return 0
    end
    
    -- Make tube plots quite hard with aggressive scaling
    playerRebirths = playerRebirths or 0
    local baseCost = TUBEPLOT_BASE_COST
    local scalingFactor = TUBEPLOT_SCALING_FACTOR
    
    -- Even harder scaling for higher rebirths to maintain challenge
    if playerRebirths >= 4 then
        baseCost = 100
        scalingFactor = 4.0
    elseif playerRebirths >= 2 then
        baseCost = 75
        scalingFactor = 3.8
    end
    
    return math.floor(baseCost * (scalingFactor ^ (tubePlotNumber - 2)))
end

-- Helper function to check if plot is middle of row (for rebirth text display)
function PlotConfig.isMiddlePlotOfRow(plotNumber)
    if plotNumber >= 1 and plotNumber <= 5 then
        return plotNumber == 3 -- Middle of first row
    elseif plotNumber >= 8 and plotNumber <= 14 then
        return plotNumber == 11 -- Middle of second row
    elseif plotNumber >= 15 and plotNumber <= 21 then
        return plotNumber == 18 -- Middle of third row
    elseif plotNumber >= 22 and plotNumber <= 28 then
        return plotNumber == 25 -- Middle of fourth row
    elseif plotNumber >= 29 and plotNumber <= 35 then
        return plotNumber == 32 -- Middle of fifth row
    elseif plotNumber >= 36 and plotNumber <= 42 then
        return plotNumber == 39 -- Middle of sixth row
    elseif plotNumber >= 43 and plotNumber <= 49 then
        return plotNumber == 46 -- Middle of seventh row
    end
    return false
end

-- Helper function for tubeplot rebirth text display
function PlotConfig.shouldShowTubePlotRebirthText(tubePlotNumber, playerRebirths)
    local requiredRebirths = PlotConfig.getTubePlotRebirthRequirement(tubePlotNumber)
    -- Only show for NEXT rebirth tier and on first tubeplot that needs higher rebirth
    return requiredRebirths == (playerRebirths + 1) and 
           (tubePlotNumber == 1 or playerRebirths >= PlotConfig.getTubePlotRebirthRequirement(tubePlotNumber - 1))
end

return PlotConfig