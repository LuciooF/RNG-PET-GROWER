## Engineering Principles

- Never use weird fallbacks like "If database doesn't work lets fallback into client data". That masks the issue, if the database fails, that's a problem!

## Architecture Guidelines

### Modular Code Structure
Always follow this modular architecture pattern for maintainable code:

#### **Core Principles:**
1. **Single Responsibility** - Each module has one clear purpose
2. **Separation of Concerns** - UI, business logic, and data are separated
3. **Shared Utilities** - Eliminate code duplication through shared modules
4. **Error Handling** - All services must have comprehensive error handling
5. **Performance First** - Optimize update loops and avoid unnecessary calculations

#### **Directory Structure:**
```
src/
├── client/
│   ├── services/
│   │   ├── [MainService].lua          (Core orchestration)
│   │   ├── [BusinessLogic]Service.lua (Specific business logic)
│   │   └── controllers/
│   │       ├── [Domain]Controller.lua (Specialized controllers)
│   │       └── [Another]Factory.lua   (Creation/factory patterns)
│   ├── components/                    (React UI components only)
│   └── Main.client.lua
├── shared/
│   ├── utils/
│   │   ├── ScreenUtils.lua           (Responsive design utilities)
│   │   └── AnimationHelpers.lua      (Reusable animations)
│   ├── constants/
│   │   └── [Domain]Constants.lua     (Centralized constants)
│   └── config/
└── server/
    └── services/
```

#### **Require Path Standards:**
- **Shared utilities**: `ReplicatedStorage.utils.*`
- **Shared constants**: `ReplicatedStorage.constants.*`
- **Shared config**: `ReplicatedStorage.Shared.config.*`
- **Store/Redux**: `ReplicatedStorage.store.*`
- **Client services**: `script.Parent.Parent.services.*` (from components)
- **Service controllers**: `script.Parent.controllers.*` (from services)
- **Server modules**: Use relative paths `script.Parent.*`

#### **Service Architecture Pattern:**
```lua
-- Main Service (Orchestrator)
local MainService = {}
local controllerA = require(script.Parent.controllers.ControllerA)
local controllerB = require(script.Parent.controllers.ControllerB)

function MainService:Initialize()
    -- Error handling wrapper
    local success, error = pcall(function()
        controllerA:Initialize()
        controllerB:Initialize()
        
        -- Pass shared data references
        controllerA:setSharedData(sharedDataTable)
        controllerB:setSharedData(sharedDataTable)
    end)
    
    if not success then
        warn("MainService initialization failed:", error)
        return false
    end
end
```

#### **Component Standards:**
```lua
-- UI Components should ONLY handle display
local ScreenUtils = require(ReplicatedStorage.utils.ScreenUtils)
local AnimationHelpers = require(ReplicatedStorage.utils.AnimationHelpers)
local PetConstants = require(ReplicatedStorage.constants.PetConstants)
local BusinessService = require(script.Parent.Parent.services.BusinessService)

-- Use shared utilities instead of duplicating code
local responsiveSize = ScreenUtils.getProportionalSize(screenSize, 100)
local petEmoji = PetConstants.getPetEmoji(petName)

-- Delegate business logic to services
BusinessService.performAction(data)
```

#### **Performance Optimization Rules:**
1. **Throttle Update Loops** - Never run at full 60 FPS unless necessary
2. **Cache Frequently Accessed Data** - Store references to avoid repeated lookups
3. **Conditional Processing** - Only update what actually changed
4. **Batch Operations** - Group similar operations together
5. **Proper Cleanup** - Always disconnect connections and destroy unused objects

#### **Error Handling Standards:**
```lua
function Service:CriticalOperation(data)
    local success, result = pcall(function()
        -- Validate inputs
        if not data or not data.requiredField then
            return false, "Invalid input data"
        end
        
        -- Perform operation
        return true, processedData
    end)
    
    if not success then
        warn("Service:CriticalOperation failed:", result)
        return false, result
    end
    
    return success, result
end
```

#### **Redux/State Management:**
- **Client-Side Immediate Updates** - Update Redux state immediately for responsive UI
- **Async Server Sync** - Send to server in background without blocking UI
- **No Direct Store Access in UI** - Use service layers for state management

#### **Code Quality Checklist:**
- [ ] No code duplication (use shared utilities)
- [ ] Proper error handling with pcall
- [ ] Input validation for all public functions
- [ ] Performance optimized (no unnecessary loops)
- [ ] Clean separation of concerns
- [ ] Consistent require paths
- [ ] Comprehensive cleanup methods

#### **When to Create New Modules:**
- **>400 lines** - Consider splitting into logical modules
- **Duplicated code** - Extract into shared utilities
- **Mixed responsibilities** - Separate UI from business logic
- **Performance issues** - Extract heavy operations into controllers

### Recent Successful Refactoring Example:
**PetGrowthService.lua** (870 lines) was successfully split into:
- **PetGrowthService.lua** (393 lines) - Core orchestration
- **PetModelFactory.lua** (218 lines) - Model creation & scaling
- **PetAnimationController.lua** (156 lines) - Animations & visual effects
- **PetStatusGUIController.lua** (85 lines) - GUI management
- **PetAssignmentService.lua** (127 lines) - Business logic extraction

This pattern should be followed for all future large services.