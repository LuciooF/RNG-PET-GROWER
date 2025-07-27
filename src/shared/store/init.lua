-- Store initialization for state management
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rodux = require(ReplicatedStorage.Packages:WaitForChild("rodux"))

local playerReducer = require(script.reducers.playerReducer)

-- Root reducer combining all reducers
local rootReducer = Rodux.combineReducers({
    player = playerReducer
})

-- Create store
local store = Rodux.Store.new(rootReducer, {}, {
    Rodux.thunkMiddleware
})

return store