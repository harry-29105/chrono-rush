--[[
    ChronoRush - Runner Controller
    Handles forward movement and runner-style camera
    Player runs forward, camera follows from behind
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChronoRushClient = ReplicatedStorage:WaitForChild("ChronoRush"):WaitForChild("Client")

local Constants = require(ReplicatedStorage:WaitForChild("ChronoRush"):WaitForChild("Shared"):WaitForChild("Constants"))
local CameraController = require(ChronoRushClient:WaitForChild("CameraController"))

local RunnerController = {}
RunnerController.__index = RunnerController

function RunnerController.new(character)
    local self = setmetatable({}, RunnerController)
    
    self.Character = character
    self.Humanoid = character:WaitForChild("Humanoid")
    self.RootPart = character:WaitForChild("HumanoidRootPart")
    
    -- Movement state
    self.CurrentVelocity = Vector3.new()
    
    -- Camera controller
    self.CameraCtrl = CameraController.new()
    self.CameraCtrl:Start()
    
    -- Physics
    self.BodyVelocity = nil
    
    -- WASD tracking
    self.WKeyDown = false
    self.AKeyDown = false
    self.SKeyDown = false
    self.DKeyDown = false
    
    -- Runner mode settings
    self.ForwardSpeed = Constants.MOVE_SPEED
    
    -- Callback for position updates
    self.OnPositionUpdate = nil
    
    return self
end

function RunnerController:Start()
    if not self.Humanoid or not self.RootPart then
        return
    end
    
    -- Disable default humanoid movement
    self.Humanoid.WalkSpeed = 0
    self.Humanoid.JumpPower = Constants.JUMP_FORCE
    
    -- Create BodyVelocity for custom movement
    self.BodyVelocity = Instance.new("BodyVelocity")
    self.BodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
    self.BodyVelocity.Parent = self.RootPart
    
    -- Track WASD keys
    self:SetupInputTracking()
    
    -- Update loop
    self.Connection = RunService.Heartbeat:Connect(function(dt)
        self:Update(dt)
    end)
end

function RunnerController:SetupInputTracking()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.W then self.WKeyDown = true end
        if input.KeyCode == Enum.KeyCode.A then self.AKeyDown = true end
        if input.KeyCode == Enum.KeyCode.S then self.SKeyDown = true end
        if input.KeyCode == Enum.KeyCode.D then self.DKeyDown = true end
    end)
    
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.W then self.WKeyDown = false end
        if input.KeyCode == Enum.KeyCode.A then self.AKeyDown = false end
        if input.KeyCode == Enum.KeyCode.S then self.SKeyDown = false end
        if input.KeyCode == Enum.KeyCode.D then self.DKeyDown = false end
    end)
end

function RunnerController:Update(dt)
    local humanoid = self.Humanoid
    local rootPart = self.RootPart
    
    if not humanoid or not rootPart or not self.BodyVelocity then return end
    
    -- CHECK IF DASHING
    if self.Character and self.Character:GetAttribute("Dashing") then
        local dashEndTime = self.Character:GetAttribute("DashEndTime") or 0
        local dashDir = self.Character:GetAttribute("DashDirection")
        
        if dashDir and tick() < dashEndTime then
            -- DASH MODE
            self.BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            local currentY = rootPart.Velocity.Y
            self.BodyVelocity.Velocity = Vector3.new(
                dashDir.X * Constants.DASH_SPEED,
                currentY,
                dashDir.Z * Constants.DASH_SPEED
            )
            
            -- Notify position update
            if self.OnPositionUpdate then
                self.OnPositionUpdate(rootPart.Position.Z)
            end
            return
        else
            if self.Character then
                self.Character:SetAttribute("Dashing", false)
            end
        end
    end
    
    -- NORMAL MOVEMENT
    self.BodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
    
    -- Calculate movement direction
    local moveX = 0
    local moveZ = 0
    
    -- Forward/backward (W/S moves in Z direction - forward/back)
    if self.WKeyDown then moveZ = moveZ + 1 end
    if self.SKeyDown then moveZ = moveZ - 1 end
    
    -- Strafe (A/D moves in X direction - left/right)
    if self.AKeyDown then moveX = moveX - 1 end
    if self.DKeyDown then moveX = moveX + 1 end
    
    -- Apply movement
    local targetVel = Vector3.new(moveX * self.ForwardSpeed, 0, moveZ * self.ForwardSpeed)
    
    -- Smooth acceleration
    self.CurrentVelocity = self.CurrentVelocity:Lerp(targetVel, Constants.ACCELERATION * dt)
    
    -- Air control
    local isAirborne = humanoid:GetState() ~= Enum.HumanoidStateType.Running
    if isAirborne then
        self.CurrentVelocity = self.CurrentVelocity * Constants.AIR_CONTROL
    end
    
    self.BodyVelocity.Velocity = self.CurrentVelocity
    
    -- Notify position update (for level progress tracking)
    if self.OnPositionUpdate then
        self.OnPositionUpdate(rootPart.Position.Z)
    end
    
    -- Rotate character to face movement direction when moving
    if moveX ~= 0 or moveZ ~= 0 then
        self:RotateToFaceMovement(moveX, moveZ)
    end
end

function RunnerController:RotateToFaceMovement(moveX, moveZ)
    -- Face the direction of movement (but only horizontal)
    local direction = Vector3.new(moveX, 0, moveZ)
    if direction.Magnitude < 0.1 then return end
    direction = direction.Unit
    
    local targetCFrame = CFrame.lookAt(self.RootPart.Position, self.RootPart.Position + direction)
    self.RootPart.CFrame = targetCFrame
end

function RunnerController:SetForwardSpeed(speed)
    self.ForwardSpeed = speed
end

function RunnerController:Destroy()
    if self.Connection then
        self.Connection:Disconnect()
    end
    if self.CameraCtrl then
        self.CameraCtrl:Destroy()
    end
    if self.BodyVelocity then
        self.BodyVelocity:Destroy()
    end
end

return RunnerController