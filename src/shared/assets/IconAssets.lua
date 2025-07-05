-- Icon Assets Module
-- Contains all vector-icon-pack-2 asset IDs
-- Extracted from main assets.luau for better organization

local IconAssets = {
    -- Currency Icons
    ["vector-icon-pack-2/Currency/Cash/Cash 256.png"] = "rbxassetid://113646258809687",
    ["vector-icon-pack-2/Currency/Cash/Cash 64.png"] = "rbxassetid://79366669028417",
    ["vector-icon-pack-2/Currency/Cash/Cash Blue 256.png"] = "rbxassetid://89611993810865",
    ["vector-icon-pack-2/Currency/Cash/Cash Blue 64.png"] = "rbxassetid://91936128727051",
    ["vector-icon-pack-2/Currency/Cash/Cash Blue Outline 256.png"] = "rbxassetid://111977916989951",
    ["vector-icon-pack-2/Currency/Cash/Cash Blue Outline 64.png"] = "rbxassetid://81566872048678",
    ["vector-icon-pack-2/Currency/Cash/Cash Flat Black 256.png"] = "rbxassetid://107372087228913",
    ["vector-icon-pack-2/Currency/Cash/Cash Flat Black 64.png"] = "rbxassetid://103669460194989",
    ["vector-icon-pack-2/Currency/Cash/Cash Flat White 256.png"] = "rbxassetid://111071412417039",
    ["vector-icon-pack-2/Currency/Cash/Cash Flat White 64.png"] = "rbxassetid://93321923484254",
    ["vector-icon-pack-2/Currency/Cash/Cash Outline 256.png"] = "rbxassetid://123739018607883",
    ["vector-icon-pack-2/Currency/Cash/Cash Outline 64.png"] = "rbxassetid://89998671279248",
    
    -- Player/Friends Icons
    ["vector-icon-pack-2/Player/Friends/Friends Outline 256.png"] = "rbxassetid://109603896823206",
    
    -- General Icons (extracted from actual assets.luau usage)
    ["vector-icon-pack-2/General/Pet 2/Pet 2 Outline 256.png"] = "rbxassetid://87508636031909",
    ["vector-icon-pack-2/General/Shop/Shop Outline 256.png"] = "rbxassetid://129534417365670", 
    ["vector-icon-pack-2/General/Rebirth/Rebirth Outline 256.png"] = "rbxassetid://77419838076550",
    
    -- Currency Gems (for diamond display)
    ["vector-icon-pack-2/Currency/Gem/Gem Blue Outline 256.png"] = "rbxassetid://119428121311770",
    
    -- UI Elements
    ["vector-icon-pack-2/UI/X Button/X Button Outline 256.png"] = "rbxassetid://137122155343638",
    
    -- Music Controls
    ["vector-icon-pack-2/UI/Music/Music Outline 256.png"] = "rbxassetid://81492064422345",
    ["vector-icon-pack-2/UI/Music Off/Music Off Outline 256.png"] = "rbxassetid://90643255904101",
    
    -- Codes
    ["vector-icon-pack-2/General/Codes/Codes Outline 256.png"] = "rbxassetid://127882863069718",
    
    -- Missing assets (components have fallbacks):
    -- ["vector-icon-pack-2/General/Bug/Bug Outline 256.png"] = "N/A - Uses emoji fallback 🐛"
    
    -- NOTE: Added all critical UI assets that components actually use
    -- This fixes the invisible UI asset issue
}

return IconAssets