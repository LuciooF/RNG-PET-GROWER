-- PetService - Handles pet creation, management, and operations
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DataService = require(script.Parent.DataService)
local PetConfig = require(ReplicatedStorage.config.PetConfig)
local PetUtils = require(ReplicatedStorage.utils.PetUtils)
local BoostCalculator = require(ReplicatedStorage.utils.BoostCalculator)

local PetService = {}
PetService.__index = PetService

-- Configuration
local DEFAULT_MAX_EQUIPPED_PETS = 3 -- Can be increased with gamepasses

function PetService:Initialize()
    -- Service initialized
end

-- Get max equipped pets for a player (with gamepass bonuses)
function PetService:GetMaxEquippedPets(player)
    -- TODO: Add gamepass logic here later
    -- local GamepassService = require(script.Parent.GamepassService)
    -- local extraSlots = GamepassService:GetEquippedPetSlots(player)
    -- return DEFAULT_MAX_EQUIPPED_PETS + extraSlots
    
    return DEFAULT_MAX_EQUIPPED_PETS
end

-- Create a new random pet for a player
function PetService:CreateRandomPet(player, rarityWeights, variationWeights)
    local newPet = PetConfig.createRandomPet(rarityWeights, variationWeights)
    
    if newPet then
        local success = DataService:AddPet(player, newPet)
        if success then
            return newPet
        end
    end
    
    return nil
end

-- Create a specific pet for a player
function PetService:CreatePet(player, petName, variation)
    local basePet = PetConfig.getBasePetByName(petName)
    if not basePet then
        warn("PetService: Pet not found: " .. tostring(petName))
        return nil
    end
    
    local newPet = PetConfig.createPet(basePet, variation)
    local success = DataService:AddPet(player, newPet)
    
    if success then
        return newPet
    end
    
    return nil
end

-- Equip a pet for a player
function PetService:EquipPet(player, petId)
    local maxEquipped = self:GetMaxEquippedPets(player)
    
    -- Delegate to DataService - single source of truth with auto-sync
    return DataService:EquipPetById(player, petId, maxEquipped)
end

-- Unequip a pet for a player
function PetService:UnequipPet(player, petId)
    -- Delegate to DataService - single source of truth with auto-sync
    return DataService:UnequipPetById(player, petId)
end

-- Get best pets from player's collection
function PetService:GetBestPets(player, maxCount)
    local playerData = DataService:GetPlayerData(player)
    if not playerData then
        return {}
    end
    
    return PetUtils.getBestPets(playerData.Pets, maxCount or 10)
end

-- Auto-equip best pets for a player
function PetService:AutoEquipBestPets(player, maxEquipped)
    maxEquipped = maxEquipped or 3 -- Default to 3 equipped pets for new design
    
    -- Get best pets from inventory (business logic only)
    local bestPets = self:GetBestPets(player, maxEquipped)
    
    if #bestPets == 0 then
        return false, "No pets available to equip"
    end
    
    -- Delegate to DataService - single source of truth with auto-sync
    local success, message = DataService:SetEquippedPets(player, bestPets)
    
    if success then
        -- Auto-equipped best pets
    end
    
    return success, message
end

