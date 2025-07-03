local PlayerActions = {}

PlayerActions.SET_RESOURCES = "SET_RESOURCES"
PlayerActions.ADD_MONEY = "ADD_MONEY"
PlayerActions.SPEND_MONEY = "SPEND_MONEY"
PlayerActions.ADD_DIAMONDS = "ADD_DIAMONDS"
PlayerActions.SPEND_DIAMONDS = "SPEND_DIAMONDS"
PlayerActions.SET_REBIRTHS = "SET_REBIRTHS"

PlayerActions.ADD_PLOT = "ADD_PLOT"
PlayerActions.REMOVE_PLOT = "REMOVE_PLOT"

PlayerActions.ADD_PET = "ADD_PET"
PlayerActions.REMOVE_PET = "REMOVE_PET"
PlayerActions.UPDATE_PET = "UPDATE_PET"

PlayerActions.EQUIP_COMPANION = "EQUIP_COMPANION"
PlayerActions.UNEQUIP_COMPANION = "UNEQUIP_COMPANION"

PlayerActions.ADD_BOOST = "ADD_BOOST"
PlayerActions.REMOVE_BOOST = "REMOVE_BOOST"
PlayerActions.UPDATE_BOOST = "UPDATE_BOOST"

PlayerActions.UPDATE_STATS = "UPDATE_STATS"
PlayerActions.UPDATE_SETTINGS = "UPDATE_SETTINGS"
PlayerActions.SET_PETS = "SET_PETS"
PlayerActions.SET_COMPANIONS = "SET_COMPANIONS"

function PlayerActions.setResources(money, rebirths, diamonds)
    return {
        type = PlayerActions.SET_RESOURCES,
        money = money,
        rebirths = rebirths,
        diamonds = diamonds,
    }
end

function PlayerActions.addMoney(amount)
    return {
        type = PlayerActions.ADD_MONEY,
        amount = amount,
    }
end

function PlayerActions.spendMoney(amount)
    return {
        type = PlayerActions.SPEND_MONEY,
        amount = amount,
    }
end

function PlayerActions.addDiamonds(amount)
    return {
        type = PlayerActions.ADD_DIAMONDS,
        amount = amount,
    }
end

function PlayerActions.spendDiamonds(amount)
    return {
        type = PlayerActions.SPEND_DIAMONDS,
        amount = amount,
    }
end

function PlayerActions.setRebirths(amount)
    return {
        type = PlayerActions.SET_REBIRTHS,
        amount = amount,
    }
end

function PlayerActions.addPlot(plotId)
    return {
        type = PlayerActions.ADD_PLOT,
        plotId = plotId,
    }
end

function PlayerActions.addPet(petData)
    return {
        type = PlayerActions.ADD_PET,
        petData = petData,
    }
end

function PlayerActions.removePet(petId)
    return {
        type = PlayerActions.REMOVE_PET,
        petId = petId,
    }
end

function PlayerActions.equipCompanion(petData)
    return {
        type = PlayerActions.EQUIP_COMPANION,
        petData = petData,
    }
end

function PlayerActions.unequipCompanion(petId)
    return {
        type = PlayerActions.UNEQUIP_COMPANION,
        petId = petId,
    }
end

function PlayerActions.addBoost(boostData)
    return {
        type = PlayerActions.ADD_BOOST,
        boostData = boostData,
    }
end

function PlayerActions.removeBoost(boostId)
    return {
        type = PlayerActions.REMOVE_BOOST,
        boostId = boostId,
    }
end

function PlayerActions.updateStats(stats)
    return {
        type = PlayerActions.UPDATE_STATS,
        stats = stats,
    }
end

function PlayerActions.setPets(pets)
    return {
        type = PlayerActions.SET_PETS,
        pets = pets,
    }
end

function PlayerActions.setCompanions(companions)
    return {
        type = PlayerActions.SET_COMPANIONS,
        companions = companions,
    }
end

return PlayerActions