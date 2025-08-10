-- BoostIconService - Bottom left boost icon with click to open boost details
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local DataSyncService = require(script.Parent.DataSyncService)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)

local BoostIconService = {}
BoostIconService.__index = BoostIconService

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local connections = {}

-- Callback functions
local onBoostIconClick = nil

-- Store active spin tween to prevent overlapping animations
local activeSpinTween = nil

function BoostIconService:Initialize()
    print("BoostIconService: Starting initialization...")
    
    -- Create the boost icon GUI
    local success, error = pcall(function()
        self:CreateBoostIcon()
    end)
    
    if not success then
        warn("BoostIconService: Failed to create boost icon:", error)
        return
    end
    
    print("BoostIconService: Boost icon created successfully")
    
    -- Subscribe to data changes to update boost display
    local unsubscribe = DataSyncService:Subscribe(function(newState)
        if newState.player then
            self:UpdateBoostDisplay()
        end
    end)
    
    connections.dataSubscription = unsubscribe
    
    -- Update boost display initially
    self:UpdateBoostDisplay()
    
    print("BoostIconService: Initialization complete")
end

function BoostIconService:CreateBoostIcon()
    print("BoostIconService: Creating boost icon...")
    
    print("BoostIconService: PlayerGui exists:", playerGui ~= nil)
    print("BoostIconService: PlayerGui parent:", playerGui.Parent)
    print("BoostIconService: PlayerGui children count:", #playerGui:GetChildren())
    
    -- List all children of PlayerGui for debugging
    for i, child in pairs(playerGui:GetChildren()) do
        print("BoostIconService: PlayerGui child", i, ":", child.Name, "- Enabled:", child.Enabled)
    end
    
    -- Try to find an existing ScreenGui first (like TopStatsUI)
    local screenGui = playerGui:FindFirstChild("TopStatsUI")
    
    -- If no existing GUI found, create our own
    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "BoostIconGui"
        screenGui.ResetOnSpawn = false
        screenGui.IgnoreGuiInset = true
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- Use modern ZIndex system
        screenGui.Parent = playerGui
        print("BoostIconService: Created new ScreenGui")
    else
        print("BoostIconService: Using existing TopStatsUI ScreenGui")
    end
    
    print("BoostIconService: ScreenGui found/created and ready")
    print("BoostIconService: ScreenGui.Name:", screenGui.Name)
    print("BoostIconService: ScreenGui.Parent:", screenGui.Parent)
    print("BoostIconService: ScreenGui.Enabled:", screenGui.Enabled)
    print("BoostIconService: ScreenGui.DisplayOrder:", screenGui.DisplayOrder)
    
    -- SIMPLE TEST: Create a bright colored Frame first to test positioning
    local testFrame = Instance.new("Frame")
    testFrame.Name = "BoostTestFrame"
    testFrame.Size = UDim2.new(0, 100, 0, 100) -- Large 100x100 frame
    testFrame.Position = UDim2.new(0, 50, 1, -150) -- 50px from left, 150px from bottom
    testFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 255) -- Bright magenta
    testFrame.BorderSizePixel = 5
    testFrame.BorderColor3 = Color3.fromRGB(0, 255, 255) -- Cyan border
    testFrame.ZIndex = 200 -- Very high ZIndex
    testFrame.Parent = screenGui
    
    print("BoostIconService: Test frame created at position:", testFrame.Position)
    
    -- Get GUI inset for proper positioning
    local guiInset = GuiService:GetGuiInset()
    local screenSize = workspace.CurrentCamera.ViewportSize
    local centerY = screenSize.Y / 2
    
    -- Create boost icon button (exact same size and positioning as sidebar icons)
    local buttonSize = ScreenUtils.SIZES.SIDE_BUTTON_WIDTH()
    local boostButton = Instance.new("ImageButton")
    boostButton.Name = "BoostButton"
    boostButton.Size = buttonSize -- Exact same size as sidebar icons
    boostButton.Position = UDim2.new(0, 10, 1, -120) -- Fixed positioning: 10px from left, 120px from bottom
    boostButton.BackgroundTransparency = 0.5 -- Semi-transparent background for debugging
    boostButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Red background for debugging
    
    local boostIconAsset = IconAssets.getIcon("UI", "BOOST")
    print("BoostIconService: Boost icon asset ID:", boostIconAsset)
    boostButton.Image = boostIconAsset
    
    boostButton.ScaleType = Enum.ScaleType.Fit
    boostButton.SizeConstraint = Enum.SizeConstraint.RelativeYY -- Same constraint as sidebar icons
    boostButton.ZIndex = 100 -- High ZIndex to ensure visibility
    boostButton.Parent = screenGui
    
    print("BoostIconService: Boost button created with size:", buttonSize, "at position:", boostButton.Position)
    
    -- Create boost text label (positioned below icon)
    local boostLabel = Instance.new("TextLabel")
    boostLabel.Name = "BoostLabel"
    boostLabel.Size = UDim2.new(0, 80, 0, 20) -- Fixed size for debugging
    boostLabel.Position = UDim2.new(0, -5, 1, -35) -- Fixed positioning: slightly left of button, 35px from bottom
    boostLabel.BackgroundTransparency = 0.5 -- Semi-transparent background for debugging
    boostLabel.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Green background for debugging
    boostLabel.Font = Enum.Font.FredokaOne
    boostLabel.Text = "1.00x"
    boostLabel.TextColor3 = Color3.fromRGB(255, 255, 100) -- Yellow for boost
    boostLabel.TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() -- Responsive text size
    boostLabel.TextStrokeTransparency = 0
    boostLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    boostLabel.TextXAlignment = Enum.TextXAlignment.Center
    boostLabel.TextYAlignment = Enum.TextYAlignment.Center
    boostLabel.ZIndex = 101 -- Higher ZIndex than button
    boostLabel.Parent = screenGui
    
    print("BoostIconService: Boost label created at position:", boostLabel.Position)
    
    -- Store references
    self.screenGui = screenGui
    self.boostButton = boostButton
    self.boostLabel = boostLabel
    
    -- Set up click handling
    connections.boostButtonClick = boostButton.MouseButton1Click:Connect(function()
        if onBoostIconClick then
            onBoostIconClick()
        end
    end)
    
    -- Set up hover animation (360-degree spin on hover)
    connections.boostButtonHover = boostButton.MouseEnter:Connect(function()
        -- Cancel any existing spin animation
        if activeSpinTween then
            activeSpinTween:Cancel()
            activeSpinTween = nil
        end
        
        -- Reset rotation to 0 to prevent accumulation
        boostButton.Rotation = 0
        
        -- Create tween info for a quick 360-degree spin
        local tweenInfo = TweenInfo.new(
            0.5, -- Duration: 0.5 seconds
            Enum.EasingStyle.Back,
            Enum.EasingDirection.Out,
            0, -- Repeat count
            false, -- Reverse
            0 -- Delay
        )
        
        -- Create the rotation tween (360 degrees = full rotation)
        local spinTween = TweenService:Create(boostButton, tweenInfo, {
            Rotation = 360 -- Always go to exactly 360 degrees
        })
        
        -- Store the tween reference
        activeSpinTween = spinTween
        
        -- Clean up reference when animation completes
        spinTween.Completed:Connect(function()
            -- Reset to 0 degrees after completing 360
            boostButton.Rotation = 0
            activeSpinTween = nil
        end)
        
        -- Play the animation
        spinTween:Play()
    end)
