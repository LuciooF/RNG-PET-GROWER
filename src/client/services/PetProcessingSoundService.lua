-- PetProcessingSoundService - Handles pet processing sound effects
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetProcessingSoundService = {}
PetProcessingSoundService.__index = PetProcessingSoundService

local player = Players.LocalPlayer

-- Configuration
local PROCESSING_SOUND_ID = "rbxassetid://1839901317"
local SOUND_VOLUME = 0.025
local SOUND_SPEED = 3.0 -- 3x speed
local MAX_CONCURRENT_SOUNDS = 15 -- Handle multiple pets processing at once
local SOUND_COOLDOWN = 0.02 -- Very short cooldown

-- Sound management
local soundPool = {}
local availableSounds = {}
local lastSoundTime = 0

function PetProcessingSoundService:Initialize()
    print("PetProcessingSoundService: Initializing pet processing sounds...")
    
    -- Create sound pool to handle multiple simultaneous processing
    self:CreateSoundPool()
    
    -- Listen for pet processing events
    self:SetupProcessingListener()
    
    print("PetProcessingSoundService: Service initialized")
end

function PetProcessingSoundService:CreateSoundPool()
    -- Create multiple sound instances to handle rapid processing
    for i = 1, MAX_CONCURRENT_SOUNDS do
        local sound = Instance.new("Sound")
        sound.Name = "PetProcessingSound" .. i
        sound.SoundId = PROCESSING_SOUND_ID
        sound.Volume = SOUND_VOLUME
        sound.PlaybackSpeed = SOUND_SPEED -- 2x speed
        sound.RollOffMode = Enum.RollOffMode.Inverse
        sound.Parent = SoundService
        
        -- Add to pools
        table.insert(soundPool, sound)
        table.insert(availableSounds, sound)
        
        -- Clean up when sound finishes
        sound.Ended:Connect(function()
            self:ReturnSoundToPool(sound)
        end)
    end
    
    print("PetProcessingSoundService: Created sound pool with", MAX_CONCURRENT_SOUNDS, "sounds at", SOUND_SPEED .. "x speed")
end

function PetProcessingSoundService:SetupProcessingListener()
    -- Listen for pet processing events from the server
    local petProcessedRemote = ReplicatedStorage:FindFirstChild("PetProcessed")
    if not petProcessedRemote then
        -- Wait for the remote to be created
        petProcessedRemote = ReplicatedStorage:WaitForChild("PetProcessed", 30)
        if not petProcessedRemote then
            warn("PetProcessingSoundService: PetProcessed remote event not found after 30 seconds")
            return
        end
    end
    
    petProcessedRemote.OnClientEvent:Connect(function()
        self:PlayProcessingSound()
    end)
    
    print("PetProcessingSoundService: Processing listener set up")
end

function PetProcessingSoundService:PlayProcessingSound()
    -- Check cooldown to prevent audio spam
    local currentTime = tick()
    if currentTime - lastSoundTime < SOUND_COOLDOWN then
        return -- Skip this sound to prevent spam
    end
    lastSoundTime = currentTime
    
    -- Get available sound from pool
    local sound = self:GetAvailableSound()
    if not sound then
        -- All sounds in use, skip this one
        return
    end
    
    -- Play the sound
    sound:Play()
end

function PetProcessingSoundService:GetAvailableSound()
    if #availableSounds > 0 then
        -- Get and remove from available sounds
        local sound = table.remove(availableSounds, 1)
        return sound
    end
    
    return nil -- No sounds available
end

function PetProcessingSoundService:ReturnSoundToPool(sound)
    -- Return sound to available pool
    table.insert(availableSounds, sound)
end

function PetProcessingSoundService:SetVolume(volume)
    volume = math.clamp(volume, 0, 1)
    SOUND_VOLUME = volume
    
    -- Update all sounds in pool
    for _, sound in pairs(soundPool) do
        sound.Volume = volume
    end
    
    print("PetProcessingSoundService: Volume set to", volume)
end

function PetProcessingSoundService:SetSpeed(speed)
    speed = math.clamp(speed, 0.1, 5.0)
    SOUND_SPEED = speed
    
    -- Update all sounds in pool
    for _, sound in pairs(soundPool) do
        sound.PlaybackSpeed = speed
    end
    
    print("PetProcessingSoundService: Speed set to", speed .. "x")
end

-- Clean up when service is destroyed
function PetProcessingSoundService:Cleanup()
    print("PetProcessingSoundService: Cleaning up...")
    
    -- Clean up all sounds
    for _, sound in pairs(soundPool) do
        if sound then
            sound:Stop()
            sound:Destroy()
        end
    end
    
    soundPool = {}
    availableSounds = {}
end

-- Handle player leaving (cleanup)
game.Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        PetProcessingSoundService:Cleanup()
    end
end)

return PetProcessingSoundService