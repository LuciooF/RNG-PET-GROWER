-- Safe Asset Loader Utility
-- Provides safe asset loading with fallbacks and loading state management
-- Use this in UI components to prevent invisible assets due to loading race conditions

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SafeAssetLoader = {}

-- Cache for loaded assets and loading states
local assetCache = {}
local loadingStates = {}

-- Fallback/placeholder asset IDs for different types
local FALLBACKS = {
    icon = "rbxasset://textures/ui/GuiImagePlaceholder.png",
    button = "rbxasset://textures/ui/GuiImagePlaceholder.png", 
    currency = "rbxasset://textures/ui/GuiImagePlaceholder.png",
    default = "rbxasset://textures/ui/GuiImagePlaceholder.png"
}

-- Get asset with proper fallback and loading state tracking
function SafeAssetLoader.getAsset(assetPath, assetType, timeout)
    timeout = timeout or 3 -- 3 second timeout
    assetType = assetType or "default"
    
    -- Return cached asset if available
    if assetCache[assetPath] then
        return assetCache[assetPath]
    end
    
    -- Check if already loading
    if loadingStates[assetPath] then
        return FALLBACKS[assetType] -- Return fallback while loading
    end
    
    -- Mark as loading
    loadingStates[assetPath] = true
    
    -- Async load the asset
    task.spawn(function()
        local startTime = tick()
        local assets = nil
        
        -- Wait for asset system to be ready
        while not assets and (tick() - startTime) < timeout do
            local success, result = pcall(function()
                return require(ReplicatedStorage.assets)
            end)
            
            if success and result then
                assets = result
                break
            end
            
            task.wait(0.1)
        end
        
        if assets then
            local assetId = assets[assetPath]
            if assetId then
                assetCache[assetPath] = assetId
                print(string.format("SafeAssetLoader: Loaded asset %s = %s", assetPath, assetId))
            else
                warn(string.format("SafeAssetLoader: Asset not found: %s", assetPath))
                assetCache[assetPath] = FALLBACKS[assetType]
            end
        else
            warn(string.format("SafeAssetLoader: Timeout loading asset system for: %s", assetPath))
            assetCache[assetPath] = FALLBACKS[assetType]
        end
        
        loadingStates[assetPath] = false
    end)
    
    -- Return fallback immediately
    return FALLBACKS[assetType]
end

-- Batch load multiple assets
function SafeAssetLoader.batchLoad(assetPaths, assetType, timeout)
    local results = {}
    for i, path in ipairs(assetPaths) do
        results[i] = SafeAssetLoader.getAsset(path, assetType, timeout)
    end
    return results
end

-- Pre-load critical UI assets
function SafeAssetLoader.preloadCriticalAssets()
    local criticalAssets = {
        "vector-icon-pack-2/General/Pet 2/Pet 2 Outline 256.png",
        "vector-icon-pack-2/General/Shop/Shop Outline 256.png",
        "vector-icon-pack-2/General/Rebirth/Rebirth Outline 256.png",
        "vector-icon-pack-2/Currency/Gem/Gem Blue Outline 256.png",
        "vector-icon-pack-2/Currency/Cash/Cash Outline 256.png",
        "vector-icon-pack-2/UI/X Button/X Button Outline 256.png",
        "vector-icon-pack-2/UI/Music/Music Outline 256.png",
        "vector-icon-pack-2/UI/Music Off/Music Off Outline 256.png"
    }
    
    print("SafeAssetLoader: Pre-loading critical UI assets...")
    for _, assetPath in ipairs(criticalAssets) do
        SafeAssetLoader.getAsset(assetPath, "icon", 5)
    end
end

-- Check if asset is loaded
function SafeAssetLoader.isAssetLoaded(assetPath)
    return assetCache[assetPath] ~= nil and assetCache[assetPath] ~= FALLBACKS.default
end

-- Get cache stats for debugging
function SafeAssetLoader.getCacheStats()
    local loaded = 0
    local loading = 0
    
    for _ in pairs(assetCache) do
        loaded = loaded + 1
    end
    
    for _ in pairs(loadingStates) do
        loading = loading + 1
    end
    
    return {
        cached = loaded,
        loading = loading,
        cache = assetCache,
        loadingStates = loadingStates
    }
end

-- Clear cache (for debugging)
function SafeAssetLoader.clearCache()
    assetCache = {}
    loadingStates = {}
    print("SafeAssetLoader: Cache cleared")
end

return SafeAssetLoader