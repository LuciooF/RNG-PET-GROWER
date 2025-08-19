-- PetMixerAnimationService - Handles visual animations for pet mixer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local DataSyncService = require(script.Parent.DataSyncService)
local PetUtils = require(ReplicatedStorage.utils.PetUtils)
local PlayerAreaFinder = require(ReplicatedStorage.utils.PlayerAreaFinder)

local PetMixerAnimationService = {}
PetMixerAnimationService.__index = PetMixerAnimationService

local player = Players.LocalPlayer
local activeMixerAnimations = {} -- Track active animations by mixer ID
local mixerParts = {} -- Cache mixer parts by area
local connections = {}

-- Animation settings
local BOUNCE_HEIGHT = 5 -- Studs to bounce up (increased from 3)
local BOUNCE_DURATION = 0.8 -- Time for one bounce cycle
local SHINE_DURATION = 2 -- Duration of shine effect
local PET_BALL_SIZE = Vector3.new(1, 1, 1) -- Size of animated pet balls

-- Sound configuration
local COMPLETION_SOUND_ID = "rbxassetid://6946986098"

-- Pre-create completion sound for instant playback
local completionSound = Instance.new("Sound")
completionSound.SoundId = COMPLETION_SOUND_ID
completionSound.Volume = 0.8 -- Celebratory volume
completionSound.Parent = SoundService

-- Play completion sound instantly
local function playCompletionSound()
    completionSound:Play()
end

function PetMixerAnimationService:Initialize()
    -- Animation service initialized
    
    -- Delay initialization to ensure workspace is loaded
    task.wait(1.5) -- Slightly longer wait for animation service
    
    -- Find mixer parts in player's area
    self:FindMixerParts()
    
    -- Subscribe to player data changes to detect mixer state changes
    self:SetupDataSubscription()
    
    -- Handle character respawn
    player.CharacterAdded:Connect(function()
        self:Cleanup()
        -- Wait for area assignment and workspace loading
        task.wait(2)
        self:FindMixerParts()
        self:SetupDataSubscription()
    end)
    
    -- Set up retry mechanism for failed part findings
    self:SetupRetryMechanism()
end

function PetMixerAnimationService:FindMixerParts()
    -- Wait for character and area assignment
    if not player.Character then
        player.CharacterAdded:Wait()
    end
    
    -- Use the improved PlayerAreaFinder utility
    local PlayerAreaFinder = require(ReplicatedStorage.utils.PlayerAreaFinder)
    local playerArea = PlayerAreaFinder:WaitForPlayerArea(15)

    if not playerArea then
        warn("PetMixerAnimationService: Player area not found")
        return
    end
    
    -- Find Tubes folder and PetMixer parts
    local tubesFolder = playerArea:FindFirstChild("Tubes")
    if not tubesFolder then
        warn("PetMixerAnimationService: Tubes folder not found")
        return
    end
    
    -- Cache all PetMixer parts
    mixerParts = {}
    for _, child in pairs(tubesFolder:GetChildren()) do
        if child.Name:match("^PetMixer") then -- Matches PetMixer, PetMixer1, PetMixer2, etc.
            -- Try to find an anchor part - be flexible about the name
            local anchorPart = child:FindFirstChild("Cube.006")
                or child:FindFirstChild("Cube")
                or child:FindFirstChild("Anchor")
                or child:FindFirstChild("Center")
                or child:FindFirstChild("Union")
                or child:FindFirstChild("Part")
                or child:FindFirstChild("MeshPart")
                or child:FindFirstChildOfClass("BasePart")
            
            -- If still not found, search descendants for any suitable part
            if not anchorPart then
                for _, descendant in pairs(child:GetDescendants()) do
                    if descendant:IsA("BasePart") then
                        anchorPart = descendant
                        break
                    end
                end
            end
            
            if anchorPart and anchorPart:IsA("BasePart") then
                local mixerNumber = child.Name:match("PetMixer(%d*)") or "1"
                if mixerNumber == "" then mixerNumber = "1" end
                mixerParts[tonumber(mixerNumber)] = {
                    mixerModel = child,
                    anchorPart = anchorPart
                }
                -- PetMixerAnimationService found mixer
            else
                -- Store for retry instead of warning immediately
                if not self.failedMixers then
                    self.failedMixers = {}
                end
                table.insert(self.failedMixers, child)
            end
        end
    end
end

