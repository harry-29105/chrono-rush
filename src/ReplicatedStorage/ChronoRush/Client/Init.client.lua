--[[
    ChronoRush - Client Entry Point
    Initializes all client-side systems
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for game to be ready
task.wait(1)

-- Initialize Game Manager
local GameManager = require(script.GameManager)

local gameManager = GameManager.new()
gameManager:Start()

-- Show start UI
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local startGui = Instance.new("ScreenGui")
startGui.Name = "StartUI"
startGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.4, 0, 0.4, 0)
frame.Position = UDim2.new(0.3, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
frame.BorderSizePixel = 0
frame.Parent = startGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 25)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0.3, 0)
title.Position = UDim2.new(0, 0, 0.1, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "CHRONO RUSH"
title.TextColor3 = Color3.fromRGB(100, 255, 200)
title.TextScaled = true
title.Parent = frame

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, 0, 0.2, 0)
subtitle.Position = UDim2.new(0, 0, 0.35, 0)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.GothamMedium
subtitle.Text = "Dodge projectiles. Build combos. Beat your best."
subtitle.TextColor3 = Color3.fromRGB(150, 150, 170)
subtitle.TextScaled = true
subtitle.Parent = frame

local controlsLabel = Instance.new("TextLabel")
controlsLabel.Size = UDim2.new(0.8, 0, 0.15, 0)
controlsLabel.Position = UDim2.new(0.1, 0, 0.5, 0)
controlsLabel.BackgroundTransparency = 1
controlsLabel.Font = Enum.Font.Gotham
controlsLabel.Text = "WASD - Move\nSPACE - Jump (x2)\nSHIFT - Dash"
controlsLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
controlsLabel.TextScaled = true
controlsLabel.Parent = frame

local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(0.6, 0, 0.15, 0)
startBtn.Position = UDim2.new(0.2, 0, 0.75, 0)
startBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 150)
startBtn.BorderSizePixel = 0
startBtn.Font = Enum.Font.GothamBold
startBtn.Text = "START GAME"
startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
startBtn.TextScaled = true
startBtn.Parent = frame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 10)
btnCorner.Parent = startBtn

startBtn.MouseButton1Click:Connect(function()
    startGui:Destroy()
    
    -- Start the game
    local remoteEvent = ReplicatedStorage:FindFirstChild("StartGame")
    if remoteEvent then
        remoteEvent:FireServer()
    end
    
    -- Also start locally
    gameManager:StartGame()
end)

print("ChronoRush client initialized!")