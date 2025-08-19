-- AnnouncementService - Handles server-wide announcements for rare pet discoveries
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local PetConstants = require(ReplicatedStorage.constants.PetConstants)
local NumberFormatter = require(ReplicatedStorage.utils.NumberFormatter)

local AnnouncementService = {}
AnnouncementService.__index = AnnouncementService

-- Anti-spam system - track last announcement time globally
local lastAnnouncementTime = 0
local ANNOUNCEMENT_COOLDOWN = 3

local function getRarityOrder(rarity)
    local rarityOrder = {
        ["Common"] = 1,
        ["Uncommon"] = 2,
        ["Rare"] = 3, 
        ["Epic"] = 4,
        ["Legendary"] = 5,
        ["Mythic"] = 6,
        ["Ancient"] = 7,
        ["Celestial"] = 8,
        ["Transcendent"] = 9,
        ["Omnipotent"] = 10,
        ["Ethereal"] = 11,
        ["Primordial"] = 12,
        ["Cosmic"] = 13,
        ["Infinite"] = 14,
        ["Omniscient"] = 15
    }
    return rarityOrder[rarity] or 1
end

-- Configuration: Announce only Epic+ pets (same filter as discovery popup)
local MIN_RARITY_FOR_ANNOUNCEMENT = 4

-- Configuration: Announce Epic+ pets (same filter as discovery popup)
-- No variation filtering - all Epic+ pets qualify regardless of variation

function AnnouncementService:Initialize()
    -- Create the GlobalChatMessage RemoteEvent for fallback communication
    local globalChatRemote = ReplicatedStorage:FindFirstChild("GlobalChatMessage")
    if not globalChatRemote then
        globalChatRemote = Instance.new("RemoteEvent")
        globalChatRemote.Name = "GlobalChatMessage"
        globalChatRemote.Parent = ReplicatedStorage
        -- Created GlobalChatMessage RemoteEvent
    end
    
    -- AnnouncementService initialized
end

local function findPetByName(petName)
    local PetConfig = require(ReplicatedStorage.config.PetConfig)
    
    local actualPetName = petName
    local variations = {"Bronze", "Silver", "Gold", "Platinum", "Diamond", "Emerald", "Sapphire", "Ruby", "Titanium", "Obsidian", "Crystal", "Rainbow", "Cosmic", "Void", "Divine"}
    for _, variation in pairs(variations) do
        if string.find(petName, variation .. "$") then -- ends with variation
            actualPetName = string.gsub(petName, variation .. "$", "")
            break
        end
    end
    
    for level = 1, 7 do
        local petsInLevel = PetConfig.getPetsByLevel(level)
        if petsInLevel then
            for _, petData in pairs(petsInLevel) do
                if petData.Name == actualPetName then
                    return petData
                end
            end
        end
    end
    
    return nil
end

