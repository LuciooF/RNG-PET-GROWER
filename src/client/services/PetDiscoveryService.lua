-- PetDiscoveryService - Shows discovery popups for new pets
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local DataSyncService = require(script.Parent.DataSyncService)
local PetConstants = require(ReplicatedStorage.constants.PetConstants)
local PetConfig = require(ReplicatedStorage.config.PetConfig)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)

local PetDiscoveryService = {}
PetDiscoveryService.__index = PetDiscoveryService

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local connections = {}

-- Discovery queue to prevent spam
local discoveryQueue = {}
local isShowingDiscovery = false
local previousCollectedPets = {}

function PetDiscoveryService:Initialize()
    -- Subscribe to data changes to detect new pet discoveries
    local unsubscribe = DataSyncService:Subscribe(function(newState)
        if newState.player and newState.player.CollectedPets then
            self:CheckForNewDiscoveries(newState.player.CollectedPets)
        end
    end)
    
    connections.dataSubscription = unsubscribe
    
    -- Initialize previous collected pets (prevent spam on first load)
    local initialData = DataSyncService:GetPlayerData()
    if initialData and initialData.CollectedPets then
        previousCollectedPets = self:CloneTable(initialData.CollectedPets)
    end
    
    -- Process discovery queue with rate limiting
    self:StartQueueProcessor()
end

