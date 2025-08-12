-- FreeOpItemUI - UI panel for Free OP Item reward progress and claiming
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local React = require(ReplicatedStorage.Packages.react)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local FreeOpItemConfig = require(ReplicatedStorage.config.FreeOpItemConfig)
local GamepassConfig = require(ReplicatedStorage.config.GamepassConfig)

local function FreeOpItemUI(props)
    local config = FreeOpItemConfig.GetConfig()
    local requiredTimeSeconds = config.RequiredPlaytimeMinutes * 60
    
    -- Animation state for rainbow gradient rotation
    local rainbowRotation, setRainbowRotation = React.useState(0)
    
    -- Dynamic gamepass info
    local gamepassPrice, setGamepassPrice = React.useState("99") -- Fallback to config price
    local gamepassIcon, setGamepassIcon = React.useState("rbxasset://textures/ui/GuiImagePlaceholder.png")
    
    -- Group check state
    local isInGroup, setIsInGroup = React.useState(false)
    local groupCheckCooldown, setGroupCheckCooldown = React.useState(0)
    local lastGroupCheckTime = React.useRef(0)
    local hasCheckedOnJoin = React.useRef(false)
    
    -- Client-side session tracking (like PlaytimeRewards)
    local sessionStartTime = props.sharedSessionStartTime or tick()
    local currentSessionTime, setCurrentSessionTime = React.useState(0)
    
    -- Use shared claim state from App.lua
    local lastClaimTime = props.sharedFreeOpLastClaimTime or 0
    local claimCount = props.sharedFreeOpClaimCount or 0
    local setLastClaimTime = props.setSharedFreeOpLastClaimTime
    local setClaimCount = props.setSharedFreeOpClaimCount
    
    -- Calculate progress and eligibility on client side with cooldown support
    local timeSinceLastClaim = (tick() - lastClaimTime) / 60 -- Convert to minutes
    local effectivePlaytime = lastClaimTime > 0 and timeSinceLastClaim or currentSessionTime
    local progress = math.min(effectivePlaytime * 60 / requiredTimeSeconds, 1)
    local timeRemaining = math.max(0, requiredTimeSeconds - (effectivePlaytime * 60))
    local timeRequirementMet = progress >= 1
    local canClaim = timeRequirementMet and isInGroup -- Require both time AND group membership
    local isEligible = true
    
    -- Fetch dynamic gamepass price and icon from MarketplaceService + initial group check
    React.useEffect(function()
        local petMagnetConfig = GamepassConfig.GAMEPASSES.PetMagnet
        if petMagnetConfig and petMagnetConfig.id then
            task.spawn(function()
                local success, gamepassInfo = pcall(function()
                    return MarketplaceService:GetProductInfo(petMagnetConfig.id, Enum.InfoType.GamePass)
                end)
                
                if success and gamepassInfo then
                    if gamepassInfo.PriceInRobux then
                        setGamepassPrice(tostring(gamepassInfo.PriceInRobux))
                    end
                    if gamepassInfo.IconImageAssetId and gamepassInfo.IconImageAssetId ~= 0 then
                        setGamepassIcon("rbxassetid://" .. gamepassInfo.IconImageAssetId)
                    end
                end
            end)
        end
        
        -- Perform automatic group check once per session (when UI first loads)
        if not hasCheckedOnJoin.current then
            hasCheckedOnJoin.current = true
            
            task.spawn(function()
                local Players = game:GetService("Players")
                local player = Players.LocalPlayer
                
                local success, result = pcall(function()
                    return player:IsInGroup(config.RequiredGroupId)
                end)
                
                if success then
                    setIsInGroup(result)
                    print("FreeOpItemUI: Initial group check result:", result)
                else
                    warn("FreeOpItemUI: Failed initial group check:", result)
                    setIsInGroup(false)
                end
            end)
        end
    end, {})
    
    -- Client-side session timer, rainbow animation, and group check cooldown
    React.useEffect(function()
        local lastUpdateTime = 0
        local updateTimer = function()
            local currentTime = tick()
            local sessionMinutes = (currentTime - sessionStartTime) / 60
            
            -- Only update state once per second to avoid React loops
            if currentTime - lastUpdateTime >= 1 then
                lastUpdateTime = currentTime
                setCurrentSessionTime(sessionMinutes)
                
                -- Update group check cooldown
                local timeSinceLastCheck = currentTime - lastGroupCheckTime.current
                local cooldownRemaining = math.max(0, config.GroupCheckCooldownSeconds - timeSinceLastCheck)
                setGroupCheckCooldown(cooldownRemaining)
            end
            
            -- Animate rainbow gradient rotation (60 degrees per second)
            local rainbowSpeed = 60 -- degrees per second
            setRainbowRotation(function(current)
                return (current + rainbowSpeed * (1/60)) % 360
            end)
        end
        
        updateTimer()
        local heartbeatConnection = RunService.Heartbeat:Connect(updateTimer)
        
        return function()
            if heartbeatConnection then
                heartbeatConnection:Disconnect()
            end
        end
    end, {})
    
    -- Handle group check button
    local function handleGroupCheck()
        local currentTime = tick()
        
        -- Check cooldown
        if currentTime - lastGroupCheckTime.current < config.GroupCheckCooldownSeconds then
            return -- Still on cooldown
        end
        
        -- Update cooldown time
        lastGroupCheckTime.current = currentTime
        setGroupCheckCooldown(config.GroupCheckCooldownSeconds)
        
        -- Check if player is in group using Roblox's built-in method
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        
        task.spawn(function()
            local success, result = pcall(function()
                return player:IsInGroup(config.RequiredGroupId)
            end)
            
            if success then
                setIsInGroup(result)
                print("FreeOpItemUI: Group check result:", result)
            else
                warn("FreeOpItemUI: Failed to check group membership:", result)
                setIsInGroup(false)
            end
        end)
    end
    
    -- Handle claim button
    local function handleClaim()
        if not canClaim then return end
        
        -- Reset progress for next claim
        setLastClaimTime(tick())
        setClaimCount(function(prev) return prev + 1 end)
        
        -- Fire remote to give reward with session validation
        local claimFreeOpItemRemote = ReplicatedStorage:FindFirstChild("ClaimFreeOpItem")
        if claimFreeOpItemRemote then
            claimFreeOpItemRemote:FireServer(effectivePlaytime)
        end
    end
    
    -- Don't render if not visible
    if not props.visible then
        return nil
    end
    
    local config = FreeOpItemConfig.GetConfig()
    local screenSize = ScreenUtils.getScreenSize()
    local screenWidth = screenSize.X
    local screenHeight = screenSize.Y
    
    -- Calculate responsive panel size (less wide, more responsive height)
    local panelWidth = math.max(ScreenUtils.getProportionalSize(360), screenWidth * 0.28)
    local panelHeight = screenHeight * 0.6 -- 60% of screen height for taller requirements section
    
    -- Format time remaining using client-side calculation
    local timeText = FreeOpItemConfig.FormatTime(timeRemaining)
    local progressPercent = math.floor(progress * 100)
    
    -- Create invisible click-outside-to-close overlay
    return React.createElement("TextButton", {
        Name = "FreeOpItemUIOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 199,
        [React.Event.MouseButton1Click] = props.onClose,
    }, {
        FreeOpItemPanel = React.createElement("Frame", {
            Name = "FreeOpItemPanel",
            Size = UDim2.new(0, panelWidth, 0, 0), -- No fixed height
            AutomaticSize = Enum.AutomaticSize.Y, -- Let it size based on content
            Position = UDim2.new(0.5, 0, 0.5, 0), -- Center both horizontally and vertically  
            AnchorPoint = Vector2.new(0.5, 0.5), -- Center anchor point
            BackgroundTransparency = 1,
            ZIndex = 200,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(12)),
            }),
            
            -- Main panel outline
            PanelOutline = React.createElement("UIStroke", {
                Thickness = ScreenUtils.getProportionalSize(3),
                Color = Color3.fromRGB(0, 0, 0),
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }),
            
            -- White background
            WhiteBackground = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(245, 245, 245),
                BorderSizePixel = 0,
                ZIndex = 198,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(12)),
                }),
            }),
            
            -- Header section
            Header = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(55)),
                BackgroundTransparency = 1,
                ZIndex = 201,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(12))
                }),
                
                -- Header gradient background
                GradientBackground = React.createElement("Frame", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundColor3 = Color3.fromRGB(255, 165, 0), -- Orange theme for magnet
                    BorderSizePixel = 0,
                    ZIndex = 200,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(12))
                    }),
                    Gradient = React.createElement("UIGradient", {
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))
                        }),
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0.3),
                            NumberSequenceKeypoint.new(1, 0.6)
                        }),
                        Rotation = 90,
                    }),
                }),
                
                -- Header container with title and flanking icons
                HeaderContainer = React.createElement("Frame", {
                    Size = UDim2.new(1, -ScreenUtils.getProportionalSize(60), 1, 0),
                    Position = UDim2.new(0.5, 0, 0, 0),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    ZIndex = 202,
                }, {
                    Layout = React.createElement("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = UDim.new(0, ScreenUtils.getProportionalSize(8)), -- Small gap between elements
                        SortOrder = Enum.SortOrder.LayoutOrder
                    }),
                    
                    -- Magnet icon (left of text)
                    HeaderMagnetIcon = React.createElement("ImageLabel", {
                        Size = UDim2.new(0, ScreenUtils.getProportionalSize(35), 0, ScreenUtils.getProportionalSize(35)),
                        BackgroundTransparency = 1,
                        Image = config.MagnetIconId,
                        ScaleType = Enum.ScaleType.Fit,
                        ZIndex = 203,
                        LayoutOrder = 1
                    }),
                    
                    -- Header title (2x bigger)
                    Title = React.createElement("TextLabel", {
                        Size = UDim2.new(0, 0, 1, 0),
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundTransparency = 1,
                        Text = config.ButtonText,
                        TextColor3 = Color3.fromRGB(255, 165, 0),
                        TextSize = ScreenUtils.getTextSize(48), -- 2x bigger
                        TextStrokeTransparency = 0,
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        Font = Enum.Font.FredokaOne,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        ZIndex = 203,
                        LayoutOrder = 2
                    }),
                    
                    -- Pet icon (right of text)
                    HeaderPetIcon = React.createElement("ImageLabel", {
                        Size = UDim2.new(0, ScreenUtils.getProportionalSize(35), 0, ScreenUtils.getProportionalSize(35)),
                        BackgroundTransparency = 1,
                        Image = IconAssets.getIcon(config.PetIconAsset.type, config.PetIconAsset.name),
                        ScaleType = Enum.ScaleType.Fit,
                        ZIndex = 203,
                        LayoutOrder = 3
                    }),
                }),
                
                -- Close button
                CloseButton = React.createElement("ImageButton", {
                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(45), 0, ScreenUtils.getProportionalSize(45)),
                    Position = UDim2.new(1, -ScreenUtils.getProportionalSize(50), 0.5, -ScreenUtils.getProportionalSize(22.5)),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    Image = IconAssets.getIcon("UI", "X_BUTTON"),
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 202,
                    [React.Event.Activated] = props.onClose,
                })
            }),
            
            -- Content area
            ContentArea = React.createElement("Frame", {
                Size = UDim2.new(1, -ScreenUtils.getProportionalSize(30), 0, 0), -- No fixed height
                AutomaticSize = Enum.AutomaticSize.Y, -- Let it size based on content
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(15), 0, ScreenUtils.getProportionalSize(70)),
                BackgroundTransparency = 1,
                ZIndex = 201,
            }, {
                Layout = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Top,
                    Padding = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(20)), -- Better padding between sections
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }),
                
                -- Gamepass icon container (big icon below text)
                GamepassIconContainer = React.createElement("Frame", {
                    Name = "GamepassIconContainer",
                    Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(120)), -- Increased height for proper spacing
                    BackgroundTransparency = 1,
                    ZIndex = 202,
                    LayoutOrder = 1,
                }, {
                    -- Pet Magnet Gamepass icon (big and centered)
                    GamepassIcon = React.createElement("ImageLabel", {
                        Size = UDim2.new(0, ScreenUtils.getProportionalSize(90), 0, ScreenUtils.getProportionalSize(90)), -- Reduced size
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,
                        Image = gamepassIcon, -- Dynamic gamepass icon from MarketplaceService
                        ScaleType = Enum.ScaleType.Fit,
                        ZIndex = 203,
                    }),
                }),
                
                -- Description container with formatted text (with padding)
                DescriptionContainer = React.createElement("Frame", {
                    Name = "DescriptionContainer",
                    Size = UDim2.new(1, -ScreenUtils.getProportionalSize(30), 0, 0), -- No fixed height
                    AutomaticSize = Enum.AutomaticSize.Y, -- Let it size based on content
                    BackgroundTransparency = 1,
                    ZIndex = 202,
                    LayoutOrder = 2,
                }, {
                    -- Main description text with inline elements
                    DescriptionLabel = React.createElement("Frame", {
                        Size = UDim2.new(1, 0, 0, 0), -- No fixed height
                        AutomaticSize = Enum.AutomaticSize.Y, -- Let it size based on content
                        BackgroundTransparency = 1,
                        ZIndex = 203,
                    }, {
                        -- Layout for vertical text arrangement
                        Layout = React.createElement("UIListLayout", {
                            FillDirection = Enum.FillDirection.Vertical,
                            HorizontalAlignment = Enum.HorizontalAlignment.Center,
                            VerticalAlignment = Enum.VerticalAlignment.Center,
                            Padding = UDim.new(0, ScreenUtils.getProportionalSize(2)),
                            SortOrder = Enum.SortOrder.LayoutOrder
                        }),
                        
                        -- Line 1: "Free limited [OP] 24h Pet Magnet potion" (same size as other text)
                        Line1Container = React.createElement("Frame", {
                            Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(28)), -- Reduced height
                            BackgroundTransparency = 1,
                            ZIndex = 204,
                            LayoutOrder = 1
                        }, {
                            Layout = React.createElement("UIListLayout", {
                                FillDirection = Enum.FillDirection.Horizontal,
                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                VerticalAlignment = Enum.VerticalAlignment.Center,
                                Padding = UDim.new(0, ScreenUtils.getProportionalSize(3)),
                                SortOrder = Enum.SortOrder.LayoutOrder
                            }),
                            
                            Text1 = React.createElement("TextLabel", {
                                Size = UDim2.new(0, 0, 1, 0),
                                AutomaticSize = Enum.AutomaticSize.X,
                                BackgroundTransparency = 1,
                                Text = "Free limited [",
                                TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                                TextSize = ScreenUtils.getTextSize(32), -- Same size as other text
                                Font = Enum.Font.FredokaOne, -- Same font as button
                                TextStrokeTransparency = 0, -- Full black outline
                                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                                ZIndex = 205,
                                LayoutOrder = 1
                            }),
                            
                            OPText = React.createElement("TextLabel", {
                                Size = UDim2.new(0, 0, 1, 0),
                                AutomaticSize = Enum.AutomaticSize.X,
                                BackgroundTransparency = 1,
                                Text = "OP",
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                TextSize = ScreenUtils.getTextSize(32), -- Same size as other text
                                Font = Enum.Font.FredokaOne, -- Same font as button
                                TextStrokeTransparency = 0,
                                TextStrokeColor3 = Color3.fromRGB(0, 0, 0), -- Black outline
                                ZIndex = 205,
                                LayoutOrder = 2
                            }, {
                                -- Animated rainbow gradient
                                RainbowGradient = React.createElement("UIGradient", {
                                    Color = ColorSequence.new({
                                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                                        ColorSequenceKeypoint.new(0.14, Color3.fromRGB(255, 127, 0)),
                                        ColorSequenceKeypoint.new(0.28, Color3.fromRGB(255, 255, 0)),
                                        ColorSequenceKeypoint.new(0.42, Color3.fromRGB(0, 255, 0)),
                                        ColorSequenceKeypoint.new(0.57, Color3.fromRGB(0, 0, 255)),
                                        ColorSequenceKeypoint.new(0.71, Color3.fromRGB(75, 0, 130)),
                                        ColorSequenceKeypoint.new(0.85, Color3.fromRGB(148, 0, 211)),
                                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
                                    }),
                                    Rotation = rainbowRotation
                                })
                            }),
                            
                            Text2 = React.createElement("TextLabel", {
                                Size = UDim2.new(0, 0, 1, 0),
                                AutomaticSize = Enum.AutomaticSize.X,
                                BackgroundTransparency = 1,
                                Text = "] 24h Pet Magnet potion",
                                TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                                TextSize = ScreenUtils.getTextSize(32), -- Same size as other text
                                Font = Enum.Font.FredokaOne, -- Same font as button
                                TextStrokeTransparency = 0, -- Full black outline
                                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                                ZIndex = 205,
                                LayoutOrder = 3
                            })
                        }),
                        
                        -- Line 2: "Worth {price} Robux!" with green value and icon (same text size)
                        Line2Container = React.createElement("Frame", {
                            Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(28)), -- Reduced height
                            BackgroundTransparency = 1,
                            ZIndex = 204,
                            LayoutOrder = 2
                        }, {
                            Layout = React.createElement("UIListLayout", {
                                FillDirection = Enum.FillDirection.Horizontal,
                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                VerticalAlignment = Enum.VerticalAlignment.Center,
                                Padding = UDim.new(0, ScreenUtils.getProportionalSize(3)),
                                SortOrder = Enum.SortOrder.LayoutOrder
                            }),
                            
                            WorthText = React.createElement("TextLabel", {
                                Size = UDim2.new(0, 0, 1, 0),
                                AutomaticSize = Enum.AutomaticSize.X,
                                BackgroundTransparency = 1,
                                Text = "Worth ",
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                TextSize = ScreenUtils.getTextSize(32), -- 25% smaller than Free limited text (42 * 0.75 = 32)
                                Font = Enum.Font.FredokaOne,
                                TextStrokeTransparency = 0,
                                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                                ZIndex = 205,
                                LayoutOrder = 1
                            }),
                            
                            PriceText = React.createElement("TextLabel", {
                                Size = UDim2.new(0, 0, 1, 0),
                                AutomaticSize = Enum.AutomaticSize.X,
                                BackgroundTransparency = 1,
                                Text = gamepassPrice, -- Dynamic price from MarketplaceService
                                TextColor3 = Color3.fromRGB(85, 255, 85), -- Green like OPPetButton
                                TextSize = ScreenUtils.getTextSize(32), -- 25% smaller than Free limited text
                                Font = Enum.Font.FredokaOne,
                                TextStrokeTransparency = 0,
                                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                                ZIndex = 205,
                                LayoutOrder = 2
                            }),
                            
                            RobuxIcon = React.createElement("ImageLabel", {
                                Size = UDim2.new(0, ScreenUtils.getProportionalSize(24), 0, ScreenUtils.getProportionalSize(24)),
                                BackgroundTransparency = 1,
                                Image = "rbxasset://textures/ui/common/robux.png", -- Correct Robux icon path
                                ImageColor3 = Color3.fromRGB(85, 255, 85), -- Green like the price
                                ScaleType = Enum.ScaleType.Fit,
                                ZIndex = 205,
                                LayoutOrder = 3
                            }),
                            
                            ExclamationText = React.createElement("TextLabel", {
                                Size = UDim2.new(0, 0, 1, 0),
                                AutomaticSize = Enum.AutomaticSize.X,
                                BackgroundTransparency = 1,
                                Text = "!",
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                TextSize = ScreenUtils.getTextSize(32), -- 25% smaller than Free limited text
                                Font = Enum.Font.FredokaOne,
                                TextStrokeTransparency = 0,
                                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                                ZIndex = 205,
                                LayoutOrder = 4
                            })
                        }),
                        
                        -- Line 3: Requirements list (structured format)
                        RequirementsContainer = React.createElement("Frame", {
                            Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(120)), -- Back to proper height for multi-line requirements
                            BackgroundTransparency = 1,
                            ZIndex = 204,
                            LayoutOrder = 3
                        }, {
                            Layout = React.createElement("UIListLayout", {
                                FillDirection = Enum.FillDirection.Vertical,
                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                VerticalAlignment = Enum.VerticalAlignment.Top,
                                Padding = UDim.new(0, ScreenUtils.getProportionalSize(2)),
                                SortOrder = Enum.SortOrder.LayoutOrder
                            }),
                            
                            -- Requirements header
                            RequirementsHeader = React.createElement("TextLabel", {
                                Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(35)),
                                BackgroundTransparency = 1,
                                Text = "Requirements:",
                                TextColor3 = Color3.fromRGB(255, 215, 0), -- Gold color for header
                                TextSize = ScreenUtils.getTextSize(34), -- Slightly bigger for header
                                Font = Enum.Font.FredokaOne,
                                TextStrokeTransparency = 0,
                                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                                TextXAlignment = Enum.TextXAlignment.Center,
                                ZIndex = 205,
                                LayoutOrder = 1
                            }),
                            
                            -- Requirement 1: Play time (with tick when completed)
                            Requirement1 = React.createElement("TextLabel", {
                                Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(28)),
                                BackgroundTransparency = 1,
                                Text = (timeRequirementMet and "✓ " or "• ") .. "Play for " .. config.RequiredPlaytimeMinutes .. " minute" .. (config.RequiredPlaytimeMinutes == 1 and "" or "s"),
                                TextColor3 = timeRequirementMet and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 255, 255),
                                TextSize = ScreenUtils.getTextSize(30),
                                Font = Enum.Font.FredokaOne,
                                TextStrokeTransparency = 0,
                                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                                TextXAlignment = Enum.TextXAlignment.Center,
                                ZIndex = 205,
                                LayoutOrder = 2
                            }),
                            
                            -- Requirement 2: Like the game (always shows heart)
                            Requirement2 = React.createElement("TextLabel", {
                                Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(28)),
                                BackgroundTransparency = 1,
                                Text = "❤️ Like the game",
                                TextColor3 = Color3.fromRGB(255, 100, 100), -- Pinkish for heart
                                TextSize = ScreenUtils.getTextSize(30),
                                Font = Enum.Font.FredokaOne,
                                TextStrokeTransparency = 0,
                                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                                TextXAlignment = Enum.TextXAlignment.Center,
                                ZIndex = 205,
                                LayoutOrder = 3
                            }),
                            
                            -- Requirement 3: Join group (with tick when completed)
                            Requirement3 = React.createElement("TextLabel", {
                                Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(28)),
                                BackgroundTransparency = 1,
                                Text = (isInGroup and "✓ " or "• ") .. "Join our group!",
                                TextColor3 = isInGroup and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 255, 255),
                                TextSize = ScreenUtils.getTextSize(30),
                                Font = Enum.Font.FredokaOne,
                                TextStrokeTransparency = 0,
                                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                                TextXAlignment = Enum.TextXAlignment.Center,
                                ZIndex = 205,
                                LayoutOrder = 4
                            })
                        })
                    })
                }),
                
                -- Progress section (with padding)
                ProgressSection = React.createElement("Frame", {
                    Name = "ProgressSection",
                    Size = UDim2.new(1, -ScreenUtils.getProportionalSize(30), 0, ScreenUtils.getProportionalSize(60)), -- Reduced height
                    BackgroundTransparency = 1,
                    ZIndex = 202,
                    LayoutOrder = 4,
                }, {
                    -- Progress label (bigger with white outline)
                    ProgressLabel = React.createElement("TextLabel", {
                        Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(25)), -- Reduced height
                        Position = UDim2.new(0, 0, 0, 0),
                        BackgroundTransparency = 1,
                        Text = canClaim and "All requirements met - Ready to claim!" or (
                            "Time Progress: " .. progressPercent .. "% (" .. timeText .. " remaining)"
                        ),
                        TextColor3 = canClaim and Color3.fromRGB(50, 205, 50) or Color3.fromRGB(50, 50, 50),
                        TextSize = ScreenUtils.getTextSize(32), -- 25% smaller than Free limited text
                        Font = Enum.Font.FredokaOne,
                        TextStrokeTransparency = 0,
                        TextStrokeColor3 = Color3.fromRGB(255, 255, 255),
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ZIndex = 203,
                    }),
                    
                    -- Progress bar background
                    ProgressBarBackground = React.createElement("Frame", {
                        Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(20)),
                        Position = UDim2.new(0, 0, 0, ScreenUtils.getProportionalSize(28)), -- Adjusted for smaller text
                        BackgroundColor3 = Color3.fromRGB(200, 200, 200),
                        BorderSizePixel = 0,
                        ZIndex = 203,
                    }, {
                        Corner = React.createElement("UICorner", {
                            CornerRadius = ScreenUtils.udim(0, 10),
                        }),
                        
                        -- Progress bar fill
                        ProgressBarFill = React.createElement("Frame", {
                            Size = UDim2.new(progress, 0, 1, 0),
                            Position = UDim2.new(0, 0, 0, 0),
                            BackgroundColor3 = canClaim and Color3.fromRGB(50, 205, 50) or Color3.fromRGB(255, 165, 0),
                            BorderSizePixel = 0,
                            ZIndex = 204,
                        }, {
                            Corner = React.createElement("UICorner", {
                                CornerRadius = ScreenUtils.udim(0, 10),
                            }),
                        }),
                    }),
                }),
                
                -- Group check button (blue)
                GroupCheckButton = React.createElement("TextButton", {
                    Name = "GroupCheckButton",
                    Size = UDim2.new(0.8, 0, 0, ScreenUtils.getProportionalSize(50)), -- Slightly smaller than claim button
                    BackgroundColor3 = groupCheckCooldown > 0 and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(50, 120, 200), -- Blue or grey if on cooldown
                    BorderSizePixel = 0,
                    Text = groupCheckCooldown > 0 and ("Cooldown: " .. math.ceil(groupCheckCooldown) .. "s") or (isInGroup and "✓ In Group!" or "I've joined the group"),
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.getTextSize(32),
                    Font = Enum.Font.FredokaOne,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    Active = groupCheckCooldown <= 0, -- Only active when not on cooldown
                    ZIndex = 202,
                    LayoutOrder = 5,
                    [React.Event.Activated] = handleGroupCheck,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, 8)
                    }),
                    
                    Stroke = React.createElement("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = 2,
                        Transparency = 0
                    })
                }),
                
                -- Claim button (bigger text)
                ClaimButton = React.createElement("TextButton", {
                    Name = "ClaimButton",
                    Size = UDim2.new(0.8, 0, 0, ScreenUtils.getProportionalSize(55)), -- Taller for bigger text
                    BackgroundColor3 = canClaim and Color3.fromRGB(50, 205, 50) or Color3.fromRGB(150, 150, 150),
                    BorderSizePixel = 0,
                    Text = canClaim and "CLAIM REWARD!" or "NOT READY",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.getTextSize(36), -- Keep button text slightly bigger
                    Font = Enum.Font.FredokaOne,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    Active = canClaim,
                    ZIndex = 202,
                    LayoutOrder = 6, -- After group check button
                    [React.Event.Activated] = handleClaim,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, 8)
                    }),
                    
                    Stroke = React.createElement("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = 2,
                        Transparency = 0
                    })
                }),
                
                -- Bottom padding spacer
                BottomPadding = React.createElement("Frame", {
                    Name = "BottomPadding",
                    Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(25)), -- 25px bottom padding
                    BackgroundTransparency = 1,
                    ZIndex = 202,
                    LayoutOrder = 7, -- After claim button
                })
            })
        })
    })
end

return FreeOpItemUI