-- MusicToggleService - Music toggle button using TopBarPlus
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local MusicToggleService = {}
MusicToggleService.__index = MusicToggleService

local player = Players.LocalPlayer
local isMusicEnabled = true -- Default to music on
local musicIcon = nil

-- Music icons
local MUSIC_ON_ICON = "rbxassetid://125913600400373"
local MUSIC_OFF_ICON = "rbxassetid://84129807205936"

-- Try to load TopBarPlus, fallback to simple GUI if not available
local Icon = nil
pcall(function()
    Icon = require(ReplicatedStorage.Packages.topbarplus)
end)

-- Store/State management
local store = require(ReplicatedStorage.store)
local DataSyncService = require(script.Parent.DataSyncService)

function MusicToggleService:Initialize()
    -- Import the BackgroundMusicService
    local BackgroundMusicService = require(script.Parent.BackgroundMusicService)
    
    -- Load music setting from player data
    self:LoadMusicSetting()
    
    -- Apply initial music state
    if not isMusicEnabled then
        BackgroundMusicService:StopMusic()
    end
    
    if Icon then
        -- Use TopBarPlus
        self:CreateTopBarPlusButton(BackgroundMusicService)
    else
        -- Fallback to simple GUI
        warn("MusicToggleService: TopBarPlus not available, using fallback GUI")
        self:CreateFallbackButton(BackgroundMusicService)
    end
end

function MusicToggleService:LoadMusicSetting()
    -- Load from player data store
    local state = store:getState()
    if state.player and state.player.Settings and state.player.Settings.MusicEnabled ~= nil then
        isMusicEnabled = state.player.Settings.MusicEnabled
    else
        -- Default to music on if no setting found
        isMusicEnabled = true
    end
end

function MusicToggleService:SaveMusicSetting()
    -- Save music setting via DataSyncService (syncs to server)
    DataSyncService:UpdatePlayerSettings({
        MusicEnabled = isMusicEnabled
    })
end

function MusicToggleService:CreateTopBarPlusButton(BackgroundMusicService)
    -- Create music toggle icon using TopBarPlus
    musicIcon = Icon.new()
        :setImage(isMusicEnabled and MUSIC_ON_ICON or MUSIC_OFF_ICON)
        :setCaption(isMusicEnabled and "Music is ON - Click to turn OFF" or "Music is OFF - Click to turn ON")
        :align("Right") -- Position on the right side of the screen
        :oneClick(true) -- Make it behave like a button
        :bindEvent("selected", function()
            self:ToggleMusic(BackgroundMusicService)
            self:UpdateTopBarIcon()
        end)
end

function MusicToggleService:CreateFallbackButton(BackgroundMusicService)
    -- Create a simple GUI button as fallback
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MusicToggleGUI"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = playerGui
    
    -- Create button frame
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "MusicToggleButton"
    toggleButton.Size = UDim2.new(0, 40, 0, 40) -- Square button for icon
    toggleButton.Position = UDim2.new(0, 10, 0, 50) -- Top left, below other UI
    toggleButton.BackgroundColor3 = isMusicEnabled and Color3.fromRGB(70, 130, 220) or Color3.fromRGB(180, 60, 60)
    toggleButton.Text = ""
    toggleButton.ZIndex = 100
    toggleButton.Parent = screenGui
    
    -- Add music icon
    local musicIconImage = Instance.new("ImageLabel")
    musicIconImage.Name = "MusicIcon"
    musicIconImage.Size = UDim2.new(0.8, 0, 0.8, 0)
    musicIconImage.Position = UDim2.new(0.1, 0, 0.1, 0)
    musicIconImage.BackgroundTransparency = 1
    musicIconImage.Image = isMusicEnabled and MUSIC_ON_ICON or MUSIC_OFF_ICON
    musicIconImage.ScaleType = Enum.ScaleType.Fit
    musicIconImage.Parent = toggleButton
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = toggleButton
    
    -- Add click handler
    toggleButton.Activated:Connect(function()
        self:ToggleMusic(BackgroundMusicService)
        self:UpdateButtonAppearance(toggleButton)
    end)
    
    -- Store reference for updates
    self.toggleButton = toggleButton
end

function MusicToggleService:ToggleMusic(BackgroundMusicService)
    isMusicEnabled = not isMusicEnabled
    
    if isMusicEnabled then
        -- Turn music ON
        BackgroundMusicService:ResumeMusic()
    else
        -- Turn music OFF
        BackgroundMusicService:StopMusic()
    end
    
    -- Save the setting
    self:SaveMusicSetting()
end

function MusicToggleService:UpdateTopBarIcon()
    if not musicIcon then return end
    
    musicIcon:setImage(isMusicEnabled and MUSIC_ON_ICON or MUSIC_OFF_ICON)
        :setCaption(isMusicEnabled and "Music is ON - Click to turn OFF" or "Music is OFF - Click to turn ON")
end

function MusicToggleService:UpdateButtonAppearance(button)
    -- Update background color
    button.BackgroundColor3 = isMusicEnabled and Color3.fromRGB(70, 130, 220) or Color3.fromRGB(180, 60, 60)
    
    -- Update icon image
    local musicIconImage = button:FindFirstChild("MusicIcon")
    if musicIconImage then
        musicIconImage.Image = isMusicEnabled and MUSIC_ON_ICON or MUSIC_OFF_ICON
    end
end

function MusicToggleService:IsMusicEnabled()
    return isMusicEnabled
end

function MusicToggleService:Cleanup()
    -- Clean up TopBarPlus icon
    if musicIcon then
        musicIcon:destroy()
        musicIcon = nil
    end
    
    -- Clean up fallback GUI elements
    if self.toggleButton and self.toggleButton.Parent then
        self.toggleButton.Parent:Destroy()
    end
end

-- Handle player leaving
Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        MusicToggleService:Cleanup()
    end
end)

return MusicToggleService