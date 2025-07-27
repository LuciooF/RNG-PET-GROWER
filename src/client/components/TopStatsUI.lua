-- TopStatsUI - Displays player resources at the top of the screen
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local React = require(ReplicatedStorage.Packages.react)
local DataSyncService = require(script.Parent.Parent.services.DataSyncService)

local player = Players.LocalPlayer

local function TopStatsUI()
    local playerData, setPlayerData = React.useState({
        Resources = {
            Money = 0,
            Diamonds = 0,
            Rebirths = 0
        }
    })
    
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
    
    -- Format numbers for display
    local function formatNumber(num)
        if num >= 1000000 then
            return string.format("%.1fM", num / 1000000)
        elseif num >= 1000 then
            return string.format("%.1fK", num / 1000)
        else
            return tostring(num)
        end
    end
    
    return React.createElement("ScreenGui", {
        Name = "TopStatsUI",
        ResetOnSpawn = false
    }, {
        MainFrame = React.createElement("Frame", {
            Name = "MainFrame",
            Size = UDim2.new(0, 500, 0, 60),
            Position = UDim2.new(0.5, -250, 0, 10),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 0.3,
            BorderSizePixel = 2,
            BorderColor3 = Color3.fromRGB(255, 255, 255)
        }, {
            UICorner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0, 8)
            }),
            
            UIListLayout = React.createElement("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 20)
            }),
            
            -- Money Display
            MoneyFrame = React.createElement("Frame", {
                Name = "MoneyFrame",
                Size = UDim2.new(0, 140, 1, 0),
                BackgroundTransparency = 1
            }, {
                UIListLayout = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 8)
                }),
                
                MoneyIcon = React.createElement("TextLabel", {
                    Name = "MoneyIcon",
                    Size = UDim2.new(0, 30, 0, 30),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextSize = 24,
                    TextColor3 = Color3.fromRGB(85, 255, 85),
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    Text = "$"
                }),
                
                MoneyLabel = React.createElement("TextLabel", {
                    Name = "MoneyLabel",
                    Size = UDim2.new(0, 100, 0, 30),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    TextSize = 18,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    Text = formatNumber(playerData.Resources.Money),
                    TextXAlignment = Enum.TextXAlignment.Left
                })
            }),
            
            -- Diamonds Display
            DiamondsFrame = React.createElement("Frame", {
                Name = "DiamondsFrame",
                Size = UDim2.new(0, 140, 1, 0),
                BackgroundTransparency = 1
            }, {
                UIListLayout = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 8)
                }),
                
                DiamondsIcon = React.createElement("TextLabel", {
                    Name = "DiamondsIcon",
                    Size = UDim2.new(0, 30, 0, 30),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextSize = 24,
                    TextColor3 = Color3.fromRGB(185, 242, 255),
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    Text = "💎"
                }),
                
                DiamondsLabel = React.createElement("TextLabel", {
                    Name = "DiamondsLabel",
                    Size = UDim2.new(0, 100, 0, 30),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    TextSize = 18,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    Text = formatNumber(playerData.Resources.Diamonds),
                    TextXAlignment = Enum.TextXAlignment.Left
                })
            }),
            
            -- Rebirths Display
            RebirthsFrame = React.createElement("Frame", {
                Name = "RebirthsFrame",
                Size = UDim2.new(0, 140, 1, 0),
                BackgroundTransparency = 1
            }, {
                UIListLayout = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 8)
                }),
                
                RebirthsIcon = React.createElement("TextLabel", {
                    Name = "RebirthsIcon",
                    Size = UDim2.new(0, 30, 0, 30),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextSize = 24,
                    TextColor3 = Color3.fromRGB(255, 215, 0),
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    Text = "⭐"
                }),
                
                RebirthsLabel = React.createElement("TextLabel", {
                    Name = "RebirthsLabel",
                    Size = UDim2.new(0, 100, 0, 30),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    TextSize = 18,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    Text = formatNumber(playerData.Resources.Rebirths),
                    TextXAlignment = Enum.TextXAlignment.Left
                })
            })
        })
    })
end

return TopStatsUI