local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Rodux = require(Packages.rodux)

local reducers = script.reducers

local playerReducer = require(reducers.playerReducer)

local rootReducer = Rodux.combineReducers({
    player = playerReducer,
})

-- Define initial state for the entire store
local initialState = {
    player = {
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
        maxSlots = 3,
    }
}

local store = Rodux.Store.new(rootReducer, initialState)

return store