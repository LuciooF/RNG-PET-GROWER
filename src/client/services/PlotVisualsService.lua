local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local PlotConfig = require(ReplicatedStorage.Shared.config.PlotConfig)
local assets = require(ReplicatedStorage.assets)

local PlotVisualsService = {}
PlotVisualsService.__index = PlotVisualsService

local player = Players.LocalPlayer
local connection = nil
local plotGUIs = {} -- Store references to plot GUIs
local lastPlayerData = {} -- Cache player data to avoid unnecessary updates
local touchCooldowns = {} -- Store touch cooldowns per plot
local plotStates = {} -- Track previous plot states to detect purchases
local playerAreaNumber = nil -- Store the player's assigned area number
local areaAssignments = {} -- Store area assignments from server

-- Distance threshold for showing GUIs (in studs)
local GUI_VISIBILITY_DISTANCE = 200

-- Touch cooldown time (in seconds)
local TOUCH_COOLDOWN_TIME = 2

function PlotVisualsService:Initialize()
    
    
    -- Wait for PlayerAreas to be created
    local playerAreas = Workspace:WaitForChild("PlayerAreas", 10)
    if not playerAreas then
        warn("PlotVisualsService: PlayerAreas not found!")
        return
    end
    
    
    -- Wait for player data sync
    local playerDataSync = ReplicatedStorage:WaitForChild("PlayerDataSync", 10)
    if playerDataSync then
        playerDataSync.OnClientEvent:Connect(function(data)
            if data and data.resources then
                lastPlayerData = {
                    money = data.resources.money or 0,
                    rebirths = data.resources.rebirths or 0,
                    boughtPlots = data.boughtPlots or {}
                }
                self:UpdateAllPlots()
            end
        end)
    end
    
    -- Wait for area assignment sync
    local areaAssignmentSync = ReplicatedStorage:WaitForChild("AreaAssignmentSync", 10)
    if areaAssignmentSync then
        areaAssignmentSync.OnClientEvent:Connect(function(assignmentData)
            areaAssignments = assignmentData
            playerAreaNumber = self:GetPlayerAreaNumber()
            self:UpdateAllPlots()
        end)
    end
    
    -- Update plot GUI visibility at a reasonable rate (10 times per second)
    local lastVisibilityUpdate = 0
    local VISIBILITY_UPDATE_RATE = 0.1 -- 10 times per second
    
    connection = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        if currentTime - lastVisibilityUpdate >= VISIBILITY_UPDATE_RATE then
            lastVisibilityUpdate = currentTime
            self:UpdatePlotGUIVisibility()
        end
    end)
    
    -- Set up plot touch handlers (initially)
    self:SetupPlotTouchHandlers()
    
    
    -- Initial update
    self:UpdateAllPlots()
    
end

function PlotVisualsService:GetPlayerAreaNumber()
    -- Find which area the current player is assigned to
    for areaNumber, assignmentData in pairs(areaAssignments) do
        if assignmentData.playerName == player.Name then
            return areaNumber
        end
    end
    return nil -- Player not assigned to any area yet
end

function PlotVisualsService:UpdateAllPlots()
    local playerAreas = Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then 
        print("PlotVisualsService: No PlayerAreas found in UpdateAllPlots")
        return 
    end
    
    -- Only process plots if player has an assigned area
    if not playerAreaNumber then
        return
    end
    
    local plotCount = 0
    
    -- Find the player's assigned area
    local playerArea = playerAreas:FindFirstChild("PlayerArea" .. playerAreaNumber)
    if not playerArea then
        return
    end
    
    local plotsFolder = playerArea:FindFirstChild("Plots")
    if plotsFolder then
        for _, plot in pairs(plotsFolder:GetChildren()) do
            if plot:IsA("Model") then
                self:UpdatePlotVisual(plot)
                plotCount = plotCount + 1
            end
        end
    end
    
    -- Re-setup touch handlers after plot updates (in case plots were converted to models)
    if plotCount > 0 then
        self:SetupPlotTouchHandlers()
    end
