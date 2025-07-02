-- Pet Inventory Panel Component  
-- Modern card-grid layout showing collected pets
-- Adapted from InventoryPanel.lua for pet collection system

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local React = require(ReplicatedStorage.Packages.react)
local e = React.createElement

local PetConfig = require(ReplicatedStorage.Shared.config.PetConfig)

-- Utility functions for responsive design
local function getProportionalScale(screenSize)
    local baseScreenSize = Vector2.new(1024, 768)
    return math.min(screenSize.X / baseScreenSize.X, screenSize.Y / baseScreenSize.Y)
end

local function getProportionalSize(screenSize, size)
    return size * getProportionalScale(screenSize)
end

local function getProportionalTextSize(screenSize, size)
    return math.max(12, size * getProportionalScale(screenSize))
end

-- Sound effects (simplified for now)
local function playSound(soundType)
    -- Placeholder for sound effects
end

-- Function to create flip animation for icons
local function createFlipAnimation(iconRef, animationTracker)
    if not iconRef.current then return end
    
    -- Cancel any existing animation for this icon
    if animationTracker.current then
        animationTracker.current:Cancel()
        animationTracker.current:Destroy()
        animationTracker.current = nil
    end
    
    -- Reset rotation to 0 to prevent accumulation
    iconRef.current.Rotation = 0
    
    -- Create new animation
    animationTracker.current = TweenService:Create(
        iconRef.current,
        TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Rotation = 360 }
    )
    
    animationTracker.current:Play()
end

-- Function to create bounce animation for cards
local function createBounceAnimation(cardElement)
    if not cardElement then return end
    
    -- Store the original size since GridLayout controls position
    local originalSize = cardElement.Size
    
    -- Create bounce animation (scale up slightly)
    local bounceUpTween = TweenService:Create(
        cardElement,
        TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { 
            Size = originalSize + UDim2.new(0, 6, 0, 6) -- Grow by 6 pixels each way
        }
    )
    
    bounceUpTween:Play()
    
    -- Create return animation
    bounceUpTween.Completed:Connect(function()
        -- Safety check: make sure the card still exists
        if not cardElement or not cardElement.Parent then return end
        
        local returnTween = TweenService:Create(
            cardElement,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { 
                Size = originalSize -- Return to original size
            }
        )
        returnTween:Play()
    end)
end

