-- SideBar - Unified side navigation with all buttons in proper order
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local React = require(ReplicatedStorage.Packages.react)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)
local TooltipUtils = require(ReplicatedStorage.utils.TooltipUtils)
local DataSyncService = require(script.Parent.Parent.services.DataSyncService)
local SoundService = game:GetService("SoundService")
local AuthorizationUtils = require(ReplicatedStorage.utils.AuthorizationUtils)
local BoostCalculator = require(ReplicatedStorage.utils.BoostCalculator)

-- Sound configuration
local HOVER_SOUND_ID = "rbxassetid://6895079853"

-- Pre-create hover sound for instant playback
local hoverSound = Instance.new("Sound")
hoverSound.SoundId = HOVER_SOUND_ID
hoverSound.Volume = 0.5
hoverSound.Parent = SoundService

-- Play hover sound instantly (no creation overhead)
local function playHoverSound()
    -- Just play the pre-created sound
    hoverSound:Play()
end

local function SideBar(props)
    -- Subscribe to player data for pet count and boost calculation
    local playerData, setPlayerData = React.useState({
        Pets = {},
        EquippedPets = {},
        OPPets = {},
        OwnedGamepasses = {}
    })
    
    React.useEffect(function()
        -- Get initial data
        local initialData = DataSyncService:GetPlayerData()
        if initialData then
            setPlayerData(initialData)
        end
        
        local unsubscribe = DataSyncService:Subscribe(function(newState)
            if newState.player then
                setPlayerData(newState.player)
            end
        end)
        
        return function()
            if unsubscribe and type(unsubscribe) == "function" then
                unsubscribe()
            end
        end
    end, {})
    
    -- Calculate pet count and format it
    local petCount = #(playerData.Pets or {})
    local petCountText = NumberFormatter.format(petCount)
    
    -- Use centralized boost calculation
    local totalBoostMultiplier = BoostCalculator.calculateTotalBoostMultiplier(playerData)
    
    -- Responsive button setup (10% smaller)
    local screenSize = ScreenUtils.getScreenSize()
    local screenHeight = screenSize.Y
    local buttonPixelSize = screenHeight * 0.063 -- 6.3% of screen height for buttons (10% smaller)
    local spacingPixelSize = screenHeight * 0.036 -- 3.6% of screen height for spacing (10% smaller)
    local buttonSize = UDim2.new(0, buttonPixelSize, 0, buttonPixelSize)
    
    -- Create buttons array in the EXACT order we want them to appear
    local buttons = {}
    
    -- 1. Gamepasses
    buttons[1] = TooltipUtils.createHoverButton({
        Name = "A_GamepassButton",
        Size = buttonSize,
        BackgroundTransparency = 1,
        Image = IconAssets.getIcon("CURRENCY", "ROBUX"),
        ScaleType = Enum.ScaleType.Fit,
        SizeConstraint = Enum.SizeConstraint.RelativeYY,
        [React.Event.Activated] = function()
            if props.onGamepassClick then
                props.onGamepassClick()
            end
        end
    }, "Gamepasses")
    
    -- 2. Pets
    buttons[2] = React.createElement("Frame", {
        Name = "B_PetsButtonContainer",
        Size = buttonSize,
        BackgroundTransparency = 1,
        ZIndex = 50
    }, {
        PetsButton = TooltipUtils.createHoverButton({
            Name = "PetsButton",
            Size = ScreenUtils.udim2(1, 0, 1, 0),
            Position = ScreenUtils.udim2(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Image = IconAssets.getIcon("UI", "PET"),
            ScaleType = Enum.ScaleType.Fit,
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            [React.Event.Activated] = function()
                if props.onPetsClick then
                    props.onPetsClick()
                end
            end
        }, "Pet Inventory"),
        
        PetCountBadge = React.createElement("Frame", {
            Name = "PetCountBadge",
            Size = ScreenUtils.udim2(0, 36, 0, 24), -- Bigger badge
            Position = ScreenUtils.udim2(1, -18, 0, -4),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundColor3 = Color3.fromRGB(255, 100, 100),
            BorderSizePixel = 0,
            ZIndex = 52
        }, {
            UICorner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, 12)
            }),
            UIStroke = React.createElement("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 2,
                Transparency = 0
            }),
            CountText = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = petCountText,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                TextSize = 16, -- Bigger text
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 53
            })
        })
    })
    
    -- 3. Index
    buttons[3] = TooltipUtils.createHoverButton({
        Name = "C_IndexButton",
        Size = buttonSize,
        BackgroundTransparency = 1,
        Image = IconAssets.getIcon("UI", "INDEX"),
        ScaleType = Enum.ScaleType.Fit,
        SizeConstraint = Enum.SizeConstraint.RelativeYY,
        [React.Event.Activated] = function()
            if props.onIndexClick then
                props.onIndexClick()
            end
        end
    }, "Pet Index")
    
    -- 4. Rebirth
    buttons[4] = TooltipUtils.createHoverButton({
        Name = "D_RebirthButton",
        Size = buttonSize,
        BackgroundTransparency = 1,
        Image = IconAssets.getIcon("UI", "REBIRTH"),
        ScaleType = Enum.ScaleType.Fit,
        SizeConstraint = Enum.SizeConstraint.RelativeYY,
        [React.Event.Activated] = function()
            if props.onRebirthClick then
                props.onRebirthClick()
            end
        end
    }, "Rebirths")
    
    -- 5. Debug (only for authorized users)
    local localPlayer = Players.LocalPlayer
    if AuthorizationUtils.isAuthorized(localPlayer) then
        buttons[5] = TooltipUtils.createHoverButton({
            Name = "E_DebugButton",
            Size = buttonSize,
            BackgroundTransparency = 1,
            Image = IconAssets.getIcon("UI", "SETTINGS"),
            ScaleType = Enum.ScaleType.Fit,
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            [React.Event.Activated] = function()
                if props.onDebugClick then
                    props.onDebugClick()
                end
            end
        }, "Settings")
    else
        -- Create empty placeholder for unauthorized users
        buttons[5] = React.createElement("Frame", {
            Name = "E_DebugPlaceholder",
            Size = buttonSize,
            BackgroundTransparency = 1,
        })
    end
    
    -- 6. Boost
    buttons[6] = React.createElement("Frame", {
        Name = "F_BoostButtonContainer",
        Size = buttonSize,
        BackgroundTransparency = 1,
        ZIndex = 50
    }, {
        BoostButton = TooltipUtils.createHoverButton({
            Name = "BoostButton",
            Size = ScreenUtils.udim2(1, 0, 1, 0),
            Position = ScreenUtils.udim2(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Image = IconAssets.getIcon("UI", "BOOST"),
            ScaleType = Enum.ScaleType.Fit,
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            [React.Event.Activated] = function()
                if props.onBoostClick then
                    props.onBoostClick()
                end
            end
        }, "Boost Panel"),
        
        BoostBadge = React.createElement("Frame", {
            Name = "BoostBadge",
            Size = UDim2.new(0, buttonPixelSize * 0.55, 0, buttonPixelSize * 0.35), -- Made bigger
            Position = UDim2.new(1, -buttonPixelSize * 0.57, 0, -4), -- Adjusted position
            BackgroundColor3 = Color3.fromRGB(255, 215, 0),
            BorderSizePixel = 0,
            ZIndex = 52
        }, {
            BoostCorner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, 6) -- Slightly bigger corner radius
            }),
            BoostText = React.createElement("TextLabel", {
                Name = "BoostText",
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = string.format("%sx", NumberFormatter.formatBoost(totalBoostMultiplier)), -- Use formatted numbers
                TextColor3 = Color3.fromRGB(0, 0, 0),
                TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(), -- Made bigger text
                Font = Enum.Font.FredokaOne,
                TextScaled = true,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 53
            })
        })
    })
    
    
    -- Create structured layout with rows
    local children = {
        UIListLayout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, spacingPixelSize * 0.6), -- Reduce spacing between rows
            SortOrder = Enum.SortOrder.Name
        })
    }
    
    -- Row 1: Gamepass Button (centered)
    children["Row1_Gamepass"] = React.createElement("Frame", {
        Size = UDim2.new(0, buttonPixelSize, 0, buttonPixelSize),
        BackgroundTransparency = 1,
        ZIndex = 50
    }, {
        GamepassButton = buttons[1]
    })
    
    -- Row 2: Pet Button | Pet Index Button (side by side)
    children["Row2_PetsAndIndex"] = React.createElement("Frame", {
        Size = UDim2.new(0, buttonPixelSize * 2 + spacingPixelSize * 0.5, 0, buttonPixelSize),
        BackgroundTransparency = 1,
        ZIndex = 50
    }, {
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, spacingPixelSize * 0.5),
            SortOrder = Enum.SortOrder.Name
        }),
        PetButton = buttons[2],  -- Pets
        IndexButton = buttons[3]  -- Index
    })
    
    -- Row 3: Rebirth Button | Boost Button (side by side)
    children["Row3_RebirthAndBoost"] = React.createElement("Frame", {
        Size = UDim2.new(0, buttonPixelSize * 2 + spacingPixelSize * 0.5, 0, buttonPixelSize),
        BackgroundTransparency = 1,
        ZIndex = 50
    }, {
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, spacingPixelSize * 0.5),
            SortOrder = Enum.SortOrder.Name
        }),
        RebirthButton = buttons[4],  -- Rebirth
        BoostButton = buttons[6]  -- Boost
    })
    
    -- Row 4: Debug Button (only if authorized)
    if AuthorizationUtils.isAuthorized(localPlayer) then
        children["Row4_Debug"] = React.createElement("Frame", {
            Size = UDim2.new(0, buttonPixelSize, 0, buttonPixelSize),
            BackgroundTransparency = 1,
            ZIndex = 50
        }, {
            DebugButton = buttons[5]
        })
    end
    
    return React.createElement("Frame", {
        Name = "SideBar",
        Size = ScreenUtils.udim2(0, buttonPixelSize * 2 + spacingPixelSize + 30, 1, 0), -- Wide enough for 2 buttons + spacing + padding
        Position = ScreenUtils.udim2(0, 15, 0, 0), -- More padding from left edge
        BackgroundTransparency = 1,
        ZIndex = 50
    }, {
        ButtonContainer = React.createElement("Frame", {
            Name = "ButtonContainer",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Position = UDim2.new(0, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            ZIndex = 50
        }, children)
    })
end

return SideBar