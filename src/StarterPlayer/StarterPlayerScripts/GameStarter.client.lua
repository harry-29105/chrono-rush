--[[
    ChronoRush - GameStarter
    Entry point that runs when the game starts
    Must be a LocalScript in StarterPlayerScripts to execute automatically
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("===========================================")
print("ChronoRush - Game Starting...")
print("===========================================")

-- Wait for character to load
local player = Players.LocalPlayer
repeat task.wait() until player.Character

print("Player character loaded!")

-- Wait for ChronoRush module to be available
local chronorush = ReplicatedStorage:WaitForChild("ChronoRush", 10)
if not chronorush then
    warn("ChronoRush module not found in ReplicatedStorage!")
    return
end

print("ChronoRush module found!")

-- Wait for Client folder
local client = chronorush:WaitForChild("Client", 10)
if not client then
    warn("ChronoRush Client folder not found!")
    return
end

print("Client folder found!")

-- Require GameManager
local gameManagerModule = client:WaitForChild("GameManager", 10)
if not gameManagerModule then
    warn("GameManager not found!")
    return
end

print("GameManager found, initializing...")

-- Create and start game manager
local GameManager = require(gameManagerModule)
local game = GameManager.new()
game:Start()

print("===========================================")
print("ChronoRush is LIVE! Good luck!")
print("===========================================")