end

function PlotVisualsService:UpdatePlotVisual(plot)
    local plotIdValue = plot:FindFirstChild("PlotId")
    if not plotIdValue or not plotIdValue:IsA("IntValue") then
        return
    end
    
    local plotId = plotIdValue.Value
    local plotData = PlotConfig:GetPlotData(plotId)
    if not plotData then
        return
    end
    
    -- Determine if this plot is purchased
    local isPurchased = false
    for _, purchasedId in pairs(lastPlayerData.boughtPlots or {}) do
        if purchasedId == plotId then
            isPurchased = true
            break
        end
    end
    
    -- Get plot state
    local state = PlotConfig:GetPlotState(
        plotId,
        lastPlayerData.rebirths or 0,
        lastPlayerData.money or 0,
        isPurchased
    )
    
    if not state then
        return
    end
    
    
    -- Check if plot was just purchased (state changed to PURCHASED)
    local previousState = plotStates[plotId]
    if previousState and previousState ~= PlotConfig.STATES.PURCHASED and state == PlotConfig.STATES.PURCHASED then
        self:PlayPurchaseAnimation(plot, plotId)
    elseif state == PlotConfig.STATES.PURCHASED and not previousState then
        -- Plot is already purchased when we first see it (player rejoined)
        self:SetPlotToPressedPosition(plot)
    end
    
    -- Store current state for next update
    plotStates[plotId] = state
    
    -- Update plot appearance
    self:UpdatePlotColor(plot, state)
    
    -- Create or update plot GUI
    self:UpdatePlotGUI(plot, plotId, state)
end


function PlotVisualsService:GetPressedPosition(plotPart)
    -- Store original position if we haven't already
    local originalPos = plotPart:GetAttribute("OriginalPosition")
    if not originalPos then
        -- Store the original position as an attribute
        plotPart:SetAttribute("OriginalPosition", plotPart.Position)
        originalPos = plotPart.Position
    end
    
    -- Calculate pressed position (0.5 studs down)
    return originalPos - Vector3.new(0, 0.5, 0)
end

function PlotVisualsService:PlayPurchaseAnimation(plot, plotId)
    local plotPart = plot:FindFirstChild("Plot")
    if not plotPart or not plotPart:IsA("BasePart") then
        return
    end
    
    -- Get or calculate the pressed position
    local pressedPosition = self:GetPressedPosition(plotPart)
    
    
    -- Animate to pressed position and stay there
    local pressDownTween = TweenService:Create(plotPart,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Position = pressedPosition}
    )
    
    pressDownTween:Play()
    pressDownTween.Completed:Connect(function()
        pressDownTween:Destroy()
    end)
end

function PlotVisualsService:SetPlotToPressedPosition(plot)
    local plotPart = plot:FindFirstChild("Plot")
    if not plotPart or not plotPart:IsA("BasePart") then
        return
    end
    
    -- Set to pressed position immediately (for plots already owned when player joins)
    local pressedPosition = self:GetPressedPosition(plotPart)
    plotPart.Position = pressedPosition
end

function PlotVisualsService:UpdatePlotColor(plot, state)
    local color = PlotConfig:GetPlotColor(state)
    local transparency = PlotConfig:GetPlotTransparency(state)
    
    -- Only update the "Plot" part for color/transparency
    local plotPart = plot:FindFirstChild("Plot")
    if plotPart and plotPart:IsA("BasePart") then
        plotPart.Color = color
        plotPart.Transparency = transparency
    else
        -- Fallback: update all parts if no "Plot" part found
        for _, child in pairs(plot:GetChildren()) do
            if child:IsA("BasePart") then
                child.Color = color
                child.Transparency = transparency
            end
        end
    end
end


