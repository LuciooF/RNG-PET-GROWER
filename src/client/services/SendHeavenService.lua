-- Send Heaven Service
-- Handles SendHeaven part detection and selling all unassigned pets for money
-- When player touches SendHeaven part, sells all pets except assigned ones

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Store = require(ReplicatedStorage.store)
local PlayerActions = require(ReplicatedStorage.store.actions.PlayerActions)
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local ProcessingRateGUI = require(script.Parent.Parent.components.ui.ProcessingRateGUI)

local SendHeavenService = {}
SendHeavenService.__index = SendHeavenService

local player = Players.LocalPlayer
local playerAreaNumber = nil
local areaAssignments = {}
local connections = {} -- Store all touch connections
local lastSendTime = 0 -- Prevent spam clicking
local confirmationUI = nil -- Store confirmation dialog
local isConfirmationOpen = false
local processingRateGUI = nil -- Store processing rate GUI

-- Configuration
local SEND_COOLDOWN = 2 -- Seconds between send operations

function SendHeavenService:Initialize()
    -- Wait for area assignment sync
    local areaAssignmentSync = ReplicatedStorage:WaitForChild("AreaAssignmentSync", 10)
    if areaAssignmentSync then
        areaAssignmentSync.OnClientEvent:Connect(function(assignmentData)
            areaAssignments = assignmentData
            playerAreaNumber = self:GetPlayerAreaNumber()
            self:SetupSendHeavenPart()
        end)
    end
end

function SendHeavenService:GetPlayerAreaNumber()
    -- Find which area the current player is assigned to
    for areaNumber, assignmentData in pairs(areaAssignments) do
        if assignmentData.playerName == player.Name then
            return areaNumber
        end
    end
    return nil
end

function SendHeavenService:SetupSendHeavenPart()
    if not playerAreaNumber then
        return
    end
    
    -- Clean up existing connections
    self:CleanupConnections()
    
    local playerAreas = Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then return end
    
    local playerArea = playerAreas:FindFirstChild("PlayerArea" .. playerAreaNumber)
    if not playerArea then return end
    
    local sendHeavenPart = playerArea:FindFirstChild("SendHeaven")
    if sendHeavenPart and sendHeavenPart:IsA("BasePart") then
        -- Set up touch detection
        local connection = sendHeavenPart.Touched:Connect(function(hit)
            local humanoid = hit.Parent:FindFirstChild("Humanoid")
            if humanoid and hit.Parent == player.Character then
                self:HandleSendHeavenTouch()
            end
        end)
        
        connections.sendHeavenTouch = connection
        
        -- Individual tube GUIs are now managed by TubeManagerService
        -- No need for central processing rate GUI
        
        print("SendHeavenService: Set up SendHeaven part in area", playerAreaNumber)
    else
        warn("SendHeavenService: SendHeaven part not found in player area", playerAreaNumber)
    end
end

function SendHeavenService:HandleSendHeavenTouch()
    local currentTime = tick()
    
    -- Check cooldown
    if currentTime - lastSendTime < SEND_COOLDOWN then
        print("SendHeavenService: Send to heaven on cooldown")
        return
    end
    
    -- Don't open if confirmation is already open
    if isConfirmationOpen then
        return
    end
    
    -- Get current player data
    local state = Store:getState()
    local ownedPets = state.player.ownedPets or {}
    local companionPets = state.player.companionPets or {}
    
    -- Create lookup table for assigned pets
    local assignedPetIds = {}
    for _, assignedPet in ipairs(companionPets) do
        if assignedPet.uniqueId then
            assignedPetIds[assignedPet.uniqueId] = true
        end
    end
    
    -- Find all unassigned pets
    local unassignedPets = {}
    local totalValue = 0
    
    for _, pet in ipairs(ownedPets) do
        if not (pet.uniqueId and assignedPetIds[pet.uniqueId]) then
            -- This pet is not assigned, add to sell list
            table.insert(unassignedPets, pet)
            totalValue = totalValue + (pet.value or 1)
        end
    end
    
    if #unassignedPets == 0 then
        print("SendHeavenService: No unassigned pets to send to heaven")
        return
    end
    
    -- Show confirmation dialog instead of immediately selling
    self:ShowConfirmationDialog(unassignedPets, totalValue)