-- Announce a rare pet discovery to all players
function AnnouncementService:AnnouncePetDiscovery(player, petData)
    if not player or not petData then return end
    
    local currentTime = tick()
    if currentTime - lastAnnouncementTime < ANNOUNCEMENT_COOLDOWN then
        return
    end
    
    local petConfig = findPetByName(petData.Name)
    if not petConfig then
        return
    end
    
    
    local variation = petData.Variation
    if type(variation) == "table" then
        variation = variation.VariationName
    end
    
    local PetConfig = require(ReplicatedStorage.config.PetConfig)
    
    local spawnLevel = petData.SpawnLevel or 1
    local spawnDoor = petData.SpawnDoor or nil
    
    local odds = 1000000
    if PetConfig.getActualPetRarity then
        local result = PetConfig.getActualPetRarity(petData.Name, variation, spawnLevel, spawnDoor)
        if type(result) == "number" then
            odds = result
        else
                warn("AnnouncementService: Pet has unknown rarity, skipping announcement:", petData.Name, variation)
            return
        end
    end
    
    -- Only announce pets rarer than 1 in 750
    if odds < 750 then
        return
    else
        odds = PetConstants.getCombinedRarityChance(petConfig.Rarity, variation)
        
        if not odds then
            warn("AnnouncementService: getCombinedRarityChance returned nil for rarity:", petConfig.Rarity, "variation:", variation, "type:", type(variation))
        end
        
        if not odds or odds <= 0 then
            odds = PetConstants.getRarityChance(petConfig.Rarity) or 50
            warn("AnnouncementService: Combined rarity calculation failed for", petConfig.Rarity, variation, "- using pet rarity only")
        end
    end
    
    local petName = petData.Name or "Unknown Pet"
    local rarityName = petConfig.Rarity -- Use rarity from pet config
    
    local actionMessage = "has discovered"
    if odds >= 1000 then
        actionMessage = "has struck GOLD and found"
    elseif odds >= 100 then
        actionMessage = "has found the rare"
    end
    
    local rarityColor = PetConstants.getRarityColor(petConfig.Rarity)
    local variationColor = PetConstants.getVariationColor(variation)
    
    local function color3ToHex(color3)
        local r = math.floor(color3.R * 255)
        local g = math.floor(color3.G * 255)
        local b = math.floor(color3.B * 255)
        return string.format("#%02X%02X%02X", r, g, b)
    end
    
    local function getEnhancedRarityColor(rarity)
        local enhancedColors = {
            ["Common"] = Color3.fromRGB(150, 150, 150),      -- Gray
            ["Uncommon"] = Color3.fromRGB(85, 255, 85),      -- Bright Green
            ["Rare"] = Color3.fromRGB(85, 150, 255),         -- Light Blue
            ["Epic"] = Color3.fromRGB(200, 85, 255),         -- Bright Purple
            ["Legendary"] = Color3.fromRGB(255, 140, 0),     -- Bright Orange
            ["Mythic"] = Color3.fromRGB(255, 50, 150),       -- Hot Pink (not gold!)
            ["Ancient"] = Color3.fromRGB(180, 100, 50),      -- Brown
            ["Celestial"] = Color3.fromRGB(135, 206, 250),   -- Sky Blue
            ["Transcendent"] = Color3.fromRGB(255, 20, 147), -- Deep Pink
            ["Omnipotent"] = Color3.fromRGB(255, 50, 50),    -- Bright Red
            ["Ethereal"] = Color3.fromRGB(100, 255, 255),    -- Cyan
            ["Primordial"] = Color3.fromRGB(180, 50, 180),   -- Dark Purple
            ["Cosmic"] = Color3.fromRGB(150, 100, 255),      -- Cosmic Purple
            ["Infinite"] = Color3.fromRGB(255, 255, 255),    -- White
            ["Omniscient"] = Color3.fromRGB(255, 255, 100)   -- Light Yellow
        }
        return enhancedColors[rarity] or rarityColor
    end
    
    
    local enhancedRarityColor = getEnhancedRarityColor(petConfig.Rarity)
    local rarityHex = color3ToHex(enhancedRarityColor)
    local variationHex = color3ToHex(variationColor)
    local whitePlayerName = string.format('<font color="#FFFFFF"><b>%s</b></font>', player.Name)
    local whiteHex = "#FFFFFF"
    local goldHex = "#FFD700"
    
    local message = string.format(
        "%s <b>%s</b> <font color=\"%s\"><b>%s</b></font> <font color=\"%s\"><b>%s</b></font> <font color=\"%s\"><b>%s</b></font> <font color=\"%s\"><b>(1 in %s)</b></font>!",
        whitePlayerName,
        actionMessage,
        rarityHex, rarityName,
        variationHex, variation,
        whiteHex, petName,
        goldHex, NumberFormatter.format(odds)
    )
    
    lastAnnouncementTime = currentTime
    
    self:BroadcastMessage(message)
end

function AnnouncementService:BroadcastMessage(message)
    local success, error = pcall(function()
        local chatEvent = ReplicatedStorage:FindFirstChild("GlobalChatMessage")
        if chatEvent then
            chatEvent:FireAllClients(message)
        else
            error("GlobalChatMessage RemoteEvent not found")
        end
    end)
    
    if not success then
        warn("AnnouncementService: Failed to broadcast message:", error)
    end
end


return AnnouncementService