-- TopStatsUI - Displays player resources at the top of the screen
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")

local React = require(ReplicatedStorage.Packages.react)
local DataSyncService = require(script.Parent.Parent.services.DataSyncService)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)

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
    
    -- Subscribe to data changes
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
        
        return unsubscribe
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
            Size = ScreenUtils.udim2(0, 800, 0, 100), -- BIGGER responsive size
            Position = UDim2.new(0.5, 0, 0, 5), -- Very top, just 5px from absolute top
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1, -- No background
            ZIndex = 10
        }, {
            UIListLayout = React.createElement("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = ScreenUtils.udim(0, 50) -- BIGGER padding between stats
            }),
            
            -- Diamonds Display (BIGGER, left side)
            DiamondsFrame = React.createElement("Frame", {
                Name = "DiamondsFrame",
                Size = ScreenUtils.udim2(0, 180, 0, 80), -- BIGGER size
                BackgroundTransparency = 1
            }, {
                UIListLayout = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = ScreenUtils.udim(0, 12)
                }),
                
                DiamondsIcon = React.createElement("ImageLabel", {
                    Name = "DiamondsIcon",
                    Size = ScreenUtils.udim2(0, 55, 0, 55), -- Even bigger icon
                    BackgroundTransparency = 1,
                    Image = IconAssets.getIcon("CURRENCY", "DIAMONDS"),
                    ScaleType = Enum.ScaleType.Fit,
                    SizeConstraint = Enum.SizeConstraint.RelativeYY
                }),
                
                DiamondsLabel = React.createElement("TextLabel", {
                    Name = "DiamondsLabel",
                    Size = ScreenUtils.udim2(0, 120, 0, 55),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextSize = ScreenUtils.TEXT_SIZES.TITLE() + 4, -- Even bigger text
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    Text = formatNumber(playerData.Resources.Diamonds),
                    TextXAlignment = Enum.TextXAlignment.Left
                }, shouldBeRainbow("Diamonds") and {
                    Rainbow = React.createElement("UIGradient", {
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
                    })
                } or nil)
            }),
            
            -- Money Display (LARGEST, center)
            MoneyFrame = React.createElement("Frame", {
                Name = "MoneyFrame",
                Size = ScreenUtils.udim2(0, 220, 0, 100), -- LARGEST size for main currency
                BackgroundTransparency = 1
            }, {
                UIListLayout = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = ScreenUtils.udim(0, 15)
                }),
                
                MoneyIcon = React.createElement("ImageLabel", {
                    Name = "MoneyIcon",
                    Size = ScreenUtils.udim2(0, 70, 0, 70), -- Even larger icon
                    BackgroundTransparency = 1,
                    Image = IconAssets.getIcon("CURRENCY", "MONEY"),
                    ScaleType = Enum.ScaleType.Fit,
                    SizeConstraint = Enum.SizeConstraint.RelativeYY
                }),
                
                MoneyLabel = React.createElement("TextLabel", {
                    Name = "MoneyLabel",
                    Size = ScreenUtils.udim2(0, 145, 0, 70),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextSize = math.max(32, ScreenUtils.TEXT_SIZES.TITLE() * 1.5), -- Even bigger text for main currency
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    Text = formatNumber(playerData.Resources.Money),
                    TextXAlignment = Enum.TextXAlignment.Left
                }, shouldBeRainbow("Money") and {
                    Rainbow = React.createElement("UIGradient", {
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
                    })
                } or nil)
            }),
            
            -- Rebirths Display (BIGGER, right side)
            RebirthsFrame = React.createElement("Frame", {
                Name = "RebirthsFrame",
                Size = ScreenUtils.udim2(0, 180, 0, 80), -- BIGGER size
                BackgroundTransparency = 1
            }, {
                UIListLayout = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = ScreenUtils.udim(0, 12)
                }),
                
                RebirthsIcon = React.createElement("ImageLabel", {
                    Name = "RebirthsIcon",
                    Size = ScreenUtils.udim2(0, 55, 0, 55), -- Even bigger icon
                    BackgroundTransparency = 1,
                    Image = IconAssets.getIcon("UI", "REBIRTH"),
                    ScaleType = Enum.ScaleType.Fit,
                    SizeConstraint = Enum.SizeConstraint.RelativeYY
                }),
                
                RebirthsLabel = React.createElement("TextLabel", {
                    Name = "RebirthsLabel",
                    Size = ScreenUtils.udim2(0, 120, 0, 55),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextSize = ScreenUtils.TEXT_SIZES.TITLE() + 4, -- Even bigger text
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    Text = formatNumber(playerData.Resources.Rebirths),
                    TextXAlignment = Enum.TextXAlignment.Left
                }, shouldBeRainbow("Rebirths") and {
                    Rainbow = React.createElement("UIGradient", {
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
                    })
                } or nil)
            })
        })
    })
end

return TopStatsUI