-- PlaytimeRewardsService - Handles playtime reward claiming with validation
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local PlaytimeRewardsConfig = require(ReplicatedStorage.config.PlaytimeRewardsConfig)

local PlaytimeRewardsService = {}
PlaytimeRewardsService.__index = PlaytimeRewardsService

function PlaytimeRewardsService:Initialize()
    print("PlaytimeRewardsService: Initialized")
end

-- Perform instant rebirth (same logic as Main.server.lua performRebirth function)
function PlaytimeRewardsService:PerformInstantRebirth(player)
    print("PlaytimeRewardsService: Instant rebirth for", player.Name)
    
    local DataService = require(script.Parent.DataService)
    local PetService = require(script.Parent.PetService)
    local PlotService = require(script.Parent.PlotService)
    local StateService = require(script.Parent.StateService)
    local LeaderboardService = require(script.Parent.LeaderboardService)
    
    -- Get player data
    local playerData = DataService:GetPlayerData(player)
    local profile = DataService:GetPlayerProfile(player)
    
    if not profile or not playerData then
        warn("PlaytimeRewardsService: No profile found for player", player.Name)
        return false
    end
    
    -- Perform rebirth - reset everything except rebirths
    local currentRebirths = playerData.Resources.Rebirths or 0
    local currentDiamonds = playerData.Resources.Diamonds or 0 -- Keep diamonds
    local currentEquippedPets = playerData.EquippedPets or {} -- Keep equipped pets
    local currentOPPets = playerData.OPPets or {} -- Keep OP pets (premium purchases)
    
    profile.Data.Resources = {
        Diamonds = currentDiamonds, -- Keep diamonds through rebirth
        Money = 0, -- Reset money to 0
        Rebirths = currentRebirths + 1
    }
    profile.Data.Pets = currentEquippedPets -- Only keep equipped pets
    profile.Data.EquippedPets = currentEquippedPets -- Keep equipped pets
    profile.Data.OPPets = currentOPPets -- Keep OP pets (they're premium purchases)
    profile.Data.ProcessingPets = {} -- Clear processing pets
    profile.Data.OwnedTubes = {}
    profile.Data.OwnedPlots = {}
    
    -- Stop any active heaven processing
    PetService:StopHeavenProcessing(player)
    
    -- Clear spawned pet balls in player's area
    PlotService:ClearAllPetBallsInPlayerArea(player)
    
    -- Sync updated data to client
    StateService:BroadcastPlayerDataUpdate(player)
    
    -- Re-initialize the player's area to update visuals
    PlotService:ReinitializePlayerArea(player)
    
    -- Update leaderboard with new rebirth count
    task.spawn(function()
        local updatedData = DataService:GetPlayerData(player)
        if updatedData then
            LeaderboardService:UpdateLeaderstats(player, updatedData)
        end
    end)
    
    print("PlaytimeRewardsService: Instant rebirth completed for", player.Name, "- now has", currentRebirths + 1, "rebirths")
    return true
end

-- Claim a playtime reward
function PlaytimeRewardsService:ClaimReward(player, timeMinutes, sessionTime)
    if not player or not timeMinutes then
        return false, "Invalid parameters"
    end
    
    local DataService = require(script.Parent.DataService)
    local PlaytimeTrackingService = require(script.Parent.PlaytimeTrackingService)
    
    local profile = DataService:GetPlayerProfile(player)
    if not profile then
        return false, "Player profile not found"
    end
    
    -- Use session time if provided, otherwise fall back to server tracking
    local currentPlaytime = sessionTime or PlaytimeTrackingService:GetSessionTime(player)
    
    -- Check if player has enough session playtime
    if currentPlaytime < timeMinutes then
        return false, "Not enough session playtime. Need " .. timeMinutes .. " minutes, have " .. math.floor(currentPlaytime * 10) / 10 .. " minutes"
    end
    
    -- Get reward configuration
    local reward = PlaytimeRewardsConfig.getRewardByTime(timeMinutes)
    if not reward then
        return false, "Invalid reward time"
    end
    
    -- For session-based rewards, we don't check persistent claimed rewards
    -- Client handles session-based claiming validation
    -- Server only validates playtime and grants rewards
    
    -- Grant the reward
    local success = false
    if reward.type == "Diamonds" then
        success = DataService:UpdatePlayerResources(player, "Diamonds", reward.amount)
    elseif reward.type == "Money" then
        success = DataService:UpdatePlayerResources(player, "Money", reward.amount)
    elseif reward.type == "Pet" then
        -- Create pet reward with "Reward" rarity and variation
        success = true -- Assume success unless pet creation fails
        
        for i = 1, reward.amount do
            local petData = {
                Name = reward.petName,
                Rarity = {
                    RarityName = "Reward",
                    RarityChance = 100,
                    RarityColor = Color3.fromRGB(255, 215, 0) -- Gold color for reward pets
                },
                Variation = {
                    VariationName = "Reward",
                    VariationChance = 100,
                    VariationColor = Color3.fromRGB(255, 215, 0), -- Gold color for reward pets
                    VariationMultiplier = 1
                },
                BaseValue = reward.value or 500,
                BaseBoost = reward.boost or 20,
                FinalValue = reward.value or 500,
                FinalBoost = reward.boost or 20,
                ID = HttpService:GenerateGUID()
            }
            
            local petSuccess = DataService:AddPetToPlayer(player, petData)
            if not petSuccess then
                success = false
                break
            end
        end
    elseif reward.type == "Rebirth" then
        -- Perform instant rebirth(s) - this does all the rebirth logic
        success = true
        
        for i = 1, reward.amount do
            -- Perform rebirth manually using same logic as Main.server.lua
            local rebirthSuccess = self:PerformInstantRebirth(player)
            if not rebirthSuccess then
                success = false
                break
            end
        end
    end
    
    if not success then
        return false, "Failed to grant reward"
    end
    
    -- For session-based rewards, we don't persistently store claimed rewards
    -- Each session allows claiming all eligible rewards
    
    -- Sync to client
    local StateService = require(script.Parent.StateService)
    StateService:BroadcastPlayerDataUpdate(player)
    
    print("PlaytimeRewardsService: Player", player.Name, "claimed", reward.amount, reward.type, "for", timeMinutes, "minutes playtime")
    return true, "Reward claimed successfully"
end

-- Get all available rewards for a player (session-based)
function PlaytimeRewardsService:GetAvailableRewards(player, sessionTime)
    local PlaytimeTrackingService = require(script.Parent.PlaytimeTrackingService)
    
    local currentPlaytime = sessionTime or PlaytimeTrackingService:GetSessionTime(player)
    local availableRewards = {}
    local allRewards = PlaytimeRewardsConfig.getAllRewards()
    
    for _, reward in ipairs(allRewards) do
        -- For session-based rewards, only check if player has enough session playtime
        if currentPlaytime >= reward.timeMinutes then
            table.insert(availableRewards, reward)
        end
    end
    
    return availableRewards
end

-- Get reward status for a specific time (session-based)
function PlaytimeRewardsService:GetRewardStatus(player, timeMinutes, sessionTime)
    local PlaytimeTrackingService = require(script.Parent.PlaytimeTrackingService)
    
    local currentPlaytime = sessionTime or PlaytimeTrackingService:GetSessionTime(player)
    
    -- For session-based rewards, claimed status is handled client-side
    -- Server only determines if reward is available based on session playtime
    if currentPlaytime >= timeMinutes then
        return "available"
    end
    
    return "locked"
end

return PlaytimeRewardsService