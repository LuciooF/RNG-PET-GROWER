local PetConfig = {}

-- Pet definitions with their properties
PetConfig.PETS = {
    [1] = {
        name = "4th Of July Doggy",
        assetPath = "Pets/4th Of July Doggy",
        rarity = 1,
        spawnChance = 0.25, -- 25% - Most common in rarity 1
        value = 1,
        description = "A patriotic pup celebrating freedom and fun.",
        isFlyingPet = false,
        baseBoost = 10 -- Base boost will be calculated dynamically
    },
    [2] = {
        name = "Acid Rain Doggy",
        assetPath = "Pets/Acid Rain Doggy",
        rarity = 1,
        spawnChance = 0.22, -- 22%
        value = 1,
        description = "A mysterious canine with acidic powers.",
        isFlyingPet = false,
        baseBoost = 12
    },
    [3] = {
        name = "Alien Doggy",
        assetPath = "Pets/Alien Doggy",
        rarity = 1,
        spawnChance = 0.20, -- 20%
        value = 1,
        description = "An otherworldly companion from distant stars.",
        isFlyingPet = false,
        baseBoost = 15
    },
    [4] = {
        name = "Angel & Devil Doggy",
        assetPath = "Pets/Angel & Devil Doggy",
        rarity = 1,
        spawnChance = 0.18, -- 18%
        value = 1,
        description = "A dual-natured pup balancing good and mischief.",
        isFlyingPet = false,
        baseBoost = 18
    },
    [5] = {
        name = "Anime Doggy",
        assetPath = "Pets/Anime Doggy",
        rarity = 1,
        spawnChance = 0.15, -- 15% - Rarest in rarity 1
        value = 1,
        description = "A stylish doggy with anime charm.",
        isFlyingPet = false,
        baseBoost = 22
    },
    [6] = {
        name = "Arcade Doggy",
        assetPath = "Pets/Arcade Doggy",
        rarity = 2,
        spawnChance = 0.23, -- 23% - Most common in rarity 2
        value = 5,
        description = "A retro gaming enthusiast with pixel power.",
        isFlyingPet = false,
        baseBoost = 25
    },
    [7] = {
        name = "Baby Doggy",
        assetPath = "Pets/Baby Doggy",
        rarity = 2,
        spawnChance = 0.21, -- 21%
        value = 5,
        description = "An adorable puppy with endless energy.",
        isFlyingPet = false,
        baseBoost = 28
    },
    [8] = {
        name = "Beach Doggy",
        assetPath = "Pets/Beach Doggy",
        rarity = 2,
        spawnChance = 0.19, -- 19%
        value = 5,
        description = "A sun-loving surfer ready for summer fun.",
        isFlyingPet = false,
        baseBoost = 32
    },
    [9] = {
        name = "Blossom Doggy",
        assetPath = "Pets/Blossom Doggy",
        rarity = 2,
        spawnChance = 0.17, -- 17%
        value = 5,
        description = "A spring-inspired pup blooming with beauty.",
        isFlyingPet = false,
        baseBoost = 36
    },
    [10] = {
        name = "St' Patrics Doggy",
        assetPath = "Pets/St' Patrics Doggy",
        rarity = 2,
        spawnChance = 0.20, -- 20% - Middle rarity in tier 2
        value = 5,
        description = "A lucky Irish pup bringing fortune and cheer.",
        isFlyingPet = false,
        baseBoost = 30
    }
}

-- Size system
PetConfig.SIZES = {
    [1] = {
        name = "Tiny",
        displayName = "Tiny",
        multiplier = 1.0, -- No bonus for smallest size
        color = Color3.fromRGB(150, 150, 150) -- Gray
    },
    [2] = {
        name = "Small",
        displayName = "Small", 
        multiplier = 1.2, -- 20% bonus
        color = Color3.fromRGB(100, 255, 100) -- Light green
    },
    [3] = {
        name = "Medium",
        displayName = "Medium",
        multiplier = 1.5, -- 50% bonus  
        color = Color3.fromRGB(100, 150, 255) -- Light blue
    },
    [4] = {
        name = "Large",
        displayName = "Large",
        multiplier = 2.0, -- 100% bonus
        color = Color3.fromRGB(255, 150, 100) -- Light orange
    },
    [5] = {
        name = "Gigantic",
        displayName = "Gigantic",
        multiplier = 3.0, -- 200% bonus
        color = Color3.fromRGB(255, 100, 255) -- Light purple
    }
}

-- Comprehensive Aura system with varied rarities
PetConfig.AURAS = {
    none = {
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
        color = Color3.fromRGB(100, 200, 255), -- Light Blue
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
        color = Color3.fromRGB(15, 82, 186), -- Blue
        multiplier = 7.0,
        valueMultiplier = 7.0,
        chance = 0.005, -- 0.5% chance (increased)
        rarity = "Exotic"
    },
    rainbow = {
        name = "Rainbow",
        color = Color3.fromRGB(255, 100, 255), -- Rainbow (purple base)
        multiplier = 10.0,
        valueMultiplier = 10.0,
        chance = 0.003, -- 0.3% chance (increased)
        rarity = "Exotic"
    },
    cosmic = {
        name = "Cosmic",
        color = Color3.fromRGB(75, 0, 130), -- Indigo
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

-- Pet rarity configurations
PetConfig.RARITY_CONFIG = {
    [1] = {
        name = "Basic",
        color = Color3.fromRGB(255, 255, 255), -- White
        pets = {1, 2, 3, 4, 5} -- First 5 pets (rarity 1)
    },
    [2] = {
        name = "Rare",
        color = Color3.fromRGB(100, 255, 100), -- Green
        pets = {6, 7, 8, 9, 10} -- Last 5 pets (rarity 2)
    }
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
    
    -- Base boost from pet
    local baseBoost = petData.baseBoost or 10
    
    -- Rarity multiplier based on how rare the combination is
    -- The rarer the pet+aura combo, the higher the boost
    local rarityMultiplier = math.max(1, math.log10(1 / combinedProbability))
    
    -- Size multiplier
    local sizeMultiplier = sizeData and sizeData.multiplier or 1
    
    -- Final boost calculation
    local finalBoost = math.floor(baseBoost * rarityMultiplier * sizeMultiplier)
    
    return math.max(1, finalBoost)
end

-- Get rarity tier name based on combined probability
function PetConfig:GetRarityTierName(combinedProbability)
    if combinedProbability >= 0.1 then
        return "Common", Color3.fromRGB(200, 200, 200)
    elseif combinedProbability >= 0.05 then
        return "Uncommon", Color3.fromRGB(100, 255, 100)
    elseif combinedProbability >= 0.02 then
        return "Rare", Color3.fromRGB(100, 150, 255)
    elseif combinedProbability >= 0.01 then
        return "Epic", Color3.fromRGB(160, 100, 255)
    elseif combinedProbability >= 0.005 then
        return "Legendary", Color3.fromRGB(255, 200, 100)
    elseif combinedProbability >= 0.001 then
        return "Mythic", Color3.fromRGB(255, 100, 200)
    elseif combinedProbability >= 0.0001 then
        return "Exotic", Color3.fromRGB(100, 255, 255)
    elseif combinedProbability >= 0.00001 then
        return "Divine", Color3.fromRGB(255, 255, 100)
    else
        return "Godly", Color3.fromRGB(255, 255, 255)
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
        moneyMultiplier = 1 + (dynamicBoost / 100) -- Convert boost to multiplier
    }
end

return PetConfig