-- Pet Index UI - Shows all pets and collected variations
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.react)
local UserInputService = game:GetService("UserInputService")

local DataSyncService = require(script.Parent.Parent.services.DataSyncService)

-- Load the config files (copied by server on startup)
local PetSpawnConfig, VariationConfig

-- Wait for config files to be available
local configFolder = ReplicatedStorage:WaitForChild("config", 10)
if configFolder then
    local success, errorMsg = pcall(function()
        PetSpawnConfig = require(configFolder:WaitForChild("PetSpawnConfig", 5))
        VariationConfig = require(configFolder:WaitForChild("VariationConfig", 5))
    end)
    
    if not success then
        warn("PetIndexUI: Failed to load config files:", errorMsg)
        PetSpawnConfig = nil
        VariationConfig = nil
    else
        print("PetIndexUI: Successfully loaded config files")
    end
else
    warn("PetIndexUI: Config folder not found in ReplicatedStorage")
end

-- Provide fallbacks if configs couldn't be loaded
if not PetSpawnConfig then
    PetSpawnConfig = {
        PetsByLevel = {},
        GetSpawnChancesForDoor = function() return {} end
    }
end

if not VariationConfig then
    VariationConfig = {
        Variations = {},
        GetRandomVariation = function() return {} end
    }
end

