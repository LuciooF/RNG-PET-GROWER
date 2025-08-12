-- Client PotionService - Handles potion UI management and client-side logic
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local PotionConfig = require(ReplicatedStorage.config.PotionConfig)

local PotionService = {}
PotionService.__index = PotionService

local player = Players.LocalPlayer

-- Client state
local activePotions = {} -- [potionId] = activePotionData
local potionCallbacks = {} -- UI update callbacks
local uiUpdateConnection = nil

-- Remote events
local activatePotionRemote = ReplicatedStorage:WaitForChild("ActivatePotion")
local potionExpiredRemote = ReplicatedStorage:WaitForChild("PotionExpired")
local potionActivatedRemote = ReplicatedStorage:WaitForChild("PotionActivated")

-- Wait for GetActivePotions remote function
local getActivePotionsRemote

-- Sound effects
local ACTIVATION_SOUND_ID = "rbxassetid://131961136" -- Potion drink sound
local EXPIRATION_SOUND_ID = "rbxassetid://131961136" -- Same for now

-- Pre-create sounds
local activationSound = Instance.new("Sound")
activationSound.SoundId = ACTIVATION_SOUND_ID
activationSound.Volume = 0.6
activationSound.Parent = SoundService

local expirationSound = Instance.new("Sound")
expirationSound.SoundId = EXPIRATION_SOUND_ID
expirationSound.Volume = 0.4
expirationSound.Parent = SoundService

-- Initialize the service
function PotionService:Initialize()
    print("PotionService: Initializing client-side potion management")
    
    -- Handle potion activation confirmations
    potionActivatedRemote.OnClientEvent:Connect(function(activePotionData)
        self:OnPotionActivated(activePotionData)
    end)
    
    -- Handle potion expiration notifications
    potionExpiredRemote.OnClientEvent:Connect(function(potionId)
        self:OnPotionExpired(potionId)
    end)
    
    -- Request initial active potions from server
    task.spawn(function()
        task.wait(1) -- Give server time to set up
        self:RequestActivePotions()
    end)
    
    -- Start UI update loop for countdown timers
    self:StartUIUpdateLoop()
end

-- Request active potions from server (for initial sync)
function PotionService:RequestActivePotions()
    task.spawn(function()
        -- Wait for the remote function to be available
        if not getActivePotionsRemote then
            getActivePotionsRemote = ReplicatedStorage:WaitForChild("GetActivePotions", 10)
        end
        
        if getActivePotionsRemote then
            print("PotionService: Requesting active potions from server")
            local success, serverActivePotions = pcall(function()
                return getActivePotionsRemote:InvokeServer()
            end)
            
            if success and serverActivePotions then
                self:SyncActivePotionsFromServer(serverActivePotions)
            else
                warn("PotionService: Failed to get active potions from server:", serverActivePotions)
            end
        else
            warn("PotionService: GetActivePotions remote not available after waiting")
        end
    end)
end

