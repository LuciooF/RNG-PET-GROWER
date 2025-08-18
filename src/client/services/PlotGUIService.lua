-- PlotGUIService - Client-side service for creating and managing plot GUIs with icons
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

-- Configuration now centralized in PlotConfig

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
    
    -- Create BillboardGui (taller to accommodate luck text)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PlotBillboard"
    billboard.Size = UDim2.new(0, 90, 0, 60) -- Taller for luck text
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
    moneyIcon.Position = UDim2.new(0, 15, 0.25, -9) -- Centered in top half
    moneyIcon.BackgroundTransparency = 1
    moneyIcon.Image = IconAssets.getIcon("CURRENCY", "MONEY")
    moneyIcon.ScaleType = Enum.ScaleType.Fit
    moneyIcon.Parent = container
    moneyIcon.Visible = false -- Hidden by default
    
    -- Create rebirth icon (positioned absolutely for tight control)
    local rebirthIcon = Instance.new("ImageLabel")
    rebirthIcon.Name = "RebirthIcon"
    rebirthIcon.Size = UDim2.new(0, 20, 0, 20)
    rebirthIcon.Position = UDim2.new(0, 5, 0.25, -10) -- Centered in top half
    rebirthIcon.BackgroundTransparency = 1
    rebirthIcon.Image = IconAssets.getIcon("UI", "REBIRTH")
    rebirthIcon.ScaleType = Enum.ScaleType.Fit
    rebirthIcon.Parent = container
    rebirthIcon.Visible = false -- Hidden by default
    
    -- Create cost label (positioned in top half)
    local costLabel = Instance.new("TextLabel")
    costLabel.Name = "CostLabel"
    costLabel.Size = UDim2.new(0, 50, 0.5, 0) -- Half height, positioned next to icon
    costLabel.Position = UDim2.new(0, 35, 0, 0) -- Right next to icon, top half
    costLabel.BackgroundTransparency = 1
    costLabel.BorderSizePixel = 0
    costLabel.Font = Enum.Font.FredokaOne
    costLabel.TextSize = ScreenUtils.getTextSize(22)
    costLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    costLabel.TextStrokeTransparency = 0
    costLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    costLabel.TextXAlignment = Enum.TextXAlignment.Left
    costLabel.TextYAlignment = Enum.TextYAlignment.Center
    costLabel.Parent = container
    
    -- Create luck label (positioned below cost)
    local luckLabel = Instance.new("TextLabel")
    luckLabel.Name = "LuckLabel"
    luckLabel.Size = UDim2.new(1, 0, 0.4, 0) -- Full width, bottom 40%
    luckLabel.Position = UDim2.new(0, 0, 0.6, 0) -- Bottom section
    luckLabel.BackgroundTransparency = 1
    luckLabel.BorderSizePixel = 0
    luckLabel.Font = Enum.Font.FredokaOne
    luckLabel.TextSize = ScreenUtils.getTextSize(16)
    luckLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold color for luck
    luckLabel.TextStrokeTransparency = 0
    luckLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    luckLabel.TextXAlignment = Enum.TextXAlignment.Center
    luckLabel.TextYAlignment = Enum.TextYAlignment.Top
    luckLabel.Text = "" -- Will be set in update function
    luckLabel.Parent = container
    
    createdGUIs[plotId] = {
        uiPart = uiPart,
        billboard = billboard,
        container = container,
        moneyIcon = moneyIcon,
        rebirthIcon = rebirthIcon,
        costLabel = costLabel,
        luckLabel = luckLabel,
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
    
    -- Create BillboardGui (taller to accommodate tube text)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "TubePlotBillboard"
    billboard.Size = UDim2.new(0, 90, 0, 60) -- Taller for tube text
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
    moneyIcon.Position = UDim2.new(0, 15, 0.25, -9) -- Centered in top half
    moneyIcon.BackgroundTransparency = 1
    moneyIcon.Image = IconAssets.getIcon("CURRENCY", "MONEY")
    moneyIcon.ScaleType = Enum.ScaleType.Fit
    moneyIcon.Parent = container
    moneyIcon.Visible = false -- Hidden by default
    
    -- Create rebirth icon (positioned absolutely for tight control)
    local rebirthIcon = Instance.new("ImageLabel")
    rebirthIcon.Name = "RebirthIcon"
    rebirthIcon.Size = UDim2.new(0, 20, 0, 20)
    rebirthIcon.Position = UDim2.new(0, 5, 0.25, -10) -- Centered in top half
    rebirthIcon.BackgroundTransparency = 1
    rebirthIcon.Image = IconAssets.getIcon("UI", "REBIRTH")
    rebirthIcon.ScaleType = Enum.ScaleType.Fit
    rebirthIcon.Parent = container
    rebirthIcon.Visible = false -- Hidden by default
    
    -- Create cost label (positioned in top half)
    local costLabel = Instance.new("TextLabel")
    costLabel.Name = "CostLabel"
    costLabel.Size = UDim2.new(0, 50, 0.5, 0) -- Half height, positioned next to icon
    costLabel.Position = UDim2.new(0, 35, 0, 0) -- Right next to icon, top half
    costLabel.BackgroundTransparency = 1
    costLabel.BorderSizePixel = 0
    costLabel.Font = Enum.Font.FredokaOne
    costLabel.TextSize = ScreenUtils.getTextSize(22)
    costLabel.TextColor3 = Color3.fromRGB(255, 165, 0) -- Orange for tubeplots
    costLabel.TextStrokeTransparency = 0
    costLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    costLabel.TextXAlignment = Enum.TextXAlignment.Left
    costLabel.TextYAlignment = Enum.TextYAlignment.Center
    costLabel.Parent = container
    
    -- Create tube label (positioned below cost) 
    local tubeLabel = Instance.new("TextLabel")
    tubeLabel.Name = "TubeLabel"
    tubeLabel.Size = UDim2.new(1, 0, 0.4, 0) -- Full width, bottom 40%
    tubeLabel.Position = UDim2.new(0, 0, 0.6, 0) -- Bottom section
    tubeLabel.BackgroundTransparency = 1
    tubeLabel.BorderSizePixel = 0
    tubeLabel.Font = Enum.Font.FredokaOne
    tubeLabel.TextSize = ScreenUtils.getTextSize(16)
    tubeLabel.TextColor3 = Color3.fromRGB(255, 165, 0) -- Orange color for tubes
    tubeLabel.TextStrokeTransparency = 0
    tubeLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    tubeLabel.TextXAlignment = Enum.TextXAlignment.Center
    tubeLabel.TextYAlignment = Enum.TextYAlignment.Top
    tubeLabel.Text = "+1 Tube" -- Always shows +1 tube
    tubeLabel.Parent = container
    
    createdGUIs[tubePlotId] = {
        uiPart = uiPart,
        billboard = billboard,
        container = container,
        moneyIcon = moneyIcon,
        rebirthIcon = rebirthIcon,
        costLabel = costLabel,
        tubeLabel = tubeLabel,
        tubePlotNumber = tubePlotNumber
    }
end

-- Update all plot GUIs based on current player data from Rodux store
function PlotGUIService:UpdateAllGUIs()
    local playerData = store:getState().player
    if not playerData then 
        -- No player data available yet
        return 
    end
    
    local playerMoney = playerData.Resources.Money or 0
    local playerRebirths = playerData.Resources.Rebirths or 0
    local ownedPlots = playerData.OwnedPlots or {}
    local ownedTubes = playerData.OwnedTubes or {}
    
    -- Updating plot GUIs with current player data
    
    -- Debug: Print owned plots array
    if #ownedPlots > 0 then
        local plotsList = {}
        for _, plotNumber in pairs(ownedPlots) do
            table.insert(plotsList, tostring(plotNumber))
        end
        -- Processing owned plots
    end
    
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

-- Helper function to get door number for a plot (matching PlotService logic)
function PlotGUIService:GetDoorForPlot(plotNumber)
    -- Skip plots 6 and 7 (they don't exist)
    if plotNumber == 6 or plotNumber == 7 then
        return nil
    end
    
    local LEVEL_CONFIG = {
        [1] = {startPlot = 1, endPlot = 5},   -- Level 1: Plots 1-5, Doors 1-5
        [2] = {startPlot = 8, endPlot = 14},  -- Level 2: Plots 8-14, Doors 1-7
        [3] = {startPlot = 15, endPlot = 21}, -- Level 3: Plots 15-21, Doors 1-7
        [4] = {startPlot = 22, endPlot = 28}, -- Level 4: Plots 22-28, Doors 1-7
        [5] = {startPlot = 29, endPlot = 35}, -- Level 5: Plots 29-35, Doors 1-7
        [6] = {startPlot = 36, endPlot = 42}, -- Level 6: Plots 36-42, Doors 1-7
        [7] = {startPlot = 43, endPlot = 49}  -- Level 7: Plots 43-49, Doors 1-7
    }
    
    for level, config in pairs(LEVEL_CONFIG) do
        if plotNumber >= config.startPlot and plotNumber <= config.endPlot then
            local doorNumber = plotNumber - config.startPlot + 1
            return doorNumber
        end
    end
    
    return nil
end

-- Update individual plot GUI
function PlotGUIService:UpdatePlotGUI(guiData, playerMoney, playerRebirths, ownedPlotsSet)
    local plotNumber = guiData.plotNumber
    local requiredRebirths = PlotConfig.getPlotRebirthRequirement(plotNumber)
    local plotCost = PlotConfig.getPlotCost(plotNumber, playerRebirths)
    
    local moneyIcon = guiData.moneyIcon
    local rebirthIcon = guiData.rebirthIcon
    local costLabel = guiData.costLabel
    local luckLabel = guiData.luckLabel
    local billboard = guiData.billboard
    
    -- Get door number for luck display
    local doorNumber = self:GetDoorForPlot(plotNumber)
    local luckText = doorNumber and ("+" .. doorNumber .. " Luck") or ""
    
    if ownedPlotsSet[plotNumber] then
        -- Owned plot - hide GUI entirely (surface GUI already shows owned status)
        guiData.billboard.Enabled = false
        
    elseif playerRebirths < requiredRebirths then
        -- Show rebirth requirement ONLY for the next rebirth tier (playerRebirths + 1)
        if requiredRebirths == (playerRebirths + 1) and PlotConfig.isMiddlePlotOfRow(plotNumber) then
            -- Show rebirth icon and text
            moneyIcon.Visible = false
            rebirthIcon.Visible = true
            costLabel.Text = requiredRebirths .. " Needed"
            costLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
            costLabel.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
            costLabel.TextSize = ScreenUtils.getTextSize(24)
            -- Adjust positioning for rebirth text (wider)
            costLabel.Position = UDim2.new(0, 30, 0, 0) -- More space for "Needed" text
            costLabel.Size = UDim2.new(0, 80, 1, 0) -- Full height since no luck text
            luckLabel.Visible = false -- Hide luck text for locked plots
            billboard.Size = UDim2.new(0, 120, 0, 50) -- Shorter since no luck text
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
        costLabel.Size = UDim2.new(1, 0, 0.5, 0)
        costLabel.TextXAlignment = Enum.TextXAlignment.Center
        luckLabel.Text = luckText
        luckLabel.Visible = true
        billboard.Size = UDim2.new(0, 80, 0, 60)
        guiData.billboard.Enabled = true
        
    else
        -- Show price with money icon - very tight positioning
        moneyIcon.Visible = true
        rebirthIcon.Visible = false
        costLabel.Text = NumberFormatter.format(plotCost)
        costLabel.Position = UDim2.new(0, 35, 0, 0) -- Right next to icon (18px icon + 2px gap + 15px padding)
        costLabel.Size = UDim2.new(0, 50, 0.5, 0)
        luckLabel.Text = luckText
        luckLabel.Visible = true
        costLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        if playerMoney >= plotCost then
            -- Can afford (green)
            costLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        else
            -- Can't afford (red)
            costLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        end
        
        costLabel.TextSize = ScreenUtils.getTextSize(22)
        billboard.Size = UDim2.new(0, 90, 0, 60)
        guiData.billboard.Enabled = true
    end
end

-- Update individual tubeplot GUI
function PlotGUIService:UpdateTubePlotGUI(guiData, playerMoney, playerRebirths, ownedTubesSet)
    local tubePlotNumber = guiData.tubePlotNumber
    local requiredRebirths = PlotConfig.getTubePlotRebirthRequirement(tubePlotNumber)
    local tubePlotCost = PlotConfig.getTubePlotCost(tubePlotNumber, playerRebirths)
    
    local moneyIcon = guiData.moneyIcon
    local rebirthIcon = guiData.rebirthIcon
    local costLabel = guiData.costLabel
    local tubeLabel = guiData.tubeLabel
    local billboard = guiData.billboard
    
    if ownedTubesSet[tubePlotNumber] then
        -- Owned tubeplot - hide GUI entirely (surface GUI already shows owned status)
        guiData.billboard.Enabled = false
        
    elseif playerRebirths < requiredRebirths then
        -- Show rebirth requirement (only on first that needs higher rebirth)
        if PlotConfig.shouldShowTubePlotRebirthText(tubePlotNumber, playerRebirths) then
            -- Show rebirth icon and text
            moneyIcon.Visible = false
            rebirthIcon.Visible = true
            costLabel.Text = requiredRebirths .. " Needed"
            costLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
            costLabel.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
            costLabel.TextSize = ScreenUtils.getTextSize(24)
            -- Adjust positioning for rebirth text (wider)
            costLabel.Position = UDim2.new(0, 30, 0, 0) -- More space for "Needed" text
            costLabel.Size = UDim2.new(0, 80, 0.5, 0)
            tubeLabel.Visible = true
            billboard.Size = UDim2.new(0, 120, 0, 60)
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
        costLabel.Size = UDim2.new(1, 0, 0.5, 0)
        costLabel.TextXAlignment = Enum.TextXAlignment.Center
        tubeLabel.Visible = true
        billboard.Size = UDim2.new(0, 80, 0, 60)
        guiData.billboard.Enabled = true
        
    else
        -- Show price with money icon - very tight positioning
        moneyIcon.Visible = true
        rebirthIcon.Visible = false
        costLabel.Text = NumberFormatter.format(tubePlotCost)
        costLabel.Position = UDim2.new(0, 35, 0, 0) -- Right next to icon (18px icon + 2px gap + 15px padding)
        costLabel.Size = UDim2.new(0, 50, 0.5, 0)
        tubeLabel.Visible = true
        costLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        if playerMoney >= tubePlotCost then
            -- Can afford (green)
            costLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        else
            -- Can't afford (red)
            costLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        end
        
        costLabel.TextSize = ScreenUtils.getTextSize(22)
        billboard.Size = UDim2.new(0, 90, 0, 60)
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
    for plotNumber = 1, PlotConfig.TOTAL_PLOTS do
        if plotNumber ~= 6 and plotNumber ~= 7 then -- Skip invalid plots
            local plot = playerArea:FindFirstChild("Buttons") and playerArea.Buttons:FindFirstChild("Plot" .. plotNumber)
            if plot then
                self:CreatePlotGUI(playerArea, plot, plotNumber)
            end
        end
    end
    
    -- Create GUIs for tubeplots
    for tubePlotNumber = 1, PlotConfig.TOTAL_TUBEPLOTS do
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
        
        -- Subscribe to Rodux store changes to keep GUIs updated
        -- Subscribing to store changes
        local unsubscribe = store.changed:connect(function(newState, oldState)
            if newState.player then
                -- Always update when player data changes (temporary for debugging)
                -- Store changed, updating GUIs
                self:UpdateAllGUIs()
                
                -- TODO: Add back performance optimization after debugging
                -- local oldPlayer = oldState.player  
                -- if not oldPlayer or 
                --    newState.player.Resources.Money ~= oldPlayer.Resources.Money or
                --    newState.player.Resources.Rebirths ~= oldPlayer.Resources.Rebirths or
                --    -- Need better array comparison for OwnedPlots/OwnedTubes
                --    then
                --     self:UpdateAllGUIs()
                -- end
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