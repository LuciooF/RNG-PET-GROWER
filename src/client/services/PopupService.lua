-- PopupService - Shows "+{amount}" popups for money, diamonds, and rebirths
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local DataSyncService = require(script.Parent.DataSyncService)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)

local PopupService = {}
PopupService.__index = PopupService

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local connections = {}

-- Track previous values to detect changes
local previousMoney = 0
local previousDiamonds = 0
local previousRebirths = 0

-- Store active popups to replace them
local activePopups = {
    Money = nil,
    Diamonds = nil,
    Rebirths = nil
}

function PopupService:Initialize()
    -- Subscribe to data changes to detect money/diamond/rebirth gains
    local unsubscribe = DataSyncService:Subscribe(function(newState)
        if newState.player then
            self:CheckForResourceChanges(newState.player)
        end
    end)
    
    connections.dataSubscription = unsubscribe
    
    -- Initialize previous values
    local initialData = DataSyncService:GetPlayerData()
    if initialData and initialData.Resources then
        previousMoney = initialData.Resources.Money or 0
        previousDiamonds = initialData.Resources.Diamonds or 0
        previousRebirths = initialData.Resources.Rebirths or 0
    end
end

function PopupService:CheckForResourceChanges(playerData)
    if not playerData.Resources then return end
    
    local currentMoney = playerData.Resources.Money or 0
    local currentDiamonds = playerData.Resources.Diamonds or 0
    local currentRebirths = playerData.Resources.Rebirths or 0
    
    -- Check for money gain
    if currentMoney > previousMoney then
        local gain = currentMoney - previousMoney
        self:ShowPopup("Money", gain, IconAssets.getIcon("CURRENCY", "MONEY"))
    end
    
    -- Check for diamond gain
    if currentDiamonds > previousDiamonds then
        local gain = currentDiamonds - previousDiamonds
        self:ShowPopup("Diamonds", gain, IconAssets.getIcon("CURRENCY", "DIAMONDS"))
    end
    
    -- Check for rebirth gain
    if currentRebirths > previousRebirths then
        local gain = currentRebirths - previousRebirths
        self:ShowPopup("Rebirths", gain, IconAssets.getIcon("UI", "REBIRTH"))
    end
    
    -- Update previous values
    previousMoney = currentMoney
    previousDiamonds = currentDiamonds
    previousRebirths = currentRebirths
end

