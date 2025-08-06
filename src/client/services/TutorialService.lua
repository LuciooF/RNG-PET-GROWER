-- TutorialService - Manages tutorial progression and pathfinding
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")

local store = require(ReplicatedStorage.store)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)

local TutorialService = {}
TutorialService.__index = TutorialService

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local connections = {}
local currentPathVisual = nil
local pathUpdateConnection = nil
local lastPlayerPosition = nil
local activeTweens = {} -- Track active tweens for proper cleanup

-- Tutorial step definitions
local TUTORIAL_STEPS = {
    {
        id = "unlock_first_plot",
        title = "🏗️ Unlock Your First Plot",
        description = "Follow the glowing path to Plot 1 and click on it to unlock it. This will cost you 0 money (it's free!)",
        targetType = "plot",
        targetId = 1,
        pathTarget = function()
            local plot = nil
            local playerAreas = Workspace:FindFirstChild("PlayerAreas")
            
            if playerAreas and character and character:FindFirstChild("HumanoidRootPart") then
                -- Use PlayerAreaFinder to get the player's assigned area only
                local PlayerAreaFinder = require(script.Parent.Parent.utils.PlayerAreaFinder)
                local playerArea = PlayerAreaFinder:FindPlayerArea()
                
                if playerArea then
                    local buttons = playerArea:FindFirstChild("Buttons")
                    if buttons then
                        plot = buttons:FindFirstChild("Plot1")
                    end
                end
            end
            
            if plot then
                if plot:FindFirstChild("TouchPart") then
                    return plot.TouchPart
                elseif plot:FindFirstChild("Cube.008") then
                    return plot:FindFirstChild("Cube.008")
                elseif plot:FindFirstChild("Position") then
                    return plot.Position
                end
                return plot
            end
            
            return nil
        end
    },
    {
        id = "collect_10_pets",
        title = "🐾 Collect 10 Pets",
        description = "Pet balls will spawn near unlocked doors! Walk over them to collect pets. Collect 10 pets total.",
        targetType = "collection",
        targetCount = 10,
        pathTarget = function()
            -- Use CollectBase for pet collection area (pathfinding will ignore Boundary1 obstacles)
            local playerAreas = Workspace:FindFirstChild("PlayerAreas")
            
            if playerAreas and character and character:FindFirstChild("HumanoidRootPart") then
                -- Use PlayerAreaFinder to get the player's assigned area only
                local PlayerAreaFinder = require(script.Parent.Parent.utils.PlayerAreaFinder)
                local playerArea = PlayerAreaFinder:FindPlayerArea()
                
                if playerArea then
                    local collectBase = playerArea:FindFirstChild("CollectBase")
                    if collectBase then
                        return collectBase
                    end
                end
            end
            
            -- Fallback: look for nearest pet ball
            local nearestBall = nil
            local nearestDistance = math.huge
            
            for _, obj in pairs(Workspace:GetChildren()) do
                if obj.Name == "PetBall" and obj:FindFirstChild("Position") then
                    local distance = (obj.Position - character.HumanoidRootPart.Position).Magnitude
                    if distance < nearestDistance then
                        nearestDistance = distance
                        nearestBall = obj
                    end
                end
            end
            
            return nearestBall
        end
    },
    {
        id = "unlock_first_tube",
        title = "🧪 Unlock Your First Tube",
        description = "Great! Now follow the path to TubePlot 1 to unlock your first processing tube. This is where you'll process pets for rewards!",
        targetType = "tubeplot",
        targetId = 1,
        pathTarget = function()
            local tubePlot = nil
            local playerAreas = Workspace:FindFirstChild("PlayerAreas")
            
            if playerAreas and character and character:FindFirstChild("HumanoidRootPart") then
                -- Use PlayerAreaFinder to get the player's assigned area only
                local PlayerAreaFinder = require(script.Parent.Parent.utils.PlayerAreaFinder)
                local playerArea = PlayerAreaFinder:FindPlayerArea()
                
                if playerArea then
                    local buttons = playerArea:FindFirstChild("Buttons")
                    if buttons then
                        tubePlot = buttons:FindFirstChild("TubePlot1")
                    end
                end
            end
            
            if tubePlot then
                if tubePlot:FindFirstChild("TouchPart") then
                    return tubePlot.TouchPart
                elseif tubePlot:FindFirstChild("Cube.008") then
                    return tubePlot:FindFirstChild("Cube.008")
                elseif tubePlot:FindFirstChild("Position") then
                    return tubePlot.Position
                end
                return tubePlot
            end
            
            return nil
        end
    },
    {
        id = "process_pets",
        title = "⚙️ Process Your Pets",
        description = "Go to your tube and process some pets! Click on the tube to start processing. You need to process 20 pets.",
        targetType = "processing",
        targetCount = 20,
        pathTarget = function()
            -- Find Cylinder.007 inside SendHeaven model in player's area
            local playerAreas = Workspace:FindFirstChild("PlayerAreas")
            
            if playerAreas and character and character:FindFirstChild("HumanoidRootPart") then
                -- Use PlayerAreaFinder to get the player's assigned area only
                local PlayerAreaFinder = require(script.Parent.Parent.utils.PlayerAreaFinder)
                local playerArea = PlayerAreaFinder:FindPlayerArea()
                
                if playerArea then
                    local buttons = playerArea:FindFirstChild("Buttons")
                    if buttons then
                        local sendHeaven = buttons:FindFirstChild("SendHeaven")
                        if sendHeaven then
                            local cylinder = sendHeaven:FindFirstChild("Cylinder.007")
                            if cylinder then
                                return cylinder
                            end
                        end
                    end
                end
            end
            
            -- Fallback: look for any tube in workspace
            local tube = Workspace:FindFirstChild("Tube1")
            if tube and tube:FindFirstChild("Position") then
                return tube
            end
            
            return nil
        end
    },
    {
        id = "unlock_next_door",
        title = "🚪 Unlock the Next Door",
        description = "Great progress! Now unlock Plot 2 to open the next door and access more pet spawning areas. This will cost 10 money.",
        targetType = "plot",
        targetId = 2,
        pathTarget = function()
            local plot = nil
            local playerAreas = Workspace:FindFirstChild("PlayerAreas")
            
            if playerAreas and character and character:FindFirstChild("HumanoidRootPart") then
                -- Use PlayerAreaFinder to get the player's assigned area only
                local PlayerAreaFinder = require(script.Parent.Parent.utils.PlayerAreaFinder)
                local playerArea = PlayerAreaFinder:FindPlayerArea()
                
                if playerArea then
                    local buttons = playerArea:FindFirstChild("Buttons")
                    if buttons then
                        plot = buttons:FindFirstChild("Plot2")
                    end
                end
            end
            
            if not plot then
                plot = Workspace:FindFirstChild("Plot2")
            end
            
            if plot then
                if plot:FindFirstChild("TouchPart") then
                    return plot.TouchPart
                elseif plot:FindFirstChild("Cube.008") then
                    return plot:FindFirstChild("Cube.008")
                elseif plot:FindFirstChild("Position") then
                    return plot.Position
                end
                return plot
            end
            
            return nil
        end
    },
    {
        id = "get_rare_pet",
        title = "✨ Get a Rare Pet",
        description = "Keep collecting pets until you get one that's rarer than 1 in 250! Check the Pet Index to see your collection.",
        targetType = "rarity",
        pathTarget = function()
            -- Find CollectBase in player's area
            local playerAreas = Workspace:FindFirstChild("PlayerAreas")
            
            if playerAreas and character and character:FindFirstChild("HumanoidRootPart") then
                -- Use PlayerAreaFinder to get the player's assigned area only
                local PlayerAreaFinder = require(script.Parent.Parent.utils.PlayerAreaFinder)
                local playerArea = PlayerAreaFinder:FindPlayerArea()
                
                if playerArea then
                    local boundary1 = playerArea:FindFirstChild("Boundary1")
                    if boundary1 then
                        return boundary1
                    end
                end
            end
            
            -- Fallback: look for nearest pet ball
            local nearestBall = nil
            local nearestDistance = math.huge
            
            for _, obj in pairs(Workspace:GetChildren()) do
                if obj.Name == "PetBall" and obj:FindFirstChild("Position") then
                    local distance = (obj.Position - character.HumanoidRootPart.Position).Magnitude
                    if distance < nearestDistance then
                        nearestDistance = distance
                        nearestBall = obj
                    end
                end
            end
            
            return nearestBall
        end
    },
    {
        id = "first_rebirth",
        title = "🌟 Perform Your First Rebirth",
        description = "You're ready to rebirth! This will reset your progress but give you permanent bonuses. Walk to the Rebirth button in your area or use the Rebirth UI button on screen.",
        targetType = "rebirth",
        targetCount = 1,
        pathTarget = function()
            -- Find RebirthButton in player's area
            local playerAreas = Workspace:FindFirstChild("PlayerAreas")
            
            if playerAreas and character and character:FindFirstChild("HumanoidRootPart") then
                -- Use PlayerAreaFinder to get the player's assigned area only
                local PlayerAreaFinder = require(script.Parent.Parent.utils.PlayerAreaFinder)
                local playerArea = PlayerAreaFinder:FindPlayerArea()
                
                if playerArea then
                    local buttons = playerArea:FindFirstChild("Buttons")
                    if buttons then
                        local rebirthButton = buttons:FindFirstChild("RebirthButton")
                        if rebirthButton then
                            local cube = rebirthButton:FindFirstChild("Cube.009")
                            if cube then
                                return cube
                            end
                            -- Fallback to any part in RebirthButton
                            local part = rebirthButton:FindFirstChildWhichIsA("BasePart")
                            if part then
                                return part
                            end
                        end
                    end
                end
            end
            
            -- No physical button found, tutorial will still work with UI button
            return nil
        end
    },
    {
        id = "collect_100_pets",
        title = "🐾 Collect 100 Pets Total",
        description = "Now that you've rebirthed, collect 100 pets total. Your rebirth bonuses will help you collect pets faster!",
        targetType = "collection",
        targetCount = 100,
        pathTarget = function()
            -- Find CollectBase in player's area
            local playerAreas = Workspace:FindFirstChild("PlayerAreas")
            
            if playerAreas and character and character:FindFirstChild("HumanoidRootPart") then
                -- Use PlayerAreaFinder to get the player's assigned area only
                local PlayerAreaFinder = require(script.Parent.Parent.utils.PlayerAreaFinder)
                local playerArea = PlayerAreaFinder:FindPlayerArea()
                
                if playerArea then
                    local boundary1 = playerArea:FindFirstChild("Boundary1")
                    if boundary1 then
                        return boundary1
                    end
                end
            end
            
            -- Fallback: look for nearest pet ball
            local nearestBall = nil
            local nearestDistance = math.huge
            
            for _, obj in pairs(Workspace:GetChildren()) do
                if obj.Name == "PetBall" and obj:FindFirstChild("Position") then
                    local distance = (obj.Position - character.HumanoidRootPart.Position).Magnitude
                    if distance < nearestDistance then
                        nearestDistance = distance
                        nearestBall = obj
                    end
                end
            end
            
            return nearestBall
        end
    },
    {
        id = "process_500_pets",
        title = "⚙️ Process 500 Pets Total",
        description = "Process 500 pets total through your tubes. This will give you lots of money and help you progress faster!",
        targetType = "processing",
        targetCount = 500,
        pathTarget = function()
            -- Find Cylinder.007 inside SendHeaven model in player's area
            local playerAreas = Workspace:FindFirstChild("PlayerAreas")
            
            if playerAreas and character and character:FindFirstChild("HumanoidRootPart") then
                -- Use PlayerAreaFinder to get the player's assigned area only
                local PlayerAreaFinder = require(script.Parent.Parent.utils.PlayerAreaFinder)
                local playerArea = PlayerAreaFinder:FindPlayerArea()
                
                if playerArea then
                    local buttons = playerArea:FindFirstChild("Buttons")
                    if buttons then
                        local sendHeaven = buttons:FindFirstChild("SendHeaven")
                        if sendHeaven then
                            local cylinder = sendHeaven:FindFirstChild("Cylinder.007")
                            if cylinder then
                                return cylinder
                            end
                        end
                    end
                end
            end
            
            -- Fallback: look for any tube in workspace
            for i = 1, 10 do
                local tube = Workspace:FindFirstChild("Tube" .. i)
                if tube then
                    return tube
                end
            end
            return Workspace:FindFirstChild("TubePlot1")
        end
    },
    {
        id = "unlock_pet_mixer",
        title = "🔮 Unlock the Pet Mixer",
        description = "Reach 3 rebirths to unlock the Pet Mixer! This powerful feature lets you combine pets for better ones.",
        targetType = "rebirth",
        targetCount = 3,
        pathTarget = function()
            -- No specific path target - rebirth is done via GUI
            return nil
        end
    }
}

