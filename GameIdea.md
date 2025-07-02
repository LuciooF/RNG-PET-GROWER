# Pet Grower RNG - Game Design Document

## Core Concept
A pet incubator idle/incremental game where players manage rows of pet incubators, collect rare pets with different auras, and progress through rebirths to unlock more content.

## Pet Incubator System

### Incubator States
1. **Locked (Black)** - Requires 1+ more rebirth to unlock
2. **Available (Red)** - Player has enough rebirths but hasn't purchased yet
3. **Owned (Active)** - Player owns and can use the incubator

### Incubator Layout
- Arranged in rows, each row represents a different rarity tier
- Each row contains 2-3 incubators (depending on available pets for that rarity)
- Higher rarity rows unlock with more rebirths

### Rarity Tiers
- **Noob** (Starting tier)
- **Common**
- **Uncommon** 
- **Rare**
- **Epic**
- **Legendary**
- **Mythical**
- *(Additional tiers can be added as needed)*

## Pet System

### Pet Generation
- Each incubator generates random pets from its assigned rarity pool
- Pets grow in size over time within the incubator
- Growth speed affected by player's equipped pets and potions

### Aura System (Secondary Rarity)
- **Normal** - No special effects
- **Gold** - Golden outline
- **Platinum** - Silver/white outline  
- **Diamond** - Rainbow/prismatic outline + particles
- **Cosmic** - Animated space-themed outline + special particles
- *(Auras are independent of pet rarity - can have "Diamond Common" pets)*

### Pet Stats
- **Luck Boost** - Increases chance of getting higher aura pets
- **Production Boost** - Increases pet growth speed in incubators
- **Rarity Multiplier** - Higher rarity pets have better base stats

### Pet Management
- **Equipping** - Player can equip 2 pets simultaneously for their bonuses
- **Selling** - Convert pets to currency for progression
- **Merging** - Combine multiple same pets to create stronger variants
  - 3 Baby → 1 Teenager (1.5x stats)
  - 3 Teenager → 1 Adult (2x stats)
  - 3 Adult → 1 Elder (3x stats)

## Progression Systems

### Currency
- **Coins** - Primary currency from selling pets
- **Gems** - Premium currency (potentially from special achievements/purchases)

### Rebirth System
- **Triggers** - Reaching certain milestones or currency thresholds
- **Benefits** - Unlock new incubator rows, permanent bonuses, special pets
- **Cost** - Resets progress but provides permanent upgrades

### Temporary Boosts (Potions)
- **Production Boost** - Faster pet growth (2x, 3x, 5x for different durations)
- **Luck Boost** - Higher aura drop rates
- **Double Coins** - 2x selling price
- **Auto-Collect** - Automatically harvests grown pets

## User Interface

### Pet Inventory
- Grid view of all owned pets
- Filter by rarity, aura, or stats
- Equip/unequip interface
- Merge interface for combining pets

### Shop
- Temporary boost potions
- Permanent upgrades
- Special pet packages (if monetized)

### Main Game View
- Incubator rows with visual indicators
- Current equipped pets display
- Currency and stats display
- Progress indicators

## Additional Features to Consider

### Achievement System
- Collect X pets of Y rarity
- Reach certain rebirth milestones
- Merge pets X times
- Unlock all incubators in a row

### Collection Book
- Catalog of all discovered pets
- Completion percentages
- Special rewards for completing collections

### Statistics Tracking
- Total pets collected
- Highest aura pet found
- Total rebirths
- Time played

### Quality of Life Features
- Auto-sell pets below certain rarity
- Bulk merging
- Offline progression
- Cloud save

### Visual & Audio
- Particle effects for rare aura pets
- Sound effects for pet generation, merging, upgrades
- Smooth animations for pet growth
- Screen shake/flash for very rare drops

### Balancing Considerations
- Aura drop rates (Normal: 70%, Gold: 20%, Platinum: 8%, Diamond: 1.9%, Cosmic: 0.1%)
- Pet growth timers (balance between engagement and patience)
- Rebirth requirements scaling
- Currency inflation management

### Data Requirements
- Player progress (rebirths, unlocked incubators)
- Pet inventory with stats and auras
- Equipped pets
- Currency amounts
- Achievement progress
- Settings preferences