local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages.react)
local e = React.createElement

-- Assets - TODO: Upload to Roblox and replace with proper asset IDs
local assets = {}
-- For now, we'll use TextLabel with emojis instead of ImageLabel
-- assets["Currency/Cash/Cash Outline 256.png"] = "rbxassetid://YOUR_CASH_ASSET_ID"
-- assets["General/Rebirth/Rebirth Outline 256.png"] = "rbxassetid://YOUR_REBIRTH_ASSET_ID"

-- Simple NumberFormatter
local function formatNumber(number)
    if not number or type(number) ~= "number" then
        return "0"
    end
    
    if number < 1000 then
        return tostring(math.floor(number))
    elseif number < 1000000 then
        return string.format("%.1fK", number / 1000)
    elseif number < 1000000000 then
        return string.format("%.1fM", number / 1000000)
    elseif number < 1000000000000 then
        return string.format("%.1fB", number / 1000000000)
    else
        return string.format("%.1fT", number / 1000000000000)
    end
end

-- Simple ScreenUtils
local function getProportionalScale(currentSize, referenceSize, minScale, maxScale)
    local scaleX = currentSize.X / referenceSize.X
    local scaleY = currentSize.Y / referenceSize.Y
    local scale = math.min(scaleX, scaleY)
    
    return math.clamp(scale, minScale or 0.5, maxScale or 2.0)
end

local function getProportionalTextSize(currentSize, baseTextSize)
    local scale = getProportionalScale(currentSize, Vector2.new(1920, 1080), 0.7, 1.5)
    return math.floor(baseTextSize * scale)
end

