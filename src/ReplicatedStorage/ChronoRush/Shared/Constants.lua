--[[
    ChronoRush - Constants Module
    Defines all game constants and configuration values
]]

local Constants = {}

-- Movement Settings
Constants.MOVE_SPEED = 20 -- Base walk speed
Constants.ACCELERATION = 80 -- How fast player reaches max speed
Constants.DECELERATION = 40 -- How fast player stops
Constants.AIR_CONTROL = 0.7 -- Control while airborne (0-1)

-- Jump Settings
Constants.JUMP_FORCE = 50 -- Jump height power
Constants.DOUBLE_JUMP_FORCE = 60 -- Double jump power (higher for Blox Fruits feel)
Constants.MAX_JUMPS = 2 -- Total jumps allowed (1 ground + 1 air)
Constants.GRAVITY = 50 -- Lower gravity for floaty feel
Constants.JUMP_BUFFER_TIME = 0.15 -- Input buffer for jumps

-- Dash Settings
Constants.DASH_SPEED = 120 -- Burst speed during dash (Blox Fruits style)
Constants.DASH_DURATION = 0.15 -- How long dash lasts
Constants.DASH_COOLDOWN = 0.5 -- Cooldown between dashes (fast for aggressive play)
Constants.DASH_COOLDOWN_PREMIUM = 1.0 -- With gamepass
Constants.DASH_CHARGES = 1 -- Charges (2 with gamepass)

-- Combo Settings
Constants.COMBO_DISPLAY_X = 0.5 -- Screen X position (0-1)
Constants.COMBO_DISPLAY_Y = 0.3 -- Screen Y position
Constants.HIT_INVINCIBILITY_DURATION = 0.5 -- Brief invincibility after hit

-- Projectile Settings
Constants.PROJECTILE_SPEED = 60 -- Base projectile speed
Constants.PROJECTILE_SPAWN_INTERVAL = 2.0 -- Time between spawns (seconds)
Constants.PROJECTILE_SPAWN_INTERVAL_MIN = 0.5 -- Fastest spawn rate

-- Colors
Constants.COLOR_PROJECTILE_FAST = Color3.fromRGB(255, 100, 50) -- Red/orange
Constants.COLOR_PROJECTILE_SLOW = Color3.fromRGB(50, 200, 255) -- Blue/cyan
Constants.COLOR_DASH_TRAIL = Color3.fromRGB(100, 255, 200) -- Cyan trail

return Constants