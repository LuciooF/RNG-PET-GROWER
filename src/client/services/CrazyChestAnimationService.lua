-- CrazyChestAnimationService - Animates the existing cards in the chest UI
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local CrazyChestConfig = require(ReplicatedStorage.config.CrazyChestConfig)

-- Sound configuration
local HOVER_SOUND_ID = "rbxassetid://6895079853"

-- Pre-create hover sound for instant playback
local hoverSound = Instance.new("Sound")
hoverSound.SoundId = HOVER_SOUND_ID
hoverSound.Volume = 0.3 -- Quieter for rapid succession
hoverSound.Parent = SoundService

local CrazyChestAnimationService = {}
CrazyChestAnimationService.isAnimating = false

local WINNING_POSITION = 38 -- The position where the winning card will always land

function CrazyChestAnimationService:Initialize()
    -- Silent initialization for performance
end

function CrazyChestAnimationService:StartCaseOpeningAnimation(roll, reward)
    if self.isAnimating then 
        warn("CrazyChestAnimationService: Animation already running!")
        return 
    end
    
    self.isAnimating = true
    
    -- Print reward info
    if reward.type == "money" then
        print("CrazyChestAnimationService: Starting animation - Roll:", roll, "Reward:", reward.money, "money")
    else
        print("CrazyChestAnimationService: Starting animation - Roll:", roll, "Reward:", reward.diamonds, "diamonds")
    end
    
    -- Find the existing reward strip in the UI
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local rewardStrip = nil
    
    -- Search for the RewardStrip in any ScreenGui
    for _, gui in pairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            local function findRewardStrip(parent)
                for _, child in pairs(parent:GetChildren()) do
                    if child.Name == "RewardStrip" and child:IsA("ScrollingFrame") then
                        return child
                    end
                    local found = findRewardStrip(child)
                    if found then return found end
                end
                return nil
            end
            
            rewardStrip = findRewardStrip(gui)
            if rewardStrip then
                print("CrazyChestAnimationService: Found RewardStrip!")
                break
            end
        end
    end
    
    if not rewardStrip then
        warn("CrazyChestAnimationService: RewardStrip not found!")
        self.isAnimating = false
        return
    end
    
    -- Replace the card at the winning position with the actual reward
    local winningCard = rewardStrip:FindFirstChild("RewardItem" .. WINNING_POSITION)
    if winningCard then
        -- Import NumberFormatter for consistent formatting
        local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)
        
        -- Update the background color and transparency to match the actual reward
        winningCard.BackgroundColor3 = reward.color or Color3.fromRGB(255, 255, 255)
        winningCard.BackgroundTransparency = reward.special == "rainbow" and 0.3 or 0.7 -- Less transparency for rainbow
        
        -- Add rainbow gradient to background for rainbow rewards
        if reward.special == "rainbow" then
            local existingGradient = winningCard:FindFirstChild("UIGradient")
            if existingGradient then
                existingGradient:Destroy()
            end
            
            local rainbowGradient = Instance.new("UIGradient")
            rainbowGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),     -- Red
                ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 127, 0)), -- Orange
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)), -- Yellow
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),    -- Green
                ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),   -- Blue
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)),  -- Indigo
                ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 0, 211))     -- Violet
            })
            rainbowGradient.Rotation = 45
            rainbowGradient.Parent = winningCard
        end
        
        -- Update the border color to match the reward rarity
        local stroke = winningCard:FindFirstChild("Stroke")
        if stroke then
            stroke.Color = reward.color or Color3.fromRGB(200, 200, 200)
        end
        
        -- Update the icon - handle pets vs currency properly
        if reward.type == "pet" then
            -- Remove currency icon if it exists
            local currencyIcon = winningCard:FindFirstChild("CurrencyIcon")
            if currencyIcon then
                currencyIcon:Destroy()
            end
            
            -- Create or update pet viewport
            local existingViewport = winningCard:FindFirstChild("PetModel")
            if existingViewport then
                existingViewport:Destroy()
            end
            
            -- Create new ViewportFrame for pet (same as in UI creation)
            local petViewport = Instance.new("ViewportFrame")
            petViewport.Name = "PetModel"
            petViewport.Size = UDim2.new(0, 70, 0, 70) -- Same size as animation cards
            petViewport.Position = UDim2.new(0.5, -35, 0, 15) -- Same position as animation cards
            petViewport.BackgroundTransparency = 1
            petViewport.ZIndex = 1025
            petViewport.Parent = winningCard
            
            -- Load the pet model asynchronously
            task.spawn(function()
                task.wait(0.1)
                
                local petsFolder = ReplicatedStorage:FindFirstChild("Pets")
                if petsFolder then
                    local petModelTemplate = petsFolder:FindFirstChild(reward.petName)
                    if petModelTemplate then
                        -- Same loading logic as UI cards
                        local model = petModelTemplate:Clone()
                        model.Name = "PetModel"
                        
                        -- Prepare model exactly like UI cards
                        if not model.PrimaryPart then
                            local largestPart = nil
                            local largestSize = 0
                            for _, part in pairs(model:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    local size = part.Size.X * part.Size.Y * part.Size.Z
                                    if size > largestSize then
                                        largestSize = size
                                        largestPart = part
                                    end
                                end
                            end
                            if largestPart then
                                model.PrimaryPart = largestPart
                            end
                        end
                        
                        for _, part in pairs(model:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                                part.Anchored = true
                                part.Massless = true
                            end
                        end
                        
                        -- Apply same rotation as UI cards
                        local modelCFrame, modelSize = model:GetBoundingBox()
                        local offset = modelCFrame.Position
                        for _, part in pairs(model:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.Position = part.Position - offset
                            end
                        end
                        
                        local rotationAngle = 120
                        for _, part in pairs(model:GetDescendants()) do
                            if part:IsA("BasePart") then
                                local rotationCFrame = CFrame.Angles(math.rad(20), math.rad(rotationAngle), 0)
                                local currentPos = part.Position
                                local rotatedPos = rotationCFrame * currentPos
                                part.Position = rotatedPos
                                part.CFrame = CFrame.new(rotatedPos) * rotationCFrame * (part.CFrame - part.Position)
                            end
                        end
                        
                        model.Parent = petViewport
                        
                        -- Same camera setup as UI cards
                        local camera = Instance.new("Camera")
                        camera.CameraType = Enum.CameraType.Scriptable
                        camera.CFrame = CFrame.new(0.1, -0.15, 10)
                        camera.FieldOfView = 90
                        camera.Parent = petViewport
                        petViewport.CurrentCamera = camera
                        
                        petViewport.LightDirection = Vector3.new(0, -0.1, -1).Unit
                        petViewport.Ambient = Color3.fromRGB(255, 255, 255)
                        petViewport.LightColor = Color3.fromRGB(255, 255, 255)
                        
                        print("CrazyChestAnimationService: Pet model loaded for winning card:", reward.petName)
                    end
                end
            end)
        else
            -- Handle currency icons
            local icon = winningCard:FindFirstChild("CurrencyIcon")
            if icon and icon:IsA("ImageLabel") then
                icon.Image = reward.type == "money" and "rbxassetid://80960000119108" or "rbxassetid://135421873302468"
            end
            
            -- Remove pet viewport if it exists (switching from pet to currency)
            local existingViewport = winningCard:FindFirstChild("PetModel")
            if existingViewport then
                existingViewport:Destroy()
            end
        end
        
        -- Update the text with proper formatting to match other cards
        local text = winningCard:FindFirstChild("RewardText")
        if text and text:IsA("TextLabel") then
            text.Text = reward.type == "pet" and (reward.boost .. "x Boost!") or 
                       (reward.type == "money" and (NumberFormatter.format(reward.money) .. " Money!") or 
                       (NumberFormatter.format(reward.diamonds) .. " Diamonds!"))
        end
        
        print("CrazyChestAnimationService: Updated winning card at position", WINNING_POSITION, "with proper formatting")
    end
    
    -- Calculate where to scroll to (center the winning card with random offset)
    local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
    local itemWidth = ScreenUtils.getProportionalSize(120)
    local itemSpacing = ScreenUtils.getProportionalSize(10)
    
    -- Base position to center card 38
    local basePosition = (WINNING_POSITION - 1) * (itemWidth + itemSpacing) - (rewardStrip.AbsoluteSize.X / 2) + (itemWidth / 2)
    
    -- Add biased random positioning - prefer edges for more drama
    local randomOffsetPercent = self:GetBiasedRandomPercent()
    local randomOffset = (randomOffsetPercent - 0.5) * itemWidth -- Center around the card
    local finalScrollPosition = basePosition + randomOffset
    
    -- Start from beginning
    rewardStrip.CanvasPosition = Vector2.new(0, 0)
    
    -- Create animation with sound tracking
    self:StartAnimationWithSounds(rewardStrip, finalScrollPosition, itemWidth, itemSpacing, winningCard, reward)
end

-- Get biased random percentage that prefers edges (0-10% and 90-100%)
function CrazyChestAnimationService:GetBiasedRandomPercent()
    local roll = math.random()
    
    -- 40% chance for early edge (0-10%)
    if roll < 0.4 then
        return math.random(0, 10) / 100
    -- 40% chance for late edge (90-100%) 
    elseif roll < 0.8 then
        return math.random(90, 100) / 100
    -- 20% chance for middle (10-90%)
    else
        return math.random(10, 90) / 100
    end
end

-- Animation with sound tracking for each card passed
function CrazyChestAnimationService:StartAnimationWithSounds(rewardStrip, finalPosition, itemWidth, itemSpacing, winningCard, reward)
    local cardSize = itemWidth + itemSpacing
    local startTime = tick()
    local duration = 6 -- 6 seconds
    local startPosition = 0
    local lastCardPassed = 0
    
    -- Track animation progress and play sounds
    local animationConnection
    animationConnection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        local progress = math.min(elapsed / duration, 1)
        
        -- Apply cubic easing (out) for smooth deceleration
        local easedProgress = 1 - math.pow(1 - progress, 3)
        
        -- Calculate current position
        local currentPosition = startPosition + (finalPosition - startPosition) * easedProgress
        rewardStrip.CanvasPosition = Vector2.new(currentPosition, 0)
        
        -- Calculate which card we're currently passing
        local centerViewportPosition = rewardStrip.AbsoluteSize.X / 2
        local currentCardIndex = math.floor((currentPosition + centerViewportPosition) / cardSize) + 1
        
        -- Play sound when passing a new card
        if currentCardIndex > lastCardPassed and currentCardIndex <= 50 then
            lastCardPassed = currentCardIndex
            -- Play sound (create new sound instance for overlapping)
            local sound = hoverSound:Clone()
            sound.Parent = SoundService
            sound:Play()
            
            -- Clean up sound after it finishes
            sound.Ended:Connect(function()
                sound:Destroy()
            end)
        end
        
        -- Check if animation is complete
        if progress >= 1 then
            animationConnection:Disconnect()
            rewardStrip.CanvasPosition = Vector2.new(finalPosition, 0)
            self:CompleteAnimation(rewardStrip, winningCard, reward)
        end
    end)
end

-- Complete animation with effects
function CrazyChestAnimationService:CompleteAnimation(rewardStrip, winningCard, reward)
    -- Highlight the winning card
    if winningCard then
        -- Add glow effect
        local glow = Instance.new("UIStroke")
        glow.Color = Color3.fromRGB(255, 215, 0)
        glow.Thickness = 3
        glow.Parent = winningCard
    end
    
    -- Add "YOU WON" text
    local caseOpeningSection = rewardStrip.Parent
    if caseOpeningSection then
        local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
        local youWonText = Instance.new("TextLabel")
        youWonText.Name = "YouWonText"
        youWonText.Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(40))
        youWonText.Position = UDim2.new(0, 0, 0, ScreenUtils.getProportionalSize(5))
        youWonText.BackgroundTransparency = 1
        youWonText.Text = "YOU WON: " .. (reward.type == "money" and ("💰 " .. (reward.money or 0)) or ("💎 " .. (reward.diamonds or 0)))
        youWonText.TextColor3 = Color3.fromRGB(255, 215, 0)
        youWonText.TextSize = ScreenUtils.TEXT_SIZES.LARGE()
        youWonText.Font = Enum.Font.FredokaOne
        youWonText.TextXAlignment = Enum.TextXAlignment.Center
        youWonText.TextStrokeTransparency = 0
        youWonText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        youWonText.ZIndex = 106
        youWonText.Parent = caseOpeningSection
        
        -- Fade in
        youWonText.TextTransparency = 1
        local fadeIn = TweenService:Create(youWonText, 
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
            {TextTransparency = 0}
        )
        fadeIn:Play()
    end
    
    self.isAnimating = false
    print("CrazyChestAnimationService: Realistic animation complete!")
end

function CrazyChestAnimationService:Cleanup()
    self.isAnimating = false
end

return CrazyChestAnimationService