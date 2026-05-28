# Chrono Rush - Project Memory

## Project Info
- **Location:** D:\Game_Development\Chrono-Rush
- **GitHub:** https://github.com/harry-29105/chrono-rush
- **Roblox Game:** Dodge/Runner style game

## Current Working Features

### ✅ Movement System (FULLY WORKING)
- **File:** `src\ReplicatedStorage\ChronoRush\Client\Movement.lua`
- **WASD** = Camera-relative movement (W moves towards camera facing)
- Character rotates to face movement direction when moving
- BodyGyro controls rotation (P=12000, D=800)
- BodyVelocity controls movement (MaxForce = math.huge, 0, math.huge)
- Smooth acceleration/deceleration

### ✅ Camera Controller (FULLY WORKING)
- **File:** `src\ReplicatedStorage\ChronoRush\Client\CameraController.lua`
- **Shift** = Toggle camera lock (LockCenter cursor mode)
- **Scroll wheel** = Zoom in/out (smooth, continuous)
- MinZoom = 0.5, MaxZoom = 80
- Camera-relative movement directions calculated from camera CFrame

### ✅ Jump System
- **File:** `src\ReplicatedStorage\ChronoRush\Client\Jump.lua`
- Double jump works (MAX_JUMPS = 2)
- JUMP_FORCE = 50, DOUBLE_JUMP_FORCE = 60

### ✅ Dash System
- **File:** `src\ReplicatedStorage\ChronoRush\Client\Dash.lua`
- **Q key** = Dash
- DASH_SPEED = 120, DASH_DURATION = 0.15, DASH_COOLDOWN = 0.5
- Dash uses WASD input direction (camera-relative)
- Cyan trail effect during dash

### ✅ Constants
- **File:** `src\ReplicatedStorage\ChronoRush\Shared\Constants.lua`
- MOVE_SPEED = 20
- ACCELERATION = 100
- DECELERATION = 80
- AIR_CONTROL = 0.75

## Code Structure

```
src/
├── ReplicatedStorage/ChronoRush/
│   ├── Client/
│   │   ├── Movement.lua (working)
│   │   ├── Jump.lua (working)
│   │   ├── Dash.lua (working)
│   │   ├── CameraController.lua (working)
│   │   ├── GameManager.lua (needs fixing)
│   │   ├── TokenManager.lua (code exists)
│   │   ├── EquipmentShop.lua (code exists)
│   │   ├── UIManager.lua (needs fixing)
│   │   └── ObstacleCourse.lua (code exists)
│   └── Shared/
│       └── Constants.lua
├── ServerScriptService/
│   └── MapBuilder.server.lua (not working)
└── StarterPlayer/StarterPlayerScripts/
    └── GameStarter.client.lua (entry point)
```

## Known Issues (Need Fixing)

### ❌ Token System
- **File:** `TokenManager.lua` - code exists
- Checkpoint gives 10 tokens, level complete gives 25
- NOT triggering because game flow is broken

### ❌ Equipment Shop
- **File:** `EquipmentShop.lua` - code exists
- Shop opens with **P key**
- 5 items: Basic Treadmill (100), Advanced Treadmill (250), Speed Pad (500), Rocket Boosters (1000), Teleport Pads (2000)
- NOT triggering because game flow is broken

### ❌ Obstacle Course Map
- **File:** `MapBuilder.server.lua` - server script exists
- Should create: green platforms, red lava floor, yellow arrows, cyan checkpoint, gold finish line, gray walls
- NOT creating physical parts in game world

## What Needs To Be Fixed

1. **Map Builder** - Server script not creating parts
2. **Game Flow** - Token system and shop not triggering
3. **Lava Floor** - Should kill player on touch (death script not working)
4. **Checkpoints** - Not triggering token rewards

## Entry Point
- `GameStarter.client.lua` in StarterPlayerScripts
- Requires GameManager from ReplicatedStorage
- GameManager initializes all modules

## Last Working State
- Movement, camera, shift lock, jump, dash all working
- Token and shop systems exist in code but not triggered
- Map not appearing (server script issue)