-- Sync active potions data from server
function PotionService:SyncActivePotionsFromServer(serverActivePotions)
    print("PotionService: Syncing active potions from server:", #serverActivePotions, "potions")
    
    -- Clear existing active potions
    activePotions = {}
    
    -- Add each active potion from server, but only if not expired
    local validPotions = 0
    for _, activePotionData in pairs(serverActivePotions) do
        if activePotionData.RemainingTime > 0 then
            activePotions[activePotionData.PotionId] = activePotionData
            print("PotionService: Loaded active potion:", activePotionData.PotionId, "expires in", activePotionData.RemainingTime, "seconds")
            validPotions = validPotions + 1
        else
            print("PotionService: Skipping expired potion:", activePotionData.PotionId, "(0 seconds remaining)")
        end
    end
    
    print("PotionService: Loaded", validPotions, "valid active potions")
    
    -- Notify UI about the sync
    self:NotifyCallbacks("PotionsSynced", activePotions)
end

-- Request potion activation from server
function PotionService:ActivatePotion(potionId)
    local potionConfig = PotionConfig.GetPotion(potionId)
    if not potionConfig then
        warn("PotionService: Invalid potion ID:", potionId)
        return false
    end
    
    -- Check if we already have this boost type active
    for _, activePotion in pairs(activePotions) do
        local activePotionConfig = PotionConfig.GetPotion(activePotion.PotionId)
        if activePotionConfig and activePotionConfig.BoostType == potionConfig.BoostType then
            warn("PotionService: Already have", potionConfig.BoostType, "potion active")
            -- TODO: Show UI notification
            return false
        end
    end
    
    print("PotionService: Requesting activation of", potionId)
    activatePotionRemote:FireServer(potionId)
    return true
end

-- Cancel an active potion
function PotionService:CancelActivePotion(potionId)
    if not activePotions[potionId] then
        warn("PotionService: Potion", potionId, "is not active")
        return false
    end
    
    print("PotionService: Requesting cancellation of", potionId)
    
    -- Get the cancel remote
    local cancelPotionRemote = ReplicatedStorage:FindFirstChild("CancelPotion")
    if not cancelPotionRemote then
        warn("PotionService: CancelPotion remote not found")
        return false
    end
    
    cancelPotionRemote:FireServer(potionId)
    return true
end

-- Handle successful potion activation from server
function PotionService:OnPotionActivated(activePotionData)
    print("PotionService: Potion activated:", activePotionData.PotionId)
    
    -- Store locally
    activePotions[activePotionData.PotionId] = activePotionData
    
    -- Play activation sound
    activationSound:Play()
    
    -- Show activation notification
    self:ShowPotionNotification(activePotionData.PotionId, "activated")
    
    -- Notify UI callbacks
    self:NotifyCallbacks("PotionActivated", activePotionData)
end

-- Handle potion expiration from server
function PotionService:OnPotionExpired(potionId)
    print("PotionService: Potion expired:", potionId)
    
    -- Remove from local storage
    activePotions[potionId] = nil
    
    -- Play expiration sound
    expirationSound:Play()
    
    -- Show expiration notification
    self:ShowPotionNotification(potionId, "expired")
    
    -- Notify UI callbacks
    self:NotifyCallbacks("PotionExpired", potionId)
end

-- Show potion notification (TODO: implement proper notification system)
function PotionService:ShowPotionNotification(potionId, action)
    local potionConfig = PotionConfig.GetPotion(potionId)
    if not potionConfig then return end
    
    local message = ""
    if action == "activated" then
        local boostText = potionConfig.BoostType == PotionConfig.BoostTypes.PET_MAGNET and potionConfig.BoostType or PotionConfig.FormatBoostAmount(potionConfig.BoostAmount, potionConfig.BoostType)
        message = string.format("%s activated! %s boost for %s", 
            potionConfig.Name, 
            boostText,
            PotionConfig.FormatDuration(potionConfig.Duration)
        )
    elseif action == "expired" then
        message = string.format("%s expired", potionConfig.Name)
    end
    
    print("NOTIFICATION:", message)
    -- TODO: Integrate with proper notification system when available
end

-- Start UI update loop for countdown timers
function PotionService:StartUIUpdateLoop()
    if uiUpdateConnection then
        uiUpdateConnection:Disconnect()
    end
    
    uiUpdateConnection = RunService.Heartbeat:Connect(function()
        local currentTime = os.time()
        local needsUpdate = false
        
        -- Update remaining time for all active potions
        for potionId, activePotion in pairs(activePotions) do
            local oldRemainingTime = activePotion.RemainingTime
            activePotion.RemainingTime = math.max(0, activePotion.ExpiresAt - currentTime)
            
            if activePotion.RemainingTime ~= oldRemainingTime then
                needsUpdate = true
            end
        end
        
        -- Notify UI if times changed
        if needsUpdate then
            self:NotifyCallbacks("PotionTimersUpdated", activePotions)
        end
    end)
end

-- Register callback for UI updates
function PotionService:RegisterCallback(callbackName, callback)
    if not potionCallbacks[callbackName] then
        potionCallbacks[callbackName] = {}
    end
    table.insert(potionCallbacks[callbackName], callback)
end

-- Unregister callback
function PotionService:UnregisterCallback(callbackName, callback)
    if potionCallbacks[callbackName] then
        for i, cb in ipairs(potionCallbacks[callbackName]) do
            if cb == callback then
                table.remove(potionCallbacks[callbackName], i)
                break
            end
        end
    end
end

-- Notify all registered callbacks
function PotionService:NotifyCallbacks(event, data)
    if potionCallbacks[event] then
        for _, callback in ipairs(potionCallbacks[event]) do
            task.spawn(callback, data)
        end
    end
end

-- Get all active potions
function PotionService:GetActivePotions()
    return activePotions
end

-- Get active potion by ID
function PotionService:GetActivePotion(potionId)
    return activePotions[potionId]
end

-- Check if a boost type is currently active
function PotionService:HasActiveBoost(boostType)
    for _, activePotion in pairs(activePotions) do
        local potionConfig = PotionConfig.GetPotion(activePotion.PotionId)
        if potionConfig and potionConfig.BoostType == boostType then
            return true
        end
    end
    return false
end

-- Get boost multiplier for a specific boost type
function PotionService:GetBoostMultiplier(boostType)
    for _, activePotion in pairs(activePotions) do
        local potionConfig = PotionConfig.GetPotion(activePotion.PotionId)
        if potionConfig and potionConfig.BoostType == boostType then
            return potionConfig.BoostAmount
        end
    end
    return 1 -- No boost
end

-- Get formatted time remaining for active potion
function PotionService:GetFormattedTimeRemaining(potionId)
    local activePotion = activePotions[potionId]
    if not activePotion then
        return "0s"
    end
    
    return PotionConfig.FormatDuration(activePotion.RemainingTime)
end

-- Cleanup on service destruction
function PotionService:Cleanup()
    if uiUpdateConnection then
        uiUpdateConnection:Disconnect()
        uiUpdateConnection = nil
    end
    
    activePotions = {}
    potionCallbacks = {}
end

-- Singleton instance
local instance = PotionService
instance:Initialize()

return instance