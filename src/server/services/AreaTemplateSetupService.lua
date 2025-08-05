-- AreaTemplateSetupService - Pre-creates static GUIs in AreaTemplate for performance
-- This eliminates the need to create identical GUIs for each of the 6 player areas

local Workspace = game:GetService("Workspace")

local AreaTemplateSetupService = {}
AreaTemplateSetupService.__index = AreaTemplateSetupService

function AreaTemplateSetupService:Initialize()
    -- Wait for AreaTemplate to exist
    local areaTemplate = Workspace:WaitForChild("AreaTemplate", 10)
    if not areaTemplate then
        warn("AreaTemplateSetupService: AreaTemplate not found in Workspace")
        return
    end
    
    -- Setup static GUIs in AreaTemplate
    
    -- Pre-create all door level/number GUIs
    self:CreateDoorGUIs(areaTemplate)
    
    -- Pre-create all tube number GUIs
    self:CreateTubeGUIs(areaTemplate)
    
    -- Pre-create instruction GUIs for buttons
    self:CreateInstructionGUIs(areaTemplate)
    
    -- Pre-create gamepass button GUIs (ownership status added later)
    self:CreateGamepassButtonGUIs(areaTemplate)
    
    -- VIP button now uses standard gamepass GUI system (handled above)
    
    -- Static GUI setup complete
end

function AreaTemplateSetupService:CreateDoorGUIs(areaTemplate)
    -- Create door label GUIs for all levels and doors
    local totalDoors = 0
    for level = 1, 7 do
        local levelFolder = areaTemplate:FindFirstChild("Level" .. level)
        if levelFolder then
            local doorsFolder = levelFolder:FindFirstChild("Level" .. level .. "Doors")
            if doorsFolder then
                for _, door in pairs(doorsFolder:GetChildren()) do
                    local doorNumber = tonumber(door.Name:match("Door(%d+)"))
                    if doorNumber then
                        self:CreateDoorSurfaceGui(door, level, doorNumber)
                        totalDoors = totalDoors + 1
                    end
                end
            end
        end
    end
    -- Created door GUIs
end

function AreaTemplateSetupService:CreateDoorSurfaceGui(door, level, doorNumber)
    -- Find the main part of the door to attach GUI to
    local targetPart = self:FindDoorTargetPart(door)
    if not targetPart then
        return
    end
    
    -- Skip if GUI already exists
    if targetPart:FindFirstChild("DoorLabelGui_Left") then
        return
    end
    
    -- Debug: Print what we're attaching to
    -- Attaching door GUI
    
    -- Create SurfaceGui on Left face only
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Name = "DoorLabelGui_Left"
    surfaceGui.Face = Enum.NormalId.Left
    surfaceGui.LightInfluence = 0
    surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surfaceGui.PixelsPerStud = 51 -- Slightly different to avoid z-fighting
    surfaceGui.CanvasSize = Vector2.new(400, 400) -- Explicit canvas size
    surfaceGui.Parent = targetPart
    
    -- Create text label (no background frame)
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "DoorLabel"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "Level " .. level .. "\n\nDoor " .. doorNumber
    textLabel.TextColor3 = Color3.fromRGB(255, 165, 0) -- Orange - visible on both red and green
    textLabel.TextSize = 72 -- Larger text size
    textLabel.Font = Enum.Font.FredokaOne
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.Rotation = 270 -- Rotate 270 degrees to make text horizontal and right-side up
    textLabel.ZIndex = 2 -- Higher ZIndex to appear in front of lock/unlock icons
    textLabel.Parent = surfaceGui
end

function AreaTemplateSetupService:FindDoorTargetPart(door)
    local targetPart = nil
    
    if door:IsA("Model") then
        -- Look for the main door part
        for _, part in pairs(door:GetDescendants()) do
            if part:IsA("BasePart") and (part.Name:lower():find("door") or part.Name:lower():find("main") or part.Size.Y > 5) then
                targetPart = part
                break
            end
        end
        -- Fallback to first BasePart if no specific part found
        if not targetPart then
            for _, part in pairs(door:GetDescendants()) do
                if part:IsA("BasePart") then
                    targetPart = part
                    break
                end
            end
        end
    elseif door:IsA("BasePart") then
        targetPart = door
    end
    
    return targetPart
