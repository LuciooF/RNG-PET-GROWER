-- Pet Inventory Panel Component  
-- Modern card-grid layout showing collected pets
-- Adapted from InventoryPanel.lua for pet collection system

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local React = require(ReplicatedStorage.Packages.react)
local e = React.createElement

local PetConfig = require(ReplicatedStorage.Shared.config.PetConfig)
local assets = require(ReplicatedStorage.assets)
local Store = require(ReplicatedStorage.store)
local PlayerActions = require(ReplicatedStorage.store.actions.PlayerActions)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local AnimationHelpers = require(ReplicatedStorage.utils.AnimationHelpers)
local PetConstants = require(ReplicatedStorage.constants.PetConstants)
local PetAssignmentService = require(script.Parent.Parent.services.PetAssignmentService)

-- Using shared responsive design utilities

-- Using shared animation helpers

-- Sound effects (simplified for now)
local function playSound(soundType)
    -- Placeholder for sound effects
end

-- Function to get pet asset model (same approach as PetModelFactory)
local function getPetAssetModel(petData)
    -- Find the assets Folder in ReplicatedStorage (not the ModuleScript)
    local assets = nil
    for _, child in pairs(ReplicatedStorage:GetChildren()) do
        if child.Name == "assets" and child.ClassName == "Folder" then
            assets = child
            break
        end
    end
    
    if assets and petData.assetPath then
        local pathParts = string.split(petData.assetPath, "/")
        local currentFolder = assets
        
        -- Navigate through the path
        for _, pathPart in ipairs(pathParts) do
            currentFolder = currentFolder:FindFirstChild(pathPart)
            if not currentFolder then
                break
            end
        end
        
        if currentFolder and currentFolder:IsA("Model") then
            return currentFolder:Clone()
        end
    end
    
    return nil
end

