-- PlotGUIService - Client-side service for creating and managing plot GUIs with icons
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DataSyncService = require(script.Parent.DataSyncService)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)

local PlotGUIService = {}
local connections = {}
local createdGUIs = {} -- Track created GUIs to avoid duplicates

-- Plot configuration (matches server)
local TOTAL_PLOTS = 35
local TOTAL_TUBEPLOTS = 10

-- Helper functions for plot requirements (matches server)
local function getPlotRebirthRequirement(plotNumber)
    if plotNumber >= 1 and plotNumber <= 5 then
        return 0
    elseif plotNumber >= 8 and plotNumber <= 14 then
        return 1
    elseif plotNumber >= 15 and plotNumber <= 21 then
        return 2
    elseif plotNumber >= 22 and plotNumber <= 28 then
        return 4 -- Skip rebirth 3
    elseif plotNumber >= 29 and plotNumber <= 35 then
        return 5
    else
        return 999 -- Invalid plot numbers (6, 7)
    end
end

local function getTubePlotRebirthRequirement(tubePlotNumber)
    return tubePlotNumber - 1
end

-- Plot cost functions (matches server)
local function getPlotCost(plotNumber, playerRebirths)
    if plotNumber == 1 then
        return 0 -- First plot is free
    end
    
    -- Start at 25 for second plot, increment by 70% (1.7x) for each subsequent plot (matches server)
    local baseCost = 25
    local scalingFactor = 1.7 -- 70% increment per plot
    
    -- Apply rebirth-based multipliers to the base cost
    playerRebirths = playerRebirths or 0
    local rebirthMultiplier = 1.0
    
    if playerRebirths <= 1 then
        -- Easier for first two rebirths (20% cheaper)
        rebirthMultiplier = 0.8
    elseif playerRebirths <= 3 then
        -- Normal pricing for rebirths 2-3
        rebirthMultiplier = 1.0
    else
        -- 50% more expensive after rebirth 4+
        rebirthMultiplier = 1.5
    end
    
    local finalCost = baseCost * (scalingFactor ^ (plotNumber - 2)) * rebirthMultiplier
    return math.floor(finalCost)
end

local function getTubePlotCost(tubePlotNumber, playerRebirths)
    if tubePlotNumber == 1 then
        return 0 -- First tubeplot is free
    end
    
    -- Make tube plots quite hard with aggressive scaling (matches server)
    playerRebirths = playerRebirths or 0
    local baseCost = 50 -- Much higher base cost than regular plots
    local scalingFactor = 3.5 -- Aggressive 3.5x scaling instead of 2x
    
    -- Even harder scaling for higher rebirths to maintain challenge
    if playerRebirths >= 4 then
        baseCost = 100
        scalingFactor = 4.0
    elseif playerRebirths >= 2 then
        baseCost = 75
        scalingFactor = 3.8
    end
    
    return math.floor(baseCost * (scalingFactor ^ (tubePlotNumber - 2)))
end

-- Helper function to check if plot is middle of row (for rebirth text display)
local function isMiddlePlotOfRow(plotNumber)
    if plotNumber >= 1 and plotNumber <= 5 then
        return plotNumber == 3 -- Middle of first row
    elseif plotNumber >= 8 and plotNumber <= 14 then
        return plotNumber == 11 -- Middle of second row
    elseif plotNumber >= 15 and plotNumber <= 21 then
        return plotNumber == 18 -- Middle of third row
    elseif plotNumber >= 22 and plotNumber <= 28 then
        return plotNumber == 25 -- Middle of fourth row
    elseif plotNumber >= 29 and plotNumber <= 35 then
        return plotNumber == 32 -- Middle of fifth row
    end
    return false
end

-- Helper function for tubeplot rebirth text display
local function shouldShowTubePlotRebirthText(tubePlotNumber, playerRebirths)
    local requiredRebirths = getTubePlotRebirthRequirement(tubePlotNumber)
    -- Only show for NEXT rebirth tier and on first tubeplot that needs higher rebirth
    return requiredRebirths == (playerRebirths + 1) and (tubePlotNumber == 1 or playerRebirths >= getTubePlotRebirthRequirement(tubePlotNumber - 1))
end

