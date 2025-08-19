-- AnimationService - Centralized animation management for UI components
-- Provides reusable, configurable animations with clean API
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local AnimationService = {}
AnimationService.__index = AnimationService

-- Animation Presets for consistency across the game
AnimationService.Presets = {
    -- Breathing animation (smooth scaling)
    BREATHING = {
        duration = 2, -- seconds for one complete cycle
        minScale = 1.0,
        maxScale = 1.05, -- 5% scale variation
        easing = Enum.EasingStyle.Sine,
        direction = Enum.EasingDirection.InOut,
        reverses = true,
        repeats = -1 -- infinite
    },
    
    -- Shake animation (attention-grabbing)
    SHAKE = {
        interval = 1.5, -- seconds between shakes
        growPhase = 0.1, -- seconds to grow
        shakePhase = 0.3, -- seconds to shake
        maxScale = 1.15, -- 15% growth
        shakeIntensity = 8, -- pixels of movement
        shakeFrequency = 25, -- oscillations per second
    },
    
    -- Pulse animation (for important items)
    PULSE = {
        duration = 0.5,
        minScale = 0.95,
        maxScale = 1.1,
        easing = Enum.EasingStyle.Back,
        direction = Enum.EasingDirection.Out
    },
    
    -- FLOAT preset removed - unused (all components use BOUNCE instead)
    
    -- Spin animation (continuous rotation)
    SPIN = {
        duration = 8, -- seconds for full rotation
        continuous = true,
        easing = Enum.EasingStyle.Linear
    },
    
    -- Bounce animation (replicates Pet Index UI bounce exactly)
    BOUNCE = {
        duration = 0.8, -- 0.8 seconds like Pet Index
        upOffset = 10, -- 10 pixels up like Pet Index
        downOffset = 10, -- 10 pixels down like Pet Index  
        pauseBetween = 0.5, -- 0.5 second pause like Pet Index
        easing = Enum.EasingStyle.Sine, -- Sine easing like Pet Index
        direction = Enum.EasingDirection.InOut
    }
}

-- Active animations tracker
local activeAnimations = {}
local animationIdCounter = 0

-- Initialize the service
function AnimationService:Initialize()
    -- Client-side cleanup when player leaves (BindToClose is server-only)
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    
    if player then
        player.AncestryChanged:Connect(function()
            if not player.Parent then
                self:CleanupAll()
            end
        end)
    end
    
    -- AnimationService initialized
end

-- Create a breathing animation (smooth size pulsing)
function AnimationService:CreateBreathingAnimation(target, customSettings)
    local settings = self:MergeSettings(self.Presets.BREATHING, customSettings)
    
    if not target or not target.Parent then
        warn("AnimationService: Invalid target for breathing animation")
        return nil
    end
    
    local originalSize = target.Size
    local tweenInfo = TweenInfo.new(
        settings.duration,
        settings.easing,
        settings.direction,
        settings.repeats,
        settings.reverses
    )
    
    local tween = TweenService:Create(target, tweenInfo, {
        Size = UDim2.new(settings.maxScale, 0, settings.maxScale, 0)
    })
    
    tween:Play()
    
    -- Track animation
    local animationId = self:GenerateAnimationId()
    activeAnimations[animationId] = {
        type = "breathing",
        tween = tween,
        target = target
    }
    
    -- Return handle for control
    return {
        id = animationId,
        Stop = function()
            self:StopAnimation(animationId)
        end,
        Pause = function()
            tween:Pause()
        end,
        Resume = function()
            tween:Play()
        end
    }
end

