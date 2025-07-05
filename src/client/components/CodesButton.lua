-- Codes Button Component
-- Rectangular button on the right side of the screen

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local ScreenUtils = require(game:GetService("ReplicatedStorage").utils.ScreenUtils)
local assets = require(game:GetService("ReplicatedStorage").assets)
local e = React.createElement

local function CodesButton(props)
    local onClick = props.onClick or function() end
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    -- Responsive sizing with mobile minimum touch targets
    local scale = ScreenUtils.getProportionalScale(screenSize)
    local buttonWidth = math.max(88, ScreenUtils.getProportionalSize(screenSize, 120)) -- Wider minimum for text
    local buttonHeight = math.max(44, ScreenUtils.getProportionalSize(screenSize, 45)) -- 44pt minimum for mobile
    local iconSize = math.max(32, ScreenUtils.getProportionalSize(screenSize, 48)) -- 32pt minimum for mobile
    local textSize = ScreenUtils.getProportionalTextSize(screenSize, 18)
    
    -- Hover state
    local isHovering, setIsHovering = React.useState(false)
    
    return e("TextButton", {
        Name = "CodesButton",
        Size = UDim2.new(0, buttonWidth, 0, buttonHeight),
        Position = UDim2.new(1, -buttonWidth - 5 * scale, 0.5, 0), -- Minimal margin - close to right edge
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255), -- Pure white background
        Text = "",
        BorderSizePixel = 0,
        ZIndex = 10,
        [React.Event.Activated] = onClick,
        [React.Event.MouseEnter] = function()
            setIsHovering(true)
        end,
        [React.Event.MouseLeave] = function()
            setIsHovering(false)
        end
    }, {
        Corner = e("UICorner", {
            CornerRadius = UDim.new(0, 12)
        }),
        Stroke = e("UIStroke", {
            Color = Color3.fromRGB(0, 0, 0),
            Thickness = 3,
            Transparency = 0
        }),
        Shadow = e("ImageLabel", {
            Name = "Shadow",
            Size = UDim2.new(1, 6, 1, 6),
            Position = UDim2.new(0.5, 2, 0.5, 2),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = "rbxassetid://1316045217",
            ImageColor3 = Color3.fromRGB(0, 0, 0),
            ImageTransparency = 0.8,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(10, 10, 118, 118),
            ZIndex = 9
        }),
        -- Icon positioned slightly outside the button
        Icon = e("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0, iconSize, 0, iconSize),
            Position = UDim2.new(0, -14 * scale, 0.5, 0), -- Moved further left for better spacing
            AnchorPoint = Vector2.new(0, 0.5),
            Image = assets["vector-icon-pack-2/General/Codes/Codes Outline 256.png"] or "",
            BackgroundTransparency = 1,
            ZIndex = 12
        }),
        
        Container = e("Frame", {
            Name = "Container",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ZIndex = 11
        }, {
            Text = e("TextLabel", {
                Name = "Text",
                Size = UDim2.new(1, -20 * scale, 1, 0),
                Position = UDim2.new(0, 10 * scale, 0, 0), -- Fixed position inside button
                Text = "Codes!",
                TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                TextSize = textSize,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                BackgroundTransparency = 1,
                ZIndex = 11,
                -- Black outline for text
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            })
        }),
        -- Shine effect on hover
        Shine = isHovering and e("Frame", {
            Name = "Shine",
            Size = UDim2.new(0, 40, 2, 0),
            Position = UDim2.new(-0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            Rotation = 45,
            ZIndex = 12
        }, {
            Gradient = e("UIGradient", {
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(0.5, 0.5),
                    NumberSequenceKeypoint.new(1, 1)
                })
            })
        }) or nil
    })
end

return CodesButton