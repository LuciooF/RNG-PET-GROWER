-- PlotGUIService - Refactored and simplified client-side GUI service
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local store = require(ReplicatedStorage.store)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)
local PlotConfig = require(ReplicatedStorage.config.PlotConfig)

local PlotGUIService = {}
local connections = {}
local createdGUIs = {} -- Track created GUIs to avoid duplicates

-- Configuration for different GUI types
local GUI_CONFIG = {
    plot = {
        namePrefix = "PlotUI_",
        billboardName = "PlotBillboard",
        moneyIconColor = Color3.fromRGB(255, 255, 255),
        costLabelColor = Color3.fromRGB(255, 255, 255),
        bonusLabelText = function(data) 
            local doorNumber = PlotConfig.getDoorForPlot(data.number)
            return doorNumber and ("+" .. doorNumber .. " Luck") or ""
        end,
        bonusLabelColor = Color3.fromRGB(255, 215, 0), -- Gold for luck
    },
    tubeplot = {
        namePrefix = "TubePlotUI_",
        billboardName = "TubePlotBillboard", 
        moneyIconColor = Color3.fromRGB(255, 165, 0),
        costLabelColor = Color3.fromRGB(255, 165, 0),
        bonusLabelText = function(data) return "+1 Tube" end,
        bonusLabelColor = Color3.fromRGB(255, 165, 0), -- Orange for tubes
    }
}

-- Common function to create base GUI structure
local function createBaseGUI(area, targetObject, config, number)
    local id = area.Name .. "_" .. config.namePrefix .. number
    if createdGUIs[id] then
        return nil -- Already created
    end
    
    -- Create UI part above the target
    local uiPart = Instance.new("Part")
    uiPart.Name = config.namePrefix .. number
    uiPart.Size = Vector3.new(4, 0.1, 4)
    uiPart.Transparency = 1
    uiPart.CanCollide = false
    uiPart.Anchored = true
    
    -- Position above the target
    local targetPosition
    if targetObject:IsA("Model") then
        local cframe, size = targetObject:GetBoundingBox()
        targetPosition = cframe.Position
    else
        targetPosition = targetObject.Position
    end
    uiPart.Position = targetPosition + Vector3.new(0, 2, 0)
    uiPart.Parent = area
    
    -- Create BillboardGui
    local billboard = Instance.new("BillboardGui")
    billboard.Name = config.billboardName
    billboard.Size = UDim2.new(0, 90, 0, 60) -- Taller for bonus text
    billboard.StudsOffset = Vector3.new(0, 0, 0)
    billboard.MaxDistance = 100
    billboard.Parent = uiPart
    
    -- Create container frame
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Position = UDim2.new(0, 0, 0, 0)
    container.Parent = billboard
    
    return {
        uiPart = uiPart,
        billboard = billboard,
        container = container,
        id = id,
        number = number,
        type = config == GUI_CONFIG.plot and "plot" or "tubeplot"
    }
end

