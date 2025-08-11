-- TwoXMoneyButtonService - Handles physical 2x Money button interaction
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local DataSyncService = require(script.Parent.DataSyncService)
local GamepassConfig = require(ReplicatedStorage.config.GamepassConfig)
local PlayerAreaFinder = require(ReplicatedStorage.utils.PlayerAreaFinder)

local TwoXMoneyButtonService = {}
TwoXMoneyButtonService.__index = TwoXMoneyButtonService

local player = Players.LocalPlayer
local proximityConnection = nil
local twoXMoneyButtonPart = nil

-- Configuration
local GAMEPASS_ID = 1351722330
local INTERACTION_DISTANCE = 10 -- Distance in studs to trigger interaction
local PURCHASE_COOLDOWN = 3 -- Seconds between purchase attempts

-- Cooldown tracking
local lastPurchaseAttempt = 0

-- State tracking to prevent unnecessary updates
local lastKnownOwnership = nil

function TwoXMoneyButtonService:Initialize()
    
    -- Find the 2x Money button in the player's area
    self:FindTwoXMoneyButton()
    
    -- Set up proximity detection only if button found in player area
    if twoXMoneyButtonPart then
        self:SetupProximityDetection()
    end
    
    -- Set up data subscription for visibility updates only if button found
    if twoXMoneyButtonPart then
        self:SetupDataSubscription()
    end
    
    -- Hide gamepass GUIs in all OTHER player areas (not own area)
    self:HideGamepassGUIsInOtherAreas()
end

function TwoXMoneyButtonService:FindTwoXMoneyButton()
    -- Wait for character to spawn
    if not player.Character then
        player.CharacterAdded:Wait()
    end
    
    -- Use shared utility to find player's area
    local playerArea = PlayerAreaFinder:WaitForPlayerArea(5)
    if not playerArea then
        warn("TwoXMoneyButtonService: Player area not found")
        return
    end
    
    -- Find the Buttons folder
    local buttonsFolder = playerArea:FindFirstChild("Buttons")
    if not buttonsFolder then
        warn("TwoXMoneyButtonService: Buttons folder not found")
        return
    end
    
    -- Find the 2xMoneyButton
    twoXMoneyButtonPart = buttonsFolder:FindFirstChild("2xMoneyButton")
    if twoXMoneyButtonPart then
        self:UpdateGamepassGUI()
    else
        warn("TwoXMoneyButtonService: 2xMoneyButton not found")
    end
end

function TwoXMoneyButtonService:UpdateGamepassGUI()
    -- GUI already exists from AreaTemplate, just update ownership status
    local existingBillboard = twoXMoneyButtonPart:FindFirstChild("GamepassBillboard", true)
    if not existingBillboard then
        warn("TwoXMoneyButtonService: GamepassBillboard not found - should exist from template")
        return
    end
    
    -- Check ownership and update visibility
    self:CheckOwnershipAndUpdateGUI(existingBillboard)
end

function TwoXMoneyButtonService:CheckOwnershipAndUpdateGUI(billboard)
    -- Get player data to check ownership
    local playerData = DataSyncService:GetPlayerData()
    
    local ownsGamepass = false
    if playerData and playerData.OwnedGamepasses then
        for _, gamepassName in pairs(playerData.OwnedGamepasses) do
            if gamepassName == "TwoXMoney" then
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
function TwoXMoneyButtonService:UpdateBillboardInfo(billboard)
    if not billboard then return end
    
    -- Clean existing elements and create new layout
    billboard:ClearAllChildren()
    
    -- Create container frame for vertical layout
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = billboard
    
    -- Get gamepass info from MarketplaceService (async to prevent yielding in Redux)
    local gamepassId = GamepassConfig.GAMEPASSES.TwoXMoney.id
    local gamepassName = "2X Money"
    local price = GamepassConfig.GAMEPASSES.TwoXMoney.price
    local iconId = nil
    
    -- Use task.spawn to prevent yielding in Redux callback
    task.spawn(function()
        local success, info = pcall(function()
            return MarketplaceService:GetProductInfo(gamepassId, Enum.InfoType.GamePass)
        end)
        
        if success and info then
            gamepassName = info.Name
            price = info.PriceInRobux
            iconId = info.IconImageAssetId
        end
        
        -- Continue with UI creation after async call
        self:CreateBillboardUI(billboard, container, gamepassName, price, iconId)
    end)
end

function TwoXMoneyButtonService:CreateBillboardUI(billboard, container, gamepassName, price, iconId)
    if not billboard or not container then return end
    
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
function TwoXMoneyButtonService:AddOwnedSurfaceGUI()
    if not twoXMoneyButtonPart then 
        return 
    end
    
    -- Check if already exists
    local existingGui = twoXMoneyButtonPart:FindFirstChild("OwnedSurfaceGui")
    if existingGui then
        if existingGui.Parent then
            return
        else
            existingGui:Destroy()
        end
    end
    
    -- Find the main part to attach GUI to
    local targetPart = twoXMoneyButtonPart
    if twoXMoneyButtonPart:IsA("Model") then
        for _, part in pairs(twoXMoneyButtonPart:GetDescendants()) do
            if part:IsA("BasePart") then
                targetPart = part
                break
            end
        end
    end
    
    -- Create surface GUI on Top face to be visible
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Name = "OwnedSurfaceGui"
    surfaceGui.Face = Enum.NormalId.Top
    surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surfaceGui.PixelsPerStud = 100 -- Standardized across all gamepass buttons
    surfaceGui.Parent = targetPart
    
    -- Create "Owned" text label
    local ownedLabel = Instance.new("TextLabel")
    ownedLabel.Name = "OwnedText"
    ownedLabel.Size = UDim2.new(1, 0, 1, 0)
    ownedLabel.BackgroundTransparency = 1
    ownedLabel.Font = Enum.Font.FredokaOne
    ownedLabel.Text = "OWNED"
    ownedLabel.TextColor3 = Color3.fromRGB(255, 255, 0) -- Yellow for visibility
    ownedLabel.TextSize = 32 -- Standardized text size
    ownedLabel.TextStrokeTransparency = 0
    ownedLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    ownedLabel.TextXAlignment = Enum.TextXAlignment.Center
    ownedLabel.TextYAlignment = Enum.TextYAlignment.Center
    ownedLabel.Rotation = 180 -- Rotate 180 degrees to fix upside-down text
    ownedLabel.Parent = surfaceGui
