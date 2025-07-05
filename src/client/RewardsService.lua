-- Rewards Service
-- Handles showing rewards to players with nice animations
-- Supports different reward types: money, pets, boosts, etc.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
-- Simple logging functions
local function logWarn(...) warn("[WARN] RewardsService:", ...) end

local RewardsService = {}

-- Reward queue for handling multiple rewards
local rewardQueue = {}
local isShowingReward = false

-- Event connections
local rewardConnections = {}

-- Initialize the service
function RewardsService.initialize()
end

-- Show a reward to the player
function RewardsService.showReward(rewardData)
    -- Validate reward data
    if not rewardData or not rewardData.type then
        error("[ERROR] RewardsService: Invalid reward data provided to showReward")
        return
    end
    
    
    -- Add to queue
    table.insert(rewardQueue, rewardData)
    
    -- Process queue if not already showing a reward
    if not isShowingReward then
        RewardsService.processNextReward()
    end
end

-- Process the next reward in the queue
function RewardsService.processNextReward()
    if #rewardQueue == 0 then
        isShowingReward = false
        return
    end
    
    isShowingReward = true
    local reward = table.remove(rewardQueue, 1)
    
    
    -- Fire event to show UI
    local event = RewardsService.getRewardShowEvent()
    if event then
        event:Fire(reward)
    else
        logWarn("Reward show event not found - UI may not be initialized")
        isShowingReward = false
    end
end

-- Get the reward show event (created by UI)
function RewardsService.getRewardShowEvent()
    return RewardsService._rewardShowEvent
end

-- Set the reward show event (called by UI)
function RewardsService.setRewardShowEvent(event)
    RewardsService._rewardShowEvent = event
end

-- Called when a reward UI finishes showing
function RewardsService.onRewardFinished()
    isShowingReward = false
    
    -- Process next reward after a short delay
    spawn(function()
        wait(0.5) -- Small delay between rewards
        RewardsService.processNextReward()
    end)
end

-- Helper functions for different reward types

-- Show money reward
function RewardsService.showMoneyReward(amount, description)
    local rewardData = {
        type = "money",
        amount = amount,
        title = "Money Earned!",
        description = description or ("You earned $" .. tostring(amount) .. "!"),
        iconAsset = "vector-icon-pack-2/Currency/Cash/Cash Outline 256.png", -- Will be looked up in assets
        color = Color3.fromRGB(85, 170, 85), -- Green
        rarity = "common"
    }
    
    RewardsService.showReward(rewardData)
end

-- Show pet reward (for future use)
function RewardsService.showPetReward(petType, petName)
    local rewardData = {
        type = "pet",
        petType = petType,
        petName = petName,
        title = "New Pet!",
        description = "You got a new pet: " .. petName .. "!",
        iconAsset = "vector-icon-pack-2/General/Pet 2/Pet 2 Outline 256.png", -- Will be updated per pet
        color = Color3.fromRGB(255, 200, 100), -- Golden
        rarity = "legendary"
    }
    
    RewardsService.showReward(rewardData)
end

-- Show boost reward (for future use)
function RewardsService.showBoostReward(boostType, duration, multiplier, description)
    local rewardData = {
        type = "boost",
        boostType = boostType,
        duration = duration,
        multiplier = multiplier,
        title = "Boost Activated!",
        description = description or (tostring(multiplier) .. "x " .. boostType .. " for " .. tostring(duration) .. " minutes!"),
        iconAsset = "vector-icon-pack-2/Currency/Gem/Gem Blue Outline 256.png", -- Boost icon (using available gem icon)
        color = Color3.fromRGB(100, 150, 255), -- Blue
        rarity = "rare"
    }
    
    RewardsService.showReward(rewardData)
end

-- Get rarity color
function RewardsService.getRarityColor(rarity)
    local rarityColors = {
        common = Color3.fromRGB(150, 150, 150), -- Gray
        uncommon = Color3.fromRGB(85, 170, 85), -- Green  
        rare = Color3.fromRGB(85, 150, 255), -- Blue
        epic = Color3.fromRGB(170, 85, 255), -- Purple
        legendary = Color3.fromRGB(255, 170, 85), -- Orange/Gold
        mythic = Color3.fromRGB(255, 85, 85) -- Red
    }
    
    return rarityColors[rarity] or rarityColors.common
end

return RewardsService