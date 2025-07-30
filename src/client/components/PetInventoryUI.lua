-- PetInventoryUI - Shows player's pet collection and rebirth functionality
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local React = require(ReplicatedStorage.Packages.react)
local DataSyncService = require(script.Parent.Parent.services.DataSyncService)
local RebirthUI = require(script.Parent.RebirthUI)

local function PetInventoryUI()
    local playerData, setPlayerData = React.useState({
        Pets = {}
    })
    local isVisible, setIsVisible = React.useState(false)
    local isRebirthVisible, setIsRebirthVisible = React.useState(false)

    -- Subscribe to data changes
    React.useEffect(function()
        -- Get initial data
        local initialData = DataSyncService:GetPlayerData()
        if initialData then
            setPlayerData(initialData)
        end
        
        -- Use proper Rodux subscription instead of heartbeat
        local unsubscribe = DataSyncService:Subscribe(function(newState)
            if newState and newState.player then
                setPlayerData(newState.player)
            end
        end)
        
        return function()
            if unsubscribe and type(unsubscribe) == "function" then
                unsubscribe()
            end
        end
    end, {})

    -- Keyboard shortcut (P key)
    React.useEffect(function()
        local connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            if input.KeyCode == Enum.KeyCode.P then
                setIsVisible(function(prev) return not prev end)
            end
        end)
        
        return function()
            if connection and typeof(connection) == "RBXScriptConnection" then
                pcall(function()
                    connection:Disconnect()
                end)
            end
        end
    end, {})

    local pets = playerData and playerData.Pets or {}
    local equippedPets = playerData and playerData.EquippedPets or {}
    
    -- Create a set of equipped pet IDs for quick lookup
    local equippedPetIds = {}
    for _, pet in ipairs(equippedPets) do
        equippedPetIds[pet.ID] = true
    end
    
    -- Separate pets into equipped and non-equipped groups
    local groupedEquippedPets = {}
    local groupedInventoryPets = {}
    
    -- First, group equipped pets
    for _, pet in ipairs(equippedPets) do
        local rarityName = (pet.Rarity and pet.Rarity.RarityName) or "Common"
        local variationName = (pet.Variation and pet.Variation.VariationName) or "Bronze"
        local key = string.format("%s_%s_%s_equipped", pet.Name or "Unknown", rarityName, variationName)
        
        if not groupedEquippedPets[key] then
            groupedEquippedPets[key] = {
                Name = pet.Name or "Unknown",
                Rarity = pet.Rarity or {RarityName = "Common", RarityColor = {200, 200, 200}}, 
                Variation = pet.Variation or {VariationName = "Bronze", VariationColor = {205, 127, 50}},
                Quantity = 0,
                IsEquipped = true,
                SamplePet = pet -- Store sample pet for unequip
            }
        end
        groupedEquippedPets[key].Quantity = groupedEquippedPets[key].Quantity + 1
    end
    
    -- Then, group non-equipped pets from inventory
    for _, pet in ipairs(pets) do
        if not equippedPetIds[pet.ID] then -- Only include if not equipped
            local rarityName = (pet.Rarity and pet.Rarity.RarityName) or "Common"
            local variationName = (pet.Variation and pet.Variation.VariationName) or "Bronze"
            local key = string.format("%s_%s_%s", pet.Name or "Unknown", rarityName, variationName)
            
            if not groupedInventoryPets[key] then
                groupedInventoryPets[key] = {
                    Name = pet.Name or "Unknown",
                    Rarity = pet.Rarity or {RarityName = "Common", RarityColor = {200, 200, 200}}, 
                    Variation = pet.Variation or {VariationName = "Bronze", VariationColor = {205, 127, 50}},
                    Quantity = 0,
                    IsEquipped = false,
                    SamplePet = pet -- Store sample pet for equip
                }
            end
            groupedInventoryPets[key].Quantity = groupedInventoryPets[key].Quantity + 1
        end
    end
    
    -- Combine both groups (equipped first, then inventory)
    local groupedPets = {}
    for key, group in pairs(groupedEquippedPets) do
        groupedPets[key] = group
    end
    for key, group in pairs(groupedInventoryPets) do
        groupedPets[key] = group
    end
    
    -- Convert to array and sort (equipped pets first)
    local petGroups = {}
    for _, group in pairs(groupedPets) do
        table.insert(petGroups, group)
    end
    
    -- Sort: equipped pets first, then by rarity/name
    table.sort(petGroups, function(a, b)
        if a.IsEquipped and not b.IsEquipped then
            return true
        elseif not a.IsEquipped and b.IsEquipped then
            return false
        else
            -- Both equipped or both not equipped, sort by name
            return a.Name < b.Name
        end
    end)

    -- Side buttons (Pets and Rebirth)
    local sideButtons = React.createElement("Frame", {
        Size = UDim2.new(0, 100, 0, 120),
        Position = UDim2.new(0, 10, 0.5, -60),
        BackgroundTransparency = 1,
    }, {
        -- Pets button
        PetsButton = React.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, 50),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0, 8)
            }),
            
            Button = React.createElement("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Color3.fromRGB(60, 60, 60),
                BorderSizePixel = 0,
                Text = "Pets",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                Font = Enum.Font.GothamBold,
                [React.Event.Activated] = function()
                    setIsVisible(true)
                end
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 8)
                }),
                
                PetCount = React.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 0.3, 0),
                    Position = UDim2.new(0, 0, 0.7, 0),
                    BackgroundTransparency = 1,
                    Text = string.format("(%d)", #pets),
                    TextColor3 = Color3.fromRGB(200, 200, 200),
                    TextScaled = true,
                    Font = Enum.Font.Gotham
                })
            })
        }),
        
        -- Rebirth button
        RebirthButton = React.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, 50),
            Position = UDim2.new(0, 0, 0, 60),
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0, 8)
            }),
            
            Button = React.createElement("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Color3.fromRGB(138, 43, 226),
                BorderSizePixel = 0,
                Text = "Rebirth",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                Font = Enum.Font.GothamBold,
                [React.Event.Activated] = function()
                    setIsRebirthVisible(true)
                end
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 8)
                }),
                
                RebirthCount = React.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 0.3, 0),
                    Position = UDim2.new(0, 0, 0.7, 0),
                    BackgroundTransparency = 1,
                    Text = string.format("(%d)", playerData.Resources and playerData.Resources.Rebirths or 0),
                    TextColor3 = Color3.fromRGB(200, 200, 200),
                    TextScaled = true,
                    Font = Enum.Font.Gotham
                })
            })
        })
    })

    if not isVisible and not isRebirthVisible then
        return sideButtons
    end

    -- Pet inventory panel
    local petInventoryPanel = React.createElement("Frame", {
        Size = UDim2.new(0, 600, 0, 400),
        Position = UDim2.new(0.5, -300, 0.5, -200),
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        BorderSizePixel = 0,
        ZIndex = 100,
        Visible = true
    }, {
        Corner = React.createElement("UICorner", {
            CornerRadius = UDim.new(0, 12)
        }),
        
        -- Header
        Header = React.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, 50),
            BackgroundColor3 = Color3.fromRGB(45, 45, 45),
            BorderSizePixel = 0,
            ZIndex = 101,
            Visible = true
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0, 12)
            }),
            
            Title = React.createElement("TextLabel", {
                Size = UDim2.new(1, -100, 1, 0),
                Position = UDim2.new(0, 20, 0, 0),
                BackgroundTransparency = 1,
                Text = string.format("Pet Inventory (%d pets, %d unique)", #pets, #petGroups),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 102,
                Visible = true
            }),
            
            CloseButton = React.createElement("TextButton", {
                Size = UDim2.new(0, 40, 0, 40),
                Position = UDim2.new(1, -50, 0.5, -20),
                BackgroundColor3 = Color3.fromRGB(200, 50, 50),
                BorderSizePixel = 0,
                Text = "✕",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                Font = Enum.Font.GothamBold,
                ZIndex = 102,
                Visible = true,
                [React.Event.Activated] = function()
                    setIsVisible(false)
                end
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 8)
                })
            })
        }),
        
        -- Content
        Content = React.createElement("ScrollingFrame", {
            Size = UDim2.new(1, -20, 1, -70),
            Position = UDim2.new(0, 10, 0, 60),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 8,
            ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100),
            CanvasSize = UDim2.new(0, 0, 0, math.ceil(#petGroups / 4) * 120 + 20),
            ZIndex = 101,
            Visible = true
        }, {
            Layout = React.createElement("UIGridLayout", {
                CellSize = UDim2.new(0, 130, 0, 100),
                CellPadding = UDim2.new(0, 10, 0, 10),
                SortOrder = Enum.SortOrder.LayoutOrder,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                VerticalAlignment = Enum.VerticalAlignment.Top
            }),
            
            Padding = React.createElement("UIPadding", {
                PaddingTop = UDim.new(0, 10),
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10)
            })
        }, #petGroups > 0 and React.createElement(React.Fragment, nil, (function()
            local petElements = {}
            
            for i, petGroup in ipairs(petGroups) do
                petElements["PetGroup_" .. i] = React.createElement("Frame", {
                    BackgroundColor3 = Color3.fromRGB(50, 50, 50),
                    BorderSizePixel = 0,
                    LayoutOrder = i,
                    ZIndex = 102,
                    Visible = true
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = UDim.new(0, 8)
                    }),
                    
                    PetName = React.createElement("TextLabel", {
                        Size = UDim2.new(1, -10, 0, 18),
                        Position = UDim2.new(0, 5, 0, 5),
                        BackgroundTransparency = 1,
                        Text = petGroup.Name,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextScaled = true,
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ZIndex = 103,
                        Visible = true
                    }),
                    
                    Quantity = React.createElement("TextLabel", {
                        Size = UDim2.new(1, -10, 0, 16),
                        Position = UDim2.new(0, 5, 0, 23),
                        BackgroundTransparency = 1,
                        Text = string.format("QTY: %d", petGroup.Quantity),
                        TextColor3 = Color3.fromRGB(100, 255, 100),
                        TextScaled = true,
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ZIndex = 103,
                        Visible = true
                    }),
                    
                    Rarity = React.createElement("TextLabel", {
                        Size = UDim2.new(1, -10, 0, 14),
                        Position = UDim2.new(0, 5, 0, 42),
                        BackgroundTransparency = 1,
                        Text = (petGroup.Rarity and petGroup.Rarity.RarityName) or "Common",
                        TextColor3 = Color3.fromRGB(150, 200, 255),
                        TextScaled = true,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ZIndex = 103,
                        Visible = true
                    }),
                    
                    Variation = React.createElement("TextLabel", {
                        Size = UDim2.new(1, -10, 0, 14),
                        Position = UDim2.new(0, 5, 0, 58),
                        BackgroundTransparency = 1,
                        Text = (petGroup.Variation and petGroup.Variation.VariationName) or "Bronze",
                        TextColor3 = Color3.fromRGB(255, 215, 100),
                        TextScaled = true,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ZIndex = 103,
                        Visible = true
                    }),
                    
                    -- Equipped indicator
                    EquippedIndicator = petGroup.IsEquipped and React.createElement("TextLabel", {
                        Size = UDim2.new(0, 60, 0, 12),
                        Position = UDim2.new(1, -65, 0, 5),
                        BackgroundColor3 = Color3.fromRGB(100, 255, 100),
                        BorderSizePixel = 0,
                        Text = "EQUIPPED",
                        TextColor3 = Color3.fromRGB(0, 0, 0),
                        TextScaled = true,
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ZIndex = 104,
                    }, {
                        Corner = React.createElement("UICorner", {
                            CornerRadius = UDim.new(0, 4)
                        })
                    }) or nil,
                    
                    -- Equip/Unequip button
                    EquipButton = React.createElement("TextButton", {
                        Size = UDim2.new(1, -10, 0, 18),
                        Position = UDim2.new(0, 5, 1, -23),
                        BackgroundColor3 = petGroup.IsEquipped and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 100),
                        BorderSizePixel = 0,
                        Text = petGroup.IsEquipped and "Unequip" or "Equip",
                        TextColor3 = Color3.fromRGB(0, 0, 0),
                        TextScaled = true,
                        Font = Enum.Font.GothamBold,
                        ZIndex = 103,
                        [React.Event.Activated] = function()
                            local equipRemote = ReplicatedStorage:FindFirstChild("EquipPet")
                            local unequipRemote = ReplicatedStorage:FindFirstChild("UnequipPet")
                            
                            if petGroup.IsEquipped then
                                -- Unequip pet
                                if unequipRemote and petGroup.SamplePet then
                                    unequipRemote:FireServer(petGroup.SamplePet.ID)
                                end
                            else
                                -- Equip pet
                                if equipRemote and petGroup.SamplePet then
                                    equipRemote:FireServer(petGroup.SamplePet.ID)
                                end
                            end
                        end
                    }, {
                        Corner = React.createElement("UICorner", {
                            CornerRadius = UDim.new(0, 4)
                        })
                    })
                })
            end
            
            return petElements
        end)()) or nil),
        
        -- Empty state
        EmptyState = #petGroups == 0 and React.createElement("Frame", {
            Size = UDim2.new(1, -20, 1, -70),
            Position = UDim2.new(0, 10, 0, 60),
            BackgroundTransparency = 1
        }, {
            EmptyText = React.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "No pets collected yet!\nTouch purple pet balls to collect pets.",
                TextColor3 = Color3.fromRGB(150, 150, 150),
                TextScaled = true,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center
            })
        }) or nil
    })
    
    -- Handle rebirth functionality
    local function handleRebirth()
        -- Create remote event request
        local rebirthRemote = ReplicatedStorage:WaitForChild("RebirthPlayer")
        rebirthRemote:FireServer()
        setIsRebirthVisible(false)
    end
    
    -- Return multiple UI elements
    return React.createElement(React.Fragment, nil, {
        SideButtons = sideButtons,
        
        PetInventory = isVisible and petInventoryPanel or nil,
        
        RebirthPanel = isRebirthVisible and React.createElement(RebirthUI.new, {
            visible = isRebirthVisible,
            playerMoney = playerData.Resources and playerData.Resources.Money or 0,
            playerRebirths = playerData.Resources and playerData.Resources.Rebirths or 0,
            canRebirth = playerData.Resources and playerData.Resources.Money >= 1000,
            onClose = function()
                setIsRebirthVisible(false)
            end,
            onRebirth = handleRebirth
        }) or nil
    })
end

return PetInventoryUI