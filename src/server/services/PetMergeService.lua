-- Pet Merge Service (Server)
-- Handles server-side pet merging validation and processing
-- Ensures security and prevents cheating

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PetConfig = require(ReplicatedStorage.Shared.config.PetConfig)
local DataService = require(ServerScriptService.services.DataService)
local PlayerService = require(ServerScriptService.services.PlayerService)

local PetMergeService = {}
PetMergeService.__index = PetMergeService

-- Import the shared merge logic for consistency
local PetMergeController = require(ReplicatedStorage.Shared.controllers.PetMergeController)

function PetMergeService:Initialize()
    print("PetMergeService: Initializing...")
    
    -- Set up merge remote
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local mergePetsRemote = remotes:FindFirstChild("MergePets")
    
    if not mergePetsRemote then
        mergePetsRemote = Instance.new("RemoteEvent")
        mergePetsRemote.Name = "MergePets"
        mergePetsRemote.Parent = remotes
    end
    
    mergePetsRemote.OnServerEvent:Connect(function(player, requestData)
        self:HandleMergeRequest(player, requestData)
    end)
    
    print("PetMergeService: Initialized successfully")
end

function PetMergeService:HandleMergeRequest(player, requestData)
    print(string.format("PetMergeService: %s requesting pet merge", player.Name))
    
    -- Get the remote to send response
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local mergePetsRemote = remotes:FindFirstChild("MergePets")
    
    -- Validate request structure
    if not requestData or not requestData.petIds or #requestData.petIds ~= 3 then
        warn("PetMergeService: Invalid merge request from", player.Name)
        if mergePetsRemote then
            mergePetsRemote:FireClient(player, {
                success = false,
                error = "Invalid merge request"
            })
        end
        return
    end
    
    local petId1, petId2, petId3 = requestData.petIds[1], requestData.petIds[2], requestData.petIds[3]
    
    -- Get player data
    local playerData = DataService:GetPlayerData(player)
    if not playerData then
        warn("PetMergeService: No player data found for", player.Name)
        if mergePetsRemote then
            mergePetsRemote:FireClient(player, {
                success = false,
                error = "Player data not found"
            })
        end
        return
    end
    
    -- Find the pets to merge
    local pet1, pet2, pet3 = self:FindPetsByIds(playerData.ownedPets, petId1, petId2, petId3)
    
    if not pet1 or not pet2 or not pet3 then
        warn("PetMergeService: Could not find all pets for merge:", petId1, petId2, petId3)
        if mergePetsRemote then
            mergePetsRemote:FireClient(player, {
                success = false,
                error = "Could not find all selected pets"
            })
        end
        return
    end
    
    -- Validate pets can be merged (server-side validation)
    local canMerge, error = self:ValidateMerge(player, pet1, pet2, pet3)
    if not canMerge then
        warn("PetMergeService: Merge validation failed for", player.Name, ":", error)
        if mergePetsRemote then
            mergePetsRemote:FireClient(player, {
                success = false,
                error = error
            })
        end
        return
    end
    
    -- Calculate diamond cost and validate player has enough
    local diamondCost = self:CalculateDiamondCost(pet1, pet2, pet3)
    local playerDiamonds = playerData.resources.diamonds or 0
    
    if playerDiamonds < diamondCost then
        warn(string.format("PetMergeService: %s has insufficient diamonds (%d/%d)", 
            player.Name, playerDiamonds, diamondCost))
        if mergePetsRemote then
            mergePetsRemote:FireClient(player, {
                success = false,
                error = "Not enough diamonds"
            })
        end
        return
    end
    
    -- Perform the merge
    local success, mergedPet = self:ExecuteMerge(player, pet1, pet2, pet3, diamondCost)
    
    if success then
        print(string.format("PetMergeService: %s successfully merged pets into %s (%s %s)", 
            player.Name, mergedPet.name, mergedPet.aura, 
            PetConfig:GetSizeData(mergedPet.size).displayName))
        
        -- Send success response to client
        if mergePetsRemote then
            mergePetsRemote:FireClient(player, {
                success = true,
                newPet = mergedPet
            })
        end
        
        -- Sync updated data to client
        PlayerService:SyncPlayerDataToClient(player, true) -- Priority sync
    else
        warn("PetMergeService: Merge execution failed for", player.Name)
        if mergePetsRemote then
            mergePetsRemote:FireClient(player, {
                success = false,
                error = "Merge execution failed"
            })
        end
    end
