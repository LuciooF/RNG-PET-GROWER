-- Shop Panel Component
-- Modern card-grid layout inspired by the GamepassPanel design
-- Shows all available pets and gamepasses with purchase options

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages.react)
local e = React.createElement

-- Import shared utilities and assets
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)
local assets = require(ReplicatedStorage.assets)

-- Import config for products
local DeveloperProductConfig = require(ReplicatedStorage.Shared.config.DeveloperProductConfig)
local GamepassConfig = require(ReplicatedStorage.Shared.config.GamepassConfig)

-- Import card components
local ShopPetCard = require(script.Parent.ui.ShopPetCard)
local ShopGamepassCard = require(script.Parent.ui.ShopGamepassCard)

-- Sound IDs for button interactions
local HOVER_SOUND_ID = "rbxassetid://15675059323"
local CLICK_SOUND_ID = "rbxassetid://6324790483"

-- Pre-create sounds for better performance
local hoverSound = Instance.new("Sound")
hoverSound.SoundId = HOVER_SOUND_ID
hoverSound.Volume = 0.3
hoverSound.Parent = SoundService

local clickSound = Instance.new("Sound")
clickSound.SoundId = CLICK_SOUND_ID
clickSound.Volume = 0.4
clickSound.Parent = SoundService

-- Function to play sound effects
local function playSound(soundType)
    if soundType == "hover" and hoverSound then
        hoverSound:Play()
    elseif soundType == "click" and clickSound then
        clickSound:Play()
    end
end

-- Function to create flip animation for icons
local function createFlipAnimation(iconRef, animationTracker)
    if not iconRef.current then return end
    
    -- Cancel any existing animation for this icon
    if animationTracker.current then
        pcall(function()
            animationTracker.current:Cancel()
        end)
        pcall(function()
            animationTracker.current:Destroy()
        end)
        animationTracker.current = nil
    end
    
    -- Reset rotation to 0 to prevent accumulation
    iconRef.current.Rotation = 0
    
    -- Create flip animation (360 degree rotation for full flip)
    local flipTween = TweenService:Create(iconRef.current,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Rotation = 360}
    )
    
    -- Store reference to current animation
    animationTracker.current = flipTween
    
    flipTween:Play()
    flipTween.Completed:Connect(function()
        -- Reset rotation after animation
        if iconRef.current then
            iconRef.current.Rotation = 0
        end
        -- Clear the tracker
        if animationTracker.current == flipTween then
            animationTracker.current = nil
        end
        flipTween:Destroy()
    end)
end

local ShopPanel = {}

-- Tab types
local TABS = {
    PETS = "Pets",
    GAMEPASSES = "Gamepasses"
}