end

function AreaTemplateSetupService:CreateTubeGUIs(areaTemplate)
    -- Find tubes folder
    local tubesFolder = areaTemplate:FindFirstChild("Tubes")
    if not tubesFolder then
        return
    end
    
    local innerTubesFolder = tubesFolder:FindFirstChild("Tubes")
    if not innerTubesFolder then
        return
    end
    
    -- Create tube number GUIs
    for i = 1, 10 do -- Assuming up to 10 tubes
        local tubePlot = innerTubesFolder:FindFirstChild("Tube" .. i)
        if tubePlot then
            self:CreateTubeNumberSurfaceGui(tubePlot, i)
        end
    end
end

function AreaTemplateSetupService:CreateTubeNumberSurfaceGui(tubePlot, tubePlotNumber)
    -- Find the correct part to attach GUI to
    local targetPart = nil
    if tubePlot:IsA("Model") then
        local cube = tubePlot:FindFirstChild("Cube.009")
        if cube and cube:IsA("BasePart") then
            targetPart = cube
        end
    elseif tubePlot:IsA("BasePart") then
        targetPart = tubePlot
    end
    
    if not targetPart then
        return
    end
    
    -- Skip if GUI already exists
    if targetPart:FindFirstChild("TubeNumberSurfaceGui") then
        return
    end
    
    -- Create SurfaceGui on the tube plot
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Name = "TubeNumberSurfaceGui"
    surfaceGui.Face = Enum.NormalId.Top
    surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surfaceGui.PixelsPerStud = 50
    surfaceGui.Parent = targetPart
    
    -- Create text label
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    
    -- Convert number to ordinal (1st, 2nd, 3rd, etc.)
    local ordinalText
    if tubePlotNumber == 1 then
        ordinalText = "\n\n1st Tube"
    elseif tubePlotNumber == 2 then
        ordinalText = "\n\n2nd Tube"
    elseif tubePlotNumber == 3 then
        ordinalText = "\n\n3rd Tube"
    else
        ordinalText = "\n\n" .. tubePlotNumber .. "th Tube"
    end
    
    textLabel.Text = ordinalText
    textLabel.Font = Enum.Font.FredokaOne
    textLabel.TextSize = 36
    textLabel.TextColor3 = Color3.fromRGB(255, 165, 0) -- Orange text
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.Rotation = 270  -- 270 degrees for TubePlots
    textLabel.Parent = surfaceGui
end

function AreaTemplateSetupService:CreateInstructionGUIs(areaTemplate)
    -- SendHeaven instruction GUI removed per user request
    
    -- Create Teleport instruction GUIs
    self:CreateTeleportInstructionGUIs(areaTemplate)
    
    -- Create Pet Mixer requirement GUIs
    self:CreatePetMixerRequirementGUIs(areaTemplate)
    
    -- Rebirth instruction GUI removed per user request
end


