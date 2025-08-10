-- AreaService - Creates 6 player areas in circular formation
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local AreaService = {}
AreaService.__index = AreaService

-- Configuration
local MAX_PLAYERS = 6
local CIRCLE_RADIUS = 350 -- Distance from center to each area
local AREA_ASSIGNMENTS = {} -- playerUserId -> areaNumber

-- Store created areas
local playerAreas = {}

function AreaService:Initialize()
    -- Wait for AreaTemplate
    local areaTemplate = Workspace:WaitForChild("AreaTemplate", 10)
    if not areaTemplate then
        warn("AreaService: AreaTemplate not found in Workspace after 10 seconds!")
        return
    end
    
    -- Wait for TycoonMap
    local tycoonMap = Workspace:WaitForChild("Center", 10)
    if tycoonMap then
        tycoonMap = tycoonMap:WaitForChild("TycoonMap", 10)
    end
    if not tycoonMap then
        warn("AreaService: TycoonMap not found in Workspace.Center after 10 seconds!")
        return
    end
    
    -- Create container for all areas
    local areasContainer = Instance.new("Folder")
    areasContainer.Name = "PlayerAreas"
    areasContainer.Parent = Workspace
    
    -- Create 6 areas aligned with TycoonMap entrances
    self:CreateAlignedAreas(areaTemplate, areasContainer, tycoonMap)
    
    -- Remove the template after creating all areas to clean up workspace
    areaTemplate:Destroy()
    print("AreaService: Removed AreaTemplate after creating 6 player areas")
    
    -- Set up player assignment system
    self:SetupPlayerAssignment()
end

function AreaService:CreateAlignedAreas(template, container, tycoonMap)
    for i = 1, MAX_PLAYERS do
        -- Find the corresponding entrance part in TycoonMap
        local entrancePart = tycoonMap:FindFirstChild("Entrance" .. i)
        if not entrancePart then
            warn("AreaService: Entrance" .. i .. " not found in TycoonMap!")
            continue
        end
        
        -- Clone and position area
        local area = template:Clone()
        area.Name = "PlayerArea" .. i
        area.Parent = container
        
        -- Position area so its entrance aligns with the TycoonMap entrance
        self:PositionAreaWithEntrance(area, entrancePart, i)
        
        -- Remove any TycoonMap parts that intersect with this area (disabled to preserve floor)
        -- self:RemoveConflictingParts(area, tycoonMap, i)
        
        -- Store reference (get position after positioning)
        local areaPosition = Vector3.new(0, 0, 0)
        if area.PrimaryPart then
            areaPosition = area.PrimaryPart.Position
        else
            areaPosition = area:GetBoundingBox().Position
        end
        
        playerAreas[i] = {
            model = area,
            assignedPlayer = nil,
            position = areaPosition
        }
        
        -- Create initial "Unassigned Area" nameplate
        self:UpdateAreaNameplate(i)
        
        -- Disable all SpawnLocations in this area to prevent auto-spawning
        for _, spawn in pairs(area:GetDescendants()) do
            if spawn:IsA("SpawnLocation") then
                spawn.Enabled = false
            end
        end
    end
end

function AreaService:CreateCircularAreas(template, container)
    for i = 1, MAX_PLAYERS do
        -- Calculate position around circle
        local angle = (i - 1) * (math.pi * 2 / MAX_PLAYERS) -- Evenly distribute around circle
        local x = math.cos(angle) * CIRCLE_RADIUS
        local z = math.sin(angle) * CIRCLE_RADIUS
        local position = Vector3.new(x, 0, z)
        
        -- Clone and position area
        local area = template:Clone()
        area.Name = "PlayerArea" .. i
        area.Parent = container
        
        -- Position area so SpawnPoint is at baseplate level
        self:PositionAreaWithSpawnPointAtBaseplate(area, position)
        
        -- Store reference
        playerAreas[i] = {
            model = area,
            assignedPlayer = nil,
            position = position
        }
        
        -- Create initial "Unassigned Area" nameplate
        self:UpdateAreaNameplate(i)
        
        -- Disable all SpawnLocations in this area to prevent auto-spawning
        for _, spawn in pairs(area:GetDescendants()) do
            if spawn:IsA("SpawnLocation") then
                spawn.Enabled = false
            end
        end
    end
