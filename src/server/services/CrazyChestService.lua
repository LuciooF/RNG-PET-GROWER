-- CrazyChestService - Server-side crazy chest logic and rewards
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DataService = require(script.Parent.DataService)
local CrazyChestConfig = require(ReplicatedStorage.config.CrazyChestConfig)

local CrazyChestService = {}
local initialized = false
local pendingRewards = {} -- Store rewards waiting to be claimed after animation

function CrazyChestService:Initialize()
    -- Prevent multiple initializations
    if initialized then
        warn("CrazyChestService: Already initialized, skipping")
        return
    end
    initialized = true
    
    print("CrazyChestService: Server initializing...")
    
    -- Create remote events
    local openChestRemote = ReplicatedStorage:FindFirstChild("OpenCrazyChest")
    if not openChestRemote then
        openChestRemote = Instance.new("RemoteEvent")
        openChestRemote.Name = "OpenCrazyChest"
        openChestRemote.Parent = ReplicatedStorage
    end
    
    local chestResultRemote = ReplicatedStorage:FindFirstChild("CrazyChestResult")
    if not chestResultRemote then
        chestResultRemote = Instance.new("RemoteEvent")
        chestResultRemote.Name = "CrazyChestResult"
        chestResultRemote.Parent = ReplicatedStorage
    end
    
    local claimRewardRemote = ReplicatedStorage:FindFirstChild("ClaimCrazyChestReward")
    if not claimRewardRemote then
        claimRewardRemote = Instance.new("RemoteEvent")
        claimRewardRemote.Name = "ClaimCrazyChestReward"
        claimRewardRemote.Parent = ReplicatedStorage
    end
    
    -- Handle chest opening requests
    openChestRemote.OnServerEvent:Connect(function(player)
        self:HandleChestOpen(player)
    end)
    
    -- Handle reward claiming after animation
    claimRewardRemote.OnServerEvent:Connect(function(player, roll, rewardType)
        self:ClaimReward(player, roll, rewardType)
    end)
end

function CrazyChestService:HandleChestOpen(player)
    -- Validate player
    if not player or not player.Parent then
        return
    end
    
    -- Get player data
    local playerData = DataService:GetPlayerData(player)
    if not playerData then
        warn("CrazyChestService: No player data for", player.Name)
        return
    end
    
    -- Calculate cost based on rebirths
    local rebirthCount = playerData.Resources.Rebirths or 0
    local cost = CrazyChestConfig.getCost(rebirthCount)
    
    -- Check if player can afford it
    local currentDiamonds = playerData.Resources.Diamonds or 0
    if currentDiamonds < cost then
        warn("CrazyChestService: Player", player.Name, "cannot afford chest (has", currentDiamonds, "needs", cost, ")")
        -- Sync to revert any optimistic client updates
        DataService:SyncPlayerDataToClient(player)
        return
    end
    
    -- Deduct cost
    local success = DataService:UpdatePlayerResources(player, "Diamonds", -cost)
    if not success then
        warn("CrazyChestService: Failed to deduct diamonds from", player.Name)
        -- Important: If we can't deduct, we need to sync to revert any optimistic client updates
        DataService:SyncPlayerDataToClient(player)
        return
    end
    
    -- Generate random roll (1-100)
    local roll = math.random(1, 100)
    
    -- Get reward based on roll
    local reward = CrazyChestConfig.getRewardForRoll(roll)
    
    -- Store the reward to be claimed after animation
    -- Use a unique key combining player ID and timestamp to handle multiple chests
    local rewardKey = player.UserId .. "_" .. tostring(tick())
    pendingRewards[rewardKey] = {
        player = player,
        reward = reward,
        timestamp = tick()
    }
    
    -- Log what they will win (but don't give it yet)
    if reward.type == "money" then
        print("CrazyChestService:", player.Name, "will win", reward.money, "money from chest (pending animation)")
    elseif reward.type == "diamonds" then
        print("CrazyChestService:", player.Name, "will win", reward.diamonds, "diamonds from chest (pending animation)")
    elseif reward.type == "pet" then
        print("CrazyChestService:", player.Name, "will win", reward.boost .. "x", reward.petName, "from chest (pending animation)")
    end
    
    -- Add the reward key to the reward data so client can claim it
    reward.rewardKey = rewardKey
    
    -- Send result to client for animation
    local chestResultRemote = ReplicatedStorage:FindFirstChild("CrazyChestResult")
    if chestResultRemote then
        print("CrazyChestService: Sending result to", player.Name, "- Roll:", roll)
        chestResultRemote:FireClient(player, roll, reward)
    else
        warn("CrazyChestService: CrazyChestResult remote not found!")
    end
end

function CrazyChestService:ClaimReward(player, rewardKey)
    -- Validate the reward key
    local pendingReward = pendingRewards[rewardKey]
    if not pendingReward then
        warn("CrazyChestService: No pending reward with key", rewardKey)
        return
    end
    
    -- Verify it's the correct player
    if pendingReward.player ~= player then
        warn("CrazyChestService: Player mismatch for reward key", rewardKey)
        return
    end
    
    -- Check if reward is too old (prevent exploits with old keys)
    if tick() - pendingReward.timestamp > 30 then -- 30 second timeout
        warn("CrazyChestService: Reward key expired", rewardKey)
        pendingRewards[rewardKey] = nil
        return
    end
    
    local reward = pendingReward.reward
    
    -- Now actually give the reward
    if reward.type == "money" then
        local success = DataService:UpdatePlayerResources(player, "Money", reward.money)
        if success then
            print("CrazyChestService:", player.Name, "claimed", reward.money, "money from chest")
        end
    elseif reward.type == "diamonds" then
        local success = DataService:UpdatePlayerResources(player, "Diamonds", reward.diamonds)
        if success then
            print("CrazyChestService:", player.Name, "claimed", reward.diamonds, "diamonds from chest")
        end
    elseif reward.type == "pet" then
        -- Give pet reward using proper petData structure
        local petData = {
            Name = reward.petName,
            Rarity = {
                RarityName = "Legendary", -- Since it's from a chest, make it special
                RarityChance = 5, -- Match the 5% chance from config
                RarityColor = reward.color or Color3.fromRGB(255, 100, 50) -- Use reward color
            },
            Variation = {
                VariationName = reward.boost .. "x Boost",
                VariationChance = 100,
                VariationMultiplier = reward.boost,
                VariationColor = reward.color or Color3.fromRGB(255, 100, 50)
            },
            BaseValue = reward.value or 1000,
            BaseBoost = reward.boost or 5,
            ID = game:GetService("HttpService"):GenerateGUID()
        }
        
        local success = DataService:AddPetToPlayer(player, petData)
        if success then
            print("CrazyChestService:", player.Name, "claimed", reward.boost .. "x", reward.petName, "from chest")
        end
    end
    
    -- Remove the pending reward
    pendingRewards[rewardKey] = nil
end

-- Clean up old pending rewards periodically
task.spawn(function()
    while true do
        task.wait(60) -- Check every minute
        local now = tick()
        for key, pendingReward in pairs(pendingRewards) do
            if now - pendingReward.timestamp > 60 then -- Remove rewards older than 1 minute
                print("CrazyChestService: Cleaning up expired reward", key)
                pendingRewards[key] = nil
            end
        end
    end
end)

return CrazyChestService