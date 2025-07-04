-- Shop Controller
-- Business logic for shop operations and data management
-- Extracted from ShopPanel.lua for better separation of concerns

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

-- Import configs
local DeveloperProductConfig = require(ReplicatedStorage.Shared.config.DeveloperProductConfig)
local GamepassConfig = require(ReplicatedStorage.Shared.config.GamepassConfig)

-- Import utilities
local ErrorHandler = require(ReplicatedStorage.utils.ErrorHandler)

local ShopController = {}

-- Constants
local SHOP_TABS = {
    PETS = "pets",
    GAMEPASSES = "gamepasses"
}

-- Sound configuration
local SOUNDS = {
    HOVER = "rbxassetid://15675059323",
    CLICK = "rbxassetid://6324790483"
}

-- Pre-created sounds for performance
local sounds = {}

-- Initialize sound system
function ShopController.initializeSounds()
    for soundType, soundId in pairs(SOUNDS) do
        sounds[soundType] = ErrorHandler.safeCreate("Sound", {
            SoundId = soundId,
            Volume = soundType == "HOVER" and 0.3 or 0.4,
            Parent = SoundService
        }, nil, "Creating " .. soundType .. " sound")
    end
end

-- Play sound effects
function ShopController.playSound(soundType)
    local sound = sounds[soundType]
    if sound then
        ErrorHandler.safeCall(
            function() sound:Play() end,
            "Playing " .. soundType .. " sound"
        )
    end
end

-- Get shop tabs configuration
function ShopController.getShopTabs()
    return SHOP_TABS
end

-- Create pet products for shop display
function ShopController.createPetProducts()
    local petProducts = {}
    
    -- Special Cyber Dominus product
    local cyberDominusProduct = {
        id = 999999999,
        name = "CyberDominus",
        displayName = "🌈 Cyber Dominus",
        description = "The ultimate rainbow dominus with cosmic power!",
        type = DeveloperProductConfig.TYPES.PET,
        price = 1999,
        icon = "rbxassetid://234567890",
        petData = {
            name = "Cyber Dominus",
            assetPath = "Pets/Cyber Dominus",
            rarity = 21, -- Rainbow rarity
            value = 50000,
            description = "The most powerful dominus in existence.",
            isFlyingPet = true,
            baseBoost = 2000,
            specialEffects = {"rainbow_aura", "cosmic_power", "dominus_blessing"}
        }
    }
    
    -- Add standard developer products for pets
    for _, product in pairs(DeveloperProductConfig.PRODUCTS) do
        if product.type == DeveloperProductConfig.TYPES.PET then
            table.insert(petProducts, product)
        end
    end
    
    -- Add Cyber Dominus to the beginning
    table.insert(petProducts, 1, cyberDominusProduct)
    
    return petProducts
end

-- Create gamepass products for shop display
function ShopController.createGamepassProducts()
    local gamepassProducts = {}
    
    for _, gamepass in pairs(GamepassConfig.GAMEPASSES) do
        table.insert(gamepassProducts, gamepass)
    end
    
    return gamepassProducts
end

-- Calculate grid layout for shop items
function ShopController.calculateGridLayout(itemCount, maxCols, screenSize)
    local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
    
    -- Pet card grid sizes for specific layout
    local gridSizes = {
        {cols = 1, rows = 1}, -- Row 1: Small card
        {cols = 2, rows = 1}, -- Row 1: Long card
        {cols = 1, rows = 1}, -- Row 1: Small card
        {cols = 1, rows = 1}, -- Row 1: Small card
        {cols = 2, rows = 1}, -- Row 2: Long card
        {cols = 1, rows = 1}, -- Row 2: Small card
        {cols = 2, rows = 1}  -- Row 2: Long card
    }
    
    local baseCardWidth = ScreenUtils.getProportionalSize(screenSize, 160)
    local baseCardHeight = ScreenUtils.getProportionalSize(screenSize, 140)
    local gridPadding = ScreenUtils.getProportionalSize(screenSize, 10)
    
    return {
        gridSizes = gridSizes,
        baseCardWidth = baseCardWidth,
        baseCardHeight = baseCardHeight,
        gridPadding = gridPadding
    }
end

-- Handle tab switching logic
function ShopController.handleTabSwitch(activeTab, scrollFrameRef, targetTab)
    if targetTab == SHOP_TABS.GAMEPASSES and scrollFrameRef.current then
        -- Scroll to gamepasses section
        return ErrorHandler.safeCall(
            function()
                scrollFrameRef.current.CanvasPosition = Vector2.new(0, 1000)
                return targetTab
            end,
            "Scrolling to gamepasses section",
            activeTab -- Keep current tab on error
        )
    else
        -- Scroll to top for pets
        return ErrorHandler.safeCall(
            function()
                if scrollFrameRef.current then
                    scrollFrameRef.current.CanvasPosition = Vector2.new(0, 0)
                end
                return targetTab
            end,
            "Scrolling to pets section",
            activeTab -- Keep current tab on error
        )
    end
end

-- Purchase validation logic
function ShopController.validatePurchase(productData, playerData)
    if not productData then
        return false, "Invalid product data"
    end
    
    if not playerData then
        return false, "Invalid player data"
    end
    
    -- Check if player has enough funds (basic validation)
    local playerMoney = playerData.resources and playerData.resources.money or 0
    local productPrice = productData.price or 0
    
    if playerMoney < productPrice then
        return false, "Insufficient funds"
    end
    
    return true, "Purchase valid"
end

-- Process purchase request
function ShopController.processPurchase(productData, productType)
    return ErrorHandler.safeCall(
        function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if not remotes then
                error("Remotes folder not found")
            end
            
            local purchaseRemote
            if productType == DeveloperProductConfig.TYPES.PET then
                purchaseRemote = remotes:FindFirstChild("PurchaseDeveloperProduct")
            else
                purchaseRemote = remotes:FindFirstChild("PurchaseGamepass")
            end
            
            if not purchaseRemote then
                error("Purchase remote not found for type: " .. tostring(productType))
            end
            
            purchaseRemote:FireServer(productData)
            return true
        end,
        "Processing purchase for: " .. tostring(productData.name),
        false
    )
end

-- Calculate responsive panel dimensions
function ShopController.calculatePanelDimensions(screenSize)
    local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
    
    return {
        scale = ScreenUtils.getProportionalScale(screenSize),
        panelWidth = math.min(screenSize.X * 0.9, ScreenUtils.getProportionalSize(screenSize, 900)),
        panelHeight = math.min(screenSize.Y * 0.8, ScreenUtils.getProportionalSize(screenSize, 600)),
        titleTextSize = ScreenUtils.getProportionalTextSize(screenSize, 32),
        smallTextSize = ScreenUtils.getProportionalTextSize(screenSize, 14)
    }
end

-- Cleanup function
function ShopController.cleanup()
    for _, sound in pairs(sounds) do
        if sound and sound.Parent then
            sound:Destroy()
        end
    end
    sounds = {}
end

-- Initialize the controller
function ShopController.initialize()
    ShopController.initializeSounds()
end

return ShopController