# Chrono Rush - Development Plan

## Project Info
- **Location:** `D:\Game_Development\Chrono-Rush`
- **GitHub:** https://github.com/harry-29105/chrono-rush
- **Game Type:** Roblox Dodge/Runner Game

---

## PART 1: WHAT IS BUILT (WORKING)

### 1.1 Movement System ✅

**File:** `src/ReplicatedStorage/ChronoRush/Client/Movement.lua`

**How it works:**
- Custom movement using `BodyVelocity` on HumanoidRootPart
- `BodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)` (horizontal only)
- WASD input converted to camera-relative direction
- `CameraController` module calculates forward/right vectors from camera CFrame
- Smooth acceleration/deceleration via Lerp
- Character rotates to face movement direction using `BodyGyro`

**Key Constants (from Constants.lua):**
```lua
MOVE_SPEED = 20
ACCELERATION = 100
DECELERATION = 80
AIR_CONTROL = 0.75
```

### 1.2 Camera Controller ✅

**File:** `src/ReplicatedStorage/ChronoRush/Client/CameraController.lua`

**How it works:**
- Tracks camera CFrame to calculate movement directions
- `ConvertToCameraRelative(Vector2 input)` - converts WASD to 3D direction relative to camera
- **Shift key** toggles `MouseBehavior.LockCenter` (cursor locks to center)
- **Scroll wheel** adjusts `CameraMinZoomDistance` / `CameraMaxZoomDistance`
- Zoom interpolates smoothly using `RenderStepped` connection

**Key Settings:**
```lua
MinZoom = 0.5
MaxZoom = 80
ScrollSensitivity = 0.5
```

### 1.3 Jump System ✅

**File:** `src/ReplicatedStorage/ChronoRush/Client/Jump.lua`

**How it works:**
- Tracks jump count with `JumpsRemaining` variable
- On Space press, if `JumpsRemaining > 0`, applies vertical velocity
- Resets on landing (HumanoidState changed to Running)
- `MAX_JUMPS = 2` (ground jump + air jump)

**Key Constants:**
```lua
JUMP_FORCE = 50
DOUBLE_JUMP_FORCE = 60
MAX_JUMPS = 2
```

### 1.4 Dash System ✅

**File:** `src/ReplicatedStorage/ChronoRush/Client/Dash.lua`

**How it works:**
- **Q key** triggers dash
- `GetCurrentInputDirection()` checks which WASD keys are held
- Converts to camera-relative direction
- Sets `Character:SetAttribute("Dashing", true)` + `DashDirection`
- Movement module reads attributes and applies high-speed velocity
- `BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)` during dash

**Key Constants:**
```lua
DASH_SPEED = 120
DASH_DURATION = 0.15
DASH_COOLDOWN = 0.5
```

### 1.5 Entry Point ✅

**File:** `src/StarterPlayer/StarterPlayerScripts/GameStarter.client.lua`

**How it works:**
- Runs automatically when game starts (LocalScript in StarterPlayerScripts)
- Waits for `ReplicatedStorage:ChronoRush` folder
- Requires `GameManager` module
- Creates `GameManager.new()` and calls `:Start()`

---

## PART 2: WHAT EXISTS BUT IS BROKEN

### 2.1 Token System ⚠️

**File:** `src/ReplicatedStorage/ChronoRush/Client/TokenManager.lua`

**What it should do:**
- Track tokens (currency)
- `AddTokens(amount)` - adds tokens and fires callback
- `SpendTokens(amount)` - deducts tokens if sufficient
- Checkpoint gives 10 tokens, level complete gives 25

**Why it's broken:**
- Code exists but is never called
- `GameManager` doesn't properly integrate it into game flow

### 2.2 Equipment Shop ⚠️

**File:** `src/ReplicatedStorage/ChronoRush/Client/EquipmentShop.lua`

**What it should do:**
- Shop UI opens when **P key** pressed
- 5 items available: Basic Treadmill (100), Advanced Treadmill (250), Speed Pad (500), Rocket Boosters (1000), Teleport Pads (2000)
- Each item gives speed boost when "activated"

**Why it's broken:**
- `GameManager:ToggleShop()` creates UI but Shop UI creation code has issues
- Equipment effects not actually applied to Movement

### 2.3 Obstacle Course Map ❌

**File:** `src/ServerScriptService/MapBuilder.server.lua`

**What it should create:**
1. **Lava Floor** - Red neon part that kills on touch
2. **Green Platforms** - 6 jumping platforms at Z positions: 15, 30, 45, 60, 75, 90
3. **Yellow Arrows** - Guide path at Z: 10, 30, 50, 70
4. **Cyan Checkpoint** - At Z: 105 (awards tokens)
5. **Gold Finish Line** - At Z: 125 (completes level)
6. **Gray Walls** - Side boundaries at X: -20, +20
7. **Dark Ceiling** - At Y: 15

**Why it's broken:**
- Server script exists but parts don't appear in game
- Script may not be running or folder structure is wrong

### 2.4 Game Flow ❌

**File:** `src/ReplicatedStorage/ChronoRush/Client/GameManager.lua`

