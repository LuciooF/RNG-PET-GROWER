-- FreeOpItemUI - UI panel for Free OP Item reward progress and claiming
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local React = require(ReplicatedStorage.Packages.react)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local FreeOpItemConfig = require(ReplicatedStorage.config.FreeOpItemConfig)
local GamepassConfig = require(ReplicatedStorage.config.GamepassConfig)

local function FreeOpItemUI(props)
    local config = FreeOpItemConfig.GetConfig()
    local requiredTimeSeconds = config.RequiredPlaytimeMinutes * 60
    
    -- Animation state for rainbow gradient rotation
    local rainbowRotation, setRainbowRotation = React.useState(0)
    
    -- Dynamic gamepass info
    local gamepassPrice, setGamepassPrice = React.useState("99") -- Fallback to config price
    local gamepassIcon, setGamepassIcon = React.useState("rbxasset://textures/ui/GuiImagePlaceholder.png")
    
    -- Client-side session tracking (like PlaytimeRewards)
    local sessionStartTime = props.sharedSessionStartTime or tick()
    local currentSessionTime, setCurrentSessionTime = React.useState(0)
    
    -- Use shared claim state from App.lua
    local lastClaimTime = props.sharedFreeOpLastClaimTime or 0
    local claimCount = props.sharedFreeOpClaimCount or 0
    local setLastClaimTime = props.setSharedFreeOpLastClaimTime
    local setClaimCount = props.setSharedFreeOpClaimCount
    
    -- Calculate progress and eligibility on client side with cooldown support
    local timeSinceLastClaim = (tick() - lastClaimTime) / 60 -- Convert to minutes
    local effectivePlaytime = lastClaimTime > 0 and timeSinceLastClaim or currentSessionTime
    local progress = math.min(effectivePlaytime * 60 / requiredTimeSeconds, 1)
    local timeRemaining = math.max(0, requiredTimeSeconds - (effectivePlaytime * 60))
    local canClaim = progress >= 1
    local isEligible = true
    
    -- Fetch dynamic gamepass price and icon from MarketplaceService
    React.useEffect(function()
        local petMagnetConfig = GamepassConfig.GAMEPASSES.PetMagnet
        if petMagnetConfig and petMagnetConfig.id then
            task.spawn(function()
                local success, gamepassInfo = pcall(function()
                    return MarketplaceService:GetProductInfo(petMagnetConfig.id, Enum.InfoType.GamePass)
                end)
                
                if success and gamepassInfo then
                    if gamepassInfo.PriceInRobux then
                        setGamepassPrice(tostring(gamepassInfo.PriceInRobux))
                    end
                    if gamepassInfo.IconImageAssetId and gamepassInfo.IconImageAssetId ~= 0 then
                        setGamepassIcon("rbxassetid://" .. gamepassInfo.IconImageAssetId)
                    end
                end
            end)
        end
    end, {})
    
    -- Client-side session timer and rainbow animation
    React.useEffect(function()
        local lastUpdateTime = 0
        local updateTimer = function()
            local currentTime = tick()
            local sessionMinutes = (currentTime - sessionStartTime) / 60
            
            -- Only update state once per second to avoid React loops
            if currentTime - lastUpdateTime >= 1 then
                lastUpdateTime = currentTime
                setCurrentSessionTime(sessionMinutes)
            end
            
            -- Animate rainbow gradient rotation (60 degrees per second)
            local rainbowSpeed = 60 -- degrees per second
            setRainbowRotation(function(current)
                return (current + rainbowSpeed * (1/60)) % 360
            end)
        end
        
        updateTimer()
        local heartbeatConnection = RunService.Heartbeat:Connect(updateTimer)
        
        return function()
            if heartbeatConnection then
                heartbeatConnection:Disconnect()
            end
        end
    end, {})
    
    -- Handle claim button
    local function handleClaim()
        if not canClaim then return end
        
        -- Reset progress for next claim
        setLastClaimTime(tick())
        setClaimCount(function(prev) return prev + 1 end)
        
        -- Fire remote to give reward with session validation
        local claimFreeOpItemRemote = ReplicatedStorage:FindFirstChild("ClaimFreeOpItem")
        if claimFreeOpItemRemote then
            claimFreeOpItemRemote:FireServer(effectivePlaytime)
        end
    end
    
    -- Don't render if not visible
    if not props.visible then
        return nil
    end
    
    local config = FreeOpItemConfig.GetConfig()
    local screenSize = ScreenUtils.getScreenSize()
    local screenWidth = screenSize.X
    local screenHeight = screenSize.Y
    
    -- Calculate responsive panel size (less wide, more responsive height)
    local panelWidth = math.max(ScreenUtils.getProportionalSize(360), screenWidth * 0.28)
    local panelHeight = screenHeight * 0.5 -- 50% of screen height, fully responsive
    
    -- Format time remaining using client-side calculation
    local timeText = FreeOpItemConfig.FormatTime(timeRemaining)
    local progressPercent = math.floor(progress * 100)
    
    -- Create invisible click-outside-to-close overlay
    return React.createElement("TextButton", {
        Name = "FreeOpItemUIOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 199,
        [React.Event.MouseButton1Click] = props.onClose,
    }, {
        FreeOpItemPanel = React.createElement("Frame", {
            Name = "FreeOpItemPanel",
            Size = UDim2.new(0, panelWidth, 0, panelHeight),
            Position = UDim2.new(0.5, -panelWidth/2, 0.5, -panelHeight/2),
            BackgroundTransparency = 1,
            ZIndex = 200,
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
            
            -- Header section
            Header = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(55)),
                BackgroundTransparency = 1,
                ZIndex = 201,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(12))
                }),
                
                -- Header gradient background
                GradientBackground = React.createElement("Frame", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundColor3 = Color3.fromRGB(255, 165, 0), -- Orange theme for magnet
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
                
                -- Header container with title and flanking icons
                HeaderContainer = React.createElement("Frame", {
                    Size = UDim2.new(1, -ScreenUtils.getProportionalSize(60), 1, 0),
                    Position = UDim2.new(0.5, 0, 0, 0),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    ZIndex = 202,
                }, {
                    Layout = React.createElement("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = UDim.new(0, ScreenUtils.getProportionalSize(8)), -- Small gap between elements
                        SortOrder = Enum.SortOrder.LayoutOrder
                    }),
                    
                    -- Magnet icon (left of text)
                    HeaderMagnetIcon = React.createElement("ImageLabel", {
                        Size = UDim2.new(0, ScreenUtils.getProportionalSize(35), 0, ScreenUtils.getProportionalSize(35)),
                        BackgroundTransparency = 1,
                        Image = config.MagnetIconId,
                        ScaleType = Enum.ScaleType.Fit,
                        ZIndex = 203,
                        LayoutOrder = 1
                    }),
                    
                    -- Header title (2x bigger)
                    Title = React.createElement("TextLabel", {
                        Size = UDim2.new(0, 0, 1, 0),
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundTransparency = 1,
                        Text = config.ButtonText,
                        TextColor3 = Color3.fromRGB(255, 165, 0),
                        TextSize = ScreenUtils.getTextSize(48), -- 2x bigger
                        TextStrokeTransparency = 0,
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        Font = Enum.Font.FredokaOne,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        ZIndex = 203,
                        LayoutOrder = 2
                    }),
                    
                    -- Pet icon (right of text)
                    HeaderPetIcon = React.createElement("ImageLabel", {
                        Size = UDim2.new(0, ScreenUtils.getProportionalSize(35), 0, ScreenUtils.getProportionalSize(35)),
                        BackgroundTransparency = 1,
                        Image = IconAssets.getIcon(config.PetIconAsset.type, config.PetIconAsset.name),
                        ScaleType = Enum.ScaleType.Fit,
                        ZIndex = 203,
                        LayoutOrder = 3
                    }),
                }),
                
                -- Close button
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
                Size = UDim2.new(1, -ScreenUtils.getProportionalSize(30), 1, -ScreenUtils.getProportionalSize(85)),
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(15), 0, ScreenUtils.getProportionalSize(70)),
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
                
                -- Gamepass icon container (big icon below text)
                GamepassIconContainer = React.createElement("Frame", {
                    Name = "GamepassIconContainer",
                    Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(130)), -- Container for bigger gamepass icon
                    BackgroundTransparency = 1,
                    ZIndex = 202,
                    LayoutOrder = 1,
                }, {
                    -- Pet Magnet Gamepass icon (big and centered)
                    GamepassIcon = React.createElement("ImageLabel", {
                        Size = UDim2.new(0, ScreenUtils.getProportionalSize(120), 0, ScreenUtils.getProportionalSize(120)), -- Even bigger!
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,
                        Image = gamepassIcon, -- Dynamic gamepass icon from MarketplaceService
                        ScaleType = Enum.ScaleType.Fit,
                        ZIndex = 203,
                    }),
                }),
                
                -- Description container with formatted text
                DescriptionContainer = React.createElement("Frame", {
                    Name = "DescriptionContainer",
                    Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(100)),
                    BackgroundTransparency = 1,
                    ZIndex = 202,
                    LayoutOrder = 2,
                }, {
                    -- Main description text with inline elements
                    DescriptionLabel = React.createElement("Frame", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        ZIndex = 203,
                    }, {
                        -- Layout for vertical text arrangement
                        Layout = React.createElement("UIListLayout", {
                            FillDirection = Enum.FillDirection.Vertical,
                            HorizontalAlignment = Enum.HorizontalAlignment.Center,
                            VerticalAlignment = Enum.VerticalAlignment.Center,
                            Padding = UDim.new(0, ScreenUtils.getProportionalSize(2)),
                            SortOrder = Enum.SortOrder.LayoutOrder
                        }),
                        
                        -- Line 1: "Free limited [OP] 24h Pet Magnet potion"
                        Line1Container = React.createElement("Frame", {
                            Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(30)),
                            BackgroundTransparency = 1,
                            ZIndex = 204,
                            LayoutOrder = 1
                        }, {
                            Layout = React.createElement("UIListLayout", {
                                FillDirection = Enum.FillDirection.Horizontal,
                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                VerticalAlignment = Enum.VerticalAlignment.Center,
                                Padding = UDim.new(0, ScreenUtils.getProportionalSize(3)),
                                SortOrder = Enum.SortOrder.LayoutOrder
                            }),
                            
                            Text1 = React.createElement("TextLabel", {
                                Size = UDim2.new(0, 0, 1, 0),
                                AutomaticSize = Enum.AutomaticSize.X,
                                BackgroundTransparency = 1,
                                Text = "Free limited [",
                                TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                                TextSize = ScreenUtils.getTextSize(28),
                                Font = Enum.Font.FredokaOne, -- Same font as button
                                TextStrokeTransparency = 0, -- Full black outline
                                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                                ZIndex = 205,
                                LayoutOrder = 1
                            }),
                            
                            OPText = React.createElement("TextLabel", {
                                Size = UDim2.new(0, 0, 1, 0),
                                AutomaticSize = Enum.AutomaticSize.X,
                                BackgroundTransparency = 1,
                                Text = "OP",
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                TextSize = ScreenUtils.getTextSize(28),
                                Font = Enum.Font.FredokaOne, -- Same font as button
                                TextStrokeTransparency = 0,
                                TextStrokeColor3 = Color3.fromRGB(0, 0, 0), -- Black outline
                                ZIndex = 205,
                                LayoutOrder = 2
                            }, {
                                -- Animated rainbow gradient
                                RainbowGradient = React.createElement("UIGradient", {
                                    Color = ColorSequence.new({
                                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                                        ColorSequenceKeypoint.new(0.14, Color3.fromRGB(255, 127, 0)),
                                        ColorSequenceKeypoint.new(0.28, Color3.fromRGB(255, 255, 0)),
                                        ColorSequenceKeypoint.new(0.42, Color3.fromRGB(0, 255, 0)),
                                        ColorSequenceKeypoint.new(0.57, Color3.fromRGB(0, 0, 255)),
                                        ColorSequenceKeypoint.new(0.71, Color3.fromRGB(75, 0, 130)),
                                        ColorSequenceKeypoint.new(0.85, Color3.fromRGB(148, 0, 211)),
                                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
                                    }),
                                    Rotation = rainbowRotation
                                })
                            }),
                            
                            Text2 = React.createElement("TextLabel", {
                                Size = UDim2.new(0, 0, 1, 0),
                                AutomaticSize = Enum.AutomaticSize.X,
                                BackgroundTransparency = 1,
                                Text = "] 24h Pet Magnet potion",
                                TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                                TextSize = ScreenUtils.getTextSize(28),
                                Font = Enum.Font.FredokaOne, -- Same font as button
                                TextStrokeTransparency = 0, -- Full black outline
                                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                                ZIndex = 205,
                                LayoutOrder = 3
                            })
                        }),
                        
                        -- Line 2: "Worth {price} Robux!" with green value and icon
                        Line2Container = React.createElement("Frame", {
                            Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(35)),
                            BackgroundTransparency = 1,
                            ZIndex = 204,
                            LayoutOrder = 2
                        }, {
                            Layout = React.createElement("UIListLayout", {
                                FillDirection = Enum.FillDirection.Horizontal,
                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                VerticalAlignment = Enum.VerticalAlignment.Center,
                                Padding = UDim.new(0, ScreenUtils.getProportionalSize(3)),
                                SortOrder = Enum.SortOrder.LayoutOrder
                            }),
                            
                            WorthText = React.createElement("TextLabel", {
                                Size = UDim2.new(0, 0, 1, 0),
                                AutomaticSize = Enum.AutomaticSize.X,
                                BackgroundTransparency = 1,
                                Text = "Worth ",
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                TextSize = ScreenUtils.getTextSize(28),
                                Font = Enum.Font.FredokaOne,
                                TextStrokeTransparency = 0,
                                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                                ZIndex = 205,
                                LayoutOrder = 1
                            }),
                            
                            PriceText = React.createElement("TextLabel", {
                                Size = UDim2.new(0, 0, 1, 0),
                                AutomaticSize = Enum.AutomaticSize.X,
                                BackgroundTransparency = 1,
                                Text = gamepassPrice, -- Dynamic price from MarketplaceService
                                TextColor3 = Color3.fromRGB(85, 255, 85), -- Green like OPPetButton
                                TextSize = ScreenUtils.getTextSize(28),
                                Font = Enum.Font.FredokaOne,
                                TextStrokeTransparency = 0,
                                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                                ZIndex = 205,
                                LayoutOrder = 2
                            }),
                            
                            RobuxIcon = React.createElement("ImageLabel", {
                                Size = UDim2.new(0, ScreenUtils.getProportionalSize(24), 0, ScreenUtils.getProportionalSize(24)),
                                BackgroundTransparency = 1,
                                Image = "rbxasset://textures/ui/common/robux.png", -- Correct Robux icon path
                                ImageColor3 = Color3.fromRGB(85, 255, 85), -- Green like the price
                                ScaleType = Enum.ScaleType.Fit,
                                ZIndex = 205,
                                LayoutOrder = 3
                            }),
                            
                            ExclamationText = React.createElement("TextLabel", {
                                Size = UDim2.new(0, 0, 1, 0),
                                AutomaticSize = Enum.AutomaticSize.X,
                                BackgroundTransparency = 1,
                                Text = "!",
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                TextSize = ScreenUtils.getTextSize(28),
                                Font = Enum.Font.FredokaOne,
                                TextStrokeTransparency = 0,
                                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                                ZIndex = 205,
                                LayoutOrder = 4
                            })
                        }),
                        
                        -- Line 3: "Rewarded for playing for X minutes this session!"
                        Line3 = React.createElement("TextLabel", {
                            Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(30)),
                            BackgroundTransparency = 1,
                            Text = "Rewarded for playing for " .. config.RequiredPlaytimeMinutes .. " minute" .. (config.RequiredPlaytimeMinutes == 1 and "" or "s") .. " this session!",
                            TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                            TextSize = ScreenUtils.getTextSize(28),
                            Font = Enum.Font.FredokaOne, -- Same font as button
                            TextStrokeTransparency = 0, -- Full black outline
                            TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                            TextXAlignment = Enum.TextXAlignment.Center,
                            TextWrapped = true,
                            ZIndex = 204,
                            LayoutOrder = 3
                        })
                    })
                }),
                
                -- Progress section
                ProgressSection = React.createElement("Frame", {
                    Name = "ProgressSection",
                    Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(60)),
                    BackgroundTransparency = 1,
                    ZIndex = 202,
                    LayoutOrder = 3,
                }, {
                    -- Progress label (2x bigger with white outline)
                    ProgressLabel = React.createElement("TextLabel", {
                        Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(30)),
                        Position = UDim2.new(0, 0, 0, 0),
                        BackgroundTransparency = 1,
                        Text = canClaim and "Ready to claim!" or ("Progress: " .. progressPercent .. "% (" .. timeText .. " remaining)"),
                        TextColor3 = canClaim and Color3.fromRGB(50, 205, 50) or Color3.fromRGB(50, 50, 50),
                        TextSize = ScreenUtils.getTextSize(28), -- 2x bigger
                        Font = Enum.Font.FredokaOne,
                        TextStrokeTransparency = 0,
                        TextStrokeColor3 = Color3.fromRGB(255, 255, 255),
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ZIndex = 203,
                    }),
                    
                    -- Progress bar background
                    ProgressBarBackground = React.createElement("Frame", {
                        Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(20)),
                        Position = UDim2.new(0, 0, 0, ScreenUtils.getProportionalSize(30)),
                        BackgroundColor3 = Color3.fromRGB(200, 200, 200),
                        BorderSizePixel = 0,
                        ZIndex = 203,
                    }, {
                        Corner = React.createElement("UICorner", {
                            CornerRadius = ScreenUtils.udim(0, 10),
                        }),
                        
                        -- Progress bar fill
                        ProgressBarFill = React.createElement("Frame", {
                            Size = UDim2.new(progress, 0, 1, 0),
                            Position = UDim2.new(0, 0, 0, 0),
                            BackgroundColor3 = canClaim and Color3.fromRGB(50, 205, 50) or Color3.fromRGB(255, 165, 0),
                            BorderSizePixel = 0,
                            ZIndex = 204,
                        }, {
                            Corner = React.createElement("UICorner", {
                                CornerRadius = ScreenUtils.udim(0, 10),
                            }),
                        }),
                    }),
                }),
                
                -- Claim button (2x bigger text)
                ClaimButton = React.createElement("TextButton", {
                    Name = "ClaimButton",
                    Size = UDim2.new(0.8, 0, 0, ScreenUtils.getProportionalSize(50)),
                    BackgroundColor3 = canClaim and Color3.fromRGB(50, 205, 50) or Color3.fromRGB(150, 150, 150),
                    BorderSizePixel = 0,
                    Text = canClaim and "CLAIM REWARD!" or "NOT READY",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.getTextSize(36), -- 2x bigger
                    Font = Enum.Font.FredokaOne,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    Active = canClaim,
                    ZIndex = 202,
                    LayoutOrder = 4,
                    [React.Event.Activated] = handleClaim,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, 8)
                    }),
                    
                    Stroke = React.createElement("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = 2,
                        Transparency = 0
                    })
                })
            })
        })
    })
end

return FreeOpItemUI