end

function PetMergeService:FindPetsByIds(ownedPets, petId1, petId2, petId3)
    local pet1, pet2, pet3 = nil, nil, nil
    
    for _, pet in ipairs(ownedPets or {}) do
        if pet.uniqueId == petId1 then
            pet1 = pet
        elseif pet.uniqueId == petId2 then
            pet2 = pet
        elseif pet.uniqueId == petId3 then
            pet3 = pet
        end
    end
    
    return pet1, pet2, pet3
end

function PetMergeService:ValidateMerge(player, pet1, pet2, pet3)
    -- Check same size requirement
    local size1 = pet1.size or 1
    local size2 = pet2.size or 1
    local size3 = pet3.size or 1
    
    if size1 ~= size2 or size2 ~= size3 then
        return false, "All pets must be the same size"
    end
    
    -- Check pets are not assigned
    local playerData = DataService:GetPlayerData(player)
    local companionPets = playerData.companionPets or {}
    
    for _, assignedPet in ipairs(companionPets) do
        if assignedPet.uniqueId == pet1.uniqueId or 
           assignedPet.uniqueId == pet2.uniqueId or 
           assignedPet.uniqueId == pet3.uniqueId then
            return false, "Cannot merge assigned pets"
        end
    end
    
    -- Validate pet data integrity
    for _, pet in ipairs({pet1, pet2, pet3}) do
        local isValid, validationError = PetConfig:ValidatePetCollection(pet.id, pet.aura, pet.size)
        if not isValid then
            return false, "Invalid pet data: " .. validationError
        end
    end
    
    return true, "Merge validation passed"
end

function PetMergeService:CalculateDiamondCost(pet1, pet2, pet3)
    -- Use the same calculation as client for consistency
    local function getPetRarityValue(pet)
        local combinedProbability, _ = PetConfig:CalculateCombinedRarity(pet.id or 1, pet.aura)
        return 1 / (combinedProbability or 0.001)
    end
    
    local rarity1 = getPetRarityValue(pet1)
    local rarity2 = getPetRarityValue(pet2)
    local rarity3 = getPetRarityValue(pet3)
    local totalRarity = rarity1 + rarity2 + rarity3
    
    -- Base cost and scaling (same as client)
    local cost = 50 -- BASE_DIAMOND_COST
    local rarityMultiplier = math.log(totalRarity / 100) + 1
    rarityMultiplier = math.max(1, rarityMultiplier)
    rarityMultiplier = math.min(10, rarityMultiplier)
    
    cost = math.floor(cost * rarityMultiplier)
    
    -- Size multiplier
    local size = pet1.size or 1
    local sizeMultiplier = 1 + (size - 1) * 0.5
    cost = math.floor(cost * sizeMultiplier)
    
    return math.max(10, cost)
end

function PetMergeService:ExecuteMerge(player, pet1, pet2, pet3, diamondCost)
    local playerData = DataService:GetPlayerData(player)
    if not playerData then
        return false, nil
    end
    
    -- Deduct diamonds
    local success = DataService:SpendDiamonds(player, diamondCost)
    if not success then
        return false, nil
    end
    
    -- Roll for merge outcome
    local outcomeType = self:RollMergeOutcome()
    
    -- Generate merged pet
    local mergedPet = self:GenerateMergedPet(player, pet1, pet2, pet3, outcomeType)
    if not mergedPet then
        -- Refund diamonds if pet generation failed
        DataService:AddDiamonds(player, diamondCost)
        return false, nil
    end
    
    -- Remove the 3 input pets from player's collection
    local profile = DataService:GetProfile(player)
    if not profile then
        -- Refund diamonds if profile access failed
        DataService:AddDiamonds(player, diamondCost)
        return false, nil
    end
    
    local ownedPets = profile.Data.ownedPets or {}
    local newOwnedPets = {}
    
    -- Filter out the merged pets
    for _, pet in ipairs(ownedPets) do
        if pet.uniqueId ~= pet1.uniqueId and 
           pet.uniqueId ~= pet2.uniqueId and 
           pet.uniqueId ~= pet3.uniqueId then
            table.insert(newOwnedPets, pet)
        end
    end
    
    -- Add the new merged pet
    table.insert(newOwnedPets, mergedPet)
    
    -- Update player data
    profile.Data.ownedPets = newOwnedPets
    
    return true, mergedPet
