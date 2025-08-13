-- CrazyChestUI - Simple chest info interface
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.react)
local MarketplaceService = game:GetService("MarketplaceService")

local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local GradientUtils = require(ReplicatedStorage.utils.GradientUtils)
local store = require(ReplicatedStorage.store)

-- Wait for config to be available
local configFolder = ReplicatedStorage:WaitForChild("config", 10)
local CrazyChestConfig = configFolder and require(configFolder.CrazyChestConfig) or nil
local PotionConfig = configFolder and require(configFolder.PotionConfig) or nil

local CrazyChestUI = {}

-- Cache for created cards to prevent recreation during animation
local cardCache = nil
local lastRewardsKey = nil

-- Helper function to format potion reward text
local function formatPotionRewardText(reward, multiplier)
    if not reward or reward.type ~= "potion" then
        return "Potion!"
    end
    
    local potionConfig = PotionConfig and PotionConfig.GetPotion and PotionConfig.GetPotion(reward.potionId)
    if not potionConfig then
        return NumberFormatter.format(math.floor(reward.quantity * multiplier)) .. "\nPotion!"
    end
    
    -- Get the chest level for proper potion scaling
    local playerData = store:getState().playerData
    local chestLevel = playerData and playerData.CrazyChest and playerData.CrazyChest.Level or 1
    local potionBonus = math.floor(chestLevel / 10) -- +1 every 10 levels
    local finalQuantity = reward.quantity + potionBonus
    
    -- Format based on potion type
    if reward.potionId == "money_2x_10m" then
        return finalQuantity .. "x\n2x Money!"
    elseif reward.potionId == "diamonds_2x_10m" then
        return finalQuantity .. "x\n2x Diamonds!"
    elseif reward.potionId == "pet_magnet_10m" then
        return finalQuantity .. "x\nPet Magnet!"
    end
    
    local duration = PotionConfig.FormatDuration and PotionConfig.FormatDuration(potionConfig.Duration) or "10m"
    local name = potionConfig.BoostType == "Pet Magnet" and "Pet Magnet" or potionConfig.BoostType
    local quantity = NumberFormatter.format(math.floor(reward.quantity * multiplier))
    
    return quantity .. " - " .. duration .. "\n" .. name .. "!"
end

-- Helper function to format potion reward text for preview cards (uses next level)
local function formatPotionPreviewText(reward, nextChestLevel)
    if not reward or reward.type ~= "potion" then
        return "Potion!"
    end
    
    local potionConfig = PotionConfig and PotionConfig.GetPotion and PotionConfig.GetPotion(reward.potionId)
    if not potionConfig then
        return NumberFormatter.format(reward.quantity) .. "\nPotion!"
    end
    
    -- Calculate potion bonus for the NEXT chest level
    local potionBonus = math.floor(nextChestLevel / 10) -- +1 every 10 levels
    local finalQuantity = reward.quantity + potionBonus
    
    -- Format based on potion type
    if reward.potionId == "money_2x_10m" then
        return finalQuantity .. "x\n2x Money!"
    elseif reward.potionId == "diamonds_2x_10m" then
        return finalQuantity .. "x\n2x Diamonds!"
    elseif reward.potionId == "pet_magnet_10m" then
        return finalQuantity .. "x\nPet Magnet!"
    end
    
    local duration = PotionConfig.FormatDuration and PotionConfig.FormatDuration(potionConfig.Duration) or "10m"
    local name = potionConfig.BoostType == "Pet Magnet" and "Pet Magnet" or potionConfig.BoostType
    
    return finalQuantity .. " - " .. duration .. "\n" .. name .. "!"
end

-- Create clean purchase modal component
local function createCleanPurchaseModal(props)
    local upgradeType = props.upgradeType -- "level" or "luck"
    local diamondCost = props.diamondCost
    local currentLevel = props.currentLevel
    local onClose = props.onClose
    local onPurchaseDiamonds = props.onPurchaseDiamonds
    local onPurchaseRobux = props.onPurchaseRobux
    local canAffordDiamonds = props.canAffordDiamonds
    local robuxPrice = props.robuxPrice or "???"
    local breatheScale = props.breatheScale or 1
    
    
    local title = upgradeType == "level" and "Chest Level" or "Luck Level"
    local icon = upgradeType == "level" and "⬆️" or "🍀"
    local nextLevel = currentLevel + 1
    
    -- Calculate dynamic button widths based on text content
    local robuxText = tostring(robuxPrice)
    local diamondText = NumberFormatter.format(diamondCost)
    
    -- Calculate button widths based on text + padding for proper sizing
    -- Each character is roughly 0.035 screen width at this large size
    local baseRobuxWidth = #robuxText * 0.035
    local baseDiamondWidth = #diamondText * 0.035
    
    -- Add padding: 37.5% left + 10% right = 47.5% padding total
    -- Add extra minimum padding for short robux prices
    local robuxTextWidth = math.max(0.18, baseRobuxWidth / 0.4) -- Increased padding (was 0.525)
    local diamondTextWidth = math.max(0.15, baseDiamondWidth / 0.4) -- Increased padding (was 0.525)
    
    -- Ensure buttons don't get too wide
    robuxTextWidth = math.min(robuxTextWidth, 0.35)
    diamondTextWidth = math.min(diamondTextWidth, 0.35)
    
    -- Icon size (same as text size)
    local iconSize = ScreenUtils.TEXT_SIZES.LARGE() * 2.4 / ScreenUtils.TEXT_SIZES.MEDIUM() * 0.06 -- Convert to screen proportion
    
    return React.createElement("TextButton", {
        Name = "PurchaseModalOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        Text = "",
        ZIndex = 2000,
        [React.Event.MouseButton1Click] = onClose,
    }, {
        PurchaseModal = React.createElement("Frame", {
            Name = "PurchaseModal",
            Size = ScreenUtils.udim2(0.18, 0, 0.32, 0), -- Taller and narrower
            Position = ScreenUtils.udim2(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 2001,
        }, {
            -- Block click propagation
            ClickBlocker = React.createElement("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 2000,
                [React.Event.MouseButton1Click] = function() end,
            }),
            
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(10)),
            }),
            
            Stroke = React.createElement("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = ScreenUtils.getProportionalSize(5),
                Transparency = 0,
            }),
            
            -- Simple title
            Title = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, 0, 0.15, 0),
                Position = ScreenUtils.udim2(0, 0, 0.03, 0),
                BackgroundTransparency = 1,
                Text = string.format("%s %s", icon, title),
                TextColor3 = Color3.fromRGB(0, 0, 0),
                TextSize = ScreenUtils.TEXT_SIZES.HEADER() * 1.5,
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextStrokeTransparency = 0.8,
                TextStrokeColor3 = Color3.fromRGB(200, 200, 200),
                ZIndex = 2003,
            }),
            
            -- Close button for purchase modal
            ModalCloseButton = React.createElement("ImageButton", {
                Size = ScreenUtils.udim2(0, ScreenUtils.getProportionalSize(35), 0, ScreenUtils.getProportionalSize(35)),
                Position = ScreenUtils.udim2(1, -ScreenUtils.getProportionalSize(40), 0, ScreenUtils.getProportionalSize(8)),
                BackgroundColor3 = Color3.fromRGB(220, 53, 69), -- Red close button
                Image = IconAssets.getIcon("UI", "X_BUTTON"), -- Correct X_BUTTON icon
                ImageColor3 = Color3.fromRGB(255, 255, 255),
                ScaleType = Enum.ScaleType.Fit,
                BorderSizePixel = 0,
                ZIndex = 2004,
                [React.Event.Activated] = onClose,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(6)),
                }),
                
                Stroke = React.createElement("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = ScreenUtils.getProportionalSize(2),
                    Transparency = 0,
                }),
            }),
            
            -- Level progression - bigger
            LevelText = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, 0, 0.12, 0),
                Position = ScreenUtils.udim2(0, 0, 0.20, 0),
                BackgroundTransparency = 1,
                Text = string.format("%d → %d", currentLevel, nextLevel),
                TextColor3 = upgradeType == "level" and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(139, 69, 19),
                TextSize = ScreenUtils.TEXT_SIZES.TITLE() * 1.2,
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                ZIndex = 2003,
            }),
            
            -- Benefits text
            Benefits = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(0.9, 0, 0.08, 0),
                Position = ScreenUtils.udim2(0.05, 0, 0.34, 0),
                BackgroundTransparency = 1,
                Text = upgradeType == "level" and "+25% Rewards" or "Increases Luck",
                TextColor3 = Color3.fromRGB(100, 100, 100),
                TextSize = ScreenUtils.TEXT_SIZES.LARGE() * 1.3,
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 2002,
            }),
            
            -- "BEST VALUE!" text above robux button with shake animation
            BestValueText = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(0.5 * (breatheScale or 1), 0, 0.06 * (breatheScale or 1), 0), -- Breathing size
                Position = ScreenUtils.udim2(0.25, 0, 0.47, 0), -- No horizontal movement for breathing
                BackgroundTransparency = 1,
                Text = "BEST VALUE!",
                TextColor3 = Color3.fromRGB(255, 215, 0),
                TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() * 1.3,
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                ZIndex = 2004,
            }),
            
            -- Robux icon (LEFT) - positioned partially outside button
            RobuxIcon = React.createElement("ImageLabel", {
                Size = ScreenUtils.udim2(iconSize, 0, iconSize, 0),
                Position = ScreenUtils.udim2(0.5 - robuxTextWidth/2 - iconSize/2, 0, 0.54 + 0.06 - iconSize/2, 0), -- Half overlaps button
                BackgroundTransparency = 1,
                Image = IconAssets.CURRENCY.ROBUX,
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 2004, -- Above button
            }),
            
            -- Robux button (TOP) - highlighted with green
            RobuxButton = React.createElement("TextButton", {
                Size = ScreenUtils.udim2(robuxTextWidth, 0, 0.12, 0), -- Dynamic width based on text only
                Position = ScreenUtils.udim2(0.5 - robuxTextWidth/2, 0, 0.54, 0), -- Dynamically centered
                BackgroundColor3 = Color3.fromRGB(0, 176, 111), -- Green for "best value"
                Text = "",
                BorderSizePixel = 0,
                ZIndex = 2002,
                [React.Event.MouseButton1Click] = onPurchaseRobux,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 4),
                }),
                
                -- Inner black stroke
                InnerStroke = React.createElement("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = ScreenUtils.getProportionalSize(2),
                    Transparency = 0,
                }),
                
                -- Black button outline
                ButtonOutline = React.createElement("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = ScreenUtils.getProportionalSize(3),
                    Transparency = 0,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                }),
                
                -- Price text - with left and right padding
                PriceText = React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(0.525, 0, 1, 0), -- 52.5% width for text area
                    Position = ScreenUtils.udim2(0.375, 0, 0, 0), -- 37.5% left padding for icon space
                    BackgroundTransparency = 1,
                    Text = robuxPrice,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.TEXT_SIZES.LARGE() * 2.4,
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 2003,
                }),
            }),
            
            -- OR separator
            OrText = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(0.2, 0, 0.06, 0),
                Position = ScreenUtils.udim2(0.4, 0, 0.67, 0), -- Adjusted for smaller buttons
                BackgroundTransparency = 1,
                Text = "OR",
                TextColor3 = Color3.fromRGB(150, 150, 150),
                TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() * 1.2,
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 2003,
            }),
            
            -- Diamond icon (LEFT) - positioned partially outside button
            DiamondIcon = React.createElement("ImageLabel", {
                Size = ScreenUtils.udim2(iconSize, 0, iconSize, 0),
                Position = ScreenUtils.udim2(0.5 - diamondTextWidth/2 - iconSize/2, 0, 0.76 + 0.06 - iconSize/2, 0), -- Half overlaps button
                BackgroundTransparency = 1,
                Image = IconAssets.CURRENCY.DIAMONDS,
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 2004, -- Above button
            }),
            
            -- Diamond button (BOTTOM)
            DiamondButton = React.createElement("TextButton", {
                Size = ScreenUtils.udim2(diamondTextWidth, 0, 0.12, 0), -- Dynamic width based on text only
                Position = ScreenUtils.udim2(0.5 - diamondTextWidth/2, 0, 0.76, 0), -- Dynamically centered
                BackgroundColor3 = canAffordDiamonds and Color3.fromRGB(64, 224, 208) or Color3.fromRGB(150, 150, 150),
                Text = "",
                BorderSizePixel = 0,
                ZIndex = 2002,
                [React.Event.MouseButton1Click] = canAffordDiamonds and onPurchaseDiamonds or function() end,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 4),
                }),
                
                -- Inner black stroke
                InnerStroke = React.createElement("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = ScreenUtils.getProportionalSize(2),
                    Transparency = 0,
                }),
                
                -- Black button outline
                ButtonOutline = React.createElement("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = ScreenUtils.getProportionalSize(3),
                    Transparency = 0,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                }),
                
                -- Price text - with left and right padding
                PriceText = React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(0.525, 0, 1, 0), -- 52.5% width for text area
                    Position = ScreenUtils.udim2(0.375, 0, 0, 0), -- 37.5% left padding for icon space
                    BackgroundTransparency = 1,
                    Text = NumberFormatter.format(diamondCost),
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.TEXT_SIZES.LARGE() * 2.4,
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 2003,
                }),
            }),
        })
    })
