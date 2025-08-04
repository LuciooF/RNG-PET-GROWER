-- ErrorMessage - Shows error messages at the bottom of the screen
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local React = require(ReplicatedStorage.Packages.react)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)

-- Sound configuration
local ERROR_SOUND_ID = "rbxassetid://3779045779"

-- Pre-create error sound for instant playback
local errorSound = Instance.new("Sound")
errorSound.SoundId = ERROR_SOUND_ID
errorSound.Volume = 0.6 -- Moderate volume for error alerts
errorSound.Parent = SoundService

-- Play error sound instantly
local function playErrorSound()
    errorSound:Play()
end

local function ErrorMessage()
    local errorText, setErrorText = React.useState("")
    local isVisible, setIsVisible = React.useState(false)

    -- Subscribe to error message remote event
    React.useEffect(function()
        local errorMessageRemote = ReplicatedStorage:WaitForChild("ShowErrorMessage")
        
        local connection = errorMessageRemote.OnClientEvent:Connect(function(message)
            -- Play error sound when message appears
            playErrorSound()
            
            setErrorText(message)
            setIsVisible(true)
            
            -- Hide the message after 3 seconds using task.spawn
            task.spawn(function()
                task.wait(3)
                setIsVisible(false)
            end)
        end)
        
        return function()
            connection:Disconnect()
        end
    end, {})

    if not isVisible then
        return nil
    end

    return React.createElement("ScreenGui", {
        Name = "ErrorMessageGui",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, {
        ErrorText = React.createElement("TextLabel", {
            Size = ScreenUtils.udim2(0, 500, 0, 60), -- Smaller size
            Position = UDim2.new(0.5, 0, 0.75, 0), -- Middle-bottom of screen
            AnchorPoint = Vector2.new(0.5, 0.5), -- Center anchor point
            BackgroundTransparency = 1,
            Text = errorText,
            TextColor3 = Color3.fromRGB(255, 100, 100), -- Red text
            TextStrokeTransparency = 0,
            TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
            TextSize = ScreenUtils.TEXT_SIZES.LARGE(), -- Fixed text size instead of TextScaled
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 1000
        })
    })
end

return ErrorMessage