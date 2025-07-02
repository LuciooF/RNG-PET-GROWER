-- Pet Card Component
-- Displays individual pet with emoji, name, rarity, and collection info

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.react)
local e = React.createElement

local function PetCard(props)
    local petData = props.petData
    local onClick = props.onClick or function() end
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    local isMobile = screenSize.X < 768
    local scale = isMobile and 0.8 or 1
    
    -- Pet emojis based on name (fallback system)
    local petEmojis = {
        ["Mighty Duck"] = "🦆",
        ["Golden Duck"] = "🦆",
        ["Fire Duck"] = "🦆",
        ["Ice Duck"] = "🧊",
        ["Shadow Duck"] = "🌑"
    }
    
    -- Rarity colors (matching your theme)
    local rarityColors = {
        [1] = Color3.fromRGB(255, 255, 255), -- White - Basic
        [2] = Color3.fromRGB(100, 255, 100), -- Green - Advanced  
        [3] = Color3.fromRGB(100, 150, 255), -- Blue - Premium
        [4] = Color3.fromRGB(200, 100, 255), -- Purple - Elite
        [5] = Color3.fromRGB(255, 215, 0)    -- Gold - Master
    }
    
    -- Rarity names
    local rarityNames = {
        [1] = "BASIC",
        [2] = "ADVANCED", 
        [3] = "PREMIUM",
        [4] = "ELITE",
        [5] = "MASTER"
    }
    
    local emoji = petEmojis[petData.name] or "🐾"
    local rarityColor = rarityColors[petData.rarity] or Color3.fromRGB(255, 255, 255)
    local rarityName = rarityNames[petData.rarity] or "UNKNOWN"
    
    -- Format collection time
    local collectedTime = ""
    if petData.collectedAt then
        local timeAgo = tick() - petData.collectedAt
        if timeAgo < 60 then
            collectedTime = math.floor(timeAgo) .. "s ago"
        elseif timeAgo < 3600 then
            collectedTime = math.floor(timeAgo / 60) .. "m ago"
        else
            collectedTime = math.floor(timeAgo / 3600) .. "h ago"
        end
    end
    
    return e("TextButton", {
        Name = "PetCard_" .. petData.name:gsub(" ", "_"),
        Size = UDim2.new(0, 110 * scale, 0, 140 * scale),
        BackgroundColor3 = Color3.fromRGB(40, 45, 50),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        ZIndex = 10,
        [React.Event.Activated] = function()
            onClick(petData)
        end,
        [React.Event.MouseEnter] = function(gui)
            -- Hover effect
            gui.BackgroundColor3 = Color3.fromRGB(50, 55, 60)
        end,
        [React.Event.MouseLeave] = function(gui)
            gui.BackgroundColor3 = Color3.fromRGB(40, 45, 50)
        end
    }, {
        Corner = e("UICorner", {
            CornerRadius = UDim.new(0, 8)
        }),
        
        Stroke = e("UIStroke", {
            Color = rarityColor,
            Thickness = 2,
            Transparency = 0.3
        }),
        
        -- Pet Emoji
        EmojiLabel = e("TextLabel", {
            Name = "Emoji",
            Size = UDim2.new(1, 0, 0, 40 * scale),
            Position = UDim2.new(0, 0, 0, 5),
            Text = emoji,
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansBold,
            ZIndex = 11
        }),
        
        -- Pet Name
        NameLabel = e("TextLabel", {
            Name = "PetName",
            Size = UDim2.new(1, -6, 0, 25 * scale),
            Position = UDim2.new(0, 3, 0, 45 * scale),
            Text = petData.name:upper(),
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansBold,
            ZIndex = 11
        }),
        
        -- Rarity
        RarityLabel = e("TextLabel", {
            Name = "Rarity",
            Size = UDim2.new(1, -6, 0, 18 * scale),
            Position = UDim2.new(0, 3, 0, 70 * scale),
            Text = rarityName,
            TextColor3 = rarityColor,
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansBold,
            ZIndex = 11
        }),
        
        -- Value
        ValueLabel = e("TextLabel", {
            Name = "Value",
            Size = UDim2.new(1, -6, 0, 16 * scale),
            Position = UDim2.new(0, 3, 0, 88 * scale),
            Text = "💰 " .. (petData.value or 1),
            TextColor3 = Color3.fromRGB(100, 255, 100),
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSans,
            ZIndex = 11
        }),
        
        -- Collection Time
        TimeLabel = collectedTime ~= "" and e("TextLabel", {
            Name = "CollectedTime",
            Size = UDim2.new(1, -6, 0, 14 * scale),
            Position = UDim2.new(0, 3, 0, 104 * scale),
            Text = collectedTime,
            TextColor3 = Color3.fromRGB(180, 180, 180),
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSans,
            ZIndex = 11
        }) or nil,
        
        -- Plot Badge (showing which plot it came from)
        PlotBadge = petData.plotId and e("Frame", {
            Name = "PlotBadge",
            Size = UDim2.new(0, 25 * scale, 0, 25 * scale),
            Position = UDim2.new(1, -30 * scale, 0, 5),
            BackgroundColor3 = Color3.fromRGB(100, 150, 255),
            BorderSizePixel = 0,
            ZIndex = 12
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0.5, 0)
            }),
            
            PlotText = e("TextLabel", {
                Name = "PlotText",
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                Text = tostring(petData.plotId),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 13
            })
        }) or nil
    })
end

return PetCard