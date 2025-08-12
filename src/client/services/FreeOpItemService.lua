-- Client FreeOpItemService - Manages Free OP Item UI state and interactions
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local FreeOpItemService = {}
FreeOpItemService.__index = FreeOpItemService

local player = Players.LocalPlayer

-- UI state callbacks
local uiCallbacks = {}

function FreeOpItemService:Initialize()
    print("FreeOpItemService: Initializing client-side service")
    
    -- Wait for remote events to be created by server
    task.spawn(function()
        local getFreeOpItemDataRemote = ReplicatedStorage:WaitForChild("GetFreeOpItemData", 30)
        local claimFreeOpItemRemote = ReplicatedStorage:WaitForChild("ClaimFreeOpItem", 30)
        
        if getFreeOpItemDataRemote and claimFreeOpItemRemote then
            print("FreeOpItemService: Connected to server remotes")
        else
            warn("FreeOpItemService: Failed to connect to server remotes")
        end
    end)
end

-- Register callback for UI updates
function FreeOpItemService:RegisterCallback(callbackName, callback)
    if not uiCallbacks[callbackName] then
        uiCallbacks[callbackName] = {}
    end
    table.insert(uiCallbacks[callbackName], callback)
end

-- Unregister callback
function FreeOpItemService:UnregisterCallback(callbackName, callback)
    if uiCallbacks[callbackName] then
        for i, cb in ipairs(uiCallbacks[callbackName]) do
            if cb == callback then
                table.remove(uiCallbacks[callbackName], i)
                break
            end
        end
    end
end

-- Notify all registered callbacks
function FreeOpItemService:NotifyCallbacks(event, data)
    if uiCallbacks[event] then
        for _, callback in ipairs(uiCallbacks[event]) do
            task.spawn(callback, data)
        end
    end
end

-- Get free OP item data from server
function FreeOpItemService:GetFreeOpItemData()
    local getFreeOpItemDataRemote = ReplicatedStorage:FindFirstChild("GetFreeOpItemData")
    if getFreeOpItemDataRemote then
        local success, data = pcall(function()
            return getFreeOpItemDataRemote:InvokeServer()
        end)
        
        if success then
            return data
        else
            warn("FreeOpItemService: Failed to get data from server:", data)
            return nil
        end
    else
        warn("FreeOpItemService: GetFreeOpItemData remote not found")
        return nil
    end
end

-- Claim free OP item reward
function FreeOpItemService:ClaimReward()
    local claimFreeOpItemRemote = ReplicatedStorage:FindFirstChild("ClaimFreeOpItem")
    if claimFreeOpItemRemote then
        claimFreeOpItemRemote:FireServer()
        print("FreeOpItemService: Sent claim request to server")
        
        -- Notify UI callbacks
        self:NotifyCallbacks("RewardClaimed", {})
        
        return true
    else
        warn("FreeOpItemService: ClaimFreeOpItem remote not found")
        return false
    end
end

-- Check if player can claim reward
function FreeOpItemService:CanClaim()
    local data = self:GetFreeOpItemData()
    return data and data.canClaim or false
end

-- Get progress percentage (0-100)
function FreeOpItemService:GetProgress()
    local data = self:GetFreeOpItemData()
    return data and (data.progress * 100) or 0
end

-- Get time remaining in seconds
function FreeOpItemService:GetTimeRemaining()
    local data = self:GetFreeOpItemData()
    return data and data.timeRemaining or 0
end

-- Cleanup
function FreeOpItemService:Cleanup()
    uiCallbacks = {}
end

-- Singleton instance
local instance = FreeOpItemService
instance:Initialize()

return instance