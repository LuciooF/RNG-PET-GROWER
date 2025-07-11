local PetConfig = {}

-- Pet definitions with their properties (20 rarities, 5 pets each = 100 total pets)
PetConfig.PETS = {
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

    -- === RARITY 6: MYTHIC === (Elemental masters)
    [26] = {
        name = "Fire Fox",
        assetPath = "Pets/Fire Fox",
        rarity = 6,
        spawnChance = 0.16,
        value = 40,
        isFlyingPet = false,
        baseBoost = 85
    },
    [27] = {
        name = "Magma Golem",
        assetPath = "Pets/Magma Golem",
        rarity = 6,
        spawnChance = 0.15,
        value = 40,
        isFlyingPet = false,
        baseBoost = 90
    },
    [28] = {
        name = "Glacier",
        assetPath = "Pets/Glacier",
        rarity = 6,
        spawnChance = 0.14,
        value = 40,
        isFlyingPet = false,
        baseBoost = 88
    },
    [29] = {
        name = "Storm Bird",
        assetPath = "Pets/Electro",
        rarity = 6,
        spawnChance = 0.13,
        value = 40,
        isFlyingPet = true,
        baseBoost = 95
    },
    [30] = {
        name = "Earth Guardian",
        assetPath = "Pets/Stone Golem",
        rarity = 6,
        spawnChance = 0.12,
        value = 40,
        isFlyingPet = false,
        baseBoost = 92
    },

    -- === RARITY 7: DIVINE === (Cosmic entities)
    [31] = {
        name = "Constellation",
        assetPath = "Pets/Constellation",
        rarity = 7,
        spawnChance = 0.15,
        value = 65,
        isFlyingPet = true,
        baseBoost = 110
    },
    [32] = {
        name = "Lunar Golem",
        assetPath = "Pets/Lunar Golem",
        rarity = 7,
        spawnChance = 0.14,
        value = 65,
        isFlyingPet = false,
        baseBoost = 115
    },
    [33] = {
        name = "Solar Phoenix",
        assetPath = "Pets/Lunar Lighthawk",
        rarity = 7,
        spawnChance = 0.13,
        value = 65,
        isFlyingPet = true,
        baseBoost = 120
    },
    [34] = {
        name = "Space Golem",
        assetPath = "Pets/Space Golem",
        rarity = 7,
        spawnChance = 0.12,
        value = 65,
        isFlyingPet = false,
        baseBoost = 118
    },
    [35] = {
        name = "Nebula Crawler",
        assetPath = "Pets/Mars Crawler",
        rarity = 7,
        spawnChance = 0.11,
        value = 65,
        isFlyingPet = true,
        baseBoost = 125
    },

    -- === RARITY 8: CELESTIAL === (Planetary powers)
    [36] = {
        name = "Saturn Floppa",
        assetPath = "Pets/Saturn Floppa",
        rarity = 8,
        spawnChance = 0.14,
        value = 100,
        isFlyingPet = true,
        baseBoost = 140
    },
    [37] = {
        name = "Neptune Golem",
        assetPath = "Pets/Neptune Golem",
        rarity = 8,
        spawnChance = 0.13,
        value = 100,
        isFlyingPet = false,
        baseBoost = 145
    },
    [38] = {
        name = "Venus Overlord",
        assetPath = "Pets/Venus Overlord",
        rarity = 8,
        spawnChance = 0.12,
        value = 100,
        isFlyingPet = true,
        baseBoost = 150
    },
    [39] = {
        name = "Jupiter Storm",
        assetPath = "Pets/Martian Species",
        rarity = 8,
        spawnChance = 0.11,
        value = 100,
        isFlyingPet = true,
        baseBoost = 155
    },
    [40] = {
        name = "Mercury Swift",
        assetPath = "Pets/Astronaut",
        rarity = 8,
        spawnChance = 0.10,
        value = 100,
        isFlyingPet = true,
        baseBoost = 160
    },

    -- === RARITY 9: COSMIC === (Galactic forces)
    [41] = {
        name = "Galaxy Doggy",
        assetPath = "Pets/Galaxy Doggy",
        rarity = 9,
        spawnChance = 0.13,
        value = 150,
        isFlyingPet = true,
        baseBoost = 180
    },
    [42] = {
        name = "Black Hole",
        assetPath = "Pets/The Watcher",
        rarity = 9,
        spawnChance = 0.12,
        value = 150,
        isFlyingPet = true,
        baseBoost = 190
    },
    [43] = {
        name = "Supernova",
        assetPath = "Pets/Alien Hydra",
        rarity = 9,
        spawnChance = 0.11,
        value = 150,
        isFlyingPet = true,
        baseBoost = 185
    },
    [44] = {
        name = "Quasar",
        assetPath = "Pets/Cyberpunk Dragon",
        rarity = 9,
        spawnChance = 0.10,
        value = 150,
        isFlyingPet = true,
        baseBoost = 195
    },
    [45] = {
        name = "Dark Matter",
        assetPath = "Pets/Dark Hydra",
        rarity = 9,
        spawnChance = 0.09,
        value = 150,
        isFlyingPet = true,
        baseBoost = 200
    },

    -- === RARITY 10: VOID === (Anti-reality entities)
    [46] = {
        name = "Void Walker",
        assetPath = "Pets/Soul Golem",
        rarity = 10,
        spawnChance = 0.12,
        value = 225,
        isFlyingPet = true,
        baseBoost = 220
    },
    [47] = {
        name = "Null Entity",
        assetPath = "Pets/1x1x1x1",
        rarity = 10,
        spawnChance = 0.11,
        value = 225,
        isFlyingPet = true,
        baseBoost = 230
    },
    [48] = {
        name = "Entropy Lord",
        assetPath = "Pets/Sinister Hydra",
        rarity = 10,
        spawnChance = 0.10,
        value = 225,
        isFlyingPet = true,
        baseBoost = 240
    },
    [49] = {
        name = "Reality Breaker",
        assetPath = "Pets/Hacked Alien Hydra",
        rarity = 10,
        spawnChance = 0.09,
        value = 225,
        isFlyingPet = true,
        baseBoost = 250
    },
    [50] = {
        name = "Absolute Zero",
        assetPath = "Pets/Matrix Robot",
        rarity = 10,
        spawnChance = 0.08,
        value = 225,
        isFlyingPet = true,
        baseBoost = 260
    },

    -- === RARITY 11: QUANTUM === (Reality manipulators)
    [51] = {
        name = "Quantum Cat",
        assetPath = "Pets/Matrix Kitty",
        rarity = 11,
        spawnChance = 0.11,
        value = 350,
        isFlyingPet = true,
        baseBoost = 280
    },
    [52] = {
        name = "Time Traveller",
        assetPath = "Pets/Time Traveller Doggy",
        rarity = 11,
        spawnChance = 0.10,
        value = 350,
        isFlyingPet = true,
        baseBoost = 290
    },
    [53] = {
        name = "Paradox Engine",
        assetPath = "Pets/Computer",
        rarity = 11,
        spawnChance = 0.09,
        value = 350,
        isFlyingPet = false,
        baseBoost = 300
    },
    [54] = {
        name = "Probability Storm",
        assetPath = "Pets/Glitched TV",
        rarity = 11,
        spawnChance = 0.08,
        value = 350,
        isFlyingPet = true,
        baseBoost = 310
    },
    [55] = {
        name = "Schrödinger's Pet",
        assetPath = "Pets/Mystery Cat",
        rarity = 11,
        spawnChance = 0.07,
        value = 350,
        isFlyingPet = true,
        baseBoost = 320
    },

    -- === RARITY 12: ETHEREAL === (Spirit realm beings)
    [56] = {
        name = "Ghost Kitty",
        assetPath = "Pets/Ghost Kitty",
        rarity = 12,
        spawnChance = 0.10,
        value = 500,
        isFlyingPet = true,
        baseBoost = 340
    },
    [57] = {
        name = "Spirit Dragon",
        assetPath = "Pets/Ghostdeeri",
        rarity = 12,
        spawnChance = 0.09,
        value = 500,
        isFlyingPet = true,
        baseBoost = 350
    },
    [58] = {
        name = "Phantom Lord",
        assetPath = "Pets/Grim Reaper",
        rarity = 12,
        spawnChance = 0.08,
        value = 500,
        isFlyingPet = true,
        baseBoost = 360
    },
    [59] = {
        name = "Astral Projection",
        assetPath = "Pets/Angel Mushroom",
        rarity = 12,
        spawnChance = 0.07,
        value = 500,
        isFlyingPet = true,
        baseBoost = 370
    },
    [60] = {
        name = "Soul Harvester",
        assetPath = "Pets/Headless Horseman",
        rarity = 12,
        spawnChance = 0.06,
        value = 500,
        isFlyingPet = true,
        baseBoost = 380
    },

    -- === RARITY 13: TRANSCENDENT === (Beyond mortal comprehension)
    [61] = {
        name = "Ascended Phoenix",
        assetPath = "Pets/Heart Phoenix",
        rarity = 13,
        spawnChance = 0.09,
        value = 750,
        isFlyingPet = true,
        baseBoost = 400
    },
    [62] = {
        name = "Enlightened One",
        assetPath = "Pets/Mystic Kitsune",
        rarity = 13,
        spawnChance = 0.08,
        value = 750,
        isFlyingPet = true,
        baseBoost = 420
    },
    [63] = {
        name = "Divine Architect",
        assetPath = "Pets/Developer Pet",
        rarity = 13,
        spawnChance = 0.07,
        value = 750,
        isFlyingPet = true,
        baseBoost = 440
    },
    [64] = {
        name = "Cosmic Consciousness",
        assetPath = "Pets/Mystic Flower",
        rarity = 13,
        spawnChance = 0.06,
        value = 750,
        isFlyingPet = true,
        baseBoost = 460
    },
    [65] = {
        name = "Truth Seeker",
        assetPath = "Pets/Eye",
        rarity = 13,
        spawnChance = 0.05,
        value = 750,
        isFlyingPet = true,
        baseBoost = 480
    },

    -- === RARITY 14: INFINITE === (Boundless power)
    [66] = {
        name = "Infinite Dragon",
        assetPath = "Pets/Emerald Dragon",
        rarity = 14,
        spawnChance = 0.08,
        value = 1100,
        isFlyingPet = true,
        baseBoost = 500
    },
    [67] = {
        name = "Endless Void",
        assetPath = "Pets/Cyclops",
        rarity = 14,
        spawnChance = 0.07,
        value = 1100,
        isFlyingPet = true,
        baseBoost = 525
    },
    [68] = {
        name = "Boundless Spirit",
        assetPath = "Pets/Enchanted Golem",
        rarity = 14,
        spawnChance = 0.06,
        value = 1100,
        isFlyingPet = true,
        baseBoost = 550
    },
    [69] = {
        name = "Eternal Flame",
        assetPath = "Pets/Hell Dragon",
        rarity = 14,
        spawnChance = 0.05,
        value = 1100,
        isFlyingPet = true,
        baseBoost = 575
    },
    [70] = {
        name = "Limitless Entity",
        assetPath = "Pets/Rainbow Aqua Dragon",
        rarity = 14,
        spawnChance = 0.04,
        value = 1100,
        isFlyingPet = true,
        baseBoost = 600
    },

    -- === RARITY 15: SUPREME === (Ultimate dominion)
    [71] = {
        name = "Supreme Overlord",
        assetPath = "Pets/Frosty Overlord",
        rarity = 15,
        spawnChance = 0.07,
        value = 1650,
        isFlyingPet = true,
        baseBoost = 625
    },
    [72] = {
        name = "Alpha Prime",
        assetPath = "Pets/Guard Dragon",
        rarity = 15,
        spawnChance = 0.06,
        value = 1650,
        isFlyingPet = true,
        baseBoost = 650
    },
    [73] = {
        name = "Omega Terminus",
        assetPath = "Pets/Sapphire Dragon",
        rarity = 15,
        spawnChance = 0.05,
        value = 1650,
        isFlyingPet = true,
        baseBoost = 675
    },
    [74] = {
        name = "Master Controller",
        assetPath = "Pets/Cyber Dominus",
        rarity = 15,
        spawnChance = 0.04,
        value = 1650,
        isFlyingPet = true,
        baseBoost = 700
    },
    [75] = {
        name = "Apex Predator",
        assetPath = "Pets/Golem Hydra",
        rarity = 15,
        spawnChance = 0.03,
        value = 1650,
        isFlyingPet = true,
        baseBoost = 725
    },

    -- === RARITY 16: OMNIPOTENT === (All-powerful forces)
    [76] = {
        name = "Reality Weaver",
        assetPath = "Pets/Hat Trick Dragon",
        rarity = 16,
        spawnChance = 0.06,
        value = 2500,
        isFlyingPet = true,
        baseBoost = 750
    },
    [77] = {
        name = "Fate Controller",
        assetPath = "Pets/Circus Hat Trick Dragon",
        rarity = 16,
        spawnChance = 0.05,
        value = 2500,
        isFlyingPet = true,
        baseBoost = 800
    },
    [78] = {
        name = "Law Maker",
        assetPath = "Pets/Ban Hammer",
        rarity = 16,
        spawnChance = 0.04,
        value = 2500,
        isFlyingPet = false,
        baseBoost = 850
    },
    [79] = {
        name = "Dimension Walker",
        assetPath = "Pets/Partner Dragon",
        rarity = 16,
        spawnChance = 0.03,
        value = 2500,
        isFlyingPet = true,
        baseBoost = 900
    },
    [80] = {
        name = "Power Absolute",
        assetPath = "Pets/Diamond Golem",
        rarity = 16,
        spawnChance = 0.02,
        value = 2500,
        isFlyingPet = false,
        baseBoost = 950
    },

    -- === RARITY 17: GODLIKE === (Divine supremacy)
    [81] = {
        name = "Genesis Creator",
        assetPath = "Pets/Emerald Golem",
        rarity = 17,
        spawnChance = 0.05,
        value = 3750,
        isFlyingPet = true,
        baseBoost = 1000
    },
    [82] = {
        name = "Cosmos Shaper",
        assetPath = "Pets/Ruby Golem",
        rarity = 17,
        spawnChance = 0.04,
        value = 3750,
        isFlyingPet = true,
        baseBoost = 1100
    },
    [83] = {
        name = "Time Sovereign",
        assetPath = "Pets/Cerulean Golem",
        rarity = 17,
        spawnChance = 0.03,
        value = 3750,
        isFlyingPet = true,
        baseBoost = 1200
    },
    [84] = {
        name = "Space Emperor",
        assetPath = "Pets/Arctic Golem",
        rarity = 17,
        spawnChance = 0.025,
        value = 3750,
        isFlyingPet = true,
        baseBoost = 1300
    },
    [85] = {
        name = "Matter King",
        assetPath = "Pets/Hell Golem",
        rarity = 17,
        spawnChance = 0.02,
        value = 3750,
        isFlyingPet = false,
        baseBoost = 1400
    },

    -- === RARITY 18: UNIVERSAL === (All-encompassing entities)
    [86] = {
        name = "Universal Mind",
        assetPath = "Pets/Vaporwave Golem",
        rarity = 18,
        spawnChance = 0.04,
        value = 5600,
        isFlyingPet = true,
        baseBoost = 1500
    },
    [87] = {
        name = "Existence Itself",
        assetPath = "Pets/Pastel Golem",
        rarity = 18,
        spawnChance = 0.03,
        value = 5600,
        isFlyingPet = true,
        baseBoost = 1650
    },
    [88] = {
        name = "Eternal Witness",
        assetPath = "Pets/Cyborg Dragon",
        rarity = 18,
        spawnChance = 0.025,
        value = 5600,
        isFlyingPet = true,
        baseBoost = 1800
    },
    [89] = {
        name = "Truth Absolute",
        assetPath = "Pets/Chocolate Dragon",
        rarity = 18,
        spawnChance = 0.02,
        value = 5600,
        isFlyingPet = true,
        baseBoost = 1950
    },
    [90] = {
        name = "Prime Mover",
        assetPath = "Pets/Neptunian Dragon",
        rarity = 18,
        spawnChance = 0.015,
        value = 5600,
        isFlyingPet = true,
        baseBoost = 2100
    },

    -- === RARITY 19: MULTIVERSAL === (Beyond single universes)
    [91] = {
        name = "Multiverse Guardian",
        assetPath = "Pets/Valentines Dragon",
        rarity = 19,
        spawnChance = 0.03,
        value = 8500,
        isFlyingPet = true,
        baseBoost = 2300
    },
    [92] = {
        name = "Reality Nexus",
        assetPath = "Pets/Arcade Dragon",
        rarity = 19,
        spawnChance = 0.025,
        value = 8500,
        isFlyingPet = true,
        baseBoost = 2500
    },
    [93] = {
        name = "Infinite Possibility",
        assetPath = "Pets/Summer Dragon",
        rarity = 19,
        spawnChance = 0.02,
        value = 8500,
        isFlyingPet = true,
        baseBoost = 2700
    },
    [94] = {
        name = "Paradox Resolver",
        assetPath = "Pets/Elf Dragon",
        rarity = 19,
        spawnChance = 0.015,
        value = 8500,
        isFlyingPet = true,
        baseBoost = 2900
    },
    [95] = {
        name = "Meta Entity",
        assetPath = "Pets/Nerdy Dragon",
        rarity = 19,
        spawnChance = 0.01,
        value = 8500,
        isFlyingPet = true,
        baseBoost = 3100
    },

    -- === RARITY 20: OMNIVERSAL === (The ultimate tier)
    [96] = {
        name = "The Beginning",
        assetPath = "Pets/Baby Dragon",
        rarity = 20,
        spawnChance = 0.025,
        value = 12500,
        isFlyingPet = true,
        baseBoost = 3500
    },
    [97] = {
        name = "The End",
        assetPath = "Pets/Acid Rain Dragon",
        rarity = 20,
        spawnChance = 0.02,
        value = 12500,
        isFlyingPet = true,
        baseBoost = 4000
    },
    [98] = {
        name = "Perfect Unity",
        assetPath = "Pets/Alien Dragon",
        rarity = 20,
        spawnChance = 0.015,
        value = 12500,
        isFlyingPet = true,
        baseBoost = 4500
    },
    [99] = {
        name = "Source Code",
        assetPath = "Pets/Puzzle Cube",
        rarity = 20,
        spawnChance = 0.01,
        value = 12500,
        isFlyingPet = false,
        baseBoost = 5000
    },
    [100] = {
        name = "∞ (Infinity)",
        assetPath = "Pets/Big Galactic Toucan",
        rarity = 20,
        spawnChance = 0.005,
        value = 12500,
        isFlyingPet = true,
        baseBoost = 10000
    }
}

