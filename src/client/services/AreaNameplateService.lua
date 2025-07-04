local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages.react)
local ReactRoblox = require(Packages["react-roblox"])

local AreaNameplate = require(script.Parent.Parent.components.AreaNameplate)

local AreaNameplateService = {}
AreaNameplateService.__index = AreaNameplateService

local player = Players.LocalPlayer
local nameplateRoots = {}
local connection = nil
local areaAssignments = {} -- Store area assignments from server
local areaNameplates = {} -- Store references to area nameplates for visibility management

-- Distance threshold for showing area GUIs (larger than plot GUIs)
local AREA_GUI_VISIBILITY_DISTANCE = 150

function AreaNameplateService:Initialize()
    print("AreaNameplateService: Initializing...")
    
    -- Wait for PlayerAreas to be created
    local playerAreas = Workspace:WaitForChild("PlayerAreas", 10)
    if not playerAreas then
        warn("AreaNameplateService: PlayerAreas not found!")
        return
    end
    
    -- Set up area assignment sync from server
    local areaAssignmentSync = ReplicatedStorage:WaitForChild("AreaAssignmentSync", 10)
    if areaAssignmentSync then
        areaAssignmentSync.OnClientEvent:Connect(function(assignmentData)
            areaAssignments = assignmentData
            self:UpdateAllNameplates()
            print("AreaNameplateService: Received area assignments from server")
        end)
    end
    
    -- Set up initial nameplates (will show "Unassigned" until server data arrives)
    self:UpdateAllNameplates()
    
    -- Start visibility update loop
    self:StartVisibilityUpdates()
    
    print("AreaNameplateService: Initialized successfully")
end

function AreaNameplateService:UpdateAllNameplates()
    local playerAreas = Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then return end
    
    for _, area in pairs(playerAreas:GetChildren()) do
        if area:IsA("Model") and area.Name:match("PlayerArea%d+") then
            local areaNumber = area:FindFirstChild("AreaNumber")
            if areaNumber and areaNumber:IsA("IntValue") then
                self:UpdateNameplateForArea(area, areaNumber.Value)
            end
        end
    end
end

function AreaNameplateService:UpdateNameplateForArea(area, areaNumber)
    local nameplateAnchor = area:FindFirstChild("NameplateAnchor")
    if not nameplateAnchor then return end
    
    -- Determine the player assigned to this area
    local assignedPlayerName = self:GetAssignedPlayerName(areaNumber)
    
    -- Create or update nameplate
    local existingNameplate = nameplateAnchor:FindFirstChild("AreaNameplate")
    
    if assignedPlayerName then
        if not existingNameplate then
            -- Create new nameplate
            self:CreateNameplate(nameplateAnchor, assignedPlayerName, areaNumber)
        else
            -- Update existing nameplate if player changed
            self:UpdateNameplateText(existingNameplate, assignedPlayerName)
            -- Ensure reference is stored for visibility management
            areaNameplates[areaNumber] = {
                gui = existingNameplate,
                anchor = nameplateAnchor
            }
        end
    else
        -- No player assigned, show "Unassigned"
        if not existingNameplate then
            self:CreateNameplate(nameplateAnchor, "Unassigned", areaNumber)
        else
            self:UpdateNameplateText(existingNameplate, "Unassigned")
            -- Ensure reference is stored for visibility management
            areaNameplates[areaNumber] = {
                gui = existingNameplate,
                anchor = nameplateAnchor
            }
        end
    end
end

function AreaNameplateService:CreateNameplate(anchor, playerName, areaNumber)
    -- Create BillboardGui directly
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "AreaNameplate"
    billboardGui.Size = UDim2.new(0, 300, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 0, 0)
    billboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    billboardGui.Enabled = false -- Start disabled, proximity will enable it
    billboardGui.Parent = anchor
    
    -- Single text label for everything
    local nameText = Instance.new("TextLabel")
    nameText.Name = "NameText"
    nameText.Size = UDim2.new(1, 0, 1, 0)
    nameText.Position = UDim2.new(0, 0, 0, 0)
    nameText.BackgroundTransparency = 1
    nameText.Text = playerName .. "'s Area"
    nameText.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameText.TextSize = 28
    nameText.TextWrapped = true
    nameText.TextXAlignment = Enum.TextXAlignment.Center
    nameText.TextYAlignment = Enum.TextYAlignment.Center
    nameText.Font = Enum.Font.GothamBold
    nameText.ZIndex = 2
    nameText.Parent = billboardGui
    
    -- Black text stroke
    local textStroke = Instance.new("UIStroke")
    textStroke.Color = Color3.fromRGB(0, 0, 0)
    textStroke.Thickness = 3
    textStroke.Transparency = 0
    textStroke.Parent = nameText
    
    -- Store reference for visibility management
    areaNameplates[areaNumber] = {
        gui = billboardGui,
        anchor = anchor
    }
    
    print(string.format("AreaNameplateService: Created nameplate for area %d with player %s", areaNumber, playerName))
end

function AreaNameplateService:UpdateNameplateText(nameplate, playerName)
    local nameText = nameplate:FindFirstChild("NameText")
    if nameText then
        local newText = playerName .. "'s Area"
        if nameText.Text ~= newText then
            nameText.Text = newText
            print(string.format("AreaNameplateService: Updated nameplate to show %s", newText))
        end
    end
end

function AreaNameplateService:GetAssignedPlayerName(areaNumber)
    -- Get player name from server assignment data
    local assignmentData = areaAssignments[areaNumber]
    if assignmentData and assignmentData.playerName then
        return assignmentData.playerName
    end
    
    return nil -- No player assigned to this area
end

-- Start visibility update loop
function AreaNameplateService:StartVisibilityUpdates()
    if connection then
        connection:Disconnect()
    end
    
    connection = RunService.Heartbeat:Connect(function()
        self:UpdateNameplateVisibility()
    end)
end

-- Update nameplate visibility based on player distance
function AreaNameplateService:UpdateNameplateVisibility()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local playerPosition = player.Character.HumanoidRootPart.Position
    
    for areaNumber, nameplateData in pairs(areaNameplates) do
        if nameplateData.gui and nameplateData.anchor and nameplateData.anchor.Parent then
            local distance = (playerPosition - nameplateData.anchor.Position).Magnitude
            local shouldBeVisible = distance <= AREA_GUI_VISIBILITY_DISTANCE
            
            nameplateData.gui.Enabled = shouldBeVisible
        else
            -- Clean up invalid references
            areaNameplates[areaNumber] = nil
        end
    end
end

-- Get visibility distance (for configuration)
function AreaNameplateService:getVisibilityDistance()
    return AREA_GUI_VISIBILITY_DISTANCE
end

-- Set visibility distance (for configuration)
function AreaNameplateService:setVisibilityDistance(distance)
    AREA_GUI_VISIBILITY_DISTANCE = distance
end

function AreaNameplateService:Cleanup()
    if connection then
        connection:Disconnect()
        connection = nil
    end
    
    for _, root in pairs(nameplateRoots) do
        if root then
            root:unmount()
        end
    end
    
    nameplateRoots = {}
    areaNameplates = {}
    print("AreaNameplateService: Cleaned up")
end

return AreaNameplateService