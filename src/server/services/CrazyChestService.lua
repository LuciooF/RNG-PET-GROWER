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
    
    local upgradeChestRemote = ReplicatedStorage:FindFirstChild("UpgradeCrazyChest")
    if not upgradeChestRemote then
        upgradeChestRemote = Instance.new("RemoteEvent")
        upgradeChestRemote.Name = "UpgradeCrazyChest"
        upgradeChestRemote.Parent = ReplicatedStorage
    end
    
    local upgradeLuckRemote = ReplicatedStorage:FindFirstChild("UpgradeCrazyChestLuck")
    if not upgradeLuckRemote then
        upgradeLuckRemote = Instance.new("RemoteEvent")
        upgradeLuckRemote.Name = "UpgradeCrazyChestLuck"
        upgradeLuckRemote.Parent = ReplicatedStorage
    end
    
    local upgradeSuccessRemote = ReplicatedStorage:FindFirstChild("CrazyChestUpgradeSuccess")
    if not upgradeSuccessRemote then
        upgradeSuccessRemote = Instance.new("RemoteEvent")
        upgradeSuccessRemote.Name = "CrazyChestUpgradeSuccess"
        upgradeSuccessRemote.Parent = ReplicatedStorage
    end
    
    -- Handle chest opening requests
    openChestRemote.OnServerEvent:Connect(function(player)
        self:HandleChestOpen(player, false) -- false = diamond purchase
    end)
    
    -- Handle reward claiming after animation
    claimRewardRemote.OnServerEvent:Connect(function(player, roll, rewardType)
        self:ClaimReward(player, roll, rewardType)
    end)
    
    -- Handle chest upgrading
    upgradeChestRemote.OnServerEvent:Connect(function(player)
        self:HandleChestUpgrade(player)
    end)
    
    -- Handle luck upgrading
    upgradeLuckRemote.OnServerEvent:Connect(function(player)
        self:HandleLuckUpgrade(player)
    end)
end

function CrazyChestService:HandleChestOpen(player, isRobuxPurchase)
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
    
    -- Skip affordability check and deduction for Robux purchases
    if not isRobuxPurchase then
        -- Check if player can afford it (diamonds only)
        local currentDiamonds = playerData.Resources.Diamonds or 0
        if currentDiamonds < cost then
            warn("CrazyChestService: Player", player.Name, "cannot afford chest (has", currentDiamonds, "needs", cost, ")")
            -- Sync to revert any optimistic client updates
            DataService:SyncPlayerDataToClient(player)
            return
        end
        
        -- Deduct cost (diamonds only)
        local success = DataService:UpdatePlayerResources(player, "Diamonds", -cost)
        if not success then
            warn("CrazyChestService: Failed to deduct diamonds from", player.Name)
            -- Important: If we can't deduct, we need to sync to revert any optimistic client updates
            DataService:SyncPlayerDataToClient(player)
            return
        end
    end
    
    -- Generate random roll (1-100)
    local roll = math.random(1, 100)
    
    -- Get luck multiplier
    local luckMultiplier = DataService:GetChestLuckMultiplier(player)
    
    -- Get reward based on roll with luck adjustment
    local baseReward = CrazyChestConfig.getLuckAdjustedRewardForRoll(roll, luckMultiplier)
    
    -- Apply chest level multiplier
    local rewardMultiplier = DataService:GetChestRewardMultiplier(player)
    local reward = {}
    
    -- Copy base reward and apply multiplier
    for key, value in pairs(baseReward) do
        reward[key] = value
    end
    
    -- Apply multiplier to all reward amounts including pet boosts
    if reward.type == "money" then
        reward.money = math.floor(reward.money * rewardMultiplier)
    elseif reward.type == "diamonds" then
        reward.diamonds = math.floor(reward.diamonds * rewardMultiplier)
    elseif reward.type == "pet" then
        reward.boost = math.floor(reward.boost * rewardMultiplier)
    end
    
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
        -- Player will win money reward
    elseif reward.type == "diamonds" then
        -- Player will win diamonds reward
    elseif reward.type == "pet" then
        -- Player will win pet reward
    end
    
    -- Add the reward key to the reward data so client can claim it
    reward.rewardKey = rewardKey
    
    -- Send result to client for animation
    local chestResultRemote = ReplicatedStorage:FindFirstChild("CrazyChestResult")
    if chestResultRemote then
        -- Sending chest result to client
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
        local boostValue = reward.boost or 5
        local petData = {
            Name = reward.petName,
            Rarity = {
                RarityName = "Legendary", -- Since it's from a chest, make it special
                RarityChance = 5, -- Match the 5% chance from config
                RarityColor = reward.color or Color3.fromRGB(255, 100, 50) -- Use reward color
            },
            Variation = {
                VariationName = boostValue .. "x Boost",
                VariationChance = 100,
                VariationMultiplier = boostValue,
                VariationColor = reward.color or Color3.fromRGB(255, 100, 50)
            },
            BaseValue = reward.value or 1000,
            BaseBoost = boostValue,
            -- IMPORTANT: Add FinalBoost and FinalValue for proper sorting in auto-equip
            FinalBoost = boostValue, -- Since variation multiplier is the same as boost for chest pets
            FinalValue = (reward.value or 1000) * boostValue,
            ID = game:GetService("HttpService"):GenerateGUID()
        }
        
        print("CrazyChestService: Adding chest pet with FinalBoost:", petData.FinalBoost, "BaseBoost:", petData.BaseBoost)
        
        local success = DataService:AddPetToPlayer(player, petData)
        if success then
            print("CrazyChestService:", player.Name, "claimed", reward.boost .. "x", reward.petName, "from chest")
            -- DataService:AddPetToPlayer already handles auto-equip via ScheduleDebouncedAutoEquip
            -- which will only equip if the pet is better than current equipped pets
        else
            warn("CrazyChestService: Failed to add pet to player", player.Name)
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