end

function AreaService:PositionAreaWithEntrance(area, tycoonEntrancePart, areaNumber)
    -- Find the Entrance part in the area template
    local areaEntrance = area:FindFirstChild("Entrance", true) -- Recursive search
    if not areaEntrance then
        warn("AreaService: Entrance part not found in PlayerArea" .. areaNumber .. "! Using SpawnPoint fallback.")
        -- Fallback to SpawnPoint positioning
        local spawnPoint = area:FindFirstChild("SpawnPoint", true)
        if spawnPoint then
            local offset = tycoonEntrancePart.Position - spawnPoint.Position
            area:MoveTo(area:GetPrimaryPartCFrame().Position + offset)
        else
            -- Last resort: just move to TycoonMap entrance position
            area:MoveTo(tycoonEntrancePart.Position)
        end
        return
    end
    
    -- Get current positions
    local currentEntrancePosition = areaEntrance.Position
    local targetEntrancePosition = tycoonEntrancePart.Position
    
    -- Calculate offset needed to align entrances
    local offset = targetEntrancePosition - currentEntrancePosition
    
    -- Add manual correction: Based on the debug logs, we need to go down an additional ~14.5 studs
    local heightCorrection = -14.5 -- Force area lower to compensate for positioning issues
    offset = Vector3.new(offset.X, offset.Y + heightCorrection, offset.Z)
    
    -- Move the entire area using the corrected offset
    if area.PrimaryPart then
        area:SetPrimaryPartCFrame(area.PrimaryPart.CFrame + offset)
    else
        area:MoveTo(area:GetBoundingBox().Position + offset)
    end
    
    -- Wait for positioning to settle
    task.wait(0.1)
    
    -- Now rotate the area to face toward the center
    self:RotateAreaTowardCenter(area, tycoonEntrancePart, areaNumber)
    
    -- Re-align entrances after rotation (rotation moves the entrance part)
    local newEntrancePosition = areaEntrance.Position
    local finalOffset = tycoonEntrancePart.Position - newEntrancePosition
    
    -- Apply the same height correction as before (rotation broke the Y alignment)
    local heightCorrection = -14.5
    finalOffset = Vector3.new(finalOffset.X, finalOffset.Y + heightCorrection, finalOffset.Z)
    
    -- Apply final correction to get entrances touching again
    if area.PrimaryPart then
        area:SetPrimaryPartCFrame(area.PrimaryPart.CFrame + finalOffset)
    else
        area:MoveTo(area:GetBoundingBox().Position + finalOffset)
    end
end

function AreaService:RotateAreaTowardCenter(area, tycoonEntrancePart, areaNumber)
    -- Find the center of the TycoonMap (approximate center point)
    local tycoonMap = tycoonEntrancePart.Parent
    local centerPosition = Vector3.new(0, 0, 0) -- Assume center is at origin, adjust if needed
    
    -- You can also calculate center from TycoonMap bounds if needed:
    -- local cf, size = tycoonMap:GetBoundingBox()
    -- local centerPosition = cf.Position
    
    -- Get current area position after alignment
    local areaPosition
    if area.PrimaryPart then
        areaPosition = area.PrimaryPart.Position
    else
        areaPosition = area:GetBoundingBox().Position
    end
    
    -- Calculate direction from area to center
    local directionToCenter = (centerPosition - areaPosition).Unit
    
    -- Calculate rotation angle (Y-axis rotation to face center)
    -- Add math.pi (180 degrees) to flip the direction
    local angle = math.atan2(directionToCenter.X, directionToCenter.Z) + math.pi
    
    
    -- Create rotation CFrame around Y-axis
    local rotationCFrame = CFrame.Angles(0, angle, 0)
    
    -- Store conveyor data before rotation
    local conveyorData = self:CollectConveyorData(area)
    
    -- Apply rotation to the area
    if area.PrimaryPart then
        -- Rotate around area's position
        local currentCFrame = area.PrimaryPart.CFrame
        local rotatedCFrame = CFrame.new(currentCFrame.Position) * rotationCFrame
        area:SetPrimaryPartCFrame(rotatedCFrame)
    else
        -- For areas without PrimaryPart, rotate all parts around area center
        local areaBounds = area:GetBoundingBox()
        local areaCenter = areaBounds.Position
        
        -- Get all parts and rotate them around area center
        local function rotateParts(parent)
            for _, child in pairs(parent:GetChildren()) do
                if child:IsA("BasePart") then
                    -- Calculate offset from area center
                    local offset = child.Position - areaCenter
                    -- Rotate the offset
                    local rotatedOffset = rotationCFrame * offset
                    -- Set new position
                    child.Position = areaCenter + rotatedOffset
                    -- Rotate the part's orientation
                    child.CFrame = CFrame.new(child.Position) * rotationCFrame * (child.CFrame - child.Position)
                end
                rotateParts(child)
            end
        end
        rotateParts(area)
    end
    
    -- Fix conveyor directions after rotation
    self:FixConveyorDirections(conveyorData)
    
