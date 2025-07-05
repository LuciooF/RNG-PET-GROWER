-- Cylinder Spawner Service (Refactored)
-- Handles spawning and managing cylinders above FarmBase when plots are purchased
-- Now uses modular controllers for better maintainability

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local PlotConfig = require(ReplicatedStorage.Shared.config.PlotConfig)
local ProductionPlotConfig = require(ReplicatedStorage.Shared.config.ProductionPlotConfig)
local CylinderGUIController = require(script.Parent.controllers.CylinderGUIController)
local PetSpawningController = require(script.Parent.controllers.PetSpawningController)

local CylinderSpawnerService = {}
CylinderSpawnerService.__index = CylinderSpawnerService

local player = Players.LocalPlayer
local activeCylinders = {} -- Store active cylinders per plot
local lastPlayerData = {} -- Cache player data
local playerAreaNumber = nil -- Store the player's assigned area number
local areaAssignments = {} -- Store area assignments from server
local spawnedPets = {} -- Track all spawned pets that haven't been collected yet
local spawnedPetCount = 0 -- Counter for spawned pets
local spawnCounterGUI = nil -- GUI to display spawn counter

-- Configuration
local CYLINDER_HEIGHT = 20 -- Height above FarmBase
local PET_SPAWN_MIN_INTERVAL = 9 -- Minimum seconds between pet spawns
local PET_SPAWN_MAX_INTERVAL = 12 -- Maximum seconds between pet spawns

-- Generate random spawn interval for each cylinder
local function getRandomSpawnInterval()
    return math.random() * (PET_SPAWN_MAX_INTERVAL - PET_SPAWN_MIN_INTERVAL) + PET_SPAWN_MIN_INTERVAL
end
local MAX_SPAWNED_PETS = 50 -- Maximum pets that can be spawned at once
local CYLINDER_COLORS = {
    [1] = Color3.fromRGB(139, 69, 19), -- Brown (Basic)
    [2] = Color3.fromRGB(169, 169, 169), -- Silver (Advanced)
    [3] = Color3.fromRGB(255, 215, 0), -- Gold (Premium)
    [4] = Color3.fromRGB(138, 43, 226), -- Purple (Elite)
    [5] = Color3.fromRGB(255, 20, 147) -- Pink (Master/Legendary)
}

function CylinderSpawnerService:Initialize()
    -- Wait for PlayerAreas to be created
    local playerAreas = Workspace:WaitForChild("PlayerAreas", 10)
    if not playerAreas then
        warn("CylinderSpawnerService: PlayerAreas not found!")
        return
    end
    
    -- Set up data sync connections
    self:setupDataSync()
    self:setupAreaSync()
    
    -- Start pet spawning loop
    self:StartPetSpawningLoop()
    
    -- Initialized successfully
end

function CylinderSpawnerService:setupDataSync()
    local playerDataSync = ReplicatedStorage:WaitForChild("PlayerDataSync", 10)
    if playerDataSync then
        playerDataSync.OnClientEvent:Connect(function(data)
            if data and data.resources then
                local previousRebirths = lastPlayerData.rebirths or 0
                local newRebirths = data.resources.rebirths or 0
                
                lastPlayerData = {
                    money = data.resources.money or 0,
                    rebirths = data.resources.rebirths or 0,
                    boughtPlots = data.boughtPlots or {},
                    boughtProductionPlots = data.boughtProductionPlots or {}
                }
                
                -- Check if player just rebirthed (rebirth count increased)
                if newRebirths > previousRebirths and previousRebirths > 0 then
                    -- Clear all spawned pets when rebirth happens
                    self:ClearAllSpawnedPets()
                end
                
                self:UpdateCylinders()
            end
        end)
    end
end

function CylinderSpawnerService:setupAreaSync()
    local areaAssignmentSync = ReplicatedStorage:WaitForChild("AreaAssignmentSync", 10)
    if areaAssignmentSync then
        areaAssignmentSync.OnClientEvent:Connect(function(assignmentData)
            areaAssignments = assignmentData
            playerAreaNumber = self:GetPlayerAreaNumber()
            self:UpdateCylinders()
            self:CreateSpawnCounterGUI()
        end)
    end
