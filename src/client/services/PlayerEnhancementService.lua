-- PlayerEnhancementService - Adds speed boost and movement trail effects (client-side only)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local PlayerEnhancementService = {}
PlayerEnhancementService.__index = PlayerEnhancementService

local player = Players.LocalPlayer
local character = nil
local humanoid = nil
local rootPart = nil

-- Trail settings
local TRAIL_ENABLED = true
local TRAIL_LIFETIME = 0.8
local TRAIL_FADE_TIME = 0.6
local TRAIL_SPAWN_RATE = 0.05 -- Every 0.05 seconds
local TRAIL_SIZE = Vector3.new(3, 0.15, 3) -- 25% smaller (4 -> 3, 0.2 -> 0.15)
local TRAIL_TRANSPARENCY = 0.5 -- More transparent (0.3 -> 0.5)

-- Rainbow colors for trail (doubled amount)
local RAINBOW_COLORS = {
    Color3.fromRGB(255, 0, 0),      -- Red
    Color3.fromRGB(255, 64, 0),     -- Red-Orange
    Color3.fromRGB(255, 127, 0),    -- Orange
    Color3.fromRGB(255, 191, 0),    -- Yellow-Orange
    Color3.fromRGB(255, 255, 0),    -- Yellow
    Color3.fromRGB(127, 255, 0),    -- Yellow-Green
    Color3.fromRGB(0, 255, 0),      -- Green
    Color3.fromRGB(0, 255, 127),    -- Mint Green
    Color3.fromRGB(0, 255, 255),    -- Cyan
    Color3.fromRGB(0, 127, 255),    -- Sky Blue
    Color3.fromRGB(0, 0, 255),      -- Blue
    Color3.fromRGB(127, 0, 255),    -- Purple
    Color3.fromRGB(255, 0, 255),    -- Magenta
    Color3.fromRGB(255, 0, 127),    -- Pink
}

-- Speed settings
local SPEED_MULTIPLIER = 2.0
local DEFAULT_WALKSPEED = 16

-- Trail system variables
local lastTrailTime = 0
local lastPosition = nil
local connections = {}
local colorIndex = 1

-- Create a trail part
local function createTrailPart(position)
    -- Get the current color from rainbow
    local currentColor = RAINBOW_COLORS[colorIndex]
    
    -- Increment color index for next trail part
    colorIndex = colorIndex + 1
    if colorIndex > #RAINBOW_COLORS then
        colorIndex = 1
    end
    
    local trailPart = Instance.new("Part")
    trailPart.Name = "PlayerTrail"
    trailPart.Size = TRAIL_SIZE
    trailPart.CFrame = CFrame.new(position + Vector3.new(0, -2.5, 0)) -- Slightly below player
    trailPart.Anchored = true
    trailPart.CanCollide = false
    trailPart.CanQuery = false
    trailPart.CanTouch = false
    trailPart.Material = Enum.Material.Neon
    trailPart.Color = currentColor
    trailPart.Transparency = TRAIL_TRANSPARENCY
    trailPart.TopSurface = Enum.SurfaceType.Smooth
    trailPart.BottomSurface = Enum.SurfaceType.Smooth
    trailPart.Parent = workspace
    
    -- Add a subtle glow effect matching the color
    local pointLight = Instance.new("PointLight")
    pointLight.Color = currentColor
    pointLight.Brightness = 0.5
    pointLight.Range = 8
    pointLight.Parent = trailPart
    
    -- Fade out animation
    local fadeInfo = TweenInfo.new(
        TRAIL_FADE_TIME,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out,
        0,
        false,
        0
    )
    
    local fadeTween = TweenService:Create(trailPart, fadeInfo, {
        Transparency = 1,
        Size = TRAIL_SIZE * 0.1
    })
    
    local lightFadeTween = TweenService:Create(pointLight, fadeInfo, {
        Brightness = 0
    })
    
    -- Start fade animation immediately
    fadeTween:Play()
    lightFadeTween:Play()
    
    -- Clean up after lifetime
    Debris:AddItem(trailPart, TRAIL_LIFETIME)
