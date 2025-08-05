-- TwoXDiamondsButtonService - Handles physical 2x Diamonds button interaction
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local DataSyncService = require(script.Parent.DataSyncService)
local PlayerAreaFinder = require(script.Parent.Parent.utils.PlayerAreaFinder)

local TwoXDiamondsButtonService = {}
TwoXDiamondsButtonService.__index = TwoXDiamondsButtonService

local player = Players.LocalPlayer
local proximityConnection = nil
local twoXDiamondsButtonPart = nil
local isInitialized = false -- Prevent double initialization

-- Configuration
local GAMEPASS_ID = 1351480418
local INTERACTION_DISTANCE = 10 -- Distance in studs to trigger interaction
local PURCHASE_COOLDOWN = 3 -- Seconds between purchase attempts

-- Cooldown tracking
local lastPurchaseAttempt = 0

-- State tracking to prevent unnecessary updates
local lastKnownOwnership = nil

function TwoXDiamondsButtonService:Initialize()
    if isInitialized then
        warn("TwoXDiamondsButtonService: Already initialized, skipping")
        return
    end
    isInitialized = true
    
    
    -- Find the 2x Diamonds button in the player's area
    self:FindTwoXDiamondsButton()
    
    -- Set up proximity detection
    if twoXDiamondsButtonPart then
        self:SetupProximityDetection()
    end
    
    -- Set up data subscription for visibility updates only if button found
    if twoXDiamondsButtonPart then
        self:SetupDataSubscription()
    end
    
    -- Hide gamepass GUIs in all OTHER player areas (not own area)
    self:HideGamepassGUIsInOtherAreas()
end

function TwoXDiamondsButtonService:FindTwoXDiamondsButton()
    -- Wait for character to spawn
    if not player.Character then
        player.CharacterAdded:Wait()
    end
    
    -- Use shared utility to find player's area
    local playerArea = PlayerAreaFinder:WaitForPlayerArea(5)
    if not playerArea then
        warn("TwoXDiamondsButtonService: Player area not found")
        return
    end
    
    -- Find the Buttons folder
    local buttonsFolder = playerArea:FindFirstChild("Buttons")
    if not buttonsFolder then
        warn("TwoXDiamondsButtonService: Buttons folder not found")
        return
    end
    
    -- Find the 2xDiamondsButton
    twoXDiamondsButtonPart = buttonsFolder:FindFirstChild("2xDiamondsButton")
    if twoXDiamondsButtonPart then
        self:UpdateGamepassGUI()
    else
        warn("TwoXDiamondsButtonService: 2xDiamondsButton not found")
    end
end

function TwoXDiamondsButtonService:UpdateGamepassGUI()
    -- GUI already exists from AreaTemplate, just update ownership status
    local existingBillboard = twoXDiamondsButtonPart:FindFirstChild("GamepassBillboard", true)
    if not existingBillboard then
        warn("TwoXDiamondsButtonService: GamepassBillboard not found - should exist from template")
        return
    end
    
    -- Check ownership and update visibility
    self:CheckOwnershipAndUpdateGUI(existingBillboard)
end

function TwoXDiamondsButtonService:CheckOwnershipAndUpdateGUI(billboard)
    -- Get player data to check ownership
    local playerData = DataSyncService:GetPlayerData()
    
    local ownsGamepass = false
    if playerData and playerData.OwnedGamepasses then
        for _, gamepassName in pairs(playerData.OwnedGamepasses) do
            if gamepassName == "TwoXDiamonds" then
                ownsGamepass = true
                break
            end
        end
    end
    
    -- Update billboard GUI with icon and price (async to avoid yielding in Redux)
    task.spawn(function()
        self:UpdateBillboardInfo(billboard)
    end)
    
    -- Show/hide OWNED surface GUI based on ownership
    if ownsGamepass then
        self:ShowOwnedSurfaceGUI()
    else
        self:HideOwnedSurfaceGUI()
    end
    
end

