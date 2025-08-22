-- PhysicalLeaderboardService - Manages physical leaderboard GUI surfaces in workspace (improved)
-- Notes:
-- - Uses userId consistently (matches server)
-- - Roblox-native thumbnails (rbxthumb) with a tiny cache
-- - Safer InvokeServer with pcall + a quick retry
-- - Per-board refresh cooldown + checksum to avoid unnecessary repaints
-- - Empty-state message when no data
-- - Keeps names/labels/period strings exactly the same to avoid UI breakage

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local DataSyncService = require(script.Parent.Parent.services.DataSyncService)

local PhysicalLeaderboardService = {}
PhysicalLeaderboardService.__index = PhysicalLeaderboardService

local player = Players.LocalPlayer

-- Configuration
local LEADERBOARD_CONFIGS = {
	{
		name = "LeftLeaderboard",
		type = "Diamonds",
		pathParts = {"Center", "TycoonMap", "Leaderboards", "LeftLeaderboard"},
		partName = "Cube.047",
		titlePartName = "Cube.048",
	},
	{
		name = "MiddleLeaderboard",
		type = "Money",
		pathParts = {"Center", "TycoonMap", "Leaderboards", "MiddleLeaderboard"},
		partName = "Cube.047",
		titlePartName = "Cube.048",
	},
	{
		name = "RightLeaderboard",
		type = "Rebirths",
		pathParts = {"Center", "TycoonMap", "Leaderboards", "RightLeaderboard"},
		partName = "Cube.047",
		titlePartName = "Cube.048",
	},
}

-- Refresh cadence (client → server). Keep it gentle; server already caches.
local REFRESH_SECONDS = 30
local TAB_SWITCH_MIN_INTERVAL = 1.5 -- don't spam server when flipping tabs fast

-- Thumbnail cache (very small, avoids repeated web hits)
local ThumbCache: {[number]: string} = {}

