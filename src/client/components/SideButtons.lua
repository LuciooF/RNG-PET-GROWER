local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages.react)
local e = React.createElement

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
    local onInventoryClick = props.onInventoryClick or function() end
    local onPetsClick = props.onPetsClick or function() end
    local onRebirthClick = props.onRebirthClick or function() end
    local onEggsClick = props.onEggsClick or function() end
    local onComingSoonClick = props.onComingSoonClick or function() end
    
    -- Screen size detection for responsive design
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local scale = getProportionalScale(screenSize)
    
    -- Proportional sizing (made buttons bigger)
    local buttonSize = getProportionalSize(screenSize, 65)
    local iconSize = getProportionalSize(screenSize, 40)
    local spacing = getProportionalSize(screenSize, 15)
    
    -- Icon refs for spin animations
    local shopIconRef = React.useRef(nil)
    local inventoryIconRef = React.useRef(nil)
    local petsIconRef = React.useRef(nil)
    local rebirthIconRef = React.useRef(nil)
    local eggsIconRef = React.useRef(nil)
    local comingSoonIconRef = React.useRef(nil)
    
    -- Animation trackers to prevent stacking
    local shopAnimTracker = React.useRef(nil)
    local inventoryAnimTracker = React.useRef(nil)
    local petsAnimTracker = React.useRef(nil)
    local rebirthAnimTracker = React.useRef(nil)
    local eggsAnimTracker = React.useRef(nil)
    local comingSoonAnimTracker = React.useRef(nil)
    
    return e("Frame", {
        Name = "SideButtonsFrame",
        Size = UDim2.new(0, buttonSize, 0, (6 * buttonSize) + (5 * spacing)),
        Position = UDim2.new(0, getProportionalSize(screenSize, 20), 0.5, -((6 * buttonSize) + (5 * spacing))/2),
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
        
        -- Shop Button
        ShopButton = e("TextButton", {
            Name = "ShopButton",
            Size = UDim2.new(0, buttonSize, 0, buttonSize),
            Text = "",
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 11,
            LayoutOrder = 1,
            [React.Event.Activated] = function()
                createIconSpin(shopIconRef, shopAnimTracker)
                onShopClick()
            end,
            [React.Event.MouseEnter] = function()
                createIconSpin(shopIconRef, shopAnimTracker)
            end
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0.5, 0)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 2,
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            }),
            Icon = e("TextLabel", {
                Name = "ShopIcon",
                Size = UDim2.new(0, iconSize, 0, iconSize),
                Position = UDim2.new(0.5, -iconSize/2, 0.5, -iconSize/2),
                Text = "🛒",
                TextScaled = true,
                BackgroundTransparency = 1,
                ZIndex = 12,
                ref = shopIconRef
            })
        }),
        
        -- Inventory Button
        InventoryButton = e("TextButton", {
            Name = "InventoryButton",
            Size = UDim2.new(0, buttonSize, 0, buttonSize),
            Text = "",
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 11,
            LayoutOrder = 2,
            [React.Event.Activated] = function()
                createIconSpin(inventoryIconRef, inventoryAnimTracker)
                onInventoryClick()
            end,
            [React.Event.MouseEnter] = function()
                createIconSpin(inventoryIconRef, inventoryAnimTracker)
            end
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0.5, 0)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 2,
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            }),
            Icon = e("TextLabel", {
                Name = "InventoryIcon",
                Size = UDim2.new(0, iconSize, 0, iconSize),
                Position = UDim2.new(0.5, -iconSize/2, 0.5, -iconSize/2),
                Text = "🎒",
                TextScaled = true,
                BackgroundTransparency = 1,
                ZIndex = 12,
                ref = inventoryIconRef
            })
        }),
        
        -- Pets Button
        PetsButton = e("TextButton", {
            Name = "PetsButton",
            Size = UDim2.new(0, buttonSize, 0, buttonSize),
            Text = "",
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 11,
            LayoutOrder = 3,
            [React.Event.Activated] = function()
                createIconSpin(petsIconRef, petsAnimTracker)
                onPetsClick()
            end,
            [React.Event.MouseEnter] = function()
                createIconSpin(petsIconRef, petsAnimTracker)
            end
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0.5, 0)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 2,
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            }),
            Icon = e("TextLabel", {
                Name = "PetsIcon",
                Size = UDim2.new(0, iconSize, 0, iconSize),
                Position = UDim2.new(0.5, -iconSize/2, 0.5, -iconSize/2),
                Text = "🐾",
                TextScaled = true,
                BackgroundTransparency = 1,
                ZIndex = 12,
                ref = petsIconRef
            })
        }),
        
        -- Rebirth Button
        RebirthButton = e("TextButton", {
            Name = "RebirthButton",
            Size = UDim2.new(0, buttonSize, 0, buttonSize),
            Text = "",
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 11,
            LayoutOrder = 4,
            [React.Event.Activated] = function()
                createIconSpin(rebirthIconRef, rebirthAnimTracker)
                onRebirthClick()
            end,
            [React.Event.MouseEnter] = function()
                createIconSpin(rebirthIconRef, rebirthAnimTracker)
            end
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0.5, 0)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 2,
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            }),
            Icon = e("TextLabel", {
                Name = "RebirthIcon",
                Size = UDim2.new(0, iconSize, 0, iconSize),
                Position = UDim2.new(0.5, -iconSize/2, 0.5, -iconSize/2),
                Text = "🔄",
                TextScaled = true,
                BackgroundTransparency = 1,
                ZIndex = 12,
                ref = rebirthIconRef
            })
        }),
        
        -- Eggs Button
        EggsButton = e("TextButton", {
            Name = "EggsButton",
            Size = UDim2.new(0, buttonSize, 0, buttonSize),
            Text = "",
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 11,
            LayoutOrder = 5,
            [React.Event.Activated] = function()
                createIconSpin(eggsIconRef, eggsAnimTracker)
                onEggsClick()
            end,
            [React.Event.MouseEnter] = function()
                createIconSpin(eggsIconRef, eggsAnimTracker)
            end
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0.5, 0)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 2,
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            }),
            Icon = e("TextLabel", {
                Name = "EggsIcon",
                Size = UDim2.new(0, iconSize, 0, iconSize),
                Position = UDim2.new(0.5, -iconSize/2, 0.5, -iconSize/2),
                Text = "🥚",
                TextScaled = true,
                BackgroundTransparency = 1,
                ZIndex = 12,
                ref = eggsIconRef
            })
        }),
        
        -- Coming Soon Button
        ComingSoonButton = e("TextButton", {
            Name = "ComingSoonButton",
            Size = UDim2.new(0, buttonSize, 0, buttonSize),
            Text = "",
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 11,
            LayoutOrder = 6,
            [React.Event.Activated] = function()
                createIconSpin(comingSoonIconRef, comingSoonAnimTracker)
                onComingSoonClick()
            end,
            [React.Event.MouseEnter] = function()
                createIconSpin(comingSoonIconRef, comingSoonAnimTracker)
            end
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0.5, 0)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 2,
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            }),
            Icon = e("TextLabel", {
                Name = "ComingSoonIcon",
                Size = UDim2.new(0, iconSize, 0, iconSize),
                Position = UDim2.new(0.5, -iconSize/2, 0.5, -iconSize/2),
                Text = "❓",
                TextScaled = true,
                BackgroundTransparency = 1,
                ZIndex = 12,
                ref = comingSoonIconRef
            })
        })
    })
end

return SideButtons