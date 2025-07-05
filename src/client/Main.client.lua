local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

print("Main.client: Starting initialization at", tick())

-- Wait for critical systems to be available
print("Main.client: Waiting for Packages...")
local Packages = ReplicatedStorage:WaitForChild("Packages")
print("Main.client: Waiting for React...")
local React = require(Packages.react)
local ReactRoblox = require(Packages["react-roblox"])
print("Main.client: Waiting for Store...")
local Store = require(ReplicatedStorage.store)

-- Pre-load and verify asset system
print("Main.client: Pre-loading asset system...")
local assets = require(ReplicatedStorage.assets)
if assets._debug then
    print("Main.client: Asset system loaded, checking status...")
    assets._debug.printStatus()
else
    warn("Main.client: Asset system missing debug functions!")
end

-- Pre-load critical UI assets to prevent invisible buttons
print("Main.client: Pre-loading critical UI assets...")
local SafeAssetLoader = require(ReplicatedStorage.utils.SafeAssetLoader)
SafeAssetLoader.preloadCriticalAssets()


-- Load UI components (these depend on assets)
print("Main.client: Loading UI components...")
local TopStats = require(script.Parent.components.TopStats)
print("Main.client: ✓ TopStats loaded")
local DebugUI = require(script.Parent.components.DebugUI)
print("Main.client: ✓ DebugUI loaded")
local SideButtons = require(script.Parent.components.SideButtons)
print("Main.client: ✓ SideButtons loaded")
local MusicButton = require(script.Parent.components.MusicButton)
print("Main.client: ✓ MusicButton loaded")
local PetInventoryPanel = require(script.Parent.components.PetInventoryPanel)
print("Main.client: ✓ PetInventoryPanel loaded")
local RebirthPanel = require(script.Parent.components.RebirthPanel)
print("Main.client: ✓ RebirthPanel loaded")
local ShopPanel = require(script.Parent.components.ShopPanel)
print("Main.client: ✓ ShopPanel loaded")
local RebirthAnimationEffect = require(script.Parent.components.RebirthAnimationEffect)
print("Main.client: ✓ RebirthAnimationEffect loaded")
local RewardsPanel = require(script.Parent.components.RewardsPanel)
print("Main.client: ✓ RewardsPanel loaded")
local CodesButton = require(script.Parent.components.CodesButton)
print("Main.client: ✓ CodesButton loaded")
local CodesPanel = require(script.Parent.components.CodesPanel)
print("Main.client: ✓ CodesPanel loaded")
local FriendsPanel = require(script.Parent.components.FriendsPanel)
print("Main.client: ✓ FriendsPanel loaded")
local LabPanel = require(script.Parent.components.LabPanelModern)
print("Main.client: ✓ LabPanel loaded")
local ToastNotification = require(script.Parent.components.ToastNotification)
print("Main.client: ✓ ToastNotification loaded")
local RarestPetsDisplay = require(script.Parent.components.RarestPetsDisplay)
print("Main.client: ✓ RarestPetsDisplay loaded")
local AreaNameplateService = require(script.Parent.services.AreaNameplateService)
local PlotVisualsService = require(script.Parent.services.PlotVisualsService)
local ProductionPlotVisualsService = require(script.Parent.services.ProductionPlotVisualsService)
local CylinderSpawnerService = require(script.Parent.services.CylinderSpawnerService)
local PetFollowService = require(script.Parent.services.PetFollowService)
local SendHeavenService = require(script.Parent.services.SendHeavenService)
local HeavenAnimationService = require(script.Parent.services.HeavenAnimationService)
local TubeManagerService = require(script.Parent.services.TubeManagerService)
local RewardsService = require(script.Parent.RewardsService)
local CodesService = require(script.Parent.CodesService)
local ToastService = require(script.Parent.ToastService)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for remotes to be created
local playerDataSync = ReplicatedStorage:WaitForChild("PlayerDataSync")