local function getPlayerHeadshot(userId: number): string
	if ThumbCache[userId] then
		return ThumbCache[userId]
	end
	local ok, content = pcall(function()
		return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
	end)
	if ok and content then
		ThumbCache[userId] = content
		return content
	end
	-- Fallback to rbxthumb URL
	local url = ("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(userId)
	ThumbCache[userId] = url
	return url
end

-- Helper: current player's live value for a leaderboard type
local function getCurrentPlayerValue(leaderboardType: string): number
	local playerData = DataSyncService:GetPlayerData()
	if not playerData or not playerData.Resources then
		return 0
	end
	if leaderboardType == "Money" then
		return playerData.Resources.Money or 0
	elseif leaderboardType == "Diamonds" then
		return playerData.Resources.Diamonds or 0
	elseif leaderboardType == "Rebirths" then
		return playerData.Resources.Rebirths or 0
	end
	return 0
end

-- Insert local player's live row into a server list (keeps rank logic consistent)
local function insertLivePlayerData(serverLeaderboardData: {{rank: number?, userId: number, playerName: string, value: number}}, selectedType: string)
	if not serverLeaderboardData then return {} end

	local currentUserId = player.UserId
	local currentValue = getCurrentPlayerValue(selectedType)

	-- Copy (don’t mutate server data)
	local live = table.clone(serverLeaderboardData)

	-- Normalise rank fallback
	for i, e in ipairs(live) do
		if e.rank == nil then
			e.rank = i
		end
		-- ensure numeric
		if e.value ~= nil then
			e.value = tonumber(e.value) or 0
		end
	end

	-- Remove any existing row for me
	for i = #live, 1, -1 do
		if live[i].userId == currentUserId then
			table.remove(live, i)
			break
		end
	end

	-- Insert my live row by value desc
	local myRow = {
		rank = 0,
		userId = currentUserId,
		playerName = player.Name,
		value = currentValue,
		isLiveUpdate = true,
	}
	local inserted = false
	for i, e in ipairs(live) do
		if currentValue > (e.value or 0) then
			table.insert(live, i, myRow)
			inserted = true
			break
		end
	end
	if not inserted then
		table.insert(live, myRow)
	end

	-- Re-rank
	for i, e in ipairs(live) do
		e.rank = i
	end

	return live
end

-- Icons
local function getTypeIcon(leaderboardType: string): string
	if leaderboardType == "Money" then
		return IconAssets.getIcon("CURRENCY", "MONEY")
	elseif leaderboardType == "Diamonds" then
		return IconAssets.getIcon("CURRENCY", "DIAMONDS")
	elseif leaderboardType == "Rebirths" then
		return IconAssets.getIcon("UI", "REBIRTH")
	end
	return ""
end

-- Value formatting
local function formatValue(value: number, leaderboardType: string): string
	if leaderboardType == "Rebirths" then
		return tostring(value or 0)
	else
		return NumberFormatter.format(value or 0)
	end
end

-- Simple checksum to detect data changes and avoid repainting
local function checksum(entries: {{rank: number?, userId: number, playerName: string, value: number}}): string
	local parts = table.create(math.min(#entries, 25))
	for i = 1, math.min(#entries, 25) do
		local e = entries[i]
		parts[i] = string.format("%d:%d:%s:%s", i, e.userId or 0, tostring(e.playerName or ""), tostring(e.value or 0))
	end
	return table.concat(parts, "|")
end

-- Title GUI
function PhysicalLeaderboardService:CreateTitleGUI(surfacePart: BasePart?, leaderboardType: string)
	if not surfacePart then
		warn("PhysicalLeaderboardService: Title surface part not found")
		return nil
	end

	local existing = surfacePart:FindFirstChild("LeaderboardTitleGUI_" .. leaderboardType)
	if existing and existing:IsA("SurfaceGui") then
		existing:Destroy()
	end

	local sg = Instance.new("SurfaceGui")
	sg.Name = "LeaderboardTitleGUI_" .. leaderboardType
	sg.Face = Enum.NormalId.Back
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 50
	sg.ResetOnSpawn = false
	sg.LightInfluence = 0
	sg.AlwaysOnTop = true
	sg.Parent = surfacePart

	local main = Instance.new("Frame")
	main.Name = "MainFrame"
	main.Size = UDim2.new(1, 0, 1, 0)
	main.BackgroundTransparency = 1
	main.BorderSizePixel = 0
	main.Parent = sg

	local typeColor, typeIcon
	if leaderboardType == "Money" then
		typeColor = Color3.fromRGB(0, 255, 0)
		typeIcon = IconAssets.getIcon("CURRENCY", "MONEY")
	elseif leaderboardType == "Diamonds" then
		typeColor = Color3.fromRGB(0, 150, 255)
		typeIcon = IconAssets.getIcon("CURRENCY", "DIAMONDS")
	elseif leaderboardType == "Rebirths" then
		typeColor = Color3.fromRGB(255, 50, 50)
		typeIcon = IconAssets.getIcon("UI", "REBIRTH")
	else
		typeColor = Color3.fromRGB(255, 215, 0)
		typeIcon = ""
	end

	local icon = Instance.new("ImageLabel")
	icon.Name = "IconLabel"
	icon.Size = UDim2.new(0, 80, 0, 80)
	icon.Position = UDim2.new(0, 20, 0.5, -40)
	icon.BackgroundTransparency = 1
	icon.Image = typeIcon
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Parent = main

	local title = Instance.new("TextLabel")
	title.Name = "TitleLabel"
	title.Size = UDim2.new(1, -120, 1, 0)
	title.Position = UDim2.new(0, 110, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = leaderboardType:upper() .. " LEADERBOARD"
	title.TextColor3 = typeColor
	title.TextSize = 48
	title.Font = Enum.Font.FredokaOne
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextYAlignment = Enum.TextYAlignment.Center
	title.TextStrokeTransparency = 0
	title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	title.TextScaled = true
	title.Parent = main

	return sg
end

-- Leaderboard GUI
function PhysicalLeaderboardService:CreateLeaderboardGUI(surfacePart: BasePart?, leaderboardType: string)
	if not surfacePart then
		warn("PhysicalLeaderboardService: Surface part not found")
		return nil
	end

	local existing = surfacePart:FindFirstChild("LeaderboardGUI_" .. leaderboardType)
	if existing and existing:IsA("SurfaceGui") then
		existing:Destroy()
	end

	local sg = Instance.new("SurfaceGui")
	sg.Name = "LeaderboardGUI_" .. leaderboardType
	sg.Face = Enum.NormalId.Back
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 50
	sg.ResetOnSpawn = false
	sg.LightInfluence = 0
	sg.AlwaysOnTop = true
	sg.Parent = surfacePart

	local main = Instance.new("Frame")
	main.Name = "MainFrame"
	main.Size = UDim2.new(1, 0, 1, 0)
	main.BackgroundTransparency = 1
	main.BorderSizePixel = 0
	main.Parent = sg

	local tabContainer = Instance.new("Frame")
	tabContainer.Name = "TabContainer"
	tabContainer.Size = UDim2.new(0, 400, 0, 60)
	tabContainer.Position = UDim2.new(0.5, -200, 0, 10)
	tabContainer.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	tabContainer.BorderSizePixel = 0
	tabContainer.Parent = main

	local tabCorner = Instance.new("UICorner")
	tabCorner.CornerRadius = UDim.new(0, 50)
	tabCorner.Parent = tabContainer

	local allTimeTab = Instance.new("TextButton")
	allTimeTab.Name = "AllTimeTab"
	allTimeTab.Size = UDim2.new(0.5, -4, 1, -8)
	allTimeTab.Position = UDim2.new(0, 4, 0, 4)
	allTimeTab.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
	allTimeTab.BorderSizePixel = 0
	allTimeTab.Text = "All-Time"
	allTimeTab.TextColor3 = Color3.fromRGB(255, 255, 255)
	allTimeTab.TextSize = 28
	allTimeTab.Font = Enum.Font.Gotham
	allTimeTab.TextScaled = true
	allTimeTab.Parent = tabContainer

	local allTimeCorner = Instance.new("UICorner")
	allTimeCorner.CornerRadius = UDim.new(0, 45)
	allTimeCorner.Parent = allTimeTab

	local weeklyTab = Instance.new("TextButton")
	weeklyTab.Name = "WeeklyTab"
	weeklyTab.Size = UDim2.new(0.5, -4, 1, -8)
	weeklyTab.Position = UDim2.new(0.5, 0, 0, 4)
	weeklyTab.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	weeklyTab.BorderSizePixel = 0
	weeklyTab.Text = "Weekly"
	weeklyTab.TextColor3 = Color3.fromRGB(0, 0, 0)
	weeklyTab.TextSize = 28
	weeklyTab.Font = Enum.Font.Gotham
	weeklyTab.TextScaled = true
	weeklyTab.Parent = tabContainer

	local weeklyCorner = Instance.new("UICorner")
	weeklyCorner.CornerRadius = UDim.new(0, 45)
	weeklyCorner.Parent = weeklyTab

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ContentArea"
	scrollFrame.Size = UDim2.new(1, -20, 1, -90)
	scrollFrame.Position = UDim2.new(0, 10, 0, 80)
	scrollFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	scrollFrame.BackgroundTransparency = 0.2
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	scrollFrame.ScrollBarThickness = 12
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.Parent = main

	local scrollCorner = Instance.new("UICorner")
	scrollCorner.CornerRadius = UDim.new(0, 30)
	scrollCorner.Parent = scrollFrame

	local emptyLabel = Instance.new("TextLabel")
	emptyLabel.Name = "EmptyState"
	emptyLabel.Size = UDim2.new(1, 0, 1, -90)
	emptyLabel.Position = UDim2.new(0, 0, 0, 80)
	emptyLabel.BackgroundTransparency = 1
	emptyLabel.Text = "No entries yet."
	emptyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	emptyLabel.TextSize = 32
	emptyLabel.Font = Enum.Font.FredokaOne
	emptyLabel.TextXAlignment = Enum.TextXAlignment.Center
	emptyLabel.TextYAlignment = Enum.TextYAlignment.Center
	emptyLabel.Visible = false
	emptyLabel.Parent = main

	local guiManager = {
		surfaceGui = sg,
		scrollFrame = scrollFrame,
		allTimeTab = allTimeTab,
		weeklyTab = weeklyTab,
		leaderboardType = leaderboardType,
		currentPeriod = "All-Time",
		_lastFetchT = 0,
		_lastChecksum = nil,
		_emptyLabel = emptyLabel,
	}

	local function setActive(tabBtn: TextButton, active: boolean)
		if active then
			tabBtn.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
			tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			tabBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
			tabBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
		end
	end

	allTimeTab.Activated:Connect(function()
		if os.clock() - guiManager._lastFetchT < TAB_SWITCH_MIN_INTERVAL then return end
		guiManager.currentPeriod = "All-Time"
		setActive(allTimeTab, true)
		setActive(weeklyTab, false)
		PhysicalLeaderboardService:UpdateLeaderboardData(guiManager, true)
	end)

	weeklyTab.Activated:Connect(function()
		if os.clock() - guiManager._lastFetchT < TAB_SWITCH_MIN_INTERVAL then return end
		guiManager.currentPeriod = "Weekly"
		setActive(weeklyTab, true)
		setActive(allTimeTab, false)
		PhysicalLeaderboardService:UpdateLeaderboardData(guiManager, true)
	end)

	return guiManager
end

-- Fetch + populate
function PhysicalLeaderboardService:UpdateLeaderboardData(guiManager, forceNow: boolean?)
	if not guiManager then return end
	if not guiManager.scrollFrame then return end

	local now = os.clock()
	if not forceNow and (now - guiManager._lastFetchT < REFRESH_SECONDS) then
		return
	end
	guiManager._lastFetchT = now

	local remote = ReplicatedStorage:FindFirstChild("GetLeaderboardData")
	if not remote or not remote.IsA or not remote:IsA("RemoteFunction") then
		warn("PhysicalLeaderboardService: GetLeaderboardData RemoteFunction not found")
		return
	end

	task.spawn(function()
		local ok, data = pcall(function()
			return remote:InvokeServer(guiManager.currentPeriod, guiManager.leaderboardType)
		end)
		if not ok or not data then
			-- quick retry once
			task.wait(0.25)
			ok, data = pcall(function()
				return remote:InvokeServer(guiManager.currentPeriod, guiManager.leaderboardType)
			end)
		end

		if ok and data then
			-- Expecting entries: { rank, userId, playerName, value }
			local liveData = insertLivePlayerData(data, guiManager.leaderboardType)

			-- Empty state toggle
			local hasAny = #liveData > 0
			if guiManager._emptyLabel then
				guiManager._emptyLabel.Visible = not hasAny
			end

			-- Checksum to avoid unnecessary rebuilds
			local sig = checksum(liveData)
			if sig ~= guiManager._lastChecksum then
				guiManager._lastChecksum = sig
				self:PopulateLeaderboardEntries(guiManager, liveData)
			end
		else
			warn("PhysicalLeaderboardService: Failed to fetch leaderboard data")
		end
	end)
end

-- Build rows
function PhysicalLeaderboardService:PopulateLeaderboardEntries(guiManager, leaderboardData)
	if not guiManager or not guiManager.scrollFrame then return end

	-- Clear old entries (keep other non-entry children)
	for _, child in ipairs(guiManager.scrollFrame:GetChildren()) do
		if child:IsA("Frame") and (child.Name:match("^Entry_") or child.Name == "Separator") then
			child:Destroy()
		end
	end

	-- Find current player in list (using userId)
	local myEntry, myRank
	for i, entry in ipairs(leaderboardData) do
		if entry.userId == player.UserId then
			myEntry, myRank = entry, i
			break
		end
	end

	-- Top 19 + me (if not already top 19)
	local display = {}
	local maxTop = 19
	for i = 1, math.min(#leaderboardData, maxTop) do
		table.insert(display, leaderboardData[i])
	end
	if myEntry and myRank and myRank > maxTop then
		table.insert(display, myEntry)
	end

	local entryHeight = 80
	local entrySpacing = 8
	local y = 0

	for idx, entry in ipairs(display) do
		local isMe = entry.userId == player.UserId
		local isTailMe = (idx == #display and myEntry and myRank and myRank > maxTop)

		if isTailMe then
			local sep = Instance.new("Frame")
			sep.Name = "Separator"
			sep.Size = UDim2.new(1, -16, 0, 2)
			sep.Position = UDim2.new(0, 8, 0, y)
			sep.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
			sep.BorderSizePixel = 0
			sep.Parent = guiManager.scrollFrame
			y += 10
		end

		local frame = Instance.new("Frame")
		frame.Name = ("Entry_%d"):format(idx)
		frame.Size = UDim2.new(1, -16, 0, entryHeight)
		frame.Position = UDim2.new(0, 8, 0, y + 5)
		frame.BackgroundColor3 =
			(entry.rank == 1 and Color3.fromRGB(255, 215, 0)) or
			(entry.rank == 2 and Color3.fromRGB(192, 192, 192)) or
			(entry.rank == 3 and Color3.fromRGB(205, 127, 50)) or
			(isMe and Color3.fromRGB(100, 150, 255)) or
			Color3.fromRGB(255, 255, 255)
		frame.BackgroundTransparency =
			(entry.rank and entry.rank <= 3 and 0.2) or
			(isMe and 0.3) or
			0.8
		frame.BorderSizePixel = 0
		frame.Parent = guiManager.scrollFrame

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 30)
		corner.Parent = frame

		local rankLbl = Instance.new("TextLabel")
		rankLbl.Name = "RankLabel"
		rankLbl.Size = UDim2.new(0, 60, 1, 0)
		rankLbl.Position = UDim2.new(0, 8, 0, 0)
		rankLbl.BackgroundTransparency = 1
		rankLbl.Text = "#" .. tostring(entry.rank or idx)
		rankLbl.TextColor3 = (entry.rank and entry.rank <= 3) and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 255, 255)
		rankLbl.TextSize = 24
		rankLbl.Font = Enum.Font.FredokaOne
		rankLbl.TextXAlignment = Enum.TextXAlignment.Center
		rankLbl.TextYAlignment = Enum.TextYAlignment.Center
		rankLbl.TextStrokeTransparency = 0
		rankLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		rankLbl.TextScaled = true
		rankLbl.Parent = frame

		local faceFrame = Instance.new("Frame")
		faceFrame.Name = "FaceFrame"
		faceFrame.Size = UDim2.new(0, 60, 0, 60)
		faceFrame.Position = UDim2.new(0, 100, 0.5, -30)
		faceFrame.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
		faceFrame.BorderSizePixel = 0
		faceFrame.Parent = frame

		local faceCorner = Instance.new("UICorner")
		faceCorner.CornerRadius = UDim.new(0.5, 0)
		faceCorner.Parent = faceFrame

		local faceImage = Instance.new("ImageLabel")
		faceImage.Size = UDim2.new(1, 0, 1, 0)
		faceImage.BackgroundTransparency = 1
		faceImage.Image = getPlayerHeadshot(entry.userId)
		faceImage.ScaleType = Enum.ScaleType.Crop
		faceImage.Parent = faceFrame

		local faceImageCorner = Instance.new("UICorner")
		faceImageCorner.CornerRadius = UDim.new(0.5, 0)
		faceImageCorner.Parent = faceImage

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Name = "NameLabel"
		nameLbl.Size = UDim2.new(0, 150, 1, 0)
		nameLbl.Position = UDim2.new(0, 175, 0, 0)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Text = entry.playerName or "Player"
		nameLbl.TextColor3 = isMe and Color3.fromRGB(255, 255, 100) or Color3.fromRGB(255, 255, 255)
		nameLbl.TextSize = 24
		nameLbl.Font = Enum.Font.FredokaOne
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.TextYAlignment = Enum.TextYAlignment.Center
		nameLbl.TextStrokeTransparency = 0
		nameLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		nameLbl.TextScaled = true
		nameLbl.TextWrapped = true
		nameLbl.Parent = frame

		local valueFrame = Instance.new("Frame")
		valueFrame.Name = "ValueFrame"
		valueFrame.Size = UDim2.new(0, 140, 1, 0)
		valueFrame.Position = UDim2.new(1, -150, 0, 0)
		valueFrame.BackgroundTransparency = 1
		valueFrame.Parent = frame

		local valueLayout = Instance.new("UIListLayout")
		valueLayout.FillDirection = Enum.FillDirection.Horizontal
		valueLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		valueLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		valueLayout.SortOrder = Enum.SortOrder.LayoutOrder
		valueLayout.Padding = UDim.new(0, 1)
		valueLayout.Parent = valueFrame

		local valueLbl = Instance.new("TextLabel")
		valueLbl.Name = "ValueLabel"
		valueLbl.Size = UDim2.new(0, 110, 0, 40)
		valueLbl.BackgroundTransparency = 1
		valueLbl.Text = formatValue(entry.value, guiManager.leaderboardType)
		valueLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		valueLbl.TextSize = 24
		valueLbl.Font = Enum.Font.FredokaOne
		valueLbl.TextXAlignment = Enum.TextXAlignment.Right
		valueLbl.TextYAlignment = Enum.TextYAlignment.Center
		valueLbl.TextStrokeTransparency = 0
		valueLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		valueLbl.TextScaled = true
		valueLbl.LayoutOrder = 1
		valueLbl.Parent = valueFrame

		local valueIcon = Instance.new("ImageLabel")
		valueIcon.Name = "ValueIcon"
		valueIcon.Size = UDim2.new(0, 30, 0, 30)
		valueIcon.BackgroundTransparency = 1
		valueIcon.Image = getTypeIcon(guiManager.leaderboardType)
		valueIcon.ScaleType = Enum.ScaleType.Fit
		valueIcon.LayoutOrder = 2
		valueIcon.Parent = valueFrame

		y += (entryHeight + entrySpacing)
	end

	guiManager.scrollFrame.CanvasSize = UDim2.new(0, 0, 0, y + 10)
end

-- Initialize all physical leaderboards
function PhysicalLeaderboardService:Initialize()
	-- Initialize asynchronously to avoid blocking loading screen
	task.spawn(function()
		-- small delay for world to be ready (moved to async)
		task.wait(2)

	local managers = {}

	for _, config in ipairs(LEADERBOARD_CONFIGS) do
		-- walk the path
		local model: Instance = workspace
		for _, seg in ipairs(config.pathParts) do
			local nextModel = (model and model:FindFirstChild(seg)) or nil
			if not nextModel then
				warn("PhysicalLeaderboardService: Missing path segment", seg, "for", config.name)
				model = nil
				break
			end
			model = nextModel
		end

		if model then
			local boardPart = model:FindFirstChild(config.partName)
			local titlePart = model:FindFirstChild(config.titlePartName)

			if boardPart and titlePart and boardPart:IsA("BasePart") and titlePart:IsA("BasePart") then
				local okTitle = pcall(function()
					self:CreateTitleGUI(titlePart :: BasePart, config.type)
				end)
				if not okTitle then
					warn("PhysicalLeaderboardService: Failed to create title for", config.name)
				end

				local ok, guiManager = pcall(function()
					return self:CreateLeaderboardGUI(boardPart :: BasePart, config.type)
				end)
				if ok and guiManager then
					managers[config.name] = guiManager
					self:UpdateLeaderboardData(guiManager, true)
				else
					warn("PhysicalLeaderboardService: Failed to create leaderboard GUI for", config.name)
				end
			else
				if not boardPart then
					warn("PhysicalLeaderboardService: Part not found:", config.partName, "in", config.name)
				end
				if not titlePart then
					warn("PhysicalLeaderboardService: Title part not found:", config.titlePartName, "in", config.name)
				end
			end
		end
	end

	-- periodic refresh (lightweight; server already caches)
	task.spawn(function()
		while true do
			task.wait(REFRESH_SECONDS)
			for _, manager in pairs(managers) do
				self:UpdateLeaderboardData(manager)
			end
		end
	end)
	end) -- Close task.spawn
end

function PhysicalLeaderboardService:Cleanup()
	-- SurfaceGuis parented to parts will GC when parts or service are cleaned up
end

return PhysicalLeaderboardService