-- Import modular size system
local PetSizeSystem = require(script.Parent.PetSizeSystem)
PetConfig.SIZES = PetSizeSystem.SIZES

-- Import modular aura system
local PetAuraSystem = require(script.Parent.PetAuraSystem)
PetConfig.AURAS = PetAuraSystem.AURAS

-- Function to randomly select an aura
function PetConfig:GetRandomAura()
    local rand = math.random()
    local cumulativeChance = 0
    
    for auraId, auraData in pairs(self.AURAS) do
        cumulativeChance = cumulativeChance + auraData.chance
        if rand <= cumulativeChance then
            return auraId, auraData
        end
    end
    
    -- Fallback to none
    return "none", self.AURAS.none
end

-- Import business logic functions
local PetConfigLogic = require(script.Parent.PetConfigLogic)
for methodName, method in pairs(PetConfigLogic) do
    PetConfig[methodName] = method
end

-- Pet rarity configurations (20 rarities, 5 pets each)
PetConfig.RARITY_CONFIG = {
    basic = {
        name = "Basic",
        color = Color3.fromRGB(200, 200, 200), -- Gray
        multiplier = 1.0, -- No bonus
        valueMultiplier = 1.0, -- No value bonus
        chance = 0.60, -- 60% chance (reduced from 70%)
        rarity = "Common"
    },
    wood = {
        name = "Wood",
        color = Color3.fromRGB(139, 69, 19), -- Brown
        multiplier = 1.2,
        valueMultiplier = 1.2,
        chance = 0.20, -- 20% chance (increased from 15%)
        rarity = "Uncommon"
    },
    silver = {
        name = "Silver",
        color = Color3.fromRGB(192, 192, 192), -- Silver
        multiplier = 1.5,
        valueMultiplier = 1.5,
        chance = 0.10, -- 10% chance (increased from 8%)
        rarity = "Rare"
    },
    gold = {
        name = "Gold",
        color = Color3.fromRGB(255, 215, 0), -- Gold
        multiplier = 2.0,
        valueMultiplier = 2.0,
        chance = 0.05, -- 5% chance (increased from 4%)
        rarity = "Epic"
    },
    diamond = {
        name = "Diamond",
        color = Color3.fromRGB(255, 255, 255), -- Pure White (like actual diamonds)
        multiplier = 3.0,
        valueMultiplier = 3.0,
        chance = 0.025, -- 2.5% chance (increased)
        rarity = "Legendary"
    },
    platinum = {
        name = "Platinum",
        color = Color3.fromRGB(229, 228, 226), -- Platinum
        multiplier = 4.0,
        valueMultiplier = 4.0,
        chance = 0.015, -- 1.5% chance (increased)
        rarity = "Mythic"
    },
    emerald = {
        name = "Emerald",
        color = Color3.fromRGB(80, 200, 120), -- Green
        multiplier = 5.0,
        valueMultiplier = 5.0,
        chance = 0.010, -- 1.0% chance (increased)
        rarity = "Mythic"
    },
    ruby = {
        name = "Ruby",
        color = Color3.fromRGB(224, 17, 95), -- Red
        multiplier = 6.0,
        valueMultiplier = 6.0,
        chance = 0.008, -- 0.8% chance (increased)
        rarity = "Mythic"
    },
    sapphire = {
        name = "Sapphire",
        color = Color3.fromRGB(65, 105, 225), -- Royal Blue (more vibrant)
        multiplier = 7.0,
        valueMultiplier = 7.0,
        chance = 0.005, -- 0.5% chance (increased)
        rarity = "Exotic"
    },
    rainbow = {
        name = "Rainbow",
        color = Color3.fromRGB(255, 0, 127), -- Hot Pink (will cycle through rainbow in effects)
        multiplier = 10.0,
        valueMultiplier = 10.0,
        chance = 0.003, -- 0.3% chance (increased)
        rarity = "Exotic"
    },
    cosmic = {
        name = "Cosmic",
        color = Color3.fromRGB(138, 43, 226), -- Blue Violet (more cosmic/galaxy-like)
        multiplier = 15.0,
        valueMultiplier = 15.0,
        chance = 0.002, -- 0.2% chance (increased)
        rarity = "Divine"
    },
    void = {
        name = "Void",
        color = Color3.fromRGB(50, 0, 50), -- Dark Purple
        multiplier = 25.0,
        valueMultiplier = 25.0,
        chance = 0.001, -- 0.1% chance (increased)
        rarity = "Divine"
    },
    celestial = {
        name = "Celestial",
        color = Color3.fromRGB(255, 255, 150), -- Light Yellow
        multiplier = 50.0,
        valueMultiplier = 50.0,
        chance = 0.001, -- 0.1% chance (increased)
        rarity = "Godly"
    },
    premium_rainbow = {
        name = "Premium Rainbow",
        color = Color3.fromRGB(255, 100, 255), -- Bright Magenta (will cycle through rainbow)
        multiplier = 100.0, -- Double the power of regular rainbow!
        valueMultiplier = 100.0,
        chance = 0.0, -- Only available on Developer Product pets
        rarity = "Developer Exclusive",
        special = true, -- Mark as special aura
        effects = {"rainbow_explosion", "premium_sparkles", "divine_blessing"}
    },
    -- Merged pet auras (only obtainable through Lab merging)
    merged = {
        name = "Merged",
        color = Color3.fromRGB(120, 255, 120), -- Bright Green
        multiplier = 1.0, -- Base multiplier, power comes from combined rarity
        valueMultiplier = 1.0,
        chance = 0.0, -- Only available through merging
        rarity = "Lab Created",
        special = true,
        mergedAura = true -- Mark as merged aura
    },
    zombie = {
        name = "Zombie",
        color = Color3.fromRGB(100, 50, 100), -- Dark Purple-Green
        multiplier = 1.0, -- Base multiplier, power comes from combined rarity
        valueMultiplier = 1.0,
        chance = 0.0, -- Only available through merging
        rarity = "Lab Created",
        special = true,
        mergedAura = true -- Mark as merged aura
    }
}