-- Tutorial state
local tutorialData = {
    active = false,
    currentStep = 1,
    completed = false,
    steps = TUTORIAL_STEPS
}

local isInitialized = false

-- Path visualization functions
local function clearPathVisual()
    -- Cancel all active tweens first
    for _, tween in pairs(activeTweens) do
        if tween then
            tween:Cancel()
        end
    end
    activeTweens = {} -- Clear the tween tracking table
    
    -- Clean up visual folder if it exists
    local existingFolder = Workspace:FindFirstChild("TutorialPath")
    if existingFolder then
        existingFolder:Destroy()
    end
    currentPathVisual = nil
end

-- Create NavigationBeams between waypoints
local function createNavigationBeams(waypoints)
    if #waypoints < 2 then return end
    
    -- Create beams between consecutive waypoints
    for i = 1, #waypoints - 1 do
        local waypoint1 = waypoints[i]
        local waypoint2 = waypoints[i + 1]
        
        -- Create invisible parts for attachments
        local part1 = Instance.new("Part")
        part1.Name = "BeamAnchor" .. i
        part1.Anchored = true
        part1.CanCollide = false
        part1.Transparency = 1
        part1.Size = Vector3.new(0.1, 0.1, 0.1)
        part1.Position = waypoint1.Position + Vector3.new(0, 0.5, 0) -- Slightly elevated
        part1.Parent = currentPathVisual
        
        local part2 = Instance.new("Part")
        part2.Name = "BeamAnchor" .. (i + 1)
        part2.Anchored = true
        part2.CanCollide = false
        part2.Transparency = 1
        part2.Size = Vector3.new(0.1, 0.1, 0.1)
        part2.Position = waypoint2.Position + Vector3.new(0, 0.5, 0) -- Slightly elevated
        part2.Parent = currentPathVisual
        
        -- Create attachments
        local attachment1 = Instance.new("Attachment")
        attachment1.Parent = part1
        
        local attachment2 = Instance.new("Attachment")
        attachment2.Parent = part2
        
        -- Create NavigationBeam with reversed attachments to flip arrow direction
        local beam = Instance.new("Beam")
        beam.Name = "NavigationBeam"
        beam.Attachment0 = attachment2  -- Swap: end becomes start
        beam.Attachment1 = attachment1  -- Swap: start becomes end
        beam.FaceCamera = true -- Always visible from any angle
        
        -- Start with white, will be animated to rainbow
        beam.Color = ColorSequence.new(Color3.new(1, 1, 1)) -- White base
        
        beam.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.4),
            NumberSequenceKeypoint.new(0.5, 0.2),
            NumberSequenceKeypoint.new(1, 0.4)
        }
        
        -- Use the rainbow arrow texture
        beam.Texture = "rbxassetid://138007024966757"
        beam.TextureMode = Enum.TextureMode.Wrap
        beam.TextureLength = 4 -- Length of each arrow segment
        beam.TextureSpeed = -2 -- Negative speed to match flipped beam direction
        
        -- Make beam thicker and maintain arrow direction effect
        beam.Width0 = 1.5 -- Start thicker
        beam.Width1 = 2.0 -- End even thicker (creates arrow head effect)
        
        beam.Parent = part1
        
        -- Create rainbow color animation
        local rainbowColors = {
            Color3.fromRGB(255, 0, 0),      -- Red
            Color3.fromRGB(255, 127, 0),    -- Orange
            Color3.fromRGB(255, 255, 0),    -- Yellow
            Color3.fromRGB(0, 255, 0),      -- Green
            Color3.fromRGB(0, 255, 255),    -- Cyan
            Color3.fromRGB(0, 0, 255),      -- Blue
            Color3.fromRGB(255, 0, 255),    -- Magenta
        }
        
        -- Start rainbow cycling animation
        local colorIndex = 1
        local function animateRainbow()
            while beam and beam.Parent do
                -- Set the current rainbow color directly
                local currentColor = rainbowColors[colorIndex]
                beam.Color = ColorSequence.new(currentColor)
                
                -- Move to next color
                colorIndex = colorIndex % #rainbowColors + 1
                
                -- Wait before next color change
                task.wait(0.5)
            end
        end
        
        -- Start the rainbow animation
        task.spawn(animateRainbow)
        
        -- No visible markers - just clean arrow beams
    end
