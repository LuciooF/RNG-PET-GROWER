-- Plot GUI Controller
-- Handles plot billboard GUI creation, updates, and visibility management
-- Extracted from PlotVisualsService.lua to follow modular architecture

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PlotConfig = require(ReplicatedStorage.Shared.config.PlotConfig)
local ProductionPlotConfig = require(ReplicatedStorage.Shared.config.ProductionPlotConfig)
local assets = require(ReplicatedStorage.assets)

local PlotGUIController = {}

local player = Players.LocalPlayer
local plotGUIs = {} -- Store references to plot GUIs

-- Distance threshold for showing GUIs (in studs) - reduced for closer proximity
local GUI_VISIBILITY_DISTANCE = 50

-- Create or update plot GUI (optimized to avoid recreation)
function PlotGUIController.updatePlotGUI(plot, plotId, state, playerData, isProductionPlot)
    -- Get GUI text from appropriate config
    local guiText
    if isProductionPlot then
        guiText = ProductionPlotConfig:GetPlotGUIText(plotId, state, playerData.rebirths or 0)
    else
        guiText = PlotConfig:GetPlotGUIText(plotId, state, playerData.rebirths or 0)
    end
    
    -- Check if GUI exists
    local existingGUI = plot:FindFirstChild("PlotGUIAnchor")
    
    if guiText == "" then
        -- Remove GUI if no text to show
        if existingGUI then
            existingGUI:Destroy()
        end
        return
    end
    
    -- If GUI exists, try to update text instead of recreating
    if existingGUI then
        local billboardGui = existingGUI:FindFirstChild("PlotGUI")
        local textLabel = billboardGui and billboardGui:FindFirstChild("PlotText")
        
        if textLabel and textLabel.Text ~= guiText then
            -- Update text only if it changed
            textLabel.Text = guiText
            return
        elseif textLabel and textLabel.Text == guiText then
            -- Text is same, no update needed
            return
        end
        
        -- If we can't update, destroy and recreate
        existingGUI:Destroy()
    end
    
    -- Create GUI anchor (invisible part above the plot)
    local guiAnchor = Instance.new("Part")
    guiAnchor.Name = "PlotGUIAnchor"
    guiAnchor.Size = Vector3.new(1, 1, 1)
    guiAnchor.Transparency = 1
    guiAnchor.CanCollide = false
    guiAnchor.Anchored = true
    
    -- Position above the plot
    local plotCenter = PlotGUIController.getPlotCenter(plot)
    guiAnchor.Position = plotCenter + Vector3.new(0, 3, 0)
    guiAnchor.Parent = plot
    
    -- Create BillboardGui (smaller size for cleaner look)
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "PlotGUI"
    billboardGui.Size = UDim2.new(0, 120, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 0, 0)
    billboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    billboardGui.Enabled = false -- Start disabled, proximity will enable it
    billboardGui.Parent = guiAnchor
    
    -- Check if this is a price display (should show cash icon)
    local shouldShowCashIcon = (state == PlotConfig.STATES.UNLOCKED_CANT_AFFORD or state == PlotConfig.STATES.UNLOCKED_CAN_AFFORD) and guiText ~= ""
    
    if shouldShowCashIcon then
        PlotGUIController.createPriceGUI(billboardGui, guiText, state)
    else
        PlotGUIController.createTextGUI(billboardGui, guiText, state)
    end
    
    -- Store reference
    plotGUIs[plotId] = {
        gui = billboardGui,
        anchor = guiAnchor,
        plot = plot
    }
end

