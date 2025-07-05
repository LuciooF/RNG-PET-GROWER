-- Color Palette Utility
-- Centralized color definitions to eliminate code duplication
-- Use this instead of hardcoded Color3.fromRGB() values throughout the codebase

local ColorPalette = {}

-- Basic Colors (most commonly duplicated)
ColorPalette.WHITE = Color3.fromRGB(255, 255, 255)
ColorPalette.BLACK = Color3.fromRGB(0, 0, 0)
ColorPalette.TRANSPARENT = Color3.fromRGB(255, 255, 255) -- Use with Transparency = 1

-- UI Theme Colors
ColorPalette.UI = {
    -- Backgrounds
    DARK_BACKGROUND = Color3.fromRGB(30, 30, 30),
    LIGHT_BACKGROUND = Color3.fromRGB(240, 245, 255),
    MODAL_BACKGROUND = Color3.fromRGB(50, 50, 50),
    CARD_BACKGROUND = Color3.fromRGB(255, 255, 255),
    
    -- Buttons
    PRIMARY_BUTTON = Color3.fromRGB(100, 150, 255),
    SUCCESS_BUTTON = Color3.fromRGB(0, 255, 0),
    DANGER_BUTTON = Color3.fromRGB(255, 0, 0),
    WARNING_BUTTON = Color3.fromRGB(255, 150, 0),
    SECONDARY_BUTTON = Color3.fromRGB(169, 169, 169),
    
    -- Text Colors
    PRIMARY_TEXT = Color3.fromRGB(255, 255, 255),
    SECONDARY_TEXT = Color3.fromRGB(200, 200, 200),
    ACCENT_TEXT = Color3.fromRGB(255, 215, 0),
    ERROR_TEXT = Color3.fromRGB(255, 100, 100),
    
    -- Borders and Strokes
    BORDER_COLOR = Color3.fromRGB(255, 255, 255),
    ACCENT_BORDER = Color3.fromRGB(100, 200, 255),
    ERROR_BORDER = Color3.fromRGB(255, 100, 100)
}

-- Game-Specific Colors
ColorPalette.GAME = {
    -- Currency Colors
    MONEY_COLOR = Color3.fromRGB(0, 255, 0),
    DIAMOND_COLOR = Color3.fromRGB(100, 200, 255),
    REBIRTH_COLOR = Color3.fromRGB(255, 150, 50),
    
    -- Status Colors
    AFFORDABLE = Color3.fromRGB(0, 255, 0),
    CANT_AFFORD = Color3.fromRGB(255, 0, 0),
    OWNED = Color3.fromRGB(255, 255, 255),
    LOCKED = Color3.fromRGB(0, 0, 0),
    
    -- Heaven/Processing Colors
    HEAVEN_GOLD = Color3.fromRGB(255, 215, 0),
    PROCESSING_BLUE = Color3.fromRGB(100, 150, 255),
    
    -- Boost Colors
    BOOST_ACTIVE = Color3.fromRGB(255, 215, 0),
    BOOST_INACTIVE = Color3.fromRGB(100, 100, 100),
    
    -- Success/Danger Colors for music button
    SUCCESS = Color3.fromRGB(180, 255, 180),
    SUCCESS_DARK = Color3.fromRGB(120, 220, 120),
    DANGER = Color3.fromRGB(255, 180, 180),
    DANGER_DARK = Color3.fromRGB(220, 120, 120)
}

-- Rarity Colors (matches cylinder/plot colors)
ColorPalette.RARITY = {
    [1] = Color3.fromRGB(139, 69, 19),    -- Brown (Basic)
    [2] = Color3.fromRGB(169, 169, 169),  -- Silver (Advanced)
    [3] = Color3.fromRGB(255, 215, 0),    -- Gold (Premium)
    [4] = Color3.fromRGB(138, 43, 226),   -- Purple (Elite)
    [5] = Color3.fromRGB(255, 20, 147)    -- Pink (Master/Legendary)
}