local function PetIndexUI(props)
    local visible = props and props.visible or false
    local setVisible = props and props.setVisible or function() end
    local hoveredPet, setHoveredPet = React.useState(nil)
    local playerData, setPlayerData = React.useState(nil)
    local selectedLevel, setSelectedLevel = React.useState(1)
    local selectedDoor, setSelectedDoor = React.useState(1)
    
    -- Subscribe to player data changes
    React.useEffect(function()
        local unsubscribe = DataSyncService:Subscribe(function(newState)
            if newState and newState.player then
                setPlayerData(newState.player)
            end
        end)
        
        return unsubscribe
    end, {})
    
    -- Keyboard shortcut (I key)
    React.useEffect(function()
        local connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            if input.KeyCode == Enum.KeyCode.I then
                setVisible(function(prev) return not prev end)
            end
        end)
        
        return function()
            connection:Disconnect()
        end
    end, {})
    
    if not visible then
        return nil
    end
    
    -- Safety check for config files
    if not PetSpawnConfig or not VariationConfig or not PetSpawnConfig.PetsByLevel then
        return React.createElement("Frame", {
            Size = UDim2.new(0.8, 0, 0.8, 0),
            Position = UDim2.new(0.1, 0, 0.1, 0),
            BackgroundColor3 = Color3.fromRGB(50, 50, 50),
            BorderSizePixel = 0,
            Visible = visible
        }, {
            Title = React.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0, 40),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                BorderSizePixel = 0,
                Text = "Pet Index",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                Font = Enum.Font.GothamBold
            }),
            
            CloseButton = React.createElement("TextButton", {
                Size = UDim2.new(0, 30, 0, 30),
                Position = UDim2.new(1, -35, 0, 5),
                BackgroundColor3 = Color3.fromRGB(255, 100, 100),
                BorderSizePixel = 0,
                Text = "X",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                Font = Enum.Font.GothamBold,
                [React.Event.Activated] = function()
                    setVisible(false)
                end
            }),
            
            ErrorText = React.createElement("TextLabel", {
                Size = UDim2.new(1, -20, 1, -60),
                Position = UDim2.new(0, 10, 0, 50),
                BackgroundTransparency = 1,
                Text = "Loading Pet Index...\n\nIf this persists, config files may not be available.",
                TextColor3 = Color3.fromRGB(255, 200, 100),
                TextScaled = true,
                Font = Enum.Font.Gotham
            })
        })
    end
    
    -- Get all possible pets from selected level
    local allPets = {}
    local spawnChances = {}
    
    pcall(function()
        allPets = PetSpawnConfig.PetsByLevel[selectedLevel] or {}
        if #allPets > 0 then
            spawnChances = PetSpawnConfig:GetSpawnChancesForDoor(selectedLevel, selectedDoor)
        end
    end)
    
    local collectedPetsDict = {}
    if playerData and playerData.CollectedPets then
        collectedPetsDict = playerData.CollectedPets
    end
    
    -- Build a map of collected pets and their variations from the persistent dictionary
    local collectedData = {}
    for collectionKey, collectionInfo in pairs(collectedPetsDict) do
        local petName = collectionInfo.petName
        local variationName = collectionInfo.variationName
        
        if not collectedData[petName] then
            collectedData[petName] = {
                variations = {},
                rarestVariation = nil,
                rarestValue = 0,
                totalCollected = 0
            }
        end
        
        -- Mark this variation as collected
        collectedData[petName].variations[variationName] = {
            collected = true,
            count = collectionInfo.count,
            firstCollected = collectionInfo.firstCollected,
            lastCollected = collectionInfo.lastCollected
        }
        
        collectedData[petName].totalCollected = collectedData[petName].totalCollected + collectionInfo.count
        
        -- Find the rarest variation (highest value multiplier) from collected ones
        if VariationConfig and VariationConfig.Variations then
            for _, variation in ipairs(VariationConfig.Variations) do
                if variation.name == variationName then
                    if variation.valueMultiplier > collectedData[petName].rarestValue then
                        collectedData[petName].rarestValue = variation.valueMultiplier
                        collectedData[petName].rarestVariation = {
                            VariationName = variationName,
                            VariationColor = variation.color and {255, 255, 255} or {255, 255, 255} -- Default to white if no color
                        }
                    end
                    break
                end
            end
        end
    end
    
    -- Create pet cards
    local petCards = {}
    for index, petConfig in ipairs(allPets) do
        local petName = petConfig.name
        local isCollected = collectedData[petName] ~= nil
        local rarestVariation = isCollected and collectedData[petName].rarestVariation or nil
        local petChance = spawnChances[index] and spawnChances[index].normalizedChance or 0
        
        petCards[index] = React.createElement("Frame", {
            Size = UDim2.new(0, 120, 0, 180),
            BackgroundColor3 = isCollected and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(40, 40, 40),
            BorderSizePixel = 2,
            BorderColor3 = isCollected and Color3.fromRGB(120, 120, 120) or Color3.fromRGB(60, 60, 60),
            LayoutOrder = index,
            
            -- Mouse enter/leave for hover
            [React.Event.MouseEnter] = function()
                setHoveredPet({name = petName, index = index})
            end,
            
            [React.Event.MouseLeave] = function()
                setHoveredPet(nil)
            end
        }, {
            -- Pet name
            PetName = React.createElement("TextLabel", {
                Size = UDim2.new(1, -10, 0, 20),
                Position = UDim2.new(0, 5, 0, 5),
                BackgroundTransparency = 1,
                Text = petName,
                TextColor3 = isCollected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150),
                TextScaled = true,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center
            }),
            
            -- Pet rarity
            PetRarity = React.createElement("TextLabel", {
                Size = UDim2.new(1, -10, 0, 15),
                Position = UDim2.new(0, 5, 0, 28),
                BackgroundTransparency = 1,
                Text = petConfig.rarity,
                TextColor3 = isCollected and Color3.fromRGB(150, 200, 255) or Color3.fromRGB(100, 100, 100),
                TextScaled = true,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Center
            }),
            
            -- Collection status or variation
            StatusLabel = React.createElement("TextLabel", {
                Size = UDim2.new(1, -10, 0, 60),
                Position = UDim2.new(0, 5, 0, 50),
                BackgroundTransparency = 1,
                Text = isCollected and (rarestVariation and rarestVariation.VariationName or "Normal") or "Not Collected",
                TextColor3 = isCollected and (rarestVariation and rarestVariation.VariationColor and 
                    Color3.fromRGB(rarestVariation.VariationColor[1], rarestVariation.VariationColor[2], rarestVariation.VariationColor[3]) or 
                    Color3.fromRGB(255, 255, 255)) or Color3.fromRGB(255, 100, 100),
                TextScaled = true,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center
            }),
            
            -- Spawn chance
            SpawnChance = React.createElement("TextLabel", {
                Size = UDim2.new(1, -10, 0, 20),
                Position = UDim2.new(0, 5, 1, -45),
                BackgroundTransparency = 1,
                Text = string.format("%.2f%% chance", petChance),
                TextColor3 = Color3.fromRGB(255, 200, 100),
                TextScaled = true,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Center
            }),
            
            -- Collection info (if collected)
            CollectionInfo = isCollected and React.createElement("TextLabel", {
                Size = UDim2.new(1, -10, 0, 20),
                Position = UDim2.new(0, 5, 1, -25),
                BackgroundTransparency = 1,
                Text = (function()
                    local variationCount = 0
                    for _ in pairs(collectedData[petName].variations) do
                        variationCount = variationCount + 1
                    end
                    local totalCount = collectedData[petName].totalCollected or 0
                    return "Collected: " .. tostring(totalCount) .. " (" .. variationCount .. "/15)"
                end)(),
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextScaled = true,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Center
            }) or nil
        })
    end
    
    -- Hover details panel
    local hoverPanel = nil
    if hoveredPet then
        local hoveredPetName = hoveredPet.name
        local hoveredPetIndex = hoveredPet.index
        local petSpawnChance = spawnChances[hoveredPetIndex] and spawnChances[hoveredPetIndex].normalizedChance or 0
        
        local allVariations = {}
        if VariationConfig and VariationConfig.Variations then
            allVariations = VariationConfig.Variations
        end
        
        local collectedVariations = collectedData[hoveredPetName] and collectedData[hoveredPetName].variations or {}
        
        local variationList = {}
        for i, variation in ipairs(allVariations) do
            local variationData = collectedVariations[variation.name]
            local isOwned = variationData ~= nil
            local combinedChance = (petSpawnChance / 100) * variation.chance
            
            -- Create display text with collection info
            local displayText = variation.name .. (isOwned and " ✓" or " ✗")
            if isOwned and variationData.count then
                displayText = displayText .. " (" .. variationData.count .. ")"
            end
            
            variationList[i] = React.createElement("Frame", {
                Size = UDim2.new(1, -10, 0, 20),
                Position = UDim2.new(0, 5, 0, 50 + (i-1) * 22),
                BackgroundTransparency = 1,
                ZIndex = 202
            }, {
                VariationName = React.createElement("TextLabel", {
                    Size = UDim2.new(0, 120, 1, 0),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Text = displayText,
                    TextColor3 = isOwned and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100),
                    TextScaled = true,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 203
                }),
                
                ChanceText = React.createElement("TextLabel", {
                    Size = UDim2.new(0, 60, 1, 0),
                    Position = UDim2.new(1, -60, 0, 0),
                    BackgroundTransparency = 1,
                    Text = string.format("%.3f%%", combinedChance),
                    TextColor3 = Color3.fromRGB(255, 200, 100),
                    TextScaled = true,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    ZIndex = 203
                })
            })
        end
        
        hoverPanel = React.createElement("Frame", {
            Size = UDim2.new(0, 200, 0, 420),
            Position = UDim2.new(0.5, 110, 0.5, -210),
            BackgroundColor3 = Color3.fromRGB(30, 30, 30),
            BorderSizePixel = 2,
            BorderColor3 = Color3.fromRGB(100, 100, 100),
            ZIndex = 200 -- Higher than main UI
        }, {
            Title = React.createElement("TextLabel", {
                Size = UDim2.new(1, -10, 0, 20),
                Position = UDim2.new(0, 5, 0, 5),
                BackgroundTransparency = 1,
                Text = hoveredPetName,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 201
            }),
            
            PetChance = React.createElement("TextLabel", {
                Size = UDim2.new(1, -10, 0, 18),
                Position = UDim2.new(0, 5, 0, 28),
                BackgroundTransparency = 1,
                Text = string.format("Pet spawn: %.2f%%", petSpawnChance),
                TextColor3 = Color3.fromRGB(255, 200, 100),
                TextScaled = true,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 201
            }),
            
            VariationList = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 1, -35),
                Position = UDim2.new(0, 0, 0, 35),
                BackgroundTransparency = 1,
                ZIndex = 201
            }, variationList)
        })
    end
    
    -- Create level tabs (vertical on left)
    local levelTabs = {}
    for level = 1, 6 do
        levelTabs[level] = React.createElement("TextButton", {
            Size = UDim2.new(1, 0, 0, 50),
            Position = UDim2.new(0, 0, 0, (level - 1) * 55),
            BackgroundColor3 = selectedLevel == level and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(60, 60, 60),
            BorderSizePixel = 0,
            Text = "Lv " .. level,
            TextColor3 = selectedLevel == level and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200),
            TextScaled = true,
            Font = Enum.Font.GothamBold,
            [React.Event.Activated] = function()
                setSelectedLevel(level)
                setHoveredPet(nil)
            end
        })
    end
    
    -- Create door selector (horizontal)
    local doorButtons = {}
    for door = 1, 7 do
        doorButtons[door] = React.createElement("TextButton", {
            Size = UDim2.new(0, 40, 1, 0),
            Position = UDim2.new(0, (door - 1) * 45, 0, 0),
            BackgroundColor3 = selectedDoor == door and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(60, 60, 60),
            BorderSizePixel = 0,
            Text = tostring(door),
            TextColor3 = selectedDoor == door and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200),
            TextScaled = true,
            Font = Enum.Font.GothamBold,
            [React.Event.Activated] = function()
                setSelectedDoor(door)
                setHoveredPet(nil)
            end
        })
    end
    
    return React.createElement("Frame", {
        Size = UDim2.new(0.8, 0, 0.8, 0),
        Position = UDim2.new(0.1, 0, 0.1, 0),
        BackgroundColor3 = Color3.fromRGB(50, 50, 50),
        BorderSizePixel = 0,
        Visible = visible
    }, {
        -- Title
        Title = React.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, 40),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            BorderSizePixel = 0,
            Text = "Pet Index (Press I to toggle)",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextScaled = true,
            Font = Enum.Font.GothamBold
        }),
        
        -- Close button
        CloseButton = React.createElement("TextButton", {
            Size = UDim2.new(0, 30, 0, 30),
            Position = UDim2.new(1, -35, 0, 5),
            BackgroundColor3 = Color3.fromRGB(255, 100, 100),
            BorderSizePixel = 0,
            Text = "X",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextScaled = true,
            Font = Enum.Font.GothamBold,
            [React.Event.Activated] = function()
                setVisible(false)
            end
        }),
        
        -- Level tabs sidebar (vertical on left)
        LevelSidebar = React.createElement("Frame", {
            Size = UDim2.new(0, 80, 1, -50),
            Position = UDim2.new(0, 10, 0, 50),
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            BorderSizePixel = 0
        }, {
            Title = React.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0, 30),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                BorderSizePixel = 0,
                Text = "LEVELS",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                Font = Enum.Font.GothamBold
            }),
            
            TabContainer = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 1, -30),
                Position = UDim2.new(0, 0, 0, 30),
                BackgroundTransparency = 1
            }, levelTabs)
        }),
        
        -- Door selector (horizontal top bar)
        DoorSelector = React.createElement("Frame", {
            Size = UDim2.new(1, -110, 0, 40),
            Position = UDim2.new(0, 100, 0, 50),
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            BorderSizePixel = 0
        }, {
            Title = React.createElement("TextLabel", {
                Size = UDim2.new(0, 80, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = "DOOR:",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left
            }),
            
            Buttons = React.createElement("Frame", {
                Size = UDim2.new(1, -100, 1, 0),
                Position = UDim2.new(0, 100, 0, 0),
                BackgroundTransparency = 1
            }, doorButtons)
        }),
        
        -- Main content area for pet cards
        ScrollFrame = React.createElement("ScrollingFrame", {
            Size = UDim2.new(1, -110, 1, -100),
            Position = UDim2.new(0, 100, 0, 100),
            BackgroundTransparency = 1,
            ScrollBarThickness = 6,
            ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100),
            CanvasSize = UDim2.new(0, 0, 0, math.ceil(#allPets / 6) * 160)
        }, {
            GridLayout = React.createElement("UIGridLayout", {
                CellSize = UDim2.new(0, 120, 0, 180),
                CellPadding = UDim2.new(0, 10, 0, 10),
                SortOrder = Enum.SortOrder.LayoutOrder
            }),
            
            PetCards = React.createElement(React.Fragment, nil, petCards)
        }),
        
        -- Hover panel
        HoverPanel = hoverPanel
    })
end

return PetIndexUI