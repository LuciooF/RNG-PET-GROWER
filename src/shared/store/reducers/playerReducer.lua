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
    }
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
        return Rodux.Dictionary.join(state, {
            resources = {
                money = action.money,
                rebirths = action.rebirths,
                diamonds = action.diamonds,
            }
        })
    end,
    
    [PlayerActions.ADD_MONEY] = function(state, action)
        return Rodux.Dictionary.join(state, {
            resources = Rodux.Dictionary.join(state.resources, {
                money = state.resources.money + action.amount
            })
        })
    end,
    
    [PlayerActions.SPEND_MONEY] = function(state, action)
        return Rodux.Dictionary.join(state, {
            resources = Rodux.Dictionary.join(state.resources, {
                money = math.max(0, state.resources.money - action.amount)
            })
        })
    end,
    
    [PlayerActions.ADD_DIAMONDS] = function(state, action)
        return Rodux.Dictionary.join(state, {
            resources = Rodux.Dictionary.join(state.resources, {
                diamonds = state.resources.diamonds + action.amount
            })
        })
    end,
    
    [PlayerActions.SPEND_DIAMONDS] = function(state, action)
        return Rodux.Dictionary.join(state, {
            resources = Rodux.Dictionary.join(state.resources, {
                diamonds = math.max(0, state.resources.diamonds - action.amount)
            })
        })
    end,
    
    [PlayerActions.SET_REBIRTHS] = function(state, action)
        return Rodux.Dictionary.join(state, {
            resources = Rodux.Dictionary.join(state.resources, {
                rebirths = action.amount
            })
        })
    end,
    
    [PlayerActions.ADD_PLOT] = function(state, action)
        local newBoughtPlots = Rodux.List.join(state.boughtPlots, {action.plotId})
        return Rodux.Dictionary.join(state, {
            boughtPlots = newBoughtPlots
        })
    end,
    
    [PlayerActions.ADD_PET] = function(state, action)
        local newOwnedPets = Rodux.List.join(state.ownedPets, {action.petData})
        return Rodux.Dictionary.join(state, {
            ownedPets = newOwnedPets,
            stats = Rodux.Dictionary.join(state.stats, {
                totalPetsCollected = state.stats.totalPetsCollected + 1
            })
        })
    end,
    
    [PlayerActions.REMOVE_PET] = function(state, action)
        local petIndex = findPetIndex(state.ownedPets, action.petId)
        if petIndex then
            local newOwnedPets = Rodux.List.join(state.ownedPets)
            table.remove(newOwnedPets, petIndex)
            return Rodux.Dictionary.join(state, {
                ownedPets = newOwnedPets
            })
        end
        return state
    end,
    
    [PlayerActions.EQUIP_COMPANION] = function(state, action)
        if #state.companionPets >= 2 then
            return state
        end
        
        local newCompanionPets = Rodux.List.join(state.companionPets, {action.petData})
        return Rodux.Dictionary.join(state, {
            companionPets = newCompanionPets
        })
    end,
    
    [PlayerActions.UNEQUIP_COMPANION] = function(state, action)
        local petIndex = findPetIndex(state.companionPets, action.petId)
        if petIndex then
            local newCompanionPets = Rodux.List.join(state.companionPets)
            table.remove(newCompanionPets, petIndex)
            return Rodux.Dictionary.join(state, {
                companionPets = newCompanionPets
            })
        end
        return state
    end,
    
    [PlayerActions.ADD_BOOST] = function(state, action)
        local newActiveBoosts = Rodux.List.join(state.activeBoosts, {action.boostData})
        return Rodux.Dictionary.join(state, {
            activeBoosts = newActiveBoosts
        })
    end,
    
    [PlayerActions.REMOVE_BOOST] = function(state, action)
        local boostIndex = findBoostIndex(state.activeBoosts, action.boostId)
        if boostIndex then
            local newActiveBoosts = Rodux.List.join(state.activeBoosts)
            table.remove(newActiveBoosts, boostIndex)
            return Rodux.Dictionary.join(state, {
                activeBoosts = newActiveBoosts
            })
        end
        return state
    end,
    
    [PlayerActions.UPDATE_STATS] = function(state, action)
        return Rodux.Dictionary.join(state, {
            stats = Rodux.Dictionary.join(state.stats, action.stats)
        })
    end,
    
    [PlayerActions.UPDATE_SETTINGS] = function(state, action)
        return Rodux.Dictionary.join(state, {
            settings = Rodux.Dictionary.join(state.settings, action.settings)
        })
    end,
})

return playerReducer