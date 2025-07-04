-- Modern Shop Panel Component
-- Refactored version demonstrating proper separation of concerns
-- Business logic extracted to ShopController, UI focused on display only

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages.react)
local e = React.createElement

-- Import shared utilities
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local ColorPalette = require(ReplicatedStorage.utils.ColorPalette)
local AnimationHelpers = require(ReplicatedStorage.utils.AnimationHelpers)

-- Import business logic controller
local ShopController = require(script.Parent.Parent.Parent.services.controllers.ShopController)

-- Import card components
local ShopPetCard = require(script.Parent.ShopPetCard)
local ShopGamepassCard = require(script.Parent.ShopGamepassCard)

local ShopPanelModern = {}

-- Initialize controller when component loads
React.useEffect(function()
    ShopController.initialize()
    return function()
        ShopController.cleanup()
    end
end, {})

function ShopPanelModern.create(props)
    local visible = props.visible or false
    local onClose = props.onClose or function() end
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    -- Get shop configuration from controller
    local shopTabs = ShopController.getShopTabs()
    
    -- State for active tab
    local activeTab, setActiveTab = React.useState(shopTabs.PETS)
    
    -- Ref for scrolling frame
    local scrollFrameRef = React.useRef(nil)
    
    -- Get responsive dimensions from controller
    local dimensions = ShopController.calculatePanelDimensions(screenSize)
    local gridLayout = ShopController.calculateGridLayout(7, 4, screenSize)
    
    -- Get products from controller
    local petProducts = ShopController.createPetProducts()
    local gamepassProducts = ShopController.createGamepassProducts()
    
    -- Handler functions that use controller logic
    local function handleTabClick(tabType)
        ShopController.playSound("CLICK")
        local newTab = ShopController.handleTabSwitch(activeTab, scrollFrameRef, tabType)
        setActiveTab(newTab)
    end
    
    local function handleCloseClick()
        ShopController.playSound("CLICK")
        onClose()
    end
    
    if not visible then
        return nil
    end
    
    return e("ScreenGui", {
        Name = "ShopPanel",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true
    }, {
        -- Background overlay
        Overlay = e("Frame", {
            Name = "Overlay",
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = ColorPalette.BLACK,
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0
        }),
        
        -- Main panel
        MainPanel = e("Frame", {
            Name = "MainPanel",
            Size = UDim2.new(0, dimensions.panelWidth, 0, dimensions.panelHeight),
            Position = UDim2.new(0.5, -dimensions.panelWidth/2, 0.5, -dimensions.panelHeight/2),
            BackgroundColor3 = ColorPalette.UI.LIGHT_BACKGROUND,
            BorderSizePixel = 0
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 20)
            }),
            
            -- Header section
            Header = ShopPanelModern.createHeader({
                titleTextSize = dimensions.titleTextSize,
                onClose = handleCloseClick
            }),
            
            -- Tab navigation
            TabNavigation = ShopPanelModern.createTabNavigation({
                activeTab = activeTab,
                onTabClick = handleTabClick,
                smallTextSize = dimensions.smallTextSize
            }),
            
            -- Content area
            ContentArea = ShopPanelModern.createContentArea({
                petProducts = petProducts,
                gamepassProducts = gamepassProducts,
                gridLayout = gridLayout,
                scrollFrameRef = scrollFrameRef,
                screenSize = screenSize
            })
        })
    })
end

-- Create header section
function ShopPanelModern.createHeader(config)
    return e("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 60),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1
    }, {
        Title = e("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -60, 1, 0),
            Position = UDim2.new(0, 20, 0, 0),
            BackgroundTransparency = 1,
            Text = "🛒 Shop",
            TextColor3 = ColorPalette.UI.PRIMARY_TEXT,
            TextSize = config.titleTextSize,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center
        }),
        
        CloseButton = e("TextButton", {
            Name = "CloseButton",
            Size = UDim2.new(0, 40, 0, 40),
            Position = UDim2.new(1, -50, 0, 10),
            BackgroundColor3 = ColorPalette.UI.DANGER_BUTTON,
            BorderSizePixel = 0,
            Text = "✕",
            TextColor3 = ColorPalette.WHITE,
            TextSize = 20,
            Font = Enum.Font.GothamBold,
            [React.Event.Activated] = config.onClose,
            [React.Event.MouseEnter] = function()
                ShopController.playSound("HOVER")
            end
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 8)
            })
        })
    })
