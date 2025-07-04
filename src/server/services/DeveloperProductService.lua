-- Developer Product Service  
-- Handles developer product purchases (consumables like pets, currency, boosts)
-- Integrates with MarketplaceService for purchase processing

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local DeveloperProductConfig = require(ReplicatedStorage.Shared.config.DeveloperProductConfig)
local DataService = require(script.Parent.DataService)

local DeveloperProductService = {}
DeveloperProductService.__index = DeveloperProductService

-- Purchase receipt cache to prevent duplicate processing
local processedReceipts = {}
local RECEIPT_CACHE_TIME = 3600 -- 1 hour

-- Initialize service
function DeveloperProductService:Initialize()
    print("DeveloperProductService: Initializing...")
    
    -- Set up MarketplaceService callback
    MarketplaceService.ProcessReceipt = function(receiptInfo)
        return self:ProcessReceipt(receiptInfo)
    end
    
    -- Clean up old receipts periodically
    task.spawn(function()
        while true do
            task.wait(RECEIPT_CACHE_TIME)
            self:CleanupReceiptCache()
        end
    end)
    
    print("DeveloperProductService: Initialized successfully")
    return true
end

-- Process purchase receipt from Roblox
function DeveloperProductService:ProcessReceipt(receiptInfo)
    print(string.format("DeveloperProductService: Processing receipt for product %d (player %d)", 
        receiptInfo.ProductId, receiptInfo.PlayerId))
    
    -- Check for duplicate receipt
    local receiptKey = string.format("%d_%s", receiptInfo.PlayerId, receiptInfo.PurchaseId)
    if processedReceipts[receiptKey] then
        print("DeveloperProductService: Duplicate receipt detected, returning PurchaseGranted")
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end
    
    -- Get player
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then
        warn("DeveloperProductService: Player not found for receipt")
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    
    -- Get product data
    local productData = DeveloperProductConfig:GetProductData(receiptInfo.ProductId)
    if not productData then
        warn(string.format("DeveloperProductService: Unknown product ID %d", receiptInfo.ProductId))
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    
    -- Process the purchase based on product type
    local success = false
    
    if productData.type == DeveloperProductConfig.TYPES.PET then
        success = self:ProcessPetPurchase(player, productData, receiptInfo)
    elseif productData.type == DeveloperProductConfig.TYPES.CURRENCY then
        success = self:ProcessCurrencyPurchase(player, productData, receiptInfo)
    elseif productData.type == DeveloperProductConfig.TYPES.BOOST then
        success = self:ProcessBoostPurchase(player, productData, receiptInfo)
    elseif productData.type == DeveloperProductConfig.TYPES.SPECIAL then
        success = self:ProcessSpecialPurchase(player, productData, receiptInfo)
    else
        warn(string.format("DeveloperProductService: Unknown product type %s", productData.type))
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    
    if success then
        -- Mark receipt as processed
        processedReceipts[receiptKey] = {
            timestamp = tick(),
            productId = receiptInfo.ProductId,
            playerId = receiptInfo.PlayerId
        }
        
        -- Notify client of successful purchase
        self:NotifyClientPurchase(player, productData, receiptInfo)
        
        print(string.format("DeveloperProductService: Successfully processed %s for %s", 
            productData.name, player.Name))
        
        return Enum.ProductPurchaseDecision.PurchaseGranted
    else
        warn(string.format("DeveloperProductService: Failed to process %s for %s", 
            productData.name, player.Name))
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
end

-- Process pet purchase (Rainbow rarity pets)
function DeveloperProductService:ProcessPetPurchase(player, productData, receiptInfo)
    print(string.format("DeveloperProductService: Processing pet purchase %s for %s", 
        productData.name, player.Name))
    
    if not productData.petData then
        warn("DeveloperProductService: No pet data found for pet product")
        return false
    end
    
    -- Create pet with premium rainbow aura
    local newPet = {
        id = 999999, -- Special ID for developer product pets (will need to add to PetConfig)
        uniqueId = game:GetService("HttpService"):GenerateGUID(false),
        name = productData.petData.name,
        rarity = 21, -- Rainbow rarity
        value = productData.petData.value,
        description = productData.petData.description,
        isFlyingPet = productData.petData.isFlyingPet,
        baseBoost = productData.petData.baseBoost,
        assetPath = productData.petData.assetPath,
        aura = "premium_rainbow", -- Special premium rainbow aura
        size = 5, -- Always maximum size (Gigantic)
        purchaseTime = tick(),
        purchaseId = receiptInfo.PurchaseId,
        isDeveloperProduct = true,
        specialEffects = productData.petData.specialEffects or {}
    }
    
    -- Add pet to player's collection
    local success = DataService:AddPet(player, newPet)
    if not success then
        warn("DeveloperProductService: Failed to add developer pet to inventory")
        return false
    end
    
    -- Give bonus diamonds for purchasing premium pet
    DataService:AddDiamonds(player, 100) -- Bonus diamonds for dev product purchase
    
    return true
end

