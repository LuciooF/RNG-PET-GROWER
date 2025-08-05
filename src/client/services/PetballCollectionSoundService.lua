-- PetballCollectionSoundService - Handles petball collection sound effects
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetballCollectionSoundService = {}
PetballCollectionSoundService.__index = PetballCollectionSoundService

local player = Players.LocalPlayer

-- Configuration
local COLLECTION_SOUND_ID = "rbxassetid://1289263994"
local SOUND_VOLUME = 0.5
local MAX_CONCURRENT_SOUNDS = 10 -- Limit to prevent audio overload
local SOUND_COOLDOWN = 0.05 -- Minimum time between sounds in seconds

-- Sound management
local soundPool = {}
local availableSounds = {}
local lastSoundTime = 0

function PetballCollectionSoundService:Initialize()
    -- Create sound pool to handle multiple simultaneous collections
    self:CreateSoundPool()
end

function PetballCollectionSoundService:CreateSoundPool()
    -- Create multiple sound instances to handle rapid collections
    for i = 1, MAX_CONCURRENT_SOUNDS do
        local sound = Instance.new("Sound")
        sound.Name = "PetballCollectionSound" .. i
        sound.SoundId = COLLECTION_SOUND_ID
        sound.Volume = SOUND_VOLUME
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
    
    -- Sound pool created
end


function PetballCollectionSoundService:PlayCollectionSound()
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

function PetballCollectionSoundService:GetAvailableSound()
    if #availableSounds > 0 then
        -- Get and remove from available sounds
        local sound = table.remove(availableSounds, 1)
        return sound
    end
    
    return nil -- No sounds available
end

function PetballCollectionSoundService:ReturnSoundToPool(sound)
    -- Return sound to available pool
    table.insert(availableSounds, sound)
end

function PetballCollectionSoundService:SetVolume(volume)
    volume = math.clamp(volume, 0, 1)
    SOUND_VOLUME = volume
    
    -- Update all sounds in pool
    for _, sound in pairs(soundPool) do
        sound.Volume = volume
    end
    
    print("PetballCollectionSoundService: Volume set to", volume)
end

-- Clean up when service is destroyed
function PetballCollectionSoundService:Cleanup()
    print("PetballCollectionSoundService: Cleaning up...")
    
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
        PetballCollectionSoundService:Cleanup()
    end
end)

return PetballCollectionSoundService