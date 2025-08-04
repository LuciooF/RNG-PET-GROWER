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
    local errorRef = React.useRef(nil)
    local currentTween = React.useRef(nil) -- Track current animation
    local hideTimeout = React.useRef(nil) -- Track hide timeout
    local isAnimating = React.useRef(false) -- Track animation state
    local lastErrorTime = React.useRef(0) -- Track last error time for spam prevention
    local ERROR_SPAM_COOLDOWN = 1.0 -- 1 second cooldown between error messages

    -- Subscribe to error message remote event
    React.useEffect(function()
        local errorMessageRemote = ReplicatedStorage:WaitForChild("ShowErrorMessage")
        
        local connection = errorMessageRemote.OnClientEvent:Connect(function(message)
            -- Check for spam prevention
            local currentTime = tick()
            if currentTime - lastErrorTime.current < ERROR_SPAM_COOLDOWN then
                -- Too soon since last error, ignore this one
                return
            end
            
            -- Update last error time
            lastErrorTime.current = currentTime
            
            -- Play error sound when message appears
            playErrorSound()
            
            -- Cancel any existing animations and timeouts
            if currentTween.current then
                currentTween.current:Cancel()
                currentTween.current = nil
            end
            
            if hideTimeout.current then
                task.cancel(hideTimeout.current)
                hideTimeout.current = nil
            end
            
            -- Reset animation state
            isAnimating.current = false
            
            -- Update text and ensure visibility
            setErrorText(message)
            setIsVisible(true)
            
            -- Start fresh animation sequence
            task.spawn(function()
                task.wait(0.1) -- Small delay for rendering
                
                if errorRef.current and not isAnimating.current then
                    isAnimating.current = true
                    
                    -- Force position below screen
                    errorRef.current.Position = UDim2.new(0.5, 0, 1.3, 0)
                    
                    -- Tween up to visible position
                    local slideUpTween = TweenService:Create(errorRef.current, TweenInfo.new(
                        0.5, -- Duration
                        Enum.EasingStyle.Back, -- Back easing for bounce effect
                        Enum.EasingDirection.Out
                    ), {
                        Position = UDim2.new(0.5, 0, 0.9, 0) -- Final position
                    })
                    
                    currentTween.current = slideUpTween
                    slideUpTween:Play()
                    
                    -- Set up hide timeout
                    hideTimeout.current = task.spawn(function()
                        task.wait(4.5) -- Display time
                        
                        -- Only animate down if still the same message and element exists
                        if errorRef.current and errorRef.current.Parent and isAnimating.current then
                            local slideDownTween = TweenService:Create(errorRef.current, TweenInfo.new(
                                0.4, -- Exit duration
                                Enum.EasingStyle.Quad, -- Smooth exit
                                Enum.EasingDirection.In
                            ), {
                                Position = UDim2.new(0.5, 0, 1.3, 0) -- Slide below screen
                            })
                            
                            currentTween.current = slideDownTween
                            slideDownTween:Play()
                            
                            -- Clean up after animation completes
                            slideDownTween.Completed:Connect(function()
                                if isAnimating.current then -- Only hide if this animation is still current
                                    setIsVisible(false)
                                    isAnimating.current = false
                                    currentTween.current = nil
                                    hideTimeout.current = nil
                                end
                            end)
                        else
                            -- Fallback cleanup
                            setIsVisible(false)
                            isAnimating.current = false
                            currentTween.current = nil
                            hideTimeout.current = nil
                        end
                    end)
                end
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
            Size = ScreenUtils.udim2(0, ScreenUtils.getProportionalSize(3000), 0, ScreenUtils.getProportionalSize(400)), -- 4x bigger size (2x from previous 2x)
            Position = UDim2.new(0.5, 0, 1.3, 0), -- Start further below screen for animation
            AnchorPoint = Vector2.new(0.5, 0.5), -- Center anchor point
            BackgroundTransparency = 1,
            Text = errorText,
            TextColor3 = Color3.fromRGB(200, 50, 50), -- Darker red text
            TextStrokeTransparency = 0, -- No transparency on outline
            TextStrokeColor3 = Color3.fromRGB(0, 0, 0), -- Black outline
            TextSize = ScreenUtils.TEXT_SIZES.HEADER() * 2, -- 2x bigger text size
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            TextWrapped = true, -- Enable text wrapping for multiple lines
            TextScaled = false, -- Keep fixed size, allow wrapping instead
            ZIndex = 1000,
            ref = errorRef -- Add ref for animation control
        })
    })
end

return ErrorMessage