-- Pet Merge Controller
-- Handles the business logic for pet merging in the Lab
-- Calculates merge probabilities, diamond costs, and possible outcomes

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetConfig = require(ReplicatedStorage.Shared.config.PetConfig)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)

local PetMergeController = {}

-- Merge configuration
local MERGE_CONFIG = {
    -- Base diamond cost per merge attempt
    BASE_DIAMOND_COST = 50,
    
    -- Rarity multipliers for diamond cost
    RARITY_COST_MULTIPLIERS = {
        [1] = 1.0,    -- Basic
        [2] = 1.2,    -- Common
        [3] = 1.5,    -- Rare
        [4] = 2.0,    -- Epic
        [5] = 2.5,    -- Legendary
        [6] = 3.0,    -- Mythic+
    },
    
    -- Outcome probabilities
    OUTCOME_CHANCES = {
        SUCCESS_UPGRADE = 0.40,  -- 40% chance to get better pet
        SAME_TIER = 0.35,        -- 35% chance to get same tier
        DOWNGRADE = 0.25,        -- 25% chance to get worse
    },
    
    -- Size upgrade chances (when merging same size pets)
    SIZE_UPGRADE_CHANCE = 0.30,  -- 30% chance to upgrade size
    
    -- Merged auras
    MERGED_AURAS = {"merged", "zombie"},
}

-- Validate that 3 pets can be merged together
function PetMergeController.validateMergePets(pet1, pet2, pet3)
    if not pet1 or not pet2 or not pet3 then
        return false, "All 3 pet slots must be filled"
    end
    
    -- Check that all pets have the same size
    local size1 = pet1.size or 1
    local size2 = pet2.size or 1  
    local size3 = pet3.size or 1
    
    if size1 ~= size2 or size2 ~= size3 then
        return false, "All pets must be the same size to merge"
    end
    
    -- Check that pets are not assigned
    if pet1.isAssigned or pet2.isAssigned or pet3.isAssigned then
        return false, "Cannot merge assigned pets. Unassign them first."
    end
    
    return true, "Pets can be merged"
end

-- Calculate the combined rarity value of 3 pets for merging
function PetMergeController.calculateCombinedRarity(pet1, pet2, pet3)
    local function getPetRarityValue(pet)
        local combinedProbability, _ = PetConfig:CalculateCombinedRarity(pet.id or 1, pet.aura)
        -- Convert probability to rarity value (lower probability = higher rarity value)
        return 1 / (combinedProbability or 0.001)
    end
    
    local rarity1 = getPetRarityValue(pet1)
    local rarity2 = getPetRarityValue(pet2)
    local rarity3 = getPetRarityValue(pet3)
    
    -- Sum the rarity values
    local totalRarity = rarity1 + rarity2 + rarity3
    
    return totalRarity, {rarity1, rarity2, rarity3}
end

-- Calculate diamond cost for merging
function PetMergeController.calculateDiamondCost(pet1, pet2, pet3)
    local totalRarity, individualRarities = PetMergeController.calculateCombinedRarity(pet1, pet2, pet3)
    
    -- Base cost
    local cost = MERGE_CONFIG.BASE_DIAMOND_COST
    
    -- Scale cost based on combined rarity (higher rarity = more expensive)
    -- Use logarithmic scaling to prevent extreme costs
    local rarityMultiplier = math.log(totalRarity / 100) + 1
    rarityMultiplier = math.max(1, rarityMultiplier)
    rarityMultiplier = math.min(10, rarityMultiplier) -- Cap at 10x
    
    cost = math.floor(cost * rarityMultiplier)
    
    -- Size multiplier (larger pets cost more to merge)
    local size = pet1.size or 1
    local sizeMultiplier = 1 + (size - 1) * 0.5  -- +50% cost per size tier
    cost = math.floor(cost * sizeMultiplier)
    
    return math.max(10, cost) -- Minimum 10 diamonds
end

