--[[
    ChronoRush - Projectile Manager (Client)
    Spawns and manages projectiles in the arena
]]

local RunService = game:GetService("RunService")

local Constants = require(script.Parent.Parent.Shared.Constants)

local ProjectileManager = {}
ProjectileManager.__index = ProjectileManager

function ProjectileManager.new()
    local self = setmetatable({}, ProjectileManager)
    
    self.Projectiles = {}
    self.SpawnTimer = 0
    self.SpawnInterval = Constants.PROJECTILE_SPAWN_INTERVAL
    self.DifficultyTimer = 0
    self.IsActive = false
    
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
    self.SpawnInterval = Constants.PROJECTILE_SPAWN_INTERVAL
    self.Projectiles = {}
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
        self:SpawnProjectile()
        self.SpawnTimer = 0
    end
    
    -- Difficulty scaling
    self.DifficultyTimer = self.DifficultyTimer + dt
    if self.DifficultyTimer >= 10 then
        -- Increase difficulty every 10 seconds
        self.SpawnInterval = math.max(
            Constants.PROJECTILE_SPAWN_INTERVAL_MIN,
            self.SpawnInterval - 0.1
        )
        self.DifficultyTimer = 0
    end
    
    -- Update projectile positions
    self:UpdateProjectiles(dt)
end

function ProjectileManager:SpawnProjectile()
    -- Get player position
    local player = game.Players.LocalPlayer
    local character = player.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local playerPos = rootPart.Position
    
    -- Random spawn position around player
    local angle = math.random() * math.pi * 2
    local distance = 80 + math.random() * 40 -- 80-120 studs away
    
    local spawnPos = playerPos + Vector3.new(
        math.cos(angle) * distance,
        math.random(-10, 10), -- Slight height variation
        math.sin(angle) * distance
    )
    
    -- Create projectile part
    local projectile = Instance.new("Part")
    projectile.Name = "Projectile"
    projectile.Size = Vector3.new(3, 3, 3)
    projectile.Shape = Enum.PartType.Ball
    projectile.Position = spawnPos
    projectile.Anchored = true
    projectile.CanCollide = false
    
    -- Neon material for glow
    projectile.Material = Enum.Material.Neon
    
    -- Color based on speed
    local speed = Constants.PROJECTILE_SPEED
    if math.random() > 0.7 then
        speed = speed * 1.3
        projectile.Color = Constants.COLOR_PROJECTILE_FAST
    else
        projectile.Color = Constants.COLOR_PROJECTILE_SLOW
    end
    
    -- Point towards player
    local direction = (playerPos - spawnPos).Unit
    projectile.CFrame = CFrame.new(spawnPos, spawnPos + direction)
    
    projectile.Parent = workspace
    
    -- Add to tracking
    table.insert(self.Projectiles, projectile)
    
    -- Add movement script
    local moveScript = Instance.new("Script")
    moveScript.Source = [[
        local RunService = game:GetService("RunService")
        local speed = ]] .. speed .. [[
        local direction = ]] .. tostring(direction) .. [[
        
        local connection
        connection = RunService.Heartbeat:Connect(function(dt)
            script.Parent.Position = script.Parent.Position + direction * speed * dt
            
            -- Remove if too far
            local player = game.Players.LocalPlayer
            local char = player and player.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    local dist = (script.Parent.Position - root.Position).Magnitude
                    if dist > 200 then
                        script.Parent:Destroy()
                    end
                end
            end
        end)
        
        script.Parent.Destroying:Connect(function()
            connection:Disconnect()
        end)
    ]]
    moveScript.Disabled = false
    moveScript.Parent = projectile
end

function ProjectileManager:UpdateProjectiles(dt)
    -- Clean up destroyed projectiles
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