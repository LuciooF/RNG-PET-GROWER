-- Modern GamepassUI - Beautiful design with gamepasses and developer products tabs
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local React = require(ReplicatedStorage.Packages.react)
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local DataSyncService = require(script.Parent.Parent.services.DataSyncService)
local GamepassConfig = require(ReplicatedStorage.config.GamepassConfig)
local DeveloperProductConfig = require(ReplicatedStorage.config.DeveloperProductConfig)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)

local player = Players.LocalPlayer

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

local function GamepassUI(props)
    local playerData, setPlayerData = React.useState({
        OwnedGamepasses = {}
    })
    local isVisible, setIsVisible = React.useState(props.visible or false)
    local selectedTab, setSelectedTab = React.useState("Gamepasses") -- "Gamepasses" or "Products"
    local gamepassData, setGamepassData = React.useState({}) -- Dynamic gamepass data with real prices/icons
    local productData, setProductData = React.useState({}) -- Dynamic product data with real prices/icons
    
    -- Update visibility when props change
    React.useEffect(function()
        setIsVisible(props.visible or false)
    end, {props.visible})
    
    -- Subscribe to data changes
    React.useEffect(function()
        -- Get initial data
        local initialData = DataSyncService:GetPlayerData()
        if initialData then
            setPlayerData(initialData)
        end
        
        local unsubscribe = DataSyncService:Subscribe(function(newState)
            if newState.player then
                setPlayerData(newState.player)
            end
        end)
        
        return unsubscribe
    end, {})
    
    -- Fetch dynamic gamepass data with real prices and icons
    React.useEffect(function()
        local function fetchGamepassData()
            local allGamepasses = GamepassConfig.getAllGamepasses()
            local dynamicData = {}
            
            for gamepassName, config in pairs(allGamepasses) do
                -- Initialize with config data
                dynamicData[gamepassName] = {
                    name = config.name,
                    description = config.description,
                    price = "Loading...",
                    icon = config.icon,
                    gamepassId = config.id,
                    benefits = config.benefits
                }
                
                -- Fetch real price from MarketplaceService
                if config.id then
                    task.spawn(function()
                        local success, result = pcall(function()
                            return MarketplaceService:GetProductInfo(config.id, Enum.InfoType.GamePass)
                        end)
                        
                        if success and result then
                            dynamicData[gamepassName].price = result.PriceInRobux or 0
                            dynamicData[gamepassName].priceText = result.PriceInRobux and (tostring(result.PriceInRobux) .. " R$") or "Free"
                            dynamicData[gamepassName].icon = result.IconImageAssetId and ("rbxassetid://" .. result.IconImageAssetId) or config.icon
                            
                            -- Update state
                            setGamepassData(function(currentData)
                                local newData = {}
                                for key, value in pairs(currentData) do
                                    newData[key] = value
                                end
                                newData[gamepassName] = dynamicData[gamepassName]
                                return newData
                            end)
                        else
                            dynamicData[gamepassName].price = 0
                            dynamicData[gamepassName].priceText = "N/A"
                        end
                    end)
                end
            end
            
            setGamepassData(dynamicData)
        end
        
        -- Fetch dynamic product data from the game's developer products
        local function fetchProductData()
            task.spawn(function()
                local success, pagesObject = pcall(function()
                    return MarketplaceService:GetDeveloperProductsAsync()
                end)
                
                if success and pagesObject then
                    local dynamicData = {}
                    
                    -- Iterate through all pages of developer products
                    while true do
                        local pageSuccess, currentPage = pcall(function()
                            return pagesObject:GetCurrentPage()
                        end)
                        
                        if pageSuccess and currentPage then
                            -- Process each developer product on this page
                            for _, productInfo in pairs(currentPage) do
                                if productInfo and productInfo.ProductId then
                                    local productKey = "Product_" .. productInfo.ProductId
                                    -- Initialize with basic info
                                    dynamicData[productKey] = {
                                        name = productInfo.Name or "Developer Product",
                                        description = productInfo.Description or "Premium purchase item",
                                        price = productInfo.PriceInRobux or 0,
                                        priceText = productInfo.PriceInRobux and (tostring(productInfo.PriceInRobux) .. " R$") or "Free",
                                        icon = IconAssets.getIcon("CURRENCY", "ROBUX"), -- Default fallback
                                        productId = productInfo.ProductId,
                                        category = "Products"
                                    }
                                    
                                    -- Fetch detailed product info including icon (same as gamepasses)
                                    task.spawn(function()
                                        local success, detailedInfo = pcall(function()
                                            return MarketplaceService:GetProductInfo(productInfo.ProductId, Enum.InfoType.Product)
                                        end)
                                        
                                        if success and detailedInfo then
                                            -- Update with real icon if available
                                            if detailedInfo.IconImageAssetId then
                                                dynamicData[productKey].icon = "rbxassetid://" .. detailedInfo.IconImageAssetId
                                            end
                                            
                                            -- Update state to trigger re-render with new icon
                                            setProductData(function(currentData)
                                                local newData = {}
                                                for key, value in pairs(currentData) do
                                                    newData[key] = value
                                                end
                                                newData[productKey] = dynamicData[productKey]
                                                return newData
                                            end)
                                        end
                                    end)
                                end
                            end
                        end
                        
                        -- Check if there are more pages
                        if pagesObject.IsFinished then
                            break
                        else
                            local advanceSuccess = pcall(function()
                                pagesObject:AdvanceToNextPageAsync()
                            end)
                            if not advanceSuccess then
                                break -- Stop if we can't advance to next page
                            end
                        end
                    end
                    
                    -- Update state with all products at once
                    setProductData(dynamicData)
                else
                    warn("Failed to fetch developer products:", pagesObject)
                    setProductData({}) -- Set empty if failed
                end
            end)
        end
        
        fetchGamepassData()
        fetchProductData()
    end, {})
    
    -- Check if player owns a gamepass
    local function playerOwnsGamepass(gamepassName)
        if not playerData.OwnedGamepasses then return false end
        
        for _, ownedGamepass in pairs(playerData.OwnedGamepasses) do
            if ownedGamepass == gamepassName then
                return true
            end
        end
        return false
    end
    
    -- Handle gamepass purchase
    local function handleGamepassPurchase(gamepassName)
        local purchaseGamepassRemote = ReplicatedStorage:FindFirstChild("PurchaseGamepass")
        if purchaseGamepassRemote then
            purchaseGamepassRemote:FireServer(gamepassName)
        end
    end
    
    -- Handle product purchase
    local function handleProductPurchase(productName)
        local purchaseProductRemote = ReplicatedStorage:FindFirstChild("PurchaseProduct")
        if purchaseProductRemote then
            purchaseProductRemote:FireServer(productName)
        end
    end
    
    -- Handle toggle setting (for owned gamepasses with toggleable features)
    local function handleToggleSetting(settingName)
        local toggleGamepassSettingRemote = ReplicatedStorage:FindFirstChild("ToggleGamepassSetting")
        if toggleGamepassSettingRemote then
            toggleGamepassSettingRemote:FireServer(settingName)
        end
    end
    
    -- Check if setting is enabled
    local function isSettingEnabled(settingName)
        if not playerData.GamepassSettings then return false end
        return playerData.GamepassSettings[settingName] or false
    end
    
    if not isVisible then
        return nil
    end
    
    -- Create gamepass cards with rainbow squiggles (owned gamepasses at bottom)
    local function createItemCards(items, isGamepass)
        local itemCards = {}
        local ownedItems = {}
        local unownedItems = {}
        
        -- Separate owned and unowned items
        for itemName, config in pairs(items) do
            local isOwned = isGamepass and playerOwnsGamepass(itemName) or false
            local dynamicConfig = isGamepass and gamepassData[itemName] or productData[itemName]
            local displayConfig = dynamicConfig or config
            
            local itemData = {
                name = itemName,
                config = config,
                displayConfig = displayConfig,
                isOwned = isOwned
            }
            
            if isOwned then
                table.insert(ownedItems, itemData)
            else
                table.insert(unownedItems, itemData)
            end
        end
        
        -- Combine arrays: unowned first, then owned at bottom
        local sortedItems = {}
        for _, item in pairs(unownedItems) do
            table.insert(sortedItems, item)
        end
        for _, item in pairs(ownedItems) do
            table.insert(sortedItems, item)
        end
        
        local cardIndex = 0
        for _, itemData in pairs(sortedItems) do
            cardIndex = cardIndex + 1
            local itemName = itemData.name
            local config = itemData.config
            local displayConfig = itemData.displayConfig
            local isOwned = itemData.isOwned
            
            itemCards[cardIndex] = React.createElement("Frame", {
                Name = itemName .. "Card",
                Size = ScreenUtils.udim2(0, 320, 0, 500), -- Even bigger cards
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                LayoutOrder = cardIndex,
                ZIndex = 110,
                [React.Event.MouseEnter] = function()
                    playHoverSound()
                end
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 160) -- Half of 320 for circular
                }),
                
                -- Rainbow squiggle background
                RainbowSquiggle = React.createElement("ImageLabel", {
                    Size = ScreenUtils.udim2(0.9, 0, 0.9, 0),
                    Position = ScreenUtils.udim2(0.5, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = IconAssets.getIcon("UI", "SQUIGGLE"),
                    ImageColor3 = Color3.fromRGB(255, 255, 255),
                    ImageTransparency = 0.2,
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 109,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, 144) -- Circular clipping (90% of 160)
                    }),
                    
                    -- Rainbow gradient on squiggle
                    RainbowGradient = React.createElement("UIGradient", {
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),     -- Red
                            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 165, 0)), -- Orange
                            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)), -- Yellow
                            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),   -- Green
                            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),  -- Blue
                            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)), -- Indigo
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 0, 211))    -- Violet
                        }),
                        Rotation = 45
                    })
                }),
                
                -- Icon (top center, positioned better)
                Icon = React.createElement("ImageLabel", {
                    Size = ScreenUtils.udim2(0, 80, 0, 80), -- Slightly smaller to fit better
                    Position = ScreenUtils.udim2(0.5, -40, 0, 40), -- More centered and lower
                    BackgroundTransparency = 1,
                    Image = displayConfig.icon or IconAssets.getIcon("CURRENCY", "ROBUX"),
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 112,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, 16),
                    }),
                    
                    Glow = React.createElement("UIStroke", {
                        Color = Color3.fromRGB(255, 255, 255),
                        Thickness = 3,
                        Transparency = 0.5,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    }),
                }),
                
                -- Title with rainbow gradient
                Title = React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(1, -20, 0, 50), -- Taller for bigger text
                    Position = ScreenUtils.udim2(0, 10, 0, 130),
                    BackgroundTransparency = 1,
                    Text = displayConfig.name,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = isGamepass and ScreenUtils.TEXT_SIZES.LARGE() or (ScreenUtils.TEXT_SIZES.LARGE() + 4), -- Bigger for dev products
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 112,
                }, {
                    TitleGradient = React.createElement("UIGradient", {
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 20, 147)),
                            ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 105, 180)),
                            ColorSequenceKeypoint.new(0.6, Color3.fromRGB(138, 43, 226)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 144, 255))
                        }),
                        Rotation = 0
                    })
                }),
                
                -- Price with Robux icon (prominent display)
                PriceContainer = React.createElement("Frame", {
                    Size = ScreenUtils.udim2(1, -20, 0, 40),
                    Position = ScreenUtils.udim2(0, 10, 0, 190), -- Moved down slightly for bigger title
                    BackgroundTransparency = 1,
                    ZIndex = 112,
                }, {
                    Layout = React.createElement("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = ScreenUtils.udim(0, 5),
                    }),
                    
                    PriceLabel = React.createElement("TextLabel", {
                        Size = ScreenUtils.udim2(0, isOwned and 120 or 80, 1, 0),
                        BackgroundTransparency = 1,
                        Text = isOwned and "✅ OWNED" or (displayConfig.price and tostring(displayConfig.price) or "Loading..."),
                        TextColor3 = isOwned and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 215, 0),
                        TextSize = ScreenUtils.TEXT_SIZES.LARGE() + 2, -- Even bigger price
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        TextStrokeTransparency = 0,
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        ZIndex = 112,
                    }),
                    
                    RobuxIcon = (not isOwned) and React.createElement("ImageLabel", {
                        Size = ScreenUtils.udim2(0, 25, 0, 25),
                        BackgroundTransparency = 1,
                        Image = IconAssets.getIcon("CURRENCY", "ROBUX"),
                        ScaleType = Enum.ScaleType.Fit,
                        ZIndex = 112,
                    }) or nil
                }),
                
                -- Description (better contrast color)
                Description = React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(1, -30, 0, 80), -- Smaller description area to reduce gap
                    Position = ScreenUtils.udim2(0, 15, 0, 240), -- Moved down for bigger title
                    BackgroundTransparency = 1,
                    Text = displayConfig.description or "Premium item with amazing benefits!",
                    TextColor3 = Color3.fromRGB(40, 40, 40), -- Much darker gray for better contrast
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() + 2, -- Bigger text
                    Font = Enum.Font.GothamBold, -- Make description bold
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    TextWrapped = true,
                    -- NO TEXT STROKE as requested
                    ZIndex = 112,
                }),
                
                -- Action Button with animation (bottom)
                ActionButton = React.createElement("TextButton", {
                    Size = ScreenUtils.udim2(0, 200, 0, 50), -- Bigger button for bigger cards
                    Position = ScreenUtils.udim2(0.5, -100, 0, 340), -- Fixed position instead of relative to bottom
                    BackgroundColor3 = isOwned and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(0, 200, 0), -- Green for buy buttons
                    BorderSizePixel = 0,
                    Text = isGamepass and (isOwned and "Toggle" or "") or "", -- Remove text, will use children for layout
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.TEXT_SIZES.LARGE(),
                    Font = Enum.Font.GothamBold,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 112,
                    [React.Event.MouseButton1Click] = function()
                        if isGamepass then
                            if isOwned then
                                handleToggleSetting(itemName)
                            else
                                handleGamepassPurchase(itemName)
                            end
                        else
                            handleProductPurchase(itemName)
                        end
                    end,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, 18),
                    }),
                    
                    -- Button content layout for new format
                    ButtonContent = (not isOwned) and React.createElement("Frame", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        ZIndex = 114,
                    }, {
                        Layout = React.createElement("UIListLayout", {
                            FillDirection = Enum.FillDirection.Horizontal,
                            HorizontalAlignment = Enum.HorizontalAlignment.Center,
                            VerticalAlignment = Enum.VerticalAlignment.Center,
                            Padding = ScreenUtils.udim(0, 5),
                        }),
                        
                        RobuxIcon = React.createElement("ImageLabel", {
                            Size = ScreenUtils.udim2(0, 20, 0, 20),
                            BackgroundTransparency = 1,
                            Image = IconAssets.getIcon("CURRENCY", "ROBUX"),
                            ScaleType = Enum.ScaleType.Fit,
                            ZIndex = 115,
                        }),
                        
                        PriceText = React.createElement("TextLabel", {
                            Size = ScreenUtils.udim2(0, 40, 1, 0), -- Auto-size based on text
                            BackgroundTransparency = 1,
                            Text = tostring(displayConfig.price or "0"),
                            TextColor3 = Color3.fromRGB(255, 255, 255),
                            TextSize = ScreenUtils.TEXT_SIZES.LARGE(),
                            Font = Enum.Font.GothamBold,
                            TextStrokeTransparency = 0,
                            TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                            TextXAlignment = Enum.TextXAlignment.Center,
                            ZIndex = 115,
                        }),
                        
                        BuyText = React.createElement("TextLabel", {
                            Size = ScreenUtils.udim2(0, 80, 1, 0),
                            BackgroundTransparency = 1,
                            Text = "Buy Now!",
                            TextColor3 = Color3.fromRGB(255, 255, 255),
                            TextSize = ScreenUtils.TEXT_SIZES.LARGE(),
                            Font = Enum.Font.GothamBold,
                            TextStrokeTransparency = 0,
                            TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                            TextXAlignment = Enum.TextXAlignment.Center,
                            ZIndex = 115,
                        })
                    }) or (isGamepass and isOwned and React.createElement("TextLabel", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Text = "Toggle",
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = ScreenUtils.TEXT_SIZES.LARGE(),
                        Font = Enum.Font.GothamBold,
                        TextStrokeTransparency = 0,
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        ZIndex = 114,
                    }) or nil),
                    
                    -- Shining gradient effect (only for non-owned items)
                    ShineGradient = (not isOwned) and React.createElement("UIGradient", {
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 150)),     -- Bright Green
                            ColorSequenceKeypoint.new(0.3, Color3.fromRGB(100, 255, 100)), -- Light Green
                            ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0, 200, 0)),     -- Medium Green
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 150, 0))       -- Dark Green
                        }),
                        Rotation = 45,
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0.2),
                            NumberSequenceKeypoint.new(1, 0.4)
                        })
                    }) or nil,
                    
                    -- Animated shine overlay for moving effect
                    ShineOverlay = (not isOwned) and React.createElement("Frame", {
                        Size = ScreenUtils.udim2(0.3, 0, 1.2, 0),
                        Position = ScreenUtils.udim2(-0.3, 0, -0.1, 0),
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        BackgroundTransparency = 0.6,
                        BorderSizePixel = 0,
                        ZIndex = 113,
                        Rotation = 25,
                        ref = function(rbx)
                            if rbx and not isOwned then
                                -- Create repeating shine animation
                                local function animateShine()
                                    local tweenInfo = TweenInfo.new(
                                        2, -- Duration
                                        Enum.EasingStyle.Linear,
                                        Enum.EasingDirection.InOut,
                                        -1, -- Repeat infinitely
                                        false, -- No reverse
                                        0 -- No delay
                                    )
                                    
                                    local tween = TweenService:Create(
                                        rbx,
                                        tweenInfo,
                                        {Position = ScreenUtils.udim2(1.2, 0, -0.1, 0)}
                                    )
                                    
                                    tween:Play()
                                    
                                    tween.Completed:Connect(function()
                                        rbx.Position = ScreenUtils.udim2(-0.3, 0, -0.1, 0)
                                    end)
                                end
                                
                                -- Start animation after a brief delay
                                task.wait(0.1)
                                animateShine()
                            end
                        end
                    }, {
                        Corner = React.createElement("UICorner", {
                            CornerRadius = ScreenUtils.udim(0, 4),
                        }),
                        
                        ShineGradient = React.createElement("UIGradient", {
                            Color = ColorSequence.new({
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
                            }),
                            Transparency = NumberSequence.new({
                                NumberSequenceKeypoint.new(0, 1),
                                NumberSequenceKeypoint.new(0.5, 0.2),
                                NumberSequenceKeypoint.new(1, 1)
                            })
                        })
                    }) or nil,
                    
                    ButtonOutline = React.createElement("UIStroke", {
                        Thickness = 3,
                        Color = isOwned and Color3.fromRGB(200, 150, 0) or Color3.fromRGB(0, 150, 0), -- Green outline for buy buttons
                        Transparency = 0,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    }),
                }),
                
                -- Status indicator for gamepasses
                StatusIndicator = (isGamepass and isOwned) and React.createElement("Frame", {
                    Size = ScreenUtils.udim2(0, 25, 0, 25),
                    Position = ScreenUtils.udim2(1, -35, 0, 10),
                    BackgroundColor3 = isSettingEnabled(itemName) and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 100, 100),
                    BorderSizePixel = 0,
                    ZIndex = 113,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, 12.5)
                    }),
                    
                    StatusOutline = React.createElement("UIStroke", {
                        Thickness = 2,
                        Color = Color3.fromRGB(0, 0, 0),
                        Transparency = 0,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    }),
                }) or nil
            })
        end
        
        return itemCards
    end
    
    -- Get current items based on selected tab
    local currentItems = selectedTab == "Gamepasses" and GamepassConfig.getAllGamepasses() or productData
    local currentCards = createItemCards(currentItems, selectedTab == "Gamepasses")
    local itemCount = 0
    for _ in pairs(currentItems) do itemCount = itemCount + 1 end
    
    -- Background overlay
    return React.createElement("TextButton", {
        Name = "GamepassOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 100,
        [React.Event.Activated] = function()
            setIsVisible(false)
            if props.onClose then props.onClose() end
        end
    }, {
        -- Main panel
        MainPanel = React.createElement("Frame", {
            Size = ScreenUtils.udim2(0.6, 0, 0.75, 0), -- Same size as other GUIs
            Position = ScreenUtils.udim2(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 3,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = 105,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, 12)
            }),
            
            -- Header with rainbow gradient
            Header = React.createElement("Frame", {
                Size = ScreenUtils.udim2(1, 0, 0, 50),
                BackgroundTransparency = 1,
                BorderSizePixel = 2,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                ZIndex = 106,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 12)
                }),
                
                -- Rainbow gradient background
                GradientBackground = React.createElement("Frame", {
                    Size = ScreenUtils.udim2(1, 0, 1, 0),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 0,
                    ZIndex = 105,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, 12)
                    }),
                    
                    RainbowGradient = React.createElement("UIGradient", {
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 150)),    -- Hot Pink
                            ColorSequenceKeypoint.new(0.15, Color3.fromRGB(255, 100, 0)),  -- Bright Orange
                            ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 255, 0)),   -- Bright Yellow
                            ColorSequenceKeypoint.new(0.45, Color3.fromRGB(0, 255, 100)),  -- Bright Green
                            ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0, 150, 255)),   -- Bright Blue
                            ColorSequenceKeypoint.new(0.75, Color3.fromRGB(150, 0, 255)),  -- Bright Purple
                            ColorSequenceKeypoint.new(0.9, Color3.fromRGB(255, 0, 200)),   -- Magenta
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 150))      -- Hot Pink
                        }),
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0.5), -- More vibrant (less transparent)
                            NumberSequenceKeypoint.new(1, 0.6)
                        }),
                        Rotation = 0, -- Vertical pattern (0 degrees is vertical in Roblox)
                    }),
                }),
                
                -- Robux icon in header
                RobuxIcon = React.createElement("ImageLabel", {
                    Size = ScreenUtils.udim2(0, 30, 0, 30),
                    Position = ScreenUtils.udim2(0, 15, 0.5, -15),
                    BackgroundTransparency = 1,
                    Image = IconAssets.getIcon("CURRENCY", "ROBUX"),
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 107,
                }),
                
                Title = React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(1, -100, 1, 0),
                    Position = ScreenUtils.udim2(0, 50, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "✨🛒 PREMIUM STORE 🛒✨",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.TEXT_SIZES.LARGE() + 8, -- Much bigger
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 107,
                }, {
                    -- Cool rainbow gradient for title text
                    TitleGradient = React.createElement("UIGradient", {
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),    -- Gold
                            ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 100, 255)), -- Magenta  
                            ColorSequenceKeypoint.new(0.4, Color3.fromRGB(0, 255, 255)),   -- Cyan
                            ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 255, 0)),   -- Yellow
                            ColorSequenceKeypoint.new(0.8, Color3.fromRGB(255, 100, 0)),   -- Orange
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 215, 0))      -- Gold
                        }),
                        Rotation = 0 -- Horizontal rainbow
                    })
                }),
                
                CloseButton = React.createElement("ImageButton", {
                    Size = ScreenUtils.udim2(0, 50, 0, 50), -- Bigger close button
                    Position = ScreenUtils.udim2(1, -55, 0.5, -25),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    Image = IconAssets.getIcon("UI", "X_BUTTON"),
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 107,
                    [React.Event.Activated] = function()
                        setIsVisible(false)
                        if props.onClose then props.onClose() end
                    end
                })
            }),
            
            -- Tab buttons
            TabContainer = React.createElement("Frame", {
                Size = ScreenUtils.udim2(1, -40, 0, 60), -- Bigger tab container for bigger tabs
                Position = ScreenUtils.udim2(0, 20, 0, 60),
                BackgroundTransparency = 1,
                ZIndex = 106,
            }, {
                TabLayout = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = ScreenUtils.udim(0, 5),
                }),
                
                GamepassTab = React.createElement("TextButton", {
                    Size = ScreenUtils.udim2(0.5, -10, 0, 50), -- 50% width, bigger height
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 0,
                    Text = "🎮 Gamepasses",
                    TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                    TextSize = ScreenUtils.TEXT_SIZES.LARGE() + 4, -- Much bigger tab text
                    Font = Enum.Font.GothamBold,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 107,
                    [React.Event.Activated] = function()
                        setSelectedTab("Gamepasses")
                    end,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, 12),
                    }),
                    
                    -- Multi-colored rainbow gradient for gamepass tab
                    GamepassGradient = React.createElement("UIGradient", {
                        Color = selectedTab == "Gamepasses" and ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 150)),    -- Hot Pink
                            ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 100, 0)),  -- Orange
                            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 0, 255)),   -- Purple
                            ColorSequenceKeypoint.new(0.75, Color3.fromRGB(0, 150, 255)),  -- Blue
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 150))      -- Green
                        }) or ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 180, 180)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 120, 120))
                        }),
                        Rotation = 45
                    }),
                    
                    TabOutline = React.createElement("UIStroke", {
                        Thickness = 3,
                        Color = selectedTab == "Gamepasses" and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(100, 100, 100),
                        Transparency = 0,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    }),
                }),
                
                ProductTab = React.createElement("TextButton", {
                    Size = ScreenUtils.udim2(0.5, -10, 0, 50), -- 50% width, bigger height
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 0,
                    Text = "🛒 Products",
                    TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                    TextSize = ScreenUtils.TEXT_SIZES.LARGE() + 4, -- Much bigger tab text
                    Font = Enum.Font.GothamBold,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 107,
                    [React.Event.Activated] = function()
                        setSelectedTab("Products")
                    end,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, 12),
                    }),
                    
                    -- Multi-colored rainbow gradient for products tab  
                    ProductGradient = React.createElement("UIGradient", {
                        Color = selectedTab == "Products" and ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 200)),     -- Cyan
                            ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 150, 0)),  -- Orange
                            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 0, 100)),   -- Pink
                            ColorSequenceKeypoint.new(0.75, Color3.fromRGB(100, 0, 255)),  -- Purple
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 0))      -- Yellow
                        }) or ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 180, 180)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 120, 120))
                        }),
                        Rotation = -45
                    }),
                    
                    TabOutline = React.createElement("UIStroke", {
                        Thickness = 3,
                        Color = selectedTab == "Products" and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(100, 100, 100),
                        Transparency = 0,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    }),
                })
            }),
            
            -- Main content area
            ContentArea = React.createElement("Frame", {
                Size = ScreenUtils.udim2(1, -40, 1, -140), -- Leave space for bigger header and tabs  
                Position = ScreenUtils.udim2(0.5, 0, 0, 130), -- Adjust for bigger tabs
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 2,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                ZIndex = 106,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 8)
                }),
                
                Stroke = React.createElement("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = 2,
                }),
                
                -- Background
                WhiteBackground = React.createElement("Frame", {
                    Size = ScreenUtils.udim2(1, 0, 1, 0),
                    Position = ScreenUtils.udim2(0, 0, 0, 0),
                    BackgroundColor3 = Color3.fromRGB(245, 245, 245),
                    BorderSizePixel = 0,
                    ZIndex = 104,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, 8)
                    }),
                }),
                
                BackgroundImage = React.createElement("ImageLabel", {
                    Size = ScreenUtils.udim2(1, 0, 1, 0),
                    Position = ScreenUtils.udim2(0, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://116367512866072",
                    ScaleType = Enum.ScaleType.Tile,
                    TileSize = ScreenUtils.udim2(0, 120, 0, 120),
                    ImageTransparency = 0.85,
                    ImageColor3 = Color3.fromRGB(200, 200, 200),
                    ZIndex = 105,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, 8)
                    }),
                }),
                
                -- Items grid
                ItemGrid = React.createElement("ScrollingFrame", {
                    Size = ScreenUtils.udim2(1, -10, 1, -10),
                    Position = ScreenUtils.udim2(0.5, 0, 0, 5),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ScrollBarThickness = 8,
                    ScrollBarImageColor3 = Color3.fromRGB(150, 150, 150),
                    CanvasSize = ScreenUtils.udim2(0, 0, 0, math.ceil(itemCount / 3) * 520 + 30), -- Even bigger cards spacing
                    ZIndex = 107,
                }, {
                    Layout = React.createElement("UIGridLayout", {
                        CellSize = ScreenUtils.udim2(0, 320, 0, 500), -- Even bigger cells to match card size
                        CellPadding = ScreenUtils.udim2(0, 15, 0, 15),
                        StartCorner = Enum.StartCorner.TopLeft,
                        FillDirectionMaxCells = 3, -- 3 items per row
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Top
                    }),
                    
                    Padding = React.createElement("UIPadding", {
                        PaddingLeft = ScreenUtils.udim(0, 5),
                        PaddingRight = ScreenUtils.udim(0, 5),
                        PaddingTop = ScreenUtils.udim(0, 5),
                        PaddingBottom = ScreenUtils.udim(0, 5)
                    })
                }, currentCards)
            })
        })
    })
end

return GamepassUI