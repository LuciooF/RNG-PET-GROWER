-- OPPetService - Handles OP pet purchases and management
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local DataService = require(script.Parent.DataService)
local OPPetConfig = require(ReplicatedStorage.config.OPPetConfig)

local OPPetService = {}
OPPetService.__index = OPPetService

function OPPetService:Initialize()
    -- ProcessReceipt is handled by Main.server.lua to avoid conflicts
    -- This service provides ProcessReceipt method for Main.server.lua to call
    -- OPPetService initialized
end

-- Process dev product purchases
function OPPetService:ProcessReceipt(receiptInfo)
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    
    -- Check if this is an OP pet purchase
    local opPetData = OPPetConfig.getOPPetByDevProduct(receiptInfo.ProductId)
    if not opPetData then
        -- Not an OP pet purchase, let other services handle it
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    
    -- Create the OP pet
    local opPet = OPPetConfig.createOPPet(opPetData, player.UserId)
    
    -- Add to player's OP pets array
    local success = self:AddOPPetToPlayer(player, opPet)
    
    if success then
        -- Track robux spending for leaderboard (dynamic price)
        local DataService = require(script.Parent.DataService)
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
        
        local price = getDevProductPrice(opPetData.DevProductId)
        DataService:AddRobuxSpent(player, price)
        
        -- Send success notification to client
        local successRemote = ReplicatedStorage:FindFirstChild("OPPetPurchaseSuccess")
        if successRemote then
            successRemote:FireClient(player, opPet)
        end
        
        return Enum.ProductPurchaseDecision.PurchaseGranted
    else
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
end

-- Add OP pet to player's data
function OPPetService:AddOPPetToPlayer(player, opPet)
    local profile = DataService:GetPlayerProfile(player)
    if not profile then
        return false
    end
    
    -- Initialize OP pets array if it doesn't exist
    if not profile.Data.OPPets then
        profile.Data.OPPets = {}
    end
    
    -- Add the OP pet
    table.insert(profile.Data.OPPets, opPet)
    
    -- OP pets are automatically "equipped" (they always provide boost)
    -- No need to manage equipped status since they're always active
    
    -- Sync data to client
    DataService:SyncPlayerDataToClient(player)
    
    return true
end

-- Get all OP pets for a player
function OPPetService:GetPlayerOPPets(player)
    local profile = DataService:GetPlayerProfile(player)
    if not profile then
        return {}
    end
    
    return profile.Data.OPPets or {}
end

-- Calculate total boost from OP pets
function OPPetService:GetOPPetBoost(player)
    local opPets = self:GetPlayerOPPets(player)
    local totalBoost = 0
    
    for _, opPet in ipairs(opPets) do
        totalBoost = totalBoost + (opPet.FinalBoost or opPet.BaseBoost or 0)
    end
    
    return totalBoost
end

-- Check if player owns specific OP pet
function OPPetService:PlayerOwnsOPPet(player, opPetName)
    local opPets = self:GetPlayerOPPets(player)
    
    for _, opPet in ipairs(opPets) do
        if opPet.Name == opPetName then
            return true
        end
    end
    
    return false
end

-- Prompt player to purchase OP pet
function OPPetService:PromptOPPetPurchase(player, opPetName)
    print("OPPetService:PromptOPPetPurchase called for", player.Name, "pet:", opPetName)
    
    local opPetData = OPPetConfig.getOPPetByName(opPetName)
    if not opPetData then
        warn("OP pet data not found for:", opPetName)
        return false
    end
    
    print("Found OP pet data:", opPetData.Name, "DevProductId:", opPetData.DevProductId)
    
    if not opPetData.DevProductId then
        warn("No DevProductId set for OP pet:", opPetName)
        return false
    end
    
    -- Allow multiple purchases of the same OP pet (removed ownership check)
    print("Allowing purchase of OP pet:", opPetName, "- multiple purchases enabled")
    
    -- Prompt purchase
    print("Attempting to prompt purchase for DevProduct:", opPetData.DevProductId)
    local success, error = pcall(function()
        MarketplaceService:PromptProductPurchase(player, opPetData.DevProductId)
    end)
    
    if not success then
        warn("Failed to prompt purchase:", error)
        -- Send feedback to client that prompt failed
        local feedbackRemote = ReplicatedStorage:FindFirstChild("OPPetPurchaseError")
        if feedbackRemote then
            feedbackRemote:FireClient(player, "Purchase prompt failed: " .. tostring(error))
        end
        return false
    end
    
    print("Purchase prompt successful")
    return true
end

return OPPetService