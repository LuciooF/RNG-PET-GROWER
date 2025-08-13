-- CrazyChestAnimationService - Animates the existing cards in the chest UI
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local CrazyChestConfig = require(ReplicatedStorage.config.CrazyChestConfig)
local PotionConfig = require(ReplicatedStorage.config.PotionConfig)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)

-- Sound configuration
local HOVER_SOUND_ID = "rbxassetid://6895079853"

-- Helper function to format potion reward text for winning card
-- Note: The server already applies the chest level bonus to reward.quantity
local function formatPotionRewardText(reward, multiplier)
    if not reward or reward.type ~= "potion" then
        return "Potion!"
    end
    
    local potionConfig = PotionConfig and PotionConfig.GetPotion and PotionConfig.GetPotion(reward.potionId)
    if not potionConfig then
        return NumberFormatter.format(math.floor(reward.quantity * multiplier)) .. "\nPotion!"
    end
    
    -- The server already added the chest level bonus to reward.quantity
    -- So we just use reward.quantity directly
    local finalQuantity = reward.quantity
    
    -- Format based on potion type
    if reward.potionId == "money_2x_10m" then
        return finalQuantity .. "x\n2x Money!"
    elseif reward.potionId == "diamonds_2x_10m" then
        return finalQuantity .. "x\n2x Diamonds!"
    elseif reward.potionId == "pet_magnet_10m" then
        return finalQuantity .. "x\nPet Magnet!"
    end
    
    local duration = PotionConfig.FormatDuration and PotionConfig.FormatDuration(potionConfig.Duration) or "10m"
    local name = potionConfig.BoostType == "Pet Magnet" and "Pet Magnet" or potionConfig.BoostType
    local quantity = NumberFormatter.format(math.floor(reward.quantity * multiplier))
    
    return quantity .. " - " .. duration .. "\n" .. name .. "!"
