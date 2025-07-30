-- GamepassConfig - Configuration for all gamepasses
local GamepassConfig = {}

-- Gamepass definitions
GamepassConfig.GAMEPASSES = {
    PetMagnet = {
        id = 1350346424, -- Real Roblox gamepass ID
        name = "Pet Magnet",
        description = "Automatically collect pet balls from a distance! Pet balls will float directly to you through walls.",
        price = 99, -- Robux price (for UI display)
        icon = "rbxasset://textures/ui/GuiImagePlaceholder.png", -- Placeholder icon
        benefits = {
            "Automatic pet collection",
            "Pet balls float through walls",
            "No need to manually touch pet balls",
            "Works from any distance in your area"
        }
    },
    AutoHeaven = {
        id = 1350860383, -- Real Roblox gamepass ID for Auto Heaven
        name = "Auto Heaven",
        description = "Automatically send pets to heaven every 30 seconds! Includes countdown timer and toggle on/off control.",
        price = 199, -- Robux price (for UI display)
        icon = "rbxasset://textures/ui/GuiImagePlaceholder.png", -- Placeholder icon
        benefits = {
            "Auto-send pets every 30 seconds",
            "Visual countdown timer",
            "Toggle on/off control",
            "Never miss processing opportunities"
        }
    },
    TwoXMoney = {
        id = 1351722330, -- Real Roblox gamepass ID for 2x Money
        name = "2x Money",
        description = "Double all money earned from processing pets! Get twice the rewards for every pet sent to heaven.",
        price = 149, -- Robux price (for UI display)
        icon = "rbxasset://textures/ui/GuiImagePlaceholder.png", -- Placeholder icon
        benefits = {
            "2x money from all pet processing",
            "Doubles money from heaven rewards",
            "Permanent money multiplier",
            "Stacks with other bonuses"
        }
    },
    TwoXDiamonds = {
        id = 1351480418, -- Real Roblox gamepass ID for 2x Diamonds
        name = "2x Diamonds",
        description = "Earn 2 diamonds per pet ball collected instead of 1! Double your diamond income from pet collection.",
        price = 199, -- Robux price (for UI display)
        icon = "rbxasset://textures/ui/GuiImagePlaceholder.png", -- Placeholder icon
        benefits = {
            "2 diamonds per pet ball collected",
            "Double diamond income",
            "Permanent diamond multiplier",
            "More premium currency rewards"
        }
    },
    TwoXHeavenSpeed = {
        id = 1351198429, -- Real Roblox gamepass ID for 2x Heaven Speed
        name = "2x Heaven Speed",
        description = "Process pets 2x faster in all tubes! Cut processing time in half for quicker rewards.",
        price = 179, -- Robux price (for UI display)
        icon = "rbxasset://textures/ui/GuiImagePlaceholder.png", -- Placeholder icon
        benefits = {
            "2x faster pet processing",
            "Half the processing time",
            "Quicker heaven rewards",
            "More efficient gameplay"
        }
    },
    VIP = {
        id = 1351374499, -- Real Roblox gamepass ID for VIP
        name = "VIP Package",
        description = "Get ALL gamepasses in one premium bundle! Includes Pet Magnet, Auto Heaven, 2x Money, 2x Diamonds, and 2x Heaven Speed.",
        price = 499, -- Robux price (for UI display)
        icon = "rbxasset://textures/ui/GuiImagePlaceholder.png", -- Placeholder icon
        benefits = {
            "All gamepasses included",
            "Pet Magnet + Auto Heaven",
            "2x Money + 2x Diamonds",
            "2x Heaven Speed",
            "Best value package"
        }
    }
}

-- Gamepass benefits configuration
GamepassConfig.BENEFITS = {
    PetMagnet = {
        magnetRange = 50, -- Range in studs for pet magnet
        magnetSpeed = 25, -- Speed at which pets float to player
        throughWalls = true -- Whether pets go through walls
    },
    AutoHeaven = {
        processInterval = 30, -- Seconds between auto-processing
        defaultEnabled = true -- Whether auto-heaven starts enabled by default
    },
    TwoXMoney = {
        moneyMultiplier = 2 -- Multiplier for money earned from processing
    },
    TwoXDiamonds = {
        diamondMultiplier = 2 -- Multiplier for diamonds earned from pet balls
    },
    TwoXHeavenSpeed = {
        speedMultiplier = 2 -- Multiplier for processing speed (2x faster = 0.5x time)
    },
    VIP = {
        -- VIP includes all benefits from other gamepasses
        magnetRange = 50,
        magnetSpeed = 25,
        throughWalls = true,
        processInterval = 30,
        defaultEnabled = true,
        moneyMultiplier = 2,
        diamondMultiplier = 2,
        speedMultiplier = 2
    }
}

-- Helper functions
function GamepassConfig.getGamepassById(gamepassId)
    for name, config in pairs(GamepassConfig.GAMEPASSES) do
        if config.id == gamepassId then
            return name, config
        end
    end
    return nil
end

function GamepassConfig.getGamepassByName(gamepassName)
    return GamepassConfig.GAMEPASSES[gamepassName]
end

function GamepassConfig.getAllGamepasses()
    return GamepassConfig.GAMEPASSES
end

function GamepassConfig.getBenefits(gamepassName)
    return GamepassConfig.BENEFITS[gamepassName]
end

return GamepassConfig