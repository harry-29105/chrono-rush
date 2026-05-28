# Chrono Rush

A fast-paced dodge game for Roblox inspired by Blox Fruits movement mechanics.

## 🎮 Game Concept

**Chrono Rush** is a skill-based dodge game where players:
- Move with fluid, Blox Fruits-inspired controls (WASD + smooth acceleration)
- Double jump and dash to avoid projectiles
- Build combos by dodging consecutively
- Compete on leaderboards for the highest combo

## 🕹️ Controls

| Key | Action |
|-----|--------|
| WASD | Move in all directions |
| Space | Jump (press again mid-air for double jump) |
| Shift | Dash in movement direction |
| ESC | Pause |

## 🚀 Quick Start

### Prerequisites
- Node.js (for Rojo build tool)
- Git & GitHub account
- Roblox Studio
- Visual Studio Code

### Setup
1. Clone this repository
2. Install Rojo: `npm install -g rojo`
3. Open Roblox Studio, go to Plugins → install "Rojo" by Rojo Reynarth
4. Open a terminal in this folder, run: `rojo serve`
5. In Roblox Studio, click "Connect" in the Rojo plugin
6. Your code syncs automatically!

## 📁 Project Structure

```
chrono-rush/
├── src/
│   ├── ReplicatedStorage/
│   │   └── ChronoRush/
│   │       ├── Client/          # Client-side scripts
│   │       │   ├── Init.client.lua
│   │       │   ├── GameManager.lua
│   │       │   ├── Movement.lua
│   │       │   ├── Jump.lua
│   │       │   ├── Dash.lua
│   │       │   ├── Combo.lua
│   │       │   └── ProjectileManager.lua
│   │       └── Shared/
│   │           └── Constants.lua
│   └── Workspace/
│       └── ChronoRush/          # Server-side & workspace objects
├── default.project.json         # Rojo configuration
└── README.md
```

## 🎯 Features

### Phase 1 (MVP)
- ✅ Smooth WASD movement with acceleration/deceleration
- ✅ Double jump (2 air jumps)
- ✅ Dash ability with cooldown
- ✅ Combo system with UI
- ✅ Projectile spawning
- ✅ Game over on hit

### Phase 2+
- Obstacle patterns (burst, aimed, wave)
- Difficulty scaling
- Cyberpunk neon aesthetic
- Gamepass monetization
- Time Fragments currency

## 💰 Monetization

| Gamepass | Effect |
|----------|--------|
| Dash Cooldown Reduction | Faster Shift cooldown |
| Combo Guardian | 1 miss allowed |
| Extra Life | One hit forgiven |
| Dash Master | 2 dash charges |
| Double Time Fragments | 2x currency |
| Custom Trails | Cosmetic effects |

## 🔧 Development

### Code Style
- Lua with clear module separation
- Each system (Movement, Jump, Dash, etc.) is a self-contained module
- Constants centralized in `Constants.lua`

### Automation
- GitHub for version control
- Rojo syncs code to Roblox Studio automatically
- No copy-pasting required!

## 📝 License

This project is for learning and development purposes.