-- Create GUI for a plot
function PlotGUIService:CreatePlotGUI(area, plot, plotNumber)
    local plotId = area.Name .. "_Plot" .. plotNumber
    if createdGUIs[plotId] then
        return -- Already created
    end
    
    -- Create UI part above the plot
    local uiPart = Instance.new("Part")
    uiPart.Name = "PlotUI_" .. plotNumber
    uiPart.Size = Vector3.new(4, 0.1, 4)
    uiPart.Transparency = 1
    uiPart.CanCollide = false
    uiPart.Anchored = true
    
    -- Position above the plot
    local plotPosition
    if plot:IsA("Model") then
        local cframe, size = plot:GetBoundingBox()
        plotPosition = cframe.Position
    else
        plotPosition = plot.Position
    end
    uiPart.Position = plotPosition + Vector3.new(0, 2, 0)
    uiPart.Parent = area
    
    -- Create BillboardGui (smaller for price displays)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PlotBillboard"
    billboard.Size = UDim2.new(0, 90, 0, 40) -- Smaller size
    billboard.StudsOffset = Vector3.new(0, 0, 0)
    billboard.MaxDistance = 100
    billboard.Parent = uiPart
    
    -- Create container frame for very tight icon + text layout
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Position = UDim2.new(0, 0, 0, 0)
    container.Parent = billboard
    
    -- Create money icon (positioned absolutely for tight control)
    local moneyIcon = Instance.new("ImageLabel")
    moneyIcon.Name = "MoneyIcon"
    moneyIcon.Size = UDim2.new(0, 18, 0, 18)
    moneyIcon.Position = UDim2.new(0, 15, 0.5, -9) -- Positioned on left side
    moneyIcon.BackgroundTransparency = 1
    moneyIcon.Image = IconAssets.getIcon("CURRENCY", "MONEY")
    moneyIcon.ScaleType = Enum.ScaleType.Fit
    moneyIcon.Parent = container
    moneyIcon.Visible = false -- Hidden by default
    
    -- Create rebirth icon (positioned absolutely for tight control)
    local rebirthIcon = Instance.new("ImageLabel")
    rebirthIcon.Name = "RebirthIcon"
    rebirthIcon.Size = UDim2.new(0, 20, 0, 20)
    rebirthIcon.Position = UDim2.new(0, 5, 0.5, -10) -- Positioned on left side
    rebirthIcon.BackgroundTransparency = 1
    rebirthIcon.Image = IconAssets.getIcon("UI", "REBIRTH")
    rebirthIcon.ScaleType = Enum.ScaleType.Fit
    rebirthIcon.Parent = container
    rebirthIcon.Visible = false -- Hidden by default
    
    -- Create cost label (positioned right next to icon)
    local costLabel = Instance.new("TextLabel")
    costLabel.Name = "CostLabel"
    costLabel.Size = UDim2.new(0, 50, 1, 0) -- Small width, positioned next to icon
    costLabel.Position = UDim2.new(0, 35, 0, 0) -- Right next to icon
    costLabel.BackgroundTransparency = 1
    costLabel.BorderSizePixel = 0
    costLabel.Font = Enum.Font.GothamBold
    costLabel.TextSize = ScreenUtils.getTextSize(22)
    costLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    costLabel.TextStrokeTransparency = 0
    costLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    costLabel.TextXAlignment = Enum.TextXAlignment.Left
    costLabel.TextYAlignment = Enum.TextYAlignment.Center
    costLabel.Parent = container
    
    createdGUIs[plotId] = {
        uiPart = uiPart,
        billboard = billboard,
        container = container,
        moneyIcon = moneyIcon,
        rebirthIcon = rebirthIcon,
        costLabel = costLabel,
        plotNumber = plotNumber
    }
end