end

-- Reusable RewardCard component for static reward display (top section)
local function RewardCard(props)
    local reward = props.reward
    local layoutOrder = props.layoutOrder
    local isChanceBackgroundTransparent = props.isChanceBackgroundTransparent or false
    local rewardMultiplier = props.rewardMultiplier or 1
    local totalCards = props.totalCards or 8
    
    -- Calculate dynamic width: leave 20% for spacing/margins, divide remaining 80% by number of cards
    local cardWidthPercent = 0.8 / totalCards -- 80% divided by number of cards
    
    return React.createElement("Frame", {
        Size = UDim2.new(cardWidthPercent, 0, 0, ScreenUtils.getProportionalSize(176)), -- 10% bigger: 160 * 1.1 = 176
        -- Removed AutomaticSize so all cards have same height
        BackgroundColor3 = reward.color or Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = (reward.special == "rainbow" or (reward.special == "black_market" or reward.special == "black_market_rainbow_text")) and 0.3 or 0.7,
        BorderSizePixel = 0,
        LayoutOrder = layoutOrder,
        ZIndex = 1003,
    }, {
        -- Rounded corners
        Corner = React.createElement("UICorner", {
            CornerRadius = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(8)),
        }),
        
        -- Rainbow gradient background
        reward.special == "rainbow" and GradientUtils.CreateReactGradient(GradientUtils.RAINBOW_DIAGONAL) or nil,
        
        -- Black market gradient background
        (reward.special == "black_market" or reward.special == "black_market_rainbow_text") and GradientUtils.CreateReactGradient(GradientUtils.BLACK_MARKET) or nil,
        
        -- Colored border
        ColorOutline = React.createElement("UIStroke", {
            Color = reward.color or Color3.fromRGB(200, 200, 200),
            Thickness = ScreenUtils.getProportionalSize(4),
        }, {
            reward.special == "rainbow" and GradientUtils.CreateReactGradient(GradientUtils.RAINBOW_DIAGONAL) or nil,
            
            (reward.special == "black_market" or reward.special == "black_market_rainbow_text") and GradientUtils.CreateReactGradient(GradientUtils.BLACK_MARKET) or nil,
        }),
        
        -- Content container
        ContentContainer = React.createElement("Frame", {
            Name = "ContentContainer",
            Size = UDim2.new(1, 0, 0, 0), -- Full width, let AutomaticSize determine height
            AutomaticSize = Enum.AutomaticSize.Y, -- Size to fit content height
            Position = UDim2.new(0, 0, 0, 0), -- Top left position
            BackgroundTransparency = 1, -- Transparent
            ZIndex = 1004,
        }, {
            -- Padding
            Padding = React.createElement("UIPadding", {
                PaddingTop = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(11)), -- 10% bigger: 10 * 1.1 = 11
                PaddingBottom = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(11)),
                PaddingLeft = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(11)),
                PaddingRight = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(11)),
            }),
            
            -- Layout
            Layout = React.createElement("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Top,
                Padding = UDim.new(0.02, 0), -- Use percentage-based spacing instead of fixed pixels
            }),
            
            -- Pet model or currency icon
            reward.type == "pet" and React.createElement("ViewportFrame", {
                Name = "PetModel",
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(88), 0, ScreenUtils.getProportionalSize(88)), -- 10% bigger: 80 * 1.1 = 88
                BackgroundTransparency = 1, -- Transparent
                LayoutOrder = 1,
                ZIndex = 1020,
                [React.Event.AncestryChanged] = function(rbx)
                    if rbx.Parent then
                        task.spawn(function()
                            task.wait(0.1)
                            -- Clear existing models
                            for _, child in pairs(rbx:GetChildren()) do
                                if child:IsA("Model") or child:IsA("Camera") then
                                    child:Destroy()
                                end
                            end
                            
                            local petsFolder = ReplicatedStorage:FindFirstChild("Pets")
                            if petsFolder then
                                local petModelTemplate = petsFolder:FindFirstChild(reward.petName)
                                if petModelTemplate then
                                    local model = petModelTemplate:Clone()
                                    model.Name = "ViewportModel"
                                    
                                    -- Set PrimaryPart
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
                                        if largestPart then model.PrimaryPart = largestPart end
                                    end
                                    
                                    -- Prepare model
                                    for _, part in pairs(model:GetDescendants()) do
                                        if part:IsA("BasePart") then
                                            part.CanCollide = false
                                            part.Anchored = true
                                            part.Massless = true
                                        end
                                    end
                                    
                                    -- Center and rotate model
                                    local modelCFrame, modelSize = model:GetBoundingBox()
                                    local offset = modelCFrame.Position
                                    for _, part in pairs(model:GetDescendants()) do
                                        if part:IsA("BasePart") then
                                            part.Position = part.Position - offset
                                        end
                                    end
                                    
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
                                    
                                    model.Parent = rbx
                                    
                                    -- Camera setup
                                    local camera = Instance.new("Camera")
                                    camera.CameraType = Enum.CameraType.Scriptable
                                    camera.CFrame = CFrame.new(0.1, -0.15, 10)
                                    camera.FieldOfView = 90
                                    camera.Parent = rbx
                                    rbx.CurrentCamera = camera
                                    
                                    rbx.LightDirection = Vector3.new(0, -0.1, -1).Unit
                                    rbx.Ambient = Color3.fromRGB(255, 255, 255)
                                    rbx.LightColor = Color3.fromRGB(255, 255, 255)
                                end
                            end
                        end)
                    end
                end,
            }) or React.createElement("ImageLabel", {
                Name = "CurrencyIcon",
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(66), 0, ScreenUtils.getProportionalSize(66)), -- 10% bigger: 60 * 1.1 = 66
                BackgroundTransparency = 1, -- Transparent
                Image = reward.type == "money" and "rbxassetid://80960000119108" or 
                       (reward.type == "potion" and (function()
                           local potionConfig = PotionConfig and PotionConfig.GetPotion and PotionConfig.GetPotion(reward.potionId)
                           return potionConfig and potionConfig.Icon or "rbxassetid://118134400760699"
                       end)() or "rbxassetid://135421873302468"),
                ImageColor3 = Color3.fromRGB(255, 255, 255),
                LayoutOrder = 1,
                ZIndex = 1005,
            }),
            
            -- Reward text - formatted on two lines with larger text
            RewardText = React.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(44)), -- 10% bigger: 40 * 1.1 = 44
                BackgroundTransparency = 1, -- Transparent
                -- Special text for ultra-rare chest, regular formatting for others
                Text = reward.special == "black_market_rainbow_text" and (NumberFormatter.format(math.floor(reward.boost * rewardMultiplier)) .. "\nBoost!") or
                       (reward.type == "pet" and (NumberFormatter.format(math.floor(reward.boost * rewardMultiplier)) .. "\nBoost!") or 
                       (reward.type == "money" and (NumberFormatter.format(math.floor(reward.money * rewardMultiplier)) .. "\nMoney!") or
                       (reward.type == "potion" and formatPotionRewardText(reward, rewardMultiplier) or
                       (NumberFormatter.format(math.floor(reward.diamonds * rewardMultiplier)) .. "\nDiamonds!")))),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = ScreenUtils.TEXT_SIZES.LARGE(), -- 50% bigger - upgraded from MEDIUM to LARGE
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center, -- Center vertically for two lines
                TextScaled = true, -- Enable text scaling to fit smaller cards
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                LayoutOrder = 2,
                ZIndex = 1005,
            }, {
                -- Rainbow text gradient for ultra-rare chest
                reward.special == "black_market_rainbow_text" and GradientUtils.CreateReactGradient(GradientUtils.RAINBOW) or nil,
            }),
            
            -- No pet name for cleaner UI - viewport model and boost text is enough
        }),
        
        -- CONSISTENT PERCENTAGE TEXT FOR ALL CARDS - THIS IS THE KEY FIX
        ChanceLabel = React.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(39)), -- 10% bigger: 35 * 1.1 = 39 (rounded)
            Position = UDim2.new(0, 0, 1, -ScreenUtils.getProportionalSize(39)), -- Anchored to bottom of card
            -- Use transparency to inherit main card background or solid color
            BackgroundColor3 = reward.color or Color3.fromRGB(200, 200, 200),
            BackgroundTransparency = isChanceBackgroundTransparent and 1 or 0, -- Transparent inherits main background
            Text = reward.special == "black_market_rainbow_text" and string.format("%.3f%%", reward.chance) or string.format("%.2f%%", reward.chance),
            -- WHITE TEXT except for special black market with rainbow text
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = ScreenUtils.getProportionalSize(39), -- Text size matches container height exactly (10% bigger)
            Font = Enum.Font.FredokaOne,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextScaled = true, -- Enable text scaling to fit smaller cards
            -- ALWAYS BLACK STROKE - no exceptions, no conditions, no inheritance
            TextStrokeTransparency = 0,
            TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            ZIndex = 1004,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(8)),
            }),
            
        }),
    })
end

