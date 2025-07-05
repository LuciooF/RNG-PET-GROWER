-- Heaven Animation Service
-- Handles visual effects of pets flying to heaven during processing
-- Creates pet models that fly upward from Tube1 Base part and disappear

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local PetModelFactory = require(script.Parent.controllers.PetModelFactory)

local HeavenAnimationService = {}
HeavenAnimationService.__index = HeavenAnimationService

local player = Players.LocalPlayer
local playerAreaNumber = nil
local areaAssignments = {}

-- Animation configuration
local HEAVEN_HEIGHT = 100 -- How high pets fly before disappearing
local ANIMATION_DURATION = 8 -- How long the animation takes (slower)
local PET_SCALE = Vector3.new(0.3, 0.3, 0.3) -- Same scale as spawned pets

-- Animation batching to prevent lag
local animationQueue = {} -- Queue of pets waiting to animate
local isProcessingQueue = false
local ANIMATIONS_PER_BATCH = 3 -- Max animations to start at once
local BATCH_DELAY = 0.2 -- Delay between batches (seconds)

function HeavenAnimationService:Initialize()
    -- Wait for area assignment sync
    local areaAssignmentSync = ReplicatedStorage:WaitForChild("AreaAssignmentSync", 10)
    if areaAssignmentSync then
        areaAssignmentSync.OnClientEvent:Connect(function(assignmentData)
            areaAssignments = assignmentData
            playerAreaNumber = self:GetPlayerAreaNumber()
        end)
    end
    
    -- Listen for heaven animation events
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
    if remotes then
        local heavenAnimation = remotes:WaitForChild("HeavenAnimation", 10)
        if heavenAnimation then
            heavenAnimation.OnClientEvent:Connect(function(petData)
                self:QueueHeavenAnimation(petData)
            end)
        end
    end
end

function HeavenAnimationService:GetPlayerAreaNumber()
    -- Find which area the current player is assigned to
    for areaNumber, assignmentData in pairs(areaAssignments) do
        if assignmentData.playerName == player.Name then
            return areaNumber
        end
    end
    return nil
end

function HeavenAnimationService:FindAllTubeBases()
    if not playerAreaNumber then
        return {}
    end
    
    local playerAreas = Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then return {} end
    
    local playerArea = playerAreas:FindFirstChild("PlayerArea" .. playerAreaNumber)
    if not playerArea then return {} end
    
    local tubeBases = {}
    
    -- Always look for default Tube1 first
    local tube1 = playerArea:FindFirstChild("Tube1")
    if tube1 then
        local tube1Base = tube1:FindFirstChild("Base")
        if tube1Base then
            table.insert(tubeBases, {
                base = tube1Base,
                name = "Tube1",
                isDefault = true
            })
        end
    end
    
    -- Look for production tubes (Tube2, Tube3, etc. up to Tube11 for 10 production plots)
    for i = 2, 11 do
        local tubeName = "Tube" .. i
        local tube = playerArea:FindFirstChild(tubeName)
        if tube then
            local tubeBase = tube:FindFirstChild("Base")
            if tubeBase then
                table.insert(tubeBases, {
                    base = tubeBase,
                    name = tubeName,
                    isDefault = false,
                    productionPlotId = i - 1 -- Maps to production plot 1-10
                })
            end
        end
    end
    
    -- Fallback to SendHeaven if no tubes exist
    if #tubeBases == 0 then
        warn("HeavenAnimationService: No tubes found! Falling back to SendHeaven part.")
        local sendHeavenPart = playerArea:FindFirstChild("SendHeaven")
        if sendHeavenPart and sendHeavenPart:IsA("BasePart") then
            table.insert(tubeBases, {
                base = sendHeavenPart,
                name = "SendHeaven",
                isDefault = true
            })
        end
    end
    
    return tubeBases
end

