-- CrazyChestService - Handles client-side crazy chest interactions
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local SoundService = game:GetService("SoundService")

local DataSyncService = require(script.Parent.DataSyncService)
local CrazyChestConfig = require(ReplicatedStorage.config.CrazyChestConfig)
local PlayerAreaFinder = require(ReplicatedStorage.utils.PlayerAreaFinder)
local CrazyChestAnimationService = require(script.Parent.CrazyChestAnimationService)
local RewardsService = require(script.Parent.RewardsService)

local CrazyChestService = {}
CrazyChestService.__index = CrazyChestService

-- Track if already initialized to prevent duplicate connections
local clientInitialized = false

-- Upgrade success sound
local UPGRADE_SUCCESS_SOUND_ID = "rbxassetid://128506762153961"

-- Function to play upgrade success sound
local function playUpgradeSuccessSound()
    local sound = Instance.new("Sound")
    sound.SoundId = UPGRADE_SUCCESS_SOUND_ID
    sound.Volume = 0.5
    sound.Parent = SoundService
    sound:Play()
    
    -- Clean up sound after it finishes
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

local player = Players.LocalPlayer
local chestPart = nil
local proximityPrompt = nil
local connections = {}

-- UI state
local isChestUIOpen = false
local isRewarding = false -- Track reward display state

function CrazyChestService:Initialize()
    -- Prevent multiple initializations
    if clientInitialized then
        warn("CrazyChestService: CLIENT already initialized, skipping")
        return
    end
    clientInitialized = true
    
    -- Initialize animation service
    CrazyChestAnimationService:Initialize()
    
    -- Find the chest in player's area
    self:FindChestInPlayerArea()
    
    -- Set up remote events
    self:SetupRemoteEvents()
end

function CrazyChestService:FindChestInPlayerArea()
    -- Use shared utility to find player's area
    local playerArea = PlayerAreaFinder:WaitForPlayerArea(30)
    if not playerArea then
        warn("CrazyChestService: Player area not found for", player.Name)
        return
    end
    
    -- Find chest in Environmentals
    local environmentals = playerArea:FindFirstChild("Environmentals")
    if environmentals then
        chestPart = environmentals:FindFirstChild("Chest")
        if chestPart then
            self:CreateProximityPrompt()
        else
            warn("CrazyChestService: Chest not found in Environmentals")
        end
    else
        warn("CrazyChestService: Environmentals folder not found")
    end
end

function CrazyChestService:CreateProximityPrompt()
    if not chestPart then 
        warn("CrazyChestService: Cannot create proximity prompt - chestPart is nil")
        return 
    end
    
    -- Find a suitable part to attach the prompt to
    local attachPart
    if chestPart:IsA("Model") then
        attachPart = chestPart.PrimaryPart or chestPart:FindFirstChildWhichIsA("BasePart", true)
        if not attachPart then
            warn("CrazyChestService: No suitable part found in chest model for ProximityPrompt")
            return
        end
    else
        attachPart = chestPart
    end
    
    -- Create ProximityPrompt
    proximityPrompt = Instance.new("ProximityPrompt")
    proximityPrompt.Name = "CrazyChestPrompt"
    proximityPrompt.ActionText = "Open Crazy Chest"
    proximityPrompt.ObjectText = "Crazy Chest"
    proximityPrompt.HoldDuration = 0
    proximityPrompt.MaxActivationDistance = 8
    proximityPrompt.RequiresLineOfSight = false
    
    proximityPrompt.Parent = attachPart
    
    -- Connect to the Triggered event
    connections.promptTriggered = proximityPrompt.Triggered:Connect(function(playerWhoTriggered)
        if playerWhoTriggered == player then
            -- Open the chest UI first to show chances and cost
            self:OpenChestUI()
        end
    end)
end

