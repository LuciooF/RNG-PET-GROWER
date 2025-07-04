-- Processing Rate GUI Component
-- Shows the heaven processing rate above SendHeaven part with pet inventory counter

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Store = require(ReplicatedStorage.store)
local ProductionPlotConfig = require(ReplicatedStorage.Shared.config.ProductionPlotConfig)

local ProcessingRateGUI = {}

-- Configuration
local BASE_PROCESSING_RATE = 1 -- 1 pet per second base rate from server config
local PET_INVENTORY_CAP = 1000 -- Match server constant

-- Function to calculate current processing rate based on production plot speeds
local function getCurrentProcessingRate()
    local state = Store:getState()
    local playerData = state.player or {}
    local boughtProductionPlots = playerData.boughtProductionPlots or {}
    
    -- Use ProductionPlotConfig to calculate total rate including individual plot speeds
    local totalRate = ProductionPlotConfig:CalculateTotalProcessingRate(boughtProductionPlots)
    return totalRate -- Show actual rate, not floored
end

-- Function to get current tube count from Redux store
local function getCurrentTubeCount()
    local state = Store:getState()
    local playerData = state.player or {}
    local boughtProductionPlots = playerData.boughtProductionPlots or {}
    return 1 + #boughtProductionPlots -- 1 for Tube1 + production tubes
end

-- Create processing rate GUI above SendHeaven part
function ProcessingRateGUI.createProcessingRateGUI(sendHeavenPart)
    if not sendHeavenPart then
        warn("ProcessingRateGUI: Invalid sendHeavenPart")
        return nil
    end
    
    -- Create GUI anchor above SendHeaven part
    local guiAnchor = Instance.new("Part")
    guiAnchor.Name = "ProcessingRateAnchor"
    guiAnchor.Size = Vector3.new(1, 1, 1)
    guiAnchor.Transparency = 1
    guiAnchor.CanCollide = false
    guiAnchor.Anchored = true
    guiAnchor.Position = sendHeavenPart.Position + Vector3.new(0, 8, 0) -- Above SendHeaven part
    guiAnchor.Parent = sendHeavenPart.Parent
    
    -- Create BillboardGui
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "ProcessingRateGUI"
    billboardGui.Size = UDim2.new(0, 140, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 0, 0)
    billboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    billboardGui.Parent = guiAnchor
    
    -- Create background frame
    local backgroundFrame = Instance.new("Frame")
    backgroundFrame.Name = "Background"
    backgroundFrame.Size = UDim2.new(1, 0, 1, 0)
    backgroundFrame.Position = UDim2.new(0, 0, 0, 0)
    backgroundFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Gold color for heaven theme
    backgroundFrame.BackgroundTransparency = 0.1
    backgroundFrame.BorderSizePixel = 0
    backgroundFrame.Parent = billboardGui
    
    -- Add corner radius and styling
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = backgroundFrame
    
    -- Add gradient for visual appeal
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 235, 100)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 50))
    }
    gradient.Rotation = 90
    gradient.Parent = backgroundFrame
    
    -- Add border stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    stroke.Parent = backgroundFrame
    
    -- Create title label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0.4, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "⚡ PROCESSING RATE"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 12
    titleLabel.TextWrapped = false
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.TextYAlignment = Enum.TextYAlignment.Center
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.ZIndex = 2
    titleLabel.Parent = backgroundFrame
    
    -- Add text stroke for title
    local titleStroke = Instance.new("UIStroke")
    titleStroke.Color = Color3.fromRGB(0, 0, 0)
    titleStroke.Thickness = 1
    titleStroke.Transparency = 0.5
    titleStroke.Parent = titleLabel
    
    -- Create rate label
    local rateLabel = Instance.new("TextLabel")
    rateLabel.Name = "RateLabel"
    rateLabel.Size = UDim2.new(1, 0, 0.6, 0)
    rateLabel.Position = UDim2.new(0, 0, 0.4, 0)
    rateLabel.BackgroundTransparency = 1
    -- Set initial rate text (will be updated dynamically)
    local currentRate = getCurrentProcessingRate()
    local tubeCount = getCurrentTubeCount()
    rateLabel.Text = string.format("%.1f/s (%d tubes)", currentRate, tubeCount)
    rateLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    rateLabel.TextSize = 16
    rateLabel.TextWrapped = false
    rateLabel.TextXAlignment = Enum.TextXAlignment.Center
    rateLabel.TextYAlignment = Enum.TextYAlignment.Center
    rateLabel.Font = Enum.Font.GothamBold
    rateLabel.ZIndex = 2
    rateLabel.Parent = backgroundFrame
    
    -- Add text stroke for rate
    local rateStroke = Instance.new("UIStroke")
    rateStroke.Color = Color3.fromRGB(0, 0, 0)
    rateStroke.Thickness = 2
    rateStroke.Transparency = 0
    rateStroke.Parent = rateLabel
    
    -- Create inventory counter badge (bottom right, similar to boost button)
    local currentState = Store:getState()
    local currentPets = currentState.player.ownedPets or {}
    local petCount = #currentPets
    
    local inventoryBadge = Instance.new("Frame")
    inventoryBadge.Name = "InventoryBadge"
    inventoryBadge.Size = UDim2.new(0, 65, 0, 18)
    inventoryBadge.Position = UDim2.new(1, -60, 1, -10)
    inventoryBadge.BackgroundColor3 = Color3.fromRGB(100, 150, 255) -- Blue color (different from boost)
    inventoryBadge.BorderSizePixel = 0
    inventoryBadge.ZIndex = 3
    inventoryBadge.Parent = billboardGui
    
    -- Add corner radius to badge
    local inventoryCorner = Instance.new("UICorner")
    inventoryCorner.CornerRadius = UDim.new(0, 9)
    inventoryCorner.Parent = inventoryBadge
    
    -- Create inventory text
    local inventoryText = Instance.new("TextLabel")
    inventoryText.Name = "InventoryText"
    inventoryText.Size = UDim2.new(1, 0, 1, 0)
    inventoryText.Text = string.format("%d/%d", petCount, PET_INVENTORY_CAP)
    inventoryText.TextColor3 = Color3.fromRGB(255, 255, 255)
    inventoryText.TextSize = 11
    inventoryText.TextWrapped = true
    inventoryText.BackgroundTransparency = 1
    inventoryText.Font = Enum.Font.GothamBold
    inventoryText.ZIndex = 4
    inventoryText.Parent = inventoryBadge
    
    -- Add text stroke for inventory text
    local inventoryStroke = Instance.new("UIStroke")
    inventoryStroke.Color = Color3.fromRGB(0, 0, 0)
    inventoryStroke.Thickness = 2
    inventoryStroke.Transparency = 0.5
    inventoryStroke.Parent = inventoryText
    
    -- Return GUI reference structure
    return {
        anchor = guiAnchor,
        gui = billboardGui,
        titleLabel = titleLabel,
        rateLabel = rateLabel,
        backgroundFrame = backgroundFrame,
        inventoryBadge = inventoryBadge,
        inventoryText = inventoryText
    }
