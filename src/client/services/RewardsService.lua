-- RewardsService - Shows reward popups for various reward types (Money, Diamonds, Pet, Rebirth)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local GradientUtils = require(ReplicatedStorage.utils.GradientUtils)
local PotionConfig = require(ReplicatedStorage.config.PotionConfig)

local RewardsService = {}
RewardsService.__index = RewardsService

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Reward queue to prevent spam
local rewardQueue = {}
local isShowingReward = false

-- Anti-spam system - track last popup time 
local lastPopupTime = 0
local POPUP_COOLDOWN = 2 -- 2 seconds between popups

-- Sound configuration
local REWARD_SOUND_ID = "rbxassetid://5728423829" -- Same celebratory sound as pet discovery

-- Pre-create reward sound for instant playback
local rewardSound = Instance.new("Sound")
rewardSound.SoundId = REWARD_SOUND_ID
rewardSound.Volume = 0.8 -- Celebratory volume
rewardSound.Parent = SoundService

-- Play reward sound instantly
local function playRewardSound()
    rewardSound:Play()
end

function RewardsService:Initialize()
    -- Set up remote event listener for server-triggered rewards
    local showRewardRemote = ReplicatedStorage:WaitForChild("ShowReward")
    showRewardRemote.OnClientEvent:Connect(function(rewardData)
        self:ShowReward(rewardData)
    end)
    
    -- RewardsService ready
end

-- Show reward popup for any reward type
function RewardsService:ShowReward(rewardData)
    -- Validate reward data
    if not rewardData or not rewardData.type or not rewardData.amount then
        warn("RewardsService: Invalid reward data")
        return
    end
    
    -- Anti-spam check
    local currentTime = tick()
    if currentTime - lastPopupTime < POPUP_COOLDOWN then
        -- Queue the reward for later
        table.insert(rewardQueue, rewardData)
        self:ProcessQueue()
        return
    end
    
    -- If already showing a reward, queue this one
    if isShowingReward then
        table.insert(rewardQueue, rewardData)
        return
    end
    
    -- Update last popup time
    lastPopupTime = currentTime
    
    -- Show the reward popup
    self:ShowRewardPopup(rewardData)
end

-- Process queued rewards
function RewardsService:ProcessQueue()
    if isShowingReward or #rewardQueue == 0 then
        return
    end
    
    local currentTime = tick()
    if currentTime - lastPopupTime < POPUP_COOLDOWN then
        -- Wait and try again
        task.spawn(function()
            task.wait(POPUP_COOLDOWN - (currentTime - lastPopupTime))
            self:ProcessQueue()
        end)
        return
    end
    
    -- Show next reward in queue
    local nextReward = table.remove(rewardQueue, 1)
    if nextReward then
        lastPopupTime = currentTime
        self:ShowRewardPopup(nextReward)
    end
end

-- Helper function to create pet model for reward viewport (same as PetDiscoveryService)
function RewardsService:CreatePetModelForReward(petName)
    local petsFolder = ReplicatedStorage:FindFirstChild("Pets")
    if not petsFolder then return nil end
    
    local petModelTemplate = petsFolder:FindFirstChild(petName)
    if not petModelTemplate then
        petModelTemplate = petsFolder:GetChildren()[1]
    end
    
    if petModelTemplate then
        local clonedModel = petModelTemplate:Clone()
        clonedModel.Name = "RewardPetModel"
        
        -- Scale for reward viewport (bigger for impressive display)
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

-- Setup viewport camera for reward popup (same as PetDiscoveryService)
function RewardsService:SetupRewardViewportCamera(viewportFrame, petModel)
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