end

function SendHeavenService:ShowConfirmationDialog(unassignedPets, totalValue)
    if isConfirmationOpen then
        return
    end
    
    isConfirmationOpen = true
    
    -- Import React
    local Packages = ReplicatedStorage:WaitForChild("Packages")
    local React = require(Packages.react)
    local ReactRoblox = require(Packages["react-roblox"])
    
    -- Get screen size
    local camera = workspace.CurrentCamera
    local screenSize = camera.ViewportSize
    
    -- Create confirmation dialog
    local function ConfirmationDialog()
        -- Calculate responsive sizes
        local panelWidth = math.min(screenSize.X * 0.5, ScreenUtils.getProportionalSize(screenSize, 400))
        local panelHeight = math.min(screenSize.Y * 0.4, ScreenUtils.getProportionalSize(screenSize, 250))
        local titleTextSize = ScreenUtils.getProportionalTextSize(screenSize, 24)
        local normalTextSize = ScreenUtils.getProportionalTextSize(screenSize, 18)
        local buttonTextSize = ScreenUtils.getProportionalTextSize(screenSize, 16)
        
        return React.createElement("Frame", {
            Name = "SendHeavenConfirmation",
            Size = UDim2.new(0, panelWidth, 0, panelHeight),
            Position = UDim2.new(0.5, -panelWidth/2, 0.5, -panelHeight/2),
            BackgroundColor3 = Color3.fromRGB(240, 245, 255),
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
            ZIndex = 50
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0, 15)
            }),
            
            Stroke = React.createElement("UIStroke", {
                Color = Color3.fromRGB(200, 220, 255),
                Thickness = 3,
                Transparency = 0.3
            }),
            
            -- Title
            Title = React.createElement("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -40, 0, 50),
                Position = UDim2.new(0, 20, 0, 15),
                BackgroundTransparency = 1,
                Text = "🌟 Send Pets to Heaven 🌟",
                TextColor3 = Color3.fromRGB(255, 150, 50),
                TextSize = titleTextSize,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 51
            }, {
                Stroke = React.createElement("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = 2,
                    Transparency = 0.3
                })
            }),
            
            -- Message
            Message = React.createElement("TextLabel", {
                Name = "Message",
                Size = UDim2.new(1, -40, 0, 80),
                Position = UDim2.new(0, 20, 0, 70),
                BackgroundTransparency = 1,
                Text = string.format("This will send %d unassigned pets to heaven for %d money.\n\nAssigned pets will stay safe!\n\nAre you sure?", 
                    #unassignedPets, totalValue),
                TextColor3 = Color3.fromRGB(50, 50, 50),
                TextSize = normalTextSize,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextWrapped = true,
                ZIndex = 51
            }),
            
            -- Button container
            ButtonContainer = React.createElement("Frame", {
                Name = "ButtonContainer",
                Size = UDim2.new(1, -40, 0, 50),
                Position = UDim2.new(0, 20, 1, -70),
                BackgroundTransparency = 1,
                ZIndex = 51
            }, {
                Layout = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 20)
                }),
                
                -- Cancel Button
                CancelButton = React.createElement("TextButton", {
                    Name = "CancelButton",
                    Size = UDim2.new(0, 120, 0, 40),
                    BackgroundColor3 = Color3.fromRGB(200, 100, 100),
                    BorderSizePixel = 0,
                    Text = "Cancel",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = buttonTextSize,
                    Font = Enum.Font.GothamBold,
                    ZIndex = 52,
                    [React.Event.Activated] = function()
                        self:CloseConfirmationDialog()
                    end
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = UDim.new(0, 8)
                    })
                }),
                
                -- Confirm Button
                ConfirmButton = React.createElement("TextButton", {
                    Name = "ConfirmButton",
                    Size = UDim2.new(0, 120, 0, 40),
                    BackgroundColor3 = Color3.fromRGB(255, 150, 50), -- Heaven gold color
                    BorderSizePixel = 0,
                    Text = "Send to Heaven",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = buttonTextSize,
                    Font = Enum.Font.GothamBold,
                    ZIndex = 52,
                    [React.Event.Activated] = function()
                        self:ConfirmSendToHeaven(unassignedPets, totalValue)
                    end
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = UDim.new(0, 8)
                    })
                })
            })
        })
    end
    
    -- Mount the confirmation UI
    local playerGui = player:WaitForChild("PlayerGui")
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SendHeavenConfirmation"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    
    local root = ReactRoblox.createRoot(screenGui)
    root:render(React.createElement(ConfirmationDialog))
    
    confirmationUI = {
        screenGui = screenGui,
        root = root
    }
    
    print("SendHeavenService: Opened confirmation dialog")
