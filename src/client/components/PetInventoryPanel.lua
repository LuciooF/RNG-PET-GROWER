-- Pet Inventory Panel Component  
-- Modern card-grid layout showing collected pets
-- Refactored to use modular architecture with PetInventoryController and PetCardComponent

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local React = require(ReplicatedStorage.Packages.react)
local e = React.createElement

-- Shared utilities
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local AnimationHelpers = require(ReplicatedStorage.utils.AnimationHelpers)
local assets = require(ReplicatedStorage.assets)

-- Business logic controllers
local PetInventoryController = require(script.Parent.Parent.services.PetInventoryController)
local PetBoostController = require(script.Parent.Parent.services.controllers.PetBoostController)

-- UI components
local PetCardComponent = require(script.Parent.PetCardComponent)
local ClickOutsideWrapper = require(script.Parent.ClickOutsideWrapper)

-- Sound effects (simplified for now)
local function playSound(soundType)
    -- Placeholder for sound effects
end

local function PetInventoryPanel(props)
    local playerData = props.playerData
    local visible = props.visible or false
    local onClose = props.onClose or function() end
    local remotes = props.remotes or {}
    
    -- Subscribe to Redux store for maxSlots changes
    local Store = require(ReplicatedStorage.store)
    local maxSlots, setMaxSlots = React.useState(function()
        local state = Store:getState()
        return (state.player and state.player.maxSlots) or 3
    end)
    
    -- Listen for Redux store changes to update maxSlots
    React.useEffect(function()
        local connection = Store.changed:connect(function(newState)
            local newMaxSlots = (newState.player and newState.player.maxSlots) or 3
            if newMaxSlots ~= maxSlots then
                setMaxSlots(newMaxSlots)
                print(string.format("PetInventoryPanel: Updated maxSlots to %d", newMaxSlots))
            end
        end)
        
        return function()
            connection:disconnect()
        end
    end, {maxSlots})
    
    -- Responsive sizing (same as original)
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local scale = ScreenUtils.getProportionalScale(screenSize)
    local aspectRatio = screenSize.X / screenSize.Y
    
    -- Proportional text sizes
    local titleTextSize = ScreenUtils.getProportionalTextSize(screenSize, 32)
    local normalTextSize = ScreenUtils.getProportionalTextSize(screenSize, 18)
    local smallTextSize = ScreenUtils.getProportionalTextSize(screenSize, 14)
    local buttonTextSize = ScreenUtils.getProportionalTextSize(screenSize, 16)
    local cardTitleSize = ScreenUtils.getProportionalTextSize(screenSize, 20)
    local cardValueSize = ScreenUtils.getProportionalTextSize(screenSize, 16)
    
    -- Panel sizing (exact same as original)
    local panelWidth = math.min(screenSize.X * 0.9, ScreenUtils.getProportionalSize(screenSize, 900))
    local panelHeight = math.min(screenSize.Y * 0.85, ScreenUtils.getProportionalSize(screenSize, 600))
    
    -- Use PetInventoryController for business logic
    local petGroups, assignedPets = PetInventoryController.groupPets(playerData)
    local petItems = PetInventoryController.createSortedPetItems(petGroups)
    local gridDimensions = PetInventoryController.calculateGridDimensions(petItems, screenSize, panelWidth)
    
    -- Calculate pet boost data for header
    local friendsBoost = playerData.friendsBoost or 0
    local petBoosts, totalMoneyMultiplier = PetBoostController.generateBoostData(assignedPets, friendsBoost)
    local totalBoosts = #petBoosts
    
    local cardsPerRow = gridDimensions.cardsPerRow
    local cardWidth = gridDimensions.cardWidth
    local cardHeight = gridDimensions.cardHeight
    local totalHeight = gridDimensions.totalHeight
    
    return e(ClickOutsideWrapper, {
        visible = visible,
        onClose = onClose
    }, {
        Container = e("Frame", {
            Name = "PetInventoryContainer",
            Size = UDim2.new(0, panelWidth, 0, panelHeight + 50),
            Position = UDim2.new(0.5, -panelWidth / 2, 0.5, -(panelHeight + 50) / 2),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
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
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 280), 0, ScreenUtils.getProportionalSize(screenSize, 40)),
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
                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 24), 0, ScreenUtils.getProportionalSize(screenSize, 24)),
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
        CloseButton = e("ImageButton", {
            Name = "CloseButton",
            Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 32), 0, ScreenUtils.getProportionalSize(screenSize, 32)),
            Position = UDim2.new(1, -16, 0, -16),
            Image = assets["vector-icon-pack-2/UI/X Button/X Button Outline 256.png"] or "",
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 34,
            ScaleType = Enum.ScaleType.Fit,
            [React.Event.Activated] = onClose,
            [React.Event.MouseEnter] = function(button)
                button.ImageColor3 = Color3.fromRGB(180, 180, 180)
            end,
            [React.Event.MouseLeave] = function(button)
                button.ImageColor3 = Color3.fromRGB(255, 255, 255)
            end
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
        
        -- Summary Stats (Pet Boost Header)
        SummaryStats = e("Frame", {
            Name = "SummaryStats",
            Size = UDim2.new(1, -40, 0, 30),
            Position = UDim2.new(0, 20, 0, 45),
            BackgroundColor3 = Color3.fromRGB(255, 240, 200),
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
            ZIndex = 31
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 10)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(255, 150, 50),
                Thickness = 2,
                Transparency = 0.4
            }),
            
            SummaryText = e("TextLabel", {
                Size = UDim2.new(1, -20, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                Text = PetBoostController.getSummaryText(totalMoneyMultiplier, totalBoosts, maxSlots),
                TextColor3 = Color3.fromRGB(80, 60, 0),
                TextSize = normalTextSize,
                TextWrapped = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 32
            })
        }),
        
        -- Equipped Pets Section
        EquippedSection = e("Frame", {
            Name = "EquippedSection",
            Size = UDim2.new(1, -40, 0, 160),
            Position = UDim2.new(0, 20, 0, 85),
            BackgroundColor3 = Color3.fromRGB(250, 252, 255),
            BackgroundTransparency = 0.1,
            BorderSizePixel = 0,
            ZIndex = 31
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 15)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(100, 255, 100),
                Thickness = 2,
                Transparency = 0.3
            }),
            
            -- Title
            EquippedTitle = e("TextLabel", {
                Name = "EquippedTitle",
                Size = UDim2.new(1, -20, 0, 20),
                Position = UDim2.new(0, 10, 0, 5),
                Text = "EQUIPPED PETS",
                TextColor3 = Color3.fromRGB(60, 80, 140),
                TextSize = normalTextSize,
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 32
            }),
            
            -- Equipped Slots Container
            EquippedSlots = e("Frame", {
                Name = "EquippedSlots",
                Size = UDim2.new(1, -20, 0, 80),
                Position = UDim2.new(0, 10, 0, 30),
                BackgroundTransparency = 1,
                ZIndex = 32
            }, {
                Layout = e("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 10),
                    SortOrder = Enum.SortOrder.LayoutOrder
                }),
                
                -- Generate slots based on owned slots + purchase options
                Slots = React.createElement(React.Fragment, {}, (function()
                    local slots = {}
                    local totalSlotsToShow = math.min(maxSlots + (maxSlots < 5 and 1 or 0), 5) -- Show up to 1 purchasable slot, max 5 total
                    
                    for i = 1, totalSlotsToShow do
                        local assignedPet = assignedPets[i] or nil
                        local isEquippedSlot = i <= maxSlots
                        local isPlusSlot = i > maxSlots
                        
                        slots["equipped_slot_" .. i] = e("Frame", {
                            Name = "EquippedSlot" .. i,
                            Size = UDim2.new(0, 100, 0, 80),
                            BackgroundColor3 = (function()
                                if assignedPet then
                                    return Color3.fromRGB(255, 255, 255)
                                elseif isEquippedSlot then
                                    return Color3.fromRGB(220, 220, 220)
                                else -- Plus slot
                                    return Color3.fromRGB(200, 200, 200)
                                end
                            end)(),
                            BackgroundTransparency = assignedPet and 0.1 or 0.3,
                            BorderSizePixel = 0,
                            ZIndex = 33,
                            LayoutOrder = i
                        }, {
                            Corner = e("UICorner", {
                                CornerRadius = UDim.new(0, 12)
                            }),
                            Stroke = e("UIStroke", {
                                Color = (function()
                                    if assignedPet then
                                        return Color3.fromRGB(100, 255, 100)
                                    elseif isEquippedSlot then
                                        return Color3.fromRGB(150, 150, 150)
                                    else -- Plus slot
                                        return Color3.fromRGB(255, 200, 50)
                                    end
                                end)(),
                                Thickness = 2,
                                Transparency = 0.2
                            }),
                            
                            -- Content based on slot type
                            Content = (function()
                                if assignedPet then
                                    -- Show equipped pet
                                    return e("Frame", {
                                        Size = UDim2.new(1, -4, 1, -4),
                                        Position = UDim2.new(0, 2, 0, 2),
                                        BackgroundTransparency = 1,
                                        ZIndex = 34
                                    }, {
                                        Layout = e("UIListLayout", {
                                            FillDirection = Enum.FillDirection.Vertical,
                                            HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                            VerticalAlignment = Enum.VerticalAlignment.Center,
                                            Padding = UDim.new(0, 2),
                                            SortOrder = Enum.SortOrder.LayoutOrder
                                        }),
                                        
                                        Padding = e("UIPadding", {
                                            PaddingTop = UDim.new(0, 4),
                                            PaddingBottom = UDim.new(0, 4),
                                            PaddingLeft = UDim.new(0, 2),
                                            PaddingRight = UDim.new(0, 2)
                                        }),
                                        
                                        PetName = e("TextLabel", {
                                            Size = UDim2.new(1, 0, 0, 20),
                                            Text = string.upper(assignedPet.name or "Unknown"),
                                            TextColor3 = Color3.fromRGB(60, 80, 140),
                                            TextSize = ScreenUtils.getProportionalTextSize(screenSize, 7),
                                            TextWrapped = true,
                                            TextScaled = false,
                                            BackgroundTransparency = 1,
                                            Font = Enum.Font.GothamBold,
                                            TextXAlignment = Enum.TextXAlignment.Center,
                                            TextYAlignment = Enum.TextYAlignment.Center,
                                            ZIndex = 35,
                                            LayoutOrder = 1
                                        }),
                                        
                                        -- Pet Rarity Display
                                        PetRarity = e("TextLabel", {
                                            Size = UDim2.new(1, 0, 0, 16),
                                            Text = (function()
                                                local PetConfig = require(ReplicatedStorage.Shared.config.PetConfig)
                                                local comprehensiveInfo = PetConfig:GetComprehensivePetInfo(assignedPet.id or 1, assignedPet.aura, assignedPet.size)
                                                if comprehensiveInfo then
                                                    -- Use the same format as pet cards: "1/333 - Celestial"
                                                    return comprehensiveInfo.rarityText
                                                end
                                                return "1/1 - Common"
                                            end)(),
                                            TextColor3 = (function()
                                                local PetConfig = require(ReplicatedStorage.Shared.config.PetConfig)
                                                local comprehensiveInfo = PetConfig:GetComprehensivePetInfo(assignedPet.id or 1, assignedPet.aura, assignedPet.size)
                                                if comprehensiveInfo then
                                                    -- Use the same color as pet cards
                                                    return comprehensiveInfo.rarityColor
                                                end
                                                return Color3.fromRGB(200, 200, 200)
                                            end)(),
                                            TextSize = ScreenUtils.getProportionalTextSize(screenSize, 7),
                                            TextWrapped = false,
                                            BackgroundTransparency = 1,
                                            Font = Enum.Font.GothamBold,
                                            TextXAlignment = Enum.TextXAlignment.Center,
                                            TextYAlignment = Enum.TextYAlignment.Center,
                                            ZIndex = 35,
                                            LayoutOrder = 2
                                        }),
                                        
                                        -- Pet Boost Display
                                        PetBoost = e("TextLabel", {
                                            Size = UDim2.new(1, 0, 0, 16),
                                            Text = (function()
                                                local PetConfig = require(ReplicatedStorage.Shared.config.PetConfig)
                                                local comprehensiveInfo = PetConfig:GetComprehensivePetInfo(assignedPet.id or 1, assignedPet.aura, assignedPet.size)
                                                if comprehensiveInfo then
                                                    return string.format("+%.1f%% Money", (comprehensiveInfo.moneyMultiplier - 1) * 100)
                                                end
                                                return "+0% Money"
                                            end)(),
                                            TextColor3 = Color3.fromRGB(100, 255, 100),
                                            TextSize = ScreenUtils.getProportionalTextSize(screenSize, 7),
                                            TextWrapped = false,
                                            BackgroundTransparency = 1,
                                            Font = Enum.Font.GothamBold,
                                            TextXAlignment = Enum.TextXAlignment.Center,
                                            TextYAlignment = Enum.TextYAlignment.Center,
                                            ZIndex = 35,
                                            LayoutOrder = 3
                                        }, {
                                            TextStroke = e("UIStroke", {
                                                Color = Color3.fromRGB(0, 0, 0),
                                                Thickness = 1.5,
                                                Transparency = 0.3
                                            })
                                        }),
                                        
                                        -- Size display
                                        PetSize = e("Frame", {
                                            Size = UDim2.new(1, 0, 0, 0),
                                            AutomaticSize = Enum.AutomaticSize.Y,
                                            BackgroundTransparency = 1,
                                            ZIndex = 35,
                                            LayoutOrder = 4
                                        }, {
                                            Layout = e("UIListLayout", {
                                                FillDirection = Enum.FillDirection.Horizontal,
                                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                                VerticalAlignment = Enum.VerticalAlignment.Center,
                                                Padding = UDim.new(0, 2),
                                                SortOrder = Enum.SortOrder.LayoutOrder
                                            }),
                                            
                                            SizeLabel = e("TextLabel", {
                                                Name = "SizeLabel",
                                                Size = UDim2.new(0, 0, 0, 14),
                                                AutomaticSize = Enum.AutomaticSize.X,
                                                Text = "Size: ",
                                                TextColor3 = Color3.fromRGB(80, 80, 80),
                                                TextSize = ScreenUtils.getProportionalTextSize(screenSize, 7),
                                                BackgroundTransparency = 1,
                                                Font = Enum.Font.GothamBold,
                                                ZIndex = 36,
                                                LayoutOrder = 1
                                            }),
                                            
                                            SizeValue = e("TextLabel", {
                                                Name = "SizeValue",
                                                Size = UDim2.new(0, 0, 0, 14),
                                                AutomaticSize = Enum.AutomaticSize.X,
                                                Text = (function()
                                                    local PetConfig = require(ReplicatedStorage.Shared.config.PetConfig)
                                                    local sizeData = PetConfig:GetSizeData(assignedPet.size or 1)
                                                    return sizeData.displayName
                                                end)(),
                                                TextColor3 = (function()
                                                    local PetConfig = require(ReplicatedStorage.Shared.config.PetConfig)
                                                    local sizeData = PetConfig:GetSizeData(assignedPet.size or 1)
                                                    return sizeData.color
                                                end)(),
                                                TextSize = ScreenUtils.getProportionalTextSize(screenSize, 7),
                                                BackgroundTransparency = 1,
                                                Font = Enum.Font.GothamBold,
                                                ZIndex = 36,
                                                LayoutOrder = 2
                                            })
                                        })
                                    })
                                elseif isEquippedSlot then
                                    -- Empty equipped slot
                                    return e("TextLabel", {
                                        Size = UDim2.new(1, 0, 1, 0),
                                        Text = "Empty",
                                        TextColor3 = Color3.fromRGB(150, 150, 150),
                                        TextSize = ScreenUtils.getProportionalTextSize(screenSize, 11),
                                        BackgroundTransparency = 1,
                                        Font = Enum.Font.Gotham,
                                        TextXAlignment = Enum.TextXAlignment.Center,
                                        TextYAlignment = Enum.TextYAlignment.Center,
                                        ZIndex = 34
                                    })
                                else
                                    -- Plus button for additional slots
                                    return e("TextButton", {
                                        Size = UDim2.new(1, 0, 1, 0),
                                        Text = "+",
                                        TextColor3 = Color3.fromRGB(255, 200, 50),
                                        TextSize = ScreenUtils.getProportionalTextSize(screenSize, 24),
                                        BackgroundTransparency = 1,
                                        Font = Enum.Font.GothamBold,
                                        TextXAlignment = Enum.TextXAlignment.Center,
                                        TextYAlignment = Enum.TextYAlignment.Center,
                                        ZIndex = 34,
                                        [React.Event.Activated] = function()
                                            -- Trigger pet slot expansion purchase
                                            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                                            if remotes and remotes:FindFirstChild("PromptProductPurchase") then
                                                remotes.PromptProductPurchase:FireServer("PetSlotExpansion")
                                            else
                                                warn("PetInventoryPanel: PromptProductPurchase remote not found")
                                            end
                                        end,
                                        [React.Event.MouseEnter] = function(button)
                                            button.TextColor3 = Color3.fromRGB(255, 220, 100)
                                        end,
                                        [React.Event.MouseLeave] = function(button)
                                            button.TextColor3 = Color3.fromRGB(255, 200, 50)
                                        end
                                    })
                                end
                            end)()
                        })
                    end
                    
                    return slots
                end)())
            }),
            
            -- Equip Best Button
            EquipBestButton = e("TextButton", {
                Name = "EquipBestButton",
                Size = UDim2.new(0, 120, 0, 30),
                Position = UDim2.new(0.5, -60, 0, 125),
                Text = "EQUIP BEST",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = ScreenUtils.getProportionalTextSize(screenSize, 12),
                BackgroundColor3 = Color3.fromRGB(100, 255, 100),
                BorderSizePixel = 0,
                Font = Enum.Font.GothamBold,
                ZIndex = 32,
                [React.Event.Activated] = function()
                    -- Get the PetAssignmentService to handle equipping best pets
                    local PetAssignmentService = require(script.Parent.Parent.services.PetAssignmentService)
                    PetAssignmentService.equipBestPets()
                end,
                [React.Event.MouseEnter] = function(button)
                    button.BackgroundColor3 = Color3.fromRGB(120, 255, 120)
                end,
                [React.Event.MouseLeave] = function(button)
                    button.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
                end
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 8)
                }),
                Stroke = e("UIStroke", {
                    Color = Color3.fromRGB(255, 255, 255),
                    Thickness = 2,
                    Transparency = 0.2
                }),
                TextStroke = e("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = 2,
                    Transparency = 0.3
                }),
                ButtonTextStroke = e("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = 2,
                    Transparency = 0.3,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
                })
            })
        }),
        
        -- Scrollable Cards Container
        CardsContainer = e("ScrollingFrame", {
            Name = "CardsContainer",
            Size = UDim2.new(1, -40, 1, -270),
            Position = UDim2.new(0, 20, 0, 260),
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
            
            -- Generate pet cards using PetCardComponent
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
                    -- Generate pet cards using PetCardComponent
                    for i, petItem in ipairs(petItems) do
                        local collectedTime = PetInventoryController.formatCollectionTime(petItem.latestCollectionTime)
                        local displayInfo = PetInventoryController.getPetDisplayInfo(petItem)
                        
                        cards["pet_" .. i] = PetCardComponent({
                            petItem = petItem,
                            displayInfo = displayInfo,
                            assignedPets = assignedPets,
                            screenSize = screenSize,
                            cardWidth = cardWidth,
                            cardHeight = cardHeight,
                            layoutOrder = i,
                            collectedTime = collectedTime
                        })
                    end
                end
                
                return cards
            end)())
        })
    })
    })
    })
end

return PetInventoryPanel