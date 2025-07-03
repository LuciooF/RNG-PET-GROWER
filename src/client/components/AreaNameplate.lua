local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages.react)
local e = React.createElement

-- Import shared utilities
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)

-- Use shared utility functions
local getProportionalScale = ScreenUtils.getProportionalScale
local getProportionalTextSize = ScreenUtils.getProportionalTextSize

local function AreaNameplate(props)
    local playerName = props.playerName or "Unassigned"
    local areaPosition = props.areaPosition or Vector3.new(0, 0, 0)
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    local titleTextSize = getProportionalTextSize(screenSize, 24)
    local nameTextSize = getProportionalTextSize(screenSize, 20)
    
    -- Animation refs
    local nameplateRef = React.useRef()
    
    -- Floating animation effect
    React.useEffect(function()
        if not nameplateRef.current then return end
        
        local floatTween = TweenService:Create(nameplateRef.current,
            TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {Position = UDim2.new(0.5, 0, 0, -5)}
        )
        
        floatTween:Play()
        
        return function()
            if floatTween then
                floatTween:Cancel()
                floatTween:Destroy()
            end
        end
    end, {})
    
    return e("BillboardGui", {
        Name = "AreaNameplate",
        Size = UDim2.new(0, 200, 0, 80),
        StudsOffset = Vector3.new(0, 15, 0), -- Float above the area
        Adornee = nil, -- Will be set by the server
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ref = nameplateRef
    }, {
        -- Background frame
        Background = e("Frame", {
            Name = "Background",
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundColor3 = Color3.fromRGB(30, 30, 30),
            BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
            ZIndex = 1
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 12)
            }),
            
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(255, 255, 255),
                Thickness = 2,
                Transparency = 0.3
            }),
            
            -- Gradient for a nice effect
            Gradient = e("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 50)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20))
                }),
                Rotation = 90
            }),
            
            -- Player name text
            PlayerNameText = e("TextLabel", {
                Name = "PlayerNameText",
                Size = UDim2.new(1, -10, 0, 30),
                Position = UDim2.new(0, 5, 0, 5),
                BackgroundTransparency = 1,
                Text = playerName,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = nameTextSize,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                Font = Enum.Font.GothamBold,
                ZIndex = 2
            }, {
                TextStroke = e("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = 1,
                    Transparency = 0.5
                })
            }),
            
            -- "Area" text
            AreaText = e("TextLabel", {
                Name = "AreaText",
                Size = UDim2.new(1, -10, 0, 25),
                Position = UDim2.new(0, 5, 0, 35),
                BackgroundTransparency = 1,
                Text = "'s Area",
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextSize = titleTextSize - 4,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                Font = Enum.Font.Gotham,
                ZIndex = 2
            }, {
                TextStroke = e("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = 1,
                    Transparency = 0.5
                })
            })
        })
    })
end

return AreaNameplate