-- PetMagnetButtonService - Handles physical PetMagnet button interaction
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DataSyncService = require(script.Parent.DataSyncService)
local GamepassConfig = require(ReplicatedStorage.config.GamepassConfig)

local PetMagnetButtonService = {}
PetMagnetButtonService.__index = PetMagnetButtonService

local player = Players.LocalPlayer
local proximityConnection = nil
local petMagnetButtonPart = nil

-- Configuration
local INTERACTION_DISTANCE = 10 -- Distance in studs to trigger interaction
local PURCHASE_COOLDOWN = 3 -- Seconds between purchase attempts

-- Cooldown tracking
local lastPurchaseAttempt = 0

-- State tracking to prevent unnecessary updates
local lastKnownOwnership = nil

function PetMagnetButtonService:Initialize()
    -- Find the PetMagnet button in the player's area
    self:FindPetMagnetButton()
    
    -- Set up proximity detection
    if petMagnetButtonPart then
        self:SetupProximityDetection()
    end
    
    -- Set up data subscription for visibility updates
    self:SetupDataSubscription()
end

function PetMagnetButtonService:FindPetMagnetButton()
    -- Wait for character to spawn
    if not player.Character then
        player.CharacterAdded:Wait()
    end
    
    -- Wait a bit for area assignment to complete
    task.wait(2)
    
    -- Find player's area (similar to how RebirthButtonService does it)
    local playerAreas = game.Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then
        warn("PetMagnetButtonService: PlayerAreas not found")
        return
    end
    
    print("PetMagnetButtonService: Found PlayerAreas, looking for player's area...")
    
    -- Find the player's assigned area by checking the area nameplate
    local playerArea = nil
    for _, area in pairs(playerAreas:GetChildren()) do
        if area.Name:match("PlayerArea") then
            print("PetMagnetButtonService: Checking area:", area.Name)
            -- Check if this area belongs to the current player by looking at the nameplate
            local nameplate = area:FindFirstChild("AreaNameplate")
            if nameplate then
                print("PetMagnetButtonService: Found nameplate in", area.Name)
                local billboard = nameplate:FindFirstChild("NameplateBillboard")
                if billboard then
                    local textLabel = billboard:FindFirstChild("TextLabel")
                    if textLabel then
                        print("PetMagnetButtonService: Nameplate text:", textLabel.Text, "Looking for:", player.Name .. "'s Area")
                        if textLabel.Text == (player.Name .. "'s Area") then
                            playerArea = area
                            print("PetMagnetButtonService: Found player's area:", area.Name)
                            break
                        end
                    end
                end
            else
                print("PetMagnetButtonService: No nameplate found in", area.Name)
            end
        end
    end
    
    if not playerArea then
        warn("PetMagnetButtonService: Player area not found")
        return
    end
    
    -- Find the PetMagnet button
    local buttonsFolder = playerArea:FindFirstChild("Buttons")
    if not buttonsFolder then
        warn("PetMagnetButtonService: Buttons folder not found")
        return
    end
    
    petMagnetButtonPart = buttonsFolder:FindFirstChild("PetMagnet")
    if not petMagnetButtonPart then
        warn("PetMagnetButtonService: PetMagnet button not found")
        return
    end
    
    -- Add GUI to the button
    self:CreatePetMagnetButtonGUI()
    
    -- Set initial visibility based on gamepass ownership
    self:UpdateButtonVisibility()
end

function PetMagnetButtonService:CreatePetMagnetButtonGUI()
    if not petMagnetButtonPart then return end
    
    -- Find the best part to attach GUI to
    local targetPart = nil
    if petMagnetButtonPart:IsA("Model") then
        -- Look for a part with "Platform" or similar in the name, or just use the first BasePart
        for _, part in pairs(petMagnetButtonPart:GetDescendants()) do
            if part:IsA("BasePart") then
                if part.Name:lower():find("platform") or part.Name:lower():find("base") or part.Name:lower():find("top") then
                    targetPart = part
                    break
                end
            end
        end
        -- Fallback to first BasePart if no specific part found
        if not targetPart then
            for _, part in pairs(petMagnetButtonPart:GetDescendants()) do
                if part:IsA("BasePart") then
                    targetPart = part
                    break
                end
            end
        end
    else
        targetPart = petMagnetButtonPart
    end
    
    if not targetPart then
        warn("PetMagnetButtonService: No suitable part found for GUI attachment")
        return
    end
    
    -- Clean up existing GUIs
    local existingBillboard = petMagnetButtonPart:FindFirstChild("PetMagnetBillboard", true)
    if existingBillboard then
        existingBillboard:Destroy()
    end
    
    -- Get player data to check ownership
    local playerData = DataSyncService:GetPlayerData()
    local ownsPetMagnet = self:PlayerOwnsPetMagnet(playerData)
    
    -- Create BillboardGui for gamepass info (floating above button)
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "PetMagnetBillboard"
    billboardGui.Size = UDim2.new(0, 150, 0, 80)
    billboardGui.StudsOffset = Vector3.new(0, 5, 0) -- Float 5 studs above the part
    billboardGui.MaxDistance = 80 -- Much further visibility for camera angles
    billboardGui.Parent = targetPart
    
    if ownsPetMagnet then
        -- Show simple "OWNED" text when player owns it
        local ownedLabel = Instance.new("TextLabel")
        ownedLabel.Name = "OwnedText"
        ownedLabel.Size = UDim2.new(1, 0, 1, 0)
        ownedLabel.BackgroundTransparency = 1
        ownedLabel.Font = Enum.Font.GothamBold
        ownedLabel.Text = "Pet Magnet\nOWNED"
        ownedLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green
        ownedLabel.TextSize = 20
        ownedLabel.TextStrokeTransparency = 0
        ownedLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        ownedLabel.Parent = billboardGui
    else
        -- Show title and description when not owned
        local petMagnetLabel = Instance.new("TextLabel")
        petMagnetLabel.Name = "PetMagnetText"
        petMagnetLabel.Size = UDim2.new(1, 0, 0, 30)
        petMagnetLabel.Position = UDim2.new(0, 0, 0, 0)
        petMagnetLabel.BackgroundTransparency = 1
        petMagnetLabel.Font = Enum.Font.GothamBold
        petMagnetLabel.Text = "Pet Magnet!"
        petMagnetLabel.TextColor3 = Color3.fromRGB(0, 162, 255) -- Blue pet magnet color
        petMagnetLabel.TextSize = 18
        petMagnetLabel.TextStrokeTransparency = 0
        petMagnetLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        petMagnetLabel.Parent = billboardGui
        
        -- Add description
        local descriptionLabel = Instance.new("TextLabel")
        descriptionLabel.Name = "DescriptionText"
        descriptionLabel.Size = UDim2.new(1, 0, 0, 50)
        descriptionLabel.Position = UDim2.new(0, 0, 0, 30)
        descriptionLabel.BackgroundTransparency = 1
        descriptionLabel.Font = Enum.Font.Gotham
        descriptionLabel.Text = "Auto-collect pet balls\nwithin range!"
        descriptionLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        descriptionLabel.TextSize = 12
        descriptionLabel.TextWrapped = true
        descriptionLabel.TextStrokeTransparency = 0
        descriptionLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        descriptionLabel.Parent = billboardGui
    end
