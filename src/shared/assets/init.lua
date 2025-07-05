-- Asset System Initialization
-- This module provides backward compatibility for the old assets.luau system
-- while redirecting to the new modular AssetManager

print("Assets init.lua: Starting asset system initialization...")

local AssetManager = require(script.AssetManager)

-- Enhanced debug logging
print("Assets init.lua: AssetManager loaded, checking status...")
local status = AssetManager.getLoadingStatus()
print(string.format("Assets init.lua: Loaded %d assets in %.3fs", 
    status.assetCount, status.loadTime or 0))

-- Add debug function to assets table for troubleshooting
local assets = AssetManager.assets
assets._debug = {
    getStatus = AssetManager.getLoadingStatus,
    printStatus = AssetManager.printLoadingStatus,
    getSafeAsset = AssetManager.getSafeAsset,
    manager = AssetManager
}

-- Log a few sample assets to verify loading
local sampleAssets = {
    "vector-icon-pack-2/General/Pet 2/Pet 2 Outline 256.png",
    "vector-icon-pack-2/General/Shop/Shop Outline 256.png",
    "vector-icon-pack-2/Currency/Gem/Gem Blue Outline 256.png",
    "vector-icon-pack-2/UI/Music/Music Outline 256.png"
}

print("Assets init.lua: Verifying sample assets...")
for _, assetPath in ipairs(sampleAssets) do
    local assetId = assets[assetPath]
    if assetId then
        print(string.format("✓ Found: %s = %s", assetPath, assetId))
    else
        warn(string.format("✗ Missing: %s", assetPath))
    end
end

print("Assets init.lua: Asset system initialization complete!")

-- For backward compatibility, return the assets table directly
-- This allows existing code like `require(ReplicatedStorage.assets)` to work unchanged
return assets