-- Get reward display properties based on type
function RewardsService:GetRewardDisplayInfo(rewardData)
    local displayInfo = {
        title = "🎉 REWARD CLAIMED! 🎉",
        mainText = "",
        subText = "",
        icon = "",
        iconColor = Color3.fromRGB(255, 255, 255),
        sourceText = rewardData.source or "Playtime Rewards",
        showViewport = false,
        petName = nil
    }
    
    if rewardData.type == "Money" then
        displayInfo.title = "💰 MONEY REWARD! 💰"
        displayInfo.mainText = NumberFormatter.format(rewardData.amount)
        displayInfo.subText = "Money"
        displayInfo.icon = IconAssets.getIcon("CURRENCY", "MONEY")
        displayInfo.iconColor = Color3.fromRGB(255, 215, 0) -- Gold color
        
    elseif rewardData.type == "Diamonds" then
        displayInfo.title = "💎 DIAMOND REWARD! 💎"
        displayInfo.mainText = NumberFormatter.format(rewardData.amount)
        displayInfo.subText = "Diamonds"
        displayInfo.icon = IconAssets.getIcon("CURRENCY", "DIAMONDS")
        displayInfo.iconColor = Color3.fromRGB(0, 191, 255) -- Diamond blue
        
    elseif rewardData.type == "Pet" then
        displayInfo.title = "🐾 PET REWARD! 🐾"
        displayInfo.mainText = rewardData.petName or "Pet"
        displayInfo.subText = "New Pet!"
        displayInfo.showViewport = true
        displayInfo.petName = rewardData.petName
        
    elseif rewardData.type == "Rebirth" then
        displayInfo.title = "🔄 REBIRTH REWARD! 🔄"
        displayInfo.mainText = NumberFormatter.format(rewardData.amount) .. " Rebirth" .. (rewardData.amount > 1 and "s" or "")
        displayInfo.subText = "Instant Rebirth!"
        displayInfo.icon = IconAssets.getIcon("UI", "REBIRTH")
        displayInfo.iconColor = Color3.fromRGB(255, 165, 0) -- Orange color
        
    elseif rewardData.type == "Potion" then
        local potionConfig = PotionConfig.GetPotion(rewardData.potionId)
        if potionConfig then
            displayInfo.title = "🧪 POTION REWARD! 🧪"
            displayInfo.mainText = potionConfig.Name
            local boostText = potionConfig.BoostType == PotionConfig.BoostTypes.PET_MAGNET and potionConfig.BoostType or (PotionConfig.FormatBoostAmount(potionConfig.BoostAmount, potionConfig.BoostType) .. " " .. potionConfig.BoostType)
            displayInfo.subText = "x" .. (rewardData.amount or 1) .. " - " .. boostText
            displayInfo.icon = potionConfig.Icon
            displayInfo.iconColor = PotionConfig.GetRarityColor(potionConfig.Rarity)
        else
            displayInfo.title = "🧪 POTION REWARD! 🧪"
            displayInfo.mainText = "Unknown Potion"
            displayInfo.subText = "x" .. (rewardData.amount or 1)
            displayInfo.icon = "rbxassetid://104089702525726" -- Default diamond potion icon
            displayInfo.iconColor = Color3.fromRGB(200, 200, 200) -- Gray for unknown
        end
    end
    
    return displayInfo
end

