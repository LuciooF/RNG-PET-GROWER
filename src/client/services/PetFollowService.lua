-- PetFollowService - Handles equipped pets following the player
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local DataSyncService = require(script.Parent.DataSyncService)
local PetConfig = require(ReplicatedStorage.config.PetConfig)

local PetFollowService = {}
PetFollowService.__index = PetFollowService

-- Configuration
local FOLLOW_DISTANCE = 6 -- Distance behind player
local PET_SPACING = 3 -- Distance between pets horizontally
local UPDATE_RATE = 0.03 -- How often to update positions (30 FPS for smoother following)
local SMOOTH_FACTOR = 0.2 -- How quickly pets catch up (0.1 = slow, 1 = instant)
local FLOAT_AMPLITUDE = 0.3 -- How much pets float up/down (very small)
local FLOAT_SPEED = 2 -- Speed of floating animation

-- Tracking
local equippedPetModels = {} -- petId -> model
local lastUpdateTime = 0
local connection = nil
local petVelocities = {} -- petId -> Vector3 velocity for smooth movement

function PetFollowService:Initialize()
    local player = Players.LocalPlayer
    
    -- Get initial data
    local initialData = DataSyncService:GetPlayerData()
    if initialData and initialData.EquippedPets then
        self:UpdateEquippedPets(initialData.EquippedPets)
    end
    
    -- Subscribe to player data changes
    DataSyncService:Subscribe(function(newState)
        if newState.player and newState.player.EquippedPets then
            self:UpdateEquippedPets(newState.player.EquippedPets)
        end
    end)
    
    -- Handle character respawn
    local function onCharacterAdded(character)
        -- Wait a moment for character to fully load
        task.wait(0.1)
        
        -- Recreate all pet models at new character position
        local tempModels = {}
        for petId, petInfo in pairs(equippedPetModels) do
            tempModels[petId] = petInfo.petData
        end
        
        -- Clear and recreate
        for petId in pairs(equippedPetModels) do
            self:RemovePetModel(petId)
        end
        
        local index = 1
        for petId, petData in pairs(tempModels) do
            self:CreatePetModel(petData, index)
            index = index + 1
        end
    end
    
    -- Connect to character added
    if player.Character then
        onCharacterAdded(player.Character)
    end
    player.CharacterAdded:Connect(onCharacterAdded)
    
    -- Start update loop
    self:StartFollowLoop()
end

function PetFollowService:UpdateEquippedPets(equippedPets)
    -- Remove pets that are no longer equipped
    for petId, model in pairs(equippedPetModels) do
        local stillEquipped = false
        for _, pet in pairs(equippedPets) do
            if pet.ID == petId then
                stillEquipped = true
                break
            end
        end
        
        if not stillEquipped then
            self:RemovePetModel(petId)
        end
    end
    
    -- Add/update pets that are equipped
    for i, pet in pairs(equippedPets) do
        if not equippedPetModels[pet.ID] then
            self:CreatePetModel(pet, i)
        end
    end
end

function PetFollowService:CreatePetModel(petData, position)
    local player = Players.LocalPlayer
    
    -- Create simple ball model for now (will add assets later)
    local petModel = Instance.new("Model")
    local ball = Instance.new("Part")
    
    -- Set up the ball
    ball.Name = "Ball"
    ball.Shape = Enum.PartType.Ball
    ball.Size = Vector3.new(2, 2, 2)
    ball.Material = Enum.Material.Neon
    ball.CanCollide = false
    ball.Anchored = true
    ball.Parent = petModel
    
    -- Color by rarity (get from PetConstants if available)
    local PetConstants = require(ReplicatedStorage.constants.PetConstants)
    local rarityColor = PetConstants.getRarityColor(petData.Rarity or "Common")
    ball.Color = rarityColor
    
    -- Set up the model
    petModel.Name = "EquippedPet_" .. petData.ID
    petModel.Parent = workspace
    petModel.PrimaryPart = ball
    
    -- Position the ball initially behind the player
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = player.Character.HumanoidRootPart
        ball.Position = hrp.Position - (hrp.CFrame.LookVector * FOLLOW_DISTANCE) + Vector3.new(0, -2, 0)
    end
    
    -- Store references (no floating animation)
    equippedPetModels[petData.ID] = {
        model = petModel,
        position = position,
        petData = petData
    }
    
    -- Initialize velocity for smooth movement
    petVelocities[petData.ID] = Vector3.new(0, 0, 0)
