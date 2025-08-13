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
local END_HEIGHT_OFFSET = 5 -- How high above player (torso level)
local EASE_STYLE = Enum.EasingStyle.Quart
local EASE_DIRECTION = Enum.EasingDirection.Out

-- State
local animationInProgress = false
local originalCameraType = nil
local originalCFrame = nil

function WelcomeCameraService:Initialize()
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
        return nil 
    end
    
    local playerPos = self:GetPlayerPosition()
    
    -- First try: Find area that contains the player (by checking if player is inside area bounds)
    for _, area in pairs(playerAreas:GetChildren()) do
        if area:IsA("Model") then
            -- Check if player is within this area's bounds
            local areaCFrame, areaSize = area:GetBoundingBox()
            local areaPosition = areaCFrame.Position
            local distanceToAreaCenter = (areaPosition - playerPos).Magnitude
            
            if distanceToAreaCenter < 100 then -- Player is within this area
                local level1Part = area:FindFirstChild("Level1", true)
                if level1Part then
                    return level1Part
                end
            end
        end
    end
    
    -- Fallback: Find closest Level1 if we couldn't determine player's area
    local closestLevel1 = nil
    local closestDistance = math.huge
    
    -- Look for the player's specific area (areas are named PlayerArea1, PlayerArea2, etc.)
    for _, area in pairs(playerAreas:GetChildren()) do
        if area:IsA("Model") then
            local level1Part = area:FindFirstChild("Level1", true)
            if level1Part then
                -- Level1 is a Model, so we need to get its position from a part inside it
                local level1Position = nil
                if level1Part:IsA("Model") then
                    -- Get the primary part or any part from the model
                    if level1Part.PrimaryPart then
                        level1Position = level1Part.PrimaryPart.Position
                    else
                        -- Find any part in the model to get position
                        for _, child in pairs(level1Part:GetChildren()) do
                            if child:IsA("BasePart") then
                                level1Position = child.Position
                                break
                            end
                        end
                    end
                elseif level1Part:IsA("BasePart") then
                    level1Position = level1Part.Position
                end
                
                if level1Position then
                    local distance = (level1Position - playerPos).Magnitude
                    
                    if distance < closestDistance and distance < 500 then -- Increased distance threshold
                        closestLevel1 = level1Part
                        closestDistance = distance
                    end
                end
            end
        end
    end
    
    return closestLevel1
end

-- Get final camera position (behind player at torso level, looking towards Level1)
function WelcomeCameraService:GetFinalCameraPosition()
    local playerPos = self:GetPlayerPosition()
    local level1Part = self:GetPlayerLevel1Part()
    
    if level1Part then
        -- Position camera behind the player, at torso level, so we see player's back facing Level1
        local level1Pos = nil
        if level1Part:IsA("Model") then
            -- Get position from the model
            if level1Part.PrimaryPart then
                level1Pos = level1Part.PrimaryPart.Position
            else
                -- Find any part in the model to get position
                for _, child in pairs(level1Part:GetChildren()) do
                    if child:IsA("BasePart") then
                        level1Pos = child.Position
                        break
                    end
                end
            end
        elseif level1Part:IsA("BasePart") then
            level1Pos = level1Part.Position
        end
        
        if level1Pos then
            -- Calculate horizontal direction from player to Level1 (where player faces)
            local playerToLevel1 = Vector3.new(level1Pos.X - playerPos.X, 0, level1Pos.Z - playerPos.Z).Unit
            
            -- Position camera directly behind player (opposite to where they're facing), at torso level
            local distanceBehindPlayer = 12
            local cameraPosition = playerPos + (-playerToLevel1 * distanceBehindPlayer) + Vector3.new(0, END_HEIGHT_OFFSET, 0)
            
            
            return cameraPosition
        end
    else
        -- Fallback to default positioning if Level1 not found
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
    if animationInProgress then
        return
    end
    
    local camera = Workspace.CurrentCamera
    if not camera then
        warn("WelcomeCameraService: No camera found")
        return
    end
    
    -- Wait for player character to load (with timeout)
    local maxWait = 10 -- Maximum 10 seconds to wait for character
    local startTime = tick()
    
    while (not player.Character or not player.Character:FindFirstChild("HumanoidRootPart")) and (tick() - startTime) < maxWait do
        task.wait(0.1)
    end
    
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        warn("WelcomeCameraService: Character/HumanoidRootPart not ready after 10 seconds, starting animation anyway")
    end
    
    animationInProgress = true
    
    -- Store original camera settings
    originalCameraType = camera.CameraType
    originalCFrame = camera.CFrame
    
    -- Set camera to scriptable mode
    camera.CameraType = Enum.CameraType.Scriptable
    
    -- Calculate start and end positions
    local mapCenter = self:GetMapCenter()
    local playerAreaCenter = self:GetPlayerAreaCenter()
    local playerPosition = self:GetPlayerPosition()
    local level1Part = self:GetPlayerLevel1Part()
    local finalCameraPosition = self:GetFinalCameraPosition()
    
    -- Start from high above map center, looking towards the player area
    local startPosition = mapCenter + Vector3.new(0, START_HEIGHT_OFFSET, 0)
    local endPosition = finalCameraPosition
    
    -- Calculate start and end CFrames (looking at targets)
    local startCFrame = self:CalculateCameraLookAt(startPosition, playerAreaCenter) -- Look towards player area from center
    
    -- For end frame, look towards Level1 (same direction as player) not at player
    local endTarget = playerPosition -- Default fallback
    if level1Part then
        -- Get Level1 position from Model
        if level1Part:IsA("Model") then
            if level1Part.PrimaryPart then
                endTarget = level1Part.PrimaryPart.Position
            else
                for _, child in pairs(level1Part:GetChildren()) do
                    if child:IsA("BasePart") then
                        endTarget = child.Position
                        break
                    end
                end
            end
        elseif level1Part:IsA("BasePart") then
            endTarget = level1Part.Position
        end
    end
    local endCFrame = self:CalculateCameraLookAt(endPosition, endTarget)
    
    -- Set initial camera position
    camera.CFrame = startCFrame
    
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
        local currentLookTarget = playerAreaCenter:lerp(endTarget, progress)
        
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