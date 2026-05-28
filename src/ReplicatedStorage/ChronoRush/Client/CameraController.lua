--[[
    ChronoRush - Camera Controller
    Handles camera-relative movement, Shift lock toggle, and character rotation
    
    Smooth scroll zoom - no fixed steps, continuous control
    Scroll up = zoom in | Scroll down = zoom out
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
    self.RotateWithCamera = false
    
    -- Smooth zoom settings
    self.MinZoom = 0.5   -- Maximum zoom in (FPS view)
    self.MaxZoom = 80    -- Maximum zoom out (limited as requested)
    
    -- Current zoom state
    self.TargetZoom = 35 -- Default starting zoom
    self.CurrentZoom = 35
    self.ZoomSpeed = 10  -- How fast to interpolate to target zoom
    
    -- Scroll sensitivity
    self.ScrollSensitivity = 0.5 -- Zoom per scroll tick
    
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
    
    -- Listen for scroll wheel (smooth continuous zoom)
    UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            self:HandleZoom(input.Position.Z)
        end
    end)
    
    -- Update loop - smooth zoom interpolation
    self.Connection = RunService.RenderStepped:Connect(function(dt)
        self:Update(dt)
    end)
end

function CameraController:ToggleShiftLock()
    self.IsShiftLockEnabled = not self.IsShiftLockEnabled
    self.RotateWithCamera = self.IsShiftLockEnabled
    
    if self.IsShiftLockEnabled then
        -- Lock cursor to center
        self.Player.CameraMode = Enum.CameraMode.Classic
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        
        -- Lock to comfortable zoom when shift lock on
        self.TargetZoom = 25
        self.CurrentZoom = 25
        self:ApplyZoom(25)
    else
        -- Release cursor
        self.Player.CameraMode = Enum.CameraMode.Classic
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        
        -- Reset zoom limits
        self.Player.CameraMinZoomDistance = self.MinZoom
        self.Player.CameraMaxZoomDistance = self.MaxZoom
    end
    
    print("Shift Lock: " .. (self.IsShiftLockEnabled and "ON" or "OFF"))
end

function CameraController:HandleZoom(scrollDelta)
    -- Smooth zoom - no fixed steps, continuous control
    -- scrollDelta: positive = scroll up (zoom in), negative = scroll down (zoom out)
    
    local zoomChange = scrollDelta * self.ScrollSensitivity * 5 -- Multiply for smoother control
    self.TargetZoom = self.TargetZoom - zoomChange
    
    -- Clamp to limits
    self.TargetZoom = math.max(self.MinZoom, math.min(self.MaxZoom, self.TargetZoom))
    
    -- Reset to FPS if target is very close
    if self.TargetZoom < 5 then
        self.Player.CameraMode = Enum.CameraMode.LockFirstPerson
    end
end

function CameraController:Update(dt)
    -- Smoothly interpolate to target zoom
    if math.abs(self.CurrentZoom - self.TargetZoom) > 0.1 then
        self.CurrentZoom = self.CurrentZoom + (self.TargetZoom - self.CurrentZoom) * self.ZoomSpeed * dt
        self:ApplyZoom(self.CurrentZoom)
    end
end

function CameraController:ApplyZoom(zoom)
    -- Apply zoom by setting camera distance
    self.Player.CameraMinZoomDistance = zoom
    self.Player.CameraMaxZoomDistance = zoom
end

function CameraController:GetCameraRelativeDirections()
    local cameraCFrame = self.Camera.CFrame
    local lookVector = cameraCFrame.LookVector
    local rightVector = cameraCFrame.RightVector
    
    -- Flatten to horizontal
    local forward = Vector3.new(lookVector.X, 0, lookVector.Z)
    if forward.Magnitude < 0.01 then
        forward = Vector3.new(0, 0, -1)
    else
        forward = forward.Unit
    end
    
    local right = Vector3.new(rightVector.X, 0, rightVector.Z)
    if right.Magnitude < 0.01 then
        right = Vector3.new(1, 0, 0)
    else
        right = right.Unit
    end
    
    return forward, right
end

function CameraController:ConvertToCameraRelative(inputDir)
    local forward, right = self:GetCameraRelativeDirections()
    
    local moveDir = Vector3.new()
    moveDir = moveDir + (forward * -inputDir.Y)
    moveDir = moveDir + (right * inputDir.X)
    
    if moveDir.Magnitude > 0.01 then
        return moveDir.Unit
    else
        return Vector3.new()
    end
end

function CameraController:GetCameraYaw()
    local lookVector = self.Camera.CFrame.LookVector
    return math.atan2(-lookVector.X, -lookVector.Z)
end

function CameraController:Destroy()
    if self.Connection then
        self.Connection:Disconnect()
    end
    
    self.Player.CameraMode = Enum.CameraMode.Classic
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    self.Player.CameraMinZoomDistance = 0.5
    self.Player.CameraMaxZoomDistance = 400
end

return CameraController