-- Function to randomly select an aura
function PetConfig:GetRandomAura()
    local rand = math.random()
    local cumulativeChance = 0
    
    for auraId, auraData in pairs(self.AURAS) do
        cumulativeChance = cumulativeChance + auraData.chance
        if rand <= cumulativeChance then
            return auraId, auraData
        end
    end
    
    -- Fallback to none
    return "none", self.AURAS.none
end

-- Pet rarity configurations (20 rarities, 5 pets each)
PetConfig.RARITY_CONFIG = {
    [1] = { name = "Basic", color = Color3.fromRGB(150, 150, 150), pets = {1, 2, 3, 4, 5} },
    [2] = { name = "Common", color = Color3.fromRGB(100, 255, 100), pets = {6, 7, 8, 9, 10} },
    [3] = { name = "Rare", color = Color3.fromRGB(100, 150, 255), pets = {11, 12, 13, 14, 15} },
    [4] = { name = "Epic", color = Color3.fromRGB(160, 100, 255), pets = {16, 17, 18, 19, 20} },
    [5] = { name = "Legendary", color = Color3.fromRGB(255, 200, 100), pets = {21, 22, 23, 24, 25} },
    [6] = { name = "Mythic", color = Color3.fromRGB(255, 100, 200), pets = {26, 27, 28, 29, 30} },
    [7] = { name = "Divine", color = Color3.fromRGB(255, 255, 100), pets = {31, 32, 33, 34, 35} },
    [8] = { name = "Celestial", color = Color3.fromRGB(135, 206, 250), pets = {36, 37, 38, 39, 40} },
    [9] = { name = "Cosmic", color = Color3.fromRGB(75, 0, 130), pets = {41, 42, 43, 44, 45} },
    [10] = { name = "Void", color = Color3.fromRGB(25, 25, 25), pets = {46, 47, 48, 49, 50} },
    [11] = { name = "Quantum", color = Color3.fromRGB(0, 255, 255), pets = {51, 52, 53, 54, 55} },
    [12] = { name = "Ethereal", color = Color3.fromRGB(200, 200, 255), pets = {56, 57, 58, 59, 60} },
    [13] = { name = "Transcendent", color = Color3.fromRGB(255, 215, 255), pets = {61, 62, 63, 64, 65} },
    [14] = { name = "Infinite", color = Color3.fromRGB(255, 255, 255), pets = {66, 67, 68, 69, 70} },
    [15] = { name = "Supreme", color = Color3.fromRGB(255, 215, 0), pets = {71, 72, 73, 74, 75} },
    [16] = { name = "Omnipotent", color = Color3.fromRGB(255, 100, 100), pets = {76, 77, 78, 79, 80} },
    [17] = { name = "Godlike", color = Color3.fromRGB(100, 255, 255), pets = {81, 82, 83, 84, 85} },
    [18] = { name = "Universal", color = Color3.fromRGB(255, 100, 255), pets = {86, 87, 88, 89, 90} },
    [19] = { name = "Multiversal", color = Color3.fromRGB(100, 100, 255), pets = {91, 92, 93, 94, 95} },
    [20] = { name = "Omniversal", color = Color3.fromRGB(255, 255, 255), pets = {96, 97, 98, 99, 100} },
    [21] = { name = "Rainbow", color = Color3.fromRGB(255, 0, 127), pets = {} } -- Developer Product exclusive rarity
}