**What it should do:**
- Initialize all modules (Movement, Jump, Dash, Camera, UI, Tokens, Shop, ObstacleCourse)
- Check player Z position against checkpoint/finish positions
- Award tokens on checkpoint reached
- Show UI messages
- Trigger game over when player falls

**Why it's broken:**
- Game loop checks (`CheckObstacles` function) exist but may not be running
- `ObstacleCourse` client module isn't being used properly
- Server map builder and client game manager aren't connected

---

## PART 3: PROJECT STRUCTURE

```
chrono-rush/
├── default.project.json          # Rojo config
├── AGENTS.md                     # Project memory
├── src/
│   ├── ReplicatedStorage/
│   │   └── ChronoRush/
│   │       ├── Client/
│   │       │   ├── Movement.lua        ✅ WORKING
│   │       │   ├── Jump.lua            ✅ WORKING
│   │       │   ├── Dash.lua            ✅ WORKING
│   │       │   ├── CameraController.lua ✅ WORKING
│   │       │   ├── GameManager.lua     ⚠️ NEEDS FIX
│   │       │   ├── TokenManager.lua    ⚠️ EXISTS, NOT TRIGGERED
│   │       │   ├── EquipmentShop.lua    ⚠️ EXISTS, NOT TRIGGERED
│   │       │   ├── ObstacleCourse.lua  ❌ EXISTS, NOT USED
│   │       │   └── UIManager.lua       ⚠️ NEEDS FIX
│   │       └── Shared/
│   │           └── Constants.lua       ✅ WORKING
│   ├── ServerScriptService/
│   │   └── MapBuilder.server.lua       ❌ NOT CREATING PARTS
│   └── StarterPlayer/
│       └── StarterPlayerScripts/
│           └── GameStarter.client.lua  ✅ ENTRY POINT
└── out/
    └── test.rbxlx               # Built game file
```

---

## PART 4: WHAT NEEDS TO BE FIXED

### Issue 1: Map Builder Not Creating Parts

**Problem:** `MapBuilder.server.lua` should create physical parts when game starts, but nothing appears.

**Possible causes:**
1. Server script not running
2. Folder path in `default.project.json` wrong
3. Script error preventing execution

**Fix needed:**
- Verify `MapBuilder.server.lua` is in `ServerScriptService` in the built game
- Add print statements to debug execution
- Check for script errors in Output panel

### Issue 2: Game Manager Not Triggering Systems

**Problem:** Token system and equipment shop code exists but never executes.

**Fix needed:**
- `GameManager:StartGame()` should initialize token/shop systems
- Add debug prints to verify functions are called
- Ensure `CheckObstacles(dt)` loop is running

### Issue 3: Checkpoint/Finish Detection Not Working

**Problem:** Even if map existed, game wouldn't detect player reaching checkpoint/finish.

**Fix needed:**
- `GameManager:CheckObstacles()` needs to track player Z position
- Fire callbacks when Z > CheckpointZ or Z > FinishZ

### Issue 4: Lava Floor Not Killing Player

**Problem:** Lava floor part exists but doesn't kill on touch.

**Fix needed:**
- Death script on lava part must correctly identify player
- `script.Parent.Touched:Connect()` should check for `HumanoidRootPart` or `Hitbox`
- Verify kill script is enabled and not disabled

---

## PART 5: RECOMMENDED FIX PRIORITY

### Priority 1: Verify Server Script Runs
1. Open `test.rbxlx` in Roblox Studio
2. Check Output panel for "Building Map" message
3. If no message, server script isn't running

### Priority 2: Manually Test Map Creation
1. Create a simple script that creates one part
2. Verify parts can be created at all
3. Then scale up to full map

### Priority 3: Fix Game Manager Integration
1. Add print statements to every function
2. Verify GameManager initializes all modules
3. Test that CheckObstacles loop runs

### Priority 4: Connect Token/Shop Systems
1. Test that pressing P opens shop UI
2. Debug why shop UI creation fails
3. Connect equipment purchase to movement speed

---

## PART 6: KEY FILES TO REVIEW

For OpenClaw to help fix this:

1. **Read first:** `AGENTS.md` (project overview)
2. **Working code reference:** `Movement.lua`, `CameraController.lua`, `Jump.lua`, `Dash.lua`
3. **Needs fixing:** `GameManager.lua`, `MapBuilder.server.lua`
4. **Project config:** `default.project.json`

---

## Quick Test Checklist

- [ ] Server script runs → Check Output for "Building Map"
- [ ] Parts appear in Workspace → Look for "ObstacleCourseMap" folder
- [ ] Green platforms visible → Should be at Z: 15, 30, 45, 60, 75, 90
- [ ] Red lava floor visible → Should be at Y: -0.5
- [ ] Player can jump between platforms
- [ ] Lava floor kills player
- [ ] Checkpoint at Z: 105 awards tokens
- [ ] Finish at Z: 125 completes level
- [ ] P key opens shop UI
- [ ] Tokens display in UI

---

## If All Else Fails

If server scripts won't work, recommend manually building in Roblox Studio:

1. Create Part for lava floor
2. Create Parts for platforms
3. Add kill script to lava
4. Position checkpoint and finish parts
5. Add walls and ceiling
6. Save and sync

This bypasses the server script execution issue entirely.