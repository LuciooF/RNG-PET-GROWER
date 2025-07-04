-- Pet Boost Empty State Component
-- Extracted from PetBoostPanel.lua for better modularity
-- Shows when no pets are assigned for boosts

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.react)
local e = React.createElement

local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)

local PetBoostEmptyState = {}

function PetBoostEmptyState.create(props)
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local normalTextSize = ScreenUtils.getProportionalTextSize(screenSize, 18)
    
    return e("Frame", {
        Name = "EmptyState",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = 32
    }, {
        EmptyContainer = e("Frame", {
            Size = UDim2.new(0, 400, 0, 300),
            Position = UDim2.new(0.5, -200, 0.5, -150),
            BackgroundColor3 = Color3.fromRGB(250, 250, 250),
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
            ZIndex = 33
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 20)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(200, 200, 200),
                Thickness = 2,
                Transparency = 0.5
            }),
            
            EmptyIcon = e("TextLabel", {
                Size = UDim2.new(0, 120, 0, 120),
                Position = UDim2.new(0.5, -60, 0, 30),
                Text = "🐾",
                TextSize = normalTextSize,
                TextWrapped = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 34
            }),
            EmptyTitle = e("TextLabel", {
                Size = UDim2.new(1, -40, 0, 40),
                Position = UDim2.new(0, 20, 0, 160),
                Text = "No Pets Assigned",
                TextColor3 = Color3.fromRGB(80, 80, 80),
                TextSize = normalTextSize,
                TextWrapped = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 34
            }),
            EmptyText = e("TextLabel", {
                Size = UDim2.new(1, -40, 0, 60),
                Position = UDim2.new(0, 20, 0, 210),
                Text = "Assign pets from your collection to see their boosts here!\nEach assigned pet provides powerful bonuses.",
                TextColor3 = Color3.fromRGB(120, 120, 120),
                TextSize = 16,
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextWrapped = true,
                ZIndex = 34
            })
        })
    })
end

return PetBoostEmptyState