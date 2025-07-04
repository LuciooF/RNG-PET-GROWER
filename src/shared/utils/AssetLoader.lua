-- Asset Loader Utility
-- Centralized asset loading to eliminate code duplication across 7+ files
-- Replaces repeated asset folder finding logic

local AssetLoader = {}

-- Cached reference to assets folder for performance
local assetsFolder = nil

-- Initialize and cache the assets folder reference
local function getAssetsFolder()
    if assetsFolder then
        return assetsFolder
    end
    
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    -- Find the assets Folder (not ModuleScript)
    for _, child in pairs(ReplicatedStorage:GetChildren()) do
        if child.Name == "assets" and child.ClassName == "Folder" then
            assetsFolder = child
            return assetsFolder
        end
    end
    
    warn("AssetLoader: Assets folder not found in ReplicatedStorage")
    return nil
end

-- Load a pet model from asset path using PetModelFactory (consolidated logic)
function AssetLoader.loadPetModel(assetPath)
    if not assetPath then
        return nil
    end
    
    -- Try to get PetModelFactory from multiple possible locations
    local PetModelFactory = nil
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    -- Try different possible paths for PetModelFactory
    local possiblePaths = {
        "client.services.controllers.PetModelFactory",
        "Shared.controllers.PetModelFactory"
    }
    
    for _, path in ipairs(possiblePaths) do
        local success, factory = pcall(function()
            local current = ReplicatedStorage
            for part in string.gmatch(path, "[^.]+") do
                current = current:FindFirstChild(part)
                if not current then
                    return nil
                end
            end
            return require(current)
        end)
        
        if success and factory then
            PetModelFactory = factory
            break
        end
    end
    
    if PetModelFactory then
        -- Create a fake petData object with the assetPath for PetModelFactory
        local petData = {
            assetPath = assetPath,
            name = "UIDisplay"
        }
        -- Use position of zero since this is for UI display
        return PetModelFactory.createPetModel(petData, Vector3.new(0, 0, 0))
    else
        -- Fallback to original logic if PetModelFactory not found
        local assets = getAssetsFolder()
        if not assets then
            return nil
        end
        
        local pathParts = string.split(assetPath, "/")
        local currentFolder = assets
        
        -- Navigate through the path
        for _, pathPart in ipairs(pathParts) do
            currentFolder = currentFolder:FindFirstChild(pathPart)
            if not currentFolder then
                warn("AssetLoader: Asset path not found:", assetPath)
                return nil
            end
        end
        
        if currentFolder and currentFolder:IsA("Model") then
            return currentFolder:Clone()
        end
        
        warn("AssetLoader: Asset is not a Model:", assetPath)
        return nil
    end
end

-- Load an icon/image asset
function AssetLoader.loadIcon(iconPath)
    local assets = getAssetsFolder()
    if not assets or not iconPath then
        return ""
    end
    
    local pathParts = string.split(iconPath, "/")
    local currentFolder = assets
    
    -- Navigate through the path
    for _, pathPart in ipairs(pathParts) do
        currentFolder = currentFolder:FindFirstChild(pathPart)
        if not currentFolder then
            return "" -- Return empty string for missing icons
        end
    end
    
    return currentFolder
end

-- Get the assets folder reference (for direct access if needed)
function AssetLoader.getAssetsFolder()
    return getAssetsFolder()
end

-- Clear cache (for testing or if assets folder changes)
function AssetLoader.clearCache()
    assetsFolder = nil
end

return AssetLoader