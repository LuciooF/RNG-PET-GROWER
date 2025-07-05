-- Codes Manager
-- Handles code validation and reward distribution on the server

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

-- Get required modules
local PlayerService = require(script.Parent.Parent.services.PlayerService)

local CodesManager = {}

-- DataStore for tracking redeemed codes and daily usage
local redeemedCodesDataStore = nil
local dailyCodesDataStore = nil
pcall(function()
    redeemedCodesDataStore = DataStoreService:GetDataStore("PetGrowerRedeemedCodes")
    dailyCodesDataStore = DataStoreService:GetDataStore("PetGrowerDailyCodes")
end)

-- Valid codes configuration
local VALID_CODES = {
    ["WELCOME"] = {
        rewardType = "diamonds",
        rewardAmount = 500,
        description = "Welcome to Pet Grower RNG!",
        oneTimeUse = true,
        expiresAt = nil -- Never expires
    },
    ["TODAY"] = {
        rewardType = "diamonds",
        rewardAmount = 500,
        description = "Daily diamond bonus!",
        dailyUse = true,
        expiresAt = nil -- Never expires
    }
}

-- Get current date string for daily codes (format: YYYY-MM-DD)
local function getCurrentDateString()
    local date = os.date("*t")
    return string.format("%04d-%02d-%02d", date.year, date.month, date.day)
end

-- Check if a one-time code has been redeemed by a player
local function hasRedeemedOneTimeCode(player, code)
    if not redeemedCodesDataStore then
        warn("CodesManager: DataStore not available, cannot check redeemed codes")
        return false
    end
    
    local success, redeemed = pcall(function()
        local key = "Player_" .. player.UserId .. "_Code_" .. code
        return redeemedCodesDataStore:GetAsync(key)
    end)
    
    if not success then
        warn("CodesManager: Failed to check redeemed code:", redeemed)
        return false
    end
    
    return redeemed == true
end

-- Check if a daily code has been redeemed today by a player
local function hasRedeemedDailyCodeToday(player, code)
    if not dailyCodesDataStore then
        warn("CodesManager: DataStore not available, cannot check daily codes")
        return false
    end
    
    local success, lastRedeemed = pcall(function()
        local key = "Player_" .. player.UserId .. "_DailyCode_" .. code
        return dailyCodesDataStore:GetAsync(key)
    end)
    
    if not success then
        warn("CodesManager: Failed to check daily code:", lastRedeemed)
        return false
    end
    
    local currentDate = getCurrentDateString()
    return lastRedeemed == currentDate
end

-- Mark a one-time code as redeemed by a player
local function markOneTimeCodeAsRedeemed(player, code)
    if not redeemedCodesDataStore then
        warn("CodesManager: DataStore not available, cannot mark code as redeemed")
        return false
    end
    
    local success, err = pcall(function()
        local key = "Player_" .. player.UserId .. "_Code_" .. code
        redeemedCodesDataStore:SetAsync(key, true)
    end)
    
    if not success then
        warn("CodesManager: Failed to mark code as redeemed:", err)
        return false
    end
    
    return true
end

-- Mark a daily code as redeemed today by a player
local function markDailyCodeAsRedeemedToday(player, code)
    if not dailyCodesDataStore then
        warn("CodesManager: DataStore not available, cannot mark daily code as redeemed")
        return false
    end
    
    local success, err = pcall(function()
        local key = "Player_" .. player.UserId .. "_DailyCode_" .. code
        local currentDate = getCurrentDateString()
        dailyCodesDataStore:SetAsync(key, currentDate)
    end)
    
    if not success then
        warn("CodesManager: Failed to mark daily code as redeemed:", err)
        return false
    end
    
    return true
end

-- Clear all redeemed codes for a player (debug function)
function CodesManager.clearPlayerCodes(player)
    if not redeemedCodesDataStore or not dailyCodesDataStore then
        warn("CodesManager: DataStores not available, cannot clear codes")
        return false
    end
    
    local success, err = pcall(function()
        -- Clear all one-time codes for this player
        for code, codeData in pairs(VALID_CODES) do
            if codeData.oneTimeUse then
                local key = "Player_" .. player.UserId .. "_Code_" .. code
                redeemedCodesDataStore:RemoveAsync(key)
            end
        end
        
        -- Clear all daily codes for this player
        for code, codeData in pairs(VALID_CODES) do
            if codeData.dailyUse then
                local key = "Player_" .. player.UserId .. "_DailyCode_" .. code
                dailyCodesDataStore:RemoveAsync(key)
            end
        end
    end)
    
    if not success then
        warn("CodesManager: Failed to clear player codes:", err)
        return false
    end
    
    print("CodesManager: Cleared all codes for player:", player.Name)
    return true
end

