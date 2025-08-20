-- SendHeavenButtonService - Handles SendHeaven button GUI display
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DataSyncService = require(script.Parent.DataSyncService)

local SendHeavenButtonService = {}
SendHeavenButtonService.__index = SendHeavenButtonService

local player = Players.LocalPlayer
local sendHeavenButtonPart = nil
local processingTextLabel = nil -- Store reference to update processing count
local dataSubscription = nil -- Track data subscription for cleanup

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
    
    -- Use the improved PlayerAreaFinder utility
    local PlayerAreaFinder = require(ReplicatedStorage.utils.PlayerAreaFinder)
    local playerArea = PlayerAreaFinder:WaitForPlayerArea(15)

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
    processorLabel.Size = UDim2.new(0, 80, 0.5, 0) -- Half height for first line
    processorLabel.Position = UDim2.new(0, 40, 0, 0) -- Right next to icon, top half
    processorLabel.BackgroundTransparency = 1
    processorLabel.Font = Enum.Font.FredokaOne
    processorLabel.Text = "Processor!"
    processorLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold color to match heaven theme
    processorLabel.TextSize = 18 -- Slightly smaller to fit both lines
    processorLabel.TextStrokeTransparency = 0
    processorLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    processorLabel.TextXAlignment = Enum.TextXAlignment.Left
    processorLabel.TextYAlignment = Enum.TextYAlignment.Center
    processorLabel.Parent = container
    
    -- Create processing count label (second line)
    local processingLabel = Instance.new("TextLabel")
    processingLabel.Name = "ProcessingText"
    processingLabel.Size = UDim2.new(0, 80, 0.5, 0) -- Half height for second line
    processingLabel.Position = UDim2.new(0, 40, 0.5, 0) -- Right next to icon, bottom half
    processingLabel.BackgroundTransparency = 1
    processingLabel.Font = Enum.Font.FredokaOne
    processingLabel.Text = "Processing: 0 pets!" -- Default text, will be updated dynamically
    processingLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green color for processing status
    processingLabel.TextSize = 16 -- Smaller text for secondary info
    processingLabel.TextStrokeTransparency = 0
    processingLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    processingLabel.TextXAlignment = Enum.TextXAlignment.Left
    processingLabel.TextYAlignment = Enum.TextYAlignment.Center
    processingLabel.Parent = container
    
    -- Store reference for dynamic updates
    processingTextLabel = processingLabel
    
    -- Set up data subscription to monitor processing pets
    self:SetupProcessingMonitor()
    
end

-- Set up monitoring for processing pets count changes
function SendHeavenButtonService:SetupProcessingMonitor()
    -- Get initial processing count
    local initialData = DataSyncService:GetPlayerData()
    if initialData and initialData.ProcessingPets then
        self:UpdateProcessingCount(#initialData.ProcessingPets)
    end
    
    -- Subscribe to data changes to update processing count
    dataSubscription = DataSyncService:Subscribe(function(newState)
        if newState and newState.player and newState.player.ProcessingPets then
            local processingCount = #newState.player.ProcessingPets
            self:UpdateProcessingCount(processingCount)
        end
    end)
end

-- Update processing count display
function SendHeavenButtonService:UpdateProcessingCount(processingCount)
    if processingTextLabel then
        processingTextLabel.Text = string.format("Processing: %d pets!", processingCount)
    end
end

-- Cleanup method
function SendHeavenButtonService:Cleanup()
    -- Clean up data subscription
    if dataSubscription and type(dataSubscription) == "function" then
        dataSubscription()
        dataSubscription = nil
    end
    
    -- Clear references
    sendHeavenButtonPart = nil
    processingTextLabel = nil
end

-- Handle character respawn
Players.LocalPlayer.CharacterAdded:Connect(function()
    -- Re-initialize after character respawn
    task.wait(1) -- Wait for character to fully load
    SendHeavenButtonService:Initialize()
end)

return SendHeavenButtonService