function AreaTemplateSetupService:CreateTeleportInstructionGUIs(areaTemplate)
    -- Find Teleport model
    local teleportModel = areaTemplate:FindFirstChild("Teleport", true)
    if not teleportModel then
        return
    end
    
    -- Find Cube.018 specifically (same as TeleportService)
    local teleportPart = teleportModel:FindFirstChild("Cube.018")
    if not teleportPart then
        warn("AreaTemplateSetupService: Cube.018 not found in Teleport model")
        return
    end
    
    -- Skip if GUI already exists
    if teleportPart:FindFirstChild("TeleportRequirementGui_Front") then
        return
    end
    
    -- Create requirement GUIs on multiple faces
    local faces = {Enum.NormalId.Front, Enum.NormalId.Top, Enum.NormalId.Back}
    
    for _, face in ipairs(faces) do
        local surfaceGui = Instance.new("SurfaceGui")
        surfaceGui.Name = "TeleportRequirementGui_" .. face.Name
        surfaceGui.Face = face
        surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        surfaceGui.PixelsPerStud = 100 -- Doubled from 50 to make it bigger
        surfaceGui.Parent = teleportPart
        
        -- Create container frame for tight icon + text layout (like plot GUIs)
        local container = Instance.new("Frame")
        container.Name = "Container"
        container.Size = UDim2.new(1, 0, 1, 0)
        container.BackgroundTransparency = 1
        container.Parent = surfaceGui
        
        -- Create rebirth icon (bigger, positioned like plot GUIs)
        local IconAssets = require(game.ReplicatedStorage.utils.IconAssets)
        local rebirthIcon = Instance.new("ImageLabel")
        rebirthIcon.Name = "RebirthIcon"
        rebirthIcon.Size = UDim2.new(0, 60, 0, 60) -- Bigger icon
        rebirthIcon.Position = UDim2.new(0.5, -120, 0.5, -30) -- Left side, centered vertically
        rebirthIcon.BackgroundTransparency = 1
        rebirthIcon.Image = IconAssets.getIcon("UI", "REBIRTH")
        rebirthIcon.ScaleType = Enum.ScaleType.Fit
        rebirthIcon.Parent = container
        
        -- Create requirement text label (positioned right next to icon like plot GUIs)
        local requirementLabel = Instance.new("TextLabel")
        requirementLabel.Name = "RequirementText"
        requirementLabel.Size = UDim2.new(0, 300, 1, 0) -- Wider for bigger text
        requirementLabel.Position = UDim2.new(0.5, -50, 0, 0) -- Right next to icon
        requirementLabel.BackgroundTransparency = 1 -- No background
        requirementLabel.Font = Enum.Font.FredokaOne
        requirementLabel.Text = "20 rebirths\nneeded" -- Split into two lines for bigger text
        requirementLabel.TextColor3 = Color3.fromRGB(255, 255, 0) -- Bright yellow for high contrast on purple
        requirementLabel.TextSize = 360 -- 10x bigger text size (was 36, now 360)
        requirementLabel.TextStrokeTransparency = 0
        requirementLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0) -- Black stroke for extra contrast
        requirementLabel.TextXAlignment = Enum.TextXAlignment.Left
        requirementLabel.TextYAlignment = Enum.TextYAlignment.Center
        requirementLabel.Parent = container
    end
end

function AreaTemplateSetupService:CreatePetMixerRequirementGUIs(areaTemplate)
    -- Find Pet Mixer Button (not the mixer itself)
    local mixerButton = areaTemplate:FindFirstChild("PetMixerButton", true)
    if not mixerButton then
        return
    end
    
    -- Find the button part to attach GUI to
    local buttonPart = nil
    if mixerButton:IsA("Model") then
        -- Look for the main button part
        for _, part in pairs(mixerButton:GetDescendants()) do
            if part:IsA("BasePart") then
                buttonPart = part
                break
            end
        end
    elseif mixerButton:IsA("BasePart") then
        buttonPart = mixerButton
    end
    
    if not buttonPart then
        return
    end
    
    -- Skip if GUI already exists
    if buttonPart:FindFirstChild("MixerRequirementGui_Front") then
        return
    end
    
    -- Create requirement GUIs on multiple faces
    local faces = {Enum.NormalId.Front, Enum.NormalId.Top, Enum.NormalId.Back}
    
    for _, face in ipairs(faces) do
        local surfaceGui = Instance.new("SurfaceGui")
        surfaceGui.Name = "MixerRequirementGui_" .. face.Name
        surfaceGui.Face = face
        surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        surfaceGui.PixelsPerStud = 100
        surfaceGui.Parent = buttonPart
        
        local requirementLabel = Instance.new("TextLabel")
        requirementLabel.Name = "RequirementText"
        requirementLabel.Size = UDim2.new(1, 0, 1, 0)
        requirementLabel.BackgroundTransparency = 1
        requirementLabel.Font = Enum.Font.FredokaOne
        requirementLabel.Text = "Need 3 rebirths\\nto use mixer!"
        requirementLabel.TextColor3 = Color3.fromRGB(0, 0, 0) -- Black text
        requirementLabel.TextSize = 48
        requirementLabel.TextStrokeTransparency = 0
        requirementLabel.TextStrokeColor3 = Color3.fromRGB(255, 255, 255) -- White stroke for contrast
        requirementLabel.TextXAlignment = Enum.TextXAlignment.Center
        requirementLabel.TextYAlignment = Enum.TextYAlignment.Center
        requirementLabel.Parent = surfaceGui
    end