-- Initialize the codes manager
function CodesManager.initialize()
    print("CodesManager: Initializing with", #VALID_CODES, "valid codes")
    
    -- Create remotes folder if it doesn't exist
    local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotesFolder then
        remotesFolder = Instance.new("Folder")
        remotesFolder.Name = "Remotes"
        remotesFolder.Parent = ReplicatedStorage
    end
    
    -- Create remotes
    local redeemCodeRemote = Instance.new("RemoteEvent")
    redeemCodeRemote.Name = "redeemCode"
    redeemCodeRemote.Parent = remotesFolder
    
    local clearCodesRemote = Instance.new("RemoteEvent")
    clearCodesRemote.Name = "clearCodes"
    clearCodesRemote.Parent = remotesFolder
    
    print("CodesManager: Created remote events")
    
    -- Handle code redemption requests
    redeemCodeRemote.OnServerEvent:Connect(function(player, code)
        if not code or type(code) ~= "string" then
            warn("CodesManager: Invalid code redemption request from", player.Name)
            redeemCodeRemote:FireClient(player, false, nil)
            return
        end
        
        -- Clean up the code (uppercase, trim whitespace)
        code = string.upper(string.gsub(code, "^%s*(.-)%s*$", "%1"))
        
        print("CodesManager: Player", player.Name, "attempting to redeem code:", code)
        
        -- Check if code is valid
        local codeData = VALID_CODES[code]
        if not codeData then
            print("CodesManager: Invalid code attempted:", code)
            redeemCodeRemote:FireClient(player, false, {
                error = "invalid_code",
                message = "Invalid code!"
            })
            return
        end
        
        -- Check if code has expired
        if codeData.expiresAt and os.time() > codeData.expiresAt then
            print("CodesManager: Expired code attempted:", code)
            redeemCodeRemote:FireClient(player, false, {
                error = "invalid_code",
                message = "This code has expired!"
            })
            return
        end
        
        -- Check redemption status based on code type
        if codeData.oneTimeUse then
            if hasRedeemedOneTimeCode(player, code) then
                print("CodesManager: Player", player.Name, "has already redeemed one-time code:", code)
                redeemCodeRemote:FireClient(player, false, {
                    error = "already_redeemed",
                    message = "You have already redeemed this code!"
                })
                return
            end
        elseif codeData.dailyUse then
            if hasRedeemedDailyCodeToday(player, code) then
                print("CodesManager: Player", player.Name, "has already redeemed daily code today:", code)
                redeemCodeRemote:FireClient(player, false, {
                    error = "daily_limit",
                    message = "You have already redeemed this code today! Come back tomorrow!"
                })
                return
            end
        end
        
        -- Apply the reward using PlayerService
        local success = false
        if codeData.rewardType == "diamonds" then
            -- Give diamonds reward
            success = PlayerService:GiveDiamonds(player, codeData.rewardAmount)
            if success then
                print("CodesManager: Gave", player.Name, codeData.rewardAmount, "diamonds from code:", code)
            end
            
        elseif codeData.rewardType == "money" then
            -- Give money reward  
            success = PlayerService:GiveMoney(player, codeData.rewardAmount)
            if success then
                print("CodesManager: Gave", player.Name, "$" .. codeData.rewardAmount, "from code:", code)
            end
        end
        
        if success then
            -- Mark code as redeemed based on type
            if codeData.oneTimeUse then
                markOneTimeCodeAsRedeemed(player, code)
            elseif codeData.dailyUse then
                markDailyCodeAsRedeemedToday(player, code)
            end
            
            -- PlayerService:GiveDiamonds/GiveMoney already handles syncing and saving data
            
            -- Send success response
            redeemCodeRemote:FireClient(player, true, {
                code = code,
                rewardType = codeData.rewardType,
                rewardAmount = codeData.rewardAmount,
                description = codeData.description
            })
            
            print("CodesManager: Code", code, "successfully redeemed by", player.Name)
        else
            redeemCodeRemote:FireClient(player, false, {
                error = "server_error",
                message = "Failed to apply reward, please try again!"
            })
        end
    end)
    
    -- Handle clear codes requests (debug only)
    clearCodesRemote.OnServerEvent:Connect(function(player)
        print("CodesManager: Debug - Clearing codes for player", player.Name)
        local success = CodesManager.clearPlayerCodes(player)
        clearCodesRemote:FireClient(player, success)
    end)
    
    print("CodesManager: Initialization complete")
end

-- Add a new code (for admin use)
function CodesManager.addCode(code, rewardData)
    if not code or not rewardData then
        warn("CodesManager: Invalid code data provided")
        return false
    end
    
    VALID_CODES[string.upper(code)] = rewardData
    print("CodesManager: Added new code:", code)
    return true
end

-- Remove a code (for admin use)
function CodesManager.removeCode(code)
    if not code then
        return false
    end
    
    code = string.upper(code)
    if VALID_CODES[code] then
        VALID_CODES[code] = nil
        print("CodesManager: Removed code:", code)
        return true
    end
    
    return false
end

-- Get all valid codes (for admin use)
function CodesManager.getValidCodes()
    local codes = {}
    for code, data in pairs(VALID_CODES) do
        codes[code] = data
    end
    return codes
end

return CodesManager