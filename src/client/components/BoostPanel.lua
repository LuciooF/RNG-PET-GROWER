-- BoostPanel - React component for detailed boost breakdown display
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.react)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)
local DataSyncService = require(script.Parent.Parent.services.DataSyncService)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)

local function BoostPanel(props)
    -- Subscribe to player data for boost calculation
    local playerData, setPlayerData = React.useState({
        EquippedPets = {},
        OPPets = {},
        OwnedGamepasses = {}
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
    
    -- Calculate boost breakdown
    local petBoostMultiplier = 0 -- Start at 0, not 1
    local petCount = 0
    
    for _, pet in pairs(playerData.EquippedPets or {}) do
        petCount = petCount + 1
        if pet.FinalBoost then
            petBoostMultiplier = petBoostMultiplier + (pet.FinalBoost - 1) -- Convert 1.36x to 0.36, then add
        end
    end
    
    -- Calculate OP pet boost
    local opPetBoostMultiplier = 0 -- Start at 0, not 1
    local opPetCount = 0
    
    for _, opPet in pairs(playerData.OPPets or {}) do
        opPetCount = opPetCount + 1
        if opPet.FinalBoost then
            opPetBoostMultiplier = opPetBoostMultiplier + (opPet.FinalBoost - 1) -- Convert 1.36x to 0.36, then add
        elseif opPet.BaseBoost then
            opPetBoostMultiplier = opPetBoostMultiplier + (opPet.BaseBoost - 1) -- Fallback to BaseBoost
        end
    end
    
    -- Calculate gamepass boost
    local gamepassMultiplier = 1
    local gamepasses = {}
    local gamepassNames = {}
    
    for _, gamepassName in pairs(playerData.OwnedGamepasses or {}) do
        gamepasses[gamepassName] = true
    end
    
    if gamepasses.TwoXMoney then
        gamepassMultiplier = gamepassMultiplier * 2
        table.insert(gamepassNames, "2x Money")
    end
    
    if gamepasses.VIP then
        gamepassMultiplier = gamepassMultiplier * 2
        table.insert(gamepassNames, "VIP")
    end
    
    -- Calculate rebirth multiplier (0.5x per rebirth: 0 rebirths = 1x, 1 rebirth = 1.5x, 2 rebirths = 2x, etc.)
    local playerRebirths = playerData.Resources and playerData.Resources.Rebirths or 0
    local rebirthMultiplier = 1 + (playerRebirths * 0.5)
    
    -- Total boost calculation: base 1x + pet boost + OP pet boost + gamepass bonus + rebirth bonus (all additive)
    local totalMultiplier = 1 + petBoostMultiplier + opPetBoostMultiplier + (gamepassMultiplier - 1) + (rebirthMultiplier - 1)
    
    -- Don't render if not visible
    if not props.visible then
        return nil
    end
    
    -- Get screen size for responsive sizing
    local screenSize = ScreenUtils.getScreenSize()
    local screenWidth = screenSize.X
    local screenHeight = screenSize.Y
    
    -- Calculate responsive panel size
    local panelWidth = math.max(ScreenUtils.getProportionalSize(400), screenWidth * 0.32) -- 32% of screen width, responsive minimum
    local panelHeight = math.max(ScreenUtils.getProportionalSize(280), screenHeight * 0.35) -- 35% of screen height, responsive minimum
    
    -- Create invisible click-outside-to-close overlay (no dark background)
    return React.createElement("TextButton", {
        Name = "BoostPanelOverlay",
        Size = UDim2.new(1, 0, 1, 0), -- Full screen overlay
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1, -- Completely invisible overlay
        Text = "", -- No text
        ZIndex = 199,
        [React.Event.MouseButton1Click] = props.onClose, -- Click anywhere to close
    }, {
        BoostPanel = React.createElement("Frame", {
            Name = "BoostPanel",
            Size = UDim2.new(0, panelWidth, 0, panelHeight), -- Responsive size
            Position = UDim2.new(0.5, -panelWidth/2, 0.5, -panelHeight/2), -- Center on screen
            BackgroundTransparency = 1, -- Transparent to show background pattern
            ZIndex = 200,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(12)), -- Match Pet UI corner radius
            }),
            
            -- Main panel outline like Pet UI
            PanelOutline = React.createElement("UIStroke", {
                Thickness = ScreenUtils.getProportionalSize(3),
                Color = Color3.fromRGB(0, 0, 0), -- Black outline
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }),
            
            -- White background like Pet UI
            WhiteBackground = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(245, 245, 245), -- Light grey background like Pet UI
                BorderSizePixel = 0,
                ZIndex = 198, -- Behind everything
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
                ZIndex = 199, -- Above white background but behind content
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(12)),
                }),
            }),
            
            -- Header section like Pet UI
            Header = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(55)), -- Responsive header height
                BackgroundTransparency = 1, -- Transparent for gradient
                ZIndex = 201,
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
                    ZIndex = 200,
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
                    Size = UDim2.new(1, -ScreenUtils.getProportionalSize(60), 1, 0),
                    Position = UDim2.new(0.5, 0, 0, 0),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    Text = "💪 Boost Breakdown",
                    TextColor3 = Color3.fromRGB(64, 224, 208), -- Turquoise like Pet UI
                    TextSize = ScreenUtils.TEXT_SIZES.LARGE() + 2, -- Responsive text
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    ZIndex = 202,
                }),
                
                -- Close button like Pet UI
                CloseButton = React.createElement("ImageButton", {
                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(45), 0, ScreenUtils.getProportionalSize(45)),
                    Position = UDim2.new(1, -ScreenUtils.getProportionalSize(50), 0.5, -ScreenUtils.getProportionalSize(22.5)),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    Image = IconAssets.getIcon("UI", "X_BUTTON"),
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 202,
                    [React.Event.Activated] = props.onClose,
                })
            }),
            
            -- Content area
            ContentArea = React.createElement("Frame", {
                Size = UDim2.new(1, -ScreenUtils.getProportionalSize(30), 1, -ScreenUtils.getProportionalSize(85)), -- Leave room for header and padding
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(15), 0, ScreenUtils.getProportionalSize(70)), -- Below header
                BackgroundTransparency = 1,
                ZIndex = 201,
            }, {
                Layout = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Top,
                    Padding = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(15)),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }),
                
                -- Total boost display
                TotalBoostLabel = React.createElement("TextLabel", {
                    Name = "TotalBoostLabel",
                    Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(45)), -- Bigger size
                    BackgroundTransparency = 1,
                    Text = string.format("📊 Total Boost: %sx", NumberFormatter.formatBoost(totalMultiplier)),
                    TextColor3 = totalMultiplier > 1 and Color3.fromRGB(64, 224, 208) or Color3.fromRGB(100, 100, 100), -- Turquoise like Pet UI
                    TextSize = ScreenUtils.TEXT_SIZES.HEADER() + 4, -- Bigger text size
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextStrokeTransparency = 1, -- Remove outline
                    ZIndex = 202,
                    LayoutOrder = 1,
                }),
                
                -- Pet boost display
                PetBoostLabel = React.createElement("TextLabel", {
                    Name = "PetBoostLabel",
                    Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(40)), -- Bigger size
                    BackgroundTransparency = 1,
                    Text = string.format("🐾 Pet Boost: %sx", NumberFormatter.formatBoost(petBoostMultiplier)),
                    TextColor3 = petBoostMultiplier > 1 and Color3.fromRGB(50, 200, 100) or Color3.fromRGB(120, 120, 120), -- Green theme
                    TextSize = ScreenUtils.TEXT_SIZES.LARGE() + 3, -- Bigger text size
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextStrokeTransparency = 1, -- Remove outline
                    ZIndex = 202,
                    LayoutOrder = 2,
                }),
                
                -- OP Pet boost display with rainbow gradient
                OPPetBoostLabel = React.createElement("TextLabel", {
                    Name = "OPPetBoostLabel",
                    Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(40)), -- Same size as other boosts
                    BackgroundTransparency = 1,
                    Text = string.format("🌈 OP PET BOOST: %sx", NumberFormatter.formatBoost(opPetBoostMultiplier)),
                    TextColor3 = Color3.fromRGB(255, 255, 255), -- White base for rainbow gradient
                    TextSize = ScreenUtils.TEXT_SIZES.LARGE() + 3, -- Same size as other boosts
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextStrokeTransparency = 0, -- Black stroke for visibility
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 202,
                    LayoutOrder = 3,
                }, {
                    -- Rainbow gradient for OP pet boost
                    RainbowGradient = React.createElement("UIGradient", {
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),     -- Red
                            ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 127, 0)), -- Orange
                            ColorSequenceKeypoint.new(0.32, Color3.fromRGB(255, 255, 0)), -- Yellow  
                            ColorSequenceKeypoint.new(0.48, Color3.fromRGB(0, 255, 0)),   -- Green
                            ColorSequenceKeypoint.new(0.64, Color3.fromRGB(0, 255, 255)), -- Cyan
                            ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0, 0, 255)),   -- Blue
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255))    -- Magenta
                        }),
                        Rotation = 0 -- Horizontal gradient
                    })
                }),
                
                -- Gamepass boost display
                GamepassBoostLabel = React.createElement("TextLabel", {
                    Name = "GamepassBoostLabel",
                    Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(40)), -- Bigger size
                    BackgroundTransparency = 1,
                    Text = gamepassMultiplier > 1 and 
                        string.format("💎 Gamepasses: %.1fx (%s)", gamepassMultiplier, table.concat(gamepassNames, " + ")) or 
                        "💎 Gamepasses: 1x",
                    TextColor3 = gamepassMultiplier > 1 and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(120, 120, 120), -- Gold theme like Pet UI badges
                    TextSize = ScreenUtils.TEXT_SIZES.LARGE() + 3, -- Bigger text size
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextStrokeTransparency = 1, -- Remove outline
                    ZIndex = 202,
                    LayoutOrder = 4,
                }),
                
                -- Rebirth boost display
                RebirthBoostLabel = React.createElement("TextLabel", {
                    Name = "RebirthBoostLabel",
                    Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(40)), -- Same size as other boosts
                    BackgroundTransparency = 1,
                    Text = string.format("🔄 Rebirth Boost: %sx", NumberFormatter.formatBoost(rebirthMultiplier)),
                    TextColor3 = rebirthMultiplier > 1 and Color3.fromRGB(255, 100, 200) or Color3.fromRGB(120, 120, 120), -- Pink theme for rebirths
                    TextSize = ScreenUtils.TEXT_SIZES.LARGE() + 3, -- Same size as other boosts
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextStrokeTransparency = 1, -- Remove outline
                    ZIndex = 202,
                    LayoutOrder = 5,
                }, {
                    -- Add multiplier icon
                    MultiplierIcon = React.createElement("ImageLabel", {
                        Size = UDim2.new(0, ScreenUtils.getProportionalSize(30), 0, ScreenUtils.getProportionalSize(30)),
                        Position = UDim2.new(0, ScreenUtils.getProportionalSize(15), 0.5, -ScreenUtils.getProportionalSize(15)),
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundTransparency = 1,
                        Image = "rbxassetid://118906329469728", -- Multiplier icon
                        ScaleType = Enum.ScaleType.Fit,
                        ImageColor3 = rebirthMultiplier > 1 and Color3.fromRGB(255, 100, 200) or Color3.fromRGB(120, 120, 120),
                        ZIndex = 203,
                    })
                }),
                
                -- Pet count display
                PetCountLabel = React.createElement("TextLabel", {
                    Name = "PetCountLabel",
                    Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(35)), -- Bigger size
                    BackgroundTransparency = 1,
                    Text = petCount == 1 and "📊 1 pet equipped" or "📊 " .. petCount .. " pets equipped",
                    TextColor3 = Color3.fromRGB(80, 80, 80), -- Darker gray for better readability
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() + 3, -- Bigger text size
                    Font = Enum.Font.Gotham, -- Regular font for info text
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextStrokeTransparency = 1, -- Remove outline
                    ZIndex = 202,
                    LayoutOrder = 6,
                })
            })
        })
    })
end

return BoostPanel