-- PlayerRankGUIService - Shows rank GUI above all players' heads based on rebirth count
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DataSyncService = require(script.Parent.DataSyncService)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local RankUtils = require(ReplicatedStorage.utils.RankUtils)
local store = require(ReplicatedStorage.store)

local PlayerRankGUIService = {}
PlayerRankGUIService.__index = PlayerRankGUIService

local player = Players.LocalPlayer
local activeGUIs = {} -- Track active GUIs for cleanup
local connections = {}

-- Distance settings
local SHOW_DISTANCE = 80 -- Show when within 80 studs
local HIDE_DISTANCE = 100 -- Hide when beyond 100 studs

function PlayerRankGUIService:Initialize()
    -- Wait a bit for the game to fully load
    task.wait(2)
    
    -- Create GUIs for ALL players (including local player for 3rd person view)
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        self:CreatePlayerRankGUI(targetPlayer)
    end
    
    -- Handle new players joining
    connections.playerAdded = Players.PlayerAdded:Connect(function(newPlayer)
        task.wait(1) -- Wait for character to load
        self:CreatePlayerRankGUI(newPlayer)
    end)
    
    -- Handle players leaving
    connections.playerRemoving = Players.PlayerRemoving:Connect(function(leavingPlayer)
        self:RemovePlayerRankGUI(leavingPlayer)
    end)
    
    -- Listen for Rodux store changes to update ranks in real-time
    connections.storeConnection = store.changed:connect(function(newState, oldState)
        -- Only update for local player since we only get local player's data
        local newPlayerData = newState.player
        local oldPlayerData = oldState.player
        
        -- Check if rebirth count actually changed
        local newRebirths = (newPlayerData and newPlayerData.Resources and newPlayerData.Resources.Rebirths) or 0
        local oldRebirths = (oldPlayerData and oldPlayerData.Resources and oldPlayerData.Resources.Rebirths) or 0
        
        if newRebirths ~= oldRebirths then
            self:UpdatePlayerRankGUI(player, newPlayerData)
        end
    end)
    
    -- Update distance checking every frame
    connections.heartbeat = RunService.Heartbeat:Connect(function()
        self:UpdateGUIVisibility()
    end)
    
    -- Service initialized successfully
end

-- Get rank info based on rebirth count (use shared utility)
function PlayerRankGUIService:GetRankInfo(rebirthCount)
    return RankUtils.getRankInfo(rebirthCount)
end

-- Create rank GUI for a specific player
function PlayerRankGUIService:CreatePlayerRankGUI(targetPlayer)
    if activeGUIs[targetPlayer] then
        return -- Already has GUI
    end
    
    -- Wait for character and head
    if not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("Head") then
        -- Wait for character to spawn
        local connection
        connection = targetPlayer.CharacterAdded:Connect(function(character)
            connection:Disconnect()
            task.wait(0.5) -- Wait for character to fully load
            if targetPlayer.Parent then -- Make sure player didn't leave
                self:CreatePlayerRankGUI(targetPlayer)
            end
        end)
        return
    end
    
    local character = targetPlayer.Character
    local head = character:FindFirstChild("Head")
    if not head then 
        return 
    end
    
    -- Get player's rebirth count
    local rebirthCount = 0
    
    if targetPlayer == player then
        -- For local player, use local data
        local success, playerData = pcall(function()
            return DataSyncService:GetPlayerData()
        end)
        
        if success and playerData and playerData.Resources then
            rebirthCount = playerData.Resources.Rebirths or 0
        end
    else
        -- For other players, get data from server
        local remote = ReplicatedStorage:FindFirstChild("GetPlayerRebirths")
        if remote and remote:IsA("RemoteFunction") then
            local success, serverRebirthCount = pcall(function()
                return remote:InvokeServer(targetPlayer.UserId)
            end)
            
            if success and serverRebirthCount then
                rebirthCount = serverRebirthCount
            end
        else
            -- Default to 0 if remote not found
            rebirthCount = 0
        end
    end
    
    -- Get rank info
    local rankInfo = self:GetRankInfo(rebirthCount)
    
    -- Create BillboardGui with NO distance scaling
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "PlayerRankGUI"
    -- Fixed size in studs - this prevents distance scaling
    billboardGui.Size = UDim2.new(4, 0, 2, 0) -- 4x2 studs, constant size regardless of distance
    billboardGui.StudsOffset = Vector3.new(0, 5.5, 0) -- 1.5 studs higher
    billboardGui.LightInfluence = 0 -- Always visible regardless of lighting
    billboardGui.AlwaysOnTop = false -- Don't force on top
    billboardGui.MaxDistance = 200 -- Max distance to render
    billboardGui.Enabled = true -- Start visible for testing
    
    -- Attach to HumanoidRootPart instead of head for more stability
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        billboardGui.Parent = rootPart
    else
        billboardGui.Parent = head
    end
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.Parent = billboardGui
    
    -- Username label (top line)
    local usernameLabel = Instance.new("TextLabel")
    usernameLabel.Name = "UsernameLabel"
    usernameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    usernameLabel.Position = UDim2.new(0, 0, 0, 0)
    usernameLabel.BackgroundTransparency = 1
    usernameLabel.Text = targetPlayer.DisplayName or targetPlayer.Name
    usernameLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
    usernameLabel.TextSize = ScreenUtils.getTextSize(28) -- Halfway between 32 and 24
    usernameLabel.Font = Enum.Font.FredokaOne
    usernameLabel.TextXAlignment = Enum.TextXAlignment.Center
    usernameLabel.TextYAlignment = Enum.TextYAlignment.Center
    usernameLabel.TextStrokeTransparency = 0
    usernameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0) -- Black outline
    usernameLabel.TextScaled = false -- Don't scale with size
    usernameLabel.Parent = mainFrame
    
    -- Thicker outline for username
    local usernameStroke = Instance.new("UIStroke")
    usernameStroke.Color = Color3.fromRGB(0, 0, 0) -- Black outline
    usernameStroke.Thickness = ScreenUtils.getProportionalSize(2) -- Thinner outline
    usernameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    usernameStroke.Parent = usernameLabel
    
    -- Rank label (bottom line)
    local rankLabel = Instance.new("TextLabel")
    rankLabel.Name = "RankLabel"
    rankLabel.Size = UDim2.new(1, 0, 0.5, 0)
    rankLabel.Position = UDim2.new(0, 0, 0.5, 0)
    rankLabel.BackgroundTransparency = 1
    rankLabel.Text = rankInfo.emoji .. " " .. rankInfo.name .. " " .. rankInfo.emoji
    rankLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
    rankLabel.TextSize = ScreenUtils.getTextSize(24) -- Halfway between 28 and 20
    rankLabel.Font = Enum.Font.FredokaOne
    rankLabel.TextXAlignment = Enum.TextXAlignment.Center
    rankLabel.TextYAlignment = Enum.TextYAlignment.Center
    rankLabel.TextStrokeTransparency = 0
    rankLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0) -- Black outline
    rankLabel.TextScaled = false -- Don't scale with size
    rankLabel.Parent = mainFrame
    
    -- Thicker outline for rank
    local rankStroke = Instance.new("UIStroke")
    rankStroke.Color = Color3.fromRGB(0, 0, 0) -- Black outline
    rankStroke.Thickness = ScreenUtils.getProportionalSize(2) -- Thinner outline
    rankStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    rankStroke.Parent = rankLabel
    
    -- Store GUI reference
    activeGUIs[targetPlayer] = {
        gui = billboardGui,
        character = character,
        visible = true -- Start visible for testing
    }
    
    -- GUI created successfully
