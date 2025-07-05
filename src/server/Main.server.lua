local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

local PlayerService = require(ServerScriptService.services.PlayerService)
local AreaService = require(ServerScriptService.services.AreaService)
local PlotService = require(ServerScriptService.services.PlotService)
local AssetService = require(ServerScriptService.services.AssetService)
local GamepassService = require(ServerScriptService.services.GamepassService)
local DeveloperProductService = require(ServerScriptService.services.DeveloperProductService)
local PetMergeService = require(ServerScriptService.services.PetMergeService)
local CodesManager = require(ServerScriptService.modules.CodesManager)

-- Rate limiting for pet collection - allow burst of 10 pets per 0.5 seconds
local playerCollectionData = {} -- {[playerId] = {lastReset = time, count = number}}

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
    
    local buyProductionPlot = Instance.new("RemoteEvent")
    buyProductionPlot.Name = "BuyProductionPlot"
    buyProductionPlot.Parent = remoteFolder
    
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
    
    -- Response remotes for rollback mechanism
    local assignPetResponse = Instance.new("RemoteEvent")
    assignPetResponse.Name = "AssignPetResponse"
    assignPetResponse.Parent = remoteFolder
    
    local unassignPetResponse = Instance.new("RemoteEvent")
    unassignPetResponse.Name = "UnassignPetResponse"
    unassignPetResponse.Parent = remoteFolder
    
    -- State reconciliation remote
    local requestStateReconciliation = Instance.new("RemoteEvent")
    requestStateReconciliation.Name = "RequestStateReconciliation"
    requestStateReconciliation.Parent = remoteFolder
    
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
    
    local debugBuyProductionPlot = Instance.new("RemoteEvent")
    debugBuyProductionPlot.Name = "DebugBuyProductionPlot"
    debugBuyProductionPlot.Parent = remoteFolder
    
    -- Developer product purchase
    local promptProductPurchase = Instance.new("RemoteEvent")
    promptProductPurchase.Name = "PromptProductPurchase"
    promptProductPurchase.Parent = remoteFolder
    
    -- Rebirth system
    local playerRebirth = Instance.new("RemoteEvent")
    playerRebirth.Name = "PlayerRebirth"
    playerRebirth.Parent = remoteFolder
    
    local sendPetsToHeaven = Instance.new("RemoteEvent")
    sendPetsToHeaven.Name = "SendPetsToHeaven"
    sendPetsToHeaven.Parent = remoteFolder
    
    local heavenAnimation = Instance.new("RemoteEvent")
    heavenAnimation.Name = "HeavenAnimation"
    heavenAnimation.Parent = remoteFolder
    
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
    
    -- Pet assignment remotes
    local assignPet = Instance.new("RemoteEvent")
    assignPet.Name = "AssignPet"
    assignPet.Parent = remoteFolder
    
    local unassignPet = Instance.new("RemoteEvent")
    unassignPet.Name = "UnassignPet"
    unassignPet.Parent = remoteFolder
    
    -- Gamepass and Developer Product remotes
    local gamepassSync = Instance.new("RemoteEvent")
    gamepassSync.Name = "GamepassSync"
    gamepassSync.Parent = ReplicatedStorage
    
    -- Music preference remote
    local musicPreference = Instance.new("RemoteEvent")
    musicPreference.Name = "MusicPreference"
    musicPreference.Parent = remoteFolder
    
    local gamepassPurchased = Instance.new("RemoteEvent")
    gamepassPurchased.Name = "GamepassPurchased"
    gamepassPurchased.Parent = ReplicatedStorage
    
    local developerProductPurchased = Instance.new("RemoteEvent")
    developerProductPurchased.Name = "DeveloperProductPurchased"
    developerProductPurchased.Parent = ReplicatedStorage
    
    local promptGamepassPurchase = Instance.new("RemoteEvent")
    promptGamepassPurchase.Name = "PromptGamepassPurchase"
    promptGamepassPurchase.Parent = remoteFolder
    
    local promptDeveloperProductPurchase = Instance.new("RemoteEvent")
    promptDeveloperProductPurchase.Name = "PromptDeveloperProductPurchase"
    promptDeveloperProductPurchase.Parent = remoteFolder
    
end

createRemotes()

-- Initialize collision groups for pets and players
local function initializeCollisionGroups()
    print("Server: Setting up collision groups...")
    
    -- Use modern collision group system
    PhysicsService:RegisterCollisionGroup("Pets")
    PhysicsService:RegisterCollisionGroup("Players")
    
    -- Configure collision behavior: Pets don't collide with Players
    PhysicsService:CollisionGroupSetCollidable("Pets", "Players", false)
    PhysicsService:CollisionGroupSetCollidable("Pets", "Default", true) -- Pets still collide with ground/world
    PhysicsService:CollisionGroupSetCollidable("Players", "Default", true) -- Players still collide with world
    
    print("Server: Collision groups configured - Pets and Players won't collide with each other")
