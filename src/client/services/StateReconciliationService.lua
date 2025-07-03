-- State Reconciliation Service
-- Periodically syncs client and server state to detect and resolve discrepancies
-- Helps maintain data consistency in optimistic update architecture

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Store = require(ReplicatedStorage.store)
local PlayerActions = require(ReplicatedStorage.store.actions.PlayerActions)

local StateReconciliationService = {}

-- Reconciliation settings
local RECONCILIATION_INTERVAL = 30 -- seconds between reconciliation checks
local reconciliationConnection

-- Initialize periodic state reconciliation
function StateReconciliationService:Initialize()
    local success, error = pcall(function()
        print("StateReconciliationService: Initializing periodic state reconciliation")
        
        -- Start periodic reconciliation
        reconciliationConnection = task.spawn(function()
            while true do
                task.wait(RECONCILIATION_INTERVAL)
                self:PerformReconciliation()
            end
        end)
        
        print("StateReconciliationService: Initialized successfully")
    end)
    
    if not success then
        warn("StateReconciliationService: Failed to initialize:", error)
    end
end

-- Perform state reconciliation with server
function StateReconciliationService:PerformReconciliation()
    local success, error = pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then
            warn("StateReconciliationService: Remotes folder not found")
            return
        end
        
        local reconcileRemote = remotes:FindFirstChild("RequestStateReconciliation")
        if reconcileRemote then
            -- Request full state from server
            reconcileRemote:FireServer()
            print("StateReconciliationService: Requested state reconciliation from server")
        else
            warn("StateReconciliationService: RequestStateReconciliation remote not found")
        end
    end)
    
    if not success then
        warn("StateReconciliationService: Reconciliation failed:", error)
    end
end

-- Handle reconciliation response from server
function StateReconciliationService:HandleReconciliationResponse(serverState)
    local success, error = pcall(function()
        local clientState = Store:getState().player
        if not clientState then
            warn("StateReconciliationService: No client state available")
            return
        end
        
        -- Compare and reconcile pets
        self:ReconcilePets(clientState, serverState)
        
        -- Compare and reconcile companions
        self:ReconcileCompanions(clientState, serverState)
        
        -- Compare and reconcile resources (with tolerance for ongoing operations)
        self:ReconcileResources(clientState, serverState)
        
        print("StateReconciliationService: State reconciliation completed")
    end)
    
    if not success then
        warn("StateReconciliationService: Failed to handle reconciliation response:", error)
    end
end

-- Reconcile pet collections
function StateReconciliationService:ReconcilePets(clientState, serverState)
    local clientPets = clientState.ownedPets or {}
    local serverPets = serverState.ownedPets or {}
    
    -- Check for discrepancies
    if #clientPets ~= #serverPets then
        warn("StateReconciliationService: Pet count mismatch - Client:", #clientPets, "Server:", #serverPets)
        
        -- Use server state as authoritative
        Store:dispatch(PlayerActions.setPets(serverPets))
        print("StateReconciliationService: Pet collection reconciled with server state")
    else
        -- TODO: Could add more detailed comparison of individual pets if needed
        print("StateReconciliationService: Pet counts match")
    end
end

-- Reconcile companion assignments
function StateReconciliationService:ReconcileCompanions(clientState, serverState)
    local clientCompanions = clientState.companionPets or {}
    local serverCompanions = serverState.companionPets or {}
    
    -- Check for discrepancies
    if #clientCompanions ~= #serverCompanions then
        warn("StateReconciliationService: Companion count mismatch - Client:", #clientCompanions, "Server:", #serverCompanions)
        
        -- Use server state as authoritative
        Store:dispatch(PlayerActions.setCompanions(serverCompanions))
        print("StateReconciliationService: Companions reconciled with server state")
    else
        -- Check if the same pets are assigned
        local mismatch = false
        for i, clientPet in ipairs(clientCompanions) do
            local serverPet = serverCompanions[i]
            if not serverPet or clientPet.uniqueId ~= serverPet.uniqueId then
                mismatch = true
                break
            end
        end
        
        if mismatch then
            warn("StateReconciliationService: Companion assignment mismatch detected")
            Store:dispatch(PlayerActions.setCompanions(serverCompanions))
            print("StateReconciliationService: Companions reconciled with server state")
        else
            print("StateReconciliationService: Companions match")
        end
    end
end

-- Reconcile resources (with tolerance for ongoing operations)
function StateReconciliationService:ReconcileResources(clientState, serverState)
    local clientResources = clientState.resources or {}
    local serverResources = serverState.resources or {}
    
    -- Allow small discrepancies for ongoing operations (e.g., pet collection)
    local TOLERANCE = 100 -- Allow up to 100 money difference
    
    local moneyDiff = math.abs((clientResources.money or 0) - (serverResources.money or 0))
    local rebirthsDiff = math.abs((clientResources.rebirths or 0) - (serverResources.rebirths or 0))
    local diamondsDiff = math.abs((clientResources.diamonds or 0) - (serverResources.diamonds or 0))
    
    if moneyDiff > TOLERANCE or rebirthsDiff > 0 or diamondsDiff > 0 then
        warn("StateReconciliationService: Resource mismatch detected")
        warn("  Money diff:", moneyDiff, "Rebirths diff:", rebirthsDiff, "Diamonds diff:", diamondsDiff)
        
        -- Use server state as authoritative
        Store:dispatch(PlayerActions.setResources(
            serverResources.money or 0,
            serverResources.rebirths or 0,
            serverResources.diamonds or 0
        ))
        print("StateReconciliationService: Resources reconciled with server state")
    else
        print("StateReconciliationService: Resources match (within tolerance)")
    end
end

-- Cleanup function
function StateReconciliationService:Cleanup()
    if reconciliationConnection then
        task.cancel(reconciliationConnection)
        reconciliationConnection = nil
        print("StateReconciliationService: Cleanup completed")
    end
end

-- Force immediate reconciliation (for debugging or manual sync)
function StateReconciliationService:ForceReconciliation()
    print("StateReconciliationService: Forcing immediate reconciliation")
    self:PerformReconciliation()
end

return StateReconciliationService