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
    
    -- Create pet model FIRST (same as other pet balls)
    local actualPetModel = self:CreateActualPetModel(petData)
    if not actualPetModel then
        warn("PetFollowService: Failed to create pet model")
        return
    end
    
    -- Calculate appropriate ball size based on pet model (bigger for equipped pets)
    local modelSize = actualPetModel:GetExtentsSize()
    local ballSize = math.min(3.0, math.max(modelSize.X, modelSize.Y, modelSize.Z) * 1.2) -- Increased from 2.0 and 0.8
    
    -- Create pet ball sized appropriately around the model
    local ball = Instance.new("Part")
    ball.Name = "Ball"
    ball.Shape = Enum.PartType.Ball
    ball.Size = Vector3.new(ballSize, ballSize, ballSize)
    
    -- Get variation color (same as other balls) 
    local PetConstants = require(ReplicatedStorage.constants.PetConstants)
    local variationColor = PetConstants.getVariationColor(petData.Variation or "Bronze")
    ball.Color = variationColor
    
    ball.Material = Enum.Material.Neon
    ball.Transparency = 0.87 -- Same as door pet balls
    ball.CanCollide = false
    ball.Anchored = false -- Unanchored so it can follow the player
    ball.Parent = workspace
    
    -- Add BodyVelocity for smooth following movement
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = ball
    
    -- Parent pet model to ball and weld properly (same as other balls)
    actualPetModel.Parent = ball
    
    -- Position the ball initially behind the player first
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = player.Character.HumanoidRootPart
        ball.Position = hrp.Position - (hrp.CFrame.LookVector * FOLLOW_DISTANCE) + Vector3.new(0, -2, 0)
    end
    
    -- Position and weld all pet parts (same as other balls)
    for _, descendant in pairs(actualPetModel:GetDescendants()) do
        if descendant:IsA("BasePart") then
            -- Position the part at the ball center
            descendant.Position = ball.Position
            
            -- Set physics properties (same as other balls)
            descendant.Anchored = false
            descendant.CanCollide = false
            descendant.Massless = true
            descendant.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            descendant.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            
            -- Create robust weld (same as other balls)
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = ball
            weld.Part1 = descendant
            weld.Parent = ball
            
            -- Store reference to prevent garbage collection
            descendant:SetAttribute("WeldedToBall", true)
            
            -- Custom physics properties for smooth following
            descendant.CustomPhysicalProperties = PhysicalProperties.new(
                0.01, -- Density (very light)
                0.5,  -- Friction
                0,    -- Elasticity
                1,    -- FrictionWeight
                1     -- ElasticityWeight
            )
        end
    end
    
    -- Add pet name GUI above the ball (same as other balls)
    self:CreatePetNameGUI(ball, petData)
    
    -- Set up the container model
    local containerModel = Instance.new("Model")
    containerModel.Name = "EquippedPet_" .. petData.ID
    containerModel.Parent = workspace
    containerModel.PrimaryPart = ball
    ball.Parent = containerModel
    
    -- Store references (container model for following)
    equippedPetModels[petData.ID] = {
        model = containerModel,
        position = position,
        petData = petData
    }
    
    -- Initialize velocity for smooth movement
    petVelocities[petData.ID] = Vector3.new(0, 0, 0)
end

