-- Pet Spawning Controller
-- Handles pet spawning logic, physics, and collection setup
-- Centralizes pet creation and collection patterns

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PetConfig = require(ReplicatedStorage.Shared.config.PetConfig)
local PetModelFactory = require(script.Parent.PetModelFactory)
local Store = require(ReplicatedStorage.store)
local PlayerActions = require(ReplicatedStorage.store.actions.PlayerActions)

local PetSpawningController = {}

local player = Players.LocalPlayer

-- Generate pet data for spawning
function PetSpawningController.generatePetData(plotData)
    if not plotData or not plotData.rarity then
        warn("PetSpawningController: Invalid plot data")
        return nil
    end
    
    -- Get a random pet for this plot's rarity
    local petSelection = PetConfig:GetRandomPetForRarity(plotData.rarity)
    if not petSelection then
        warn("PetSpawningController: No pet found for rarity", plotData.rarity)
        return nil
    end

    local petData = petSelection.data
    
    -- Generate random aura and size
    local auraId, auraData = PetConfig:GetRandomAura()
    local petSize = PetConfig:GetSmallestSize()
    local sizeData = PetConfig:GetSizeData(petSize)
    
    return {
        id = petSelection.id,
        name = petData.name,
        rarity = petData.rarity,
        value = petData.value * (auraData.valueMultiplier or 1) * (sizeData.multiplier or 1),
        description = petData.description,
        assetPath = petData.assetPath,
        aura = auraId,
        auraData = auraData,
        size = petSize,
        sizeData = sizeData
    }
end

-- Create and spawn pet model with physics
function PetSpawningController.spawnPetModel(petData, spawnPosition, parentObject)
    if not petData or not spawnPosition or not parentObject then
        warn("PetSpawningController: Invalid spawn parameters")
        return nil
    end
    
    -- Create pet model
    local petModel = PetModelFactory.createPetModel(petData, spawnPosition)
    if not petModel then
        warn("PetSpawningController: Failed to create pet model")
        return nil
    end
    
    petModel.Parent = parentObject
    
    -- Scale the pet model
    local finalScale = Vector3.new(0.3, 0.3, 0.3)
    PetModelFactory.scaleModel(petModel, finalScale)
    
    -- Aura particle effects removed - cleaner visual experience
    
    -- Add invisible collector part for easier collection (must be done before physics setup)
    PetSpawningController.addCollectorPart(petModel)
    
    -- Set up physics on the collector part
    PetSpawningController.setupPetPhysics(petModel)
    
    return petModel
end

-- Set up pet physics with proper welding
function PetSpawningController.setupPetPhysics(petModel)
    if not petModel or not petModel.PrimaryPart then
        return false
    end
    
    -- At this point, PrimaryPart should be the collector part
    local collectorPart = petModel.PrimaryPart
    
    -- Set up physics for falling and rolling on collector part
    collectorPart.Anchored = false
    collectorPart.CanCollide = true
    
    -- Ensure all other parts are properly welded and non-collidable
    for _, part in pairs(petModel:GetDescendants()) do
        if part:IsA("BasePart") and part ~= collectorPart and part.Name ~= "PetCollector" then
            -- Make sure visual parts don't interfere with physics
            part.Anchored = false
            part.CanCollide = false
            
            -- Weld visual parts to collector if not already welded
            local hasWeld = false
            for _, child in pairs(part:GetChildren()) do
                if child:IsA("WeldConstraint") then
                    hasWeld = true
                    break
                end
            end
            
            if not hasWeld then
                local weld = Instance.new("WeldConstraint")
                weld.Part0 = collectorPart
                weld.Part1 = part
                weld.Parent = collectorPart
            end
        end
    end
    
    -- Add realistic gravity with slight horizontal variation
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(1000, math.huge, 1000)
    bodyVelocity.Velocity = Vector3.new(
        math.random(-3, 3), -- Small horizontal variation
        0, -- Let gravity handle downward movement naturally
        math.random(-3, 3)  -- Small horizontal variation
    )
    bodyVelocity.Parent = collectorPart
    
    -- Remove velocity after a short time to allow natural physics
    task.spawn(function()
        task.wait(0.5)
        if bodyVelocity and bodyVelocity.Parent then
            bodyVelocity:Destroy()
        end
    end)
    
    return true
end

