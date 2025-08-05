-- PetMagnetButtonService - Handles physical PetMagnet button interaction
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DataSyncService = require(script.Parent.DataSyncService)
local GamepassConfig = require(ReplicatedStorage.config.GamepassConfig)
local PlayerAreaFinder = require(script.Parent.Parent.utils.PlayerAreaFinder)

local PetMagnetButtonService = {}
PetMagnetButtonService.__index = PetMagnetButtonService

local player = Players.LocalPlayer
local proximityConnection = nil
local petMagnetButtonPart = nil

-- Configuration
local INTERACTION_DISTANCE = 10 -- Distance in studs to trigger interaction
local PURCHASE_COOLDOWN = 3 -- Seconds between purchase attempts

-- Cooldown tracking
local lastPurchaseAttempt = 0

-- State tracking to prevent unnecessary updates
local lastKnownOwnership = nil

function PetMagnetButtonService:Initialize()
    -- Find the PetMagnet button in the player's area
    self:FindPetMagnetButton()
    
    -- Set up proximity detection
    if petMagnetButtonPart then
        self:SetupProximityDetection()
    end
    
    -- Set up data subscription for visibility updates only if button found
    if petMagnetButtonPart then
        self:SetupDataSubscription()
    end
    
    -- Hide gamepass GUIs in all OTHER player areas (not own area)
    self:HideGamepassGUIsInOtherAreas()
end

function PetMagnetButtonService:FindPetMagnetButton()
    -- Wait for character to spawn
    if not player.Character then
        player.CharacterAdded:Wait()
    end
    
    -- Use shared utility to find player's area
    local playerArea = PlayerAreaFinder:WaitForPlayerArea(5)
    if not playerArea then
        warn("PetMagnetButtonService: Player area not found")
        return
    end
    
    -- Find the PetMagnet button
    local buttonsFolder = playerArea:FindFirstChild("Buttons")
    if not buttonsFolder then
        warn("PetMagnetButtonService: Buttons folder not found")
        return
    end
    
    petMagnetButtonPart = buttonsFolder:FindFirstChild("PetMagnet")
    if not petMagnetButtonPart then
        warn("PetMagnetButtonService: PetMagnet button not found")
        return
    end
    
    -- Update existing template GUI with ownership status
    self:UpdateGamepassGUI()
end

function PetMagnetButtonService:UpdateGamepassGUI()
    -- GUI already exists from AreaTemplate, just update ownership status
    local existingBillboard = petMagnetButtonPart:FindFirstChild("GamepassBillboard", true)
    if not existingBillboard then
        warn("PetMagnetButtonService: GamepassBillboard not found - should exist from template")
        return
    end
    
    -- Check ownership and update visibility
    self:CheckOwnershipAndUpdateGUI(existingBillboard)
end

function PetMagnetButtonService:CheckOwnershipAndUpdateGUI(billboard)
    -- Get player data to check ownership
    local playerData = DataSyncService:GetPlayerData()
    
    local ownsGamepass = false
    if playerData and playerData.OwnedGamepasses then
        for _, gamepassName in pairs(playerData.OwnedGamepasses) do
            if gamepassName == "PetMagnet" then
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
function PetMagnetButtonService:UpdateBillboardInfo(billboard)
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
    local MarketplaceService = game:GetService("MarketplaceService")
    local gamepassId = GamepassConfig.GAMEPASSES.PetMagnet.id
    local gamepassName = "Pet Magnet"
    local price = GamepassConfig.GAMEPASSES.PetMagnet.price
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
    end)
end

-- Add "Owned" surface GUI to the button part
function PetMagnetButtonService:AddOwnedSurfaceGUI()
    if not petMagnetButtonPart then return end
    
    -- Check if already exists
    local existingGui = petMagnetButtonPart:FindFirstChild("OwnedSurfaceGui")
    if existingGui then return end
    
    -- Find first BasePart in the button model
    local targetPart = petMagnetButtonPart
    if petMagnetButtonPart:IsA("Model") then
        for _, part in pairs(petMagnetButtonPart:GetDescendants()) do
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

function PetMagnetButtonService:ShowOwnedSurfaceGUI()
    if not petMagnetButtonPart then return end
    
    local ownedGui = petMagnetButtonPart:FindFirstChild("OwnedSurfaceGui", true)
    if ownedGui then
        ownedGui.Enabled = true
    end
