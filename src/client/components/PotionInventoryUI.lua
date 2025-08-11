-- PotionInventoryUI - Display and manage player's potion inventory
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.react)

local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)
local PotionConfig = require(ReplicatedStorage.config.PotionConfig)
local DataSyncService = require(script.Parent.Parent.services.DataSyncService)
local PotionService = require(script.Parent.Parent.services.PotionService)
local AnimationService = require(script.Parent.Parent.services.AnimationService)
local GradientUtils = require(ReplicatedStorage.utils.GradientUtils)

local function PotionInventoryUI(props)
    local playerData, setPlayerData = React.useState({
        Potions = {},
        ActivePotions = {}
    })
    local isVisible, setIsVisible = React.useState(props.visible or false)
    local bounceOffset, setBounceOffset = React.useState(0)
    local activeAnimations = React.useRef({})
    local activePotions, setActivePotions = React.useState({})
    local previousPotions = React.useRef({})

    -- Update visibility when props change
    React.useEffect(function()
        setIsVisible(props.visible or false)
    end, {props.visible})

    -- Setup bounce animation for title (same as Pet Index)
    React.useEffect(function()
        if isVisible then
            local bounceAnimation = AnimationService:CreateReactBounceAnimation({
                duration = 0.8,
                upOffset = 10,
                downOffset = 10,
                pauseBetween = 0.5
            }, {
                onPositionChange = setBounceOffset
            })
            activeAnimations.current.titleBounce = bounceAnimation
            
            return function()
                if bounceAnimation then
                    bounceAnimation:Stop()
                end
                activeAnimations.current = {}
            end
        end
    end, {isVisible})

    -- Subscribe to data changes
    React.useEffect(function()
        local initialData = DataSyncService:GetPlayerData()
        if initialData then
            setPlayerData(initialData)
            previousPotions.current = initialData.Potions or {}
        end
        
        local unsubscribe = DataSyncService:Subscribe(function(newState)
            if newState and newState.player then
                local newPotions = newState.player.Potions or {}
                local oldPotions = previousPotions.current or {}
                
                -- Compare potion data to see if anything changed
                local potionsChanged = false
                
                -- Check if any potion quantities changed or new potions added
                for potionId, quantity in pairs(newPotions) do
                    if oldPotions[potionId] ~= quantity then
                        potionsChanged = true
                        break
                    end
                end
                
                -- Check if any potions were removed
                if not potionsChanged then
                    for potionId, quantity in pairs(oldPotions) do
                        if newPotions[potionId] ~= quantity then
                            potionsChanged = true
                            break
                        end
                    end
                end
                
                if potionsChanged then
                    print("PotionInventoryUI: Potions changed, updating UI")
                    previousPotions.current = newPotions
                    setPlayerData(newState.player)
                end
            end
        end)
        
        return function()
            if unsubscribe and type(unsubscribe) == "function" then
                unsubscribe()
            end
        end
    end, {})

    -- Subscribe to active potions updates from PotionService
    React.useEffect(function()
        -- Get initial active potions
        local initialActivePotions = PotionService:GetActivePotions()
        setActivePotions(initialActivePotions)
        
        -- Register callbacks for potion events
        local function onPotionActivated(activePotionData)
            setActivePotions(PotionService:GetActivePotions())
        end
        
        local function onPotionExpired(potionId)
            setActivePotions(PotionService:GetActivePotions())
        end
        
        local function onTimersUpdated(updatedActivePotions)
            setActivePotions(updatedActivePotions)
        end
        
        local function onPotionsSynced(syncedActivePotions)
            setActivePotions(syncedActivePotions)
        end
        
        PotionService:RegisterCallback("PotionActivated", onPotionActivated)
        PotionService:RegisterCallback("PotionExpired", onPotionExpired)
        PotionService:RegisterCallback("PotionTimersUpdated", onTimersUpdated)
        PotionService:RegisterCallback("PotionsSynced", onPotionsSynced)
        
        return function()
            PotionService:UnregisterCallback("PotionActivated", onPotionActivated)
            PotionService:UnregisterCallback("PotionExpired", onPotionExpired)
            PotionService:UnregisterCallback("PotionTimersUpdated", onTimersUpdated)
            PotionService:UnregisterCallback("PotionsSynced", onPotionsSynced)
        end
    end, {})

    -- Handle potion activation
    local function handlePotionActivation(potionId)
        print("PotionInventoryUI: Activating potion", potionId)
        PotionService:ActivatePotion(potionId)
    end

    -- Create active potion card component
    local function createActivePotionCard(potionId, activePotionData, index)
        local potionConfig = PotionConfig.GetPotion(potionId)
        if not potionConfig then return nil end

        local rarityColor = PotionConfig.GetRarityColor(potionConfig.Rarity)
        local timeRemaining = activePotionData.RemainingTime or 0
        local formattedTime = PotionConfig.FormatDuration(timeRemaining)

        return React.createElement("Frame", {
            Size = ScreenUtils.udim2(0, 160, 0, 180),
            BackgroundTransparency = 1,
            LayoutOrder = index,
            ZIndex = 10,
        }, {
            -- Card background with rarity color border
            CardBackground = React.createElement("Frame", {
                Size = ScreenUtils.udim2(1, 0, 1, 0),
                BackgroundColor3 = Color3.fromRGB(245, 245, 245),
                BorderSizePixel = 0,
                ZIndex = 9,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 12)
                }),
                
                Stroke = React.createElement("UIStroke", {
                    Color = rarityColor,
                    Thickness = 3,
                    Transparency = 0
                }),
                
                -- Background gradient
                Gradient = GradientUtils.CreateReactGradient(GradientUtils.WHITE_TO_GRAY)
            }),

            -- Active indicator (glowing border)
            ActiveGlow = React.createElement("Frame", {
                Size = ScreenUtils.udim2(1, 6, 1, 6),
                Position = ScreenUtils.udim2(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.fromRGB(50, 205, 50),
                BackgroundTransparency = 0.3,
                BorderSizePixel = 0,
                ZIndex = 8,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 15)
                })
            }),

            -- Potion icon
            PotionIcon = React.createElement("ImageLabel", {
                Size = ScreenUtils.udim2(0, 60, 0, 60),
                Position = ScreenUtils.udim2(0.5, 0, 0, 15),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundTransparency = 1,
                Image = potionConfig.Icon,
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 11,
            }),

            -- Potion name
            PotionName = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, -10, 0, 20),
                Position = ScreenUtils.udim2(0, 5, 0, 80),
                BackgroundTransparency = 1,
                Text = potionConfig.Name,
                TextColor3 = Color3.fromRGB(50, 50, 50),
                TextSize = ScreenUtils.TEXT_SIZES.SMALL(),
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextScaled = true,
                TextStrokeTransparency = 0.5,
                TextStrokeColor3 = Color3.fromRGB(255, 255, 255),
                ZIndex = 11,
            }),

            -- Boost amount
            BoostAmount = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, -10, 0, 18),
                Position = ScreenUtils.udim2(0, 5, 0, 105),
                BackgroundTransparency = 1,
                Text = potionConfig.BoostType == PotionConfig.BoostTypes.PET_MAGNET and potionConfig.BoostType or (PotionConfig.FormatBoostAmount(potionConfig.BoostAmount, potionConfig.BoostType) .. " " .. potionConfig.BoostType),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = ScreenUtils.TEXT_SIZES.SMALL(),
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                ZIndex = 11,
            }, {
                -- Shiny gradient for boost text
                BoostGradient = GradientUtils.CreateReactGradient(GradientUtils.SHINY_BOOST)
            }),

            -- Time remaining (main feature)
            TimeRemaining = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, -10, 0, 25),
                Position = ScreenUtils.udim2(0, 5, 0, 125),
                BackgroundTransparency = 1,
                Text = "⏰ " .. formattedTime,
                TextColor3 = timeRemaining <= 60 and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 100), -- Red if < 1 minute
                TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                ZIndex = 11,
            }),

            -- Active status badge
            ActiveBadge = React.createElement("Frame", {
                Size = ScreenUtils.udim2(0, 50, 0, 18),
                Position = ScreenUtils.udim2(0.5, 0, 1, -23),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundColor3 = Color3.fromRGB(50, 205, 50),
                BorderSizePixel = 0,
                ZIndex = 12,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 4)
                }),
                
                ActiveText = React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "ACTIVE",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.TEXT_SIZES.SMALL(),
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 13,
                })
            })
        })
    end

    -- Create potion card component
    local function createPotionCard(potionId, quantity, index)
        local potionConfig = PotionConfig.GetPotion(potionId)
        if not potionConfig then return nil end

        local rarityColor = PotionConfig.GetRarityColor(potionConfig.Rarity)
        local isActive = PotionService:HasActiveBoost(potionConfig.BoostType)

        return React.createElement("Frame", {
            Size = ScreenUtils.udim2(0, 180, 0, 220),
            BackgroundTransparency = 1,
            LayoutOrder = index,
            ZIndex = 10,
        }, {
            -- Card background with rarity color border
            CardBackground = React.createElement("Frame", {
                Size = ScreenUtils.udim2(1, 0, 1, 0),
                BackgroundColor3 = Color3.fromRGB(245, 245, 245),
                BorderSizePixel = 0,
                ZIndex = 9,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 12)
                }),
                
                Stroke = React.createElement("UIStroke", {
                    Color = rarityColor,
                    Thickness = 3,
                    Transparency = 0
                }),
                
                -- Background gradient
                Gradient = GradientUtils.CreateReactGradient(GradientUtils.WHITE_TO_GRAY)
            }),

            -- Potion icon
            PotionIcon = React.createElement("ImageLabel", {
                Size = ScreenUtils.udim2(0, 80, 0, 80),
                Position = ScreenUtils.udim2(0.5, 0, 0, 20),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundTransparency = 1,
                Image = potionConfig.Icon,
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 11,
            }),

            -- Potion name
            PotionName = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, -10, 0, 25),
                Position = ScreenUtils.udim2(0, 5, 0, 110),
                BackgroundTransparency = 1,
                Text = potionConfig.Name,
                TextColor3 = Color3.fromRGB(50, 50, 50),
                TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextScaled = true,
                TextStrokeTransparency = 0.5,
                TextStrokeColor3 = Color3.fromRGB(255, 255, 255),
                ZIndex = 11,
            }),

            -- Boost amount
            BoostAmount = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, -10, 0, 20),
                Position = ScreenUtils.udim2(0, 5, 0, 140),
                BackgroundTransparency = 1,
                Text = potionConfig.BoostType == PotionConfig.BoostTypes.PET_MAGNET and potionConfig.BoostType or (PotionConfig.FormatBoostAmount(potionConfig.BoostAmount, potionConfig.BoostType) .. " " .. potionConfig.BoostType),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                ZIndex = 11,
            }, {
                -- Shiny gradient for boost text
                BoostGradient = GradientUtils.CreateReactGradient(GradientUtils.SHINY_BOOST)
            }),

            -- Duration
            Duration = React.createElement("TextLabel", {
                Size = ScreenUtils.udim2(1, -10, 0, 15),
                Position = ScreenUtils.udim2(0, 5, 0, 165),
                BackgroundTransparency = 1,
                Text = "Duration: " .. PotionConfig.FormatDuration(potionConfig.Duration),
                TextColor3 = Color3.fromRGB(100, 100, 100),
                TextSize = ScreenUtils.TEXT_SIZES.SMALL(),
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 11,
            }),

            -- Quantity badge
            QuantityBadge = React.createElement("Frame", {
                Size = ScreenUtils.udim2(0, 40, 0, 20),
                Position = ScreenUtils.udim2(1, -45, 0, 5),
                BackgroundColor3 = Color3.fromRGB(255, 215, 0),
                BorderSizePixel = 0,
                ZIndex = 12,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 4)
                }),
                
                QuantityText = React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "x" .. quantity,
                    TextColor3 = Color3.fromRGB(0, 0, 0),
                    TextSize = ScreenUtils.TEXT_SIZES.SMALL(),
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    ZIndex = 13,
                })
            }),

            -- Active indicator (if this boost type is active)
            ActiveIndicator = isActive and React.createElement("Frame", {
                Size = ScreenUtils.udim2(0, 60, 0, 20),
                Position = ScreenUtils.udim2(0.5, 0, 0, 5),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundColor3 = Color3.fromRGB(50, 205, 50),
                BorderSizePixel = 0,
                ZIndex = 12,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 4)
                }),
                
                ActiveText = React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "ACTIVE",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.TEXT_SIZES.SMALL(),
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 13,
                })
            }) or nil,

            -- Activate button
            ActivateButton = React.createElement("TextButton", {
                Size = ScreenUtils.udim2(1, -20, 0, 25),
                Position = ScreenUtils.udim2(0, 10, 1, -30),
                BackgroundColor3 = isActive and Color3.fromRGB(150, 150, 150) or Color3.fromRGB(76, 175, 80),
                BorderSizePixel = 0,
                Text = isActive and "BOOST ACTIVE" or "ACTIVATE",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                Font = Enum.Font.FredokaOne,
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                Active = not isActive,
                ZIndex = 11,
                [React.Event.Activated] = function()
                    if not isActive then
                        handlePotionActivation(potionId)
                    end
                end,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 6)
                }),
                
                Stroke = React.createElement("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = 2,
                    Transparency = 0
                })
            })
        })
    end

    if not isVisible then
        return nil
    end

    local potions = playerData.Potions or {}
    local hasPotions = false
    for _ in pairs(potions) do
        hasPotions = true
        break
    end
    

    -- Check if we have active potions
    local hasActivePotions = false
    for _ in pairs(activePotions) do
        hasActivePotions = true
        break
    end

    return React.createElement("ScreenGui", {
        Name = "PotionInventoryGUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
    }, {
        -- Click-outside overlay
        ClickOutsideOverlay = React.createElement("TextButton", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 0,
            [React.Event.MouseButton1Click] = function()
                setIsVisible(false)
                if props.onClose then props.onClose() end
            end
        }),
        
        -- Main panel
        MainPanel = React.createElement("TextButton", {
            Size = ScreenUtils.udim2(0.7, 0, 0.8, 0),
            Position = ScreenUtils.udim2(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 3,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Text = "",
            AutoButtonColor = false,
            ZIndex = 1,
            [React.Event.Activated] = function()
                -- Prevent closing when clicking inside
            end
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, 12)
            }),
            
            -- Header
            Header = React.createElement("Frame", {
                Size = ScreenUtils.udim2(1, 0, 0, 60),
                BackgroundColor3 = Color3.fromRGB(100, 200, 255),
                BorderSizePixel = 2,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                ZIndex = 6,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 12)
                }),
                
                HeaderGradient = GradientUtils.CreateReactGradient(GradientUtils.CreateSimple(
                    Color3.fromRGB(100, 200, 255),
                    Color3.fromRGB(80, 160, 220),
                    90
                )),
                
                -- Title with bounce animation
                Title = React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(1, -60, 1, 0),
                    Position = ScreenUtils.udim2(0.5, 0, 0, bounceOffset),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    Text = "🧪 Potion Inventory",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.TEXT_SIZES.LARGE() + 4,
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 7,
                }),
                
                -- Close button
                CloseButton = React.createElement("ImageButton", {
                    Size = ScreenUtils.udim2(0, 50, 0, 50),
                    Position = ScreenUtils.udim2(1, -55, 0.5, -25),
                    BackgroundTransparency = 1,
                    Image = IconAssets.getIcon("UI", "X_BUTTON"),
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 7,
                    [React.Event.Activated] = function()
                        setIsVisible(false)
                        if props.onClose then props.onClose() end
                    end
                })
            }),
            
            -- Content area
            ContentArea = React.createElement("Frame", {
                Size = ScreenUtils.udim2(1, -20, 1, -80),
                Position = ScreenUtils.udim2(0, 10, 0, 70),
                BackgroundTransparency = 1,
                ZIndex = 5,
            }, {
                -- Description text
                Description = React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(1, 0, 0, 30),
                    Position = ScreenUtils.udim2(0, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "Activate potions for temporary boosts! Only one boost per type can be active.",
                    TextColor3 = Color3.fromRGB(100, 100, 100),
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextWrapped = true,
                    ZIndex = 6,
                }),

                -- Active Potions Section
                ActivePotionsSection = hasActivePotions and React.createElement("Frame", {
                    Size = ScreenUtils.udim2(1, 0, 0, 220),
                    Position = ScreenUtils.udim2(0, 0, 0, 40),
                    BackgroundTransparency = 1,
                    ZIndex = 5,
                }, {
                    -- Active potions header
                    ActiveHeader = React.createElement("TextLabel", {
                        Size = ScreenUtils.udim2(1, 0, 0, 25),
                        Position = ScreenUtils.udim2(0, 0, 0, 0),
                        BackgroundTransparency = 1,
                        Text = "⚡ Active Potions",
                        TextColor3 = Color3.fromRGB(50, 205, 50),
                        TextSize = ScreenUtils.TEXT_SIZES.LARGE(),
                        Font = Enum.Font.FredokaOne,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextStrokeTransparency = 0,
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        ZIndex = 6,
                    }),

                    -- Active potions grid
                    ActivePotionsGrid = React.createElement("ScrollingFrame", {
                        Size = ScreenUtils.udim2(1, 0, 0, 190),
                        Position = ScreenUtils.udim2(0, 0, 0, 30),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        ScrollBarThickness = 4,
                        ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100),
                        CanvasSize = ScreenUtils.udim2(0, 0, 0, 200),
                        ZIndex = 5,
                        ScrollingDirection = Enum.ScrollingDirection.X,
                    }, {
                        Layout = React.createElement("UIListLayout", {
                            FillDirection = Enum.FillDirection.Horizontal,
                            SortOrder = Enum.SortOrder.LayoutOrder,
                            Padding = ScreenUtils.udim(0, 10),
                            HorizontalAlignment = Enum.HorizontalAlignment.Center,
                            VerticalAlignment = Enum.VerticalAlignment.Top
                        }),
                        
                        Padding = React.createElement("UIPadding", {
                            PaddingTop = ScreenUtils.udim(0, 10),
                            PaddingBottom = ScreenUtils.udim(0, 10),
                            PaddingLeft = ScreenUtils.udim(0, 10),
                            PaddingRight = ScreenUtils.udim(0, 10)
                        })
                    }, React.createElement(React.Fragment, nil, (function()
                        local activePotionElements = {}
                        local index = 1
                        
                        for potionId, activePotionData in pairs(activePotions) do
                            local timeRemaining = activePotionData.RemainingTime or 0
                            -- Only show potions that still have time remaining
                            if timeRemaining > 0 then
                                activePotionElements["ActivePotion_" .. potionId] = createActivePotionCard(potionId, activePotionData, index)
                                index = index + 1
                            end
                        end
                        
                        return activePotionElements
                    end)())),

                    -- Separator line
                    Separator = React.createElement("Frame", {
                        Size = ScreenUtils.udim2(1, -40, 0, 2),
                        Position = ScreenUtils.udim2(0, 20, 1, -5),
                        BackgroundColor3 = Color3.fromRGB(200, 200, 200),
                        BorderSizePixel = 0,
                        ZIndex = 6,
                    })
                }) or nil,

                -- Inventory header
                InventoryHeader = React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(1, 0, 0, 25),
                    Position = ScreenUtils.udim2(0, 0, 0, hasActivePotions and 270 or 40),
                    BackgroundTransparency = 1,
                    Text = "🎒 Potion Inventory",
                    TextColor3 = Color3.fromRGB(100, 150, 255),
                    TextSize = ScreenUtils.TEXT_SIZES.LARGE(),
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 6,
                }),

                -- Potions grid
                PotionsGrid = React.createElement("ScrollingFrame", {
                    Size = ScreenUtils.udim2(1, 0, 1, hasActivePotions and -305 or -75),
                    Position = ScreenUtils.udim2(0, 0, 0, hasActivePotions and 300 or 70),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ScrollBarThickness = 6,
                    ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100),
                    CanvasSize = ScreenUtils.udim2(0, 0, 0, math.ceil((hasPotions and #PotionConfig.GetAllPotions() or 0) / 3) * 240 + 20),
                    ZIndex = 5,
                }, {
                    Layout = React.createElement("UIGridLayout", {
                        CellSize = ScreenUtils.udim2(0, 180, 0, 220),
                        CellPadding = ScreenUtils.udim2(0, 10, 0, 10),
                        StartCorner = Enum.StartCorner.TopLeft,
                        FillDirectionMaxCells = 3,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Top
                    }),
                    
                    Padding = React.createElement("UIPadding", {
                        PaddingTop = ScreenUtils.udim(0, 10),
                        PaddingBottom = ScreenUtils.udim(0, 10),
                        PaddingLeft = ScreenUtils.udim(0, 10),
                        PaddingRight = ScreenUtils.udim(0, 10)
                    })
                }, hasPotions and React.createElement(React.Fragment, nil, (function()
                    local potionElements = {}
                    local index = 1
                    
                    for potionId, quantity in pairs(potions) do
                        if quantity > 0 then
                            potionElements["Potion_" .. potionId] = createPotionCard(potionId, quantity, index)
                            index = index + 1
                        end
                    end
                    
                    return potionElements
                end)()) or nil),

                -- Empty state
                EmptyState = (not hasPotions) and React.createElement("Frame", {
                    Size = ScreenUtils.udim2(1, 0, 1, hasActivePotions and -305 or -75),
                    Position = ScreenUtils.udim2(0, 0, 0, hasActivePotions and 300 or 70),
                    BackgroundTransparency = 1,
                    ZIndex = 5,
                }, {
                    EmptyText = React.createElement("TextLabel", {
                        Size = ScreenUtils.udim2(1, 0, 0, 100),
                        Position = ScreenUtils.udim2(0.5, 0, 0.5, -50),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,
                        Text = "🧪\n\nNo potions yet!\nEarn potions from chests and rewards.",
                        TextColor3 = Color3.fromRGB(150, 150, 150),
                        TextSize = ScreenUtils.TEXT_SIZES.LARGE(),
                        Font = Enum.Font.FredokaOne,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        ZIndex = 6,
                    })
                }) or nil
            })
        })
    })
end

return PotionInventoryUI