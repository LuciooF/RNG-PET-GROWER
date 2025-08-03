-- PetMixerService - Handles pet mixing with offline timer support
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local DataService = require(script.Parent.DataService)
local StateService = require(script.Parent.StateService)
local PetMixerConfig = require(ReplicatedStorage.config.PetMixerConfig)
-- We'll use basic color mapping for now to avoid circular dependencies

local PetMixerService = {}
PetMixerService.__index = PetMixerService

-- Track mixer check connections
local mixerCheckConnections = {}

function PetMixerService:Initialize()
    
    -- Set up periodic checks for all players
    self:SetupMixerCompletionChecks()
end

-- Start a new pet mixing process
function PetMixerService:StartMixing(player, petIds)
    local profile = DataService:GetPlayerProfile(player)
    if not profile then
        return false, "No player data found"
    end
    
    -- Validate pet count
    if not petIds or #petIds == 0 then
        return false, "No pets selected for mixing"
    end
    
    if #petIds < PetMixerConfig.MIN_PETS_PER_MIX then
        return false, "Need at least " .. PetMixerConfig.MIN_PETS_PER_MIX .. " pets for mixing"
    end
    
    if #petIds > PetMixerConfig.MAX_PETS_PER_MIX then
        return false, "Too many pets selected (max " .. PetMixerConfig.MAX_PETS_PER_MIX .. ")"
    end
    
    -- Check diamond cost
    local diamondCost = PetMixerConfig.calculateDiamondCost(#petIds)
    local currentDiamonds = profile.Data.Resources.Diamonds or 0
    
    if currentDiamonds < diamondCost then
        return false, "Not enough diamonds (need " .. diamondCost .. ", have " .. currentDiamonds .. ")"
    end
    
    -- Check active mixer limit
    local activeMixers = 0
    for _, mixer in ipairs(profile.Data.Mixers or {}) do
        if not mixer.claimed then
            activeMixers = activeMixers + 1
        end
    end
    
    if activeMixers >= PetMixerConfig.MAX_ACTIVE_MIXERS then
        return false, "Maximum active mixers reached (max " .. PetMixerConfig.MAX_ACTIVE_MIXERS .. ")"
    end
    
    -- Validate and collect input pets
    local inputPets = {}
    local petsToRemove = {}
    
    for _, petId in ipairs(petIds) do
        local found = false
        for i, pet in ipairs(profile.Data.Pets) do
            if pet.ID == petId then
                -- Check if pet is equipped or processing
                local isEquipped = false
                for _, equipped in ipairs(profile.Data.EquippedPets or {}) do
                    if equipped.ID == petId then
                        isEquipped = true
                        break
                    end
                end
                
                if isEquipped then
                    return false, "Cannot mix equipped pets"
                end
                
                local isProcessing = false
                for _, processing in ipairs(profile.Data.ProcessingPets or {}) do
                    if processing.ID == petId then
                        isProcessing = true
                        break
                    end
                end
                
                if isProcessing then
                    return false, "Cannot mix pets being processed"
                end
                
                table.insert(inputPets, pet)
                table.insert(petsToRemove, i)
                found = true
                break
            end
        end
        
        if not found then
            return false, "Pet not found in inventory"
        end
    end
    
    -- Remove pets from inventory (in reverse order to maintain indices)
    for i = #petsToRemove, 1, -1 do
        table.remove(profile.Data.Pets, petsToRemove[i])
    end
    
    -- Deduct diamond cost
    profile.Data.Resources.Diamonds = profile.Data.Resources.Diamonds - diamondCost
    
    -- Calculate output pet
    local outputPet = self:CalculateOutputPet(inputPets)
    
    -- Calculate mixing time
    local mixTime = PetMixerConfig.calculateMixTime(#inputPets)
    local currentTime = os.time()
    
    -- Create mixer object
    local mixer = {
        id = HttpService:GenerateGUID(false),
        inputPets = inputPets,
        outputPet = outputPet,
        startTime = currentTime,
        completionTime = currentTime + mixTime,
        claimed = false
    }
    
    -- Add to player's mixers
    if not profile.Data.Mixers then
        profile.Data.Mixers = {}
    end
    table.insert(profile.Data.Mixers, mixer)
    
    -- Sync data to client
    StateService:BroadcastPlayerDataUpdate(player)
    
    
    return true, mixer
end

-- Calculate the output pet based on input pets (simplified)
function PetMixerService:CalculateOutputPet(inputPets)
    if #inputPets == 0 then
        return nil
    end
    
    -- 10 Exclusive mixing-only pets (same as client UI)
    local exclusiveMixingPets = {
        "Witch Dominus",              -- Magical themed
        "Time Traveller Doggy",       -- Sci-fi themed
        "Valentines Dragon",          -- Holiday themed  
        "Summer Dragon",              -- Season themed
        "Elf Dragon",                 -- Fantasy themed
        "Nerdy Dragon",               -- Character themed
        "Guard Dragon",               -- Professional themed
        "Circus Hat Trick Dragon",    -- Entertainment themed
        "Partner Dragon",             -- Relationship themed
        "Cyborg Dragon"               -- Tech themed
    }
    
    -- Select random exclusive pet for mixing output
    local randomIndex = math.random(1, #exclusiveMixingPets)
    local selectedExclusivePet = exclusiveMixingPets[randomIndex]
    
    -- Create mixed pet - always "Mixed" rarity and variation
    local outputPet = {
        ID = HttpService:GenerateGUID(false),
        Name = selectedExclusivePet, -- Use exclusive pet name instead of "Mix"
        ModelName = selectedExclusivePet, -- Set ModelName to match Name for proper asset loading
        Rarity = {
            RarityName = "Mixed",
            RarityChance = 50,
            RarityColor = {255, 100, 255} -- Store as RGB array for DataStore compatibility
        },
        Variation = {
            VariationName = "Mixed",
            VariationChance = 100,
            VariationColor = {255, 100, 255} -- Store as RGB array for DataStore compatibility
        },
        BaseBoost = PetMixerConfig.calculateMixedPetBoost(inputPets),
        BaseValue = PetMixerConfig.calculateMixedPetValue(inputPets)
    }
    
    -- Calculate final values
    outputPet.FinalBoost = outputPet.BaseBoost
    outputPet.FinalValue = outputPet.BaseValue
    
    return outputPet
end

-- Claim a completed mixer
function PetMixerService:ClaimMixer(player, mixerId)
    local profile = DataService:GetPlayerProfile(player)
    if not profile then
        return false, "No player data found"
    end
    
    -- Find the mixer
    local mixer = nil
    local mixerIndex = nil
    
    for i, m in ipairs(profile.Data.Mixers or {}) do
        if m.id == mixerId then
            mixer = m
            mixerIndex = i
            break
        end
    end
    
    if not mixer then
        return false, "Mixer not found"
    end
    
    if mixer.claimed then
        return false, "Mixer already claimed"
    end
    
    -- Check if mixer is complete
    local currentTime = os.time()
    if currentTime < mixer.completionTime then
        local timeLeft = mixer.completionTime - currentTime
        return false, "Mixer not ready yet (" .. timeLeft .. " seconds remaining)"
    end
    
    -- Add output pet to inventory with auto-equip logic
    if mixer.outputPet then
        -- Use DataService:AddPetToPlayer for consistent auto-equip behavior
        local DataService = require(script.Parent.DataService)
        local success, result = DataService:AddPetToPlayer(player, mixer.outputPet)
        
        if not success then
            -- If failed to add pet (e.g., inventory full), don't mark as claimed
            return false, result or "Failed to add pet to inventory"
        end
    end
    
    -- Mark as claimed
    mixer.claimed = true
    
    -- Remove claimed mixer
    table.remove(profile.Data.Mixers, mixerIndex)
    
    -- Sync data to client (this is also done by AddPetToPlayer, but ensure it's called)
    StateService:BroadcastPlayerDataUpdate(player)
    
    
    return true, mixer.outputPet
end

-- Cancel an active mixer (returns pets)
function PetMixerService:CancelMixer(player, mixerId)
    local profile = DataService:GetPlayerProfile(player)
    if not profile then
        return false, "No player data found"
    end
    
    -- Find the mixer
    local mixer = nil
    local mixerIndex = nil
    
    for i, m in ipairs(profile.Data.Mixers or {}) do
        if m.id == mixerId then
            mixer = m
            mixerIndex = i
            break
        end
    end
    
    if not mixer then
        return false, "Mixer not found"
    end
    
    if mixer.claimed then
        return false, "Cannot cancel claimed mixer"
    end
    
    -- Return input pets to inventory
    for _, pet in ipairs(mixer.inputPets) do
        table.insert(profile.Data.Pets, pet)
    end
    
    -- Remove mixer
    table.remove(profile.Data.Mixers, mixerIndex)
    
    -- Sync data to client
    StateService:BroadcastPlayerDataUpdate(player)
    
    
    return true
end

-- Check all mixers for completion
function PetMixerService:CheckMixerCompletions(player)
    local profile = DataService:GetPlayerProfile(player)
    if not profile then
        return
    end
    
    local currentTime = os.time()
    local hasCompletions = false
    
    for _, mixer in ipairs(profile.Data.Mixers or {}) do
        if not mixer.claimed and currentTime >= mixer.completionTime then
            hasCompletions = true
        end
    end
    
    -- Notify client if there are completions
    if hasCompletions then
        StateService:BroadcastPlayerDataUpdate(player)
    end
end

-- Get rarity color based on rarity name (returns RGB array for DataStore compatibility)
function PetMixerService:GetRarityColor(rarityName)
    local rarityColors = {
        Common = {200, 200, 200},    -- Gray
        Uncommon = {0, 255, 0},      -- Green
        Rare = {0, 162, 255},        -- Blue
        Epic = {163, 53, 238},       -- Purple
        Legendary = {255, 170, 0},   -- Orange
        Mythic = {255, 0, 0}         -- Red
    }
    return rarityColors[rarityName] or {255, 255, 255}
end

-- Set up periodic checks for mixer completions
function PetMixerService:SetupMixerCompletionChecks()
    -- Check every 5 seconds for all online players
    RunService.Heartbeat:Connect(function()
        if tick() % 5 < 0.1 then -- Check roughly every 5 seconds
            for _, player in ipairs(game.Players:GetPlayers()) do
                self:CheckMixerCompletions(player)
            end
        end
    end)
end

-- Check mixers when player joins (for offline progress)
function PetMixerService:OnPlayerJoined(player)
    -- Wait for data to load
    task.wait(3)
    
    self:CheckMixerCompletions(player)
end

return PetMixerService