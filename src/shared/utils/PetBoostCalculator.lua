-- Pet Boost Calculator Utility
-- Centralized boost calculation logic extracted from UI components
-- Handles money boosts, aura multipliers, and size multipliers

local PetBoostCalculator = {}

-- Calculate individual pet boost data
function PetBoostCalculator.calculatePetBoost(pet, petConfig, auraData, sizeData)
    local boostData = {
        pet = pet,
        petConfig = petConfig,
        aura = pet.aura or "none",
        auraData = auraData,
        size = pet.size or 1,
        sizeData = sizeData,
        category = "🐾 Pet Boost",
        effect = "+0%",
        effects = {},
        color = auraData.color,
        duration = "While assigned"
    }
    
    -- Use new dynamic boost calculation system
    local PetConfig = require(script.Parent.Parent.Shared.config.PetConfig)
    local comprehensiveInfo = PetConfig:GetComprehensivePetInfo(pet.id, pet.aura, pet.size)
    
    if comprehensiveInfo then
        local boostPercentage = (comprehensiveInfo.moneyMultiplier - 1) * 100
        boostData.effect = "+" .. math.floor(boostPercentage) .. "%"
        boostData.effects = {
            "+" .. math.floor(boostPercentage) .. "% money from all sources",
            "Rarity: " .. comprehensiveInfo.rarityText,
            "Aura: " .. auraData.name,
            "Size: " .. sizeData.displayName
        }
        boostData.totalBoostMultiplier = comprehensiveInfo.moneyMultiplier
    else
        boostData.totalBoostMultiplier = 1
    end
    
    return boostData
end

-- Calculate total money multiplier from all assigned pets
function PetBoostCalculator.calculateTotalMoneyMultiplier(assignedPets, PetConfig)
    local totalMoneyMultiplier = 1
    
    for _, pet in ipairs(assignedPets) do
        local petConfig = PetConfig:GetPetData(pet.id)
        if petConfig then
            local auraData = PetConfig.AURAS[pet.aura or "none"] or PetConfig.AURAS.none
            local sizeData = PetConfig:GetSizeData(pet.size or 1)
            
            local boostData = PetBoostCalculator.calculatePetBoost(pet, petConfig, auraData, sizeData)
            totalMoneyMultiplier = totalMoneyMultiplier + (boostData.totalBoostMultiplier - 1)
        end
    end
    
    return totalMoneyMultiplier
end

-- Calculate total money multiplier including friends boost
function PetBoostCalculator.calculateTotalMoneyMultiplierWithFriends(assignedPets, PetConfig, friendsBoost)
    local petMultiplier = PetBoostCalculator.calculateTotalMoneyMultiplier(assignedPets, PetConfig)
    local friendsMultiplier = 1 + (friendsBoost / 100) -- Convert percentage to multiplier
    
    -- Friends boost is additive with pet boosts
    return petMultiplier + (friendsMultiplier - 1)
end

-- Create friends boost data for UI display
function PetBoostCalculator.createFriendsBoostData(friendsBoost)
    if friendsBoost <= 0 then
        return nil
    end
    
    return {
        category = "👥 Friends Boost",
        effect = "+" .. friendsBoost .. "%",
        description = "Each friend in the server gives you 100% boost",
        color = Color3.fromRGB(34, 139, 34), -- Green
        duration = "While friends are online",
        effects = {
            "+" .. friendsBoost .. "% money from all sources",
            "Boost increases with more friends online"
        },
        totalBoostMultiplier = 1 + (friendsBoost / 100)
    }
end

-- Generate boost data for all assigned pets
function PetBoostCalculator.generatePetBoostData(assignedPets, PetConfig)
    local petBoosts = {}
    
    for _, pet in ipairs(assignedPets) do
        local petConfig = PetConfig:GetPetData(pet.id)
        if petConfig then
            local auraData = PetConfig.AURAS[pet.aura or "none"] or PetConfig.AURAS.none
            local sizeData = PetConfig:GetSizeData(pet.size or 1)
            
            local boostData = PetBoostCalculator.calculatePetBoost(pet, petConfig, auraData, sizeData)
            table.insert(petBoosts, boostData)
        end
    end
    
    return petBoosts
end

-- Format boost percentage for display
function PetBoostCalculator.formatBoostPercentage(multiplier)
    local percentValue = (multiplier - 1) * 100
    return "+" .. math.floor(percentValue) .. "%"
end

-- Get boost color based on magnitude
function PetBoostCalculator.getBoostMagnitudeColor(multiplier)
    local percentValue = (multiplier - 1) * 100
    
    if percentValue >= 100 then
        return Color3.fromRGB(255, 100, 255) -- Purple for very high boosts
    elseif percentValue >= 50 then
        return Color3.fromRGB(255, 150, 100) -- Orange for high boosts
    elseif percentValue >= 25 then
        return Color3.fromRGB(255, 215, 0) -- Gold for medium boosts
    elseif percentValue >= 10 then
        return Color3.fromRGB(100, 255, 100) -- Green for low boosts
    else
        return Color3.fromRGB(200, 200, 200) -- Gray for minimal boosts
    end
end

return PetBoostCalculator