end

function AreaTemplateSetupService:CreateRebirthInstructionGUI(areaTemplate)
    -- Find Rebirth button
    local rebirthButton = areaTemplate:FindFirstChild("RebirthButton", true)
    if not rebirthButton then
        return
    end
    
    -- Skip if GUI already exists
    if rebirthButton:FindFirstChild("RebirthInstructionBillboard") then
        return
    end
    
    -- Create BillboardGui for instruction
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "RebirthInstructionBillboard"
    billboardGui.Size = UDim2.new(0, 200, 0, 80)
    billboardGui.StudsOffset = Vector3.new(0, 6, 0)
    billboardGui.MaxDistance = 50
    billboardGui.Parent = rebirthButton
    
    -- Create instruction label
    local instructionLabel = Instance.new("TextLabel")
    instructionLabel.Size = UDim2.new(1, 0, 1, 0)
    instructionLabel.BackgroundTransparency = 1
    instructionLabel.Font = Enum.Font.FredokaOne
    instructionLabel.Text = "Rebirth here for\nmore power!"
    instructionLabel.TextColor3 = Color3.fromRGB(255, 200, 100) -- Orange/gold color
    instructionLabel.TextSize = 18
    instructionLabel.TextStrokeTransparency = 0
    instructionLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    instructionLabel.Parent = billboardGui
end

function AreaTemplateSetupService:CreateGamepassButtonGUIs(areaTemplate)
    -- Create base GUIs for all gamepass buttons with proper structure
    local gamepassButtons = {
        {name = "2xMoneyButton", text = "2x Money", description = "Double money from\nall pet sales!", color = Color3.fromRGB(85, 170, 85)},
        {name = "2xDiamondsButton", text = "2x Diamonds", description = "Double diamonds from\nall sources!", color = Color3.fromRGB(100, 149, 237)},
        {name = "2xHeavenSpeedButton", text = "2x Heaven Speed", description = "Process pets twice\nas fast in heaven!", color = Color3.fromRGB(255, 165, 0)},
        {name = "VIPButton", text = "VIP", description = "All gamepasses included\n+ exclusive benefits!", color = Color3.fromRGB(255, 215, 0)},
        {name = "PetMagnet", text = "Pet Magnet", description = "Auto-collect pet balls\nwithin range!", color = Color3.fromRGB(0, 162, 255)},
        {name = "AutoSendHeaven", text = "Auto Heaven", description = "Auto-send pets every 30s\nwith countdown timer!", color = Color3.fromRGB(255, 215, 0)}
    }
    
    for _, buttonConfig in ipairs(gamepassButtons) do
        self:CreateGamepassButtonGUI(areaTemplate, buttonConfig.name, buttonConfig.text, buttonConfig.description, buttonConfig.color)
    end
end

