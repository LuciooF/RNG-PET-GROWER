-- RemoteService - Manages remote events and functions
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteService = {}

-- Storage for remote events/functions
local remotes = {}

function RemoteService:GetRemote(name, remoteType)
    -- Check if remote already exists
    if remotes[name] then
        return remotes[name]
    end
    
    -- Look for existing remote in ReplicatedStorage
    local existingRemote = ReplicatedStorage:FindFirstChild(name)
    if existingRemote then
        remotes[name] = existingRemote
        return existingRemote
    end
    
    -- Create new remote
    local remote
    if remoteType == "RemoteEvent" then
        remote = Instance.new("RemoteEvent")
    elseif remoteType == "RemoteFunction" then
        remote = Instance.new("RemoteFunction")
    else
        error("Invalid remote type: " .. tostring(remoteType))
    end
    
    remote.Name = name
    remote.Parent = ReplicatedStorage
    
    -- Store reference
    remotes[name] = remote
    
    return remote
end

return RemoteService