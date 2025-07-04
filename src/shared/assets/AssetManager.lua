-- Asset Manager
-- Centralized asset management system that consolidates all asset modules
-- Replaces the monolithic assets.luau file with a modular approach

local AssetManager = {}

-- Import all asset modules
local FoodAssets = require(script.Parent.FoodAssets)
local IconAssets = require(script.Parent.IconAssets)
local PetAssets = require(script.Parent.PetAssets)

-- Consolidated asset table (maintains backward compatibility)
local assets = {}

-- Merge all asset modules into the main table
local function mergeAssets(sourceTable)
    for key, value in pairs(sourceTable) do
        assets[key] = value
    end
end

-- Build the consolidated asset table
mergeAssets(FoodAssets)
mergeAssets(IconAssets)
mergeAssets(PetAssets)

-- Backward compatibility: expose assets table directly
AssetManager.assets = assets

-- Modern API: category-specific getters
function AssetManager.getFoodAsset(path)
    return FoodAssets[path]
end

function AssetManager.getIconAsset(path)
    return IconAssets[path]
end

function AssetManager.getPetAsset(path)
    return PetAssets[path]
end

-- Generic getter with fallback
function AssetManager.getAsset(path, fallback)
    return assets[path] or fallback
end

-- Utility functions
function AssetManager.hasAsset(path)
    return assets[path] ~= nil
end

function AssetManager.getAllAssets()
    return assets
end

function AssetManager.getAssetsByCategory(category)
    local categoryAssets = {}
    local categoryPrefix = category:lower()
    
    for path, assetId in pairs(assets) do
        if path:lower():find(categoryPrefix) then
            categoryAssets[path] = assetId
        end
    end
    
    return categoryAssets
end

-- Asset validation
function AssetManager.validateAssetId(assetId)
    return type(assetId) == "string" and assetId:match("^rbxassetid://")
end

-- Debug functions
function AssetManager.getAssetCount()
    local count = 0
    for _ in pairs(assets) do
        count = count + 1
    end
    return count
end

function AssetManager.getCategoryStats()
    local stats = {
        food = 0,
        icon = 0,
        pet = 0,
        other = 0
    }
    
    for path, _ in pairs(assets) do
        if path:find("vector-food-pack") then
            stats.food = stats.food + 1
        elseif path:find("vector-icon-pack") then
            stats.icon = stats.icon + 1
        elseif path:find("Pets") or path:find("pet") then
            stats.pet = stats.pet + 1
        else
            stats.other = stats.other + 1
        end
    end
    
    return stats
end

-- For backward compatibility, also expose the table directly
-- This allows existing code like `require(ReplicatedStorage.assets)` to continue working
setmetatable(AssetManager, {
    __index = function(_, key)
        return assets[key]
    end,
    __pairs = function()
        return pairs(assets)
    end,
    __len = function()
        return #assets
    end
})

return AssetManager