function PetMixerAnimationService:SetupRetryMechanism()
    -- Retry finding mixer parts after a delay
    task.spawn(function()
        task.wait(3) -- Wait for workspace to fully load
        
        if self.failedMixers and #self.failedMixers > 0 then
            warn("PetMixerAnimationService: Retrying", #self.failedMixers, "failed mixer part findings")
            
            for _, mixerModel in ipairs(self.failedMixers) do
                -- Try to find anchor part again
                local anchorPart = mixerModel:FindFirstChild("Cube.006")
                    or mixerModel:FindFirstChild("Cube")
                    or mixerModel:FindFirstChild("Anchor")
                    or mixerModel:FindFirstChild("Center")
                    or mixerModel:FindFirstChild("Union")
                    or mixerModel:FindFirstChild("Part")
                    or mixerModel:FindFirstChild("MeshPart")
                    or mixerModel:FindFirstChildOfClass("BasePart")
                
                -- If still not found, search descendants
                if not anchorPart then
                    for _, descendant in pairs(mixerModel:GetDescendants()) do
                        if descendant:IsA("BasePart") then
                            anchorPart = descendant
                            break
                        end
                    end
                end
                
                if anchorPart and anchorPart:IsA("BasePart") then
                    local mixerNumber = mixerModel.Name:match("PetMixer(%d*)") or "1"
                    if mixerNumber == "" then mixerNumber = "1" end
                    mixerParts[tonumber(mixerNumber)] = {
                        mixerModel = mixerModel,
                        anchorPart = anchorPart
                    }
                    print("PetMixerAnimationService: Successfully found mixer", mixerNumber, "on retry")
                else
                    warn("PetMixerAnimationService: Still couldn't find anchor part for", mixerModel.Name, "after retry")
                end
            end
            
            -- Clear the retry list
            self.failedMixers = {}
        end
    end)
end

function PetMixerAnimationService:SetupDataSubscription()
    -- Clean up existing connection
    if connections.dataSync then
        connections.dataSync:Disconnect()
    end
    
    local lastMixerStates = {}
    
    connections.dataSync = DataSyncService:Subscribe(function(newState)
        if not newState.player or not newState.player.Mixers then return end
        
        local currentMixers = newState.player.Mixers
        
        -- Check for new mixers (start animations)
        for _, mixer in ipairs(currentMixers) do
            if not lastMixerStates[mixer.id] then
                -- New mixer started
                self:StartMixingAnimation(mixer)
                lastMixerStates[mixer.id] = {
                    claimed = mixer.claimed,
                    completionTime = mixer.completionTime
                }
            elseif lastMixerStates[mixer.id] and not lastMixerStates[mixer.id].claimed and mixer.claimed then
                -- Mixer was claimed
                self:StopMixingAnimation(mixer.id)
                lastMixerStates[mixer.id] = nil
            elseif lastMixerStates[mixer.id] and not lastMixerStates[mixer.id].completed and os.time() >= mixer.completionTime then
                -- Mixer just completed
                self:ShowCompletionEffect(mixer)
                lastMixerStates[mixer.id].completed = true
            end
        end
        
        -- Check for removed mixers (cleanup)
        local currentMixerIds = {}
        for _, mixer in ipairs(currentMixers) do
            currentMixerIds[mixer.id] = true
        end
        
        for mixerId, _ in pairs(lastMixerStates) do
            if not currentMixerIds[mixerId] then
                self:StopMixingAnimation(mixerId)
                lastMixerStates[mixerId] = nil
            end
        end
    end)
end

function PetMixerAnimationService:StartMixingAnimation(mixer)
    local mixerNumber = 1 -- Default to mixer 1, could be enhanced to support multiple mixers
    local mixerData = mixerParts[mixerNumber]
    
    if not mixerData or not mixerData.anchorPart then
        warn("PetMixerAnimationService: Mixer", mixerNumber, "not found for animation")
        return
    end
    
    -- Start mixing animation
    
    -- Stop any existing animation for this mixer
    self:StopMixingAnimation(mixer.id)
    
    local anchorPart = mixerData.anchorPart
    local mixerModel = mixerData.mixerModel
    
    -- Create folder to hold animated pet balls
    local animationFolder = Instance.new("Folder")
    animationFolder.Name = "MixingAnimation_" .. mixer.id
    animationFolder.Parent = mixerModel
    
    -- Create animated pet balls based on input pets
    local petBalls = {}
    local petCount = math.min(#mixer.inputPets, 10) -- Limit visual pets to prevent lag
    
    for i = 1, petCount do
        local pet = mixer.inputPets[i]
        local petBall = self:CreateAnimatedPetBall(pet, anchorPart.Position)
        petBall.Parent = animationFolder
        table.insert(petBalls, petBall)
    end
    
    -- Create mixing particle effects
    local particleEmitters = self:CreateMixingParticles(anchorPart, animationFolder)
    
    -- Create mixing timer GUI
    local timerGUI = self:CreateMixingTimerGUI(mixer, mixerModel)
    
    -- Start bouncing animations with different timing for each pet ball
    local animationData = {
        petBalls = petBalls,
        animationFolder = animationFolder,
        bounceConnections = {},
        particleEmitters = particleEmitters,
        timerGUI = timerGUI
    }
    
    for i, petBall in ipairs(petBalls) do
        -- Create circular positions around the anchor
        local angle = (i - 1) * (math.pi * 2 / petCount)
        local radius = 1.5 -- Reduced from 3 to bring pet balls closer together
        local basePosition = anchorPart.Position + Vector3.new(
            math.cos(angle) * radius,
            0,
            math.sin(angle) * radius
        )
        
        -- Set initial position
        petBall.Position = basePosition
        
        -- Start bouncing animation with offset timing
        local bounceOffset = (i - 1) * 0.2 -- Stagger bounces
        animationData.bounceConnections[i] = self:StartBounceAnimation(petBall, basePosition, bounceOffset)
    end
    
    activeMixerAnimations[mixer.id] = animationData
end

function PetMixerAnimationService:CreateAnimatedPetBall(pet, centerPosition)
    -- Create pet model FIRST (like ClientPetBallService)
    local petModel = self:CreatePetModel(pet)
    if not petModel then
        warn("PetMixerAnimationService: Failed to create pet model")
        return self:CreateFallbackPetBall(pet)
    end
    
    -- Calculate appropriate ball size based on pet model (like ClientPetBallService)
    local modelSize = petModel:GetExtentsSize()
    local ballSize = math.min(2.0, math.max(modelSize.X, modelSize.Y, modelSize.Z) * 0.8)
    
    -- Create pet ball sized appropriately around the model
    local petBall = Instance.new("Part")
    petBall.Name = "AnimatedPetBall_" .. (pet.Name or "Unknown")
    petBall.Shape = Enum.PartType.Ball
    petBall.Size = Vector3.new(ballSize, ballSize, ballSize)
    
    -- Get variation color (like ClientPetBallService)
    local PetConstants = require(ReplicatedStorage.constants.PetConstants)
    local variation = pet.Variation
    if type(variation) == "table" then
        variation = variation.VariationName or "Bronze"
    elseif type(variation) ~= "string" then
        variation = "Bronze"
    end
    local variationColor = PetConstants.getVariationColor(variation)
    petBall.Color = variationColor
    
    petBall.Material = Enum.Material.Neon
    petBall.Transparency = 0.87 -- Very transparent with hint of color (like ClientPetBallService)
    petBall.CanCollide = false
    petBall.Anchored = true
    
    -- Position the ball at center position
    petBall.Position = centerPosition
    
    -- Parent pet model to ball and position it (like ClientPetBallService)
    petModel.Parent = petBall
    
    -- Position all pet parts at the ball center and weld them properly (like ClientPetBallService)
    for _, descendant in pairs(petModel:GetDescendants()) do
        if descendant:IsA("BasePart") then
            -- Position the part at the ball center
            descendant.Position = petBall.Position
            
            -- Set physics properties to follow ball animation
            descendant.Anchored = true -- Keep anchored so they follow ball position exactly
            descendant.CanCollide = false
            descendant.Massless = true
            descendant.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            descendant.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            
            -- Create a robust weld (like ClientPetBallService)
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = petBall
            weld.Part1 = descendant
            weld.Parent = petBall
            
            -- Store reference to prevent garbage collection
            descendant:SetAttribute("WeldedToBall", true)
            
            -- Custom physical properties (like ClientPetBallService)
            descendant.CustomPhysicalProperties = PhysicalProperties.new(
                0.01, -- Density (very light)
                0.5,  -- Friction
                0,    -- Elasticity
                1,    -- FrictionWeight
                1     -- ElasticityWeight
            )
        end
    end
    
    -- Add pet name GUI above the ball (like ClientPetBallService)
    self:CreatePetNameGUI(petBall, pet)
    
    -- Add glowing effect
    local pointLight = Instance.new("PointLight")
    pointLight.Brightness = 1
    pointLight.Range = 5
    pointLight.Color = variationColor
    pointLight.Parent = petBall
    
    return petBall
end

function PetMixerAnimationService:CreatePetModel(petData)
    -- Try to get actual pet model from ReplicatedStorage.Pets (like ClientPetBallService)
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
            
            -- Process all parts in the model (like ClientPetBallService)
            local scaleFactor = 0.15 -- Even smaller to fit inside the smaller ball
            
            for _, descendant in pairs(clonedModel:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    descendant.Size = descendant.Size * scaleFactor
                    descendant.CanCollide = false
                    descendant.Anchored = false
                    descendant.Massless = true
                    -- Make parts visible (like ClientPetBallService)
                    descendant.Transparency = math.min(descendant.Transparency, 0.5) -- Max 50% transparent
                    descendant.Material = Enum.Material.Neon -- Make them glow to be more visible
                end
            end
            
            -- Find or create PrimaryPart (like ClientPetBallService)
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
            
            -- If still no PrimaryPart, try to find one (like ClientPetBallService)
            if not clonedModel.PrimaryPart then
                for _, child in pairs(clonedModel:GetChildren()) do
                    if child:IsA("BasePart") then
                        clonedModel.PrimaryPart = child
                        break
                    end
                end
                
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
    
    return nil -- No fallback here, will be handled by CreateFallbackPetBall
end

function PetMixerAnimationService:CreateFallbackPetBall(pet)
    -- Fallback: create original simple colored ball (like old CreateAnimatedPetBall)
    local petBall = Instance.new("Part")
    petBall.Name = "AnimatedPetBall_" .. (pet.Name or "Unknown")
    petBall.Size = PET_BALL_SIZE
    petBall.Shape = Enum.PartType.Ball
    petBall.Material = Enum.Material.Neon
    petBall.CanCollide = false
    petBall.Anchored = true
    
    -- Set color based on pet variation
    local PetConstants = require(ReplicatedStorage.constants.PetConstants)
    local variation = pet.Variation
    if type(variation) == "table" then
        variation = variation.VariationName or "Bronze"
    elseif type(variation) ~= "string" then
        variation = "Bronze"
    end
    local variationColor = PetConstants.getVariationColor(variation)
    petBall.Color = variationColor
    
    -- Add glowing effect
    local pointLight = Instance.new("PointLight")
    pointLight.Brightness = 1
    pointLight.Range = 5
    pointLight.Color = variationColor
    pointLight.Parent = petBall
    
    return petBall
end

function PetMixerAnimationService:CreatePetNameGUI(petBall, petData)
    -- Create BillboardGui (like ClientPetBallService)
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "PetNameGUI"
    billboardGui.Size = UDim2.new(0, 35, 0, 35) -- Small size for mixing animation
    billboardGui.StudsOffset = Vector3.new(0, 2.5, 0) -- Above ball
    billboardGui.LightInfluence = 0
    billboardGui.AlwaysOnTop = true
    billboardGui.Enabled = true -- Always visible during mixing
    billboardGui.Parent = petBall
    
    -- Create TextLabel (like ClientPetBallService)
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1 -- No background
    -- Create text with variation and pet name
    local variationName = petData.Variation
    if type(variationName) == "table" then
        variationName = variationName.VariationName or "Bronze"
    elseif type(variationName) ~= "string" then
        variationName = "Bronze"
    end
    
    local petName = petData.Name or "Unknown Pet"
    nameLabel.Text = variationName .. "\\n" .. petName
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    
    -- Get variation color (like ClientPetBallService)
    local PetConstants = require(ReplicatedStorage.constants.PetConstants)
    local variationColor = PetConstants.getVariationColor(variationName)
    nameLabel.TextColor3 = variationColor
    
    -- Add black outline (like ClientPetBallService)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0) -- Black outline
    
    nameLabel.Parent = billboardGui
    
    return billboardGui
end

function PetMixerAnimationService:CreateMixingParticles(anchorPart, parentFolder)
    local particleEmitters = {}
    
    -- Create multiple particle emitters for a rich mixing effect
    for i = 1, 3 do
        local particlePart = Instance.new("Part")
        particlePart.Name = "ParticleEmitter" .. i
        particlePart.Size = Vector3.new(0.1, 0.1, 0.1)
        particlePart.Transparency = 1
        particlePart.CanCollide = false
        particlePart.Anchored = true
        
        -- Position particles around the anchor in a triangle
        local angle = (i - 1) * (math.pi * 2 / 3)
        local radius = 1
        particlePart.Position = anchorPart.Position + Vector3.new(
            math.cos(angle) * radius,
            1, -- Slightly above the anchor
            math.sin(angle) * radius
        )
        particlePart.Parent = parentFolder
        
        -- Create sparkle/magic particles
        local attachment = Instance.new("Attachment")
        attachment.Parent = particlePart
        
        -- Main swirling particles
        local particles1 = Instance.new("ParticleEmitter")
        particles1.Parent = attachment
        particles1.Enabled = true
        particles1.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        particles1.Lifetime = NumberRange.new(0.8, 1.2)
        particles1.Rate = 50
        particles1.SpreadAngle = Vector2.new(45, 45)
        particles1.Speed = NumberRange.new(3, 6)
        particles1.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 255)), -- Purple
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 215, 0)), -- Gold
            ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 255, 255))  -- Cyan
        }
        particles1.Size = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(0.5, 1.2),
            NumberSequenceKeypoint.new(1, 0.2)
        }
        particles1.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.3),
            NumberSequenceKeypoint.new(1, 1)
        }
        
        -- Secondary glowing dust particles
        local particles2 = Instance.new("ParticleEmitter")
        particles2.Parent = attachment
        particles2.Enabled = true
        particles2.Texture = "rbxasset://textures/particles/fire_main.dds"
        particles2.Lifetime = NumberRange.new(1.5, 2.0)
        particles2.Rate = 25
        particles2.SpreadAngle = Vector2.new(180, 180)
        particles2.Speed = NumberRange.new(1, 3)
        particles2.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 100)), -- Light yellow
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 255))  -- Purple
        }
        particles2.Size = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.3),
            NumberSequenceKeypoint.new(1, 0.8)
        }
        particles2.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(1, 1)
        }
        
        table.insert(particleEmitters, {particlePart, particles1, particles2})
    end
    
    return particleEmitters
