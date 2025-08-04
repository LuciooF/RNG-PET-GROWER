-- PetMixerButtonService - Handles physical mixer button interactions
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PetMixerButtonService = {}
PetMixerButtonService.__index = PetMixerButtonService

local player = Players.LocalPlayer
local mixerConnections = {}
local proximityCheckConnections = {}
local dataSubscriptions = {} -- Track data subscriptions per mixer
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
                -- Set up mixer button
            end
        end
    end
end

function PetMixerButtonService:SetupMixerButton(mixerButtonPart, mixerNumber)
    -- Create GUI for the mixer button
    self:CreateMixerButtonGUI(mixerButtonPart, mixerNumber)
    
    -- Set up proximity detection
    self:SetupProximityDetection(mixerButtonPart, mixerNumber)
    
    -- Set up data subscription to update GUI when rebirth count changes
    self:SetupDataSubscription(mixerButtonPart, mixerNumber)
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
    
    -- Paint Cylinder.007 black for Mixer1Button
    if mixerNumber == 1 then
        local cylinder007 = mixerButtonPart:FindFirstChild("Cylinder.007", true)
        if cylinder007 and cylinder007:IsA("BasePart") then
            cylinder007.Color = Color3.fromRGB(0, 0, 0) -- Paint it black
            -- Painted cylinder black
        else
            warn("PetMixerButtonService: Cylinder.007 not found in Mixer1Button")
        end
    end
    
    -- Clean up existing GUIs
    for _, child in pairs(mixerButtonPart:GetDescendants()) do
        if child:IsA("BillboardGui") or child:IsA("SurfaceGui") then
            child:Destroy()
        end
    end
    
    -- Get player data to check rebirth requirement
    local DataSyncService = require(script.Parent.DataSyncService)
    local playerData = DataSyncService:GetPlayerData()
    local rebirthCount = 0
    if playerData and playerData.Resources then
        rebirthCount = playerData.Resources.Rebirths or 0
    end
    
    -- Create BillboardGui for Pet2 icon + "Pet Mixer" text or rebirth requirement
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "MixerBillboard"
    billboardGui.StudsOffset = Vector3.new(0, 5, 0) -- Float 5 studs above the part
    billboardGui.MaxDistance = 80 -- Much further visibility for camera angles
    billboardGui.Parent = targetPart
    
    if rebirthCount < 3 then
        -- Show rebirth requirement
        billboardGui.Size = UDim2.new(0, 140, 0, 80)
        
        -- Create container frame for rebirth requirement layout
        local container = Instance.new("Frame")
        container.Name = "Container"
        container.Size = UDim2.new(1, 0, 1, 0)
        container.BackgroundTransparency = 1
        container.Parent = billboardGui
        
        -- Create rebirth icon
        local IconAssets = require(ReplicatedStorage.utils.IconAssets)
        local rebirthIcon = Instance.new("ImageLabel")
        rebirthIcon.Name = "RebirthIcon"
        rebirthIcon.Size = UDim2.new(0, 24, 0, 24)
        rebirthIcon.Position = UDim2.new(0, 10, 0.5, -12)
        rebirthIcon.BackgroundTransparency = 1
        rebirthIcon.Image = IconAssets.getIcon("UI", "REBIRTH")
        rebirthIcon.ScaleType = Enum.ScaleType.Fit
        rebirthIcon.Parent = container
        
        -- Create requirement text
        local requirementLabel = Instance.new("TextLabel")
        requirementLabel.Name = "RequirementText"
        requirementLabel.Size = UDim2.new(0, 100, 1, 0)
        requirementLabel.Position = UDim2.new(0, 40, 0, 0)
        requirementLabel.BackgroundTransparency = 1
        requirementLabel.Font = Enum.Font.GothamBold
        requirementLabel.Text = "Requires 3\nRebirths"
        requirementLabel.TextColor3 = Color3.fromRGB(255, 0, 0) -- Red for requirement
        requirementLabel.TextSize = 16
        requirementLabel.TextStrokeTransparency = 0
        requirementLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        requirementLabel.TextXAlignment = Enum.TextXAlignment.Left
        requirementLabel.TextYAlignment = Enum.TextYAlignment.Center
        requirementLabel.Parent = container
    else
        -- Show Pet2 icon + "Pet Mixer" text
        billboardGui.Size = UDim2.new(0, 120, 0, 60)
        
        -- Create container frame for icon + text layout
        local container = Instance.new("Frame")
        container.Name = "Container"
        container.Size = UDim2.new(1, 0, 1, 0)
        container.BackgroundTransparency = 1
        container.Parent = billboardGui
        
        -- Create Pet2 icon
        local IconAssets = require(ReplicatedStorage.utils.IconAssets)
        local pet2Icon = Instance.new("ImageLabel")
        pet2Icon.Name = "Pet2Icon"
        pet2Icon.Size = UDim2.new(0, 24, 0, 24)
        pet2Icon.Position = UDim2.new(0, 10, 0.5, -12)
        pet2Icon.BackgroundTransparency = 1
        pet2Icon.Image = IconAssets.getIcon("UI", "PET2")
        pet2Icon.ScaleType = Enum.ScaleType.Fit
        pet2Icon.Parent = container
        
        -- Create "Pet Mixer" text
        local mixerLabel = Instance.new("TextLabel")
        mixerLabel.Name = "MixerText"
        mixerLabel.Size = UDim2.new(0, 80, 1, 0)
        mixerLabel.Position = UDim2.new(0, 40, 0, 0)
        mixerLabel.BackgroundTransparency = 1
        mixerLabel.Font = Enum.Font.GothamBold
        mixerLabel.Text = "Pet Mixer"
        mixerLabel.TextColor3 = Color3.fromRGB(255, 140, 0) -- Orange color for mixer
        mixerLabel.TextSize = 20
        mixerLabel.TextStrokeTransparency = 0
        mixerLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        mixerLabel.TextXAlignment = Enum.TextXAlignment.Left
        mixerLabel.TextYAlignment = Enum.TextYAlignment.Center
        mixerLabel.Parent = container
    end
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
                    -- Check if player has enough rebirths to use mixer
                    local DataSyncService = require(script.Parent.DataSyncService)
                    local playerData = DataSyncService:GetPlayerData()
                    local rebirthCount = 0
                    if playerData and playerData.Resources then
                        rebirthCount = playerData.Resources.Rebirths or 0
                    end
                    
                    if rebirthCount < 3 then
                        -- Show popup message instead of opening UI
                        -- Show unlock requirement
                        self:ShowRebirthRequirementMessage()
                        return
                    end
                    
                    state.isNearMixer = true
                    state.mixerUIOpen = true
                    -- Track which mixer is active
                    activeMixers[mixerNumber] = true
                    -- Open mixer UI
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
                    -- Close mixer UI (distance)
                    if onMixerClose then
                        onMixerClose(mixerNumber)
                    end
                end
            else
                -- If character is missing, close UI
                state.isNearMixer = false
                state.mixerUIOpen = false
                activeMixers[mixerNumber] = nil
                -- Close mixer UI (no character)
                if onMixerClose then
                    onMixerClose(mixerNumber)
                end
            end
        end
    end)
