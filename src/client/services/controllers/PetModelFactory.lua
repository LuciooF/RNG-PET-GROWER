-- Pet Model Factory
-- Handles creation and manipulation of pet and egg models
-- Extracted from PetGrowthService.lua for better modularity

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local PetConfig = require(ReplicatedStorage.Shared.config.PetConfig)

local PetModelFactory = {}

-- Create egg model for first phase of growth
function PetModelFactory.createEggModel(position)
    -- Load from ReplicatedStorage assets FOLDER (not the ModuleScript)
    local assets = nil
    for _, child in pairs(ReplicatedStorage:GetChildren()) do
        if child.Name == "assets" and child.ClassName == "Folder" then
            assets = child
            break
        end
    end
    
    if assets then
        -- Navigate to Pets > Eggs > Pixel Egg
        local petsFolder = assets:FindFirstChild("Pets")
        if petsFolder then
            local eggsFolder = petsFolder:FindFirstChild("Eggs")
            if eggsFolder then
                local pixelEgg = eggsFolder:FindFirstChild("Pixel Egg")
                if pixelEgg then
                    
                    -- Create a model to contain the egg mesh
                    local model = Instance.new("Model")
                    model.Name = "Egg"
                    
                    local eggPart
                    if pixelEgg:IsA("Model") then
                        -- If it's already a model, clone it
                        eggPart = pixelEgg:Clone()
                        eggPart.Parent = model
                    else
                        -- If it's just a mesh/part, clone it and wrap in a model
                        eggPart = pixelEgg:Clone()
                        eggPart.Name = "EggPart"
                        eggPart.Anchored = true
                        eggPart.CanCollide = false
                        eggPart.Position = position
                        eggPart.Parent = model
                        
                        -- Set this as the PrimaryPart
                        model.PrimaryPart = eggPart
                    end
                    
                    return model
                end
            end
        end
    end
    
    -- Fallback: Create a simple egg model if asset not found
    local model = Instance.new("Model")
    model.Name = "Egg"
    
    local eggBody = Instance.new("Part")
    eggBody.Name = "EggBody"
    eggBody.Size = Vector3.new(1.8, 2.2, 1.8)
    eggBody.Shape = Enum.PartType.Ball
    eggBody.Material = Enum.Material.SmoothPlastic
    eggBody.Color = Color3.fromRGB(255, 248, 220) -- Cream color
    eggBody.Position = position
    eggBody.Anchored = true
    eggBody.CanCollide = false
    eggBody.Parent = model
    
    model.PrimaryPart = eggBody
    
    return model
end

