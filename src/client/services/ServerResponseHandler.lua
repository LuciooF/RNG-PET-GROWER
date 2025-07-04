-- Server Response Handler
-- Handles server responses for rollback mechanism and other client-server communication
-- Integrates with PetAssignmentService for rollback functionality

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetAssignmentService = require(script.Parent.PetAssignmentService)

local ServerResponseHandler = {}

-- Track request mappings (petUniqueId -> requestId)
local requestIdMap = {}

-- Initialize response handlers
function ServerResponseHandler:Initialize()
    local success, error = pcall(function()
        local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
        if not remotes then
            warn("ServerResponseHandler: Remotes folder not found")
            return
        end
        
        -- Set up assignment response handler
        local assignPetResponse = remotes:WaitForChild("AssignPetResponse", 5)
        if assignPetResponse then
            assignPetResponse.OnClientEvent:Connect(function(success, petUniqueId, reason)
                self:HandleAssignmentResponse(success, petUniqueId, reason)
            end)
        else
            warn("ServerResponseHandler: AssignPetResponse remote not found")
        end
        
        -- Set up unassignment response handler
        local unassignPetResponse = remotes:WaitForChild("UnassignPetResponse", 5)
        if unassignPetResponse then
            unassignPetResponse.OnClientEvent:Connect(function(success, petUniqueId, reason)
                self:HandleUnassignmentResponse(success, petUniqueId, reason)
            end)
        else
            warn("ServerResponseHandler: UnassignPetResponse remote not found")
        end
        
    end)
    
    if not success then
        warn("ServerResponseHandler: Failed to initialize:", error)
    end
end

-- Handle assignment response from server
function ServerResponseHandler:HandleAssignmentResponse(success, petUniqueId, reason)
    local requestId = requestIdMap[petUniqueId]
    if not requestId then
        warn("ServerResponseHandler: No request ID found for pet:", petUniqueId)
        return
    end
    
    if success then
        -- Operation was successful, confirm it (prevents rollback)
        PetAssignmentService.confirmServerOperation(requestId)
    else
        -- Operation failed, trigger rollback
        PetAssignmentService.forceRollback(requestId, reason)
        warn("ServerResponseHandler: Assignment failed, rolled back:", reason)
    end
    
    -- Clean up request mapping
    requestIdMap[petUniqueId] = nil
end

-- Handle unassignment response from server
function ServerResponseHandler:HandleUnassignmentResponse(success, petUniqueId, reason)
    local requestId = requestIdMap[petUniqueId]
    if not requestId then
        warn("ServerResponseHandler: No request ID found for pet:", petUniqueId)
        return
    end
    
    if success then
        -- Operation was successful, confirm it (prevents rollback)
        PetAssignmentService.confirmServerOperation(requestId)
    else
        -- Operation failed, trigger rollback
        PetAssignmentService.forceRollback(requestId, reason)
        warn("ServerResponseHandler: Unassignment failed, rolled back:", reason)
    end
    
    -- Clean up request mapping
    requestIdMap[petUniqueId] = nil
end

-- Register a request for tracking (called by PetAssignmentService)
function ServerResponseHandler:RegisterRequest(requestId, petUniqueId)
    requestIdMap[petUniqueId] = requestId
end

-- Clean up old request mappings (cleanup function)
function ServerResponseHandler:CleanupOldRequests()
    -- Note: This could be enhanced with timestamps if needed
    -- For now, requests are cleaned up when responses are received
end

-- Get pending request count (for debugging)
function ServerResponseHandler:getPendingRequestCount()
    local count = 0
    for _ in pairs(requestIdMap) do
        count = count + 1
    end
    return count
end

return ServerResponseHandler