-- Basic Tier Pets (Rarities 1-5)
-- Modular pet configuration following CLAUDE.md architectural patterns

return {
    -- === RARITY 1: BASIC === (Starter pets)
    [1] = {
        name = "Forest Squirrel",
        assetPath = "Pets/Squirrel",
        rarity = 1,
        spawnChance = 0.25,
        value = 2,
        isFlyingPet = false,
        baseBoost = 10
    },
    [2] = {
        name = "Field Mouse",
        assetPath = "Pets/Mouse",
        rarity = 1,
        spawnChance = 0.24,
        value = 3,
        isFlyingPet = false,
        baseBoost = 12
    },
    [3] = {
        name = "Farm Chicken",
        assetPath = "Pets/Chicken",
        rarity = 1,
        spawnChance = 0.23,
        value = 4,
        isFlyingPet = false,
        baseBoost = 11
    },
    [4] = {
        name = "Ant",
        assetPath = "Pets/Ant",
        rarity = 1,
        spawnChance = 0.15,
        value = 5,
        isFlyingPet = false,
        baseBoost = 8
    },
    [5] = {
        name = "Cat",
        assetPath = "Pets/Cat",
        rarity = 1,
        spawnChance = 0.13,
        value = 4,
        isFlyingPet = false,
        baseBoost = 9
    },

    -- === RARITY 2: COMMON === (Farm animals & basic pets)
    [6] = {
        name = "Cow",
        assetPath = "Pets/Cow",
        rarity = 2,
        spawnChance = 0.22,
        value = 8,
        isFlyingPet = false,
        baseBoost = 15
    },
    [7] = {
        name = "Piggy",
        assetPath = "Pets/Piggy",
        rarity = 2,
        spawnChance = 0.21,
        value = 10,
        isFlyingPet = false,
        baseBoost = 16
    },
    [8] = {
        name = "Lamb",
        assetPath = "Pets/Lamb",
        rarity = 2,
        spawnChance = 0.20,
        value = 12,
        isFlyingPet = false,
        baseBoost = 17
    },
    [9] = {
        name = "Goat",
        assetPath = "Pets/Goat",
        rarity = 2,
        spawnChance = 0.19,
        value = 14,
        isFlyingPet = false,
        baseBoost = 18
    },
    [10] = {
        name = "Brown Bear",
        assetPath = "Pets/Brown Bear",
        rarity = 2,
        spawnChance = 0.18,
        value = 15,
        isFlyingPet = false,
        baseBoost = 20
    },

    -- === RARITY 3: RARE === (Exotic animals)
    [11] = {
        name = "Red Panda",
        assetPath = "Pets/Red Panda",
        rarity = 3,
        spawnChance = 0.19,
        value = 25,
        isFlyingPet = false,
        baseBoost = 25
    },
    [12] = {
        name = "Panda",
        assetPath = "Pets/Panda",
        rarity = 3,
        spawnChance = 0.18,
        value = 30,
        isFlyingPet = false,
        baseBoost = 27
    },
    [13] = {
        name = "Tiger",
        assetPath = "Pets/Tiger",
        rarity = 3,
        spawnChance = 0.17,
        value = 35,
        isFlyingPet = false,
        baseBoost = 30
    },
    [14] = {
        name = "Polar Bear",
        assetPath = "Pets/Polar Bear",
        rarity = 3,
        spawnChance = 0.16,
        value = 38,
        isFlyingPet = false,
        baseBoost = 32
    },
    [15] = {
        name = "Flamingo",
        assetPath = "Pets/Flamingo",
        rarity = 3,
        spawnChance = 0.15,
        value = 40,
        isFlyingPet = true,
        baseBoost = 35
    },

    -- === RARITY 4: EPIC === (Mythological creatures)
    [16] = {
        name = "Unicorn",
        assetPath = "Pets/Unicorn",
        rarity = 4,
        spawnChance = 0.18,
        value = 80,
        isFlyingPet = false,
        baseBoost = 40
    },
    [17] = {
        name = "Phoenix",
        assetPath = "Pets/Phoenix",
        rarity = 4,
        spawnChance = 0.17,
        value = 90,
        isFlyingPet = true,
        baseBoost = 45
    },
    [18] = {
        name = "Kitsune",
        assetPath = "Pets/Kitsune",
        rarity = 4,
        spawnChance = 0.16,
        value = 100,
        isFlyingPet = false,
        baseBoost = 42
    },
    [19] = {
        name = "Dragon",
        assetPath = "Pets/Dragon",
        rarity = 4,
        spawnChance = 0.15,
        value = 110,
        isFlyingPet = true,
        baseBoost = 50
    },
    [20] = {
        name = "Pegasus",
        assetPath = "Pets/Toucan",
        rarity = 4,
        spawnChance = 0.14,
        value = 120,
        isFlyingPet = true,
        baseBoost = 48
    },

    -- === RARITY 5: LEGENDARY === (Divine & celestial beings)
    [21] = {
        name = "Angel",
        assetPath = "Pets/Angel",
        rarity = 5,
        spawnChance = 0.17,
        value = 25,
        isFlyingPet = true,
        baseBoost = 60
    },
    [22] = {
        name = "Demon",
        assetPath = "Pets/Demon",
        rarity = 5,
        spawnChance = 0.16,
        value = 25,
        isFlyingPet = true,
        baseBoost = 65
    },
    [23] = {
        name = "Heaven Peacock",
        assetPath = "Pets/Heaven Peacock",
        rarity = 5,
        spawnChance = 0.15,
        value = 25,
        isFlyingPet = true,
        baseBoost = 62
    },
    [24] = {
        name = "Crystal Lord",
        assetPath = "Pets/Crystal Lord",
        rarity = 5,
        spawnChance = 0.14,
        value = 25,
        isFlyingPet = false,
        baseBoost = 70
    },
    [25] = {
        name = "The Chosen One",
        assetPath = "Pets/The Chosen One",
        rarity = 5,
        spawnChance = 0.13,
        value = 25,
        isFlyingPet = true,
        baseBoost = 75
    },
}