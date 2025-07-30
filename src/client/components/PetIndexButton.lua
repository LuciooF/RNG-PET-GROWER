-- Pet Index Button - A UI button to open the Pet Index
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.react)

local function PetIndexButton(props)
    return React.createElement("Frame", {
        Size = UDim2.new(0, 60, 0, 60),
        Position = UDim2.new(0, 10, 0.5, 70), -- Below Pets (0) and Rebirth (60) buttons
        BackgroundTransparency = 1
    }, {
        Button = React.createElement("ImageButton", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.fromRGB(100, 100, 100),
            BorderSizePixel = 0,
            [React.Event.Activated] = props.onClick
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0, 8)
            }),
            
            Icon = React.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0.7, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = "📚",
                TextScaled = true,
                Font = Enum.Font.Gotham
            }),
            
            Label = React.createElement("TextLabel", {
                Size = UDim2.new(1, -4, 0.3, 0),
                Position = UDim2.new(0, 2, 0.7, 0),
                BackgroundTransparency = 1,
                Text = "Index",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                Font = Enum.Font.GothamBold
            }),
            
            Hotkey = React.createElement("TextLabel", {
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(1, -22, 0, 2),
                BackgroundColor3 = Color3.fromRGB(50, 50, 50),
                BorderSizePixel = 0,
                Text = "I",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                Font = Enum.Font.GothamBold
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 4)
                })
            })
        })
    })
end

return PetIndexButton