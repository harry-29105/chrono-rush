--[[
    ChronoRush - Jump Module
    Handles double jump with air control
    Blox Fruits-inspired - smooth, higher second jump
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage:WaitForChild("ChronoRush"):WaitForChild("Shared"):WaitForChild("Constants"))

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
    self.LastJumpTime = 0
    
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
    
    -- Listen for jump input using JumpRequest (more responsive)
    local player = Players.LocalPlayer
    
    player.Idled:Connect(function()
        -- Prevents AFK kick but not needed for jumping
    end)
    
    -- Use UserInputService for space key
    local UserInputService = game:GetService("UserInputService")
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Space then
            self:Jump()
        end
    end)
    
    -- Update loop for jump buffering and double jump timing
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
    elseif self.JumpsRemaining > 0 then
        -- Allow double jump
        return true
    end
    
    return false
end

function Jump:ExecuteJump()
    local humanoid = self.Humanoid
    local grounded = self:CheckGrounded()
    
    -- Determine jump power - Blox Fruits style
    local jumpPower = Constants.JUMP_FORCE
    
    if not grounded then
        -- Double jump! Make it stronger and smoother
        jumpPower = Constants.DOUBLE_JUMP_FORCE * 1.3 -- Boost the double jump
        
        -- Consume a jump
        self.JumpsRemaining = self.JumpsRemaining - 1
        
        -- Fire event for effects
        self:OnDoubleJump()
    end
    
    -- Apply jump immediately
    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    
    -- Give upward velocity with smooth acceleration
    if self.RootPart then
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
        bodyVelocity.Velocity = Vector3.new(0, jumpPower, 0)
        bodyVelocity.Parent = self.RootPart
        
        -- Remove after small delay - gives smooth feel
        task.delay(0.15, function()
            if bodyVelocity and bodyVelocity.Parent then
                bodyVelocity:Destroy()
            end
        end)
    end
    
    self.LastJumpTime = tick()
end

function Jump:OnDoubleJump()
    -- Could spawn particles or play sound here
    print("Double jump!")
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