-- Handle chest upgrade requests
function CrazyChestService:HandleChestUpgrade(player)
    print("🎯 CrazyChestService:HandleChestUpgrade called for", player.Name)
    if not player or not player.Parent then
        print("🎯 Player validation failed")
        return false
    end
    
    print("🎯 Calling DataService:UpgradeCrazyChest...")
    local success, message = DataService:UpgradeCrazyChest(player)
    print("🎯 DataService upgrade result:", success, message)
    
    -- Fire success event to client for sound/UI updates
    if success then
        local upgradeSuccessRemote = ReplicatedStorage:FindFirstChild("CrazyChestUpgradeSuccess")
        if upgradeSuccessRemote then
            print("🎯 Firing success event to client")
            upgradeSuccessRemote:FireClient(player, "level")
        else
            warn("🎯 CrazyChestUpgradeSuccess remote not found!")
        end
    end
    
    return success
end

-- Handle luck upgrade requests
function CrazyChestService:HandleLuckUpgrade(player)
    print("🍀 CrazyChestService:HandleLuckUpgrade called for", player.Name)
    if not player or not player.Parent then
        print("🍀 Player validation failed")
        return false
    end
    
    print("🍀 Calling DataService:UpgradeCrazyChestLuck...")
    local success, message = DataService:UpgradeCrazyChestLuck(player)
    print("🍀 DataService upgrade result:", success, message)
    
    -- Fire success event to client for sound/UI updates
    if success then
        local upgradeSuccessRemote = ReplicatedStorage:FindFirstChild("CrazyChestUpgradeSuccess")
        if upgradeSuccessRemote then
            print("🍀 Firing success event to client")
            upgradeSuccessRemote:FireClient(player, "luck")
        else
            warn("🍀 CrazyChestUpgradeSuccess remote not found!")
        end
    end
    
    return success
end

-- Handle chest upgrade via Robux (no diamond cost)
function CrazyChestService:HandleChestUpgradeRobux(player)
    print("🎯💎 CrazyChestService:HandleChestUpgradeRobux called for", player.Name)
    if not player or not player.Parent then
        print("🎯💎 Player validation failed")
        return false
    end
    
    print("🎯💎 Calling DataService:UpgradeCrazyChestRobux...")
    local success, message = DataService:UpgradeCrazyChestRobux(player)
    print("🎯💎 DataService robux upgrade result:", success, message)
    
    -- Fire success event to client for sound/UI updates
    if success then
        local upgradeSuccessRemote = ReplicatedStorage:FindFirstChild("CrazyChestUpgradeSuccess")
        if upgradeSuccessRemote then
            print("🎯💎 Firing success event to client")
            upgradeSuccessRemote:FireClient(player, "level")
        else
            warn("🎯💎 CrazyChestUpgradeSuccess remote not found!")
        end
    end
    
    return success
end

-- Handle luck upgrade via Robux (no diamond cost)
function CrazyChestService:HandleLuckUpgradeRobux(player)
    print("🍀💎 CrazyChestService:HandleLuckUpgradeRobux called for", player.Name)
    if not player or not player.Parent then
        print("🍀💎 Player validation failed")
        return false
    end
    
    print("🍀💎 Calling DataService:UpgradeCrazyChestLuckRobux...")
    local success, message = DataService:UpgradeCrazyChestLuckRobux(player)
    print("🍀💎 DataService robux upgrade result:", success, message)
    
    -- Fire success event to client for sound/UI updates
    if success then
        local upgradeSuccessRemote = ReplicatedStorage:FindFirstChild("CrazyChestUpgradeSuccess")
        if upgradeSuccessRemote then
            print("🍀💎 Firing success event to client")
            upgradeSuccessRemote:FireClient(player, "luck")
        else
            warn("🍀💎 CrazyChestUpgradeSuccess remote not found!")
        end
    end
    
    return success
end

return CrazyChestService