end

-- Simple function: just create one beam from character to destination
local function updatePathMarkers(startPos, endPos)
    -- Always clear and recreate path
    clearPathVisual()
    
    -- Create folder for visual elements
    local pathFolder = Instance.new("Folder")
    pathFolder.Name = "TutorialPath"
    pathFolder.Parent = Workspace
    currentPathVisual = pathFolder
    
    -- Create just two waypoints for a single straight beam
    local waypoints = {
        {Position = startPos},
        {Position = endPos}
    }
    
    -- Create the single navigation beam
    createNavigationBeams(waypoints)
end


local lastUpdateTime = 0
local UPDATE_THROTTLE = 0.05 -- Update path every 0.05 seconds (20 FPS) for smooth tracking

local function updatePathVisual()
    if not tutorialData.active or tutorialData.completed then
        return
    end
    
    -- Throttle updates to prevent lag
    local currentTime = tick()
    if currentTime - lastUpdateTime < UPDATE_THROTTLE then
        return
    end
    
    local currentStep = TUTORIAL_STEPS[tutorialData.currentStep]
    if not currentStep or not currentStep.pathTarget then
        return
    end
    
    character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local target = currentStep.pathTarget()
    if not target then
        return
    end
    
    local targetPos = nil
    if target:IsA("BasePart") then
        targetPos = target.Position
    elseif target:FindFirstChild("Position") then
        local positionPart = target:FindFirstChild("Position")
        if positionPart:IsA("BasePart") then
            targetPos = positionPart.Position
        end
    end
    
    if not targetPos then
        return
    end
    
    -- Position at character's feet (ground level)
    local rootPart = character.HumanoidRootPart
    local startPos = rootPart.Position - Vector3.new(0, 3, 0)  -- Go down 3 studs to reach feet level
    
    -- Always check if player moved significantly
    if not lastPlayerPosition then
        lastPlayerPosition = startPos
        updatePathMarkers(startPos, targetPos)
        lastUpdateTime = currentTime
    else
        local moveDistance = (startPos - lastPlayerPosition).Magnitude
        
        if moveDistance > 8 then
            updatePathMarkers(startPos, targetPos)
            lastPlayerPosition = startPos
            lastUpdateTime = currentTime
        end
    end
