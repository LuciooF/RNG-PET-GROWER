-- PetMixerUI - UI for mixing pets with timer display
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local React = require(ReplicatedStorage.Packages.react)
local DataSyncService = require(script.Parent.Parent.services.DataSyncService)
local PetMixerConfig = require(ReplicatedStorage.config.PetMixerConfig)
local PetMixerButtonService = require(script.Parent.Parent.services.PetMixerButtonService)
local PetUtils = require(ReplicatedStorage.utils.PetUtils)

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
    
    -- Set up mixer button callbacks
    React.useEffect(function()
        PetMixerButtonService:Initialize()
        
        -- Set callbacks for mixer interaction
        PetMixerButtonService:SetOpenCallback(function(mixerNumber)
            setIsVisible(true)
            setActiveMixerNumber(mixerNumber)
            setSelectedPets({}) -- Clear selection when opening
        end)
        
        PetMixerButtonService:SetCloseCallback(function(mixerNumber)
            setIsVisible(false)
        end)
        
        return function()
            PetMixerButtonService:Cleanup()
        end
    end, {})
    
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
    
    -- Calculate preview of mixed pet outcome (simplified)
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
        
        -- Get first pet name for preview
        local firstName = selectedPetsList[1].Name
        
        return {
            outputName = firstName .. " Mix",
            boost = previewBoost,
            value = previewValue,
            petCount = #selectedPetsList
        }
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
        
        return React.createElement("Frame", {
            Name = "PetCard" .. index,
            Size = UDim2.new(0, 100, 0, 120),
            BackgroundColor3 = isSelected and Color3.fromRGB(0, 255, 0) or (isDisabled and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(60, 60, 60)),
            BorderSizePixel = 0
        }, {
            UICorner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0, 8)
            }),
            
            -- Pet Name
            PetName = React.createElement("TextLabel", {
                Size = UDim2.new(1, -10, 0, 30),
                Position = UDim2.new(0, 5, 0, 5),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = pet.Name or "Unknown",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 12,
                TextWrapped = true
            }),
            
            -- Rarity
            Rarity = React.createElement("TextLabel", {
                Size = UDim2.new(1, -10, 0, 20),
                Position = UDim2.new(0, 5, 0, 35),
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Text = (pet.Rarity and pet.Rarity.RarityName) or "Common",
                TextColor3 = PetUtils.arrayToColor(pet.Rarity and pet.Rarity.RarityColor),
                TextSize = 10
            }),
            
            -- Stats
            Stats = React.createElement("TextLabel", {
                Size = UDim2.new(1, -10, 0, 30),
                Position = UDim2.new(0, 5, 0, 55),
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Text = string.format("Boost: %.1fx\nValue: $%d", pet.FinalBoost or pet.BaseBoost or 1, pet.FinalValue or pet.BaseValue or 1),
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextSize = 10,
                TextYAlignment = Enum.TextYAlignment.Top
            }),
            
            -- Status
            Status = isDisabled and React.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0, 20),
                Position = UDim2.new(0, 0, 1, -20),
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 0.3,
                Font = Enum.Font.GothamBold,
                Text = isEquipped and "EQUIPPED" or "PROCESSING",
                TextColor3 = Color3.fromRGB(255, 100, 100),
                TextSize = 10
            }) or nil,
            
            -- Select Button
            SelectButton = React.createElement("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
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
                Font = Enum.Font.GothamBold,
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
                Font = Enum.Font.GothamBold,
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
                Font = Enum.Font.GothamBold,
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
                Font = Enum.Font.GothamBold,
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
    
    -- Create pet grid
    local petCards = {}
    for i, pet in ipairs(playerData.Pets or {}) do
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
    
    return React.createElement("ScreenGui", {
        Name = "PetMixerUI",
        ResetOnSpawn = false
    }, {
        -- Main Panel (no toggle button, controlled by proximity)
        MainPanel = isVisible and React.createElement("Frame", {
            Name = "MixerPanel",
            Size = UDim2.new(0, 600, 0, 500),
            Position = UDim2.new(0.5, -300, 0.5, -250),
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            BorderSizePixel = 0
        }, {
            UICorner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0, 12)
            }),
            
            -- Title
            Title = React.createElement("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -40, 0, 40),
                Position = UDim2.new(0, 20, 0, 10),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = "Pet Mixer " .. activeMixerNumber,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 24,
                TextXAlignment = Enum.TextXAlignment.Left
            }),
            
            -- Close button
            CloseButton = React.createElement("TextButton", {
                Name = "CloseButton",
                Size = UDim2.new(0, 50, 0, 50), -- Bigger close button
                Position = UDim2.new(1, -55, 0, 10),
                BackgroundColor3 = Color3.fromRGB(200, 50, 50),
                BorderSizePixel = 0,
                Font = Enum.Font.GothamBold,
                Text = "×",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 18,
                [React.Event.Activated] = function()
                    setIsVisible(false)
                end
            }, {
                UICorner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 6)
                })
            }),
            
            -- Active Mixers Section
            MixersSection = React.createElement("Frame", {
                Name = "MixersSection",
                Size = UDim2.new(1, -40, 0, 150),
                Position = UDim2.new(0, 20, 0, 60),
                BackgroundTransparency = 1
            }, {
                SectionTitle = React.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    Text = "Active Mixers (" .. #mixerDisplays .. "/" .. PetMixerConfig.MAX_ACTIVE_MIXERS .. ")",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 16,
                    TextXAlignment = Enum.TextXAlignment.Left
                }),
                
                MixersList = React.createElement("ScrollingFrame", {
                    Size = UDim2.new(1, 0, 1, -25),
                    Position = UDim2.new(0, 0, 0, 25),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    CanvasSize = UDim2.new(0, 0, 0, #mixerDisplays * 110),
                    ScrollBarThickness = 8
                }, mixerDisplays)
            }),
            
            -- Pet Selection Section
            SelectionSection = React.createElement("Frame", {
                Name = "SelectionSection",
                Size = UDim2.new(1, -40, 1, -280),
                Position = UDim2.new(0, 20, 0, 220),
                BackgroundTransparency = 1
            }, {
                SectionTitle = React.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    Text = "Select Pets to Mix",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 16,
                    TextXAlignment = Enum.TextXAlignment.Left
                }),
                
                PetGrid = React.createElement("ScrollingFrame", {
                    Size = UDim2.new(1, 0, 1, -25),
                    Position = UDim2.new(0, 0, 0, 25),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    CanvasSize = UDim2.new(0, 0, 0, math.ceil(#(playerData.Pets or {}) / 5) * 130),
                    ScrollBarThickness = 8
                }, {
                    UIGridLayout = React.createElement("UIGridLayout", {
                        CellPadding = UDim2.new(0, 10, 0, 10),
                        CellSize = UDim2.new(0, 100, 0, 120),
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Left,
                        VerticalAlignment = Enum.VerticalAlignment.Top
                    }),
                    
                    Pets = React.createElement(React.Fragment, nil, petCards)
                })
            }),
            
            -- Outcome Preview Section
            PreviewSection = mixPreview and React.createElement("Frame", {
                Name = "PreviewSection",
                Size = UDim2.new(1, -40, 0, 80),
                Position = UDim2.new(0, 20, 1, -150),
                BackgroundColor3 = Color3.fromRGB(50, 50, 50),
                BorderSizePixel = 0
            }, {
                UICorner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 8)
                }),
                
                -- Preview Title
                PreviewTitle = React.createElement("TextLabel", {
                    Size = UDim2.new(1, -20, 0, 20),
                    Position = UDim2.new(0, 10, 0, 5),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    Text = "Mix Outcome: " .. mixPreview.outputName,
                    TextColor3 = Color3.fromRGB(255, 100, 255), -- Purple for Mixed pets
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left
                }),
                
                -- Rarity Info
                RarityInfo = React.createElement("TextLabel", {
                    Size = UDim2.new(0.5, -10, 0, 20),
                    Position = UDim2.new(0, 10, 0, 25),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    Text = "Rarity: Mixed | Variation: Mixed",
                    TextColor3 = Color3.fromRGB(255, 100, 255), -- Purple for Mixed
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left
                }),
                
                -- Boost Preview
                BoostPreview = React.createElement("TextLabel", {
                    Size = UDim2.new(0.25, -10, 0, 20),
                    Position = UDim2.new(0.5, 0, 0, 25),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    Text = "Boost: " .. string.format("%.2fx", mixPreview.boost),
                    TextColor3 = Color3.fromRGB(0, 255, 0),
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left
                }),
                
                -- Value Preview (in diamonds)
                ValuePreview = React.createElement("TextLabel", {
                    Size = UDim2.new(0.25, -10, 0, 20),
                    Position = UDim2.new(0.75, 0, 0, 25),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    Text = "Value: " .. mixPreview.value .. " 💎",
                    TextColor3 = Color3.fromRGB(0, 255, 255),
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left
                }),
                
                -- Cost Info
                CostInfo = React.createElement("TextLabel", {
                    Size = UDim2.new(0.5, -10, 0, 20),
                    Position = UDim2.new(0, 10, 0, 45),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    Text = "Cost: " .. calculateDiamondCost() .. " 💎",
                    TextColor3 = (playerData.Resources and playerData.Resources.Diamonds or 0) >= calculateDiamondCost() 
                               and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 100, 100),
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left
                }),
                
                -- Note
                Note = React.createElement("TextLabel", {
                    Size = UDim2.new(0.5, -10, 0, 20),
                    Position = UDim2.new(0.5, 0, 0, 45),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    Text = "All mixed pets are 'Mixed' rarity/variation",
                    TextColor3 = Color3.fromRGB(150, 150, 150),
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
            }) or nil,
            
            -- Mix Button and Info
            MixSection = React.createElement("Frame", {
                Name = "MixSection",
                Size = UDim2.new(1, -40, 0, 50),
                Position = UDim2.new(0, 20, 1, -60),
                BackgroundTransparency = 1
            }, {
                -- Selection Info
                SelectionInfo = React.createElement("TextLabel", {
                    Size = UDim2.new(0.6, -10, 1, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    Text = string.format("Selected: %d pets (min %d, max %d) | Mix Time: %s | Cost: %d 💎", 
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
                    TextColor3 = Color3.fromRGB(200, 200, 200),
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center
                }),
                
                -- Start Mix Button
                MixButton = React.createElement("TextButton", {
                    Size = UDim2.new(0, 120, 0, 40),
                    Position = UDim2.new(1, -120, 0.5, -20),
                    BackgroundColor3 = (function()
                        local count = 0
                        for _ in pairs(selectedPets) do
                            count = count + 1
                        end
                        return count >= PetMixerConfig.MIN_PETS_PER_MIX and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(100, 100, 100)
                    end)(),
                    BorderSizePixel = 0,
                    Font = Enum.Font.GothamBold,
                    Text = "Start Mixing",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 16,
                    [React.Event.Activated] = startMixing
                }, {
                    UICorner = React.createElement("UICorner", {
                        CornerRadius = UDim.new(0, 8)
                    })
                })
            })
        }) or nil
    })
end

return PetMixerUI