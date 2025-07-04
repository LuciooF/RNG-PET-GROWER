-- Tube Manager Service
-- Manages creation and destruction of production tubes (Tube2-Tube11) based on owned production plots
-- Tube1 is always present by default, production plots create additional tubes for faster heaven processing

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local ProductionPlotConfig = require(ReplicatedStorage.Shared.config.ProductionPlotConfig)
local TubeGUI = require(script.Parent.Parent.components.ui.TubeGUI)

local TubeManagerService = {}
TubeManagerService.__index = TubeManagerService

local player = Players.LocalPlayer
local playerAreaNumber = nil
local areaAssignments = {}
local activeTubes = {} -- Track created tubes
local lastPlayerData = {} -- Cache player data
local tube1GUI = nil -- GUI for default Tube1

-- Configuration
local TUBE_SPACING = 8 -- Distance between tubes
local TUBE_HEIGHT = 10 -- Height of tubes above ground

function TubeManagerService:Initialize()
    -- Wait for PlayerAreas to be created
    local playerAreas = Workspace:WaitForChild("PlayerAreas", 10)
    if not playerAreas then
        warn("TubeManagerService: PlayerAreas not found!")
        return
    end
    
    -- Set up data sync connections
    self:setupDataSync()
    self:setupAreaSync()
    
    -- Set up Tube1 GUI
    self:SetupTube1GUI()
    
    print("TubeManagerService: Initialized successfully")
end

function TubeManagerService:setupDataSync()
    local playerDataSync = ReplicatedStorage:WaitForChild("PlayerDataSync", 10)
    if playerDataSync then
        playerDataSync.OnClientEvent:Connect(function(data)
            if data and data.resources then
                lastPlayerData = {
                    money = data.resources.money or 0,
                    rebirths = data.resources.rebirths or 0,
                    boughtPlots = data.boughtPlots or {},
                    boughtProductionPlots = data.boughtProductionPlots or {}
                }
                self:UpdateTubes()
            end
        end)
    end
end

function TubeManagerService:setupAreaSync()
    local areaAssignmentSync = ReplicatedStorage:WaitForChild("AreaAssignmentSync", 10)
    if areaAssignmentSync then
        areaAssignmentSync.OnClientEvent:Connect(function(assignmentData)
            areaAssignments = assignmentData
            playerAreaNumber = self:GetPlayerAreaNumber()
            self:UpdateTubes()
        end)
    end
end

function TubeManagerService:GetPlayerAreaNumber()
    for areaNumber, assignmentData in pairs(areaAssignments) do
        if assignmentData.playerName == player.Name then
            return areaNumber
        end
    end
    return nil
end

function TubeManagerService:GetPlayerArea()
    if not playerAreaNumber then return nil end
    
    local playerAreas = Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then return nil end
    
    return playerAreas:FindFirstChild("PlayerArea" .. playerAreaNumber)
end

function TubeManagerService:GetTube1Position()
    local playerArea = self:GetPlayerArea()
    if not playerArea then return nil end
    
    local tube1 = playerArea:FindFirstChild("Tube1")
    if not tube1 then
        warn("TubeManagerService: Tube1 not found! Cannot position production tubes.")
        return nil
    end
    
    -- Get the Base part position from Tube1 model
    local tube1Base = tube1:FindFirstChild("Base")
    if not tube1Base then
        warn("TubeManagerService: Tube1 Base part not found! Cannot position production tubes.")
        return nil
    end
    
    return tube1Base.Position
end

function TubeManagerService:SetupTube1GUI()
    if not playerAreaNumber then return end
    
    local playerArea = self:GetPlayerArea()
    if not playerArea then return end
    
    local tube1 = playerArea:FindFirstChild("Tube1")
    if not tube1 then return end
    
    -- Clean up existing GUI
    if tube1GUI then
        TubeGUI.destroyTubeGUI(tube1GUI)
        tube1GUI = nil
    end
    
    -- Create GUI for default Tube1 (plotId = 0 means default tube)
    tube1GUI = TubeGUI.createTubeGUI(tube1, 0)
    if tube1GUI then
        TubeGUI.addPulseEffect(tube1GUI)
        print("TubeManagerService: Created GUI for Tube1")
    end
