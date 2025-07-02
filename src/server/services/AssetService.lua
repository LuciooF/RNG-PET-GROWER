local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local AssetService = {}
AssetService.__index = AssetService

-- Cache for loaded assets to avoid reloading
local assetCache = {}
local cacheFolder = nil

function AssetService:Initialize()
    
    -- Create cache folder in ReplicatedStorage for client access
    cacheFolder = Instance.new("Folder")
    cacheFolder.Name = "AssetCache"
    cacheFolder.Parent = ReplicatedStorage
    
end

function AssetService:LoadAsset(assetId)
    
    -- Check cache first
    local cacheKey = "Asset_" .. tostring(assetId)
    if assetCache[cacheKey] then
        return assetCache[cacheKey]
    end
    
    -- Check if asset is already in ReplicatedStorage cache
    local cachedAsset = cacheFolder:FindFirstChild(cacheKey)
    if cachedAsset then
        assetCache[cacheKey] = cachedAsset
        return cachedAsset
    end
    
    -- Load asset using InsertService (server-side)
    local success, result = pcall(function()
        return game:GetService("InsertService"):LoadAsset(assetId)
    end)
    
    if success and result then
        
        -- Find the model in the loaded asset
        local model = result:FindFirstChildOfClass("Model")
        if model then
            
            -- Clone and prepare the model for caching
            local cachedModel = model:Clone()
            cachedModel.Name = cacheKey
            
            -- Make sure all parts are properly configured for cloning
            for _, descendant in pairs(cachedModel:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    -- Don't set anchored/CanCollide here - let the client handle that
                    -- Just make sure the model is ready for cloning
                end
            end
            
            -- Store in ReplicatedStorage for client access
            cachedModel.Parent = cacheFolder
            
            -- Store in memory cache
            assetCache[cacheKey] = cachedModel
            
            -- Clean up original
            result:Destroy()
            
            return cachedModel
        else
            result:Destroy()
        end
    else
    end
    
    return nil
end

function AssetService:GetCachedAsset(assetId)
    local cacheKey = "Asset_" .. tostring(assetId)
    
    -- Check memory cache
    if assetCache[cacheKey] then
        return assetCache[cacheKey]
    end
    
    -- Check ReplicatedStorage cache
    local cachedAsset = cacheFolder:FindFirstChild(cacheKey)
    if cachedAsset then
        assetCache[cacheKey] = cachedAsset
        return cachedAsset
    end
    
    return nil
end

function AssetService:PreloadAssets(assetIds)
    
    for _, assetId in ipairs(assetIds) do
        spawn(function()
            self:LoadAsset(assetId)
        end)
    end
end

return AssetService