function HeavenAnimationService:SelectTubeForPet()
    local tubeBases = self:FindAllTubeBases()
    if #tubeBases == 0 then
        return nil
    end
    
    -- Round-robin selection across all available tubes for even distribution
    if not self.currentTubeIndex then
        self.currentTubeIndex = 1
    else
        self.currentTubeIndex = (self.currentTubeIndex % #tubeBases) + 1
    end
    
    return tubeBases[self.currentTubeIndex]
end

-- Queue animation instead of playing immediately
function HeavenAnimationService:QueueHeavenAnimation(petData)
    table.insert(animationQueue, petData)
    
    -- Start processing queue if not already running
    if not isProcessingQueue then
        self:StartProcessingQueue()
    end
end

-- Process the animation queue in batches to prevent lag
function HeavenAnimationService:StartProcessingQueue()
    if isProcessingQueue then return end
    isProcessingQueue = true
    
    task.spawn(function()
        while #animationQueue > 0 do
            -- Process a batch of animations
            local batch = {}
            for i = 1, math.min(ANIMATIONS_PER_BATCH, #animationQueue) do
                table.insert(batch, table.remove(animationQueue, 1))
            end
            
            -- Start all animations in this batch simultaneously
            for _, petData in ipairs(batch) do
                self:PlayHeavenAnimation(petData)
            end
            
            -- Wait before processing next batch
            if #animationQueue > 0 then
                task.wait(BATCH_DELAY)
            end
        end
        
        isProcessingQueue = false
    end)
end

function HeavenAnimationService:PlayHeavenAnimation(petData)
    local selectedTube = self:SelectTubeForPet()
    if not selectedTube then
        warn("HeavenAnimationService: No tube available for animation")
        return
    end
    
    -- Calculate spawn position (5 studs above selected tube base at dead center)
    local spawnPosition = selectedTube.base.Position + Vector3.new(0, 5, 0)
    
    -- Create pet model for animation (wrapped in pcall to handle any errors gracefully)
    local success, petModel = pcall(function()
        return self:CreateAnimationPet(petData, selectedTube.base.Position)
    end)
    
    if not success or not petModel then
        warn("HeavenAnimationService: Failed to create pet model for animation:", success and "model creation failed" or petModel)
        return
    end
    
    -- Start the heaven flight animation using the spawn position
    self:AnimatePetToHeaven(petModel, spawnPosition)
    
    -- Reduced logging to prevent spam
    -- print(string.format("HeavenAnimationService: Flying %s to heaven from %s", petData.petName, selectedTube.name))
end

function HeavenAnimationService:CreateAnimationPet(petData, startPosition)
    -- Create a lightweight pet model for animation only
    local fullPetData = {
        id = petData.petId,
        name = petData.petName,
        assetPath = petData.assetPath,
        aura = "none", -- Skip aura effects for performance
        size = petData.size or 1,
        value = petData.value
    }
    
    -- Spawn slightly above the Tube1 Base part at dead center
    local spawnPosition = startPosition + Vector3.new(0, 5, 0)
    local petModel = PetModelFactory.createPetModel(fullPetData, spawnPosition)
    
    if not petModel then
        return nil
    end
    
    -- Set parent immediately to prevent orphaned models
    petModel.Parent = Workspace
    
    -- Apply rarity outline effects (even for animation pets so players can see the rarity)
    PetModelFactory.applyRarityOutline(petModel, fullPetData)
    
    -- Scale the pet model (lightweight operation)
    PetModelFactory.scaleModel(petModel, PET_SCALE)
    
    -- Skip aura effects entirely for animation pets (performance optimization)
    
    -- Ensure all parts are anchored for animation (no physics/welding needed)
    if petModel.PrimaryPart then
        -- Anchor all parts - we'll move them as a group using SetPrimaryPartCFrame
        for _, part in pairs(petModel:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored = true
                part.CanCollide = false
            end
        end
    else
        warn("HeavenAnimationService: Pet model has no PrimaryPart!")
        return nil
    end
    
    return petModel
end

function HeavenAnimationService:AnimatePetToHeaven(petModel, startPosition)
    if not petModel or not petModel.PrimaryPart then
        warn("HeavenAnimationService: Invalid pet model or missing PrimaryPart")
        return
    end
    
    -- Store reference to primary part to avoid nil issues
    local primaryPart = petModel.PrimaryPart
    
    -- Calculate end position (fly straight up)
    local endPosition = startPosition + Vector3.new(0, HEAVEN_HEIGHT, 0)
    
    -- Create combined movement and rotation animation
    local animationConnection
    local startTime = tick()
    
    animationConnection = RunService.Heartbeat:Connect(function()
        -- Check if model still exists and has PrimaryPart
        if not petModel or not petModel.Parent or not petModel.PrimaryPart then
            if animationConnection then
                animationConnection:Disconnect()
            end
            return
        end
        
        local elapsed = tick() - startTime
        local progress = math.min(elapsed / ANIMATION_DURATION, 1)
        
        -- Calculate position with easing
        local easedProgress = 1 - (1 - progress) * (1 - progress) -- Quad out easing
        local currentPosition = startPosition:Lerp(endPosition, easedProgress)
        
        -- Calculate rotation (continuous spin)
        local rotationAngle = (elapsed / ANIMATION_DURATION) * math.pi * 4 -- 2 full rotations
        
        -- Use SetPrimaryPartCFrame to move the entire model as one unit
        local targetCFrame = CFrame.new(currentPosition) * CFrame.Angles(0, rotationAngle, 0)
        petModel:SetPrimaryPartCFrame(targetCFrame)
        
        -- Stop animation when complete
        if progress >= 1 then
            animationConnection:Disconnect()
        end
    end)
    
    -- Create fade out tween (starts 75% through animation for slower fade)
    local fadeDelay = ANIMATION_DURATION * 0.75
    
    task.spawn(function()
        task.wait(fadeDelay)
        
        -- Fade out all parts
        local fadeTweens = {}
        for _, part in pairs(petModel:GetDescendants()) do
            if part:IsA("BasePart") then
                local fadeTween = TweenService:Create(
                    part,
                    TweenInfo.new(
                        ANIMATION_DURATION * 0.25, -- Fade over the last 25% of animation
                        Enum.EasingStyle.Quad,
                        Enum.EasingDirection.Out
                    ),
                    {
                        Transparency = 1
                    }
                )
                fadeTween:Play()
                table.insert(fadeTweens, fadeTween)
            end
        end
        
        -- Clean up after fade completes
        if #fadeTweens > 0 then
            fadeTweens[1].Completed:Connect(function()
                if petModel and petModel.Parent then
                    petModel:Destroy()
                end
            end)
        end
    end)
    
    -- Clean up if something goes wrong
    Debris:AddItem(petModel, ANIMATION_DURATION + 1)
end

function HeavenAnimationService:Cleanup()
    -- No ongoing connections to clean up
end

return HeavenAnimationService