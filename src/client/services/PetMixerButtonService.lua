-- PetMixerButtonService - Handles physical mixer button interactions
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PetMixerButtonService = {}
PetMixerButtonService.__index = PetMixerButtonService

local player = Players.LocalPlayer
local mixerConnections = {}
local proximityCheckConnections = {}
local activeMixers = {} -- Track which mixers are active
local mixerUIStates = {} -- Track UI open state per mixer

-- Configuration
local INTERACTION_DISTANCE = 15 -- Distance in studs to trigger interaction

-- Callbacks for UI control
local onMixerOpen = nil
local onMixerClose = nil

function PetMixerButtonService:Initialize()
    -- Find all mixer buttons in the player's area
    self:FindMixerButtons()
end

function PetMixerButtonService:FindMixerButtons()
    -- Wait for character to spawn
    if not player.Character then
        player.CharacterAdded:Wait()
    end
    
    -- Wait for PlayerAreas to exist, then find player's area
    local playerAreas = game.Workspace:WaitForChild("PlayerAreas", 10)
    if not playerAreas then
        warn("PetMixerButtonService: PlayerAreas not found")
        return
    end
    
    -- Wait for player's area to be assigned (event-based instead of delay-based)
    local playerArea = nil
    local function findPlayerArea()
        for _, area in pairs(playerAreas:GetChildren()) do
            if area.Name:match("PlayerArea") then
                local nameplate = area:FindFirstChild("AreaNameplate")
                if nameplate then
                    local billboard = nameplate:FindFirstChild("NameplateBillboard")
                    if billboard then
                        local textLabel = billboard:FindFirstChild("TextLabel")
                        if textLabel and textLabel.Text == (player.Name .. "'s Area") then
                            return area
                        end
                    end
                end
            end
        end
        return nil
    end
    
    -- Try to find area immediately
    playerArea = findPlayerArea()
    
    -- If not found, wait for area assignments to be updated
    if not playerArea then
        local connection
        connection = playerAreas.ChildAdded:Connect(function()
            playerArea = findPlayerArea()
            if playerArea then
                connection:Disconnect()
            end
        end)
        
        -- Also check for nameplate updates
        local nameplateConnection
        nameplateConnection = playerAreas.DescendantAdded:Connect(function(descendant)
            if descendant.Name == "AreaNameplate" then
                task.wait(0.1) -- Small delay for nameplate to be fully set up
                playerArea = findPlayerArea()
                if playerArea then
                    nameplateConnection:Disconnect()
                end
            end
        end)
        
        -- Wait with timeout
        local attempts = 0
        while not playerArea and attempts < 100 do -- 10 second timeout
            task.wait(0.1)
            attempts = attempts + 1
            playerArea = findPlayerArea()
        end
        
        -- Clean up connections
        if connection then connection:Disconnect() end
        if nameplateConnection then nameplateConnection:Disconnect() end
    end
    
    if not playerArea then
        warn("PetMixerButtonService: Player area not found")
        return
    end
    
    -- Find the Buttons folder
    local buttonsFolder = playerArea:FindFirstChild("Buttons")
    if not buttonsFolder then
        warn("PetMixerButtonService: Buttons folder not found")
        return
    end
    
    -- Look for mixer buttons (Mixer1Button, Mixer2Button, etc.)
    for _, child in pairs(buttonsFolder:GetChildren()) do
        if child.Name:match("^Mixer%dButton$") then -- Matches Mixer1Button, Mixer2Button, etc.
            local mixerNumber = tonumber(child.Name:match("Mixer(%d)Button"))
            if mixerNumber then
                self:SetupMixerButton(child, mixerNumber)
                print("PetMixerButtonService: Set up", child.Name)
            end
        end
    end
end

function PetMixerButtonService:SetupMixerButton(mixerButtonPart, mixerNumber)
    -- Create GUI for the mixer button
    self:CreateMixerButtonGUI(mixerButtonPart, mixerNumber)
    
    -- Set up proximity detection
    self:SetupProximityDetection(mixerButtonPart, mixerNumber)
end

function PetMixerButtonService:CreateMixerButtonGUI(mixerButtonPart, mixerNumber)
    -- Find the best part to attach GUI to
    local targetPart = nil
    if mixerButtonPart:IsA("Model") then
        -- Look for a suitable part in the model
        for _, part in pairs(mixerButtonPart:GetDescendants()) do
            if part:IsA("BasePart") then
                targetPart = part
                break
            end
        end
    else
        targetPart = mixerButtonPart
    end
    
    if not targetPart then
        warn("PetMixerButtonService: No suitable part found for GUI attachment")
        return
    end
    
    -- Clean up existing GUIs
    local existingBillboard = mixerButtonPart:FindFirstChild("MixerBillboard", true)
    if existingBillboard then
        existingBillboard:Destroy()
    end
    
    -- Create BillboardGui for "Pet Mixer #" text
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "MixerBillboard"
    billboardGui.Size = UDim2.new(0, 150, 0, 80)
    billboardGui.StudsOffset = Vector3.new(0, 5, 0) -- Float 5 studs above the part
    billboardGui.MaxDistance = 80 -- Much further visibility for camera angles
    billboardGui.Parent = targetPart
    
    -- Create mixer label
    local mixerLabel = Instance.new("TextLabel")
    mixerLabel.Name = "MixerText"
    mixerLabel.Size = UDim2.new(1, 0, 1, 0)
    mixerLabel.BackgroundTransparency = 1
    mixerLabel.Font = Enum.Font.GothamBold
    mixerLabel.Text = "Pet\nMixer " .. mixerNumber
    mixerLabel.TextColor3 = Color3.fromRGB(255, 140, 0) -- Orange color for mixer
    mixerLabel.TextSize = 20
    mixerLabel.TextStrokeTransparency = 0
    mixerLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    mixerLabel.Parent = billboardGui