end

-- Set up subscription to player data changes for visibility updates
function PetMagnetButtonService:SetupDataSubscription()
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
function PetMagnetButtonService:UpdateButtonVisibility()
    if not petMagnetButtonPart then return end
    
    -- Get player data from DataSyncService
    local playerData = DataSyncService:GetPlayerData()
    local ownsPetMagnet = self:PlayerOwnsPetMagnet(playerData)
    
    -- Only update if ownership state has changed
    if lastKnownOwnership == ownsPetMagnet then
        return -- No change, skip update
    end
    
    -- Update the tracked state
    lastKnownOwnership = ownsPetMagnet
    
    -- Recreate the GUI to reflect the new ownership status
    self:CreatePetMagnetButtonGUI()
    
    print("PetMagnetButtonService: Player owns gamepass:", ownsPetMagnet)
end


-- Check if player owns PetMagnet gamepass
function PetMagnetButtonService:PlayerOwnsPetMagnet(playerData)
    if not playerData or not playerData.OwnedGamepasses then
        return false
    end
    
    for _, gamepass in pairs(playerData.OwnedGamepasses) do
        if gamepass == "PetMagnet" then
            return true
        end
    end
    
    return false
end

function PetMagnetButtonService:SetupProximityDetection()
    if not petMagnetButtonPart then return end
    
    -- Clean up existing connections
    if proximityConnection then
        proximityConnection:Disconnect()
    end
    
    -- Get button position for distance calculation
    local buttonPosition
    if petMagnetButtonPart:IsA("Model") then
        local cframe, size = petMagnetButtonPart:GetBoundingBox()
        buttonPosition = cframe.Position
    else
        buttonPosition = petMagnetButtonPart.Position
    end
    
    -- Set up touch detection for the PetMagnet button (handle Model with multiple parts)
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
                        print("PetMagnetButtonService: Purchase cooldown active, wait", math.ceil(timeLeft), "seconds")
                        return -- Still in cooldown, ignore touch
                    end
                    
                    -- Check if player already owns the gamepass
                    local playerData = DataSyncService:GetPlayerData()
                    if not self:PlayerOwnsPetMagnet(playerData) then
                        -- Update cooldown timer
                        lastPurchaseAttempt = currentTime
                        -- Trigger gamepass purchase popup
                        self:OpenGamepassPurchasePopup()
                    end
                end
            end
        end
    end
    
    -- Connect to all parts in the PetMagnet button (in case it's a model with multiple parts)
    if petMagnetButtonPart:IsA("Model") then
        for _, part in pairs(petMagnetButtonPart:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Touched:Connect(onTouch)
            end
        end
    elseif petMagnetButtonPart:IsA("BasePart") then
        proximityConnection = petMagnetButtonPart.Touched:Connect(onTouch)
    end
end

-- Open gamepass purchase popup
function PetMagnetButtonService:OpenGamepassPurchasePopup()
    -- Send purchase request to server (same as the GamepassUI does)
    local purchaseGamepassRemote = ReplicatedStorage:FindFirstChild("PurchaseGamepass")
    if purchaseGamepassRemote then
        purchaseGamepassRemote:FireServer("PetMagnet")
        print("PetMagnetButtonService: Triggered PetMagnet gamepass purchase")
    else
        warn("PetMagnetButtonService: PurchaseGamepass remote not found")
    end
end

-- Clean up connections
function PetMagnetButtonService:Cleanup()
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
    PetMagnetButtonService:Cleanup()
    task.wait(1) -- Wait for character to fully load
    PetMagnetButtonService:Initialize()
end)

return PetMagnetButtonService