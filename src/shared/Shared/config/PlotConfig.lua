local PlotConfig = {}

-- Plot pricing and unlock requirements
-- Each rebirth unlocks 5 plots, 8 rows of 5 plots = 40 total
PlotConfig.PLOTS = {
    -- Row 1: Starter Plots (Rarity 1) - Rebirth 0
    [1] = {
        price = 100,
        rebirthsRequired = 0,
        name = "Starter Plot 1",
        rarity = 1
    },
    [2] = {
        price = 150,
        rebirthsRequired = 0,
        name = "Starter Plot 2",
        rarity = 1
    },
    [3] = {
        price = 200,
        rebirthsRequired = 0,
        name = "Starter Plot 3",
        rarity = 1
    },
    [4] = {
        price = 250,
        rebirthsRequired = 0,
        name = "Starter Plot 4",
        rarity = 1
    },
    [5] = {
        price = 300,
        rebirthsRequired = 0,
        name = "Starter Plot 5",
        rarity = 1
    },
    
    -- Row 2: Basic Plots (Rarity 1) - Rebirth 1
    [6] = {
        price = 400,
        rebirthsRequired = 1,
        name = "Basic Plot 1",
        rarity = 1
    },
    [7] = {
        price = 500,
        rebirthsRequired = 1,
        name = "Basic Plot 2",
        rarity = 1
    },
    [8] = {
        price = 600,
        rebirthsRequired = 1,
        name = "Basic Plot 3",
        rarity = 1
    },
    [9] = {
        price = 700,
        rebirthsRequired = 1,
        name = "Basic Plot 4",
        rarity = 1
    },
    [10] = {
        price = 800,
        rebirthsRequired = 1,
        name = "Basic Plot 5",
        rarity = 1
    },
    
    -- Row 3: Advanced Plots (Rarity 2) - Rebirth 2
    [11] = {
        price = 1000,
        rebirthsRequired = 2,
        name = "Advanced Plot 1",
        rarity = 2
    },
    [12] = {
        price = 1250,
        rebirthsRequired = 2,
        name = "Advanced Plot 2",
        rarity = 2
    },
    [13] = {
        price = 1500,
        rebirthsRequired = 2,
        name = "Advanced Plot 3",
        rarity = 2
    },
    [14] = {
        price = 1750,
        rebirthsRequired = 2,
        name = "Advanced Plot 4",
        rarity = 2
    },
    [15] = {
        price = 2000,
        rebirthsRequired = 2,
        name = "Advanced Plot 5",
        rarity = 2
    },
    
    -- Row 4: Enhanced Plots (Rarity 2) - Rebirth 3
    [16] = {
        price = 2500,
        rebirthsRequired = 3,
        name = "Enhanced Plot 1",
        rarity = 2
    },
    [17] = {
        price = 3000,
        rebirthsRequired = 3,
        name = "Enhanced Plot 2",
        rarity = 2
    },
    [18] = {
        price = 3500,
        rebirthsRequired = 3,
        name = "Enhanced Plot 3",
        rarity = 2
    },
    [19] = {
        price = 4000,
        rebirthsRequired = 3,
        name = "Enhanced Plot 4",
        rarity = 2
    },
    [20] = {
        price = 4500,
        rebirthsRequired = 3,
        name = "Enhanced Plot 5",
        rarity = 2
    },
    
    -- Row 5: Premium Plots (Rarity 3) - Rebirth 4
    [21] = {
        price = 5500,
        rebirthsRequired = 4,
        name = "Premium Plot 1",
        rarity = 3
    },
    [22] = {
        price = 6500,
        rebirthsRequired = 4,
        name = "Premium Plot 2",
        rarity = 3
    },
    [23] = {
        price = 7500,
        rebirthsRequired = 4,
        name = "Premium Plot 3",
        rarity = 3
    },
    [24] = {
        price = 8500,
        rebirthsRequired = 4,
        name = "Premium Plot 4",
        rarity = 3
    },
    [25] = {
        price = 9500,
        rebirthsRequired = 4,
        name = "Premium Plot 5",
        rarity = 3
    },
    
    -- Row 6: Elite Plots (Rarity 3) - Rebirth 5
    [26] = {
        price = 11000,
        rebirthsRequired = 5,
        name = "Elite Plot 1",
        rarity = 3
    },
    [27] = {
        price = 13000,
        rebirthsRequired = 5,
        name = "Elite Plot 2",
        rarity = 3
    },
    [28] = {
        price = 15000,
        rebirthsRequired = 5,
        name = "Elite Plot 3",
        rarity = 3
    },
    [29] = {
        price = 17000,
        rebirthsRequired = 5,
        name = "Elite Plot 4",
        rarity = 3
    },
    [30] = {
        price = 19000,
        rebirthsRequired = 5,
        name = "Elite Plot 5",
        rarity = 3
    },
    
    -- Row 7: Master Plots (Rarity 4) - Rebirth 6
    [31] = {
        price = 22000,
        rebirthsRequired = 6,
        name = "Master Plot 1",
        rarity = 4
    },
    [32] = {
        price = 26000,
        rebirthsRequired = 6,
        name = "Master Plot 2",
        rarity = 4
    },
    [33] = {
        price = 30000,
        rebirthsRequired = 6,
        name = "Master Plot 3",
        rarity = 4
    },
    [34] = {
        price = 34000,
        rebirthsRequired = 6,
        name = "Master Plot 4",
        rarity = 4
    },
    [35] = {
        price = 38000,
        rebirthsRequired = 6,
        name = "Master Plot 5",
        rarity = 4
    },
    
    -- Row 8: Legendary Plots (Rarity 5) - Rebirth 7
    [36] = {
        price = 45000,
        rebirthsRequired = 7,
        name = "Legendary Plot 1",
        rarity = 5
    },
    [37] = {
        price = 55000,
        rebirthsRequired = 7,
        name = "Legendary Plot 2",
        rarity = 5
    },
    [38] = {
        price = 65000,
        rebirthsRequired = 7,
        name = "Legendary Plot 3",
        rarity = 5
    },
    [39] = {
        price = 75000,
        rebirthsRequired = 7,
        name = "Legendary Plot 4",
        rarity = 5
    },
    [40] = {
        price = 85000,
        rebirthsRequired = 7,
        name = "Legendary Plot 5",
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

-- Rarity name mapping (extended to 50 rarities)
PlotConfig.RARITY_NAMES = {
    [1] = "Basic",
    [2] = "Common", 
    [3] = "Rare",
    [4] = "Epic",
    [5] = "Legendary",
    [6] = "Mythic",
    [7] = "Divine",
    [8] = "Celestial",
    [9] = "Cosmic",
    [10] = "Void",
    [11] = "Quantum",
    [12] = "Ethereal",
    [13] = "Transcendent",
    [14] = "Infinite",
    [15] = "Supreme",
    [16] = "Omnipotent",
    [17] = "Godlike",
    [18] = "Universal",
    [19] = "Multiversal",
    [20] = "Omniversal",
    [21] = "Primordial",
    [22] = "Apocalyptic",
    [23] = "Genesis",
    [24] = "Omega",
    [25] = "Alpha",
    [26] = "Nexus",
    [27] = "Singularity",
    [28] = "Paradox",
    [29] = "Eternal",
    [30] = "Immaculate",
    [31] = "Perfected",
    [32] = "Ascended",
    [33] = "Enlightened",
    [34] = "Crystalline",
    [35] = "Radiant",
    [36] = "Luminous",
    [37] = "Brilliant",
    [38] = "Prismatic",
    [39] = "Spectral",
    [40] = "Phantom",
    [41] = "Shadow",
    [42] = "Nightmare",
    [43] = "Forbidden",
    [44] = "Cursed",
    [45] = "Blessed",
    [46] = "Sacred",
    [47] = "Hallowed",
    [48] = "Exalted",
    [49] = "Glorified",
    [50] = "Perfection"
}

-- Plot colors for each state
-- Plot colors and transparency removed - plots keep their original appearance

-- Calculate dynamic rarity based on player rebirths and base plot rarity
function PlotConfig:GetDynamicRarity(plotId, playerRebirths)
    local plotData = self.PLOTS[plotId]
    if not plotData then
        return 1 -- Default to basic rarity
    end
    
    -- Dynamic rarity = base rarity + player rebirths
    -- This means a player with 0 rebirths gets base rarity
    -- A player with 10 rebirths gets base rarity + 10
    return plotData.rarity + playerRebirths
end

-- Get rarity name with fallback for very high rarities
function PlotConfig:GetRarityName(rarity)
    local rarityName = self.RARITY_NAMES[rarity]
    if rarityName then
        return rarityName
    else
        -- For extremely high rarities beyond our predefined names
        if rarity > 50 then
            return string.format("Tier %d", rarity)
        else
            return "Unknown"
        end
    end
end

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

function PlotConfig:ShouldPlotBeVisible(plotId, playerRebirths)
    local plotData = self.PLOTS[plotId]
    if not plotData then
        return false
    end
    
    local rebirthsRequired = plotData.rebirthsRequired
    local rebirthDifference = rebirthsRequired - playerRebirths
    
    -- Only show plots that are unlocked or unlock next rebirth
    return rebirthDifference <= 1
end

-- Plot color functions removed - plots keep their original appearance

function PlotConfig:GetPlotGUIText(plotId, state, playerRebirths)
    local plotData = self.PLOTS[plotId]
    if not plotData then
        return ""
    end
    
    if state == self.STATES.UNLOCKS_NEXT_REBIRTH then
        return string.format("%d rebirths required", plotData.rebirthsRequired)
    elseif state == self.STATES.UNLOCKED_CANT_AFFORD then
        -- Calculate dynamic rarity based on player rebirths
        local dynamicRarity = self:GetDynamicRarity(plotId, playerRebirths)
        local rarityName = self:GetRarityName(dynamicRarity)
        return string.format("%s Spawner\n%d", rarityName, plotData.price)
    elseif state == self.STATES.UNLOCKED_CAN_AFFORD then
        -- Calculate dynamic rarity based on player rebirths
        local dynamicRarity = self:GetDynamicRarity(plotId, playerRebirths)
        local rarityName = self:GetRarityName(dynamicRarity)
        return string.format("%s Spawner\n%d", rarityName, plotData.price)
    else
        -- PURCHASED or UNLOCKS_LATER show nothing
        return ""
    end
end

function PlotConfig:GetPlotGUIColor(state)
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

return PlotConfig