-- Create GUI for a tubeplot
function PlotGUIService:CreateTubePlotGUI(area, tubePlot, tubePlotNumber)
    local tubePlotId = area.Name .. "_TubePlot" .. tubePlotNumber
    if createdGUIs[tubePlotId] then
        return -- Already created
    end
    
    -- Create UI part above the tubeplot
    local uiPart = Instance.new("Part")
    uiPart.Name = "TubePlotUI_" .. tubePlotNumber
    uiPart.Size = Vector3.new(4, 0.1, 4)
    uiPart.Transparency = 1
    uiPart.CanCollide = false
    uiPart.Anchored = true
    
    -- Position above the tubeplot
    local tubePlotPosition
    if tubePlot:IsA("Model") then
        local cframe, size = tubePlot:GetBoundingBox()
        tubePlotPosition = cframe.Position
    else
        tubePlotPosition = tubePlot.Position
    end
    uiPart.Position = tubePlotPosition + Vector3.new(0, 2, 0)
    uiPart.Parent = area
    
    -- Create BillboardGui (smaller for price displays)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "TubePlotBillboard"
    billboard.Size = UDim2.new(0, 90, 0, 40) -- Smaller size
    billboard.StudsOffset = Vector3.new(0, 0, 0)
    billboard.MaxDistance = 100
    billboard.Parent = uiPart
    
    -- Create container frame for very tight icon + text layout
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Position = UDim2.new(0, 0, 0, 0)
    container.Parent = billboard
    
    -- Create money icon (positioned absolutely for tight control)
    local moneyIcon = Instance.new("ImageLabel")
    moneyIcon.Name = "MoneyIcon"
    moneyIcon.Size = UDim2.new(0, 18, 0, 18)
    moneyIcon.Position = UDim2.new(0, 15, 0.5, -9) -- Positioned on left side
    moneyIcon.BackgroundTransparency = 1
    moneyIcon.Image = IconAssets.getIcon("CURRENCY", "MONEY")
    moneyIcon.ScaleType = Enum.ScaleType.Fit
    moneyIcon.Parent = container
    moneyIcon.Visible = false -- Hidden by default
    
    -- Create rebirth icon (positioned absolutely for tight control)
    local rebirthIcon = Instance.new("ImageLabel")
    rebirthIcon.Name = "RebirthIcon"
    rebirthIcon.Size = UDim2.new(0, 20, 0, 20)
    rebirthIcon.Position = UDim2.new(0, 5, 0.5, -10) -- Positioned on left side
    rebirthIcon.BackgroundTransparency = 1
    rebirthIcon.Image = IconAssets.getIcon("UI", "REBIRTH")
    rebirthIcon.ScaleType = Enum.ScaleType.Fit
    rebirthIcon.Parent = container
    rebirthIcon.Visible = false -- Hidden by default
    
    -- Create cost label (positioned right next to icon)
    local costLabel = Instance.new("TextLabel")
    costLabel.Name = "CostLabel"
    costLabel.Size = UDim2.new(0, 50, 1, 0) -- Small width, positioned next to icon
    costLabel.Position = UDim2.new(0, 35, 0, 0) -- Right next to icon
    costLabel.BackgroundTransparency = 1
    costLabel.BorderSizePixel = 0
    costLabel.Font = Enum.Font.GothamBold
    costLabel.TextSize = ScreenUtils.getTextSize(22)
    costLabel.TextColor3 = Color3.fromRGB(255, 165, 0) -- Orange for tubeplots
    costLabel.TextStrokeTransparency = 0
    costLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    costLabel.TextXAlignment = Enum.TextXAlignment.Left
    costLabel.TextYAlignment = Enum.TextYAlignment.Center
    costLabel.Parent = container
    
    createdGUIs[tubePlotId] = {
        uiPart = uiPart,
        billboard = billboard,
        container = container,
        moneyIcon = moneyIcon,
        rebirthIcon = rebirthIcon,
        costLabel = costLabel,
        tubePlotNumber = tubePlotNumber
    }
end

-- Update all plot GUIs based on current player data
function PlotGUIService:UpdateAllGUIs()
    local playerData = DataSyncService:GetPlayerData()
    if not playerData then return end
    
    local playerMoney = playerData.Resources.Money or 0
    local playerRebirths = playerData.Resources.Rebirths or 0
    local ownedPlots = playerData.OwnedPlots or {}
    local ownedTubes = playerData.OwnedTubes or {}
    
    -- Create sets for faster lookup
    local ownedPlotsSet = {}
    for _, plotNumber in pairs(ownedPlots) do
        ownedPlotsSet[plotNumber] = true
    end
    
    local ownedTubesSet = {}
    for _, tubeNumber in pairs(ownedTubes) do
        ownedTubesSet[tubeNumber] = true
    end
    
    -- Update all plot GUIs
    for guiId, guiData in pairs(createdGUIs) do
        if guiData.plotNumber then
            self:UpdatePlotGUI(guiData, playerMoney, playerRebirths, ownedPlotsSet)
        elseif guiData.tubePlotNumber then
            self:UpdateTubePlotGUI(guiData, playerMoney, playerRebirths, ownedTubesSet)
        end
    end
end