local function TopStats(props)
    local playerData = props.playerData or {}
    
    local money = playerData.money or 0
    local rebirths = playerData.rebirths or 0
    local diamonds = playerData.diamonds or 0
    
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local scale = getProportionalScale(screenSize, Vector2.new(1920, 1080), 0.7, 1.5)
    
    local titleTextSize = getProportionalTextSize(screenSize, 24)
    local popupTextSize = getProportionalTextSize(screenSize, 18)
    
    local moneyText = formatNumber(money)
    local rebirthText = tostring(rebirths)
    local diamondText = formatNumber(diamonds)
    
    local baseWidth = 120
    local moneyWidth = math.max(baseWidth, 80 + (string.len(moneyText) * 10)) * scale
    local rebirthWidth = math.max(baseWidth, 80 + (string.len(rebirthText) * 10)) * scale
    local diamondWidth = math.max(baseWidth, 80 + (string.len(diamondText) * 10)) * scale
    
    local containerHeight = 45 * scale
    local containerSpacing = 25 * scale
    local iconSize = 55 * scale
    
    local totalWidth = moneyWidth + rebirthWidth + diamondWidth + (containerSpacing * 2)
    
    -- Get GUI inset for proper positioning
    local guiInset = GuiService:GetGuiInset()
    
    local cashIconRef = React.useRef()
    local rebirthIconRef = React.useRef()
    local diamondIconRef = React.useRef()
    local moneyPopupRef = React.useRef()
    local rebirthPopupRef = React.useRef()
    local diamondPopupRef = React.useRef()
    
    local prevMoney = React.useRef(money)
    local prevRebirths = React.useRef(rebirths)
    local prevDiamonds = React.useRef(diamonds)
    
    local moneyAnimationId = React.useRef(0)
    local rebirthAnimationId = React.useRef(0)
    local diamondAnimationId = React.useRef(0)
    
    local moneyPopupText, setMoneyPopupText = React.useState("")
    local rebirthPopupText, setRebirthPopupText = React.useState("")
    local diamondPopupText, setDiamondPopupText = React.useState("")
    local showMoneyPopup, setShowMoneyPopup = React.useState(false)
    local showRebirthPopup, setShowRebirthPopup = React.useState(false)
    local showDiamondPopup, setShowDiamondPopup = React.useState(false)
    
    React.useEffect(function()
        if not cashIconRef.current then return end
        
        local currentMoney = money
        local previousMoney = prevMoney.current
        
        if currentMoney > previousMoney then
            local difference = currentMoney - previousMoney
            
            local bounceUp = TweenService:Create(cashIconRef.current, 
                TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
                {Position = UDim2.new(0, -iconSize * 0.3, 0.5, -iconSize/2 - 8)}
            )
            
            local bounceDown = TweenService:Create(cashIconRef.current, 
                TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
                {Position = UDim2.new(0, -iconSize * 0.3, 0.5, -iconSize/2)}
            )
            
            bounceUp:Play()
            bounceUp.Completed:Connect(function()
                bounceDown:Play()
            end)
            
            moneyAnimationId.current = moneyAnimationId.current + 1
            local currentAnimationId = moneyAnimationId.current
            
            setMoneyPopupText("+$" .. formatNumber(difference))
            setShowMoneyPopup(true)
            
            task.spawn(function()
                task.wait(0.1)
                
                if moneyPopupRef.current and moneyAnimationId.current == currentAnimationId then
                    moneyPopupRef.current.Position = UDim2.new(0, moneyWidth/2 - 100, 1, 10)
                    moneyPopupRef.current.TextTransparency = 0
                    
                    local floatTween = TweenService:Create(moneyPopupRef.current,
                        TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {
                            Position = UDim2.new(0, moneyWidth/2 - 100, 1, -30),
                            TextTransparency = 1
                        }
                    )
                    
                    floatTween:Play()
                    floatTween.Completed:Connect(function()
                        if moneyAnimationId.current == currentAnimationId then
                            setShowMoneyPopup(false)
                        end
                        floatTween:Destroy()
                    end)
                end
            end)
        end
        
        prevMoney.current = currentMoney
    end, {money})
    
    React.useEffect(function()
        if not rebirthIconRef.current then return end
        
        local currentRebirths = rebirths
        local previousRebirths = prevRebirths.current
        
        if currentRebirths ~= previousRebirths then
            local difference = currentRebirths - previousRebirths
            
            local spinTween = TweenService:Create(rebirthIconRef.current, 
                TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
                {Rotation = 360}
            )
            
            spinTween:Play()
            spinTween.Completed:Connect(function()
                rebirthIconRef.current.Rotation = 0
            end)
            
            if difference > 0 then
                rebirthAnimationId.current = rebirthAnimationId.current + 1
                local currentAnimationId = rebirthAnimationId.current
                
                setRebirthPopupText("+" .. difference .. " Rebirth" .. (difference > 1 and "s" or ""))
                setShowRebirthPopup(true)
                
                local connection
                connection = RunService.Heartbeat:Connect(function()
                    connection:Disconnect()
                    
                    if rebirthPopupRef.current and rebirthAnimationId.current == currentAnimationId then
                        local rebirthContainerX = moneyWidth + containerSpacing
                        rebirthPopupRef.current.Position = UDim2.new(0, rebirthContainerX + rebirthWidth/2 - 100, 1, 10)
                        rebirthPopupRef.current.TextTransparency = 0
                        
                        local floatTween = TweenService:Create(rebirthPopupRef.current,
                            TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                            {
                                Position = UDim2.new(0, rebirthContainerX + rebirthWidth/2 - 100, 1, -30),
                                TextTransparency = 1
                            }
                        )
                        
                        floatTween:Play()
                        floatTween.Completed:Connect(function()
                            if rebirthAnimationId.current == currentAnimationId then
                                setShowRebirthPopup(false)
                            end
                            floatTween:Destroy()
                        end)
                    end
                end)
            end
        end
        
        prevRebirths.current = currentRebirths
    end, {rebirths})
    
    React.useEffect(function()
        if not diamondIconRef.current then return end
        
        local currentDiamonds = diamonds
        local previousDiamonds = prevDiamonds.current
        
        if currentDiamonds > previousDiamonds then
            local difference = currentDiamonds - previousDiamonds
            
            local sparkleRotation = TweenService:Create(diamondIconRef.current, 
                TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
                {Rotation = 180}
            )
            
            local sparkleBack = TweenService:Create(diamondIconRef.current, 
                TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
                {Rotation = 0}
            )
            
            sparkleRotation:Play()
            sparkleRotation.Completed:Connect(function()
                sparkleBack:Play()
            end)
            
            diamondAnimationId.current = diamondAnimationId.current + 1
            local currentAnimationId = diamondAnimationId.current
            
            setDiamondPopupText("+" .. formatNumber(difference) .. " 💎")
            setShowDiamondPopup(true)
            
            task.spawn(function()
                task.wait(0.1)
                
                if diamondPopupRef.current and diamondAnimationId.current == currentAnimationId then
                    local diamondContainerX = moneyWidth + rebirthWidth + (containerSpacing * 2)
                    diamondPopupRef.current.Position = UDim2.new(0, diamondContainerX + diamondWidth/2 - 100, 1, 10)
                    diamondPopupRef.current.TextTransparency = 0
                    
                    local floatTween = TweenService:Create(diamondPopupRef.current,
                        TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {
                            Position = UDim2.new(0, diamondContainerX + diamondWidth/2 - 100, 1, -30),
                            TextTransparency = 1
                        }
                    )
                    
                    floatTween:Play()
                    floatTween.Completed:Connect(function()
                        if diamondAnimationId.current == currentAnimationId then
                            setShowDiamondPopup(false)
                        end
                        floatTween:Destroy()
                    end)
                end
            end)
        end
        
        prevDiamonds.current = currentDiamonds
    end, {diamonds})
    
    return e("Frame", {
        Name = "TopStatsFrame",
        Size = UDim2.new(0, totalWidth, 0, containerHeight),
        Position = UDim2.new(0.5, -totalWidth/2, 0, 5),
        BackgroundTransparency = 1,
        ZIndex = 10,
        ClipsDescendants = false
    }, {
        MoneyContainer = e("Frame", {
            Name = "MoneyContainer",
            Size = UDim2.new(0, moneyWidth, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            ZIndex = 11,
            ClipsDescendants = false
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 16)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 2,
                Transparency = 0
            }),
            
            CashIcon = e("TextLabel", {
                Name = "CashIcon",
                Size = UDim2.new(0, iconSize, 0, iconSize),
                Position = UDim2.new(0, -iconSize * 0.3, 0.5, -iconSize/2),
                Text = "💰",
                TextScaled = true,
                BackgroundTransparency = 1,
                ZIndex = 12,
                ref = cashIconRef
            }),
            
            MoneyText = e("TextLabel", {
                Name = "MoneyText",
                Size = UDim2.new(1, -(iconSize * 0.7 + 5), 1, 0),
                Position = UDim2.new(0, iconSize * 0.7 + 5, 0, 0),
                Text = moneyText,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = titleTextSize,
                TextWrapped = false,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 12
            }, {
                TextStroke = e("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = 2,
                    Transparency = 0.3
                })
            }),
            
            MoneyPopup = showMoneyPopup and e("TextLabel", {
                Name = "MoneyPopup",
                Size = UDim2.new(0, 200, 0, 30),
                Position = UDim2.new(0, moneyWidth/2 - 100, 1, 10),
                Text = moneyPopupText,
                TextColor3 = Color3.fromRGB(0, 200, 0),
                TextSize = popupTextSize,
                TextWrapped = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 15,
                TextStrokeTransparency = 0.5,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                ref = moneyPopupRef
            }) or nil
        }),
        
        RebirthContainer = e("Frame", {
            Name = "RebirthContainer",
            Size = UDim2.new(0, rebirthWidth, 1, 0),
            Position = UDim2.new(0, moneyWidth + containerSpacing, 0, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            ZIndex = 11,
            ClipsDescendants = false
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 16)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 2,
                Transparency = 0
            }),
            
            RebirthIcon = e("TextLabel", {
                Name = "RebirthIcon",
                Size = UDim2.new(0, iconSize, 0, iconSize),
                Position = UDim2.new(0, -iconSize * 0.3, 0.5, -iconSize/2),
                Text = "🔄",
                TextScaled = true,
                BackgroundTransparency = 1,
                ZIndex = 12,
                ref = rebirthIconRef
            }),
            
            RebirthText = e("TextLabel", {
                Name = "RebirthText",
                Size = UDim2.new(1, -(iconSize * 0.7 + 5), 1, 0),
                Position = UDim2.new(0, iconSize * 0.7 + 5, 0, 0),
                Text = rebirthText,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = titleTextSize,
                TextWrapped = false,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 12
            }, {
                TextStroke = e("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = 2,
                    Transparency = 0.3
                })
            })
        }),
        
        DiamondContainer = e("Frame", {
            Name = "DiamondContainer",
            Size = UDim2.new(0, diamondWidth, 1, 0),
            Position = UDim2.new(0, moneyWidth + rebirthWidth + (containerSpacing * 2), 0, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            ZIndex = 11,
            ClipsDescendants = false
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 16)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 2,
                Transparency = 0
            }),
            
            DiamondIcon = e("TextLabel", {
                Name = "DiamondIcon",
                Size = UDim2.new(0, iconSize, 0, iconSize),
                Position = UDim2.new(0, -iconSize * 0.3, 0.5, -iconSize/2),
                Text = "💎",
                TextScaled = true,
                BackgroundTransparency = 1,
                ZIndex = 12,
                ref = diamondIconRef
            }),
            
            DiamondText = e("TextLabel", {
                Name = "DiamondText",
                Size = UDim2.new(1, -(iconSize * 0.7 + 5), 1, 0),
                Position = UDim2.new(0, iconSize * 0.7 + 5, 0, 0),
                Text = diamondText,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = titleTextSize,
                TextWrapped = false,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 12
            }, {
                TextStroke = e("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = 2,
                    Transparency = 0.3
                })
            })
        }),
        
        RebirthPopup = showRebirthPopup and e("TextLabel", {
            Name = "RebirthPopup",
            Size = UDim2.new(0, 200, 0, 30),
            Position = UDim2.new(0, moneyWidth + containerSpacing + rebirthWidth/2 - 100, 1, 10),
            Text = rebirthPopupText,
            TextColor3 = Color3.fromRGB(255, 200, 0),
            TextSize = popupTextSize,
            TextWrapped = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansBold,
            ZIndex = 15,
            TextStrokeTransparency = 0.5,
            TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
            ref = rebirthPopupRef
        }) or nil,
        
        DiamondPopup = showDiamondPopup and e("TextLabel", {
            Name = "DiamondPopup",
            Size = UDim2.new(0, 200, 0, 30),
            Position = UDim2.new(0, moneyWidth + rebirthWidth + (containerSpacing * 2) + diamondWidth/2 - 100, 1, 10),
            Text = diamondPopupText,
            TextColor3 = Color3.fromRGB(0, 200, 255),
            TextSize = popupTextSize,
            TextWrapped = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansBold,
            ZIndex = 15,
            TextStrokeTransparency = 0.5,
            TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
            ref = diamondPopupRef
        }) or nil
    })
end

return TopStats