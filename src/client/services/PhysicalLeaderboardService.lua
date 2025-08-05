-- PhysicalLeaderboardService - Manages physical leaderboard GUI surfaces in workspace
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

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
        titlePartName = "Cube.048"
    },
    {
        name = "MiddleLeaderboard", 
        type = "Money",
        pathParts = {"Center", "TycoonMap", "Leaderboards", "MiddleLeaderboard"},
        partName = "Cube.047",
        titlePartName = "Cube.048"
    },
    {
        name = "RightLeaderboard",
        type = "Rebirths", 
        pathParts = {"Center", "TycoonMap", "Leaderboards", "RightLeaderboard"},
        partName = "Cube.047",
        titlePartName = "Cube.048"
    }
}

-- Helper function to get player headshot
local function getPlayerHeadshot(playerId)
    return "https://www.roblox.com/headshot-thumbnail/image?userId=" .. playerId .. "&width=150&height=150&format=png"
end

-- Helper function to get current player's live value for a leaderboard type
local function getCurrentPlayerValue(leaderboardType)
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

-- Helper function to insert current player's live data into leaderboard for accurate positioning
local function insertLivePlayerData(serverLeaderboardData, selectedType)
    if not serverLeaderboardData then return {} end
    
    local currentPlayerValue = getCurrentPlayerValue(selectedType)
    local currentPlayerId = player.UserId
    
    -- Create a copy of the server data
    local liveLeaderboard = {}
    for i, entry in ipairs(serverLeaderboardData) do
        table.insert(liveLeaderboard, {
            rank = entry.rank,
            playerId = entry.playerId,
            playerName = entry.playerName,
            value = entry.value,
            isLiveUpdate = false
        })
    end
    
    -- Remove existing entry for current player (if any)
    for i = #liveLeaderboard, 1, -1 do
        if liveLeaderboard[i].playerId == currentPlayerId then
            table.remove(liveLeaderboard, i)
            break
        end
    end
    
    -- Insert current player with live data in correct position
    local currentPlayerEntry = {
        rank = 0, -- Will be set below
        playerId = currentPlayerId,
        playerName = player.Name,
        value = currentPlayerValue,
        isLiveUpdate = true -- Mark as live data
    }
    
    -- Find correct position based on value
    local inserted = false
    for i, entry in ipairs(liveLeaderboard) do
        if currentPlayerValue > entry.value then
            table.insert(liveLeaderboard, i, currentPlayerEntry)
            inserted = true
            break
        end
    end
    
    -- If not inserted, add to end
    if not inserted then
        table.insert(liveLeaderboard, currentPlayerEntry)
    end
    
    -- Update ranks
    for i, entry in ipairs(liveLeaderboard) do
        entry.rank = i
    end
    
    return liveLeaderboard
end

-- Helper function to get icon for leaderboard type
local function getTypeIcon(leaderboardType)
    if leaderboardType == "Money" then
        return IconAssets.getIcon("CURRENCY", "MONEY")
    elseif leaderboardType == "Diamonds" then
        return IconAssets.getIcon("CURRENCY", "DIAMONDS")
    elseif leaderboardType == "Rebirths" then
        return IconAssets.getIcon("UI", "REBIRTH")
    end
    return ""
end

-- Helper function to format value based on type
local function formatValue(value, leaderboardType)
    if leaderboardType == "Rebirths" then
        return tostring(value)
    else
        return NumberFormatter.format(value)
    end
end

