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
    
    -- Add GUI to the button
    self:CreateAutoHeavenButtonGUI()
    
    -- Set initial visibility based on gamepass ownership
    self:UpdateButtonVisibility()
end

function AutoHeavenButtonService:CreateAutoHeavenButtonGUI()
    if not autoHeavenButtonPart then return end
    
    -- Find the best part to attach GUI to
    local targetPart = nil
    if autoHeavenButtonPart:IsA("Model") then
        -- Look for a part with "Platform" or similar in the name, or just use the first BasePart
        for _, part in pairs(autoHeavenButtonPart:GetDescendants()) do
            if part:IsA("BasePart") then
                if part.Name:lower():find("platform") or part.Name:lower():find("base") or part.Name:lower():find("top") then
                    targetPart = part
                    break
                end
            end
        end
        -- Fallback to first BasePart if no specific part found
        if not targetPart then
            for _, part in pairs(autoHeavenButtonPart:GetDescendants()) do
                if part:IsA("BasePart") then
                    targetPart = part
                    break
                end
            end
        end
    else
        targetPart = autoHeavenButtonPart
    end
    
    if not targetPart then
        warn("AutoHeavenButtonService: No suitable part found for GUI attachment")
        return
    end
    
    -- Clean up existing GUIs
    local existingBillboard = autoHeavenButtonPart:FindFirstChild("AutoHeavenBillboard", true)
    if existingBillboard then
        existingBillboard:Destroy()
    end
    
    -- Get player data to check ownership
    local playerData = DataSyncService:GetPlayerData()
    local ownsAutoHeaven = self:PlayerOwnsAutoHeaven(playerData)
    
    -- Create BillboardGui for gamepass info (floating above button)
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "AutoHeavenBillboard"
    billboardGui.Size = UDim2.new(0, 150, 0, 80)
    billboardGui.StudsOffset = Vector3.new(0, 5, 0) -- Float 5 studs above the part
    billboardGui.MaxDistance = 80 -- Much further visibility for camera angles
    billboardGui.Parent = targetPart
    
    if ownsAutoHeaven then
        -- Show simple "OWNED" text when player owns it
        local ownedLabel = Instance.new("TextLabel")
        ownedLabel.Name = "OwnedText"
        ownedLabel.Size = UDim2.new(1, 0, 1, 0)
        ownedLabel.BackgroundTransparency = 1
        ownedLabel.Font = Enum.Font.GothamBold
        ownedLabel.Text = "Auto Heaven\nOWNED"
        ownedLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green
        ownedLabel.TextSize = 20
        ownedLabel.TextStrokeTransparency = 0
        ownedLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        ownedLabel.Parent = billboardGui
    else
        -- Show title and description when not owned
        local autoHeavenLabel = Instance.new("TextLabel")
        autoHeavenLabel.Name = "AutoHeavenText"
        autoHeavenLabel.Size = UDim2.new(1, 0, 0, 30)
        autoHeavenLabel.Position = UDim2.new(0, 0, 0, 0)
        autoHeavenLabel.BackgroundTransparency = 1
        autoHeavenLabel.Font = Enum.Font.GothamBold
        autoHeavenLabel.Text = "Auto Heaven!"
        autoHeavenLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold auto heaven color
        autoHeavenLabel.TextSize = 18
        autoHeavenLabel.TextStrokeTransparency = 0
        autoHeavenLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        autoHeavenLabel.Parent = billboardGui
        
        -- Add description
        local descriptionLabel = Instance.new("TextLabel")
        descriptionLabel.Name = "DescriptionText"
        descriptionLabel.Size = UDim2.new(1, 0, 0, 50)
        descriptionLabel.Position = UDim2.new(0, 0, 0, 30)
        descriptionLabel.BackgroundTransparency = 1
        descriptionLabel.Font = Enum.Font.Gotham
        descriptionLabel.Text = "Auto-send pets every 30s\nwith countdown timer!"
        descriptionLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        descriptionLabel.TextSize = 12
        descriptionLabel.TextWrapped = true
        descriptionLabel.TextStrokeTransparency = 0
        descriptionLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        descriptionLabel.Parent = billboardGui
    end
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
    
    -- Recreate the GUI to reflect the new ownership status
    self:CreateAutoHeavenButtonGUI()
    
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