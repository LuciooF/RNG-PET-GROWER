-- ClientPetBallService - Handles client-side pet ball creation and management
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local ClientPetBallService = {}
ClientPetBallService.__index = ClientPetBallService

-- Helper function to safely extract pet name from pet data
local function getSafePetName(petData)
    if not petData.Name then
        return "Unknown Pet"
    end
    
    if type(petData.Name) == "string" then
        return petData.Name
    elseif type(petData.Name) == "table" then
        -- If it's a table, try to convert it to string or use a fallback
        return tostring(petData.Name)
    else
        return "Unknown Pet"
    end
end

-- Helper function to safely extract variation name from pet data
local function getSafeVariationName(petData)
    if not petData.Variation then
        return "Bronze"
    end
    
    if type(petData.Variation) == "string" then
        return petData.Variation
    elseif type(petData.Variation) == "table" and petData.Variation.VariationName then
        return petData.Variation.VariationName
    else
        return "Bronze"
    end
end

local player = Players.LocalPlayer

-- Configuration
local MAX_PET_BALLS_PER_AREA = 50

-- Track pet balls per area for this client
local areaPetBallCounts = {}

-- Remote events
local spawnPetBallRemote = nil
local spawnHeavenPetBallRemote = nil

function ClientPetBallService:Initialize()
    -- Wait for remote events from server
    spawnPetBallRemote = ReplicatedStorage:WaitForChild("SpawnPetBall")
    spawnHeavenPetBallRemote = ReplicatedStorage:WaitForChild("SpawnHeavenPetBall")
    
    -- Listen for pet ball spawn requests from server
    spawnPetBallRemote.OnClientEvent:Connect(function(doorPosition, petData, areaName)
        self:CreatePetBall(doorPosition, petData, areaName)
    end)
    
    -- Listen for heaven pet ball spawn requests from server
    spawnHeavenPetBallRemote.OnClientEvent:Connect(function(petData, tubeNumber, areaName)
        self:CreateHeavenPetBall(petData, tubeNumber, areaName)
    end)
    
    -- Listen for clear requests from server (for rebirth) - non-blocking
    task.spawn(function()
        local clearPetBallsRemote = ReplicatedStorage:WaitForChild("ClearPetBalls", 10)
        if clearPetBallsRemote then
            clearPetBallsRemote.OnClientEvent:Connect(function(areaName)
                self:ClearPetBallsInArea(areaName)
            end)
        else
            warn("ClientPetBallService: ClearPetBalls remote not found after 10 seconds")
        end
    end)
    
    -- Initialize counter GUI for the current player's area
    task.spawn(function()
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        
        local playerAreas = Workspace:WaitForChild("PlayerAreas", 10)
        if playerAreas then
            -- Wait a bit for areas to be set up, then find player's area
            task.wait(2)
            
            -- Find the player's assigned area by looking for their name
            for _, area in pairs(playerAreas:GetChildren()) do
                if area.Name:match("^PlayerArea%d+$") then
                    -- Check if this area belongs to the current player
                    local nameplate = area:FindFirstChild("Nameplate")
                    if nameplate then
                        local textLabel = nameplate:FindFirstChild("SurfaceGui") and nameplate.SurfaceGui:FindFirstChild("TextLabel")
                        if textLabel and textLabel.Text == (player.Name .. "'s Area") then
                            -- This is the player's area, initialize the counter
                            self:UpdateCounterGUI(area.Name, 0)
                            break
                        end
                    end
                end
            end
        end
    end)
end