function ShopPanel.create(props)
    local visible = props.visible or false
    local onClose = props.onClose or function() end
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    -- State for active tab
    local activeTab, setActiveTab = React.useState(TABS.PETS)
    
    -- Ref for scrolling frame to control scroll position
    local scrollFrameRef = React.useRef(nil)
    
    -- Responsive sizing
    local scale = ScreenUtils.getProportionalScale(screenSize)
    local panelWidth = math.min(screenSize.X * 0.9, ScreenUtils.getProportionalSize(screenSize, 900))
    local panelHeight = math.min(screenSize.Y * 0.8, ScreenUtils.getProportionalSize(screenSize, 600))
    
    -- Text sizes
    local titleTextSize = ScreenUtils.getProportionalTextSize(screenSize, 32)
    local smallTextSize = ScreenUtils.getProportionalTextSize(screenSize, 14)
    
    -- Card grid settings - variable sizes (fit within container bounds)
    local baseCardWidth = ScreenUtils.getProportionalSize(screenSize, 160)
    local containerHeight = panelHeight - ScreenUtils.getProportionalSize(screenSize, 120) -- Available height
    local baseCardHeight = math.floor((containerHeight - ScreenUtils.getProportionalSize(screenSize, 60)) / 2) -- Fit 2 rows with padding
    local gridRows = 2 -- 2 row grid
    local gridPadding = ScreenUtils.getProportionalSize(screenSize, 10)
    
    -- Get all products for both sections (pets and gamepasses combined)
    local petProducts = {}
    local gamepassProducts = {}
    
    -- Create pet products (8 cards with specific layout)
    local cyberDominusProduct = {
        id = 999999999,
        name = "CyberDominus",
        displayName = "🌈 Cyber Dominus",
        description = "The ultimate rainbow dominus with cosmic power!",
        type = DeveloperProductConfig.TYPES.PET,
        price = 1999,
        icon = "rbxassetid://234567890",
        petData = {
            name = "Cyber Dominus",
            assetPath = "Pets/Cyber Dominus",
            rarity = 21, -- Rainbow rarity
            value = 50000,
            description = "The most powerful dominus in existence.",
            isFlyingPet = true,
            baseBoost = 2000,
            specialEffects = {"rainbow_aura", "cosmic_power", "dominus_blessing"}
        }
    }
    
    -- Create grid layout pattern for 2 rows with exact layout:
    -- Row 1: Small, Long, Small, Small
    -- Row 2: Long, Small, Long
    local gridSizes = {
        {cols = 1, rows = 1}, -- Row 1: Small card
        {cols = 2, rows = 1}, -- Row 1: Long card
        {cols = 1, rows = 1}, -- Row 1: Small card
        {cols = 1, rows = 1}, -- Row 1: Small card
        {cols = 2, rows = 1}, -- Row 2: Long card
        {cols = 1, rows = 1}, -- Row 2: Small card
        {cols = 2, rows = 1}  -- Row 2: Long card
    }
    
    for i = 1, 7 do
        local product = {}
        for k, v in pairs(cyberDominusProduct) do
            product[k] = v
        end
        product.gridSize = gridSizes[i] or {cols = 1, rows = 1}
        product.section = "pets"
        table.insert(petProducts, product)
    end
    
    -- Create gamepass products
    local gamepasses = GamepassConfig:GetAllGamepasses()
    for _, gamepass in pairs(gamepasses) do
        gamepass.gridSize = {cols = 1, rows = 1} -- Default size for gamepasses
        gamepass.section = "gamepasses"
        table.insert(gamepassProducts, gamepass)
    end
    
    if not visible then
        return nil
    end
    
    -- Modal overlay with GamepassPanel structure
    return e("Frame", {
        Name = "ShopPanelOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ZIndex = 30
    }, {
        ShopContainer = e("Frame", {
            Name = "ShopContainer", 
            Size = UDim2.new(0, panelWidth, 0, panelHeight + ScreenUtils.getProportionalSize(screenSize, 50)),
            Position = UDim2.new(0.5, -panelWidth / 2, 0.5, -(panelHeight + ScreenUtils.getProportionalSize(screenSize, 50)) / 2),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 30
        }, {
            ShopPanel = e("Frame", {
                Name = "ShopPanel",
                Size = UDim2.new(0, panelWidth, 0, panelHeight),
                Position = UDim2.new(0, 0, 0, ScreenUtils.getProportionalSize(screenSize, 50)),
                BackgroundColor3 = Color3.fromRGB(240, 245, 255),
                BackgroundTransparency = 0.05,
                BorderSizePixel = 0,
                ZIndex = 30
            }, {
                -- Floating Title
                FloatingTitle = e("Frame", {
                    Name = "FloatingTitle",
                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 200), 0, ScreenUtils.getProportionalSize(screenSize, 40)),
                    Position = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, -10), 0, ScreenUtils.getProportionalSize(screenSize, -25)),
                    BackgroundColor3 = Color3.fromRGB(255, 140, 0),
                    BorderSizePixel = 0,
                    ZIndex = 32
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 12)
                    }),
                    Gradient = e("UIGradient", {
                        Color = ColorSequence.new{
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 160, 50)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 120, 0))
                        },
                        Rotation = 45
                    }),
                    Stroke = e("UIStroke", {
                        Color = Color3.fromRGB(255, 255, 255),
                        Thickness = 3,
                        Transparency = 0.2
                    }),
                    TitleText = e("TextLabel", {
                        Size = UDim2.new(1, -10, 1, 0),
                        Position = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 5), 0, 0),
                        Text = "🛒 PREMIUM SHOP",
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = titleTextSize,
                        TextWrapped = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold,
                        ZIndex = 33
                    }, {
                        TextStroke = e("UIStroke", {
                            Color = Color3.fromRGB(0, 0, 0),
                            Thickness = 2,
                            Transparency = 0.5
                        })
                    })
                }),
                
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 20)
                }),
                Stroke = e("UIStroke", {
                    Color = Color3.fromRGB(255, 140, 0),
                    Thickness = 3,
                    Transparency = 0.1
                }),
                Gradient = e("UIGradient", {
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(240, 250, 255)),
                        ColorSequenceKeypoint.new(0.7, Color3.fromRGB(230, 240, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 235, 255))
                    },
                    Rotation = 135
                }),
                
                -- Close Button (matching GamepassPanel style)
                CloseButton = e("ImageButton", {
                    Name = "CloseButton",
                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 32), 0, ScreenUtils.getProportionalSize(screenSize, 32)),
                    Position = UDim2.new(1, ScreenUtils.getProportionalSize(screenSize, -16), 0, ScreenUtils.getProportionalSize(screenSize, -16)),
                    Image = assets and assets["X Button/X Button 64.png"] or "",
                    ImageColor3 = Color3.fromRGB(255, 255, 255),
                    ScaleType = Enum.ScaleType.Fit,
                    BackgroundColor3 = Color3.fromRGB(255, 100, 100),
                    BorderSizePixel = 0,
                    ZIndex = 34,
                    [React.Event.Activated] = function()
                        playSound("click")
                        onClose()
                    end
                }, {
                    TextStroke = e("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = 2,
                        Transparency = 0.3,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
                    }),
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 6)
                    }),
                    Gradient = e("UIGradient", {
                        Color = ColorSequence.new{
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 140, 140)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 60, 60))
                        },
                        Rotation = 90
                    }),
                    Stroke = e("UIStroke", {
                        Color = Color3.fromRGB(255, 255, 255),
                        Thickness = 2,
                        Transparency = 0.2
                    }),
                    Shadow = e("Frame", {
                        Name = "Shadow",
                        Size = UDim2.new(1, 2, 1, 2),
                        Position = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 2), 0, ScreenUtils.getProportionalSize(screenSize, 2)),
                        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                        BackgroundTransparency = 0.7,
                        BorderSizePixel = 0,
                        ZIndex = 33
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 6)
                        })
                    })
                }),
                
                -- Tab buttons container
                TabContainer = e("Frame", {
                    Name = "TabContainer",
                    Size = UDim2.new(1, -40, 0, 35),
                    Position = UDim2.new(0, 20, 0, 20),
                    BackgroundTransparency = 1,
                    ZIndex = 31
                }, {
                    Layout = e("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Top,
                        Padding = UDim.new(0, 10)
                    }),
                    
                    PetsTab = ShopPanel.createTabButton({
                        text = "🌈 PETS",
                        isActive = activeTab == TABS.PETS,
                        onActivated = function()
                            playSound("click")
                            setActiveTab(TABS.PETS)
                            -- Scroll to pets section (beginning)
                            if scrollFrameRef.current then
                                scrollFrameRef.current.CanvasPosition = Vector2.new(0, 0)
                            end
                        end,
                        screenSize = screenSize
                    }),
                    
                    GamepassesTab = ShopPanel.createTabButton({
                        text = "💎 GAMEPASSES",
                        isActive = activeTab == TABS.GAMEPASSES,
                        onActivated = function()
                            playSound("click")
                            setActiveTab(TABS.GAMEPASSES)
                            -- Scroll to gamepasses section (calculate position based on pet section width)
                            if scrollFrameRef.current then
                                -- Calculate pets section width: 8 cards with varying sizes
                                local petsRowWidth = (1 + 2 + 1 + 1) * (baseCardWidth + gridPadding) -- Row 1: Small + Long + Small + Small
                                local gamepassSectionStart = math.max(petsRowWidth, (2 + 1 + 2 + 1) * (baseCardWidth + gridPadding)) -- Use max of both rows
                                scrollFrameRef.current.CanvasPosition = Vector2.new(gamepassSectionStart + gridPadding * 4, 0) -- Extra padding between sections
                            end
                        end,
                        screenSize = screenSize
                    })
                }),
                
                -- Subtitle
                Subtitle = e("TextLabel", {
                    Name = "Subtitle",
                    Size = UDim2.new(1, -80, 0, 25),
                    Position = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 40), 0, ScreenUtils.getProportionalSize(screenSize, 60)),
                    Text = "Scroll right to explore pets and gamepasses • Tap tabs to jump to sections",
                    TextColor3 = Color3.fromRGB(60, 80, 140),
                    TextSize = smallTextSize,
                    TextWrapped = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 31
                }),
                
                -- Cards Container (horizontal scrolling, 2 rows) - fixed to stay within bounds
                CardsContainer = e("ScrollingFrame", {
                    Name = "CardsContainer",
                    Size = UDim2.new(1, -40, 1, -ScreenUtils.getProportionalSize(screenSize, 120)), -- Dynamic height to fit panel
                    Position = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 20), 0, ScreenUtils.getProportionalSize(screenSize, 90)),
                    BackgroundColor3 = Color3.fromRGB(250, 252, 255),
                    BackgroundTransparency = 0.2,
                    BorderSizePixel = 0,
                    ScrollBarThickness = 12,
                    ScrollingDirection = Enum.ScrollingDirection.X,
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    AutomaticCanvasSize = Enum.AutomaticSize.X,
                    ScrollBarImageColor3 = Color3.fromRGB(100, 150, 255),
                    ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
                    ZIndex = 31,
                    ref = scrollFrameRef
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 15)
                    }),
                    ContainerGradient = e("UIGradient", {
                        Color = ColorSequence.new{
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(245, 250, 255))
                        },
                        Rotation = 45
                    }),
                    
                    -- No UIGridLayout - we'll position cards manually for flexible grid
                    
                    Padding = e("UIPadding", {
                        PaddingTop = UDim.new(0, ScreenUtils.getProportionalSize(screenSize, 15)),
                        PaddingLeft = UDim.new(0, ScreenUtils.getProportionalSize(screenSize, 15)),
                        PaddingRight = UDim.new(0, ScreenUtils.getProportionalSize(screenSize, 15)),
                        PaddingBottom = UDim.new(0, ScreenUtils.getProportionalSize(screenSize, 15))
                    }),
                    
                    -- Generate cards with manual grid positioning for both sections
                    Cards = React.createElement(React.Fragment, {}, (function()
                        local cards = {}
                        
                        -- Grid positioning logic for pets section (specific layout pattern)
                        local rowPositions = {0, 0} -- Track current position in each row
                        
                        -- Define which row each pet card goes in based on layout:
                        -- Row 1: Small(1), Long(2), Small(3), Small(4) 
                        -- Row 2: Long(5), Small(6), Long(7)
                        local petCardRowAssignment = {1, 1, 1, 1, 2, 2, 2}
                        
                        -- Position pet cards according to the specific pattern
                        for i, product in ipairs(petProducts) do
                            local gridSize = product.gridSize or {cols = 1, rows = 1}
                            local row = petCardRowAssignment[i] or 1
                            
                            -- Calculate actual position and size with proper scaling
                            local xPos = rowPositions[row] * (baseCardWidth + gridPadding)
                            local yPos = (row - 1) * (baseCardHeight + gridPadding)
                            local width = (gridSize.cols * baseCardWidth) + ((gridSize.cols - 1) * gridPadding)
                            local height = baseCardHeight -- Always single row height for horizontal layout
                            
                            -- Update row position
                            rowPositions[row] = rowPositions[row] + gridSize.cols
                            
                            -- Create container for positioned pet card
                            cards["PetCardContainer_" .. i] = e("Frame", {
                                Name = "PetCardContainer_" .. i,
                                Position = UDim2.new(0, xPos, 0, yPos),
                                Size = UDim2.new(0, width, 0, height),
                                BackgroundTransparency = 1,
                                ZIndex = 32
                            }, {
                                Card = e(ShopPetCard, {
                                    product = product,
                                    layoutOrder = i,
                                    screenSize = screenSize,
                                    customSize = {width = width, height = height},
                                    onPurchase = function(productData)
                                        print("Purchase pet:", productData.name)
                                        -- TODO: Connect to purchase handler
                                    end
                                })
                            })
                        end
                        
                        -- Calculate starting position for gamepasses section
                        local maxPetRowWidth = math.max(rowPositions[1], rowPositions[2])
                        local gamepassSectionStartX = maxPetRowWidth * (baseCardWidth + gridPadding) + gridPadding * 6 -- Extra spacing between sections
                        
                        -- Reset row positions for gamepasses section
                        local gamepassRowPositions = {0, 0}
                        
                        -- Position gamepass cards in a simple grid (all same size)
                        for i, gamepass in ipairs(gamepassProducts) do
                            local gridSize = gamepass.gridSize or {cols = 1, rows = 1}
                            local row = ((i - 1) % 2) + 1 -- Alternate between rows
                            
                            -- Calculate position relative to gamepass section start
                            local xPos = gamepassSectionStartX + gamepassRowPositions[row] * (baseCardWidth + gridPadding)
                            local yPos = (row - 1) * (baseCardHeight + gridPadding)
                            local width = baseCardWidth
                            local height = baseCardHeight
                            
                            -- Update gamepass row position
                            gamepassRowPositions[row] = gamepassRowPositions[row] + 1
                            
                            -- Create container for positioned gamepass card
                            cards["GamepassCardContainer_" .. i] = e("Frame", {
                                Name = "GamepassCardContainer_" .. i,
                                Position = UDim2.new(0, xPos, 0, yPos),
                                Size = UDim2.new(0, width, 0, height),
                                BackgroundTransparency = 1,
                                ZIndex = 32
                            }, {
                                Card = e(ShopGamepassCard, {
                                    gamepass = gamepass,
                                    layoutOrder = i,
                                    screenSize = screenSize,
                                    customSize = {width = width, height = height},
                                    onPurchase = function(gamepassData)
                                        print("Purchase gamepass:", gamepassData.name)
                                        -- TODO: Connect to purchase handler
                                    end
                                })
                            })
                        end
                        
                        -- Canvas width will be set automatically by AutomaticCanvasSize
                        
                        return cards
                    end)())
                })
            })
        })
    })
