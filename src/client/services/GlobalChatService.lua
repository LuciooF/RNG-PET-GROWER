-- GlobalChatService - Handles server-wide chat announcements on client
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local StarterGui = game:GetService("StarterGui")

local GlobalChatService = {}
GlobalChatService.__index = GlobalChatService

local player = Players.LocalPlayer

function GlobalChatService:Initialize()
    -- Wait for the global chat message remote event with longer timeout
    task.spawn(function()
        local globalChatRemote = ReplicatedStorage:WaitForChild("GlobalChatMessage", 30)
        
        if globalChatRemote then
            -- Connect to receive global chat messages
            globalChatRemote.OnClientEvent:Connect(function(message)
                self:DisplayGlobalMessage(message)
            end)
            
        else
            warn("GlobalChatService: Timeout waiting for GlobalChatMessage remote event")
        end
    end)
end

-- Display global message using available chat system
function GlobalChatService:DisplayGlobalMessage(message)
    local success, error = pcall(function()
        -- Try multiple chat methods
        local chatWorked = false
        
        -- Method 1: Try TextChatService (new chat) - supports rich text
        if TextChatService and TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local textChannels = TextChatService:FindFirstChild("TextChannels")
            if textChannels then
                local rbxGeneral = textChannels:FindFirstChild("RBXGeneral")
                if rbxGeneral then
                    -- TextChatService supports rich text formatting
                    rbxGeneral:DisplaySystemMessage(message)
                    chatWorked = true
                end
            end
        end
        
        -- Method 2: Legacy chat fallback (doesn't support rich text, so strip tags)
        if not chatWorked then
            -- Strip rich text tags for legacy chat since it doesn't support them
            local plainMessage = string.gsub(message, "<[^>]*>", "")
            
            StarterGui:SetCore("ChatMakeSystemMessage", {
                Text = plainMessage,
                Color = Color3.fromRGB(255, 215, 0), -- Gold color for announcements
                Font = Enum.Font.FredokaOne,
                FontSize = Enum.FontSize.Size18
            })
        end
    end)
    
    if not success then
        warn("GlobalChatService: Failed to display message:", error)
    end
end

return GlobalChatService