--[[
    ChronoRush - Movement Module
    Handles player movement with smooth acceleration/deceleration
    Camera-relative movement: W moves towards camera facing direction
    
    Character Rotation:
    - Shift OFF: Character faces movement direction (WASD)
    - Shift ON: Character faces camera direction
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChronoRushClient = ReplicatedStorage:WaitForChild("ChronoRush"):WaitForChild("Client")

local Constants = require(ReplicatedStorage:WaitForChild("ChronoRush"):WaitForChild("Shared"):WaitForChild("Constants"))
local CameraController = require(ChronoRushClient:WaitForChild("CameraController"))

local Movement = {}
Movement.__index = Movement

function Movement.new(character)
    local self = setmetatable({}, Movement)
    
    self.Character = character
    self.Humanoid = character:WaitForChild("Humanoid")
    self.RootPart = character:WaitForChild("HumanoidRootPart")
    
    -- Movement state
    self.CurrentVelocity = Vector3.new()
    self.LastMoveInput = Vector3.new()
    
    -- Camera controller for relative movement
    self.CameraCtrl = CameraController.new()
    self.CameraCtrl:Start()
    
    -- BodyGyro for character rotation
    self.BodyGyro = nil
    
    -- Physics
    self.BodyVelocity = nil
    
    -- WASD key tracking
    self.WKeyDown = false
    self.AKeyDown = false
    self.SKeyDown = false
    self.DKeyDown = false
    
    return self
end

function Movement:Start()
    -- Wait for character to be loaded
    if not self.Humanoid or not self.RootPart then
        return
    end
    
    -- Set initial physics
    self.Humanoid.WalkSpeed = 0 -- We control movement manually
    self.Humanoid.JumpPower = Constants.JUMP_FORCE
    
    -- Create BodyVelocity for custom movement
    self.BodyVelocity = Instance.new("BodyVelocity")
    self.BodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
    self.BodyVelocity.Parent = self.RootPart
    
    -- Create BodyGyro for character rotation (snappier)
    self.BodyGyro = Instance.new("BodyGyro")
    self.BodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    self.BodyGyro.P = 20000 -- Higher P = snappier rotation
    self.BodyGyro.D = 1000  -- Higher D = less oscillation
    self.BodyGyro.Parent = self.RootPart
    
    -- Track WASD keys for raw input
    self:SetupInputTracking()
    
    -- Update loop
    self.Connection = RunService.Heartbeat:Connect(function(dt)
        self:Update(dt)
    end)
end

function Movement:SetupInputTracking()
    -- Track W key
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

function Movement:GetRawInputDirection()
    -- Get raw WASD input as 2D vector (camera-relative)
    local inputX = 0
    local inputZ = 0
    
    if self.WKeyDown then inputZ = inputZ - 1 end
    if self.SKeyDown then inputZ = inputZ + 1 end
    if self.AKeyDown then inputX = inputX - 1 end
    if self.DKeyDown then inputX = inputX + 1 end
    
    return Vector2.new(inputX, inputZ)
end

function Movement:Update(dt)
    local humanoid = self.Humanoid
    local rootPart = self.RootPart
    
    if not humanoid or not rootPart then return end
    if not self.BodyVelocity or not self.BodyGyro then return end
    
    -- CHECK IF DASHING - override velocity if so
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
            
            -- Rotate character to face dash direction
            self:RotateCharacterToDirection(dashDir)
            return
        else
            if self.Character then
                self.Character:SetAttribute("Dashing", false)
            end
        end
    end
    
    -- NORMAL MOVEMENT
    self.BodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
    
    -- Get camera-relative movement direction
    local rawInput = self:GetRawInputDirection()
    local moveDir = self.CameraCtrl:ConvertToCameraRelative(rawInput)
    
    -- Store last input for dash fallback
    if moveDir.Magnitude > 0.01 then
        self.LastMoveInput = moveDir
    end
    
    -- Apply acceleration/deceleration for smooth feel
    if moveDir.Magnitude > 0.01 then
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
    
    -- CHARACTER ROTATION based on shift lock state
    if self.CameraCtrl.IsShiftLockEnabled then
        -- Shift ON: Face camera direction
        local cameraYaw = self.CameraCtrl:GetCameraYaw()
        self:RotateCharacterToYaw(cameraYaw)
    else
        -- Shift OFF: Face movement direction
        if moveDir.Magnitude > 0.01 then
            self:RotateCharacterToDirection(moveDir)
        end
    end
end

function Movement:RotateCharacterToDirection(direction)
    -- Flatten to horizontal
    local flatDir = Vector3.new(direction.X, 0, direction.Z)
    if flatDir.Magnitude < 0.01 then return end
    flatDir = flatDir.Unit
    
    -- Create CFrame that faces the direction
    local targetCFrame = CFrame.lookAt(self.RootPart.Position, self.RootPart.Position + flatDir)
    
    -- Apply rotation (keep current Y position)
    self.BodyGyro.CFrame = targetCFrame
end

function Movement:RotateCharacterToYaw(yaw)
    -- Create CFrame with just Y rotation
    local targetCFrame = CFrame.Angles(0, yaw, 0)
    targetCFrame = targetCFrame + self.RootPart.Position
    
    self.BodyGyro.CFrame = targetCFrame
end

function Movement:Destroy()
    if self.Connection then
        self.Connection:Disconnect()
    end
    if self.CameraCtrl then
        self.CameraCtrl:Destroy()
    end
    if self.BodyVelocity then
        self.BodyVelocity:Destroy()
    end
    if self.BodyGyro then
        self.BodyGyro:Destroy()
    end
end

return Movement