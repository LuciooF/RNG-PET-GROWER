local PlotConfig = {}

-- Plot pricing and unlock requirements
PlotConfig.PLOTS = {
    -- Row 1: Basic Plots (Rarity 1)
    [1] = {
        price = 100,
        rebirthsRequired = 0,
        name = "Basic Plot 1",
        rarity = 1
    },
    [2] = {
        price = 100,
        rebirthsRequired = 0,
        name = "Basic Plot 2",
        rarity = 1
    },
    [3] = {
        price = 100,
        rebirthsRequired = 0,
        name = "Basic Plot 3",
        rarity = 1
    },
    [4] = {
        price = 100,
        rebirthsRequired = 0,
        name = "Basic Plot 4",
        rarity = 1
    },
    [5] = {
        price = 100,
        rebirthsRequired = 0,
        name = "Basic Plot 5",
        rarity = 1
    },
    
    -- Row 2: Advanced Plots (Rarity 2)
    [6] = {
        price = 500,
        rebirthsRequired = 0,
        name = "Advanced Plot 1",
        rarity = 2
    },
    [7] = {
        price = 500,
        rebirthsRequired = 1,
        name = "Advanced Plot 2",
        rarity = 2
    },
    [8] = {
        price = 500,
        rebirthsRequired = 1,
        name = "Advanced Plot 3",
        rarity = 2
    },
    [9] = {
        price = 500,
        rebirthsRequired = 1,
        name = "Advanced Plot 4",
        rarity = 2
    },
    [10] = {
        price = 500,
        rebirthsRequired = 1,
        name = "Advanced Plot 5",
        rarity = 2
    },
    
    -- Row 3: Premium Plots (Rarity 3)
    [11] = {
        price = 1000,
        rebirthsRequired = 2,
        name = "Premium Plot 1",
        rarity = 3
    },
    [12] = {
        price = 1000,
        rebirthsRequired = 2,
        name = "Premium Plot 2",
        rarity = 3
    },
    [13] = {
        price = 1000,
        rebirthsRequired = 2,
        name = "Premium Plot 3",
        rarity = 3
    },
    [14] = {
        price = 1000,
        rebirthsRequired = 2,
        name = "Premium Plot 4",
        rarity = 3
    },
    [15] = {
        price = 1000,
        rebirthsRequired = 2,
        name = "Premium Plot 5",
        rarity = 3
    },
    
    -- Row 4: Elite Plots (Rarity 4)
    [16] = {
        price = 2500,
        rebirthsRequired = 3,
        name = "Elite Plot 1",
        rarity = 4
    },
    [17] = {
        price = 2500,
        rebirthsRequired = 3,
        name = "Elite Plot 2",
        rarity = 4
    },
    [18] = {
        price = 2500,
        rebirthsRequired = 3,
        name = "Elite Plot 3",
        rarity = 4
    },
    [19] = {
        price = 2500,
        rebirthsRequired = 3,
        name = "Elite Plot 4",
        rarity = 4
    },
    [20] = {
        price = 2500,
        rebirthsRequired = 3,
        name = "Elite Plot 5",
        rarity = 4
    },
    
    -- Row 5: Master Plots (Rarity 5)
    [21] = {
        price = 5000,
        rebirthsRequired = 5,
        name = "Master Plot 1",
        rarity = 5
    },
    [22] = {
        price = 5000,
        rebirthsRequired = 5,
        name = "Master Plot 2",
        rarity = 5
    },
    [23] = {
        price = 5000,
        rebirthsRequired = 5,
        name = "Master Plot 3",
        rarity = 5
    },
    [24] = {
        price = 5000,
        rebirthsRequired = 5,
        name = "Master Plot 4",
        rarity = 5
    },
    [25] = {
        price = 5000,
        rebirthsRequired = 5,
        name = "Master Plot 5",
        rarity = 5
    }
}

-- Plot state constants
PlotConfig.STATES = {
    UNLOCKS_NEXT_REBIRTH = 1,
    UNLOCKS_LATER = 2,
    UNLOCKED_CANT_AFFORD = 3,
    UNLOCKED_CAN_AFFORD = 4,
    PURCHASED = 5
}

-- Plot colors for each state
PlotConfig.COLORS = {
    [PlotConfig.STATES.UNLOCKS_NEXT_REBIRTH] = Color3.fromRGB(0, 0, 0), -- Black
    [PlotConfig.STATES.UNLOCKS_LATER] = Color3.fromRGB(255, 255, 255), -- Will be invisible
    [PlotConfig.STATES.UNLOCKED_CANT_AFFORD] = Color3.fromRGB(255, 0, 0), -- Red
    [PlotConfig.STATES.UNLOCKED_CAN_AFFORD] = Color3.fromRGB(0, 255, 0), -- Green
    [PlotConfig.STATES.PURCHASED] = Color3.fromRGB(255, 255, 255) -- White
}

-- Transparency for each state
PlotConfig.TRANSPARENCY = {
    [PlotConfig.STATES.UNLOCKS_NEXT_REBIRTH] = 0, -- Visible
    [PlotConfig.STATES.UNLOCKS_LATER] = 1, -- Invisible
    [PlotConfig.STATES.UNLOCKED_CANT_AFFORD] = 0, -- Visible
    [PlotConfig.STATES.UNLOCKED_CAN_AFFORD] = 0, -- Visible
    [PlotConfig.STATES.PURCHASED] = 0 -- Visible
}

function PlotConfig:GetPlotData(plotId)
    return self.PLOTS[plotId]
end

function PlotConfig:GetPlotState(plotId, playerRebirths, playerMoney, isPurchased)
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

function PlotConfig:GetPlotColor(state)
    return self.COLORS[state] or Color3.fromRGB(255, 255, 255)
end

function PlotConfig:GetPlotTransparency(state)
    return self.TRANSPARENCY[state] or 0
end

function PlotConfig:GetPlotGUIText(plotId, state, playerRebirths)
    local plotData = self.PLOTS[plotId]
    if not plotData then
        return ""
    end
    
    if state == self.STATES.UNLOCKS_NEXT_REBIRTH then
        return string.format("%d rebirths required", plotData.rebirthsRequired)
    elseif state == self.STATES.UNLOCKED_CANT_AFFORD then
        return string.format("%d", plotData.price) -- No emoji, just number
    elseif state == self.STATES.UNLOCKED_CAN_AFFORD then
        return string.format("%d", plotData.price) -- No emoji, just number  
    else
        -- PURCHASED or UNLOCKS_LATER show nothing
        return ""
    end
end

function PlotConfig:GetPlotGUIColor(state)
    if state == self.STATES.UNLOCKED_CANT_AFFORD then
        return Color3.fromRGB(255, 0, 0) -- Red
    elseif state == self.STATES.UNLOCKED_CAN_AFFORD then
        return Color3.fromRGB(0, 255, 0) -- Green
    else
        return Color3.fromRGB(255, 255, 255) -- White
    end
end

return PlotConfig