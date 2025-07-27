-- ErrorMessage - Shows error messages in the center of the screen
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local React = require(ReplicatedStorage.Packages.react)

local function ErrorMessage()
    local errorText, setErrorText = React.useState("")
    local isVisible, setIsVisible = React.useState(false)

    -- Subscribe to error message remote event
    React.useEffect(function()
        local errorMessageRemote = ReplicatedStorage:WaitForChild("ShowErrorMessage")
        
        local connection = errorMessageRemote.OnClientEvent:Connect(function(message)
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
            Size = UDim2.new(0, 800, 0, 100),
            Position = UDim2.new(0.5, -400, 0.5, -50),
            BackgroundTransparency = 1,
            Text = errorText,
            TextColor3 = Color3.fromRGB(255, 100, 100), -- Red text
            TextStrokeTransparency = 0,
            TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
            TextScaled = true,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 1000
        })
    })
end

return ErrorMessage