-- TooltipUtils - Utility for creating hover tooltips
local TooltipUtils = {}

local React = require(game.ReplicatedStorage.Packages.react)
local ScreenUtils = require(script.Parent.ScreenUtils)
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

-- Store active spin tweens to prevent overlapping animations
local activeSpinTweens = {}

-- Sound configuration
local HOVER_SOUND_ID = "rbxassetid://6895079853"

-- Pre-create hover sound for instant playback
local hoverSound = Instance.new("Sound")
hoverSound.SoundId = HOVER_SOUND_ID
hoverSound.Volume = 0.5
hoverSound.Parent = SoundService

-- Play hover sound instantly (no creation overhead)
local function playHoverSound()
    -- Just play the pre-created sound
    hoverSound:Play()
end

-- Create a 360-degree spin animation for buttons
local function spinButton(button)
    if not button then return end
    
    -- Cancel any existing spin animation for this button
    if activeSpinTweens[button] then
        activeSpinTweens[button]:Cancel()
        activeSpinTweens[button] = nil
    end
    
    -- Reset rotation to 0 to prevent accumulation
    button.Rotation = 0
    
    -- Create tween info for a quick 360-degree spin
    local tweenInfo = TweenInfo.new(
        0.5, -- Duration: 0.5 seconds
        Enum.EasingStyle.Back,
        Enum.EasingDirection.Out,
        0, -- Repeat count
        false, -- Reverse
        0 -- Delay
    )
    
    -- Create the rotation tween (360 degrees = full rotation)
    local spinTween = TweenService:Create(button, tweenInfo, {
        Rotation = 360 -- Always go to exactly 360 degrees
    })
    
    -- Store the tween reference
    activeSpinTweens[button] = spinTween
    
    -- Clean up reference when animation completes
    spinTween.Completed:Connect(function()
        -- Reset to 0 degrees after completing 360
        button.Rotation = 0
        activeSpinTweens[button] = nil
    end)
    
    -- Play the animation
    spinTween:Play()
end

-- Create a tooltip that appears on hover
function TooltipUtils.createTooltip(text, targetButton)
    local showTooltip, setShowTooltip = React.useState(false)
    
    return React.createElement("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = targetButton.ZIndex or 1
    }, {
        -- The target button/element
        Target = targetButton,
        
        -- Tooltip that appears on hover
        Tooltip = showTooltip and React.createElement("Frame", {
            Size = ScreenUtils.udim2(0, string.len(text) * 8 + 20, 0, 30), -- Dynamic width based on text length
            Position = ScreenUtils.udim2(1, 10, 0.5, -15), -- To the right of the button
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Color3.fromRGB(20, 20, 20),
            BorderSizePixel = 1,
            BorderColor3 = Color3.fromRGB(255, 255, 255),
            ZIndex = 1000, -- Very high Z-index to appear above everything
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, 6)
            }),
            
            Text = React.createElement("TextLabel", {
                Size = UDim2.new(1, -10, 1, 0),
                Position = UDim2.new(0, 5, 0, 0),
                BackgroundTransparency = 1,
                Text = text,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = ScreenUtils.TEXT_SIZES.SMALL(),
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 1001
            })
        }) or nil
    })
end

-- Create a hover-enabled button with tooltip and spin animation
function TooltipUtils.createHoverButton(buttonProps, tooltipText)
    local showTooltip, setShowTooltip = React.useState(false)
    
    -- Merge hover events with existing events
    local enhancedProps = {}
    for key, value in pairs(buttonProps) do
        enhancedProps[key] = value
    end
    
    -- Add hover detection with spin animation and sound
    enhancedProps[React.Event.MouseEnter] = function(rbx)
        setShowTooltip(true)
        spinButton(rbx) -- Trigger 360-degree spin animation
        playHoverSound() -- Play hover click sound
        if buttonProps[React.Event.MouseEnter] then
            buttonProps[React.Event.MouseEnter](rbx)
        end
    end
    
    enhancedProps[React.Event.MouseLeave] = function(rbx)
        setShowTooltip(false)
        if buttonProps[React.Event.MouseLeave] then
            buttonProps[React.Event.MouseLeave](rbx)
        end
    end
    
    return React.createElement("Frame", {
        Size = buttonProps.Size or UDim2.new(0, 100, 0, 100),
        Position = buttonProps.Position or UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = buttonProps.ZIndex or 1
    }, {
        -- The actual button
        Button = React.createElement("ImageButton", enhancedProps),
        
        -- Tooltip that appears on hover (no background, white text with black outline)
        Tooltip = showTooltip and React.createElement("TextLabel", {
            Size = ScreenUtils.udim2(0, math.max(120, string.len(tooltipText) * 8 + 20), 0, 30), -- Dynamic width with minimum
            Position = ScreenUtils.udim2(1, 10, 0.5, -15), -- To the right of the button
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1, -- No background
            Text = tooltipText,
            TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
            TextStrokeTransparency = 0, -- Black outline
            TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
            TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 1000, -- Very high Z-index to appear above everything
        }) or nil
    })
end

return TooltipUtils