end

function TubeManagerService:UpdateTubes()
    if not playerAreaNumber then return end
    
    local tube1Position = self:GetTube1Position()
    if not tube1Position then return end
    
    -- Set up Tube1 GUI if not already done
    if not tube1GUI then
        self:SetupTube1GUI()
    end
    
    -- Remove tubes for production plots no longer owned
    self:cleanupUnownedTubes()
    
    -- Create tubes for newly owned production plots
    self:createTubesForOwnedPlots(tube1Position)
end

function TubeManagerService:cleanupUnownedTubes()
    for plotId, tubeData in pairs(activeTubes) do
        local isOwned = false
        
        for _, ownedPlotId in pairs(lastPlayerData.boughtProductionPlots or {}) do
            if ownedPlotId == plotId then
                isOwned = true
                break
            end
        end
        
        if not isOwned then
            self:destroyTube(plotId)
        end
    end
end

function TubeManagerService:createTubesForOwnedPlots(tube1Position)
    local boughtProductionPlots = lastPlayerData.boughtProductionPlots or {}
    
    -- Only print if the owned plots changed (reduce spam)
    local currentPlots = table.concat(boughtProductionPlots, ",")
    if not lastPlayerData.lastPlotString or lastPlayerData.lastPlotString ~= currentPlots then
        lastPlayerData.lastPlotString = currentPlots
        if #boughtProductionPlots > 0 then
            print("TubeManagerService: Player owns production plots:", table.concat(boughtProductionPlots, ", "))
        else
            print("TubeManagerService: Player owns no production plots yet.")
        end
    end
    
    for _, plotId in pairs(boughtProductionPlots) do
        if not activeTubes[plotId] then
            self:CreateProductionTube(plotId, tube1Position)
        end
    end
end

function TubeManagerService:CreateProductionTube(plotId, tube1Position)
    local plotData = ProductionPlotConfig:GetPlotData(plotId)
    if not plotData then
        warn("TubeManagerService: Invalid production plot ID:", plotId)
        return
    end
    
    local playerArea = self:GetPlayerArea()
    if not playerArea then return end
    
    -- Calculate tube position based on plot ID
    -- Tube1 is center, production tubes spread out on both sides
    -- Plot 1,3,5,7,9 go to the right (Tube2,4,6,8,10)
    -- Plot 2,4,6,8,10 go to the left (Tube3,5,7,9,11)
    local tubeNumber = plotId + 1 -- Tube2-Tube11 for plots 1-10
    local isRightSide = (plotId % 2 == 1) -- Odd plots go right
    local sideIndex = math.ceil(plotId / 2) -- 1,2,3,4,5 for each side
    
    local offsetX = isRightSide and (sideIndex * TUBE_SPACING) or -(sideIndex * TUBE_SPACING)
    local tubePosition = tube1Position + Vector3.new(offsetX, 0, 0)
    
    -- Create tube model
    local tubeModel = self:createTubeModel(tubeNumber, tubePosition, plotId)
    if not tubeModel then
        warn("TubeManagerService: Failed to create tube model for plot", plotId)
        return
    end
    
    tubeModel.Parent = playerArea
    
    -- Create GUI for this tube
    local tubeGUIRef = TubeGUI.createTubeGUI(tubeModel, plotId)
    if tubeGUIRef then
        TubeGUI.addPulseEffect(tubeGUIRef)
    end
    
    -- Store tube data
    activeTubes[plotId] = {
        model = tubeModel,
        plotId = plotId,
        tubeNumber = tubeNumber,
        position = tubePosition,
        gui = tubeGUIRef
    }
    
    -- Notify that tube count changed
    self:NotifyTubeCountChanged()
    
    print(string.format("TubeManagerService: Created Tube%d for production plot %d", tubeNumber, plotId))
