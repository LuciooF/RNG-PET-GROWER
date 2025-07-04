-- Asset System Initialization
-- This module provides backward compatibility for the old assets.luau system
-- while redirecting to the new modular AssetManager

local AssetManager = require(script.AssetManager)

-- For backward compatibility, return the assets table directly
-- This allows existing code like `require(ReplicatedStorage.assets)` to work unchanged
return AssetManager.assets