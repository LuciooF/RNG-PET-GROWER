-- Lab Outcome Display Component
-- Shows possible merge outcomes with probabilities
-- Extracted from LabPanel.lua following CLAUDE.md modular architecture patterns

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.react)
local e = React.createElement

local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local PetConfig = require(ReplicatedStorage.Shared.config.PetConfig)

local function LabOutcomeDisplay(props)
    local outcomes = props.outcomes or {}
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    local getProportionalTextSize = ScreenUtils.getProportionalTextSize
    
    -- Responsive sizing
    local containerWidth = ScreenUtils.getProportionalSize(screenSize, 380)
    local cardWidth = ScreenUtils.getProportionalSize(screenSize, 180)
    local cardPadding = ScreenUtils.getProportionalSize(screenSize, 15)
    local imageSizeResult = ScreenUtils.getProportionalSize(screenSize, 60)
    
    return e("Frame", {
        Name = "OutcomeDisplayContainer",
        Size = UDim2.new(0, containerWidth, 1, -40),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 53,
        LayoutOrder = 3
    }, {
        Layout = e("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, cardPadding),
            SortOrder = Enum.SortOrder.LayoutOrder
        }),
        
        -- Result Pet Card
        ResultPetCard = e("Frame", {
            Name = "ResultPetCard",
            Size = UDim2.new(0, cardWidth, 1, -10),
            BackgroundColor3 = Color3.fromRGB(240, 240, 250),
            BackgroundTransparency = 0.1,
            BorderSizePixel = 0,
            ZIndex = 54,
            LayoutOrder = 1
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 12)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(150, 150, 200),
                Thickness = 2,
                Transparency = 0.3
            }),
            
            Layout = e("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 8),
                SortOrder = Enum.SortOrder.LayoutOrder
            }),
            
            Padding = e("UIPadding", {
                PaddingTop = UDim.new(0, 10),
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10)
            }),
            
            -- Title
            Title = e("TextLabel", {
                Size = UDim2.new(1, 0, 0, 18),
                Text = "Result Pet",
                TextColor3 = Color3.fromRGB(60, 80, 140),
                TextSize = getProportionalTextSize(screenSize, 14),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 55,
                LayoutOrder = 1
            }),
            
            -- Pet name
            PetName = e("TextLabel", {
                Size = UDim2.new(1, 0, 0, 16),
                Text = "Sinister Hydra",
                TextColor3 = Color3.fromRGB(60, 80, 140),
                TextSize = getProportionalTextSize(screenSize, 12),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 55,
                LayoutOrder = 2
            }),
            
            -- Pet image placeholder
            PetImage = e("TextLabel", {
                Size = UDim2.new(0, imageSizeResult, 0, imageSizeResult),
                Text = "🐉",
                TextSize = getProportionalTextSize(screenSize, 28),
                TextColor3 = Color3.fromRGB(100, 100, 100),
                BackgroundColor3 = Color3.fromRGB(220, 220, 220),
                BorderSizePixel = 0,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 55,
                LayoutOrder = 3
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 8)
                })
            }),
            
            -- Size
            SizeText = e("TextLabel", {
                Size = UDim2.new(1, 0, 0, 14),
                Text = "Medium",
                TextColor3 = Color3.fromRGB(100, 150, 255),
                TextSize = getProportionalTextSize(screenSize, 10),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 55,
                LayoutOrder = 4
            })
        }),
        
        -- Chances Card
        ChancesCard = e("Frame", {
            Name = "ChancesCard",
            Size = UDim2.new(0, cardWidth, 1, -10),
            BackgroundColor3 = Color3.fromRGB(240, 240, 250),
            BackgroundTransparency = 0.1,
            BorderSizePixel = 0,
            ZIndex = 54,
            LayoutOrder = 2,
            ClipsDescendants = true
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 12)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(150, 150, 200),
                Thickness = 2,
                Transparency = 0.3
            }),
            
            Layout = e("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Top,
                Padding = UDim.new(0, 3),
                SortOrder = Enum.SortOrder.LayoutOrder
            }),
            
            Padding = e("UIPadding", {
                PaddingTop = UDim.new(0, 8),
                PaddingBottom = UDim.new(0, 8),
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8)
            }),
            
            -- Title
            Title = e("TextLabel", {
                Size = UDim2.new(1, 0, 0, 18),
                Text = "Chances",
                TextColor3 = Color3.fromRGB(60, 80, 140),
                TextSize = getProportionalTextSize(screenSize, 14),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 55,
                LayoutOrder = 1
            }),
            
            -- Outcomes list
            Outcomes = React.createElement(React.Fragment, {}, (function()
                local outcomeElements = {}
                
                for i, outcome in ipairs(outcomes) do
                    outcomeElements["outcome_" .. i] = e("TextLabel", {
                        Size = UDim2.new(1, 0, 0, 22),
                        Text = (outcome.chance or "0%") .. " chance of " .. (outcome.rarity or "1/100"),
                        TextColor3 = outcome.color or Color3.fromRGB(60, 80, 140),
                        TextSize = getProportionalTextSize(screenSize, 10),
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextWrapped = true,
                        ZIndex = 55,
                        LayoutOrder = 1 + i
                    }, {
                        TextStroke = e("UIStroke", {
                            Color = Color3.fromRGB(0, 0, 0),
                            Thickness = 1,
                            Transparency = 0
                        })
                    })
                end
                
                return outcomeElements
            end)())
        })
    })
end

return LabOutcomeDisplay