function PetConfig:GetPetData(petId)
    return self.PETS[petId]
end

function PetConfig:GetPetsForRarity(rarity)
    local rarityConfig = self.RARITY_CONFIG[rarity]
    if not rarityConfig then
        return {}
    end
    
    local pets = {}
    for _, petId in pairs(rarityConfig.pets) do
        local petData = self.PETS[petId]
        if petData then
            table.insert(pets, {
                id = petId,
                data = petData
            })
        end
    end
    
    return pets
end

function PetConfig:GetRandomPetForRarity(rarity)
    local availablePets = self:GetPetsForRarity(rarity)
    if #availablePets == 0 then
        return nil
    end
    
    -- Weighted random selection based on spawn chance
    local totalWeight = 0
    for _, petSelection in ipairs(availablePets) do
        totalWeight = totalWeight + petSelection.data.spawnChance
    end
    
    local random = math.random() * totalWeight
    local currentWeight = 0
    
    for _, petSelection in ipairs(availablePets) do
        currentWeight = currentWeight + petSelection.data.spawnChance
        if random <= currentWeight then
            return petSelection
        end
    end
    
    -- Fallback to first pet
    return availablePets[1]
end

function PetConfig:GetRarityConfig(rarity)
    return self.RARITY_CONFIG[rarity]
