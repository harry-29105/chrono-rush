--[[
    ChronoRush - Obstacle Course Builder
    Creates visible lava floor obstacle course using Roblox Studio parts
    This runs on SERVER side to create the actual map
]]

local Workspace = game:GetService("Workspace")
local ChronoRush = Workspace:WaitForChild("ChronoRush", 10)

local ObstacleCourse = {}
ObstacleCourse.__index = ObstacleCourse

function ObstacleCourse.new()
    local self = setmetatable({}, ObstacleCourse)
    self.CourseFolder = nil
    return self
end

function ObstacleCourse:BuildLevel1()
    print("Building Level 1 obstacle course...")
    
    -- Clear existing course
    self:Clear()
    
    -- Create course folder
    self.CourseFolder = Instance.new("Folder")
    self.CourseFolder.Name = "ObstacleCourse"
    self.CourseFolder.Parent = ChronoRush
    
    -- 1. Create FLOOR (lava)
    local lavaFloor = Instance.new("Part")
    lavaFloor.Name = "LavaFloor"
    lavaFloor.Size = Vector3.new(40, 1, 120)  -- Long floor
    lavaFloor.Position = Vector3.new(0, -0.5, 60)
    lavaFloor.Anchored = true
    lavaFloor.CanCollide = true
    lavaFloor.Material = Enum.Material.Neon
    lavaFloor.Color = Color3.fromRGB(255, 50, 0)  -- Red lava
    lavaFloor.Parent = self.CourseFolder
    
    -- Add death script to lava
    local deathScript = Instance.new("Script")
    deathScript.Source = [[
        script.Parent.Touched:Connect(function(hit)
            local char = hit.Parent
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.Health = 0
            end
        end)
    ]]
    deathScript.Disabled = false
    deathScript.Parent = lavaFloor
    
    -- 2. Create PLATFORMS (jumping stones)
    local platformPositions = {
        {x = 0, y = 2, z = 15, w = 10, d = 10},   -- Platform 1
        {x = 5, y = 3, z = 30, w = 8, d = 8},     -- Platform 2
        {x = -5, y = 4, z = 45, w = 8, d = 8},    -- Platform 3
        {x = 0, y = 5, z = 60, w = 10, d = 10},   -- Platform 4
        {x = 3, y = 5, z = 75, w = 8, d = 8},     -- Platform 5
        {x = 0, y = 6, z = 90, w = 12, d = 12},   -- Platform 6 (checkpoint)
    }
    
    for i, p in ipairs(platformPositions) do
        local platform = Instance.new("Part")
        platform.Name = "Platform_" .. i
        platform.Size = Vector3.new(p.w, 1, p.d)
        platform.Position = Vector3.new(p.x, p.y, p.z)
        platform.Anchored = true
        platform.CanCollide = true
        platform.Material = Enum.Material.SmoothPlastic
        platform.Color = Color3.fromRGB(50, 200, 50)  -- Green platforms
        platform.Parent = self.CourseFolder
        
        -- Add glow
        local light = Instance.new("PointLight")
        light.Color = Color3.fromRGB(100, 255, 100)
        light.Brightness = 1
        light.Range = 12
        light.Parent = platform
    end
    
    -- 3. Create START LINE
    local startLine = Instance.new("Part")
    startLine.Name = "StartLine"
    startLine.Size = Vector3.new(30, 0.5, 5)
    startLine.Position = Vector3.new(0, 0.25, -2)
    startLine.Anchored = true
    startLine.CanCollide = true
    startLine.Material = Enum.Material.Neon
    startLine.Color = Color3.fromRGB(0, 255, 100)
    startLine.Parent = self.CourseFolder
    
    -- 4. Create CHECKPOINT (after last platform)
    local checkpoint = Instance.new("Part")
    checkpoint.Name = "Checkpoint"
    checkpoint.Size = Vector3.new(30, 5, 3)
    checkpoint.Position = Vector3.new(0, 3, 105)
    checkpoint.Anchored = true
    checkpoint.CanCollide = false
    checkpoint.Material = Enum.Material.Neon
    checkpoint.Color = Color3.fromRGB(0, 200, 255)
    checkpoint.Transparency = 0.5
    checkpoint.Parent = self.CourseFolder
    
    local checkpointLight = Instance.new("PointLight")
    checkpointLight.Color = Color3.fromRGB(0, 255, 255)
    checkpointLight.Brightness = 2
    checkpointLight.Range = 20
    checkpointLight.Parent = checkpoint
    
    -- 5. Create FINISH LINE (after checkpoint)
    local finishLine = Instance.new("Part")
    finishLine.Name = "FinishLine"
    finishLine.Size = Vector3.new(30, 3, 5)
    finishLine.Position = Vector3.new(0, 1.5, 125)
    finishLine.Anchored = true
    finishLine.CanCollide = false
    finishLine.Material = Enum.Material.Neon
    finishLine.Color = Color3.fromRGB(255, 215, 0)  -- Gold
    finishLine.Transparency = 0.5
    finishLine.Parent = self.CourseFolder
    
    local finishLight = Instance.new("PointLight")
    finishLight.Color = Color3.fromRGB(255, 215, 0)
    finishLight.Brightness = 2
    finishLight.Range = 25
    finishLight.Parent = finishLine
    
    -- 6. Create SIDE WALLS (so player can't go too far left/right)
    local wallPositions = {
        {x = -20, z = 60, sizeX = 1, sizeZ = 130},
        {x = 20, z = 60, sizeX = 1, sizeZ = 130},
    }
    
    for i, w in ipairs(wallPositions) do
        local wall = Instance.new("Part")
        wall.Name = "SideWall_" .. i
        wall.Size = Vector3.new(w.sizeX, 10, w.sizeZ)
        wall.Position = Vector3.new(w.x, 5, w.z)
        wall.Anchored = true
        wall.CanCollide = true
        wall.Material = Enum.Material.SmoothPlastic
        wall.Color = Color3.fromRGB(80, 80, 80)  -- Gray walls
        wall.Parent = self.CourseFolder
    end
    
    -- 7. Create ARROW GUIDES (pointing forward)
    for z = 10, 80, 20 do
        local arrow = Instance.new("Part")
        arrow.Name = "Arrow_" .. z
        arrow.Size = Vector3.new(4, 0.3, 4)
        arrow.Position = Vector3.new(0, 0.3, z)
        arrow.Anchored = true
        arrow.CanCollide = false
        arrow.Material = Enum.Material.Neon
        arrow.Color = Color3.fromRGB(255, 255, 100)
        arrow.Parent = self.CourseFolder
    end
    
    -- 8. Create CEILING (optional, to make it feel like a corridor)
    local ceiling = Instance.new("Part")
    ceiling.Name = "Ceiling"
    ceiling.Size = Vector3.new(40, 1, 130)
    ceiling.Position = Vector3.new(0, 15, 60)
    ceiling.Anchored = true
    ceiling.CanCollide = true
    ceiling.Material = Enum.Material.SmoothPlastic
    ceiling.Color = Color3.fromRGB(40, 40, 50)  -- Dark ceiling
    ceiling.Transparency = 0.3
    ceiling.Parent = self.CourseFolder
    
    print("Level 1 obstacle course created!")
    print("- Green platforms to jump across")
    print("- Red lava floor (death if touched)")
    print("- Follow yellow arrows to checkpoint")
    print("- Reach gold finish line to win!")
end

function ObstacleCourse:Clear()
    if self.CourseFolder then
        self.CourseFolder:Destroy()
        self.CourseFolder = nil
    end
    
    -- Also clear any existing by name
    local names = {"ObstacleCourse", "LavaFloor", "Checkpoint", "FinishLine", "StartLine"}
    for _, name in ipairs(names) do
        local existing = ChronoRush and ChronoRush:FindFirstChild(name)
        if existing then
            existing:Destroy()
        end
    end
end

function ObstacleCourse:TeleportPlayer(player)
    -- Teleport player to start
    local character = player.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(0, 3, 0)
            print("Player teleported to start!")
        end
    end
end

return ObstacleCourse