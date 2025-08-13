-- App - Main client application component
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local React = require(ReplicatedStorage.Packages.react)
local ReactRoblox = require(ReplicatedStorage.Packages["react-roblox"])

local TopStatsUI = require(script.Parent.TopStatsUI)
local PetInventoryUI = require(script.Parent.PetInventoryUI)
local DebugPanel = require(script.Parent.DebugPanel)
local ErrorMessage = require(script.Parent.ErrorMessage)
local PlotVisual = require(script.Parent.PlotVisual)
local RebirthUI = require(script.Parent.RebirthUI)
local GamepassUI = require(script.Parent.GamepassUI)
local PetMixerUI = require(script.Parent.PetMixerUI)
local PetIndexUI = require(script.Parent.PetIndexUI)
local SideBar = require(script.Parent.SideBar)
local RightSideBar = require(script.Parent.RightSideBar)
local BoostButton = require(script.Parent.BoostButton)
local BoostPanel = require(script.Parent.BoostPanel)
local TutorialUI = require(script.Parent.TutorialUI)
local OPPetButton = require(script.Parent.OPPetButton)
local PlaytimeRewardsPanel = require(script.Parent.PlaytimeRewardsPanel)
local DailyRewardsPanel = require(script.Parent.DailyRewardsPanel)
local LeaderboardPanel = require(script.Parent.LeaderboardPanel)
local PotionInventoryUI = require(script.Parent.PotionInventoryUI)
local CrazyChestUI = require(script.Parent.CrazyChestUI)
local FreeOpItemUI = require(script.Parent.FreeOpItemUI)
local DataSyncService = require(script.Parent.Parent.services.DataSyncService)
local TutorialService = require(script.Parent.Parent.services.TutorialService)
local RebirthButtonService = require(script.Parent.Parent.services.RebirthButtonService)
local TeleportService = require(script.Parent.Parent.services.TeleportService)
local PetMagnetService = require(script.Parent.Parent.services.PetMagnetService)
local AutoHeavenService = require(script.Parent.Parent.services.AutoHeavenService)
local PetMagnetButtonService = require(script.Parent.Parent.services.PetMagnetButtonService)
local AutoHeavenButtonService = require(script.Parent.Parent.services.AutoHeavenButtonService)
local PetMixerAnimationService = require(script.Parent.Parent.services.PetMixerAnimationService)
local TwoXMoneyButtonService = require(script.Parent.Parent.services.TwoXMoneyButtonService)
local TwoXDiamondsButtonService = require(script.Parent.Parent.services.TwoXDiamondsButtonService)
local TwoXHeavenSpeedButtonService = require(script.Parent.Parent.services.TwoXHeavenSpeedButtonService)
local CrazyChestService = require(script.Parent.Parent.services.CrazyChestService)
local VIPButtonService = require(script.Parent.Parent.services.VIPButtonService)
local SendHeavenButtonService = require(script.Parent.Parent.services.SendHeavenButtonService)
local RewardsService = require(script.Parent.Parent.services.RewardsService)

