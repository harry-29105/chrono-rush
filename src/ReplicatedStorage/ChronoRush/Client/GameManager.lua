--[[
    ChronoRush - Game Manager (Client)
    Main game loop, state management, and module coordination
    
    Wave Survival Game Mode:
    - 10 levels with 3-6 waves each
    - Survive all waves to complete level
    - Progress to next level on success
    - Retry same level on failure
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ChronoRushClient = ReplicatedStorage:WaitForChild("ChronoRush"):WaitForChild("Client")

local Movement = require(ChronoRushClient:WaitForChild("Movement"))
local Jump = require(ChronoRushClient:WaitForChild("Jump"))
local Dash = require(ChronoRushClient:WaitForChild("Dash"))
local Combo = require(ChronoRushClient:WaitForChild("Combo"))
local ProjectileManager = require(ChronoRushClient:WaitForChild("ProjectileManager"))
local CameraController = require(ChronoRushClient:WaitForChild("CameraController"))
local UIManager = require(ChronoRushClient:WaitForChild("UIManager"))

local GameManager = {}
GameManager.__index = GameManager

function GameManager.new()
    local self = setmetatable({}, GameManager)
    
    self.Player = Players.LocalPlayer
    self.Character = nil
    
    -- Game state
    self.IsPlaying = false
    self.IsPaused = false
    self.IsGameOver = false
    
    -- Modules
    self.Movement = nil
    self.Jump = nil
    self.Dash = nil
    self.Combo = nil
    self.ProjectileManager = nil
    self.CameraController = nil
    self.UI = nil
    
    return self
end

function GameManager:Start()
    -- Wait for character
    self.Player.CharacterAdded:Connect(function(char)
        self:OnCharacterAdded(char)
    end)
    
    if self.Player.Character then
        self:OnCharacterAdded(self.Player.Character)
    end
    
    -- Input handlers
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Escape then
            self:TogglePause()
        end
    end)
end

function GameManager:OnCharacterAdded(character)
    self.Character = character
    
    self:InitializeModules()
end

function GameManager:InitializeModules()
    if not self.Character then return end
    
    -- Create UI first
    self.UI = UIManager.new()
    self.UI:Create()
    
    -- Initialize game modules
    self.Movement = Movement.new(self.Character)
    self.Movement:Start()
    
    self.Jump = Jump.new(self.Character)
    self.Jump:Start()
    
    self.Dash = Dash.new(self.Character)
    self.Dash:Start()
    
    self.Combo = Combo.new()
    self.Combo:Start()
    
    self.CameraController = CameraController.new()
    self.CameraController:Start()
    
    self.ProjectileManager = ProjectileManager.new()
    self.ProjectileManager:Start()
    
    -- Set up hit detection
    self:SetupHitDetection()
    
    -- Set up level callbacks
    self:SetupLevelCallbacks()
    
    -- Start game automatically after brief delay
    task.delay(2, function()
        self:StartGame()
    end)
end

function GameManager:SetupHitDetection()
    if not self.Character then return end
    
    local humanoid = self.Character:WaitForChild("Humanoid")
    local rootPart = self.Character:WaitForChild("HumanoidRootPart")
    
    -- Create invisible hitbox
    local hitbox = Instance.new("Part")
    hitbox.Name = "Hitbox"
    hitbox.Size = Vector3.new(4, 4, 4)
    hitbox.Shape = Enum.PartType.Ball
    hitbox.Anchored = false
    hitbox.CanCollide = false
    hitbox.Transparency = 1
    hitbox.Material = Enum.Material.Plastic
    hitbox.Color = Color3.new(0, 0, 0)
    hitbox.Parent = rootPart
    
    local weld = Instance.new("Weld")
    weld.Part0 = rootPart
    weld.Part1 = hitbox
    weld.Parent = hitbox
    
    -- Touch detection
    hitbox.Touched:Connect(function(otherPart)
        if otherPart.Name == "Projectile" then
            self:OnPlayerHit()
            otherPart:Destroy()
        end
    end)
end

function GameManager:SetupLevelCallbacks()
    if not self.ProjectileManager or not self.ProjectileManager.LevelManager then return end
    
    local lm = self.ProjectileManager.LevelManager
    
    lm.OnLevelStart = function(level)
        self:OnLevelStart(level)
    end
    
    lm.OnWaveStart = function(wave, total)
        self:OnWaveStart(wave, total)
    end
    
    lm.OnWaveEnd = function(wave)
        self:OnWaveEnd(wave)
    end
    
    lm.OnLevelComplete = function(level)
        self:OnLevelComplete(level)
    end
    
    lm.OnLevelFailed = function(level)
        self:OnLevelFailed(level)
    end
    
    lm.OnGameComplete = function()
        self:OnGameComplete()
    end
end

function GameManager:StartGame()
    if self.IsGameOver then return end
    
    self.IsPlaying = true
    
    if self.ProjectileManager then
        self.ProjectileManager:StartGame()
    end
    
    if self.Combo then
        self.Combo:Reset()
    end
    
    print("=== GAME STARTED ===")
    print("Controls: WASD=Move, Space=Jump, Q=Dash, Shift=Camera Lock, Scroll=Zoom")
end

function GameManager:OnLevelStart(level)
    local totalLevels = self.ProjectileManager.LevelManager:GetTotalLevels()
    self.UI:UpdateLevel(level, totalLevels)
    self.UI:ShowLevelStart(level)
end

function GameManager:OnWaveStart(wave, total)
    self.UI:UpdateWave(wave, total)
    self.UI:ShowWaveStart(wave, total)
end

function GameManager:OnWaveEnd(wave)
    -- Show break message
    print("Wave " .. wave .. " cleared! Next wave coming...")
end

function GameManager:OnLevelComplete(level)
    self.UI:ShowLevelComplete(level)
    
    -- Clear combo (survived!)
    if self.Combo then
        self.Combo:BreakCombo()
    end
    
    -- Advance to next level
    task.delay(3, function()
        if self.ProjectileManager and self.ProjectileManager.LevelManager then
            self.ProjectileManager.LevelManager:AdvanceToNextLevel()
        end
    end)
end

function GameManager:OnLevelFailed(level)
    self.UI:ShowGameOver(level)
    
    -- Clear combo
    if self.Combo then
        self.Combo:BreakCombo()
    end
    
    -- End game
    self:EndGame(level)
end

function GameManager:OnGameComplete()
    self.UI:ShowGameComplete()
    
    -- Show victory screen
    self:ShowVictoryScreen()
    
    self.IsPlaying = false
    self.IsGameOver = true
end

function GameManager:OnPlayerHit()
    if not self.IsPlaying then return end
    
    -- Break combo
    if self.Combo then
        self.Combo:BreakCombo()
    end
    
    -- Trigger level failed
    if self.ProjectileManager and self.ProjectileManager.LevelManager then
        self.ProjectileManager.LevelManager:OnPlayerHit()
    end
end

function GameManager:EndGame(failedLevel)
    self.IsPlaying = false
    
    -- Clear projectiles
    if self.ProjectileManager then
        self.ProjectileManager:StopGame()
    end
    
    -- Show game over screen
    self:ShowGameOver(failedLevel or 1)
end

function GameManager:ShowGameOver(failedLevel)
    local playerGui = self.Player:WaitForChild("PlayerGui")
    
    -- Remove existing UI if any
    local existing = playerGui:FindFirstChild("GameOverScreen")
    if existing then existing:Destroy() end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GameOverScreen"
    screenGui.Parent = playerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.4, 0, 0.35, 0)
    frame.Position = UDim2.new(0.3, 0, 0.32, 0)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.35, 0)
    title.Position = UDim2.new(0, 0, 0.1, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "💀 HIT! 💀"
    title.TextColor3 = Color3.fromRGB(255, 80, 80)
    title.TextSize = 48
    title.Parent = frame
    
    local subTitle = Instance.new("TextLabel")
    subTitle.Size = UDim2.new(1, 0, 0.25, 0)
    subTitle.Position = UDim2.new(0, 0, 0.4, 0)
    subTitle.BackgroundTransparency = 1
    subTitle.Font = Enum.Font.GothamMedium
    subTitle.Text = "Failed at Level " .. tostring(failedLevel)
    subTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    subTitle.TextSize = 28
    subTitle.Parent = frame
    
    local restartBtn = Instance.new("TextButton")
    restartBtn.Size = UDim2.new(0.5, 0, 0.15, 0)
    restartBtn.Position = UDim2.new(0.25, 0, 0.7, 0)
    restartBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 150)
    restartBtn.BorderSizePixel = 0
    restartBtn.Font = Enum.Font.GothamBold
    restartBtn.Text = "RETRY"
    restartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    restartBtn.TextSize = 32
    restartBtn.Parent = frame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 10)
    btnCorner.Parent = restartBtn
    
    restartBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
        self:RestartGame()
    end)
