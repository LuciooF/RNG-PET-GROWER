-- Rewards Panel Component
-- Beautiful animated popup for showing rewards to players
-- Matches the game's UI design with proper colors and animations

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local TweenService = game:GetService("TweenService")
local e = React.createElement

local ScreenUtils = require(game:GetService("ReplicatedStorage").utils.ScreenUtils)
local assets = require(game:GetService("ReplicatedStorage").assets)
local NumberFormatter = require(game:GetService("ReplicatedStorage").utils.NumberFormatter)

local function RewardsPanel(props)
    local visible, setVisible = React.useState(false)
    local rewardData, setRewardData = React.useState(nil)
    local timeRemaining, setTimeRemaining = React.useState(5)
    
    -- Screen size for responsive design
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local scale = ScreenUtils.getProportionalScale(screenSize)
    
    -- Animation refs
    local panelRef = React.useRef()
    local iconRef = React.useRef()
    local timerRef = React.useRef() -- Ref to store timer for cleanup
    local hideRewardRef = React.useRef() -- Ref to store hideReward function for timer access
    
    -- Proportional sizing - make wider to accommodate icon and text properly
    local panelWidth = ScreenUtils.getProportionalSize(screenSize, 450)
    local panelHeight = ScreenUtils.getProportionalSize(screenSize, 240)
    local iconSize = ScreenUtils.getProportionalSize(screenSize, 80)
    
    -- Text sizes
    local titleTextSize = ScreenUtils.getProportionalTextSize(screenSize, 28)
    local amountTextSize = ScreenUtils.getProportionalTextSize(screenSize, 24)
    local descriptionTextSize = ScreenUtils.getProportionalTextSize(screenSize, 18)
    
    -- Hide reward function (defined first so it's available for timer)
    local hideReward = React.useCallback(function()
        -- Stop timer if it's running
        timerRef.current = nil
        
        if panelRef.current then
            local slideOut = TweenService:Create(panelRef.current,
                TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In),
                {Position = UDim2.new(0.5, -panelWidth/2, 1, 50)}
            )
            
            slideOut:Play()
            slideOut.Completed:Connect(function()
                setVisible(false)
                setRewardData(nil)
                setTimeRemaining(5) -- Reset for next time
                
                -- Notify RewardsService that we're done
                local RewardsService = require(script.Parent.Parent.RewardsService)
                RewardsService.onRewardFinished()
            end)
        end
    end, {panelWidth})
    
    -- Store hideReward function in ref for timer access
    hideRewardRef.current = hideReward

    -- Show reward function
    local showReward = React.useCallback(function(reward)
        setRewardData(reward)
        setVisible(true)
        setTimeRemaining(5) -- Reset timer
        
        -- Start countdown timer with better control
        local timerActive = true
        timerRef.current = timerActive
        
        spawn(function()
            for i = 5, 1, -1 do
                if not timerRef.current then 
                    return 
                end
                setTimeRemaining(i)
                wait(1)
            end
            -- Check one more time before auto-closing
            if timerRef.current then
                if hideRewardRef.current then
                    hideRewardRef.current()
                end
            end
        end)
        
        -- Start animations after next frame
        spawn(function()
            wait(0.1)
            if panelRef.current and iconRef.current then
                -- Panel slide in animation
                panelRef.current.Position = UDim2.new(0.5, -panelWidth/2, 1, 50) -- Start below screen
                
                local slideIn = TweenService:Create(panelRef.current,
                    TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                    {Position = UDim2.new(0.5, -panelWidth/2, 0.5, -panelHeight/2)}
                )
                
                -- Icon bounce animation
                local iconBounce = TweenService:Create(iconRef.current,
                    TweenInfo.new(0.8, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
                    {Size = UDim2.new(0, iconSize * 1.1, 0, iconSize * 1.1)}
                )
                
                slideIn:Play()
                iconBounce:Play()
            end
        end)
    end, {panelWidth, panelHeight, iconSize, hideReward})
    
    -- Set up reward event listener
    React.useEffect(function()
        local RewardsService = require(script.Parent.Parent.RewardsService)
        
        -- Create event for communication
        local rewardShowEvent = Instance.new("BindableEvent")
        RewardsService.setRewardShowEvent(rewardShowEvent)
        
        local connection = rewardShowEvent.Event:Connect(showReward)
        
        return function()
            connection:Disconnect()
            rewardShowEvent:Destroy()
        end
    end, {showReward})
    
    if not visible or not rewardData then
        return nil
    end
    
    -- Get reward-specific data
    local rewardIcon = assets[rewardData.iconAsset] or ""
    local rewardColor = rewardData.color or Color3.fromRGB(100, 100, 100)
    
    -- Format amount text
    local amountText = ""
    if rewardData.type == "money" and rewardData.amount then
        amountText = "+$" .. NumberFormatter.format(rewardData.amount)
    elseif rewardData.amount then
        amountText = "+" .. tostring(rewardData.amount)
    end
    
    -- Daily rewards icon (using available icon from assets)
    local dailyRewardsIcon = assets["vector-icon-pack-2/Currency/Gem/Gem Blue Outline 256.png"] or ""
    
    return e("ScreenGui", {
        Name = "RewardsUI",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    }, {
        -- Main panel
        RewardPanel = e("Frame", {
            Name = "RewardPanel",
            Size = UDim2.new(0, panelWidth, 0, panelHeight),
            Position = UDim2.new(0.5, -panelWidth/2, 1, 50), -- Start off screen
            BackgroundColor3 = Color3.fromRGB(230, 240, 255), -- Nice blue palette background
            BorderSizePixel = 0,
            ZIndex = 100,
            ref = panelRef
        }, {
            -- Corner radius
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 20)
            }),
            
            -- Green outline border
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(85, 170, 85), -- Green outline
                Thickness = 4,
                Transparency = 0
            }),
            
            -- Floating Header (top left like other UIs)
            FloatingHeader = e("Frame", {
                Name = "FloatingHeader",
                Size = UDim2.new(0, 140, 0, 35),
                Position = UDim2.new(0, -10, 0, -20),
                BackgroundColor3 = Color3.fromRGB(85, 170, 85), -- Green background
                BorderSizePixel = 0,
                ZIndex = 102
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 12)
                }),
                Stroke = e("UIStroke", {
                    Color = Color3.fromRGB(255, 255, 255),
                    Thickness = 3,
                    Transparency = 0.2
                }),
                HeaderIcon = e("ImageLabel", {
                    Name = "HeaderIcon",
                    Size = UDim2.new(0, 24, 0, 24),
                    Position = UDim2.new(0, 8, 0.5, -12),
                    Image = dailyRewardsIcon,
                    BackgroundTransparency = 1,
                    ZIndex = 103
                }),
                HeaderText = e("TextLabel", {
                    Size = UDim2.new(1, -40, 1, 0),
                    Position = UDim2.new(0, 35, 0, 0),
                    Text = "REWARD!",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.getProportionalTextSize(screenSize, 16),
                    TextWrapped = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    ZIndex = 103
                }, {
                    TextStroke = e("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = 2,
                        Transparency = 0.5
                    })
                })
            }),
            
            -- Icon container
            IconContainer = e("Frame", {
                Name = "IconContainer",
                Size = UDim2.new(0, iconSize + 20, 0, iconSize + 20),
                Position = UDim2.new(0, 20, 0.5, -(iconSize + 20)/2),
                BackgroundColor3 = rewardColor,
                BorderSizePixel = 0,
                ZIndex = 102
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0.5, 0) -- Circular
                }),
                Stroke = e("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = 2,
                    Transparency = 0
                }),
                
                -- Reward icon
                Icon = e("ImageLabel", {
                    Name = "RewardIcon",
                    Size = UDim2.new(0, iconSize, 0, iconSize),
                    Position = UDim2.new(0.5, -iconSize/2, 0.5, -iconSize/2),
                    Image = rewardIcon,
                    BackgroundTransparency = 1,
                    ZIndex = 103,
                    ref = iconRef
                })
            }),
            
            -- Text container (positioned to not overlap with icon)
            TextContainer = e("Frame", {
                Name = "TextContainer",
                Size = UDim2.new(1, -(iconSize + 80), 1, -60), -- More margin to prevent overlap
                Position = UDim2.new(0, iconSize + 50, 0, 30), -- Move down and right more
                BackgroundTransparency = 1,
                ZIndex = 102
            }, {
                -- Title
                Title = e("TextLabel", {
                    Name = "Title",
                    Size = UDim2.new(1, 0, 0, 35),
                    Position = UDim2.new(0, 0, 0, 0),
                    Text = rewardData.title or "Reward!",
                    TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                    TextSize = titleTextSize,
                    TextWrapped = false,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    ZIndex = 103
                }, {
                    TextSizeConstraint = e("UITextSizeConstraint", {
                        MaxTextSize = titleTextSize,
                        MinTextSize = math.max(16, titleTextSize * 0.7)
                    }),
                    -- Black outline for text
                    TextStroke = e("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0), -- Black outline
                        Thickness = 1,
                        Transparency = 0
                    })
                }),
                
                -- Amount (if applicable)
                Amount = amountText ~= "" and e("TextLabel", {
                    Name = "Amount",
                    Size = UDim2.new(1, 0, 0, 30),
                    Position = UDim2.new(0, 0, 0, 35),
                    Text = amountText,
                    TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                    TextSize = amountTextSize,
                    TextWrapped = false,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    ZIndex = 103
                }, {
                    TextSizeConstraint = e("UITextSizeConstraint", {
                        MaxTextSize = amountTextSize,
                        MinTextSize = math.max(14, amountTextSize * 0.7)
                    }),
                    -- Black outline for text
                    TextStroke = e("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0), -- Black outline
                        Thickness = 1,
                        Transparency = 0
                    })
                }) or nil,
                
                -- Description
                Description = e("TextLabel", {
                    Name = "Description",
                    Size = UDim2.new(1, 0, 1, -65),
                    Position = UDim2.new(0, 0, 0, 65),
                    Text = rewardData.description or "",
                    TextColor3 = Color3.fromRGB(0, 0, 0), -- Normal black text
                    TextSize = descriptionTextSize,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    ZIndex = 103
                }, {
                    TextSizeConstraint = e("UITextSizeConstraint", {
                        MaxTextSize = descriptionTextSize,
                        MinTextSize = math.max(12, descriptionTextSize * 0.7)
                    })
                    -- No outline for description text - just normal black text
                })
            }),
            
            -- OK Button with countdown timer
            OkayButton = e("TextButton", {
                Name = "OkayButton",
                Size = UDim2.new(0, 120, 0, 40),
                Position = UDim2.new(0.5, -60, 1, -50),
                Text = "Okay! (" .. timeRemaining .. "s)",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = ScreenUtils.getProportionalTextSize(screenSize, 18),
                BackgroundColor3 = Color3.fromRGB(85, 170, 85), -- Green background
                BorderSizePixel = 0,
                Font = Enum.Font.GothamBold,
                ZIndex = 104,
                [React.Event.Activated] = hideReward,
                [React.Event.MouseEnter] = function(rbx)
                    rbx.BackgroundColor3 = Color3.fromRGB(100, 200, 100) -- Lighter green on hover
                end,
                [React.Event.MouseLeave] = function(rbx)
                    rbx.BackgroundColor3 = Color3.fromRGB(85, 170, 85) -- Back to normal green
                end
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 12)
                }),
                Stroke = e("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0), -- Black border instead of white
                    Thickness = 2,
                    Transparency = 0
                }),
                TextStroke = e("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0), -- Black outline for button text
                    Thickness = 2,
                    Transparency = 0
                })
            })
        })
    })
end

return RewardsPanel