-- Update billboard GUI with gamepass icon, name, and robux price
function TwoXDiamondsButtonService:UpdateBillboardInfo(billboard)
    if not billboard then return end
    
    -- Clean existing elements and create new layout
    billboard:ClearAllChildren()
    
    -- Create container frame for vertical layout
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = billboard
    
    -- Get gamepass info from MarketplaceService
    local GamepassConfig = require(ReplicatedStorage.config.GamepassConfig)
    local gamepassId = GamepassConfig.GAMEPASSES.TwoXDiamonds.id
    local gamepassName = "2X Diamonds"
    local price = GamepassConfig.GAMEPASSES.TwoXDiamonds.price
    local iconId = nil
    
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(gamepassId, Enum.InfoType.GamePass)
    end)
    
    if success and info then
        gamepassName = info.Name
        price = info.PriceInRobux
        iconId = info.IconImageAssetId
    end
    
    -- Create gamepass icon (top)
    local gamepassIcon = Instance.new("ImageLabel")
    gamepassIcon.Name = "GamepassIcon"
    gamepassIcon.Size = UDim2.new(0, 40, 0, 40)
    gamepassIcon.Position = UDim2.new(0.5, -20, 0, 5)
    gamepassIcon.BackgroundTransparency = 1
    gamepassIcon.Image = iconId and ("rbxassetid://" .. tostring(iconId)) or ""
    gamepassIcon.ScaleType = Enum.ScaleType.Fit
    gamepassIcon.Parent = container
    
    -- Create gamepass name label (middle)
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.Position = UDim2.new(0, 0, 0, 50)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.FredokaOne
    nameLabel.Text = gamepassName
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 14
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.TextYAlignment = Enum.TextYAlignment.Center
    nameLabel.Parent = container
    
    -- Create price container with robux icon (bottom)
    local priceContainer = Instance.new("Frame")
    priceContainer.Name = "PriceContainer"
    priceContainer.Size = UDim2.new(1, 0, 0, 20)
    priceContainer.Position = UDim2.new(0, 0, 0, 75)
    priceContainer.BackgroundTransparency = 1
    priceContainer.Parent = container
    
    -- Create robux icon
    local IconAssets = require(ReplicatedStorage.utils.IconAssets)
    local robuxIcon = Instance.new("ImageLabel")
    robuxIcon.Name = "RobuxIcon"
    robuxIcon.Size = UDim2.new(0, 16, 0, 16)
    robuxIcon.Position = UDim2.new(0.5, -25, 0.5, -8)
    robuxIcon.BackgroundTransparency = 1
    robuxIcon.Image = IconAssets.getIcon("CURRENCY", "ROBUX")
    robuxIcon.ScaleType = Enum.ScaleType.Fit
    robuxIcon.Parent = priceContainer
    
    -- Create price label
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Name = "PriceLabel"
    priceLabel.Size = UDim2.new(0, 50, 1, 0)
    priceLabel.Position = UDim2.new(0.5, -5, 0, 0)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Font = Enum.Font.FredokaOne
    priceLabel.Text = tostring(price)
    priceLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    priceLabel.TextSize = 14
    priceLabel.TextStrokeTransparency = 0
    priceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    priceLabel.TextXAlignment = Enum.TextXAlignment.Left
    priceLabel.TextYAlignment = Enum.TextYAlignment.Center
    priceLabel.Parent = priceContainer
    
    -- Adjust billboard size to fit new layout
    billboard.Size = UDim2.new(0, 120, 0, 100)
end

-- Add "Owned" surface GUI to the button part
function TwoXDiamondsButtonService:AddOwnedSurfaceGUI()
    if not twoXDiamondsButtonPart then 
        return 
    end
    
    -- Check if already exists
    if twoXDiamondsButtonPart:FindFirstChild("OwnedSurfaceGui", true) then
        return
    end
    
    -- Find a BasePart to attach to
    local targetPart = twoXDiamondsButtonPart
    if twoXDiamondsButtonPart:IsA("Model") then
        for _, part in pairs(twoXDiamondsButtonPart:GetDescendants()) do
            if part:IsA("BasePart") then
                targetPart = part
                break
            end
        end
    end
    
    -- Create surface GUI
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Name = "OwnedSurfaceGui"
    surfaceGui.Face = Enum.NormalId.Top
    surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surfaceGui.PixelsPerStud = 100
    surfaceGui.Parent = targetPart
    
    -- Create "OWNED" text
    local ownedLabel = Instance.new("TextLabel")
    ownedLabel.Size = UDim2.new(1, 0, 1, 0)
    ownedLabel.BackgroundTransparency = 1
    ownedLabel.Font = Enum.Font.FredokaOne
    ownedLabel.Text = "OWNED"
    ownedLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    ownedLabel.TextSize = 32
    ownedLabel.TextStrokeTransparency = 0
    ownedLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    ownedLabel.TextXAlignment = Enum.TextXAlignment.Center
    ownedLabel.TextYAlignment = Enum.TextYAlignment.Center
    ownedLabel.Rotation = 180
    ownedLabel.Parent = surfaceGui
end

function TwoXDiamondsButtonService:ShowOwnedSurfaceGUI()
    if not twoXDiamondsButtonPart then return end
    
    local ownedGui = twoXDiamondsButtonPart:FindFirstChild("OwnedSurfaceGui", true)
    if ownedGui then
        ownedGui.Enabled = true
    end
end

function TwoXDiamondsButtonService:HideOwnedSurfaceGUI()
    if not twoXDiamondsButtonPart then return end
    
    local ownedGui = twoXDiamondsButtonPart:FindFirstChild("OwnedSurfaceGui", true)
    if ownedGui then
        ownedGui.Enabled = false
    end
end