-- Create pet model from asset path
function PetModelFactory.createPetModel(petData, position)
    -- Load from ReplicatedStorage assets FOLDER (not the ModuleScript)
    local assets = nil
    for _, child in pairs(ReplicatedStorage:GetChildren()) do
        if child.Name == "assets" and child.ClassName == "Folder" then
            assets = child
            break
        end
    end
    
    if assets and petData.assetPath then
        local pathParts = string.split(petData.assetPath, "/")
        local currentFolder = assets
        
        -- Navigate through the path
        for _, pathPart in ipairs(pathParts) do
            currentFolder = currentFolder:FindFirstChild(pathPart)
            if not currentFolder then
                break
            end
        end
        
        if currentFolder and currentFolder:IsA("Model") then
            local model = currentFolder:Clone()
            model.Name = "Pet_" .. petData.name:gsub(" ", "_")
            
            -- Properly configure model for pet use and preserve original properties
            for _, part in pairs(model:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Anchored = true
                    part.CanCollide = false
                    -- Don't modify Material, Color, or other visual properties
                    -- Let the model keep its original appearance
                end
            end
            
            -- Set a proper PrimaryPart (find the largest part)
            if not model.PrimaryPart then
                local largestPart = nil
                local largestVolume = 0
                for _, part in pairs(model:GetDescendants()) do
                    if part:IsA("BasePart") then
                        local volume = part.Size.X * part.Size.Y * part.Size.Z
                        if volume > largestVolume then
                            largestVolume = volume
                            largestPart = part
                        end
                    end
                end
                if largestPart then
                    model.PrimaryPart = largestPart
                end
            end
            
            -- Position the model at the target location
            if model.PrimaryPart then
                model:SetPrimaryPartCFrame(CFrame.new(position))
            else
                -- Fallback: move all parts
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
                    local offset = position - modelCenter
                    for _, part in pairs(model:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.Position = part.Position + offset
                        end
                    end
                end
            end
            
            return model
        end
    end
    
    -- Fallback: Create a simple placeholder model
    local model = Instance.new("Model")
    model.Name = "Pet_" .. petData.name:gsub(" ", "_")
    
    -- Simple body
    local body = Instance.new("Part")
    body.Name = "Body"
    body.Size = Vector3.new(2, 2, 2)
    body.Shape = Enum.PartType.Ball
    body.Material = Enum.Material.SmoothPlastic
    body.Color = Color3.fromRGB(100, 200, 255) -- Light blue
    body.Position = position
    body.Anchored = true
    body.CanCollide = false
    body.Parent = model
    
    -- Set primary part
    model.PrimaryPart = body
    
    return model
end

-- Scale model while preserving center and relative positions
function PetModelFactory.scaleModel(model, scale)
    -- Always calculate the model's center point fresh (no caching to avoid conflicts)
    local modelCenter = Vector3.new(0, 0, 0)
    local partCount = 0
    local originalData = {}
    
    -- Calculate current center and store original data
    for _, descendant in pairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            modelCenter = modelCenter + descendant.Position
            partCount = partCount + 1
            
            -- Store original size and relative position for this scaling operation
            originalData[descendant] = {
                originalSize = descendant:GetAttribute("OriginalSize") or descendant.Size,
                currentPosition = descendant.Position
            }
            
            -- Set original size attribute if not already set
            if not descendant:GetAttribute("OriginalSize") then
                descendant:SetAttribute("OriginalSize", descendant.Size)
            end
        end
    end
    
    if partCount > 0 then
        modelCenter = modelCenter / partCount
    end
    
    -- Don't store relative positions as attributes (causes conflicts between same pet types)
    -- Let the animation controller calculate them dynamically
    
    -- Scale all parts relative to the current center
    for _, descendant in pairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") and originalData[descendant] then
            local data = originalData[descendant]
            local relativePos = data.currentPosition - modelCenter
            
            -- Scale the size using original size
            descendant.Size = data.originalSize * scale
            -- Scale the position relative to current center
            descendant.Position = modelCenter + (relativePos * scale)
        end
    end
end

-- Apply rarity outline effects to model
function PetModelFactory.applyRarityOutline(model, petData)
    if not model or not petData then 
        return 
    end
    
    -- Calculate combined rarity (pet + aura combination)
    local combinedProbability, rarityText = PetConfig:CalculateCombinedRarity(petData.id or 1, petData.aura)
    if not combinedProbability then
        return
    end
    
    -- Get the combined rarity tier and color
    local rarityTierName, rarityColor = PetConfig:GetRarityTierName(combinedProbability)
    
    -- Don't add outline for Common rarity (most basic combined rarity)
    if rarityTierName == "Common" then
        return
    end
    
    -- Find all BaseParts in the model to apply outline
    for _, part in pairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            -- Create SelectionBox for outline effect
            local selectionBox = Instance.new("SelectionBox")
            selectionBox.Name = "RarityOutline"
            selectionBox.Adornee = part
            selectionBox.Color3 = rarityColor -- Use combined rarity color
            selectionBox.LineThickness = 0.04 -- Ultra-thin outline
            selectionBox.Transparency = 0.2 -- Slightly less transparent for visibility
            selectionBox.SurfaceTransparency = 1 -- No surface fill, just outline
            selectionBox.Parent = part
        end
    end
end

-- Apply aura visual effects to model
function PetModelFactory.applyAuraEffects(model, auraData)
    if not model or not auraData then 
        return 
    end
    
    -- Skip aura effects for "Basic" aura
    if auraData.name == "Basic" or auraData.name == "None" then
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
    
    -- Configure particles based on aura rarity and type
    local auraName = auraData.name
    local auraColor = auraData.color
    local auraMultiplier = auraData.multiplier or 1
    
    -- Base particle configuration for all auras
    particleEmitter.Color = ColorSequence.new(auraColor)
    particleEmitter.Lifetime = NumberRange.new(1, 2.5)
    particleEmitter.SpreadAngle = Vector2.new(180, 180)
    particleEmitter.LightEmission = 0.8
    particleEmitter.LightInfluence = 0.2
    
    -- Configure particle intensity and effects based on aura rarity
    if auraName == "Basic" then
        -- No particles for basic aura
        particleEmitter:Destroy()
        return
    elseif auraName == "Rainbow" then
        -- Special rainbow aura with cycling colors
        particleEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        particleEmitter.Rate = 50
        particleEmitter.Speed = NumberRange.new(2, 4)
        particleEmitter.Size = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(0.5, 0.5),
            NumberSequenceKeypoint.new(1, 0)
        }
        particleEmitter.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.6),
            NumberSequenceKeypoint.new(0.5, 0.3),
            NumberSequenceKeypoint.new(1, 1)
        }
        particleEmitter.LightEmission = 1
        
        -- Create rainbow color sequence
        particleEmitter.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),    -- Red
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 127, 0)), -- Orange  
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)), -- Yellow
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),    -- Green
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),   -- Blue
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)),  -- Indigo
            ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 0, 211))     -- Violet
        }
        
        -- Rainbow glow
        local pointLight = Instance.new("PointLight")
        pointLight.Name = "AuraGlow"
        pointLight.Color = Color3.fromRGB(255, 255, 255) -- White light for rainbow
        pointLight.Brightness = 0.8
        pointLight.Range = 15
        pointLight.Parent = primaryPart
        
        -- Add second rainbow particle emitter
        local secondaryEmitter = Instance.new("ParticleEmitter")
        secondaryEmitter.Name = "RainbowParticles"
        secondaryEmitter.Parent = primaryPart
        secondaryEmitter.Texture = "rbxasset://textures/particles/fire_main.dds"
        secondaryEmitter.Rate = 25
        secondaryEmitter.Speed = NumberRange.new(0.5, 2)
        secondaryEmitter.Lifetime = NumberRange.new(2, 4)
        secondaryEmitter.Size = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.3),
            NumberSequenceKeypoint.new(0.5, 0.6),
            NumberSequenceKeypoint.new(1, 0)
        }
        secondaryEmitter.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.8),
            NumberSequenceKeypoint.new(0.5, 0.5),
            NumberSequenceKeypoint.new(1, 1)
        }
        secondaryEmitter.LightEmission = 0.9
        secondaryEmitter.SpreadAngle = Vector2.new(45, 45)
        -- Offset rainbow colors for the secondary emitter
        secondaryEmitter.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 127)),    -- Hot Pink
            ColorSequenceKeypoint.new(0.25, Color3.fromRGB(0, 255, 127)), -- Spring Green
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(127, 0, 255)),  -- Purple
            ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 127, 0)), -- Orange
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 127, 255))     -- Sky Blue
        }
    elseif auraMultiplier <= 1.5 then
        -- Low-tier auras (Wood, Silver) - made more visible
        particleEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        particleEmitter.Rate = 15  -- Increased from 8
        particleEmitter.Speed = NumberRange.new(1, 2)  -- Increased speed
        particleEmitter.Size = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.15),  -- Increased from 0.1
            NumberSequenceKeypoint.new(0.5, 0.25),  -- Increased from 0.2
            NumberSequenceKeypoint.new(1, 0)
        }
        particleEmitter.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.7),  -- Less transparent (was 0.9)
            NumberSequenceKeypoint.new(0.5, 0.5),  -- Less transparent (was 0.7)
            NumberSequenceKeypoint.new(1, 1)
        }
    elseif auraMultiplier <= 5 then
        -- Mid-tier auras (Gold, Diamond, Platinum)
        particleEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        particleEmitter.Rate = 20
        particleEmitter.Speed = NumberRange.new(1, 2.5)
        particleEmitter.Size = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.15),
            NumberSequenceKeypoint.new(0.5, 0.3),
            NumberSequenceKeypoint.new(1, 0)
        }
        particleEmitter.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.8),
            NumberSequenceKeypoint.new(0.5, 0.5),
            NumberSequenceKeypoint.new(1, 1)
        }
        
        -- Add point light for mid-tier
        local pointLight = Instance.new("PointLight")
        pointLight.Name = "AuraGlow"
        pointLight.Color = auraColor
        pointLight.Brightness = 0.3
        pointLight.Range = 8
        pointLight.Parent = primaryPart
    elseif auraMultiplier <= 15 then
        -- High-tier auras (Emerald, Ruby, Sapphire, Rainbow)
        particleEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        particleEmitter.Rate = 40
        particleEmitter.Speed = NumberRange.new(1.5, 3.5)
        particleEmitter.Size = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(0.5, 0.4),
            NumberSequenceKeypoint.new(1, 0)
        }
        particleEmitter.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.7),
            NumberSequenceKeypoint.new(0.5, 0.4),
            NumberSequenceKeypoint.new(1, 1)
        }
        
        -- Stronger glow for high-tier
        local pointLight = Instance.new("PointLight")
        pointLight.Name = "AuraGlow"
        pointLight.Color = auraColor
        pointLight.Brightness = 0.6
        pointLight.Range = 12
        pointLight.Parent = primaryPart
    else
        -- God-tier auras (Cosmic, Void, Celestial)
        particleEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        particleEmitter.Rate = 60
        particleEmitter.Speed = NumberRange.new(2, 4)
        particleEmitter.Size = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.25),
            NumberSequenceKeypoint.new(0.5, 0.5),
            NumberSequenceKeypoint.new(1, 0)
        }
        particleEmitter.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.6),
            NumberSequenceKeypoint.new(0.5, 0.3),
            NumberSequenceKeypoint.new(1, 1)
        }
        particleEmitter.LightEmission = 1
        
        -- Intense glow for god-tier
        local pointLight = Instance.new("PointLight")
        pointLight.Name = "AuraGlow"
        pointLight.Color = auraColor
        pointLight.Brightness = 1
        pointLight.Range = 15
        pointLight.Parent = primaryPart
        
        -- Add second particle emitter for extra effects on god-tier
        local secondaryEmitter = Instance.new("ParticleEmitter")
        secondaryEmitter.Name = "SecondaryAuraParticles"
        secondaryEmitter.Parent = primaryPart
        secondaryEmitter.Texture = "rbxasset://textures/particles/fire_main.dds"
        secondaryEmitter.Color = ColorSequence.new(auraColor)
        secondaryEmitter.Rate = 15
        secondaryEmitter.Speed = NumberRange.new(0.5, 1)
        secondaryEmitter.Lifetime = NumberRange.new(2, 3)
        secondaryEmitter.Size = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.3),
            NumberSequenceKeypoint.new(0.5, 0.6),
            NumberSequenceKeypoint.new(1, 0)
        }
        secondaryEmitter.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.8),
            NumberSequenceKeypoint.new(0.5, 0.6),
            NumberSequenceKeypoint.new(1, 1)
        }
        secondaryEmitter.LightEmission = 0.9
        secondaryEmitter.SpreadAngle = Vector2.new(90, 90)
    end
end

return PetModelFactory