function CrazyChestService:SetupRemoteEvents()
    -- Wait for remote events
    local openChestRemote = ReplicatedStorage:WaitForChild("OpenCrazyChest", 10)
    local chestResultRemote = ReplicatedStorage:WaitForChild("CrazyChestResult", 10)
    local upgradeSuccessRemote = ReplicatedStorage:WaitForChild("CrazyChestUpgradeSuccess", 10)
    
    if not openChestRemote or not chestResultRemote then
        warn("CrazyChestService: Critical remote events not found!")
        return
    end
    
    -- Handle chest result from server
    connections.chestResult = chestResultRemote.OnClientEvent:Connect(function(roll, reward)
        -- Received chest result from server
        
        -- Store the reward key for claiming later
        local rewardKey = reward.rewardKey
        
        -- Start the CSGO-style case opening animation
        CrazyChestAnimationService:StartCaseOpeningAnimation(roll, reward)
        
        -- Show reward popup after animation completes 
        task.spawn(function()
            task.wait(6) -- Wait for 6 second animation to complete
            
            -- Claim the reward from server NOW (after animation)
            local claimRewardRemote = ReplicatedStorage:FindFirstChild("ClaimCrazyChestReward")
            if claimRewardRemote and rewardKey then
                print("CrazyChestService: Claiming reward with key:", rewardKey)
                claimRewardRemote:FireServer(rewardKey)
            end
            
            -- Set rewarding state
            isRewarding = true
            print("CrazyChestService: Animation complete, showing reward...")
            
            -- Show reward popup
            local rewardData = {
                source = "Crazy Chest"
            }
            
            if reward.type == "money" then
                rewardData.type = "Money"
                rewardData.amount = reward.money
            elseif reward.type == "diamonds" then
                rewardData.type = "Diamonds"
                rewardData.amount = reward.diamonds
            elseif reward.type == "pet" then
                rewardData.type = "Pet"
                rewardData.petName = reward.petName
                rewardData.boost = reward.boost
                rewardData.amount = reward.amount or 1
            end
            
            RewardsService:ShowReward(rewardData)
            
            -- Keep showing "Rewarding" for 2 seconds
            task.wait(2)
            
            -- Clear rewarding state but keep UI open
            isRewarding = false
            print("CrazyChestService: Ready for next chest opening")
        end)
    end)
    
    -- Handle upgrade success from server (for robux purchases)
    if upgradeSuccessRemote then
        connections.upgradeSuccess = upgradeSuccessRemote.OnClientEvent:Connect(function(upgradeType)
            
            -- Play success sound when upgrade completes
            playUpgradeSuccessSound()
            
            -- Refresh preview cards if visible (wait for actual data sync)
            if upgradeType == "level" then
                task.spawn(function()
                    -- Wait for data to actually sync (poll until level increases)
                    local startTime = tick()
                    local maxWaitTime = 2 -- Max 2 seconds
                    local initialLevel = nil
                    
                    while tick() - startTime < maxWaitTime do
                        local playerData = DataSyncService:GetPlayerData()
                        local currentLevel = playerData and playerData.CrazyChest and playerData.CrazyChest.Level or 1
                        
                        if not initialLevel then
                            initialLevel = currentLevel - 1 -- We expect it to be 1 higher than before
                        end
                        
                        if currentLevel > initialLevel then
                                            self:ForceRefreshAllCards()
                            return
                        end
                        
                        task.wait(0.1)
                    end
                    
                    -- Fallback if data doesn't sync in time
                    warn("🎯 Data sync timeout - force refreshing anyway")
                    self:ForceRefreshAllCards()
                end)
            elseif upgradeType == "luck" then
                task.spawn(function()
                    -- Wait for data to actually sync (poll until luck increases)
                    local startTime = tick()
                    local maxWaitTime = 2 -- Max 2 seconds
                    local initialLuck = nil
                    
                    while tick() - startTime < maxWaitTime do
                        local playerData = DataSyncService:GetPlayerData()
                        local currentLuck = playerData and playerData.CrazyChest and playerData.CrazyChest.Luck or 1
                        
                        if not initialLuck then
                            initialLuck = currentLuck - 1 -- We expect it to be 1 higher than before
                        end
                        
                        if currentLuck > initialLuck then
                                            self:ForceRefreshAllCards()
                            return
                        end
                        
                        task.wait(0.1)
                    end
                    
                    -- Fallback if data doesn't sync in time
                    warn("🍀 Data sync timeout - force refreshing anyway")
                    self:ForceRefreshAllCards()
                end)
            end
        end)
    else
        warn("CrazyChestUpgradeSuccess remote not found on client!")
    end
end

