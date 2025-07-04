local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages.react)
local ReactRoblox = require(Packages["react-roblox"])
local Store = require(ReplicatedStorage.store)


local TopStats = require(script.Parent.components.TopStats)
local DebugUI = require(script.Parent.components.DebugUI)
local SideButtons = require(script.Parent.components.SideButtons)
local PetInventoryPanel = require(script.Parent.components.PetInventoryPanel)
local PetBoostPanel = require(script.Parent.components.PetBoostPanel)
local RebirthPanel = require(script.Parent.components.RebirthPanel)
local ShopPanel = require(script.Parent.components.ShopPanel)
local RebirthAnimationEffect = require(script.Parent.components.RebirthAnimationEffect)
local AreaNameplateService = require(script.Parent.services.AreaNameplateService)
local PlotVisualsService = require(script.Parent.services.PlotVisualsService)
local ProductionPlotVisualsService = require(script.Parent.services.ProductionPlotVisualsService)
local CylinderSpawnerService = require(script.Parent.services.CylinderSpawnerService)
local PetFollowService = require(script.Parent.services.PetFollowService)
local SendHeavenService = require(script.Parent.services.SendHeavenService)
local HeavenAnimationService = require(script.Parent.services.HeavenAnimationService)
local TubeManagerService = require(script.Parent.services.TubeManagerService)

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
    local debugUIVisible, setDebugUIVisible = React.useState(false)
    local rebirthPanelVisible, setRebirthPanelVisible = React.useState(false)
    local rebirthAnimationVisible, setRebirthAnimationVisible = React.useState(false)
    
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
    
    -- Subscribe to Redux store changes
    React.useEffect(function()
        local connection = Store.changed:connect(function(newState)
            local newPlayerData = newState.player or {}
            setPlayerData(newPlayerData)
            
            
            -- Update pet follow service with new assigned pets
            PetFollowService:UpdateAssignedPets(newPlayerData)
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
            end
        end)
        
        return function()
            connection:disconnect()
            serverConnection:Disconnect()
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
                setShopPanelVisible(function(current) return not current end)
            end,
            onPetsClick = function() 
                setPetInventoryVisible(function(current) return not current end)
            end,
            onRebirthClick = function() 
                setRebirthPanelVisible(true)
            end,
            onDebugClick = function()
                setDebugUIVisible(function(current) return not current end)
            end
        }),
        DebugUI = React.createElement(DebugUI, {
            visible = debugUIVisible,
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
        PetBoosts = React.createElement(PetBoostPanel, {
            playerData = {
                companionPets = playerData.companionPets or {}
            },
            screenSize = screenSize
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

-- Initialize server response handler for rollback mechanism
local ServerResponseHandler = require(script.Parent.services.ServerResponseHandler)
ServerResponseHandler:Initialize()

-- Initialize state reconciliation service
local StateReconciliationService = require(script.Parent.services.StateReconciliationService)
StateReconciliationService:Initialize()

-- Pet scanning removed - no longer needed for maintenance