end

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
    
    print("=== CRAZY CHEST ANIMATION START ===")
    print("Roll:", roll)
    print("Reward type:", reward.type)
    print("Reward data:", game:GetService("HttpService"):JSONEncode(reward))
    print("===============================")
    
    -- Find the existing reward strip in the UI
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local rewardStrip = nil
    
    print("CrazyChestAnimationService: Searching for RewardStrip...")
    
    -- Search for the RewardStrip in any ScreenGui
    for _, gui in pairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            print("  - Checking ScreenGui:", gui.Name)
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
                print("  - Found RewardStrip in:", gui.Name)
                print("  - RewardStrip children count:", #rewardStrip:GetChildren())
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
    print("CrazyChestAnimationService: Starting winning card update")
    print("  - Reward type:", reward.type)
    print("  - Reward details:", reward.type == "money" and ("money=" .. tostring(reward.money)) or 
                                 reward.type == "diamonds" and ("diamonds=" .. tostring(reward.diamonds)) or
                                 reward.type == "potion" and ("potionId=" .. tostring(reward.potionId) .. ", quantity=" .. tostring(reward.quantity)) or
                                 reward.type == "pet" and ("petName=" .. tostring(reward.petName) .. ", boost=" .. tostring(reward.boost)) or "unknown")
    
    if winningCard then
        print("CrazyChestAnimationService: Found winning card at position", WINNING_POSITION)
        
        -- Import NumberFormatter for consistent formatting
        local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)
        
        -- Update the background color and transparency to match the actual reward
        winningCard.BackgroundColor3 = reward.color or Color3.fromRGB(255, 255, 255)
        winningCard.BackgroundTransparency = (reward.special == "rainbow" or reward.special == "black_market" or reward.special == "black_market_rainbow_text") and 0.3 or 0.7
        
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
        
        -- Add black market gradient to background for black market rewards
        if reward.special == "black_market" or reward.special == "black_market_rainbow_text" then
            local existingGradient = winningCard:FindFirstChild("UIGradient")
            if existingGradient then
                existingGradient:Destroy()
            end
            
            local blackMarketGradient = Instance.new("UIGradient")
            blackMarketGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 20)),
                ColorSequenceKeypoint.new(0.25, Color3.fromRGB(40, 20, 40)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 20, 20)),
                ColorSequenceKeypoint.new(0.75, Color3.fromRGB(40, 20, 60)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20))
            })
            blackMarketGradient.Rotation = 135
            blackMarketGradient.Parent = winningCard
        end
        
        -- Update the border color and gradients to match the reward rarity
        local stroke = winningCard:FindFirstChild("Stroke")
        if stroke then
            stroke.Color = reward.color or Color3.fromRGB(200, 200, 200)
            
            -- Add gradient to stroke for special effects
            if reward.special == "rainbow" then
                local existingStrokeGradient = stroke:FindFirstChild("UIGradient")
                if existingStrokeGradient then
                    existingStrokeGradient:Destroy()
                end
                
                local strokeRainbowGradient = Instance.new("UIGradient")
                strokeRainbowGradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 127, 0)),
                    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
                    ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
                    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 0, 211))
                })
                strokeRainbowGradient.Rotation = 45
                strokeRainbowGradient.Parent = stroke
            elseif reward.special == "black_market" or reward.special == "black_market_rainbow_text" then
                local existingStrokeGradient = stroke:FindFirstChild("UIGradient")
                if existingStrokeGradient then
                    existingStrokeGradient:Destroy()
                end
                
                local strokeBlackMarketGradient = Instance.new("UIGradient")
                strokeBlackMarketGradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 20)),
                    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(40, 20, 40)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 20, 20)),
                    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(40, 20, 60)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20))
                })
                strokeBlackMarketGradient.Rotation = 135
                strokeBlackMarketGradient.Parent = stroke
            end
        end
        
        -- Update the icon - handle pets, potions, and currency properly
        print("CrazyChestAnimationService: Updating icon for type:", reward.type)
        
        -- Log what's currently in the winning card
        local existingIcon = winningCard:FindFirstChild("CurrencyIcon")
        local existingViewport = winningCard:FindFirstChild("PetModel") 
        print("  - Existing CurrencyIcon:", existingIcon and "found" or "not found")
        print("  - Existing PetModel:", existingViewport and "found" or "not found")
        
        if reward.type == "pet" then
            print("CrazyChestAnimationService: Setting up pet viewport")
            -- Remove currency icon if it exists
            local currencyIcon = winningCard:FindFirstChild("CurrencyIcon")
            if currencyIcon then
                currencyIcon:Destroy()
                print("  - Removed existing CurrencyIcon")
            end
            
            -- Create or update pet viewport
            local existingViewport = winningCard:FindFirstChild("PetModel")
            if existingViewport then
                existingViewport:Destroy()
                print("  - Removed existing PetModel")
            end
            
            -- Create new ViewportFrame for pet (same as in UI creation)
            local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
            local petViewport = Instance.new("ViewportFrame")
            petViewport.Name = "PetModel"
            petViewport.Size = UDim2.new(0, ScreenUtils.getProportionalSize(70), 0, ScreenUtils.getProportionalSize(70))
            petViewport.Position = UDim2.new(0.5, -ScreenUtils.getProportionalSize(35), 0, ScreenUtils.getProportionalSize(15))
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
        elseif reward.type == "potion" then
            -- Handle potion icons
            print("CrazyChestAnimationService: Updating winning card for potion:", reward.potionId, "quantity:", reward.quantity)
            
            -- Remove pet viewport if it exists (switching from pet to potion)
            local existingViewport = winningCard:FindFirstChild("PetModel")
            if existingViewport then
                existingViewport:Destroy()
            end
            
            -- Find or create currency icon for potion
            local currencyIcon = winningCard:FindFirstChild("CurrencyIcon")
            if not currencyIcon then
                print("CrazyChestAnimationService: CurrencyIcon not found, creating new one")
                local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
                currencyIcon = Instance.new("ImageLabel")
                currencyIcon.Name = "CurrencyIcon"
                currencyIcon.Size = UDim2.new(0, ScreenUtils.getProportionalSize(60), 0, ScreenUtils.getProportionalSize(60))
                currencyIcon.Position = UDim2.new(0.5, -ScreenUtils.getProportionalSize(30), 0, ScreenUtils.getProportionalSize(15))
                currencyIcon.BackgroundTransparency = 1
                currencyIcon.ScaleType = Enum.ScaleType.Fit
                currencyIcon.ZIndex = 1025
                currencyIcon.Parent = winningCard
            end
            
            -- Get potion icon from config
            local potionConfig = PotionConfig and PotionConfig.GetPotion and PotionConfig.GetPotion(reward.potionId)
            local potionIcon = potionConfig and potionConfig.Icon or "rbxassetid://118134400760699"
            currencyIcon.Image = potionIcon
            print("CrazyChestAnimationService: Set potion icon to:", potionIcon)
        else
            -- Handle currency icons (money/diamonds)
            print("CrazyChestAnimationService: Setting up currency icon for type:", reward.type)
            
            -- Remove pet viewport if it exists (switching from pet to currency)
            local existingViewport = winningCard:FindFirstChild("PetModel")
            if existingViewport then
                existingViewport:Destroy()
                print("  - Removed existing PetModel")
            end
            
            -- Find or create currency icon
            local icon = winningCard:FindFirstChild("CurrencyIcon")
            if not icon then
                print("CrazyChestAnimationService: CurrencyIcon not found, creating new one for", reward.type)
                local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
                icon = Instance.new("ImageLabel")
                icon.Name = "CurrencyIcon"
                icon.Size = UDim2.new(0, ScreenUtils.getProportionalSize(60), 0, ScreenUtils.getProportionalSize(60))
                icon.Position = UDim2.new(0.5, -ScreenUtils.getProportionalSize(30), 0, ScreenUtils.getProportionalSize(15))
                icon.BackgroundTransparency = 1
                icon.ScaleType = Enum.ScaleType.Fit
                icon.ZIndex = 1025
                icon.Parent = winningCard
                print("  - Created new CurrencyIcon")
            else
                print("  - Using existing CurrencyIcon")
            end
            
            if icon and icon:IsA("ImageLabel") then
                local imageId = reward.type == "money" and "rbxassetid://80960000119108" or "rbxassetid://135421873302468"
                icon.Image = imageId
                print("  - Set icon image to:", imageId, "for type:", reward.type)
            else
                print("  - ERROR: Icon is not an ImageLabel or is nil!")
            end
        end
        
        -- Update the text with proper formatting to match other cards (two-line format with \n)
        local text = winningCard:FindFirstChild("RewardText")
        print("CrazyChestAnimationService: Updating text - RewardText found:", text and "yes" or "no")
        
        if text and text:IsA("TextLabel") then
            -- Format text with proper multipliers for all rewards including ultra-rare chest
            if reward.special == "black_market_rainbow_text" then
                local textContent = NumberFormatter.format(reward.boost) .. "\nBoost!"
                text.Text = textContent
                print("  - Set ultra-rare text:", textContent)
                
                -- Add rainbow gradient to text for ultra-rare chest
                local existingTextGradient = text:FindFirstChild("UIGradient")
                if existingTextGradient then
                    existingTextGradient:Destroy()
                end
                
                local textRainbowGradient = Instance.new("UIGradient")
                textRainbowGradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 127, 0)),
                    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
                    ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
                    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 0, 211))
                })
                textRainbowGradient.Parent = text
            else
                local textContent = reward.type == "pet" and (NumberFormatter.format(reward.boost) .. "\nBoost!") or 
                                   (reward.type == "money" and (NumberFormatter.format(reward.money) .. "\nMoney!") or 
                                   (reward.type == "potion" and formatPotionRewardText(reward, 1)) or
                                   (NumberFormatter.format(reward.diamonds) .. "\nDiamonds!"))
                text.Text = textContent
                print("  - Set reward text:", textContent)
            end
        else
            print("CrazyChestAnimationService: ERROR - RewardText not found or not a TextLabel!")
        end
        
        -- Update chance label formatting if it exists
        local chanceLabel = winningCard:FindFirstChild("ChanceLabel")
        if chanceLabel and chanceLabel:IsA("TextLabel") then
            if reward.special == "black_market_rainbow_text" then
                -- Use special formatting for ultra-rare chest (but no rainbow gradient on chance text)
                chanceLabel.Text = string.format("%.3f%%", reward.chance)
            else
                -- Regular formatting for other cards with proper decimal formatting
                chanceLabel.Text = string.format("%.2f%%", reward.chance)
            end
        end
        
        -- Updated winning card with reward formatting
        print("CrazyChestAnimationService: Finished updating winning card")
    else
        print("CrazyChestAnimationService: ERROR - Could not find winning card at position", WINNING_POSITION)
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
        local youWonContent = "YOU WON: " .. (reward.type == "money" and ("💰 " .. NumberFormatter.format(reward.money or 0)) or 
                                               (reward.type == "potion" and ("🧪 " .. formatPotionRewardText(reward, 1):gsub("\n", " ")) or 
                                               (reward.type == "pet" and ("🐾 " .. NumberFormatter.format(reward.boost) .. " Boost") or 
                                               ("💎 " .. NumberFormatter.format(reward.diamonds or 0)))))
        youWonText.Text = youWonContent
        print("CrazyChestAnimationService: Set YOU WON text:", youWonContent)
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