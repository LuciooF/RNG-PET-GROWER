-- Rebirth Progress Bar Component
-- Reusable progress bar specifically for rebirth progress

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.react)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)

local e = React.createElement

local function RebirthProgressBar(props)
    local progress = props.progress or 0
    local currentMoney = props.currentMoney or 0
    local rebirthCost = props.rebirthCost or 1
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    -- Responsive sizing
    local normalTextSize = ScreenUtils.getProportionalTextSize(screenSize, 18)
    
    return e("Frame", {
        Name = "ProgressSection",
        Size = props.size or UDim2.new(1, 0, 0, 150),
        Position = props.position or UDim2.new(0, 0, 1, -150),
        BackgroundTransparency = 1,
        ZIndex = props.zIndex or 31
    }, {
        ProgressTitle = e("TextLabel", {
            Size = UDim2.new(1, 0, 0, 25),
            Position = UDim2.new(0, 0, 0, 0),
            Text = "Progress to Next Rebirth",
            TextColor3 = Color3.fromRGB(100, 100, 100),
            TextSize = normalTextSize,
            TextWrapped = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = (props.zIndex or 31) + 1
        }),
        
        -- Progress Bar Background
        ProgressBarBg = e("Frame", {
            Size = UDim2.new(1, -60, 0, 30),
            Position = UDim2.new(0, 30, 0, 35),
            BackgroundColor3 = Color3.fromRGB(200, 200, 200),
            BorderSizePixel = 0,
            ZIndex = (props.zIndex or 31) + 1
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 15)
            }),
            
            -- Progress Bar Fill
            ProgressFill = e("Frame", {
                Size = UDim2.new(progress / 100, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(255, 200, 0),
                BorderSizePixel = 0,
                ZIndex = (props.zIndex or 31) + 2
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 15)
                }),
                Gradient = e("UIGradient", {
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 100)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 180, 0))
                    },
                    Rotation = 90
                })
            }),
            
            -- Progress Text
            ProgressText = e("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                Text = string.format("%.1f%%", progress),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = normalTextSize,
                TextWrapped = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                ZIndex = (props.zIndex or 31) + 3
            }, {
                TextStroke = e("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = 2,
                    Transparency = 0.5
                })
            })
        }),
        
        -- Money Status
        MoneyStatus = e("TextLabel", {
            Size = UDim2.new(1, 0, 0, 20),
            Position = UDim2.new(0, 0, 0, 70),
            Text = "$" .. NumberFormatter.formatCurrency(currentMoney) .. " / $" .. NumberFormatter.formatCurrency(rebirthCost),
            TextColor3 = Color3.fromRGB(100, 100, 100),
            TextSize = normalTextSize,
            TextWrapped = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = (props.zIndex or 31) + 1
        })
    })
end

return RebirthProgressBar