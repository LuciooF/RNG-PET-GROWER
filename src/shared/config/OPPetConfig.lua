-- OP Pet Configuration - Premium pets purchasable with Robux
local PetConstants = require(script.Parent.Parent.constants.PetConstants)

local OPPetConfig = {}

-- OP Pet definitions - These are premium pets with ridiculous boosts!
-- All OP pets have OP rarity and OP variation (rainbow color scheme)
OPPetConfig.OPPets = {
    {
        Name = "Constellation King",
        ModelName = "Constellation", -- Cool space-themed pet
        DevProductId = 3356802236,   -- Your provided dev product
        BaseValue = 1000000,         -- 1 million base value!
        BaseBoost = 100000,          -- 100,000x base boost!
        RobuxPrice = 100,            -- Display price (actual price set in dev product)
        Description = "⭐ Galactic overlord with cosmic powers! Provides massive boost and follows you forever!"
    },
    {
        Name = "Ban Hammer Lord",
        ModelName = "Ban Hammer",    -- Iconic Roblox reference
        DevProductId = nil,          -- Will need another dev product
        BaseValue = 2000000,         -- 2 million base value!
        BaseBoost = 750,             -- 750x base boost!
        RobuxPrice = 150,
        Description = "🔨 The ultimate moderator pet! Bans lag and multiplies your earnings!"
    },
    {
        Name = "Developer Pet Supreme",
        ModelName = "Developer Pet", -- Developer themed
        DevProductId = nil,          -- Will need another dev product
        BaseValue = 5000000,         -- 5 million base value!
        BaseBoost = 1000,            -- 1000x base boost!
        RobuxPrice = 200,
        Description = "💻 The legendary dev pet! Created by the game developers themselves!"
    },
    {
        Name = "Dominus Empyreus Ultimate",
        ModelName = "White Dominus", -- Premium Dominus
        DevProductId = nil,          -- Will need another dev product
        BaseValue = 10000000,        -- 10 million base value!
        BaseBoost = 1500,            -- 1500x base boost!
        RobuxPrice = 300,
        Description = "👑 The crown jewel of pets! Ultimate prestige and power!"
    },
    {
        Name = "The Chosen One Omega",
        ModelName = "The Chosen One", -- Already legendary
        DevProductId = nil,          -- Will need another dev product
        BaseValue = 25000000,        -- 25 million base value!
        BaseBoost = 2500,            -- 2500x base boost!
        RobuxPrice = 500,
        Description = "🌟 The most powerful pet in existence! Chosen by destiny itself!"
    }
}

-- Create an OP pet with full data structure
function OPPetConfig.createOPPet(opPetData, playerId)
    local pet = {
        ID = game:GetService("HttpService"):GenerateGUID(false),
        Name = opPetData.Name,
        ModelName = opPetData.ModelName,
        Rarity = {
            RarityName = PetConstants.Rarity.OP,
            RarityChance = 0, -- Not obtainable through normal means
            RarityColor = {255, 0, 255} -- Magenta/Rainbow
        },
        Variation = {
            VariationName = PetConstants.Variation.OP,
            VariationChance = 0, -- Not obtainable through normal means
            VariationColor = {255, 0, 255} -- Magenta/Rainbow
        },
        BaseValue = opPetData.BaseValue,
        BaseBoost = opPetData.BaseBoost,
        -- OP pets get the full OP multiplier (100x)
        FinalValue = opPetData.BaseValue * PetConstants.VariationMultipliers[PetConstants.Variation.OP],
        FinalBoost = opPetData.BaseBoost * PetConstants.VariationMultipliers[PetConstants.Variation.OP],
        DevProductId = opPetData.DevProductId,
        -- RobuxPrice removed - now fetched dynamically from marketplace
        Description = opPetData.Description,
        PurchasedBy = playerId,
        PurchaseTime = os.time(),
        IsOPPet = true -- Flag to identify OP pets
    }
    
    return pet
end

-- Get OP pet by dev product ID
function OPPetConfig.getOPPetByDevProduct(devProductId)
    for _, opPet in ipairs(OPPetConfig.OPPets) do
        if opPet.DevProductId == devProductId then
            return opPet
        end
    end
    return nil
end

-- Get OP pet by name
function OPPetConfig.getOPPetByName(name)
    for _, opPet in ipairs(OPPetConfig.OPPets) do
        if opPet.Name == name then
            return opPet
        end
    end
    return nil
end

-- Check if a pet is an OP pet
function OPPetConfig.isOPPet(pet)
    if type(pet) ~= "table" then return false end
    
    -- Check by flag
    if pet.IsOPPet then return true end
    
    -- Check by rarity
    local rarityName = pet.Rarity
    if type(pet.Rarity) == "table" then
        rarityName = pet.Rarity.RarityName
    end
    
    return rarityName == PetConstants.Rarity.OP
end

return OPPetConfig