end

function PetMixerAnimationService:CreateMixingTimerGUI(mixer, mixerModel)
    local mixerNumber = 1 -- Default to mixer 1
    local mixerData = mixerParts[mixerNumber]
    
    if not mixerData or not mixerData.anchorPart then
        return nil
    end
    
    local anchorPart = mixerData.anchorPart
    
    -- Create BillboardGui centered on anchor part
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "MixingTimer"
    billboardGui.Size = UDim2.new(0, 280, 0, 100) -- Slightly wider for timer text
    billboardGui.StudsOffset = Vector3.new(0, 18, 0) -- Higher above mixer
    billboardGui.MaxDistance = 100 -- Much further visibility for camera angles
    billboardGui.Parent = anchorPart
    
    -- Create timer label
    local timerLabel = Instance.new("TextLabel")
    timerLabel.Name = "TimerText"
    timerLabel.Size = UDim2.new(1, 0, 1, 0)
    timerLabel.BackgroundTransparency = 1
    timerLabel.Font = Enum.Font.FredokaOne
    timerLabel.Text = "Mixing..."
    timerLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold color
    timerLabel.TextSize = 36
    timerLabel.TextStrokeTransparency = 0
    timerLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    timerLabel.Parent = billboardGui
    
    -- Update timer continuously
    local startTime = tick()
    local completionTime = mixer.completionTime
    
    local updateConnection = RunService.Heartbeat:Connect(function()
        local currentTime = os.time()
        local timeLeft = completionTime - currentTime
        
        if timeLeft <= 0 then
            timerLabel.Text = "Done!"
            timerLabel.TextColor3 = Color3.fromRGB(0, 255, 0) -- Green when done
        else
            -- Format time as MM:SS
            local minutes = math.floor(timeLeft / 60)
            local seconds = timeLeft % 60
            
            if minutes > 0 then
                timerLabel.Text = string.format("Mixing... %dm %ds", minutes, seconds)
            else
                timerLabel.Text = string.format("Mixing... %ds", seconds)
            end
        end
    end)
    
    -- Return GUI and connection for cleanup
    return {
        gui = billboardGui,
        connection = updateConnection
    }
