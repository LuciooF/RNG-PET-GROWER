-- Rarest Pets Display Component
-- Shows the 6 rarest pets the player has collected in the bottom right
-- With cool animations when new pets join the list

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local React = require(ReplicatedStorage.Packages.react)
local e = React.createElement

local PetConfig = require(ReplicatedStorage.Shared.config.PetConfig)

-- Import shared utilities
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local ColorPalette = require(ReplicatedStorage.utils.ColorPalette)

-- Use shared utility functions
local getProportionalScale = ScreenUtils.getProportionalScale
local getProportionalSize = ScreenUtils.getProportionalSize
local getProportionalTextSize = ScreenUtils.getProportionalTextSize
local getProportionalPadding = ScreenUtils.getProportionalPadding

local function RarestPetsDisplay(props)
    local playerData = props.playerData or {}
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    local scale = getProportionalScale(screenSize)
    
    -- Responsive sizing for individual cards
    local cardWidth = math.max(220, getProportionalSize(screenSize, 280))
    local cardHeight = math.max(30, getProportionalSize(screenSize, 35))
    local maxRows = 5 -- Show only 5 rarest pets
    local cardSpacing = getProportionalSize(screenSize, 5)
    local headerHeight = math.max(25, getProportionalSize(screenSize, 30))
    local headerSpacing = getProportionalSize(screenSize, 8)
    local padding = getProportionalPadding(screenSize, 15)
    
    -- Text sizes
    local titleTextSize = getProportionalTextSize(screenSize, 16)
    local petNameTextSize = getProportionalTextSize(screenSize, 14)
    local rarityTextSize = getProportionalTextSize(screenSize, 12)
    
    -- Animation states for new pets
    local animatingPets, setAnimatingPets = React.useState({})
    
    -- Process player's pets to find the rarest ones
    local rarestPets = React.useMemo(function()
        local ownedPets = playerData.ownedPets or {}
        if #ownedPets == 0 then
            return {}
        end
        
        -- Group pets by their unique combination (name + aura + size)
        local petGroups = {}
        for _, pet in ipairs(ownedPets) do
            local combinedProbability, rarityText = PetConfig:CalculateCombinedRarity(pet.id or 1, pet.aura)
            if combinedProbability and combinedProbability > 0 then
                local rarityTierName, rarityColor = PetConfig:GetRarityTierName(combinedProbability)
                
                -- Create unique key for this pet type (name + aura + size)
                local petKey = (pet.name or "Unknown") .. "_" .. (pet.aura or "none") .. "_" .. (pet.size or 1)
                
                if not petGroups[petKey] then
                    petGroups[petKey] = {
                        pet = pet, -- Representative pet for display
                        combinedProbability = combinedProbability,
                        rarityText = rarityText,
                        rarityTierName = rarityTierName,
                        rarityColor = rarityColor,
                        sortKey = combinedProbability, -- Lower probability = rarer
                        quantity = 0,
                        pets = {} -- All pets of this type
                    }
                end
                
                petGroups[petKey].quantity = petGroups[petKey].quantity + 1
                table.insert(petGroups[petKey].pets, pet)
            end
        end
        
        -- Convert groups to array and sort by rarity
        local petsWithRarity = {}
        for _, group in pairs(petGroups) do
            table.insert(petsWithRarity, group)
        end
        
        -- Sort by rarity (lowest probability first = rarest first)
        table.sort(petsWithRarity, function(a, b)
            return a.sortKey < b.sortKey
        end)
        
        -- Take only the top 6 rarest
        local topRarest = {}
        for i = 1, math.min(maxRows, #petsWithRarity) do
            table.insert(topRarest, petsWithRarity[i])
        end
        
        return topRarest
    end, {playerData.ownedPets})
    
    -- Track previous rarest pets to detect new entries
    local previousRarest = React.useRef({})
    
    -- Detect new pets and trigger animations
    React.useEffect(function()
        local newAnimatingPets = {}
        
        -- Check if any current rarest pet group wasn't in the previous list or has increased quantity
        for i, currentGroup in ipairs(rarestPets) do
            local wasInPrevious = false
            local prevQuantity = 0
            
            for _, prevGroup in ipairs(previousRarest.current) do
                -- Compare by the pet type key (name + aura + size)
                local currentKey = (currentGroup.pet.name or "Unknown") .. "_" .. (currentGroup.pet.aura or "none") .. "_" .. (currentGroup.pet.size or 1)
                local prevKey = (prevGroup.pet.name or "Unknown") .. "_" .. (prevGroup.pet.aura or "none") .. "_" .. (prevGroup.pet.size or 1)
                
                if currentKey == prevKey then
                    wasInPrevious = true
                    prevQuantity = prevGroup.quantity
                    break
                end
            end
            
            -- Animate if it's a new pet type or quantity increased
            if not wasInPrevious or currentGroup.quantity > prevQuantity then
                newAnimatingPets[i] = true
            end
        end
        
        if next(newAnimatingPets) then
            setAnimatingPets(newAnimatingPets)
            
            -- Clear animations after delay
            task.delay(2, function()
                setAnimatingPets({})
            end)
        end
        
        -- Update previous list
        previousRarest.current = rarestPets
    end, {rarestPets})
    
    -- Don't show if no pets
    if #rarestPets == 0 then
        return nil
    end
    
    -- Calculate total height needed based on actual number of pets + header
    local totalCards = math.min(maxRows, #rarestPets)
    local cardsHeight = totalCards * cardHeight + (totalCards - 1) * cardSpacing
    local totalHeight = headerHeight + headerSpacing + cardsHeight
    
    return e("Frame", {
        Name = "RarestPetsDisplay",
        Size = UDim2.new(0, cardWidth, 0, totalHeight),
        Position = UDim2.new(1, -cardWidth - padding, 1, -totalHeight - padding),
        BackgroundTransparency = 1, -- No background
        BorderSizePixel = 0,
        ZIndex = 15
    }, {
        -- Header
        Header = e("TextLabel", {
            Name = "Header",
            Size = UDim2.new(1, 0, 0, headerHeight),
            Position = UDim2.new(0, 0, 0, 0),
            Text = "Your 5 Rarest pets",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = titleTextSize,
            TextWrapped = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 16
        }, {
            TextStroke = e("UIStroke", {
                Color = ColorPalette.BLACK,
                Thickness = 2,
                Transparency = 0.3
            })
        }),
        -- Generate individual pet cards
        PetCards = React.createElement(React.Fragment, {}, (function()
            local cards = {}
            
            for i, petRarity in ipairs(rarestPets) do
                local pet = petRarity.pet
                local isAnimating = animatingPets[i] == true
                
                -- Format display text: "Pet Name (Rarity Tier 1/XXXX)"
                local displayText = string.format("%s (%s %s)", 
                    pet.name or "Unknown Pet", 
                    petRarity.rarityTierName,
                    petRarity.rarityText
                )
                
                -- Calculate position for this card (account for header)
                local yOffset = headerHeight + headerSpacing + (i - 1) * (cardHeight + cardSpacing)
                
                cards["pet_card_" .. i] = e("Frame", {
                    Name = "PetCard" .. i,
                    Size = UDim2.new(0, cardWidth, 0, cardHeight),
                    Position = UDim2.new(0, 0, 0, yOffset),
                    BackgroundColor3 = petRarity.rarityColor, -- Use rarity color as background
                    BackgroundTransparency = 0.2, -- Slightly more opaque to show color better
                    BorderSizePixel = 0,
                    ZIndex = 17
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 8)
                    }),
                    
                    -- White border for contrast
                    Border = e("UIStroke", {
                        Color = Color3.fromRGB(255, 255, 255),
                        Thickness = 2,
                        Transparency = 0.3
                    }),
                    
                    -- Glow effect for animating pets
                    Glow = isAnimating and e("UIStroke", {
                        Color = Color3.fromRGB(255, 255, 255),
                        Thickness = 4,
                        Transparency = 0.1
                    }) or nil,
                    
                    -- Pet name and rarity
                    PetInfo = e("TextLabel", {
                        Name = "PetInfo",
                        Size = UDim2.new(1, -25, 1, 0), -- Less space for quantity badge
                        Position = UDim2.new(0, 4, 0, 0), -- Very small left padding
                        Text = displayText,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = petNameTextSize,
                        TextWrapped = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamSemibold,
                        TextXAlignment = Enum.TextXAlignment.Center, -- Center the text
                        TextYAlignment = Enum.TextYAlignment.Center,
                        ZIndex = 18
                    }, {
                        TextStroke = e("UIStroke", {
                            Color = ColorPalette.BLACK,
                            Thickness = 2, -- Stronger stroke for better contrast
                            Transparency = 0.2
                        })
                    }),
                    
                    -- Quantity badge (top right) - only show if quantity > 1
                    QuantityBadge = petRarity.quantity > 1 and e("Frame", {
                        Name = "QuantityBadge",
                        Size = UDim2.new(0, 20, 0, 16),
                        Position = UDim2.new(1, -21, 0, 2),
                        BackgroundColor3 = Color3.fromRGB(0, 0, 0), -- Black background for contrast
                        BackgroundTransparency = 0.3,
                        BorderSizePixel = 0,
                        ZIndex = 19
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 8)
                        }),
                        
                        Stroke = e("UIStroke", {
                            Color = Color3.fromRGB(255, 255, 255),
                            Thickness = 1,
                            Transparency = 0.2
                        }),
                        
                        QuantityText = e("TextLabel", {
                            Size = UDim2.new(1, 0, 1, 0),
                            Text = "x" .. petRarity.quantity,
                            TextColor3 = Color3.fromRGB(255, 255, 255),
                            TextSize = math.max(8, getProportionalTextSize(screenSize, 10)),
                            BackgroundTransparency = 1,
                            Font = Enum.Font.GothamBold,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            TextYAlignment = Enum.TextYAlignment.Center,
                            ZIndex = 20
                        }, {
                            TextStroke = e("UIStroke", {
                                Color = ColorPalette.BLACK,
                                Thickness = 1,
                                Transparency = 0.3
                            })
                        })
                    }) or nil,
                    
                    -- Pulse animation for new pets
                    PulseEffect = isAnimating and e("Frame", {
                        Name = "PulseEffect",
                        Size = UDim2.new(1, 6, 1, 6),
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundColor3 = petRarity.rarityColor,
                        BackgroundTransparency = 0.7,
                        BorderSizePixel = 0,
                        ZIndex = 16
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 10)
                        }),
                        
                        PulseStroke = e("UIStroke", {
                            Color = petRarity.rarityColor,
                            Thickness = 3,
                            Transparency = 0.3
                        })
                    }) or nil
                })
            end
            
            return cards
        end)())
    })
end

return RarestPetsDisplay