-- ComingSoonGUIService - Displays "Coming Soon" GUIs on specific game objects
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local ComingSoonGUIService = {}
ComingSoonGUIService.__index = ComingSoonGUIService

local player = Players.LocalPlayer

-- Rainbow color sequence for animated gradient
local RAINBOW_COLORS = {
    Color3.fromRGB(255, 0, 0),    -- Red
    Color3.fromRGB(255, 127, 0),  -- Orange
    Color3.fromRGB(255, 255, 0),  -- Yellow
    Color3.fromRGB(0, 255, 0),    -- Green
    Color3.fromRGB(0, 0, 255),    -- Blue
    Color3.fromRGB(75, 0, 130),   -- Indigo
    Color3.fromRGB(148, 0, 211),  -- Violet
    Color3.fromRGB(255, 0, 0)     -- Back to Red
}

-- Create color sequence from colors
local function createRainbowSequence()
    local keypoints = {}
    for i, color in ipairs(RAINBOW_COLORS) do
        local time = (i - 1) / (#RAINBOW_COLORS - 1)
        table.insert(keypoints, ColorSequenceKeypoint.new(time, color))
    end
    return ColorSequence.new(keypoints)
end

-- Create a coming soon GUI with distance-based visibility
local function createComingSoonGUI(part, text, offset, customDistances)
    local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
    
    -- Create BillboardGui
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "ComingSoonGUI"
    billboardGui.Size = ScreenUtils.udim2(0, 180, 0, 70) -- Smaller size
    billboardGui.StudsOffset = offset or Vector3.new(0, 5, 0)
    billboardGui.AlwaysOnTop = true
    billboardGui.LightInfluence = 0
    billboardGui.Enabled = false -- Start hidden
    billboardGui.Parent = part
    
    -- Create text label (no background)
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "ComingSoonText"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0) -- Black outline for better contrast
    textLabel.Parent = billboardGui
    
    -- Add text gradient for rainbow effect
    local textGradient = Instance.new("UIGradient")
    textGradient.Color = createRainbowSequence()
    textGradient.Rotation = 0
    textGradient.Parent = textLabel
    
    -- Distance-based visibility and animation
    local SHOW_DISTANCE = customDistances and customDistances.show or 40 -- Show when within 40 studs
    local HIDE_DISTANCE = customDistances and customDistances.hide or 50 -- Hide when beyond 50 studs
    local rotationSpeed = 60 -- degrees per second
    
    local connection
    connection = RunService.Heartbeat:Connect(function(deltaTime)
        if not billboardGui.Parent then
            connection:Disconnect()
            return
        end
        
        -- Check distance to player
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local playerPosition = player.Character.HumanoidRootPart.Position
            local partPosition = part.Position
            local distance = (playerPosition - partPosition).Magnitude
            
            -- Use hysteresis to prevent flickering
            if not billboardGui.Enabled and distance <= SHOW_DISTANCE then
                billboardGui.Enabled = true
            elseif billboardGui.Enabled and distance > HIDE_DISTANCE then
                billboardGui.Enabled = false
            end
        end
        
        -- Animate rainbow gradient when visible
        if billboardGui.Enabled then
            textGradient.Rotation = (textGradient.Rotation + rotationSpeed * deltaTime) % 360
        end
    end)
    
    -- Add floating animation when visible
    local originalOffset = offset
    local floatConnection
    floatConnection = RunService.Heartbeat:Connect(function()
        if not billboardGui.Parent then
            floatConnection:Disconnect()
            return
        end
        
        if billboardGui.Enabled then
            local time = tick()
            local floatY = math.sin(time * 2) * 0.5 -- Gentle floating
            billboardGui.StudsOffset = originalOffset + Vector3.new(0, floatY, 0)
        end
    end)
    
    return billboardGui
end

function ComingSoonGUIService:Initialize()
    -- Wait for PlayerAreas to be created and process each one
    task.spawn(function()
        local playerAreas = Workspace:WaitForChild("PlayerAreas", 30)
        if not playerAreas then
            warn("ComingSoonGUIService: PlayerAreas not found in Workspace after 30 seconds")
            return
        end
        
        -- Process all existing player areas
        for _, area in pairs(playerAreas:GetChildren()) do
            if area:IsA("Model") and area.Name:find("PlayerArea") then
                self:ProcessPlayerArea(area)
            end
        end
        
        -- Listen for new player areas being added
        playerAreas.ChildAdded:Connect(function(child)
            if child:IsA("Model") and child.Name:find("PlayerArea") then
                self:ProcessPlayerArea(child)
            end
        end)
        
        -- Process leaderboard in center map
        self:ProcessLeaderboard()
    end)
end

function ComingSoonGUIService:ProcessPlayerArea(playerArea)
    -- Find and process Chest in player area
    local environmentals = playerArea:FindFirstChild("Environmentals")
    if environmentals then
        -- Process Chest
        local chest = environmentals:FindFirstChild("Chest")
        if chest then
            local container = chest:FindFirstChild("Container")
            if container then
                -- Check if GUI already exists
                if not container:FindFirstChild("ComingSoonGUI") then
                    createComingSoonGUI(container, "Crazy Pet Chest!\nComing Soon...", Vector3.new(0, 8, 0))
                end
            end
        end
        
        -- Process EggPodium2
        local eggPodium = environmentals:FindFirstChild("EggPodium2")
        if eggPodium then
            local egg = eggPodium:FindFirstChild("Egg")
            if egg then
                -- Check if GUI already exists
                if not egg:FindFirstChild("ComingSoonGUI") then
                    createComingSoonGUI(egg, "[OP] Eggs!\nComing Soon...", Vector3.new(0, 6, 0))
                end
            end
        end
    end
end

function ComingSoonGUIService:ProcessLeaderboard()
    -- Find leaderboard in center map
    local center = Workspace:WaitForChild("Center", 10)
    if not center then
        return
    end
    
    local tycoonMap = center:WaitForChild("TycoonMap", 10)
    if not tycoonMap then
        return
    end
    
    local leaderboards = tycoonMap:WaitForChild("Leaderboards", 10)
    if not leaderboards then
        return
    end
    
    local middleLeaderboard = leaderboards:WaitForChild("MiddleLeaderboard", 10)
    if not middleLeaderboard then
        return
    end
    
    local cube = middleLeaderboard:WaitForChild("Cube.048", 10)
    if not cube then
        return
    end
    
    -- Check if GUI already exists
    if not cube:FindFirstChild("ComingSoonGUI") then
        -- Create with custom distance for leaderboard (4x normal distance)
        createComingSoonGUI(cube, "Leaderboards\nComing Soon!", Vector3.new(0, 8, 0), {
            show = 160, -- Show when within 160 studs (4x40)
            hide = 200  -- Hide when beyond 200 studs (4x50)
        })
    end
end

function ComingSoonGUIService:Cleanup()
    -- Cleanup is handled by individual GUI connections
end

return ComingSoonGUIService