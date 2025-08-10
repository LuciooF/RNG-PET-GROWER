-- ChestLevelGUIService - Displays chest level and luck level on the crazy chest
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local DataSyncService = require(script.Parent.DataSyncService)

local ChestLevelGUIService = {}
ChestLevelGUIService.__index = ChestLevelGUIService

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

-- Create a chest level GUI with distance-based visibility
local function createChestLevelGUI(part, offset)
    local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
    
    -- Create BillboardGui
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "ChestLevelGUI"
    billboardGui.Size = ScreenUtils.udim2(0, 200, 0, 90) -- Larger for 3 lines
    billboardGui.StudsOffset = offset or Vector3.new(0, 8, 0)
    billboardGui.AlwaysOnTop = true
    billboardGui.LightInfluence = 0
    billboardGui.Enabled = false -- Start hidden
    billboardGui.Parent = part
    
    -- Create main frame to hold all text elements
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.Parent = billboardGui
    
    -- Create "Crazy Chest!" title with rainbow gradient
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0.33, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Crazy Chest!"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.FredokaOne
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.TextYAlignment = Enum.TextYAlignment.Center
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    titleLabel.Parent = mainFrame
    
    -- Add rainbow gradient to title
    local titleGradient = Instance.new("UIGradient")
    titleGradient.Color = createRainbowSequence()
    titleGradient.Rotation = 0
    titleGradient.Parent = titleLabel
    
    -- Create chest level line
    local chestLevelFrame = Instance.new("Frame")
    chestLevelFrame.Name = "ChestLevelFrame"
    chestLevelFrame.Size = UDim2.new(1, 0, 0.33, 0)
    chestLevelFrame.Position = UDim2.new(0, 0, 0.33, 0)
    chestLevelFrame.BackgroundTransparency = 1
    chestLevelFrame.Parent = mainFrame
    
    -- "Level:" text in white
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Name = "LevelLabel"
    levelLabel.Size = UDim2.new(0.6, 0, 1, 0)
    levelLabel.Position = UDim2.new(0, 0, 0, 0)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Text = "Level:"
    levelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    levelLabel.TextScaled = true
    levelLabel.Font = Enum.Font.FredokaOne
    levelLabel.TextXAlignment = Enum.TextXAlignment.Right
    levelLabel.TextYAlignment = Enum.TextYAlignment.Center
    levelLabel.TextStrokeTransparency = 0
    levelLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    levelLabel.Parent = chestLevelFrame
    
    -- Chest level number in cyan
    local levelNumberLabel = Instance.new("TextLabel")
    levelNumberLabel.Name = "LevelNumberLabel"
    levelNumberLabel.Size = UDim2.new(0.4, 0, 1, 0)
    levelNumberLabel.Position = UDim2.new(0.6, 0, 0, 0)
    levelNumberLabel.BackgroundTransparency = 1
    levelNumberLabel.Text = " 1"
    levelNumberLabel.TextColor3 = Color3.fromRGB(0, 255, 255) -- Cyan
    levelNumberLabel.TextScaled = true
    levelNumberLabel.Font = Enum.Font.FredokaOne
    levelNumberLabel.TextXAlignment = Enum.TextXAlignment.Left
    levelNumberLabel.TextYAlignment = Enum.TextYAlignment.Center
    levelNumberLabel.TextStrokeTransparency = 0
    levelNumberLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    levelNumberLabel.Parent = chestLevelFrame
    
    -- Create luck level line
    local luckLevelFrame = Instance.new("Frame")
    luckLevelFrame.Name = "LuckLevelFrame"
    luckLevelFrame.Size = UDim2.new(1, 0, 0.34, 0)
    luckLevelFrame.Position = UDim2.new(0, 0, 0.66, 0)
    luckLevelFrame.BackgroundTransparency = 1
    luckLevelFrame.Parent = mainFrame
    
    -- "Luck Level:" text in white
    local luckLabel = Instance.new("TextLabel")
    luckLabel.Name = "LuckLabel"
    luckLabel.Size = UDim2.new(0.7, 0, 1, 0)
    luckLabel.Position = UDim2.new(0, 0, 0, 0)
    luckLabel.BackgroundTransparency = 1
    luckLabel.Text = "Luck Level:"
    luckLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    luckLabel.TextScaled = true
    luckLabel.Font = Enum.Font.FredokaOne
    luckLabel.TextXAlignment = Enum.TextXAlignment.Right
    luckLabel.TextYAlignment = Enum.TextYAlignment.Center
    luckLabel.TextStrokeTransparency = 0
    luckLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    luckLabel.Parent = luckLevelFrame
    
    -- Luck level number in green
    local luckNumberLabel = Instance.new("TextLabel")
    luckNumberLabel.Name = "LuckNumberLabel"
    luckNumberLabel.Size = UDim2.new(0.3, 0, 1, 0)
    luckNumberLabel.Position = UDim2.new(0.7, 0, 0, 0)
    luckNumberLabel.BackgroundTransparency = 1
    luckNumberLabel.Text = " 1"
    luckNumberLabel.TextColor3 = Color3.fromRGB(0, 255, 0) -- Green
    luckNumberLabel.TextScaled = true
    luckNumberLabel.Font = Enum.Font.FredokaOne
    luckNumberLabel.TextXAlignment = Enum.TextXAlignment.Left
    luckNumberLabel.TextYAlignment = Enum.TextYAlignment.Center
    luckNumberLabel.TextStrokeTransparency = 0
    luckNumberLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    luckNumberLabel.Parent = luckLevelFrame
    
    -- Distance-based visibility and animation
    local SHOW_DISTANCE = 40 -- Show when within 40 studs
    local HIDE_DISTANCE = 50 -- Hide when beyond 50 studs
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
        
        -- Animate rainbow gradient on title when visible
        if billboardGui.Enabled then
            titleGradient.Rotation = (titleGradient.Rotation + rotationSpeed * deltaTime) % 360
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
    
    return billboardGui, levelNumberLabel, luckNumberLabel
