# 🔧 Codebase Maintenance Prompt

**Use this exact prompt when you want me to perform routine codebase maintenance and modularization:**

---

## **CODEBASE MAINTENANCE REQUEST**

Please perform a comprehensive codebase maintenance review following the established architectural patterns in CLAUDE.md. Focus on:

### **Primary Tasks:**
1. **File Size Analysis**: Identify files >400 lines that violate modular architecture principles
2. **Modularization**: Extract business logic, UI components, and utilities following established patterns
3. **Code Duplication**: Find and eliminate duplicate code by creating/using shared utilities
4. **Architecture Compliance**: Ensure separation of concerns between UI, business logic, and data management

### **Specific Areas to Check:**
- **Large Files**: Scan for files >400 lines and prioritize >600 lines for immediate refactoring
- **Mixed Responsibilities**: Look for UI components doing business logic or services handling GUI management
- **Duplicate Patterns**: Search for repeated code patterns that can be extracted into utilities
- **Import Violations**: Find files not using established shared utilities (ScreenUtils, NumberFormatter, etc.)

### **Established Patterns to Follow:**
- **Services**: Extract controllers for business logic (following PetBoostController pattern)
- **UI Components**: Create reusable components in `/ui/` folders (following PetBoostButton pattern)
- **Utilities**: Use/enhance shared utilities in `ReplicatedStorage.utils.*`
- **Constants**: Centralize constants in `ReplicatedStorage.constants.*`

### **Success Metrics:**
- Reduce file sizes by 20-30% where possible
- Create 3-5 new reusable components/utilities per session
- Eliminate code duplication instances
- Update CLAUDE.md with findings and improvements

### **Output Requirements:**
1. **Todo List**: Use TodoWrite to track progress throughout the session
2. **Documentation**: Update CLAUDE.md with comprehensive refactoring results
3. **Summary**: Provide before/after line counts and architectural improvements made

**Continue the modularization effort from where we left off, always referring to CLAUDE.md for context and architectural guidelines.**

---

## **When to Use This Prompt:**
- Monthly maintenance cycles
- After major feature additions
- When you notice files growing beyond 400 lines
- Before important releases or milestones
- When code review reveals architectural debt

## **Expected Session Duration:**
- Full maintenance: 30-45 minutes
- Quick maintenance: 15-20 minutes
- Focus on 3-6 files per session for best results