function ClientPetBallService:CreatePetBall(doorPosition, petData, areaName)
    
    -- Check local pet ball limit
    local currentCount = areaPetBallCounts[areaName] or 0
    if currentCount >= MAX_PET_BALLS_PER_AREA then
        return
    end
    
    -- Create pet model FIRST
    local petModel = self:CreatePetModel(petData)
    if not petModel then
        warn("ClientPetBallService: Failed to create pet model")
        return
    end
    
    -- Calculate appropriate ball size based on pet model (but cap it to reasonable size)
    local modelSize = petModel:GetExtentsSize()
    local ballSize = math.min(2.0, math.max(modelSize.X, modelSize.Y, modelSize.Z) * 0.8) -- Even smaller: cap at 2.0 studs max
    
    -- Create pet ball sized appropriately around the model
    local petBall = Instance.new("Part")
    petBall.Name = "PetBall"
    petBall.Shape = Enum.PartType.Ball
    petBall.Size = Vector3.new(ballSize, ballSize, ballSize)
    
    -- Get variation color (this determines the actual ball color)
    local PetConstants = require(ReplicatedStorage.constants.PetConstants)
    local variationColor = PetConstants.getVariationColor(petData.Variation or "Bronze")
    petBall.Color = variationColor
    
    petBall.Material = Enum.Material.Neon
    petBall.Transparency = 0.87 -- Very transparent with hint of color
    petBall.CanCollide = true
    petBall.Anchored = false
    
    -- Set collision group for pet balls
    petBall.CollisionGroup = "PetBalls"
    
    -- Store pet data in the ball
    local petDataValue = Instance.new("StringValue")
    petDataValue.Name = "PetData"
    petDataValue.Value = HttpService:JSONEncode(petData)
    petDataValue.Parent = petBall
    
    -- Position the ball exactly at the door center (no offset)
    petBall.Position = doorPosition
    
    -- Parent pet model to ball and position it simply
    petModel.Parent = petBall
    
    -- Simply position all pet parts at the ball center and weld them properly
    for _, descendant in pairs(petModel:GetDescendants()) do
        if descendant:IsA("BasePart") then
            -- Position the part at the ball center
            descendant.Position = petBall.Position
            
            -- Set physics properties to ensure proper welding during magnet attraction
            descendant.Anchored = false
            descendant.CanCollide = false
            descendant.Massless = true
            descendant.AssemblyLinearVelocity = Vector3.new(0, 0, 0) -- Ensure no initial velocity
            descendant.AssemblyAngularVelocity = Vector3.new(0, 0, 0) -- Ensure no initial rotation
            
            -- Create a more robust weld that survives CanCollide changes
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = petBall
            weld.Part1 = descendant
            weld.Parent = petBall
            
            -- Store reference to prevent garbage collection
            descendant:SetAttribute("WeldedToBall", true)
            
            -- Ensure the part follows the ball even during tweening by making it truly massless
            descendant.CustomPhysicalProperties = PhysicalProperties.new(
                0.01, -- Density (very light)
                0.5,  -- Friction
                0,    -- Elasticity
                1,    -- FrictionWeight
                1     -- ElasticityWeight
            )
        end
    end
    
    -- Find the appropriate area to parent the ball to
    local playerAreas = Workspace:FindFirstChild("PlayerAreas")
    if playerAreas then
        local area = playerAreas:FindFirstChild(areaName)
        if area then
            petBall.Parent = area
            
            -- Update local counter
            areaPetBallCounts[areaName] = currentCount + 1
            
            -- Update client-side counter GUI
            self:UpdateCounterGUI(areaName, areaPetBallCounts[areaName])
            
            -- Add pet name GUI above the ball
            self:CreatePetNameGUI(petBall, petData)
        end
    end
end