end

function TubeManagerService:createTubeModel(tubeNumber, position, plotId)
    local playerArea = self:GetPlayerArea()
    if not playerArea then return nil end
    
    -- Find the original Tube1 to use as template
    local tube1 = playerArea:FindFirstChild("Tube1")
    if not tube1 then
        warn("TubeManagerService: Tube1 template not found! Cannot create production tube.")
        return nil
    end
    
    -- Clone Tube1 exactly
    local tubeModel = tube1:Clone()
    tubeModel.Name = "Tube" .. tubeNumber
    
    -- Get the original Tube1 base position for relative positioning
    local tube1Base = tube1:FindFirstChild("Base")
    if not tube1Base then
        warn("TubeManagerService: Tube1 Base not found! Cannot position production tube.")
        return nil
    end
    
    -- Calculate offset from original position
    local originalPosition = tube1Base.Position
    local positionOffset = position - originalPosition
    
    -- Move all parts by the offset to maintain relative positioning
    for _, child in pairs(tubeModel:GetDescendants()) do
        if child:IsA("BasePart") then
            child.Position = child.Position + positionOffset
            
            -- Change color based on production plot rarity using correct plotId
            if child.Name == "Base" or child.Name:find("Tube") then
                local rarityColor = ProductionPlotConfig:GetPlotRarityColor(plotId)
                child.Color = rarityColor
                
                -- Update point light color if it exists
                local pointLight = child:FindFirstChild("PointLight")
                if pointLight then
                    pointLight.Color = child.Color
                end
            end
        end
    end
    
    return tubeModel
end

function TubeManagerService:destroyTube(plotId)
    local tubeData = activeTubes[plotId]
    if not tubeData then return end
    
    -- Clean up GUI
    if tubeData.gui then
        TubeGUI.destroyTubeGUI(tubeData.gui)
    end
    
    -- Clean up model
    if tubeData.model and tubeData.model.Parent then
        tubeData.model:Destroy()
    end
    
    activeTubes[plotId] = nil
    
    -- Notify that tube count changed
    self:NotifyTubeCountChanged()
    
    print(string.format("TubeManagerService: Destroyed tube for production plot %d", plotId))
end

function TubeManagerService:GetActiveTubeCount()
    local count = 1 -- Always count Tube1
    for _ in pairs(activeTubes) do
        count = count + 1
    end
    return count
end

-- Notify other services that tube count has changed
function TubeManagerService:NotifyTubeCountChanged()
    -- Try to update ProcessingRateGUI if SendHeavenService is loaded
    local success, SendHeavenService = pcall(function()
        return require(script.Parent.SendHeavenService)
    end)
    
    if success and SendHeavenService and SendHeavenService.UpdateProcessingRateGUI then
        SendHeavenService:UpdateProcessingRateGUI()
    end
end

-- Update all tube GUIs with new processing speeds (for game balancing)
function TubeManagerService:UpdateAllTubeGUIs()
    -- Update Tube1 GUI
    if tube1GUI then
        TubeGUI.updateTubeGUI(tube1GUI, 1.0)
    end
    
    -- Update production tube GUIs
    for plotId, tubeData in pairs(activeTubes) do
        if tubeData.gui then
            local newSpeed = ProductionPlotConfig:GetPlotProcessingSpeed(plotId)
            TubeGUI.updateTubeGUI(tubeData.gui, newSpeed)
        end
    end
end

-- Update tube GUI configuration (for game balancing)
function TubeManagerService:UpdateTubeGUIConfig(newConfig)
    TubeGUI.updateConfig(newConfig)
end

function TubeManagerService:Cleanup()
    -- Clean up Tube1 GUI
    if tube1GUI then
        TubeGUI.destroyTubeGUI(tube1GUI)
        tube1GUI = nil
    end
    
    -- Clean up all created tubes
    for plotId, tubeData in pairs(activeTubes) do
        self:destroyTube(plotId)
    end
    activeTubes = {}
end

return TubeManagerService