-- Plot Generator Service
-- Programmatically creates a 4x5 grid of plots based on Plot1 template
-- Ensures all plots are at the same height (lowest part on baseplate)

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlotGenerator = {}
PlotGenerator.__index = PlotGenerator

-- Configuration for plot grid
local PLOT_CONFIG = {
    rows = 4,  -- Vertical rows
    columns = 6,  -- Horizontal columns
    totalPlots = 24, -- 4 * 6
    spacing = Vector3.new(12, 0, 12), -- Moderate distance between plot centers
    gridOffset = Vector3.new(-6, 0, 6) -- Position Plot1 next to spawn point
}

function PlotGenerator:Initialize()
    print("PlotGenerator: Initializing plot grid generation...")
    return true
end

-- Generate the complete plot grid for a player area
function PlotGenerator:GeneratePlotGrid(playerArea)
    if not playerArea then
        warn("PlotGenerator: No player area provided")
        return false
    end
    
    -- Find the spawn point to use as reference
    local spawnPoint = playerArea:FindFirstChild("SpawnPoint")
    if not spawnPoint then
        warn("PlotGenerator: SpawnPoint not found in area")
        return false
    end
    
    -- Find the Plot1 template in the area
    local plotTemplate = playerArea:FindFirstChild("Plots") and playerArea.Plots:FindFirstChild("Plot1")
    if not plotTemplate then
        warn("PlotGenerator: Plot1 template not found in area")
        return false
    end
    
    print("PlotGenerator: Found Plot1 template and SpawnPoint, generating grid relative to spawn...")
    
    -- Get the plots container
    local plotsContainer = playerArea.Plots
    
    -- Get spawn point position as reference
    local spawnPosition = spawnPoint.Position
    
    -- Calculate the lowest Y position of the template to ensure consistent height
    local templateLowestY = self:GetLowestPartY(plotTemplate)
    local baseplateY = 0 -- Assuming baseplate is at Y=0
    local heightOffset = baseplateY - templateLowestY
    
    local plotIndex = 1
    
    -- Generate plots in vertical columns (1-5, 6-10, etc)
    for column = 1, PLOT_CONFIG.columns do
        for row = 1, PLOT_CONFIG.rows do
            if plotIndex <= PLOT_CONFIG.totalPlots then
                -- Calculate the plot number for vertical ordering
                local actualPlotNumber = row + (column - 1) * PLOT_CONFIG.rows
                
                -- Skip Plot1 since it already exists
                if actualPlotNumber > 1 then
                    local plotPosition = self:CalculatePlotPositionVertical(row, column, spawnPosition)
                    local newPlot = self:CreatePlotFromTemplate(plotTemplate, actualPlotNumber, plotPosition, heightOffset)
                    
                    if newPlot then
                        newPlot.Parent = plotsContainer
                        print(string.format("PlotGenerator: Created Plot%d at row %d, column %d", actualPlotNumber, row, column))
                    end
                end
                plotIndex = plotIndex + 1
            end
        end
    end
    
    -- Position Plot1 correctly next to spawn
    local plot1Position = self:CalculatePlotPositionVertical(1, 1, spawnPosition)
    self:PositionPlot(plotTemplate, plot1Position, heightOffset)
    
    -- Ensure Plot1 has PlotId value
    local plot1IdValue = plotTemplate:FindFirstChild("PlotId")
    if not plot1IdValue then
        plot1IdValue = Instance.new("IntValue")
        plot1IdValue.Name = "PlotId"
        plot1IdValue.Parent = plotTemplate
    end
    plot1IdValue.Value = 1
    
    print("PlotGenerator: Plot grid generation completed for area!")
    return true
end

-- Calculate position for a plot based on its row and column relative to spawn point (vertical layout)
function PlotGenerator:CalculatePlotPositionVertical(row, column, spawnPosition)
    -- Vertical layout: rows go up (negative Z), columns go left (negative X)
    -- Plot1 is bottom-right, next to spawn
    local x = spawnPosition.X + PLOT_CONFIG.gridOffset.X - (column - 1) * PLOT_CONFIG.spacing.X
    local z = spawnPosition.Z + PLOT_CONFIG.gridOffset.Z - (row - 1) * PLOT_CONFIG.spacing.Z
    local y = spawnPosition.Y -- Keep Y at spawn level
    
    return Vector3.new(x, y, z)
end

-- Create a new plot from the template
function PlotGenerator:CreatePlotFromTemplate(template, plotIndex, position, heightOffset)
    local newPlot = template:Clone()
    newPlot.Name = "Plot" .. plotIndex
    
    -- Add or update PlotId value
    local plotIdValue = newPlot:FindFirstChild("PlotId")
    if not plotIdValue then
        plotIdValue = Instance.new("IntValue")
        plotIdValue.Name = "PlotId"
        plotIdValue.Parent = newPlot
    end
    plotIdValue.Value = plotIndex
    
    -- Position the plot correctly
    self:PositionPlot(newPlot, position, heightOffset)
    
    return newPlot
end

-- Position a plot at the specified location with height adjustment
function PlotGenerator:PositionPlot(plot, position, heightOffset)
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
function PlotGenerator:GetPlotCenter(plot)
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
function PlotGenerator:GetLowestPartY(plot)
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

-- Generate plots for all existing player areas
function PlotGenerator:GenerateAllAreaPlots()
    local playerAreas = Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then
        warn("PlotGenerator: PlayerAreas not found in Workspace")
        return false
    end
    
    local successCount = 0
    for _, area in pairs(playerAreas:GetChildren()) do
        if area:IsA("Model") then
            if self:GeneratePlotGrid(area) then
                successCount = successCount + 1
            end
        end
    end
    
    print(string.format("PlotGenerator: Successfully generated plots for %d areas", successCount))
    return successCount > 0
end

return PlotGenerator