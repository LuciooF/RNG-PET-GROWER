-- Modern Pet Inventory UI - Matches screenshot design with white background and proper sections
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local React = require(ReplicatedStorage.Packages.react)
local DataSyncService = require(script.Parent.Parent.services.DataSyncService)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local PetConstants = require(ReplicatedStorage.constants.PetConstants)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)
local AnimationService = require(script.Parent.Parent.services.AnimationService)
local GradientUtils = require(ReplicatedStorage.utils.GradientUtils)

-- Pet inventory limit
local MAX_PET_INVENTORY = 1000

-- Sound configuration
local HOVER_SOUND_ID = "rbxassetid://6895079853"

-- Pre-create hover sound for instant playback
local hoverSound = Instance.new("Sound")
hoverSound.SoundId = HOVER_SOUND_ID
hoverSound.Volume = 0.5
hoverSound.Parent = SoundService

-- Play hover sound instantly
local function playHoverSound()
    hoverSound:Play()
end

-- Helper function to create pet models for ViewportFrame (same pattern as ClientPetBallService)
local function createPetModelForInventory(petData, rotationIndex)
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
            
            -- First, process all parts for scaling and properties
            local scaleFactor = 4.2 -- 20% bigger than previous (3.5 * 1.2)
            
            for _, descendant in pairs(clonedModel:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    descendant.Size = descendant.Size * scaleFactor
                    descendant.CanCollide = false
                    descendant.Anchored = true -- Anchored for viewport
                    descendant.Massless = true
                    -- Make parts visible with original materials preserved
                    descendant.Transparency = math.max(0, descendant.Transparency - 0.3) -- Reduce transparency
                    -- Keep original material unless it's invisible
                    if descendant.Material == Enum.Material.ForceField then
                        descendant.Material = Enum.Material.Plastic
                    end
                end
            end
            
            -- Use 160 degrees rotation for all pets to show faces correctly
            local rotationAngle = 160
            
            -- Move entire model to origin using MoveTo, then rotate all parts
            clonedModel:MoveTo(Vector3.new(0, 0, 0))
            
            -- Then apply rotation to each part around the origin
            for _, descendant in pairs(clonedModel:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    -- Rotate each part around the origin
                    local rotationCFrame = CFrame.Angles(0, math.rad(rotationAngle), 0)
                    local currentPos = descendant.Position
                    local rotatedPos = rotationCFrame * currentPos
                    descendant.Position = rotatedPos
                    
                    -- Also rotate the part's orientation
                    descendant.CFrame = CFrame.new(rotatedPos) * rotationCFrame * (descendant.CFrame - descendant.Position)
                end
            end
            
            return clonedModel
        end
    end
    
    -- Return nil if no model found
    return nil
end

-- Helper function to setup ViewportFrame camera for pet model
local function setupPetViewportCamera(viewportFrame, petModel)
    if not viewportFrame or not petModel then
        return
    end
    
    -- Create camera for the viewport
    local camera = Instance.new("Camera")
    camera.CameraType = Enum.CameraType.Scriptable
    camera.Parent = viewportFrame
    viewportFrame.CurrentCamera = camera
    
    -- Get model bounds for better camera positioning
    local modelCFrame, modelSize = petModel:GetBoundingBox()
    local maxSize = math.max(modelSize.X, modelSize.Y, modelSize.Z)
    
    -- Position camera at a good angle to show the pet model fully
    local distance = maxSize * 1.8 -- Good distance to see full model
    local cameraPosition = modelCFrame.Position + Vector3.new(distance * 0.7, distance * 0.4, distance * 0.7)
    
    -- Point camera at center of model
    camera.CFrame = CFrame.lookAt(cameraPosition, modelCFrame.Position)
    
    -- Add slight lighting by setting the ambient
    game.Lighting.Ambient = Color3.fromRGB(100, 100, 100)
end

local function PetInventoryUI(props)
    local playerData, setPlayerData = React.useState({
        Pets = {},
        EquippedPets = {},
        OPPets = {}
    })
    local isVisible, setIsVisible = React.useState(props.visible or false)
    local hoveredPet, setHoveredPet = React.useState(nil)
    local tooltipPosition, setTooltipPosition = React.useState(UDim2.new(0, 0, 0, 0))
    local equippedTab, setEquippedTab = React.useState("Regular") -- "Regular" or "OP"
    
    -- Animation state for bouncing disclaimer text
    local disclaimerBounceOffset, setDisclaimerBounceOffset = React.useState(0)
    local activeAnimations = React.useRef({})
    
    -- Update visibility when props change
    React.useEffect(function()
        setIsVisible(props.visible or false)
    end, {props.visible})
    
    -- Setup bounce animation for disclaimer text (same as Pet Index)
    React.useEffect(function()
        if isVisible then
            local bounceAnimation = AnimationService:CreateReactBounceAnimation({
                duration = 0.8, -- Same as Pet Index
                upOffset = 10, -- Same as Pet Index  
                downOffset = 10, -- Same as Pet Index
                pauseBetween = 0.5 -- Same as Pet Index
            }, {
                onPositionChange = setDisclaimerBounceOffset
            })
            activeAnimations.current.disclaimerBounce = bounceAnimation
            
            return function()
                if bounceAnimation then
                    bounceAnimation:Stop()
                end
                activeAnimations.current = {}
            end
        end
    end, {isVisible})

    -- Subscribe to data changes
    React.useEffect(function()
        -- Get initial data
        local initialData = DataSyncService:GetPlayerData()
        if initialData then
            setPlayerData(initialData)
        end
        
        -- Subscribe to data updates
        local unsubscribe = DataSyncService:Subscribe(function(newState)
            if newState and newState.player then
                setPlayerData(newState.player)
            end
        end)
        
        return function()
            if unsubscribe and type(unsubscribe) == "function" then
                unsubscribe()
            end
        end
    end, {})

    -- Keyboard shortcut (P key)
    React.useEffect(function()
        local connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            if input.KeyCode == Enum.KeyCode.P then
                setIsVisible(function(prev) return not prev end)
            end
        end)
        
        return function()
            if connection and typeof(connection) == "RBXScriptConnection" then
                pcall(function()
                    connection:Disconnect()
                end)
            end
        end
    end, {})

    local pets = playerData and playerData.Pets or {}
    local equippedPets = playerData and playerData.EquippedPets or {}
    local opPets = playerData and playerData.OPPets or {}
    
    -- Group pets by name, rarity, and variation for inventory
    local function groupPets(petList)
        local groups = {}
        
        for _, pet in ipairs(petList) do
            if pet and pet.Name then
                -- Extract rarity and variation names from either string or table format
                local rarityName = pet.Rarity
                if type(pet.Rarity) == "table" and pet.Rarity.RarityName then
                    rarityName = pet.Rarity.RarityName
                end
                
                local variationName = pet.Variation
                if type(pet.Variation) == "table" and pet.Variation.VariationName then
                    variationName = pet.Variation.VariationName
                end
                
                if rarityName and variationName then
                    local key = string.format("%s_%s_%s", pet.Name, rarityName, variationName)
                    
                    if not groups[key] then
                        groups[key] = {
                            Name = pet.Name,
                            Rarity = rarityName,
                            Variation = variationName,
                            BaseValue = pet.BaseValue or 100,
                            BaseBoost = pet.BaseBoost or 1,
                            FinalBoost = pet.FinalBoost or pet.BaseBoost or 1,
                            Quantity = 0,
                            SamplePet = pet
                        }
                    end
                    groups[key].Quantity = groups[key].Quantity + 1
                end
            end
        end
        
        -- Convert to array and sort by boost (highest first)
        local groupArray = {}
        for _, group in pairs(groups) do
            table.insert(groupArray, group)
        end
        
        table.sort(groupArray, function(a, b)
            local aBoost = a.FinalBoost or a.BaseBoost or 1
            local bBoost = b.FinalBoost or b.BaseBoost or 1
            if aBoost ~= bBoost then
                return aBoost > bBoost -- Higher boost first
            else
                return a.Name < b.Name -- Alphabetical as tiebreaker
            end
        end)
        
        return groupArray
    end
    
    local equippedGroups = groupPets(equippedPets)
    local opGroups = groupPets(opPets)
    local inventoryGroups = groupPets(pets)
    
    -- Create pet card component
    local function createPetCard(petGroup, cardIndex, isEquipped, inEquippedSection)
        -- Safety check: ensure petGroup is valid
        if not petGroup or not petGroup.Name then
            return nil
        end
        local variationColor = PetConstants.getVariationColor(petGroup.Variation)
        local rarityColor = PetConstants.getRarityColor(petGroup.Rarity)
        
        -- Check if this is an OP pet
        local isOPPet = petGroup.Rarity == "OP" or petGroup.Rarity == PetConstants.Rarity.OP or 
                        (petGroup.SamplePet and petGroup.SamplePet.IsOPPet)
        
        -- Calculate final value
        local baseValue = petGroup.BaseValue or 100
        local variationMultiplier = PetConstants.getVariationMultiplier(petGroup.Variation)
        local finalValue = math.floor(baseValue * variationMultiplier)
        
        -- Calculate final boost display
        local finalBoost = petGroup.FinalBoost or petGroup.BaseBoost or 1
        local boostPercentage = (finalBoost - 1) * 100
        
        return React.createElement("Frame", {
            Size = ScreenUtils.udim2(0, 190, 0, 190), -- Even bigger card size (was 160x160)
            BackgroundTransparency = 1, -- Fully transparent to show colored background
            BorderSizePixel = 0, -- No border, using UIStroke instead
            LayoutOrder = cardIndex,
            ZIndex = 10,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, 80) -- Half of 160 for perfect circle
            }),
            
            -- Squiggle background with rarity color (waiting for white squiggle asset)
            SquiggleBackground = React.createElement("ImageLabel", {
                Size = ScreenUtils.udim2(0.9, 0, 0.9, 0),
                Position = ScreenUtils.udim2(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1, -- Transparent background
                Image = IconAssets.getIcon("UI", "SQUIGGLE"),
                ImageColor3 = isOPPet and Color3.fromRGB(255, 255, 255) or variationColor, -- White for OP pets to show gradient
                ImageTransparency = 0.3, -- Slightly transparent
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 9, -- Behind viewport
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 58) -- Circular clipping
                }),
                -- Rainbow gradient for OP pets
                RainbowGradient = isOPPet and GradientUtils.CreateReactGradient(GradientUtils.WithRotation(GradientUtils.RAINBOW_CYAN, 45)) or nil
            }),
            
            -- Pet model viewport (takes most of the card space)
            PetViewport = React.createElement("ViewportFrame", {
                Size = ScreenUtils.udim2(1, -10, 1, -25), -- Leave space for pet name and badges
                Position = ScreenUtils.udim2(0, 5, 0, 5),
                BackgroundTransparency = 1, -- Transparent viewport
                ZIndex = 11, -- Above paint splatter
                
                -- Load pet model when viewport is created
                [React.Event.AncestryChanged] = function(rbx)
                    if rbx.Parent then
                        -- Delay to ensure viewport is ready
                        task.spawn(function()
                            task.wait(0.1)
                            
                            local petModel = createPetModelForInventory(petGroup.SamplePet or petGroup, cardIndex)
                            if petModel then
                                petModel.Parent = rbx
                                setupPetViewportCamera(rbx, petModel)
                            end
                        end)
                    end
                end,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 60) -- Circular viewport
                }),
            }),
            
            -- Quantity badge (top right)
            QuantityBadge = React.createElement("Frame", {
                Size = ScreenUtils.udim2(0, 70, 0, 35), -- Even bigger badge
                Position = ScreenUtils.udim2(1, -75, 0, 5),
                BackgroundColor3 = Color3.fromRGB(255, 215, 0), -- Gold background
                BackgroundTransparency = 0,
                BorderSizePixel = 3,
                BorderColor3 = Color3.fromRGB(0, 0, 0), -- Thicker black outline
                ZIndex = 12,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 6)
                }),
                
                QuantityText = React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "x" .. petGroup.Quantity,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() * 1.2, -- Even bigger text
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextStrokeTransparency = 0, -- Add text outline
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 13,
                })
            }),
            
            -- Equipped badge (top left, higher up to avoid overlap with quantity)
            EquippedBadge = (isEquipped and not inEquippedSection) and (function()
                return React.createElement("Frame", {
                Size = ScreenUtils.udim2(0, 80, 0, 30), -- Bigger badge
                Position = ScreenUtils.udim2(0.5, -40, 0.5, -15), -- Center of the card
                BackgroundColor3 = Color3.fromRGB(50, 205, 50), -- Lime green background
                BackgroundTransparency = 0,
                BorderSizePixel = 3,
                BorderColor3 = Color3.fromRGB(0, 0, 0), -- Thicker black outline
                ZIndex = 12,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 6)
                }),
                
                EquippedText = React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "EQUIPPED",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() * 0.9, -- Bigger text
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextStrokeTransparency = 0, -- Add text outline
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 13,
                })
            })
            end)() or nil,
            
            
            -- Boost text above pet name (rainbow gradient for visual appeal)
            BoostText = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, -10, 0, 25), -- Bigger height
                Position = ScreenUtils.udim2(0, 5, 1, -55), -- Adjust position for bigger card
                BackgroundTransparency = 1,
                Text = "x" .. NumberFormatter.formatBoost(finalBoost),
                TextColor3 = Color3.fromRGB(255, 255, 255), -- White base for gradient overlay
                TextSize = ScreenUtils.TEXT_SIZES.LARGE() * 0.85, -- Same size as pet name
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextScaled = true, -- Match pet name scaling
                TextStrokeTransparency = 0, -- Black outline for boost text
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                ZIndex = 14,
            }, {
                -- Shiny pink to blue gradient overlay
                ShinyGradient = GradientUtils.CreateReactGradient(GradientUtils.SHINY_BOOST)
            }),
            
            -- Pet name at bottom (with rarity color or rainbow for OP)
            PetName = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, -10, 0, 25), -- Bigger height
                Position = ScreenUtils.udim2(0, 5, 1, -25), -- Adjust position
                BackgroundTransparency = 1, -- No background
                Text = petGroup.Name,
                TextColor3 = isOPPet and Color3.fromRGB(255, 255, 255) or rarityColor, -- White for OP pets to show gradient
                TextSize = ScreenUtils.TEXT_SIZES.LARGE() * 0.85, -- Increased from MEDIUM
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextScaled = true,
                TextStrokeTransparency = 0, -- Black stroke for visibility
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                ZIndex = 14,
            }, {
                -- Rainbow gradient for OP pet names
                RainbowGradient = isOPPet and GradientUtils.CreateReactGradient(GradientUtils.RAINBOW_CYAN) or nil
            }),
            
            -- Hover detection for tooltip
            HoverDetector = React.createElement("TextButton", {
                Size = ScreenUtils.udim2(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 15,
                [React.Event.MouseEnter] = function(rbx)
                    playHoverSound() -- Play hover sound
                    setHoveredPet(petGroup)
                    
                    -- Calculate tooltip position with error handling
                    local success, _ = pcall(function()
                        if rbx and rbx.Parent and rbx.AbsolutePosition and rbx.AbsoluteSize then
                            local responsiveOffset = ScreenUtils.getScaleFactor() * 10
                            setTooltipPosition(UDim2.new(0, rbx.AbsolutePosition.X + rbx.AbsoluteSize.X + responsiveOffset, 0, rbx.AbsolutePosition.Y))
                        end
                    end)
                    
                    if not success then
                        -- Fallback: try again after a brief delay
                        task.spawn(function()
                            task.wait(0.1)
                            pcall(function()
                                if rbx and rbx.Parent and rbx.AbsolutePosition and rbx.AbsoluteSize then
                                    local responsiveOffset = ScreenUtils.getScaleFactor() * 10
                                    setTooltipPosition(UDim2.new(0, rbx.AbsolutePosition.X + rbx.AbsoluteSize.X + responsiveOffset, 0, rbx.AbsolutePosition.Y))
                                end
                            end)
                        end)
                    end
                end,
                [React.Event.MouseLeave] = function()
                    -- Store reference to current pet for delayed clearing
                    local currentPet = petGroup
                    task.spawn(function()
                        task.wait(0.05) -- Very short delay (50ms)
                        -- Only clear if we're still on the same pet (haven't moved to another card)
                        setHoveredPet(function(currentHoveredPet)
                            if currentHoveredPet == currentPet then
                                return nil -- Clear only if still the same pet
                            else
                                return currentHoveredPet -- Keep current hovered pet
                            end
                        end)
                    end)
                end,
            })
        })
    end
    
    -- Create tooltip component
    local function createTooltip()
        if not hoveredPet then return nil end
        
        local variationColor = PetConstants.getVariationColor(hoveredPet.Variation)
        local rarityColor = PetConstants.getRarityColor(hoveredPet.Rarity)
        
        -- Check if this is an OP pet
        local isOPPet = hoveredPet.Rarity == "OP" or hoveredPet.Rarity == PetConstants.Rarity.OP or 
                        (hoveredPet.SamplePet and hoveredPet.SamplePet.IsOPPet) or
                        hoveredPet.IsOPPet
        
        -- Calculate final value
        local baseValue = hoveredPet.BaseValue or 100
        local variationMultiplier = PetConstants.getVariationMultiplier(hoveredPet.Variation)
        local finalValue = math.floor(baseValue * variationMultiplier)
        
        -- Calculate final boost
        local finalBoost = hoveredPet.FinalBoost or hoveredPet.BaseBoost or 1
        
        return React.createElement("Frame", {
            Size = ScreenUtils.udim2(0, 280, 0, 210), -- Even bigger tooltip to fit rarity chance
            Position = tooltipPosition,
            BackgroundColor3 = Color3.fromRGB(250, 250, 250), -- Light background
            BorderSizePixel = 0, -- No border, using shadow effect
            ZIndex = 1000,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, 12) -- More rounded corners
            }),
            
            -- Drop shadow effect
            Shadow = React.createElement("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 2,
                Transparency = 0.8, -- Subtle shadow
            }),
            
            -- Gradient background for modern look
            Gradient = GradientUtils.CreateReactGradient(GradientUtils.CreateSimple(
                Color3.fromRGB(255, 255, 255),
                Color3.fromRGB(240, 240, 240),
                45
            )),
            
            -- Pet name (title)
            Name = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, -20, 0, 30),
                Position = ScreenUtils.udim2(0, 10, 0, 10),
                BackgroundTransparency = 1,
                Text = hoveredPet.Name,
                TextColor3 = Color3.fromRGB(50, 50, 50),
                TextSize = ScreenUtils.TEXT_SIZES.LARGE(), -- Bigger title
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center, -- Center the text
                ZIndex = 1001,
            }),
            
            -- Rarity (with color or rainbow for OP)
            Rarity = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, -20, 0, 25),
                Position = ScreenUtils.udim2(0, 10, 0, 45),
                BackgroundTransparency = 1,
                Text = "Rarity: " .. hoveredPet.Rarity,
                TextColor3 = isOPPet and Color3.fromRGB(255, 255, 255) or rarityColor,
                TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(), -- Bigger text
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center, -- Center the text
                ZIndex = 1001,
            }, {
                -- Rainbow gradient for OP pet rarity
                RainbowGradient = isOPPet and GradientUtils.CreateReactGradient(GradientUtils.RAINBOW_CYAN) or nil
            }),
            
            -- Variation (with color or rainbow for OP)
            Variation = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, -20, 0, 25),
                Position = ScreenUtils.udim2(0, 10, 0, 75),
                BackgroundTransparency = 1,
                Text = "Variation: " .. hoveredPet.Variation,
                TextColor3 = isOPPet and Color3.fromRGB(255, 255, 255) or variationColor,
                TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center, -- Center the text
                ZIndex = 1001,
            }, {
                -- Rainbow gradient for OP pet variation
                RainbowGradient = isOPPet and GradientUtils.CreateReactGradient(GradientUtils.RAINBOW_CYAN) or nil
            }),
            
            -- Rarity chance (1 in xxx format)
            RarityChance = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, -20, 0, 25),
                Position = ScreenUtils.udim2(0, 10, 0, 105),
                BackgroundTransparency = 1,
                Text = "Chance: 1 in " .. (PetConstants.getCombinedRarityChance and NumberFormatter.format(PetConstants.getCombinedRarityChance(hoveredPet.Rarity, hoveredPet.Variation)) or "???"),
                TextColor3 = Color3.fromRGB(150, 150, 150), -- Lighter gray for better visibility
                TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                Font = Enum.Font.GothamSemibold,
                TextXAlignment = Enum.TextXAlignment.Center, -- Center the text
                TextStrokeTransparency = 0.5, -- Lighter stroke
                TextStrokeColor3 = Color3.fromRGB(255, 255, 255), -- White outline instead of black
                ZIndex = 1001,
            }),
            
            -- Value with money icon
            Value = React.createElement("Frame", {
                Size = ScreenUtils.udim2(1, -20, 0, 25),
                Position = ScreenUtils.udim2(0, 10, 0, 135), -- Moved down to make room for rarity chance
                BackgroundTransparency = 1,
                ZIndex = 1001,
            }, {
                MoneyIcon = React.createElement("ImageLabel", {
                    Size = ScreenUtils.udim2(0, 20, 0, 20), -- Bigger icon
                    Position = ScreenUtils.udim2(0, 0, 0, 2),
                    BackgroundTransparency = 1,
                    Image = IconAssets.getIcon("CURRENCY", "MONEY"),
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 1002,
                }),
                
                ValueText = React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(1, -25, 1, 0),
                    Position = ScreenUtils.udim2(0, 25, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "Value: " .. NumberFormatter.format(finalValue),
                    TextColor3 = Color3.fromRGB(50, 50, 50),
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(), -- Bigger text
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center, -- Center the text
                    ZIndex = 1002,
                })
            }),
            
            -- Boost with boost icon
            Boost = React.createElement("Frame", {
                Size = ScreenUtils.udim2(1, -20, 0, 25),
                Position = ScreenUtils.udim2(0, 10, 0, 165), -- Moved down further to make room for rarity chance and value
                BackgroundTransparency = 1,
                ZIndex = 1001,
            }, {
                BoostIcon = React.createElement("ImageLabel", {
                    Size = ScreenUtils.udim2(0, 20, 0, 20), -- Bigger icon
                    Position = ScreenUtils.udim2(0, 0, 0, 2),
                    BackgroundTransparency = 1,
                    Image = IconAssets.getIcon("UI", "BOOST"),
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 1002,
                }),
                
                BoostText = React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(1, -25, 1, 0),
                    Position = ScreenUtils.udim2(0, 25, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "x" .. NumberFormatter.formatBoost(finalBoost),
                    TextColor3 = Color3.fromRGB(255, 255, 255), -- White base for gradient
                    TextSize = ScreenUtils.TEXT_SIZES.LARGE() * 0.85, -- Same size as pet name
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center, -- Center the text
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextScaled = true, -- Match pet name scaling
                    TextStrokeTransparency = 0, -- Black outline for boost text
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 1002,
                }, {
                    -- Same pink to blue gradient as inventory cards
                    ShinyGradient = GradientUtils.CreateReactGradient(GradientUtils.SHINY_BOOST)
                })
            })
        })
    end

    if not isVisible then
        return nil
    end

    -- Main inventory panel
    return React.createElement("ScreenGui", {
        Name = "PetInventoryGUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
    }, {
        -- Click-outside overlay (same pattern as PetIndexUI)
        ClickOutsideOverlay = React.createElement("TextButton", {
            Name = "PetInventoryOverlay",
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 0, -- Lowest - behind everything
            [React.Event.MouseButton1Click] = function()
                -- Close inventory when clicking outside
                setIsVisible(false)
                if props.onClose then props.onClose() end
            end
        }),
        
        -- Main panel (smaller and more centered)
        MainPanel = React.createElement("TextButton", {
            Size = ScreenUtils.udim2(0.6, 0, 0.75, 0), -- Even smaller overall UI
            Position = ScreenUtils.udim2(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255), -- White background
            BorderSizePixel = 3,
            BorderColor3 = Color3.fromRGB(0, 0, 0), -- Black outline
            ZIndex = 1, -- Background should be lowest
            Text = "", -- No text
            AutoButtonColor = false, -- Don't change color on hover
            [React.Event.Activated] = function()
                -- Do nothing to prevent closing when clicking inside
            end
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, 12)
            }),
            
            -- Header with X button
            Header = React.createElement("Frame", {
                Size = ScreenUtils.udim2(1, 0, 0, 50),
                BackgroundTransparency = 1, -- Transparent for gradient
                BorderSizePixel = 2,
                BorderColor3 = Color3.fromRGB(0, 0, 0), -- Black outline
                ZIndex = 6,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 12)
                }),
                
                -- Gradient background for header
                GradientBackground = React.createElement("Frame", {
                    Size = ScreenUtils.udim2(1, 0, 1, 0),
                    BackgroundColor3 = Color3.fromRGB(64, 224, 208), -- Turquoise base
                    BorderSizePixel = 0,
                    ZIndex = 5,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, 12)
                    }),
                    Gradient = GradientUtils.CreateReactGradient(GradientUtils.WHITE_TO_GRAY, {
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0.3),
                            NumberSequenceKeypoint.new(1, 0.6)
                        })
                    }),
                }),
                
                Title = React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(1, -60, 1, 0),
                    Position = ScreenUtils.udim2(0.5, 0, 0, 0),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    Text = "Pet Inventory",
                    TextColor3 = Color3.fromRGB(64, 224, 208), -- Turquoise
                    TextSize = ScreenUtils.TEXT_SIZES.LARGE() + 4, -- Bigger
                    TextStrokeTransparency = 0, -- Black outline
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    ZIndex = 7,
                }),
                
                CloseButton = React.createElement("ImageButton", {
                    Size = ScreenUtils.udim2(0, 50, 0, 50), -- Bigger close button
                    Position = ScreenUtils.udim2(1, -55, 0.5, -25),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    Image = IconAssets.getIcon("UI", "X_BUTTON"),
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 7,
                    [React.Event.Activated] = function()
                        setIsVisible(false)
                        if props.onClose then props.onClose() end
                    end
                })
            }),
            
            -- Equipped pets section
            EquippedSection = React.createElement("Frame", {
                Size = ScreenUtils.udim2(1, -40, 0, 380), -- Increased height to show pet names better
                Position = ScreenUtils.udim2(0.5, 0, 0, 60),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundTransparency = 1, -- Remove background for image
                BorderSizePixel = 2,
                BorderColor3 = Color3.fromRGB(0, 0, 0), -- Black outline
                ZIndex = 6,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 8)
                }),
                
                Stroke = React.createElement("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0), -- Black outline
                    Thickness = 2,
                }),
                
                -- White background (or rainbow for OP)
                WhiteBackground = React.createElement("Frame", {
                    Size = ScreenUtils.udim2(1, 0, 1, 0),
                    Position = ScreenUtils.udim2(0, 0, 0, 0),
                    BackgroundColor3 = equippedTab == "OP" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(245, 245, 245), -- White for gradient base
                    BorderSizePixel = 0,
                    ZIndex = 4, -- Behind everything
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, 8)
                    }),
                    -- Rainbow gradient for OP pets
                    RainbowGradient = equippedTab == "OP" and GradientUtils.CreateReactGradient(GradientUtils.LIGHT_RAINBOW) or nil
                }),
                
                -- Background image for equipped pets section
                BackgroundImage = React.createElement("ImageLabel", {
                    Size = ScreenUtils.udim2(1, 0, 1, 0),
                    Position = ScreenUtils.udim2(0, 0, 0, 0),
                    BackgroundTransparency = 1, -- Transparent so white shows through
                    Image = "rbxassetid://116367512866072",
                    ScaleType = Enum.ScaleType.Tile,
                    TileSize = ScreenUtils.udim2(0, 120, 0, 120), -- Medium paw pattern
                    ImageTransparency = 0.85, -- More transparent for subtle effect
                    ImageColor3 = Color3.fromRGB(200, 200, 200), -- Lighter grey tint
                    ZIndex = 5, -- Above white background
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, 8)
                    }),
                }),
                
                -- Tab container
                TabContainer = React.createElement("Frame", {
                    Size = ScreenUtils.udim2(1, -10, 0, 40),
                    Position = ScreenUtils.udim2(0.5, 0, 0, 5),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    ZIndex = 7,
                }, {
                    -- Regular pets tab
                    RegularTab = React.createElement("TextButton", {
                        Size = ScreenUtils.udim2(0.5, -5, 1, 0),
                        Position = ScreenUtils.udim2(0, 0, 0, 0),
                        BackgroundColor3 = equippedTab == "Regular" and Color3.fromRGB(64, 224, 208) or Color3.fromRGB(200, 200, 200),
                        BorderSizePixel = 2,
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        Text = string.format("Equipped Pets %d/3", #equippedPets),
                        TextColor3 = equippedTab == "Regular" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 100, 100),
                        TextSize = ScreenUtils.TEXT_SIZES.LARGE() + 2,
                        TextStrokeTransparency = equippedTab == "Regular" and 0 or 0.5,
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        Font = Enum.Font.FredokaOne,
                        ZIndex = 8,
                        [React.Event.Activated] = function()
                            setEquippedTab("Regular")
                        end
                    }, {
                        Corner = React.createElement("UICorner", {
                            CornerRadius = ScreenUtils.udim(0, 8)
                        })
                    }),
                    
                    -- OP pets tab
                    OPTab = React.createElement("TextButton", {
                        Size = ScreenUtils.udim2(0.5, -5, 1, 0),
                        Position = ScreenUtils.udim2(0.5, 5, 0, 0),
                        BackgroundColor3 = equippedTab == "OP" and Color3.fromRGB(255, 20, 147) or Color3.fromRGB(200, 200, 200),
                        BorderSizePixel = 2,
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        Text = string.format("OP Pets (%d)", #opPets),
                        TextColor3 = equippedTab == "OP" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 100, 100),
                        TextSize = ScreenUtils.TEXT_SIZES.LARGE() + 2,
                        TextStrokeTransparency = equippedTab == "OP" and 0 or 0.5,
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        Font = Enum.Font.FredokaOne,
                        ZIndex = 8,
                        [React.Event.Activated] = function()
                            setEquippedTab("OP")
                        end
                    }, {
                        Corner = React.createElement("UICorner", {
                            CornerRadius = ScreenUtils.udim(0, 8)
                        }),
                        -- Rainbow gradient for OP tab when active
                        Gradient = equippedTab == "OP" and GradientUtils.CreateReactGradient(GradientUtils.RAINBOW) or nil
                    })
                }),
                
                -- Auto-equip disclaimer with AnimationService bounce (same as Pet Index)
                Disclaimer = equippedTab == "Regular" and React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(0, 320, 0, 50), -- Even bigger to fit two lines
                    Position = ScreenUtils.udim2(0, 20, 0, 50 + disclaimerBounceOffset), -- AnimationService bounce offset
                    AnchorPoint = Vector2.new(0, 0),
                    BackgroundTransparency = 1,
                    Text = "Best pets automatically get equipped!\nThe boost affects the money production!",
                    TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                    TextSize = ScreenUtils.TEXT_SIZES.LARGE(), -- Bigger text
                    Font = Enum.Font.FredokaOne, -- Bold for emphasis
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0), -- Black outline
                    Rotation = 0, -- Straight text (no tilt)
                    ZIndex = 8,
                }) or nil,
                
                EquippedGrid = React.createElement("ScrollingFrame", {
                    Size = ScreenUtils.udim2(1, -10, 1, -70), -- More height for pet cards
                    Position = ScreenUtils.udim2(0.5, 0, 0, 65), -- Moved up slightly
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 2,
                BorderColor3 = Color3.fromRGB(0, 0, 0), -- Black outline
                    ScrollBarThickness = 6,
                    ScrollBarImageColor3 = Color3.fromRGB(150, 150, 150),
                    ScrollingDirection = Enum.ScrollingDirection.X, -- Horizontal scroll
                    CanvasSize = ScreenUtils.udim2(0, math.max(500, (equippedTab == "Regular" and #equippedGroups or #opGroups) * 200), 1, 0), -- Dynamic based on tab
                    ZIndex = 7,
                }, {
                    Layout = React.createElement("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Padding = ScreenUtils.udim(0, 10),
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                    }),
                    
                    Padding = React.createElement("UIPadding", {
                        PaddingLeft = ScreenUtils.udim(0, 5),
                        PaddingRight = ScreenUtils.udim(0, 5),
                        PaddingTop = ScreenUtils.udim(0, 5),
                        PaddingBottom = ScreenUtils.udim(0, 5)
                    })
                }, (equippedTab == "Regular" and #equippedGroups > 0) and React.createElement(React.Fragment, nil, (function()
                    local equippedElements = {}
                    for i, petGroup in ipairs(equippedGroups) do
                        equippedElements["EquippedPet_" .. i] = createPetCard(petGroup, i, true, true) -- true for inEquippedSection
                    end
                    return equippedElements
                end)()) or (equippedTab == "OP" and #opGroups > 0) and React.createElement(React.Fragment, nil, (function()
                    local opElements = {}
                    for i, petGroup in ipairs(opGroups) do
                        opElements["OPPet_" .. i] = createPetCard(petGroup, i, true, true) -- OP pets are always "equipped"
                    end
                    return opElements
                end)()) or nil)
            }),
            
            -- Inventory pets section (only show for Regular tab)
            InventorySection = equippedTab == "Regular" and React.createElement("Frame", {
                Size = ScreenUtils.udim2(1, -40, 1, -460), -- Adjust for even bigger equipped section
                Position = ScreenUtils.udim2(0.5, 0, 0, 450), -- Move down more to accommodate bigger equipped section
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundTransparency = 1, -- Remove background for image
                BorderSizePixel = 2,
                BorderColor3 = Color3.fromRGB(0, 0, 0), -- Black outline
                ZIndex = 6,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 8)
                }),
                
                Stroke = React.createElement("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0), -- Black outline
                    Thickness = 2,
                }),
                
                -- White background
                WhiteBackground = React.createElement("Frame", {
                    Size = ScreenUtils.udim2(1, 0, 1, 0),
                    Position = ScreenUtils.udim2(0, 0, 0, 0),
                    BackgroundColor3 = Color3.fromRGB(245, 245, 245), -- Light grey background
                    BorderSizePixel = 0,
                    ZIndex = 4, -- Behind everything
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, 8)
                    }),
                }),
                
                -- Background image for inventory pets section
                BackgroundImage = React.createElement("ImageLabel", {
                    Size = ScreenUtils.udim2(1, 0, 1, 0),
                    Position = ScreenUtils.udim2(0, 0, 0, 0),
                    BackgroundTransparency = 1, -- Transparent so white shows through
                    Image = "rbxassetid://116367512866072",
                    ScaleType = Enum.ScaleType.Tile,
                    TileSize = ScreenUtils.udim2(0, 120, 0, 120), -- Medium paw pattern
                    ImageTransparency = 0.85, -- More transparent for subtle effect
                    ImageColor3 = Color3.fromRGB(200, 200, 200), -- Lighter grey tint
                    ZIndex = 5, -- Above white background
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, 8)
                    }),
                }),
                
                InventoryTitle = React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(1, -10, 0, 30),
                    Position = ScreenUtils.udim2(0.5, 0, 0, 5),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    Text = string.format("Pets %d/%d", #pets, MAX_PET_INVENTORY),
                    TextColor3 = Color3.fromRGB(64, 224, 208), -- Turquoise
                    TextSize = ScreenUtils.TEXT_SIZES.LARGE() + 4, -- Much bigger section title
                    TextStrokeTransparency = 0, -- Black outline
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    ZIndex = 7,
                }),
                
                InventoryGrid = React.createElement("ScrollingFrame", {
                    Size = ScreenUtils.udim2(1, -10, 1, -40),
                    Position = ScreenUtils.udim2(0.5, 0, 0, 35),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 2,
                BorderColor3 = Color3.fromRGB(0, 0, 0), -- Black outline
                    ScrollBarThickness = 8,
                    ScrollBarImageColor3 = Color3.fromRGB(150, 150, 150),
                    CanvasSize = ScreenUtils.udim2(0, 0, 0, math.ceil(#inventoryGroups / 6) * 215 + 30), -- Updated for 6 columns with bigger spacing
                    ZIndex = 7,
                }, {
                    Layout = React.createElement("UIGridLayout", {
                        CellSize = ScreenUtils.udim2(0, 190, 0, 200), -- Even bigger cell size to match card size
                        CellPadding = ScreenUtils.udim2(0, 15, 0, 15), -- More spacing
                        StartCorner = Enum.StartCorner.TopLeft,
                        FillDirectionMaxCells = 6, -- Reduced to 6 columns per row for bigger cards
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Top
                    }),
                    
                    Padding = React.createElement("UIPadding", {
                        PaddingLeft = ScreenUtils.udim(0, 5),
                        PaddingRight = ScreenUtils.udim(0, 5),
                        PaddingTop = ScreenUtils.udim(0, 5),
                        PaddingBottom = ScreenUtils.udim(0, 5)
                    })
                }, #inventoryGroups > 0 and React.createElement(React.Fragment, nil, (function()
                    -- Create a lookup table for equipped pets
                    local equippedLookup = {}
                    for _, equippedGroup in ipairs(equippedGroups) do
                        -- Create a key from name and variation to identify unique pets
                        local key = equippedGroup.Name .. "_" .. equippedGroup.Variation
                        equippedLookup[key] = true
                    end
                    
                    local inventoryElements = {}
                    for i, petGroup in ipairs(inventoryGroups) do
                        -- Check if this pet is equipped
                        local petKey = petGroup.Name .. "_" .. petGroup.Variation
                        local isEquipped = equippedLookup[petKey] == true
                        
                        inventoryElements["InventoryPet_" .. i] = createPetCard(petGroup, i, isEquipped, false) -- false for inEquippedSection
                    end
                    return inventoryElements
                end)()) or nil)
            }) or nil,
            
            -- OP Pets static text (shown under OP pets section when OP tab is selected)
            OPStaticText = equippedTab == "OP" and React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(0.8, 0, 0, 80),
                Position = ScreenUtils.udim2(0.5, 0, 0, 445), -- Below the equipped section
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundTransparency = 1,
                Text = "OP (Robux) Pets do not occupy equipped pets slots!\nThey provide boosts without taking regular pet slots!",
                TextColor3 = Color3.fromRGB(255, 255, 255), -- White base for rainbow gradient
                TextSize = ScreenUtils.TEXT_SIZES.LARGE() * 1.3, -- Even bigger text
                Font = Enum.Font.FredokaOne, -- Bold for emphasis
                TextXAlignment = Enum.TextXAlignment.Center,
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                ZIndex = 8,
            }, {
                -- Rainbow gradient overlay
                RainbowGradient = GradientUtils.CreateReactGradient(GradientUtils.RAINBOW_CYAN)
            }) or nil
        }),
        
        -- Tooltip (rendered on top)
        Tooltip = createTooltip()
    })
end


return PetInventoryUI