end

function PetMixerAnimationService:StartBounceAnimation(petBall, basePosition, timeOffset)
    local startTime = tick() + timeOffset
    
    local connection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        if elapsed < 0 then return end -- Wait for offset
        
        -- Calculate bounce using sine wave
        local bouncePhase = (elapsed % BOUNCE_DURATION) / BOUNCE_DURATION
        local bounceHeight = math.sin(bouncePhase * math.pi) * BOUNCE_HEIGHT
        
        -- Calculate new position and rotation
        local newPosition = basePosition + Vector3.new(0, bounceHeight, 0)
        local newCFrame = CFrame.new(newPosition) * CFrame.Angles(0, elapsed * 2, 0)
        
        -- Update ball position and rotation
        petBall.Position = newPosition
        petBall.CFrame = newCFrame
        
        -- Update all pet model parts to follow the ball exactly
        local petModel = petBall:FindFirstChild("PetModel")
        if petModel then
            for _, descendant in pairs(petModel:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    -- Move pet parts to follow ball position exactly
                    descendant.Position = newPosition
                    descendant.CFrame = newCFrame -- Also apply rotation to pet parts
                end
            end
        end
    end)
    
    return connection
end

function PetMixerAnimationService:ShowCompletionEffect(mixer)
    local mixerNumber = 1 -- Default to mixer 1
    local mixerData = mixerParts[mixerNumber]
    
    if not mixerData or not mixerData.mixerModel then
        return
    end
    
    -- Show completion effect
    
    local mixerModel = mixerData.mixerModel
    local anchorPart = mixerData.anchorPart
    
    -- Play completion sound at the start of the animation block
    playCompletionSound()
    
    -- Stop just the mixing animation parts (balls and particles) but keep mixer tracked
    self:StopMixingAnimationOnly(mixer.id)
    
    -- Clean up any existing mixing timer GUI to prevent overlap
    local existingTimer = mixerModel:FindFirstChild("MixingTimer", true)
    if existingTimer then
        existingTimer:Destroy()
    end
    
    -- Create shine effect
    self:CreateShineEffect(mixerModel)
    
    -- Create completion particle burst
    self:CreateCompletionParticles(anchorPart, mixerModel)
    
    -- Create bouncing crafted pet ball
    self:CreateCraftedPetBall(mixer, anchorPart, mixerModel)
    
    -- Create "Done!" GUI (higher and bigger)
    self:CreateDoneGUI(mixerModel)
