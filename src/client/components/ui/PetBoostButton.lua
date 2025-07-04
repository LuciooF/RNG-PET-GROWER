-- Pet Boost Button Component
-- Extracted from PetBoostPanel.lua for better modularity
-- Handles the floating action button for pet boosts

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.react)
local e = React.createElement

local assets = require(ReplicatedStorage.assets)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local AnimationHelpers = require(ReplicatedStorage.utils.AnimationHelpers)
local PetBoostController = require(script.Parent.Parent.Parent.services.controllers.PetBoostController)

local PetBoostButton = {}

function PetBoostButton.create(props)
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local totalBoosts = props.totalBoosts or 0
    local totalMoneyMultiplier = props.totalMoneyMultiplier or 1.0
    local onToggle = props.onToggle or function() end
    local onHover = props.onHover or function() end
    local buttonRef = props.buttonRef
    
    local buttonSize = ScreenUtils.getProportionalSize(screenSize, 55)
    local padding = ScreenUtils.getProportionalPadding(screenSize, 20)
    
    return e("TextButton", {
        Name = "PetBoostButton",
        Size = UDim2.new(0, buttonSize, 0, buttonSize),
        Position = UDim2.new(1, -(buttonSize + padding), 1, -(buttonSize + padding)),
        Text = "",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 15,
        [React.Event.Activated] = onToggle,
        [React.Event.MouseEnter] = onHover
    }, {
        -- Pet Boost Icon (centered in circle)
        PetBoostIcon = e("ImageLabel", {
            Name = "PetBoostIcon",
            Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 32), 0, ScreenUtils.getProportionalSize(screenSize, 32)),
            Position = UDim2.new(0.5, ScreenUtils.getProportionalSize(screenSize, -16), 0.5, ScreenUtils.getProportionalSize(screenSize, -16)),
            Image = assets["vector-icon-pack-2/Player/Boost/Boost Yellow Outline 256.png"] or "",
            BackgroundTransparency = 1,
            ScaleType = Enum.ScaleType.Fit,
            ImageColor3 = Color3.fromRGB(255, 150, 50), -- Orange theme for pets
            ZIndex = 16,
            ref = buttonRef
        }),
        
        -- Pet Count Badge (top left)
        CountBadge = e("Frame", {
            Name = "CountBadge",
            Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 24), 0, ScreenUtils.getProportionalSize(screenSize, 16)),
            Position = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, -6), 0, ScreenUtils.getProportionalSize(screenSize, -4)),
            BackgroundColor3 = Color3.fromRGB(255, 80, 80),
            BorderSizePixel = 0,
            ZIndex = 17
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 8)
            }),
            CountText = e("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                Text = tostring(totalBoosts),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = ScreenUtils.getProportionalTextSize(screenSize, 12),
                TextWrapped = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                ZIndex = 18
            }, {
                TextStroke = e("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = 2,
                    Transparency = 0.5
                })
            })
        }),
        
        -- Effect Badge (bottom right)
        EffectBadge = e("Frame", {
            Name = "EffectBadge",
            Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 65), 0, ScreenUtils.getProportionalSize(screenSize, 18)),
            Position = UDim2.new(1, ScreenUtils.getProportionalSize(screenSize, -60), 1, ScreenUtils.getProportionalSize(screenSize, -10)),
            BackgroundColor3 = Color3.fromRGB(80, 255, 80),
            BorderSizePixel = 0,
            ZIndex = 17
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 9)
            }),
            EffectText = e("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                Text = PetBoostController.formatBoostPercentage(totalMoneyMultiplier),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = ScreenUtils.getProportionalTextSize(screenSize, 11),
                TextWrapped = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                ZIndex = 18
            }, {
                TextStroke = e("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = 2,
                    Transparency = 0.5
                })
            })
        })
    })
end

return PetBoostButton