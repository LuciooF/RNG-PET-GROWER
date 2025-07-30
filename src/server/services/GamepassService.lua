-- GamepassService - Handles gamepass purchases and ownership
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local DataService = require(script.Parent.DataService)
local GamepassConfig = require(ReplicatedStorage.config.GamepassConfig)

local GamepassService = {}
GamepassService.__index = GamepassService

function GamepassService:Initialize()
    -- Set up marketplace service event handlers
    self:SetupMarketplaceEvents()
end

function GamepassService:SetupMarketplaceEvents()
    -- Handle successful gamepass purchases
    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
        if wasPurchased then
            print("GamepassService: Player", player.Name, "purchased gamepass", gamePassId)
            self:OnGamepassPurchased(player, gamePassId)
        end
    end)
end

-- Handle when a gamepass is purchased
function GamepassService:OnGamepassPurchased(player, gamePassId)
    -- Find which gamepass this ID corresponds to
    local gamepassName, gamepassConfig = GamepassConfig.getGamepassById(gamePassId)
    
    if gamepassName then
        -- Add to player's owned gamepasses
        local success = self:AddGamepassToPlayer(player, gamepassName)
        if success then
            print("GamepassService: Added", gamepassName, "to", player.Name)
            
            -- Sync data to client
            local StateService = require(script.Parent.StateService)
            StateService:BroadcastPlayerDataUpdate(player)
            
            -- Show success message
            self:ShowGamepassMessage(player, "Successfully purchased " .. gamepassConfig.name .. "!")
        else
            warn("GamepassService: Failed to add gamepass to player data")
        end
    else
        warn("GamepassService: Unknown gamepass ID purchased:", gamePassId)
    end
end

-- Add a gamepass to a player's owned list
function GamepassService:AddGamepassToPlayer(player, gamepassName)
    local profile = DataService:GetPlayerProfile(player)
    if not profile then
        return false
    end
    
    -- Check if player already owns this gamepass
    if self:PlayerOwnsGamepass(player, gamepassName) then
        print("GamepassService: Player already owns", gamepassName)
        return true
    end
    
    -- Add to owned gamepasses
    table.insert(profile.Data.OwnedGamepasses, gamepassName)
    return true
end

-- Remove a gamepass from a player's owned list
function GamepassService:RemoveGamepassFromPlayer(player, gamepassName)
    local profile = DataService:GetPlayerProfile(player)
    if not profile then
        return false
    end
    
    -- Find and remove the gamepass from owned list
    for i, ownedGamepass in pairs(profile.Data.OwnedGamepasses) do
        if ownedGamepass == gamepassName then
            table.remove(profile.Data.OwnedGamepasses, i)
            print("GamepassService: Removed", gamepassName, "from", player.Name)
            return true
        end
    end
    
    print("GamepassService: Player didn't have", gamepassName, "in data")
    return false
end

-- Check if a player owns a specific gamepass
function GamepassService:PlayerOwnsGamepass(player, gamepassName)
    local playerData = DataService:GetPlayerData(player)
    if not playerData then
        return false
    end
    
    for _, ownedGamepass in pairs(playerData.OwnedGamepasses or {}) do
        if ownedGamepass == gamepassName then
            return true
        end
    end
    
    return false
end

-- Get all gamepasses owned by a player
function GamepassService:GetPlayerGamepasses(player)
    local playerData = DataService:GetPlayerData(player)
    if not playerData then
        return {}
    end
    
    return playerData.OwnedGamepasses or {}
end

-- Prompt player to purchase a gamepass
function GamepassService:PromptGamepassPurchase(player, gamepassName)
    local gamepassConfig = GamepassConfig.getGamepassByName(gamepassName)
    if not gamepassConfig then
        warn("GamepassService: Unknown gamepass:", gamepassName)
        return false
    end
    
    -- Check if player already owns it
    if self:PlayerOwnsGamepass(player, gamepassName) then
        self:ShowGamepassMessage(player, "You already own " .. gamepassConfig.name .. "!")
        return false
    end
    
    -- Prompt purchase
    MarketplaceService:PromptGamePassPurchase(player, gamepassConfig.id)
    return true
end

