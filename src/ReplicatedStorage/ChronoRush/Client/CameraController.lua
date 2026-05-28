--[[
    ChronoRush - Camera Controller
    Handles camera-relative movement, Shift lock toggle, and character rotation
    
    Shift Lock: Locks cursor to center so camera rotates without RMB
    Character Rotation:
    - Shift OFF: Character faces movement direction (WASD)
    - Shift ON: Character faces camera direction
    Scroll Wheel: Always works for zoom (3rd person <-> closer)
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
    
    -- Shift lock state (cursor locked to center, camera rotates freely)
    self.IsShiftLockEnabled = false
    
    -- Character rotation mode
    self.RotateWithCamera = false -- True when shift lock is on
    
    -- Camera zoom settings
    self.MinZoom = 10  -- Closest zoom (FPS-ish)
    self.MaxZoom = 60  -- Farthest zoom (full 3rd person)
    self.ZoomStep = 5   -- Scroll wheel step size
    self.DefaultZoom = 35
    
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
    
    -- Listen for scroll wheel zoom (always works!)
    UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            self:HandleZoom(input.Position.Z)
        end
    end)
    
    -- Update loop - handle character rotation
    self.Connection = RunService.RenderStepped:Connect(function(dt)
        self:Update(dt)
    end)
end

function CameraController:ToggleShiftLock()
    self.IsShiftLockEnabled = not self.IsShiftLockEnabled
    self.RotateWithCamera = self.IsShiftLockEnabled
    
    if self.IsShiftLockEnabled then
        -- Lock cursor to center - camera rotates freely without RMB
        -- MiddleClick allows mouse look without zooming in to FPS
        self.Player.CameraMode = Enum.CameraMode.Classic
        UserInputService.MouseBehavior = Enum.MouseBehavior.MiddleClick
        
        -- Set comfortable zoom distance for locked camera
        self.Player.CameraMinZoomDistance = 25
        self.Player.CameraMaxZoomDistance = 25
    else
        -- Release - allow free mouse look and zoom
        self.Player.CameraMode = Enum.CameraMode.Classic
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        
        -- Reset to default zoom
        self.Player.CameraMinZoomDistance = 10
        self.Player.CameraMaxZoomDistance = 128
    end
    
    print("Shift Lock: " .. (self.IsShiftLockEnabled and "ON" or "OFF"))
end

function CameraController:HandleZoom(scrollDelta)
    -- Always allow zoom regardless of shift lock state
    local currentZoom = self.Camera.CFrame.LookVector.Magnitude
    
    if scrollDelta > 0 then
        -- Scroll up = zoom in (closer)
        currentZoom = math.max(self.MinZoom, currentZoom - self.ZoomStep)
    else
        -- Scroll down = zoom out (farther)
        currentZoom = math.min(self.MaxZoom, currentZoom + self.ZoomStep)
    end
    
    -- Apply zoom by setting camera offset
    -- We do this by modifying the camera's subject offset
    self:SetCameraZoom(currentZoom)
end

function CameraController:SetCameraZoom(zoom)
    -- Set camera distance from character
    self.Player.CameraMinZoomDistance = zoom
    self.Player.CameraMaxZoomDistance = zoom
end

function CameraController:Update(dt)
    -- Character rotation is handled by Movement module
    -- This just tracks the state
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

function CameraController:GetCameraYaw()
    -- Get camera's Y rotation (for character facing)
    local lookVector = self.Camera.CFrame.LookVector
    return math.atan2(-lookVector.X, -lookVector.Z)
end

function CameraController:Destroy()
    if self.Connection then
        self.Connection:Disconnect()
    end
    
    -- Reset camera mode
    self.Player.CameraMode = Enum.CameraMode.Classic
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    
    -- Reset zoom
    self.Player.CameraMinZoomDistance = 0.5
    self.Player.CameraMaxZoomDistance = 400
end

return CameraController