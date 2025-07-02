local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local PlayerService = require(ServerScriptService.services.PlayerService)
local AreaService = require(ServerScriptService.services.AreaService)
local PlotService = require(ServerScriptService.services.PlotService)
local AssetService = require(ServerScriptService.services.AssetService)

-- Create remotes directly here instead of requiring from ReplicatedStorage
local function createRemotes()
    local remoteFolder = Instance.new("Folder")
    remoteFolder.Name = "Remotes"
    remoteFolder.Parent = ReplicatedStorage
    
    local playerDataSync = Instance.new("RemoteEvent")
    playerDataSync.Name = "PlayerDataSync"
    playerDataSync.Parent = ReplicatedStorage
    
    local buyPlot = Instance.new("RemoteEvent")
    buyPlot.Name = "BuyPlot"
    buyPlot.Parent = remoteFolder
    
    local collectPet = Instance.new("RemoteEvent")
    collectPet.Name = "CollectPet"
    collectPet.Parent = remoteFolder
    
    local sellPet = Instance.new("RemoteEvent")
    sellPet.Name = "SellPet"
    sellPet.Parent = remoteFolder
    
    local equipCompanion = Instance.new("RemoteEvent")
    equipCompanion.Name = "EquipCompanion"
    equipCompanion.Parent = remoteFolder
    
    local unequipCompanion = Instance.new("RemoteEvent")
    unequipCompanion.Name = "UnequipCompanion"
    unequipCompanion.Parent = remoteFolder
    
    local buyBoost = Instance.new("RemoteEvent")
    buyBoost.Name = "BuyBoost"
    buyBoost.Parent = remoteFolder
    
    -- Debug remotes
    local debugAddMoney = Instance.new("RemoteEvent")
    debugAddMoney.Name = "DebugAddMoney"
    debugAddMoney.Parent = remoteFolder
    
    local debugAddDiamonds = Instance.new("RemoteEvent")
    debugAddDiamonds.Name = "DebugAddDiamonds"
    debugAddDiamonds.Parent = remoteFolder
    
    local debugAddRebirths = Instance.new("RemoteEvent")
    debugAddRebirths.Name = "DebugAddRebirths"
    debugAddRebirths.Parent = remoteFolder
    
    local debugResetData = Instance.new("RemoteEvent")
    debugResetData.Name = "DebugResetData"
    debugResetData.Parent = remoteFolder
    
    -- Area assignment sync
    local areaAssignmentSync = Instance.new("RemoteEvent")
    areaAssignmentSync.Name = "AreaAssignmentSync"
    areaAssignmentSync.Parent = ReplicatedStorage
    
    -- Discovery announcement remote
    local discoveryAnnouncement = Instance.new("RemoteEvent")
    discoveryAnnouncement.Name = "DiscoveryAnnouncement"
    discoveryAnnouncement.Parent = ReplicatedStorage
    
    -- Asset loading remote function
    local loadAssetRemote = Instance.new("RemoteFunction")
    loadAssetRemote.Name = "LoadAsset"
    loadAssetRemote.Parent = remoteFolder
    
end

createRemotes()

-- Initialize AssetService (asset loading and caching)
AssetService:Initialize()

-- Initialize AreaService (create all player areas)
AreaService:Initialize()

-- Initialize PlotService (handle plot purchases)
PlotService:Initialize()

-- Preload common assets
local PetConfig = require(ReplicatedStorage.Shared.config.PetConfig)
local assetsToPreload = {}
for petId, petData in pairs(PetConfig.PETS) do
    table.insert(assetsToPreload, petData.assetId)
end
AssetService:PreloadAssets(assetsToPreload)

Players.PlayerAdded:Connect(function(player)
    PlayerService:OnPlayerAdded(player)
    
    -- Assign an area to the player and teleport them there
    local areaId, areaData = AreaService:AssignAreaToPlayer(player)
    if areaId then
        -- Wait a moment for character to load
        player.CharacterAdded:Connect(function(character)
            wait(1) -- Give character time to fully load
            AreaService:TeleportPlayerToArea(player, areaId)
            -- Sync area assignments to this player after they spawn
            AreaService:SyncAreaAssignmentsToPlayer(player)
        end)
        
        -- If character already exists, teleport immediately
        if player.Character then
            wait(1)
            AreaService:TeleportPlayerToArea(player, areaId)
            AreaService:SyncAreaAssignmentsToPlayer(player)
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    PlayerService:OnPlayerRemoving(player)
    
    -- Release the player's area
    AreaService:ReleaseAreaFromPlayer(player)
end)

-- Remote handlers
local function setupRemoteHandlers()
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    
    -- Pet collection handler
    remotes.CollectPet.OnServerEvent:Connect(function(player, petData)
        
        -- Validate pet data
        if not petData or not petData.name or not petData.rarity then
            warn("Invalid pet data received from", player.Name)
            return
        end
        
        -- Add timestamp and unique ID to pet (only store serializable data)
        local collectedPet = {
            id = petData.petId,
            name = petData.name,
            rarity = petData.rarity,
            value = petData.value or 1,
            collectedAt = tick(),
            plotId = petData.plotId,
            aura = petData.aura or "none"
            -- Note: Don't store auraData as it contains Color3 objects that can't be serialized
        }
        
        -- Add pet to player's collection
        local success = PlayerService:AddPetToCollection(player, collectedPet)
        if success then
            
            -- Check for new discovery and announce if needed
            PlayerService:CheckAndAnnounceDiscovery(player, collectedPet)
            
            -- Optionally give money reward
            PlayerService:GiveMoney(player, collectedPet.value)
        else
            warn("Failed to add pet to", player.Name, "'s collection")
        end
    end)
    
    -- Debug remote handlers
    remotes.DebugAddMoney.OnServerEvent:Connect(function(player)
        PlayerService:GiveMoney(player, 1000)
    end)
    
    remotes.DebugAddDiamonds.OnServerEvent:Connect(function(player)
        PlayerService:GiveDiamonds(player, 1000)
    end)
    
    remotes.DebugAddRebirths.OnServerEvent:Connect(function(player)
        PlayerService:GivePlayerRebirths(player, 1)
    end)
    
    remotes.DebugResetData.OnServerEvent:Connect(function(player)
        PlayerService:ResetPlayerData(player)
    end)
    
    -- Asset loading handler
    remotes.LoadAsset.OnServerInvoke = function(player, assetId)
        
        -- Load or get cached asset
        local asset = AssetService:LoadAsset(assetId)
        if asset then
            return asset
        else
            warn("Server: Failed to load asset", assetId, "for", player.Name)
            return nil
        end
    end
end

setupRemoteHandlers()

