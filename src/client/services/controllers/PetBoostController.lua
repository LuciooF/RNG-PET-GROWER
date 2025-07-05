-- Pet Boost Controller
-- Business logic for pet boost calculations and display data
-- Extracted from PetBoostPanel.lua to follow modular architecture

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetConfig = require(ReplicatedStorage.Shared.config.PetConfig)
local PetBoostCalculator = require(ReplicatedStorage.utils.PetBoostCalculator)
local PetConstants = require(ReplicatedStorage.constants.PetConstants)

local PetBoostController = {}

-- Process assigned pets and generate boost data for display (with optional friends boost)
function PetBoostController.generateBoostData(assignedPets, friendsBoost)
    local petBoosts = {}
    local totalMoneyMultiplier = 1.0
    friendsBoost = friendsBoost or 0
    
    -- Use PetBoostCalculator for consistent calculations including friends
    local calculatedBoosts = PetBoostCalculator.generatePetBoostData(assignedPets, PetConfig)
    totalMoneyMultiplier = PetBoostCalculator.calculateTotalMoneyMultiplierWithFriends(assignedPets, PetConfig, friendsBoost)
    
    -- Convert calculated data to display format
    for i, boostData in ipairs(calculatedBoosts) do
        local displayBoost = {
            name = boostData.pet.name or "Unknown Pet",
            emoji = PetConstants.getPetEmoji(boostData.pet.name),
            pet = boostData.pet,
            petConfig = boostData.petConfig,
            aura = boostData.aura,
            auraData = boostData.auraData,
            size = boostData.size,
            sizeData = boostData.sizeData,
            description = boostData.description,
            category = boostData.category,
            effect = boostData.effect,
            effects = boostData.effects,
            color = boostData.color,
            duration = boostData.duration
        }
        
        table.insert(petBoosts, displayBoost)
    end
    
    -- Add friends boost if it exists
    if friendsBoost > 0 then
        local friendsBoostData = PetBoostCalculator.createFriendsBoostData(friendsBoost)
        if friendsBoostData then
            table.insert(petBoosts, friendsBoostData)
        end
    end
    
    return petBoosts, totalMoneyMultiplier
end

-- Calculate grid dimensions for boost cards display
function PetBoostController.calculateBoostGridDimensions(petBoosts, screenSize, panelWidth)
    local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
    
    local minCardWidth = ScreenUtils.getProportionalSize(screenSize, 250)
    local cardsPerRow = math.max(1, math.floor((panelWidth - 120) / (minCardWidth + 20)))
    local cardWidth = (panelWidth - 120) / cardsPerRow - 20
    local cardHeight = ScreenUtils.getProportionalSize(screenSize, 280)
    local totalRows = math.ceil(#petBoosts / cardsPerRow)
    local totalHeight = ((totalRows * cardHeight) + ((totalRows - 1) * 20) + 40) * 1.3
    
    return {
        cardsPerRow = cardsPerRow,
        cardWidth = cardWidth,
        cardHeight = cardHeight,
        totalRows = totalRows,
        totalHeight = totalHeight
    }
end

-- Get summary text for assigned pets
function PetBoostController.getSummaryText(totalMoneyMultiplier, totalBoosts, maxSlots)
    maxSlots = maxSlots or 3
    return string.format("🚀 Total Pet Boost: +%.0f%% | 🐾 Assigned Pets: %d/%d", 
        (totalMoneyMultiplier - 1) * 100, totalBoosts, maxSlots)
end

-- Check if boost panel should be visible (has assigned pets)
function PetBoostController.shouldShowPanel(assignedPets)
    return #assignedPets > 0
end

-- Format boost percentage for button display
function PetBoostController.formatBoostPercentage(totalMoneyMultiplier)
    return PetBoostCalculator.formatBoostPercentage(totalMoneyMultiplier)
end

return PetBoostController