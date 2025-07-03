-- Pet Growth Service
-- Core orchestration service for pet growing mechanics
-- Refactored to use modular controllers for better organization

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local PlotConfig = require(ReplicatedStorage.Shared.config.PlotConfig)
local PetConfig = require(ReplicatedStorage.Shared.config.PetConfig)
local Store = require(ReplicatedStorage.store)
local PlayerActions = require(ReplicatedStorage.store.actions.PlayerActions)

-- Import modular controllers
local PetModelFactory = require(script.Parent.controllers.PetModelFactory)
local PetAnimationController = require(script.Parent.controllers.PetAnimationController)
local PetStatusGUIController = require(script.Parent.controllers.PetStatusGUIController)

local PetGrowthService = {}
PetGrowthService.__index = PetGrowthService

local player = Players.LocalPlayer
local lastPlayerData = {} -- Cache player data
local playerAreaNumber = nil -- Store the player's assigned area number
local areaAssignments = {} -- Store area assignments from server
local activePets = {} -- Store active pets per plot {[plotId] = {model, growthTween, etc}}

-- Growth configuration
local PET_HOVER_HEIGHT = 3 -- studs above plot

-- Initialize controllers
local animationController = PetAnimationController
local guiController = PetStatusGUIController

function PetGrowthService:Initialize()
    local success, error = pcall(function()
        -- Wait for PlayerAreas to be created
        local playerAreas = Workspace:WaitForChild("PlayerAreas", 10)
        if not playerAreas then
            warn("PetGrowthService: PlayerAreas not found!")
            return false
        end
        
        -- Initialize controllers with error handling
        local animSuccess, animError = pcall(function()
            animationController:Initialize()
        end)
        if not animSuccess then
            warn("PetGrowthService: Failed to initialize animation controller:", animError)
        end
        
        local guiSuccess, guiError = pcall(function()
            guiController:Initialize()
        end)
        if not guiSuccess then
            warn("PetGrowthService: Failed to initialize GUI controller:", guiError)
        end
        
        return true
    end)
    
    if not success then
        warn("PetGrowthService: Initialization failed:", error)
        return false
    end
    
    -- Pass shared data references to controllers
    animationController:setActivePets(activePets, PetModelFactory)
    guiController:setActivePets(activePets)
    
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
                self:UpdatePetSpawning()
            end
        end)
    end
    
    -- Wait for area assignment sync
    local areaAssignmentSync = ReplicatedStorage:WaitForChild("AreaAssignmentSync", 10)
    if areaAssignmentSync then
        areaAssignmentSync.OnClientEvent:Connect(function(assignmentData)
            areaAssignments = assignmentData
            playerAreaNumber = self:GetPlayerAreaNumber()
            self:UpdatePetSpawning()
        end)
    end
end

function PetGrowthService:GetPlayerAreaNumber()
    -- Find which area the current player is assigned to
    for areaNumber, assignmentData in pairs(areaAssignments) do
        if assignmentData.playerName == player.Name then
            return areaNumber
        end
    end
    return nil -- Player not assigned to any area yet
end

