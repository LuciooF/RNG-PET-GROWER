local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DataService = require(ServerScriptService.services.DataService)
local ProductionPlotConfig = require(ReplicatedStorage.Shared.config.ProductionPlotConfig)

local PlayerService = {}
PlayerService.__index = PlayerService

local PlayerConnections = {}
local HeavenProcessingConnection = nil

-- Heaven processing configuration
local HEAVEN_PROCESS_INTERVAL = 1 -- Process 1 pet per second
local HEAVEN_PROCESS_RATE = 1 -- How many pets to process per interval

function PlayerService:OnPlayerAdded(player)
    local profile = DataService:LoadProfile(player)
    
    if profile then
        local leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
        
        local money = Instance.new("IntValue")
        money.Name = "Money"
        money.Value = profile.Data.resources.money
        money.Parent = leaderstats
        
        local rebirths = Instance.new("IntValue")
        rebirths.Name = "Rebirths"
        rebirths.Value = profile.Data.resources.rebirths
        rebirths.Parent = leaderstats
        
        local diamonds = Instance.new("IntValue")
        diamonds.Name = "Diamonds"
        diamonds.Value = profile.Data.resources.diamonds
        diamonds.Parent = leaderstats
        
        self:SetupDataSync(player, profile)
        self:SetupPlaytimeTracking(player)
        
        -- Start heaven processing if this is the first player
        if not HeavenProcessingConnection then
            self:StartHeavenProcessing()
        end
        
        self:SyncPlayerDataToClient(player)
    end
end

function PlayerService:OnPlayerRemoving(player)
    if PlayerConnections[player] then
        PlayerConnections[player]:Disconnect()
        PlayerConnections[player] = nil
    end
    
    DataService:ReleaseProfile(player)
end

function PlayerService:SetupDataSync(player, profile)
    local function updateLeaderstats()
        local leaderstats = player:FindFirstChild("leaderstats")
        local currentData = DataService:GetPlayerData(player)
        if leaderstats and currentData then
            local money = leaderstats:FindFirstChild("Money")
            local rebirths = leaderstats:FindFirstChild("Rebirths")
            local diamonds = leaderstats:FindFirstChild("Diamonds")
            
            if money then
                money.Value = currentData.resources.money
            end
            
            if rebirths then
                rebirths.Value = currentData.resources.rebirths
            end
            
            if diamonds then
                diamonds.Value = currentData.resources.diamonds
            end
        end
    end
    
    local connection = RunService.Heartbeat:Connect(function()
        if not player.Parent then
            return
        end
        
        updateLeaderstats()
    end)
    
    PlayerConnections[player] = connection
end

function PlayerService:SetupPlaytimeTracking(player)
    local startTime = tick()
    
    local connection = RunService.Heartbeat:Connect(function()
        if not player.Parent then
            return
        end
        
        local currentTime = tick()
        local deltaTime = currentTime - startTime
        startTime = currentTime
        
        DataService:UpdatePlaytime(player, deltaTime)
    end)
    
    if PlayerConnections[player] then
        PlayerConnections[player]:Disconnect()
    end
    PlayerConnections[player] = connection
end

function PlayerService:SyncPlayerDataToClient(player)
    local playerData = DataService:GetPlayerData(player)
    if playerData then
        local remoteEvent = ReplicatedStorage:WaitForChild("PlayerDataSync", 5)
        if remoteEvent then
            remoteEvent:FireClient(player, playerData)
        end
    end
end

function PlayerService:GiveMoney(player, amount)
    local success = DataService:AddMoney(player, amount)
    if success then
        self:SyncPlayerDataToClient(player)
    end
    return success
end

function PlayerService:TakeMoney(player, amount)
    local success = DataService:SpendMoney(player, amount)
    if success then
        self:SyncPlayerDataToClient(player)
    end
    return success
end

function PlayerService:GiveDiamonds(player, amount)
    local success = DataService:AddDiamonds(player, amount)
    if success then
        self:SyncPlayerDataToClient(player)
    end
    return success
end

function PlayerService:TakeDiamonds(player, amount)
    local success = DataService:SpendDiamonds(player, amount)
    if success then
        self:SyncPlayerDataToClient(player)
    end
    return success
end

function PlayerService:AddPetToPlayer(player, petData)
    local success = DataService:AddPet(player, petData)
    if success then
        self:SyncPlayerDataToClient(player)
    end
    return success
