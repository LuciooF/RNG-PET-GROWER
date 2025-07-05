local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Rodux = require(Packages.rodux)

local PlayerActions = require(script.Parent.Parent.actions.PlayerActions)

local initialState = {
    resources = {
        money = 0,
        rebirths = 0,
        diamonds = 0,
    },
    boughtPlots = {},
    ownedPets = {},
    companionPets = {},
    activeBoosts = {},
    settings = {
        musicEnabled = true,
        sfxEnabled = true,
    },
    stats = {
        playtime = 0,
        joins = 0,
        totalPetsCollected = 0,
        totalRebirths = 0,
    },
    maxSlots = 3
}

local function findPetIndex(pets, petId)
    for i, pet in ipairs(pets) do
        if pet.id == petId then
            return i
        end
    end
    return nil
end

local function findBoostIndex(boosts, boostId)
    for i, boost in ipairs(boosts) do
        if boost.id == boostId then
            return i
        end
    end
    return nil
end

local playerReducer = Rodux.createReducer(initialState, {
    [PlayerActions.SET_RESOURCES] = function(state, action)
        -- Defensive check for nil state
        if not state then
            state = initialState
        end
        
        -- Create new state using table copy instead of Rodux.Dictionary.join
        local newState = {}
        for k, v in pairs(state) do
            newState[k] = v
        end
        newState.resources = {
            money = action.money or 0,
            rebirths = action.rebirths or 0,
            diamonds = action.diamonds or 0,
        }
        return newState
    end,
    
    [PlayerActions.ADD_MONEY] = function(state, action)
        -- Defensive check for nil state
        if not state then
            state = initialState
        end
        if not state.resources then
            state = {
                resources = initialState.resources,
                boughtPlots = state.boughtPlots or {},
                ownedPets = state.ownedPets or {},
                companionPets = state.companionPets or {},
                activeBoosts = state.activeBoosts or {},
                settings = state.settings or initialState.settings,
                stats = state.stats or initialState.stats,
            }
        end
        
        -- Create new state using table copy
        local newState = {}
        for k, v in pairs(state) do
            newState[k] = v
        end
        
        -- Create new resources object
        local newResources = {}
        for k, v in pairs(state.resources) do
            newResources[k] = v
        end
        newResources.money = (state.resources.money or 0) + (action.amount or 0)
        newState.resources = newResources
        
        return newState
    end,
    
    [PlayerActions.SPEND_MONEY] = function(state, action)
        local newState = {}
        for k, v in pairs(state) do
            newState[k] = v
        end
        
        local newResources = {}
        for k, v in pairs(state.resources) do
            newResources[k] = v
        end
        newResources.money = math.max(0, state.resources.money - action.amount)
        
        newState.resources = newResources
        return newState
    end,
    
    [PlayerActions.ADD_DIAMONDS] = function(state, action)
        local newState = {}
        for k, v in pairs(state) do
            newState[k] = v
        end
        
        local newResources = {}
        for k, v in pairs(state.resources) do
            newResources[k] = v
        end
        newResources.diamonds = state.resources.diamonds + action.amount
        
        newState.resources = newResources
        return newState
    end,
    
    [PlayerActions.SPEND_DIAMONDS] = function(state, action)
        local newState = {}
        for k, v in pairs(state) do
            newState[k] = v
        end
        
        local newResources = {}
        for k, v in pairs(state.resources) do
            newResources[k] = v
        end
        newResources.diamonds = math.max(0, state.resources.diamonds - action.amount)
        
        newState.resources = newResources
        return newState
    end,
    
    [PlayerActions.SET_REBIRTHS] = function(state, action)
        local newState = {}
        for k, v in pairs(state) do
            newState[k] = v
        end
        
        local newResources = {}
        for k, v in pairs(state.resources) do
            newResources[k] = v
        end
        newResources.rebirths = action.amount
        
        newState.resources = newResources
        return newState
    end,
    
    [PlayerActions.ADD_PLOT] = function(state, action)
        local newBoughtPlots = {}
        for i, plotId in ipairs(state.boughtPlots) do
            newBoughtPlots[i] = plotId
        end
        table.insert(newBoughtPlots, action.plotId)
        
        local newState = {}
        for k, v in pairs(state) do
            newState[k] = v
        end
        newState.boughtPlots = newBoughtPlots
        return newState
    end,
    
    [PlayerActions.ADD_PET] = function(state, action)
        -- Defensive check for nil state
        if not state then
            state = initialState
        end
        if not state.ownedPets then
            state = {
                resources = state.resources or initialState.resources,
                boughtPlots = state.boughtPlots or {},
                ownedPets = {},
                companionPets = state.companionPets or {},
                activeBoosts = state.activeBoosts or {},
                settings = state.settings or initialState.settings,
                stats = state.stats or initialState.stats,
            }
        end
        
        -- Create new state using table copy
        local newState = {}
        for k, v in pairs(state) do
            newState[k] = v
        end
        
        -- Add pet to owned pets array
        local newOwnedPets = {}
        for i, pet in ipairs(state.ownedPets) do
            newOwnedPets[i] = pet
        end
        table.insert(newOwnedPets, action.petData)
        newState.ownedPets = newOwnedPets
        
        -- Update stats
        local newStats = {}
        for k, v in pairs(state.stats or {}) do
            newStats[k] = v
        end
        newStats.totalPetsCollected = (newStats.totalPetsCollected or 0) + 1
        newState.stats = newStats
        
        return newState
    end,
    
    [PlayerActions.REMOVE_PET] = function(state, action)
        local petIndex = findPetIndex(state.ownedPets, action.petId)
        if petIndex then
            local newOwnedPets = {}
            for i, pet in ipairs(state.ownedPets) do
                if i ~= petIndex then
                    table.insert(newOwnedPets, pet)
                end
            end
            
            local newState = {}
            for k, v in pairs(state) do
                newState[k] = v
            end
            newState.ownedPets = newOwnedPets
            return newState
        end
        return state
    end,
    
    [PlayerActions.EQUIP_COMPANION] = function(state, action)
        local maxSlots = state.maxSlots or 3
        if #state.companionPets >= maxSlots then
            return state
        end
        
        -- Create new companionPets array with plain Lua table operations
        local newCompanionPets = {}
        for i, pet in ipairs(state.companionPets) do
            newCompanionPets[i] = pet
        end
        table.insert(newCompanionPets, action.petData)
        
        -- Create new state using table copy
        local newState = {}
        for k, v in pairs(state) do
            newState[k] = v
        end
        newState.companionPets = newCompanionPets
        return newState
    end,
    
    [PlayerActions.UNEQUIP_COMPANION] = function(state, action)
        local petIndex = findPetIndex(state.companionPets, action.petId)
        if petIndex then
            -- Create new companionPets array without the removed pet
            local newCompanionPets = {}
            for i, pet in ipairs(state.companionPets) do
                if i ~= petIndex then
                    table.insert(newCompanionPets, pet)
                end
            end
            
            -- Create new state using table copy
            local newState = {}
            for k, v in pairs(state) do
                newState[k] = v
            end
            newState.companionPets = newCompanionPets
            return newState
        end
        return state
    end,
    
    [PlayerActions.ADD_BOOST] = function(state, action)
        -- Create new activeBoosts array with plain Lua table operations
        local newActiveBoosts = {}
        for i, boost in ipairs(state.activeBoosts) do
            newActiveBoosts[i] = boost
        end
        table.insert(newActiveBoosts, action.boostData)
        
        -- Create new state using table copy
        local newState = {}
        for k, v in pairs(state) do
            newState[k] = v
        end
        newState.activeBoosts = newActiveBoosts
        return newState
    end,
    
    [PlayerActions.REMOVE_BOOST] = function(state, action)
        local boostIndex = findBoostIndex(state.activeBoosts, action.boostId)
        if boostIndex then
            local newActiveBoosts = {}
            for i, boost in ipairs(state.activeBoosts) do
                if i ~= boostIndex then
                    table.insert(newActiveBoosts, boost)
                end
            end
            
            local newState = {}
            for k, v in pairs(state) do
                newState[k] = v
            end
            newState.activeBoosts = newActiveBoosts
            return newState
        end
        return state
    end,
    
    [PlayerActions.UPDATE_STATS] = function(state, action)
        -- Defensive check for nil state
        if not state then
            state = initialState
        end
        if not state.stats then
            state = {
                resources = state.resources or initialState.resources,
                boughtPlots = state.boughtPlots or {},
                ownedPets = state.ownedPets or {},
                companionPets = state.companionPets or {},
                activeBoosts = state.activeBoosts or {},
                settings = state.settings or initialState.settings,
                stats = initialState.stats,
            }
        end
        
        -- Create new state using table copy
        local newState = {}
        for k, v in pairs(state) do
            newState[k] = v
        end
        
        -- Update stats
        local newStats = {}
        for k, v in pairs(state.stats) do
            newStats[k] = v
        end
        for k, v in pairs(action.stats or {}) do
            newStats[k] = v
        end
        newState.stats = newStats
        
        return newState
    end,
    
    [PlayerActions.UPDATE_SETTINGS] = function(state, action)
        local newState = {}
        for k, v in pairs(state) do
            newState[k] = v
        end
        
        local newSettings = {}
        for k, v in pairs(state.settings) do
            newSettings[k] = v
        end
        for k, v in pairs(action.settings or {}) do
            newSettings[k] = v
        end
        
        newState.settings = newSettings
        return newState
    end,
    
    [PlayerActions.SET_PETS] = function(state, action)
        -- Defensive check for nil state
        if not state then
            state = initialState
        end
        
        -- Create new state using table copy
        local newState = {}
        for k, v in pairs(state) do
            newState[k] = v
        end
        newState.ownedPets = action.pets or {}
        return newState
    end,
    
    [PlayerActions.SET_COMPANIONS] = function(state, action)
        -- Defensive check for nil state
        if not state then
            state = initialState
        end
        
        -- Create new state using table copy
        local newState = {}
        for k, v in pairs(state) do
            newState[k] = v
        end
        newState.companionPets = action.companions or {}
        return newState
    end,
    
    [PlayerActions.SET_MAX_SLOTS] = function(state, action)
        -- Defensive check for nil state
        if not state then
            state = initialState
        end
        
        -- Create new state using table copy
        local newState = {}
        for k, v in pairs(state) do
            newState[k] = v
        end
        newState.maxSlots = action.maxSlots or 3
        return newState
    end,
})

return playerReducer