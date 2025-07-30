-- PlayerAreaFinder - Shared utility for finding player's assigned area
local Players = game:GetService("Players")

local PlayerAreaFinder = {}
local player = Players.LocalPlayer

-- Cache the found area to avoid repeated searches
local cachedPlayerArea = nil
local cacheTime = 0

function PlayerAreaFinder:FindPlayerArea()
    local currentTime = tick()
    
    -- Return cached result if it's recent (within 10 seconds)
    if cachedPlayerArea and (currentTime - cacheTime) < 10 then
        return cachedPlayerArea
    end
    
    -- Find PlayerAreas folder
    local playerAreas = game.Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then
        return nil
    end
    
    -- Search for player's assigned area
    local targetText = player.Name .. "'s Area"
    
    for _, area in pairs(playerAreas:GetChildren()) do
        if area.Name:match("PlayerArea") then
            local nameplate = area:FindFirstChild("AreaNameplate")
            if nameplate then
                local billboard = nameplate:FindFirstChild("NameplateBillboard")
                if billboard then
                    local textLabel = billboard:FindFirstChild("TextLabel")
                    if textLabel and textLabel.Text == targetText then
                        -- Cache the result
                        cachedPlayerArea = area
                        cacheTime = currentTime
                        return area
                    end
                end
            end
        end
    end
    
    return nil
end

function PlayerAreaFinder:WaitForPlayerArea(timeout)
    timeout = timeout or 10
    local startTime = tick()
    
    local area = self:FindPlayerArea()
    while not area and (tick() - startTime) < timeout do
        task.wait(0.1)
        area = self:FindPlayerArea()
    end
    
    return area
end

function PlayerAreaFinder:ClearCache()
    cachedPlayerArea = nil
    cacheTime = 0
end

return PlayerAreaFinder