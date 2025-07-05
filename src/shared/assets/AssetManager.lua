-- Asset Manager
-- Centralized asset management system that consolidates all asset modules
-- Replaces the monolithic assets.luau file with a modular approach

local AssetManager = {}

-- Asset loading status tracking
local loadingStatus = {
    initialized = false,
    foodLoaded = false,
    iconLoaded = false,
    petLoaded = false,
    startTime = tick()
}

-- Safe module loading with error handling
local function safeRequire(module, moduleName)
    local success, result = pcall(function()
        return require(module)
    end)
    
    if success then
        print(string.format("AssetManager: Successfully loaded %s (%d assets)", moduleName, result and type(result) == "table" and #result or "unknown"))
        return result
    else
        warn(string.format("AssetManager: Failed to load %s - %s", moduleName, tostring(result)))
        return {}
    end
end

-- Import all asset modules with error handling
print("AssetManager: Starting asset loading at", tick())
local FoodAssets = safeRequire(script.Parent.FoodAssets, "FoodAssets")
loadingStatus.foodLoaded = true

local IconAssets = safeRequire(script.Parent.IconAssets, "IconAssets") 
loadingStatus.iconLoaded = true

local PetAssets = safeRequire(script.Parent.PetAssets, "PetAssets")
loadingStatus.petLoaded = true

-- Consolidated asset table (maintains backward compatibility)
local assets = {}

-- Merge all asset modules into the main table with logging
local function mergeAssets(sourceTable, sourceName)
    local count = 0
    for key, value in pairs(sourceTable) do
        assets[key] = value
        count = count + 1
    end
    print(string.format("AssetManager: Merged %d assets from %s", count, sourceName))
    return count
end

-- Build the consolidated asset table
print("AssetManager: Building consolidated asset table...")
local foodCount = mergeAssets(FoodAssets, "FoodAssets")
local iconCount = mergeAssets(IconAssets, "IconAssets") 
local petCount = mergeAssets(PetAssets, "PetAssets")

local totalLoadTime = tick() - loadingStatus.startTime
loadingStatus.initialized = true

print(string.format("AssetManager: Initialization complete! Loaded %d total assets in %.3f seconds", 
    foodCount + iconCount + petCount, totalLoadTime))
print(string.format("AssetManager: Breakdown - Food: %d, Icons: %d, Pets: %d", 
    foodCount, iconCount, petCount))

-- Backward compatibility: expose assets table directly
AssetManager.assets = assets

-- Modern API: category-specific getters with logging
function AssetManager.getFoodAsset(path)
    local asset = FoodAssets[path]
    if not asset then
        warn(string.format("AssetManager: Food asset not found: %s", tostring(path)))
    end
    return asset
end

function AssetManager.getIconAsset(path)
    local asset = IconAssets[path]
    if not asset then
        warn(string.format("AssetManager: Icon asset not found: %s", tostring(path)))
    end
    return asset
end

function AssetManager.getPetAsset(path)
    local asset = PetAssets[path]
    if not asset then
        warn(string.format("AssetManager: Pet asset not found: %s", tostring(path)))
    end
    return asset
end

-- Generic getter with fallback and logging
function AssetManager.getAsset(path, fallback)
    if not loadingStatus.initialized then
        warn("AssetManager: Attempting to get asset before initialization complete:", path)
    end
    
    local asset = assets[path]
    if not asset then
        warn(string.format("AssetManager: Asset not found: %s (using fallback: %s)", 
            tostring(path), tostring(fallback)))
        return fallback
    end
    return asset
end

-- Safe asset getter that waits for initialization
function AssetManager.getSafeAsset(path, fallback, timeout)
    timeout = timeout or 5 -- 5 second timeout
    local startTime = tick()
    
    -- Wait for initialization if needed
    while not loadingStatus.initialized and (tick() - startTime) < timeout do
        wait(0.1)
    end
    
    if not loadingStatus.initialized then
        warn(string.format("AssetManager: Timeout waiting for initialization when requesting: %s", tostring(path)))
        return fallback
    end
    
    return AssetManager.getAsset(path, fallback)
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

function AssetManager.getLoadingStatus()
    return {
        initialized = loadingStatus.initialized,
        foodLoaded = loadingStatus.foodLoaded,
        iconLoaded = loadingStatus.iconLoaded,
        petLoaded = loadingStatus.petLoaded,
        startTime = loadingStatus.startTime,
        loadTime = loadingStatus.initialized and (tick() - loadingStatus.startTime) or nil,
        assetCount = AssetManager.getAssetCount()
    }
end

function AssetManager.printLoadingStatus()
    local status = AssetManager.getLoadingStatus()
    print("=== AssetManager Loading Status ===")
    print("Initialized:", status.initialized)
    print("Food Loaded:", status.foodLoaded) 
    print("Icon Loaded:", status.iconLoaded)
    print("Pet Loaded:", status.petLoaded)
    print("Asset Count:", status.assetCount)
    print("Load Time:", status.loadTime and string.format("%.3fs", status.loadTime) or "N/A")
    print("==================================")
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