-- Create price GUI with cash icon
function PlotGUIController.createPriceGUI(billboardGui, guiText, state)
    -- Parse the guiText to extract rarity and price
    local lines = string.split(guiText, "\n")
    local rarityText = lines[1] or ""
    local priceText = lines[2] or ""
    
    -- Create frame to hold all elements
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, 0, 1, 0)
    contentFrame.Position = UDim2.new(0, 0, 0, 0)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = billboardGui
    
    -- Create layout for vertical arrangement
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 2)
    layout.Parent = contentFrame
    
    -- Create rarity text label (first line)
    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Name = "RarityText"
    rarityLabel.Size = UDim2.new(1, 0, 0, 30)
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.Text = rarityText
    rarityLabel.TextColor3 = PlotConfig:GetPlotGUIColor(state)
    rarityLabel.TextSize = 14
    rarityLabel.TextWrapped = false
    rarityLabel.TextXAlignment = Enum.TextXAlignment.Center
    rarityLabel.TextYAlignment = Enum.TextYAlignment.Center
    rarityLabel.Font = Enum.Font.GothamBold
    rarityLabel.ZIndex = 2
    rarityLabel.Parent = contentFrame
    
    -- Add black text stroke to rarity
    local rarityStroke = Instance.new("UIStroke")
    rarityStroke.Color = Color3.fromRGB(0, 0, 0)
    rarityStroke.Thickness = 2
    rarityStroke.Transparency = 0
    rarityStroke.Parent = rarityLabel
    
    -- Create frame for cash icon and price (horizontal layout)
    local priceFrame = Instance.new("Frame")
    priceFrame.Name = "PriceFrame"
    priceFrame.Size = UDim2.new(1, 0, 0, 25)
    priceFrame.BackgroundTransparency = 1
    priceFrame.Parent = contentFrame
    
    -- Create horizontal layout for cash icon and price
    local priceLayout = Instance.new("UIListLayout")
    priceLayout.FillDirection = Enum.FillDirection.Horizontal
    priceLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    priceLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    priceLayout.Padding = UDim.new(0, 3)
    priceLayout.Parent = priceFrame
    
    -- Create cash icon (keep original gold color)
    local cashIcon = Instance.new("ImageLabel")
    cashIcon.Name = "CashIcon"
    cashIcon.Size = UDim2.new(0, 16, 0, 16)
    cashIcon.BackgroundTransparency = 1
    cashIcon.Image = assets["vector-icon-pack-2/Currency/Cash/Cash Outline 256.png"] or ""
    cashIcon.ScaleType = Enum.ScaleType.Fit
    cashIcon.ImageColor3 = Color3.fromRGB(255, 215, 0) -- Gold color (not affected by state)
    cashIcon.ZIndex = 2
    cashIcon.Parent = priceFrame
    
    -- Create price text label
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Name = "PriceText"
    priceLabel.Size = UDim2.new(0, 0, 1, 0)
    priceLabel.AutomaticSize = Enum.AutomaticSize.X
    priceLabel.BackgroundTransparency = 1
    priceLabel.Text = priceText
    priceLabel.TextColor3 = PlotConfig:GetPlotGUIColor(state)
    priceLabel.TextSize = 12
    priceLabel.TextWrapped = false
    priceLabel.TextXAlignment = Enum.TextXAlignment.Left
    priceLabel.TextYAlignment = Enum.TextYAlignment.Center
    priceLabel.Font = Enum.Font.GothamBold
    priceLabel.ZIndex = 2
    priceLabel.Parent = priceFrame
    
    -- Add black text stroke to price
    local priceStroke = Instance.new("UIStroke")
    priceStroke.Color = Color3.fromRGB(0, 0, 0)
    priceStroke.Thickness = 2
    priceStroke.Transparency = 0
    priceStroke.Parent = priceLabel
end

-- Create regular text GUI
function PlotGUIController.createTextGUI(billboardGui, guiText, state)
    -- Create regular text label for non-price displays
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "PlotText"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Position = UDim2.new(0, 0, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = guiText
    textLabel.TextColor3 = PlotConfig:GetPlotGUIColor(state)
    textLabel.TextSize = 16
    textLabel.TextWrapped = true
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.Font = Enum.Font.GothamBold
    textLabel.ZIndex = 2
    textLabel.Parent = billboardGui
    
    -- Add black text stroke
    local textStroke = Instance.new("UIStroke")
    textStroke.Color = Color3.fromRGB(0, 0, 0)
    textStroke.Thickness = 2
    textStroke.Transparency = 0
    textStroke.Parent = textLabel
end

-- Update plot GUI visibility based on player distance
function PlotGUIController.updateGUIVisibility()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local playerPosition = player.Character.HumanoidRootPart.Position
    local visibleCount = 0
    
    for plotId, guiData in pairs(plotGUIs) do
        if guiData.gui and guiData.anchor and guiData.plot.Parent then
            local distance = (playerPosition - guiData.anchor.Position).Magnitude
            local shouldBeVisible = distance <= GUI_VISIBILITY_DISTANCE
            
            guiData.gui.Enabled = shouldBeVisible
            
            if shouldBeVisible then
                visibleCount = visibleCount + 1
            end
        else
            -- Clean up invalid references
            plotGUIs[plotId] = nil
        end
    end
end

-- Calculate the center point of a plot model
function PlotGUIController.getPlotCenter(plot)
    local parts = {}
    
    for _, child in pairs(plot:GetChildren()) do
        if child:IsA("BasePart") then
            table.insert(parts, child)
        end
    end
    
    if #parts == 0 then
        return Vector3.new(0, 0, 0)
    end
    
    local totalPosition = Vector3.new(0, 0, 0)
    for _, part in pairs(parts) do
        totalPosition = totalPosition + part.Position
    end
    
    return totalPosition / #parts
end

-- Clean up all plot GUIs
function PlotGUIController.cleanup()
    for plotId, guiData in pairs(plotGUIs) do
        if guiData.anchor and guiData.anchor.Parent then
            guiData.anchor:Destroy()
        end
    end
    plotGUIs = {}
end

-- Get visibility distance (for configuration)
function PlotGUIController.getVisibilityDistance()
    return GUI_VISIBILITY_DISTANCE
end

-- Set visibility distance (for configuration)
function PlotGUIController.setVisibilityDistance(distance)
    GUI_VISIBILITY_DISTANCE = distance
end

return PlotGUIController