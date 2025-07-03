-- Pet Follow Service
-- Handles assigned pets following the player with animations
-- Ground pets bounce/walk, flying pets float above player's head

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetConfig = require(ReplicatedStorage.Shared.config.PetConfig)

local PetFollowService = {}
PetFollowService.__index = PetFollowService

local player = Players.LocalPlayer
local activePets = {} -- Table to store active pet instances
local petConnections = {} -- Store connections for cleanup
local lastPlayerPosition = nil
local isPlayerMoving = false
local movementCheckConnection = nil

-- Configuration
local GROUND_PET_HEIGHT = 0 -- Height above ground for ground pets
local FLYING_PET_HEIGHT = 8 -- Height above player's head for flying pets
local PET_SPACING = 4 -- Distance between pets
local FOLLOW_DISTANCE = 6 -- Distance behind player
local MOVEMENT_THRESHOLD = 0.1 -- Minimum movement to trigger animations
local ANIMATION_SPEED = 2 -- Speed of bounce/float animations

-- Utility function to load actual pet model (using same method as PetGrowthService)
local function createPetModel(petData)
    local petConfig = PetConfig:GetPetData(petData.id or 1)
    if not petConfig then return nil end
    
    -- Load from ReplicatedStorage assets FOLDER (not the ModuleScript)
    local assets = nil
    for _, child in pairs(ReplicatedStorage:GetChildren()) do
        if child.Name == "assets" and child.ClassName == "Folder" then
            assets = child
            break
        end
    end
    
    
    local petModel = nil
    if assets and petConfig.assetPath then
        local pathParts = string.split(petConfig.assetPath, "/")
        local currentFolder = assets
        
        -- Navigate through the path
        for _, pathPart in ipairs(pathParts) do
            currentFolder = currentFolder:FindFirstChild(pathPart)
            if not currentFolder then
                break
            end
        end
        
        if currentFolder and currentFolder:IsA("Model") then
            petModel = currentFolder
        end
    end
    
    if not petModel then
        warn("PetFollowService: No pet model available for", petData.name)
        return nil
    end
    
    -- Clone the model for our use
    local clonedModel = petModel:Clone()
    clonedModel.Name = "Pet_" .. (petData.name or "Unknown"):gsub(" ", "_") .. "_" .. (petData.uniqueId or "")
    
    -- Configure model for pet use - keep parts anchored
    for _, part in pairs(clonedModel:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
            part.CanCollide = false
        end
    end
    
    -- Ensure model has a PrimaryPart - find the largest part
    if not clonedModel.PrimaryPart then
        local largestPart = nil
        local largestVolume = 0
        
        for _, part in pairs(clonedModel:GetDescendants()) do
            if part:IsA("BasePart") then
                local volume = part.Size.X * part.Size.Y * part.Size.Z
                if volume > largestVolume then
                    largestVolume = volume
                    largestPart = part
                end
            end
        end
        
        if largestPart then
            clonedModel.PrimaryPart = largestPart
        else
            -- Fallback to first part
            local firstPart = clonedModel:FindFirstChildOfClass("BasePart")
            if firstPart then
                clonedModel.PrimaryPart = firstPart
            end
        end
    end
    
    -- No welding needed - we'll move all parts together manually
    
    -- Apply proper scaling (smaller to match plot pets)
    local baseScale = 0.3 -- Match the plot pet size
    local sizeData = PetConfig:GetSizeData(petData.size or 1)
    local sizeMultiplier = (sizeData and sizeData.multiplier) or 1
    local finalScale = baseScale * sizeMultiplier
    
    -- Scale the model using the same method as PetGrowthService
    local function scaleModel(model, scale)
        -- Get or calculate the model's center point
        local modelCenter = Vector3.new(0, 0, 0)
        local partCount = 0
        for _, part in pairs(model:GetDescendants()) do
            if part:IsA("BasePart") then
                modelCenter = modelCenter + part.Position
                partCount = partCount + 1
            end
        end
        if partCount > 0 then
            modelCenter = modelCenter / partCount
        end
        
        -- Scale all parts relative to model center
        for _, part in pairs(model:GetDescendants()) do
            if part:IsA("BasePart") then
                -- Scale the part size
                part.Size = part.Size * scale
                
                -- Scale position relative to model center
                local offset = part.Position - modelCenter
                part.Position = modelCenter + (offset * scale)
            end
        end
    end
    
    scaleModel(clonedModel, finalScale)
    
    -- Add aura effect if not "none"
    local auraData = PetConfig.AURAS[petData.aura or "none"] or PetConfig.AURAS.none
    if petData.aura and petData.aura ~= "none" then
        -- Add aura glow effect to all parts
        for _, child in pairs(clonedModel:GetDescendants()) do
            if child:IsA("BasePart") then
                -- Add subtle glow effect
                local pointLight = Instance.new("PointLight")
                pointLight.Color = auraData.color
                pointLight.Brightness = 0.5
                pointLight.Range = 5
                pointLight.Parent = child
                
                -- Remove selection box as it blocks the model view
                -- local selectionBox = Instance.new("SelectionBox")
                -- selectionBox.Parent = child
                -- selectionBox.Adornee = child
                -- selectionBox.Color3 = auraData.color
                -- selectionBox.Transparency = 0.7
                -- selectionBox.LineThickness = 0.1
            end
        end
    end
    
    -- Add name tag
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 100, 0, 25)
    billboard.StudsOffset = Vector3.new(0, 3 * finalScale, 0) -- Adjust height based on final scale
    billboard.Parent = clonedModel.PrimaryPart or clonedModel:FindFirstChildOfClass("BasePart")
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = petData.name or "Pet"
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard
    
    local textStroke = Instance.new("UIStroke")
    textStroke.Color = Color3.new(0, 0, 0)
    textStroke.Thickness = 2
    textStroke.Parent = nameLabel
    
    return clonedModel
