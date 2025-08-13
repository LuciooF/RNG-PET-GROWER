-- WelcomeCameraService - Handles the welcome camera animation when player joins
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local WelcomeCameraService = {}
local player = Players.LocalPlayer

-- Animation settings
local ANIMATION_DURATION = 4 -- seconds for the full animation
local START_HEIGHT_OFFSET = 50 -- How high above the map center to start
local END_HEIGHT_OFFSET = 20 -- How high above player area to end
local EASE_STYLE = Enum.EasingStyle.Quart
local EASE_DIRECTION = Enum.EasingDirection.Out

-- State
local animationInProgress = false
local originalCameraType = nil
local originalCFrame = nil

function WelcomeCameraService:Initialize()
    print("WelcomeCameraService: Initializing...")
end

-- Get the center point of the map (you may need to adjust these coordinates)
function WelcomeCameraService:GetMapCenter()
    -- Find the center of the map - you might want to adjust these coordinates
    -- based on your actual map layout
    local mapCenter = Vector3.new(0, 0, 0) -- Default center
    
    -- Try to find a part named "MapCenter" or similar landmark
    local mapCenterPart = Workspace:FindFirstChild("MapCenter")
    if mapCenterPart and mapCenterPart:IsA("BasePart") then
        mapCenter = mapCenterPart.Position
    else
        -- Try to calculate center based on spawns or other landmarks
        local spawns = Workspace:FindFirstChild("SpawnLocation")
        if spawns then
            mapCenter = spawns.Position
        end
    end
    
    return mapCenter
end

-- Get the player's area position
function WelcomeCameraService:GetPlayerAreaPosition()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        -- Fallback to spawn location or default position
        return Vector3.new(0, 10, 20)
    end
    
    local playerPosition = player.Character.HumanoidRootPart.Position
    
    -- Add some offset to get a good camera angle
    local cameraOffset = Vector3.new(0, END_HEIGHT_OFFSET, 15) -- Behind and above player
    return playerPosition + cameraOffset
end

-- Calculate a good camera CFrame looking at a target
function WelcomeCameraService:CalculateCameraLookAt(position, target)
    return CFrame.lookAt(position, target)
end

-- Start the welcome animation
function WelcomeCameraService:StartWelcomeAnimation()
    print("WelcomeCameraService: StartWelcomeAnimation called")
    
    if animationInProgress then
        print("WelcomeCameraService: Animation already in progress")
        return
    end
    
    local camera = Workspace.CurrentCamera
    if not camera then
        warn("WelcomeCameraService: No camera found")
        return
    end
    
    print("WelcomeCameraService: Camera found, checking character...")
    
    -- Wait for player character to load (with timeout)
    local maxWait = 10 -- Maximum 10 seconds to wait for character
    local startTime = tick()
    
    while (not player.Character or not player.Character:FindFirstChild("HumanoidRootPart")) and (tick() - startTime) < maxWait do
        if not player.Character then
            print("WelcomeCameraService: No character, waiting...")
        else
            print("WelcomeCameraService: Character exists but no HumanoidRootPart, waiting...")
        end
        task.wait(0.1)
    end
    
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        warn("WelcomeCameraService: Character/HumanoidRootPart not ready after 10 seconds, starting animation anyway")
    else
        print("WelcomeCameraService: Character ready, starting animation...")
    end
    
    animationInProgress = true
    
    -- Store original camera settings
    originalCameraType = camera.CameraType
    originalCFrame = camera.CFrame
    
    -- Set camera to scriptable mode
    print("WelcomeCameraService: Setting camera to scriptable mode")
    camera.CameraType = Enum.CameraType.Scriptable
    
    -- Calculate start and end positions
    local mapCenter = self:GetMapCenter()
    local playerArea = self:GetPlayerAreaPosition()
    
    print("WelcomeCameraService: Map center:", mapCenter)
    print("WelcomeCameraService: Player area:", playerArea)
    
    local startPosition = mapCenter + Vector3.new(0, START_HEIGHT_OFFSET, 25)
    local endPosition = playerArea
    
    print("WelcomeCameraService: Start position:", startPosition)
    print("WelcomeCameraService: End position:", endPosition)
    
    -- Calculate start and end CFrames (looking at targets)
    local startCFrame = self:CalculateCameraLookAt(startPosition, mapCenter)
    local endTarget = mapCenter -- Default target
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        endTarget = player.Character.HumanoidRootPart.Position
    end
    local endCFrame = self:CalculateCameraLookAt(endPosition, endTarget)
    
    -- Set initial camera position
    camera.CFrame = startCFrame
    
    print("WelcomeCameraService: Starting animation from", startPosition, "to", endPosition)
    
    -- Create the tween animation
    local tweenInfo = TweenInfo.new(
        ANIMATION_DURATION,
        EASE_STYLE,
        EASE_DIRECTION,
        0, -- Repeat count
        false, -- Reverse
        0 -- Delay
    )
    
    -- Create a part to tween (since we can't tween CFrame directly)
    local tweenTarget = {
        Position = startPosition,
        LookAt = mapCenter
    }
    
    local tween = TweenService:Create(
        tweenTarget,
        tweenInfo,
        {
            Position = endPosition,
            LookAt = endTarget
        }
    )
    
    -- Update camera position during tween
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not animationInProgress then
            connection:Disconnect()
            return
        end
        
        -- Update camera CFrame based on tween progress
        local currentCFrame = self:CalculateCameraLookAt(tweenTarget.Position, tweenTarget.LookAt)
        camera.CFrame = currentCFrame
    end)
    
    -- Start the tween
    tween:Play()
    
    -- When animation completes
    tween.Completed:Connect(function()
        connection:Disconnect()
        self:FinishWelcomeAnimation()
    end)
end

-- Finish the animation and restore normal camera
function WelcomeCameraService:FinishWelcomeAnimation()
    print("WelcomeCameraService: Animation complete, restoring camera")
    
    local camera = Workspace.CurrentCamera
    if camera and originalCameraType then
        -- Restore original camera type (usually Follow)
        camera.CameraType = originalCameraType
    end
    
    animationInProgress = false
    originalCameraType = nil
    originalCFrame = nil
end

-- Check if animation is currently running
function WelcomeCameraService:IsAnimationActive()
    return animationInProgress
end

-- Force stop animation (emergency)
function WelcomeCameraService:StopAnimation()
    if animationInProgress then
        self:FinishWelcomeAnimation()
    end
end

return WelcomeCameraService