function CrazyChestService:OpenChestUI()
    isChestUIOpen = true
    
    -- Disable the proximity prompt while UI is open
    if proximityPrompt then
        proximityPrompt.Enabled = false
    end
    
    -- Complete tutorial step if active
    local TutorialService = require(script.Parent.TutorialService)
    if TutorialService:IsActive() then
        local currentStep = TutorialService:GetCurrentStep()
        if currentStep and currentStep.id == "open_crazy_chest" then
            print("CrazyChestService: Completing tutorial step - open_crazy_chest")
            TutorialService:CompleteStep("open_crazy_chest")
        end
    end
end

function CrazyChestService:CloseChestUI()
    isChestUIOpen = false
    isRewarding = false -- Clear rewarding state when closing
    
    -- Re-enable the proximity prompt
    if proximityPrompt then
        proximityPrompt.Enabled = true
    end
end

function CrazyChestService:HandleChestOpen()
    
    -- Check if animation is already running or rewarding (prevent multiple openings)
    if CrazyChestAnimationService.isAnimating or isRewarding then
        warn("CrazyChestService: Cannot open chest - animation or reward in progress!")
        return
    end
    
    -- Get player data
    local playerData = DataSyncService:GetPlayerData()
    if not playerData then
        warn("CrazyChestService: No player data available")
        return
    end
    
    if not CrazyChestConfig then
        warn("CrazyChestService: CrazyChestConfig not loaded!")
        return
    end
    
    local cost = CrazyChestConfig.getCost(playerData.Resources.Rebirths or 0)
    
    if (playerData.Resources.Diamonds or 0) < cost then
        warn("CrazyChestService: Not enough diamonds")
        return
    end
    
    -- Optimistically deduct diamonds on client for instant feedback
    -- The server will validate and sync the real state
    local store = require(ReplicatedStorage.store)
    local Actions = require(ReplicatedStorage.store.actions)
    store:dispatch(Actions.updateResources("Diamonds", -cost))
    
    -- Send request to server
    local openChestRemote = ReplicatedStorage:FindFirstChild("OpenCrazyChest")
    if openChestRemote then
        openChestRemote:FireServer()
    else
        warn("CrazyChestService: OpenCrazyChest remote not found!")
        -- Revert the optimistic update if we can't contact server
        store:dispatch(Actions.updateResources("Diamonds", cost))
    end
end

-- Upgrade the chest level
function CrazyChestService:UpgradeChest()
    local playerData = DataSyncService:GetPlayerData()
    local chestLevel = playerData and playerData.CrazyChest and playerData.CrazyChest.Level or 1
    local upgradeCost = chestLevel * 100
    
    -- Check if player has enough diamonds (no sound notification)
    if not playerData or not playerData.Resources or playerData.Resources.Diamonds < upgradeCost then
        return -- Silently fail if not enough diamonds
    end
    
    -- Send upgrade request to server
    local upgradeRemote = ReplicatedStorage:FindFirstChild("UpgradeCrazyChest")
    if upgradeRemote then
        upgradeRemote:FireServer()
        
        -- Play upgrade success sound immediately
        playUpgradeSuccessSound()
        
        -- After upgrade, check if preview cards are currently visible and refresh them
        task.spawn(function()
            task.wait(0.1) -- Wait for server response and data sync
            self:RefreshPreviewCardsIfVisible()
        end)
    else
        warn("CrazyChestService: UpgradeCrazyChest remote not found!")
    end
end

-- Upgrade the chest luck
function CrazyChestService:UpgradeChestLuck()
    local playerData = DataSyncService:GetPlayerData()
    local chestLuck = playerData and playerData.CrazyChest and playerData.CrazyChest.Luck or 1
    local upgradeCost = chestLuck * 500 -- More expensive than level upgrade
    
    -- Check if player has enough diamonds (no sound notification)
    if not playerData or not playerData.Resources or playerData.Resources.Diamonds < upgradeCost then
        return -- Silently fail if not enough diamonds
    end
    
    -- Send upgrade request to server
    local upgradeRemote = ReplicatedStorage:FindFirstChild("UpgradeCrazyChestLuck")
    if upgradeRemote then
        upgradeRemote:FireServer()
        
        -- Play upgrade success sound immediately
        playUpgradeSuccessSound()
        
        -- After upgrade, check if preview cards are currently visible and refresh them
        task.spawn(function()
            task.wait(0.1) -- Wait for server response and data sync
            self:RefreshLuckPreviewCardsIfVisible()
        end)
    else
        warn("CrazyChestService: UpgradeCrazyChestLuck remote not found!")
    end
end

