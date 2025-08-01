-- AutoHeavenButtonService - Handles physical AutoSendHeaven button interaction
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local DataSyncService = require(script.Parent.DataSyncService)
local GamepassConfig = require(ReplicatedStorage.config.GamepassConfig)
local PlayerAreaFinder = require(script.Parent.Parent.utils.PlayerAreaFinder)

local AutoHeavenButtonService = {}
AutoHeavenButtonService.__index = AutoHeavenButtonService

local player = Players.LocalPlayer
local proximityConnection = nil
local autoHeavenButtonPart = nil

-- Configuration
local INTERACTION_DISTANCE = 10 -- Distance in studs to trigger interaction
local PURCHASE_COOLDOWN = 3 -- Seconds between purchase attempts

-- Cooldown tracking
local lastPurchaseAttempt = 0

-- State tracking to prevent unnecessary updates
local lastKnownOwnership = nil

function AutoHeavenButtonService:Initialize()
    -- Find the AutoSendHeaven button in the player's area
    self:FindAutoHeavenButton()
    
    -- Set up proximity detection
    if autoHeavenButtonPart then
        self:SetupProximityDetection()
    end
    
    -- Set up data subscription for visibility updates
    self:SetupDataSubscription()
    
    -- Set up gamepass purchase detection
    self:SetupGamepassPurchaseDetection()
end

function AutoHeavenButtonService:FindAutoHeavenButton()
    -- Wait for character to spawn
    if not player.Character then
        player.CharacterAdded:Wait()
    end
    
    -- Use shared utility to find player's area
    local playerArea = PlayerAreaFinder:WaitForPlayerArea(5)
    if not playerArea then
        warn("AutoHeavenButtonService: Player area not found")
        return
    end
    
    -- Find the AutoSendHeaven button
    local buttonsFolder = playerArea:FindFirstChild("Buttons")
    if not buttonsFolder then
        warn("AutoHeavenButtonService: Buttons folder not found")
        return
    end
    
    autoHeavenButtonPart = buttonsFolder:FindFirstChild("AutoSendHeaven")
    if not autoHeavenButtonPart then
        warn("AutoHeavenButtonService: AutoSendHeaven button not found")
        return
    end
    
    -- Update existing template GUI with ownership status
    self:UpdateGamepassGUI()
end

function AutoHeavenButtonService:UpdateGamepassGUI()
    -- GUI already exists from AreaTemplate, just update ownership status
    local existingBillboard = autoHeavenButtonPart:FindFirstChild("GamepassBillboard", true)
    if not existingBillboard then
        warn("AutoHeavenButtonService: GamepassBillboard not found - should exist from template")
        return
    end
    
    -- Check ownership and update visibility
    self:CheckOwnershipAndUpdateGUI(existingBillboard)
end

function AutoHeavenButtonService:CheckOwnershipAndUpdateGUI(billboard)
    -- Get player data to check ownership
    local playerData = DataSyncService:GetPlayerData()
    
    local ownsGamepass = false
    if playerData and playerData.OwnedGamepasses then
        for _, gamepassName in pairs(playerData.OwnedGamepasses) do
            if gamepassName == "AutoHeaven" then
                ownsGamepass = true
                break
            end
        end
    end
    
    -- Update billboard GUI with icon and price
    self:UpdateBillboardInfo(billboard)
    
    -- Show/hide OWNED surface GUI based on ownership
    if ownsGamepass then
        self:ShowOwnedSurfaceGUI()
    else
        self:HideOwnedSurfaceGUI()
    end
    
end

-- Update billboard GUI with gamepass icon, name, and robux price
function AutoHeavenButtonService:UpdateBillboardInfo(billboard)
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
    local gamepassId = GamepassConfig.GAMEPASSES.AutoHeaven.id
    local gamepassName = "Auto Heaven"
    local price = GamepassConfig.GAMEPASSES.AutoHeaven.price
    local iconId = nil
    
    -- Wrap yielding call in task.spawn to prevent yielding in changed event
    task.spawn(function()
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
        nameLabel.Font = Enum.Font.GothamBold
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
        priceLabel.Font = Enum.Font.GothamBold
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
    end)
end

-- Add "Owned" surface GUI to the button part
function AutoHeavenButtonService:AddOwnedSurfaceGUI()
    if not autoHeavenButtonPart then return end
    
    -- Check if already exists
    local existingGui = autoHeavenButtonPart:FindFirstChild("OwnedSurfaceGui")
    if existingGui then return end
    
    -- Find first BasePart in the button model
    local targetPart = autoHeavenButtonPart
    if autoHeavenButtonPart:IsA("Model") then
        for _, part in pairs(autoHeavenButtonPart:GetDescendants()) do
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
    
    -- Create "OWNED" text label
    local ownedLabel = Instance.new("TextLabel")
    ownedLabel.Name = "OwnedText"
    ownedLabel.Size = UDim2.new(1, 0, 1, 0)
    ownedLabel.BackgroundTransparency = 1
    ownedLabel.Font = Enum.Font.GothamBold
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

-- Remove "Owned" surface GUI from the button part
function AutoHeavenButtonService:ShowOwnedSurfaceGUI()
    if not autoHeavenButtonPart then return end
    
    -- Find and show owned surface GUI
    local ownedGui = autoHeavenButtonPart:FindFirstChild("OwnedSurfaceGui", true)
    if ownedGui then
        ownedGui.Enabled = true
    end
end

function AutoHeavenButtonService:HideOwnedSurfaceGUI()
    if not autoHeavenButtonPart then return end
    
    -- Find and hide owned surface GUI
    local ownedGui = autoHeavenButtonPart:FindFirstChild("OwnedSurfaceGui", true)
    if ownedGui then
        ownedGui.Enabled = false
    end
