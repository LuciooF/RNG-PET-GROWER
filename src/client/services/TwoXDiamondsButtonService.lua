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

-- Configuration
local GAMEPASS_ID = 1351480418
local INTERACTION_DISTANCE = 10 -- Distance in studs to trigger interaction
local PURCHASE_COOLDOWN = 3 -- Seconds between purchase attempts

-- Cooldown tracking
local lastPurchaseAttempt = 0

-- State tracking to prevent unnecessary updates
local lastKnownOwnership = nil

function TwoXDiamondsButtonService:Initialize()
    -- Find the 2x Diamonds button in the player's area
    self:FindTwoXDiamondsButton()
    
    -- Set up proximity detection
    if twoXDiamondsButtonPart then
        self:SetupProximityDetection()
    end
    
    -- Set up data subscription for visibility updates
    self:SetupDataSubscription()
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
        print("TwoXDiamondsButtonService: Found 2xDiamondsButton")
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
    
    print("TwoXDiamondsButtonService: Player owns gamepass:", ownsGamepass)
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
        print("TwoXDiamondsButtonService: Player already owns 2x Diamonds gamepass")
        return
    end
    
    print("TwoXDiamondsButtonService: Prompting 2x Diamonds gamepass purchase")
    
    -- Prompt the purchase
    local success, error = pcall(function()
        MarketplaceService:PromptGamePassPurchase(player, GAMEPASS_ID)
    end)
    
    if not success then
        warn("TwoXDiamondsButtonService: Failed to prompt gamepass purchase:", error)
    end
end

function TwoXDiamondsButtonService:SetupDataSubscription()
    -- Subscribe to data changes to update GUI
    local unsubscribe = DataSyncService:Subscribe(function(newState)
        if newState and newState.player then
            self:UpdateGamepassGUI()
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
    print("TwoXDiamondsButtonService: Cleaned up")
end

-- Handle character respawn
Players.LocalPlayer.CharacterAdded:Connect(function()
    -- Re-initialize after character respawn
    TwoXDiamondsButtonService:Cleanup()
    task.wait(1) -- Wait for character to fully load
    TwoXDiamondsButtonService:Initialize()
end)

return TwoXDiamondsButtonService