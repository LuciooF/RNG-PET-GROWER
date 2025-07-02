local ScreenUtils = {}

function ScreenUtils.getProportionalScale(currentSize, referenceSize, minScale, maxScale)
    local scaleX = currentSize.X / referenceSize.X
    local scaleY = currentSize.Y / referenceSize.Y
    local scale = math.min(scaleX, scaleY)
    
    return math.clamp(scale, minScale or 0.5, maxScale or 2.0)
end

function ScreenUtils.getProportionalTextSize(currentSize, baseTextSize)
    local scale = ScreenUtils.getProportionalScale(currentSize, Vector2.new(1920, 1080), 0.7, 1.5)
    return math.floor(baseTextSize * scale)
end

return ScreenUtils