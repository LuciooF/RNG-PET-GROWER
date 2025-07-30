-- TwoXHeavenSpeedButtonService - Handles physical 2x Heaven Speed button interaction
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local DataSyncService = require(script.Parent.DataSyncService)
local PlayerAreaFinder = require(script.Parent.Parent.utils.PlayerAreaFinder)

local TwoXHeavenSpeedButtonService = {}
TwoXHeavenSpeedButtonService.__index = TwoXHeavenSpeedButtonService

local player = Players.LocalPlayer
local proximityConnection = nil
local twoXHeavenSpeedButtonPart = nil

-- Configuration
local GAMEPASS_ID = 1351198429
local INTERACTION_DISTANCE = 10 -- Distance in studs to trigger interaction
local PURCHASE_COOLDOWN = 3 -- Seconds between purchase attempts

-- Cooldown tracking
local lastPurchaseAttempt = 0

-- State tracking to prevent unnecessary updates
local lastKnownOwnership = nil

function TwoXHeavenSpeedButtonService:Initialize()
    -- Find the 2x Heaven Speed button in the player's area
    self:FindTwoXHeavenSpeedButton()
    
    -- Set up proximity detection
    if twoXHeavenSpeedButtonPart then
        self:SetupProximityDetection()
    end
    
    -- Set up data subscription for visibility updates
    self:SetupDataSubscription()
end

function TwoXHeavenSpeedButtonService:FindTwoXHeavenSpeedButton()
    -- Wait for character to spawn
    if not player.Character then
        player.CharacterAdded:Wait()
    end
    
    -- Use shared utility to find player's area
    local playerArea = PlayerAreaFinder:WaitForPlayerArea(5)
    if not playerArea then
        warn("TwoXHeavenSpeedButtonService: Player area not found")
        return
    end
    
    -- Find the Buttons folder
    local buttonsFolder = playerArea:FindFirstChild("Buttons")
    if not buttonsFolder then
        warn("TwoXHeavenSpeedButtonService: Buttons folder not found")
        return
    end
    
    -- Find the 2xHeavenSpeedButton
    twoXHeavenSpeedButtonPart = buttonsFolder:FindFirstChild("2xHeavenSpeedButton")
    if twoXHeavenSpeedButtonPart then
        print("TwoXHeavenSpeedButtonService: Found 2xHeavenSpeedButton")
        self:CreateGamepassGUI()
    else
        warn("TwoXHeavenSpeedButtonService: 2xHeavenSpeedButton not found")
    end
end

function TwoXHeavenSpeedButtonService:CreateGamepassGUI()
    -- Find the best part to attach GUI to
    local targetPart = nil
    if twoXHeavenSpeedButtonPart:IsA("Model") then
        -- Look for a suitable part in the model
        for _, part in pairs(twoXHeavenSpeedButtonPart:GetDescendants()) do
            if part:IsA("BasePart") then
                targetPart = part
                break
            end
        end
    else
        targetPart = twoXHeavenSpeedButtonPart
    end
    
    if not targetPart then
        warn("TwoXHeavenSpeedButtonService: No suitable part found for GUI attachment")
        return
    end
    
    -- Clean up existing GUIs
    local existingBillboard = twoXHeavenSpeedButtonPart:FindFirstChild("GamepassBillboard", true)
    if existingBillboard then
        existingBillboard:Destroy()
    end
    
    -- Create BillboardGui for gamepass information
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "GamepassBillboard"
    billboardGui.Size = UDim2.new(0, 150, 0, 80) -- Smaller size
    billboardGui.StudsOffset = Vector3.new(0, 4, 0) -- Float 4 studs above the part
    billboardGui.MaxDistance = 80 -- Much further visibility for camera angles
    billboardGui.Parent = targetPart
    
    -- Create gamepass icon
    local iconLabel = Instance.new("ImageLabel")
    iconLabel.Name = "GamepassIcon"
    iconLabel.Size = UDim2.new(0, 40, 0, 40)
    iconLabel.Position = UDim2.new(0.5, -20, 0, 5)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png" -- Default, will be updated
    iconLabel.Parent = billboardGui
    
    -- Create gamepass label
    local gamepassLabel = Instance.new("TextLabel")
    gamepassLabel.Name = "GamepassText"
    gamepassLabel.Size = UDim2.new(1, 0, 0, 20)
    gamepassLabel.Position = UDim2.new(0, 0, 0, 48)
    gamepassLabel.BackgroundTransparency = 1
    gamepassLabel.Font = Enum.Font.GothamBold
    gamepassLabel.Text = "2x Speed"
    gamepassLabel.TextColor3 = Color3.fromRGB(255, 100, 255) -- Purple color for heaven
    gamepassLabel.TextSize = 18
    gamepassLabel.TextStrokeTransparency = 0
    gamepassLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    gamepassLabel.Parent = billboardGui
    
    -- Create status label (will show "Owned" or price)
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusText"
    statusLabel.Size = UDim2.new(1, 0, 0, 14)
    statusLabel.Position = UDim2.new(0, 0, 1, -16)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Text = "Loading..."
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLabel.TextSize = 14
    statusLabel.TextStrokeTransparency = 0
    statusLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    statusLabel.Parent = billboardGui
    
    -- Update status and icon based on ownership
    self:UpdateGamepassStatus(statusLabel, iconLabel)
    
    -- Also try to update immediately in case data is already loaded
    task.spawn(function()
        task.wait(0.5) -- Small delay to ensure MarketplaceService is ready
        self:UpdateGamepassStatus(statusLabel, iconLabel)
    end)
