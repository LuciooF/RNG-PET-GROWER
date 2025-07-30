-- PetMagnetService - Handles automatic pet collection for PetMagnet gamepass
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local DataSyncService = require(script.Parent.DataSyncService)
local GamepassConfig = require(ReplicatedStorage.config.GamepassConfig)

local PetMagnetService = {}
PetMagnetService.__index = PetMagnetService

local player = Players.LocalPlayer
local magnetConnection = nil
local magnetBenefits = GamepassConfig.getBenefits("PetMagnet")

-- Configuration
local MAGNET_RANGE = magnetBenefits and magnetBenefits.magnetRange or 50
local MAGNET_SPEED = magnetBenefits and magnetBenefits.magnetSpeed or 25
local THROUGH_WALLS = magnetBenefits and magnetBenefits.throughWalls or true

-- Track tweened pet balls to avoid duplicate tweens
local tweeningPetBalls = {}

function PetMagnetService:Initialize()
    -- Subscribe to player data changes to check gamepass ownership
    self:SetupDataSubscription()
end

function PetMagnetService:SetupDataSubscription()
    -- Subscribe to data changes to check gamepass ownership
    local unsubscribe = DataSyncService:Subscribe(function(newState)
        if newState.player then
            self:UpdateMagnetStatus(newState.player)
        end
    end)
    
    -- Also check initial data
    local initialData = DataSyncService:GetPlayerData()
    if initialData then
        self:UpdateMagnetStatus(initialData)
    end
    
    -- Store unsubscribe function for cleanup
    self.dataSubscription = unsubscribe
end

-- Update magnet status based on gamepass ownership and settings
function PetMagnetService:UpdateMagnetStatus(playerData)
    local ownsPetMagnet = self:PlayerOwnsPetMagnet(playerData)
    local petMagnetEnabled = playerData.GamepassSettings and playerData.GamepassSettings.PetMagnetEnabled
    
    if ownsPetMagnet and petMagnetEnabled and not magnetConnection then
        -- Start pet magnet
        self:StartPetMagnet()
        print("PetMagnetService: Started pet magnet")
    elseif (not ownsPetMagnet or not petMagnetEnabled) and magnetConnection then
        -- Stop pet magnet
        self:StopPetMagnet()
        print("PetMagnetService: Stopped pet magnet")
    end
end

-- Check if player owns PetMagnet gamepass
function PetMagnetService:PlayerOwnsPetMagnet(playerData)
    if not playerData or not playerData.OwnedGamepasses then
        return false
    end
    
    for _, gamepass in pairs(playerData.OwnedGamepasses) do
        if gamepass == "PetMagnet" then
            return true
        end
    end
    
    return false
end

-- Start the pet magnet functionality
function PetMagnetService:StartPetMagnet()
    if magnetConnection then
        return -- Already running
    end
    
    magnetConnection = RunService.Heartbeat:Connect(function()
        self:UpdatePetMagnet()
    end)
end

-- Stop the pet magnet functionality
function PetMagnetService:StopPetMagnet()
    if magnetConnection then
        magnetConnection:Disconnect()
        magnetConnection = nil
    end
    
    -- Cancel all active tweens
    for petBall, tween in pairs(tweeningPetBalls) do
        if tween then
            tween:Cancel()
        end
    end
    tweeningPetBalls = {}
end

-- Update pet magnet - find and attract nearby pet balls
function PetMagnetService:UpdatePetMagnet()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local playerPosition = player.Character.HumanoidRootPart.Position
    
    -- Find player's area to limit search
    local playerArea = self:FindPlayerArea()
    if not playerArea then
        return
    end
    
    -- Look for pet balls in the player's area
    for _, child in pairs(playerArea:GetDescendants()) do
        if child.Name == "PetBall" and child:IsA("BasePart") and not tweeningPetBalls[child] then
            local distance = (child.Position - playerPosition).Magnitude
            
            if distance <= MAGNET_RANGE and distance > 3 then -- Don't magnet if too close
                self:AttractPetBall(child, playerPosition)
            end
        end
    end
end

-- Find the player's assigned area
function PetMagnetService:FindPlayerArea()
    local playerAreas = game.Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then
        return nil
    end
    
    -- Find the player's assigned area by checking the area nameplate
    for _, area in pairs(playerAreas:GetChildren()) do
        if area.Name:match("PlayerArea") then
            local nameplate = area:FindFirstChild("AreaNameplate")
            if nameplate then
                local billboard = nameplate:FindFirstChild("NameplateBillboard")
                if billboard then
                    local textLabel = billboard:FindFirstChild("TextLabel")
                    if textLabel and textLabel.Text == (player.Name .. "'s Area") then
                        return area
                    end
                end
            end
        end
    end
    
    return nil
end

-- Attract a pet ball to the player
function PetMagnetService:AttractPetBall(petBall, targetPosition)
    -- Mark as tweening to avoid duplicate tweens
    tweeningPetBalls[petBall] = true
    
    -- Calculate distance for tween duration
    local distance = (petBall.Position - targetPosition).Magnitude
    local duration = distance / MAGNET_SPEED
    
    -- Make pet ball non-collidable if going through walls
    if THROUGH_WALLS then
        petBall.CanCollide = false
    end
    
    -- Create tween to player position (torso/legs level)
    local tween = TweenService:Create(petBall, 
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Position = targetPosition + Vector3.new(0, -2, 0)} -- Lower to torso/legs level
    )
    
    -- Store tween reference
    tweeningPetBalls[petBall] = tween
    
    -- Handle tween completion
    tween.Completed:Connect(function()
        tweeningPetBalls[petBall] = nil
        -- Pet ball should be collected automatically when it reaches player
    end)
    
    -- Handle if pet ball is destroyed during tween
    petBall.AncestryChanged:Connect(function()
        if not petBall.Parent then
            if tweeningPetBalls[petBall] then
                tweeningPetBalls[petBall] = nil
            end
        end
    end)
    
    -- Start the tween
    tween:Play()
end

-- Clean up connections
function PetMagnetService:Cleanup()
    self:StopPetMagnet()
    
    if self.dataSubscription then
        self.dataSubscription()
        self.dataSubscription = nil
    end
end

-- Handle character respawn
Players.LocalPlayer.CharacterAdded:Connect(function()
    -- Re-check magnet status after respawn
    task.wait(1) -- Wait for character to fully load
    local playerData = DataSyncService:GetPlayerData()
    if playerData then
        PetMagnetService:UpdateMagnetStatus(playerData)
    end
end)

return PetMagnetService