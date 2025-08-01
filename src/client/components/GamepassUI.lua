-- Modern GamepassUI - Dynamic UI for purchasing gamepasses with real prices and icons
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local React = require(ReplicatedStorage.Packages.react)
local DataSyncService = require(script.Parent.Parent.services.DataSyncService)
local GamepassConfig = require(ReplicatedStorage.config.GamepassConfig)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)

local player = Players.LocalPlayer

local function GamepassUI(props)
    local playerData, setPlayerData = React.useState({
        OwnedGamepasses = {}
    })
    local isVisible, setIsVisible = React.useState(props.visible or false)
    local gamepassData, setGamepassData = React.useState({}) -- Dynamic gamepass data with real prices/icons
    
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
                    gamepassId = config.gamepassId
                }
                
                -- Fetch real price from MarketplaceService
                if config.gamepassId then
                    task.spawn(function()
                        local success, result = pcall(function()
                            return MarketplaceService:GetProductInfo(config.gamepassId, Enum.InfoType.GamePass)
                        end)
                        
                        if success and result then
                            dynamicData[gamepassName].price = result.PriceInRobux and (tostring(result.PriceInRobux) .. " R$") or "Free"
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
                            dynamicData[gamepassName].price = "N/A"
                        end
                    end)
                end
            end
            
            setGamepassData(dynamicData)
        end
        
        fetchGamepassData()
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
    
    -- Create modern gamepass cards
    local gamepassCards = {}
    local allGamepasses = GamepassConfig.getAllGamepasses()
    local cardIndex = 0
    
    for gamepassName, config in pairs(allGamepasses) do
        cardIndex = cardIndex + 1
        local isOwned = playerOwnsGamepass(gamepassName)
        local dynamicConfig = gamepassData[gamepassName]
        local displayConfig = dynamicConfig or config
        
        gamepassCards[cardIndex] = React.createElement("Frame", {
            Name = gamepassName .. "Card",
            Size = ScreenUtils.udim2(0, 350, 0, 120), -- Modern card size
            BackgroundColor3 = isOwned and Color3.fromRGB(220, 255, 220) or Color3.fromRGB(255, 255, 255), -- Light green if owned, white if not
            BorderSizePixel = 0,
            LayoutOrder = cardIndex,
            ZIndex = 103,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, 12),
            }),
            
            Outline = React.createElement("UIStroke", {
                Thickness = isOwned and 3 or 2,
                Color = isOwned and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(0, 0, 0), -- Green if owned, black if not
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }),
            
            -- Icon
            Icon = React.createElement("ImageLabel", {
                Size = ScreenUtils.udim2(0, 50, 0, 50),
                Position = ScreenUtils.udim2(0, 10, 0, 10),
                BackgroundTransparency = 1,
                Image = displayConfig.icon or IconAssets.getIcon("UI", "GAMEPASS"),
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 104,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 8),
                }),
            }),
            
            -- Title
            Title = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, -150, 0, 25),
                Position = ScreenUtils.udim2(0, 70, 0, 10),
                BackgroundTransparency = 1,
                Text = displayConfig.name,
                TextColor3 = isOwned and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(50, 50, 50), -- Green if owned, dark if not
                TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() + 2,
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(255, 255, 255),
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 104,
            }),
            
            -- Description
            Description = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, -150, 0, 40),
                Position = ScreenUtils.udim2(0, 70, 0, 35),
                BackgroundTransparency = 1,
                Text = displayConfig.description,
                TextColor3 = Color3.fromRGB(80, 80, 80),
                TextSize = ScreenUtils.TEXT_SIZES.SMALL(),
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(255, 255, 255),
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
                ZIndex = 104,
            }),
            
            -- Price/Status
            PriceLabel = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(0, 80, 0, 20),
                Position = ScreenUtils.udim2(1, -90, 0, 10),
                BackgroundTransparency = 1,
                Text = isOwned and "OWNED" or (dynamicConfig and dynamicConfig.price or "Loading..."),
                TextColor3 = isOwned and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(0, 162, 255), -- Green if owned, blue for price
                TextSize = ScreenUtils.TEXT_SIZES.SMALL() + 1,
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(255, 255, 255),
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 104,
            }),
            
            -- Action Button
            ActionButton = React.createElement("TextButton", {
                Size = ScreenUtils.udim2(0, 80, 0, 30),
                Position = ScreenUtils.udim2(1, -90, 1, -40),
                BackgroundColor3 = isOwned and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(0, 162, 255), -- Orange for toggle, blue for buy
                BorderSizePixel = 0,
                Text = isOwned and "Toggle" or "Buy",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = ScreenUtils.TEXT_SIZES.SMALL() + 1,
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                Font = Enum.Font.GothamBold,
                ZIndex = 104,
                [React.Event.MouseButton1Click] = function()
                    if isOwned then
                        -- Handle toggle for owned gamepasses
                        handleToggleSetting(gamepassName)
                    else
                        -- Handle purchase for unowned gamepasses
                        handleGamepassPurchase(gamepassName)
                    end
                end,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 8),
                }),
                
                Outline = React.createElement("UIStroke", {
                    Thickness = 2,
                    Color = Color3.fromRGB(0, 0, 0),
                    Transparency = 0,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                }),
            }),
            
            -- Status indicator for toggleable features (if owned)
            StatusIndicator = isOwned and React.createElement("Frame", {
                Size = ScreenUtils.udim2(0, 12, 0, 12),
                Position = ScreenUtils.udim2(1, -15, 0, 50),
                BackgroundColor3 = isSettingEnabled(gamepassName) and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 100, 100), -- Green if enabled, red if disabled
                BorderSizePixel = 0,
                ZIndex = 104,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 6), -- Circular
                }),
                
                Outline = React.createElement("UIStroke", {
                    Thickness = 1,
                    Color = Color3.fromRGB(0, 0, 0),
                    Transparency = 0,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                }),
            }) or nil
        })
    end
    
    -- Create click-outside-to-close overlay
    return React.createElement("TextButton", {
        Name = "GamepassOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1, -- Invisible overlay
        Text = "",
        ZIndex = 100,
        [React.Event.MouseButton1Click] = function()
            setIsVisible(false) -- Click outside to close
            if props.onVisibilityChange then
                props.onVisibilityChange(false)
            end
        end,
    }, {
        -- Modern modal container
        GamepassModal = React.createElement("Frame", {
            Name = "GamepassModal",
            Size = ScreenUtils.udim2(0, 800, 0, 600), -- Large modal
            Position = ScreenUtils.udim2(0.5, -400, 0.5, -300), -- Center on screen
            BackgroundColor3 = Color3.fromRGB(255, 255, 255), -- White background
            BackgroundTransparency = 0,
            ZIndex = 101,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, 15), -- Rounded corners
            }),
            
            ModalOutline = React.createElement("UIStroke", {
                Thickness = 4,
                Color = Color3.fromRGB(0, 0, 0), -- Black outline
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }),
            
            -- Background pattern like Pets UI
            BackgroundPattern = React.createElement("ImageLabel", {
                Name = "BackgroundPattern",
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                Image = "rbxassetid://116367512866072",
                ImageTransparency = 0.95, -- Very faint background
                ScaleType = Enum.ScaleType.Tile,
                TileSize = UDim2.new(0, 50, 0, 50),
                ZIndex = 101, -- Behind content
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 15),
                }),
            }),
            
            -- Header section
            Header = React.createElement("Frame", {
                Size = ScreenUtils.udim2(1, 0, 0, 60),
                BackgroundTransparency = 1,
                ZIndex = 103,
            }, {
                -- Title Container (centered)
                TitleContainer = React.createElement("Frame", {
                    Size = ScreenUtils.udim2(0, 220, 1, 0),
                    Position = ScreenUtils.udim2(0.5, -110, 0, 0),
                    BackgroundTransparency = 1,
                    ZIndex = 104,
                }, {
                    -- Gamepass Icon
                    GamepassIcon = React.createElement("ImageLabel", {
                        Size = ScreenUtils.udim2(0, 40, 0, 40),
                        Position = ScreenUtils.udim2(0, 0, 0.5, -20),
                        BackgroundTransparency = 1,
                        Image = IconAssets.getIcon("UI", "GAMEPASS"),
                        ScaleType = Enum.ScaleType.Fit,
                        ZIndex = 105,
                    }),
                    
                    -- Title Text
                    Title = React.createElement("TextLabel", {
                        Size = ScreenUtils.udim2(0, 170, 1, 0),
                        Position = ScreenUtils.udim2(0, 50, 0, 0),
                        BackgroundTransparency = 1,
                        Text = "Gamepasses",
                        TextColor3 = Color3.fromRGB(50, 50, 50), -- Dark text
                        TextSize = ScreenUtils.TEXT_SIZES.LARGE() + 4,
                        TextStrokeTransparency = 0,
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        ZIndex = 105,
                    }),
                }),
                
                -- Close button (right side)
                CloseButton = React.createElement("ImageButton", {
                    Size = ScreenUtils.udim2(0, 30, 0, 30),
                    Position = ScreenUtils.udim2(1, -40, 0.5, -15),
                    BackgroundColor3 = Color3.fromRGB(255, 100, 100), -- Light red
                    Image = IconAssets.getIcon("UI", "X_BUTTON"),
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 105,
                    [React.Event.MouseButton1Click] = function()
                        setIsVisible(false)
                        if props.onVisibilityChange then
                            props.onVisibilityChange(false)
                        end
                    end,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, 8),
                    }),
                    Outline = React.createElement("UIStroke", {
                        Thickness = 2,
                        Color = Color3.fromRGB(0, 0, 0),
                        Transparency = 0,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    }),
                }),
            }),
            
            -- Gamepasses grid (main content area)
            GamepassGridContainer = React.createElement("Frame", {
                Size = ScreenUtils.udim2(1, -40, 1, -80),
                Position = ScreenUtils.udim2(0, 20, 0, 70),
                BackgroundTransparency = 1,
                ZIndex = 102,
            }, {
                -- Scrolling frame for gamepass cards
                GamepassScrollFrame = React.createElement("ScrollingFrame", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ScrollBarThickness = 8,
                    ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100),
                    CanvasSize = UDim2.new(0, 0, 0, math.ceil(cardIndex / 2) * 140), -- 2 cards per row, 140px height each
                    ZIndex = 103,
                }, {
                    -- Grid layout
                    GridLayout = React.createElement("UIGridLayout", {
                        CellSize = ScreenUtils.udim2(0, 360, 0, 130),
                        CellPadding = ScreenUtils.udim2(0, 15, 0, 10),
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Top,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                    }),
                    
                    -- Gamepass cards container
                    GamepassCards = React.createElement("Frame", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        ZIndex = 103,
                    }, gamepassCards)
                })
            })
        })
    })
end

return GamepassUI