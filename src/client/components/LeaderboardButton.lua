-- LeaderboardButton - Simple leaderboard button for right side
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local React = require(ReplicatedStorage.Packages.react)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)

-- Sound configuration
local HOVER_SOUND_ID = "rbxassetid://6895079853"

-- Pre-create hover sound for instant playback
local hoverSound = Instance.new("Sound")
hoverSound.SoundId = HOVER_SOUND_ID
hoverSound.Volume = 0.5
hoverSound.Parent = SoundService

-- Play hover sound instantly
local function playHoverSound()
    hoverSound:Play()
end

local function LeaderboardButton(props)
    -- Match SideBar button sizing exactly (7% of screen height)
    local screenHeight = workspace.CurrentCamera.ViewportSize.Y
    local buttonPixelSize = screenHeight * 0.07 -- Same as SideBar
    local buttonSize = UDim2.new(0, buttonPixelSize, 0, buttonPixelSize)
    local screenPadding = ScreenUtils.getProportionalSize(10)
    
    return React.createElement("ImageButton", {
        Name = "LeaderboardButton",
        Size = buttonSize, -- Same size as sidebar buttons
        Position = UDim2.new(1, -buttonPixelSize - screenPadding, 0.5, buttonPixelSize + ScreenUtils.getProportionalSize(20)), -- Below playtime rewards
        BackgroundTransparency = 1, -- No background like sidebar buttons
        Image = IconAssets.getIcon("UI", "TROPHY"),
        ImageColor3 = Color3.fromRGB(255, 215, 0), -- Gold color
        ScaleType = Enum.ScaleType.Fit,
        SizeConstraint = Enum.SizeConstraint.RelativeYY,
        ZIndex = 50,
        [React.Event.Activated] = function()
            if props.onLeaderboardClick then
                props.onLeaderboardClick()
            end
        end,
        [React.Event.MouseEnter] = function()
            playHoverSound()
        end
    })
end

return LeaderboardButton