-- Create a shake animation for React components (uses callbacks instead of direct manipulation)
function AnimationService:CreateReactShakeAnimation(customSettings, callbacks)
    local settings = self:MergeSettings(self.Presets.SHAKE, customSettings)
    callbacks = callbacks or {}
    
    if not callbacks.onScaleChange or not callbacks.onRotationChange then
        warn("AnimationService: React shake animation requires onScaleChange and onRotationChange callbacks")
        return nil
    end
    
    local animationId = self:GenerateAnimationId()
    local isRunning = true
    
    -- Simple periodic shake using callbacks for React state
    local shakeLoop = task.spawn(function()
        while isRunning do
            task.wait(settings.interval)
            
            if not isRunning then break end
            
            -- Phase 1: Quick grow (100ms)
            for i = 1, 10 do
                if not isRunning then break end
                local progress = i / 10
                local scale = 1 + (settings.maxScale - 1) * progress
                callbacks.onScaleChange(scale)
                callbacks.onRotationChange(0)
                task.wait(settings.growPhase / 10)
            end
            
            if not isRunning then break end
            
            -- Phase 2: Shake with rotation while shrinking (400ms)
            local startTime = tick()
            while tick() - startTime < settings.shakePhase do
                if not isRunning then break end
                
                local elapsed = tick() - startTime
                local progress = elapsed / settings.shakePhase
                
                -- Shrink back to normal
                local scale = settings.maxScale - (settings.maxScale - 1) * progress
                callbacks.onScaleChange(scale)
                
                -- Shake rotation
                local shake = math.sin(elapsed * settings.shakeFrequency) * settings.shakeIntensity * (1 - progress)
                callbacks.onRotationChange(shake)
                
                task.wait()
            end
            
            -- Reset to normal
            if isRunning then
                callbacks.onScaleChange(1)
                callbacks.onRotationChange(0)
            end
        end
    end)
    
    -- Track animation
    activeAnimations[animationId] = {
        type = "reactShake",
        shakeLoop = shakeLoop
    }
    
    -- Return handle
    return {
        id = animationId,
        Stop = function()
            isRunning = false
            if shakeLoop then
                task.cancel(shakeLoop)
            end
            callbacks.onScaleChange(1)
            callbacks.onRotationChange(0)
            activeAnimations[animationId] = nil
        end
    }
end

-- CreateReactFloatAnimation removed - unused (all components use bounce instead)

-- Create a bounce animation for React components (replicates Pet Index UI bounce exactly)
function AnimationService:CreateReactBounceAnimation(customSettings, callbacks)
    local settings = self:MergeSettings(self.Presets.BOUNCE, customSettings)
    
    callbacks = callbacks or {}
    
    if not callbacks.onPositionChange then
        warn("AnimationService: React bounce animation requires onPositionChange callback")
        return nil
    end
    
    local animationId = self:GenerateAnimationId()
    local isRunning = true
    
    -- Bounce animation loop replicating Pet Index UI exactly
    local bounceLoop = task.spawn(function()
        while isRunning do
            -- Bounce up (0.8 seconds)
            local startTime = tick()
            while tick() - startTime < settings.duration do
                if not isRunning then break end
                
                local progress = (tick() - startTime) / settings.duration
                -- Use Sine easing like Pet Index
                local easedProgress = math.sin(progress * math.pi / 2)
                local currentOffset = -settings.upOffset * easedProgress -- Negative because up is negative Y
                callbacks.onPositionChange(currentOffset)
                
                task.wait()
            end
            
            if not isRunning then break end
            
            -- Bounce down (0.8 seconds)  
            startTime = tick()
            while tick() - startTime < settings.duration do
                if not isRunning then break end
                
                local progress = (tick() - startTime) / settings.duration
                -- Use Sine easing like Pet Index
                local easedProgress = math.sin(progress * math.pi / 2)
                local currentOffset = -settings.upOffset + (settings.upOffset + settings.downOffset) * easedProgress
                callbacks.onPositionChange(currentOffset)
                
                task.wait()
            end
            
            if not isRunning then break end
            
            -- Pause between bounces (0.5 seconds like Pet Index)
            task.wait(settings.pauseBetween)
        end
    end)
    
    -- Track animation
    activeAnimations[animationId] = {
        type = "reactBounce",
        bounceLoop = bounceLoop
    }
    
    -- Return handle
    return {
        id = animationId,
        Stop = function()
            isRunning = false
            if bounceLoop then
                task.cancel(bounceLoop)
            end
            callbacks.onPositionChange(0) -- Reset to base position
            activeAnimations[animationId] = nil
        end
    }
end

