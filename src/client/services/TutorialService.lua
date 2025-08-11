-- TutorialService - Manages tutorial progression and path visuals (improved)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local CollectionService = game:GetService("CollectionService")

local store = require(ReplicatedStorage.store)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)
local PlayerAreaFinder = require(ReplicatedStorage.utils.PlayerAreaFinder)

local TutorialService = {}
TutorialService.__index = TutorialService

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local connections = {}

-- Visual beam state (persistent — we move anchors instead of rebuilding)
local beamFolder: Folder? = nil
local startPart: BasePart? = nil
local endPart: BasePart? = nil
local beam: Beam? = nil

-- Update loop connections
local visualUpdateConn: RBXScriptConnection? = nil

-- Target/area caches
local cachedArea: Instance? = nil
local currentTargetInstance: Instance? = nil

-- Small throttle since we're only moving attachments (cheap)
local lastUpdateTime = 0
local UPDATE_THROTTLE = 0.02 -- ~50 FPS

-- ========= Helpers =========

local function getPlayerArea(): Instance?
	if cachedArea and cachedArea.Parent then
		return cachedArea
	end
	cachedArea = PlayerAreaFinder:FindPlayerArea()
	return cachedArea
end

local function resolveTargetPosition(target: Instance?): Vector3?
	if not target or not target.Parent then return nil end
	if target:IsA("BasePart") then return target.Position end
	local pos = target:FindFirstChild("Position")
	if pos and pos:IsA("BasePart") then return pos.Position end
	return nil
end

local function findInButtons(area: Instance?, name: string): Instance?
	if not area then return nil end
	local buttons = area:FindFirstChild("Buttons")
	if not buttons then return nil end
	return buttons:FindFirstChild(name)
end

local function findNearestPetBall(fromPos: Vector3): Instance?
	-- Prefer tagged objects (cheaper than scanning entire Workspace)
	local tagged = {}
	local ok, res = pcall(function()
		return CollectionService:GetTagged("PetBall")
	end)
	if ok and res and #res > 0 then
		tagged = res
	else
		-- Fallback: scan workspace (avoid every frame if possible)
		tagged = {}
		for _, obj in ipairs(Workspace:GetChildren()) do
			if obj.Name == "PetBall" then
				table.insert(tagged, obj)
			end
		end
	end

	local nearest, nearestDist = nil, math.huge
	for _, obj in ipairs(tagged) do
		local pos = resolveTargetPosition(obj) or (obj:IsA("BasePart") and obj.Position or nil)
		if pos then
			local d = (pos - fromPos).Magnitude
			if d < nearestDist then
				nearestDist = d
				nearest = obj
			end
		end
	end
	return nearest
end

-- ========= Path Beam (persistent) =========

local function clearPathVisual()
	if visualUpdateConn then
		visualUpdateConn:Disconnect()
		visualUpdateConn = nil
	end
	if beamFolder then
		beamFolder:Destroy()
		beamFolder = nil
		beam = nil
		startPart = nil
		endPart = nil
	end
	currentTargetInstance = nil
end

local function ensureBeam()
	if beam and beam.Parent then return end

	if beamFolder then
		beamFolder:Destroy()
	end

	beamFolder = Instance.new("Folder")
	beamFolder.Name = "TutorialPath"
	beamFolder.Parent = Workspace

	startPart = Instance.new("Part")
	startPart.Name = "StartAnchor"
	startPart.Anchored = true
	startPart.CanCollide = false
	startPart.Transparency = 1
	startPart.Size = Vector3.new(0.1, 0.1, 0.1)
	startPart.Parent = beamFolder

	endPart = startPart:Clone()
	endPart.Name = "EndAnchor"
	endPart.Parent = beamFolder

	local a0 = Instance.new("Attachment")
	a0.Name = "StartAttachment"
	a0.Parent = startPart

	local a1 = Instance.new("Attachment")
	a1.Name = "EndAttachment"
	a1.Parent = endPart

	beam = Instance.new("Beam")
	beam.Name = "NavigationBeam"
	beam.Attachment0 = a1 -- flipped for arrow direction
	beam.Attachment1 = a0
	beam.FaceCamera = true
	beam.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
	ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 127, 0)),
	ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),
	ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 0)),
	ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 255, 255)),
	ColorSequenceKeypoint.new(0.83, Color3.fromRGB(0, 0, 255)),
	ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 255)),
})
	beam.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 0.4)
	}
	beam.Texture = "rbxassetid://138007024966757" -- rainbow arrow texture
	beam.TextureMode = Enum.TextureMode.Wrap
	beam.TextureLength = 4
	beam.TextureSpeed = -2
	beam.Width0 = 1.5
	beam.Width1 = 2.0
	beam.Parent = startPart
