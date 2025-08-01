-- DebugButton - Side button to toggle debug panel
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.react)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local TooltipUtils = require(ReplicatedStorage.utils.TooltipUtils)

local function DebugButton(props)
    local buttonSpacing = ScreenUtils.getScaleFactor() * 20
    
    return TooltipUtils.createHoverButton({
        Size = ScreenUtils.SIZES.SIDE_BUTTON_WIDTH(),
        Position = ScreenUtils.udim2(0, 10, 0.5, -100 + buttonSpacing * 15), -- Position for Debug (5th button)
        BackgroundTransparency = 1,
        Image = IconAssets.getIcon("UI", "SETTINGS"),
        ScaleType = Enum.ScaleType.Fit,
        SizeConstraint = Enum.SizeConstraint.RelativeYY,
        [React.Event.Activated] = props.onClick
    }, "Settings")
end

return DebugButton