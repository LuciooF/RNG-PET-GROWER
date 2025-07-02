local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages.react)
local e = React.createElement

local function DebugUI()
    local isVisible, setIsVisible = React.useState(false)
    
    -- print("DebugUI component loaded")
    
    -- Expose global toggle function
    React.useEffect(function()
        _G.DebugUI = {
            toggle = function()
                setIsVisible(function(current) 
                    return not current 
                end)
            end
        }
        
        return function()
            _G.DebugUI = nil
        end
    end, {})
    
    local function fireRemoteEvent(remoteName)
        local remotes = ReplicatedStorage:WaitForChild("Remotes")
        local remote = remotes:FindFirstChild(remoteName)
        if remote then
            remote:FireServer()
        end
    end
    
    -- Debug Panel (only render when visible, no toggle button)
    return isVisible and e("Frame", {
        Name = "DebugUI",
        Size = UDim2.new(0, 250, 0, 300),
        Position = UDim2.new(0.5, -125, 0.5, -150),
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        BorderSizePixel = 0,
        ZIndex = 100
    }, {
        Corner = e("UICorner", {
            CornerRadius = UDim.new(0, 8)
        }),
        
        Stroke = e("UIStroke", {
            Color = Color3.fromRGB(255, 255, 255),
            Thickness = 2,
            Transparency = 0.5
        }),
        
        Title = e("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, 0, 0, 40),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = "DEBUG PANEL",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 16,
            Font = Enum.Font.SourceSansBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 101
        }),
        
        ButtonContainer = e("Frame", {
            Name = "ButtonContainer",
            Size = UDim2.new(1, -20, 1, -60),
            Position = UDim2.new(0, 10, 0, 50),
            BackgroundTransparency = 1,
            ZIndex = 101
        }, {
            Layout = e("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                Padding = UDim.new(0, 10),
                SortOrder = Enum.SortOrder.LayoutOrder
            }),
            
            AddMoneyButton = e("TextButton", {
                Name = "AddMoneyButton",
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundColor3 = Color3.fromRGB(0, 150, 0),
                BorderSizePixel = 0,
                Text = "Add 1000 Money",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 14,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 102,
                LayoutOrder = 1,
                [React.Event.MouseButton1Click] = function()
                    fireRemoteEvent("DebugAddMoney")
                end
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 6)
                })
            }),
            
            AddDiamondsButton = e("TextButton", {
                Name = "AddDiamondsButton",
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundColor3 = Color3.fromRGB(0, 150, 255),
                BorderSizePixel = 0,
                Text = "Add 1000 Diamonds",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 14,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 102,
                LayoutOrder = 2,
                [React.Event.MouseButton1Click] = function()
                    fireRemoteEvent("DebugAddDiamonds")
                end
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 6)
                })
            }),
            
            AddRebirthButton = e("TextButton", {
                Name = "AddRebirthButton",
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundColor3 = Color3.fromRGB(255, 150, 0),
                BorderSizePixel = 0,
                Text = "Add 1 Rebirth",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 14,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 102,
                LayoutOrder = 3,
                [React.Event.MouseButton1Click] = function()
                    fireRemoteEvent("DebugAddRebirths")
                end
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 6)
                })
            }),
            
            ResetDataButton = e("TextButton", {
                Name = "ResetDataButton",
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundColor3 = Color3.fromRGB(200, 50, 50),
                BorderSizePixel = 0,
                Text = "RESET DATA",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 14,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 102,
                LayoutOrder = 4,
                [React.Event.MouseButton1Click] = function()
                    fireRemoteEvent("DebugResetData")
                end
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 6)
                })
            }),
            
            Instructions = e("TextLabel", {
                Name = "Instructions",
                Size = UDim2.new(1, 0, 0, 60),
                BackgroundTransparency = 1,
                Text = "Click the shop button\nto toggle this panel.",
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextSize = 12,
                Font = Enum.Font.SourceSans,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextWrapped = true,
                ZIndex = 101,
                LayoutOrder = 5
            })
        })
    }) or nil
end

return DebugUI