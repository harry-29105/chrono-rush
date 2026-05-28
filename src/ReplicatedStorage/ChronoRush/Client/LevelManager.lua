--[[
    ChronoRush - Level Manager
    Handles wave survival system with 10 levels
    
    Each level has:
    - 3 waves of projectiles
    - Break time between waves
    - Increasing difficulty (faster spawns, more patterns)
    
    Win: Survive all waves in a level
    Lose: Get hit by projectile
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage:WaitForChild("ChronoRush"):WaitForChild("Shared"):WaitForChild("Constants"))

local LevelManager = {}
LevelManager.__index = LevelManager

-- Level configuration
local LEVEL_CONFIG = {
    -- Level 1: Easy introduction
    {
        name = "Level 1",
        waveCount = 3,
        waveDuration = 8,       -- seconds of projectiles per wave
        waveBreak = 5,          -- seconds between waves
        spawnInterval = 3.0,    -- time between projectile spawns
        projectileSpeed = 40,    -- base projectile speed
        patterns = {"single"},  -- allowed patterns
        difficulty = 1
    },
    -- Level 2: Introduce bursts
    {
        name = "Level 2",
        waveCount = 3,
        waveDuration = 10,
        waveBreak = 4,
        spawnInterval = 2.5,
        projectileSpeed = 45,
        patterns = {"single", "burst"},
        difficulty = 2
    },
    -- Level 3: Introduce aimed shots
    {
        name = "Level 3",
        waveCount = 3,
        waveDuration = 12,
        waveBreak = 4,
        spawnInterval = 2.0,
        projectileSpeed = 50,
        patterns = {"single", "burst", "aimed"},
        difficulty = 3
    },
    -- Level 4: Introduce waves
    {
        name = "Level 4",
        waveCount = 3,
        waveDuration = 12,
        waveBreak = 3,
        spawnInterval = 1.8,
        projectileSpeed = 55,
        patterns = {"single", "burst", "aimed", "wave"},
        difficulty = 4
    },
    -- Level 5: Medium challenge
    {
        name = "Level 5",
        waveCount = 4,
        waveDuration = 15,
        waveBreak = 3,
        spawnInterval = 1.5,
        projectileSpeed = 60,
        patterns = {"single", "burst", "aimed", "wave"},
        difficulty = 5
    },
    -- Level 6: Getting harder
    {
        name = "Level 6",
        waveCount = 4,
        waveDuration = 15,
        waveBreak = 2.5,
        spawnInterval = 1.3,
        projectileSpeed = 65,
        patterns = {"burst", "aimed", "wave"},
        difficulty = 6
    },
    -- Level 7: High intensity
    {
        name = "Level 7",
        waveCount = 5,
        waveDuration = 18,
        waveBreak = 2,
        spawnInterval = 1.0,
        projectileSpeed = 70,
        patterns = {"burst", "aimed", "wave"},
        difficulty = 7
    },
    -- Level 8: Very hard
    {
        name = "Level 8",
        waveCount = 5,
        waveDuration = 18,
        waveBreak = 2,
        spawnInterval = 0.8,
        projectileSpeed = 75,
        patterns = {"burst", "aimed", "wave"},
        difficulty = 8
    },
    -- Level 9: Extreme
    {
        name = "Level 9",
        waveCount = 5,
        waveDuration = 20,
        waveBreak = 1.5,
        spawnInterval = 0.6,
        projectileSpeed = 80,
        patterns = {"burst", "aimed", "wave"},
        difficulty = 9
    },
    -- Level 10: Final boss
    {
        name = "Level 10",
        waveCount = 6,
        waveDuration = 25,
        waveBreak = 1,
        spawnInterval = 0.4,
        projectileSpeed = 90,
        patterns = {"burst", "aimed", "wave"},
        difficulty = 10
    }
}

function LevelManager.new()
    local self = setmetatable({}, LevelManager)
    
    self.CurrentLevel = 1
    self.CurrentWave = 0
    self.IsWaveActive = false
    self.IsLevelComplete = false
    self.IsGameComplete = false
    
    -- Timers
    self.WaveTimer = 0
    self.BreakTimer = 0
    self.SpawnTimer = 0
    
    -- Callbacks
    self.OnWaveStart = nil
    self.OnWaveEnd = nil
    self.OnLevelStart = nil
    self.OnLevelComplete = nil
    self.OnGameComplete = nil
    self.OnLevelFailed = nil
    
    return self
end

function LevelManager:Start()
    print("Level Manager started - Level 1")
end

function LevelManager:Reset()
    self.CurrentLevel = 1
    self.CurrentWave = 0
    self.IsWaveActive = false
    self.IsLevelComplete = false
    self.IsGameComplete = false
    self.WaveTimer = 0
    self.BreakTimer = 0
    self.SpawnTimer = 0
end

function LevelManager:StartLevel()
    if self.CurrentLevel > #LEVEL_CONFIG then
        -- All levels complete!
        self.IsGameComplete = true
        if self.OnGameComplete then
            self.OnGameComplete()
        end
        return
    end
    
    self.CurrentWave = 0
    self.IsLevelComplete = false
    
    local config = self:GetCurrentLevelConfig()
    print("Starting " .. config.name .. " - " .. config.waveCount .. " waves")
    
    if self.OnLevelStart then
        self.OnLevelStart(self.CurrentLevel, config)
    end
    
    -- Start first wave after brief countdown
    task.delay(2, function()
        self:StartNextWave()
    end)
end

function LevelManager:StartNextWave()
    local config = self:GetCurrentLevelConfig()
    
    self.CurrentWave = self.CurrentWave + 1
    
    if self.CurrentWave > config.waveCount then
        -- Level complete!
        self.IsLevelComplete = true
        print(config.name .. " complete!")
        
        if self.OnLevelComplete then
            self.OnLevelComplete(self.CurrentLevel)
        end
        
        return
    end
    
    -- Start wave
    self.IsWaveActive = true
    self.WaveTimer = config.waveDuration
    self.SpawnTimer = 0
    
    print("Wave " .. self.CurrentWave .. "/" .. config.waveCount .. " started!")
    
    if self.OnWaveStart then
        self.OnWaveStart(self.CurrentWave, config.waveCount, config)
    end
end

function LevelManager:EndWave()
    self.IsWaveActive = false
    self.BreakTimer = self:GetCurrentLevelConfig().waveBreak
    
    print("Wave " .. self.CurrentWave .. " ended - " .. self.BreakTimer .. "s break")
    
    if self.OnWaveEnd then
        self.OnWaveEnd(self.CurrentWave)
    end
    
    -- Schedule next wave
    task.delay(self.BreakTimer, function()
        self:StartNextWave()
    end)
end

function LevelManager:Update(dt)
    if self.IsGameComplete then return end
    if self.IsLevelComplete then return end
    
    if self.IsWaveActive then
        -- Update wave timer
        self.WaveTimer = self.WaveTimer - dt
        self.SpawnTimer = self.SpawnTimer + dt
        
        -- Check if wave should end
        if self.WaveTimer <= 0 then
            self:EndWave()
        end
    end
end

function LevelManager:ShouldSpawnProjectile()
    if not self.IsWaveActive then return false end
    
    local config = self:GetCurrentLevelConfig()
    
    if self.SpawnTimer >= config.spawnInterval then
        self.SpawnTimer = 0
        return true
    end
    
    return false
end

function LevelManager:GetCurrentLevelConfig()
    return LEVEL_CONFIG[self.CurrentLevel] or LEVEL_CONFIG[#LEVEL_CONFIG]
end

function LevelManager:GetCurrentPattern()
    local config = self:GetCurrentLevelConfig()
    local patterns = config.patterns
    
    -- Random pattern from allowed patterns
    local randomIndex = math.random(1, #patterns)
    return patterns[randomIndex]
end

function LevelManager:AdvanceToNextLevel()
    self.CurrentLevel = self.CurrentLevel + 1
    
    if self.CurrentLevel > #LEVEL_CONFIG then
        self.IsGameComplete = true
        if self.OnGameComplete then
            self.OnGameComplete()
        end
    else
        -- Reset for next level
        task.delay(3, function()
            self:StartLevel()
        end)
    end
end

function LevelManager:OnPlayerHit()
    -- Player failed this level
    print("Hit! Level failed")
    
    if self.OnLevelFailed then
        self.OnLevelFailed(self.CurrentLevel)
    end
end

function LevelManager:GetStatus()
    return {
        level = self.CurrentLevel,
        wave = self.CurrentWave,
        totalWaves = self:GetCurrentLevelConfig().waveCount,
        isWaveActive = self.IsWaveActive,
        isLevelComplete = self.IsLevelComplete,
        isGameComplete = self.IsGameComplete,
        waveTimeLeft = self.WaveTimer,
        breakTimeLeft = self.BreakTimer
    }
end

function LevelManager:IsLastLevel()
    return self.CurrentLevel >= #LEVEL_CONFIG
end

function LevelManager:GetTotalLevels()
    return #LEVEL_CONFIG
end

return LevelManager