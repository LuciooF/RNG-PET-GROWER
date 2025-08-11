-- RebirthButtonService - Handles physical rebirth button interaction
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local RebirthButtonService = {}
RebirthButtonService.__index = RebirthButtonService

local player = Players.LocalPlayer
local proximityConnection = nil
local proximityCheckConnection = nil
local rebirthButtonPart = nil

-- Configuration
local INTERACTION_DISTANCE = 10 -- Distance in studs to trigger interaction

-- Use shared rebirth cost calculation
local RebirthUtils = require(ReplicatedStorage.utils.RebirthUtils)

-- Callback functions
local onRebirthButtonOpen = nil
local onRebirthButtonClose = nil

-- Progress label reference
RebirthButtonService.progressLabel = nil

function RebirthButtonService:Initialize()
    -- Find the rebirth button in the player's area
    self:FindRebirthButton()
    
    -- Set up proximity detection
    if rebirthButtonPart then
        self:SetupProximityDetection()
    end
    
    -- Set up data subscription for progress updates
    self:SetupDataSubscription()
end

function RebirthButtonService:FindRebirthButton()
    -- Wait for character to spawn
    if not player.Character then
        player.CharacterAdded:Wait()
    end
    
    -- Use the improved PlayerAreaFinder utility
    local PlayerAreaFinder = require(ReplicatedStorage.utils.PlayerAreaFinder)
    local playerArea = PlayerAreaFinder:WaitForPlayerArea(15)
    
    if not playerArea then
        warn("RebirthButtonService: Player area not found")
        return
    end
    
    -- Find the rebirth button
    local buttonsFolder = playerArea:FindFirstChild("Buttons")
    if not buttonsFolder then
        warn("RebirthButtonService: Buttons folder not found")
        return
    end
    
    rebirthButtonPart = buttonsFolder:FindFirstChild("RebirthButton")
    if not rebirthButtonPart then
        warn("RebirthButtonService: RebirthButton not found")
        return
    end
    
    -- Add SurfaceGui if it doesn't exist
    self:CreateRebirthButtonGUI()
end

function RebirthButtonService:CreateRebirthButtonGUI()
    if not rebirthButtonPart then return end
    
    -- Find the best part to attach GUI to
    local targetPart = nil
    if rebirthButtonPart:IsA("Model") then
        -- Look for a part with "Platform" or similar in the name, or just use the first BasePart
        for _, part in pairs(rebirthButtonPart:GetDescendants()) do
            if part:IsA("BasePart") then
                if part.Name:lower():find("platform") or part.Name:lower():find("base") or part.Name:lower():find("top") then
                    targetPart = part
                    break
                end
            end
        end
        -- Fallback to first BasePart if no specific part found
        if not targetPart then
            for _, part in pairs(rebirthButtonPart:GetDescendants()) do
                if part:IsA("BasePart") then
                    targetPart = part
                    break
                end
            end
        end
    else
        targetPart = rebirthButtonPart
    end
    
    if not targetPart then
        warn("RebirthButtonService: No suitable part found for GUI attachment")
        return
    end
    
    -- Clean up existing GUIs
    local existingBillboard = rebirthButtonPart:FindFirstChild("RebirthBillboard", true)
    if existingBillboard then
        existingBillboard:Destroy()
    end
    local existingSurface = rebirthButtonPart:FindFirstChild("RebirthProgressGui", true)
    if existingSurface then
        existingSurface:Destroy()
    end
    
    -- Create BillboardGui for rebirth icon (floating above button)
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "RebirthBillboard"
    billboardGui.Size = UDim2.new(0, 40, 0, 40) -- Much smaller, square size for icon
    billboardGui.StudsOffset = Vector3.new(0, 5, 0) -- Float 5 studs above the part
    billboardGui.MaxDistance = 50 -- Limit visibility distance to prevent scaling issues
    billboardGui.Parent = targetPart
    
    -- Create rebirth icon (no text)
    local IconAssets = require(game.ReplicatedStorage.utils.IconAssets)
    local rebirthIcon = Instance.new("ImageLabel")
    rebirthIcon.Name = "RebirthIcon"
    rebirthIcon.Size = UDim2.new(1, 0, 1, 0)
    rebirthIcon.BackgroundTransparency = 1
    rebirthIcon.Image = IconAssets.getIcon("UI", "REBIRTH")
    rebirthIcon.ScaleType = Enum.ScaleType.Fit
    rebirthIcon.Parent = billboardGui
    
    -- Create SurfaceGui for progress bar (on top of the part) - similar to processing counter
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Name = "RebirthProgressGui"
    surfaceGui.Face = Enum.NormalId.Top
    surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surfaceGui.PixelsPerStud = 50
    surfaceGui.Parent = targetPart
    
    -- Create progress text label (no background frame, just text like processing counter)
    local progressLabel = Instance.new("TextLabel")
    progressLabel.Name = "ProgressText"
    progressLabel.Size = UDim2.new(1, 0, 1, 0)
    progressLabel.Position = UDim2.new(0, 0, 0, 0)
    progressLabel.BackgroundTransparency = 1 -- No background like processing counter
    progressLabel.Font = Enum.Font.FredokaOne
    progressLabel.Text = "$0 / $500" -- Will be updated dynamically with correct cost
    progressLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    progressLabel.TextSize = 24 -- Smaller than billboard, similar to processing counter
    progressLabel.TextStrokeTransparency = 0
    progressLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    progressLabel.TextXAlignment = Enum.TextXAlignment.Center
    progressLabel.TextYAlignment = Enum.TextYAlignment.Center
    progressLabel.Parent = surfaceGui
    
    -- Store reference to progress label for updates
    self.progressLabel = progressLabel
    
    -- Update progress initially
    self:UpdateProgressDisplay()
