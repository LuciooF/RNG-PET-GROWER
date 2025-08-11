-- BoostCalculator - Centralized boost calculations for consistency across server and client
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PotionConfig = require(ReplicatedStorage.config.PotionConfig)

local BoostCalculator = {}

-- Normalize pet boost value (handles both decimal and multiplier formats)
function BoostCalculator.normalizePetBoost(petBoost)
    if not petBoost or petBoost == 0 then
        return 0 -- No boost
    end
    
    -- Fix for pets with boost values stored as decimals (0.77) instead of multipliers (1.77)
    if petBoost < 1 then
        -- Convert decimal to percentage (0.77 becomes 0.77 = 77% boost)
        return petBoost
    else
        -- Standard conversion (1.77 becomes 0.77 = 77% boost)
        return petBoost - 1
    end
end

-- Calculate total boost from equipped pets only
function BoostCalculator.calculateEquippedPetBoost(equippedPets)
    local totalBoostPercentage = 0
    
    if not equippedPets then
        return totalBoostPercentage
    end
    
    for _, equippedPet in pairs(equippedPets) do
        -- Use BaseBoost to avoid double-multiplying (FinalBoost may already include variations)
        local petBoost = equippedPet.BaseBoost or equippedPet.FinalBoost or 1
        local boostPercentage = BoostCalculator.normalizePetBoost(petBoost)
        totalBoostPercentage = totalBoostPercentage + boostPercentage
    end
    
    return totalBoostPercentage
end

-- Calculate total boost from OP pets (always active)
function BoostCalculator.calculateOPPetBoost(opPets)
    local totalBoostPercentage = 0
    
    if not opPets then
        return totalBoostPercentage
    end
    
    for _, opPet in pairs(opPets) do
        -- Use FinalBoost for OP pets as they may have enhanced multipliers
        local petBoost = opPet.FinalBoost or opPet.BaseBoost or 1
        local boostPercentage = BoostCalculator.normalizePetBoost(petBoost)
        totalBoostPercentage = totalBoostPercentage + boostPercentage
    end
    
    return totalBoostPercentage
end

-- Calculate gamepass multiplier
function BoostCalculator.calculateGamepassMultiplier(ownedGamepasses)
    local gamepassMultiplier = 1
    
    if not ownedGamepasses then
        return gamepassMultiplier
    end
    
    -- Convert array to lookup table for efficient checking
    local gamepasses = {}
    for _, gamepassName in pairs(ownedGamepasses) do
        gamepasses[gamepassName] = true
    end
    
    -- Stack gamepass multipliers
    if gamepasses.TwoXMoney then
        gamepassMultiplier = gamepassMultiplier * 2
    end
    
    if gamepasses.VIP then
        gamepassMultiplier = gamepassMultiplier * 2
    end
    
    return gamepassMultiplier
end

-- Calculate rebirth multiplier
function BoostCalculator.calculateRebirthMultiplier(playerRebirths)
    playerRebirths = playerRebirths or 0
    return 1 + (playerRebirths * 0.5) -- 50% boost per rebirth
end

-- Calculate potion boost multiplier for a specific boost type
function BoostCalculator.calculatePotionMultiplier(activePotions, boostType)
    if not activePotions or not boostType then
        print("BoostCalculator DEBUG: No activePotions or boostType provided")
        return 1
    end
    
    local currentTime = os.time()
    
    for _, activePotion in pairs(activePotions) do
        -- Check if potion is still active
        local remainingTime = activePotion.ExpiresAt - currentTime
        
        if remainingTime > 0 then
            local potionConfig = PotionConfig.GetPotion(activePotion.PotionId)
            if potionConfig and potionConfig.BoostType == boostType then
                return potionConfig.BoostAmount
            end
        end
    end
    return 1 -- No active potion for this boost type
end

-- Get all active potion boosts breakdown
function BoostCalculator.getActivePotionBoosts(activePotions)
    if not activePotions then
        return {
            Money = 1,
            Diamonds = 1,
            PetMagnet = 1
        }
    end
    
    return {
        Money = BoostCalculator.calculatePotionMultiplier(activePotions, "Money"),
        Diamonds = BoostCalculator.calculatePotionMultiplier(activePotions, "Diamonds"),
        PetMagnet = BoostCalculator.calculatePotionMultiplier(activePotions, "PetMagnet")
    }
end

-- Calculate total boost multiplier (all sources combined) - Money boost specifically
function BoostCalculator.calculateTotalBoostMultiplier(playerData)
    if not playerData then
        return 1 -- No boost if no data
    end
    
    -- Calculate individual boost components
    local petBoostPercentage = BoostCalculator.calculateEquippedPetBoost(playerData.EquippedPets)
    local opPetBoostPercentage = BoostCalculator.calculateOPPetBoost(playerData.OPPets)
    local gamepassMultiplier = BoostCalculator.calculateGamepassMultiplier(playerData.OwnedGamepasses)
    local rebirthMultiplier = BoostCalculator.calculateRebirthMultiplier(playerData.Resources and playerData.Resources.Rebirths)
    local potionMultiplier = BoostCalculator.calculatePotionMultiplier(playerData.ActivePotions, "Money")
    
    -- Combine all boosts: pets/OP pets/gamepasses/rebirths are additive, potions are multiplicative
    local baseMultiplier = 1 + petBoostPercentage + opPetBoostPercentage + (gamepassMultiplier - 1) + (rebirthMultiplier - 1)
    local totalMultiplier = baseMultiplier * potionMultiplier
    
    return totalMultiplier
end

-- Calculate boost for specific pet list (utility function)
function BoostCalculator.calculatePetListBoost(pets, useBaseBoost)
    if not pets then
        return 1
    end
    
    local totalBoost = 1
    
    for _, pet in pairs(pets) do
        local boost = useBaseBoost and pet.BaseBoost or pet.FinalBoost
        if boost and boost > 0 then
            totalBoost = totalBoost * boost -- Multiplicative for utility calculations
        end
    end
    
    return totalBoost
end

-- Get boost breakdown for UI display
function BoostCalculator.getBoostBreakdown(playerData)
    if not playerData then
        return {
            petBoost = 1,
            opPetBoost = 1,
            gamepassBoost = 1,
            rebirthBoost = 1,
            potionBoosts = { Money = 1, Diamonds = 1, PetMagnet = 1 },
            totalBoost = 1,
            petCount = 0,
            opPetCount = 0
        }
    end
    
    
    local petBoostPercentage = BoostCalculator.calculateEquippedPetBoost(playerData.EquippedPets)
    local opPetBoostPercentage = BoostCalculator.calculateOPPetBoost(playerData.OPPets)
    local gamepassMultiplier = BoostCalculator.calculateGamepassMultiplier(playerData.OwnedGamepasses)
    local rebirthMultiplier = BoostCalculator.calculateRebirthMultiplier(playerData.Resources and playerData.Resources.Rebirths)
    local potionBoosts = BoostCalculator.getActivePotionBoosts(playerData.ActivePotions)
    
    return {
        petBoost = 1 + petBoostPercentage,
        opPetBoost = 1 + opPetBoostPercentage,
        gamepassBoost = gamepassMultiplier,
        rebirthBoost = rebirthMultiplier,
        potionBoosts = potionBoosts,
        totalBoost = BoostCalculator.calculateTotalBoostMultiplier(playerData),
        petCount = playerData.EquippedPets and #playerData.EquippedPets or 0,
        opPetCount = playerData.OPPets and #playerData.OPPets or 0
    }
end

return BoostCalculator