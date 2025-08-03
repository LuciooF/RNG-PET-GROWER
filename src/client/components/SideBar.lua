-- SideBar - Unified side navigation with all buttons in proper order
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local React = require(ReplicatedStorage.Packages.react)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)
local TooltipUtils = require(ReplicatedStorage.utils.TooltipUtils)
local DataSyncService = require(script.Parent.Parent.services.DataSyncService)

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
    local petCountText = ""
    if petCount >= 1000000 then
        petCountText = string.format("%.1fM", petCount / 1000000)
    elseif petCount >= 1000 then
        petCountText = string.format("%.1fK", petCount / 1000)
    else
        petCountText = tostring(petCount)
    end
    
    -- Calculate total boost for boost button (matches BoostPanel calculation)
    -- Pet boost calculation
    local petBoostMultiplier = 0 -- Start at 0, not 1
    for _, pet in pairs(playerData.EquippedPets or {}) do
        if pet.FinalBoost then
            petBoostMultiplier = petBoostMultiplier + (pet.FinalBoost - 1)
        end
    end
    
    -- OP Pet boost calculation
    local opPetBoostMultiplier = 0 -- Start at 0, not 1
    for _, opPet in pairs(playerData.OPPets or {}) do
        if opPet.FinalBoost then
            opPetBoostMultiplier = opPetBoostMultiplier + (opPet.FinalBoost - 1)
        elseif opPet.BaseBoost then
            opPetBoostMultiplier = opPetBoostMultiplier + (opPet.BaseBoost - 1)
        end
    end
    
    -- Gamepass boost calculation
    local gamepassMultiplier = 1
    local gamepasses = {}
    for _, gamepassName in pairs(playerData.OwnedGamepasses or {}) do
        gamepasses[gamepassName] = true
    end
    
    if gamepasses["TwoXMoney"] then
        gamepassMultiplier = gamepassMultiplier * 2
    end
    if gamepasses["VIP"] then
        gamepassMultiplier = gamepassMultiplier * 2
    end
    
    -- Calculate rebirth multiplier
    local playerRebirths = playerData.Resources and playerData.Resources.Rebirths or 0
    local rebirthMultiplier = 1 + (playerRebirths * 0.5)
    
    -- Total boost calculation: base 1x + pet boost + OP pet boost + gamepass bonus + rebirth bonus (all additive)
    local totalBoostMultiplier = 1 + petBoostMultiplier + opPetBoostMultiplier + (gamepassMultiplier - 1) + (rebirthMultiplier - 1)
    
    -- Responsive button setup
    local screenSize = ScreenUtils.getScreenSize()
    local screenHeight = screenSize.Y
    local buttonPixelSize = screenHeight * 0.07 -- 7% of screen height for buttons
    local spacingPixelSize = screenHeight * 0.04 -- 4% of screen height for spacing
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
            Size = ScreenUtils.udim2(0, 24, 0, 16),
            Position = ScreenUtils.udim2(1, -12, 0, -2),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundColor3 = Color3.fromRGB(255, 100, 100),
            BorderSizePixel = 0,
            ZIndex = 52
        }, {
            UICorner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, 8)
            }),
            CountText = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = petCountText,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                TextSize = 10,
                Font = Enum.Font.GothamBold,
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
    
    -- 5. Debug
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
                Font = Enum.Font.GothamBold,
                TextScaled = true,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 53
            })
        })
    })
    
    -- Convert array to React children object
    local children = {
        UIListLayout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, spacingPixelSize),
            SortOrder = Enum.SortOrder.Name
        })
    }
    
    -- Add buttons to children in alphabetical order for Name sorting
    children["A_Gamepasses"] = buttons[1]  -- Gamepasses
    children["B_Pets"] = buttons[2]  -- Pets  
    children["C_Index"] = buttons[3]  -- Index
    children["D_Rebirth"] = buttons[4]  -- Rebirth
    children["E_Debug"] = buttons[5]  -- Debug
    children["F_Boost"] = buttons[6]  -- Boost
    
    return React.createElement("Frame", {
        Name = "SideBar",
        Size = ScreenUtils.udim2(0, buttonPixelSize + 20, 1, 0),
        Position = ScreenUtils.udim2(0, 10, 0, 0),
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