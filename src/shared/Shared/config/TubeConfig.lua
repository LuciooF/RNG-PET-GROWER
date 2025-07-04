-- Tube Configuration
-- Centralized configuration for tube processing speeds and visual settings
-- This file makes it easy to balance tube performance without touching multiple files

local TubeConfig = {}

-- PROCESSING SPEED CONFIGURATION
-- Simplified: All tubes process at 1/s, so total rate = number of tubes
TubeConfig.PROCESSING_SPEEDS = {
    -- All tubes process at the same rate for simplicity
    TUBE_RATE = 1.0  -- Each tube processes 1 pet per second
}

-- GUI VISUAL CONFIGURATION
-- These settings control how tube GUIs look and behave
TubeConfig.GUI_SETTINGS = {
    -- Size and positioning
    guiSize = UDim2.new(0, 100, 0, 40),
    heightAboveTube = 6,
    
    -- Visual styling
    backgroundColor = Color3.fromRGB(50, 50, 50),
    backgroundTransparency = 0.2,
    cornerRadius = 6,
    
    -- Text appearance
    textColor = Color3.fromRGB(255, 255, 255),
    textSize = 14,
    font = Enum.Font.GothamBold,
    
    -- Border styling
    borderColor = Color3.fromRGB(255, 255, 255),
    borderThickness = 2,
    borderTransparency = 0.3,
    
    -- Animation settings
    pulseEnabled = true,
    pulseDuration = 2.0
}

-- BALANCE PRESETS
-- Pre-configured speed sets for different game phases
TubeConfig.BALANCE_PRESETS = {
    -- Early game (lower speeds for slower progression)
    EARLY_GAME = {
        DEFAULT_TUBE = 0.5,
        PRODUCTION_PLOTS = {
            [1] = 0.5, [2] = 0.75, [3] = 1.0, [4] = 1.25,
            [5] = 1.5, [6] = 1.75, [7] = 2.0, [8] = 2.25,
            [9] = 2.5, [10] = 3.0, [11] = 3.5, [12] = 4.0
        }
    },
    
    -- Late game (higher speeds for faster progression)
    LATE_GAME = {
        DEFAULT_TUBE = 2.0,
        PRODUCTION_PLOTS = {
            [1] = 2.0, [2] = 2.5, [3] = 3.0, [4] = 3.5,
            [5] = 4.0, [6] = 4.5, [7] = 5.0, [8] = 5.5,
            [9] = 6.0, [10] = 7.0, [11] = 8.0, [12] = 10.0
        }
    }
}

-- HELPER FUNCTIONS

-- Get processing speed for any tube (all tubes are the same now)
function TubeConfig:GetTubeSpeed()
    return self.PROCESSING_SPEEDS.TUBE_RATE
end

-- Get processing speed for default tube (same as any tube)
function TubeConfig:GetDefaultTubeSpeed()
    return self.PROCESSING_SPEEDS.TUBE_RATE
end

-- Get processing speed for a production plot tube (same as any tube)
function TubeConfig:GetProductionPlotSpeed(plotId)
    return self.PROCESSING_SPEEDS.TUBE_RATE
end

-- Apply a balance preset
function TubeConfig:ApplyBalancePreset(presetName)
    local preset = self.BALANCE_PRESETS[presetName]
    if not preset then
        warn("TubeConfig: Unknown balance preset:", presetName)
        return false
    end
    
    self.PROCESSING_SPEEDS.DEFAULT_TUBE = preset.DEFAULT_TUBE
    for plotId, speed in pairs(preset.PRODUCTION_PLOTS) do
        self.PROCESSING_SPEEDS.PRODUCTION_PLOTS[plotId] = speed
    end
    
    print("TubeConfig: Applied balance preset:", presetName)
    return true
end

-- Scale all speeds by a multiplier (for global speed adjustments)
function TubeConfig:ScaleAllSpeeds(multiplier)
    self.PROCESSING_SPEEDS.DEFAULT_TUBE = self.PROCESSING_SPEEDS.DEFAULT_TUBE * multiplier
    
    for plotId, speed in pairs(self.PROCESSING_SPEEDS.PRODUCTION_PLOTS) do
        self.PROCESSING_SPEEDS.PRODUCTION_PLOTS[plotId] = speed * multiplier
    end
    
    print(string.format("TubeConfig: Scaled all speeds by %.2fx", multiplier))
end

-- Update GUI settings
function TubeConfig:UpdateGUISettings(newSettings)
    for key, value in pairs(newSettings) do
        if self.GUI_SETTINGS[key] ~= nil then
            self.GUI_SETTINGS[key] = value
        end
    end
    
    print("TubeConfig: Updated GUI settings")
end

-- Get current configuration summary
function TubeConfig:GetConfigSummary()
    local summary = {
        defaultSpeed = self.PROCESSING_SPEEDS.DEFAULT_TUBE,
        productionSpeeds = {},
        totalMaxSpeed = self.PROCESSING_SPEEDS.DEFAULT_TUBE
    }
    
    for plotId, speed in pairs(self.PROCESSING_SPEEDS.PRODUCTION_PLOTS) do
        summary.productionSpeeds[plotId] = speed
        summary.totalMaxSpeed = summary.totalMaxSpeed + speed
    end
    
    return summary
end

return TubeConfig