-- Create title GUI for a specific surface
function PhysicalLeaderboardService:CreateTitleGUI(surfacePart, leaderboardType)
    if not surfacePart then
        warn("PhysicalLeaderboardService: Title surface part not found")
        return nil
    end


    -- Create SurfaceGui for title with better positioning
    local titleSurfaceGui = Instance.new("SurfaceGui")
    titleSurfaceGui.Name = "LeaderboardTitleGUI_" .. leaderboardType
    titleSurfaceGui.Face = Enum.NormalId.Back
    titleSurfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    titleSurfaceGui.PixelsPerStud = 50
    titleSurfaceGui.ResetOnSpawn = false
    titleSurfaceGui.LightInfluence = 0 -- Reduce lighting effects
    titleSurfaceGui.Parent = surfacePart
    
    -- Main container for title
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = titleSurfaceGui

    -- Get type-specific color and icon
    local typeColor, typeIcon
    if leaderboardType == "Money" then
        typeColor = Color3.fromRGB(0, 255, 0) -- Green
        typeIcon = IconAssets.getIcon("CURRENCY", "MONEY")
    elseif leaderboardType == "Diamonds" then
        typeColor = Color3.fromRGB(0, 150, 255) -- Blue
        typeIcon = IconAssets.getIcon("CURRENCY", "DIAMONDS")
    elseif leaderboardType == "Rebirths" then
        typeColor = Color3.fromRGB(255, 50, 50) -- Red
        typeIcon = IconAssets.getIcon("UI", "REBIRTH")
    else
        typeColor = Color3.fromRGB(255, 215, 0) -- Default gold
        typeIcon = ""
    end

    -- Icon
    local iconLabel = Instance.new("ImageLabel")
    iconLabel.Name = "IconLabel"
    iconLabel.Size = UDim2.new(0, 80, 0, 80)
    iconLabel.Position = UDim2.new(0, 20, 0.5, -40)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Image = typeIcon
    iconLabel.ScaleType = Enum.ScaleType.Fit
    iconLabel.Parent = mainFrame

    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -120, 1, 0)
    titleLabel.Position = UDim2.new(0, 110, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = leaderboardType:upper() .. " LEADERBOARD"
    titleLabel.TextColor3 = typeColor -- Color-coded by type
    titleLabel.TextSize = 48
    titleLabel.Font = Enum.Font.FredokaOne
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextYAlignment = Enum.TextYAlignment.Center
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    titleLabel.TextScaled = true
    titleLabel.Parent = mainFrame

end

-- Create leaderboard GUI for a specific surface
function PhysicalLeaderboardService:CreateLeaderboardGUI(surfacePart, leaderboardType)
    if not surfacePart then
        warn("PhysicalLeaderboardService: Surface part not found")
        return nil
    end


    -- Create SurfaceGui - Back face with better positioning
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Name = "LeaderboardGUI_" .. leaderboardType
    surfaceGui.Face = Enum.NormalId.Back -- Back face (correct side)
    surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surfaceGui.PixelsPerStud = 50 -- Standard resolution
    surfaceGui.ResetOnSpawn = false
    surfaceGui.LightInfluence = 0 -- Reduce lighting effects
    surfaceGui.Parent = surfacePart

    -- Main container
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1 -- Transparent background
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = surfaceGui

    -- Tab container (moved to top)
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(0, 400, 0, 60)
    tabContainer.Position = UDim2.new(0.5, -200, 0, 10)
    tabContainer.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    tabContainer.BorderSizePixel = 0
    tabContainer.Parent = mainFrame

    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 50) -- Much more rounded
    tabCorner.Parent = tabContainer

    -- All-Time tab
    local allTimeTab = Instance.new("TextButton")
    allTimeTab.Name = "AllTimeTab"
    allTimeTab.Size = UDim2.new(0.5, -4, 1, -8)
    allTimeTab.Position = UDim2.new(0, 4, 0, 4)
    allTimeTab.BackgroundColor3 = Color3.fromRGB(100, 150, 255) -- Active by default
    allTimeTab.BorderSizePixel = 0
    allTimeTab.Text = "All-Time"
    allTimeTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    allTimeTab.TextSize = 28 -- Bigger text
    allTimeTab.Font = Enum.Font.Gotham
    allTimeTab.TextScaled = true
    allTimeTab.Parent = tabContainer

    local allTimeCorner = Instance.new("UICorner")
    allTimeCorner.CornerRadius = UDim.new(0, 45) -- Much more rounded
    allTimeCorner.Parent = allTimeTab

    -- Weekly tab
    local weeklyTab = Instance.new("TextButton")
    weeklyTab.Name = "WeeklyTab"
    weeklyTab.Size = UDim2.new(0.5, -4, 1, -8)
    weeklyTab.Position = UDim2.new(0.5, 0, 0, 4)
    weeklyTab.BackgroundColor3 = Color3.fromRGB(80, 80, 80) -- Inactive by default
    weeklyTab.BorderSizePixel = 0
    weeklyTab.Text = "Weekly"
    weeklyTab.TextColor3 = Color3.fromRGB(0, 0, 0)
    weeklyTab.TextSize = 28 -- Bigger text
    weeklyTab.Font = Enum.Font.Gotham
    weeklyTab.TextScaled = true
    weeklyTab.Parent = tabContainer

    local weeklyCorner = Instance.new("UICorner")
    weeklyCorner.CornerRadius = UDim.new(0, 45) -- Much more rounded
    weeklyCorner.Parent = weeklyTab

    -- Content area (scrollable)
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ContentArea"
    scrollFrame.Size = UDim2.new(1, -20, 1, -90) -- Leave room for tabs only
    scrollFrame.Position = UDim2.new(0, 10, 0, 80)
    scrollFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    scrollFrame.BackgroundTransparency = 0.2
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    scrollFrame.ScrollBarThickness = 12 -- Thicker scroll bar
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be updated with entries
    scrollFrame.Parent = mainFrame

    local scrollCorner = Instance.new("UICorner")
    scrollCorner.CornerRadius = UDim.new(0, 30) -- Much more rounded
    scrollCorner.Parent = scrollFrame

    -- Create GUI management object
    local guiManager = {
        surfaceGui = surfaceGui,
        scrollFrame = scrollFrame,
        allTimeTab = allTimeTab,
        weeklyTab = weeklyTab,
        leaderboardType = leaderboardType,
        currentPeriod = "All-Time" -- Default
    }

    -- Tab switching logic
    allTimeTab.Activated:Connect(function()
        guiManager.currentPeriod = "All-Time"
        allTimeTab.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
        allTimeTab.TextColor3 = Color3.fromRGB(255, 255, 255)
        weeklyTab.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        weeklyTab.TextColor3 = Color3.fromRGB(0, 0, 0)
        PhysicalLeaderboardService:UpdateLeaderboardData(guiManager)
    end)

    weeklyTab.Activated:Connect(function()
        guiManager.currentPeriod = "Weekly"
        weeklyTab.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
        weeklyTab.TextColor3 = Color3.fromRGB(255, 255, 255)
        allTimeTab.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        allTimeTab.TextColor3 = Color3.fromRGB(0, 0, 0)
        PhysicalLeaderboardService:UpdateLeaderboardData(guiManager)
    end)

    return guiManager
