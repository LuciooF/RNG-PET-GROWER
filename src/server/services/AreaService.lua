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
    
    -- Create container for all areas
    local areasContainer = Instance.new("Folder")
    areasContainer.Name = "PlayerAreas"
    areasContainer.Parent = Workspace
    
    -- Create 6 areas in circular formation
    self:CreateCircularAreas(areaTemplate, areasContainer)
    
    -- Set up player assignment system
    self:SetupPlayerAssignment()
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
    end
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
    end)
    
    -- Handle player leaving
    Players.PlayerRemoving:Connect(function(player)
        self:UnassignPlayerFromArea(player)
    end)
    
    -- Handle players already in game
    for _, player in pairs(Players:GetPlayers()) do
        self:AssignPlayerToArea(player)
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
            
            -- Teleport player to their assigned area
            self:TeleportPlayerToArea(player, areaNumber)
            
            -- Update area nameplate
            self:UpdateAreaNameplate(areaNumber)
            
            -- Initialize doors for this area based on player's owned plots
            local PlotService = require(script.Parent.PlotService)
            task.spawn(function()
                -- Small delay to ensure data is loaded
                wait(0.5)
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
    -- Wait for player character to load
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        player.CharacterAdded:Wait()
    end
    
    local character = player.Character
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
    
    if humanoidRootPart then
        local areaData = playerAreas[areaNumber]
        local area = areaData.model
        
        -- Find the SpawnPoint in the area
        local spawnPoint = area:FindFirstChild("SpawnPoint", true)
        if spawnPoint and spawnPoint:IsA("SpawnLocation") then
            -- Teleport to SpawnPoint position
            humanoidRootPart.CFrame = CFrame.new(spawnPoint.Position + Vector3.new(0, 3, 0))
            -- Player teleported successfully
        else
            -- Fallback to area position if no SpawnPoint found
            local areaPosition = areaData.position
            humanoidRootPart.CFrame = CFrame.new(areaPosition + Vector3.new(0, 10, 0))
            -- Player teleported to fallback position
        end
    else
        warn(string.format("AreaService: Could not teleport %s - HumanoidRootPart not found", player.Name))
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
    
    -- Position above the area
    local areaPosition = playerAreas[areaNumber].position
    namePart.Position = areaPosition + Vector3.new(0, 50, 0) -- 50 studs above area
    
    -- Create BillboardGui
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NameplateBillboard"
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 0, 0)
    billboard.Parent = namePart
    
    -- Create text label
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.GothamBold
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

return AreaService