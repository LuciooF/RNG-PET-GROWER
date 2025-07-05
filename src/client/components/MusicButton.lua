-- Music Button Component
-- Small music toggle button for bottom left corner

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages.react)
local e = React.createElement

-- Assets
local assets = require(ReplicatedStorage.assets)

-- Import shared utilities
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local ColorPalette = require(ReplicatedStorage.utils.ColorPalette)

-- Sound IDs for button interactions (same as reference)
local HOVER_SOUND_ID = "rbxassetid://15675059323"
local CLICK_SOUND_ID = "rbxassetid://6324790483"

-- Pre-create sounds for better performance
local hoverSound = Instance.new("Sound")
hoverSound.SoundId = HOVER_SOUND_ID
hoverSound.Volume = 0.3
hoverSound.Parent = SoundService

local clickSound = Instance.new("Sound")
clickSound.SoundId = CLICK_SOUND_ID
clickSound.Volume = 0.4
clickSound.Parent = SoundService

-- Function to play sound effects
local function playSound(soundType)
    if soundType == "hover" and hoverSound then
        hoverSound:Play()
    elseif soundType == "click" and clickSound then
        clickSound:Play()
    end
end

-- Function to create flip animation for music button
local function createFlipAnimation(iconRef, animationTracker)
    if not iconRef.current then return end
    
    -- Cancel any existing animation for this icon
    if animationTracker.current then
        pcall(function()
            animationTracker.current:Cancel()
        end)
        pcall(function()
            animationTracker.current:Destroy()
        end)
        animationTracker.current = nil
    end
    
    -- Reset rotation to 0 to prevent accumulation
    iconRef.current.Rotation = 0
    
    -- Create flip animation
    local flipTween = TweenService:Create(iconRef.current,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Rotation = 360}
    )
    
    -- Store reference to current animation
    animationTracker.current = flipTween
    
    flipTween:Play()
    flipTween.Completed:Connect(function()
        -- Reset rotation after animation
        if iconRef.current then
            iconRef.current.Rotation = 0
        end
        -- Clear the tracker
        if animationTracker.current == flipTween then
            animationTracker.current = nil
        end
        flipTween:Destroy()
    end)
end

local function MusicButton(props)
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local playerData = props.playerData or {}
    
    -- Don't show the button until player data is loaded
    if not playerData.resources then
        return nil
    end
    
    -- Music state - get from player data, default to true only if no settings exist
    local initialMusicState = true
    if playerData.settings and playerData.settings.musicEnabled ~= nil then
        initialMusicState = playerData.settings.musicEnabled
    end
    local musicEnabled, setMusicEnabled = React.useState(initialMusicState)
    
    -- Animation refs
    local musicIconRef = React.useRef(nil)
    local musicAnimTracker = React.useRef(nil)
    
    local scale = ScreenUtils.getProportionalScale(screenSize)
    
    -- Button sizing to match side buttons
    local buttonSize = math.max(44, ScreenUtils.getProportionalSize(screenSize, 55)) -- 44pt minimum for mobile
    
    -- Sync music state when player data changes
    React.useEffect(function()
        if playerData.settings and playerData.settings.musicEnabled ~= nil then
            setMusicEnabled(playerData.settings.musicEnabled)
        end
    end, {playerData.settings})
    
    -- Apply music setting when state changes
    React.useEffect(function()
        -- For now, just control the background music through SoundService
        -- This can be expanded later with a proper BackgroundMusicManager
        if musicEnabled then
            -- Enable background music
            SoundService.RespectFilteringEnabled = false
        else
            -- Disable background music
            SoundService.RespectFilteringEnabled = true
        end
    end, {musicEnabled})
    
    -- Handle music toggle
    local function toggleMusic()
        playSound("click")
        createFlipAnimation(musicIconRef, musicAnimTracker)
        
        local newMusicState = not musicEnabled
        setMusicEnabled(newMusicState)
        
        -- Send preference to server
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local musicPreference = remotes:FindFirstChild("MusicPreference")
            if musicPreference then
                musicPreference:FireServer(newMusicState)
            end
        end
        
        -- Music state change will be handled by the useEffect above
    end
    
    return e("Frame", {
        Name = "MusicButtonContainer",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 14
    }, {
        -- Music Button (top right corner)
        MusicButton = e("TextButton", {
            Name = "MusicButton",
            Size = UDim2.new(0, buttonSize, 0, buttonSize),
            Position = UDim2.new(1, -(buttonSize + ScreenUtils.getProportionalPadding(screenSize, 5)), 0, ScreenUtils.getProportionalPadding(screenSize, 10)), -- Top right corner (minimal margin)
            Text = "",
            BackgroundColor3 = ColorPalette.WHITE,
            BorderSizePixel = 0,
            ZIndex = 15,
            [React.Event.Activated] = toggleMusic,
            [React.Event.MouseEnter] = function()
                playSound("hover")
                createFlipAnimation(musicIconRef, musicAnimTracker)
            end
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0.5, 0) -- Make it circular
            }),
            Stroke = e("UIStroke", {
                Color = ColorPalette.BLACK, -- Black outline
                Thickness = 2,
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            }),
            Gradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, musicEnabled and ColorPalette.GAME.SUCCESS or ColorPalette.GAME.DANGER),
                    ColorSequenceKeypoint.new(1, musicEnabled and ColorPalette.GAME.SUCCESS_DARK or ColorPalette.GAME.DANGER_DARK)
                },
                Rotation = 45
            }),
            
            -- Music Icon (centered in circle)
            MusicIcon = e("ImageLabel", {
                Name = "MusicIcon",
                Size = UDim2.new(0, 32, 0, 32),
                Position = UDim2.new(0.5, -16, 0.5, -16), -- Perfectly centered
                Image = musicEnabled and "rbxassetid://81492064422345" or "rbxassetid://90643255904101", -- Music on/off icons
                BackgroundTransparency = 1,
                ScaleType = Enum.ScaleType.Fit,
                ImageColor3 = ColorPalette.WHITE,
                ZIndex = 16,
                ref = musicIconRef
            })
        })
    })
end

return MusicButton