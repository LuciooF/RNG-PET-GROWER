-- AnimationServiceSimple - Simplified animation management for UI components
-- Provides basic, reliable animations with clean API
local TweenService = game:GetService("TweenService")

local AnimationServiceSimple = {}

-- Create a simple breathing animation (smooth scaling)
function AnimationServiceSimple:CreateBreathingAnimation(target, settings)
    settings = settings or {}
    local duration = settings.duration or 2
    local minScale = settings.minScale or 1.0
    local maxScale = settings.maxScale or 1.05
    
    if not target or not target.Parent then
        warn("AnimationServiceSimple: Invalid target for breathing animation")
        return nil
    end
    
    local tweenInfo = TweenInfo.new(
        duration,
        Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut,
        -1, -- Infinite repeats
        true -- Reverse
    )
    
    -- Calculate target size based on current size
    local currentSize = target.Size
    local targetSize = UDim2.new(
        currentSize.X.Scale * maxScale,
        currentSize.X.Offset * maxScale,
        currentSize.Y.Scale * maxScale,
        currentSize.Y.Offset * maxScale
    )
    
    local tween = TweenService:Create(target, tweenInfo, {
        Size = targetSize
    })
    
    tween:Play()
    
    -- Return control handle
    return {
        Stop = function()
            tween:Cancel()
            -- Reset to original size
            target.Size = currentSize
        end,
        Pause = function()
            tween:Pause()
        end,
        Resume = function()
            tween:Play()
        end
    }
end

-- Create a simple spinning animation (continuous rotation)
function AnimationServiceSimple:CreateSpinAnimation(target, settings)
    settings = settings or {}
    local duration = settings.duration or 8
    
    if not target or not target.Parent then
        warn("AnimationServiceSimple: Invalid target for spin animation")
        return nil
    end
    
    local tweenInfo = TweenInfo.new(
        duration,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.InOut,
        -1, -- Infinite repeats
        false -- Don't reverse
    )
    
    local tween = TweenService:Create(target, tweenInfo, {
        Rotation = 360
    })
    
    -- Reset rotation on completion to avoid accumulation
    tween.Completed:Connect(function()
        if target.Parent then
            target.Rotation = 0
        end
    end)
    
    tween:Play()
    
    -- Return control handle
    return {
        Stop = function()
            tween:Cancel()
            target.Rotation = 0
        end,
        Pause = function()
            tween:Pause()
        end,
        Resume = function()
            tween:Play()
        end
    }
end

-- Create a simple periodic pulse animation (for attention)
function AnimationServiceSimple:CreatePeriodicPulse(target, settings)
    settings = settings or {}
    local interval = settings.interval or 3
    local pulseDuration = settings.pulseDuration or 0.3
    local pulseScale = settings.pulseScale or 1.2
    
    if not target or not target.Parent then
        warn("AnimationServiceSimple: Invalid target for pulse animation")
        return nil
    end
    
    local originalSize = target.Size
    local isRunning = true
    
    -- Start the periodic pulse loop
    local pulseLoop = task.spawn(function()
        while isRunning and target.Parent do
            task.wait(interval)
            
            if not target.Parent then break end
            
            -- Create pulse animation
            local pulseTween = TweenService:Create(target, TweenInfo.new(
                pulseDuration / 2,
                Enum.EasingStyle.Back,
                Enum.EasingDirection.Out
            ), {
                Size = UDim2.new(
                    originalSize.X.Scale * pulseScale,
                    originalSize.X.Offset * pulseScale,
                    originalSize.Y.Scale * pulseScale,
                    originalSize.Y.Offset * pulseScale
                )
            })
            
            pulseTween:Play()
            pulseTween.Completed:Wait()
            
            if not target.Parent then break end
            
            -- Return to original size
            local returnTween = TweenService:Create(target, TweenInfo.new(
                pulseDuration / 2,
                Enum.EasingStyle.Back,
                Enum.EasingDirection.Out
            ), {
                Size = originalSize
            })
            
            returnTween:Play()
            returnTween.Completed:Wait()
        end
    end)
    
    -- Return control handle
    return {
        Stop = function()
            isRunning = false
            if pulseLoop then
                task.cancel(pulseLoop)
            end
            target.Size = originalSize
        end
    }
end

return AnimationServiceSimple