end

local function setBeamPositions(startPos: Vector3, endPos: Vector3)
	if not beam or not startPart or not endPart then return end
	startPart.Position = startPos + Vector3.new(0, 0.5, 0)
	endPart.Position = endPos + Vector3.new(0, 0.5, 0)
end

-- ========= Steps =========

local TUTORIAL_STEPS = {
	{
		id = "unlock_first_plot",
		title = "🏗️ Unlock Your First Plot",
		description = "Follow the glowing path to Plot 1 and click on it to unlock it. This will cost you 0 money (it's free!)",
		targetType = "plot",
		targetId = 1,
		pathTarget = function()
			local area = getPlayerArea()
			if not area then return nil end
			local plot = findInButtons(area, "Plot1")
			if not plot then return nil end
			return plot:FindFirstChild("TouchPart") or plot:FindFirstChild("Cube.008") or plot:FindFirstChild("Position") or plot
		end
	},
	{
		id = "collect_10_pets",
		title = "🐾 Collect 10 Pets",
		description = "Pet balls will spawn near unlocked doors! Walk over them to collect pets. Collect 10 pets total.",
		targetType = "collection",
		targetCount = 10,
		pathTarget = function()
			local area = getPlayerArea()
			if area then
				local collectBase = area:FindFirstChild("CollectBase")
				if collectBase then return collectBase end
			end
			if character and character:FindFirstChild("HumanoidRootPart") then
				return findNearestPetBall(character.HumanoidRootPart.Position)
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
		pathTarget = function()
			local area = getPlayerArea()
			if not area then return nil end
			local tubePlot = findInButtons(area, "TubePlot1")
			if not tubePlot then return nil end
			return tubePlot:FindFirstChild("TouchPart") or tubePlot:FindFirstChild("Cube.008") or tubePlot:FindFirstChild("Position") or tubePlot
		end
	},
	{
		id = "process_pets",
		title = "⚙️ Process Your Pets",
		description = "Go to your tube and process some pets! Click on the tube to start processing. You need to process 20 pets.",
		targetType = "processing",
		targetCount = 20,
		pathTarget = function()
			local area = getPlayerArea()
			if area then
				local buttons = area:FindFirstChild("Buttons")
				if buttons then
					local sendHeaven = buttons:FindFirstChild("SendHeaven")
					if sendHeaven then
						local cyl = sendHeaven:FindFirstChild("Cylinder.007")
						if cyl then return cyl end
					end
				end
			end
			for i = 1, 10 do
				local tube = Workspace:FindFirstChild("Tube" .. i)
				if tube then return tube end
			end
			return Workspace:FindFirstChild("TubePlot1")
		end
	},
	{
		id = "unlock_next_door",
		title = "🚪 Unlock the Next Door",
		description = "Great progress! Now unlock Plot 2 to open the next door and access more pet spawning areas. This will cost 10 money.",
		targetType = "plot",
		targetId = 2,
		pathTarget = function()
			local area = getPlayerArea()
			if area then
				local plot = findInButtons(area, "Plot2")
				if plot then
					return plot:FindFirstChild("TouchPart") or plot:FindFirstChild("Cube.008") or plot:FindFirstChild("Position") or plot
				end
			end
			-- Fallback global (if single instance)
			local fallback = Workspace:FindFirstChild("Plot2")
			if fallback then
				return fallback:FindFirstChild("TouchPart") or fallback:FindFirstChild("Cube.008") or fallback:FindFirstChild("Position") or fallback
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
			local area = getPlayerArea()
			if area then
				local b1 = area:FindFirstChild("Boundary1")
				if b1 then return b1 end
			end
			if character and character:FindFirstChild("HumanoidRootPart") then
				return findNearestPetBall(character.HumanoidRootPart.Position)
			end
			return nil
		end
	},
	{
		id = "open_crazy_chest",
		title = "🎁 Open the Crazy Pet Chest",
		description = "Great job! Now try the Crazy Pet Chest for amazing rewards! Follow the path to the chest and click on it to open it.",
		targetType = "chest",
		pathTarget = function()
			local area = getPlayerArea()
			if not area then return nil end
			local env = area:FindFirstChild("Environmentals")
			if not env then return nil end
			local chest = env:FindFirstChild("Chest")
			if not chest then return nil end
			return chest:FindFirstChild("Container") or chest:FindFirstChildWhichIsA("BasePart", true)
		end
	},
	{
		id = "first_rebirth",
		title = "🌟 Perform Your First Rebirth",
		description = "You're ready to rebirth! This will reset your progress but give you permanent bonuses. Walk to the Rebirth button in your area or use the Rebirth UI button on screen.",
		targetType = "rebirth",
		targetCount = 1,
		pathTarget = function()
			local area = getPlayerArea()
			if not area then return nil end
			local btns = area:FindFirstChild("Buttons")
			if not btns then return nil end
			local reb = btns:FindFirstChild("RebirthButton")
			if not reb then return nil end
			return reb:FindFirstChild("Cube.009") or reb:FindFirstChildWhichIsA("BasePart")
		end
	},
	{
		id = "collect_100_pets",
		title = "🐾 Collect 100 Pets Total",
		description = "Now that you've rebirthed, collect 100 pets total. Your rebirth bonuses will help you collect pets faster!",
		targetType = "collection",
		targetCount = 100,
		pathTarget = function()
			local area = getPlayerArea()
			if area then
				local b1 = area:FindFirstChild("Boundary1")
				if b1 then return b1 end
			end
			if character and character:FindFirstChild("HumanoidRootPart") then
				return findNearestPetBall(character.HumanoidRootPart.Position)
			end
			return nil
		end
	},
	{
		id = "process_500_pets",
		title = "⚙️ Process 500 Pets Total",
		description = "Process 500 pets total through your tubes. This will give you lots of money and help you progress faster!",
		targetType = "processing",
		targetCount = 500,
		pathTarget = function()
			local area = getPlayerArea()
			if area then
				local buttons = area:FindFirstChild("Buttons")
				if buttons then
					local sendHeaven = buttons:FindFirstChild("SendHeaven")
					if sendHeaven then
						local cyl = sendHeaven:FindFirstChild("Cylinder.007")
						if cyl then return cyl end
					end
				end
			end
			for i = 1, 10 do
				local tube = Workspace:FindFirstChild("Tube" .. i)
				if tube then return tube end
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
			return nil -- GUI-driven
		end
	}
}

