-- LeaderboardPanel - UI component for displaying all-time and weekly leaderboards
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local React = require(ReplicatedStorage.Packages.react)

local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)
local TimeFormatter = require(ReplicatedStorage.utils.TimeFormatter)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local DataSyncService = require(script.Parent.Parent.services.DataSyncService)

local player = Players.LocalPlayer

-- Sound constants
local HOVER_SOUND_ID = "rbxassetid://6895079853"
local CLICK_SOUND_ID = "rbxassetid://876939830"

-- Pre-create hover sound for instant playback
local hoverSound = Instance.new("Sound")
hoverSound.SoundId = HOVER_SOUND_ID
hoverSound.Volume = 0.5
hoverSound.Parent = SoundService

-- Pre-create click sound
local clickSound = Instance.new("Sound")
clickSound.SoundId = CLICK_SOUND_ID
clickSound.Volume = 0.6
clickSound.Parent = SoundService

-- Play hover sound instantly
local function playHoverSound()
    hoverSound:Play()
end

-- Play click sound
local function playClickSound()
    clickSound:Play()
end

-- Helper function to get player headshot image
local function getPlayerHeadshot(playerId)
    -- Handle nil or invalid playerId
    if not playerId or type(playerId) ~= "number" then
        -- Return a default/placeholder image or empty string
        return ""
    end
    return "https://www.roblox.com/headshot-thumbnail/image?userId=" .. tostring(playerId) .. "&width=150&height=150&format=png"
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
    elseif leaderboardType == "TimePlayed" then
        -- Convert minutes to seconds to match server format
        local playtimeMinutes = playerData.PlaytimeMinutes or 0
        return math.floor(playtimeMinutes * 60)
    elseif leaderboardType == "RobuxSpent" then
        return playerData.Resources.RobuxSpent or 0
    end
    
    return 0
end

-- Helper function to insert current player's live data into leaderboard for accurate positioning
local function insertLivePlayerData(serverLeaderboardData, selectedType)
    if not serverLeaderboardData then return {} end
    
    local currentPlayerValue = getCurrentPlayerValue(selectedType)
    local currentPlayerId = player.UserId
    
    -- Create a copy of the server data (only include entries with userId)
    local liveLeaderboard = {}
    for i, entry in ipairs(serverLeaderboardData) do
        -- Only include entries that have a userId (ignore old data)
        if entry.userId then
            table.insert(liveLeaderboard, {
                rank = entry.rank,
                playerId = entry.userId, -- Use userId consistently
                playerName = entry.playerName,
                value = entry.value,
                isLiveUpdate = false
            })
        end
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

-- Tab constants
local TABS = {
    ALL_TIME = "All-Time",
    WEEKLY = "Weekly"
}

local LEADERBOARD_TYPES = {
    DIAMONDS = "Diamonds",
    MONEY = "Money", 
    REBIRTHS = "Rebirths",
    TIME_PLAYED = "TimePlayed",
    ROBUX_SPENT = "RobuxSpent"
}

