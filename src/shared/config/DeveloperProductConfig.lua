-- DeveloperProductConfig - Dynamic configuration for all developer products
local DeveloperProductConfig = {}

-- Dynamic developer products - fetched from marketplace
DeveloperProductConfig.PRODUCTS = {}

-- Function to get all real developer products from the game dynamically
function DeveloperProductConfig.getAllProducts()
    -- Return empty table - products will be fetched dynamically by the GamepassUI
    -- from the Roblox marketplace using MarketplaceService
    return DeveloperProductConfig.PRODUCTS
end

-- Helper functions for backward compatibility
function DeveloperProductConfig.getProductById(productId)
    for name, config in pairs(DeveloperProductConfig.PRODUCTS) do
        if config.id == productId then
            return name, config
        end
    end
    return nil
end

function DeveloperProductConfig.getProductByName(productName)
    return DeveloperProductConfig.PRODUCTS[productName]
end

function DeveloperProductConfig.getProductsByCategory(category)
    local products = {}
    for name, config in pairs(DeveloperProductConfig.PRODUCTS) do
        if config.category == category then
            products[name] = config
        end
    end
    return products
end

-- Function to set products dynamically (called by GamepassUI)
function DeveloperProductConfig.setProducts(products)
    DeveloperProductConfig.PRODUCTS = products or {}
end

return DeveloperProductConfig