--[[
    ChronoRush - Dash Module
    Handles dash ability with cooldown and charges
    Blox Fruits-style: dash in camera-relative WASD direction
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChronoRushClient = ReplicatedStorage:WaitForChild("ChronoRush"):WaitForChild("Client")

local Constants = require(ReplicatedStorage:WaitForChild("ChronoRush"):WaitForChild("Shared"):WaitForChild("Constants"))
local CameraController = require(ChronoRushClient:WaitForChild("CameraController"))

local Dash = {}
Dash.__index = Dash

-- Key code mappings for WASD
local KEY_TO_DIRECTION = {
    [Enum.KeyCode.W] = Vector3.new(0, 0, -1),
    [Enum.KeyCode.S] = Vector3.new(0, 0, 1),
    [Enum.KeyCode.A] = Vector3.new(-1, 0, 0),
    [Enum.KeyCode.D] = Vector3.new(1, 0, 0),
}

function Dash.new(character)
    local self = setmetatable({}, Dash)
    
    self.Character = character
    self.Humanoid = character:WaitForChild("Humanoid")
    self.RootPart = character:WaitForChild("HumanoidRootPart")
    
    -- Camera controller for camera-relative dash
    self.CameraCtrl = CameraController.new()
    
    -- Dash state
    self.CooldownRemaining = 0
    self.Charges = Constants.DASH_CHARGES
    self.MaxCharges = Constants.DASH_CHARGES
    self.IsDashing = false
    
    return self
end

function Dash:Start()
    local player = Players.LocalPlayer
    
    -- Listen for Q key dash
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Q then
            self:TryDash()
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
    
    -- BLOX FRUITS STYLE: Dash in WASD INPUT direction, NOT facing direction
    -- Use last known movement input, or default forward if no input
    local dashDir = self:GetCurrentInputDirection()
    
    -- Normalize to purely horizontal (ignore Y)
    dashDir = Vector3.new(dashDir.X, 0, dashDir.Z)
    if dashDir.Magnitude < 0.1 then
        dashDir = Vector3.new(0, 0, 1) -- Default forward if somehow zero
    end
    dashDir = dashDir.Unit
    
    -- Tell Movement to apply dash with CURRENT Y velocity preserved
    if self.Character then
        self.Character:SetAttribute("Dashing", true)
        self.Character:SetAttribute("DashDirection", dashDir)
        self.Character:SetAttribute("DashEndTime", tick() + Constants.DASH_DURATION)
    end
    
    -- Visual effects
    self:SpawnDashEffect(rootPart)
    
    -- End dash after duration
    task.delay(Constants.DASH_DURATION, function()
        if self.Character then
            self.Character:SetAttribute("Dashing", false)
        end
        self.IsDashing = false
        
        -- Start cooldown
        self.CooldownRemaining = Constants.DASH_COOLDOWN
        
        -- Recharge charge after cooldown
        task.delay(Constants.DASH_COOLDOWN, function()
            if self.Charges < self.MaxCharges then
                self.Charges = self.Charges + 1
            end
        end)
    end)
end

function Dash:GetCurrentInputDirection()
    -- Check which WASD keys are currently held, convert to camera-relative
    local inputX = 0
    local inputZ = 0
    
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then inputZ = inputZ - 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then inputZ = inputZ + 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then inputX = inputX - 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then inputX = inputX + 1 end
    
    if inputX ~= 0 or inputZ ~= 0 then
        local rawInput = Vector2.new(inputX, inputZ)
        return self.CameraCtrl:ConvertToCameraRelative(rawInput)
    end
    
    -- Fallback to last movement direction from character
    if self.Character then
        local humanoid = self.Character:FindFirstChild("Humanoid")
        if humanoid then
            local moveDir = humanoid.MoveDirection
            if moveDir.Magnitude > 0 then
                return moveDir.Unit
            end
        end
    end
    
    -- Final fallback: use facing direction
    if self.RootPart then
        local lookDir = self.RootPart.CFrame.LookVector
        return Vector3.new(lookDir.X, 0, lookDir.Z).Unit
    end
    
    return Vector3.new(1, 0, 0) -- Absolute fallback
end

function Dash:SpawnDashEffect(rootPart)
    -- Create trail effect
    local attachment0 = Instance.new("Attachment")
    attachment0.Position = Vector3.new(0, 0, -0.5)
    attachment0.Parent = rootPart
    
    local attachment1 = Instance.new("Attachment")
    attachment1.Position = Vector3.new(0, 0, 0.5)
    attachment1.Parent = rootPart
    
    local trail = Instance.new("Trail")
    trail.Attachment0 = attachment0
    trail.Attachment1 = attachment1
    trail.Lifetime = 0.3
    trail.FaceCamera = true
    trail.LightEmission = 1
    trail.LightInfluence = 0.5
    
    local colorSequence = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Constants.COLOR_DASH_TRAIL),
        ColorSequenceKeypoint.new(1, Constants.COLOR_DASH_TRAIL:lerp(Color3.new(1, 1, 1), 0.5))
    })
    trail.Color = colorSequence
    
    local transparencySequence = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.5, 0.3),
        NumberSequenceKeypoint.new(1, 1)
    })
    trail.Transparency = transparencySequence
    
    trail.WidthScale = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0)
    })
    
    trail.Parent = rootPart
    
    -- Clean up
    task.delay(Constants.DASH_DURATION + 0.5, function()
        if trail then trail:Destroy() end
        if attachment0 then attachment0:Destroy() end
        if attachment1 then attachment1:Destroy() end
    end)
end

function Dash:Update(dt)
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
    if self.CameraCtrl then
        self.CameraCtrl:Destroy()
    end
end

return Dash