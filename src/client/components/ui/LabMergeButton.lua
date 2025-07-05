-- Lab Merge Button Component
-- Reusable merge button with diamond cost display
-- Extracted from LabPanel.lua following CLAUDE.md modular architecture patterns

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.react)
local e = React.createElement

local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)
local assets = require(ReplicatedStorage.assets)

local function LabMergeButton(props)
    local mergeInfo = props.mergeInfo or {}
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local onMerge = props.onMerge or function() end
    local selectedCount = props.selectedCount or 0
    
    local getProportionalTextSize = ScreenUtils.getProportionalTextSize
    
    -- Responsive sizing variables
    local buttonWidth = ScreenUtils.getProportionalSize(screenSize, 200)
    local buttonHeight = ScreenUtils.getProportionalSize(screenSize, 50)
    local iconSize = ScreenUtils.getProportionalSize(screenSize, 24)
    
    local isDisabled = not mergeInfo.canMerge or not mergeInfo.hasEnoughDiamonds
    local buttonColor = isDisabled and Color3.fromRGB(150, 150, 150) or Color3.fromRGB(100, 255, 100)
    local textColor = isDisabled and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(255, 255, 255)
    
    local diamondAsset = assets["vector-icon-pack-2/Currency/Gem/Gem Blue Outline 256.png"]
    
    -- Determine button text based on selection state
    local showDiamondCost = selectedCount >= 3 and mergeInfo.canMerge
    local buttonText = showDiamondCost and " - MERGE" or (selectedCount .. "/3 Selected")
    
    return e("TextButton", {
        Name = "MergeButton",
        Size = UDim2.new(0, buttonWidth, 0, buttonHeight),
        BackgroundColor3 = buttonColor,
        BorderSizePixel = 0,
        Text = "",
        ZIndex = 54,
        LayoutOrder = 3,
        [React.Event.Activated] = isDisabled and function() end or onMerge
    }, {
        Corner = e("UICorner", {
            CornerRadius = UDim.new(0, 12)
        }),
        Stroke = e("UIStroke", {
            Color = Color3.fromRGB(0, 0, 0),
            Thickness = 2,
            Transparency = 0
        }),
        
        Layout = e("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 5),
            SortOrder = Enum.SortOrder.LayoutOrder
        }),
        
        -- Diamond icon (only show when ready to merge)
        DiamondIcon = showDiamondCost and e("ImageLabel", {
            Size = UDim2.new(0, iconSize, 0, iconSize),
            BackgroundTransparency = 1,
            Image = diamondAsset,
            ImageColor3 = textColor,
            ZIndex = 55,
            LayoutOrder = 1
        }) or nil,
        
        -- Cost text (only show when ready to merge)
        CostText = showDiamondCost and e("TextLabel", {
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            Text = mergeInfo.diamondCost and NumberFormatter.format(mergeInfo.diamondCost) or "0",
            TextColor3 = textColor,
            TextSize = getProportionalTextSize(screenSize, 16),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 55,
            LayoutOrder = 2
        }, {
            TextStroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 2,
                Transparency = 0
            })
        }) or nil,
        
        -- Button text (selection count or merge text)
        ButtonText = e("TextLabel", {
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            Text = buttonText,
            TextColor3 = textColor,
            TextSize = getProportionalTextSize(screenSize, 16),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 55,
            LayoutOrder = showDiamondCost and 3 or 1
        }, {
            TextStroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 2,
                Transparency = 0
            })
        })
    })
end

return LabMergeButton