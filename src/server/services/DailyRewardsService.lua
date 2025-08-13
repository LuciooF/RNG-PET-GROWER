-- DailyRewardsService - Handles daily login rewards with streak tracking
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local DailyRewardsConfig = require(ReplicatedStorage.config.DailyRewardsConfig)

local DailyRewardsService = {}
DailyRewardsService.__index = DailyRewardsService

function DailyRewardsService:Initialize()
    print("DailyRewardsService: Initialized")
    
    -- Set up remote events
    self:SetupRemoteEvents()
end

function DailyRewardsService:SetupRemoteEvents()
    -- Create remote events for daily rewards
    local claimDailyRewardRemote = Instance.new("RemoteFunction")
    claimDailyRewardRemote.Name = "ClaimDailyReward"
    claimDailyRewardRemote.Parent = ReplicatedStorage
    
    local getDailyRewardsStatusRemote = Instance.new("RemoteFunction")
    getDailyRewardsStatusRemote.Name = "GetDailyRewardsStatus"
    getDailyRewardsStatusRemote.Parent = ReplicatedStorage
    
    local debugSetLastLoginYesterdayRemote = Instance.new("RemoteFunction")
    debugSetLastLoginYesterdayRemote.Name = "DebugSetLastLoginYesterday"
    debugSetLastLoginYesterdayRemote.Parent = ReplicatedStorage
    
    local debugResetDailyRewardsRemote = Instance.new("RemoteFunction")
    debugResetDailyRewardsRemote.Name = "DebugResetDailyRewards"
    debugResetDailyRewardsRemote.Parent = ReplicatedStorage
    
    local debugIncrementStreakRemote = Instance.new("RemoteFunction")
    debugIncrementStreakRemote.Name = "DebugIncrementStreak"
    debugIncrementStreakRemote.Parent = ReplicatedStorage
    
    -- Handle claiming daily rewards
    claimDailyRewardRemote.OnServerInvoke = function(player, dayNumber)
        return self:ClaimDailyReward(player, dayNumber)
    end
    
    -- Handle getting daily rewards status
    getDailyRewardsStatusRemote.OnServerInvoke = function(player)
        return self:GetDailyRewardsStatus(player)
    end
    
    -- Handle debug: set last login to yesterday
    debugSetLastLoginYesterdayRemote.OnServerInvoke = function(player)
        local AuthorizationUtils = require(ReplicatedStorage.utils.AuthorizationUtils)
        if not AuthorizationUtils.isAuthorized(player) then
            AuthorizationUtils.logUnauthorizedAccess(player, "debug set last login yesterday")
            return false
        end
        return self:DebugSetLastLoginYesterday(player)
    end
    
    -- Handle debug: reset daily rewards
    debugResetDailyRewardsRemote.OnServerInvoke = function(player)
        local AuthorizationUtils = require(ReplicatedStorage.utils.AuthorizationUtils)
        if not AuthorizationUtils.isAuthorized(player) then
            AuthorizationUtils.logUnauthorizedAccess(player, "debug reset daily rewards")
            return false
        end
        return self:DebugResetDailyRewards(player)
    end
    
    -- Handle debug: increment streak
    debugIncrementStreakRemote.OnServerInvoke = function(player)
        local AuthorizationUtils = require(ReplicatedStorage.utils.AuthorizationUtils)
        if not AuthorizationUtils.isAuthorized(player) then
            AuthorizationUtils.logUnauthorizedAccess(player, "debug increment streak")
            return false
        end
        return self:DebugIncrementStreak(player)
    end
end

-- Update player's login streak when they join
function DailyRewardsService:UpdatePlayerLoginStreak(player)
    local DataService = require(script.Parent.DataService)
    local profile = DataService:GetPlayerProfile(player)
    
    if not profile then
        return false
    end
    
    -- Initialize DailyRewards if it doesn't exist (for existing saves)
    if not profile.Data.DailyRewards then
        profile.Data.DailyRewards = {
            LastLoginTime = nil,
            CurrentStreak = 0,
            ClaimedDays = {},
            StreakStartTime = nil
        }
    end
    
    local currentTime = os.time()
    local lastLoginTime = profile.Data.DailyRewards.LastLoginTime
    local dayInSeconds = 24 * 60 * 60
    
    -- If this is first login or more than 1 day since last login, handle streak
    if not lastLoginTime then
        -- First time login - start streak at 1 and allow immediate claiming
        profile.Data.DailyRewards.CurrentStreak = 1
        profile.Data.DailyRewards.StreakStartTime = currentTime
        profile.Data.DailyRewards.ClaimedDays = {} -- Reset claimed days
    else
        local timeSinceLastLogin = currentTime - lastLoginTime
        local daysSinceLastLogin = math.floor(timeSinceLastLogin / dayInSeconds)
        
        if daysSinceLastLogin > 1 then
            -- Streak broken - reset to day 1
            profile.Data.DailyRewards.CurrentStreak = 1
            profile.Data.DailyRewards.StreakStartTime = currentTime
            profile.Data.DailyRewards.ClaimedDays = {} -- Reset claimed days
        elseif daysSinceLastLogin == 1 then
            -- Exactly 1 day - can potentially continue streak (if they claim today)
            -- Don't increment streak yet - wait for them to claim
        else
            -- Same day - no change needed
        end
    end
    
    -- Update last login time to current time for all users
    profile.Data.DailyRewards.LastLoginTime = currentTime
    
    -- Sync to client
    DataService:SyncPlayerDataToClient(player)
    
    return true
