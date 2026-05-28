--[[
    ChronoRush - Dash Module
    Handles dash ability with cooldown and charges
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Constants = require(script.Parent.Parent.Shared.Constants)

local Dash = {}
Dash.__index = Dash

function Dash.new(character)
    local self = setmetatable({}, Dash)
    
    self.Character = character
    self.Humanoid = character:WaitForChild("Humanoid")
    self.RootPart = character:WaitForChild("HumanoidRootPart")
    
    -- Dash state
    self.CooldownRemaining = 0
    self.Charges = Constants.DASH_CHARGES
    self.MaxCharges = Constants.DASH_CHARGES
    self.IsDashing = false
    
    -- Direction tracking
    self.LastMoveDirection = Vector3.new(0, 0, 1) -- Default forward
    
    return self
end

function Dash:Start()
    local player = Players.LocalPlayer
    
    -- Listen for dash input
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.LeftShift or 
           input.KeyCode == Enum.KeyCode.RightShift then
            self:TryDash()
        end
    end)
    
    -- Track movement direction
    self.Humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
        local dir = self.Humanoid.MoveDirection
        if dir.Magnitude > 0 then
            self.LastMoveDirection = dir
        end
    end)
    
    -- Update cooldown
    self.Connection = RunService.Heartbeat:Connect(function(dt)
        self:Update(dt)
    end)
end

function Dash:TryDash()
    -- Check if we can dash
    if self.IsDashing then return end
    if self.CooldownRemaining > 0 then return end
    if self.Charges <= 0 then return end
    
    -- Execute dash
    self:ExecuteDash()
end

function Dash:ExecuteDash()
    local humanoid = self.Humanoid
    local rootPart = self.RootPart
    
    if not rootPart then return end
    
    self.IsDashing = true
    self.Charges = self.Charges - 1
    
    -- Determine dash direction
    local dashDir = self.LastMoveDirection
    
    -- If no direction, use character's facing direction
    if dashDir.Magnitude < 0.1 then
        dashDir = rootPart.CFrame.LookVector
    end
    
    -- Normalize horizontal direction (no vertical dash)
    dashDir = Vector3.new(dashDir.X, 0, dashDir.Z).Unit
    
    -- Create dash velocity
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = dashDir * Constants.DASH_SPEED + Vector3.new(0, 20, 0)
    bodyVelocity.Parent = rootPart
    
    -- Spawn trail effect
    self:SpawnTrail(rootPart)
    
    -- End dash after duration
    task.delay(Constants.DASH_DURATION, function()
        if bodyVelocity and bodyVelocity.Parent then
            bodyVelocity:Destroy()
        end
        self.IsDashing = false
        
        -- Start cooldown
        self.CooldownRemaining = Constants.DASH_COOLDOWN
        
        -- Recharge after cooldown
        task.delay(Constants.DASH_COOLDOWN, function()
            if self.Charges < self.MaxCharges then
                self.Charges = self.Charges + 1
            end
        end)
    end)
end

function Dash:SpawnTrail(rootPart)
    -- Create visual trail effect during dash
    local trail = Instance.new("Trail")
    trail.Lifetime = 0.3
    trail.FaceCamera = true
    
    -- Front attachment
    local a0 = Instance.new("Attachment")
    a0.Position = Vector3.new(0, 0, -0.5)
    a0.Parent = rootPart
    
    -- Back attachment
    local a1 = Instance.new("Attachment")
    a1.Position = Vector3.new(0, 0, 0.5)
    a1.Parent = rootPart
    
    -- Trail parts
    local b = Instance.new("Beam")
    b.Attachment0 = a0
    b.Attachment1 = a1
    b.Color = ColorSequence.new(Constants.COLOR_DASH_TRAIL)
    b.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    b.Width = 0.5
    b.Parent = rootPart
    
    -- Remove after dash
    task.delay(Constants.DASH_DURATION + 0.5, function()
        trail:Destroy()
        b:Destroy()
    end)
end

function Dash:Update(dt)
    -- Countdown cooldown
    if self.CooldownRemaining > 0 then
        self.CooldownRemaining = self.CooldownRemaining - dt
    end
end

function Dash:IsReady()
    return not self.IsDashing and 
           self.CooldownRemaining <= 0 and 
           self.Charges > 0
end

function Dash:Destroy()
    if self.Connection then
        self.Connection:Disconnect()
    end
end

return Dash