-- PetService - Handles pet creation, management, and operations
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DataService = require(script.Parent.DataService)
local PetConfig = require(ReplicatedStorage.config.PetConfig)
local PetUtils = require(ReplicatedStorage.utils.PetUtils)

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
    local playerData = DataService:GetPlayerData(player)
    if not playerData then
        return false, "Player data not found"
    end
    
    -- Check if already at max equipped pets
    local maxEquipped = self:GetMaxEquippedPets(player)
    if #(playerData.EquippedPets or {}) >= maxEquipped then
        return false, "Maximum equipped pets reached (" .. maxEquipped .. ")"
    end
    
    -- Find the pet in player's collection
    local petToEquip = nil
    for _, pet in pairs(playerData.Pets or {}) do
        if pet.ID == petId then
            petToEquip = pet
            break
        end
    end
    
    if not petToEquip then
        return false, "Pet not found in inventory"
    end
    
    -- Check if pet is already equipped
    for _, equippedPet in pairs(playerData.EquippedPets or {}) do
        if equippedPet.ID == petId then
            return false, "Pet already equipped"
        end
    end
    
    -- Add to equipped pets (pet stays in inventory too)
    local profile = DataService:GetPlayerProfile(player)
    if not profile then
        return false, "Player profile not found"
    end
    
    -- Add to EquippedPets array
    table.insert(profile.Data.EquippedPets, petToEquip)
    
    -- Sync data to client
    local StateService = require(script.Parent.StateService)
    StateService:BroadcastPlayerDataUpdate(player)
    
    return true, "Pet equipped successfully"
end

-- Unequip a pet for a player
function PetService:UnequipPet(player, petId)
    local playerData = DataService:GetPlayerData(player)
    if not playerData then
        return false, "Player data not found"
    end
    
    -- Find and remove from equipped pets
    local profile = DataService:GetPlayerProfile(player)
    if not profile then
        return false, "Player profile not found"
    end
    
    local newEquippedPets = {}
    local found = false
    
    for _, equippedPet in pairs(playerData.EquippedPets or {}) do
        if equippedPet.ID ~= petId then
            table.insert(newEquippedPets, equippedPet)
        else
            found = true
        end
    end
    
    if found then
        profile.Data.EquippedPets = newEquippedPets
        
        -- Sync data to client
        local StateService = require(script.Parent.StateService)
        StateService:BroadcastPlayerDataUpdate(player)
        
        return true, "Pet unequipped successfully"
    end
    
    return false, "Pet not found in equipped pets"
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
    maxEquipped = maxEquipped or 6 -- Default max equipped pets
    
    local playerData = DataService:GetPlayerData(player)
    if not playerData then
        return false
    end
    
    local profile = DataService:GetPlayerProfile(player)
    if not profile then
        return false
    end
    
    -- Get best pets
    local bestPets = self:GetBestPets(player, maxEquipped)
    
    -- Replace equipped pets with best pets
    profile.Data.EquippedPets = bestPets
    
    return true
end

