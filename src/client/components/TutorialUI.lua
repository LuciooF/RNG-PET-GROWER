-- TutorialUI - Simple tutorial system with clean text display
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local React = require(ReplicatedStorage.Packages.react)

local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local IconAssets = require(ReplicatedStorage.utils.IconAssets)
local DataSyncService = require(script.Parent.Parent.services.DataSyncService)
local TutorialService = require(script.Parent.Parent.services.TutorialService)

local TutorialUI = {}

-- Constants
local UI_CONSTANTS = {
    PANEL_WIDTH = 400,
    PANEL_WIDTH_RATIO = 0.35,
    MARGIN = 20,
    TEXT_SIZE_OFFSET = 8,
    PROGRESS_TEXT_SIZE_OFFSET = 6,
    REWARD_TEXT_SIZE_OFFSET = 4,
}

-- Helper function to remove emojis from step titles
local function removeEmojis(text)
    local emojis = {"🏗️ ", "🐾 ", "🧪 ", "⚙️ ", "🚪 ", "✨ ", "🎁 ", "🌟 ", "🔮 "}
    for _, emoji in ipairs(emojis) do
        text = text:gsub(emoji, "")
    end
    return text
end

-- Helper function to determine progress color
local function getProgressColor(progressText)
    if progressText == "100%" then
        return Color3.fromRGB(50, 255, 50) -- Bright green when complete
    elseif progressText:find("/") then
        -- For X/Y format, check if X equals Y
        local current, total = progressText:match("(%d+)/(%d+)")
        if current and total and tonumber(current) >= tonumber(total) then
            return Color3.fromRGB(50, 255, 50) -- Bright green when complete
        else
            return Color3.fromRGB(255, 255, 0) -- Yellow for in progress
        end
    else
        return Color3.fromRGB(255, 255, 0) -- Yellow for in progress
    end
end

local function TutorialPanel(props)
    local visible = props.visible or false
    local currentStep = props.currentStep or 1
    local tutorialData = props.tutorialData or {}
    
    if not visible or not tutorialData.steps or #tutorialData.steps == 0 then
        return nil
    end
    
    local step = tutorialData.steps[currentStep]
    if not step then
        return nil
    end
    
    -- Get screen size for responsive sizing
    local screenSize = ScreenUtils.getScreenSize()
    
    -- Create simple tutorial text format
    local totalSteps = #tutorialData.steps
    local stepTitle = removeEmojis(step.title or "Step " .. currentStep)
    local instructionText = "Tutorial: Step " .. currentStep .. "/" .. totalSteps .. "\n" .. stepTitle
    
    -- Get progress for this step
    local progressText = TutorialService:GetProgressText() or "0%"
    local progressColor = getProgressColor(progressText)
    
    -- Get reward amount for this step
    local rewardAmount = step.reward and step.reward.amount or 0
    
    return React.createElement("ScreenGui", {
        Name = "TutorialUI",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    }, {
        -- Tutorial container (bottom right)
        TutorialContainer = React.createElement("Frame", {
            Size = UDim2.new(0, math.min(UI_CONSTANTS.PANEL_WIDTH, screenSize.X * UI_CONSTANTS.PANEL_WIDTH_RATIO), 0, 0), -- Fixed width based on screen, auto height
            AutomaticSize = Enum.AutomaticSize.Y,
            Position = UDim2.new(1, -UI_CONSTANTS.MARGIN, 1, -UI_CONSTANTS.MARGIN), -- Bottom right corner with margin
            AnchorPoint = Vector2.new(1, 1), -- Anchor to bottom right
            BackgroundTransparency = 1,
            ZIndex = 200,
        }, {
            Layout = React.createElement("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                VerticalAlignment = Enum.VerticalAlignment.Bottom,
                Padding = ScreenUtils.udim(0, 5),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
            
            -- Main instruction text
            InstructionText = React.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0, 0), -- Full width, auto height
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Text = instructionText,
                TextColor3 = Color3.fromRGB(255, 255, 255), -- White text
                TextSize = ScreenUtils.TEXT_SIZES.HEADER() + UI_CONSTANTS.TEXT_SIZE_OFFSET, -- Bigger text
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextYAlignment = Enum.TextYAlignment.Bottom,
                TextWrapped = true,
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0), -- Black outline
                ZIndex = 201,
                LayoutOrder = 1,
            }),
            
            -- Progress indicator
            ProgressText = React.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0, 0), -- Full width, auto height
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Text = "Progress: " .. progressText,
                TextColor3 = progressColor, -- Dynamic color based on progress
                TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() + UI_CONSTANTS.PROGRESS_TEXT_SIZE_OFFSET, -- Bigger progress text
                Font = Enum.Font.FredokaOne,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextYAlignment = Enum.TextYAlignment.Bottom,
                TextWrapped = true,
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0), -- Black outline
                ZIndex = 201,
                LayoutOrder = 2,
            }),
            
            -- Reward indicator with diamond icon
            RewardContainer = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, 0), -- Full width, auto height
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                ZIndex = 201,
                LayoutOrder = 3,
            }, {
                Layout = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Right,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = ScreenUtils.udim(0, 5),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }),
                
                RewardText = React.createElement("TextLabel", {
                    Size = UDim2.new(0, 0, 0, 0), -- Auto size both dimensions
                    AutomaticSize = Enum.AutomaticSize.XY,
                    BackgroundTransparency = 1,
                    Text = "Reward: " .. rewardAmount,
                    TextColor3 = Color3.fromRGB(100, 150, 255), -- Blue text
                    TextSize = ScreenUtils.TEXT_SIZES.MEDIUM() + UI_CONSTANTS.REWARD_TEXT_SIZE_OFFSET,
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0), -- Black outline
                    ZIndex = 202,
                    LayoutOrder = 1,
                }),
                
                DiamondIcon = React.createElement("ImageLabel", {
                    Size = UDim2.new(0, ScreenUtils.TEXT_SIZES.MEDIUM() + UI_CONSTANTS.REWARD_TEXT_SIZE_OFFSET, 0, ScreenUtils.TEXT_SIZES.MEDIUM() + UI_CONSTANTS.REWARD_TEXT_SIZE_OFFSET), -- Size to match text
                    BackgroundTransparency = 1,
                    Image = IconAssets.getIcon("CURRENCY", "DIAMONDS"),
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 202,
                    LayoutOrder = 2,
                })
            })
        }),
    })
end

function TutorialUI.new(props)
    return React.createElement(TutorialPanel, props)
end

return TutorialUI