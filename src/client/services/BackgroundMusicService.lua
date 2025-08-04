-- BackgroundMusicService - Handles background music playback
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")

local BackgroundMusicService = {}
BackgroundMusicService.__index = BackgroundMusicService

local player = Players.LocalPlayer
local backgroundMusic = nil

-- Configuration
local MUSIC_ASSET_ID = "rbxassetid://1840684529"
local MUSIC_VOLUME = 0.1
local FADE_TIME = 2 -- Seconds for fade in/out

function BackgroundMusicService:Initialize()
    print("BackgroundMusicService: Initializing background music...")
    
    -- Create the background music sound
    backgroundMusic = Instance.new("Sound")
    backgroundMusic.Name = "BackgroundMusic"
    backgroundMusic.SoundId = MUSIC_ASSET_ID
    backgroundMusic.Volume = 0 -- Start at 0 for fade in
    backgroundMusic.Looped = true
    backgroundMusic.RollOffMode = Enum.RollOffMode.Inverse
    backgroundMusic.Parent = SoundService
    
    -- Wait for character to spawn before starting music
    if player.Character then
        self:StartMusic()
    else
        player.CharacterAdded:Connect(function()
            self:StartMusic()
        end)
    end
    
    -- Handle character respawn
    player.CharacterAdded:Connect(function()
        if backgroundMusic and not backgroundMusic.IsPlaying then
            self:StartMusic()
        end
    end)
    
    print("BackgroundMusicService: Background music service initialized")
end

function BackgroundMusicService:StartMusic()
    if not backgroundMusic then return end
    
    print("BackgroundMusicService: Starting background music...")
    
    -- Start playing the music
    backgroundMusic:Play()
    
    -- Fade in the music
    self:FadeIn()
end

function BackgroundMusicService:FadeIn()
    if not backgroundMusic then return end
    
    print("BackgroundMusicService: Fading in music...")
    
    -- Create fade in tween
    local TweenService = game:GetService("TweenService")
    local tweenInfo = TweenInfo.new(
        FADE_TIME, -- Duration
        Enum.EasingStyle.Sine, -- Easing style
        Enum.EasingDirection.Out, -- Easing direction
        0, -- Repeat count
        false, -- Reverse
        0 -- Delay
    )
    
    local fadeInTween = TweenService:Create(backgroundMusic, tweenInfo, {
        Volume = MUSIC_VOLUME
    })
    
    fadeInTween:Play()
end

function BackgroundMusicService:FadeOut()
    if not backgroundMusic then return end
    
    print("BackgroundMusicService: Fading out music...")
    
    -- Create fade out tween
    local TweenService = game:GetService("TweenService")
    local tweenInfo = TweenInfo.new(
        FADE_TIME, -- Duration
        Enum.EasingStyle.Sine, -- Easing style
        Enum.EasingDirection.Out, -- Easing direction
        0, -- Repeat count
        false, -- Reverse
        0 -- Delay
    )
    
    local fadeOutTween = TweenService:Create(backgroundMusic, tweenInfo, {
        Volume = 0
    })
    
    fadeOutTween:Play()
    
    -- Stop the music after fade out completes
    fadeOutTween.Completed:Connect(function()
        if backgroundMusic then
            backgroundMusic:Stop()
        end
    end)
end

function BackgroundMusicService:SetVolume(volume)
    volume = math.clamp(volume, 0, 1)
    MUSIC_VOLUME = volume
    
    if backgroundMusic and backgroundMusic.IsPlaying then
        backgroundMusic.Volume = volume
    end
    
    print("BackgroundMusicService: Volume set to", volume)
end

function BackgroundMusicService:StopMusic()
    if backgroundMusic and backgroundMusic.IsPlaying then
        self:FadeOut()
    end
end

function BackgroundMusicService:ResumeMusic()
    if backgroundMusic and not backgroundMusic.IsPlaying then
        self:StartMusic()
    end
end

function BackgroundMusicService:IsPlaying()
    return backgroundMusic and backgroundMusic.IsPlaying
end

-- Clean up when service is destroyed
function BackgroundMusicService:Cleanup()
    print("BackgroundMusicService: Cleaning up...")
    
    if backgroundMusic then
        backgroundMusic:Stop()
        backgroundMusic:Destroy()
        backgroundMusic = nil
    end
end

-- Handle player leaving (cleanup)
game.Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        BackgroundMusicService:Cleanup()
    end
end)

return BackgroundMusicService