-- Create a pulse animation (quick scale pop)
function AnimationService:CreatePulseAnimation(target, customSettings, callback)
    local settings = self:MergeSettings(self.Presets.PULSE, customSettings)
    
    if not target or not target.Parent then
        warn("AnimationService: Invalid target for pulse animation")
        return nil
    end
    
    local originalSize = target.Size
    
    -- Create sequence: shrink -> grow -> normal
    local tweenInfo = TweenInfo.new(
        settings.duration / 2,
        settings.easing,
        settings.direction
    )
    
    -- Shrink first
    local shrinkTween = TweenService:Create(target, tweenInfo, {
        Size = UDim2.new(
            originalSize.X.Scale * settings.minScale,
            originalSize.X.Offset * settings.minScale,
            originalSize.Y.Scale * settings.minScale,
            originalSize.Y.Offset * settings.minScale
        )
    })
    
    -- Then grow
    local growTween = TweenService:Create(target, tweenInfo, {
        Size = UDim2.new(
            originalSize.X.Scale * settings.maxScale,
            originalSize.X.Offset * settings.maxScale,
            originalSize.Y.Scale * settings.maxScale,
            originalSize.Y.Offset * settings.maxScale
        )
    })
    
    -- Return to normal
    local normalTween = TweenService:Create(target, tweenInfo, {
        Size = originalSize
    })
    
    -- Chain animations
    shrinkTween.Completed:Connect(function()
        growTween:Play()
    end)
    
    growTween.Completed:Connect(function()
        normalTween:Play()
    end)
    
    normalTween.Completed:Connect(function()
        if callback then
            callback()
        end
    end)
    
    shrinkTween:Play()
    
    -- Track animation
    local animationId = self:GenerateAnimationId()
    activeAnimations[animationId] = {
        type = "pulse",
        tweens = {shrinkTween, growTween, normalTween},
        target = target
    }
    
    return {
        id = animationId,
        Stop = function()
            self:StopAnimation(animationId)
        end
    }
end

-- CreateFloatAnimation removed - unused (all components use React bounce instead)

-- Create a spin animation (continuous rotation)
function AnimationService:CreateSpinAnimation(target, customSettings)
    local settings = self:MergeSettings(self.Presets.SPIN, customSettings)
    
    if not target or not target.Parent then
        warn("AnimationService: Invalid target for spin animation")
        return nil
    end
    
    local tweenInfo = TweenInfo.new(
        settings.duration,
        settings.easing or Enum.EasingStyle.Linear,
        Enum.EasingDirection.InOut,
        -1, -- Infinite
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
    
    -- Track animation
    local animationId = self:GenerateAnimationId()
    activeAnimations[animationId] = {
        type = "spin",
        tween = tween,
        target = target
    }
    
    return {
        id = animationId,
        Stop = function()
            self:StopAnimation(animationId)
        end
    }
end

-- Stop a specific animation
function AnimationService:StopAnimation(animationId)
    local animation = activeAnimations[animationId]
    if not animation then
        return
    end
    
    -- Clean up based on animation type
    if animation.tween then
        animation.tween:Cancel()
    elseif animation.tweens then
        for _, tween in ipairs(animation.tweens) do
            tween:Cancel()
        end
    elseif animation.connection then
        animation.connection:Disconnect()
    end
    
    -- Reset target to original state if possible
    if animation.target and animation.target.Parent then
        -- Reset common properties
        if animation.originalSize then
            animation.target.Size = animation.originalSize
        end
        if animation.originalPosition then
            animation.target.Position = animation.originalPosition
        end
        if animation.originalRotation then
            animation.target.Rotation = animation.originalRotation
        end
    end
    
    activeAnimations[animationId] = nil
end

-- Stop all animations
function AnimationService:CleanupAll()
    for animationId, _ in pairs(activeAnimations) do
        self:StopAnimation(animationId)
    end
    activeAnimations = {}
end

-- Helper: Merge custom settings with preset
function AnimationService:MergeSettings(preset, custom)
    if not custom then
        return preset
    end
    
    local merged = {}
    for key, value in pairs(preset) do
        merged[key] = custom[key] or value
    end
    for key, value in pairs(custom) do
        if merged[key] == nil then
            merged[key] = value
        end
    end
    
    return merged
end

-- Helper: Generate unique animation ID
function AnimationService:GenerateAnimationId()
    animationIdCounter = animationIdCounter + 1
    return "animation_" .. animationIdCounter
end

-- Singleton pattern
local instance = AnimationService
instance:Initialize()

return instance