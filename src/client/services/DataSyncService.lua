local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Store = require(ReplicatedStorage:WaitForChild("store"))
local PlayerActions = require(ReplicatedStorage:WaitForChild("store"):WaitForChild("actions"):WaitForChild("PlayerActions"))

local DataSyncService = {}

local player = Players.LocalPlayer

function DataSyncService:Initialize()
    local playerDataSync = ReplicatedStorage:WaitForChild("PlayerDataSync")
    
    playerDataSync.OnClientEvent:Connect(function(playerData)
        self:SyncPlayerData(playerData)
    end)
    
    print("DataSyncService initialized")
end

function DataSyncService:SyncPlayerData(playerData)
    if not playerData then
        warn("Received nil player data")
        return
    end
    
    -- Debug logging for slot expansion
    if playerData.maxSlots then
        print(string.format("DataSyncService: Received maxSlots: %d", playerData.maxSlots))
    else
        print("DataSyncService: No maxSlots field received")
    end
    
    Store:dispatch(PlayerActions.setResources(
        playerData.resources.money,
        playerData.resources.rebirths,
        playerData.resources.diamonds
    ))
    
    for _, plotId in ipairs(playerData.boughtPlots) do
        Store:dispatch(PlayerActions.addPlot(plotId))
    end
    
    for _, pet in ipairs(playerData.ownedPets) do
        Store:dispatch(PlayerActions.addPet(pet))
    end
    
    for _, companion in ipairs(playerData.companionPets) do
        Store:dispatch(PlayerActions.equipCompanion(companion))
    end
    
    for _, boost in ipairs(playerData.activeBoosts) do
        Store:dispatch(PlayerActions.addBoost(boost))
    end
    
    Store:dispatch(PlayerActions.updateStats(playerData.stats))
    Store:dispatch(PlayerActions.updateSettings(playerData.settings))
    
    -- Sync maxSlots if present
    if playerData.maxSlots then
        Store:dispatch(PlayerActions.setMaxSlots(playerData.maxSlots))
        print(string.format("DataSyncService: Set maxSlots to %d", playerData.maxSlots))
    end
    
    print("Player data synced to client store")
end

return DataSyncService