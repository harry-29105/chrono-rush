# Roblox Development Knowledge

## Rojo Project Structure

### Key Learnings (2026-05-28)

1. **Rojo File Naming Conventions:**
   - `.server.lua` → Script instance
   - `.client.lua` → LocalScript instance
   - `.lua` (other) → ModuleScript instance
   - `init.server.lua` / `init.client.lua` / `init.lua` → transforms parent folder into the respective script type

2. **Require Paths in Roblox:**
   - `require(script.Parent.SiblingName)` - works for sibling modules in same folder
   - BUT Rojo may compile modules with different names than expected
   - SAFE PATTERN: Use absolute require via ReplicatedStorage:
     ```lua
     local ChronoRush = ReplicatedStorage:WaitForChild("ChronoRush")
     local Movement = require(ChronoRush.Client:WaitForChild("Movement"))
     ```
   - This is more verbose but guaranteed to work regardless of how Rojo names instances

3. **Entry Point for Client Scripts:**
   - Scripts in `ReplicatedStorage` don't auto-run
   - Need a LocalScript in `StarterPlayerScripts` to be the entry point
   - The entry script should require modules from ReplicatedStorage

4. **Project JSON Structure:**
   ```json
   {
     "name": "project-name",
     "tree": {
       "$className": "DataModel",
       "ReplicatedStorage": {
         "$className": "ReplicatedStorage",
         "ModuleFolder": { "$path": "src/path" }
       },
       "StarterPlayer": {
         "StarterPlayerScripts": {
           "$className": "StarterPlayerScripts",
           "EntryScript": { "$path": "src/path/script.client.lua" }
         }
       }
     }
   }
   ```

5. **Common Errors:**
   - "Movement is not a valid member of ModuleScript" → requires are failing, use absolute paths
   - "Malformed number" → syntax error in the script itself
   - "$className and $path both set" → when path points to a file, don't set className

6. **Testing Workflow:**
   - Modify code → Rojo syncs to Studio → Press Play → Check Output window
   - Output window shows all print statements and errors

## Chrono Rush Game Project

- Location: `D:\Game_Development\Chrono-Rush`
- GitHub: `github.com/harry-29105/chrono-rush`
- Entry point: `src/StarterPlayer/StarterPlayerScripts/GameStarter.client.lua`
- All modules in: `src/ReplicatedStorage/ChronoRush/Client/`
- Constants in: `src/ReplicatedStorage/ChronoRush/Shared/Constants.lua`