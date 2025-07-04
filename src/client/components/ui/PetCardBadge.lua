-- Pet Card Badge Component
-- Reusable badge component for pet cards
-- Extracted from PetCardComponent.lua for better modularity

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.react)
local e = React.createElement

local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)

local PetCardBadge = {}

-- Create a standard badge with text
function PetCardBadge.createTextBadge(props)
    local text = props.text or ""
    local size = props.size or UDim2.new(0.4, 0, 0.06, 0)
    local position = props.position or UDim2.new(0.5, 0, 0, 0)
    local backgroundColor = props.backgroundColor or Color3.fromRGB(150, 150, 150)
    local textColor = props.textColor or Color3.fromRGB(255, 255, 255)
    local textSize = props.textSize or 14
    local anchorPoint = props.anchorPoint or Vector2.new(0.5, 0)
    local zIndex = props.zIndex or 33
    
    return e("Frame", {
        Name = props.name or "Badge",
        Size = size,
        Position = position,
        AnchorPoint = anchorPoint,
        BackgroundColor3 = backgroundColor,
        BorderSizePixel = 0,
        ZIndex = zIndex
    }, {
        Corner = e("UICorner", {
            CornerRadius = UDim.new(0, 8)
        }),
        BadgeText = e("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            Text = text,
            TextColor3 = textColor,
            TextSize = textSize,
            TextWrapped = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansBold,
            ZIndex = zIndex + 1
        }, {
            TextStroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 2,
                Transparency = 0.3
            })
        })
    })
end

-- Create an icon badge (like assignment status)
function PetCardBadge.createIconBadge(props)
    local icon = props.icon or "★"
    local size = props.size or UDim2.new(0, 30, 0, 20)
    local position = props.position or UDim2.new(0, 4, 0, 4)
    local backgroundColor = props.backgroundColor or Color3.fromRGB(100, 255, 100)
    local textColor = props.textColor or Color3.fromRGB(255, 255, 255)
    local textSize = props.textSize or 12
    local zIndex = props.zIndex or 34
    
    return e("Frame", {
        Name = props.name or "IconBadge",
        Size = size,
        Position = position,
        BackgroundColor3 = backgroundColor,
        BorderSizePixel = 0,
        ZIndex = zIndex
    }, {
        Corner = e("UICorner", {
            CornerRadius = UDim.new(0, 10)
        }),
        IconText = e("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            Text = icon,
            TextColor3 = textColor,
            TextSize = textSize,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansBold,
            ZIndex = zIndex + 1
        })
    })
end

-- Create a quantity badge with number display
function PetCardBadge.createQuantityBadge(props)
    local quantity = props.quantity or 1
    local size = props.size or UDim2.new(0, 40, 0, 25)
    local position = props.position or UDim2.new(1, -5, 0, 5)
    local backgroundColor = props.backgroundColor or Color3.fromRGB(100, 150, 255)
    local textColor = props.textColor or Color3.fromRGB(255, 255, 255)
    local textSize = props.textSize or 14
    local anchorPoint = props.anchorPoint or Vector2.new(1, 0)
    local zIndex = props.zIndex or 34
    
    if quantity <= 1 then
        return nil
    end
    
    return e("Frame", {
        Name = props.name or "QuantityBadge",
        Size = size,
        Position = position,
        AnchorPoint = anchorPoint,
        BackgroundColor3 = backgroundColor,
        BorderSizePixel = 0,
        ZIndex = zIndex
    }, {
        Corner = e("UICorner", {
            CornerRadius = UDim.new(0, 12)
        }),
        Stroke = e("UIStroke", {
            Color = Color3.fromRGB(255, 255, 255),
            Thickness = 2,
            Transparency = 0.5
        }),
        QuantityText = e("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            Text = "x" .. tostring(quantity),
            TextColor3 = textColor,
            TextSize = textSize,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansBold,
            ZIndex = zIndex + 1
        }, {
            TextStroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 2,
                Transparency = 0.3
            })
        })
    })
end

return PetCardBadge