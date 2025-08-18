-- Pet configuration and data
local PetConstants = require(script.Parent.Parent.constants.PetConstants)

local PetConfig = {}


-- Pet definitions by level
PetConfig.PetsByLevel = {
    -- LEVEL 1 - Starter Tier - Cool but accessible pets
    [1] = {
        {Name = "Gecko", ModelName = "Gecko", Rarity = PetConstants.Rarity.COMMON, BaseValue = 1, BaseBoost = 0.76, SpawnChance = 20.0},        -- 1 in 5
        {Name = "Red Panda", ModelName = "Red Panda", Rarity = PetConstants.Rarity.UNCOMMON, BaseValue = 2, BaseBoost = 0.77, SpawnChance = 10.0},     -- 1 in 10
        {Name = "Flamingo", ModelName = "Flamingo", Rarity = PetConstants.Rarity.RARE, BaseValue = 4, BaseBoost = 0.78, SpawnChance = 4.0},         -- 1 in 25
        {Name = "Capybara", ModelName = "Capybara", Rarity = PetConstants.Rarity.EPIC, BaseValue = 8, BaseBoost = 0.81, SpawnChance = 2.0},      -- 1 in 50
        {Name = "Sloth", ModelName = "Sloth", Rarity = PetConstants.Rarity.LEGENDARY, BaseValue = 16, BaseBoost = 0.87, SpawnChance = 1.0},   -- 1 in 100
        {Name = "Baby Dragon", ModelName = "Baby Dragon", Rarity = PetConstants.Rarity.MYTHIC, BaseValue = 32, BaseBoost = 0.99, SpawnChance = 0.4}, -- 1 in 250
        {Name = "Narwhal", ModelName = "Narwhal", Rarity = PetConstants.Rarity.ANCIENT, BaseValue = 64, BaseBoost = 1.23, SpawnChance = 0.2},      -- 1 in 500
        {Name = "Phoenix", ModelName = "Phoenix", Rarity = PetConstants.Rarity.CELESTIAL, BaseValue = 128, BaseBoost = 1.71, SpawnChance = 0.1}, -- 1 in 1k (Keep - already cool!)
        {Name = "Dragon", ModelName = "Dragon", Rarity = PetConstants.Rarity.TRANSCENDENT, BaseValue = 256, BaseBoost = 1.92, SpawnChance = 0.04}, -- 1 in 2.5k (Keep - already cool!)
        {Name = "Crystal Lord", ModelName = "Crystal Lord", Rarity = PetConstants.Rarity.OMNIPOTENT, BaseValue = 512, BaseBoost = 3.84, SpawnChance = 0.02}, -- 1 in 5k (Keep - already cool!)
        {Name = "Octopus", ModelName = "Octopus", Rarity = PetConstants.Rarity.ETHEREAL, BaseValue = 1024, BaseBoost = 7.68, SpawnChance = 0.01},   -- 1 in 10k
        {Name = "Pufferfish", ModelName = "Pufferfish", Rarity = PetConstants.Rarity.PRIMORDIAL, BaseValue = 2048, BaseBoost = 15.36, SpawnChance = 0.004}, -- 1 in 25k
        {Name = "Stegosaurus", ModelName = "Stegosaurus", Rarity = PetConstants.Rarity.COSMIC, BaseValue = 4096, BaseBoost = 30.72, SpawnChance = 0.002}, -- 1 in 50k
        {Name = "Grim Reaper", ModelName = "Grim Reaper", Rarity = PetConstants.Rarity.INFINITE, BaseValue = 8192, BaseBoost = 61.44, SpawnChance = 0.001}, -- 1 in 100k
        {Name = "The Chosen One", ModelName = "The Chosen One", Rarity = PetConstants.Rarity.OMNISCIENT, BaseValue = 16384, BaseBoost = 122.88, SpawnChance = 0.0001} -- 1 in 1M (Keep - already cool!)
    },
    
    -- LEVEL 2 - Cyberpunk/Space Tier - Futuristic and alien themes
    [2] = {
        -- 15 different rarities with incremental spawn chances - Tech/space themed pets
        {Name = "Vaporwave Cat", ModelName = "Vaporwave Cat", Rarity = PetConstants.Rarity.COMMON, BaseValue = 2, BaseBoost = 0.77, SpawnChance = 20.0},        -- 1 in 5
        {Name = "Cyber Cat", ModelName = "Cyber Cat", Rarity = PetConstants.Rarity.UNCOMMON, BaseValue = 4, BaseBoost = 0.78, SpawnChance = 10.0},     -- 1 in 10
        {Name = "Fire Fox", ModelName = "Fire Fox", Rarity = PetConstants.Rarity.RARE, BaseValue = 8, BaseBoost = 0.81, SpawnChance = 4.0},         -- 1 in 25 (Keep - already cool!)
        {Name = "Astronaut", ModelName = "Astronaut", Rarity = PetConstants.Rarity.EPIC, BaseValue = 16, BaseBoost = 0.87, SpawnChance = 2.0},      -- 1 in 50
        {Name = "Matrix Doggy", ModelName = "Matrix Doggy", Rarity = PetConstants.Rarity.LEGENDARY, BaseValue = 32, BaseBoost = 0.99, SpawnChance = 1.0},   -- 1 in 100
        {Name = "Alien Dragon", ModelName = "Alien Dragon", Rarity = PetConstants.Rarity.MYTHIC, BaseValue = 64, BaseBoost = 1.23, SpawnChance = 0.4}, -- 1 in 250
        {Name = "Mars Crawler", ModelName = "Mars Crawler", Rarity = PetConstants.Rarity.ANCIENT, BaseValue = 128, BaseBoost = 1.71, SpawnChance = 0.2},      -- 1 in 500
        {Name = "Saturn Cat", ModelName = "Saturn Cat", Rarity = PetConstants.Rarity.CELESTIAL, BaseValue = 256, BaseBoost = 1.92, SpawnChance = 0.1}, -- 1 in 1k
        {Name = "Cyber Dominus", ModelName = "Cyber Dominus", Rarity = PetConstants.Rarity.TRANSCENDENT, BaseValue = 512, BaseBoost = 3.84, SpawnChance = 0.04}, -- 1 in 2.5k (Keep - already cool!)
        {Name = "Neptune Golem", ModelName = "Neptune Golem", Rarity = PetConstants.Rarity.OMNIPOTENT, BaseValue = 1024, BaseBoost = 7.68, SpawnChance = 0.02}, -- 1 in 5k
        {Name = "Alien Hydra", ModelName = "Alien Hydra", Rarity = PetConstants.Rarity.ETHEREAL, BaseValue = 2048, BaseBoost = 15.36, SpawnChance = 0.01},   -- 1 in 10k  
        {Name = "Mecha Spider", ModelName = "Mecha Spider", Rarity = PetConstants.Rarity.PRIMORDIAL, BaseValue = 4096, BaseBoost = 30.72, SpawnChance = 0.004}, -- 1 in 25k
        {Name = "Cyber Robot", ModelName = "Cyber Robot", Rarity = PetConstants.Rarity.COSMIC, BaseValue = 8192, BaseBoost = 61.44, SpawnChance = 0.002}, -- 1 in 50k
        {Name = "Constellation", ModelName = "Constellation", Rarity = PetConstants.Rarity.INFINITE, BaseValue = 16384, BaseBoost = 122.88, SpawnChance = 0.001}, -- 1 in 100k
        {Name = "The Watcher", ModelName = "The Watcher", Rarity = PetConstants.Rarity.OMNISCIENT, BaseValue = 32768, BaseBoost = 245.76, SpawnChance = 0.0001} -- 1 in 1M (Keep - already cool!)
    },
    
    -- LEVEL 3 - Mythical/Fantasy Tier - Dragons, demons, and legendary creatures
    [3] = {
        -- 15 different rarities with incremental spawn chances - Epic fantasy creatures
        {Name = "Hell Dragon", ModelName = "Hell Dragon", Rarity = PetConstants.Rarity.COMMON, BaseValue = 4, BaseBoost = 0.78, SpawnChance = 20.0},        -- 1 in 5 (Keep - very cool!)
        {Name = "Heaven Peacock", ModelName = "Heaven Peacock", Rarity = PetConstants.Rarity.UNCOMMON, BaseValue = 8, BaseBoost = 0.81, SpawnChance = 10.0},     -- 1 in 10 (Keep - very cool!)
        {Name = "Emerald Dragon", ModelName = "Emerald Dragon", Rarity = PetConstants.Rarity.RARE, BaseValue = 16, BaseBoost = 0.87, SpawnChance = 4.0},         -- 1 in 25
        {Name = "Sapphire Dragon", ModelName = "Sapphire Dragon", Rarity = PetConstants.Rarity.EPIC, BaseValue = 32, BaseBoost = 0.99, SpawnChance = 2.0},      -- 1 in 50
        {Name = "Diamond Golem", ModelName = "Diamond Golem", Rarity = PetConstants.Rarity.LEGENDARY, BaseValue = 64, BaseBoost = 1.23, SpawnChance = 1.0},   -- 1 in 100
        {Name = "Kitsune", ModelName = "Kitsune", Rarity = PetConstants.Rarity.MYTHIC, BaseValue = 128, BaseBoost = 1.71, SpawnChance = 0.4}, -- 1 in 250
        {Name = "Headless Horseman", ModelName = "Headless Horseman", Rarity = PetConstants.Rarity.ANCIENT, BaseValue = 256, BaseBoost = 1.92, SpawnChance = 0.2},      -- 1 in 500
        {Name = "Cyber Dominus", ModelName = "Cyber Dominus", Rarity = PetConstants.Rarity.CELESTIAL, BaseValue = 512, BaseBoost = 3.84, SpawnChance = 0.1}, -- 1 in 1k
        {Name = "Gingerbread Dominus", ModelName = "Gingerbread Dominus", Rarity = PetConstants.Rarity.TRANSCENDENT, BaseValue = 1024, BaseBoost = 7.68, SpawnChance = 0.04}, -- 1 in 2.5k (Keep - unique!)
        {Name = "Soul Golem", ModelName = "Soul Golem", Rarity = PetConstants.Rarity.OMNIPOTENT, BaseValue = 2048, BaseBoost = 15.36, SpawnChance = 0.02}, -- 1 in 5k
        {Name = "Demon", ModelName = "Demon", Rarity = PetConstants.Rarity.ETHEREAL, BaseValue = 4096, BaseBoost = 30.72, SpawnChance = 0.01},   -- 1 in 10k (Keep - classic!)
        {Name = "Cyclops", ModelName = "Cyclops", Rarity = PetConstants.Rarity.PRIMORDIAL, BaseValue = 8192, BaseBoost = 61.44, SpawnChance = 0.004}, -- 1 in 25k
        {Name = "Ban Hammer", ModelName = "Ban Hammer", Rarity = PetConstants.Rarity.COSMIC, BaseValue = 16384, BaseBoost = 122.88, SpawnChance = 0.002}, -- 1 in 50k
        {Name = "Developer Pet", ModelName = "Developer Pet", Rarity = PetConstants.Rarity.INFINITE, BaseValue = 32768, BaseBoost = 245.76, SpawnChance = 0.001}, -- 1 in 100k
        {Name = "1x1x1x1", ModelName = "1x1x1x1", Rarity = PetConstants.Rarity.OMNISCIENT, BaseValue = 65536, BaseBoost = 491.52, SpawnChance = 0.0001} -- 1 in 1M (Keep - legendary Roblox reference!)
    },
    
    -- LEVEL 4 - Mystical/Food Tier - Magical creatures and themed pets
    [4] = {
        {Name = "Hot Dog", ModelName = "Hot Dog", Rarity = PetConstants.Rarity.COMMON, BaseValue = 8, BaseBoost = 0.80, SpawnChance = 18.0},
        {Name = "Ice Cream Cone", ModelName = "Ice Cream Cone", Rarity = PetConstants.Rarity.COMMON, BaseValue = 8, BaseBoost = 0.80, SpawnChance = 16.0},
        {Name = "Mystic Fox", ModelName = "Mystic Fox", Rarity = PetConstants.Rarity.UNCOMMON, BaseValue = 16, BaseBoost = 0.84, SpawnChance = 14.0}, -- Keep - unique!
        {Name = "Popcorn Cat", ModelName = "Popcorn Cat", Rarity = PetConstants.Rarity.UNCOMMON, BaseValue = 16, BaseBoost = 0.86, SpawnChance = 12.0},
        {Name = "Chocolate Dragon", ModelName = "Chocolate Dragon", Rarity = PetConstants.Rarity.RARE, BaseValue = 32, BaseBoost = 0.89, SpawnChance = 10.0},
        {Name = "Donut Doggy", ModelName = "Donut Doggy", Rarity = PetConstants.Rarity.RARE, BaseValue = 40, BaseBoost = 0.90, SpawnChance = 8.0},
        {Name = "Enchanted Golem", ModelName = "Enchanted Golem", Rarity = PetConstants.Rarity.EPIC, BaseValue = 64, BaseBoost = 0.94, SpawnChance = 6.0},
        {Name = "Enchanted Bunny", ModelName = "Enchanted Bunny", Rarity = PetConstants.Rarity.EPIC, BaseValue = 80, BaseBoost = 0.98, SpawnChance = 5.0},
        {Name = "Ruby Golem", ModelName = "Ruby Golem", Rarity = PetConstants.Rarity.LEGENDARY, BaseValue = 160, BaseBoost = 1.01, SpawnChance = 4.0},
        {Name = "Sapphire Dragon", ModelName = "Sapphire Dragon", Rarity = PetConstants.Rarity.MYTHIC, BaseValue = 400, BaseBoost = 1.05, SpawnChance = 3.0},
        {Name = "Kitsune", ModelName = "Kitsune", Rarity = PetConstants.Rarity.COMMON, BaseValue = 8, BaseBoost = 0.80, SpawnChance = 2.0},
        {Name = "Owl", ModelName = "Chocolate Owl", Rarity = PetConstants.Rarity.UNCOMMON, BaseValue = 24, BaseBoost = 0.89, SpawnChance = 1.5},
        {Name = "Wizard Cat", ModelName = "Lucky Cat", Rarity = PetConstants.Rarity.RARE, BaseValue = 48, BaseBoost = 0.93, SpawnChance = 1.0},
        {Name = "Cyclops", ModelName = "Cyclops", Rarity = PetConstants.Rarity.EPIC, BaseValue = 120, BaseBoost = 1.02, SpawnChance = 0.4},
        {Name = "Developer Pet", ModelName = "Developer Pet", Rarity = PetConstants.Rarity.MYTHIC, BaseValue = 800, BaseBoost = 1.09, SpawnChance = 0.1} -- SUPER DUPER RARE
    },
    
    -- LEVEL 5 - Galactic pets (16x value multiplier from Level 1)
    [5] = {
        {Name = "Saturn Cat", ModelName = "Saturn Cat", Rarity = PetConstants.Rarity.COMMON, BaseValue = 16, BaseBoost = 0.81, SpawnChance = 18.0},
        {Name = "Saturn Doggy", ModelName = "Saturn Doggy", Rarity = PetConstants.Rarity.COMMON, BaseValue = 16, BaseBoost = 0.81, SpawnChance = 16.0},
        {Name = "Mars Crawler", ModelName = "Mars Crawler", Rarity = PetConstants.Rarity.UNCOMMON, BaseValue = 32, BaseBoost = 0.87, SpawnChance = 14.0},
        {Name = "Saturn Floppa", ModelName = "Saturn Floppa", Rarity = PetConstants.Rarity.UNCOMMON, BaseValue = 32, BaseBoost = 0.90, SpawnChance = 12.0},
        {Name = "Martian Cat", ModelName = "Martian Cat", Rarity = PetConstants.Rarity.RARE, BaseValue = 64, BaseBoost = 0.93, SpawnChance = 10.0},
        {Name = "Martian Doggy", ModelName = "Martian Doggy", Rarity = PetConstants.Rarity.RARE, BaseValue = 80, BaseBoost = 0.96, SpawnChance = 8.0},
        {Name = "Neptune Golem", ModelName = "Neptune Golem", Rarity = PetConstants.Rarity.EPIC, BaseValue = 128, BaseBoost = 0.99, SpawnChance = 6.0},
        {Name = "Lunar Golem", ModelName = "Lunar Golem", Rarity = PetConstants.Rarity.EPIC, BaseValue = 160, BaseBoost = 1.02, SpawnChance = 5.0},
        {Name = "Neptunian Dragon", ModelName = "Neptunian Dragon", Rarity = PetConstants.Rarity.LEGENDARY, BaseValue = 320, BaseBoost = 1.05, SpawnChance = 4.0},
        {Name = "Constellation", ModelName = "Constellation", Rarity = PetConstants.Rarity.MYTHIC, BaseValue = 800, BaseBoost = 1.09, SpawnChance = 3.0},
        {Name = "Alien", ModelName = "Alien", Rarity = PetConstants.Rarity.COMMON, BaseValue = 16, BaseBoost = 0.81, SpawnChance = 2.0},
        {Name = "Astronaut", ModelName = "Astronaut", Rarity = PetConstants.Rarity.UNCOMMON, BaseValue = 48, BaseBoost = 0.93, SpawnChance = 1.5},
        {Name = "Space Golem", ModelName = "Space Golem", Rarity = PetConstants.Rarity.RARE, BaseValue = 96, BaseBoost = 0.98, SpawnChance = 1.0},
        {Name = "Venus Overlord", ModelName = "Venus Overlord", Rarity = PetConstants.Rarity.EPIC, BaseValue = 240, BaseBoost = 1.07, SpawnChance = 0.4},
        {Name = "Robux Fiend", ModelName = "Robux Fiend", Rarity = PetConstants.Rarity.MYTHIC, BaseValue = 1600, BaseBoost = 1.13, SpawnChance = 0.1} -- SUPER DUPER RARE
    },
    
    -- LEVEL 6 - Divine pets (32x value multiplier from Level 1)
    [6] = {
        {Name = "Angel", ModelName = "Angel", Rarity = PetConstants.Rarity.COMMON, BaseValue = 32, BaseBoost = 0.83, SpawnChance = 18.0},
        {Name = "Angel Bee", ModelName = "Angel Bee", Rarity = PetConstants.Rarity.COMMON, BaseValue = 32, BaseBoost = 0.83, SpawnChance = 16.0},
        {Name = "Angel Crab", ModelName = "Angel Crab", Rarity = PetConstants.Rarity.UNCOMMON, BaseValue = 64, BaseBoost = 0.90, SpawnChance = 14.0},
        {Name = "Cactus Angel", ModelName = "Cactus Angel", Rarity = PetConstants.Rarity.UNCOMMON, BaseValue = 64, BaseBoost = 0.94, SpawnChance = 12.0},
        {Name = "Heart Phoenix", ModelName = "Heart Phoenix", Rarity = PetConstants.Rarity.RARE, BaseValue = 128, BaseBoost = 0.98, SpawnChance = 10.0},
        {Name = "Heart Unicorn", ModelName = "Heart Unicorn", Rarity = PetConstants.Rarity.RARE, BaseValue = 160, BaseBoost = 1.01, SpawnChance = 8.0},
        {Name = "Heart Dominus", ModelName = "Heart Dominus", Rarity = PetConstants.Rarity.EPIC, BaseValue = 256, BaseBoost = 1.05, SpawnChance = 6.0},
        {Name = "Crystal Bunny 2.0", ModelName = "Crystal Bunny 2.0", Rarity = PetConstants.Rarity.EPIC, BaseValue = 320, BaseBoost = 1.09, SpawnChance = 5.0},
        {Name = "Diamond Golem", ModelName = "Diamond Golem", Rarity = PetConstants.Rarity.LEGENDARY, BaseValue = 640, BaseBoost = 1.13, SpawnChance = 4.0},
        {Name = "Emerald Golem", ModelName = "Emerald Golem", Rarity = PetConstants.Rarity.MYTHIC, BaseValue = 1600, BaseBoost = 1.16, SpawnChance = 3.0},
        {Name = "Angel Mushroom", ModelName = "Angel Mushroom", Rarity = PetConstants.Rarity.COMMON, BaseValue = 32, BaseBoost = 0.83, SpawnChance = 2.0},
        {Name = "Heart Floppa", ModelName = "Heart Floppa", Rarity = PetConstants.Rarity.UNCOMMON, BaseValue = 96, BaseBoost = 0.98, SpawnChance = 1.5},
        {Name = "Heart Husky", ModelName = "Heart Husky", Rarity = PetConstants.Rarity.RARE, BaseValue = 192, BaseBoost = 1.02, SpawnChance = 1.0},
        {Name = "Headless Horseman", ModelName = "Headless Horseman", Rarity = PetConstants.Rarity.EPIC, BaseValue = 480, BaseBoost = 1.11, SpawnChance = 0.4},
        {Name = "Ban Hammer", ModelName = "Ban Hammer", Rarity = PetConstants.Rarity.MYTHIC, BaseValue = 3200, BaseBoost = 1.20, SpawnChance = 0.1} -- SUPER DUPER RARE
    },
    
    -- LEVEL 7 - Legendary pets (64x value multiplier from Level 1)
    [7] = {
        {Name = "Rainbow Aqua Dragon", ModelName = "Rainbow Aqua Dragon", Rarity = PetConstants.Rarity.COMMON, BaseValue = 64, BaseBoost = 0.84, SpawnChance = 18.0},
        {Name = "Cyberpunk Dragon", ModelName = "Cyberpunk Dragon", Rarity = PetConstants.Rarity.COMMON, BaseValue = 64, BaseBoost = 0.84, SpawnChance = 16.0},
        {Name = "Cyborg Dragon", ModelName = "Cyborg Dragon", Rarity = PetConstants.Rarity.UNCOMMON, BaseValue = 128, BaseBoost = 0.93, SpawnChance = 14.0},
        {Name = "Partner Dragon", ModelName = "Partner Dragon", Rarity = PetConstants.Rarity.UNCOMMON, BaseValue = 128, BaseBoost = 0.98, SpawnChance = 12.0},
        {Name = "Hat Trick Dragon", ModelName = "Hat Trick Dragon", Rarity = PetConstants.Rarity.RARE, BaseValue = 256, BaseBoost = 1.02, SpawnChance = 10.0},
        {Name = "Circus Hat Trick Dragon", ModelName = "Circus Hat Trick Dragon", Rarity = PetConstants.Rarity.RARE, BaseValue = 320, BaseBoost = 1.05, SpawnChance = 8.0},
        {Name = "Guard Dragon", ModelName = "Guard Dragon", Rarity = PetConstants.Rarity.EPIC, BaseValue = 512, BaseBoost = 1.09, SpawnChance = 6.0},
        {Name = "Nerdy Dragon", ModelName = "Nerdy Dragon", Rarity = PetConstants.Rarity.EPIC, BaseValue = 640, BaseBoost = 1.13, SpawnChance = 5.0},
        {Name = "Elf Dragon", ModelName = "Elf Dragon", Rarity = PetConstants.Rarity.LEGENDARY, BaseValue = 1280, BaseBoost = 1.16, SpawnChance = 4.0},
        {Name = "Chocolate Dragon", ModelName = "Chocolate Dragon", Rarity = PetConstants.Rarity.MYTHIC, BaseValue = 3200, BaseBoost = 1.20, SpawnChance = 3.0},
        {Name = "Summer Dragon", ModelName = "Summer Dragon", Rarity = PetConstants.Rarity.COMMON, BaseValue = 64, BaseBoost = 0.84, SpawnChance = 2.0},
        {Name = "Valentines Dragon", ModelName = "Valentines Dragon", Rarity = PetConstants.Rarity.UNCOMMON, BaseValue = 192, BaseBoost = 1.02, SpawnChance = 1.5},
        {Name = "Time Traveller Doggy", ModelName = "Time Traveller Doggy", Rarity = PetConstants.Rarity.RARE, BaseValue = 384, BaseBoost = 1.07, SpawnChance = 1.0},
        {Name = "Witch Dominus", ModelName = "Witch Dominus", Rarity = PetConstants.Rarity.EPIC, BaseValue = 960, BaseBoost = 1.16, SpawnChance = 0.4},
        {Name = "Dominus Empyreus", ModelName = "White Dominus", Rarity = PetConstants.Rarity.MYTHIC, BaseValue = 6400, BaseBoost = 1.24, SpawnChance = 0.1} -- SUPER DUPER RARE
    }
}

