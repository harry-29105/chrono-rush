--[[
    ChronoRush - Obstacle Manager
    Handles different obstacle types for obstacle course
    
    Current Obstacles:
    - LAVA_FLOOR: Floor is lava, must jump across platforms
    - FALLING_BALLS: Balls fall from above
    - PROJECTILE_WAVE: Projectiles fly from front
    
    Each obstacle:
    - Has a start Z position
    - Has an end Z position (checkpoint)
    - Awards tokens when completed
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChronoRushClient = ReplicatedStorage:WaitForChild("ChronoRush"):WaitForChild("Client")

local Constants = require(ReplicatedStorage:WaitForChild("ChronoRush"):WaitForChild("Shared"):WaitForChild("Constants"))

local ObstacleManager = {}
ObstacleManager.__index = ObstacleManager

-- Obstacle types
local ObstacleType = {
    LAVA_FLOOR = "lava_floor",
    FALLING_BALLS = "falling_balls",
    PROJECTILE_WAVE = "projectile_wave"
}

function ObstacleManager.new()
    local self = setmetatable({}, ObstacleManager)
    
    self.Player = Players.LocalPlayer
    self.Character = nil
    self.RootPart = nil
    
    -- Current obstacle
    self.CurrentObstacle = nil
    self.IsObstacleActive = false
    self.ObstacleStartZ = 0
    self.ObstacleEndZ = 0
    
    -- Obstacle elements (parts in workspace)
    self.ObstacleParts = {}
    
    -- Callbacks
    self.OnObstacleStart = nil
    self.OnObstacleComplete = nil
    self.OnObstacleFailed = nil
    
    return self
end

function ObstacleManager:Start()
    print("Obstacle Manager started")
end

function ObstacleManager:SetCharacter(character)
    self.Character = character
    self.RootPart = character and character:FindFirstChild("HumanoidRootPart")
end

-- LAVA FLOOR OBSTACLE
function ObstacleManager:StartLavaFloor(startZ, endZ, platformPositions)
    self.CurrentObstacle = ObstacleType.LAVA_FLOOR
    self.IsObstacleActive = true
    self.ObstacleStartZ = startZ
    self.ObstacleEndZ = endZ
    
    print("LAVA FLOOR starting from Z=" .. startZ .. " to Z=" .. endZ)
    print("Platforms: " .. #platformPositions)
    
    -- Create lava floor
    self:CreateLavaFloor(startZ, endZ)
    
    -- Create platforms
    self:CreatePlatforms(platformPositions)
    
    -- Create checkpoint at end
    self:CreateCheckpoint(endZ)
    
    if self.OnObstacleStart then
        self.OnObstacleStart(ObstacleType.LAVA_FLOOR)
    end
    
    -- Start checking player position
    self:StartPositionCheck()
end

function ObstacleManager:CreateLavaFloor(startZ, endZ)
    -- Create lava floor (red/part that kills you)
    local lavaFloor = Instance.new("Part")
    lavaFloor.Name = "LavaFloor"
    lavaFloor.Size = Vector3.new(50, 1, endZ - startZ + 50)
    lavaFloor.Position = Vector3.new(0, -2, startZ + (endZ - startZ) / 2)
    lavaFloor.Anchored = true
    lavaFloor.CanCollide = true
    lavaFloor.Material = Enum.Material.Neon
    lavaFloor.Color = Color3.fromRGB(255, 50, 0)
    lavaFloor.Parent = workspace
    
    -- Add kill script
    local killScript = Instance.new("Script")
    killScript.Source = [[
        local Players = game:GetService("Players")
        
        script.Parent.Touched:Connect(function(otherPart)
            local character = otherPart.Parent
            if character and character:FindFirstChild("Humanoid") then
                local humanoid = character.Humanoid
                humanoid.Health = 0
            end
        end)
    ]]
    killScript.Disabled = false
    killScript.Parent = lavaFloor
    
    table.insert(self.ObstacleParts, lavaFloor)
end

function ObstacleManager:CreatePlatforms(positions)
    for i, pos in ipairs(positions) do
        local platform = Instance.new("Part")
        platform.Name = "LavaPlatform_" .. i
        platform.Size = Vector3.new(8, 1, 8)
        platform.Position = Vector3.new(pos.X, pos.Y, pos.Z)
        platform.Anchored = true
        platform.CanCollide = true
        platform.Material = Enum.Material.SmoothPlastic
        platform.Color = Color3.fromRGB(100, 100, 100)
        platform.Parent = workspace
        
        -- Add glow effect
        local pointLight = Instance.new("PointLight")
        pointLight.Color = Color3.fromRGB(100, 255, 100)
        pointLight.Brightness = 0.5
        pointLight.Range = 10
        pointLight.Parent = platform
        
        table.insert(self.ObstacleParts, platform)
    end
end

function ObstacleManager:CreateCheckpoint(zPosition)
    -- Create checkpoint zone
    local checkpoint = Instance.new("Part")
    checkpoint.Name = "Checkpoint"
    checkpoint.Size = Vector3.new(50, 10, 5)
    checkpoint.Position = Vector3.new(0, 5, zPosition)
    checkpoint.Anchored = true
    checkpoint.CanCollide = false
    checkpoint.Transparency = 0.5
    checkpoint.Material = Enum.Material.Neon
    checkpoint.Color = Color3.fromRGB(100, 255, 200)
    checkpoint.Parent = workspace
    
    -- Checkpoint trigger
    local trigger = Instance.new("Script")
    trigger.Source = [[
        local Players = game:GetService("Players")
        local triggered = false
        
        script.Parent.Touched:Connect(function(otherPart)
            if triggered then return end
            
            local character = otherPart.Parent
            if character and character:FindFirstChild("HumanoidRootPart") then
                local player = Players:GetPlayerFromCharacter(character)
                if player then
                    triggered = true
                    
                    -- Fire event to parent obstacle manager
                    local events = script.Parent:GetChildren()
                    for _, child in ipairs(events) do
                        if child:IsA("RemoteEvent") then
                            child:FireClient(player)
                        end
                    end
                end
            end
        end)
    ]]
    trigger.Disabled = false
    trigger.Parent = checkpoint
    
    table.insert(self.ObstacleParts, checkpoint)
end

function ObstacleManager:StartPositionCheck()
    -- Monitor player position to check if they reached checkpoint or fell
    self.PositionCheckConnection = RunService.Heartbeat:Connect(function(dt)
        if not self.IsObstacleActive then return end
        if not self.RootPart or not self.RootPart.Parent then return end
        
        local playerZ = self.RootPart.Position.Z
        local playerY = self.RootPart.Position.Y
        
        -- Check if player reached checkpoint
        if playerZ >= self.ObstacleEndZ then
            self:CompleteObstacle()
            return
        end
        
        -- Check if player fell (below lava floor level)
        if playerY < -5 then
            self:FailObstacle()
            return
        end
    end)
end

function ObstacleManager:CompleteObstacle()
    self.IsObstacleActive = false
    
    if self.PositionCheckConnection then
        self.PositionCheckConnection:Disconnect()
    end
    
    print("Obstacle complete!")
    
    -- Clear obstacle parts
    self:ClearObstacleParts()
    
    if self.OnObstacleComplete then
        self.OnObstacleComplete(self.CurrentObstacle)
    end
end

function ObstacleManager:FailObstacle()
    self.IsObstacleActive = false
    
    if self.PositionCheckConnection then
        self.PositionCheckConnection:Disconnect()
    end
    
    print("Obstacle failed!")
    
    -- Clear obstacle parts
    self:ClearObstacleParts()
    
    if self.OnObstacleFailed then
        self.OnObstacleFailed(self.CurrentObstacle)
    end
end

function ObstacleManager:ClearObstacleParts()
    for _, part in ipairs(self.ObstacleParts) do
        if part and part.Parent then
            part:Destroy()
        end
    end
    self.ObstacleParts = {}
end

function ObstacleManager:StopObstacle()
    self.IsObstacleActive = false
    self.CurrentObstacle = nil
    
    if self.PositionCheckConnection then
        self.PositionCheckConnection:Disconnect()
    end
    
    self:ClearObstacleParts()
end

function ObstacleManager:Destroy()
    self:StopObstacle()
end

return ObstacleManager