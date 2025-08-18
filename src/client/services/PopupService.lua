-- PopupService - Shows "+{amount}" popups for money, diamonds, and rebirths
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local store = require(ReplicatedStorage.store)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)

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
    -- Initializing PopupService with store subscription
    
    -- Subscribe directly to Rodux store changes
    local unsubscribe = store.changed:connect(function(newState, oldState)
        if newState.player and newState.player.Resources then
            self:CheckForResourceChanges(newState.player, oldState.player)
        end
    end)
    
    connections.dataSubscription = unsubscribe
    
    -- Initialize previous values from current store state
    local initialState = store:getState()
    if initialState.player and initialState.player.Resources then
        previousMoney = initialState.player.Resources.Money or 0
        previousDiamonds = initialState.player.Resources.Diamonds or 0
        previousRebirths = initialState.player.Resources.Rebirths or 0
        -- Initial resource values loaded
    end
end

function PopupService:CheckForResourceChanges(newPlayerData, oldPlayerData)
    if not newPlayerData.Resources then return end
    
    local currentMoney = newPlayerData.Resources.Money or 0
    local currentDiamonds = newPlayerData.Resources.Diamonds or 0
    local currentRebirths = newPlayerData.Resources.Rebirths or 0
    
    -- Use previousMoney or oldState for comparison (more reliable)
    local oldMoney = (oldPlayerData and oldPlayerData.Resources and oldPlayerData.Resources.Money) or previousMoney
    local oldDiamonds = (oldPlayerData and oldPlayerData.Resources and oldPlayerData.Resources.Diamonds) or previousDiamonds
    local oldRebirths = (oldPlayerData and oldPlayerData.Resources and oldPlayerData.Resources.Rebirths) or previousRebirths
    
    -- Check for money gain
    if currentMoney > oldMoney then
        local gain = currentMoney - oldMoney
        -- Money gained, showing popup
        self:ShowPopup("Money", gain, IconAssets.getIcon("CURRENCY", "MONEY"))
    end
    
    -- Check for diamond gain
    if currentDiamonds > oldDiamonds then
        local gain = currentDiamonds - oldDiamonds
        -- Diamonds gained, showing popup
        self:ShowPopup("Diamonds", gain, IconAssets.getIcon("CURRENCY", "DIAMONDS"))
    end
    
    -- Check for rebirth gain
    if currentRebirths > oldRebirths then
        local gain = currentRebirths - oldRebirths
        -- Rebirths gained, showing popup
        self:ShowPopup("Rebirths", gain, IconAssets.getIcon("UI", "REBIRTH"))
    end
    
    -- Update previous values for backup comparison
    previousMoney = currentMoney
    previousDiamonds = currentDiamonds
    previousRebirths = currentRebirths
end

function PopupService:GetDynamicPosition(topStatsGui, resourceType)
    if not topStatsGui then 
        return nil 
    end
    
    -- Navigate to the specific frame: TopStatsUI > Container > [Resource]Frame
    local container = topStatsGui:FindFirstChild("Container")
    if not container then
        -- Container not found in TopStatsUI
        return nil
    end
    
    local frameName = resourceType .. "Frame" -- "DiamondsFrame", "MoneyFrame", "RebirthsFrame"
    local resourceFrame = container:FindFirstChild(frameName)
    if not resourceFrame then
        -- Resource frame not found
        return nil
    end
    
    -- Get the absolute position of the resource frame
    local absolutePos = resourceFrame.AbsolutePosition
    local absoluteSize = resourceFrame.AbsoluteSize
    
    -- Position popup below the center of the resource frame
    local centerX = absolutePos.X + (absoluteSize.X / 2)
    local belowY = absolutePos.Y + absoluteSize.Y + ScreenUtils.getProportionalSize(10) -- 10px gap
    
    -- Convert back to UDim2 (scale, offset)
    local screenSize = workspace.CurrentCamera.ViewportSize
    local position = UDim2.new(0, centerX - (ScreenUtils.getProportionalSize(80)), 0, belowY) -- Center the popup (width = 160, so offset by 80)
    
    return position
