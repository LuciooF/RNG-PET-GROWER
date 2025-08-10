-- LeaderboardService - Manages Roblox integrated leaderstats
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)

local LeaderboardService = {}


-- Create leaderstats for a player
function LeaderboardService:CreateLeaderstats(player)
    -- Creating leaderstats
    
    -- Create leaderstats folder
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player
    
    -- Create Rebirths stat (primary sort)
    local rebirths = Instance.new("IntValue")
    rebirths.Name = "Rebirths"
    rebirths.Value = 0
    rebirths.Parent = leaderstats
    
    -- Create Diamonds stat (secondary sort)
    local diamonds = Instance.new("StringValue")
    diamonds.Name = "Diamonds"
    diamonds.Value = "0"
    diamonds.Parent = leaderstats
    
    -- Create Money stat (display only, formatted)
    local money = Instance.new("StringValue")
    money.Name = "Money"
    money.Value = "0"
    money.Parent = leaderstats
    
    -- Leaderstats created
    return leaderstats, rebirths, diamonds, money
end

-- Update leaderstats with current player data
function LeaderboardService:UpdateLeaderstats(player, playerData)
    if not player or not player.Parent then
        return -- Player left
    end
    
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        print("LeaderboardService: No leaderstats found for", player.Name)
        return
    end
    
    local rebirthsStat = leaderstats:FindFirstChild("Rebirths")
    local diamondsStat = leaderstats:FindFirstChild("Diamonds")
    local moneyStat = leaderstats:FindFirstChild("Money")
    
    if rebirthsStat and playerData.Resources and playerData.Resources.Rebirths then
        rebirthsStat.Value = playerData.Resources.Rebirths
    end
    
    if diamondsStat and playerData.Resources and playerData.Resources.Diamonds then
        local formattedDiamonds = NumberFormatter.format(playerData.Resources.Diamonds)
        diamondsStat.Value = formattedDiamonds
    end
    
    if moneyStat and playerData.Resources and playerData.Resources.Money then
        local formattedMoney = NumberFormatter.format(playerData.Resources.Money)
        moneyStat.Value = formattedMoney
    end
end

-- Initialize leaderstats when player joins
function LeaderboardService:OnPlayerAdded(player)
    -- Player joined
    
    -- Create leaderstats immediately
    local leaderstats, rebirthsStat, diamondsStat, moneyStat = self:CreateLeaderstats(player)
    
    -- Store references for easy access
    player:SetAttribute("LeaderboardInitialized", true)
    
    return leaderstats
end

-- Cleanup when player leaves
function LeaderboardService:OnPlayerRemoving(player)
    -- Player leaving
    -- Leaderstats are automatically cleaned up by Roblox
end

-- Initialize the service
function LeaderboardService:Initialize()
    -- Connect to player events
    Players.PlayerAdded:Connect(function(player)
        self:OnPlayerAdded(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:OnPlayerRemoving(player)
    end)
    
    -- Handle players already in game
    for _, player in pairs(Players:GetPlayers()) do
        if not player:GetAttribute("LeaderboardInitialized") then
            self:OnPlayerAdded(player)
        end
    end
end

-- Update leaderstats for all players with their current data
function LeaderboardService:UpdateAllLeaderstats(playerDataMap)
    for player, playerData in pairs(playerDataMap) do
        if player and player.Parent then
            self:UpdateLeaderstats(player, playerData)
        end
    end
end

-- Get leaderboard data for debugging
function LeaderboardService:GetLeaderboardData()
    local leaderboardData = {}
    
    for _, player in pairs(Players:GetPlayers()) do
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            local rebirths = leaderstats:FindFirstChild("Rebirths")
            local money = leaderstats:FindFirstChild("Money")
            
            table.insert(leaderboardData, {
                playerName = player.Name,
                rebirths = rebirths and rebirths.Value or 0,
                money = money and money.Value or "0"
            })
        end
    end
    
    -- Sort by rebirths (descending)
    table.sort(leaderboardData, function(a, b)
        return a.rebirths > b.rebirths
    end)
    
    return leaderboardData
end

-- Manual refresh for testing
function LeaderboardService:RefreshLeaderboard()
    print("LeaderboardService: Manual refresh requested")
    
    -- Update all players' leaderstats with their current data
    for _, player in pairs(Players:GetPlayers()) do
        task.spawn(function()
            local DataService = require(script.Parent.DataService)
            local playerData = DataService:GetPlayerData(player)
            if playerData then
                self:UpdateLeaderstats(player, playerData)
            end
        end)
    end
end

-- Get formatted money for testing
function LeaderboardService:FormatMoney(amount)
    return NumberFormatter.format(amount)
end

return LeaderboardService