end

function GameManager:ShowVictoryScreen()
    local playerGui = self.Player:WaitForChild("PlayerGui")
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "VictoryScreen"
    screenGui.Parent = playerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.5, 0, 0.4, 0)
    frame.Position = UDim2.new(0.25, 0, 0.3, 0)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 20)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.4, 0)
    title.Position = UDim2.new(0, 0, 0.05, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "🎉 VICTORY! 🎉"
    title.TextColor3 = Color3.fromRGB(255, 215, 0)
    title.TextSize = 56
    title.Parent = frame
    
    local subTitle = Instance.new("TextLabel")
    subTitle.Size = UDim2.new(1, 0, 0.3, 0)
    subTitle.Position = UDim2.new(0, 0, 0.4, 0)
    subTitle.BackgroundTransparency = 1
    subTitle.Font = Enum.Font.GothamMedium
    subTitle.Text = "You completed all 10 levels!"
    subTitle.TextColor3 = Color3.fromRGB(200, 255, 200)
    subTitle.TextSize = 32
    subTitle.Parent = frame
    
    local restartBtn = Instance.new("TextButton")
    restartBtn.Size = UDim2.new(0.6, 0, 0.18, 0)
    restartBtn.Position = UDim2.new(0.2, 0, 0.7, 0)
    restartBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
    restartBtn.BorderSizePixel = 0
    restartBtn.Font = Enum.Font.GothamBold
    restartBtn.Text = "PLAY AGAIN"
    restartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    restartBtn.TextSize = 32
    restartBtn.Parent = frame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 10)
    btnCorner.Parent = restartBtn
    
    restartBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
        self:RestartGame()
    end)
end

function GameManager:RestartGame()
    -- Reset game state
    self.IsGameOver = false
    self.IsPlaying = false
    
    -- Clear old UI
    if self.UI then
        self.UI:Destroy()
    end
    
    -- Recreate UI
    self.UI = UIManager.new()
    self.UI:Create()
    
    -- Restart game
    task.delay(1, function()
        self:StartGame()
    end)
end

function GameManager:TogglePause()
    self.IsPaused = not self.IsPaused
    -- TODO: Implement pause menu
end

function GameManager:Destroy()
    if self.ProjectileManager then
        self.ProjectileManager:Destroy()
    end
    if self.UI then
        self.UI:Destroy()
    end
    if self.CameraController then
        self.CameraController:Destroy()
    end
end

return GameManager