end

function CylinderSpawnerService:GetPlayerAreaNumber()
    for areaNumber, assignmentData in pairs(areaAssignments) do
        if assignmentData.playerName == player.Name then
            return areaNumber
        end
    end
    return nil
end

function CylinderSpawnerService:UpdateCylinders()
    if not playerAreaNumber then return end
    
    local farmBase = self:getFarmBase()
    if not farmBase then return end
    
    -- Remove cylinders for plots no longer owned
    self:cleanupUnownedCylinders()
    
    -- Create cylinders for newly owned plots
    self:createCylindersForOwnedPlots(farmBase)
end

function CylinderSpawnerService:getFarmBase()
    local playerAreas = Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then return nil end
    
    local playerArea = playerAreas:FindFirstChild("PlayerArea" .. playerAreaNumber)
    if not playerArea then return nil end
    
    local farm = playerArea:FindFirstChild("Farm")
    if not farm then
        warn("CylinderSpawnerService: Farm model not found in player area!")
        return nil
    end
    
    local farmBase = farm:FindFirstChild("FarmBase")
    if not farmBase then
        warn("CylinderSpawnerService: FarmBase not found in Farm model!")
        return nil
    end
    
    return farmBase
end

function CylinderSpawnerService:getFarmModel()
    local playerAreas = Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then return nil end
    
    local playerArea = playerAreas:FindFirstChild("PlayerArea" .. playerAreaNumber)
    if not playerArea then return nil end
    
    local farm = playerArea:FindFirstChild("Farm")
    if not farm then
        warn("CylinderSpawnerService: Farm model not found in player area!")
        return nil
    end
    
    return farm
end

function CylinderSpawnerService:cleanupUnownedCylinders()
    for cylinderKey, cylinderData in pairs(activeCylinders) do
        local isOwned = false
        
        if cylinderData.plotType == "production" then
            for _, ownedPlotId in pairs(lastPlayerData.boughtProductionPlots or {}) do
                if ownedPlotId == cylinderData.plotId then
                    isOwned = true
                    break
                end
            end
        else
            for _, ownedPlotId in pairs(lastPlayerData.boughtPlots or {}) do
                if ownedPlotId == cylinderData.plotId then
                    isOwned = true
                    break
                end
            end
        end
        
        if not isOwned then
            self:destroyCylinder(cylinderKey)
        end
    end
end

function CylinderSpawnerService:createCylindersForOwnedPlots(farmBase)
    -- Check regular plots
    for _, plotId in pairs(lastPlayerData.boughtPlots or {}) do
        if not activeCylinders[plotId] then
            self:CreateCylinder(plotId, "regular", farmBase)
        end
    end
    
    -- Check production plots
    for _, plotId in pairs(lastPlayerData.boughtProductionPlots or {}) do
        local cylinderKey = "prod_" .. plotId
        if not activeCylinders[cylinderKey] then
            self:CreateCylinder(plotId, "production", farmBase)
        end
    end
end

function CylinderSpawnerService:CreateCylinder(plotId, plotType, farmBase)
    local plotConfig = plotType == "production" and ProductionPlotConfig or PlotConfig
    local plotData = plotConfig:GetPlotData(plotId)
    if not plotData then return end
    
    -- Create cylinder part
    local cylinder = self:createCylinderPart(plotId, plotType, plotData)
    
    -- Position cylinder above farm
    local cylinderPosition = self:calculateCylinderPosition(farmBase, plotId, plotType)
    cylinder.CFrame = CFrame.new(cylinderPosition) * CFrame.Angles(0, 0, math.rad(90))
    
    -- Add lighting effect
    self:addCylinderEffects(cylinder, plotData)
    
    -- Create rarity GUI using controller (pass player rebirths for dynamic rarity)
    local cylinderGUI = CylinderGUIController.createCylinderGUI(cylinder, plotData, lastPlayerData.rebirths or 0)
    
    cylinder.Parent = farmBase.Parent
    
    -- Store cylinder data with random spawn interval and staggered start time
    local cylinderKey = plotType == "production" and ("prod_" .. plotId) or plotId
    activeCylinders[cylinderKey] = {
        cylinder = cylinder,
        plotType = plotType,
        plotId = plotId,
        plotData = plotData,
        lastSpawnTime = tick() - math.random() * PET_SPAWN_MAX_INTERVAL, -- Random initial offset
        spawnInterval = getRandomSpawnInterval(), -- Individual random interval
        gui = cylinderGUI
    }
    
    -- Cylinder created successfully