end

function PetMixerAnimationService:CreateShineEffect(mixerModel)
    -- Create a glowing part that expands and fades
    local shinePart = Instance.new("Part")
    shinePart.Name = "ShineEffect"
    shinePart.Size = Vector3.new(1, 1, 1)
    shinePart.Shape = Enum.PartType.Ball
    shinePart.Material = Enum.Material.ForceField
    shinePart.Color = Color3.fromRGB(255, 255, 0) -- Bright yellow
    shinePart.CanCollide = false
    shinePart.Anchored = true
    shinePart.Transparency = 0.3
    
    -- Position at mixer center
    local cframe, size = mixerModel:GetBoundingBox()
    shinePart.Position = cframe.Position
    shinePart.Parent = mixerModel
    
    -- Create expanding and fading tween
    local expandInfo = TweenInfo.new(
        SHINE_DURATION,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out,
        0,
        false,
        0
    )
    
    local expandTween = TweenService:Create(shinePart, expandInfo, {
        Size = Vector3.new(8, 8, 8),
        Transparency = 1
    })
    
    expandTween:Play()
    
    -- Clean up after animation
    expandTween.Completed:Connect(function()
        shinePart:Destroy()
    end)
end

function PetMixerAnimationService:CreateCompletionParticles(anchorPart, mixerModel)
    -- Create a burst of celebration particles
    local particlePart = Instance.new("Part")
    particlePart.Name = "CompletionParticles"
    particlePart.Size = Vector3.new(0.1, 0.1, 0.1)
    particlePart.Transparency = 1
    particlePart.CanCollide = false
    particlePart.Anchored = true
    particlePart.Position = anchorPart.Position + Vector3.new(0, 2, 0) -- Above the anchor
    particlePart.Parent = mixerModel
    
    local attachment = Instance.new("Attachment")
    attachment.Parent = particlePart
    
    -- Celebration burst particles
    local burstParticles = Instance.new("ParticleEmitter")
    burstParticles.Parent = attachment
    burstParticles.Enabled = false -- We'll burst manually
    burstParticles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    burstParticles.Lifetime = NumberRange.new(1.5, 2.5)
    burstParticles.Rate = 200
    burstParticles.SpreadAngle = Vector2.new(180, 180)
    burstParticles.Speed = NumberRange.new(8, 15)
    burstParticles.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)), -- Gold
        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 100, 255)), -- Purple
        ColorSequenceKeypoint.new(0.7, Color3.fromRGB(100, 255, 100)), -- Green
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))  -- White
    }
    burstParticles.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 1.0),
        NumberSequenceKeypoint.new(0.5, 1.8),
        NumberSequenceKeypoint.new(1, 0.5)
    }
    burstParticles.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 1)
    }
    
    -- Confetti particles
    local confettiParticles = Instance.new("ParticleEmitter")
    confettiParticles.Parent = attachment
    confettiParticles.Enabled = false
    confettiParticles.Texture = "rbxasset://textures/particles/fire_main.dds"
    confettiParticles.Lifetime = NumberRange.new(2.0, 3.0)
    confettiParticles.Rate = 100
    confettiParticles.SpreadAngle = Vector2.new(45, 45)
    confettiParticles.Speed = NumberRange.new(5, 12)
    confettiParticles.Acceleration = Vector3.new(0, -20, 0) -- Gravity effect
    confettiParticles.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 100)), -- Red
        ColorSequenceKeypoint.new(0.25, Color3.fromRGB(100, 255, 100)), -- Green
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 100, 255)), -- Blue
        ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 255, 100)), -- Yellow
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 255))  -- Magenta
    }
    confettiParticles.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.8),
        NumberSequenceKeypoint.new(1, 1.2)
    }
    
    -- Trigger the burst
    burstParticles:Emit(150)
    confettiParticles:Emit(100)
    
    -- Clean up after particles finish
    Debris:AddItem(particlePart, 5)