-- Update individual plot GUI
function PlotGUIService:UpdatePlotGUI(guiData, playerMoney, playerRebirths, ownedPlotsSet)
    local plotNumber = guiData.plotNumber
    local requiredRebirths = getPlotRebirthRequirement(plotNumber)
    local plotCost = getPlotCost(plotNumber, playerRebirths)
    
    local moneyIcon = guiData.moneyIcon
    local rebirthIcon = guiData.rebirthIcon
    local costLabel = guiData.costLabel
    local billboard = guiData.billboard
    
    if ownedPlotsSet[plotNumber] then
        -- Owned plot - hide GUI entirely (surface GUI already shows owned status)
        guiData.billboard.Enabled = false
        
    elseif playerRebirths < requiredRebirths then
        -- Show rebirth requirement ONLY for the next rebirth tier (playerRebirths + 1)
        if requiredRebirths == (playerRebirths + 1) and isMiddlePlotOfRow(plotNumber) then
            -- Show rebirth icon and text
            moneyIcon.Visible = false
            rebirthIcon.Visible = true
            costLabel.Text = requiredRebirths .. " Needed"
            costLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
            costLabel.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
            costLabel.TextSize = ScreenUtils.getTextSize(24)
            -- Adjust positioning for rebirth text (wider)
            costLabel.Position = UDim2.new(0, 30, 0, 0) -- More space for "Needed" text
            costLabel.Size = UDim2.new(0, 80, 1, 0)
            billboard.Size = UDim2.new(0, 120, 0, 50)
            guiData.billboard.Enabled = true
        else
            -- Hide on non-next-tier plots or non-middle plots
            guiData.billboard.Enabled = false
        end
        
    elseif plotCost == 0 then
        -- Free plot - center text, no icon
        moneyIcon.Visible = false
        rebirthIcon.Visible = false
        costLabel.Text = "FREE"
        costLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        costLabel.TextSize = ScreenUtils.getTextSize(22)
        costLabel.Position = UDim2.new(0, 0, 0, 0) -- Centered
        costLabel.Size = UDim2.new(1, 0, 1, 0)
        costLabel.TextXAlignment = Enum.TextXAlignment.Center
        billboard.Size = UDim2.new(0, 80, 0, 35)
        guiData.billboard.Enabled = true
        
    else
        -- Show price with money icon - very tight positioning
        moneyIcon.Visible = true
        rebirthIcon.Visible = false
        costLabel.Text = NumberFormatter.format(plotCost)
        costLabel.Position = UDim2.new(0, 35, 0, 0) -- Right next to icon (18px icon + 2px gap + 15px padding)
        costLabel.Size = UDim2.new(0, 50, 1, 0)
        costLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        if playerMoney >= plotCost then
            -- Can afford (green)
            costLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        else
            -- Can't afford (red)
            costLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        end
        
        costLabel.TextSize = ScreenUtils.getTextSize(22)
        billboard.Size = UDim2.new(0, 90, 0, 40)
        guiData.billboard.Enabled = true
    end
end

-- Update individual tubeplot GUI
function PlotGUIService:UpdateTubePlotGUI(guiData, playerMoney, playerRebirths, ownedTubesSet)
    local tubePlotNumber = guiData.tubePlotNumber
    local requiredRebirths = getTubePlotRebirthRequirement(tubePlotNumber)
    local tubePlotCost = getTubePlotCost(tubePlotNumber, playerRebirths)
    
    local moneyIcon = guiData.moneyIcon
    local rebirthIcon = guiData.rebirthIcon
    local costLabel = guiData.costLabel
    local billboard = guiData.billboard
    
    if ownedTubesSet[tubePlotNumber] then
        -- Owned tubeplot - hide GUI entirely (surface GUI already shows owned status)
        guiData.billboard.Enabled = false
        
    elseif playerRebirths < requiredRebirths then
        -- Show rebirth requirement (only on first that needs higher rebirth)
        if shouldShowTubePlotRebirthText(tubePlotNumber, playerRebirths) then
            -- Show rebirth icon and text
            moneyIcon.Visible = false
            rebirthIcon.Visible = true
            costLabel.Text = requiredRebirths .. " Needed"
            costLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
            costLabel.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
            costLabel.TextSize = ScreenUtils.getTextSize(24)
            -- Adjust positioning for rebirth text (wider)
            costLabel.Position = UDim2.new(0, 30, 0, 0) -- More space for "Needed" text
            costLabel.Size = UDim2.new(0, 80, 1, 0)
            billboard.Size = UDim2.new(0, 120, 0, 50)
            guiData.billboard.Enabled = true
        else
            -- Hide on other tubeplots that need rebirths
            guiData.billboard.Enabled = false
        end
        
    elseif tubePlotCost == 0 then
        -- Free tubeplot - center text, no icon
        moneyIcon.Visible = false
        rebirthIcon.Visible = false
        costLabel.Text = "FREE"
        costLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        costLabel.TextSize = ScreenUtils.getTextSize(22)
        costLabel.Position = UDim2.new(0, 0, 0, 0) -- Centered
        costLabel.Size = UDim2.new(1, 0, 1, 0)
        costLabel.TextXAlignment = Enum.TextXAlignment.Center
        billboard.Size = UDim2.new(0, 80, 0, 35)
        guiData.billboard.Enabled = true
        
    else
        -- Show price with money icon - very tight positioning
        moneyIcon.Visible = true
        rebirthIcon.Visible = false
        costLabel.Text = NumberFormatter.format(tubePlotCost)
        costLabel.Position = UDim2.new(0, 35, 0, 0) -- Right next to icon (18px icon + 2px gap + 15px padding)
        costLabel.Size = UDim2.new(0, 50, 1, 0)
        costLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        if playerMoney >= tubePlotCost then
            -- Can afford (green)
            costLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        else
            -- Can't afford (red)
            costLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        end
        
        costLabel.TextSize = ScreenUtils.getTextSize(22)
        billboard.Size = UDim2.new(0, 90, 0, 40)
        guiData.billboard.Enabled = true
    end
