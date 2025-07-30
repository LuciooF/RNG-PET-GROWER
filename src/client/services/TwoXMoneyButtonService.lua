-- TwoXMoneyButtonService - Handles physical 2x Money button interaction
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local DataSyncService = require(script.Parent.DataSyncService)

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
    
    -- Set up proximity detection
    if twoXMoneyButtonPart then
        self:SetupProximityDetection()
    end
    
    -- Set up data subscription for visibility updates
    self:SetupDataSubscription()
end

function TwoXMoneyButtonService:FindTwoXMoneyButton()
    -- Wait for character to spawn
    if not player.Character then
        player.CharacterAdded:Wait()
    end
    
    -- Use event-based waiting instead of hardcoded delay
    
    -- Find player's area
    local playerAreas = game.Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then
        warn("TwoXMoneyButtonService: PlayerAreas not found")
        return
    end
    
    print("TwoXMoneyButtonService: Found PlayerAreas, looking for player's area...")
    
    -- Find the player's assigned area by checking the area nameplate
    local playerArea = nil
    for _, area in pairs(playerAreas:GetChildren()) do
        if area.Name:match("PlayerArea") then
            local nameplate = area:FindFirstChild("AreaNameplate")
            if nameplate then
                local billboard = nameplate:FindFirstChild("NameplateBillboard")
                if billboard then
                    local textLabel = billboard:FindFirstChild("TextLabel")
                    if textLabel and textLabel.Text == (player.Name .. "'s Area") then
                        playerArea = area
                        print("TwoXMoneyButtonService: Found player's area:", area.Name)
                        break
                    end
                end
            end
        end
    end
    
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
        print("TwoXMoneyButtonService: Found 2xMoneyButton")
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
    local DataSyncService = require(script.Parent.DataSyncService)
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
    
    -- Get template labels
    local titleLabel = billboard:FindFirstChild("TitleLabel")
    local descriptionLabel = billboard:FindFirstChild("DescriptionLabel")
    local ownedLabel = billboard:FindFirstChild("OwnedLabel")
    
    if ownsGamepass then
        -- Show owned state: hide title+description, show owned label
        if titleLabel then titleLabel.Visible = false end
        if descriptionLabel then descriptionLabel.Visible = false end
        if ownedLabel then ownedLabel.Visible = true end
    else
        -- Show purchase state: show title+description, hide owned label
        if titleLabel then titleLabel.Visible = true end
        if descriptionLabel then descriptionLabel.Visible = true end
        if ownedLabel then ownedLabel.Visible = false end
    end
    
    print("TwoXMoneyButtonService: Player owns gamepass:", ownsGamepass)
end

function TwoXMoneyButtonService:CreateGamepassGUI_OLD()
    -- Find the best part to attach GUI to
    local targetPart = nil
    if twoXMoneyButtonPart:IsA("Model") then
        -- Look for a suitable part in the model
        for _, part in pairs(twoXMoneyButtonPart:GetDescendants()) do
            if part:IsA("BasePart") then
                targetPart = part
                break
            end
        end
    else
        targetPart = twoXMoneyButtonPart
    end
    
    if not targetPart then
        warn("TwoXMoneyButtonService: No suitable part found for GUI attachment")
        return
    end
    
    -- Clean up existing GUIs
    local existingBillboard = twoXMoneyButtonPart:FindFirstChild("GamepassBillboard", true)
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
    gamepassLabel.Text = "2x Money"
    gamepassLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold color
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

function TwoXMoneyButtonService:UpdateGamepassStatus(statusLabel, iconLabel)
    if not statusLabel then return end
    
    local playerData = DataSyncService:GetPlayerData()
    local owns2xMoney = playerData and playerData.OwnedGamepasses and table.find(playerData.OwnedGamepasses, "TwoXMoney")
    
    -- Check if we need to update (ownership changed or still showing Loading...)
    local needsUpdate = lastKnownOwnership ~= owns2xMoney or statusLabel.Text == "Loading..."
    
    if not needsUpdate then
        return
    end
    lastKnownOwnership = owns2xMoney
    
    -- Get gamepass info for icon and price
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(GAMEPASS_ID, Enum.InfoType.GamePass)
    end)
    
    -- Update icon if we have it
    if iconLabel and success and info and info.IconImageAssetId then
        iconLabel.Image = "rbxassetid://" .. tostring(info.IconImageAssetId)
    end
    
    if owns2xMoney then
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

function TwoXMoneyButtonService:SetupProximityDetection()
    -- Get button position for distance calculation
    local buttonPosition
    if twoXMoneyButtonPart:IsA("Model") then
        local cframe, size = twoXMoneyButtonPart:GetBoundingBox()
        buttonPosition = cframe.Position
    else
        buttonPosition = twoXMoneyButtonPart.Position
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
    if twoXMoneyButtonPart:IsA("Model") then
        for _, part in pairs(twoXMoneyButtonPart:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Touched:Connect(onTouch)
            end
        end
    elseif twoXMoneyButtonPart:IsA("BasePart") then
        twoXMoneyButtonPart.Touched:Connect(onTouch)
    end
end


function TwoXMoneyButtonService:HandleGamepassPurchase()
    -- Check cooldown
    local currentTime = tick()
    if currentTime - lastPurchaseAttempt < PURCHASE_COOLDOWN then
        return
    end
    lastPurchaseAttempt = currentTime
    
    -- Check if player already owns the gamepass
    local playerData = DataSyncService:GetPlayerData()
    local owns2xMoney = playerData and playerData.OwnedGamepasses and table.find(playerData.OwnedGamepasses, "TwoXMoney")
    
    if owns2xMoney then
        print("TwoXMoneyButtonService: Player already owns 2x Money gamepass")
        return
    end
    
    print("TwoXMoneyButtonService: Prompting 2x Money gamepass purchase")
    
    -- Prompt the purchase
    local success, error = pcall(function()
        MarketplaceService:PromptGamePassPurchase(player, GAMEPASS_ID)
    end)
    
    if not success then
        warn("TwoXMoneyButtonService: Failed to prompt gamepass purchase:", error)
    end
end

function TwoXMoneyButtonService:SetupDataSubscription()
    -- Subscribe to data changes to update GUI
    DataSyncService:Subscribe(function(newState)
        if newState and newState.player then
            local billboard = twoXMoneyButtonPart and twoXMoneyButtonPart:FindFirstChild("GamepassBillboard", true)
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

function TwoXMoneyButtonService:Cleanup()
    if proximityConnection then
        proximityConnection:Disconnect()
        proximityConnection = nil
    end
    
    lastKnownOwnership = nil
    print("TwoXMoneyButtonService: Cleaned up")
end

-- Handle character respawn
Players.LocalPlayer.CharacterAdded:Connect(function()
    -- Re-initialize after character respawn
    TwoXMoneyButtonService:Cleanup()
    task.wait(1) -- Wait for character to fully load
    TwoXMoneyButtonService:Initialize()
end)

return TwoXMoneyButtonService