end

function TwoXHeavenSpeedButtonService:UpdateGamepassStatus(statusLabel, iconLabel)
    if not statusLabel then return end
    
    local playerData = DataSyncService:GetPlayerData()
    local owns2xHeavenSpeed = playerData and playerData.OwnedGamepasses and table.find(playerData.OwnedGamepasses, "TwoXHeavenSpeed")
    
    -- Check if we need to update (ownership changed or still showing Loading...)
    local needsUpdate = lastKnownOwnership ~= owns2xHeavenSpeed or statusLabel.Text == "Loading..."
    
    if not needsUpdate then
        return
    end
    lastKnownOwnership = owns2xHeavenSpeed
    
    -- Get gamepass info for icon and price
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(GAMEPASS_ID, Enum.InfoType.GamePass)
    end)
    
    -- Update icon if we have it
    if iconLabel and success and info and info.IconImageAssetId then
        iconLabel.Image = "rbxassetid://" .. tostring(info.IconImageAssetId)
    end
    
    if owns2xHeavenSpeed then
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

function TwoXHeavenSpeedButtonService:SetupProximityDetection()
    -- Get button position for distance calculation
    local buttonPosition
    if twoXHeavenSpeedButtonPart:IsA("Model") then
        local cframe, size = twoXHeavenSpeedButtonPart:GetBoundingBox()
        buttonPosition = cframe.Position
    else
        buttonPosition = twoXHeavenSpeedButtonPart.Position
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
    if twoXHeavenSpeedButtonPart:IsA("Model") then
        for _, part in pairs(twoXHeavenSpeedButtonPart:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Touched:Connect(onTouch)
            end
        end
    elseif twoXHeavenSpeedButtonPart:IsA("BasePart") then
        twoXHeavenSpeedButtonPart.Touched:Connect(onTouch)
    end
end


function TwoXHeavenSpeedButtonService:HandleGamepassPurchase()
    -- Check cooldown
    local currentTime = tick()
    if currentTime - lastPurchaseAttempt < PURCHASE_COOLDOWN then
        return
    end
    lastPurchaseAttempt = currentTime
    
    -- Check if player already owns the gamepass
    local playerData = DataSyncService:GetPlayerData()
    local owns2xHeavenSpeed = playerData and playerData.OwnedGamepasses and table.find(playerData.OwnedGamepasses, "TwoXHeavenSpeed")
    
    if owns2xHeavenSpeed then
        print("TwoXHeavenSpeedButtonService: Player already owns 2x Heaven Speed gamepass")
        return
    end
    
    print("TwoXHeavenSpeedButtonService: Prompting 2x Heaven Speed gamepass purchase")
    
    -- Prompt the purchase
    local success, error = pcall(function()
        MarketplaceService:PromptGamePassPurchase(player, GAMEPASS_ID)
    end)
    
    if not success then
        warn("TwoXHeavenSpeedButtonService: Failed to prompt gamepass purchase:", error)
    end
end

function TwoXHeavenSpeedButtonService:SetupDataSubscription()
    -- Subscribe to data changes to update GUI
    DataSyncService:Subscribe(function(newState)
        if newState and newState.player then
            local billboard = twoXHeavenSpeedButtonPart and twoXHeavenSpeedButtonPart:FindFirstChild("GamepassBillboard", true)
            if billboard then
                local statusLabel = billboard:FindFirstChild("StatusText")
                local iconLabel = billboard:FindFirstChild("GamepassIcon")
                if statusLabel then
                    self:UpdateGamepassStatus(statusLabel, iconLabel)
                end
            end
        end
    end)
end

function TwoXHeavenSpeedButtonService:Cleanup()
    if proximityConnection then
        proximityConnection:Disconnect()
        proximityConnection = nil
    end
    
    lastKnownOwnership = nil
    print("TwoXHeavenSpeedButtonService: Cleaned up")
end

-- Handle character respawn
Players.LocalPlayer.CharacterAdded:Connect(function()
    -- Re-initialize after character respawn
    TwoXHeavenSpeedButtonService:Cleanup()
    task.wait(1) -- Wait for character to fully load
    TwoXHeavenSpeedButtonService:Initialize()
end)

return TwoXHeavenSpeedButtonService