local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages.react)
local e = React.createElement

-- Assets (use new modular system)
local assets = require(ReplicatedStorage.assets)

-- Import shared utilities
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local AnimationHelpers = require(ReplicatedStorage.utils.AnimationHelpers)

-- Use shared utility functions
local getProportionalScale = ScreenUtils.getProportionalScale
local getProportionalSize = ScreenUtils.getProportionalSize

-- Use shared animation helper (createFlipAnimation works for spin too)
local createIconSpin = AnimationHelpers.createFlipAnimation

local function SideButtons(props)
    local onShopClick = props.onShopClick or function() end
    local onPetsClick = props.onPetsClick or function() end
    local onRebirthClick = props.onRebirthClick or function() end
    local onDebugClick = props.onDebugClick or function() end
    
    -- Screen size detection for responsive design
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local scale = getProportionalScale(screenSize)
    
    -- Proportional sizing (made buttons bigger)
    local buttonSize = getProportionalSize(screenSize, 65)
    local iconSize = getProportionalSize(screenSize, 40)
    local spacing = getProportionalSize(screenSize, 15)
    
    -- Icon refs for spin animations
    local shopIconRef = React.useRef(nil)
    local petsIconRef = React.useRef(nil)
    local rebirthIconRef = React.useRef(nil)
    
    -- Animation trackers to prevent stacking
    local shopAnimTracker = React.useRef(nil)
    local petsAnimTracker = React.useRef(nil)
    local rebirthAnimTracker = React.useRef(nil)
    
    -- Icon refs for spin animations  
    local debugIconRef = React.useRef(nil)
    
    -- Animation trackers to prevent stacking
    local debugAnimTracker = React.useRef(nil)
    
    return e("Frame", {
        Name = "SideButtonsFrame",
        Size = UDim2.new(0, buttonSize, 0, (4 * buttonSize) + (3 * spacing)),
        Position = UDim2.new(0, getProportionalSize(screenSize, 20), 0.5, -((4 * buttonSize) + (3 * spacing))/2),
        BackgroundTransparency = 1,
        ZIndex = 10
    }, {
        Layout = e("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            Padding = UDim.new(0, spacing),
            SortOrder = Enum.SortOrder.LayoutOrder
        }),
        
        -- Pet Inventory Button (moved to top)
        PetInventoryButton = e("TextButton", {
            Name = "PetInventoryButton",
            Size = UDim2.new(0, buttonSize, 0, buttonSize),
            Text = "",
            BackgroundTransparency = 1, -- Remove white background
            BorderSizePixel = 0,
            ZIndex = 11,
            LayoutOrder = 1,
            [React.Event.Activated] = function()
                createIconSpin(petsIconRef, petsAnimTracker)
                onPetsClick()
            end,
            [React.Event.MouseEnter] = function()
                createIconSpin(petsIconRef, petsAnimTracker)
            end
        }, {
            Icon = e("ImageLabel", {
                Name = "PetInventoryIcon",
                Size = UDim2.new(0, iconSize, 0, iconSize),
                Position = UDim2.new(0.5, -iconSize/2, 0.5, -iconSize/2),
                Image = assets["vector-icon-pack-2/General/Pet 2/Pet 2 Outline 256.png"] or "",
                BackgroundTransparency = 1,
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 12,
                ref = petsIconRef
            })
        }),
        
        -- Shop Button (moved to middle)
        ShopButton = e("TextButton", {
            Name = "ShopButton",
            Size = UDim2.new(0, buttonSize, 0, buttonSize),
            Text = "",
            BackgroundTransparency = 1, -- Remove white background
            BorderSizePixel = 0,
            ZIndex = 11,
            LayoutOrder = 2,
            [React.Event.Activated] = function()
                createIconSpin(shopIconRef, shopAnimTracker)
                onShopClick()
            end,
            [React.Event.MouseEnter] = function()
                createIconSpin(shopIconRef, shopAnimTracker)
            end
        }, {
            Icon = e("ImageLabel", {
                Name = "ShopIcon",
                Size = UDim2.new(0, iconSize, 0, iconSize),
                Position = UDim2.new(0.5, -iconSize/2, 0.5, -iconSize/2),
                Image = assets["vector-icon-pack-2/General/Shop/Shop Outline 256.png"] or "",
                BackgroundTransparency = 1,
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 12,
                ref = shopIconRef
            })
        }),
        
        -- Rebirth Button
        RebirthButton = e("TextButton", {
            Name = "RebirthButton",
            Size = UDim2.new(0, buttonSize, 0, buttonSize),
            Text = "",
            BackgroundTransparency = 1, -- Remove white background
            BorderSizePixel = 0,
            ZIndex = 11,
            LayoutOrder = 3,
            [React.Event.Activated] = function()
                createIconSpin(rebirthIconRef, rebirthAnimTracker)
                onRebirthClick()
            end,
            [React.Event.MouseEnter] = function()
                createIconSpin(rebirthIconRef, rebirthAnimTracker)
            end
        }, {
            Icon = e("ImageLabel", {
                Name = "RebirthIcon",
                Size = UDim2.new(0, iconSize, 0, iconSize),
                Position = UDim2.new(0.5, -iconSize/2, 0.5, -iconSize/2),
                Image = assets["vector-icon-pack-2/General/Rebirth/Rebirth Outline 256.png"] or "",
                BackgroundTransparency = 1,
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 12,
                ref = rebirthIconRef
            })
        }),
        
        -- Debug Button (bottom)
        DebugButton = e("TextButton", {
            Name = "DebugButton",
            Size = UDim2.new(0, buttonSize, 0, buttonSize),
            Text = "",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 11,
            LayoutOrder = 4,
            [React.Event.Activated] = function()
                createIconSpin(debugIconRef, debugAnimTracker)
                onDebugClick()
            end,
            [React.Event.MouseEnter] = function()
                createIconSpin(debugIconRef, debugAnimTracker)
            end
        }, {
            Icon = e("ImageLabel", {
                Name = "DebugIcon",
                Size = UDim2.new(0, iconSize, 0, iconSize),
                Position = UDim2.new(0.5, -iconSize/2, 0.5, -iconSize/2),
                Image = assets["vector-icon-pack-2/General/Bug/Bug Outline 256.png"] or "",
                BackgroundTransparency = 1,
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 12,
                ref = debugIconRef
            }),
            
            -- Fallback text if image doesn't load
            FallbackText = e("TextLabel", {
                Name = "DebugText",
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                Text = "🐛",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = iconSize * 0.6,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 13
            })
        })
    })
end

return SideButtons