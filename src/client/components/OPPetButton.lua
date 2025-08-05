-- OP Pet Purchase Button - Shows on screen with breathing animation
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local React = require(ReplicatedStorage.Packages.react)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local OPPetConfig = require(ReplicatedStorage.config.OPPetConfig)

local player = Players.LocalPlayer

local function OPPetButton(props)
    -- Get the first OP pet as featured (Constellation King)
    local featuredOPPet = OPPetConfig.OPPets[1] -- Constellation King
    local devProductPrice, setDevProductPrice = React.useState("Loading...")
    local viewportRef = React.useRef()
    
    -- Fetch dynamic price from MarketplaceService
    React.useEffect(function()
        if featuredOPPet.DevProductId then
            task.spawn(function()
                local success, result = pcall(function()
                    return MarketplaceService:GetProductInfo(featuredOPPet.DevProductId, Enum.InfoType.Product)
                end)
                
                if success and result and result.PriceInRobux then
                    setDevProductPrice(tostring(result.PriceInRobux))
                else
                    setDevProductPrice("N/A")
                end
            end)
        end
    end, {})
    
    -- Handle purchase click
    local function handlePurchase()
        print("OPPetButton: Purchase clicked for", featuredOPPet.Name)
        local purchaseOPPetRemote = ReplicatedStorage:FindFirstChild("PurchaseOPPet")
        if purchaseOPPetRemote then
            print("OPPetButton: Firing server with pet name:", featuredOPPet.Name)
            purchaseOPPetRemote:FireServer(featuredOPPet.Name)
        else
            warn("OPPetButton: PurchaseOPPet remote not found")
        end
    end
    
    -- Create pet model for viewport (using same approach as PlaytimeRewardsPanel)
    local function createPetModel()
        local petsFolder = ReplicatedStorage:FindFirstChild("Pets")
        if not petsFolder then return nil end
        
        local petModelTemplate = petsFolder:FindFirstChild(featuredOPPet.ModelName)
        if not petModelTemplate then return nil end
        
        -- Clone model WITHOUT SCALING (Baby size = scale 1)
        local clonedModel = petModelTemplate:Clone()
        clonedModel.Name = "PetModel"
        
        -- Prepare model
        for _, part in pairs(clonedModel:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
                part.Anchored = true
                part.Massless = true
            end
        end
        
        -- Position and rotate model using PivetTo (180 degrees the other way)
        clonedModel:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(20), math.rad(-60), 0)) -- 180 degrees opposite of 120
        
        return clonedModel
    end
    
    -- Setup viewport camera (highest quality possible)
    local function setupViewportCamera(viewportFrame, petModel)
        if not viewportFrame or not petModel then return end
        
        -- Setup camera for MAXIMUM quality with proper sizing
        local camera = Instance.new("Camera")
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = CFrame.new(0.1, -0.15, 15) -- Back to previous distance
        camera.FieldOfView = 70 -- Back to previous FOV to show whole pet
        camera.Parent = viewportFrame
        viewportFrame.CurrentCamera = camera
        
        -- Set lighting with reduced brightness
        viewportFrame.LightDirection = Vector3.new(0, -0.1, -1).Unit
        viewportFrame.Ambient = Color3.fromRGB(180, 180, 180) -- Reduced from 255 to 180 for less brightness
        viewportFrame.LightColor = Color3.fromRGB(220, 220, 220) -- Reduced from 255 to 220
    end
    
    -- Animation refs
    local squiggleRef = React.useRef()
    
    -- Start breathing, spinning, and viewport rotation animations
    React.useEffect(function()
        local viewport = viewportRef.current
        local squiggle = squiggleRef.current
        
        local cleanupFunctions = {}
        
        -- Breathing animation for viewport
        if viewport then
            local breathingInfo = TweenInfo.new(
                2, -- Duration
                Enum.EasingStyle.Sine,
                Enum.EasingDirection.InOut,
                -1, -- Repeat infinitely
                true -- Reverse
            )
            
            local breathingTween = TweenService:Create(viewport, breathingInfo, {
                Size = UDim2.new(1.45, 0, 1.45, 0) -- Breathe between 1.4 and 1.45
            })
            
            breathingTween:Play()
            table.insert(cleanupFunctions, function() breathingTween:Cancel() end)
        end
        
        -- Spinning animation for background
        if squiggle then
            local spinningInfo = TweenInfo.new(
                8, -- 8 second rotation
                Enum.EasingStyle.Linear,
                Enum.EasingDirection.InOut,
                -1, -- Repeat infinitely
                false -- No reverse
            )
            
            local spinningTween = TweenService:Create(squiggle, spinningInfo, {
                Rotation = 360
            })
            
            spinningTween:Play()
            
            -- Reset rotation when complete to avoid accumulation
            spinningTween.Completed:Connect(function()
                if squiggle and squiggle.Parent then
                    squiggle.Rotation = 0
                end
            end)
            
            table.insert(cleanupFunctions, function() spinningTween:Cancel() end)
        end
        
        return function()
            for _, cleanup in ipairs(cleanupFunctions) do
                cleanup()
            end
        end
    end, {})
    
    -- Calculate responsive size and position (20% from edges)
    local screenSize = ScreenUtils.getScreenSize()
    local buttonSize = math.min(screenSize.X * 0.18, screenSize.Y * 0.18) -- Back to 18% for original button size
    local xPosition = screenSize.X * 0.8 - buttonSize -- 20% from right edge
    local yPosition = screenSize.Y * 0.2 -- 20% from top
    
    return React.createElement("TextButton", {
        Name = "OPPetButton",
        Size = UDim2.new(0, buttonSize, 0, buttonSize), -- Square button
        Position = UDim2.new(0, xPosition, 0, yPosition),
        BackgroundTransparency = 1, -- Transparent for custom design
        Text = "", -- No default text
        ZIndex = 5, -- Low z-index to stay behind panel UIs
        [React.Event.Activated] = handlePurchase,
    }, {
        -- Just the spinning squiggle background (no white background or border)
        RainbowSquiggle = React.createElement("ImageLabel", {
            Size = UDim2.new(1, 0, 1, 0), -- Full button size
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = IconAssets.getIcon("UI", "SQUIGGLE"),
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            ImageTransparency = 0.2,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 3,
            ref = squiggleRef, -- For spinning animation
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0.5, 0) -- Circular clipping
            }),
            -- Rainbow gradient on squiggle (matching gamepass UI)
            RainbowGradient = React.createElement("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),     -- Red
                    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 165, 0)), -- Orange
                    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)), -- Yellow
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),   -- Green
                    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),  -- Blue
                    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)), -- Indigo
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 0, 211))    -- Violet
                }),
                Rotation = 45
            })
        }),
        
        -- Pet viewport with breathing animation (made 2x bigger!)
        PetViewport = React.createElement("ViewportFrame", {
            Name = "PetViewport",
            Size = UDim2.new(1.4, 0, 1.4, 0), -- Reduced from 1.9 to 1.4 - smaller pet
            Position = UDim2.new(-0.2, 0, -0.2, 0), -- Adjusted position for smaller size
            BackgroundTransparency = 1,
            ZIndex = 4,
            ref = viewportRef,
            
            [React.Event.AncestryChanged] = function(rbx)
                if rbx.Parent then
                    -- Create pet model
                    task.spawn(function()
                        task.wait(0.1)
                        local petModel = createPetModel()
                        if petModel then
                            petModel.Parent = rbx
                            setupViewportCamera(rbx, petModel)
                        end
                    end)
                end
            end
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0.5, 0) -- Circular viewport
            })
        }),
        
        -- Title text overlaying the top of the button (MUCH bigger and nicer)
        TitleText = React.createElement("TextLabel", {
            Size = UDim2.new(0, buttonSize + 100, 0, 50), -- Much wider and taller
            Position = UDim2.new(0, -50, 0, -10), -- Overlaying top of button
            BackgroundTransparency = 1,
            Text = "[OP] Constellation King",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = ScreenUtils.TEXT_SIZES.HEADER() + 8, -- MUCH bigger text
            TextStrokeTransparency = 0,
            TextStrokeColor3 = Color3.fromRGB(0, 0, 0), -- Black outline for visibility
            Font = Enum.Font.FredokaOne,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 7,
        }, {
            -- Rainbow gradient for title text
            TitleGradient = React.createElement("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),     -- Red
                    ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 127, 0)), -- Orange
                    ColorSequenceKeypoint.new(0.32, Color3.fromRGB(255, 255, 0)), -- Yellow  
                    ColorSequenceKeypoint.new(0.48, Color3.fromRGB(0, 255, 0)),   -- Green
                    ColorSequenceKeypoint.new(0.64, Color3.fromRGB(0, 255, 255)), -- Cyan
                    ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0, 0, 255)),   -- Blue
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255))    -- Magenta
                }),
                Rotation = 0 -- Horizontal gradient
            })
        }),
        
        -- Boost text overlaying the bottom of the button (MUCH bigger)
        BoostText = React.createElement("TextLabel", {
            Size = UDim2.new(0, buttonSize + 80, 0, 40), -- Much bigger
            Position = UDim2.new(0, -40, 1, -30), -- Overlaying bottom of button
            BackgroundTransparency = 1,
            Text = "(100K Boost)",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = ScreenUtils.TEXT_SIZES.LARGE() + 6, -- MUCH bigger text
            TextStrokeTransparency = 0,
            TextStrokeColor3 = Color3.fromRGB(0, 0, 0), -- Black outline for visibility
            Font = Enum.Font.FredokaOne,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 7,
        }, {
            -- Rainbow gradient for boost text
            BoostGradient = React.createElement("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),     -- Red
                    ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 127, 0)), -- Orange
                    ColorSequenceKeypoint.new(0.32, Color3.fromRGB(255, 255, 0)), -- Yellow  
                    ColorSequenceKeypoint.new(0.48, Color3.fromRGB(0, 255, 0)),   -- Green
                    ColorSequenceKeypoint.new(0.64, Color3.fromRGB(0, 255, 255)), -- Cyan
                    ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0, 0, 255)),   -- Blue
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255))    -- Magenta
                }),
                Rotation = 0 -- Horizontal gradient
            })
        }),
        
        -- Price label container (MUCH bigger and nicer)
        PriceContainer = React.createElement("Frame", {
            Size = UDim2.new(0, buttonSize + 60, 0, 35), -- Much bigger
            Position = UDim2.new(0, -30, 1, 15), -- Just below button
            BackgroundTransparency = 1,
            ZIndex = 7,
        }, {
            -- Robux icon
            RobuxIcon = React.createElement("ImageLabel", {
                Size = UDim2.new(0, 30, 0, 30), -- Much bigger icon
                Position = UDim2.new(0.5, -40, 0.5, -15),
                BackgroundTransparency = 1,
                Image = IconAssets.getIcon("CURRENCY", "ROBUX") or "rbxasset://textures/ui/Shell/Icons/Robux.png",
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 8,
            }),
            -- Price text
            PriceText = React.createElement("TextLabel", {
                Size = UDim2.new(0, 80, 1, 0), -- Much bigger
                Position = UDim2.new(0.5, -10, 0, 0),
                BackgroundTransparency = 1,
                Text = devProductPrice,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = ScreenUtils.TEXT_SIZES.LARGE() + 4, -- MUCH bigger text
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0), -- Black outline for visibility
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 8,
            }, {
                -- Rainbow gradient for price text
                PriceGradient = React.createElement("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),     -- Red
                        ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 127, 0)), -- Orange
                        ColorSequenceKeypoint.new(0.32, Color3.fromRGB(255, 255, 0)), -- Yellow  
                        ColorSequenceKeypoint.new(0.48, Color3.fromRGB(0, 255, 0)),   -- Green
                        ColorSequenceKeypoint.new(0.64, Color3.fromRGB(0, 255, 255)), -- Cyan
                        ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0, 0, 255)),   -- Blue
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255))    -- Magenta
                    }),
                    Rotation = 0 -- Horizontal gradient
                })
            })
        })
    })
end

return OPPetButton