-- AuthorizationUtils - Centralized authorization system for debug/admin features
local AuthorizationUtils = {}

-- List of authorized user IDs for debug/admin features
-- Add new tester IDs to this list as needed
AuthorizationUtils.AUTHORIZED_USER_IDS = {
    7273741008, -- LuciooF
    3768499941 -- Aushi
}

-- Check if a player is authorized for debug/admin features
function AuthorizationUtils.isAuthorized(player)
    if not player or not player.UserId then
        return false
    end
    
    for _, authorizedId in ipairs(AuthorizationUtils.AUTHORIZED_USER_IDS) do
        if player.UserId == authorizedId then
            return true
        end
    end
    
    return false
end

-- Get authorized user IDs list (for logging purposes)
function AuthorizationUtils.getAuthorizedIds()
    return AuthorizationUtils.AUTHORIZED_USER_IDS
end

-- Log unauthorized access attempt
function AuthorizationUtils.logUnauthorizedAccess(player, feature)
    warn("AuthorizationUtils: Unauthorized access attempt to", feature, "from", player.Name, "UserID:", player.UserId)
end

return AuthorizationUtils