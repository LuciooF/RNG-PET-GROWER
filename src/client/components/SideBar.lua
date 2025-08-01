-- SideBar - Unified side navigation with all buttons in proper order
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local React = require(ReplicatedStorage.Packages.react)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local TooltipUtils = require(ReplicatedStorage.utils.TooltipUtils)
local DataSyncService = require(script.Parent.Parent.services.DataSyncService)

local function SideBar(props)
    -- Subscribe to player data for pet count
    local playerData, setPlayerData = React.useState({
        Pets = {}
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
    
    -- Simple button setup
    local buttonSize = ScreenUtils.SIZES.SIDE_BUTTON_WIDTH()
    local buttonSpacing = 40 -- 40px spacing between buttons
    
    -- True mathematical center of screen (0.5) - ignoring GUI inset completely
    -- If screen is 200px, center is at pixel 100 (50%)
    local centerY = 0.5
    
    return React.createElement("Frame", {
        Name = "SideBar",
        Size = ScreenUtils.udim2(0, 80, 1, 0), -- Full height container
        Position = ScreenUtils.udim2(0, 10, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 50 -- Above most UI but below modals
    }, {
        -- Button 1: Gamepasses (2 spaces above center)
        GamepassButton = TooltipUtils.createHoverButton({
            Name = "GamepassButton",
            Size = buttonSize,
            Position = UDim2.new(0, 0, centerY, -buttonSpacing * 2),
            BackgroundTransparency = 1,
            Image = IconAssets.getIcon("CURRENCY", "ROBUX"),
            ScaleType = Enum.ScaleType.Fit,
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            [React.Event.Activated] = function()
                if props.onGamepassClick then
                    props.onGamepassClick()
                end
            end
        }, "Gamepasses"),
        
        -- Button 2: Pets (1 space above center) - Custom button with pet count badge
        PetsButtonContainer = React.createElement("Frame", {
            Name = "PetsButtonContainer",
            Size = buttonSize,
            Position = UDim2.new(0, 0, centerY, -buttonSpacing * 1),
            BackgroundTransparency = 1,
            ZIndex = 50
        }, {
            -- Main pets button
            PetsButton = TooltipUtils.createHoverButton({
                Name = "PetsButton",
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
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
            
            -- Pet count badge (always show, even with 0 pets)
            PetCountBadge = React.createElement("Frame", {
                Name = "PetCountBadge",
                Size = UDim2.new(0, 24, 0, 16), -- Small badge
                Position = UDim2.new(1, -12, 0, -2), -- Top-right corner
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundColor3 = Color3.fromRGB(255, 100, 100), -- Red badge
                BorderSizePixel = 0,
                ZIndex = 52
            }, {
                UICorner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 8) -- Rounded badge
                }),
                
                CountText = React.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = petCountText,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextStrokeTransparency = 0, -- Enable text outline
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0), -- Black outline
                    TextSize = 10,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    ZIndex = 53
                })
            })
        }),
        
        -- Button 3: Index (CENTER)
        IndexButton = TooltipUtils.createHoverButton({
            Name = "IndexButton",
            Size = buttonSize,
            Position = UDim2.new(0, 0, centerY, 0),
            BackgroundTransparency = 1,
            Image = IconAssets.getIcon("UI", "INDEX"),
            ScaleType = Enum.ScaleType.Fit,
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            [React.Event.Activated] = function()
                if props.onIndexClick then
                    props.onIndexClick()
                end
            end
        }, "Pet Index"),
        
        -- Button 4: Rebirth (1 space below center)
        RebirthButton = TooltipUtils.createHoverButton({
            Name = "RebirthButton",
            Size = buttonSize,
            Position = UDim2.new(0, 0, centerY, buttonSpacing * 1),
            BackgroundTransparency = 1,
            Image = IconAssets.getIcon("UI", "REBIRTH"),
            ScaleType = Enum.ScaleType.Fit,
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            [React.Event.Activated] = function()
                if props.onRebirthClick then
                    props.onRebirthClick()
                end
            end
        }, "Rebirths"),
        
        -- Button 5: Debug/Settings (2 spaces below center)
        DebugButton = TooltipUtils.createHoverButton({
            Name = "DebugButton",
            Size = buttonSize,
            Position = UDim2.new(0, 0, centerY, buttonSpacing * 2),
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
    })
end

return SideBar