end

-- Set up subscription to player data changes for progress updates
function RebirthButtonService:SetupDataSubscription()
    local store = require(ReplicatedStorage.store)
    
    -- Subscribe to data changes to update progress display
    local unsubscribe = store.changed:connect(function(newState, oldState)
        if newState.player then
            self:UpdateProgressDisplay()
        end
    end)
    
    -- Store unsubscribe function for cleanup
    self.dataSubscription = unsubscribe
end

-- Update the progress display with current player money
function RebirthButtonService:UpdateProgressDisplay()
    if not self.progressLabel then return end
    
    -- Get player data from Rodux store
    local store = require(ReplicatedStorage.store)
    local playerData = store:getState().player
    
    if playerData and playerData.Resources then
        local currentMoney = playerData.Resources.Money or 0
        local currentRebirths = playerData.Resources.Rebirths or 0
        local rebirthCost = RebirthUtils.getRebirthCost(currentRebirths)
        local progressText = "$" .. currentMoney .. " / $" .. rebirthCost
        self.progressLabel.Text = progressText
        
        -- Change color based on progress
        if currentMoney >= rebirthCost then
            self.progressLabel.TextColor3 = Color3.fromRGB(0, 255, 0) -- Green if can rebirth
        else
            self.progressLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White if not ready
        end
    end
end

function RebirthButtonService:SetupProximityDetection()
    if not rebirthButtonPart then return end
    
    -- Clean up existing connections
    if proximityConnection then
        proximityConnection:Disconnect()
    end
    if proximityCheckConnection then
        proximityCheckConnection:Disconnect()
    end
    
    local isNearButton = false
    local rebirthUIOpen = false
    
    -- Get button position for distance calculation
    local buttonPosition
    if rebirthButtonPart:IsA("Model") then
        local cframe, size = rebirthButtonPart:GetBoundingBox()
        buttonPosition = cframe.Position
    else
        buttonPosition = rebirthButtonPart.Position
    end
    
    -- Set up touch detection for the rebirth button (handle Model with multiple parts)
    local function onTouch(hit)
        local character = hit.Parent
        if character == player.Character then
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                local distance = (humanoidRootPart.Position - buttonPosition).Magnitude
                if distance <= INTERACTION_DISTANCE and not rebirthUIOpen then
                    isNearButton = true
                    rebirthUIOpen = true
                    if onRebirthButtonOpen then
                        onRebirthButtonOpen()
                    end
                end
            end
        end
    end
    
    -- Connect to all parts in the RebirthButton (in case it's a model with multiple parts)
    if rebirthButtonPart:IsA("Model") then
        for _, part in pairs(rebirthButtonPart:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Touched:Connect(onTouch)
            end
        end
    elseif rebirthButtonPart:IsA("BasePart") then
        proximityConnection = rebirthButtonPart.Touched:Connect(onTouch)
    end
    
    -- Set up continuous proximity checking while UI is open
    proximityCheckConnection = RunService.Heartbeat:Connect(function()
        if rebirthUIOpen and player.Character then
            local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                local distance = (humanoidRootPart.Position - buttonPosition).Magnitude
                if distance > INTERACTION_DISTANCE then
                    isNearButton = false
                    rebirthUIOpen = false
                    if onRebirthButtonClose then
                        onRebirthButtonClose()
                    end
                end
            end
        end
    end)
end

-- Set callback for when rebirth button should open UI
function RebirthButtonService:SetOpenCallback(callback)
    onRebirthButtonOpen = callback
end

-- Set callback for when rebirth button should close UI
function RebirthButtonService:SetCloseCallback(callback)
    onRebirthButtonClose = callback
end

-- Clean up connections
function RebirthButtonService:Cleanup()
    if proximityConnection then
        proximityConnection:Disconnect()
        proximityConnection = nil
    end
    if proximityCheckConnection then
        proximityCheckConnection:Disconnect()
        proximityCheckConnection = nil
    end
    if self.dataSubscription and type(self.dataSubscription) == "function" then
        self.dataSubscription()
        self.dataSubscription = nil
    end
    self.progressLabel = nil
end

-- Handle character respawn
Players.LocalPlayer.CharacterAdded:Connect(function()
    -- Re-initialize after character respawn
    RebirthButtonService:Cleanup()
    task.wait(1) -- Wait for character to fully load
    RebirthButtonService:Initialize()
end)

return RebirthButtonService