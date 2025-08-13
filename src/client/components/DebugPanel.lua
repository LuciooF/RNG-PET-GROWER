-- Enhanced DebugPanel - Developer tools for testing with modern theme and expanded functionality
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local React = require(ReplicatedStorage.Packages.react)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local AuthorizationUtils = require(ReplicatedStorage.utils.AuthorizationUtils)

local function DebugPanel(props)
    -- Check if current player is authorized
    local localPlayer = Players.LocalPlayer
    if not AuthorizationUtils.isAuthorized(localPlayer) then
        return nil -- Don't render debug panel for unauthorized users
    end
    
    local isVisible, setIsVisible = React.useState(props.visible or false)
    local selectedTab, setSelectedTab = React.useState("resources")
    
    -- State for custom pet creation
    local petBoost, setPetBoost = React.useState("1.5")
    local petValue, setPetValue = React.useState("500")
    local petName, setPetName = React.useState("Debug Pet")
    
    -- Update visibility when props change
    React.useEffect(function()
        setIsVisible(props.visible or false)
    end, {props.visible})
    
    -- Toggle with F1 key
    React.useEffect(function()
        local connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            if input.KeyCode == Enum.KeyCode.F1 then
                local newVisible = not isVisible
                setIsVisible(newVisible)
                if props.onVisibilityChange then
                    props.onVisibilityChange(newVisible)
                end
            end
        end)
        
        return function()
            connection:Disconnect()
        end
    end, {})
    
    -- Helper function to send debug commands (DRY principle)
    local function sendDebugCommand(commandType, ...)
        local debugCommandRemote = ReplicatedStorage:FindFirstChild("DebugCommand") 
        
        -- If not found directly, check in RemoteEvents folder
        if not debugCommandRemote then
            local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
            if remoteEventsFolder then
                debugCommandRemote = remoteEventsFolder:FindFirstChild("DebugCommand")
            end
        end
        
        if debugCommandRemote then
            debugCommandRemote:FireServer(commandType, ...)
        else
            warn("DebugPanel: DebugCommand remote not found for command:", commandType)
        end
    end
    
    -- Debug functions - Use proper server-authority pattern
    local function addMoney(amount)
        sendDebugCommand("AddMoney", amount)
    end
    
    local function addDiamonds(amount)
        sendDebugCommand("AddDiamonds", amount)
    end
    
    local function giveRebirth()
        sendDebugCommand("GiveRebirth")
    end
    
    local function createCustomPet()
        local boost = tonumber(petBoost) or 1.5
        local value = tonumber(petValue) or 500
        sendDebugCommand("CreateCustomPet", petName, boost, value)
    end
    
    local function resetPlayerData()
        sendDebugCommand("ResetPlayerData")
    end
    
    local function startTutorial()
        sendDebugCommand("StartTutorial")
    end
    
    local function setLastLoginYesterday()
        local remote = ReplicatedStorage:FindFirstChild("DebugSetLastLoginYesterday")
        if remote then
            local success, result = pcall(function()
                return remote:InvokeServer()
            end)
            if success and result then
                print("Debug: Set last login to yesterday - can now claim daily reward!")
            else
                warn("Debug: Failed to set last login time")
            end
        end
    end
    
    local function resetDailyRewards()
        local remote = ReplicatedStorage:FindFirstChild("DebugResetDailyRewards")
        if remote then
            local success, result = pcall(function()
                return remote:InvokeServer()
            end)
            if success and result then
                print("Debug: Reset daily rewards data")
            else
                warn("Debug: Failed to reset daily rewards")
            end
        end
    end
    
    local function stopTutorial()
        sendDebugCommand("StopTutorial")
    end
    
    -- Potion debug functions
    local function giveDiamondPotion()
        sendDebugCommand("GivePotion", "diamond_2x_10m", 5)
    end
    
    local function giveMoneyPotion()
        sendDebugCommand("GivePotion", "money_2x_10m", 5)
    end
    
    local function givePetMagnetPotion()
        sendDebugCommand("GivePotion", "pet_magnet_10m", 3)
    end
    
    -- UI Testing functions (client-side only)
    local function triggerPetDiscovery()
        -- Directly create and show the pet discovery popup for testing
        local PetDiscoveryService = require(game.Players.LocalPlayer.PlayerScripts.services.PetDiscoveryService)
        
        -- Create a simple test discovery
        local testDiscovery = {
            name = "Gecko", -- Use base pet name without variation
            variation = "Bronze",
            data = {
                variations = { Bronze = true }
            },
            timestamp = tick()
        }
        
        -- Call the popup directly
        PetDiscoveryService:ShowDiscoveryPopup(testDiscovery)
    end
    
    local function triggerRewardPopup()
        -- Actually give 1000 money using server command
        sendDebugCommand("AddMoney", 1000)
        
        -- Also show the reward popup immediately
        local RewardsService = require(game.Players.LocalPlayer.PlayerScripts.services.RewardsService)
        RewardsService:ShowRewardPopup({
            type = "money",
            amount = 1000,
            source = "Debug Test"
        })
    end
    
    -- Helper function to create a styled button
    local function createButton(props)
        return React.createElement("TextButton", {
            Size = props.size or ScreenUtils.udim2(1, 0, 0, 40),
            BackgroundColor3 = props.color or Color3.fromRGB(100, 150, 255),
            BorderSizePixel = 0,
            Text = props.text or "Button",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
            TextStrokeTransparency = 0,
            TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
            Font = Enum.Font.FredokaOne,
            LayoutOrder = props.layoutOrder,
            ZIndex = 203,
            [React.Event.Activated] = props.onActivated
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, 8)
            }),
            Outline = React.createElement("UIStroke", {
                Thickness = props.strokeThickness or 2,
                Color = Color3.fromRGB(0, 0, 0),
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }),
        })
    end
    
    -- Helper function to create section headers
    local function createSectionHeader(text, color, layoutOrder)
        return React.createElement("TextLabel", {
            Size = ScreenUtils.udim2(1, 0, 0, 35),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = color,
            TextSize = ScreenUtils.TEXT_SIZES.LARGE() - 2,
            TextStrokeTransparency = 0,
            TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
            Font = Enum.Font.FredokaOne,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = layoutOrder,
            ZIndex = 203
        })
    end
    
    -- Helper function to create tab buttons
    local function createTabButton(tabId, title, layoutOrder)
        local isSelected = selectedTab == tabId
        return React.createElement("TextButton", {
            Size = ScreenUtils.udim2(0, 100, 0, 35),
            BackgroundColor3 = isSelected and Color3.fromRGB(0, 162, 255) or Color3.fromRGB(150, 150, 150),
            BorderSizePixel = 0,
            Text = title,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() - 2,
            TextStrokeTransparency = 0,
            TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
            Font = Enum.Font.FredokaOne,
            LayoutOrder = layoutOrder,
            ZIndex = 203,
            [React.Event.Activated] = function()
                setSelectedTab(tabId)
            end
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, 6)
            }),
            Outline = React.createElement("UIStroke", {
                Thickness = isSelected and 3 or 2,
                Color = Color3.fromRGB(0, 0, 0),
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }),
        })
    end
    
    if not isVisible then
        return nil -- Don't show anything when not visible - controlled by side button now
    end
    
    -- Create click-outside-to-close overlay
    return React.createElement("TextButton", {
        Name = "DebugOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1, -- Invisible overlay
        Text = "",
        ZIndex = 200,
        [React.Event.MouseButton1Click] = function()
            setIsVisible(false) -- Click outside to close
            if props.onVisibilityChange then
                props.onVisibilityChange(false)
            end
        end,
    }, {
        -- Modern modal container (larger)
        DebugModal = React.createElement("Frame", {
            Name = "DebugModal",
            Size = ScreenUtils.udim2(0, 550, 0, 600), -- Much bigger for more content
            Position = ScreenUtils.udim2(0.5, -275, 0.5, -300), -- Center on screen
            BackgroundColor3 = Color3.fromRGB(255, 255, 255), -- White background
            BackgroundTransparency = 0,
            ZIndex = 201,
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
            
            -- Background pattern like other modern UIs
            BackgroundPattern = React.createElement("ImageLabel", {
                Name = "BackgroundPattern",
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                Image = "rbxassetid://116367512866072",
                ImageTransparency = 0.95, -- Very faint background
                ScaleType = Enum.ScaleType.Tile,
                TileSize = UDim2.new(0, 50, 0, 50),
                ZIndex = 201, -- Behind content
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 15),
                }),
            }),
        
            -- Header section
            Header = React.createElement("Frame", {
                Size = ScreenUtils.udim2(1, 0, 0, 60),
                BackgroundTransparency = 1,
                ZIndex = 203,
            }, {
                -- Title Container (centered)
                TitleContainer = React.createElement("Frame", {
                    Size = ScreenUtils.udim2(0, 250, 1, 0),
                    Position = ScreenUtils.udim2(0.5, -125, 0, 0),
                    BackgroundTransparency = 1,
                    ZIndex = 204,
                }, {
                    -- Debug Icon
                    DebugIcon = React.createElement("ImageLabel", {
                        Size = ScreenUtils.udim2(0, 40, 0, 40),
                        Position = ScreenUtils.udim2(0, 0, 0.5, -20),
                        BackgroundTransparency = 1,
                        Image = IconAssets.getIcon("UI", "SETTINGS"),
                        ScaleType = Enum.ScaleType.Fit,
                        ZIndex = 205,
                    }),
                    
                    -- Title Text
                    Title = React.createElement("TextLabel", {
                        Size = ScreenUtils.udim2(0, 200, 1, 0),
                        Position = ScreenUtils.udim2(0, 50, 0, 0),
                        BackgroundTransparency = 1,
                        Text = "Enhanced Debug Panel",
                        TextColor3 = Color3.fromRGB(50, 50, 50), -- Dark text
                        TextSize = ScreenUtils.TEXT_SIZES.LARGE() + 2,
                        TextStrokeTransparency = 0,
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        Font = Enum.Font.FredokaOne,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        ZIndex = 205,
                    }),
                }),
                
                -- Close button (right side)
                CloseButton = React.createElement("ImageButton", {
                    Size = ScreenUtils.udim2(0, 50, 0, 50), -- Bigger close button
                    Position = ScreenUtils.udim2(1, -55, 0.5, -25),
                    BackgroundColor3 = Color3.fromRGB(255, 100, 100), -- Light red
                    Image = IconAssets.getIcon("UI", "X_BUTTON"),
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 205,
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
            
            -- Tab navigation
            TabContainer = React.createElement("Frame", {
                Size = ScreenUtils.udim2(1, -20, 0, 50),
                Position = ScreenUtils.udim2(0, 10, 0, 70),
                BackgroundTransparency = 1,
                ZIndex = 202,
            }, {
                TabLayout = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = ScreenUtils.udim(0, 5)
                }),
                
                ResourcesTab = createTabButton("resources", "💰 Resources", 1),
                PetsTab = createTabButton("pets", "🐕 Pets", 2),
                PotionsTab = createTabButton("potions", "🧪 Potions", 3),
                DataTab = createTabButton("data", "⚠️ Data", 4),
                UtilsTab = createTabButton("utils", "🔧 Utils", 5),
                UITestTab = createTabButton("uitest", "🎨 UI Test", 6),
            }),
        
            -- Scrollable content area
            ContentScrollFrame = React.createElement("ScrollingFrame", {
                Size = ScreenUtils.udim2(1, -40, 1, -140),
                Position = ScreenUtils.udim2(0, 20, 0, 130),
                BackgroundTransparency = 1,
                ScrollBarThickness = 8,
                ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100),
                ZIndex = 202,
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                CanvasSize = UDim2.new(0, 0, 0, 0)
            }, {
                ContentLayout = React.createElement("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = ScreenUtils.udim(0, 8)
                }),
                
                ContentPadding = React.createElement("UIPadding", {
                    PaddingTop = ScreenUtils.udim(0, 10),
                    PaddingBottom = ScreenUtils.udim(0, 10),
                    PaddingLeft = ScreenUtils.udim(0, 5),
                    PaddingRight = ScreenUtils.udim(0, 15),
                }),
                
                -- Resources Tab Content
                ResourcesContent = selectedTab == "resources" and React.createElement(React.Fragment, nil, {
                    MoneyHeader = createSectionHeader("💰 Money Controls", Color3.fromRGB(0, 162, 255), 1),
                    
                    Money100Button = createButton({
                        text = "+100 Money",
                        color = Color3.fromRGB(0, 200, 100),
                        layoutOrder = 2,
                        size = ScreenUtils.udim2(1, 0, 0, 35),
                        onActivated = function() addMoney(100) end
                    }),
                    
                    Money1kButton = createButton({
                        text = "+1,000 Money",
                        color = Color3.fromRGB(0, 180, 100),
                        layoutOrder = 3,
                        size = ScreenUtils.udim2(1, 0, 0, 35),
                        onActivated = function() addMoney(1000) end
                    }),
                    
                    Money10kButton = createButton({
                        text = "+10,000 Money",
                        color = Color3.fromRGB(0, 160, 100),
                        layoutOrder = 4,
                        size = ScreenUtils.udim2(1, 0, 0, 35),
                        onActivated = function() addMoney(10000) end
                    }),
                    
                    Money100kButton = createButton({
                        text = "+100,000 Money",
                        color = Color3.fromRGB(0, 140, 100),
                        layoutOrder = 5,
                        size = ScreenUtils.udim2(1, 0, 0, 35),
                        onActivated = function() addMoney(100000) end
                    }),
                    
                    DiamondHeader = createSectionHeader("💎 Diamond Controls", Color3.fromRGB(255, 100, 255), 6),
                    
                    Diamonds10Button = createButton({
                        text = "+10 Diamonds",
                        color = Color3.fromRGB(200, 0, 200),
                        layoutOrder = 7,
                        size = ScreenUtils.udim2(1, 0, 0, 35),
                        onActivated = function() addDiamonds(10) end
                    }),
                    
                    Diamonds100Button = createButton({
                        text = "+100 Diamonds",
                        color = Color3.fromRGB(180, 0, 180),
                        layoutOrder = 8,
                        size = ScreenUtils.udim2(1, 0, 0, 35),
                        onActivated = function() addDiamonds(100) end
                    }),
                    
                    Diamonds1000Button = createButton({
                        text = "+1,000 Diamonds",
                        color = Color3.fromRGB(160, 0, 160),
                        layoutOrder = 9,
                        size = ScreenUtils.udim2(1, 0, 0, 35),
                        onActivated = function() addDiamonds(1000) end
                    }),
                    
                    RebirthHeader = createSectionHeader("🔄 Rebirth Controls", Color3.fromRGB(255, 150, 0), 10),
                    
                    RebirthButton = createButton({
                        text = "🔄 +1 Rebirth",
                        color = Color3.fromRGB(255, 140, 0),
                        layoutOrder = 11,
                        size = ScreenUtils.udim2(1, 0, 0, 40),
                        strokeThickness = 3,
                        onActivated = giveRebirth
                    }),
                }) or nil,
                
                -- Pets Tab Content
                PetsContent = selectedTab == "pets" and React.createElement(React.Fragment, nil, {
                    PetHeader = createSectionHeader("🐕 Custom Pet Creator", Color3.fromRGB(255, 165, 0), 1),
                    
                    -- Pet Name Input
                    NameLabel = React.createElement("TextLabel", {
                        Size = ScreenUtils.udim2(1, 0, 0, 25),
                        BackgroundTransparency = 1,
                        Text = "Pet Name:",
                        TextColor3 = Color3.fromRGB(50, 50, 50),
                        TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                        Font = Enum.Font.FredokaOne,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        LayoutOrder = 2,
                        ZIndex = 203
                    }),
                    
                    NameInput = React.createElement("TextBox", {
                        Size = ScreenUtils.udim2(1, 0, 0, 35),
                        BackgroundColor3 = Color3.fromRGB(240, 240, 240),
                        BorderSizePixel = 0,
                        Text = petName,
                        TextColor3 = Color3.fromRGB(50, 50, 50),
                        TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                        Font = Enum.Font.FredokaOne,
                        PlaceholderText = "Enter pet name...",
                        LayoutOrder = 3,
                        ZIndex = 203,
                        [React.Event.FocusLost] = function(rbx)
                            setPetName(rbx.Text)
                        end
                    }, {
                        Corner = React.createElement("UICorner", {
                            CornerRadius = ScreenUtils.udim(0, 8)
                        }),
                        Outline = React.createElement("UIStroke", {
                            Thickness = 2,
                            Color = Color3.fromRGB(0, 0, 0),
                            Transparency = 0,
                            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                        }),
                    }),
                    
                    -- Pet Boost Input
                    BoostLabel = React.createElement("TextLabel", {
                        Size = ScreenUtils.udim2(1, 0, 0, 25),
                        BackgroundTransparency = 1,
                        Text = "Pet Boost (multiplier):",
                        TextColor3 = Color3.fromRGB(50, 50, 50),
                        TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                        Font = Enum.Font.FredokaOne,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        LayoutOrder = 4,
                        ZIndex = 203
                    }),
                    
                    BoostInput = React.createElement("TextBox", {
                        Size = ScreenUtils.udim2(1, 0, 0, 35),
                        BackgroundColor3 = Color3.fromRGB(240, 240, 240),
                        BorderSizePixel = 0,
                        Text = petBoost,
                        TextColor3 = Color3.fromRGB(50, 50, 50),
                        TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                        Font = Enum.Font.FredokaOne,
                        PlaceholderText = "e.g., 1.5, 10, 100",
                        LayoutOrder = 5,
                        ZIndex = 203,
                        [React.Event.FocusLost] = function(rbx)
                            setPetBoost(rbx.Text)
                        end
                    }, {
                        Corner = React.createElement("UICorner", {
                            CornerRadius = ScreenUtils.udim(0, 8)
                        }),
                        Outline = React.createElement("UIStroke", {
                            Thickness = 2,
                            Color = Color3.fromRGB(0, 0, 0),
                            Transparency = 0,
                            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                        }),
                    }),
                    
                    -- Pet Value Input
                    ValueLabel = React.createElement("TextLabel", {
                        Size = ScreenUtils.udim2(1, 0, 0, 25),
                        BackgroundTransparency = 1,
                        Text = "Pet Value (money when processed):",
                        TextColor3 = Color3.fromRGB(50, 50, 50),
                        TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                        Font = Enum.Font.FredokaOne,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        LayoutOrder = 6,
                        ZIndex = 203
                    }),
                    
                    ValueInput = React.createElement("TextBox", {
                        Size = ScreenUtils.udim2(1, 0, 0, 35),
                        BackgroundColor3 = Color3.fromRGB(240, 240, 240),
                        BorderSizePixel = 0,
                        Text = petValue,
                        TextColor3 = Color3.fromRGB(50, 50, 50),
                        TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                        Font = Enum.Font.FredokaOne,
                        PlaceholderText = "e.g., 500, 1000, 5000",
                        LayoutOrder = 7,
                        ZIndex = 203,
                        [React.Event.FocusLost] = function(rbx)
                            setPetValue(rbx.Text)
                        end
                    }, {
                        Corner = React.createElement("UICorner", {
                            CornerRadius = ScreenUtils.udim(0, 8)
                        }),
                        Outline = React.createElement("UIStroke", {
                            Thickness = 2,
                            Color = Color3.fromRGB(0, 0, 0),
                            Transparency = 0,
                            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                        }),
                    }),
                    
                    -- Create Pet Button
                    CreatePetButton = createButton({
                        text = "🐕 Create Custom Pet",
                        color = Color3.fromRGB(255, 140, 0),
                        layoutOrder = 8,
                        size = ScreenUtils.udim2(1, 0, 0, 45),
                        strokeThickness = 3,
                        onActivated = createCustomPet
                    }),
                }) or nil,
                
                -- Potions Tab Content
                PotionsContent = selectedTab == "potions" and React.createElement(React.Fragment, nil, {
                    PotionHeader = createSectionHeader("🧪 Potion Debug Commands", Color3.fromRGB(138, 43, 226), 1),
                    
                    DiamondPotionButton = createButton({
                        text = "Give 5x Diamond Potions",
                        color = Color3.fromRGB(0, 191, 255),
                        layoutOrder = 2,
                        size = ScreenUtils.udim2(1, 0, 0, 35),
                        onActivated = giveDiamondPotion
                    }),
                    
                    MoneyPotionButton = createButton({
                        text = "Give 5x Money Potions",
                        color = Color3.fromRGB(255, 215, 0),
                        layoutOrder = 3,
                        size = ScreenUtils.udim2(1, 0, 0, 35),
                        onActivated = giveMoneyPotion
                    }),
                    
                    PetMagnetPotionButton = createButton({
                        text = "Give Pet Magnet Potions",
                        color = Color3.fromRGB(50, 255, 50),
                        layoutOrder = 4,
                        size = ScreenUtils.udim2(1, 0, 0, 35),
                        onActivated = givePetMagnetPotion
                    })
                    
                }) or nil,
                
                -- Data Tab Content
                DataContent = selectedTab == "data" and React.createElement(React.Fragment, nil, {
                    DataHeader = createSectionHeader("⚠️ Data Management", Color3.fromRGB(255, 100, 100), 1),
                    
                    ResetDataButton = createButton({
                        text = "⚠️ Reset All Data",
                        color = Color3.fromRGB(220, 50, 50),
                        layoutOrder = 2,
                        size = ScreenUtils.udim2(1, 0, 0, 45),
                        strokeThickness = 3,
                        onActivated = resetPlayerData
                    }),
                    
                    -- Daily Rewards Debug Section
                    DailyRewardsHeader = createSectionHeader("🎁 Daily Rewards Debug", Color3.fromRGB(255, 100, 255), 3),
                    
                    SetLastLoginYesterdayButton = createButton({
                        text = "🎁 Set Last Login Yesterday",
                        color = Color3.fromRGB(255, 150, 255),
                        layoutOrder = 4,
                        size = ScreenUtils.udim2(1, 0, 0, 40),
                        onActivated = setLastLoginYesterday
                    }),
                    
                    ResetDailyRewardsButton = createButton({
                        text = "🔄 Reset Daily Rewards",
                        color = Color3.fromRGB(150, 100, 255),
                        layoutOrder = 5,
                        size = ScreenUtils.udim2(1, 0, 0, 40),
                        onActivated = resetDailyRewards
                    }),
                }) or nil,
                
                -- Utils Tab Content  
                UtilsContent = selectedTab == "utils" and React.createElement(React.Fragment, nil, {
                    TutorialHeader = createSectionHeader("🎯 Tutorial Controls", Color3.fromRGB(100, 150, 255), 1),
                    
                    StartTutorialButton = createButton({
                        text = "🎯 Start Tutorial",
                        color = Color3.fromRGB(100, 150, 255),
                        layoutOrder = 2,
                        size = ScreenUtils.udim2(1, 0, 0, 35),
                        onActivated = startTutorial
                    }),
                    
                    StopTutorialButton = createButton({
                        text = "⏹️ Stop Tutorial",
                        color = Color3.fromRGB(150, 150, 150),
                        layoutOrder = 3,
                        size = ScreenUtils.udim2(1, 0, 0, 35),
                        onActivated = stopTutorial
                    }),
                }) or nil,
                
                -- UI Testing Tab Content
                UITestContent = selectedTab == "uitest" and React.createElement(React.Fragment, nil, {
                    UITestHeader = createSectionHeader("🎨 UI Testing Controls", Color3.fromRGB(255, 100, 255), 1),
                    
                    PetDiscoveryButton = createButton({
                        text = "🦎 Trigger Pet Discovery (Bronze Gecko)",
                        color = Color3.fromRGB(0, 255, 255),
                        layoutOrder = 2,
                        size = ScreenUtils.udim2(1, 0, 0, 40),
                        onActivated = triggerPetDiscovery
                    }),
                    
                    RewardPopupButton = createButton({
                        text = "💰 Trigger Reward Popup (1000 Money)",
                        color = Color3.fromRGB(100, 255, 100),
                        layoutOrder = 3,
                        size = ScreenUtils.udim2(1, 0, 0, 40),
                        onActivated = triggerRewardPopup
                    }),
                    
                    UITestNote = React.createElement("TextLabel", {
                        Size = ScreenUtils.udim2(1, 0, 0, 60),
                        BackgroundTransparency = 1,
                        Text = "⚠️ These buttons trigger UI popups only.\nNo actual rewards are given.",
                        TextColor3 = Color3.fromRGB(255, 200, 100),
                        TextSize = ScreenUtils.TEXT_SIZES.SMALL(),
                        Font = Enum.Font.SourceSans,
                        TextWrapped = true,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        LayoutOrder = 4,
                    }),
                }) or nil,
            })
        })
    })
end

return DebugPanel