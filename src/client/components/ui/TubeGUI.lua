-- Tube GUI Component
-- Shows individual processing rate above each tube

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TubeConfig = require(ReplicatedStorage.Shared.config.TubeConfig)

local TubeGUI = {}

-- Configuration (easily adjustable for game balance)
local GUI_CONFIG = {
    size = UDim2.new(0, 100, 0, 40),
    studOffset = Vector3.new(0, 0, 0),
    heightAboveTube = 6,
    
    -- Background styling
    backgroundColor = Color3.fromRGB(50, 50, 50),
    backgroundTransparency = 0.2,
    cornerRadius = 6,
    
    -- Text styling
    textColor = Color3.fromRGB(255, 255, 255),
    textSize = 14,
    font = Enum.Font.GothamBold,
    
    -- Border styling
    borderColor = Color3.fromRGB(255, 255, 255),
    borderThickness = 2,
    borderTransparency = 0.3
}

-- Create GUI for a specific tube
function TubeGUI.createTubeGUI(tubeModel, plotId)
    if not tubeModel then
        warn("TubeGUI: Invalid tube model")
        return nil
    end
    
    -- Find the tube base part
    local tubeBase = tubeModel:FindFirstChild("Base")
    if not tubeBase then
        warn("TubeGUI: Tube Base part not found")
        return nil
    end
    
    -- Get processing speed for this tube (all tubes are 1.0/s now)
    local processingSpeed = TubeConfig:GetTubeSpeed()
    
    -- Create GUI anchor above tube
    local guiAnchor = Instance.new("Part")
    guiAnchor.Name = "TubeGUIAnchor"
    guiAnchor.Size = Vector3.new(1, 1, 1)
    guiAnchor.Transparency = 1
    guiAnchor.CanCollide = false
    guiAnchor.Anchored = true
    guiAnchor.Position = tubeBase.Position + Vector3.new(0, GUI_CONFIG.heightAboveTube, 0)
    guiAnchor.Parent = tubeModel
    
    -- Create BillboardGui
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "TubeGUI"
    billboardGui.Size = GUI_CONFIG.size
    billboardGui.StudsOffset = GUI_CONFIG.studOffset
    billboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    billboardGui.Parent = guiAnchor
    
    -- Create background frame
    local backgroundFrame = Instance.new("Frame")
    backgroundFrame.Name = "Background"
    backgroundFrame.Size = UDim2.new(1, 0, 1, 0)
    backgroundFrame.Position = UDim2.new(0, 0, 0, 0)
    backgroundFrame.BackgroundColor3 = GUI_CONFIG.backgroundColor
    backgroundFrame.BackgroundTransparency = GUI_CONFIG.backgroundTransparency
    backgroundFrame.BorderSizePixel = 0
    backgroundFrame.Parent = billboardGui
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, GUI_CONFIG.cornerRadius)
    corner.Parent = backgroundFrame
    
    -- Add border stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = GUI_CONFIG.borderColor
    stroke.Thickness = GUI_CONFIG.borderThickness
    stroke.Transparency = GUI_CONFIG.borderTransparency
    stroke.Parent = backgroundFrame
    
    -- Create rate label
    local rateLabel = Instance.new("TextLabel")
    rateLabel.Name = "RateLabel"
    rateLabel.Size = UDim2.new(1, 0, 1, 0)
    rateLabel.Position = UDim2.new(0, 0, 0, 0)
    rateLabel.BackgroundTransparency = 1
    rateLabel.Text = string.format("%.1f/s", processingSpeed)
    rateLabel.TextColor3 = GUI_CONFIG.textColor
    rateLabel.TextSize = GUI_CONFIG.textSize
    rateLabel.TextWrapped = false
    rateLabel.TextXAlignment = Enum.TextXAlignment.Center
    rateLabel.TextYAlignment = Enum.TextYAlignment.Center
    rateLabel.Font = GUI_CONFIG.font
    rateLabel.ZIndex = 2
    rateLabel.Parent = backgroundFrame
    
    -- Add text stroke for better visibility
    local textStroke = Instance.new("UIStroke")
    textStroke.Color = Color3.fromRGB(0, 0, 0)
    textStroke.Thickness = 1
    textStroke.Transparency = 0.5
    textStroke.Parent = rateLabel
    
    -- Return GUI reference structure
    return {
        anchor = guiAnchor,
        gui = billboardGui,
        backgroundFrame = backgroundFrame,
        rateLabel = rateLabel,
        plotId = plotId,
        processingSpeed = processingSpeed
    }
end

-- Update tube GUI with new processing speed (for rebalancing)
function TubeGUI.updateTubeGUI(tubeGUIRef, newProcessingSpeed)
    if not tubeGUIRef or not tubeGUIRef.rateLabel then
        return false
    end
    
    if newProcessingSpeed then
        tubeGUIRef.processingSpeed = newProcessingSpeed
    end
    
    tubeGUIRef.rateLabel.Text = string.format("%.1f/s", tubeGUIRef.processingSpeed)
    return true
end

-- Update GUI configuration (for easy game balancing)
function TubeGUI.updateConfig(newConfig)
    for key, value in pairs(newConfig) do
        if GUI_CONFIG[key] ~= nil then
            GUI_CONFIG[key] = value
        end
    end
end

-- Get current configuration (for debugging/inspection)
function TubeGUI.getConfig()
    return GUI_CONFIG
end

-- Clean up tube GUI
function TubeGUI.destroyTubeGUI(tubeGUIRef)
    if tubeGUIRef and tubeGUIRef.anchor and tubeGUIRef.anchor.Parent then
        tubeGUIRef.anchor:Destroy()
    end
end

-- Add pulse effect to tube GUI
function TubeGUI.addPulseEffect(tubeGUIRef)
    if not tubeGUIRef or not tubeGUIRef.backgroundFrame then
        return false
    end
    
    local TweenService = game:GetService("TweenService")
    local tweenInfo = TweenInfo.new(
        2.0, -- Duration
        Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut,
        -1, -- Repeat infinitely
        true -- Reverse
    )
    
    local pulseTween = TweenService:Create(
        tubeGUIRef.backgroundFrame,
        tweenInfo,
        {BackgroundTransparency = 0.5}
    )
    
    pulseTween:Play()
    return true
end

return TubeGUI