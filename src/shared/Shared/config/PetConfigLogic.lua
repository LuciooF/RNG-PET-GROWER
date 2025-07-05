-- Pet Configuration Business Logic
-- Extracted from PetConfig.lua following CLAUDE.md modular architecture patterns

local PetConfigLogic = {}

function PetConfigLogic:GetRandomAura()
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

function PetConfigLogic:GetPetData(petId)
    return self.PETS[petId]
end

function PetConfigLogic:GetPetsForRarity(rarity)
    local rarityConfig = self.RARITY_CONFIG[rarity]
    if not rarityConfig then
        return {}
    end
    
    local pets = {}
    for _, petId in ipairs(rarityConfig.pets) do
        local petData = self:GetPetData(petId)
        if petData then
            table.insert(pets, petData)
        end
    end
    
    return pets
end

function PetConfigLogic:GetRandomPetForRarity(rarity)
    local pets = self:GetPetsForRarity(rarity)
    if #pets == 0 then
        return nil
    end
    
    -- Calculate total spawn chance
    local totalChance = 0
    for _, pet in ipairs(pets) do
        totalChance = totalChance + pet.spawnChance
    end
    
    -- Select random pet based on spawn chances
    local rand = math.random() * totalChance
    local currentChance = 0
    
    for _, pet in ipairs(pets) do
        currentChance = currentChance + pet.spawnChance
        if rand <= currentChance then
            return pet
        end
    end
    
    -- Fallback to first pet
    return pets[1]
end

function PetConfigLogic:GetRarityConfig(rarity)
    return self.RARITY_CONFIG[rarity]
end

function PetConfigLogic:GetSizeData(sizeId)
    return self.SIZES[sizeId]
end

function PetConfigLogic:GetSmallestSize()
    return self.SIZES[1]
end

function PetConfigLogic:GetSizeCount()
    return 5
end

function PetConfigLogic:CalculatePetValue(petId, aura, size)
    local petData = self:GetPetData(petId)
    if not petData then
        return 1
    end
    
    local auraData = self.AURAS[aura or "none"]
    local sizeData = self:GetSizeData(size or 1)
    
    local baseValue = petData.value or 1
    local auraMultiplier = auraData and auraData.valueMultiplier or 1
    local sizeMultiplier = sizeData and sizeData.multiplier or 1
    
    return math.floor(baseValue * auraMultiplier * sizeMultiplier)
end

function PetConfigLogic:ValidatePetCollection(petId, aura, size)
    -- Validate pet ID
    local petData = self:GetPetData(petId)
    if not petData then
        return false, "Invalid pet ID"
    end
    
    -- Validate aura
    local auraData = self.AURAS[aura or "none"]
    if not auraData then
        return false, "Invalid aura"
    end
    
    -- Validate size
    local sizeData = self:GetSizeData(size or 1)
    if not sizeData then
        return false, "Invalid size"
    end
    
    return true, "Valid pet configuration"
end

function PetConfigLogic:CalculateCombinedRarity(petId, aura)
    local petData = self:GetPetData(petId)
    if not petData then
        return 1, "1/1"
    end
    
    local auraData = self.AURAS[aura or "none"]
    if not auraData then
        return 1, "1/1"
    end
    
    -- Calculate combined probability (pet spawn chance * aura chance)
    local petChance = petData.spawnChance or 0.01
    local auraChance = auraData.chance or 1
    local combinedChance = petChance * auraChance
    
    -- Convert to 1/X format
    local oneInX = math.floor(1 / combinedChance)
    local rarityText = string.format("1/%d", oneInX)
    
    return combinedChance, rarityText
end

function PetConfigLogic:CalculateDynamicBoost(petId, aura, size)
    local petData = self:GetPetData(petId)
    if not petData then
        return 10 -- Default boost
    end
    
    local auraData = self.AURAS[aura or "none"]
    local sizeData = self:GetSizeData(size or 1)
    
    -- Base boost from pet
    local baseBoost = petData.baseBoost or 10
    
    -- Aura multiplier
    local auraMultiplier = auraData and auraData.multiplier or 1
    
    -- Size multiplier
    local sizeMultiplier = sizeData and sizeData.multiplier or 1
    
    -- Calculate final boost percentage
    local finalBoost = baseBoost * auraMultiplier * sizeMultiplier
    
    return finalBoost
end

function PetConfigLogic:GetRarityTierName(combinedProbability)
    -- Define probability thresholds for tier names
    local tiers = {
        {threshold = 0.001, name = "Omniversal", color = Color3.fromRGB(255, 255, 255)},
        {threshold = 0.005, name = "Multiversal", color = Color3.fromRGB(100, 100, 255)},
        {threshold = 0.01, name = "Universal", color = Color3.fromRGB(255, 100, 255)},
        {threshold = 0.02, name = "Godlike", color = Color3.fromRGB(100, 255, 255)},
        {threshold = 0.03, name = "Omnipotent", color = Color3.fromRGB(255, 100, 100)},
        {threshold = 0.04, name = "Supreme", color = Color3.fromRGB(255, 215, 0)},
        {threshold = 0.05, name = "Infinite", color = Color3.fromRGB(255, 255, 255)},
        {threshold = 0.06, name = "Transcendent", color = Color3.fromRGB(255, 215, 255)},
        {threshold = 0.07, name = "Ethereal", color = Color3.fromRGB(200, 200, 255)},
        {threshold = 0.08, name = "Quantum", color = Color3.fromRGB(0, 255, 255)},
        {threshold = 0.09, name = "Void", color = Color3.fromRGB(25, 25, 25)},
        {threshold = 0.10, name = "Cosmic", color = Color3.fromRGB(75, 0, 130)},
        {threshold = 0.12, name = "Celestial", color = Color3.fromRGB(135, 206, 250)},
        {threshold = 0.14, name = "Divine", color = Color3.fromRGB(255, 255, 100)},
        {threshold = 0.16, name = "Mythic", color = Color3.fromRGB(255, 100, 200)},
        {threshold = 0.18, name = "Legendary", color = Color3.fromRGB(255, 200, 100)},
        {threshold = 0.20, name = "Epic", color = Color3.fromRGB(160, 100, 255)},
        {threshold = 0.30, name = "Rare", color = Color3.fromRGB(100, 150, 255)},
        {threshold = 0.50, name = "Common", color = Color3.fromRGB(100, 255, 100)},
        {threshold = 1.0, name = "Basic", color = Color3.fromRGB(150, 150, 150)},
    }
    
    for _, tier in ipairs(tiers) do
        if combinedProbability <= tier.threshold then
            return tier.name, tier.color
        end
    end
    
    return "Basic", Color3.fromRGB(150, 150, 150)
end

function PetConfigLogic:CalculateEnhancedPetValue(petId, aura, size)
    local petData = self:GetPetData(petId)
    if not petData then
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

function PetConfigLogic:GetComprehensivePetInfo(petId, aura, size)
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

return PetConfigLogic