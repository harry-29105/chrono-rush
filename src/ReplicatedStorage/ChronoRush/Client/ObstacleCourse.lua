--[[
    ChronoRush - Obstacle Course
    Creates the actual visible map with:
    - Start line
    - Lava floor with platforms
    - Checkpoint
    - Finish line
    
    All parts are visible in the game world!
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ChronoRushClient = ReplicatedStorage:WaitForChild("ChronoRush"):WaitForChild("Client")

local ObstacleCourse = {}
ObstacleCourse.__index = ObstacleCourse

function ObstacleCourse.new()
    local self = setmetatable({}, ObstacleCourse)
    
    self.Player = Players.LocalPlayer
    self.CourseParts = {}
    self.Camera = workspace.CurrentCamera
    
    return self
end

function ObstacleCourse:CreateLevel1()
    print("Creating Level 1 obstacle course...")
    
    -- Clear any existing course
    self:ClearCourse()
    
    -- Create course parts
    self:CreateStartLine()
    self:CreateLavaFloor()
    self:CreatePlatforms()
    self:CreateCheckpoint()
    self:CreateFinishLine()
    self:CreatePathGuides()
    
    print("Obstacle course created! Follow the green platforms.")
end

function ObstacleCourse:CreateStartLine()
    -- Start line (green)
    local startLine = Instance.new("Part")
    startLine.Name = "StartLine"
    startLine.Size = Vector3.new(30, 1, 3)
    startLine.Position = Vector3.new(0, 0.5, 0)
    startLine.Anchored = true
    startLine.CanCollide = true
    startLine.Material = Enum.Material.SmoothPlastic
    startLine.Color = Color3.fromRGB(50, 255, 100)
    startLine.Parent = workspace
    
    -- Glow effect
    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(50, 255, 100)
    light.Brightness = 1
    light.Range = 15
    light.Parent = startLine
    
    -- Text sign
    local sign = Instance.new("SurfaceGui")
    sign.Parent = startLine
    sign.Face = Enum.NormalId.Top
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.Text = "START"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Parent = sign
    
    table.insert(self.CourseParts, startLine)
end

function ObstacleCourse:CreateLavaFloor()
    -- Lava floor (red, kills you)
    local lava = Instance.new("Part")
    lava.Name = "LavaFloor"
    lava.Size = Vector3.new(30, 0.5, 100)
    lava.Position = Vector3.new(0, -1, 50) -- Extended lava
    lava.Anchored = true
    lava.CanCollide = true
    lava.Material = Enum.Material.Neon
    lava.Color = Color3.fromRGB(255, 50, 0)
    lava.Parent = workspace
    
    -- Kill script
    local killScript = Instance.new("Script")
    killScript.Source = [[
        script.Parent.Touched:Connect(function(otherPart)
            if otherPart.Name == "Hitbox" or otherPart.Name == "HumanoidRootPart" then
                local character = otherPart.Parent
                if character and character:FindFirstChild("Humanoid") then
                    local humanoid = character:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        humanoid.Health = 0
                    end
                end
            end
        end)
    ]]
    killScript.Disabled = false
    killScript.Parent = lava
    
    table.insert(self.CourseParts, lava)
end

function ObstacleCourse:CreatePlatforms()
    -- Platform positions (jumping stones over lava)
    local platforms = {
        {pos = Vector3.new(0, 2, 15), size = Vector3.new(8, 1, 8)},      -- First jump
        {pos = Vector3.new(5, 3, 30), size = Vector3.new(7, 1, 7)},     -- Second jump
        {pos = Vector3.new(-5, 4, 45), size = Vector3.new(7, 1, 7)},     -- Third jump
        {pos = Vector3.new(0, 5, 60), size = Vector3.new(8, 1, 8)},      -- Fourth jump
        {pos = Vector3.new(3, 5, 75), size = Vector3.new(8, 1, 8)},      -- Fifth jump (before checkpoint)
    }
    
    for i, p in ipairs(platforms) do
        local platform = Instance.new("Part")
        platform.Name = "Platform_" .. i
        platform.Size = p.size
        platform.Position = p.pos
        platform.Anchored = true
        platform.CanCollide = true
        platform.Material = Enum.Material.SmoothPlastic
        platform.Color = Color3.fromRGB(100, 200, 100) -- Greenish platforms
        platform.Parent = workspace
        
        -- Glow effect
        local light = Instance.new("PointLight")
        light.Color = Color3.fromRGB(100, 255, 100)
        light.Brightness = 0.8
        light.Range = 10
        light.Parent = platform
        
        table.insert(self.CourseParts, platform)
    end
end

function ObstacleCourse:CreateCheckpoint()
    -- Checkpoint (glowing cyan)
    local checkpoint = Instance.new("Part")
    checkpoint.Name = "Checkpoint"
    checkpoint.Size = Vector3.new(30, 5, 3)
    checkpoint.Position = Vector3.new(0, 2.5, 90)
    checkpoint.Anchored = true
    checkpoint.CanCollide = false
    checkpoint.Material = Enum.Material.Neon
    checkpoint.Color = Color3.fromRGB(0, 255, 200)
    checkpoint.Transparency = 0.3
    checkpoint.Parent = workspace
    
    -- Intense glow
    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(0, 255, 200)
    light.Brightness = 2
    light.Range = 20
    light.Parent = checkpoint
    
    -- Checkpoint trigger
    local trigger = Instance.new("Script")
    trigger.Source = [[
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local fired = false
        
        script.Parent.Touched:Connect(function(otherPart)
            if fired then return end
            
            if otherPart.Name == "Hitbox" or otherPart.Name == "HumanoidRootPart" then
                local character = otherPart.Parent
                if character then
                    local player = Players:GetPlayerFromCharacter(character)
                    if player then
                        fired = true
                        
                        -- Fire to GameManager (via remote event if needed)
                        -- For now, just show message
                        local playerGui = player:FindFirstChild("PlayerGui")
                        if playerGui then
                            local ui = playerGui:FindFirstChild("ChronoRushUI")
                            if ui then
                                -- The checkpoint is reached logic is in GameManager
                            end
                        end
                    end
                end
            end
        end)
    ]]
    trigger.Disabled = false
    trigger.Parent = checkpoint
    
    table.insert(self.CourseParts, checkpoint)
end

function ObstacleCourse:CreateFinishLine()
    -- Finish line (gold)
    local finish = Instance.new("Part")
    finish.Name = "FinishLine"
    finish.Size = Vector3.new(30, 3, 5)
    finish.Position = Vector3.new(0, 1.5, 125)
    finish.Anchored = true
    finish.CanCollide = false
    finish.Material = Enum.Material.Neon
    finish.Color = Color3.fromRGB(255, 215, 0) -- Gold
    finish.Transparency = 0.5
    finish.Parent = workspace
    
    -- Gold glow
    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 215, 0)
    light.Brightness = 2
    light.Range = 25
    light.Parent = finish
    
    -- Text sign
    local sign = Instance.new("SurfaceGui")
    sign.Parent = finish
    sign.Face = Enum.NormalId.Top
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.Text = "FINISH!"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Parent = sign
    
    table.insert(self.CourseParts, finish)
end

function ObstacleCourse:CreatePathGuides()
    -- Arrow indicators pointing forward
    for z = 20, 80, 20 do
        local arrow = Instance.new("Part")
        arrow.Name = "Arrow_" .. z
        arrow.Size = Vector3.new(3, 0.2, 3)
        arrow.Position = Vector3.new(0, 0.3, z)
        arrow.Anchored = true
        arrow.CanCollide = false
        arrow.Material = Enum.Material.Neon
        arrow.Color = Color3.fromRGB(255, 255, 100) -- Yellow arrows
        arrow.Parent = workspace
        
        local light = Instance.new("PointLight")
        light.Color = Color3.fromRGB(255, 255, 100)
        light.Brightness = 0.5
        light.Range = 5
        light.Parent = arrow
        
        table.insert(self.CourseParts, arrow)
    end
end

function ObstacleCourse:ClearCourse()
    for _, part in ipairs(self.CourseParts) do
        if part and part.Parent then
            part:Destroy()
        end
    end
    self.CourseParts = {}
    
    -- Also clear any existing course parts by name
    local names = {"StartLine", "LavaFloor", "Platform_1", "Platform_2", "Platform_3", 
                   "Platform_4", "Platform_5", "Checkpoint", "FinishLine", "Arrow_20", 
                   "Arrow_40", "Arrow_60", "Arrow_80"}
    
    for _, name in ipairs(names) do
        local existing = workspace:FindFirstChild(name)
        if existing then
            existing:Destroy()
        end
    end
end

function ObstacleCourse:TeleportToStart()
    -- Teleport player to start
    local player = self.Player
    local character = player.Character
    
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(0, 2, 0)
            print("Teleported to start!")
        end
    end
end

function ObstacleCourse:Destroy()
    self:ClearCourse()
end

return ObstacleCourse