end

-- Update rank GUI for a specific player when their data changes
function PlayerRankGUIService:UpdatePlayerRankGUI(targetPlayer, newData)
    local guiData = activeGUIs[targetPlayer]
    if not guiData or not guiData.gui then
        self:CreatePlayerRankGUI(targetPlayer)
        return
    end
    
    -- Get new rebirth count
    local rebirthCount = 0
    if newData and newData.Resources then
        rebirthCount = newData.Resources.Rebirths or 0
    end
    
    -- Get new rank info
    local rankInfo = self:GetRankInfo(rebirthCount)
    
    -- Find and update the rank label
    local mainFrame = guiData.gui:FindFirstChild("MainFrame")
    if mainFrame then
        local rankLabel = mainFrame:FindFirstChild("RankLabel")
        if rankLabel then
            rankLabel.Text = rankInfo.emoji .. " " .. rankInfo.name .. " " .. rankInfo.emoji
        end
    end
end

-- Remove rank GUI for a specific player
function PlayerRankGUIService:RemovePlayerRankGUI(targetPlayer)
    if activeGUIs[targetPlayer] then
        if activeGUIs[targetPlayer].gui then
            activeGUIs[targetPlayer].gui:Destroy()
        end
        activeGUIs[targetPlayer] = nil
    end
end

-- Update GUI visibility based on distance
function PlayerRankGUIService:UpdateGUIVisibility()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local playerPosition = player.Character.HumanoidRootPart.Position
    
    for targetPlayer, guiData in pairs(activeGUIs) do
        if guiData.character and guiData.character:FindFirstChild("HumanoidRootPart") and guiData.gui then
            local targetPosition = guiData.character.HumanoidRootPart.Position
            local distance = (playerPosition - targetPosition).Magnitude
            
            -- Show/hide based on distance with hysteresis
            if not guiData.visible and distance <= SHOW_DISTANCE then
                guiData.gui.Enabled = true
                guiData.visible = true
            elseif guiData.visible and distance >= HIDE_DISTANCE then
                guiData.gui.Enabled = false
                guiData.visible = false
            end
        end
    end
end

-- Handle character respawn for existing players
function PlayerRankGUIService:HandleCharacterRespawn(targetPlayer)
    -- Remove old GUI if exists
    self:RemovePlayerRankGUI(targetPlayer)
    
    -- Wait a bit for character to fully load, then create new GUI
    task.wait(0.5)
    if targetPlayer.Parent then -- Make sure player didn't leave
        self:CreatePlayerRankGUI(targetPlayer)
    end
end

function PlayerRankGUIService:Cleanup()
    -- Disconnect all connections
    for name, connection in pairs(connections) do
        if connection then
            if name == "storeConnection" then
                -- Rodux connection uses lowercase disconnect
                connection:disconnect()
            else
                -- Regular Roblox connections use uppercase Disconnect
                connection:Disconnect()
            end
        end
    end
    connections = {}
    
    -- Clean up all active GUIs
    for targetPlayer, guiData in pairs(activeGUIs) do
        if guiData.gui then
            guiData.gui:Destroy()
        end
    end
    activeGUIs = {}
end

-- Handle character respawns for all players (including local player)
Players.PlayerAdded:Connect(function(newPlayer)
    newPlayer.CharacterAdded:Connect(function()
        PlayerRankGUIService:HandleCharacterRespawn(newPlayer)
    end)
end)

-- Handle existing players' character respawns (including local player)
for _, existingPlayer in pairs(Players:GetPlayers()) do
    existingPlayer.CharacterAdded:Connect(function()
        PlayerRankGUIService:HandleCharacterRespawn(existingPlayer)
    end)
end

return PlayerRankGUIService