end

function PetMergeService:RollMergeOutcome()
    local roll = math.random()
    
    if roll <= 0.40 then -- 40% success
        return "success"
    elseif roll <= 0.75 then -- 35% same tier  
        return "same"
    else -- 25% downgrade
        return "downgrade"
    end
end

function PetMergeService:GenerateMergedPet(player, pet1, pet2, pet3, outcomeType)
    -- Calculate combined rarity value
    local function getPetRarityValue(pet)
        local combinedProbability, _ = PetConfig:CalculateCombinedRarity(pet.id or 1, pet.aura)
        if not combinedProbability or combinedProbability <= 0 then
            print(string.format("PetMergeService: WARNING - Pet %s (id=%d, aura=%s) has invalid probability %s", 
                pet.name or "Unknown", pet.id or 1, pet.aura or "none", tostring(combinedProbability)))
            combinedProbability = 0.001 -- Fallback
        end
        local rarityValue = 1 / combinedProbability
        print(string.format("PetMergeService: Pet %s (id=%d, aura=%s) - probability=%.6f, rarity=1/%d", 
            pet.name or "Unknown", pet.id or 1, pet.aura or "none", combinedProbability, math.floor(rarityValue)))
        return rarityValue
    end
    
    local rarity1 = getPetRarityValue(pet1)
    local rarity2 = getPetRarityValue(pet2)
    local rarity3 = getPetRarityValue(pet3)
    local totalRarity = rarity1 + rarity2 + rarity3
    
    -- Calculate outcome rarity based on type
    local outcomeRarity
    if outcomeType == "success" then
        outcomeRarity = totalRarity * 1.5 -- 50% better
    elseif outcomeType == "same" then
        outcomeRarity = totalRarity * 1.0 -- Same
    else -- downgrade
        outcomeRarity = totalRarity * 0.6 -- 40% worse
    end
    
    -- Determine size (chance for upgrade on success)
    local inputSize = pet1.size or 1
    local outputSize = inputSize
    
    if outcomeType == "success" and math.random() < 0.30 then -- 30% chance for size upgrade
        outputSize = math.min(inputSize + 1, 5)
    end
    
    -- Select random merged aura
    local mergedAuras = {"merged", "zombie"}
    local selectedAura = mergedAuras[math.random(#mergedAuras)]
    
    -- Select random base pet
    local basePetId = math.random(1, 100)
    local basePetData = PetConfig:GetPetData(basePetId)
    
    if not basePetData then
        basePetId = 1 -- Fallback
        basePetData = PetConfig:GetPetData(basePetId)
    end
    
    -- Calculate custom value based on outcome rarity (not standard pet calculation)
    local baseValue = basePetData.value or 1
    local sizeMultiplier = math.pow(2, outputSize - 1) -- Size multiplier: 1x, 2x, 4x, 8x, 16x
    local rarityBasedValue = math.floor(baseValue * sizeMultiplier * (outcomeRarity / 1000))
    
    -- Debug logging
    print(string.format("PetMergeService: Merge calculation - rarity1=%d, rarity2=%d, rarity3=%d", rarity1, rarity2, rarity3))
    print(string.format("PetMergeService: totalRarity=%d, outcomeType=%s, outcomeRarity=%d", totalRarity, outcomeType, outcomeRarity))
    print(string.format("PetMergeService: baseValue=%d, sizeMultiplier=%.2f, rarityBasedValue=%d", baseValue, sizeMultiplier, rarityBasedValue))
    
    -- Ensure reasonable bounds
    local finalValue = math.max(1, math.min(rarityBasedValue, 999999999))
    print(string.format("PetMergeService: finalValue=%d", finalValue))
    
    -- Create merged pet with custom calculation
    local mergedPet = {
        id = basePetId,
        name = basePetData.name,
        aura = selectedAura,
        size = outputSize,
        value = finalValue,
        rarity = math.floor(outcomeRarity), -- Set the actual rarity value
        mergedFromRarity = outcomeRarity,
        mergedTimestamp = tick(),
        mergedOutcome = outcomeType,
        uniqueId = player.Name .. "_" .. tostring(math.random(100000, 999999)) .. "_" .. tostring(tick()),
        isAssigned = false,
        collectedAt = tick()
    }
    
    return mergedPet
end

return PetMergeService