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
    
    print("AreaTemplateSetupService: Setting up static GUIs in AreaTemplate for bulk copying...")
    
    -- Pre-create all door level/number GUIs
    self:CreateDoorGUIs(areaTemplate)
    
    -- Pre-create all tube number GUIs
    self:CreateTubeGUIs(areaTemplate)
    
    -- Pre-create instruction GUIs for buttons
    self:CreateInstructionGUIs(areaTemplate)
    
    -- Pre-create gamepass button GUIs (ownership status added later)
    self:CreateGamepassButtonGUIs(areaTemplate)
    
    print("AreaTemplateSetupService: Static GUI setup completed - will be copied to all 6 areas")
end

function AreaTemplateSetupService:CreateDoorGUIs(areaTemplate)
    -- Create door label GUIs for all levels and doors
    local totalDoors = 0
    for level = 1, 6 do
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
    print("AreaTemplateSetupService: Created door GUIs for", totalDoors, "doors")
end

function AreaTemplateSetupService:CreateDoorSurfaceGui(door, level, doorNumber)
    -- Find the main part of the door to attach GUI to
    local targetPart = self:FindDoorTargetPart(door)
    if not targetPart then
        return
    end
    
    -- Skip if GUI already exists
    if targetPart:FindFirstChild("DoorLabelGui_Front") then
        return
    end
    
    -- Create SurfaceGui for all faces
    local faces = {
        Enum.NormalId.Front,
        Enum.NormalId.Back,
        Enum.NormalId.Left,
        Enum.NormalId.Right,
        Enum.NormalId.Top,
        Enum.NormalId.Bottom
    }
    
    for _, face in pairs(faces) do
        local surfaceGui = Instance.new("SurfaceGui")
        surfaceGui.Name = "DoorLabelGui_" .. tostring(face)
        surfaceGui.Face = face
        surfaceGui.LightInfluence = 0
        surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        surfaceGui.PixelsPerStud = 50
        surfaceGui.Parent = targetPart
        
        -- Create background frame for better visibility
        local bgFrame = Instance.new("Frame")
        bgFrame.Name = "Background"
        bgFrame.Size = UDim2.new(0.8, 0, 0.6, 0)
        bgFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
        bgFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        bgFrame.BackgroundTransparency = 0.3
        bgFrame.BorderSizePixel = 0
        bgFrame.Parent = surfaceGui
        
        -- Create text label
        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "DoorLabel"
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = "Level " .. level .. "\n\nDoor " .. doorNumber
        textLabel.TextColor3 = Color3.fromRGB(255, 165, 0) -- Orange - visible on both red and green
        textLabel.TextSize = 72 -- Larger text size
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextStrokeTransparency = 0
        textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        textLabel.TextXAlignment = Enum.TextXAlignment.Center
        textLabel.TextYAlignment = Enum.TextYAlignment.Center
        textLabel.Parent = bgFrame
    end
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
    textLabel.Font = Enum.Font.GothamBold
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
    -- Create SendHeaven instruction GUI
    self:CreateSendHeavenInstructionGUI(areaTemplate)
    
    -- Create Teleport instruction GUIs
    self:CreateTeleportInstructionGUIs(areaTemplate)
    
    -- Rebirth instruction GUI removed per user request
end

function AreaTemplateSetupService:CreateSendHeavenInstructionGUI(areaTemplate)
    -- Find SendHeaven button
    local sendHeavenButton = areaTemplate:FindFirstChild("SendHeaven", true)
    if not sendHeavenButton then
        return
    end
    
    -- Skip if GUI already exists
    if sendHeavenButton:FindFirstChild("InstructionBillboard") then
        return
    end
    
    -- Create BillboardGui for instruction
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "InstructionBillboard"
    billboardGui.Size = UDim2.new(0, 200, 0, 80)
    billboardGui.StudsOffset = Vector3.new(0, 8, 0)
    billboardGui.MaxDistance = 50
    billboardGui.Parent = sendHeavenButton
    
    -- Create instruction label
    local instructionLabel = Instance.new("TextLabel")
    instructionLabel.Size = UDim2.new(1, 0, 1, 0)
    instructionLabel.BackgroundTransparency = 1
    instructionLabel.Font = Enum.Font.GothamBold
    instructionLabel.Text = "Send pets to\nheaven here!"
    instructionLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold color
    instructionLabel.TextSize = 20
    instructionLabel.TextStrokeTransparency = 0
    instructionLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    instructionLabel.Parent = billboardGui
