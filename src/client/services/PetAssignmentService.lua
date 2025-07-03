-- Pet Assignment Service
-- Handles pet assignment/unassignment logic for companion pets
-- Extracted from PetInventoryPanel.lua for better separation of concerns
-- Enhanced with rollback mechanism and request queuing for reliability

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Store = require(ReplicatedStorage.store)
local PlayerActions = require(ReplicatedStorage.store.actions.PlayerActions)

-- Lazy load ServerResponseHandler to avoid circular dependency
local ServerResponseHandler

local PetAssignmentService = {}

-- Maximum number of pets that can be assigned as companions
local MAX_ASSIGNED_PETS = 3

-- Request queuing and rollback management
local pendingRequests = {} -- Queue for pending server requests
local rollbackHistory = {} -- History for rollback operations
local isProcessingQueue = false

-- Rollback timeout (in seconds)
local ROLLBACK_TIMEOUT = 10

-- Generate unique request ID for tracking
local function generateRequestId()
    return tostring(tick() .. "_" .. math.random(1000, 9999))
end

-- Store rollback state before making changes
local function storeRollbackState(requestId, operation, petData)
    local currentState = Store:getState()
    rollbackHistory[requestId] = {
        operation = operation,
        petData = petData,
        previousCompanions = currentState.player.companionPets or {},
        timestamp = tick()
    }
end

-- Execute rollback for failed operation
local function executeRollback(requestId, reason)
    local rollbackData = rollbackHistory[requestId]
    if not rollbackData then
        warn("PetAssignmentService: No rollback data found for request:", requestId)
        return
    end
    
    warn("PetAssignmentService: Rolling back operation due to:", reason)
    
    -- Restore previous companion state
    Store:dispatch(PlayerActions.setCompanions(rollbackData.previousCompanions))
    
    -- Clean up rollback history
    rollbackHistory[requestId] = nil
    
    -- Show user feedback (could be enhanced with UI notification)
    warn("Pet assignment was reverted:", reason)
end

-- Clean up old rollback history entries
local function cleanupRollbackHistory()
    local currentTime = tick()
    for requestId, data in pairs(rollbackHistory) do
        if currentTime - data.timestamp > ROLLBACK_TIMEOUT then
            rollbackHistory[requestId] = nil
        end
    end
end

-- Process pending requests queue
local function processRequestQueue()
    if isProcessingQueue or #pendingRequests == 0 then
        return
    end
    
    isProcessingQueue = true
    
    local request = table.remove(pendingRequests, 1)
    if not request then
        isProcessingQueue = false
        return
    end
    
    -- Execute the server request
    task.spawn(function()
        local success, result = pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if not remotes then
                error("Remotes folder not found")
            end
            
            local remoteName = request.operation == "assign" and "AssignPet" or "UnassignPet"
            local remote = remotes:FindFirstChild(remoteName) or remotes:FindFirstChild(request.operation == "assign" and "EquipCompanion" or "UnequipCompanion")
            
            if not remote then
                error("Remote " .. remoteName .. " not found")
            end
            
            -- Fire server request with timeout
            remote:FireServer(request.petId)
            
            -- Wait for server response or timeout
            local startTime = tick()
            while tick() - startTime < ROLLBACK_TIMEOUT do
                task.wait(0.1)
                -- Check if server responded (would be handled by separate confirmation system)
                if rollbackHistory[request.requestId] == nil then
                    -- Request was confirmed, no rollback needed
                    break
                end
            end
            
            -- If we reach here and rollback data still exists, the request timed out
            if rollbackHistory[request.requestId] then
                executeRollback(request.requestId, "Server response timeout")
            end
        end)
        
        if not success then
            -- Server request failed
            executeRollback(request.requestId, "Server request failed: " .. tostring(result))
        end
        
        -- Continue processing queue
        isProcessingQueue = false
        processRequestQueue()
    end)
end

-- Lazy load ServerResponseHandler
local function getServerResponseHandler()
    if not ServerResponseHandler then
        ServerResponseHandler = require(script.Parent.ServerResponseHandler)
    end
    return ServerResponseHandler
end

-- Add request to queue
local function queueRequest(operation, petId, requestId)
    table.insert(pendingRequests, {
        operation = operation,
        petId = petId,
        requestId = requestId,
        timestamp = tick()
    })
    
    -- Register request with response handler for tracking
    local responseHandler = getServerResponseHandler()
    responseHandler:RegisterRequest(requestId, petId)
    
    -- Start processing if not already running
    processRequestQueue()
end

-- Check if a pet can be assigned
function PetAssignmentService.canAssignPet(companionPets, petToAssign)
    -- Check if already at maximum capacity
    if #companionPets >= MAX_ASSIGNED_PETS then
        return false, "Maximum companions reached (" .. MAX_ASSIGNED_PETS .. ")"
    end
    
    -- Check if pet is already assigned
    for _, assignedPet in ipairs(companionPets) do
        if assignedPet.uniqueId == petToAssign.uniqueId then
            return false, "Pet is already assigned"
        end
    end
    
    return true, "Can assign pet"