-- Calculate possible merge outcomes
function PetMergeController.calculateMergeOutcomes(pet1, pet2, pet3)
    local totalRarity, _ = PetMergeController.calculateCombinedRarity(pet1, pet2, pet3)
    local size = pet1.size or 1
    
    local outcomes = {}
    
    -- Success outcome - better pet
    local successRarity = totalRarity * 1.5 -- 50% better than sum
    local successProbability = 1 / successRarity
    
    table.insert(outcomes, {
        type = "success",
        chance = MERGE_CONFIG.OUTCOME_CHANCES.SUCCESS_UPGRADE,
        description = "Superior Pet",
        expectedRarity = string.format("1/%d", math.floor(successRarity)),
        size = math.random() < MERGE_CONFIG.SIZE_UPGRADE_CHANCE and math.min(size + 1, 5) or size,
        aura = MERGE_CONFIG.MERGED_AURAS[math.random(#MERGE_CONFIG.MERGED_AURAS)],
        rarityValue = successRarity,
        color = Color3.fromRGB(100, 255, 100) -- Green
    })
    
    -- Same tier outcome
    local sameTierRarity = totalRarity * 1.0 -- Same as sum
    table.insert(outcomes, {
        type = "same",
        chance = MERGE_CONFIG.OUTCOME_CHANCES.SAME_TIER,
        description = "Equivalent Pet",
        expectedRarity = string.format("1/%d", math.floor(sameTierRarity)),
        size = size,
        aura = MERGE_CONFIG.MERGED_AURAS[math.random(#MERGE_CONFIG.MERGED_AURAS)],
        rarityValue = sameTierRarity,
        color = Color3.fromRGB(255, 255, 100) -- Yellow
    })
    
    -- Downgrade outcome
    local downgradeRarity = totalRarity * 0.6 -- 40% worse than sum
    table.insert(outcomes, {
        type = "downgrade", 
        chance = MERGE_CONFIG.OUTCOME_CHANCES.DOWNGRADE,
        description = "Lesser Pet",
        expectedRarity = string.format("1/%d", math.floor(downgradeRarity)),
        size = size,
        aura = MERGE_CONFIG.MERGED_AURAS[math.random(#MERGE_CONFIG.MERGED_AURAS)],
        rarityValue = downgradeRarity,
        color = Color3.fromRGB(255, 100, 100) -- Red
    })
    
    return outcomes
end

-- Generate the actual merged pet based on outcome
function PetMergeController.generateMergedPet(pet1, pet2, pet3, outcomeType)
    local outcomes = PetMergeController.calculateMergeOutcomes(pet1, pet2, pet3)
    local selectedOutcome = nil
    
    -- Find the outcome that matches the type
    for _, outcome in ipairs(outcomes) do
        if outcome.type == outcomeType then
            selectedOutcome = outcome
            break
        end
    end
    
    if not selectedOutcome then
        return nil, "Invalid outcome type"
    end
    
    -- Select a random pet from the same size category as input pets
    local basePetId = math.random(1, 100) -- Random pet from available pets
    local basePetData = PetConfig:GetPetData(basePetId)
    
    if not basePetData then
        basePetId = 1 -- Fallback to first pet
        basePetData = PetConfig:GetPetData(basePetId)
    end
    
    -- Create merged pet data
    local mergedPet = {
        id = basePetId,
        name = basePetData.name,
        aura = selectedOutcome.aura,
        size = selectedOutcome.size,
        value = PetConfig:CalculatePetValue(basePetId, selectedOutcome.aura, selectedOutcome.size),
        mergedFromRarity = selectedOutcome.rarityValue,
        mergedTimestamp = tick(),
        uniqueId = tostring(math.random(100000, 999999)) .. "_" .. tostring(tick()),
        isAssigned = false
    }
    
    return mergedPet, nil
end

-- Randomly determine merge outcome based on probabilities
function PetMergeController.rollMergeOutcome()
    local roll = math.random()
    local cumulative = 0
    
    cumulative = cumulative + MERGE_CONFIG.OUTCOME_CHANCES.SUCCESS_UPGRADE
    if roll <= cumulative then
        return "success"
    end
    
    cumulative = cumulative + MERGE_CONFIG.OUTCOME_CHANCES.SAME_TIER  
    if roll <= cumulative then
        return "same"
    end
    
    return "downgrade"
end

-- Format outcome information for UI display
function PetMergeController.formatOutcomeInfo(outcomes)
    local formattedOutcomes = {}
    
    for _, outcome in ipairs(outcomes) do
        table.insert(formattedOutcomes, {
            title = outcome.description,
            chance = string.format("%.1f%%", outcome.chance * 100),
            rarity = outcome.expectedRarity,
            size = PetConfig:GetSizeData(outcome.size).displayName,
            aura = outcome.aura,
            color = outcome.color
        })
    end
    
    return formattedOutcomes
end

-- Get summary text for merge preview
function PetMergeController.getMergeSummaryText(pet1, pet2, pet3)
    local totalRarity, _ = PetMergeController.calculateCombinedRarity(pet1, pet2, pet3)
    local cost = PetMergeController.calculateDiamondCost(pet1, pet2, pet3)
    local size = PetConfig:GetSizeData(pet1.size or 1).displayName
    
    return string.format(
        "Merging 3 %s pets with combined rarity 1/%d for %s diamonds",
        size,
        math.floor(totalRarity),
        NumberFormatter.format(cost)
    )
end

return PetMergeController