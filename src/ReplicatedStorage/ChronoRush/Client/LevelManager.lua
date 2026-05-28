--[[
    ChronoRush - Level Manager (Runner Mode)
    Handles straight-path levels where player runs to the finish
    
    Game concept:
    - Player moves forward on a straight path
    - Projectiles fly from the front towards the player
    - Reach the finish line to complete level
    - Multiple levels with increasing length and difficulty
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage:WaitForChild("ChronoRush"):WaitForChild("Shared"):WaitForChild("Constants"))

local LevelManager = {}
LevelManager.__index = LevelManager

-- Level configuration
local LEVEL_CONFIG = {
    -- Level 1: Easy intro
    {
        name = "Level 1",
        length = 100,          -- distance to finish (studs)
        duration = 30,         -- max time to complete
        projectileInterval = 1.5,
        projectileSpeed = 50,
        patterns = {"single"},
        startDelay = 2
    },
    -- Level 2
    {
        name = "Level 2",
        length = 150,
        duration = 35,
        projectileInterval = 1.2,
        projectileSpeed = 55,
        patterns = {"single", "burst"},
        startDelay = 2
    },
    -- Level 3
    {
        name = "Level 3",
        length = 180,
        duration = 40,
        projectileInterval = 1.0,
        projectileSpeed = 60,
        patterns = {"single", "burst"},
        startDelay = 2
    },
    -- Level 4
    {
        name = "Level 4",
        length = 200,
        duration = 45,
        projectileInterval = 0.8,
        projectileSpeed = 65,
        patterns = {"single", "burst", "aimed"},
        startDelay = 2
    },
    -- Level 5
    {
        name = "Level 5",
        length = 250,
        duration = 50,
        projectileInterval = 0.7,
        projectileSpeed = 70,
        patterns = {"burst", "aimed"},
        startDelay = 2
    },
    -- Level 6
    {
        name = "Level 6",
        length = 280,
        duration = 55,
        projectileInterval = 0.6,
        projectileSpeed = 75,
        patterns = {"burst", "aimed"},
        startDelay = 2
    },
    -- Level 7
    {
        name = "Level 7",
        length = 300,
        duration = 55,
        projectileInterval = 0.5,
        projectileSpeed = 80,
        patterns = {"burst", "aimed"},
        startDelay = 2
    },
    -- Level 8
    {
        name = "Level 8",
        length = 320,
        duration = 60,
        projectileInterval = 0.4,
        projectileSpeed = 85,
        patterns = {"burst", "aimed"},
        startDelay = 2
    },
    -- Level 9
    {
        name = "Level 9",
        length = 350,
        duration = 60,
        projectileInterval = 0.35,
        projectileSpeed = 90,
        patterns = {"burst", "aimed"},
        startDelay = 2
    },
    -- Level 10: Final
    {
        name = "Level 10",
        length = 400,
        duration = 65,
        projectileInterval = 0.3,
        projectileSpeed = 95,
        patterns = {"burst", "aimed"},
        startDelay = 2
    }
}

function LevelManager.new()
    local self = setmetatable({}, LevelManager)
    
    self.CurrentLevel = 1
    self.IsRunning = false
    self.IsLevelComplete = false
    self.IsGameComplete = false
    self.IsFailed = false
    
    -- Player progress
    self.PlayerZ = 0
    self.LevelLength = 0
    self.TimeRemaining = 0
    
    -- Spawn timer
    self.SpawnTimer = 0
    
    -- Callbacks
    self.OnLevelStart = nil
    self.OnLevelComplete = nil
    self.OnLevelFailed = nil
    self.OnGameComplete = nil
    self.OnProjectileSpawn = nil
    self.OnProgress = nil
    
    return self
end

function LevelManager:Start()
    print("Level Manager started - Runner Mode")
end

function LevelManager:Reset()
    self.CurrentLevel = 1
    self.IsRunning = false
    self.IsLevelComplete = false
    self.IsGameComplete = false
    self.IsFailed = false
end

function LevelManager:GetCurrentLevelConfig()
    return LEVEL_CONFIG[self.CurrentLevel] or LEVEL_CONFIG[#LEVEL_CONFIG]
end

function LevelManager:StartLevel()
    if self.CurrentLevel > #LEVEL_CONFIG then
        self.IsGameComplete = true
        if self.OnGameComplete then
            self.OnGameComplete()
        end
        return false
    end
    
    local config = self:GetCurrentLevelConfig()
    
    self.IsRunning = true
    self.IsLevelComplete = false
    self.IsFailed = false
    self.PlayerZ = 0
    self.LevelLength = config.length
    self.TimeRemaining = config.duration
    self.SpawnTimer = 0
    
    print("Starting " .. config.name .. " - Distance: " .. config.length .. " studs")
    
    if self.OnLevelStart then
        self.OnLevelStart(self.CurrentLevel, config)
    end
    
    return true
end

function LevelManager:StopLevel()
    self.IsRunning = false
end

function LevelManager:Update(dt)
    if not self.IsRunning then return end
    if self.IsLevelComplete or self.IsFailed then return end
    
    local config = self:GetCurrentLevelConfig()
    
    -- Update timer
    self.TimeRemaining = self.TimeRemaining - dt
    
    -- Check timeout
    if self.TimeRemaining <= 0 then
        self:LevelFailed()
        return
    end
    
    -- Spawn projectiles
    self.SpawnTimer = self.SpawnTimer + dt
    if self.SpawnTimer >= config.projectileInterval then
        self.SpawnTimer = 0
        self:SpawnProjectile()
    end
    
    -- Check progress
    if self.OnProgress then
        self.OnProgress(self.PlayerZ, self.LevelLength)
    end
end

function LevelManager:UpdatePlayerPosition(z)
    self.PlayerZ = z
    
    -- Check if reached finish
    if self.PlayerZ >= self.LevelLength then
        self:LevelComplete()
    end
    
    -- Check progress
    if self.OnProgress then
        self.OnProgress(self.PlayerZ, self.LevelLength)
    end
end

function LevelManager:SpawnProjectile()
    if not self.IsRunning then return end
    
    local config = self:GetCurrentLevelConfig()
    local patterns = config.patterns
    local pattern = patterns[math.random(1, #patterns)]
    
    if self.OnProjectileSpawn then
        self.OnProjectileSpawn(pattern, config.projectileSpeed, self.PlayerZ, self.LevelLength)
    end
end

function LevelManager:LevelComplete()
    self.IsRunning = false
    self.IsLevelComplete = true
    
    print("Level " .. self.CurrentLevel .. " complete!")
    
    if self.OnLevelComplete then
        self.OnLevelComplete(self.CurrentLevel)
    end
end

function LevelManager:LevelFailed()
    self.IsRunning = false
    self.IsFailed = true
    
    print("Level " .. self.CurrentLevel .. " failed!")
    
    if self.OnLevelFailed then
        self.OnLevelFailed(self.CurrentLevel)
    end
end

function LevelManager:AdvanceToNextLevel()
    self.CurrentLevel = self.CurrentLevel + 1
    
    if self.CurrentLevel > #LEVEL_CONFIG then
        self.IsGameComplete = true
        if self.OnGameComplete then
            self.OnGameComplete()
        end
    else
        task.delay(2, function()
            self:StartLevel()
        end)
    end
end

function LevelManager:RetryLevel()
    task.delay(1, function()
        self:StartLevel()
    end)
end

function LevelManager:GetProgress()
    if self.LevelLength <= 0 then return 0 end
    return math.clamp(self.PlayerZ / self.LevelLength, 0, 1)
end

function LevelManager:GetTimeRemaining()
    return self.TimeRemaining
end

function LevelManager:IsLastLevel()
    return self.CurrentLevel >= #LEVEL_CONFIG
end

function LevelManager:GetTotalLevels()
    return #LEVEL_CONFIG
end

return LevelManager