local function LeaderboardPanel(props)
    -- State management
    local selectedTab, setSelectedTab = React.useState(TABS.ALL_TIME)
    local selectedType, setSelectedType = React.useState(LEADERBOARD_TYPES.MONEY)
    local leaderboardData, setLeaderboardData = React.useState({})
    local isLoading, setIsLoading = React.useState(true)
    local outerCircleRef = React.useRef()
    local hoveredEntry, setHoveredEntry = React.useState(nil)
    local resetCountdown, setResetCountdown = React.useState("")
    
    -- Rainbow gradient animation state for Robux Spent tab
    local rainbowRotation, setRainbowRotation = React.useState(0)
    
    -- Fetch leaderboard data when tab or type changes
    React.useEffect(function()
        setIsLoading(true)
        
        -- Fetch real leaderboard data from server
        task.spawn(function()
            local getLeaderboardDataRemote = ReplicatedStorage:FindFirstChild("GetLeaderboardData")
            if not getLeaderboardDataRemote then
                warn("LeaderboardPanel: GetLeaderboardData remote not found")
                setIsLoading(false)
                return
            end
            
            local success, serverLeaderboardData = pcall(function()
                return getLeaderboardDataRemote:InvokeServer(selectedTab, selectedType)
            end)
            
            if success and serverLeaderboardData then
                -- Insert current player's live data for accurate positioning
                local liveLeaderboardData = insertLivePlayerData(serverLeaderboardData, selectedType)
                setLeaderboardData(liveLeaderboardData)
            else
                warn("LeaderboardPanel: Failed to fetch leaderboard data:", serverLeaderboardData)
                setLeaderboardData({})
            end
            
            setIsLoading(false)
        end)
    end, {selectedTab, selectedType})
    
    -- Animation effect for live indicator
    local TweenService = game:GetService("TweenService")
    React.useEffect(function()
        if outerCircleRef.current then
            -- Create two tweens for breathing effect
            local tweenInfo = TweenInfo.new(
                1.2, -- Duration
                Enum.EasingStyle.Sine,
                Enum.EasingDirection.InOut,
                -1, -- Repeat infinitely
                true -- Reverse
            )
            
            -- Transparency tween
            local transparencyTween = TweenService:Create(
                outerCircleRef.current.OuterRing,
                tweenInfo,
                {Transparency = 0.8} -- Breathe between 0.3 and 0.8 transparency
            )
            
            -- Size tween for breathing effect
            local sizeTween = TweenService:Create(
                outerCircleRef.current,
                tweenInfo,
                {Size = UDim2.new(0, ScreenUtils.getProportionalSize(30), 0, ScreenUtils.getProportionalSize(30))} -- Grow from 24 to 30
            )
            
            -- Position tween to keep it centered while growing
            local positionTween = TweenService:Create(
                outerCircleRef.current,
                tweenInfo,
                {Position = UDim2.new(0, ScreenUtils.getProportionalSize(1), 0.5, -ScreenUtils.getProportionalSize(15))} -- Adjust position as it grows
            )
            
            transparencyTween:Play()
            sizeTween:Play()
            positionTween:Play()
            
            return function()
                transparencyTween:Cancel()
                sizeTween:Cancel()
                positionTween:Cancel()
            end
        end
    end, {hasLiveData})
    
    -- Weekly reset countdown calculation
    React.useEffect(function()
        local function updateCountdown()
            local currentTime = os.time()
            local currentDate = os.date("*t", currentTime)
            
            -- Calculate days since epoch Sunday
            local daysSinceEpoch = math.floor(currentTime / 86400)
            local daysSinceSunday = (daysSinceEpoch + 4) % 7 -- Epoch was Thursday, so +4 to get Sunday = 0
            
            -- Calculate next Sunday at 12 PM
            local daysUntilSunday = daysSinceSunday == 0 and 0 or (7 - daysSinceSunday)
            local nextResetTime = currentTime + (daysUntilSunday * 86400) - (currentDate.hour * 3600) - (currentDate.min * 60) - currentDate.sec + (12 * 3600)
            
            -- If it's Sunday but before 12 PM, reset is today
            if daysSinceSunday == 0 and currentDate.hour < 12 then
                nextResetTime = currentTime - (currentDate.hour * 3600) - (currentDate.min * 60) - currentDate.sec + (12 * 3600)
            end
            
            local timeUntilReset = nextResetTime - currentTime
            
            if timeUntilReset <= 0 then
                -- Reset just happened, calculate next week
                nextResetTime = nextResetTime + (7 * 86400)
                timeUntilReset = nextResetTime - currentTime
            end
            
            -- Format countdown
            local days = math.floor(timeUntilReset / 86400)
            local hours = math.floor((timeUntilReset % 86400) / 3600)
            local minutes = math.floor((timeUntilReset % 3600) / 60)
            local seconds = math.floor(timeUntilReset % 60)
            
            local nextResetDate = os.date("*t", nextResetTime)
            local monthNames = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}
            local dayOfMonth = nextResetDate.day
            local ordinalSuffix = "th"
            if dayOfMonth % 10 == 1 and dayOfMonth ~= 11 then
                ordinalSuffix = "st"
            elseif dayOfMonth % 10 == 2 and dayOfMonth ~= 12 then
                ordinalSuffix = "nd"
            elseif dayOfMonth % 10 == 3 and dayOfMonth ~= 13 then
                ordinalSuffix = "rd"
            end
            local resetDateStr = string.format("Sunday %d%s %s at 12:00", dayOfMonth, ordinalSuffix, monthNames[nextResetDate.month])
            
            local countdownStr = ""
            if days > 0 then
                countdownStr = string.format("(in %dd %dh %dm %ds)", days, hours, minutes, seconds)
            elseif hours > 0 then
                countdownStr = string.format("(in %dh %dm %ds)", hours, minutes, seconds)
            elseif minutes > 0 then
                countdownStr = string.format("(in %dm %ds)", minutes, seconds)
            else
                countdownStr = string.format("(in %ds)", seconds)
            end
            
            setResetCountdown("Resets on " .. resetDateStr .. " " .. countdownStr)
        end
        
        -- Update immediately
        updateCountdown()
        
        -- Update every second for live countdown
        local connection = task.spawn(function()
            while true do
                task.wait(1) -- Update every second
                updateCountdown()
            end
        end)
        
        return function()
            task.cancel(connection)
        end
    end, {})
    
    -- Rainbow gradient animation for Robux Spent tab (same as Free OP Item)
    React.useEffect(function()
        local RunService = game:GetService("RunService")
        
        local connection = RunService.Heartbeat:Connect(function()
            -- Animate rainbow gradient rotation (60 degrees per second like Free OP Item)
            local rainbowSpeed = 60 -- degrees per second
            setRainbowRotation(function(current)
                return (current + rainbowSpeed * (1/60)) % 360
            end)
        end)
        
        return function()
            connection:Disconnect()
        end
    end, {})
    
    -- Helper function to get icon for leaderboard type
    local function getTypeIcon(leaderboardType)
        if leaderboardType == "Money" then
            return IconAssets.getIcon("CURRENCY", "MONEY")
        elseif leaderboardType == "Diamonds" then
            return IconAssets.getIcon("CURRENCY", "DIAMONDS")
        elseif leaderboardType == "Rebirths" then
            return IconAssets.getIcon("UI", "REBIRTH")
        elseif leaderboardType == "TimePlayed" then
            return "rbxassetid://6031075938" -- Clock icon
        elseif leaderboardType == "RobuxSpent" then
            return "rbxassetid://6031302977" -- Robux icon
        end
        return ""
    end
    
    -- Helper function to format value based on type
    local function formatValue(value, leaderboardType)
        if leaderboardType == "Rebirths" then
            return tostring(value)
        elseif leaderboardType == "TimePlayed" then
            return TimeFormatter.formatForLeaderboard(value)
        else
            return NumberFormatter.format(value)
        end
    end
    
    -- Create leaderboard entry component
    local function createLeaderboardEntry(entryData, index)
        local isCurrentPlayer = entryData.playerId == player.UserId
        local isLiveData = entryData.isLiveUpdate or false
        local isHovered = hoveredEntry == index
        
        return React.createElement("Frame", {
            Name = "Entry_" .. index,
            Size = UDim2.new(1, -ScreenUtils.getProportionalSize(20), 0, ScreenUtils.getProportionalSize(60)), -- Smaller row height
            Position = UDim2.new(0, ScreenUtils.getProportionalSize(10), 0, (index - 1) * ScreenUtils.getProportionalSize(65) + (index == 1 and ScreenUtils.getProportionalSize(10) or 0)), -- Smaller spacing
            BackgroundColor3 = entryData.rank == 1 and Color3.fromRGB(255, 215, 0) or -- Gold
                              entryData.rank == 2 and Color3.fromRGB(192, 192, 192) or -- Silver
                              entryData.rank == 3 and Color3.fromRGB(205, 127, 50) or -- Bronze
                              isCurrentPlayer and (isLiveData and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(150, 200, 255)) or 
                              (isHovered and Color3.fromRGB(245, 245, 245) or Color3.fromRGB(255, 255, 255)),
            BorderSizePixel = 0,
            ZIndex = 52,
            [React.Event.MouseEnter] = function()
                setHoveredEntry(index)
                playHoverSound()
            end,
            [React.Event.MouseLeave] = function()
                setHoveredEntry(nil)
            end
        }, {
            -- Rounded corners
            Corner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0, ScreenUtils.getProportionalSize(12))
            }),
            
            -- Black outline
            Stroke = React.createElement("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = ScreenUtils.getProportionalSize(2)
            }),
            
            -- Rank number
            RankLabel = React.createElement("TextLabel", {
                Name = "RankLabel",
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(60), 1, 0),
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(10), 0, 0),
                BackgroundTransparency = 1,
                Text = "#" .. entryData.rank,
                TextColor3 = entryData.rank <= 3 and Color3.fromRGB(255, 180, 0) or Color3.fromRGB(80, 80, 80),
                TextSize = ScreenUtils.getTextSize(32),
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextStrokeTransparency = 1,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                ZIndex = 53
            }),
            
            -- Player face image (placeholder for now)
            PlayerFace = React.createElement("Frame", {
                Name = "PlayerFace",
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(50), 0, ScreenUtils.getProportionalSize(50)),
                Position = UDim2.new(0.5, -ScreenUtils.getProportionalSize(130), 0.5, -ScreenUtils.getProportionalSize(25)), -- Centered in middle section
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                ZIndex = 53
            }, {
                -- Circular face
                FaceCorner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(0.5, 0)
                }),
                
                -- Player headshot image
                FaceImage = React.createElement("ImageLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Image = getPlayerHeadshot(entryData.playerId),
                    ScaleType = Enum.ScaleType.Crop,
                    ZIndex = 54
                }, {
                    ImageCorner = React.createElement("UICorner", {
                        CornerRadius = UDim.new(0.5, 0)
                    })
                })
            }),
            
            -- Player name
            PlayerName = React.createElement("TextLabel", {
                Name = "PlayerName",
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(200), 1, 0),
                Position = UDim2.new(0.5, -ScreenUtils.getProportionalSize(70), 0, 0), -- Centered next to face
                BackgroundTransparency = 1,
                Text = entryData.playerName,
                TextColor3 = isCurrentPlayer and Color3.fromRGB(50, 150, 255) or Color3.fromRGB(60, 60, 60),
                TextSize = ScreenUtils.getTextSize(32), -- Same size as rank numbers
                Font = Enum.Font.FredokaOne, -- Same font as rank numbers
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextScaled = true, -- Auto-resize text to fit container
                TextWrapped = true, -- Allow text wrapping if needed
                TextStrokeTransparency = 1,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                ZIndex = 53
            }),
            
            -- Value icon and amount
            ValueContainer = React.createElement("Frame", {
                Name = "ValueContainer",
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(200), 1, 0),
                Position = UDim2.new(1, -ScreenUtils.getProportionalSize(210), 0, 0),
                BackgroundTransparency = 1,
                ZIndex = 53
            }, {
                -- Layout for icon and text
                Layout = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Right,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, ScreenUtils.getProportionalSize(1)) -- Right next to each other
                }),
                
                -- Value text (now first)
                ValueText = React.createElement("TextLabel", {
                    Name = "ValueText",
                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(150), 0, ScreenUtils.getProportionalSize(40)),
                    BackgroundTransparency = 1,
                    Text = formatValue(entryData.value, selectedType),
                    TextColor3 = Color3.fromRGB(80, 80, 80),
                    TextSize = ScreenUtils.getTextSize(32), -- Same size as rank numbers
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextScaled = true, -- Auto-resize text to fit container
                    TextStrokeTransparency = 1,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    LayoutOrder = 1, -- First in layout
                    ZIndex = 54
                }),
                
                -- Value icon (now second)
                ValueIcon = React.createElement("ImageLabel", {
                    Name = "ValueIcon",
                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(32), 0, ScreenUtils.getProportionalSize(32)),
                    BackgroundTransparency = 1,
                    Image = getTypeIcon(selectedType),
                    ScaleType = Enum.ScaleType.Fit,
                    LayoutOrder = 2, -- Second in layout
                    ZIndex = 54
                })
            }),
            
        })
    end
    
    -- Return early if not visible
    if not props.isVisible then
        return nil
    end
    
    -- Check if current player has live data
    local hasLiveData = false
    for _, entry in ipairs(leaderboardData) do
        if entry.playerId == player.UserId and entry.isLiveUpdate then
            hasLiveData = true
            break
        end
    end
    
    return React.createElement("TextButton", {
        Name = "LeaderboardOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        ZIndex = 50,
        Text = "",
        [React.Event.Activated] = function()
            if props.onClose then
                props.onClose()
            end
        end
    }, {
        -- Main panel 
        MainPanel = React.createElement("Frame", {
            Name = "MainPanel", 
            Size = UDim2.new(0, ScreenUtils.getProportionalSize(700), 0, ScreenUtils.getProportionalSize(650)), -- Taller to fit content properly
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(248, 248, 248),
            BorderSizePixel = 0,
            ZIndex = 51
        }, {
            -- Rounded corners
            Corner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0, ScreenUtils.getProportionalSize(20))
            }),
            
            -- Black outline
            Stroke = React.createElement("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = ScreenUtils.getProportionalSize(3)
            }),
            
            -- Background pattern (subtle paw print pattern like playtime rewards)
            PatternOverlay = React.createElement("ImageLabel", {
                Name = "PatternOverlay",
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                Image = "rbxassetid://116367512866072", -- Same paw pattern as playtime rewards
                ScaleType = Enum.ScaleType.Tile,
                TileSize = UDim2.new(0, ScreenUtils.getProportionalSize(120), 0, ScreenUtils.getProportionalSize(120)),
                ImageTransparency = 0.95, -- Very subtle
                ZIndex = 51
            }),
            
            -- Invisible click blocker to prevent closing when clicking inside panel
            ClickBlocker = React.createElement("TextButton", {
                Name = "ClickBlocker",
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 52,
                [React.Event.Activated] = function()
                    -- Do nothing - prevents closing when clicking inside panel
                end
            }),
            
            -- Title
            Title = React.createElement("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -ScreenUtils.getProportionalSize(100), 0, ScreenUtils.getProportionalSize(80)),
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(50), 0, ScreenUtils.getProportionalSize(20)),
                BackgroundTransparency = 1,
                Text = "🏆 LEADERBOARDS 🏆",
                TextColor3 = Color3.fromRGB(255, 215, 0),
                TextSize = ScreenUtils.getTextSize(48),
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                ZIndex = 52
            }),
            
            -- Live indicator (only when player has live data) - top left of UI
            hasLiveData and React.createElement("Frame", {
                Name = "LiveIndicator",
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(120), 0, ScreenUtils.getProportionalSize(40)),
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(20), 0, ScreenUtils.getProportionalSize(20)),
                BackgroundTransparency = 1,
                ZIndex = 100 -- High z-index to appear on top
            }, {
                -- Inner red circle (solid)
                InnerCircle = React.createElement("Frame", {
                    Name = "InnerCircle",
                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(12), 0, ScreenUtils.getProportionalSize(12)),
                    Position = UDim2.new(0, ScreenUtils.getProportionalSize(10), 0.5, -ScreenUtils.getProportionalSize(6)),
                    BackgroundColor3 = Color3.fromRGB(255, 50, 50), -- Red
                    BorderSizePixel = 0,
                    ZIndex = 102
                }, {
                    InnerCorner = React.createElement("UICorner", {
                        CornerRadius = UDim.new(0.5, 0) -- Circular
                    })
                }),
                
                -- Outer red circle (hollow, animated)
                OuterCircle = React.createElement("Frame", {
                    Name = "OuterCircle", 
                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(24), 0, ScreenUtils.getProportionalSize(24)),
                    Position = UDim2.new(0, ScreenUtils.getProportionalSize(4), 0.5, -ScreenUtils.getProportionalSize(12)),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ZIndex = 101,
                    ref = outerCircleRef -- Add ref for animation
                }, {
                    OuterRing = React.createElement("UIStroke", {
                        Color = Color3.fromRGB(255, 50, 50), -- Red
                        Thickness = 3,
                        Transparency = 0.3
                    }),
                    OuterCorner = React.createElement("UICorner", {
                        CornerRadius = UDim.new(0.5, 0) -- Circular
                    })
                }),
                
                -- LIVE text
                LiveText = React.createElement("TextLabel", {
                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(70), 1, 0),
                    Position = UDim2.new(0, ScreenUtils.getProportionalSize(35), 0, 0),
                    BackgroundTransparency = 1,
                    Text = "LIVE",
                    TextColor3 = Color3.fromRGB(255, 50, 50), -- Red text
                    TextSize = ScreenUtils.getTextSize(24),
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 103
                })
            }) or nil,
            
            -- Close button
            CloseButton = React.createElement("ImageButton", {
                Name = "CloseButton",
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(50), 0, ScreenUtils.getProportionalSize(50)),
                Position = UDim2.new(1, -ScreenUtils.getProportionalSize(70), 0, ScreenUtils.getProportionalSize(25)),
                BackgroundTransparency = 1,
                Image = IconAssets.getIcon("UI", "X_BUTTON"),
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 52,
                [React.Event.Activated] = function()
                    playClickSound()
                    if props.onClose then
                        props.onClose()
                    end
                end,
                [React.Event.MouseEnter] = function()
                    playHoverSound()
                end
            }),
            
            -- Tab selector (All-Time vs Weekly)
            TabContainer = React.createElement("Frame", {
                Name = "TabContainer",
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(400), 0, ScreenUtils.getProportionalSize(60)),
                Position = UDim2.new(0.5, -ScreenUtils.getProportionalSize(200), 0, ScreenUtils.getProportionalSize(120)),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                ZIndex = 52
            }, {
                TabCorner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(0, ScreenUtils.getProportionalSize(30))
                }),
                
                TabStroke = React.createElement("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = ScreenUtils.getProportionalSize(2)
                }),
                
                -- All-Time tab
                AllTimeTab = React.createElement("TextButton", {
                    Name = "AllTimeTab",
                    Size = UDim2.new(0.5, -ScreenUtils.getProportionalSize(5), 1, -ScreenUtils.getProportionalSize(10)),
                    Position = UDim2.new(0, ScreenUtils.getProportionalSize(5), 0, ScreenUtils.getProportionalSize(5)),
                    BackgroundColor3 = selectedTab == TABS.ALL_TIME and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(0, 0, 0, 0),
                    BackgroundTransparency = selectedTab == TABS.ALL_TIME and 0 or 1,
                    BorderSizePixel = 0,
                    Text = TABS.ALL_TIME,
                    TextColor3 = selectedTab == TABS.ALL_TIME and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0), -- Black for inactive
                    TextSize = ScreenUtils.getTextSize(24),
                    Font = Enum.Font.Gotham,
                    ZIndex = 53,
                    [React.Event.Activated] = function()
                        playClickSound()
                        setSelectedTab(TABS.ALL_TIME)
                    end,
                    [React.Event.MouseEnter] = function()
                        if selectedTab ~= TABS.ALL_TIME then
                            playHoverSound()
                        end
                    end
                }, selectedTab == TABS.ALL_TIME and {
                    SelectedCorner = React.createElement("UICorner", {
                        CornerRadius = UDim.new(0, ScreenUtils.getProportionalSize(25))
                    })
                } or {}),
                
                -- Weekly tab
                WeeklyTab = React.createElement("TextButton", {
                    Name = "WeeklyTab",
                    Size = UDim2.new(0.5, -ScreenUtils.getProportionalSize(5), 1, -ScreenUtils.getProportionalSize(10)),
                    Position = UDim2.new(0.5, 0, 0, ScreenUtils.getProportionalSize(5)),
                    BackgroundColor3 = selectedTab == TABS.WEEKLY and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(0, 0, 0, 0),
                    BackgroundTransparency = selectedTab == TABS.WEEKLY and 0 or 1,
                    BorderSizePixel = 0,
                    Text = TABS.WEEKLY,
                    TextColor3 = selectedTab == TABS.WEEKLY and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0), -- Black for inactive
                    TextSize = ScreenUtils.getTextSize(24),
                    Font = Enum.Font.Gotham,
                    ZIndex = 53,
                    [React.Event.Activated] = function()
                        playClickSound()
                        setSelectedTab(TABS.WEEKLY)
                    end,
                    [React.Event.MouseEnter] = function()
                        if selectedTab ~= TABS.WEEKLY then
                            playHoverSound()
                        end
                    end
                }, selectedTab == TABS.WEEKLY and {
                    SelectedCorner = React.createElement("UICorner", {
                        CornerRadius = UDim.new(0, ScreenUtils.getProportionalSize(25))
                    })
                } or {})
            }),
            
            -- Type selector (Money, Diamonds, Rebirths, TimePlayed)
            TypeContainer = React.createElement("Frame", {
                Name = "TypeContainer",
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(700), 0, ScreenUtils.getProportionalSize(60)),
                Position = UDim2.new(0.5, -ScreenUtils.getProportionalSize(350), 0, ScreenUtils.getProportionalSize(200)),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                ZIndex = 52
            }, {
                TypeCorner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(0, ScreenUtils.getProportionalSize(30))
                }),
                
                TypeStroke = React.createElement("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = ScreenUtils.getProportionalSize(2)
                }),
                
                -- Diamonds type (first position)
                DiamondsType = React.createElement("TextButton", {
                    Name = "DiamondsType",
                    Size = UDim2.new(0.2, -ScreenUtils.getProportionalSize(6), 1, -ScreenUtils.getProportionalSize(10)),
                    Position = UDim2.new(0, ScreenUtils.getProportionalSize(3), 0, ScreenUtils.getProportionalSize(5)),
                    BackgroundColor3 = selectedType == LEADERBOARD_TYPES.DIAMONDS and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(0, 0, 0, 0),
                    BackgroundTransparency = selectedType == LEADERBOARD_TYPES.DIAMONDS and 0 or 1,
                    BorderSizePixel = 0,
                    Text = LEADERBOARD_TYPES.DIAMONDS,
                    TextColor3 = selectedType == LEADERBOARD_TYPES.DIAMONDS and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0),
                    TextSize = ScreenUtils.getTextSize(22),
                    Font = Enum.Font.Gotham,
                    ZIndex = 53,
                    [React.Event.Activated] = function()
                        playClickSound()
                        setSelectedType(LEADERBOARD_TYPES.DIAMONDS)
                    end,
                    [React.Event.MouseEnter] = function()
                        if selectedType ~= LEADERBOARD_TYPES.DIAMONDS then
                            playHoverSound()
                        end
                    end
                }, selectedType == LEADERBOARD_TYPES.DIAMONDS and {
                    DiamondsCorner = React.createElement("UICorner", {
                        CornerRadius = UDim.new(0, ScreenUtils.getProportionalSize(25))
                    })
                } or {}),
                
                -- Money type (second position)
                MoneyType = React.createElement("TextButton", {
                    Name = "MoneyType",
                    Size = UDim2.new(0.2, -ScreenUtils.getProportionalSize(6), 1, -ScreenUtils.getProportionalSize(10)),
                    Position = UDim2.new(0.2, ScreenUtils.getProportionalSize(1), 0, ScreenUtils.getProportionalSize(5)),
                    BackgroundColor3 = selectedType == LEADERBOARD_TYPES.MONEY and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(0, 0, 0, 0),
                    BackgroundTransparency = selectedType == LEADERBOARD_TYPES.MONEY and 0 or 1,
                    BorderSizePixel = 0,
                    Text = LEADERBOARD_TYPES.MONEY,
                    TextColor3 = selectedType == LEADERBOARD_TYPES.MONEY and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0),
                    TextSize = ScreenUtils.getTextSize(22),
                    Font = Enum.Font.Gotham,
                    ZIndex = 53,
                    [React.Event.Activated] = function()
                        playClickSound()
                        setSelectedType(LEADERBOARD_TYPES.MONEY)
                    end,
                    [React.Event.MouseEnter] = function()
                        if selectedType ~= LEADERBOARD_TYPES.MONEY then
                            playHoverSound()
                        end
                    end
                }, selectedType == LEADERBOARD_TYPES.MONEY and {
                    MoneyCorner = React.createElement("UICorner", {
                        CornerRadius = UDim.new(0, ScreenUtils.getProportionalSize(25))
                    })
                } or {}),
                
                -- Rebirths type (third position)
                RebirthsType = React.createElement("TextButton", {
                    Name = "RebirthsType",
                    Size = UDim2.new(0.2, -ScreenUtils.getProportionalSize(6), 1, -ScreenUtils.getProportionalSize(10)),
                    Position = UDim2.new(0.4, ScreenUtils.getProportionalSize(1), 0, ScreenUtils.getProportionalSize(5)),
                    BackgroundColor3 = selectedType == LEADERBOARD_TYPES.REBIRTHS and Color3.fromRGB(57, 255, 20) or Color3.fromRGB(0, 0, 0, 0),
                    BackgroundTransparency = selectedType == LEADERBOARD_TYPES.REBIRTHS and 0 or 1,
                    BorderSizePixel = 0,
                    Text = LEADERBOARD_TYPES.REBIRTHS,
                    TextColor3 = selectedType == LEADERBOARD_TYPES.REBIRTHS and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0),
                    TextSize = ScreenUtils.getTextSize(22),
                    Font = Enum.Font.Gotham,
                    ZIndex = 53,
                    [React.Event.Activated] = function()
                        playClickSound()
                        setSelectedType(LEADERBOARD_TYPES.REBIRTHS)
                    end,
                    [React.Event.MouseEnter] = function()
                        if selectedType ~= LEADERBOARD_TYPES.REBIRTHS then
                            playHoverSound()
                        end
                    end
                }, selectedType == LEADERBOARD_TYPES.REBIRTHS and {
                    RebirthsCorner = React.createElement("UICorner", {
                        CornerRadius = UDim.new(0, ScreenUtils.getProportionalSize(25))
                    })
                } or {}),
                
                -- Time Played type (fourth position)
                TimePlayedType = React.createElement("TextButton", {
                    Name = "TimePlayedType",
                    Size = UDim2.new(0.2, -ScreenUtils.getProportionalSize(6), 1, -ScreenUtils.getProportionalSize(10)),
                    Position = UDim2.new(0.6, ScreenUtils.getProportionalSize(1), 0, ScreenUtils.getProportionalSize(5)),
                    BackgroundColor3 = selectedType == LEADERBOARD_TYPES.TIME_PLAYED and Color3.fromRGB(255, 150, 0) or Color3.fromRGB(0, 0, 0, 0),
                    BackgroundTransparency = selectedType == LEADERBOARD_TYPES.TIME_PLAYED and 0 or 1,
                    BorderSizePixel = 0,
                    Text = "Time Played",
                    TextColor3 = selectedType == LEADERBOARD_TYPES.TIME_PLAYED and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0),
                    TextSize = ScreenUtils.getTextSize(20), -- Slightly smaller for longer text
                    Font = Enum.Font.Gotham,
                    ZIndex = 53,
                    [React.Event.Activated] = function()
                        playClickSound()
                        setSelectedType(LEADERBOARD_TYPES.TIME_PLAYED)
                    end,
                    [React.Event.MouseEnter] = function()
                        if selectedType ~= LEADERBOARD_TYPES.TIME_PLAYED then
                            playHoverSound()
                        end
                    end
                }, selectedType == LEADERBOARD_TYPES.TIME_PLAYED and {
                    TimePlayedCorner = React.createElement("UICorner", {
                        CornerRadius = UDim.new(0, ScreenUtils.getProportionalSize(25))
                    })
                } or {}),
                
                -- Robux Spent type (fifth position)
                RobuxSpentType = React.createElement("TextButton", {
                    Name = "RobuxSpentType",
                    Size = UDim2.new(0.2, -ScreenUtils.getProportionalSize(6), 1, -ScreenUtils.getProportionalSize(10)),
                    Position = UDim2.new(0.8, ScreenUtils.getProportionalSize(1), 0, ScreenUtils.getProportionalSize(5)),
                    BackgroundColor3 = selectedType == LEADERBOARD_TYPES.ROBUX_SPENT and Color3.fromRGB(50, 50, 50) or Color3.fromRGB(0, 0, 0, 0), -- Dark background when selected
                    BackgroundTransparency = selectedType == LEADERBOARD_TYPES.ROBUX_SPENT and 0 or 1,
                    BorderSizePixel = 0,
                    Text = "Robux Spent",
                    TextColor3 = Color3.fromRGB(255, 255, 255), -- Always white (will be overridden by gradient)
                    TextSize = ScreenUtils.getTextSize(22),
                    Font = Enum.Font.Gotham,
                    ZIndex = 53,
                    [React.Event.Activated] = function()
                        playClickSound()
                        setSelectedType(LEADERBOARD_TYPES.ROBUX_SPENT)
                    end,
                    [React.Event.MouseEnter] = function()
                        if selectedType ~= LEADERBOARD_TYPES.ROBUX_SPENT then
                            playHoverSound()
                        end
                    end
                }, {
                    -- Always show rainbow gradient for text (regardless of selection)
                    RobuxSpentGradient = React.createElement("UIGradient", {
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),    -- Red
                            ColorSequenceKeypoint.new(0.14, Color3.fromRGB(255, 127, 0)),  -- Orange
                            ColorSequenceKeypoint.new(0.28, Color3.fromRGB(255, 255, 0)),  -- Yellow
                            ColorSequenceKeypoint.new(0.42, Color3.fromRGB(0, 255, 0)),    -- Green
                            ColorSequenceKeypoint.new(0.57, Color3.fromRGB(0, 0, 255)),    -- Blue
                            ColorSequenceKeypoint.new(0.71, Color3.fromRGB(75, 0, 130)),   -- Indigo
                            ColorSequenceKeypoint.new(0.85, Color3.fromRGB(148, 0, 211)),  -- Violet
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))     -- Back to Red
                        }),
                        Rotation = rainbowRotation -- Animated rotation
                    }),
                    
                    -- Corner radius when selected
                    RobuxSpentCorner = selectedType == LEADERBOARD_TYPES.ROBUX_SPENT and React.createElement("UICorner", {
                        CornerRadius = UDim.new(0, ScreenUtils.getProportionalSize(25))
                    }) or nil
                })
            }),
            
            -- Leaderboard content area
            ContentArea = React.createElement("ScrollingFrame", {
                Name = "ContentArea",
                Size = UDim2.new(1, -ScreenUtils.getProportionalSize(40), 0, ScreenUtils.getProportionalSize(320)), -- Fit within panel: 650 - 280 - 50 = 320
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(20), 0, ScreenUtils.getProportionalSize(280)),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                ScrollBarImageColor3 = Color3.fromRGB(200, 200, 200),
                ScrollBarThickness = ScreenUtils.getProportionalSize(8),
                CanvasSize = UDim2.new(0, 0, 0, math.max(#leaderboardData * ScreenUtils.getProportionalSize(65) + ScreenUtils.getProportionalSize(10), ScreenUtils.getProportionalSize(320))),
                ZIndex = 51
            }, {
                ContentCorner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(0, ScreenUtils.getProportionalSize(15))
                }),
                
                ContentStroke = React.createElement("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = ScreenUtils.getProportionalSize(2)
                }),
                
                -- Loading indicator
                isLoading and React.createElement("TextLabel", {
                    Name = "LoadingLabel",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "Loading leaderboard...",
                    TextColor3 = Color3.fromRGB(100, 100, 100),
                    TextSize = ScreenUtils.getTextSize(28),
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    ZIndex = 52
                }) or nil,
                
                -- Leaderboard entries
                not isLoading and leaderboardData and #leaderboardData > 0 and React.createElement(React.Fragment, {}, 
                    (function()
                        local entries = {}
                        for i, entryData in ipairs(leaderboardData) do
                            entries["Entry_" .. i] = createLeaderboardEntry(entryData, i)
                        end
                        return entries
                    end)()
                ) or nil,
                
                -- No data message
                not isLoading and (not leaderboardData or #leaderboardData == 0) and React.createElement("TextLabel", {
                    Name = "NoDataLabel",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "No leaderboard data available",
                    TextColor3 = Color3.fromRGB(100, 100, 100),
                    TextSize = ScreenUtils.getTextSize(28),
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    ZIndex = 52
                }) or nil
            }),
            
            -- Weekly reset countdown (only show when Weekly tab is selected)
            selectedTab == TABS.WEEKLY and React.createElement("TextLabel", {
                Name = "ResetCountdown",
                Size = UDim2.new(1, -ScreenUtils.getProportionalSize(40), 0, ScreenUtils.getProportionalSize(35)),
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(20), 1, -ScreenUtils.getProportionalSize(45)),
                BackgroundTransparency = 1,
                Text = resetCountdown,
                TextColor3 = Color3.fromRGB(150, 50, 50), -- Dark red text
                TextSize = ScreenUtils.getTextSize(22), -- Bigger text
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 52
            }) or nil
        })
    })
end

return LeaderboardPanel