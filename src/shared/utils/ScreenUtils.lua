-- ScreenUtils - Responsive design utilities for consistent UI across all screen sizes
local ScreenUtils = {}

local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

-- Base reference resolution (what we design for)
local BASE_RESOLUTION = Vector2.new(1920, 1080)

-- Get current screen size
function ScreenUtils.getScreenSize()
    local camera = workspace.CurrentCamera
    if camera then
        return camera.ViewportSize
    end
    return BASE_RESOLUTION
end

-- Get scale factor based on screen size
function ScreenUtils.getScaleFactor()
    local currentSize = ScreenUtils.getScreenSize()
    local scaleX = currentSize.X / BASE_RESOLUTION.X
    local scaleY = currentSize.Y / BASE_RESOLUTION.Y
    
    -- Use the smaller scale to maintain aspect ratio
    return math.min(scaleX, scaleY)
end

-- Get proportional size based on screen
function ScreenUtils.getProportionalSize(baseSize)
    local scale = ScreenUtils.getScaleFactor()
    if typeof(baseSize) == "UDim2" then
        -- Scale offset values only, keep scale values
        return UDim2.new(
            baseSize.X.Scale,
            baseSize.X.Offset * scale,
            baseSize.Y.Scale,
            baseSize.Y.Offset * scale
        )
    elseif typeof(baseSize) == "Vector2" then
        return baseSize * scale
    elseif typeof(baseSize) == "number" then
        return baseSize * scale
    end
    return baseSize
end

-- Get proportional position
function ScreenUtils.getProportionalPosition(basePosition)
    local scale = ScreenUtils.getScaleFactor()
    if typeof(basePosition) == "UDim2" then
        return UDim2.new(
            basePosition.X.Scale,
            basePosition.X.Offset * scale,
            basePosition.Y.Scale,
            basePosition.Y.Offset * scale
        )
    end
    return basePosition
end

-- Check if device is mobile
function ScreenUtils.isMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

-- Get safe area insets (for mobile notch/home indicator)
function ScreenUtils.getSafeAreaInsets()
    return GuiService:GetGuiInset()
end

-- Create responsive UDim2 size
function ScreenUtils.udim2(xScale, xOffset, yScale, yOffset)
    local scale = ScreenUtils.getScaleFactor()
    return UDim2.new(
        xScale or 0,
        (xOffset or 0) * scale,
        yScale or 0,
        (yOffset or 0) * scale
    )
end

-- Create responsive UDim size
function ScreenUtils.udim(scale, offset)
    local scaleFactor = ScreenUtils.getScaleFactor()
    return UDim.new(scale or 0, (offset or 0) * scaleFactor)
end

-- Get responsive text size
function ScreenUtils.getTextSize(baseSize)
    local scale = ScreenUtils.getScaleFactor()
    return math.max(8, math.floor(baseSize * scale)) -- Minimum 8 pixel text
end

-- Get responsive corner radius
function ScreenUtils.getCornerRadius(baseRadius)
    local scale = ScreenUtils.getScaleFactor()
    return math.max(2, math.floor(baseRadius * scale)) -- Minimum 2 pixel radius
end

-- Common responsive sizes for UI elements
ScreenUtils.SIZES = {
    -- Buttons
    SMALL_BUTTON = function() return ScreenUtils.udim2(0, 80, 0, 32) end,
    MEDIUM_BUTTON = function() return ScreenUtils.udim2(0, 120, 0, 40) end,
    LARGE_BUTTON = function() return ScreenUtils.udim2(0, 200, 0, 50) end,
    
    -- Icons
    SMALL_ICON = function() return ScreenUtils.udim2(0, 24, 0, 24) end,
    MEDIUM_ICON = function() return ScreenUtils.udim2(0, 32, 0, 32) end,
    LARGE_ICON = function() return ScreenUtils.udim2(0, 48, 0, 48) end,
    
    -- Panels
    SMALL_PANEL = function() return ScreenUtils.udim2(0, 300, 0, 200) end,
    MEDIUM_PANEL = function() return ScreenUtils.udim2(0, 500, 0, 350) end,
    LARGE_PANEL = function() return ScreenUtils.udim2(0, 700, 0, 500) end,
    
    -- Side elements
    SIDE_BUTTON_WIDTH = function() return ScreenUtils.udim2(0, 70, 0, 70) end,
}

-- Common responsive text sizes
ScreenUtils.TEXT_SIZES = {
    SMALL = function() return ScreenUtils.getTextSize(12) end,
    MEDIUM = function() return ScreenUtils.getTextSize(16) end,
    LARGE = function() return ScreenUtils.getTextSize(20) end,
    HEADER = function() return ScreenUtils.getTextSize(24) end,
    TITLE = function() return ScreenUtils.getTextSize(32) end,
}

-- Common responsive spacing
ScreenUtils.SPACING = {
    TINY = function() return ScreenUtils.getScaleFactor() * 4 end,
    SMALL = function() return ScreenUtils.getScaleFactor() * 8 end,
    MEDIUM = function() return ScreenUtils.getScaleFactor() * 16 end,
    LARGE = function() return ScreenUtils.getScaleFactor() * 24 end,
    HUGE = function() return ScreenUtils.getScaleFactor() * 32 end,
}

return ScreenUtils