-- Create actual pet model (same logic as ClientPetBallService)
function PetFollowService:CreateActualPetModel(petData)
    -- Try to get actual pet model from ReplicatedStorage.Pets
    local petsFolder = ReplicatedStorage:FindFirstChild("Pets")
    
    if petsFolder then
        -- Use the actual model name from pet data, or fall back to first available pet
        local modelName = petData.ModelName or petData.Name or "Acid Rain Doggy"
        
        local petModelTemplate = petsFolder:FindFirstChild(modelName)
        if not petModelTemplate then
            petModelTemplate = petsFolder:GetChildren()[1]
        end
        
        if petModelTemplate then
            local clonedModel = petModelTemplate:Clone()
            clonedModel.Name = "PetModel"
            
            -- Process all parts in the model (bigger for equipped pets)
            local scaleFactor = 0.25 -- Increased from 0.15 for bigger equipped pets
            local partCount = 0
            
            for _, descendant in pairs(clonedModel:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    partCount = partCount + 1
                    descendant.Size = descendant.Size * scaleFactor
                    descendant.CanCollide = false
                    descendant.Anchored = false
                    descendant.Massless = true
                    -- Make parts visible (they become invisible in ReplicatedStorage)
                    descendant.Transparency = math.min(descendant.Transparency, 0.5) -- Max 50% transparent
                    descendant.Material = Enum.Material.Neon -- Make them glow to be more visible
                    -- Keep original colors
                end
            end
            
            -- Find or create PrimaryPart
            if not clonedModel.PrimaryPart then
                local primaryPart = clonedModel:FindFirstChild("HumanoidRootPart") 
                    or clonedModel:FindFirstChild("RootPart")
                    or clonedModel:FindFirstChild("Torso")
                    or clonedModel:FindFirstChild("Head")
                    or clonedModel:FindFirstChildOfClass("BasePart")
                
                if primaryPart then
                    clonedModel.PrimaryPart = primaryPart
                end
            end
            
            -- If still no PrimaryPart, try to find one
            if not clonedModel.PrimaryPart then
                -- Force create a PrimaryPart from first BasePart
                for _, child in pairs(clonedModel:GetChildren()) do
                    if child:IsA("BasePart") then
                        clonedModel.PrimaryPart = child
                        break
                    end
                end
                
                -- If still no part found in direct children, search descendants
                if not clonedModel.PrimaryPart then
                    for _, descendant in pairs(clonedModel:GetDescendants()) do
                        if descendant:IsA("BasePart") then
                            clonedModel.PrimaryPart = descendant
                            break
                        end
                    end
                end
            end
            
            return clonedModel
        end
    end
    
    -- Fallback: create a simple colored model
    local petModel = Instance.new("Model")
    petModel.Name = "PetModel"
    
    local petPart = Instance.new("Part")
    petPart.Name = "PetPart"
    petPart.Shape = Enum.PartType.Ball
    petPart.Size = Vector3.new(1.8, 1.8, 1.8) -- Increased from 1.2 for bigger equipped pets
    petPart.Material = Enum.Material.Neon
    petPart.CanCollide = false
    petPart.Anchored = false
    petPart.Massless = true
    
    -- Color by rarity
    local PetConstants = require(ReplicatedStorage.constants.PetConstants)
    local rarityColor = PetConstants.getRarityColor(petData.Rarity or "Common")
    local h, s, v = rarityColor:ToHSV()
    petPart.Color = Color3.fromHSV(h, s * 1.2, v * 0.6)
    
    petPart.Parent = petModel
    petModel.PrimaryPart = petPart
    
    return petModel
end

-- Create floating name GUI for equipped pet balls (same as ClientPetBallService)
function PetFollowService:CreatePetNameGUI(petBall, petData)
    -- Create BillboardGui
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "PetNameGUI"
    billboardGui.Size = UDim2.new(0, 35, 0, 35) -- Same size as other pet balls
    billboardGui.StudsOffset = Vector3.new(0, 2.5, 0) -- Float above ball
    billboardGui.LightInfluence = 0
    billboardGui.AlwaysOnTop = true
    billboardGui.Enabled = true -- Always visible for equipped pets
    billboardGui.Parent = petBall
    
    -- Create TextLabel
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)  
    nameLabel.BackgroundTransparency = 1 -- No background
    -- Create text with variation and pet name
    local variationName = petData.Variation or "Bronze"
    local petName = petData.Name or "Unknown Pet"
    nameLabel.Text = variationName .. "\n" .. petName
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    
    -- Get variation color (same as the ball color)
    local PetConstants = require(ReplicatedStorage.constants.PetConstants)
    local variationColor = PetConstants.getVariationColor(petData.Variation or "Bronze")
    nameLabel.TextColor3 = variationColor
    
    -- Add black outline
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0) -- Black outline
    
    nameLabel.Parent = billboardGui
    
    return billboardGui
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
            
            -- Calculate smooth velocity towards target
            local positionDifference = targetPosition - currentPosition
            local distance = positionDifference.Magnitude
            
            -- Use BodyVelocity for smooth movement
            local bodyVelocity = model.PrimaryPart:FindFirstChild("BodyVelocity")
            if bodyVelocity then
                if distance > 0.5 then
                    -- Move towards target with speed based on distance
                    local moveSpeed = math.min(distance * 8, 30) -- Max speed of 30, accelerates with distance
                    bodyVelocity.Velocity = positionDifference.Unit * moveSpeed
                else
                    -- Slow down when close
                    bodyVelocity.Velocity = positionDifference * 10
                end
                
                -- Add floating effect to Y velocity
                local floatVelocity = math.cos(currentTime * FLOAT_SPEED + index) * FLOAT_AMPLITUDE * FLOAT_SPEED
                bodyVelocity.Velocity = bodyVelocity.Velocity + Vector3.new(0, floatVelocity, 0)
            end
            
            -- Make the ball (and pet model) face the player (with 270 degree adjustment)
            local directionToPlayer = (playerPosition - currentPosition).Unit
            local lookCFrame = CFrame.lookAt(currentPosition, currentPosition + directionToPlayer)
            -- Add 270 degree rotation around Y axis (90 + 180)
            local rotatedCFrame = lookCFrame * CFrame.Angles(0, math.rad(270), 0)
            model.PrimaryPart.CFrame = CFrame.new(model.PrimaryPart.Position) * (rotatedCFrame - rotatedCFrame.Position)
            
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