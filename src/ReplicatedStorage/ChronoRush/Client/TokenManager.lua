--[[
    ChronoRush - Token Manager
    Handles tokens/currency system
    Tokens earned from checkpoints, spent on equipment
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TokenManager = {}
TokenManager.__index = TokenManager

function TokenManager.new()
    local self = setmetatable({}, TokenManager)
    
    self.Player = Players.LocalPlayer
    self.Tokens = 0
    self.LifetimeTokens = 0 -- Tokens earned total (doesn't reset on fail)
    
    -- Token rewards
    self.CheckpointReward = 50 -- Tokens per checkpoint
    self.LevelCompleteReward = 100 -- Tokens for completing level
    
    return self
end

function TokenManager:Start()
    -- Initialize from player data (if exists)
    -- For now, start with 0 tokens
    print("Token Manager started - Tokens: " .. self.Tokens)
end

function TokenManager:AddTokens(amount)
    self.Tokens = self.Tokens + amount
    self.LifetimeTokens = self.LifetimeTokens + amount
    
    print("+" .. amount .. " tokens! Total: " .. self.Tokens)
    
    -- Update UI if exists
    if self.OnTokensChanged then
        self.OnTokensChanged(self.Tokens, self.LifetimeTokens)
    end
    
    return self.Tokens
end

function TokenManager:SpendTokens(amount)
    if self.Tokens >= amount then
        self.Tokens = self.Tokens - amount
        print("-" .. amount .. " tokens. Remaining: " .. self.Tokens)
        
        if self.OnTokensChanged then
            self.OnTokensChanged(self.Tokens, self.LifetimeTokens)
        end
        
        return true
    else
        print("Not enough tokens! Need " .. amount .. ", have " .. self.Tokens)
        return false
    end
end

function TokenManager:GetTokens()
    return self.Tokens
end

function TokenManager:GetLifetimeTokens()
    return self.LifetimeTokens
end

function TokenManager:ResetForNewGame()
    -- Reset current tokens but keep lifetime tokens
    -- (tokens persist even if you fail)
    self.Tokens = 0
    print("Tokens reset for new game attempt. Lifetime: " .. self.LifetimeTokens)
end

return TokenManager