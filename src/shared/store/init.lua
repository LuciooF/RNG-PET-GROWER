-- Store initialization for state management
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rodux = require(ReplicatedStorage.Packages:WaitForChild("rodux"))
local RunService = game:GetService("RunService")

local playerReducer = require(script.reducers.playerReducer)
local Actions = require(script.actions)

-- Root reducer combining all reducers
local rootReducer = Rodux.combineReducers({
    player = playerReducer
})

-- Create store
local store = Rodux.Store.new(rootReducer, {}, {
    Rodux.thunkMiddleware
})

-- Handle server data sync directly in store (client-side only)
if RunService:IsClient() then
    task.spawn(function()
        -- Wait for server remote event
        local updateDataRemote = ReplicatedStorage:WaitForChild("UpdatePlayerData", 10)
        if updateDataRemote then
            -- Listen for server updates and dispatch directly to store
            updateDataRemote.OnClientEvent:Connect(function(playerData)
                store:dispatch(Actions.setPlayerData(playerData))
            end)
        else
            warn("Rodux Store: Failed to connect to server updates!")
        end
    end)
end

return store