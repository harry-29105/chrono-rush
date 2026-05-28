--[[
    ChronoRush - Jump Module
    Handles double jump with air control
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Constants = require(script.Parent.Parent.Shared.Constants)

local Jump = {}
Jump.__index = Jump

function Jump.new(character)
    local self = setmetatable({}, Jump)
    
    self.Character = character
    self.Humanoid = character:WaitForChild("Humanoid")
    self.RootPart = character:WaitForChild("HumanoidRootPart")
    
    -- Jump state
    self.JumpsRemaining = Constants.MAX_JUMPS
    self.IsGrounded = true
    self.JumpBufferTimer = 0
    
    -- Tracks if we've used ground jump
    self.HasUsedGroundJump = false
    
    return self
end

function Jump:Start()
    local humanoid = self.Humanoid
    
    -- Track ground state changes
    humanoid.StateChanged:Connect(function(oldState, newState)
        self:OnStateChanged(oldState, newState)
    end)
    
    -- Initial ground check
    self:CheckGrounded()
    
    -- Listen for jump input
    local player = Players.LocalPlayer
    local UserInputService = game:GetService("UserInputService")
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Space then
            self:Jump()
        end
    end)
    
    -- Update loop for jump buffering
    self.Connection = RunService.Heartbeat:Connect(function(dt)
        self:Update(dt)
    end)
end

function Jump:CheckGrounded()
    local humanoid = self.Humanoid
    local state = humanoid:GetState()
    
    local grounded = (state == Enum.HumanoidStateType.Running) or 
                     (state == Enum.HumanoidStateType.RunningNoPhysics)
    
    if grounded and not self.IsGrounded then
        -- Just landed
        self:OnLand()
    end
    
    self.IsGrounded = grounded
    return grounded
end

function Jump:OnStateChanged(oldState, newState)
    self:CheckGrounded()
end

function Jump:OnLand()
    -- Reset jumps when landing
    self.JumpsRemaining = Constants.MAX_JUMPS
    self.HasUsedGroundJump = false
    
    -- Apply jump buffer if player pressed jump before landing
    if self.JumpBufferTimer > 0 then
        self:ExecuteJump()
        self.JumpBufferTimer = 0
    end
end

function Jump:Jump()
    -- Buffer the jump for a short time
    self.JumpBufferTimer = Constants.JUMP_BUFFER_TIME
    
    -- Execute if can jump now
    if self:CanJump() then
        self:ExecuteJump()
    end
end

function Jump:CanJump()
    local grounded = self:CheckGrounded()
    
    if grounded then
        return true
    elseif self.JumpsRemaining > 0 and not self.HasUsedGroundJump then
        -- Allow double jump only once per ground touch
        return true
    end
    
    return false
end

function Jump:ExecuteJump()
    local humanoid = self.Humanoid
    local grounded = self:CheckGrounded()
    
    -- Determine jump power
    local jumpPower = Constants.JUMP_FORCE
    
    if not grounded then
        -- Double jump!
        jumpPower = Constants.DOUBLE_JUMP_FORCE
        
        -- Consume a jump
        if not self.HasUsedGroundJump then
            self.HasUsedGroundJump = true
        else
            self.JumpsRemaining = self.JumpsRemaining - 1
        end
        
        -- Fire event for effects (dash trail, particles, etc.)
        self:OnDoubleJump()
    end
    
    -- Apply jump
    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    
    -- Give upward velocity
    if self.RootPart then
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
        bodyVelocity.Velocity = Vector3.new(0, jumpPower, 0)
        bodyVelocity.Parent = self.RootPart
        
        -- Remove after small delay
        task.delay(0.1, function()
            if bodyVelocity and bodyVelocity.Parent then
                bodyVelocity:Destroy()
            end
        end)
    end
end

function Jump:OnDoubleJump()
    -- Override this in extending modules for effects
    -- e.g., spawn particle trail, play sound
end

function Jump:Update(dt)
    -- Handle jump buffer timer
    if self.JumpBufferTimer > 0 then
        self.JumpBufferTimer = self.JumpBufferTimer - dt
        
        -- If we landed while buffer active, execute
        if self:CheckGrounded() and self.JumpBufferTimer > 0 then
            self:ExecuteJump()
            self.JumpBufferTimer = 0
        end
    end
end

function Jump:Destroy()
    if self.Connection then
        self.Connection:Disconnect()
    end
end

return Jump