function PetGrowthService:UpdatePetSpawning()
    if not playerAreaNumber then
        return
    end
    
    local playerAreas = Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then return end
    
    local playerArea = playerAreas:FindFirstChild("PlayerArea" .. playerAreaNumber)
    if not playerArea then return end
    
    local plotsFolder = playerArea:FindFirstChild("Plots")
    if not plotsFolder then return end
    
    -- Check each owned plot
    for _, ownedPlotId in pairs(lastPlayerData.boughtPlots or {}) do
        local plot = plotsFolder:FindFirstChild("Plot" .. ownedPlotId)
        if plot and plot:IsA("Model") then
            -- Check if this plot already has a pet
            if not activePets[ownedPlotId] then
                self:StartPetGrowth(plot, ownedPlotId)
            end
        end
    end
    
    -- Clean up pets on plots that are no longer owned (shouldn't happen, but safety check)
    for plotId, petData in pairs(activePets) do
        local isOwned = false
        for _, ownedPlotId in pairs(lastPlayerData.boughtPlots or {}) do
            if ownedPlotId == plotId then
                isOwned = true
                break
            end
        end
        
        if not isOwned then
            self:RemovePet(plotId)
        end
    end
end

function PetGrowthService:StartPetGrowth(plot, plotId)
    local success, error = pcall(function()
        local plotData = PlotConfig:GetPlotData(plotId)
        if not plotData then
            warn("PetGrowthService: No plot data for plotId:", plotId)
            return false
        end
        
        return true
    end)
    
    if not success then
        warn("PetGrowthService: StartPetGrowth failed for plot", plotId, ":", error)
        return
    end
    
    local plotData = PlotConfig:GetPlotData(plotId)
    if not plotData then
        return
    end
    
    -- Get a random pet for this plot's rarity
    local petSelection = PetConfig:GetRandomPetForRarity(plotData.rarity)
    if not petSelection then
        return
    end
    
    local petData = petSelection.data
    
    -- Get plot center position
    local plotCenter = self:GetPlotCenter(plot)
    local spawnPosition = plotCenter + Vector3.new(0, PET_HOVER_HEIGHT, 0)
    
    -- Start with egg model for first 5 seconds
    local eggModel = PetModelFactory.createEggModel(spawnPosition)
    if not eggModel then
        return
    end
    
    eggModel.Parent = plot
    
    -- Set egg at smaller size to match pet size
    local eggFullScale = Vector3.new(0.3, 0.3, 0.3) -- Match pet final size
    PetModelFactory.scaleModel(eggModel, eggFullScale)
    
    -- Generate random aura for this pet
    local auraId, auraData = PetConfig:GetRandomAura()
    
    -- Store pet data (include pet ID from selection, aura, and size)
    local petSize = PetConfig:GetSmallestSize() -- All new pets start at smallest size
    local sizeData = PetConfig:GetSizeData(petSize)
    
    local fullPetData = {
        id = petSelection.id,
        name = petData.name,
        rarity = petData.rarity,
        value = petData.value * (auraData.valueMultiplier or 1) * (sizeData.multiplier or 1),
        description = petData.description,
        aura = auraId,
        auraData = auraData,
        size = petSize,
        sizeData = sizeData
    }
    
    activePets[plotId] = {
        model = eggModel, -- Start with egg model
        petData = fullPetData,
        plot = plot,
        originalScale = Vector3.new(1, 1, 1),
        currentScale = eggFullScale,
        spawnPosition = spawnPosition,
        growthStartTime = tick(),
        isFullyGrown = false,
        floatOffset = 0,
        rotationOffset = 0,
        isEggPhase = true, -- Track if we're in egg phase
        actualPetData = petData -- Store the actual pet data for later
    }
    
    -- Create pet status GUI
    guiController:createPetStatusGUI(plotId)
    
    -- Apply aura visual effects to the egg model
    PetModelFactory.applyAuraEffects(eggModel, auraData)
    
    -- Start egg phase animation
    animationController:startEggPhaseAnimation(plotId, function(completedPlotId)
        self:SwitchToPetPhase(completedPlotId)
    end)
end

function PetGrowthService:SwitchToPetPhase(plotId)
    local petInfo = activePets[plotId]
    if not petInfo or not petInfo.isEggPhase then return end
    
    -- Remove egg model
    if petInfo.model then
        petInfo.model:Destroy()
    end
    
    -- Create actual pet model
    local petModel = PetModelFactory.createPetModel(petInfo.actualPetData, petInfo.spawnPosition)
    if not petModel then
        -- If pet creation fails, remove from active pets
        activePets[plotId] = nil
        return
    end
    
    petModel.Parent = petInfo.plot
    
    -- Start pet small and grow to full size
    local startScale = Vector3.new(0.03, 0.03, 0.03)
    PetModelFactory.scaleModel(petModel, startScale)
    
    -- Update pet info
    petInfo.model = petModel
    petInfo.isEggPhase = false
    petInfo.currentScale = startScale
    petInfo.isAnimating = true -- Enable animation updates
    
    -- Create new status GUI for the pet model
    guiController:createPetStatusGUI(plotId)
    
    -- Apply aura visual effects to the pet model
    PetModelFactory.applyAuraEffects(petModel, petInfo.petData.auraData)
    
    -- Start pet growth animation
    animationController:startPetGrowthAnimation(plotId, function(completedPlotId, isReady)
        -- Update GUI to show "Ready!" and set up touch detection
        guiController:updatePetStatusGUI(completedPlotId, isReady)
        self:SetupPetPickup(completedPlotId)
    end)
end

function PetGrowthService:SetupPetPickup(plotId)
    local petInfo = activePets[plotId]
    if not petInfo or not petInfo.model then 
        return 
    end
    
    local touchConnections = {}
    
    -- Set up touch detection for all parts in the model
    local function setupTouchForPart(part)
        if part:IsA("BasePart") then
            local connection = part.Touched:Connect(function(hit)
                local humanoid = hit.Parent:FindFirstChild("Humanoid")
                if humanoid and hit.Parent == player.Character then
                    
                    -- Clean up all touch connections immediately
                    for _, conn in pairs(touchConnections) do
                        conn:Disconnect()
                    end
                    
                    -- Store the plot reference before removing pet
                    local plot = petInfo.plot
                    
                    -- Create pet data for collection
                    local collectedPet = {
                        id = petInfo.petData.id or 1,
                        uniqueId = game:GetService("HttpService"):GenerateGUID(false),
                        name = petInfo.petData.name,
                        rarity = petInfo.petData.rarity,
                        value = petInfo.petData.value,
                        collectedAt = tick(),
                        plotId = plotId,
                        aura = petInfo.petData.aura or "none",
                        size = petInfo.petData.size or 1
                    }
                    
                    -- IMMEDIATE STATE UPDATES - No server delay!
                    Store:dispatch(PlayerActions.addPet(collectedPet))
                    -- Give 1 diamond for pet collection (optimistic update)
                    Store:dispatch(PlayerActions.addDiamonds(1))
                    
                    -- Update pet collection stats
                    local currentState = Store:getState()
                    local currentStats = currentState.player.stats or {}
                    Store:dispatch(PlayerActions.updateStats({
                        totalPetsCollected = (currentStats.totalPetsCollected or 0) + 1
                    }))
                    
                    -- Remove the pet immediately (no waiting for server)
                    self:RemovePet(plotId)
                    
                    -- Start growing a new pet immediately (no delay)
                    self:StartPetGrowth(plot, plotId)
                    
                    -- Send minimal data to server for validation and persistence (async, no waiting)
                    task.spawn(function()
                        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                        if remotes then
                            local collectPetRemote = remotes:FindFirstChild("CollectPet")
                            if collectPetRemote then
                                -- Send only the data server needs for validation
                                local serverData = {
                                    petId = collectedPet.id, -- Server expects 'petId', not 'id'
                                    plotId = collectedPet.plotId,
                                    aura = collectedPet.aura,
                                    size = collectedPet.size
                                }
                                collectPetRemote:FireServer(serverData)
                            end
                        end
                    end)
                end
            end)
            table.insert(touchConnections, connection)
        end
    end
    
    -- If it's a model, set up touch for all parts
    if petInfo.model:IsA("Model") then
        for _, descendant in pairs(petInfo.model:GetDescendants()) do
            setupTouchForPart(descendant)
        end
    else
        -- If it's a single part
        setupTouchForPart(petInfo.model)
    end
    
    -- Store all connections for cleanup
    petInfo.touchConnections = touchConnections
end

function PetGrowthService:RemovePet(plotId)
    local petInfo = activePets[plotId]
    if not petInfo then return end
    
    -- Clean up touch connections
    if petInfo.touchConnections then
        for _, connection in pairs(petInfo.touchConnections) do
            connection:Disconnect()
        end
    elseif petInfo.touchConnection then
        petInfo.touchConnection:Disconnect()
    end
    
    -- Clean up status GUI
    guiController:removeStatusGUI(plotId)
    
    -- Remove the model
    if petInfo.model then
        petInfo.model:Destroy()
    end
    
    -- Clear from active pets
    activePets[plotId] = nil
end

function PetGrowthService:GetPlotCenter(plot)
    local parts = {}
    
    for _, child in pairs(plot:GetChildren()) do
        if child:IsA("BasePart") then
            table.insert(parts, child)
        end
    end
    
    if #parts == 0 then
        if plot:IsA("Model") and plot.PrimaryPart then
            return plot.PrimaryPart.Position
        elseif plot:IsA("BasePart") then
            return plot.Position
        else
            return Vector3.new(0, 0, 0)
        end
    end
    
    local sumPosition = Vector3.new(0, 0, 0)
    for i, part in pairs(parts) do
        sumPosition = sumPosition + part.Position
    end
    
    local center = sumPosition / #parts
    return center
end

function PetGrowthService:Cleanup()
    -- Clean up controllers
    animationController:cleanup()
    guiController:cleanup()
    
    -- Clean up all active pets
    for plotId, _ in pairs(activePets) do
        self:RemovePet(plotId)
    end
end

return PetGrowthService