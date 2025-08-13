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
    -- Create a simple non-React loading screen for reliability
    container = Instance.new("ScreenGui")
    container.Name = "LoadingScreenContainer"
    container.ResetOnSpawn = false
    container.IgnoreGuiInset = true
    container.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    container.DisplayOrder = 999
    container.Parent = playerGui
    
    -- Background frame
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.Position = UDim2.new(0, 0, 0, 0)
    background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    background.BorderSizePixel = 0
    background.Parent = container
    
    -- Content frame
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(0, 400, 0, 200)
    content.Position = UDim2.new(0.5, -200, 0.5, -100)
    content.BackgroundTransparency = 1
    content.Parent = background
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 60)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Loading..."
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 48
    title.Font = Enum.Font.FredokaOne
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.TextYAlignment = Enum.TextYAlignment.Center
    title.Parent = content
    
    -- Loading bar background
    local loadingBarBg = Instance.new("Frame")
    loadingBarBg.Name = "LoadingBarBg"
    loadingBarBg.Size = UDim2.new(1, 0, 0, 6)
    loadingBarBg.Position = UDim2.new(0, 0, 0, 80)
    loadingBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    loadingBarBg.BorderSizePixel = 0
    loadingBarBg.Parent = content
    
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 3)
    bgCorner.Parent = loadingBarBg
    
    -- Loading bar progress
    local loadingBarProgress = Instance.new("Frame")
    loadingBarProgress.Name = "LoadingBarProgress"
    loadingBarProgress.Size = UDim2.new(0, 0, 1, 0)
    loadingBarProgress.Position = UDim2.new(0, 0, 0, 0)
    loadingBarProgress.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    loadingBarProgress.BorderSizePixel = 0
    loadingBarProgress.Parent = loadingBarBg
    
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 3)
    progressCorner.Parent = loadingBarProgress
    
    -- Status text
    local statusText = Instance.new("TextLabel")
    statusText.Name = "StatusText"
    statusText.Size = UDim2.new(1, 0, 0, 30)
    statusText.Position = UDim2.new(0, 0, 0, 110)
    statusText.BackgroundTransparency = 1
    statusText.Text = "Initializing..."
    statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusText.TextSize = 18
    statusText.Font = Enum.Font.Gotham
    statusText.TextXAlignment = Enum.TextXAlignment.Center
    statusText.TextYAlignment = Enum.TextYAlignment.Center
    statusText.Parent = content
    
    -- Store references
    self.progressBar = loadingBarProgress
    self.statusLabel = statusText
end

function LoadingService:UpdateDisplay()
    if self.progressBar then
        -- Animate progress bar
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(self.progressBar, tweenInfo, {
            Size = UDim2.new(currentProgress, 0, 1, 0)
        })
        tween:Play()
    end
    
    if self.statusLabel then
        self.statusLabel.Text = currentStatus
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
    
    -- Fade out the loading screen
    if container then
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local background = container:FindFirstChild("Background")
        if background then
            local tween = TweenService:Create(background, tweenInfo, {
                BackgroundTransparency = 1
            })
            
            -- Fade out all text elements too
            for _, child in pairs(background:GetDescendants()) do
                if child:IsA("TextLabel") then
                    TweenService:Create(child, tweenInfo, {
                        TextTransparency = 1
                    }):Play()
                elseif child:IsA("Frame") and child.Name ~= "Background" then
                    TweenService:Create(child, tweenInfo, {
                        BackgroundTransparency = 1
                    }):Play()
                end
            end
            
            tween:Play()
            tween.Completed:Connect(function()
                if container then
                    container:Destroy()
                    container = nil
                end
                self.progressBar = nil
                self.statusLabel = nil
            end)
        end
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