end

function PetMagnetButtonService:HideOwnedSurfaceGUI()
    if not petMagnetButtonPart then return end
    
    local ownedGui = petMagnetButtonPart:FindFirstChild("OwnedSurfaceGui", true)
    if ownedGui then
        ownedGui.Enabled = false
    end
end

function PetMagnetButtonService:HideGamepassGUIsInOtherAreas()
    -- Find all player areas and hide Pet Magnet GUIs in areas that aren't the player's
    local playerAreas = game.Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then return end
    
    -- Get player's own area for comparison
    local PlayerAreaFinder = require(script.Parent.Parent.utils.PlayerAreaFinder)
    local playerArea = PlayerAreaFinder:FindPlayerArea()
    
    for _, area in pairs(playerAreas:GetChildren()) do
        if area.Name:match("PlayerArea") and area ~= playerArea then
            -- This is not the player's area, hide the PetMagnet button GUI
            local gamepassButton = area:FindFirstChild("PetMagnet", true)
            if gamepassButton then
                local billboard = gamepassButton:FindFirstChild("GamepassBillboard", true)
                if billboard then
                    billboard.Enabled = false -- Hide the billboard GUI
                end
            end
        end
    end
end

-- Set up subscription to player data changes for visibility updates
function PetMagnetButtonService:SetupDataSubscription()
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
function PetMagnetButtonService:UpdateButtonVisibility()
    if not petMagnetButtonPart then return end
    
    -- Get player data from DataSyncService
    local playerData = DataSyncService:GetPlayerData()
    local ownsPetMagnet = self:PlayerOwnsPetMagnet(playerData)
    
    -- Only update if ownership state has changed
    if lastKnownOwnership == ownsPetMagnet then
        return -- No change, skip update
    end
    
    -- Update the tracked state
    lastKnownOwnership = ownsPetMagnet
    
    -- Update the GUI to reflect the new ownership status
    self:UpdateGamepassGUI()
    
end


-- Check if player owns PetMagnet gamepass
function PetMagnetButtonService:PlayerOwnsPetMagnet(playerData)
    if not playerData or not playerData.OwnedGamepasses then
        return false
    end
    
    for _, gamepass in pairs(playerData.OwnedGamepasses) do
        if gamepass == "PetMagnet" then
            return true
        end
    end
    
    return false
end

function PetMagnetButtonService:SetupProximityDetection()
    if not petMagnetButtonPart then return end
    
    -- Clean up existing connections
    if proximityConnection then
        proximityConnection:Disconnect()
    end
    
    -- Get button position for distance calculation
    local buttonPosition
    if petMagnetButtonPart:IsA("Model") then
        local cframe, size = petMagnetButtonPart:GetBoundingBox()
        buttonPosition = cframe.Position
    else
        buttonPosition = petMagnetButtonPart.Position
    end
    
    -- Set up touch detection for the PetMagnet button (handle Model with multiple parts)
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
                    if not self:PlayerOwnsPetMagnet(playerData) then
                        -- Update cooldown timer
                        lastPurchaseAttempt = currentTime
                        -- Trigger gamepass purchase popup
                        self:OpenGamepassPurchasePopup()
                    end
                end
            end
        end
    end
    
    -- Connect to all parts in the PetMagnet button (in case it's a model with multiple parts)
    if petMagnetButtonPart:IsA("Model") then
        for _, part in pairs(petMagnetButtonPart:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Touched:Connect(onTouch)
            end
        end
    elseif petMagnetButtonPart:IsA("BasePart") then
        proximityConnection = petMagnetButtonPart.Touched:Connect(onTouch)
    end
end

-- Open gamepass purchase popup
function PetMagnetButtonService:OpenGamepassPurchasePopup()
    -- Send purchase request to server (same as the GamepassUI does)
    local purchaseGamepassRemote = ReplicatedStorage:FindFirstChild("PurchaseGamepass")
    if purchaseGamepassRemote then
        purchaseGamepassRemote:FireServer("PetMagnet")
    else
        warn("PetMagnetButtonService: PurchaseGamepass remote not found")
    end
end

-- Clean up connections
function PetMagnetButtonService:Cleanup()
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

return PetMagnetButtonService