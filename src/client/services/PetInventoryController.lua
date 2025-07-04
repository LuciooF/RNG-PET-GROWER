-- Pet Inventory Controller
-- Business logic extracted from PetInventoryPanel.lua
-- Handles pet grouping, sorting, and inventory management

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetConfig = require(ReplicatedStorage.Shared.config.PetConfig)

local PetInventoryController = {}

-- Group pets by type, aura, size, and assignment status
function PetInventoryController.groupPets(playerData)
    local assignedPets = playerData.companionPets or {}
    local assignedPetIds = {}
    
    -- Create lookup table for assigned pets
    for _, assignedPet in ipairs(assignedPets) do
        if assignedPet.uniqueId then
            assignedPetIds[assignedPet.uniqueId] = true
        end
    end
    
    local petGroups = {}
    
    if playerData.ownedPets then
        for i, pet in ipairs(playerData.ownedPets) do
            local isAssigned = pet.uniqueId and assignedPetIds[pet.uniqueId] or false
            -- Group pets by type, aura, and size (regardless of assignment status)
            local petKey = (pet.name or "Unknown") .. "_" .. (pet.aura or "none") .. "_" .. (pet.size or 1)
            
            if not petGroups[petKey] then
                petGroups[petKey] = {
                    petType = pet,
                    quantity = 0,
                    assignedCount = 0,
                    latestCollectionTime = 0,
                    petConfig = PetConfig:GetPetData(pet.id or 1),
                    aura = pet.aura or "none",
                    auraData = PetConfig.AURAS[pet.aura or "none"] or PetConfig.AURAS.none,
                    size = pet.size or 1,
                    sizeData = PetConfig:GetSizeData(pet.size or 1),
                    hasAssigned = false,
                    samplePet = pet -- Store one pet for assign/unassign operations
                }
            end
            
            petGroups[petKey].quantity = petGroups[petKey].quantity + 1
            petGroups[petKey].latestCollectionTime = math.max(petGroups[petKey].latestCollectionTime, pet.collectedAt or 0)
            
            -- Track assigned pets
            if isAssigned then
                petGroups[petKey].assignedCount = petGroups[petKey].assignedCount + 1
                petGroups[petKey].hasAssigned = true
            end
            
            -- Always update sample pet to ensure we have a valid one
            petGroups[petKey].samplePet = pet
        end
    end
    
    return petGroups, assignedPets
end

-- Convert pet groups to sorted array
function PetInventoryController.createSortedPetItems(petGroups)
    local petItems = {}
    for petKey, groupData in pairs(petGroups) do
        table.insert(petItems, {
            name = groupData.petType.name,
            id = groupData.petType.id or 1,
            pet = groupData.petType,
            quantity = groupData.quantity,
            latestCollectionTime = groupData.latestCollectionTime,
            petConfig = groupData.petConfig,
            aura = groupData.aura,
            auraData = groupData.auraData,
            size = groupData.size,
            sizeData = groupData.sizeData,
            rarity = groupData.petType.rarity or 1,
            hasAssigned = groupData.hasAssigned,
            assignedCount = groupData.assignedCount,
            isAssigned = groupData.hasAssigned, -- Add flag for card button logic
            samplePet = groupData.samplePet
        })
    end
    
    -- Sort by: 1) assigned pets first (by rarity), 2) unassigned pets (by rarity)
    table.sort(petItems, function(a, b)
        -- Pets with assigned companions go first, but within each group sort by rarity
        if a.hasAssigned ~= b.hasAssigned then
            return a.hasAssigned
        end
        
        -- Within same assignment status, sort by rarity (rarest first)
        local aInfo = PetConfig:GetComprehensivePetInfo(a.pet.id, a.pet.aura, a.pet.size)
        local bInfo = PetConfig:GetComprehensivePetInfo(b.pet.id, b.pet.aura, b.pet.size)
        
        if aInfo and bInfo then
            -- Sort by combined probability (rarer first = lower probability first)
            if aInfo.combinedProbability ~= bInfo.combinedProbability then
                return aInfo.combinedProbability < bInfo.combinedProbability -- Lower probability = rarer = first
            end
            
            -- If rarity is same, sort by dynamic boost (higher boost first)
            if aInfo.dynamicBoost ~= bInfo.dynamicBoost then
                return aInfo.dynamicBoost > bInfo.dynamicBoost
            end
        end
        
        -- Fallback: sort by pet rarity then aura multiplier
        if a.pet.rarity ~= b.pet.rarity then
            return a.pet.rarity > b.pet.rarity
        end
        
        local aAuraMultiplier = a.auraData and a.auraData.multiplier or 1
        local bAuraMultiplier = b.auraData and b.auraData.multiplier or 1
        if aAuraMultiplier ~= bAuraMultiplier then
            return aAuraMultiplier > bAuraMultiplier
        end
        
        -- Finally by collection time (newest first)
        return a.latestCollectionTime > b.latestCollectionTime
    end)
    
    return petItems
