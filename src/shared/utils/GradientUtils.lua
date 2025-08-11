-- GradientUtils - Centralized gradient management for consistent UI styling
-- Provides reusable gradient definitions and utility functions for creating gradients

local React = require(game:GetService("ReplicatedStorage").Packages.react)

local GradientUtils = {}

-- =====================================
-- PREDEFINED GRADIENT CONFIGURATIONS
-- =====================================

-- Standard rainbow gradient (most commonly used across the app)
GradientUtils.RAINBOW = {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),     -- Red
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 165, 0)), -- Orange  
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)), -- Yellow
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),   -- Green
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),  -- Blue
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)), -- Indigo
        ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 0, 211))    -- Violet
    }),
    Rotation = 0 -- Horizontal by default
}

-- Alternative rainbow with cyan (used in some components)
GradientUtils.RAINBOW_CYAN = {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),     -- Red
        ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 127, 0)), -- Orange
        ColorSequenceKeypoint.new(0.32, Color3.fromRGB(255, 255, 0)), -- Yellow  
        ColorSequenceKeypoint.new(0.48, Color3.fromRGB(0, 255, 0)),   -- Green
        ColorSequenceKeypoint.new(0.64, Color3.fromRGB(0, 255, 255)), -- Cyan
        ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0, 0, 255)),   -- Blue
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255))    -- Magenta
    }),
    Rotation = 0
}

-- Diagonal rainbow (45 degrees)
GradientUtils.RAINBOW_DIAGONAL = {
    Color = GradientUtils.RAINBOW.Color,
    Rotation = 45
}

-- Shiny boost gradient (pink to blue for boost multipliers)
GradientUtils.SHINY_BOOST = {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 20, 147)),   -- Deep Pink
        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 105, 180)), -- Hot Pink
        ColorSequenceKeypoint.new(0.6, Color3.fromRGB(138, 43, 226)),  -- Blue Violet
        ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 144, 255))     -- Dodger Blue
    }),
    Rotation = 0
}

-- Black market gradient (dark themed for special items)
GradientUtils.BLACK_MARKET = {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 20)),      -- Very dark
        ColorSequenceKeypoint.new(0.25, Color3.fromRGB(40, 20, 40)),   -- Dark purple
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 20, 20)),    -- Dark red
        ColorSequenceKeypoint.new(0.75, Color3.fromRGB(40, 20, 60)),   -- Dark purple-blue
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20))       -- Very dark
    }),
    Rotation = 135
}

-- OP text gradient (dark orange-red to golden)
GradientUtils.OP_TEXT = {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 60, 20)), -- Dark orange-red
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 140, 0)), -- Orange
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 215, 0)) -- Golden
    }),
    Rotation = 90 -- Vertical gradient
}

-- Light rainbow gradient (for backgrounds with reduced opacity)
GradientUtils.LIGHT_RAINBOW = {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 100)),     -- Light Red
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 200, 100)), -- Light Orange
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 150)), -- Light Yellow
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 255, 150)),   -- Light Green
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(150, 150, 255)),  -- Light Blue
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(200, 150, 255)), -- Light Indigo
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 150, 255))    -- Light Violet
    }),
    Rotation = 45
}

-- Simple two-color gradients
GradientUtils.WHITE_TO_GRAY = {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))
    }),
    Rotation = 90
}

GradientUtils.LIGHT_TO_DARK_GRAY = {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(245, 245, 245)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))
    }),
    Rotation = 90
}

-- =====================================
-- UTILITY FUNCTIONS
-- =====================================