-- Process currency purchase (Diamond packs)
function DeveloperProductService:ProcessCurrencyPurchase(player, productData, receiptInfo)
    print(string.format("DeveloperProductService: Processing currency purchase %s for %s", 
        productData.name, player.Name))
    
    if not productData.rewards then
        warn("DeveloperProductService: No rewards data found for currency product")
        return false
    end
    
    -- Add diamonds
    if productData.rewards.diamonds then
        local success = DataService:AddDiamonds(player, productData.rewards.diamonds)
        if not success then
            warn("DeveloperProductService: Failed to add diamonds")
            return false
        end
    end
    
    -- Add money if specified
    if productData.rewards.money then
        local success = DataService:AddRawMoney(player, productData.rewards.money)
        if not success then
            warn("DeveloperProductService: Failed to add money")
            return false
        end
    end
    
    return true
end

-- Process boost purchase (Temporary multipliers)
function DeveloperProductService:ProcessBoostPurchase(player, productData, receiptInfo)
    print(string.format("DeveloperProductService: Processing boost purchase %s for %s", 
        productData.name, player.Name))
    
    if not productData.boost then
        warn("DeveloperProductService: No boost data found for boost product")
        return false
    end
    
    -- Create boost data
    local boostData = {
        type = productData.boost.type,
        multiplier = productData.boost.multiplier,
        startTime = tick(),
        duration = productData.boost.duration,
        endTime = tick() + productData.boost.duration,
        purchaseId = receiptInfo.PurchaseId,
        name = productData.displayName
    }
    
    -- Add boost to player's active boosts
    local success = DataService:AddBoost(player, boostData)
    if not success then
        warn("DeveloperProductService: Failed to add boost")
        return false
    end
    
    return true
end

-- Process special purchase (Instant rebirth, inventory expansion, etc.)
function DeveloperProductService:ProcessSpecialPurchase(player, productData, receiptInfo)
    print(string.format("DeveloperProductService: Processing special purchase %s for %s", 
        productData.name, player.Name))
    
    if not productData.special then
        warn("DeveloperProductService: No special data found for special product")
        return false
    end
    
    local action = productData.special.action
    
    if action == "instant_rebirth" then
        -- Grant instant rebirth
        local success = DataService:PerformRebirth(player)
        if not success then
            warn("DeveloperProductService: Failed to perform instant rebirth")
            return false
        end
        
        -- Give bonus for using instant rebirth
        DataService:AddDiamonds(player, 50)
        
    elseif action == "max_inventory" then
        -- Temporarily expand inventory (would need to implement temporary effects system)
        local playerData = DataService:GetPlayerData(player)
        if playerData then
            -- Set temporary inventory expansion (this would need to be checked in inventory cap logic)
            if not playerData.temporaryEffects then
                playerData.temporaryEffects = {}
            end
            
            playerData.temporaryEffects.expandedInventory = {
                additionalSpace = productData.special.value or 1000,
                expirationTime = tick() + (24 * 3600), -- 24 hours
                purchaseId = receiptInfo.PurchaseId
            }
            
            DataService:SetData(player, "temporaryEffects", playerData.temporaryEffects)
        end
        
    else
        warn(string.format("DeveloperProductService: Unknown special action %s", action))
        return false
    end
    
    return true
end

-- Notify client of successful purchase
function DeveloperProductService:NotifyClientPurchase(player, productData, receiptInfo)
    local remoteEvent = ReplicatedStorage:FindFirstChild("DeveloperProductPurchased")
    if remoteEvent then
        remoteEvent:FireClient(player, {
            productName = productData.name,
            displayName = productData.displayName,
            type = productData.type,
            description = productData.description,
            purchaseId = receiptInfo.PurchaseId
        })
    end
end

-- Clean up old receipt cache entries
function DeveloperProductService:CleanupReceiptCache()
    local currentTime = tick()
    local cleanedCount = 0
    
    for receiptKey, receiptData in pairs(processedReceipts) do
        if currentTime - receiptData.timestamp > RECEIPT_CACHE_TIME then
            processedReceipts[receiptKey] = nil
            cleanedCount = cleanedCount + 1
        end
    end
    
    if cleanedCount > 0 then
        print(string.format("DeveloperProductService: Cleaned up %d old receipts", cleanedCount))
    end
end

-- Prompt player to purchase developer product
function DeveloperProductService:PromptPurchase(player, productName)
    local productData = DeveloperProductConfig:GetProductByName(productName)
    if not productData then
        warn(string.format("DeveloperProductService: Unknown product %s", productName))
        return false
    end
    
    local success, errorMessage = pcall(function()
        MarketplaceService:PromptProductPurchase(player, productData.id)
    end)
    
    if not success then
        warn(string.format("DeveloperProductService: Failed to prompt purchase for %s: %s", 
            productName, errorMessage))
        return false
    end
    
    print(string.format("DeveloperProductService: Prompted %s to purchase %s", 
        player.Name, productName))
    return true
end

-- Get all available products for a specific type
function DeveloperProductService:GetProductsByType(productType)
    return DeveloperProductConfig:GetProductsByType(productType)
end

-- Get product info for client display
function DeveloperProductService:GetProductInfo(productName)
    return DeveloperProductConfig:GetProductByName(productName)
end

-- Debug function
function DeveloperProductService:DebugReceipts()
    print("=== DEVELOPER PRODUCT RECEIPTS ===")
    local count = 0
    for receiptKey, receiptData in pairs(processedReceipts) do
        print(string.format("- %s: Product %d (Player %d) at %d", 
            receiptKey, receiptData.productId, receiptData.playerId, receiptData.timestamp))
        count = count + 1
    end
    print(string.format("Total cached receipts: %d", count))
    print("================================")
end

return DeveloperProductService