-- Common function to create GUI elements (icons, labels)
local function createGUIElements(container, config, data)
    -- Create money icon
    local moneyIcon = Instance.new("ImageLabel")
    moneyIcon.Name = "MoneyIcon"
    moneyIcon.Size = UDim2.new(0, 18, 0, 18)
    moneyIcon.Position = UDim2.new(0, 15, 0.25, -9) -- Centered in top half
    moneyIcon.BackgroundTransparency = 1
    moneyIcon.Image = IconAssets.getIcon("CURRENCY", "MONEY")
    moneyIcon.ScaleType = Enum.ScaleType.Fit
    moneyIcon.Parent = container
    moneyIcon.Visible = false
    
    -- Create rebirth icon
    local rebirthIcon = Instance.new("ImageLabel")
    rebirthIcon.Name = "RebirthIcon"
    rebirthIcon.Size = UDim2.new(0, 20, 0, 20)
    rebirthIcon.Position = UDim2.new(0, 5, 0.25, -10) -- Centered in top half
    rebirthIcon.BackgroundTransparency = 1
    rebirthIcon.Image = IconAssets.getIcon("UI", "REBIRTH")
    rebirthIcon.ScaleType = Enum.ScaleType.Fit
    rebirthIcon.Parent = container
    rebirthIcon.Visible = false
    
    -- Create cost label (positioned in top half)
    local costLabel = Instance.new("TextLabel")
    costLabel.Name = "CostLabel"
    costLabel.Size = UDim2.new(0, 50, 0.5, 0) -- Half height for bonus text
    costLabel.Position = UDim2.new(0, 35, 0, 0) -- Right next to icon, top half
    costLabel.BackgroundTransparency = 1
    costLabel.BorderSizePixel = 0
    costLabel.Font = Enum.Font.FredokaOne
    costLabel.TextSize = ScreenUtils.getTextSize(38)
    costLabel.TextColor3 = config.costLabelColor
    costLabel.TextStrokeTransparency = 0
    costLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    costLabel.TextXAlignment = Enum.TextXAlignment.Left
    costLabel.TextYAlignment = Enum.TextYAlignment.Center
    costLabel.Parent = container
    
    -- Create bonus label (luck/tube text)
    local bonusLabel = Instance.new("TextLabel")
    bonusLabel.Name = "BonusLabel"
    bonusLabel.Size = UDim2.new(1, 0, 0.4, 0) -- Full width, bottom 40%
    bonusLabel.Position = UDim2.new(0, 0, 0.6, 0) -- Bottom section
    bonusLabel.BackgroundTransparency = 1
    bonusLabel.BorderSizePixel = 0
    bonusLabel.Font = Enum.Font.FredokaOne
    bonusLabel.TextSize = ScreenUtils.getTextSize(28)
    bonusLabel.TextColor3 = config.bonusLabelColor
    bonusLabel.TextStrokeTransparency = 0
    bonusLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    bonusLabel.TextXAlignment = Enum.TextXAlignment.Center
    bonusLabel.TextYAlignment = Enum.TextYAlignment.Top
    bonusLabel.Text = config.bonusLabelText(data)
    bonusLabel.Parent = container
    
    return {
        moneyIcon = moneyIcon,
        rebirthIcon = rebirthIcon,
        costLabel = costLabel,
        bonusLabel = bonusLabel
    }
end

-- Unified GUI creation function
local function createGUI(area, targetObject, guiType, number)
    local config = GUI_CONFIG[guiType]
    if not config then
        warn("PlotGUIService: Invalid GUI type:", guiType)
        return
    end
    
    local baseGUI = createBaseGUI(area, targetObject, config, number)
    if not baseGUI then
        return -- Already exists
    end
    
    local elements = createGUIElements(baseGUI.container, config, baseGUI)
    
    -- Store created GUI data
    createdGUIs[baseGUI.id] = {
        uiPart = baseGUI.uiPart,
        billboard = baseGUI.billboard,
        container = baseGUI.container,
        moneyIcon = elements.moneyIcon,
        rebirthIcon = elements.rebirthIcon,
        costLabel = elements.costLabel,
        bonusLabel = elements.bonusLabel,
        number = number,
        type = guiType
    }
end

-- GetDoorForPlot function moved to PlotConfig.getDoorForPlot() for centralization

-- Public interface functions
function PlotGUIService:CreatePlotGUI(area, plot, plotNumber)
    createGUI(area, plot, "plot", plotNumber)
end

function PlotGUIService:CreateTubePlotGUI(area, tubePlot, tubePlotNumber)
    createGUI(area, tubePlot, "tubeplot", tubePlotNumber)
end

