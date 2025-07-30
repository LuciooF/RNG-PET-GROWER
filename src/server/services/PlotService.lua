-- PlotService - Handles plot purchasing and management
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local DataService = require(script.Parent.DataService)
local StateService = require(script.Parent.StateService)

local PlotService = {}
PlotService.__index = PlotService

-- Configuration
local PLOT_BASE_COST = 10
local TOTAL_PLOTS = 35
local TUBEPLOT_BASE_COST = 20
local TOTAL_TUBEPLOTS = 10
local UI_VISIBILITY_DISTANCE = 50 -- Distance to show plot UIs

-- Level and door mapping
local LEVEL_CONFIG = {
    [1] = {startPlot = 1, endPlot = 5, doors = 5},   -- Level 1: Plots 1-5, Doors 1-5
    [2] = {startPlot = 8, endPlot = 14, doors = 7},  -- Level 2: Plots 8-14, Doors 1-7 (skip 6,7)
    [3] = {startPlot = 15, endPlot = 21, doors = 7}, -- Level 3: Plots 15-21, Doors 1-7
    [4] = {startPlot = 22, endPlot = 28, doors = 7}, -- Level 4: Plots 22-28, Doors 1-7
    [5] = {startPlot = 29, endPlot = 35, doors = 7}  -- Level 5: Plots 29-35, Doors 1-7
}

-- Store plot connections for cleanup
local plotConnections = {}

-- Store doors that are spawning pets
local spawningDoors = {}

-- Store pet ball count per area
local areaPetBallCounts = {}
local MAX_PET_BALLS_PER_AREA = 100


-- Helper functions for rebirth requirements
local function isMiddlePlotOfRow(plotNumber)
    -- Check if this plot is the middle plot of its row
    -- Level 2 (8-14): middle = 11
    -- Level 3 (15-21): middle = 18
    -- Level 4 (22-28): middle = 25
    -- Level 5 (29-35): middle = 32
    return plotNumber == 11 or plotNumber == 18 or plotNumber == 25 or plotNumber == 32
end

local function getTubePlotRebirthRequirement(tubePlotNumber)
    -- TubePlot 1: 0 rebirths
    -- TubePlot 2: 1 rebirth
    -- TubePlot 3: 2 rebirths
    -- etc.
    return tubePlotNumber - 1
end

local function shouldShowTubePlotRebirthText(tubePlotNumber, playerRebirths)
    -- For tubeplots, only show rebirth requirement on the first tubeplot that needs higher rebirth
    -- This way we don't spam the same message across multiple tubeplots
    local requiredRebirths = getTubePlotRebirthRequirement(tubePlotNumber)
    
    -- Only show on the first tubeplot that the player can't access
    if playerRebirths < requiredRebirths then
        -- Check if this is the first inaccessible tubeplot
        for i = 1, tubePlotNumber - 1 do
            local prevRequired = getTubePlotRebirthRequirement(i)
            if playerRebirths < prevRequired then
                return false -- Not the first one
            end
        end
        return true -- This is the first inaccessible one
    end
    return false
end

local function getPlotRebirthRequirement(plotNumber)
    -- Plots 1-5: 0 rebirths
    -- Plots 8-14: 1 rebirth
    -- Plots 15-21: 2 rebirths
    -- Plots 22-28: 3 rebirths
    -- Plots 29-35: 4 rebirths
    if plotNumber >= 1 and plotNumber <= 5 then
        return 0
    elseif plotNumber >= 8 and plotNumber <= 14 then
        return 1
    elseif plotNumber >= 15 and plotNumber <= 21 then
        return 2
    elseif plotNumber >= 22 and plotNumber <= 28 then
        return 3
    elseif plotNumber >= 29 and plotNumber <= 35 then
        return 4
    else
        return 999 -- Invalid plot numbers (6, 7)
    end
end

function PlotService:SetupCollisionGroups()
    local PhysicsService = game:GetService("PhysicsService")
    local CollectionService = game:GetService("CollectionService")
    local Players = game:GetService("Players")
    
    -- Create collision groups if they don't exist
    pcall(function()
        PhysicsService:RegisterCollisionGroup("PetBalls")
        PhysicsService:RegisterCollisionGroup("PetBallBoundaries") 
        PhysicsService:RegisterCollisionGroup("Players")
    end)
    
    -- Configure collision rules
    PhysicsService:CollisionGroupSetCollidable("PetBalls", "PetBallBoundaries", true)  -- Pet balls collide with boundaries
    PhysicsService:CollisionGroupSetCollidable("Players", "PetBallBoundaries", false) -- Players pass through boundaries
    
    -- Set up all existing boundary parts with the tag
    local boundaryParts = CollectionService:GetTagged("PetBallBoundary") 
    
    for _, boundaryPart in pairs(boundaryParts) do
        boundaryPart.CanCollide = true      -- Must be true for collision groups to work
        boundaryPart.Transparency = 1       -- Invisible
        boundaryPart.CanTouch = true        -- Enable touch detection
        boundaryPart.CollisionGroup = "PetBallBoundaries"
    end
    
    -- Listen for new boundary parts being tagged
    CollectionService:GetInstanceAddedSignal("PetBallBoundary"):Connect(function(part)
        part.CanCollide = true
        part.Transparency = 1
        part.CanTouch = true
        part.CollisionGroup = "PetBallBoundaries"
    end)
    
    -- Set up player collision groups for existing players
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character then
            self:SetPlayerCollisionGroup(player.Character)
        end
    end
    
    -- Set up collision groups for new players
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            self:SetPlayerCollisionGroup(character)
        end)
    end)
    
    -- Handle existing players who get new characters
    for _, player in pairs(Players:GetPlayers()) do
        player.CharacterAdded:Connect(function(character)
            self:SetPlayerCollisionGroup(character)
        end)
    end
end

function PlotService:SetPlayerCollisionGroup(character)
    -- Wait for character to fully load, then set collision groups
    task.spawn(function()
        -- Wait for HumanoidRootPart to ensure character is fully loaded
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
        if not humanoidRootPart then
            return
        end
        
        -- Set all character parts to Players collision group
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") then
                part.CollisionGroup = "Players"
            end
        end
        
        -- Handle new parts added to character
        character.ChildAdded:Connect(function(child)
            if child:IsA("BasePart") then
                child.CollisionGroup = "Players"
            end
        end)
    end)
end

function PlotService:Initialize()
    -- Set up collision groups for pet ball boundaries
    self:SetupCollisionGroups()
    
    -- Set up plot purchasing for all existing areas
    local playerAreas = Workspace:WaitForChild("PlayerAreas", 10)
    if playerAreas then
        for _, area in pairs(playerAreas:GetChildren()) do
            self:SetupAreaPlots(area)
        end
        
        -- Handle new areas being added
        playerAreas.ChildAdded:Connect(function(area)
            self:SetupAreaPlots(area)
        end)
        
        -- Start proximity checking for UI visibility
        self:StartProximityChecking()
    end
end

function PlotService:SetupAreaPlots(area)
    local buttonsFolder = area:FindFirstChild("Buttons")
    if not buttonsFolder then
        warn("PlotService: No Buttons folder found in " .. area.Name)
        return
    end
    
    -- Skip Surface GUI creation during initialization - will be created when player is assigned
    -- self:AddDoorSurfaceGuis(area) -- DEFERRED FOR PERFORMANCE
    
    -- Set up touch detection for each plot
    for i = 1, TOTAL_PLOTS do
        local plotName = "Plot" .. i
        local plot = buttonsFolder:FindFirstChild(plotName)
        
        if plot then
            self:SetupPlotPurchasing(area, plot, i)
            
            -- Only create UI for plots that players can potentially see (rebirth level 0-1 initially)
            local plotRebirthRequirement = getPlotRebirthRequirement(i)
            if plotRebirthRequirement <= 1 then -- Show plots for rebirth 0 and 1 initially
                self:CreatePlotUI(area, plot, i)
                
                -- Initially hide UI (proximity will show them)
                local uiPart = area:FindFirstChild("PlotUI_" .. i)
                if uiPart then
                    uiPart.Transparency = 1
                    local billboard = uiPart:FindFirstChild("PlotBillboard")
                    if billboard then
                        billboard.Enabled = false
                    end
                end
            end
        end
    end
    
    -- Set up touch detection for each TubePlot
    for i = 1, TOTAL_TUBEPLOTS do
        local tubePlotName = "TubePlot" .. i
        local tubePlot = buttonsFolder:FindFirstChild(tubePlotName)
        
        if tubePlot then
            self:SetupTubePlotPurchasing(area, tubePlot, i)
            
            -- Only create UI for tubeplots that players can potentially see (rebirth level 0-1 initially)
            local tubePlotRebirthRequirement = getTubePlotRebirthRequirement(i)
            if tubePlotRebirthRequirement <= 1 then -- Show tubeplots for rebirth 0 and 1 initially
                self:CreateTubePlotUI(area, tubePlot, i)
                
                -- Initially hide UI (proximity will show them)
                local uiPart = area:FindFirstChild("TubePlotUI_" .. i)
                if uiPart then
                    uiPart.Transparency = 1
                    local billboard = uiPart:FindFirstChild("TubePlotBillboard")
                    if billboard then
                        billboard.Enabled = false
                    end
                end
            end
        end
    end
    
    -- Set up SendHeaven button
    self:SetupSendHeavenButton(area)
    
    -- Hide UI for plots that players already own and initialize door colors
    self:UpdateAreaPlotUIs(area)
    self:UpdateAreaTubePlotUIs(area)
    -- Hide plots/tubeplots based on rebirth visibility
    self:UpdatePlotVisibility(area)
    -- First color all doors red (locked state)
    self:ColorAllDoorsInArea(area, Color3.fromRGB(255, 0, 0))
    -- First hide all tubes (locked state)
    self:HideAllTubesInArea(area)
    -- Then color owned doors green
    self:InitializeAreaDoors(area)
    -- Then show owned tubes
    self:InitializeAreaTubes(area)
    -- Initialize counter GUI
    self:UpdateCounterGUI(area.Name, 0)
    
    -- Initialize processing counter with 0 when area is set up
    self:UpdateProcessingCounter(area.Name, 0)
    
    -- Update plot colors and GUIs for the assigned player
    local AreaService = require(script.Parent.AreaService)
    local areaNumber = tonumber(area.Name:match("PlayerArea(%d+)"))
    if areaNumber then
        -- Find the player assigned to this area
        for _, player in pairs(Players:GetPlayers()) do
            local playerArea = AreaService:GetPlayerAssignedArea(player)
            if playerArea == areaNumber then
                self:UpdatePlotGUIs(area, player)
                self:UpdatePlotColors(area, player) -- Add "Purchased" SurfaceGuis for owned plots
                self:UpdatePlotVisibility(area, player)
                break
            end
        end
    end
