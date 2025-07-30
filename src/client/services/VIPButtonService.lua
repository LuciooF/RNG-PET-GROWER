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
    -- Find the VIP button in the player's area
    self:FindVIPButton()
    
    -- Set up proximity detection
    if vipButtonPart then
        self:SetupProximityDetection()
    end
    
    -- Set up data subscription for visibility updates
    self:SetupDataSubscription()
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
    
    -- Find the VIPButton
    vipButtonPart = buttonsFolder:FindFirstChild("VIPButton")
    if vipButtonPart then
        print("VIPButtonService: Found VIPButton")
        self:CreateGamepassGUI()
    else
        warn("VIPButtonService: VIPButton not found")
    end
end

function VIPButtonService:CreateGamepassGUI()
    -- Find the best part to attach GUI to
    local targetPart = nil
    if vipButtonPart:IsA("Model") then
        -- Look for a suitable part in the model
        for _, part in pairs(vipButtonPart:GetDescendants()) do
            if part:IsA("BasePart") then
                targetPart = part
                break
            end
        end
    else
        targetPart = vipButtonPart
    end
    
    if not targetPart then
        warn("VIPButtonService: No suitable part found for GUI attachment")
        return
    end
    
    -- Clean up existing GUIs
    local existingBillboard = vipButtonPart:FindFirstChild("GamepassBillboard", true)
    if existingBillboard then
        existingBillboard:Destroy()
    end
    
    -- Create BillboardGui for gamepass information
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "GamepassBillboard"
    billboardGui.Size = UDim2.new(0, 160, 0, 100) -- Slightly bigger for VIP
    billboardGui.StudsOffset = Vector3.new(0, 4, 0) -- Float 4 studs above the part
    billboardGui.MaxDistance = 80 -- Much further visibility for camera angles
    billboardGui.Parent = targetPart
    
    -- Create gamepass icon
    local iconLabel = Instance.new("ImageLabel")
    iconLabel.Name = "GamepassIcon"
    iconLabel.Size = UDim2.new(0, 50, 0, 50) -- Bigger icon for VIP
    iconLabel.Position = UDim2.new(0.5, -25, 0, 5)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png" -- Default, will be updated
    iconLabel.Parent = billboardGui
    
    -- Create gamepass label
    local gamepassLabel = Instance.new("TextLabel")
    gamepassLabel.Name = "GamepassText"
    gamepassLabel.Size = UDim2.new(1, 0, 0, 20)
    gamepassLabel.Position = UDim2.new(0, 0, 0, 58)
    gamepassLabel.BackgroundTransparency = 1
    gamepassLabel.Font = Enum.Font.GothamBold
    gamepassLabel.Text = "VIP"
    gamepassLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold color for VIP
    gamepassLabel.TextSize = 20
    gamepassLabel.TextStrokeTransparency = 0
    gamepassLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    gamepassLabel.Parent = billboardGui
    
    -- Create benefits label
    local benefitsLabel = Instance.new("TextLabel")
    benefitsLabel.Name = "BenefitsText"
    benefitsLabel.Size = UDim2.new(1, 0, 0, 12)
    benefitsLabel.Position = UDim2.new(0, 0, 0, 80)
    benefitsLabel.BackgroundTransparency = 1
    benefitsLabel.Font = Enum.Font.Gotham
    benefitsLabel.Text = "All Passes Included!"
    benefitsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    benefitsLabel.TextSize = 10
    benefitsLabel.TextStrokeTransparency = 0
    benefitsLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    benefitsLabel.Parent = billboardGui
    
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

function VIPButtonService:UpdateGamepassStatus(statusLabel, iconLabel)
    if not statusLabel then return end
    
    local playerData = DataSyncService:GetPlayerData()
    local ownsVIP = playerData and playerData.OwnedGamepasses and table.find(playerData.OwnedGamepasses, "VIP")
    
    -- Check if we need to update (ownership changed or still showing Loading...)
    local needsUpdate = lastKnownOwnership ~= ownsVIP or statusLabel.Text == "Loading..."
    
    if not needsUpdate then
        return
    end
    lastKnownOwnership = ownsVIP
    
    -- Get gamepass info for icon and price
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(GAMEPASS_ID, Enum.InfoType.GamePass)
    end)
    
    -- Update icon if we have it
    if iconLabel and success and info and info.IconImageAssetId then
        iconLabel.Image = "rbxassetid://" .. tostring(info.IconImageAssetId)
    end
    
    if ownsVIP then
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
    
    -- Prompt the purchase
    local success, error = pcall(function()
        MarketplaceService:PromptGamePassPurchase(player, GAMEPASS_ID)
    end)
    
    if not success then
        warn("VIPButtonService: Failed to prompt gamepass purchase:", error)
    end
end

function VIPButtonService:SetupDataSubscription()
    -- Subscribe to data changes to update GUI
    DataSyncService:Subscribe(function(newState)
        if newState and newState.player then
            local billboard = vipButtonPart and vipButtonPart:FindFirstChild("GamepassBillboard", true)
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

function VIPButtonService:Cleanup()
    if proximityConnection then
        proximityConnection:Disconnect()
        proximityConnection = nil
    end
    
    lastKnownOwnership = nil
    print("VIPButtonService: Cleaned up")
end

-- Handle character respawn
Players.LocalPlayer.CharacterAdded:Connect(function()
    -- Re-initialize after character respawn
    VIPButtonService:Cleanup()
    task.wait(1) -- Wait for character to fully load
    VIPButtonService:Initialize()
end)

return VIPButtonService