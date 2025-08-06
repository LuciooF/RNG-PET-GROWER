-- CrazyChestUI - Simple chest info interface
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.react)

local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)

-- Wait for config to be available
local configFolder = ReplicatedStorage:WaitForChild("config", 10)
local CrazyChestConfig = configFolder and require(configFolder.CrazyChestConfig) or nil

local CrazyChestUI = {}

-- Cache for created cards to prevent recreation during animation
local cardCache = nil
local lastRewardsKey = nil

-- Reusable RewardCard component for static reward display (top section)
local function RewardCard(props)
    local reward = props.reward
    local layoutOrder = props.layoutOrder
    local isChanceBackgroundTransparent = props.isChanceBackgroundTransparent or false
    
    return React.createElement("Frame", {
        Size = ScreenUtils.udim2(0, ScreenUtils.getProportionalSize(130), 1, -ScreenUtils.getProportionalSize(10)),
        BackgroundColor3 = reward.color or Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = reward.special == "rainbow" and 0.3 or 0.7,
        BorderSizePixel = 0,
        LayoutOrder = layoutOrder,
        ZIndex = 1003,
    }, {
        -- Rounded corners
        Corner = React.createElement("UICorner", {
            CornerRadius = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(8)),
        }),
        
        -- Rainbow gradient background
        reward.special == "rainbow" and React.createElement("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 127, 0)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 0, 211))
            }),
            Rotation = 45
        }) or nil,
        
        -- Colored border
        ColorOutline = React.createElement("UIStroke", {
            Color = reward.color or Color3.fromRGB(200, 200, 200),
            Thickness = ScreenUtils.getProportionalSize(4),
        }, {
            reward.special == "rainbow" and React.createElement("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 127, 0)),
                    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
                    ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
                    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 0, 211))
                }),
                Rotation = 45
            }) or nil,
        }),
        
        -- Content container
        ContentContainer = React.createElement("Frame", {
            Size = UDim2.new(1, 0, 1, -ScreenUtils.getProportionalSize(55)),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            ZIndex = 1004,
        }, {
            -- Padding
            Padding = React.createElement("UIPadding", {
                PaddingTop = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(10)),
                PaddingBottom = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(10)),
                PaddingLeft = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(10)),
                PaddingRight = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(10)),
            }),
            
            -- Layout
            Layout = React.createElement("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Top,
                Padding = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(5)),
            }),
            
            -- Pet model or currency icon
            reward.type == "pet" and React.createElement("ViewportFrame", {
                Name = "PetModel",
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(80), 0, ScreenUtils.getProportionalSize(80)),
                BackgroundTransparency = 1,
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
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(60), 0, ScreenUtils.getProportionalSize(60)),
                BackgroundTransparency = 1,
                Image = reward.type == "money" and "rbxassetid://80960000119108" or "rbxassetid://135421873302468",
                ImageColor3 = Color3.fromRGB(255, 255, 255),
                LayoutOrder = 1,
                ZIndex = 1005,
            }),
            
            -- Reward text - formatted on two lines with larger text
            RewardText = React.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(40)), -- Taller for two lines
                BackgroundTransparency = 1,
                -- Format text on two lines: "500\nDiamonds!" or "5x\nBoost!"
                Text = reward.type == "pet" and (reward.boost .. "x\nBoost!") or 
                       (reward.type == "money" and (NumberFormatter.format(reward.money) .. "\nMoney!") or 
                       (NumberFormatter.format(reward.diamonds) .. "\nDiamonds!")),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = ScreenUtils.TEXT_SIZES.LARGE(), -- 50% bigger - upgraded from MEDIUM to LARGE
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center, -- Center vertically for two lines
                TextScaled = false, -- Turn off scaling for consistent size
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                LayoutOrder = 2,
                ZIndex = 1005,
            }),
            
            -- Pet name for pets
            reward.type == "pet" and React.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(20)),
                BackgroundTransparency = 1,
                Text = reward.petName,
                TextColor3 = Color3.fromRGB(100, 100, 100),
                TextSize = ScreenUtils.TEXT_SIZES.SMALL(),
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextScaled = true,
                LayoutOrder = 3,
                ZIndex = 1005,
            }) or nil,
        }),
        
        -- CONSISTENT PERCENTAGE TEXT FOR ALL CARDS - THIS IS THE KEY FIX
        ChanceLabel = React.createElement("TextLabel", {
            Size = ScreenUtils.udim2(1, 0, 0, ScreenUtils.getProportionalSize(55)),
            Position = ScreenUtils.udim2(0, 0, 1, -ScreenUtils.getProportionalSize(55)),
            -- Use transparency to inherit main card background or solid color
            BackgroundColor3 = reward.color or Color3.fromRGB(200, 200, 200),
            BackgroundTransparency = isChanceBackgroundTransparent and 1 or 0, -- Transparent inherits main background
            Text = reward.chance .. "%",
            -- ALWAYS WHITE TEXT - no exceptions, no conditions, no inheritance
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = ScreenUtils.TEXT_SIZES.HEADER(),
            Font = Enum.Font.FredokaOne,
            TextXAlignment = Enum.TextXAlignment.Center,
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
    
    -- Create reward text for animation cards - same two-line format as RewardCard
    local rewardText = reward.type == "pet" and (reward.boost .. "x\nBoost!") or 
                      (reward.type == "money" and (NumberFormatter.format(reward.money) .. "\nMoney!") or 
                      (NumberFormatter.format(reward.diamonds) .. "\nDiamonds!"))
    
    return React.createElement("Frame", {
        Name = "RewardItem" .. position,
        Size = UDim2.new(0, itemWidth, 1, 0),
        Position = UDim2.new(0, (position-1) * (itemWidth + itemSpacing), 0, 0),
        BackgroundColor3 = reward.color or Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = reward.special == "rainbow" and 0.3 or 0.7,
        BorderSizePixel = 0,
        ZIndex = 1011,
    }, {
        Corner = React.createElement("UICorner", {
            CornerRadius = ScreenUtils.udim(0, 8),
        }),
        
        -- Rainbow gradient background
        reward.special == "rainbow" and React.createElement("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 127, 0)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 0, 211))
            }),
            Rotation = 45
        }) or nil,
        
        -- Thick border
        Stroke = React.createElement("UIStroke", {
            Color = reward.color or Color3.fromRGB(200, 200, 200),
            Thickness = ScreenUtils.getProportionalSize(4),
        }, {
            reward.special == "rainbow" and React.createElement("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 127, 0)),
                    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
                    ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
                    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 0, 211))
                }),
                Rotation = 45
            }) or nil,
        }),
        
        -- Pet model or currency icon
        reward.type == "pet" and React.createElement("ViewportFrame", {
            Name = "PetModel",
            Size = UDim2.new(0, ScreenUtils.getProportionalSize(70), 0, ScreenUtils.getProportionalSize(70)),
            Position = UDim2.new(0.5, -ScreenUtils.getProportionalSize(35), 0, ScreenUtils.getProportionalSize(15)),
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
            Size = UDim2.new(0, ScreenUtils.getProportionalSize(60), 0, ScreenUtils.getProportionalSize(60)),
            Position = UDim2.new(0.5, -ScreenUtils.getProportionalSize(30), 0, ScreenUtils.getProportionalSize(20)),
            BackgroundTransparency = 1,
            Image = reward.type == "money" and "rbxassetid://80960000119108" or "rbxassetid://135421873302468",
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            ZIndex = 1012,
        }),
        
        -- Reward text - same formatting as RewardCard (two lines, large text)
        RewardText = React.createElement("TextLabel", {
            Size = UDim2.new(1, -10, 0, ScreenUtils.getProportionalSize(40)),
            Position = UDim2.new(0, 5, 1, -ScreenUtils.getProportionalSize(50)),
            BackgroundTransparency = 1,
            Text = rewardText,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = ScreenUtils.TEXT_SIZES.LARGE(), -- Same large size as RewardCard
            Font = Enum.Font.FredokaOne,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center, -- Center vertically for two lines
            TextScaled = false, -- No scaling for consistent size
            TextStrokeTransparency = 0,
            TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = 1012,
        })
    })
