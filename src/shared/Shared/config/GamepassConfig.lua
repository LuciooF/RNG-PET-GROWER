-- Gamepass Configuration
-- Defines all available gamepasses with their IDs, benefits, and properties

local GamepassConfig = {}

-- Gamepass definitions
GamepassConfig.GAMEPASSES = {
    [1] = {
        id = 123456789, -- Replace with actual Roblox gamepass ID
        name = "VIP",
        displayName = "🌟 VIP Status",
        description = "Unlock exclusive VIP benefits and perks!",
        price = 199, -- Robux price
        icon = "rbxassetid://123456789", -- Replace with actual icon ID
        benefits = {
            "2x Money Multiplier",
            "Access to VIP-only pets",
            "Exclusive VIP nameplate",
            "Priority customer support"
        },
        effects = {
            moneyMultiplier = 2.0,
            accessVIPPets = true,
            vipNameplate = true
        }
    },
    
    [2] = {
        id = 123456790, -- Replace with actual Roblox gamepass ID
        name = "PetCollector",
        displayName = "🐾 Pet Collector",
        description = "Double your pet inventory space and collection speed!",
        price = 149,
        icon = "rbxassetid://123456790",
        benefits = {
            "2x Pet Inventory Space (2000 pets)",
            "1.5x Pet Spawn Rate",
            "Access to Collector pets"
        },
        effects = {
            inventoryMultiplier = 2.0, -- 2000 instead of 1000
            petSpawnMultiplier = 1.5,
            accessCollectorPets = true
        }
    },
    
    [3] = {
        id = 123456791, -- Replace with actual Roblox gamepass ID
        name = "FastRebirths",
        displayName = "⚡ Fast Rebirths",
        description = "Rebirth faster and get bonus rewards!",
        price = 99,
        icon = "rbxassetid://123456791",
        benefits = {
            "50% Reduced Rebirth Requirements",
            "+1 Bonus Rebirth Multiplier",
            "Instant Rebirth Animation"
        },
        effects = {
            rebirthRequirementMultiplier = 0.5,
            bonusRebirthMultiplier = 1,
            instantRebirth = true
        }
    },
    
    [4] = {
        id = 123456792, -- Replace with actual Roblox gamepass ID
        name = "AutoCollect",
        displayName = "🤖 Auto Collect",
        description = "Automatically collect pets without clicking!",
        price = 299,
        icon = "rbxassetid://123456792",
        benefits = {
            "Auto-collect pets from plots",
            "Auto-send to heaven when full",
            "Customizable auto-collect settings"
        },
        effects = {
            autoCollectPets = true,
            autoSendHeaven = true,
            autoCollectRadius = 50
        }
    },
    
    [5] = {
        id = 123456793, -- Replace with actual Roblox gamepass ID
        name = "DiamondBoost",
        displayName = "💎 Diamond Boost",
        description = "Earn more diamonds and get exclusive perks!",
        price = 179,
        icon = "rbxassetid://123456793",
        benefits = {
            "3x Diamond Earnings",
            "Access to Diamond-tier pets",
            "Daily diamond bonus"
        },
        effects = {
            diamondMultiplier = 3.0,
            accessDiamondPets = true,
            dailyDiamondBonus = 50
        }
    }
}

-- Helper functions
function GamepassConfig:GetGamepassData(gamepassId)
    for _, gamepass in pairs(self.GAMEPASSES) do
        if gamepass.id == gamepassId then
            return gamepass
        end
    end
    return nil
end

function GamepassConfig:GetGamepassByName(name)
    for _, gamepass in pairs(self.GAMEPASSES) do
        if gamepass.name == name then
            return gamepass
        end
    end
    return nil
end

function GamepassConfig:GetAllGamepasses()
    return self.GAMEPASSES
end

-- Calculate total multipliers from multiple gamepasses
function GamepassConfig:CalculateEffects(ownedGamepasses)
    local effects = {
        moneyMultiplier = 1.0,
        diamondMultiplier = 1.0,
        inventoryMultiplier = 1.0,
        petSpawnMultiplier = 1.0,
        rebirthRequirementMultiplier = 1.0,
        bonusRebirthMultiplier = 0,
        
        -- Boolean effects
        accessVIPPets = false,
        accessCollectorPets = false,
        accessDiamondPets = false,
        vipNameplate = false,
        autoCollectPets = false,
        autoSendHeaven = false,
        instantRebirth = false,
        
        -- Special values
        autoCollectRadius = 0,
        dailyDiamondBonus = 0
    }
    
    for gamepassName, _ in pairs(ownedGamepasses) do
        local gamepass = self:GetGamepassByName(gamepassName)
        if gamepass and gamepass.effects then
            -- Multiply numerical effects
            if gamepass.effects.moneyMultiplier then
                effects.moneyMultiplier = effects.moneyMultiplier * gamepass.effects.moneyMultiplier
            end
            if gamepass.effects.diamondMultiplier then
                effects.diamondMultiplier = effects.diamondMultiplier * gamepass.effects.diamondMultiplier
            end
            if gamepass.effects.inventoryMultiplier then
                effects.inventoryMultiplier = effects.inventoryMultiplier * gamepass.effects.inventoryMultiplier
            end
            if gamepass.effects.petSpawnMultiplier then
                effects.petSpawnMultiplier = effects.petSpawnMultiplier * gamepass.effects.petSpawnMultiplier
            end
            if gamepass.effects.rebirthRequirementMultiplier then
                effects.rebirthRequirementMultiplier = effects.rebirthRequirementMultiplier * gamepass.effects.rebirthRequirementMultiplier
            end
            
            -- Add bonus values
            if gamepass.effects.bonusRebirthMultiplier then
                effects.bonusRebirthMultiplier = effects.bonusRebirthMultiplier + gamepass.effects.bonusRebirthMultiplier
            end
            if gamepass.effects.dailyDiamondBonus then
                effects.dailyDiamondBonus = effects.dailyDiamondBonus + gamepass.effects.dailyDiamondBonus
            end
            
            -- Boolean effects (OR logic)
            for key, value in pairs(gamepass.effects) do
                if type(value) == "boolean" and value then
                    effects[key] = true
                end
            end
            
            -- Special values (take highest)
            if gamepass.effects.autoCollectRadius then
                effects.autoCollectRadius = math.max(effects.autoCollectRadius, gamepass.effects.autoCollectRadius)
            end
        end
    end
    
    return effects
end

return GamepassConfig