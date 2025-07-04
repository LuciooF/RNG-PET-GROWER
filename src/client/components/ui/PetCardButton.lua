-- Pet Card Button Component
-- Reusable action button component for pet cards
-- Extracted from PetCardComponent.lua for better modularity

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.react)
local e = React.createElement

local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)

local PetCardButton = {}

-- Create an assignment/action button for pet cards
function PetCardButton.createAssignButton(props)
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local isAssigned = props.isAssigned or false
    local assignedCount = props.assignedCount or 0
    local maxAssigned = props.maxAssigned or 3
    local onAction = props.onAction or function() end
    local size = props.size or UDim2.new(0.4, 0, 0.08, 0)
    local position = props.position or UDim2.new(0.5, 0, 0.86, 0)
    local anchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5)
    local zIndex = props.zIndex or 34
    
    -- Determine button state and appearance
    local buttonText, backgroundColor, isActive
    
    if isAssigned then
        buttonText = "UNASSIGN"
        backgroundColor = Color3.fromRGB(200, 80, 80) -- Red for unassign
        isActive = true
    elseif assignedCount >= maxAssigned then
        buttonText = "FULL"
        backgroundColor = Color3.fromRGB(120, 120, 120) -- Gray for full
        isActive = false
    else
        buttonText = "ASSIGN"
        backgroundColor = Color3.fromRGB(80, 200, 80) -- Green for assign
        isActive = true
    end
    
    return e("TextButton", {
        Name = props.name or "AssignButton",
        Size = size,
        Position = position,
        AnchorPoint = anchorPoint,
        Text = buttonText,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = ScreenUtils.getProportionalTextSize(screenSize, 12),
        BackgroundColor3 = backgroundColor,
        BorderSizePixel = 0,
        Font = Enum.Font.SourceSansBold,
        ZIndex = zIndex,
        Active = isActive,
        [React.Event.Activated] = isActive and onAction or nil
    }, {
        Corner = e("UICorner", {
            CornerRadius = UDim.new(0, 8)
        }),
        TextStroke = e("UIStroke", {
            Color = Color3.fromRGB(0, 0, 0),
            Thickness = 2,
            Transparency = 0.3
        })
    })
end

-- Create a generic action button
function PetCardButton.createActionButton(props)
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local text = props.text or "ACTION"
    local backgroundColor = props.backgroundColor or Color3.fromRGB(80, 120, 200)
    local textColor = props.textColor or Color3.fromRGB(255, 255, 255)
    local onAction = props.onAction or function() end
    local size = props.size or UDim2.new(0.4, 0, 0.08, 0)
    local position = props.position or UDim2.new(0.5, 0, 0.86, 0)
    local anchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5)
    local zIndex = props.zIndex or 34
    local active = props.active ~= false -- Default to true unless explicitly false
    
    return e("TextButton", {
        Name = props.name or "ActionButton",
        Size = size,
        Position = position,
        AnchorPoint = anchorPoint,
        Text = text,
        TextColor3 = textColor,
        TextSize = ScreenUtils.getProportionalTextSize(screenSize, 12),
        BackgroundColor3 = backgroundColor,
        BorderSizePixel = 0,
        Font = Enum.Font.SourceSansBold,
        ZIndex = zIndex,
        Active = active,
        [React.Event.Activated] = active and onAction or nil
    }, {
        Corner = e("UICorner", {
            CornerRadius = UDim.new(0, 8)
        }),
        TextStroke = e("UIStroke", {
            Color = Color3.fromRGB(0, 0, 0),
            Thickness = 2,
            Transparency = 0.3
        })
    })
end

return PetCardButton