end

function PetFollowService:RemovePetModel(petId)
    local petInfo = equippedPetModels[petId]
    if petInfo then
        if petInfo.model then
            petInfo.model:Destroy()
        end
        equippedPetModels[petId] = nil
        petVelocities[petId] = nil
    end
end

function PetFollowService:StartFollowLoop()
    if connection then
        connection:Disconnect()
    end
    
    -- Use RenderStepped for smoother visual updates
    connection = RunService.RenderStepped:Connect(function(deltaTime)
        self:UpdatePetPositions(deltaTime)
    end)
end

function PetFollowService:UpdatePetPositions(deltaTime)
    local player = Players.LocalPlayer
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local humanoidRootPart = character.HumanoidRootPart
    local playerPosition = humanoidRootPart.Position
    local playerLookDirection = humanoidRootPart.CFrame.LookVector
    
    -- Calculate base follow position (behind player at feet level)
    local followPosition = playerPosition - (playerLookDirection * FOLLOW_DISTANCE)
    -- Keep pets at ground level (player's Y position minus a bit to account for character height)
    local baseY = playerPosition.Y - 2
    followPosition = Vector3.new(followPosition.X, baseY, followPosition.Z)
    
    -- Get right direction for horizontal spacing
    local rightDirection = humanoidRootPart.CFrame.RightVector
    
    local petCount = 0
    for _ in pairs(equippedPetModels) do
        petCount = petCount + 1
    end
    
    if petCount == 0 then return end
    
    -- Calculate positions for horizontal formation
    local startOffset = -(petCount - 1) * PET_SPACING / 2
    
    local index = 0
    local currentTime = tick()
    
    -- Sort pets by ID for consistent ordering
    local sortedPets = {}
    for petId, petInfo in pairs(equippedPetModels) do
        table.insert(sortedPets, {id = petId, info = petInfo})
    end
    table.sort(sortedPets, function(a, b) return a.id < b.id end)
    
    for _, petData in ipairs(sortedPets) do
        local petId = petData.id
        local petInfo = petData.info
        local model = petInfo.model
        
        if model and model.PrimaryPart then
            -- Calculate position for this pet
            local horizontalOffset = startOffset + (index * PET_SPACING)
            local targetPosition = followPosition + (rightDirection * horizontalOffset)
            
            -- Add subtle floating animation (offset based on pet index for variety)
            local floatOffset = math.sin(currentTime * FLOAT_SPEED + index) * FLOAT_AMPLITUDE
            targetPosition = targetPosition + Vector3.new(0, floatOffset, 0)
            
            -- Get current position
            local currentPosition = model.PrimaryPart.Position
            
            -- Calculate velocity-based smoothing
            local velocity = petVelocities[petId] or Vector3.new(0, 0, 0)
            local positionDifference = targetPosition - currentPosition
            
            -- Apply damping to velocity
            velocity = velocity * 0.8 + positionDifference * 0.3
            petVelocities[petId] = velocity
            
            -- Update position using velocity
            local newPosition = currentPosition + velocity * deltaTime * 60 -- Normalize for 60 FPS
            
            -- Update position and rotation
            model.PrimaryPart.CFrame = CFrame.new(newPosition, newPosition + playerLookDirection)
            
            index = index + 1
        end
    end
end

function PetFollowService:Destroy()
    if connection then
        connection:Disconnect()
        connection = nil
    end
    
    -- Clean up all pet models
    for petId in pairs(equippedPetModels) do
        self:RemovePetModel(petId)
    end
end

return PetFollowService