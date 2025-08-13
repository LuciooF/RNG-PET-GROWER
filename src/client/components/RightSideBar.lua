-- RightSideBar - Unified right navigation with all buttons in proper order
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.react)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local DataSyncService = require(script.Parent.Parent.services.DataSyncService)
local PlaytimeRewardsConfig = require(ReplicatedStorage.config.PlaytimeRewardsConfig)
local DailyRewardsConfig = require(ReplicatedStorage.config.DailyRewardsConfig)
local FreeOpItemButton = require(script.Parent.FreeOpItemButton)

-- Sound configuration
local HOVER_SOUND_ID = "rbxassetid://6895079853"

-- Pre-create hover sound for instant playback
local hoverSound = Instance.new("Sound")
hoverSound.SoundId = HOVER_SOUND_ID
hoverSound.Volume = 0.5
hoverSound.Parent = SoundService

-- Play hover sound instantly (no creation overhead)
local function playHoverSound()
    hoverSound:Play()
end

-- Store active spin tweens to prevent overlapping animations
local activeSpinTweens = {}

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

local function RightSideBar(props)
    -- Subscribe to player data for potion count
    local playerData, setPlayerData = React.useState({
        Potions = {}
    })
    
    -- State for notification badges
    local claimableDailyCount, setClaimableDailyCount = React.useState(0)
    
    -- Session-based playtime timer using shared start time
    local sessionStartTime = props.sharedSessionStartTime or tick()
    local currentSessionTime, setCurrentSessionTime = React.useState(0)
    
    -- Animation state for playtime rewards icon shake
    local playtimeIconRotation, setPlaytimeIconRotation = React.useState(-15) -- Base rotation
    local playtimeIconScale, setPlaytimeIconScale = React.useState(1)
    local lastShakeTime = React.useRef(0)
    
    React.useEffect(function()
        -- Get initial data
        local initialData = DataSyncService:GetPlayerData()
        if initialData then
            setPlayerData(initialData)
        end
        
        local unsubscribe = DataSyncService:Subscribe(function(newState)
            if newState and newState.player then
                setPlayerData(newState.player)
            end
        end)
        
        return function()
            if unsubscribe and type(unsubscribe) == "function" then
                unsubscribe()
            end
        end
    end, {})
    
    -- Update session timer every second and handle icon shake animation
    React.useEffect(function()
        local lastUpdateTime = 0
        local updateTimer = function()
            local currentTime = tick()
            local sessionMinutes = (currentTime - sessionStartTime) / 60
            
            -- Only update state once per second to avoid infinite React loops
            if currentTime - lastUpdateTime >= 1 then
                lastUpdateTime = currentTime
                setCurrentSessionTime(sessionMinutes)
            end
            
            -- Shake animation every 5 seconds for playtime rewards
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
                        setPlaytimeIconScale(currentScale)
                        setPlaytimeIconRotation(-15) -- Keep base rotation during size change
                    elseif elapsed < 0.4 then 
                        -- Phase 2: Shake while returning to normal size (300ms)
                        local shakeElapsed = elapsed - 0.1
                        local sizeProgress = 1 - (shakeElapsed / 0.3)
                        local currentScale = 1 + (0.2 * sizeProgress)
                        setPlaytimeIconScale(currentScale)
                        
                        -- Shake animation
                        local shakeIntensity = 15 -- degrees of shake
                        local frequency = 20 -- shake speed
                        local shake = math.sin(shakeElapsed * frequency) * shakeIntensity * (1 - shakeElapsed/0.3)
                        setPlaytimeIconRotation(-15 + shake) -- Base -15° + shake offset
                    else
                        -- Phase 3: Return to base state
                        setPlaytimeIconScale(1) -- Normal size
                        setPlaytimeIconRotation(-15) -- Base rotation
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
    
    -- Effect to check daily rewards claimable count
    React.useEffect(function()
        local function updateDailyRewardsCount()
            local getDailyRewardsStatusRemote = ReplicatedStorage:FindFirstChild("GetDailyRewardsStatus")
            if getDailyRewardsStatusRemote then
                task.spawn(function()
                    local success, result = pcall(function()
                        return getDailyRewardsStatusRemote:InvokeServer()
                    end)
                    
                    if success and result and result.rewardStatuses then
                        local count = 0
                        for _, status in ipairs(result.rewardStatuses) do
                            if status.status == "available" then
                                count = count + 1
                            end
                        end
                        setClaimableDailyCount(count)
                    end
                end)
            end
        end
        
        -- Update immediately
        updateDailyRewardsCount()
        
        -- Update every 30 seconds to keep it fresh
        local timerConnection = task.spawn(function()
            while true do
                task.wait(30)
                updateDailyRewardsCount()
            end
        end)
        
        return function()
            if timerConnection then
                task.cancel(timerConnection)
            end
        end
    end, {})
    
    -- Calculate potion count
    local potionCount = 0
    for _, quantity in pairs(playerData.Potions or {}) do
        potionCount = potionCount + quantity
    end
    local potionCountText = NumberFormatter.format(potionCount)
    
    -- Calculate next claimable reward using the original logic from the working version
    local allRewards = PlaytimeRewardsConfig.getAllRewards()
    local nextReward = nil
    local canClaim = false
    local sharedClaimedRewards = props.sharedSessionClaimedRewards or {}
    
    -- First pass: count all claimable rewards
    local claimablePlaytimeCount = 0
    for _, reward in ipairs(allRewards) do
        local hasPlaytime = currentSessionTime >= reward.timeMinutes
        local alreadyClaimed = sharedClaimedRewards[reward.timeMinutes] or false
        
        if hasPlaytime and not alreadyClaimed then
            claimablePlaytimeCount = claimablePlaytimeCount + 1
            canClaim = true -- Keep this for existing logic compatibility
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
    
    -- Calculate status text using original logic
    local statusText = "Claim Gift!"
    
    if not canClaim and nextReward then
        local timeUntil = nextReward.timeMinutes - currentSessionTime
        statusText = "In " .. PlaytimeRewardsConfig.formatTime(timeUntil)
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
    local playtimeButtonWidth = getBucketedWidth(rawButtonWidth) -- Bucketed width to prevent flickering
    local playtimeButtonHeight = ScreenUtils.getProportionalSize(90) -- Original size
    local iconSize = ScreenUtils.getProportionalSize(103) -- Original size (82.5 * 1.25)
    local iconOffset = iconSize / 2 -- Half the icon width for half-in/half-out effect
    local borderThickness = ScreenUtils.getProportionalSize(4) -- Keep border thickness same
    local cornerRadius = ScreenUtils.getProportionalSize(28) -- Original size
    local innerCornerRadius = ScreenUtils.getProportionalSize(24) -- Original size
    
    -- Standard button setup for other buttons (10% smaller to match left sidebar)
    local screenSize = ScreenUtils.getScreenSize()
    local screenHeight = screenSize.Y
    local buttonPixelSize = screenHeight * 0.07 -- 7% of screen height for buttons
    local spacingPixelSize = screenHeight * 0.04 -- 4% of screen height for spacing
    local buttonSize = UDim2.new(0, buttonPixelSize, 0, buttonPixelSize)
    
    -- Create buttons array in the order we want them to appear
    local buttons = {}
    
    -- 1. Free OP Item Button
    buttons[1] = React.createElement(FreeOpItemButton, {
        Name = "A_FreeOpItemButton",
        Size = UDim2.new(0, math.max(buttonPixelSize, playtimeButtonWidth), 0, buttonPixelSize),
        buttonPixelSize = buttonPixelSize,
        sharedSessionStartTime = props.sharedSessionStartTime,
        sharedFreeOpLastClaimTime = props.sharedFreeOpLastClaimTime,
        sharedFreeOpClaimCount = props.sharedFreeOpClaimCount,
        onFreeOpItemClick = function()
            if props.onFreeOpItemClick then
                props.onFreeOpItemClick()
            end
        end
    })
    
    -- 2. Playtime Rewards Button (original styled design)
    buttons[2] = React.createElement("Frame", {
        Name = "B_PlaytimeRewardsButton",
        Size = UDim2.new(0, playtimeButtonWidth, 0, playtimeButtonHeight),
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
                    Size = UDim2.new(0, iconSize * playtimeIconScale, 0, iconSize * playtimeIconScale), -- Animated size
                    Position = UDim2.new(0, -iconOffset, 1, -iconSize), -- Bottom aligned
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://129282541147867",
                    ImageColor3 = Color3.fromRGB(255, 165, 0), -- Keep orange color always (neutral)
                    ScaleType = Enum.ScaleType.Fit,
                    Rotation = playtimeIconRotation, -- Animated rotation with shake
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
            
            -- Red notification badge when rewards are claimable (with count)
            claimablePlaytimeCount > 0 and React.createElement("Frame", {
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
                }),
                -- Count text
                BadgeText = React.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = tostring(claimablePlaytimeCount),
                    TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                    TextSize = ScreenUtils.getTextSize(18),
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    ZIndex = 55
                })
            }) or nil
        })
    })
    
    -- 3. Potion Button
    buttons[3] = React.createElement("Frame", {
        Name = "C_PotionButtonContainer",
        Size = buttonSize,
        BackgroundTransparency = 1,
        ZIndex = 50
    }, {
        PotionButton = React.createElement("ImageButton", {
            Name = "PotionButton",
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = "rbxassetid://104089702525726", -- Diamond potion icon
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 50,
            [React.Event.Activated] = function()
                if props.onPotionClick then
                    props.onPotionClick()
                end
            end,
            [React.Event.MouseEnter] = function(rbx)
                playHoverSound()
                spinButton(rbx)
            end
        }),
        
        -- Potion count badge
        PotionCountBadge = potionCount > 0 and React.createElement("Frame", {
            Name = "PotionCountBadge",
            Size = ScreenUtils.udim2(0, 36, 0, 24),
            Position = ScreenUtils.udim2(1, -18, 0, -4),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundColor3 = Color3.fromRGB(138, 43, 226), -- Purple for potions
            BorderSizePixel = 0,
            ZIndex = 52
        }, {
            UICorner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, 12)
            }),
            UIStroke = React.createElement("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 2,
                Transparency = 0
            }),
            CountText = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = potionCountText,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                TextSize = 16,
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 53
            })
        }) or nil
    })
    
    -- 4. Leaderboard Button
    buttons[4] = React.createElement("Frame", {
        Name = "D_LeaderboardButtonContainer",
        Size = buttonSize,
        BackgroundTransparency = 1,
        ZIndex = 50
    }, {
        LeaderboardButton = React.createElement("ImageButton", {
            Name = "LeaderboardButton",
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Image = IconAssets.getIcon("UI", "TROPHY"),
            ImageColor3 = Color3.fromRGB(255, 215, 0), -- Gold color
            ScaleType = Enum.ScaleType.Fit,
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            ZIndex = 50,
            [React.Event.Activated] = function()
                if props.onLeaderboardClick then
                    props.onLeaderboardClick()
                end
            end,
            [React.Event.MouseEnter] = function(rbx)
                playHoverSound()
                spinButton(rbx)
            end
        })
    })
    
    -- 5. Daily Rewards Button
    buttons[5] = React.createElement("Frame", {
        Name = "E_DailyRewardsButtonContainer",
        Size = buttonSize,
        BackgroundTransparency = 1,
        ZIndex = 50
    }, {
        DailyRewardsButton = React.createElement("ImageButton", {
            Name = "DailyRewardsButton",
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Image = "rbxassetid://78432604638666", -- Calendar icon
            ImageColor3 = Color3.fromRGB(255, 255, 255), -- No tint for daily rewards button
            ScaleType = Enum.ScaleType.Fit,
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            ZIndex = 50,
            [React.Event.Activated] = function()
                if props.onDailyRewardsClick then
                    props.onDailyRewardsClick()
                end
            end,
            [React.Event.MouseEnter] = function(rbx)
                playHoverSound()
                spinButton(rbx)
            end
        }),
        
        -- Notification badge for claimable daily rewards
        claimableDailyCount > 0 and React.createElement("Frame", {
            Name = "DailyNotificationBadge",
            Size = UDim2.new(0, ScreenUtils.getProportionalSize(24), 0, ScreenUtils.getProportionalSize(24)),
            Position = UDim2.new(1, -ScreenUtils.getProportionalSize(8), 0, ScreenUtils.getProportionalSize(8)),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 50, 50), -- Red notification badge
            BorderSizePixel = 0,
            ZIndex = 53
        }, {
            BadgeCorner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0.5, 0) -- Circular badge
            }),
            BadgeText = React.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = tostring(claimableDailyCount),
                TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                TextSize = ScreenUtils.getTextSize(18),
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 54
            })
        }) or nil
    })
    
    -- Convert array to React children object
    local children = {
        UIListLayout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, spacingPixelSize * 0.6), -- Reduce spacing between rows
            SortOrder = Enum.SortOrder.Name
        })
    }
    
    -- Row 1: Free OP Item Button (centered)
    children["Row1_FreeOpItem"] = React.createElement("Frame", {
        Size = UDim2.new(0, maxRowWidth, 0, buttonPixelSize), -- Use full row width
        BackgroundTransparency = 1,
        ZIndex = 50
    }, {
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center, -- Center the button
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.Name
        }),
        FreeOpItemButton = buttons[1]
    })
    
    -- Row 2: Potions Button | Leaderboard Button (side by side)
    children["Row2_PotionsAndLeaderboard"] = React.createElement("Frame", {
        Size = UDim2.new(0, buttonPixelSize * 2 + spacingPixelSize * 0.5, 0, buttonPixelSize),
        BackgroundTransparency = 1,
        ZIndex = 50
    }, {
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, spacingPixelSize * 0.5),
            SortOrder = Enum.SortOrder.Name
        }),
        PotionButton = buttons[3],  -- Potions
        LeaderboardButton = buttons[4]  -- Leaderboard
    })
    
    -- Row 3: Playtime Rewards Button (centered)
    children["Row3_PlaytimeRewards"] = React.createElement("Frame", {
        Size = UDim2.new(0, maxRowWidth, 0, playtimeButtonHeight), -- Use full row width
        BackgroundTransparency = 1,
        ZIndex = 50
    }, {
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center, -- Center the button
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.Name
        }),
        PlaytimeRewardsButton = buttons[2]
    })
    
    -- Row4: Daily Rewards Button (centered)
    children["Row4_DailyRewards"] = React.createElement("Frame", {
        Size = UDim2.new(0, buttonPixelSize, 0, buttonPixelSize),
        BackgroundTransparency = 1,
        ZIndex = 50
    }, {
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.Name
        }),
        DailyRewardsButton = buttons[5]
    })
    
    -- Calculate the maximum button width including FreeOpItem button
    local textService = game:GetService("TextService")
    local freeOpItemText = "Free OP Item!"
    local freeOpItemTextBounds = textService:GetTextSize(
        freeOpItemText,
        ScreenUtils.getTextSize(36),
        Enum.Font.Cartoon,
        Vector2.new(1000, 100)
    )
    
    local function getBucketedWidth(width)
        local bucketSize = ScreenUtils.getProportionalSize(30)
        return math.ceil(width / bucketSize) * bucketSize
    end
    
    local textPadding = ScreenUtils.getProportionalSize(20)
    local leftPadding = ScreenUtils.getProportionalSize(15)
    local rawFreeOpItemWidth = freeOpItemTextBounds.X + textPadding * 2 + leftPadding
    local freeOpItemButtonWidth = getBucketedWidth(rawFreeOpItemWidth)
    
    -- Find the maximum width among all button configurations
    local maxSingleButtonWidth = math.max(buttonPixelSize, playtimeButtonWidth, freeOpItemButtonWidth)
    local doubleButtonWidth = buttonPixelSize * 2 + spacingPixelSize * 0.5 -- Width of row with 2 buttons
    local maxRowWidth = math.max(maxSingleButtonWidth, doubleButtonWidth)
    local totalSidebarWidth = maxRowWidth + 200 -- Even higher padding for right side
    
    return React.createElement("Frame", {
        Name = "RightSideBar",
        Size = ScreenUtils.udim2(0, totalSidebarWidth, 1, 0),
        Position = ScreenUtils.udim2(1, -totalSidebarWidth, 0, 0), -- Position from right edge
        BackgroundTransparency = 1,
        ZIndex = 50
    }, {
        ButtonContainer = React.createElement("Frame", {
            Name = "ButtonContainer",
            Size = UDim2.new(1, -200, 0, 0), -- 100px padding each side
            AutomaticSize = Enum.AutomaticSize.Y,
            Position = UDim2.new(1, -100, 0.5, 0), -- 100px padding from right edge (mobile safe area)
            AnchorPoint = Vector2.new(1, 0.5), -- Anchor from right
            BackgroundTransparency = 1,
            ZIndex = 50
        }, children)
    })
end

return RightSideBar