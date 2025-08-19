-- PlotService - Handles plot purchasing and management
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")

local DataService = require(script.Parent.DataService)
local PlotConfig = require(ReplicatedStorage.config.PlotConfig)

local PlotService = {}
PlotService.__index = PlotService

-- Configuration - Now centralized in PlotConfig
local UI_VISIBILITY_DISTANCE = 50 -- Distance to show plot UIs

-- Sound configuration
local PLOT_PURCHASE_SOUND_ID = "rbxassetid://1172510525"
local TUBE_PURCHASE_SOUND_ID = "rbxassetid://98585875176475" 
local SOUND_COOLDOWN = 0.5 -- Prevent spam by limiting sounds to every 0.5 seconds per player

-- Track last sound time per player to prevent spam
local lastSoundTime = {}

-- Helper function to play purchase sounds with anti-spam protection
local function playPurchaseSound(player, soundId)
    local currentTime = tick()
    local playerId = player.UserId
    
    -- Check if enough time has passed since last sound for this player
    if lastSoundTime[playerId] and (currentTime - lastSoundTime[playerId]) < SOUND_COOLDOWN then
        return -- Skip sound due to cooldown
    end
    
    -- Update last sound time
    lastSoundTime[playerId] = currentTime
    
    -- Play sound for the player
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = 0.5
    sound.Parent = SoundService
    
    -- Play sound and clean up
    sound:Play()
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
    
    -- Fallback cleanup in case Ended doesn't fire
    task.spawn(function()
        task.wait(5)
        if sound and sound.Parent then
            sound:Destroy()
        end
    end)
end

-- Level and door mapping now centralized in PlotConfig.LEVEL_CONFIG

-- Store plot connections for cleanup
local plotConnections = {}

-- Store doors that are spawning pets
local spawningDoors = {}

-- Note: Pet ball counting is now handled client-side
local MAX_PET_BALLS_PER_AREA = 50 -- Kept for GUI display purposes only

-- Helper functions now centralized in PlotConfig

-- Utility functions for common patterns
function PlotService:GetPlayerAreaModel(player)
    local AreaService = require(script.Parent.AreaService)
    local assignedAreaNumber = AreaService:GetPlayerAssignedArea(player)
    
    if not assignedAreaNumber then
        return nil
    end
    
    local playerAreas = Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then
        return nil
    end
    
    return playerAreas:FindFirstChild("PlayerArea" .. assignedAreaNumber), assignedAreaNumber
end

function PlotService:GetPlayerDataSafe(player)
    local playerData = DataService:GetPlayerData(player)
    if not playerData then
        return nil
    end
    return playerData
end

function PlotService:CreateOwnedPlotsSet(ownedPlotsArray)
    local ownedPlots = {}
    for _, plotNumber in pairs(ownedPlotsArray) do
        ownedPlots[plotNumber] = true
    end
    return ownedPlots
end

