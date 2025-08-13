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
local START_HEIGHT_OFFSET = 80 -- How high above the map center to start
local END_HEIGHT_OFFSET = 25 -- How high above player area to end
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

-- Get the player's actual position (fallback if no character)
function WelcomeCameraService:GetPlayerPosition()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        -- Fallback to default spawn area - adjust these coordinates for your map
        return Vector3.new(200, -70, 120) -- Typical player area coordinates
    end
    
    return player.Character.HumanoidRootPart.Position
end

-- Get the player area center (where most player plots/areas are)
function WelcomeCameraService:GetPlayerAreaCenter()
    local playerPos = self:GetPlayerPosition()
    -- Return a general area around where players spawn/play
    return Vector3.new(playerPos.X, playerPos.Y, playerPos.Z)
end

-- Find the player's Level1 part
function WelcomeCameraService:GetPlayerLevel1Part()
    -- Try to find the player's area and Level1 part
    local playerAreas = Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then 
        print("WelcomeCameraService: PlayerAreas folder not found")
        return nil 
    end
    
    local playerPos = self:GetPlayerPosition()
    local closestLevel1 = nil
    local closestDistance = math.huge
    
    print("WelcomeCameraService: Searching for Level1 parts near player at", playerPos)
    
    -- Look for the player's specific area (areas are typically numbered)
    for _, area in pairs(playerAreas:GetChildren()) do
        if area:IsA("Model") then
            print("WelcomeCameraService: Checking area", area.Name)
            local level1Part = area:FindFirstChild("Level1", true)
            if level1Part and level1Part:IsA("BasePart") then
                local distance = (level1Part.Position - playerPos).Magnitude
                print("WelcomeCameraService: Found Level1 at", level1Part.Position, "distance:", distance)
                
                if distance < closestDistance and distance < 150 then -- Within reasonable distance
                    closestLevel1 = level1Part
                    closestDistance = distance
                end
            end
        end
    end
    
    if closestLevel1 then
        print("WelcomeCameraService: Using closest Level1 at distance", closestDistance)
    else
        print("WelcomeCameraService: No suitable Level1 part found")
    end
    
    return closestLevel1
end

-- Get final camera position (positioned to show player with Level1 in background)
function WelcomeCameraService:GetFinalCameraPosition()
    local playerPos = self:GetPlayerPosition()
    local level1Part = self:GetPlayerLevel1Part()
    
    if level1Part then
        -- Position camera so Level1 is behind the player in the shot
        local level1Pos = level1Part.Position
        
        -- Calculate horizontal direction from Level1 to player (ignore Y differences)
        local level1ToPlayer = Vector3.new(playerPos.X - level1Pos.X, 0, playerPos.Z - level1Pos.Z).Unit
        
        -- Position camera further in that direction, elevated, and slightly to the side
        local distanceBehindPlayer = 25
        local cameraPosition = playerPos + (level1ToPlayer * distanceBehindPlayer) + Vector3.new(3, END_HEIGHT_OFFSET, 0)
        
        print("WelcomeCameraService: Level1 to Player direction:", level1ToPlayer)
        print("WelcomeCameraService: Camera positioned at:", cameraPosition)
        
        return cameraPosition
    else
        -- Fallback to default positioning if Level1 not found
        print("WelcomeCameraService: Using fallback camera position")
        local cameraOffset = Vector3.new(-15, END_HEIGHT_OFFSET, 15)
        return playerPos + cameraOffset
    end
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
    local playerAreaCenter = self:GetPlayerAreaCenter()
    local playerPosition = self:GetPlayerPosition()
    local level1Part = self:GetPlayerLevel1Part()
    local finalCameraPosition = self:GetFinalCameraPosition()
    
    print("WelcomeCameraService: Map center:", mapCenter)
    print("WelcomeCameraService: Player area center:", playerAreaCenter)
    print("WelcomeCameraService: Player position:", playerPosition)
    if level1Part then
        print("WelcomeCameraService: Level1 part found at:", level1Part.Position)
    else
        print("WelcomeCameraService: Level1 part not found, using fallback")
    end
    print("WelcomeCameraService: Final camera position:", finalCameraPosition)
    
    -- Start from high above map center, looking towards the player area
    local startPosition = mapCenter + Vector3.new(0, START_HEIGHT_OFFSET, 0)
    local endPosition = finalCameraPosition
    
    print("WelcomeCameraService: Start position:", startPosition)
    print("WelcomeCameraService: End position:", endPosition)
    
    -- Calculate start and end CFrames (looking at targets)
    local startCFrame = self:CalculateCameraLookAt(startPosition, playerAreaCenter) -- Look towards player area from center
    local endCFrame = self:CalculateCameraLookAt(endPosition, playerPosition) -- Look at player from final position
    
    -- Set initial camera position
    camera.CFrame = startCFrame
    
    print("WelcomeCameraService: Starting animation from", startPosition, "to", endPosition)
    
    -- Create the tween animation using a NumberValue for progress
    local tweenInfo = TweenInfo.new(
        ANIMATION_DURATION,
        EASE_STYLE,
        EASE_DIRECTION,
        0, -- Repeat count
        false, -- Reverse
        0 -- Delay
    )
    
    -- Create a NumberValue to tween from 0 to 1
    local progressValue = Instance.new("NumberValue")
    progressValue.Value = 0
    
    local tween = TweenService:Create(
        progressValue,
        tweenInfo,
        {
            Value = 1
        }
    )
    
    -- Update camera position during tween
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not animationInProgress then
            connection:Disconnect()
            return
        end
        
        -- Get current progress (0 to 1)
        local progress = progressValue.Value
        
        -- Interpolate position and look target
        local currentPosition = startPosition:lerp(endPosition, progress)
        local currentLookTarget = playerAreaCenter:lerp(playerPosition, progress)
        
        -- Update camera CFrame based on interpolated values
        local currentCFrame = self:CalculateCameraLookAt(currentPosition, currentLookTarget)
        camera.CFrame = currentCFrame
    end)
    
    -- Start the tween
    tween:Play()
    
    -- When animation completes
    tween.Completed:Connect(function()
        connection:Disconnect()
        progressValue:Destroy()
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