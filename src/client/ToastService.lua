-- Toast Service
-- Manages toast notifications with cooldown to prevent spam

local ToastService = {}

local currentToast = nil
local lastToastTime = 0
local TOAST_COOLDOWN = 3 -- seconds between same message

-- Callbacks for UI updates
local showToastCallback = nil

function ToastService.initialize()
    -- Reset state
    currentToast = nil
    lastToastTime = 0
end

function ToastService.setShowToastCallback(callback)
    showToastCallback = callback
end

function ToastService.showToast(message, duration)
    local currentTime = tick()
    
    -- Check if we're showing the same message too soon
    if currentToast == message and currentTime - lastToastTime < TOAST_COOLDOWN then
        return -- Skip to prevent spam
    end
    
    -- Update state
    currentToast = message
    lastToastTime = currentTime
    
    -- Call the UI update callback
    if showToastCallback then
        showToastCallback(message, duration or 3)
    end
end

-- Specific toast messages
function ToastService.showInventoryFullToast()
    ToastService.showToast("You have the max limit of pets (1k) send them to heaven to pick more up!", 4)
end

return ToastService