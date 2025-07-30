-- Pet Variation Configuration
-- Variations are cosmetic/value modifiers that apply to any pet regardless of rarity or level

local VariationConfig = {}

-- Variation definitions with spawn chances
-- Total must equal 100%
VariationConfig.Variations = {
    -- Common Variations (70% total)
    {
        name = "Normal",
        chance = 35,        -- 35%
        valueMultiplier = 1.0,
        boostMultiplier = 1.0,
        color = Color3.fromRGB(200, 200, 200),  -- Light gray
        particleEffect = nil
    },
    {
        name = "Shiny",
        chance = 20,        -- 20%
        valueMultiplier = 1.2,
        boostMultiplier = 1.05,
        color = Color3.fromRGB(255, 255, 200),  -- Light yellow
        particleEffect = "Sparkles"
    },
    {
        name = "Bronze",
        chance = 15,        -- 15%
        valueMultiplier = 1.5,
        boostMultiplier = 1.1,
        color = Color3.fromRGB(205, 127, 50),   -- Bronze
        particleEffect = nil
    },
    
    -- Uncommon Variations (20% total)
    {
        name = "Silver",
        chance = 8,         -- 8%
        valueMultiplier = 2.0,
        boostMultiplier = 1.15,
        color = Color3.fromRGB(192, 192, 192),  -- Silver
        particleEffect = "Shimmer"
    },
    {
        name = "Golden",
        chance = 6,         -- 6%
        valueMultiplier = 3.0,
        boostMultiplier = 1.2,
        color = Color3.fromRGB(255, 215, 0),    -- Gold
        particleEffect = "GoldSparkles"
    },
    {
        name = "Crystal",
        chance = 4,         -- 4%
        valueMultiplier = 4.0,
        boostMultiplier = 1.25,
        color = Color3.fromRGB(200, 230, 255),  -- Light blue crystal
        particleEffect = "CrystalShards"
    },
    {
        name = "Shadow",
        chance = 2,         -- 2%
        valueMultiplier = 5.0,
        boostMultiplier = 1.3,
        color = Color3.fromRGB(50, 50, 50),     -- Dark gray
        particleEffect = "DarkAura"
    },
    
    -- Rare Variations (8% total)
    {
        name = "Electric",
        chance = 2.5,       -- 2.5%
        valueMultiplier = 6.0,
        boostMultiplier = 1.35,
        color = Color3.fromRGB(255, 255, 100),  -- Electric yellow
        particleEffect = "Lightning"
    },
    {
        name = "Frozen",
        chance = 2,         -- 2%
        valueMultiplier = 7.0,
        boostMultiplier = 1.4,
        color = Color3.fromRGB(150, 200, 255),  -- Ice blue
        particleEffect = "IceShards"
    },
    {
        name = "Toxic",
        chance = 1.5,       -- 1.5%
        valueMultiplier = 8.0,
        boostMultiplier = 1.45,
        color = Color3.fromRGB(120, 255, 100),  -- Toxic green
        particleEffect = "ToxicBubbles"
    },
    {
        name = "Lava",
        chance = 1,         -- 1%
        valueMultiplier = 10.0,
        boostMultiplier = 1.5,
        color = Color3.fromRGB(255, 100, 0),    -- Orange-red
        particleEffect = "LavaDrops"
    },
    {
        name = "Diamond",
        chance = 1,         -- 1%
        valueMultiplier = 12.0,
        boostMultiplier = 1.55,
        color = Color3.fromRGB(185, 242, 255),  -- Diamond blue
        particleEffect = "DiamondSparkles"
    },
    
    -- Ultra Rare Variations (2% total)
    {
        name = "Cosmic",
        chance = 0.8,       -- 0.8%
        valueMultiplier = 15.0,
        boostMultiplier = 1.6,
        color = Color3.fromRGB(150, 100, 255),  -- Purple cosmic
        particleEffect = "CosmicStars"
    },
    {
        name = "Rainbow",
        chance = 0.7,       -- 0.7%
        valueMultiplier = 20.0,
        boostMultiplier = 1.65,
        color = Color3.fromRGB(255, 255, 255),  -- White (with rainbow effect)
        particleEffect = "RainbowAura"
    },
    {
        name = "Void",
        chance = 0.5,       -- 0.5%
        valueMultiplier = 25.0,
        boostMultiplier = 1.7,
        color = Color3.fromRGB(20, 0, 40),      -- Deep purple-black
        particleEffect = "VoidPortal"
    }
}

-- Get a random variation based on chances
function VariationConfig:GetRandomVariation()
    local roll = math.random() * 100
    local cumulative = 0
    
    for _, variation in ipairs(self.Variations) do
        cumulative = cumulative + variation.chance
        if roll <= cumulative then
            return {
                VariationName = variation.name,
                VariationColor = {variation.color.R * 255, variation.color.G * 255, variation.color.B * 255},
                ValueMultiplier = variation.valueMultiplier,
                BoostMultiplier = variation.boostMultiplier,
                ParticleEffect = variation.particleEffect
            }
        end
    end
    
    -- Fallback to Normal (should never reach here)
    return {
        VariationName = "Normal",
        VariationColor = {200, 200, 200},
        ValueMultiplier = 1.0,
        BoostMultiplier = 1.0,
        ParticleEffect = nil
    }
end

-- Get variation by name (for specific cases)
function VariationConfig:GetVariationByName(name)
    for _, variation in ipairs(self.Variations) do
        if variation.name == name then
            return {
                VariationName = variation.name,
                VariationColor = {variation.color.R * 255, variation.color.G * 255, variation.color.B * 255},
                ValueMultiplier = variation.valueMultiplier,
                BoostMultiplier = variation.boostMultiplier,
                ParticleEffect = variation.particleEffect
            }
        end
    end
    
    -- Default to Normal if not found
    return self:GetVariationByName("Normal")
end

-- Debug function to print all variations and their chances
function VariationConfig:PrintVariationChances()
    print("\n=== PET VARIATION CHANCES ===")
    print("These chances apply to ALL pets regardless of rarity, level, or door")
    print("\nVariation Name   | Chance | Value Multi | Boost Multi | Color")
    print("-----------------|--------|-------------|-------------|------------------")
    
    local totalChance = 0
    for _, variation in ipairs(self.Variations) do
        totalChance = totalChance + variation.chance
        local colorStr = string.format("RGB(%d,%d,%d)", 
            variation.color.R * 255, 
            variation.color.G * 255, 
            variation.color.B * 255
        )
        print(string.format("%-16s | %5.1f%% | %11.1fx | %11.2fx | %s",
            variation.name,
            variation.chance,
            variation.valueMultiplier,
            variation.boostMultiplier,
            colorStr
        ))
    end
    
    print("\nTotal Chance: " .. totalChance .. "% (should be 100%)")
    print("\nRarity Tiers:")
    print("- Common (70%): Normal, Shiny, Bronze")
    print("- Uncommon (20%): Silver, Golden, Crystal, Shadow")
    print("- Rare (8%): Electric, Frozen, Toxic, Lava, Diamond")
    print("- Ultra Rare (2%): Cosmic, Rainbow, Void")
end

return VariationConfig