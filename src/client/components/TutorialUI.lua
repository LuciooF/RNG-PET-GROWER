-- TutorialUI - Interactive tutorial system with pathfinding
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local React = require(ReplicatedStorage.Packages.react)

local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)
local DataSyncService = require(script.Parent.Parent.services.DataSyncService)
local TutorialService = require(script.Parent.Parent.services.TutorialService)

local TutorialUI = {}

local function TutorialPanel(props)
    local visible = props.visible or false
    local currentStep = props.currentStep or 1
    local tutorialData = props.tutorialData or {}
    local onClose = props.onClose or function() end
    local onNext = props.onNext or function() end
    local onSkip = props.onSkip or function() end
    
    -- State for confirmation dialog
    local showConfirmDialog, setShowConfirmDialog = React.useState(false)
    local confirmAction, setConfirmAction = React.useState(nil)
    
    if not visible or not tutorialData.steps or #tutorialData.steps == 0 then
        return nil
    end
    
    local step = tutorialData.steps[currentStep]
    if not step then
        return nil
    end
    
    local isLastStep = currentStep >= #tutorialData.steps
    
    -- Get progress text and determine if we should show visual progress bar
    local progressText = TutorialService:GetProgressText() or "Loading..."
    
    -- Determine if this step should show a visual progress bar
    local showProgressBar = false
    local progress = 0
    
    if step.id == "collect_pets" or step.id == "collect_10_pets" or step.id == "collect_100_pets" or 
       step.id == "process_pets" or step.id == "process_500_pets" then
        -- These steps have meaningful progress (X/Y format)
        showProgressBar = true
        local taskProgress = tutorialData.taskProgress or 0
        progress = math.floor(taskProgress)
    elseif progressText:find("%%") then
        -- If the text contains %, it's a percentage-based step
        showProgressBar = true
        local taskProgress = tutorialData.taskProgress or 0
        progress = math.floor(taskProgress)
    else
        -- Binary completion steps (completed/not achieved) - no visual progress bar
        showProgressBar = false
        progress = 0
    end
    
    -- Handle confirmation actions
    local function handleCloseConfirm()
        setShowConfirmDialog(true)
        setConfirmAction("close")
    end
    
    local function handleSkipConfirm()
        setShowConfirmDialog(true)
        setConfirmAction("skip")
    end
    
    local function handleConfirm()
        setShowConfirmDialog(false)
        if confirmAction == "close" then
            onClose()
        elseif confirmAction == "skip" then
            onSkip()
        end
        setConfirmAction(nil)
    end
    
    local function handleCancel()
        setShowConfirmDialog(false)
        setConfirmAction(nil)
    end
    
    -- Get screen size for responsive sizing
    local screenSize = ScreenUtils.getScreenSize()
    local screenWidth = screenSize.X
    local screenHeight = screenSize.Y
    
    -- Calculate responsive panel width (balanced size)
    local panelWidth = math.max(350, screenWidth * 0.28) -- 28% of screen width, minimum 350px
    local panelMargin = ScreenUtils.getProportionalSize(20) -- Margin from screen edge
    
    return React.createElement("ScreenGui", {
        Name = "TutorialUI",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    }, {
        -- Tutorial Panel (bottom-right) - Dynamic height, responsive positioning
        TutorialPanel = React.createElement("Frame", {
            Name = "TutorialPanel",
            Size = UDim2.new(0, panelWidth, 0, 0), -- Responsive width, auto height
            AutomaticSize = Enum.AutomaticSize.Y, -- Dynamic height based on content
            Position = UDim2.new(1, -(panelWidth + panelMargin), 1, -panelMargin), -- Responsive positioning
            AnchorPoint = Vector2.new(0, 1), -- Anchor to bottom so it grows upward
            BackgroundColor3 = Color3.fromRGB(245, 248, 255), -- Soft blue-tinted white
            BorderSizePixel = 0,
            ZIndex = 200,
        }, {
            -- Layout for the entire panel
            PanelLayout = React.createElement("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Top,
                Padding = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(10)), -- Responsive spacing
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
            
            -- Padding at top and bottom
            PanelPadding = React.createElement("UIPadding", {
                PaddingTop = ScreenUtils.udim(0, 0), -- Remove top padding so header is at the top
                PaddingBottom = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(15)),
                PaddingLeft = ScreenUtils.udim(0, 0),
                PaddingRight = ScreenUtils.udim(0, 0),
            }),
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(15))
            }),
            
            Stroke = React.createElement("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0), -- Clean black border
                Thickness = 3,
                Transparency = 0,
            }),
            
            -- Background gradient (subtle)
            Gradient = React.createElement("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(245, 248, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(230, 240, 255))
                }),
                Rotation = 45,
            }),
            
            -- Header with close button
            Header = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(55)), -- Responsive header height
                BackgroundColor3 = Color3.fromRGB(70, 130, 220), -- Vibrant blue header
                BorderSizePixel = 0,
                ZIndex = 201,
                LayoutOrder = 1,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(15))
                }),
                
                -- Tutorial title
                Title = React.createElement("TextLabel", {
                    Size = UDim2.new(1, -ScreenUtils.getProportionalSize(80), 1, 0),
                    Position = UDim2.new(0, ScreenUtils.getProportionalSize(40), 0, 0),
                    BackgroundTransparency = 1,
                    Text = "🎯 Tutorial - Step " .. currentStep .. "/" .. #tutorialData.steps,
                    TextColor3 = Color3.fromRGB(255, 255, 255), -- Clean white text
                    TextSize = ScreenUtils.TEXT_SIZES.HEADER(),
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 202,
                }),
                
                -- Close button
                CloseButton = React.createElement("ImageButton", {
                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(40), 0, ScreenUtils.getProportionalSize(40)),
                    Position = UDim2.new(1, -ScreenUtils.getProportionalSize(45), 0.5, -ScreenUtils.getProportionalSize(20)),
                    BackgroundColor3 = Color3.fromRGB(255, 80, 80), -- Bright red
                    Image = IconAssets.getIcon("UI", "X_BUTTON"),
                    ImageColor3 = Color3.fromRGB(255, 255, 255),
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 202,
                    [React.Event.Activated] = handleCloseConfirm,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(8))
                    }),
                }),
            }),
            
            -- Progress bar
            ProgressContainer = React.createElement("Frame", {
                Size = UDim2.new(1, -ScreenUtils.getProportionalSize(30), 0, ScreenUtils.getProportionalSize(25)), -- Responsive progress bar
                BackgroundColor3 = Color3.fromRGB(220, 230, 240), -- Light blue-gray background
                BorderSizePixel = 0,
                ZIndex = 201,
                LayoutOrder = 2,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(10))
                }),
                
                ProgressBar = React.createElement("Frame", {
                    Size = showProgressBar and UDim2.new(progress / 100, 0, 1, 0) or UDim2.new(0, 0, 1, 0), -- Dynamic based on step type
                    BackgroundColor3 = Color3.fromRGB(50, 200, 100), -- Vibrant teal
                    BorderSizePixel = 0,
                    ZIndex = 202,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(10))
                    }),
                    
                    Gradient = React.createElement("UIGradient", {
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 255, 100)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 200, 50))
                        }),
                    }),
                }),
                
                ProgressText = React.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = progressText,
                    TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() + 2,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 203,
                }),
            }),
            
            -- Step content with automatic layout
            ContentArea = React.createElement("Frame", {
                Size = UDim2.new(1, -30, 0, 0), -- Width fixed, height automatic
                AutomaticSize = Enum.AutomaticSize.Y, -- Dynamic height
                BackgroundTransparency = 1,
                ZIndex = 201,
                LayoutOrder = 3,
            }, {
                -- Use UIListLayout for automatic sizing
                Layout = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Top,
                    Padding = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(10)),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }),
                
                -- Step title (auto-sized)
                StepTitle = React.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 0), -- Height will be determined by TextBounds
                    AutomaticSize = Enum.AutomaticSize.Y, -- Let it size itself vertically
                    BackgroundTransparency = 1,
                    Text = step.title or "Step " .. currentStep,
                    TextColor3 = Color3.fromRGB(20, 20, 20),
                    TextSize = ScreenUtils.TEXT_SIZES.HEADER() + 2,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    TextWrapped = true,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(255, 255, 255),
                    ZIndex = 202,
                    LayoutOrder = 1,
                }),
                
                -- Step description (auto-sized)
                StepDescription = React.createElement("TextLabel", {
                    Size = UDim2.new(1, -20, 0, 0), -- Height will be determined by TextBounds
                    AutomaticSize = Enum.AutomaticSize.Y, -- Let it size itself vertically
                    BackgroundTransparency = 1,
                    Text = step.description or "Follow the glowing path to continue.",
                    TextColor3 = Color3.fromRGB(40, 40, 40),
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() + 1,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    TextWrapped = true,
                    LineHeight = 1.3,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(255, 255, 255),
                    ZIndex = 202,
                    LayoutOrder = 2,
                }),
                
                -- Objective status (removed - taking up too much space)
            }),
            
            -- Action buttons (only Next button when needed) - Auto height
            ButtonContainer = React.createElement("Frame", {
                Size = UDim2.new(1, -ScreenUtils.getProportionalSize(30), 0, ScreenUtils.getProportionalSize(60)), -- Responsive button container
                BackgroundTransparency = 1,
                ZIndex = 201,
                LayoutOrder = 4,
            }, {                
                -- Next button (only show if step is completed or can be skipped)
                NextButton = (step.completed or step.canSkip) and React.createElement("TextButton", {
                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(120), 0, ScreenUtils.getProportionalSize(40)),
                    Position = UDim2.new(1, -ScreenUtils.getProportionalSize(120), 0.5, -ScreenUtils.getProportionalSize(20)), -- Responsive positioning
                    BackgroundColor3 = isLastStep and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(70, 130, 220), -- Green for finish, blue for next
                    Text = isLastStep and "Finish" or "Next",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.TEXT_SIZES.LARGE(),
                    Font = Enum.Font.GothamBold,
                    ZIndex = 202,
                    [React.Event.Activated] = onNext,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(8))
                    }),
                }) or nil,
            }),
        }),
        
        -- Confirmation Dialog
        ConfirmDialog = showConfirmDialog and React.createElement("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 0.3,
            ZIndex = 300,
        }, {
            DialogBox = React.createElement("Frame", {
                Size = ScreenUtils.udim2(0, math.max(450, screenWidth * 0.35), 0, math.max(300, screenHeight * 0.25)), -- Responsive dialog size
                Position = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                ZIndex = 301,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(15))
                }),
                
                Stroke = React.createElement("UIStroke", {
                    Color = Color3.fromRGB(200, 50, 50),
                    Thickness = ScreenUtils.getProportionalSize(3),
                }),
                
                -- Warning icon and title
                Title = React.createElement("TextLabel", {
                    Size = UDim2.new(1, -ScreenUtils.getProportionalSize(20), 0, ScreenUtils.getProportionalSize(60)),
                    Position = UDim2.new(0, ScreenUtils.getProportionalSize(10), 0, ScreenUtils.getProportionalSize(15)),
                    BackgroundTransparency = 1,
                    Text = "⚠️ WARNING",
                    TextColor3 = Color3.fromRGB(200, 50, 50),
                    TextSize = ScreenUtils.TEXT_SIZES.LARGE() + 4,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 302,
                }),
                
                -- Warning message
                Message = React.createElement("TextLabel", {
                    Size = UDim2.new(1, -ScreenUtils.getProportionalSize(40), 1, -ScreenUtils.getProportionalSize(160)), -- Take remaining space, leave room for title and buttons
                    Position = UDim2.new(0, ScreenUtils.getProportionalSize(20), 0, ScreenUtils.getProportionalSize(85)),
                    BackgroundTransparency = 1,
                    Text = confirmAction == "close" and 
                        "Are you sure you want to close the tutorial?\n\nYou may not know what to do without it!" or
                        "Are you sure you want to skip the tutorial?\n\nYou may miss important game mechanics!",
                    TextColor3 = Color3.fromRGB(50, 50, 50),
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                    Font = Enum.Font.Gotham,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    ZIndex = 302,
                }),
                
                -- Button container
                ButtonContainer = React.createElement("Frame", {
                    Size = UDim2.new(1, -ScreenUtils.getProportionalSize(40), 0, ScreenUtils.getProportionalSize(50)),
                    Position = UDim2.new(0, ScreenUtils.getProportionalSize(20), 1, -ScreenUtils.getProportionalSize(70)),
                    BackgroundTransparency = 1,
                    ZIndex = 301,
                }, {
                    Layout = React.createElement("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = ScreenUtils.udim(0, ScreenUtils.getProportionalSize(20)),
                    }),
                    
                    -- Cancel button
                    CancelButton = React.createElement("TextButton", {
                        Size = UDim2.new(0, ScreenUtils.getProportionalSize(140), 0, ScreenUtils.getProportionalSize(45)),
                        BackgroundColor3 = Color3.fromRGB(100, 200, 100),
                        Text = "Stay in Tutorial",
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                        Font = Enum.Font.GothamBold,
                        ZIndex = 302,
                        [React.Event.Activated] = handleCancel,
                    }, {
                        Corner = React.createElement("UICorner", {
                            CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(8))
                        }),
                    }),
                    
                    -- Confirm button
                    ConfirmButton = React.createElement("TextButton", {
                        Size = UDim2.new(0, ScreenUtils.getProportionalSize(140), 0, ScreenUtils.getProportionalSize(45)),
                        BackgroundColor3 = Color3.fromRGB(200, 50, 50),
                        Text = confirmAction == "close" and "Close" or "Skip",
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                        Font = Enum.Font.GothamBold,
                        ZIndex = 302,
                        [React.Event.Activated] = handleConfirm,
                    }, {
                        Corner = React.createElement("UICorner", {
                            CornerRadius = ScreenUtils.udim(0, ScreenUtils.getCornerRadius(8))
                        }),
                    }),
                }),
            }),
        }) or nil,
    })
end

function TutorialUI.new(props)
    return React.createElement(TutorialPanel, props)
end

return TutorialUI