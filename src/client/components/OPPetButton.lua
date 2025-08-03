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
    
    -- Create pet model for viewport (copying PetInventoryUI method exactly)
    local function createPetModel()
        local petsFolder = ReplicatedStorage:FindFirstChild("Pets")
        if not petsFolder then return nil end
        
        local petModelTemplate = petsFolder:FindFirstChild(featuredOPPet.ModelName)
        if not petModelTemplate then return nil end
        
        local clonedModel = petModelTemplate:Clone()
        clonedModel.Name = "PetModel"
        
        -- Use same scaling and processing as PetInventoryUI
        local scaleFactor = 4.2 -- Same as PetInventoryUI for consistency
        
        for _, descendant in pairs(clonedModel:GetDescendants()) do
            if descendant:IsA("BasePart") then
                descendant.Size = descendant.Size * scaleFactor
                descendant.CanCollide = false
                descendant.Anchored = true -- Anchored for viewport
                descendant.Massless = true
                -- Make parts visible with original materials preserved (same as PetInventoryUI)
                descendant.Transparency = math.max(0, descendant.Transparency - 0.3) -- Reduce transparency
                -- Keep original material unless it's invisible (same as PetInventoryUI)
                if descendant.Material == Enum.Material.ForceField then
                    descendant.Material = Enum.Material.Plastic
                end
            end
        end
        
        -- Use 160 degrees rotation for showing faces correctly (same as PetInventoryUI)
        local rotationAngle = 160
        
        -- Move entire model to origin using MoveTo, then rotate all parts (same as PetInventoryUI)
        clonedModel:MoveTo(Vector3.new(0, 0, 0))
        
        -- Then apply rotation to each part around the origin (same as PetInventoryUI)
        for _, descendant in pairs(clonedModel:GetDescendants()) do
            if descendant:IsA("BasePart") then
                -- Rotate each part around the origin
                local rotationCFrame = CFrame.Angles(0, math.rad(rotationAngle), 0)
                local currentPos = descendant.Position
                local rotatedPos = rotationCFrame * currentPos
                descendant.Position = rotatedPos
                
                -- Also rotate the part's orientation
                descendant.CFrame = CFrame.new(rotatedPos) * rotationCFrame * (descendant.CFrame - descendant.Position)
            end
        end
        
        return clonedModel
    end
    
    -- Setup viewport camera (matching PetInventoryUI style)
    local function setupViewportCamera(viewportFrame, petModel)
        if not viewportFrame or not petModel then return end
        
        local camera = Instance.new("Camera")
        camera.CameraType = Enum.CameraType.Scriptable
        camera.Parent = viewportFrame
        viewportFrame.CurrentCamera = camera
        
        local modelCFrame, modelSize = petModel:GetBoundingBox()
        local maxSize = math.max(modelSize.X, modelSize.Y, modelSize.Z)
        
        -- Use same camera positioning as PetInventoryUI
        local distance = maxSize * 1.8 -- Good distance to see full model
        local cameraPosition = modelCFrame.Position + Vector3.new(distance * 0.7, distance * 0.4, distance * 0.7)
        
        -- Point camera at center of model
        camera.CFrame = CFrame.lookAt(cameraPosition, modelCFrame.Position)
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
                Size = UDim2.new(1.95, 0, 1.95, 0) -- Breathe between 1.9 and 1.95
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
    local buttonSize = math.min(screenSize.X * 0.18, screenSize.Y * 0.18) -- Made even bigger: 18% of smaller screen dimension
    local xPosition = screenSize.X * 0.8 - buttonSize -- 20% from right edge
    local yPosition = screenSize.Y * 0.2 -- 20% from top
    
    return React.createElement("TextButton", {
        Name = "OPPetButton",
        Size = UDim2.new(0, buttonSize, 0, buttonSize), -- Square button
        Position = UDim2.new(0, xPosition, 0, yPosition),
        BackgroundTransparency = 1, -- Transparent for custom design
        Text = "", -- No default text
        ZIndex = 50, -- High z-index to appear above other UI
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
            ZIndex = 48,
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
            Size = UDim2.new(1.9, 0, 1.9, 0), -- 2x bigger: 190% of button size!
            Position = UDim2.new(-0.45, 0, -0.45, 0), -- Centered with the larger size
            BackgroundTransparency = 1,
            ZIndex = 49,
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
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 52,
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
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 52,
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
            ZIndex = 52,
        }, {
            -- Robux icon
            RobuxIcon = React.createElement("ImageLabel", {
                Size = UDim2.new(0, 30, 0, 30), -- Much bigger icon
                Position = UDim2.new(0.5, -40, 0.5, -15),
                BackgroundTransparency = 1,
                Image = IconAssets.getIcon("CURRENCY", "ROBUX") or "rbxasset://textures/ui/Shell/Icons/Robux.png",
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 53,
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
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 53,
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