end

function PetConfig:GetSizeData(sizeId)
    return self.SIZES[sizeId]
end

function PetConfig:GetSmallestSize()
    return 1 -- Tiny is the smallest size
end

function PetConfig:GetSizeCount()
    return #self.SIZES
end

-- Calculate authoritative pet value with aura and size multipliers
function PetConfig:CalculatePetValue(petId, aura, size)
    local petData = self:GetPetData(petId)
    if not petData then
        warn("PetConfig:CalculatePetValue - Invalid pet ID:", petId)
        return 1 -- Default value
    end
    
    local baseValue = petData.value or 1
    
    -- Apply aura multiplier
    local auraMultiplier = 1
    if aura and aura ~= "none" then
        local auraData = self.AURAS[aura]
        if auraData and auraData.multiplier then
            auraMultiplier = auraData.multiplier
        end
    end
    
    -- Apply size multiplier
    local sizeMultiplier = 1
    if size and size > 1 then
        local sizeData = self:GetSizeData(size)
        if sizeData and sizeData.multiplier then
            sizeMultiplier = sizeData.multiplier
        end
    end
    
    -- Calculate final value: base * aura * size
    local finalValue = math.floor(baseValue * auraMultiplier * sizeMultiplier)
    return math.max(1, finalValue) -- Ensure minimum value of 1
