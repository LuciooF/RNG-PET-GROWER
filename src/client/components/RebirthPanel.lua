-- Modern Rebirth Panel Component for Pet Grower RNG
-- Refactored to use modular components for maintainability
-- Shows current rebirth status, benefits, and next rebirth preview

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.react)
local e = React.createElement

local assets = require(ReplicatedStorage.assets)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)
local RebirthCalculator = require(ReplicatedStorage.utils.RebirthCalculator)
local RebirthProgressBar = require(script.Parent.ui.RebirthProgressBar)
local RebirthStatsCard = require(script.Parent.ui.RebirthStatsCard)

local function RebirthPanel(props)
    local playerData = props.playerData
    local visible = props.visible or false
    local onClose = props.onClose or function() end
    local onRebirth = props.onRebirth or function() end
    
    -- Calculate rebirth data using RebirthCalculator
    local currentRebirths = playerData.rebirths or 0
    local currentMultiplier = RebirthCalculator.getCurrentMultiplier(currentRebirths)
    local nextRebirths = currentRebirths + 1
    local nextMultiplier = RebirthCalculator.getNextMultiplier(currentRebirths)
    
    local rebirthCost = RebirthCalculator.getRebirthCost()
    local canAfford = RebirthCalculator.canAffordRebirth(playerData.money)
    local progress = RebirthCalculator.calculateProgress(playerData.money, rebirthCost)
    
    -- Calculate dates
    local achievedDate = RebirthCalculator.getAchievementDate(currentRebirths)
    local nextDateText, predictionExplanation = RebirthCalculator.predictNextRebirthDate(playerData.money, rebirthCost)
    
    -- Responsive sizing
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local scale = ScreenUtils.getProportionalScale(screenSize)
    local panelWidth = math.min(screenSize.X * 0.8, ScreenUtils.getProportionalSize(screenSize, 800))
    local panelHeight = math.min(screenSize.Y * 0.75, ScreenUtils.getProportionalSize(screenSize, 550))
    
    -- Proportional text sizes
    local titleTextSize = ScreenUtils.getProportionalTextSize(screenSize, 32)
    local normalTextSize = ScreenUtils.getProportionalTextSize(screenSize, 18)
    local buttonTextSize = ScreenUtils.getProportionalTextSize(screenSize, 22)
    
    -- Handle rebirth action
    local function handleRebirth()
        if canAfford then
            if onRebirth then
                onRebirth() -- This will trigger the animation and fire the remote
            else
                warn("onRebirth callback not provided!")
            end
        end
    end
    
    return e("Frame", {
        Name = "RebirthContainer",
        Size = UDim2.new(0, panelWidth, 0, panelHeight + 50),
        Position = UDim2.new(0.5, -panelWidth / 2, 0.5, -(panelHeight + 50) / 2),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = visible,
        ZIndex = 30
    }, {
        
        RebirthPanel = e("Frame", {
            Name = "RebirthPanel",
            Size = UDim2.new(0, panelWidth, 0, panelHeight),
            Position = UDim2.new(0, 0, 0, 50),
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
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 180, 50)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 120, 0))
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
                    
                    RebirthIcon = e("ImageLabel", {
                        Name = "RebirthIcon",
                        Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 24), 0, ScreenUtils.getProportionalSize(screenSize, 24)),
                        Image = assets["vector-icon-pack-2/General/Rebirth/Rebirth Outline 256.png"] or "",
                        BackgroundTransparency = 1,
                        ScaleType = Enum.ScaleType.Fit,
                        ImageColor3 = Color3.fromRGB(255, 255, 255),
                        ZIndex = 34,
                        LayoutOrder = 1
                    }),
                    
                    TitleText = e("TextLabel", {
                        Size = UDim2.new(1, 0, 1, 0),
                        Text = "REBIRTHS",
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = normalTextSize,
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
                Color = Color3.fromRGB(255, 140, 0),
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
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 32), 0, ScreenUtils.getProportionalSize(screenSize, 32)),
                Position = UDim2.new(1, -16, 0, -16),
                Image = assets["vector-icon-pack-2/UI/X Button/X Button Outline 256.png"] or "",
                ImageColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 34,
                ScaleType = Enum.ScaleType.Fit,
                [React.Event.Activated] = onClose,
                [React.Event.MouseEnter] = function(button)
                    button.ImageColor3 = Color3.fromRGB(180, 180, 180)
                end,
                [React.Event.MouseLeave] = function(button)
                    button.ImageColor3 = Color3.fromRGB(255, 255, 255)
                end
            }),
            
            -- Main Content
            MainContent = e("Frame", {
                Name = "MainContent",
                Size = UDim2.new(1, ScreenUtils.getProportionalSize(screenSize, -40), 1, ScreenUtils.getProportionalSize(screenSize, -80)),
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 20), 0, ScreenUtils.getProportionalSize(screenSize, 40)),
                BackgroundTransparency = 1,
                ZIndex = 31
            }, {
                -- Info Text
                InfoText = e("TextLabel", {
                    Size = UDim2.new(1, -20, 0, ScreenUtils.getProportionalSize(screenSize, 80)),
                    Position = UDim2.new(0, 10, 0, 0),
                    Text = "🌟 Rebirth resets your money but gives you permanent money multiplier! 🌟",
                    TextColor3 = Color3.fromRGB(100, 50, 150),
                    TextSize = titleTextSize * 0.8,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    TextWrapped = true,
                    TextScaled = true,
                    ZIndex = 32
                }),
                
                -- Stats Container using modular components
                StatsContainer = e("Frame", {
                    Size = UDim2.new(1, 0, 0.6, ScreenUtils.getProportionalSize(screenSize, -90)),
                    Position = UDim2.new(0, 0, 0, ScreenUtils.getProportionalSize(screenSize, 90)),
                    BackgroundTransparency = 1,
                    ZIndex = 31
                }, {
                    -- Current Stats using modular component
                    CurrentStats = e(RebirthStatsCard, {
                        cardType = "current",
                        rebirths = currentRebirths,
                        multiplier = currentMultiplier,
                        achievementDate = achievedDate,
                        screenSize = screenSize,
                        size = UDim2.new(0.4, -10, 1, 0),
                        position = UDim2.new(0, 0, 0, 0),
                        zIndex = 32
                    }),
                    
                    -- Arrow
                    Arrow = e("ImageLabel", {
                        Size = UDim2.new(0, 60, 0, 60),
                        Position = UDim2.new(0.5, -30, 0.5, -30),
                        Image = assets["vector-icon-pack-2/General/Arrow 2/Arrow 2 Right Outline 256.png"] or "rbxasset://textures/ui/Controls/RotateRight.png",
                        BackgroundTransparency = 1,
                        ScaleType = Enum.ScaleType.Fit,
                        ImageColor3 = Color3.fromRGB(255, 140, 0),
                        ZIndex = 35
                    }),
                    
                    -- Next Stats using modular component
                    NextStats = e(RebirthStatsCard, {
                        cardType = "next",
                        rebirths = nextRebirths,
                        multiplier = nextMultiplier,
                        achievementDate = nextDateText,
                        predictionExplanation = predictionExplanation,
                        screenSize = screenSize,
                        size = UDim2.new(0.4, -10, 1, 0),
                        position = UDim2.new(0.6, 10, 0, 0),
                        zIndex = 32
                    })
                }),
                
                -- Progress Section using modular component
                ProgressSection = e(RebirthProgressBar, {
                    progress = progress,
                    currentMoney = playerData.money,
                    rebirthCost = rebirthCost,
                    screenSize = screenSize,
                    size = UDim2.new(1, 0, 0, 100),
                    position = UDim2.new(0, 0, 1, -100),
                    zIndex = 31
                }),
                
                -- Rebirth Button (full width)
                RebirthButton = e("TextButton", {
                    Size = UDim2.new(1, -40, 0, 50),
                    Position = UDim2.new(0, 20, 1, -50),
                    Text = "",
                    BackgroundColor3 = canAfford and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(180, 80, 80),
                    BackgroundTransparency = canAfford and 0 or 0.3,
                    BorderSizePixel = 0,
                    AutoButtonColor = canAfford,
                    ZIndex = 32,
                    [React.Event.Activated] = canAfford and handleRebirth or nil
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 10)
                    }),
                    Stroke = e("UIStroke", {
                        Color = canAfford and Color3.fromRGB(80, 160, 80) or Color3.fromRGB(120, 40, 40),
                        Thickness = 3,
                        Transparency = canAfford and 0.2 or 0.5
                    }),
                    Gradient = e("UIGradient", {
                        Color = canAfford and ColorSequence.new{
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 220, 120)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 180, 80))
                        } or ColorSequence.new{
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 100, 100)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 60, 60))
                        },
                        Rotation = 90
                    }),
                    
                    ButtonContent = e("Frame", {
                        Size = UDim2.new(1, -10, 1, -10),
                        Position = UDim2.new(0, 5, 0, 5),
                        BackgroundTransparency = 1,
                        ZIndex = 33
                    }, {
                        
                        ButtonText = e("TextLabel", {
                            Size = UDim2.new(1, 0, 0.5, 0),
                            Position = UDim2.new(0, 0, 0, 0),
                            Text = canAfford and "REBIRTH" or "NEED",
                            TextColor3 = Color3.fromRGB(255, 255, 255),
                            TextSize = buttonTextSize * 0.8,
                            TextWrapped = true,
                            BackgroundTransparency = 1,
                            Font = Enum.Font.GothamBold,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            ZIndex = 34
                        }, {
                            TextStroke = e("UIStroke", {
                                Color = Color3.fromRGB(0, 0, 0),
                                Thickness = 2,
                                Transparency = 0
                            })
                        }),
                        
                        PriceContainer = e("Frame", {
                            Size = UDim2.new(1, 0, 0.5, 0),
                            Position = UDim2.new(0, 0, 0.5, 0),
                            BackgroundTransparency = 1,
                            ZIndex = 33
                        }, {
                            Layout = e("UIListLayout", {
                                FillDirection = Enum.FillDirection.Horizontal,
                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                VerticalAlignment = Enum.VerticalAlignment.Center,
                                Padding = UDim.new(0, 3),
                                SortOrder = Enum.SortOrder.LayoutOrder
                            }),
                            
                            CashIcon = e("ImageLabel", {
                                Size = UDim2.new(0, buttonTextSize * 0.6, 0, buttonTextSize * 0.6),
                                Image = assets["vector-icon-pack-2/Currency/Cash/Cash Outline 256.png"] or "",
                                BackgroundTransparency = 1,
                                ScaleType = Enum.ScaleType.Fit,
                                ImageColor3 = Color3.fromRGB(255, 255, 255),
                                ZIndex = 34,
                                LayoutOrder = 1
                            }),
                            
                            CostText = e("TextLabel", {
                                Size = UDim2.new(0, 0, 1, 0),
                                AutomaticSize = Enum.AutomaticSize.X,
                                Text = NumberFormatter.formatCurrency(rebirthCost),
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                TextSize = buttonTextSize * 0.7,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.GothamBold,
                                ZIndex = 34,
                                LayoutOrder = 2
                            }, {
                                TextStroke = e("UIStroke", {
                                    Color = Color3.fromRGB(0, 0, 0),
                                    Thickness = 1,
                                    Transparency = 0
                                })
                            })
                        })
                    })
                })
            })
        })
    })
end

return RebirthPanel