end

-- Create tab navigation
function ShopPanelModern.createTabNavigation(config)
    local tabs = ShopController.getShopTabs()
    
    return e("Frame", {
        Name = "TabNavigation",
        Size = UDim2.new(1, -40, 0, 50),
        Position = UDim2.new(0, 20, 0, 70),
        BackgroundTransparency = 1
    }, {
        Layout = e("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 10)
        }),
        
        PetsTab = ShopPanelModern.createTabButton({
            text = "🐾 Pets",
            isActive = config.activeTab == tabs.PETS,
            onClick = function() config.onTabClick(tabs.PETS) end,
            textSize = config.smallTextSize
        }),
        
        GamepassesTab = ShopPanelModern.createTabButton({
            text = "💎 Gamepasses",
            isActive = config.activeTab == tabs.GAMEPASSES,
            onClick = function() config.onTabClick(tabs.GAMEPASSES) end,
            textSize = config.smallTextSize
        })
    })
end

-- Create individual tab button
function ShopPanelModern.createTabButton(config)
    local backgroundColor = config.isActive and ColorPalette.UI.PRIMARY_BUTTON or ColorPalette.UI.SECONDARY_BUTTON
    
    return e("TextButton", {
        Size = UDim2.new(0, 150, 0, 35),
        BackgroundColor3 = backgroundColor,
        BorderSizePixel = 0,
        Text = config.text,
        TextColor3 = ColorPalette.WHITE,
        TextSize = config.textSize,
        Font = Enum.Font.GothamBold,
        [React.Event.Activated] = config.onClick,
        [React.Event.MouseEnter] = function()
            ShopController.playSound("HOVER")
        end
    }, {
        Corner = e("UICorner", {
            CornerRadius = UDim.new(0, 8)
        })
    })
end

-- Create content area (simplified for demonstration)
function ShopPanelModern.createContentArea(config)
    return e("ScrollingFrame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -40, 1, -140),
        Position = UDim2.new(0, 20, 0, 130),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 8,
        CanvasSize = UDim2.new(0, 0, 0, 2000), -- Will be calculated dynamically
        [React.Ref] = config.scrollFrameRef
    }, {
        -- Pet cards section
        PetSection = ShopPanelModern.createPetSection(config),
        
        -- Gamepass cards section  
        GamepassSection = ShopPanelModern.createGamepassSection(config)
    })
end

-- Simplified pet section for demonstration
function ShopPanelModern.createPetSection(config)
    local petCards = {}
    
    for i, product in ipairs(config.petProducts) do
        if i <= 7 then -- Limit to 7 cards as per requirements
            petCards["PetCard" .. i] = e(ShopPetCard, {
                product = product,
                gridIndex = i,
                gridLayout = config.gridLayout,
                screenSize = config.screenSize
            })
        end
    end
    
    return e("Frame", {
        Name = "PetSection",
        Size = UDim2.new(1, 0, 0, 600),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1
    }, petCards)
end

-- Simplified gamepass section for demonstration
function ShopPanelModern.createGamepassSection(config)
    local gamepassCards = {}
    
    for i, gamepass in ipairs(config.gamepassProducts) do
        gamepassCards["GamepassCard" .. i] = e(ShopGamepassCard, {
            gamepass = gamepass,
            index = i,
            screenSize = config.screenSize
        })
    end
    
    return e("Frame", {
        Name = "GamepassSection",
        Size = UDim2.new(1, 0, 0, 800),
        Position = UDim2.new(0, 0, 0, 650),
        BackgroundTransparency = 1
    }, gamepassCards)
end

return ShopPanelModern