-- Robux purchase for chest level upgrade
function CrazyChestService:UpgradeChestRobux(devProductId)
    print("CrazyChestService: Attempting robux purchase for chest level upgrade - Product ID:", devProductId)
    print("CrazyChestService: Player:", player.Name)
    print("CrazyChestService: MarketplaceService available:", MarketplaceService ~= nil)
    
    -- Use MarketplaceService to prompt purchase
    local success, errorMessage = pcall(function()
        print("CrazyChestService: About to call PromptProductPurchase...")
        MarketplaceService:PromptProductPurchase(player, devProductId)
        print("CrazyChestService: PromptProductPurchase call completed")
        
    end)
    
    if not success then
        warn("CrazyChestService: Failed to prompt robux purchase for chest level:", errorMessage)
    else
        print("CrazyChestService: Successfully prompted robux purchase for chest level")
    end
end

-- Robux purchase for chest opening
function CrazyChestService:OpenChestRobux(devProductId)
    print("CrazyChestService: Attempting robux purchase for chest opening - Product ID:", devProductId)
    print("CrazyChestService: Player:", player.Name)
    print("CrazyChestService: MarketplaceService available:", MarketplaceService ~= nil)
    
    -- Use MarketplaceService to prompt purchase
    local success, errorMessage = pcall(function()
        print("CrazyChestService: About to call PromptProductPurchase...")
        MarketplaceService:PromptProductPurchase(player, devProductId)
        print("CrazyChestService: PromptProductPurchase call completed")
    end)
    
    if not success then
        warn("CrazyChestService: Failed to prompt robux purchase for chest opening:", errorMessage)
    else
        print("CrazyChestService: Successfully prompted robux purchase for chest opening")
    end
end

-- Robux purchase for chest luck upgrade  
function CrazyChestService:UpgradeChestLuckRobux(devProductId)
    print("CrazyChestService: Attempting robux purchase for chest luck upgrade - Product ID:", devProductId)
    print("CrazyChestService: Player:", player.Name)
    print("CrazyChestService: MarketplaceService available:", MarketplaceService ~= nil)
    
    -- Use MarketplaceService to prompt purchase
    local success, errorMessage = pcall(function()
        print("CrazyChestService: About to call PromptProductPurchase...")
        MarketplaceService:PromptProductPurchase(player, devProductId)
        print("CrazyChestService: PromptProductPurchase call completed")
        
    end)
    
    if not success then
        warn("CrazyChestService: Failed to prompt robux purchase for chest luck:", errorMessage)
    else
        print("CrazyChestService: Successfully prompted robux purchase for chest luck")
    end
end

-- Helper function to refresh preview cards if they're currently visible
function CrazyChestService:RefreshPreviewCardsIfVisible()
    -- Find the UI elements
    local player = game.Players.LocalPlayer
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    -- Look for preview cards (indicates hovering state)
    local foundPreviewCards = false
    for _, gui in pairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            local function findPreviewCards(parent)
                for _, child in pairs(parent:GetDescendants()) do
                    if child.Name and string.find(child.Name, "PreviewCard") then
                        return true
                    end
                end
                return false
            end
            
            if findPreviewCards(gui) then
                foundPreviewCards = true
                break
            end
        end
    end
    
    -- If preview cards are visible, trigger a refresh by simulating mouse leave/enter
    if foundPreviewCards then
        local modal = playerGui:FindFirstChild("CrazyChestUIOverlay")
        if modal then
            local upgradeButton = nil
            local function findUpgradeButton(parent)
                for _, child in pairs(parent:GetDescendants()) do
                    if child:IsA("TextButton") and child.Text and string.find(child.Text, "⬆️") then
                        return child
                    end
                end
                return nil
            end
            
            upgradeButton = findUpgradeButton(modal)
            if upgradeButton then
                -- Trigger mouse leave then enter to refresh preview cards
                local mouseLeaveEvent = upgradeButton.MouseLeave
                local mouseEnterEvent = upgradeButton.MouseEnter
                
                if mouseLeaveEvent and mouseEnterEvent then
                    mouseLeaveEvent:Fire()
                    task.wait(0.05) -- Small delay
                    mouseEnterEvent:Fire()
                end
            end
        end
    end
end

