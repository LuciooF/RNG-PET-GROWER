-- BoostPanel - React component for detailed boost breakdown display with tabs and cards
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local React = require(ReplicatedStorage.Packages.react)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)
local DataSyncService = require(script.Parent.Parent.services.DataSyncService)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local BoostCalculator = require(ReplicatedStorage.utils.BoostCalculator)
local PotionConfig = require(ReplicatedStorage.config.PotionConfig)

local BOOST_TYPES = {
    MONEY = "Money",
    DIAMONDS = "Diamonds"
}

-- Sound constants
local HOVER_SOUND_ID = "rbxassetid://6895079853"
local CLICK_SOUND_ID = "rbxassetid://876939830"

-- Pre-create hover sound for instant playback
local hoverSound = Instance.new("Sound")
hoverSound.SoundId = HOVER_SOUND_ID
hoverSound.Volume = 0.5
hoverSound.Parent = SoundService

-- Pre-create click sound
local clickSound = Instance.new("Sound")
clickSound.SoundId = CLICK_SOUND_ID
clickSound.Volume = 0.6
clickSound.Parent = SoundService

-- Play hover sound instantly
local function playHoverSound()
    hoverSound:Play()
end

-- Play click sound
local function playClickSound()
    clickSound:Play()
end

local function BoostPanel(props)
    -- Tab state management
    local selectedTab, setSelectedTab = React.useState(BOOST_TYPES.MONEY)
    
    -- Subscribe to player data for boost calculation
    local playerData, setPlayerData = React.useState({
        EquippedPets = {},
        OPPets = {},
        OwnedGamepasses = {},
        ActivePotions = {}
    })
    
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
        
        return function()
            if unsubscribe and type(unsubscribe) == "function" then
                unsubscribe()
            end
        end
    end, {})
    
    -- Use centralized boost calculation
    local boostBreakdown = BoostCalculator.getBoostBreakdown(playerData)
    
    -- Helper function to create boost cards
    local function createBoostCard(boostData, layoutOrder)
        if not boostData or boostData.multiplier <= 1 then
            return nil
        end
        
        local cardSize = ScreenUtils.getProportionalSize(180) -- Bigger cards
        
        return React.createElement("Frame", {
            Name = "BoostCard" .. layoutOrder,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255), -- White background like pet cards
            BorderSizePixel = 0,
            LayoutOrder = layoutOrder,
            Size = UDim2.new(0, cardSize, 0, cardSize),
            ZIndex = 202,
        }, {
            -- Card corner radius
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(12)),
            }),
            
            -- Card outline
            CardOutline = React.createElement("UIStroke", {
                Thickness = ScreenUtils.getProportionalSize(2),
                Color = boostData.color or Color3.fromRGB(0, 0, 0),
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }),
            
            -- Icon container
            IconContainer = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 0.6, 0), -- Top 60% for icon
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                ZIndex = 203,
            }, {
                -- Icon image
                Icon = React.createElement("ImageLabel", {
                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(80), 0, ScreenUtils.getProportionalSize(80)), -- Bigger icon
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = boostData.icon,
                    ScaleType = Enum.ScaleType.Fit,
                    ImageColor3 = boostData.noTint and Color3.fromRGB(255, 255, 255) or (boostData.iconColor or Color3.fromRGB(255, 255, 255)),
                    ZIndex = 204,
                })
            }),
            
            -- Text container
            TextContainer = React.createElement("Frame", {
                Size = UDim2.new(1, -ScreenUtils.getProportionalSize(10), 0.4, 0), -- Bottom 40% for text
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(5), 0.6, 0),
                BackgroundTransparency = 1,
                ZIndex = 203,
            }, {
                -- Boost multiplier text
                BoostText = React.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 0.6, 0),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Text = NumberFormatter.formatBoost(boostData.multiplier) .. "x",
                    TextColor3 = boostData.color or Color3.fromRGB(0, 0, 0),
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextScaled = true,
                    ZIndex = 204,
                }),
                
                -- Label text (white with black outline)
                LabelText = React.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 0.4, 0),
                    Position = UDim2.new(0, 0, 0.6, 0),
                    BackgroundTransparency = 1,
                    Text = boostData.label,
                    TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                    TextSize = ScreenUtils.TEXT_SIZES.SMALL(),
                    Font = Enum.Font.FredokaOne, -- Fredoka One font
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextScaled = true,
                    TextStrokeTransparency = 0, -- Black outline
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0), -- Black stroke
                    ZIndex = 204,
                })
            })
        })
    end
    
    -- Function to get boost cards for the selected tab
    local function getBoostCards(boostType)
        local boostData = {} -- Store all boost data with multipliers for sorting
        
        -- Only show pet boosts for Money tab
        if boostType == BOOST_TYPES.MONEY then
            -- Pet Boosts
            if boostBreakdown.petBoost > 1 then
                table.insert(boostData, {
                    multiplier = boostBreakdown.petBoost,
                    label = "Pets (" .. boostBreakdown.petCount .. ")",
                    icon = IconAssets.getIcon("UI", "PET2"),
                    color = Color3.fromRGB(50, 200, 100),
                    noTint = true, -- Don't tint pet icons
                    key = "PetBoost"
                })
            end
            
            -- OP Pet Boosts
            if boostBreakdown.opPetBoost > 1 then
                table.insert(boostData, {
                    multiplier = boostBreakdown.opPetBoost,
                    label = "OP Pets (" .. boostBreakdown.opPetCount .. ")",
                    icon = IconAssets.getIcon("UI", "PET2"),
                    color = Color3.fromRGB(255, 0, 255), -- Magenta for OP
                    noTint = true, -- Don't tint pet icons
                    key = "OPPetBoost"
                })
            end
        end
        
        -- Gamepass Boosts
        local gamepasses = {}
        for _, gamepassName in pairs(playerData.OwnedGamepasses or {}) do
            gamepasses[gamepassName] = true
        end
        
        -- VIP Boost (affects both Money and Diamonds)
        if gamepasses.VIP then
            table.insert(boostData, {
                multiplier = 2, -- VIP is 2x
                label = "VIP",
                icon = IconAssets.getIcon("UI", "VIP"),
                color = Color3.fromRGB(255, 215, 0),
                noTint = true, -- Don't tint the VIP icon
                key = "VIPBoost"
            })
        end
        
        -- 2x Money Boost (only for Money tab)
        if boostType == BOOST_TYPES.MONEY and gamepasses.TwoXMoney then
            table.insert(boostData, {
                multiplier = 2, -- 2x Money is 2x
                label = "2x Money",
                icon = IconAssets.getIcon("UI", "TWO_X_MONEY"),
                color = Color3.fromRGB(0, 200, 0),
                noTint = true, -- Don't tint the 2x Money icon
                key = "TwoXMoneyBoost"
            })
        end
        
        -- Rebirth Boost (only for Money tab)
        if boostType == BOOST_TYPES.MONEY and boostBreakdown.rebirthBoost > 1 then
            local rebirths = (playerData.Resources and playerData.Resources.Rebirths) or 0
            table.insert(boostData, {
                multiplier = boostBreakdown.rebirthBoost,
                label = "Rebirths (" .. rebirths .. ")",
                icon = IconAssets.getIcon("UI", "REBIRTH"),
                color = Color3.fromRGB(255, 100, 200),
                noTint = true, -- Don't tint the rebirth icon
                key = "RebirthBoost"
            })
        end
        
        -- Potion Boost
        local potionMultiplier = boostBreakdown.potionBoosts[boostType] or 1
        if potionMultiplier > 1 then
            local potionIcon = "rbxassetid://116367512866072" -- Default potion icon
            local potionColor = Color3.fromRGB(138, 43, 226)
            
            -- Try to get specific potion info
            if playerData.ActivePotions then
                for _, activePotion in pairs(playerData.ActivePotions) do
                    local remainingTime = activePotion.ExpiresAt - os.time()
                    if remainingTime > 0 then
                        local potionConfig = PotionConfig.GetPotion(activePotion.PotionId)
                        if potionConfig and potionConfig.BoostType == boostType then
                            potionIcon = potionConfig.Icon or potionIcon
                            potionColor = potionConfig.Color or potionColor
                            break
                        end
                    end
                end
            end
            
            table.insert(boostData, {
                multiplier = potionMultiplier,
                label = boostType .. " Potion",
                icon = potionIcon,
                color = potionColor,
                noTint = true, -- Don't tint potion icons
                key = "PotionBoost"
            })
        end
        
        -- Sort boost data by multiplier (highest first)
        table.sort(boostData, function(a, b)
            return a.multiplier > b.multiplier
        end)
        
        -- Create cards from sorted data
        local cards = {}
        for i, data in ipairs(boostData) do
            local card = createBoostCard(data, i)
            if card then
                cards[data.key] = card
            end
        end
        
        return cards
    end
    
    -- Don't render if not visible
    if not props.visible then
        return nil
    end
    
    -- Get screen size for responsive sizing
    local screenSize = ScreenUtils.getScreenSize()
    local screenWidth = screenSize.X
    local screenHeight = screenSize.Y
    
    -- Calculate responsive panel size (much narrower for 3 cards per row)
    local panelWidth = math.max(ScreenUtils.getProportionalSize(580), screenWidth * 0.45) -- 45% of screen width, much narrower
    local panelHeight = math.max(ScreenUtils.getProportionalSize(600), screenHeight * 0.7) -- 70% of screen height
    
    -- Get current tab's boost cards
    local currentCards = getBoostCards(selectedTab)
    
    -- Calculate total boost for the selected type
    local totalMultiplier
    if selectedTab == BOOST_TYPES.MONEY then
        totalMultiplier = boostBreakdown.totalBoost
    elseif selectedTab == BOOST_TYPES.DIAMONDS then
        -- Calculate diamonds total boost (only VIP and diamond potions affect diamonds)
        local vipBoost = 1
        local gamepasses = {}
        for _, gamepassName in pairs(playerData.OwnedGamepasses or {}) do
            gamepasses[gamepassName] = true
        end
        if gamepasses.VIP then
            vipBoost = 2 -- VIP gives 2x
        end
        
        local diamondPotionBoost = boostBreakdown.potionBoosts.Diamonds or 1
        
        -- Diamonds are only affected by VIP and diamond potions
        totalMultiplier = vipBoost * diamondPotionBoost
    else
        totalMultiplier = 1
    end
    
    -- Create invisible click-outside-to-close overlay
    return React.createElement("TextButton", {
        Name = "BoostPanelOverlay",
        Size = UDim2.new(1, 0, 1, 0), -- Full screen overlay
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1, -- Completely invisible overlay
        Text = "", -- No text
        ZIndex = 199,
        [React.Event.MouseButton1Click] = props.onClose, -- Click anywhere to close
    }, {
        BoostPanel = React.createElement("TextButton", {
            Name = "BoostPanel",
            Size = UDim2.new(0, panelWidth, 0, panelHeight), -- Responsive size
            Position = UDim2.new(0.5, -panelWidth/2, 0.5, -panelHeight/2), -- Center on screen
            BackgroundTransparency = 1, -- Transparent to show background pattern
            Text = "", -- No text
            ZIndex = 200,
            [React.Event.Activated] = function()
                -- Prevent click-through by consuming the event
            end,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(12)),
            }),
            
            -- Main panel outline
            PanelOutline = React.createElement("UIStroke", {
                Thickness = ScreenUtils.getProportionalSize(3),
                Color = Color3.fromRGB(0, 0, 0),
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }),
            
            -- White background
            WhiteBackground = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(245, 245, 245),
                BorderSizePixel = 0,
                ZIndex = 198,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(12)),
                }),
            }),
            
            -- Background pattern
            BackgroundPattern = React.createElement("ImageLabel", {
                Name = "BackgroundPattern",
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                Image = "rbxassetid://116367512866072",
                ScaleType = Enum.ScaleType.Tile,
                TileSize = UDim2.new(0, ScreenUtils.getProportionalSize(120), 0, ScreenUtils.getProportionalSize(120)),
                ImageTransparency = 0.85,
                ImageColor3 = Color3.fromRGB(200, 200, 200),
                ZIndex = 199,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(12)),
                }),
            }),
            
            -- Header section (just the header, no tabs)
            Header = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(70)), -- Just for header
                BackgroundTransparency = 1,
                ZIndex = 201,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(12))
                }),
                
                -- Header outline
                HeaderOutline = React.createElement("UIStroke", {
                    Thickness = ScreenUtils.getProportionalSize(2),
                    Color = Color3.fromRGB(0, 0, 0),
                    Transparency = 0,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                }),
                
                -- Solid background for header
                SolidBackground = React.createElement("Frame", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundColor3 = Color3.fromRGB(64, 224, 208),
                    BorderSizePixel = 0,
                    ZIndex = 200,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(12))
                    }),
                }),
                
                -- Header container with icon and text
                HeaderContainer = React.createElement("Frame", {
                    Size = UDim2.new(1, -ScreenUtils.getProportionalSize(60), 0, ScreenUtils.getProportionalSize(50)),
                    Position = UDim2.new(0.5, 0, 0, ScreenUtils.getProportionalSize(10)),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    ZIndex = 202,
                }, {
                    Layout = React.createElement("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(10)),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                    }),
                    
                    -- Boost icon
                    BoostIcon = React.createElement("ImageLabel", {
                        Size = UDim2.new(0, ScreenUtils.getProportionalSize(40), 0, ScreenUtils.getProportionalSize(40)),
                        BackgroundTransparency = 1,
                        Image = IconAssets.getIcon("UI", "BOOST"),
                        ScaleType = Enum.ScaleType.Fit,
                        ImageColor3 = Color3.fromRGB(255, 255, 255), -- Natural/white color
                        ZIndex = 203,
                        LayoutOrder = 1,
                    }),
                    
                    -- Header title text
                    Title = React.createElement("TextLabel", {
                        Size = UDim2.new(0, ScreenUtils.getProportionalSize(200), 1, 0),
                        BackgroundTransparency = 1,
                        Text = "Boost Cards",
                        TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                        TextSize = ScreenUtils.TEXT_SIZES.LARGE() + 2,
                        TextStrokeTransparency = 0,
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0), -- Black outline
                        Font = Enum.Font.FredokaOne,
                        TextXAlignment = Enum.TextXAlignment.Center, -- Centered text
                        TextYAlignment = Enum.TextYAlignment.Center,
                        ZIndex = 203,
                        LayoutOrder = 2,
                    }),
                }),
                
                -- Close button
                CloseButton = React.createElement("ImageButton", {
                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(45), 0, ScreenUtils.getProportionalSize(45)),
                    Position = UDim2.new(1, -ScreenUtils.getProportionalSize(50), 0, ScreenUtils.getProportionalSize(15)),
                    BackgroundTransparency = 1,
                    Image = IconAssets.getIcon("UI", "X_BUTTON"),
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 202,
                    [React.Event.Activated] = props.onClose,
                })
            }),
            
            -- Tab buttons (separate from header)
            TabsContainer = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(60)), -- Slightly taller tab section
                Position = UDim2.new(0, 0, 0, ScreenUtils.getProportionalSize(70)), -- Right below header
                BackgroundTransparency = 1,
                ZIndex = 201,
            }, {
                -- Tab background (same as main UI background)
                TabBackground = React.createElement("Frame", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundColor3 = Color3.fromRGB(245, 245, 245), -- Same as main UI background
                    BorderSizePixel = 0,
                    ZIndex = 200,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(0)) -- No corner for seamless look
                    }),
                }),
                
                -- Background pattern for tabs (same as main UI)
                TabBackgroundPattern = React.createElement("ImageLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://116367512866072",
                    ScaleType = Enum.ScaleType.Tile,
                    TileSize = UDim2.new(0, ScreenUtils.getProportionalSize(120), 0, ScreenUtils.getProportionalSize(120)),
                    ImageTransparency = 0.85,
                    ImageColor3 = Color3.fromRGB(200, 200, 200),
                    ZIndex = 199,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(0))
                    }),
                }),
                
                -- Tab container
                TabButtonsContainer = React.createElement("Frame", {
                    Size = UDim2.new(0.7, 0, 0, ScreenUtils.getProportionalSize(45)), -- Slightly bigger
                    Position = UDim2.new(0.15, 0, 0.5, -ScreenUtils.getProportionalSize(22.5)), -- Centered
                    BackgroundTransparency = 1,
                    ZIndex = 202,
                }, {
                    TabLayout = React.createElement("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(8)), -- Better spacing between tabs
                        SortOrder = Enum.SortOrder.LayoutOrder,
                    }),
                    
                    -- Money tab
                    MoneyTab = React.createElement("TextButton", {
                        Size = UDim2.new(0.5, -ScreenUtils.getProportionalSize(4), 1, 0), -- Half width minus padding
                        BackgroundColor3 = selectedTab == BOOST_TYPES.MONEY and Color3.fromRGB(46, 125, 50) or Color3.fromRGB(255, 255, 255),
                        BorderSizePixel = 0,
                        Text = "", -- No text, we'll use icon + label
                        ZIndex = 203,
                        LayoutOrder = 1,
                        [React.Event.Activated] = function()
                            playClickSound()
                            setSelectedTab(BOOST_TYPES.MONEY)
                        end,
                        [React.Event.MouseEnter] = function()
                            if selectedTab ~= BOOST_TYPES.MONEY then
                                playHoverSound()
                            end
                        end,
                    }, {
                        -- Tab content container
                        TabContent = React.createElement("Frame", {
                            Size = UDim2.new(1, 0, 1, 0),
                            BackgroundTransparency = 1,
                            ZIndex = 204,
                        }, {
                            TabLayout = React.createElement("UIListLayout", {
                                FillDirection = Enum.FillDirection.Horizontal,
                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                VerticalAlignment = Enum.VerticalAlignment.Center,
                                Padding = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(5)),
                                SortOrder = Enum.SortOrder.LayoutOrder,
                            }),
                            
                            -- Money icon
                            MoneyIcon = React.createElement("ImageLabel", {
                                Size = UDim2.new(0, ScreenUtils.TEXT_SIZES.MEDIUM() * 1.5, 0, ScreenUtils.TEXT_SIZES.MEDIUM() * 1.5), -- Proportional to text size
                                BackgroundTransparency = 1,
                                Image = IconAssets.getIcon("CURRENCY", "MONEY"),
                                ScaleType = Enum.ScaleType.Fit,
                                ImageColor3 = Color3.fromRGB(255, 255, 255), -- Natural color
                                ZIndex = 205,
                                LayoutOrder = 1,
                            }),
                            
                            -- Money label
                            MoneyLabel = React.createElement("TextLabel", {
                                Size = UDim2.new(1, -ScreenUtils.TEXT_SIZES.MEDIUM() * 2, 1, 0), -- Take remaining space after icon
                                BackgroundTransparency = 1,
                                Text = "Money",
                                TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                                TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() * 2, -- 2x bigger text
                                Font = Enum.Font.FredokaOne,
                                TextStrokeTransparency = 0, -- Black outline
                                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                                TextXAlignment = Enum.TextXAlignment.Left, -- Left align next to icon
                                TextYAlignment = Enum.TextYAlignment.Center,
                                ZIndex = 205,
                                LayoutOrder = 2,
                            })
                        }),
                        Corner = React.createElement("UICorner", {
                            CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(12)), -- More rounded corners
                        }),
                        
                        -- Enhanced outline with shadow effect
                        TabOutline = React.createElement("UIStroke", {
                            Thickness = selectedTab == BOOST_TYPES.MONEY and ScreenUtils.getProportionalSize(3) or ScreenUtils.getProportionalSize(2),
                            Color = selectedTab == BOOST_TYPES.MONEY and Color3.fromRGB(27, 94, 32) or Color3.fromRGB(180, 180, 180),
                            Transparency = 0,
                            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                        }),
                        
                        -- Subtle gradient for selected tab
                        TabGradient = selectedTab == BOOST_TYPES.MONEY and React.createElement("UIGradient", {
                            Color = ColorSequence.new({
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(56, 142, 60)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(46, 125, 50))
                            }),
                            Rotation = 90,
                        }) or nil
                    }),
                    
                    -- Diamonds tab
                    DiamondsTab = React.createElement("TextButton", {
                        Size = UDim2.new(0.5, -ScreenUtils.getProportionalSize(4), 1, 0), -- Half width minus padding
                        BackgroundColor3 = selectedTab == BOOST_TYPES.DIAMONDS and Color3.fromRGB(21, 101, 192) or Color3.fromRGB(255, 255, 255),
                        BorderSizePixel = 0,
                        Text = "", -- No text, we'll use icon + label
                        ZIndex = 203,
                        LayoutOrder = 2,
                        [React.Event.Activated] = function()
                            playClickSound()
                            setSelectedTab(BOOST_TYPES.DIAMONDS)
                        end,
                        [React.Event.MouseEnter] = function()
                            if selectedTab ~= BOOST_TYPES.DIAMONDS then
                                playHoverSound()
                            end
                        end,
                    }, {
                        -- Tab content container
                        TabContent = React.createElement("Frame", {
                            Size = UDim2.new(1, 0, 1, 0),
                            BackgroundTransparency = 1,
                            ZIndex = 204,
                        }, {
                            TabLayout = React.createElement("UIListLayout", {
                                FillDirection = Enum.FillDirection.Horizontal,
                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                VerticalAlignment = Enum.VerticalAlignment.Center,
                                Padding = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(5)),
                                SortOrder = Enum.SortOrder.LayoutOrder,
                            }),
                            
                            -- Diamond icon
                            DiamondIcon = React.createElement("ImageLabel", {
                                Size = UDim2.new(0, ScreenUtils.TEXT_SIZES.MEDIUM() * 1.5, 0, ScreenUtils.TEXT_SIZES.MEDIUM() * 1.5), -- Proportional to text size
                                BackgroundTransparency = 1,
                                Image = IconAssets.getIcon("CURRENCY", "DIAMONDS"),
                                ScaleType = Enum.ScaleType.Fit,
                                ImageColor3 = Color3.fromRGB(255, 255, 255), -- Natural color
                                ZIndex = 205,
                                LayoutOrder = 1,
                            }),
                            
                            -- Diamond label
                            DiamondLabel = React.createElement("TextLabel", {
                                Size = UDim2.new(1, -ScreenUtils.TEXT_SIZES.MEDIUM() * 2, 1, 0), -- Take remaining space after icon
                                BackgroundTransparency = 1,
                                Text = "Diamonds",
                                TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                                TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() * 2, -- 2x bigger text
                                Font = Enum.Font.FredokaOne,
                                TextStrokeTransparency = 0, -- Black outline
                                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                                TextXAlignment = Enum.TextXAlignment.Left, -- Left align next to icon
                                TextYAlignment = Enum.TextYAlignment.Center,
                                ZIndex = 205,
                                LayoutOrder = 2,
                            })
                        }),
                        Corner = React.createElement("UICorner", {
                            CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(12)), -- More rounded corners
                        }),
                        
                        -- Enhanced outline with shadow effect
                        TabOutline = React.createElement("UIStroke", {
                            Thickness = selectedTab == BOOST_TYPES.DIAMONDS and ScreenUtils.getProportionalSize(3) or ScreenUtils.getProportionalSize(2),
                            Color = selectedTab == BOOST_TYPES.DIAMONDS and Color3.fromRGB(13, 71, 161) or Color3.fromRGB(180, 180, 180),
                            Transparency = 0,
                            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                        }),
                        
                        -- Subtle gradient for selected tab
                        TabGradient = selectedTab == BOOST_TYPES.DIAMONDS and React.createElement("UIGradient", {
                            Color = ColorSequence.new({
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(33, 150, 243)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(21, 101, 192))
                            }),
                            Rotation = 90,
                        }) or nil
                    })
                })
            }),
            
            -- Content area
            ContentArea = React.createElement("Frame", {
                Size = UDim2.new(1, -ScreenUtils.getProportionalSize(30), 1, -ScreenUtils.getProportionalSize(150)), -- Leave room for header and tabs
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(15), 0, ScreenUtils.getProportionalSize(140)), -- Below header and tabs (adjusted for taller tabs)
                BackgroundTransparency = 1,
                ZIndex = 201,
            }, {
                -- Total boost display at top
                TotalBoostLabel = React.createElement("TextLabel", {
                    Name = "TotalBoostLabel",
                    Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(50)),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Text = string.format("📊 Total %s Boost: %sx", selectedTab, NumberFormatter.formatBoost(totalMultiplier)),
                    TextColor3 = totalMultiplier > 1 and Color3.fromRGB(64, 224, 208) or Color3.fromRGB(100, 100, 100),
                    TextSize = ScreenUtils.TEXT_SIZES.HEADER(),
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 202,
                }),
                
                -- Cards container with grid layout
                CardsContainer = (function()
                    local cardChildren = {
                        -- Grid layout for cards
                        CardGrid = React.createElement("UIGridLayout", {
                            CellSize = UDim2.new(0, ScreenUtils.getProportionalSize(180), 0, ScreenUtils.getProportionalSize(180)), -- Same card size
                            CellPadding = UDim2.new(0, ScreenUtils.getProportionalSize(20), 0, ScreenUtils.getProportionalSize(20)), -- More spacing
                            HorizontalAlignment = Enum.HorizontalAlignment.Center,
                            VerticalAlignment = Enum.VerticalAlignment.Top,
                            SortOrder = Enum.SortOrder.LayoutOrder,
                            FillDirectionMaxCells = 3, -- 3 cards per row instead of 4
                        })
                    }
                    
                    -- Add boost cards to children
                    for cardName, cardElement in pairs(currentCards) do
                        cardChildren[cardName] = cardElement
                    end
                    
                    return React.createElement("Frame", {
                        Size = UDim2.new(1, 0, 1, -ScreenUtils.getProportionalSize(60)),
                        Position = UDim2.new(0, 0, 0, ScreenUtils.getProportionalSize(60)),
                        BackgroundTransparency = 1,
                        ZIndex = 202,
                    }, cardChildren)
                end)(),
                
                -- No boosts message if no cards
                NoBoostsMessage = not next(currentCards) and React.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 1, -ScreenUtils.getProportionalSize(60)),
                    Position = UDim2.new(0, 0, 0, ScreenUtils.getProportionalSize(60)),
                    BackgroundTransparency = 1,
                    Text = "No active " .. selectedTab:lower() .. " boosts",
                    TextColor3 = Color3.fromRGB(150, 150, 150),
                    TextSize = ScreenUtils.TEXT_SIZES.LARGE(),
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    ZIndex = 202,
                }) or nil
            })
        })
    })
end

return BoostPanel