-- BoostPanel - React component for detailed boost breakdown display
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.react)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)
local DataSyncService = require(script.Parent.Parent.services.DataSyncService)

local function BoostPanel(props)
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
    
    -- Calculate boost breakdown
    local petBoostMultiplier = 1
    local petCount = 0
    
    for _, pet in pairs(playerData.EquippedPets or {}) do
        petCount = petCount + 1
        if pet.FinalBoost then
            petBoostMultiplier = petBoostMultiplier + (pet.FinalBoost - 1) -- Convert 1.36x to 0.36, then add
        end
    end
    
    -- Calculate gamepass boost
    local gamepassMultiplier = 1
    local gamepasses = {}
    local gamepassNames = {}
    
    for _, gamepassName in pairs(playerData.OwnedGamepasses or {}) do
        gamepasses[gamepassName] = true
    end
    
    if gamepasses.TwoXMoney then
        gamepassMultiplier = gamepassMultiplier * 2
        table.insert(gamepassNames, "2x Money")
    end
    
    if gamepasses.VIP then
        gamepassMultiplier = gamepassMultiplier * 2
        table.insert(gamepassNames, "VIP")
    end
    
    -- Total boost (simple addition - pet boost + gamepass boost)
    local totalMultiplier = petBoostMultiplier + gamepassMultiplier
    
    -- Don't render if not visible
    if not props.visible then
        return nil
    end
    
    -- Create click-outside-to-close overlay
    return React.createElement("TextButton", {
        Name = "BoostPanelOverlay",
        Size = UDim2.new(1, 0, 1, 0), -- Full screen overlay
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1, -- Invisible overlay
        Text = "", -- No text
        ZIndex = 199,
        [React.Event.MouseButton1Click] = props.onClose, -- Click anywhere to close
    }, {
        BoostPanel = React.createElement("TextButton", {
            Name = "BoostPanel",
            Size = ScreenUtils.udim2(0, 320, 0, 180), -- Much bigger size for better readability
            Position = ScreenUtils.udim2(0, 100, 1, -200), -- Adjusted positioning for bigger panel
            BackgroundColor3 = Color3.fromRGB(255, 255, 255), -- White background like Pets UI
            BackgroundTransparency = 0,
            Text = "", -- No text
            ZIndex = 200,
            [React.Event.MouseButton1Click] = function()
                -- Prevent click from bubbling up to overlay (don't close panel when clicking on it)
            end,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, 15), -- Bigger responsive corner radius
            }),
            
            PanelOutline = React.createElement("UIStroke", {
                Thickness = 4,
                Color = Color3.fromRGB(0, 0, 0), -- Black outline for the white panel
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }),
            
            -- Background pattern like Pets UI
            BackgroundPattern = React.createElement("ImageLabel", {
                Name = "BackgroundPattern",
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                Image = "rbxassetid://116367512866072",
                ImageTransparency = 0.95, -- Very faint background
                ScaleType = Enum.ScaleType.Tile,
                TileSize = UDim2.new(0, 50, 0, 50),
                ZIndex = 199, -- Behind text but above panel background
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 15),
                }),
            }),
        
            -- Title label (shows total boost)
            TitleLabel = React.createElement("TextLabel", {
                Name = "TitleLabel",
                Size = ScreenUtils.udim2(1, -30, 0, 40), -- Bigger responsive size
                Position = ScreenUtils.udim2(0, 15, 0, 12), -- More padding
                BackgroundTransparency = 1,
                Text = string.format("💪 Total Boost: %.2fx", totalMultiplier),
                TextColor3 = totalMultiplier > 1 and Color3.fromRGB(64, 224, 208) or Color3.fromRGB(100, 100, 100), -- Turquoise like Pets UI
                TextSize = ScreenUtils.TEXT_SIZES.HEADER(), -- Bigger text size for title
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center, -- Centered text
                TextYAlignment = Enum.TextYAlignment.Center,
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0), -- Black outline
                ZIndex = 201,
            }),
        
            -- Pet boost value label
            PetBoostLabel = React.createElement("TextLabel", {
                Name = "PetBoostLabel",
                Size = ScreenUtils.udim2(1, -30, 0, 32), -- Bigger responsive size
                Position = ScreenUtils.udim2(0, 15, 0, 58), -- More spacing
                BackgroundTransparency = 1,
                Text = string.format("🐾 Pets: %.2fx", petBoostMultiplier),
                TextColor3 = petBoostMultiplier > 1 and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(120, 120, 120),
                TextSize = ScreenUtils.TEXT_SIZES.LARGE(), -- Bigger text size
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center, -- Centered text
                TextYAlignment = Enum.TextYAlignment.Center,
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0), -- Black outline
                ZIndex = 201,
            }),
        
            -- Gamepass boost value label
            GamepassBoostLabel = React.createElement("TextLabel", {
                Name = "GamepassBoostLabel",
                Size = ScreenUtils.udim2(1, -30, 0, 32), -- Bigger responsive size
                Position = ScreenUtils.udim2(0, 15, 0, 96), -- More spacing
                BackgroundTransparency = 1,
                Text = gamepassMultiplier > 1 and 
                    string.format("💎 Gamepasses: %.1fx (%s)", gamepassMultiplier, table.concat(gamepassNames, " + ")) or 
                    "💎 Gamepasses: 1x",
                TextColor3 = gamepassMultiplier > 1 and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(120, 120, 120),
                TextSize = ScreenUtils.TEXT_SIZES.LARGE(), -- Bigger text size
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center, -- Centered text
                TextYAlignment = Enum.TextYAlignment.Center,
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0), -- Black outline
                ZIndex = 201,
            }),
        
            -- Pet count label
            PetCountLabel = React.createElement("TextLabel", {
                Name = "PetCountLabel",
                Size = ScreenUtils.udim2(1, -30, 0, 25), -- Bigger responsive size
                Position = ScreenUtils.udim2(0, 15, 1, -35), -- More spacing from bottom
                BackgroundTransparency = 1,
                Text = petCount == 1 and "📊 1 pet equipped" or "📊 " .. petCount .. " pets equipped",
                TextColor3 = Color3.fromRGB(80, 80, 80), -- Darker gray for better readability
                TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(), -- Bigger text size
                Font = Enum.Font.GothamBold, -- Bold font for better visibility
                TextXAlignment = Enum.TextXAlignment.Center, -- Centered text
                TextYAlignment = Enum.TextYAlignment.Center,
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0), -- Black outline
                ZIndex = 201,
            })
        })
    })
end

return BoostPanel