local function PetInventoryPanel(props)
    local playerData = props.playerData
    local visible = props.visible or false
    local onClose = props.onClose or function() end
    local remotes = props.remotes or {}
    
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
    
    -- Calculate grid for pet cards - responsive layout
    local minCardWidth = ScreenUtils.getProportionalSize(screenSize, 250)
    local cardsPerRow = math.max(2, math.min(4, math.floor((panelWidth - 120) / (minCardWidth + 20))))
    local cardWidth = (panelWidth - 120) / cardsPerRow - 20
    local cardHeight = ScreenUtils.getProportionalSize(screenSize, 280)
    
    -- Get assigned pets (companionPets) and owned pets
    local assignedPets = playerData.companionPets or {}
    local assignedPetIds = {}
    
    -- Create lookup table for assigned pets
    for _, assignedPet in ipairs(assignedPets) do
        if assignedPet.uniqueId then
            assignedPetIds[assignedPet.uniqueId] = true
        end
    end
    
    -- Get pets from player data and group by type AND aura
    local petGroups = {}
    
    -- Debug: Check if we have any pets and available assets
    print("PetInventory Debug: ownedPets count:", playerData.ownedPets and #playerData.ownedPets or 0)
    
    -- Debug: Show some available assets for pets
    local assetCount = 0
    for assetPath, asset in pairs(assets) do
        if string.find(assetPath, "Pet") then
            print("PetInventory Debug: Found pet asset:", assetPath)
            assetCount = assetCount + 1
            if assetCount >= 5 then break end -- Only show first 5
        end
    end
    
    if playerData.ownedPets then
        for i, pet in ipairs(playerData.ownedPets) do
            local isAssigned = pet.uniqueId and assignedPetIds[pet.uniqueId] or false
            -- Create separate keys for assigned and unassigned pets
            local baseKey = (pet.name or "Unknown") .. "_" .. (pet.aura or "none") .. "_" .. (pet.size or 1)
            local petKey = baseKey .. "_" .. (isAssigned and "assigned" or "unassigned")
            
            if not petGroups[petKey] then
                petGroups[petKey] = {
                    petType = pet,
                    quantity = 0,
                    latestCollectionTime = 0,
                    petConfig = PetConfig:GetPetData(pet.id or 1),
                    aura = pet.aura or "none",
                    auraData = PetConfig.AURAS[pet.aura or "none"] or PetConfig.AURAS.none,
                    size = pet.size or 1,
                    sizeData = PetConfig:GetSizeData(pet.size or 1),
                    isAssigned = isAssigned,
                    samplePet = pet -- Store one pet for assign/unassign operations
                }
            end
            
            petGroups[petKey].quantity = petGroups[petKey].quantity + 1
            petGroups[petKey].latestCollectionTime = math.max(petGroups[petKey].latestCollectionTime, pet.collectedAt or 0)
            
            -- Always update sample pet to ensure we have a valid one
            petGroups[petKey].samplePet = pet
        end
    end
    
    -- Convert to array for sorting
    local petItems = {}
    for petKey, groupData in pairs(petGroups) do
        table.insert(petItems, {
            name = groupData.petType.name,
            id = groupData.petType.id or 1, -- Add the pet ID here
            pet = groupData.petType,
            quantity = groupData.quantity,
            latestCollectionTime = groupData.latestCollectionTime,
            petConfig = groupData.petConfig,
            aura = groupData.aura,
            auraData = groupData.auraData,
            size = groupData.size,
            sizeData = groupData.sizeData,
            rarity = groupData.petType.rarity or 1, -- Add rarity here too
            isAssigned = groupData.isAssigned,
            samplePet = groupData.samplePet
        })
    end
    
    -- Sort by: 1) assigned pets first, 2) boost/rarity (higher first), 3) collection time
    table.sort(petItems, function(a, b)
        -- Assigned pets go first
        if a.isAssigned ~= b.isAssigned then
            return a.isAssigned
        end
        
        -- Get comprehensive info for both pets to compare boosts
        local aInfo = PetConfig:GetComprehensivePetInfo(a.pet.id, a.pet.aura, a.pet.size)
        local bInfo = PetConfig:GetComprehensivePetInfo(b.pet.id, b.pet.aura, b.pet.size)
        
        if aInfo and bInfo then
            -- Sort by dynamic boost (higher boost = rarer = first)
            if aInfo.dynamicBoost ~= bInfo.dynamicBoost then
                return aInfo.dynamicBoost > bInfo.dynamicBoost
            end
            
            -- If boost is same, sort by combined probability (rarer first)
            if aInfo.combinedProbability ~= bInfo.combinedProbability then
                return aInfo.combinedProbability < bInfo.combinedProbability -- Lower probability = rarer = first
            end
        end
        
        -- Fallback: sort by pet rarity then aura multiplier
        if a.pet.rarity ~= b.pet.rarity then
            return a.pet.rarity > b.pet.rarity
        end
        
        local aAuraMultiplier = a.auraData and a.auraData.multiplier or 1
        local bAuraMultiplier = b.auraData and b.auraData.multiplier or 1
        if aAuraMultiplier ~= bAuraMultiplier then
            return aAuraMultiplier > bAuraMultiplier
        end
        
        -- Finally by collection time (newest first)
        return a.latestCollectionTime > b.latestCollectionTime
    end)
    
    -- Calculate grid dimensions
    local totalRows = math.ceil(#petItems / cardsPerRow)
    local totalHeight = ((totalRows * cardHeight) + ((totalRows - 1) * 20) + 40) * 1.3
    
    -- Pet emojis based on name
    -- Using shared pet constants
    
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
        CloseButton = e("TextButton", {
            Name = "CloseButton",
            Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 32), 0, ScreenUtils.getProportionalSize(screenSize, 32)),
            Position = UDim2.new(1, -16, 0, -16),
            Text = "✕",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = ScreenUtils.getProportionalTextSize(screenSize, 20),
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
                        -- Get comprehensive pet information using new rarity system
                        local comprehensiveInfo = PetConfig:GetComprehensivePetInfo(pet.id, pet.aura, pet.size)
                        
                        local rarity = pet.rarity or 1
                        local colors = PetConstants.getRarityColor(rarity, true)
                        local rarityName = PetConstants.getRarityName(rarity)
                        -- Get the actual pet model instead of emoji
                        local petModel = getPetAssetModel(petItem.petConfig)
                        
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
                        
                        -- Use new comprehensive rarity and boost calculation
                        local description = petConfig and petConfig.description or "A mysterious pet with hidden powers."
                        local boostText = ""
                        local combinedRarityText = "1/1"
                        local rarityTierName = "Common"
                        local rarityTierColor = Color3.fromRGB(200, 200, 200)
                        
                        if comprehensiveInfo then
                            -- Dynamic boost based on combined rarity
                            local boostPercentage = math.floor((comprehensiveInfo.moneyMultiplier - 1) * 100)
                            boostText = "+" .. boostPercentage .. "% Money"
                            
                            -- Combined rarity display (e.g., "1/1000")
                            combinedRarityText = comprehensiveInfo.rarityText
                            rarityTierName = comprehensiveInfo.rarityTier
                            rarityTierColor = comprehensiveInfo.rarityColor
                        end
                        
                        -- Animation refs - removed to fix React hooks rule violation
                        local petIconRef = nil
                        local cardElement = nil
                        
                        
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
                            
                            -- Card Gradient Background
                            CardGradient = e("UIGradient", {
                                Color = ColorSequence.new{
                                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                                    ColorSequenceKeypoint.new(1, Color3.fromRGB(252, 248, 255))
                                },
                                Rotation = 45
                            }),
                            
                            Stroke = e("UIStroke", {
                                Color = colors.primary, -- Rarity-colored outline
                                Thickness = 3,
                                Transparency = 0.3
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
                                Size = UDim2.new(0.6, 0, 0.35, 0),
                                Position = UDim2.new(0.5, 0, 0.15, 0),
                                AnchorPoint = Vector2.new(0.5, 0.5),
                                BackgroundTransparency = 1,
                                BorderSizePixel = 0,
                                ZIndex = 33,
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
                                        
                                        -- Position camera to show the pet model nicely
                                        local cf, size = clonedModel:GetBoundingBox()
                                        local maxExtent = math.max(size.X, size.Y, size.Z)
                                        local cameraDistance = maxExtent * 2.5
                                        camera.CFrame = CFrame.lookAt(
                                            cf.Position + Vector3.new(cameraDistance, cameraDistance * 0.5, cameraDistance),
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
                                TextSize = normalTextSize,
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
                                    BackgroundColor3 = petItem.sizeData.color,
                                    BorderSizePixel = 0,
                                    ZIndex = 34
                                }, {
                                    Corner = e("UICorner", {
                                        CornerRadius = UDim.new(0, 8) -- Match the badge corner radius
                                    }),
                                    SizeText = e("TextLabel", {
                                        Size = UDim2.new(1, 0, 1, 0),
                                        Text = petItem.sizeData.displayName:upper(), -- Full size name (TINY, SMALL, etc.)
                                        TextColor3 = Color3.fromRGB(255, 255, 255),
                                        TextSize = smallTextSize, -- Match the badge text size
                                        BackgroundTransparency = 1,
                                        Font = Enum.Font.SourceSansBold, -- Match the badge font
                                        TextXAlignment = Enum.TextXAlignment.Center,
                                        TextYAlignment = Enum.TextYAlignment.Center,
                                        TextWrapped = true, -- Match the badge text wrapping
                                        ZIndex = 35
                                    })
                                })
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
                                Text = combinedRarityText .. " • " .. rarityTierName,
                                TextColor3 = rarityTierColor,
                                TextSize = ScreenUtils.getProportionalTextSize(screenSize, 11),
                                TextWrapped = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.GothamBold,
                                ZIndex = 33
                            }, {
                                TextStroke = e("UIStroke", {
                                    Color = Color3.fromRGB(0, 0, 0),
                                    Thickness = 1,
                                    Transparency = 0.6
                                })
                            }),
                            
                            -- Pet Description
                            PetDescription = e("TextLabel", {
                                Name = "PetDescription",
                                Size = UDim2.new(0.9, 0, 0.10, 0),
                                Position = UDim2.new(0.05, 0, 0.42, 0),
                                Text = description,
                                TextColor3 = Color3.fromRGB(70, 80, 120),
                                TextSize = ScreenUtils.getProportionalTextSize(screenSize, 12),
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
                                Size = UDim2.new(0.4, 0, 0.06, 0),
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
                                })
                            }),
                            
                            -- Boost Display with Icon
                            BoostContainer = boostText ~= "" and e("Frame", {
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
                                    Size = UDim2.new(0, ScreenUtils.getProportionalTextSize(screenSize, 14), 0, ScreenUtils.getProportionalTextSize(screenSize, 14)),
                                    Image = assets["vector-icon-pack-2/Player/Boost/Boost Yellow Outline 256.png"] or "",
                                    BackgroundTransparency = 1,
                                    ScaleType = Enum.ScaleType.Fit,
                                    ImageColor3 = Color3.fromRGB(255, 200, 100),
                                    ZIndex = 34,
                                    LayoutOrder = 1
                                }),
                                
                                BoostLabel = e("TextLabel", {
                                    Name = "BoostText",
                                    Size = UDim2.new(0, 0, 1, 0),
                                    AutomaticSize = Enum.AutomaticSize.X,
                                    Text = boostText,
                                    TextColor3 = Color3.fromRGB(255, 200, 100),
                                    TextSize = ScreenUtils.getProportionalTextSize(screenSize, 14),
                                    TextWrapped = true,
                                    BackgroundTransparency = 1,
                                    Font = Enum.Font.SourceSansBold,
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
                                    Image = assets["vector-icon-pack-2/Currency/Cash/Cash Outline 256.png"] or "",
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
                                    Text = (function()
                                        if comprehensiveInfo then
                                            -- Use new enhanced value calculation
                                            return comprehensiveInfo.enhancedValue .. " each"
                                        else
                                            -- Fallback to old calculation
                                            local baseValue = pet.value or 1
                                            local auraMultiplier = petItem.auraData and petItem.auraData.valueMultiplier or 1
                                            local totalValue = math.floor(baseValue * auraMultiplier)
                                            return totalValue .. " each"
                                        end
                                    end)(),
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
                                })
                            }),
                            
                            -- Assignment Status Badge (if assigned)
                            AssignmentBadge = petItem.isAssigned and e("Frame", {
                                Name = "AssignmentBadge",
                                Size = UDim2.new(0.15, 0, 0.08, 0),
                                Position = UDim2.new(0.15, 0, 0.02, 0),
                                AnchorPoint = Vector2.new(0.5, 0),
                                BackgroundColor3 = Color3.fromRGB(80, 200, 80), -- Green for assigned
                                BorderSizePixel = 0,
                                ZIndex = 34
                            }, {
                                Corner = e("UICorner", {
                                    CornerRadius = UDim.new(0.5, 0)
                                }),
                                AssignedText = e("TextLabel", {
                                    Size = UDim2.new(1, 0, 1, 0),
                                    Text = "✓",
                                    TextColor3 = Color3.fromRGB(255, 255, 255),
                                    TextSize = ScreenUtils.getProportionalTextSize(screenSize, 11),
                                    BackgroundTransparency = 1,
                                    Font = Enum.Font.SourceSansBold,
                                    ZIndex = 35
                                })
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
                            }),
                            
                            -- Collection Time (below assign button, centered)
                            TimeLabel = collectedTime ~= "" and e("TextLabel", {
                                Name = "CollectedTime",
                                Size = UDim2.new(0.8, 0, 0.04, 0),
                                Position = UDim2.new(0.5, 0, 0.93, 0),
                                AnchorPoint = Vector2.new(0.5, 0),
                                Text = "Latest: " .. collectedTime,
                                TextColor3 = Color3.fromRGB(180, 180, 180),
                                TextSize = ScreenUtils.getProportionalTextSize(screenSize, 10),
                                TextWrapped = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.SourceSans,
                                TextXAlignment = Enum.TextXAlignment.Center,
                                ZIndex = 33
                            }) or nil
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