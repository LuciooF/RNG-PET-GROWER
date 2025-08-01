-- RebirthCelebrationService - Shows celebration animation when player rebirths
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local DataSyncService = require(script.Parent.DataSyncService)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)

local RebirthCelebrationService = {}
RebirthCelebrationService.__index = RebirthCelebrationService

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local connections = {}

-- Track previous rebirth count to detect when player rebirths
local previousRebirths = 0

function RebirthCelebrationService:Initialize()
    -- Subscribe to data changes to detect rebirth increases
    local unsubscribe = DataSyncService:Subscribe(function(newState)
        if newState.player then
            self:CheckForRebirthIncrease(newState.player)
        end
    end)
    
    connections.dataSubscription = unsubscribe
    
    -- Initialize previous rebirth count
    local initialData = DataSyncService:GetPlayerData()
    if initialData and initialData.Resources then
        previousRebirths = initialData.Resources.Rebirths or 0
    end
end

function RebirthCelebrationService:CheckForRebirthIncrease(playerData)
    if not playerData.Resources then return end
    
    local currentRebirths = playerData.Resources.Rebirths or 0
    
    -- Check if player has rebirthed (gained rebirths)
    if currentRebirths > previousRebirths then
        self:PlayRebirthCelebration()
    end
    
    -- Update previous rebirth count
    previousRebirths = currentRebirths
end

function RebirthCelebrationService:PlayRebirthCelebration()
    -- Create celebration GUI
    local celebrationGui = Instance.new("ScreenGui")
    celebrationGui.Name = "RebirthCelebrationGUI"
    celebrationGui.ResetOnSpawn = false
    celebrationGui.IgnoreGuiInset = true
    celebrationGui.Parent = playerGui
    
    -- Create rebirth icon for celebration (keep original animation)
    local rebirthIcon = Instance.new("ImageLabel")
    rebirthIcon.Name = "RebirthCelebrationIcon"
    rebirthIcon.Size = UDim2.new(0, 100, 0, 100)
    rebirthIcon.Position = UDim2.new(0.5, -50, 0.5, -50) -- Center of screen
    rebirthIcon.BackgroundTransparency = 1
    rebirthIcon.Image = IconAssets.getIcon("UI", "REBIRTH")
    rebirthIcon.ScaleType = Enum.ScaleType.Fit
    rebirthIcon.ImageTransparency = 0
    rebirthIcon.Rotation = 0
    rebirthIcon.Parent = celebrationGui
    
    -- Add congratulations text above the existing icon
    local congratsText = Instance.new("TextLabel")
    congratsText.Name = "CongratsText"
    congratsText.Size = UDim2.new(0, 400, 0, 80)
    congratsText.Position = UDim2.new(0.5, -200, 0.5, -120) -- Above the icon
    congratsText.BackgroundTransparency = 1
    congratsText.Text = "Congrats!\n+1 Rebirth!"
    congratsText.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
    congratsText.TextSize = 28
    congratsText.TextStrokeTransparency = 0
    congratsText.TextStrokeColor3 = Color3.fromRGB(138, 43, 226) -- Purple outline
    congratsText.Font = Enum.Font.GothamBold
    congratsText.TextXAlignment = Enum.TextXAlignment.Center
    congratsText.TextYAlignment = Enum.TextYAlignment.Center
    congratsText.TextTransparency = 1 -- Start invisible
    congratsText.Parent = celebrationGui
    
    -- Keep original animation duration
    local animationDuration = 2.0
    
    -- Create tween infos (simple version like original)
    local spinTweenInfo = TweenInfo.new(
        animationDuration * 0.8, -- Spin for most of the animation
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.InOut,
        0, -- No repeat
        false, -- No reverse
        0 -- No delay
    )
    
    local scaleUpTweenInfo = TweenInfo.new(
        animationDuration * 0.3, -- Scale up quickly
        Enum.EasingStyle.Back,
        Enum.EasingDirection.Out,
        0, -- No repeat
        false, -- No reverse
        0 -- No delay
    )
    
    local scaleDownTweenInfo = TweenInfo.new(
        animationDuration * 0.4, -- Scale down
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.In,
        0, -- No repeat
        false, -- No reverse
        animationDuration * 0.3 -- Start after scale up
    )
    
    local fadeOutTweenInfo = TweenInfo.new(
        animationDuration * 0.3, -- Fade out
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.In,
        0, -- No repeat
        false, -- No reverse
        animationDuration * 0.7 -- Start near the end
    )
    
    -- Text animation
    local textFadeInTweenInfo = TweenInfo.new(
        0.5, -- Quick fade in
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out,
        0, -- No repeat
        false, -- No reverse
        0.2 -- Small delay
    )
    
    -- Create tweens (keep original simple animation)
    local spinTween = TweenService:Create(rebirthIcon, spinTweenInfo, {
        Rotation = 720 -- Two full rotations like original
    })
    
    local scaleUpTween = TweenService:Create(rebirthIcon, scaleUpTweenInfo, {
        Size = UDim2.new(0, 140, 0, 140) -- Scale up
    })
    
    local scaleDownTween = TweenService:Create(rebirthIcon, scaleDownTweenInfo, {
        Size = UDim2.new(0, 110, 0, 110) -- Scale down
    })
    
    local fadeOutTween = TweenService:Create(rebirthIcon, fadeOutTweenInfo, {
        ImageTransparency = 1 -- Fade to invisible
    })
    
    -- Text animation
    local textFadeInTween = TweenService:Create(congratsText, textFadeInTweenInfo, {
        TextTransparency = 0 -- Fade text in
    })
    
    local textFadeOutTween = TweenService:Create(congratsText, fadeOutTweenInfo, {
        TextTransparency = 1 -- Fade text out with icon
    })
    
    -- Play animations in sequence (original simple version)
    spinTween:Play()
    scaleUpTween:Play()
    
    -- Chain the scale down after scale up completes
    scaleUpTween.Completed:Connect(function()
        scaleDownTween:Play()
    end)
    
    -- Add text animation
    textFadeInTween:Play()
    
    -- Use task.spawn to avoid yielding in Redux callback
    task.spawn(function()
        -- Wait before starting fade out
        task.wait(animationDuration * 0.7)
        fadeOutTween:Play()
        textFadeOutTween:Play()
        
        -- Clean up when fade out completes
        fadeOutTween.Completed:Connect(function()
            celebrationGui:Destroy()
        end)
        
        -- Also clean up after total duration as failsafe
        task.wait(animationDuration + 1)
        if celebrationGui.Parent then
            celebrationGui:Destroy()
        end
    end)
end

function RebirthCelebrationService:Cleanup()
    -- Disconnect all connections
    for name, connection in pairs(connections) do
        if connection and type(connection) == "function" then
            connection()
        elseif connection and typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end
    connections = {}
end

-- Handle character respawn
Players.LocalPlayer.CharacterAdded:Connect(function()
    -- Re-initialize after character respawn
    RebirthCelebrationService:Cleanup()
    task.wait(1) -- Wait for character to fully load
    RebirthCelebrationService:Initialize()
end)

return RebirthCelebrationService