-- Pet configuration and data
local PetConstants = require(script.Parent.Parent.constants.PetConstants)

local PetConfig = {}

-- Pet data structure template
PetConfig.PetTemplate = {
    Name = "",
    Rarity = PetConstants.Rarity.COMMON,
    Variation = PetConstants.Variation.BRONZE,
    BaseValue = 0,
    BaseBoost = 0,
    -- Runtime properties (added when pet is created)
    ID = nil,          -- Unique identifier
    FinalValue = 0,    -- BaseValue * VariationMultiplier
    FinalBoost = 0     -- BaseBoost * VariationMultiplier
}

-- Base pet definitions - 7 levels, 15 pets each, with individual spawn chances
-- Each pet has a specific tier and spawn chance: 18%, 16%, 14%, 12%, 10%, 8%, 6%, 5%, 4%, 3%, 2%, 1.5%, 1%, 0.4%, 0.1%
PetConfig.PetsByLevel = {
    -- LEVEL 1 - Starter Tier - Cool but accessible pets
    [1] = {
        -- 15 different rarities with incremental spawn chances
        -- Replaced boring cats/dogs with unique models from the 467 available
        {Name = "Gecko", ModelName = "Gecko", Rarity = PetConstants.Rarity.COMMON, BaseValue = 1, BaseBoost = 1.01, SpawnChance = 20.0},        -- 1 in 5
        {Name = "Red Panda", ModelName = "Red Panda", Rarity = PetConstants.Rarity.UNCOMMON, BaseValue = 2, BaseBoost = 1.02, SpawnChance = 10.0},     -- 1 in 10
        {Name = "Flamingo", ModelName = "Flamingo", Rarity = PetConstants.Rarity.RARE, BaseValue = 4, BaseBoost = 1.04, SpawnChance = 4.0},         -- 1 in 25
        {Name = "Capybara", ModelName = "Capybara", Rarity = PetConstants.Rarity.EPIC, BaseValue = 8, BaseBoost = 1.08, SpawnChance = 2.0},      -- 1 in 50
        {Name = "Sloth", ModelName = "Sloth", Rarity = PetConstants.Rarity.LEGENDARY, BaseValue = 16, BaseBoost = 1.16, SpawnChance = 1.0},   -- 1 in 100
        {Name = "Baby Dragon", ModelName = "Baby Dragon", Rarity = PetConstants.Rarity.MYTHIC, BaseValue = 32, BaseBoost = 1.32, SpawnChance = 0.4}, -- 1 in 250
        {Name = "Narwhal", ModelName = "Narwhal", Rarity = PetConstants.Rarity.ANCIENT, BaseValue = 64, BaseBoost = 1.64, SpawnChance = 0.2},      -- 1 in 500
        {Name = "Phoenix", ModelName = "Phoenix", Rarity = PetConstants.Rarity.CELESTIAL, BaseValue = 128, BaseBoost = 2.28, SpawnChance = 0.1}, -- 1 in 1k (Keep - already cool!)
        {Name = "Dragon", ModelName = "Dragon", Rarity = PetConstants.Rarity.TRANSCENDENT, BaseValue = 256, BaseBoost = 2.56, SpawnChance = 0.04}, -- 1 in 2.5k (Keep - already cool!)
        {Name = "Crystal Lord", ModelName = "Crystal Lord", Rarity = PetConstants.Rarity.OMNIPOTENT, BaseValue = 512, BaseBoost = 5.12, SpawnChance = 0.02}, -- 1 in 5k (Keep - already cool!)
        {Name = "Octopus", ModelName = "Octopus", Rarity = PetConstants.Rarity.ETHEREAL, BaseValue = 1024, BaseBoost = 10.24, SpawnChance = 0.01},   -- 1 in 10k
        {Name = "Pufferfish", ModelName = "Pufferfish", Rarity = PetConstants.Rarity.PRIMORDIAL, BaseValue = 2048, BaseBoost = 20.48, SpawnChance = 0.004}, -- 1 in 25k
        {Name = "Stegosaurus", ModelName = "Stegosaurus", Rarity = PetConstants.Rarity.COSMIC, BaseValue = 4096, BaseBoost = 40.96, SpawnChance = 0.002}, -- 1 in 50k
        {Name = "Grim Reaper", ModelName = "Grim Reaper", Rarity = PetConstants.Rarity.INFINITE, BaseValue = 8192, BaseBoost = 81.92, SpawnChance = 0.001}, -- 1 in 100k
        {Name = "The Chosen One", ModelName = "The Chosen One", Rarity = PetConstants.Rarity.OMNISCIENT, BaseValue = 16384, BaseBoost = 163.84, SpawnChance = 0.0001} -- 1 in 1M (Keep - already cool!)
    },
    
    -- LEVEL 2 - Cyberpunk/Space Tier - Futuristic and alien themes
    [2] = {
        -- 15 different rarities with incremental spawn chances - Tech/space themed pets
        {Name = "Vaporwave Cat", ModelName = "Vaporwave Cat", Rarity = PetConstants.Rarity.COMMON, BaseValue = 2, BaseBoost = 1.02, SpawnChance = 20.0},        -- 1 in 5
        {Name = "Cyber Cat", ModelName = "Cyber Cat", Rarity = PetConstants.Rarity.UNCOMMON, BaseValue = 4, BaseBoost = 1.04, SpawnChance = 10.0},     -- 1 in 10
        {Name = "Fire Fox", ModelName = "Fire Fox", Rarity = PetConstants.Rarity.RARE, BaseValue = 8, BaseBoost = 1.08, SpawnChance = 4.0},         -- 1 in 25 (Keep - already cool!)
        {Name = "Astronaut", ModelName = "Astronaut", Rarity = PetConstants.Rarity.EPIC, BaseValue = 16, BaseBoost = 1.16, SpawnChance = 2.0},      -- 1 in 50
        {Name = "Matrix Doggy", ModelName = "Matrix Doggy", Rarity = PetConstants.Rarity.LEGENDARY, BaseValue = 32, BaseBoost = 1.32, SpawnChance = 1.0},   -- 1 in 100
        {Name = "Alien Dragon", ModelName = "Alien Dragon", Rarity = PetConstants.Rarity.MYTHIC, BaseValue = 64, BaseBoost = 1.64, SpawnChance = 0.4}, -- 1 in 250
        {Name = "Mars Crawler", ModelName = "Mars Crawler", Rarity = PetConstants.Rarity.ANCIENT, BaseValue = 128, BaseBoost = 2.28, SpawnChance = 0.2},      -- 1 in 500
        {Name = "Saturn Cat", ModelName = "Saturn Cat", Rarity = PetConstants.Rarity.CELESTIAL, BaseValue = 256, BaseBoost = 2.56, SpawnChance = 0.1}, -- 1 in 1k
        {Name = "Cyber Dominus", ModelName = "Cyber Dominus", Rarity = PetConstants.Rarity.TRANSCENDENT, BaseValue = 512, BaseBoost = 5.12, SpawnChance = 0.04}, -- 1 in 2.5k (Keep - already cool!)
        {Name = "Neptune Golem", ModelName = "Neptune Golem", Rarity = PetConstants.Rarity.OMNIPOTENT, BaseValue = 1024, BaseBoost = 10.24, SpawnChance = 0.02}, -- 1 in 5k
        {Name = "Alien Hydra", ModelName = "Alien Hydra", Rarity = PetConstants.Rarity.ETHEREAL, BaseValue = 2048, BaseBoost = 20.48, SpawnChance = 0.01},   -- 1 in 10k  
        {Name = "Mecha Spider", ModelName = "Mecha Spider", Rarity = PetConstants.Rarity.PRIMORDIAL, BaseValue = 4096, BaseBoost = 40.96, SpawnChance = 0.004}, -- 1 in 25k
        {Name = "Cyber Robot", ModelName = "Cyber Robot", Rarity = PetConstants.Rarity.COSMIC, BaseValue = 8192, BaseBoost = 81.92, SpawnChance = 0.002}, -- 1 in 50k
        {Name = "Constellation", ModelName = "Constellation", Rarity = PetConstants.Rarity.INFINITE, BaseValue = 16384, BaseBoost = 163.84, SpawnChance = 0.001}, -- 1 in 100k
        {Name = "The Watcher", ModelName = "The Watcher", Rarity = PetConstants.Rarity.OMNISCIENT, BaseValue = 32768, BaseBoost = 327.68, SpawnChance = 0.0001} -- 1 in 1M (Keep - already cool!)
    },
    
    -- LEVEL 3 - Mythical/Fantasy Tier - Dragons, demons, and legendary creatures
    [3] = {
        -- 15 different rarities with incremental spawn chances - Epic fantasy creatures
        {Name = "Hell Dragon", ModelName = "Hell Dragon", Rarity = PetConstants.Rarity.COMMON, BaseValue = 4, BaseBoost = 1.04, SpawnChance = 20.0},        -- 1 in 5 (Keep - very cool!)
        {Name = "Heaven Peacock", ModelName = "Heaven Peacock", Rarity = PetConstants.Rarity.UNCOMMON, BaseValue = 8, BaseBoost = 1.08, SpawnChance = 10.0},     -- 1 in 10 (Keep - very cool!)
        {Name = "Emerald Dragon", ModelName = "Emerald Dragon", Rarity = PetConstants.Rarity.RARE, BaseValue = 16, BaseBoost = 1.16, SpawnChance = 4.0},         -- 1 in 25
        {Name = "Sapphire Dragon", ModelName = "Sapphire Dragon", Rarity = PetConstants.Rarity.EPIC, BaseValue = 32, BaseBoost = 1.32, SpawnChance = 2.0},      -- 1 in 50
        {Name = "Diamond Golem", ModelName = "Diamond Golem", Rarity = PetConstants.Rarity.LEGENDARY, BaseValue = 64, BaseBoost = 1.64, SpawnChance = 1.0},   -- 1 in 100
        {Name = "Kitsune", ModelName = "Kitsune", Rarity = PetConstants.Rarity.MYTHIC, BaseValue = 128, BaseBoost = 2.28, SpawnChance = 0.4}, -- 1 in 250
        {Name = "Headless Horseman", ModelName = "Headless Horseman", Rarity = PetConstants.Rarity.ANCIENT, BaseValue = 256, BaseBoost = 2.56, SpawnChance = 0.2},      -- 1 in 500
        {Name = "Cyber Dominus", ModelName = "Cyber Dominus", Rarity = PetConstants.Rarity.CELESTIAL, BaseValue = 512, BaseBoost = 5.12, SpawnChance = 0.1}, -- 1 in 1k
        {Name = "Gingerbread Dominus", ModelName = "Gingerbread Dominus", Rarity = PetConstants.Rarity.TRANSCENDENT, BaseValue = 1024, BaseBoost = 10.24, SpawnChance = 0.04}, -- 1 in 2.5k (Keep - unique!)
        {Name = "Soul Golem", ModelName = "Soul Golem", Rarity = PetConstants.Rarity.OMNIPOTENT, BaseValue = 2048, BaseBoost = 20.48, SpawnChance = 0.02}, -- 1 in 5k
        {Name = "Demon", ModelName = "Demon", Rarity = PetConstants.Rarity.ETHEREAL, BaseValue = 4096, BaseBoost = 40.96, SpawnChance = 0.01},   -- 1 in 10k (Keep - classic!)
        {Name = "Cyclops", ModelName = "Cyclops", Rarity = PetConstants.Rarity.PRIMORDIAL, BaseValue = 8192, BaseBoost = 81.92, SpawnChance = 0.004}, -- 1 in 25k
        {Name = "Ban Hammer", ModelName = "Ban Hammer", Rarity = PetConstants.Rarity.COSMIC, BaseValue = 16384, BaseBoost = 163.84, SpawnChance = 0.002}, -- 1 in 50k
        {Name = "Developer Pet", ModelName = "Developer Pet", Rarity = PetConstants.Rarity.INFINITE, BaseValue = 32768, BaseBoost = 327.68, SpawnChance = 0.001}, -- 1 in 100k
        {Name = "1x1x1x1", ModelName = "1x1x1x1", Rarity = PetConstants.Rarity.OMNISCIENT, BaseValue = 65536, BaseBoost = 655.36, SpawnChance = 0.0001} -- 1 in 1M (Keep - legendary Roblox reference!)
    },
    
    -- LEVEL 4 - Mystical/Food Tier - Magical creatures and themed pets
    [4] = {
        {Name = "Hot Dog", ModelName = "Hot Dog", Rarity = PetConstants.Rarity.COMMON, BaseValue = 8, BaseBoost = 1.06, SpawnChance = 18.0},
        {Name = "Ice Cream Cone", ModelName = "Ice Cream Cone", Rarity = PetConstants.Rarity.COMMON, BaseValue = 8, BaseBoost = 1.06, SpawnChance = 16.0},
        {Name = "Mystic Fox", ModelName = "Mystic Fox", Rarity = PetConstants.Rarity.UNCOMMON, BaseValue = 16, BaseBoost = 1.12, SpawnChance = 14.0}, -- Keep - unique!
        {Name = "Popcorn Cat", ModelName = "Popcorn Cat", Rarity = PetConstants.Rarity.UNCOMMON, BaseValue = 16, BaseBoost = 1.15, SpawnChance = 12.0},
        {Name = "Chocolate Dragon", ModelName = "Chocolate Dragon", Rarity = PetConstants.Rarity.RARE, BaseValue = 32, BaseBoost = 1.18, SpawnChance = 10.0},
        {Name = "Donut Doggy", ModelName = "Donut Doggy", Rarity = PetConstants.Rarity.RARE, BaseValue = 40, BaseBoost = 1.2, SpawnChance = 8.0},
        {Name = "Enchanted Golem", ModelName = "Enchanted Golem", Rarity = PetConstants.Rarity.EPIC, BaseValue = 64, BaseBoost = 1.25, SpawnChance = 6.0},
        {Name = "Enchanted Bunny", ModelName = "Enchanted Bunny", Rarity = PetConstants.Rarity.EPIC, BaseValue = 80, BaseBoost = 1.3, SpawnChance = 5.0},
        {Name = "Ruby Golem", ModelName = "Ruby Golem", Rarity = PetConstants.Rarity.LEGENDARY, BaseValue = 160, BaseBoost = 1.35, SpawnChance = 4.0},
        {Name = "Sapphire Dragon", ModelName = "Sapphire Dragon", Rarity = PetConstants.Rarity.MYTHIC, BaseValue = 400, BaseBoost = 1.4, SpawnChance = 3.0},
        -- 5 NEW PETS
        {Name = "Kitsune", ModelName = "Kitsune", Rarity = PetConstants.Rarity.COMMON, BaseValue = 8, BaseBoost = 1.06, SpawnChance = 2.0},
        {Name = "Owl", ModelName = "Chocolate Owl", Rarity = PetConstants.Rarity.UNCOMMON, BaseValue = 24, BaseBoost = 1.18, SpawnChance = 1.5},
        {Name = "Wizard Cat", ModelName = "Lucky Cat", Rarity = PetConstants.Rarity.RARE, BaseValue = 48, BaseBoost = 1.24, SpawnChance = 1.0},
        {Name = "Cyclops", ModelName = "Cyclops", Rarity = PetConstants.Rarity.EPIC, BaseValue = 120, BaseBoost = 1.36, SpawnChance = 0.4},
        {Name = "Developer Pet", ModelName = "Developer Pet", Rarity = PetConstants.Rarity.MYTHIC, BaseValue = 800, BaseBoost = 1.45, SpawnChance = 0.1} -- SUPER DUPER RARE
    },
    
    -- LEVEL 5 - Galactic pets (16x value multiplier from Level 1)
    [5] = {
        {Name = "Saturn Cat", ModelName = "Saturn Cat", Rarity = PetConstants.Rarity.COMMON, BaseValue = 16, BaseBoost = 1.08, SpawnChance = 18.0},
        {Name = "Saturn Doggy", ModelName = "Saturn Doggy", Rarity = PetConstants.Rarity.COMMON, BaseValue = 16, BaseBoost = 1.08, SpawnChance = 16.0},
        {Name = "Mars Crawler", ModelName = "Mars Crawler", Rarity = PetConstants.Rarity.UNCOMMON, BaseValue = 32, BaseBoost = 1.16, SpawnChance = 14.0},
        {Name = "Saturn Floppa", ModelName = "Saturn Floppa", Rarity = PetConstants.Rarity.UNCOMMON, BaseValue = 32, BaseBoost = 1.2, SpawnChance = 12.0},
        {Name = "Martian Cat", ModelName = "Martian Cat", Rarity = PetConstants.Rarity.RARE, BaseValue = 64, BaseBoost = 1.24, SpawnChance = 10.0},
        {Name = "Martian Doggy", ModelName = "Martian Doggy", Rarity = PetConstants.Rarity.RARE, BaseValue = 80, BaseBoost = 1.28, SpawnChance = 8.0},
        {Name = "Neptune Golem", ModelName = "Neptune Golem", Rarity = PetConstants.Rarity.EPIC, BaseValue = 128, BaseBoost = 1.32, SpawnChance = 6.0},
        {Name = "Lunar Golem", ModelName = "Lunar Golem", Rarity = PetConstants.Rarity.EPIC, BaseValue = 160, BaseBoost = 1.36, SpawnChance = 5.0},
        {Name = "Neptunian Dragon", ModelName = "Neptunian Dragon", Rarity = PetConstants.Rarity.LEGENDARY, BaseValue = 320, BaseBoost = 1.4, SpawnChance = 4.0},
        {Name = "Constellation", ModelName = "Constellation", Rarity = PetConstants.Rarity.MYTHIC, BaseValue = 800, BaseBoost = 1.45, SpawnChance = 3.0},
        -- 5 NEW PETS
        {Name = "Alien", ModelName = "Alien", Rarity = PetConstants.Rarity.COMMON, BaseValue = 16, BaseBoost = 1.08, SpawnChance = 2.0},
        {Name = "Astronaut", ModelName = "Astronaut", Rarity = PetConstants.Rarity.UNCOMMON, BaseValue = 48, BaseBoost = 1.24, SpawnChance = 1.5},
        {Name = "Space Golem", ModelName = "Space Golem", Rarity = PetConstants.Rarity.RARE, BaseValue = 96, BaseBoost = 1.30, SpawnChance = 1.0},
        {Name = "Venus Overlord", ModelName = "Venus Overlord", Rarity = PetConstants.Rarity.EPIC, BaseValue = 240, BaseBoost = 1.42, SpawnChance = 0.4},
        {Name = "Robux Fiend", ModelName = "Robux Fiend", Rarity = PetConstants.Rarity.MYTHIC, BaseValue = 1600, BaseBoost = 1.50, SpawnChance = 0.1} -- SUPER DUPER RARE
    },
    
    -- LEVEL 6 - Divine pets (32x value multiplier from Level 1)
    [6] = {
        {Name = "Angel", ModelName = "Angel", Rarity = PetConstants.Rarity.COMMON, BaseValue = 32, BaseBoost = 1.1, SpawnChance = 18.0},
        {Name = "Angel Bee", ModelName = "Angel Bee", Rarity = PetConstants.Rarity.COMMON, BaseValue = 32, BaseBoost = 1.1, SpawnChance = 16.0},
        {Name = "Angel Crab", ModelName = "Angel Crab", Rarity = PetConstants.Rarity.UNCOMMON, BaseValue = 64, BaseBoost = 1.2, SpawnChance = 14.0},
        {Name = "Cactus Angel", ModelName = "Cactus Angel", Rarity = PetConstants.Rarity.UNCOMMON, BaseValue = 64, BaseBoost = 1.25, SpawnChance = 12.0},
        {Name = "Heart Phoenix", ModelName = "Heart Phoenix", Rarity = PetConstants.Rarity.RARE, BaseValue = 128, BaseBoost = 1.3, SpawnChance = 10.0},
        {Name = "Heart Unicorn", ModelName = "Heart Unicorn", Rarity = PetConstants.Rarity.RARE, BaseValue = 160, BaseBoost = 1.35, SpawnChance = 8.0},
        {Name = "Heart Dominus", ModelName = "Heart Dominus", Rarity = PetConstants.Rarity.EPIC, BaseValue = 256, BaseBoost = 1.4, SpawnChance = 6.0},
        {Name = "Crystal Bunny 2.0", ModelName = "Crystal Bunny 2.0", Rarity = PetConstants.Rarity.EPIC, BaseValue = 320, BaseBoost = 1.45, SpawnChance = 5.0},
        {Name = "Diamond Golem", ModelName = "Diamond Golem", Rarity = PetConstants.Rarity.LEGENDARY, BaseValue = 640, BaseBoost = 1.5, SpawnChance = 4.0},
        {Name = "Emerald Golem", ModelName = "Emerald Golem", Rarity = PetConstants.Rarity.MYTHIC, BaseValue = 1600, BaseBoost = 1.55, SpawnChance = 3.0},
        -- 5 NEW PETS
        {Name = "Angel Mushroom", ModelName = "Angel Mushroom", Rarity = PetConstants.Rarity.COMMON, BaseValue = 32, BaseBoost = 1.1, SpawnChance = 2.0},
        {Name = "Heart Floppa", ModelName = "Heart Floppa", Rarity = PetConstants.Rarity.UNCOMMON, BaseValue = 96, BaseBoost = 1.30, SpawnChance = 1.5},
        {Name = "Heart Husky", ModelName = "Heart Husky", Rarity = PetConstants.Rarity.RARE, BaseValue = 192, BaseBoost = 1.36, SpawnChance = 1.0},
        {Name = "Headless Horseman", ModelName = "Headless Horseman", Rarity = PetConstants.Rarity.EPIC, BaseValue = 480, BaseBoost = 1.48, SpawnChance = 0.4},
        {Name = "Ban Hammer", ModelName = "Ban Hammer", Rarity = PetConstants.Rarity.MYTHIC, BaseValue = 3200, BaseBoost = 1.60, SpawnChance = 0.1} -- SUPER DUPER RARE
    },
    
    -- LEVEL 7 - Legendary pets (64x value multiplier from Level 1)
    [7] = {
        {Name = "Rainbow Aqua Dragon", ModelName = "Rainbow Aqua Dragon", Rarity = PetConstants.Rarity.COMMON, BaseValue = 64, BaseBoost = 1.12, SpawnChance = 18.0},
        {Name = "Cyberpunk Dragon", ModelName = "Cyberpunk Dragon", Rarity = PetConstants.Rarity.COMMON, BaseValue = 64, BaseBoost = 1.12, SpawnChance = 16.0},
        {Name = "Cyborg Dragon", ModelName = "Cyborg Dragon", Rarity = PetConstants.Rarity.UNCOMMON, BaseValue = 128, BaseBoost = 1.24, SpawnChance = 14.0},
        {Name = "Partner Dragon", ModelName = "Partner Dragon", Rarity = PetConstants.Rarity.UNCOMMON, BaseValue = 128, BaseBoost = 1.3, SpawnChance = 12.0},
        {Name = "Hat Trick Dragon", ModelName = "Hat Trick Dragon", Rarity = PetConstants.Rarity.RARE, BaseValue = 256, BaseBoost = 1.36, SpawnChance = 10.0},
        {Name = "Circus Hat Trick Dragon", ModelName = "Circus Hat Trick Dragon", Rarity = PetConstants.Rarity.RARE, BaseValue = 320, BaseBoost = 1.4, SpawnChance = 8.0},
        {Name = "Guard Dragon", ModelName = "Guard Dragon", Rarity = PetConstants.Rarity.EPIC, BaseValue = 512, BaseBoost = 1.45, SpawnChance = 6.0},
        {Name = "Nerdy Dragon", ModelName = "Nerdy Dragon", Rarity = PetConstants.Rarity.EPIC, BaseValue = 640, BaseBoost = 1.5, SpawnChance = 5.0},
        {Name = "Elf Dragon", ModelName = "Elf Dragon", Rarity = PetConstants.Rarity.LEGENDARY, BaseValue = 1280, BaseBoost = 1.55, SpawnChance = 4.0},
        {Name = "Chocolate Dragon", ModelName = "Chocolate Dragon", Rarity = PetConstants.Rarity.MYTHIC, BaseValue = 3200, BaseBoost = 1.6, SpawnChance = 3.0},
        -- 5 NEW PETS
        {Name = "Summer Dragon", ModelName = "Summer Dragon", Rarity = PetConstants.Rarity.COMMON, BaseValue = 64, BaseBoost = 1.12, SpawnChance = 2.0},
        {Name = "Valentines Dragon", ModelName = "Valentines Dragon", Rarity = PetConstants.Rarity.UNCOMMON, BaseValue = 192, BaseBoost = 1.36, SpawnChance = 1.5},
        {Name = "Time Traveller Doggy", ModelName = "Time Traveller Doggy", Rarity = PetConstants.Rarity.RARE, BaseValue = 384, BaseBoost = 1.42, SpawnChance = 1.0},
        {Name = "Witch Dominus", ModelName = "Witch Dominus", Rarity = PetConstants.Rarity.EPIC, BaseValue = 960, BaseBoost = 1.54, SpawnChance = 0.4},
        {Name = "Dominus Empyreus", ModelName = "White Dominus", Rarity = PetConstants.Rarity.MYTHIC, BaseValue = 6400, BaseBoost = 1.65, SpawnChance = 0.1} -- SUPER DUPER RARE
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
        [PetConstants.Variation.BRONZE] = 50,
        [PetConstants.Variation.SILVER] = 35,
        [PetConstants.Variation.GOLD] = 15
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

-- Create random pet for a specific level using individual spawn chances
function PetConfig.createRandomPetForLevel(level, petWeights, variationWeights)
    local levelPets = PetConfig.getPetsByLevel(level)
    if #levelPets == 0 then
        warn("No pets found for level: " .. tostring(level))
        return nil
    end
    
    -- Build pet weights from SpawnChance if not provided
    if not petWeights then
        petWeights = {}
        for _, pet in pairs(levelPets) do
            petWeights[pet] = pet.SpawnChance or 1.0
        end
    end
    
    -- 15 variation distribution with proper rarity curve
    variationWeights = variationWeights or {
        [PetConstants.Variation.BRONZE] = 25.0,    -- Most common
        [PetConstants.Variation.SILVER] = 20.0,
        [PetConstants.Variation.GOLD] = 15.0,
        [PetConstants.Variation.PLATINUM] = 12.0,
        [PetConstants.Variation.DIAMOND] = 10.0,
        [PetConstants.Variation.EMERALD] = 8.0,
        [PetConstants.Variation.SAPPHIRE] = 5.0,
        [PetConstants.Variation.RUBY] = 3.0,
        [PetConstants.Variation.TITANIUM] = 1.5,
        [PetConstants.Variation.OBSIDIAN] = 0.3,
        [PetConstants.Variation.CRYSTAL] = 0.1,
        [PetConstants.Variation.RAINBOW] = 0.05,
        [PetConstants.Variation.COSMIC] = 0.03,
        [PetConstants.Variation.VOID] = 0.015,
        [PetConstants.Variation.DIVINE] = 0.005    -- Rarest (0.005% chance)
    }
    
    -- Select random pet based on individual spawn chances
    local selectedPet = PetConfig.weightedRandomSelect(petWeights)
    
    -- Select random variation
    local selectedVariation = PetConfig.weightedRandomSelect(variationWeights)
    
    return PetConfig.createPet(selectedPet, selectedVariation)
end

return PetConfig