end

function BoostIconService:UpdateBoostDisplay()
    if not self.boostLabel then return end
    
    local playerData = DataSyncService:GetPlayerData()
    if not playerData then
        self.boostLabel.Text = "1.00x"
        return
    end
    
    local equippedPets = playerData.EquippedPets or {}
    local ownedGamepasses = playerData.OwnedGamepasses or {}
    
    -- Calculate pet boost multiplier
    local petBoostMultiplier = 1
    for _, pet in pairs(equippedPets) do
        if pet.FinalBoost then
            petBoostMultiplier = petBoostMultiplier + (pet.FinalBoost - 1) -- Add boost amounts
        end
    end
    
    -- Calculate gamepass multiplier
    local gamepassMultiplier = 1
    local gamepasses = {}
    
    -- Convert OwnedGamepasses array to lookup table
    for _, gamepassName in pairs(ownedGamepasses) do
        gamepasses[gamepassName] = true
    end
    
    -- Stack gamepass multipliers
    if gamepasses.TwoXMoney then
        gamepassMultiplier = gamepassMultiplier * 2
    end
    
    if gamepasses.VIP then
        gamepassMultiplier = gamepassMultiplier * 2
    end
    
    -- Calculate total boost (additive)
    local totalMultiplier = petBoostMultiplier + gamepassMultiplier - 1 -- Subtract 1 to avoid double-counting base
    
    -- Update display
    self.boostLabel.Text = string.format("%sx", NumberFormatter.formatBoost(totalMultiplier))
end

-- Set callback for when boost icon is clicked
function BoostIconService:SetClickCallback(callback)
    onBoostIconClick = callback
end

-- Clean up connections
function BoostIconService:Cleanup()
    for name, connection in pairs(connections) do
        if connection and type(connection) == "function" then
            connection()
        elseif connection and typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end
    connections = {}
    
    if self.screenGui then
        self.screenGui:Destroy()
    end
end

-- Handle character respawn - DISABLED for debugging
--[[
Players.LocalPlayer.CharacterAdded:Connect(function()
    -- Re-initialize after character respawn
    BoostIconService:Cleanup()
    task.wait(1) -- Wait for character to fully load
    BoostIconService:Initialize()
end)
--]]

return BoostIconService