end

-- Calculate pet position based on index and type
local function calculatePetPosition(playerPosition, playerLookDirection, petIndex, isFlying)
    -- Calculate base position behind player
    local baseOffset = playerLookDirection * -FOLLOW_DISTANCE
    
    -- Calculate lateral offset for multiple pets
    local lateralOffset = Vector3.new(0, 0, 0)
    if petIndex > 1 then
        local sideOffset = (petIndex - 1) * PET_SPACING
        -- Alternate pets on left and right
        if petIndex % 2 == 0 then
            sideOffset = sideOffset * -1
        end
        lateralOffset = playerLookDirection:Cross(Vector3.new(0, 1, 0)).Unit * sideOffset
    end
    
    -- Calculate height offset
    local heightOffset = Vector3.new(0, 0, 0)
    if isFlying then
        heightOffset = Vector3.new(0, FLYING_PET_HEIGHT, 0)
    else
        heightOffset = Vector3.new(0, GROUND_PET_HEIGHT, 0)
    end
    
    return playerPosition + baseOffset + lateralOffset + heightOffset
end

-- Create bounce animation for ground pets
local function createBounceAnimation(petModel)
    if not petModel or not petModel.Parent or not petModel.PrimaryPart then return end
    
    local primaryPart = petModel.PrimaryPart
    local bounceHeight = 1
    
    local bounceUp = TweenService:Create(primaryPart,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Position = primaryPart.Position + Vector3.new(0, bounceHeight, 0)}
    )
    
    local bounceDown = TweenService:Create(primaryPart,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Position = primaryPart.Position}
    )
    
    bounceUp:Play()
    bounceUp.Completed:Connect(function()
        if petModel and petModel.Parent and petModel.PrimaryPart then
            bounceDown:Play()
        end
    end)
end

