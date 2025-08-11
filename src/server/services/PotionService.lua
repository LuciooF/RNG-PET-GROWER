-- Server PotionService - Handles potion activation, expiration, and boost calculations
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local PotionConfig = require(ReplicatedStorage.config.PotionConfig)
local DataService = require(script.Parent.DataService)

local PotionService = {}
PotionService.__index = PotionService

-- Active potion tracking (per player)
local activePlayerPotions = {} -- [player] = {[potionId] = expirationData}
local potionTimers = {} -- [player] = {[potionId] = connection}

-- Remote events
local activatePotionRemote = ReplicatedStorage:FindFirstChild("ActivatePotion")
local potionExpiredRemote = ReplicatedStorage:FindFirstChild("PotionExpired") 
local potionActivatedRemote = ReplicatedStorage:FindFirstChild("PotionActivated")
local getActivePotionsRemote = ReplicatedStorage:FindFirstChild("GetActivePotions")

-- Create remote events if they don't exist
if not activatePotionRemote then
    activatePotionRemote = Instance.new("RemoteEvent")
    activatePotionRemote.Name = "ActivatePotion"
    activatePotionRemote.Parent = ReplicatedStorage
end

if not potionExpiredRemote then
    potionExpiredRemote = Instance.new("RemoteEvent")
    potionExpiredRemote.Name = "PotionExpired"
    potionExpiredRemote.Parent = ReplicatedStorage
end

if not potionActivatedRemote then
    potionActivatedRemote = Instance.new("RemoteEvent")
    potionActivatedRemote.Name = "PotionActivated"
    potionActivatedRemote.Parent = ReplicatedStorage
end

if not getActivePotionsRemote then
    getActivePotionsRemote = Instance.new("RemoteFunction")
    getActivePotionsRemote.Name = "GetActivePotions"
    getActivePotionsRemote.Parent = ReplicatedStorage
end

-- Initialize the service
function PotionService:Initialize()
    print("PotionService: Initializing server-side potion management")
    
    -- Handle potion activation requests
    activatePotionRemote.OnServerEvent:Connect(function(player, potionId)
        self:HandlePotionActivation(player, potionId)
    end)
    
    -- Handle get active potions requests
    getActivePotionsRemote.OnServerInvoke = function(player)
        return self:GetActivePotionsForClient(player)
    end
    
    -- Handle player leaving (cleanup)
    Players.PlayerRemoving:Connect(function(player)
        self:CleanupPlayer(player)
    end)
    
    -- Load active potions for existing players
    for _, player in pairs(Players:GetPlayers()) do
        task.spawn(function()
            self:LoadPlayerActivePotions(player)
        end)
    end
end

-- Handle potion activation request from client
function PotionService:HandlePotionActivation(player, potionId)
    if not player or not potionId then
        warn("PotionService: Invalid activation request")
        return
    end
    
    -- Validate potion exists
    local potionConfig = PotionConfig.GetPotion(potionId)
    if not potionConfig then
        warn("PotionService: Invalid potion ID:", potionId)
        return
    end
    
    -- Get player data
    local playerData = DataService:GetPlayerData(player)
    if not playerData then
        warn("PotionService: Could not get player data for", player.Name)
        return
    end
    
    -- Check if player has this potion in inventory
    local playerPotions = playerData.Potions or {}
    local potionQuantity = playerPotions[potionId] or 0
    
    if potionQuantity <= 0 then
        warn("PotionService: Player", player.Name, "doesn't have potion", potionId)
        return
    end
    
    -- Check if player already has this boost type active
    local activePotions = playerData.ActivePotions or {}
    for _, activePotion in pairs(activePotions) do
        local activePotionConfig = PotionConfig.GetPotion(activePotion.PotionId)
        if activePotionConfig and activePotionConfig.BoostType == potionConfig.BoostType then
            warn("PotionService: Player", player.Name, "already has", potionConfig.BoostType, "potion active")
            return
        end
    end
    
    -- Activate the potion
    local currentTime = os.time()
    local expirationTime = currentTime + potionConfig.Duration
    
    -- Create active potion data
    local activePotionData = {
        PotionId = potionId,
        ActivatedAt = currentTime,
        ExpiresAt = expirationTime,
        RemainingTime = potionConfig.Duration
    }
    
    -- Update player data
    -- Remove from inventory
    playerPotions[potionId] = potionQuantity - 1
    if playerPotions[potionId] <= 0 then
        playerPotions[potionId] = nil
    end
    
    -- Add to active potions
    if not activePotions then
        activePotions = {}
    end
    table.insert(activePotions, activePotionData)
    
    -- Update player data (ProfileService auto-saves)
    playerData.Potions = playerPotions
    playerData.ActivePotions = activePotions
    
    -- Track locally for timer management
    if not activePlayerPotions[player] then
        activePlayerPotions[player] = {}
    end
    activePlayerPotions[player][potionId] = activePotionData
    
    -- Start expiration timer
    self:StartPotionTimer(player, potionId, potionConfig.Duration)
    
    -- Notify client
    potionActivatedRemote:FireClient(player, activePotionData)
    
    print("PotionService: Activated", potionId, "for player", player.Name)
