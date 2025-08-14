-- DailyRewardsPanel - UI panel showing daily login rewards in card grid layout
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local React = require(ReplicatedStorage.Packages.react)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local DailyRewardsConfig = require(ReplicatedStorage.config.DailyRewardsConfig)
local DataSyncService = require(script.Parent.Parent.services.DataSyncService)
local ViewportModelUtils = require(ReplicatedStorage.utils.ViewportModelUtils)
local RewardsService = require(script.Parent.Parent.services.RewardsService)
local AnimationService = require(script.Parent.Parent.services.AnimationService)

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

local function DailyRewardsPanel(props)
    -- Animation state for breathing effect and shake animations
    local animationOffset, setAnimationOffset = React.useState(0)
    local rewardShakeScale, setRewardShakeScale = React.useState(1)
    local rewardShakeRotation, setRewardShakeRotation = React.useState(0)
    
    -- Daily rewards status state
    local dailyStatus, setDailyStatus = React.useState(nil)
    local isLoading, setIsLoading = React.useState(true)
    local timeUntilNextReward, setTimeUntilNextReward = React.useState("")
    
    -- Animation references for cleanup
    local activeAnimations = React.useRef({})
    
    -- Setup animations using AnimationService
    React.useEffect(function()
        -- Create bouncing animation for warning text using callback method
        local bounceAnimation = AnimationService:CreateReactBounceAnimation({
            duration = 0.8,
            upOffset = 10, 
            downOffset = 10,
            pauseBetween = 0.5
        }, {
            onPositionChange = setAnimationOffset
        })
        activeAnimations.current.warningBounce = bounceAnimation
        
        -- Setup shake animation for claimable rewards using callback method
        local shakeAnimation = AnimationService:CreateReactShakeAnimation({
            interval = 1.5, -- Every 1.5 seconds
            growPhase = 0.1, -- 100ms grow phase
            shakePhase = 0.3, -- 300ms shake phase
            maxScale = 1.15, -- 1.15x scale
            shakeIntensity = 8 -- 8 pixels of shake converted to rotation
        }, {
            onScaleChange = setRewardShakeScale,
            onRotationChange = setRewardShakeRotation
        })
        activeAnimations.current.rewardShake = shakeAnimation
        
        -- Cleanup function
        return function()
            -- Cleanup all animations
            for _, animation in pairs(activeAnimations.current) do
                if animation and animation.Stop then
                    animation:Stop()
                end
            end
            activeAnimations.current = {}
        end
    end, {})
    
    -- Load daily rewards status when panel opens
    React.useEffect(function()
        if props.isVisible then
            setIsLoading(true)
            
            -- Get daily rewards status from server
            local getDailyRewardsStatusRemote = ReplicatedStorage:WaitForChild("GetDailyRewardsStatus", 5)
            if getDailyRewardsStatusRemote then
                task.spawn(function()
                    local success, result = pcall(function()
                        return getDailyRewardsStatusRemote:InvokeServer()
                    end)
                    
                    if success and result then
                        setDailyStatus(result)
                    else
                        warn("DailyRewardsPanel: Failed to load daily rewards status:", result)
                        setDailyStatus({
                            currentStreak = 1,
                            nextRewardDay = 1,
                            canClaim = false,
                            streakBroken = false,
                            rewardStatuses = {}
                        })
                    end
                    
                    setIsLoading(false)
                end)
            else
                warn("DailyRewardsPanel: GetDailyRewardsStatus remote not found")
                setIsLoading(false)
            end
        end
    end, {props.isVisible})
    
    -- Timer effect to update countdown until next reward
    React.useEffect(function()
        if not props.isVisible or not dailyStatus or dailyStatus.canClaim then
            return
        end
        
        local function updateTimer()
            -- Calculate time until next day (midnight)
            local currentTime = os.time()
            local secondsInDay = 24 * 60 * 60
            local secondsSinceMidnight = currentTime % secondsInDay
            local secondsUntilMidnight = secondsInDay - secondsSinceMidnight
            
            local hours = math.floor(secondsUntilMidnight / 3600)
            local minutes = math.floor((secondsUntilMidnight % 3600) / 60)
            local seconds = secondsUntilMidnight % 60
            
            local timeText = string.format("%02d:%02d:%02d", hours, minutes, seconds)
            setTimeUntilNextReward(timeText)
        end
        
        -- Update immediately and then every second
        updateTimer()
        local heartbeatConnection = game:GetService("RunService").Heartbeat:Connect(function()
            updateTimer()
        end)
        
        return function()
            if heartbeatConnection then
                heartbeatConnection:Disconnect()
            end
        end
    end, {props.isVisible, dailyStatus})
    
    if not props.isVisible then
        return nil
    end
    
    -- Show loading state
    if isLoading or not dailyStatus then
        return React.createElement("ScreenGui", {
            Name = "DailyRewardsGUI",
            ResetOnSpawn = false,
            IgnoreGuiInset = true,
        }, {
            LoadingFrame = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 0.5,
                ZIndex = 100
            }, {
                LoadingText = React.createElement("TextLabel", {
                    Size = UDim2.new(0, 400, 0, 100),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Text = "Loading Daily Rewards...",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.getTextSize(32),
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 101
                })
            })
        })
    end
    
    -- Get all rewards and calculate states
    local allRewards = DailyRewardsConfig.getAllRewards()
    
    -- Create smooth gradient progression for card outlines (pink-purple-teal theme)
    local function getGradientColor(cardIndex, totalCards)
        local progress = (cardIndex - 1) / math.max(totalCards - 1, 1) -- 0 to 1
        local cycle = progress * 3 -- 0 to 3 for 4 color transitions
        
        local r, g, b
        if cycle < 1 then
            -- Pink to Purple (0-1)
            local t = cycle
            r = math.floor(255 * (1 - t) + 180 * t)
            g = math.floor(100 * (1 - t) + 50 * t) 
            b = math.floor(255 * (1 - t) + 255 * t)
        elseif cycle < 2 then
            -- Purple to Teal (1-2)
            local t = cycle - 1
            r = math.floor(180 * (1 - t) + 50 * t)
            g = math.floor(50 * (1 - t) + 200 * t)
            b = math.floor(255 * (1 - t) + 200 * t)
        elseif cycle < 3 then
            -- Teal to Cyan (2-3)
            local t = cycle - 2
            r = math.floor(50 * (1 - t) + 0 * t)
            g = math.floor(200 * (1 - t) + 255 * t)
            b = math.floor(200 * (1 - t) + 255 * t)
        else
            -- Cyan back to Pink (3+)
            local t = cycle - 3
            r = math.floor(0 * (1 - t) + 255 * t)
            g = math.floor(255 * (1 - t) + 100 * t)
            b = math.floor(255 * (1 - t) + 255 * t)
        end
        
        return Color3.fromRGB(r, g, b)
    end
    
    -- Handle claiming a daily reward
    local function handleClaimReward(dayNumber)
        local claimDailyRewardRemote = ReplicatedStorage:FindFirstChild("ClaimDailyReward")
        if not claimDailyRewardRemote then
            warn("DailyRewardsPanel: ClaimDailyReward remote not found")
            return
        end
        
        task.spawn(function()
            local success, result = pcall(function()
                return claimDailyRewardRemote:InvokeServer(dayNumber)
            end)
            
            if success and result and result.success then
                -- Show reward popup
                RewardsService:ShowReward({
                    type = result.reward.type,
                    amount = result.reward.amount,
                    petName = result.reward.petName,
                    boost = result.reward.boost,
                    source = "Daily Rewards"
                })
                
                -- Refresh status
                local getDailyRewardsStatusRemote = ReplicatedStorage:FindFirstChild("GetDailyRewardsStatus")
                if getDailyRewardsStatusRemote then
                    local statusSuccess, statusResult = pcall(function()
                        return getDailyRewardsStatusRemote:InvokeServer()
                    end)
                    
                    if statusSuccess and statusResult then
                        setDailyStatus(statusResult)
                    end
                end
            else
                warn("DailyRewardsPanel: Failed to claim reward:", result and result.message or "Unknown error")
            end
        end)
    end
    
    -- Create reward cards
    local rewardCards = {}
    for index, reward in ipairs(allRewards) do
        -- Find status for this day
        local rewardStatus = nil
        for _, status in ipairs(dailyStatus.rewardStatuses or {}) do
            if status.day == reward.day then
                rewardStatus = status
                break
            end
        end
        
        local status = rewardStatus and rewardStatus.status or "locked"
        local canClaim = status == "available"
        local isClaimed = status == "claimed"
        local isLocked = status == "locked"
        
        local cardColor = getGradientColor(index, #allRewards)
        local cardBackgroundColor
        local buttonText
        local buttonColor
        
        if isClaimed then
            cardBackgroundColor = Color3.fromRGB(240, 220, 255) -- Light purple background for claimed
            buttonText = "CLAIMED"
            buttonColor = Color3.fromRGB(180, 100, 255) -- Purple button for claimed
        elseif canClaim then
            cardBackgroundColor = Color3.fromRGB(255, 255, 255) -- White background
            buttonText = "CLAIM"
            buttonColor = Color3.fromRGB(255, 100, 180) -- Pink button for claimable
        else
            cardBackgroundColor = Color3.fromRGB(255, 255, 255) -- White background
            buttonText = "DAY " .. reward.day
            buttonColor = Color3.fromRGB(120, 160, 180) -- Teal-gray for locked
        end
        
        local cardChildren = {
            -- Rounded corners
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(8))
            }),
            
            -- Vibrant color outline for each card
            ColorOutline = React.createElement("UIStroke", {
                Color = cardColor,
                Thickness = ScreenUtils.getProportionalSize(3)
            }),
            
            -- Content container with layout (excludes the button)
            ContentContainer = React.createElement("Frame", {
                Name = "ContentContainer",
                Size = UDim2.new(1, 0, 1, -ScreenUtils.getProportionalSize(120)),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                ZIndex = 102
            }, {
                -- Card padding for content
                Padding = React.createElement("UIPadding", {
                    PaddingTop = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(10)),
                    PaddingBottom = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(150)),
                    PaddingLeft = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(50)),
                    PaddingRight = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(50))
                }),
                
                -- Vertical layout for content only
                Layout = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Top,
                    Padding = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(10))
                }),
                
                -- Pet Model viewport with black overlay for locked rewards
                React.createElement("Frame", {
                    Name = "PetModelContainer",
                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(120) * (canClaim and rewardShakeScale or 1), 0, ScreenUtils.getProportionalSize(120) * (canClaim and rewardShakeScale or 1)),
                    Position = UDim2.new(0.5, 0, 0, 0),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    LayoutOrder = 1,
                    ZIndex = 103,
                    Rotation = canClaim and rewardShakeRotation or 0
                }, {
                    -- ViewportFrame for the pet model
                    PetModel = React.createElement("ViewportFrame", {
                        Name = "PetModel",
                        Size = UDim2.new(1, 0, 1, 0),
                        Position = UDim2.new(0, 0, 0, 0),
                        BackgroundTransparency = 1,
                        ZIndex = 103,
                    -- Load pet model when viewport is created
                    [React.Event.AncestryChanged] = function(rbx)
                        if rbx.Parent then
                            task.spawn(function()
                                task.wait(0.1)
                                
                                -- Load pet model from ReplicatedStorage.Pets
                                local petsFolder = ReplicatedStorage:FindFirstChild("Pets")
                                
                                if petsFolder then
                                    local petModelTemplate = petsFolder:FindFirstChild(reward.petName)
                                    if petModelTemplate then
                                        -- Clone model
                                        local model = petModelTemplate:Clone()
                                        model.Name = "PetModel"
                                        
                                        -- Set PrimaryPart if missing
                                        if not model.PrimaryPart then
                                            local largestPart = nil
                                            local largestSize = 0
                                            
                                            for _, part in pairs(model:GetDescendants()) do
                                                if part:IsA("BasePart") then
                                                    local size = part.Size.X * part.Size.Y * part.Size.Z
                                                    if size > largestSize then
                                                        largestSize = size
                                                        largestPart = part
                                                    end
                                                end
                                            end
                                            
                                            if largestPart then
                                                model.PrimaryPart = largestPart
                                            end
                                        end
                                        
                                        -- Prepare model
                                        for _, part in pairs(model:GetDescendants()) do
                                            if part:IsA("BasePart") then
                                                part.CanCollide = false
                                                part.Anchored = true
                                                part.Massless = true
                                                
                                                -- Black out the model for locked rewards
                                                if isLocked then
                                                    part.Color = Color3.fromRGB(0, 0, 0) -- Pure black
                                                    part.Material = Enum.Material.Neon -- Make it solid black
                                                end
                                            elseif isLocked then
                                                -- Black out faces, decals, textures, etc.
                                                if part:IsA("Decal") or part:IsA("Texture") then
                                                    part.Color3 = Color3.fromRGB(0, 0, 0) -- Black tint
                                                    part.Transparency = 0.9 -- Nearly invisible
                                                elseif part:IsA("SurfaceGui") then
                                                    part.Enabled = false -- Hide surface GUIs
                                                elseif part:IsA("BillboardGui") or part:IsA("SurfaceGui") then
                                                    part.Enabled = false -- Hide any GUI elements
                                                elseif part:IsA("Fire") or part:IsA("Smoke") or part:IsA("Sparkles") then
                                                    part.Enabled = false -- Hide particle effects
                                                elseif part:IsA("PointLight") or part:IsA("SpotLight") or part:IsA("SurfaceLight") then
                                                    part.Enabled = false -- Turn off lights
                                                elseif part:IsA("Sound") then
                                                    part.Volume = 0 -- Mute sounds
                                                end
                                            end
                                        end
                                        
                                        -- Rotate model
                                        local modelCFrame, modelSize = model:GetBoundingBox()
                                        local offset = modelCFrame.Position
                                        
                                        -- Move all parts to center the model at origin
                                        for _, part in pairs(model:GetDescendants()) do
                                            if part:IsA("BasePart") then
                                                part.Position = part.Position - offset
                                            end
                                        end
                                        
                                        -- Apply rotation to each part around the origin (120 degrees)
                                        local rotationAngle = 120
                                        
                                        for _, part in pairs(model:GetDescendants()) do
                                            if part:IsA("BasePart") then
                                                local rotationCFrame = CFrame.Angles(math.rad(20), math.rad(rotationAngle), 0)
                                                local currentPos = part.Position
                                                local rotatedPos = rotationCFrame * currentPos
                                                part.Position = rotatedPos
                                                part.CFrame = CFrame.new(rotatedPos) * rotationCFrame * (part.CFrame - part.Position)
                                            end
                                        end
                                        
                                        -- Parent to viewport
                                        model.Parent = rbx
                                        
                                        -- Setup camera
                                        local camera = Instance.new("Camera")
                                        camera.CameraType = Enum.CameraType.Scriptable
                                        camera.CFrame = CFrame.new(0.1, -0.15, 10)
                                        camera.FieldOfView = 90
                                        camera.Parent = rbx
                                        rbx.CurrentCamera = camera
                                        
                                        -- Set lighting
                                        rbx.LightDirection = Vector3.new(0, -0.1, -1).Unit
                                        rbx.Ambient = Color3.fromRGB(255, 255, 255)
                                        rbx.LightColor = Color3.fromRGB(255, 255, 255)
                                    end
                                end
                            end)
                        end
                    end
                })
                }),
                
                -- Boost text (always white with black outline)
                BoostText = React.createElement("TextLabel", {
                    Name = "BoostText",
                    Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(35)),
                    BackgroundTransparency = 1,
                    Text = NumberFormatter.format(reward.boost) .. "x Boost",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.getTextSize(32),
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextScaled = false,
                    TextWrapped = false,
                    LayoutOrder = 2,
                    ZIndex = 103,
                    -- Black outline on text
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                }, {
                    -- Thicker black outline for boost text
                    BoostTextStroke = React.createElement("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = ScreenUtils.getProportionalSize(2),
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
                    })
                }),
                
                -- Pet name text (rainbow gradient for ??? only)
                PetNameText = React.createElement("TextLabel", {
                    Name = "PetNameText",
                    Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(35)),
                    BackgroundTransparency = 1,
                    Text = isLocked and "???" or reward.petName,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.getTextSize(30),
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextScaled = false,
                    TextWrapped = false,
                    LayoutOrder = 3,
                    ZIndex = 103,
                    -- Black outline on text
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                }, {
                    -- Rainbow gradient for locked rewards (??? text only)
                    isLocked and React.createElement("UIGradient", {
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
                        Rotation = 45 -- Static angle for consistency
                    }) or nil,
                    -- Thicker black outline for pet name text
                    PetNameTextStroke = React.createElement("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = ScreenUtils.getProportionalSize(2),
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
                    })
                })
            }),
            
            -- Button positioned at bottom of card
            ClaimButton = React.createElement("Frame", {
                Name = "ClaimButtonContainer",
                Size = UDim2.new(0.9, 0, 0, ScreenUtils.getProportionalSize(60)),
                Position = UDim2.new(0.5, 0, 1, -ScreenUtils.getProportionalSize(15)),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                ZIndex = 104,
            }, {
                -- Gradient overlay for shiny effect
                ButtonGradient = React.createElement("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, isClaimed and Color3.fromRGB(200, 120, 255) or 
                                                     (canClaim and Color3.fromRGB(255, 120, 200) or Color3.fromRGB(140, 180, 200))),
                        ColorSequenceKeypoint.new(0.5, isClaimed and Color3.fromRGB(160, 80, 220) or 
                                                      (canClaim and Color3.fromRGB(220, 80, 160) or Color3.fromRGB(100, 140, 160))),
                        ColorSequenceKeypoint.new(1, isClaimed and Color3.fromRGB(120, 40, 180) or 
                                                     (canClaim and Color3.fromRGB(180, 40, 120) or Color3.fromRGB(60, 100, 120)))
                    }),
                    Rotation = 0
                }),
                
                -- Actual button with text
                ActualButton = React.createElement("TextButton", {
                    Name = "ActualButton",
                    Size = UDim2.new(1, 0, 1, 0),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Text = buttonText,
                    TextColor3 = canClaim and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180), -- Grey text for non-clickable
                    TextSize = ScreenUtils.getTextSize(40),
                    Font = Enum.Font.SourceSans,
                    BorderSizePixel = 0,
                    Active = canClaim,
                    ZIndex = 105,
                    -- Thicker black outline on button text
                    TextStrokeTransparency = canClaim and 0 or 0.3, -- Faded outline for non-clickable
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    [React.Event.Activated] = canClaim and function()
                        handleClaimReward(reward.day)
                    end or nil
                }, {
                    -- Thicker text outline for button text
                    ButtonTextStroke = React.createElement("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = ScreenUtils.getProportionalSize(2),
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
                    })
                }),
                -- Rounded button corners
                ButtonCorner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(8))
                }),
                
                -- Black outline around the BUTTON itself
                ButtonOutline = React.createElement("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = ScreenUtils.getProportionalSize(1),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                })
            }),
            
            -- Claimed badge overlay when reward is claimed
            isClaimed and React.createElement("Frame", {
                Name = "ClaimedOverlay",
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 0.6,
                ZIndex = 110
            }, {
                -- Rounded corners to match card
                ClaimedCorner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(8))
                }),
                
                -- Large "CLAIMED" text badge
                ClaimedBadge = React.createElement("TextLabel", {
                    Name = "ClaimedBadge",
                    Size = UDim2.new(0.8, 0, 0.3, 0),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = Color3.fromRGB(180, 100, 255), -- Purple badge
                    Text = "CLAIMED",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.getTextSize(24),
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    ZIndex = 111,
                    Rotation = -15,
                    -- Black outline on white text
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                }, {
                    -- Badge rounded corners
                    BadgeCorner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(8))
                    }),
                    
                    -- Badge black outline
                    BadgeOutline = React.createElement("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = ScreenUtils.getProportionalSize(2)
                    })
                })
            }) or nil
        }
        
        rewardCards["RewardCard" .. index] = React.createElement("Frame", {
            Name = "RewardCard" .. index,
            BackgroundColor3 = cardBackgroundColor,
            BorderSizePixel = 0,
            LayoutOrder = index,
            ZIndex = 102,
            Size = UDim2.new(0, ScreenUtils.getProportionalSize(280), 0, ScreenUtils.getProportionalSize(280)),
            [React.Event.MouseEnter] = function()
                playHoverSound()
            end
        }, cardChildren)
    end
    
    -- Calculate responsive card size - 5 columns (same as playtime rewards)
    local cardSize = ScreenUtils.getProportionalSize(280)
    local cardPadding = ScreenUtils.getProportionalSize(25)
    local contentPadding = ScreenUtils.getProportionalSize(35)
    local columns = 5 -- Always 5 columns
    
    return React.createElement("ScreenGui", {
        Name = "DailyRewardsGUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
    }, {
        -- Click-outside overlay
        ClickOutsideOverlay = React.createElement("TextButton", {
            Name = "DailyRewardsOverlay",
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 99,
            [React.Event.MouseButton1Click] = function()
                if props.onClose then 
                    props.onClose() 
                end
            end
        }),
        
        -- Main panel
        MainPanel = React.createElement("Frame", {
            Size = ScreenUtils.udim2(0.6, 0, 0.6, 0),
            Position = ScreenUtils.udim2(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(245, 240, 255), -- Light purple background
            BorderSizePixel = 0,
            ZIndex = 100
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(25))
            }),
            
            -- Black outline for the main panel
            PanelStroke = React.createElement("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = ScreenUtils.getProportionalSize(6),
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            }),
            
            -- Click handler frame to prevent closing when clicking inside
            ClickHandler = React.createElement("TextButton", {
                Name = "ClickHandler",
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 99,
                [React.Event.Activated] = function()
                    -- Do nothing to prevent closing when clicking inside
                end
            }),
        
            -- Header section
            Header = React.createElement("Frame", {
                Name = "Header",
                Size = UDim2.new(1, -ScreenUtils.getProportionalSize(20), 0, ScreenUtils.getProportionalSize(70)),
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(10), 0, ScreenUtils.getProportionalSize(10)),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 101
            }, {
                -- Gradient background for header
                HeaderBackground = React.createElement("Frame", {
                    Name = "HeaderBackground",
                    Size = UDim2.new(1, 0, 1, 0),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundColor3 = getGradientColor(1, 5),
                    BorderSizePixel = 0,
                    ZIndex = 101
                }, {
                    HeaderCorner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(12))
                    }),
                    
                    -- Header gradient overlay
                    HeaderGradient = React.createElement("UIGradient", {
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, getGradientColor(1, 5)),
                            ColorSequenceKeypoint.new(0.5, getGradientColor(2, 5)),
                            ColorSequenceKeypoint.new(1, getGradientColor(3, 5))
                        }),
                        Rotation = 45
                    }),
                    
                    -- Header stroke
                    HeaderStroke = React.createElement("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = ScreenUtils.getProportionalSize(2)
                    })
                }),
                
                HeaderTitle = React.createElement("TextLabel", {
                    Name = "HeaderTitle",
                    Size = UDim2.new(1, -ScreenUtils.getProportionalSize(100), 1, 0),
                    Position = UDim2.new(0.5, 0, 0, 0),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    Text = "Daily Rewards - Streak: " .. (dailyStatus.currentStreak or 0),
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.getTextSize(52),
                    Font = Enum.Font.Cartoon,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    ZIndex = 102,
                    -- Black text outline
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                }, {
                    -- Thicker text outline
                    HeaderTextStroke = React.createElement("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = ScreenUtils.getProportionalSize(3),
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
                    })
                }),
                
                CloseButton = React.createElement("ImageButton", {
                    Name = "CloseButton",
                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(40), 0, ScreenUtils.getProportionalSize(40)),
                    Position = UDim2.new(1, -ScreenUtils.getProportionalSize(50), 0.5, -ScreenUtils.getProportionalSize(20)),
                    BackgroundColor3 = Color3.fromRGB(220, 80, 80),
                    Image = IconAssets.getIcon("UI", "X_BUTTON"),
                    ImageColor3 = Color3.fromRGB(255, 255, 255),
                    ScaleType = Enum.ScaleType.Fit,
                    BorderSizePixel = 0,
                    ZIndex = 102,
                    [React.Event.Activated] = function()
                        if props.onClose then
                            props.onClose()
                        end
                    end
                }, {
                    CloseCorner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(8))
                    }),
                    
                    -- Black outline for close button
                    CloseStroke = React.createElement("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = ScreenUtils.getProportionalSize(2)
                    })
                })
            }),
            
            -- Content with scrollable frame for reward cards
            Content = React.createElement("ScrollingFrame", {
                Name = "Content",
                Size = UDim2.new(1, -ScreenUtils.getProportionalSize(20), 1, -ScreenUtils.getProportionalSize(90)),
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(10), 0, ScreenUtils.getProportionalSize(80)),
                BackgroundTransparency = 1,
                ScrollBarThickness = ScreenUtils.getProportionalSize(8),
                ScrollBarImageColor3 = Color3.fromRGB(150, 150, 150),
                ScrollingDirection = Enum.ScrollingDirection.Y,
                ScrollingEnabled = true,
                -- Calculate canvas size for 10 rewards in 2 rows (5 per row) with extra bottom padding
                CanvasSize = UDim2.new(0, 0, 0, 2 * (cardSize + cardPadding) + (2 * contentPadding) + 400),
                ZIndex = 101
            }, {
                ContentPadding = React.createElement("UIPadding", {
                    PaddingTop = ScreenUtils.udim(0, contentPadding),
                    PaddingBottom = ScreenUtils.udim(0, contentPadding),
                    PaddingLeft = ScreenUtils.udim(0, contentPadding),
                    PaddingRight = ScreenUtils.udim(0, contentPadding)
                }),
                
                -- Grid layout for reward cards (5 columns)
                GridLayout = React.createElement("UIGridLayout", {
                    CellSize = UDim2.new(0, cardSize, 0, cardSize),
                    CellPadding = UDim2.new(0, cardPadding, 0, cardPadding),
                    StartCorner = Enum.StartCorner.TopLeft,
                    FillDirectionMaxCells = columns,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Top
                })
            }, rewardCards)
        }),
        
        -- Warning text centered at bottom with breathing animation
        WarningText = React.createElement("TextLabel", {
            Name = "WarningText",
            Size = UDim2.new(0, ScreenUtils.getProportionalSize(800), 0, ScreenUtils.getProportionalSize(60)),
            Position = UDim2.new(0.5, 0, 0.825, ScreenUtils.getProportionalSize(20) + animationOffset),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
            Text = (dailyStatus.streakBroken and "Your streak was broken! Start fresh with Day 1." or 
                   (dailyStatus.canClaim and "You can claim your daily reward!" or 
                    ("Come back in " .. timeUntilNextReward .. " for your next reward!"))),
            TextColor3 = dailyStatus.streakBroken and Color3.fromRGB(255, 80, 120) or 
                        (dailyStatus.canClaim and Color3.fromRGB(255, 100, 200) or Color3.fromRGB(100, 180, 220)),
            TextSize = ScreenUtils.getTextSize(60),
            Font = Enum.Font.Cartoon,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 105,
            -- Black text outline
            TextStrokeTransparency = 0,
            TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        }, {
            -- Thicker black outline for warning text
            WarningTextStroke = React.createElement("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = ScreenUtils.getProportionalSize(3),
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
            })
        })
    })
end

return DailyRewardsPanel