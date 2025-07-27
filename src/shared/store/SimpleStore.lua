-- Simple Redux-like store implementation (no external dependencies)
local SimpleStore = {}
SimpleStore.__index = SimpleStore

function SimpleStore.new(reducer, initialState)
    local self = setmetatable({}, SimpleStore)
    
    self._reducer = reducer
    self._state = initialState or {}
    self._listeners = {}
    
    return self
end

function SimpleStore:getState()
    return self._state
end

function SimpleStore:dispatch(action)
    local newState = self._reducer(self._state, action)
    self._state = newState
    
    -- Notify all listeners
    for _, listener in pairs(self._listeners) do
        listener(self._state)
    end
    
    return action
end

function SimpleStore:subscribe(listener)
    table.insert(self._listeners, listener)
    
    -- Return unsubscribe function
    return function()
        for i, l in pairs(self._listeners) do
            if l == listener then
                table.remove(self._listeners, i)
                break
            end
        end
    end
end

-- Helper function to combine reducers
function SimpleStore.combineReducers(reducers)
    return function(state, action)
        local newState = {}
        
        for key, reducer in pairs(reducers) do
            newState[key] = reducer(state and state[key], action)
        end
        
        return newState
    end
end

return SimpleStore