end

-- Save tutorial progress to server
local function saveTutorialProgress()
    local tutorialRemote = ReplicatedStorage:FindFirstChild("UpdateTutorialProgress")
    if tutorialRemote then
        tutorialRemote:FireServer({
            currentStep = tutorialData.currentStep,
            active = tutorialData.active,
            completed = tutorialData.completed
        })
    end
end

-- Tutorial control functions
function TutorialService:StartTutorial()
    tutorialData.active = true
    tutorialData.completed = false
    tutorialData.steps = TUTORIAL_STEPS  -- Make sure steps are available
    
    -- Reset path following
    lastPlayerPosition = nil
    clearPathVisual()
    
    -- Start path updates
    if pathUpdateConnection then
        pathUpdateConnection:Disconnect()
    end
    pathUpdateConnection = RunService.Heartbeat:Connect(function()
        updatePathVisual()
    end)
    
    -- Save progress
    saveTutorialProgress()
    
    -- Tutorial started
end

function TutorialService:StopTutorial()
    tutorialData.active = false
    tutorialData.completed = true
    clearPathVisual()
    
    -- Stop path update connection to prevent lag
    if pathUpdateConnection then
        pathUpdateConnection:Disconnect()
        pathUpdateConnection = nil
    end
    
    -- Save progress
    saveTutorialProgress()
    
    -- Tutorial stopped
