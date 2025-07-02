local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlotConfig = require(ReplicatedStorage.Shared.config.PlotConfig)
local DataService = require(ServerScriptService.services.DataService)
local PlayerService = require(ServerScriptService.services.PlayerService)

local PlotService = {}
PlotService.__index = PlotService

function PlotService:Initialize()
    print("PlotService: Initializing...")
    
    -- Set up plot purchase remote
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local buyPlotRemote = remotes:FindFirstChild("BuyPlot")
    
    if buyPlotRemote then
        buyPlotRemote.OnServerEvent:Connect(function(player, plotId)
            self:HandlePlotPurchase(player, plotId)
        end)
        print("PlotService: Connected to BuyPlot remote")
    else
        warn("PlotService: BuyPlot remote not found!")
    end
    
    print("PlotService: Initialized successfully")
end

function PlotService:HandlePlotPurchase(player, plotId)
    print(string.format("PlotService: %s attempting to buy plot %d", player.Name, plotId))
    
    -- Validate plot ID
    local plotData = PlotConfig:GetPlotData(plotId)
    if not plotData then
        warn(string.format("PlotService: Invalid plot ID %d", plotId))
        return
    end
    
    -- Get player data
    local playerData = DataService:GetPlayerData(player)
    if not playerData then
        warn(string.format("PlotService: No player data found for %s", player.Name))
        return
    end
    
    -- Check if player already owns this plot
    for _, ownedPlotId in pairs(playerData.boughtPlots or {}) do
        if ownedPlotId == plotId then
            print(string.format("PlotService: %s already owns plot %d", player.Name, plotId))
            return
        end
    end
    
    -- Check if player has enough rebirths
    local playerRebirths = playerData.resources.rebirths or 0
    if playerRebirths < plotData.rebirthsRequired then
        print(string.format("PlotService: %s needs %d rebirths for plot %d (has %d)", 
            player.Name, plotData.rebirthsRequired, plotId, playerRebirths))
        return
    end
    
    -- Check if player has enough money
    local playerMoney = playerData.resources.money or 0
    if playerMoney < plotData.price then
        print(string.format("PlotService: %s needs %d money for plot %d (has %d)", 
            player.Name, plotData.price, plotId, playerMoney))
        return
    end
    
    -- Purchase the plot
    local success = self:PurchasePlot(player, plotId, plotData.price)
    if success then
        print(string.format("PlotService: %s successfully purchased plot %d for %d money", 
            player.Name, plotId, plotData.price))
    else
        warn(string.format("PlotService: Failed to process plot purchase for %s", player.Name))
    end
end

function PlotService:PurchasePlot(player, plotId, price)
    -- Deduct money
    local moneyDeducted = PlayerService:TakeMoney(player, price)
    if not moneyDeducted then
        return false
    end
    
    -- Add plot to player's owned plots
    local plotAdded = PlayerService:BuyPlotForPlayer(player, plotId)
    if not plotAdded then
        -- Refund money if plot addition failed
        PlayerService:GiveMoney(player, price)
        return false
    end
    
    return true
end

function PlotService:GetPlayerPlots(player)
    local playerData = DataService:GetPlayerData(player)
    if playerData then
        return playerData.boughtPlots or {}
    end
    return {}
end

function PlotService:DoesPlayerOwnPlot(player, plotId)
    local ownedPlots = self:GetPlayerPlots(player)
    for _, ownedPlotId in pairs(ownedPlots) do
        if ownedPlotId == plotId then
            return true
        end
    end
    return false
end

return PlotService