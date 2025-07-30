-- AutoHeavenService - Handles automatic heaven processing for AutoHeaven gamepass
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DataSyncService = require(script.Parent.DataSyncService)
local GamepassConfig = require(ReplicatedStorage.config.GamepassConfig)
local PlayerAreaFinder = require(script.Parent.Parent.utils.PlayerAreaFinder)

local AutoHeavenService = {}
AutoHeavenService.__index = AutoHeavenService

local player = Players.LocalPlayer
local autoHeavenConnection = nil
local countdownConnection = nil
local countdownGui = nil

-- Configuration
local autoHeavenBenefits = GamepassConfig.getBenefits("AutoHeaven")
local PROCESS_INTERVAL = autoHeavenBenefits and autoHeavenBenefits.processInterval or 30

-- Timer state
local nextProcessTime = 0
local isAutoHeavenEnabled = false

function AutoHeavenService:Initialize()
    -- Subscribe to player data changes to check gamepass ownership
    self:SetupDataSubscription()
end

function AutoHeavenService:SetupDataSubscription()
    -- Subscribe to data changes to check gamepass ownership and settings
    local unsubscribe = DataSyncService:Subscribe(function(newState)
        if newState.player then
            self:UpdateAutoHeavenStatus(newState.player)
        end
    end)
    
    -- Also check initial data
    local initialData = DataSyncService:GetPlayerData()
    if initialData then
        self:UpdateAutoHeavenStatus(initialData)
    end
    
    -- Store unsubscribe function for cleanup
    self.dataSubscription = unsubscribe
end

-- Update auto heaven status based on gamepass ownership and settings
function AutoHeavenService:UpdateAutoHeavenStatus(playerData)
    local ownsAutoHeaven = self:PlayerOwnsAutoHeaven(playerData)
    local autoHeavenEnabled = playerData.GamepassSettings and playerData.GamepassSettings.AutoHeavenEnabled
    
    if ownsAutoHeaven and autoHeavenEnabled and not autoHeavenConnection then
        -- Start auto heaven
        self:StartAutoHeaven()
        print("AutoHeavenService: Started auto heaven")
    elseif (not ownsAutoHeaven or not autoHeavenEnabled) and autoHeavenConnection then
        -- Stop auto heaven
        self:StopAutoHeaven()
        print("AutoHeavenService: Stopped auto heaven")
    end
    
    -- Update countdown GUI visibility
    if ownsAutoHeaven then
        self:CreateCountdownGUI()
    else
        self:RemoveCountdownGUI()
    end
end

-- Check if player owns AutoHeaven gamepass
function AutoHeavenService:PlayerOwnsAutoHeaven(playerData)
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

-- Start the auto heaven functionality
function AutoHeavenService:StartAutoHeaven()
    if autoHeavenConnection then
        return -- Already running
    end
    
    -- Set initial next process time
    nextProcessTime = tick() + PROCESS_INTERVAL
    
    autoHeavenConnection = RunService.Heartbeat:Connect(function()
        self:UpdateAutoHeaven()
    end)
end

-- Stop the auto heaven functionality
function AutoHeavenService:StopAutoHeaven()
    if autoHeavenConnection then
        autoHeavenConnection:Disconnect()
        autoHeavenConnection = nil
    end
end

-- Update auto heaven - check if it's time to process
function AutoHeavenService:UpdateAutoHeaven()
    local currentTime = tick()
    
    if currentTime >= nextProcessTime then
        -- Time to process!
        self:TriggerHeavenProcessing()
        -- Set next process time
        nextProcessTime = currentTime + PROCESS_INTERVAL
    end
end

-- Trigger heaven processing
function AutoHeavenService:TriggerHeavenProcessing()
    local sendToHeavenRemote = ReplicatedStorage:FindFirstChild("SendToHeaven")
    if sendToHeavenRemote then
        sendToHeavenRemote:FireServer()
        print("AutoHeavenService: Auto-triggered heaven processing")
    else
        warn("AutoHeavenService: SendToHeaven remote not found")
    end
end

