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
    local onLabClick = props.onLabClick or function() end
    local onRebirthClick = props.onRebirthClick or function() end
    local onFriendsClick = props.onFriendsClick or function() end
    local onDebugClick = props.onDebugClick or function() end
    
    -- Screen size detection for responsive design
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local scale = getProportionalScale(screenSize)
    
    -- Proportional sizing with mobile minimum touch targets
    local buttonSize = math.max(44, getProportionalSize(screenSize, 65)) -- 44pt minimum for mobile
    local iconSize = math.max(24, getProportionalSize(screenSize, 40)) -- 24pt minimum for mobile
    local spacing = getProportionalSize(screenSize, 15)
    
    -- Icon refs for spin animations
    local shopIconRef = React.useRef(nil)
    local petsIconRef = React.useRef(nil)
    local labIconRef = React.useRef(nil)
    local rebirthIconRef = React.useRef(nil)
    local friendsIconRef = React.useRef(nil)
    local debugIconRef = React.useRef(nil)
    
    -- Animation trackers to prevent stacking
    local shopAnimTracker = React.useRef(nil)
    local petsAnimTracker = React.useRef(nil)
    local labAnimTracker = React.useRef(nil)
    local rebirthAnimTracker = React.useRef(nil)
    local friendsAnimTracker = React.useRef(nil)
    local debugAnimTracker = React.useRef(nil)
    
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
        
        -- Lab Button 
        LabButton = e("TextButton", {
            Name = "LabButton",
            Size = UDim2.new(0, buttonSize, 0, buttonSize),
            Text = "",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 11,
            LayoutOrder = 3,
            [React.Event.Activated] = function()
                createIconSpin(labIconRef, labAnimTracker)
                onLabClick()
            end,
            [React.Event.MouseEnter] = function()
                createIconSpin(labIconRef, labAnimTracker)
            end
        }, {
            Icon = e("ImageLabel", {
                Name = "LabIcon",
                Size = UDim2.new(0, iconSize, 0, iconSize),
                Position = UDim2.new(0.5, -iconSize/2, 0.5, -iconSize/2),
                Image = assets["vector-icon-pack-2/Tools/Potion 4/Potion 4 Green Outline 256.png"] or "",
                BackgroundTransparency = 1,
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 12,
                ref = labIconRef
            }),
            
            -- Fallback emoji if potion icon doesn't exist
            FallbackIcon = e("TextLabel", {
                Name = "LabFallbackIcon",
                Size = UDim2.new(0, iconSize, 0, iconSize),
                Position = UDim2.new(0.5, -iconSize/2, 0.5, -iconSize/2),
                Text = "🧪",
                TextColor3 = Color3.fromRGB(100, 255, 150),
                TextSize = getProportionalSize(screenSize, 20),
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 11, -- Behind the image
                Visible = assets["vector-icon-pack-2/Tools/Potion 4/Potion 4 Green Outline 256.png"] == nil or assets["vector-icon-pack-2/Tools/Potion 4/Potion 4 Green Outline 256.png"] == ""
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
            LayoutOrder = 4,
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
        
        
        -- Friends Button
        FriendsButton = e("TextButton", {
            Name = "FriendsButton",
            Size = UDim2.new(0, buttonSize, 0, buttonSize),
            Text = "",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 11,
            LayoutOrder = 5,
            [React.Event.Activated] = function()
                createIconSpin(friendsIconRef, friendsAnimTracker)
                onFriendsClick()
            end,
            [React.Event.MouseEnter] = function()
                createIconSpin(friendsIconRef, friendsAnimTracker)
            end
        }, {
            Icon = e("ImageLabel", {
                Name = "FriendsIcon",
                Size = UDim2.new(0, iconSize, 0, iconSize),
                Position = UDim2.new(0.5, -iconSize/2, 0.5, -iconSize/2),
                Image = assets["vector-icon-pack-2/Player/Friends/Friends Outline 256.png"] or "",
                BackgroundTransparency = 1,
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 12,
                ref = friendsIconRef
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
            LayoutOrder = 6,
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