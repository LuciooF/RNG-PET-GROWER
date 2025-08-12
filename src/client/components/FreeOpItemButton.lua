-- FreeOpItemButton - Styled button for Free OP Item rewards (similar to PlaytimeRewards)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local React = require(ReplicatedStorage.Packages.react)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)
local FreeOpItemConfig = require(ReplicatedStorage.config.FreeOpItemConfig)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)

-- Sound configuration
local HOVER_SOUND_ID = "rbxassetid://6895079853"

-- Pre-create hover sound for instant playback
local hoverSound = Instance.new("Sound")
hoverSound.SoundId = HOVER_SOUND_ID
hoverSound.Volume = 0.5
hoverSound.Parent = SoundService

local function playHoverSound()
    hoverSound:Play()
end

local function FreeOpItemButton(props)
    local config = FreeOpItemConfig.GetConfig()
    local requiredTimeSeconds = config.RequiredPlaytimeMinutes * 60
    
    -- Client-side session tracking (like PlaytimeRewards)
    local sessionStartTime = props.sharedSessionStartTime or tick()
    local currentSessionTime, setCurrentSessionTime = React.useState(0)
    
    -- Use shared claim state from App.lua
    local lastClaimTime = props.sharedFreeOpLastClaimTime or 0
    local claimCount = props.sharedFreeOpClaimCount or 0
    
    -- Animation state for shake effect
    local iconRotation, setIconRotation = React.useState(-15) -- Base rotation
    local iconScale, setIconScale = React.useState(1)
    local lastShakeTime = React.useRef(0)
    
    -- Animation state for shine effect only
    local shineOffset, setShineOffset = React.useState(-1.5) -- Start shine off-screen
    
    -- Animation state for rainbow gradient rotation
    local rainbowRotation, setRainbowRotation = React.useState(0)
    
    -- Client-side session timer and animations
    React.useEffect(function()
        local lastUpdateTime = 0
        local updateTimer = function()
            local currentTime = tick()
            local sessionMinutes = (currentTime - sessionStartTime) / 60
            
            -- Update session time once per second
            if currentTime - lastUpdateTime >= 1 then
                lastUpdateTime = currentTime
                setCurrentSessionTime(sessionMinutes)
            end
            
            -- Continuous shine animation (moves across button every 3 seconds)
            local shineSpeed = 2 / 3 -- Complete cycle in 3 seconds (from -1.5 to 1.5)
            local newShineOffset = (shineOffset + shineSpeed * (1/60)) -- 60 FPS assumption
            if newShineOffset > 1.5 then
                setShineOffset(-1.5) -- Reset to start
            else
                setShineOffset(newShineOffset)
            end
            
            -- Animate rainbow gradient rotation (60 degrees per second like ComingSoonGUI)
            local rainbowSpeed = 60 -- degrees per second
            setRainbowRotation(function(current)
                return (current + rainbowSpeed * (1/60)) % 360
            end)
            
            -- Shake animation every 5 seconds (same as PlaytimeRewards)
            if currentTime - lastShakeTime.current >= 5 then
                lastShakeTime.current = currentTime
                
                -- Create combined size + shake animation
                local animationStartTime = currentTime
                local animationConnection
                animationConnection = RunService.Heartbeat:Connect(function()
                    local elapsed = tick() - animationStartTime
                    
                    if elapsed < 0.1 then 
                        -- Phase 1: Size increase (100ms)
                        local sizeProgress = elapsed / 0.1
                        local currentScale = 1 + (0.2 * sizeProgress) -- Grow to 1.2x size
                        setIconScale(currentScale)
                        setIconRotation(-15) -- Keep base rotation during size change
                    elseif elapsed < 0.4 then 
                        -- Phase 2: Shake while returning to normal size (300ms)
                        local shakeElapsed = elapsed - 0.1
                        local sizeProgress = 1 - (shakeElapsed / 0.3)
                        local currentScale = 1 + (0.2 * sizeProgress)
                        setIconScale(currentScale)
                        
                        -- Shake animation
                        local shakeIntensity = 15 -- degrees of shake
                        local frequency = 20 -- shake speed
                        local shake = math.sin(shakeElapsed * frequency) * shakeIntensity * (1 - shakeElapsed/0.3)
                        setIconRotation(-15 + shake) -- Base -15° + shake offset
                    else
                        -- Phase 3: Return to base state
                        setIconScale(1) -- Normal size
                        setIconRotation(-15) -- Base rotation
                        animationConnection:Disconnect()
                    end
                end)
            end
        end
        
        updateTimer()
        local heartbeatConnection = RunService.Heartbeat:Connect(updateTimer)
        
        return function()
            if heartbeatConnection then
                heartbeatConnection:Disconnect()
            end
        end
    end, {})
    
    local config = FreeOpItemConfig.GetConfig()
    
    -- Calculate dynamic button sizing (similar to PlaytimeRewards)
    local textService = game:GetService("TextService")
    local buttonText = "Free OP Item!"
    local textBounds = textService:GetTextSize(
        buttonText,
        ScreenUtils.getTextSize(36), -- Slightly smaller than PlaytimeRewards
        Enum.Font.Cartoon,
        Vector2.new(1000, 100)
    )
    
    -- Width bucketing to prevent flickering
    local function getBucketedWidth(width)
        local bucketSize = ScreenUtils.getProportionalSize(30) -- 30px buckets
        return math.ceil(width / bucketSize) * bucketSize
    end
    
    -- Responsive sizing calculations (similar to PlaytimeRewards but smaller)
    local textPadding = ScreenUtils.getProportionalSize(20) -- Slightly less padding
    local leftPadding = ScreenUtils.getProportionalSize(15) -- Less left padding
    local rawButtonWidth = textBounds.X + textPadding * 2 + leftPadding
    local buttonWidth = getBucketedWidth(rawButtonWidth)
    local buttonHeight = ScreenUtils.getProportionalSize(70) -- Smaller than PlaytimeRewards (90)
    local iconSize = ScreenUtils.getProportionalSize(103) -- Same size as PlaytimeRewards (25% bigger)
    local iconOffset = iconSize / 2
    local borderThickness = ScreenUtils.getProportionalSize(3)
    local cornerRadius = ScreenUtils.getProportionalSize(24)
    local innerCornerRadius = ScreenUtils.getProportionalSize(20)
    
    -- Calculate progress on client side with cooldown support
    local timeSinceLastClaim = (tick() - lastClaimTime) / 60 -- Convert to minutes
    local effectivePlaytime = lastClaimTime > 0 and timeSinceLastClaim or currentSessionTime
    local progress = math.min(effectivePlaytime * 60 / requiredTimeSeconds, 1)
    local timeRemaining = math.max(0, requiredTimeSeconds - (effectivePlaytime * 60))
    local canClaim = progress >= 1
    
    -- Determine button state for notification badge
    local canShowBadge = canClaim
    
    
    return React.createElement("Frame", {
        Name = props.Name or "FreeOpItemButton",
        Size = UDim2.new(0, buttonWidth, 0, buttonHeight),
        BackgroundTransparency = 1,
        ZIndex = 50
    }, {
        -- Button with black outline frame first (same as PlaytimeRewards)
        OutlineFrame = React.createElement("Frame", {
            Name = "OutlineFrame",
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0), -- Black background for outline
            BorderSizePixel = 0,
            ZIndex = 50
        }, {
            -- Rounded corners for outline
            OutlineCorner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0, cornerRadius)
            }),
            
            -- Inner white button (smaller to create outline effect)
            InnerButton = React.createElement("TextButton", {
                Name = "InnerButton",
                Size = UDim2.new(1, -borderThickness*2, 1, -borderThickness*2),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Text = "",
                ZIndex = 51,
                [React.Event.Activated] = function()
                    if props.onFreeOpItemClick then
                        props.onFreeOpItemClick()
                    end
                end,
                [React.Event.MouseEnter] = function()
                    playHoverSound()
                end
            }, {
                -- Rounded corners for inner button
                InnerCorner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(0, innerCornerRadius)
                }),
            
                -- Gradient background
                Gradient = React.createElement("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(245, 245, 245)), -- Light grey
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))  -- White
                    }),
                    Rotation = 90
                }),
                
                -- Progress bar fill (transparent green that fills from left to right)
                ProgressFill = React.createElement("Frame", {
                    Name = "ProgressFill",
                    Size = UDim2.new(progress, 0, 1, 0), -- Width based on progress
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundColor3 = canClaim and Color3.fromRGB(50, 205, 50) or Color3.fromRGB(100, 255, 100), -- Bright green when ready, light green while progressing
                    BackgroundTransparency = canClaim and 0.3 or 0.5, -- More opaque when ready
                    BorderSizePixel = 0,
                    ZIndex = 51, -- Same level as button but behind text
                    ClipsDescendants = true
                }, {
                    -- Rounded corners to match inner button
                    FillCorner = React.createElement("UICorner", {
                        CornerRadius = UDim.new(0, innerCornerRadius)
                    }),
                    -- Add a subtle gradient for depth
                    FillGradient = React.createElement("UIGradient", {
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), -- White tint at top
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 255, 200))  -- Slightly darker green at bottom
                        }),
                        Rotation = 90,
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0.2),  -- Slightly transparent at top
                            NumberSequenceKeypoint.new(1, 0)     -- Fully visible at bottom
                        })
                    })
                }),
            
                -- Magnet icon positioned like PlaytimeRewards (bottom left, bigger, animated)
                MagnetIcon = React.createElement("ImageLabel", {
                    Name = "MagnetIcon",
                    Size = UDim2.new(0, iconSize * iconScale, 0, iconSize * iconScale), -- Animated size
                    Position = UDim2.new(0, -iconOffset, 1, -iconSize), -- Bottom aligned, half sticking out left
                    BackgroundTransparency = 1,
                    Image = config.MagnetIconId,
                    -- No ImageColor3 - keep original icon colors
                    ScaleType = Enum.ScaleType.Fit,
                    Rotation = iconRotation, -- Animated rotation with shake
                    ZIndex = 52
                }),
            
                -- Enhanced shine effect overlay (animated across button)
                ShineEffect = React.createElement("Frame", {
                    Name = "ShineEffect",
                    Size = UDim2.new(0.4, 0, 1, 0), -- Slightly wider shine band
                    Position = UDim2.new(shineOffset, 0, 0, 0), -- Animated position
                    BackgroundTransparency = 1, -- Fully transparent, gradient handles visibility
                    BorderSizePixel = 0,
                    ZIndex = 55, -- Above text and everything else
                    ClipsDescendants = false -- Allow shine to extend beyond bounds
                }, {
                    ShineCorner = React.createElement("UICorner", {
                        CornerRadius = UDim.new(0, innerCornerRadius)
                    }),
                    ShineGradient = React.createElement("UIGradient", {
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),   -- White
                            ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 255, 255)), -- White
                            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)), -- White center
                            ColorSequenceKeypoint.new(0.7, Color3.fromRGB(255, 255, 255)), -- White
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))    -- White
                        }),
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 1),      -- Invisible left edge
                            NumberSequenceKeypoint.new(0.2, 0.8),  -- Fade in
                            NumberSequenceKeypoint.new(0.4, 0.2),  -- Bright
                            NumberSequenceKeypoint.new(0.5, 0.1),  -- Brightest center
                            NumberSequenceKeypoint.new(0.6, 0.2),  -- Bright
                            NumberSequenceKeypoint.new(0.8, 0.8),  -- Fade out
                            NumberSequenceKeypoint.new(1, 1)       -- Invisible right edge
                        }),
                        Rotation = 15 -- Slight angle for more dynamic shine
                    })
                }),
                
                -- Container for text parts (Free + OP + Item!)
                TextContainer = React.createElement("Frame", {
                    Name = "TextContainer",
                    Size = UDim2.new(1, -textPadding * 2, 1, 0),
                    Position = UDim2.new(0, textPadding + leftPadding, 0, 0),
                    BackgroundTransparency = 1,
                    ZIndex = 52
                }, {
                    -- Layout to arrange text parts horizontally
                    Layout = React.createElement("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = UDim.new(0, ScreenUtils.getProportionalSize(4)), -- Small gap between words
                        SortOrder = Enum.SortOrder.LayoutOrder
                    }),
                    
                    -- "Free " text (normal white)
                    FreeText = React.createElement("TextLabel", {
                        Name = "FreeText",
                        Size = UDim2.new(0, 0, 1, 0),
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundTransparency = 1,
                        Text = "Free ",
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = ScreenUtils.getTextSize(36),
                        Font = Enum.Font.Cartoon,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        TextStrokeTransparency = 0,
                        TextStrokeColor3 = Color3.fromRGB(50, 50, 50),
                        ZIndex = 53,
                        LayoutOrder = 1
                    }, {
                        TextStroke = React.createElement("UIStroke", {
                            Color = Color3.fromRGB(50, 50, 50),
                            Thickness = ScreenUtils.getProportionalSize(2),
                            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
                        })
                    }),
                    
                    -- "OP" text (rainbow gradient)
                    OPText = React.createElement("TextLabel", {
                        Name = "OPText",
                        Size = UDim2.new(0, 0, 1, 0),
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundTransparency = 1,
                        Text = "OP",
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = ScreenUtils.getTextSize(36),
                        Font = Enum.Font.Cartoon,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        TextStrokeTransparency = 0,
                        TextStrokeColor3 = Color3.fromRGB(50, 50, 50),
                        ZIndex = 53,
                        LayoutOrder = 2
                    }, {
                        -- Rainbow gradient for OP text (animated)
                        RainbowGradient = React.createElement("UIGradient", {
                            Color = ColorSequence.new({
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),    -- Red
                                ColorSequenceKeypoint.new(0.14, Color3.fromRGB(255, 127, 0)),  -- Orange
                                ColorSequenceKeypoint.new(0.28, Color3.fromRGB(255, 255, 0)),  -- Yellow
                                ColorSequenceKeypoint.new(0.42, Color3.fromRGB(0, 255, 0)),    -- Green
                                ColorSequenceKeypoint.new(0.57, Color3.fromRGB(0, 0, 255)),    -- Blue
                                ColorSequenceKeypoint.new(0.71, Color3.fromRGB(75, 0, 130)),   -- Indigo
                                ColorSequenceKeypoint.new(0.85, Color3.fromRGB(148, 0, 211)),  -- Violet
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))     -- Back to Red
                            }),
                            Rotation = rainbowRotation -- Animated rotation
                        }),
                        TextStroke = React.createElement("UIStroke", {
                            Color = Color3.fromRGB(50, 50, 50),
                            Thickness = ScreenUtils.getProportionalSize(2),
                            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
                        })
                    }),
                    
                    -- " Item!" text (normal white)
                    ItemText = React.createElement("TextLabel", {
                        Name = "ItemText",
                        Size = UDim2.new(0, 0, 1, 0),
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundTransparency = 1,
                        Text = " Item!",
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = ScreenUtils.getTextSize(36),
                        Font = Enum.Font.Cartoon,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        TextStrokeTransparency = 0,
                        TextStrokeColor3 = Color3.fromRGB(50, 50, 50),
                        ZIndex = 53,
                        LayoutOrder = 3
                    }, {
                        TextStroke = React.createElement("UIStroke", {
                            Color = Color3.fromRGB(50, 50, 50),
                            Thickness = ScreenUtils.getProportionalSize(2),
                            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
                        })
                    })
                })
            }),
            
            -- Red notification badge when rewards are claimable
            canShowBadge and React.createElement("Frame", {
                Name = "NotificationBadge",
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(22), 0, ScreenUtils.getProportionalSize(22)), -- Smaller badge
                Position = UDim2.new(1, -ScreenUtils.getProportionalSize(15), 0, ScreenUtils.getProportionalSize(2)), -- Top right corner
                BackgroundColor3 = Color3.fromRGB(200, 15, 15), -- Darker red
                BorderSizePixel = 0,
                ZIndex = 54 -- Above everything else
            }, {
                -- Circular badge
                BadgeCorner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(0.5, 0) -- Perfect circle
                }),
                -- Black outline using UIStroke
                BadgeStroke = React.createElement("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0), -- Black outline
                    Thickness = ScreenUtils.getProportionalSize(2)
                })
            }) or nil
        })
    })
end

return FreeOpItemButton