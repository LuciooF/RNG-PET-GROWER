-- FreeOpItemConfig - Configurable free OP item rewards system
local FreeOpItemConfig = {}

-- Main configuration for the free OP item system
FreeOpItemConfig.Config = {
    -- Timing requirements
    RequiredPlaytimeMinutes = 30, -- Minutes player must play to unlock reward
    ClaimCooldownMinutes = 30, -- Minutes before next claim (can be same or different from required time)
    SessionResetHours = 24, -- DEPRECATED - kept for compatibility
    
    -- Multiple claims configuration
    MaxClaimsPerSession = -1, -- -1 for unlimited claims in one session
    
    -- Reward configuration (can be made into an array later for different rewards)
    RewardType = "Potion", -- "Potion", "Pet", "Currency", etc.
    PotionId = "pet_magnet_op_24h", -- Potion to give (OP Pet Magnet for 24h)
    PotionQuantity = 1,
    
    -- UI configuration
    ButtonText = "FREE OP ITEM",
    MagnetIconId = "rbxassetid://133122022215716",
    PetIconAsset = {type = "UI", name = "PET"}, -- Use IconAssets system like other UI
    
    -- Pricing for display (estimated Robux value)
    EstimatedRobuxValue = 299, -- Display value for the reward
    
    -- Progress tracking
    TrackingEnabled = true,
    DebugMode = true, -- Set to true for faster testing (reduces times)
}

-- Debug configuration (for testing)
FreeOpItemConfig.DebugConfig = {
    RequiredPlaytimeMinutes = 1, -- 1 minute for testing
    ClaimCooldownMinutes = 1, -- 1 minute cooldown between claims for testing
    SessionResetHours = 0.1, -- DEPRECATED
    MaxClaimsPerSession = -1, -- Unlimited for testing
    EstimatedRobuxValue = 299,
}

-- Get configuration (returns debug config if debug mode is enabled)
function FreeOpItemConfig.GetConfig()
    if FreeOpItemConfig.Config.DebugMode then
        -- Merge base config with debug overrides
        local config = {}
        for key, value in pairs(FreeOpItemConfig.Config) do
            config[key] = value
        end
        for key, value in pairs(FreeOpItemConfig.DebugConfig) do
            config[key] = value
        end
        return config
    else
        return FreeOpItemConfig.Config
    end
end

-- Helper functions for time calculations
function FreeOpItemConfig.GetRequiredPlaytimeSeconds()
    return FreeOpItemConfig.GetConfig().RequiredPlaytimeMinutes * 60
end

function FreeOpItemConfig.GetClaimCooldownSeconds()
    return FreeOpItemConfig.GetConfig().ClaimCooldownMinutes * 60
end

function FreeOpItemConfig.GetSessionResetSeconds()
    return FreeOpItemConfig.GetConfig().SessionResetHours * 3600
end

function FreeOpItemConfig.GetMaxClaimsPerSession()
    return FreeOpItemConfig.GetConfig().MaxClaimsPerSession
end

-- Format time for UI display
function FreeOpItemConfig.FormatTime(seconds)
    if seconds <= 0 then
        return "0:00"
    end
    
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%d:%02d", minutes, secs)
end

-- Get reward description for UI
function FreeOpItemConfig.GetRewardDescription()
    local config = FreeOpItemConfig.GetConfig()
    if config.RewardType == "Potion" then
        -- Get dynamic Pet Magnet gamepass price
        local GamepassConfig = require(script.Parent.GamepassConfig)
        local petMagnetPrice = GamepassConfig.GAMEPASSES.PetMagnet.price or 99 -- Fallback to 99
        return string.format("Free OP 24H Pet Magnet Potion (Worth %d Robux)", petMagnetPrice)
    else
        return string.format("Free OP Item (Worth %d Robux)", config.EstimatedRobuxValue)
    end
end

-- Get potion configuration
function FreeOpItemConfig.GetPotionReward()
    local config = FreeOpItemConfig.GetConfig()
    return {
        potionId = config.PotionId,
        quantity = config.PotionQuantity
    }
end

return FreeOpItemConfig