end

function TwoXMoneyButtonService:ShowOwnedSurfaceGUI()
    if not twoXMoneyButtonPart then return end
    
    local ownedGui = twoXMoneyButtonPart:FindFirstChild("OwnedSurfaceGui", true)
    if ownedGui then
        ownedGui.Enabled = true
    end
end

function TwoXMoneyButtonService:HideOwnedSurfaceGUI()
    if not twoXMoneyButtonPart then return end
    
    local ownedGui = twoXMoneyButtonPart:FindFirstChild("OwnedSurfaceGui", true)
    if ownedGui then
        ownedGui.Enabled = false
    end
end

function TwoXMoneyButtonService:SetupProximityDetection()
    if not twoXMoneyButtonPart then return end
    
    -- Clean up existing connections
    if proximityConnection then
        proximityConnection:Disconnect()
    end
    
    -- Get button position for distance calculation
    local buttonPosition
    if twoXMoneyButtonPart:IsA("Model") then
        local cframe, size = twoXMoneyButtonPart:GetBoundingBox()
        buttonPosition = cframe.Position
    else
        buttonPosition = twoXMoneyButtonPart.Position
    end
    
    -- Set up touch detection for the button
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
                    if not self:PlayerOwnsTwoXMoney(playerData) then
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
    
    -- Connect to all parts in the button
    if twoXMoneyButtonPart:IsA("Model") then
        for _, part in pairs(twoXMoneyButtonPart:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Touched:Connect(onTouch)
            end
        end
    elseif twoXMoneyButtonPart:IsA("BasePart") then
        proximityConnection = twoXMoneyButtonPart.Touched:Connect(onTouch)
    end
end

-- Open gamepass purchase popup
function TwoXMoneyButtonService:OpenGamepassPurchasePopup()
    -- Send purchase request to server (same as the GamepassUI does)
    local purchaseGamepassRemote = ReplicatedStorage:FindFirstChild("PurchaseGamepass")
    if purchaseGamepassRemote then
        purchaseGamepassRemote:FireServer("TwoXMoney")
    else
        warn("TwoXMoneyButtonService: PurchaseGamepass remote not found")
    end
end

-- Set up subscription to player data changes for visibility updates
function TwoXMoneyButtonService:SetupDataSubscription()
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

-- Update button visibility based on gamepass ownership
function TwoXMoneyButtonService:UpdateButtonVisibility()
    if not twoXMoneyButtonPart then return end
    
    -- Get player data from DataSyncService
    local playerData = DataSyncService:GetPlayerData()
    local ownsTwoXMoney = self:PlayerOwnsTwoXMoney(playerData)
    
    -- Only update if ownership state has changed
    if lastKnownOwnership == ownsTwoXMoney then
        return -- No change, skip update
    end
    
    -- Update the tracked state
    lastKnownOwnership = ownsTwoXMoney
    
    -- Update the GUI to reflect the new ownership status
    self:UpdateGamepassGUI()
    
end

-- Check if player owns TwoXMoney gamepass
function TwoXMoneyButtonService:PlayerOwnsTwoXMoney(playerData)
    if not playerData or not playerData.OwnedGamepasses then
        return false
    end
    
    for _, gamepass in pairs(playerData.OwnedGamepasses) do
        if gamepass == "TwoXMoney" then
            return true
        end
    end
    
    return false
end

function TwoXMoneyButtonService:HideGamepassGUIsInOtherAreas()
    -- Find all player areas and hide 2x Money GUIs in areas that aren't the player's
    local playerAreas = game.Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then return end
    
    -- Get player's own area for comparison
    local playerArea = PlayerAreaFinder:FindPlayerArea()
    
    for _, area in pairs(playerAreas:GetChildren()) do
        if area.Name:match("PlayerArea") and area ~= playerArea then
            -- This is not the player's area, hide the 2x Money button GUI
            local twoXMoneyButton = area:FindFirstChild("2xMoneyButton", true)
            if twoXMoneyButton then
                local billboard = twoXMoneyButton:FindFirstChild("GamepassBillboard", true)
                if billboard then
                    billboard.Enabled = false -- Hide the billboard GUI
                end
            end
        end
    end
end

-- Clean up connections
function TwoXMoneyButtonService:Cleanup()
    if proximityConnection then
        proximityConnection:Disconnect()
        proximityConnection = nil
    end
    if self.dataSubscription then
        self.dataSubscription()
        self.dataSubscription = nil
    end
    -- Reset cooldown and state tracking
    lastPurchaseAttempt = 0
    lastKnownOwnership = nil
end

return TwoXMoneyButtonService