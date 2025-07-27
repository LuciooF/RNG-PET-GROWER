-- Main Client Script
-- Handles client-side initialization and data sync

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local React = require(ReplicatedStorage.Packages.react)
local ReactRoblox = require(ReplicatedStorage.Packages["react-roblox"])

-- Initialize data sync service
local DataSyncService = require(script.Parent.services.DataSyncService)
DataSyncService:Initialize()

-- Initialize pet collection service
local PetCollectionService = require(script.Parent.services.PetCollectionService)
PetCollectionService:Initialize()

-- Initialize pet follow service
local PetFollowService = require(script.Parent.services.PetFollowService)
PetFollowService:Initialize()

-- Initialize React app
local App = require(script.Parent.components.App)
local root = ReactRoblox.createRoot(Players.LocalPlayer:WaitForChild("PlayerGui"))
root:render(React.createElement(App))

-- Wait for PlayerAreas to be created by server
local playerAreas = Workspace:WaitForChild("PlayerAreas", 30)
if not playerAreas then
    warn("Client: PlayerAreas not found!")
end