-- Create floating animation for flying pets
local function createFloatAnimation(petModel)
    if not petModel or not petModel.Parent or not petModel.PrimaryPart then return end
    
    local primaryPart = petModel.PrimaryPart
    local floatHeight = 0.5
    
    local floatUp = TweenService:Create(primaryPart,
        TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        {Position = primaryPart.Position + Vector3.new(0, floatHeight, 0)}
    )
    
    local floatDown = TweenService:Create(primaryPart,
        TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        {Position = primaryPart.Position - Vector3.new(0, floatHeight, 0)}
    )
    
    -- Create looping float animation
    local function startFloatLoop()
        floatUp:Play()
        floatUp.Completed:Connect(function()
            if petModel and petModel.Parent and petModel.PrimaryPart then
                floatDown:Play()
                floatDown.Completed:Connect(function()
                    if petModel and petModel.Parent and petModel.PrimaryPart then
                        startFloatLoop()
                    end
                end)
            end
        end)
    end
    
    startFloatLoop()
end

-- Update pet positions (reduced frequency for performance)
local lastUpdateTime = 0
local UPDATE_FREQUENCY = 0.05 -- Update every 0.05 seconds for smoother movement

-- Cache player data to avoid repeated lookups
local cachedCharacter = nil
local cachedHumanoidRootPart = nil

local function updatePetPositions()
    local currentTime = tick()
    if currentTime - lastUpdateTime < UPDATE_FREQUENCY then
        return -- Skip this frame
    end
    lastUpdateTime = currentTime
    
    -- Cache character references
    if not cachedCharacter or not cachedCharacter.Parent then
        cachedCharacter = player.Character
        cachedHumanoidRootPart = cachedCharacter and cachedCharacter:FindFirstChild("HumanoidRootPart")
    end
    
    if not cachedHumanoidRootPart then return end
    
    local playerPosition = cachedHumanoidRootPart.Position
    local playerLookDirection = cachedHumanoidRootPart.CFrame.LookVector
    
    -- Check if player is moving
    if lastPlayerPosition then
        local movementDistance = (playerPosition - lastPlayerPosition).Magnitude
        isPlayerMoving = movementDistance > MOVEMENT_THRESHOLD
    end
    lastPlayerPosition = playerPosition
    
    -- Update each pet position
    for i, petInfo in ipairs(activePets) do
        local petModel = petInfo.model
        local petData = petInfo.data
        local petConfig = PetConfig:GetPetData(petData.id or 1)
        
        if petModel and petModel.Parent and petModel.PrimaryPart and petConfig then
            local isFlying = petConfig.isFlyingPet or false
            local targetPosition = calculatePetPosition(playerPosition, playerLookDirection, i, isFlying)
            
            -- Smooth pet movement
            
            -- Store the current pet info for smooth movement
            if not petInfo.targetPosition then
                petInfo.targetPosition = targetPosition
            end
            
            -- Only update pets that are actually moving or need updating
            local needsUpdate = false
            if isPlayerMoving or petInfo.isAnimating then
                needsUpdate = true
            elseif petInfo.targetPosition then
                local distanceToTarget = (targetPosition - petInfo.targetPosition).Magnitude
                needsUpdate = distanceToTarget > 0.3
            else
                needsUpdate = true -- First update
            end
            
            if needsUpdate then
                petInfo.targetPosition = targetPosition
                
                -- Calculate direction to face the player
                local directionToPlayer = (playerPosition - targetPosition).Unit
                local lookDirection = CFrame.lookAt(targetPosition, playerPosition)
                
                -- Cancel any existing tween for this pet
                if petInfo.moveTween then
                    petInfo.moveTween:Cancel()
                end
                
                -- Move the entire model using SetPrimaryPartCFrame for smoother movement
                if petModel.PrimaryPart then
                    -- Create smooth movement tween with rotation
                    local currentCFrame = petModel.PrimaryPart.CFrame
                    local targetCFrame = CFrame.new(targetPosition) * CFrame.Angles(0, lookDirection.LookVector:Cross(Vector3.new(0, 1, 0)).Magnitude > 0.1 and math.atan2(-lookDirection.LookVector.X, -lookDirection.LookVector.Z) or 0, 0)
                    
                    local moveInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                    local cframeValue = Instance.new("CFrameValue")
                    cframeValue.Value = currentCFrame
                    
                    local moveTween = TweenService:Create(cframeValue, moveInfo, {Value = targetCFrame})
                    petInfo.moveTween = moveTween
                    
                    -- Update model position and rotation as tween progresses
                    local connection = cframeValue.Changed:Connect(function(newCFrame)
                        if petModel and petModel.Parent and petModel.PrimaryPart then
                            petModel:SetPrimaryPartCFrame(newCFrame)
                        end
                    end)
                    
                    moveTween:Play()
                    moveTween.Completed:Connect(function()
                        cframeValue:Destroy()
                        connection:Disconnect()
                        petInfo.moveTween = nil
                    end)
                end
            end
            
            -- Trigger animations based on movement and pet type
            if isPlayerMoving then
                if isFlying then
                    -- Flying pets continue floating
                    if not petInfo.isAnimating then
                        createFloatAnimation(petModel)
                        petInfo.isAnimating = true
                    end
                else
                    -- Ground pets bounce when moving
                    if not petInfo.isAnimating then
                        createBounceAnimation(petModel)
                        petInfo.isAnimating = true
                        
                        -- Reset animation flag after bounce
                        task.wait(0.6)
                        petInfo.isAnimating = false
                    end
                end
            else
                -- Player stopped moving
                if isFlying and not petInfo.isFloating then
                    -- Start continuous floating for flying pets
                    createFloatAnimation(petModel)
                    petInfo.isFloating = true
                end
            end
        end
    end