-- Tutorial state
local tutorialData = {
	active = false,
	currentStep = 1,
	completed = false,
	steps = TUTORIAL_STEPS,
	taskProgress = 0,
}

local isInitialized = false

-- ========= Path update =========

local function getCurrentTargetInstance(): Instance?
	local step = TUTORIAL_STEPS[tutorialData.currentStep]
	if not step or not step.pathTarget then return nil end
	local ok, target = pcall(step.pathTarget)
	if not ok then return nil end
	if target and target.Parent then return target end
	return nil
end

local function updatePathVisual()
	if not tutorialData.active or tutorialData.completed then return end

	local now = os.clock()
	if now - lastUpdateTime < UPDATE_THROTTLE then return end
	lastUpdateTime = now

	character = player.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	local target = getCurrentTargetInstance()
	if not target then return end

	-- Rebuild beam only when the target *instance* changes
	if currentTargetInstance ~= target then
		currentTargetInstance = target
		ensureBeam()
	end

	local targetPos = resolveTargetPosition(target)
	if not targetPos then return end

	local startPos = root.Position - Vector3.new(0, 3, 0)
	setBeamPositions(startPos, targetPos)

	-- Optional: distance-based progress for specific steps
	local currentStep = TUTORIAL_STEPS[tutorialData.currentStep]
	if currentStep then
		if currentStep.id == "open_crazy_chest"
			or currentStep.id == "unlock_first_plot"
			or currentStep.id == "unlock_first_tube"
			or currentStep.id == "unlock_next_door"
		then
			local distance = (targetPos - root.Position).Magnitude
			tutorialData.taskProgress = math.clamp(100 - distance, 0, 100)
		end
	end
end

-- ========= Persistence =========