function AreaTemplateSetupService:CreateGamepassButtonGUI(areaTemplate, buttonName, buttonText, buttonDescription, buttonColor)
    -- Find the gamepass button
    local button = areaTemplate:FindFirstChild(buttonName, true)
    if not button then
        return
    end
    
    -- Skip if GUI already exists
    if button:FindFirstChild("GamepassBillboard") then
        return
    end
    
    -- Create BillboardGui for the button (better design)
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "GamepassBillboard"
    billboardGui.Size = UDim2.new(0, 160, 0, 100)  -- Larger to fit icon
    billboardGui.StudsOffset = Vector3.new(0, 5, 0)  -- Float 5 studs above
    billboardGui.MaxDistance = 80
    billboardGui.Parent = button
    
    -- Create icon image (will be updated with actual gamepass icon)
    local iconImage = Instance.new("ImageLabel")
    iconImage.Name = "IconImage"
    iconImage.Size = UDim2.new(0, 32, 0, 32)
    iconImage.Position = UDim2.new(0, 5, 0, 5)
    iconImage.BackgroundTransparency = 1
    iconImage.Image = "" -- Will be set dynamically
    iconImage.Parent = billboardGui
    
    -- Create title label (shows gamepass name)
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -40, 0, 20)
    titleLabel.Position = UDim2.new(0, 40, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.FredokaOne
    titleLabel.Text = buttonText
    titleLabel.TextColor3 = buttonColor
    titleLabel.TextSize = 16
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextYAlignment = Enum.TextYAlignment.Center
    titleLabel.Parent = billboardGui
    
    -- Create price label (shows gamepass price)
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Name = "PriceLabel"
    priceLabel.Size = UDim2.new(1, -40, 0, 20)
    priceLabel.Position = UDim2.new(0, 40, 0, 25)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Font = Enum.Font.Gotham
    priceLabel.Text = "Loading..." -- Will be set dynamically
    priceLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
    priceLabel.TextSize = 14
    priceLabel.TextStrokeTransparency = 0
    priceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    priceLabel.TextXAlignment = Enum.TextXAlignment.Left
    priceLabel.TextYAlignment = Enum.TextYAlignment.Center
    priceLabel.Parent = billboardGui
    
    -- Create description label (shows gamepass benefits)
    local descriptionLabel = Instance.new("TextLabel")
    descriptionLabel.Name = "DescriptionLabel"
    descriptionLabel.Size = UDim2.new(1, -5, 0, 50)
    descriptionLabel.Position = UDim2.new(0, 5, 0, 45)
    descriptionLabel.BackgroundTransparency = 1
    descriptionLabel.Font = Enum.Font.Gotham
    descriptionLabel.Text = buttonDescription
    descriptionLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    descriptionLabel.TextSize = 11
    descriptionLabel.TextWrapped = true
    descriptionLabel.TextStrokeTransparency = 0
    descriptionLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    descriptionLabel.TextXAlignment = Enum.TextXAlignment.Center
    descriptionLabel.TextYAlignment = Enum.TextYAlignment.Top
    descriptionLabel.Parent = billboardGui
    
    -- Add OWNED surface GUI by default (will be removed if player doesn't own it)
    self:CreateOwnedSurfaceGUI(button)
end

function AreaTemplateSetupService:CreateOwnedSurfaceGUI(button)
    -- Find the correct BasePart to attach the OWNED surface GUI to
    local targetPart = button
    if button:IsA("Model") then
        -- Look for Cylinder.007 specifically (the visible part)
        local preferredPart = button:FindFirstChild("Cylinder.007", true)
        if preferredPart then
            targetPart = preferredPart
        else
            -- Fallback to any BasePart
            for _, part in pairs(button:GetDescendants()) do
                if part:IsA("BasePart") then
                    targetPart = part
                    break
                end
            end
        end
    end
    
    -- Skip if OWNED surface GUI already exists
    if targetPart:FindFirstChild("OwnedSurfaceGui") then
        return
    end
    
    -- Create OWNED surface GUI (always visible by default)
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Name = "OwnedSurfaceGui"
    surfaceGui.Face = Enum.NormalId.Top
    surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surfaceGui.PixelsPerStud = 100
    surfaceGui.Enabled = true -- Always enabled, visibility controlled by service logic
    surfaceGui.Parent = targetPart
    
    -- Create "OWNED" text
    local ownedLabel = Instance.new("TextLabel")
    ownedLabel.Name = "OwnedText"
    ownedLabel.Size = UDim2.new(1, 0, 1, 0)
    ownedLabel.BackgroundTransparency = 1
    ownedLabel.Font = Enum.Font.FredokaOne
    ownedLabel.Text = "OWNED"
    ownedLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    ownedLabel.TextSize = 48
    ownedLabel.TextStrokeTransparency = 0
    ownedLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    ownedLabel.TextXAlignment = Enum.TextXAlignment.Center
    ownedLabel.TextYAlignment = Enum.TextYAlignment.Center
    ownedLabel.Rotation = 180
    ownedLabel.Parent = surfaceGui
    
    -- Created OWNED surface GUI
end

function AreaTemplateSetupService:CreateVIPStandGUI(areaTemplate)
    -- Find the VIPStand model (separate from VIPButton)
    local vipStand = areaTemplate:FindFirstChild("VIPStand", true)
    if not vipStand then
        return
    end
    
    -- Find the Cube.010 stand part within the VIPStand model
    local standPart = vipStand:FindFirstChild("Cube.010")
    if not standPart then
        return
    end
    
    -- Skip if GUI already exists
    if standPart:FindFirstChild("VIPStandGui") then
        return
    end
    
    -- Creating VIP stand GUI
    
    -- Create surface GUI on the stand
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Name = "VIPStandGui"
    surfaceGui.Face = Enum.NormalId.Front
    surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surfaceGui.PixelsPerStud = 500 -- Very high resolution for much better visibility
    surfaceGui.Parent = standPart
    
    -- Create simple transparent container
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.Position = UDim2.new(0, 0, 0, 0)
    mainFrame.BackgroundTransparency = 1 -- Completely transparent
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = surfaceGui
    
    -- VIP Icon (top section - will be set dynamically)
    local iconImage = Instance.new("ImageLabel")
    iconImage.Name = "VIPIcon"
    iconImage.Size = UDim2.new(0.25, 0, 0.2, 0) -- Smaller icon
    iconImage.Position = UDim2.new(0.375, 0, 0.05, 0) -- Centered
    iconImage.BackgroundTransparency = 1
    iconImage.ScaleType = Enum.ScaleType.Fit
    iconImage.Image = "" -- Will be set dynamically by VIPButtonService
    iconImage.Parent = mainFrame
    
    -- VIP Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "VIPTitle"
    titleLabel.Size = UDim2.new(1, 0, 0.15, 0)
    titleLabel.Position = UDim2.new(0, 0, 0.3, 0) -- Moved up slightly
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.FredokaOne
    titleLabel.Text = "VIP"
    titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
    titleLabel.TextSize = 32 -- Larger text for better visibility
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.TextYAlignment = Enum.TextYAlignment.Center
    titleLabel.Parent = mainFrame
    
    -- Description
    local descLabel = Instance.new("TextLabel")
    descLabel.Name = "VIPDescription"
    descLabel.Size = UDim2.new(1, 0, 0.2, 0)
    descLabel.Position = UDim2.new(0, 0, 0.45, 0) -- Adjusted position
    descLabel.BackgroundTransparency = 1
    descLabel.Font = Enum.Font.Gotham
    descLabel.Text = "All gamepasses included\n+ exclusive benefits!"
    descLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    descLabel.TextSize = 18 -- Larger description text
    descLabel.TextStrokeTransparency = 0
    descLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    descLabel.TextXAlignment = Enum.TextXAlignment.Center
    descLabel.TextYAlignment = Enum.TextYAlignment.Center
    descLabel.Parent = mainFrame
    
    -- Price label (will be updated dynamically)
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Name = "VIPPrice"
    priceLabel.Size = UDim2.new(1, 0, 0.15, 0)
    priceLabel.Position = UDim2.new(0, 0, 0.75, 0)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Font = Enum.Font.FredokaOne
    priceLabel.Text = "Loading..."
    priceLabel.TextColor3 = Color3.fromRGB(255, 255, 100) -- Yellow
    priceLabel.TextSize = 24 -- Larger price text
    priceLabel.TextStrokeTransparency = 0
    priceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    priceLabel.TextXAlignment = Enum.TextXAlignment.Center
    priceLabel.TextYAlignment = Enum.TextYAlignment.Center
    priceLabel.Parent = mainFrame
    
    -- OWNED label (hidden by default, shown when owned)
    local ownedLabel = Instance.new("TextLabel")
    ownedLabel.Name = "VIPOwned"
    ownedLabel.Size = UDim2.new(1, 0, 0.15, 0)
    ownedLabel.Position = UDim2.new(0, 0, 0.75, 0)
    ownedLabel.BackgroundTransparency = 1
    ownedLabel.Font = Enum.Font.FredokaOne
    ownedLabel.Text = "OWNED"
    ownedLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green
    ownedLabel.TextSize = 28 -- Larger OWNED text
    ownedLabel.TextStrokeTransparency = 0
    ownedLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    ownedLabel.TextXAlignment = Enum.TextXAlignment.Center
    ownedLabel.TextYAlignment = Enum.TextYAlignment.Center
    ownedLabel.Visible = false -- Hidden by default
    ownedLabel.Parent = mainFrame
end

return AreaTemplateSetupService