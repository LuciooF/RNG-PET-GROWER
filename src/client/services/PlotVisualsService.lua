local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local PlotConfig = require(ReplicatedStorage.Shared.config.PlotConfig)

-- Import GUI controller
local PlotGUIController = require(script.Parent.controllers.PlotGUIController)

local PlotVisualsService = {}
PlotVisualsService.__index = PlotVisualsService

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
                local newPlayerData = {
                    money = data.resources.money or 0,
                    rebirths = data.resources.rebirths or 0,
                    boughtPlots = data.boughtPlots or {}
                }
                
                -- Only update if relevant data actually changed
                if self:ShouldUpdatePlots(lastPlayerData, newPlayerData) then
                    lastPlayerData = newPlayerData
                    -- Force immediate update for plot purchases
                    self:UpdateAllPlots(true)
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
            PlotGUIController.updateGUIVisibility()
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

function PlotVisualsService:ShouldUpdatePlots(oldData, newData)
    -- Only update if data that affects plot GUIs actually changed
    if not oldData then return true end -- First time
    
    -- Check if money changed (affects purchase buttons)
    if oldData.money ~= newData.money then return true end
    
    -- Check if rebirths changed (affects plot visibility and requirements)
    if oldData.rebirths ~= newData.rebirths then return true end
    
    -- Check if bought plots changed (affects plot states)
    local oldPlots = oldData.boughtPlots or {}
    local newPlots = newData.boughtPlots or {}
    
    if #oldPlots ~= #newPlots then return true end
    
    -- Compare plot arrays (simple comparison since they're usually small)
    for i, plotId in ipairs(oldPlots) do
        if newPlots[i] ~= plotId then return true end
    end
    
    return false -- No relevant changes
end

function PlotVisualsService:UpdateAllPlots(forceUpdate)
    -- Throttle updates to prevent excessive calls (unless forced)
    local currentTime = tick()
    if not forceUpdate and currentTime - lastUpdateTime < UPDATE_THROTTLE then
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
    
    -- Check if plot should be visible based on player's rebirths
    local shouldBeVisible = PlotConfig:ShouldPlotBeVisible(plotId, lastPlayerData.rebirths or 0)
    
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
    
    -- Update plot colors based on state
    self:UpdatePlotColor(plot, state)
    
    -- Create or update plot GUI using controller
    PlotGUIController.updatePlotGUI(plot, plotId, state, lastPlayerData)
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
    local plotPart = plot:FindFirstChild("Plot")
    if not plotPart or not plotPart:IsA("BasePart") then
        return
    end
    
    local plotIdValue = plot:FindFirstChild("PlotId")
    if not plotIdValue or not plotIdValue:IsA("IntValue") then
        return
    end
    
    local plotId = plotIdValue.Value
    
    -- Use same color logic as cylinders for consistency
    local CYLINDER_COLORS = {
        [1] = Color3.fromRGB(139, 69, 19), -- Brown (Basic)
        [2] = Color3.fromRGB(169, 169, 169), -- Silver (Advanced)
        [3] = Color3.fromRGB(255, 215, 0), -- Gold (Premium)
        [4] = Color3.fromRGB(138, 43, 226), -- Purple (Elite)
        [5] = Color3.fromRGB(255, 20, 147) -- Pink (Master/Legendary)
    }
    
    -- Calculate dynamic rarity exactly like cylinders do
    local dynamicRarity = PlotConfig:GetDynamicRarity(plotId, lastPlayerData.rebirths or 0)
    local colorIndex = ((dynamicRarity - 1) % #CYLINDER_COLORS) + 1
    local rarityColor = CYLINDER_COLORS[colorIndex] or CYLINDER_COLORS[1]
    
    -- Helper function to darken a color
    local function darkenColor(color, factor)
        factor = factor or 0.7 -- Default darkening factor
        return Color3.fromRGB(
            math.floor(color.R * 255 * factor),
            math.floor(color.G * 255 * factor),
            math.floor(color.B * 255 * factor)
        )
    end
    
    -- Color based on state using same colors as cylinders
    if state == PlotConfig.STATES.UNLOCKED_CANT_AFFORD then
        -- Red when player can't afford it
        plotPart.Color = Color3.fromRGB(255, 0, 0)
        plotPart.Material = Enum.Material.Plastic
        plotPart.Transparency = 0
    elseif state == PlotConfig.STATES.UNLOCKED_CAN_AFFORD then
        -- Cylinder rarity color but slightly darker when player can afford it
        plotPart.Color = darkenColor(rarityColor, 0.7)
        plotPart.Material = Enum.Material.Plastic
        plotPart.Transparency = 0
    elseif state == PlotConfig.STATES.UNLOCKS_NEXT_REBIRTH then
        -- Black when unlocks next rebirth (same as before)
        plotPart.Color = Color3.fromRGB(0, 0, 0)
        plotPart.Material = Enum.Material.Plastic
        plotPart.Transparency = 0
    elseif state == PlotConfig.STATES.UNLOCKS_LATER then
        -- Black when locked for later rebirths (same as before)
        plotPart.Color = Color3.fromRGB(0, 0, 0)
        plotPart.Material = Enum.Material.Plastic
        plotPart.Transparency = 0.5
    elseif state == PlotConfig.STATES.PURCHASED then
        -- Actual cylinder rarity color with neon material when player owns it
        plotPart.Color = rarityColor
        plotPart.Material = Enum.Material.Neon
        plotPart.Transparency = 0
    else
        -- Default color
        plotPart.Color = Color3.fromRGB(255, 255, 255)
        plotPart.Material = Enum.Material.Plastic
        plotPart.Transparency = 0
    end
end


-- GUI management has been moved to PlotGUIController for better separation of concerns
-- PlotVisualsService now focuses on plot state management and visual updates only

function PlotVisualsService:GetPlotCenter(plot)
    -- Delegate to PlotGUIController to avoid code duplication
    return PlotGUIController.getPlotCenter(plot)
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
    
    -- Clean up all GUIs through controller
    PlotGUIController.cleanup()
end

return PlotVisualsService