--[[
    ChronoRush - Map Initializer
    Server script that creates the obstacle course map
    Placed in ServerScriptService so it runs on server side
]]

local Workspace = game:GetService("Workspace")

print("=== Building Map ===")

-- Create folder to hold map parts
local mapFolder = Instance.new("Folder")
mapFolder.Name = "ObstacleCourseMap"
mapFolder.Parent = Workspace

-- 1. LAVA FLOOR (red, kills)
local lavaFloor = Instance.new("Part")
lavaFloor.Name = "LavaFloor"
lavaFloor.Size = Vector3.new(40, 1, 120)
lavaFloor.Position = Vector3.new(0, -0.5, 60)
lavaFloor.Anchored = true
lavaFloor.CanCollide = true
lavaFloor.Material = Enum.Material.Neon
lavaFloor.Color = Color3.fromRGB(255, 50, 0)
lavaFloor.Parent = mapFolder

-- Kill script on lava
local killScript = Instance.new("Script")
killScript.Source = [[
    script.Parent.Touched:Connect(function(hit)
        if hit.Name == "HumanoidRootPart" or hit.Name == "Hitbox" then
            local char = hit.Parent
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.Health = 0
            end
        end
    end)
]]
killScript.Disabled = false
killScript.Parent = lavaFloor

-- 2. PLATFORMS (green)
local platforms = {
    {x = 0, y = 2, z = 15, w = 10, d = 10},
    {x = 5, y = 3, z = 30, w = 8, d = 8},
    {x = -5, y = 4, z = 45, w = 8, d = 8},
    {x = 0, y = 5, z = 60, w = 10, d = 10},
    {x = 3, y = 5, z = 75, w = 8, d = 8},
    {x = 0, y = 6, z = 90, w = 12, d = 12},
}

for i, p in ipairs(platforms) do
    local platform = Instance.new("Part")
    platform.Name = "Platform_" .. i
    platform.Size = Vector3.new(p.w, 1, p.d)
    platform.Position = Vector3.new(p.x, p.y, p.z)
    platform.Anchored = true
    platform.Material = Enum.Material.SmoothPlastic
    platform.Color = Color3.fromRGB(50, 200, 50)
    platform.Parent = mapFolder
    
    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(100, 255, 100)
    light.Brightness = 1
    light.Range = 12
    light.Parent = platform
end

-- 3. START LINE
local startLine = Instance.new("Part")
startLine.Name = "StartLine"
startLine.Size = Vector3.new(30, 0.5, 5)
startLine.Position = Vector3.new(0, 0.25, -2)
startLine.Anchored = true
startLine.Material = Enum.Material.Neon
startLine.Color = Color3.fromRGB(0, 255, 100)
startLine.Parent = mapFolder

-- 4. CHECKPOINT
local checkpoint = Instance.new("Part")
checkpoint.Name = "Checkpoint"
checkpoint.Size = Vector3.new(30, 5, 3)
checkpoint.Position = Vector3.new(0, 3, 105)
checkpoint.Anchored = true
checkpoint.Material = Enum.Material.Neon
checkpoint.Color = Color3.fromRGB(0, 200, 255)
checkpoint.Transparency = 0.5
checkpoint.Parent = mapFolder

local cpLight = Instance.new("PointLight")
cpLight.Color = Color3.fromRGB(0, 255, 255)
cpLight.Brightness = 2
cpLight.Range = 20
cpLight.Parent = checkpoint

-- 5. FINISH LINE
local finishLine = Instance.new("Part")
finishLine.Name = "FinishLine"
finishLine.Size = Vector3.new(30, 3, 5)
finishLine.Position = Vector3.new(0, 1.5, 125)
finishLine.Anchored = true
finishLine.Material = Enum.Material.Neon
finishLine.Color = Color3.fromRGB(255, 215, 0)
finishLine.Transparency = 0.5
finishLine.Parent = mapFolder

local finLight = Instance.new("PointLight")
finLight.Color = Color3.fromRGB(255, 215, 0)
finLight.Brightness = 2
finLight.Range = 25
finLight.Parent = finishLine

-- 6. SIDE WALLS
local leftWall = Instance.new("Part")
leftWall.Name = "LeftWall"
leftWall.Size = Vector3.new(1, 15, 130)
leftWall.Position = Vector3.new(-20, 7, 60)
leftWall.Anchored = true
leftWall.Material = Enum.Material.SmoothPlastic
leftWall.Color = Color3.fromRGB(80, 80, 80)
leftWall.Parent = mapFolder

local rightWall = Instance.new("Part")
rightWall.Name = "RightWall"
rightWall.Size = Vector3.new(1, 15, 130)
rightWall.Position = Vector3.new(20, 7, 60)
rightWall.Anchored = true
rightWall.Material = Enum.Material.SmoothPlastic
rightWall.Color = Color3.fromRGB(80, 80, 80)
rightWall.Parent = mapFolder

-- 7. ARROWS
for z = 10, 80, 20 do
    local arrow = Instance.new("Part")
    arrow.Name = "Arrow_" .. z
    arrow.Size = Vector3.new(4, 0.3, 4)
    arrow.Position = Vector3.new(0, 0.3, z)
    arrow.Anchored = true
    arrow.Material = Enum.Material.Neon
    arrow.Color = Color3.fromRGB(255, 255, 100)
    arrow.Parent = mapFolder
end

-- 8. CEILING
local ceiling = Instance.new("Part")
ceiling.Name = "Ceiling"
ceiling.Size = Vector3.new(40, 1, 130)
ceiling.Position = Vector3.new(0, 15, 60)
ceiling.Anchored = true
ceiling.Material = Enum.Material.SmoothPlastic
ceiling.Color = Color3.fromRGB(40, 40, 50)
ceiling.Transparency = 0.3
ceiling.Parent = mapFolder

print("Map created! Green platforms, red lava, arrows, checkpoint, finish!")