end

-- Calculate grid dimensions for pet cards
function PetInventoryController.calculateGridDimensions(petItems, screenSize, panelWidth)
    local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
    
    -- Calculate grid for pet cards - responsive layout (3-5 cards per row)
    local minCardWidth = ScreenUtils.getProportionalSize(screenSize, 200)  -- Smaller minimum for more cards
    local cardsPerRow = math.max(3, math.min(5, math.floor((panelWidth - 120) / (minCardWidth + 20))))
    local cardWidth = (panelWidth - 120) / cardsPerRow - 20
    local cardHeight = ScreenUtils.getProportionalSize(screenSize, 260)  -- Slightly smaller height
    
    local totalRows = math.ceil(#petItems / cardsPerRow)
    local totalHeight = ((totalRows * cardHeight) + ((totalRows - 1) * 20) + 40) * 1.3
    
    return {
        cardsPerRow = cardsPerRow,
        cardWidth = cardWidth,
        cardHeight = cardHeight,
        totalRows = totalRows,
        totalHeight = totalHeight
    }
end

-- Format collection time for display
function PetInventoryController.formatCollectionTime(latestCollectionTime)
    if latestCollectionTime <= 0 then
        return ""
    end
    
    local timeAgo = tick() - latestCollectionTime
    if timeAgo < 60 then
        return math.floor(timeAgo) .. "s ago"
    elseif timeAgo < 3600 then
        return math.floor(timeAgo / 60) .. "m ago"
    else
        return math.floor(timeAgo / 3600) .. "h ago"
    end
end

-- Get comprehensive pet information for display
function PetInventoryController.getPetDisplayInfo(petItem)
    local pet = petItem.pet
    local petConfig = petItem.petConfig
    
    -- Get comprehensive pet information using new rarity system
    local comprehensiveInfo = PetConfig:GetComprehensivePetInfo(pet.id, pet.aura, pet.size)
    
    local displayInfo = {
        description = petConfig and petConfig.description or "A mysterious pet with hidden powers.",
        boostText = "",
        combinedRarityText = "1/1",
        rarityTierName = "Common",
        rarityTierColor = Color3.fromRGB(200, 200, 200),
        enhancedValue = pet.value or 1
    }
    
    if comprehensiveInfo then
        -- Dynamic boost based on combined rarity
        local boostPercentage = (comprehensiveInfo.moneyMultiplier - 1) * 100
        -- Format with 2 decimal places if less than 1%, otherwise 1 decimal place
        if boostPercentage < 1 then
            displayInfo.boostText = string.format("+%.2f%% Money", boostPercentage)
        else
            displayInfo.boostText = string.format("+%.1f%% Money", boostPercentage)
        end
        
        -- Combined rarity display (e.g., "1/1000")
        displayInfo.combinedRarityText = comprehensiveInfo.rarityText
        displayInfo.rarityTierName = comprehensiveInfo.rarityTier
        displayInfo.rarityTierColor = comprehensiveInfo.rarityColor
        displayInfo.enhancedValue = comprehensiveInfo.enhancedValue
    end
    
    return displayInfo
end

return PetInventoryController