end

-- Claim a daily reward
function DailyRewardsService:ClaimDailyReward(player, dayNumber)
    if not player or not dayNumber then
        return {success = false, message = "Invalid parameters"}
    end
    
    local DataService = require(script.Parent.DataService)
    local profile = DataService:GetPlayerProfile(player)
    
    if not profile then
        return {success = false, message = "Player profile not found"}
    end
    
    -- Initialize DailyRewards if it doesn't exist
    if not profile.Data.DailyRewards then
        profile.Data.DailyRewards = {
            LastLoginTime = os.time(),
            CurrentStreak = 1,
            ClaimedDays = {},
            StreakStartTime = os.time()
        }
    end
    
    -- Get current streak status
    local streakStatus = self:CalculateStreakStatus(player)
    
    -- Validate that they can claim this day
    if not streakStatus.canClaim then
        return {success = false, message = "Cannot claim reward yet - come back tomorrow!"}
    end
    
    if dayNumber ~= streakStatus.nextRewardDay then
        return {success = false, message = "Invalid day to claim - expected day " .. streakStatus.nextRewardDay}
    end
    
    -- Check if already claimed this day
    if profile.Data.DailyRewards.ClaimedDays[dayNumber] then
        return {success = false, message = "Already claimed reward for day " .. dayNumber}
    end
    
    -- Get reward configuration
    local reward = DailyRewardsConfig.getRewardByDay(dayNumber)
    if not reward then
        return {success = false, message = "Invalid reward day"}
    end
    
    -- Grant the OP pet reward
    local success = false
    
    if reward.type == "Pet" then
        -- Create OP pet reward with special "Daily Reward" rarity and variation
        success = true -- Assume success unless pet creation fails
        
        for i = 1, reward.amount do
            local petData = {
                Name = reward.petName,
                Rarity = {
                    RarityName = "Daily Reward",
                    RarityChance = 100,
                    RarityColor = Color3.fromRGB(255, 215, 0) -- Gold color for daily reward pets
                },
                Variation = {
                    VariationName = "Daily Login",
                    VariationChance = 100,
                    VariationColor = Color3.fromRGB(255, 100, 255), -- Pink/magenta color for daily pets
                    VariationMultiplier = 1
                },
                BaseValue = reward.value,
                BaseBoost = reward.boost,
                FinalValue = reward.value,
                FinalBoost = reward.boost,
                ID = HttpService:GenerateGUID()
            }
            
            local petSuccess, reason = DataService:AddPetToPlayer(player, petData)
            if not petSuccess then
                success = false
                return {success = false, message = "Failed to grant pet: " .. (reason or "Unknown error")}
            end
        end
    end
    
    if not success then
        return {success = false, message = "Failed to grant reward"}
    end
    
    -- Mark day as claimed
    profile.Data.DailyRewards.ClaimedDays[dayNumber] = true
    
    -- Update current streak to the claimed day
    profile.Data.DailyRewards.CurrentStreak = dayNumber
    
    -- CRITICAL: Update last login time to NOW to prevent claiming multiple rewards
    profile.Data.DailyRewards.LastLoginTime = os.time()
    
    -- Sync to client
    DataService:SyncPlayerDataToClient(player)
    
    return {
        success = true, 
        message = "Daily reward claimed successfully!",
        reward = reward,
        newStreak = dayNumber
    }
end

-- Calculate current streak status for a player
function DailyRewardsService:CalculateStreakStatus(player)
    local DataService = require(script.Parent.DataService)
    local profile = DataService:GetPlayerProfile(player)
    
    if not profile or not profile.Data.DailyRewards then
        return {
            currentStreak = 1,
            canClaim = true,
            streakBroken = false,
            nextRewardDay = 1,
            claimedDays = {}
        }
    end
    
    local dailyData = profile.Data.DailyRewards
    local currentTime = os.time()
    local lastLoginTime = dailyData.LastLoginTime
    local claimedDays = dailyData.ClaimedDays or {}
    
    -- Use config function to calculate status
    local status = DailyRewardsConfig.calculateStreakStatus(lastLoginTime, claimedDays)
    status.claimedDays = claimedDays -- Add claimed days to response
    
    return status
