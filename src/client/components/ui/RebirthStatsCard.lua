-- Rebirth Stats Card Component
-- Reusable card component for displaying current/next rebirth stats

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.react)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)

local assets = require(ReplicatedStorage.assets)
local e = React.createElement

local function RebirthStatsCard(props)
    local cardType = props.cardType or "current" -- "current" or "next"
    local rebirths = props.rebirths or 0
    local multiplier = props.multiplier or 1
    local achievementDate = props.achievementDate or "Unknown"
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local isNext = cardType == "next"
    
    -- Responsive sizing
    local normalTextSize = ScreenUtils.getProportionalTextSize(screenSize, 18)
    local cardValueSize = ScreenUtils.getProportionalTextSize(screenSize, 24)
    local largeValueSize = ScreenUtils.getProportionalTextSize(screenSize, 28)
    
    -- Card styling based on type
    local titleText = isNext and "NEXT REBIRTH" or "CURRENT STATUS"
    local titleColor = isNext and Color3.fromRGB(255, 150, 0) or Color3.fromRGB(150, 100, 200)
    local strokeColor = isNext and Color3.fromRGB(255, 200, 100) or Color3.fromRGB(200, 150, 255)
    local gradient = isNext and ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 245, 200)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 235, 150))
    } or nil
    
    local shineEffect = nil
    if isNext then
        shineEffect = e("Frame", {
            Size = UDim2.new(0.3, 0, 1, 0),
            Position = UDim2.new(-0.3, 0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.7,
            BorderSizePixel = 0,
            ZIndex = (props.zIndex or 32) + 3
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 15)
            }),
            Gradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
                },
                Transparency = NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(0.5, 0.3),
                    NumberSequenceKeypoint.new(1, 1)
                },
                Rotation = 45
            })
        })
    end
    
    return e("Frame", {
        Size = props.size or UDim2.new(0.4, -10, 1, 0),
        Position = props.position or UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        ZIndex = props.zIndex or 32
    }, {
        Corner = e("UICorner", {
            CornerRadius = UDim.new(0, 15)
        }),
        Stroke = e("UIStroke", {
            Color = strokeColor,
            Thickness = 2,
            Transparency = 0.3
        }),
        Gradient = gradient and e("UIGradient", {
            Color = gradient,
            Rotation = 90
        }) or nil,
        
        -- Shiny effect for next card
        ShineEffect = shineEffect,
        
        Title = e("TextLabel", {
            Size = UDim2.new(1, 0, 0, 30),
            Position = UDim2.new(0, 0, 0, 10),
            Text = titleText,
            TextColor3 = titleColor,
            TextSize = normalTextSize,
            TextWrapped = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            ZIndex = (props.zIndex or 32) + 1
        }),
        
        RebirthCount = e("Frame", {
            Size = UDim2.new(1, -20, 0, 40),
            Position = UDim2.new(0, 10, 0, 50),
            BackgroundTransparency = 1,
            ZIndex = (props.zIndex or 32) + 1
        }, {
            Layout = e("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 10)
            }),
            
            RebirthIcon = e("ImageLabel", {
                Size = UDim2.new(0, 35, 0, 35),
                Image = assets["vector-icon-pack-2/General/Rebirth/Rebirth Outline 256.png"] or "",
                BackgroundTransparency = 1,
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = (props.zIndex or 32) + 2
            }),
            
            RebirthText = e("TextLabel", {
                Size = UDim2.new(0, 0, 1, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                Text = tostring(rebirths),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = largeValueSize,
                TextWrapped = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                ZIndex = (props.zIndex or 32) + 2
            }, {
                TextStroke = e("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = 2,
                    Transparency = 0
                })
            })
        }),
        
        Benefits = e("Frame", {
            Size = UDim2.new(1, -20, 0, 40),
            Position = UDim2.new(0, 10, 0, 95),
            BackgroundTransparency = 1,
            ZIndex = (props.zIndex or 32) + 1
        }, {
            Layout = e("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 5)
            }),
            
            BenefitIcon = e("ImageLabel", {
                Size = UDim2.new(0, 30, 0, 30),
                Image = assets["vector-icon-pack-2/General/Upgrade/Upgrade Outline 256.png"] or "",
                BackgroundTransparency = 1,
                ScaleType = Enum.ScaleType.Fit,
                ImageColor3 = Color3.fromRGB(255, 200, 0),
                ZIndex = (props.zIndex or 32) + 2
            }),
            
            BenefitText = e("TextLabel", {
                Size = UDim2.new(0, 0, 1, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                Text = string.format("%.2fx Boost", multiplier),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = cardValueSize,
                TextWrapped = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                ZIndex = (props.zIndex or 32) + 2
            }, {
                TextStroke = e("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = 2,
                    Transparency = 0
                })
            })
        }),
        
        DateInfo = e("TextLabel", {
            Size = UDim2.new(1, -20, 0, 25),
            Position = UDim2.new(0, 10, 0, 140),
            Text = (isNext and "Predicted: " or "Achieved: ") .. achievementDate,
            TextColor3 = Color3.fromRGB(100, 100, 100),
            TextSize = normalTextSize,
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = (props.zIndex or 32) + 1
        }),
        
        -- Prediction explanation for next card
        PredictionExplanation = isNext and props.predictionExplanation and e("TextLabel", {
            Size = UDim2.new(1, -20, 0, 20),
            Position = UDim2.new(0, 10, 0, 165),
            Text = props.predictionExplanation,
            TextColor3 = Color3.fromRGB(120, 120, 120),
            TextSize = ScreenUtils.getProportionalTextSize(screenSize, 14),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = (props.zIndex or 32) + 1
        }) or nil
    })
end

return RebirthStatsCard