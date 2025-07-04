-- Shop Gamepass Card Component
-- Exact copy from GamepassPanel.lua in other game
-- Professional card design for gamepasses with circular icons and proper layout

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local React = require(ReplicatedStorage.Packages.react)
local e = React.createElement

-- Import shared utilities
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)

-- Sound effects
local function playSound(soundType)
    -- Placeholder for sound effects
end

-- Function to create flip animation for icons
local function createFlipAnimation(iconRef, animationTracker)
    if not iconRef or not iconRef.current then return end
    
    -- Cancel any existing animation for this icon
    if animationTracker and animationTracker.current then
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
    if animationTracker then
        animationTracker.current = flipTween
    end
    
    flipTween:Play()
    flipTween.Completed:Connect(function()
        -- Reset rotation after animation
        if iconRef.current then
            iconRef.current.Rotation = 0
        end
        -- Clear the tracker
        if animationTracker and animationTracker.current == flipTween then
            animationTracker.current = nil
        end
        flipTween:Destroy()
    end)
end

local function ShopGamepassCard(props)
    local gamepass = props.gamepass
    local layoutOrder = props.layoutOrder or 1
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local onPurchase = props.onPurchase or function() end
    local customSize = props.customSize
    
    if not gamepass then
        return nil
    end
    
    -- Use custom size if provided, otherwise use default sizing
    local cardWidth, cardHeight
    if customSize then
        cardWidth = customSize.width
        cardHeight = customSize.height
    else
        -- Default sizing - match original gamepass cards
        cardWidth = ScreenUtils.getProportionalSize(screenSize, 220)
        cardHeight = ScreenUtils.getProportionalSize(screenSize, 200)
    end
    
    -- Check if player owns this gamepass (for this example, assume not owned)
    local isOwned = false -- You can add ownership logic here
    
    -- Proportional text sizes
    local normalTextSize = ScreenUtils.getProportionalTextSize(screenSize, 18)
    local cardTitleSize = ScreenUtils.getProportionalTextSize(screenSize, 20)
    local cardValueSize = ScreenUtils.getProportionalTextSize(screenSize, 16)
    
    -- Create refs for animation
    local gamepassIconRef = React.useRef(nil)
    local robuxIconRef = React.useRef(nil)
    local gamepassAnimTracker = React.useRef(nil)
    local robuxAnimTracker = React.useRef(nil)
    
    return e("Frame", {
        Name = "ShopGamepassCardContainer",
        Size = customSize and UDim2.new(1, -10, 1, -10) or UDim2.new(0, cardWidth, 0, cardHeight),
        Position = customSize and UDim2.new(0, 5, 0, 5) or UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        LayoutOrder = layoutOrder,
        ZIndex = 32
    }, {
        GamepassCard = e("TextButton", {
            Name = gamepass.name .. "Card",
            Text = "",
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
            ZIndex = 32,
            AutoButtonColor = false,
            Size = UDim2.new(1, 0, 1, 0),
            [React.Event.MouseEnter] = function()
                if not isOwned then
                    playSound("hover")
                    createFlipAnimation(gamepassIconRef, gamepassAnimTracker)
                    createFlipAnimation(robuxIconRef, robuxAnimTracker)
                end
            end,
            [React.Event.Activated] = function()
                if not isOwned then
                    playSound("click")
                    createFlipAnimation(gamepassIconRef, gamepassAnimTracker)
                    createFlipAnimation(robuxIconRef, robuxAnimTracker)
                    onPurchase(gamepass)
                end
            end
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 15)
            }),
            
            -- Card Gradient Background
            CardGradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, isOwned and Color3.fromRGB(240, 255, 240) or Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(1, isOwned and Color3.fromRGB(220, 245, 220) or Color3.fromRGB(248, 252, 255))
                },
                Rotation = 45
            }),
            
            Stroke = e("UIStroke", {
                Color = isOwned and Color3.fromRGB(100, 200, 100) or (gamepass.gradientColors and gamepass.gradientColors[1] or Color3.fromRGB(100, 150, 255)),
                Thickness = 3,
                Transparency = 0.1
            }),
            
            -- Owned Badge
            OwnedBadge = isOwned and e("Frame", {
                Name = "OwnedBadge",
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 60), 0, ScreenUtils.getProportionalSize(screenSize, 25)),
                Position = UDim2.new(1, ScreenUtils.getProportionalSize(screenSize, -70), 0, ScreenUtils.getProportionalSize(screenSize, 10)),
                BackgroundColor3 = Color3.fromRGB(50, 150, 50),
                BorderSizePixel = 0,
                ZIndex = 35
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 12)
                }),
                BadgeText = e("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "OWNED",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = normalTextSize,
                    TextWrapped = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    ZIndex = 35
                })
            }) or nil,
            
            -- Category Badge
            CategoryBadge = e("Frame", {
                Name = "CategoryBadge",
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 100), 0, ScreenUtils.getProportionalSize(screenSize, 20)),
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 10), 0, ScreenUtils.getProportionalSize(screenSize, 10)),
                BackgroundColor3 = gamepass.gradientColors and gamepass.gradientColors[2] or Color3.fromRGB(80, 130, 255),
                BorderSizePixel = 0,
                ZIndex = 34
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 10)
                }),
                CategoryText = e("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = gamepass.category or "💎 Premium",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = normalTextSize,
                    TextWrapped = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    ZIndex = 34
                })
            }),
            
            -- Gamepass Icon
            IconContainer = e("Frame", {
                Name = "IconContainer",
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 60), 0, ScreenUtils.getProportionalSize(screenSize, 60)),
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 15), 0, ScreenUtils.getProportionalSize(screenSize, 40)),
                BackgroundColor3 = Color3.fromRGB(40, 45, 55),
                BorderSizePixel = 0,
                ZIndex = 33
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0.5, 0) -- Make it perfectly circular
                }),
                IconGradient = e("UIGradient", {
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, gamepass.gradientColors and gamepass.gradientColors[1] or Color3.fromRGB(100, 150, 255)),
                        ColorSequenceKeypoint.new(1, gamepass.gradientColors and gamepass.gradientColors[2] or Color3.fromRGB(80, 130, 255))
                    },
                    Rotation = 45
                }),
                -- White border ring for extra polish
                IconStroke = e("UIStroke", {
                    Color = Color3.fromRGB(255, 255, 255),
                    Thickness = 2,
                    Transparency = 0.3
                }),
                Icon = e("ImageLabel", {
                    Name = "GamepassIcon",
                    Size = UDim2.new(0.9, 0, 0.9, 0),
                    Position = UDim2.new(0.05, 0, 0.05, 0),
                    Image = gamepass.icon or "rbxassetid://6031068426",
                    BackgroundTransparency = 1,
                    ImageColor3 = Color3.fromRGB(255, 255, 255),
                    ZIndex = 34,
                    ref = gamepassIconRef
                }, {
                    -- Make the icon itself circular too for perfect fit
                    IconCorner = e("UICorner", {
                        CornerRadius = UDim.new(0.5, 0)
                    })
                })
            }),
            
            -- Gamepass Name
            GamepassName = e("TextLabel", {
                Name = "GamepassName",
                Size = UDim2.new(1, ScreenUtils.getProportionalSize(screenSize, -95), 0, ScreenUtils.getProportionalSize(screenSize, 25)),
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 85), 0, ScreenUtils.getProportionalSize(screenSize, 40)),
                Text = gamepass.displayName or gamepass.name,
                TextColor3 = Color3.fromRGB(40, 50, 80),
                TextSize = cardTitleSize,
                TextWrapped = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 33
            }),
            
            -- Gamepass Description
            Description = e("TextLabel", {
                Name = "Description",
                Size = UDim2.new(1, ScreenUtils.getProportionalSize(screenSize, -95), 0, ScreenUtils.getProportionalSize(screenSize, 35)),
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 85), 0, ScreenUtils.getProportionalSize(screenSize, 65)),
                Text = gamepass.description or "Unlock powerful features and boost your experience!",
                TextColor3 = Color3.fromRGB(70, 80, 120),
                TextSize = ScreenUtils.getProportionalTextSize(screenSize, 12),
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
                ZIndex = 33
            }),
            
            -- Purchase Button
            PurchaseButton = e("TextButton", {
                Name = "PurchaseButton",
                Size = UDim2.new(1, ScreenUtils.getProportionalSize(screenSize, -20), 0, ScreenUtils.getProportionalSize(screenSize, 35)),
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 10), 1, ScreenUtils.getProportionalSize(screenSize, -45)),
                Text = isOwned and "✅ OWNED" or "",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = normalTextSize,
                TextWrapped = true,
                BackgroundColor3 = isOwned and Color3.fromRGB(50, 150, 50) or (gamepass.gradientColors and gamepass.gradientColors[1] or Color3.fromRGB(100, 150, 255)),
                BorderSizePixel = 0,
                Font = Enum.Font.GothamBold,
                ZIndex = 33,
                Active = not isOwned,
                AutoButtonColor = not isOwned,
                [React.Event.Activated] = not isOwned and function()
                    onPurchase(gamepass)
                end or nil
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 10)
                }),
                ButtonGradient = e("UIGradient", {
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, isOwned and Color3.fromRGB(60, 180, 60) or (gamepass.gradientColors and gamepass.gradientColors[1] or Color3.fromRGB(100, 150, 255))),
                        ColorSequenceKeypoint.new(1, isOwned and Color3.fromRGB(40, 140, 40) or (gamepass.gradientColors and gamepass.gradientColors[2] or Color3.fromRGB(80, 130, 255)))
                    },
                    Rotation = 45
                }),
                ButtonStroke = e("UIStroke", {
                    Color = Color3.fromRGB(255, 255, 255),
                    Thickness = 2,
                    Transparency = 0.2
                }),
                TextStroke = e("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = 3,
                    Transparency = 0.3,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
                }),
                
                -- Robux Icon and Price (only for unowned gamepasses)
                PriceContainer = not isOwned and e("Frame", {
                    Name = "PriceContainer",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    ZIndex = 34
                }, {
                    Layout = e("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = UDim.new(0, ScreenUtils.getProportionalSize(screenSize, 5)),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    }),
                    
                    RobuxIcon = e("ImageLabel", {
                        Name = "RobuxIcon",
                        Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 28), 0, ScreenUtils.getProportionalSize(screenSize, 28)),
                        Image = "rbxasset://textures/ui/common/robux.png", -- Official Robux icon
                        BackgroundTransparency = 1,
                        ImageColor3 = Color3.fromRGB(255, 255, 255),
                        ZIndex = 34,
                        LayoutOrder = 1,
                        ref = robuxIconRef
                    }),
                    
                    PriceText = e("TextLabel", {
                        Name = "PriceText",
                        Size = UDim2.new(0, 0, 1, 0),
                        AutomaticSize = Enum.AutomaticSize.X,
                        Text = tostring(gamepass.price or 99),
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = cardValueSize,
                        TextWrapped = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold,
                        ZIndex = 34,
                        LayoutOrder = 2
                    }, {
                        TextStroke = e("UIStroke", {
                            Color = Color3.fromRGB(0, 0, 0),
                            Thickness = 3,
                            Transparency = 0.3,
                            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
                        })
                    })
                }) or nil
            })
        })
    })
end

return ShopGamepassCard