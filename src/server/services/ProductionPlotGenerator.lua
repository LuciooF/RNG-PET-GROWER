-- Production Plot Generator Service
-- Programmatically creates a 2x6 grid of production plots based on Plot1 template
-- Positions them on the opposite side of regular plots with space in between

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProductionPlotGenerator = {}
ProductionPlotGenerator.__index = ProductionPlotGenerator

-- Configuration for production plot grid
local PRODUCTION_PLOT_CONFIG = {
    rows = 2,  -- Vertical rows
    columns = 6,  -- Horizontal columns
    totalPlots = 12, -- 2 * 6
    spacing = Vector3.new(12, 0, 12), -- Same spacing as regular plots
    gridOffset = Vector3.new(-6, 0, -42) -- Positioned on opposite side with gap
}

function ProductionPlotGenerator:Initialize()
    print("ProductionPlotGenerator: Initializing production plot grid generation...")
    return true
end

-- Generate the complete production plot grid for a player area
function ProductionPlotGenerator:GenerateProductionPlotGrid(playerArea)
    if not playerArea then
        warn("ProductionPlotGenerator: No player area provided")
        return false
    end
    
    -- Find the spawn point to use as reference
    local spawnPoint = playerArea:FindFirstChild("SpawnPoint")
    if not spawnPoint then
        warn("ProductionPlotGenerator: SpawnPoint not found in area")
        return false
    end
    
    -- Find the Plot1 template in the regular Plots folder
    local plotTemplate = playerArea:FindFirstChild("Plots") and playerArea.Plots:FindFirstChild("Plot1")
    if not plotTemplate then
        warn("ProductionPlotGenerator: Plot1 template not found in area")
        return false
    end
    
    print("ProductionPlotGenerator: Found Plot1 template and SpawnPoint, generating production grid...")
    
    -- Create ProductionPlots container if it doesn't exist
    local productionPlotsContainer = playerArea:FindFirstChild("ProductionPlots")
    if not productionPlotsContainer then
        productionPlotsContainer = Instance.new("Folder")
        productionPlotsContainer.Name = "ProductionPlots"
        productionPlotsContainer.Parent = playerArea
    end
    
    -- Get spawn point position as reference
    local spawnPosition = spawnPoint.Position
    
    -- Calculate the lowest Y position of the template to ensure consistent height
    local templateLowestY = self:GetLowestPartY(plotTemplate)
    local baseplateY = 0 -- Assuming baseplate is at Y=0
    local heightOffset = baseplateY - templateLowestY
    
    local plotIndex = 1
    
    -- Generate production plots in vertical columns
    for column = 1, PRODUCTION_PLOT_CONFIG.columns do
        for row = 1, PRODUCTION_PLOT_CONFIG.rows do
            if plotIndex <= PRODUCTION_PLOT_CONFIG.totalPlots then
                -- Calculate the plot number for vertical ordering
                local actualPlotNumber = row + (column - 1) * PRODUCTION_PLOT_CONFIG.rows
                
                local plotPosition = self:CalculateProductionPlotPosition(row, column, spawnPosition)
                local newPlot = self:CreateProductionPlotFromTemplate(plotTemplate, actualPlotNumber, plotPosition, heightOffset)
                
                if newPlot then
                    newPlot.Parent = productionPlotsContainer
                    print(string.format("ProductionPlotGenerator: Created ProductionPlot%d at row %d, column %d", actualPlotNumber, row, column))
                end
                
                plotIndex = plotIndex + 1
            end
        end
    end
    
    print("ProductionPlotGenerator: Production plot grid generation completed for area!")
    return true
end

-- Calculate position for a production plot based on its row and column relative to spawn point
function ProductionPlotGenerator:CalculateProductionPlotPosition(row, column, spawnPosition)
    -- Position on opposite side of regular plots with gap
    local x = spawnPosition.X + PRODUCTION_PLOT_CONFIG.gridOffset.X - (column - 1) * PRODUCTION_PLOT_CONFIG.spacing.X
    local z = spawnPosition.Z + PRODUCTION_PLOT_CONFIG.gridOffset.Z - (row - 1) * PRODUCTION_PLOT_CONFIG.spacing.Z
    local y = spawnPosition.Y -- Keep Y at spawn level
    
    return Vector3.new(x, y, z)
end

-- Create a new production plot from the template
function ProductionPlotGenerator:CreateProductionPlotFromTemplate(template, plotIndex, position, heightOffset)
    local newPlot = template:Clone()
    newPlot.Name = "ProductionPlot" .. plotIndex
    
    -- Add or update PlotId value
    local plotIdValue = newPlot:FindFirstChild("PlotId")
    if not plotIdValue then
        plotIdValue = Instance.new("IntValue")
        plotIdValue.Name = "PlotId"
        plotIdValue.Parent = newPlot
    end
    plotIdValue.Value = plotIndex
    
    -- Add PlotType identifier
    local plotTypeValue = Instance.new("StringValue")
    plotTypeValue.Name = "PlotType"
    plotTypeValue.Value = "Production"
    plotTypeValue.Parent = newPlot
    
    -- Position the plot correctly
    self:PositionPlot(newPlot, position, heightOffset)
    
    return newPlot
end

-- Position a plot at the specified location with height adjustment
function ProductionPlotGenerator:PositionPlot(plot, position, heightOffset)
    if plot.PrimaryPart then
        -- Use PrimaryPart for positioning
        local currentCFrame = plot.PrimaryPart.CFrame
        local newPosition = position + Vector3.new(0, heightOffset, 0)
        plot:SetPrimaryPartCFrame(CFrame.new(newPosition) * (currentCFrame - currentCFrame.Position))
    else
        -- Fallback: move all parts
        local plotCenter = self:GetPlotCenter(plot)
        local offset = position + Vector3.new(0, heightOffset, 0) - plotCenter
        
        for _, part in pairs(plot:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Position = part.Position + offset
            end
        end
    end
end

-- Get the center position of a plot
function ProductionPlotGenerator:GetPlotCenter(plot)
    local totalPosition = Vector3.new(0, 0, 0)
    local partCount = 0
    
    for _, part in pairs(plot:GetDescendants()) do
        if part:IsA("BasePart") then
            totalPosition = totalPosition + part.Position
            partCount = partCount + 1
        end
    end
    
    if partCount > 0 then
        return totalPosition / partCount
    else
        return Vector3.new(0, 0, 0)
    end
end

-- Get the lowest Y position of any part in the plot
function ProductionPlotGenerator:GetLowestPartY(plot)
    local lowestY = math.huge
    
    for _, part in pairs(plot:GetDescendants()) do
        if part:IsA("BasePart") then
            local partBottomY = part.Position.Y - (part.Size.Y / 2)
            if partBottomY < lowestY then
                lowestY = partBottomY
            end
        end
    end
    
    return lowestY == math.huge and 0 or lowestY
end

-- Generate production plots for all existing player areas
function ProductionPlotGenerator:GenerateAllAreaProductionPlots()
    local playerAreas = Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then
        warn("ProductionPlotGenerator: PlayerAreas not found in Workspace")
        return false
    end
    
    local successCount = 0
    for _, area in pairs(playerAreas:GetChildren()) do
        if area:IsA("Model") then
            if self:GenerateProductionPlotGrid(area) then
                successCount = successCount + 1
            end
        end
    end
    
    print(string.format("ProductionPlotGenerator: Successfully generated production plots for %d areas", successCount))
    return successCount > 0
end

return ProductionPlotGenerator