end

-- Find and create GUIs for all plots in player areas
function PlotGUIService:ScanAndCreateGUIs()
    local player = Players.LocalPlayer
    local playerAreas = Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then return end
    
    -- Find player's assigned area
    local playerArea = nil
    for _, area in pairs(playerAreas:GetChildren()) do
        if area.Name:match("PlayerArea") then
            -- Check if this area belongs to the current player by looking at the nameplate
            local nameplate = area:FindFirstChild("AreaNameplate")
            if nameplate then
                local billboard = nameplate:FindFirstChild("NameplateBillboard")
                if billboard then
                    local textLabel = billboard:FindFirstChild("TextLabel")
                    if textLabel and textLabel.Text == (player.Name .. "'s Area") then
                        playerArea = area
                        break
                    end
                end
            end
        end
    end
    
    if not playerArea then return end
    
    -- Create GUIs for plots
    for plotNumber = 1, TOTAL_PLOTS do
        if plotNumber ~= 6 and plotNumber ~= 7 then -- Skip invalid plots
            local plot = playerArea:FindFirstChild("Buttons") and playerArea.Buttons:FindFirstChild("Plot" .. plotNumber)
            if plot then
                self:CreatePlotGUI(playerArea, plot, plotNumber)
            end
        end
    end
    
    -- Create GUIs for tubeplots
    for tubePlotNumber = 1, TOTAL_TUBEPLOTS do
        local tubePlot = playerArea:FindFirstChild("Buttons") and playerArea.Buttons:FindFirstChild("TubePlot" .. tubePlotNumber)
        if tubePlot then
            self:CreateTubePlotGUI(playerArea, tubePlot, tubePlotNumber)
        end
    end
end

-- Initialize the service
function PlotGUIService:Initialize()
    local success, error = pcall(function()
        -- Wait a moment for areas to load
        task.wait(2)
        
        -- Scan and create GUIs
        self:ScanAndCreateGUIs()
        
        -- Subscribe to data changes to keep GUIs updated
        local unsubscribe = DataSyncService:Subscribe(function(newState)
            if newState.player then
                self:UpdateAllGUIs()
            end
        end)
        
        connections.dataSubscription = unsubscribe
        
        -- Update GUIs initially
        self:UpdateAllGUIs()
        
    end)
    
    if not success then
        warn("PlotGUIService initialization failed:", error)
        return false
    end
    
    return true
end

-- Cleanup the service
function PlotGUIService:Cleanup()
    -- Disconnect all connections
    for name, connection in pairs(connections) do
        if connection and type(connection) == "function" then
            connection()
        elseif connection and typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end
    connections = {}
    
    -- Clean up created GUIs
    for guiId, guiData in pairs(createdGUIs) do
        if guiData.uiPart and guiData.uiPart.Parent then
            guiData.uiPart:Destroy()
        end
    end
    createdGUIs = {}
end

return PlotGUIService