-- Create countdown GUI over SendHeaven button
function AutoHeavenService:CreateCountdownGUI()
    if countdownGui then
        return -- Already exists
    end
    
    -- Find SendHeaven button in player's area
    local sendHeavenButton = self:FindSendHeavenButton()
    if not sendHeavenButton then
        return
    end
    
    -- Create BillboardGui for countdown
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "AutoHeavenCountdown"
    billboardGui.Size = UDim2.new(0, 200, 0, 80)
    billboardGui.StudsOffset = Vector3.new(0, 8, 0) -- Float above the button
    billboardGui.Parent = sendHeavenButton
    
    -- Create countdown text label
    local countdownLabel = Instance.new("TextLabel")
    countdownLabel.Name = "CountdownText"
    countdownLabel.Size = UDim2.new(1, 0, 1, 0)
    countdownLabel.BackgroundTransparency = 1
    countdownLabel.Font = Enum.Font.GothamBold
    countdownLabel.Text = "Processing in 30s"
    countdownLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold color
    countdownLabel.TextSize = 18
    countdownLabel.TextStrokeTransparency = 0
    countdownLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    countdownLabel.Parent = billboardGui
    
    countdownGui = billboardGui
    
    -- Start countdown update
    self:StartCountdownUpdate()
end

-- Remove countdown GUI
function AutoHeavenService:RemoveCountdownGUI()
    if countdownGui then
        countdownGui:Destroy()
        countdownGui = nil
    end
    
    if countdownConnection then
        countdownConnection:Disconnect()
        countdownConnection = nil
    end
end

-- Start updating countdown display
function AutoHeavenService:StartCountdownUpdate()
    if countdownConnection then
        countdownConnection:Disconnect()
    end
    
    countdownConnection = RunService.Heartbeat:Connect(function()
        self:UpdateCountdownDisplay()
    end)
end

-- Update countdown display
function AutoHeavenService:UpdateCountdownDisplay()
    if not countdownGui then return end
    
    local countdownLabel = countdownGui:FindFirstChild("CountdownText")
    if not countdownLabel then return end
    
    local currentTime = tick()
    local timeLeft = math.max(0, nextProcessTime - currentTime)
    
    local playerData = DataSyncService:GetPlayerData()
    local autoHeavenEnabled = playerData and playerData.GamepassSettings and playerData.GamepassSettings.AutoHeavenEnabled
    
    if not autoHeavenEnabled then
        countdownLabel.Text = "Auto Heaven: OFF"
        countdownLabel.TextColor3 = Color3.fromRGB(150, 150, 150) -- Gray when disabled
    elseif timeLeft > 0 then
        countdownLabel.Text = string.format("Processing in %ds", math.ceil(timeLeft))
        countdownLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold when counting
    else
        countdownLabel.Text = "Processing..."
        countdownLabel.TextColor3 = Color3.fromRGB(0, 255, 0) -- Green when processing
    end
end

-- Find SendHeaven button in player's area
function AutoHeavenService:FindSendHeavenButton()
    local playerAreas = game.Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then return nil end
    
    -- Find the player's assigned area
    for _, area in pairs(playerAreas:GetChildren()) do
        if area.Name:match("PlayerArea") then
            local nameplate = area:FindFirstChild("AreaNameplate")
            if nameplate then
                local billboard = nameplate:FindFirstChild("NameplateBillboard")
                if billboard then
                    local textLabel = billboard:FindFirstChild("TextLabel")
                    if textLabel and textLabel.Text == (player.Name .. "'s Area") then
                        -- Found player's area, look for SendHeaven button
                        local buttonsFolder = area:FindFirstChild("Buttons")
                        if buttonsFolder then
                            return buttonsFolder:FindFirstChild("SendHeaven")
                        end
                    end
                end
            end
        end
    end
    
    return nil
end

-- Toggle auto heaven enabled state
function AutoHeavenService:ToggleAutoHeaven()
    local toggleGamepassSettingRemote = ReplicatedStorage:FindFirstChild("ToggleGamepassSetting")
    if toggleGamepassSettingRemote then
        toggleGamepassSettingRemote:FireServer("AutoHeavenEnabled")
        print("AutoHeavenService: Toggled auto heaven setting")
    else
        warn("AutoHeavenService: ToggleGamepassSetting remote not found")
    end
end

-- Clean up connections
function AutoHeavenService:Cleanup()
    self:StopAutoHeaven()
    self:RemoveCountdownGUI()
    
    if self.dataSubscription then
        self.dataSubscription()
        self.dataSubscription = nil
    end
end

-- Handle character respawn
Players.LocalPlayer.CharacterAdded:Connect(function()
    -- Re-check auto heaven status after respawn
    -- Wait for character and area to fully load handled by PlayerAreaFinder
    local playerData = DataSyncService:GetPlayerData()
    if playerData then
        AutoHeavenService:UpdateAutoHeavenStatus(playerData)
    end
end)

return AutoHeavenService