--[[
    ChronoRush - Projectile Manager (Client)
    Spawns projectiles based on level/wave configuration
    Works with LevelManager to control difficulty
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChronoRushClient = ReplicatedStorage:WaitForChild("ChronoRush"):WaitForChild("Client")

local Constants = require(ReplicatedStorage:WaitForChild("ChronoRush"):WaitForChild("Shared"):WaitForChild("Constants"))
local LevelManager = require(ChronoRushClient:WaitForChild("LevelManager"))

local ProjectileManager = {}
ProjectileManager.__index = ProjectileManager

-- Pattern type mapping
local PATTERN_MAP = {
    single = "SINGLE",
    burst = "BURST",
    aimed = "AIMED",
    wave = "WAVE"
}

function ProjectileManager.new()
    local self = setmetatable({}, ProjectileManager)
    
    self.Projectiles = {}
    self.IsActive = false
    self.LevelManager = nil
    
    -- Track current difficulty from level
    self.CurrentSpeed = Constants.PROJECTILE_SPEED
    
    return self
end

function ProjectileManager:Start()
    -- Create LevelManager
    self.LevelManager = LevelManager.new()
    self.LevelManager:Start()
    
    -- Set up callbacks
    self.LevelManager.OnLevelStart = function(level, config)
        self:OnLevelStart(level, config)
    end
    
    self.LevelManager.OnWaveStart = function(wave, total, config)
        self:OnWaveStart(wave, total, config)
    end
    
    self.LevelManager.OnWaveEnd = function(wave)
        self:OnWaveEnd(wave)
    end
    
    self.LevelManager.OnLevelComplete = function(level)
        self:OnLevelComplete(level)
    end
    
    self.LevelManager.OnGameComplete = function()
        self:OnGameComplete()
    end
    
    self.LevelManager.OnLevelFailed = function(level)
        self:OnLevelFailed(level)
    end
    
    -- Update loop
    self.Connection = RunService.Heartbeat:Connect(function(dt)
        self:Update(dt)
    end)
end

function ProjectileManager:StartGame()
    self.IsActive = true
    self.Projectiles = {}
    self.LevelManager:Reset()
    self.LevelManager:StartLevel()
end

function ProjectileManager:StopGame()
    self.IsActive = false
    self:ClearAllProjectiles()
end

function ProjectileManager:Update(dt)
    if not self.IsActive then return end
    if not self.LevelManager then return end
    
    -- Update level manager
    self.LevelManager:Update(dt)
    
    -- Check if we should spawn
    if self.LevelManager:ShouldSpawnProjectile() then
        self:SpawnProjectileFromPattern()
    end
    
    -- Cleanup
    self:CleanupProjectiles()
end

function ProjectileManager:OnLevelStart(level, config)
    self.CurrentSpeed = config.projectileSpeed
    print("ProjectileManager: Level " .. level .. " started, speed=" .. config.projectileSpeed)
end

function ProjectileManager:OnWaveStart(wave, total, config)
    print("ProjectileManager: Wave " .. wave .. " started")
end

function ProjectileManager:OnWaveEnd(wave)
    -- Clear projectiles during break
    self:ClearAllProjectiles()
    print("ProjectileManager: Wave " .. wave .. " ended, clearing projectiles")
end

function ProjectileManager:OnLevelComplete(level)
    -- Clear all projectiles
    self:ClearAllProjectiles()
end

function ProjectileManager:OnGameComplete()
    self:ClearAllProjectiles()
end

function ProjectileManager:OnLevelFailed(level)
    self:ClearAllProjectiles()
end

function ProjectileManager:SpawnProjectileFromPattern()
    if not self.LevelManager then return end
    
    local patternName = self.LevelManager:GetCurrentPattern()
    local patternType = PATTERN_MAP[patternName] or "SINGLE"
    
    local player = Players.LocalPlayer
    local character = player.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local playerPos = rootPart.Position
    
    print("Spawning: " .. patternType)
    
    if patternType == "BURST" then
        self:SpawnBurstPattern(playerPos)
    elseif patternType == "AIMED" then
        self:SpawnAimedPattern(playerPos)
    elseif patternType == "WAVE" then
        self:SpawnWavePattern(playerPos)
    else
        self:SpawnSingleProjectile(playerPos)
    end
end

function ProjectileManager:SpawnSingleProjectile(playerPos)
    local angle = math.random() * math.pi * 2
    local distance = 80 + math.random() * 40
    
    local spawnPos = playerPos + Vector3.new(
        math.cos(angle) * distance,
        math.random(-10, 10),
        math.sin(angle) * distance
    )
    
    local direction = (playerPos - spawnPos).Unit
    self:CreateProjectile(spawnPos, direction, self.CurrentSpeed, false)
end

function ProjectileManager:SpawnBurstPattern(playerPos)
    local angle = math.random() * math.pi * 2
    local distance = 80 + math.random() * 20
    
    local basePos = playerPos + Vector3.new(
        math.cos(angle) * distance,
        math.random(-5, 5),
        math.sin(angle) * distance
    )
    
    local baseDir = (playerPos - basePos).Unit
    local spreadAngle = math.rad(30)
    
    for i = -1, 1 do
        local angleOffset = i * (spreadAngle / 2)
        local rotatedDir = self:RotateVector(baseDir, angleOffset)
        local spawnPos = basePos + Vector3.new(0, 0, 0)
        
        self:CreateProjectile(spawnPos, rotatedDir, self.CurrentSpeed, true)
        task.wait(0.05)
    end
end

function ProjectileManager:SpawnAimedPattern(playerPos)
    local angle = math.random() * math.pi * 2
    local distance = 100 + math.random() * 30
    
    local spawnPos = playerPos + Vector3.new(
        math.cos(angle) * distance,
        math.random(-5, 5),
        math.sin(angle) * distance
    )
    
    local direction = (playerPos - spawnPos).Unit
    self:CreateProjectile(spawnPos, direction, self.CurrentSpeed * 1.3, true)
end

function ProjectileManager:SpawnWavePattern(playerPos)
    local waveDir = math.random() > 0.5 and 1 or -1
    local centerPos = playerPos + Vector3.new(0, 0, waveDir * 100)
    
    local projectileCount = 5 + math.random(0, 2)
    local spacing = 15
    
    for i = 1, projectileCount do
        local offset = (i - (projectileCount + 1) / 2) * spacing
        local spawnPos = centerPos + Vector3.new(offset, math.random(-5, 5), 0)
        local direction = Vector3.new(0, 0, -waveDir).Unit
        
        self:CreateProjectile(spawnPos, direction, self.CurrentSpeed * 0.8, false)
        task.wait(0.08)
    end
end

function ProjectileManager:RotateVector(vec, angle)
    local cos = math.cos(angle)
    local sin = math.sin(angle)
    return Vector3.new(
        vec.X * cos - vec.Z * sin,
        vec.Y,
        vec.X * sin + vec.Z * cos
    ).Unit
end

function ProjectileManager:CreateProjectile(position, direction, speed, isDangerous)
    local projectile = Instance.new("Part")
    projectile.Name = "Projectile"
    projectile.Size = Vector3.new(3, 3, 3)
    projectile.Shape = Enum.PartType.Ball
    projectile.Position = position
    projectile.Anchored = true
    projectile.CanCollide = false
    
    projectile.Material = Enum.Material.Neon
    
    if isDangerous then
        projectile.Color = Constants.COLOR_PROJECTILE_FAST
    else
        projectile.Color = Constants.COLOR_PROJECTILE_SLOW
    end
    
    local lookAt = position + direction
    projectile.CFrame = CFrame.new(position, lookAt)
    
    projectile.Parent = workspace
    
    -- Movement script
    local speedValue = speed
    local dirX, dirY, dirZ = direction.X, direction.Y, direction.Z
    
    local moveScript = Instance.new("Script")
    moveScript.Source = [[
        local RunService = game:GetService("RunService")
        local speed = ]] .. speedValue .. [[
        local dirX, dirY, dirZ = ]] .. dirX .. [[, ]] .. dirY .. [[, ]] .. dirZ .. [[
        local direction = Vector3.new(dirX, dirY, dirZ)
        local active = true
        local lifetime = 0
        
        local connection
        connection = RunService.Heartbeat:Connect(function(dt)
            if not active then return end
            lifetime = lifetime + dt
            
            if not script.Parent or not script.Parent.Parent then
                active = false
                return
            end
            
            script.Parent.Position = script.Parent.Position + direction * speed * dt
            
            if lifetime > 8 then
                active = false
                script.Parent:Destroy()
            end
            
            local player = game.Players.LocalPlayer
            local char = player and player.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    local dist = (script.Parent.Position - root.Position).Magnitude
                    if dist > 250 or lifetime > 8 then
                        active = false
                        script.Parent:Destroy()
                    end
                end
            end
        end)
        
        script.Parent.Destroying:Connect(function()
            active = false
            if connection then connection:Disconnect() end
        end)
    ]]
    moveScript.Disabled = false
    moveScript.Parent = projectile
    
    table.insert(self.Projectiles, projectile)
end

function ProjectileManager:CleanupProjectiles()
    local alive = {}
    for _, proj in ipairs(self.Projectiles) do
        if proj and proj.Parent then
            table.insert(alive, proj)
        end
    end
    self.Projectiles = alive
end

function ProjectileManager:ClearAllProjectiles()
    for _, proj in ipairs(self.Projectiles) do
        if proj and proj.Parent then
            proj:Destroy()
        end
    end
    self.Projectiles = {}
end

function ProjectileManager:Destroy()
    if self.Connection then
        self.Connection:Disconnect()
    end
    if self.LevelManager then
        self.LevelManager = nil
    end
    self:ClearAllProjectiles()
end

return ProjectileManager