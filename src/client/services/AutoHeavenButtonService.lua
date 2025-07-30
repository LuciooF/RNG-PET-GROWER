-- AutoHeavenButtonService - Handles physical AutoSendHeaven button interaction
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

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
    
    print("AutoHeavenButtonService: Player owns gamepass:", ownsGamepass)
end

-- Set up subscription to player data changes for visibility updates
function AutoHeavenButtonService:SetupDataSubscription()
    -- Subscribe to data changes to check gamepass ownership
    local unsubscribe = DataSyncService:Subscribe(function(newState)
        if newState.player then
            self:UpdateButtonVisibility()
        end
    end)
    
    -- Store unsubscribe function for cleanup
    self.dataSubscription = unsubscribe
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
    
    print("AutoHeavenButtonService: Player owns gamepass:", ownsAutoHeaven)
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
                        print("AutoHeavenButtonService: Purchase cooldown active, wait", math.ceil(timeLeft), "seconds")
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
                        print("AutoHeavenButtonService: Player already owns AutoHeaven gamepass, no purchase needed")
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
        print("AutoHeavenButtonService: Triggered AutoHeaven gamepass purchase")
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
    -- Reset cooldown and state tracking
    lastPurchaseAttempt = 0
    lastKnownOwnership = nil
end

-- Handle character respawn
Players.LocalPlayer.CharacterAdded:Connect(function()
    -- Re-initialize after character respawn
    AutoHeavenButtonService:Cleanup()
    task.wait(1) -- Wait for character to fully load
    AutoHeavenButtonService:Initialize()
end)

return AutoHeavenButtonService