end

function CylinderSpawnerService:createCylinderPart(plotId, plotType, plotData)
    local cylinder = Instance.new("Part")
    cylinder.Name = (plotType == "production" and "ProductionCylinder" or "Cylinder") .. plotId
    cylinder.Shape = Enum.PartType.Cylinder
    cylinder.Material = Enum.Material.Neon
    cylinder.Size = Vector3.new(1.5, 12, 1.5)
    cylinder.Anchored = true
    cylinder.CanCollide = false
    
    -- Calculate dynamic rarity for cylinder color
    local PlotConfig = require(ReplicatedStorage.Shared.config.PlotConfig)
    local dynamicRarity = PlotConfig:GetDynamicRarity(plotId, lastPlayerData.rebirths or 0)
    local colorIndex = ((dynamicRarity - 1) % #CYLINDER_COLORS) + 1
    cylinder.Color = CYLINDER_COLORS[colorIndex] or CYLINDER_COLORS[1]
    
    return cylinder
end

function CylinderSpawnerService:calculateCylinderPosition(farmBase, plotId, plotType)
    local farmBasePosition = farmBase.Position
    local farmBaseSize = farmBase.Size
    
    -- Calculate grid position for cylinder
    local cylindersPerRow = 6
    local row = math.floor((plotId - 1) / cylindersPerRow)
    local col = (plotId - 1) % cylindersPerRow
    
    local spacingX = farmBaseSize.X / (cylindersPerRow + 1)
    local spacingZ = farmBaseSize.Z / 6
    
    local offsetX = (col - (cylindersPerRow - 1) / 2) * spacingX
    local offsetZ = (row - 2) * spacingZ
    
    return farmBasePosition + Vector3.new(
        offsetX, 
        farmBaseSize.Y/2 + CYLINDER_HEIGHT, 
        offsetZ
    )
end

function CylinderSpawnerService:addCylinderEffects(cylinder, plotData)
    -- Add glow effect
    local pointLight = Instance.new("PointLight")
    pointLight.Brightness = 2
    pointLight.Range = 10
    pointLight.Color = cylinder.Color
    pointLight.Parent = cylinder
end

function CylinderSpawnerService:destroyCylinder(cylinderKey)
    local cylinderData = activeCylinders[cylinderKey]
    if not cylinderData then return end
    
    if cylinderData.cylinder and cylinderData.cylinder.Parent then
        cylinderData.cylinder:Destroy()
    end
    
    if cylinderData.gui then
        CylinderGUIController.destroyGUI(cylinderData.gui)
    end
    
    activeCylinders[cylinderKey] = nil
end

function CylinderSpawnerService:StartPetSpawningLoop()
    local connection = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        
        -- Check if we've reached the pet cap
        if spawnedPetCount >= MAX_SPAWNED_PETS then
            return
        end
        
        for cylinderKey, cylinderData in pairs(activeCylinders) do
            if cylinderData.cylinder and cylinderData.cylinder.Parent then
                -- Use individual cylinder's spawn interval
                local spawnInterval = cylinderData.spawnInterval or getRandomSpawnInterval()
                if currentTime - cylinderData.lastSpawnTime >= spawnInterval and spawnedPetCount < MAX_SPAWNED_PETS then
                    self:SpawnPetFromCylinder(cylinderData)
                    cylinderData.lastSpawnTime = currentTime
                    -- Generate new random interval for next spawn
                    cylinderData.spawnInterval = getRandomSpawnInterval()
                end
            else
                -- Clean up invalid cylinders
                activeCylinders[cylinderKey] = nil
            end
        end
    end)
