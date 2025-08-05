-- SendHeavenButtonService - Handles SendHeaven button GUI display
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SendHeavenButtonService = {}
SendHeavenButtonService.__index = SendHeavenButtonService

local player = Players.LocalPlayer
local sendHeavenButtonPart = nil

function SendHeavenButtonService:Initialize()
    -- Find the SendHeaven button in the player's area
    self:FindSendHeavenButton()
    
    -- Create GUI for send heaven button
    if sendHeavenButtonPart then
        self:CreateSendHeavenButtonGUI()
    end
end

function SendHeavenButtonService:FindSendHeavenButton()
    -- Wait for character to spawn
    if not player.Character then
        player.CharacterAdded:Wait()
    end
    
    -- Find player's area
    local playerAreas = game.Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then
        warn("SendHeavenButtonService: PlayerAreas not found")
        return
    end
    
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
                        break
                    end
                end
            end
        end
    end
    
    if not playerArea then
        warn("SendHeavenButtonService: Player area not found")
        return
    end
    
    -- Find the SendHeaven button
    local buttonsFolder = playerArea:FindFirstChild("Buttons")
    if not buttonsFolder then
        warn("SendHeavenButtonService: Buttons folder not found")
        return
    end
    
    sendHeavenButtonPart = buttonsFolder:FindFirstChild("SendHeaven")
    if not sendHeavenButtonPart then
        warn("SendHeavenButtonService: SendHeaven button not found")
        return
    end
    
end

function SendHeavenButtonService:CreateSendHeavenButtonGUI()
    if not sendHeavenButtonPart then return end
    
    -- Find the best part to attach GUI to
    local targetPart = nil
    if sendHeavenButtonPart:IsA("Model") then
        -- Look for a suitable part in the model
        for _, part in pairs(sendHeavenButtonPart:GetDescendants()) do
            if part:IsA("BasePart") then
                targetPart = part
                break
            end
        end
    else
        targetPart = sendHeavenButtonPart
    end
    
    if not targetPart then
        warn("SendHeavenButtonService: No suitable part found for GUI attachment")
        return
    end
    
    -- Clean up ALL existing GUIs on the SendHeaven button (more thorough cleanup)
    for _, child in pairs(sendHeavenButtonPart:GetDescendants()) do
        if child:IsA("BillboardGui") or child:IsA("SurfaceGui") then
            child:Destroy()
        end
    end
    
    -- Create BillboardGui for pet icon and processor text (floating above button)
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "SendHeavenInstructionBillboard"
    billboardGui.Size = UDim2.new(0, 120, 0, 60) -- Compact size to match other buttons
    billboardGui.StudsOffset = Vector3.new(0, 5, 0) -- Float 5 studs above the part
    billboardGui.MaxDistance = 80 -- Much further visibility for camera angles
    billboardGui.Parent = targetPart
    
    -- Create container frame for tight icon + text layout
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Position = UDim2.new(0, 0, 0, 0)
    container.Parent = billboardGui
    
    -- Create pet icon (positioned absolutely for tight control)
    local IconAssets = require(ReplicatedStorage.utils.IconAssets)
    local petIcon = Instance.new("ImageLabel")
    petIcon.Name = "PetIcon"
    petIcon.Size = UDim2.new(0, 24, 0, 24)
    petIcon.Position = UDim2.new(0, 10, 0.5, -12) -- Positioned on left side
    petIcon.BackgroundTransparency = 1
    petIcon.Image = IconAssets.getIcon("UI", "PET")
    petIcon.ScaleType = Enum.ScaleType.Fit
    petIcon.Parent = container
    
    -- Create processor text label (positioned right next to icon)
    local processorLabel = Instance.new("TextLabel")
    processorLabel.Name = "ProcessorText"
    processorLabel.Size = UDim2.new(0, 80, 1, 0) -- Width for "Processor!" text
    processorLabel.Position = UDim2.new(0, 40, 0, 0) -- Right next to icon
    processorLabel.BackgroundTransparency = 1
    processorLabel.Font = Enum.Font.FredokaOne
    processorLabel.Text = "Processor!"
    processorLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold color to match heaven theme
    processorLabel.TextSize = 20 -- Match other button text sizes
    processorLabel.TextStrokeTransparency = 0
    processorLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    processorLabel.TextXAlignment = Enum.TextXAlignment.Left
    processorLabel.TextYAlignment = Enum.TextYAlignment.Center
    processorLabel.Parent = container
    
end

-- Cleanup method (minimal - this service doesn't track much state)
function SendHeavenButtonService:Cleanup()
    -- Nothing to clean up for this simple service
    sendHeavenButtonPart = nil
end

-- Handle character respawn
Players.LocalPlayer.CharacterAdded:Connect(function()
    -- Re-initialize after character respawn
    task.wait(1) -- Wait for character to fully load
    SendHeavenButtonService:Initialize()
end)

return SendHeavenButtonService