function PlotService:CreateOwnedTubesSet(ownedTubesArray)
    local ownedTubes = {}
    for _, tubeNumber in pairs(ownedTubesArray) do
        ownedTubes[tubeNumber] = true
    end
    return ownedTubes
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
        boundaryPart.CanCollide = false     -- Disable collision for mouse raycasting
        boundaryPart.Transparency = 1       -- Invisible
        boundaryPart.CanTouch = true        -- Enable touch detection (this is what pet balls actually use)
        boundaryPart.CollisionGroup = "PetBallBoundaries"
    end
    
    -- Listen for new boundary parts being tagged
    CollectionService:GetInstanceAddedSignal("PetBallBoundary"):Connect(function(part)
        part.CanCollide = false     -- Disable collision for mouse raycasting
        part.Transparency = 1
        part.CanTouch = true        -- Enable touch detection (this is what pet balls actually use)
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
    
    -- Clean up sound tracking when players leave to prevent memory leaks
    Players.PlayerRemoving:Connect(function(player)
        lastSoundTime[player.UserId] = nil
    end)
end

function PlotService:SetupAreaPlots(area)
    local buttonsFolder = area:FindFirstChild("Buttons")
    if not buttonsFolder then
        warn("PlotService: No Buttons folder found in " .. area.Name)
        return
    end
    
    -- Note: Door GUIs are pre-created in AreaTemplate and copied automatically
    
    -- Set up touch detection for each plot
    for i = 1, PlotConfig.TOTAL_PLOTS do
        local plotName = "Plot" .. i
        local plot = buttonsFolder:FindFirstChild(plotName)
        
        if plot then
            self:SetupPlotPurchasing(area, plot, i)
            
            -- Plot UI creation is now handled client-side by PlotGUIService
        end
    end
    
    -- Set up touch detection for each TubePlot
    for i = 1, PlotConfig.TOTAL_TUBEPLOTS do
        local tubePlotName = "TubePlot" .. i
        local tubePlot = buttonsFolder:FindFirstChild(tubePlotName)
        
        if tubePlot then
            self:SetupTubePlotPurchasing(area, tubePlot, i)
            
            -- TubePlot UI creation is now handled client-side by PlotGUIService
        end
    end
    
    -- Set up SendHeaven button
    self:SetupSendHeavenButton(area)
    
    -- UI updates for plots are now handled client-side by PlotGUIService via Rodux
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
    -- Color pet mixer black (locked state)
    self:ColorPetMixerInArea(area, Color3.fromRGB(0, 0, 0))
    -- Create initial counter GUI structure (client handles updates)
    self:CreateCounterGUI(area.Name)
    
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
                -- GUI updates now handled client-side by PlotGUIService via Rodux
                self:UpdatePlotColors(area, player) -- Add "Purchased" SurfaceGuis for owned plots
                self:UpdatePlotVisibility(area, player)
                break
            end
        end
    end
end


function PlotService:SetupPurchasing(area, purchaseObject, objectNumber, isPlot)
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
        
        -- Attempt to purchase based on type
        if isPlot then
            self:AttemptPlotPurchase(player, objectNumber)
        else
            self:AttemptTubePlotPurchase(player, objectNumber)
        end
    end
    
    -- Connect to all parts in the object (in case it's a model with multiple parts)
    if purchaseObject:IsA("Model") then
        for _, part in pairs(purchaseObject:GetDescendants()) do
            if part:IsA("BasePart") then
                local connection = part.Touched:Connect(onTouch)
                table.insert(plotConnections, connection)
            end
        end
    elseif purchaseObject:IsA("BasePart") then
        local connection = purchaseObject.Touched:Connect(onTouch)
        table.insert(plotConnections, connection)
    end
end

-- Convenience wrappers for backward compatibility
function PlotService:SetupPlotPurchasing(area, plot, plotNumber)
    self:SetupPurchasing(area, plot, plotNumber, true)
end

function PlotService:SetupTubePlotPurchasing(area, tubePlot, tubePlotNumber)
    self:SetupPurchasing(area, tubePlot, tubePlotNumber, false)
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

-- CreatePlotUI function removed - GUI creation is now handled client-side by PlotGUIService

-- CreateTubePlotUI function removed - GUI creation is now handled client-side by PlotGUIService

function PlotService:AttemptPlotPurchase(player, plotNumber)
    local playerData = self:GetPlayerDataSafe(player)
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
    local requiredRebirths = PlotConfig.getPlotRebirthRequirement(plotNumber)
    local playerRebirths = playerData.Resources and playerData.Resources.Rebirths or 0
    if playerRebirths < requiredRebirths then
        return false
    end
    
    -- Check if player has enough money
    local plotCost = PlotConfig.getPlotCost(plotNumber, playerRebirths)
    if playerData.Resources.Money < plotCost then
        -- Not enough money
        return false
    end
    
    -- Purchase the plot
    local success = DataService:UpdatePlayerResources(player, "Money", -plotCost)
    if success then
        DataService:AddOwnedPlot(player, plotNumber)
        -- DataService methods automatically sync to client Rodux store
        
        -- Play plot purchase sound with anti-spam protection
        playPurchaseSound(player, PLOT_PURCHASE_SOUND_ID)
        
        -- Note: Plot UI updates are handled client-side by PlotGUIService via Rodux state changes
        
        -- Unlock the corresponding door
        self:UnlockDoorForPlot(player, plotNumber)
        
        -- Play button press animation and update plot colors in player's area
        local area, assignedAreaNumber = self:GetPlayerAreaModel(player)
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
        
        return true
    end
    
    return false
end

function PlotService:AttemptTubePlotPurchase(player, tubePlotNumber)
    local playerData = self:GetPlayerDataSafe(player)
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
    local requiredRebirths = PlotConfig.getTubePlotRebirthRequirement(tubePlotNumber)
    local playerRebirths = playerData.Resources and playerData.Resources.Rebirths or 0
    if playerRebirths < requiredRebirths then
        return false
    end
    
    -- Check if player has enough money
    local tubePlotCost = PlotConfig.getTubePlotCost(tubePlotNumber, playerRebirths)
    if playerData.Resources.Money < tubePlotCost then
        -- Not enough money
        return false
    end
    
    -- Purchase the TubePlot
    local success = DataService:UpdatePlayerResources(player, "Money", -tubePlotCost)
    if success then
        DataService:AddOwnedTube(player, tubePlotNumber)
        -- DataService methods automatically sync to client Rodux store
        
        -- Play tube purchase sound with anti-spam protection
        playPurchaseSound(player, TUBE_PURCHASE_SOUND_ID)
        
        -- Note: TubePlot UI updates are handled client-side by PlotGUIService via Rodux state changes
        
        -- Unlock the corresponding tube
        self:UnlockTubeForTubePlot(player, tubePlotNumber)
        
        -- Play button press animation and update plot colors in player's area
        local area, assignedAreaNumber = self:GetPlayerAreaModel(player)
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
        
        return true
    end
    
    return false
end

-- GetPlotCost and GetTubePlotCost wrapper functions removed - use PlotConfig directly

function PlotService:PlayerOwnsArea(player, areaNumber)
    -- Use AreaService to get the player's assigned area
    local AreaService = require(script.Parent.AreaService)
    local assignedAreaNumber = AreaService:GetPlayerAssignedArea(player)
    
    -- Player owns the area if it matches their assigned area
    return assignedAreaNumber == areaNumber
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
    textLabel.Text = "Owned"
    textLabel.Font = Enum.Font.FredokaOne
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
    textLabel.Font = Enum.Font.FredokaOne
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
    textLabel.Font = Enum.Font.FredokaOne
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

function PlotService:GetPlayerOwnedPlots(player)
    local playerData = self:GetPlayerDataSafe(player)
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
    local playerData = self:GetPlayerDataSafe(player)
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

-- UpdateAreaPlotUIs, UpdateAreaTubePlotUIs, UpdatePlayerAreaPlotUIs, and UpdatePlayerAreaTubePlotUIs functions removed
-- All UI updates are now handled client-side by PlotGUIService via Rodux state changes

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
    local playerData = self:GetPlayerDataSafe(player)
    local playerRebirths = playerData and playerData.Resources and playerData.Resources.Rebirths or 0
    
    -- Check each area for plot UIs
    for _, area in pairs(playerAreas:GetChildren()) do
        local areaNumber = tonumber(area.Name:match("PlayerArea(%d+)"))
        if areaNumber and self:PlayerOwnsArea(player, areaNumber) then
            -- Check each plot UI in this area
            for i = 1, PlotConfig.TOTAL_PLOTS do
                local uiPart = area:FindFirstChild("PlotUI_" .. i)
                if uiPart then
                    local distance = (playerPosition - uiPart.Position).Magnitude
                    local billboard = uiPart:FindFirstChild("PlotBillboard")
                    
                    -- Check if player should be able to see this plot
                    local plotRebirthRequirement = PlotConfig.getPlotRebirthRequirement(i)
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
            for i = 1, PlotConfig.TOTAL_TUBEPLOTS do
                local uiPart = area:FindFirstChild("TubePlotUI_" .. i)
                if uiPart then
                    local distance = (playerPosition - uiPart.Position).Magnitude
                    local billboard = uiPart:FindFirstChild("TubePlotBillboard")
                    
                    -- Check if player should be able to see this tubeplot
                    local tubePlotRebirthRequirement = PlotConfig.getTubePlotRebirthRequirement(i)
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
    
    for level, config in pairs(PlotConfig.LEVEL_CONFIG) do
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
    
    -- Remove locked emoji when door is unlocked
    self:UpdateDoorLockedEmoji(door, false)
    
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
            -- Wait 5 seconds before next spawn (faster spawn rate)
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
            -- GUI updates now handled client-side by PlotGUIService via Rodux
            self:UpdatePlotColors(area, player)
            self:UpdatePlotVisibility(area, player)
        end
    end
end

-- Color all doors in an area
function PlotService:ColorAllDoorsInArea(area, color)
    -- Go through all levels and color their doors
    for level = 1, 7 do
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
                        
                        -- Update locked emoji based on color
                        local isLocked = (color.R > 0.8 and color.G < 0.2 and color.B < 0.2) -- Red = locked
                        self:UpdateDoorLockedEmoji(door, isLocked)
                    end
                end
            end
        end
    end
end

function PlotService:UpdateDoorLockedEmoji(door, isLocked)
    -- Find the target part (same logic as AreaTemplateSetupService)
    local targetPart = nil
    if door:IsA("Model") then
        for _, part in pairs(door:GetDescendants()) do
            if part:IsA("BasePart") and (part.Name:lower():find("door") or part.Name:lower():find("main") or part.Size.Y > 5) then
                targetPart = part
                break
            end
        end
        if not targetPart then
            for _, part in pairs(door:GetDescendants()) do
                if part:IsA("BasePart") then
                    targetPart = part
                    break
                end
            end
        end
    elseif door:IsA("BasePart") then
        targetPart = door
    end
    
    if not targetPart then
        return
    end
    
    -- Clean up old emoji GUI if it exists
    local oldLockedGui = targetPart:FindFirstChild("DoorLockedGui")
    if oldLockedGui then
        oldLockedGui:Destroy()
    end
    
    -- Find or create door status GUI
    local statusGui = targetPart:FindFirstChild("DoorStatusGui")
    
    -- Always create/update the GUI to show appropriate icon
    if not statusGui then
        statusGui = Instance.new("SurfaceGui")
        statusGui.Name = "DoorStatusGui"
        statusGui.Face = Enum.NormalId.Left -- Same face as door labels
        statusGui.LightInfluence = 0
        statusGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        statusGui.PixelsPerStud = 49 -- Slightly different to avoid z-fighting
        statusGui.CanvasSize = Vector2.new(400, 400)
        statusGui.Parent = targetPart
        
        -- Create status icon
        local IconAssets = require(game.ReplicatedStorage.utils.IconAssets)
        local statusIcon = Instance.new("ImageLabel")
        statusIcon.Name = "StatusIcon"
        statusIcon.Size = UDim2.new(0.27, 0, 0.27, 0) -- 3x smaller (was 0.8, now ~0.27)
        statusIcon.Position = UDim2.new(0.365, 0, 0.365, 0) -- Centered for smaller icon
        statusIcon.BackgroundTransparency = 1
        statusIcon.ScaleType = Enum.ScaleType.Fit
        statusIcon.Rotation = 270 -- Same rotation as door labels
        statusIcon.ZIndex = 1 -- Lower ZIndex to appear behind door labels
        statusIcon.Parent = statusGui
    end
    
    -- Update the icon based on lock status
    local statusIcon = statusGui:FindFirstChild("StatusIcon")
    if statusIcon then
        local IconAssets = require(game.ReplicatedStorage.utils.IconAssets)
        if isLocked then
            -- Show locked icon
            statusIcon.Image = IconAssets.getIcon("STATUS", "LOCKED")
            statusIcon.ImageColor3 = Color3.fromRGB(255, 100, 100) -- Red tint for locked
        else
            -- Show unlocked icon
            statusIcon.Image = IconAssets.getIcon("STATUS", "UNLOCKED")
            statusIcon.ImageColor3 = Color3.fromRGB(100, 255, 100) -- Green tint for unlocked
        end
    end
    
    -- Always enable the GUI (we always want to show status)
    statusGui.Enabled = true
end

-- Color pet mixer and mixer button in an area and manage requirement GUI visibility
function PlotService:ColorPetMixerInArea(area, color)
    -- Find the PetMixer model
    local petMixer = area:FindFirstChild("PetMixer", true)
    if petMixer then
        -- Special handling for restoring original colors
        if color == "RESTORE_ORIGINAL" then
            -- Store original colors if not already stored
            if not petMixer:GetAttribute("OriginalColorsStored") then
                self:StoreOriginalMixerColors(petMixer)
            end
            -- Restore original colors
            self:RestoreOriginalMixerColors(petMixer)
        else
            -- Store original colors before changing (if not already stored)
            if not petMixer:GetAttribute("OriginalColorsStored") then
                self:StoreOriginalMixerColors(petMixer)
            end
            -- Apply new color
            local function colorPart(part)
                if part:IsA("BasePart") then
                    part.Color = color
                end
            end
            
            if petMixer:IsA("Model") then
                for _, descendant in pairs(petMixer:GetDescendants()) do
                    colorPart(descendant)
                end
            elseif petMixer:IsA("BasePart") then
                colorPart(petMixer)
            end
        end
    end
    
    -- Find and color the PetMixerButton
    local mixerButton = area:FindFirstChild("PetMixerButton", true)
    if mixerButton then
        -- Special handling for restoring original colors
        if color == "RESTORE_ORIGINAL" then
            -- Store original colors if not already stored
            if not mixerButton:GetAttribute("OriginalColorsStored") then
                self:StoreOriginalMixerColors(mixerButton)
            end
            -- Restore original colors
            self:RestoreOriginalMixerColors(mixerButton)
        else
            -- Store original colors before changing (if not already stored)
            if not mixerButton:GetAttribute("OriginalColorsStored") then
                self:StoreOriginalMixerColors(mixerButton)
            end
            -- Apply new color
            local function colorButtonPart(part)
                if part:IsA("BasePart") then
                    part.Color = color
                end
            end
            
            if mixerButton:IsA("Model") then
                for _, descendant in pairs(mixerButton:GetDescendants()) do
                    colorButtonPart(descendant)
                end
            elseif mixerButton:IsA("BasePart") then
                colorButtonPart(mixerButton)
            end
        end
        
        -- Show/hide requirement GUIs based on color/lock status
        local isLocked = (color ~= "RESTORE_ORIGINAL" and color.R < 0.2 and color.G < 0.2 and color.B < 0.2) -- Black = locked
        self:UpdateMixerRequirementGUI(mixerButton, isLocked, nil)
    end
end

-- Store original colors of mixer parts using attributes
function PlotService:StoreOriginalMixerColors(mixer)
    local function storePart(part)
        if part:IsA("BasePart") then
            -- Store original color as string attribute
            local colorString = string.format("%.3f,%.3f,%.3f", part.Color.R, part.Color.G, part.Color.B)
            part:SetAttribute("OriginalColor", colorString)
        end
    end
    
    if mixer:IsA("Model") then
        for _, descendant in pairs(mixer:GetDescendants()) do
            storePart(descendant)
        end
        mixer:SetAttribute("OriginalColorsStored", true)
    elseif mixer:IsA("BasePart") then
        storePart(mixer)
        mixer:SetAttribute("OriginalColorsStored", true)
    end
end

-- Restore original colors of mixer parts from attributes
function PlotService:RestoreOriginalMixerColors(mixer)
    local function restorePart(part)
        if part:IsA("BasePart") then
            local colorString = part:GetAttribute("OriginalColor")
            if colorString then
                local r, g, b = string.match(colorString, "([%d%.]+),([%d%.]+),([%d%.]+)")
                if r and g and b then
                    part.Color = Color3.fromRGB(tonumber(r) * 255, tonumber(g) * 255, tonumber(b) * 255)
                end
            end
        end
    end
    
    if mixer:IsA("Model") then
        for _, descendant in pairs(mixer:GetDescendants()) do
            restorePart(descendant)
        end
    elseif mixer:IsA("BasePart") then
        restorePart(mixer)
    end
end

-- Update mixer requirement GUI visibility based on lock status
function PlotService:UpdateMixerRequirementGUI(mixerButton, isLocked, player)
    -- Find the button part that should have the GUI
    local buttonPart = nil
    if mixerButton:IsA("Model") then
        -- Look for the main button part
        for _, part in pairs(mixerButton:GetDescendants()) do
            if part:IsA("BasePart") then
                buttonPart = part
                break
            end
        end
    elseif mixerButton:IsA("BasePart") then
        buttonPart = mixerButton
    end
    
    if not buttonPart then
        return
    end
    
    -- Always hide the static requirement GUIs since PetMixerButtonService handles mixer UI now
    local faces = {"Front", "Top", "Back"}
    for _, face in ipairs(faces) do
        local gui = buttonPart:FindFirstChild("MixerRequirementGui_" .. face)
        if gui then
            gui.Enabled = false -- Always disabled - let PetMixerButtonService handle mixer UI
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
            for i = 1, PlotConfig.TOTAL_TUBEPLOTS do
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
    
    -- Find the player who owns this area
    local areaNumber = tonumber(areaName:match("PlayerArea(%d+)"))
    if not areaNumber then
        return
    end
    
    local AreaService = require(script.Parent.AreaService)
    local targetPlayer = nil
    for _, player in pairs(Players:GetPlayers()) do
        if AreaService:GetPlayerAssignedArea(player) == areaNumber then
            targetPlayer = player
            break
        end
    end
    
    if not targetPlayer then
        return -- No player assigned to this area
    end
    
    -- Get door number and level for pet generation
    local doorNumber = tonumber(door.Name:match("Door(%d+)")) or 1
    local level = self:GetLevelFromDoor(door)
    
    -- Generate random pet data using NEW door-based system
    local PetConfig = require(ReplicatedStorage.config.PetConfig)
    local randomPetData = PetConfig.createRandomPetForLevelAndDoor(level, doorNumber)
    
    if not randomPetData then
        warn("PlotService: Failed to generate random pet data")
        return
    end
    
    -- Add level and door info to pet data for accurate rarity calculation
    randomPetData.SpawnLevel = level
    randomPetData.SpawnDoor = doorNumber
    
    -- Spawn logging removed for cleaner console output
    
    -- Get door position
    local doorPosition
    if door:IsA("Model") then
        local cframe, size = door:GetBoundingBox()
        doorPosition = cframe.Position
    else
        doorPosition = door.Position
    end
    
    -- Send spawn request to the target player's client for client-side pet ball creation
    local spawnPetBallRemote = ReplicatedStorage:FindFirstChild("SpawnPetBall")
    if spawnPetBallRemote then
        spawnPetBallRemote:FireClient(targetPlayer, doorPosition, randomPetData, areaName)
    end
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
    DataService:AddPet(player, petData)
    
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
    
    -- DataService:AddPetToPlayer automatically syncs to client Rodux store
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

-- Create initial counter GUI structure (client-side service handles updates)
function PlotService:CreateCounterGUI(areaName)
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
    
    -- Only create if it doesn't exist
    local surfaceGui = counterAnchor:FindFirstChild("CounterGUI")
    if surfaceGui then
        return -- Already exists
    end
    
    -- Create SurfaceGui
    surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Name = "CounterGUI"
    surfaceGui.Face = Enum.NormalId.Front
    surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surfaceGui.PixelsPerStud = 50
    surfaceGui.Parent = counterAnchor
    
    -- Create background frame for the progress bar
    local backgroundFrame = Instance.new("Frame")
    backgroundFrame.Name = "BackgroundFrame"
    backgroundFrame.Size = UDim2.new(0.9, 0, 0.6, 0)
    backgroundFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
    backgroundFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    backgroundFrame.BorderSizePixel = 2
    backgroundFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)
    backgroundFrame.Parent = surfaceGui
    
    -- Create progress bar fill
    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    progressBar.Position = UDim2.new(0, 0, 0, 0)
    progressBar.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = backgroundFrame
    
    -- Create text label
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "CounterText"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Position = UDim2.new(0, 0, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.FredokaOne
    textLabel.TextSize = 36
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.Text = "Pets: 0/" .. MAX_PET_BALLS_PER_AREA
    textLabel.ZIndex = 2
    textLabel.Parent = backgroundFrame
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
        textLabel.Font = Enum.Font.FredokaOne
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

-- Reinitialize a player's area after data reset
function PlotService:ReinitializePlayerArea(player)
    -- Get player's assigned area from AreaService
    local targetArea, assignedAreaNumber = self:GetPlayerAreaModel(player)
    if not targetArea then
        return
    end
    
    -- Reset all doors to red (locked)
    self:ColorAllDoorsInArea(targetArea, Color3.fromRGB(255, 0, 0))
    
    -- Reset all tubes to hidden (locked)
    self:HideAllTubesInArea(targetArea)
    
    -- Plot/TubePlot UI restoration is now handled client-side by PlotGUIService
    
    -- Initialize doors and tubes for any owned plots/tubes (should be none after reset)
    self:InitializeAreaDoors(targetArea)
    self:InitializeAreaTubes(targetArea)
    
    -- Update plot GUIs and visibility
    -- GUI updates now handled client-side by PlotGUIService via Rodux
    self:UpdatePlotColors(targetArea, player)
    self:UpdatePlotVisibility(targetArea, player)
    
end

-- RestoreAllPlotUIs and RestoreAllTubePlotUIs functions removed - GUI creation is now handled client-side by PlotGUIService

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

-- Update level visibility based on rebirth requirements
function PlotService:UpdateLevelVisibility(area, playerRebirths)
    -- Level configuration mapping rebirths to levels
    local levelRebirthRequirements = {
        [1] = 0,  -- Level 1 unlocked at rebirth 0 (starting)
        [2] = 1,  -- Level 2 unlocked at rebirth 1
        [3] = 2,  -- Level 3 unlocked at rebirth 2
        [4] = 4,  -- Level 4 unlocked at rebirth 4 (skip rebirth 3)
        [5] = 5,  -- Level 5 unlocked at rebirth 5
        [6] = 6,  -- Level 6 unlocked at rebirth 6
        [7] = 7   -- Level 7 unlocked at rebirth 7
    }
    
    -- Scale levels based on unlock status
    for levelNumber = 1, 7 do
        local levelName = "Level" .. levelNumber
        local level = area:FindFirstChild(levelName)
        
        if level then
            local requiredRebirths = levelRebirthRequirements[levelNumber]
            local isUnlocked = playerRebirths >= requiredRebirths
            
            if level:IsA("Model") then
                -- Set scale for the entire level model
                if isUnlocked then
                    -- Scale to 0.8 when unlocked (visible)
                    self:ScaleModel(level, 0.8)
                else
                    -- Scale to 0 when locked (invisible)
                    self:ScaleModel(level, 0)
                end
            end
        end
    end
end

-- Helper function to scale a model 
function PlotService:ScaleModel(model, scale)
    if not model or not model:IsA("Model") then
        return
    end
    
    -- Simply scale the entire model - everything inside will scale automatically
    if scale == 0 then
        -- Make invisible by scaling to very small value (Roblox doesn't allow 0)
        model:ScaleTo(0.001)
    else
        -- Scale to the desired size (0.8 for unlocked)
        model:ScaleTo(scale)
    end
end

-- Update plot and tubeplot visibility based on player rebirth level
-- Helper function to find assigned player for area
function PlotService:FindAssignedPlayerForArea(areaNumber)
    local AreaService = require(script.Parent.AreaService)
    for _, player in pairs(Players:GetPlayers()) do
        local playerArea = AreaService:GetPlayerAssignedArea(player)
        if playerArea == areaNumber then
            return player
        end
    end
    return nil
end

-- Helper function to get player rebirth level
function PlotService:GetPlayerRebirthLevel(player)
    if not player then
        return 0
    end
    
    local playerData = self:GetPlayerDataSafe(player)
    return playerData and playerData.Resources and playerData.Resources.Rebirths or 0
end

-- Helper function to set object visibility
function PlotService:SetObjectVisibility(object, visible)
    if object:IsA("Model") then
        for _, part in pairs(object:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = visible and 0 or 1
                part.CanCollide = visible
            end
        end
    elseif object:IsA("BasePart") then
        object.Transparency = visible and 0 or 1
        object.CanCollide = visible
    end
end

-- Update plots visibility and GUI elements
function PlotService:UpdatePlotsVisibility(buttonsFolder, playerRebirths)
    for i = 1, PlotConfig.TOTAL_PLOTS do
        local plot = buttonsFolder:FindFirstChild("Plot" .. i)
        if plot then
            local rebirthRequirement = PlotConfig.getPlotRebirthRequirement(i)
            local shouldShow = playerRebirths >= (rebirthRequirement - 1)
            
            self:SetObjectVisibility(plot, shouldShow)
            
            if shouldShow then
                self:AddLevelDoorSurfaceGui(plot, i)
            else
                self:RemoveLevelDoorSurfaceGui(plot)
            end
        end
    end
end

-- Update tubeplots visibility and GUI elements  
function PlotService:UpdateTubePlotsVisibility(buttonsFolder, playerRebirths)
    for i = 1, PlotConfig.TOTAL_TUBEPLOTS do
        local tubePlot = buttonsFolder:FindFirstChild("TubePlot" .. i)
        if tubePlot then
            local rebirthRequirement = PlotConfig.getTubePlotRebirthRequirement(i)
            local shouldShow = playerRebirths >= (rebirthRequirement - 1)
            
            self:SetObjectVisibility(tubePlot, shouldShow)
            
            if shouldShow then
                self:AddTubeNumberSurfaceGui(tubePlot, i)
            else
                self:RemoveTubeNumberSurfaceGui(tubePlot)
            end
        end
    end
end

-- Main function - now much cleaner and focused
function PlotService:UpdatePlotVisibility(area, player)
    local areaNumber = tonumber(area.Name:match("PlayerArea(%d+)"))
    if not areaNumber then
        return
    end
    
    -- Find the assigned player if not provided
    player = player or self:FindAssignedPlayerForArea(areaNumber)
    
    -- Get player's rebirth level
    local playerRebirths = self:GetPlayerRebirthLevel(player)
    
    -- Update level visibility based on rebirth requirements
    self:UpdateLevelVisibility(area, playerRebirths)
    
    local buttonsFolder = area:FindFirstChild("Buttons")
    if not buttonsFolder then
        return
    end
    
    -- Update plots and tubeplots visibility
    self:UpdatePlotsVisibility(buttonsFolder, playerRebirths)
    self:UpdateTubePlotsVisibility(buttonsFolder, playerRebirths)
end

-- CreateNewRebirthTierUIs function removed - GUI creation is now handled client-side by PlotGUIService

-- Update plot and tubeplot GUIs based on player status
-- UpdatePlotGUIs function removed - all GUI updates are now handled client-side by PlotGUIService via Rodux state changes

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
    for plotNumber = 1, PlotConfig.TOTAL_PLOTS do
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
    
    for tubeNumber = 1, PlotConfig.TOTAL_TUBEPLOTS do
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
    
    -- Update mixer accessibility based on rebirth count
    self:UpdateMixerAccessibility(area, player)
end

-- Update mixer accessibility based on player's rebirth count
function PlotService:UpdateMixerAccessibility(area, player)
    if not player then
        return
    end
    
    -- Get player's rebirth count
    local DataService = require(script.Parent.DataService)
    local playerData = DataService:GetPlayerData(player)
    if not playerData or not playerData.Resources then
        return
    end
    
    local rebirthCount = playerData.Resources.Rebirths or 0
    
    -- Check if player has 3+ rebirths (unlocks mixer)
    if rebirthCount >= 3 then
        -- Unlock mixer - restore original colors
        self:ColorPetMixerInArea(area, "RESTORE_ORIGINAL") -- Restore original colors
    else
        -- Keep mixer locked - color it black  
        self:ColorPetMixerInArea(area, Color3.fromRGB(0, 0, 0)) -- Black mixer and button
    end
end

-- Clear all pet balls in a player's area (now sends client-side clear request)
function PlotService:ClearAllPetBallsInPlayerArea(player)
    -- Get player's assigned area
    local AreaService = require(script.Parent.AreaService)
    local assignedAreaNumber = AreaService:GetPlayerAssignedArea(player)
    
    if not assignedAreaNumber then
        return
    end
    
    local areaName = "PlayerArea" .. assignedAreaNumber
    
    -- Send clear request to client since balls are client-only
    local clearPetBallsRemote = ReplicatedStorage:FindFirstChild("ClearPetBalls")
    if clearPetBallsRemote then
        clearPetBallsRemote:FireClient(player, areaName)
    end
end


-- Reset player area data
function PlotService:ResetPlayerAreaData(player)
    local AreaService = require(script.Parent.AreaService)
    local assignedAreaNumber = AreaService:GetPlayerAssignedArea(player)
    
    if assignedAreaNumber then
        local areaName = "PlayerArea" .. assignedAreaNumber
        
        -- Note: Pet ball counters are now handled client-side
    end
end

-- Called when player data is reset to update door colors
function PlotService:OnPlayerDataReset(player)
    -- Updating door colors and plot states after reset
    
    local area, assignedAreaNumber = self:GetPlayerAreaModel(player)
    if not area then
        -- No assigned area found
        return
    end
    
    -- Resetting door colors after data reset
    
    -- Reset all doors to red (locked) since player has no plots now
    self:ColorAllDoorsInArea(area, Color3.fromRGB(255, 0, 0))
    
    -- Hide all tubes since player has no tube plots now
    self:HideAllTubesInArea(area)
    
    -- Stop all pet spawning (player has no owned doors)
    for doorKey, spawnCoroutine in pairs(spawningDoors) do
        if doorKey:find(area.Name) then
            task.cancel(spawnCoroutine)
            spawningDoors[doorKey] = nil
            -- Stopped pet spawning
        end
    end
    
    -- Update plot GUIs to show costs again (since no plots are owned)
    -- GUI updates now handled client-side by PlotGUIService via Rodux
    
    -- Update plot visibility based on rebirth level (should be 0 now)
    self:UpdatePlotVisibility(area, player)
    
    -- Lock pet mixer back to black since rebirths are now 0
    self:ColorPetMixerInArea(area, Color3.fromRGB(0, 0, 0))
    
    -- Successfully reset all plot states
end

return PlotService