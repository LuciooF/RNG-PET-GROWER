-- BoostButton - React component for boost icon in bottom-left
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.react)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)
local DataSyncService = require(script.Parent.Parent.services.DataSyncService)

local function BoostButton(props)
    -- Subscribe to player data for boost calculation
    local playerData, setPlayerData = React.useState({
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
    
    -- Calculate total boost
    local totalBoostMultiplier = 1
    
    -- Pet boost calculation
    local petBoostMultiplier = 1
    for _, pet in pairs(playerData.EquippedPets or {}) do
        if pet.FinalBoost then
            petBoostMultiplier = petBoostMultiplier + (pet.FinalBoost - 1)
        end
    end
    
    -- OP Pet boost calculation
    local opPetBoostMultiplier = 1
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
    
    if gamepasses.TwoXMoney then
        gamepassMultiplier = gamepassMultiplier * 2
    end
    
    if gamepasses.VIP then
        gamepassMultiplier = gamepassMultiplier * 2
    end
    
    -- Total boost (simple addition - pet boost + OP pet boost + gamepass boost) 
    totalBoostMultiplier = petBoostMultiplier + opPetBoostMultiplier + gamepassMultiplier - 1 -- Subtract 1 to avoid double counting base
    
    -- Use same mobile DPI compensation as SideBar
    local screenSize = ScreenUtils.getScreenSize()
    local screenHeight = screenSize.Y
    local isMobile = screenHeight < 500
    
    -- Button sizing with mobile compensation
    local buttonPercent = isMobile and 0.095 or 0.065
    local buttonPixelSize = screenHeight * buttonPercent
    local buttonSize = UDim2.new(0, buttonPixelSize, 0, buttonPixelSize)
    
    -- Container sizing and positioning
    local containerWidth = buttonPixelSize + (isMobile and 20 or 10)
    local containerHeight = buttonPixelSize + (isMobile and 50 or 30) -- Extra space for text
    local bottomMargin = isMobile and screenHeight * 0.05 or screenHeight * 0.03
    
    -- Text spacing below button
    local textSpacing = isMobile and buttonPixelSize * 0.3 or buttonPixelSize * 0.2
    
    return React.createElement("Frame", {
        Name = "BoostButtonContainer",
        Size = UDim2.new(0, containerWidth, 0, containerHeight),
        Position = UDim2.new(0, 10, 1, -bottomMargin), -- Better bottom positioning
        BackgroundTransparency = 1,
        ZIndex = 100,
    }, {
        BoostButton = React.createElement("ImageButton", {
            Name = "BoostButton",
            Size = buttonSize,
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Image = IconAssets.getIcon("UI", "BOOST"),
            ScaleType = Enum.ScaleType.Fit,
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            ZIndex = 101,
            [React.Event.MouseButton1Click] = props.onClick,
        }),
        
        BoostLabel = React.createElement("TextLabel", {
            Name = "BoostLabel",
            Size = UDim2.new(0, containerWidth, 0, isMobile and 35 or 25),
            Position = UDim2.new(0, 0, 0, buttonPixelSize + textSpacing), -- Below button with proper spacing
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            Text = string.format("%sx", NumberFormatter.formatBoost(totalBoostMultiplier)),
            TextColor3 = Color3.fromRGB(255, 255, 100),
            TextSize = isMobile and ScreenUtils.TEXT_SIZES.LARGE() * 1.2 or ScreenUtils.TEXT_SIZES.LARGE(),
            TextStrokeTransparency = 0,
            TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 102,
        })
    })
end

return BoostButton