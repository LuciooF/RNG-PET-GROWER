-- Screen Utilities
-- Shared responsive design functions used across UI components
-- Consolidates duplicated utility functions from multiple components

local ScreenUtils = {}

-- Base screen size for proportional scaling calculations
local BASE_SCREEN_SIZE = Vector2.new(1024, 768)

-- Minimum text size to ensure readability
local MIN_TEXT_SIZE = 12

-- Calculate proportional scale factor based on current screen size
function ScreenUtils.getProportionalScale(screenSize)
    return math.min(screenSize.X / BASE_SCREEN_SIZE.X, screenSize.Y / BASE_SCREEN_SIZE.Y)
end

-- Get proportionally scaled size value
function ScreenUtils.getProportionalSize(screenSize, size)
    return size * ScreenUtils.getProportionalScale(screenSize)
end

-- Get proportionally scaled text size with minimum threshold
function ScreenUtils.getProportionalTextSize(screenSize, size)
    return math.max(MIN_TEXT_SIZE, size * ScreenUtils.getProportionalScale(screenSize))
end

-- Get proportionally scaled padding value
function ScreenUtils.getProportionalPadding(screenSize, padding)
    return padding * ScreenUtils.getProportionalScale(screenSize)
end

-- Get proportionally scaled UDim2 offset
function ScreenUtils.getProportionalOffset(screenSize, offset)
    local scale = ScreenUtils.getProportionalScale(screenSize)
    return UDim2.new(0, offset.X.Offset * scale, 0, offset.Y.Offset * scale)
end

-- Get proportionally scaled UDim2 size
function ScreenUtils.getProportionalUDim2Size(screenSize, size)
    local scale = ScreenUtils.getProportionalScale(screenSize)
    return UDim2.new(
        size.X.Scale, 
        size.X.Offset * scale,
        size.Y.Scale, 
        size.Y.Offset * scale
    )
end

-- Constants for common screen sizes (for reference)
ScreenUtils.MOBILE_THRESHOLD = Vector2.new(480, 854)
ScreenUtils.TABLET_THRESHOLD = Vector2.new(768, 1024)
ScreenUtils.DESKTOP_THRESHOLD = Vector2.new(1024, 768)

-- Helper to determine device type
function ScreenUtils.getDeviceType(screenSize)
    if screenSize.X <= ScreenUtils.MOBILE_THRESHOLD.X then
        return "mobile"
    elseif screenSize.X <= ScreenUtils.TABLET_THRESHOLD.X then
        return "tablet"
    else
        return "desktop"
    end
end

return ScreenUtils