-- Pet-Related Colors
ColorPalette.PET = {
    -- Size Colors
    TINY = Color3.fromRGB(150, 150, 150),     -- Gray
    SMALL = Color3.fromRGB(100, 255, 100),    -- Light green
    NORMAL = Color3.fromRGB(100, 150, 255),   -- Light blue
    LARGE = Color3.fromRGB(255, 150, 100),    -- Light orange
    HUGE = Color3.fromRGB(255, 100, 255),     -- Light purple
    GIANT = Color3.fromRGB(255, 215, 0),      -- Gold
    
    -- Aura Colors
    DIAMOND_AURA = Color3.fromRGB(185, 242, 255),
    GOLDEN_AURA = Color3.fromRGB(255, 215, 0),
    RAINBOW_AURA = Color3.fromRGB(255, 100, 255)
}

-- Gradient Helper Functions
function ColorPalette.createGradient(startColor, endColor)
    return ColorSequence.new{
        ColorSequenceKeypoint.new(0, startColor),
        ColorSequenceKeypoint.new(1, endColor)
    }
end

function ColorPalette.createThreePointGradient(startColor, midColor, endColor)
    return ColorSequence.new{
        ColorSequenceKeypoint.new(0, startColor),
        ColorSequenceKeypoint.new(0.5, midColor),
        ColorSequenceKeypoint.new(1, endColor)
    }
end

-- Color Utility Functions
function ColorPalette.darken(color, factor)
    factor = factor or 0.7
    return Color3.fromRGB(
        math.floor(color.R * 255 * factor),
        math.floor(color.G * 255 * factor),
        math.floor(color.B * 255 * factor)
    )
end

function ColorPalette.lighten(color, factor)
    factor = factor or 1.3
    return Color3.fromRGB(
        math.min(255, math.floor(color.R * 255 * factor)),
        math.min(255, math.floor(color.G * 255 * factor)),
        math.min(255, math.floor(color.B * 255 * factor))
    )
end

function ColorPalette.withAlpha(color, alpha)
    -- Returns color info for use with BackgroundTransparency
    return {
        color = color,
        transparency = 1 - alpha
    }
end

-- Common Gradient Presets
ColorPalette.GRADIENTS = {
    GOLD_SHINE = ColorPalette.createGradient(
        Color3.fromRGB(255, 235, 100),
        Color3.fromRGB(255, 200, 50)
    ),
    BLUE_SHINE = ColorPalette.createGradient(
        Color3.fromRGB(150, 200, 255),
        Color3.fromRGB(100, 150, 255)
    ),
    DARK_TO_LIGHT = ColorPalette.createGradient(
        ColorPalette.BLACK,
        Color3.fromRGB(100, 100, 100)
    ),
    RAINBOW = ColorPalette.createThreePointGradient(
        Color3.fromRGB(255, 0, 0),
        Color3.fromRGB(0, 255, 0),
        Color3.fromRGB(0, 0, 255)
    )
}

-- Helper function to get rarity color with fallback
function ColorPalette.getRarityColor(rarity)
    return ColorPalette.RARITY[rarity] or ColorPalette.RARITY[1]
end

-- Theme switching support (for future dark/light mode)
ColorPalette.THEMES = {
    DARK = {
        background = ColorPalette.UI.DARK_BACKGROUND,
        text = ColorPalette.UI.PRIMARY_TEXT,
        accent = ColorPalette.UI.ACCENT_TEXT
    },
    LIGHT = {
        background = ColorPalette.UI.LIGHT_BACKGROUND,
        text = ColorPalette.BLACK,
        accent = ColorPalette.UI.PRIMARY_BUTTON
    }
}

function ColorPalette.getThemeColors(themeName)
    return ColorPalette.THEMES[themeName] or ColorPalette.THEMES.DARK
end

return ColorPalette