-- Player data reducer for state management
local Actions = require(script.Parent.Parent.actions)

-- Default player state
local defaultState = {
    Resources = {
        Diamonds = 0,
        Money = 0,
        Rebirths = 0
    },
    Pets = {},
    EquippedPets = {},
    OwnedTubes = {},
    OwnedPlots = {},
    Settings = {
        MusicEnabled = true -- Default to music on
    }
}

local function playerReducer(state, action)
    state = state or defaultState
    
    if action.type == Actions.SET_PLAYER_DATA then
        return action.payload
        
    elseif action.type == Actions.UPDATE_RESOURCES then
        local newState = {}
        for key, value in pairs(state) do
            if key == "Resources" then
                newState[key] = {}
                for resourceKey, resourceValue in pairs(value) do
                    newState[key][resourceKey] = resourceValue
                end
                -- Update the specific resource
                newState[key][action.payload.resourceType] = 
                    newState[key][action.payload.resourceType] + action.payload.amount
            else
                newState[key] = value
            end
        end
        return newState
        
    elseif action.type == Actions.SET_RESOURCE then
        local newState = {}
        for key, value in pairs(state) do
            if key == "Resources" then
                newState[key] = {}
                for resourceKey, resourceValue in pairs(value) do
                    newState[key][resourceKey] = resourceValue
                end
                -- Set the specific resource
                newState[key][action.payload.resourceType] = action.payload.amount
            else
                newState[key] = value
            end
        end
        return newState
        
    elseif action.type == Actions.ADD_PET then
        local newState = {}
        for key, value in pairs(state) do
            if key == "Pets" then
                newState[key] = {}
                for i, pet in pairs(value) do
                    newState[key][i] = pet
                end
                table.insert(newState[key], action.payload)
            else
                newState[key] = value
            end
        end
        return newState
        
    elseif action.type == Actions.REMOVE_PET then
        local newState = {}
        for key, value in pairs(state) do
            if key == "Pets" then
                newState[key] = {}
                for i, pet in pairs(value) do
                    if pet.id ~= action.payload then
                        table.insert(newState[key], pet)
                    end
                end
            else
                newState[key] = value
            end
        end
        return newState
        
    elseif action.type == Actions.EQUIP_PET then
        local newState = {}
        for key, value in pairs(state) do
            if key == "EquippedPets" then
                newState[key] = {}
                for i, pet in pairs(value) do
                    newState[key][i] = pet
                end
                table.insert(newState[key], action.payload)
            else
                newState[key] = value
            end
        end
        return newState
        
    elseif action.type == Actions.UNEQUIP_PET then
        local newState = {}
        for key, value in pairs(state) do
            if key == "EquippedPets" then
                newState[key] = {}
                for i, pet in pairs(value) do
                    if pet.id ~= action.payload then
                        table.insert(newState[key], pet)
                    end
                end
            else
                newState[key] = value
            end
        end
        return newState
        
    elseif action.type == Actions.UPDATE_PET then
        local newState = {}
        for key, value in pairs(state) do
            if key == "Pets" then
                newState[key] = {}
                for i, pet in pairs(value) do
                    if pet.ID == action.payload.ID then
                        newState[key][i] = action.payload
                    else
                        newState[key][i] = pet
                    end
                end
            else
                newState[key] = value
            end
        end
        return newState
        
    elseif action.type == Actions.ADD_OWNED_TUBE then
        local newState = {}
        for key, value in pairs(state) do
            if key == "OwnedTubes" then
                newState[key] = {}
                for i, tubeNumber in pairs(value) do
                    newState[key][i] = tubeNumber
                end
                table.insert(newState[key], action.payload)
            else
                newState[key] = value
            end
        end
        return newState
        
    elseif action.type == Actions.ADD_OWNED_PLOT then
        local newState = {}
        for key, value in pairs(state) do
            if key == "OwnedPlots" then
                newState[key] = {}
                for i, plotNumber in pairs(value) do
                    newState[key][i] = plotNumber
                end
                table.insert(newState[key], action.payload)
            else
                newState[key] = value
            end
        end
        return newState
        
    elseif action.type == Actions.UPDATE_PLAYER_SETTINGS then
        local newState = {}
        for key, value in pairs(state) do
            if key == "Settings" then
                newState[key] = {}
                -- Copy existing settings
                if value then
                    for settingKey, settingValue in pairs(value) do
                        newState[key][settingKey] = settingValue
                    end
                end
                -- Update with new settings
                for settingKey, settingValue in pairs(action.payload) do
                    newState[key][settingKey] = settingValue
                end
            else
                newState[key] = value
            end
        end
        return newState
    end
    
    return state
end

return playerReducer