-- Separate AnimationCard component for the scrolling animation section  
local function AnimationCard(props)
    local reward = props.reward
    local itemWidth = props.itemWidth
    local itemSpacing = props.itemSpacing
    local position = props.position
    local rewardMultiplier = props.rewardMultiplier or 1
    
    -- Create reward text for animation cards - same two-line format as RewardCard with chest level multiplier
    local rewardText = reward.type == "pet" and (NumberFormatter.format(math.floor(reward.boost * rewardMultiplier)) .. "\nBoost!") or 
                      (reward.type == "money" and (NumberFormatter.format(math.floor(reward.money * rewardMultiplier)) .. "\nMoney!") or
                      (reward.type == "potion" and formatPotionRewardText(reward, rewardMultiplier) or
                      (NumberFormatter.format(math.floor(reward.diamonds * rewardMultiplier)) .. "\nDiamonds!")))
    
    return React.createElement("Frame", {
        Name = "RewardItem" .. position,
        Size = UDim2.new(0, itemWidth, 1, 0),
        Position = UDim2.new(0, (position-1) * (itemWidth + itemSpacing), 0, 0),
        BackgroundColor3 = reward.color or Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = (reward.special == "rainbow" or (reward.special == "black_market" or reward.special == "black_market_rainbow_text")) and 0.3 or 0.7,
        BorderSizePixel = 0,
        ZIndex = 1011,
    }, {
        Corner = React.createElement("UICorner", {
            CornerRadius = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(8)),
        }),
        
        -- Rainbow gradient background
        reward.special == "rainbow" and GradientUtils.CreateReactGradient(GradientUtils.RAINBOW_DIAGONAL) or nil,
        
        -- Thick border
        Stroke = React.createElement("UIStroke", {
            Color = reward.color or Color3.fromRGB(200, 200, 200),
            Thickness = ScreenUtils.getProportionalSize(4),
        }, {
            reward.special == "rainbow" and GradientUtils.CreateReactGradient(GradientUtils.RAINBOW_DIAGONAL) or nil,
            
            (reward.special == "black_market" or reward.special == "black_market_rainbow_text") and GradientUtils.CreateReactGradient(GradientUtils.BLACK_MARKET) or nil,
        }),
        
        -- Pet model or currency icon
        reward.type == "pet" and React.createElement("ViewportFrame", {
            Name = "PetModel",
            Size = ScreenUtils.udim2(0.6, 0, 0.6, 0), -- 60% of card size
            Position = ScreenUtils.udim2(0.2, 0, 0.1, 0), -- Centered with 20% margin
            BackgroundTransparency = 1,
            ZIndex = 1025,
            [React.Event.AncestryChanged] = function(rbx)
                if rbx.Parent then
                    task.spawn(function()
                        task.wait(0.1)
                        
                        for _, child in pairs(rbx:GetChildren()) do
                            if child:IsA("Model") or child:IsA("Camera") then
                                child:Destroy()
                            end
                        end
                        
                        local petsFolder = ReplicatedStorage:FindFirstChild("Pets")
                        if petsFolder then
                            local petModelTemplate = petsFolder:FindFirstChild(reward.petName)
                            if petModelTemplate then
                                local model = petModelTemplate:Clone()
                                model.Name = "PetModel"
                                
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
                                    if largestPart then model.PrimaryPart = largestPart end
                                end
                                
                                for _, part in pairs(model:GetDescendants()) do
                                    if part:IsA("BasePart") then
                                        part.CanCollide = false
                                        part.Anchored = true
                                        part.Massless = true
                                    end
                                end
                                
                                local modelCFrame, modelSize = model:GetBoundingBox()
                                local offset = modelCFrame.Position
                                for _, part in pairs(model:GetDescendants()) do
                                    if part:IsA("BasePart") then
                                        part.Position = part.Position - offset
                                    end
                                end
                                
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
                                
                                model.Parent = rbx
                                
                                local camera = Instance.new("Camera")
                                camera.CameraType = Enum.CameraType.Scriptable
                                camera.CFrame = CFrame.new(0.1, -0.15, 10)
                                camera.FieldOfView = 90
                                camera.Parent = rbx
                                rbx.CurrentCamera = camera
                                
                                rbx.LightDirection = Vector3.new(0, -0.1, -1).Unit
                                rbx.Ambient = Color3.fromRGB(255, 255, 255)
                                rbx.LightColor = Color3.fromRGB(255, 255, 255)
                            end
                        end
                    end)
                end
            end,
        }) or React.createElement("ImageLabel", {
            Name = "CurrencyIcon",
            Size = ScreenUtils.udim2(0.5, 0, 0.5, 0), -- 50% of card size
            Position = ScreenUtils.udim2(0.25, 0, 0.15, 0), -- Centered with 25% margin
            BackgroundTransparency = 1,
            Image = reward.type == "money" and "rbxassetid://80960000119108" or 
                   (reward.type == "potion" and (function()
                       local potionConfig = PotionConfig and PotionConfig.GetPotion and PotionConfig.GetPotion(reward.potionId)
                       return potionConfig and potionConfig.Icon or "rbxassetid://118134400760699"
                   end)() or "rbxassetid://135421873302468"),
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            ScaleType = Enum.ScaleType.Fit, -- Maintain aspect ratio
            ZIndex = 1012,
        }),
        
        -- Reward text - same formatting as RewardCard (two lines, large text)
        RewardText = React.createElement("TextLabel", {
            Size = ScreenUtils.udim2(1, -10, 0.35, 0), -- 35% of card height
            Position = ScreenUtils.udim2(0, 5, 0.6, 0), -- Position at 60% down the card
            BackgroundTransparency = 1,
            Text = rewardText,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = ScreenUtils.TEXT_SIZES.LARGE(), -- Keep base size but allow scaling
            Font = Enum.Font.FredokaOne,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center, -- Center vertically for two lines
            TextScaled = true, -- Enable scaling to fit container
            TextStrokeTransparency = 0,
            TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = 1012,
        })
    })
end

-- Create static reward strip that shows all the time (before animation)  
function CrazyChestUI.createStaticRewardStrip(rewards, rewardMultiplier, chestLuck)
    if not rewards or #rewards == 0 then
        return {
            PlaceholderText = React.createElement("TextLabel", {
                Name = "PlaceholderText",
                Size = ScreenUtils.udim2(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "Loading rewards...",
                TextColor3 = Color3.fromRGB(150, 150, 150),
                TextSize = ScreenUtils.TEXT_SIZES.LARGE(),
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 1002,
            })
        }
    end
    
    local itemWidth = ScreenUtils.getProportionalSize(120)
    local itemSpacing = ScreenUtils.getProportionalSize(10)
    local totalItems = 50 -- Need 50 cards for the animation to work properly
    
    -- Create a unique key for rewards to check if they changed (include multiplier and luck-adjusted chances)
    local rewardsKey = ""
    for i, reward in ipairs(rewards) do
        rewardsKey = rewardsKey .. (reward.type or "") .. (reward.money or reward.diamonds or 0) .. (reward.chance or 0) .. "_"
    end
    rewardsKey = rewardsKey .. (rewardMultiplier or 1) .. "_" .. (chestLuck or 1) -- Include multiplier and luck level in cache key
    
    -- Only recreate cards if rewards OR multiplier actually changed
    if cardCache and lastRewardsKey == rewardsKey then
        -- Silently return cached cards for better performance
        return cardCache
    end
    
    -- Creating reward cards
    lastRewardsKey = rewardsKey
    
    local cardElements = {
        Corner = React.createElement("UICorner", {
            CornerRadius = ScreenUtils.udim(0, 15),
        }),
        
        -- Selection indicator (the line that shows where the result will land)
        SelectionIndicator = React.createElement("Frame", {
            Name = "SelectionIndicator",
            Size = ScreenUtils.udim2(0, ScreenUtils.getProportionalSize(4), 1, -ScreenUtils.getProportionalSize(80)),
            Position = ScreenUtils.udim2(0.5, -ScreenUtils.getProportionalSize(2), 0, ScreenUtils.getProportionalSize(40)),
            BackgroundColor3 = Color3.fromRGB(255, 215, 0), -- Gold like PlaytimeRewards claimed color
            BorderSizePixel = 0,
            ZIndex = 1013, -- Highest z-index to be above cards
        }, {
            -- Add black outline to selection line
            BlackOutline = React.createElement("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = ScreenUtils.getProportionalSize(3),
                Transparency = 0,
            }),
            
            -- Add inner glow effect to selection line (on top of black outline)
            Glow = React.createElement("UIStroke", {
                Color = Color3.fromRGB(255, 215, 0),
                Thickness = ScreenUtils.getProportionalSize(1),
                Transparency = 0.2,
            }),
        }),
        
        -- Scrolling container for rewards (static initially) with proper padding
        RewardStrip = React.createElement("ScrollingFrame", {
            Name = "RewardStrip", 
            Size = ScreenUtils.udim2(1, -ScreenUtils.getProportionalSize(40), 1, -ScreenUtils.getProportionalSize(60)), -- Reduced padding: 40px horizontal, 60px vertical
            Position = ScreenUtils.udim2(0, ScreenUtils.getProportionalSize(20), 0, ScreenUtils.getProportionalSize(30)), -- Reduced padding
            BackgroundColor3 = Color3.fromRGB(255, 255, 255), -- White background to match main UI
            BackgroundTransparency = 0,
            ScrollBarThickness = 0,
            ScrollingEnabled = false,
            CanvasSize = UDim2.new(0, totalItems * (itemWidth + itemSpacing), 0, 0),
            ZIndex = 1010, -- Higher than modal content
        }, (function()
            local elements = CrazyChestUI.createRewardCards(rewards, totalItems, itemWidth, itemSpacing, rewardMultiplier or 1)
            -- Add padding inside the scroll frame so cards don't touch edges
            elements.Padding = React.createElement("UIPadding", {
                PaddingTop = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(15)),
                PaddingBottom = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(15)),
                PaddingLeft = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(10)),
                PaddingRight = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(10)),
            })
            return elements
        end)())
    }
    
    -- Cache the created elements
    cardCache = cardElements
    return cardElements
end