end

function AreaTemplateSetupService:CreateTeleportInstructionGUIs(areaTemplate)
    -- Find Teleport model
    local teleportModel = areaTemplate:FindFirstChild("Teleport", true)
    if not teleportModel then
        return
    end
    
    -- Find the teleport part (look for a part named "Teleport" or first BasePart)
    local teleportPart = teleportModel:FindFirstChild("Teleport")
    if not teleportPart or not teleportPart:IsA("BasePart") then
        -- Fallback to first BasePart
        for _, part in pairs(teleportModel:GetChildren()) do
            if part:IsA("BasePart") then
                teleportPart = part
                break
            end
        end
    end
    
    if not teleportPart then
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
        surfaceGui.PixelsPerStud = 100
        surfaceGui.Parent = teleportPart
        
        local requirementLabel = Instance.new("TextLabel")
        requirementLabel.Name = "RequirementText"
        requirementLabel.Size = UDim2.new(1, 0, 1, 0)
        requirementLabel.BackgroundTransparency = 1
        requirementLabel.Font = Enum.Font.GothamBold
        requirementLabel.Text = "Need 5 rebirths\nto teleport here!"
        requirementLabel.TextColor3 = Color3.fromRGB(255, 100, 100) -- Red for requirement
        requirementLabel.TextSize = 48
        requirementLabel.TextStrokeTransparency = 0
        requirementLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
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
    instructionLabel.Font = Enum.Font.GothamBold
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
    billboardGui.Size = UDim2.new(0, 150, 0, 80)  -- Better proportions
    billboardGui.StudsOffset = Vector3.new(0, 5, 0)  -- Float 5 studs above
    billboardGui.MaxDistance = 80
    billboardGui.Parent = button
    
    -- Create title label (shows gamepass name)
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = buttonText
    titleLabel.TextColor3 = buttonColor
    titleLabel.TextSize = 18
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.TextYAlignment = Enum.TextYAlignment.Center
    titleLabel.Parent = billboardGui
    
    -- Create description label (shows gamepass benefits)
    local descriptionLabel = Instance.new("TextLabel")
    descriptionLabel.Name = "DescriptionLabel"
    descriptionLabel.Size = UDim2.new(1, 0, 0, 50)
    descriptionLabel.Position = UDim2.new(0, 0, 0, 30)
    descriptionLabel.BackgroundTransparency = 1
    descriptionLabel.Font = Enum.Font.Gotham
    descriptionLabel.Text = buttonDescription
    descriptionLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    descriptionLabel.TextSize = 12
    descriptionLabel.TextWrapped = true
    descriptionLabel.TextStrokeTransparency = 0
    descriptionLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    descriptionLabel.TextXAlignment = Enum.TextXAlignment.Center
    descriptionLabel.TextYAlignment = Enum.TextYAlignment.Top
    descriptionLabel.Parent = billboardGui
    
    -- Create owned label (hidden by default, shown when owned)
    local ownedLabel = Instance.new("TextLabel")
    ownedLabel.Name = "OwnedLabel"
    ownedLabel.Size = UDim2.new(1, 0, 1, 0)
    ownedLabel.Position = UDim2.new(0, 0, 0, 0)
    ownedLabel.BackgroundTransparency = 1
    ownedLabel.Font = Enum.Font.GothamBold
    ownedLabel.Text = buttonText .. "\nOWNED"
    ownedLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green for owned
    ownedLabel.TextSize = 20
    ownedLabel.TextStrokeTransparency = 0
    ownedLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    ownedLabel.TextXAlignment = Enum.TextXAlignment.Center
    ownedLabel.TextYAlignment = Enum.TextYAlignment.Center
    ownedLabel.Visible = false -- Hidden by default
    ownedLabel.Parent = billboardGui
end

return AreaTemplateSetupService