-- Codes Service
-- Handles code redemption and validation

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RewardsService = require(script.Parent.RewardsService)

local CodesService = {}

-- Initialize the service
function CodesService.initialize(remotes)
    -- Listen for code redemption responses
    if remotes.redeemCode then
        remotes.redeemCode.OnClientEvent:Connect(function(success, responseData)
            if success and responseData then
                print("[INFO] Code redeemed successfully:", responseData.code)
                
                -- Show reward using RewardsService
                if responseData.rewardType == "diamonds" then
                    RewardsService.showReward({
                        type = "diamonds",
                        amount = responseData.rewardAmount,
                        title = "Diamonds Received!",
                        description = "Code '" .. responseData.code .. "' gave you " .. responseData.rewardAmount .. " diamonds!",
                        iconAsset = "vector-icon-pack-2/Currency/Gem/Gem Blue Outline 256.png",
                        color = Color3.fromRGB(100, 150, 255),
                        rarity = "rare"
                    })
                elseif responseData.rewardType == "money" then
                    RewardsService.showMoneyReward(
                        responseData.rewardAmount,
                        "Code '" .. responseData.code .. "' redeemed!"
                    )
                elseif responseData.rewardType == "pets" then
                    -- Future pet reward implementation
                    RewardsService.showPetReward(
                        responseData.petType or "Cat",
                        responseData.petName or "Special Pet",
                        "Code '" .. responseData.code .. "' gave you a " .. (responseData.petName or "Special Pet") .. "!"
                    )
                end
                
                -- Return success to UI
                if CodesService.onRedeemCallback then
                    CodesService.onRedeemCallback(true, responseData.code, nil)
                end
            else
                print("[WARN] Code redemption failed")
                
                -- Handle different types of failures
                local errorMessage = "Invalid or already redeemed code!"
                local errorType = "generic"
                
                if responseData and responseData.error then
                    if responseData.error == "already_redeemed" then
                        errorType = "already_redeemed"
                        errorMessage = responseData.message or "You have already redeemed this code!"
                    elseif responseData.error == "invalid_code" then
                        errorType = "invalid_code"
                        errorMessage = responseData.message or "Invalid code!"
                    elseif responseData.error == "daily_limit" then
                        errorType = "daily_limit"
                        errorMessage = responseData.message or "You can only redeem this code once per day!"
                    end
                end
                
                -- Return failure to UI
                if CodesService.onRedeemCallback then
                    CodesService.onRedeemCallback(false, nil, {type = errorType, message = errorMessage})
                end
            end
        end)
    end
    
    -- Listen for clear codes responses
    if remotes.clearCodes then
        remotes.clearCodes.OnClientEvent:Connect(function(success)
            if success then
                print("[INFO] Codes cleared successfully")
            else
                print("[WARN] Failed to clear codes")
            end
        end)
    end
end

-- Redeem a code
function CodesService.redeemCode(code, remotes)
    if not code or code == "" then
        print("[WARN] No code provided")
        return false
    end
    
    -- Trim whitespace and convert to uppercase
    code = string.upper(string.gsub(code, "^%s*(.-)%s*$", "%1"))
    
    print("[INFO] Attempting to redeem code:", code)
    
    if remotes.redeemCode then
        remotes.redeemCode:FireServer(code)
        return true
    else
        warn("Redeem code remote not available")
        return false
    end
end

-- Clear all redeemed codes (debug function)
function CodesService.clearCodes(remotes)
    print("[INFO] Clearing all redeemed codes...")
    
    if remotes.clearCodes then
        remotes.clearCodes:FireServer()
        return true
    else
        warn("Clear codes remote not available")
        return false
    end
end

-- Set callback for UI updates
function CodesService.setRedeemCallback(callback)
    CodesService.onRedeemCallback = callback
end

return CodesService