end

-- Update trail system
local function updateTrail()
    if not TRAIL_ENABLED or not rootPart or not humanoid then
        return
    end
    
    local currentTime = tick()
    local currentPosition = rootPart.Position
    
    -- Check if enough time has passed
    if currentTime - lastTrailTime >= TRAIL_SPAWN_RATE then
        -- Only create trail if moving horizontally AND not jumping/in air
        if lastPosition then
            -- Check horizontal movement only
            local horizontalDelta = Vector2.new(
                currentPosition.X - lastPosition.X,
                currentPosition.Z - lastPosition.Z
            ).Magnitude
            
            -- Check if Y position changed at all (even slightly means jumping/falling)
            local verticalChange = math.abs(currentPosition.Y - lastPosition.Y)
            
            -- Check humanoid state - must be on ground
            local humanoidState = humanoid:GetState()
            local isOnGround = (
                humanoidState ~= Enum.HumanoidStateType.Freefall and
                humanoidState ~= Enum.HumanoidStateType.Jumping and
                humanoidState ~= Enum.HumanoidStateType.Flying
            )
            
            -- Only create trail if:
            -- 1. Moving horizontally
            -- 2. No vertical movement (Y axis unchanged)
            -- 3. Humanoid is on ground
            if horizontalDelta > 0.1 and verticalChange < 0.01 and isOnGround then
                -- Player is walking on flat ground, create trail
                createTrailPart(currentPosition)
                lastTrailTime = currentTime
            end
        end
        
        lastPosition = currentPosition
    end
end

-- Setup speed boost
local function setupSpeedBoost()
    if not humanoid then
        return
    end
    
    -- Apply speed multiplier
    local originalWalkSpeed = humanoid.WalkSpeed
    if originalWalkSpeed <= DEFAULT_WALKSPEED then
        originalWalkSpeed = DEFAULT_WALKSPEED
    end
    
    humanoid.WalkSpeed = originalWalkSpeed * SPEED_MULTIPLIER
end

-- Setup character references
local function setupCharacter(newCharacter)
    -- Clean up old connections
    for _, connection in pairs(connections) do
        connection:Disconnect()
    end
    connections = {}
    
    character = newCharacter
    if not character then
        return
    end
    
    -- Wait for required parts
    humanoid = character:WaitForChild("Humanoid", 5)
    rootPart = character:WaitForChild("HumanoidRootPart", 5)
    
    if not humanoid or not rootPart then
        warn("PlayerEnhancementService: Failed to find Humanoid or HumanoidRootPart")
        return
    end
    
    -- Setup speed boost
    setupSpeedBoost()
    
    -- Reset trail system
    lastPosition = rootPart.Position
    lastTrailTime = tick()
end

function PlayerEnhancementService:Initialize()
    -- Setup for current character
    if player.Character then
        setupCharacter(player.Character)
    end
    
    -- Listen for character respawns
    player.CharacterAdded:Connect(setupCharacter)
    
    -- Start trail update loop
    connections.trailUpdate = RunService.Heartbeat:Connect(updateTrail)
end

function PlayerEnhancementService:SetSpeedMultiplier(multiplier)
    SPEED_MULTIPLIER = multiplier
    if humanoid then
        setupSpeedBoost()
    end
end

function PlayerEnhancementService:SetTrailEnabled(enabled)
    TRAIL_ENABLED = enabled
end

function PlayerEnhancementService:Cleanup()
    -- Clean up connections
    for _, connection in pairs(connections) do
        connection:Disconnect()
    end
    connections = {}
    
    -- Reset speed to normal
    if humanoid then
        humanoid.WalkSpeed = DEFAULT_WALKSPEED
    end
    
    print("PlayerEnhancementService: Cleaned up")
end

return PlayerEnhancementService