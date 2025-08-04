-- PetDiscoveryService - Shows discovery popups for new pets
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

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

-- Sound configuration
local DISCOVERY_SOUND_ID = "rbxassetid://5728423829"

-- Pre-create discovery sound for instant playback
local discoverySound = Instance.new("Sound")
discoverySound.SoundId = DISCOVERY_SOUND_ID
discoverySound.Volume = 0.8 -- Celebratory volume
discoverySound.Parent = SoundService

-- Play discovery sound instantly
local function playDiscoverySound()
    discoverySound:Play()
end

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
    
    -- No queue processor needed - discoveries show immediately or not at all
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
    
    -- If there's already a popup showing, ignore new discoveries (no queue)
    if isShowingDiscovery then
        return
    end
    
    -- Filter discoveries to only show rarer pets (Epic and above)
    local filteredDiscoveries = {}
    for _, discovery in ipairs(newDiscoveries) do
        local petConfig = self:FindPetByName(discovery.name)
        if petConfig then
            local rarityOrder = self:GetRarityOrder(petConfig.Rarity)
            -- Only show pets with rarity Epic (4) or higher
            if rarityOrder >= 4 then
                table.insert(filteredDiscoveries, discovery)
            end
        end
    end
    
    -- If there are filtered discoveries and no popup is active, show the first one
    if #filteredDiscoveries > 0 then
        self:ShowDiscoveryPopup(filteredDiscoveries[1]) -- Only show the first discovery
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

-- Queue processor removed - no longer needed since we don't queue discoveries

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

-- Helper function to create pet model for discovery viewport (similar to pet inventory)
function PetDiscoveryService:CreatePetModelForDiscovery(petName)
    local petsFolder = ReplicatedStorage:FindFirstChild("Pets")
    if not petsFolder then return nil end
    
    local petModelTemplate = petsFolder:FindFirstChild(petName)
    if not petModelTemplate then
        petModelTemplate = petsFolder:GetChildren()[1]
    end
    
    if petModelTemplate then
        local clonedModel = petModelTemplate:Clone()
        clonedModel.Name = "DiscoveryPetModel"
        
        -- Scale for discovery viewport (bigger for more impressive discovery)
        local scaleFactor = 7.0
        
        for _, descendant in pairs(clonedModel:GetDescendants()) do
            if descendant:IsA("BasePart") then
                descendant.Size = descendant.Size * scaleFactor
                descendant.CanCollide = false
                descendant.Anchored = true
                descendant.Massless = true
                descendant.Transparency = math.max(0, descendant.Transparency - 0.3)
                if descendant.Material == Enum.Material.ForceField then
                    descendant.Material = Enum.Material.Plastic
                end
            end
        end
        
        -- Position and rotate model
        local rotationAngle = 160
        clonedModel:MoveTo(Vector3.new(0, 0, 0))
        
        for _, descendant in pairs(clonedModel:GetDescendants()) do
            if descendant:IsA("BasePart") then
                local rotationCFrame = CFrame.Angles(0, math.rad(rotationAngle), 0)
                local currentPos = descendant.Position
                local rotatedPos = rotationCFrame * currentPos
                descendant.Position = rotatedPos
                descendant.CFrame = CFrame.new(rotatedPos) * rotationCFrame * (descendant.CFrame - descendant.Position)
            end
        end
        
        return clonedModel
    end
    
    return nil
end

-- Setup viewport camera for discovery popup
function PetDiscoveryService:SetupDiscoveryViewportCamera(viewportFrame, petModel)
    if not viewportFrame or not petModel then return end
    
    local camera = Instance.new("Camera")
    camera.CameraType = Enum.CameraType.Scriptable
    camera.Parent = viewportFrame
    viewportFrame.CurrentCamera = camera
    
    local modelCFrame, modelSize = petModel:GetBoundingBox()
    local maxSize = math.max(modelSize.X, modelSize.Y, modelSize.Z)
    
    local distance = maxSize * 1.5
    local cameraPosition = modelCFrame.Position + Vector3.new(distance * 0.7, distance * 0.4, distance * 0.7)
    
    camera.CFrame = CFrame.lookAt(cameraPosition, modelCFrame.Position)
end