local function App()
    -- State for UI visibility
    local rebirthUIVisible, setRebirthUIVisible = React.useState(false)
    local petIndexVisible, setPetIndexVisible = React.useState(false)
    local debugVisible, setDebugVisible = React.useState(false)
    local petInventoryVisible, setPetInventoryVisible = React.useState(false)
    local gamepassVisible, setGamepassVisible = React.useState(false)
    local boostPanelVisible, setBoostPanelVisible = React.useState(false)
    local tutorialVisible, setTutorialVisible = React.useState(false)
    local playtimeRewardsVisible, setPlaytimeRewardsVisible = React.useState(false)
    local dailyRewardsVisible, setDailyRewardsVisible = React.useState(false)
    local leaderboardVisible, setLeaderboardVisible = React.useState(false)
    local potionInventoryVisible, setPotionInventoryVisible = React.useState(false)
    local freeOpItemVisible, setFreeOpItemVisible = React.useState(false)
    local tutorialData, setTutorialData = React.useState({})
    local crazyChestProps, setCrazyChestProps = React.useState(CrazyChestService:GetUIProps())
    local playerData, setPlayerData = React.useState({
        Resources = { Money = 0, Rebirths = 0 }
    })
    
    -- Shared session timer for playtime rewards (created once when app loads)
    local sharedSessionStartTime = React.useRef(tick())
    
    -- Shared session claimed rewards state (resets when app reloads)
    local sharedSessionClaimedRewards, setSharedSessionClaimedRewards = React.useState({})
    
    -- Shared Free OP Item claim state (resets when app reloads)
    local sharedFreeOpLastClaimTime, setSharedFreeOpLastClaimTime = React.useState(0)
    local sharedFreeOpClaimCount, setSharedFreeOpClaimCount = React.useState(0)
    
    -- Subscribe to data changes
    React.useEffect(function()
        -- Get initial data
        local initialData = DataSyncService:GetPlayerData()
        if initialData then
            setPlayerData(initialData)
        end
        
        local unsubscribe = DataSyncService:Subscribe(function(newState)
            if newState.player then
                setPlayerData(newState.player)
            end
        end)
        
        return function()
            if unsubscribe and type(unsubscribe) == "function" then
                unsubscribe()
            end
        end
    end, {})
    
    -- Set up rebirth button service
    React.useEffect(function()
        RebirthButtonService:Initialize()
        
        -- Set callbacks for rebirth button interaction
        RebirthButtonService:SetOpenCallback(function()
            setRebirthUIVisible(true)
        end)
        
        RebirthButtonService:SetCloseCallback(function()
            setRebirthUIVisible(false)
        end)
        
        return function()
            RebirthButtonService:Cleanup()
        end
    end, {})
    
    -- Set up teleport service
    React.useEffect(function()
        TeleportService:Initialize()
        
        return function()
            TeleportService:Cleanup()
        end
    end, {})
    
    -- Set up pet magnet service
    React.useEffect(function()
        PetMagnetService:Initialize()
        
        return function()
            PetMagnetService:Cleanup()
        end
    end, {})
    
    -- Set up auto heaven service
    React.useEffect(function()
        AutoHeavenService:Initialize()
        
        return function()
            AutoHeavenService:Cleanup()
        end
    end, {})
    
    -- Gamepass button services are initialized by Main.client.lua
    -- (Removed duplicate initialization to prevent conflicts)
    
    -- Set up pet mixer animation service
    React.useEffect(function()
        PetMixerAnimationService:Initialize()
        
        return function()
            PetMixerAnimationService:Cleanup()
        end
    end, {})
    
    -- 2X gamepass button services are initialized by Main.client.lua
    -- (Removed duplicate initialization to prevent conflicts)
    
    -- VIP button service is initialized by Main.client.lua
    -- (Removed duplicate initialization to prevent conflicts)
    
    -- Set up SendHeaven button service
    React.useEffect(function()
        SendHeavenButtonService:Initialize()
        
        return function()
            -- No cleanup method needed for this service
        end
    end, {})
    
    -- Set up tutorial service
    React.useEffect(function()
        TutorialService:Initialize()
        
        -- Update tutorial state (no polling, event-driven)
        local updateTutorial = function()
            local tutorialActive = TutorialService:IsActive()
            local currentTutorialData = TutorialService:GetTutorialData()
            
            setTutorialVisible(tutorialActive)
            setTutorialData(currentTutorialData)
        end
        
        -- Initial update only
        updateTutorial()
        
        -- Update when tutorial service changes (via DataSyncService subscription)
        local tutorialConnection = DataSyncService:Subscribe(function(newState)
            if newState.player then
                updateTutorial()
            end
        end)
        
        -- Also update periodically to catch tutorial state changes
        local lastUpdateTime = 0
        local updateConnection = RunService.Heartbeat:Connect(function()
            -- Throttle to once per second
            if tick() - lastUpdateTime > 1 then
                lastUpdateTime = tick()
                updateTutorial()
            end
        end)
        
        return function()
            TutorialService:Cleanup()
            if tutorialConnection then
                tutorialConnection()
            end
            if updateConnection then
                updateConnection:Disconnect()
            end
        end
    end, {})
    
    -- Set up rewards service
    React.useEffect(function()
        RewardsService:Initialize()
        
        return function()
            RewardsService:Cleanup()
        end
    end, {})
    
    -- Crazy chest service is initialized in Main.client.lua
    -- No need to initialize again here
    
    -- Update crazy chest props periodically (throttled)
    React.useEffect(function()
        local lastUpdate = 0
        local connection = game:GetService("RunService").Heartbeat:Connect(function()
            if tick() - lastUpdate > 1 then -- Update every 1 second to avoid React infinite loops
                lastUpdate = tick()
                setCrazyChestProps(CrazyChestService:GetUIProps())
            end
        end)
        
        return function()
            connection:Disconnect()
        end
    end, {})
    
    -- Handle rebirth UI close
    local function handleRebirthClose()
        setRebirthUIVisible(false)
    end
    
    -- Handle rebirth action
    local function handleRebirth()
        -- Fire rebirth remote to server
        local rebirthRemote = ReplicatedStorage:FindFirstChild("RebirthPlayer")
        if rebirthRemote then
            rebirthRemote:FireServer()
            setRebirthUIVisible(false)
        else
            warn("RebirthPlayer remote event not found")
        end
    end
    
    -- Tutorial event handlers
    local function handleTutorialClose()
        TutorialService:StopTutorial()
        setTutorialVisible(false)
    end
    
    local function handleTutorialNext()
        TutorialService:NextStep()
    end
    
    local function handleTutorialSkip()
        TutorialService:StopTutorial()
        setTutorialVisible(false)
    end
    
    -- Use shared rebirth cost calculation
    local RebirthUtils = require(ReplicatedStorage.utils.RebirthUtils)
    
    local currentRebirths = playerData.Resources.Rebirths or 0
    local rebirthCost = RebirthUtils.getRebirthCost(currentRebirths)
    local canRebirth = (playerData.Resources.Money or 0) >= rebirthCost
    
    -- TutorialUI rendering handled below
    
    return React.createElement("ScreenGui", {
        Name = "PetGrowerApp",
        ResetOnSpawn = false,
        IgnoreGuiInset = true
    }, {
        -- Unified SideBar with all navigation buttons including boost
        SideBar = React.createElement(SideBar, {
            onGamepassClick = function()
                setGamepassVisible(function(prev) return not prev end)
            end,
            onPetsClick = function()
                setPetInventoryVisible(function(prev) return not prev end)
            end,
            onIndexClick = function()
                setPetIndexVisible(function(prev) return not prev end)
            end,
            onRebirthClick = function()
                setRebirthUIVisible(true)
            end,
            onDebugClick = function()
                setDebugVisible(function(prev) return not prev end)
            end,
            onBoostClick = function()
                setBoostPanelVisible(not boostPanelVisible)
            end
        }),
        
        -- Right side navigation (now includes all right-side buttons)
        RightSideBar = React.createElement(RightSideBar, {
            onPotionClick = function()
                setPotionInventoryVisible(function(prev) return not prev end)
            end,
            onPlaytimeRewardsClick = function()
                setPlaytimeRewardsVisible(function(prev) return not prev end)
            end,
            onDailyRewardsClick = function()
                setDailyRewardsVisible(function(prev) return not prev end)
            end,
            onLeaderboardClick = function()
                setLeaderboardVisible(function(prev) return not prev end)
            end,
            onFreeOpItemClick = function()
                setFreeOpItemVisible(function(prev) return not prev end)
            end,
            sharedSessionStartTime = sharedSessionStartTime.current,
            sharedSessionClaimedRewards = sharedSessionClaimedRewards,
            setSharedSessionClaimedRewards = setSharedSessionClaimedRewards,
            sharedFreeOpLastClaimTime = sharedFreeOpLastClaimTime,
            sharedFreeOpClaimCount = sharedFreeOpClaimCount
        }),
        
        -- UI Components
        TopStats = React.createElement(TopStatsUI),
        PetInventory = React.createElement(PetInventoryUI, {
            visible = petInventoryVisible,
            onClose = function()
                setPetInventoryVisible(false)
            end,
            onOpenRebirth = function()
                setRebirthUIVisible(true)
            end
        }),
        DebugPanel = React.createElement(DebugPanel, {
            visible = debugVisible,
            onVisibilityChange = setDebugVisible
        }),
        ErrorMessage = React.createElement(ErrorMessage),
        PlotVisual = React.createElement(PlotVisual),
        GamepassUI = React.createElement(GamepassUI, {
            visible = gamepassVisible,
            onClose = function()
                setGamepassVisible(false)
            end
        }),
        PetMixerUI = React.createElement(PetMixerUI),
        PetIndexUI = React.createElement(PetIndexUI, {
            visible = petIndexVisible,
            setVisible = setPetIndexVisible
        }),
        BoostPanel = React.createElement(BoostPanel, {
            visible = boostPanelVisible,
            onClose = function()
                setBoostPanelVisible(false)
            end
        }),
        RebirthUI = rebirthUIVisible and React.createElement(RebirthUI.new, {
            visible = rebirthUIVisible,
            playerMoney = playerData.Resources.Money or 0,
            playerRebirths = playerData.Resources.Rebirths or 0,
            rebirthCost = rebirthCost,
            canRebirth = canRebirth,
            onClose = handleRebirthClose,
            onRebirth = handleRebirth
        }) or nil,
        TutorialUI = tutorialVisible and React.createElement(TutorialUI.new, {
            visible = tutorialVisible,
            currentStep = tutorialData.currentStep or 1,
            tutorialData = tutorialData,
            onClose = handleTutorialClose,
            onNext = handleTutorialNext,
            onSkip = handleTutorialSkip
        }) or nil,
        
        PlaytimeRewardsPanel = playtimeRewardsVisible and React.createElement(PlaytimeRewardsPanel, {
            isVisible = playtimeRewardsVisible,
            onClose = function()
                setPlaytimeRewardsVisible(false)
            end,
            onClaimReward = function(timeMinutes, sessionTime)
                -- Mark as claimed in shared state first
                setSharedSessionClaimedRewards(function(prev)
                    local newClaimed = {}
                    for k, v in pairs(prev) do
                        newClaimed[k] = v
                    end
                    newClaimed[timeMinutes] = true
                    return newClaimed
                end)
                
                -- Fire remote event to claim reward with session time validation
                local claimPlaytimeRewardRemote = ReplicatedStorage:FindFirstChild("ClaimPlaytimeReward")
                if claimPlaytimeRewardRemote then
                    claimPlaytimeRewardRemote:FireServer(timeMinutes, sessionTime)
                end
            end,
            sharedSessionStartTime = sharedSessionStartTime.current,
            sharedSessionClaimedRewards = sharedSessionClaimedRewards,
            setSharedSessionClaimedRewards = setSharedSessionClaimedRewards
        }) or nil,
        
        -- Daily Rewards Panel
        DailyRewardsPanel = dailyRewardsVisible and React.createElement(DailyRewardsPanel, {
            isVisible = dailyRewardsVisible,
            onClose = function()
                setDailyRewardsVisible(false)
            end
        }) or nil,
        
        -- Leaderboard Panel
        LeaderboardPanel = leaderboardVisible and React.createElement(LeaderboardPanel, {
            isVisible = leaderboardVisible,
            onClose = function()
                setLeaderboardVisible(false)
            end
        }) or nil,
        
        -- Potion Inventory Panel
        PotionInventoryUI = potionInventoryVisible and React.createElement(PotionInventoryUI, {
            visible = potionInventoryVisible,
            onClose = function()
                setPotionInventoryVisible(false)
            end
        }) or nil,
        
        -- Free OP Item Panel
        FreeOpItemUI = freeOpItemVisible and React.createElement(FreeOpItemUI, {
            visible = freeOpItemVisible,
            onClose = function()
                setFreeOpItemVisible(false)
            end,
            sharedSessionStartTime = sharedSessionStartTime.current,
            sharedFreeOpLastClaimTime = sharedFreeOpLastClaimTime,
            setSharedFreeOpLastClaimTime = setSharedFreeOpLastClaimTime,
            sharedFreeOpClaimCount = sharedFreeOpClaimCount,
            setSharedFreeOpClaimCount = setSharedFreeOpClaimCount
        }) or nil,
        
        -- OP Pet Purchase Button (always visible on top right)
        OPPetButton = React.createElement(OPPetButton),
        
        
        -- Crazy Chest UI (conditional rendering based on visibility)
        CrazyChestUI = React.createElement(CrazyChestUI.new, crazyChestProps)
    })
end

return App