end

-- Get daily rewards status for a player (used by client)
function DailyRewardsService:GetDailyRewardsStatus(player)
    local streakStatus = self:CalculateStreakStatus(player)
    local allRewards = DailyRewardsConfig.getAllRewards()
    
    -- Build reward status list
    local rewardStatuses = {}
    for _, reward in ipairs(allRewards) do
        local status = "locked" -- Default to locked
        
        if streakStatus.claimedDays[reward.day] then
            status = "claimed"
        elseif reward.day == streakStatus.nextRewardDay and streakStatus.canClaim then
            status = "available"
        elseif reward.day < streakStatus.nextRewardDay then
            status = "missed" -- They could have claimed this but missed it
        end
        
        table.insert(rewardStatuses, {
            day = reward.day,
            status = status,
            reward = reward
        })
    end
    
    return {
        currentStreak = streakStatus.currentStreak,
        nextRewardDay = streakStatus.nextRewardDay,
        canClaim = streakStatus.canClaim,
        streakBroken = streakStatus.streakBroken,
        rewardStatuses = rewardStatuses
    }
end

-- Check if player has any claimable rewards (for UI notifications)
function DailyRewardsService:HasClaimableRewards(player)
    local streakStatus = self:CalculateStreakStatus(player)
    return streakStatus.canClaim and streakStatus.nextRewardDay <= 10
end

-- Debug function: Set last login time to 1 day ago to test claiming
function DailyRewardsService:DebugSetLastLoginYesterday(player)
    local DataService = require(script.Parent.DataService)
    local profile = DataService:GetPlayerProfile(player)
    
    if not profile then
        return false
    end
    
    -- Initialize DailyRewards if it doesn't exist
    if not profile.Data.DailyRewards then
        profile.Data.DailyRewards = {
            LastLoginTime = nil,
            CurrentStreak = 0,
            ClaimedDays = {},
            StreakStartTime = nil
        }
    end
    
    -- Set last login time to exactly 24 hours ago
    local dayInSeconds = 24 * 60 * 60
    profile.Data.DailyRewards.LastLoginTime = os.time() - dayInSeconds
    
    -- Sync to client
    DataService:SyncPlayerDataToClient(player)
    
    return true
end

-- Debug function: Reset daily rewards data completely
function DailyRewardsService:DebugResetDailyRewards(player)
    local DataService = require(script.Parent.DataService)
    local profile = DataService:GetPlayerProfile(player)
    
    if not profile then
        return false
    end
    
    -- Reset daily rewards data completely
    profile.Data.DailyRewards = {
        LastLoginTime = nil,
        CurrentStreak = 0,
        ClaimedDays = {},
        StreakStartTime = nil
    }
    
    -- Sync to client
    DataService:SyncPlayerDataToClient(player)
    
    return true
end

-- Debug function: Simulate moving forward one day (allows claiming next reward)
function DailyRewardsService:DebugIncrementStreak(player)
    local DataService = require(script.Parent.DataService)
    local profile = DataService:GetPlayerProfile(player)
    
    if not profile then
        return false
    end
    
    -- Initialize DailyRewards if it doesn't exist
    if not profile.Data.DailyRewards then
        profile.Data.DailyRewards = {
            LastLoginTime = os.time(),
            CurrentStreak = 0,
            ClaimedDays = {},
            StreakStartTime = nil
        }
    end
    
    -- Get current status
    local currentTime = os.time()
    local dayInSeconds = 24 * 60 * 60
    local lastLoginTime = profile.Data.DailyRewards.LastLoginTime or currentTime
    
    -- Calculate what day we're on
    local maxClaimedDay = 0
    for day, _ in pairs(profile.Data.DailyRewards.ClaimedDays or {}) do
        maxClaimedDay = math.max(maxClaimedDay, day)
    end
    
    -- If player has already claimed today's reward, we need to "move forward" in time
    local timeSinceLastLogin = currentTime - lastLoginTime
    local daysSinceLastLogin = math.floor(timeSinceLastLogin / dayInSeconds)
    
    if daysSinceLastLogin == 0 and maxClaimedDay > 0 then
        -- Player already claimed today, so simulate moving to tomorrow
        -- Set last login to exactly 24 hours ago so they can claim ONE more reward
        profile.Data.DailyRewards.LastLoginTime = currentTime - dayInSeconds
        -- Time travel simulated
    else
        -- Player hasn't claimed today yet, just let them claim current day
    end
    
    -- Sync to client
    DataService:SyncPlayerDataToClient(player)
    
    return true
end

return DailyRewardsService