local function saveTutorialProgress()
	local tutorialRemote = ReplicatedStorage:FindFirstChild("UpdateTutorialProgress")
	if tutorialRemote and tutorialRemote:IsA("RemoteEvent") then
		tutorialRemote:FireServer({
			currentStep = tutorialData.currentStep,
			active = tutorialData.active,
			completed = tutorialData.completed
		})
	end
end

local function loadTutorialProgress()
	local playerData = store:getState().player
	if playerData and playerData.TutorialProgress then
		local progress = playerData.TutorialProgress
		tutorialData.currentStep = progress.currentStep or 1
		tutorialData.active = progress.active or false
		tutorialData.completed = playerData.TutorialCompleted or false
		tutorialData.steps = TUTORIAL_STEPS
	end
end

-- ========= Public API =========

function TutorialService:StartTutorial()
	tutorialData.active = true
	tutorialData.completed = false
	tutorialData.steps = TUTORIAL_STEPS

	currentTargetInstance = nil
	clearPathVisual() -- clears connection too
	ensureBeam()

	-- Visual updates on RenderStepped for smoothness
	if visualUpdateConn then visualUpdateConn:Disconnect() end
	visualUpdateConn = RunService.RenderStepped:Connect(updatePathVisual)

	saveTutorialProgress()
end

function TutorialService:StopTutorial()
	tutorialData.active = false
	tutorialData.completed = true
	clearPathVisual()
	saveTutorialProgress()
end

function TutorialService:NextStep()
	if tutorialData.currentStep < #TUTORIAL_STEPS then
		tutorialData.currentStep += 1

		-- Reset visuals for new step
		currentTargetInstance = nil
		ensureBeam()
		updatePathVisual()

		task.spawn(saveTutorialProgress)
	else
		self:StopTutorial()
	end
end

function TutorialService:SetStep(stepNumber: number)
	if stepNumber >= 1 and stepNumber <= #TUTORIAL_STEPS then
		tutorialData.currentStep = stepNumber
		tutorialData.completed = false

		for _, step in ipairs(TUTORIAL_STEPS) do
			step.completed = false
		end

		currentTargetInstance = nil
		ensureBeam()
		updatePathVisual()
		saveTutorialProgress()
	end
end

