-- Pet Card Component
-- Reusable pet card UI extracted from PetInventoryPanel.lua
-- Handles individual pet card rendering and interactions

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.react)
local e = React.createElement

local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local AnimationHelpers = require(ReplicatedStorage.utils.AnimationHelpers)
local AssetLoader = require(ReplicatedStorage.utils.AssetLoader)
local PetAssignmentService = require(script.Parent.Parent.services.PetAssignmentService)

-- Import assets system
local assets = require(ReplicatedStorage.assets)

-- Import modular UI components for future refactoring
-- PetCardBadge: Reusable badge components (text, icon, quantity)
-- PetCardButton: Reusable button components (assign, action)
local PetCardBadge = require(script.Parent.ui.PetCardBadge)
local PetCardButton = require(script.Parent.ui.PetCardButton)

-- Function to get pet asset model (using new AssetLoader)
local function getPetAssetModel(petConfig)
    if not petConfig or not petConfig.assetPath then
        return nil
    end
    
    return AssetLoader.loadPetModel(petConfig.assetPath)
end

-- Sound effects placeholder
local function playSound(soundType)
    -- Placeholder for sound effects
end

local function PetCardComponent(props)
    local petItem = props.petItem
    local displayInfo = props.displayInfo
    local assignedPets = props.assignedPets
    local screenSize = props.screenSize
    local cardWidth = props.cardWidth
    local cardHeight = props.cardHeight
    local layoutOrder = props.layoutOrder or 1
    local hideAssignButton = props.hideAssignButton or false
    local onLabSelect = props.onLabSelect -- Lab-specific selection callback
    
    local pet = petItem.pet
    local quantity = petItem.quantity
    local collectedTime = props.collectedTime or ""
    
    
    -- Get rarity colors for styling
    local PetConstants = require(ReplicatedStorage.constants.PetConstants)
    local rarity = pet.rarity or 1
    local rarityColor = PetConstants.getRarityColor(rarity, false) -- Get single color, not gradient
    local rarityName = PetConstants.getRarityName(rarity)
    
    -- Get the actual pet model
    local petModel = getPetAssetModel(petItem.petConfig)
    
    -- Proportional sizing
    local cardTitleSize = ScreenUtils.getProportionalTextSize(screenSize, 20)
    local cardValueSize = ScreenUtils.getProportionalTextSize(screenSize, 16)
    local smallTextSize = ScreenUtils.getProportionalTextSize(screenSize, 14)
    
    -- Animation refs - removed to fix React hooks rule violation
    local petIconRef = nil
    local cardElement = nil
    
    return e("TextButton", {
        Name = "PetCard_" .. layoutOrder,
        Text = "",
        BackgroundColor3 = petItem.isAssigned and Color3.fromRGB(255, 255, 150) or Color3.fromRGB(255, 255, 255), -- Yellow if assigned
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        ZIndex = 32,
        LayoutOrder = layoutOrder,
        AutoButtonColor = false,
        Size = UDim2.new(0, cardWidth, 0, cardHeight),
        ref = function(element)
            cardElement = element
        end,
        [React.Event.MouseEnter] = function()
            playSound("hover")
            -- Animation removed to fix React hooks issue
        end,
        [React.Event.Activated] = function()
            -- Animation removed to fix React hooks issue
            if cardElement then
                AnimationHelpers.createBounceAnimation(cardElement)
            end
            
            -- Handle lab selection if callback provided
            if onLabSelect then
                onLabSelect()
                return
            end
            
            -- Handle assign/unassign when card is clicked
            if petItem.isAssigned and petItem.samplePet then
                -- Unassign this pet using the service
                PetAssignmentService.unassignPet(petItem.samplePet)
            elseif petItem.samplePet then
                -- Check if we can assign more pets using the service
                local canAssign = PetAssignmentService.canAssignPet(assignedPets, petItem.samplePet)
                if canAssign then
                    PetAssignmentService.assignPet(petItem.samplePet)
                end
            end
        end
    }, {
        Corner = e("UICorner", {
            CornerRadius = UDim.new(0, 15)
        }),
        
        -- Card Gradient Background (subtle aura tint)
        CardGradient = e("UIGradient", {
            Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(1, Color3.new(
                    math.min(1, 0.95 + petItem.auraData.color.R * 0.05),
                    math.min(1, 0.95 + petItem.auraData.color.G * 0.05),
                    math.min(1, 0.95 + petItem.auraData.color.B * 0.05)
                ))
            },
            Rotation = 45
        }),
        
        
        -- Boost Badge (above pet picture, sized to fit text)
        BoostBadge = (displayInfo.boostText ~= "" and displayInfo.boostText ~= "0.0% money") and e("Frame", {
            Name = "BoostBadge",
            Size = UDim2.new(0, 0, 0, 20), -- AutomaticSize will handle width
            Position = UDim2.new(0.5, 0, 0.06, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(100, 255, 100),
            BorderSizePixel = 0,
            ZIndex = 36,
            AutomaticSize = Enum.AutomaticSize.X
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 10) -- Rounded rectangle
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(255, 255, 255),
                Thickness = 2,
                Transparency = 0.1
            }),
            Padding = e("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
                PaddingTop = UDim.new(0, 2),
                PaddingBottom = UDim.new(0, 2)
            }),
            BoostText = e("TextLabel", {
                Size = UDim2.new(0, 0, 1, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                Text = displayInfo.boostText:gsub("%% money", "%%"):gsub("%.0%%", "%%"), -- Clean up the text
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = ScreenUtils.getProportionalTextSize(screenSize, 9),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 37
            }, {
                TextStroke = e("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = 1.5,
                    Transparency = 0.3
                })
            })
        }) or nil,
        
        -- Divider between boost and pet
        BoostDivider = (displayInfo.boostText ~= "" and displayInfo.boostText ~= "0.0% money") and e("Frame", {
            Name = "BoostDivider",
            Size = UDim2.new(0.6, 0, 0, 1),
            Position = UDim2.new(0.2, 0, 0.11, 0),
            BackgroundColor3 = Color3.fromRGB(180, 180, 180),
            BorderSizePixel = 0,
            ZIndex = 33
        }) or nil,
        
        -- Pet Model Display
        PetIcon = petModel and e("ViewportFrame", {
            Name = "PetIcon",
            Size = UDim2.new(1, 0, 0.45, 0),
            Position = UDim2.new(0.5, 0, 0.15, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 33,
            ClipsDescendants = false,
            ref = function(viewportFrame)
                petIconRef = viewportFrame
                if viewportFrame and petModel then
                    -- Set up the viewport to display the pet model
                    local clonedModel = petModel:Clone()
                    clonedModel.Parent = viewportFrame
                    
                    -- Create camera for viewport
                    local camera = Instance.new("Camera")
                    camera.Parent = viewportFrame
                    viewportFrame.CurrentCamera = camera
                    
                    -- Position camera to show the pet model nicely (angled view, final positioning)
                    local cf, size = clonedModel:GetBoundingBox()
                    local maxExtent = math.max(size.X, size.Y, size.Z)
                    local cameraDistance = maxExtent * 1.3-- Even closer camera
                    -- Final angled view positioning
                    camera.CFrame = CFrame.lookAt(
                        cf.Position + Vector3.new(cameraDistance * -1.75, cameraDistance * 0.3, -cameraDistance),
                        cf.Position
                    )
                end
            end
        }, {}) or e("TextLabel", {
            Name = "PetIcon",
            Size = UDim2.new(0.6, 0, 0.35, 0),
            Position = UDim2.new(0.5, 0, 0.15, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Text = "🐾",
            TextSize = ScreenUtils.getProportionalTextSize(screenSize, 18),
            TextWrapped = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansBold,
            ZIndex = 33,
            ref = function(element)
                petIconRef = element
            end
        }, {
            -- Size indicator on top of pet icon
            SizeIndicator = e("Frame", {
                Name = "SizeIndicator",
                Size = UDim2.new(0.8, 0, 0.3, 0),
                Position = UDim2.new(0.5, 0, 0, 0),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundColor3 = (petItem.sizeData and petItem.sizeData.color) or Color3.fromRGB(150, 150, 150),
                BorderSizePixel = 0,
                ZIndex = 34
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 8)
                }),
                SizeText = e("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = (petItem.sizeData and petItem.sizeData.displayName and petItem.sizeData.displayName:upper()) or "TINY",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.getProportionalTextSize(screenSize, 10),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.SourceSansBold,
                    ZIndex = 35
                })
            }),
            
            
        }),
        
        -- Pet Name
        PetName = e("TextLabel", {
            Name = "PetName",
            Size = UDim2.new(0.9, 0, 0.12, 0),
            Position = UDim2.new(0.05, 0, 0.30, 0),
            Text = pet.name:upper(),
            TextColor3 = Color3.fromRGB(40, 40, 40),
            TextSize = ScreenUtils.getProportionalTextSize(screenSize, 15),
            TextWrapped = true,
            TextScaled = false,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 33
        }),
        
        -- Divider after pet name
        NameDivider = e("Frame", {
            Name = "NameDivider",
            Size = UDim2.new(0.8, 0, 0, 1),
            Position = UDim2.new(0.1, 0, 0.44, 0),
            BackgroundColor3 = Color3.fromRGB(200, 200, 200),
            BorderSizePixel = 0,
            ZIndex = 33
        }),
        
        -- Combined Rarity Display (e.g., "1/1000")
        CombinedRarity = e("TextLabel", {
            Name = "CombinedRarity",
            Size = UDim2.new(0.9, 0, 0.04, 0),
            Position = UDim2.new(0.05, 0, 0.47, 0),
            Text = displayInfo.combinedRarityText .. " • " .. displayInfo.rarityTierName,
            TextColor3 = displayInfo.rarityTierColor,
            TextSize = ScreenUtils.getProportionalTextSize(screenSize, 11),
            TextWrapped = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            ZIndex = 33
        }, {
            TextStroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 2,
                Transparency = 0
            })
        }),
        
        
        -- Rarity Row (full width)
        RarityRow = e("Frame", {
            Name = "RarityRow",
            Size = UDim2.new(0.9, 0, 0.035, 0),
            Position = UDim2.new(0.05, 0, 0.535, 0),
            BackgroundTransparency = 1,
            ZIndex = 33
        }, {
            Layout = e("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder
            }),
            
            RarityLabel = e("TextLabel", {
                Name = "RarityLabel",
                Size = UDim2.new(0, 0, 1, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                Text = "Rarity: ",
                TextColor3 = Color3.fromRGB(60, 60, 60),
                TextSize = ScreenUtils.getProportionalTextSize(screenSize, 10),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                ZIndex = 34,
                LayoutOrder = 1
            }),
            
            RarityValue = e("TextLabel", {
                Name = "RarityValue",
                Size = UDim2.new(0, 0, 1, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                Text = rarityName,
                TextColor3 = rarityColor,
                TextSize = ScreenUtils.getProportionalTextSize(screenSize, 12),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                ZIndex = 34,
                LayoutOrder = 2
            }, {
                TextStroke = e("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = 1.5,
                    Transparency = 0
                })
            })
        }),
        
        -- Aura Row (full width)
        AuraRow = e("Frame", {
            Name = "AuraRow",
            Size = UDim2.new(0.9, 0, 0.035, 0),
            Position = UDim2.new(0.05, 0, 0.585, 0),
            BackgroundTransparency = 1,
            ZIndex = 33
        }, {
            Layout = e("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder
            }),
            
            AuraLabel = e("TextLabel", {
                Name = "AuraLabel",
                Size = UDim2.new(0, 0, 1, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                Text = "Aura: ",
                TextColor3 = Color3.fromRGB(60, 60, 60),
                TextSize = ScreenUtils.getProportionalTextSize(screenSize, 12),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                ZIndex = 34,
                LayoutOrder = 1
            }),
            
            AuraValue = e("TextLabel", {
                Name = "AuraValue",
                Size = UDim2.new(0, 0, 1, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                Text = (petItem.aura ~= "none" and petItem.auraData.name or "Basic"),
                TextColor3 = petItem.aura ~= "none" and petItem.auraData.color or Color3.fromRGB(150, 150, 150),
                TextSize = ScreenUtils.getProportionalTextSize(screenSize, 12),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                ZIndex = 34,
                LayoutOrder = 2
            }, {
                TextStroke = e("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = 1.5,
                    Transparency = 0
                })
            })
        }),
        
        -- Size Row (full width)
        SizeRow = e("Frame", {
            Name = "SizeRow",
            Size = UDim2.new(0.9, 0, 0.035, 0),
            Position = UDim2.new(0.05, 0, 0.635, 0),
            BackgroundTransparency = 1,
            ZIndex = 33
        }, {
            Layout = e("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder
            }),
            
            SizeLabel = e("TextLabel", {
                Name = "SizeLabel",
                Size = UDim2.new(0, 0, 1, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                Text = "Size: ",
                TextColor3 = Color3.fromRGB(60, 60, 60),
                TextSize = ScreenUtils.getProportionalTextSize(screenSize, 12),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                ZIndex = 34,
                LayoutOrder = 1
            }),
            
            SizeValue = e("TextLabel", {
                Name = "SizeValue",
                Size = UDim2.new(0, 0, 1, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                Text = (petItem.sizeData and petItem.sizeData.displayName or "Tiny"),
                TextColor3 = (petItem.sizeData and petItem.sizeData.color or Color3.fromRGB(150, 150, 150)),
                TextSize = ScreenUtils.getProportionalTextSize(screenSize, 12),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                ZIndex = 34,
                LayoutOrder = 2
            }, {
                TextStroke = e("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = 1.5,
                    Transparency = 0
                })
            })
        }),
        
        -- Divider after size
        SizeDivider = e("Frame", {
            Name = "SizeDivider",
            Size = UDim2.new(0.8, 0, 0, 1),
            Position = UDim2.new(0.1, 0, 0.685, 0),
            BackgroundColor3 = Color3.fromRGB(200, 200, 200),
            BorderSizePixel = 0,
            ZIndex = 33
        }),
        
        
        -- Value Display
        ValueContainer = e("Frame", {
            Name = "ValueContainer",
            Size = UDim2.new(0.9, 0, 0.04, 0),
            Position = UDim2.new(0.05, 0, 0.715, 0),
            BackgroundTransparency = 1,
            ZIndex = 33
        }, {
            Layout = e("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder
            }),
            
            CashIcon = e("ImageLabel", {
                Name = "CashIcon",
                Size = UDim2.new(0, cardValueSize, 0, cardValueSize),
                Image = (assets and assets["vector-icon-pack-2/General/Money/Money Filled 256.png"]) or "",
                BackgroundTransparency = 1,
                ScaleType = Enum.ScaleType.Fit,
                ImageColor3 = Color3.fromRGB(255, 215, 0),
                ZIndex = 34,
                LayoutOrder = 1,
                Visible = assets and assets["vector-icon-pack-2/General/Money/Money Filled 256.png"] ~= nil
            }),
            
            -- Fallback cash emoji if asset doesn't load
            CashEmoji = e("TextLabel", {
                Name = "CashEmoji",
                Size = UDim2.new(0, cardValueSize, 0, cardValueSize),
                Text = "💰",
                TextSize = ScreenUtils.getProportionalTextSize(screenSize, 12),
                TextColor3 = Color3.fromRGB(255, 215, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 34,
                LayoutOrder = 1,
                Visible = not (assets and assets["vector-icon-pack-2/General/Money/Money Filled 256.png"])
            }),
            
            ValueLabel = e("TextLabel", {
                Name = "ValueText",
                Size = UDim2.new(0, 0, 1, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                Text = displayInfo.enhancedValue .. " each",
                TextColor3 = Color3.fromRGB(100, 255, 100),
                TextSize = ScreenUtils.getProportionalTextSize(screenSize, 14),
                TextWrapped = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSans,
                ZIndex = 34,
                LayoutOrder = 2
            }, {
                TextStroke = e("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = 2,
                    Transparency = 0.3
                })
            })
        }),
        
        -- Divider after value
        ValueDivider = e("Frame", {
            Name = "ValueDivider",
            Size = UDim2.new(0.8, 0, 0, 1),
            Position = UDim2.new(0.1, 0, 0.77, 0),
            BackgroundColor3 = Color3.fromRGB(200, 200, 200),
            BorderSizePixel = 0,
            ZIndex = 33
        }),
        
        -- Assign button removed - click the card directly to assign/unassign
        
        -- Collection Time Display (at bottom of card)
        CollectionTime = collectedTime ~= "" and e("TextLabel", {
            Name = "CollectionTime",
            Size = UDim2.new(0.9, 0, 0.03, 0),
            Position = UDim2.new(0.5, 0, 0.85, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Text = "Latest: " .. collectedTime,
            TextColor3 = Color3.fromRGB(120, 120, 120),
            TextSize = ScreenUtils.getProportionalTextSize(screenSize, 10),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            ZIndex = 33
        }) or nil,
        
        -- Assignment Status Badge (if assigned)
        AssignmentBadge = petItem.isAssigned and e("Frame", {
            Name = "AssignmentBadge",
            Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 30), 0, ScreenUtils.getProportionalSize(screenSize, 20)),
            Position = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 4), 0, ScreenUtils.getProportionalSize(screenSize, 4)),
            BackgroundColor3 = Color3.fromRGB(100, 255, 100),
            BorderSizePixel = 0,
            ZIndex = 34
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 10)
            }),
            AssignmentText = e("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                Text = "★",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = ScreenUtils.getProportionalTextSize(screenSize, 12),
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 35
            })
        }) or nil,
        
        -- Quantity Badge (positioned above the pet model)
        QuantityBadge = quantity > 1 and e("Frame", {
                Name = "QuantityBadge",
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 32), 0, ScreenUtils.getProportionalSize(screenSize, 20)),
                Position = UDim2.new(0.5, 0, 0, ScreenUtils.getProportionalSize(screenSize, 5)),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundColor3 = Color3.fromRGB(255, 80, 80),
                BorderSizePixel = 0,
                ZIndex = 40
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 12)
                }),
                QuantityText = e("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "x" .. quantity,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.getProportionalTextSize(screenSize, 12),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    ZIndex = 41
                }, {
                    TextStroke = e("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = 2,
                        Transparency = 0.2
                    })
                })
            }) or nil,
        
        -- Aura-colored stroke (moved to end to ensure it's on top)
        AuraStroke = e("UIStroke", {
            Color = petItem.auraData and petItem.auraData.color or Color3.fromRGB(255, 0, 0), -- Debug with red if no aura data
            Thickness = 5,
            Transparency = 0.0, -- Make it fully visible
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        })
    })
end

return PetCardComponent