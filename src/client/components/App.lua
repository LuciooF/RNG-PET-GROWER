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

local function App()
    return React.createElement("ScreenGui", {
        Name = "PetGrowerApp",
        ResetOnSpawn = false
    }, {
        TopStats = React.createElement(TopStatsUI),
        PetInventory = React.createElement(PetInventoryUI),
        DebugPanel = React.createElement(DebugPanel),
        ErrorMessage = React.createElement(ErrorMessage),
        PlotVisual = React.createElement(PlotVisual) -- Reactive plot color management
    })
end

return App