end

-- Start a timer for potion expiration
function PotionService:StartPotionTimer(player, potionId, duration)
    if not potionTimers[player] then
        potionTimers[player] = {}
    end
    
    -- Clear existing timer if any
    if potionTimers[player][potionId] then
        task.cancel(potionTimers[player][potionId])
    end
    
    -- Create new timer thread
    potionTimers[player][potionId] = task.delay(duration, function()
        self:ExpirePotion(player, potionId)
    end)
end

-- Handle potion expiration
function PotionService:ExpirePotion(player, potionId)
    if not player or not player.Parent then
        return -- Player left
    end
    
    print("PotionService: Expiring", potionId, "for player", player.Name)
    
    -- Remove from local tracking
    if activePlayerPotions[player] then
        activePlayerPotions[player][potionId] = nil
    end
    
    -- Clear timer
    if potionTimers[player] and potionTimers[player][potionId] then
        task.cancel(potionTimers[player][potionId])
        potionTimers[player][potionId] = nil
    end
    
    -- Update player data
    local playerData = DataService:GetPlayerData(player)
    if playerData and playerData.ActivePotions then
        local activePotions = playerData.ActivePotions
        for i = #activePotions, 1, -1 do
            if activePotions[i].PotionId == potionId then
                table.remove(activePotions, i)
                break
            end
        end
        -- ProfileService handles auto-saving
    end
    
    -- Notify client
    potionExpiredRemote:FireClient(player, potionId)
end

-- Load active potions when player joins (handle server restarts)
function PotionService:LoadPlayerActivePotions(player)
    local playerData = DataService:GetPlayerData(player)
    if not playerData or not playerData.ActivePotions then
        return
    end
    
    local currentTime = os.time()
    local activePotions = playerData.ActivePotions
    local updatedActivePotions = {}
    
    -- Check each active potion
    for _, activePotion in pairs(activePotions) do
        if activePotion.ExpiresAt > currentTime then
            -- Potion is still active
            local remainingTime = activePotion.ExpiresAt - currentTime
            activePotion.RemainingTime = remainingTime
            
            table.insert(updatedActivePotions, activePotion)
            
            -- Track locally and restart timer
            if not activePlayerPotions[player] then
                activePlayerPotions[player] = {}
            end
            activePlayerPotions[player][activePotion.PotionId] = activePotion
            
            -- Restart timer with remaining time
            self:StartPotionTimer(player, activePotion.PotionId, remainingTime)
            
            print("PotionService: Resumed potion", activePotion.PotionId, "for", player.Name, "with", remainingTime, "seconds remaining")
        else
            -- Potion expired while offline
            print("PotionService: Expired offline potion", activePotion.PotionId, "for", player.Name)
        end
    end
    
    -- Update player data with only active potions
    if #updatedActivePotions ~= #activePotions then
        playerData.ActivePotions = updatedActivePotions
        -- ProfileService handles auto-saving
    end
end

-- Get active boost multiplier for a specific boost type
function PotionService:GetBoostMultiplier(player, boostType)
    if not activePlayerPotions[player] then
        return 1 -- No boost
    end
    
    for potionId, _ in pairs(activePlayerPotions[player]) do
        local potionConfig = PotionConfig.GetPotion(potionId)
        if potionConfig and potionConfig.BoostType == boostType then
            return potionConfig.BoostAmount
        end
    end
    
    return 1 -- No boost for this type