-- Create individual reward cards based on probability distribution - now using RewardCard component
function CrazyChestUI.createRewardCards(rewards, totalItems, itemWidth, itemSpacing, rewardMultiplier)
    local cards = {}
    
    -- Create a weighted distribution based on reward chances
    local distribution = {}
    for _, reward in ipairs(rewards) do
        for _ = 1, reward.chance do -- Add reward multiple times based on chance
            table.insert(distribution, reward)
        end
    end
    
    for i = 1, totalItems do
        -- Select reward based on weighted distribution (more common = more cards)
        -- BUT add "near miss" excitement by biasing rare items near winning position
        local reward
        
        -- Check if this card is directly adjacent to the winning position (positions 37 and 39 only)
        local isNearWinning = (i == 37 or i == 39) -- Only positions directly next to winner (38)
        
        if isNearWinning then
            -- 35% chance to show a rare item near the winning position - subtle but noticeable
            if math.random() < 0.35 then
                -- Find rarer rewards (chance <= 10%) for "almost won" effect
                local rareRewards = {}
                for _, testReward in ipairs(rewards) do
                    if testReward.chance <= 10 then -- Epic, Legendary, Mythic, or Omniscient
                        table.insert(rareRewards, testReward)
                    end
                end
                
                if #rareRewards > 0 then
                    reward = rareRewards[math.random(1, #rareRewards)]
                    -- Remove obvious logging to make it less obvious
                    -- print("CrazyChestUI: *** NEAR MISS *** Placing rare", reward.name, "at position", i, "near winner (38) for excitement!")
                else
                    -- Fallback to normal distribution if no rare rewards
                    local rewardIndex = math.random(1, #distribution)
                    reward = distribution[rewardIndex]
                end
            else
                -- 65% chance to use normal distribution even near winning position
                local rewardIndex = math.random(1, #distribution)
                reward = distribution[rewardIndex]
            end
        -- Add extra rainbow cards throughout strip for better visibility - also reduced
        elseif math.random() < 0.02 then -- 2% chance for any position to be ultra-rare (reduced from 5%)
            local ultraRareRewards = {}
            for _, testReward in ipairs(rewards) do
                if testReward.chance <= 1 then -- Only Mythic (0.9%) and Omniscient (0.1%)
                    table.insert(ultraRareRewards, testReward)
                end
            end
            
            if #ultraRareRewards > 0 then
                reward = ultraRareRewards[math.random(1, #ultraRareRewards)]
                -- Removed logging to make it more subtle
            else
                local rewardIndex = math.random(1, #distribution)
                reward = distribution[rewardIndex]
            end
        else
            -- Normal weighted distribution for all other positions
            local rewardIndex = math.random(1, #distribution)
            reward = distribution[rewardIndex]
        end
        
        -- Use AnimationCard component for clean animation cards
        cards["RewardCard" .. i] = AnimationCard({
            reward = reward,
            itemWidth = itemWidth,
            itemSpacing = itemSpacing,
            position = i,
            rewardMultiplier = rewardMultiplier or 1, -- Pass the chest level multiplier to animation cards
        })
    end
    
    return cards
end

function CrazyChestUI.new(props)
    -- Don't render if not visible or config not available
    if not props.visible or not CrazyChestConfig then
        return nil
    end
    
    -- Modal state management
    local showLevelUpgradeModal, setShowLevelUpgradeModal = React.useState(false)
    local showLuckUpgradeModal, setShowLuckUpgradeModal = React.useState(false)
    
    -- State to track whether preview cards should persist after clicking upgrade button
    local persistLevelPreview, setPersistLevelPreview = React.useState(false)
    local persistLuckPreview, setPersistLuckPreview = React.useState(false)
    
    -- Centralized function to clean up ALL preview cards and show original cards
    local function cleanupAllPreviewCards(scrollFrame, source)
        if not scrollFrame then return end
        
        local levelPreviews = 0
        local luckPreviews = 0
        local originalCards = 0
        
        -- Count and remove ALL preview cards (both level and luck)
        for i = 1, 20 do
            local levelPreviewCard = scrollFrame:FindFirstChild("PreviewCard" .. i)
            if levelPreviewCard then
                levelPreviewCard:Destroy()
                levelPreviews = levelPreviews + 1
            end
        end
        
        for _, child in pairs(scrollFrame:GetChildren()) do
            if child:IsA("Frame") and string.find(child.Name, "LuckPreviewCard") then
                child:Destroy()
                luckPreviews = luckPreviews + 1
            end
        end
        
        -- Show ALL original cards
        for _, child in pairs(scrollFrame:GetChildren()) do
            if child:IsA("Frame") and child.LayoutOrder and not string.find(child.Name, "Preview") then
                child.Visible = true
                originalCards = originalCards + 1
            end
        end
        
        print("🧹 CLEANUP (" .. source .. "): Removed", levelPreviews, "level +", luckPreviews, "luck previews. Showed", originalCards, "originals")
    end
    
    -- Helper function to restore original cards by cleaning up preview cards
    local function forceRestoreOriginalCards()
        local playerGui = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
        if not playerGui then return end
        
        -- Navigate through React app structure: PlayerGui -> ReactContainer -> PetGrowerApp
        local reactContainer = playerGui:FindFirstChild("ReactContainer")
        if not reactContainer then return end
        
        local petGrowerApp = reactContainer:FindFirstChild("PetGrowerApp")
        if not petGrowerApp then return end
        
        -- Now look for the modal inside the React app
        local modal = petGrowerApp:FindFirstChild("CrazyChestUIOverlay")
        if not modal then return end
        
        -- Navigate to ChestModal first, then RewardsFrame
        local chestModal = modal:FindFirstChild("ChestModal")
        if not chestModal then return end
        
        local rewardsFrame = chestModal:FindFirstChild("RewardsFrame")
        if not rewardsFrame then return end
        
        local scrollFrame = rewardsFrame:FindFirstChild("RewardsContainer")
        if not scrollFrame then return end
        
        -- Remove ALL preview cards (both level and luck)
        for i = 1, 20 do -- Search up to 20 preview cards (should be more than enough)
            local previewCard = scrollFrame:FindFirstChild("PreviewCard" .. i)
            if previewCard then
                previewCard:Destroy()
            end
        end
        
        for _, child in pairs(scrollFrame:GetChildren()) do
            if child:IsA("Frame") and string.find(child.Name, "LuckPreviewCard") then
                child:Destroy()
            end
        end
        
        -- Show original cards
        for _, child in pairs(scrollFrame:GetChildren()) do
            if child:IsA("Frame") and child.LayoutOrder and not string.find(child.Name, "Preview") then
                child.Visible = true
            end
        end
    end
    
    -- Robux price state
    local levelRobuxPrice, setLevelRobuxPrice = React.useState("???")
    local luckRobuxPrice, setLuckRobuxPrice = React.useState("???")
    local openChestRobuxPrice, setOpenChestRobuxPrice = React.useState("???")
    
    -- Animation state for "BEST VALUE" breathing effect
    local breatheScale, setBreatheScale = React.useState(1)
    local lastBreatheTime = React.useRef(0)
    
    -- Fetch robux prices from MarketplaceService
    React.useEffect(function()
        -- Fetch level upgrade price
        task.spawn(function()
            local success, result = pcall(function()
                return MarketplaceService:GetProductInfo(3360998824, Enum.InfoType.Product)
            end)
            if success and result and result.PriceInRobux then
                setLevelRobuxPrice(tostring(result.PriceInRobux))
            end
        end)
        
        -- Fetch luck upgrade price
        task.spawn(function()
            local success, result = pcall(function()
                return MarketplaceService:GetProductInfo(3360998460, Enum.InfoType.Product)
            end)
            if success and result and result.PriceInRobux then
                setLuckRobuxPrice(tostring(result.PriceInRobux))
            end
        end)
        
        -- Fetch open chest price
        task.spawn(function()
            local success, result = pcall(function()
                return MarketplaceService:GetProductInfo(3361129353, Enum.InfoType.Product)
            end)
            if success and result and result.PriceInRobux then
                setOpenChestRobuxPrice(tostring(result.PriceInRobux))
            end
        end)
    end, {})
    
    -- Breathing animation effect every 3 seconds for "BEST VALUE" text
    React.useEffect(function()
        local RunService = game:GetService("RunService")
        
        local animationConnection
        animationConnection = RunService.Heartbeat:Connect(function()
            local currentTime = tick()
            
            -- Breathing animation every 3 seconds
            if currentTime - lastBreatheTime.current >= 3 then
                lastBreatheTime.current = currentTime
                
                local animationStartTime = currentTime
                local breatheConnection
                breatheConnection = RunService.Heartbeat:Connect(function()
                    local elapsed = tick() - animationStartTime
                    
                    if elapsed < 0.6 then 
                        -- Breathing cycle (600ms total)
                        -- Use sine wave for smooth breathing effect
                        local progress = elapsed / 0.6
                        local currentBreatheScale = 1 + (math.sin(progress * math.pi) * 0.2) -- Breathe from 1.0 to 1.2 and back
                        setBreatheScale(currentBreatheScale)
                    else
                        -- Return to normal and disconnect
                        setBreatheScale(1)
                        breatheConnection:Disconnect()
                    end
                end)
            end
        end)
        
        return function()
            animationConnection:Disconnect()
        end
    end, {})
    
    -- Purchase handlers
    
    local function handleLevelPurchaseDiamonds()
        setShowLevelUpgradeModal(false)
        setPersistLevelPreview(false) -- Clear persistence after purchase
        if props.onUpgradeChest then
            props.onUpgradeChest()
        end
    end
    
    local function handleLevelPurchaseRobux()
        setShowLevelUpgradeModal(false)
        setPersistLevelPreview(false) -- Clear persistence after purchase
        if props.onUpgradeChestRobux then
            props.onUpgradeChestRobux(3360998824) -- Dev product ID for level upgrade
        end
    end
    
    local function handleLuckPurchaseDiamonds()
        setShowLuckUpgradeModal(false)
        setPersistLuckPreview(false) -- Clear persistence after purchase
        if props.onUpgradeChestLuck then
            props.onUpgradeChestLuck()
        end
    end
    
    local function handleLuckPurchaseRobux()
        setShowLuckUpgradeModal(false)
        setPersistLuckPreview(false) -- Clear persistence after purchase
        if props.onUpgradeChestLuckRobux then
            props.onUpgradeChestLuckRobux(3360998460) -- Dev product ID for luck upgrade
        end
    end
    
    local function handleOpenChestRobux()
        if props.onOpenChestRobux then
            props.onOpenChestRobux(3361129353) -- Dev product ID for opening chest with robux
        end
    end
    
    local function handleOpenChestDiamonds()
        if props.onOpenChest then
            props.onOpenChest() -- Use existing diamond open chest handler
        end
    end
    
    -- UI is rendering properly
    
    -- Safe cost calculation with fallback
    local cost = 100 -- Default cost
    if CrazyChestConfig and CrazyChestConfig.getCost then
        local success, result = pcall(CrazyChestConfig.getCost, props.playerRebirths or 0)
        if success and result then
            cost = result
        end
    end
    
    local canAfford = (props.playerDiamonds or 0) >= cost
    
    -- Get luck-adjusted rewards based on current player's luck level
    local rewards = {}
    if CrazyChestConfig then
        if CrazyChestConfig.getLuckAdjustedRewards and props.chestLuck then
            -- Use luck-adjusted rewards if available
            local success, result = pcall(CrazyChestConfig.getLuckAdjustedRewards, props.chestLuck)
            if success and result then
                rewards = result
            else
                -- Fallback to base rewards
                rewards = CrazyChestConfig.REWARDS or {}
            end
        else
            -- Fallback to base rewards
            rewards = CrazyChestConfig.REWARDS or {}
        end
    end
    
    local isAnimating = props.isAnimating or false
    local isRewarding = props.isRewarding or false
    
    -- Check button states with animation awareness
    local isButtonsEnabled = not isAnimating and not isRewarding
    local diamondButtonEnabled = isButtonsEnabled and canAfford
    local robuxButtonEnabled = isButtonsEnabled
    
    -- Calculate dynamic button widths for Open Chest buttons (same logic as upgrade buttons)
    local robuxOpenText = openChestRobuxPrice
    local diamondOpenText = NumberFormatter.format(cost) -- Always show the cost
    
    -- Calculate button widths based on text + padding
    local baseRobuxOpenWidth = #robuxOpenText * 0.035
    local baseDiamondOpenWidth = #diamondOpenText * 0.035
    
    -- Add padding and minimums (reduced padding for less empty space)
    local robuxOpenTextWidth = math.max(0.18, baseRobuxOpenWidth / 0.65)
    local diamondOpenTextWidth = math.max(0.15, baseDiamondOpenWidth / 0.65)
    
    -- Ensure buttons don't get too wide
    robuxOpenTextWidth = math.min(robuxOpenTextWidth, 0.35)
    diamondOpenTextWidth = math.min(diamondOpenTextWidth, 0.35)
    
    -- Icon size (much larger to match reference - let's make it bigger)
    local openIconSize = ScreenUtils.TEXT_SIZES.LARGE() * 2.4 / ScreenUtils.TEXT_SIZES.MEDIUM() * 0.15 -- Increased from 0.06 to 0.15
    
    -- Header button icon size (2x larger than open chest icons)
    local headerIconSize = openIconSize * 2
    
    -- Create click-outside-to-close overlay
    return React.createElement("TextButton", {
        Name = "CrazyChestUIOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        Text = "",
        ZIndex = 999,
        [React.Event.MouseButton1Click] = function()
            -- Clear any persistent preview states before closing
            setPersistLevelPreview(false)
            setPersistLuckPreview(false)
            -- Restore cards before closing
            forceRestoreOriginalCards()
            props.onClose()
        end,
    }, {
        ChestModal = React.createElement("Frame", {
            Name = "ChestModal", 
            Size = ScreenUtils.udim2(0.5, 0, 0.7, 0), -- 50% width, 70% height - much narrower
            Position = ScreenUtils.udim2(0.5, 0, 0.5, 0), -- Center positioned
            AnchorPoint = Vector2.new(0.5, 0.5), -- Center anchor
            BackgroundColor3 = Color3.fromRGB(255, 255, 255), -- White background like PlaytimeRewards
            BorderSizePixel = 0,
            ZIndex = 1000,
        }, {
            -- Prevent click bubbling
            ClickBlocker = React.createElement("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 999,
                [React.Event.MouseButton1Click] = function() end,
            }),
            
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, 15),
            }),
            
            -- Add subtle border like PlaytimeRewards
            Stroke = React.createElement("UIStroke", {
                Color = Color3.fromRGB(230, 230, 230),
                Thickness = ScreenUtils.getProportionalSize(1),
            }),
            
            -- Header
            Header = React.createElement("Frame", {
                Size = ScreenUtils.udim2(1, 0, 0.1, 0), -- 10% of modal height
                BackgroundColor3 = Color3.fromRGB(255, 215, 0),
                BorderSizePixel = 0,
                ZIndex = 1001,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(15))
                }),
                
                -- Header black outline
                HeaderStroke = React.createElement("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = ScreenUtils.getProportionalSize(3),
                    Transparency = 0,
                }),
                
                Title = React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(0.5, 0, 1, 0), -- Wider to accommodate text
                    Position = ScreenUtils.udim2(0.25, 0, 0, 0), -- Centered between buttons (0.05 to 0.78 range)
                    BackgroundTransparency = 1,
                    Text = "🎰 CRAZY CHEST",
                    TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                    TextSize = ScreenUtils.TEXT_SIZES.LARGE() * 2.4, -- Same size as button text
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextStrokeTransparency = 0, -- Black outline
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0), -- Black outline
                    ZIndex = 1002,
                }),
                
                -- Close button
                CloseButton = React.createElement("ImageButton", {
                    Size = ScreenUtils.udim2(0, ScreenUtils.getProportionalSize(50), 0, ScreenUtils.getProportionalSize(50)), -- Bigger (was 40x40)
                    Position = ScreenUtils.udim2(1, -ScreenUtils.getProportionalSize(25), 0, -ScreenUtils.getProportionalSize(25)), -- Top-right corner, half outside
                    BackgroundColor3 = Color3.fromRGB(220, 53, 69), -- Red close button
                    Image = IconAssets.getIcon("UI", "X_BUTTON"), -- Correct X_BUTTON icon
                    ImageColor3 = Color3.fromRGB(255, 255, 255),
                    ScaleType = Enum.ScaleType.Fit,
                    BorderSizePixel = 0,
                    ZIndex = 1003,
                    [React.Event.Activated] = function()
                        -- Clear any persistent preview states before closing
                        setPersistLevelPreview(false)
                        setPersistLuckPreview(false)
                        -- Restore cards before closing
                        forceRestoreOriginalCards()
                        -- Call the original close handler
                        props.onClose()
                    end,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(8)),
                    }),
                    
                    Stroke = React.createElement("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = ScreenUtils.getProportionalSize(2),
                        Transparency = 0,
                    }),
                }),
                
                UpgradeButton = React.createElement("TextButton", {
                    Size = ScreenUtils.udim2(0.2, 0, 0.8, 0), -- Slightly smaller width
                    Position = ScreenUtils.udim2(0.78, 0, 0.1, 0), -- Right side position
                    BackgroundColor3 = not props.isAnimating and Color3.fromRGB(0, 176, 111) or Color3.fromRGB(150, 150, 150), -- Same green as robux buttons
                    Text = "",
                    BorderSizePixel = 0,
                    ZIndex = 1002,
                    [React.Event.MouseButton1Click] = not props.isAnimating and function()
                        setPersistLevelPreview(true) -- Keep preview cards visible
                        setShowLevelUpgradeModal(true)
                    end or function() end,
                    [React.Event.MouseEnter] = function(rbx)
                        -- Don't show preview during animation
                        if props.isAnimating then return end
                        
                        
                        -- Hide original cards and create green preview cards
                        local modal = rbx.Parent.Parent
                        local rewardsFrame = modal:FindFirstChild("RewardsFrame")
                        local scrollFrame = rewardsFrame and rewardsFrame:FindFirstChild("RewardsContainer")
                        
                        if scrollFrame then
                            -- Calculate next level multiplier (60% increase per level)
                            local nextLevel = (props.chestLevel or 1) + 1
                            local nextLevelMultiplier = 1 + (nextLevel - 1) * 0.6
                            
                            -- Step 1: Clean up ALL existing preview cards and show original cards
                            cleanupAllPreviewCards(scrollFrame, "LEVEL_ENTER")
                            
                            -- Step 2: Hide all original cards (they're now visible after cleanup)
                            for _, child in pairs(scrollFrame:GetChildren()) do
                                if child:IsA("Frame") and child.LayoutOrder and not string.find(child.Name, "Preview") then
                                    child.Visible = false
                                end
                            end
                            
                            -- Step 3: Create green preview cards that take their place in the layout
                            for i, reward in ipairs(rewards) do
                                -- Calculate dynamic width: same as RewardCard
                                local totalCards = #rewards
                                local cardWidthPercent = 0.8 / totalCards
                                
                                -- Create preview card
                                local previewCard = Instance.new("Frame")
                                previewCard.Name = "PreviewCard" .. i
                                previewCard.Size = UDim2.new(cardWidthPercent, 0, 0, ScreenUtils.getProportionalSize(176)) -- Match RewardCard dimensions
                                previewCard.BackgroundColor3 = reward.color or Color3.fromRGB(255, 255, 255)
                                previewCard.BackgroundTransparency = (reward.special == "rainbow" or reward.special == "black_market" or reward.special == "black_market_rainbow_text") and 0.3 or 0.7
                                previewCard.BorderSizePixel = 0
                                previewCard.LayoutOrder = i -- Take the same layout position
                                previewCard.ZIndex = 1003
                                previewCard.Parent = scrollFrame
                                
                                -- Add corner
                                local corner = Instance.new("UICorner")
                                corner.CornerRadius = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(8))
                                corner.Parent = previewCard
                                
                                -- Add gradient if needed
                                if reward.special == "rainbow" then
                                    local gradient = Instance.new("UIGradient")
                                    gradient.Parent = previewCard
                                    GradientUtils.ApplyGradient(GradientUtils.RAINBOW_DIAGONAL, gradient)
                                elseif reward.special == "black_market" or reward.special == "black_market_rainbow_text" then
                                    local gradient = Instance.new("UIGradient")
                                    gradient.Parent = previewCard
                                    GradientUtils.ApplyGradient(GradientUtils.BLACK_MARKET, gradient)
                                end
                                
                                -- Add stroke
                                local stroke = Instance.new("UIStroke")
                                stroke.Color = reward.color or Color3.fromRGB(200, 200, 200)
                                stroke.Thickness = ScreenUtils.getProportionalSize(4)
                                stroke.Parent = previewCard
                                
                                -- Add gradient to stroke if needed
                                if reward.special == "rainbow" then
                                    local strokeGradient = Instance.new("UIGradient")
                                    strokeGradient.Parent = stroke
                                    GradientUtils.ApplyGradient(GradientUtils.RAINBOW_DIAGONAL, strokeGradient)
                                elseif reward.special == "black_market" or reward.special == "black_market_rainbow_text" then
                                    local strokeGradient = Instance.new("UIGradient")
                                    strokeGradient.Parent = stroke
                                    GradientUtils.ApplyGradient(GradientUtils.BLACK_MARKET, strokeGradient)
                                end
                                
                                -- Add content container
                                local contentContainer = Instance.new("Frame")
                                contentContainer.Size = UDim2.new(1, 0, 1, -ScreenUtils.getProportionalSize(55))
                                contentContainer.Position = UDim2.new(0, 0, 0, 0)
                                contentContainer.BackgroundTransparency = 1
                                contentContainer.ZIndex = 1004
                                contentContainer.Parent = previewCard
                                
                                -- Add padding
                                local padding = Instance.new("UIPadding")
                                padding.PaddingTop = UDim.new(0, ScreenUtils.getProportionalSize(10))
                                padding.PaddingBottom = UDim.new(0, ScreenUtils.getProportionalSize(10))
                                padding.PaddingLeft = UDim.new(0, ScreenUtils.getProportionalSize(10))
                                padding.PaddingRight = UDim.new(0, ScreenUtils.getProportionalSize(10))
                                padding.Parent = contentContainer
                                
                                -- Add layout
                                local layout = Instance.new("UIListLayout")
                                layout.FillDirection = Enum.FillDirection.Vertical
                                layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                                layout.VerticalAlignment = Enum.VerticalAlignment.Top
                                layout.Padding = UDim.new(0, ScreenUtils.getProportionalSize(5))
                                layout.Parent = contentContainer
                                
                                -- Add icon (pet model or currency)
                                if reward.type == "pet" then
                                    -- Add viewport for pet model with full loading logic
                                    local viewport = Instance.new("ViewportFrame")
                                    viewport.Name = "PetModel"
                                    viewport.Size = UDim2.new(0, ScreenUtils.getProportionalSize(80), 0, ScreenUtils.getProportionalSize(80))
                                    viewport.BackgroundTransparency = 1
                                    viewport.ZIndex = 1020
                                    viewport.Parent = contentContainer
                                    
                                    -- Load the pet model asynchronously (same logic as React component)
                                    task.spawn(function()
                                        task.wait(0.1)
                                        -- Clear existing models
                                        for _, child in pairs(viewport:GetChildren()) do
                                            if child:IsA("Model") or child:IsA("Camera") then
                                                child:Destroy()
                                            end
                                        end
                                        
                                        local petsFolder = ReplicatedStorage:FindFirstChild("Pets")
                                        if petsFolder then
                                            local petModelTemplate = petsFolder:FindFirstChild(reward.petName)
                                            if petModelTemplate then
                                                local model = petModelTemplate:Clone()
                                                model.Name = "ViewportModel"
                                                
                                                -- Set PrimaryPart
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
                                                    if largestPart then model.PrimaryPart = largestPart end
                                                end
                                                
                                                -- Prepare model
                                                for _, part in pairs(model:GetDescendants()) do
                                                    if part:IsA("BasePart") then
                                                        part.CanCollide = false
                                                        part.Anchored = true
                                                        part.Massless = true
                                                    end
                                                end
                                                
                                                -- Center and rotate model
                                                local modelCFrame, modelSize = model:GetBoundingBox()
                                                local offset = modelCFrame.Position
                                                for _, part in pairs(model:GetDescendants()) do
                                                    if part:IsA("BasePart") then
                                                        part.Position = part.Position - offset
                                                    end
                                                end
                                                
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
                                                
                                                model.Parent = viewport
                                                
                                                -- Camera setup
                                                local camera = Instance.new("Camera")
                                                camera.CameraType = Enum.CameraType.Scriptable
                                                camera.CFrame = CFrame.new(0.1, -0.15, 10)
                                                camera.FieldOfView = 90
                                                camera.Parent = viewport
                                                viewport.CurrentCamera = camera
                                                
                                                viewport.LightDirection = Vector3.new(0, -0.1, -1).Unit
                                                viewport.Ambient = Color3.fromRGB(255, 255, 255)
                                                viewport.LightColor = Color3.fromRGB(255, 255, 255)
                                            end
                                        end
                                    end)
                                else
                                    -- Add currency icon
                                    local icon = Instance.new("ImageLabel")
                                    icon.Size = UDim2.new(0, ScreenUtils.getProportionalSize(66), 0, ScreenUtils.getProportionalSize(66)) -- Match RewardCard: 66px
                                    icon.BackgroundTransparency = 1
                                    icon.Image = reward.type == "money" and "rbxassetid://80960000119108" or 
                                                (reward.type == "potion" and (function()
                                                    local potionConfig = PotionConfig and PotionConfig.GetPotion and PotionConfig.GetPotion(reward.potionId)
                                                    return potionConfig and potionConfig.Icon or "rbxassetid://118134400760699"
                                                end)() or "rbxassetid://135421873302468")
                                    icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
                                    icon.ZIndex = 1005
                                    icon.Parent = contentContainer
                                end
                                
                                -- Add reward text with green color and next level multiplier
                                local rewardText = Instance.new("TextLabel")
                                rewardText.Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(44)) -- Match RewardCard: 44px
                                rewardText.BackgroundTransparency = 1
                                rewardText.TextColor3 = Color3.fromRGB(0, 255, 0) -- Green text
                                rewardText.TextSize = ScreenUtils.TEXT_SIZES.LARGE()
                                rewardText.Font = Enum.Font.FredokaOne
                                rewardText.TextXAlignment = Enum.TextXAlignment.Center
                                rewardText.TextYAlignment = Enum.TextYAlignment.Center
                                rewardText.TextStrokeTransparency = 0
                                rewardText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                                rewardText.ZIndex = 1005
                                
                                -- Calculate next level text
                                if reward.type == "pet" then
                                    -- Calculate boost with multiplier (including ultra-rare chest)
                                    local nextLevelBoost = math.floor(reward.boost * nextLevelMultiplier)
                                    rewardText.Text = NumberFormatter.format(nextLevelBoost) .. "\nBoost!"
                                elseif reward.type == "money" then
                                    local nextLevelAmount = math.floor(reward.money * nextLevelMultiplier)
                                    rewardText.Text = NumberFormatter.format(nextLevelAmount) .. "\nMoney!"
                                elseif reward.type == "potion" then
                                    rewardText.Text = formatPotionPreviewText(reward, nextLevel)
                                else -- diamonds
                                    local nextLevelAmount = math.floor(reward.diamonds * nextLevelMultiplier)
                                    rewardText.Text = NumberFormatter.format(nextLevelAmount) .. "\nDiamonds!"
                                end
                                
                                rewardText.Parent = contentContainer
                                
                                -- Add rainbow gradient to reward text for ultra-rare chest
                                if reward.special == "black_market_rainbow_text" then
                                    local textGradient = Instance.new("UIGradient")
                                    textGradient.Parent = rewardText
                                    GradientUtils.ApplyGradient(GradientUtils.RAINBOW, textGradient)
                                end
                                
                                -- Add chance label with same styling as original (white text, not green)
                                local chanceLabel = Instance.new("TextLabel")
                                chanceLabel.Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(39)) -- Match RewardCard: 39px
                                chanceLabel.Position = UDim2.new(0, 0, 1, -ScreenUtils.getProportionalSize(39)) -- Position at bottom
                                chanceLabel.BackgroundColor3 = reward.color or Color3.fromRGB(200, 200, 200)
                                chanceLabel.BackgroundTransparency = (reward.special == "rainbow" or (reward.special == "black_market" or reward.special == "black_market_rainbow_text")) and 1 or 0
                                chanceLabel.Text = reward.special == "black_market_rainbow_text" and string.format("%.3f%%", reward.chance) or string.format("%.2f%%", reward.chance)
                                chanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text like original
                                chanceLabel.TextSize = ScreenUtils.getProportionalSize(39) -- Match RewardCard: 39px text
                                chanceLabel.Font = Enum.Font.FredokaOne
                                chanceLabel.TextXAlignment = Enum.TextXAlignment.Center
                                chanceLabel.TextScaled = true -- Match RewardCard text scaling
                                chanceLabel.TextStrokeTransparency = 0
                                chanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                                chanceLabel.ZIndex = 1004
                                chanceLabel.Parent = previewCard
                                
                                -- Add corner to chance label
                                local chanceCorner = Instance.new("UICorner")
                                chanceCorner.CornerRadius = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(8))
                                chanceCorner.Parent = chanceLabel
                            end
                        end
                    end,
                    [React.Event.MouseLeave] = function(rbx)
                        -- Only hide preview cards if they're not set to persist
                        if persistLevelPreview then 
                            return 
                        end
                        
                        
                        -- Show original cards and remove preview cards
                        local modal = rbx.Parent.Parent
                        local rewardsFrame = modal:FindFirstChild("RewardsFrame")
                        local scrollFrame = rewardsFrame and rewardsFrame:FindFirstChild("RewardsContainer")
                        
                        if scrollFrame then
                            local removedLevel = 0
                            local showedOriginal = 0
                            
                            -- Step 1: Remove all preview cards (use range instead of #rewards)
                            for i = 1, 20 do
                                local previewCard = scrollFrame:FindFirstChild("PreviewCard" .. i)
                                if previewCard then
                                    previewCard:Destroy()
                                    removedLevel = removedLevel + 1
                                end
                            end
                            
                            -- Step 2: Only show original cards if NO other preview cards exist
                            local otherPreviews = 0
                            for _, child in pairs(scrollFrame:GetChildren()) do
                                if child:IsA("Frame") and string.find(child.Name, "PreviewCard") then
                                    otherPreviews = otherPreviews + 1
                                elseif child:IsA("Frame") and string.find(child.Name, "LuckPreviewCard") then
                                    otherPreviews = otherPreviews + 1
                                end
                            end
                            
                            if otherPreviews == 0 then
                                for _, child in pairs(scrollFrame:GetChildren()) do
                                    if child:IsA("Frame") and child.LayoutOrder and not string.find(child.Name, "Preview") then
                                        child.Visible = true
                                        showedOriginal = showedOriginal + 1
                                    end
                                end
                            else
                            end
                        end
                    end,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(4)),
                    }),
                    
                    InnerStroke = React.createElement("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = ScreenUtils.getProportionalSize(2),
                        Transparency = 0,
                    }),
                    
                    ButtonOutline = React.createElement("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = ScreenUtils.getProportionalSize(3),
                        Transparency = 0,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    }),
                    
                    PriceText = React.createElement("TextLabel", {
                        Size = ScreenUtils.udim2(1, 0, 1, 0), -- Full button width
                        Position = ScreenUtils.udim2(0, 0, 0, 0), -- No left padding, text touches left outline
                        BackgroundTransparency = 1,
                        Text = "+Rewards!",
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = ScreenUtils.TEXT_SIZES.LARGE() * 2.4,
                        Font = Enum.Font.FredokaOne,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextStrokeTransparency = 0,
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        ZIndex = 1003,
                    }),
                }),
                
                -- Chest Level icon (half overlapping button edge on left side)
                ChestLevelIcon = React.createElement("ImageLabel", {
                    Size = ScreenUtils.udim2(headerIconSize, 0, headerIconSize, 0), -- 2x larger than open chest icons
                    Position = ScreenUtils.udim2(0.78 - headerIconSize/2, 0, 0.1 + 0.4 - headerIconSize/2, 0), -- Left side of button, half overlaps
                    BackgroundTransparency = 1,
                    Image = IconAssets.UI.CHEST_LEVEL,
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 1004, -- Above button
                }),
                
                -- Current Level display for Rewards button
                RewardsLevelText = React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(0.25, 0, 0.2, 0), -- Bigger size
                    Position = ScreenUtils.udim2(0.78 - 0.025, 0, 1.05, 0), -- Much lower position - beyond the UI boundary
                    BackgroundTransparency = 1,
                    Text = string.format("Rewards Level: %d", props.chestLevel or 1),
                    TextColor3 = Color3.fromRGB(255, 215, 0), -- Gold color - fits the reward/treasure theme
                    TextSize = ScreenUtils.TEXT_SIZES.SMALL() * 2.4, -- 3x bigger (0.8 * 3 = 2.4)
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 1005, -- Higher Z-index to overlay
                }),
                
                -- Luck upgrade button
                LuckButton = React.createElement("TextButton", {
                    Size = ScreenUtils.udim2(0.2, 0, 0.8, 0), -- Slightly smaller width
                    Position = ScreenUtils.udim2(0.05, 0, 0.1, 0), -- Left side position
                    BackgroundColor3 = not props.isAnimating and Color3.fromRGB(255, 165, 0) or Color3.fromRGB(150, 150, 150), -- Orange color for luck
                    Text = "",
                    BorderSizePixel = 0,
                    ZIndex = 1002,
                    [React.Event.MouseButton1Click] = not props.isAnimating and function()
                        setPersistLuckPreview(true) -- Keep preview cards visible
                        setShowLuckUpgradeModal(true)
                    end or function() end,
                    [React.Event.MouseEnter] = function(rbx)
                        if props.isAnimating then return end
                        
                        
                        local modal = rbx.Parent.Parent
                        local rewardsFrame = modal:FindFirstChild("RewardsFrame")
                        local scrollFrame = rewardsFrame and rewardsFrame:FindFirstChild("RewardsContainer")
                        
                        if scrollFrame then
                            local currentLuck = props.chestLuck or 1
                            local nextLuck = currentLuck + 1
                            local currentRewards = CrazyChestConfig.getLuckAdjustedRewards(currentLuck)
                            local nextRewards = CrazyChestConfig.getLuckAdjustedRewards(nextLuck)
                            
                            -- Step 1: Clean up ALL existing preview cards and show original cards
                            cleanupAllPreviewCards(scrollFrame, "LUCK_ENTER")
                            
                            -- Step 2: Hide all original cards (they're now visible after cleanup)
                            for _, child in pairs(scrollFrame:GetChildren()) do
                                if child:IsA("Frame") and child.LayoutOrder and not string.find(child.Name, "Preview") then
                                    child.Visible = false
                                end
                            end
                            
                            -- Step 3: Create luck preview cards
                            for i, reward in ipairs(nextRewards) do
                                local currentChance = currentRewards[i].chance
                                local nextChance = reward.chance
                                local isIncrease = nextChance - currentChance > 0
                                
                                -- Calculate dynamic width: same as RewardCard
                                local totalCards = #nextRewards
                                local cardWidthPercent = 0.8 / totalCards
                                
                                local previewCard = Instance.new("Frame")
                                previewCard.Name = "LuckPreviewCard" .. i
                                previewCard.Size = UDim2.new(cardWidthPercent, 0, 0, ScreenUtils.getProportionalSize(176)) -- Match RewardCard dimensions
                                previewCard.BackgroundColor3 = reward.color or Color3.fromRGB(255, 255, 255)
                                previewCard.BackgroundTransparency = (reward.special == "rainbow" or reward.special == "black_market" or reward.special == "black_market_rainbow_text") and 0.3 or 0.7
                                previewCard.BorderSizePixel = 0
                                previewCard.LayoutOrder = i
                                previewCard.ZIndex = 1003
                                previewCard.Parent = scrollFrame
                                
                                local corner = Instance.new("UICorner")
                                corner.CornerRadius = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(8))
                                corner.Parent = previewCard
                                if reward.special == "rainbow" then
                                    local gradient = Instance.new("UIGradient")
                                    gradient.Parent = previewCard
                                    GradientUtils.ApplyGradient(GradientUtils.RAINBOW_DIAGONAL, gradient)
                                elseif reward.special == "black_market" or reward.special == "black_market_rainbow_text" then
                                    local gradient = Instance.new("UIGradient")
                                    gradient.Parent = previewCard
                                    GradientUtils.ApplyGradient(GradientUtils.BLACK_MARKET, gradient)
                                end
                                
                                local stroke = Instance.new("UIStroke")
                                stroke.Color = reward.color or Color3.fromRGB(200, 200, 200)
                                stroke.Thickness = ScreenUtils.getProportionalSize(4)
                                stroke.Parent = previewCard
                                if reward.special == "rainbow" then
                                    local strokeGradient = Instance.new("UIGradient")
                                    strokeGradient.Parent = stroke
                                    GradientUtils.ApplyGradient(GradientUtils.RAINBOW_DIAGONAL, strokeGradient)
                                elseif reward.special == "black_market" or reward.special == "black_market_rainbow_text" then
                                    local strokeGradient = Instance.new("UIGradient")
                                    strokeGradient.Parent = stroke
                                    GradientUtils.ApplyGradient(GradientUtils.BLACK_MARKET, strokeGradient)
                                end
                                
                                local contentContainer = Instance.new("Frame")
                                contentContainer.Size = UDim2.new(1, -ScreenUtils.getProportionalSize(22), 1, -ScreenUtils.getProportionalSize(39)) -- Leave space for 39px chance label
                                contentContainer.Position = UDim2.new(0, ScreenUtils.getProportionalSize(11), 0, ScreenUtils.getProportionalSize(11)) -- Match RewardCard padding: 11px
                                contentContainer.BackgroundTransparency = 1
                                contentContainer.ZIndex = 1004
                                contentContainer.Parent = previewCard
                                if reward.type == "pet" then
                                    local viewport = Instance.new("ViewportFrame")
                                    viewport.Size = UDim2.new(0, ScreenUtils.getProportionalSize(88), 0, ScreenUtils.getProportionalSize(88)) -- Match RewardCard: 88px
                                    viewport.Position = UDim2.new(0.5, -ScreenUtils.getProportionalSize(44), 0, ScreenUtils.getProportionalSize(11)) -- Match RewardCard positioning
                                    viewport.BackgroundTransparency = 1
                                    viewport.ZIndex = 1025
                                    viewport.Parent = previewCard
                                    
                                    task.spawn(function()
                                        task.wait(0.1)
                                        local petsFolder = ReplicatedStorage:FindFirstChild("Pets")
                                        if petsFolder then
                                            local petModelTemplate = petsFolder:FindFirstChild(reward.petName)
                                            if petModelTemplate then
                                                local model = petModelTemplate:Clone()
                                                model.Name = "PetModel"
                                                
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
                                                
                                                for _, part in pairs(model:GetDescendants()) do
                                                    if part:IsA("BasePart") then
                                                        part.CanCollide = false
                                                        part.Anchored = true
                                                        part.Massless = true
                                                    end
                                                end
                                                
                                                local modelCFrame, modelSize = model:GetBoundingBox()
                                                local offset = modelCFrame.Position
                                                for _, part in pairs(model:GetDescendants()) do
                                                    if part:IsA("BasePart") then
                                                        part.Position = part.Position - offset
                                                    end
                                                end
                                                
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
                                                
                                                model.Parent = viewport
                                                
                                                local camera = Instance.new("Camera")
                                                camera.CameraType = Enum.CameraType.Scriptable
                                                camera.CFrame = CFrame.new(0.1, -0.15, 10)
                                                camera.FieldOfView = 90
                                                camera.Parent = viewport
                                                viewport.CurrentCamera = camera
                                                
                                                viewport.LightDirection = Vector3.new(0, -0.1, -1).Unit
                                                viewport.Ambient = Color3.fromRGB(255, 255, 255)
                                                viewport.LightColor = Color3.fromRGB(255, 255, 255)
                                            end
                                        end
                                    end)
                                else
                                    local icon = Instance.new("ImageLabel")
                                    icon.Size = UDim2.new(0, ScreenUtils.getProportionalSize(66), 0, ScreenUtils.getProportionalSize(66)) -- Match RewardCard: 66px
                                    icon.BackgroundTransparency = 1
                                    icon.Image = reward.type == "money" and "rbxassetid://80960000119108" or 
                                                (reward.type == "potion" and (function()
                                                    local potionConfig = PotionConfig and PotionConfig.GetPotion and PotionConfig.GetPotion(reward.potionId)
                                                    return potionConfig and potionConfig.Icon or "rbxassetid://118134400760699"
                                                end)() or "rbxassetid://135421873302468")
                                    icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
                                    icon.ZIndex = 1005
                                    icon.Parent = contentContainer
                                end
                                
                                local rewardText = Instance.new("TextLabel")
                                rewardText.Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(44)) -- Match RewardCard: 44px
                                rewardText.Position = UDim2.new(0, 0, 0, ScreenUtils.getProportionalSize(85))
                                rewardText.BackgroundTransparency = 1
                                rewardText.TextColor3 = Color3.fromRGB(255, 255, 255)
                                rewardText.TextSize = ScreenUtils.TEXT_SIZES.LARGE()
                                rewardText.Font = Enum.Font.FredokaOne
                                rewardText.TextXAlignment = Enum.TextXAlignment.Center
                                rewardText.TextYAlignment = Enum.TextYAlignment.Center
                                rewardText.TextStrokeTransparency = 0
                                rewardText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                                rewardText.ZIndex = 1005
                                if reward.type == "pet" then
                                    -- Calculate boost with multiplier (including ultra-rare chest)
                                    local boostAmount = math.floor(reward.boost * (props.rewardMultiplier or 1))
                                    rewardText.Text = NumberFormatter.format(boostAmount) .. "\nBoost!"
                                elseif reward.type == "money" then
                                    local amount = math.floor(reward.money * (props.rewardMultiplier or 1))
                                    rewardText.Text = NumberFormatter.format(amount) .. "\nMoney!"
                                elseif reward.type == "potion" then
                                    rewardText.Text = formatPotionRewardText(reward, props.rewardMultiplier or 1)
                                else -- diamonds
                                    local amount = math.floor(reward.diamonds * (props.rewardMultiplier or 1))
                                    rewardText.Text = NumberFormatter.format(amount) .. "\nDiamonds!"
                                end
                                
                                rewardText.Parent = previewCard
                                
                                -- Add rainbow gradient to reward text for ultra-rare chest
                                if reward.special == "black_market_rainbow_text" then
                                    local textGradient = Instance.new("UIGradient")
                                    textGradient.Parent = rewardText
                                    GradientUtils.ApplyGradient(GradientUtils.RAINBOW, textGradient)
                                end
                                
                                local chanceLabel = Instance.new("TextLabel")
                                chanceLabel.Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(39)) -- Match RewardCard: 39px
                                chanceLabel.Position = UDim2.new(0, 0, 1, -ScreenUtils.getProportionalSize(39)) -- Position at bottom
                                chanceLabel.BackgroundColor3 = reward.color or Color3.fromRGB(200, 200, 200)
                                chanceLabel.BackgroundTransparency = (reward.special == "rainbow" or (reward.special == "black_market" or reward.special == "black_market_rainbow_text")) and 1 or 0
                                chanceLabel.Text = reward.special == "black_market_rainbow_text" and string.format("%.3f%%", nextChance) or string.format("%.2f%%", nextChance)
                                chanceLabel.TextColor3 = isIncrease and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                                chanceLabel.TextSize = ScreenUtils.getProportionalSize(39) -- Match RewardCard: 39px text
                                chanceLabel.Font = Enum.Font.FredokaOne
                                chanceLabel.TextXAlignment = Enum.TextXAlignment.Center
                                chanceLabel.TextScaled = true -- Match RewardCard text scaling
                                chanceLabel.TextStrokeTransparency = 0
                                chanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                                chanceLabel.ZIndex = 1004
                                chanceLabel.Parent = previewCard
                                
                                local chanceCorner = Instance.new("UICorner")
                                chanceCorner.CornerRadius = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(8))
                                chanceCorner.Parent = chanceLabel
                            end
                        end
                    end,
                    [React.Event.MouseLeave] = function(rbx)
                        -- Only hide preview cards if they're not set to persist
                        if persistLuckPreview then 
                            return 
                        end
                        
                        
                        local modal = rbx.Parent.Parent
                        local rewardsFrame = modal:FindFirstChild("RewardsFrame")
                        local scrollFrame = rewardsFrame and rewardsFrame:FindFirstChild("RewardsContainer")
                        
                        if scrollFrame then
                            local removedLuck = 0
                            local showedOriginal = 0
                            
                            for _, child in pairs(scrollFrame:GetChildren()) do
                                if child:IsA("Frame") and string.find(child.Name, "LuckPreviewCard") then
                                    child:Destroy()
                                    removedLuck = removedLuck + 1
                                end
                            end
                            
                            -- Only show original cards if NO other preview cards exist
                            local otherPreviews = 0
                            for _, child in pairs(scrollFrame:GetChildren()) do
                                if child:IsA("Frame") and string.find(child.Name, "PreviewCard") then
                                    otherPreviews = otherPreviews + 1
                                elseif child:IsA("Frame") and string.find(child.Name, "LuckPreviewCard") then
                                    otherPreviews = otherPreviews + 1
                                end
                            end
                            
                            if otherPreviews == 0 then
                                for _, child in pairs(scrollFrame:GetChildren()) do
                                    if child:IsA("Frame") and child.LayoutOrder and not string.find(child.Name, "Preview") then
                                        child.Visible = true
                                        showedOriginal = showedOriginal + 1
                                    end
                                end
                            else
                            end
                        end
                    end,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(4)),
                    }),
                    
                    InnerStroke = React.createElement("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = ScreenUtils.getProportionalSize(2),
                        Transparency = 0,
                    }),
                    
                    ButtonOutline = React.createElement("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = ScreenUtils.getProportionalSize(3),
                        Transparency = 0,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    }),
                    
                    PriceText = React.createElement("TextLabel", {
                        Size = ScreenUtils.udim2(1, 0, 1, 0), -- Full button width
                        Position = ScreenUtils.udim2(0, 0, 0, 0), -- No left padding, text touches left outline
                        BackgroundTransparency = 1,
                        Text = "+Luck!",
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = ScreenUtils.TEXT_SIZES.LARGE() * 2.4,
                        Font = Enum.Font.FredokaOne,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextStrokeTransparency = 0,
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        ZIndex = 1003,
                    }),
                }),
                
                -- Luck icon (half overlapping button edge on left side)
                LuckIcon = React.createElement("ImageLabel", {
                    Size = ScreenUtils.udim2(headerIconSize, 0, headerIconSize, 0), -- 2x larger than open chest icons
                    Position = ScreenUtils.udim2(0.05 - headerIconSize/2, 0, 0.1 + 0.4 - headerIconSize/2, 0), -- Left side of button, half overlaps
                    BackgroundTransparency = 1,
                    Image = IconAssets.UI.LUCK,
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 1004, -- Above button
                }),
                
                -- Current Level display for Luck button
                LuckLevelText = React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(0.25, 0, 0.2, 0), -- Bigger size
                    Position = ScreenUtils.udim2(0.05 - 0.025, 0, 1.05, 0), -- Much lower position - beyond the UI boundary
                    BackgroundTransparency = 1,
                    Text = string.format("Luck Level: %d", props.chestLuck or 1),
                    TextColor3 = Color3.fromRGB(50, 205, 50), -- Lime green - perfect for luck theme
                    TextSize = ScreenUtils.TEXT_SIZES.SMALL() * 2.4, -- 3x bigger (0.8 * 3 = 2.4)
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 1005, -- Higher Z-index to overlay
                }),
            }),
            
            
            
            -- Top Section: Rewards as horizontal scrolling cards like PlaytimeRewards
            RewardsFrame = React.createElement("Frame", {
                Size = ScreenUtils.udim2(1, -ScreenUtils.getProportionalSize(40), 0.28, 0), -- 28% of modal height (reduced to give button more space)
                Position = ScreenUtils.udim2(0, ScreenUtils.getProportionalSize(20), 0.12, 0), -- 12% from top (moved up since we removed cost frame)
                BackgroundColor3 = Color3.fromRGB(255, 255, 255), -- White background to match main UI
                BorderSizePixel = 0,
                ZIndex = 1001,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(10)),
                }),
                
                -- Title for rewards section
                RewardsTitle = React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(1, 0, 0, ScreenUtils.getProportionalSize(30)),
                    Position = ScreenUtils.udim2(0, 0, 0, ScreenUtils.getProportionalSize(5)),
                    BackgroundTransparency = 1,
                    Text = "🎁 POSSIBLE REWARDS",
                    TextColor3 = Color3.fromRGB(60, 60, 60),
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 1002,
                }),
                
                -- Simple container frame for dynamic number of cards
                RewardsContainer = React.createElement("Frame", {
                    Size = ScreenUtils.udim2(1, -ScreenUtils.getProportionalSize(20), 1, -ScreenUtils.getProportionalSize(40)), -- Leave some padding
                    Position = ScreenUtils.udim2(0, ScreenUtils.getProportionalSize(10), 0, ScreenUtils.getProportionalSize(35)), -- Centered
                    BackgroundTransparency = 1, -- Transparent container
                    ZIndex = 1002,
                }, {
                    -- Horizontal layout for cards - ALWAYS CENTER ALIGNMENT
                    Layout = React.createElement("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center, -- ALWAYS CENTER - this is required
                        VerticalAlignment = Enum.VerticalAlignment.Center, -- Center vertically
                        Padding = UDim.new(math.max(0.01, 0.03 / (rewards and #rewards or 8)), 0), -- Slightly more padding between cards
                    }),
                
                -- Create reward cards like PlaytimeRewards
                RewardCards = React.createElement(React.Fragment, nil, (function()
                    local cards = {}
                    
                    -- Safety check for rewards
                    if not rewards or #rewards == 0 then
                        cards[1] = React.createElement("TextLabel", {
                            Size = ScreenUtils.udim2(0, ScreenUtils.getProportionalSize(200), 1, 0),
                            BackgroundTransparency = 1,
                            Text = "Loading rewards...",
                            TextColor3 = Color3.fromRGB(150, 150, 150),
                            TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                            Font = Enum.Font.FredokaOne,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            LayoutOrder = 1,
                            ZIndex = 1003,
                        })
                        return cards
                    end
                    
                    for i, reward in ipairs(rewards) do
                        cards[i] = RewardCard({
                            reward = reward,
                            layoutOrder = i,
                            totalCards = #rewards, -- Pass total number of cards for dynamic sizing
                            rewardMultiplier = props.rewardMultiplier or 1, -- Pass the chest level multiplier
                            -- Rainbow cards use transparent background to show main card rainbow, others use solid
                            isChanceBackgroundTransparent = (reward.special == "rainbow" or (reward.special == "black_market" or reward.special == "black_market_rainbow_text")),
                        })
                    end
                    
                    return cards
                end)()),
                }),
            }),
            
            -- Case Opening Animation Section (bottom half) - with pre-populated cards
            CaseOpeningSection = React.createElement("Frame", {
                Name = "CaseOpeningSection",
                Size = ScreenUtils.udim2(1, -ScreenUtils.getProportionalSize(40), 0.25, 0), -- Reduced to 25% of modal height
                Position = ScreenUtils.udim2(0, ScreenUtils.getProportionalSize(20), 0.48, 0), -- Adjusted position
                BackgroundColor3 = Color3.fromRGB(255, 255, 255), -- White background to match main UI
                BorderSizePixel = 0,
                ZIndex = 1001,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(10)),
                }),
                
            }, CrazyChestUI.createStaticRewardStrip(rewards, props.rewardMultiplier or 1, props.chestLuck)),
            
            -- Open Chest section with dual buttons
            OpenChestSection = React.createElement("Frame", {
                Size = ScreenUtils.udim2(1, -ScreenUtils.getProportionalSize(40), 0.15, 0), -- 15% height for two buttons
                Position = ScreenUtils.udim2(0, ScreenUtils.getProportionalSize(20), 0.78, 0), -- 78% from top (more space)
                BackgroundTransparency = 1,
                ZIndex = 1001,
            }, {
                -- "Open Chest!" title
                OpenChestTitle = React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(1, 0, 0.25, 0),
                    Position = ScreenUtils.udim2(0, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "Open Chest!",
                    TextColor3 = Color3.fromRGB(76, 175, 80), -- Green text
                    TextSize = ScreenUtils.TEXT_SIZES.LARGE() * 1.5,
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0), -- Black outline
                    ZIndex = 1002,
                }),
                
                -- Robux button (dynamic width)
                RobuxButton = React.createElement("TextButton", {
                    Size = ScreenUtils.udim2(robuxOpenTextWidth, 0, 0.4, 0), -- Larger height to match reference
                    Position = ScreenUtils.udim2(0.25 - robuxOpenTextWidth/2, 0, 0.32, 0), -- Centered at 25%
                    BackgroundColor3 = robuxButtonEnabled and Color3.fromRGB(0, 176, 111) or Color3.fromRGB(150, 150, 150),
                    Text = "",
                    BorderSizePixel = 0,
                    ZIndex = 1002,
                    [React.Event.MouseButton1Click] = robuxButtonEnabled and handleOpenChestRobux or function() end,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(4)),
                    }),
                    
                    InnerStroke = React.createElement("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = ScreenUtils.getProportionalSize(2),
                        Transparency = 0,
                    }),
                    
                    ButtonOutline = React.createElement("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = ScreenUtils.getProportionalSize(3),
                        Transparency = 0,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    }),
                    
                    PriceText = React.createElement("TextLabel", {
                        Size = ScreenUtils.udim2(0.65, 0, 1, 0), -- Text area (increased from 0.525)
                        Position = ScreenUtils.udim2(0.3, 0, 0, 0), -- Left padding for icon space (reduced from 0.375)
                        BackgroundTransparency = 1,
                        Text = robuxOpenText,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = ScreenUtils.TEXT_SIZES.LARGE() * 2.4,
                        Font = Enum.Font.FredokaOne,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextStrokeTransparency = 0,
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        ZIndex = 1003,
                    }),
                    
                    -- "BEST VALUE!" text above button with breathing animation
                    BestValueText = React.createElement("TextLabel", {
                        Size = ScreenUtils.udim2(1 * (breatheScale or 1), 0, 0.4 * (breatheScale or 1), 0), -- Breathing size, relative to button
                        Position = ScreenUtils.udim2(0, 0, -0.5, 0), -- Above button (negative Y position)
                        BackgroundTransparency = 1,
                        Text = "BEST VALUE!",
                        TextColor3 = Color3.fromRGB(255, 215, 0),
                        TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() * 1.3,
                        Font = Enum.Font.FredokaOne,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextStrokeTransparency = 0,
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        ZIndex = 1005,
                    }),
                }),
                
                -- Robux icon (half overlapping button edge)
                RobuxIcon = React.createElement("ImageLabel", {
                    Size = ScreenUtils.udim2(openIconSize, 0, openIconSize, 0),
                    Position = ScreenUtils.udim2(0.25 - robuxOpenTextWidth/2 - openIconSize/2, 0, 0.32 + 0.2 - openIconSize/2, 0), -- Half overlaps button
                    BackgroundTransparency = 1,
                    Image = IconAssets.CURRENCY.ROBUX,
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 1004, -- Above button
                }),
                
                -- "OR" separator
                OrText = React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(0.1, 0, 0.25, 0),
                    Position = ScreenUtils.udim2(0.45, 0, 0.375, 0), -- Centered between buttons
                    BackgroundTransparency = 1,
                    Text = "OR",
                    TextColor3 = Color3.fromRGB(150, 150, 150),
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() * 1.2,
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 1003,
                }),
                
                -- Diamond button (dynamic width)
                DiamondButton = React.createElement("TextButton", {
                    Size = ScreenUtils.udim2(diamondOpenTextWidth, 0, 0.4, 0), -- Larger height to match reference
                    Position = ScreenUtils.udim2(0.75 - diamondOpenTextWidth/2, 0, 0.32, 0), -- Centered at 75%
                    BackgroundColor3 = diamondButtonEnabled and Color3.fromRGB(64, 224, 208) or Color3.fromRGB(150, 150, 150),
                    Text = "",
                    BorderSizePixel = 0,
                    ZIndex = 1002,
                    [React.Event.MouseButton1Click] = diamondButtonEnabled and handleOpenChestDiamonds or function() end,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(4)),
                    }),
                    
                    InnerStroke = React.createElement("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = ScreenUtils.getProportionalSize(2),
                        Transparency = 0,
                    }),
                    
                    ButtonOutline = React.createElement("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = ScreenUtils.getProportionalSize(3),
                        Transparency = 0,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    }),
                    
                    PriceText = React.createElement("TextLabel", {
                        Size = ScreenUtils.udim2(0.65, 0, 1, 0), -- Text area (increased from 0.525)
                        Position = ScreenUtils.udim2(0.3, 0, 0, 0), -- Left padding for icon space (reduced from 0.375)
                        BackgroundTransparency = 1,
                        Text = diamondOpenText,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = ScreenUtils.TEXT_SIZES.LARGE() * 2.4,
                        Font = Enum.Font.FredokaOne,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextStrokeTransparency = 0,
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        ZIndex = 1003,
                    }),
                }),
                
                -- Diamond icon (half overlapping button edge)
                DiamondIcon = React.createElement("ImageLabel", {
                    Size = ScreenUtils.udim2(openIconSize, 0, openIconSize, 0),
                    Position = ScreenUtils.udim2(0.75 - diamondOpenTextWidth/2 - openIconSize/2, 0, 0.32 + 0.2 - openIconSize/2, 0), -- Half overlaps button
                    BackgroundTransparency = 1,
                    Image = IconAssets.CURRENCY.DIAMONDS,
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 1004, -- Above button
                }),
            }),
        }),
        
        -- Level upgrade modal
        showLevelUpgradeModal and createCleanPurchaseModal({
            upgradeType = "level",
            diamondCost = props.upgradeCost or 100,
            currentLevel = props.chestLevel or 1,
            canAffordDiamonds = props.canUpgrade,
            robuxPrice = levelRobuxPrice,
            breatheScale = breatheScale,
            onClose = function() 
                -- Clear persistence state first so MouseLeave logic works
                setPersistLevelPreview(false)
                -- Restore cards WHILE modal is still open and DOM exists
                forceRestoreOriginalCards()
                -- Now close the modal  
                setShowLevelUpgradeModal(false)
            end,
            onPurchaseDiamonds = handleLevelPurchaseDiamonds,
            onPurchaseRobux = handleLevelPurchaseRobux,
        }) or nil,
        
        -- Luck upgrade modal
        showLuckUpgradeModal and createCleanPurchaseModal({
            upgradeType = "luck", 
            diamondCost = props.luckUpgradeCost or 500,
            currentLevel = props.chestLuck or 1,
            canAffordDiamonds = props.canUpgradeLuck,
            robuxPrice = luckRobuxPrice,
            breatheScale = breatheScale,
            onClose = function() 
                -- Clear persistence state first so MouseLeave logic works
                setPersistLuckPreview(false)
                -- Restore cards WHILE modal is still open and DOM exists
                forceRestoreOriginalCards()
                -- Now close the modal
                setShowLuckUpgradeModal(false)
            end,
            onPurchaseDiamonds = handleLuckPurchaseDiamonds,
            onPurchaseRobux = handleLuckPurchaseRobux,
        }) or nil,
    })
end

return CrazyChestUI