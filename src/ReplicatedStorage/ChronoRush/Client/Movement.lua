--[[
    ChronoRush - Movement Module
    Handles player movement with smooth acceleration/deceleration
    Blox Fruits-inspired floaty but responsive feel
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Constants = require(script.Parent.Parent.Shared.Constants)

local Movement = {}
Movement.__index = Movement

function Movement.new(character)
    local self = setmetatable({}, Movement)
    
    self.Character = character
    self.Humanoid = character:WaitForChild("Humanoid")
    self.RootPart = character:WaitForChild("HumanoidRootPart")
    
    -- Movement state
    self.MoveDirection = Vector3.new()
    self.CurrentVelocity = Vector3.new()
    self.LastMoveInput = Vector3.new()
    
    -- Physics
    self.GroundDetector = nil
    
    return self
end

function Movement:Start()
    -- Wait for character to be loaded
    if not self.Humanoid or not self.RootPart then
        return
    end
    
    -- Set initial physics
    self.Humanoid.WalkSpeed = Constants.MOVE_SPEED
    self.Humanoid.JumpPower = Constants.JUMP_FORCE
    
    -- Track movement input
    self.Humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
        self:OnMoveDirectionChanged()
    end)
    
    -- Update loop
    self.Connection = RunService.Heartbeat:Connect(function(dt)
        self:Update(dt)
    end)
end

function Movement:OnMoveDirectionChanged()
    local moveDir = self.Humanoid.MoveDirection
    if moveDir.Magnitude > 0 then
        self.LastMoveInput = moveDir
    end
end

function Movement:Update(dt)
    local humanoid = self.Humanoid
    local rootPart = self.RootPart
    
    if not humanoid or not rootPart then return end
    
    -- Get movement input
    local moveDir = humanoid.MoveDirection
    
    -- Apply acceleration/deceleration for smooth feel
    if moveDir.Magnitude > 0 then
        -- Accelerate towards input direction
        self.CurrentVelocity = self.CurrentVelocity:Lerp(
            moveDir * Constants.MOVE_SPEED,
            Constants.ACCELERATION * dt
        )
    else
        -- Decelerate when no input
        self.CurrentVelocity = self.CurrentVelocity:Lerp(
            Vector3.new(),
            Constants.DECELERATION * dt
        )
    end
    
    -- Air control (reduce acceleration in air)
    local isAirborne = humanoid:GetState() ~= Enum.HumanoidStateType.Running
    if isAirborne then
        self.CurrentVelocity = self.CurrentVelocity * Constants.AIR_CONTROL
    end
    
    -- Apply velocity via BodyVelocity
    if not self.BodyVelocity then
        self.BodyVelocity = Instance.new("BodyVelocity")
        self.BodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
        self.BodyVelocity.Parent = rootPart
    end
    
    -- Only move horizontally (preserve jump/dash vertical)
    local horizontalVel = Vector3.new(self.CurrentVelocity.X, 0, self.CurrentVelocity.Z)
    self.BodyVelocity.Velocity = horizontalVel
end

function Movement:Destroy()
    if self.Connection then
        self.Connection:Disconnect()
    end
    if self.BodyVelocity then
        self.BodyVelocity:Destroy()
    end
end

return Movement