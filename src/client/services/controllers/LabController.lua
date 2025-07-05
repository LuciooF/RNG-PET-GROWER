-- Lab Controller - Business Logic for Pet Merging
-- Extracted from LabPanel.lua following CLAUDE.md modular architecture patterns
-- Handles pet filtering, selection logic, and merge calculations

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetConfig = require(ReplicatedStorage.Shared.config.PetConfig)
local PetMergeController = require(ReplicatedStorage.Shared.controllers.PetMergeController)

local LabController = {}

-- Filter available pets for merging (unassigned pets only)
function LabController.getAvailablePets(playerData)
    local ownedPets = playerData.ownedPets or {}
    local assignedPets = playerData.companionPets or {}
    local assignedIds = {}
    
    -- Create lookup for assigned pets
    for _, assignedPet in ipairs(assignedPets) do
        assignedIds[assignedPet.uniqueId] = true
    end
    
    -- Filter to unassigned pets
    local unassignedPets = {}
    for _, pet in ipairs(ownedPets) do
        if not assignedIds[pet.uniqueId] then
            -- Transform pet data for UI compatibility
            local petConfig = PetConfig:GetPetData(pet.id or 1)
            local auraData = PetConfig.AURAS[pet.aura or "none"] or PetConfig.AURAS.none
            local sizeData = PetConfig:GetSizeData(pet.size or 1)
            
            table.insert(unassignedPets, {
                pet = pet,
                name = pet.name,
                id = pet.id or 1,
                quantity = 1,
                petConfig = petConfig,
                aura = pet.aura or "none",
                auraData = auraData,
                size = pet.size or 1,
                sizeData = sizeData,
                rarity = pet.rarity or 1,
                isAssigned = false,
                uniqueId = pet.uniqueId
            })
        end
    end
    
    -- Sort pets by combined rarity (most rare first)
    table.sort(unassignedPets, function(a, b)
        local aComprehensive = PetConfig:GetComprehensivePetInfo(a.pet.id, a.pet.aura, a.pet.size)
        local bComprehensive = PetConfig:GetComprehensivePetInfo(b.pet.id, b.pet.aura, b.pet.size)
        
        -- Get combined rarity with fallbacks
        local aRarity = (aComprehensive and aComprehensive.combinedRarity) or a.pet.rarity or 1
        local bRarity = (bComprehensive and bComprehensive.combinedRarity) or b.pet.rarity or 1
        
        -- Sort by combined rarity (higher number = more rare = should come first)
        return aRarity > bRarity
    end)
    
    return unassignedPets
end

-- Calculate merge information for selected pets
function LabController.calculateMergeInfo(selectedPets, playerData)
    local pet1, pet2, pet3 = selectedPets[1], selectedPets[2], selectedPets[3]
    
    if not pet1 or not pet2 or not pet3 then
        return {
            canMerge = false,
            error = "Select 3 pets to merge",
            showPreview = false
        }
    end
    
    local canMerge, error = PetMergeController.validateMergePets(pet1.pet, pet2.pet, pet3.pet)
    
    if not canMerge then
        return {
            canMerge = false,
            error = error,
            showPreview = false
        }
    end
    
    local diamondCost = PetMergeController.calculateDiamondCost(pet1.pet, pet2.pet, pet3.pet)
    local outcomes = PetMergeController.calculateMergeOutcomes(pet1.pet, pet2.pet, pet3.pet)
    local formattedOutcomes = PetMergeController.formatOutcomeInfo(outcomes)
    
    local playerDiamonds = (playerData.resources and playerData.resources.diamonds) or 0
    
    return {
        canMerge = true,
        diamondCost = diamondCost,
        outcomes = formattedOutcomes,
        hasEnoughDiamonds = playerDiamonds >= diamondCost,
        showPreview = true,
        playerDiamonds = playerDiamonds
    }
end

-- Handle pet selection logic
function LabController.selectPet(currentSelection, petItem)
    local newSelection = {currentSelection[1], currentSelection[2], currentSelection[3]}
    
    -- Find first empty slot
    for i = 1, 3 do
        if not newSelection[i] then
            newSelection[i] = petItem
            return newSelection
        end
    end
    
    -- All slots filled, replace first one
    newSelection[1] = petItem
    return newSelection
end

-- Handle pet removal from selection
function LabController.removePet(currentSelection, slotIndex)
    local newSelection = {currentSelection[1], currentSelection[2], currentSelection[3]}
    newSelection[slotIndex] = nil
    return newSelection
end

-- Validate merge attempt
function LabController.canExecuteMerge(mergeInfo)
    return mergeInfo.canMerge and mergeInfo.hasEnoughDiamonds
end

-- Reset lab state
function LabController.resetLabState()
    return {
        selectedPets = {nil, nil, nil},
        showMergeConfirm = false,
        merging = false,
        mergeResult = nil
    }
end

-- Handle merge execution request
function LabController.requestMerge(selectedPets, mergeInfo)
    if not LabController.canExecuteMerge(mergeInfo) then
        return false, "Cannot execute merge - validation failed"
    end
    
    local pet1, pet2, pet3 = selectedPets[1], selectedPets[2], selectedPets[3]
    
    -- Prepare merge request data
    local mergeData = {
        pets = {
            pet1.pet.uniqueId,
            pet2.pet.uniqueId, 
            pet3.pet.uniqueId
        },
        diamondCost = mergeInfo.diamondCost
    }
    
    return true, mergeData
end

return LabController