end

function PopupService:ShowPopup(resourceType, amount, iconAsset)
    -- Try to find the TopStatsUI inside PetGrowerApp
    local petGrowerApp = playerGui:FindFirstChild("PetGrowerApp")
    local topStatsGui = petGrowerApp and petGrowerApp:FindFirstChild("TopStatsUI")
    
    -- Creating resource popup
    
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
    
    -- Create popup frame with visible background
    local popupFrame = Instance.new("Frame")
    popupFrame.Name = "PopupFrame"
    popupFrame.Size = UDim2.new(0, ScreenUtils.getProportionalSize(160), 0, ScreenUtils.getProportionalSize(40)) -- Slightly larger for better visibility
    popupFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Dark background
    popupFrame.BackgroundTransparency = 0.3 -- Semi-transparent
    popupFrame.BorderSizePixel = 0
    popupFrame.Parent = popupGui
    
    -- Add rounded corners
    local popupCorner = Instance.new("UICorner")
    popupCorner.CornerRadius = UDim.new(0, ScreenUtils.getProportionalSize(8))
    popupCorner.Parent = popupFrame
    
    -- Try to position dynamically based on actual UI positions
    local dynamicPosition = self:GetDynamicPosition(topStatsGui, resourceType)
    if dynamicPosition then
        popupFrame.Position = dynamicPosition
        -- Using dynamic position
    else
        -- Fallback to fixed positions (improved spacing based on TopStatsUI layout)
        -- Using fallback position
        if resourceType == "Diamonds" then
            -- Diamonds are on the far left in TopStatsUI
            popupFrame.Position = UDim2.new(0.5, -ScreenUtils.getProportionalSize(320), 0, ScreenUtils.getProportionalSize(140))
        elseif resourceType == "Money" then
            -- Money is in the center
            popupFrame.Position = UDim2.new(0.5, 0, 0, ScreenUtils.getProportionalSize(140))
        elseif resourceType == "Rebirths" then
            -- Rebirths are on the far right
            popupFrame.Position = UDim2.new(0.5, ScreenUtils.getProportionalSize(320), 0, ScreenUtils.getProportionalSize(140))
        end
    end
    
    -- Create icon
    local popupIcon = Instance.new("ImageLabel")
    popupIcon.Name = "PopupIcon"
    popupIcon.Size = UDim2.new(0, ScreenUtils.getProportionalSize(24), 0, ScreenUtils.getProportionalSize(24))
    popupIcon.Position = UDim2.new(0, ScreenUtils.getProportionalSize(8), 0.5, -ScreenUtils.getProportionalSize(12))
    popupIcon.BackgroundTransparency = 1
    popupIcon.Image = iconAsset
    popupIcon.ScaleType = Enum.ScaleType.Fit
    popupIcon.Parent = popupFrame
    
    -- Create text label
    local popupLabel = Instance.new("TextLabel")
    popupLabel.Name = "PopupLabel"
    popupLabel.Size = UDim2.new(0, ScreenUtils.getProportionalSize(120), 1, 0)
    popupLabel.Position = UDim2.new(0, ScreenUtils.getProportionalSize(36), 0, 0) -- Right next to icon with proper spacing
    popupLabel.BackgroundTransparency = 1
    popupLabel.Font = Enum.Font.FredokaOne
    popupLabel.Text = "+" .. NumberFormatter.format(amount)
    popupLabel.TextSize = ScreenUtils.getTextSize(45) -- Larger text for better readability
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
    local endPosition = UDim2.new(startPosition.X.Scale, startPosition.X.Offset, startPosition.Y.Scale, startPosition.Y.Offset - ScreenUtils.getProportionalSize(30))
    
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