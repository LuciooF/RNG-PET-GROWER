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

-- Base number of pets that can be assigned as companions
local BASE_ASSIGNED_PETS = 3

-- Get the current maximum pet slots for a player
local function getMaxAssignedPets()
    local currentState = Store:getState()
    if currentState and currentState.player then
        local maxSlots = currentState.player.maxSlots or BASE_ASSIGNED_PETS
        print(string.format("PetAssignmentService: getMaxAssignedPets returning %d", maxSlots))
        return maxSlots
    end
    print(string.format("PetAssignmentService: No state available, returning base %d", BASE_ASSIGNED_PETS))
    return BASE_ASSIGNED_PETS
end

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
    local maxPets = getMaxAssignedPets()
    -- Check if already at maximum capacity
    if #companionPets >= maxPets then
        return false, "Maximum companions reached (" .. maxPets .. ")"
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
    local maxPets = getMaxAssignedPets()
    
    return maxPets - #companionPets
end

-- Get all assigned pets
function PetAssignmentService.getAssignedPets()
    local currentState = Store:getState()
    return currentState.player.companionPets or {}
end

-- Get maximum assignable pet slots
function PetAssignmentService.getMaxSlots()
    return getMaxAssignedPets()
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

-- Equip the best pets automatically (replaces current equipped pets)
function PetAssignmentService.equipBestPets()
    local success, result = pcall(function()
        -- Get current state
        local currentState = Store:getState()
        if not currentState or not currentState.player then
            return false, "Player state not available"
        end
        
        local ownedPets = currentState.player.ownedPets or {}
        local currentCompanions = currentState.player.companionPets or {}
        
        -- Import PetConfig for rarity calculations
        local PetConfig = require(ReplicatedStorage.Shared.config.PetConfig)
        
        -- Get all pets with their comprehensive info for sorting
        local petsWithInfo = {}
        for _, pet in ipairs(ownedPets) do
            local comprehensiveInfo = PetConfig:GetComprehensivePetInfo(pet.id, pet.aura, pet.size)
            if comprehensiveInfo then
                table.insert(petsWithInfo, {
                    pet = pet,
                    combinedProbability = comprehensiveInfo.combinedProbability,
                    moneyMultiplier = comprehensiveInfo.moneyMultiplier,
                    enhancedValue = comprehensiveInfo.enhancedValue
                })
            end
        end
        
        -- Sort pets by rarity (lowest probability = rarest = best)
        table.sort(petsWithInfo, function(a, b)
            -- Primary: combined probability (rarer first)
            if a.combinedProbability ~= b.combinedProbability then
                return a.combinedProbability < b.combinedProbability
            end
            
            -- Secondary: money multiplier (higher boost first)
            if a.moneyMultiplier ~= b.moneyMultiplier then
                return a.moneyMultiplier > b.moneyMultiplier
            end
            
            -- Tertiary: enhanced value (higher value first)
            return a.enhancedValue > b.enhancedValue
        end)
        
        -- Determine how many slots we have (3 base + any unlocked slots)
        local maxSlots = getMaxAssignedPets()
        
        -- Get the best pets (up to maxSlots)
        local bestPets = {}
        for i = 1, math.min(maxSlots, #petsWithInfo) do
            table.insert(bestPets, petsWithInfo[i].pet)
        end
        
        -- Check if we already have the optimal setup
        if #currentCompanions == #bestPets then
            local alreadyOptimal = true
            local bestPetIds = {}
            for _, bestPet in ipairs(bestPets) do
                bestPetIds[bestPet.uniqueId] = true
            end
            
            for _, companion in ipairs(currentCompanions) do
                if not bestPetIds[companion.uniqueId] then
                    alreadyOptimal = false
                    break
                end
            end
            
            if alreadyOptimal then
                return true, "Already equipped with best pets"
            end
        end
        
        -- Clean up old rollback history
        cleanupRollbackHistory()
        
        -- First, unassign all current pets using the proper queue system
        for _, companion in ipairs(currentCompanions) do
            PetAssignmentService.unassignPet(companion)
        end
        
        -- Wait for all unassignments to actually complete by checking companion count
        local maxWaitTime = 5 -- Maximum 5 seconds to wait
        local startTime = tick()
        
        while tick() - startTime < maxWaitTime do
            local currentState = Store:getState()
            local currentCompanionCount = #(currentState.player.companionPets or {})
            
            if currentCompanionCount == 0 then
                print("PetAssignmentService: All pets unassigned, proceeding with assignments")
                break
            end
            
            task.wait(0.1) -- Check every 100ms
        end
        
        -- Small frame wait to ensure Redux state update is processed
        task.wait()
        
        -- Then assign the best pets
        for _, bestPet in ipairs(bestPets) do
            PetAssignmentService.assignPet(bestPet)
        end
        
        return true, string.format("Equipped %d best pets", #bestPets)
    end)
    
    if not success then
        warn("PetAssignmentService: Failed to equip best pets:", result)
        return false, result
    end
    
    print("PetAssignmentService:", result)
    return true, result
end

return PetAssignmentService