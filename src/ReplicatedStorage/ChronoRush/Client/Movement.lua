--[[
    ChronoRush - Movement Module
    Handles player movement with smooth acceleration/deceleration
    Blox Fruits-inspired floaty but responsive feel
    Cooperates with Dash module via character attributes
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage:WaitForChild("ChronoRush"):WaitForChild("Shared"):WaitForChild("Constants"))

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
    self.BodyVelocity = nil
    
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
    
    -- Create BodyVelocity for custom movement
    self.BodyVelocity = Instance.new("BodyVelocity")
    self.BodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
    self.BodyVelocity.Parent = self.RootPart
    
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
    
    if not humanoid or not rootPart or not self.BodyVelocity then return end
    
    -- CHECK IF DASHING - override velocity if so (Blox Fruits style)
    if self.Character and self.Character:GetAttribute("Dashing") then
        local dashEndTime = self.Character:GetAttribute("DashEndTime") or 0
        local dashDir = self.Character:GetAttribute("DashDirection")
        
        if dashDir and tick() < dashEndTime then
            -- DASH MODE - apply full velocity control to fight gravity
            self.BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            local currentY = rootPart.Velocity.Y
            self.BodyVelocity.Velocity = Vector3.new(
                dashDir.X * Constants.DASH_SPEED, 
                currentY,
                dashDir.Z * Constants.DASH_SPEED
            )
            return -- Skip normal movement
        else
            -- Dash ended
            if self.Character then
                self.Character:SetAttribute("Dashing", false)
            end
        end
    end
    
    -- NORMAL MOVEMENT - restore X/Z control only
    self.BodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
    
    -- Get movement input
    local moveDir = humanoid.MoveDirection
    
    -- Apply acceleration/deceleration for smooth feel
    if moveDir.Magnitude > 0 then
        self.CurrentVelocity = self.CurrentVelocity:Lerp(
            moveDir * Constants.MOVE_SPEED,
            Constants.ACCELERATION * dt
        )
    else
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
    
    -- Only move horizontally (preserve jump/fall via physics)
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