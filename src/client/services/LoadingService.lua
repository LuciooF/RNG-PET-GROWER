-- LoadingService - Manages the loading screen display and progress
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local React = require(ReplicatedStorage.Packages.react)
local ReactRoblox = require(ReplicatedStorage.Packages["react-roblox"])
local LoadingScreen = require(script.Parent.Parent.components.LoadingScreen)

local LoadingService = {}
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- State
local isVisible = true
local currentProgress = 0
local currentStatus = "Initializing..."
local root = nil
local container = nil

function LoadingService:Initialize()
    -- Create container for loading screen
    container = Instance.new("ScreenGui")
    container.Name = "LoadingScreenContainer"
    container.ResetOnSpawn = false
    container.IgnoreGuiInset = true
    container.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    container.DisplayOrder = 999
    container.Parent = playerGui
    
    -- Create React root and render loading screen
    root = ReactRoblox.createRoot(container)
    self:UpdateDisplay()
end

function LoadingService:UpdateDisplay()
    if root then
        root:render(React.createElement(LoadingScreen, {
            visible = isVisible,
            progress = currentProgress,
            status = currentStatus
        }))
    end
end

function LoadingService:SetProgress(progress, status)
    currentProgress = math.clamp(progress, 0, 1)
    if status then
        currentStatus = status
    end
    self:UpdateDisplay()
end

function LoadingService:Hide()
    if not isVisible then return end
    
    isVisible = false
    self:UpdateDisplay()
    
    -- Clean up after a short delay
    task.wait(0.5)
    if root then
        root:unmount()
        root = nil
    end
    if container then
        container:Destroy()
        container = nil
    end
end

function LoadingService:Show()
    if isVisible then return end
    
    isVisible = true
    currentProgress = 0
    currentStatus = "Loading..."
    
    if not container then
        self:Initialize()
    else
        self:UpdateDisplay()
    end
end

function LoadingService:IsVisible()
    return isVisible
end

return LoadingService