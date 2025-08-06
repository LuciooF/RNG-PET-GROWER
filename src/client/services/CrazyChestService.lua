-- CrazyChestService - Handles client-side crazy chest interactions
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DataSyncService = require(script.Parent.DataSyncService)
local CrazyChestConfig = require(ReplicatedStorage.config.CrazyChestConfig)
local PlayerAreaFinder = require(script.Parent.Parent.utils.PlayerAreaFinder)
local CrazyChestAnimationService = require(script.Parent.CrazyChestAnimationService)
local RewardsService = require(script.Parent.RewardsService)

local CrazyChestService = {}
CrazyChestService.__index = CrazyChestService

-- Track if already initialized to prevent duplicate connections
local clientInitialized = false

local player = Players.LocalPlayer
local chestPart = nil
local proximityPrompt = nil
local connections = {}

-- UI state
local isChestUIOpen = false
local isRewarding = false -- Track reward display state

function CrazyChestService:Initialize()
    -- Prevent multiple initializations
    if clientInitialized then
        warn("CrazyChestService: CLIENT already initialized, skipping")
        return
    end
    clientInitialized = true
    
    -- Initialize animation service
    CrazyChestAnimationService:Initialize()
    
    -- Find the chest in player's area
    self:FindChestInPlayerArea()
    
    -- Set up remote events
    self:SetupRemoteEvents()
end

function CrazyChestService:FindChestInPlayerArea()
    -- Use shared utility to find player's area
    local playerArea = PlayerAreaFinder:WaitForPlayerArea(30)
    if not playerArea then
        warn("CrazyChestService: Player area not found for", player.Name)
        return
    end
    
    -- Find chest in Environmentals
    local environmentals = playerArea:FindFirstChild("Environmentals")
    if environmentals then
        chestPart = environmentals:FindFirstChild("Chest")
        if chestPart then
            self:CreateProximityPrompt()
        else
            warn("CrazyChestService: Chest not found in Environmentals")
        end
    else
        warn("CrazyChestService: Environmentals folder not found")
    end
end

function CrazyChestService:CreateProximityPrompt()
    if not chestPart then return end
    
    -- Find a suitable part to attach the prompt to
    local attachPart
    if chestPart:IsA("Model") then
        attachPart = chestPart.PrimaryPart or chestPart:FindFirstChildWhichIsA("BasePart", true)
        if not attachPart then
            warn("CrazyChestService: No suitable part found in chest model for ProximityPrompt")
            return
        end
    else
        attachPart = chestPart
    end
    
    -- Create ProximityPrompt
    proximityPrompt = Instance.new("ProximityPrompt")
    proximityPrompt.Name = "CrazyChestPrompt"
    proximityPrompt.ActionText = "Open Crazy Chest"
    proximityPrompt.ObjectText = "Crazy Chest"
    proximityPrompt.HoldDuration = 0
    proximityPrompt.MaxActivationDistance = 8
    proximityPrompt.RequiresLineOfSight = false
    proximityPrompt.Parent = attachPart
    
    -- Connect to the Triggered event
    connections.promptTriggered = proximityPrompt.Triggered:Connect(function(playerWhoTriggered)
        if playerWhoTriggered == player then
            -- Open the chest UI first to show chances and cost
            self:OpenChestUI()
        end
    end)
end