end

function PetMixerButtonService:SetupProximityDetection(mixerButtonPart, mixerNumber)
    -- Clean up existing connections for this mixer
    if mixerConnections[mixerNumber] then
        mixerConnections[mixerNumber]:Disconnect()
    end
    if proximityCheckConnections[mixerNumber] then
        proximityCheckConnections[mixerNumber]:Disconnect()
    end
    
    -- Initialize UI state for this mixer
    mixerUIStates[mixerNumber] = {
        isNearMixer = false,
        mixerUIOpen = false
    }
    
    -- Get button position for distance calculation
    local buttonPosition
    if mixerButtonPart:IsA("Model") then
        local cframe, size = mixerButtonPart:GetBoundingBox()
        buttonPosition = cframe.Position
    else
        buttonPosition = mixerButtonPart.Position
    end
    
    -- Set up touch detection for the mixer button
    local function onTouch(hit)
        local character = hit.Parent
        if character == player.Character then
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                local distance = (humanoidRootPart.Position - buttonPosition).Magnitude
                local state = mixerUIStates[mixerNumber]
                if distance <= INTERACTION_DISTANCE and not state.mixerUIOpen then
                    state.isNearMixer = true
                    state.mixerUIOpen = true
                    -- Track which mixer is active
                    activeMixers[mixerNumber] = true
                    print("PetMixerButtonService: Opening mixer", mixerNumber, "UI")
                    if onMixerOpen then
                        onMixerOpen(mixerNumber)
                    end
                end
            end
        end
    end
    
    -- Connect to all parts in the mixer button
    if mixerButtonPart:IsA("Model") then
        for _, part in pairs(mixerButtonPart:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Touched:Connect(onTouch)
            end
        end
    elseif mixerButtonPart:IsA("BasePart") then
        mixerConnections[mixerNumber] = mixerButtonPart.Touched:Connect(onTouch)
    end
    
    -- Set up continuous proximity checking while UI is open
    proximityCheckConnections[mixerNumber] = RunService.Heartbeat:Connect(function()
        local state = mixerUIStates[mixerNumber]
        if state and state.mixerUIOpen and player.Character then
            local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                local distance = (humanoidRootPart.Position - buttonPosition).Magnitude
                if distance > INTERACTION_DISTANCE then
                    state.isNearMixer = false
                    state.mixerUIOpen = false
                    activeMixers[mixerNumber] = nil
                    print("PetMixerButtonService: Closing mixer", mixerNumber, "UI (distance:", distance, ")")
                    if onMixerClose then
                        onMixerClose(mixerNumber)
                    end
                end
            else
                -- If character is missing, close UI
                state.isNearMixer = false
                state.mixerUIOpen = false
                activeMixers[mixerNumber] = nil
                print("PetMixerButtonService: Closing mixer", mixerNumber, "UI (no character)")
                if onMixerClose then
                    onMixerClose(mixerNumber)
                end
            end
        end
    end)
end

-- Set callback for when mixer should open UI
function PetMixerButtonService:SetOpenCallback(callback)
    onMixerOpen = callback
end

-- Set callback for when mixer should close UI
function PetMixerButtonService:SetCloseCallback(callback)
    onMixerClose = callback
end

-- Get currently active mixer number
function PetMixerButtonService:GetActiveMixer()
    for mixerNumber, _ in pairs(activeMixers) do
        return mixerNumber -- Return first active mixer
    end
    return nil
end

-- Force close UI for a specific mixer (useful for external cleanup)
function PetMixerButtonService:ForceCloseMixer(mixerNumber)
    local state = mixerUIStates[mixerNumber]
    if state and state.mixerUIOpen then
        state.isNearMixer = false
        state.mixerUIOpen = false
        activeMixers[mixerNumber] = nil
        print("PetMixerButtonService: Force closing mixer", mixerNumber, "UI")
        if onMixerClose then
            onMixerClose(mixerNumber)
        end
    end
end

-- Clean up connections
function PetMixerButtonService:Cleanup()
    for mixerNumber, connection in pairs(mixerConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    mixerConnections = {}
    
    for mixerNumber, connection in pairs(proximityCheckConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    proximityCheckConnections = {}
    
    activeMixers = {}
    mixerUIStates = {}
    print("PetMixerButtonService: Cleaned up all mixer states")
end

-- Handle character respawn
Players.LocalPlayer.CharacterAdded:Connect(function()
    -- Re-initialize after character respawn
    PetMixerButtonService:Cleanup()
    task.wait(1) -- Wait for character to fully load
    PetMixerButtonService:Initialize()
end)

return PetMixerButtonService