function TutorialService:Reset()
	tutorialData.currentStep = 1
	tutorialData.completed = false
	tutorialData.active = true

	for _, step in ipairs(TUTORIAL_STEPS) do
		step.completed = false
	end

	currentTargetInstance = nil
	clearPathVisual()
	ensureBeam()
	saveTutorialProgress()
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

	local function pct(v) return tostring(math.floor(v)) .. "%" end

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

	elseif stepId == "unlock_first_plot" then
		local area = getPlayerArea()
		if area and character and character:FindFirstChild("HumanoidRootPart") then
			local p1 = findInButtons(area, "Plot1")
			local touch = p1 and p1:FindFirstChild("TouchPart")
			if touch then
				local d = (touch.Position - character.HumanoidRootPart.Position).Magnitude
				return pct(math.clamp(100 - d, 0, 100))
			end
		end
		return (playerData.OwnedPlots and #playerData.OwnedPlots > 0) and "100%" or "0%"

	elseif stepId == "unlock_first_tube" then
		local area = getPlayerArea()
		if area and character and character:FindFirstChild("HumanoidRootPart") then
			local t1 = findInButtons(area, "TubePlot1")
			local touch = t1 and t1:FindFirstChild("TouchPart")
			if touch then
				local d = (touch.Position - character.HumanoidRootPart.Position).Magnitude
				return pct(math.clamp(100 - d, 0, 100))
			end
		end
		return (playerData.OwnedTubes and #playerData.OwnedTubes > 0) and "100%" or "0%"

	elseif stepId == "unlock_next_door" then
		if playerData.OwnedPlots then
			for _, n in ipairs(playerData.OwnedPlots) do
				if n == 2 then return "100%" end
			end
		end
		local area = getPlayerArea()
		if area and character and character:FindFirstChild("HumanoidRootPart") then
			local p2 = findInButtons(area, "Plot2")
			local touch = p2 and p2:FindFirstChild("TouchPart")
			if touch then
				local d = (touch.Position - character.HumanoidRootPart.Position).Magnitude
				return pct(math.clamp(100 - d, 0, 100))
			end
		end
		return "0%"

	elseif stepId == "get_rare_pet" then
		if playerData.Pets then
			local PetConstants = require(ReplicatedStorage.constants.PetConstants)
			for _, pet in ipairs(playerData.Pets) do
				if pet.Rarity and pet.Variation then
					local variationName = type(pet.Variation) == "table" and pet.Variation.VariationName or pet.Variation
					local combinedOdds = PetConstants.getCombinedRarityChance(pet.Rarity, variationName)
					if combinedOdds and combinedOdds > 250 then
						return "100%"
					end
				end
			end
		end
		return "0%"

	elseif stepId == "open_crazy_chest" then
		local area = getPlayerArea()
		if area and character and character:FindFirstChild("HumanoidRootPart") then
			local env = area:FindFirstChild("Environmentals")
			local chest = env and env:FindFirstChild("Chest")
			local container = chest and chest:FindFirstChild("Container")
			if container then
				local d = (container.Position - character.HumanoidRootPart.Position).Magnitude
				return pct(math.clamp(100 - d, 0, 100))
			end
		end
		return "0%"

	elseif stepId == "first_rebirth" then
		return (playerData.Resources and playerData.Resources.Rebirths >= 1) and "100%" or "0%"

	elseif stepId == "unlock_pet_mixer" then
		local current = playerData.Resources and playerData.Resources.Rebirths or 0
		return pct(math.min(100, (current / 3) * 100))
	end

	return "0%"
end

function TutorialService:IsActive()
	return tutorialData.active
end

function TutorialService:GetCurrentStep()
	return TUTORIAL_STEPS[tutorialData.currentStep]
end

function TutorialService:CompleteStep(stepId: string)
	if not tutorialData.active or tutorialData.completed then return end
	local currentStep = TUTORIAL_STEPS[tutorialData.currentStep]
	if currentStep and currentStep.id == stepId and not currentStep.completed then
		currentStep.completed = true
		task.spawn(function()
			task.wait(0.5)
			if tutorialData.active and not tutorialData.completed then
				self:NextStep()
			end
		end)
	end
end

-- ========= Progress checking =========

local function calculateTaskProgress(step, playerData)
	if not step or not playerData then return 0 end
	local stepId = step.id

	local function distTo(part: BasePart?): number
		if not part or not character or not character:FindFirstChild("HumanoidRootPart") then return 0 end
		return (part.Position - character.HumanoidRootPart.Position).Magnitude
	end

	if stepId == "unlock_first_plot" then
		local area = getPlayerArea()
		local p1 = findInButtons(area, "Plot1")
		local touch = p1 and p1:FindFirstChild("TouchPart")
		if touch then return math.clamp(100 - distTo(touch), 0, 100) end
		return (playerData.OwnedPlots and #playerData.OwnedPlots > 0) and 100 or 0

	elseif stepId == "unlock_first_tube" then
		local area = getPlayerArea()
		local t1 = findInButtons(area, "TubePlot1")
		local touch = t1 and t1:FindFirstChild("TouchPart")
		if touch then return math.clamp(100 - distTo(touch), 0, 100) end
		return (playerData.OwnedTubes and #playerData.OwnedTubes > 0) and 100 or 0

	elseif stepId == "collect_10_pets" then
		local current = playerData.Pets and #playerData.Pets or 0
		return math.min(100, (current / 10) * 100)

	elseif stepId == "process_pets" then
		local current = playerData.ProcessedPets or 0
		return math.min(100, (current / 20) * 100)

	elseif stepId == "unlock_next_door" then
		if playerData.OwnedPlots then
			for _, n in ipairs(playerData.OwnedPlots) do
				if n == 2 then return 100 end
			end
		end
		local area = getPlayerArea()
		local p2 = findInButtons(area, "Plot2")
		local touch = p2 and p2:FindFirstChild("TouchPart")
		if touch then return math.clamp(100 - distTo(touch), 0, 100) end
		return 0

	elseif stepId == "get_rare_pet" then
		if playerData.Pets then
			local PetConstants = require(ReplicatedStorage.constants.PetConstants)
			for _, pet in ipairs(playerData.Pets) do
				if pet.Rarity and pet.Variation then
					local variationName = type(pet.Variation) == "table" and pet.Variation.VariationName or pet.Variation
					local combinedOdds = PetConstants.getCombinedRarityChance(pet.Rarity, variationName)
					if combinedOdds and combinedOdds > 250 then
						return 100
					end
				end
			end
		end
		return 0

	elseif stepId == "open_crazy_chest" then
		local area = getPlayerArea()
		local env = area and area:FindFirstChild("Environmentals") or nil
		local chest = env and env:FindFirstChild("Chest") or nil
		local container = chest and chest:FindFirstChild("Container") or nil
		if container then
			return math.clamp(100 - distTo(container), 0, 100)
		end
		return 0

	elseif stepId == "first_rebirth" then
		return (playerData.Resources and playerData.Resources.Rebirths >= 1) and 100 or 0

	elseif stepId == "collect_100_pets" then
		local current = playerData.Pets and #playerData.Pets or 0
		return math.min(100, (current / 100) * 100)

	elseif stepId == "process_500_pets" then
		local current = playerData.ProcessedPets or 0
		return math.min(100, (current / 500) * 100)

	elseif stepId == "unlock_pet_mixer" then
		local current = playerData.Resources and playerData.Resources.Rebirths or 0
		return math.min(100, (current / 3) * 100)
	end

	return 0
end

function TutorialService:CheckStepCompletion(playerData)
	if not tutorialData.active or tutorialData.completed then return end

	local currentStep = TUTORIAL_STEPS[tutorialData.currentStep]
	if not currentStep or currentStep.completed then return end
	if not playerData then return end

	local taskProgress = calculateTaskProgress(currentStep, playerData)
	tutorialData.taskProgress = taskProgress

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
		if playerData.OwnedPlots then
			for _, n in ipairs(playerData.OwnedPlots) do
				if n == 2 then stepCompleted = true break end
			end
		end

	elseif stepId == "get_rare_pet" then
		if playerData.Pets then
			local PetConstants = require(ReplicatedStorage.constants.PetConstants)
			for _, pet in ipairs(playerData.Pets) do
				if pet.Rarity and pet.Variation then
					local variationName = type(pet.Variation) == "table" and pet.Variation.VariationName or pet.Variation
					local combinedOdds = PetConstants.getCombinedRarityChance(pet.Rarity, variationName)
					if combinedOdds and combinedOdds > 250 then
						stepCompleted = true
						break
					end
				end
			end
		end

	elseif stepId == "open_crazy_chest" then
		-- Hook this up to your chest interaction event; for now remains false until triggered elsewhere.
		stepCompleted = false

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
		currentStep.completed = true
		task.spawn(function()
			task.wait(0.5)
			if tutorialData.active and not tutorialData.completed then
				self:NextStep()
			end
		end)
	end
end

-- ========= Init / Cleanup =========

function TutorialService:Initialize()
	if isInitialized then return end
	isInitialized = true

	local unsubscribe = store.changed:connect(function(newState, _old)
		if newState.player then
			loadTutorialProgress()
			self:CheckStepCompletion(newState.player)
		end
	end)
	connections.dataSubscription = unsubscribe

	player.CharacterAdded:Connect(function(newCharacter)
		character = newCharacter
		task.wait(1)
		currentTargetInstance = nil
		ensureBeam()
		updatePathVisual()
	end)

	task.spawn(function()
		local playerData = store:getState().player
		local attempts = 0
		while not playerData and attempts < 20 do
			task.wait(0.1)
			playerData = store:getState().player
			attempts += 1
		end

		loadTutorialProgress()

		if playerData then
			local shouldShowTutorial = not playerData.TutorialCompleted
			if shouldShowTutorial then
				local isNewPlayer = not playerData.OwnedPlots or #playerData.OwnedPlots == 0
				if isNewPlayer and not tutorialData.active then
					self:StartTutorial()
				elseif tutorialData.active then
					tutorialData.steps = TUTORIAL_STEPS
					if visualUpdateConn then visualUpdateConn:Disconnect() end
					ensureBeam()
					visualUpdateConn = RunService.RenderStepped:Connect(updatePathVisual)
				end
			end
		end
	end)
end

function TutorialService:Cleanup()
	tutorialData.active = false
	if visualUpdateConn then
		visualUpdateConn:Disconnect()
		visualUpdateConn = nil
	end
	for name, connection in pairs(connections) do
		if typeof(connection) == "RBXScriptConnection" then
			connection:Disconnect()
		elseif typeof(connection) == "function" then
			connection()
		end
		connections[name] = nil
	end
	clearPathVisual()
end

return TutorialService
