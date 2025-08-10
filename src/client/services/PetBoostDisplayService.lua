-- PetBoostDisplayService - Shows total equipped pet boost on bottom-left GUI
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DataSyncService = require(script.Parent.DataSyncService)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)

local PetBoostDisplayService = {}
PetBoostDisplayService.__index = PetBoostDisplayService

local player = Players.LocalPlayer
local boostGui = nil

function PetBoostDisplayService:Initialize()
    -- Create the boost display GUI
    self:CreateBoostGUI()
    
    -- Subscribe to player data changes
    DataSyncService:Subscribe(function(newState)
        if newState.player then
            self:UpdateBoostDisplay(newState.player.EquippedPets, newState.player.OwnedGamepasses)
        end
    end)
    
    -- Get initial data
    local initialData = DataSyncService:GetPlayerData()
    if initialData then
        self:UpdateBoostDisplay(initialData.EquippedPets, initialData.OwnedGamepasses)
    end
end

function PetBoostDisplayService:CreateBoostGUI()
    -- Create ScreenGui
    local playerGui = player:WaitForChild("PlayerGui")
    boostGui = Instance.new("ScreenGui")
    boostGui.Name = "PetBoostDisplayGUI"
    boostGui.ResetOnSpawn = false
    boostGui.Enabled = false -- Start hidden by default, will be shown via boost icon
    boostGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- Use modern ZIndex system
    boostGui.DisplayOrder = 100 -- High display order
    boostGui.Parent = playerGui
    
    -- Main frame (bottom-left corner) - increased height for gamepass boost
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "BoostFrame"
    mainFrame.Size = UDim2.new(0, 200, 0, 110)
    mainFrame.Position = UDim2.new(0, 100, 1, -130) -- Moved right to avoid overlap with boost button
    mainFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 255) -- Bright magenta for debugging
    mainFrame.BorderSizePixel = 5
    mainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255) -- Cyan border for debugging
    mainFrame.ZIndex = 200 -- Very high ZIndex
    mainFrame.Parent = boostGui
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    -- Title label (shows total boost)
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -10, 0, 25)
    titleLabel.Position = UDim2.new(0, 5, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "💪 Total Boost: +0%"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.FredokaOne
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = mainFrame
    
    -- Pet boost value label
    local petBoostLabel = Instance.new("TextLabel")
    petBoostLabel.Name = "PetBoostLabel"
    petBoostLabel.Size = UDim2.new(1, -10, 0, 20)
    petBoostLabel.Position = UDim2.new(0, 5, 0, 30)
    petBoostLabel.BackgroundTransparency = 1
    petBoostLabel.Text = "Pets: +0%"
    petBoostLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green color
    petBoostLabel.TextScaled = true
    petBoostLabel.Font = Enum.Font.FredokaOne
    petBoostLabel.TextXAlignment = Enum.TextXAlignment.Left
    petBoostLabel.Parent = mainFrame
    
    -- Gamepass boost value label
    local gamepassBoostLabel = Instance.new("TextLabel")
    gamepassBoostLabel.Name = "GamepassBoostLabel"
    gamepassBoostLabel.Size = UDim2.new(1, -10, 0, 20)
    gamepassBoostLabel.Position = UDim2.new(0, 5, 0, 50)
    gamepassBoostLabel.BackgroundTransparency = 1
    gamepassBoostLabel.Text = "Gamepasses: +0%"
    gamepassBoostLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold color
    gamepassBoostLabel.TextScaled = true
    gamepassBoostLabel.Font = Enum.Font.FredokaOne
    gamepassBoostLabel.TextXAlignment = Enum.TextXAlignment.Left
    gamepassBoostLabel.Parent = mainFrame
    
    -- Pet count label (small text)
    local petCountLabel = Instance.new("TextLabel")
    petCountLabel.Name = "PetCountLabel"
    petCountLabel.Size = UDim2.new(1, -10, 0, 15)
    petCountLabel.Position = UDim2.new(0, 5, 1, -20)
    petCountLabel.BackgroundTransparency = 1
    petCountLabel.Text = "0 pets equipped"
    petCountLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    petCountLabel.TextScaled = true
    petCountLabel.Font = Enum.Font.Gotham
    petCountLabel.TextXAlignment = Enum.TextXAlignment.Left
    petCountLabel.Parent = mainFrame
end

function PetBoostDisplayService:UpdateBoostDisplay(equippedPets, ownedGamepasses)
    if not boostGui then return end
    
    local boostFrame = boostGui:FindFirstChild("BoostFrame")
    if not boostFrame then return end
    
    local titleLabel = boostFrame:FindFirstChild("TitleLabel")
    local petBoostLabel = boostFrame:FindFirstChild("PetBoostLabel")
    local gamepassBoostLabel = boostFrame:FindFirstChild("GamepassBoostLabel")
    local petCountLabel = boostFrame:FindFirstChild("PetCountLabel")
    
    if not titleLabel or not petBoostLabel or not gamepassBoostLabel or not petCountLabel then return end
    
    -- Calculate pet boost percentage
    local petBoostMultiplier = 1 -- Start with 1 (no boost)
    local petCount = 0
    
    if equippedPets then
        for _, equippedPet in pairs(equippedPets) do
            petCount = petCount + 1
            local petBoost = equippedPet.BaseBoost or 1
            -- Convert boost to percentage (e.g., 1.1 boost = 0.1 = 10% boost)
            local boostPercentage = petBoost - 1 -- 1.1 becomes 0.1 (10%)
            petBoostMultiplier = petBoostMultiplier + boostPercentage
        end
    end
    
    -- Calculate gamepass boost
    local gamepassMultiplier = 1
    local gamepasses = {}
    
    -- Convert OwnedGamepasses array to lookup table
    if ownedGamepasses then
        for _, gamepassName in pairs(ownedGamepasses) do
            gamepasses[gamepassName] = true
        end
    end
    
    -- Stack gamepass multipliers
    if gamepasses.TwoXMoney then
        gamepassMultiplier = gamepassMultiplier * 2
    end
    
    if gamepasses.VIP then
        gamepassMultiplier = gamepassMultiplier * 2
    end
    
    -- Calculate total boost multipliers (additive - more intuitive)
    local totalMultiplier = petBoostMultiplier + gamepassMultiplier - 1 -- Subtract 1 to avoid double-counting base multiplier
    
    -- Update title with total boost (show as multiplier)
    if totalMultiplier > 1 then
        titleLabel.Text = string.format("💪 Total Boost: %sx", NumberFormatter.formatBoost(totalMultiplier))
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 100) -- Yellow for total
    else
        titleLabel.Text = "💪 Total Boost: 1x"
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White for no boost
    end
    
    -- Update pet boost label (show as multiplier)
    if petBoostMultiplier > 1 then
        petBoostLabel.Text = string.format("Pets: %sx", NumberFormatter.formatBoost(petBoostMultiplier))
        petBoostLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green for positive boost
    else
        petBoostLabel.Text = "Pets: 1x"
        petBoostLabel.TextColor3 = Color3.fromRGB(150, 150, 150) -- Gray for no boost
    end
    
    -- Update gamepass boost label (show as multiplier)
    if gamepassMultiplier > 1 then
        local gamepassText = "Gamepasses: "
        local gamepassNames = {}
        
        if gamepasses.TwoXMoney then
            table.insert(gamepassNames, "2x Money")
        end
        
        if gamepasses.VIP then
            table.insert(gamepassNames, "VIP")
        end
        
        gamepassText = gamepassText .. string.format("%sx (%s)", NumberFormatter.formatBoost(gamepassMultiplier), table.concat(gamepassNames, " + "))
        gamepassBoostLabel.Text = gamepassText
        gamepassBoostLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold for gamepass boost
    else
        gamepassBoostLabel.Text = "Gamepasses: 1x"
        gamepassBoostLabel.TextColor3 = Color3.fromRGB(150, 150, 150) -- Gray for no boost
    end
    
    -- Update pet count
    if petCount == 1 then
        petCountLabel.Text = "1 pet equipped"
    else
        petCountLabel.Text = petCount .. " pets equipped"
    end
end

-- Toggle visibility of the boost panel
function PetBoostDisplayService:ToggleVisibility()
    print("PetBoostDisplayService:ToggleVisibility called")
    if boostGui then
        local wasEnabled = boostGui.Enabled
        boostGui.Enabled = not boostGui.Enabled
        print("Panel toggled from", wasEnabled, "to", boostGui.Enabled)
    else
        print("ERROR: boostGui is nil!")
    end
end

-- Show the boost panel
function PetBoostDisplayService:Show()
    if boostGui then
        boostGui.Enabled = true
    end
end

-- Hide the boost panel
function PetBoostDisplayService:Hide()
    if boostGui then
        boostGui.Enabled = false
    end
end

-- Check if boost panel is visible
function PetBoostDisplayService:IsVisible()
    return boostGui and boostGui.Enabled or false
end

function PetBoostDisplayService:Cleanup()
    if boostGui then
        boostGui:Destroy()
        boostGui = nil
    end
end

return PetBoostDisplayService