end

function PetMixerAnimationService:CreateCraftedPetBall(mixer, anchorPart, mixerModel)
    -- Create a bouncing pet ball representing the crafted pet
    local craftedPet = mixer.outputPet
    if not craftedPet then return end
    
    local craftedBall = self:CreateAnimatedPetBall(craftedPet, anchorPart.Position)
    craftedBall.Name = "CraftedPetBall"
    craftedBall.Parent = mixerModel
    
    -- Position the ball at the anchor point
    local basePosition = anchorPart.Position + Vector3.new(0, 1, 0) -- Slightly above anchor
    craftedBall.Position = basePosition
    
    -- Make it slightly bigger to show it's special
    craftedBall.Size = PET_BALL_SIZE * 1.3
    
    -- Add extra glow effect for the crafted pet
    local extraGlow = Instance.new("PointLight")
    extraGlow.Brightness = 2
    extraGlow.Range = 8
    extraGlow.Color = craftedBall.Color
    extraGlow.Parent = craftedBall
    
    -- Create pulsing glow effect
    local pulseInfo = TweenInfo.new(
        1.0,
        Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut,
        -1, -- Infinite
        true, -- Reverse
        0
    )
    
    local pulseTween = TweenService:Create(extraGlow, pulseInfo, {
        Brightness = 3,
        Range = 12
    })
    pulseTween:Play()
    
    -- Start bouncing animation (continuous until claimed)
    local startTime = tick()
    local bounceConnection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        
        -- Calculate bounce using sine wave (same as mixing animation but continuous)
        local bouncePhase = (elapsed % BOUNCE_DURATION) / BOUNCE_DURATION
        local bounceHeight = math.sin(bouncePhase * math.pi) * BOUNCE_HEIGHT
        
        -- Calculate new position and rotation
        local newPosition = basePosition + Vector3.new(0, bounceHeight, 0)
        local newCFrame = CFrame.new(newPosition) * CFrame.Angles(0, elapsed * 0.5, 0)
        
        -- Update ball position and rotation
        craftedBall.Position = newPosition
        craftedBall.CFrame = newCFrame
        
        -- Update all pet model parts to follow the ball exactly
        local petModel = craftedBall:FindFirstChild("PetModel")
        if petModel then
            for _, descendant in pairs(petModel:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    -- Move pet parts to follow ball position exactly
                    descendant.Position = newPosition
                    descendant.CFrame = newCFrame -- Also apply rotation to pet parts
                end
            end
        end
    end)
    
    -- Clean up after 10 seconds or when mixer is claimed
    local function cleanup()
        if bounceConnection then
            bounceConnection:Disconnect()
        end
        if pulseTween then
            pulseTween:Cancel()
        end
        if craftedBall then
            craftedBall:Destroy()
        end
    end
    
    -- Store cleanup function in animation data so it can be called when mixer is claimed
    -- Don't auto-cleanup - will be cleaned up when mixer is claimed
    if not activeMixerAnimations[mixer.id] then
        activeMixerAnimations[mixer.id] = {}
    end
    activeMixerAnimations[mixer.id].craftedBallCleanup = cleanup