end

-- Update leaderboard data for a GUI
function PhysicalLeaderboardService:UpdateLeaderboardData(guiManager)
    if not guiManager then return end

    -- Fetch data from server
    local getLeaderboardDataRemote = ReplicatedStorage:FindFirstChild("GetLeaderboardData")
    if not getLeaderboardDataRemote then
        warn("PhysicalLeaderboardService: GetLeaderboardData remote not found")
        return
    end

    task.spawn(function()
        local success, serverLeaderboardData = pcall(function()
            return getLeaderboardDataRemote:InvokeServer(guiManager.currentPeriod, guiManager.leaderboardType)
        end)

        if success and serverLeaderboardData then
            -- Insert current player's live data for accurate positioning (same as screen UI)
            local liveLeaderboardData = insertLivePlayerData(serverLeaderboardData, guiManager.leaderboardType)
            self:PopulateLeaderboardEntries(guiManager, liveLeaderboardData)
        else
            warn("PhysicalLeaderboardService: Failed to fetch leaderboard data:", serverLeaderboardData)
        end
    end)
end

-- Populate leaderboard entries in the scroll frame
function PhysicalLeaderboardService:PopulateLeaderboardEntries(guiManager, leaderboardData)
    if not guiManager or not guiManager.scrollFrame then return end

    -- Clear existing entries and separators
    for _, child in pairs(guiManager.scrollFrame:GetChildren()) do
        if child:IsA("Frame") and (child.Name:match("Entry_") or child.Name == "Separator") then
            child:Destroy()
        end
    end

    -- Find current player in the full leaderboard
    local currentPlayerEntry = nil
    local currentPlayerRank = nil
    for i, entry in ipairs(leaderboardData) do
        if entry.playerId == player.UserId then
            currentPlayerEntry = entry
            currentPlayerRank = i
            break
        end
    end

    -- Create display list: Top 19 + current player (if not in top 19)
    local displayEntries = {}
    local maxTopEntries = 19 -- Show top 19 to leave room for current player if needed
    
    -- Add top entries
    for i = 1, math.min(#leaderboardData, maxTopEntries) do
        table.insert(displayEntries, leaderboardData[i])
    end
    
    -- Add current player if not already in top 19
    if currentPlayerEntry and currentPlayerRank > maxTopEntries then
        table.insert(displayEntries, currentPlayerEntry)
    end

    -- Create entries
    local entryHeight = 80 -- Bigger entries
    local entrySpacing = 8

    for displayIndex = 1, #displayEntries do
        local entryData = displayEntries[displayIndex]
        local yPosition = (displayIndex - 1) * (entryHeight + entrySpacing)
        
        -- Add separator before current player if they're not in top rankings
        if displayIndex == #displayEntries and currentPlayerEntry and currentPlayerRank > maxTopEntries then
            local separator = Instance.new("Frame")
            separator.Name = "Separator"
            separator.Size = UDim2.new(1, -16, 0, 2)
            separator.Position = UDim2.new(0, 8, 0, yPosition)
            separator.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
            separator.BorderSizePixel = 0
            separator.Parent = guiManager.scrollFrame
            
            -- Adjust entry position to account for separator
            yPosition = yPosition + 10
        end

        local entryFrame = Instance.new("Frame")
        entryFrame.Name = "Entry_" .. displayIndex
        entryFrame.Size = UDim2.new(1, -16, 0, entryHeight)
        entryFrame.Position = UDim2.new(0, 8, 0, yPosition + 5)
        -- Position-based background colors matching UI leaderboard
        entryFrame.BackgroundColor3 = entryData.rank == 1 and Color3.fromRGB(255, 215, 0) or -- Gold
                                     entryData.rank == 2 and Color3.fromRGB(192, 192, 192) or -- Silver  
                                     entryData.rank == 3 and Color3.fromRGB(205, 127, 50) or -- Bronze
                                     entryData.playerId == player.UserId and Color3.fromRGB(100, 150, 255) or -- Current player
                                     Color3.fromRGB(255, 255, 255) -- Default white
        -- Adjust transparency - make top 3 more visible, current player highlighted
        entryFrame.BackgroundTransparency = entryData.rank <= 3 and 0.2 or -- Top 3 positions more opaque
                                           entryData.playerId == player.UserId and 0.3 or -- Current player
                                           0.8 -- Default
        entryFrame.BorderSizePixel = 0
        entryFrame.Parent = guiManager.scrollFrame

        local entryCorner = Instance.new("UICorner")
        entryCorner.CornerRadius = UDim.new(0, 30) -- Much more rounded corners
        entryCorner.Parent = entryFrame

        -- Rank
        local rankLabel = Instance.new("TextLabel")
        rankLabel.Name = "RankLabel"
        rankLabel.Size = UDim2.new(0, 60, 1, 0)
        rankLabel.Position = UDim2.new(0, 8, 0, 0)
        rankLabel.BackgroundTransparency = 1
        rankLabel.Text = "#" .. entryData.rank
        rankLabel.TextColor3 = entryData.rank <= 3 and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 255, 255)
        rankLabel.TextSize = 24 -- Bigger text
        rankLabel.Font = Enum.Font.FredokaOne
        rankLabel.TextXAlignment = Enum.TextXAlignment.Center
        rankLabel.TextYAlignment = Enum.TextYAlignment.Center
        rankLabel.TextStrokeTransparency = 0
        rankLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        rankLabel.TextScaled = true
        rankLabel.Parent = entryFrame

        -- Player face
        local faceFrame = Instance.new("Frame")
        faceFrame.Name = "FaceFrame"
        faceFrame.Size = UDim2.new(0, 60, 0, 60)
        faceFrame.Position = UDim2.new(0, 100, 0.5, -30) -- More centered
        faceFrame.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        faceFrame.BorderSizePixel = 0
        faceFrame.Parent = entryFrame

        local faceCorner = Instance.new("UICorner")
        faceCorner.CornerRadius = UDim.new(0.5, 0)
        faceCorner.Parent = faceFrame

        local faceImage = Instance.new("ImageLabel")
        faceImage.Size = UDim2.new(1, 0, 1, 0)
        faceImage.BackgroundTransparency = 1
        faceImage.Image = getPlayerHeadshot(entryData.playerId)
        faceImage.ScaleType = Enum.ScaleType.Crop
        faceImage.Parent = faceFrame

        local faceImageCorner = Instance.new("UICorner")
        faceImageCorner.CornerRadius = UDim.new(0.5, 0)
        faceImageCorner.Parent = faceImage

        -- Player name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "NameLabel"
        nameLabel.Size = UDim2.new(0, 150, 1, 0) -- Reduced width to prevent overlap
        nameLabel.Position = UDim2.new(0, 175, 0, 0) -- More centered to align with face
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = entryData.playerName
        nameLabel.TextColor3 = entryData.playerId == player.UserId and Color3.fromRGB(255, 255, 100) or Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = 24 -- Same size as rank numbers
        nameLabel.Font = Enum.Font.FredokaOne -- Same font as rank numbers
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextYAlignment = Enum.TextYAlignment.Center
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameLabel.TextScaled = true
        nameLabel.TextWrapped = true -- Allow text wrapping for long names
        nameLabel.Parent = entryFrame

        -- Value (right side)
        local valueFrame = Instance.new("Frame")
        valueFrame.Name = "ValueFrame"
        valueFrame.Size = UDim2.new(0, 140, 1, 0) -- Slightly smaller
        valueFrame.Position = UDim2.new(1, -150, 0, 0) -- Moved closer to right edge
        valueFrame.BackgroundTransparency = 1
        valueFrame.Parent = entryFrame

        local valueLayout = Instance.new("UIListLayout")
        valueLayout.FillDirection = Enum.FillDirection.Horizontal
        valueLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        valueLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        valueLayout.SortOrder = Enum.SortOrder.LayoutOrder
        valueLayout.Padding = UDim.new(0, 1) -- Even closer - right next to each other
        valueLayout.Parent = valueFrame

        -- Value text comes first now
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Name = "ValueLabel"
        valueLabel.Size = UDim2.new(0, 110, 0, 40)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = formatValue(entryData.value, guiManager.leaderboardType)
        valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        valueLabel.TextSize = 24 -- Same size as rank numbers 
        valueLabel.Font = Enum.Font.FredokaOne
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.TextYAlignment = Enum.TextYAlignment.Center
        valueLabel.TextStrokeTransparency = 0
        valueLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        valueLabel.TextScaled = true
        valueLabel.LayoutOrder = 1 -- First in layout
        valueLabel.Parent = valueFrame

        -- Icon comes second
        local valueIcon = Instance.new("ImageLabel")
        valueIcon.Name = "ValueIcon"
        valueIcon.Size = UDim2.new(0, 30, 0, 30)
        valueIcon.BackgroundTransparency = 1
        valueIcon.Image = getTypeIcon(guiManager.leaderboardType)
        valueIcon.ScaleType = Enum.ScaleType.Fit
        valueIcon.LayoutOrder = 2 -- Second in layout
        valueIcon.Parent = valueFrame
    end

    -- Update canvas size
    local totalHeight = #displayEntries * (entryHeight + entrySpacing) + 10
    guiManager.scrollFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