end

-- Set up subscription to player data changes for visibility updates
function AutoHeavenButtonService:SetupDataSubscription()
    -- Subscribe to data changes to check gamepass ownership - BUT ONLY when gamepass data changes
    local lastGamepassData = nil
    
    local unsubscribe = DataSyncService:Subscribe(function(newState)
        if newState.player and newState.player.OwnedGamepasses then
            -- Only update if gamepass data actually changed
            local currentGamepassData = game:GetService("HttpService"):JSONEncode(newState.player.OwnedGamepasses)
            if currentGamepassData ~= lastGamepassData then
                lastGamepassData = currentGamepassData
                self:UpdateButtonVisibility()
            end
        end
    end)
    
    -- Store unsubscribe function for cleanup
    self.dataSubscription = unsubscribe
end

function AutoHeavenButtonService:SetupGamepassPurchaseDetection()
    -- Listen for gamepass purchases to update OWNED status in real-time
    local gamepassId = GamepassConfig.GAMEPASSES.AutoHeaven.id
    
    self.purchaseConnection = MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(playerWhoMadePurchase, gamePassId, wasPurchased)
        if playerWhoMadePurchase == player and gamePassId == gamepassId and wasPurchased then
            print("AutoHeavenButtonService: AutoHeaven gamepass purchased! Updating OWNED status...")
            -- Small delay to let server update the data
            task.wait(1)
            self:UpdateGamepassGUI()
        end
    end)
end

-- Update button visibility based on gamepass ownership
function AutoHeavenButtonService:UpdateButtonVisibility()
    if not autoHeavenButtonPart then return end
    
    -- Get player data from DataSyncService
    local playerData = DataSyncService:GetPlayerData()
    local ownsAutoHeaven = self:PlayerOwnsAutoHeaven(playerData)
    
    -- Only update if ownership state has changed
    if lastKnownOwnership == ownsAutoHeaven then
        return -- No change, skip update
    end
    
    -- Update the tracked state
    lastKnownOwnership = ownsAutoHeaven
    
    -- Update the GUI to reflect the new ownership status
    self:UpdateGamepassGUI()
    
end


-- Check if player owns AutoHeaven gamepass
function AutoHeavenButtonService:PlayerOwnsAutoHeaven(playerData)
    if not playerData or not playerData.OwnedGamepasses then
        return false
    end
    
    for _, gamepass in pairs(playerData.OwnedGamepasses) do
        if gamepass == "AutoHeaven" then
            return true
        end
    end
    
    return false
end

function AutoHeavenButtonService:SetupProximityDetection()
    if not autoHeavenButtonPart then return end
    
    -- Clean up existing connections
    if proximityConnection then
        proximityConnection:Disconnect()
    end
    
    -- Get button position for distance calculation
    local buttonPosition
    if autoHeavenButtonPart:IsA("Model") then
        local cframe, size = autoHeavenButtonPart:GetBoundingBox()
        buttonPosition = cframe.Position
    else
        buttonPosition = autoHeavenButtonPart.Position
    end
    
    -- Set up touch detection for the AutoSendHeaven button (handle Model with multiple parts)
    local function onTouch(hit)
        local character = hit.Parent
        if character == player.Character then
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                local distance = (humanoidRootPart.Position - buttonPosition).Magnitude
                if distance <= INTERACTION_DISTANCE then
                    -- Check cooldown to prevent spamming
                    local currentTime = tick()
                    if currentTime - lastPurchaseAttempt < PURCHASE_COOLDOWN then
                        local timeLeft = PURCHASE_COOLDOWN - (currentTime - lastPurchaseAttempt)
                        return -- Still in cooldown, ignore touch
                    end
                    
                    -- Check if player already owns the gamepass
                    local playerData = DataSyncService:GetPlayerData()
                    if not self:PlayerOwnsAutoHeaven(playerData) then
                        -- Update cooldown timer
                        lastPurchaseAttempt = currentTime
                        -- Trigger gamepass purchase popup
                        self:OpenGamepassPurchasePopup()
                    else
                    end
                end
            end
        end
    end
    
    -- Connect to all parts in the AutoSendHeaven button (in case it's a model with multiple parts)
    if autoHeavenButtonPart:IsA("Model") then
        for _, part in pairs(autoHeavenButtonPart:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Touched:Connect(onTouch)
            end
        end
    elseif autoHeavenButtonPart:IsA("BasePart") then
        proximityConnection = autoHeavenButtonPart.Touched:Connect(onTouch)
    end
end

-- Open gamepass purchase popup
function AutoHeavenButtonService:OpenGamepassPurchasePopup()
    -- Send purchase request to server (same as the GamepassUI does)
    local purchaseGamepassRemote = ReplicatedStorage:FindFirstChild("PurchaseGamepass")
    if purchaseGamepassRemote then
        purchaseGamepassRemote:FireServer("AutoHeaven")
    else
        warn("AutoHeavenButtonService: PurchaseGamepass remote not found")
    end
end

-- Clean up connections
function AutoHeavenButtonService:Cleanup()
    if proximityConnection then
        proximityConnection:Disconnect()
        proximityConnection = nil
    end
    if self.dataSubscription then
        self.dataSubscription()
        self.dataSubscription = nil
    end
    if self.purchaseConnection then
        self.purchaseConnection:Disconnect()
        self.purchaseConnection = nil
    end
    -- Reset cooldown and state tracking
    lastPurchaseAttempt = 0
    lastKnownOwnership = nil
end

return AutoHeavenButtonService