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
    
    -- GUI already exists from AreaTemplate (skip creation for performance)
end

function SendHeavenButtonService:FindSendHeavenButton()
    -- Wait for character to spawn
    if not player.Character then
        player.CharacterAdded:Wait()
    end
    
    -- Use event-based waiting instead of hardcoded delay
    
    -- Find player's area
    local playerAreas = game.Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then
        warn("SendHeavenButtonService: PlayerAreas not found")
        return
    end
    
    print("SendHeavenButtonService: Found PlayerAreas, looking for player's area...")
    
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
                        print("SendHeavenButtonService: Found player's area:", area.Name)
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
    
    print("SendHeavenButtonService: Found SendHeaven button")
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
    
    -- Clean up existing GUIs (only our specific one)
    local existingBillboard = sendHeavenButtonPart:FindFirstChild("SendHeavenInstructionBillboard", true)
    if existingBillboard then
        existingBillboard:Destroy()
    end
    
    -- Create BillboardGui for instruction text (floating above button)
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "SendHeavenInstructionBillboard"
    billboardGui.Size = UDim2.new(0, 150, 0, 80) -- Compact size to match other buttons
    billboardGui.StudsOffset = Vector3.new(0, 5, 0) -- Float 5 studs above the part
    billboardGui.MaxDistance = 80 -- Much further visibility for camera angles
    billboardGui.Parent = targetPart
    
    -- Create instruction text label
    local instructionLabel = Instance.new("TextLabel")
    instructionLabel.Name = "InstructionText"
    instructionLabel.Size = UDim2.new(1, 0, 1, 0)
    instructionLabel.BackgroundTransparency = 1
    instructionLabel.Font = Enum.Font.GothamBold
    instructionLabel.Text = "Send pets to\nheaven here!"
    instructionLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold color to match heaven theme
    instructionLabel.TextSize = 20 -- Match other button text sizes
    instructionLabel.TextStrokeTransparency = 0
    instructionLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    instructionLabel.Parent = billboardGui
    
    print("SendHeavenButtonService: Created instruction GUI over SendHeaven button")
end

-- Handle character respawn
Players.LocalPlayer.CharacterAdded:Connect(function()
    -- Re-initialize after character respawn
    task.wait(1) -- Wait for character to fully load
    SendHeavenButtonService:Initialize()
end)

return SendHeavenButtonService