end

-- Create tab button (simplified for modal design)
function ShopPanel.createTabButton(props)
    local text = props.text
    local isActive = props.isActive
    local onActivated = props.onActivated
    local screenSize = props.screenSize
    
    return e("TextButton", {
        Name = "TabButton",
        Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 140), 1, 0),
        BackgroundColor3 = isActive and Color3.fromRGB(255, 140, 0) or Color3.fromRGB(200, 210, 230),
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = ScreenUtils.getProportionalTextSize(screenSize, 14),
        Font = Enum.Font.GothamBold,
        ZIndex = 32,
        [React.Event.Activated] = onActivated,
        [React.Event.MouseEnter] = function()
            if not isActive then
                playSound("hover")
            end
        end
    }, {
        Corner = e("UICorner", {
            CornerRadius = UDim.new(0, 18)
        }),
        
        Gradient = e("UIGradient", {
            Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, isActive and Color3.fromRGB(255, 160, 50) or Color3.fromRGB(220, 230, 250)),
                ColorSequenceKeypoint.new(1, isActive and Color3.fromRGB(255, 120, 0) or Color3.fromRGB(180, 190, 210))
            },
            Rotation = 45
        }),
        
        TextStroke = e("UIStroke", {
            Color = Color3.fromRGB(0, 0, 0),
            Thickness = 2,
            Transparency = 0.3
        }),
        
        Stroke = e("UIStroke", {
            Color = isActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 160, 180),
            Thickness = 2,
            Transparency = isActive and 0.2 or 0.5
        })
    })
end

-- Content creation is now handled inline in the main create function
-- This provides better integration with the grid layout system

return ShopPanel