end

function AreaService:RemoveConflictingParts(area, tycoonMap, areaNumber)
    -- Get all parts in the area (recursively)
    local areaParts = {}
    local function collectParts(parent)
        for _, child in pairs(parent:GetChildren()) do
            if child:IsA("BasePart") then
                table.insert(areaParts, child)
            end
            collectParts(child)
        end
    end
    collectParts(area)
    
    -- Get all parts in TycoonMap that could conflict
    local tycoonParts = {}
    local function collectTycoonParts(parent)
        for _, child in pairs(parent:GetChildren()) do
            if child:IsA("BasePart") and child.CanCollide then -- Only check collidable parts
                -- Skip entrance parts (we don't want to remove those)
                if not child.Name:match("Entrance%d+") then
                    table.insert(tycoonParts, child)
                end
            end
            collectTycoonParts(child)
        end
    end
    collectTycoonParts(tycoonMap)
    
    local removedCount = 0
    
    -- Check each TycoonMap part against each area part for overlap
    for _, tycoonPart in pairs(tycoonParts) do
        local shouldRemove = false
        
        for _, areaPart in pairs(areaParts) do
            if self:PartsOverlap(areaPart, tycoonPart) then
                shouldRemove = true
                break
            end
        end
        
        if shouldRemove then
            -- Remove the conflicting part and its parent model if it becomes empty
            local parent = tycoonPart.Parent
            tycoonPart:Destroy()
            removedCount = removedCount + 1
            
            -- If parent is a model and now empty, remove it too
            if parent and parent:IsA("Model") and #parent:GetChildren() == 0 then
                parent:Destroy()
            end
        end
    end
    
end


function AreaService:PartsOverlap(part1, part2)
    -- Get bounding boxes of both parts
    local cf1, size1 = part1.CFrame, part1.Size
    local cf2, size2 = part2.CFrame, part2.Size
    
    -- Convert to Region3-like bounds for easier calculation
    local min1 = cf1.Position - size1/2
    local max1 = cf1.Position + size1/2
    local min2 = cf2.Position - size2/2
    local max2 = cf2.Position + size2/2
    
    -- Check if bounding boxes overlap in all 3 dimensions
    local overlapX = (min1.X <= max2.X) and (max1.X >= min2.X)
    local overlapY = (min1.Y <= max2.Y) and (max1.Y >= min2.Y)
    local overlapZ = (min1.Z <= max2.Z) and (max1.Z >= min2.Z)
    
    return overlapX and overlapY and overlapZ
end

function AreaService:PositionAreaWithSpawnPointAtBaseplate(area, targetPosition)
    -- Find the SpawnPoint in the area
    local spawnPoint = area:FindFirstChild("SpawnPoint", true) -- Recursive search
    
    if spawnPoint and spawnPoint:IsA("SpawnLocation") then
        -- Get current SpawnPoint position
        local currentSpawnPointY = spawnPoint.Position.Y
        
        -- Calculate how much to offset the entire area so SpawnPoint ends up at Y = 0 (baseplate level)
        local yOffset = 0 - currentSpawnPointY
        
        -- Move the entire area to target position with Y offset to put SpawnPoint at baseplate level
        local finalPosition = Vector3.new(targetPosition.X, targetPosition.Y + yOffset, targetPosition.Z)
        area:MoveTo(finalPosition)
        
        -- Area positioned successfully
    else
        -- Fallback: just move to target position if no SpawnPoint found
        area:MoveTo(targetPosition)
        warn("AreaService: SpawnPoint not found in " .. area.Name .. ", using fallback positioning")
    end
end

function AreaService:SetupPlayerAssignment()
    -- Handle player joining
    Players.PlayerAdded:Connect(function(player)
        self:AssignPlayerToArea(player)
        
        -- Handle both initial spawn and respawning - always teleport to assigned area
        player.CharacterAdded:Connect(function(character)
            -- Wait a moment for character to fully load
            task.wait(0.1)
            
            -- Get assigned area and teleport immediately
            local areaNumber = self:GetPlayerAssignedArea(player)
            if areaNumber then
                self:TeleportPlayerToArea(player, areaNumber)
            end
        end)
    end)
    
    -- Handle player leaving
    Players.PlayerRemoving:Connect(function(player)
        self:UnassignPlayerFromArea(player)
    end)
    
    -- Handle players already in game
    for _, player in pairs(Players:GetPlayers()) do
        self:AssignPlayerToArea(player)
        
        -- Also setup respawn handler for existing players
        player.CharacterAdded:Connect(function(character)
            task.wait(0.1)
            local areaNumber = self:GetPlayerAssignedArea(player)
            if areaNumber then
                self:TeleportPlayerToArea(player, areaNumber)
            end
        end)
    end
end

function AreaService:AssignPlayerToArea(player)
    -- Find first available area
    for areaNumber = 1, MAX_PLAYERS do
        local areaData = playerAreas[areaNumber]
        if not areaData.assignedPlayer then
            -- Assign player to this area
            areaData.assignedPlayer = player
            AREA_ASSIGNMENTS[player.UserId] = areaNumber
            
            -- Player assigned successfully
            
            -- Teleport player to their assigned area (for players who join after server start)
            if player.Character then
                self:TeleportPlayerToArea(player, areaNumber)
            end
            
            -- Update area nameplate
            self:UpdateAreaNameplate(areaNumber)
            
            -- Initialize doors for this area based on player's owned plots
            local PlotService = require(script.Parent.PlotService)
            task.spawn(function()
                -- Wait for player data to be ready instead of arbitrary delay
                local DataService = require(script.Parent.DataService)
                while not DataService:GetPlayerData(player) do
                    task.wait(0.1) -- Check every 100ms
                end
                PlotService:InitializeAreaDoors(areaData.model)
            end)
            
            return
        end
    end
    
    -- Server is full
    warn(string.format("AreaService: Server full! Could not assign area to %s", player.Name))
end

function AreaService:GetPlayerAssignedArea(player)
    return AREA_ASSIGNMENTS[player.UserId]
end


function AreaService:TeleportPlayerToArea(player, areaNumber)
    local character = player.Character
    if not character then
        warn(string.format("AreaService: Cannot teleport %s - no character", player.Name))
        return
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        -- Wait briefly for HumanoidRootPart to load
        humanoidRootPart = character:WaitForChild("HumanoidRootPart", 2)
        if not humanoidRootPart then
            warn(string.format("AreaService: Could not teleport %s - HumanoidRootPart not found after waiting", player.Name))
            return
        end
    end
    
    local areaData = playerAreas[areaNumber]
    if not areaData then
        warn(string.format("AreaService: Cannot teleport %s - invalid area %d", player.Name, areaNumber))
        return
    end
    
    local area = areaData.model
    
    -- Find the SpawnPoint in the area
    local spawnPoint = area:FindFirstChild("SpawnPoint", true)
    if spawnPoint and spawnPoint:IsA("SpawnLocation") then
        -- Teleport to SpawnPoint position (slightly above to prevent clipping)
        humanoidRootPart.CFrame = CFrame.new(spawnPoint.Position + Vector3.new(0, 3, 0))
    else
        -- Fallback to area position if no SpawnPoint found
        local areaPosition = areaData.position
        humanoidRootPart.CFrame = CFrame.new(areaPosition + Vector3.new(0, 10, 0))
        warn(string.format("AreaService: Used fallback position for %s in area %d", player.Name, areaNumber))
    end
end

function AreaService:UnassignPlayerFromArea(player)
    local areaNumber = AREA_ASSIGNMENTS[player.UserId]
    if areaNumber then
        local areaData = playerAreas[areaNumber]
        areaData.assignedPlayer = nil
        AREA_ASSIGNMENTS[player.UserId] = nil
        
        -- Player unassigned successfully
        
        -- Update area nameplate
        self:UpdateAreaNameplate(areaNumber)
    end
end

function AreaService:UpdateAreaNameplate(areaNumber)
    local areaData = playerAreas[areaNumber]
    local area = areaData.model
    
    -- Remove existing nameplate
    local existingNameplate = area:FindFirstChild("AreaNameplate")
    if existingNameplate then
        existingNameplate:Destroy()
    end
    
    -- Create new nameplate
    local nameplate = self:CreateAreaNameplate(areaData.assignedPlayer, areaNumber)
    nameplate.Parent = area
end

function AreaService:CreateAreaNameplate(assignedPlayer, areaNumber)
    -- Create invisible part to hold the GUI
    local namePart = Instance.new("Part")
    namePart.Name = "AreaNameplate"
    namePart.Size = Vector3.new(1, 1, 1)
    namePart.Transparency = 1
    namePart.CanCollide = false
    namePart.Anchored = true
    
    -- Position much higher above the area
    local areaPosition = playerAreas[areaNumber].position
    namePart.Position = areaPosition + Vector3.new(0, 120, 0) -- Much higher above area
    
    -- Create BillboardGui
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NameplateBillboard"
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 0, 0)
    billboard.MaxDistance = 120 -- Much further visibility for camera angles
    billboard.Parent = namePart
    
    -- Create text label
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.FredokaOne
    textLabel.TextSize = 24
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.Parent = billboard
    
    -- Set text based on assignment - always white with black outline
    if assignedPlayer then
        textLabel.Text = assignedPlayer.Name .. "'s Area"
    else
        textLabel.Text = "Unassigned Area"
    end
    
    -- Always white text with black outline
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    
    return namePart
