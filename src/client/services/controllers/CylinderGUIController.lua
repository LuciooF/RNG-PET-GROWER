-- Cylinder GUI Controller
-- Handles all billboard GUI creation and management for cylinders
-- Centralizes GUI creation patterns for reusability

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlotConfig = require(ReplicatedStorage.Shared.config.PlotConfig)

local CylinderGUIController = {}

-- Extended cylinder colors configuration for higher rarities
local CYLINDER_COLORS = {
    [1] = Color3.fromRGB(139, 69, 19), -- Brown (Basic)
    [2] = Color3.fromRGB(169, 169, 169), -- Silver (Common)
    [3] = Color3.fromRGB(255, 215, 0), -- Gold (Rare)
    [4] = Color3.fromRGB(138, 43, 226), -- Purple (Epic)
    [5] = Color3.fromRGB(255, 20, 147), -- Pink (Legendary)
    [6] = Color3.fromRGB(0, 255, 255), -- Cyan (Mythic)
    [7] = Color3.fromRGB(255, 215, 255), -- Light Pink (Divine)
    [8] = Color3.fromRGB(135, 206, 250), -- Sky Blue (Celestial)
    [9] = Color3.fromRGB(75, 0, 130), -- Indigo (Cosmic)
    [10] = Color3.fromRGB(25, 25, 25), -- Dark Gray (Void)
}

-- Create cylinder rarity GUI above cylinder
function CylinderGUIController.createCylinderGUI(cylinder, plotData, playerRebirths)
    if not cylinder or not plotData then
        warn("CylinderGUIController: Invalid cylinder or plot data")
        return nil
    end
    
    playerRebirths = playerRebirths or 0
    
    -- Create GUI anchor above cylinder
    local guiAnchor = Instance.new("Part")
    guiAnchor.Name = "CylinderGUIAnchor"
    guiAnchor.Size = Vector3.new(1, 1, 1)
    guiAnchor.Transparency = 1
    guiAnchor.CanCollide = false
    guiAnchor.Anchored = true
    guiAnchor.Position = cylinder.Position + Vector3.new(0, 8, 0) -- Above cylinder
    guiAnchor.Parent = cylinder.Parent
    
    -- Create BillboardGui
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "CylinderRarityGUI"
    billboardGui.Size = UDim2.new(0, 120, 0, 30)
    billboardGui.StudsOffset = Vector3.new(0, 0, 0)
    billboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    billboardGui.Parent = guiAnchor
    
    -- Calculate dynamic rarity based on player rebirths
    local dynamicRarity = PlotConfig:GetDynamicRarity(plotData.id or 1, playerRebirths)
    local rarityName = PlotConfig:GetRarityName(dynamicRarity)
    
    -- Get color for display (use modulo for colors beyond our defined range)
    local colorIndex = ((dynamicRarity - 1) % #CYLINDER_COLORS) + 1
    local rarityColor = CYLINDER_COLORS[colorIndex] or Color3.fromRGB(255, 255, 255)
    
    -- Create text label
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "RarityText"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Position = UDim2.new(0, 0, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = rarityName
    textLabel.TextColor3 = rarityColor
    textLabel.TextSize = 16
    textLabel.TextWrapped = false
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.Font = Enum.Font.GothamBold
    textLabel.ZIndex = 2
    textLabel.Parent = billboardGui
    
    -- Add black text stroke for visibility
    local textStroke = Instance.new("UIStroke")
    textStroke.Color = Color3.fromRGB(0, 0, 0)
    textStroke.Thickness = 2
    textStroke.Transparency = 0
    textStroke.Parent = textLabel
    
    -- Return GUI reference structure
    return {
        anchor = guiAnchor,
        gui = billboardGui,
        textLabel = textLabel,
        dynamicRarity = dynamicRarity
    }
end

-- Create spawn counter GUI above farm
function CylinderGUIController.createSpawnCounterGUI(farmBase, currentCount, maxCount)
    if not farmBase then
        warn("CylinderGUIController: Invalid farmBase for spawn counter")
        return nil
    end
    
    -- Create GUI anchor above farm
    local guiAnchor = Instance.new("Part")
    guiAnchor.Name = "SpawnCounterAnchor"
    guiAnchor.Size = Vector3.new(1, 1, 1)
    guiAnchor.Transparency = 1
    guiAnchor.CanCollide = false
    guiAnchor.Anchored = true
    guiAnchor.Position = farmBase.Position + Vector3.new(0, 30, 0) -- High above farm
    guiAnchor.Parent = farmBase.Parent
    
    -- Create BillboardGui
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "SpawnCounterGUI"
    billboardGui.Size = UDim2.new(0, 120, 0, 40)
    billboardGui.StudsOffset = Vector3.new(0, 0, 0)
    billboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    billboardGui.Parent = guiAnchor
    
    -- Create background frame
    local backgroundFrame = Instance.new("Frame")
    backgroundFrame.Name = "Background"
    backgroundFrame.Size = UDim2.new(1, 0, 1, 0)
    backgroundFrame.Position = UDim2.new(0, 0, 0, 0)
    backgroundFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backgroundFrame.BackgroundTransparency = 0.3
    backgroundFrame.BorderSizePixel = 0
    backgroundFrame.Parent = billboardGui
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = backgroundFrame
    
    -- Create text label
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "CounterText"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Position = UDim2.new(0, 0, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = (currentCount or 0) .. "/" .. (maxCount or 100)
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextSize = 18
    textLabel.TextWrapped = false
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.Font = Enum.Font.GothamBold
    textLabel.ZIndex = 2
    textLabel.Parent = backgroundFrame
    
    -- Add text stroke for visibility
    local textStroke = Instance.new("UIStroke")
    textStroke.Color = Color3.fromRGB(0, 0, 0)
    textStroke.Thickness = 2
    textStroke.Transparency = 0
    textStroke.Parent = textLabel
    
    -- Return GUI reference structure
    return {
        anchor = guiAnchor,
        gui = billboardGui,
        textLabel = textLabel,
        backgroundFrame = backgroundFrame
    }
end

-- Update spawn counter display
function CylinderGUIController.updateSpawnCounter(spawnCounterGUI, currentCount, maxCount)
    if not spawnCounterGUI or not spawnCounterGUI.textLabel then
        return false
    end
    
    spawnCounterGUI.textLabel.Text = currentCount .. "/" .. maxCount
    
    -- Change color based on how close to cap we are
    local percentage = currentCount / maxCount
    if percentage >= 0.9 then
        spawnCounterGUI.textLabel.TextColor3 = Color3.fromRGB(255, 100, 100) -- Red when close to cap
    elseif percentage >= 0.7 then
        spawnCounterGUI.textLabel.TextColor3 = Color3.fromRGB(255, 255, 100) -- Yellow when getting full
    else
        spawnCounterGUI.textLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White when plenty of space
    end
    
    return true
end

-- Clean up GUI
function CylinderGUIController.destroyGUI(guiReference)
    if guiReference and guiReference.anchor and guiReference.anchor.Parent then
        guiReference.anchor:Destroy()
    end
end

return CylinderGUIController