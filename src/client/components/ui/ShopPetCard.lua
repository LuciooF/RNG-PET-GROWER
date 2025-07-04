-- Shop Pet Card Component
-- Based on PetCardComponent design but adapted for shop purchases
-- Replaces assign button with purchase button, keeps LIMITED/HOT badges

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.react)
local e = React.createElement

-- Import shared utilities
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)
local AnimationHelpers = require(ReplicatedStorage.utils.AnimationHelpers)
local AssetLoader = require(ReplicatedStorage.utils.AssetLoader)
local PetConstants = require(ReplicatedStorage.constants.PetConstants)

-- Function to get pet asset model
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

local function ShopPetCard(props)
    local product = props.product
    local layoutOrder = props.layoutOrder or 1
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local onPurchase = props.onPurchase or function() end
    local customSize = props.customSize -- New prop for custom sizing
    
    if not product or not product.petData then
        return nil
    end
    
    local petData = product.petData
    
    -- Use custom size if provided, otherwise use default sizing
    local cardWidth, cardHeight
    if customSize then
        cardWidth = customSize.width
        cardHeight = customSize.height
    else
        -- Default sizing - made cards taller to accommodate massive pet image
        cardWidth = ScreenUtils.getProportionalSize(screenSize, 180)
        cardHeight = ScreenUtils.getProportionalSize(screenSize, 320) -- Increased from 220 to 320
    end
    
    -- Get rarity colors for styling
    local rarity = petData.rarity or 1
    local rarityColor = PetConstants.getRarityColor(rarity, false) -- Get single color, not gradient
    local rarityName = PetConstants.getRarityName(rarity)
    
    -- Get the actual pet model (always use Cyber Dominus for now)
    local cyberDominusPetData = {
        name = "Cyber Dominus",
        assetPath = "Pets/Cyber Dominus",
        rarity = petData.rarity,
        value = petData.value,
        baseBoost = petData.baseBoost
    }
    local petModel = getPetAssetModel(cyberDominusPetData)
    
    -- Proportional sizing
    local cardTitleSize = ScreenUtils.getProportionalTextSize(screenSize, 20)
    local cardValueSize = ScreenUtils.getProportionalTextSize(screenSize, 16)
    local smallTextSize = ScreenUtils.getProportionalTextSize(screenSize, 14)
    
    -- Check if this is a featured/premium card
    local isFeatured = (layoutOrder or 1) % 3 == 0
    local isPremium = product.price >= 1500
    
    -- Animation refs
    local petIconRef = nil
    local cardElement = nil
    
    return e("Frame", {
        Name = "ShopPetCardContainer",
        Size = customSize and UDim2.new(1, -10, 1, -10) or UDim2.new(0, cardWidth, 0, cardHeight),
        Position = customSize and UDim2.new(0, 5, 0, 5) or UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        LayoutOrder = layoutOrder,
        ZIndex = 104
    }, {
        PetCard = e("TextButton", {
            Name = "PetCard_" .. layoutOrder,
            Text = "",
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
            ZIndex = 32,
            AutoButtonColor = false,
            Size = UDim2.new(1, 0, 1, 0),
            ref = function(element)
                cardElement = element
            end,
            [React.Event.MouseEnter] = function()
                playSound("hover")
            end,
            [React.Event.Activated] = function()
                if cardElement then
                    AnimationHelpers.createBounceAnimation(cardElement)
                end
            end
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 15)
            }),
            
            -- Simple black border for clarity
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 2,
                Transparency = 0
            }),
            
            -- Card Gradient Background (subtle rainbow tint)
            CardGradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(248, 252, 255))
                },
                Rotation = 45
            }),
            
            
            -- Boost Display (above pet image)
            BoostBadge = e("Frame", {
                Name = "BoostBadge",
                Size = UDim2.new(0, math.max(80, cardWidth * 0.5), 0, math.max(20, cardHeight * 0.06)),
                Position = UDim2.new(0.5, 0, 0.05, 0),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundColor3 = Color3.fromRGB(34, 139, 34),
                BorderSizePixel = 0,
                ZIndex = 35
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 10)
                }),
                
                BoostGradient = e("UIGradient", {
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 205, 50)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(34, 139, 34))
                    },
                    Rotation = 45
                }),
                
                BoostText = e("TextLabel", {
                    Name = "BoostText",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "+" .. math.floor((petData.baseBoost / 100) * 10) .. "% BOOST!",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = math.max(8, cardHeight * 0.025),
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    ZIndex = 36
                }, {
                    TextStroke = e("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = 2,
                        Transparency = 0.3
                    })
                })
            }),
            
            -- Pet Model Display (4x bigger - MASSIVE) - moved down to make room for boost badge
            PetIcon = petModel and e("ViewportFrame", {
                Name = "PetIcon",
                Size = UDim2.new(2.4, 0, 1.2, 0),
                Position = UDim2.new(0.5, 0, 0.38, 0),
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
                        local cameraDistance = maxExtent * 1.3
                        camera.CFrame = CFrame.lookAt(
                            cf.Position + Vector3.new(cameraDistance * -1.75, cameraDistance * 0.3, -cameraDistance),
                            cf.Position
                        )
                    end
                end
            }, {}) or e("TextLabel", {
                Name = "PetIcon",
                Size = UDim2.new(2.0, 0, 1.2, 0),
                Position = UDim2.new(0.5, 0, 0.38, 0),
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
            }, {}),
            
            -- Label under pet image (OP, Limited, etc.) - moved higher
            UnderPetLabel = e("Frame", {
                Name = "UnderPetLabel",
                Size = UDim2.new(0, math.max(60, cardWidth * 0.4), 0, math.max(18, cardHeight * 0.055)),
                Position = UDim2.new(0.5, 0, 0.55, 0),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundColor3 = (function()
                    if product.price >= 2000 then
                        return Color3.fromRGB(138, 43, 226) -- Purple for OP
                    elseif isPremium then
                        return Color3.fromRGB(255, 80, 80) -- Red for Limited
                    elseif isFeatured then
                        return Color3.fromRGB(255, 215, 0) -- Gold for Hot
                    else
                        return Color3.fromRGB(255, 0, 127) -- Pink for Rainbow
                    end
                end)(),
                BorderSizePixel = 0,
                ZIndex = 35
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 10)
                }),
                
                LabelGradient = e("UIGradient", {
                    Color = (function()
                        if product.price >= 2000 then
                            return ColorSequence.new{
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(148, 0, 211)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(75, 0, 130))
                            }
                        elseif isPremium then
                            return ColorSequence.new{
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 100)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 20, 20))
                            }
                        elseif isFeatured then
                            return ColorSequence.new{
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 235, 59)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 193, 7))
                            }
                        else
                            return ColorSequence.new{
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 128)),
                                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 165, 0)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(128, 0, 255))
                            }
                        end
                    end)(),
                    Rotation = 45
                }),
                
                LabelText = e("TextLabel", {
                    Name = "LabelText",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = (function()
                        if product.price >= 2000 then
                            return "💀 OP!"
                        elseif isPremium then
                            return "⏰ LIMITED"
                        elseif isFeatured then
                            return "🔥 HOT!"
                        else
                            return "🌈 RAINBOW"
                        end
                    end)(),
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = math.max(8, cardHeight * 0.025),
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    ZIndex = 36
                }, {
                    TextStroke = e("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = 2,
                        Transparency = 0.3
                    })
                })
            }),
            
            -- Pet Name
            PetName = e("TextLabel", {
                Name = "PetName",
                Size = UDim2.new(0.9, 0, 0.06, 0),
                Position = UDim2.new(0.05, 0, 0.62, 0),
                Text = petData.name:upper(),
                TextColor3 = Color3.fromRGB(40, 40, 40),
                TextSize = cardTitleSize,
                TextWrapped = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 33
            }),
            
            -- Rarity Header (above rarity badge)
            RarityHeader = e("TextLabel", {
                Name = "RarityHeader",
                Size = UDim2.new(0.4, 0, 0.03, 0),
                Position = UDim2.new(0.3, 0, 0.72, 0),
                AnchorPoint = Vector2.new(0.5, 0),
                Text = "RARITY",
                TextColor3 = Color3.fromRGB(80, 80, 80),
                TextSize = ScreenUtils.getProportionalTextSize(screenSize, 8),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 34
            }),
            
            -- Aura Header (above aura badge)  
            AuraHeader = e("TextLabel", {
                Name = "AuraHeader",
                Size = UDim2.new(0.4, 0, 0.03, 0),
                Position = UDim2.new(0.7, 0, 0.72, 0),
                AnchorPoint = Vector2.new(0.5, 0),
                Text = "AURA",
                TextColor3 = Color3.fromRGB(80, 80, 80),
                TextSize = ScreenUtils.getProportionalTextSize(screenSize, 8),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 34
            }),
            
            -- Rarity Badge
            RarityBadge = e("Frame", {
                Name = "RarityBadge",
                Size = UDim2.new(0.4, 0, 0.05, 0),
                Position = UDim2.new(0.3, 0, 0.75, 0),
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
                Size = UDim2.new(0.4, 0, 0.05, 0),
                Position = UDim2.new(0.7, 0, 0.75, 0),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundColor3 = Color3.fromRGB(150, 150, 150), -- Default gray for basic aura
                BorderSizePixel = 0,
                ZIndex = 33
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 8)
                }),
                AuraText = e("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "BASIC", -- Default basic aura for shop pets
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
            
            
            -- Purchase Button (centered, replacing assign button)
            PurchaseButton = e("TextButton", {
                Name = "PurchaseButton",
                Size = UDim2.new(0.8, 0, 0.09, 0),
                Position = UDim2.new(0.5, 0, 0.87, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Text = "💎 BUY " .. NumberFormatter.formatCurrency(product.price) .. " R$",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = ScreenUtils.getProportionalTextSize(screenSize, 12),
                BackgroundColor3 = Color3.fromRGB(255, 80, 80),
                BorderSizePixel = 0,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 34,
                [React.Event.Activated] = function()
                    onPurchase(product)
                end
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 8)
                }),
                
                -- Purchase button gradient
                Gradient = e("UIGradient", {
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 100)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 20, 20))
                    },
                    Rotation = 45
                }),
                
                TextStroke = e("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = 2,
                    Transparency = 0.3
                })
            })
        })
    })
end

return ShopPetCard