local function PetInventoryPanel(props)
    local playerData = props.playerData
    local visible = props.visible or false
    local onClose = props.onClose or function() end
    local remotes = props.remotes or {}
    
    -- Responsive sizing (same as original)
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local scale = getProportionalScale(screenSize)
    local aspectRatio = screenSize.X / screenSize.Y
    
    -- Proportional text sizes
    local titleTextSize = getProportionalTextSize(screenSize, 32)
    local normalTextSize = getProportionalTextSize(screenSize, 18)
    local smallTextSize = getProportionalTextSize(screenSize, 14)
    local buttonTextSize = getProportionalTextSize(screenSize, 16)
    local cardTitleSize = getProportionalTextSize(screenSize, 20)
    local cardValueSize = getProportionalTextSize(screenSize, 16)
    
    -- Panel sizing (exact same as original)
    local panelWidth = math.min(screenSize.X * 0.9, getProportionalSize(screenSize, 900))
    local panelHeight = math.min(screenSize.Y * 0.85, getProportionalSize(screenSize, 600))
    
    -- Calculate grid for pet cards - responsive layout
    local minCardWidth = getProportionalSize(screenSize, 250)
    local cardsPerRow = math.max(2, math.min(4, math.floor((panelWidth - 120) / (minCardWidth + 20))))
    local cardWidth = (panelWidth - 120) / cardsPerRow - 20
    local cardHeight = getProportionalSize(screenSize, 280)
    
    -- Get pets from player data and group by type AND aura
    local petGroups = {}
    
    if playerData.ownedPets then
        for i, pet in ipairs(playerData.ownedPets) do
            local petKey = (pet.name or "Unknown") .. "_" .. (pet.aura or "none")
            if not petGroups[petKey] then
                petGroups[petKey] = {
                    petType = pet,
                    quantity = 0,
                    latestCollectionTime = 0,
                    petConfig = PetConfig:GetPetData(pet.id or 1),
                    aura = pet.aura or "none",
                    auraData = PetConfig.AURAS[pet.aura or "none"] or PetConfig.AURAS.none
                }
            end
            petGroups[petKey].quantity = petGroups[petKey].quantity + 1
            petGroups[petKey].latestCollectionTime = math.max(petGroups[petKey].latestCollectionTime, pet.collectedAt or 0)
        end
    end
    
    -- Convert to array for sorting
    local petItems = {}
    for petKey, groupData in pairs(petGroups) do
        table.insert(petItems, {
            name = groupData.petType.name,
            pet = groupData.petType,
            quantity = groupData.quantity,
            latestCollectionTime = groupData.latestCollectionTime,
            petConfig = groupData.petConfig,
            aura = groupData.aura,
            auraData = groupData.auraData
        })
    end
    
    -- Sort by rarity, then by latest collection time (newest first)
    table.sort(petItems, function(a, b)
        if a.pet.rarity == b.pet.rarity then
            return a.latestCollectionTime > b.latestCollectionTime
        end
        return a.pet.rarity > b.pet.rarity -- Higher rarity first
    end)
    
    -- Calculate grid dimensions
    local totalRows = math.ceil(#petItems / cardsPerRow)
    local totalHeight = ((totalRows * cardHeight) + ((totalRows - 1) * 20) + 40) * 1.3
    
    -- Pet emojis based on name
    local petEmojis = {
        ["Mighty Duck"] = "🦆",
        ["Golden Duck"] = "🦆",
        ["Fire Duck"] = "🔥",
        ["Ice Duck"] = "🧊",
        ["Shadow Duck"] = "🌑"
    }
    
    -- Rarity colors for borders and effects
    local rarityColors = {
        [1] = {Color3.fromRGB(150, 150, 150), Color3.fromRGB(180, 180, 180)}, -- Basic - Gray
        [2] = {Color3.fromRGB(100, 255, 100), Color3.fromRGB(150, 255, 150)}, -- Advanced - Green
        [3] = {Color3.fromRGB(100, 100, 255), Color3.fromRGB(150, 150, 255)}, -- Premium - Blue
        [4] = {Color3.fromRGB(255, 100, 255), Color3.fromRGB(255, 150, 255)}, -- Elite - Purple
        [5] = {Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 235, 50)}     -- Master - Gold
    }
    
    -- Rarity names
    local rarityNames = {
        [1] = "BASIC",
        [2] = "ADVANCED", 
        [3] = "PREMIUM",
        [4] = "ELITE",
        [5] = "MASTER"
    }
    
    return e("Frame", {
        Name = "PetInventoryContainer",
        Size = UDim2.new(0, panelWidth, 0, panelHeight + 50),
        Position = UDim2.new(0.5, -panelWidth / 2, 0.5, -(panelHeight + 50) / 2),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = visible,
        ZIndex = 30
    }, {
        
        PetInventoryPanel = e("Frame", {
            Name = "PetInventoryPanel",
            Size = UDim2.new(0, panelWidth, 0, panelHeight),
            Position = UDim2.new(0, 0, 0, 50),
            BackgroundColor3 = Color3.fromRGB(240, 245, 255),
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
            ZIndex = 30
        }, {
            -- Floating Title
            FloatingTitle = e("Frame", {
                Name = "FloatingTitle",
                Size = UDim2.new(0, getProportionalSize(screenSize, 280), 0, getProportionalSize(screenSize, 40)),
                Position = UDim2.new(0, -10, 0, -25),
                BackgroundColor3 = Color3.fromRGB(255, 150, 50), -- Orange theme for pets
                BorderSizePixel = 0,
                ZIndex = 32
            }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 12)
            }),
            Gradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 170, 70)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 130, 30))
                },
                Rotation = 45
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(255, 255, 255),
                Thickness = 3,
                Transparency = 0.2
            }),
            -- Title Content Container
            TitleContent = e("Frame", {
                Size = UDim2.new(1, -10, 1, 0),
                Position = UDim2.new(0, 5, 0, 0),
                BackgroundTransparency = 1,
                ZIndex = 33
            }, {
                Layout = e("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 5),
                    SortOrder = Enum.SortOrder.LayoutOrder
                }),
                
                PetIcon = e("TextLabel", {
                    Name = "PetIcon",
                    Size = UDim2.new(0, getProportionalSize(screenSize, 24), 0, getProportionalSize(screenSize, 24)),
                    Text = "🐾",
                    BackgroundTransparency = 1,
                    TextScaled = true,
                    Font = Enum.Font.SourceSansBold,
                    ZIndex = 34,
                    LayoutOrder = 1
                }),
                
                TitleText = e("TextLabel", {
                    Size = UDim2.new(0, 0, 1, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    Text = "PET COLLECTION",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = titleTextSize,
                    TextWrapped = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    ZIndex = 34,
                    LayoutOrder = 2
                }, {
                    TextStroke = e("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = 2,
                        Transparency = 0.5
                    })
                })
            })
        }),
        Corner = e("UICorner", {
            CornerRadius = UDim.new(0, 20)
        }),
        Stroke = e("UIStroke", {
            Color = Color3.fromRGB(255, 150, 50),
            Thickness = 3,
            Transparency = 0.1
        }),
        Gradient = e("UIGradient", {
            Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(0.3, Color3.fromRGB(250, 245, 255)),
                ColorSequenceKeypoint.new(0.7, Color3.fromRGB(245, 240, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(240, 235, 255))
            },
            Rotation = 135
        }),
        
        -- Close Button
        CloseButton = e("TextButton", {
            Name = "CloseButton",
            Size = UDim2.new(0, getProportionalSize(screenSize, 32), 0, getProportionalSize(screenSize, 32)),
            Position = UDim2.new(1, -16, 0, -16),
            Text = "✕",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = getProportionalTextSize(screenSize, 20),
            BackgroundColor3 = Color3.fromRGB(255, 100, 100),
            BorderSizePixel = 0,
            ZIndex = 34,
            Font = Enum.Font.SourceSansBold,
            [React.Event.Activated] = onClose
        }, {
            TextStroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 2,
                Transparency = 0.3
            }),
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 6)
            }),
            Gradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 140, 140)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 60, 60))
                },
                Rotation = 90
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(255, 255, 255),
                Thickness = 2,
                Transparency = 0.2
            })
        }),
        
        -- Subtitle
        Subtitle = e("TextLabel", {
            Name = "Subtitle",
            Size = UDim2.new(1, -80, 0, 25),
            Position = UDim2.new(0, 40, 0, 15),
            Text = (function()
                local totalPets = 0
                for _, item in ipairs(petItems) do
                    totalPets = totalPets + item.quantity
                end
                return "Your collected pets! Types: " .. #petItems .. " | Total: " .. totalPets
            end)(),
            TextColor3 = Color3.fromRGB(60, 80, 140),
            TextSize = smallTextSize,
            TextWrapped = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 31
        }),
        
        -- Scrollable Cards Container
        CardsContainer = e("ScrollingFrame", {
            Name = "CardsContainer",
            Size = UDim2.new(1, -40, 1, -60),
            Position = UDim2.new(0, 20, 0, 50),
            BackgroundColor3 = Color3.fromRGB(250, 252, 255),
            BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
            ScrollBarThickness = 12,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            CanvasSize = UDim2.new(0, 0, 0, totalHeight),
            ScrollBarImageColor3 = Color3.fromRGB(255, 150, 50),
            ZIndex = 31
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 15)
            }),
            ContainerGradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 250, 245))
                },
                Rotation = 45
            }),
            
            -- Grid Layout
            GridLayout = e("UIGridLayout", {
                CellSize = UDim2.new(0, cardWidth, 0, cardHeight),
                CellPadding = UDim2.new(0, 20, 0, 20),
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Top,
                SortOrder = Enum.SortOrder.LayoutOrder
            }),
            
            Padding = e("UIPadding", {
                PaddingTop = UDim.new(0, 20),
                PaddingLeft = UDim.new(0, 20),
                PaddingRight = UDim.new(0, 20),
                PaddingBottom = UDim.new(0, 20)
            }),
            
            -- Generate pet cards
            PetCards = React.createElement(React.Fragment, {}, (function()
                local cards = {}
                
                -- Show enhanced empty state if no pets
                if #petItems == 0 then
                    cards["emptyState"] = e("Frame", {
                        Name = "EmptyState",
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        ZIndex = 32
                    }, {
                        EmptyContainer = e("Frame", {
                            Size = UDim2.new(0, 400, 0, 300),
                            Position = UDim2.new(0.5, -200, 0.5, -150),
                            BackgroundColor3 = Color3.fromRGB(250, 250, 250),
                            BackgroundTransparency = 0.3,
                            BorderSizePixel = 0,
                            ZIndex = 33
                        }, {
                            Corner = e("UICorner", {
                                CornerRadius = UDim.new(0, 20)
                            }),
                            Stroke = e("UIStroke", {
                                Color = Color3.fromRGB(200, 200, 200),
                                Thickness = 2,
                                Transparency = 0.5
                            }),
                            
                            EmptyIcon = e("TextLabel", {
                                Size = UDim2.new(0, 120, 0, 120),
                                Position = UDim2.new(0.5, -60, 0, 30),
                                Text = "🐾",
                                TextSize = normalTextSize,
                                TextWrapped = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.SourceSansBold,
                                ZIndex = 34
                            }),
                            EmptyTitle = e("TextLabel", {
                                Size = UDim2.new(1, -40, 0, 40),
                                Position = UDim2.new(0, 20, 0, 160),
                                Text = "No Pets Collected",
                                TextColor3 = Color3.fromRGB(80, 80, 80),
                                TextSize = normalTextSize,
                                TextWrapped = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.GothamBold,
                                TextXAlignment = Enum.TextXAlignment.Center,
                                ZIndex = 34
                            }),
                            EmptyText = e("TextLabel", {
                                Size = UDim2.new(1, -40, 0, 60),
                                Position = UDim2.new(0, 20, 0, 210),
                                Text = "Buy plots and collect pets to see them here!\nEach pet you touch will be added to your collection.",
                                TextColor3 = Color3.fromRGB(120, 120, 120),
                                TextSize = 16,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.Gotham,
                                TextXAlignment = Enum.TextXAlignment.Center,
                                TextWrapped = true,
                                ZIndex = 34
                            })
                        })
                    })
                else
                    -- Generate pet cards
                    for i, petItem in ipairs(petItems) do
                        local pet = petItem.pet
                        local quantity = petItem.quantity
                        local petConfig = petItem.petConfig
                        local rarity = pet.rarity or 1
                        local colors = rarityColors[rarity] or rarityColors[1]
                        local rarityName = rarityNames[rarity] or "BASIC"
                        local emoji = petEmojis[pet.name] or "🐾"
                        
                        -- Format collection time (use latest collection time)
                        local collectedTime = ""
                        if petItem.latestCollectionTime > 0 then
                            local timeAgo = tick() - petItem.latestCollectionTime
                            if timeAgo < 60 then
                                collectedTime = math.floor(timeAgo) .. "s ago"
                            elseif timeAgo < 3600 then
                                collectedTime = math.floor(timeAgo / 60) .. "m ago"
                            else
                                collectedTime = math.floor(timeAgo / 3600) .. "h ago"
                            end
                        end
                        
                        -- Get description and boost info from config
                        local description = petConfig and petConfig.description or "A mysterious pet with hidden powers."
                        local boostText = ""
                        if petConfig and petConfig.boosts then
                            if petConfig.boosts.moneyMultiplier then
                                local basePercentage = math.floor((petConfig.boosts.moneyMultiplier - 1) * 100)
                                local auraMultiplier = petItem.auraData and petItem.auraData.multiplier or 1
                                local totalPercentage = math.floor(basePercentage * auraMultiplier)
                                boostText = "💰 +" .. totalPercentage .. "% Money"
                                if auraMultiplier > 1 then
                                    boostText = boostText .. " (+" .. basePercentage .. "% × " .. auraMultiplier .. ")"
                                end
                            end
                        end
                        
                        -- Animation refs - simplified
                        local petIconRef = {current = nil}
                        local cardElement = nil
                        local petAnimTracker = {current = nil}
                        
                        cards["pet_" .. i] = e("TextButton", {
                            Name = "PetCard_" .. i,
                            Text = "",
                            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                            BackgroundTransparency = 0.05,
                            BorderSizePixel = 0,
                            ZIndex = 32,
                            LayoutOrder = i,
                            AutoButtonColor = false,
                            ref = function(element)
                                cardElement = element
                            end,
                            [React.Event.MouseEnter] = function()
                                playSound("hover")
                                createFlipAnimation(petIconRef, petAnimTracker)
                            end,
                            [React.Event.Activated] = function()
                                createFlipAnimation(petIconRef, petAnimTracker)
                                createBounceAnimation(cardElement)
                            end
                        }, {
                            Corner = e("UICorner", {
                                CornerRadius = UDim.new(0, 15)
                            }),
                            
                            -- Card Gradient Background
                            CardGradient = e("UIGradient", {
                                Color = ColorSequence.new{
                                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                                    ColorSequenceKeypoint.new(1, Color3.fromRGB(252, 248, 255))
                                },
                                Rotation = 45
                            }),
                            
                            Stroke = e("UIStroke", {
                                Color = colors[1],
                                Thickness = 3,
                                Transparency = 0.1
                            }),
                            
                            -- Pet Emoji/Icon
                            PetIcon = e("TextLabel", {
                                Name = "PetIcon",
                                Size = UDim2.new(0.4, 0, 0.3, 0),
                                Position = UDim2.new(0.5, 0, 0.15, 0),
                                AnchorPoint = Vector2.new(0.5, 0.5),
                                Text = emoji,
                                TextSize = normalTextSize,
                                TextWrapped = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.SourceSansBold,
                                ZIndex = 33,
                                ref = petIconRef
                            }),
                            
                            -- Pet Name
                            PetName = e("TextLabel", {
                                Name = "PetName",
                                Size = UDim2.new(0.9, 0, 0.08, 0),
                                Position = UDim2.new(0.05, 0, 0.32, 0),
                                Text = pet.name:upper(),
                                TextColor3 = Color3.fromRGB(40, 40, 40),
                                TextSize = cardTitleSize,
                                TextWrapped = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.SourceSansBold,
                                ZIndex = 33
                            }),
                            
                            -- Pet Description
                            PetDescription = e("TextLabel", {
                                Name = "PetDescription",
                                Size = UDim2.new(0.9, 0, 0.12, 0),
                                Position = UDim2.new(0.05, 0, 0.40, 0),
                                Text = description,
                                TextColor3 = Color3.fromRGB(70, 80, 120),
                                TextSize = getProportionalTextSize(screenSize, 12),
                                BackgroundTransparency = 1,
                                Font = Enum.Font.Gotham,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                TextYAlignment = Enum.TextYAlignment.Top,
                                TextWrapped = true,
                                TextScaled = true,
                                ZIndex = 33
                            }),
                            
                            -- Rarity Badge
                            RarityBadge = e("Frame", {
                                Name = "RarityBadge",
                                Size = UDim2.new(0.3, 0, 0.06, 0),
                                Position = UDim2.new(0.3, 0, 0.54, 0),
                                AnchorPoint = Vector2.new(0.5, 0),
                                BackgroundColor3 = colors[1],
                                BorderSizePixel = 0,
                                ZIndex = 33
                            }, {
                                Corner = e("UICorner", {
                                    CornerRadius = UDim.new(0, 8)
                                }),
                                RarityText = e("TextLabel", {
                                    Size = UDim2.new(1, 0, 1, 0),
                                    Text = rarityName,
                                    TextColor3 = Color3.fromRGB(255, 255, 255),
                                    TextSize = smallTextSize,
                                    TextWrapped = true,
                                    BackgroundTransparency = 1,
                                    Font = Enum.Font.SourceSansBold,
                                    ZIndex = 34
                                })
                            }),
                            
                            -- Aura Badge
                            AuraBadge = petItem.aura ~= "none" and e("Frame", {
                                Name = "AuraBadge",
                                Size = UDim2.new(0.3, 0, 0.06, 0),
                                Position = UDim2.new(0.7, 0, 0.54, 0),
                                AnchorPoint = Vector2.new(0.5, 0),
                                BackgroundColor3 = petItem.auraData.color,
                                BorderSizePixel = 0,
                                ZIndex = 33
                            }, {
                                Corner = e("UICorner", {
                                    CornerRadius = UDim.new(0, 8)
                                }),
                                AuraText = e("TextLabel", {
                                    Size = UDim2.new(1, 0, 1, 0),
                                    Text = petItem.auraData.name:upper(),
                                    TextColor3 = Color3.fromRGB(255, 255, 255),
                                    TextSize = smallTextSize,
                                    TextWrapped = true,
                                    BackgroundTransparency = 1,
                                    Font = Enum.Font.SourceSansBold,
                                    ZIndex = 34
                                })
                            }) or nil,
                            
                            -- Boost Display
                            BoostLabel = boostText ~= "" and e("TextLabel", {
                                Name = "Boost",
                                Size = UDim2.new(0.9, 0, 0.06, 0),
                                Position = UDim2.new(0.05, 0, 0.62, 0),
                                Text = boostText,
                                TextColor3 = Color3.fromRGB(255, 200, 100),
                                TextSize = getProportionalTextSize(screenSize, 14),
                                TextWrapped = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.SourceSansBold,
                                ZIndex = 33
                            }) or nil,
                            
                            -- Value Display
                            ValueLabel = e("TextLabel", {
                                Name = "Value",
                                Size = UDim2.new(0.9, 0, 0.06, 0),
                                Position = UDim2.new(0.05, 0, 0.70, 0),
                                Text = (function()
                                    local baseValue = pet.value or 1
                                    local auraMultiplier = petItem.auraData and petItem.auraData.valueMultiplier or 1
                                    local totalValue = math.floor(baseValue * auraMultiplier)
                                    if auraMultiplier > 1 then
                                        return "💰 " .. totalValue .. " each (" .. baseValue .. " × " .. auraMultiplier .. ")"
                                    else
                                        return "💰 " .. totalValue .. " each"
                                    end
                                end)(),
                                TextColor3 = Color3.fromRGB(100, 255, 100),
                                TextSize = cardValueSize,
                                TextWrapped = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.SourceSans,
                                ZIndex = 33
                            }),
                            
                            -- Collection Time
                            TimeLabel = collectedTime ~= "" and e("TextLabel", {
                                Name = "CollectedTime",
                                Size = UDim2.new(0.9, 0, 0.05, 0),
                                Position = UDim2.new(0.05, 0, 0.78, 0),
                                Text = "Latest: " .. collectedTime,
                                TextColor3 = Color3.fromRGB(180, 180, 180),
                                TextSize = getProportionalTextSize(screenSize, 11),
                                TextWrapped = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.SourceSans,
                                ZIndex = 33
                            }) or nil,
                            
                            -- Quantity Badge (top right)
                            QuantityBadge = e("Frame", {
                                Name = "QuantityBadge",
                                Size = UDim2.new(0.15, 0, 0.08, 0),
                                Position = UDim2.new(0.85, 0, 0.02, 0),
                                AnchorPoint = Vector2.new(0.5, 0),
                                BackgroundColor3 = Color3.fromRGB(255, 165, 0),
                                BorderSizePixel = 0,
                                ZIndex = 34
                            }, {
                                Corner = e("UICorner", {
                                    CornerRadius = UDim.new(0.5, 0)
                                }),
                                QuantityText = e("TextLabel", {
                                    Size = UDim2.new(1, 0, 1, 0),
                                    Text = tostring(quantity),
                                    TextColor3 = Color3.fromRGB(255, 255, 255),
                                    TextSize = smallTextSize,
                                    TextWrapped = true,
                                    BackgroundTransparency = 1,
                                    Font = Enum.Font.SourceSansBold,
                                    ZIndex = 35
                                }, {
                                    TextStroke = e("UIStroke", {
                                        Color = Color3.fromRGB(0, 0, 0),
                                        Thickness = 2,
                                        Transparency = 0.5
                                    })
                                })
                            })
                        })
                    end
                end
                
                return cards
            end)())
        })
    })
    })
end

return PetInventoryPanel