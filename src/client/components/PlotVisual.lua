-- PlotVisual - Reactive component that updates plot colors based on Redux state
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local React = require(ReplicatedStorage.Packages.react)
local DataSyncService = require(script.Parent.Parent.services.DataSyncService)
local PlotConfig = require(ReplicatedStorage.config.PlotConfig)

-- Configuration now centralized in PlotConfig

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
            for plotNumber = 1, PlotConfig.TOTAL_PLOTS do
                if plotNumber ~= 6 and plotNumber ~= 7 then
                    local plot = area:FindFirstChild("Buttons") and area.Buttons:FindFirstChild("Plot" .. plotNumber)
                    if plot and plot:IsA("Model") then
                        local cube = plot:FindFirstChild("Cube.009")
                        if cube and cube:IsA("BasePart") then
                            cube.Material = Enum.Material.Neon
                            
                            local requiredRebirths = PlotConfig.getPlotRebirthRequirement(plotNumber)
                            
                            if ownedPlotsSet[plotNumber] then
                                -- White if purchased
                                cube.Color = Color3.fromRGB(255, 255, 255)
                            elseif playerRebirths < requiredRebirths then
                                -- Black if not enough rebirths
                                cube.Color = Color3.fromRGB(0, 0, 0)
                            elseif playerMoney >= PlotConfig.getPlotCost(plotNumber, playerRebirths) then
                                -- Green if can afford
                                cube.Color = Color3.fromRGB(0, 255, 0)
                            else
                                -- Darker turquoise if can't afford
                                cube.Color = Color3.fromRGB(32, 178, 170)
                            end
                        end
                    end
                end
            end
            
            -- Update tube plots
            for tubeNumber = 1, PlotConfig.TOTAL_TUBEPLOTS do
                local tubePlot = area:FindFirstChild("Buttons") and area.Buttons:FindFirstChild("TubePlot" .. tubeNumber)
                if tubePlot and tubePlot:IsA("Model") then
                    local cube = tubePlot:FindFirstChild("Cube.009")
                    if cube and cube:IsA("BasePart") then
                        cube.Material = Enum.Material.Neon
                        
                        local requiredRebirths = PlotConfig.getTubePlotRebirthRequirement(tubeNumber)
                        
                        if ownedTubesSet[tubeNumber] then
                            -- White if purchased
                            cube.Color = Color3.fromRGB(255, 255, 255)
                        elseif playerRebirths < requiredRebirths then
                            -- Black if not enough rebirths
                            cube.Color = Color3.fromRGB(0, 0, 0)
                        elseif playerMoney >= PlotConfig.getTubePlotCost(tubeNumber, playerRebirths) then
                            -- Green if can afford
                            cube.Color = Color3.fromRGB(0, 255, 0)
                        else
                            -- Darker turquoise if can't afford
                            cube.Color = Color3.fromRGB(32, 178, 170)
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