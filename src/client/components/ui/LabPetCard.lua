-- Lab Pet Card Component
-- Lab-specific pet card for pet selection interface
-- Matches Lab UI theme and handles Lab-specific interactions

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.react)
local e = React.createElement

local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local AssetLoader = require(ReplicatedStorage.utils.AssetLoader)
local PetConfig = require(ReplicatedStorage.Shared.config.PetConfig)
local assets = require(ReplicatedStorage.assets)

local function LabPetCard(props)
    local petItem = props.petItem
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    -- Use responsive sizing if cardWidth/cardHeight not provided
    local cardWidth = props.cardWidth or ScreenUtils.getProportionalSize(screenSize, 120)
    local cardHeight = props.cardHeight or ScreenUtils.getProportionalSize(screenSize, 100)
    local layoutOrder = props.layoutOrder or 1
    local onSelect = props.onSelect or function() end
    local isSelected = props.isSelected or false
    
    local getProportionalTextSize = ScreenUtils.getProportionalTextSize
    
    -- Responsive sizing variables
    local imageSize = ScreenUtils.getProportionalSize(screenSize, 80)
    local cardPadding = ScreenUtils.getProportionalSize(screenSize, 8)
    
    -- Get pet display information
    local pet = petItem.pet
    local petConfig = petItem.petConfig
    local sizeData = petItem.sizeData
    
    -- Get comprehensive pet info for rarity display
    local comprehensiveInfo = PetConfig:GetComprehensivePetInfo(pet.id, pet.aura, pet.size)
    local rarityText = comprehensiveInfo and comprehensiveInfo.rarityText or ("1/" .. (pet.rarity or 1))
    local rarityColor = comprehensiveInfo and comprehensiveInfo.rarityColor or Color3.fromRGB(150, 150, 150)
    
    return e("TextButton", {
        Name = "LabPetCard_" .. layoutOrder,
        Size = UDim2.new(0, cardWidth, 0, cardHeight),
        BackgroundColor3 = isSelected and Color3.fromRGB(255, 255, 150) or Color3.fromRGB(240, 245, 255),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Text = "",
        ZIndex = 53,
        LayoutOrder = layoutOrder,
        [React.Event.Activated] = function()
            onSelect(petItem)
        end
    }, {
        Corner = e("UICorner", {
            CornerRadius = UDim.new(0, 12)
        }),
        Stroke = e("UIStroke", {
            Color = Color3.fromRGB(150, 150, 200),
            Thickness = 1,
            Transparency = 0.3
        }),
        
        Layout = e("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            Padding = UDim.new(0, 5),
            SortOrder = Enum.SortOrder.LayoutOrder
        }),
        
        Padding = e("UIPadding", {
            PaddingTop = UDim.new(0, cardPadding),
            PaddingBottom = UDim.new(0, cardPadding),
            PaddingLeft = UDim.new(0, cardPadding),
            PaddingRight = UDim.new(0, cardPadding)
        }),
        
        -- Pet Name
        PetName = e("TextLabel", {
            Size = UDim2.new(1, 0, 0, 20),
            Text = pet.name or "Unknown Pet",
            TextColor3 = Color3.fromRGB(60, 80, 140),
            TextSize = getProportionalTextSize(screenSize, 13),
            TextWrapped = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 54,
            LayoutOrder = 1
        }),
        
        -- Pet Image
        PetImage = (function()
            local petModel = AssetLoader.loadPetModel(petConfig.assetPath)
            
            if petModel then
                return e("ViewportFrame", {
                    Size = UDim2.new(0, imageSize, 0, imageSize),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ZIndex = 54,
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
                    ZIndex = 54,
                    LayoutOrder = 2
                })
            end
        end)(),
        
        -- Combined Rarity
        RarityText = e("TextLabel", {
            Size = UDim2.new(1, 0, 0, 16),
            Text = rarityText,
            TextColor3 = rarityColor,
            TextSize = getProportionalTextSize(screenSize, 11),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 54,
            LayoutOrder = 3
        }, {
            TextStroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 1,
                Transparency = 0
            })
        }),
        
        -- Boost percentage
        BoostText = e("TextLabel", {
            Size = UDim2.new(1, 0, 0, 16),
            Text = (comprehensiveInfo and comprehensiveInfo.dynamicBoost) and ("+" .. string.format("%.1f", comprehensiveInfo.dynamicBoost) .. "% Money") or "+0.0% Money",
            TextColor3 = Color3.fromRGB(100, 200, 100),
            TextSize = getProportionalTextSize(screenSize, 10),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 54,
            LayoutOrder = 4
        }, {
            TextStroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 1,
                Transparency = 0
            })
        }),
        
        -- Size
        SizeText = e("TextLabel", {
            Size = UDim2.new(1, 0, 0, 16),
            Text = "Size: " .. (sizeData and sizeData.displayName or "Tiny"),
            TextColor3 = sizeData and sizeData.color or Color3.fromRGB(150, 150, 150),
            TextSize = getProportionalTextSize(screenSize, 10),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 54,
            LayoutOrder = 5
        })
    })
end

return LabPetCard