end

function TutorialService:NextStep()
    if tutorialData.currentStep < #TUTORIAL_STEPS then
        tutorialData.currentStep = tutorialData.currentStep + 1
        
        -- Tutorial advanced to next step
        
        -- Clear old path and force recreation for new step (immediate client-side)
        clearPathVisual()
        lastPlayerPosition = nil
        
        -- Force immediate path creation for new step
        task.spawn(function()
            -- Small delay to ensure character position is stable
            task.wait(0.1)
            
            local currentStep = TUTORIAL_STEPS[tutorialData.currentStep]
            if currentStep and currentStep.pathTarget and character and character:FindFirstChild("HumanoidRootPart") then
                local target = currentStep.pathTarget()
                if target then
                    local targetPos = nil
                    if target:IsA("BasePart") then
                        targetPos = target.Position
                    elseif target:FindFirstChild("Position") then
                        local positionPart = target:FindFirstChild("Position")
                        if positionPart:IsA("BasePart") then
                            targetPos = positionPart.Position
                        end
                    end
                    
                    if targetPos then
                        local startPos = character.HumanoidRootPart.Position
                        updatePathMarkers(startPos, targetPos)
                        lastPlayerPosition = startPos
                        -- Path created for step
                    else
                        -- No valid target position
                    end
                else
                    -- No path target found
                end
            else
                -- Step has no pathTarget function
            end
        end)
        
        -- Save progress to server (async, doesn't block UI)
        task.spawn(function()
            saveTutorialProgress()
        end)
        
    else
        self:StopTutorial()
    end
end

function TutorialService:SetStep(stepNumber)
    if stepNumber >= 1 and stepNumber <= #TUTORIAL_STEPS then
        tutorialData.currentStep = stepNumber
        tutorialData.completed = false
        
        -- Reset all step completion flags
        for _, step in pairs(TUTORIAL_STEPS) do
            step.completed = false
        end
        
        -- Clear old path and force recreation for new step
        clearPathVisual()
        lastPlayerPosition = nil
        
        -- Force immediate path creation for new step
        local currentStep = TUTORIAL_STEPS[tutorialData.currentStep]
        if currentStep and currentStep.pathTarget and character and character:FindFirstChild("HumanoidRootPart") then
            local target = currentStep.pathTarget()
            if target then
                local targetPos = nil
                if target:IsA("BasePart") then
                    targetPos = target.Position
                elseif target:FindFirstChild("Position") then
                    local positionPart = target:FindFirstChild("Position")
                    if positionPart:IsA("BasePart") then
                        targetPos = positionPart.Position
                    end
                end
                
                if targetPos then
                    local startPos = character.HumanoidRootPart.Position
                    updatePathMarkers(startPos, targetPos)
                    lastPlayerPosition = startPos
                end
            end
        end
        
        -- Save progress
        saveTutorialProgress()
        
        -- Tutorial manually set to step
    end
end

function TutorialService:Reset()
    tutorialData.currentStep = 1
    tutorialData.completed = false
    tutorialData.active = true
    
    -- Reset all step completion flags
    for _, step in pairs(TUTORIAL_STEPS) do
        step.completed = false
    end
    
    lastPlayerPosition = nil
    clearPathVisual()
    
    -- Save progress
    saveTutorialProgress()
    
    -- Tutorial reset
end

function TutorialService:GetTutorialData()
    return tutorialData
end

function TutorialService:GetProgressText()
    if not tutorialData.active or tutorialData.completed then
        return "100%"
    end
    
    local currentStep = TUTORIAL_STEPS[tutorialData.currentStep]
    if not currentStep then
        return "0%"
    end
    
    local playerData = store:getState().player
    if not playerData then
        return "0%"
    end
    
    local stepId = currentStep.id
    
    if stepId == "collect_10_pets" then
        local current = playerData.Pets and #playerData.Pets or 0
        return math.min(current, 10) .. "/10"
        
    elseif stepId == "process_pets" then
        local current = playerData.ProcessedPets or 0
        return math.min(current, 20) .. "/20"
        
    elseif stepId == "collect_100_pets" then
        local current = playerData.Pets and #playerData.Pets or 0
        return math.min(current, 100) .. "/100"
        
    elseif stepId == "process_500_pets" then
        local current = playerData.ProcessedPets or 0
        return math.min(current, 500) .. "/500"
        
    else
        -- For non-counting steps, show percentage
        -- Recalculate progress inline since calculateTaskProgress is local
        if stepId == "unlock_first_plot" then
            if character and character:FindFirstChild("HumanoidRootPart") then
                local plot = Workspace:FindFirstChild("Plot1")
                if plot and plot:FindFirstChild("TouchPart") then
                    local distance = (plot.TouchPart.Position - character.HumanoidRootPart.Position).Magnitude
                    local progress = math.max(0, math.min(100, (100 - distance)))
                    return math.floor(progress) .. "%"
                end
            end
            return playerData.OwnedPlots and #playerData.OwnedPlots > 0 and "100%" or "0%"
            
        elseif stepId == "unlock_first_tube" then
            if character and character:FindFirstChild("HumanoidRootPart") then
                local tubePlot = Workspace:FindFirstChild("TubePlot1")
                if tubePlot and tubePlot:FindFirstChild("TouchPart") then
                    local distance = (tubePlot.TouchPart.Position - character.HumanoidRootPart.Position).Magnitude
                    local progress = math.max(0, math.min(100, (100 - distance)))
                    return math.floor(progress) .. "%"
                end
            end
            return playerData.OwnedTubes and #playerData.OwnedTubes > 0 and "✅ Completed!" or "❌ Not achieved"
            
        elseif stepId == "unlock_next_door" then
            -- Check if Plot 2 is owned
            if playerData.OwnedPlots then
                for _, plotNumber in pairs(playerData.OwnedPlots) do
                    if plotNumber == 2 then
                        return "✅ Completed!"
                    end
                end
            end
            -- Check distance to Plot2 for progress
            if character and character:FindFirstChild("HumanoidRootPart") then
                local playerAreas = Workspace:FindFirstChild("PlayerAreas")
                if playerAreas then
                    for _, area in pairs(playerAreas:GetChildren()) do
                        if area.Name:match("PlayerArea") then
                            local buttons = area:FindFirstChild("Buttons")
                            if buttons then
                                local plot2 = buttons:FindFirstChild("Plot2")
                                if plot2 and plot2:FindFirstChild("TouchPart") then
                                    local distance = (plot2.TouchPart.Position - character.HumanoidRootPart.Position).Magnitude
                                    local progress = math.max(0, math.min(100, (100 - distance)))
                                    return math.floor(progress) .. "%"
                                end
                            end
                        end
                    end
                end
            end
            return "❌ Not achieved"
            
        elseif stepId == "get_rare_pet" then
            if playerData.Pets then
                for _, pet in pairs(playerData.Pets) do
                    if pet.SpawnChance and pet.SpawnChance <= 0.4 then
                        return "✅ Completed!"
                    end
                end
            end
            return "❌ Not achieved"
            
        elseif stepId == "first_rebirth" then
            return playerData.Resources and playerData.Resources.Rebirths >= 1 and "✅ Completed!" or "❌ Not achieved"
            
        elseif stepId == "unlock_pet_mixer" then
            local current = playerData.Resources and playerData.Resources.Rebirths or 0
            local progress = math.min(100, (current / 3) * 100)
            return math.floor(progress) .. "%"
            
        else
            return "0%"
        end
    end
end

function TutorialService:IsActive()
    return tutorialData.active
end

function TutorialService:GetCurrentStep()
    return TUTORIAL_STEPS[tutorialData.currentStep]
end

-- Check tutorial progress
-- Calculate task-specific progress percentage
local function calculateTaskProgress(step, playerData)
    if not step or not playerData then return 0 end
    
    local stepId = step.id
    
    -- Handle each step type
    if stepId == "unlock_first_plot" then
        -- Check distance to Plot1
        if character and character:FindFirstChild("HumanoidRootPart") then
            local plot = Workspace:FindFirstChild("Plot1")
            if plot and plot:FindFirstChild("TouchPart") then
                local distance = (plot.TouchPart.Position - character.HumanoidRootPart.Position).Magnitude
                -- Closer = higher progress (max distance 100 studs)
                return math.max(0, math.min(100, (100 - distance)))
            end
        end
        return playerData.OwnedPlots and #playerData.OwnedPlots > 0 and 100 or 0
        
    elseif stepId == "unlock_first_tube" then
        -- Similar distance-based progress for tube
        if character and character:FindFirstChild("HumanoidRootPart") then
            local tubePlot = Workspace:FindFirstChild("TubePlot1")
            if tubePlot and tubePlot:FindFirstChild("TouchPart") then
                local distance = (tubePlot.TouchPart.Position - character.HumanoidRootPart.Position).Magnitude
                return math.max(0, math.min(100, (100 - distance)))
            end
        end
        return playerData.OwnedTubes and #playerData.OwnedTubes > 0 and 100 or 0
        
    elseif stepId == "collect_10_pets" then
        -- 10 pets target
        local current = playerData.Pets and #playerData.Pets or 0
        return math.min(100, (current / 10) * 100)
        
    elseif stepId == "process_pets" then
        -- 20 pets processed target
        local current = playerData.ProcessedPets or 0
        return math.min(100, (current / 20) * 100)
        
    elseif stepId == "unlock_next_door" then
        -- Check if Plot 2 is owned
        if playerData.OwnedPlots then
            for _, plotNumber in pairs(playerData.OwnedPlots) do
                if plotNumber == 2 then
                    return 100
                end
            end
        end
        -- Check distance to Plot2 for progress
        if character and character:FindFirstChild("HumanoidRootPart") then
            local playerAreas = Workspace:FindFirstChild("PlayerAreas")
            if playerAreas then
                for _, area in pairs(playerAreas:GetChildren()) do
                    if area.Name:match("PlayerArea") then
                        local buttons = area:FindFirstChild("Buttons")
                        if buttons then
                            local plot2 = buttons:FindFirstChild("Plot2")
                            if plot2 and plot2:FindFirstChild("TouchPart") then
                                local distance = (plot2.TouchPart.Position - character.HumanoidRootPart.Position).Magnitude
                                return math.max(0, math.min(100, (100 - distance)))
                            end
                        end
                    end
                end
            end
        end
        return 0
        
    elseif stepId == "get_rare_pet" then
        -- Check if any pet has rarity > 1000
        if playerData.Pets then
            for _, pet in pairs(playerData.Pets) do
                if pet.SpawnChance and pet.SpawnChance <= 0.4 then -- 1 in 250 or rarer (0.4%)
                    return 100
                end
            end
        end
        return 0
        
    elseif stepId == "first_rebirth" then
        -- Binary: either rebirthed or not
        return playerData.Resources and playerData.Resources.Rebirths >= 1 and 100 or 0
        
    elseif stepId == "collect_100_pets" then
        -- 100 pets target
        local current = playerData.Pets and #playerData.Pets or 0
        return math.min(100, (current / 100) * 100)
        
    elseif stepId == "process_500_pets" then
        -- 500 pets processed target
        local current = playerData.ProcessedPets or 0
        return math.min(100, (current / 500) * 100)
        
    elseif stepId == "unlock_pet_mixer" then
        -- 3 rebirths required
        local current = playerData.Resources and playerData.Resources.Rebirths or 0
        return math.min(100, (current / 3) * 100)
    end
    
    return 0
end

-- Event-driven step completion checking
function TutorialService:CheckStepCompletion(playerData)
    if not tutorialData.active or tutorialData.completed then
        return
    end
    
    local currentStep = TUTORIAL_STEPS[tutorialData.currentStep]
    if not currentStep or currentStep.completed then
        return
    end
    
    if not playerData then
        return
    end
    
    -- Calculate task progress for UI
    local taskProgress = calculateTaskProgress(currentStep, playerData)
    tutorialData.taskProgress = taskProgress
    
    -- Check if step is completed
    local stepCompleted = false
    local stepId = currentStep.id
    
    if stepId == "unlock_first_plot" then
        stepCompleted = playerData.OwnedPlots and #playerData.OwnedPlots > 0
        
    elseif stepId == "collect_10_pets" then
        stepCompleted = playerData.Pets and #playerData.Pets >= 10
        
    elseif stepId == "unlock_first_tube" then
        stepCompleted = playerData.OwnedTubes and #playerData.OwnedTubes > 0
        
    elseif stepId == "process_pets" then
        stepCompleted = playerData.ProcessedPets and playerData.ProcessedPets >= 20
        
    elseif stepId == "unlock_next_door" then
        -- Check if player owns Plot 2
        if playerData.OwnedPlots then
            for _, plotNumber in pairs(playerData.OwnedPlots) do
                if plotNumber == 2 then
                    stepCompleted = true
                    break
                end
            end
        end
        
    elseif stepId == "get_rare_pet" then
        if playerData.Pets then
            for _, pet in pairs(playerData.Pets) do
                -- Debug: Check what data we have
                if pet.SpawnChance then
                    print("TutorialService: Checking pet", pet.Name or "Unknown", "with SpawnChance", pet.SpawnChance)
                    if pet.SpawnChance <= 0.4 then -- 1 in 250 or rarer (0.4%)
                        print("TutorialService: Found rare pet!", pet.Name, "with SpawnChance", pet.SpawnChance)
                        stepCompleted = true
                        break
                    end
                else
                    print("TutorialService: Pet", pet.Name or "Unknown", "has no SpawnChance field")
                end
            end
        end
        
    elseif stepId == "first_rebirth" then
        stepCompleted = playerData.Resources and playerData.Resources.Rebirths >= 1
        
    elseif stepId == "collect_100_pets" then
        stepCompleted = playerData.Pets and #playerData.Pets >= 100
        
    elseif stepId == "process_500_pets" then
        stepCompleted = playerData.ProcessedPets and playerData.ProcessedPets >= 500
        
    elseif stepId == "unlock_pet_mixer" then
        stepCompleted = playerData.Resources and playerData.Resources.Rebirths >= 3
    end
    
    if stepCompleted and not currentStep.completed then
        -- Step completed
        currentStep.completed = true
        
        -- Advance to next step immediately (client-side)
        task.spawn(function()
            task.wait(0.5) -- Very brief delay for visual feedback
            if tutorialData.active and not tutorialData.completed then
                self:NextStep()
            end
        end)
    end
end

-- Load tutorial progress from player data
local function loadTutorialProgress()
    local playerData = store:getState().player
    if playerData and playerData.TutorialProgress then
        local progress = playerData.TutorialProgress
        tutorialData.currentStep = progress.currentStep or 1
        tutorialData.active = progress.active or false
        tutorialData.completed = playerData.TutorialCompleted or false
        tutorialData.steps = TUTORIAL_STEPS  -- Always include steps
        
        -- Tutorial progress loaded silently
    end
end

-- Initialize tutorial system
function TutorialService:Initialize()
    if isInitialized then
        return
    end
    isInitialized = true
    
    -- TutorialService initializing
    
    -- Subscribe to data changes for event-driven step completion
    local unsubscribe = store.changed:connect(function(newState, oldState)
        if newState.player then
            -- Load tutorial progress when data updates
            loadTutorialProgress()
            -- Check step completion when player data changes
            self:CheckStepCompletion(newState.player)
        end
    end)
    
    connections.dataSubscription = unsubscribe
    
    -- Handle character respawning
    player.CharacterAdded:Connect(function(newCharacter)
        character = newCharacter
        task.wait(1) -- Wait for character to load
        updatePathVisual()
    end)
    
    -- Auto-start tutorial for new players
    task.spawn(function()
        task.wait(5) -- Wait for game and data to load
        
        local playerData = store:getState().player
        -- Check if should start tutorial
        
        -- Load existing progress first
        loadTutorialProgress()
        
        -- Start tutorial if player hasn't completed it
        if playerData then
            -- Tutorial should show if not completed
            local shouldShowTutorial = not playerData.TutorialCompleted
            
            if shouldShowTutorial then
                -- Check if we should auto-start (new player with no plots)
                local isNewPlayer = not playerData.OwnedPlots or #playerData.OwnedPlots == 0
                
                if isNewPlayer and not tutorialData.active then
                    -- Auto-starting tutorial for new player
                    self:StartTutorial()
                elseif tutorialData.active then
                    -- Tutorial already active, resuming
                    -- Ensure steps are loaded
                    tutorialData.steps = TUTORIAL_STEPS
                    -- Start path updates for resumed tutorial
                    if pathUpdateConnection then
                        pathUpdateConnection:Disconnect()
                    end
                    pathUpdateConnection = RunService.Heartbeat:Connect(function()
                        updatePathVisual()
                    end)
                    -- Started path update connection
                else
                    -- Tutorial available but not auto-starting
                end
            else
                -- Tutorial completed
            end
        end
    end)
end

function TutorialService:Cleanup()
    -- Stop tutorial first to clean up path updates
    tutorialData.active = false
    
    -- Disconnect path update connection
    if pathUpdateConnection then
        pathUpdateConnection:Disconnect()
        pathUpdateConnection = nil
    end
    
    -- Clean up all connections
    for name, connection in pairs(connections) do
        if connection and type(connection) == "function" then
            connection()
        elseif connection and typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end
    connections = {}
    
    -- Clear path visuals and cancel all tweens
    clearPathVisual()
end

return TutorialService