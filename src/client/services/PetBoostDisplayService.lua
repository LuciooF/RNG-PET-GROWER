-- PetBoostDisplayService - Shows total equipped pet boost on bottom-left GUI
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DataSyncService = require(script.Parent.DataSyncService)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)
local BoostCalculator = require(ReplicatedStorage.utils.BoostCalculator)

local PetBoostDisplayService = {}
PetBoostDisplayService.__index = PetBoostDisplayService

local player = Players.LocalPlayer
local boostGui = nil

function PetBoostDisplayService:Initialize()
    print("PetBoostDisplayService DEBUG: Initialize() called")
    -- Create the boost display GUI
    self:CreateBoostGUI()
    print("PetBoostDisplayService DEBUG: GUI created")
    
    -- Subscribe to player data changes
    print("PetBoostDisplayService DEBUG: Setting up DataSyncService subscription")
    DataSyncService:Subscribe(function(newState)
        print("PetBoostDisplayService DEBUG: DataSyncService callback triggered")
        if newState.player then
            print("PetBoostDisplayService DEBUG: Player data found in newState, calling UpdateBoostDisplay")
            self:UpdateBoostDisplay(newState.player)
        else
            print("PetBoostDisplayService DEBUG: No player data in newState")
        end
    end)
    
    -- Get initial data
    print("PetBoostDisplayService DEBUG: Getting initial data")
    local initialData = DataSyncService:GetPlayerData()
    if initialData then
        print("PetBoostDisplayService DEBUG: Initial data found, calling UpdateBoostDisplay")
        self:UpdateBoostDisplay(initialData)
    else
        print("PetBoostDisplayService DEBUG: No initial data found")
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
    
    -- Main frame (bottom-left corner) - increased height for gamepass boost + potions
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "BoostFrame"
    mainFrame.Size = UDim2.new(0, 200, 0, 130) -- Increased height for potion line
    mainFrame.Position = UDim2.new(0, 100, 1, -150) -- Adjusted position for taller frame
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
    
    -- Potion boost value label
    local potionBoostLabel = Instance.new("TextLabel")
    potionBoostLabel.Name = "PotionBoostLabel"
    potionBoostLabel.Size = UDim2.new(1, -10, 0, 20)
    potionBoostLabel.Position = UDim2.new(0, 5, 0, 70)
    potionBoostLabel.BackgroundTransparency = 1
    potionBoostLabel.Text = "Potions: 1x"
    potionBoostLabel.TextColor3 = Color3.fromRGB(138, 43, 226) -- Purple color (matches potion theme)
    potionBoostLabel.TextScaled = true
    potionBoostLabel.Font = Enum.Font.FredokaOne
    potionBoostLabel.TextXAlignment = Enum.TextXAlignment.Left
    potionBoostLabel.Parent = mainFrame
    
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

function PetBoostDisplayService:UpdateBoostDisplay(playerData)
    if not boostGui then return end
    
    local boostFrame = boostGui:FindFirstChild("BoostFrame")
    if not boostFrame then return end
    
    local titleLabel = boostFrame:FindFirstChild("TitleLabel")
    local petBoostLabel = boostFrame:FindFirstChild("PetBoostLabel")
    local gamepassBoostLabel = boostFrame:FindFirstChild("GamepassBoostLabel")
    local potionBoostLabel = boostFrame:FindFirstChild("PotionBoostLabel")
    local petCountLabel = boostFrame:FindFirstChild("PetCountLabel")
    
    if not titleLabel or not petBoostLabel or not gamepassBoostLabel or not potionBoostLabel or not petCountLabel then return end
    
    -- Use centralized boost calculation with full player data
    print("PetBoostDisplayService DEBUG: UpdateBoostDisplay called")
    print("PetBoostDisplayService DEBUG: ActivePotions present:", playerData and playerData.ActivePotions and #playerData.ActivePotions or "NONE")
    
    local boostBreakdown = BoostCalculator.getBoostBreakdown(playerData)
    print("PetBoostDisplayService DEBUG: Total boost from breakdown:", boostBreakdown.totalBoost)
    
    -- Update title with total boost (show as multiplier)
    if boostBreakdown.totalBoost > 1 then
        titleLabel.Text = string.format("💪 Total Boost: %sx", NumberFormatter.formatBoost(boostBreakdown.totalBoost))
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 100) -- Yellow for total
    else
        titleLabel.Text = "💪 Total Boost: 1x"
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White for no boost
    end
    
    -- Update pet boost label (show as multiplier)
    if boostBreakdown.petBoost > 1 then
        petBoostLabel.Text = string.format("Pets: %sx", NumberFormatter.formatBoost(boostBreakdown.petBoost))
        petBoostLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green for positive boost
    else
        petBoostLabel.Text = "Pets: 1x"
        petBoostLabel.TextColor3 = Color3.fromRGB(150, 150, 150) -- Gray for no boost
    end
    
    -- Update gamepass boost label (show as multiplier)
    if boostBreakdown.gamepassBoost > 1 then
        local gamepassText = "Gamepasses: "
        local gamepassNames = {}
        
        -- Convert array to lookup for display
        local gamepasses = {}
        if ownedGamepasses then
            for _, gamepassName in pairs(ownedGamepasses) do
                gamepasses[gamepassName] = true
            end
        end
        
        if gamepasses.TwoXMoney then
            table.insert(gamepassNames, "2x Money")
        end
        
        if gamepasses.VIP then
            table.insert(gamepassNames, "VIP")
        end
        
        gamepassText = gamepassText .. string.format("%sx (%s)", NumberFormatter.formatBoost(boostBreakdown.gamepassBoost), table.concat(gamepassNames, " + "))
        gamepassBoostLabel.Text = gamepassText
        gamepassBoostLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold for gamepass boost
    else
        gamepassBoostLabel.Text = "Gamepasses: 1x"
        gamepassBoostLabel.TextColor3 = Color3.fromRGB(150, 150, 150) -- Gray for no boost
    end
    
    -- Update potion boost label (Money potions only)
    local moneyPotionBoost = boostBreakdown.potionBoosts.Money or 1
    
    if moneyPotionBoost > 1 then
        potionBoostLabel.Text = string.format("Potions: %sx (Money)", NumberFormatter.formatBoost(moneyPotionBoost))
        potionBoostLabel.TextColor3 = Color3.fromRGB(138, 43, 226) -- Purple for active potions
    else
        potionBoostLabel.Text = "Potions: 1x"
        potionBoostLabel.TextColor3 = Color3.fromRGB(150, 150, 150) -- Gray for no boost
    end
    
    -- Update pet count
    if boostBreakdown.petCount == 1 then
        petCountLabel.Text = "1 pet equipped"
    else
        petCountLabel.Text = boostBreakdown.petCount .. " pets equipped"
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