function PlotVisualsService:UpdatePlotGUI(plot, plotId, state)
    -- Remove existing GUI if it exists
    local existingGUI = plot:FindFirstChild("PlotGUIAnchor")
    if existingGUI then
        existingGUI:Destroy()
    end
    
    -- Get GUI text
    local guiText = PlotConfig:GetPlotGUIText(plotId, state, lastPlayerData.rebirths or 0)
    
    
    -- Don't create GUI if no text to show
    if guiText == "" then
        return
    end
    
    -- Create GUI anchor (invisible part above the plot)
    local guiAnchor = Instance.new("Part")
    guiAnchor.Name = "PlotGUIAnchor"
    guiAnchor.Size = Vector3.new(1, 1, 1)
    guiAnchor.Transparency = 1
    guiAnchor.CanCollide = false
    guiAnchor.Anchored = true
    
    -- Position above the plot (lower)
    local plotCenter = self:GetPlotCenter(plot)
    guiAnchor.Position = plotCenter + Vector3.new(0, 3, 0)
    guiAnchor.Parent = plot
    
    
    -- Create BillboardGui
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "PlotGUI"
    billboardGui.Size = UDim2.new(0, 200, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 0, 0)
    billboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    billboardGui.Enabled = false -- Start disabled, proximity will enable it
    billboardGui.Parent = guiAnchor
    
    -- Check if this is a price display (should show cash icon)
    local shouldShowCashIcon = (state == PlotConfig.STATES.UNLOCKED_CANT_AFFORD or state == PlotConfig.STATES.UNLOCKED_CAN_AFFORD) and guiText ~= ""
    
    if shouldShowCashIcon then
        -- Create frame to hold icon and text
        local contentFrame = Instance.new("Frame")
        contentFrame.Name = "ContentFrame"
        contentFrame.Size = UDim2.new(1, 0, 1, 0)
        contentFrame.Position = UDim2.new(0, 0, 0, 0)
        contentFrame.BackgroundTransparency = 1
        contentFrame.Parent = billboardGui
        
        -- Create layout for horizontal arrangement
        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment = Enum.VerticalAlignment.Center
        layout.Padding = UDim.new(0, 5)
        layout.Parent = contentFrame
        
        -- Create cash icon
        local cashIcon = Instance.new("ImageLabel")
        cashIcon.Name = "CashIcon"
        cashIcon.Size = UDim2.new(0, 24, 0, 24)
        cashIcon.BackgroundTransparency = 1
        cashIcon.Image = assets["vector-icon-pack-2/Currency/Cash/Cash Outline 256.png"] or ""
        cashIcon.ScaleType = Enum.ScaleType.Fit
        cashIcon.ZIndex = 2
        cashIcon.Parent = contentFrame
        
        -- Create text label for price
        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "PlotText"
        textLabel.Size = UDim2.new(0, 0, 1, 0)
        textLabel.AutomaticSize = Enum.AutomaticSize.X
        textLabel.BackgroundTransparency = 1
        textLabel.Text = guiText
        textLabel.TextColor3 = PlotConfig:GetPlotGUIColor(state)
        textLabel.TextSize = 28
        textLabel.TextWrapped = false
        textLabel.Font = Enum.Font.GothamBold
        textLabel.ZIndex = 2
        textLabel.Parent = contentFrame
        
        -- Add black text stroke
        local textStroke = Instance.new("UIStroke")
        textStroke.Color = Color3.fromRGB(0, 0, 0)
        textStroke.Thickness = 2
        textStroke.Transparency = 0
        textStroke.Parent = textLabel
    else
        -- Create regular text label for non-price displays
        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "PlotText"
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.Position = UDim2.new(0, 0, 0, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = guiText
        textLabel.TextColor3 = PlotConfig:GetPlotGUIColor(state)
        textLabel.TextSize = 28
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
    
    -- Store reference
    plotGUIs[plotId] = {
        gui = billboardGui,
        anchor = guiAnchor,
        plot = plot
    }
end


function PlotVisualsService:UpdatePlotGUIVisibility()
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
    
    -- Debug visibility removed for performance (was causing unnecessary calculations)
end

function PlotVisualsService:GetPlotCenter(plot)
    local parts = {}
    
    for _, child in pairs(plot:GetChildren()) do
        if child:IsA("BasePart") then
            table.insert(parts, child)
        end
    end
    
    if #parts == 0 then
        return Vector3.new(0, 0, 0)
    end
    
    local sumPosition = Vector3.new(0, 0, 0)
    for _, part in pairs(parts) do
        sumPosition = sumPosition + part.Position
    end
    
    return sumPosition / #parts
end

function PlotVisualsService:SetupPlotTouchHandlers()
    
    local playerAreas = Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then 
        return 
    end
    
    -- Only process plots if player has an assigned area
    if not playerAreaNumber then
        return
    end
    
    local totalPlots = 0
    
    -- Find the player's assigned area
    local playerArea = playerAreas:FindFirstChild("PlayerArea" .. playerAreaNumber)
    if not playerArea then
        return
    end
    
    local plotsFolder = playerArea:FindFirstChild("Plots")
    if plotsFolder then
        for _, plot in pairs(plotsFolder:GetChildren()) do
            if plot:IsA("Model") then
                self:SetupPlotTouch(plot)
                totalPlots = totalPlots + 1
            end
        end
    end
    
end

function PlotVisualsService:SetupPlotTouch(plot)
    local plotIdValue = plot:FindFirstChild("PlotId")
    if not plotIdValue or not plotIdValue:IsA("IntValue") then
        return
    end
    
    local plotId = plotIdValue.Value
    local partCount = 0
    
    
    -- Set up touch detection for all parts in the plot
    for _, child in pairs(plot:GetChildren()) do
        if child:IsA("BasePart") then
            local connection = child.Touched:Connect(function(hit)
                local humanoid = hit.Parent:FindFirstChild("Humanoid")
                if humanoid and hit.Parent == player.Character then
                    self:HandlePlotTouch(plotId)
                end
            end)
            partCount = partCount + 1
        end
    end
    
    
end

function PlotVisualsService:HandlePlotTouch(plotId)
    -- Check touch cooldown
    local currentTime = tick()
    if touchCooldowns[plotId] and currentTime - touchCooldowns[plotId] < TOUCH_COOLDOWN_TIME then
        -- Still in cooldown, ignore this touch
        return
    end
    
    local plotData = PlotConfig:GetPlotData(plotId)
    if not plotData then
        return
    end
    
    -- Check if player already owns this plot
    for _, ownedPlotId in pairs(lastPlayerData.boughtPlots or {}) do
        if ownedPlotId == plotId then
            -- Set cooldown even for owned plots to prevent spam
            touchCooldowns[plotId] = currentTime
            return
        end
    end
    
    -- Get current plot state
    local state = PlotConfig:GetPlotState(
        plotId,
        lastPlayerData.rebirths or 0,
        lastPlayerData.money or 0,
        false -- not purchased since we checked above
    )
    
    -- Only allow purchase if player can afford it
    if state == PlotConfig.STATES.UNLOCKED_CAN_AFFORD then
        
        -- Set cooldown to prevent rapid successive purchases
        touchCooldowns[plotId] = currentTime
        
        -- Send purchase request to server
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local buyPlotRemote = remotes:FindFirstChild("BuyPlot")
            if buyPlotRemote then
                buyPlotRemote:FireServer(plotId)
            end
        end
    else
        -- Set cooldown for failed attempts too
        touchCooldowns[plotId] = currentTime
    end
end

function PlotVisualsService:Cleanup()
    if connection then
        connection:Disconnect()
        connection = nil
    end
    
    -- Clean up all GUIs
    for plotId, guiData in pairs(plotGUIs) do
        if guiData.gui then
            guiData.gui:Destroy()
        end
        if guiData.anchor then
            guiData.anchor:Destroy()
        end
    end
    
    plotGUIs = {}
end

return PlotVisualsService