end

-- Check if a pet can be unassigned
function PetAssignmentService.canUnassignPet(companionPets, petToUnassign)
    -- Check if pet is actually assigned
    for _, assignedPet in ipairs(companionPets) do
        if assignedPet.uniqueId == petToUnassign.uniqueId then
            return true, "Can unassign pet"
        end
    end
    
    return false, "Pet is not assigned"
end

-- Assign a pet as companion (client-side immediate with server sync and rollback)
function PetAssignmentService.assignPet(petToAssign)
    -- Clean up old rollback history
    cleanupRollbackHistory()
    
    local success, result = pcall(function()
        -- Validate input
        if not petToAssign or not petToAssign.uniqueId then
            return false, "Invalid pet data provided"
        end
        
        -- Get current state
        local currentState = Store:getState()
        if not currentState or not currentState.player then
            return false, "Player state not available"
        end
        
        local companionPets = currentState.player.companionPets or {}
        return true, companionPets
    end)
    
    if not success then
        warn("PetAssignmentService: Assignment validation failed:", result)
        return false, result
    end
    
    local _, companionPets = result
    if not companionPets then
        local currentState = Store:getState()
        companionPets = currentState.player.companionPets or {}
    end
    
    -- Validate assignment
    local canAssign, reason = PetAssignmentService.canAssignPet(companionPets, petToAssign)
    if not canAssign then
        warn("Cannot assign pet:", reason)
        return false, reason
    end
    
    -- Generate request ID for tracking
    local requestId = generateRequestId()
    
    -- Store rollback state before making changes
    storeRollbackState(requestId, "assign", petToAssign)
    
    -- Dispatch immediate Redux action for instant UI update
    Store:dispatch(PlayerActions.equipCompanion(petToAssign))
    
    -- Queue server request with rollback protection
    queueRequest("assign", petToAssign.uniqueId, requestId)
    
    return true, "Pet assigned successfully"
end

-- Unassign a pet from companions (client-side immediate with server sync and rollback)
function PetAssignmentService.unassignPet(petToUnassign)
    -- Clean up old rollback history
    cleanupRollbackHistory()
    
    local success, result = pcall(function()
        -- Validate input
        if not petToUnassign or not petToUnassign.uniqueId then
            return false, "Invalid pet data provided"
        end
        
        -- Get current state
        local currentState = Store:getState()
        if not currentState or not currentState.player then
            return false, "Player state not available"
        end
        
        local companionPets = currentState.player.companionPets or {}
        return true, companionPets
    end)
    
    if not success then
        warn("PetAssignmentService: Unassignment validation failed:", result)
        return false, result
    end
    
    local _, companionPets = result
    if not companionPets then
        local currentState = Store:getState()
        companionPets = currentState.player.companionPets or {}
    end
    
    -- Validate unassignment
    local canUnassign, reason = PetAssignmentService.canUnassignPet(companionPets, petToUnassign)
    if not canUnassign then
        warn("Cannot unassign pet:", reason)
        return false, reason
    end
    
    -- Generate request ID for tracking
    local requestId = generateRequestId()
    
    -- Store rollback state before making changes
    storeRollbackState(requestId, "unassign", petToUnassign)
    
    -- Dispatch immediate Redux action for instant UI update
    Store:dispatch(PlayerActions.unequipCompanion(petToUnassign.uniqueId))
    
    -- Queue server request with rollback protection
    queueRequest("unassign", petToUnassign.uniqueId, requestId)
    
    return true, "Pet unassigned successfully"
end

-- Get assignment status for a pet
function PetAssignmentService.getPetAssignmentStatus(pet)
    local currentState = Store:getState()
    local companionPets = currentState.player.companionPets or {}
    
    for _, assignedPet in ipairs(companionPets) do
        if assignedPet.uniqueId == pet.uniqueId then
            return true -- Pet is assigned
        end
    end
    
    return false -- Pet is not assigned
end

-- Get available assignment slots
function PetAssignmentService.getAvailableSlots()
    local currentState = Store:getState()
    local companionPets = currentState.player.companionPets or {}
    
    return MAX_ASSIGNED_PETS - #companionPets
end

-- Get all assigned pets
function PetAssignmentService.getAssignedPets()
    local currentState = Store:getState()
    return currentState.player.companionPets or {}
end

-- Confirm successful server operation (call this when server confirms)
function PetAssignmentService.confirmServerOperation(requestId)
    if rollbackHistory[requestId] then
        -- Operation was successful, remove from rollback history
        rollbackHistory[requestId] = nil
    end
end

-- Force rollback for a specific request (call this when server rejects)
function PetAssignmentService.forceRollback(requestId, reason)
    executeRollback(requestId, reason or "Server rejected operation")
end

-- Get pending request count (for debugging)
function PetAssignmentService.getPendingRequestCount()
    return #pendingRequests
end

-- Get rollback history count (for debugging)
function PetAssignmentService.getRollbackHistoryCount()
    local count = 0
    for _ in pairs(rollbackHistory) do
        count = count + 1
    end
    return count
end

return PetAssignmentService