function ClientPetBallService:CreatePetModel(petData)
    -- Try to get actual pet model from ReplicatedStorage.Pets
    local petsFolder = ReplicatedStorage:FindFirstChild("Pets")
    
    if petsFolder then
        -- Use the actual model name from pet data, or fall back to first available pet
        local modelName = petData.ModelName or getSafePetName(petData) or "Acid Rain Doggy"
        
        local petModelTemplate = petsFolder:FindFirstChild(modelName)
        if not petModelTemplate then
            petModelTemplate = petsFolder:GetChildren()[1]
        end
        
        if petModelTemplate then
            local clonedModel = petModelTemplate:Clone()
            clonedModel.Name = "PetModel"
            
            -- Process all parts in the model
            local scaleFactor = 0.15 -- Even smaller to fit inside the smaller ball
            local partCount = 0
            
            for _, descendant in pairs(clonedModel:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    partCount = partCount + 1
                    descendant.Size = descendant.Size * scaleFactor
                    descendant.CanCollide = false
                    descendant.Anchored = false
                    descendant.Massless = true
                    -- IMPORTANT: Make parts visible (they become invisible in ReplicatedStorage)
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
    petPart.Size = Vector3.new(1.2, 1.2, 1.2)
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

-- Create floating name GUI for pet balls
function ClientPetBallService:CreatePetNameGUI(petBall, petData)
    -- Create BillboardGui
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "PetNameGUI"
    billboardGui.Size = UDim2.new(0, 35, 0, 35) -- Even smaller: 35x35 pixels
    billboardGui.StudsOffset = Vector3.new(0, 2.5, 0) -- Bit higher: 2.5 studs above ball
    billboardGui.LightInfluence = 0
    billboardGui.AlwaysOnTop = true
    billboardGui.Enabled = false -- Start hidden
    billboardGui.Parent = petBall
    
    -- Create TextLabel
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1 -- No background
    -- Create text with variation and pet name using helper functions
    local variationName = getSafeVariationName(petData)
    local petName = getSafePetName(petData)
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
    
    -- Add distance-based visibility with hysteresis to prevent flickering
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local player = Players.LocalPlayer
    local SHOW_DISTANCE = 75 -- Show GUI when within 75 studs (5x the original 15)
    local HIDE_DISTANCE = 90 -- Hide GUI when beyond 90 studs (prevents flickering)
    
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not petBall.Parent then
            -- Pet ball was destroyed, clean up connection
            connection:Disconnect()
            return
        end
        
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local playerPosition = player.Character.HumanoidRootPart.Position
            
            -- Get position from either a Part or Model
            local targetPosition
            if petBall:IsA("BasePart") then
                targetPosition = petBall.Position
            elseif petBall:IsA("Model") then
                -- For Models, use PrimaryPart position or first BasePart
                local primaryPart = petBall.PrimaryPart or petBall:FindFirstChildOfClass("BasePart")
                if primaryPart then
                    targetPosition = primaryPart.Position
                end
            end
            
            if targetPosition then
                local distance = (playerPosition - targetPosition).Magnitude
                
                -- Use hysteresis to prevent flickering
                if not billboardGui.Enabled and distance <= SHOW_DISTANCE then
                    -- Show GUI when getting close
                    billboardGui.Enabled = true
                elseif billboardGui.Enabled and distance > HIDE_DISTANCE then
                    -- Hide GUI when getting far away
                    billboardGui.Enabled = false
                end
            end
        end
    end)
    
    return billboardGui
end

-- Clean up pet balls in an area (called during rebirth)
function ClientPetBallService:ClearPetBallsInArea(areaName)
    local playerAreas = Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then return end
    
    local area = playerAreas:FindFirstChild(areaName)
    if not area then return end
    
    -- Find and destroy all pet balls in the area
    for _, descendant in pairs(area:GetDescendants()) do
        if descendant.Name == "PetBall" and descendant:IsA("BasePart") then
            descendant:Destroy()
        end
    end
    
    -- Reset counter
    areaPetBallCounts[areaName] = 0
    
    -- Update client-side counter GUI
    self:UpdateCounterGUI(areaName, 0)
end

-- Called when a pet ball is collected
function ClientPetBallService:OnPetBallCollected(areaName)
    local currentCount = areaPetBallCounts[areaName] or 0
    areaPetBallCounts[areaName] = math.max(0, currentCount - 1)
    
    -- Update client-side counter GUI
    self:UpdateCounterGUI(areaName, areaPetBallCounts[areaName])
end