-- Unified update logic
local function updateGUIState(guiData, playerMoney, playerRebirths, ownedSet, isPlot)
    local number = guiData.number
    local moneyIcon = guiData.moneyIcon
    local rebirthIcon = guiData.rebirthIcon
    local costLabel = guiData.costLabel
    local bonusLabel = guiData.bonusLabel
    local billboard = guiData.billboard
    
    -- Get requirements and cost based on type
    local requiredRebirths, cost, shouldShowRebirthText
    if isPlot then
        requiredRebirths = PlotConfig.getPlotRebirthRequirement(number)
        cost = PlotConfig.getPlotCost(number, playerRebirths)
        shouldShowRebirthText = requiredRebirths == (playerRebirths + 1) and PlotConfig.isMiddlePlotOfRow(number)
    else
        requiredRebirths = PlotConfig.getTubePlotRebirthRequirement(number)
        cost = PlotConfig.getTubePlotCost(number, playerRebirths)
        shouldShowRebirthText = PlotConfig.shouldShowTubePlotRebirthText(number, playerRebirths)
    end
    
    if ownedSet[number] then
        -- Owned - hide GUI entirely
        billboard.Enabled = false
        
    elseif playerRebirths < requiredRebirths then
        -- Show rebirth requirement
        if shouldShowRebirthText then
            moneyIcon.Visible = false
            rebirthIcon.Visible = true
            -- Center the rebirth icon horizontally
            rebirthIcon.Position = UDim2.new(0.5, -10, 0.15, 0) -- Centered horizontally, top section
            rebirthIcon.Size = UDim2.new(0, 20, 0, 20)
            
            costLabel.Text = requiredRebirths .. " Needed"
            -- Always use black text for "x Needed"
            costLabel.TextColor3 = Color3.fromRGB(0, 0, 0) -- Black text
            costLabel.TextStrokeColor3 = Color3.fromRGB(255, 255, 255) -- White stroke for visibility
            costLabel.TextSize = ScreenUtils.getTextSize(36)
            -- Position text below the centered icon
            costLabel.Position = UDim2.new(0, 0, 0.45, 0) -- Below icon
            costLabel.Size = UDim2.new(1, 0, 0.5, 0) -- Full width, bottom half
            costLabel.TextXAlignment = Enum.TextXAlignment.Center -- Center the text
            bonusLabel.Visible = false -- Hide bonus for locked
            billboard.Size = UDim2.new(0, 100, 0, 50) -- Adjust width
            billboard.Enabled = true
        else
            billboard.Enabled = false
        end
        
    elseif cost == 0 then
        -- Free
        moneyIcon.Visible = false
        rebirthIcon.Visible = false
        costLabel.Text = "FREE"
        costLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        costLabel.TextSize = ScreenUtils.getTextSize(38)
        costLabel.Position = UDim2.new(0, 0, 0, 0)
        costLabel.Size = UDim2.new(1, 0, 0.5, 0) -- Half height for bonus text
        costLabel.TextXAlignment = Enum.TextXAlignment.Center
        bonusLabel.Visible = true
        billboard.Size = UDim2.new(0, 80, 0, 60)
        billboard.Enabled = true
        
    else
        -- Show price
        moneyIcon.Visible = true
        rebirthIcon.Visible = false
        costLabel.Text = NumberFormatter.format(cost)
        costLabel.Position = UDim2.new(0, 35, 0, 0)
        costLabel.Size = UDim2.new(0, 50, 0.5, 0) -- Half height for bonus text
        costLabel.TextXAlignment = Enum.TextXAlignment.Left
        bonusLabel.Visible = true
        
        -- Color based on affordability
        local config = GUI_CONFIG[guiData.type]
        if playerMoney >= cost then
            costLabel.TextColor3 = Color3.fromRGB(0, 255, 0) -- Green
        else
            costLabel.TextColor3 = Color3.fromRGB(255, 0, 0) -- Red
        end
        
        costLabel.TextSize = ScreenUtils.getTextSize(38)
        billboard.Size = UDim2.new(0, 90, 0, 60)
        billboard.Enabled = true
    end
end

-- Public update functions
function PlotGUIService:UpdatePlotGUI(guiData, playerMoney, playerRebirths, ownedPlotsSet)
    updateGUIState(guiData, playerMoney, playerRebirths, ownedPlotsSet, true)
end

function PlotGUIService:UpdateTubePlotGUI(guiData, playerMoney, playerRebirths, ownedTubesSet)
    updateGUIState(guiData, playerMoney, playerRebirths, ownedTubesSet, false)
end