end

-- Set up data subscription to update mixer GUI when rebirth count changes
function PetMixerButtonService:SetupDataSubscription(mixerButtonPart, mixerNumber)
    local DataSyncService = require(script.Parent.DataSyncService)
    
    -- Clean up existing subscription for this mixer
    if dataSubscriptions[mixerNumber] then
        dataSubscriptions[mixerNumber]()
        dataSubscriptions[mixerNumber] = nil
    end
    
    -- Subscribe to data changes to update GUI when rebirth count changes
    local lastRebirthCount = nil
    local unsubscribe = DataSyncService:Subscribe(function(newState)
        if newState.player and newState.player.Resources then
            local currentRebirthCount = newState.player.Resources.Rebirths or 0
            
            -- Only update GUI if rebirth count actually changed
            if lastRebirthCount ~= currentRebirthCount then
                lastRebirthCount = currentRebirthCount
                -- Update GUI for rebirth change
                
                -- Recreate the GUI with updated rebirth check
                self:CreateMixerButtonGUI(mixerButtonPart, mixerNumber)
            end
        end
    end)
    
    -- Store the unsubscribe function
    dataSubscriptions[mixerNumber] = unsubscribe
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
        -- Force close mixer UI
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
    
    -- Clean up data subscriptions
    for mixerNumber, unsubscribe in pairs(dataSubscriptions) do
        if unsubscribe and type(unsubscribe) == "function" then
            unsubscribe()
        end
    end
    dataSubscriptions = {}
    
    activeMixers = {}
    mixerUIStates = {}
    -- Cleaned up mixer states
end

-- Handle character respawn
Players.LocalPlayer.CharacterAdded:Connect(function()
    -- Re-initialize after character respawn
    PetMixerButtonService:Cleanup()
    task.wait(1) -- Wait for character to fully load
    PetMixerButtonService:Initialize()
end)

-- Show popup message when player doesn't have enough rebirths
function PetMixerButtonService:ShowRebirthRequirementMessage()
    -- Use the same error message system as tubes for consistency
    local errorMessageRemote = ReplicatedStorage:FindFirstChild("ShowErrorMessage")
    if errorMessageRemote then
        -- Send requirement message to the centralized error system
        errorMessageRemote:FireServer("Need 3 rebirths to unlock mixer!")
    else
        warn("PetMixerButtonService: ShowErrorMessage remote event not found!")
        -- Fallback to console message
        -- Show unlock requirement locally
    end
end

return PetMixerButtonService