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

    -- Handle potion cancellation/removal
    local function handlePotionCancellation(potionId)
        print("PotionInventoryUI: Cancelling active potion", potionId)
        -- Call PotionService to remove the active potion
        PotionService:CancelActivePotion(potionId)
    end

    -- Create active potion card component
    local function createActivePotionCard(potionId, activePotionData, index)
        local potionConfig = PotionConfig.GetPotion(potionId)
        if not potionConfig then return nil end

        local rarityColor = PotionConfig.GetRarityColor(potionConfig.Rarity)
        local timeRemaining = activePotionData.RemainingTime or 0
        local formattedTime = PotionConfig.FormatDuration(timeRemaining)
        local cardSize = ScreenUtils.getProportionalSize(240) -- Even bigger cards

        return React.createElement("Frame", {
            Size = UDim2.new(0, cardSize, 0, cardSize + 40), -- Square + extra height for text
            BackgroundTransparency = 1,
            LayoutOrder = index,
            ZIndex = 10,
        }, {
            -- Card background with rarity color border
            CardBackground = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255), -- White background like boost panel
                BorderSizePixel = 0,
                ZIndex = 9,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(12))
                }),
                
                Stroke = React.createElement("UIStroke", {
                    Color = rarityColor,
                    Thickness = ScreenUtils.getProportionalSize(3), -- Responsive thickness
                    Transparency = 0,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                })
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

            -- Potion icon (much bigger)
            PotionIcon = React.createElement("ImageLabel", {
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(140), 0, ScreenUtils.getProportionalSize(140)),
                Position = UDim2.new(0.5, 0, 0.35, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Image = potionConfig.Icon,
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 11,
            }),

            -- Potion name (bigger text)
            PotionName = React.createElement("TextLabel", {
                Size = UDim2.new(1, -ScreenUtils.getProportionalSize(10), 0, ScreenUtils.getProportionalSize(40)),
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(5), 0.65, 0),
                BackgroundTransparency = 1,
                Text = potionConfig.Name,
                TextColor3 = Color3.fromRGB(50, 50, 50),
                TextSize = ScreenUtils.TEXT_SIZES.HEADER(), -- Even bigger text
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextScaled = true,
                ZIndex = 11,
            }),

            -- Boost amount (bigger text)
            BoostAmount = React.createElement("TextLabel", {
                Size = UDim2.new(1, -ScreenUtils.getProportionalSize(10), 0, ScreenUtils.getProportionalSize(35)),
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(5), 0.8, 0),
                BackgroundTransparency = 1,
                Text = potionConfig.BoostType == PotionConfig.BoostTypes.PET_MAGNET and potionConfig.BoostType or (PotionConfig.FormatBoostAmount(potionConfig.BoostAmount, potionConfig.BoostType) .. " " .. potionConfig.BoostType),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = ScreenUtils.TEXT_SIZES.HEADER(), -- Bigger boost text
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                ZIndex = 11,
            }, {
                -- Shiny gradient for boost text
                BoostGradient = GradientUtils.CreateReactGradient(GradientUtils.SHINY_BOOST)
            }),

            -- Time remaining (main feature, much bigger text)
            TimeRemaining = React.createElement("TextLabel", {
                Size = UDim2.new(1, -ScreenUtils.getProportionalSize(10), 0, ScreenUtils.getProportionalSize(45)),
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(5), 0.92, 0),
                BackgroundTransparency = 1,
                Text = "⏰ " .. formattedTime,
                TextColor3 = timeRemaining <= 60 and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 100), -- Red if < 1 minute
                TextSize = ScreenUtils.TEXT_SIZES.TITLE(), -- Biggest text for time
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                ZIndex = 11,
            }),

            -- Active status badge (bigger and better positioned)
            ActiveBadge = React.createElement("Frame", {
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(80), 0, ScreenUtils.getProportionalSize(25)),
                Position = UDim2.new(0.5, 0, 1, -ScreenUtils.getProportionalSize(30)),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundColor3 = Color3.fromRGB(50, 205, 50),
                BorderSizePixel = 0,
                ZIndex = 12,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(6))
                }),
                
                ActiveText = React.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "ACTIVE",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 13,
                })
            }),

            -- Close button (X) to cancel the potion (bigger)
            CloseButton = React.createElement("ImageButton", {
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(30), 0, ScreenUtils.getProportionalSize(30)),
                Position = UDim2.new(1, -ScreenUtils.getProportionalSize(35), 0, ScreenUtils.getProportionalSize(5)),
                BackgroundTransparency = 1,
                Image = IconAssets.getIcon("UI", "X_BUTTON"),
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 14,
                [React.Event.Activated] = function()
                    handlePotionCancellation(potionId)
                end
            })
        })
    end

    -- Create potion card component
    local function createPotionCard(potionId, quantity, index)
        local potionConfig = PotionConfig.GetPotion(potionId)
        if not potionConfig then return nil end

        local rarityColor = PotionConfig.GetRarityColor(potionConfig.Rarity)
        local isActive = PotionService:HasActiveBoost(potionConfig.BoostType)

        local cardSize = ScreenUtils.getProportionalSize(260) -- Much bigger cards

        return React.createElement("Frame", {
            Size = UDim2.new(0, cardSize, 0, cardSize + 80), -- Square + extra height for button
            BackgroundTransparency = 1,
            LayoutOrder = index,
            ZIndex = 10,
        }, {
            -- Card background with colorful rarity outline like boost panel
            CardBackground = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255), -- White background like boost panel
                BorderSizePixel = 0,
                ZIndex = 9,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(12))
                }),
                
                -- Colorful outline based on rarity
                Stroke = React.createElement("UIStroke", {
                    Color = rarityColor,
                    Thickness = ScreenUtils.getProportionalSize(4), -- Thicker colorful outline
                    Transparency = 0,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                })
            }),

            -- Potion icon (much bigger)
            PotionIcon = React.createElement("ImageLabel", {
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(160), 0, ScreenUtils.getProportionalSize(160)),
                Position = UDim2.new(0.5, 0, 0.28, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Image = potionConfig.Icon,
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 11,
            }),

            -- Potion name (much bigger text)
            PotionName = React.createElement("TextLabel", {
                Size = UDim2.new(1, -ScreenUtils.getProportionalSize(10), 0, ScreenUtils.getProportionalSize(40)),
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(5), 0.55, 0),
                BackgroundTransparency = 1,
                Text = potionConfig.Name,
                TextColor3 = Color3.fromRGB(50, 50, 50),
                TextSize = ScreenUtils.TEXT_SIZES.HEADER(), -- Much bigger text
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextScaled = true,
                ZIndex = 11,
            }),

            -- Boost amount (much bigger text)
            BoostAmount = React.createElement("TextLabel", {
                Size = UDim2.new(1, -ScreenUtils.getProportionalSize(10), 0, ScreenUtils.getProportionalSize(35)),
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(5), 0.68, 0),
                BackgroundTransparency = 1,
                Text = potionConfig.BoostType == PotionConfig.BoostTypes.PET_MAGNET and potionConfig.BoostType or (PotionConfig.FormatBoostAmount(potionConfig.BoostAmount, potionConfig.BoostType) .. " " .. potionConfig.BoostType),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = ScreenUtils.TEXT_SIZES.HEADER(), -- Much bigger boost text
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                ZIndex = 11,
            }, {
                -- Shiny gradient for boost text
                BoostGradient = GradientUtils.CreateReactGradient(GradientUtils.SHINY_BOOST)
            }),

            -- Duration (bigger text)
            Duration = React.createElement("TextLabel", {
                Size = UDim2.new(1, -ScreenUtils.getProportionalSize(10), 0, ScreenUtils.getProportionalSize(25)),
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(5), 0.82, 0),
                BackgroundTransparency = 1,
                Text = "Duration: " .. PotionConfig.FormatDuration(potionConfig.Duration),
                TextColor3 = Color3.fromRGB(100, 100, 100),
                TextSize = ScreenUtils.TEXT_SIZES.LARGE(), -- Much bigger duration text
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 11,
            }),

            -- Quantity badge (bigger)
            QuantityBadge = React.createElement("Frame", {
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(60), 0, ScreenUtils.getProportionalSize(30)),
                Position = UDim2.new(1, -ScreenUtils.getProportionalSize(65), 0, ScreenUtils.getProportionalSize(5)),
                BackgroundColor3 = Color3.fromRGB(255, 215, 0),
                BorderSizePixel = 0,
                ZIndex = 12,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(6))
                }),
                
                QuantityText = React.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "x" .. quantity,
                    TextColor3 = Color3.fromRGB(0, 0, 0),
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    ZIndex = 13,
                })
            }),

            -- Active indicator (if this boost type is active, bigger)
            ActiveIndicator = isActive and React.createElement("Frame", {
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(90), 0, ScreenUtils.getProportionalSize(30)),
                Position = UDim2.new(0.5, 0, 0, ScreenUtils.getProportionalSize(5)),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundColor3 = Color3.fromRGB(50, 205, 50),
                BorderSizePixel = 0,
                ZIndex = 12,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(6))
                }),
                
                ActiveText = React.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "ACTIVE",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 13,
                })
            }) or nil,

            -- Activate button (much bigger)
            ActivateButton = React.createElement("TextButton", {
                Size = UDim2.new(1, -ScreenUtils.getProportionalSize(20), 0, ScreenUtils.getProportionalSize(50)),
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(10), 1, -ScreenUtils.getProportionalSize(55)),
                BackgroundColor3 = isActive and Color3.fromRGB(150, 150, 150) or Color3.fromRGB(76, 175, 80),
                BorderSizePixel = 0,
                Text = isActive and "BOOST ACTIVE" or "ACTIVATE",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = ScreenUtils.TEXT_SIZES.HEADER(), -- Much bigger button text
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
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(8))
                }),
                
                Stroke = React.createElement("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = ScreenUtils.getProportionalSize(2),
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
    
    -- Calculate optimal panel size (narrower like boost panel but with comfortable padding)
    -- Width to fit 3 cards: 3 cards * 260px + 2 gaps * 20px + extra side padding = ~920px
    local screenSize = ScreenUtils.getScreenSize()
    local panelWidth = math.min(ScreenUtils.getProportionalSize(920), screenSize.X * 0.6) -- 60% of screen width max, more breathing room
    local panelHeight = math.min(ScreenUtils.getProportionalSize(900), screenSize.Y * 0.9)

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
            Size = UDim2.new(0, panelWidth, 0, panelHeight),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1, -- Transparent to show background pattern
            Text = "",
            AutoButtonColor = false,
            ZIndex = 1,
            [React.Event.Activated] = function()
                -- Prevent closing when clicking inside
            end
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(12))
            }),
            
            -- Main panel black outline
            PanelOutline = React.createElement("UIStroke", {
                Thickness = ScreenUtils.getProportionalSize(3),
                Color = Color3.fromRGB(0, 0, 0),
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }),
            
            -- White background
            WhiteBackground = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(245, 245, 245),
                BorderSizePixel = 0,
                ZIndex = -2,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(12)),
                }),
            }),
            
            -- Background pattern like boost panel
            BackgroundPattern = React.createElement("ImageLabel", {
                Name = "BackgroundPattern",
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                Image = "rbxassetid://116367512866072",
                ScaleType = Enum.ScaleType.Tile,
                TileSize = UDim2.new(0, ScreenUtils.getProportionalSize(120), 0, ScreenUtils.getProportionalSize(120)),
                ImageTransparency = 0.85,
                ImageColor3 = Color3.fromRGB(200, 200, 200),
                ZIndex = -1,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(12)),
                }),
            }),
            
            -- Header
            Header = React.createElement("Frame", {
                Size = ScreenUtils.udim2(1, 0, 0, ScreenUtils.getProportionalSize(80)), -- Bigger header
                BackgroundColor3 = Color3.fromRGB(100, 200, 255),
                BorderSizePixel = 0,
                ZIndex = 6,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(12))
                }),
                
                -- Header outline
                HeaderOutline = React.createElement("UIStroke", {
                    Thickness = ScreenUtils.getProportionalSize(2),
                    Color = Color3.fromRGB(0, 0, 0),
                    Transparency = 0,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                }),
                
                HeaderGradient = GradientUtils.CreateReactGradient(GradientUtils.CreateSimple(
                    Color3.fromRGB(100, 200, 255),
                    Color3.fromRGB(80, 160, 220),
                    90
                )),
                
                -- Title with bounce animation (bigger text)
                Title = React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(1, -ScreenUtils.getProportionalSize(80), 1, 0),
                    Position = ScreenUtils.udim2(0.5, 0, 0, bounceOffset),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    Text = "🧪 Potion Inventory", -- Using potion emoji instead of backpack
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.TEXT_SIZES.TITLE(), -- Much bigger title
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 7,
                }),
                
                -- Close button (bigger)
                CloseButton = React.createElement("ImageButton", {
                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(60), 0, ScreenUtils.getProportionalSize(60)),
                    Position = UDim2.new(1, -ScreenUtils.getProportionalSize(70), 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
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
                Size = ScreenUtils.udim2(1, -ScreenUtils.getProportionalSize(20), 1, -ScreenUtils.getProportionalSize(100)),
                Position = ScreenUtils.udim2(0, ScreenUtils.getProportionalSize(10), 0, ScreenUtils.getProportionalSize(90)),
                BackgroundTransparency = 1,
                ZIndex = 5,
            }, {

                -- Active Potions Section
                ActivePotionsSection = hasActivePotions and React.createElement("Frame", {
                    Size = ScreenUtils.udim2(1, 0, 0, ScreenUtils.getProportionalSize(260)), -- Bigger for larger cards
                    Position = ScreenUtils.udim2(0, 0, 0, ScreenUtils.getProportionalSize(10)), -- At top now since description moved to bottom
                    BackgroundTransparency = 1,
                    ZIndex = 5,
                }, {
                    -- Active potions header (bigger text)
                    ActiveHeader = React.createElement("TextLabel", {
                        Size = ScreenUtils.udim2(1, 0, 0, ScreenUtils.getProportionalSize(35)),
                        Position = ScreenUtils.udim2(0, 0, 0, 0),
                        BackgroundTransparency = 1,
                        Text = "⚡ Active Potions",
                        TextColor3 = Color3.fromRGB(50, 205, 50),
                        TextSize = ScreenUtils.TEXT_SIZES.TITLE(),
                        Font = Enum.Font.FredokaOne,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        TextStrokeTransparency = 0,
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        ZIndex = 6,
                    }),

                    -- Active potions grid
                    ActivePotionsGrid = React.createElement("ScrollingFrame", {
                        Size = ScreenUtils.udim2(1, 0, 0, ScreenUtils.getProportionalSize(220)), -- Bigger for larger cards
                        Position = ScreenUtils.udim2(0, 0, 0, ScreenUtils.getProportionalSize(40)),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        ScrollBarThickness = ScreenUtils.getProportionalSize(6),
                        ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100),
                        CanvasSize = ScreenUtils.udim2(0, 0, 0, ScreenUtils.getProportionalSize(220)),
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

                -- Inventory header (bigger text)
                InventoryHeader = React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(1, 0, 0, ScreenUtils.getProportionalSize(35)),
                    Position = ScreenUtils.udim2(0, 0, 0, hasActivePotions and ScreenUtils.getProportionalSize(280) or ScreenUtils.getProportionalSize(10)),
                    BackgroundTransparency = 1,
                    Text = "🧪 Potion Inventory", -- Using potion emoji for consistency
                    TextColor3 = Color3.fromRGB(100, 150, 255),
                    TextSize = ScreenUtils.TEXT_SIZES.TITLE(),
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 6,
                }),

                -- Potions grid (with padding from header)
                PotionsGrid = React.createElement("ScrollingFrame", {
                    Size = ScreenUtils.udim2(1, 0, 1, hasActivePotions and ScreenUtils.getProportionalSize(-420) or ScreenUtils.getProportionalSize(-160)), -- Reduced height to make room for bottom description
                    Position = ScreenUtils.udim2(0, 0, 0, hasActivePotions and ScreenUtils.getProportionalSize(330) or ScreenUtils.getProportionalSize(60)), -- Added 50px padding from header
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ScrollBarThickness = ScreenUtils.getProportionalSize(8),
                    ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100),
                    CanvasSize = ScreenUtils.udim2(0, 0, 0, math.ceil((hasPotions and #PotionConfig.GetAllPotions() or 0) / 3) * ScreenUtils.getProportionalSize(360) + ScreenUtils.getProportionalSize(60)),
                    ZIndex = 5,
                }, {
                    Layout = React.createElement("UIGridLayout", {
                        CellSize = UDim2.new(0, ScreenUtils.getProportionalSize(260), 0, ScreenUtils.getProportionalSize(340)), -- Much bigger cells for larger cards
                        CellPadding = UDim2.new(0, ScreenUtils.getProportionalSize(20), 0, ScreenUtils.getProportionalSize(20)),
                        StartCorner = Enum.StartCorner.TopLeft,
                        FillDirectionMaxCells = 3, -- Show 3 cards per row (panel is sized appropriately)
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
                    Size = ScreenUtils.udim2(1, 0, 1, hasActivePotions and ScreenUtils.getProportionalSize(-420) or ScreenUtils.getProportionalSize(-160)), -- Match grid size for bottom description
                    Position = ScreenUtils.udim2(0, 0, 0, hasActivePotions and ScreenUtils.getProportionalSize(330) or ScreenUtils.getProportionalSize(60)),
                    BackgroundTransparency = 1,
                    ZIndex = 5,
                }, {
                    EmptyText = React.createElement("TextLabel", {
                        Size = ScreenUtils.udim2(1, 0, 0, ScreenUtils.getProportionalSize(120)),
                        Position = ScreenUtils.udim2(0.5, 0, 0.5, -ScreenUtils.getProportionalSize(60)),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,
                        Text = "🧪\n\nNo potions yet!\nEarn potions from chests and rewards.",
                        TextColor3 = Color3.fromRGB(120, 120, 120),
                        TextSize = ScreenUtils.TEXT_SIZES.TITLE(),
                        Font = Enum.Font.FredokaOne,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        ZIndex = 6,
                    })
                }) or nil,
                
                -- Description text at bottom
                BottomDescription = React.createElement("TextLabel", {
                    Size = ScreenUtils.udim2(1, -ScreenUtils.getProportionalSize(40), 0, ScreenUtils.getProportionalSize(50)),
                    Position = ScreenUtils.udim2(0.5, 0, 1, -ScreenUtils.getProportionalSize(60)),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    Text = "Activate potions for temporary boosts! Only one boost per type can be active.",
                    TextColor3 = Color3.fromRGB(100, 100, 100),
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextWrapped = true,
                    ZIndex = 6,
                })
            })
        })
    })
end

return PotionInventoryUI