-- PlotConfig - Centralized configuration for plot pricing and requirements
local PlotConfig = {}

-- Constants
PlotConfig.TOTAL_PLOTS = 49  -- Server has 49 plots total
PlotConfig.TOTAL_TUBEPLOTS = 10

-- Level configuration mapping
PlotConfig.LEVEL_CONFIG = {
    [1] = {startPlot = 1, endPlot = 5, doors = 5, rebirthRequired = 0},
    [2] = {startPlot = 8, endPlot = 14, doors = 7, rebirthRequired = 1},
    [3] = {startPlot = 15, endPlot = 21, doors = 7, rebirthRequired = 2},
    [4] = {startPlot = 22, endPlot = 28, doors = 7, rebirthRequired = 4},
    [5] = {startPlot = 29, endPlot = 35, doors = 7, rebirthRequired = 5},
    [6] = {startPlot = 36, endPlot = 42, doors = 7, rebirthRequired = 6},
    [7] = {startPlot = 43, endPlot = 49, doors = 7, rebirthRequired = 7}
}

-- Plot pricing configuration
local PLOT_BASE_COST = 100 -- Reasonable base cost
local PLOT_SCALING_FACTOR = 1.6 -- Moderate scaling (60% increment per plot)

-- TubePlot pricing configuration  
local TUBEPLOT_BASE_COST = 150 -- Increased from 50 to 150 for much higher base cost
local TUBEPLOT_SCALING_FACTOR = 6.0 -- Increased from 3.5x to 6.0x for extreme scaling

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
    
    playerRebirths = playerRebirths or 0
    local plotIndex = plotNumber - 2
    
    -- Pure exponential scaling - no cap for aggressive high-end costs
    local baseCost = PLOT_BASE_COST * (PLOT_SCALING_FACTOR ^ plotIndex)
    
    -- Extreme rebirth multiplier that scales aggressively
    local rebirthMultiplier = 1.0 + (playerRebirths * playerRebirths * playerRebirths * 0.2) -- Cubic scaling: 0.2x, 1.6x, 5.4x, 12.8x, 25x, 43.2x...
    
    local finalCost = baseCost * rebirthMultiplier
    return math.floor(finalCost)
end

-- TubePlot cost calculation
function PlotConfig.getTubePlotCost(tubePlotNumber, playerRebirths)
    -- First tubeplot is free
    if tubePlotNumber == 1 then
        return 0
    end
    
    -- Use consistent tube plot pricing across all rebirth levels (no escalating difficulty)
    playerRebirths = playerRebirths or 0
    local baseCost = TUBEPLOT_BASE_COST -- Use base cost for all rebirth levels
    local scalingFactor = TUBEPLOT_SCALING_FACTOR -- Use base scaling for all rebirth levels
    
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

-- Helper function to get door number for a plot (used by PlotGUIService)
function PlotConfig.getDoorForPlot(plotNumber)
    if plotNumber == 6 or plotNumber == 7 then
        return nil -- These plots don't exist
    end
    
    for level, config in pairs(PlotConfig.LEVEL_CONFIG) do
        if plotNumber >= config.startPlot and plotNumber <= config.endPlot then
            return plotNumber - config.startPlot + 1
        end
    end
    
    return nil
end

return PlotConfig