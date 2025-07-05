-- Pet Configuration Module - Modular Architecture
-- Follows CLAUDE.md architectural patterns for maintainable config management

local PetConfig = {}

-- Import individual rarity tier modules
local RarityTiers = {
    require(script.BasicTier),      -- Rarity 1-5
    require(script.CommonTier),     -- Rarity 6-10
    require(script.EpicTier),       -- Rarity 11-15
    require(script.LegendaryTier),  -- Rarity 16-20
}

-- Import systems
local SizeSystem = require(script.SizeSystem)
local AuraSystem = require(script.AuraSystem)

-- Consolidate all pets from tiers
PetConfig.PETS = {}
for _, tier in ipairs(RarityTiers) do
    for petId, petData in pairs(tier) do
        PetConfig.PETS[petId] = petData
    end
end

-- Import systems
PetConfig.SIZES = SizeSystem.SIZES
PetConfig.AURAS = AuraSystem.AURAS

-- Import business logic functions
local PetConfigLogic = require(script.PetConfigLogic)
for methodName, method in pairs(PetConfigLogic) do
    PetConfig[methodName] = method
end

return PetConfig