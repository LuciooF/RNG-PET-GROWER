-- TeleportService - Handles teleport pad interaction and GUI
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local TeleportService = {}
TeleportService.__index = TeleportService

local player = Players.LocalPlayer
local teleportPart = nil

-- Configuration
local TELEPORT_REBIRTH_REQUIREMENT = 30
local TOUCH_COOLDOWN = 3 -- 3 seconds between touch messages

-- Touch cooldown tracking
local lastTouchTime = 0

function TeleportService:Initialize()
    -- Find the teleport pad in the player's area
    self:FindTeleportPad()
    
    -- Set up touch detection (GUI already exists from AreaTemplate)
    if teleportPart then
        self:SetupTouchDetection()
    end
end

function TeleportService:FindTeleportPad()
    -- Wait for character to spawn
    if not player.Character then
        player.CharacterAdded:Wait()
    end
    
    -- Use event-based waiting instead of hardcoded delay
    
    -- Find player's area
    local playerAreas = game.Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then
        warn("TeleportService: PlayerAreas not found")
        return
    end
    
    print("TeleportService: Found PlayerAreas, looking for player's area...")
    
    -- Find the player's assigned area by checking the area nameplate
    local playerArea = nil
    for _, area in pairs(playerAreas:GetChildren()) do
        if area.Name:match("PlayerArea") then
            print("TeleportService: Checking area:", area.Name)
            -- Check if this area belongs to the current player by looking at the nameplate
            local nameplate = area:FindFirstChild("AreaNameplate")
            if nameplate then
                print("TeleportService: Found nameplate in", area.Name)
                local billboard = nameplate:FindFirstChild("NameplateBillboard")
                if billboard then
                    local textLabel = billboard:FindFirstChild("TextLabel")
                    if textLabel then
                        print("TeleportService: Nameplate text:", textLabel.Text, "Looking for:", player.Name .. "'s Area")
                        if textLabel.Text == (player.Name .. "'s Area") then
                            playerArea = area
                            print("TeleportService: Found player's area:", area.Name)
                            break
                        end
                    end
                end
            else
                print("TeleportService: No nameplate found in", area.Name)
            end
        end
    end
    
    if not playerArea then
        warn("TeleportService: Player area not found")
        return
    end
    
    -- Find the Teleport model
    teleportPart = playerArea:FindFirstChild("Teleport")
    if not teleportPart then
        warn("TeleportService: Teleport model not found in player area")
        return
    end
    
    print("TeleportService: Found Teleport model:", teleportPart.Name)
end

function TeleportService:CreateTeleportGUI()
    if not teleportPart then return end
    
    -- Find Cube.018 inside the Teleport model
    local targetPart = teleportPart:FindFirstChild("Cube.018")
    if not targetPart then
        warn("TeleportService: Cube.018 not found in Teleport model")
        return
    end
    
    -- Clean up existing GUI
    local existingSurface = teleportPart:FindFirstChild("TeleportRequirementGui", true)
    if existingSurface then
        existingSurface:Destroy()
    end
    
    -- Put GUI on multiple faces to ensure it's visible from different angles
    local faces = {Enum.NormalId.Front, Enum.NormalId.Top, Enum.NormalId.Back}
    
    for _, face in ipairs(faces) do
        -- Create SurfaceGui for requirement text
        local surfaceGui = Instance.new("SurfaceGui")
        surfaceGui.Name = "TeleportRequirementGui_" .. face.Name
        surfaceGui.Face = face
        surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        surfaceGui.PixelsPerStud = 100 -- Doubled from 50 to make it bigger
        surfaceGui.Parent = targetPart
        
        -- Create requirement text label with high contrast
        local requirementLabel = Instance.new("TextLabel")
        requirementLabel.Name = "RequirementText"
        requirementLabel.Size = UDim2.new(1, 0, 1, 0)
        requirementLabel.Position = UDim2.new(0, 0, 0, 0)
        requirementLabel.BackgroundTransparency = 1 -- No background
        requirementLabel.Font = Enum.Font.GothamBold
        requirementLabel.Text = "Unlocks at\n" .. TELEPORT_REBIRTH_REQUIREMENT .. " rebirths!"
        requirementLabel.TextColor3 = Color3.fromRGB(255, 255, 0) -- Bright yellow for high contrast on purple
        requirementLabel.TextScaled = true -- Scale text to fit the GUI size
        requirementLabel.TextStrokeTransparency = 0
        requirementLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0) -- Black stroke for extra contrast
        requirementLabel.TextXAlignment = Enum.TextXAlignment.Center
        requirementLabel.TextYAlignment = Enum.TextYAlignment.Center
        requirementLabel.Parent = surfaceGui
        
        print("TeleportService: Created teleport requirement GUI on", face.Name, "face")
    end
    
    print("TeleportService: Created teleport requirement GUI")
end

function TeleportService:SetupTouchDetection()
    if not teleportPart then return end
    
    print("TeleportService: Setting up touch detection for teleport")
    
    -- Set up touch detection for the teleport model (handle Model with multiple parts)
    local function onTouch(hit)
        print("TeleportService: Touch detected on teleport part by:", hit.Parent.Name)
        local character = hit.Parent
        if character == player.Character then
            print("TeleportService: Touch confirmed from player character")
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                print("TeleportService: Humanoid found, checking cooldown")
                -- Check cooldown to prevent spam
                local currentTime = tick()
                if currentTime - lastTouchTime >= TOUCH_COOLDOWN then
                    lastTouchTime = currentTime
                    print("TeleportService: Cooldown passed, showing message")
                    -- Show requirement message
                    self:ShowRequirementMessage()
                else
                    print("TeleportService: Still in cooldown, ignoring touch")
                end
            end
        end
    end
    
    -- Connect to all parts in the Teleport model
    if teleportPart:IsA("Model") then
        for _, part in pairs(teleportPart:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Touched:Connect(onTouch)
            end
        end
    elseif teleportPart:IsA("BasePart") then
        teleportPart.Touched:Connect(onTouch)
    end
    
    print("TeleportService: Touch detection setup complete")
end

-- Show the requirement message to the player
function TeleportService:ShowRequirementMessage()
    -- Get the error message remote event (should exist from Main.server.lua)
    local errorMessageRemote = ReplicatedStorage:FindFirstChild("ShowErrorMessage")
    if errorMessageRemote then
        local message = "Next Area will be unlocked at " .. TELEPORT_REBIRTH_REQUIREMENT .. " rebirths!"
        -- Fire to server, which will fire back to client
        errorMessageRemote:FireServer(message)
        print("TeleportService: Sent teleport requirement message to server")
    else
        warn("TeleportService: ShowErrorMessage remote event not found!")
        -- Fallback: just print to console
        print("Next Area will be unlocked at " .. TELEPORT_REBIRTH_REQUIREMENT .. " rebirths!")
    end
end

-- Clean up (for character respawn)
function TeleportService:Cleanup()
    teleportPart = nil
end

-- Handle character respawn
Players.LocalPlayer.CharacterAdded:Connect(function()
    -- Re-initialize after character respawn
    TeleportService:Cleanup()
    task.wait(1) -- Wait for character to fully load
    TeleportService:Initialize()
end)

return TeleportService