-- Set up discovery announcement handler
spawn(function()
    local discoveryAnnouncement = ReplicatedStorage:WaitForChild("DiscoveryAnnouncement", 10)
    if discoveryAnnouncement then
        discoveryAnnouncement.OnClientEvent:Connect(function(announcementData)
            local message = announcementData.message
            local auraName = announcementData.auraName
            
            -- Send to chat using TextChatService
            task.spawn(function()
                local success, error = pcall(function()
                    local TextChatService = game:GetService("TextChatService")
                    local generalChannel = TextChatService:WaitForChild("TextChannels", 1):WaitForChild("RBXGeneral", 1)
                    
                    -- Format message with bold text and colored aura word only
                    local formattedMessage
                    if auraName == "diamond" then
                        -- Make the whole message bold, but only color the word "Diamond"
                        formattedMessage = '<b>[DISCOVERY] ' .. announcementData.playerName .. ' has discovered <font color="rgb(100,200,255)">Diamond</font> ' .. announcementData.petName .. ' - 1 in 200 chance!</b>'
                    else
                        -- For normal discoveries (None aura), just make it bold
                        formattedMessage = '<b>[DISCOVERY] ' .. message .. '</b>'
                    end
                    
                    generalChannel:DisplaySystemMessage(formattedMessage)
                end)
                
                if not success then
                    warn("Client: Failed to send to chat:", error)
                end
            end)
        end)
    else
        warn("Client: Failed to find DiscoveryAnnouncement RemoteEvent!")
    end
end)