end

function PetMixerAnimationService:CreateDoneGUI(mixerModel)
    local mixerNumber = 1 -- Default to mixer 1
    local mixerData = mixerParts[mixerNumber]
    
    if not mixerData or not mixerData.anchorPart then
        return
    end
    
    local anchorPart = mixerData.anchorPart
    
    -- Create BillboardGui centered on anchor part
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "DoneEffect"
    billboardGui.Size = UDim2.new(0, 250, 0, 120) -- Slightly bigger (was 200x100)
    billboardGui.StudsOffset = Vector3.new(0, 18, 0) -- Higher above mixer (same as timer)
    billboardGui.MaxDistance = 100 -- Much further visibility for camera angles
    billboardGui.Parent = anchorPart
    
    -- Create "Done!" label
    local doneLabel = Instance.new("TextLabel")
    doneLabel.Name = "DoneText"
    doneLabel.Size = UDim2.new(1, 0, 1, 0)
    doneLabel.BackgroundTransparency = 1
    doneLabel.Font = Enum.Font.FredokaOne
    doneLabel.Text = "Done!"
    doneLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    doneLabel.TextSize = 42 -- Slightly bigger (was 36)
    doneLabel.TextStrokeTransparency = 0
    doneLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    doneLabel.Parent = billboardGui
    
    -- Create pulsing animation
    local pulseInfo = TweenInfo.new(
        0.5,
        Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut,
        4, -- Repeat 4 times
        true, -- Reverse
        0
    )
    
    local pulseTween = TweenService:Create(doneLabel, pulseInfo, {
        TextSize = 56 -- Slightly bigger pulse (was 48)
    })
    
    pulseTween:Play()
    
    -- Don't auto-cleanup - GUI will be removed when mixer is claimed
