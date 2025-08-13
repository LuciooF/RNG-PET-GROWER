-- LoadingScreen - Simple loading screen component
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local React = require(ReplicatedStorage.Packages.react)

local function LoadingScreen(props)
    return React.createElement("ScreenGui", {
        Name = "LoadingScreen",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999, -- High priority to be on top
        Enabled = props.visible
    }, {
        Background = React.createElement("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
        }),
        
        Content = React.createElement("Frame", {
            Size = UDim2.new(0, 400, 0, 200),
            Position = UDim2.new(0.5, -200, 0.5, -100),
            BackgroundTransparency = 1,
        }, {
            Title = React.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0, 60),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = "Loading...",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 48,
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
            }),
            
            LoadingBar = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, 6),
                Position = UDim2.new(0, 0, 0, 80),
                BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                BorderSizePixel = 0,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 3),
                }),
                
                Progress = React.createElement("Frame", {
                    Size = UDim2.new(props.progress or 0, 0, 1, 0),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundColor3 = Color3.fromRGB(100, 150, 255),
                    BorderSizePixel = 0,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = UDim.new(0, 3),
                    }),
                }),
            }),
            
            StatusText = React.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0, 30),
                Position = UDim2.new(0, 0, 0, 110),
                BackgroundTransparency = 1,
                Text = props.status or "Initializing...",
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextSize = 18,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
            }),
        })
    })
end

return LoadingScreen