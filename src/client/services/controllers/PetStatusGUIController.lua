-- Pet Status GUI Controller
-- Handles creation and updating of pet status billboard GUIs
-- Extracted from PetGrowthService.lua for better modularity

local PetStatusGUIController = {}

-- Initialize the GUI controller
function PetStatusGUIController:Initialize()
    -- No initialization needed for GUI controller
end

-- Set the active pets table reference
function PetStatusGUIController:setActivePets(activePetsRef)
    self.activePets = activePetsRef
end

-- Create pet status GUI billboard
function PetStatusGUIController:createPetStatusGUI(plotId)
    if not self.activePets or not self.activePets[plotId] then return end
    
    local petInfo = self.activePets[plotId]
    if not petInfo.model then return end
    
    local petData = petInfo.petData
    local auraName = petData.auraData.name
    local petName = petData.name
    local auraColor = petData.auraData.color
    
    -- Create BillboardGui
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PetStatusGUI"
    billboard.Size = UDim2.new(0, 200, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.LightInfluence = 0
    billboard.AlwaysOnTop = true
    billboard.Parent = petInfo.model
    
    -- Create text label (no background, just text like plot GUIs)
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "StatusText"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Position = UDim2.new(0, 0, 0, 0)
    textLabel.BackgroundTransparency = 1
    -- Show improved format: "Diamond\nAcid Dog\nGrowing!"
    if petInfo.isEggPhase then
        textLabel.Text = auraName .. "\n????\nGrowing..."
        textLabel.TextColor3 = auraColor -- Use aura color even for egg
    else
        textLabel.Text = auraName .. "\n" .. petName .. "\nGrowing..."
        textLabel.TextColor3 = auraColor
    end
    textLabel.TextSize = 18
    textLabel.TextWrapped = true
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Parent = billboard
    
    -- Add black outline for better visibility
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 0, 0)
    stroke.Thickness = 3
    stroke.Parent = textLabel
    
    -- Store GUI reference
    petInfo.statusGUI = billboard
end

-- Update pet status GUI text
function PetStatusGUIController:updatePetStatusGUI(plotId, isReady)
    if not self.activePets or not self.activePets[plotId] then return end
    
    local petInfo = self.activePets[plotId]
    if not petInfo.statusGUI then return end
    
    local textLabel = petInfo.statusGUI.StatusText
    local petData = petInfo.petData
    local auraName = petData.auraData.name
    local petName = petData.name
    local auraColor = petData.auraData.color
    
    if isReady then
        textLabel.Text = auraName .. "\n" .. petName .. "\nReady!"
        textLabel.TextColor3 = auraColor -- Use aura color even when ready
    elseif petInfo.isEggPhase then
        -- Keep mystery during egg phase
        textLabel.Text = auraName .. "\n????\nGrowing..."
        textLabel.TextColor3 = auraColor
    else
        -- Reveal pet name after egg hatches
        textLabel.Text = auraName .. "\n" .. petName .. "\nGrowing..."
        textLabel.TextColor3 = auraColor
    end
end

-- Remove status GUI for a pet
function PetStatusGUIController:removeStatusGUI(plotId)
    if not self.activePets or not self.activePets[plotId] then return end
    
    local petInfo = self.activePets[plotId]
    if petInfo.statusGUI then
        petInfo.statusGUI:Destroy()
        petInfo.statusGUI = nil
    end
end

-- Cleanup all GUIs
function PetStatusGUIController:cleanup()
    if not self.activePets then return end
    
    for plotId, petInfo in pairs(self.activePets) do
        if petInfo.statusGUI then
            petInfo.statusGUI:Destroy()
            petInfo.statusGUI = nil
        end
    end
end

return PetStatusGUIController