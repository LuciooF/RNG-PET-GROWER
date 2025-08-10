-- PetMixerUI - UI for mixing pets with timer display
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local React = require(ReplicatedStorage.Packages.react)
local DataSyncService = require(script.Parent.Parent.services.DataSyncService)
local PetMixerConfig = require(ReplicatedStorage.config.PetMixerConfig)
local PetMixerButtonService = require(script.Parent.Parent.services.PetMixerButtonService)
local PetUtils = require(ReplicatedStorage.utils.PetUtils)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local PetConstants = require(ReplicatedStorage.constants.PetConstants)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)

local player = Players.LocalPlayer

local function PetMixerUI()
    local playerData, setPlayerData = React.useState({
        Pets = {},
        Mixers = {}
    })
    local isVisible, setIsVisible = React.useState(false)
    local activeMixerNumber, setActiveMixerNumber = React.useState(1)
    local selectedPets, setSelectedPets = React.useState({})
    local currentTime, setCurrentTime = React.useState(os.time())
    local hoveredPet, setHoveredPet = React.useState(nil)
    local tooltipPosition, setTooltipPosition = React.useState(UDim2.new(0, 0, 0, 0))
    local selectedExclusivePet, setSelectedExclusivePet = React.useState(nil)
    local loadedPetModels, setLoadedPetModels = React.useState({}) -- Track which pet models are loaded
    
    -- Store mouse connections to prevent memory leaks
    local mouseConnections = {}
    
    -- 10 Exclusive mixing-only pets (cool ones from assets that aren't used elsewhere)
    local exclusiveMixingPets = {
        "Witch Dominus",     -- Magical themed
        "Time Traveller Doggy", -- Sci-fi themed
        "Valentines Dragon", -- Holiday themed  
        "Summer Dragon",     -- Seasonal themed
        "Elf Dragon",        -- Fantasy themed
        "Nerdy Dragon",      -- Quirky themed
        "Guard Dragon",      -- Military themed
        "Circus Hat Trick Dragon", -- Entertainment themed
        "Partner Dragon",    -- Social themed
        "Cyborg Dragon"      -- Tech themed
    }
    
    -- Get random exclusive pet for mixing
    local function getRandomExclusivePet()
        local randomIndex = math.random(1, #exclusiveMixingPets)
        return exclusiveMixingPets[randomIndex]
    end
    
    -- Subscribe to data changes
    React.useEffect(function()
        -- Get initial data
        local initialData = DataSyncService:GetPlayerData()
        if initialData then
            setPlayerData(initialData)
        end
        
        local unsubscribe = DataSyncService:Subscribe(function(newState)
            if newState.player then
                setPlayerData(newState.player)
            end
        end)
        
        return unsubscribe
    end, {})
    
    -- Update current time every second for timer display
    React.useEffect(function()
        local connection = game:GetService("RunService").Heartbeat:Connect(function()
            setCurrentTime(os.time())
        end)
        
        return function()
            connection:Disconnect()
        end
    end, {})
    
    -- Cleanup mouse connections on unmount
    React.useEffect(function()
        return function()
            for _, conn in pairs(mouseConnections) do
                if conn then
                    conn:Disconnect()
                end
            end
        end
    end, {})
    
    -- Set up mixer button callbacks
    React.useEffect(function()
        PetMixerButtonService:Initialize()
        
        -- Set callbacks for mixer interaction
        PetMixerButtonService:SetOpenCallback(function(mixerNumber)
            setIsVisible(true)
            setActiveMixerNumber(mixerNumber)
            setSelectedPets({}) -- Clear selection when opening
            setSelectedExclusivePet(nil) -- Clear exclusive pet
            setLoadedPetModels({}) -- Clear loaded models cache when opening
        end)
        
        PetMixerButtonService:SetCloseCallback(function(mixerNumber)
            setIsVisible(false)
        end)
        
        return function()
            PetMixerButtonService:Cleanup()
        end
    end, {})
    
    -- Update exclusive pet when selected pets change
    React.useEffect(function()
        local count = 0
        for _ in pairs(selectedPets) do
            count = count + 1
        end
        
        if count >= PetMixerConfig.MIN_PETS_PER_MIX then
            -- Only set a new exclusive pet if we don't have one
            if not selectedExclusivePet then
                setSelectedExclusivePet(getRandomExclusivePet())
            end
        else
            -- Clear exclusive pet if not enough pets selected
            setSelectedExclusivePet(nil)
        end
    end, {selectedPets})
    
    -- Toggle pet selection
    local function togglePetSelection(petId)
        local newSelection = {}
        for id, _ in pairs(selectedPets) do
            newSelection[id] = true
        end
        
        if newSelection[petId] then
            newSelection[petId] = nil
        else
            -- Check max selection
            local count = 0
            for _ in pairs(newSelection) do
                count = count + 1
            end
            
            if count < PetMixerConfig.MAX_PETS_PER_MIX then
                newSelection[petId] = true
            end
        end
        
        setSelectedPets(newSelection)
    end
    
    -- Start mixing selected pets
    local function startMixing()
        -- Check if mixer is already active
        local hasActiveMixer = false
        for _, mixer in ipairs(playerData.Mixers or {}) do
            if not mixer.claimed then
                hasActiveMixer = true
                break
            end
        end
        
        if hasActiveMixer then
            warn("Cannot start mixing: mixer already active")
            return
        end
        
        local petIds = {}
        for id, _ in pairs(selectedPets) do
            table.insert(petIds, id)
        end
        
        if #petIds < PetMixerConfig.MIN_PETS_PER_MIX then
            return
        end
        
        local startMixingRemote = ReplicatedStorage:FindFirstChild("StartMixing")
        if startMixingRemote then
            startMixingRemote:FireServer(petIds)
            setSelectedPets({}) -- Clear selection after starting
            setSelectedExclusivePet(nil) -- Clear exclusive pet after starting
        end
    end
    
    -- Claim completed mixer
    local function claimMixer(mixerId)
        local claimMixerRemote = ReplicatedStorage:FindFirstChild("ClaimMixer")
        if claimMixerRemote then
            claimMixerRemote:FireServer(mixerId)
        end
    end
    
    -- Cancel active mixer
    local function cancelMixer(mixerId)
        local cancelMixerRemote = ReplicatedStorage:FindFirstChild("CancelMixer")
        if cancelMixerRemote then
            cancelMixerRemote:FireServer(mixerId)
        end
    end
    
    -- Calculate mixing time for selected pets
    local function calculateMixTime()
        local count = 0
        for _ in pairs(selectedPets) do
            count = count + 1
        end
        return PetMixerConfig.calculateMixTime(count)
    end
    
    -- Calculate diamond cost for selected pets
    local function calculateDiamondCost()
        local count = 0
        for _ in pairs(selectedPets) do
            count = count + 1
        end
        return PetMixerConfig.calculateDiamondCost(count)
    end
    
    -- Format time display
    local function formatTime(seconds)
        if seconds <= 0 then return "Ready!" end
        
        local minutes = math.floor(seconds / 60)
        local secs = seconds % 60
        
        if minutes > 0 then
            return string.format("%dm %ds", minutes, secs)
        else
            return string.format("%ds", secs)
        end
    end
    
    -- Calculate preview of mixed pet outcome with exclusive pets
    local function calculateMixPreview()
        local selectedPetsList = {}
        for petId, _ in pairs(selectedPets) do
            for _, pet in ipairs(playerData.Pets or {}) do
                if pet.ID == petId then
                    table.insert(selectedPetsList, pet)
                    break
                end
            end
        end
        
        if #selectedPetsList < PetMixerConfig.MIN_PETS_PER_MIX then
            return nil
        end
        
        -- Calculate preview values
        local previewBoost = PetMixerConfig.calculateMixedPetBoost(selectedPetsList)
        local previewValue = PetMixerConfig.calculateMixedPetValue(selectedPetsList)
        
        -- Use stored exclusive pet or get a new one if none selected
        local petName = selectedExclusivePet or exclusiveMixingPets[1]
        
        return {
            outputName = petName,
            boost = previewBoost,
            value = previewValue,
            petCount = #selectedPetsList
        }
    end
    
    -- Helper function to create pet models for ViewportFrame (copied from Pet UI)
    local function createPetModelForMixer(petData, rotationIndex)
        local petsFolder = ReplicatedStorage:FindFirstChild("Pets")
        
        if petsFolder then
            local modelName = petData.ModelName or petData.Name or "Acid Rain Doggy"
            
            -- Debug logs removed for performance
            
            local petModelTemplate = petsFolder:FindFirstChild(modelName)
            if not petModelTemplate then
                -- Model not found, trying exact pet name match
                
                -- Try exact pet name match first (for mixed pets)
                petModelTemplate = petsFolder:FindFirstChild(petData.Name or "")
                
                if not petModelTemplate then
                    -- Exact name match failed, trying partial match
                    -- Try to find a more appropriate fallback based on pet name
                    for _, model in pairs(petsFolder:GetChildren()) do
                        if model.Name:lower():find((petData.Name or ""):lower()) then
                            petModelTemplate = model
                            -- Found matching model
                            break
                        end
                    end
                end
                
                -- If still no match, use first available
                if not petModelTemplate then
                    petModelTemplate = petsFolder:GetChildren()[1]
                    -- Using fallback model
                else
                    -- Successfully found model
                end
            else
                -- Direct model match found
            end
            
            if petModelTemplate then
                local clonedModel = petModelTemplate:Clone()
                clonedModel.Name = "PetModel"
                
                local scaleFactor = 3.5 -- Same scale as Pet UI
                
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
    
    -- Helper function to setup ViewportFrame camera (copied from Pet UI)
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
        game.Lighting.Ambient = Color3.fromRGB(100, 100, 100)
    end

    -- Create tooltip component (copied from Pet UI)
    local function createTooltip()
        if not hoveredPet then return nil end
        
        local variationColor = PetConstants.getVariationColor(type(hoveredPet.Variation) == "table" and hoveredPet.Variation.VariationName or hoveredPet.Variation)
        local rarityColor = PetConstants.getRarityColor(type(hoveredPet.Rarity) == "table" and hoveredPet.Rarity.RarityName or hoveredPet.Rarity)
        
        -- Calculate final value
        local baseValue = hoveredPet.BaseValue or 100
        local variationMultiplier = PetConstants.getVariationMultiplier(type(hoveredPet.Variation) == "table" and hoveredPet.Variation.VariationName or hoveredPet.Variation)
        local finalValue = math.floor(baseValue * variationMultiplier)
        
        -- Calculate final boost
        local finalBoost = hoveredPet.FinalBoost or hoveredPet.BaseBoost or 1
        
        return React.createElement("Frame", {
            Size = ScreenUtils.udim2(0, 280, 0, 210),
            Position = tooltipPosition,
            BackgroundColor3 = Color3.fromRGB(250, 250, 250),
            BorderSizePixel = 0,
            ZIndex = 1000,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, 12)
            }),
            
            Shadow = React.createElement("UIStroke", {
                Thickness = 3,
                Color = Color3.fromRGB(0, 0, 0),
                Transparency = 0.8,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }),
            
            -- Pet name (title)
            Name = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, -20, 0, 30),
                Position = ScreenUtils.udim2(0, 10, 0, 10),
                BackgroundTransparency = 1,
                Text = hoveredPet.Name,
                TextColor3 = Color3.fromRGB(50, 50, 50),
                TextSize = ScreenUtils.TEXT_SIZES.LARGE(),
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 1001,
            }),
            
            -- Rarity (with color)
            Rarity = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, -20, 0, 25),
                Position = ScreenUtils.udim2(0, 10, 0, 45),
                BackgroundTransparency = 1,
                Text = "Rarity: " .. (type(hoveredPet.Rarity) == "table" and hoveredPet.Rarity.RarityName or hoveredPet.Rarity),
                TextColor3 = rarityColor,
                TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 1001,
            }),
            
            -- Variation (with color)
            Variation = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, -20, 0, 25),
                Position = ScreenUtils.udim2(0, 10, 0, 75),
                BackgroundTransparency = 1,
                Text = "Variation: " .. (type(hoveredPet.Variation) == "table" and hoveredPet.Variation.VariationName or hoveredPet.Variation),
                TextColor3 = variationColor,
                TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 1001,
            }),
            
            -- Value with money icon
            Value = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, -20, 0, 25),
                Position = ScreenUtils.udim2(0, 10, 0, 105),
                BackgroundTransparency = 1,
                Text = "Value: $" .. NumberFormatter.format(finalValue),
                TextColor3 = Color3.fromRGB(85, 170, 85),
                TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 1001,
            }),
            
            -- Boost with icon
            Boost = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, -20, 0, 25),
                Position = ScreenUtils.udim2(0, 10, 0, 135),
                BackgroundTransparency = 1,
                Text = "Boost: x" .. string.format("%.2f", finalBoost),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = ScreenUtils.TEXT_SIZES.LARGE() * 0.85,
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextScaled = true,
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                ZIndex = 1002,
            }, {
                -- Pink to blue gradient like Pet UI
                ShinyGradient = React.createElement("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 20, 147)),   -- Deep Pink
                        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 105, 180)), -- Hot Pink
                        ColorSequenceKeypoint.new(0.6, Color3.fromRGB(138, 43, 226)),  -- Blue Violet
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 144, 255))     -- Dodger Blue
                    }),
                    Rotation = 0
                })
            }),
            
            -- Quantity owned
            Quantity = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, -20, 0, 25),
                Position = ScreenUtils.udim2(0, 10, 0, 165),
                BackgroundTransparency = 1,
                Text = "Owned: " .. (hoveredPet.Quantity or 1),
                TextColor3 = Color3.fromRGB(100, 100, 100),
                TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 1001,
            })
        })
    end
    
    -- Create pet selection card
    local function createPetCard(pet, index)
        local isSelected = selectedPets[pet.ID] == true
        local isEquipped = false
        local isProcessing = false
        
        -- Check if equipped
        for _, equipped in pairs(playerData.EquippedPets or {}) do
            if equipped.ID == pet.ID then
                isEquipped = true
                break
            end
        end
        
        -- Check if processing
        for _, processing in pairs(playerData.ProcessingPets or {}) do
            if processing.ID == pet.ID then
                isProcessing = true
                break
            end
        end
        
        -- Mixed pets can be re-mixed (no additional restrictions)
        local isDisabled = isEquipped or isProcessing
        
        -- Get variation color for background like Pet UI
        local variationColor = PetConstants.getVariationColor(pet.Variation)
        local rarityColor = PetConstants.getRarityColor(pet.Rarity)
        
        -- Calculate final value like Pet UI
        local baseValue = pet.BaseValue or 100
        local variationMultiplier = PetConstants.getVariationMultiplier(pet.Variation)
        local finalValue = math.floor(baseValue * variationMultiplier)
        local finalBoost = pet.FinalBoost or pet.BaseBoost or 1
        
        return React.createElement("Frame", {
            Name = "PetCard" .. index,
            Size = UDim2.new(0, ScreenUtils.getProportionalSize(160), 0, ScreenUtils.getProportionalSize(160)), -- Bigger like Pet UI cards
            BackgroundTransparency = 1, -- Transparent to show colored background
            BorderSizePixel = 0,
            LayoutOrder = index,
            ZIndex = 10,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(80)) -- Circular like Pet UI
            }),
            
            -- Selection outline
            SelectionOutline = isSelected and React.createElement("UIStroke", {
                Thickness = ScreenUtils.getProportionalSize(4),
                Color = Color3.fromRGB(0, 255, 0), -- Green selection outline
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }) or nil,
            
            -- Squiggle background with variation color like Pet UI
            SquiggleBackground = React.createElement("ImageLabel", {
                Size = UDim2.new(0.9, 0, 0.9, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Image = IconAssets.getIcon("UI", "SQUIGGLE"),
                ImageColor3 = variationColor, -- Apply variation color like Pet UI
                ImageTransparency = 0.3,
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 9, -- Behind viewport
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(58)) -- Circular clipping
                }),
            }),
            
            -- Pet model viewport like Pet UI
            PetViewport = React.createElement("ViewportFrame", {
                Size = UDim2.new(1, -ScreenUtils.getProportionalSize(10), 1, -ScreenUtils.getProportionalSize(25)), -- Leave space for name and badges
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(5), 0, ScreenUtils.getProportionalSize(5)),
                BackgroundTransparency = 1, -- Transparent viewport
                ZIndex = 11, -- Above background
                
                -- Load pet model when viewport is created
                [React.Event.AncestryChanged] = function(rbx)
                    if rbx.Parent and not loadedPetModels[pet.ID] then
                        -- Mark as loaded to prevent duplicate loading
                        setLoadedPetModels(function(current)
                            local new = {}
                            for k, v in pairs(current) do
                                new[k] = v
                            end
                            new[pet.ID] = true
                            return new
                        end)
                        
                        -- Stagger model loading to prevent lag
                        task.spawn(function()
                            -- Add random delay based on index to stagger loading
                            task.wait(0.1 + (index * 0.05))
                            
                            local petModel = createPetModelForMixer(pet, index)
                            if petModel and rbx.Parent then
                                petModel.Parent = rbx
                                setupPetViewportCamera(rbx, petModel)
                            end
                        end)
                    end
                end,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(60)) -- Circular viewport
                }),
            }),
            
            -- Pet name label like Pet UI (bigger, rarity colored)
            PetName = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, -10, 0, 25), -- Bigger height like Pet UI
                Position = ScreenUtils.udim2(0, 5, 1, -25), -- Adjust position
                BackgroundTransparency = 1,
                Text = pet.Name or "Unknown",
                TextColor3 = rarityColor, -- Use rarity color like Pet UI
                TextSize = ScreenUtils.TEXT_SIZES.LARGE() * 0.85, -- Bigger text like Pet UI
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextScaled = true, -- Scale text like Pet UI
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                ZIndex = 14,
            }),
            
            -- Boost text overlay like Pet UI (multicolor gradient)
            BoostText = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, -10, 0, 25), -- Bigger height
                Position = ScreenUtils.udim2(0, 5, 1, -55), -- Above pet name
                BackgroundTransparency = 1,
                Text = string.format("x%.2f", finalBoost),
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
                -- Shiny pink to blue gradient overlay like Pet UI
                ShinyGradient = React.createElement("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 20, 147)),   -- Deep Pink
                        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 105, 180)), -- Hot Pink
                        ColorSequenceKeypoint.new(0.6, Color3.fromRGB(138, 43, 226)),  -- Blue Violet
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 144, 255))     -- Dodger Blue
                    }),
                    Rotation = 0 -- Horizontal gradient
                })
            }),
            
            -- Remove badges - we now use text overlay like Pet UI
            
            -- Disabled overlay for equipped/processing pets
            DisabledOverlay = isDisabled and React.createElement("Frame", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 0.6,
                ZIndex = 15,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(80))
                }),
                
                StatusText = React.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(25)),
                    Position = UDim2.new(0, 0, 0.5, -ScreenUtils.getProportionalSize(12.5)),
                    BackgroundColor3 = Color3.fromRGB(255, 100, 100),
                    BackgroundTransparency = 0.2,
                    Text = isEquipped and "EQUIPPED" or "PROCESSING",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 16,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(6))
                    }),
                })
            }) or nil,
            
            -- Hover detection for tooltip and click handling
            HoverDetector = React.createElement("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 15,
                [React.Event.MouseEnter] = function(rbx)
                    setHoveredPet(pet)
                    -- Start tracking mouse position for tooltip
                    if mouseConnections.petCard then
                        mouseConnections.petCard:Disconnect()
                    end
                    
                    mouseConnections.petCard = UserInputService.InputChanged:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseMovement then
                            local mousePos = UserInputService:GetMouseLocation()
                            local responsiveOffset = ScreenUtils.getScaleFactor() * 15
                            setTooltipPosition(UDim2.new(0, mousePos.X + responsiveOffset, 0, mousePos.Y - responsiveOffset))
                        end
                    end)
                end,
                [React.Event.MouseLeave] = function(rbx)
                    setHoveredPet(nil)
                    -- Disconnect mouse tracking
                    if mouseConnections.petCard then
                        mouseConnections.petCard:Disconnect()
                        mouseConnections.petCard = nil
                    end
                end,
                [React.Event.Activated] = function()
                    if not isDisabled then
                        togglePetSelection(pet.ID)
                    end
                end
            })
        })
    end
    
    -- Create mixer display
    local function createMixerDisplay(mixer, index)
        local timeLeft = mixer.completionTime - currentTime
        local isComplete = timeLeft <= 0
        
        return React.createElement("Frame", {
            Name = "Mixer" .. index,
            Size = UDim2.new(1, -20, 0, 100),
            Position = UDim2.new(0, 10, 0, (index - 1) * 110),
            BackgroundColor3 = Color3.fromRGB(60, 60, 60),
            BorderSizePixel = 0
        }, {
            UICorner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0, 8)
            }),
            
            -- Mixer Title
            Title = React.createElement("TextLabel", {
                Size = UDim2.new(0.5, -10, 0, 30),
                Position = UDim2.new(0, 10, 0, 10),
                BackgroundTransparency = 1,
                Font = Enum.Font.FredokaOne,
                Text = "Mixing " .. #mixer.inputPets .. " pets",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Left
            }),
            
            -- Timer/Status
            Timer = React.createElement("TextLabel", {
                Size = UDim2.new(0.5, -10, 0, 30),
                Position = UDim2.new(0.5, 0, 0, 10),
                BackgroundTransparency = 1,
                Font = Enum.Font.FredokaOne,
                Text = formatTime(math.max(0, timeLeft)),
                TextColor3 = isComplete and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 215, 0),
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Right
            }),
            
            -- Output Pet Info
            OutputInfo = React.createElement("TextLabel", {
                Size = UDim2.new(1, -20, 0, 20),
                Position = UDim2.new(0, 10, 0, 40),
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Text = "Output: " .. (mixer.outputPet and mixer.outputPet.Name or "Unknown") .. 
                       " (" .. (mixer.outputPet and mixer.outputPet.Rarity and mixer.outputPet.Rarity.RarityName or "Unknown") .. ")",
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left
            }),
            
            -- Action Buttons
            ClaimButton = isComplete and React.createElement("TextButton", {
                Size = UDim2.new(0, 80, 0, 25),
                Position = UDim2.new(1, -90, 1, -35),
                BackgroundColor3 = Color3.fromRGB(0, 255, 0),
                BorderSizePixel = 0,
                Font = Enum.Font.FredokaOne,
                Text = "Claim",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 14,
                [React.Event.Activated] = function()
                    claimMixer(mixer.id)
                end
            }, {
                UICorner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 4)
                })
            }) or nil,
            
            CancelButton = not isComplete and React.createElement("TextButton", {
                Size = UDim2.new(0, 80, 0, 25),
                Position = UDim2.new(1, -90, 1, -35),
                BackgroundColor3 = Color3.fromRGB(255, 100, 100),
                BorderSizePixel = 0,
                Font = Enum.Font.FredokaOne,
                Text = "Cancel",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 14,
                [React.Event.Activated] = function()
                    cancelMixer(mixer.id)
                end
            }, {
                UICorner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 4)
                })
            }) or nil
        })
    end
    
    -- Create pet grid with proper filtering for equipped pets
    local petCards = {}
    local availablePets = {}
    
    -- Group pets by name and filter out equipped ones and OP pets
    local petGroups = {}
    for _, pet in ipairs(playerData.Pets or {}) do
        -- Skip OP pets (they can't be mixed)
        local isOPPet = false
        if pet.Rarity then
            local rarityName = pet.Rarity
            if type(pet.Rarity) == "table" then
                rarityName = pet.Rarity.RarityName
            end
            isOPPet = (rarityName == "OP")
        end
        
        if not isOPPet then
            local petName = pet.Name
            if not petGroups[petName] then
                petGroups[petName] = { total = 0, equipped = 0, pets = {} }
            end
            petGroups[petName].total = petGroups[petName].total + 1
            table.insert(petGroups[petName].pets, pet)
            
            -- Check if this specific pet is equipped
            for _, equipped in pairs(playerData.EquippedPets or {}) do
                if equipped.ID == pet.ID then
                    petGroups[petName].equipped = petGroups[petName].equipped + 1
                    break
                end
            end
        end
    end
    
    -- Add available pets (not equipped) to the list
    for petName, group in pairs(petGroups) do
        local availableCount = group.total - group.equipped
        if availableCount > 0 then
            -- Add non-equipped pets from this group
            local addedCount = 0
            for _, pet in ipairs(group.pets) do
                if addedCount < availableCount then
                    local isEquipped = false
                    for _, equipped in pairs(playerData.EquippedPets or {}) do
                        if equipped.ID == pet.ID then
                            isEquipped = true
                            break
                        end
                    end
                    
                    if not isEquipped then
                        table.insert(availablePets, pet)
                        addedCount = addedCount + 1
                    end
                end
            end
        end
    end
    
    -- Create cards for available pets
    for i, pet in ipairs(availablePets) do
        petCards["Pet" .. i] = createPetCard(pet, i)
    end
    
    -- Create mixer displays
    local mixerDisplays = {}
    for i, mixer in ipairs(playerData.Mixers or {}) do
        if not mixer.claimed then
            mixerDisplays["Mixer" .. i] = createMixerDisplay(mixer, i)
        end
    end
    
    -- Get mix preview
    local mixPreview = calculateMixPreview()
    
    -- Check if any mixer is currently active for this player
    local activeMixer = nil
    for _, mixer in ipairs(playerData.Mixers or {}) do
        if not mixer.claimed then
            activeMixer = mixer
            break
        end
    end
    
    -- Calculate mixing progress
    local mixingProgress = 0
    local timeRemaining = 0
    local isCompleted = false
    
    if activeMixer then
        timeRemaining = math.max(0, activeMixer.completionTime - currentTime)
        local totalTime = activeMixer.duration or 60 -- Default to 60 seconds if not specified
        mixingProgress = math.max(0, math.min(1, (totalTime - timeRemaining) / totalTime))
        isCompleted = timeRemaining <= 0
    end
    
    -- Get screen size for responsive sizing
    local screenSize = ScreenUtils.getScreenSize()
    local screenWidth = screenSize.X
    local screenHeight = screenSize.Y
    
    -- Calculate responsive panel size (smaller as requested)
    local panelWidth = math.max(ScreenUtils.getProportionalSize(550), screenWidth * 0.55) -- 55% of screen width, smaller
    local panelHeight = math.max(ScreenUtils.getProportionalSize(500), screenHeight * 0.7) -- 70% of screen height, smaller
    
    return React.createElement("ScreenGui", {
        Name = "PetMixerUI",
        ResetOnSpawn = false
    }, {
        -- Background overlay (no darkening, no auto-close)
        Background = isVisible and React.createElement("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1, -- Completely transparent
            BorderSizePixel = 0,
            ZIndex = 1,
        }) or nil,
        
        -- Main Panel with Pet UI theme
        MainPanel = isVisible and React.createElement("Frame", {
            Name = "MixerPanel",
            Size = UDim2.new(0, panelWidth, 0, panelHeight),
            Position = UDim2.new(0.5, -panelWidth/2, 0.5, -panelHeight/2),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255), -- White background like Pet UI
            BorderSizePixel = ScreenUtils.getProportionalSize(3),
            BorderColor3 = Color3.fromRGB(0, 0, 0), -- Black border like Pet UI
            ZIndex = 5,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(12)) -- Responsive corner
            }),
            
            -- White background like Pet UI
            WhiteBackground = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(245, 245, 245), -- Light grey background like Pet UI
                BorderSizePixel = 0,
                ZIndex = 4, -- Behind everything
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(12)),
                }),
            }),
            
            -- Background pattern like Pet UI
            BackgroundPattern = React.createElement("ImageLabel", {
                Name = "BackgroundPattern",
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1, -- Transparent so white shows through
                Image = "rbxassetid://116367512866072",
                ScaleType = Enum.ScaleType.Tile,
                TileSize = UDim2.new(0, ScreenUtils.getProportionalSize(120), 0, ScreenUtils.getProportionalSize(120)), -- Medium paw pattern like Pet UI
                ImageTransparency = 0.85, -- More transparent for subtle effect like Pet UI
                ImageColor3 = Color3.fromRGB(200, 200, 200), -- Lighter grey tint like Pet UI
                ZIndex = 5, -- Above white background but behind content
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(12)),
                }),
            }),
            
            -- Header section like Pet UI
            Header = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(60)), -- Responsive header height
                BackgroundTransparency = 1, -- Transparent for gradient
                ZIndex = 6,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(12))
                }),
                
                -- Header outline like Pet UI
                HeaderOutline = React.createElement("UIStroke", {
                    Thickness = ScreenUtils.getProportionalSize(2),
                    Color = Color3.fromRGB(0, 0, 0), -- Black outline
                    Transparency = 0,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                }),
                
                -- Gradient background for header like Pet UI
                GradientBackground = React.createElement("Frame", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundColor3 = Color3.fromRGB(64, 224, 208), -- Turquoise base like Pet UI
                    BorderSizePixel = 0,
                    ZIndex = 5,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(12))
                    }),
                    Gradient = React.createElement("UIGradient", {
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))
                        }),
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0.3),
                            NumberSequenceKeypoint.new(1, 0.6)
                        }),
                        Rotation = 90,
                    }),
                }),
                
                -- Header title
                Title = React.createElement("TextLabel", {
                    Size = UDim2.new(1, -ScreenUtils.getProportionalSize(70), 1, 0),
                    Position = UDim2.new(0.5, 0, 0, 0),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    Text = "🧪 Pet Mixer",
                    TextColor3 = Color3.fromRGB(64, 224, 208), -- Turquoise like Pet UI
                    TextSize = ScreenUtils.TEXT_SIZES.HEADER(), -- Responsive text
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    ZIndex = 7,
                }),
                
                -- Close button like Pet UI
                CloseButton = React.createElement("ImageButton", {
                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(50), 0, ScreenUtils.getProportionalSize(50)),
                    Position = UDim2.new(1, -ScreenUtils.getProportionalSize(55), 0.5, -ScreenUtils.getProportionalSize(25)),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    Image = IconAssets.getIcon("UI", "X_BUTTON"),
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 7,
                    [React.Event.Activated] = function()
                        setIsVisible(false)
                    end
                })
            }),
            
            
            -- Top section with Selected Pets Table and Mix Outcome
            TopSection = React.createElement("Frame", {
                Name = "TopSection",
                Size = UDim2.new(1, -ScreenUtils.getProportionalSize(40), 0, ScreenUtils.getProportionalSize(220)), -- Increased height to accommodate mixing card
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(20), 0, ScreenUtils.getProportionalSize(80)),
                BackgroundTransparency = 1,
                ZIndex = 6,
            }, {
                -- Selected Pets Table (left side) - TRANSPARENT BACKGROUND
                SelectedPetsSection = React.createElement("Frame", {
                    Name = "SelectedPetsSection",
                    Size = activeMixer and UDim2.new(1, 0, 1, 0) or UDim2.new(0.6, -ScreenUtils.getProportionalSize(10), 1, 0), -- Full width when mixing, 60% when selecting
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundTransparency = 1, -- Transparent to match main panel
                    BorderSizePixel = ScreenUtils.getProportionalSize(2),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 6,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(8))
                    }),
                    -- Selected pets table title
                    TableTitle = React.createElement("TextLabel", {
                        Size = UDim2.new(1, -20, 0, ScreenUtils.getProportionalSize(25)),
                        Position = UDim2.new(0, 10, 0, 5),
                        BackgroundTransparency = 1,
                        Font = Enum.Font.FredokaOne,
                        Text = activeMixer and not isCompleted and "⚗️ Mixing..." or (isCompleted and "🎁 Ready to Claim" or "📝 Selected Pets"),
                        TextColor3 = isCompleted and Color3.fromRGB(50, 200, 100) or Color3.fromRGB(64, 224, 208),
                        TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextStrokeTransparency = 0,
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        ZIndex = 7,
                    }),
                    
                    -- Selected pets list
                    SelectedPetsList = React.createElement("ScrollingFrame", {
                        Size = UDim2.new(1, -20, 1, -40),
                        Position = UDim2.new(0, 10, 0, 35),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        CanvasSize = UDim2.new(0, 0, 0, (function()
                            if activeMixer and activeMixer.outputPet then
                                return ScreenUtils.getProportionalSize(120) -- Size for output pet card
                            else
                                local count = 0
                                for _ in pairs(selectedPets) do
                                    count = count + 1
                                end
                                return count * ScreenUtils.getProportionalSize(40) -- Updated spacing for selected pets
                            end
                        end)()),
                        ScrollBarThickness = 6,
                        ZIndex = 6,
                    }, (function()
                        local petItems = {}
                        
                        -- Show output pet when claiming/mixing, or selected pets when selecting
                        if activeMixer and activeMixer.outputPet then
                            -- Show the output pet when mixing or ready to claim
                            local outputPet = activeMixer.outputPet
                            -- Mixed pets should show "Mixed" for both rarity and variation
                            local variation = "Mixed"
                            local rarity = "Mixed"
                            local variationColor = Color3.fromRGB(128, 0, 128) -- Purple for mixed
                            local rarityColor = Color3.fromRGB(255, 215, 0) -- Gold for mixed
                            
                            petItems["OutputPet"] = React.createElement("Frame", {
                                Name = "OutputPetCard",
                                Size = UDim2.new(0, ScreenUtils.getProportionalSize(180), 0, ScreenUtils.getProportionalSize(180)), -- Slightly larger since we have full width
                                Position = UDim2.new(0.5, 0, 0, ScreenUtils.getProportionalSize(30)), -- Perfectly centered with margin
                                AnchorPoint = Vector2.new(0.5, 0), -- Anchor from center for true centering
                                BackgroundTransparency = 1, -- Transparent to show colored background
                                BorderSizePixel = 0,
                                ZIndex = 10,
                                
                                -- Add mouse events for tooltip support
                                [React.Event.MouseEnter] = function(rbx)
                                    if outputPet then
                                        showTooltip(rbx, outputPet)
                                    end
                                end,
                                [React.Event.MouseLeave] = function(rbx)
                                    hideTooltip()
                                end,
                            }, {
                                Corner = React.createElement("UICorner", {
                                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(80)) -- Circular like Pet UI
                                }),
                                
                                -- Completion outline (green when ready, gold when mixing)
                                CompletionOutline = React.createElement("UIStroke", {
                                    Thickness = ScreenUtils.getProportionalSize(4),
                                    Color = isCompleted and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 215, 0), -- Green when ready, gold when mixing
                                    Transparency = 0,
                                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                                }),
                                
                                -- Squiggle background with mixed color like Pet UI
                                SquiggleBackground = React.createElement("ImageLabel", {
                                    Size = UDim2.new(0.9, 0, 0.9, 0),
                                    Position = UDim2.new(0.5, 0, 0.5, 0),
                                    AnchorPoint = Vector2.new(0.5, 0.5),
                                    BackgroundTransparency = 1,
                                    Image = IconAssets.getIcon("UI", "SQUIGGLE"),
                                    ImageColor3 = variationColor, -- Apply mixed color
                                    ImageTransparency = 0.3,
                                    ScaleType = Enum.ScaleType.Fit,
                                    ZIndex = 9, -- Behind viewport
                                }, {
                                    Corner = React.createElement("UICorner", {
                                        CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(58)) -- Circular clipping
                                    }),
                                }),
                                
                                -- Pet model viewport like Pet UI
                                PetViewport = React.createElement("ViewportFrame", {
                                    Size = UDim2.new(1, -ScreenUtils.getProportionalSize(10), 1, -ScreenUtils.getProportionalSize(25)), -- Leave space for name and badges
                                    Position = UDim2.new(0, ScreenUtils.getProportionalSize(5), 0, ScreenUtils.getProportionalSize(5)),
                                    BackgroundTransparency = 1, -- Transparent viewport
                                    ZIndex = 11, -- Above background
                                    
                                    -- Load pet model when viewport is created (lazy loading)
                                    [React.Event.AncestryChanged] = function(rbx)
                                        if rbx.Parent then
                                            -- Stagger loading to prevent lag
                                            task.spawn(function()
                                                task.wait(0.3) -- Longer delay for mixer output pets
                                                
                                                local petModel = createPetModelForMixer(outputPet, 1)
                                                if petModel and rbx.Parent then
                                                    petModel.Parent = rbx
                                                    setupPetViewportCamera(rbx, petModel)
                                                end
                                            end)
                                        end
                                    end
                                }),
                                
                                -- Pet name badge like Pet UI
                                NameBadge = React.createElement("Frame", {
                                    Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(25)),
                                    Position = UDim2.new(0, 0, 0.5, -ScreenUtils.getProportionalSize(12.5)),
                                    BackgroundColor3 = Color3.fromRGB(0, 0, 0), -- Black background like Pet UI
                                    BackgroundTransparency = 0.3,
                                    BorderSizePixel = 0,
                                    ZIndex = 12, -- Above viewport
                                }, {
                                    NameText = React.createElement("TextLabel", {
                                        Size = UDim2.new(1, 0, 1, 0),
                                        BackgroundTransparency = 1,
                                        Text = selectedExclusivePet or outputPet.Name or "Mystery Pet",
                                        TextColor3 = Color3.fromRGB(255, 255, 255),
                                        TextSize = ScreenUtils.TEXT_SIZES.SMALL(),
                                        Font = Enum.Font.FredokaOne,
                                        TextXAlignment = Enum.TextXAlignment.Center,
                                        TextYAlignment = Enum.TextYAlignment.Center,
                                        ZIndex = 13,
                                    })
                                }),
                                
                                -- Status badge (top right)
                                StatusBadge = React.createElement("Frame", {
                                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(50), 0, ScreenUtils.getProportionalSize(20)),
                                    Position = UDim2.new(1, -ScreenUtils.getProportionalSize(55), 0, ScreenUtils.getProportionalSize(5)),
                                    BackgroundColor3 = isCompleted and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 165, 0),
                                    BorderSizePixel = 1,
                                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                                    ZIndex = 12,
                                }, {
                                    Corner = React.createElement("UICorner", {
                                        CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(10))
                                    }),
                                    StatusText = React.createElement("TextLabel", {
                                        Size = UDim2.new(1, 0, 1, 0),
                                        BackgroundTransparency = 1,
                                        Text = isCompleted and "READY" or "MIXING",
                                        TextColor3 = Color3.fromRGB(255, 255, 255),
                                        TextSize = ScreenUtils.TEXT_SIZES.SMALL() * 0.7,
                                        Font = Enum.Font.FredokaOne,
                                        TextXAlignment = Enum.TextXAlignment.Center,
                                        TextYAlignment = Enum.TextYAlignment.Center,
                                        ZIndex = 13,
                                    })
                                }),
                                
                                -- Boost badge (bottom left) like Pet UI
                                BoostBadge = React.createElement("Frame", {
                                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(50), 0, ScreenUtils.getProportionalSize(20)),
                                    Position = UDim2.new(0, ScreenUtils.getProportionalSize(5), 1, -ScreenUtils.getProportionalSize(25)),
                                    BackgroundColor3 = Color3.fromRGB(255, 215, 0), -- Gold
                                    BorderSizePixel = 1,
                                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                                    ZIndex = 12,
                                }, {
                                    Corner = React.createElement("UICorner", {
                                        CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(10))
                                    }),
                                    BoostText = React.createElement("TextLabel", {
                                        Size = UDim2.new(1, 0, 1, 0),
                                        BackgroundTransparency = 1,
                                        Text = string.format("%.1fx", outputPet.FinalBoost or outputPet.BaseBoost or 1),
                                        TextColor3 = Color3.fromRGB(0, 0, 0),
                                        TextSize = ScreenUtils.TEXT_SIZES.SMALL() * 0.7,
                                        Font = Enum.Font.FredokaOne,
                                        TextXAlignment = Enum.TextXAlignment.Center,
                                        TextYAlignment = Enum.TextYAlignment.Center,
                                        ZIndex = 13,
                                    })
                                })
                            })
                        else
                            -- Show selected pets when selecting
                            local index = 1
                            for petId, _ in pairs(selectedPets) do
                                -- Find the pet data
                                local selectedPet = nil
                                for _, pet in ipairs(availablePets) do
                                    if pet.ID == petId then
                                        selectedPet = pet
                                        break
                                    end
                                end
                                
                                if selectedPet then
                                local rarityColor = PetConstants.getRarityColor(type(selectedPet.Rarity) == "table" and selectedPet.Rarity.RarityName or selectedPet.Rarity)
                                local variationColor = PetConstants.getVariationColor(type(selectedPet.Variation) == "table" and selectedPet.Variation.VariationName or selectedPet.Variation)
                                
                                -- Get spawn chance for rarity display
                                local spawnChance = selectedPet.SpawnChance or 1
                                local rarityChance = spawnChance > 0 and math.floor(100 / spawnChance) or 1000000
                                
                                petItems["SelectedPet" .. index] = React.createElement("Frame", {
                                    Size = UDim2.new(1, 0, 0, 35), -- Taller row for more info
                                    Position = UDim2.new(0, 0, 0, (index - 1) * 40), -- More spacing
                                    BackgroundColor3 = variationColor, -- Variation-colored background
                                    BackgroundTransparency = 0.8, -- Semi-transparent for subtle effect
                                    BorderSizePixel = ScreenUtils.getProportionalSize(1),
                                    BorderColor3 = variationColor, -- Variation-colored border
                                    ZIndex = 7,
                                }, {
                                    Corner = React.createElement("UICorner", {
                                        CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(4))
                                    }),
                                    -- Main pet info row
                                    InfoRow = React.createElement("Frame", {
                                        Size = UDim2.new(1, -20, 1, 0),
                                        Position = UDim2.new(0, 10, 0, 0),
                                        BackgroundTransparency = 1,
                                        ZIndex = 8,
                                    }, {
                                        -- Pet name (bigger)
                                        PetName = React.createElement("TextLabel", {
                                            Size = UDim2.new(0.4, 0, 0.5, 0),
                                            Position = UDim2.new(0, 0, 0, 0),
                                            BackgroundTransparency = 1,
                                            Text = selectedPet.Name,
                                            TextColor3 = Color3.fromRGB(255, 255, 255),
                                            TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(), -- Bigger text
                                            Font = Enum.Font.FredokaOne,
                                            TextStrokeTransparency = 0,
                                            TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                                            TextXAlignment = Enum.TextXAlignment.Center,
                                            TextYAlignment = Enum.TextYAlignment.Center,
                                            ZIndex = 9,
                                        }),
                                        -- Boost (top right)
                                        BoostLabel = React.createElement("TextLabel", {
                                            Size = UDim2.new(0.3, 0, 0.5, 0),
                                            Position = UDim2.new(0.4, 0, 0, 0),
                                            BackgroundTransparency = 1,
                                            Text = string.format("Boost: x%.2f", selectedPet.FinalBoost or selectedPet.BaseBoost or 1),
                                            TextColor3 = Color3.fromRGB(255, 255, 255),
                                            TextSize = ScreenUtils.TEXT_SIZES.SMALL(),
                                            Font = Enum.Font.FredokaOne,
                                            TextStrokeTransparency = 0,
                                            TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                                            TextXAlignment = Enum.TextXAlignment.Center,
                                            TextYAlignment = Enum.TextYAlignment.Center,
                                            ZIndex = 9,
                                        }),
                                        -- Variation (bottom left)
                                        VariationLabel = React.createElement("TextLabel", {
                                            Size = UDim2.new(0.4, 0, 0.5, 0),
                                            Position = UDim2.new(0, 0, 0.5, 0),
                                            BackgroundTransparency = 1,
                                            Text = type(selectedPet.Variation) == "table" and selectedPet.Variation.VariationName or selectedPet.Variation or "Bronze",
                                            TextColor3 = Color3.fromRGB(200, 200, 200),
                                            TextSize = ScreenUtils.TEXT_SIZES.SMALL() * 0.9,
                                            Font = Enum.Font.Gotham,
                                            TextXAlignment = Enum.TextXAlignment.Center,
                                            TextYAlignment = Enum.TextYAlignment.Center,
                                            ZIndex = 9,
                                        }),
                                        -- Rarity with 1 in X (bottom right)
                                        RarityLabel = React.createElement("TextLabel", {
                                            Size = UDim2.new(0.3, 0, 0.5, 0),
                                            Position = UDim2.new(0.4, 0, 0.5, 0),
                                            BackgroundTransparency = 1,
                                            Text = string.format("1 in %s", NumberFormatter.format(rarityChance)),
                                            TextColor3 = rarityColor,
                                            TextSize = ScreenUtils.TEXT_SIZES.SMALL() * 0.9,
                                            Font = Enum.Font.Gotham,
                                            TextXAlignment = Enum.TextXAlignment.Center,
                                            TextYAlignment = Enum.TextYAlignment.Center,
                                            ZIndex = 9,
                                        }),
                                    }),
                                    
                                    RemoveButton = React.createElement("TextButton", {
                                        Size = UDim2.new(0, 20, 0, 20),
                                        Position = UDim2.new(1, -20, 0.5, -10),
                                        BackgroundColor3 = Color3.fromRGB(255, 100, 100),
                                        Text = "X",
                                        TextColor3 = Color3.fromRGB(255, 255, 255),
                                        TextSize = ScreenUtils.TEXT_SIZES.SMALL(),
                                        Font = Enum.Font.FredokaOne,
                                        ZIndex = 8,
                                        [React.Event.Activated] = function()
                                            togglePetSelection(petId)
                                        end
                                    }, {
                                        Corner = React.createElement("UICorner", {
                                            CornerRadius = ScreenUtils.udim(0, 4)
                                        })
                                    })
                                })
                                    index = index + 1
                                end
                            end
                        end -- Close the else branch
                        return petItems
                    end)()
                    )
                }),
                
                -- Mix Outcome Section (right side) with proper pet card and styling - Hide when actively mixing
                OutcomeSection = mixPreview and not activeMixer and React.createElement("Frame", {
                    Name = "OutcomeSection",
                    Size = UDim2.new(0.4, -ScreenUtils.getProportionalSize(10), 1, 0), -- 40% width
                    Position = UDim2.new(0.6, ScreenUtils.getProportionalSize(10), 0, 0),
                    BackgroundTransparency = 1, -- Transparent to match main panel background
                    ZIndex = 6,
                }, {
                    -- Preview Title (centered above everything)
                    PreviewTitle = React.createElement("TextLabel", {
                        Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(25)),
                        Position = UDim2.new(0.5, 0, 0, ScreenUtils.getProportionalSize(5)),
                        AnchorPoint = Vector2.new(0.5, 0),
                        BackgroundTransparency = 1,
                        Font = Enum.Font.FredokaOne,
                        Text = "✨ Mix Outcome",
                        TextColor3 = Color3.fromRGB(64, 224, 208), -- Turquoise like Pet UI headers
                        TextSize = ScreenUtils.TEXT_SIZES.LARGE(),
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextStrokeTransparency = 0,
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        ZIndex = 8,
                    }),
                    
                    -- Pet card (left side - MASSIVE)
                    OutcomePetCard = React.createElement("Frame", {
                        Size = UDim2.new(0, ScreenUtils.getProportionalSize(200), 0, ScreenUtils.getProportionalSize(200)), -- MASSIVE pet card
                        Position = UDim2.new(0, ScreenUtils.getProportionalSize(5), 0, ScreenUtils.getProportionalSize(35)), -- Below title
                        BackgroundTransparency = 1,
                        ZIndex = 7,
                    }, {
                        Corner = React.createElement("UICorner", {
                            CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(100)) -- Circular for massive size
                        }),
                        
                        -- Mixed pet squiggle background (purple)
                        MixedBackground = React.createElement("ImageLabel", {
                            Size = UDim2.new(0.9, 0, 0.9, 0),
                            Position = UDim2.new(0.5, 0, 0.5, 0),
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            BackgroundTransparency = 1,
                            Image = IconAssets.getIcon("UI", "SQUIGGLE"),
                            ImageColor3 = Color3.fromRGB(138, 43, 226), -- Purple for mixed pets
                            ImageTransparency = 0.3,
                            ScaleType = Enum.ScaleType.Fit,
                            ZIndex = 8,
                        }, {
                            Corner = React.createElement("UICorner", {
                                CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(50))
                            }),
                        }),
                        
                        -- Pet ViewportFrame (like Pet UI)
                        PetViewport = React.createElement("ViewportFrame", {
                            Size = UDim2.new(1, -ScreenUtils.getProportionalSize(10), 1, -ScreenUtils.getProportionalSize(25)),
                            Position = UDim2.new(0, ScreenUtils.getProportionalSize(5), 0, ScreenUtils.getProportionalSize(5)),
                            BackgroundTransparency = 1,
                            ZIndex = 9,
                            
                            -- Load exclusive mixing pet model when viewport is created (lazy loading)
                            [React.Event.AncestryChanged] = function(rbx)
                                if rbx.Parent and selectedExclusivePet then
                                    task.spawn(function()
                                        task.wait(0.2) -- Stagger exclusive pet loading
                                        
                                        -- Use the already selected exclusive pet
                                        local exclusivePetData = {
                                            Name = selectedExclusivePet,
                                            ModelName = selectedExclusivePet -- Model names should match
                                        }
                                        
                                        local petModel = createPetModelForMixer(exclusivePetData, 1)
                                        if petModel and rbx.Parent then
                                            petModel.Parent = rbx
                                            setupPetViewportCamera(rbx, petModel)
                                            
                                            -- Tint the model purple for mixed/exclusive effect
                                            for _, descendant in pairs(petModel:GetDescendants()) do
                                                if descendant:IsA("BasePart") then
                                                    descendant.Color = Color3.fromRGB(138, 43, 226):lerp(descendant.Color, 0.3)
                                                end
                                            end
                                        end
                                    end)
                                end
                            end,
                        }, {
                            Corner = React.createElement("UICorner", {
                                CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(50))
                            }),
                        }),
                        
                        -- Pet name with rarity color (HUGE for massive card)
                        PetName = React.createElement("TextLabel", {
                            Size = ScreenUtils.udim2(1, -10, 0, 35),
                            Position = ScreenUtils.udim2(0, 5, 1, -40),
                            BackgroundTransparency = 1,
                            Text = mixPreview.outputName,
                            TextColor3 = Color3.fromRGB(138, 43, 226), -- Purple for Mixed rarity
                            TextSize = ScreenUtils.TEXT_SIZES.TITLE(), -- Biggest text size
                            Font = Enum.Font.FredokaOne,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            TextYAlignment = Enum.TextYAlignment.Center,
                            TextScaled = true,
                            TextStrokeTransparency = 0,
                            TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                            ZIndex = 10,
                        }),
                        
                        -- Boost text overlay like Pet UI (HUGE for massive card)
                        BoostText = React.createElement("TextLabel", {
                            Size = ScreenUtils.udim2(1, -10, 0, 30),
                            Position = ScreenUtils.udim2(0, 5, 1, -80),
                            BackgroundTransparency = 1,
                            Text = string.format("x%.2f", mixPreview.boost),
                            TextColor3 = Color3.fromRGB(255, 255, 255),
                            TextSize = ScreenUtils.TEXT_SIZES.HEADER(), -- Header size
                            Font = Enum.Font.FredokaOne,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            TextYAlignment = Enum.TextYAlignment.Center,
                            TextScaled = true,
                            TextStrokeTransparency = 0,
                            TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                            ZIndex = 10,
                        }, {
                            -- Pink to blue gradient like Pet UI
                            ShinyGradient = React.createElement("UIGradient", {
                                Color = ColorSequence.new({
                                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 20, 147)),   -- Deep Pink
                                    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 105, 180)), -- Hot Pink
                                    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(138, 43, 226)),  -- Blue Violet
                                    ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 144, 255))     -- Dodger Blue
                                }),
                                Rotation = 0
                            })
                        }),
                        
                        -- Hover detector for tooltip
                        HoverDetector = React.createElement("TextButton", {
                            Size = UDim2.new(1, 0, 1, 0),
                            BackgroundTransparency = 1,
                            Text = "",
                            ZIndex = 11,
                            [React.Event.MouseEnter] = function(rbx)
                                if mixPreview then
                                    -- Create a fake pet data for tooltip
                                    local tooltipPet = {
                                        Name = mixPreview.outputName,
                                        Rarity = "Mixed", 
                                        Variation = "Exclusive",
                                        FinalBoost = mixPreview.boost,
                                        BaseBoost = mixPreview.boost,
                                        BaseValue = mixPreview.value,
                                        Quantity = 1
                                    }
                                    setHoveredPet(tooltipPet)
                                    
                                    -- Track mouse position
                                    if mouseConnections.outcomeCard then
                                        mouseConnections.outcomeCard:Disconnect()
                                    end
                                    
                                    mouseConnections.outcomeCard = UserInputService.InputChanged:Connect(function(input)
                                        if input.UserInputType == Enum.UserInputType.MouseMovement then
                                            local mousePos = UserInputService:GetMouseLocation()
                                            local responsiveOffset = ScreenUtils.getScaleFactor() * 15
                                            setTooltipPosition(UDim2.new(0, mousePos.X + responsiveOffset, 0, mousePos.Y - responsiveOffset))
                                        end
                                    end)
                                end
                            end,
                            [React.Event.MouseLeave] = function(rbx)
                                setHoveredPet(nil)
                                -- Disconnect mouse tracking
                                if mouseConnections.outcomeCard then
                                    mouseConnections.outcomeCard:Disconnect()
                                    mouseConnections.outcomeCard = nil
                                end
                            end
                        })
                    }),
                    
                    -- Mix Details Section (right side - adjusted for MASSIVE pet card)
                    DetailsSection = React.createElement("Frame", {
                        Size = UDim2.new(1, -ScreenUtils.getProportionalSize(220), 0, ScreenUtils.getProportionalSize(200)), -- Adjusted for MASSIVE card
                        Position = UDim2.new(0, ScreenUtils.getProportionalSize(215), 0, ScreenUtils.getProportionalSize(35)), -- Next to MASSIVE pet card
                        BackgroundTransparency = 1,
                        ZIndex = 7,
                    }, {
                        Layout = React.createElement("UIListLayout", {
                            FillDirection = Enum.FillDirection.Vertical,
                            HorizontalAlignment = Enum.HorizontalAlignment.Center,
                            VerticalAlignment = Enum.VerticalAlignment.Top,
                            Padding = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(5)),
                            SortOrder = Enum.SortOrder.LayoutOrder,
                        }),
                        
                        -- Diamond Cost with icon
                        CostInfo = React.createElement("Frame", {
                            Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(25)),
                            BackgroundTransparency = 1,
                            LayoutOrder = 1,
                            ZIndex = 8,
                        }, {
                            DiamondIcon = React.createElement("ImageLabel", {
                                Size = UDim2.new(0, ScreenUtils.getProportionalSize(20), 0, ScreenUtils.getProportionalSize(20)),
                                Position = UDim2.new(0, 0, 0.5, -ScreenUtils.getProportionalSize(10)),
                                BackgroundTransparency = 1,
                                Image = IconAssets.getIcon("CURRENCY", "DIAMONDS"),
                                ScaleType = Enum.ScaleType.Fit,
                                ZIndex = 9,
                            }),
                            
                            CostText = React.createElement("TextLabel", {
                                Size = UDim2.new(1, -ScreenUtils.getProportionalSize(25), 1, 0),
                                Position = UDim2.new(0, ScreenUtils.getProportionalSize(25), 0, 0),
                                BackgroundTransparency = 1,
                                Text = string.format("Cost: %s Diamonds", NumberFormatter.format(calculateDiamondCost())),
                                TextColor3 = (playerData.Resources and playerData.Resources.Diamonds or 0) >= calculateDiamondCost() 
                                           and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(255, 100, 100),
                                TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                                Font = Enum.Font.FredokaOne,
                                TextXAlignment = Enum.TextXAlignment.Center,
                                TextYAlignment = Enum.TextYAlignment.Center,
                                ZIndex = 9,
                            })
                        }),
                        
                        -- Mix Time with clock icon
                        TimeInfo = React.createElement("Frame", {
                            Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(25)),
                            BackgroundTransparency = 1,
                            LayoutOrder = 2,
                            ZIndex = 8,
                        }, {
                            ClockIcon = React.createElement("TextLabel", {
                                Size = UDim2.new(0, ScreenUtils.getProportionalSize(20), 0, ScreenUtils.getProportionalSize(20)),
                                Position = UDim2.new(0, 0, 0.5, -ScreenUtils.getProportionalSize(10)),
                                BackgroundTransparency = 1,
                                Text = "⏱️", -- Clock emoji
                                TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                                Font = Enum.Font.Gotham,
                                TextXAlignment = Enum.TextXAlignment.Center,
                                TextYAlignment = Enum.TextYAlignment.Center,
                                ZIndex = 9,
                            }),
                            
                            TimeText = React.createElement("TextLabel", {
                                Size = UDim2.new(1, -ScreenUtils.getProportionalSize(25), 1, 0),
                                Position = UDim2.new(0, ScreenUtils.getProportionalSize(25), 0, 0),
                                BackgroundTransparency = 1,
                                Text = string.format("Time: %s", formatTime(calculateMixTime())),
                                TextColor3 = Color3.fromRGB(64, 224, 208), -- Turquoise
                                TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                                Font = Enum.Font.FredokaOne,
                                TextXAlignment = Enum.TextXAlignment.Center,
                                TextYAlignment = Enum.TextYAlignment.Center,
                                ZIndex = 9,
                            })
                        }),
                        
                        -- Pet Value with money icon
                        ValueInfo = React.createElement("Frame", {
                            Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(25)),
                            BackgroundTransparency = 1,
                            LayoutOrder = 3,
                            ZIndex = 8,
                        }, {
                            MoneyIcon = React.createElement("ImageLabel", {
                                Size = UDim2.new(0, ScreenUtils.getProportionalSize(20), 0, ScreenUtils.getProportionalSize(20)),
                                Position = UDim2.new(0, 0, 0.5, -ScreenUtils.getProportionalSize(10)),
                                BackgroundTransparency = 1,
                                Image = IconAssets.getIcon("CURRENCY", "MONEY"),
                                ScaleType = Enum.ScaleType.Fit,
                                ZIndex = 9,
                            }),
                            
                            ValueText = React.createElement("TextLabel", {
                                Size = UDim2.new(1, -ScreenUtils.getProportionalSize(25), 1, 0),
                                Position = UDim2.new(0, ScreenUtils.getProportionalSize(25), 0, 0),
                                BackgroundTransparency = 1,
                                Text = string.format("Value: $%s", NumberFormatter.format(mixPreview.value)),
                                TextColor3 = Color3.fromRGB(85, 170, 85), -- Green
                                TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                                Font = Enum.Font.FredokaOne,
                                TextXAlignment = Enum.TextXAlignment.Center,
                                TextYAlignment = Enum.TextYAlignment.Center,
                                ZIndex = 9,
                            })
                        }),
                        
                        -- Start Mix Button (bottom of details section)
                        MixButton = React.createElement("TextButton", {
                            Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(25)),
                            BackgroundColor3 = (function()
                                if activeMixer then
                                    return Color3.fromRGB(100, 100, 100) -- Gray when mixer is active
                                end
                                local count = 0
                                for _ in pairs(selectedPets) do
                                    count = count + 1
                                end
                                return count >= PetMixerConfig.MIN_PETS_PER_MIX and Color3.fromRGB(50, 200, 100) or Color3.fromRGB(120, 120, 120)
                            end)(),
                            BorderSizePixel = ScreenUtils.getProportionalSize(2),
                            BorderColor3 = Color3.fromRGB(0, 0, 0),
                            Font = Enum.Font.FredokaOne,
                            Text = activeMixer and "⚗️ Mixer Active" or "🧪 Start Mixing",
                            TextColor3 = Color3.fromRGB(255, 255, 255),
                            TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                            TextStrokeTransparency = 0,
                            TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                            ZIndex = 9,
                            LayoutOrder = 4,
                            [React.Event.Activated] = activeMixer and function() end or startMixing -- Disable when mixer is active
                        }, {
                            Corner = React.createElement("UICorner", {
                                CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(6))
                            })
                        })
                    }),
                    
                }) or nil
            }),
            
            -- Mixing Progress Section (only show when mixing is active)
            MixingProgressSection = activeMixer and React.createElement("Frame", {
                Name = "MixingProgressSection",
                Size = UDim2.new(1, -ScreenUtils.getProportionalSize(40), 0, ScreenUtils.getProportionalSize(80)),
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(20), 0, ScreenUtils.getProportionalSize(320)), -- Move down to avoid overlap with mixing card
                BackgroundColor3 = Color3.fromRGB(245, 245, 245), -- Match main panel background
                BorderSizePixel = ScreenUtils.getProportionalSize(2),
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                ZIndex = 6,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(8))
                }),
                
                -- Progress section title
                ProgressTitle = React.createElement("TextLabel", {
                    Size = UDim2.new(1, -20, 0, ScreenUtils.getProportionalSize(25)),
                    Position = UDim2.new(0, 10, 0, 5),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.FredokaOne,
                    Text = isCompleted and (activeMixer.outputPet and 
                        string.format("🎉 Created: %s!", activeMixer.outputPet.Name or "Mystery Pet") or "🎉 Mixing Complete!") 
                        or (activeMixer.outputPet and string.format("⚗️ Creating: %s...", activeMixer.outputPet.Name or "Mystery Pet") or "⚗️ Mixing in Progress..."),
                    TextColor3 = isCompleted and Color3.fromRGB(50, 200, 100) or Color3.fromRGB(255, 165, 0),
                    TextSize = ScreenUtils.TEXT_SIZES.LARGE(),
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 7,
                }),
                
                -- Progress bar background
                ProgressBarBG = React.createElement("Frame", {
                    Size = UDim2.new(1, -40, 0, ScreenUtils.getProportionalSize(20)),
                    Position = UDim2.new(0, 20, 0, ScreenUtils.getProportionalSize(35)),
                    BackgroundColor3 = Color3.fromRGB(200, 200, 200),
                    BorderSizePixel = ScreenUtils.getProportionalSize(1),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 7,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(4))
                    }),
                    
                    -- Progress bar fill
                    ProgressBarFill = React.createElement("Frame", {
                        Size = UDim2.new(mixingProgress, 0, 1, 0),
                        Position = UDim2.new(0, 0, 0, 0),
                        BackgroundColor3 = isCompleted and Color3.fromRGB(50, 200, 100) or Color3.fromRGB(255, 165, 0),
                        BorderSizePixel = 0,
                        ZIndex = 8,
                    }, {
                        Corner = React.createElement("UICorner", {
                            CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(4))
                        }),
                    })
                }),
                
                -- Time remaining display or claim button
                TimeDisplay = not isCompleted and React.createElement("TextLabel", {
                    Size = UDim2.new(1, -20, 0, ScreenUtils.getProportionalSize(20)),
                    Position = UDim2.new(0, 10, 1, -ScreenUtils.getProportionalSize(25)),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    Text = string.format("Time remaining: %s", formatTime(timeRemaining)),
                    TextColor3 = Color3.fromRGB(100, 100, 100),
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 7,
                }) or nil,
                
                -- Claim button (only when completed)
                ClaimButton = isCompleted and React.createElement("TextButton", {
                    Size = UDim2.new(1, -40, 0, ScreenUtils.getProportionalSize(30)),
                    Position = UDim2.new(0, 20, 1, -ScreenUtils.getProportionalSize(35)),
                    BackgroundColor3 = Color3.fromRGB(50, 200, 100), -- Green
                    BorderSizePixel = ScreenUtils.getProportionalSize(2),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Font = Enum.Font.FredokaOne,
                    Text = "🎁 Claim Pet!",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.TEXT_SIZES.LARGE(),
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 7,
                    [React.Event.Activated] = function()
                        -- Claim the mixer
                        if activeMixer then
                            local remoteEvent = ReplicatedStorage:FindFirstChild("ClaimMixer")
                            if remoteEvent then
                                remoteEvent:FireServer(activeMixer.id)
                                -- Clear selected pets and exclusive pet to allow new mixing
                                setSelectedPets({})
                                setSelectedExclusivePet(nil)
                            else
                                warn("ClaimMixer remote event not found")
                            end
                        end
                    end
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(6))
                    }),
                }) or nil,
            }) or nil,
            
            -- Pet Selection Section
            SelectionSection = React.createElement("Frame", {
                Name = "SelectionSection",
                Size = UDim2.new(1, -ScreenUtils.getProportionalSize(40), 1, -ScreenUtils.getProportionalSize(activeMixer and 480 or 380)),
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(20), 0, ScreenUtils.getProportionalSize(activeMixer and 380 or 280)),
                BackgroundTransparency = 1,
                ZIndex = 6,
            }, {
                SectionTitle = React.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(25)),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.FredokaOne,
                    Text = "🎲 Select Pets to Mix",
                    TextColor3 = Color3.fromRGB(64, 224, 208), -- Turquoise like Pet UI
                    TextSize = ScreenUtils.TEXT_SIZES.LARGE(),
                    TextXAlignment = Enum.TextXAlignment.Center, -- Centered
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 7,
                }),
                
                PetGrid = #availablePets > 0 and React.createElement("ScrollingFrame", {
                    Size = UDim2.new(1, 0, 1, -ScreenUtils.getProportionalSize(30)),
                    Position = UDim2.new(0, 0, 0, ScreenUtils.getProportionalSize(30)),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    CanvasSize = UDim2.new(0, 0, 0, math.ceil(#availablePets / 3) * ScreenUtils.getProportionalSize(180)), -- Use available pets count
                    ScrollBarThickness = ScreenUtils.getProportionalSize(8),
                    ZIndex = 6,
                }, {
                    UIGridLayout = React.createElement("UIGridLayout", {
                        CellPadding = UDim2.new(0, ScreenUtils.getProportionalSize(10), 0, ScreenUtils.getProportionalSize(10)),
                        CellSize = UDim2.new(0, ScreenUtils.getProportionalSize(160), 0, ScreenUtils.getProportionalSize(160)), -- Bigger cells like Pet UI
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center, -- Centered grid
                        VerticalAlignment = Enum.VerticalAlignment.Top
                    }),
                    
                    Pets = React.createElement(React.Fragment, nil, petCards)
                }) or React.createElement("Frame", {
                    Size = UDim2.new(1, 0, 1, -ScreenUtils.getProportionalSize(30)),
                    Position = UDim2.new(0, 0, 0, ScreenUtils.getProportionalSize(30)),
                    BackgroundTransparency = 1,
                    ZIndex = 6,
                }, {
                    -- Empty state message
                    EmptyStateContainer = React.createElement("Frame", {
                        Size = UDim2.new(1, -40, 0, 200),
                        Position = UDim2.new(0.5, 0, 0.5, -100),
                        AnchorPoint = Vector2.new(0.5, 0),
                        BackgroundColor3 = Color3.fromRGB(245, 245, 245),
                        BorderSizePixel = ScreenUtils.getProportionalSize(2),
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        ZIndex = 7,
                    }, {
                        Corner = React.createElement("UICorner", {
                            CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(12))
                        }),
                        
                        -- Icon
                        Icon = React.createElement("TextLabel", {
                            Size = UDim2.new(1, 0, 0, 60),
                            Position = UDim2.new(0, 0, 0, 20),
                            BackgroundTransparency = 1,
                            Text = "📦",
                            TextSize = 50,
                            TextColor3 = Color3.fromRGB(64, 224, 208),
                            Font = Enum.Font.FredokaOne,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            ZIndex = 8,
                        }),
                        
                        -- Main message
                        Message = React.createElement("TextLabel", {
                            Size = UDim2.new(1, -40, 0, 30),
                            Position = UDim2.new(0, 20, 0, 80),
                            BackgroundTransparency = 1,
                            Text = "No Pets Available for Mixing!",
                            TextColor3 = Color3.fromRGB(50, 50, 50),
                            TextSize = ScreenUtils.TEXT_SIZES.LARGE(),
                            Font = Enum.Font.FredokaOne,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            TextWrapped = true,
                            ZIndex = 8,
                        }),
                        
                        -- Explanation
                        Explanation = React.createElement("TextLabel", {
                            Size = UDim2.new(1, -40, 0, 60),
                            Position = UDim2.new(0, 20, 0, 115),
                            BackgroundTransparency = 1,
                            Text = "You need unequipped pets in your inventory to use the mixer.\nEquipped pets and OP pets cannot be mixed.",
                            TextColor3 = Color3.fromRGB(100, 100, 100),
                            TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            TextWrapped = true,
                            TextYAlignment = Enum.TextYAlignment.Top,
                            ZIndex = 8,
                        })
                    })
                })
            }),
            
            -- Removed - Mix outcome section moved to top
            
            -- Selection Info Section (bottom)
            InfoSection = React.createElement("Frame", {
                Name = "InfoSection",
                Size = UDim2.new(1, -ScreenUtils.getProportionalSize(40), 0, ScreenUtils.getProportionalSize(50)),
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(20), 1, -ScreenUtils.getProportionalSize(60)),
                BackgroundTransparency = 1,
                ZIndex = 6,
            }, {
                -- Selection Info
                SelectionInfo = React.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    Text = string.format("📋 Selected: %d pets (min %d, max %d) | ⏱️ Mix Time: %s | 💎 Cost: %d", 
                        (function()
                            local count = 0
                            for _ in pairs(selectedPets) do
                                count = count + 1
                            end
                            return count
                        end)(),
                        PetMixerConfig.MIN_PETS_PER_MIX,
                        PetMixerConfig.MAX_PETS_PER_MIX,
                        formatTime(calculateMixTime()),
                        calculateDiamondCost()
                    ),
                    TextColor3 = Color3.fromRGB(50, 50, 50), -- Darker text for better readability
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextWrapped = true,
                    ZIndex = 7,
                })
            }),
            
            -- Tooltip (floating)
            Tooltip = createTooltip()
        }) or nil
    })
end

return PetMixerUI