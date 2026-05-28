--[[
    ChronoRush - Camera Controller
    Handles camera-relative movement and Shift lock toggle
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local CameraController = {}
CameraController.__index = CameraController

function CameraController.new()
    local self = setmetatable({}, CameraController)
    
    self.Player = Players.LocalPlayer
    self.Camera = workspace.CurrentCamera
    
    -- Shift lock state
    self.IsShiftLockEnabled = false
    self.LastMousePosition = nil
    
    return self
end

function CameraController:Start()
    -- Listen for Shift key toggle
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
            self:ToggleShiftLock()
        end
    end)
    
    -- Update loop
    self.Connection = RunService.RenderStepped:Connect(function(dt)
        self:Update(dt)
    end)
end

function CameraController:ToggleShiftLock()
    self.IsShiftLockEnabled = not self.IsShiftLockEnabled
    
    if self.IsShiftLockEnabled then
        -- Lock camera to cursor position
        self:LockToCursor()
        print("Shift Lock: ON")
    else
        -- Release camera
        self:UnlockFromCursor()
        print("Shift Lock: OFF")
    end
end

function CameraController:LockToCursor()
    -- Enable mouse lock
    self.Player.CameraMode = Enum.CameraMode.LockFirstPerson
    
    -- Lock cursor
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end

function CameraController:UnlockFromCursor()
    -- Restore normal camera
    self.Player.CameraMode = Enum.CameraMode.Classic
    
    -- Unlock cursor
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

function CameraController:Update(dt)
    if not self.IsShiftLockEnabled then return end
    
    -- Keep cursor locked to center (for FPS-style look)
    if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    end
end

function CameraController:GetCameraRelativeDirections()
    -- Get camera CFrame
    local cameraCFrame = self.Camera.CFrame
    
    -- Extract forward and right vectors (flatten to horizontal plane)
    local lookVector = cameraCFrame.LookVector
    local rightVector = cameraCFrame.RightVector
    
    -- Flatten to horizontal (ignore Y component)
    local forward = Vector3.new(lookVector.X, 0, lookVector.Z)
    if forward.Magnitude < 0.01 then
        forward = Vector3.new(0, 0, -1) -- Default forward
    else
        forward = forward.Unit
    end
    
    local right = Vector3.new(rightVector.X, 0, rightVector.Z)
    if right.Magnitude < 0.01 then
        right = Vector3.new(1, 0, 0) -- Default right
    else
        right = right.Unit
    end
    
    return forward, right
end

function CameraController:ConvertToCameraRelative(inputDir)
    -- inputDir is a 2D vector: (x, z) from WASD
    -- Convert to camera-relative 3D direction
    
    local forward, right = self:GetCameraRelativeDirections()
    
    -- W = forward, S = back, A = left, D = right
    local moveDir = Vector3.new()
    
    -- Forward/back from input.y (W/S)
    moveDir = moveDir + (forward * -inputDir.Y)
    
    -- Left/right from input.x (A/D)
    moveDir = moveDir + (right * inputDir.X)
    
    if moveDir.Magnitude > 0.01 then
        return moveDir.Unit
    else
        return Vector3.new()
    end
end

function CameraController:Destroy()
    if self.Connection then
        self.Connection:Disconnect()
    end
    self:UnlockFromCursor()
end

return CameraController