-- RebirthUI - Modal for rebirth functionality
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.react)

local store = require(ReplicatedStorage.store)

local RebirthUI = {}

function RebirthUI.new(props)
    return React.createElement("Frame", {
        Name = "RebirthPanel",
        Size = UDim2.new(0, 400, 0, 300),
        Position = UDim2.new(0.5, -200, 0.5, -150),
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        BorderSizePixel = 0,
        ZIndex = 10,
        Visible = props.visible
    }, {
        -- Background blur effect
        UICorner = React.createElement("UICorner", {
            CornerRadius = UDim.new(0, 12)
        }),
        
        -- Title
        Title = React.createElement("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -40, 0, 50),
            Position = UDim2.new(0, 20, 0, 20),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            Text = "Rebirth",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 24,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 11
        }),
        
        -- Close button
        CloseButton = React.createElement("TextButton", {
            Name = "CloseButton",
            Size = UDim2.new(0, 30, 0, 30),
            Position = UDim2.new(1, -40, 0, 15),
            BackgroundColor3 = Color3.fromRGB(200, 50, 50),
            BorderSizePixel = 0,
            Font = Enum.Font.GothamBold,
            Text = "×",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 18,
            ZIndex = 11,
            [React.Event.Activated] = props.onClose
        }, {
            UICorner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0, 6)
            })
        }),
        
        -- Description
        Description = React.createElement("TextLabel", {
            Name = "Description",
            Size = UDim2.new(1, -40, 0, 80),
            Position = UDim2.new(0, 20, 0, 80),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            Text = "Rebirth to gain permanent bonuses!\n\nCost: 1,000 Money\n\nThis will reset your money, plots, doors, and pets.",
            TextColor3 = Color3.fromRGB(200, 200, 200),
            TextSize = 14,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 11
        }),
        
        -- Current stats
        StatsContainer = React.createElement("Frame", {
            Name = "StatsContainer",
            Size = UDim2.new(1, -40, 0, 60),
            Position = UDim2.new(0, 20, 0, 170),
            BackgroundColor3 = Color3.fromRGB(30, 30, 30),
            BorderSizePixel = 0,
            ZIndex = 11
        }, {
            UICorner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0, 8)
            }),
            
            MoneyLabel = React.createElement("TextLabel", {
                Name = "MoneyLabel",
                Size = UDim2.new(0.5, -10, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = "Money: " .. (props.playerMoney or 0),
                TextColor3 = Color3.fromRGB(255, 215, 0),
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 12
            }),
            
            RebirthsLabel = React.createElement("TextLabel", {
                Name = "RebirthsLabel",
                Size = UDim2.new(0.5, -10, 1, 0),
                Position = UDim2.new(0.5, 0, 0, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = "Rebirths: " .. (props.playerRebirths or 0),
                TextColor3 = Color3.fromRGB(138, 43, 226),
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 12
            })
        }),
        
        -- Rebirth button
        RebirthButton = React.createElement("TextButton", {
            Name = "RebirthButton",
            Size = UDim2.new(0, 200, 0, 40),
            Position = UDim2.new(0.5, -100, 1, -60),
            BackgroundColor3 = props.canRebirth and Color3.fromRGB(138, 43, 226) or Color3.fromRGB(100, 100, 100),
            BorderSizePixel = 0,
            Font = Enum.Font.GothamBold,
            Text = props.canRebirth and "REBIRTH" or "Need 1,000 Money",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 18,
            ZIndex = 11,
            [React.Event.Activated] = props.canRebirth and props.onRebirth or nil
        }, {
            UICorner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0, 8)
            })
        })
    })
end

return RebirthUI