end

-- Alias for consistency with server remote handler
function PlayerService:AddPetToCollection(player, petData)
    return self:AddPetToPlayer(player, petData)
end

function PlayerService:CheckAndAnnounceDiscovery(player, petData)
    local combination = petData.name .. "_" .. (petData.aura or "none")
    
    
    -- Check if this is a new discovery for this player
    local hasDiscovered = DataService:HasDiscoveredCombination(player, combination)
    
    if not hasDiscovered then
        -- Add to discovered combinations
        local success = DataService:AddDiscoveredCombination(player, combination)
        if success then
            -- Send server-wide announcement
            self:AnnounceDiscovery(player, petData)
            return true
        else
        end
    else
    end
    return false
end

function PlayerService:AnnounceDiscovery(player, petData)
    local TextService = game:GetService("TextService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    local petName = petData.name
    local auraName = petData.aura or "none"
    local playerName = player.Name
    
    -- Calculate rarity chance (placeholder for now)
    local chance = "1 in 100"
    if auraName == "diamond" then
        chance = "1 in 200" -- Diamond is rarer
    end
    
    -- Create base message
    local baseMessage = playerName .. " has discovered " .. auraName:gsub("^%l", string.upper) .. " " .. petName .. " - " .. chance .. " chance!"
    
    -- Filter the message using TextService
    local success, filteredMessage = pcall(function()
        return TextService:FilterStringAsync(baseMessage, player.UserId):GetNonChatStringForBroadcastAsync()
    end)
    
    if success then
        -- Send to all players via a remote event
        local announcementEvent = ReplicatedStorage:WaitForChild("DiscoveryAnnouncement")
        
        -- Send announcement with aura color data
        local announcementData = {
            message = filteredMessage,
            auraName = auraName,
            petName = petName,
            playerName = playerName
        }
        
        announcementEvent:FireAllClients(announcementData)
    else
        warn("Announcement: Failed to filter discovery message:", baseMessage)
        warn("Error:", filteredMessage)
    end
end

function PlayerService:RemovePetFromPlayer(player, petId)
    local success = DataService:RemovePet(player, petId)
    if success then
        self:SyncPlayerDataToClient(player)
    end
    return success
end

function PlayerService:BuyPlotForPlayer(player, plotId)
    local success = DataService:AddPlot(player, plotId)
    if success then
        self:SyncPlayerDataToClient(player)
    end
    return success
end

function PlayerService:BuyProductionPlotForPlayer(player, plotId)
    local success = DataService:AddProductionPlot(player, plotId)
    if success then
        self:SyncPlayerDataToClient(player)
    end
    return success
end

function PlayerService:AddBoostToPlayer(player, boostData)
    local success = DataService:AddBoost(player, boostData)
    if success then
        self:SyncPlayerDataToClient(player)
    end
    return success
end

function PlayerService:GivePlayerRebirths(player, amount)
    local success = DataService:AddRebirths(player, amount)
    if success then
        self:SyncPlayerDataToClient(player)
    end
    return success
end

function PlayerService:PerformPlayerRebirth(player)
    local success = DataService:PerformRebirth(player)
    if success then
        self:SyncPlayerDataToClient(player)
    end
    return success
end

function PlayerService:ResetPlayerData(player)
    local success = DataService:ResetPlayerData(player)
    if success then
        self:SyncPlayerDataToClient(player)
    end
    return success
end

function PlayerService:AssignPet(player, petUniqueId)
    local success = DataService:AssignPet(player, petUniqueId)
    return success
end

function PlayerService:UnassignPet(player, petUniqueId)
    local success = DataService:UnassignPet(player, petUniqueId)
    return success
end

function PlayerService:SendPetsToHeaven(player, requestData)
    if not requestData or not requestData.pets or not requestData.expectedValue then
        warn("PlayerService:SendPetsToHeaven - Invalid request data from", player.Name)
        return false
    end
    
    print(string.format("PlayerService:SendPetsToHeaven - %s wants to sell %d pets for %d money", 
        player.Name, #requestData.pets, requestData.expectedValue))
    
    local success, actualValue = DataService:SellUnassignedPets(player, requestData.pets, requestData.expectedValue)
    
    if success then
        print(string.format("PlayerService:SendPetsToHeaven - Successfully sold pets for %d money", actualValue))
        self:SyncPlayerDataToClient(player)
    else
        warn("PlayerService:SendPetsToHeaven - Failed to sell pets for", player.Name)
    end
    
    return success
end

function PlayerService:StartHeavenProcessing()
    if HeavenProcessingConnection then
        return -- Already running
    end
    
    print("PlayerService: Starting heaven processing system")
    
    local lastProcessTime = tick()
    
    HeavenProcessingConnection = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        
        -- Check if enough time has passed for processing
        if currentTime - lastProcessTime >= HEAVEN_PROCESS_INTERVAL then
            lastProcessTime = currentTime
            self:ProcessHeavenQueues()
        end
    end)
end

function PlayerService:ProcessHeavenQueues()
    for player, profile in pairs(DataService:GetAllProfiles()) do
        if profile and profile.Data.heavenQueue and #profile.Data.heavenQueue.pets > 0 then
            self:ProcessPlayerHeavenQueue(player, profile)
        end
    end
end

function PlayerService:ProcessPlayerHeavenQueue(player, profile)
    local heavenQueue = profile.Data.heavenQueue
    if not heavenQueue or #heavenQueue.pets == 0 then
        return
    end
    
    -- Calculate processing rate based on production plots owned using new speed system
    local boughtProductionPlots = profile.Data.boughtProductionPlots or {}
    local totalProcessingRate = ProductionPlotConfig:CalculateTotalProcessingRate(boughtProductionPlots)
    
    -- Handle fractional processing rates properly
    local baseRate = math.floor(totalProcessingRate)
    local fractionalPart = totalProcessingRate - baseRate
    
    -- Add fractional chance (e.g., if rate is 2.5, process 2 pets + 50% chance for 1 more)
    local actualProcessingRate = baseRate
    if fractionalPart > 0 and math.random() < fractionalPart then
        actualProcessingRate = actualProcessingRate + 1
    end
    
    local petsToProcess = math.min(actualProcessingRate, #heavenQueue.pets)
    local totalMoneyGained = 0
    
    -- Process pets from the front of the queue
    for i = 1, petsToProcess do
        local processedPet = table.remove(heavenQueue.pets, 1) -- Remove from front
        if processedPet then
            totalMoneyGained = totalMoneyGained + processedPet.value
            
            -- Trigger heaven animation on client
            self:TriggerHeavenAnimation(player, processedPet)
            
            print(string.format("PlayerService: Processed %s for %d money (%s)", 
                processedPet.name, processedPet.value, player.Name))
        end
    end
    
    if totalMoneyGained > 0 then
        -- Add money to player
        profile.Data.resources.money = profile.Data.resources.money + totalMoneyGained
        
        -- Update leaderstats
        if player and player.Parent and player:FindFirstChild("leaderstats") then
            local moneyValue = player.leaderstats:FindFirstChild("Money")
            if moneyValue then
                moneyValue.Value = profile.Data.resources.money
            end
        end
        
        -- Sync updated data to client
        self:SyncPlayerDataToClient(player)
        
        print(string.format("PlayerService: %s gained %d money from heaven processing (%d pets processed, %d production plots, %d pets remaining in queue)", 
            player.Name, totalMoneyGained, petsToProcess, #boughtProductionPlots, #heavenQueue.pets))
    end
    
    -- Update last process time
    heavenQueue.lastProcessTime = tick()
end

function PlayerService:TriggerHeavenAnimation(player, processedPet)
    -- Send heaven animation trigger to specific player
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local heavenAnimation = remotes:FindFirstChild("HeavenAnimation")
        if heavenAnimation then
            -- Send pet data for animation
            local animationData = {
                petId = processedPet.id,
                petName = processedPet.name,
                aura = processedPet.aura,
                size = processedPet.size,
                value = processedPet.value,
                assetPath = processedPet.assetPath or ("Pets/" .. processedPet.name) -- Fallback path construction
            }
            
            heavenAnimation:FireClient(player, animationData)
        end
    end
end

function PlayerService:StopHeavenProcessing()
    if HeavenProcessingConnection then
        HeavenProcessingConnection:Disconnect()
        HeavenProcessingConnection = nil
        print("PlayerService: Stopped heaven processing system")
    end
end

return PlayerService