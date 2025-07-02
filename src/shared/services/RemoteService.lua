local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteService = {}

function RemoteService:CreateRemotes()
    local remoteFolder = Instance.new("Folder")
    remoteFolder.Name = "Remotes"
    remoteFolder.Parent = ReplicatedStorage
    
    local playerDataSync = Instance.new("RemoteEvent")
    playerDataSync.Name = "PlayerDataSync"
    playerDataSync.Parent = ReplicatedStorage
    
    local buyPlot = Instance.new("RemoteEvent")
    buyPlot.Name = "BuyPlot"
    buyPlot.Parent = remoteFolder
    
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
    
    print("Remotes created successfully")
end

return RemoteService