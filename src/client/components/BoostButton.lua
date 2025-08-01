-- BoostButton - React component for boost icon in bottom-left
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.react)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local DataSyncService = require(script.Parent.Parent.services.DataSyncService)

local function BoostButton(props)
    -- Subscribe to player data for boost calculation
    local playerData, setPlayerData = React.useState({
        EquippedPets = {},
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
    
    -- Total boost (simple addition - pet boost + gamepass boost) 
    totalBoostMultiplier = petBoostMultiplier + gamepassMultiplier
    
    local buttonSize = ScreenUtils.SIZES.SIDE_BUTTON_WIDTH() -- Get actual button size for centering
    
    return React.createElement("Frame", {
        Name = "BoostButtonContainer",
        Size = UDim2.new(0, 80, 0, 90),
        Position = UDim2.new(0, 10, 1, -100), -- Bottom-left corner
        BackgroundTransparency = 1,
        ZIndex = 100,
    }, {
        BoostButton = React.createElement("ImageButton", {
            Name = "BoostButton",
            Size = buttonSize,
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1, -- No background
            Image = IconAssets.getIcon("UI", "BOOST"),
            ScaleType = Enum.ScaleType.Fit,
            SizeConstraint = Enum.SizeConstraint.RelativeYY, -- Same constraint as sidebar icons
            ZIndex = 101,
            [React.Event.MouseButton1Click] = props.onClick,
        }),
        
        BoostLabel = React.createElement("TextLabel", {
            Name = "BoostLabel",
            Size = UDim2.new(0, 80, 0, 24), -- Slightly taller for bigger text
            Position = UDim2.new(0, (buttonSize.X.Offset - 80) / 2, 1, -28), -- Properly centered relative to button width
            BackgroundTransparency = 1, -- No background
            Font = Enum.Font.GothamBold,
            Text = string.format("%.2fx", totalBoostMultiplier),
            TextColor3 = Color3.fromRGB(255, 255, 100), -- Yellow for boost
            TextSize = ScreenUtils.TEXT_SIZES.LARGE(), -- Bigger text
            TextStrokeTransparency = 0,
            TextStrokeColor3 = Color3.fromRGB(0, 0, 0), -- Black outline
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 102,
        })
    })
end

return BoostButton