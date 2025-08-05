-- RightSideBar - Responsive right side button for playtime rewards
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.react)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local PlaytimeRewardsConfig = require(ReplicatedStorage.config.PlaytimeRewardsConfig)

-- Sound configuration
local HOVER_SOUND_ID = "rbxassetid://6895079853"

-- Pre-create hover sound for instant playback
local hoverSound = Instance.new("Sound")
hoverSound.SoundId = HOVER_SOUND_ID
hoverSound.Volume = 0.5
hoverSound.Parent = SoundService

-- Play hover sound instantly
local function playHoverSound()
    hoverSound:Play()
end

local function RightSideBar(props)
    -- Session-based playtime timer using shared start time
    local sessionStartTime = props.sharedSessionStartTime or tick()
    local currentSessionTime, setCurrentSessionTime = React.useState(0)
    
    -- Animation state for icon shake and size
    local iconRotation, setIconRotation = React.useState(-15) -- Base rotation
    local iconScale, setIconScale = React.useState(1) -- Base scale
    local lastShakeTime = React.useRef(0)
    
    -- Update session timer every second and handle icon shake animation
    React.useEffect(function()
        local updateTimer = function()
            local currentTime = tick()
            local sessionMinutes = (currentTime - sessionStartTime) / 60
            setCurrentSessionTime(sessionMinutes)
            
            -- Shake animation every 5 seconds
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
                        local sizeProgress = 1 - (shakeElapsed / 0.3) -- Return to normal size
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
    
    -- Calculate next claimable reward using shared claimed state
    local allRewards = PlaytimeRewardsConfig.getAllRewards()
    local nextReward = nil
    local canClaim = false
    local sharedClaimedRewards = props.sharedSessionClaimedRewards or {}
    
    -- First pass: check for any claimable rewards
    for _, reward in ipairs(allRewards) do
        local hasPlaytime = currentSessionTime >= reward.timeMinutes
        local alreadyClaimed = sharedClaimedRewards[reward.timeMinutes] or false
        
        if hasPlaytime and not alreadyClaimed then
            canClaim = true
            break -- Found a claimable reward, stop checking
        end
    end
    
    -- Second pass: if no claimable rewards, find next unclaimed reward
    if not canClaim then
        for _, reward in ipairs(allRewards) do
            local alreadyClaimed = sharedClaimedRewards[reward.timeMinutes] or false
            
            if not alreadyClaimed and (not nextReward or reward.timeMinutes < nextReward.timeMinutes) then
                nextReward = reward
            end
        end
    end
    
    -- Calculate status text
    local statusText = "Claim Gift!"
    local statusColor = Color3.fromRGB(85, 200, 85) -- Green
    
    if not canClaim and nextReward then
        local timeUntil = nextReward.timeMinutes - currentSessionTime
        statusText = "In " .. PlaytimeRewardsConfig.formatTime(timeUntil)
        statusColor = Color3.fromRGB(200, 120, 120) -- Red
    end
    
    -- Calculate text width for dynamic button sizing with bucketing to prevent flickering
    local textService = game:GetService("TextService")
    local textBounds = textService:GetTextSize(
        statusText,
        ScreenUtils.getTextSize(48),
        Enum.Font.Cartoon,
        Vector2.new(1000, 100)
    )
    
    -- Width bucketing to prevent constant flickering on small changes
    local function getBucketedWidth(width)
        local bucketSize = ScreenUtils.getProportionalSize(30) -- 30px buckets
        return math.ceil(width / bucketSize) * bucketSize
    end
    
    -- Responsive sizing calculations
    local textPadding = ScreenUtils.getProportionalSize(25) -- Balanced padding on each side
    local leftPadding = ScreenUtils.getProportionalSize(20) -- Slightly more left padding
    local rawButtonWidth = textBounds.X + textPadding * 2 + leftPadding
    local buttonWidth = getBucketedWidth(rawButtonWidth) -- Bucketed width to prevent flickering
    local buttonHeight = ScreenUtils.getProportionalSize(90)
    local iconSize = ScreenUtils.getProportionalSize(103) -- 25% bigger (82.5 * 1.25)
    local iconOffset = iconSize / 2 -- Half the icon width for half-in/half-out effect
    local screenPadding = ScreenUtils.getProportionalSize(10)
    local borderThickness = ScreenUtils.getProportionalSize(4)
    local cornerRadius = ScreenUtils.getProportionalSize(28)
    local innerCornerRadius = ScreenUtils.getProportionalSize(24)
    
    return React.createElement("Frame", {
        Name = "RightSideBar",
        Size = UDim2.new(0, buttonWidth, 0, buttonHeight),
        Position = UDim2.new(1, -buttonWidth - screenPadding, 0.5, -buttonHeight/2),
        BackgroundTransparency = 1,
        ZIndex = 50
    }, {
        -- Button with black outline frame first
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
                    if props.onPlaytimeRewardsClick then
                        props.onPlaytimeRewardsClick()
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
            
                -- Gift icon with bottom aligned to button bottom and tilted left (animated)
                GiftIcon = React.createElement("ImageLabel", {
                    Name = "GiftIcon",
                    Size = UDim2.new(0, iconSize * iconScale, 0, iconSize * iconScale), -- Animated size
                    Position = UDim2.new(0, -iconOffset, 1, -iconSize), -- Bottom aligned
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://129282541147867",
                    ImageColor3 = Color3.fromRGB(255, 165, 0), -- Keep orange color always (neutral)
                    ScaleType = Enum.ScaleType.Fit,
                    Rotation = iconRotation, -- Animated rotation with shake
                    ZIndex = 52
                }),
            
                -- Status text centered in button with padding
                StatusText = React.createElement("TextLabel", {
                    Name = "StatusText",
                    Size = UDim2.new(1, -textPadding * 2, 1, 0), -- Account for padding
                    Position = UDim2.new(0, textPadding + leftPadding, 0, 0), -- Add left padding
                    BackgroundTransparency = 1,
                    Text = statusText,
                    TextColor3 = Color3.fromRGB(255, 165, 0), -- Orange color
                    TextSize = ScreenUtils.getTextSize(48), -- 2x bigger text size
                    Font = Enum.Font.Cartoon, -- SakuraOne style font
                    TextXAlignment = Enum.TextXAlignment.Center, -- Center in available space
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextScaled = false, -- Don't scale to prevent multi-line
                    TextWrapped = false, -- Prevent text wrapping
                    TextStrokeTransparency = 0, -- Full outline
                    TextStrokeColor3 = Color3.fromRGB(50, 50, 50), -- Dark grey stroke (almost black)
                    ZIndex = 52
                }, {
                    -- Add UIStroke for thicker outline
                    TextStroke = React.createElement("UIStroke", {
                        Color = Color3.fromRGB(50, 50, 50), -- Dark grey color (almost black)
                        Thickness = ScreenUtils.getProportionalSize(3), -- Responsive thickness
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
                    })
                })
            }),
            
            -- Red notification badge when rewards are claimable
            canClaim and React.createElement("Frame", {
                Name = "NotificationBadge",
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(26), 0, ScreenUtils.getProportionalSize(26)), -- Bigger
                Position = UDim2.new(1, -ScreenUtils.getProportionalSize(20), 0, ScreenUtils.getProportionalSize(3)), -- More left, slightly higher
                BackgroundColor3 = Color3.fromRGB(200, 15, 15), -- Darker red
                BorderSizePixel = 0, -- Remove default border
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

return RightSideBar