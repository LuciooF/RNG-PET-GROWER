-- Modern DebugPanel - Developer tools for testing with modern theme
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local React = require(ReplicatedStorage.Packages.react)
local DataSyncService = require(script.Parent.Parent.services.DataSyncService)
local TutorialService = require(script.Parent.Parent.services.TutorialService)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)

local function DebugPanel(props)
    local isVisible, setIsVisible = React.useState(props.visible or false)
    
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
    
    -- Debug functions
    local function addMoney(amount)
        DataSyncService:UpdateResource("Money", amount)
    end
    
    local function resetPlayerData()
        -- Fire remote event to reset data on server
        local resetDataRemote = ReplicatedStorage:FindFirstChild("ResetPlayerData")
        if resetDataRemote then
            resetDataRemote:FireServer()
        end
    end
    
    local function startTutorial()
        print("DebugPanel: Starting tutorial manually")
        TutorialService:StartTutorial()
    end
    
    local function stopTutorial()
        print("DebugPanel: Stopping tutorial manually")
        TutorialService:StopTutorial()
    end
    
    local function grantOPPet()
        -- Grant the Constellation King OP pet for testing
        local purchaseOPPetRemote = ReplicatedStorage:FindFirstChild("PurchaseOPPet")
        if purchaseOPPetRemote then
            -- Simulate the purchase by sending a test remote
            local debugGrantOPRemote = ReplicatedStorage:FindFirstChild("DebugGrantOPPet")
            if debugGrantOPRemote then
                debugGrantOPRemote:FireServer("Constellation King")
            end
        end
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
        -- Modern modal container
        DebugModal = React.createElement("Frame", {
            Name = "DebugModal",
            Size = ScreenUtils.udim2(0, 400, 0, 400), -- Bigger modern modal
            Position = ScreenUtils.udim2(0.5, -200, 0.5, -200), -- Center on screen
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
                    Size = ScreenUtils.udim2(0, 200, 1, 0),
                    Position = ScreenUtils.udim2(0.5, -100, 0, 0),
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
                        Size = ScreenUtils.udim2(0, 150, 1, 0),
                        Position = ScreenUtils.udim2(0, 50, 0, 0),
                        BackgroundTransparency = 1,
                        Text = "Debug Panel",
                        TextColor3 = Color3.fromRGB(50, 50, 50), -- Dark text
                        TextSize = ScreenUtils.TEXT_SIZES.LARGE() + 4,
                        TextStrokeTransparency = 0,
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        Font = Enum.Font.GothamBold,
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
        
            -- Content area
            Content = React.createElement("Frame", {
                Size = ScreenUtils.udim2(1, -40, 1, -80),
                Position = ScreenUtils.udim2(0, 20, 0, 70),
                BackgroundTransparency = 1,
                ZIndex = 202
            }, {
                Layout = React.createElement("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = ScreenUtils.udim(0, 12)
                }),
                
                -- Money section header
                MoneyLabel = React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(1, 0, 0, 30),
                    BackgroundTransparency = 1,
                    Text = "Money Controls",
                    TextColor3 = Color3.fromRGB(0, 162, 255), -- Blue theme
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() + 2,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    LayoutOrder = 1,
                    ZIndex = 203
                }),
            
                Money100Button = React.createElement("TextButton", {
                    Size = ScreenUtils.udim2(1, 0, 0, 35),
                    BackgroundColor3 = Color3.fromRGB(0, 200, 100), -- Modern green
                    BorderSizePixel = 0,
                    Text = "+100 Money",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    Font = Enum.Font.GothamBold,
                    LayoutOrder = 2,
                    ZIndex = 203,
                    [React.Event.Activated] = function()
                        addMoney(100)
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
            
                Money1kButton = React.createElement("TextButton", {
                    Size = ScreenUtils.udim2(1, 0, 0, 35),
                    BackgroundColor3 = Color3.fromRGB(0, 180, 100), -- Slightly darker green
                    BorderSizePixel = 0,
                    Text = "+1,000 Money",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    Font = Enum.Font.GothamBold,
                    LayoutOrder = 3,
                    ZIndex = 203,
                    [React.Event.Activated] = function()
                        addMoney(1000)
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
            
                Money10kButton = React.createElement("TextButton", {
                    Size = ScreenUtils.udim2(1, 0, 0, 35),
                    BackgroundColor3 = Color3.fromRGB(0, 160, 100), -- Darker green
                    BorderSizePixel = 0,
                    Text = "+10,000 Money",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    Font = Enum.Font.GothamBold,
                    LayoutOrder = 4,
                    ZIndex = 203,
                    [React.Event.Activated] = function()
                        addMoney(10000)
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
            
                -- Data section header
                DataLabel = React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(1, 0, 0, 30),
                    BackgroundTransparency = 1,
                    Text = "Data Controls",
                    TextColor3 = Color3.fromRGB(255, 100, 100), -- Red theme for dangerous operations
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() + 2,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    LayoutOrder = 5,
                    ZIndex = 203
                }),
            
                ResetDataButton = React.createElement("TextButton", {
                    Size = ScreenUtils.udim2(1, 0, 0, 40), -- Bigger for dangerous action
                    BackgroundColor3 = Color3.fromRGB(220, 50, 50), -- Modern red
                    BorderSizePixel = 0,
                    Text = "⚠️ Reset All Data",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() + 1,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    Font = Enum.Font.GothamBold,
                    LayoutOrder = 6,
                    ZIndex = 203,
                    [React.Event.Activated] = function()
                        resetPlayerData()
                    end
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, 8)
                    }),
                    Outline = React.createElement("UIStroke", {
                        Thickness = 3, -- Thicker outline for danger
                        Color = Color3.fromRGB(0, 0, 0),
                        Transparency = 0,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    }),
                }),
                
                StartTutorialButton = React.createElement("TextButton", {
                    Size = ScreenUtils.udim2(1, 0, 0, 35),
                    BackgroundColor3 = Color3.fromRGB(100, 150, 255), -- Blue for tutorial
                    BorderSizePixel = 0,
                    Text = "🎯 Start Tutorial",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                    Font = Enum.Font.GothamBold,
                    LayoutOrder = 7,
                    ZIndex = 203,
                    [React.Event.Activated] = function()
                        startTutorial()
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
                
                StopTutorialButton = React.createElement("TextButton", {
                    Size = ScreenUtils.udim2(1, 0, 0, 35),
                    BackgroundColor3 = Color3.fromRGB(150, 150, 150), -- Gray for stop
                    BorderSizePixel = 0,
                    Text = "⏹️ Stop Tutorial",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                    Font = Enum.Font.GothamBold,
                    LayoutOrder = 8,
                    ZIndex = 203,
                    [React.Event.Activated] = function()
                        stopTutorial()
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
                
                GrantOPPetButton = React.createElement("TextButton", {
                    Size = ScreenUtils.udim2(1, 0, 0, 35),
                    BackgroundColor3 = Color3.fromRGB(255, 100, 255), -- Magenta for OP pets
                    BorderSizePixel = 0,
                    Text = "🌟 Grant OP Pet",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                    Font = Enum.Font.GothamBold,
                    LayoutOrder = 9,
                    ZIndex = 203,
                    [React.Event.Activated] = function()
                        grantOPPet()
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
                })
            })
        })
    })
end

return DebugPanel