function PetDiscoveryService:ShowDiscoveryPopup(discovery)
    isShowingDiscovery = true
    
    -- Play discovery sound at the start of popup creation
    playDiscoverySound()
    
    -- Get pet config for rarity and variation colors
    local petConfig = self:FindPetByName(discovery.name)
    if not petConfig then
        isShowingDiscovery = false
        return
    end
    
    local rarityColor = PetConstants.getRarityColor(petConfig.Rarity)
    local variationColor = discovery.variation and PetConstants.getVariationColor(discovery.variation) or PetConstants.getVariationColor("Bronze")
    
    -- Extract actual pet name (remove variation suffix)
    local actualPetName = discovery.name
    local variations = {"Bronze", "Silver", "Gold", "Platinum", "Diamond", "Emerald", "Sapphire", "Ruby", "Titanium", "Obsidian", "Crystal", "Rainbow", "Cosmic", "Void", "Divine"}
    for _, variation in pairs(variations) do
        if string.find(discovery.name, variation .. "$") then
            actualPetName = string.gsub(discovery.name, variation .. "$", "")
            break
        end
    end
    
    -- Create popup GUI
    local popupGui = Instance.new("ScreenGui")
    popupGui.Name = "PetDiscoveryPopup"
    popupGui.ResetOnSpawn = false
    popupGui.IgnoreGuiInset = true
    popupGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    popupGui.Parent = playerGui
    
    -- Main popup frame with expanding animation
    local popupFrame = Instance.new("Frame")
    popupFrame.Name = "PopupFrame"
    popupFrame.Size = UDim2.new(0, 0, 0, 0) -- Start at size 0 for expanding animation
    popupFrame.Position = UDim2.new(0.5, 0, 0.85, 0) -- Bottom-middle of screen
    popupFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    popupFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- Dark background
    popupFrame.BackgroundTransparency = 0.1
    popupFrame.BorderSizePixel = 0
    popupFrame.ZIndex = 1000
    popupFrame.Parent = popupGui
    
    -- Rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(20))
    corner.Parent = popupFrame
    
    -- Drop shadow
    local shadow = Instance.new("UIStroke")
    shadow.Color = Color3.fromRGB(0, 0, 0)
    shadow.Thickness = math.max(2, ScreenUtils.getScaleFactor() * 4)
    shadow.Transparency = 0.5
    shadow.Parent = popupFrame
    
    -- Rainbow gradient border for excitement
    local gradientBorder = Instance.new("UIStroke")
    gradientBorder.Color = Color3.fromRGB(255, 255, 255)
    gradientBorder.Thickness = math.max(3, ScreenUtils.getScaleFactor() * 5)
    gradientBorder.Transparency = 0.3
    gradientBorder.Parent = popupFrame
    
    local rainbowGradient = Instance.new("UIGradient")
    rainbowGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),     -- Red
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 165, 0)), -- Orange
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)), -- Yellow
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),   -- Green
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),  -- Blue
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)), -- Indigo
        ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 0, 211))    -- Violet
    })
    rainbowGradient.Parent = gradientBorder
    
    -- Pet viewport (left side)
    local petViewport = Instance.new("ViewportFrame")
    petViewport.Name = "PetViewport"
    petViewport.Size = ScreenUtils.udim2(0, ScreenUtils.getProportionalSize(200), 0, ScreenUtils.getProportionalSize(200))
    petViewport.Position = ScreenUtils.udim2(0, ScreenUtils.getProportionalSize(20), 0, ScreenUtils.getProportionalSize(40))
    petViewport.BackgroundTransparency = 1
    petViewport.ZIndex = 1001
    petViewport.Parent = popupFrame
    
    -- Create pet model and setup viewport
    local petModel = self:CreatePetModelForDiscovery(actualPetName)
    if petModel then
        petModel.Parent = petViewport
        self:SetupDiscoveryViewportCamera(petViewport, petModel)
    end
    
    -- "New Pet Discovered!" title (top center)
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = ScreenUtils.udim2(1, -ScreenUtils.getProportionalSize(40), 0, ScreenUtils.getProportionalSize(40))
    titleLabel.Position = ScreenUtils.udim2(0, ScreenUtils.getProportionalSize(20), 0, ScreenUtils.getProportionalSize(10))
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = discovery.variation and "🌟 NEW VARIATION DISCOVERED! 🌟" or "🎉 NEW PET DISCOVERED! 🎉"
    titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
    titleLabel.TextSize = ScreenUtils.TEXT_SIZES.HEADER()
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    titleLabel.ZIndex = 1001
    titleLabel.Parent = popupFrame
    
    -- Info panel (right side of viewport)
    local infoPanel = Instance.new("Frame")
    infoPanel.Name = "InfoPanel"
    infoPanel.Size = ScreenUtils.udim2(0, ScreenUtils.getProportionalSize(240), 0, ScreenUtils.getProportionalSize(180))
    infoPanel.Position = ScreenUtils.udim2(0, ScreenUtils.getProportionalSize(240), 0, ScreenUtils.getProportionalSize(60))
    infoPanel.BackgroundTransparency = 1
    infoPanel.ZIndex = 1001
    infoPanel.Parent = popupFrame
    
    -- Pet name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "PetName"
    nameLabel.Size = ScreenUtils.udim2(1, 0, 0, ScreenUtils.getProportionalSize(50))
    nameLabel.Position = ScreenUtils.udim2(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = actualPetName
    nameLabel.TextColor3 = rarityColor
    nameLabel.TextSize = ScreenUtils.TEXT_SIZES.HEADER() * 0.85 -- Use proportional sizing instead of subtraction
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.ZIndex = 1002
    nameLabel.Parent = infoPanel
    
    -- Variation (if applicable)
    local yOffset = ScreenUtils.getProportionalSize(50)
    if discovery.variation then
        local variationLabel = Instance.new("TextLabel")
        variationLabel.Name = "Variation"
        variationLabel.Size = ScreenUtils.udim2(1, 0, 0, ScreenUtils.getProportionalSize(30))
        variationLabel.Position = ScreenUtils.udim2(0, 0, 0, yOffset)
        variationLabel.BackgroundTransparency = 1
        variationLabel.Text = discovery.variation .. " Variation"
        variationLabel.TextColor3 = variationColor
        variationLabel.TextSize = ScreenUtils.TEXT_SIZES.LARGE()
        variationLabel.Font = Enum.Font.GothamBold
        variationLabel.TextXAlignment = Enum.TextXAlignment.Center
        variationLabel.TextStrokeTransparency = 0
        variationLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        variationLabel.ZIndex = 1002
        variationLabel.Parent = infoPanel
        yOffset = yOffset + ScreenUtils.getProportionalSize(35)
    end
    
    -- Rarity info with separate labels for "Rarity:" and the actual rarity
    local rarityChance = PetConstants.getRarityChance and PetConstants.getRarityChance(petConfig.Rarity) or 1000000
    
    -- "Rarity:" label in grey
    local rarityPrefixLabel = Instance.new("TextLabel")
    rarityPrefixLabel.Name = "RarityPrefix"
    rarityPrefixLabel.Size = ScreenUtils.udim2(0.4, 0, 0, ScreenUtils.getProportionalSize(25))
    rarityPrefixLabel.Position = ScreenUtils.udim2(0, 0, 0, yOffset)
    rarityPrefixLabel.BackgroundTransparency = 1
    rarityPrefixLabel.Text = "Rarity:"
    rarityPrefixLabel.TextColor3 = Color3.fromRGB(150, 150, 150) -- Grey color
    rarityPrefixLabel.TextSize = ScreenUtils.TEXT_SIZES.MEDIUM()
    rarityPrefixLabel.Font = Enum.Font.Gotham
    rarityPrefixLabel.TextXAlignment = Enum.TextXAlignment.Right
    rarityPrefixLabel.TextStrokeTransparency = 0
    rarityPrefixLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    rarityPrefixLabel.ZIndex = 1002
    rarityPrefixLabel.Parent = infoPanel
    
    -- Actual rarity value in rarity color
    local rarityValueLabel = Instance.new("TextLabel")
    rarityValueLabel.Name = "RarityValue"
    rarityValueLabel.Size = ScreenUtils.udim2(0.6, 0, 0, ScreenUtils.getProportionalSize(25))
    rarityValueLabel.Position = ScreenUtils.udim2(0.4, ScreenUtils.getProportionalSize(5), 0, yOffset)
    rarityValueLabel.BackgroundTransparency = 1
    rarityValueLabel.Text = petConfig.Rarity
    rarityValueLabel.TextColor3 = rarityColor -- Bright rarity color
    rarityValueLabel.TextSize = ScreenUtils.TEXT_SIZES.MEDIUM()
    rarityValueLabel.Font = Enum.Font.GothamBold
    rarityValueLabel.TextXAlignment = Enum.TextXAlignment.Left
    rarityValueLabel.TextStrokeTransparency = 0
    rarityValueLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    rarityValueLabel.ZIndex = 1002
    rarityValueLabel.Parent = infoPanel
    yOffset = yOffset + ScreenUtils.getProportionalSize(30)
    
    -- Chance info with bigger text and rainbow colors
    local chanceLabel = Instance.new("TextLabel")
    chanceLabel.Name = "Chance"
    chanceLabel.Size = ScreenUtils.udim2(1, 0, 0, ScreenUtils.getProportionalSize(35)) -- Taller for bigger text
    chanceLabel.Position = ScreenUtils.udim2(0, 0, 0, yOffset)
    chanceLabel.BackgroundTransparency = 1
    chanceLabel.Text = "1 in " .. NumberFormatter.format(rarityChance)
    chanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White base for rainbow gradient
    chanceLabel.TextSize = ScreenUtils.TEXT_SIZES.LARGE() -- Bigger text size
    chanceLabel.Font = Enum.Font.GothamBold -- Bold font
    chanceLabel.TextXAlignment = Enum.TextXAlignment.Center
    chanceLabel.TextStrokeTransparency = 0
    chanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    chanceLabel.ZIndex = 1002
    chanceLabel.Parent = infoPanel
    
    -- Rainbow gradient for chance text
    local chanceGradient = Instance.new("UIGradient")
    chanceGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),     -- Red
        ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 127, 0)), -- Orange
        ColorSequenceKeypoint.new(0.32, Color3.fromRGB(255, 255, 0)), -- Yellow
        ColorSequenceKeypoint.new(0.48, Color3.fromRGB(0, 255, 0)),   -- Green
        ColorSequenceKeypoint.new(0.64, Color3.fromRGB(0, 255, 255)), -- Cyan
        ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0, 0, 255)),   -- Blue
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255))    -- Magenta
    })
    chanceGradient.Rotation = 0 -- Horizontal gradient
    chanceGradient.Parent = chanceLabel
    yOffset = yOffset + ScreenUtils.getProportionalSize(45) -- More space for bigger text
    
    -- Congratulations message
    local congratsLabel = Instance.new("TextLabel")
    congratsLabel.Name = "Congrats"
    congratsLabel.Size = ScreenUtils.udim2(1, 0, 0, ScreenUtils.getProportionalSize(40))
    congratsLabel.Position = ScreenUtils.udim2(0, 0, 0, yOffset)
    congratsLabel.BackgroundTransparency = 1
    congratsLabel.Text = "Check your Pet Index!"
    congratsLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Bright green
    congratsLabel.TextSize = ScreenUtils.TEXT_SIZES.MEDIUM()
    congratsLabel.Font = Enum.Font.GothamBold
    congratsLabel.TextXAlignment = Enum.TextXAlignment.Center
    congratsLabel.TextStrokeTransparency = 0
    congratsLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    congratsLabel.ZIndex = 1002
    congratsLabel.Parent = infoPanel
    
    -- AMAZING EXPANDING ANIMATION from center outward!
    local finalSize = ScreenUtils.udim2(0, ScreenUtils.getProportionalSize(500), 0, ScreenUtils.getProportionalSize(260)) -- Final popup size
    
    -- Create expanding animation with Back easing for satisfying effect
    local expandTween = TweenService:Create(popupFrame, TweenInfo.new(
        0.8, -- Duration
        Enum.EasingStyle.Back, -- Back easing for overshoot effect
        Enum.EasingDirection.Out, -- Out direction
        0, -- No repeat
        false, -- No reverse
        0 -- No delay
    ), {
        Size = finalSize
    })
    
    -- Add pet model rotation animation
    local function animatePetModel()
        if petModel then
            task.spawn(function()
                while petModel.Parent and popupFrame.Parent do
                    for _, descendant in pairs(petModel:GetDescendants()) do
                        if descendant:IsA("BasePart") then
                            local currentCFrame = descendant.CFrame
                            local rotationIncrement = CFrame.Angles(0, math.rad(1), 0)
                            descendant.CFrame = currentCFrame * rotationIncrement
                        end
                    end
                    task.wait(0.03) -- Smooth rotation
                end
            end)
        end
    end
    
    -- Rainbow border pulsing animation
    local function animateRainbowBorder()
        task.spawn(function()
            local rotationTween = TweenService:Create(rainbowGradient, TweenInfo.new(
                3, -- 3 second rotation
                Enum.EasingStyle.Linear,
                Enum.EasingDirection.InOut,
                -1, -- Infinite repeat
                false, -- No reverse
                0
            ), {
                Rotation = 360
            })
            rotationTween:Play()
        end)
    end
    
    -- Start expanding animation
    expandTween:Play()
    
    -- Start secondary animations when expand completes
    expandTween.Completed:Connect(function()
        animatePetModel()
        animateRainbowBorder()
    end)
    
    -- Auto-dismiss after 4 seconds (longer to enjoy the new popup)
    task.spawn(function()
        task.wait(4)
        
        -- Shrinking animation (reverse of expanding)
        local shrinkTween = TweenService:Create(popupFrame, TweenInfo.new(
            0.5,
            Enum.EasingStyle.Back,
            Enum.EasingDirection.In
        ), {
            Size = UDim2.new(0, 0, 0, 0) -- Shrink back to nothing
        })
        
        shrinkTween:Play()
        shrinkTween.Completed:Connect(function()
            popupGui:Destroy()
            isShowingDiscovery = false
        end)
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