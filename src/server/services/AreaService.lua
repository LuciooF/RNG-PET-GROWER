local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

-- Plot generators removed - using pre-built plots from AreaTemplate

local AreaService = {}
AreaService.__index = AreaService

-- Configuration
local AREAS_CONFIG = {
    totalAreas = 6,
    gridSize = {rows = 2, columns = 3},
    areaSpacing = Vector3.new(200, 0, 200), -- Distance between area centers (doubled from 100 to 200)
    startPosition = Vector3.new(0, 0, 0) -- Center position for the first area
}

-- Store references to all created areas
local playerAreas = {}
local areaTemplate = nil

function AreaService:Initialize()
    -- Initializing AreaService
    
    -- Wait for the AreaTemplate model to exist in Workspace
    areaTemplate = Workspace:WaitForChild("AreaTemplate", 10)
    if not areaTemplate then
        warn("AreaService: AreaTemplate not found in Workspace!")
        return false
    end
    
    -- Creating player areas from template
    self:CreatePlayerAreas()
    
    return true
end

function AreaService:CreatePlayerAreas()
    -- Create a container for all player areas
    local areasContainer = Instance.new("Folder")
    areasContainer.Name = "PlayerAreas"
    areasContainer.Parent = Workspace
    
    local areaIndex = 1
    
    -- Create areas in a 2x3 grid
    for row = 1, AREAS_CONFIG.gridSize.rows do
        for column = 1, AREAS_CONFIG.gridSize.columns do
            if areaIndex <= AREAS_CONFIG.totalAreas then
                local areaPosition = self:CalculateAreaPosition(row, column)
                local newArea = self:CreateSingleArea(areaIndex, areaPosition)
                
                if newArea then
                    newArea.Parent = areasContainer
                    
                    -- Ensure all plots have PlotId values
                    self:EnsurePlotIds(newArea)
                    
                    playerAreas[areaIndex] = {
                        model = newArea,
                        position = areaPosition,
                        assignedPlayer = nil, -- Will be assigned when player joins
                        plots = self:GetPlotsFromArea(newArea),
                        spawnPoint = self:GetSpawnPointFromArea(newArea)
                    }
                    
                    -- Area created successfully
                end
                
                areaIndex = areaIndex + 1
            end
        end
    end
    
    print(string.format("AreaService: Successfully created %d player areas", #playerAreas))
    
    -- Plot generation removed - plots are now pre-built in AreaTemplate
    -- Remove the original template from workspace now that we've cloned it
    if areaTemplate and areaTemplate.Parent then
        areaTemplate:Destroy()
    end
end

function AreaService:CalculateAreaPosition(row, column)
    local baseX = AREAS_CONFIG.startPosition.X + ((column - 1) - (AREAS_CONFIG.gridSize.columns - 1) / 2) * AREAS_CONFIG.areaSpacing.X
    local baseY = AREAS_CONFIG.startPosition.Y
    local baseZ = AREAS_CONFIG.startPosition.Z + ((row - 1) - (AREAS_CONFIG.gridSize.rows - 1) / 2) * AREAS_CONFIG.areaSpacing.Z
    
    return Vector3.new(baseX, baseY, baseZ)
end

function AreaService:CreateSingleArea(areaNumber, position)
    if not areaTemplate then
        warn("AreaService: No area template available")
        return nil
    end
    
    -- Clone the template
    local newArea = areaTemplate:Clone()
    newArea.Name = "PlayerArea" .. areaNumber
    
    -- Move the area to the correct position
    if newArea.PrimaryPart then
        newArea:SetPrimaryPartCFrame(CFrame.new(position))
    else
        -- If no PrimaryPart, calculate offset from template's current position
        local templateCenter = self:GetModelCenter(areaTemplate)
        local offset = position - templateCenter
        
        -- Move all parts in the model
        self:MoveModelParts(newArea, offset)
    end
    
    -- Set up area-specific properties
    self:SetupAreaProperties(newArea, areaNumber)
    
    return newArea
end

function AreaService:GetModelCenter(model)
    local parts = {}
    local function collectParts(parent)
        for _, child in pairs(parent:GetChildren()) do
            if child:IsA("BasePart") then
                table.insert(parts, child)
            elseif child:IsA("Model") then
                collectParts(child)
            elseif child:IsA("Folder") then
                collectParts(child) -- Also collect parts from folders like "Plots"
            end
        end
    end
    
    collectParts(model)
    
    if #parts == 0 then
        return Vector3.new(0, 0, 0)
    end
    
    local sumPosition = Vector3.new(0, 0, 0)
    for _, part in pairs(parts) do
        sumPosition = sumPosition + part.Position
    end
    
    return sumPosition / #parts
end

function AreaService:MoveModelParts(model, offset)
    local function moveParts(parent)
        for _, child in pairs(parent:GetChildren()) do
            if child:IsA("BasePart") then
                child.Position = child.Position + offset
            elseif child:IsA("Model") then
                if child.PrimaryPart then
                    child:SetPrimaryPartCFrame(child.PrimaryPart.CFrame + offset)
                else
                    moveParts(child) -- Recursively move parts in nested models
                end
            elseif child:IsA("Folder") then
                moveParts(child) -- Also handle folders like "Plots"
            end
        end
    end
    
    moveParts(model)
end

function AreaService:SetupAreaProperties(area, areaNumber)
    -- Add area identification
    local areaValue = Instance.new("IntValue")
    areaValue.Name = "AreaNumber"
    areaValue.Value = areaNumber
    areaValue.Parent = area
    
    -- Create nameplate anchor point
    local nameplateAnchor = Instance.new("Part")
    nameplateAnchor.Name = "NameplateAnchor"
    nameplateAnchor.Size = Vector3.new(1, 1, 1)
    nameplateAnchor.Transparency = 1
    nameplateAnchor.CanCollide = false
    nameplateAnchor.Anchored = true
    
    -- Position the anchor above the area center
    local areaCenter = self:GetModelCenter(area)
    nameplateAnchor.Position = areaCenter + Vector3.new(0, 20, 0)
    nameplateAnchor.Parent = area
    
    -- Set up plots if they exist
    local plotsFolder = area:FindFirstChild("Plots")
    if plotsFolder then
        for _, plot in pairs(plotsFolder:GetChildren()) do
            if plot:IsA("Model") then
                -- Add plot identification
                local plotAreaValue = Instance.new("IntValue")
                plotAreaValue.Name = "AreaNumber"
                plotAreaValue.Value = areaNumber
                plotAreaValue.Parent = plot
                
                -- Add plot ID based on name (Plot1, Plot2, etc.)
                local plotId = plot.Name:match("Plot(%d+)")
                if plotId then
                    local plotIdValue = Instance.new("IntValue")
                    plotIdValue.Name = "PlotId"
                    plotIdValue.Value = tonumber(plotId)
                    plotIdValue.Parent = plot
                end
                
                -- Plot configured successfully
            end
        end
    else
        warn(string.format("AreaService: No Plots folder found in area %d", areaNumber))
    end
end

function AreaService:GetPlotsFromArea(area)
    local plots = {}
    local plotsFolder = area:FindFirstChild("Plots")
    
    if plotsFolder then
        for _, plot in pairs(plotsFolder:GetChildren()) do
            if plot:IsA("Model") then
                local plotId = plot:FindFirstChild("PlotId")
                if plotId and plotId:IsA("IntValue") then
                    plots[plotId.Value] = {
                        model = plot,
                        id = plotId.Value,
                        name = plot.Name,
                        position = plot.PrimaryPart and plot.PrimaryPart.Position or Vector3.new()
                    }
                end
            end
        end
    end
    
    return plots
end

function AreaService:GetSpawnPointFromArea(area)
    -- Look for a SpawnPoint part or model
    local spawnPoint = area:FindFirstChild("SpawnPoint")
    
    if spawnPoint then
        if spawnPoint:IsA("BasePart") then
            return spawnPoint.Position + Vector3.new(0, 3, 0) -- Slightly above the spawn point
        elseif spawnPoint:IsA("Model") and spawnPoint.PrimaryPart then
            return spawnPoint.PrimaryPart.Position + Vector3.new(0, 3, 0)
        end
    end
    
    -- If no spawn point found, use area center + some height
    return area:FindFirstChild("AreaNumber") and Vector3.new(0, 10, 0) or Vector3.new(0, 10, 0)
end

function AreaService:AssignAreaToPlayer(player)
    -- Find an unassigned area
    for areaId, areaData in pairs(playerAreas) do
        if not areaData.assignedPlayer then
            areaData.assignedPlayer = player
            -- Area assigned successfully
            
            -- Sync to all clients
            self:SyncAreaAssignments()
            
            return areaId, areaData
        end
    end
    
    warn(string.format("AreaService: No available areas for player %s", player.Name))
    return nil, nil
end

function AreaService:ReleaseAreaFromPlayer(player)
    for areaId, areaData in pairs(playerAreas) do
        if areaData.assignedPlayer == player then
            areaData.assignedPlayer = nil
            -- Area released successfully
            
            -- Sync to all clients
            self:SyncAreaAssignments()
            
            return true
        end
    end
    
    return false
end

function AreaService:GetPlayerArea(player)
    for areaId, areaData in pairs(playerAreas) do
        if areaData.assignedPlayer == player then
            return areaId, areaData
        end
    end
    
    return nil, nil
end

function AreaService:GetAreaById(areaId)
    return playerAreas[areaId]
end

function AreaService:GetAllAreas()
    return playerAreas
end

function AreaService:TeleportPlayerToArea(player, areaId)
    local areaData = playerAreas[areaId]
    if not areaData then
        warn(string.format("AreaService: Area %d not found", areaId))
        return false
    end
    
    -- Use the spawn point if available, otherwise use area center
    local spawnPosition = areaData.spawnPoint or (areaData.position + Vector3.new(0, 10, 0))
    
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(spawnPosition)
        -- Player teleported successfully
        return true
    end
    
    return false
end

function AreaService:SyncAreaAssignments()
    -- Create area assignment data to send to clients
    local assignmentData = {}
    
    for areaId, areaData in pairs(playerAreas) do
        assignmentData[areaId] = {
            playerName = areaData.assignedPlayer and areaData.assignedPlayer.Name or nil,
            areaNumber = areaId
        }
    end
    
    -- Send to all players
    local areaAssignmentSync = ReplicatedStorage:FindFirstChild("AreaAssignmentSync")
    if areaAssignmentSync then
        areaAssignmentSync:FireAllClients(assignmentData)
        -- Area assignments synced
    end
end

function AreaService:SyncAreaAssignmentsToPlayer(player)
    -- Send current assignments to a specific player (for when they join)
    local assignmentData = {}
    
    for areaId, areaData in pairs(playerAreas) do
        assignmentData[areaId] = {
            playerName = areaData.assignedPlayer and areaData.assignedPlayer.Name or nil,
            areaNumber = areaId
        }
    end
    
    -- Send to specific player
    local areaAssignmentSync = ReplicatedStorage:FindFirstChild("AreaAssignmentSync")
    if areaAssignmentSync then
        areaAssignmentSync:FireClient(player, assignmentData)
        -- Area assignments synced to player
    end
end

function AreaService:EnsurePlotIds(area)
    -- Ensure regular plots have PlotId values
    local plotsFolder = area:FindFirstChild("Plots")
    if plotsFolder then
        for _, plot in pairs(plotsFolder:GetChildren()) do
            if plot:IsA("Model") then
                local plotIdValue = plot:FindFirstChild("PlotId")
                if not plotIdValue then
                    -- Extract plot ID from name (Plot1, Plot2, etc.)
                    local plotId = plot.Name:match("Plot(%d+)")
                    if plotId then
                        plotIdValue = Instance.new("IntValue")
                        plotIdValue.Name = "PlotId"
                        plotIdValue.Value = tonumber(plotId)
                        plotIdValue.Parent = plot
                        -- PlotId assigned
                    end
                end
            end
        end
    end
    
    -- Ensure production plots have PlotId values
    local productionPlotsFolder = area:FindFirstChild("ProductionPlots")
    if productionPlotsFolder then
        for _, plot in pairs(productionPlotsFolder:GetChildren()) do
            if plot:IsA("Model") then
                local plotIdValue = plot:FindFirstChild("PlotId")
                if not plotIdValue then
                    -- Extract plot ID from name (ProductionPlot1, ProductionPlot2, etc.)
                    local plotId = plot.Name:match("ProductionPlot(%d+)")
                    if plotId then
                        plotIdValue = Instance.new("IntValue")
                        plotIdValue.Name = "PlotId"
                        plotIdValue.Value = tonumber(plotId)
                        plotIdValue.Parent = plot
                        
                        -- Add PlotType identifier for production plots
                        local plotTypeValue = Instance.new("StringValue")
                        plotTypeValue.Name = "PlotType"
                        plotTypeValue.Value = "Production"
                        plotTypeValue.Parent = plot
                        
                        -- PlotId assigned
                    end
                end
            end
        end
    end
end

return AreaService