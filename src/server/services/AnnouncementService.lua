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
local ANNOUNCEMENT_COOLDOWN = 3 -- 3 seconds between announcements

-- Helper function to get rarity order (same as PetDiscoveryService)
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
local MIN_RARITY_FOR_ANNOUNCEMENT = 4 -- Epic and above (matches popup exactly)

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

-- Helper function to find pet config by name (same as popup)
local function findPetByName(petName)
    local PetConfig = require(ReplicatedStorage.config.PetConfig)
    
    -- Extract just the pet name (remove variation suffix) - same logic as popup
    local actualPetName = petName
    local variations = {"Bronze", "Silver", "Gold", "Platinum", "Diamond", "Emerald", "Sapphire", "Ruby", "Titanium", "Obsidian", "Crystal", "Rainbow", "Cosmic", "Void", "Divine"}
    for _, variation in pairs(variations) do
        if string.find(petName, variation .. "$") then -- ends with variation
            actualPetName = string.gsub(petName, variation .. "$", "")
            break
        end
    end
    
    -- Search through all levels to find the pet - same logic as popup
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
    
    -- Anti-spam check - prevent announcement flooding (same as popup anti-spam)
    local currentTime = tick()
    if currentTime - lastAnnouncementTime < ANNOUNCEMENT_COOLDOWN then
        return -- Too soon since last announcement
    end
    
    -- Look up pet config the same way the popup does (CRITICAL - must match exactly)
    local petConfig = findPetByName(petData.Name)
    if not petConfig then
        return
    end
    
    -- Check rarity filter using pet config rarity (Epic+ only, same as discovery popup)
    local rarityOrder = getRarityOrder(petConfig.Rarity)
    if rarityOrder < MIN_RARITY_FOR_ANNOUNCEMENT then
        return -- Not rare enough rarity to announce
    end
    
    local variation = petData.Variation
    if type(variation) == "table" then
        variation = variation.VariationName
    end
    
    -- Get combined rarity chance for odds calculation (pet rarity × variation rarity)
    local odds = PetConstants.getCombinedRarityChance(petConfig.Rarity, variation)
    
    -- Debug info for troubleshooting
    if not odds then
        warn("AnnouncementService: getCombinedRarityChance returned nil for rarity:", petConfig.Rarity, "variation:", variation, "type:", type(variation))
    end
    
    -- Build the announcement message
    local petName = petData.Name or "Unknown Pet"
    local rarityName = petConfig.Rarity -- Use rarity from pet config
    
    -- Fallback if combined calculation fails
    if not odds or odds <= 0 then
        odds = PetConstants.getRarityChance(petConfig.Rarity) or 50
        warn("AnnouncementService: Combined rarity calculation failed for", petConfig.Rarity, variation, "- using pet rarity only")
    end
    
    -- Create dynamic message based on rarity (match popup behavior)
    local actionMessage = "has discovered"
    if odds >= 1000 then -- Very rare pets (1 in 1000+)
        actionMessage = "has struck GOLD and found"
    elseif odds >= 100 then -- Rare pets (1 in 100+)
        actionMessage = "has found the rare"
    end
    
    -- Get colors for rich text formatting
    local rarityColor = PetConstants.getRarityColor(petConfig.Rarity)
    local variationColor = PetConstants.getVariationColor(variation)
    
    -- Convert Color3 to hex for rich text
    local function color3ToHex(color3)
        local r = math.floor(color3.R * 255)
        local g = math.floor(color3.G * 255)
        local b = math.floor(color3.B * 255)
        return string.format("#%02X%02X%02X", r, g, b)
    end
    
    -- Enhanced rarity colors to avoid conflicts and look cooler
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
    
    -- Create rainbow player name (one color per letter) with bold
    local function createRainbowText(text)
        local rainbowColors = {
            "#FF0000", -- Red
            "#FF7F00", -- Orange
            "#FFFF00", -- Yellow
            "#00FF00", -- Green
            "#0080FF", -- Blue
            "#8000FF", -- Purple
            "#FF00FF"  -- Magenta
        }
        
        local rainbowText = ""
        for i = 1, #text do
            local char = string.sub(text, i, i)
            local colorIndex = ((i - 1) % #rainbowColors) + 1
            rainbowText = rainbowText .. string.format('<font color="%s"><b>%s</b></font>', rainbowColors[colorIndex], char)
        end
        return rainbowText
    end
    
    local enhancedRarityColor = getEnhancedRarityColor(petConfig.Rarity)
    local rarityHex = color3ToHex(enhancedRarityColor)
    local variationHex = color3ToHex(variationColor)
    local rainbowPlayerName = createRainbowText(player.Name)
    local whiteHex = "#FFFFFF" -- White for pet name
    local goldHex = "#FFD700" -- Gold for odds
    
    -- Create colorful rich text message with rainbow player name and all bold text
    local message = string.format(
        "%s <b>%s</b> <font color=\"%s\"><b>%s</b></font> <font color=\"%s\"><b>%s</b></font> <font color=\"%s\"><b>%s</b></font> <font color=\"%s\"><b>(1 in %s)</b></font>!",
        rainbowPlayerName,
        actionMessage,
        rarityHex, rarityName,
        variationHex, variation,
        whiteHex, petName,
        goldHex, NumberFormatter.format(odds)
    )
    
    -- Update last announcement time to prevent spam
    lastAnnouncementTime = currentTime
    
    -- Send to all players via TextChatService
    self:BroadcastMessage(message)
end

-- Broadcast message to all players in the server
function AnnouncementService:BroadcastMessage(message)
    -- Use RemoteEvent method primarily (TextChatService method is unreliable)
    local success, error = pcall(function()
        local chatEvent = ReplicatedStorage:FindFirstChild("GlobalChatMessage")
        if chatEvent then
            -- Fire to all clients with colored message
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