end

-- Initialize the service
function PetFollowService:Initialize()
    
    -- Start position update loop
    if movementCheckConnection then
        movementCheckConnection:Disconnect()
    end
    
    movementCheckConnection = RunService.Heartbeat:Connect(updatePetPositions)
end

-- Update assigned pets (called when player data changes)
function PetFollowService:UpdateAssignedPets(playerData)
    -- Clear existing pets
    self:ClearAllPets()
    
    -- Get assigned pets
    local assignedPets = playerData.companionPets or {}
    
    -- Create new pet models
    for i, petData in ipairs(assignedPets) do
        local petModel = createPetModel(petData)
        if petModel then
            petModel.Parent = workspace
            
            -- Set initial position behind player if player exists
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                local humanoidRootPart = character.HumanoidRootPart
                local playerPosition = humanoidRootPart.Position
                local playerLookDirection = humanoidRootPart.CFrame.LookVector
                
                local petConfig = PetConfig:GetPetData(petData.id or 1)
                local isFlying = petConfig and petConfig.isFlyingPet or false
                local initialPosition = calculatePetPosition(playerPosition, playerLookDirection, i, isFlying)
                
                if petModel.PrimaryPart then
                    -- Calculate offset to move entire model to initial position
                    local currentModelCenter = petModel.PrimaryPart.Position
                    local offset = initialPosition - currentModelCenter
                    
                    -- Move all parts by the offset
                    for _, part in pairs(petModel:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.Position = part.Position + offset
                        end
                    end
                end
            end
            
            -- Store pet info
            
            table.insert(activePets, {
                model = petModel,
                data = petData,
                isAnimating = false,
                isFloating = false,
                targetPosition = nil,
                moveTween = nil
            })
        else
            warn("PetFollowService: Failed to create pet model for:", petData.name)
        end
    end
end

-- Clear all pets
function PetFollowService:ClearAllPets()
    for _, petInfo in ipairs(activePets) do
        -- Cancel any active tweens
        if petInfo.moveTween then
            petInfo.moveTween:Cancel()
        end
        
        -- Destroy the model
        if petInfo.model and petInfo.model.Parent then
            petInfo.model:Destroy()
        end
    end
    activePets = {}
end

-- Cleanup
function PetFollowService:Cleanup()
    if movementCheckConnection then
        movementCheckConnection:Disconnect()
        movementCheckConnection = nil
    end
    
    self:ClearAllPets()
    
    for _, connection in pairs(petConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    petConnections = {}
    
end

return PetFollowService