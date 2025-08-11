-- PlaytimeRewardsPanel - UI panel showing playtime milestone rewards in card grid layout
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local React = require(ReplicatedStorage.Packages.react)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local PlaytimeRewardsConfig = require(ReplicatedStorage.config.PlaytimeRewardsConfig)
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

local function PlaytimeRewardsPanel(props)
    -- Session-based playtime timer using shared start time from App
    local sessionStartTime = props.sharedSessionStartTime or tick()
    local currentSessionTime, setCurrentSessionTime = React.useState(0)
    
    -- Animation state for breathing effect and shake animations
    local animationOffset, setAnimationOffset = React.useState(0)
    local rewardShakeScale, setRewardShakeScale = React.useState(1)
    local rewardShakeRotation, setRewardShakeRotation = React.useState(0)
    
    -- Animation references for cleanup
    local activeAnimations = React.useRef({})
    
    -- Use shared session claimed rewards from App component
    local sessionClaimedRewards = props.sharedSessionClaimedRewards or {}
    local setSessionClaimedRewards = props.setSharedSessionClaimedRewards or function() end
    
    -- Setup animations using AnimationService
    React.useEffect(function()
        -- Create bouncing animation for warning text using callback method (same as Pet Index)
        local bounceAnimation = AnimationService:CreateReactBounceAnimation({
            duration = 0.8, -- Same as Pet Index
            upOffset = 10, -- Same as Pet Index  
            downOffset = 10, -- Same as Pet Index
            pauseBetween = 0.5 -- Same as Pet Index
        }, {
            onPositionChange = setAnimationOffset
        })
        activeAnimations.current.warningBounce = bounceAnimation
        
        -- Setup shake animation for claimable rewards using callback method
        local shakeAnimation = AnimationService:CreateReactShakeAnimation({
            interval = 1.5, -- Every 1.5 seconds like original
            growPhase = 0.1, -- 100ms grow phase
            shakePhase = 0.3, -- 300ms shake phase
            maxScale = 1.15, -- 1.15x scale like original
            shakeIntensity = 8 -- 8 pixels of shake converted to rotation
        }, {
            onScaleChange = setRewardShakeScale,
            onRotationChange = setRewardShakeRotation
        })
        activeAnimations.current.rewardShake = shakeAnimation
        
        -- Timer for session updates only (animations handled by AnimationService)
        local lastSessionUpdate = 0
        local updateTimer = function()
            local currentTime = tick()
            local sessionMinutes = (currentTime - sessionStartTime) / 60
            
            -- Only update session time state once per second to avoid React loops
            if currentTime - lastSessionUpdate >= 1 then
                lastSessionUpdate = currentTime
                setCurrentSessionTime(sessionMinutes)
            end
        end
        
        -- Update immediately
        updateTimer()
        
        -- Setup timer connection (only for session time updates)
        local heartbeatConnection = game:GetService("RunService").Heartbeat:Connect(updateTimer)
        
        -- All animations now handled by AnimationService above
        
        -- Cleanup function
        return function()
            if heartbeatConnection then
                heartbeatConnection:Disconnect()
            end
            -- Cleanup all animations
            for _, animation in pairs(activeAnimations.current) do
                if animation and animation.Stop then
                    animation:Stop()
                end
            end
            activeAnimations.current = {}
        end
    end, {})
    
    if not props.isVisible then
        return nil
    end
    
    -- Get all rewards and calculate states
    local allRewards = PlaytimeRewardsConfig.getAllRewards()
    local currentPlaytime = currentSessionTime -- Use session time instead of server time
    
    -- Create smooth gradient progression for card outlines
    -- Fade from green -> blue -> yellow -> red -> purple -> back to green
    local function getGradientColor(cardIndex, totalCards)
        local progress = (cardIndex - 1) / math.max(totalCards - 1, 1) -- 0 to 1
        local cycle = progress * 4 -- 0 to 4 for 5 color transitions
        
        local r, g, b
        if cycle < 1 then
            -- Green to Blue (0-1)
            local t = cycle
            r = math.floor(85 * (1 - t) + 54 * t)
            g = math.floor(255 * (1 - t) + 162 * t) 
            b = math.floor(85 * (1 - t) + 235 * t)
        elseif cycle < 2 then
            -- Blue to Yellow (1-2)
            local t = cycle - 1
            r = math.floor(54 * (1 - t) + 255 * t)
            g = math.floor(162 * (1 - t) + 235 * t)
            b = math.floor(235 * (1 - t) + 85 * t)
        elseif cycle < 3 then
            -- Yellow to Red (2-3)
            local t = cycle - 2
            r = math.floor(255 * (1 - t) + 255 * t)
            g = math.floor(235 * (1 - t) + 85 * t)
            b = math.floor(85 * (1 - t) + 85 * t)
        elseif cycle < 4 then
            -- Red to Purple (3-4)
            local t = cycle - 3
            r = math.floor(255 * (1 - t) + 153 * t)
            g = math.floor(85 * (1 - t) + 102 * t)
            b = math.floor(85 * (1 - t) + 255 * t)
        else
            -- Purple back to Green (4+)
            local t = cycle - 4
            r = math.floor(153 * (1 - t) + 85 * t)
            g = math.floor(102 * (1 - t) + 255 * t)
            b = math.floor(255 * (1 - t) + 85 * t)
        end
        
        return Color3.fromRGB(r, g, b)
    end
    
    -- Create reward cards in the established UI pattern
    local rewardCards = {}
    for index, reward in ipairs(allRewards) do
        local isAvailable = currentPlaytime >= reward.timeMinutes
        local isClaimed = sessionClaimedRewards[reward.timeMinutes] or false -- Use session-based claimed state
        
        local cardColor
        local cardBackgroundColor
        local buttonText
        local buttonColor
        local canClaim = false
        local timeUntilAvailable = 0
        
        if isClaimed then
            cardColor = Color3.fromRGB(255, 215, 0) -- Gold border for claimed
            cardBackgroundColor = Color3.fromRGB(255, 250, 205) -- Light gold background for claimed
            buttonText = "CLAIMED"
            buttonColor = Color3.fromRGB(255, 215, 0) -- Gold button for claimed
        elseif isAvailable then
            cardColor = Color3.fromRGB(85, 200, 85) -- Green for available
            cardBackgroundColor = Color3.fromRGB(255, 255, 255) -- White background
            buttonText = "CLAIM"
            buttonColor = Color3.fromRGB(50, 180, 50)
            canClaim = true
        else
            cardColor = Color3.fromRGB(200, 120, 120) -- Red for locked
            cardBackgroundColor = Color3.fromRGB(255, 255, 255) -- White background
            timeUntilAvailable = reward.timeMinutes - currentPlaytime
            buttonText = "In " .. PlaytimeRewardsConfig.formatTime(timeUntilAvailable)
            buttonColor = Color3.fromRGB(160, 160, 160)
        end
        
        local cardColor = getGradientColor(index, #allRewards)
        
        local cardChildren = {
            -- Rounded corners - RESPONSIVE
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(8)) -- RESPONSIVE corner radius
            }),
            
            -- Vibrant color outline for each card - RESPONSIVE
            ColorOutline = React.createElement("UIStroke", {
                Color = cardColor, -- Vibrant color based on card index
                Thickness = ScreenUtils.getProportionalSize(3) -- RESPONSIVE thickness for vibrant colors
            }),
            
            -- Content container with layout (excludes the button) - RESPONSIVE spacing
            ContentContainer = React.createElement("Frame", {
                Name = "ContentContainer",
                Size = UDim2.new(1, 0, 1, -ScreenUtils.getProportionalSize(120)), -- Responsive button space
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                ZIndex = 102
            }, {
                -- Card padding for content - ALL RESPONSIVE
                Padding = React.createElement("UIPadding", {
                    PaddingTop = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(10)), -- Responsive top padding
                    PaddingBottom = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(150)), -- Responsive bottom padding
                    PaddingLeft = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(50)), -- Responsive side padding
                    PaddingRight = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(50)) -- Responsive side padding
                }),
                
                -- Vertical layout for content only - RESPONSIVE
                Layout = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Top,
                    Padding = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(10)) -- Responsive icon-text spacing
                }),
                
                -- Currency Icon, Pet Model, or Rebirth Icon (Dynamic based on reward type)
                reward.type == "Pet" and React.createElement("ViewportFrame", {
                    Name = "PetModel",
                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(120) * (canClaim and rewardShakeScale or 1), 0, ScreenUtils.getProportionalSize(120) * (canClaim and rewardShakeScale or 1)), -- React state animation
                    Position = UDim2.new(0.5, 0, 0, 0), -- Base position
                    AnchorPoint = Vector2.new(0.5, 0), -- Center anchor
                    BackgroundTransparency = 1,
                    LayoutOrder = 1,
                    ZIndex = 103,
                    Rotation = canClaim and rewardShakeRotation or 0, -- React state rotation
                    -- Load pet model when viewport is created
                    [React.Event.AncestryChanged] = function(rbx)
                        if rbx.Parent then
                            -- Delay to ensure viewport is ready
                            task.spawn(function()
                                task.wait(0.1)
                                
                                -- Try to get actual pet model from ReplicatedStorage.Pets
                                local petsFolder = ReplicatedStorage:FindFirstChild("Pets")
                                
                                if petsFolder then
                                    local petModelTemplate = petsFolder:FindFirstChild(reward.petName)
                                    if petModelTemplate then
                                        -- Clone model WITHOUT SCALING (Baby size = scale 1)
                                        local model = petModelTemplate:Clone()
                                        model.Name = "PetModel"
                                        
                                        -- Set PrimaryPart if missing (this is the key fix!)
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
                                            end
                                        end
                                        
                                        -- Use the old manual rotation method (like original PetInventoryUI)
                                        -- This rotates each part individually instead of relying on PrimaryPart
                                        
                                        -- Move entire model to origin first
                                        local modelCFrame, modelSize = model:GetBoundingBox()
                                        local offset = modelCFrame.Position
                                        
                                        -- Move all parts to center the model at origin
                                        for _, part in pairs(model:GetDescendants()) do
                                            if part:IsA("BasePart") then
                                                part.Position = part.Position - offset
                                            end
                                        end
                                        
                                        -- Now apply rotation to each part around the origin (120 degrees)
                                        local rotationAngle = 120
                                        
                                        for _, part in pairs(model:GetDescendants()) do
                                            if part:IsA("BasePart") then
                                                -- Rotate each part around the origin
                                                local rotationCFrame = CFrame.Angles(math.rad(20), math.rad(rotationAngle), 0)
                                                local currentPos = part.Position
                                                local rotatedPos = rotationCFrame * currentPos
                                                part.Position = rotatedPos
                                                
                                                -- Also rotate the part's orientation
                                                part.CFrame = CFrame.new(rotatedPos) * rotationCFrame * (part.CFrame - part.Position)
                                            end
                                        end
                                        
                                        -- Parent to viewport
                                        model.Parent = rbx
                                        
                                        -- Setup camera for ULTIMATE quality
                                        local camera = Instance.new("Camera")
                                        camera.CameraType = Enum.CameraType.Scriptable
                                        camera.CFrame = CFrame.new(0.1, -0.15, 10) -- Even closer for ultimate quality
                                        camera.FieldOfView = 90 -- Higher FOV to maintain size at closer distance
                                        camera.Parent = rbx
                                        rbx.CurrentCamera = camera
                                        
                                        -- Set lighting back to reference
                                        rbx.LightDirection = Vector3.new(0, -0.1, -1).Unit
                                        rbx.Ambient = Color3.fromRGB(255, 255, 255) -- Full bright
                                        rbx.LightColor = Color3.fromRGB(255, 255, 255)
                                    end
                                end
                            end)
                        end
                    end
                }) or React.createElement("ImageLabel", {
                    Name = reward.type == "Rebirth" and "RebirthIcon" or "CurrencyIcon",
                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(120) * (canClaim and rewardShakeScale or 1), 0, ScreenUtils.getProportionalSize(120) * (canClaim and rewardShakeScale or 1)), -- React state animation
                    Position = UDim2.new(0.5, 0, 0, 0), -- Base position
                    AnchorPoint = Vector2.new(0.5, 0), -- Center anchor
                    BackgroundTransparency = 1,
                    Image = reward.type == "Rebirth" and IconAssets.getIcon("UI", "REBIRTH") -- Proper rebirth icon
                        or (reward.type == "Diamonds" and IconAssets.getIcon("CURRENCY", "DIAMONDS") or IconAssets.getIcon("CURRENCY", "MONEY")),
                    ScaleType = Enum.ScaleType.Fit,
                    ImageColor3 = Color3.fromRGB(255, 255, 255), -- No tinting - natural icon colors for all types
                    LayoutOrder = 1,
                    ZIndex = 103,
                    Rotation = canClaim and rewardShakeRotation or 0 -- React state rotation
                }),
                
                -- Currency amount text - dynamic based on reward type
                Title = React.createElement("TextLabel", {
                    Name = "Title",
                    Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(70)), -- Taller for two lines (50 -> 70)
                    BackgroundTransparency = 1, -- Transparent background
                    Text = reward.type == "Pet" and (reward.boost .. "x Boost\n" .. reward.petName) 
                        or reward.type == "Rebirth" and (NumberFormatter.format(reward.amount) .. "\n" .. "Rebirth" .. (reward.amount > 1 and "s" or ""))
                        or (NumberFormatter.format(reward.amount) .. "\n" .. reward.type), -- Pet boost, rebirth, or currency type
                    TextColor3 = Color3.fromRGB(255, 255, 255), -- White text as requested
                    TextSize = ScreenUtils.getTextSize(32), -- Keep big text size
                    Font = Enum.Font.FredokaOne, -- SakuraOne equivalent (closest available)
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextScaled = false,
                    TextWrapped = false, -- Don't auto-wrap, we control line breaks
                    LayoutOrder = 2,
                    ZIndex = 103,
                    -- Black outline on text
                    TextStrokeTransparency = 0, -- Make outline visible
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0) -- Black outline
                }, {
                    -- Thicker black outline for currency text - RESPONSIVE
                    CurrencyTextStroke = React.createElement("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0), -- Black outline
                        Thickness = ScreenUtils.getProportionalSize(2), -- RESPONSIVE thickness
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual -- Apply to text
                    })
                })
            }),
            
            -- Button positioned at bottom of card - FULLY RESPONSIVE
            ClaimButton = React.createElement("Frame", {
                Name = "ClaimButtonContainer",
                Size = UDim2.new(0.9, 0, 0, ScreenUtils.getProportionalSize(60)), -- Wider button to prevent flickering
                Position = UDim2.new(0.5, 0, 1, -ScreenUtils.getProportionalSize(15)), -- Responsive positioning (60/4 = 15)
                AnchorPoint = Vector2.new(0.5, 0.5), -- Center horizontally, middle vertically
                BackgroundColor3 = Color3.fromRGB(255, 255, 255), -- Base color for gradient
                BorderSizePixel = 0,
                ZIndex = 104, -- Above card
            }, {
                -- Gradient overlay for shiny effect
                ButtonGradient = React.createElement("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, canClaim and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(120, 120, 120)), -- Lighter shade on left
                        ColorSequenceKeypoint.new(0.5, canClaim and Color3.fromRGB(60, 140, 65) or Color3.fromRGB(80, 80, 80)), -- Medium shade in middle
                        ColorSequenceKeypoint.new(1, canClaim and Color3.fromRGB(45, 105, 50) or Color3.fromRGB(50, 50, 50)) -- Darker shade on right
                    }),
                    Rotation = 0 -- Horizontal gradient (left to right)
                }),
                
                -- Actual button with text
                ActualButton = React.createElement("TextButton", {
                    Name = "ActualButton",
                    Size = UDim2.new(1, 0, 1, 0),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundTransparency = 1, -- Transparent so gradient shows through
                    Text = buttonText, -- Either "Claim" or timer
                    TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                    TextSize = ScreenUtils.getTextSize(40), -- RESPONSIVE button text size
                    Font = Enum.Font.SourceSans, -- SakuraOne equivalent
                    BorderSizePixel = 0,
                    Active = canClaim,
                    ZIndex = 105, -- Above gradient
                    -- Thicker black outline on button text
                    TextStrokeTransparency = 0, -- Make outline visible
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0), -- Black outline
                    [React.Event.Activated] = canClaim and function()
                        if props.onClaimReward then
                            -- Show reward popup before claiming
                            RewardsService:ShowReward({
                                type = reward.type,
                                amount = reward.amount,
                                petName = reward.petName, -- For pet rewards
                                source = "Playtime Rewards"
                            })
                            
                            -- Then claim the reward
                            props.onClaimReward(reward.timeMinutes, currentPlaytime)
                        end
                    end or nil
                }, {
                    -- Thicker text outline for button text - RESPONSIVE
                    ButtonTextStroke = React.createElement("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0), -- Black outline for text
                        Thickness = ScreenUtils.getProportionalSize(2), -- Responsive text outline thickness
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual -- Apply to text
                    })
                }),
                -- Rounded button corners - RESPONSIVE
                ButtonCorner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(8)) -- Responsive corner radius
                }),
                
                -- Black outline around the BUTTON itself - RESPONSIVE thickness
                ButtonOutline = React.createElement("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0), -- Black outline around button background
                    Thickness = ScreenUtils.getProportionalSize(1), -- Responsive outline thickness
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border -- Apply only to border
                })
            }),
            
            -- Claimed badge overlay when reward is claimed
            isClaimed and React.createElement("Frame", {
                Name = "ClaimedOverlay",
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(0, 0, 0), -- Dark overlay
                BackgroundTransparency = 0.6, -- Semi-transparent
                ZIndex = 110 -- Above everything else
            }, {
                -- Rounded corners to match card - RESPONSIVE
                ClaimedCorner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(8)) -- Responsive corner radius
                }),
                
                -- Large "CLAIMED" text badge - FULLY RESPONSIVE
                ClaimedBadge = React.createElement("TextLabel", {
                    Name = "ClaimedBadge",
                    Size = UDim2.new(0.8, 0, 0.3, 0),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = Color3.fromRGB(255, 215, 0), -- Gold background
                    Text = "CLAIMED",
                    TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                    TextSize = ScreenUtils.getTextSize(24), -- RESPONSIVE text size
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    ZIndex = 111,
                    Rotation = -15, -- Slight rotation for badge effect
                    -- Black outline on white text
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                }, {
                    -- Badge rounded corners - RESPONSIVE
                    BadgeCorner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(8)) -- Responsive corner radius
                    }),
                    
                    -- Badge black outline - RESPONSIVE
                    BadgeOutline = React.createElement("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = ScreenUtils.getProportionalSize(2) -- Responsive outline thickness
                    })
                })
            }) or nil
        }
        
        rewardCards["RewardCard" .. index] = React.createElement("Frame", {
            Name = "RewardCard" .. index,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255), -- White background
            BorderSizePixel = 0,
            LayoutOrder = index,
            ZIndex = 102,
            -- Explicitly set size to ensure proper scaling (UIGridLayout should override, but this ensures fallback)
            Size = UDim2.new(0, cardSize, 0, cardSize), -- Responsive card size
            [React.Event.MouseEnter] = function()
                playHoverSound()
            end
        }, cardChildren)
    end
    
    -- Calculate responsive card size - always 5 columns
    local cardSize = ScreenUtils.getProportionalSize(280) -- Proportional card size
    local cardPadding = ScreenUtils.getProportionalSize(25) -- Keep original spacing
    local contentPadding = ScreenUtils.getProportionalSize(35) -- Keep original padding
    local columns = 5 -- Always 5 columns (fixed as requested)
    local rows = math.ceil(#allRewards / columns)
    
    return React.createElement("ScreenGui", {
        Name = "PlaytimeRewardsGUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
    }, {
        -- Click-outside overlay (same pattern as other UIs)
        ClickOutsideOverlay = React.createElement("TextButton", {
            Name = "PlaytimeRewardsOverlay",
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 99, -- Behind panel but in front of everything else
            [React.Event.MouseButton1Click] = function()
                -- Close panel when clicking outside
                if props.onClose then 
                    props.onClose() 
                end
            end
        }),
        
        -- Main panel - taller and with VISIBLE black outline and rounded corners
        MainPanel = React.createElement("Frame", { -- Changed from TextButton to Frame
            Size = ScreenUtils.udim2(0.6, 0, 0.6, 0), -- Reduced height slightly (0.65->0.6) for better fit
            Position = ScreenUtils.udim2(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(248, 248, 248), -- Very light grey background
            BorderSizePixel = 0,
            ZIndex = 100
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(25)) -- More rounded corners for outer UI
            }),
            
            -- VISIBLE Black outline for the main panel - MUST be visible!
            PanelStroke = React.createElement("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0), -- Pure black outline
                Thickness = ScreenUtils.getProportionalSize(6), -- RESPONSIVE thickness
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border -- Apply only to border
            }),
            
            -- Click handler frame to prevent closing when clicking inside
            ClickHandler = React.createElement("TextButton", {
                Name = "ClickHandler",
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1, -- Invisible click handler
                Text = "",
                ZIndex = 99, -- Below other content
                [React.Event.Activated] = function()
                    -- Do nothing to prevent closing when clicking inside
                end
            }),
        
            -- Header section - FULLY RESPONSIVE
            Header = React.createElement("Frame", {
                Name = "Header",
                Size = UDim2.new(1, -ScreenUtils.getProportionalSize(20), 0, ScreenUtils.getProportionalSize(70)), -- RESPONSIVE header size
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(10), 0, ScreenUtils.getProportionalSize(10)), -- RESPONSIVE positioning
                BackgroundTransparency = 1, -- Transparent header
                BorderSizePixel = 0,
                ZIndex = 101
            }, {
                -- Gradient background for header using same color logic as cards
                HeaderBackground = React.createElement("Frame", {
                    Name = "HeaderBackground",
                    Size = UDim2.new(1, 0, 1, 0),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundColor3 = getGradientColor(1, 5), -- Use first gradient color
                    BorderSizePixel = 0,
                    ZIndex = 101
                }, {
                    HeaderCorner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(12)) -- RESPONSIVE corner radius
                    }),
                    
                    -- Header gradient overlay
                    HeaderGradient = React.createElement("UIGradient", {
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, getGradientColor(1, 5)),
                            ColorSequenceKeypoint.new(0.5, getGradientColor(2, 5)),
                            ColorSequenceKeypoint.new(1, getGradientColor(3, 5))
                        }),
                        Rotation = 45 -- Keep rotation as-is
                    }),
                    
                    -- Header stroke - RESPONSIVE
                    HeaderStroke = React.createElement("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = ScreenUtils.getProportionalSize(2) -- RESPONSIVE stroke thickness
                    })
                }),
                
                HeaderTitle = React.createElement("TextLabel", {
                    Name = "HeaderTitle",
                    Size = UDim2.new(1, -ScreenUtils.getProportionalSize(100), 1, 0), -- RESPONSIVE width
                    Position = UDim2.new(0.5, 0, 0, 0),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    Text = "Playtime Rewards",
                    TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                    TextSize = ScreenUtils.getTextSize(52), -- Much bigger text (was LARGE ~36, now 52)
                    Font = Enum.Font.Cartoon, -- SakuraOne equivalent (closest available)
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    ZIndex = 102,
                    -- Black text outline
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                }, {
                    -- Thicker text outline - RESPONSIVE
                    HeaderTextStroke = React.createElement("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0), -- Black outline
                        Thickness = ScreenUtils.getProportionalSize(3), -- RESPONSIVE outline thickness
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual -- Apply to text
                    })
                }),
                
                
                CloseButton = React.createElement("ImageButton", {
                    Name = "CloseButton",
                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(40), 0, ScreenUtils.getProportionalSize(40)), -- RESPONSIVE button size
                    Position = UDim2.new(1, -ScreenUtils.getProportionalSize(50), 0.5, -ScreenUtils.getProportionalSize(20)), -- RESPONSIVE positioning
                    BackgroundColor3 = Color3.fromRGB(220, 80, 80),
                    Image = IconAssets.getIcon("UI", "X_BUTTON"), -- Fixed: Use correct X_BUTTON icon
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
                        CornerRadius = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(8)) -- RESPONSIVE corner radius
                    }),
                    
                    -- Black outline for close button - RESPONSIVE
                    CloseStroke = React.createElement("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = ScreenUtils.getProportionalSize(2) -- RESPONSIVE stroke thickness
                    })
                })
            }),
            
            -- Content with scrollable frame for reward cards - FULLY RESPONSIVE
            Content = React.createElement("ScrollingFrame", {
                Name = "Content",
                Size = UDim2.new(1, -ScreenUtils.getProportionalSize(20), 1, -ScreenUtils.getProportionalSize(90)), -- RESPONSIVE spacing for header
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(10), 0, ScreenUtils.getProportionalSize(80)), -- RESPONSIVE positioning
                BackgroundTransparency = 1,
                ScrollBarThickness = ScreenUtils.getProportionalSize(8), -- RESPONSIVE scrollbar thickness
                ScrollBarImageColor3 = Color3.fromRGB(150, 150, 150),
                ScrollingDirection = Enum.ScrollingDirection.Y, -- Ensure vertical scrolling only
                ScrollingEnabled = true, -- Explicitly enable scrolling
                -- Calculate for worst case: assume 3 columns on small screens, 21 rewards = 7 rows
                CanvasSize = UDim2.new(0, 0, 0, math.ceil(#allRewards / 3) * (cardSize + cardPadding) + (2 * contentPadding) + 200),
                ZIndex = 101
            }, {
                ContentPadding = React.createElement("UIPadding", {
                    PaddingTop = ScreenUtils.udim(0, contentPadding), -- Already responsive (contentPadding uses ScreenUtils)
                    PaddingBottom = ScreenUtils.udim(0, contentPadding), -- Already responsive
                    PaddingLeft = ScreenUtils.udim(0, contentPadding), -- Already responsive
                    PaddingRight = ScreenUtils.udim(0, contentPadding) -- Already responsive
                }),
                
                -- Grid layout for reward cards (fixed 5 columns)
                GridLayout = React.createElement("UIGridLayout", {
                    CellSize = UDim2.new(0, cardSize, 0, cardSize), -- cardSize already uses ScreenUtils.getProportionalSize()
                    CellPadding = UDim2.new(0, cardPadding, 0, cardPadding), -- cardPadding already uses ScreenUtils.getProportionalSize()
                    StartCorner = Enum.StartCorner.TopLeft,
                    FillDirectionMaxCells = columns, -- Fixed 5 columns as requested
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Top
                })
            }, rewardCards)
        }),
        
        -- Warning text centered at bottom UNDER the main PlaytimeRewards panel with breathing animation
        WarningText = React.createElement("TextLabel", {
            Name = "WarningText",
            Size = UDim2.new(0, ScreenUtils.getProportionalSize(600), 0, ScreenUtils.getProportionalSize(60)), -- Responsive size for larger text
            Position = UDim2.new(0.5, 0, 0.825, ScreenUtils.getProportionalSize(20) + animationOffset), -- Animated breathing position
            AnchorPoint = Vector2.new(0.5, 0), -- Anchor to center top of text
            BackgroundTransparency = 1, -- Transparent background
            Text = "Session Rewards Reset if you disconnect!",
            TextColor3 = Color3.fromRGB(200, 30, 30), -- Darker red text
            TextSize = ScreenUtils.getTextSize(60), -- Responsive 3x bigger text size (20 * 3 = 60)
            Font = Enum.Font.Cartoon, -- SakuraOne equivalent
            TextXAlignment = Enum.TextXAlignment.Center, -- Center aligned
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 105, -- Above everything else
            -- Black text outline
            TextStrokeTransparency = 0,
            TextStrokeColor3 = Color3.fromRGB(0, 0, 0) -- Black outline
        }, {
            -- Thicker black outline for warning text - RESPONSIVE
            WarningTextStroke = React.createElement("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0), -- Black outline
                Thickness = ScreenUtils.getProportionalSize(3), -- Responsive thicker outline for larger text
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual -- Apply to text
            })
        })
    })
end

return PlaytimeRewardsPanel