end

function AreaService:CollectConveyorData(area)
    local conveyorData = {}
    
    -- Recursive function to find all LocalVelocity scripts in the area
    local function findLocalVelocities(parent)
        for _, child in pairs(parent:GetChildren()) do
            if child.Name == "LocalVelocity" and child:IsA("Script") then
                -- Store the parent part (the conveyor)
                table.insert(conveyorData, {
                    part = child.Parent
                })
            end
            
            -- Recurse into children
            if #child:GetChildren() > 0 then
                findLocalVelocities(child)
            end
        end
    end
    
    -- Search recursively through the entire area
    findLocalVelocities(area)
    
    return conveyorData
end

function AreaService:FixConveyorDirections(conveyorData)
    -- The LocalVelocity script sets velocity based on part.CFrame.LookVector * speed
    -- After rotation, we need to update the velocity to use the NEW LookVector
    for _, conveyorInfo in pairs(conveyorData) do
        local part = conveyorInfo.part
        
        if part and part.Parent then
            -- The LocalVelocity script uses speed = 20
            local speed = 20
            
            -- Calculate the new velocity based on the part's CURRENT (rotated) orientation
            local newVelocity = part.CFrame.LookVector * speed
            part.AssemblyLinearVelocity = newVelocity
        end
    end
end

return AreaService