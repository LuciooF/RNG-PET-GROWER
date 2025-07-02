local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Rodux = require(Packages.rodux)

local reducers = script.reducers

local rootReducer = Rodux.combineReducers({
    player = require(reducers.playerReducer),
})

local store = Rodux.Store.new(rootReducer, nil, {
    Rodux.loggerMiddleware,
})

return store