end

-- Create static reward strip that shows all the time (before animation)  
function CrazyChestUI.createStaticRewardStrip(rewards)
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
    
    -- Create a unique key for rewards to check if they changed
    local rewardsKey = ""
    for i, reward in ipairs(rewards) do
        rewardsKey = rewardsKey .. (reward.type or "") .. (reward.money or reward.diamonds or 0) .. "_"
    end
    
    -- Only recreate cards if rewards actually changed
    if cardCache and lastRewardsKey == rewardsKey then
        -- Silently return cached cards for better performance
        return cardCache
    end
    
    print("CrazyChestUI: Creating", totalItems, "reward cards (rewards changed)")
    lastRewardsKey = rewardsKey
    
    local cardElements = {
        Corner = React.createElement("UICorner", {
            CornerRadius = ScreenUtils.udim(0, 15),
        }),
        
        -- Selection indicator (the line that shows where the result will land)
        SelectionIndicator = React.createElement("Frame", {
            Name = "SelectionIndicator",
            Size = ScreenUtils.udim2(0, 4, 1, -ScreenUtils.getProportionalSize(80)),
            Position = ScreenUtils.udim2(0.5, -2, 0, ScreenUtils.getProportionalSize(40)),
            BackgroundColor3 = Color3.fromRGB(255, 215, 0), -- Gold like PlaytimeRewards claimed color
            BorderSizePixel = 0,
            ZIndex = 1013, -- Highest z-index to be above cards
        }, {
            -- Add glow effect to selection line
            Glow = React.createElement("UIStroke", {
                Color = Color3.fromRGB(255, 215, 0),
                Thickness = ScreenUtils.getProportionalSize(2),
                Transparency = 0.3,
            }),
        }),
        
        -- Scrolling container for rewards (static initially) with proper padding
        RewardStrip = React.createElement("ScrollingFrame", {
            Name = "RewardStrip", 
            Size = ScreenUtils.udim2(1, -ScreenUtils.getProportionalSize(60), 1, -ScreenUtils.getProportionalSize(140)), -- More padding
            Position = ScreenUtils.udim2(0, ScreenUtils.getProportionalSize(30), 0, ScreenUtils.getProportionalSize(90)), -- More padding
            BackgroundColor3 = Color3.fromRGB(248, 248, 248), -- Light grey like PlaytimeRewards
            BackgroundTransparency = 0,
            ScrollBarThickness = 0,
            ScrollingEnabled = false,
            CanvasSize = UDim2.new(0, totalItems * (itemWidth + itemSpacing), 0, 0),
            ZIndex = 1010, -- Higher than modal content
        }, (function()
            local elements = CrazyChestUI.createRewardCards(rewards, totalItems, itemWidth, itemSpacing)
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
function CrazyChestUI.createRewardCards(rewards, totalItems, itemWidth, itemSpacing)
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
        })
    end
    
    return cards
end

function CrazyChestUI.new(props)
    -- Don't render if not visible or config not available
    if not props.visible or not CrazyChestConfig then
        return nil
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
    local rewards = CrazyChestConfig and CrazyChestConfig.REWARDS or {}
    local isAnimating = props.isAnimating or false
    local isRewarding = props.isRewarding or false
    
    -- Button state with animation awareness
    local buttonText, buttonColor, buttonEnabled
    if isAnimating then
        buttonText = "Opening..."
        buttonColor = Color3.fromRGB(120, 120, 120) -- Greyed out
        buttonEnabled = false
    elseif isRewarding then
        buttonText = "Rewarding..."
        buttonColor = Color3.fromRGB(120, 120, 120) -- Greyed out
        buttonEnabled = false
    elseif not canAfford then
        buttonText = "NOT ENOUGH 💎"
        buttonColor = Color3.fromRGB(120, 120, 120)
        buttonEnabled = false
    else
        buttonText = "OPEN CHEST"
        buttonColor = Color3.fromRGB(100, 200, 100)
        buttonEnabled = true
    end
    
    -- Handle chest opening
    local function handleOpenChest()
        if not buttonEnabled then 
            print("CrazyChestUI: Button disabled, ignoring click")
            return 
        end
        
        print("CrazyChestUI: handleOpenChest called")
        
        -- Trigger the chest opening on server
        if props.onOpenChest then
            props.onOpenChest()
        end
    end
    
    -- Create click-outside-to-close overlay
    return React.createElement("TextButton", {
        Name = "CrazyChestUIOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        Text = "",
        ZIndex = 999,
        [React.Event.MouseButton1Click] = props.onClose,
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
                    CornerRadius = ScreenUtils.udim(0, 15)
                }),
                
                Title = React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "🎰 MYSTERY CHEST",
                    TextColor3 = Color3.fromRGB(0, 0, 0),
                    TextSize = ScreenUtils.TEXT_SIZES.HEADER(),
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 1002,
                }),
            }),
            
            -- Cost display
            CostFrame = React.createElement("Frame", {
                Size = ScreenUtils.udim2(1, -40, 0.08, 0), -- 8% of modal height, responsive padding
                Position = ScreenUtils.udim2(0, 20, 0.12, 0), -- 12% from top
                BackgroundColor3 = Color3.fromRGB(248, 248, 248), -- Light grey like PlaytimeRewards
                BorderSizePixel = 0,
                ZIndex = 1001,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 10),
                }),
                
                CostLabel = React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "Cost: 💎 " .. NumberFormatter.format(cost),
                    TextColor3 = canAfford and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100),
                    TextSize = ScreenUtils.TEXT_SIZES.LARGE(),
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 1002,
                }),
            }),
            
            -- Top Section: Rewards as horizontal scrolling cards like PlaytimeRewards
            RewardsFrame = React.createElement("Frame", {
                Size = ScreenUtils.udim2(1, -40, 0.32, 0), -- 32% of modal height
                Position = ScreenUtils.udim2(0, 20, 0.2, 0), -- 20% from top
                BackgroundColor3 = Color3.fromRGB(248, 248, 248), -- Light grey background
                BorderSizePixel = 0,
                ZIndex = 1001,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 10),
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
                
                -- Horizontal scrolling frame for reward cards
                RewardsScrollFrame = React.createElement("ScrollingFrame", {
                    Size = ScreenUtils.udim2(1, -20, 1, -ScreenUtils.getProportionalSize(40)),
                    Position = ScreenUtils.udim2(0, 10, 0, ScreenUtils.getProportionalSize(35)),
                    BackgroundTransparency = 1,
                    ScrollBarThickness = ScreenUtils.getProportionalSize(4),
                    ScrollBarImageColor3 = Color3.fromRGB(200, 200, 200),
                    ScrollingDirection = Enum.ScrollingDirection.X,
                    CanvasSize = UDim2.new(0, math.max(#rewards, 1) * ScreenUtils.getProportionalSize(150), 0, 0), -- Horizontal canvas (increased for padding)
                    ZIndex = 1002,
                }, {
                    -- Horizontal layout for cards
                    Layout = React.createElement("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center, -- Center the cards
                        VerticalAlignment = Enum.VerticalAlignment.Center, -- Center vertically too
                        Padding = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(20)), -- Increased padding
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
                            -- Rainbow cards use transparent background to show main card rainbow, others use solid
                            isChanceBackgroundTransparent = reward.special == "rainbow",
                        })
                    end
                    
                    return cards
                end)()),
                }),
            }),
            
            -- Case Opening Animation Section (bottom half) - with pre-populated cards
            CaseOpeningSection = React.createElement("Frame", {
                Name = "CaseOpeningSection",
                Size = ScreenUtils.udim2(1, -40, 0.38, 0), -- 38% of modal height (back to original - padding fixed the card issue)
                Position = ScreenUtils.udim2(0, 20, 0.54, 0), -- 54% from top (after rewards section)
                BackgroundColor3 = Color3.fromRGB(248, 248, 248), -- Light grey like PlaytimeRewards
                BorderSizePixel = 0,
                ZIndex = 1001,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 10),
                }),
                
            }, CrazyChestUI.createStaticRewardStrip(rewards)),
            
            -- Open button (moved to bottom)
            OpenButton = React.createElement("TextButton", {
                Size = ScreenUtils.udim2(1, -40, 0.06, 0), -- 6% of modal height (back to original)
                Position = ScreenUtils.udim2(0, 20, 0.93, 0), -- 93% from top (back to original)
                BackgroundColor3 = buttonColor,
                Text = buttonText,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = ScreenUtils.TEXT_SIZES.LARGE(),
                Font = Enum.Font.FredokaOne,
                BorderSizePixel = 0,
                ZIndex = 1001,
                [React.Event.MouseButton1Click] = handleOpenChest,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 10),
                }),
            }),
        })
    })
end

return CrazyChestUI