-- IconAssets - Centralized UI icons with Roblox asset IDs
local IconAssets = {}

-- UI Action Icons
IconAssets.UI = {
    REBIRTH = "rbxassetid://92717178060094",
    PET = "rbxassetid://138531430194385",
    PET2 = "rbxassetid://75809518369670",
    INDEX = "rbxassetid://98181721431436",
    SETTINGS = "rbxassetid://130394376204059",
    BOOST = "rbxassetid://94893203982408",
    X_BUTTON = "rbxassetid://127395587086818",
    SQUIGGLE = "rbxassetid://90469870388671", -- Pet card background squiggle (white version)
    TROPHY = "rbxassetid://109359695542141", -- Leaderboard trophy icon
    CHEST_LEVEL = "rbxassetid://138661508380946", -- Chest level upgrade icon
    LUCK = "rbxassetid://132766128034954", -- Luck upgrade icon
    PLUS = "rbxassetid://113659939452435", -- Plus icon for expanding limits
    VIP = "rbxassetid://136192524148303", -- VIP gamepass icon
    TWO_X_MONEY = "rbxassetid://83944209149942", -- 2x Money gamepass icon
    -- Add more UI icons here as needed
    -- SHOP = "rbxassetid://...",
    -- CLOSE = "rbxassetid://...",
}

-- Game Feature Icons
IconAssets.FEATURES = {
    -- Add feature-specific icons here
    -- PET_MIXER = "rbxassetid://...",
    -- AUTO_HEAVEN = "rbxassetid://...",
    -- PET_MAGNET = "rbxassetid://...",
}

-- Particle Effects and Visual Assets
IconAssets.PARTICLES = {
    CRAZY_CHEST_REWARD = "rbxassetid://688963157", -- Reward particle effect for crazy chest
    -- Add more particle effects here as needed
    -- EXPLOSION = "rbxassetid://...",
    -- SPARKLE = "rbxassetid://...",
    -- MAGIC = "rbxassetid://...",
}

-- Currency Icons
IconAssets.CURRENCY = {
    MONEY = "rbxassetid://80960000119108",
    DIAMONDS = "rbxassetid://135421873302468",
    ROBUX = "rbxassetid://100296166775625",
}

-- Status Icons
IconAssets.STATUS = {
    LOCKED = "rbxassetid://139266803709755",
    UNLOCKED = "rbxassetid://114864766926977",
    -- Add more status/indicator icons here
    -- EQUIPPED = "rbxassetid://...",
}

-- Helper function to get icon by category and name
function IconAssets.getIcon(category, iconName)
    local categoryTable = IconAssets[category]
    if categoryTable and categoryTable[iconName] then
        return categoryTable[iconName]
    end
    warn("IconAssets: Icon not found -", category, iconName)
    return ""
end

-- Helper function to create ImageLabel with icon
function IconAssets.createImageLabel(category, iconName, properties)
    properties = properties or {}
    
    local imageLabel = Instance.new("ImageLabel")
    imageLabel.Image = IconAssets.getIcon(category, iconName)
    imageLabel.BackgroundTransparency = 1
    imageLabel.ScaleType = Enum.ScaleType.Fit
    imageLabel.SizeConstraint = Enum.SizeConstraint.RelativeYY -- Maintain aspect ratio
    
    -- Apply custom properties
    for property, value in pairs(properties) do
        imageLabel[property] = value
    end
    
    return imageLabel
end

-- Helper function to create ImageButton with icon
function IconAssets.createImageButton(category, iconName, properties)
    properties = properties or {}
    
    local imageButton = Instance.new("ImageButton")
    imageButton.Image = IconAssets.getIcon(category, iconName)
    imageButton.BackgroundTransparency = 1
    imageButton.ScaleType = Enum.ScaleType.Fit
    imageButton.SizeConstraint = Enum.SizeConstraint.RelativeYY -- Maintain aspect ratio
    
    -- Apply custom properties
    for property, value in pairs(properties) do
        imageButton[property] = value
    end
    
    return imageButton
end

return IconAssets