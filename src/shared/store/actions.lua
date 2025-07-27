-- Redux-style actions for state management
local Actions = {}

-- Player Data Actions
Actions.SET_PLAYER_DATA = "SET_PLAYER_DATA"
Actions.UPDATE_RESOURCES = "UPDATE_RESOURCES"
Actions.SET_RESOURCE = "SET_RESOURCE"

-- Pet Actions
Actions.ADD_PET = "ADD_PET"
Actions.REMOVE_PET = "REMOVE_PET"
Actions.EQUIP_PET = "EQUIP_PET"
Actions.UNEQUIP_PET = "UNEQUIP_PET"
Actions.UPDATE_PET = "UPDATE_PET"

-- Other Actions
Actions.ADD_OWNED_TUBE = "ADD_OWNED_TUBE"
Actions.ADD_OWNED_PLOT = "ADD_OWNED_PLOT"

-- Action creators
function Actions.setPlayerData(playerData)
    return {
        type = Actions.SET_PLAYER_DATA,
        payload = playerData
    }
end

function Actions.updateResources(resourceType, amount)
    return {
        type = Actions.UPDATE_RESOURCES,
        payload = {
            resourceType = resourceType,
            amount = amount
        }
    }
end

function Actions.setResource(resourceType, amount)
    return {
        type = Actions.SET_RESOURCE,
        payload = {
            resourceType = resourceType,
            amount = amount
        }
    }
end

function Actions.addPet(petData)
    return {
        type = Actions.ADD_PET,
        payload = petData
    }
end

function Actions.removePet(petId)
    return {
        type = Actions.REMOVE_PET,
        payload = petId
    }
end

function Actions.equipPet(petData)
    return {
        type = Actions.EQUIP_PET,
        payload = petData
    }
end

function Actions.unequipPet(petId)
    return {
        type = Actions.UNEQUIP_PET,
        payload = petId
    }
end

function Actions.updatePet(petData)
    return {
        type = Actions.UPDATE_PET,
        payload = petData
    }
end

function Actions.addOwnedTube(tubeNumber)
    return {
        type = Actions.ADD_OWNED_TUBE,
        payload = tubeNumber
    }
end

function Actions.addOwnedPlot(plotNumber)
    return {
        type = Actions.ADD_OWNED_PLOT,
        payload = plotNumber
    }
end

return Actions