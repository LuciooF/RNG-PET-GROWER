-- GamepassUI - Dynamic UI for purchasing gamepasses with real prices and icons
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local React = require(ReplicatedStorage.Packages.react)
local DataSyncService = require(script.Parent.Parent.services.DataSyncService)
local GamepassConfig = require(ReplicatedStorage.config.GamepassConfig)

local player = Players.LocalPlayer

local function GamepassUI()
    local playerData, setPlayerData = React.useState({
        OwnedGamepasses = {}
    })
    local isVisible, setIsVisible = React.useState(false)
    local gamepassData, setGamepassData = React.useState({}) -- Dynamic gamepass data with real prices/icons
    
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
                -- Start with config data
                dynamicData[gamepassName] = {
                    name = config.name,
                    description = config.description,
                    price = config.price, -- Fallback price
                    icon = config.icon,   -- Fallback icon
                    id = config.id
                }
                
                -- Fetch real data from Roblox MarketplaceService
                task.spawn(function()
                    local success, info = pcall(function()
                        return MarketplaceService:GetProductInfo(config.id, Enum.InfoType.GamePass)
                    end)
                    
                    if success and info then
                        -- Update with real data
                        dynamicData[gamepassName].price = info.PriceInRobux or config.price
                        if info.IconImageAssetId then
                            dynamicData[gamepassName].icon = "rbxassetid://" .. tostring(info.IconImageAssetId)
                        end
                        
                        -- Update state with new data
                        setGamepassData(function(prevData)
                            local newData = {}
                            for k, v in pairs(prevData) do
                                newData[k] = v
                            end
                            newData[gamepassName] = dynamicData[gamepassName]
                            return newData
                        end)
                    else
                        -- Use fallback data if API call fails
                        setGamepassData(function(prevData)
                            local newData = {}
                            for k, v in pairs(prevData) do
                                newData[k] = v
                            end
                            newData[gamepassName] = dynamicData[gamepassName]
                            return newData
                        end)
                    end
                end)
            end
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
        -- Send purchase request to server
        local purchaseGamepassRemote = ReplicatedStorage:FindFirstChild("PurchaseGamepass")
        if purchaseGamepassRemote then
            purchaseGamepassRemote:FireServer(gamepassName)
        else
            warn("GamepassUI: PurchaseGamepass remote not found")
        end
    end
    
    -- Handle debug grant (for testing)
    local function handleDebugGrant(gamepassName)
        local debugGrantGamepassRemote = ReplicatedStorage:FindFirstChild("DebugGrantGamepass")
        if debugGrantGamepassRemote then
            debugGrantGamepassRemote:FireServer(gamepassName)
        else
            warn("GamepassUI: DebugGrantGamepass remote not found")
        end
    end
    
    -- Handle toggle setting (for owned gamepasses with toggleable features)
    local function handleToggleSetting(settingName)
        local toggleGamepassSettingRemote = ReplicatedStorage:FindFirstChild("ToggleGamepassSetting")
        if toggleGamepassSettingRemote then
            toggleGamepassSettingRemote:FireServer(settingName)
        else
            warn("GamepassUI: ToggleGamepassSetting remote not found")
        end
    end
    
    -- Check if setting is enabled
    local function isSettingEnabled(settingName)
        if not playerData.GamepassSettings then return false end
        return playerData.GamepassSettings[settingName] or false
    end
    
    -- Toggle panel visibility
    local function togglePanel()
        setIsVisible(not isVisible)
    end
    
    -- Create gamepass card with dynamic data
    local function createGamepassCard(gamepassName)
        local isOwned = playerOwnsGamepass(gamepassName)
        local dynamicConfig = gamepassData[gamepassName]
        
        -- Use dynamic data if available, otherwise fall back to static config
        local config = dynamicConfig or GamepassConfig.getGamepassByName(gamepassName)
        if not config then return nil end
        
        return React.createElement("Frame", {
            Name = gamepassName .. "Card",
            Size = UDim2.new(1, -20, 0, 150), -- Reduced height since description is conditional
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundColor3 = Color3.fromRGB(60, 60, 60),
            BorderSizePixel = 0,
            ZIndex = 102
        }, {
            UICorner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0, 8)
            }),
            
            -- Icon
            Icon = React.createElement("ImageLabel", {
                Name = "Icon",
                Size = UDim2.new(0, 40, 0, 40),
                Position = UDim2.new(0, 10, 0, 10),
                BackgroundTransparency = 1,
                Image = config.icon or "rbxasset://textures/ui/GuiImagePlaceholder.png",
                ZIndex = 103
            }, {
                UICorner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 6)
                })
            }),
            
            -- Title
            Title = React.createElement("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -70, 0, 30),
                Position = UDim2.new(0, 60, 0, 10),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = config.name,
                TextColor3 = isOwned and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 255),
                TextSize = 18,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 103
            }),
            
            -- Description (only show when not owned)
            Description = not isOwned and React.createElement("TextLabel", {
                Name = "Description",
                Size = UDim2.new(1, -70, 0, 70), -- Large area for text wrapping
                Position = UDim2.new(0, 60, 0, 45),
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Text = config.description,
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextSize = 12,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                ZIndex = 103
            }) or nil,
            
            -- Price/Status
            PriceLabel = React.createElement("TextLabel", {
                Name = "PriceLabel",
                Size = UDim2.new(0, 80, 0, 25),
                Position = isOwned and UDim2.new(0, 60, 0, 60) or UDim2.new(0, 60, 0, 120), -- Higher when owned, lower when not owned
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = isOwned and "OWNED" or (config.price .. " R$"),
                TextColor3 = isOwned and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 215, 0),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 103
            }),
            
            -- Purchase Button (when not owned)
            PurchaseButton = not isOwned and React.createElement("TextButton", {
                Name = "PurchaseButton",
                Size = UDim2.new(0, 80, 0, 25),
                Position = UDim2.new(1, -90, 0, 120), -- Positioned with price when not owned
                BackgroundColor3 = Color3.fromRGB(0, 162, 255),
                BorderSizePixel = 0,
                Font = Enum.Font.GothamBold,
                Text = "Buy",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 14,
                ZIndex = 103,
                [React.Event.Activated] = function()
                    handleGamepassPurchase(gamepassName)
                end
            }, {
                UICorner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 4)
                })
            }) or nil,
            
            -- Toggle Button (only for gamepasses with settings)
            ToggleButton = isOwned and (gamepassName == "AutoHeaven" or gamepassName == "PetMagnet") and React.createElement("TextButton", {
                Name = "ToggleButton",
                Size = UDim2.new(0, 80, 0, 25),
                Position = UDim2.new(1, -90, 0, 60), -- Positioned with OWNED text when owned
                BackgroundColor3 = (function()
                    if gamepassName == "AutoHeaven" then
                        return isSettingEnabled("AutoHeavenEnabled") and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 100, 100)
                    elseif gamepassName == "PetMagnet" then
                        return isSettingEnabled("PetMagnetEnabled") and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 100, 100)
                    end
                    return Color3.fromRGB(100, 100, 100)
                end)(),
                BorderSizePixel = 0,
                Font = Enum.Font.GothamBold,
                Text = (function()
                    if gamepassName == "AutoHeaven" then
                        return isSettingEnabled("AutoHeavenEnabled") and "ON" or "OFF"
                    elseif gamepassName == "PetMagnet" then
                        return isSettingEnabled("PetMagnetEnabled") and "ON" or "OFF"
                    end
                    return "OFF"
                end)(),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 14,
                ZIndex = 103,
                [React.Event.Activated] = function()
                    if gamepassName == "AutoHeaven" then
                        handleToggleSetting("AutoHeavenEnabled")
                    elseif gamepassName == "PetMagnet" then
                        handleToggleSetting("PetMagnetEnabled")
                    end
                end
            }, {
                UICorner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 4)
                })
            }) or nil,
            
            -- Debug Grant Button (for testing)
            DebugButton = not isOwned and React.createElement("TextButton", {
                Name = "DebugButton",
                Size = UDim2.new(0, 60, 0, 20),
                Position = UDim2.new(1, -70, 0, 10),
                BackgroundColor3 = Color3.fromRGB(255, 100, 100),
                BorderSizePixel = 0,
                Font = Enum.Font.Gotham,
                Text = "DEBUG",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 10,
                ZIndex = 103,
                [React.Event.Activated] = function()
                    handleDebugGrant(gamepassName)
                end
            }, {
                UICorner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 4)
                })
            }) or nil
        })
    end
    
    return React.createElement("ScreenGui", {
        Name = "GamepassUI",
        ResetOnSpawn = false
    }, {
        -- Toggle Button
        ToggleButton = React.createElement("TextButton", {
            Name = "GamepassToggle",
            Size = UDim2.new(0, 100, 0, 40),
            Position = UDim2.new(0, 10, 0, 100),
            BackgroundColor3 = Color3.fromRGB(138, 43, 226),
            BorderSizePixel = 0,
            Font = Enum.Font.GothamBold,
            Text = "Gamepasses",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 14,
            [React.Event.Activated] = togglePanel
        }, {
            UICorner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0, 8)
            })
        }),
        
        -- Main Panel
        MainPanel = isVisible and React.createElement("Frame", {
            Name = "GamepassPanel",
            Size = UDim2.new(0, 400, 0, 300),
            Position = UDim2.new(0.5, -200, 0.5, -150),
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            BorderSizePixel = 0,
            ZIndex = 100 -- Much higher Z-index
        }, {
            UICorner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0, 12)
            }),
            
            -- Title
            Title = React.createElement("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -40, 0, 40),
                Position = UDim2.new(0, 20, 0, 10),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = "Gamepasses",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 24,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 101
            }),
            
            -- Close button
            CloseButton = React.createElement("TextButton", {
                Name = "CloseButton",
                Size = UDim2.new(0, 30, 0, 30),
                Position = UDim2.new(1, -40, 0, 10),
                BackgroundColor3 = Color3.fromRGB(200, 50, 50),
                BorderSizePixel = 0,
                Font = Enum.Font.GothamBold,
                Text = "×",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 18,
                ZIndex = 101,
                [React.Event.Activated] = function()
                    setIsVisible(false)
                end
            }, {
                UICorner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 6)
                })
            }),
            
            -- Scrolling Frame for gamepasses
            ScrollingFrame = React.createElement("ScrollingFrame", {
                Name = "GamepassList",
                Size = UDim2.new(1, -40, 1, -70),
                Position = UDim2.new(0, 20, 0, 60),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                CanvasSize = UDim2.new(0, 0, 0, 960), -- 6 cards * 150px + 6 * 10px padding
                ScrollBarThickness = 8,
                ZIndex = 101
            }, {
                UIListLayout = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Top,
                    Padding = UDim.new(0, 10)
                }),
                
                -- PetMagnet Gamepass Card
                PetMagnetCard = createGamepassCard("PetMagnet"),
                
                -- AutoHeaven Gamepass Card  
                AutoHeavenCard = createGamepassCard("AutoHeaven"),
                
                -- 2x Money Gamepass Card
                TwoXMoneyCard = createGamepassCard("TwoXMoney"),
                
                -- 2x Diamonds Gamepass Card
                TwoXDiamondsCard = createGamepassCard("TwoXDiamonds"),
                
                -- 2x Heaven Speed Gamepass Card
                TwoXHeavenSpeedCard = createGamepassCard("TwoXHeavenSpeed"),
                
                -- VIP Gamepass Card
                VIPCard = createGamepassCard("VIP")
            })
        }) or nil
    })
end

return GamepassUI