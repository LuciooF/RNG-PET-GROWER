local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages.react)
local e = React.createElement

-- Import ScreenUtils for responsive scaling
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local ClickOutsideWrapper = require(script.Parent.ClickOutsideWrapper)

local function DebugUI(props)
    local visible = props.visible or false
    local onClose = props.onClose or function() end
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    -- Responsive sizing using ScreenUtils
    local panelWidth = math.min(screenSize.X * 0.9, ScreenUtils.getProportionalSize(screenSize, 250))
    local panelHeight = math.min(screenSize.Y * 0.8, ScreenUtils.getProportionalSize(screenSize, 400))
    local titleTextSize = ScreenUtils.getProportionalTextSize(screenSize, 16)
    local buttonTextSize = ScreenUtils.getProportionalTextSize(screenSize, 14)
    local buttonHeight = math.max(44, ScreenUtils.getProportionalSize(screenSize, 40)) -- 44pt minimum for mobile
    local closeButtonSize = math.max(44, ScreenUtils.getProportionalSize(screenSize, 30))
    
    -- print("DebugUI component loaded")
    
    local function fireRemoteEvent(remoteName)
        local remotes = ReplicatedStorage:WaitForChild("Remotes")
        local remote = remotes:FindFirstChild(remoteName)
        if remote then
            remote:FireServer()
        end
    end
    
    -- Debug Panel (only render when visible, no toggle button)
    return e(ClickOutsideWrapper, {
        visible = visible,
        onClose = onClose
    }, {
        Container = e("Frame", {
        Name = "DebugUI",
        Size = UDim2.new(0, panelWidth, 0, panelHeight),
        Position = UDim2.new(0.5, -panelWidth/2, 0.5, -panelHeight/2),
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        BorderSizePixel = 0,
        ZIndex = 100
    }, {
        Corner = e("UICorner", {
            CornerRadius = UDim.new(0, 8)
        }),
        
        Stroke = e("UIStroke", {
            Color = Color3.fromRGB(255, 255, 255),
            Thickness = 2,
            Transparency = 0.5
        }),
        
        Title = e("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -closeButtonSize, 0, closeButtonSize),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = "DEBUG PANEL",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = titleTextSize,
            Font = Enum.Font.SourceSansBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 101
        }),
        
        CloseButton = e("TextButton", {
            Name = "CloseButton",
            Size = UDim2.new(0, closeButtonSize, 0, closeButtonSize),
            Position = UDim2.new(1, -closeButtonSize - 5, 0, 5),
            BackgroundColor3 = Color3.fromRGB(200, 50, 50),
            BorderSizePixel = 0,
            Text = "✕",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = titleTextSize,
            Font = Enum.Font.SourceSansBold,
            ZIndex = 102,
            [React.Event.Activated] = onClose
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 6)
            })
        }),
        
        ButtonContainer = e("Frame", {
            Name = "ButtonContainer",
            Size = UDim2.new(1, -20, 1, -closeButtonSize - 10),
            Position = UDim2.new(0, 10, 0, closeButtonSize + 5),
            BackgroundTransparency = 1,
            ZIndex = 101
        }, {
            Layout = e("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                Padding = UDim.new(0, 10),
                SortOrder = Enum.SortOrder.LayoutOrder
            }),
            
            AddMoneyButton = e("TextButton", {
                Name = "AddMoneyButton",
                Size = UDim2.new(1, 0, 0, buttonHeight),
                BackgroundColor3 = Color3.fromRGB(0, 150, 0),
                BorderSizePixel = 0,
                Text = "Add 1000 Money",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = buttonTextSize,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 102,
                LayoutOrder = 1,
                [React.Event.MouseButton1Click] = function()
                    fireRemoteEvent("DebugAddMoney")
                end
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 6)
                })
            }),
            
            AddDiamondsButton = e("TextButton", {
                Name = "AddDiamondsButton",
                Size = UDim2.new(1, 0, 0, buttonHeight),
                BackgroundColor3 = Color3.fromRGB(0, 150, 255),
                BorderSizePixel = 0,
                Text = "Add 1000 Diamonds",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = buttonTextSize,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 102,
                LayoutOrder = 2,
                [React.Event.MouseButton1Click] = function()
                    fireRemoteEvent("DebugAddDiamonds")
                end
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 6)
                })
            }),
            
            AddRebirthButton = e("TextButton", {
                Name = "AddRebirthButton",
                Size = UDim2.new(1, 0, 0, buttonHeight),
                BackgroundColor3 = Color3.fromRGB(255, 150, 0),
                BorderSizePixel = 0,
                Text = "Add 1 Rebirth",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = buttonTextSize,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 102,
                LayoutOrder = 3,
                [React.Event.MouseButton1Click] = function()
                    fireRemoteEvent("DebugAddRebirths")
                end
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 6)
                })
            }),
            
            ResetDataButton = e("TextButton", {
                Name = "ResetDataButton",
                Size = UDim2.new(1, 0, 0, buttonHeight),
                BackgroundColor3 = Color3.fromRGB(200, 50, 50),
                BorderSizePixel = 0,
                Text = "RESET DATA",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = buttonTextSize,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 102,
                LayoutOrder = 4,
                [React.Event.MouseButton1Click] = function()
                    fireRemoteEvent("DebugResetData")
                end
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 6)
                })
            }),
            
            BuyProductionPlotButton = e("TextButton", {
                Name = "BuyProductionPlotButton",
                Size = UDim2.new(1, 0, 0, buttonHeight),
                BackgroundColor3 = Color3.fromRGB(100, 200, 255),
                BorderSizePixel = 0,
                Text = "Buy Production Plot 1",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = buttonTextSize,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 102,
                LayoutOrder = 5,
                [React.Event.MouseButton1Click] = function()
                    fireRemoteEvent("DebugBuyProductionPlot")
                end
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 6)
                })
            }),
            
            CheckAssetsButton = e("TextButton", {
                Name = "CheckAssetsButton",
                Size = UDim2.new(1, 0, 0, buttonHeight),
                BackgroundColor3 = Color3.fromRGB(150, 100, 255),
                BorderSizePixel = 0,
                Text = "Check Asset Status",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = buttonTextSize,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 102,
                LayoutOrder = 6,
                [React.Event.MouseButton1Click] = function()
                    -- Check asset system status
                    local assets = require(ReplicatedStorage.assets)
                    if assets._debug then
                        print("=== ASSET DEBUG INFO ===")
                        assets._debug.printStatus()
                        
                        -- Test critical UI assets that actually exist
                        local testAssets = {
                            "vector-icon-pack-2/General/Pet 2/Pet 2 Outline 256.png",
                            "vector-icon-pack-2/General/Shop/Shop Outline 256.png", 
                            "vector-icon-pack-2/General/Rebirth/Rebirth Outline 256.png",
                            "vector-icon-pack-2/Currency/Gem/Gem Blue Outline 256.png",
                            "vector-icon-pack-2/Currency/Cash/Cash Outline 256.png",
                            "vector-icon-pack-2/UI/X Button/X Button Outline 256.png"
                        }
                        
                        print("Testing UI assets:")
                        for _, assetPath in ipairs(testAssets) do
                            local assetId = assets[assetPath]
                            if assetId then
                                print("✓", assetPath, "=", assetId)
                            else
                                print("✗ MISSING:", assetPath)
                            end
                        end
                        print("========================")
                    else
                        warn("Asset debug functions not available!")
                    end
                end
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 6)
                })
            }),
            
            TestRewardButton = e("TextButton", {
                Name = "TestRewardButton",
                Size = UDim2.new(1, 0, 0, buttonHeight),
                BackgroundColor3 = Color3.fromRGB(255, 200, 100),
                BorderSizePixel = 0,
                Text = "Test Reward",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = buttonTextSize,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 102,
                LayoutOrder = 7,
                [React.Event.MouseButton1Click] = function()
                    -- Test different reward types
                    local RewardsService = require(script.Parent.Parent.RewardsService)
                    
                    -- Create a test reward queue with different types
                    local testRewards = {
                        {
                            type = "money",
                            amount = 5000,
                            title = "Money Reward!",
                            description = "You earned $5,000 from testing!",
                            iconAsset = "vector-icon-pack-2/Currency/Cash/Cash Outline 256.png",
                            color = Color3.fromRGB(85, 170, 85),
                            rarity = "common"
                        },
                        {
                            type = "pet",
                            petType = "Cat",
                            petName = "Golden Cat",
                            title = "New Pet!",
                            description = "You got a rare Golden Cat!",
                            iconAsset = "vector-icon-pack-2/General/Pet 2/Pet 2 Outline 256.png",
                            color = Color3.fromRGB(255, 200, 100),
                            rarity = "legendary"
                        },
                        {
                            type = "boost",
                            boostType = "Money",
                            duration = 10,
                            multiplier = 2,
                            title = "Boost Activated!",
                            description = "2x Money boost for 10 minutes!",
                            iconAsset = "vector-icon-pack-2/Currency/Gem/Gem Blue Outline 256.png",
                            color = Color3.fromRGB(100, 150, 255),
                            rarity = "rare"
                        }
                    }
                    
                    -- Show a random reward
                    local randomReward = testRewards[math.random(1, #testRewards)]
                    RewardsService.showReward(randomReward)
                    
                    print("Debug: Showing test reward:", randomReward.title)
                end
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 6)
                })
            }),
            
            TestCodesButton = e("TextButton", {
                Name = "TestCodesButton",
                Size = UDim2.new(1, 0, 0, buttonHeight),
                BackgroundColor3 = Color3.fromRGB(255, 215, 0),
                BorderSizePixel = 0,
                Text = "Test Codes",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = buttonTextSize,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 102,
                LayoutOrder = 8,
                [React.Event.MouseButton1Click] = function()
                    -- Test the codes system by simulating redemption responses
                    local CodesService = require(script.Parent.Parent.CodesService)
                    local RewardsService = require(script.Parent.Parent.RewardsService)
                    
                    -- Simulate different code redemption scenarios
                    local testCodes = {
                        {
                            code = "WELCOME",
                            success = true,
                            responseData = {
                                code = "WELCOME",
                                rewardType = "diamonds",
                                rewardAmount = 500
                            }
                        },
                        {
                            code = "TODAY",
                            success = true,
                            responseData = {
                                code = "TODAY",
                                rewardType = "diamonds",
                                rewardAmount = 500
                            }
                        }
                    }
                    
                    -- Pick a random test code
                    local testCode = testCodes[math.random(1, #testCodes)]
                    
                    -- Simulate the reward directly
                    if testCode.success and testCode.responseData.rewardType == "diamonds" then
                        RewardsService.showReward({
                            type = "diamonds",
                            amount = testCode.responseData.rewardAmount,
                            title = "Diamonds Received!",
                            description = "Code '" .. testCode.responseData.code .. "' gave you " .. testCode.responseData.rewardAmount .. " diamonds!",
                            iconAsset = "vector-icon-pack-2/Currency/Gem/Gem Blue Outline 256.png",
                            color = Color3.fromRGB(100, 150, 255),
                            rarity = "rare"
                        })
                    end
                    
                    print("Debug: Testing code redemption:", testCode.code)
                end
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 6)
                })
            }),
            
            Instructions = e("TextLabel", {
                Name = "Instructions",
                Size = UDim2.new(1, 0, 0, 60),
                BackgroundTransparency = 1,
                Text = "Click the shop button\nto toggle this panel.",
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextSize = 12,
                Font = Enum.Font.SourceSans,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextWrapped = true,
                ZIndex = 101,
                LayoutOrder = 5
            })
        })
    })
    })
end

return DebugUI