end

-- Update processing rate display (for future dynamic rates)
function ProcessingRateGUI.updateProcessingRate(processingRateGUI, ratePerSecond)
    if not processingRateGUI or not processingRateGUI.rateLabel then
        return false
    end
    
    -- Use dynamic rate if no rate provided
    if not ratePerSecond then
        ratePerSecond = getCurrentProcessingRate()
    end
    
    local tubeCount = getCurrentTubeCount()
    
    -- Show rate per second with tube count
    processingRateGUI.rateLabel.Text = string.format("%.1f/s (%d tubes)", ratePerSecond, tubeCount)
    
    return true
end

-- Alternative display formats
function ProcessingRateGUI.setDisplayFormat(processingRateGUI, format, ratePerSecond)
    if not processingRateGUI or not processingRateGUI.rateLabel then
        return false
    end
    
    ratePerSecond = ratePerSecond or PROCESSING_RATE_PER_SECOND
    
    if format == "second" then
        processingRateGUI.rateLabel.Text = string.format("%d/s", ratePerSecond)
    elseif format == "minute" then
        processingRateGUI.rateLabel.Text = string.format("%d/m", ratePerSecond * 60)
    elseif format == "hour" then
        processingRateGUI.rateLabel.Text = string.format("%d/h", ratePerSecond * 3600)
    end
    
    return true
end

-- Add pulse animation effect
function ProcessingRateGUI.addPulseEffect(processingRateGUI)
    if not processingRateGUI or not processingRateGUI.backgroundFrame then
        return false
    end
    
    -- Create gentle pulsing effect
    local TweenService = game:GetService("TweenService")
    local tweenInfo = TweenInfo.new(
        1.5, -- Duration
        Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut,
        -1, -- Repeat infinitely
        true -- Reverse
    )
    
    local pulseTween = TweenService:Create(
        processingRateGUI.backgroundFrame,
        tweenInfo,
        {BackgroundTransparency = 0.3}
    )
    
    pulseTween:Play()
    
    return true
end

-- Update inventory counter display
function ProcessingRateGUI.updateInventoryCounter(processingRateGUI)
    if not processingRateGUI or not processingRateGUI.inventoryText then
        return false
    end
    
    local currentState = Store:getState()
    local currentPets = currentState.player.ownedPets or {}
    local petCount = #currentPets
    
    processingRateGUI.inventoryText.Text = string.format("%d/%d", petCount, PET_INVENTORY_CAP)
    
    -- Change color if inventory is getting full
    if petCount >= PET_INVENTORY_CAP * 0.9 then -- 90% full
        processingRateGUI.inventoryBadge.BackgroundColor3 = Color3.fromRGB(255, 100, 100) -- Red warning
    elseif petCount >= PET_INVENTORY_CAP * 0.7 then -- 70% full
        processingRateGUI.inventoryBadge.BackgroundColor3 = Color3.fromRGB(255, 200, 100) -- Orange warning
    else
        processingRateGUI.inventoryBadge.BackgroundColor3 = Color3.fromRGB(100, 150, 255) -- Normal blue
    end
    
    return true
end

-- Clean up GUI
function ProcessingRateGUI.destroyGUI(guiReference)
    if guiReference and guiReference.anchor and guiReference.anchor.Parent then
        guiReference.anchor:Destroy()
    end
end

return ProcessingRateGUI