end

-- Check if player has any active potion of a specific boost type
function PotionService:HasActiveBoost(player, boostType)
    return self:GetBoostMultiplier(player, boostType) > 1
end

-- Get all active potions for a player
function PotionService:GetActivePotions(player)
    return activePlayerPotions[player] or {}
end

-- Get active potions formatted for client (with updated remaining time)
function PotionService:GetActivePotionsForClient(player)
    local playerData = DataService:GetPlayerData(player)
    if not playerData or not playerData.ActivePotions then
        return {}
    end
    
    local currentTime = os.time()
    local formattedActivePotions = {}
    local expiredPotions = {}
    
    -- Check each potion and separate valid vs expired
    for i, activePotion in pairs(playerData.ActivePotions) do
        local remainingTime = math.max(0, activePotion.ExpiresAt - currentTime)
        
        if remainingTime > 0 then
            -- Still active - include in response
            local formattedPotion = {
                PotionId = activePotion.PotionId,
                ActivatedAt = activePotion.ActivatedAt,
                ExpiresAt = activePotion.ExpiresAt,
                RemainingTime = remainingTime
            }
            table.insert(formattedActivePotions, formattedPotion)
        else
            -- Expired - mark for removal
            table.insert(expiredPotions, i)
            print("PotionService: Found expired potion during sync:", activePotion.PotionId, "for", player.Name)
        end
    end
    
    -- Clean up expired potions from player data (remove in reverse order to avoid index issues)
    if #expiredPotions > 0 then
        for i = #expiredPotions, 1, -1 do
            local expiredIndex = expiredPotions[i]
            local expiredPotion = playerData.ActivePotions[expiredIndex]
            table.remove(playerData.ActivePotions, expiredIndex)
            
            -- Also clean up local tracking
            if activePlayerPotions[player] then
                activePlayerPotions[player][expiredPotion.PotionId] = nil
            end
            
            print("PotionService: Cleaned up expired potion:", expiredPotion.PotionId, "for", player.Name)
        end
    end
    
    print("PotionService: Sending", #formattedActivePotions, "active potions to client for", player.Name, "(cleaned up", #expiredPotions, "expired)")
    return formattedActivePotions
end

-- Clean up when player leaves
function PotionService:CleanupPlayer(player)
    if potionTimers[player] then
        for _, thread in pairs(potionTimers[player]) do
            if thread then
                task.cancel(thread)
            end
        end
        potionTimers[player] = nil
    end
    
    activePlayerPotions[player] = nil
    print("PotionService: Cleaned up potions for", player.Name)
end

-- Give a potion to a player (for rewards, admin commands, etc.)
function PotionService:GivePotion(player, potionId, quantity)
    quantity = quantity or 1
    
    local potionConfig = PotionConfig.GetPotion(potionId)
    if not potionConfig then
        warn("PotionService: Invalid potion ID:", potionId)
        return false
    end
    
    local playerData = DataService:GetPlayerData(player)
    if not playerData then
        warn("PotionService: Could not get player data for", player.Name)
        return false
    end
    
    local playerPotions = playerData.Potions or {}
    local currentQuantity = playerPotions[potionId] or 0
    local newQuantity = math.min(currentQuantity + quantity, potionConfig.StackLimit)
    
    playerPotions[potionId] = newQuantity
    playerData.Potions = playerPotions
    
    -- ProfileService handles auto-saving
    
    print("PotionService: Gave", quantity, "x", potionId, "to", player.Name)
    return true
end

-- Give potion with reward popup (helper for other services)
function PotionService:GivePotionWithReward(player, potionId, quantity, source)
    local success = self:GivePotion(player, potionId, quantity)
    if success then
        -- Show reward popup on client
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local showRewardRemote = ReplicatedStorage:FindFirstChild("ShowReward")
        if showRewardRemote then
            showRewardRemote:FireClient(player, {
                type = "Potion",
                potionId = potionId,
                amount = quantity,
                source = source or "Reward"
            })
        else
            warn("PotionService: ShowReward remote event not found")
        end
    end
    return success
end

-- Singleton instance
local instance = PotionService
instance:Initialize()

return instance