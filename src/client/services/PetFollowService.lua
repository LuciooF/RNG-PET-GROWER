-- Pet Follow Service
-- Simple and clean pet following system

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetConfig = require(ReplicatedStorage.Shared.config.PetConfig)
local PetModelFactory = require(script.Parent.controllers.PetModelFactory)

local PetFollowService = {}
PetFollowService.__index = PetFollowService

local player = Players.LocalPlayer
local activePets = {} -- Table to store active pet instances

-- Configuration
local FOLLOW_DISTANCE = 5 -- Distance behind player
local PET_SPACING = 3 -- Distance between pets
local GROUND_PET_HEIGHT = 0 -- Ground pets at ground level
local FLYING_PET_HEIGHT = 8 -- Flying pets above player's head

-- Create pet model for following
local function createPetModel(petData)
    local petConfig = PetConfig:GetPetData(petData.id or 1)
    if not petConfig then return nil end
    
    -- Use PetModelFactory for model creation
    local petModel = PetModelFactory.createPetModel(petConfig, Vector3.new(0, 0, 0))
    if not petModel then return nil end
    
    -- Apply rarity outline effects
    PetModelFactory.applyRarityOutline(petModel, petData)
    
    -- Scale down companion pets (50% smaller)
    local baseScale = 0.15
    local sizeData = PetConfig:GetSizeData(petData.size or 1)
    local sizeMultiplier = (sizeData and sizeData.multiplier) or 1
    local finalScale = baseScale * sizeMultiplier
    
    PetModelFactory.scaleModel(petModel, finalScale)
    
    -- Make all parts anchored for simple following (no physics)
    for _, part in pairs(petModel:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
            part.CanCollide = false
            part.CollisionGroup = "Pets"
        end
    end
    
    return petModel
end

-- Simple update loop
local function updatePetPositions()
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local playerCFrame = humanoidRootPart.CFrame
    local playerPosition = humanoidRootPart.Position
    
    -- Update each pet position
    for i, petInfo in ipairs(activePets) do
        local petModel = petInfo.model
        local petData = petInfo.data
        if petModel and petModel.Parent and petModel.PrimaryPart then
            -- Get pet config to check if flying
            local petConfig = PetConfig:GetPetData(petData.id or 1)
            local isFlying = petConfig and petConfig.isFlyingPet or false
            
            -- Calculate grid position (3x3 formation)
            local petsPerRow = 3
            local petIndex = i - 1 -- 0-based index
            local row = math.floor(petIndex / petsPerRow) -- Which row (0, 1, 2)
            local col = petIndex % petsPerRow -- Which column (0, 1, 2)
            
            -- Center the formation
            local offsetX = (col - 1) * PET_SPACING -- -1, 0, 1 for columns
            local offsetZ = FOLLOW_DISTANCE + (row * PET_SPACING) -- Rows go further back
            
            -- Calculate world position (behind the player)
            local offset = playerCFrame:VectorToWorldSpace(Vector3.new(offsetX, 0, offsetZ))
            local petHeight = isFlying and FLYING_PET_HEIGHT or GROUND_PET_HEIGHT
            local targetPosition = playerPosition + offset + Vector3.new(0, petHeight, 0)
            
            -- Simple direct positioning - face the player
            petModel:SetPrimaryPartCFrame(CFrame.new(targetPosition, playerPosition))
        end
    end
end

-- Initialize the service
function PetFollowService:Initialize()
    -- Simple heartbeat connection for updates
    RunService.Heartbeat:Connect(updatePetPositions)
end

-- Update assigned pets (optimized - only update when actually changed)
function PetFollowService:UpdateAssignedPets(playerData)
    local assignedPets = playerData.companionPets or {}
    
    -- Check if the pets actually changed to avoid unnecessary recreation
    if self:ComparePetLists(activePets, assignedPets) then
        return -- No changes, skip update
    end
    
    -- Clear existing pets only if there are actual changes
    self:ClearAllPets()
    
    -- Create new pet models
    for i, petData in ipairs(assignedPets) do
        local petModel = createPetModel(petData)
        if petModel then
            petModel.Parent = workspace
            
            -- Store pet info
            table.insert(activePets, {
                model = petModel,
                data = petData
            })
        end
    end
end

-- Compare two pet lists to see if they're the same (optimization)
function PetFollowService:ComparePetLists(currentPets, newPets)
    if #currentPets ~= #newPets then
        return false
    end
    
    for i, currentPetInfo in ipairs(currentPets) do
        local currentPet = currentPetInfo.data
        local newPet = newPets[i]
        
        if not newPet or 
           currentPet.uniqueId ~= newPet.uniqueId or
           currentPet.id ~= newPet.id or
           currentPet.aura ~= newPet.aura or
           currentPet.size ~= newPet.size then
            return false
        end
    end
    
    return true -- Lists are identical
end

-- Clear all pets
function PetFollowService:ClearAllPets()
    for _, petInfo in ipairs(activePets) do
        if petInfo.model and petInfo.model.Parent then
            petInfo.model:Destroy()
        end
    end
    activePets = {}
end

-- Cleanup
function PetFollowService:Cleanup()
    self:ClearAllPets()
end

return PetFollowService