-- TopStatsUI - Displays player resources at the top of the screen
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")

local React = require(ReplicatedStorage.Packages.react)
local store = require(ReplicatedStorage.store)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local SoundService = game:GetService("SoundService")

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

local player = Players.LocalPlayer

local function TopStatsUI()
    local playerData, setPlayerData = React.useState({
        Resources = {
            Money = 0,
            Diamonds = 0,
            Rebirths = 0
        },
        OwnedGamepasses = {}
    })
    
    -- Subscribe directly to Rodux store changes
    React.useEffect(function()
        -- Get initial data from store
        local initialState = store:getState()
        if initialState.player then
            setPlayerData(initialState.player)
            print("TopStatsUI: Initial data loaded - Money:", initialState.player.Resources.Money, "Diamonds:", initialState.player.Resources.Diamonds)
        end
        
        -- Subscribe to store changes
        local unsubscribe = store.changed:connect(function(newState, oldState)
            if newState.player then
                setPlayerData(newState.player)
                -- State updated, refreshing display
            end
        end)
        
        return function()
            unsubscribe()
        end
    end, {})
    
    -- Check if player owns a specific gamepass
    local function ownsGamepass(gamepassName)
        if not playerData.OwnedGamepasses then return false end
        for _, ownedGamepass in pairs(playerData.OwnedGamepasses) do
            if ownedGamepass == gamepassName then
                return true
            end
        end
        return false
    end
    
    -- Determine if text should be rainbow based on gamepass ownership
    local function shouldBeRainbow(statType)
        local ownsVIP = ownsGamepass("VIP")
        local owns2xMoney = ownsGamepass("2X_MONEY")
        local owns2xDiamonds = ownsGamepass("2X_DIAMONDS")
        
        if ownsVIP then
            return true -- VIP makes everything rainbow
        elseif statType == "Money" and owns2xMoney then
            return true
        elseif statType == "Diamonds" and owns2xDiamonds then
            return true
        end
        return false
    end
    
    -- Format numbers for display with better prettification
    local function formatNumber(num)
        if num >= 1000000000000 then
            return string.format("%.1fT", num / 1000000000000)
        elseif num >= 1000000000 then
            return string.format("%.1fB", num / 1000000000)
        elseif num >= 1000000 then
            return string.format("%.1fM", num / 1000000)
        elseif num >= 1000 then
            return string.format("%.1fK", num / 1000)
        else
            return tostring(math.floor(num))
        end
    end
    
    return React.createElement("ScreenGui", {
        Name = "TopStatsUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true -- This allows us to use the Roblox reserved space
    }, {
        -- No background frame - just the stats directly using Roblox reserved space
        Container = React.createElement("Frame", {
            Name = "Container",
            Size = ScreenUtils.udim2(1, 0, 0, 150), -- Full width, bigger height that scales
            Position = UDim2.new(0.5, 0, 0, 5), -- Very top, just 5px from absolute top
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1, -- No background
            ZIndex = 10
        }, {
            UIListLayout = React.createElement("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = ScreenUtils.udim(0, 80), -- Bigger dynamic padding
            }),
            
            -- Diamonds Display
            DiamondsFrame = React.createElement("Frame", {
                Name = "DiamondsFrame",
                Size = ScreenUtils.udim2(0, 300, 0, 120),
                BackgroundTransparency = 1,
                [React.Event.MouseEnter] = function()
                    playHoverSound()
                end
            }, {
                UIListLayout = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = ScreenUtils.udim(0, 18)
                }),
                
                DiamondsIcon = React.createElement("ImageLabel", {
                    Name = "DiamondsIcon",
                    Size = ScreenUtils.udim2(0, 82, 0, 82),
                    BackgroundTransparency = 1,
                    Image = IconAssets.getIcon("CURRENCY", "DIAMONDS"),
                    ScaleType = Enum.ScaleType.Fit,
                    SizeConstraint = Enum.SizeConstraint.RelativeYY
                }),
                
                DiamondsLabel = React.createElement("TextLabel", {
                    Name = "DiamondsLabel",
                    Size = ScreenUtils.udim2(0, 180, 0, 82),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.FredokaOne,
                    TextScaled = true,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    Text = formatNumber(playerData.Resources.Diamonds),
                    TextXAlignment = Enum.TextXAlignment.Left
                }, {
                    UIStroke = React.createElement("UIStroke", {
                        Thickness = 2,
                        Color = Color3.fromRGB(0, 0, 0),
                        Transparency = 0,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
                    }),
                    Rainbow = shouldBeRainbow("Diamonds") and React.createElement("UIGradient", {
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),     -- Red
                            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 165, 0)), -- Orange
                            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)), -- Yellow
                            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),   -- Green
                            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),  -- Blue
                            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)), -- Indigo
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 0, 211))    -- Violet
                        }),
                        Rotation = 0
                    }) or nil
                })
            }),
            
            -- Money Display (center, slightly larger)
            MoneyFrame = React.createElement("Frame", {
                Name = "MoneyFrame",
                Size = ScreenUtils.udim2(0, 375, 0, 150),
                BackgroundTransparency = 1,
                [React.Event.MouseEnter] = function()
                    playHoverSound()
                end
            }, {
                UIListLayout = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = ScreenUtils.udim(0, 22)
                }),
                
                MoneyIcon = React.createElement("ImageLabel", {
                    Name = "MoneyIcon",
                    Size = ScreenUtils.udim2(0, 105, 0, 105),
                    BackgroundTransparency = 1,
                    Image = IconAssets.getIcon("CURRENCY", "MONEY"),
                    ScaleType = Enum.ScaleType.Fit,
                    SizeConstraint = Enum.SizeConstraint.RelativeYY
                }),
                
                MoneyLabel = React.createElement("TextLabel", {
                    Name = "MoneyLabel",
                    Size = ScreenUtils.udim2(0, 225, 0, 105),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.FredokaOne,
                    TextScaled = true,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    Text = formatNumber(playerData.Resources.Money),
                    TextXAlignment = Enum.TextXAlignment.Left
                }, {
                    UIStroke = React.createElement("UIStroke", {
                        Thickness = 2,
                        Color = Color3.fromRGB(0, 0, 0),
                        Transparency = 0,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
                    }),
                    Rainbow = shouldBeRainbow("Money") and React.createElement("UIGradient", {
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),     -- Red
                            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 165, 0)), -- Orange
                            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)), -- Yellow
                            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),   -- Green
                            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),  -- Blue
                            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)), -- Indigo
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 0, 211))    -- Violet
                        }),
                        Rotation = 0
                    }) or nil
                })
            }),
            
            -- Rebirths Display
            RebirthsFrame = React.createElement("Frame", {
                Name = "RebirthsFrame",
                Size = ScreenUtils.udim2(0, 300, 0, 120),
                BackgroundTransparency = 1,
                [React.Event.MouseEnter] = function()
                    playHoverSound()
                end
            }, {
                UIListLayout = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = ScreenUtils.udim(0, 18)
                }),
                
                RebirthsIcon = React.createElement("ImageLabel", {
                    Name = "RebirthsIcon",
                    Size = ScreenUtils.udim2(0, 82, 0, 82),
                    BackgroundTransparency = 1,
                    Image = IconAssets.getIcon("UI", "REBIRTH"),
                    ScaleType = Enum.ScaleType.Fit,
                    SizeConstraint = Enum.SizeConstraint.RelativeYY
                }),
                
                RebirthsLabel = React.createElement("TextLabel", {
                    Name = "RebirthsLabel",
                    Size = ScreenUtils.udim2(0, 180, 0, 82),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.FredokaOne,
                    TextScaled = true,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    Text = formatNumber(playerData.Resources.Rebirths),
                    TextXAlignment = Enum.TextXAlignment.Left
                }, {
                    UIStroke = React.createElement("UIStroke", {
                        Thickness = 2,
                        Color = Color3.fromRGB(0, 0, 0),
                        Transparency = 0,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
                    }),
                    Rainbow = shouldBeRainbow("Rebirths") and React.createElement("UIGradient", {
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),     -- Red
                            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 165, 0)), -- Orange
                            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)), -- Yellow
                            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),   -- Green
                            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),  -- Blue
                            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)), -- Indigo
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 0, 211))    -- Violet
                        }),
                        Rotation = 0
                    }) or nil
                })
            })
        })
    })
end

return TopStatsUI