-- Lab Panel Modern - Modular Architecture
-- Refactored from LabPanel.lua following CLAUDE.md modular architecture patterns
-- Uses extracted controllers and reusable UI components

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local React = require(ReplicatedStorage.Packages.react)
local e = React.createElement

-- Import shared utilities
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local AnimationHelpers = require(ReplicatedStorage.utils.AnimationHelpers)

-- Import business logic controllers
local LabController = require(script.Parent.Parent.services.controllers.LabController)
local PetInventoryController = require(script.Parent.Parent.services.PetInventoryController)

-- Import UI components
local LabPetCard = require(script.Parent.ui.LabPetCard)
local LabPetSlot = require(script.Parent.ui.LabPetSlot)
local LabMergeButton = require(script.Parent.ui.LabMergeButton)
local LabOutcomeDisplay = require(script.Parent.ui.LabOutcomeDisplay)

-- Import services
local RewardsService = require(script.Parent.Parent.RewardsService)

local function LabPanelModern(props)
    local playerData = props.playerData or {}
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local visible = props.visible or false
    local onClose = props.onClose or function() end
    
    -- Panel state using LabController
    local selectedPets, setSelectedPets = React.useState({nil, nil, nil})
    local showMergeConfirm, setShowMergeConfirm = React.useState(false)
    local merging, setMerging = React.useState(false)
    local mergeResult, setMergeResult = React.useState(nil)
    
    -- Responsive sizing
    local scale = ScreenUtils.getProportionalScale(screenSize)
    local panelWidth = math.min(screenSize.X * 0.9, ScreenUtils.getProportionalSize(screenSize, 900))
    local panelHeight = math.min(screenSize.Y * 0.85, ScreenUtils.getProportionalSize(screenSize, 600))
    
    -- Text sizes
    local titleTextSize = ScreenUtils.getProportionalTextSize(screenSize, 32)
    local normalTextSize = ScreenUtils.getProportionalTextSize(screenSize, 18)
    local buttonTextSize = ScreenUtils.getProportionalTextSize(screenSize, 16)
    
    -- Get available pets using LabController
    local availablePets = React.useMemo(function()
        return LabController.getAvailablePets(playerData)
    end, {playerData.ownedPets, playerData.companionPets})
    
    -- Calculate grid dimensions
    local gridDimensions = PetInventoryController.calculateGridDimensions(availablePets, screenSize, panelWidth)
    local cardWidth = gridDimensions.cardWidth
    local cardHeight = gridDimensions.cardHeight
    local totalHeight = gridDimensions.totalHeight
    
    -- Calculate merge information using LabController
    local mergeInfo = React.useMemo(function()
        return LabController.calculateMergeInfo(selectedPets, playerData)
    end, {selectedPets, playerData.resources and playerData.resources.diamonds})
    
    -- Event handlers using LabController
    local function handlePetSelect(petItem)
        -- Check if already 3 pets selected and this isn't a deselection
        local currentSelectedCount = 0
        for i = 1, 3 do
            if selectedPets[i] then
                currentSelectedCount = currentSelectedCount + 1
            end
        end
        
        -- Check if this exact pet (uniqueId) is already selected
        local alreadySelectedIndex = nil
        for i = 1, 3 do
            if selectedPets[i] and selectedPets[i].uniqueId == petItem.uniqueId then
                alreadySelectedIndex = i
                break
            end
        end
        
        -- If this pet is already selected, deselect it
        if alreadySelectedIndex then
            setSelectedPets(function(current)
                return LabController.removePet(current, alreadySelectedIndex)
            end)
            return
        end
        
        -- If trying to select a 4th pet
        if currentSelectedCount >= 3 then
            print("Can't select a 4th pet, deselect one first")
            return
        end
        
        setSelectedPets(function(current)
            return LabController.selectPet(current, petItem)
        end)
    end
    
    local function handlePetRemove(slotIndex)
        setSelectedPets(function(current)
            return LabController.removePet(current, slotIndex)
        end)
    end
    
    local function handleMerge()
        if not LabController.canExecuteMerge(mergeInfo) then
            return
        end
        setShowMergeConfirm(true)
    end
    
    local function handleConfirmedMerge()
        local success, mergeData = LabController.requestMerge(selectedPets, mergeInfo)
        if not success then
            print("Merge failed:", mergeData)
            return
        end
        
        setMerging(true)
        setShowMergeConfirm(false)
        
        -- Execute merge via remote
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local mergePetsRemote = remotes:FindFirstChild("MergePets")
            if mergePetsRemote then
                mergePetsRemote:FireServer(mergeData)
            end
        end
    end
    
    local function handleClose()
        local resetState = LabController.resetLabState()
        setSelectedPets(resetState.selectedPets)
        setShowMergeConfirm(resetState.showMergeConfirm)
        setMerging(resetState.merging)
        setMergeResult(resetState.mergeResult)
        onClose()
    end
    
    if not visible then return nil end
    
    return e("Frame", {
        Name = "LabPanel",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ZIndex = 50
    }, {
        MainPanel = e("Frame", {
            Name = "LabPanel",
            Size = UDim2.new(0, panelWidth, 0, panelHeight),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(240, 245, 255),
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
            ZIndex = 51
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 20)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(100, 255, 100), -- Green theme for Lab
                Thickness = 3,
                Transparency = 0.1
            }),
            Gradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(250, 255, 250)),
                    ColorSequenceKeypoint.new(0.7, Color3.fromRGB(245, 255, 245)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(240, 255, 240))
                },
                Rotation = 135
            }),
            
            -- Floating Title (matching Pet Inventory pattern)
            FloatingTitle = e("Frame", {
                Name = "FloatingTitle",
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 280), 0, ScreenUtils.getProportionalSize(screenSize, 40)),
                Position = UDim2.new(0, -10, 0, -25),
                BackgroundColor3 = Color3.fromRGB(100, 255, 100), -- Green theme for Lab
                BorderSizePixel = 0,
                ZIndex = 52
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 12)
                }),
                Gradient = e("UIGradient", {
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 255, 120)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 255, 80))
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
                    ZIndex = 53
                }, {
                    Layout = e("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = UDim.new(0, 5),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    }),
                    
                    LabIcon = e("TextLabel", {
                        Name = "LabIcon",
                        Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 24), 0, ScreenUtils.getProportionalSize(screenSize, 24)),
                        Text = "🧪",
                        BackgroundTransparency = 1,
                        TextScaled = true,
                        Font = Enum.Font.SourceSansBold,
                        ZIndex = 54,
                        LayoutOrder = 1
                    }),
                    
                    TitleText = e("TextLabel", {
                        Size = UDim2.new(0, 0, 1, 0),
                        AutomaticSize = Enum.AutomaticSize.X,
                        Text = "PET LAB",
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = titleTextSize,
                        TextWrapped = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold,
                        ZIndex = 54,
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
            
            -- Close Button (matching Pet Inventory pattern)
            CloseButton = e("ImageButton", {
                Name = "CloseButton",
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 32), 0, ScreenUtils.getProportionalSize(screenSize, 32)),
                Position = UDim2.new(1, -16, 0, -16),
                Image = "rbxassetid://137122155343638",
                ImageColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 54,
                ScaleType = Enum.ScaleType.Fit,
                [React.Event.Activated] = handleClose,
                [React.Event.MouseEnter] = function(button)
                    button.ImageColor3 = Color3.fromRGB(180, 180, 180)
                end,
                [React.Event.MouseLeave] = function(button)
                    button.ImageColor3 = Color3.fromRGB(255, 255, 255)
                end
            }),
            
            -- Merge Section
            MergeSection = e("Frame", {
                Name = "MergeSection",
                Size = UDim2.new(1, -40, 0, 200),
                Position = UDim2.new(0, 20, 0, 50),
                BackgroundColor3 = Color3.fromRGB(250, 252, 255),
                BackgroundTransparency = 0.1,
                BorderSizePixel = 0,
                ZIndex = 52
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 15)
                }),
                
                Layout = e("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 20),
                    SortOrder = Enum.SortOrder.LayoutOrder
                }),
                
                -- Input Slots
                InputSlots = e("Frame", {
                    Name = "InputSlots",
                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 450), 1, -40),
                    BackgroundTransparency = 1,
                    ZIndex = 53,
                    LayoutOrder = 1
                }, {
                    SlotsLayout = e("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = UDim.new(0, 10),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    }),
                    
                    -- Generate 3 input slots using LabPetSlot component
                    Slots = React.createElement(React.Fragment, {}, (function()
                        local slots = {}
                        
                        for i = 1, 3 do
                            slots["slot_" .. i] = React.createElement(LabPetSlot, {
                                slotIndex = i,
                                selectedPet = selectedPets[i],
                                screenSize = screenSize,
                                onRemove = handlePetRemove
                            })
                        end
                        
                        return slots
                    end)())
                }),
                
                -- Equals symbol
                EqualsSymbol = e("TextLabel", {
                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 30), 0, ScreenUtils.getProportionalSize(screenSize, 40)),
                    Text = "=",
                    TextColor3 = Color3.fromRGB(60, 80, 140),
                    TextSize = ScreenUtils.getProportionalTextSize(screenSize, 32),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 53,
                    LayoutOrder = 2
                }),
                
                -- Outcome Display using LabOutcomeDisplay component
                OutcomeDisplay = mergeInfo.showPreview and React.createElement(LabOutcomeDisplay, {
                    outcomes = mergeInfo.outcomes or {},
                    screenSize = screenSize
                }) or e("Frame", {
                    Name = "PlaceholderOutcome", 
                    Size = UDim2.new(0, 180, 1, -40),
                    BackgroundColor3 = Color3.fromRGB(220, 220, 220),
                    BackgroundTransparency = 0.3,
                    BorderSizePixel = 0,
                    ZIndex = 53,
                    LayoutOrder = 3
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 12)
                    }),
                    PlaceholderText = e("TextLabel", {
                        Size = UDim2.new(1, 0, 1, 0),
                        Text = mergeInfo.error or "Select 3 pets to merge",
                        TextColor3 = Color3.fromRGB(100, 100, 100),
                        TextSize = normalTextSize,
                        TextWrapped = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        ZIndex = 54
                    })
                })
            }),
            
            -- Merge Button using LabMergeButton component
            MergeButtonContainer = e("Frame", {
                Name = "MergeButtonContainer",
                Size = UDim2.new(1, -40, 0, 70),
                Position = UDim2.new(0, 20, 0, 270),
                BackgroundTransparency = 1,
                ZIndex = 52
            }, {
                Layout = e("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    SortOrder = Enum.SortOrder.LayoutOrder
                }),
                
                MergeButton = React.createElement(LabMergeButton, {
                    mergeInfo = mergeInfo,
                    screenSize = screenSize,
                    selectedCount = (selectedPets[1] and 1 or 0) + (selectedPets[2] and 1 or 0) + (selectedPets[3] and 1 or 0),
                    onMerge = handleMerge
                })
            }),
            
            -- Pet Selection Area
            PetSelectionArea = e("Frame", {
                Name = "PetSelectionArea",
                Size = UDim2.new(1, -40, 1, -360),
                Position = UDim2.new(0, 20, 0, 350),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 0.1,
                BorderSizePixel = 0,
                ZIndex = 52
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 15)
                }),
                
                Title = e("TextLabel", {
                    Size = UDim2.new(1, -20, 0, 30),
                    Position = UDim2.new(0, 10, 0, 10),
                    Text = "Select Pets to Merge (same size only)",
                    TextColor3 = Color3.fromRGB(60, 80, 140),
                    TextSize = normalTextSize,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 53
                }),
                
                -- Scrolling pet list
                PetScrollFrame = e("ScrollingFrame", {
                    Size = UDim2.new(1, -20, 1, -50),
                    Position = UDim2.new(0, 10, 0, 40),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    CanvasSize = UDim2.new(0, 0, 0, totalHeight),
                    ScrollBarThickness = 8,
                    ZIndex = 53
                }, {
                    -- Pet cards
                    PetCards = React.createElement(React.Fragment, {}, (function()
                        local cards = {}
                        
                        for i, petItem in ipairs(availablePets) do
                            -- Check if this pet is currently selected
                            local isSelected = false
                            for j = 1, 3 do
                                if selectedPets[j] and selectedPets[j].uniqueId == petItem.uniqueId then
                                    isSelected = true
                                    break
                                end
                            end
                            
                            cards["pet_" .. i] = React.createElement(LabPetCard, {
                                petItem = petItem,
                                screenSize = screenSize,
                                cardWidth = cardWidth,
                                cardHeight = cardHeight,
                                layoutOrder = i,
                                isSelected = isSelected,
                                onSelect = handlePetSelect
                            })
                        end
                        
                        return cards
                    end)()),
                    
                    Layout = e("UIGridLayout", {
                        CellSize = UDim2.new(0, cardWidth, 0, cardHeight),
                        CellPadding = UDim2.new(0, 10, 0, 10),
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Top,
                        SortOrder = Enum.SortOrder.LayoutOrder
                    })
                })
            })
        }),
        
        -- Confirmation Dialog
        ConfirmDialog = showMergeConfirm and e("Frame", {
            Name = "ConfirmDialog",
            Size = UDim2.new(0, 400, 0, 200),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 60
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 15)
            }),
            
            Layout = e("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 15),
                SortOrder = Enum.SortOrder.LayoutOrder
            }),
            
            Padding = e("UIPadding", {
                PaddingTop = UDim.new(0, 20),
                PaddingBottom = UDim.new(0, 20),
                PaddingLeft = UDim.new(0, 20),
                PaddingRight = UDim.new(0, 20)
            }),
            
            Title = e("TextLabel", {
                Size = UDim2.new(1, 0, 0, 30),
                Text = "Confirm Merge",
                TextColor3 = Color3.fromRGB(60, 80, 140),
                TextSize = ScreenUtils.getProportionalTextSize(screenSize, 24),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 61,
                LayoutOrder = 1
            }),
            
            Message = e("TextLabel", {
                Size = UDim2.new(1, 0, 0, 60),
                Text = string.format("Merge 3 pets for %d diamonds?", mergeInfo.diamondCost or 0),
                TextColor3 = Color3.fromRGB(80, 80, 80),
                TextSize = normalTextSize,
                TextWrapped = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 61,
                LayoutOrder = 2
            }),
            
            ButtonContainer = e("Frame", {
                Size = UDim2.new(1, 0, 0, 50),
                BackgroundTransparency = 1,
                ZIndex = 61,
                LayoutOrder = 3
            }, {
                Layout = e("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 20),
                    SortOrder = Enum.SortOrder.LayoutOrder
                }),
                
                ConfirmButton = e("TextButton", {
                    Size = UDim2.new(0, 120, 0, 40),
                    BackgroundColor3 = Color3.fromRGB(100, 255, 100),
                    BorderSizePixel = 0,
                    Text = "CONFIRM",
                    TextColor3 = Color3.fromRGB(0, 0, 0),
                    TextSize = buttonTextSize,
                    Font = Enum.Font.GothamBold,
                    ZIndex = 62,
                    LayoutOrder = 1,
                    [React.Event.Activated] = handleConfirmedMerge
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 8)
                    })
                }),
                
                CancelButton = e("TextButton", {
                    Size = UDim2.new(0, 120, 0, 40),
                    BackgroundColor3 = Color3.fromRGB(255, 100, 100),
                    BorderSizePixel = 0,
                    Text = "CANCEL",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = buttonTextSize,
                    Font = Enum.Font.GothamBold,
                    ZIndex = 62,
                    LayoutOrder = 2,
                    [React.Event.Activated] = function()
                        setShowMergeConfirm(false)
                    end
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 8)
                    })
                })
            })
        }) or nil
    })
end

return LabPanelModern