end

function SendHeavenService:CloseConfirmationDialog()
    if not isConfirmationOpen then
        return
    end
    
    isConfirmationOpen = false
    
    if confirmationUI then
        if confirmationUI.root then
            confirmationUI.root:unmount()
        end
        if confirmationUI.screenGui and confirmationUI.screenGui.Parent then
            confirmationUI.screenGui:Destroy()
        end
        confirmationUI = nil
    end
    
    print("SendHeavenService: Closed confirmation dialog")
end

function SendHeavenService:ConfirmSendToHeaven(unassignedPets, totalValue)
    lastSendTime = tick()
    
    -- Close the confirmation dialog
    self:CloseConfirmationDialog()
    
    print(string.format("SendHeavenService: Sending %d pets to heaven for %d money", 
        #unassignedPets, totalValue))
    
    -- IMMEDIATE CLIENT-SIDE UPDATES for responsive UI
    self:UpdateClientState(unassignedPets, totalValue)
    
    -- Send to server for validation (async)
    self:SendToServer(unassignedPets, totalValue)
end

function SendHeavenService:UpdateClientState(soldPets, totalValue)
    -- Batch process large pet arrays to prevent lag spikes
    self:BatchProcessPetRemoval(soldPets, totalValue)
end

function SendHeavenService:BatchProcessPetRemoval(soldPets, totalValue)
    local state = Store:getState()
    local currentOwnedPets = state.player.ownedPets or {}
    
    -- Create lookup table for sold pets (batch in chunks to prevent lag)
    local soldPetIds = {}
    local BATCH_SIZE = 100 -- Process 100 pets per frame
    local currentIndex = 1
    
    local function processBatch()
        local endIndex = math.min(currentIndex + BATCH_SIZE - 1, #soldPets)
        
        -- Process current batch
        for i = currentIndex, endIndex do
            local soldPet = soldPets[i]
            if soldPet.uniqueId then
                soldPetIds[soldPet.uniqueId] = true
            end
        end
        
        currentIndex = endIndex + 1
        
        -- Continue processing if there are more pets
        if currentIndex <= #soldPets then
            task.wait() -- Yield to next frame
            processBatch()
        else
            -- All pets processed, now filter the owned pets
            self:FilterOwnedPets(currentOwnedPets, soldPetIds, totalValue, #soldPets)
        end
    end
    
    -- Start batch processing
    processBatch()
end

function SendHeavenService:FilterOwnedPets(currentOwnedPets, soldPetIds, totalValue, soldCount)
    -- Filter out sold pets (also batched for large inventories)
    local remainingPets = {}
    local FILTER_BATCH_SIZE = 200 -- Process 200 pets per frame
    local currentIndex = 1
    
    local function filterBatch()
        local endIndex = math.min(currentIndex + FILTER_BATCH_SIZE - 1, #currentOwnedPets)
        
        -- Filter current batch
        for i = currentIndex, endIndex do
            local pet = currentOwnedPets[i]
            if not (pet.uniqueId and soldPetIds[pet.uniqueId]) then
                table.insert(remainingPets, pet)
            end
        end
        
        currentIndex = endIndex + 1
        
        -- Continue filtering if there are more pets
        if currentIndex <= #currentOwnedPets then
            task.wait() -- Yield to next frame
            filterBatch()
        else
            -- All pets filtered, update store
            self:FinalizeStateUpdate(remainingPets, totalValue, soldCount)
        end
    end
    
    -- Start filter processing
    filterBatch()
end

function SendHeavenService:FinalizeStateUpdate(remainingPets, totalValue, soldCount)
    -- Update Redux store (NO money added immediately - will come from server processing)
    Store:dispatch(PlayerActions.setPets(remainingPets))
    
    -- Update inventory counter immediately
    if processingRateGUI then
        ProcessingRateGUI.updateInventoryCounter(processingRateGUI)
    end
    
    print(string.format("SendHeavenService: Updated client state - removed %d pets, queued for processing (worth %d money)", 
        soldCount, totalValue))
end

function SendHeavenService:SendToServer(soldPets, expectedValue)
    task.spawn(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then
            warn("SendHeavenService: Remotes folder not found")
            return
        end
        
        local sendHeavenRemote = remotes:FindFirstChild("SendPetsToHeaven")
        if not sendHeavenRemote then
            warn("SendHeavenService: SendPetsToHeaven remote not found")
            return
        end
        
        -- Send pet data to server for validation
        local petData = {}
        for _, pet in ipairs(soldPets) do
            table.insert(petData, {
                uniqueId = pet.uniqueId,
                id = pet.id,
                value = pet.value,
                aura = pet.aura,
                size = pet.size
            })
        end
        
        sendHeavenRemote:FireServer({
            pets = petData,
            expectedValue = expectedValue,
            timestamp = tick()
        })
        
        print("SendHeavenService: Sent", #petData, "pets to server for validation")
    end)
end

function SendHeavenService:CreateProcessingRateGUI(sendHeavenPart)
    -- Remove existing processing rate GUI if it exists
    if processingRateGUI then
        ProcessingRateGUI.destroyGUI(processingRateGUI)
        processingRateGUI = nil
    end
    
    -- Create new processing rate GUI
    processingRateGUI = ProcessingRateGUI.createProcessingRateGUI(sendHeavenPart)
    if processingRateGUI then
        -- Add pulse effect for visual appeal
        ProcessingRateGUI.addPulseEffect(processingRateGUI)
        
        -- Set up Store subscription to update inventory counter
        self:StartInventoryCounterUpdates()
        
        print("SendHeavenService: Created processing rate GUI with inventory counter")
    else
        warn("SendHeavenService: Failed to create processing rate GUI")
    end
end

-- Start monitoring inventory changes to update counter
function SendHeavenService:StartInventoryCounterUpdates()
    if not processingRateGUI then
        return
    end
    
    -- Initial update
    ProcessingRateGUI.updateInventoryCounter(processingRateGUI)
    ProcessingRateGUI.updateProcessingRate(processingRateGUI) -- Also update processing rate
    
    -- Set up periodic updates (every 2 seconds to catch changes)
    local RunService = game:GetService("RunService")
    local lastUpdateTime = 0
    local UPDATE_FREQUENCY = 2 -- Update every 2 seconds
    
    if connections.inventoryUpdate then
        connections.inventoryUpdate:Disconnect()
    end
    
    connections.inventoryUpdate = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        if currentTime - lastUpdateTime >= UPDATE_FREQUENCY then
            lastUpdateTime = currentTime
            if processingRateGUI then
                ProcessingRateGUI.updateInventoryCounter(processingRateGUI)
                ProcessingRateGUI.updateProcessingRate(processingRateGUI) -- Update processing rate too
            end
        end
    end)
end

-- Update processing rate GUI (called by TubeManagerService when tube count changes)
function SendHeavenService:UpdateProcessingRateGUI()
    if processingRateGUI then
        ProcessingRateGUI.updateProcessingRate(processingRateGUI)
    end
end

function SendHeavenService:CleanupConnections()
    for key, connection in pairs(connections) do
        if connection then
            connection:Disconnect()
        end
    end
    connections = {}
end

function SendHeavenService:Cleanup()
    self:CleanupConnections()
    self:CloseConfirmationDialog()
    
    -- Clean up processing rate GUI
    if processingRateGUI then
        ProcessingRateGUI.destroyGUI(processingRateGUI)
        processingRateGUI = nil
    end
end

return SendHeavenService