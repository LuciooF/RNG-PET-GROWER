-- Lab Pet Slot Component
-- Reusable slot for displaying selected pets in lab interface
-- Extracted from LabPanel.lua following CLAUDE.md modular architecture patterns

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.react)
local e = React.createElement

local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local assets = require(ReplicatedStorage.assets)

local function LabPetSlot(props)
    local slotIndex = props.slotIndex or 1
    local selectedPet = props.selectedPet
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local onRemove = props.onRemove or function() end
    
    local getProportionalTextSize = ScreenUtils.getProportionalTextSize
    
    -- Responsive sizing variables
    local slotWidth = ScreenUtils.getProportionalSize(screenSize, 120)
    local slotHeight = ScreenUtils.getProportionalSize(screenSize, 160)
    local imageSize = ScreenUtils.getProportionalSize(screenSize, 60)
    local removeButtonSize = ScreenUtils.getProportionalSize(screenSize, 20)
    
    return e("Frame", {
        Name = "Slot" .. slotIndex,
        Size = UDim2.new(0, slotWidth, 0, slotHeight),
        BackgroundColor3 = selectedPet and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200),
        BackgroundTransparency = selectedPet and 0.1 or 0.3,
        BorderSizePixel = 0,
        ZIndex = 54,
        LayoutOrder = slotIndex
    }, {
        Corner = e("UICorner", {
            CornerRadius = UDim.new(0, 12)
        }),
        Stroke = e("UIStroke", {
            Color = selectedPet and Color3.fromRGB(255, 150, 50) or Color3.fromRGB(150, 150, 150),
            Thickness = 2,
            Transparency = 0.2
        }),
        
        -- Content based on whether pet is selected
        Content = selectedPet and e("Frame", {
            Size = UDim2.new(1, -10, 1, -10),
            Position = UDim2.new(0, 5, 0, 5),
            BackgroundTransparency = 1,
            ZIndex = 55
        }, {
            Layout = e("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Top,
                Padding = UDim.new(0, 3),
                SortOrder = Enum.SortOrder.LayoutOrder
            }),
            
            -- Pet Name with Size
            PetName = e("TextLabel", {
                Size = UDim2.new(1, 0, 0, 18),
                Text = selectedPet.name .. " (" .. (selectedPet.sizeData and selectedPet.sizeData.displayName or "Tiny") .. ")",
                TextColor3 = Color3.fromRGB(60, 80, 140),
                TextSize = getProportionalTextSize(screenSize, 11),
                TextWrapped = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 56,
                LayoutOrder = 1
            }),
            
            -- Pet Image (using AssetLoader)
            PetImage = (function()
                local AssetLoader = require(ReplicatedStorage.utils.AssetLoader)
                local petModel = AssetLoader.loadPetModel(selectedPet.petConfig.assetPath)
                
                if petModel then
                    return e("ViewportFrame", {
                        Size = UDim2.new(0, imageSize, 0, imageSize),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        ZIndex = 56,
                        LayoutOrder = 2,
                        ref = function(viewportFrame)
                            if viewportFrame and petModel then
                                local clonedModel = petModel:Clone()
                                clonedModel.Parent = viewportFrame
                                
                                local camera = Instance.new("Camera")
                                camera.Parent = viewportFrame
                                viewportFrame.CurrentCamera = camera
                                
                                local cf, size = clonedModel:GetBoundingBox()
                                local maxExtent = math.max(size.X, size.Y, size.Z)
                                local cameraDistance = maxExtent * 1.5
                                camera.CFrame = CFrame.lookAt(
                                    cf.Position + Vector3.new(cameraDistance * -1.75, cameraDistance * 0.3, -cameraDistance),
                                    cf.Position
                                )
                            end
                        end
                    })
                else
                    return e("TextLabel", {
                        Size = UDim2.new(0, imageSize, 0, imageSize),
                        Text = "🐾",
                        TextSize = getProportionalTextSize(screenSize, 24),
                        TextColor3 = Color3.fromRGB(100, 100, 100),
                        BackgroundTransparency = 1,
                        Font = Enum.Font.SourceSansBold,
                        ZIndex = 56,
                        LayoutOrder = 2
                    })
                end
            end)(),
            
            -- Combined Rarity
            RarityText = (function()
                local PetConfig = require(ReplicatedStorage.Shared.config.PetConfig)
                local comprehensiveInfo = PetConfig:GetComprehensivePetInfo(selectedPet.pet.id, selectedPet.pet.aura, selectedPet.pet.size)
                local rarityText = comprehensiveInfo and comprehensiveInfo.rarityText or ("1/" .. (selectedPet.pet.rarity or 1))
                local rarityColor = comprehensiveInfo and comprehensiveInfo.rarityColor or Color3.fromRGB(150, 150, 150)
                
                return e("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 14),
                    Text = rarityText,
                    TextColor3 = rarityColor,
                    TextSize = getProportionalTextSize(screenSize, 9),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 56,
                    LayoutOrder = 3
                }, {
                    TextStroke = e("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = 1,
                        Transparency = 0
                    })
                })
            end)(),
            
            -- Boost percentage
            BoostText = (function()
                local PetConfig = require(ReplicatedStorage.Shared.config.PetConfig)
                local comprehensiveInfo = PetConfig:GetComprehensivePetInfo(selectedPet.pet.id, selectedPet.pet.aura, selectedPet.pet.size)
                local boostText = (comprehensiveInfo and comprehensiveInfo.dynamicBoost) and ("+" .. string.format("%.1f", comprehensiveInfo.dynamicBoost) .. "%") or "+0.0%"
                
                return e("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 14),
                    Text = boostText,
                    TextColor3 = Color3.fromRGB(100, 200, 100),
                    TextSize = getProportionalTextSize(screenSize, 9),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 56,
                    LayoutOrder = 4
                }, {
                    TextStroke = e("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = 1,
                        Transparency = 0
                    })
                })
            end)(),
            
            -- Aura
            AuraText = (function()
                local auraData = selectedPet.auraData
                local auraName = auraData and auraData.name or "None"
                local auraColor = auraData and auraData.color or Color3.fromRGB(150, 150, 150)
                
                return e("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 12),
                    Text = auraName,
                    TextColor3 = auraColor,
                    TextSize = getProportionalTextSize(screenSize, 8),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 56,
                    LayoutOrder = 5
                })
            end)(),
            
            -- Remove button using proper X asset
            RemoveButton = e("ImageButton", {
                Size = UDim2.new(0, removeButtonSize, 0, removeButtonSize),
                Position = UDim2.new(1, -25, 0, 5),
                AnchorPoint = Vector2.new(0, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Image = assets["vector-icon-pack-2/UI/X Button/X Button Outline 256.png"] or "rbxassetid://137122155343638",
                ImageColor3 = Color3.fromRGB(255, 100, 100),
                ZIndex = 57,
                [React.Event.Activated] = function()
                    onRemove(slotIndex)
                end
            })
        }) or e("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            Text = "Empty Slot " .. slotIndex,
            TextColor3 = Color3.fromRGB(120, 120, 120),
            TextSize = getProportionalTextSize(screenSize, 14),
            TextWrapped = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 55
        })
    })
end

return LabPetSlot