end

function CylinderSpawnerService:SpawnPetFromCylinder(cylinderData)
    local cylinder = cylinderData.cylinder
    local plotData = cylinderData.plotData
    
    -- Generate pet data using controller with player rebirths for dynamic rarity
    local playerRebirths = lastPlayerData.rebirths or 0
    local petData = PetSpawningController.generatePetData(plotData, playerRebirths, cylinderData.plotId)
    if not petData then return end
    
    -- Get Farm model for cleaner organization
    local farmModel = self:getFarmModel()
    if not farmModel then
        warn("CylinderSpawnerService: Farm model not found! Using cylinder parent as fallback.")
        farmModel = cylinder.Parent
    end
    
    -- Spawn position just below cylinder
    local spawnPosition = cylinder.Position + Vector3.new(0, -2, 0)
    local petModel = PetSpawningController.spawnPetModel(petData, spawnPosition, farmModel)
    if not petModel then return end
    
    -- Track spawned pet
    local petUniqueId = PetSpawningController.generatePetId()
    spawnedPets[petUniqueId] = {
        model = petModel,
        data = petData,
        plotId = cylinderData.plotId,
        spawnTime = tick()
    }
    spawnedPetCount = spawnedPetCount + 1
    
    -- Update spawn counter GUI
    self:UpdateSpawnCounterGUI()
    
    -- Store unique ID on the model
    local idValue = Instance.new("StringValue")
    idValue.Name = "SpawnedPetId"
    idValue.Value = petUniqueId
    idValue.Parent = petModel
    
    -- Set up collection using controller
    PetSpawningController.setupPetCollection(petModel, petData, cylinderData.plotId, function(collectedPet)
        -- Callback when pet is collected
        if spawnedPets[petUniqueId] then
            spawnedPets[petUniqueId] = nil
            spawnedPetCount = math.max(0, spawnedPetCount - 1)
            self:UpdateSpawnCounterGUI()
        end
    end)
    
    -- Pet spawned successfully
end

function CylinderSpawnerService:CreateSpawnCounterGUI()
    if not playerAreaNumber then return end
    
    local farmBase = self:getFarmBase()
    if not farmBase then return end
    
    -- Remove existing GUI if it exists
    if spawnCounterGUI then
        CylinderGUIController.destroyGUI(spawnCounterGUI)
        spawnCounterGUI = nil
    end
    
    -- Create new spawn counter using controller
    spawnCounterGUI = CylinderGUIController.createSpawnCounterGUI(farmBase, spawnedPetCount, MAX_SPAWNED_PETS)
end

function CylinderSpawnerService:UpdateSpawnCounterGUI()
    if spawnCounterGUI then
        CylinderGUIController.updateSpawnCounter(spawnCounterGUI, spawnedPetCount, MAX_SPAWNED_PETS)
    end
end

function CylinderSpawnerService:ClearAllSpawnedPets()
    -- Clean up all spawned pets (used during rebirth)
    for petId, petData in pairs(spawnedPets) do
        if petData.model and petData.model.Parent then
            petData.model:Destroy()
        end
    end
    spawnedPets = {}
    spawnedPetCount = 0
    
    -- Update spawn counter GUI
    self:UpdateSpawnCounterGUI()
    
    print("CylinderSpawnerService: Cleared all spawned pets")
end

function CylinderSpawnerService:Cleanup()
    -- Clean up all cylinders
    for cylinderKey, cylinderData in pairs(activeCylinders) do
        self:destroyCylinder(cylinderKey)
    end
    activeCylinders = {}
    
    -- Clean up spawned pets tracking
    self:ClearAllSpawnedPets()
    
    -- Clean up spawn counter GUI
    if spawnCounterGUI then
        CylinderGUIController.destroyGUI(spawnCounterGUI)
        spawnCounterGUI = nil
    end
end

return CylinderSpawnerService