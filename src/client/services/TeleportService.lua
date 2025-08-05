-- TeleportService - Handles teleport pad interaction and GUI
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local TeleportService = {}
TeleportService.__index = TeleportService

local player = Players.LocalPlayer
local teleportPart = nil

-- Configuration
local TELEPORT_REBIRTH_REQUIREMENT = 20
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
    
    -- Find player's area
    
    -- Find the player's assigned area by checking the area nameplate
    local playerArea = nil
    for _, area in pairs(playerAreas:GetChildren()) do
        if area.Name:match("PlayerArea") then
            -- Check each area for player nameplate
            -- Check if this area belongs to the current player by looking at the nameplate
            local nameplate = area:FindFirstChild("AreaNameplate")
            if nameplate then
                -- Found nameplate, check if it matches player
                local billboard = nameplate:FindFirstChild("NameplateBillboard")
                if billboard then
                    local textLabel = billboard:FindFirstChild("TextLabel")
                    if textLabel then
                        -- Check nameplate text
                        if textLabel.Text == (player.Name .. "'s Area") then
                            playerArea = area
                            -- Found matching player area
                            break
                        end
                    end
                end
            else
                -- No nameplate in this area
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
    
    -- Found teleport part
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
        
        -- Create container frame for icon + text layout
        local container = Instance.new("Frame")
        container.Name = "Container"
        container.Size = UDim2.new(1, 0, 1, 0)
        container.BackgroundTransparency = 1
        container.Parent = surfaceGui
        
        -- Create rebirth icon (wayyy bigger)
        local IconAssets = require(ReplicatedStorage.utils.IconAssets)
        local rebirthIcon = Instance.new("ImageLabel")
        rebirthIcon.Name = "RebirthIcon"
        rebirthIcon.Size = UDim2.new(0, 80, 0, 80) -- Wayyy bigger icon (was 32x32)
        rebirthIcon.Position = UDim2.new(0.5, -40, 0.15, -40) -- Centered horizontally, upper part
        rebirthIcon.BackgroundTransparency = 1
        rebirthIcon.Image = IconAssets.getIcon("UI", "REBIRTH")
        rebirthIcon.ScaleType = Enum.ScaleType.Fit
        rebirthIcon.Parent = container
        
        -- Create requirement text label
        local requirementLabel = Instance.new("TextLabel")
        requirementLabel.Name = "RequirementText"
        requirementLabel.Size = UDim2.new(1, 0, 0.6, 0) -- Lower 60% for text
        requirementLabel.Position = UDim2.new(0, 0, 0.4, 0) -- Below the bigger icon
        requirementLabel.BackgroundTransparency = 1 -- No background
        requirementLabel.Font = Enum.Font.FredokaOne
        requirementLabel.Text = TELEPORT_REBIRTH_REQUIREMENT .. " rebirths\nneeded"
        requirementLabel.TextColor3 = Color3.fromRGB(255, 255, 0) -- Bright yellow for high contrast on purple
        requirementLabel.TextScaled = true -- Scale text to fit the GUI size
        requirementLabel.TextStrokeTransparency = 0
        requirementLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0) -- Black stroke for extra contrast
        requirementLabel.TextXAlignment = Enum.TextXAlignment.Center
        requirementLabel.TextYAlignment = Enum.TextYAlignment.Center
        requirementLabel.Parent = container
        
        -- Created GUI on face
    end
    
    -- GUI creation complete
end

function TeleportService:SetupTouchDetection()
    if not teleportPart then return end
    
    -- Setup touch detection
    
    -- Set up touch detection for the teleport model (handle Model with multiple parts)
    local function onTouch(hit)
        -- Touch detected
        local character = hit.Parent
        if character == player.Character then
            -- Valid player touch
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                -- Check cooldown
                -- Check cooldown to prevent spam
                local currentTime = tick()
                if currentTime - lastTouchTime >= TOUCH_COOLDOWN then
                    lastTouchTime = currentTime
                    -- Cooldown passed, show message
                    -- Show requirement message
                    self:ShowRequirementMessage()
                else
                    -- Still in cooldown
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
    
    -- Touch detection ready
end

-- Show the requirement message to the player
function TeleportService:ShowRequirementMessage()
    -- Get the error message remote event (should exist from Main.server.lua)
    local errorMessageRemote = ReplicatedStorage:FindFirstChild("ShowErrorMessage")
    if errorMessageRemote then
        local message = "Next Area will be unlocked at " .. TELEPORT_REBIRTH_REQUIREMENT .. " rebirths!"
        -- Fire to server, which will fire back to client
        errorMessageRemote:FireServer(message)
        -- Message sent to server
    else
        warn("TeleportService: ShowErrorMessage remote event not found!")
        -- Fallback: just print to console
        -- Show requirement message locally
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