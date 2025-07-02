local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

local PlotConfig = require(ReplicatedStorage.Shared.config.PlotConfig)
local PetConfig = require(ReplicatedStorage.Shared.config.PetConfig)

local PetGrowthService = {}
PetGrowthService.__index = PetGrowthService

local player = Players.LocalPlayer
local connection = nil
local lastPlayerData = {} -- Cache player data
local playerAreaNumber = nil -- Store the player's assigned area number
local areaAssignments = {} -- Store area assignments from server
local activePets = {} -- Store active pets per plot {[plotId] = {model, growthTween, etc}}

-- Growth configuration
local PET_GROWTH_TIME = 10 -- seconds to fully grow
local PET_HOVER_HEIGHT = 3 -- studs above plot
local PET_FLOAT_SPEED = 2 -- floating animation speed
local PET_FLOAT_AMPLITUDE = 0.2 -- how much the pet moves up/down (reduced for larger models)
local PET_ROTATION_SPEED = 0.5 -- rotation speed for full 360 (radians per second)

function PetGrowthService:Initialize()
    
    -- Wait for PlayerAreas to be created
    local playerAreas = Workspace:WaitForChild("PlayerAreas", 10)
    if not playerAreas then
        warn("PetGrowthService: PlayerAreas not found!")
        return
    end
    
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
    
    -- Start floating animation loop
    connection = RunService.Heartbeat:Connect(function()
        self:UpdatePetAnimations()
    end)
    
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
    
    
    -- Create pet model (for now, using a simple part as placeholder)
    local petModel = self:CreatePetModel(petData, spawnPosition)
    if not petModel then
        return
    end
    
    petModel.Parent = plot
    
    -- Start with very small size (scale the entire model)
    -- Duck model is much larger, so use smaller scale
    local originalScale = petData.assetId == 72905778529983 and Vector3.new(0.4, 0.4, 0.4) or Vector3.new(1, 1, 1)
    local startScale = originalScale * 0.1 -- Start at 10% scale
    self:ScaleModel(petModel, startScale)
    
    -- Generate random aura for this pet
    local auraId, auraData = PetConfig:GetRandomAura()
    
    -- Store pet data (include pet ID from selection and aura)
    local fullPetData = {
        id = petSelection.id,
        name = petData.name,
        rarity = petData.rarity,
        value = petData.value * (auraData.valueMultiplier or 1),
        description = petData.description,
        aura = auraId,
        auraData = auraData
    }
    
    activePets[plotId] = {
        model = petModel,
        petData = fullPetData,
        plot = plot,
        originalScale = originalScale,
        currentScale = startScale,
        spawnPosition = spawnPosition,
        growthStartTime = tick(),
        isFullyGrown = false,
        floatOffset = 0,
        rotationOffset = 0
    }
    
    -- Create pet status GUI
    self:CreatePetStatusGUI(plotId)
    
    -- Apply aura visual effects to the pet model
    self:ApplyAuraEffects(petModel, auraData)
    
    -- Start growth animation (manual scaling since we can't tween model scale directly)
    self:StartGrowthAnimation(plotId)
end

function PetGrowthService:ScaleModel(model, scale)
    -- Get or calculate the model's center point
    local modelCenter
    
    -- Check if we have a stored model center
    if model:GetAttribute("ModelCenter") then
        modelCenter = model:GetAttribute("ModelCenter")
    else
        -- First time - calculate and store the center
        modelCenter = Vector3.new(0, 0, 0)
        local partCount = 0
        
        for _, descendant in pairs(model:GetDescendants()) do
            if descendant:IsA("BasePart") then
                modelCenter = modelCenter + descendant.Position
                partCount = partCount + 1
            end
        end
        
        if partCount > 0 then
            modelCenter = modelCenter / partCount
        end
        
        -- Store the center on the model
        model:SetAttribute("ModelCenter", modelCenter)
        
        -- Store original positions and sizes
        for _, descendant in pairs(model:GetDescendants()) do
            if descendant:IsA("BasePart") then
                descendant:SetAttribute("OriginalSize", descendant.Size)
                local relativePos = descendant.Position - modelCenter
                descendant:SetAttribute("OriginalRelativePosition", relativePos)
            end
        end
    end
    
    -- Scale all parts in the model
    for _, descendant in pairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            local originalSize = descendant:GetAttribute("OriginalSize")
            local originalRelativePos = descendant:GetAttribute("OriginalRelativePosition")
            
            if originalSize and originalRelativePos then
                -- Scale the size
                descendant.Size = originalSize * scale
                -- Scale the position relative to the stored center
                descendant.Position = modelCenter + (originalRelativePos * scale)
            end
        end
    end
end

function PetGrowthService:StartGrowthAnimation(plotId)
    local petInfo = activePets[plotId]
    if not petInfo then return end
    
    -- Use a tween to smoothly change the scale value
    local scaleValue = Instance.new("NumberValue")
    scaleValue.Value = 0.1 -- Start scale
    
    -- Determine end scale based on original scale
    local endScale = petInfo.originalScale.X -- Use X component since they're all the same
    
    local growthTween = TweenService:Create(scaleValue,
        TweenInfo.new(PET_GROWTH_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Value = endScale} -- End scale based on model type
    )
    
    scaleValue.Changed:Connect(function(newScale)
        if activePets[plotId] and activePets[plotId].model then
            local scale = Vector3.new(newScale, newScale, newScale)
            self:ScaleModel(activePets[plotId].model, scale)
            activePets[plotId].currentScale = scale
        end
    end)
    
    growthTween:Play()
    growthTween.Completed:Connect(function()
        if activePets[plotId] then
            activePets[plotId].isFullyGrown = true
            -- Update GUI to show "Ready!"
            self:UpdatePetStatusGUI(plotId, true)
            -- Set up touch detection for pickup
            self:SetupPetPickup(plotId)
        end
        
        growthTween:Destroy()
        scaleValue:Destroy()
    end)
end

function PetGrowthService:CreatePetModel(petData, position)
    
    -- Method 1: Check ReplicatedStorage cache first (fastest)
    local assetCache = ReplicatedStorage:FindFirstChild("AssetCache")
    if assetCache then
        local cacheKey = "Asset_" .. tostring(petData.assetId)
        local cachedAsset = assetCache:FindFirstChild(cacheKey)
        if cachedAsset then
            local model = cachedAsset:Clone()
            model.Name = "Pet_" .. petData.name:gsub(" ", "_")
            
            -- Configure model for pet use
            for _, part in pairs(model:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Anchored = true
                    part.CanCollide = false
                end
            end
            
            -- Ensure model has a PrimaryPart
            if not model.PrimaryPart then
                local firstPart = model:FindFirstChildOfClass("BasePart")
                if firstPart then
                    model.PrimaryPart = firstPart
                end
            end
            
            
            -- Calculate the model's center by averaging all part positions
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
            -- Calculate offset from model center to desired position
            local offset = position - modelCenter
            
            -- Move all parts by the offset
            for _, part in pairs(model:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Position = part.Position + offset
                end
            end
            
            return model
        end
    end
    
    -- Method 2: Request asset from server via RemoteFunction
    local success, result = pcall(function()
        local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
        if remotes then
            local loadAssetRemote = remotes:FindFirstChild("LoadAsset")
            if loadAssetRemote then
                local asset = loadAssetRemote:InvokeServer(petData.assetId)
                return asset
            else
                return nil
            end
        end
        return nil
    end)
    
    if success and result then
        local model = result:Clone()
        model.Name = "Pet_" .. petData.name:gsub(" ", "_")
        
        -- Configure model for pet use
        for _, part in pairs(model:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored = true
                part.CanCollide = false
            end
        end
        
        -- Ensure model has a PrimaryPart
        if not model.PrimaryPart then
            local firstPart = model:FindFirstChildOfClass("BasePart")
            if firstPart then
                model.PrimaryPart = firstPart
                print("PetGrowthService: Set PrimaryPart to:", firstPart.Name)
            end
        end
        
        
        -- Calculate the model's center by averaging all part positions
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
        -- Calculate offset from model center to desired position
        local offset = position - modelCenter
        
        -- Move all parts by the offset
        for _, part in pairs(model:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Position = part.Position + offset
            end
        end
        
        return model
    else
    end
    
    
    -- Create a duck-like model as fallback
    local model = Instance.new("Model")
    model.Name = "Pet_" .. petData.name:gsub(" ", "_")
    
    -- Duck body
    local body = Instance.new("Part")
    body.Name = "Body"
    body.Size = Vector3.new(1.5, 1, 2)
    body.Shape = Enum.PartType.Ball
    body.Material = Enum.Material.SmoothPlastic
    body.Color = Color3.fromRGB(255, 255, 0) -- Yellow
    body.Position = position
    body.Anchored = true
    body.CanCollide = false
    body.Parent = model
    
    -- Duck head
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(0.8, 0.8, 0.8)
    head.Shape = Enum.PartType.Ball
    head.Material = Enum.Material.SmoothPlastic
    head.Color = Color3.fromRGB(255, 255, 0) -- Yellow
    head.Position = position + Vector3.new(0, 0.5, 1)
    head.Anchored = true
    head.CanCollide = false
    head.Parent = model
    
    -- Duck beak
    local beak = Instance.new("Part")
    beak.Name = "Beak"
    beak.Size = Vector3.new(0.3, 0.2, 0.6)
    beak.Material = Enum.Material.SmoothPlastic
    beak.Color = Color3.fromRGB(255, 165, 0) -- Orange
    beak.Position = position + Vector3.new(0, 0.4, 1.6)
    beak.Anchored = true
    beak.CanCollide = false
    beak.Parent = model
    
    -- Set primary part
    model.PrimaryPart = body
    
    return model
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
                    
                    -- Remove the pet immediately (no waiting for server)
                    self:RemovePet(plotId)
                    
                    -- Start growing a new pet immediately (no delay)
                    self:StartPetGrowth(plot, plotId)
                    
                    -- Send pet collection to server (fire and forget - don't wait for response)
                    task.spawn(function()
                        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                        if remotes then
                            local collectPetRemote = remotes:FindFirstChild("CollectPet")
                            if collectPetRemote then
                                -- Send pet data to server
                                local petDataToSend = {
                                    petId = petInfo.petData.id or 1, -- Default to pet ID 1 if not set
                                    name = petInfo.petData.name,
                                    rarity = petInfo.petData.rarity,
                                    value = petInfo.petData.value,
                                    plotId = plotId,
                                    aura = petInfo.petData.aura,
                                    auraData = petInfo.petData.auraData
                                }
                                collectPetRemote:FireServer(petDataToSend)
                            else
                                -- warn("PetGrowthService: CollectPet remote not found!")
                            end
                        else
                            -- warn("PetGrowthService: Remotes folder not found!")
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

function PetGrowthService:UpdatePetAnimations()
    local deltaTime = RunService.Heartbeat:Wait()
    
    for plotId, petInfo in pairs(activePets) do
        if petInfo.model and petInfo.model.Parent then
            -- Update animation offsets (animate both growing and fully grown pets)
            petInfo.rotationOffset = petInfo.rotationOffset + (PET_ROTATION_SPEED * deltaTime)
            
            -- Calculate full 360-degree rotation (continuous spinning)
            local rotationY = petInfo.rotationOffset -- Direct rotation, no amplitude needed
            
            local newPosition = petInfo.spawnPosition
            
            -- Only add floating animation if fully grown
            if petInfo.isFullyGrown then
                petInfo.floatOffset = petInfo.floatOffset + (PET_FLOAT_SPEED * deltaTime)
                local floatY = math.sin(petInfo.floatOffset) * PET_FLOAT_AMPLITUDE
                newPosition = petInfo.spawnPosition + Vector3.new(0, floatY, 0)
            end
            
            -- Apply rotation and position
            if petInfo.model:IsA("Model") then
                -- Get the model center which should be at spawn position after our repositioning
                local modelCenter = petInfo.spawnPosition
                
                -- Store original orientations if not already stored
                for _, part in pairs(petInfo.model:GetDescendants()) do
                    if part:IsA("BasePart") and not part:GetAttribute("OriginalOrientation") then
                        -- Store the original rotation relative to model
                        part:SetAttribute("OriginalOrientation", part.CFrame - part.CFrame.Position)
                    end
                end
                
                -- Rotate each part around the model center
                for _, part in pairs(petInfo.model:GetDescendants()) do
                    if part:IsA("BasePart") then
                        local originalRelativePos = part:GetAttribute("OriginalRelativePosition")
                        local originalOrientation = part:GetAttribute("OriginalOrientation")
                        
                        if originalRelativePos and originalOrientation then
                            -- Get current scale from petInfo (this updates during growth)
                            local currentScale = petInfo.currentScale.X
                            
                            -- Apply rotation to the scaled relative position
                            local scaledRelativePos = originalRelativePos * currentScale
                            local rotatedRelativePos = CFrame.Angles(0, rotationY, 0) * scaledRelativePos
                            
                            -- Set new position (with floating offset if applicable)
                            local finalPosition = newPosition + rotatedRelativePos
                            
                            -- Apply rotation to the part itself while maintaining its original orientation
                            part.CFrame = CFrame.new(finalPosition) * CFrame.Angles(0, rotationY, 0) * originalOrientation
                        end
                    end
                end
            else
                -- Single part pet
                petInfo.model.CFrame = CFrame.new(newPosition) * CFrame.Angles(0, rotationY, 0)
            end
        end
    end
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
    if petInfo.statusGUI then
        petInfo.statusGUI:Destroy()
    end
    
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

function PetGrowthService:CreatePetStatusGUI(plotId)
    local petInfo = activePets[plotId]
    if not petInfo or not petInfo.model then return end
    
    local petData = petInfo.petData
    local auraName = petData.auraData.name
    local petName = petData.name
    local auraColor = petData.auraData.color
    
    -- Get emoji for aura
    local auraEmoji = "⚪" -- Default white circle for None aura
    if auraName == "Diamond" then
        auraEmoji = "💎"
    end
    
    -- Create BillboardGui
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PetStatusGUI"
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.LightInfluence = 0
    billboard.AlwaysOnTop = true
    billboard.Parent = petInfo.model
    
    -- Create text label (no background, just text like plot GUIs)
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "StatusText"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Position = UDim2.new(0, 0, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = auraEmoji .. " " .. petName .. "\n🌱 Growing..."
    textLabel.TextColor3 = auraColor
    textLabel.TextSize = 22
    textLabel.TextWrapped = true
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Parent = billboard
    
    -- Add black outline for better visibility
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 0, 0)
    stroke.Thickness = 3
    stroke.Parent = textLabel
    
    -- Store GUI reference
    petInfo.statusGUI = billboard
    
end

function PetGrowthService:UpdatePetStatusGUI(plotId, isReady)
    local petInfo = activePets[plotId]
    if not petInfo or not petInfo.statusGUI then return end
    
    local textLabel = petInfo.statusGUI.StatusText
    local petData = petInfo.petData
    local auraName = petData.auraData.name
    local petName = petData.name
    local auraColor = petData.auraData.color
    
    -- Get emoji for aura
    local auraEmoji = "⚪" -- Default white circle for None aura
    if auraName == "Diamond" then
        auraEmoji = "💎"
    end
    
    if isReady then
        textLabel.Text = auraEmoji .. " " .. petName .. "\n✨ Ready!"
        textLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green for ready
    else
        textLabel.Text = auraEmoji .. " " .. petName .. "\n🌱 Growing..."
        textLabel.TextColor3 = auraColor -- Use aura color for growing
    end
end

function PetGrowthService:ApplyAuraEffects(model, auraData)
    if not model or not auraData then return end
    
    -- Skip aura effects for "None" aura
    if auraData.name == "None" then
        return
    end
    
    -- Find the primary part or largest part to attach particles to
    local primaryPart = model.PrimaryPart
    if not primaryPart then
        -- Find the largest part
        local largestPart = nil
        local largestSize = 0
        for _, part in pairs(model:GetDescendants()) do
            if part:IsA("BasePart") then
                local size = part.Size.X * part.Size.Y * part.Size.Z
                if size > largestSize then
                    largestSize = size
                    largestPart = part
                end
            end
        end
        primaryPart = largestPart
    end
    
    if not primaryPart then
        return
    end
    
    -- Create particle emitter for aura effect
    local particleEmitter = Instance.new("ParticleEmitter")
    particleEmitter.Name = "AuraParticles"
    particleEmitter.Parent = primaryPart
    
    -- Configure particles based on aura
    if auraData.name == "Diamond" then
        -- Diamond sparkle effect
        particleEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        particleEmitter.Color = ColorSequence.new(auraData.color)
        particleEmitter.Lifetime = NumberRange.new(1, 2)
        particleEmitter.Rate = 30
        particleEmitter.Speed = NumberRange.new(1, 3)
        particleEmitter.SpreadAngle = Vector2.new(180, 180)
        particleEmitter.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.8),
            NumberSequenceKeypoint.new(0.5, 0.5),
            NumberSequenceKeypoint.new(1, 1)
        }
        particleEmitter.Size = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(0.5, 0.4),
            NumberSequenceKeypoint.new(1, 0)
        }
        particleEmitter.LightEmission = 1
        particleEmitter.LightInfluence = 0
        
        -- Add a subtle glow effect
        local pointLight = Instance.new("PointLight")
        pointLight.Name = "AuraGlow"
        pointLight.Color = auraData.color
        pointLight.Brightness = 0.5
        pointLight.Range = 10
        pointLight.Parent = primaryPart
    end
end

function PetGrowthService:Cleanup()
    if connection then
        connection:Disconnect()
        connection = nil
    end
    
    -- Clean up all active pets
    for plotId, _ in pairs(activePets) do
        self:RemovePet(plotId)
    end
    
end

return PetGrowthService