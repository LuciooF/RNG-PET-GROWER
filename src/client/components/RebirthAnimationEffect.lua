local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages.react)

local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local assets = require(ReplicatedStorage.assets)

local e = React.createElement

local function RebirthAnimationEffect(props)
    local visible = props.visible
    local screenSize = props.screenSize
    local onComplete = props.onComplete
    
    local frameRef = React.useRef(nil)
    local iconRef = React.useRef(nil)
    
    -- Calculate responsive sizes
    local effectSize = ScreenUtils.getProportionalSize(screenSize, 200)
    local iconSize = ScreenUtils.getProportionalSize(screenSize, 120)
    
    -- Start animation when visible
    React.useEffect(function()
        if visible and frameRef.current and iconRef.current then
            local frame = frameRef.current
            local icon = iconRef.current
            
            -- Set initial state
            icon.Size = UDim2.new(0, iconSize * 0.1, 0, iconSize * 0.1) -- Start even smaller
            icon.Rotation = 0
            icon.ImageTransparency = 0
            frame.BackgroundTransparency = 1
            
            -- Animation sequence: Grow while spinning, then disappear
            local growTween = TweenService:Create(icon, TweenInfo.new(1.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, iconSize * 1.3, 0, iconSize * 1.3) -- End slightly bigger
            })
            
            local spinTween = TweenService:Create(icon, TweenInfo.new(0.6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {
                Rotation = 360
            })
            
            local shrinkTween = TweenService:Create(icon, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 0, 0, 0),
                ImageTransparency = 1
            })
            
            -- Start both grow and spin animations simultaneously
            growTween:Play()
            spinTween:Play()
            
            -- When grow finishes, wait a moment then start shrinking
            growTween.Completed:Connect(function()
                task.delay(0.8, function()
                    if icon.Parent then
                        spinTween:Cancel()
                        shrinkTween:Play()
                        
                        shrinkTween.Completed:Connect(function()
                            if onComplete then
                                onComplete()
                            end
                        end)
                    end
                end)
            end)
            
            -- Cleanup function
            return function()
                if growTween then growTween:Cancel() end
                if spinTween then spinTween:Cancel() end
                if shrinkTween then shrinkTween:Cancel() end
            end
        end
    end, {visible})
    
    if not visible then
        return nil
    end
    
    return e("Frame", {
        Name = "RebirthAnimationEffect",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 1000, -- Make sure it's on top
        ref = frameRef
    }, {
        RebirthIcon = e("ImageLabel", {
            Name = "RebirthIcon",
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = assets["vector-icon-pack-2/General/Rebirth/Rebirth Outline 256.png"] or "",
            ImageColor3 = Color3.fromRGB(255, 255, 255), -- Keep original color
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 1001,
            ref = iconRef
        })
    })
end

return RebirthAnimationEffect