-- Update counter GUI for an area (client-side version)
function ClientPetBallService:UpdateCounterGUI(areaName, count)
    
    local playerAreas = Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then 
        return 
    end
    
    local area = playerAreas:FindFirstChild(areaName)
    if not area then 
        return 
    end
    
    -- Find CounterAnchor in Level1
    local level1 = area:FindFirstChild("Level1")
    if not level1 then 
        return 
    end
    
    local counterAnchorModel = level1:FindFirstChild("CounterAnchorModel")
    if not counterAnchorModel then 
        return 
    end
    
    local counterAnchor = counterAnchorModel:FindFirstChild("CounterAnchor")
    if not counterAnchor then 
        return 
    end
    
    -- Find the SurfaceGui (it's named CounterGUI)
    local surfaceGui = counterAnchor:FindFirstChild("CounterGUI")
    if not surfaceGui then 
        return 
    end
    
    local backgroundFrame = surfaceGui:FindFirstChild("BackgroundFrame")
    local textLabel = backgroundFrame and backgroundFrame:FindFirstChild("CounterText")
    local progressBar = backgroundFrame and backgroundFrame:FindFirstChild("ProgressBar")
    
    if textLabel then
        local newText = string.format("Pets: %d/%d", count, MAX_PET_BALLS_PER_AREA)
        textLabel.Text = newText
    end
    
    -- Update progress bar
    if progressBar then
        local percentage = count / MAX_PET_BALLS_PER_AREA
        progressBar.Size = UDim2.new(percentage, 0, 1, 0)
        
        -- Change progress bar color based on percentage
        if percentage >= 1.0 then
            progressBar.BackgroundColor3 = Color3.fromRGB(255, 100, 100) -- Red when full
        elseif percentage >= 0.8 then
            progressBar.BackgroundColor3 = Color3.fromRGB(255, 200, 100) -- Orange when almost full
        else
            progressBar.BackgroundColor3 = Color3.fromRGB(100, 255, 100) -- Green when normal
        end
    end
end

-- Create heaven pet ball (floating pet in tube)
function ClientPetBallService:CreateHeavenPetBall(petData, tubeNumber, areaName)
    
    -- Find the area and tube
    local playerAreas = Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then
        warn("ClientPetBallService: PlayerAreas not found")
        return
    end
    
    local area = playerAreas:FindFirstChild(areaName)
    if not area then
        warn("ClientPetBallService: Area", areaName, "not found")
        return
    end
    
    -- Find the tube
    local tubesFolder = area:FindFirstChild("Tubes")
    if not tubesFolder then
        warn("ClientPetBallService: Tubes folder not found in area")
        return
    end
    
    local innerTubesFolder = tubesFolder:FindFirstChild("Tubes")
    if not innerTubesFolder then
        warn("ClientPetBallService: Inner Tubes folder not found")
        return
    end
    
    local tube = innerTubesFolder:FindFirstChild("Tube" .. tubeNumber)
    if not tube then
        warn("ClientPetBallService: Tube" .. tubeNumber .. " not found")
        return
    end
    
    local tubeBase = tube:FindFirstChild("TubeBase")
    if not tubeBase then
        warn("ClientPetBallService: TubeBase not found in tube")
        return
    end
    
    
    -- Create pet model FIRST (same as regular pet ball)
    local petModel = self:CreatePetModel(petData)
    if not petModel then
        warn("ClientPetBallService: Failed to create heaven pet model")
        return
    end
    
    -- Calculate appropriate ball size based on pet model (same as door pets)
    local modelSize = petModel:GetExtentsSize()
    local ballSize = math.min(2.0, math.max(modelSize.X, modelSize.Y, modelSize.Z) * 0.8) -- Same sizing as door pets
    
    -- Create heaven pet ball (same size as door pets but different material)
    local heavenBall = Instance.new("Part")
    heavenBall.Name = "HeavenPetBall"
    heavenBall.Shape = Enum.PartType.Ball
    heavenBall.Size = Vector3.new(ballSize, ballSize, ballSize) -- Same dynamic sizing as door pets
    heavenBall.Material = Enum.Material.ForceField -- Glass-like material
    heavenBall.CanCollide = false
    heavenBall.Anchored = false -- Unanchored so TweenService can move it
    heavenBall.Transparency = 0.7 -- More transparent to see pet inside
    
    -- Add BodyVelocity to prevent falling while allowing tweening
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0) -- Only prevent Y movement (gravity)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0) -- No initial velocity
    bodyVelocity.Parent = heavenBall
    
    -- Get variation color (this determines the actual ball color)
    local PetConstants = require(ReplicatedStorage.constants.PetConstants)
    local variationColor = PetConstants.getVariationColor(petData.Variation or "Bronze")
    heavenBall.Color = variationColor
    
    -- Position at tube base (higher up for visibility)
    local startPosition = tubeBase.Position + Vector3.new(0, 10, 0)
    heavenBall.Position = startPosition
    heavenBall.Parent = area -- Parent to area instead of workspace
    
    -- Parent pet model to ball and position it
    petModel.Parent = heavenBall
    
    -- Position all pet parts inside the heaven ball (model already scaled by CreatePetModel)
    for _, descendant in pairs(petModel:GetDescendants()) do
        if descendant:IsA("BasePart") then
            -- Position at ball center (no additional scaling needed - already done in CreatePetModel)
            descendant.Position = heavenBall.Position
            
            -- Set physics properties to ensure proper welding during animation (same as door pets)
            descendant.Anchored = false
            descendant.CanCollide = false
            descendant.Massless = true
            descendant.AssemblyLinearVelocity = Vector3.new(0, 0, 0) -- Ensure no initial velocity
            descendant.AssemblyAngularVelocity = Vector3.new(0, 0, 0) -- Ensure no initial rotation
            
            -- Create a robust weld that survives animation (same as door pets)
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = heavenBall
            weld.Part1 = descendant
            weld.Parent = heavenBall
            
            -- Store reference to prevent garbage collection (same as door pets)
            descendant:SetAttribute("WeldedToBall", true)
            
            -- Ensure the part follows the ball during animation (same as door pets)
            descendant.CustomPhysicalProperties = PhysicalProperties.new(
                0.01, -- Density (very light)
                0.5,  -- Friction
                0,    -- Elasticity
                1,    -- FrictionWeight
                1     -- ElasticityWeight
            )
            
            -- Make more visible and glowing for heaven effect (but keep face visible)
            descendant.Transparency = math.min(descendant.Transparency, 0.3) -- Less transparent
            descendant.Material = Enum.Material.Neon -- Glowing effect
        end
    end
    
    -- Animate floating up to heaven
    local TweenService = game:GetService("TweenService")
    local endPosition = startPosition + Vector3.new(0, 100, 0) -- Float up 100 studs
    
    -- Add pet name GUI above the pet model (so it follows the pet's animation)
    self:CreatePetNameGUI(petModel, petData)
    
    -- Handle bubble-like floating animation with rotation
    task.spawn(function()
        task.wait(0.5) -- Brief pause so ball is visible
        
        -- Create the main upward movement (faster and longer duration)
        local mainFloat = TweenService:Create(heavenBall,
            TweenInfo.new(7.0, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), -- Double the time
            { Position = endPosition }
        )
        
        -- Start main upward movement
        mainFloat:Play()
        
        -- Create flying motion (more up than down) and rotation
        local flyingActive = true
        task.spawn(function()
            local flyingOffset = 0
            local rotationOffset = 0
            local flyingSpeed = 3 -- How fast the flying motion is
            local rotationSpeed = 2 -- How fast the rotation is
            
            while flyingActive do
                local deltaTime = task.wait()
                flyingOffset = flyingOffset + flyingSpeed * deltaTime
                rotationOffset = rotationOffset + rotationSpeed * deltaTime
                
                -- Create flying motion - more up than down (using abs(sin) + sin for bias toward up)
                local flyPattern = math.abs(math.sin(flyingOffset)) * 0.7 + math.sin(flyingOffset * 0.5) * 0.3
                local yVelocity = flyPattern * 15 -- Much faster flying velocity (was 8, now 15)
                
                -- Apply flying motion
                bodyVelocity.Velocity = Vector3.new(0, yVelocity, 0)
                
                -- Apply horizontal rotation
                local currentCFrame = heavenBall.CFrame
                local rotationAngle = rotationOffset * 1.5 -- Faster rotation (was 0.5, now 1.5)
                heavenBall.CFrame = CFrame.new(currentCFrame.Position) * CFrame.Angles(0, rotationAngle, 0)
            end
        end)
        
        -- When main float completes, stop flying and fade out
        mainFloat.Completed:Connect(function()
            flyingActive = false -- Stop flying motion
            bodyVelocity.Velocity = Vector3.new(0, 0, 0) -- Stop all movement
            
            local fadeOut = TweenService:Create(heavenBall,
                TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {
                    Transparency = 1,
                    Size = Vector3.new(1, 1, 1)
                }
            )
            fadeOut:Play()
            
            -- Destroy after fade completes
            fadeOut.Completed:Connect(function()
                heavenBall:Destroy()
            end)
        end)
    end)
end

return ClientPetBallService