-- Legacy BasePets array - generated from PetsByLevel for compatibility
PetConfig.BasePets = {}
for level, pets in pairs(PetConfig.PetsByLevel) do
    for _, pet in pairs(pets) do
        table.insert(PetConfig.BasePets, pet)
    end
end

-- Pet creation functions
function PetConfig.createPet(basePetData, variation, id)
    variation = variation or PetConstants.Variation.BRONZE
    id = id or game:GetService("HttpService"):GenerateGUID(false)
    
    local multiplier = PetConstants.getVariationMultiplier(variation)
    
    local pet = {
        ID = id,
        Name = basePetData.Name,
        ModelName = basePetData.ModelName, -- Include ModelName for rendering
        Rarity = basePetData.Rarity,
        Variation = variation,
        BaseValue = basePetData.BaseValue,
        BaseBoost = basePetData.BaseBoost,
        FinalValue = math.floor(basePetData.BaseValue * multiplier),
        FinalBoost = basePetData.BaseBoost * multiplier,
        SpawnChance = basePetData.SpawnChance -- Include SpawnChance for tutorial logic
    }
    
    return pet
end

function PetConfig.createRandomPet(rarityWeights, variationWeights)
    -- Default weights if not provided
    rarityWeights = rarityWeights or {
        [PetConstants.Rarity.COMMON] = 60,
        [PetConstants.Rarity.UNCOMMON] = 30,
        [PetConstants.Rarity.RARE] = 10
    }
    
    variationWeights = variationWeights or {
        [PetConstants.Variation.BRONZE] = 30.0,
        [PetConstants.Variation.SILVER] = 25.0,
        [PetConstants.Variation.GOLD] = 18.0,
        [PetConstants.Variation.PLATINUM] = 12.0,
        [PetConstants.Variation.DIAMOND] = 8.0,
        [PetConstants.Variation.EMERALD] = 4.0,
        [PetConstants.Variation.SAPPHIRE] = 2.0,
        [PetConstants.Variation.RUBY] = 0.8,
        [PetConstants.Variation.TITANIUM] = 0.4,
        [PetConstants.Variation.OBSIDIAN] = 0.3,
        [PetConstants.Variation.CRYSTAL] = 0.2,
        [PetConstants.Variation.RAINBOW] = 0.15,
        [PetConstants.Variation.COSMIC] = 0.1,
        [PetConstants.Variation.VOID] = 0.04,
        [PetConstants.Variation.DIVINE] = 0.01
    }
    
    -- Select random rarity
    local selectedRarity = PetConfig.weightedRandomSelect(rarityWeights)
    
    -- Get pets of selected rarity
    local petsOfRarity = {}
    for _, basePet in pairs(PetConfig.BasePets) do
        if basePet.Rarity == selectedRarity then
            table.insert(petsOfRarity, basePet)
        end
    end
    
    if #petsOfRarity == 0 then
        warn("No pets found for rarity: " .. selectedRarity)
        return nil
    end
    
    -- Select random pet from rarity
    local randomPet = petsOfRarity[math.random(1, #petsOfRarity)]
    
    -- Select random variation
    local selectedVariation = PetConfig.weightedRandomSelect(variationWeights)
    
    return PetConfig.createPet(randomPet, selectedVariation)
end

function PetConfig.weightedRandomSelect(weights)
    local totalWeight = 0
    for _, weight in pairs(weights) do
        totalWeight = totalWeight + weight
    end
    
    local randomValue = math.random() * totalWeight
    local currentWeight = 0
    
    for item, weight in pairs(weights) do
        currentWeight = currentWeight + weight
        if randomValue <= currentWeight then
            return item
        end
    end
    
    -- Fallback (should never reach here)
    local firstKey = next(weights)
    return firstKey
end

function PetConfig.getPetsByRarity(rarity)
    local pets = {}
    for _, basePet in pairs(PetConfig.BasePets) do
        if basePet.Rarity == rarity then
            table.insert(pets, basePet)
        end
    end
    return pets
end

function PetConfig.getBasePetByName(name)
    for _, basePet in pairs(PetConfig.BasePets) do
        if basePet.Name == name then
            return basePet
        end
    end
    return nil
end

-- Get pets available for a specific level
function PetConfig.getPetsByLevel(level)
    return PetConfig.PetsByLevel[level] or {}
end

-- NEW: Base pet weights configuration (easy to adjust)
-- Higher number = more common base spawn rate
PetConfig.BasePetWeights = {
    [1] = 100,   -- Pet 1 (most common)
    [2] = 80,    -- Pet 2
    [3] = 60,    -- Pet 3
    [4] = 45,    -- Pet 4
    [5] = 35,    -- Pet 5
    [6] = 25,    -- Pet 6
    [7] = 18,    -- Pet 7
    [8] = 12,    -- Pet 8
    [9] = 8,     -- Pet 9
    [10] = 5,    -- Pet 10
    [11] = 3,    -- Pet 11
    [12] = 2,    -- Pet 12
    [13] = 1.5,  -- Pet 13
    [14] = 1,    -- Pet 14
    [15] = 0.5   -- Pet 15 (rarest)
}

-- NEW: Position multipliers for bell curve distribution
PetConfig.PositionMultipliers = {
    OLD = 0.2,      -- Pets in first 20% of pool (very low)
    FADING = 0.5,   -- Pets in 20-40% range (low)
    PRIME = 1.5,    -- Pets in 40-60% range (peak/sweet spot)
    GOOD = 1.0,     -- Pets in 60-80% range (decent)
    NEW = 0.6       -- Pets in 80-100% range (newly introduced)
}

-- NEW: Door configuration per level
PetConfig.DoorsPerLevel = {
    [1] = 5,  -- Level 1 has 5 doors
    [2] = 7,  -- Levels 2-7 have 7 doors
    [3] = 7,
    [4] = 7,
    [5] = 7,
    [6] = 7,
    [7] = 7
}

-- NEW: How many pets are available at each door
PetConfig.PetsPerDoor = {
    [1] = {3, 6, 9, 12, 15},           -- Level 1: 3 pets added per door
    [2] = {3, 5, 7, 9, 11, 13, 15},    -- Level 2-7: 2 pets per door (except Door 1 with 3)
    [3] = {3, 5, 7, 9, 11, 13, 15},
    [4] = {3, 5, 7, 9, 11, 13, 15},
    [5] = {3, 5, 7, 9, 11, 13, 15},
    [6] = {3, 5, 7, 9, 11, 13, 15},
    [7] = {3, 5, 7, 9, 11, 13, 15}
}

-- NEW: Get position-based multiplier for a pet
function PetConfig.getPositionMultiplier(position)
    -- Bell curve formula: peaks at 0.5, drops at edges
    -- This creates a smooth transition instead of hard brackets
    return 0.3 + 1.4 * math.exp(-8 * (position - 0.5)^2)
end

-- NEW: Calculate door-specific weights for pets
function PetConfig.calculateDoorWeights(doorNumber, level)
    local petsPerDoor = PetConfig.PetsPerDoor[level]
    if not petsPerDoor then
        warn("PetConfig: No door configuration for level " .. tostring(level))
        return {}
    end
    
    local maxPetsForDoor = petsPerDoor[doorNumber]
    if not maxPetsForDoor then
        warn("PetConfig: No configuration for door " .. tostring(doorNumber) .. " in level " .. tostring(level))
        return {}
    end
    
    local levelPets = PetConfig.getPetsByLevel(level)
    if #levelPets == 0 then
        warn("PetConfig: No pets found for level " .. tostring(level))
        return {}
    end
    
    -- Get the pets available at this door (first N pets)
    local availablePets = {}
    for i = 1, math.min(maxPetsForDoor, #levelPets) do
        table.insert(availablePets, levelPets[i])
    end
    
    -- Calculate weights with position-based multipliers
    local weights = {}
    local totalWeight = 0
    
    for i, pet in ipairs(availablePets) do
        local baseWeight = PetConfig.BasePetWeights[i] or 1
        local position = i / #availablePets  -- 0 to 1
        local multiplier = PetConfig.getPositionMultiplier(position)
        
        local finalWeight = baseWeight * multiplier
        weights[pet] = finalWeight
        totalWeight = totalWeight + finalWeight
    end
    
    -- Normalize to percentages (sum to 100)
    if totalWeight > 0 then
        for pet, weight in pairs(weights) do
            weights[pet] = (weight / totalWeight) * 100
        end
    end
    
    return weights
end

-- NEW: Get the actual spawn chance of a specific pet at a specific door
function PetConfig.getPetSpawnChanceAtDoor(petIndex, doorNumber, level)
    local weights = PetConfig.calculateDoorWeights(doorNumber, level)
    local levelPets = PetConfig.getPetsByLevel(level)
    
    if petIndex > #levelPets then
        return 0
    end
    
    local pet = levelPets[petIndex]
    return weights[pet] or 0
end

-- Get the UI display rarity (using base spawn chance, not door-weighted)
-- This is for pet index display - shows the raw chance without door effects
function PetConfig.getUIDisplayRarity(petName, variation, level)
    if not petName or not variation then
        return "Unknown"
    end
    
    level = level or 1
    
    -- Find the pet in the level
    local levelPets = PetConfig.getPetsByLevel(level)
    if not levelPets or #levelPets == 0 then
        return "Unknown"
    end
    
    local petData = nil
    for _, pet in ipairs(levelPets) do
        if pet and pet.Name == petName then
            petData = pet
            break
        end
    end
    
    if not petData or not petData.SpawnChance then
        return "Unknown"
    end
    
    -- Get variation chance (as percentage) - all 15 variations
    local variationWeights = {
        [PetConstants.Variation.BRONZE] = 30.0,
        [PetConstants.Variation.SILVER] = 25.0,
        [PetConstants.Variation.GOLD] = 18.0,
        [PetConstants.Variation.PLATINUM] = 12.0,
        [PetConstants.Variation.DIAMOND] = 8.0,
        [PetConstants.Variation.EMERALD] = 4.0,
        [PetConstants.Variation.SAPPHIRE] = 2.0,
        [PetConstants.Variation.RUBY] = 0.8,
        [PetConstants.Variation.TITANIUM] = 0.4,
        [PetConstants.Variation.OBSIDIAN] = 0.3,
        [PetConstants.Variation.CRYSTAL] = 0.2,
        [PetConstants.Variation.RAINBOW] = 0.15,
        [PetConstants.Variation.COSMIC] = 0.1,
        [PetConstants.Variation.VOID] = 0.04,
        [PetConstants.Variation.DIVINE] = 0.01
    }
    
    -- Handle string variations
    if type(variation) == "string" then
        local stringToEnum = {
            ["Bronze"] = PetConstants.Variation.BRONZE,
            ["Silver"] = PetConstants.Variation.SILVER,
            ["Gold"] = PetConstants.Variation.GOLD,
            ["Platinum"] = PetConstants.Variation.PLATINUM,
            ["Diamond"] = PetConstants.Variation.DIAMOND,
            ["Emerald"] = PetConstants.Variation.EMERALD,
            ["Sapphire"] = PetConstants.Variation.SAPPHIRE,
            ["Ruby"] = PetConstants.Variation.RUBY,
            ["Titanium"] = PetConstants.Variation.TITANIUM,
            ["Obsidian"] = PetConstants.Variation.OBSIDIAN,
            ["Crystal"] = PetConstants.Variation.CRYSTAL,
            ["Rainbow"] = PetConstants.Variation.RAINBOW,
            ["Cosmic"] = PetConstants.Variation.COSMIC,
            ["Void"] = PetConstants.Variation.VOID,
            ["Divine"] = PetConstants.Variation.DIVINE
        }
        variation = stringToEnum[variation] or variation
    end
    
    local variationChance = variationWeights[variation]
    if not variationChance then
        return "Unknown"
    end
    
    -- Use raw SpawnChance from pet data (not door-weighted)
    local petChance = petData.SpawnChance
    
    -- Calculate combined chance
    local combinedChance = (petChance / 100) * (variationChance / 100)
    
    if combinedChance > 0 then
        return math.floor(1 / combinedChance)
    else
        return "Unknown"
    end
end

-- Calculate the true combined rarity of a pet (pet chance × variation chance)
-- This uses door-weighted chances for actual spawning
function PetConfig.getActualPetRarity(petName, variation, level, doorNumber)
    if not petName or not variation then
        return "Unknown"
    end
    
    level = level or 1
    
    -- Default to middle door if not specified
    if not doorNumber then
        local doorsInLevel = PetConfig.DoorsPerLevel[level] or 5
        doorNumber = math.ceil(doorsInLevel / 2)
    end
    
    -- Find the pet in the level
    local levelPets = PetConfig.getPetsByLevel(level)
    if not levelPets or #levelPets == 0 then
        return "Unknown"
    end
    
    local petIndex = nil
    for i, pet in ipairs(levelPets) do
        if pet and pet.Name == petName then
            petIndex = i
            break
        end
    end
    
    if not petIndex then
        return "Unknown"
    end
    
    -- Get pet spawn chance at this door (as percentage)
    local petChance = PetConfig.getPetSpawnChanceAtDoor(petIndex, doorNumber, level)
    if petChance <= 0 then
        return "Unknown"
    end
    
    -- Get variation chance (as percentage) - all 15 variations
    local variationWeights = {
        [PetConstants.Variation.BRONZE] = 30.0,
        [PetConstants.Variation.SILVER] = 25.0,
        [PetConstants.Variation.GOLD] = 18.0,
        [PetConstants.Variation.PLATINUM] = 12.0,
        [PetConstants.Variation.DIAMOND] = 8.0,
        [PetConstants.Variation.EMERALD] = 4.0,
        [PetConstants.Variation.SAPPHIRE] = 2.0,
        [PetConstants.Variation.RUBY] = 0.8,
        [PetConstants.Variation.TITANIUM] = 0.4,
        [PetConstants.Variation.OBSIDIAN] = 0.3,
        [PetConstants.Variation.CRYSTAL] = 0.2,
        [PetConstants.Variation.RAINBOW] = 0.15,
        [PetConstants.Variation.COSMIC] = 0.1,
        [PetConstants.Variation.VOID] = 0.04,
        [PetConstants.Variation.DIVINE] = 0.01
    }
    
    -- Handle string variations - all 15 variations
    if type(variation) == "string" then
        local stringToEnum = {
            ["Bronze"] = PetConstants.Variation.BRONZE,
            ["Silver"] = PetConstants.Variation.SILVER,
            ["Gold"] = PetConstants.Variation.GOLD,
            ["Platinum"] = PetConstants.Variation.PLATINUM,
            ["Diamond"] = PetConstants.Variation.DIAMOND,
            ["Emerald"] = PetConstants.Variation.EMERALD,
            ["Sapphire"] = PetConstants.Variation.SAPPHIRE,
            ["Ruby"] = PetConstants.Variation.RUBY,
            ["Titanium"] = PetConstants.Variation.TITANIUM,
            ["Obsidian"] = PetConstants.Variation.OBSIDIAN,
            ["Crystal"] = PetConstants.Variation.CRYSTAL,
            ["Rainbow"] = PetConstants.Variation.RAINBOW,
            ["Cosmic"] = PetConstants.Variation.COSMIC,
            ["Void"] = PetConstants.Variation.VOID,
            ["Divine"] = PetConstants.Variation.DIVINE
        }
        variation = stringToEnum[variation] or variation
    end
    
    local variationChance = variationWeights[variation]
    if not variationChance then
        return "Unknown"
    end
    
    -- Calculate combined chance
    local combinedChance = (petChance / 100) * (variationChance / 100)
    
    if combinedChance > 0 then
        return math.floor(1 / combinedChance)
    else
        return "Unknown"
    end
end

-- Create random pet for a specific level AND door using the new system
function PetConfig.createRandomPetForLevelAndDoor(level, doorNumber, variationWeights)
    local levelPets = PetConfig.getPetsByLevel(level)
    if #levelPets == 0 then
        warn("PetConfig: No pets found for level: " .. tostring(level))
        return nil
    end
    
    -- Calculate door-specific pet weights
    local petWeights = PetConfig.calculateDoorWeights(doorNumber, level)
    
    if not next(petWeights) then
        warn("PetConfig: No pet weights calculated for door " .. tostring(doorNumber) .. " in level " .. tostring(level))
        return nil
    end
    
    -- All 15 variation distribution
    variationWeights = variationWeights or {
        [PetConstants.Variation.BRONZE] = 30.0,
        [PetConstants.Variation.SILVER] = 25.0,
        [PetConstants.Variation.GOLD] = 18.0,
        [PetConstants.Variation.PLATINUM] = 12.0,
        [PetConstants.Variation.DIAMOND] = 8.0,
        [PetConstants.Variation.EMERALD] = 4.0,
        [PetConstants.Variation.SAPPHIRE] = 2.0,
        [PetConstants.Variation.RUBY] = 0.8,
        [PetConstants.Variation.TITANIUM] = 0.4,
        [PetConstants.Variation.OBSIDIAN] = 0.3,
        [PetConstants.Variation.CRYSTAL] = 0.2,
        [PetConstants.Variation.RAINBOW] = 0.15,
        [PetConstants.Variation.COSMIC] = 0.1,
        [PetConstants.Variation.VOID] = 0.04,
        [PetConstants.Variation.DIVINE] = 0.01
    }
    
    -- Select random pet based on door-weighted chances
    local selectedPet = PetConfig.weightedRandomSelect(petWeights)
    
    -- Select random variation
    local selectedVariation = PetConfig.weightedRandomSelect(variationWeights)
    
    return PetConfig.createPet(selectedPet, selectedVariation)
end

-- DEPRECATED: Old function redirects to new door-based system with door 1 as default
function PetConfig.createRandomPetForLevel(level, petWeights, variationWeights)
    -- Default to door 1 if no door specified (for backward compatibility)
    return PetConfig.createRandomPetForLevelAndDoor(level, 1, variationWeights)
end


return PetConfig