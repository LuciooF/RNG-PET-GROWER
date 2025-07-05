-- Lab Panel Component
-- Pet merging interface for combining 3 pets into a new pet
-- Allows players to select pets, see merge outcomes, and execute merges

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local React = require(ReplicatedStorage.Packages.react)
local e = React.createElement

local PetConfig = require(ReplicatedStorage.Shared.config.PetConfig)
local assets = require(ReplicatedStorage.assets)

-- Import shared utilities
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local AnimationHelpers = require(ReplicatedStorage.utils.AnimationHelpers)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)

-- Import business logic
local PetMergeController = require(ReplicatedStorage.Shared.controllers.PetMergeController)
local PetInventoryController = require(script.Parent.Parent.services.PetInventoryController)

-- Import UI components
local PetCardComponent = require(script.Parent.PetCardComponent)

-- Import services
local RewardsService = require(script.Parent.Parent.RewardsService)

-- Use shared utility functions
local getProportionalScale = ScreenUtils.getProportionalScale
local getProportionalSize = ScreenUtils.getProportionalSize
local getProportionalTextSize = ScreenUtils.getProportionalTextSize
local getProportionalPadding = ScreenUtils.getProportionalPadding

local function LabPanel(props)
    local playerData = props.playerData or {}
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local visible = props.visible or false
    local onClose = props.onClose or function() end
    
    -- Panel state
    local selectedPets, setSelectedPets = React.useState({nil, nil, nil})
    local showMergeConfirm, setShowMergeConfirm = React.useState(false)
    local merging, setMerging = React.useState(false)
    local mergeResult, setMergeResult = React.useState(nil)
    
    local scale = getProportionalScale(screenSize)
    
    -- Panel sizing (same as Pet Inventory)
    local panelWidth = math.min(screenSize.X * 0.9, getProportionalSize(screenSize, 900))
    local panelHeight = math.min(screenSize.Y * 0.85, getProportionalSize(screenSize, 600))
    
    -- Text sizes
    local titleTextSize = getProportionalTextSize(screenSize, 32)
    local normalTextSize = getProportionalTextSize(screenSize, 18)
    local smallTextSize = getProportionalTextSize(screenSize, 14)
    local buttonTextSize = getProportionalTextSize(screenSize, 16)
    
    -- Get available pets for merging (unassigned pets only)
    local availablePets = React.useMemo(function()
        local ownedPets = playerData.ownedPets or {}
        local assignedPets = playerData.companionPets or {}
        local assignedIds = {}
        
        -- Create lookup for assigned pets
        for _, assignedPet in ipairs(assignedPets) do
            assignedIds[assignedPet.uniqueId] = true
        end
        
        -- Filter to unassigned pets
        local unassignedPets = {}
        for _, pet in ipairs(ownedPets) do
            if not assignedIds[pet.uniqueId] then
                -- Transform pet data for UI compatibility
                local petConfig = PetConfig:GetPetData(pet.id or 1)
                local auraData = PetConfig.AURAS[pet.aura or "none"] or PetConfig.AURAS.none
                local sizeData = PetConfig:GetSizeData(pet.size or 1)
                
                table.insert(unassignedPets, {
                    pet = pet,
                    name = pet.name,
                    id = pet.id or 1,
                    quantity = 1,
                    petConfig = petConfig,
                    aura = pet.aura or "none",
                    auraData = auraData,
                    size = pet.size or 1,
                    sizeData = sizeData,
                    rarity = pet.rarity or 1,
                    isAssigned = false,
                    uniqueId = pet.uniqueId
                })
            end
        end
        
        -- Sort pets by combined rarity (most rare first)
        table.sort(unassignedPets, function(a, b)
            local aComprehensive = PetConfig:GetComprehensivePetInfo(a.pet.id, a.pet.aura, a.pet.size)
            local bComprehensive = PetConfig:GetComprehensivePetInfo(b.pet.id, b.pet.aura, b.pet.size)
            
            -- Get combined rarity with fallbacks
            local aRarity = (aComprehensive and aComprehensive.combinedRarity) or a.pet.rarity or 1
            local bRarity = (bComprehensive and bComprehensive.combinedRarity) or b.pet.rarity or 1
            
            -- Sort by combined rarity (higher number = more rare = should come first)
            return aRarity > bRarity
        end)
        
        return unassignedPets
    end, {playerData.ownedPets, playerData.companionPets})
    
    -- Calculate grid dimensions
    local gridDimensions = PetInventoryController.calculateGridDimensions(availablePets, screenSize, panelWidth)
    local cardWidth = gridDimensions.cardWidth
    local cardHeight = gridDimensions.cardHeight
    local totalHeight = gridDimensions.totalHeight
    
    -- Calculate merge information when pets are selected
    local mergeInfo = React.useMemo(function()
        local pet1, pet2, pet3 = selectedPets[1], selectedPets[2], selectedPets[3]
        
        if not pet1 or not pet2 or not pet3 then
            return {
                canMerge = false,
                error = "Select 3 pets to merge",
                showPreview = false
            }
        end
        
        local canMerge, error = PetMergeController.validateMergePets(pet1.pet, pet2.pet, pet3.pet)
        
        if not canMerge then
            return {
                canMerge = false,
                error = error,
                showPreview = false
            }
        end
        
        local diamondCost = PetMergeController.calculateDiamondCost(pet1.pet, pet2.pet, pet3.pet)
        local outcomes = PetMergeController.calculateMergeOutcomes(pet1.pet, pet2.pet, pet3.pet)
        local formattedOutcomes = PetMergeController.formatOutcomeInfo(outcomes)
        
        local playerDiamonds = (playerData.resources and playerData.resources.diamonds) or 0
        
        return {
            canMerge = true,
            diamondCost = diamondCost,
            outcomes = formattedOutcomes,
            hasEnoughDiamonds = playerDiamonds >= diamondCost,
            showPreview = true,
            playerDiamonds = playerDiamonds -- For debugging
        }
    end, {selectedPets, playerData.resources and playerData.resources.diamonds})
    
    -- Handle pet selection
    local function handlePetSelect(petItem)
        setSelectedPets(function(current)
            local newSelection = {current[1], current[2], current[3]}
            
            -- Find first empty slot
            for i = 1, 3 do
                if not newSelection[i] then
                    newSelection[i] = petItem
                    return newSelection
                end
            end
            
            -- All slots filled, replace first one
            newSelection[1] = petItem
            return newSelection
        end)
    end
    
    -- Handle removing selected pet
    local function handlePetRemove(slotIndex)
        setSelectedPets(function(current)
            local newSelection = {current[1], current[2], current[3]}
            newSelection[slotIndex] = nil
            return newSelection
        end)
    end
    
    -- Handle merge execution
    local function handleMerge()
        if not mergeInfo.canMerge or not mergeInfo.hasEnoughDiamonds then
            return
        end
        
        setShowMergeConfirm(true)
    end
    
    -- Handle panel close
    local function handleClose()
        setSelectedPets({nil, nil, nil})
        setShowMergeConfirm(false)
        setMerging(false)
        setMergeResult(nil)
        onClose()
    end
    
    if not visible then
        return nil
    end
    
    return e("TextButton", {
        Name = "LabModal",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ZIndex = 50,
        Text = "",
        [React.Event.Activated] = handleClose
    }, {
        LabContainer = e("Frame", {
            Name = "LabContainer",
            Size = UDim2.new(0, panelWidth, 0, panelHeight + 50),
            Position = UDim2.new(0.5, -panelWidth / 2, 0.5, -(panelHeight + 50) / 2),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 50
        }, {
            LabPanel = e("Frame", {
                Name = "LabPanel",
                Size = UDim2.new(0, panelWidth, 0, panelHeight),
                Position = UDim2.new(0, 0, 0, 50),
                BackgroundColor3 = Color3.fromRGB(240, 245, 255),
                BackgroundTransparency = 0.05,
                BorderSizePixel = 0,
                ZIndex = 50
            }, {
                -- Floating Title (orange theme like Pet Inventory)
                FloatingTitle = e("Frame", {
                    Name = "FloatingTitle",
                    Size = UDim2.new(0, getProportionalSize(screenSize, 200), 0, getProportionalSize(screenSize, 40)),
                    Position = UDim2.new(0, -10, 0, -25),
                    BackgroundColor3 = Color3.fromRGB(255, 150, 50),
                    BorderSizePixel = 0,
                    ZIndex = 52
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 12)
                    }),
                    Gradient = e("UIGradient", {
                        Color = ColorSequence.new{
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 170, 70)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 130, 30))
                        },
                        Rotation = 45
                    }),
                    Stroke = e("UIStroke", {
                        Color = Color3.fromRGB(255, 255, 255),
                        Thickness = 3,
                        Transparency = 0.2
                    }),
                    TitleContent = e("Frame", {
                        Size = UDim2.new(1, -10, 1, 0),
                        Position = UDim2.new(0, 5, 0, 0),
                        BackgroundTransparency = 1,
                        ZIndex = 53
                    }, {
                        Layout = e("UIListLayout", {
                            FillDirection = Enum.FillDirection.Horizontal,
                            HorizontalAlignment = Enum.HorizontalAlignment.Center,
                            VerticalAlignment = Enum.VerticalAlignment.Center,
                            Padding = UDim.new(0, 5),
                            SortOrder = Enum.SortOrder.LayoutOrder
                        }),
                        
                        LabIcon = e("TextLabel", {
                            Name = "LabIcon",
                            Size = UDim2.new(0, getProportionalSize(screenSize, 24), 0, getProportionalSize(screenSize, 24)),
                            Text = "🧪",
                            BackgroundTransparency = 1,
                            TextScaled = true,
                            Font = Enum.Font.SourceSansBold,
                            ZIndex = 54,
                            LayoutOrder = 1
                        }),
                        
                        TitleText = e("TextLabel", {
                            Size = UDim2.new(0, 0, 1, 0),
                            AutomaticSize = Enum.AutomaticSize.X,
                            Text = "PET LAB",
                            TextColor3 = Color3.fromRGB(255, 255, 255),
                            TextSize = titleTextSize,
                            TextWrapped = true,
                            BackgroundTransparency = 1,
                            Font = Enum.Font.GothamBold,
                            ZIndex = 54,
                            LayoutOrder = 2
                        }, {
                            TextStroke = e("UIStroke", {
                                Color = Color3.fromRGB(0, 0, 0),
                                Thickness = 2,
                                Transparency = 0.5
                            })
                        })
                    })
                }),
                
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 20)
                }),
                
                Stroke = e("UIStroke", {
                    Color = Color3.fromRGB(255, 150, 50),
                    Thickness = 3,
                    Transparency = 0.1
                }),
                
                Gradient = e("UIGradient", {
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(250, 245, 255)),
                        ColorSequenceKeypoint.new(0.7, Color3.fromRGB(245, 240, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(240, 235, 255))
                    },
                    Rotation = 135
                }),
                
                -- Close Button
                CloseButton = e("ImageButton", {
                    Name = "CloseButton",
                    Size = UDim2.new(0, getProportionalSize(screenSize, 32), 0, getProportionalSize(screenSize, 32)),
                    Position = UDim2.new(1, -16, 0, -16),
                    Image = assets["vector-icon-pack-2/UI/X Button/X Button Outline 256.png"] or "",
                    ImageColor3 = Color3.fromRGB(255, 255, 255),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ZIndex = 54,
                    ScaleType = Enum.ScaleType.Fit,
                    [React.Event.Activated] = handleClose
                }),
                
                -- Main Content Frame
                MainContent = e("Frame", {
                    Name = "MainContent",
                    Size = UDim2.new(1, -40, 1, -80),
                    Position = UDim2.new(0, 20, 0, 40),
                    BackgroundTransparency = 1,
                    ZIndex = 51
                }, {
                    Layout = e("UIListLayout", {
                        FillDirection = Enum.FillDirection.Vertical,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Top,
                        Padding = UDim.new(0, 20),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    }),
                    
                    -- Instructions
                    Instructions = e("TextLabel", {
                        Name = "Instructions",
                        Size = UDim2.new(1, 0, 0, 30),
                        Text = "Select 3 pets of the same size to merge into a powerful new pet!",
                        TextColor3 = Color3.fromRGB(60, 80, 140),
                        TextSize = normalTextSize,
                        TextWrapped = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ZIndex = 52,
                        LayoutOrder = 1
                    }),
                    
                    -- Merge Interface (3 slots + = + result)
                    MergeInterface = e("Frame", {
                        Name = "MergeInterface",
                        Size = UDim2.new(1, 0, 0, 200),
                        BackgroundColor3 = Color3.fromRGB(250, 252, 255),
                        BackgroundTransparency = 0.2,
                        BorderSizePixel = 0,
                        ZIndex = 52,
                        LayoutOrder = 2
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 15)
                        }),
                        
                        MergeLayout = e("UIListLayout", {
                            FillDirection = Enum.FillDirection.Horizontal,
                            HorizontalAlignment = Enum.HorizontalAlignment.Center,
                            VerticalAlignment = Enum.VerticalAlignment.Center,
                            Padding = UDim.new(0, 15),
                            SortOrder = Enum.SortOrder.LayoutOrder
                        }),
                        
                        Padding = e("UIPadding", {
                            PaddingTop = UDim.new(0, 20),
                            PaddingBottom = UDim.new(0, 20),
                            PaddingLeft = UDim.new(0, 20),
                            PaddingRight = UDim.new(0, 20)
                        }),
                        
                        -- Input Slots Container
                        InputSlots = e("Frame", {
                            Name = "InputSlots",
                            Size = UDim2.new(0, 450, 1, -40),
                            BackgroundTransparency = 1,
                            ZIndex = 53,
                            LayoutOrder = 1
                        }, {
                            SlotsLayout = e("UIListLayout", {
                                FillDirection = Enum.FillDirection.Horizontal,
                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                VerticalAlignment = Enum.VerticalAlignment.Center,
                                Padding = UDim.new(0, 10),
                                SortOrder = Enum.SortOrder.LayoutOrder
                            }),
                            
                            -- Generate 3 input slots
                            Slots = React.createElement(React.Fragment, {}, (function()
                                local slots = {}
                                
                                for i = 1, 3 do
                                    local selectedPet = selectedPets[i]
                                    
                                    slots["slot_" .. i] = e("Frame", {
                                        Name = "Slot" .. i,
                                        Size = UDim2.new(0, 120, 0, 160),
                                        BackgroundColor3 = selectedPet and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200),
                                        BackgroundTransparency = selectedPet and 0.1 or 0.3,
                                        BorderSizePixel = 0,
                                        ZIndex = 54,
                                        LayoutOrder = i
                                    }, {
                                        Corner = e("UICorner", {
                                            CornerRadius = UDim.new(0, 12)
                                        }),
                                        Stroke = e("UIStroke", {
                                            Color = selectedPet and Color3.fromRGB(255, 150, 50) or Color3.fromRGB(150, 150, 150),
                                            Thickness = 2,
                                            Transparency = 0.2
                                        }),
                                        
                                        -- Content based on whether pet is selected
                                        Content = selectedPet and e("Frame", {
                                            Size = UDim2.new(1, -10, 1, -10),
                                            Position = UDim2.new(0, 5, 0, 5),
                                            BackgroundTransparency = 1,
                                            ZIndex = 55
                                        }, {
                                            Layout = e("UIListLayout", {
                                                FillDirection = Enum.FillDirection.Vertical,
                                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                                VerticalAlignment = Enum.VerticalAlignment.Top,
                                                Padding = UDim.new(0, 5),
                                                SortOrder = Enum.SortOrder.LayoutOrder
                                            }),
                                            
                                            -- Pet Name
                                            PetName = e("TextLabel", {
                                                Size = UDim2.new(1, 0, 0, 20),
                                                Text = selectedPet.name,
                                                TextColor3 = Color3.fromRGB(60, 80, 140),
                                                TextSize = getProportionalTextSize(screenSize, 13),
                                                TextWrapped = true,
                                                BackgroundTransparency = 1,
                                                Font = Enum.Font.GothamBold,
                                                TextXAlignment = Enum.TextXAlignment.Center,
                                                ZIndex = 56,
                                                LayoutOrder = 1
                                            }),
                                            
                                            -- Pet Image (using AssetLoader)
                                            PetImage = (function()
                                                local AssetLoader = require(ReplicatedStorage.utils.AssetLoader)
                                                local petModel = AssetLoader.loadPetModel(selectedPet.petConfig.assetPath)
                                                
                                                if petModel then
                                                    return e("ViewportFrame", {
                                                        Size = UDim2.new(0, 80, 0, 80),
                                                        BackgroundTransparency = 1,
                                                        BorderSizePixel = 0,
                                                        ZIndex = 56,
                                                        LayoutOrder = 2,
                                                        ref = function(viewportFrame)
                                                            if viewportFrame and petModel then
                                                                local clonedModel = petModel:Clone()
                                                                clonedModel.Parent = viewportFrame
                                                                
                                                                local camera = Instance.new("Camera")
                                                                camera.Parent = viewportFrame
                                                                viewportFrame.CurrentCamera = camera
                                                                
                                                                local cf, size = clonedModel:GetBoundingBox()
                                                                local maxExtent = math.max(size.X, size.Y, size.Z)
                                                                local cameraDistance = maxExtent * 1.5
                                                                camera.CFrame = CFrame.lookAt(
                                                                    cf.Position + Vector3.new(cameraDistance * -1.75, cameraDistance * 0.3, -cameraDistance),
                                                                    cf.Position
                                                                )
                                                            end
                                                        end
                                                    })
                                                else
                                                    return e("TextLabel", {
                                                        Size = UDim2.new(0, 80, 0, 80),
                                                        Text = "🐾",
                                                        TextSize = getProportionalTextSize(screenSize, 24),
                                                        BackgroundTransparency = 1,
                                                        Font = Enum.Font.SourceSansBold,
                                                        TextXAlignment = Enum.TextXAlignment.Center,
                                                        TextYAlignment = Enum.TextYAlignment.Center,
                                                        ZIndex = 56,
                                                        LayoutOrder = 2
                                                    })
                                                end
                                            end)(),
                                            
                                            -- Pet Size
                                            PetSize = e("TextLabel", {
                                                Size = UDim2.new(1, 0, 0, 20),
                                                Text = selectedPet.sizeData.displayName,
                                                TextColor3 = selectedPet.sizeData.color,
                                                TextSize = getProportionalTextSize(screenSize, 12),
                                                TextWrapped = true,
                                                BackgroundTransparency = 1,
                                                Font = Enum.Font.GothamBold,
                                                TextXAlignment = Enum.TextXAlignment.Center,
                                                ZIndex = 56,
                                                LayoutOrder = 3
                                            }),
                                            
                                            -- Remove Button (positioned absolutely)
                                            RemoveButton = e("ImageButton", {
                                                Size = UDim2.new(0, 24, 0, 24),
                                                Position = UDim2.new(1, -27, 0, 3),
                                                AnchorPoint = Vector2.new(0, 0),
                                                Image = assets["vector-icon-pack-2/UI/X Button/X Button Outline 256.png"] or "",
                                                ImageColor3 = Color3.fromRGB(255, 100, 100),
                                                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                                BackgroundTransparency = 0.1,
                                                BorderSizePixel = 0,
                                                ScaleType = Enum.ScaleType.Fit,
                                                ZIndex = 57,
                                                [React.Event.Activated] = function()
                                                    handlePetRemove(i)
                                                end
                                            }, {
                                                Corner = e("UICorner", {
                                                    CornerRadius = UDim.new(0, 12)
                                                }),
                                                Stroke = e("UIStroke", {
                                                    Color = Color3.fromRGB(255, 100, 100),
                                                    Thickness = 1,
                                                    Transparency = 0.3
                                                }),
                                                -- Fallback text if image doesn't load
                                                FallbackText = e("TextLabel", {
                                                    Size = UDim2.new(1, 0, 1, 0),
                                                    Text = "✕",
                                                    TextColor3 = Color3.fromRGB(255, 100, 100),
                                                    TextSize = getProportionalTextSize(screenSize, 12),
                                                    BackgroundTransparency = 1,
                                                    Font = Enum.Font.GothamBold,
                                                    TextXAlignment = Enum.TextXAlignment.Center,
                                                    TextYAlignment = Enum.TextYAlignment.Center,
                                                    ZIndex = 58,
                                                    Visible = not assets["vector-icon-pack-2/UI/X Button/X Button Outline 256.png"] or assets["vector-icon-pack-2/UI/X Button/X Button Outline 256.png"] == ""
                                                })
                                            })
                                        }) or e("TextLabel", {
                                            Size = UDim2.new(1, 0, 1, 0),
                                            Text = "Empty Slot " .. i,
                                            TextColor3 = Color3.fromRGB(150, 150, 150),
                                            TextSize = smallTextSize,
                                            BackgroundTransparency = 1,
                                            Font = Enum.Font.Gotham,
                                            TextXAlignment = Enum.TextXAlignment.Center,
                                            TextYAlignment = Enum.TextYAlignment.Center,
                                            ZIndex = 55
                                        })
                                    })
                                end
                                
                                return slots
                            end)())
                        }),
                        
                        -- Equals Sign
                        EqualsSign = e("TextLabel", {
                            Name = "EqualsSign",
                            Size = UDim2.new(0, 40, 0, 40),
                            Text = "=",
                            TextColor3 = Color3.fromRGB(255, 150, 50),
                            TextSize = getProportionalTextSize(screenSize, 32),
                            BackgroundTransparency = 1,
                            Font = Enum.Font.GothamBold,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            TextYAlignment = Enum.TextYAlignment.Center,
                            ZIndex = 53,
                            LayoutOrder = 2
                        }),
                        
                        -- Result Slot with Chances (same height as input slots)
                        ResultSlot = e("Frame", {
                            Name = "ResultSlot",
                            Size = UDim2.new(0, 400, 0, 160), -- Same height as input slots
                            BackgroundColor3 = mergeInfo.showPreview and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(230, 230, 230),
                            BackgroundTransparency = mergeInfo.showPreview and 0.1 or 0.3,
                            BorderSizePixel = 0,
                            ZIndex = 53,
                            LayoutOrder = 3
                        }, {
                            Corner = e("UICorner", {
                                CornerRadius = UDim.new(0, 12)
                            }),
                            Stroke = e("UIStroke", {
                                Color = mergeInfo.showPreview and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(150, 150, 150),
                                Thickness = 2,
                                Transparency = 0.2
                            }),
                            
                            Content = mergeInfo.showPreview and e("Frame", {
                                Size = UDim2.new(1, -20, 1, -20),
                                Position = UDim2.new(0, 10, 0, 10),
                                BackgroundTransparency = 1,
                                ZIndex = 54
                            }, {
                                Layout = e("UIListLayout", {
                                    FillDirection = Enum.FillDirection.Horizontal,
                                    HorizontalAlignment = Enum.HorizontalAlignment.Left,
                                    VerticalAlignment = Enum.VerticalAlignment.Center,
                                    Padding = UDim.new(0, 15),
                                    SortOrder = Enum.SortOrder.LayoutOrder
                                }),
                                
                                -- Pet Preview (Left side) - Format: Name → Image → Size
                                PetPreview = e("Frame", {
                                    Name = "PetPreview",
                                    Size = UDim2.new(0, 120, 1, 0),
                                    BackgroundColor3 = Color3.fromRGB(240, 240, 240),
                                    BackgroundTransparency = 0.3,
                                    BorderSizePixel = 0,
                                    ZIndex = 55,
                                    LayoutOrder = 1
                                }, {
                                    Corner = e("UICorner", {
                                        CornerRadius = UDim.new(0, 10)
                                    }),
                                    
                                    Layout = e("UIListLayout", {
                                        FillDirection = Enum.FillDirection.Vertical,
                                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                        VerticalAlignment = Enum.VerticalAlignment.Top,
                                        Padding = UDim.new(0, 5),
                                        SortOrder = Enum.SortOrder.LayoutOrder
                                    }),
                                    
                                    Padding = e("UIPadding", {
                                        PaddingTop = UDim.new(0, 5),
                                        PaddingBottom = UDim.new(0, 5),
                                        PaddingLeft = UDim.new(0, 5),
                                        PaddingRight = UDim.new(0, 5)
                                    }),
                                    
                                    -- Pet Name
                                    PetName = e("TextLabel", {
                                        Size = UDim2.new(1, 0, 0, 20),
                                        Text = "Sinister Hydra",
                                        TextColor3 = Color3.fromRGB(60, 80, 140),
                                        TextSize = getProportionalTextSize(screenSize, 13),
                                        TextWrapped = true,
                                        BackgroundTransparency = 1,
                                        Font = Enum.Font.GothamBold,
                                        TextXAlignment = Enum.TextXAlignment.Center,
                                        ZIndex = 56,
                                        LayoutOrder = 1
                                    }),
                                    
                                    -- Pet Image (Sinister Hydra)
                                    PetImage = (function()
                                        local AssetLoader = require(ReplicatedStorage.utils.AssetLoader)
                                        local petModel = AssetLoader.loadPetModel("Pets/Sinister Hydra")
                                        
                                        if petModel then
                                            return e("ViewportFrame", {
                                                Size = UDim2.new(0, 80, 0, 80),
                                                BackgroundTransparency = 1,
                                                BorderSizePixel = 0,
                                                ZIndex = 56,
                                                LayoutOrder = 2,
                                                ref = function(viewportFrame)
                                                    if viewportFrame and petModel then
                                                        local clonedModel = petModel:Clone()
                                                        clonedModel.Parent = viewportFrame
                                                        
                                                        local camera = Instance.new("Camera")
                                                        camera.Parent = viewportFrame
                                                        viewportFrame.CurrentCamera = camera
                                                        
                                                        local cf, size = clonedModel:GetBoundingBox()
                                                        local maxExtent = math.max(size.X, size.Y, size.Z)
                                                        local cameraDistance = maxExtent * 1.5
                                                        camera.CFrame = CFrame.lookAt(
                                                            cf.Position + Vector3.new(cameraDistance * -1.75, cameraDistance * 0.3, -cameraDistance),
                                                            cf.Position
                                                        )
                                                    end
                                                end
                                            })
                                        else
                                            return e("TextLabel", {
                                                Size = UDim2.new(0, 80, 0, 80),
                                                Text = "🐉",
                                                TextSize = getProportionalTextSize(screenSize, 24),
                                                BackgroundTransparency = 1,
                                                Font = Enum.Font.SourceSansBold,
                                                TextXAlignment = Enum.TextXAlignment.Center,
                                                TextYAlignment = Enum.TextYAlignment.Center,
                                                ZIndex = 56,
                                                LayoutOrder = 2
                                            })
                                        end
                                    end)(),
                                    
                                    -- Size (based on input pets)
                                    PetSize = e("TextLabel", {
                                        Size = UDim2.new(1, 0, 0, 20),
                                        Text = selectedPets[1] and selectedPets[1].sizeData.displayName or "Tiny",
                                        TextColor3 = selectedPets[1] and selectedPets[1].sizeData.color or Color3.fromRGB(150, 150, 150),
                                        TextSize = getProportionalTextSize(screenSize, 12),
                                        TextWrapped = true,
                                        BackgroundTransparency = 1,
                                        Font = Enum.Font.GothamBold,
                                        TextXAlignment = Enum.TextXAlignment.Center,
                                        ZIndex = 56,
                                        LayoutOrder = 3
                                    })
                                }),
                                
                                -- Merge Outcomes (Right side)
                                OutcomesPanel = e("Frame", {
                                    Name = "OutcomesPanel",
                                    Size = UDim2.new(0, 240, 1, 0),
                                    BackgroundTransparency = 1,
                                    ZIndex = 55,
                                    LayoutOrder = 2
                                }, {
                                    OutcomesTitle = e("TextLabel", {
                                        Size = UDim2.new(1, 0, 0, 25),
                                        Position = UDim2.new(0, 0, 0, 0),
                                        Text = "MERGE OUTCOMES",
                                        TextColor3 = Color3.fromRGB(60, 80, 140),
                                        TextSize = getProportionalTextSize(screenSize, 12),
                                        BackgroundTransparency = 1,
                                        Font = Enum.Font.GothamBold,
                                        TextXAlignment = Enum.TextXAlignment.Center,
                                        ZIndex = 56
                                    }),
                                    
                                    OutcomesList = e("ScrollingFrame", {
                                        Size = UDim2.new(1, 0, 1, -30),
                                        Position = UDim2.new(0, 0, 0, 25),
                                        BackgroundTransparency = 1,
                                        BorderSizePixel = 0,
                                        ScrollBarThickness = 4,
                                        ScrollingDirection = Enum.ScrollingDirection.Y,
                                        CanvasSize = UDim2.new(0, 0, 0, #(mergeInfo.outcomes or {}) * 25),
                                        ZIndex = 56
                                    }, {
                                        Layout = e("UIListLayout", {
                                            FillDirection = Enum.FillDirection.Vertical,
                                            HorizontalAlignment = Enum.HorizontalAlignment.Left,
                                            VerticalAlignment = Enum.VerticalAlignment.Top,
                                            Padding = UDim.new(0, 2),
                                            SortOrder = Enum.SortOrder.LayoutOrder
                                        }),
                                        
                                        Outcomes = React.createElement(React.Fragment, {}, (function()
                                            local outcomeElements = {}
                                            
                                            if mergeInfo.outcomes then
                                                for i, outcome in ipairs(mergeInfo.outcomes) do
                                                    outcomeElements["outcome_" .. i] = e("Frame", {
                                                        Size = UDim2.new(1, 0, 0, 20),
                                                        BackgroundTransparency = 1,
                                                        ZIndex = 57,
                                                        LayoutOrder = i
                                                    }, {
                                                        OutcomeText = e("TextLabel", {
                                                            Size = UDim2.new(1, 0, 1, 0),
                                                            Text = string.format("%s: %s", outcome.chance, outcome.title),
                                                            TextColor3 = outcome.color or Color3.fromRGB(100, 120, 160),
                                                            TextSize = getProportionalTextSize(screenSize, 10),
                                                            TextWrapped = true,
                                                            BackgroundTransparency = 1,
                                                            Font = Enum.Font.GothamBold,
                                                            TextXAlignment = Enum.TextXAlignment.Center,
                                                            ZIndex = 58
                                                        }, {
                                                            -- Black text outline
                                                            TextStroke = e("UIStroke", {
                                                                Color = Color3.fromRGB(0, 0, 0),
                                                                Thickness = 1.5,
                                                                Transparency = 0.4,
                                                                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
                                                            })
                                                        })
                                                    })
                                                end
                                            end
                                            
                                            return outcomeElements
                                        end)())
                                    })
                                })
                            }) or e("TextLabel", {
                                Size = UDim2.new(1, 0, 1, 0),
                                Text = "Select 3 pets to see merge preview",
                                TextColor3 = Color3.fromRGB(150, 150, 150),
                                TextSize = normalTextSize,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.Gotham,
                                TextXAlignment = Enum.TextXAlignment.Center,
                                TextYAlignment = Enum.TextYAlignment.Center,
                                ZIndex = 54
                            })
                        })
                    }),
                    
                    -- Merge Button (always show, but disabled when conditions not met)
                    MergeButton = e("TextButton", {
                        Name = "MergeButton",
                        Size = UDim2.new(0, 240, 0, 60),
                        Text = merging and "MERGING..." or 
                               (not mergeInfo.canMerge and "SELECT 3 PETS") or
                               (not mergeInfo.hasEnoughDiamonds and string.format("NEED %s", NumberFormatter.format(mergeInfo.diamondCost or 0))) or
                               string.format("MERGE FOR %s", NumberFormatter.format(mergeInfo.diamondCost or 0)),
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = buttonTextSize,
                        BackgroundColor3 = (mergeInfo.canMerge and mergeInfo.hasEnoughDiamonds and not merging) and 
                                          Color3.fromRGB(100, 255, 100) or 
                                          (mergeInfo.canMerge and not mergeInfo.hasEnoughDiamonds) and 
                                          Color3.fromRGB(255, 150, 50) or 
                                          Color3.fromRGB(150, 150, 150),
                        BorderSizePixel = 0,
                        Font = Enum.Font.GothamBold,
                        ZIndex = 52,
                        LayoutOrder = 3,
                        Active = mergeInfo.canMerge and mergeInfo.hasEnoughDiamonds and not merging,
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        TextStrokeTransparency = 0.3,
                        [React.Event.Activated] = function()
                            print("LabPanel: Merge button clicked!")
                            print("LabPanel: canMerge =", mergeInfo.canMerge)
                            print("LabPanel: hasEnoughDiamonds =", mergeInfo.hasEnoughDiamonds)
                            print("LabPanel: merging =", merging)
                            print("LabPanel: diamondCost =", mergeInfo.diamondCost)
                            print("LabPanel: playerDiamonds =", mergeInfo.playerDiamonds)
                            print("LabPanel: selectedPets count =", #selectedPets)
                            
                            if mergeInfo.canMerge and mergeInfo.hasEnoughDiamonds and not merging then
                                print("LabPanel: Calling handleMerge()...")
                                handleMerge()
                            else
                                print("LabPanel: Merge conditions not met")
                                if not mergeInfo.canMerge then
                                    print("LabPanel: Cannot merge pets")
                                end
                                if not mergeInfo.hasEnoughDiamonds then
                                    print("LabPanel: Not enough diamonds")
                                end
                                if merging then
                                    print("LabPanel: Already merging")
                                end
                            end
                        end
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 12)
                        }),
                        Stroke = e("UIStroke", {
                            Color = Color3.fromRGB(255, 255, 255),
                            Thickness = 2,
                            Transparency = 0.3
                        }),
                        
                        -- Diamond icon (only show when we have cost info)
                        DiamondIcon = (mergeInfo.canMerge and mergeInfo.diamondCost and mergeInfo.diamondCost > 0) and e("ImageLabel", {
                            Name = "DiamondIcon",
                            Size = UDim2.new(0, 24, 0, 24),
                            Position = UDim2.new(1, -30, 0.5, -12),
                            Image = assets["vector-icon-pack-2/General/Diamond/Diamond Filled 256.png"] or "",
                            BackgroundTransparency = 1,
                            ScaleType = Enum.ScaleType.Fit,
                            ImageColor3 = Color3.fromRGB(150, 220, 255),
                            ZIndex = 53
                        }) or nil
                    }),
                    
                    -- Available Pets Grid
                    CardsContainer = e("ScrollingFrame", {
                        Name = "CardsContainer",
                        Size = UDim2.new(1, 0, 1, -280),
                        BackgroundColor3 = Color3.fromRGB(250, 252, 255),
                        BackgroundTransparency = 0.2,
                        BorderSizePixel = 0,
                        ScrollBarThickness = 12,
                        ScrollingDirection = Enum.ScrollingDirection.Y,
                        CanvasSize = UDim2.new(0, 0, 0, totalHeight),
                        ScrollBarImageColor3 = Color3.fromRGB(255, 150, 50),
                        ZIndex = 52,
                        LayoutOrder = 4
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 15)
                        }),
                        ContainerGradient = e("UIGradient", {
                            Color = ColorSequence.new{
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 250, 245))
                            },
                            Rotation = 45
                        }),
                        
                        -- Grid Layout
                        GridLayout = e("UIGridLayout", {
                            CellSize = UDim2.new(0, cardWidth, 0, cardHeight),
                            CellPadding = UDim2.new(0, 20, 0, 20),
                            FillDirection = Enum.FillDirection.Horizontal,
                            HorizontalAlignment = Enum.HorizontalAlignment.Center,
                            VerticalAlignment = Enum.VerticalAlignment.Top,
                            SortOrder = Enum.SortOrder.LayoutOrder
                        }),
                        
                        Padding = e("UIPadding", {
                            PaddingTop = UDim.new(0, 20),
                            PaddingLeft = UDim.new(0, 20),
                            PaddingRight = UDim.new(0, 20),
                            PaddingBottom = UDim.new(0, 20)
                        }),
                        
                        -- Generate pet cards
                        PetCards = React.createElement(React.Fragment, {}, (function()
                            local cards = {}
                            
                            if #availablePets == 0 then
                                cards["noPets"] = e("Frame", {
                                    Name = "NoPetsMessage",
                                    Size = UDim2.new(1, 0, 0, 100),
                                    BackgroundTransparency = 1,
                                    ZIndex = 53
                                }, {
                                    Message = e("TextLabel", {
                                        Size = UDim2.new(1, 0, 1, 0),
                                        Text = "No unassigned pets available for merging.\nUnassign some pets to use them in the Lab!",
                                        TextColor3 = Color3.fromRGB(150, 150, 150),
                                        TextSize = normalTextSize,
                                        TextWrapped = true,
                                        BackgroundTransparency = 1,
                                        Font = Enum.Font.Gotham,
                                        TextXAlignment = Enum.TextXAlignment.Center,
                                        TextYAlignment = Enum.TextYAlignment.Center,
                                        ZIndex = 54
                                    })
                                })
                            else
                                for i, petItem in ipairs(availablePets) do
                                    local displayInfo = PetInventoryController.getPetDisplayInfo(petItem)
                                    
                                    -- Create pet card with lab-specific click handler
                                    cards["pet_" .. i] = e("Frame", {
                                        Name = "SelectPetContainer_" .. i,
                                        Size = UDim2.new(0, cardWidth, 0, cardHeight),
                                        BackgroundTransparency = 1,
                                        BorderSizePixel = 0,
                                        ZIndex = 54,
                                        LayoutOrder = i
                                    }, {
                                        -- Use PetCardComponent but hide assign button and override click
                                        PetCard = PetCardComponent({
                                            petItem = petItem,
                                            displayInfo = displayInfo,
                                            assignedPets = {},
                                            screenSize = screenSize,
                                            cardWidth = cardWidth,
                                            cardHeight = cardHeight,
                                            layoutOrder = 1,
                                            collectedTime = "",
                                            hideAssignButton = true, -- Hide the assign button in lab mode
                                            onLabSelect = function() -- Add lab-specific selection handler
                                                handlePetSelect(petItem)
                                            end
                                        })
                                    })
                                end
                            end
                            
                            return cards
                        end)())
                    })
                })
            })
        }),
        
        -- Merge Confirmation Modal
        MergeConfirmModal = showMergeConfirm and e("Frame", {
            Name = "MergeConfirmModal",
            Size = UDim2.new(0, 400, 0, 300),
            Position = UDim2.new(0.5, -200, 0.5, -150),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 60
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 20)
            }),
            ConfirmText = e("TextLabel", {
                Size = UDim2.new(1, -40, 0, 60),
                Position = UDim2.new(0, 20, 0, 20),
                Text = "Are you sure you want to merge these pets?\nThis action cannot be undone!",
                TextColor3 = Color3.fromRGB(60, 80, 140),
                TextSize = normalTextSize,
                TextWrapped = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 61
            }),
            
            ConfirmButton = e("TextButton", {
                Size = UDim2.new(0, 150, 0, 40),
                Position = UDim2.new(0, 50, 1, -80),
                Text = merging and "MERGING..." or "CONFIRM MERGE",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = buttonTextSize,
                BackgroundColor3 = merging and Color3.fromRGB(150, 150, 150) or Color3.fromRGB(100, 255, 100),
                BorderSizePixel = 0,
                Font = Enum.Font.GothamBold,
                ZIndex = 61,
                Active = not merging,
                [React.Event.Activated] = function()
                    -- Execute the merge
                    setMerging(true)
                    setShowMergeConfirm(false)
                    
                    -- Get the pets to merge
                    local pet1, pet2, pet3 = selectedPets[1], selectedPets[2], selectedPets[3]
                    if not pet1 or not pet2 or not pet3 then
                        setMerging(false)
                        return
                    end
                    
                    -- Send merge request to server
                    local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
                    if remotes then
                        local petMergeRemote = remotes:WaitForChild("MergePets", 5)
                        if petMergeRemote then
                            petMergeRemote:FireServer({
                                petIds = {
                                    pet1.pet.uniqueId,
                                    pet2.pet.uniqueId,
                                    pet3.pet.uniqueId
                                }
                            })
                            
                            -- Listen for merge result
                            local connection
                            connection = petMergeRemote.OnClientEvent:Connect(function(result)
                                connection:Disconnect()
                                setMerging(false)
                                
                                if result.success then
                                    -- Show reward with RewardsService
                                    RewardsService.showPetReward("merged", result.newPet.name)
                                    
                                    -- Clear selected pets and close panel
                                    setSelectedPets({nil, nil, nil})
                                    onClose()
                                else
                                    -- Show error (could enhance this with a toast notification)
                                    warn("Merge failed:", result.error)
                                end
                            end)
                        else
                            warn("PetMerge remote not found!")
                            setMerging(false)
                        end
                    else
                        warn("Remotes folder not found!")
                        setMerging(false)
                    end
                end
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 10)
                })
            }),
            
            CancelButton = e("TextButton", {
                Size = UDim2.new(0, 150, 0, 40),
                Position = UDim2.new(0, 220, 1, -80),
                Text = "CANCEL",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = buttonTextSize,
                BackgroundColor3 = Color3.fromRGB(255, 100, 100),
                BorderSizePixel = 0,
                Font = Enum.Font.GothamBold,
                ZIndex = 61,
                [React.Event.Activated] = function()
                    setShowMergeConfirm(false)
                end
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 10)
                })
            })
        }) or nil
    })
end

return LabPanel