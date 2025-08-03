-- Main Client Script
-- Handles client-side initialization and data sync

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local React = require(ReplicatedStorage.Packages.react)
local ReactRoblox = require(ReplicatedStorage.Packages["react-roblox"])

-- Initialize pet collection service (doesn't depend on player data)
local PetCollectionService = require(script.Parent.services.PetCollectionService)
PetCollectionService:Initialize()

-- Initialize client-side pet ball spawning service (doesn't depend on player data)
local ClientPetBallService = require(script.Parent.services.ClientPetBallService)
ClientPetBallService:Initialize()

-- Initialize pet follow service (doesn't depend on player data)
local PetFollowService = require(script.Parent.services.PetFollowService)
PetFollowService:Initialize()

-- Wait for server to process player, then initialize data-dependent services
task.spawn(function()
    -- Small delay to ensure server has started processing this player
    local attempts = 0
    while not game.Workspace:FindFirstChild("PlayerAreas") and attempts < 50 do
        task.wait(0.1)
        attempts = attempts + 1
    end
    
    -- Initialize data sync service first
    local DataSyncService = require(script.Parent.services.DataSyncService)
    DataSyncService:Initialize()
    
    -- Wait for initial data to be available before initializing gamepass services
    local playerData = DataSyncService:GetPlayerData()
    local maxWaitTime = 10 -- Maximum 10 seconds
    local waitStart = tick()
    
    while not playerData and (tick() - waitStart) < maxWaitTime do
        task.wait(0.5)
        playerData = DataSyncService:GetPlayerData()
    end
    
    if not playerData then
        warn("Main.client: Failed to get player data after 10 seconds, initializing gamepass services anyway")
    end
    
    -- Initialize gamepass button services after data is ready
    local AutoHeavenButtonService = require(script.Parent.services.AutoHeavenButtonService)
    AutoHeavenButtonService:Initialize()

    local PetMagnetButtonService = require(script.Parent.services.PetMagnetButtonService)
    PetMagnetButtonService:Initialize()

    local TwoXDiamondsButtonService = require(script.Parent.services.TwoXDiamondsButtonService)
    TwoXDiamondsButtonService:Initialize()

    local TwoXMoneyButtonService = require(script.Parent.services.TwoXMoneyButtonService)
    TwoXMoneyButtonService:Initialize()

    local TwoXHeavenSpeedButtonService = require(script.Parent.services.TwoXHeavenSpeedButtonService)
    TwoXHeavenSpeedButtonService:Initialize()

    local VIPButtonService = require(script.Parent.services.VIPButtonService)
    VIPButtonService:Initialize()
    
    -- Initialize plot GUI service (creates client-side plot GUIs with icons)
    local PlotGUIService = require(script.Parent.services.PlotGUIService)
    PlotGUIService:Initialize()
    
    -- Initialize popup service (shows +money/diamonds/rebirths animations)
    local PopupService = require(script.Parent.services.PopupService)
    PopupService:Initialize()
    
    -- Initialize rebirth celebration service (shows animation when player rebirths)
    local RebirthCelebrationService = require(script.Parent.services.RebirthCelebrationService)
    RebirthCelebrationService:Initialize()
    
    -- Initialize pet discovery service (shows popups for new pet discoveries)
    local PetDiscoveryService = require(script.Parent.services.PetDiscoveryService)
    PetDiscoveryService:Initialize()
    
    -- Initialize coming soon GUI service
    local ComingSoonGUIService = require(script.Parent.services.ComingSoonGUIService)
    ComingSoonGUIService:Initialize()
    
    -- Initialize area nameplate enhancement service
    local AreaNameplateService = require(script.Parent.services.AreaNameplateService)
    AreaNameplateService:Initialize()
    
    -- Initialize player enhancement service (speed boost + trail)
    local PlayerEnhancementService = require(script.Parent.services.PlayerEnhancementService)
    PlayerEnhancementService:Initialize()
end)

-- Create a dedicated ScreenGui for React (fixed mobile controls issue)
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local reactContainer = Instance.new("ScreenGui")
reactContainer.Name = "ReactContainer"
reactContainer.ResetOnSpawn = false
reactContainer.IgnoreGuiInset = true
reactContainer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
reactContainer.Parent = playerGui

-- Initialize React app
local App = require(script.Parent.components.App)
local root = ReactRoblox.createRoot(reactContainer)
root:render(React.createElement(App))

-- Wait for PlayerAreas to be created by server
local playerAreas = Workspace:WaitForChild("PlayerAreas", 30)
if not playerAreas then
    warn("Client: PlayerAreas not found!")
end