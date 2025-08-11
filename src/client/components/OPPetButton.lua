-- OP Pet Purchase Button - Shows on screen with breathing animation
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.react)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local OPPetConfig = require(ReplicatedStorage.config.OPPetConfig)
local AnimationService = require(script.Parent.Parent.services.AnimationService)
local GradientUtils = require(ReplicatedStorage.utils.GradientUtils)

local player = Players.LocalPlayer

local function OPPetButton(props)
    -- Get the first OP pet as featured (Constellation King)
    local featuredOPPet = OPPetConfig.OPPets[1] -- Constellation King
    local devProductPrice, setDevProductPrice = React.useState("Loading...")
    local viewportRef = React.useRef()
    
    -- Animation references for cleanup
    local activeAnimations = React.useRef({})
    
    -- OP text animation state (like RightSideBar)
    local textRotation, setTextRotation = React.useState(0)
    local textScale, setTextScale = React.useState(1)
    local lastShakeTime = React.useRef(0)
    
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
    
    -- Setup simple animations (temporarily back to inline while fixing AnimationService)
    React.useEffect(function()
        local viewport = viewportRef.current
        local squiggle = squiggleRef.current
        
        -- Breathing animation for viewport using AnimationService
        if viewport then
            local breathingAnimation = AnimationService:CreateBreathingAnimation(viewport, {
                duration = 2,
                maxScale = 1.05 -- This should work now with the fixed AnimationService
            })
            activeAnimations.current.breathing = breathingAnimation
        end
        
        -- Spinning animation for background using AnimationService
        if squiggle then
            local spinAnimation = AnimationService:CreateSpinAnimation(squiggle, {
                duration = 8
            })
            activeAnimations.current.spin = spinAnimation
        end
        
        -- OP text shake animation using AnimationService with React callbacks
        local shakeAnimation = AnimationService:CreateReactShakeAnimation({
            interval = 3, -- Every 3 seconds like original
            growPhase = 0.1, -- 100ms grow phase like original
            shakePhase = 0.4, -- 400ms shake phase like original
            maxScale = 1.25, -- 1.25x size like original
            shakeIntensity = 20, -- 20 degrees rotation like original
            shakeFrequency = 25 -- 25 oscillations per second like original
        }, {
            onScaleChange = setTextScale,
            onRotationChange = setTextRotation
        })
        
        activeAnimations.current.opTextShake = shakeAnimation
        
        -- Cleanup function
        return function()
            for _, animation in pairs(activeAnimations.current) do
                if animation and animation.Stop then
                    animation:Stop()
                end
            end
            activeAnimations.current = {}
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
            RainbowGradient = GradientUtils.CreateReactGradient(GradientUtils.RAINBOW_DIAGONAL)
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
        
        -- "OP!" text at bottom with gradient and shake animation
        OPText = React.createElement("TextLabel", {
            Size = UDim2.new(0.8 * textScale, 0, 0.3 * textScale, 0), -- Apply React state scale animation
            Position = UDim2.new(0.5, 0, 0.85, 0), -- Moved to bottom
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Text = "OP!",
            TextColor3 = Color3.fromRGB(255, 255, 255), -- White base for gradient
            TextSize = math.floor(buttonSize * 0.35), -- Responsive text size
            TextStrokeTransparency = 0,
            TextStrokeColor3 = Color3.fromRGB(0, 0, 0), -- Black outline
            Font = Enum.Font.FredokaOne,
            TextScaled = true,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            Rotation = textRotation, -- Apply React state rotation animation
            ZIndex = 6,
        }, {
            -- Add UIStroke for thicker outline
            Stroke = React.createElement("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 2,
                Transparency = 0
            }),
            -- Gradient from dark orange-red to golden
            TextGradient = GradientUtils.CreateReactGradient(GradientUtils.OP_TEXT)
        }),
        
        
        -- Price container at top right
        PriceContainer = React.createElement("Frame", {
            Size = UDim2.new(0.9, 0, 0.2, 0),
            Position = UDim2.new(0.95, 0, 0.05, 0),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
            ZIndex = 7,
        }, {
            -- Robux icon (green to match price)
            RobuxIcon = React.createElement("ImageLabel", {
                Size = UDim2.new(0, math.floor(buttonSize * 0.15), 0, math.floor(buttonSize * 0.15)),
                Position = UDim2.new(1, -math.floor(buttonSize * 0.35), 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                Image = "rbxasset://textures/ui/common/robux.png",
                ImageColor3 = Color3.fromRGB(85, 255, 85), -- Green color to match price
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 8,
            }),
            -- Price text in green
            PriceText = React.createElement("TextLabel", {
                Size = UDim2.new(0, math.floor(buttonSize * 0.3), 1, 0),
                Position = UDim2.new(1, -math.floor(buttonSize * 0.15), 0, 0),
                BackgroundTransparency = 1,
                Text = devProductPrice,
                TextColor3 = Color3.fromRGB(85, 255, 85), -- Nice green color
                TextSize = math.floor(buttonSize * 0.12), -- Responsive text size
                TextStrokeTransparency = 0.5,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                Font = Enum.Font.FredokaOne,
                TextScaled = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 8,
            })
        })
    })
end

return OPPetButton