-- Create the App component
local function App()
    -- Get initial state from Redux store
    local playerData, setPlayerData = React.useState(Store:getState().player or {
        resources = { money = 0, rebirths = 0, diamonds = 0 },
        ownedPets = {},
        companionPets = {}
    })
    
    local petInventoryVisible, setPetInventoryVisible = React.useState(false)
    local shopPanelVisible, setShopPanelVisible = React.useState(false)
    local labPanelVisible, setLabPanelVisible = React.useState(false)
    local debugUIVisible, setDebugUIVisible = React.useState(false)
    local rebirthPanelVisible, setRebirthPanelVisible = React.useState(false)
    local rebirthAnimationVisible, setRebirthAnimationVisible = React.useState(false)
    local codesPanelVisible, setCodesPanelVisible = React.useState(false)
    local friendsPanelVisible, setFriendsPanelVisible = React.useState(false)
    
    -- Toast notification state
    local toastVisible, setToastVisible = React.useState(false)
    local toastMessage, setToastMessage = React.useState("")
    
    -- Helper function to close all panels
    local function closeAllPanels()
        setPetInventoryVisible(false)
        setShopPanelVisible(false)
        setLabPanelVisible(false)
        setDebugUIVisible(false)
        setRebirthPanelVisible(false)
        setCodesPanelVisible(false)
        setFriendsPanelVisible(false)
    end
    
    -- Toast notification handler
    local function showToast(message, duration)
        setToastMessage(message)
        setToastVisible(true)
        
        -- Auto-hide after duration
        task.delay(duration or 3, function()
            setToastVisible(false)
        end)
    end
    
    -- Get actual screen size from camera viewport
    local camera = workspace.CurrentCamera
    local screenSize, setScreenSize = React.useState(camera.ViewportSize)
    
    -- Listen for viewport size changes
    React.useEffect(function()
        local connection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            setScreenSize(camera.ViewportSize)
        end)
        
        return function()
            connection:Disconnect()
        end
    end, {})
    
    -- Subscribe to Redux store changes (with memoization to prevent unnecessary updates)
    React.useEffect(function()
        local connection = Store.changed:connect(function(newState)
            local newPlayerData = newState.player or {}
            
            -- Only update if data actually changed (deep comparison for key fields)
            setPlayerData(function(prevPlayerData)
                if prevPlayerData.resources and newPlayerData.resources and
                   prevPlayerData.resources.money == newPlayerData.resources.money and
                   prevPlayerData.resources.rebirths == newPlayerData.resources.rebirths and
                   prevPlayerData.resources.diamonds == newPlayerData.resources.diamonds and
                   prevPlayerData.friendsBoost == newPlayerData.friendsBoost and
                   #(prevPlayerData.ownedPets or {}) == #(newPlayerData.ownedPets or {}) and
                   #(prevPlayerData.companionPets or {}) == #(newPlayerData.companionPets or {}) then
                    return prevPlayerData -- No change, prevent re-render
                end
                
                -- Update pet follow service only when companion pets actually changed
                local prevCompanions = prevPlayerData.companionPets or {}
                local newCompanions = newPlayerData.companionPets or {}
                if #prevCompanions ~= #newCompanions then
                    PetFollowService:UpdateAssignedPets(newPlayerData)
                else
                    -- Check if any companion changed
                    local companionsChanged = false
                    for i, prevPet in ipairs(prevCompanions) do
                        local newPet = newCompanions[i]
                        if not newPet or prevPet.uniqueId ~= newPet.uniqueId then
                            companionsChanged = true
                            break
                        end
                    end
                    if companionsChanged then
                        PetFollowService:UpdateAssignedPets(newPlayerData)
                    end
                end
                
                return newPlayerData
            end)
        end)
        
        -- Also still listen to server data sync for initial load/server updates
        local serverConnection = playerDataSync.OnClientEvent:Connect(function(data)
            if data and data.resources then
                -- This will come from server on initial load or manual syncs
                local PlayerActions = require(ReplicatedStorage.store.actions.PlayerActions)
                Store:dispatch(PlayerActions.setResources(data.resources.money, data.resources.rebirths, data.resources.diamonds))
                
                -- Set entire collections at once for better performance
                if data.ownedPets then
                    Store:dispatch(PlayerActions.setPets(data.ownedPets))
                end
                if data.companionPets then
                    Store:dispatch(PlayerActions.setCompanions(data.companionPets))
                end
                
                -- Sync maxSlots if present
                if data.maxSlots then
                    Store:dispatch(PlayerActions.setMaxSlots(data.maxSlots))
                    print(string.format("Main.client: Synced maxSlots to %d", data.maxSlots))
                end
            end
        end)
        
        return function()
            connection:disconnect()
            serverConnection:Disconnect()
        end
    end, {})
    
    -- Setup inventory full listener
    React.useEffect(function()
        local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
        if not remotes then return end
        
        local inventoryFullRemote = remotes:WaitForChild("InventoryFull", 10)
        if not inventoryFullRemote then return end
        
        local connection = inventoryFullRemote.OnClientEvent:Connect(function()
            showToast("You have the max limit of pets (1k) send them to heaven to pick more up!", 4)
        end)
        
        return function()
            connection:Disconnect()
        end
    end, {})
    
    return React.createElement("ScreenGui", {
        Name = "MainUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true
    }, {
        TopStats = React.createElement(TopStats, {
            playerData = {
                money = playerData.resources and playerData.resources.money or 0,
                rebirths = playerData.resources and playerData.resources.rebirths or 0,
                diamonds = playerData.resources and playerData.resources.diamonds or 0
            },
            screenSize = screenSize
        }),
        SideButtons = React.createElement(SideButtons, {
            screenSize = screenSize,
            onShopClick = function() 
                if shopPanelVisible then
                    setShopPanelVisible(false)
                else
                    closeAllPanels()
                    setShopPanelVisible(true)
                end
            end,
            onPetsClick = function() 
                if petInventoryVisible then
                    setPetInventoryVisible(false)
                else
                    closeAllPanels()
                    setPetInventoryVisible(true)
                end
            end,
            onLabClick = function()
                if labPanelVisible then
                    setLabPanelVisible(false)
                else
                    closeAllPanels()
                    setLabPanelVisible(true)
                end
            end,
            onRebirthClick = function() 
                if rebirthPanelVisible then
                    setRebirthPanelVisible(false)
                else
                    closeAllPanels()
                    setRebirthPanelVisible(true)
                end
            end,
            onFriendsClick = function()
                if friendsPanelVisible then
                    setFriendsPanelVisible(false)
                else
                    closeAllPanels()
                    setFriendsPanelVisible(true)
                end
            end,
            onDebugClick = function()
                if debugUIVisible then
                    setDebugUIVisible(false)
                else
                    closeAllPanels()
                    setDebugUIVisible(true)
                end
            end
        }),
        MusicButton = React.createElement(MusicButton, {
            screenSize = screenSize,
            playerData = playerData
        }),
        DebugUI = React.createElement(DebugUI, {
            visible = debugUIVisible,
            screenSize = screenSize,
            onClose = function()
                setDebugUIVisible(false)
            end
        }),
        ShopPanel = ShopPanel.create({
            visible = shopPanelVisible,
            screenSize = screenSize,
            onClose = function()
                setShopPanelVisible(false)
            end
        }),
        PetInventory = React.createElement(PetInventoryPanel, {
            playerData = {
                ownedPets = playerData.ownedPets or {},
                companionPets = playerData.companionPets or {}
            },
            visible = petInventoryVisible,
            screenSize = screenSize,
            onClose = function()
                setPetInventoryVisible(false)
            end,
            remotes = {} -- Add remotes if needed for pet actions
        }),
        LabPanel = React.createElement(LabPanel, {
            visible = labPanelVisible,
            playerData = playerData,
            screenSize = screenSize,
            onClose = function()
                setLabPanelVisible(false)
            end
        }),
        RebirthAnimationEffect = React.createElement(RebirthAnimationEffect, {
            visible = rebirthAnimationVisible,
            screenSize = screenSize,
            onComplete = function()
                setRebirthAnimationVisible(false)
            end
        }),
        RebirthPanel = React.createElement(RebirthPanel, {
            playerData = {
                money = playerData.resources and playerData.resources.money or 0,
                rebirths = playerData.resources and playerData.resources.rebirths or 0,
                diamonds = playerData.resources and playerData.resources.diamonds or 0
            },
            visible = rebirthPanelVisible,
            screenSize = screenSize,
            onClose = function()
                setRebirthPanelVisible(false)
            end,
            onRebirth = function()
                -- Fire rebirth remote event
                local remoteFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
                if remoteFolder then
                    local playerRebirth = remoteFolder:WaitForChild("PlayerRebirth", 10)
                    if playerRebirth then
                        playerRebirth:FireServer()
                        setRebirthPanelVisible(false)
                        setRebirthAnimationVisible(true)
                    else
                        warn("PlayerRebirth remote not found in Remotes folder!")
                    end
                else
                    warn("Remotes folder not found!")
                end
            end
        }),
        RewardsPanel = React.createElement(RewardsPanel, {
            screenSize = screenSize
        }),
        CodesButton = React.createElement(CodesButton, {
            screenSize = screenSize,
            onClick = function()
                if codesPanelVisible then
                    setCodesPanelVisible(false)
                else
                    closeAllPanels()
                    setCodesPanelVisible(true)
                end
            end
        }),
        CodesPanel = React.createElement(CodesPanel, {
            visible = codesPanelVisible,
            screenSize = screenSize,
            onClose = function()
                setCodesPanelVisible(false)
            end,
            remotes = {
                redeemCode = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("redeemCode"),
                clearCodes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("clearCodes")
            }
        }),
        FriendsPanel = React.createElement(FriendsPanel, {
            visible = friendsPanelVisible,
            screenSize = screenSize,
            playerData = playerData,
            onClose = function()
                setFriendsPanelVisible(false)
            end
        }),
        ToastNotification = React.createElement(ToastNotification, {
            visible = toastVisible,
            message = toastMessage,
            screenSize = screenSize,
            onComplete = function()
                setToastVisible(false)
            end
        }),
        RarestPetsDisplay = React.createElement(RarestPetsDisplay, {
            playerData = {
                ownedPets = playerData.ownedPets or {}
            },
            screenSize = screenSize
        })
    })
