-- Pet Boost Panel Component
-- Shows active assigned pets and their boost contributions
-- Based on BoostPanel.lua with pet-specific modifications

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

-- Import business logic controllers
local PetBoostController = require(script.Parent.Parent.services.controllers.PetBoostController)
local PetInventoryController = require(script.Parent.Parent.services.PetInventoryController)

-- Import UI components
local PetCardComponent = require(script.Parent.PetCardComponent)
local PetBoostButton = require(script.Parent.ui.PetBoostButton)
local PetBoostModal = require(script.Parent.ui.PetBoostModal)
local PetBoostEmptyState = require(script.Parent.ui.PetBoostEmptyState)

-- Use shared utility functions
local getProportionalScale = ScreenUtils.getProportionalScale
local getProportionalSize = ScreenUtils.getProportionalSize
local getProportionalTextSize = ScreenUtils.getProportionalTextSize
local getProportionalPadding = ScreenUtils.getProportionalPadding

-- Sound effects (simplified for now)
local function playSound(soundType)
    -- Placeholder for sound effects
end

-- Use shared animation helper
local createFlipAnimation = AnimationHelpers.createFlipAnimation

local function PetBoostPanel(props)
    local playerData = props.playerData or {}
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    -- Panel visibility state
    local panelVisible, setPanelVisible = React.useState(false)
    
    -- Animation refs
    local boostIconRef = React.useRef(nil)
    local boostAnimTracker = React.useRef(nil)
    
    local scale = getProportionalScale(screenSize)
    
    -- Proportional text sizes
    local titleTextSize = getProportionalTextSize(screenSize, 32)
    local normalTextSize = getProportionalTextSize(screenSize, 18)
    local smallTextSize = getProportionalTextSize(screenSize, 14)
    local buttonTextSize = getProportionalTextSize(screenSize, 16)
    local cardTitleSize = getProportionalTextSize(screenSize, 20)
    local cardValueSize = getProportionalTextSize(screenSize, 16)
    local tinyTextSize = getProportionalTextSize(screenSize, 12)
    
    -- Button sizing to match side buttons
    local buttonSize = getProportionalSize(screenSize, 55)
    
    -- Panel sizing
    local panelWidth = math.min(screenSize.X * 0.9, getProportionalSize(screenSize, 900))
    local panelHeight = math.min(screenSize.Y * 0.85, getProportionalSize(screenSize, 600))
    
    -- Get assigned pets and transform them for PetCardComponent
    local assignedPets = playerData.companionPets or {}
    local _, totalMoneyMultiplier = PetBoostController.generateBoostData(assignedPets)
    local totalBoosts = #assignedPets
    
    -- Safety check for nil values
    totalMoneyMultiplier = totalMoneyMultiplier or 1.0
    
    -- Transform assigned pets into card-compatible format
    local petItems = {}
    for i, pet in ipairs(assignedPets) do
        local petConfig = PetConfig:GetPetData(pet.id or 1)
        local auraData = PetConfig.AURAS[pet.aura or "none"] or PetConfig.AURAS.none
        local sizeData = PetConfig:GetSizeData(pet.size or 1)
        
        table.insert(petItems, {
            name = pet.name,
            id = pet.id or 1,
            pet = pet,
            quantity = 1, -- Each assigned pet shows as quantity 1
            latestCollectionTime = pet.collectedAt or 0,
            petConfig = petConfig,
            aura = pet.aura or "none",
            auraData = auraData,
            size = pet.size or 1,
            sizeData = sizeData,
            rarity = pet.rarity or 1,
            hasAssigned = true,
            assignedCount = 1,
            isAssigned = true, -- Mark individual pet as assigned for button logic
            samplePet = pet
        })
    end
    
    -- Calculate grid dimensions using boost controller
    local gridDimensions = PetBoostController.calculateBoostGridDimensions(petItems, screenSize, panelWidth)
    local cardWidth = gridDimensions.cardWidth
    local cardHeight = gridDimensions.cardHeight
    
    -- Handle panel toggle
    local function togglePanel()
        playSound("click")
        createFlipAnimation(boostIconRef, boostAnimTracker)
        setPanelVisible(not panelVisible)
    end
    
    -- Handle panel close
    local function handleClose()
        setPanelVisible(false)
    end
    
    return e("Frame", {
        Name = "PetBoostSystem",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 14
    }, {
        -- Pet Boost Button (bottom right corner)
        PetBoostButton = e("TextButton", {
            Name = "PetBoostButton",
            Size = UDim2.new(0, buttonSize, 0, buttonSize),
            Position = UDim2.new(1, -(buttonSize + getProportionalPadding(screenSize, 20)), 1, -(buttonSize + getProportionalPadding(screenSize, 20))),
            Text = "",
            BackgroundTransparency = 1, -- Remove background
            BorderSizePixel = 0,
            ZIndex = 15,
            [React.Event.Activated] = togglePanel,
            [React.Event.MouseEnter] = function()
                playSound("hover")
                createFlipAnimation(boostIconRef, boostAnimTracker)
            end
        }, {
            
            -- Pet Boost Icon (centered in circle)
            PetBoostIcon = e("ImageLabel", {
                Name = "PetBoostIcon",
                Size = UDim2.new(0, getProportionalSize(screenSize, 32), 0, getProportionalSize(screenSize, 32)),
                Position = UDim2.new(0.5, getProportionalSize(screenSize, -16), 0.5, getProportionalSize(screenSize, -16)),
                Image = assets["vector-icon-pack-2/Player/Boost/Boost Yellow Outline 256.png"] or "",
                BackgroundTransparency = 1,
                ScaleType = Enum.ScaleType.Fit,
                ImageColor3 = Color3.fromRGB(255, 150, 50), -- Orange theme for pets
                ZIndex = 16,
                ref = boostIconRef
            }),
            
            -- Pet Count Badge (top left)
            CountBadge = e("Frame", {
                Name = "CountBadge",
                Size = UDim2.new(0, getProportionalSize(screenSize, 24), 0, getProportionalSize(screenSize, 16)),
                Position = UDim2.new(0, getProportionalSize(screenSize, -6), 0, getProportionalSize(screenSize, -4)),
                BackgroundColor3 = Color3.fromRGB(255, 80, 80),
                BorderSizePixel = 0,
                ZIndex = 17
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 8)
                }),
                CountText = e("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = tostring(totalBoosts),
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = getProportionalTextSize(screenSize, 12),
                    TextWrapped = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    ZIndex = 18
                }, {
                    TextStroke = e("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = 2,
                        Transparency = 0.5
                    })
                })
            }),
            
            -- Effect Badge (bottom right)
            EffectBadge = e("Frame", {
                Name = "EffectBadge",
                Size = UDim2.new(0, getProportionalSize(screenSize, 65), 0, getProportionalSize(screenSize, 18)),
                Position = UDim2.new(1, getProportionalSize(screenSize, -60), 1, getProportionalSize(screenSize, -10)),
                BackgroundColor3 = Color3.fromRGB(80, 255, 80),
                BorderSizePixel = 0,
                ZIndex = 17
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 9)
                }),
                EffectText = e("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = PetBoostController.formatBoostPercentage(totalMoneyMultiplier),
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = getProportionalTextSize(screenSize, 11),
                    TextWrapped = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    ZIndex = 18
                }, {
                    TextStroke = e("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = 2,
                        Transparency = 0.5
                    })
                })
            })
        }),
        
        -- Pet Boost Panel Modal
        PetBoostModal = panelVisible and e("TextButton", {
            Name = "PetBoostModal",
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            ZIndex = 30,
            Text = "",
            [React.Event.Activated] = handleClose
        }, {
            PetBoostContainer = e("Frame", {
                Name = "PetBoostContainer",
                Size = UDim2.new(0, panelWidth, 0, panelHeight + 50),
                Position = UDim2.new(0.5, -panelWidth / 2, 0.5, -(panelHeight + 50) / 2),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 30
            }, {
                PetBoostPanel = e("Frame", {
                    Name = "PetBoostPanel",
                    Size = UDim2.new(0, panelWidth, 0, panelHeight),
                    Position = UDim2.new(0, 0, 0, 50),
                    BackgroundColor3 = Color3.fromRGB(240, 245, 255),
                    BackgroundTransparency = 0.05,
                    BorderSizePixel = 0,
                    ZIndex = 30
                }, {
                    -- Floating Title (Pet-themed orange)
                    FloatingTitle = e("Frame", {
                        Name = "FloatingTitle",
                        Size = UDim2.new(0, getProportionalSize(screenSize, 280), 0, getProportionalSize(screenSize, 40)),
                        Position = UDim2.new(0, -10, 0, -25),
                        BackgroundColor3 = Color3.fromRGB(255, 150, 50),
                        BorderSizePixel = 0,
                        ZIndex = 32
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
                            ZIndex = 33
                        }, {
                            Layout = e("UIListLayout", {
                                FillDirection = Enum.FillDirection.Horizontal,
                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                VerticalAlignment = Enum.VerticalAlignment.Center,
                                Padding = UDim.new(0, 5),
                                SortOrder = Enum.SortOrder.LayoutOrder
                            }),
                            
                            PetIcon = e("TextLabel", {
                                Name = "PetIcon",
                                Size = UDim2.new(0, getProportionalSize(screenSize, 24), 0, getProportionalSize(screenSize, 24)),
                                Text = "🐾",
                                BackgroundTransparency = 1,
                                TextScaled = true,
                                Font = Enum.Font.SourceSansBold,
                                ZIndex = 34,
                                LayoutOrder = 1
                            }),
                            
                            TitleText = e("TextLabel", {
                                Size = UDim2.new(0, 0, 1, 0),
                                AutomaticSize = Enum.AutomaticSize.X,
                                Text = "PET BOOSTS",
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                TextSize = titleTextSize,
                                TextWrapped = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.GothamBold,
                                ZIndex = 34,
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
                        ZIndex = 34,
                        ScaleType = Enum.ScaleType.Fit,
                        [React.Event.Activated] = handleClose,
                        [React.Event.MouseEnter] = function(button)
                            button.ImageColor3 = Color3.fromRGB(180, 180, 180)
                        end,
                        [React.Event.MouseLeave] = function(button)
                            button.ImageColor3 = Color3.fromRGB(255, 255, 255)
                        end
                    }),
                    
                    -- Subtitle
                    Subtitle = e("TextLabel", {
                        Name = "Subtitle",
                        Size = UDim2.new(1, -80, 0, 25),
                        Position = UDim2.new(0, 40, 0, 15),
                        Text = "Boosts from your assigned pets and their effects",
                        TextColor3 = Color3.fromRGB(60, 80, 140),
                        TextSize = smallTextSize,
                        TextWrapped = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ZIndex = 31
                    }),
                    
                    -- Summary Stats
                    SummaryStats = e("Frame", {
                        Name = "SummaryStats",
                        Size = UDim2.new(1, -40, 0, 30),
                        Position = UDim2.new(0, 20, 0, 45),
                        BackgroundColor3 = Color3.fromRGB(255, 240, 200),
                        BackgroundTransparency = 0.3,
                        BorderSizePixel = 0,
                        ZIndex = 31
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 10)
                        }),
                        Stroke = e("UIStroke", {
                            Color = Color3.fromRGB(255, 150, 50),
                            Thickness = 2,
                            Transparency = 0.4
                        }),
                        
                        SummaryText = e("TextLabel", {
                            Size = UDim2.new(1, -20, 1, 0),
                            Position = UDim2.new(0, 10, 0, 0),
                            Text = PetBoostController.getSummaryText(totalMoneyMultiplier, totalBoosts),
                            TextColor3 = Color3.fromRGB(80, 60, 0),
                            TextSize = normalTextSize,
                            TextWrapped = true,
                            BackgroundTransparency = 1,
                            Font = Enum.Font.GothamBold,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            ZIndex = 32
                        })
                    }),
                    
                    -- Scrollable Cards Container
                    CardsContainer = e("ScrollingFrame", {
                        Name = "CardsContainer",
                        Size = UDim2.new(1, -40, 1, -120),
                        Position = UDim2.new(0, 20, 0, 85),
                        BackgroundColor3 = Color3.fromRGB(250, 252, 255),
                        BackgroundTransparency = 0.2,
                        BorderSizePixel = 0,
                        ScrollBarThickness = 12,
                        ScrollingDirection = Enum.ScrollingDirection.Y,
                        CanvasSize = UDim2.new(0, 0, 0, totalHeight),
                        ScrollBarImageColor3 = Color3.fromRGB(255, 150, 50),
                        ZIndex = 31
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
                        
                        -- Generate pet cards using PetCardComponent (same as inventory)
                        PetBoostCards = React.createElement(React.Fragment, {}, (function()
                            local cards = {}
                            
                            -- Show enhanced empty state if no pets
                            if #petItems == 0 then
                                cards["emptyState"] = e("Frame", {
                                    Name = "EmptyState",
                                    Size = UDim2.new(1, 0, 1, 0),
                                    BackgroundTransparency = 1,
                                    ZIndex = 32
                                }, {
                                    EmptyContainer = e("Frame", {
                                        Size = UDim2.new(0, 400, 0, 300),
                                        Position = UDim2.new(0.5, -200, 0.5, -150),
                                        BackgroundColor3 = Color3.fromRGB(250, 250, 250),
                                        BackgroundTransparency = 0.3,
                                        BorderSizePixel = 0,
                                        ZIndex = 33
                                    }, {
                                        Corner = e("UICorner", {
                                            CornerRadius = UDim.new(0, 20)
                                        }),
                                        Stroke = e("UIStroke", {
                                            Color = Color3.fromRGB(200, 200, 200),
                                            Thickness = 2,
                                            Transparency = 0.5
                                        }),
                                        
                                        EmptyIcon = e("TextLabel", {
                                            Size = UDim2.new(0, 120, 0, 120),
                                            Position = UDim2.new(0.5, -60, 0, 30),
                                            Text = "🐾",
                                            TextSize = normalTextSize,
                                            TextWrapped = true,
                                            BackgroundTransparency = 1,
                                            Font = Enum.Font.SourceSansBold,
                                            ZIndex = 34
                                        }),
                                        EmptyTitle = e("TextLabel", {
                                            Size = UDim2.new(1, -40, 0, 40),
                                            Position = UDim2.new(0, 20, 0, 160),
                                            Text = "No Pets Assigned",
                                            TextColor3 = Color3.fromRGB(80, 80, 80),
                                            TextSize = normalTextSize,
                                            TextWrapped = true,
                                            BackgroundTransparency = 1,
                                            Font = Enum.Font.GothamBold,
                                            TextXAlignment = Enum.TextXAlignment.Center,
                                            ZIndex = 34
                                        }),
                                        EmptyText = e("TextLabel", {
                                            Size = UDim2.new(1, -40, 0, 60),
                                            Position = UDim2.new(0, 20, 0, 210),
                                            Text = "Assign pets from your collection to see their boosts here!\nEach assigned pet provides powerful bonuses.",
                                            TextColor3 = Color3.fromRGB(120, 120, 120),
                                            TextSize = 16,
                                            BackgroundTransparency = 1,
                                            Font = Enum.Font.Gotham,
                                            TextXAlignment = Enum.TextXAlignment.Center,
                                            TextWrapped = true,
                                            ZIndex = 34
                                        })
                                    })
                                })
                            else
                                -- Generate pet cards using PetCardComponent (same as inventory)
                                for i, petItem in ipairs(petItems) do
                                    local collectedTime = PetInventoryController.formatCollectionTime(petItem.latestCollectionTime)
                                    local displayInfo = PetInventoryController.getPetDisplayInfo(petItem)
                                    
                                    cards["pet_" .. i] = PetCardComponent({
                                        petItem = petItem,
                                        displayInfo = displayInfo,
                                        assignedPets = assignedPets,
                                        screenSize = screenSize,
                                        cardWidth = cardWidth,
                                        cardHeight = cardHeight,
                                        layoutOrder = i,
                                        collectedTime = collectedTime
                                    })
                                end
                            end
                            
                            return cards
                        end)())
                    })
                })
            })
        }) or nil
    })
end

return PetBoostPanel
