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
    local layoutOrder = props.layoutOrder
    
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
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
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
        
        -- Rarity Header (above existing rarity badge at 0.54)
        RarityHeader = e("TextLabel", {
            Name = "RarityHeader",
            Size = UDim2.new(0.4, 0, 0.03, 0),
            Position = UDim2.new(0.3, 0, 0.51, 0), -- Just above rarity badge
            AnchorPoint = Vector2.new(0.5, 0),
            Text = "RARITY",
            TextColor3 = Color3.fromRGB(80, 80, 80),
            TextSize = ScreenUtils.getProportionalTextSize(screenSize, 8),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 34
        }),
        
        -- Aura Header (above existing aura badge at 0.54)  
        AuraHeader = e("TextLabel", {
            Name = "AuraHeader",
            Size = UDim2.new(0.4, 0, 0.03, 0),
            Position = UDim2.new(0.7, 0, 0.51, 0), -- Just above aura badge
            AnchorPoint = Vector2.new(0.5, 0),
            Text = "AURA",
            TextColor3 = Color3.fromRGB(80, 80, 80),
            TextSize = ScreenUtils.getProportionalTextSize(screenSize, 8),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 34
        }),
        
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
        
        -- Pet Name with Combined Rarity
        PetName = e("TextLabel", {
            Name = "PetName",
            Size = UDim2.new(0.9, 0, 0.06, 0),
            Position = UDim2.new(0.05, 0, 0.32, 0),
            Text = pet.name:upper(),
            TextColor3 = Color3.fromRGB(40, 40, 40),
            TextSize = cardTitleSize,
            TextWrapped = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansBold,
            ZIndex = 33
        }),
        
        -- Combined Rarity Display (e.g., "1/1000")
        CombinedRarity = e("TextLabel", {
            Name = "CombinedRarity",
            Size = UDim2.new(0.9, 0, 0.04, 0),
            Position = UDim2.new(0.05, 0, 0.38, 0),
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
                Transparency = 0.3
            })
        }),
        
        -- Pet Description
        PetDescription = e("TextLabel", {
            Name = "PetDescription",
            Size = UDim2.new(0.9, 0, 0.10, 0),
            Position = UDim2.new(0.05, 0, 0.42, 0),
            Text = displayInfo.description,
            TextColor3 = Color3.fromRGB(70, 80, 120),
            TextSize = ScreenUtils.getProportionalTextSize(screenSize, 12),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextWrapped = true,
            ZIndex = 33
        }),
        
        -- Rarity Badge
        RarityBadge = e("Frame", {
            Name = "RarityBadge",
            Size = UDim2.new(0.4, 0, 0.06, 0),
            Position = UDim2.new(0.3, 0, 0.54, 0),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundColor3 = rarityColor,
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
            }, {
                TextStroke = e("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = 2,
                    Transparency = 0.3
                })
            })
        }),
        
        -- Aura Badge (always shown, "Basic" for no aura)
        AuraBadge = e("Frame", {
            Name = "AuraBadge",
            Size = UDim2.new(0.4, 0, 0.06, 0),
            Position = UDim2.new(0.7, 0, 0.54, 0),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundColor3 = petItem.aura ~= "none" and petItem.auraData.color or Color3.fromRGB(150, 150, 150),
            BorderSizePixel = 0,
            ZIndex = 33
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 8)
            }),
            AuraText = e("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                Text = petItem.aura ~= "none" and petItem.auraData.name:upper() or "BASIC",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = smallTextSize,
                TextWrapped = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 34
            }, {
                TextStroke = e("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = 2,
                    Transparency = 0.3
                })
            })
        }),
        
        -- Boost Display with Icon
        BoostContainer = displayInfo.boostText ~= "" and e("Frame", {
            Name = "BoostContainer",
            Size = UDim2.new(0.9, 0, 0.06, 0),
            Position = UDim2.new(0.05, 0, 0.62, 0),
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
            
            BoostIcon = e("ImageLabel", {
                Name = "BoostIcon",
                Size = UDim2.new(0, cardValueSize, 0, cardValueSize),
                Image = "", -- Could add boost icon here
                BackgroundTransparency = 1,
                ScaleType = Enum.ScaleType.Fit,
                ImageColor3 = Color3.fromRGB(100, 255, 100),
                ZIndex = 34,
                LayoutOrder = 1
            }),
            
            BoostLabel = e("TextLabel", {
                Name = "BoostText",
                Size = UDim2.new(0, 0, 1, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                Text = displayInfo.boostText,
                TextColor3 = Color3.fromRGB(100, 255, 100),
                TextSize = cardValueSize,
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
        }) or nil,
        
        -- Value Display
        ValueContainer = e("Frame", {
            Name = "ValueContainer",
            Size = UDim2.new(0.9, 0, 0.06, 0),
            Position = UDim2.new(0.05, 0, 0.70, 0),
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
                Image = "", -- Could use AssetLoader for cash icon
                BackgroundTransparency = 1,
                ScaleType = Enum.ScaleType.Fit,
                ImageColor3 = Color3.fromRGB(255, 215, 0),
                ZIndex = 34,
                LayoutOrder = 1
            }),
            
            ValueLabel = e("TextLabel", {
                Name = "ValueText",
                Size = UDim2.new(0, 0, 1, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                Text = displayInfo.enhancedValue .. " each",
                TextColor3 = Color3.fromRGB(100, 255, 100),
                TextSize = cardValueSize,
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
        
        -- Assign/Unassign Button (centered)
        AssignButton = e("TextButton", {
            Name = "AssignButton",
            Size = UDim2.new(0.4, 0, 0.08, 0),
            Position = UDim2.new(0.5, 0, 0.86, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Text = (function()
                if petItem.isAssigned then
                    return "UNASSIGN"
                elseif #assignedPets >= 3 then
                    return "FULL"
                else
                    return "ASSIGN"
                end
            end)(),
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = ScreenUtils.getProportionalTextSize(screenSize, 12),
            BackgroundColor3 = (function()
                if petItem.isAssigned then
                    return Color3.fromRGB(200, 80, 80) -- Red for unassign
                elseif #assignedPets >= 3 then
                    return Color3.fromRGB(120, 120, 120) -- Gray for full
                else
                    return Color3.fromRGB(80, 200, 80) -- Green for assign
                end
            end)(),
            BorderSizePixel = 0,
            Font = Enum.Font.SourceSansBold,
            ZIndex = 34,
            Active = #assignedPets < 3 or petItem.isAssigned,
            [React.Event.Activated] = function()
                if petItem.isAssigned and petItem.samplePet then
                    -- Unassign this pet using the service
                    PetAssignmentService.unassignPet(petItem.samplePet)
                elseif #assignedPets < 3 and petItem.samplePet then
                    -- Assign this pet using the service
                    PetAssignmentService.assignPet(petItem.samplePet)
                end
            end
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 8)
            }),
            TextStroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 2,
                Transparency = 0.3
            })
        }),
        
        -- Collection Time Display (below assign button)
        CollectionTime = collectedTime ~= "" and e("TextLabel", {
            Name = "CollectionTime",
            Size = UDim2.new(0.9, 0, 0.04, 0),
            Position = UDim2.new(0.5, 0, 0.94, 0),
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