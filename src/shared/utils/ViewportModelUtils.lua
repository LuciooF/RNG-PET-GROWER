-- ViewportModelUtils - High quality model rendering for ViewportFrames
local ViewportModelUtils = {}

-- Get scaled model using modern ScaleTo method
function ViewportModelUtils.getScaledModel(model, goalHeight)
    goalHeight = goalHeight or 8 -- Default height
    
    local newModel = model:Clone()
    newModel.Name = "ViewportModel"
    
    -- Ensure model has a PrimaryPart
    if not newModel.PrimaryPart then
        -- Find the largest part to use as primary
        local largestPart = nil
        local largestSize = 0
        
        for _, part in pairs(newModel:GetDescendants()) do
            if part:IsA("BasePart") then
                local size = part.Size.X * part.Size.Y * part.Size.Z
                if size > largestSize then
                    largestSize = size
                    largestPart = part
                end
            end
        end
        
        if largestPart then
            newModel.PrimaryPart = largestPart
        else
            warn("ViewportModelUtils: No suitable PrimaryPart found for model")
            return newModel
        end
    end
    
    -- Calculate scale based on PrimaryPart height
    local currentHeight = newModel.PrimaryPart.Size.Y
    local scale = goalHeight / currentHeight
    
    -- Use ScaleTo for proper model scaling (preserves proportions better)
    newModel:ScaleTo(newModel:GetScale() * scale)
    
    return newModel
end

-- Setup high quality viewport camera
function ViewportModelUtils.setupCamera(viewportFrame, model, options)
    options = options or {}
    
    -- Create high quality camera
    local camera = Instance.new("Camera")
    camera.CameraType = Enum.CameraType.Scriptable
    camera.FieldOfView = options.fieldOfView or 40 -- Lower FOV reduces distortion
    camera.Parent = viewportFrame
    viewportFrame.CurrentCamera = camera
    
    -- Get model bounds
    local modelCFrame, modelSize = model:GetBoundingBox()
    local maxSize = math.max(modelSize.X, modelSize.Y, modelSize.Z)
    
    -- Calculate camera distance
    local distanceMultiplier = options.distanceMultiplier or 2.5
    local distance = maxSize * distanceMultiplier
    
    -- Camera angle (default: slightly above and to the side)
    local angleX = options.angleX or 0.5
    local angleY = options.angleY or 0.3
    local angleZ = options.angleZ or 1
    
    local cameraPosition = modelCFrame.Position + Vector3.new(
        distance * angleX,
        distance * angleY,
        distance * angleZ
    )
    
    camera.CFrame = CFrame.lookAt(cameraPosition, modelCFrame.Position)
    
    -- Setup viewport lighting for better quality
    viewportFrame.Ambient = options.ambient or Color3.fromRGB(200, 200, 200)
    viewportFrame.LightColor = options.lightColor or Color3.fromRGB(255, 255, 255)
    viewportFrame.LightDirection = options.lightDirection or Vector3.new(-1, -1, -1)
    
    return camera
end

-- Prepare model for viewport (anchoring, collision, etc)
function ViewportModelUtils.prepareModelForViewport(model)
    for _, descendant in pairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.CanCollide = false
            descendant.Anchored = true
            descendant.Massless = true
            -- Keep original transparency and materials for quality
        end
    end
end

-- Full setup function for easy use
function ViewportModelUtils.setupViewportModel(viewportFrame, modelTemplate, options)
    options = options or {}
    
    -- Clone model (don't scale if using far camera approach)
    local model
    if options.useScaling ~= false then
        model = ViewportModelUtils.getScaledModel(modelTemplate, options.goalHeight)
    else
        model = modelTemplate:Clone()
        model.Name = "ViewportModel"
    end
    
    -- Prepare for viewport
    ViewportModelUtils.prepareModelForViewport(model)
    
    -- Use PivotTo for better positioning (like the reference code)
    local baseCFrame = CFrame.new(0, 0, 0)
    local rotationCFrame = CFrame.Angles(
        math.rad(options.rotationX or 20), -- Tilt down slightly
        math.rad(options.rotationY or 30), -- Turn to side
        math.rad(options.rotationZ or 0)
    )
    model:PivotTo(baseCFrame * rotationCFrame)
    
    -- Parent to viewport
    model.Parent = viewportFrame
    
    -- Setup camera
    local camera = ViewportModelUtils.setupCamera(viewportFrame, model, options)
    
    return model, camera
end

-- Alternative setup using far camera (like reference code)
function ViewportModelUtils.setupFarCamera(viewportFrame, modelTemplate, cameraDistance)
    -- Clone model without scaling
    local model = modelTemplate:Clone()
    model.Name = "ViewportModel"
    
    -- Prepare for viewport
    ViewportModelUtils.prepareModelForViewport(model)
    
    -- Position and rotate model like reference
    model:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(20), math.rad(30), 0))
    
    -- Parent to viewport
    model.Parent = viewportFrame
    
    -- Get model size to adjust camera distance
    local modelCFrame, modelSize = model:GetBoundingBox()
    local maxSize = math.max(modelSize.X, modelSize.Y, modelSize.Z)
    
    -- Adjust camera distance based on model size (default 180 might be too far for some models)
    local distance = cameraDistance or (maxSize * 8) -- Adjust multiplier as needed
    
    -- Create camera with reference-like settings but adjusted distance
    local camera = Instance.new("Camera")
    camera.CameraType = Enum.CameraType.Scriptable
    camera.CFrame = CFrame.new(0.1, -0.15, distance) -- Adjusted distance
    camera.FieldOfView = 1 -- Extremely low FOV for orthographic-like view
    camera.Parent = viewportFrame
    viewportFrame.CurrentCamera = camera
    
    -- Set lighting like reference
    viewportFrame.LightDirection = Vector3.new(0, -0.1, -1).Unit
    viewportFrame.Ambient = Color3.fromRGB(255, 255, 255) -- Full bright
    viewportFrame.LightColor = Color3.fromRGB(255, 255, 255)
    
    return model, camera
end

return ViewportModelUtils