end

-- Validate pet collection data (server-side security function)
function PetConfig:ValidatePetCollection(petId, aura, size)
    -- Validate pet ID
    local petData = self:GetPetData(petId)
    if not petData then
        return false, "Invalid pet ID"
    end
    
    -- Validate aura
    if aura and aura ~= "none" then
        if not self.AURAS[aura] then
            return false, "Invalid aura"
        end
    end
    
    -- Validate size
    if size and size > 1 then
        local sizeData = self:GetSizeData(size)
        if not sizeData then
            return false, "Invalid size"
        end
    end
    
    return true, "Valid pet data"
end

-- Calculate combined rarity (pet spawn chance + aura chance)
function PetConfig:CalculateCombinedRarity(petId, aura)
    local petData = self:GetPetData(petId)
    if not petData then
        return 0, "1/∞" -- Invalid pet
    end
    
    local auraData = self.AURAS[aura or "none"]
    if not auraData then
        auraData = self.AURAS.none
    end
    
    -- Combined probability = pet spawn chance × aura chance
    local combinedProbability = petData.spawnChance * auraData.chance
    
    -- Convert to "1 in X" format
    local rarityNumber = math.floor(1 / combinedProbability)
    local rarityText = "1/" .. rarityNumber
    
    return combinedProbability, rarityText
