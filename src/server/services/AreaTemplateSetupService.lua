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
    for level = 1, 6 do
        local levelFolder = areaTemplate:FindFirstChild("Level" .. level)
        if levelFolder then
            local doorsFolder = levelFolder:FindFirstChild("Level" .. level .. "Doors")
            if doorsFolder then
                for _, door in pairs(doorsFolder:GetChildren()) do
                    local doorNumber = tonumber(door.Name:match("Door(%d+)"))
                    if doorNumber then
                        self:CreateDoorSurfaceGui(door, level, doorNumber)
                    end
                end
            end
        end
    end
end

function AreaTemplateSetupService:CreateDoorSurfaceGui(door, level, doorNumber)
    -- Find the main part of the door to attach GUI to
    local targetPart = self:FindDoorTargetPart(door)
    if not targetPart then
        return
    end
    
    -- Skip if GUI already exists
    if targetPart:FindFirstChild("DoorLabelGui") then
        return
    end
    
    -- Create SurfaceGui (front face)
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Name = "DoorLabelGui"
    surfaceGui.Face = Enum.NormalId.Front
    surfaceGui.LightInfluence = 0
    surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surfaceGui.PixelsPerStud = 50
    surfaceGui.Parent = targetPart
    
    -- Create text label
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "DoorLabel"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "Level " .. level .. "\n\nDoor " .. doorNumber
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.Parent = surfaceGui
    
    -- Also create one for the back face
    local backGui = surfaceGui:Clone()
    backGui.Face = Enum.NormalId.Back
    backGui.Parent = targetPart
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
    -- Create base GUIs for all gamepass buttons
    local gamepassButtons = {
        {name = "2xMoneyButton", text = "2x Money", color = Color3.fromRGB(85, 170, 85)},
        {name = "2xDiamondsButton", text = "2x Diamonds", color = Color3.fromRGB(100, 149, 237)},
        {name = "2xHeavenSpeedButton", text = "2x Heaven Speed", color = Color3.fromRGB(255, 165, 0)},
        {name = "VIPButton", text = "VIP", color = Color3.fromRGB(255, 215, 0)},
        {name = "PetMagnetButton", text = "Pet Magnet", color = Color3.fromRGB(138, 43, 226)},
        {name = "AutoHeavenButton", text = "Auto Heaven", color = Color3.fromRGB(255, 69, 0)}
    }
    
    for _, buttonConfig in ipairs(gamepassButtons) do
        self:CreateGamepassButtonGUI(areaTemplate, buttonConfig.name, buttonConfig.text, buttonConfig.color)
    end
end

function AreaTemplateSetupService:CreateGamepassButtonGUI(areaTemplate, buttonName, buttonText, buttonColor)
    -- Find the gamepass button
    local button = areaTemplate:FindFirstChild(buttonName, true)
    if not button then
        return
    end
    
    -- Skip if GUI already exists
    if button:FindFirstChild("GamepassBillboard") then
        return
    end
    
    -- Create BillboardGui for the button (matches current design)
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "GamepassBillboard"
    billboardGui.Size = UDim2.new(0, 200, 0, 80)
    billboardGui.StudsOffset = Vector3.new(0, 8, 0)
    billboardGui.MaxDistance = 50
    billboardGui.Parent = button
    
    -- Create main text label (matches current simple design)
    local mainLabel = Instance.new("TextLabel")
    mainLabel.Name = "MainLabel"
    mainLabel.Size = UDim2.new(1, 0, 1, 0)
    mainLabel.BackgroundTransparency = 1
    mainLabel.Font = Enum.Font.GothamBold
    mainLabel.Text = buttonText
    mainLabel.TextColor3 = buttonColor
    mainLabel.TextSize = 20
    mainLabel.TextStrokeTransparency = 0
    mainLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    mainLabel.TextXAlignment = Enum.TextXAlignment.Center
    mainLabel.TextYAlignment = Enum.TextYAlignment.Center
    mainLabel.Parent = billboardGui
end

return AreaTemplateSetupService