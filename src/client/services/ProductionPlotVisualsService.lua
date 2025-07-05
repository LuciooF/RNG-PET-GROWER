local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local ProductionPlotConfig = require(ReplicatedStorage.Shared.config.ProductionPlotConfig)
local assets = require(ReplicatedStorage.assets)

-- Import GUI controller (reuse the same one)
local PlotGUIController = require(script.Parent.controllers.PlotGUIController)

local ProductionPlotVisualsService = {}
ProductionPlotVisualsService.__index = ProductionPlotVisualsService

local player = Players.LocalPlayer
local connection = nil
local lastPlayerData = {} -- Cache player data to avoid unnecessary updates
local touchCooldowns = {} -- Store touch cooldowns per plot
local plotStates = {} -- Track previous plot states to detect purchases
local playerAreaNumber = nil -- Store the player's assigned area number
local areaAssignments = {} -- Store area assignments from server
local lastUpdateTime = 0 -- Throttle updates
local UPDATE_THROTTLE = 0.1 -- Maximum 10 updates per second

-- Touch cooldown time (in seconds)
local TOUCH_COOLDOWN_TIME = 2

function ProductionPlotVisualsService:Initialize()
    
    -- Wait for PlayerAreas to be created
    local playerAreas = Workspace:WaitForChild("PlayerAreas", 10)
    if not playerAreas then
        warn("ProductionPlotVisualsService: PlayerAreas not found!")
        return
    end
    
    -- Wait for player data sync
    local playerDataSync = ReplicatedStorage:WaitForChild("PlayerDataSync", 10)
    if playerDataSync then
        playerDataSync.OnClientEvent:Connect(function(data)
            if data and data.resources then
                local newPlayerData = {
                    money = data.resources.money or 0,
                    rebirths = data.resources.rebirths or 0,
                    boughtProductionPlots = data.boughtProductionPlots or {}
                }
                
                -- Only update if relevant data actually changed
                if self:ShouldUpdateProductionPlots(lastPlayerData, newPlayerData) then
                    lastPlayerData = newPlayerData
                    self:UpdateAllProductionPlots()
                end
            end
        end)
    end
    
    -- Wait for area assignment sync
    local areaAssignmentSync = ReplicatedStorage:WaitForChild("AreaAssignmentSync", 10)
    if areaAssignmentSync then
        areaAssignmentSync.OnClientEvent:Connect(function(assignmentData)
            areaAssignments = assignmentData
            playerAreaNumber = self:GetPlayerAreaNumber()
            self:UpdateAllProductionPlots()
        end)
    end
    
    -- Update plot GUI visibility at a reasonable rate (10 times per second)
    local lastVisibilityUpdate = 0
    local VISIBILITY_UPDATE_RATE = 0.1 -- 10 times per second
    
    connection = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        if currentTime - lastVisibilityUpdate >= VISIBILITY_UPDATE_RATE then
            lastVisibilityUpdate = currentTime
            PlotGUIController.updateGUIVisibility()
        end
    end)
    
    -- Set up plot touch handlers (initially)
    self:SetupProductionPlotTouchHandlers()
    
    -- Initial update
    self:UpdateAllProductionPlots()
end

function ProductionPlotVisualsService:GetPlayerAreaNumber()
    -- Find which area the current player is assigned to
    for areaNumber, assignmentData in pairs(areaAssignments) do
        if assignmentData.playerName == player.Name then
            return areaNumber
        end
    end
    return nil -- Player not assigned to any area yet
end