-- Calculate total boost from equipped pets
function PetService:GetEquippedBoost(player)
    local playerData = DataService:GetPlayerData(player)
    if not playerData then
        return 1.0
    end
    
    return PetUtils.calculateTotalBoost(playerData.EquippedPets)
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
    
    -- Remove from pets collection
    local newPets = {}
    local found = false
    
    for _, pet in pairs(profile.Data.Pets) do
        if pet.ID ~= petId then
            table.insert(newPets, pet)
        else
            found = true
        end
    end
    
    if found then
        profile.Data.Pets = newPets
        
        -- Also remove from equipped pets if equipped
        self:UnequipPet(player, petId)
        
        return true
    end
    
    return false
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
    
    -- Add only unequipped pets from main Pets array
    for _, pet in pairs(playerData.Pets or {}) do
        if not equippedPetIds[pet.ID] then
            table.insert(petsToProcess, pet)
        end
    end
    
    if #petsToProcess == 0 then
        self:ShowErrorMessage(player, "You have no unequipped pets to send to heaven! (Equipped pets are protected)")
        return false
    end
    
    -- Move only unequipped pets to ProcessingPets
    local profile = DataService:GetPlayerProfile(player)
    if not profile then
        return false
    end
    
    -- Set ProcessingPets to unequipped pets only
    profile.Data.ProcessingPets = petsToProcess
    
    -- Update Pets array to contain only equipped pets (remove unequipped ones)
    local newPetsArray = {}
    for _, pet in pairs(playerData.Pets or {}) do
        if equippedPetIds[pet.ID] then
            table.insert(newPetsArray, pet)
        end
    end
    profile.Data.Pets = newPetsArray
    -- Keep EquippedPets untouched so they remain equipped
    
    -- Sync data to client
    local StateService = require(script.Parent.StateService)
    StateService:BroadcastPlayerDataUpdate(player)
    
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
    local profile = DataService:GetPlayerProfile(player)
    if not profile then
        return false
    end
    
    local processingPets = profile.Data.ProcessingPets or {}
    if #processingPets == 0 then
        return false -- No more pets to process
    end
    
    -- Process up to one pet per tube
    local petsProcessed = 0
    local maxProcessThisRound = math.min(#ownedTubes, #processingPets)
    
    for i = 1, maxProcessThisRound do
        local pet = processingPets[1] -- Always take first pet
        local tubeNumber = ownedTubes[i]
        
        -- Calculate pet value (BaseValue * VariationMultiplier)
        local petValue = self:CalculatePetValue(pet)
        
        -- Apply gamepass multipliers
        local finalValue = self:ApplyGamepassMultipliers(player, petValue, "Money")
        
        -- Add money to player
        DataService:UpdatePlayerResources(player, "Money", finalValue)
        
        -- Create visual heaven effect
        self:CreateHeavenEffect(player, pet, tubeNumber)
        
        -- Remove pet from ProcessingPets
        table.remove(processingPets, 1)
        
        petsProcessed = petsProcessed + 1
    end
    
    -- Update ProcessingPets
    profile.Data.ProcessingPets = processingPets
    
    if petsProcessed > 0 then
        -- Sync data to client
        local StateService = require(script.Parent.StateService)
        StateService:BroadcastPlayerDataUpdate(player)
        
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

-- Create heaven effect (floating pet ball)
function PetService:CreateHeavenEffect(player, pet, tubeNumber)
    -- Get player's area
    local AreaService = require(script.Parent.AreaService)
    local assignedAreaNumber = AreaService:GetPlayerAssignedArea(player)
    
    if not assignedAreaNumber then
        return
    end
    
    local playerAreas = game.Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then
        return
    end
    
    local area = playerAreas:FindFirstChild("PlayerArea" .. assignedAreaNumber)
    if not area then
        return
    end
    
    -- Find the tube and its base
    local tubesFolder = area:FindFirstChild("Tubes")
    if not tubesFolder then
        return
    end
    
    local innerTubesFolder = tubesFolder:FindFirstChild("Tubes")
    if not innerTubesFolder then
        return
    end
    
    local tube = innerTubesFolder:FindFirstChild("Tube" .. tubeNumber)
    if not tube then
        print("PetService: Tube" .. tubeNumber .. " not found in", innerTubesFolder.Name)
        return
    end
    
    print("PetService: Found tube:", tube.Name, "at position:", tube:GetPivot().Position)
    
    local tubeBase = tube:FindFirstChild("TubeBase")
    if not tubeBase then
        print("PetService: TubeBase not found in", tube.Name)
        return
    end
    
    print("PetService: Creating heaven effect at tube base position:", tubeBase.Position)
    
    -- Create floating pet ball
    local petBall = Instance.new("Part")
    petBall.Name = "HeavenPetBall"
    petBall.Shape = Enum.PartType.Ball
    petBall.Size = Vector3.new(3, 3, 3) -- Larger for better visibility
    petBall.Material = Enum.Material.Neon
    petBall.CanCollide = false
    petBall.Anchored = true
    petBall.Transparency = 0 -- Completely visible
    
    -- Color by rarity
    local PetConstants = require(ReplicatedStorage.constants.PetConstants)
    local rarityColor = PetConstants.getRarityColor(pet.Rarity or "Common")
    petBall.Color = rarityColor
    
    -- Position at tube base (higher up for visibility)
    local startPosition = tubeBase.Position + Vector3.new(0, 10, 0) -- Much higher
    petBall.Position = startPosition
    petBall.Parent = game.Workspace -- Parent to workspace for maximum visibility
    
    
    -- Wait a moment so the ball is visible before starting animation
    wait(0.5)
    
    -- Animate floating up to heaven (slower and longer)
    local TweenService = game:GetService("TweenService")
    local endPosition = startPosition + Vector3.new(0, 100, 0) -- Float up 100 studs
    local floatTween = TweenService:Create(petBall,
        TweenInfo.new(2.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), -- 2.5 seconds, 2x faster again
        {
            Position = endPosition -- Float higher, keep size and transparency the same
        }
    )
    
    floatTween:Play()
    
    -- After animation, wait a bit then fade out
    floatTween.Completed:Connect(function()
        -- Fade out over 1 second
        local fadeOut = TweenService:Create(petBall,
            TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Transparency = 1,
                Size = Vector3.new(1, 1, 1)
            }
        )
        fadeOut:Play()
        
        -- Destroy after fade completes
        fadeOut.Completed:Connect(function()
            petBall:Destroy()
        end)
    end)
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
        return baseValue
    end
    
    local multiplier = 1
    local gamepasses = {}
    
    -- Convert OwnedGamepasses array to lookup table
    for _, gamepassName in pairs(playerData.OwnedGamepasses or {}) do
        gamepasses[gamepassName] = true
    end
    
    -- Apply multipliers based on reward type
    if rewardType == "Money" then
        -- Check for 2x Money gamepass
        if gamepasses.TwoXMoney then
            multiplier = multiplier * 2
        end
        
        -- Check for VIP gamepass (includes all benefits)
        if gamepasses.VIP then
            multiplier = multiplier * 2
        end
    elseif rewardType == "Diamonds" then
        -- Check for 2x Diamonds gamepass
        if gamepasses.TwoXDiamonds then
            multiplier = multiplier * 2
        end
        
        -- Check for VIP gamepass (includes all benefits)
        if gamepasses.VIP then
            multiplier = multiplier * 2
        end
    end
    
    return math.floor(baseValue * multiplier)
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