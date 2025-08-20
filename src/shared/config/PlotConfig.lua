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
    
    -- Get the rebirth level where this plot unlocks
    local unlockRebirth = PlotConfig.getPlotRebirthRequirement(plotNumber)
    
    -- Use rebirth-relative pricing where last plot in tier costs ~80% of next rebirth
    local RebirthUtils = require(game.ReplicatedStorage.utils.RebirthUtils)
    local nextRebirthCost = RebirthUtils.getRebirthCost(unlockRebirth + 1)
    
    -- Define plot ranges for each tier
    local tierInfo = {}
    if plotNumber >= 1 and plotNumber <= 5 then
        tierInfo = {startPlot = 1, endPlot = 5, tierSize = 5}
    elseif plotNumber >= 8 and plotNumber <= 14 then
        tierInfo = {startPlot = 8, endPlot = 14, tierSize = 7}
    elseif plotNumber >= 15 and plotNumber <= 21 then
        tierInfo = {startPlot = 15, endPlot = 21, tierSize = 7}
    elseif plotNumber >= 22 and plotNumber <= 28 then
        tierInfo = {startPlot = 22, endPlot = 28, tierSize = 7}
    elseif plotNumber >= 29 and plotNumber <= 35 then
        tierInfo = {startPlot = 29, endPlot = 35, tierSize = 7}
    elseif plotNumber >= 36 and plotNumber <= 42 then
        tierInfo = {startPlot = 36, endPlot = 42, tierSize = 7}
    elseif plotNumber >= 43 and plotNumber <= 49 then
        tierInfo = {startPlot = 43, endPlot = 49, tierSize = 7}
    end
    
    -- Position within tier (0 = first plot, 1 = last plot)
    local tierPosition = (plotNumber - tierInfo.startPlot) / (tierInfo.tierSize - 1)
    
    -- NEW SYSTEM: Total of all available plots = 90% of current rebirth cost
    -- Create ordered list of all available plots for progressive pricing
    local availablePlotNumbers = {}
    for i = 1, 49 do
        if PlotConfig.getPlotRebirthRequirement(i) <= playerRebirths then
            table.insert(availablePlotNumbers, i)
        end
    end
    
    -- Get current rebirth cost (what player paid to reach their current level)
    local currentRebirthCost = RebirthUtils.getRebirthCost(playerRebirths)
    
    -- Target: all available plots should total 90% of current rebirth cost
    local targetTotalCost = currentRebirthCost * 0.9
    
    -- Find this plot's position in the ordered list of available plots
    local plotPosition = 0
    for i, availablePlotNumber in ipairs(availablePlotNumbers) do
        if availablePlotNumber == plotNumber then
            plotPosition = i
            break
        end
    end
    
    -- Skip plot 1 (free) in calculations
    local paidPlots = #availablePlotNumbers - 1 -- Subtract 1 for free plot 1
    local paidPlotIndex = plotPosition - 1 -- Position among paid plots (plot 1 is index 0, skipped)
    
    if paidPlotIndex <= 0 then
        -- This is plot 1 (free) or something went wrong
        return 0
    end
    
    -- Progressive pricing: each plot costs more than the previous
    -- Use quadratic growth for smooth progression
    local plotWeight = paidPlotIndex ^ 1.5 -- Quadratic-ish growth for smooth progression
    
    -- Calculate total weight for all paid plots
    local totalWeight = 0
    for i = 1, paidPlots do
        totalWeight = totalWeight + (i ^ 1.5)
    end
    
    -- Calculate this plot's cost as its weighted share of the target total
    local finalCost = (targetTotalCost * plotWeight) / totalWeight
    
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