-- Helper function to refresh luck preview cards if they're currently visible
function CrazyChestService:RefreshLuckPreviewCardsIfVisible()
    -- Find the UI elements
    local player = game.Players.LocalPlayer
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    -- Look for luck preview cards (indicates hovering state)
    local foundLuckPreviewCards = false
    for _, gui in pairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            local function findLuckPreviewCards(parent)
                for _, child in pairs(parent:GetDescendants()) do
                    if child.Name and string.find(child.Name, "LuckPreviewCard") then
                        return true
                    end
                end
                return false
            end
            
            if findLuckPreviewCards(gui) then
                foundLuckPreviewCards = true
                break
            end
        end
    end
    
    -- If luck preview cards are visible, trigger a refresh by simulating mouse leave/enter
    if foundLuckPreviewCards then
        local modal = playerGui:FindFirstChild("CrazyChestUIOverlay")
        if modal then
            local luckButton = nil
            local function findLuckButton(parent)
                for _, child in pairs(parent:GetDescendants()) do
                    if child:IsA("TextButton") and child.Text and string.find(child.Text, "🍀") then
                        return child
                    end
                end
                return nil
            end
            
            luckButton = findLuckButton(modal)
            if luckButton then
                -- Trigger mouse leave then enter to refresh preview cards
                local mouseLeaveEvent = luckButton.MouseLeave
                local mouseEnterEvent = luckButton.MouseEnter
                
                if mouseLeaveEvent and mouseEnterEvent then
                    mouseLeaveEvent:Fire()
                    task.wait(0.05) -- Small delay
                    mouseEnterEvent:Fire()
                end
            end
        end
    end
end

function CrazyChestService:GetUIProps()
    local playerData = DataSyncService:GetPlayerData()
    local chestLevel = playerData and playerData.CrazyChest and playerData.CrazyChest.Level or 1
    local chestLuck = playerData and playerData.CrazyChest and playerData.CrazyChest.Luck or 1
    local upgradeCost = chestLevel * 100 -- Same calculation as server
    local luckUpgradeCost = chestLuck * 500 -- Same calculation as server
    
    return {
        visible = isChestUIOpen,
        playerDiamonds = playerData and playerData.Resources.Diamonds or 0,
        playerRebirths = playerData and playerData.Resources.Rebirths or 0,
        chestLevel = chestLevel,
        chestLuck = chestLuck,
        upgradeCost = upgradeCost,
        luckUpgradeCost = luckUpgradeCost,
        canUpgrade = (playerData and playerData.Resources.Diamonds or 0) >= upgradeCost,
        canUpgradeLuck = (playerData and playerData.Resources.Diamonds or 0) >= luckUpgradeCost,
        rewardMultiplier = 1 + (chestLevel - 1) * 0.25, -- 25% increase per level (matches server)
        isAnimating = CrazyChestAnimationService.isAnimating, -- Pass animation state to UI
        isRewarding = isRewarding, -- Pass rewarding state to UI
        onClose = function()
            self:CloseChestUI()
        end,
        onOpenChest = function()
            self:HandleChestOpen()
        end,
        onUpgradeChest = function()
            self:UpgradeChest()
        end,
        onUpgradeChestLuck = function()
            self:UpgradeChestLuck()
        end,
        onUpgradeChestRobux = function(devProductId)
            self:UpgradeChestRobux(devProductId)
        end,
        onUpgradeChestLuckRobux = function(devProductId)
            self:UpgradeChestLuckRobux(devProductId)
        end,
        onOpenChestRobux = function(devProductId)
            self:OpenChestRobux(devProductId)
        end
    }
end

function CrazyChestService:Cleanup()
    for _, connection in pairs(connections) do
        if connection then
            connection:Disconnect()
        end
    end
    connections = {}
    
    if proximityPrompt then
        proximityPrompt:Destroy()
        proximityPrompt = nil
    end
    
    -- Cleanup animation service
    CrazyChestAnimationService:Cleanup()
end

-- Force refresh all cards after upgrade (smooth React-friendly refresh)
function CrazyChestService:ForceRefreshAllCards()
    
    -- Instead of manually clearing DOM elements, let React handle the refresh
    -- by briefly toggling the UI state - this is much smoother and React-friendly
    
    task.spawn(function()
        
        -- Ultra-fast close/reopen (10ms - essentially imperceptible to users)
        -- This forces React to completely re-render with the new luck/level data
        self:CloseChestUI()
        task.wait(0.01) -- 10ms - barely a single frame
        self:OpenChestUI()
        
    end)
end

return CrazyChestService