-- Create a custom gradient from an array of colors
-- @param colors: Array of {position, Color3} or {position, r, g, b}
-- @param rotation: Optional rotation angle (default: 0)
-- @return: Gradient configuration table
function GradientUtils.CreateGradient(colors, rotation)
    if not colors or #colors == 0 then
        warn("GradientUtils.CreateGradient: No colors provided")
        return GradientUtils.WHITE_TO_GRAY -- Fallback
    end
    
    if #colors == 1 then
        warn("GradientUtils.CreateGradient: Only one color provided, creating solid color gradient")
        local color = colors[1]
        local color3 = color.Color3 or Color3.fromRGB(color.r or color[2] or 255, color.g or color[3] or 255, color.b or color[4] or 255)
        return {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, color3),
                ColorSequenceKeypoint.new(1, color3)
            }),
            Rotation = rotation or 0
        }
    end
    
    local keypoints = {}
    for i, colorData in ipairs(colors) do
        local position, color3
        
        if type(colorData) == "table" then
            if colorData.position and colorData.Color3 then
                -- Format: {position = 0.5, Color3 = Color3.fromRGB(...)}
                position = colorData.position
                color3 = colorData.Color3
            elseif colorData.position and (colorData.r or colorData[2]) then
                -- Format: {position = 0.5, r = 255, g = 0, b = 0} or {position, r, g, b}
                position = colorData.position or colorData[1]
                color3 = Color3.fromRGB(colorData.r or colorData[2], colorData.g or colorData[3], colorData.b or colorData[4])
            elseif #colorData >= 4 then
                -- Format: {position, r, g, b}
                position = colorData[1]
                color3 = Color3.fromRGB(colorData[2], colorData[3], colorData[4])
            else
                warn("GradientUtils.CreateGradient: Invalid color format at index " .. i)
                color3 = Color3.fromRGB(255, 255, 255) -- Fallback to white
                position = (i - 1) / (#colors - 1) -- Auto-calculate position
            end
        else
            warn("GradientUtils.CreateGradient: Color data must be a table at index " .. i)
            color3 = Color3.fromRGB(255, 255, 255)
            position = (i - 1) / (#colors - 1)
        end
        
        -- Clamp position to 0-1 range
        position = math.max(0, math.min(1, position))
        
        table.insert(keypoints, ColorSequenceKeypoint.new(position, color3))
    end
    
    -- Sort keypoints by position
    table.sort(keypoints, function(a, b) return a.Time < b.Time end)
    
    return {
        Color = ColorSequence.new(keypoints),
        Rotation = rotation or 0
    }
end

-- Create a simple two-color gradient
-- @param color1: Color3 or {r, g, b}
-- @param color2: Color3 or {r, g, b}  
-- @param rotation: Optional rotation angle (default: 0)
-- @return: Gradient configuration table
function GradientUtils.CreateSimple(color1, color2, rotation)
    local c1 = color1
    local c2 = color2
    
    -- Convert {r, g, b} tables to Color3 if needed
    if type(color1) == "table" and not color1.R then
        c1 = Color3.fromRGB(color1[1] or color1.r, color1[2] or color1.g, color1[3] or color1.b)
    end
    if type(color2) == "table" and not color2.R then
        c2 = Color3.fromRGB(color2[1] or color2.r, color2[2] or color2.g, color2[3] or color2.b)
    end
    
    return {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, c1),
            ColorSequenceKeypoint.new(1, c2)
        }),
        Rotation = rotation or 0
    }
end

-- Apply a gradient configuration to a React UIGradient element
-- @param gradientConfig: Gradient configuration from this utility
-- @param customProps: Optional additional props to merge
-- @return: React UIGradient element
function GradientUtils.CreateReactGradient(gradientConfig, customProps)
    if not gradientConfig then
        warn("GradientUtils.CreateReactGradient: No gradient config provided")
        return nil
    end
    
    local props = {
        Color = gradientConfig.Color,
        Rotation = gradientConfig.Rotation or 0
    }
    
    -- Merge custom props if provided
    if customProps then
        for key, value in pairs(customProps) do
            props[key] = value
        end
    end
    
    return React.createElement("UIGradient", props)
end

-- Apply a gradient configuration to a traditional Roblox UIGradient instance
-- @param gradientConfig: Gradient configuration from this utility
-- @param uiGradient: Existing UIGradient instance to modify
function GradientUtils.ApplyGradient(gradientConfig, uiGradient)
    if not gradientConfig or not uiGradient then
        warn("GradientUtils.ApplyGradient: Missing gradient config or UIGradient instance")
        return
    end
    
    uiGradient.Color = gradientConfig.Color
    uiGradient.Rotation = gradientConfig.Rotation or 0
    
    -- Apply other properties if they exist in the config
    if gradientConfig.Transparency then
        uiGradient.Transparency = gradientConfig.Transparency
    end
    if gradientConfig.Offset then
        uiGradient.Offset = gradientConfig.Offset
    end
end

-- Get a modified version of a gradient with different rotation
-- @param gradientConfig: Base gradient configuration
-- @param newRotation: New rotation angle
-- @return: New gradient configuration with updated rotation
function GradientUtils.WithRotation(gradientConfig, newRotation)
    if not gradientConfig then return nil end
    
    return {
        Color = gradientConfig.Color,
        Rotation = newRotation,
        Transparency = gradientConfig.Transparency,
        Offset = gradientConfig.Offset
    }
end

-- Get a list of all predefined gradient names
-- @return: Array of gradient names
function GradientUtils.GetAvailableGradients()
    return {
        "RAINBOW",
        "RAINBOW_CYAN", 
        "RAINBOW_DIAGONAL",
        "SHINY_BOOST",
        "BLACK_MARKET",
        "OP_TEXT",
        "LIGHT_RAINBOW",
        "WHITE_TO_GRAY",
        "LIGHT_TO_DARK_GRAY"
    }
end

return GradientUtils