function CrazyChestService:SetupRemoteEvents()
    -- Wait for remote events
    local openChestRemote = ReplicatedStorage:WaitForChild("OpenCrazyChest", 10)
    local chestResultRemote = ReplicatedStorage:WaitForChild("CrazyChestResult", 10)
    
    if not openChestRemote or not chestResultRemote then
        warn("CrazyChestService: Critical remote events not found!")
        return
    end
    
    -- Handle chest result from server
    connections.chestResult = chestResultRemote.OnClientEvent:Connect(function(roll, reward)
        print("CrazyChestService: Received result from server - Roll:", roll, "Reward:", reward)
        
        -- Store the reward key for claiming later
        local rewardKey = reward.rewardKey
        
        -- Start the CSGO-style case opening animation
        CrazyChestAnimationService:StartCaseOpeningAnimation(roll, reward)
        
        -- Show reward popup after animation completes 
        task.spawn(function()
            task.wait(6) -- Wait for 6 second animation to complete
            
            -- Claim the reward from server NOW (after animation)
            local claimRewardRemote = ReplicatedStorage:FindFirstChild("ClaimCrazyChestReward")
            if claimRewardRemote and rewardKey then
                print("CrazyChestService: Claiming reward with key:", rewardKey)
                claimRewardRemote:FireServer(rewardKey)
            end
            
            -- Set rewarding state
            isRewarding = true
            print("CrazyChestService: Animation complete, showing reward...")
            
            -- Show reward popup
            local rewardData = {
                source = "Crazy Chest"
            }
            
            if reward.type == "money" then
                rewardData.type = "Money"
                rewardData.amount = reward.money
            elseif reward.type == "diamonds" then
                rewardData.type = "Diamonds"
                rewardData.amount = reward.diamonds
            elseif reward.type == "pet" then
                rewardData.type = "Pet"
                rewardData.petName = reward.petName
                rewardData.boost = reward.boost
                rewardData.amount = reward.amount or 1
            end
            
            RewardsService:ShowReward(rewardData)
            
            -- Keep showing "Rewarding" for 2 seconds
            task.wait(2)
            
            -- Clear rewarding state but keep UI open
            isRewarding = false
            print("CrazyChestService: Ready for next chest opening")
        end)
    end)
end

function CrazyChestService:OpenChestUI()
    isChestUIOpen = true
    
    -- Disable the proximity prompt while UI is open
    if proximityPrompt then
        proximityPrompt.Enabled = false
    end
end

function CrazyChestService:CloseChestUI()
    isChestUIOpen = false
    isRewarding = false -- Clear rewarding state when closing
    
    -- Re-enable the proximity prompt
    if proximityPrompt then
        proximityPrompt.Enabled = true
    end
end

function CrazyChestService:HandleChestOpen()
    
    -- Check if animation is already running or rewarding (prevent multiple openings)
    if CrazyChestAnimationService.isAnimating or isRewarding then
        warn("CrazyChestService: Cannot open chest - animation or reward in progress!")
        return
    end
    
    -- Get player data
    local playerData = DataSyncService:GetPlayerData()
    if not playerData then
        warn("CrazyChestService: No player data available")
        return
    end
    
    if not CrazyChestConfig then
        warn("CrazyChestService: CrazyChestConfig not loaded!")
        return
    end
    
    local cost = CrazyChestConfig.getCost(playerData.Resources.Rebirths or 0)
    
    if (playerData.Resources.Diamonds or 0) < cost then
        warn("CrazyChestService: Not enough diamonds")
        return
    end
    
    -- Optimistically deduct diamonds on client for instant feedback
    -- The server will validate and sync the real state
    local store = require(ReplicatedStorage.store)
    local Actions = require(ReplicatedStorage.store.actions)
    store:dispatch(Actions.updateResources("Diamonds", -cost))
    
    -- Send request to server
    local openChestRemote = ReplicatedStorage:FindFirstChild("OpenCrazyChest")
    if openChestRemote then
        openChestRemote:FireServer()
    else
        warn("CrazyChestService: OpenCrazyChest remote not found!")
        -- Revert the optimistic update if we can't contact server
        store:dispatch(Actions.updateResources("Diamonds", cost))
    end
end

function CrazyChestService:GetUIProps()
    local playerData = DataSyncService:GetPlayerData()
    
    return {
        visible = isChestUIOpen,
        playerDiamonds = playerData and playerData.Resources.Diamonds or 0,
        playerRebirths = playerData and playerData.Resources.Rebirths or 0,
        isAnimating = CrazyChestAnimationService.isAnimating, -- Pass animation state to UI
        isRewarding = isRewarding, -- Pass rewarding state to UI
        onClose = function()
            self:CloseChestUI()
        end,
        onOpenChest = function()
            self:HandleChestOpen()
        end
    }
end

function CrazyChestService:Cleanup()
    for _, connection in pairs(connections) do
        if connection then
            connection:Disconnect()
        end
    end
    connections = {}
    
    if proximityPrompt then
        proximityPrompt:Destroy()
        proximityPrompt = nil
    end
    
    -- Cleanup animation service
    CrazyChestAnimationService:Cleanup()
end

return CrazyChestService