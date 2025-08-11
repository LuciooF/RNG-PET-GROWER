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
    timeout = timeout or 15 -- Increased timeout for robustness
    local startTime = tick()
    
    -- First try immediate search
    local area = self:FindPlayerArea()
    if area then
        return area
    end
    
    -- Set up event-based waiting for more efficient detection
    local playerAreas = game.Workspace:WaitForChild("PlayerAreas", 5)
    if not playerAreas then
        warn("PlayerAreaFinder: PlayerAreas folder not found after 5 seconds")
        return nil
    end
    
    -- Set up event listeners for area changes
    local connections = {}
    local foundArea = nil
    
    -- Listen for new areas being added
    table.insert(connections, playerAreas.ChildAdded:Connect(function()
        if not foundArea then
            foundArea = self:FindPlayerArea()
        end
    end))
    
    -- Listen for nameplate changes (more efficient than polling)
    table.insert(connections, playerAreas.DescendantAdded:Connect(function(descendant)
        if not foundArea and descendant.Name == "TextLabel" then
            -- Small delay to allow nameplate text to be set
            task.wait(0.05)
            foundArea = self:FindPlayerArea()
        end
    end))
    
    -- Listen for property changes on TextLabels (using DescendantAdded + Changed instead)
    table.insert(connections, playerAreas.DescendantAdded:Connect(function(descendant)
        if not foundArea and descendant.Name == "TextLabel" and descendant:IsA("TextLabel") then
            -- Listen for text changes on this specific label
            local changedConnection = descendant:GetPropertyChangedSignal("Text"):Connect(function()
                if not foundArea then
                    foundArea = self:FindPlayerArea()
                end
            end)
            -- Store connection to clean up later
            table.insert(connections, changedConnection)
        end
    end))
    
    -- Fallback polling with longer intervals
    while not foundArea and (tick() - startTime) < timeout do
        task.wait(0.5) -- Less frequent polling since we have event listeners
        foundArea = self:FindPlayerArea()
    end
    
    -- Clean up connections
    for _, connection in pairs(connections) do
        connection:Disconnect()
    end
    
    if foundArea then
        print("PlayerAreaFinder: Successfully found player area for", player.Name)
    else
        warn("PlayerAreaFinder: Failed to find player area for", player.Name, "after", timeout, "seconds")
    end
    
    return foundArea
end

function PlayerAreaFinder:ClearCache()
    cachedPlayerArea = nil
    cacheTime = 0
end

return PlayerAreaFinder