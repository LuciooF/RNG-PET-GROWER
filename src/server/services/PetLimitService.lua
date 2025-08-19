-- PetLimitService - Handles pet limit expansion dev product purchases
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local DataService = require(script.Parent.DataService)

local PetLimitService = {}
PetLimitService.__index = PetLimitService

-- Configuration
local PET_LIMIT_DEV_PRODUCT_ID = 3375701119
local PET_LIMIT_INCREASE = 25
local BASE_PET_LIMIT = 50

function PetLimitService:Initialize()
    -- Create RemoteEvent for client purchases
    local purchaseRemote = Instance.new("RemoteEvent")
    purchaseRemote.Name = "PetLimitPurchase"
    purchaseRemote.Parent = ReplicatedStorage
    
    -- Create RemoteFunction to get current limit
    local getLimitRemote = Instance.new("RemoteFunction")
    getLimitRemote.Name = "GetPetLimit"
    getLimitRemote.Parent = ReplicatedStorage
    
    -- Create RemoteEvent for purchase success notifications
    local successRemote = Instance.new("RemoteEvent")
    successRemote.Name = "PetLimitPurchaseSuccess"
    successRemote.Parent = ReplicatedStorage
    
    -- Handle purchase requests from clients
    purchaseRemote.OnServerEvent:Connect(function(player)
        self:HandlePurchaseRequest(player)
    end)
    
    -- Handle get limit requests
    getLimitRemote.OnServerInvoke = function(player)
        return self:GetPlayerPetLimit(player)
    end
    
    -- PetLimitService initialized
end

-- Handle purchase request from client
function PetLimitService:HandlePurchaseRequest(player)
    if not player then
        return
    end
    
    -- Use MarketplaceService to prompt purchase
    local success, errorMessage = pcall(function()
        MarketplaceService:PromptProductPurchase(player, PET_LIMIT_DEV_PRODUCT_ID)
    end)
    
    if not success then
        warn("PetLimitService: Failed to prompt purchase for player", player.Name, ":", errorMessage)
    end
end

-- Process dev product purchases (called from Main.server.lua)
function PetLimitService:ProcessReceipt(receiptInfo)
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    
    -- Check if this is a pet limit purchase
    if receiptInfo.ProductId ~= PET_LIMIT_DEV_PRODUCT_ID then
        -- Not a pet limit purchase, let other services handle it
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    
    -- Add pet limit increase to player's data
    local success = self:IncreasePetLimit(player)
    
    if success then
        -- Track robux spending for leaderboard (dynamic price)
        local function getDevProductPrice(productId)
            local success, productInfo = pcall(function()
                return MarketplaceService:GetProductInfo(productId, Enum.InfoType.Product)
            end)
            
            if success and productInfo then
                return productInfo.PriceInRobux or 0
            else
                warn("Failed to get price for dev product:", productId)
                return 0
            end
        end
        
        local price = getDevProductPrice(receiptInfo.ProductId)
        DataService:AddRobuxSpent(player, price)
        
        -- Send success notification to client
        local successRemote = ReplicatedStorage:FindFirstChild("PetLimitPurchaseSuccess")
        if successRemote then
            local newLimit = self:GetPlayerPetLimit(player)
            successRemote:FireClient(player, newLimit)
        end
        
        return Enum.ProductPurchaseDecision.PurchaseGranted
    else
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
end

-- Increase pet limit for a player
function PetLimitService:IncreasePetLimit(player)
    local profile = DataService:GetPlayerProfile(player)
    if not profile then
        return false
    end
    
    -- Initialize pet limit purchases if it doesn't exist
    if not profile.Data.PetLimitPurchases then
        profile.Data.PetLimitPurchases = 0
    end
    
    -- Increase the count
    profile.Data.PetLimitPurchases = profile.Data.PetLimitPurchases + 1
    
    -- Sync data to client
    DataService:SyncPlayerDataToClient(player)
    
    print("PetLimitService: Increased pet limit for", player.Name, "to", self:GetPlayerPetLimit(player))
    return true
end

-- Get current pet limit for a player
function PetLimitService:GetPlayerPetLimit(player)
    local profile = DataService:GetPlayerProfile(player)
    if not profile then
        return BASE_PET_LIMIT
    end
    
    local purchases = profile.Data.PetLimitPurchases or 0
    return BASE_PET_LIMIT + (purchases * PET_LIMIT_INCREASE)
end

-- Get how many times a player has purchased the limit increase
function PetLimitService:GetPlayerPetLimitPurchases(player)
    local profile = DataService:GetPlayerProfile(player)
    if not profile then
        return 0
    end
    
    return profile.Data.PetLimitPurchases or 0
end

return PetLimitService