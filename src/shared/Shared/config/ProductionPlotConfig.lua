local ProductionPlotConfig = {}

-- Production Plot pricing and unlock requirements
-- Each rebirth unlocks 1 production plot, 2 rows of 6 plots = 12 total
ProductionPlotConfig.PLOTS = {
    -- Row 1: Basic Production Plots
    [1] = {
        price = 500,
        rebirthsRequired = 0,
        name = "Production Plot 1",
        rarity = 1
    },
    [2] = {
        price = 750,
        rebirthsRequired = 1,
        name = "Production Plot 2",
        rarity = 1
    },
    [3] = {
        price = 1000,
        rebirthsRequired = 2,
        name = "Production Plot 3",
        rarity = 1
    },
    [4] = {
        price = 1500,
        rebirthsRequired = 3,
        name = "Production Plot 4",
        rarity = 2
    },
    [5] = {
        price = 2000,
        rebirthsRequired = 4,
        name = "Production Plot 5",
        rarity = 2
    },
    [6] = {
        price = 3000,
        rebirthsRequired = 5,
        name = "Production Plot 6",
        rarity = 2
    },
    
    -- Row 2: Advanced Production Plots
    [7] = {
        price = 4000,
        rebirthsRequired = 6,
        name = "Production Plot 7",
        rarity = 3
    },
    [8] = {
        price = 6000,
        rebirthsRequired = 7,
        name = "Production Plot 8",
        rarity = 3
    },
    [9] = {
        price = 8000,
        rebirthsRequired = 8,
        name = "Production Plot 9",
        rarity = 3
    },
    [10] = {
        price = 12000,
        rebirthsRequired = 9,
        name = "Production Plot 10",
        rarity = 4
    },
    [11] = {
        price = 16000,
        rebirthsRequired = 10,
        name = "Production Plot 11",
        rarity = 4
    },
    [12] = {
        price = 25000,
        rebirthsRequired = 11,
        name = "Production Plot 12",
        rarity = 5
    }
}

-- Plot state constants (same as regular plots)
ProductionPlotConfig.STATES = {
    UNLOCKS_NEXT_REBIRTH = 1,
    UNLOCKS_LATER = 2,
    UNLOCKED_CANT_AFFORD = 3,
    UNLOCKED_CAN_AFFORD = 4,
    PURCHASED = 5
}

function ProductionPlotConfig:GetPlotData(plotId)
    return self.PLOTS[plotId]
end

function ProductionPlotConfig:GetPlotState(plotId, playerRebirths, playerMoney, isPurchased)
    local plotData = self.PLOTS[plotId]
    if not plotData then
        return nil
    end
    
    -- If already purchased
    if isPurchased then
        return self.STATES.PURCHASED
    end
    
    local rebirthsRequired = plotData.rebirthsRequired
    local rebirthDifference = rebirthsRequired - playerRebirths
    
    -- If unlocks in more than 1 rebirth
    if rebirthDifference > 1 then
        return self.STATES.UNLOCKS_LATER
    end
    
    -- If unlocks at next rebirth (exactly 1 rebirth away)
    if rebirthDifference == 1 then
        return self.STATES.UNLOCKS_NEXT_REBIRTH
    end
    
    -- If already unlocked (rebirthDifference <= 0)
    if playerMoney >= plotData.price then
        return self.STATES.UNLOCKED_CAN_AFFORD
    else
        return self.STATES.UNLOCKED_CANT_AFFORD
    end
end

function ProductionPlotConfig:ShouldPlotBeVisible(plotId, playerRebirths)
    local plotData = self.PLOTS[plotId]
    if not plotData then
        return false
    end
    
    local rebirthsRequired = plotData.rebirthsRequired
    local rebirthDifference = rebirthsRequired - playerRebirths
    
    -- Only show plots that are unlocked or unlock next rebirth
    return rebirthDifference <= 1
end

function ProductionPlotConfig:GetPlotGUIText(plotId, state, playerRebirths)
    local plotData = self.PLOTS[plotId]
    if not plotData then
        return ""
    end
    
    if state == self.STATES.UNLOCKS_NEXT_REBIRTH then
        return string.format("%d rebirths required", plotData.rebirthsRequired)
    elseif state == self.STATES.UNLOCKED_CANT_AFFORD then
        return string.format("%d", plotData.price)
    elseif state == self.STATES.UNLOCKED_CAN_AFFORD then
        return string.format("%d", plotData.price)
    else
        -- PURCHASED or UNLOCKS_LATER show nothing
        return ""
    end
end

function ProductionPlotConfig:GetPlotGUIColor(state)
    if state == self.STATES.UNLOCKED_CANT_AFFORD then
        return Color3.fromRGB(255, 0, 0) -- Red (can't afford)
    elseif state == self.STATES.UNLOCKED_CAN_AFFORD then
        return Color3.fromRGB(0, 255, 0) -- Green (can afford)
    elseif state == self.STATES.UNLOCKS_NEXT_REBIRTH then
        return Color3.fromRGB(0, 0, 0) -- Black (needs rebirth)
    else
        return Color3.fromRGB(255, 255, 255) -- White (default)
    end
end

-- Get the rarity color for a production plot (matches cylinder colors)
function ProductionPlotConfig:GetPlotRarityColor(plotId)
    local plotData = self:GetPlotData(plotId)
    if not plotData then
        return Color3.fromRGB(139, 69, 19) -- Default brown
    end
    
    -- Use same colors as regular plots/cylinders
    local CYLINDER_COLORS = {
        [1] = Color3.fromRGB(139, 69, 19), -- Brown (Basic)
        [2] = Color3.fromRGB(169, 169, 169), -- Silver (Advanced)
        [3] = Color3.fromRGB(255, 215, 0), -- Gold (Premium)
        [4] = Color3.fromRGB(138, 43, 226), -- Purple (Elite)
        [5] = Color3.fromRGB(255, 20, 147) -- Pink (Master/Legendary)
    }
    
    local rarity = plotData.rarity
    return CYLINDER_COLORS[rarity] or CYLINDER_COLORS[1]
end

-- Calculate total processing rate from all owned production plots
function ProductionPlotConfig:CalculateTotalProcessingRate(ownedProductionPlots)
    -- Import TubeConfig for centralized speed management
    local TubeConfig = require(script.Parent.TubeConfig)
    
    -- Simple calculation: 1 base tube + number of production plots
    local tubeSpeed = TubeConfig:GetTubeSpeed()
    local totalTubes = 1 + #ownedProductionPlots -- 1 for Tube1 + production tubes
    local totalRate = totalTubes * tubeSpeed
    
    print(string.format("ProductionPlotConfig: %d tubes × %.1f/s = %.1f/s total", totalTubes, tubeSpeed, totalRate))
    return totalRate
end

-- Get processing speed for a specific production plot
function ProductionPlotConfig:GetPlotProcessingSpeed(plotId)
    local TubeConfig = require(script.Parent.TubeConfig)
    return TubeConfig:GetProductionPlotSpeed(plotId)
end

return ProductionPlotConfig