function PetDiscoveryService:CloneTable(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = self:CloneTable(v)
        else
            copy[k] = v
        end
    end
    return copy
end

function PetDiscoveryService:CheckForNewDiscoveries(currentCollectedPets)
    if not currentCollectedPets then return end
    
    local newDiscoveries = {}
    
    -- Check for newly discovered pets
    for petName, petData in pairs(currentCollectedPets) do
        local wasDiscovered = previousCollectedPets[petName] ~= nil
        local isNowDiscovered = petData ~= nil
        
        if not wasDiscovered and isNowDiscovered then
            -- Extract variation from pet name
            local variation = "Bronze" -- default
            local variations = {"Bronze", "Silver", "Gold", "Platinum", "Diamond", "Emerald", "Sapphire", "Ruby", "Titanium", "Obsidian", "Crystal", "Rainbow", "Cosmic", "Void", "Divine"}
            for _, var in pairs(variations) do
                if string.find(petName, var .. "$") then
                    variation = var
                    break
                end
            end
            
            table.insert(newDiscoveries, {
                name = petName,
                variation = variation,
                data = petData,
                timestamp = tick()
            })
        end
        
        -- Check for new variations of existing pets
        if wasDiscovered and isNowDiscovered and petData.variations then
            local previousVariations = previousCollectedPets[petName].variations or {}
            for variation, _ in pairs(petData.variations) do
                if not previousVariations[variation] then
                    table.insert(newDiscoveries, {
                        name = petName,
                        variation = variation,
                        data = petData,
                        timestamp = tick()
                    })
                end
            end
        end
    end
    
    -- Add discoveries to queue, but limit to top 3 rarest if too many
    for _, discovery in ipairs(newDiscoveries) do
        table.insert(discoveryQueue, discovery)
    end
    
    -- If queue gets too long, keep only the 3 rarest discoveries
    if #discoveryQueue > 3 then
        -- Sort discoveries by rarity (rarest first)
        table.sort(discoveryQueue, function(a, b)
            local petConfigA = self:FindPetByName(a.name)
            local petConfigB = self:FindPetByName(b.name)
            
            if petConfigA and petConfigB then
                local rarityOrderA = self:GetRarityOrder(petConfigA.Rarity)
                local rarityOrderB = self:GetRarityOrder(petConfigB.Rarity)
                return rarityOrderA > rarityOrderB -- Higher order = rarer
            end
            return false
        end)
        
        -- Keep only top 3 rarest
        local topDiscoveries = {}
        for i = 1, math.min(3, #discoveryQueue) do
            table.insert(topDiscoveries, discoveryQueue[i])
        end
        discoveryQueue = topDiscoveries
    end
    
    -- Update previous state
    previousCollectedPets = self:CloneTable(currentCollectedPets)
end

function PetDiscoveryService:GetRarityOrder(rarity)
    -- Return higher numbers for rarer pets (Omniscient = 15, Common = 1)
    local rarityOrder = {
        ["Common"] = 1,
        ["Uncommon"] = 2,
        ["Rare"] = 3, 
        ["Epic"] = 4,
        ["Legendary"] = 5,
        ["Mythic"] = 6,
        ["Ancient"] = 7,
        ["Celestial"] = 8,
        ["Transcendent"] = 9,
        ["Omnipotent"] = 10,
        ["Ethereal"] = 11,
        ["Primordial"] = 12,
        ["Cosmic"] = 13,
        ["Infinite"] = 14,
        ["Omniscient"] = 15
    }
    return rarityOrder[rarity] or 1
end

function PetDiscoveryService:StartQueueProcessor()
    task.spawn(function()
        while true do
            if not isShowingDiscovery and #discoveryQueue > 0 then
                local discovery = table.remove(discoveryQueue, 1)
                self:ShowDiscoveryPopup(discovery)
                -- Wait longer between popups to prevent overwhelming
                task.wait(6) -- 6 seconds between each popup
            end
            task.wait(0.5) -- Check queue every 500ms
        end
    end)
end

-- Helper function to find pet data by name
function PetDiscoveryService:FindPetByName(petName)
    -- Extract just the pet name (remove variation suffix)
    local actualPetName = petName
    
    -- Check if petName contains a variation suffix and extract base name
    local variations = {"Bronze", "Silver", "Gold", "Platinum", "Diamond", "Emerald", "Sapphire", "Ruby", "Titanium", "Obsidian", "Crystal", "Rainbow", "Cosmic", "Void", "Divine"}
    for _, variation in pairs(variations) do
        if string.find(petName, variation .. "$") then -- ends with variation
            actualPetName = string.gsub(petName, variation .. "$", "")
            break
        end
    end
    
    -- Search through all levels to find the pet
    for level = 1, 7 do
        local petsInLevel = PetConfig.getPetsByLevel(level)
        if petsInLevel then
            for _, petData in pairs(petsInLevel) do
                if petData.Name == actualPetName then
                    return petData
                end
            end
        end
    end
    
    return nil
end

function PetDiscoveryService:ShowDiscoveryPopup(discovery)
    isShowingDiscovery = true
    
    -- Get pet config for rarity and variation colors
    local petConfig = self:FindPetByName(discovery.name)
    if not petConfig then
        isShowingDiscovery = false
        return
    end
    
    local rarityColor = PetConstants.getRarityColor(petConfig.Rarity)
    local variationColor = discovery.variation and PetConstants.getVariationColor(discovery.variation) or PetConstants.getVariationColor("Bronze")
    
    -- Create popup GUI
    local popupGui = Instance.new("ScreenGui")
    popupGui.Name = "PetDiscoveryPopup"
    popupGui.ResetOnSpawn = false
    popupGui.IgnoreGuiInset = true
    popupGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    popupGui.Parent = playerGui
    
    -- Main popup frame (smaller and more transparent)
    local popupFrame = Instance.new("Frame")
    popupFrame.Name = "PopupFrame"
    popupFrame.Size = UDim2.new(0, 320, 0, 160) -- Smaller size
    popupFrame.Position = UDim2.new(0.5, 0, 1, 50) -- Start below screen
    popupFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    popupFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    popupFrame.BackgroundTransparency = 0.15 -- More transparent
    popupFrame.BorderSizePixel = 0
    popupFrame.ZIndex = 1000
    popupFrame.Parent = popupGui
    
    -- Rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = popupFrame
    
    -- Drop shadow
    local shadow = Instance.new("UIStroke")
    shadow.Color = Color3.fromRGB(0, 0, 0)
    shadow.Thickness = 3
    shadow.Transparency = 0.7
    shadow.Parent = popupFrame
    
    -- Gradient background (more subtle)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(250, 250, 250)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(230, 230, 230))
    })
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(1, 0.3)
    })
    gradient.Rotation = 45
    gradient.Parent = popupFrame
    
    -- "New Pet Discovered!" title (smaller)
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -20, 0, 28)
    titleLabel.Position = UDim2.new(0, 10, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = discovery.variation and "New Variation Discovered!" or "New Pet Discovered!"
    titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
    titleLabel.TextSize = 20 -- Smaller text
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    titleLabel.ZIndex = 1001
    titleLabel.Parent = popupFrame
    
    -- Pet name (extract just the pet name, not the variation suffix)
    local actualPetName = discovery.name
    local variations = {"Bronze", "Silver", "Gold", "Platinum", "Diamond", "Emerald", "Sapphire", "Ruby", "Titanium", "Obsidian", "Crystal", "Rainbow", "Cosmic", "Void", "Divine"}
    for _, variation in pairs(variations) do
        if string.find(discovery.name, variation .. "$") then
            actualPetName = string.gsub(discovery.name, variation .. "$", "")
            break
        end
    end
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "PetName"
    nameLabel.Size = UDim2.new(1, -20, 0, 25)
    nameLabel.Position = UDim2.new(0, 10, 0, 40)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = actualPetName
    nameLabel.TextColor3 = rarityColor
    nameLabel.TextSize = 18 -- Smaller text
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.ZIndex = 1001
    nameLabel.Parent = popupFrame
    
    -- Variation (if applicable)
    if discovery.variation then
        local variationLabel = Instance.new("TextLabel")
        variationLabel.Name = "Variation"
        variationLabel.Size = UDim2.new(1, -20, 0, 20)
        variationLabel.Position = UDim2.new(0, 10, 0, 68)
        variationLabel.BackgroundTransparency = 1
        variationLabel.Text = discovery.variation .. " Variation"
        variationLabel.TextColor3 = variationColor
        variationLabel.TextSize = 15 -- Smaller text
        variationLabel.Font = Enum.Font.GothamBold
        variationLabel.TextXAlignment = Enum.TextXAlignment.Center
        variationLabel.TextStrokeTransparency = 0
        variationLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        variationLabel.ZIndex = 1001
        variationLabel.Parent = popupFrame
    end
    
    -- Rarity info (smaller)
    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Name = "Rarity"
    rarityLabel.Size = UDim2.new(1, -20, 0, 18)
    rarityLabel.Position = UDim2.new(0, 10, 0, discovery.variation and 92 or 70)
    rarityLabel.BackgroundTransparency = 1
    local rarityChance = PetConstants.getRarityChance and PetConstants.getRarityChance(petConfig.Rarity) or 1000000
    rarityLabel.Text = "Rarity: " .. petConfig.Rarity .. " (1 in " .. NumberFormatter.format(rarityChance) .. ")"
    rarityLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
    rarityLabel.TextSize = 12 -- Smaller text
    rarityLabel.Font = Enum.Font.Gotham
    rarityLabel.TextXAlignment = Enum.TextXAlignment.Center
    rarityLabel.ZIndex = 1001
    rarityLabel.Parent = popupFrame
    
    -- Congratulations message (smaller and adjusted)
    local congratsLabel = Instance.new("TextLabel")
    congratsLabel.Name = "Congrats"
    congratsLabel.Size = UDim2.new(1, -20, 0, 22)
    congratsLabel.Position = UDim2.new(0, 10, 0, discovery.variation and 115 or 93)
    congratsLabel.BackgroundTransparency = 1
    congratsLabel.Text = "🎉 Well done! Check your Pet Index! 🎉"
    congratsLabel.TextColor3 = Color3.fromRGB(50, 205, 50) -- Lime green
    congratsLabel.TextSize = 14 -- Smaller text
    congratsLabel.Font = Enum.Font.GothamBold
    congratsLabel.TextXAlignment = Enum.TextXAlignment.Center
    congratsLabel.TextStrokeTransparency = 0
    congratsLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    congratsLabel.ZIndex = 1001
    congratsLabel.Parent = popupFrame
    
    -- Animate popup appearance
    local targetPosition = UDim2.new(0.5, 0, 0.8, 0) -- Bottom center of screen
    
    -- Slide up animation
    local slideUpTween = TweenService:Create(popupFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = targetPosition
    })
    
    -- Add bounce animation to congratulations text
    local function animateCongrats()
        task.spawn(function()
            while congratsLabel.Parent do
                local bounceUp = TweenService:Create(congratsLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = UDim2.new(congratsLabel.Position.X.Scale, congratsLabel.Position.X.Offset, congratsLabel.Position.Y.Scale, congratsLabel.Position.Y.Offset - 5)
                })
                bounceUp:Play()
                bounceUp.Completed:Wait()
                
                local bounceDown = TweenService:Create(congratsLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    Position = UDim2.new(congratsLabel.Position.X.Scale, congratsLabel.Position.X.Offset, congratsLabel.Position.Y.Scale, congratsLabel.Position.Y.Offset + 5)
                })
                bounceDown:Play()
                bounceDown.Completed:Wait()
                
                task.wait(0.5) -- Pause between bounces
            end
        end)
    end
    
    -- Start animations
    slideUpTween:Play()
    slideUpTween.Completed:Connect(function()
        animateCongrats()
    end)
    
    -- Auto-dismiss after 3 seconds (shorter for less intrusive)
    task.wait(3)
    
    -- Slide down animation
    local slideDownTween = TweenService:Create(popupFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, 0, 1, 50) -- Back below screen
    })
    
    slideDownTween:Play()
    slideDownTween.Completed:Connect(function()
        popupGui:Destroy()
        isShowingDiscovery = false
    end)
end

function PetDiscoveryService:Cleanup()
    -- Disconnect all connections
    for name, connection in pairs(connections) do
        if connection and type(connection) == "function" then
            connection()
        elseif connection and typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end
    connections = {}
    
    -- Clear discovery queue
    discoveryQueue = {}
    isShowingDiscovery = false
end

-- Handle character respawn
Players.LocalPlayer.CharacterAdded:Connect(function()
    -- Re-initialize after character respawn
    PetDiscoveryService:Cleanup()
    task.wait(1) -- Wait for character to fully load
    PetDiscoveryService:Initialize()
end)

return PetDiscoveryService