end

-- Initialize all physical leaderboards
function PhysicalLeaderboardService:Initialize()

    -- Wait for workspace to load
    task.wait(2)

    local leaderboardManagers = {}

    for _, config in ipairs(LEADERBOARD_CONFIGS) do
        -- Navigate to the leaderboard model
        local leaderboardModel = workspace
        
        for _, pathSegment in ipairs(config.pathParts) do
            leaderboardModel = leaderboardModel:FindFirstChild(pathSegment)
            if not leaderboardModel then
                warn("PhysicalLeaderboardService: Could not find", pathSegment, "in leaderboard path for", config.name)
                break
            end
        end

        if leaderboardModel then
            -- Find the leaderboard part within the model
            local leaderboardPart = leaderboardModel:FindFirstChild(config.partName)
            local titlePart = leaderboardModel:FindFirstChild(config.titlePartName)
            
            if leaderboardPart and titlePart then
                
                -- Create title GUI
                local titleSuccess = pcall(function()
                    self:CreateTitleGUI(titlePart, config.type)
                end)
                
                if not titleSuccess then
                    warn("PhysicalLeaderboardService: Failed to create title GUI for", config.name)
                end
                
                -- Create leaderboard GUI
                local success, guiManager = pcall(function()
                    return self:CreateLeaderboardGUI(leaderboardPart, config.type)
                end)
                
                if success and guiManager then
                    leaderboardManagers[config.name] = guiManager
                    -- Initial data load
                    self:UpdateLeaderboardData(guiManager)
                else
                    warn("PhysicalLeaderboardService: Failed to create leaderboard GUI for", config.name, "Error:", guiManager or "Unknown error")
                end
            else
                if not leaderboardPart then
                    warn("PhysicalLeaderboardService: Could not find leaderboard part", config.partName, "in model", config.name)
                end
                if not titlePart then
                    warn("PhysicalLeaderboardService: Could not find title part", config.titlePartName, "in model", config.name)
                end
            end
        else
            warn("PhysicalLeaderboardService: Could not find leaderboard model for", config.name)
        end
    end

    -- Set up periodic updates every 15 seconds for more responsive live updates
    task.spawn(function()
        while true do
            task.wait(15) -- More frequent updates for better live experience
            for name, manager in pairs(leaderboardManagers) do
                self:UpdateLeaderboardData(manager)
            end
        end
    end)

    -- Count successful initializations
    local successCount = 0
    for name, manager in pairs(leaderboardManagers) do
        if manager then
            successCount = successCount + 1
        end
    end
end

function PhysicalLeaderboardService:Cleanup()
    -- Cleanup handled by SurfaceGui destruction
end

return PhysicalLeaderboardService