function TwoXDiamondsButtonService:UpdateGamepassStatus(statusLabel, iconLabel)
    if not statusLabel then return end
    
    local playerData = DataSyncService:GetPlayerData()
    local owns2xDiamonds = playerData and playerData.OwnedGamepasses and table.find(playerData.OwnedGamepasses, "TwoXDiamonds")
    
    -- Check if we need to update (ownership changed or still showing Loading...)
    local needsUpdate = lastKnownOwnership ~= owns2xDiamonds or statusLabel.Text == "Loading..."
    
    if not needsUpdate then
        return
    end
    lastKnownOwnership = owns2xDiamonds
    
    -- Get gamepass info for icon and price
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(GAMEPASS_ID, Enum.InfoType.GamePass)
    end)
    
    -- Update icon if we have it
    if iconLabel and success and info and info.IconImageAssetId then
        iconLabel.Image = "rbxassetid://" .. tostring(info.IconImageAssetId)
    end
    
    if owns2xDiamonds then
        statusLabel.Text = "OWNED"
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green
    else
        if success and info then
            statusLabel.Text = info.PriceInRobux .. " R$"
            statusLabel.TextColor3 = Color3.fromRGB(255, 255, 100) -- Yellow
        else
            statusLabel.Text = "Buy Now"
            statusLabel.TextColor3 = Color3.fromRGB(255, 255, 100) -- Yellow
        end
    end
end

function TwoXDiamondsButtonService:SetupProximityDetection()
    -- Get button position for distance calculation
    local buttonPosition
    if twoXDiamondsButtonPart:IsA("Model") then
        local cframe, size = twoXDiamondsButtonPart:GetBoundingBox()
        buttonPosition = cframe.Position
    else
        buttonPosition = twoXDiamondsButtonPart.Position
    end
    
    -- Set up touch detection for the gamepass button
    local function onTouch(hit)
        local character = hit.Parent
        if character == player.Character then
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                local distance = (humanoidRootPart.Position - buttonPosition).Magnitude
                if distance <= INTERACTION_DISTANCE then
                    self:HandleGamepassPurchase()
                end
            end
        end
    end
    
    -- Connect to all parts in the button
    if twoXDiamondsButtonPart:IsA("Model") then
        for _, part in pairs(twoXDiamondsButtonPart:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Touched:Connect(onTouch)
            end
        end
    elseif twoXDiamondsButtonPart:IsA("BasePart") then
        twoXDiamondsButtonPart.Touched:Connect(onTouch)
    end
end


function TwoXDiamondsButtonService:HandleGamepassPurchase()
    -- Check cooldown
    local currentTime = tick()
    if currentTime - lastPurchaseAttempt < PURCHASE_COOLDOWN then
        return
    end
    lastPurchaseAttempt = currentTime
    
    -- Check if player already owns the gamepass
    local playerData = DataSyncService:GetPlayerData()
    local owns2xDiamonds = playerData and playerData.OwnedGamepasses and table.find(playerData.OwnedGamepasses, "TwoXDiamonds")
    
    if owns2xDiamonds then
        return
    end
    
    
    -- Prompt the purchase
    local success, error = pcall(function()
        MarketplaceService:PromptGamePassPurchase(player, GAMEPASS_ID)
    end)
    
    if not success then
        warn("TwoXDiamondsButtonService: Failed to prompt gamepass purchase:", error)
    end
end

function TwoXDiamondsButtonService:HideGamepassGUIsInOtherAreas()
    -- Find all player areas and hide 2x Diamonds GUIs in areas that aren't the player's
    local playerAreas = game.Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then return end
    
    -- Get player's own area for comparison
    local PlayerAreaFinder = require(script.Parent.Parent.utils.PlayerAreaFinder)
    local playerArea = PlayerAreaFinder:FindPlayerArea()
    
    for _, area in pairs(playerAreas:GetChildren()) do
        if area.Name:match("PlayerArea") and area ~= playerArea then
            -- This is not the player's area, hide the 2xDiamondsButton button GUI
            local gamepassButton = area:FindFirstChild("2xDiamondsButton", true)
            if gamepassButton then
                local billboard = gamepassButton:FindFirstChild("GamepassBillboard", true)
                if billboard then
                    billboard.Enabled = false -- Hide the billboard GUI
                end
            end
        end
    end
end

function TwoXDiamondsButtonService:SetupDataSubscription()
    -- Subscribe to data changes to update GUI - BUT ONLY when gamepass data changes
    local lastGamepassData = nil
    
    local unsubscribe = DataSyncService:Subscribe(function(newState)
        if newState and newState.player and newState.player.OwnedGamepasses then
            -- Only update if gamepass data actually changed
            local currentGamepassData = game:GetService("HttpService"):JSONEncode(newState.player.OwnedGamepasses)
            if currentGamepassData ~= lastGamepassData then
                lastGamepassData = currentGamepassData
                self:UpdateGamepassGUI()
            end
        end
    end)
    
    -- Store unsubscribe function for cleanup
    self.dataSubscription = unsubscribe
end

function TwoXDiamondsButtonService:Cleanup()
    if proximityConnection then
        proximityConnection:Disconnect()
        proximityConnection = nil
    end
    
    if self.dataSubscription then
        self.dataSubscription()
        self.dataSubscription = nil
    end
    
    lastKnownOwnership = nil
end

return TwoXDiamondsButtonService