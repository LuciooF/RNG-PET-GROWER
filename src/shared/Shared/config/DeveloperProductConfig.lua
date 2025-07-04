-- Developer Product Configuration
-- Defines all purchasable developer products (consumables)

local DeveloperProductConfig = {}

-- Developer product types
DeveloperProductConfig.TYPES = {
    PET = "Pet",
    CURRENCY = "Currency", 
    BOOST = "Boost",
    SPECIAL = "Special"
}

-- Developer products
DeveloperProductConfig.PRODUCTS = {
    -- === RAINBOW RARITY PETS (Premium) ===
    [1] = {
        id = 234567890, -- Replace with actual Roblox developer product ID
        name = "TheChosenOne",
        displayName = "🌈 The Chosen One",
        description = "The legendary chosen hero with rainbow destiny!",
        type = DeveloperProductConfig.TYPES.PET,
        price = 1999, -- Robux
        icon = "rbxassetid://234567890",
        petData = {
            name = "The Chosen One",
            assetPath = "Pets/The Chosen One",
            rarity = 21, -- Rainbow rarity
            value = 50000,
            description = "Destined for greatness, this legendary being wields rainbow magic.",
            isFlyingPet = true,
            baseBoost = 2000,
            specialEffects = {"destiny_aura", "rainbow_nova", "chosen_blessing"}
        }
    },
    
    [2] = {
        id = 234567891,
        name = "CrystalLord",
        displayName = "🌈 Crystal Lord",
        description = "Ultimate rainbow crystal entity with immense power!",
        type = DeveloperProductConfig.TYPES.PET,
        price = 1299,
        icon = "rbxassetid://234567891",
        petData = {
            name = "Crystal Lord",
            assetPath = "Pets/Crystal Lord", 
            rarity = 21, -- Rainbow rarity
            value = 35000,
            description = "The supreme ruler of all crystals, radiating rainbow energy.",
            isFlyingPet = true,
            baseBoost = 1500,
            specialEffects = {"crystal_explosion", "rainbow_beam"}
        }
    },
    
    [3] = {
        id = 234567892,
        name = "TheWatcher",
        displayName = "🌈 The Watcher",
        description = "Mysterious all-seeing entity with rainbow vision!",
        type = DeveloperProductConfig.TYPES.PET,
        price = 1799,
        icon = "rbxassetid://234567892",
        petData = {
            name = "The Watcher",
            assetPath = "Pets/The Watcher",
            rarity = 21, -- Rainbow rarity
            value = 45000,
            description = "An enigmatic being that watches over all with rainbow sight.",
            isFlyingPet = true,
            baseBoost = 1800,
            specialEffects = {"omniscient_gaze", "rainbow_eye_beam", "cosmic_awareness"}
        }
    },
    
    [4] = {
        id = 234567893,
        name = "RainbowAquaDragon",
        displayName = "🌈 Rainbow Aqua Dragon",
        description = "Majestic dragon of rainbow waters and cosmic power!",
        type = DeveloperProductConfig.TYPES.PET,
        price = 1499,
        icon = "rbxassetid://234567893",
        petData = {
            name = "Rainbow Aqua Dragon",
            assetPath = "Pets/Rainbow Aqua Dragon",
            rarity = 21, -- Rainbow rarity
            value = 40000,
            description = "A cosmic dragon that commands both water and rainbow elements.",
            isFlyingPet = true,
            baseBoost = 1600,
            specialEffects = {"aqua_rainbow_breath", "cosmic_waves"}
        }
    },
    
    [5] = {
        id = 234567894,
        name = "CyberpunkDragon",
        displayName = "🌈 Cyberpunk Dragon",
        description = "Futuristic rainbow-tech dragon from the digital realm!",
        type = DeveloperProductConfig.TYPES.PET,
        price = 1199,
        icon = "rbxassetid://234567894",
        petData = {
            name = "Cyberpunk Dragon",
            assetPath = "Pets/Cyberpunk Dragon",
            rarity = 21, -- Rainbow rarity
            value = 30000,
            description = "A high-tech dragon enhanced with rainbow cybernetic implants.",
            isFlyingPet = true,
            baseBoost = 1200,
            specialEffects = {"cyber_rainbow_pulse", "digital_storm"}
        }
    },
    
    [6] = {
        id = 234567895,
        name = "SinisterHydra",
        displayName = "🌈 Sinister Hydra",
        description = "Dark rainbow hydra with multiple powerful heads!",
        type = DeveloperProductConfig.TYPES.PET,
        price = 1699,
        icon = "rbxassetid://234567895",
        petData = {
            name = "Sinister Hydra",
            assetPath = "Pets/Sinister Hydra",
            rarity = 21, -- Rainbow rarity
            value = 42000,
            description = "A multi-headed beast that breathes dark rainbow flames.",
            isFlyingPet = false,
            baseBoost = 1700,
            specialEffects = {"hydra_rainbow_breath", "sinister_regeneration"}
        }
    },
    
    [7] = {
        id = 234567896,
        name = "DiamondTuberPet",
        displayName = "🌈 Diamond Tuber Pet",
        description = "Exclusive rainbow YouTuber companion!",
        type = DeveloperProductConfig.TYPES.PET,
        price = 899,
        icon = "rbxassetid://234567896",
        petData = {
            name = "Diamond Tuber Pet",
            assetPath = "Pets/Diamond Tuber Pet",
            rarity = 21, -- Rainbow rarity
            value = 25000,
            description = "A premium creator's companion infused with rainbow energy.",
            isFlyingPet = true,
            baseBoost = 1000,
            specialEffects = {"content_creation_aura", "rainbow_subscriber_beam"}
        }
    },
    
    [8] = {
        id = 234567897,
        name = "AngelDominus",
        displayName = "🌈 Angel Dominus",
        description = "Divine rainbow crown with heavenly powers!",
        type = DeveloperProductConfig.TYPES.PET,
        price = 1399,
        icon = "rbxassetid://234567897",
        petData = {
            name = "Angel Dominus",
            assetPath = "Pets/Angel",  -- Using Angel from your list
            rarity = 21, -- Rainbow rarity
            value = 38000,
            description = "A sacred crown blessed with divine rainbow light.",
            isFlyingPet = true,
            baseBoost = 1400,
            specialEffects = {"divine_blessing", "rainbow_halo", "celestial_wings"}
        }
    },
    
    [9] = {
        id = 234567898,
        name = "DemonicDragon",
        displayName = "🌈 Demonic Dragon",
        description = "Dark rainbow dragon from the underworld!",
        type = DeveloperProductConfig.TYPES.PET,
        price = 1899,
        icon = "rbxassetid://234567898",
        petData = {
            name = "Demonic Dragon",
            assetPath = "Pets/Demonic Dragon",
            rarity = 21, -- Rainbow rarity
            value = 48000,
            description = "A fearsome dragon infused with dark rainbow flames.",
            isFlyingPet = true,
            baseBoost = 1900,
            specialEffects = {"dark_rainbow_breath", "shadow_wings", "demonic_aura"}
        }
    },
    
    [10] = {
        id = 234567899,
        name = "RainbowUnicorn",
        displayName = "🌈 Rainbow Unicorn",
        description = "Magical rainbow unicorn of pure wonder!",
        type = DeveloperProductConfig.TYPES.PET,
        price = 999,
        icon = "rbxassetid://234567899",
        petData = {
            name = "Rainbow Unicorn",
            assetPath = "Pets/Unicorn",
            rarity = 21, -- Rainbow rarity
            value = 22000,
            description = "A mystical unicorn that radiates rainbow magic.",
            isFlyingPet = true,
            baseBoost = 900,
            specialEffects = {"rainbow_horn_beam", "magic_sparkles", "healing_aura"}
        }
    },
    
    [11] = {
        id = 234567900,
        name = "CosmicPhoenix",
        displayName = "🌈 Cosmic Phoenix",
        description = "Legendary phoenix reborn in rainbow flames!",
        type = DeveloperProductConfig.TYPES.PET,
        price = 2199,
        icon = "rbxassetid://234567900",
        petData = {
            name = "Cosmic Phoenix",
            assetPath = "Pets/Phoenix",
            rarity = 21, -- Rainbow rarity
            value = 55000,
            description = "An eternal phoenix burning with cosmic rainbow fire.",
            isFlyingPet = true,
            baseBoost = 2200,
            specialEffects = {"rainbow_rebirth", "cosmic_flames", "stellar_flight"}
        }
    },
    
    [12] = {
        id = 234567901,
        name = "VoidKraken",
        displayName = "🌈 Void Kraken",
        description = "Ancient rainbow kraken from the void depths!",
        type = DeveloperProductConfig.TYPES.PET,
        price = 1699,
        icon = "rbxassetid://234567901",
        petData = {
            name = "Void Kraken",
            assetPath = "Pets/Kraken",
            rarity = 21, -- Rainbow rarity
            value = 43000,
            description = "A colossal sea beast with rainbow tentacles from the void.",
            isFlyingPet = false,
            baseBoost = 1700,
            specialEffects = {"void_tentacles", "rainbow_whirlpool", "abyssal_power"}
        }
    },
    
    -- === CURRENCY PACKS ===
    [20] = {
        id = 234567910,
        name = "SmallDiamondPack",
        displayName = "💎 Small Diamond Pack",
        description = "Get 100 diamonds instantly!",
        type = DeveloperProductConfig.TYPES.CURRENCY,
        price = 49,
        icon = "rbxassetid://234567910",
        rewards = {
            diamonds = 100
        }
    },
    
    [21] = {
        id = 234567911,
        name = "MediumDiamondPack",
        displayName = "💎 Medium Diamond Pack", 
        description = "Get 300 diamonds instantly! (Best Value)",
        type = DeveloperProductConfig.TYPES.CURRENCY,
        price = 129,
        icon = "rbxassetid://234567911",
        rewards = {
            diamonds = 300
        }
    },
    
    [22] = {
        id = 234567912,
        name = "LargeDiamondPack",
        displayName = "💎 Large Diamond Pack",
        description = "Get 750 diamonds instantly! (Premium Value)",
        type = DeveloperProductConfig.TYPES.CURRENCY,
        price = 299,
        icon = "rbxassetid://234567912",
        rewards = {
            diamonds = 750
        }
    },
    
    [23] = {
        id = 234567913,
        name = "MegaDiamondPack",
        displayName = "💎 Mega Diamond Pack",
        description = "Get 2000 diamonds instantly! (Ultimate Value)",
        type = DeveloperProductConfig.TYPES.CURRENCY,
        price = 699,
        icon = "rbxassetid://234567913",
        rewards = {
            diamonds = 2000
        }
    },
    
    -- === BOOSTS ===
    [30] = {
        id = 234567920,
        name = "MoneyBoost2x",
        displayName = "💰 2x Money Boost (1 Hour)",
        description = "Double your money earnings for 1 hour!",
        type = DeveloperProductConfig.TYPES.BOOST,
        price = 99,
        icon = "rbxassetid://234567920",
        boost = {
            type = "money",
            multiplier = 2.0,
            duration = 3600 -- 1 hour in seconds
        }
    },
    
    [31] = {
        id = 234567921,
        name = "DiamondBoost3x",
        displayName = "💎 3x Diamond Boost (30 Minutes)",
        description = "Triple your diamond earnings for 30 minutes!",
        type = DeveloperProductConfig.TYPES.BOOST,
        price = 149,
        icon = "rbxassetid://234567921",
        boost = {
            type = "diamond",
            multiplier = 3.0,
            duration = 1800 -- 30 minutes in seconds
        }
    },
    
    [32] = {
        id = 234567922,
        name = "LuckBoost5x",
        displayName = "🍀 5x Luck Boost (15 Minutes)",
        description = "Increase rare pet chances by 5x for 15 minutes!",
        type = DeveloperProductConfig.TYPES.BOOST,
        price = 199,
        icon = "rbxassetid://234567922",
        boost = {
            type = "luck",
            multiplier = 5.0,
            duration = 900 -- 15 minutes in seconds
        }
    },
    
    -- === SPECIAL ITEMS ===
    [40] = {
        id = 234567930,
        name = "InstantRebirth",
        displayName = "⚡ Instant Rebirth",
        description = "Instantly rebirth without meeting requirements!",
        type = DeveloperProductConfig.TYPES.SPECIAL,
        price = 199,
        icon = "rbxassetid://234567930",
        special = {
            action = "instant_rebirth"
        }
    },
    
    [41] = {
        id = 234567931,
        name = "MaxInventory",
        displayName = "📦 Max Inventory Space",
        description = "Instantly expand inventory to maximum capacity!",
        type = DeveloperProductConfig.TYPES.SPECIAL,
        price = 299,
        icon = "rbxassetid://234567931",
        special = {
            action = "max_inventory",
            value = 5000 -- Temporary expansion
        }
    }
}

-- Helper functions
function DeveloperProductConfig:GetProductData(productId)
    for _, product in pairs(self.PRODUCTS) do
        if product.id == productId then
            return product
        end
    end
    return nil
end

function DeveloperProductConfig:GetProductByName(name)
    for _, product in pairs(self.PRODUCTS) do
        if product.name == name then
            return product
        end
    end
    return nil
end

function DeveloperProductConfig:GetProductsByType(productType)
    local products = {}
    for _, product in pairs(self.PRODUCTS) do
        if product.type == productType then
            table.insert(products, product)
        end
    end
    return products
end

function DeveloperProductConfig:GetAllProducts()
    return self.PRODUCTS
end

return DeveloperProductConfig