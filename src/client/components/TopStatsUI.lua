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
        }
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
                    Size = ScreenUtils.udim2(0, 48, 0, 48), -- BIGGER icon
                    BackgroundTransparency = 1,
                    Image = IconAssets.getIcon("CURRENCY", "DIAMONDS"),
                    ScaleType = Enum.ScaleType.Fit,
                    SizeConstraint = Enum.SizeConstraint.RelativeYY
                }),
                
                DiamondsLabel = React.createElement("TextLabel", {
                    Name = "DiamondsLabel",
                    Size = ScreenUtils.udim2(0, 120, 0, 48),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextSize = ScreenUtils.TEXT_SIZES.TITLE(), -- BIGGER text
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    Text = formatNumber(playerData.Resources.Diamonds),
                    TextXAlignment = Enum.TextXAlignment.Left
                })
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
                    Size = ScreenUtils.udim2(0, 60, 0, 60), -- LARGEST icon
                    BackgroundTransparency = 1,
                    Image = IconAssets.getIcon("CURRENCY", "MONEY"),
                    ScaleType = Enum.ScaleType.Fit,
                    SizeConstraint = Enum.SizeConstraint.RelativeYY
                }),
                
                MoneyLabel = React.createElement("TextLabel", {
                    Name = "MoneyLabel",
                    Size = ScreenUtils.udim2(0, 145, 0, 60),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextSize = math.max(28, ScreenUtils.TEXT_SIZES.TITLE() * 1.3), -- BIGGEST text for main currency
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    Text = formatNumber(playerData.Resources.Money),
                    TextXAlignment = Enum.TextXAlignment.Left
                })
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
                    Size = ScreenUtils.udim2(0, 48, 0, 48), -- BIGGER icon
                    BackgroundTransparency = 1,
                    Image = IconAssets.getIcon("UI", "REBIRTH"),
                    ScaleType = Enum.ScaleType.Fit,
                    SizeConstraint = Enum.SizeConstraint.RelativeYY
                }),
                
                RebirthsLabel = React.createElement("TextLabel", {
                    Name = "RebirthsLabel",
                    Size = ScreenUtils.udim2(0, 120, 0, 48),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextSize = ScreenUtils.TEXT_SIZES.TITLE(), -- BIGGER text
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    Text = formatNumber(playerData.Resources.Rebirths),
                    TextXAlignment = Enum.TextXAlignment.Left
                })
            })
        })
    })
end

return TopStatsUI