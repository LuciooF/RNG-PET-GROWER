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
    
    if not visible or not tutorialData.steps or #tutorialData.steps == 0 then
        return nil
    end
    
    local step = tutorialData.steps[currentStep]
    if not step then
        return nil
    end
    
    local isLastStep = currentStep >= #tutorialData.steps
    local progress = math.floor((currentStep / #tutorialData.steps) * 100)
    
    return React.createElement("ScreenGui", {
        Name = "TutorialUI",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    }, {
        -- Tutorial Panel (bottom-right)
        TutorialPanel = React.createElement("Frame", {
            Name = "TutorialPanel",
            Size = ScreenUtils.udim2(0, 450, 0, 350), -- Even taller to prevent overlap
            Position = UDim2.new(1, -470, 1, -370), -- Bottom-right with margin
            BackgroundColor3 = Color3.fromRGB(255, 255, 255), -- Clean white background
            BorderSizePixel = 0,
            ZIndex = 200,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = ScreenUtils.udim(0, 15)
            }),
            
            Stroke = React.createElement("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0), -- Clean black border
                Thickness = 3,
                Transparency = 0,
            }),
            
            -- Background gradient (subtle)
            Gradient = React.createElement("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(240, 240, 240))
                }),
                Rotation = 45,
            }),
            
            -- Header with close button
            Header = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, 55), -- Slightly taller header
                BackgroundColor3 = Color3.fromRGB(50, 50, 50), -- Clean dark header
                BorderSizePixel = 0,
                ZIndex = 201,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 15)
                }),
                
                -- Tutorial title
                Title = React.createElement("TextLabel", {
                    Size = UDim2.new(1, -80, 1, 0),
                    Position = UDim2.new(0, 15, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "🎯 Tutorial - Step " .. currentStep .. "/" .. #tutorialData.steps,
                    TextColor3 = Color3.fromRGB(255, 255, 255), -- Clean white text
                    TextSize = ScreenUtils.TEXT_SIZES.LARGE() + 2,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    ZIndex = 202,
                }),
                
                -- Close button
                CloseButton = React.createElement("ImageButton", {
                    Size = UDim2.new(0, 40, 0, 40),
                    Position = UDim2.new(1, -45, 0.5, -20),
                    BackgroundColor3 = Color3.fromRGB(220, 50, 50), -- Clean red
                    Image = IconAssets.getIcon("UI", "X_BUTTON"),
                    ImageColor3 = Color3.fromRGB(255, 255, 255),
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 202,
                    [React.Event.Activated] = onClose,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, 8)
                    }),
                }),
            }),
            
            -- Progress bar
            ProgressContainer = React.createElement("Frame", {
                Size = UDim2.new(1, -30, 0, 25), -- Taller progress bar
                Position = UDim2.new(0, 15, 0, 65), -- More space from header
                BackgroundColor3 = Color3.fromRGB(200, 200, 200), -- Light gray background
                BorderSizePixel = 0,
                ZIndex = 201,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ScreenUtils.udim(0, 10)
                }),
                
                ProgressBar = React.createElement("Frame", {
                    Size = UDim2.new(progress / 100, 0, 1, 0),
                    BackgroundColor3 = Color3.fromRGB(50, 200, 50), -- Clean green
                    BorderSizePixel = 0,
                    ZIndex = 202,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, 10)
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
                    Text = progress .. "%",
                    TextColor3 = Color3.fromRGB(40, 40, 40), -- Dark text
                    TextSize = ScreenUtils.TEXT_SIZES.SMALL() + 2,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    ZIndex = 203,
                }),
            }),
            
            -- Step content
            ContentArea = React.createElement("Frame", {
                Size = UDim2.new(1, -30, 1, -200), -- Even more space at bottom for buttons
                Position = UDim2.new(0, 15, 0, 105), -- More space from progress bar
                BackgroundTransparency = 1,
                ZIndex = 201,
            }, {
                -- Step title
                StepTitle = React.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 45), -- Even taller title area
                    BackgroundTransparency = 1,
                    Text = step.title or "Step " .. currentStep,
                    TextColor3 = Color3.fromRGB(40, 40, 40), -- Dark readable text
                    TextSize = ScreenUtils.TEXT_SIZES.LARGE() + 2,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top, -- Align to top to prevent overlap
                    ZIndex = 202,
                }),
                
                -- Step description
                StepDescription = React.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 1, -100), -- More space for description
                    Position = UDim2.new(0, 0, 0, 50), -- Even more space from title
                    BackgroundTransparency = 1,
                    Text = step.description or "Follow the glowing path to continue.",
                    TextColor3 = Color3.fromRGB(80, 80, 80), -- Readable gray text
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    TextWrapped = true,
                    ZIndex = 202,
                }),
                
                -- Objective status
                ObjectiveStatus = step.completed and React.createElement("Frame", {
                    Size = UDim2.new(1, 0, 0, 35),
                    Position = UDim2.new(0, 0, 1, -40), -- Position at bottom of content area
                    BackgroundColor3 = Color3.fromRGB(50, 200, 50), -- Clean green
                    BorderSizePixel = 0,
                    ZIndex = 201,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, 8)
                    }),
                    
                    CompletedText = React.createElement("TextLabel", {
                        Size = UDim2.new(1, -40, 1, 0),
                        Position = UDim2.new(0, 35, 0, 0),
                        BackgroundTransparency = 1,
                        Text = "✅ Completed!",
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        ZIndex = 202,
                    }),
                }) or nil,
            }),
            
            -- Action buttons
            ButtonContainer = React.createElement("Frame", {
                Size = UDim2.new(1, -30, 0, 55), -- Taller button area
                Position = UDim2.new(0, 15, 1, -70), -- More space from bottom
                BackgroundTransparency = 1,
                ZIndex = 201,
            }, {
                Layout = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Right,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = ScreenUtils.udim(0, 10),
                }),
                
                -- Skip tutorial button
                SkipButton = React.createElement("TextButton", {
                    Size = UDim2.new(0, 80, 0, 35),
                    BackgroundColor3 = Color3.fromRGB(150, 150, 150), -- Clean gray
                    Text = "Skip",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                    Font = Enum.Font.GothamBold,
                    ZIndex = 202,
                    [React.Event.Activated] = onSkip,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, 8)
                    }),
                }),
                
                -- Next button (only show if step is completed or can be skipped)
                NextButton = (step.completed or step.canSkip) and React.createElement("TextButton", {
                    Size = UDim2.new(0, 100, 0, 35),
                    BackgroundColor3 = isLastStep and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(70, 130, 220), -- Green for finish, blue for next
                    Text = isLastStep and "Finish" or "Next",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM(),
                    Font = Enum.Font.GothamBold,
                    ZIndex = 202,
                    [React.Event.Activated] = onNext,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ScreenUtils.udim(0, 8)
                    }),
                }) or nil,
            }),
        }),
    })
end

function TutorialUI.new(props)
    return React.createElement(TutorialPanel, props)
end

return TutorialUI