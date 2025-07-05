-- Codes Panel Component
-- Modern UI for redeeming codes matching the RebirthPanel style

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local ScreenUtils = require(game:GetService("ReplicatedStorage").utils.ScreenUtils)
local assets = require(game:GetService("ReplicatedStorage").assets)
local CodesService = require(script.Parent.Parent.CodesService)
local ClickOutsideWrapper = require(script.Parent.ClickOutsideWrapper)
local e = React.createElement

local function CodesPanel(props)
    local visible = props.visible
    local onClose = props.onClose
    local remotes = props.remotes
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    -- State
    local codeInput, setCodeInput = React.useState("")
    local isRedeeming, setIsRedeeming = React.useState(false)
    local errorMessage, setErrorMessage = React.useState("")
    local successMessage, setSuccessMessage = React.useState("")
    
    -- Responsive sizing
    local scale = ScreenUtils.getProportionalScale(screenSize)
    local panelWidth = ScreenUtils.getProportionalSize(screenSize, 450)
    local panelHeight = ScreenUtils.getProportionalSize(screenSize, 280)
    
    -- Text sizes
    local titleTextSize = ScreenUtils.getProportionalTextSize(screenSize, 24)
    local normalTextSize = ScreenUtils.getProportionalTextSize(screenSize, 18)
    local buttonTextSize = ScreenUtils.getProportionalTextSize(screenSize, 20)
    
    -- Handle code submission
    local function handleSubmit()
        if isRedeeming then return end
        
        -- Clear previous messages
        setErrorMessage("")
        setSuccessMessage("")
        
        -- Validate input
        if codeInput == "" then
            setErrorMessage("Please enter a code!")
            return
        end
        
        -- Start redeeming
        setIsRedeeming(true)
        
        -- Set up callback for response
        CodesService.setRedeemCallback(function(success, code, errorData)
            setIsRedeeming(false)
            
            if success then
                setSuccessMessage("Code redeemed successfully!")
                setCodeInput("") -- Clear input on success
                -- Auto-close after 2 seconds
                spawn(function()
                    wait(2)
                    if onClose then
                        onClose()
                    end
                end)
            else
                -- Handle different error types
                if errorData and errorData.message then
                    setErrorMessage(errorData.message)
                else
                    setErrorMessage("Invalid or already redeemed code!")
                end
            end
        end)
        
        -- Attempt to redeem
        CodesService.redeemCode(codeInput, remotes)
    end
    
    return e(ClickOutsideWrapper, {
        visible = visible,
        onClose = onClose
    }, {
        Container = e("Frame", {
            Name = "CodesContainer",
            Size = UDim2.new(0, panelWidth, 0, panelHeight + 100), -- Increased height for dynamic messages
            Position = UDim2.new(0.5, -panelWidth / 2, 0.5, -(panelHeight + 100) / 2),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        ZIndex = 30
    }, {
        
        CodesPanel = e("Frame", {
            Name = "CodesPanel",
            Size = UDim2.new(0, panelWidth, 0, panelHeight),
            Position = UDim2.new(0, 0, 0, 50),
            BackgroundColor3 = Color3.fromRGB(240, 245, 255),
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
            ZIndex = 30
        }, {
            -- Floating Title (similar to RebirthPanel)
            FloatingTitle = e("Frame", {
                Name = "FloatingTitle",
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 180), 0, ScreenUtils.getProportionalSize(screenSize, 40)),
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, -10), 0, ScreenUtils.getProportionalSize(screenSize, -25)),
                BackgroundColor3 = Color3.fromRGB(255, 215, 0), -- Gold/yellow color for codes
                BorderSizePixel = 0,
                ZIndex = 32
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 12)
                }),
                Gradient = e("UIGradient", {
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 230, 100)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 0))
                    },
                    Rotation = 45
                }),
                Stroke = e("UIStroke", {
                    Color = Color3.fromRGB(255, 255, 255),
                    Thickness = 3,
                    Transparency = 0.2
                }),
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
                    
                    CodesIcon = e("ImageLabel", {
                        Name = "CodesIcon",
                        Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 24), 0, ScreenUtils.getProportionalSize(screenSize, 24)),
                        Image = assets["vector-icon-pack-2/General/Codes/Codes Outline 256.png"] or "",
                        BackgroundTransparency = 1,
                        ScaleType = Enum.ScaleType.Fit,
                        ImageColor3 = Color3.fromRGB(255, 255, 255),
                        ZIndex = 34,
                        LayoutOrder = 1
                    }),
                    
                    TitleText = e("TextLabel", {
                        Name = "TitleText",
                        Size = UDim2.new(0, 0, 1, 0),
                        AutomaticSize = Enum.AutomaticSize.X,
                        Text = "Codes",
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = titleTextSize,
                        TextWrapped = false,
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
                Color = Color3.fromRGB(255, 215, 0), -- Gold/yellow stroke
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
            
            -- Close Button (matching RebirthPanel style)
            CloseButton = e("ImageButton", {
                Name = "CloseButton",
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 32), 0, ScreenUtils.getProportionalSize(screenSize, 32)),
                Position = UDim2.new(1, ScreenUtils.getProportionalSize(screenSize, -16), 0, ScreenUtils.getProportionalSize(screenSize, -16)),
                Image = assets["vector-icon-pack-2/UI/X Button/X Button Outline 256.png"] or "",
                ImageColor3 = Color3.fromRGB(255, 255, 255),
                ScaleType = Enum.ScaleType.Fit,
                BackgroundColor3 = Color3.fromRGB(255, 100, 100),
                BorderSizePixel = 0,
                ZIndex = 34,
                [React.Event.Activated] = onClose
            }, {
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
            
            -- Main Content
            MainContent = e("Frame", {
                Name = "MainContent",
                Size = UDim2.new(1, ScreenUtils.getProportionalSize(screenSize, -40), 1, ScreenUtils.getProportionalSize(screenSize, -80)),
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 20), 0, ScreenUtils.getProportionalSize(screenSize, 40)),
                BackgroundTransparency = 1,
                ZIndex = 31
            }, {
                -- Instructions
                Instructions = e("TextLabel", {
                    Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(screenSize, 30)),
                    Position = UDim2.new(0, 0, 0, ScreenUtils.getProportionalSize(screenSize, 10)),
                    Text = "Enter a code to redeem rewards!",
                    TextColor3 = Color3.fromRGB(100, 100, 100),
                    TextSize = normalTextSize,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 32
                }),
                
                -- Code input container
                InputContainer = e("Frame", {
                    Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(screenSize, 50)),
                    Position = UDim2.new(0.5, 0, 0, ScreenUtils.getProportionalSize(screenSize, 60)),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 0,
                    ZIndex = 32
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 12)
                    }),
                    Stroke = e("UIStroke", {
                        Color = Color3.fromRGB(200, 200, 200),
                        Thickness = 2,
                        Transparency = 0
                    }),
                    CodeInput = e("TextBox", {
                        Name = "CodeInput",
                        Size = UDim2.new(1, -20, 1, 0),
                        Position = UDim2.new(0, 10, 0, 0),
                        BackgroundTransparency = 1,
                        Text = codeInput,
                        PlaceholderText = "Enter code here...",
                        TextColor3 = Color3.fromRGB(0, 0, 0),
                        PlaceholderColor3 = Color3.fromRGB(150, 150, 150),
                        TextSize = normalTextSize,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ClearTextOnFocus = false,
                        ZIndex = 33,
                        [React.Change.Text] = function(rbx)
                            setCodeInput(rbx.Text)
                            -- Clear error message when typing
                            if errorMessage ~= "" then
                                setErrorMessage("")
                            end
                        end
                    })
                }),
                
                -- Submit button
                SubmitButton = e("TextButton", {
                    Name = "SubmitButton",
                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 180), 0, ScreenUtils.getProportionalSize(screenSize, 45)),
                    Position = UDim2.new(0.5, 0, 0, ScreenUtils.getProportionalSize(screenSize, 130)),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundColor3 = isRedeeming and Color3.fromRGB(150, 150, 150) or Color3.fromRGB(85, 200, 85),
                    Text = isRedeeming and "Redeeming..." or "Submit",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = buttonTextSize,
                    Font = Enum.Font.GothamBold,
                    BorderSizePixel = 0,
                    ZIndex = 32,
                    [React.Event.Activated] = handleSubmit
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 12)
                    }),
                    Gradient = e("UIGradient", {
                        Color = ColorSequence.new{
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 220, 100)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 180, 60))
                        },
                        Rotation = 90
                    }),
                    Stroke = e("UIStroke", {
                        Color = Color3.fromRGB(255, 255, 255),
                        Thickness = 2,
                        Transparency = 0.3
                    })
                }),
                
                -- Message display (error or success) - Dynamic sizing
                MessageLabel = (errorMessage ~= "" or successMessage ~= "") and e("Frame", {
                    Name = "MessageContainer",
                    Size = UDim2.new(1, -20, 0, 0), -- Height will be automatic
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Position = UDim2.new(0.5, 0, 0, ScreenUtils.getProportionalSize(screenSize, 190)),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundColor3 = errorMessage ~= "" and Color3.fromRGB(255, 240, 240) or Color3.fromRGB(240, 255, 240),
                    BackgroundTransparency = 0.3,
                    BorderSizePixel = 0,
                    ZIndex = 32
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 8)
                    }),
                    Stroke = e("UIStroke", {
                        Color = errorMessage ~= "" and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(85, 200, 85),
                        Thickness = 2,
                        Transparency = 0.2
                    }),
                    Padding = e("UIPadding", {
                        PaddingTop = UDim.new(0, 8),
                        PaddingBottom = UDim.new(0, 8),
                        PaddingLeft = UDim.new(0, 12),
                        PaddingRight = UDim.new(0, 12)
                    }),
                    MessageText = e("TextLabel", {
                        Name = "MessageText",
                        Size = UDim2.new(1, 0, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        Text = errorMessage ~= "" and errorMessage or successMessage,
                        TextColor3 = errorMessage ~= "" and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(50, 150, 50),
                        TextSize = normalTextSize * 0.85,
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextYAlignment = Enum.TextYAlignment.Top,
                        BackgroundTransparency = 1,
                        TextWrapped = true,
                        TextScaled = false,
                        ZIndex = 33
                    }, {
                        TextSizeConstraint = e("UITextSizeConstraint", {
                            MaxTextSize = normalTextSize * 0.85,
                            MinTextSize = math.max(10, normalTextSize * 0.6)
                        }),
                        TextStroke = e("UIStroke", {
                            Color = Color3.fromRGB(255, 255, 255),
                            Thickness = 1,
                            Transparency = 0.5
                        })
                    })
                }) or nil
            })
        })
    })
    })
end

return CodesPanel