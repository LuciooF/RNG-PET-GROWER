-- Toast Notification Component
-- Shows temporary error/success messages in the center of the screen

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local React = require(ReplicatedStorage.Packages.react)
local e = React.createElement

local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)

local function ToastNotification(props)
    local message = props.message or ""
    local visible = props.visible or false
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local duration = props.duration or 3 -- seconds
    local onComplete = props.onComplete or function() end
    
    -- State for animation
    local opacity, setOpacity = React.useState(0)
    local scale, setScale = React.useState(0.8)
    
    -- Responsive sizing
    local textSize = ScreenUtils.getProportionalTextSize(screenSize, 24)
    local padding = ScreenUtils.getProportionalSize(screenSize, 20)
    
    -- Animation effect
    React.useEffect(function()
        if visible then
            -- Fade in
            setOpacity(1)
            setScale(1)
            
            -- Set timer to fade out
            local fadeOutTimer = task.delay(duration - 0.5, function()
                setOpacity(0)
                setScale(0.8)
            end)
            
            -- Complete callback after full duration
            local completeTimer = task.delay(duration, function()
                onComplete()
            end)
            
            return function()
                task.cancel(fadeOutTimer)
                task.cancel(completeTimer)
            end
        end
    end, {visible})
    
    if not visible then
        return nil
    end
    
    return e("Frame", {
        Name = "ToastNotification",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = 100,
    }, {
        Container = e("Frame", {
            Name = "ToastContainer",
            Size = UDim2.new(0.8, 0, 0, textSize * 3),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            ZIndex = 101,
        }, {
            -- Main text with red color and black outline
            ErrorText = e("TextLabel", {
                Name = "ErrorText",
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = message,
                TextColor3 = Color3.fromRGB(255, 60, 60), -- Red color
                TextScaled = false,
                TextSize = textSize,
                Font = Enum.Font.SourceSansBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextWrapped = true,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0), -- Black outline
                TextStrokeTransparency = 0,
                TextTransparency = 1 - opacity,
                ZIndex = 102,
            }),
            
            -- Scale modifier for animation
            UIScale = e("UIScale", {
                Scale = scale
            })
        })
    })
end

return ToastNotification