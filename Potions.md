# Potion System Design Document

## Overview
The Potion system will provide players with temporary boosts through consumable items. Players can collect potions, store them in inventory, and activate them for timed benefits.

## Core Architecture

### 1. Potion Data Structure

#### Base Potion Definition (Config)
```lua
{
    PotionId = "diamond_2x_10m",
    Name = "2x Diamond Potion",
    Description = "Doubles diamond earnings for 10 minutes",
    Icon = "rbxassetid://104089702525726",
    BoostType = "Diamonds", -- "Diamonds", "Money", "PetDropRate", etc.
    BoostAmount = 2, -- Multiplier (2x, 3x, etc.)
    Duration = 600, -- Duration in seconds (10 minutes = 600s)
    Rarity = "Common", -- For future expansion
    StackLimit = 10 -- Max amount player can hold
}
```

#### Player Inventory Potion
```lua
{
    PotionId = "diamond_2x_10m",
    Quantity = 3 -- How many the player owns
}
```

#### Active/Equipped Potion
```lua
{
    PotionId = "diamond_2x_10m",
    ActivatedAt = 1703123456, -- Unix timestamp when activated
    ExpiresAt = 1703124056, -- Unix timestamp when it expires (ActivatedAt + Duration)
    RemainingTime = 480 -- Seconds remaining (calculated dynamically)
}
```

## 2. System Components

### Configuration Files
- **`src/shared/config/PotionConfig.lua`**
  - Define all available potions
  - Base stats, icons, descriptions
  - Boost types and amounts

### Data Management
- **Player Data Structure Updates**
  - `PlayerData.Potions` - Inventory potions (PotionId → Quantity)
  - `PlayerData.ActivePotions` - Currently active potions array
  
### Services
- **`src/client/services/PotionService.lua`**
  - Client-side potion management
  - UI updates and notifications
  - Timer management and countdown displays
  
- **`src/server/services/PotionService.lua`**
  - Server-side potion logic
  - Activation/deactivation
  - Boost calculations
  - Anti-cheat validation

### UI Components  
- **`src/client/components/PotionInventoryUI.lua`**
  - Display available potions
  - Activation interface
  - Quantity management
  
- **`src/client/components/ActivePotionsUI.lua`**
  - Show active potions with timers
  - Progress bars for remaining time
  - Quick overview display

### Remote Events
- **`ActivatePotion`** - Client → Server (PotionId)
- **`PotionExpired`** - Server → Client (PotionId)  
- **`PotionActivated`** - Server → Client (PotionData)

## 3. Initial Potion Definitions

### Diamond Boost Potion
```lua
{
    PotionId = "diamond_2x_10m",
    Name = "2x Diamond Potion",
    Description = "Doubles all diamond earnings for 10 minutes",
    Icon = "rbxassetid://104089702525726",
    BoostType = "Diamonds",
    BoostAmount = 2,
    Duration = 600, -- 10 minutes
    Rarity = "Common",
    StackLimit = 10
}
```

### Money Boost Potion
```lua
{
    PotionId = "money_2x_10m", 
    Name = "2x Money Potion",
    Description = "Doubles all money earnings for 10 minutes",
    Icon = "rbxassetid://80792880610063",
    BoostType = "Money",
    BoostAmount = 2,
    Duration = 600, -- 10 minutes
    Rarity = "Common", 
    StackLimit = 10
}
```

## 4. Implementation Flow

### Phase 1: Core Foundation
1. **Create PotionConfig.lua** with base potion definitions
2. **Update DataService** to handle potion inventory and active potions
3. **Create server PotionService** for activation logic
4. **Update boost calculation** in money/diamond earning systems

### Phase 2: Client Integration  
1. **Create client PotionService** for UI management
2. **Build PotionInventoryUI** for viewing/activating potions
3. **Build ActivePotionsUI** for tracking active boosts
4. **Add potion notifications** and sound effects

### Phase 3: User Experience
1. **Integrate with existing UIs** (add potion buttons to main interface)
2. **Add visual effects** for active potions (glowing borders, particle effects)
3. **Create potion acquisition** methods (rewards, chests, etc.)
4. **Polish animations** and transitions

## 5. Data Flow

### Potion Activation Process
1. **Player clicks potion** in inventory UI
2. **Client validates** player has potion and no conflicting active potion
3. **Client fires** `ActivatePotion` remote with PotionId
4. **Server validates** request and player data
5. **Server updates** player data (removes from inventory, adds to active)
6. **Server applies** boost multipliers to relevant systems
7. **Server notifies** client of successful activation
8. **Client updates** UI and starts countdown timer

### Potion Expiration Process
1. **Server timer** tracks potion expiration
2. **Server removes** expired potion from ActivePotions
3. **Server removes** boost multipliers
4. **Server notifies** client of expiration
5. **Client updates** UI and shows notification

## 6. Integration Points

### Existing Systems to Modify
- **Money earning calculations** - Apply money potion multipliers
- **Diamond earning calculations** - Apply diamond potion multipliers  
- **DataService** - Add potion data management
- **Main UI** - Add potion status indicators
- **Reward systems** - Add potions as possible rewards

### Future Expansion Opportunities
- **Pet Drop Rate potions** - Increase pet spawn chances
- **Rebirth Speed potions** - Faster rebirth progress
- **Luck potions** - Better chances for rare items
- **Potion crafting** - Combine smaller potions into bigger ones
- **Premium potions** - Robux-purchasable with stronger effects

## 7. Technical Considerations

### Performance
- **Efficient timer management** - Use single server heartbeat for all active potions
- **Minimal network traffic** - Only sync when potions activate/expire
- **UI optimization** - Update displays efficiently without constant re-renders

### Data Persistence
- **Save active potions** with timestamps to survive server restarts
- **Handle offline time** - Calculate remaining duration when player rejoins
- **Backup validation** - Server double-checks potion validity on load

### Anti-Cheat
- **Server-side validation** of all potion operations
- **Cooldown systems** to prevent spam activation
- **Audit logging** for suspicious potion usage patterns

## 8. File Structure
```
src/
├── shared/
│   └── config/
│       └── PotionConfig.lua
├── server/
│   └── services/
│       └── PotionService.lua
├── client/
│   ├── services/
│   │   └── PotionService.lua
│   └── components/
│       ├── PotionInventoryUI.lua
│       └── ActivePotionsUI.lua
└── ReplicatedStorage/
    └── remotes/
        ├── ActivatePotion.lua
        ├── PotionExpired.lua
        └── PotionActivated.lua
```

## 9. Success Metrics
- **Player engagement** - Track potion usage frequency
- **Retention impact** - Monitor if potions increase session length
- **Monetization potential** - Future premium potion sales
- **Performance impact** - Ensure no lag from potion system

This design provides a solid foundation that's extensible for future potion types while maintaining clean separation of concerns and good performance characteristics.