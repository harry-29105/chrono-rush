--[[
    ChronoRush - Projectile Manager (Client)
    Spawns and manages projectiles with multiple patterns
    Phase 2: Burst, Aimed, and Wave patterns
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage:WaitForChild("ChronoRush"):WaitForChild("Shared"):WaitForChild("Constants"))

local ProjectileManager = {}
ProjectileManager.__index = ProjectileManager

-- Pattern types
local PatternType = {
    SINGLE = "single",
    BURST = "burst",      -- 3 projectiles at once
    AIMED = "aimed",      -- targets player position
    WAVE = "wave"         -- line of projectiles across arena
}

function ProjectileManager.new()
    local self = setmetatable({}, ProjectileManager)
    
    self.Projectiles = {}
    self.SpawnTimer = 0
    self.SpawnInterval = Constants.PROJECTILE_SPAWN_INTERVAL
    self.DifficultyTimer = 0
    self.IsActive = false
    
    -- Difficulty settings
    self.DifficultyLevel = 1
    self.MaxProjectileSpeed = Constants.PROJECTILE_SPEED
    self.PatternWeights = {
        [PatternType.SINGLE] = 100, -- Most common
        [PatternType.BURST] = 50,
        [PatternType.AIMED] = 30,
        [PatternType.WAVE] = 20
    }
    
    -- Wave pattern state
    self.WaveCounter = 0
    
    return self
end

function ProjectileManager:Start()
    -- Update loop
    self.Connection = RunService.Heartbeat:Connect(function(dt)
        self:Update(dt)
    end)
end

function ProjectileManager:StartGame()
    self.IsActive = true
    self.SpawnTimer = 0
    self.DifficultyTimer = 0
    self.DifficultyLevel = 1
    self.Projectiles = {}
    self.WaveCounter = 0
    self.SpawnInterval = Constants.PROJECTILE_SPAWN_INTERVAL
end

function ProjectileManager:StopGame()
    self.IsActive = false
    
    -- Clear all projectiles
    for _, proj in ipairs(self.Projectiles) do
        if proj and proj.Parent then
            proj:Destroy()
        end
    end
    self.Projectiles = {}
end

function ProjectileManager:Update(dt)
    if not self.IsActive then return end
    
    -- Spawn timer
    self.SpawnTimer = self.SpawnTimer + dt
    if self.SpawnTimer >= self.SpawnInterval then
        self:SpawnProjectilePattern()
        self.SpawnTimer = 0
    end
    
    -- Difficulty scaling every 10 seconds
    self.DifficultyTimer = self.DifficultyTimer + dt
    if self.DifficultyTimer >= 10 then
        self:IncreaseDifficulty()
        self.DifficultyTimer = 0
    end
    
    -- Update projectile positions
    self:CleanupProjectiles()
end

function ProjectileManager:IncreaseDifficulty()
    self.DifficultyLevel = self.DifficultyLevel + 1
    
    -- Decrease spawn interval (more projectiles)
    self.SpawnInterval = math.max(
        Constants.PROJECTILE_SPAWN_INTERVAL_MIN,
        Constants.PROJECTILE_SPAWN_INTERVAL - (self.DifficultyLevel * 0.1)
    )
    
    -- Increase projectile speed slightly
    self.MaxProjectileSpeed = Constants.PROJECTILE_SPEED + (self.DifficultyLevel * 3)
    
    -- Adjust pattern weights to favor harder patterns
    self.PatternWeights[PatternType.SINGLE] = math.max(30, 100 - self.DifficultyLevel * 5)
    self.PatternWeights[PatternType.BURST] = math.max(20, 50 + self.DifficultyLevel * 2)
    self.PatternWeights[PatternType.AIMED] = math.max(20, 30 + self.DifficultyLevel * 3)
    self.PatternWeights[PatternType.WAVE] = math.max(10, 20 + self.DifficultyLevel * 2)
    
    print("Difficulty increased to level " .. self.DifficultyLevel .. "! Spawn interval: " .. string.format("%.2f", self.SpawnInterval))
end

function ProjectileManager:SelectPattern()
    -- Weighted random selection
    local totalWeight = 0
    for _, weight in pairs(self.PatternWeights) do
        totalWeight = totalWeight + weight
    end
    
    local randomValue = math.random() * totalWeight
    local cumulativeWeight = 0
    
    for patternType, weight in pairs(self.PatternWeights) do
        cumulativeWeight = cumulativeWeight + weight
        if randomValue <= cumulativeWeight then
            return patternType
        end
    end
    
    return PatternType.SINGLE -- Default
end

function ProjectileManager:SpawnProjectilePattern()
    local player = Players.LocalPlayer
    local character = player.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local playerPos = rootPart.Position
    local patternType = self:SelectPattern()
    
    print("Spawning pattern: " .. patternType)
    
    if patternType == PatternType.BURST then
        self:SpawnBurstPattern(playerPos)
    elseif patternType == PatternType.AIMED then
        self:SpawnAimedPattern(playerPos)
    elseif patternType == PatternType.WAVE then
        self:SpawnWavePattern(playerPos)
    else
        self:SpawnSingleProjectile(playerPos)
    end
end

function ProjectileManager:SpawnSingleProjectile(playerPos)
    -- Random spawn position around player
    local angle = math.random() * math.pi * 2
    local distance = 80 + math.random() * 40
    
    local spawnPos = playerPos + Vector3.new(
        math.cos(angle) * distance,
        math.random(-10, 10),
        math.sin(angle) * distance
    )
    
    local direction = (playerPos - spawnPos).Unit
    self:CreateProjectile(spawnPos, direction, Constants.PROJECTILE_SPEED, false)
end

function ProjectileManager:SpawnBurstPattern(playerPos)
    -- Spawn 3 projectiles in a fan pattern
    local angle = math.random() * math.pi * 2
    local distance = 80 + math.random() * 20
    
    local basePos = playerPos + Vector3.new(
        math.cos(angle) * distance,
        math.random(-5, 5),
        math.sin(angle) * distance
    )
    
    -- Direction to player
    local baseDir = (playerPos - basePos).Unit
    
    -- Fan spread angle (30 degrees total)
    local spreadAngle = math.rad(30)
    
    for i = -1, 1 do
        local angleOffset = i * (spreadAngle / 2)
        local rotatedDir = self:RotateVector(baseDir, angleOffset)
        local spawnPos = basePos + Vector3.new(0, 0, 0)
        
        self:CreateProjectile(spawnPos, rotatedDir, self.MaxProjectileSpeed, true)
        task.wait(0.05) -- Slight delay between each
    end
end

function ProjectileManager:SpawnAimedPattern(playerPos)
    -- Spawn from random direction but aimed exactly at player
    local angle = math.random() * math.pi * 2
    local distance = 100 + math.random() * 30
    
    local spawnPos = playerPos + Vector3.new(
        math.cos(angle) * distance,
        math.random(-5, 5),
        math.sin(angle) * distance
    )
    
    -- Always aimed at player (faster projectile)
    local direction = (playerPos - spawnPos).Unit
    self:CreateProjectile(spawnPos, direction, self.MaxProjectileSpeed * 1.3, true)
end

function ProjectileManager:SpawnWavePattern(playerPos)
    -- Line of projectiles across the arena
    self.WaveCounter = self.WaveCounter + 1
    
    -- Wave direction (alternates)
    local waveDir = (self.WaveCounter % 2 == 0) and 1 or -1
    
    -- Spawn a line of projectiles perpendicular to wave direction
    local centerPos = playerPos + Vector3.new(0, 0, waveDir * 100)
    
    local projectileCount = 5 + math.min(self.DifficultyLevel, 3)
    local spacing = 15
    
    for i = 1, projectileCount do
        local offset = (i - (projectileCount + 1) / 2) * spacing
        local spawnPos = centerPos + Vector3.new(offset, math.random(-5, 5), 0)
        local direction = Vector3.new(0, 0, -waveDir).Unit
        
        self:CreateProjectile(spawnPos, direction, self.MaxProjectileSpeed * 0.8, false)
        task.wait(0.08)
    end
end

function ProjectileManager:RotateVector(vec, angle)
    -- Rotate vector around Y axis
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
    
    -- Neon material for glow
    projectile.Material = Enum.Material.Neon
    
    -- Color based on speed
    if isDangerous then
        projectile.Color = Constants.COLOR_PROJECTILE_FAST
    else
        projectile.Color = Constants.COLOR_PROJECTILE_SLOW
    end
    
    -- Point in direction of travel
    local lookAt = position + direction
    projectile.CFrame = CFrame.new(position, lookAt)
    
    projectile.Parent = workspace
    
    -- Add movement script
    local speedValue = speed
    local directionValue = direction
    
    local moveScript = Instance.new("Script")
    moveScript.Source = [[
        local RunService = game:GetService("RunService")
        local speed = ]] .. speedValue .. [[
        local direction = ]] .. tostring(direction) .. [[
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
            
            -- Remove if too old or too far
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
            if connection then
                connection:Disconnect()
            end
        end)
    ]]
    moveScript.Disabled = false
    moveScript.Parent = projectile
    
    -- Track projectile
    table.insert(self.Projectiles, projectile)
end

function ProjectileManager:CleanupProjectiles()
    -- Remove destroyed projectiles from tracking
    local alive = {}
    for _, proj in ipairs(self.Projectiles) do
        if proj and proj.Parent then
            table.insert(alive, proj)
        end
    end
    self.Projectiles = alive
end

function ProjectileManager:Destroy()
    if self.Connection then
        self.Connection:Disconnect()
    end
    self:StopGame()
end

return ProjectileManager