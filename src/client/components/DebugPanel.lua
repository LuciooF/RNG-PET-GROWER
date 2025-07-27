-- DebugPanel - Developer tools for testing
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local React = require(ReplicatedStorage.Packages.react)
local DataSyncService = require(script.Parent.Parent.services.DataSyncService)

local function DebugPanel()
    local isVisible, setIsVisible = React.useState(false)
    
    -- Toggle with F1 key
    React.useEffect(function()
        local connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            if input.KeyCode == Enum.KeyCode.F1 then
                setIsVisible(function(prev) return not prev end)
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
    
    if not isVisible then
        return React.createElement("Frame", {
            Size = UDim2.new(0, 120, 0, 30),
            Position = UDim2.new(1, -130, 0, 10),
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            BorderSizePixel = 0,
            ZIndex = 200
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0, 8)
            }),
            
            OpenButton = React.createElement("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "Debug (F1)",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                Font = Enum.Font.Gotham,
                ZIndex = 201,
                [React.Event.Activated] = function()
                    setIsVisible(true)
                end
            })
        })
    end
    
    return React.createElement("Frame", {
        Size = UDim2.new(0, 300, 0, 250),
        Position = UDim2.new(1, -310, 0, 10),
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        BorderSizePixel = 2,
        BorderColor3 = Color3.fromRGB(255, 100, 100),
        ZIndex = 200
    }, {
        Corner = React.createElement("UICorner", {
            CornerRadius = UDim.new(0, 8)
        }),
        
        -- Header
        Header = React.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            BorderSizePixel = 0,
            ZIndex = 201
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0, 8)
            }),
            
            Title = React.createElement("TextLabel", {
                Size = UDim2.new(1, -40, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = "🛠️ Debug Panel",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 202
            }),
            
            CloseButton = React.createElement("TextButton", {
                Size = UDim2.new(0, 30, 0, 30),
                Position = UDim2.new(1, -35, 0.5, -15),
                BackgroundColor3 = Color3.fromRGB(200, 50, 50),
                BorderSizePixel = 0,
                Text = "✕",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                Font = Enum.Font.GothamBold,
                ZIndex = 202,
                [React.Event.Activated] = function()
                    setIsVisible(false)
                end
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 4)
                })
            })
        }),
        
        -- Content
        Content = React.createElement("Frame", {
            Size = UDim2.new(1, -20, 1, -60),
            Position = UDim2.new(0, 10, 0, 50),
            BackgroundTransparency = 1,
            ZIndex = 201
        }, {
            Layout = React.createElement("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 10)
            }),
            
            -- Money buttons
            MoneyLabel = React.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0, 25),
                BackgroundTransparency = 1,
                Text = "💰 Money Controls",
                TextColor3 = Color3.fromRGB(255, 215, 0),
                TextScaled = true,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = 1,
                ZIndex = 202
            }),
            
            Money100Button = React.createElement("TextButton", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = Color3.fromRGB(0, 150, 0),
                BorderSizePixel = 0,
                Text = "+100 Money",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                Font = Enum.Font.Gotham,
                LayoutOrder = 2,
                ZIndex = 202,
                [React.Event.Activated] = function()
                    addMoney(100)
                end
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 4)
                })
            }),
            
            Money1kButton = React.createElement("TextButton", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = Color3.fromRGB(0, 120, 0),
                BorderSizePixel = 0,
                Text = "+1,000 Money",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                Font = Enum.Font.Gotham,
                LayoutOrder = 3,
                ZIndex = 202,
                [React.Event.Activated] = function()
                    addMoney(1000)
                end
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 4)
                })
            }),
            
            Money10kButton = React.createElement("TextButton", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = Color3.fromRGB(0, 100, 0),
                BorderSizePixel = 0,
                Text = "+10,000 Money",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                Font = Enum.Font.Gotham,
                LayoutOrder = 4,
                ZIndex = 202,
                [React.Event.Activated] = function()
                    addMoney(10000)
                end
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 4)
                })
            }),
            
            -- Data controls
            DataLabel = React.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0, 25),
                BackgroundTransparency = 1,
                Text = "🗃️ Data Controls",
                TextColor3 = Color3.fromRGB(255, 100, 100),
                TextScaled = true,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = 5,
                ZIndex = 202
            }),
            
            ResetDataButton = React.createElement("TextButton", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = Color3.fromRGB(150, 0, 0),
                BorderSizePixel = 0,
                Text = "⚠️ Reset All Data",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                Font = Enum.Font.GothamBold,
                LayoutOrder = 6,
                ZIndex = 202,
                [React.Event.Activated] = function()
                    resetPlayerData()
                end
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 4)
                })
            })
        })
    })
end

return DebugPanel