function ProductionPlotVisualsService:ShouldUpdateProductionPlots(oldData, newData)
    -- Only update if data that affects production plot GUIs actually changed
    if not oldData then return true end -- First time
    
    -- Check if money changed (affects purchase buttons)
    if oldData.money ~= newData.money then return true end
    
    -- Check if rebirths changed (affects plot visibility and requirements)
    if oldData.rebirths ~= newData.rebirths then return true end
    
    -- Check if bought production plots changed (affects plot states)
    local oldPlots = oldData.boughtProductionPlots or {}
    local newPlots = newData.boughtProductionPlots or {}
    
    if #oldPlots ~= #newPlots then return true end
    
    -- Compare plot arrays (simple comparison since they're usually small)
    for i, plotId in ipairs(oldPlots) do
        if newPlots[i] ~= plotId then return true end
    end
    
    return false -- No relevant changes
end

function ProductionPlotVisualsService:UpdateAllProductionPlots()
    -- Throttle updates to prevent excessive calls
    local currentTime = tick()
    if currentTime - lastUpdateTime < UPDATE_THROTTLE then
        return -- Skip this update, too soon
    end
    lastUpdateTime = currentTime
    
    local playerAreas = Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then 
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
    
    local productionPlotsFolder = playerArea:FindFirstChild("ProductionPlots")
    if productionPlotsFolder then
        for _, plot in pairs(productionPlotsFolder:GetChildren()) do
            if plot:IsA("Model") then
                self:UpdateProductionPlotVisual(plot)
                plotCount = plotCount + 1
            end
        end
    end
    
    -- Re-setup touch handlers after plot updates
    if plotCount > 0 then
        self:SetupProductionPlotTouchHandlers()
    end
end

function ProductionPlotVisualsService:UpdateProductionPlotVisual(plot)
    local plotIdValue = plot:FindFirstChild("PlotId")
    if not plotIdValue or not plotIdValue:IsA("IntValue") then
        return
    end
    
    local plotId = plotIdValue.Value
    local plotData = ProductionPlotConfig:GetPlotData(plotId)
    if not plotData then
        return
    end
    
    -- Check if plot should be visible based on player's rebirths
    local shouldBeVisible = ProductionPlotConfig:ShouldPlotBeVisible(plotId, lastPlayerData.rebirths or 0)
    
    -- Hide/show the entire plot model based on visibility
    if plot:IsA("Model") then
        for _, child in pairs(plot:GetDescendants()) do
            if child:IsA("BasePart") then
                child.Transparency = shouldBeVisible and 0 or 1
                child.CanCollide = shouldBeVisible
            end
        end
    end
    
    -- If plot shouldn't be visible, don't create GUI or handle interactions
    if not shouldBeVisible then
        -- Remove any existing GUI
        local existingGUI = plot:FindFirstChild("PlotGUIAnchor")
        if existingGUI then
            existingGUI:Destroy()
        end
        return
    end
    
    -- Determine if this plot is purchased
    local isPurchased = false
    for _, purchasedId in pairs(lastPlayerData.boughtProductionPlots or {}) do
        if purchasedId == plotId then
            isPurchased = true
            break
        end
    end
    
    -- Get plot state
    local state = ProductionPlotConfig:GetPlotState(
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
    if previousState and previousState ~= ProductionPlotConfig.STATES.PURCHASED and state == ProductionPlotConfig.STATES.PURCHASED then
        self:PlayPurchaseAnimation(plot, plotId)
    elseif state == ProductionPlotConfig.STATES.PURCHASED and not previousState then
        -- Plot is already purchased when we first see it (player rejoined)
        self:SetPlotToPressedPosition(plot)
    end
    
    -- Store current state for next update
    plotStates[plotId] = state
    
    -- Update plot colors based on state
    self:UpdatePlotColor(plot, state)
    
    -- Create or update plot GUI using controller (pass true for production plot)
    PlotGUIController.updatePlotGUI(plot, plotId, state, lastPlayerData, true)
end

function ProductionPlotVisualsService:GetPressedPosition(plotPart)
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

function ProductionPlotVisualsService:PlayPurchaseAnimation(plot, plotId)
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

function ProductionPlotVisualsService:SetPlotToPressedPosition(plot)
    local plotPart = plot:FindFirstChild("Plot")
    if not plotPart or not plotPart:IsA("BasePart") then
        return
    end
    
    -- Set to pressed position immediately (for plots already owned when player joins)
    local pressedPosition = self:GetPressedPosition(plotPart)
    plotPart.Position = pressedPosition
end

function ProductionPlotVisualsService:UpdatePlotColor(plot, state)
    local plotPart = plot:FindFirstChild("Plot")
    if not plotPart or not plotPart:IsA("BasePart") then
        return
    end
    
    -- Color based on state
    if state == ProductionPlotConfig.STATES.UNLOCKED_CANT_AFFORD then
        plotPart.Color = Color3.fromRGB(255, 0, 0) -- Red (can't afford)
        plotPart.Transparency = 0
    elseif state == ProductionPlotConfig.STATES.UNLOCKED_CAN_AFFORD then
        plotPart.Color = Color3.fromRGB(0, 255, 0) -- Green (can afford)
        plotPart.Transparency = 0
    elseif state == ProductionPlotConfig.STATES.UNLOCKS_NEXT_REBIRTH then
        plotPart.Color = Color3.fromRGB(0, 0, 0) -- Black (needs rebirth)
        plotPart.Transparency = 0
    elseif state == ProductionPlotConfig.STATES.UNLOCKS_LATER then
        plotPart.Color = Color3.fromRGB(0, 0, 0) -- Black (locked for later rebirths)
        plotPart.Transparency = 0.5
    elseif state == ProductionPlotConfig.STATES.PURCHASED then
        plotPart.Color = Color3.fromRGB(255, 255, 255) -- White (purchased)
        plotPart.Transparency = 0
    else
        -- Default color
        plotPart.Color = Color3.fromRGB(255, 255, 255) -- White
        plotPart.Transparency = 0
    end
end

function ProductionPlotVisualsService:SetupProductionPlotTouchHandlers()
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
    
    local productionPlotsFolder = playerArea:FindFirstChild("ProductionPlots")
    if productionPlotsFolder then
        for _, plot in pairs(productionPlotsFolder:GetChildren()) do
            if plot:IsA("Model") then
                self:SetupProductionPlotTouch(plot)
                totalPlots = totalPlots + 1
            end
        end
    end
end

function ProductionPlotVisualsService:SetupProductionPlotTouch(plot)
    local plotIdValue = plot:FindFirstChild("PlotId")
    if not plotIdValue or not plotIdValue:IsA("IntValue") then
        return
    end
    
    local plotId = plotIdValue.Value
    
    -- Set up touch detection for all parts in the plot
    for _, child in pairs(plot:GetChildren()) do
        if child:IsA("BasePart") then
            local connection = child.Touched:Connect(function(hit)
                local humanoid = hit.Parent:FindFirstChild("Humanoid")
                if humanoid and hit.Parent == player.Character then
                    self:HandleProductionPlotTouch(plotId)
                end
            end)
        end
    end
end

function ProductionPlotVisualsService:HandleProductionPlotTouch(plotId)
    -- Check touch cooldown
    local currentTime = tick()
    if touchCooldowns[plotId] and currentTime - touchCooldowns[plotId] < TOUCH_COOLDOWN_TIME then
        -- Still in cooldown, ignore this touch
        return
    end
    
    local plotData = ProductionPlotConfig:GetPlotData(plotId)
    if not plotData then
        return
    end
    
    -- Check if player already owns this plot
    for _, ownedPlotId in pairs(lastPlayerData.boughtProductionPlots or {}) do
        if ownedPlotId == plotId then
            -- Set cooldown even for owned plots to prevent spam
            touchCooldowns[plotId] = currentTime
            return
        end
    end
    
    -- Get current plot state
    local state = ProductionPlotConfig:GetPlotState(
        plotId,
        lastPlayerData.rebirths or 0,
        lastPlayerData.money or 0,
        false -- not purchased since we checked above
    )
    
    -- Only allow purchase if player can afford it
    if state == ProductionPlotConfig.STATES.UNLOCKED_CAN_AFFORD then
        
        -- Set cooldown to prevent rapid successive purchases
        touchCooldowns[plotId] = currentTime
        
        -- Send purchase request to server
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local buyProductionPlotRemote = remotes:FindFirstChild("BuyProductionPlot")
            if buyProductionPlotRemote then
                buyProductionPlotRemote:FireServer(plotId)
            end
        end
    else
        -- Set cooldown for failed attempts too
        touchCooldowns[plotId] = currentTime
    end
end

function ProductionPlotVisualsService:Cleanup()
    if connection then
        connection:Disconnect()
        connection = nil
    end
end

return ProductionPlotVisualsService