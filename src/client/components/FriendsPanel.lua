-- Friends Panel Component
-- UI matching the codes panel style for friends invites and boost info

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local ScreenUtils = require(game:GetService("ReplicatedStorage").utils.ScreenUtils)
local assets = require(game:GetService("ReplicatedStorage").assets)
local ClickOutsideWrapper = require(script.Parent.ClickOutsideWrapper)
local e = React.createElement

local function FriendsPanel(props)
    local visible = props.visible
    local onClose = props.onClose
    local playerData = props.playerData
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    -- Responsive sizing (same as codes panel)
    local panelWidth = math.min(screenSize.X * 0.85, ScreenUtils.getProportionalSize(screenSize, 400))
    local panelHeight = math.min(screenSize.Y * 0.6, ScreenUtils.getProportionalSize(screenSize, 400))
    
    -- Text sizing
    local titleTextSize = ScreenUtils.getProportionalTextSize(screenSize, 28)
    local normalTextSize = ScreenUtils.getProportionalTextSize(screenSize, 18)
    local buttonTextSize = ScreenUtils.getProportionalTextSize(screenSize, 16)
    
    -- Button sizing
    local buttonWidth = ScreenUtils.getProportionalSize(screenSize, 200)
    local buttonHeight = math.max(44, ScreenUtils.getProportionalSize(screenSize, 45))
    
    -- Calculate friends count and boost
    local friendsCount = 0
    if playerData and playerData.friends then
        friendsCount = #playerData.friends
    end
    local friendsBoost = friendsCount * 100 -- 100% per friend
    
    local function inviteFriends()
        -- Use Roblox's built-in invite friends functionality
        local SocialService = game:GetService("SocialService")
        local success, result = pcall(function()
            return SocialService:PromptGameInvite(game.Players.LocalPlayer)
        end)
        
        if not success then
            warn("Failed to open invite friends UI:", result)
        end
    end
    
    return e(ClickOutsideWrapper, {
        visible = visible,
        onClose = onClose
    }, {
        Container = e("Frame", {
            Name = "FriendsContainer",
            Size = UDim2.new(0, panelWidth, 0, panelHeight + 100),
            Position = UDim2.new(0.5, -panelWidth / 2, 0.5, -(panelHeight + 100) / 2),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 30
        }, {
            
            FriendsPanel = e("Frame", {
                Name = "FriendsPanel",
                Size = UDim2.new(0, panelWidth, 0, panelHeight),
                Position = UDim2.new(0, 0, 0, 100),
                BackgroundColor3 = Color3.fromRGB(255, 248, 220), -- Cream/gold color matching codes
                BackgroundTransparency = 0.05,
                BorderSizePixel = 0,
                ZIndex = 31
            }, {
                UICorner = e("UICorner", {
                    CornerRadius = UDim.new(0, 15)
                }),
                
                UIStroke = e("UIStroke", {
                    Color = Color3.fromRGB(218, 165, 32), -- Gold border
                    Thickness = 3
                }),
                
                -- Header Section
                Header = e("Frame", {
                    Name = "Header",
                    Size = UDim2.new(1, -20, 0, 60),
                    Position = UDim2.new(0, 10, 0, 10),
                    BackgroundTransparency = 1,
                    ZIndex = 32
                }, {
                    Title = e("TextLabel", {
                        Name = "Title",
                        Size = UDim2.new(1, -50, 1, 0),
                        Position = UDim2.new(0, 0, 0, 0),
                        BackgroundTransparency = 1,
                        Text = "Friends",
                        TextColor3 = Color3.fromRGB(184, 134, 11), -- Dark gold
                        TextScaled = false,
                        TextSize = titleTextSize,
                        Font = Enum.Font.SourceSansBold,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        ZIndex = 33
                    }),
                    
                    CloseButton = e("TextButton", {
                        Name = "CloseButton",
                        Size = UDim2.new(0, 40, 0, 40),
                        Position = UDim2.new(1, -40, 0, 10),
                        BackgroundColor3 = Color3.fromRGB(255, 100, 100),
                        BorderSizePixel = 0,
                        Text = "✕",
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextScaled = false,
                        TextSize = 20,
                        Font = Enum.Font.SourceSansBold,
                        ZIndex = 33,
                        [React.Event.Activated] = onClose
                    }, {
                        UICorner = e("UICorner", {
                            CornerRadius = UDim.new(0, 8)
                        })
                    })
                }),
                
                -- Content Section
                Content = e("Frame", {
                    Name = "Content",
                    Size = UDim2.new(1, -40, 1, -120),
                    Position = UDim2.new(0, 20, 0, 80),
                    BackgroundTransparency = 1,
                    ZIndex = 32
                }, {
                    UIListLayout = e("UIListLayout", {
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        FillDirection = Enum.FillDirection.Vertical,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Top,
                        Padding = UDim.new(0, 20)
                    }),
                    
                    -- Friends info text
                    InfoText = e("TextLabel", {
                        Name = "InfoText",
                        Size = UDim2.new(1, 0, 0, normalTextSize * 2),
                        BackgroundTransparency = 1,
                        Text = "Each friend that joins you gives you 100% boost",
                        TextColor3 = Color3.fromRGB(70, 70, 70),
                        TextScaled = false,
                        TextSize = normalTextSize,
                        Font = Enum.Font.SourceSans,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        TextWrapped = true,
                        LayoutOrder = 1,
                        ZIndex = 33
                    }),
                    
                    -- Current friends and boost display
                    StatsFrame = e("Frame", {
                        Name = "StatsFrame",
                        Size = UDim2.new(1, 0, 0, normalTextSize * 3),
                        BackgroundTransparency = 1,
                        LayoutOrder = 2,
                        ZIndex = 33
                    }, {
                        UIListLayout = e("UIListLayout", {
                            SortOrder = Enum.SortOrder.LayoutOrder,
                            FillDirection = Enum.FillDirection.Vertical,
                            HorizontalAlignment = Enum.HorizontalAlignment.Center,
                            VerticalAlignment = Enum.VerticalAlignment.Center,
                            Padding = UDim.new(0, 5)
                        }),
                        
                        FriendsCount = e("TextLabel", {
                            Name = "FriendsCount",
                            Size = UDim2.new(1, 0, 0, normalTextSize + 5),
                            BackgroundTransparency = 1,
                            Text = string.format("Friends Online: %d", friendsCount),
                            TextColor3 = Color3.fromRGB(184, 134, 11),
                            TextScaled = false,
                            TextSize = normalTextSize,
                            Font = Enum.Font.SourceSansSemibold,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            TextYAlignment = Enum.TextYAlignment.Center,
                            LayoutOrder = 1,
                            ZIndex = 34
                        }),
                        
                        BoostDisplay = e("TextLabel", {
                            Name = "BoostDisplay",
                            Size = UDim2.new(1, 0, 0, normalTextSize + 5),
                            BackgroundTransparency = 1,
                            Text = string.format("Current Boost: +%d%%", friendsBoost),
                            TextColor3 = Color3.fromRGB(34, 139, 34), -- Green for boost
                            TextScaled = false,
                            TextSize = normalTextSize,
                            Font = Enum.Font.SourceSansBold,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            TextYAlignment = Enum.TextYAlignment.Center,
                            LayoutOrder = 2,
                            ZIndex = 34
                        })
                    }),
                    
                    -- Invite Friends Button
                    InviteButton = e("TextButton", {
                        Name = "InviteButton",
                        Size = UDim2.new(0, buttonWidth, 0, buttonHeight),
                        BackgroundColor3 = Color3.fromRGB(34, 139, 34), -- Green
                        BorderSizePixel = 0,
                        Text = "Invite Friends",
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextScaled = false,
                        TextSize = buttonTextSize,
                        Font = Enum.Font.SourceSansBold,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        LayoutOrder = 3,
                        ZIndex = 34,
                        [React.Event.Activated] = inviteFriends
                    }, {
                        UICorner = e("UICorner", {
                            CornerRadius = UDim.new(0, 8)
                        }),
                        
                        UIStroke = e("UIStroke", {
                            Color = Color3.fromRGB(25, 100, 25),
                            Thickness = 2
                        })
                    })
                })
            })
        })
    })
end

return FriendsPanel