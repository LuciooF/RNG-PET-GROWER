-- Pet Index UI - EXACTLY like Pets UI but for collection tracking
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.react)
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local DataSyncService = require(script.Parent.Parent.services.DataSyncService)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)
local AnimationService = require(script.Parent.Parent.services.AnimationService)

-- Load the current PetConfig and PetConstants
local PetConfig = require(ReplicatedStorage.config.PetConfig)
local PetConstants = require(ReplicatedStorage.constants.PetConstants)

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

local function createPetModelForIndex(petName)
    local petsFolder = ReplicatedStorage:FindFirstChild("Pets")
    
    if petsFolder then
        local petModelTemplate = petsFolder:FindFirstChild(petName)
        if not petModelTemplate then
            petModelTemplate = petsFolder:GetChildren()[1]
        end
        
        if petModelTemplate then
            local clonedModel = petModelTemplate:Clone()
            clonedModel.Name = "PetModel"
            
            local scaleFactor = 4.2
            
            for _, descendant in pairs(clonedModel:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    descendant.Size = descendant.Size * scaleFactor
                    descendant.CanCollide = false
                    descendant.Anchored = true
                    descendant.Massless = true
                    descendant.Transparency = math.max(0, descendant.Transparency - 0.3)
                    if descendant.Material == Enum.Material.ForceField then
                        descendant.Material = Enum.Material.Plastic
                    end
                end
            end
            
            local rotationAngle = 160
            clonedModel:MoveTo(Vector3.new(0, 0, 0))
            
            for _, descendant in pairs(clonedModel:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    local rotationCFrame = CFrame.Angles(0, math.rad(rotationAngle), 0)
                    local currentPos = descendant.Position
                    local rotatedPos = rotationCFrame * currentPos
                    descendant.Position = rotatedPos
                    descendant.CFrame = CFrame.new(rotatedPos) * rotationCFrame * (descendant.CFrame - descendant.Position)
                end
            end
            
            return clonedModel
        end
    end
    
    return nil
end

local function setupPetViewportCamera(viewportFrame, petModel)
    if not viewportFrame or not petModel then
        return
    end
    
    local camera = Instance.new("Camera")
    camera.CameraType = Enum.CameraType.Scriptable
    camera.Parent = viewportFrame
    viewportFrame.CurrentCamera = camera
    
    local modelCFrame, modelSize = petModel:GetBoundingBox()
    local maxSize = math.max(modelSize.X, modelSize.Y, modelSize.Z)
    
    local distance = maxSize * 1.8
    local cameraPosition = modelCFrame.Position + Vector3.new(distance * 0.7, distance * 0.4, distance * 0.7)
    
    camera.CFrame = CFrame.lookAt(cameraPosition, modelCFrame.Position)
end

local function PetIndexUI(props)
    local visible = props and props.visible or false
    local setVisible = props and props.setVisible or function() end
    local hoveredPet, setHoveredPet = React.useState(nil)
    local pinnedTooltip, setPinnedTooltip = React.useState(nil)
    local playerData, setPlayerData = React.useState(nil)
    local selectedLevel, setSelectedLevel = React.useState(1)
    
    -- Animation state for bouncing text
    local bounceOffset, setBounceOffset = React.useState(0)
    local activeAnimations = React.useRef({})
    
    -- Subscribe to player data changes
    React.useEffect(function()
        local unsubscribe = DataSyncService:Subscribe(function(newState)
            if newState and newState.player then
                setPlayerData(newState.player)
            end
        end)
        
        return unsubscribe
    end, {})
    
    -- Setup bounce animation using AnimationService
    React.useEffect(function()
        if visible then
            local bounceAnimation = AnimationService:CreateReactBounceAnimation({
                duration = 0.8, -- 0.8 seconds like original
                upOffset = 10, -- 10 pixels up like original
                downOffset = 10, -- 10 pixels down like original  
                pauseBetween = 0.5 -- 0.5 second pause like original
            }, {
                onPositionChange = setBounceOffset
            })
            activeAnimations.current.bounce = bounceAnimation
            
            return function()
                if bounceAnimation then
                    bounceAnimation:Stop()
                end
                activeAnimations.current = {}
            end
        end
    end, {visible})
    
    -- Keyboard shortcut (I key)
    React.useEffect(function()
        local connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            if input.KeyCode == Enum.KeyCode.I then
                setVisible(function(prev) return not prev end)
            end
        end)
        
        return function()
            connection:Disconnect()
        end
    end, {})
    
    -- Tooltip position state
    local tooltipPosition, setTooltipPosition = React.useState(UDim2.new(0, 0, 0, 0))
    
    if not visible then
        return nil
    end
    
    -- Get all possible pets from selected level
    local allPets = PetConfig.getPetsByLevel(selectedLevel)
    
    -- Get collected pets data from player data
    local collectedData = {}
    local ownedPetNames = {}
    
    -- Build collection data from collected pets (permanent collection tracking)
    if playerData and playerData.CollectedPets then
        for collectionKey, collectionInfo in pairs(playerData.CollectedPets) do
            local petName = collectionInfo.petName
            local variationName = collectionInfo.variationName
            local count = collectionInfo.count or 1
            
            if petName then
                if not collectedData[petName] then
                    collectedData[petName] = {
                        variations = {},
                        totalCollected = 0,
                        rarestVariation = nil
                    }
                end
                
                -- Track variations
                if variationName then
                    collectedData[petName].variations[variationName] = true
                    -- Update rarest variation (prioritize rarer variations)
                    if not collectedData[petName].rarestVariation or 
                       PetConstants.getVariationMultiplier(variationName) > PetConstants.getVariationMultiplier(collectedData[petName].rarestVariation) then
                        collectedData[petName].rarestVariation = variationName
                    end
                end
                
                collectedData[petName].totalCollected = collectedData[petName].totalCollected + count
                ownedPetNames[petName] = true
            end
        end
    end
    
    -- Create pet cards EXACTLY like Pets UI
    local function createPetCard(petConfig, cardIndex)
        if not petConfig or not petConfig.Name then
            return nil
        end
        
        local petName = petConfig.Name
        local petRarity = petConfig.Rarity
        local isCollected = collectedData[petName] ~= nil
        local rarestVariation = isCollected and collectedData[petName].rarestVariation or "Bronze"
        local variationColor = isCollected and PetConstants.getVariationColor(rarestVariation) or Color3.fromRGB(150, 150, 150)
        
        
        return React.createElement("TextButton", {
            Size = ScreenUtils.udim2(0, 190, 0, 190), -- Same size as updated Pet Inventory cards
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "", -- Empty text for TextButton
            AutoButtonColor = false, -- Disable button color changes
            LayoutOrder = cardIndex,
            ZIndex = 110,
            
            [React.Event.MouseEnter] = function(rbx)
                playHoverSound() -- Play hover sound
                if not pinnedTooltip or pinnedTooltip.name ~= petName then
                    setHoveredPet({name = petName, index = cardIndex, level = selectedLevel}) -- Include level in hover state
                    -- Calculate tooltip position with error handling
                    local success, _ = pcall(function()
                        if rbx and rbx.Parent and rbx.AbsolutePosition and rbx.AbsoluteSize then
                            local absPos = rbx.AbsolutePosition
                            local absSize = rbx.AbsoluteSize
                            local responsiveOffset = ScreenUtils.getScaleFactor() * 15
                            setTooltipPosition(UDim2.new(0, absPos.X + absSize.X + responsiveOffset, 0, absPos.Y))
                        end
                    end)
                    
                    if not success then
                        -- Fallback: try again after a brief delay
                        task.spawn(function()
                            task.wait(0.1)
                            pcall(function()
                                if rbx and rbx.Parent and rbx.AbsolutePosition and rbx.AbsoluteSize then
                                    local absPos = rbx.AbsolutePosition
                                    local absSize = rbx.AbsoluteSize
                                    local responsiveOffset = ScreenUtils.getScaleFactor() * 15
                                    setTooltipPosition(UDim2.new(0, absPos.X + absSize.X + responsiveOffset, 0, absPos.Y))
                                end
                            end)
                        end)
                    end
                end
            end,
            
            [React.Event.MouseLeave] = function()
                if not pinnedTooltip then
                    -- Store reference to current pet for delayed clearing
                    local currentPetData = {name = petName, index = cardIndex, level = selectedLevel}
                    task.spawn(function()
                        task.wait(0.05) -- Very short delay (50ms)
                        if not pinnedTooltip then -- Check again after delay
                            -- Only clear if we're still on the same pet (haven't moved to another card)
                            setHoveredPet(function(currentHoveredPet)
                                if currentHoveredPet and currentHoveredPet.name == currentPetData.name and 
                                   currentHoveredPet.index == currentPetData.index then
                                    return nil -- Clear only if still the same pet
                                else
                                    return currentHoveredPet -- Keep current hovered pet
                                end
                            end)
                        end
                    end)
                end
            end,
            
            [React.Event.MouseButton1Click] = function(rbx)
                -- Pin tooltip on click
                setPinnedTooltip({name = petName, index = cardIndex, level = selectedLevel}) -- Include level in pinned state
                setHoveredPet({name = petName, index = cardIndex, level = selectedLevel}) -- Include level in hover state
                -- Calculate tooltip position
                if rbx and rbx.Parent then
                    local success, _ = pcall(function()
                        local absPos = rbx.AbsolutePosition
                        local absSize = rbx.AbsoluteSize
                        local responsiveOffset = ScreenUtils.getScaleFactor() * 15
                        setTooltipPosition(UDim2.new(0, absPos.X + absSize.X + responsiveOffset, 0, absPos.Y))
                    end)
                end
            end,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, 80) -- Same as Pet Inventory cards (half of 160)
            }),
            
            -- Pet name at the bottom (same position as Pet Inventory)
            PetName = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, -10, 0, 25),
                Position = ScreenUtils.udim2(0, 5, 1, -25), -- Bottom of card like Pet Inventory
                BackgroundTransparency = 1,
                Text = isCollected and petName or "???",
                TextColor3 = isCollected and PetConstants.getRarityColor(petRarity) or Color3.fromRGB(255, 100, 100),
                TextSize = ScreenUtils.TEXT_SIZES.LARGE() * 0.85, -- Same size as Pet Inventory
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextScaled = true,
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                ZIndex = 112,
            }),
            
            -- Rarity chance text (1 in xxx format) - above pet name like Pet Inventory boost text
            RarityChanceText = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, -10, 0, 25),
                Position = ScreenUtils.udim2(0, 5, 1, -55), -- Above pet name like boost text in Pet Inventory
                BackgroundTransparency = 1,
                Text = "1 in " .. (PetConstants.getRarityChance and NumberFormatter.format(PetConstants.getRarityChance(petRarity)) or "???"),
                TextColor3 = Color3.fromRGB(255, 255, 255), -- White base for gradient
                TextSize = ScreenUtils.TEXT_SIZES.LARGE(), -- Same size as boost text in Pet Inventory
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                ZIndex = 112,
            }, {
                -- Rainbow gradient for all pets (collected and locked)
                RainbowGradient = React.createElement("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),     -- Red
                        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 165, 0)), -- Orange
                        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)), -- Yellow
                        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),   -- Green
                        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),  -- Blue
                        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)), -- Indigo
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 0, 211))    -- Violet
                    }),
                    Rotation = 0 -- Horizontal gradient
                })
            }),
            
            SquiggleBackground = React.createElement("ImageLabel", {
                Size = ScreenUtils.udim2(0.9, 0, 0.9, 0), -- Same relative size as Pet Inventory
                Position = ScreenUtils.udim2(0.5, 0, 0.5, 0), -- Centered in card
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1, -- Transparent background
                Image = IconAssets.getIcon("UI", "SQUIGGLE"),
                ImageColor3 = isCollected and variationColor or Color3.fromRGB(50, 50, 50), -- Black for locked pets
                ImageTransparency = 0.3, -- Same as Pet Inventory UI
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 109, -- Behind viewport
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 72)
                }),
            }),
            
            PetViewport = React.createElement("ViewportFrame", {
                Size = ScreenUtils.udim2(1, -10, 1, -25), -- Same size as Pet Inventory viewport
                Position = ScreenUtils.udim2(0, 5, 0, 5), -- Same position as Pet Inventory
                BackgroundTransparency = 1, -- Transparent viewport
                ZIndex = 111, -- Above squiggle background
                key = "viewport_" .. selectedLevel .. "_" .. petName, -- Force recreation when level changes
                
                [React.Event.AncestryChanged] = function(rbx)
                    if rbx.Parent then
                        task.spawn(function()
                            task.wait(0.1)
                            
                            local petModel = createPetModelForIndex(petName)
                            if petModel then
                                petModel.Parent = rbx
                                
                                -- If not collected, make it black/locked
                                if not isCollected then
                                    for _, descendant in pairs(petModel:GetDescendants()) do
                                        if descendant:IsA("BasePart") then
                                            descendant.Color = Color3.fromRGB(20, 20, 20) -- Very dark
                                            descendant.Material = Enum.Material.Plastic
                                        end
                                    end
                                end
                                
                                setupPetViewportCamera(rbx, petModel)
                            end
                        end)
                    end
                end,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 60) -- Same as Pet Inventory viewport
                }),
            }),
            
            -- Collection status badge (top right corner like Pet Inventory quantity badge)
            CollectionBadge = React.createElement("Frame", {
                Size = ScreenUtils.udim2(0, 70, 0, 35), -- Same size as Pet Inventory quantity badge
                Position = ScreenUtils.udim2(1, -75, 0, 5), -- Top right corner
                BackgroundColor3 = isCollected and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 50, 50), -- Green if collected, red if not
                BackgroundTransparency = 0,
                BorderSizePixel = 3,
                BorderColor3 = Color3.fromRGB(0, 0, 0), -- Same border as Pet Inventory
                ZIndex = 112, -- Above viewport
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 6)
                }),
                
                StatusText = React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = isCollected and (function()
                        local count = 0
                        for _ in pairs(collectedData[petName].variations or {}) do
                            count = count + 1
                        end
                        return tostring(count) .. "/15"
                    end)() or "???",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() * 1.2, -- Same size as Pet Inventory quantity text
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextStrokeTransparency = 0, -- Add text outline
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 113,
                })
            }),
        })
    end
    
    -- Create tooltip
    local function createTooltip()
        local displayPet = pinnedTooltip or hoveredPet
        if not displayPet then 
            return nil 
        end
        
        -- Get pets from the level that was active when hovered (not current selected level)
        local petLevel = displayPet.level or selectedLevel
        local levelPets = PetConfig.getPetsByLevel(petLevel)
        
        local petConfig = nil
        for i, pet in ipairs(levelPets) do
            if pet.Name == displayPet.name then
                petConfig = pet
                break
            end
        end
        if not petConfig then 
            return nil 
        end
        
        local isCollected = collectedData[displayPet.name] ~= nil
        local rarityColor = PetConstants.getRarityColor(petConfig.Rarity) or Color3.fromRGB(100, 100, 100)
        local collectionInfo = collectedData[displayPet.name]
        
        -- Get all possible variations from PetConstants
        local allVariations = PetConstants.getAllVariations and PetConstants.getAllVariations() or {"Bronze", "Silver", "Gold", "Rainbow", "Diamond", "Emerald", "Ruby", "Sapphire", "Amethyst", "Topaz", "Opal", "Onyx", "Pearl", "Obsidian", "Crystal"}
        
        -- Create variation list
        local variationElements = {}
        if isCollected then
            for i, variation in ipairs(allVariations) do
                local hasVariation = collectionInfo.variations and collectionInfo.variations[variation] or false
                local variationColor = PetConstants.getVariationColor(variation) or Color3.fromRGB(150, 150, 150)
                
                variationElements[i] = React.createElement("Frame", {
                    Size = ScreenUtils.udim2(1, -10, 0, 30),
                    BackgroundColor3 = hasVariation and variationColor or Color3.fromRGB(245, 245, 245),
                    BackgroundTransparency = hasVariation and 0.3 or 0.1,
                    BorderSizePixel = 0,
                    LayoutOrder = i,
                    ZIndex = 1001,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, 6)
                    }),
                    
                    Outline = React.createElement("UIStroke", {
                        Color = hasVariation and variationColor or Color3.fromRGB(200, 200, 200),
                        Thickness = hasVariation and 2 or 1,
                        Transparency = 0.2,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    }),
                    
                    -- Status icon (checkmark or X using assets)
                    StatusIcon = React.createElement("ImageLabel", {
                        Size = UDim2.new(0, 20, 0, 20),
                        Position = UDim2.new(0, 7, 0.5, -10), -- Centered vertically
                        BackgroundTransparency = 1,
                        Image = hasVariation and "rbxassetid://136874710855721" or IconAssets.getIcon("UI", "X_BUTTON"), -- Tick or X icon
                        ImageColor3 = hasVariation and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(200, 50, 50),
                        ScaleType = Enum.ScaleType.Fit,
                        ZIndex = 1002,
                    }),
                    
                    -- Variation name
                    VariationName = React.createElement("TextLabel", {
                        Size = UDim2.new(0, 180, 1, 0),
                        Position = UDim2.new(0, 35, 0, 0),
                        BackgroundTransparency = 1,
                        Text = variation,
                        TextColor3 = hasVariation and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(120, 120, 120),
                        TextSize = ScreenUtils.TEXT_SIZES.SMALL() + 1,
                        Font = hasVariation and Enum.Font.FredokaOne or Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Center, -- Center the text
                        TextYAlignment = Enum.TextYAlignment.Center,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        ZIndex = 1002,
                    }),
                    
                    -- Rarity chance (bigger text)
                    RarityChance = React.createElement("TextLabel", {
                        Size = UDim2.new(0, 90, 1, 0),
                        Position = UDim2.new(1, -95, 0, 0),
                        BackgroundTransparency = 1,
                        Text = "1 in " .. (function()
                            -- Use UI display rarity for consistent display
                            if PetConfig.getUIDisplayRarity then
                                local rarity = PetConfig.getUIDisplayRarity(petConfig.Name, variation, level)
                                if type(rarity) == "number" then
                                    return NumberFormatter.format(rarity)
                                else
                                    return rarity  -- "Unknown"
                                end
                            elseif PetConfig.getActualPetRarity then
                                -- Fallback to actual rarity if new function doesn't exist
                                local rarity = PetConfig.getActualPetRarity(petConfig.Name, variation, level, nil)
                                if type(rarity) == "number" then
                                    return NumberFormatter.format(rarity)
                                else
                                    return rarity  -- "Unknown"
                                end
                            else
                                return "???"
                            end
                        end)(),
                        TextColor3 = Color3.fromRGB(60, 60, 60),
                        TextSize = ScreenUtils.TEXT_SIZES.SMALL() + 5, -- Even bigger text
                        Font = Enum.Font.FredokaOne, -- Bold for emphasis
                        TextXAlignment = Enum.TextXAlignment.Right,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        ZIndex = 1002,
                    }),
                })
            end
        end
        
        return React.createElement("Frame", {
            Size = ScreenUtils.udim2(0, 450, 0, math.min(600, #allVariations * 35 + 150)), -- Dynamic height, no scrolling needed
            Position = tooltipPosition,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 1000,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, 12)
            }),
            
            Outline = React.createElement("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 3,
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }),
            
            BackgroundPattern = React.createElement("ImageLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Image = "rbxassetid://116367512866072",
                ScaleType = Enum.ScaleType.Tile,
                TileSize = UDim2.new(0, 50, 0, 50),
                ImageTransparency = 0.95,
                ImageColor3 = Color3.fromRGB(200, 200, 200),
                ZIndex = 1000,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 12)
                }),
            }),
            
            PetName = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, -20, 0, 35),
                Position = ScreenUtils.udim2(0, 10, 0, 10),
                BackgroundTransparency = 1,
                Text = isCollected and displayPet.name or "????",
                TextColor3 = Color3.fromRGB(40, 40, 40),
                TextSize = ScreenUtils.TEXT_SIZES.LARGE() + 3,
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(255, 255, 255),
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 1001,
            }),
            
            RarityInfo = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, -20, 0, 25),
                Position = ScreenUtils.udim2(0, 10, 0, 50),
                BackgroundTransparency = 1,
                Text = "Rarity: " .. (isCollected and petConfig.Rarity or "????"),
                TextColor3 = rarityColor,
                TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() + 1,
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(255, 255, 255),
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 1001,
            }),
            
            VariationsTitle = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, -20, 0, 25),
                Position = ScreenUtils.udim2(0, 10, 0, 85),
                BackgroundTransparency = 1,
                Text = isCollected and "Collected Variations:" or "Variations: Locked",
                TextColor3 = Color3.fromRGB(80, 80, 80),
                TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(255, 255, 255),
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 1001,
            }),
            
            VariationsContainer = isCollected and React.createElement("Frame", {
                Size = ScreenUtils.udim2(1, -20, 1, -130),
                Position = ScreenUtils.udim2(0, 10, 0, 115),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 1001,
            }, {
                -- Use UIListLayout for proper vertical stacking (no scrolling)
                ListLayout = React.createElement("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = ScreenUtils.udim(0, 3), -- Small padding between rows
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Top,
                })
            }, variationElements) or nil,
        })
    end
    
    -- Level tabs (keeping the good ones)
    local levelTabs = {}
    local availableLevels = {}
    for level = 1, 7 do
        local levelPets = PetConfig.getPetsByLevel(level)
        if #levelPets > 0 then
            table.insert(availableLevels, level)
        end
    end
    
    local levelColors = {
        Color3.fromRGB(100, 200, 255),
        Color3.fromRGB(100, 255, 150),
        Color3.fromRGB(255, 200, 100),
        Color3.fromRGB(255, 150, 200),
        Color3.fromRGB(200, 150, 255),
        Color3.fromRGB(255, 255, 150),
        Color3.fromRGB(255, 100, 100)
    }
    
    for i, level in ipairs(availableLevels) do
        local isSelected = selectedLevel == level
        local levelColor = levelColors[level] or Color3.fromRGB(150, 150, 255)
        
        levelTabs[i] = React.createElement("TextButton", {
            Name = "LevelTab_" .. level,
            Size = ScreenUtils.udim2(0, 160, 0, 55), -- Bigger tabs for better visibility
            BackgroundColor3 = isSelected and levelColor or Color3.fromRGB(248, 248, 248),
            BorderSizePixel = 0,
            Text = "",
            ZIndex = 103,
            LayoutOrder = i,
            [React.Event.Activated] = function()
                setSelectedLevel(level)
                setHoveredPet(nil)
            end
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, 20),
            }),
            
            Outline = React.createElement("UIStroke", {
                Thickness = isSelected and 3 or 1,
                Color = isSelected and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(200, 200, 200),
                Transparency = isSelected and 0 or 0.5,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }),
            
            LevelLabel = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "Level " .. level,
                TextColor3 = isSelected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(60, 60, 60),
                TextSize = ScreenUtils.TEXT_SIZES.LARGE() + 2, -- Bigger text for better readability
                TextStrokeTransparency = 0,
                TextStrokeColor3 = isSelected and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255),
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 104,
            }),
        })
    end
    
    -- Sort pets by rarity (rarest first) using rarity ordering
    local rarityOrder = {
        ["Omniscient"] = 1,     -- 1 in 1M (rarest)
        ["Infinite"] = 2,       -- 1 in 100k
        ["Cosmic"] = 3,         -- 1 in 50k
        ["Primordial"] = 4,     -- 1 in 25k
        ["Ethereal"] = 5,       -- 1 in 10k
        ["Omnipotent"] = 6,     -- 1 in 5k
        ["Transcendent"] = 7,   -- 1 in 2.5k
        ["Celestial"] = 8,      -- 1 in 1k
        ["Ancient"] = 9,        -- 1 in 500
        ["Mythic"] = 10,        -- 1 in 250
        ["Legendary"] = 11,     -- 1 in 100
        ["Epic"] = 12,          -- 1 in 50
        ["Rare"] = 13,          -- 1 in 25
        ["Uncommon"] = 14,      -- 1 in 10
        ["Common"] = 15         -- 1 in 5 (most common)
    }
    
    table.sort(allPets, function(a, b)
        local aOrder = rarityOrder[a.Rarity] or 99
        local bOrder = rarityOrder[b.Rarity] or 99
        return aOrder > bOrder -- Common first (higher number = more common)
    end)
    
    -- Create pet cards
    local petCards = {}
    for i, petConfig in ipairs(allPets) do
        local card = createPetCard(petConfig, i)
        petCards[i] = card
    end
    
    -- Main UI (EXACT structure as Pets UI)
    return React.createElement("TextButton", {
        Name = "PetIndexOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 100,
        [React.Event.MouseButton1Click] = function()
            -- Close pinned tooltip and UI
            setPinnedTooltip(nil)
            setHoveredPet(nil)
            setVisible(false)
        end,
    }, {
        PetIndexModal = React.createElement("Frame", {
            Name = "PetIndexModal",
            Size = ScreenUtils.udim2(0.6, 0, 0.75, 0), -- Same size as Pet Inventory UI
            Position = ScreenUtils.udim2(0.5, 0, 0.5, 0), -- Centered
            AnchorPoint = Vector2.new(0.5, 0.5), -- Center anchor point
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0,
            ZIndex = 101,
        }, {
            ClickBlocker = React.createElement("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 101,
                [React.Event.MouseButton1Click] = function()
                    -- Close pinned tooltip when clicking inside modal but not on pet
                    setPinnedTooltip(nil)
                    setHoveredPet(nil)
                end,
            }),
            
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, 15),
            }),
            
            ModalOutline = React.createElement("UIStroke", {
                Thickness = 4,
                Color = Color3.fromRGB(0, 0, 0),
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }),
            
            BackgroundPattern = React.createElement("ImageLabel", {
                Name = "BackgroundPattern",
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                Image = "rbxassetid://116367512866072",
                ScaleType = Enum.ScaleType.Tile,
                TileSize = ScreenUtils.udim2(0, 120, 0, 120),
                ImageTransparency = 0.85,
                ImageColor3 = Color3.fromRGB(200, 200, 200),
                ZIndex = 101,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 15),
                }),
            }),
            
            Header = React.createElement("Frame", {
                Size = ScreenUtils.udim2(1, 0, 0, 50),
                BackgroundColor3 = Color3.fromRGB(255, 140, 0),
                BorderSizePixel = 0,
                ZIndex = 102,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 12)
                }),
                
                Gradient = React.createElement("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 165, 0)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 140, 0))
                    }),
                    Rotation = 90,
                }),
                
                Outline = React.createElement("UIStroke", {
                    Thickness = 3,
                    Color = Color3.fromRGB(0, 0, 0),
                    Transparency = 0,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                }),
                
                IndexIcon = React.createElement("ImageLabel", {
                    Size = ScreenUtils.udim2(0, 35, 0, 35),
                    Position = ScreenUtils.udim2(0.5, -85, 0.5, -17.5),
                    BackgroundTransparency = 1,
                    Image = IconAssets.getIcon("UI", "INDEX"),
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 103,
                }),
                
                Title = React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(0, 140, 1, 0),
                    Position = ScreenUtils.udim2(0.5, -40, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "Pet Index",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.TEXT_SIZES.LARGE() + 4,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    ZIndex = 103,
                }),
                
                CloseButton = React.createElement("ImageButton", {
                    Size = ScreenUtils.udim2(0, 50, 0, 50), -- Bigger close button
                    Position = ScreenUtils.udim2(1, -55, 0.5, -25),
                    BackgroundColor3 = Color3.fromRGB(255, 100, 100),
                    Image = IconAssets.getIcon("UI", "X_BUTTON"),
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 103,
                    [React.Event.MouseButton1Click] = function()
                        setVisible(false)
                    end,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, 8),
                    }),
                    Outline = React.createElement("UIStroke", {
                        Thickness = 2,
                        Color = Color3.fromRGB(0, 0, 0),
                        Transparency = 0,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    }),
                }),
            }),
            
            LevelTabsContainer = React.createElement("Frame", {
                Size = ScreenUtils.udim2(1, -40, 0, 50),
                Position = ScreenUtils.udim2(0, 20, 0, 60),
                BackgroundTransparency = 1,
                ZIndex = 102,
            }, {
                TabLayout = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = ScreenUtils.udim(0, 8),
                    SortOrder = Enum.SortOrder.Name,
                }),
                
                TabsContainer = React.createElement(React.Fragment, nil, levelTabs)
            }),
            
            -- EXACT grid structure as Pets UI
            PetGridContainer = React.createElement("Frame", {
                Size = ScreenUtils.udim2(1, -40, 1, -170), -- Leave space for bouncing text
                Position = ScreenUtils.udim2(0, 20, 0, 125),
                BackgroundTransparency = 1,
                ZIndex = 108,
            }, {
                PetScrollFrame = React.createElement("ScrollingFrame", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ScrollBarThickness = 8,
                    ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100),
                    CanvasSize = UDim2.new(0, 0, 0, math.ceil(#allPets / 6) * 215 + 30), -- Updated for 6 per row with bigger spacing
                    ZIndex = 109,
                }, {
                    Layout = React.createElement("UIGridLayout", {
                        CellSize = ScreenUtils.udim2(0, 190, 0, 200), -- Same as updated Pet Inventory cards
                        CellPadding = ScreenUtils.udim2(0, 15, 0, 15), -- Same spacing as Pet Inventory
                        StartCorner = Enum.StartCorner.TopLeft,
                        FillDirectionMaxCells = 6, -- Same as updated Pet Inventory: 6 per row for bigger cards
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
                }, petCards)
            }),
            
            -- Rainbow bouncing text at the bottom using AnimationService
            BouncingText = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, -40, 0, 35),
                Position = ScreenUtils.udim2(0, 20, 1, -45 + bounceOffset), -- AnimationService bounce offset
                BackgroundTransparency = 1,
                Text = "Here you can see how rare your pets really are!",
                TextColor3 = Color3.fromRGB(255, 255, 255), -- White base for gradient
                TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() + 2,
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                ZIndex = 105,
            }, {
                -- Rainbow gradient for bottom text
                RainbowGradient = React.createElement("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),     -- Red
                        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 165, 0)), -- Orange
                        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)), -- Yellow
                        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),   -- Green
                        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),  -- Blue
                        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)), -- Indigo
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 0, 211))    -- Violet
                    }),
                    Rotation = 0 -- Horizontal gradient
                }) -- Animation now handled by AnimationService
            })
        }),
        
        Tooltip = createTooltip()
    })
end

return PetIndexUI