function PopupService:ShowPopup(resourceType, amount, iconAsset)
    -- Try to find the TopStatsUI inside PetGrowerApp
    local petGrowerApp = playerGui:FindFirstChild("PetGrowerApp")
    local topStatsGui = petGrowerApp and petGrowerApp:FindFirstChild("TopStatsUI")
    -- No need to log if not found, just use fixed positioning
    
    -- Destroy existing popup of this type if it exists
    if activePopups[resourceType] then
        activePopups[resourceType]:Destroy()
        activePopups[resourceType] = nil
    end
    
    -- Create popup GUI
    local popupGui = Instance.new("ScreenGui")
    popupGui.Name = resourceType .. "PopupGUI"
    popupGui.ResetOnSpawn = false
    popupGui.IgnoreGuiInset = true
    popupGui.Parent = playerGui
    
    -- Store reference to active popup
    activePopups[resourceType] = popupGui
    
    -- Create popup frame
    local popupFrame = Instance.new("Frame")
    popupFrame.Name = "PopupFrame"
    popupFrame.Size = UDim2.new(0, 150, 0, 30)
    popupFrame.BackgroundTransparency = 1
    popupFrame.Parent = popupGui
    
    -- Position based on resource type (under the corresponding stat in top UI)
    -- TopStatsUI is centered at top with stats side by side
    if resourceType == "Diamonds" then
        popupFrame.Position = UDim2.new(0.5, -200, 0, 100) -- Under diamonds (left side of center)
    elseif resourceType == "Money" then
        popupFrame.Position = UDim2.new(0.5, 0, 0, 100) -- Under money (center)
    elseif resourceType == "Rebirths" then
        popupFrame.Position = UDim2.new(0.5, 200, 0, 100) -- Under rebirths (right side of center)
    end
    
    -- Create icon
    local popupIcon = Instance.new("ImageLabel")
    popupIcon.Name = "PopupIcon"
    popupIcon.Size = UDim2.new(0, 20, 0, 20)
    popupIcon.Position = UDim2.new(0, 0, 0.5, -10)
    popupIcon.BackgroundTransparency = 1
    popupIcon.Image = iconAsset
    popupIcon.ScaleType = Enum.ScaleType.Fit
    popupIcon.Parent = popupFrame
    
    -- Create text label
    local popupLabel = Instance.new("TextLabel")
    popupLabel.Name = "PopupLabel"
    popupLabel.Size = UDim2.new(0, 120, 1, 0)
    popupLabel.Position = UDim2.new(0, 25, 0, 0) -- Right next to icon
    popupLabel.BackgroundTransparency = 1
    popupLabel.Font = Enum.Font.FredokaOne
    popupLabel.Text = "+" .. NumberFormatter.format(amount)
    popupLabel.TextSize = 18
    popupLabel.TextStrokeTransparency = 0
    popupLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    popupLabel.TextXAlignment = Enum.TextXAlignment.Left
    popupLabel.TextYAlignment = Enum.TextYAlignment.Center
    popupLabel.Parent = popupFrame
    
    -- Set color based on resource type
    if resourceType == "Money" then
        popupLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
    elseif resourceType == "Diamonds" then
        popupLabel.TextColor3 = Color3.fromRGB(100, 149, 237) -- Light blue
    elseif resourceType == "Rebirths" then
        popupLabel.TextColor3 = Color3.fromRGB(255, 100, 255) -- Pink/purple
    end
    
    -- Animation: Slide up and fade out
    local startPosition = popupFrame.Position
    local endPosition = UDim2.new(startPosition.X.Scale, startPosition.X.Offset, startPosition.Y.Scale, startPosition.Y.Offset - 30)
    
    -- Start with 0 transparency, end with full transparency
    popupFrame.BackgroundTransparency = 1
    popupIcon.ImageTransparency = 0
    popupLabel.TextTransparency = 0
    
    -- Create tween info
    local tweenInfo = TweenInfo.new(
        2.0, -- Duration: 2 seconds
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out,
        0, -- Repeat count
        false, -- Reverse
        0 -- Delay
    )
    
    -- Create tweens
    local positionTween = TweenService:Create(popupFrame, tweenInfo, {
        Position = endPosition
    })
    
    local iconFadeTween = TweenService:Create(popupIcon, tweenInfo, {
        ImageTransparency = 1
    })
    
    local labelFadeTween = TweenService:Create(popupLabel, tweenInfo, {
        TextTransparency = 1,
        TextStrokeTransparency = 1
    })
    
    -- Play animations
    positionTween:Play()
    iconFadeTween:Play()
    labelFadeTween:Play()
    
    -- Clean up when animation completes
    positionTween.Completed:Connect(function()
        if activePopups[resourceType] == popupGui then
            activePopups[resourceType] = nil
        end
        popupGui:Destroy()
    end)
end

function PopupService:Cleanup()
    -- Disconnect all connections
    for name, connection in pairs(connections) do
        if connection and type(connection) == "function" then
            connection()
        elseif connection and typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end
    connections = {}
    
    -- Clean up active popups
    for resourceType, popup in pairs(activePopups) do
        if popup then
            popup:Destroy()
        end
    end
    activePopups = {}
end

-- Handle character respawn
Players.LocalPlayer.CharacterAdded:Connect(function()
    -- Re-initialize after character respawn
    PopupService:Cleanup()
    task.wait(1) -- Wait for character to fully load
    PopupService:Initialize()
end)

return PopupService