end

-- Set up collision groups
initializeCollisionGroups()

-- Initialize AssetService (asset loading and caching)
AssetService:Initialize()

-- Initialize AreaService (create all player areas)
AreaService:Initialize()

-- Initialize PlotService (handle plot purchases)
PlotService:Initialize()

-- Initialize GamepassService (handle gamepass ownership and benefits)
GamepassService:Initialize()

-- Initialize DeveloperProductService (handle developer product purchases)
DeveloperProductService:Initialize()

-- Initialize PetMergeService (handle pet merging in the Lab)
PetMergeService:Initialize()

-- Initialize CodesManager (handle code redemption)
CodesManager.initialize()

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
    
    -- Pet collection handler - Server validates and generates all critical data
    remotes.CollectPet.OnServerEvent:Connect(function(player, clientPetData)
        
        -- Rate limiting check - allow burst of 10 pets per 0.5 seconds
        local now = tick()
        local playerId = tostring(player.UserId)
        
        if not playerCollectionData[playerId] then
            playerCollectionData[playerId] = {lastReset = now, count = 0}
        end
        
        local collectionData = playerCollectionData[playerId]
        
        -- Reset counter if 0.5 seconds have passed
        if now - collectionData.lastReset >= 0.5 then
            collectionData.lastReset = now
            collectionData.count = 0
        end
        
        -- Check if player has exceeded 10 collections in current window
        if collectionData.count >= 30 then
            warn("Rate limit: Too many collections from", player.Name, "- limit is 30 per 0.5 seconds")
            return
        end
        
        -- Increment collection count
        collectionData.count = collectionData.count + 1
        
        -- Validate basic client data structure
        if not clientPetData or not clientPetData.petId or not clientPetData.plotId then
            warn("Invalid pet data structure from", player.Name)
            return
        end
        
        -- SERVER-SIDE VALIDATION: Get authoritative pet data from config
        local PetConfig = require(ReplicatedStorage.Shared.config.PetConfig)
        local petConfig = PetConfig:GetPetData(clientPetData.petId)
        
        if not petConfig then
            warn("Invalid pet ID", clientPetData.petId, "from", player.Name)
            return
        end
        
        -- SERVER GENERATES ALL CRITICAL VALUES (never trust client)
        local serverPetData = {
            id = clientPetData.petId,
            uniqueId = game:GetService("HttpService"):GenerateGUID(false), -- Server-generated unique ID
            name = petConfig.name, -- From server config, not client
            rarity = petConfig.rarity, -- From server config, not client
            value = petConfig.value, -- From server config, not client
            collectedAt = tick(), -- Server timestamp
            plotId = clientPetData.plotId, -- This is acceptable from client as it's just for tracking
            aura = clientPetData.aura or "none", -- Validated below
            size = clientPetData.size or 1 -- Validated below
        }
        
        -- Validate aura and size if provided
        if serverPetData.aura ~= "none" then
            local auraData = PetConfig.AURAS[serverPetData.aura]
            if not auraData then
                warn("Invalid aura", serverPetData.aura, "from", player.Name, "- using 'none'")
                serverPetData.aura = "none"
            end
        end
        
        if serverPetData.size > 1 then
            local sizeData = PetConfig:GetSizeData(serverPetData.size)
            if not sizeData then
                warn("Invalid size", serverPetData.size, "from", player.Name, "- using size 1")
                serverPetData.size = 1
            end
        end
        
        -- Calculate final value with aura/size multipliers (server-authoritative)
        local finalValue = PetConfig:CalculatePetValue(serverPetData.id, serverPetData.aura, serverPetData.size)
        serverPetData.value = finalValue
        
        -- Add pet to player's collection (immediate)
        local success, reason = PlayerService:AddPetToCollection(player, serverPetData)
        if success then
            -- Give 1 diamond reward for pet collection
            PlayerService:GiveDiamonds(player, 1)
            
            -- Do discovery check and announcement asynchronously to reduce delay
            task.spawn(function()
                PlayerService:CheckAndAnnounceDiscovery(player, serverPetData)
            end)
        else
            warn("Failed to add pet to", player.Name, "'s collection - Reason:", reason)
            
            -- Send inventory full notification to client
            if reason == "inventory_full" then
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if remotes then
                    local inventoryFullRemote = remotes:FindFirstChild("InventoryFull")
                    if not inventoryFullRemote then
                        inventoryFullRemote = Instance.new("RemoteEvent")
                        inventoryFullRemote.Name = "InventoryFull"
                        inventoryFullRemote.Parent = remotes
                    end
                    inventoryFullRemote:FireClient(player)
                end
            end
        end
    end)
    
    -- Pet assignment handlers with rollback response
    remotes.AssignPet.OnServerEvent:Connect(function(player, petUniqueId)
        if not petUniqueId or petUniqueId == "" then
            warn("Invalid pet unique ID received from", player.Name, "- ID:", petUniqueId)
            -- Send rollback signal to client
            remotes.AssignPetResponse:FireClient(player, false, petUniqueId, "Invalid pet ID")
            return
        end
        
        local success, reason = PlayerService:AssignPet(player, petUniqueId)
        if success then
            PlayerService:SyncPlayerDataToClient(player)
            -- Confirm success to client (prevents rollback)
            remotes.AssignPetResponse:FireClient(player, true, petUniqueId, "Pet assigned successfully")
        else
            warn("Failed to assign pet for", player.Name, "- ID:", petUniqueId, "- Reason:", reason)
            -- Send rollback signal to client
            remotes.AssignPetResponse:FireClient(player, false, petUniqueId, reason or "Assignment failed")
        end
    end)
    
    remotes.UnassignPet.OnServerEvent:Connect(function(player, petUniqueId)
        if not petUniqueId or petUniqueId == "" then
            warn("Invalid pet unique ID received from", player.Name, "- ID:", petUniqueId)
            -- Send rollback signal to client
            remotes.UnassignPetResponse:FireClient(player, false, petUniqueId, "Invalid pet ID")
            return
        end
        
        local success, reason = PlayerService:UnassignPet(player, petUniqueId)
        if success then
            PlayerService:SyncPlayerDataToClient(player)
            -- Confirm success to client (prevents rollback)
            remotes.UnassignPetResponse:FireClient(player, true, petUniqueId, "Pet unassigned successfully")
        else
            warn("Failed to unassign pet for", player.Name, "- ID:", petUniqueId, "- Reason:", reason)
            -- Send rollback signal to client
            remotes.UnassignPetResponse:FireClient(player, false, petUniqueId, reason or "Unassignment failed")
        end
    end)
    
    -- State reconciliation handler
    remotes.RequestStateReconciliation.OnServerEvent:Connect(function(player)
        -- Send complete authoritative state to client for reconciliation
        PlayerService:SyncPlayerDataToClient(player)
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
    
    -- Rebirth system handler
    remotes.PlayerRebirth.OnServerEvent:Connect(function(player)
        PlayerService:PerformPlayerRebirth(player)
    end)
    
    remotes.DebugResetData.OnServerEvent:Connect(function(player)
        PlayerService:ResetPlayerData(player)
    end)
    
    remotes.DebugBuyProductionPlot.OnServerEvent:Connect(function(player)
        PlayerService:BuyProductionPlot(player, 1) -- Buy production plot 1
    end)
    
    -- Developer product purchase prompt handler
    remotes.PromptProductPurchase.OnServerEvent:Connect(function(player, productName)
        print(string.format("Player %s requesting to purchase product: %s", player.Name, productName))
        DeveloperProductService:PromptPurchase(player, productName)
    end)
    
    -- Send pets to heaven handler
    remotes.SendPetsToHeaven.OnServerEvent:Connect(function(player, requestData)
        PlayerService:SendPetsToHeaven(player, requestData)
    end)
    
    -- Gamepass purchase prompt handler
    remotes.PromptGamepassPurchase.OnServerEvent:Connect(function(player, gamepassName)
        -- Get gamepass data
        local GamepassConfig = require(ReplicatedStorage.Shared.config.GamepassConfig)
        local gamepassData = GamepassConfig:GetGamepassByName(gamepassName)
        
        if not gamepassData then
            warn(string.format("Unknown gamepass: %s requested by %s", gamepassName, player.Name))
            return
        end
        
        -- Prompt purchase
        local MarketplaceService = game:GetService("MarketplaceService")
        local success, errorMessage = pcall(function()
            MarketplaceService:PromptGamePassPurchase(player, gamepassData.id)
        end)
        
        if not success then
            warn(string.format("Failed to prompt gamepass purchase for %s: %s", player.Name, errorMessage))
        else
            print(string.format("Prompted %s to purchase gamepass %s", player.Name, gamepassName))
        end
    end)
    
    -- Developer product purchase prompt handler
    remotes.PromptDeveloperProductPurchase.OnServerEvent:Connect(function(player, productName)
        local success = DeveloperProductService:PromptPurchase(player, productName)
        if not success then
            warn(string.format("Failed to prompt developer product purchase %s for %s", productName, player.Name))
        end
    end)
    
    -- Music preference handler
    remotes.MusicPreference.OnServerEvent:Connect(function(player, musicEnabled)
        if typeof(musicEnabled) ~= "boolean" then
            warn("Invalid music preference from", player.Name, "- expected boolean, got:", typeof(musicEnabled))
            return
        end
        
        -- Update player's music preference in their settings
        local success = PlayerService:UpdateMusicPreference(player, musicEnabled)
        if success then
            print(string.format("Updated music preference for %s: %s", player.Name, tostring(musicEnabled)))
        else
            warn(string.format("Failed to update music preference for %s", player.Name))
        end
    end)
    
end

setupRemoteHandlers()