end

-- Calculate dynamic boost based on combined rarity
function PetConfig:CalculateDynamicBoost(petId, aura, size)
    local petData = self:GetPetData(petId)
    if not petData then
        return 0
    end
    
    local combinedProbability, _ = self:CalculateCombinedRarity(petId, aura)
    local sizeData = self:GetSizeData(size or 1)
    
    -- Base boost from pet (much smaller base)
    local baseBoost = petData.baseBoost or 0.1
    
    -- Rarity multiplier based on how rare the combination is
    -- The rarer the pet+aura combo, the higher the boost
    -- Direct scaling: 1/317 = 0.317% boost, 1/1000 = 1% boost
    local rarityMultiplier = (1 / combinedProbability) / 100
    
    -- Size multiplier
    local sizeMultiplier = sizeData and sizeData.multiplier or 1
    
    -- Final boost calculation (direct percentage)
    local finalBoost = rarityMultiplier * sizeMultiplier
    
    
    return math.max(0.01, finalBoost) -- Minimum 0.01% boost
end

-- Get rarity tier name based on combined probability
function PetConfig:GetRarityTierName(combinedProbability)
    -- Expanded rarity system with 20+ tiers for better progression excitement
    if combinedProbability >= 0.1 then
        return "Common", Color3.fromRGB(150, 150, 150)          -- Gray
    elseif combinedProbability >= 0.05 then
        return "Uncommon", Color3.fromRGB(100, 255, 100)        -- Light Green
    elseif combinedProbability >= 0.02 then
        return "Rare", Color3.fromRGB(100, 150, 255)            -- Light Blue
    elseif combinedProbability >= 0.01 then
        return "Epic", Color3.fromRGB(160, 100, 255)            -- Purple
    elseif combinedProbability >= 0.005 then
        return "Legendary", Color3.fromRGB(255, 200, 100)       -- Orange/Gold
    elseif combinedProbability >= 0.002 then
        return "Mythic", Color3.fromRGB(255, 100, 200)          -- Pink
    elseif combinedProbability >= 0.001 then
        return "Exotic", Color3.fromRGB(100, 255, 255)          -- Cyan
    elseif combinedProbability >= 0.0005 then
        return "Divine", Color3.fromRGB(255, 255, 100)          -- Yellow
    elseif combinedProbability >= 0.0002 then
        return "Celestial", Color3.fromRGB(200, 150, 255)       -- Light Purple
    elseif combinedProbability >= 0.0001 then
        return "Cosmic", Color3.fromRGB(75, 0, 130)             -- Dark Purple
    elseif combinedProbability >= 0.00005 then
        return "Void", Color3.fromRGB(50, 50, 50)               -- Dark Gray
    elseif combinedProbability >= 0.00002 then
        return "Quantum", Color3.fromRGB(0, 255, 255)           -- Bright Cyan
    elseif combinedProbability >= 0.00001 then
        return "Ethereal", Color3.fromRGB(200, 200, 255)        -- Light Blue-Purple
    elseif combinedProbability >= 0.000005 then
        return "Transcendent", Color3.fromRGB(255, 215, 255)    -- Light Pink
    elseif combinedProbability >= 0.000002 then
        return "Infinite", Color3.fromRGB(255, 255, 255)        -- White
    elseif combinedProbability >= 0.000001 then
        return "Supreme", Color3.fromRGB(255, 215, 0)           -- Gold
    elseif combinedProbability >= 0.0000005 then
        return "Omnipotent", Color3.fromRGB(255, 100, 100)      -- Red
    elseif combinedProbability >= 0.0000002 then
        return "Godlike", Color3.fromRGB(100, 255, 255)         -- Bright Cyan
    elseif combinedProbability >= 0.0000001 then
        return "Universal", Color3.fromRGB(255, 100, 255)       -- Magenta
    elseif combinedProbability >= 0.00000005 then
        return "Multiversal", Color3.fromRGB(100, 100, 255)     -- Blue
    elseif combinedProbability >= 0.00000002 then
        return "Omniversal", Color3.fromRGB(255, 255, 255)      -- Bright White
    elseif combinedProbability >= 0.00000001 then
        return "Unreal", Color3.fromRGB(255, 0, 127)            -- Hot Pink
    elseif combinedProbability >= 0.000000005 then
        return "Impossible", Color3.fromRGB(127, 255, 0)        -- Bright Green
    elseif combinedProbability >= 0.000000002 then
        return "Legendary+", Color3.fromRGB(255, 127, 0)        -- Bright Orange
    elseif combinedProbability >= 0.000000001 then
        return "Mythic+", Color3.fromRGB(255, 0, 255)           -- Bright Magenta
    else
        return "Rainbow", Color3.fromRGB(255, 0, 127)           -- Ultimate Rainbow
    end
