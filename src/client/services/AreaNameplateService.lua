-- AreaNameplateService - Enhances area nameplates on client side with rainbow effect for own area
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local AreaNameplateService = {}
AreaNameplateService.__index = AreaNameplateService

local player = Players.LocalPlayer

-- Rainbow color sequence for animated gradient
local RAINBOW_COLORS = {
    Color3.fromRGB(255, 0, 0),    -- Red
    Color3.fromRGB(255, 127, 0),  -- Orange
    Color3.fromRGB(255, 255, 0),  -- Yellow
    Color3.fromRGB(0, 255, 0),    -- Green
    Color3.fromRGB(0, 0, 255),    -- Blue
    Color3.fromRGB(75, 0, 130),   -- Indigo
    Color3.fromRGB(148, 0, 211),  -- Violet
    Color3.fromRGB(255, 0, 0)     -- Back to Red
}

-- Create color sequence from colors
local function createRainbowSequence()
    local keypoints = {}
    for i, color in ipairs(RAINBOW_COLORS) do
        local time = (i - 1) / (#RAINBOW_COLORS - 1)
        table.insert(keypoints, ColorSequenceKeypoint.new(time, color))
    end
    return ColorSequence.new(keypoints)
end

function AreaNameplateService:Initialize()
    -- Wait for player areas to be created
    task.spawn(function()
        local playerAreas = Workspace:WaitForChild("PlayerAreas", 30)
        if not playerAreas then
            warn("AreaNameplateService: PlayerAreas not found in Workspace after 30 seconds")
            return
        end
        
        -- Process all existing nameplates
        for _, area in pairs(playerAreas:GetChildren()) do
            if area:IsA("Model") and area.Name:find("PlayerArea") then
                self:ProcessAreaNameplate(area)
            end
        end
        
        -- Listen for new nameplates
        playerAreas.DescendantAdded:Connect(function(descendant)
            if descendant.Name == "AreaNameplate" then
                task.wait(0.1) -- Wait for server to set up the nameplate
                local area = descendant.Parent
                if area and area:IsA("Model") and area.Name:find("PlayerArea") then
                    self:ProcessAreaNameplate(area)
                end
            end
        end)
    end)
end

function AreaNameplateService:ProcessAreaNameplate(area)
    local nameplatePart = area:FindFirstChild("AreaNameplate")
    if not nameplatePart then
        return
    end
    
    local billboard = nameplatePart:FindFirstChild("NameplateBillboard")
    if not billboard then
        return
    end
    
    -- Make it much bigger
    billboard.Size = UDim2.new(0, 600, 0, 150) -- 3x width, 3x height
    billboard.StudsOffset = Vector3.new(0, 30, 0) -- Higher above area
    billboard.MaxDistance = math.huge -- Visible from anywhere on the map
    billboard.AlwaysOnTop = false -- Don't show through walls
    
    local textLabel = billboard:FindFirstChildOfClass("TextLabel")
    if not textLabel then
        return
    end
    
    -- Check if this is the player's own area or unassigned
    local isOwnArea = textLabel.Text:find(player.Name)
    local isUnassigned = textLabel.Text:find("Unassigned")
    
    -- Set text size based on area type
    if isUnassigned then
        textLabel.TextSize = 36 -- Much smaller for unassigned (50% of normal)
    elseif isOwnArea then
        textLabel.TextSize = 96 -- Biggest for own area
    else
        textLabel.TextSize = 72 -- Normal size for other player areas
    end
    
    -- ALWAYS ensure black outline is applied (for all areas including rainbow)
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    
    if isOwnArea then
        -- Add rainbow gradient for own area
        local textGradient = Instance.new("UIGradient")
        textGradient.Color = createRainbowSequence()
        textGradient.Rotation = 0
        textGradient.Parent = textLabel
        
        -- IMPORTANT: Re-apply black outline after gradient (gradients can override stroke)
        textLabel.TextStrokeTransparency = 0
        textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        
        -- Animate the gradient
        local connection
        connection = RunService.Heartbeat:Connect(function(deltaTime)
            if not textGradient.Parent then
                connection:Disconnect()
                return
            end
            
            textGradient.Rotation = (textGradient.Rotation + 60 * deltaTime) % 360
            
            -- Ensure stroke stays visible during animation
            textLabel.TextStrokeTransparency = 0
            textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        end)
    end
end

function AreaNameplateService:Cleanup()
    -- Cleanup handled by individual connections
end

return AreaNameplateService