-- Update all GUIs based on current player data from Rodux store
function PlotGUIService:UpdateAllGUIs()
    local state = store:getState()
    local playerMoney = state.player.Resources.Money or 0
    local playerRebirths = state.player.Resources.Rebirths or 0
    local ownedPlots = state.player.OwnedPlots or {}
    local ownedTubes = state.player.OwnedTubes or {}
    
    
    -- Convert arrays to sets for faster lookup
    local ownedPlotsSet = {}
    for _, plotNumber in pairs(ownedPlots) do
        ownedPlotsSet[plotNumber] = true
    end
    
    local ownedTubesSet = {}
    for _, tubeNumber in pairs(ownedTubes) do
        ownedTubesSet[tubeNumber] = true
    end
    
    -- Update all GUIs
    for _, guiData in pairs(createdGUIs) do
        if guiData.type == "plot" then
            self:UpdatePlotGUI(guiData, playerMoney, playerRebirths, ownedPlotsSet)
        elseif guiData.type == "tubeplot" then
            self:UpdateTubePlotGUI(guiData, playerMoney, playerRebirths, ownedTubesSet)
        end
    end
end

-- Scan for plots and tubeplots to create GUIs (optimized to only scan local player area)
function PlotGUIService:ScanAndCreateGUIs()
    -- Use PlayerAreaFinder to get only the local player's area
    local PlayerAreaFinder = require(ReplicatedStorage.utils.PlayerAreaFinder)
    local playerArea = PlayerAreaFinder:WaitForPlayerArea(5)
    
    if not playerArea then
        warn("PlotGUIService: Could not find local player area")
        return
    end
    
    local buttonsFolder = playerArea:FindFirstChild("Buttons")
    if not buttonsFolder then
        warn("PlotGUIService: Buttons folder not found in player area")
        return
    end
    
    -- Create plot GUIs for local player area only
    for i = 1, PlotConfig.TOTAL_PLOTS do
        if i ~= 6 and i ~= 7 then -- Skip non-existent plots
            local plot = buttonsFolder:FindFirstChild("Plot" .. i)
            if plot then
                self:CreatePlotGUI(playerArea, plot, i)
            end
        end
    end
    
    -- Create tubeplot GUIs for local player area only
    for i = 1, PlotConfig.TOTAL_TUBEPLOTS do
        local tubePlot = buttonsFolder:FindFirstChild("TubePlot" .. i)
        if tubePlot then
            self:CreateTubePlotGUI(playerArea, tubePlot, i)
        end
    end
    
    -- Clean up any misplaced GUIs on mixer buttons
    for _, child in pairs(buttonsFolder:GetChildren()) do
        if child.Name:match("^Mixer%dButton$") then
            -- Remove any plot-style GUIs from mixer buttons
            for _, descendant in pairs(child:GetDescendants()) do
                if descendant:IsA("BillboardGui") and 
                   (descendant.Name == "PlotGUI" or descendant.Name == "TubePlotGUI") then
                    descendant:Destroy()
                    warn("PlotGUIService: Removed misplaced GUI from", child.Name)
                end
            end
        end
    end
end

-- Initialize the service
function PlotGUIService:Initialize()
    local success, error = pcall(function()
        -- Scan and create GUIs (PlayerAreaFinder handles waiting properly)
        self:ScanAndCreateGUIs()
        
        -- Subscribe to store changes
        connections.storeConnection = store.changed:connect(function()
            self:UpdateAllGUIs()
        end)
        
        -- Initial update
        self:UpdateAllGUIs()
        
        -- PlotGUIService initialized successfully
    end)
    
    if not success then
        warn("PlotGUIService initialization failed:", error)
    end
end

-- Cleanup function
function PlotGUIService:Cleanup()
    -- Disconnect all connections
    for _, connection in pairs(connections) do
        if connection and connection.disconnect then
            connection:disconnect()
        end
    end
    connections = {}
    
    -- Clean up all GUIs
    for _, guiData in pairs(createdGUIs) do
        if guiData.uiPart and guiData.uiPart.Parent then
            guiData.uiPart:Destroy()
        end
    end
    createdGUIs = {}
    
    -- PlotGUIService cleaned up
end

return PlotGUIService