end

-- Stop only the mixing animation (balls and particles) but keep mixer tracked for completion
function PetMixerAnimationService:StopMixingAnimationOnly(mixerId)
    local animationData = activeMixerAnimations[mixerId]
    if not animationData then return end
    
    -- Stop animation parts only
    
    -- Disconnect bounce connections
    for _, connection in pairs(animationData.bounceConnections) do
        if connection and typeof(connection) == "RBXScriptConnection" then
            pcall(function()
                connection:Disconnect()
            end)
        end
    end
    
    -- Stop particle emitters
    if animationData.particleEmitters then
        for _, emitterData in pairs(animationData.particleEmitters) do
            local particlePart, particles1, particles2 = emitterData[1], emitterData[2], emitterData[3]
            if particles1 then particles1.Enabled = false end
            if particles2 then particles2.Enabled = false end
        end
    end
    
    -- Clean up animation folder and pet balls (this will also clean up particles)
    if animationData.animationFolder then
        animationData.animationFolder:Destroy()
    end
    
    -- Clear the animation parts but keep the mixer tracked
    animationData.petBalls = nil
    animationData.animationFolder = nil
    animationData.bounceConnections = {}
    animationData.particleEmitters = nil
end

function PetMixerAnimationService:StopMixingAnimation(mixerId)
    local animationData = activeMixerAnimations[mixerId]
    if not animationData then return end
    
    -- Stop mixing animation
    
    -- Stop the mixing animation parts
    self:StopMixingAnimationOnly(mixerId)
    
    -- Clean up timer GUI
    if animationData.timerGUI then
        if animationData.timerGUI.connection then
            pcall(function()
                animationData.timerGUI.connection:Disconnect()
            end)
        end
        if animationData.timerGUI.gui then
            pcall(function()
                animationData.timerGUI.gui:Destroy()
            end)
        end
    end
    
    -- Clean up crafted ball if it exists
    if animationData.craftedBallCleanup then
        pcall(function()
            animationData.craftedBallCleanup()
        end)
    end
    
    -- Clean up "Done!" GUI from mixer model
    local mixerNumber = 1 -- Default to mixer 1
    local mixerData = mixerParts[mixerNumber]
    if mixerData and mixerData.mixerModel then
        local doneGUI = mixerData.mixerModel:FindFirstChild("DoneEffect", true)
        if doneGUI then
            pcall(function()
                doneGUI:Destroy()
            end)
        end
    end
    
    -- Fully remove from tracking
    activeMixerAnimations[mixerId] = nil
end

function PetMixerAnimationService:Cleanup()
    -- Cleaning up animation service
    
    -- Stop all active animations
    for mixerId, _ in pairs(activeMixerAnimations) do
        self:StopMixingAnimation(mixerId)
    end
    
    -- Disconnect all connections
    for key, connection in pairs(connections) do
        if connection and typeof(connection) == "RBXScriptConnection" then
            pcall(function()
                connection:Disconnect()
            end)
        end
    end
    connections = {}
    
    -- Clear cached data
    mixerParts = {}
    activeMixerAnimations = {}
end

return PetMixerAnimationService