-- Debug function to grant gamepass without purchase (for testing)
function GamepassService:DebugGrantGamepass(player, gamepassName)
    local gamepassConfig = GamepassConfig.getGamepassByName(gamepassName)
    if not gamepassConfig then
        warn("GamepassService: Unknown gamepass:", gamepassName)
        return false
    end
    
    local success = self:AddGamepassToPlayer(player, gamepassName)
    if success then
        print("GamepassService: DEBUG - Granted", gamepassName, "to", player.Name)
        
        -- Sync data to client
        local StateService = require(script.Parent.StateService)
        StateService:BroadcastPlayerDataUpdate(player)
        
        -- Show success message
        self:ShowGamepassMessage(player, "DEBUG: Granted " .. gamepassConfig.name .. "!")
        return true
    end
    
    return false
end

-- Show a message to the player about gamepass status
function GamepassService:ShowGamepassMessage(player, message)
    local errorMessageRemote = ReplicatedStorage:FindFirstChild("ShowErrorMessage")
    if errorMessageRemote then
        errorMessageRemote:FireClient(player, message)
    else
        warn("GamepassService: ShowErrorMessage remote not found")
    end
end

-- Toggle a gamepass setting for a player
function GamepassService:ToggleGamepassSetting(player, settingName)
    local profile = DataService:GetPlayerProfile(player)
    if not profile then
        return false
    end
    
    -- Ensure GamepassSettings exists
    if not profile.Data.GamepassSettings then
        profile.Data.GamepassSettings = {
            AutoHeavenEnabled = true,
            PetMagnetEnabled = true
        }
    end
    
    -- Toggle the setting
    if settingName == "AutoHeavenEnabled" then
        local currentValue = profile.Data.GamepassSettings.AutoHeavenEnabled
        profile.Data.GamepassSettings.AutoHeavenEnabled = not currentValue
        
        local newValue = profile.Data.GamepassSettings.AutoHeavenEnabled
        print("GamepassService: Toggled", settingName, "for", player.Name, "to", newValue)
        
        -- Sync data to client
        local StateService = require(script.Parent.StateService)
        StateService:BroadcastPlayerDataUpdate(player)
        
        -- Show message to player
        local message = newValue and "Auto Heaven: ON" or "Auto Heaven: OFF"
        self:ShowGamepassMessage(player, message)
        
        return true
    elseif settingName == "PetMagnetEnabled" then
        local currentValue = profile.Data.GamepassSettings.PetMagnetEnabled
        profile.Data.GamepassSettings.PetMagnetEnabled = not currentValue
        
        local newValue = profile.Data.GamepassSettings.PetMagnetEnabled
        print("GamepassService: Toggled", settingName, "for", player.Name, "to", newValue)
        
        -- Sync data to client
        local StateService = require(script.Parent.StateService)
        StateService:BroadcastPlayerDataUpdate(player)
        
        -- Show message to player
        local message = newValue and "Pet Magnet: ON" or "Pet Magnet: OFF"
        self:ShowGamepassMessage(player, message)
        
        return true
    end
    
    return false
end

-- Check gamepass ownership on player join (in case they bought it while offline or removed)
function GamepassService:ValidatePlayerGamepasses(player)
    local profile = DataService:GetPlayerProfile(player)
    if not profile then
        warn("GamepassService: No profile found for player", player.Name)
        return
    end
    
    local gamepassesChanged = false
    
    -- Check all configured gamepasses against Roblox ownership
    for gamepassName, gamepassConfig in pairs(GamepassConfig.getAllGamepasses()) do
        local success, ownsGamepass = pcall(function()
            return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassConfig.id)
        end)
        
        if success then
            local playerHasInData = self:PlayerOwnsGamepass(player, gamepassName)
            
            if ownsGamepass and not playerHasInData then
                -- Player owns this gamepass on Roblox but not in data - add it
                print("GamepassService: Player", player.Name, "owns", gamepassName, "on Roblox but not in data - adding")
                self:AddGamepassToPlayer(player, gamepassName)
                gamepassesChanged = true
                
            elseif not ownsGamepass and playerHasInData then
                -- Player doesn't own this gamepass on Roblox but has it in data - remove it
                print("GamepassService: Player", player.Name, "doesn't own", gamepassName, "on Roblox but has it in data - removing")
                self:RemoveGamepassFromPlayer(player, gamepassName)
                gamepassesChanged = true
            end
        else
            warn("GamepassService: Failed to check ownership for", gamepassName, "for player", player.Name)
        end
    end
    
    -- Sync updated data to client if any changes were made
    if gamepassesChanged then
        local StateService = require(script.Parent.StateService)
        StateService:BroadcastPlayerDataUpdate(player)
    end
    
    local ownedGamepasses = self:GetPlayerGamepasses(player)
    print("GamepassService: Player", player.Name, "validated gamepasses:", table.concat(ownedGamepasses, ", "))
end

return GamepassService