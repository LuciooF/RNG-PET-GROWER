-- Modern Rebirth UI - Matches reference image design with before/after panels and progress bar
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local React = require(ReplicatedStorage.Packages.react)

local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)
local RebirthUtils = require(ReplicatedStorage.utils.RebirthUtils)

-- Developer Product ID for Robux rebirth
local ROBUX_REBIRTH_DEV_PRODUCT_ID = 3353655412

local RebirthUI = {}

function RebirthUI.new(props)
    -- Don't render if not visible
    if not props.visible then
        return nil
    end
    
    -- Calculate rebirth cost
    local currentRebirths = props.playerRebirths or 0
    local rebirthCost = RebirthUtils.getRebirthCost(currentRebirths)
    local canAffordRebirth = (props.playerMoney or 0) >= rebirthCost
    
    -- Get Robux price dynamically from developer product
    local robuxPrice, setRobuxPrice = React.useState("50") -- Default fallback
    
    -- Use effect to fetch price when component mounts
    React.useEffect(function()
        task.spawn(function()
            local success, productInfo = pcall(function()
                return MarketplaceService:GetProductInfo(ROBUX_REBIRTH_DEV_PRODUCT_ID, Enum.InfoType.Product)
            end)
            if success and productInfo and productInfo.PriceInRobux then
                setRobuxPrice(tostring(productInfo.PriceInRobux))
            end
        end)
    end, {})
    
    -- Handle Robux rebirth purchase
    local function handleRobuxRebirth()
        MarketplaceService:PromptProductPurchase(game.Players.LocalPlayer, ROBUX_REBIRTH_DEV_PRODUCT_ID)
        -- Close UI immediately so player can see rebirth animation
        if props.onClose then
            props.onClose()
        end
        -- Note: Actual rebirth will be handled by server when purchase is processed
    end
    
    -- Calculate progress (0 to 1)
    local progress = math.min((props.playerMoney or 0) / rebirthCost, 1)
    
    -- Create click-outside-to-close overlay
    return React.createElement("TextButton", {
        Name = "RebirthUIOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1, -- Invisible overlay
        Text = "",
        ZIndex = 999,
        [React.Event.MouseButton1Click] = props.onClose, -- Click outside to close
    }, {
        RebirthModal = React.createElement("Frame", {
            Name = "RebirthModal",
            Size = ScreenUtils.udim2(0, 750, 0, 500), -- Even bigger UI to accommodate bigger panels
            Position = ScreenUtils.udim2(0.5, -375, 0.5, -250), -- Center on screen for bigger modal
            BackgroundColor3 = Color3.fromRGB(255, 255, 255), -- White background
            BackgroundTransparency = 0,
            ZIndex = 1000,
        }, {
            -- Invisible button to prevent click bubbling
            ClickBlocker = React.createElement("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 999,
                [React.Event.MouseButton1Click] = function()
                    -- Prevent click from bubbling up to overlay (don't close when clicking on modal)
                end,
            }),
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, 15), -- Rounded corners
            }),
            
            ModalOutline = React.createElement("UIStroke", {
                Thickness = 4,
                Color = Color3.fromRGB(0, 0, 0), -- Black outline
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }),
            
            -- Background pattern like Pets UI
            BackgroundPattern = React.createElement("ImageLabel", {
                Name = "BackgroundPattern",
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                Image = "rbxassetid://116367512866072",
                ImageTransparency = 0.95, -- Very faint background
                ScaleType = Enum.ScaleType.Tile,
                TileSize = UDim2.new(0, 50, 0, 50),
                ZIndex = 999, -- Behind content
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 15),
                }),
            }),
            
            -- Header section with purple rebirth theme
            Header = React.createElement("Frame", {
                Size = ScreenUtils.udim2(1, 0, 0, 60),
                BackgroundTransparency = 1, -- Transparent for gradient
                BorderSizePixel = 2,
                BorderColor3 = Color3.fromRGB(0, 0, 0), -- Black outline
                ZIndex = 1006,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 12)
                }),
                
                -- Gradient background for header (purple rebirth theme)
                GradientBackground = React.createElement("Frame", {
                    Size = ScreenUtils.udim2(1, 0, 1, 0),
                    BackgroundColor3 = Color3.fromRGB(138, 43, 226), -- Purple base
                    BorderSizePixel = 0,
                    ZIndex = 1005,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, 12)
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
                
                -- Title and Icon Container (centered)
                TitleContainer = React.createElement("Frame", {
                    Size = ScreenUtils.udim2(0, 180, 1, 0),
                    Position = ScreenUtils.udim2(0.5, -90, 0, 0), -- Center the container
                    BackgroundTransparency = 1,
                    ZIndex = 1007,
                }, {
                    -- Rebirth Icon
                    RebirthIcon = React.createElement("ImageLabel", {
                        Size = ScreenUtils.udim2(0, 40, 0, 40),
                        Position = ScreenUtils.udim2(0, 0, 0.5, -20), -- Left side of container
                        BackgroundTransparency = 1,
                        Image = IconAssets.getIcon("UI", "REBIRTH"),
                        ScaleType = Enum.ScaleType.Fit,
                        ZIndex = 1008,
                    }),
                    
                    -- Title (next to icon)
                    Title = React.createElement("TextLabel", {
                        Size = ScreenUtils.udim2(0, 130, 1, 0),
                        Position = ScreenUtils.udim2(0, 50, 0, 0), -- Right of icon
                        BackgroundTransparency = 1,
                        Text = "Rebirth",
                        TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                        TextSize = ScreenUtils.TEXT_SIZES.LARGE() + 8, -- Big title
                        TextStrokeTransparency = 0, -- Black outline
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        ZIndex = 1008,
                    }),
                }),
                
                -- Close button (right side)
                CloseButton = React.createElement("ImageButton", {
                    Size = ScreenUtils.udim2(0, 50, 0, 50), -- Bigger close button
                    Position = ScreenUtils.udim2(1, -55, 0.5, -25),
                    BackgroundColor3 = Color3.fromRGB(255, 100, 100), -- Light red
                    Image = IconAssets.getIcon("UI", "X_BUTTON"),
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 1007,
                    [React.Event.MouseButton1Click] = props.onClose,
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
            
            -- Before/After panels like reference image
            PanelsSection = React.createElement("Frame", {
                Size = ScreenUtils.udim2(1, -30, 0, 200), -- Bigger section for bigger panels
                Position = ScreenUtils.udim2(0, 15, 0, 80),
                BackgroundTransparency = 1,
                ZIndex = 1006,
            }, {
                -- Current/Before panel (left)
                CurrentPanel = React.createElement("Frame", {
                    Size = ScreenUtils.udim2(0, 320, 0, 140), -- Bigger panel
                    Position = ScreenUtils.udim2(0, 0, 0, 0),
                    BackgroundColor3 = Color3.fromRGB(240, 240, 240), -- Light gray
                    ZIndex = 1006,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, 10),
                    }),
                    Outline = React.createElement("UIStroke", {
                        Thickness = 2,
                        Color = Color3.fromRGB(0, 0, 0),
                        Transparency = 0,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    }),
                    
                    Title = React.createElement("TextLabel", {
                        Size = ScreenUtils.udim2(1, -10, 0, 30),
                        Position = ScreenUtils.udim2(0, 5, 0, 5),
                        BackgroundTransparency = 1,
                        Text = "Current",
                        TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                        TextSize = ScreenUtils.TEXT_SIZES.LARGE() + 6, -- Even bigger
                        TextStrokeTransparency = 0, -- Black outline
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ZIndex = 1007,
                    }),
                    
                    -- Rebirth icon and text
                    RebirthIcon = React.createElement("ImageLabel", {
                        Size = ScreenUtils.udim2(0, 20, 0, 20),
                        Position = ScreenUtils.udim2(0, 10, 0, 35),
                        BackgroundTransparency = 1,
                        Image = IconAssets.getIcon("UI", "REBIRTH"),
                        ScaleType = Enum.ScaleType.Fit,
                        ZIndex = 1007,
                    }),
                    RebirthText = React.createElement("TextLabel", {
                        Size = ScreenUtils.udim2(1, -40, 0, 20),
                        Position = ScreenUtils.udim2(0, 35, 0, 35),
                        BackgroundTransparency = 1,
                        Text = string.format("Rebirths: %d", currentRebirths),
                        TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                        TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() + 4, -- Even bigger
                        TextStrokeTransparency = 0, -- Black outline
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        Font = Enum.Font.GothamBold, -- Bold
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 1007,
                    }),
                    
                    -- Level icon and text
                    LevelIcon = React.createElement("ImageLabel", {
                        Size = ScreenUtils.udim2(0, 20, 0, 20),
                        Position = ScreenUtils.udim2(0, 10, 0, 58),
                        BackgroundTransparency = 1,
                        Image = "rbxassetid://119453749882559", -- Grab Yellow Outline
                        ScaleType = Enum.ScaleType.Fit,
                        ZIndex = 1007,
                    }),
                    LevelText = React.createElement("TextLabel", {
                        Size = ScreenUtils.udim2(1, -40, 0, 20),
                        Position = ScreenUtils.udim2(0, 35, 0, 58),
                        BackgroundTransparency = 1,
                        Text = string.format("Level: %d", currentRebirths + 1),
                        TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                        TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() + 4, -- Even bigger
                        TextStrokeTransparency = 0, -- Black outline
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        Font = Enum.Font.GothamBold, -- Bold
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 1007,
                    }),
                    
                    -- Money icon and text
                    MoneyIcon = React.createElement("ImageLabel", {
                        Size = ScreenUtils.udim2(0, 20, 0, 20),
                        Position = ScreenUtils.udim2(0, 10, 0, 80),
                        BackgroundTransparency = 1,
                        Image = IconAssets.getIcon("CURRENCY", "MONEY"),
                        ScaleType = Enum.ScaleType.Fit,
                        ZIndex = 1007,
                    }),
                    MoneyText = React.createElement("TextLabel", {
                        Size = ScreenUtils.udim2(1, -40, 0, 20),
                        Position = ScreenUtils.udim2(0, 35, 0, 80),
                        BackgroundTransparency = 1,
                        Text = string.format("Money: %s", NumberFormatter.format(props.playerMoney or 0)),
                        TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                        TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() + 4, -- Even bigger
                        TextStrokeTransparency = 0, -- Black outline
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        Font = Enum.Font.GothamBold, -- Bold
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 1007,
                    }),
                }),
                
                -- Arrow (using asset)
                Arrow = React.createElement("ImageLabel", {
                    Size = ScreenUtils.udim2(0, 40, 0, 40),
                    Position = ScreenUtils.udim2(0, 330, 0, 40), -- Centered between panels
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://99443771030643",
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 1007,
                }),
                
                -- After panel (right)
                AfterPanel = React.createElement("Frame", {
                    Size = ScreenUtils.udim2(0, 320, 0, 140), -- Bigger panel
                    Position = ScreenUtils.udim2(1, -320, 0, 0), -- Adjust position for bigger panel
                    BackgroundColor3 = Color3.fromRGB(220, 255, 220), -- Light green
                    ZIndex = 1006,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, 10),
                    }),
                    Outline = React.createElement("UIStroke", {
                        Thickness = 2,
                        Color = Color3.fromRGB(0, 0, 0),
                        Transparency = 0,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    }),
                    
                    Title = React.createElement("TextLabel", {
                        Size = ScreenUtils.udim2(1, -10, 0, 30),
                        Position = ScreenUtils.udim2(0, 5, 0, 5),
                        BackgroundTransparency = 1,
                        Text = "After Rebirth",
                        TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                        TextSize = ScreenUtils.TEXT_SIZES.LARGE() + 6, -- Even bigger
                        TextStrokeTransparency = 0, -- Black outline
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ZIndex = 1007,
                    }),
                    
                    -- After Rebirth icon and text
                    AfterRebirthIcon = React.createElement("ImageLabel", {
                        Size = ScreenUtils.udim2(0, 20, 0, 20),
                        Position = ScreenUtils.udim2(0, 10, 0, 35),
                        BackgroundTransparency = 1,
                        Image = IconAssets.getIcon("UI", "REBIRTH"),
                        ScaleType = Enum.ScaleType.Fit,
                        ZIndex = 1007,
                    }),
                    AfterRebirthText = React.createElement("TextLabel", {
                        Size = ScreenUtils.udim2(1, -40, 0, 20),
                        Position = ScreenUtils.udim2(0, 35, 0, 35),
                        BackgroundTransparency = 1,
                        Text = string.format("Rebirths: %d", currentRebirths + 1),
                        TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                        TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() + 4, -- Even bigger
                        TextStrokeTransparency = 0, -- Black outline
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        Font = Enum.Font.GothamBold, -- Bold
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 1007,
                    }),
                    
                    -- After Level icon and text
                    AfterLevelIcon = React.createElement("ImageLabel", {
                        Size = ScreenUtils.udim2(0, 20, 0, 20),
                        Position = ScreenUtils.udim2(0, 10, 0, 58),
                        BackgroundTransparency = 1,
                        Image = "rbxassetid://119453749882559", -- Grab Yellow Outline
                        ScaleType = Enum.ScaleType.Fit,
                        ZIndex = 1007,
                    }),
                    AfterLevelText = React.createElement("TextLabel", {
                        Size = ScreenUtils.udim2(1, -40, 0, 20),
                        Position = ScreenUtils.udim2(0, 35, 0, 58),
                        BackgroundTransparency = 1,
                        Text = string.format("Level: %d", currentRebirths + 2),
                        TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                        TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() + 4, -- Even bigger
                        TextStrokeTransparency = 0, -- Black outline
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        Font = Enum.Font.GothamBold, -- Bold
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 1007,
                    }),
                    
                    -- After Money icon and text
                    AfterMoneyIcon = React.createElement("ImageLabel", {
                        Size = ScreenUtils.udim2(0, 20, 0, 20),
                        Position = ScreenUtils.udim2(0, 10, 0, 80),
                        BackgroundTransparency = 1,
                        Image = IconAssets.getIcon("CURRENCY", "MONEY"),
                        ScaleType = Enum.ScaleType.Fit,
                        ZIndex = 1007,
                    }),
                    AfterMoneyText = React.createElement("TextLabel", {
                        Size = ScreenUtils.udim2(1, -40, 0, 20),
                        Position = ScreenUtils.udim2(0, 35, 0, 80),
                        BackgroundTransparency = 1,
                        Text = "Money: $0",
                        TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                        TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() + 4, -- Even bigger
                        TextStrokeTransparency = 0, -- Black outline
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        Font = Enum.Font.GothamBold, -- Bold
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 1007,
                    }),
                }),
                
                -- Progress bar
                ProgressSection = React.createElement("Frame", {
                    Size = ScreenUtils.udim2(1, 0, 0, 50),
                    Position = ScreenUtils.udim2(0, 0, 0, 200), -- Moved lower to reduce empty space
                    BackgroundTransparency = 1,
                    ZIndex = 1006,
                }, {
                    ProgressLabel = React.createElement("TextLabel", {
                        Size = ScreenUtils.udim2(1, 0, 0, 20),
                        Position = ScreenUtils.udim2(0, 0, 0, 0),
                        BackgroundTransparency = 1,
                        Text = string.format("Progress: %s / %s (%.1f%%)", 
                            NumberFormatter.format(props.playerMoney or 0),
                            NumberFormatter.format(rebirthCost),
                            progress * 100
                        ),
                        TextColor3 = Color3.fromRGB(50, 50, 50),
                        TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ZIndex = 1007,
                    }),
                    
                    ProgressBar = React.createElement("Frame", {
                        Size = ScreenUtils.udim2(1, 0, 0, 30), -- Thicker progress bar
                        Position = ScreenUtils.udim2(0, 0, 0, 25),
                        BackgroundColor3 = Color3.fromRGB(200, 200, 200), -- Gray background
                        ZIndex = 1006,
                    }, {
                        Corner = React.createElement("UICorner", {
                            CornerRadius = ScreenUtils.udim(0, 10),
                        }),
                        Outline = React.createElement("UIStroke", {
                            Thickness = 2,
                            Color = Color3.fromRGB(0, 0, 0),
                            Transparency = 0,
                            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                        }),
                        
                        ProgressFill = React.createElement("Frame", {
                            Size = ScreenUtils.udim2(progress, 0, 1, 0), -- Fill based on progress
                            Position = ScreenUtils.udim2(0, 0, 0, 0),
                            BackgroundColor3 = canAffordRebirth and Color3.fromRGB(138, 43, 226) or Color3.fromRGB(255, 165, 0), -- Purple if complete, orange if not
                            ZIndex = 1007,
                        }, {
                            Corner = React.createElement("UICorner", {
                                CornerRadius = ScreenUtils.udim(0, 10),
                            }),
                        }),
                    }),
                }),
                
                -- Information text between progress bar and buttons
                InfoSection = React.createElement("Frame", {
                    Size = ScreenUtils.udim2(1, 0, 0, 50), -- Taller section for bigger text
                    Position = ScreenUtils.udim2(0, 0, 0, 260), -- Adjusted for lower progress bar position
                    BackgroundTransparency = 1,
                    ZIndex = 1006,
                }, {
                    -- Information text
                    InfoText = React.createElement("TextLabel", {
                        Size = ScreenUtils.udim2(1, -40, 1, 0), -- More padding
                        Position = ScreenUtils.udim2(0, 20, 0, 0),
                        BackgroundTransparency = 1,
                        Text = "Rebirthing unlocks new levels and rarer pets, but resets your money and plots.",
                        TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                        TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() + 2, -- Much bigger text
                        TextStrokeTransparency = 0,
                        TextStrokeColor3 = Color3.fromRGB(0, 150, 0), -- Green outline
                        Font = Enum.Font.GothamBold, -- Bold for better visibility
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        TextWrapped = true, -- Allow text wrapping
                        ZIndex = 1007,
                    }),
                }),
            }),
            
            -- Button section (like reference image)
            ButtonSection = React.createElement("Frame", {
                Size = ScreenUtils.udim2(1, -30, 0, 60),
                Position = ScreenUtils.udim2(0, 15, 1, -70), -- Reduced gap from -80 to -70
                BackgroundTransparency = 1,
                ZIndex = 1006,
            }, {
                -- Money rebirth button (left)
                MoneyRebirthButton = React.createElement("TextButton", {
                    Size = ScreenUtils.udim2(0, 270, 0, 50),
                    Position = ScreenUtils.udim2(0, 0, 0, 0),
                    BackgroundColor3 = canAffordRebirth and Color3.fromRGB(138, 43, 226) or Color3.fromRGB(120, 120, 120), -- Purple if affordable, gray if not
                    Text = canAffordRebirth and string.format("REBIRTH (%s)", NumberFormatter.format(rebirthCost)) or string.format("🔄 Rebirth! %s", NumberFormatter.format(rebirthCost)),
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() + 2,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    Font = Enum.Font.GothamBold,
                    ZIndex = 1007,
                    [React.Event.MouseButton1Click] = canAffordRebirth and function()
                        -- Close UI first so player can see rebirth animation
                        if props.onClose then
                            props.onClose()
                        end
                        -- Then trigger the rebirth
                        if props.onRebirth then
                            props.onRebirth()
                        end
                    end or nil,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, 10),
                    }),
                    Outline = React.createElement("UIStroke", {
                        Thickness = 3,
                        Color = Color3.fromRGB(0, 0, 0),
                        Transparency = 0,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    }),
                    
                    -- Money icon on button
                    MoneyIcon = React.createElement("ImageLabel", {
                        Size = ScreenUtils.udim2(0, 25, 0, 25),
                        Position = ScreenUtils.udim2(0, 10, 0.5, -12.5),
                        BackgroundTransparency = 1,
                        Image = IconAssets.getIcon("CURRENCY", "MONEY"),
                        ScaleType = Enum.ScaleType.Fit,
                        ZIndex = 1008,
                    }),
                }),
                
                -- Robux rebirth button (right)
                RobuxRebirthButton = React.createElement("TextButton", {
                    Size = ScreenUtils.udim2(0, 270, 0, 50),
                    Position = ScreenUtils.udim2(1, -270, 0, 0),
                    BackgroundColor3 = Color3.fromRGB(0, 162, 255), -- Robux blue
                    Text = string.format("REBIRTH %s", robuxPrice), -- Remove parentheses
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() + 2,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    Font = Enum.Font.GothamBold,
                    ZIndex = 1007,
                    [React.Event.MouseButton1Click] = handleRobuxRebirth,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, 10),
                    }),
                    Outline = React.createElement("UIStroke", {
                        Thickness = 3,
                        Color = Color3.fromRGB(0, 0, 0),
                        Transparency = 0,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    }),
                    
                    -- Robux icon on button (positioned after the price)
                    RobuxIcon = React.createElement("ImageLabel", {
                        Size = ScreenUtils.udim2(0, 20, 0, 20),
                        Position = ScreenUtils.udim2(0, 190, 0.5, -10), -- Position after text
                        BackgroundTransparency = 1,
                        Image = IconAssets.getIcon("CURRENCY", "ROBUX"),
                        ScaleType = Enum.ScaleType.Fit,
                        ZIndex = 1008,
                    }),
                }),
            }),
        })
    })
end

return RebirthUI