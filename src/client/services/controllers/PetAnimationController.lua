-- Pet Animation Controller
-- Handles all pet animations including growth, floating, and rotation
-- Extracted from PetGrowthService.lua for better modularity

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local PetAnimationController = {}

-- Animation configuration
local PET_FLOAT_SPEED = 2 -- floating animation speed
local PET_FLOAT_AMPLITUDE = 0.1 -- how much the pet moves up/down (reduced from 0.2)
local PET_ROTATION_SPEED = 0.5 -- rotation speed for full 360 (radians per second)
local PET_PHASE_TIME = 5 -- seconds to grow actual pet
local EGG_PHASE_TIME = 5 -- seconds to show egg

-- Internal state
local connection = nil
local lastUpdateTime = 0
local UPDATE_FREQUENCY = 0.05 -- Update every 0.05 seconds for smoother movement
local cachedModelData = {} -- Cache model parts for better performance

-- Initialize the animation controller
function PetAnimationController:Initialize()
    -- Start animation update loop
    if connection then
        connection:Disconnect()
    end
    
    connection = RunService.Heartbeat:Connect(function()
        self:updateAnimations()
    end)
end

-- Set the active pets table reference and model factory
function PetAnimationController:setActivePets(activePetsRef, modelFactory)
    self.activePets = activePetsRef
    self.modelFactory = modelFactory
end

-- Update all pet animations
function PetAnimationController:updateAnimations()
    local currentTime = tick()
    if currentTime - lastUpdateTime < UPDATE_FREQUENCY then
        return -- Skip this frame
    end
    lastUpdateTime = currentTime
    
    if not self.activePets then return end
    
    local deltaTime = UPDATE_FREQUENCY -- Use fixed delta for consistency
    
    for plotId, petInfo in pairs(self.activePets) do
        if petInfo.model and petInfo.model.Parent then
            -- Only update if pet is animating or fully grown (skip static pets)
            if not petInfo.isAnimating and not petInfo.isFullyGrown then
                continue
            end
            
            -- Update animation offsets (animate both growing and fully grown pets)
            petInfo.rotationOffset = petInfo.rotationOffset + (PET_ROTATION_SPEED * deltaTime)
            
            -- Calculate full 360-degree rotation (continuous spinning)
            local rotationY = petInfo.rotationOffset -- Direct rotation, no amplitude needed
            
            -- Calculate floating offset if fully grown
            local floatOffset = 0
            if petInfo.isFullyGrown then
                petInfo.floatOffset = petInfo.floatOffset + (PET_FLOAT_SPEED * deltaTime)
                floatOffset = math.sin(petInfo.floatOffset) * PET_FLOAT_AMPLITUDE
            end
            
            -- Apply rotation and position
            if petInfo.model:IsA("Model") and petInfo.model.PrimaryPart then
                -- Simple approach: rotate the entire model using SetPrimaryPartCFrame
                local currentCenter = petInfo.model.PrimaryPart.Position + Vector3.new(0, floatOffset, 0)
                local rotationCFrame = CFrame.new(currentCenter) * CFrame.Angles(0, rotationY, 0)
                petInfo.model:SetPrimaryPartCFrame(rotationCFrame)
            else
                -- Fallback for single part or models without PrimaryPart
                local currentPos = petInfo.spawnPosition + Vector3.new(0, floatOffset, 0)
                petInfo.model.CFrame = CFrame.new(currentPos) * CFrame.Angles(0, rotationY, 0)
            end
        else
            -- Clean up invalid cache entries
            local modelId = tostring(petInfo.model)
            if cachedModelData[modelId] then
                cachedModelData[modelId] = nil
            end
        end
    end
end

-- Start egg phase animation (just waiting)
function PetAnimationController:startEggPhaseAnimation(plotId, onComplete)
    task.spawn(function()
        -- Phase 1: Just wait for 5 seconds (egg stays at full size)
        task.wait(EGG_PHASE_TIME)
        
        if self.activePets and self.activePets[plotId] then
            -- Egg phase complete, call completion callback
            if onComplete then
                onComplete(plotId)
            end
        end
    end)
end

-- Start pet growth animation with scaling
function PetAnimationController:startPetGrowthAnimation(plotId, onComplete)
    if not self.activePets or not self.activePets[plotId] then return end
    
    local petInfo = self.activePets[plotId]
    
    -- Phase 2: Grow pet for remaining 5 seconds
    local scaleValue = Instance.new("NumberValue")
    scaleValue.Value = 0.03 -- Start scale (matches the new smaller start)
    
    -- Determine end scale based on original scale (but smaller)
    local endScale = petInfo.originalScale.X * 0.3 -- Make final size 30% of original
    
    local growthTween = TweenService:Create(scaleValue,
        TweenInfo.new(PET_PHASE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Value = endScale} -- End scale based on model type
    )
    
    scaleValue.Changed:Connect(function(newScale)
        if self.activePets and self.activePets[plotId] and self.activePets[plotId].model then
            local scale = Vector3.new(newScale, newScale, newScale)
            if self.modelFactory then
                self.modelFactory.scaleModel(self.activePets[plotId].model, scale)
            end
            self.activePets[plotId].currentScale = scale
        end
    end)
    
    growthTween:Play()
    growthTween.Completed:Connect(function()
        if self.activePets and self.activePets[plotId] then
            self.activePets[plotId].isFullyGrown = true
            if onComplete then
                onComplete(plotId, true)
            end
        end
        
        growthTween:Destroy()
        scaleValue:Destroy()
    end)
end

-- Cleanup animations
function PetAnimationController:cleanup()
    if connection then
        connection:Disconnect()
        connection = nil
    end
end

return PetAnimationController