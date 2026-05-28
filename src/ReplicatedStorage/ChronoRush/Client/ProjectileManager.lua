--[[
    ChronoRush - Projectile Manager (Runner Mode)
    Spawns projectiles from ahead of the player towards them
    Projectiles fly in the -Z direction (towards player)
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
    aimed = "AIMED"
}

function ProjectileManager.new()
    local self = setmetatable({}, ProjectileManager)
    
    self.Projectiles = {}
    self.IsActive = false
    self.LevelManager = nil
    
    -- Player position tracking
    self.PlayerZ = 0
    self.LevelLength = 100
    self.StartZ = 0
    self.FinishZ = 100
    
    return self
end

function ProjectileManager:SetLevelBounds(startZ, finishZ)
    self.StartZ = startZ
    self.FinishZ = finishZ
    self.LevelLength = finishZ - startZ
end

function ProjectileManager:Start()
    -- Create LevelManager
    self.LevelManager = LevelManager.new()
    self.LevelManager:Start()
    
    -- Set up callbacks
    self.LevelManager.OnProjectileSpawn = function(pattern, speed, playerZ, levelLength)
        self:OnProjectileSpawn(pattern, speed, playerZ, levelLength)
    end
    
    -- Update loop
    self.Connection = RunService.Heartbeat:Connect(function(dt)
        self:Update(dt)
    end)
end

function ProjectileManager:StartGame()
    self.IsActive = true
    self:ClearAllProjectiles()
    self.LevelManager:Reset()
    self.LevelManager:StartLevel()
end

function ProjectileManager:StopGame()
    self.IsActive = false
    self.LevelManager:StopLevel()
    self:ClearAllProjectiles()
end

function ProjectileManager:UpdatePlayerPosition(z)
    self.PlayerZ = z
    if self.LevelManager then
        self.LevelManager:UpdatePlayerPosition(z)
    end
end

function ProjectileManager:Update(dt)
    if not self.IsActive then return end
    
    -- Update level manager
    if self.LevelManager then
        self.LevelManager:Update(dt)
    end
    
    -- Cleanup
    self:CleanupProjectiles()
end

function ProjectileManager:OnProjectileSpawn(patternName, speed, playerZ, levelLength)
    local patternType = PATTERN_MAP[patternName] or "SINGLE"
    
    print("Spawning: " .. patternType)
    
    if patternType == "BURST" then
        self:SpawnBurstPattern(playerZ, levelLength, speed)
    elseif patternType == "AIMED" then
        self:SpawnAimedPattern(playerZ, levelLength, speed)
    else
        self:SpawnSingleProjectile(playerZ, levelLength, speed)
    end
end

function ProjectileManager:SpawnSingleProjectile(playerZ, levelLength, speed)
    -- Spawn projectile ahead of player (in +Z direction from player)
    local spawnDistance = 80 + math.random(0, 40)
    local spawnZ = playerZ + spawnDistance
    
    -- Random X offset for variety (within corridor)
    local offsetX = math.random(-25, 25)
    
    local spawnPos = Vector3.new(offsetX, 5, spawnZ)
    
    -- Fly towards player (in -Z direction)
    local direction = Vector3.new(0, 0, -1).Unit
    
    self:CreateProjectile(spawnPos, direction, speed, false)
end

function ProjectileManager:SpawnBurstPattern(playerZ, levelLength, speed)
    -- Spawn 3 projectiles in a spread
    local baseZ = playerZ + 100
    local offsetX = math.random(-20, 20)
    
    local spreadDistance = 15
    
    for i = -1, 1 do
        local spawnPos = Vector3.new(offsetX + (i * spreadDistance), 5, baseZ)
        local direction = Vector3.new(0, 0, -1).Unit
        
        self:CreateProjectile(spawnPos, direction, speed, true)
        task.wait(0.08)
    end
end

function ProjectileManager:SpawnAimedPattern(playerZ, levelLength, speed)
    -- Spawn projectile that aims at player
    local spawnDistance = 100 + math.random(0, 30)
    local spawnZ = playerZ + spawnDistance
    
    local offsetX = math.random(-25, 25)
    local spawnPos = Vector3.new(offsetX, 5, spawnZ)
    
    -- Aim directly at player
    local direction = Vector3.new(0, 0, -1).Unit
    
    self:CreateProjectile(spawnPos, direction, speed * 1.2, true)
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
        local spawnZ = script.Parent.Position.Z
        
        local connection
        connection = RunService.Heartbeat:Connect(function(dt)
            if not active then return end
            lifetime = lifetime + dt
            
            if not script.Parent or not script.Parent.Parent then
                active = false
                return
            end
            
            script.Parent.Position = script.Parent.Position + direction * speed * dt
            
            -- Remove if passed behind player (went too far)
            local player = game.Players.LocalPlayer
            local char = player and player.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    local dist = script.Parent.Position.Z - root.Position.Z
                    -- Remove if projectile passed player by 20 studs
                    if dist < -20 or lifetime > 6 then
                        active = false
                        script.Parent:Destroy()
                    end
                end
            end
            
            -- Safety timeout
            if lifetime > 8 then
                active = false
                script.Parent:Destroy()
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
    self:ClearAllProjectiles()
end

return ProjectileManager