end

function ChestLevelGUIService:CreateChestGUI(container)
    local gui, levelNumberLabel, luckNumberLabel = createChestLevelGUI(container, Vector3.new(0, 8, 0))
    
    local function updateChestText()
        local playerData = DataSyncService:GetPlayerData()
        if playerData and playerData.CrazyChest then
            local chestLevel = playerData.CrazyChest.Level or 1
            local luckLevel = playerData.CrazyChest.Luck or 1
            levelNumberLabel.Text = " " .. chestLevel
            luckNumberLabel.Text = " " .. luckLevel
        else
            levelNumberLabel.Text = " 1" -- Fallback
            luckNumberLabel.Text = " 1" -- Fallback
        end
    end
    
    -- Update initially
    updateChestText()
    
    -- Subscribe to data changes
    local unsubscribe = DataSyncService:Subscribe(function(newState)
        if gui and gui.Parent and levelNumberLabel and levelNumberLabel.Parent and luckNumberLabel and luckNumberLabel.Parent then
            updateChestText()
        else
            -- GUI was destroyed, unsubscribe
            if unsubscribe and type(unsubscribe) == "function" then
                unsubscribe()
            end
        end
    end)
    
    -- Cleanup subscription when GUI is destroyed
    gui.AncestryChanged:Connect(function()
        if not gui.Parent and unsubscribe and type(unsubscribe) == "function" then
            unsubscribe()
        end
    end)
    
    return gui
end

function ChestLevelGUIService:Initialize()
    -- Wait for PlayerAreas to be created and process each one
    task.spawn(function()
        local playerAreas = Workspace:WaitForChild("PlayerAreas", 30)
        if not playerAreas then
            warn("ChestLevelGUIService: PlayerAreas not found in Workspace after 30 seconds")
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
    end)
end

function ChestLevelGUIService:ProcessPlayerArea(playerArea)
    -- Find and process Chest in player area
    local environmentals = playerArea:FindFirstChild("Environmentals")
    if environmentals then
        local chest = environmentals:FindFirstChild("Chest")
        if chest then
            local container = chest:FindFirstChild("Container")
            if container then
                -- Check if GUI already exists
                if not container:FindFirstChild("ChestLevelGUI") then
                    self:CreateChestGUI(container)
                end
            end
        end
    end
end

function ChestLevelGUIService:Cleanup()
    -- Cleanup is handled by individual GUI connections
end

return ChestLevelGUIService