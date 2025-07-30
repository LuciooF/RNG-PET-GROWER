-- Pet Spawning Configuration
local PetSpawnConfig = {}

-- Base spawn chances for pets (must add up to 100%)
-- These represent the base rarity distribution for pet spawning
PetSpawnConfig.BaseSpawnChances = {
    20,  -- 20% - Most common
    18,  -- 18%
    15,  -- 15%
    12,  -- 12%
    10,  -- 10%
    8,   -- 8%
    7,   -- 7%
    6,   -- 6%
    3,   -- 3%
    1    -- 1% - Rarest
}

-- Door scaling configuration
-- Higher doors give better chances for rarer pets
PetSpawnConfig.DoorScaling = {
    -- Base multiplier that increases with door number
    -- This creates a curve where higher doors significantly boost rare pet chances
    getMultiplier = function(doorNumber, basePetRank)
        -- doorNumber: 1-7 (or more for higher levels)
        -- basePetRank: 1-10 (1 = most common, 10 = rarest)
        
        -- Calculate a scaling factor based on door number
        local doorScale = math.log(doorNumber + 1) / math.log(8) -- Logarithmic scaling, normalized to ~1 at door 7
        
        -- Rarer pets get bigger boosts from higher doors
        local rarityBoost = 1 + (doorScale * (basePetRank - 1) / 9)
        
        -- Common pets get slightly reduced chances at higher doors
        if basePetRank <= 3 then
            rarityBoost = 1 - (doorScale * 0.3 * (4 - basePetRank) / 3)
        end
        
        return math.max(0.1, rarityBoost) -- Never go below 10% of original chance
    end
}

-- Pet definitions by level
-- Each level has 10 pets with increasing rarity
PetSpawnConfig.PetsByLevel = {
    -- Level 1 Pets (Basic animals)
    [1] = {
        { name = "Mouse", rarity = "Common", value = 10, boost = 1.05 },         -- 20% base
        { name = "Hamster", rarity = "Common", value = 15, boost = 1.06 },       -- 18% base
        { name = "Rabbit", rarity = "Common", value = 20, boost = 1.07 },        -- 15% base
        { name = "Cat", rarity = "Uncommon", value = 30, boost = 1.08 },         -- 12% base
        { name = "Dog", rarity = "Uncommon", value = 45, boost = 1.09 },         -- 10% base
        { name = "Fox", rarity = "Uncommon", value = 65, boost = 1.10 },         -- 8% base
        { name = "Wolf", rarity = "Rare", value = 90, boost = 1.12 },            -- 7% base
        { name = "Bear", rarity = "Rare", value = 120, boost = 1.14 },           -- 6% base
        { name = "Lion", rarity = "Epic", value = 200, boost = 1.18 },           -- 3% base
        { name = "Dragon", rarity = "Legendary", value = 500, boost = 1.25 }     -- 1% base
    },
    -- Level 2 Pets (Mythical creatures)
    [2] = {
        { name = "Imp", rarity = "Common", value = 50, boost = 1.10 },
        { name = "Pixie", rarity = "Common", value = 75, boost = 1.11 },
        { name = "Goblin", rarity = "Common", value = 100, boost = 1.12 },
        { name = "Sprite", rarity = "Uncommon", value = 150, boost = 1.13 },
        { name = "Elf", rarity = "Uncommon", value = 225, boost = 1.14 },
        { name = "Gnome", rarity = "Uncommon", value = 325, boost = 1.15 },
        { name = "Troll", rarity = "Rare", value = 450, boost = 1.17 },
        { name = "Ogre", rarity = "Rare", value = 600, boost = 1.19 },
        { name = "Griffin", rarity = "Epic", value = 1000, boost = 1.23 },
        { name = "Phoenix", rarity = "Legendary", value = 2500, boost = 1.30 }
    },
    -- Level 3 Pets (Elemental beings)
    [3] = {
        { name = "Fire Wisp", rarity = "Common", value = 250, boost = 1.15 },
        { name = "Water Spirit", rarity = "Common", value = 375, boost = 1.16 },
        { name = "Earth Golem", rarity = "Common", value = 500, boost = 1.17 },
        { name = "Air Elemental", rarity = "Uncommon", value = 750, boost = 1.18 },
        { name = "Lightning Beast", rarity = "Uncommon", value = 1125, boost = 1.19 },
        { name = "Ice Guardian", rarity = "Uncommon", value = 1625, boost = 1.20 },
        { name = "Magma Lord", rarity = "Rare", value = 2250, boost = 1.22 },
        { name = "Storm Titan", rarity = "Rare", value = 3000, boost = 1.24 },
        { name = "Crystal Dragon", rarity = "Epic", value = 5000, boost = 1.28 },
        { name = "Void Leviathan", rarity = "Legendary", value = 12500, boost = 1.35 }
    }
}

-- Calculate actual spawn chances for a specific door
function PetSpawnConfig:GetSpawnChancesForDoor(level, doorNumber)
    local pets = self.PetsByLevel[level]
    if not pets then
        warn("PetSpawnConfig: No pets defined for level", level)
        return {}
    end
    
    local scaledChances = {}
    local totalChance = 0
    
    -- First pass: calculate scaled chances
    for i, baseChance in ipairs(self.BaseSpawnChances) do
        local multiplier = self.DoorScaling.getMultiplier(doorNumber, i)
        local scaledChance = baseChance * multiplier
        
        scaledChances[i] = {
            name = pets[i].name,
            rarity = pets[i].rarity,
            value = pets[i].value,
            boost = pets[i].boost,
            chance = scaledChance,
            originalChance = baseChance
        }
        
        totalChance = totalChance + scaledChance
    end
    
    -- Second pass: normalize to 100%
    for i, chance in ipairs(scaledChances) do
        chance.normalizedChance = (chance.chance / totalChance) * 100
    end
    
    return scaledChances
end

-- Get a random pet based on spawn chances
function PetSpawnConfig:GetRandomPet(level, doorNumber)
    local chances = self:GetSpawnChancesForDoor(level, doorNumber)
    local roll = math.random() * 100
    local cumulative = 0
    
    for _, petChance in ipairs(chances) do
        cumulative = cumulative + petChance.normalizedChance
        if roll <= cumulative then
            return {
                Name = petChance.name,
                Rarity = petChance.rarity,
                BaseValue = petChance.value,
                BaseBoost = petChance.boost
            }
        end
    end
    
    -- Fallback to most common pet
    return {
        Name = chances[1].name,
        Rarity = chances[1].rarity,
        BaseValue = chances[1].value,
        BaseBoost = chances[1].boost
    }
end

-- Debug function to print spawn chances for all doors
function PetSpawnConfig:PrintSpawnChances(level)
    level = level or 1
    local pets = self.PetsByLevel[level]
    if not pets then
        warn("No pets defined for level", level)
        return
    end
    
    print("\n=== Pet Spawn Chances by Door (Level " .. level .. ") ===")
    print("Base chances represent the fundamental rarity distribution")
    
    for door = 1, 7 do
        print("\nDoor " .. door .. ":")
        local chances = self:GetSpawnChancesForDoor(level, door)
        
        for _, chance in ipairs(chances) do
            local change = chance.normalizedChance - chance.originalChance
            local changeStr = change >= 0 and "+" .. string.format("%.1f", change) or string.format("%.1f", change)
            print(string.format("  %s (%s): %.2f%% (base: %.0f%%, change: %s%%)", 
                chance.name, 
                chance.rarity,
                chance.normalizedChance, 
                chance.originalChance,
                changeStr
            ))
        end
    end
end

return PetSpawnConfig