end


function PlotService:SetupPlotPurchasing(area, plot, plotNumber)
    -- Find the assigned player for this area
    local areaNumber = tonumber(area.Name:match("PlayerArea(%d+)"))
    if not areaNumber then
        return
    end
    
    -- Set up touch detection
    local function onTouch(hit)
        local humanoid = hit.Parent:FindFirstChild("Humanoid")
        if not humanoid then
            return
        end
        
        local player = Players:GetPlayerFromCharacter(hit.Parent)
        if not player then
            return
        end
        
        -- Check if player owns this area
        if not self:PlayerOwnsArea(player, areaNumber) then
            return
        end
        
        -- Attempt to purchase plot
        self:AttemptPlotPurchase(player, plotNumber)
    end
    
    -- Connect to all parts in the plot (in case it's a model with multiple parts)
    if plot:IsA("Model") then
        for _, part in pairs(plot:GetDescendants()) do
            if part:IsA("BasePart") then
                local connection = part.Touched:Connect(onTouch)
                table.insert(plotConnections, connection)
            end
        end
    elseif plot:IsA("BasePart") then
        local connection = plot.Touched:Connect(onTouch)
        table.insert(plotConnections, connection)
    end
end

function PlotService:SetupTubePlotPurchasing(area, tubePlot, tubePlotNumber)
    -- Find the assigned player for this area
    local areaNumber = tonumber(area.Name:match("PlayerArea(%d+)"))
    if not areaNumber then
        return
    end
    
    -- Set up touch detection
    local function onTouch(hit)
        local humanoid = hit.Parent:FindFirstChild("Humanoid")
        if not humanoid then
            return
        end
        
        local player = Players:GetPlayerFromCharacter(hit.Parent)
        if not player then
            return
        end
        
        -- Check if player owns this area
        if not self:PlayerOwnsArea(player, areaNumber) then
            return
        end
        
        -- Attempt to purchase TubePlot
        self:AttemptTubePlotPurchase(player, tubePlotNumber)
    end
    
    -- Connect to all parts in the TubePlot (in case it's a model with multiple parts)
    if tubePlot:IsA("Model") then
        for _, part in pairs(tubePlot:GetDescendants()) do
            if part:IsA("BasePart") then
                local connection = part.Touched:Connect(onTouch)
                table.insert(plotConnections, connection)
            end
        end
    elseif tubePlot:IsA("BasePart") then
        local connection = tubePlot.Touched:Connect(onTouch)
        table.insert(plotConnections, connection)
    end
end

function PlotService:SetupSendHeavenButton(area)
    -- Find the SendHeaven button
    local buttonsFolder = area:FindFirstChild("Buttons")
    if not buttonsFolder then
        return
    end
    
    local sendHeavenButton = buttonsFolder:FindFirstChild("SendHeaven")
    if not sendHeavenButton then
        return
    end
    
    -- Find the assigned player for this area
    local areaNumber = tonumber(area.Name:match("PlayerArea(%d+)"))
    if not areaNumber then
        return
    end
    
    -- Set up touch detection
    local function onTouch(hit)
        local humanoid = hit.Parent:FindFirstChild("Humanoid")
        if not humanoid then
            return
        end
        
        local player = Players:GetPlayerFromCharacter(hit.Parent)
        if not player then
            return
        end
        
        -- Check if player owns this area
        if not self:PlayerOwnsArea(player, areaNumber) then
            return
        end
        
        -- Start heaven processing
        local PetService = require(script.Parent.PetService)
        PetService:StartHeavenProcessing(player)
    end
    
    -- Connect to all parts in the SendHeaven button
    if sendHeavenButton:IsA("Model") then
        for _, part in pairs(sendHeavenButton:GetDescendants()) do
            if part:IsA("BasePart") then
                local connection = part.Touched:Connect(onTouch)
                table.insert(plotConnections, connection)
            end
        end
    elseif sendHeavenButton:IsA("BasePart") then
        local connection = sendHeavenButton.Touched:Connect(onTouch)
        table.insert(plotConnections, connection)
    end
end

function PlotService:CreatePlotUI(area, plot, plotNumber)
    -- Create UI part above the plot
    local uiPart = Instance.new("Part")
    uiPart.Name = "PlotUI_" .. plotNumber
    uiPart.Size = Vector3.new(4, 0.1, 4)
    uiPart.Transparency = 1
    uiPart.CanCollide = false
    uiPart.Anchored = true
    
    -- Position below the plot
    local plotPosition
    if plot:IsA("Model") then
        local cframe, size = plot:GetBoundingBox()
        plotPosition = cframe.Position
    else
        plotPosition = plot.Position
    end
    uiPart.Position = plotPosition + Vector3.new(0, 2, 0)
    uiPart.Parent = area
    
    -- Create BillboardGui
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PlotBillboard"
    billboard.Size = UDim2.new(0, 150, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 0, 0)
    billboard.MaxDistance = 100 -- Much further visibility for camera angles
    billboard.Parent = uiPart
    
    -- Create cost label
    local costLabel = Instance.new("TextLabel")
    costLabel.Name = "CostLabel"
    costLabel.Size = UDim2.new(1, 0, 1, 0)
    costLabel.BackgroundTransparency = 1
    costLabel.BorderSizePixel = 0
    costLabel.Font = Enum.Font.GothamBold
    costLabel.TextSize = 24
    costLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    costLabel.TextStrokeTransparency = 0
    costLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    costLabel.TextXAlignment = Enum.TextXAlignment.Center
    costLabel.TextYAlignment = Enum.TextYAlignment.Center
    local plotCost = self:GetPlotCost(plotNumber)
    costLabel.Text = plotCost == 0 and "FREE" or ("$" .. plotCost)
    costLabel.Parent = billboard
end

function PlotService:CreateTubePlotUI(area, tubePlot, tubePlotNumber)
    -- Create UI part above the TubePlot
    local uiPart = Instance.new("Part")
    uiPart.Name = "TubePlotUI_" .. tubePlotNumber
    uiPart.Size = Vector3.new(4, 0.1, 4)
    uiPart.Transparency = 1
    uiPart.CanCollide = false
    uiPart.Anchored = true
    
    -- Position below the TubePlot
    local tubePlotPosition
    if tubePlot:IsA("Model") then
        local cframe, size = tubePlot:GetBoundingBox()
        tubePlotPosition = cframe.Position
    else
        tubePlotPosition = tubePlot.Position
    end
    uiPart.Position = tubePlotPosition + Vector3.new(0, 2, 0)
    uiPart.Parent = area
    
    -- Create BillboardGui
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "TubePlotBillboard"
    billboard.Size = UDim2.new(0, 150, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 0, 0)
    billboard.MaxDistance = 100 -- Much further visibility for camera angles
    billboard.Parent = uiPart
    
    -- Create cost label
    local costLabel = Instance.new("TextLabel")
    costLabel.Name = "CostLabel"
    costLabel.Size = UDim2.new(1, 0, 1, 0)
    costLabel.BackgroundTransparency = 1
    costLabel.BorderSizePixel = 0
    costLabel.Font = Enum.Font.GothamBold
    costLabel.TextSize = 24
    costLabel.TextColor3 = Color3.fromRGB(255, 165, 0) -- Orange text for TubePlots
    costLabel.TextStrokeTransparency = 0
    costLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    costLabel.TextXAlignment = Enum.TextXAlignment.Center
    costLabel.TextYAlignment = Enum.TextYAlignment.Center
    local tubePlotCost = self:GetTubePlotCost(tubePlotNumber)
    costLabel.Text = tubePlotCost == 0 and "FREE" or ("$" .. tubePlotCost)
    costLabel.Parent = billboard
end

function PlotService:AttemptPlotPurchase(player, plotNumber)
    local playerData = DataService:GetPlayerData(player)
    if not playerData then
        return false
    end
    
    -- Check if player already owns this plot
    for _, ownedPlot in pairs(playerData.OwnedPlots) do
        if ownedPlot == plotNumber then
            -- Player already owns this plot
            return false
        end
    end
    
    -- Check rebirth requirement
    local requiredRebirths = getPlotRebirthRequirement(plotNumber)
    local playerRebirths = playerData.Resources and playerData.Resources.Rebirths or 0
    if playerRebirths < requiredRebirths then
        return false
    end
    
    -- Check if player has enough money
    local plotCost = self:GetPlotCost(plotNumber)
    if playerData.Resources.Money < plotCost then
        -- Not enough money
        return false
    end
    
    -- Purchase the plot
    local success = DataService:UpdatePlayerResources(player, "Money", -plotCost)
    if success then
        DataService:AddOwnedPlot(player, plotNumber)
        StateService:BroadcastPlayerDataUpdate(player)
        
        -- Hide the UI for this plot
        self:HidePlotUI(player, plotNumber)
        
        -- Unlock the corresponding door
        self:UnlockDoorForPlot(player, plotNumber)
        
        -- Play button press animation and update plot colors in player's area
        local AreaService = require(script.Parent.AreaService)
        local assignedAreaNumber = AreaService:GetPlayerAssignedArea(player)
        if assignedAreaNumber then
            local playerAreas = Workspace:FindFirstChild("PlayerAreas")
            if playerAreas then
                local area = playerAreas:FindFirstChild("PlayerArea" .. assignedAreaNumber)
                if area then
                    -- Play press animation
                    self:PlayPlotPressAnimation(area, plotNumber, false)
                    
                    -- Add "Purchased" SurfaceGui to the plot
                    local buttons = area:FindFirstChild("Buttons")
                    if buttons then
                        local plot = buttons:FindFirstChild("Plot" .. plotNumber)
                        if plot then
                            self:AddPurchasedSurfaceGui(area, plot)
                        end
                    end
                end
            end
        end
        
        return true
    end
    
    return false
end

function PlotService:AttemptTubePlotPurchase(player, tubePlotNumber)
    local playerData = DataService:GetPlayerData(player)
    if not playerData then
        return false
    end
    
    -- Check if player already owns this TubePlot
    for _, ownedTube in pairs(playerData.OwnedTubes) do
        if ownedTube == tubePlotNumber then
            -- Player already owns this TubePlot
            return false
        end
    end
    
    -- Check rebirth requirement
    local requiredRebirths = getTubePlotRebirthRequirement(tubePlotNumber)
    local playerRebirths = playerData.Resources and playerData.Resources.Rebirths or 0
    if playerRebirths < requiredRebirths then
        return false
    end
    
    -- Check if player has enough money
    local tubePlotCost = self:GetTubePlotCost(tubePlotNumber)
    if playerData.Resources.Money < tubePlotCost then
        -- Not enough money
        return false
    end
    
    -- Purchase the TubePlot
    local success = DataService:UpdatePlayerResources(player, "Money", -tubePlotCost)
    if success then
        DataService:AddOwnedTube(player, tubePlotNumber)
        StateService:BroadcastPlayerDataUpdate(player)
        
        -- Hide the UI for this TubePlot
        self:HideTubePlotUI(player, tubePlotNumber)
        
        -- Unlock the corresponding tube
        self:UnlockTubeForTubePlot(player, tubePlotNumber)
        
        -- Play button press animation and update plot colors in player's area
        local AreaService = require(script.Parent.AreaService)
        local assignedAreaNumber = AreaService:GetPlayerAssignedArea(player)
        if assignedAreaNumber then
            local playerAreas = Workspace:FindFirstChild("PlayerAreas")
            if playerAreas then
                local area = playerAreas:FindFirstChild("PlayerArea" .. assignedAreaNumber)
                if area then
                    -- Play press animation for TubePlot
                    self:PlayPlotPressAnimation(area, tubePlotNumber, true)
                    
                    -- Add "Purchased" SurfaceGui to the tube plot
                    local buttons = area:FindFirstChild("Buttons")
                    if buttons then
                        local tubePlot = buttons:FindFirstChild("TubePlot" .. tubePlotNumber)
                        if tubePlot then
                            self:AddPurchasedSurfaceGui(area, tubePlot)
                        end
                    end
                end
            end
        end
        
        return true
    end
    
    return false
end

function PlotService:GetPlotCost(plotNumber)
    -- First plot is free, then each plot costs 2x the previous one
    if plotNumber == 1 then
        return 0
    end
    return PLOT_BASE_COST * (2 ^ (plotNumber - 2))
end

function PlotService:GetTubePlotCost(tubePlotNumber)
    -- First tubeplot is free, then each tubeplot costs 2x the previous one
    if tubePlotNumber == 1 then
        return 0
    end
    return TUBEPLOT_BASE_COST * (2 ^ (tubePlotNumber - 2))
end

function PlotService:PlayerOwnsArea(player, areaNumber)
    -- Use AreaService to get the player's assigned area
    local AreaService = require(script.Parent.AreaService)
    local assignedAreaNumber = AreaService:GetPlayerAssignedArea(player)
    
    -- Player owns the area if it matches their assigned area
    return assignedAreaNumber == areaNumber
end

function PlotService:HidePlotUI(player, plotNumber)
    -- No longer hide plot UI when purchased - let UpdatePlotGUIs handle showing "Purchased"
    -- This function is kept for compatibility but does nothing
end

function PlotService:AddPurchasedSurfaceGui(area, plot)
    -- Check if it already has a purchased GUI
    if plot:FindFirstChild("PurchasedSurfaceGui") then
        return
    end
    
    -- Keep level/door GUI when plot is purchased (both GUIs will show simultaneously)
    
    -- Create SurfaceGui on the plot itself
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Name = "PurchasedSurfaceGui"
    surfaceGui.Face = Enum.NormalId.Top
    surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surfaceGui.PixelsPerStud = 50
    
    -- Create text label with rotation based on plot type (positioned in the middle)
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 0.4, 0) -- Smaller height to fit in middle
    textLabel.Position = UDim2.new(0, 0, 0.3, 0) -- Position in the middle (30% from top)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "Purchased"
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 32 -- Smaller text to fit with level/door text
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    
    -- Check if it's a TubePlot and apply different rotation
    if plot.Name:match("^TubePlot") then
        textLabel.Rotation = 270  -- 270 degrees (opposite direction) for TubePlots
        -- For tube plots, adjust positioning to not overlap with tube number text
        textLabel.Position = UDim2.new(0, 0, 0.4, 0) -- Lower position for tube plots
        textLabel.Size = UDim2.new(1, 0, 0.3, 0) -- Smaller height
    else
        textLabel.Rotation = 90  -- 90 degrees for regular Plots
    end
    
    textLabel.Parent = surfaceGui
    
    -- Find the Cube.009 part inside the plot model
    if plot:IsA("Model") then
        local cube = plot:FindFirstChild("Cube.009")
        if cube and cube:IsA("BasePart") then
            surfaceGui.Parent = cube
        end
    elseif plot:IsA("BasePart") then
        surfaceGui.Parent = plot
    end
end

function PlotService:AddLevelDoorSurfaceGui(plot, plotNumber)
    -- Skip plots 6 and 7 (they don't exist)
    if plotNumber == 6 or plotNumber == 7 then
        return
    end
    
    -- Get level and door info for this plot
    local level, doorNumber = self:GetLevelAndDoorForPlot(plotNumber)
    if not level or not doorNumber then
        return
    end
    
    -- Check if it already has a level/door GUI
    if plot:FindFirstChild("LevelDoorSurfaceGui") then
        return
    end
    
    -- Create SurfaceGui on the plot itself
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Name = "LevelDoorSurfaceGui"
    surfaceGui.Face = Enum.NormalId.Top
    surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surfaceGui.PixelsPerStud = 50
    
    -- Create text label
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "Level " .. level .. "\n\nDoor " .. doorNumber
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 36
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 0) -- Yellow text
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.Rotation = 90  -- 90 degrees for regular Plots
    textLabel.Parent = surfaceGui
    
    -- Find the Cube.009 part inside the plot model
    if plot:IsA("Model") then
        local cube = plot:FindFirstChild("Cube.009")
        if cube and cube:IsA("BasePart") then
            surfaceGui.Parent = cube
        end
    elseif plot:IsA("BasePart") then
        surfaceGui.Parent = plot
    end
end

function PlotService:RemoveLevelDoorSurfaceGui(plot)
    -- Remove level/door GUI if present
    if plot:IsA("Model") then
        local cube = plot:FindFirstChild("Cube.009")
        if cube then
            local levelDoorGui = cube:FindFirstChild("LevelDoorSurfaceGui")
            if levelDoorGui then
                levelDoorGui:Destroy()
            end
        end
    elseif plot:IsA("BasePart") then
        local levelDoorGui = plot:FindFirstChild("LevelDoorSurfaceGui")
        if levelDoorGui then
            levelDoorGui:Destroy()
        end
    end
end

function PlotService:AddTubeNumberSurfaceGui(tubePlot, tubePlotNumber)
    -- Check if it already has a tube number GUI (should exist from AreaTemplate)
    if tubePlot:IsA("Model") then
        local cube = tubePlot:FindFirstChild("Cube.009")
        if cube and cube:FindFirstChild("TubeNumberSurfaceGui") then
            return -- GUI already exists from template
        end
    elseif tubePlot:IsA("BasePart") and tubePlot:FindFirstChild("TubeNumberSurfaceGui") then
        return -- GUI already exists from template
    end
    
    -- Create SurfaceGui on the tube plot itself
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Name = "TubeNumberSurfaceGui"
    surfaceGui.Face = Enum.NormalId.Top
    surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surfaceGui.PixelsPerStud = 50
    
    -- Create text label
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    
    -- Convert number to ordinal (1st, 2nd, 3rd, etc.) with line breaks for proper spacing
    local ordinalText
    if tubePlotNumber == 1 then
        ordinalText = "\n\n1st Tube"
    elseif tubePlotNumber == 2 then
        ordinalText = "\n\n2nd Tube"
    elseif tubePlotNumber == 3 then
        ordinalText = "\n\n3rd Tube"
    else
        ordinalText = "\n\n" .. tubePlotNumber .. "th Tube"
    end
    
    textLabel.Text = ordinalText
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 36
    textLabel.TextColor3 = Color3.fromRGB(255, 165, 0) -- Orange text to match tube plots
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.Rotation = 270  -- 270 degrees for TubePlots (same as "Purchased")
    textLabel.Parent = surfaceGui
    
    -- Find the Cube.009 part inside the tube plot model
    if tubePlot:IsA("Model") then
        local cube = tubePlot:FindFirstChild("Cube.009")
        if cube and cube:IsA("BasePart") then
            surfaceGui.Parent = cube
        end
    elseif tubePlot:IsA("BasePart") then
        surfaceGui.Parent = tubePlot
    end
end

function PlotService:RemoveTubeNumberSurfaceGui(tubePlot)
    -- Remove tube number GUI if present
    if tubePlot:IsA("Model") then
        local cube = tubePlot:FindFirstChild("Cube.009")
        if cube then
            local tubeNumberGui = cube:FindFirstChild("TubeNumberSurfaceGui")
            if tubeNumberGui then
                tubeNumberGui:Destroy()
            end
        end
    elseif tubePlot:IsA("BasePart") then
        local tubeNumberGui = tubePlot:FindFirstChild("TubeNumberSurfaceGui")
        if tubeNumberGui then
            tubeNumberGui:Destroy()
        end
    end
end

function PlotService:HideTubePlotUI(player, tubePlotNumber)
    -- No longer hide tubeplot UI when purchased - let UpdatePlotGUIs handle showing "Purchased"
    -- This function is kept for compatibility but does nothing
end

function PlotService:GetPlayerOwnedPlots(player)
    local playerData = DataService:GetPlayerData(player)
    if not playerData then
        return {}
    end
    
    return playerData.OwnedPlots or {}
end

function PlotService:PlayerOwnsPlot(player, plotNumber)
    local ownedPlots = self:GetPlayerOwnedPlots(player)
    
    for _, ownedPlot in pairs(ownedPlots) do
        if ownedPlot == plotNumber then
            return true
        end
    end
    
    return false
end

function PlotService:GetPlayerOwnedTubes(player)
    local playerData = DataService:GetPlayerData(player)
    if not playerData then
        return {}
    end
    
    return playerData.OwnedTubes or {}
end

function PlotService:PlayerOwnsTube(player, tubeNumber)
    local ownedTubes = self:GetPlayerOwnedTubes(player)
    
    for _, ownedTube in pairs(ownedTubes) do
        if ownedTube == tubeNumber then
            return true
        end
    end
    
    return false
end

function PlotService:UpdateAreaPlotUIs(area)
    -- Find the assigned player for this area
    local areaNumber = tonumber(area.Name:match("PlayerArea(%d+)"))
    if not areaNumber then
        return
    end
    
    -- Find the player assigned to this area (we'll need to get this from AreaService)
    -- For now, we'll check when players join and update then
    Players.PlayerAdded:Connect(function(player)
        -- Small delay to ensure data is loaded
        wait(2)
        self:UpdatePlayerAreaPlotUIs(player, area)
    end)
    
    -- Update for existing players
    for _, player in pairs(Players:GetPlayers()) do
        task.spawn(function()
            wait(2)
            self:UpdatePlayerAreaPlotUIs(player, area)
            -- Don't initialize doors here - it's handled by DataService callback
        end)
    end
end

function PlotService:UpdateAreaTubePlotUIs(area)
    -- Find the assigned player for this area
    local areaNumber = tonumber(area.Name:match("PlayerArea(%d+)"))
    if not areaNumber then
        return
    end
    
    -- Find the player assigned to this area (we'll need to get this from AreaService)
    -- For now, we'll check when players join and update then
    Players.PlayerAdded:Connect(function(player)
        -- Small delay to ensure data is loaded
        wait(2)
        self:UpdatePlayerAreaTubePlotUIs(player, area)
    end)
    
    -- Update for existing players
    for _, player in pairs(Players:GetPlayers()) do
        task.spawn(function()
            wait(2)
            self:UpdatePlayerAreaTubePlotUIs(player, area)
        end)
    end
end

function PlotService:UpdatePlayerAreaPlotUIs(player, area)
    if not self:PlayerOwnsArea(player, tonumber(area.Name:match("PlayerArea(%d+)"))) then
        return
    end
    
    -- Don't destroy owned plot UIs anymore - let UpdatePlotGUIs handle showing "Purchased"
    -- This allows purchased plots to show "Purchased" text instead of disappearing
end

function PlotService:UpdatePlayerAreaTubePlotUIs(player, area)
    if not self:PlayerOwnsArea(player, tonumber(area.Name:match("PlayerArea(%d+)"))) then
        return
    end
    
    -- Don't destroy owned tubeplot UIs anymore - let UpdatePlotGUIs handle showing "Purchased"
    -- This allows purchased tubeplots to show "Purchased" text instead of disappearing
end

-- Start proximity checking for UI visibility
function PlotService:StartProximityChecking()
    game:GetService("RunService").Heartbeat:Connect(function()
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                self:UpdatePlotUIVisibility(player)
            end
        end
    end)
end

-- Update plot UI visibility based on player proximity and rebirth level
function PlotService:UpdatePlotUIVisibility(player)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local playerPosition = character.HumanoidRootPart.Position
    local playerAreas = Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then
        return
    end
    
    -- Get player's rebirth level for visibility checking
    local playerData = DataService:GetPlayerData(player)
    local playerRebirths = playerData and playerData.Resources and playerData.Resources.Rebirths or 0
    
    -- Check each area for plot UIs
    for _, area in pairs(playerAreas:GetChildren()) do
        local areaNumber = tonumber(area.Name:match("PlayerArea(%d+)"))
        if areaNumber and self:PlayerOwnsArea(player, areaNumber) then
            -- Check each plot UI in this area
            for i = 1, TOTAL_PLOTS do
                local uiPart = area:FindFirstChild("PlotUI_" .. i)
                if uiPart then
                    local distance = (playerPosition - uiPart.Position).Magnitude
                    local billboard = uiPart:FindFirstChild("PlotBillboard")
                    
                    -- Check if player should be able to see this plot
                    local plotRebirthRequirement = getPlotRebirthRequirement(i)
                    local shouldShowPlot = playerRebirths >= (plotRebirthRequirement - 1) -- Can see current level + next level
                    
                    if distance <= UI_VISIBILITY_DISTANCE and not self:PlayerOwnsPlot(player, i) and shouldShowPlot then
                        -- Show UI
                        if billboard then
                            billboard.Enabled = true
                        end
                    else
                        -- Hide UI
                        if billboard then
                            billboard.Enabled = false
                        end
                    end
                end
            end
            
            -- Check each TubePlot UI in this area
            for i = 1, TOTAL_TUBEPLOTS do
                local uiPart = area:FindFirstChild("TubePlotUI_" .. i)
                if uiPart then
                    local distance = (playerPosition - uiPart.Position).Magnitude
                    local billboard = uiPart:FindFirstChild("TubePlotBillboard")
                    
                    -- Check if player should be able to see this tubeplot
                    local tubePlotRebirthRequirement = getTubePlotRebirthRequirement(i)
                    local shouldShowTubePlot = playerRebirths >= (tubePlotRebirthRequirement - 1) -- Can see current level + next level
                    
                    if distance <= UI_VISIBILITY_DISTANCE and not self:PlayerOwnsTube(player, i) and shouldShowTubePlot then
                        -- Show UI
                        if billboard then
                            billboard.Enabled = true
                        end
                    else
                        -- Hide UI
                        if billboard then
                            billboard.Enabled = false
                        end
                    end
                end
            end
        end
    end
end

-- Get level and door info for a plot
function PlotService:GetLevelAndDoorForPlot(plotNumber)
    -- Skip plots 6 and 7 (they don't exist)
    if plotNumber == 6 or plotNumber == 7 then
        return nil, nil
    end
    
    for level, config in pairs(LEVEL_CONFIG) do
        if plotNumber >= config.startPlot and plotNumber <= config.endPlot then
            local doorNumber = plotNumber - config.startPlot + 1
            return level, doorNumber
        end
    end
    
    return nil, nil
end

-- Unlock door corresponding to a plot
function PlotService:UnlockDoorForPlot(player, plotNumber)
    local level, doorNumber = self:GetLevelAndDoorForPlot(plotNumber)
    if not level or not doorNumber then
        return
    end
    
    -- Find player's area
    local character = player.Character
    if not character then
        return
    end
    
    local playerAreas = Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then
        return
    end
    
    -- Find which area the player owns
    for _, area in pairs(playerAreas:GetChildren()) do
        local areaNumber = tonumber(area.Name:match("PlayerArea(%d+)"))
        
        if areaNumber and self:PlayerOwnsArea(player, areaNumber) then
            
            -- Find the door in the level structure
            local levelFolder = area:FindFirstChild("Level" .. level)
            
            if levelFolder then
                local doorsFolder = levelFolder:FindFirstChild("Level" .. level .. "Doors")
                
                if doorsFolder then
                    local door = doorsFolder:FindFirstChild("Door" .. doorNumber)
                    
                    if door then
                        self:UnlockDoor(door)
                    else
                    end
                else
                    end
            else
                end
            break
        end
    end
end

-- Unlock a door (change color to green)
function PlotService:UnlockDoor(door)
    -- Change door color to green
    local function colorPart(part)
        if part:IsA("BasePart") then
            part.Color = Color3.fromRGB(85, 170, 85) -- Green
            
            -- Also ensure transparency is 0 (fully visible)
            if part.Transparency > 0.9 then
                part.Transparency = 0
            end
        end
    end
    
    if door:IsA("Model") then
        for _, descendant in pairs(door:GetDescendants()) do
            colorPart(descendant)
        end
    elseif door:IsA("BasePart") then
        colorPart(door)
    end
    
    -- Start continuous pet spawning for this door
    self:StartPetSpawningForDoor(door)
end

-- Unlock a tube (move it back to template position)
function PlotService:UnlockTube(tube)
    -- Unlock tube and restore position if needed
    local currentPosition = tube:GetPivot()
    
    -- Check if tube is underground (hidden) and restore to surface
    if currentPosition.Position.Y < -500 then
        local correctY = currentPosition.Position.Y + 1000 -- Move up 1000 studs from underground position
        local newPosition = Vector3.new(currentPosition.Position.X, correctY, currentPosition.Position.Z)
        local restoredPosition = CFrame.new(newPosition) * currentPosition.Rotation
        tube:PivotTo(restoredPosition)
    end
    
    -- Tubes don't spawn pets, they are for processing
end

-- Start continuous pet spawning for a door
function PlotService:StartPetSpawningForDoor(door)
    -- Create a unique key for this door using its path
    local doorKey = door:GetFullName()
    
    -- Check if already spawning
    if spawningDoors[doorKey] then
        return
    end
    
    -- Create spawning coroutine
    spawningDoors[doorKey] = task.spawn(function()
        -- Spawn immediately
        self:SpawnPetBall(door)
        
        while door and door.Parent do
            -- Wait 5 seconds before next spawn
            wait(5)
            
            -- Check if door still exists
            if door and door.Parent then
                -- Spawn a pet ball
                self:SpawnPetBall(door)
            end
        end
        
        -- Clean up when door is removed
        spawningDoors[doorKey] = nil
    end)
end

-- Initialize doors for already owned plots when player joins
function PlotService:InitializePlayerDoors(player)
    local ownedPlots = self:GetPlayerOwnedPlots(player)
    
    -- Get player's assigned area from AreaService
    local AreaService = require(script.Parent.AreaService)
    
    -- Wait for area assignment (with timeout)
    local attempts = 0
    local assignedAreaNumber
    repeat
        assignedAreaNumber = AreaService:GetPlayerAssignedArea(player)
        if not assignedAreaNumber then
            attempts = attempts + 1
            if attempts > 20 then -- 2 seconds timeout
                return
            end
            wait(0.1)
        end
    until assignedAreaNumber
    
    for _, plotNumber in pairs(ownedPlots) do
        self:UnlockDoorForPlotInArea(player, plotNumber, assignedAreaNumber)
    end
    
    -- Also initialize tubes for owned TubePlots
    local ownedTubes = self:GetPlayerOwnedTubes(player)
    
    for _, tubeNumber in pairs(ownedTubes) do
        self:UnlockTubeForTubePlotInArea(player, tubeNumber, assignedAreaNumber)
    end
    
    -- Update plot colors, GUIs, and visibility for this player's area
    local playerAreas = Workspace:FindFirstChild("PlayerAreas")
    if playerAreas then
        local area = playerAreas:FindFirstChild("PlayerArea" .. assignedAreaNumber)
        if area then
            self:UpdatePlotGUIs(area, player)
            self:UpdatePlotColors(area, player)
            self:UpdatePlotVisibility(area, player)
        end
    end
end

-- Color all doors in an area
function PlotService:ColorAllDoorsInArea(area, color)
    -- Go through all levels and color their doors
    for level = 1, 5 do
        local levelFolder = area:FindFirstChild("Level" .. level)
        if levelFolder then
            local doorsFolder = levelFolder:FindFirstChild("Level" .. level .. "Doors")
            if doorsFolder then
                -- Color all doors in this level
                for _, door in pairs(doorsFolder:GetChildren()) do
                    if door.Name:match("^Door%d+$") then
                        local function colorPart(part)
                            if part:IsA("BasePart") then
                                part.Color = color
                            end
                        end
                        
                        if door:IsA("Model") then
                            for _, descendant in pairs(door:GetDescendants()) do
                                colorPart(descendant)
                            end
                        elseif door:IsA("BasePart") then
                            colorPart(door)
                        end
                    end
                end
            end
        end
    end
end

-- Hide all tubes in an area by moving them underground
function PlotService:HideAllTubesInArea(area)
    -- Find the Tubes folder structure: AreaTemplate>Tubes>Tubes>Tube1-10
    local tubesFolder = area:FindFirstChild("Tubes")
    if tubesFolder then
        local innerTubesFolder = tubesFolder:FindFirstChild("Tubes")
        if innerTubesFolder then
            -- Hide all tubes by moving them underground
            for i = 1, TOTAL_TUBEPLOTS do
                local tube = innerTubesFolder:FindFirstChild("Tube" .. i)
                if tube then
                    -- Move tube far underground to hide it (only if not already hidden)
                    local currentPosition = tube:GetPivot()
                    if currentPosition.Position.Y > -500 then
                        local newPosition = currentPosition.Position + Vector3.new(0, -1000, 0)
                        local hiddenPosition = CFrame.new(newPosition) * currentPosition.Rotation
                        tube:PivotTo(hiddenPosition)
                    end
                end
            end
        end
    end
end

-- Initialize doors for an area based on assigned player's owned plots
function PlotService:AddDoorSurfaceGuis(area)
    -- Door GUIs are now pre-created in AreaTemplate and copied automatically
    -- This function is kept for backward compatibility but does nothing
    -- Static door level/number GUIs already exist from template copying
end

function PlotService:CreateDoorSurfaceGui(door, level, doorNumber)
    -- DEPRECATED: Door GUIs are now pre-created in AreaTemplate
    -- This function is kept for backward compatibility but should not be called
    return
end

function PlotService:InitializeAreaDoors(area)
    local areaNumber = tonumber(area.Name:match("PlayerArea(%d+)"))
    if not areaNumber then
        return
    end
    
    -- Door Surface GUIs already exist from AreaTemplate (no need to create them)
    
    -- Get the assigned player for this area
    local AreaService = require(script.Parent.AreaService)
    local assignedPlayer = nil
    
    -- Find which player is assigned to this area
    for _, player in pairs(Players:GetPlayers()) do
        local playerArea = AreaService:GetPlayerAssignedArea(player)
        if playerArea == areaNumber then
            assignedPlayer = player
            break
        end
    end
    
    if not assignedPlayer then
        return
    end
    
    -- Get player's owned plots
    local ownedPlots = self:GetPlayerOwnedPlots(assignedPlayer)
    
    -- Unlock doors for each owned plot
    for _, plotNumber in pairs(ownedPlots) do
        local level, doorNumber = self:GetLevelAndDoorForPlot(plotNumber)
        if level and doorNumber then
            
            -- Find the door in this specific area
            local levelFolder = area:FindFirstChild("Level" .. level)
            if levelFolder then
                local doorsFolder = levelFolder:FindFirstChild("Level" .. level .. "Doors")
                if doorsFolder then
                    local door = doorsFolder:FindFirstChild("Door" .. doorNumber)
                    if door then
                        self:UnlockDoor(door)
                    end
                end
            end
        end
    end
end

-- Initialize tubes for an area based on assigned player's owned TubePlots
function PlotService:InitializeAreaTubes(area)
    local areaNumber = tonumber(area.Name:match("PlayerArea(%d+)"))
    if not areaNumber then
        return
    end
    
    
    -- Get the assigned player for this area
    local AreaService = require(script.Parent.AreaService)
    local assignedPlayer = nil
    
    -- Find which player is assigned to this area
    for _, player in pairs(Players:GetPlayers()) do
        local playerArea = AreaService:GetPlayerAssignedArea(player)
        if playerArea == areaNumber then
            assignedPlayer = player
            break
        end
    end
    
    if not assignedPlayer then
        return
    end
    
    
    -- Get player's owned TubePlots
    local ownedTubes = self:GetPlayerOwnedTubes(assignedPlayer)
    
    -- Unlock tubes for each owned TubePlot
    for _, tubeNumber in pairs(ownedTubes) do
        
        -- Find the tube in this specific area
        local tubesFolder = area:FindFirstChild("Tubes")
        if tubesFolder then
            local innerTubesFolder = tubesFolder:FindFirstChild("Tubes")
            if innerTubesFolder then
                local tube = innerTubesFolder:FindFirstChild("Tube" .. tubeNumber)
                if tube then
                    self:UnlockTube(tube)
                end
            end
        end
    end
end

-- Unlock door for a specific plot in a specific area (used during initialization)
function PlotService:UnlockDoorForPlotInArea(player, plotNumber, areaNumber)
    
    local level, doorNumber = self:GetLevelAndDoorForPlot(plotNumber)
    if not level or not doorNumber then
        return
    end
    
    
    local playerAreas = Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then
        return
    end
    
    local targetArea = playerAreas:FindFirstChild("PlayerArea" .. areaNumber)
    if not targetArea then
        return
    end
    
    
    -- Find the door in the level structure
    local levelFolder = targetArea:FindFirstChild("Level" .. level)
    
    if levelFolder then
        local doorsFolder = levelFolder:FindFirstChild("Level" .. level .. "Doors")
        
        if doorsFolder then
            local door = doorsFolder:FindFirstChild("Door" .. doorNumber)
            
            if door then
                self:UnlockDoor(door)
            else
                -- Door not found in folder
            end
        else
            -- Level doors folder not found
        end
    else
        -- Level folder not found
    end
end

-- Unlock tube for a specific TubePlot (direct mapping TubePlot1 -> Tube1)
function PlotService:UnlockTubeForTubePlot(player, tubePlotNumber)
    
    -- Find player's area
    local character = player.Character
    if not character then
        return
    end
    
    local playerAreas = Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then
        return
    end
    
    -- Find which area the player owns
    for _, area in pairs(playerAreas:GetChildren()) do
        local areaNumber = tonumber(area.Name:match("PlayerArea(%d+)"))
        
        if areaNumber and self:PlayerOwnsArea(player, areaNumber) then
            
            -- Find the tube: AreaTemplate>Tubes>Tubes>TubeX
            local tubesFolder = area:FindFirstChild("Tubes")
            
            if tubesFolder then
                local innerTubesFolder = tubesFolder:FindFirstChild("Tubes")
                
                if innerTubesFolder then
                    local tube = innerTubesFolder:FindFirstChild("Tube" .. tubePlotNumber)
                    
                    if tube then
                        self:UnlockTube(tube)
                    else
                        -- Tube not found in folder
                    end
                else
                    -- Inner Tubes folder not found
                end
            else
                -- Tubes folder not found
            end
            break
        end
    end
end

-- Unlock tube for a specific TubePlot in a specific area (used during initialization)
function PlotService:UnlockTubeForTubePlotInArea(player, tubeNumber, areaNumber)
    
    local playerAreas = Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then
        return
    end
    
    local targetArea = playerAreas:FindFirstChild("PlayerArea" .. areaNumber)
    if not targetArea then
        return
    end
    
    
    -- Find the tube: AreaTemplate>Tubes>Tubes>TubeX
    local tubesFolder = targetArea:FindFirstChild("Tubes")
    
    if tubesFolder then
        local innerTubesFolder = tubesFolder:FindFirstChild("Tubes")
        
        if innerTubesFolder then
            local tube = innerTubesFolder:FindFirstChild("Tube" .. tubeNumber)
            
            if tube then
                self:UnlockTube(tube)
            else
                -- Tube not found
            end
        else
            -- Inner Tubes folder not found
        end
    else
        -- Tubes folder not found
    end
end

-- Check if a door is unlocked (green color)
function PlotService:IsDoorUnlocked(door)
    local greenColor = Color3.fromRGB(85, 170, 85)
    
    local function checkPart(part)
        if part:IsA("BasePart") then
            -- Check if part color matches green (unlocked state)
            local partColor = part.Color
            return math.abs(partColor.R - greenColor.R) < 0.01 and 
                   math.abs(partColor.G - greenColor.G) < 0.01 and 
                   math.abs(partColor.B - greenColor.B) < 0.01
        end
        return false
    end
    
    if door:IsA("Model") then
        -- Check if any part of the door model is green
        for _, descendant in pairs(door:GetDescendants()) do
            if checkPart(descendant) then
                return true
            end
        end
        return false
    elseif door:IsA("BasePart") then
        return checkPart(door)
    end
    
    return false
end

-- Spawn a purple pet ball near a door
function PlotService:GetLevelFromDoor(door)
    -- Traverse up the parent hierarchy to find which level folder this door belongs to
    local current = door
    while current and current.Parent do
        local parent = current.Parent
        -- Look for level folder pattern (e.g., "Level1", "Level2", etc.)
        if parent.Name:match("Level(%d+)") then
            local levelNumber = tonumber(parent.Name:match("Level(%d+)"))
            if levelNumber then
                return levelNumber
            end
        end
        -- Also check if current is a level folder
        if current.Name:match("Level(%d+)") then
            local levelNumber = tonumber(current.Name:match("Level(%d+)"))
            if levelNumber then
                return levelNumber
            end
        end
        current = parent
    end
    
    -- Fallback to level 1 if we can't determine the level
    warn("PlotService: Could not determine level for door", door.Name, "- defaulting to level 1")
    return 1
end

function PlotService:SpawnPetBall(door)
    -- Only spawn pets if door is unlocked (green)
    if not self:IsDoorUnlocked(door) then
        return
    end
    
    -- Find which area this door belongs to
    local areaName = self:GetAreaNameFromDoor(door)
    if not areaName then
        return
    end
    
    -- Check pet ball limit for this area
    local currentCount = areaPetBallCounts[areaName] or 0
    if currentCount >= MAX_PET_BALLS_PER_AREA then
        return
    end
    
    -- Get door number from door name (e.g., "Door1" -> 1)
    local doorNumber = tonumber(door.Name:match("Door(%d+)")) or 1
    
    -- Determine level based on door's location in folder structure
    local level = self:GetLevelFromDoor(door)
    -- Spawning pet ball at door
    
    -- Generate random pet data using new spawn system
    local PetSpawnConfig = require(ReplicatedStorage.config.PetSpawnConfig)
    local randomPetData = PetSpawnConfig:GetRandomPet(level, doorNumber)
    
    if not randomPetData then
        warn("PlotService: Failed to generate random pet data")
        return
    end
    
    -- Add variation to the pet using the new variation system
    local VariationConfig = require(ReplicatedStorage.config.VariationConfig)
    local variation = VariationConfig:GetRandomVariation()
    
    -- Apply variation to pet data
    randomPetData.Variation = variation
    
    -- Get door position
    local doorPosition
    if door:IsA("Model") then
        local cframe, size = door:GetBoundingBox()
        doorPosition = cframe.Position
    else
        doorPosition = door.Position
    end
    
    -- Create pet ball with rarity color
    local petBall = Instance.new("Part")
    petBall.Name = "PetBall"
    petBall.Shape = Enum.PartType.Ball
    petBall.Size = Vector3.new(2, 2, 2)
    
    -- Get rarity color from constants
    local PetConstants = require(ReplicatedStorage.constants.PetConstants)
    local rarityColor = PetConstants.getRarityColor(randomPetData.Rarity)
    petBall.Color = rarityColor
    
    petBall.Material = Enum.Material.Neon
    petBall.Transparency = 0.3 -- Make ball slightly transparent for pet asset visibility
    petBall.CanCollide = true  -- Enable collision so it can hit the ground
    petBall.Anchored = false   -- Not anchored so it can fall
    
    -- Add physics properties for better rolling
    petBall.TopSurface = Enum.SurfaceType.Smooth
    petBall.BottomSurface = Enum.SurfaceType.Smooth
    
    -- Create physical properties for bounce and friction
    local physProperties = PhysicalProperties.new(
        0.7,   -- Density
        0.5,   -- Friction  
        0.3,   -- Elasticity (bounciness)
        1,     -- FrictionWeight
        1      -- ElasticityWeight
    )
    petBall.CustomPhysicalProperties = physProperties
    
    -- Set pet ball to PetBalls collision group (collision groups set up during initialization)
    petBall.CollisionGroup = "PetBalls"
    
    -- Store pet data in the ball
    local petDataValue = Instance.new("StringValue")
    petDataValue.Name = "PetData"
    petDataValue.Value = game:GetService("HttpService"):JSONEncode(randomPetData)
    petDataValue.Parent = petBall
    
    -- Position at door center (slightly above)
    local ballPosition = doorPosition + Vector3.new(0, 1, 0)
    petBall.Position = ballPosition
    petBall.Parent = door.Parent
    
    -- Add some random initial velocity for variety
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(4000, 0, 4000)
    bodyVelocity.Velocity = Vector3.new(math.random(-5, 5), 0, math.random(-5, 5))
    bodyVelocity.Parent = petBall
    
    -- Remove the body velocity after a short time to let natural physics take over
    game:GetService("Debris"):AddItem(bodyVelocity, 0.5)
    
    -- Track pet ball for this area
    areaPetBallCounts[areaName] = (areaPetBallCounts[areaName] or 0) + 1
    
    -- Update counter GUI
    self:UpdateCounterGUI(areaName, areaPetBallCounts[areaName])
    
    -- Track when ball is destroyed (collected or expired)
    petBall.AncestryChanged:Connect(function()
        if not petBall.Parent then
            areaPetBallCounts[areaName] = math.max(0, (areaPetBallCounts[areaName] or 0) - 1)
            self:UpdateCounterGUI(areaName, areaPetBallCounts[areaName])
        end
    end)
    
    -- Pet balls don't expire - they stay until collected
end

-- Handle pet collection
function PlotService:CollectPet(player, petBall)
    -- Get the pre-generated pet data from the ball
    local petDataValue = petBall:FindFirstChild("PetData")
    if not petDataValue then
        warn("PlotService: Pet ball has no pet data!")
        return
    end
    
    -- Decode the pet data
    local success, petData = pcall(function()
        return game:GetService("HttpService"):JSONDecode(petDataValue.Value)
    end)
    
    if not success or not petData then
        warn("PlotService: Failed to decode pet data")
        return
    end
    
    -- Pet collected by player
    
    -- Add pet to player's inventory
    local DataService = require(script.Parent.DataService)
    DataService:AddPetToPlayer(player, petData)
    
    -- Create collection effect
    local TweenService = game:GetService("TweenService")
    local shrinkTween = TweenService:Create(petBall,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {Size = Vector3.new(0, 0, 0), Transparency = 1}
    )
    shrinkTween:Play()
    
    shrinkTween.Completed:Connect(function()
        petBall:Destroy()
    end)
    
    -- Sync updated data to client
    local StateService = require(script.Parent.StateService)
    StateService:BroadcastPlayerDataUpdate(player)
end

-- Get area name from door by traversing up the hierarchy
function PlotService:GetAreaNameFromDoor(door)
    local current = door.Parent
    while current do
        if current.Name:match("^PlayerArea%d+$") then
            return current.Name
        end
        current = current.Parent
    end
    return nil
end

-- Update counter GUI for an area
function PlotService:UpdateCounterGUI(areaName, count)
    local playerAreas = Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then return end
    
    local area = playerAreas:FindFirstChild(areaName)
    if not area then return end
    
    -- Find CounterAnchor in Level1
    local level1 = area:FindFirstChild("Level1")
    if not level1 then return end
    
    local counterAnchorModel = level1:FindFirstChild("CounterAnchorModel")
    if not counterAnchorModel then return end
    
    local counterAnchor = counterAnchorModel:FindFirstChild("CounterAnchor")
    if not counterAnchor then return end
    
    -- Find or create SurfaceGui
    local surfaceGui = counterAnchor:FindFirstChild("CounterGUI")
    if not surfaceGui then
        surfaceGui = Instance.new("SurfaceGui")
        surfaceGui.Name = "CounterGUI"
        surfaceGui.Face = Enum.NormalId.Front
        surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        surfaceGui.PixelsPerStud = 50
        surfaceGui.Parent = counterAnchor
        
        -- Background frame for the progress bar (bigger)
        local backgroundFrame = Instance.new("Frame")
        backgroundFrame.Name = "BackgroundFrame"
        backgroundFrame.Size = UDim2.new(0.9, 0, 0.6, 0)
        backgroundFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
        backgroundFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        backgroundFrame.BorderSizePixel = 2
        backgroundFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)
        backgroundFrame.Parent = surfaceGui
        
        -- Progress bar fill
        local progressBar = Instance.new("Frame")
        progressBar.Name = "ProgressBar"
        progressBar.Size = UDim2.new(0, 0, 1, 0)
        progressBar.Position = UDim2.new(0, 0, 0, 0)
        progressBar.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
        progressBar.BorderSizePixel = 0
        progressBar.Parent = backgroundFrame
        
        -- Text label (inside the progress bar)
        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "CounterText"
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.Position = UDim2.new(0, 0, 0, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextSize = 36
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        textLabel.TextStrokeTransparency = 0
        textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        textLabel.TextXAlignment = Enum.TextXAlignment.Center
        textLabel.TextYAlignment = Enum.TextYAlignment.Center
        textLabel.ZIndex = 2
        textLabel.Parent = backgroundFrame
    end
    
    -- Update text and progress bar
    local backgroundFrame = surfaceGui:FindFirstChild("BackgroundFrame")
    local textLabel = backgroundFrame and backgroundFrame:FindFirstChild("CounterText")
    local progressBar = backgroundFrame and backgroundFrame:FindFirstChild("ProgressBar")
    
    if textLabel then
        textLabel.Text = string.format("Pets: %d/%d", count, MAX_PET_BALLS_PER_AREA)
    end
    
    -- Update progress bar
    if progressBar then
        local percentage = count / MAX_PET_BALLS_PER_AREA
        progressBar.Size = UDim2.new(percentage, 0, 1, 0)
        
        -- Change progress bar color based on percentage
        if percentage >= 1.0 then
            progressBar.BackgroundColor3 = Color3.fromRGB(255, 100, 100) -- Red when full
        elseif percentage >= 0.8 then
            progressBar.BackgroundColor3 = Color3.fromRGB(255, 200, 100) -- Orange when almost full
        else
            progressBar.BackgroundColor3 = Color3.fromRGB(100, 255, 100) -- Green when normal
        end
    end
end

-- Update processing pets counter GUI for a specific area
function PlotService:UpdateProcessingCounter(areaName, processingCount)
    local playerAreas = Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then return end
    
    local area = playerAreas:FindFirstChild(areaName)
    if not area then return end
    
    -- Find Deposit part in Tubes>Tubes
    local tubesFolder = area:FindFirstChild("Tubes")
    if not tubesFolder then return end
    
    local innerTubesFolder = tubesFolder:FindFirstChild("Tubes")
    if not innerTubesFolder then return end
    
    local deposit = innerTubesFolder:FindFirstChild("Deposit")
    if not deposit then return end
    
    -- Find Cube.005 inside Deposit
    local cube005 = deposit:FindFirstChild("Cube.005")
    if not cube005 then return end
    
    -- Find or create SurfaceGui
    local surfaceGui = cube005:FindFirstChild("ProcessingCounterGUI")
    if not surfaceGui then
        surfaceGui = Instance.new("SurfaceGui")
        surfaceGui.Name = "ProcessingCounterGUI"
        surfaceGui.Face = Enum.NormalId.Front
        surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        surfaceGui.PixelsPerStud = 50
        surfaceGui.Parent = cube005
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "ProcessingCounterText"
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextSize = 32
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        textLabel.TextStrokeTransparency = 0
        textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        textLabel.TextXAlignment = Enum.TextXAlignment.Center
        textLabel.TextYAlignment = Enum.TextYAlignment.Center
        -- No rotation - horizontal text
        textLabel.Parent = surfaceGui
    end
    
    -- Update text
    local textLabel = surfaceGui:FindFirstChild("ProcessingCounterText")
    if textLabel then
        textLabel.Text = string.format("Processing: %d", processingCount)
        
        -- Color based on count
        if processingCount > 0 then
            textLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold when processing
        else
            textLabel.TextColor3 = Color3.fromRGB(150, 150, 150) -- Gray when not processing
        end
    end
end

-- Handle pet ball collection notification from client
function PlotService:OnPetBallCollected(ballPath)
    -- Find which area this ball belonged to by parsing the path
    local areaName = ballPath:match("%.PlayerAreas%.([^%.]+)%.")
    
    if areaName and areaPetBallCounts[areaName] then
        -- Decrement counter
        areaPetBallCounts[areaName] = math.max(0, areaPetBallCounts[areaName] - 1)
        
        -- Update GUI
        self:UpdateCounterGUI(areaName, areaPetBallCounts[areaName])
    end
end

-- Reinitialize a player's area after data reset
function PlotService:ReinitializePlayerArea(player)
    print("PlotService: Reinitializing area for player", player.Name)
    
    -- Get player's assigned area from AreaService
    local AreaService = require(script.Parent.AreaService)
    local assignedAreaNumber = AreaService:GetPlayerAssignedArea(player)
    
    if not assignedAreaNumber then
        print("PlotService: No area assigned to player", player.Name)
        return
    end
    
    local playerAreas = Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then
        print("PlotService: No PlayerAreas found")
        return
    end
    
    local targetArea = playerAreas:FindFirstChild("PlayerArea" .. assignedAreaNumber)
    if not targetArea then
        print("PlotService: Area not found for player", player.Name)
        return
    end
    
    print("PlotService: Found area", targetArea.Name, "for player", player.Name)
    
    -- Reset all doors to red (locked)
    self:ColorAllDoorsInArea(targetArea, Color3.fromRGB(255, 0, 0))
    
    -- Reset all tubes to hidden (locked)
    self:HideAllTubesInArea(targetArea)
    
    -- Show all plot UIs again (since player owns no plots after reset)
    self:RestoreAllPlotUIs(targetArea)
    
    -- Show all TubePlot UIs again
    self:RestoreAllTubePlotUIs(targetArea)
    
    -- Initialize doors and tubes for any owned plots/tubes (should be none after reset)
    self:InitializeAreaDoors(targetArea)
    self:InitializeAreaTubes(targetArea)
    
    -- Update plot GUIs and visibility
    self:UpdatePlotGUIs(targetArea, player)
    self:UpdatePlotColors(targetArea, player)
    self:UpdatePlotVisibility(targetArea, player)
    
    print("PlotService: Area reinitialized for player", player.Name)
end

-- Restore all plot UIs in an area (after data reset)
function PlotService:RestoreAllPlotUIs(area)
    for i = 1, TOTAL_PLOTS do
        -- Check if UI already exists
        local uiPart = area:FindFirstChild("PlotUI_" .. i)
        if not uiPart then
            -- Recreate the UI
            local buttonsFolder = area:FindFirstChild("Buttons")
            if buttonsFolder then
                local plot = buttonsFolder:FindFirstChild("Plot" .. i)
                if plot then
                    self:CreatePlotUI(area, plot, i)
                    
                    -- Initially hide UI (proximity will show them)
                    local newUiPart = area:FindFirstChild("PlotUI_" .. i)
                    if newUiPart then
                        newUiPart.Transparency = 1
                        local billboard = newUiPart:FindFirstChild("PlotBillboard")
                        if billboard then
                            billboard.Enabled = false
                        end
                    end
                end
            end
        end
    end
end

-- Restore all TubePlot UIs in an area (after data reset)
function PlotService:RestoreAllTubePlotUIs(area)
    for i = 1, TOTAL_TUBEPLOTS do
        -- Check if UI already exists
        local uiPart = area:FindFirstChild("TubePlotUI_" .. i)
        if not uiPart then
            -- Recreate the UI
            local buttonsFolder = area:FindFirstChild("Buttons")
            if buttonsFolder then
                local tubePlot = buttonsFolder:FindFirstChild("TubePlot" .. i)
                if tubePlot then
                    self:CreateTubePlotUI(area, tubePlot, i)
                    
                    -- Initially hide UI (proximity will show them)
                    local newUiPart = area:FindFirstChild("TubePlotUI_" .. i)
                    if newUiPart then
                        newUiPart.Transparency = 1
                        local billboard = newUiPart:FindFirstChild("TubePlotBillboard")
                        if billboard then
                            billboard.Enabled = false
                        end
                    end
                end
            end
        end
    end
end

-- Play button press animation for a plot
function PlotService:PlayPlotPressAnimation(area, plotNumber, isTubePlot)
    local TweenService = game:GetService("TweenService")
    
    local plotName = isTubePlot and ("TubePlot" .. plotNumber) or ("Plot" .. plotNumber)
    
    -- Look for plot in Buttons folder first, then in area directly
    local plot = nil
    local buttonsFolder = area:FindFirstChild("Buttons")
    if buttonsFolder then
        plot = buttonsFolder:FindFirstChild(plotName)
    end
    if not plot then
        plot = area:FindFirstChild(plotName)
    end
    
    if plot and plot:IsA("Model") then
        local cube009 = plot:FindFirstChild("Cube.009")
        if cube009 and cube009:IsA("BasePart") then
            -- Store original position
            local originalPosition = cube009.Position
            
            -- Tween down (button press)
            local pressDownTween = TweenService:Create(
                cube009,
                TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Position = originalPosition - Vector3.new(0, 0.5, 0)}
            )
            
            -- Tween back up
            local pressUpTween = TweenService:Create(
                cube009,
                TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Position = originalPosition}
            )
            
            -- Play press down, then press up
            pressDownTween:Play()
            pressDownTween.Completed:Connect(function()
                pressUpTween:Play()
            end)
        end
    end
end

-- Update plot and tubeplot visibility based on player rebirth level
function PlotService:UpdatePlotVisibility(area, player)
    local areaNumber = tonumber(area.Name:match("PlayerArea(%d+)"))
    if not areaNumber then
        return
    end
    
    -- If no specific player provided, find the assigned player for this area
    if not player then
        local AreaService = require(script.Parent.AreaService)
        -- Find which player is assigned to this area
        for _, areaPlayer in pairs(Players:GetPlayers()) do
            local playerArea = AreaService:GetPlayerAssignedArea(areaPlayer)
            if playerArea == areaNumber then
                player = areaPlayer
                break
            end
        end
    end
    
    -- If still no player, default to showing plots for rebirth level 0-1
    local playerRebirths = 0
    if player then
        local playerData = DataService:GetPlayerData(player)
        playerRebirths = playerData and playerData.Resources and playerData.Resources.Rebirths or 0
    end
    
    local buttonsFolder = area:FindFirstChild("Buttons")
    if not buttonsFolder then
        return
    end
    
    -- Get player's owned plots for level/door GUI management
    local ownedPlots = {}
    if player then
        local ownedPlotsArray = self:GetPlayerOwnedPlots(player)
        for _, plotNumber in pairs(ownedPlotsArray) do
            ownedPlots[plotNumber] = true
        end
    end
    
    -- Update plot visibility
    for i = 1, TOTAL_PLOTS do
        local plotName = "Plot" .. i
        local plot = buttonsFolder:FindFirstChild(plotName)
        
        if plot then
            local plotRebirthRequirement = getPlotRebirthRequirement(i)
            local shouldShowPlot = playerRebirths >= (plotRebirthRequirement - 1) -- Can see current level + next level
            
            -- Hide/show the entire plot model
            if plot:IsA("Model") then
                for _, part in pairs(plot:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Transparency = shouldShowPlot and 0 or 1
                        part.CanCollide = shouldShowPlot
                    end
                end
            elseif plot:IsA("BasePart") then
                plot.Transparency = shouldShowPlot and 0 or 1
                plot.CanCollide = shouldShowPlot
            end
            
            -- Manage level/door GUI based on visibility only (show on both owned and unowned visible plots)
            if shouldShowPlot then
                -- Plot is visible - add level/door GUI if not already present
                self:AddLevelDoorSurfaceGui(plot, i)
            else
                -- Plot is invisible - remove level/door GUI if present
                self:RemoveLevelDoorSurfaceGui(plot)
            end
        end
    end
    
    -- Update tubeplot visibility
    for i = 1, TOTAL_TUBEPLOTS do
        local tubePlotName = "TubePlot" .. i
        local tubePlot = buttonsFolder:FindFirstChild(tubePlotName)
        
        if tubePlot then
            local tubePlotRebirthRequirement = getTubePlotRebirthRequirement(i)
            local shouldShowTubePlot = playerRebirths >= (tubePlotRebirthRequirement - 1) -- Can see current level + next level
            
            -- Hide/show the entire tubeplot model
            if tubePlot:IsA("Model") then
                for _, part in pairs(tubePlot:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Transparency = shouldShowTubePlot and 0 or 1
                        part.CanCollide = shouldShowTubePlot
                    end
                end
            elseif tubePlot:IsA("BasePart") then
                tubePlot.Transparency = shouldShowTubePlot and 0 or 1
                tubePlot.CanCollide = shouldShowTubePlot
            end
            
            -- Manage tube number GUI based on visibility (show on all visible tube plots)
            if shouldShowTubePlot then
                -- Tube plot is visible - add tube number GUI if not already present
                self:AddTubeNumberSurfaceGui(tubePlot, i)
            else
                -- Tube plot is invisible - remove tube number GUI if present
                self:RemoveTubeNumberSurfaceGui(tubePlot)
            end
        end
    end
end

-- Create plot UIs for newly unlocked rebirth tiers
function PlotService:CreateNewRebirthTierUIs(area, player)
    if not player then
        return
    end
    
    local playerData = DataService:GetPlayerData(player)
    if not playerData then
        return
    end
    
    local playerRebirths = playerData.Resources and playerData.Resources.Rebirths or 0
    local buttonsFolder = area:FindFirstChild("Buttons")
    if not buttonsFolder then
        return
    end
    
    -- Create plot UIs for the next rebirth tier (current + 1)
    for i = 1, TOTAL_PLOTS do
        local plotRebirthRequirement = getPlotRebirthRequirement(i)
        -- If this plot should be visible at current rebirth level + 1, but UI doesn't exist yet
        if playerRebirths >= (plotRebirthRequirement - 1) then
            local uiPart = area:FindFirstChild("PlotUI_" .. i)
            if not uiPart then
                local plotName = "Plot" .. i
                local plot = buttonsFolder:FindFirstChild(plotName)
                if plot then
                    self:CreatePlotUI(area, plot, i)
                    
                    -- Initially hide UI (proximity will show them)
                    local newUiPart = area:FindFirstChild("PlotUI_" .. i)
                    if newUiPart then
                        newUiPart.Transparency = 1
                        local billboard = newUiPart:FindFirstChild("PlotBillboard")
                        if billboard then
                            billboard.Enabled = false
                        end
                    end
                end
            end
        end
    end
    
    -- Create tubeplot UIs for the next rebirth tier (current + 1)
    for i = 1, TOTAL_TUBEPLOTS do
        local tubePlotRebirthRequirement = getTubePlotRebirthRequirement(i)
        -- If this tubeplot should be visible at current rebirth level + 1, but UI doesn't exist yet
        if playerRebirths >= (tubePlotRebirthRequirement - 1) then
            local uiPart = area:FindFirstChild("TubePlotUI_" .. i)
            if not uiPart then
                local tubePlotName = "TubePlot" .. i
                local tubePlot = buttonsFolder:FindFirstChild(tubePlotName)
                if tubePlot then
                    self:CreateTubePlotUI(area, tubePlot, i)
                    
                    -- Initially hide UI (proximity will show them)
                    local newUiPart = area:FindFirstChild("TubePlotUI_" .. i)
                    if newUiPart then
                        newUiPart.Transparency = 1
                        local billboard = newUiPart:FindFirstChild("TubePlotBillboard")
                        if billboard then
                            billboard.Enabled = false
                        end
                    end
                end
            end
        end
    end
end

-- Update plot and tubeplot GUIs based on player status
function PlotService:UpdatePlotGUIs(area, player)
    if not player then
        return
    end
    
    local playerData = DataService:GetPlayerData(player)
    if not playerData then
        return
    end
    
    -- First, create any missing UIs for newly unlocked rebirth tiers
    self:CreateNewRebirthTierUIs(area, player)
    
    local playerRebirths = playerData.Resources and playerData.Resources.Rebirths or 0
    local playerMoney = playerData.Resources and playerData.Resources.Money or 0
    local ownedPlots = self:GetPlayerOwnedPlots(player)
    local ownedTubes = self:GetPlayerOwnedTubes(player)
    
    -- Create sets for faster lookup
    local ownedPlotsSet = {}
    for _, plotNumber in pairs(ownedPlots) do
        ownedPlotsSet[plotNumber] = true
    end
    
    local ownedTubesSet = {}
    for _, tubeNumber in pairs(ownedTubes) do
        ownedTubesSet[tubeNumber] = true
    end
    
    -- Update plot GUIs
    for plotNumber = 1, TOTAL_PLOTS do
        if plotNumber ~= 6 and plotNumber ~= 7 then
            local uiPart = area:FindFirstChild("PlotUI_" .. plotNumber)
            if uiPart then
                local billboard = uiPart:FindFirstChild("PlotBillboard")
                if billboard then
                    local costLabel = billboard:FindFirstChild("CostLabel")
                    if costLabel then
                        local requiredRebirths = getPlotRebirthRequirement(plotNumber)
                        local plotCost = self:GetPlotCost(plotNumber)
                        
                        if ownedPlotsSet[plotNumber] then
                            -- White text for purchased plots
                            costLabel.Text = "Purchased"
                            costLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                            costLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                            costLabel.TextSize = 24
                        elseif playerRebirths < requiredRebirths then
                            -- Only show rebirth requirement on middle plot of row
                            if isMiddlePlotOfRow(plotNumber) then
                                -- Large black text with white outline for rebirth requirement
                                costLabel.Text = requiredRebirths .. " Rebirths Required"
                                costLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
                                costLabel.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
                                costLabel.TextSize = 36 -- Larger text for visibility
                            else
                                -- Hide text on non-middle plots that need rebirths
                                costLabel.Text = ""
                            end
                        elseif playerMoney >= plotCost then
                            -- Green text for affordable plots
                            costLabel.Text = plotCost == 0 and "FREE" or ("$" .. plotCost)
                            costLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                            costLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                            costLabel.TextSize = 24
                        else
                            -- Red text for unaffordable plots
                            costLabel.Text = plotCost == 0 and "FREE" or ("$" .. plotCost)
                            costLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                            costLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                            costLabel.TextSize = 24
                        end
                    end
                end
            end
        end
    end
    
    -- Update tubeplot GUIs
    for tubeNumber = 1, TOTAL_TUBEPLOTS do
        local uiPart = area:FindFirstChild("TubePlotUI_" .. tubeNumber)
        if uiPart then
            local billboard = uiPart:FindFirstChild("TubePlotBillboard")
            if billboard then
                local costLabel = billboard:FindFirstChild("CostLabel")
                if costLabel then
                    local requiredRebirths = getTubePlotRebirthRequirement(tubeNumber)
                    local tubePlotCost = self:GetTubePlotCost(tubeNumber)
                    
                    if ownedTubesSet[tubeNumber] then
                        -- Orange text for purchased tubeplots
                        costLabel.Text = "Purchased"
                        costLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
                        costLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                        costLabel.TextSize = 24
                    elseif playerRebirths < requiredRebirths then
                        -- Only show rebirth requirement on first inaccessible tubeplot
                        if shouldShowTubePlotRebirthText(tubeNumber, playerRebirths) then
                            -- Large black text with white outline for rebirth requirement
                            costLabel.Text = requiredRebirths .. " Rebirths Required"
                            costLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
                            costLabel.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
                            costLabel.TextSize = 36 -- Larger text for visibility
                        else
                            -- Hide text on other tubeplots that need rebirths
                            costLabel.Text = ""
                        end
                    elseif playerMoney >= tubePlotCost then
                        -- Green text for affordable tubeplots
                        costLabel.Text = tubePlotCost == 0 and "FREE" or ("$" .. tubePlotCost)
                        costLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                        costLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                        costLabel.TextSize = 24
                    else
                        -- Red text for unaffordable tubeplots
                        costLabel.Text = tubePlotCost == 0 and "FREE" or ("$" .. tubePlotCost)
                        costLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                        costLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                        costLabel.TextSize = 24
                    end
                end
            end
        end
    end
end

-- Update plot colors based on ownership and affordability
function PlotService:UpdatePlotColors(area, player)
    if not player then
        return
    end
    
    local ownedPlots = self:GetPlayerOwnedPlots(player)
    local ownedTubes = self:GetPlayerOwnedTubes(player)
    
    -- Create sets for faster lookup
    local ownedPlotsSet = {}
    for _, plotNumber in pairs(ownedPlots) do
        ownedPlotsSet[plotNumber] = true
    end
    
    local ownedTubesSet = {}
    for _, tubeNumber in pairs(ownedTubes) do
        ownedTubesSet[tubeNumber] = true
    end
    
    -- Only add "Purchased" SurfaceGuis for owned plots/tubes
    for plotNumber = 1, TOTAL_PLOTS do
        if plotNumber ~= 6 and plotNumber ~= 7 and ownedPlotsSet[plotNumber] then
            local buttonsFolder = area:FindFirstChild("Buttons")
            if buttonsFolder then
                local plot = buttonsFolder:FindFirstChild("Plot" .. plotNumber)
                if plot then
                    self:AddPurchasedSurfaceGui(area, plot)
                end
            end
        end
    end
    
    for tubeNumber = 1, TOTAL_TUBEPLOTS do
        if ownedTubesSet[tubeNumber] then
            local buttonsFolder = area:FindFirstChild("Buttons")
            if buttonsFolder then
                local tubePlot = buttonsFolder:FindFirstChild("TubePlot" .. tubeNumber)
                if tubePlot then
                    self:AddPurchasedSurfaceGui(area, tubePlot)
                end
            end
        end
    end
end

-- Clear all pet balls in a player's area
function PlotService:ClearAllPetBallsInPlayerArea(player)
    -- Get player's assigned area
    local AreaService = require(script.Parent.AreaService)
    local assignedAreaNumber = AreaService:GetPlayerAssignedArea(player)
    
    if not assignedAreaNumber then
        return
    end
    
    local playerAreas = Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then
        return
    end
    
    local area = playerAreas:FindFirstChild("PlayerArea" .. assignedAreaNumber)
    if not area then
        return
    end
    
    -- Find and destroy all pet balls in the area
    for _, descendant in pairs(area:GetDescendants()) do
        if descendant.Name == "PetBall" and descendant:IsA("BasePart") then
            descendant:Destroy()
        end
    end
    
    -- Reset counter for this area
    local areaName = "PlayerArea" .. assignedAreaNumber
    areaPetBallCounts[areaName] = 0
    self:UpdateCounterGUI(areaName, 0)
end

-- Debug function to manually update plot colors for all players
function PlotService:DebugUpdateAllPlotColors()
    -- Manually updating plot colors for all players
    
    local Players = game:GetService("Players")
    local AreaService = require(script.Parent.AreaService)
    
    for _, player in pairs(Players:GetPlayers()) do
        local assignedAreaNumber = AreaService:GetPlayerAssignedArea(player)
        if assignedAreaNumber then
            local playerAreas = Workspace:FindFirstChild("PlayerAreas")
            if playerAreas then
                local area = playerAreas:FindFirstChild("PlayerArea" .. assignedAreaNumber)
                if area then
                    -- Updating GUIs and visibility for player
                    self:UpdatePlotGUIs(area, player)
                    self:UpdatePlotColors(area, player)
                    self:UpdatePlotVisibility(area, player)
                end
            end
        end
    end
end

return PlotService