-- Calculate total boost from equipped pets AND OP pets
function PetService:GetEquippedBoost(player)
    local playerData = DataService:GetPlayerData(player)
    if not playerData then
        return 1.0
    end
    
    -- Calculate boost from regular equipped pets
    local regularBoost = PetUtils.calculateTotalBoost(playerData.EquippedPets)
    
    -- Calculate boost from OP pets (they're always active)
    local opBoost = 0
    if playerData.OPPets then
        for _, opPet in ipairs(playerData.OPPets) do
            opBoost = opBoost + (opPet.FinalBoost or opPet.BaseBoost or 0)
        end
    end
    
    -- Return combined boost (additive)
    return regularBoost + opBoost
end

-- Calculate total value from equipped pets
function PetService:GetEquippedValue(player)
    local playerData = DataService:GetPlayerData(player)
    if not playerData then
        return 0
    end
    
    return PetUtils.calculateTotalValue(playerData.EquippedPets)
end

-- Get pets by rarity from player's collection
function PetService:GetPlayerPetsByRarity(player, rarity)
    local playerData = DataService:GetPlayerData(player)
    if not playerData then
        return {}
    end
    
    local petsOfRarity = {}
    for _, pet in pairs(playerData.Pets) do
        if pet.Rarity == rarity then
            table.insert(petsOfRarity, pet)
        end
    end
    
    return petsOfRarity
end

-- Validate pet ownership
function PetService:PlayerOwnsPet(player, petId)
    local playerData = DataService:GetPlayerData(player)
    if not playerData then
        return false
    end
    
    for _, pet in pairs(playerData.Pets) do
        if pet.ID == petId then
            return true
        end
    end
    
    return false
end

-- Remove a pet from player's collection
function PetService:RemovePet(player, petId)
    local profile = DataService:GetPlayerProfile(player)
    if not profile then
        return false
    end
    
    -- Delegate to DataService - single source of truth with auto-sync
    return DataService:RemovePetById(player, petId)
end

-- Store active heaven processing per player
local heavenProcessing = {}

-- Store last heaven processing time per player (for cooldown)
local lastProcessingTime = {}

-- Show error message to player
function PetService:ShowErrorMessage(player, message)
    -- Get the remote event (should already exist from Main.server.lua)
    local errorMessageRemote = ReplicatedStorage:FindFirstChild("ShowErrorMessage")
    if errorMessageRemote then
        -- Send error message to client
        errorMessageRemote:FireClient(player, message)
    else
        warn("PetService: ShowErrorMessage remote event not found!")
    end
end

-- Start heaven processing for a player
function PetService:StartHeavenProcessing(player)
    -- Check cooldown (prevent spam clicking)
    local currentTime = tick()
    local lastTime = lastProcessingTime[player] or 0
    local cooldownTime = 2 -- 2 seconds cooldown
    
    if currentTime - lastTime < cooldownTime then
        -- Still in cooldown, ignore this request
        return false
    end
    
    -- Update last processing time
    lastProcessingTime[player] = currentTime
    
    -- Get player data
    local playerData = DataService:GetPlayerData(player)
    if not playerData then
        return false
    end
    
    -- Check if player has any tubes unlocked
    local PlotService = require(script.Parent.PlotService)
    local ownedTubes = PlotService:GetPlayerOwnedTubes(player)
    
    if #ownedTubes == 0 then
        -- Show error message to player
        self:ShowErrorMessage(player, "You have to have unlocked at least 1 heaven tube first before sending pets to heaven!")
        return false
    end
    
    -- Only process pets from inventory (Pets array) that are NOT equipped
    local petsToProcess = {}
    local equippedPetIds = {}
    
    -- Create a set of equipped pet IDs for quick lookup
    for _, equippedPet in pairs(playerData.EquippedPets or {}) do
        equippedPetIds[equippedPet.ID] = true
    end
    
    -- Add only unequipped pets from main Pets array (excluding OP pets)
    for _, pet in pairs(playerData.Pets or {}) do
        if not equippedPetIds[pet.ID] then
            -- Check if this is an OP pet (by rarity)
            local isOPPet = false
            if pet.Rarity then
                local rarityName = pet.Rarity
                if type(pet.Rarity) == "table" then
                    rarityName = pet.Rarity.RarityName
                end
                isOPPet = (rarityName == "OP")
            end
            
            -- Only add non-OP pets to processing
            if not isOPPet then
                table.insert(petsToProcess, pet)
            end
        end
    end
    
    if #petsToProcess == 0 then
        self:ShowErrorMessage(player, "You have no unequipped pets to send to heaven! (Equipped pets are protected)")
        return false
    end
    
    -- Delegate to DataService - single source of truth with auto-sync
    local success, result = DataService:ProcessPetsToHeaven(player, petsToProcess)
    
    if not success then
        return false, result
    end
    
    -- Update processing counter
    self:UpdateProcessingCounter(player)
    
    -- Start the heaven processing loop
    self:StartHeavenProcessingLoop(player)
    
    return true
end

-- Start the heaven processing loop for a player
function PetService:StartHeavenProcessingLoop(player)
    -- Stop any existing processing
    if heavenProcessing[player] then
        task.cancel(heavenProcessing[player])
    end
    
    -- Get player's owned tubes
    local PlotService = require(script.Parent.PlotService)
    local ownedTubes = PlotService:GetPlayerOwnedTubes(player)
    
    if #ownedTubes == 0 then
        return
    end
    
    -- Start processing thread
    heavenProcessing[player] = task.spawn(function()
        while true do
            local success = self:ProcessOnePetPerTube(player, ownedTubes)
            if not success then
                break -- No more pets to process
            end
            -- Apply speed multiplier from gamepasses
            local speedMultiplier = self:GetProcessingSpeedMultiplier(player)
            local waitTime = 3 / speedMultiplier -- 2x speed = 1.5 seconds, normal = 3 seconds
            wait(waitTime)
        end
        
        -- Clean up when done
        heavenProcessing[player] = nil
    end)
end

-- Process one pet per tube
function PetService:ProcessOnePetPerTube(player, ownedTubes)
    -- Processing one pet per tube
    
    local profile = DataService:GetPlayerProfile(player)
    if not profile then
        -- No profile found
        return false
    end
    
    local processingPets = profile.Data.ProcessingPets or {}
    if #processingPets == 0 then
        -- No pets to process
        return false -- No more pets to process
    end
    
    -- Process up to one pet per tube
    local petsProcessed = 0
    local maxProcessThisRound = math.min(#ownedTubes, #processingPets)
    local totalMoneyToAdd = 0 -- Batch money updates to prevent race conditions in multiplayer
    
    -- Processing pets through tubes
    
    for i = 1, maxProcessThisRound do
        local pet = processingPets[1] -- Always take first pet
        local tubeNumber = ownedTubes[i]
        
        -- Calculate pet value (BaseValue * VariationMultiplier)
        local petValue = self:CalculatePetValue(pet)
        
        -- Apply gamepass multipliers (includes equipped pet boost)
        local finalValue = self:ApplyGamepassMultipliers(player, petValue, "Money")
        
        -- Processing individual pet
        
        -- Accumulate money instead of updating immediately (prevents multiplayer race conditions)
        totalMoneyToAdd = totalMoneyToAdd + finalValue
        
        -- Create visual heaven effect
        self:CreateHeavenEffect(player, pet, tubeNumber)
        
        -- Fire sound effect event to client
        local petProcessedRemote = ReplicatedStorage:FindFirstChild("PetProcessed")
        if petProcessedRemote then
            petProcessedRemote:FireClient(player)
        end
        
        -- Remove pet from ProcessingPets
        table.remove(processingPets, 1)
        
        petsProcessed = petsProcessed + 1
        
        -- Increment total processed pets counter for tutorial tracking
        profile.Data.ProcessedPets = (profile.Data.ProcessedPets or 0) + 1
    end
    
    -- Delegate to DataService - single source of truth with auto-sync
    if petsProcessed > 0 then
        -- Processed pets successfully
        
        -- Apply potion multiplier to money reward
        local PotionService = require(script.Parent.PotionService)
        local potionMultiplier = PotionService:GetBoostMultiplier(player, "Money")
        local finalMoneyToAdd = math.floor(totalMoneyToAdd * potionMultiplier)
        
        -- Update processing pets and add money reward (DataService handles sync)
        local success = DataService:UpdateProcessingAndMoney(player, processingPets, finalMoneyToAdd, petsProcessed)
        -- Processing update completed
        
        -- Update processing counter
        self:UpdateProcessingCounter(player)
        
        -- Update plot GUI colors since money changed
        local PlotService = require(script.Parent.PlotService)
        local AreaService = require(script.Parent.AreaService)
        local assignedAreaNumber = AreaService:GetPlayerAssignedArea(player)
        
        if assignedAreaNumber then
            local playerAreas = game.Workspace:FindFirstChild("PlayerAreas")
            if playerAreas then
                local area = playerAreas:FindFirstChild("PlayerArea" .. assignedAreaNumber)
                if area then
                    PlotService:UpdatePlotGUIs(area, player)
                end
            end
        end
    end
    
    return #processingPets > 0 -- Return true if more pets to process
end

-- Calculate pet value including variation multiplier
function PetService:CalculatePetValue(pet)
    -- Get base value
    local baseValue = pet.BaseValue or 1
    
    -- Get variation multiplier from pet constants
    local PetConstants = require(ReplicatedStorage.constants.PetConstants)
    local variationMultiplier = PetConstants.getVariationMultiplier(pet.Variation or "Bronze")
    
    return math.floor(baseValue * variationMultiplier)
end

-- Create heaven effect (floating pet ball) - Client-side version
function PetService:CreateHeavenEffect(player, pet, tubeNumber)
    -- Send heaven pet ball spawn request to the client
    local spawnHeavenPetBallRemote = ReplicatedStorage:FindFirstChild("SpawnHeavenPetBall")
    if spawnHeavenPetBallRemote then
        -- Get player's area name
        local AreaService = require(script.Parent.AreaService)
        local assignedAreaNumber = AreaService:GetPlayerAssignedArea(player)
        
        if assignedAreaNumber then
            local areaName = "PlayerArea" .. assignedAreaNumber
            spawnHeavenPetBallRemote:FireClient(player, pet, tubeNumber, areaName)
        end
    else
        warn("PetService: SpawnHeavenPetBall remote not found")
    end
end

-- Stop heaven processing for a player
function PetService:StopHeavenProcessing(player)
    if heavenProcessing[player] then
        task.cancel(heavenProcessing[player])
        heavenProcessing[player] = nil
    end
end

-- Update processing counter for a player's area
function PetService:UpdateProcessingCounter(player)
    -- Get player's area
    local AreaService = require(script.Parent.AreaService)
    local assignedAreaNumber = AreaService:GetPlayerAssignedArea(player)
    
    if not assignedAreaNumber then
        return
    end
    
    -- Get processing pets count
    local playerData = DataService:GetPlayerData(player)
    if not playerData then
        return
    end
    
    local processingCount = #(playerData.ProcessingPets or {})
    
    -- Update the counter GUI
    local PlotService = require(script.Parent.PlotService)
    local areaName = "PlayerArea" .. assignedAreaNumber
    PlotService:UpdateProcessingCounter(areaName, processingCount)
end

-- Apply gamepass multipliers to a value
function PetService:ApplyGamepassMultipliers(player, baseValue, rewardType)
    local playerData = DataService:GetPlayerData(player)
    if not playerData or not playerData.OwnedGamepasses then
        -- No gamepass multipliers available
        return baseValue
    end
    
    local multiplier = 1
    local gamepasses = {}
    
    -- Convert OwnedGamepasses array to lookup table
    for _, gamepassName in pairs(playerData.OwnedGamepasses or {}) do
        gamepasses[gamepassName] = true
    end
    
    -- Apply multipliers based on reward type (all additive to match client calculation)
    if rewardType == "Money" then
        -- Calculate gamepass multiplier (multiplicative for gamepasses themselves)
        local gamepassMultiplier = 1
        if gamepasses.TwoXMoney then
            gamepassMultiplier = gamepassMultiplier * 2
        end
        if gamepasses.VIP then
            gamepassMultiplier = gamepassMultiplier * 2
        end
        
        -- Apply equipped pet and OP pet boost
        local petBoostMultiplier = self:GetEquippedPetBoostMultiplier(player)
        
        -- Apply rebirth bonus
        local playerRebirths = playerData.Resources and playerData.Resources.Rebirths or 0
        local rebirthMultiplier = 1 + (playerRebirths * 0.5)
        
        -- Calculating multipliers
        
        -- Total calculation matches client: base 1x + pet boost + OP pet boost + gamepass bonus + rebirth bonus
        multiplier = 1 + (petBoostMultiplier - 1) + (gamepassMultiplier - 1) + (rebirthMultiplier - 1)
        
        -- Applied gamepass multipliers
    elseif rewardType == "Diamonds" then
        -- Check for 2x Diamonds gamepass
        if gamepasses.TwoXDiamonds then
            multiplier = multiplier * 2
        end
        
        -- Check for VIP gamepass (stacks with other gamepasses)
        if gamepasses.VIP then
            multiplier = multiplier * 2
        end
    end
    
    return math.floor(baseValue * multiplier)
end

-- Calculate total boost multiplier from equipped pets AND OP pets (now centralized)
function PetService:GetEquippedPetBoostMultiplier(player)
    local playerData = DataService:GetPlayerData(player)
    if not playerData then
        return 1 -- No boost if no player data
    end
    
    -- Use centralized boost calculation (equipped pets + OP pets only, no gamepasses/rebirths)
    local equippedBoost = BoostCalculator.calculateEquippedPetBoost(playerData.EquippedPets)
    local opPetBoost = BoostCalculator.calculateOPPetBoost(playerData.OPPets)
    
    return 1 + equippedBoost + opPetBoost
end

-- Get processing speed multiplier from gamepasses
function PetService:GetProcessingSpeedMultiplier(player)
    local playerData = DataService:GetPlayerData(player)
    if not playerData or not playerData.OwnedGamepasses then
        return 1
    end
    
    local gamepasses = {}
    
    -- Convert OwnedGamepasses array to lookup table
    for _, gamepassName in pairs(playerData.OwnedGamepasses or {}) do
        gamepasses[gamepassName] = true
    end
    
    -- Check for 2x Heaven Speed gamepass
    if gamepasses.TwoXHeavenSpeed then
        return 2 -- 2x faster processing
    end
    
    -- Check for VIP gamepass (includes all benefits)
    if gamepasses.VIP then
        return 2 -- 2x faster processing
    end
    
    return 1 -- Normal speed
end

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
    if heavenProcessing[player] then
        task.cancel(heavenProcessing[player])
        heavenProcessing[player] = nil
    end
    lastProcessingTime[player] = nil
end)

return PetService