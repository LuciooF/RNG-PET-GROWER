-- Animation Helpers
-- Shared animation functions used across UI components
-- Consolidates duplicated animation code from multiple components

local TweenService = game:GetService("TweenService")

local AnimationHelpers = {}

-- Animation timings and settings
local FLIP_DURATION = 0.6
local BOUNCE_DURATION = 0.1
local BOUNCE_SIZE_INCREASE = 6

-- Create flip animation for icons (360 degree rotation)
function AnimationHelpers.createFlipAnimation(iconRef, animationTracker)
    if not iconRef.current then return end
    
    -- Cancel any existing animation for this icon
    if animationTracker.current then
        animationTracker.current:Cancel()
        animationTracker.current:Destroy()
        animationTracker.current = nil
    end
    
    -- Reset rotation to 0 to prevent accumulation
    iconRef.current.Rotation = 0
    
    -- Create new animation
    animationTracker.current = TweenService:Create(
        iconRef.current,
        TweenInfo.new(FLIP_DURATION, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Rotation = 360 }
    )
    
    animationTracker.current:Play()
end

-- Create bounce animation for UI elements (scale up then back down)
function AnimationHelpers.createBounceAnimation(element)
    if not element then return end
    
    -- Store the original size since GridLayout controls position
    local originalSize = element.Size
    
    -- Create bounce animation (scale up slightly)
    local bounceUpTween = TweenService:Create(
        element,
        TweenInfo.new(BOUNCE_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { 
            Size = originalSize + UDim2.new(0, BOUNCE_SIZE_INCREASE, 0, BOUNCE_SIZE_INCREASE)
        }
    )
    
    bounceUpTween:Play()
    
    -- Create return animation
    bounceUpTween.Completed:Connect(function()
        -- Safety check: make sure the element still exists
        if not element or not element.Parent then return end
        
        local returnTween = TweenService:Create(
            element,
            TweenInfo.new(BOUNCE_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { 
                Size = originalSize -- Return to original size
            }
        )
        returnTween:Play()
    end)
end

-- Create smooth fade in animation
function AnimationHelpers.createFadeInAnimation(element, duration)
    if not element then return end
    
    duration = duration or 0.3
    element.BackgroundTransparency = 1
    
    local fadeIn = TweenService:Create(
        element,
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { BackgroundTransparency = 0 }
    )
    
    fadeIn:Play()
    return fadeIn
end

-- Create smooth fade out animation
function AnimationHelpers.createFadeOutAnimation(element, duration)
    if not element then return end
    
    duration = duration or 0.3
    
    local fadeOut = TweenService:Create(
        element,
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { BackgroundTransparency = 1 }
    )
    
    fadeOut:Play()
    return fadeOut
end

-- Create slide in animation from a direction
function AnimationHelpers.createSlideInAnimation(element, direction, duration)
    if not element then return end
    
    direction = direction or "bottom" -- "top", "bottom", "left", "right"
    duration = duration or 0.5
    
    local originalPosition = element.Position
    local startPosition
    
    -- Calculate start position based on direction
    if direction == "bottom" then
        startPosition = originalPosition + UDim2.new(0, 0, 1, 0)
    elseif direction == "top" then
        startPosition = originalPosition - UDim2.new(0, 0, 1, 0)
    elseif direction == "left" then
        startPosition = originalPosition - UDim2.new(1, 0, 0, 0)
    elseif direction == "right" then
        startPosition = originalPosition + UDim2.new(1, 0, 0, 0)
    end
    
    element.Position = startPosition
    
    local slideIn = TweenService:Create(
        element,
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Position = originalPosition }
    )
    
    slideIn:Play()
    return slideIn
end

-- Create pulse animation (scale up and down repeatedly)
function AnimationHelpers.createPulseAnimation(element, scale, duration)
    if not element then return end
    
    scale = scale or 1.1
    duration = duration or 1.0
    
    local originalSize = element.Size
    local scaledSize = originalSize * scale
    
    local pulseUp = TweenService:Create(
        element,
        TweenInfo.new(duration / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        { Size = scaledSize }
    )
    
    local pulseDown = TweenService:Create(
        element,
        TweenInfo.new(duration / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        { Size = originalSize }
    )
    
    -- Create looping pulse
    local function startPulse()
        pulseUp:Play()
        pulseUp.Completed:Connect(function()
            if element and element.Parent then
                pulseDown:Play()
                pulseDown.Completed:Connect(function()
                    if element and element.Parent then
                        startPulse()
                    end
                end)
            end
        end)
    end
    
    startPulse()
    
    -- Return function to stop the pulse
    return function()
        pulseUp:Cancel()
        pulseDown:Cancel()
        if element and element.Parent then
            element.Size = originalSize
        end
    end
end

return AnimationHelpers