function RewardsService:ShowRewardPopup(rewardData)
    isShowingReward = true
    
    -- Play reward sound at the start of popup creation
    playRewardSound()
    
    -- Get display information for this reward type
    local displayInfo = self:GetRewardDisplayInfo(rewardData)
    
    -- Create popup GUI
    local popupGui = Instance.new("ScreenGui")
    popupGui.Name = "RewardPopup"
    popupGui.ResetOnSpawn = false
    popupGui.IgnoreGuiInset = true
    popupGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    popupGui.Parent = playerGui
    
    -- Main popup frame with expanding animation
    local popupFrame = Instance.new("Frame")
    popupFrame.Name = "PopupFrame"
    popupFrame.Size = UDim2.new(0, 0, 0, 0) -- Start at size 0 for expanding animation
    popupFrame.Position = UDim2.new(0.5, 0, 0.75, 0) -- Bottom-middle with padding from screen edge
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
    gradientBorder.Thickness = 5 -- Fixed thickness instead of double scaling
    gradientBorder.Transparency = 0.3
    gradientBorder.Parent = popupFrame
    
    local rainbowGradient = Instance.new("UIGradient")
    rainbowGradient.Parent = gradientBorder
    GradientUtils.ApplyGradient(GradientUtils.RAINBOW, rainbowGradient)
    
    -- Icon/Viewport (left side)
    local iconOrViewport
    if displayInfo.showViewport then
        -- Pet viewport
        iconOrViewport = Instance.new("ViewportFrame")
        iconOrViewport.Name = "PetViewport"
        iconOrViewport.Size = ScreenUtils.udim2(0, 300, 0, 300) -- Fixed: removed double scaling
        iconOrViewport.Position = ScreenUtils.udim2(0, 25, 0, 50) -- Fixed: removed double scaling
        iconOrViewport.BackgroundTransparency = 1
        iconOrViewport.ZIndex = 1001
        iconOrViewport.Parent = popupFrame
        
        -- Create pet model and setup viewport
        local petModel = self:CreatePetModelForReward(displayInfo.petName)
        if petModel then
            petModel.Parent = iconOrViewport
            self:SetupRewardViewportCamera(iconOrViewport, petModel)
        end
    else
        -- Icon display
        iconOrViewport = Instance.new("ImageLabel")
        iconOrViewport.Name = "RewardIcon"
        iconOrViewport.Size = ScreenUtils.udim2(0, 250, 0, 250) -- Fixed: removed double scaling
        iconOrViewport.Position = ScreenUtils.udim2(0, 50, 0, 75) -- Fixed: removed double scaling
        iconOrViewport.BackgroundTransparency = 1
        iconOrViewport.Image = displayInfo.icon
        iconOrViewport.ImageColor3 = displayInfo.iconColor
        iconOrViewport.ScaleType = Enum.ScaleType.Fit
        iconOrViewport.ZIndex = 1001
        iconOrViewport.Parent = popupFrame
    end
    
    -- Title (top center)
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = ScreenUtils.udim2(1, -60, 0, 60) -- Fixed: removed double scaling
    titleLabel.Position = ScreenUtils.udim2(0, 30, 0, 15) -- Fixed: removed double scaling
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = displayInfo.title
    titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
    titleLabel.TextSize = ScreenUtils.TEXT_SIZES.HEADER() * 1.5
    titleLabel.Font = Enum.Font.FredokaOne
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    titleLabel.ZIndex = 1001
    titleLabel.Parent = popupFrame
    
    -- Info panel (right side of icon/viewport)
    local infoPanel = Instance.new("Frame")
    infoPanel.Name = "InfoPanel"
    infoPanel.Size = ScreenUtils.udim2(0, 360, 0, 270) -- Fixed: removed double scaling
    infoPanel.Position = ScreenUtils.udim2(0, 350, 0, 75) -- Fixed: removed double scaling
    infoPanel.BackgroundTransparency = 1
    infoPanel.ZIndex = 1001
    infoPanel.Parent = popupFrame
    
    -- Main reward text (amount/pet name)
    local mainLabel = Instance.new("TextLabel")
    mainLabel.Name = "MainReward"
    mainLabel.Size = ScreenUtils.udim2(1, 0, 0, 90) -- Fixed: removed double scaling
    mainLabel.Position = ScreenUtils.udim2(0, 0, 0, 0)
    mainLabel.BackgroundTransparency = 1
    mainLabel.Text = displayInfo.mainText
    mainLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White for rainbow gradient
    mainLabel.TextSize = ScreenUtils.TEXT_SIZES.HEADER() * 1.4
    mainLabel.Font = Enum.Font.FredokaOne
    mainLabel.TextXAlignment = Enum.TextXAlignment.Center
    mainLabel.TextStrokeTransparency = 0
    mainLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    mainLabel.ZIndex = 1002
    mainLabel.Parent = infoPanel
    
    -- Rainbow gradient for main text
    local mainGradient = Instance.new("UIGradient")
    mainGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),     -- Red
        ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 127, 0)), -- Orange
        ColorSequenceKeypoint.new(0.32, Color3.fromRGB(255, 255, 0)), -- Yellow
        ColorSequenceKeypoint.new(0.48, Color3.fromRGB(0, 255, 0)),   -- Green
        ColorSequenceKeypoint.new(0.64, Color3.fromRGB(0, 255, 255)), -- Cyan
        ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0, 0, 255)),   -- Blue
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255))    -- Magenta
    })
    mainGradient.Rotation = 0
    mainGradient.Parent = mainLabel
    
    -- Sub text (reward type)
    local subLabel = Instance.new("TextLabel")
    subLabel.Name = "SubText"
    subLabel.Size = ScreenUtils.udim2(1, 0, 0, 50) -- Fixed: removed double scaling
    subLabel.Position = ScreenUtils.udim2(0, 0, 0, 95) -- Fixed: removed double scaling
    subLabel.BackgroundTransparency = 1
    subLabel.Text = displayInfo.subText
    subLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    subLabel.TextSize = ScreenUtils.TEXT_SIZES.LARGE() * 1.3
    subLabel.Font = Enum.Font.FredokaOne
    subLabel.TextXAlignment = Enum.TextXAlignment.Center
    subLabel.TextStrokeTransparency = 0
    subLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    subLabel.ZIndex = 1002
    subLabel.Parent = infoPanel
    
    -- Source text (where the reward came from)
    local sourceLabel = Instance.new("TextLabel")
    sourceLabel.Name = "Source"
    sourceLabel.Size = ScreenUtils.udim2(1, 0, 0, 40) -- Fixed: removed double scaling
    sourceLabel.Position = ScreenUtils.udim2(0, 0, 0, 160) -- Fixed: removed double scaling
    sourceLabel.BackgroundTransparency = 1
    sourceLabel.Text = "From: " .. displayInfo.sourceText
    sourceLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    sourceLabel.TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() * 1.2
    sourceLabel.Font = Enum.Font.Gotham
    sourceLabel.TextXAlignment = Enum.TextXAlignment.Center
    sourceLabel.TextStrokeTransparency = 0
    sourceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    sourceLabel.ZIndex = 1002
    sourceLabel.Parent = infoPanel
    
    -- Congratulations message
    local congratsLabel = Instance.new("TextLabel")
    congratsLabel.Name = "Congrats"
    congratsLabel.Size = ScreenUtils.udim2(1, 0, 0, 60) -- Fixed: removed double scaling
    congratsLabel.Position = ScreenUtils.udim2(0, 0, 0, 210) -- Fixed: removed double scaling
    congratsLabel.BackgroundTransparency = 1
    congratsLabel.Text = "Reward Added!"
    congratsLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Bright green
    congratsLabel.TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() * 1.5
    congratsLabel.Font = Enum.Font.FredokaOne
    congratsLabel.TextXAlignment = Enum.TextXAlignment.Center
    congratsLabel.TextStrokeTransparency = 0
    congratsLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    congratsLabel.ZIndex = 1002
    congratsLabel.Parent = infoPanel
    
    -- AMAZING POP OUT ANIMATION - Every element animates individually!
    local finalSize = ScreenUtils.udim2(0, 750, 0, 390) -- Fixed: removed double scaling
    
    -- Set all elements to start invisible/small for pop-out effect
    local elementsToAnimate = {
        {element = titleLabel, delay = 0.1, type = "scale"},
        {element = iconOrViewport, delay = 0.2, type = "fade_in"},
        {element = mainLabel, delay = 0.3, type = "slide_right"},
        {element = subLabel, delay = 0.4, type = "slide_right"},
        {element = sourceLabel, delay = 0.5, type = "bounce"},
        {element = congratsLabel, delay = 0.6, type = "fade_in"}
    }
    
    -- Store original properties for animation
    local originalProperties = {}
    for _, animData in ipairs(elementsToAnimate) do
        local element = animData.element
        if element then
            originalProperties[element] = {
                Size = element.Size,
                Position = element.Position,
                BackgroundTransparency = element.BackgroundTransparency or 1
            }
            
            -- Only store text properties for TextLabels
            if element:IsA("TextLabel") then
                originalProperties[element].TextTransparency = element.TextTransparency or 0
                originalProperties[element].TextStrokeTransparency = element.TextStrokeTransparency or 0
            elseif element:IsA("ImageLabel") then
                originalProperties[element].ImageTransparency = element.ImageTransparency or 0
            end
            
            -- Set initial animation states
            if animData.type == "scale" then
                element.Size = UDim2.new(0, 0, 0, 0)
            elseif animData.type == "slide_right" then
                element.Position = element.Position - UDim2.new(0, ScreenUtils.getProportionalSize(50), 0, 0)
                if element:IsA("TextLabel") then
                    element.TextTransparency = 1
                    element.TextStrokeTransparency = 1
                elseif element:IsA("ImageLabel") then
                    element.ImageTransparency = 1
                else
                    element.BackgroundTransparency = 1
                end
            elseif animData.type == "bounce" then
                element.Size = UDim2.new(0, 0, 0, 0)
                if element:IsA("TextLabel") then
                    element.TextTransparency = 1
                    element.TextStrokeTransparency = 1
                elseif element:IsA("ImageLabel") then
                    element.ImageTransparency = 1
                else
                    element.BackgroundTransparency = 1
                end
            elseif animData.type == "fade_in" then
                if element:IsA("TextLabel") then
                    element.TextTransparency = 1
                    element.TextStrokeTransparency = 1
                elseif element:IsA("ImageLabel") then
                    element.ImageTransparency = 1
                else
                    element.BackgroundTransparency = 1
                end
            end
        end
    end
    
    -- Create main popup frame expansion
    local expandTween = TweenService:Create(popupFrame, TweenInfo.new(
        0.6, -- Faster main expansion
        Enum.EasingStyle.Back,
        Enum.EasingDirection.Out
    ), {
        Size = finalSize
    })
    
    -- Add pet model rotation animation (if it's a pet reward)
    local function animatePetModel()
        if displayInfo.showViewport and iconOrViewport:FindFirstChild("RewardPetModel") then
            local petModel = iconOrViewport:FindFirstChild("RewardPetModel")
            task.spawn(function()
                while petModel and petModel.Parent and popupFrame.Parent do
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
    
    -- Start main popup expansion
    expandTween:Play()
    
    -- Create individual element animations (same system as PetDiscoveryService)
    local function createElementAnimation(animData)
        local element = animData.element
        if not element then return end
        
        task.spawn(function()
            task.wait(animData.delay)
            
            if animData.type == "scale" then
                -- Scale from 0 to full size with bounce
                local originalSize = originalProperties[element].Size
                
                local scaleTween = TweenService:Create(element, TweenInfo.new(
                    0.4,
                    Enum.EasingStyle.Back,
                    Enum.EasingDirection.Out
                ), {
                    Size = originalSize
                })
                scaleTween:Play()
                
            elseif animData.type == "slide_right" then
                -- Slide in from left with fade
                local originalPos = originalProperties[element].Position
                local tweenProperties = {Position = originalPos}
                
                if element:IsA("TextLabel") then
                    tweenProperties.TextTransparency = originalProperties[element].TextTransparency
                    tweenProperties.TextStrokeTransparency = originalProperties[element].TextStrokeTransparency
                elseif element:IsA("ImageLabel") then
                    tweenProperties.ImageTransparency = originalProperties[element].ImageTransparency or 0
                else
                    tweenProperties.BackgroundTransparency = originalProperties[element].BackgroundTransparency
                end
                
                local slideTween = TweenService:Create(element, TweenInfo.new(
                    0.3,
                    Enum.EasingStyle.Quad,
                    Enum.EasingDirection.Out
                ), tweenProperties)
                slideTween:Play()
                
            elseif animData.type == "bounce" then
                -- Big bounce effect
                local originalSize = originalProperties[element].Size
                local tweenProperties = {Size = originalSize}
                
                if element:IsA("TextLabel") then
                    tweenProperties.TextTransparency = originalProperties[element].TextTransparency
                    tweenProperties.TextStrokeTransparency = originalProperties[element].TextStrokeTransparency
                elseif element:IsA("ImageLabel") then
                    tweenProperties.ImageTransparency = originalProperties[element].ImageTransparency or 0
                else
                    tweenProperties.BackgroundTransparency = originalProperties[element].BackgroundTransparency
                end
                
                local bounceTween = TweenService:Create(element, TweenInfo.new(
                    0.5,
                    Enum.EasingStyle.Elastic,
                    Enum.EasingDirection.Out
                ), tweenProperties)
                bounceTween:Play()
                
            elseif animData.type == "fade_in" then
                -- Simple fade in
                local tweenProperties = {}
                if element:IsA("TextLabel") then
                    tweenProperties.TextTransparency = originalProperties[element].TextTransparency
                    tweenProperties.TextStrokeTransparency = originalProperties[element].TextStrokeTransparency
                elseif element:IsA("ImageLabel") then
                    tweenProperties.ImageTransparency = originalProperties[element].ImageTransparency or 0
                else
                    tweenProperties.BackgroundTransparency = originalProperties[element].BackgroundTransparency
                end
                
                local fadeTween = TweenService:Create(element, TweenInfo.new(
                    0.4,
                    Enum.EasingStyle.Quad,
                    Enum.EasingDirection.Out
                ), tweenProperties)
                fadeTween:Play()
            end
        end)
    end
    
    -- Start all individual element animations
    for _, animData in ipairs(elementsToAnimate) do
        createElementAnimation(animData)
    end
    
    -- Start secondary animations after main expansion
    expandTween.Completed:Connect(function()
        animatePetModel()
        animateRainbowBorder()
    end)
    
    -- Auto-dismiss after 4 seconds
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
            isShowingReward = false
            
            -- Process next reward in queue
            self:ProcessQueue()
        end)
    end)
end

function RewardsService:Cleanup()
    -- Clear reward queue
    rewardQueue = {}
    isShowingReward = false
end

-- Handle character respawn
Players.LocalPlayer.CharacterAdded:Connect(function()
    -- Re-initialize after character respawn
    RewardsService:Cleanup()
    task.wait(1) -- Wait for character to fully load
    RewardsService:Initialize()
end)

return RewardsService