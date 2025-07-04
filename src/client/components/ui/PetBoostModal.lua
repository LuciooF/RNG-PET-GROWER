-- Pet Boost Modal Component
-- Extracted from PetBoostPanel.lua for better modularity
-- Handles the modal panel that displays pet boost information

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.react)
local e = React.createElement

local assets = require(ReplicatedStorage.assets)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local PetBoostEmptyState = require(script.Parent.PetBoostEmptyState)

local PetBoostModal = {}

function PetBoostModal.create(props)
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local panelWidth = props.panelWidth or 900
    local panelHeight = props.panelHeight or 600
    local onClose = props.onClose or function() end
    local children = props.children or {}
    local petItems = props.petItems or {}
    
    local titleTextSize = ScreenUtils.getProportionalTextSize(screenSize, 32)
    
    return e("TextButton", {
        Name = "PetBoostModal",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ZIndex = 30,
        Text = "",
        [React.Event.Activated] = onClose
    }, {
        PetBoostContainer = e("Frame", {
            Name = "PetBoostContainer",
            Size = UDim2.new(0, panelWidth, 0, panelHeight + 50),
            Position = UDim2.new(0.5, -panelWidth / 2, 0.5, -(panelHeight + 50) / 2),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 30
        }, {
            PetBoostPanel = e("Frame", {
                Name = "PetBoostPanel",
                Size = UDim2.new(0, panelWidth, 0, panelHeight),
                Position = UDim2.new(0, 0, 0, 50),
                BackgroundColor3 = Color3.fromRGB(240, 245, 255),
                BackgroundTransparency = 0.05,
                BorderSizePixel = 0,
                ZIndex = 30
            }, {
                -- Floating Title (Pet-themed orange)
                FloatingTitle = e("Frame", {
                    Name = "FloatingTitle",
                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 280), 0, ScreenUtils.getProportionalSize(screenSize, 40)),
                    Position = UDim2.new(0, -10, 0, -25),
                    BackgroundColor3 = Color3.fromRGB(255, 150, 50),
                    BorderSizePixel = 0,
                    ZIndex = 32
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 12)
                    }),
                    Gradient = e("UIGradient", {
                        Color = ColorSequence.new{
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 170, 70)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 130, 30))
                        },
                        Rotation = 45
                    }),
                    Stroke = e("UIStroke", {
                        Color = Color3.fromRGB(255, 255, 255),
                        Thickness = 3,
                        Transparency = 0.2
                    }),
                    TitleContent = e("Frame", {
                        Size = UDim2.new(1, -10, 1, 0),
                        Position = UDim2.new(0, 5, 0, 0),
                        BackgroundTransparency = 1,
                        ZIndex = 33
                    }, {
                        Layout = e("UIListLayout", {
                            FillDirection = Enum.FillDirection.Horizontal,
                            HorizontalAlignment = Enum.HorizontalAlignment.Center,
                            VerticalAlignment = Enum.VerticalAlignment.Center,
                            Padding = UDim.new(0, 5),
                            SortOrder = Enum.SortOrder.LayoutOrder
                        }),
                        
                        PetIcon = e("TextLabel", {
                            Name = "PetIcon",
                            Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 24), 0, ScreenUtils.getProportionalSize(screenSize, 24)),
                            Text = "🐾",
                            BackgroundTransparency = 1,
                            TextScaled = true,
                            Font = Enum.Font.SourceSansBold,
                            ZIndex = 34,
                            LayoutOrder = 1
                        }),
                        
                        TitleText = e("TextLabel", {
                            Size = UDim2.new(0, 0, 1, 0),
                            AutomaticSize = Enum.AutomaticSize.X,
                            Text = "PET BOOSTS",
                            TextColor3 = Color3.fromRGB(255, 255, 255),
                            TextSize = titleTextSize,
                            TextWrapped = true,
                            BackgroundTransparency = 1,
                            Font = Enum.Font.GothamBold,
                            ZIndex = 34,
                            LayoutOrder = 2
                        }, {
                            TextStroke = e("UIStroke", {
                                Color = Color3.fromRGB(0, 0, 0),
                                Thickness = 2,
                                Transparency = 0.5
                            })
                        })
                    })
                }),
                
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 20)
                }),
                
                Stroke = e("UIStroke", {
                    Color = Color3.fromRGB(255, 150, 50),
                    Thickness = 3,
                    Transparency = 0.1
                }),
                
                Gradient = e("UIGradient", {
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(250, 245, 255)),
                        ColorSequenceKeypoint.new(0.7, Color3.fromRGB(245, 240, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(240, 235, 255))
                    },
                    Rotation = 135
                }),
                
                -- Close Button
                CloseButton = e("ImageButton", {
                    Name = "CloseButton",
                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 32), 0, ScreenUtils.getProportionalSize(screenSize, 32)),
                    Position = UDim2.new(1, -16, 0, -16),
                    Image = assets["vector-icon-pack-2/UI/X Button/X Button Outline 256.png"] or "",
                    ImageColor3 = Color3.fromRGB(255, 255, 255),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ZIndex = 34,
                    ScaleType = Enum.ScaleType.Fit,
                    [React.Event.Activated] = onClose
                }),
                
                -- Content container for children
                ContentContainer = e("Frame", {
                    Name = "ContentContainer",
                    Size = UDim2.new(1, -40, 1, -80),
                    Position = UDim2.new(0, 20, 0, 60),
                    BackgroundTransparency = 1,
                    ZIndex = 31
                }, children)
            })
        })
    })
end

return PetBoostModal