end

-- Enhanced pet value calculation using new boost system
function PetConfig:CalculateEnhancedPetValue(petId, aura, size)
    local petData = self:GetPetData(petId)
    if not petData then
        warn("PetConfig:CalculateEnhancedPetValue - Invalid pet ID:", petId)
        return 1
    end
    
    -- Get dynamic boost based on rarity
    local dynamicBoost = self:CalculateDynamicBoost(petId, aura, size)
    
    -- Base value from config
    local baseValue = petData.value or 1
    
    -- Calculate final value using the dynamic boost
    local finalValue = math.floor(baseValue * dynamicBoost)
    
    return math.max(1, finalValue)
end

-- Get comprehensive pet information including rarity calculations
function PetConfig:GetComprehensivePetInfo(petId, aura, size)
    local petData = self:GetPetData(petId)
    if not petData then
        return nil
    end
    
    local auraData = self.AURAS[aura or "none"]
    local sizeData = self:GetSizeData(size or 1)
    local combinedProbability, rarityText = self:CalculateCombinedRarity(petId, aura)
    local rarityTier, rarityColor = self:GetRarityTierName(combinedProbability)
    local dynamicBoost = self:CalculateDynamicBoost(petId, aura, size)
    local enhancedValue = self:CalculateEnhancedPetValue(petId, aura, size)
    
    return {
        petData = petData,
        auraData = auraData,
        sizeData = sizeData,
        combinedProbability = combinedProbability,
        rarityText = rarityText, -- e.g., "1/1000"
        rarityTier = rarityTier, -- e.g., "Legendary"
        rarityColor = rarityColor,
        dynamicBoost = dynamicBoost,
        enhancedValue = enhancedValue,
        moneyMultiplier = 1 + (dynamicBoost / 100) -- dynamicBoost is already a percentage
    }
end

-- Pet scanning function removed - no longer needed for maintenance

return PetConfig