end

local root = ReactRoblox.createRoot(playerGui)
root:render(React.createElement(App))

-- Initialize area nameplate service
AreaNameplateService:Initialize()

-- Initialize plot visuals service
PlotVisualsService:Initialize()

-- Initialize production plot visuals service
ProductionPlotVisualsService:Initialize()

-- Initialize cylinder spawner service
CylinderSpawnerService:Initialize()

-- Initialize pet follow service
PetFollowService:Initialize()

-- Initialize send heaven service
SendHeavenService:Initialize()

-- Initialize heaven animation service
HeavenAnimationService:Initialize()

-- Initialize tube manager service
TubeManagerService:Initialize()

-- Initialize rewards service
RewardsService.initialize()

-- Initialize codes service with remotes
local remotes = {
    redeemCode = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("redeemCode"),
    clearCodes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("clearCodes")
}
CodesService.initialize(remotes)

-- Initialize server response handler for rollback mechanism
local ServerResponseHandler = require(script.Parent.services.ServerResponseHandler)
ServerResponseHandler:Initialize()

-- Initialize state reconciliation service
local StateReconciliationService = require(script.Parent.services.StateReconciliationService)
StateReconciliationService:Initialize()

-- Final asset loading verification (async, non-blocking)
print("Main.client: Final asset loading verification...")
task.spawn(function()
    task.wait(1) -- Check stats after 1 second, but don't block startup
    local stats = SafeAssetLoader.getCacheStats()
    print(string.format("Main.client: Asset cache stats - Cached: %d, Loading: %d", stats.cached, stats.loading))
    
    if assets._debug then
        print("Main.client: Final asset system status:")
        assets._debug.printStatus()
    end
end)

-- Set up player collision group for proper pet collision handling
local function setupPlayerCollisionGroup()
    -- Set player character to "Players" collision group using modern property approach
    local function setPlayerCollisionGroup(character)
        if not character then return end
        
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CollisionGroup = "Players"
            end
        end
    end
    
    -- Handle current character
    if player.Character then
        setPlayerCollisionGroup(player.Character)
    end
    
    -- Handle future character spawns
    player.CharacterAdded:Connect(setPlayerCollisionGroup)
end

-- Set up collision groups
setupPlayerCollisionGroup()

print("Main.client: Initialization complete at", tick())