-- Add invisible collector part for easier collection and rolling physics
-- Creates a larger, invisible sphere around the pet that:
-- 1. Makes collection easier for players (bigger hit area)
-- 2. Provides smooth rolling physics (ball shape)
-- 3. Can roll toward collection areas naturally
function PetSpawningController.addCollectorPart(petModel)
    if not petModel or not petModel.PrimaryPart then
        return false
    end
    
    -- Calculate collector size based on pet model bounds
    local petSize = petModel.PrimaryPart.Size
    local collectorSize = Vector3.new(
        math.max(petSize.X * 1.5, 3), -- At least 3 studs wide, 50% bigger than pet
        math.max(petSize.Y * 1.5, 3), -- At least 3 studs tall, 50% bigger than pet
        math.max(petSize.Z * 1.5, 3)  -- At least 3 studs deep, 50% bigger than pet
    )
    
    -- Create invisible collector part
    local collectorPart = Instance.new("Part")
    collectorPart.Name = "PetCollector"
    collectorPart.Size = collectorSize
    collectorPart.Shape = Enum.PartType.Ball -- Round shape for smooth rolling
    collectorPart.Material = Enum.Material.SmoothPlastic -- Smooth material for good rolling
    collectorPart.Transparency = 1 -- Completely invisible
    collectorPart.CanCollide = true -- Can be touched and can roll
    collectorPart.Anchored = false
    collectorPart.BrickColor = BrickColor.new("Bright green") -- For debugging if needed
    collectorPart.Parent = petModel
    
    -- Add custom physical properties for better rolling
    local customPhysics = Instance.new("SpecialMesh")
    customPhysics.MeshType = Enum.MeshType.Sphere
    customPhysics.Parent = collectorPart
    
    -- Position collector at pet center
    collectorPart.CFrame = petModel.PrimaryPart.CFrame
    
    -- Weld collector to pet model so they move together
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = petModel.PrimaryPart
    weld.Part1 = collectorPart
    weld.Parent = petModel.PrimaryPart
    
    -- Make the original pet parts non-collidable so only collector handles physics
    for _, part in pairs(petModel:GetDescendants()) do
        if part:IsA("BasePart") and part ~= collectorPart then
            part.CanCollide = false
        end
    end
    
    -- Set collector as the main physics body
    petModel.PrimaryPart = collectorPart
    
    return true
end

-- Set up pet collection logic
function PetSpawningController.setupPetCollection(petModel, petData, plotId, onCollectedCallback)
    if not petModel or not petData then
        warn("PetSpawningController: Invalid collection setup parameters")
        return false
    end
    
    local isCollected = false
    local touchConnections = {}
    
    local function setupTouchForPart(part)
        if not part:IsA("BasePart") then return end
        
        local connection = part.Touched:Connect(function(hit)
            if isCollected then return end
            
            -- Check if hit by player (with nil safety)
            if not hit or not hit.Parent then return end
            local isPlayer = hit.Parent:FindFirstChild("Humanoid") and hit.Parent == player.Character
            if not isPlayer then return end
            
            -- Mark as collected immediately
            isCollected = true
            
            -- IMMEDIATELY destroy the pet model for instant feedback
            if petModel and petModel.Parent then
                petModel:Destroy()
            end
            
            -- Disconnect all touch connections
            for _, conn in pairs(touchConnections) do
                conn:Disconnect()
            end
            
            -- Process everything else asynchronously to prevent lag
            task.spawn(function()
                -- Create collected pet data
                local collectedPet = {
                    id = petData.id,
                    uniqueId = game:GetService("HttpService"):GenerateGUID(false),
                    name = petData.name,
                    rarity = petData.rarity,
                    value = petData.value,
                    collectedAt = tick(),
                    plotId = plotId,
                    aura = petData.aura or "none",
                    size = petData.size or 1
                }
                
                -- Batch state updates to reduce Redux overhead
                local currentState = Store:getState()
                local currentStats = currentState.player.stats or {}
                
                -- Single dispatch with all updates
                Store:dispatch(PlayerActions.addPet(collectedPet))
                Store:dispatch(PlayerActions.addDiamonds(1))
                Store:dispatch(PlayerActions.updateStats({
                    totalPetsCollected = (currentStats.totalPetsCollected or 0) + 1
                }))
                
                -- Call collection callback if provided
                if onCollectedCallback then
                    onCollectedCallback(collectedPet)
                end
                
                -- Send to server for validation (async)
                PetSpawningController.syncCollectionToServer(collectedPet)
            end)
        end)
        
        table.insert(touchConnections, connection)
    end
    
    -- Set up touch for all parts in the model
    if petModel:IsA("Model") then
        for _, descendant in pairs(petModel:GetDescendants()) do
            setupTouchForPart(descendant)
        end
    else
        setupTouchForPart(petModel)
    end
    
    return true
end

-- Send collection data to server for validation
function PetSpawningController.syncCollectionToServer(collectedPet)
    task.spawn(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        
        local collectPetRemote = remotes:FindFirstChild("CollectPet")
        if not collectPetRemote then return end
        
        local serverData = {
            petId = collectedPet.id,
            plotId = collectedPet.plotId,
            aura = collectedPet.aura,
            size = collectedPet.size
        }
        collectPetRemote:FireServer(serverData)
    end)
end

-- Generate unique pet ID
function PetSpawningController.generatePetId()
    return game:GetService("HttpService"):GenerateGUID(false)
end

return PetSpawningController