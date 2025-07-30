-- App - Main client application component
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

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
local PetIndexButton = require(script.Parent.PetIndexButton)
local DataSyncService = require(script.Parent.Parent.services.DataSyncService)
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
local VIPButtonService = require(script.Parent.Parent.services.VIPButtonService)
local SendHeavenButtonService = require(script.Parent.Parent.services.SendHeavenButtonService)

local function App()
    -- State for rebirth UI visibility
    local rebirthUIVisible, setRebirthUIVisible = React.useState(false)
    -- State for pet index visibility
    local petIndexVisible, setPetIndexVisible = React.useState(false)
    local playerData, setPlayerData = React.useState({
        Resources = { Money = 0, Rebirths = 0 }
    })
    
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
        
        return unsubscribe
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
    
    -- Set up pet magnet button service
    React.useEffect(function()
        PetMagnetButtonService:Initialize()
        
        return function()
            PetMagnetButtonService:Cleanup()
        end
    end, {})
    
    -- Set up auto heaven button service
    React.useEffect(function()
        AutoHeavenButtonService:Initialize()
        
        return function()
            AutoHeavenButtonService:Cleanup()
        end
    end, {})
    
    -- Set up pet mixer animation service
    React.useEffect(function()
        PetMixerAnimationService:Initialize()
        
        return function()
            PetMixerAnimationService:Cleanup()
        end
    end, {})
    
    -- Set up 2x Money button service
    React.useEffect(function()
        TwoXMoneyButtonService:Initialize()
        
        return function()
            TwoXMoneyButtonService:Cleanup()
        end
    end, {})
    
    -- Set up 2x Diamonds button service
    React.useEffect(function()
        TwoXDiamondsButtonService:Initialize()
        
        return function()
            TwoXDiamondsButtonService:Cleanup()
        end
    end, {})
    
    -- Set up 2x Heaven Speed button service
    React.useEffect(function()
        TwoXHeavenSpeedButtonService:Initialize()
        
        return function()
            TwoXHeavenSpeedButtonService:Cleanup()
        end
    end, {})
    
    -- Set up VIP button service
    React.useEffect(function()
        VIPButtonService:Initialize()
        
        return function()
            VIPButtonService:Cleanup()
        end
    end, {})
    
    -- Set up SendHeaven button service
    React.useEffect(function()
        SendHeavenButtonService:Initialize()
        
        return function()
            -- No cleanup method needed for this service
        end
    end, {})
    
    -- Handle rebirth UI close
    local function handleRebirthClose()
        setRebirthUIVisible(false)
    end
    
    -- Handle rebirth action
    local function handleRebirth()
        -- TODO: Implement actual rebirth logic
        warn("Rebirth functionality not yet implemented")
        setRebirthUIVisible(false)
    end
    
    -- Check if player can rebirth (needs 1000 money)
    local canRebirth = (playerData.Resources.Money or 0) >= 1000
    
    return React.createElement("ScreenGui", {
        Name = "PetGrowerApp",
        ResetOnSpawn = false
    }, {
        TopStats = React.createElement(TopStatsUI),
        PetInventory = React.createElement(PetInventoryUI),
        DebugPanel = React.createElement(DebugPanel),
        ErrorMessage = React.createElement(ErrorMessage),
        PlotVisual = React.createElement(PlotVisual), -- Reactive plot color management
        GamepassUI = React.createElement(GamepassUI), -- Gamepass shop
        PetMixerUI = React.createElement(PetMixerUI), -- Pet mixer system
        PetIndexUI = React.createElement(PetIndexUI, {
            visible = petIndexVisible,
            setVisible = setPetIndexVisible
        }), -- Pet collection index
        PetIndexButton = React.createElement(PetIndexButton, {
            onClick = function()
                setPetIndexVisible(function(prev) return not prev end)
            end
        }), -- Button to open Pet Index
        RebirthUI = rebirthUIVisible and React.createElement(RebirthUI.new, {
            visible = rebirthUIVisible,
            playerMoney = playerData.Resources.Money or 0,
            playerRebirths = playerData.Resources.Rebirths or 0,
            canRebirth = canRebirth,
            onClose = handleRebirthClose,
            onRebirth = handleRebirth
        }) or nil
    })
end

return App