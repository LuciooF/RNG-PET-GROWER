-- TutorialService - Manages tutorial progression and pathfinding
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local DataSyncService = require(script.Parent.DataSyncService)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)

local TutorialService = {}
TutorialService.__index = TutorialService

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local connections = {}
local currentPathVisual = nil
local pathUpdateConnection = nil

-- Tutorial step definitions
local TUTORIAL_STEPS = {
    {
        id = "unlock_first_plot",
        title = "🏗️ Unlock Your First Plot",
        description = "Follow the glowing path to Plot 1 and click on it to unlock it. This will cost you 0 money (it's free!)",
        targetType = "plot",
        targetId = 1,
        checkFunction = function(playerData)
            return playerData and playerData.OwnedPlots and #playerData.OwnedPlots > 0
        end,
        pathTarget = function()
            -- Look for Plot1 or any plot with Position
            local plot = Workspace:FindFirstChild("Plot1")
            if plot and plot:FindFirstChild("Position") then
                return plot
            end
            
            -- Fallback: look for any plot
            for _, child in pairs(Workspace:GetChildren()) do
                if child.Name:match("^Plot%d+$") and child:FindFirstChild("Position") then
                    return child
                end
            end
            
            return nil
        end
    },
    {
        id = "unlock_first_tube",
        title = "🧪 Unlock Your First Tube",
        description = "Great! Now follow the path to TubePlot 1 to unlock your first processing tube. This is where you'll process pets for rewards!",
        targetType = "tubeplot",
        targetId = 1,
        checkFunction = function(playerData)
            return playerData and playerData.OwnedTubes and #playerData.OwnedTubes > 0
        end,
        pathTarget = function()
            -- Look for TubePlot1 or any tube plot with Position
            local tubePlot = Workspace:FindFirstChild("TubePlot1")
            if tubePlot and tubePlot:FindFirstChild("Position") then
                return tubePlot
            end
            
            -- Fallback: look for any tube plot
            for _, child in pairs(Workspace:GetChildren()) do
                if child.Name:match("^TubePlot%d+$") and child:FindFirstChild("Position") then
                    return child
                end
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
        checkFunction = function(playerData)
            if not playerData or not playerData.OwnedPets then return false end
            return #playerData.OwnedPets >= 10
        end,
        pathTarget = function()
            -- Find nearest pet ball or door
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
            
            -- If no pet balls, guide to first door
            return nearestBall or Workspace:FindFirstChild("Door1")
        end
    },
    {
        id = "process_pets",
        title = "⚙️ Process Your Pets",
        description = "Go to your tube and process some pets! Click on the tube to start processing. You need to process at least 1 pet.",
        targetType = "processing",
        targetCount = 1,
        checkFunction = function(playerData)
            return playerData and playerData.ProcessedPets and playerData.ProcessedPets >= 1
        end,
        pathTarget = function()
            -- Look for Tube1 or any tube with Position
            local tube = Workspace:FindFirstChild("Tube1")
            if tube and tube:FindFirstChild("Position") then
                return tube
            end
            
            -- Fallback: look for any tube
            for _, child in pairs(Workspace:GetChildren()) do
                if child.Name:match("^Tube%d+$") and child:FindFirstChild("Position") then
                    return child
                end
            end
            
            return nil
        end
    },
    {
        id = "get_rare_pet",
        title = "✨ Get a Rare Pet",
        description = "Keep collecting pets until you get one that's rarer than 1 in 1,000! Check the Pet Index to see your collection.",
        targetType = "rarity",
        checkFunction = function(playerData)
            if not playerData or not playerData.OwnedPets then return false end
            -- Check if any pet has rarity better than 1 in 1000
            for _, pet in pairs(playerData.OwnedPets) do
                if pet.SpawnChance and pet.SpawnChance < 0.1 then -- Less than 0.1% = rarer than 1 in 1000
                    return true
                end
            end
            return false
        end,
        pathTarget = function()
            -- Guide to pet collection areas
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
            
            return nearestBall or Workspace:FindFirstChild("Door1")
        end
    },
    {
        id = "first_rebirth",
        title = "🌟 Perform Your First Rebirth",
        description = "You're ready to rebirth! This will reset your progress but give you permanent bonuses. Click the Rebirth button when ready.",
        targetType = "rebirth",
        targetCount = 1,
        checkFunction = function(playerData)
            return playerData and playerData.Rebirths and playerData.Rebirths >= 1
        end,
        pathTarget = function()
            -- No specific path target - rebirth is done via GUI
            return nil
        end
    },
    {
        id = "collect_100_pets",
        title = "🐾 Collect 100 Pets Total",
        description = "Now that you've rebirthed, collect 100 pets total. Your rebirth bonuses will help you collect pets faster!",
        targetType = "collection",
        targetCount = 100,
        checkFunction = function(playerData)
            if not playerData or not playerData.OwnedPets then return false end
            return #playerData.OwnedPets >= 100
        end,
        pathTarget = function()
            -- Guide to pet collection areas
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
            
            return nearestBall or Workspace:FindFirstChild("Door2")
        end
    },
    {
        id = "process_500_pets",
        title = "⚙️ Process 500 Pets Total",
        description = "Process 500 pets total through your tubes. This will give you lots of money and help you progress faster!",
        targetType = "processing",
        targetCount = 500,
        checkFunction = function(playerData)
            return playerData and playerData.ProcessedPets and playerData.ProcessedPets >= 500
        end,
        pathTarget = function()
            -- Guide to tubes
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
        checkFunction = function(playerData)
            return playerData and playerData.Rebirths and playerData.Rebirths >= 3
        end,
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
    if currentPathVisual then
        currentPathVisual:Destroy()
        currentPathVisual = nil
    end
    if pathUpdateConnection then
        pathUpdateConnection:Disconnect()
        pathUpdateConnection = nil
    end
end

local function createPathVisual(startPos, endPos)
    clearPathVisual()
    
    -- Create a folder to hold path parts
    local pathFolder = Instance.new("Folder")
    pathFolder.Name = "TutorialPath"
    pathFolder.Parent = Workspace
    currentPathVisual = pathFolder
    
    -- Calculate path points (simple straight line for now, can be enhanced)
    local direction = (endPos - startPos).Unit
    local distance = (endPos - startPos).Magnitude
    local numPoints = math.max(3, math.floor(distance / 5)) -- Point every 5 studs
    
    for i = 1, numPoints do
        local progress = i / numPoints
        local position = startPos + direction * distance * progress
        position = Vector3.new(position.X, position.Y + 1, position.Z) -- Slightly above ground
        
        -- Create glowing orb
        local part = Instance.new("Part")
        part.Name = "PathPoint"
        part.Size = Vector3.new(2, 2, 2)
        part.Shape = Enum.PartType.Ball
        part.Material = Enum.Material.Neon
        part.BrickColor = BrickColor.new("Bright yellow")
        part.Anchored = true
        part.CanCollide = false
        part.Position = position
        part.Parent = pathFolder
        
        -- Add glowing effect
        local pointLight = Instance.new("PointLight")
        pointLight.Color = Color3.fromRGB(255, 255, 0)
        pointLight.Brightness = 2
        pointLight.Range = 10
        pointLight.Parent = part
        
        -- Animate the orb
        local tween = TweenService:Create(part, 
            TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {Transparency = 0.5}
        )
        tween:Play()
        
        -- Pulse animation
        local sizeTween = TweenService:Create(part,
            TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {Size = Vector3.new(2.5, 2.5, 2.5)}
        )
        sizeTween:Play()
    end
    
    -- Add arrow at destination
    local arrow = Instance.new("Part")
    arrow.Name = "DestinationArrow"
    arrow.Size = Vector3.new(3, 6, 1)
    arrow.Material = Enum.Material.Neon
    arrow.BrickColor = BrickColor.new("Bright green")
    arrow.Anchored = true
    arrow.CanCollide = false
    arrow.Position = endPos + Vector3.new(0, 5, 0)
    arrow.Parent = pathFolder
    
    -- Arrow mesh
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.Wedge
    mesh.Scale = Vector3.new(1, 1, 1)
    mesh.Parent = arrow
    
    -- Rotate arrow to point down
    arrow.CFrame = CFrame.new(arrow.Position) * CFrame.Angles(math.rad(180), 0, 0)
    
    -- Animate arrow
    local arrowTween = TweenService:Create(arrow,
        TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Position = endPos + Vector3.new(0, 3, 0)}
    )
    arrowTween:Play()
end

local function updatePathVisual()
    if not tutorialData.active or tutorialData.completed then
        clearPathVisual()
        return
    end
    
    local currentStep = TUTORIAL_STEPS[tutorialData.currentStep]
    if not currentStep or not currentStep.pathTarget then
        clearPathVisual()
        return
    end
    
    -- Update character reference
    character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        clearPathVisual()
        return
    end
    
    local target = currentStep.pathTarget()
    if not target then
        clearPathVisual()
        return
    end
    
    -- Get target position - handle both direct Position and child Position
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
        clearPathVisual()
        return
    end
    
    local startPos = character.HumanoidRootPart.Position
    
    -- Only update if target has moved significantly or path doesn't exist
    if not currentPathVisual or (targetPos - startPos).Magnitude > 5 then
        createPathVisual(startPos, targetPos)
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
    
    -- Start path updates
    if pathUpdateConnection then
        pathUpdateConnection:Disconnect()
    end
    pathUpdateConnection = RunService.Heartbeat:Connect(function()
        updatePathVisual()
    end)
    
    -- Save progress
    saveTutorialProgress()
    
    print("Tutorial started! Step:", tutorialData.currentStep)
end

function TutorialService:StopTutorial()
    tutorialData.active = false
    tutorialData.completed = true
    clearPathVisual()
    
    -- Save progress
    saveTutorialProgress()
    
    print("Tutorial stopped!")
end

function TutorialService:NextStep()
    if tutorialData.currentStep < #TUTORIAL_STEPS then
        tutorialData.currentStep = tutorialData.currentStep + 1
        updatePathVisual()
        
        -- Save progress
        saveTutorialProgress()
        
        print("Tutorial advanced to step:", tutorialData.currentStep)
    else
        self:StopTutorial()
    end
end

function TutorialService:GetTutorialData()
    return tutorialData
end

function TutorialService:IsActive()
    return tutorialData.active
end

function TutorialService:GetCurrentStep()
    return TUTORIAL_STEPS[tutorialData.currentStep]
end

-- Check tutorial progress
function TutorialService:CheckProgress()
    if not tutorialData.active or tutorialData.completed then
        return
    end
    
    local currentStep = TUTORIAL_STEPS[tutorialData.currentStep]
    if not currentStep then
        return
    end
    
    local playerData = DataSyncService:GetPlayerData()
    if currentStep.checkFunction and currentStep.checkFunction(playerData) then
        currentStep.completed = true
        -- Auto-advance after a short delay
        task.wait(1)
        if tutorialData.active then
            self:NextStep()
        end
    end
end

-- Load tutorial progress from player data
local function loadTutorialProgress()
    local playerData = DataSyncService:GetPlayerData()
    if playerData and playerData.TutorialProgress then
        local progress = playerData.TutorialProgress
        tutorialData.currentStep = progress.currentStep or 1
        tutorialData.active = progress.active or false
        tutorialData.completed = playerData.TutorialCompleted or false
        
        print("Tutorial progress loaded:", {
            step = tutorialData.currentStep,
            active = tutorialData.active,
            completed = tutorialData.completed
        })
    end
end

-- Initialize tutorial system
function TutorialService:Initialize()
    if isInitialized then
        return
    end
    isInitialized = true
    
    print("TutorialService: Initializing...")
    
    -- Subscribe to data changes to check progress
    local unsubscribe = DataSyncService:Subscribe(function(newState)
        if newState.player then
            -- Load tutorial progress when data updates
            loadTutorialProgress()
            self:CheckProgress()
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
        
        local playerData = DataSyncService:GetPlayerData()
        print("TutorialService: Checking if should start tutorial:", playerData and {
            tutorialCompleted = playerData.TutorialCompleted,
            ownedPlots = playerData.OwnedPlots and #playerData.OwnedPlots or 0,
            tutorialProgress = playerData.TutorialProgress
        } or "No player data")
        
        -- Load existing progress first
        loadTutorialProgress()
        
        -- Start tutorial if player hasn't completed it and has no plots
        if playerData then
            if not playerData.TutorialCompleted and (not playerData.OwnedPlots or #playerData.OwnedPlots == 0) then
                -- Only start if not already active
                if not tutorialData.active then
                    print("TutorialService: Starting tutorial for new player")
                    self:StartTutorial()
                else
                    print("TutorialService: Tutorial already active, resuming from step", tutorialData.currentStep)
                end
            else
                print("TutorialService: Tutorial not needed - completed or has progress")
            end
        end
    end)
end

function TutorialService:Cleanup()
    for name, connection in pairs(connections) do
        if connection and type(connection) == "function" then
            connection()
        elseif connection and typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end
    connections = {}
    
    clearPathVisual()
end

return TutorialService