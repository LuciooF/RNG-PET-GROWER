-- FavoritePromptService - Shows favorite prompt after 1 minute of playtime
local AvatarEditorService = game:GetService("AvatarEditorService")

local FavoritePromptService = {}
FavoritePromptService.__index = FavoritePromptService

local hasShownPrompt = false
local GAME_ID = 133559088499288

function FavoritePromptService:Initialize()
    -- Wait 1 minute then show favorite prompt
    task.spawn(function()
        task.wait(60) -- 1 minute
        
        if not hasShownPrompt then
            hasShownPrompt = true
            AvatarEditorService:PromptSetFavorite(GAME_ID, 1, true)
        end
    end)
    
    print("FavoritePromptService: Initialized")
end

function FavoritePromptService:Cleanup()
    -- Nothing to cleanup
end

return FavoritePromptService