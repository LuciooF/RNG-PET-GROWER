-- PlotVisual - Reactive component that updates plot colors based on Redux state
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local React = require(ReplicatedStorage.Packages.react)
local DataSyncService = require(script.Parent.Parent.services.DataSyncService)

-- Plot configuration
local TOTAL_PLOTS = 35
local TOTAL_TUBEPLOTS = 10

-- Helper functions for plot requirements
local function getPlotRebirthRequirement(plotNumber)
    if plotNumber >= 1 and plotNumber <= 5 then
        return 0
    elseif plotNumber >= 8 and plotNumber <= 14 then
        return 1
    elseif plotNumber >= 15 and plotNumber <= 21 then
        return 2
    elseif plotNumber >= 22 and plotNumber <= 28 then
        return 3
    elseif plotNumber >= 29 and plotNumber <= 35 then
        return 4
    else
        return 999 -- Invalid plot numbers (6, 7)
    end
end

local function getTubePlotRebirthRequirement(tubePlotNumber)
    return tubePlotNumber - 1
end

local function getPlotCost(plotNumber)
    if plotNumber == 1 then
        return 0 -- First plot is free
    end
    return 10 * (2 ^ (plotNumber - 2))
end

local function getTubePlotCost(tubePlotNumber)
    if tubePlotNumber == 1 then
        return 0 -- First tubeplot is free
    end
    return 20 * (2 ^ (tubePlotNumber - 2))
end

local function PlotVisual()
    -- Subscribe to player data
    local playerData, setPlayerData = React.useState({
        Resources = { Money = 0, Rebirths = 0 },
        OwnedPlots = {},
        OwnedTubes = {}
    })
    
    -- Subscribe to data changes
    React.useEffect(function()
        -- Get initial data
        local initialData = DataSyncService:GetPlayerData()
        if initialData then
            setPlayerData(initialData)
        end
        
        local unsubscribe = DataSyncService:Subscribe(function(newState)
            if newState.player then
                setPlayerData(newState.player)
            end
        end)
        
        return unsubscribe
    end, {})
    
    -- Update plot colors based on state
    React.useEffect(function()
        local playerMoney = playerData.Resources.Money or 0
        local playerRebirths = playerData.Resources.Rebirths or 0
        local ownedPlots = playerData.OwnedPlots or {}
        local ownedTubes = playerData.OwnedTubes or {}
        
        -- Create sets for faster lookup
        local ownedPlotsSet = {}
        for _, plotNumber in pairs(ownedPlots) do
            ownedPlotsSet[plotNumber] = true
        end
        
        local ownedTubesSet = {}
        for _, tubeNumber in pairs(ownedTubes) do
            ownedTubesSet[tubeNumber] = true
        end
        
        -- Find player's area
        local playerAreas = Workspace:FindFirstChild("PlayerAreas")
        if not playerAreas then return end
        
        -- Get player's specific area from AreaService
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        
        -- Find the player's assigned area by checking the area nameplate
        local playerArea = nil
        for _, area in pairs(playerAreas:GetChildren()) do
            if area.Name:match("PlayerArea") then
                -- Check if this area belongs to the current player by looking at the nameplate
                local nameplate = area:FindFirstChild("AreaNameplate")
                if nameplate then
                    local billboard = nameplate:FindFirstChild("NameplateBillboard")
                    if billboard then
                        local textLabel = billboard:FindFirstChild("TextLabel")
                        if textLabel and textLabel.Text == (player.Name .. "'s Area") then
                            playerArea = area
                            break
                        end
                    end
                end
            end
        end
        
        -- If we can't find the specific area, default to updating all (fallback)
        local areasToUpdate = playerArea and {playerArea} or playerAreas:GetChildren()
        
        for _, area in pairs(areasToUpdate) do
            -- Update regular plots
            for plotNumber = 1, TOTAL_PLOTS do
                if plotNumber ~= 6 and plotNumber ~= 7 then
                    local plot = area:FindFirstChild("Buttons") and area.Buttons:FindFirstChild("Plot" .. plotNumber)
                    if plot and plot:IsA("Model") then
                        local cube = plot:FindFirstChild("Cube.009")
                        if cube and cube:IsA("BasePart") then
                            cube.Material = Enum.Material.Neon
                            
                            local requiredRebirths = getPlotRebirthRequirement(plotNumber)
                            
                            if ownedPlotsSet[plotNumber] then
                                -- White if purchased
                                cube.Color = Color3.fromRGB(255, 255, 255)
                            elseif playerRebirths < requiredRebirths then
                                -- Black if not enough rebirths
                                cube.Color = Color3.fromRGB(0, 0, 0)
                            elseif playerMoney >= getPlotCost(plotNumber) then
                                -- Green if can afford
                                cube.Color = Color3.fromRGB(0, 255, 0)
                            else
                                -- Red if can't afford
                                cube.Color = Color3.fromRGB(255, 0, 0)
                            end
                        end
                    end
                end
            end
            
            -- Update tube plots
            for tubeNumber = 1, TOTAL_TUBEPLOTS do
                local tubePlot = area:FindFirstChild("Buttons") and area.Buttons:FindFirstChild("TubePlot" .. tubeNumber)
                if tubePlot and tubePlot:IsA("Model") then
                    local cube = tubePlot:FindFirstChild("Cube.009")
                    if cube and cube:IsA("BasePart") then
                        cube.Material = Enum.Material.Neon
                        
                        local requiredRebirths = getTubePlotRebirthRequirement(tubeNumber)
                        
                        if ownedTubesSet[tubeNumber] then
                            -- White if purchased
                            cube.Color = Color3.fromRGB(255, 255, 255)
                        elseif playerRebirths < requiredRebirths then
                            -- Black if not enough rebirths
                            cube.Color = Color3.fromRGB(0, 0, 0)
                        elseif playerMoney >= getTubePlotCost(tubeNumber) then
                            -- Green if can afford
                            cube.Color = Color3.fromRGB(0, 255, 0)
                        else
                            -- Red if can't afford
                            cube.Color = Color3.fromRGB(255, 0, 0)
                        end
                    end
                end
            end
        end
    end, {playerData})
    
    -- This component doesn't render any UI, it just manages plot colors
    return nil
end

return PlotVisual