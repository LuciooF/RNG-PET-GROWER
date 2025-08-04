-- VIPButtonService - Handles physical VIP button interaction (includes all gamepasses)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local DataSyncService = require(script.Parent.DataSyncService)
local PlayerAreaFinder = require(script.Parent.Parent.utils.PlayerAreaFinder)

local VIPButtonService = {}
VIPButtonService.__index = VIPButtonService

local player = Players.LocalPlayer
local proximityConnection = nil
local vipButtonPart = nil

-- Configuration
local GAMEPASS_ID = 1351374499
local INTERACTION_DISTANCE = 10 -- Distance in studs to trigger interaction
local PURCHASE_COOLDOWN = 3 -- Seconds between purchase attempts

-- Cooldown tracking
local lastPurchaseAttempt = 0

-- State tracking to prevent unnecessary updates
local lastKnownOwnership = nil

function VIPButtonService:Initialize()
    -- Find the VIP button in the player's area only
    self:FindVIPButton()
    
    -- Set up proximity detection only if button found in player area
    if vipButtonPart then
        self:SetupProximityDetection()
    end
    
    -- Set up data subscription for visibility updates only if button found
    if vipButtonPart then
        self:SetupDataSubscription()
    end
    
    -- Hide gamepass GUIs in all OTHER player areas (not own area)
    self:HideGamepassGUIsInOtherAreas()
end

function VIPButtonService:FindVIPButton()
    -- Wait for character to spawn
    if not player.Character then
        player.CharacterAdded:Wait()
    end
    
    -- Use shared utility to find player's area
    local playerArea = PlayerAreaFinder:WaitForPlayerArea(5)
    if not playerArea then
        warn("VIPButtonService: Player area not found")
        return
    end
    
    -- Find the Buttons folder
    local buttonsFolder = playerArea:FindFirstChild("Buttons")
    if not buttonsFolder then
        warn("VIPButtonService: Buttons folder not found")
        return
    end
    
    -- Find the VIPButton (for purchase logic)
    vipButtonPart = buttonsFolder:FindFirstChild("VIPButton")
    if vipButtonPart then
        -- Found VIP button
    else
        warn("VIPButtonService: VIPButton not found")
    end
    
    -- Update the GUI regardless (will find the stand separately)
    self:UpdateGamepassGUI()
end

function VIPButtonService:UpdateGamepassGUI()
    -- GUI already exists from AreaTemplate, just update ownership status
    local existingBillboard = vipButtonPart:FindFirstChild("GamepassBillboard", true)
    if not existingBillboard then
        warn("VIPButtonService: GamepassBillboard not found - should exist from template")
        return
    end
    
    -- Check ownership and update visibility
    self:CheckOwnershipAndUpdateGUI(existingBillboard)
end

function VIPButtonService:CheckOwnershipAndUpdateGUI(billboard)
    -- Get player data to check ownership
    local playerData = DataSyncService:GetPlayerData()
    
    local ownsGamepass = false
    if playerData and playerData.OwnedGamepasses then
        for _, gamepassName in pairs(playerData.OwnedGamepasses) do
            if gamepassName == "VIP" then
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
function VIPButtonService:UpdateBillboardInfo(billboard)
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
    local gamepassName = "VIP"
    local price = "100" -- fallback price
    local iconId = nil
    
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(GAMEPASS_ID, Enum.InfoType.GamePass)
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
end

function VIPButtonService:ShowOwnedSurfaceGUI()
    if not vipButtonPart then return end
    
    local ownedGui = vipButtonPart:FindFirstChild("OwnedSurfaceGui", true)
    if ownedGui then
        ownedGui.Enabled = true
    end
end

function VIPButtonService:HideOwnedSurfaceGUI()
    if not vipButtonPart then return end
    
    local ownedGui = vipButtonPart:FindFirstChild("OwnedSurfaceGui", true)
    if ownedGui then
        ownedGui.Enabled = false
    end
end


function VIPButtonService:SetupProximityDetection()
    -- Get button position for distance calculation
    local buttonPosition
    if vipButtonPart:IsA("Model") then
        local cframe, size = vipButtonPart:GetBoundingBox()
        buttonPosition = cframe.Position
    else
        buttonPosition = vipButtonPart.Position
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
    if vipButtonPart:IsA("Model") then
        for _, part in pairs(vipButtonPart:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Touched:Connect(onTouch)
            end
        end
    elseif vipButtonPart:IsA("BasePart") then
        vipButtonPart.Touched:Connect(onTouch)
    end
end


function VIPButtonService:HandleGamepassPurchase()
    -- Check cooldown
    local currentTime = tick()
    if currentTime - lastPurchaseAttempt < PURCHASE_COOLDOWN then
        return
    end
    lastPurchaseAttempt = currentTime
    
    -- Check if player already owns the gamepass
    local playerData = DataSyncService:GetPlayerData()
    local ownsVIP = playerData and playerData.OwnedGamepasses and table.find(playerData.OwnedGamepasses, "VIP")
    
    if ownsVIP then
        print("VIPButtonService: Player already owns VIP gamepass")
        return
    end
    
    print("VIPButtonService: Prompting VIP gamepass purchase")
    
    -- Send purchase request to server (same as the GamepassUI does)
    local purchaseGamepassRemote = ReplicatedStorage:FindFirstChild("PurchaseGamepass")
    if purchaseGamepassRemote then
        purchaseGamepassRemote:FireServer("VIP")
        print("VIPButtonService: Triggered VIP gamepass purchase")
    else
        warn("VIPButtonService: PurchaseGamepass remote not found")
    end
end

function VIPButtonService:SetupDataSubscription()
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

function VIPButtonService:HideGamepassGUIsInOtherAreas()
    -- Find all player areas and hide VIP GUIs in areas that aren't the player's
    local playerAreas = game.Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then return end
    
    -- Get player's own area for comparison
    local playerArea = PlayerAreaFinder:FindPlayerArea()
    
    for _, area in pairs(playerAreas:GetChildren()) do
        if area.Name:match("PlayerArea") and area ~= playerArea then
            -- This is not the player's area, hide the VIP button GUI
            local vipButton = area:FindFirstChild("VIPButton", true)
            if vipButton then
                local billboard = vipButton:FindFirstChild("GamepassBillboard", true)
                if billboard then
                    billboard.Enabled = false -- Hide the billboard GUI
                end
            end
        end
    end
end

function VIPButtonService:Cleanup()
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

return VIPButtonService