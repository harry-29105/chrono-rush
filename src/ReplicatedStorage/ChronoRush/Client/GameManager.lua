--[[
    ChronoRush - Game Manager (Corridor Runner)
    Main game loop with original camera-relative movement
    
    Game concept:
    - Original WASD movement (camera-relative)
    - Map has walls on sides, straight corridor path
    - Projectiles fly from ahead, player moves freely
    - Reach finish line (Z position) to complete level
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
    self.IsGameOver = false
    
    -- Modules
    self.Movement = nil
    self.Jump = nil
    self.Dash = nil
    self.Combo = nil
    self.ProjectileManager = nil
    self.CameraController = nil
    self.UI = nil
    
    -- Level state
    self.StartZ = 0
    self.FinishZ = 100
    
    return self
end

function GameManager:Start()
    self.Player.CharacterAdded:Connect(function(char)
        self:OnCharacterAdded(char)
    end)
    
    if self.Player.Character then
        self:OnCharacterAdded(self.Player.Character)
    end
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.Escape then
            self:TogglePause()
        end
    end)
end

function GameManager:OnCharacterAdded(character)
    self.Character = character
    
    -- Store starting Z position
    task.wait(0.5)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        self.StartZ = rootPart.Position.Z
    end
    
    self:InitializeModules()
end

function GameManager:InitializeModules()
    if not self.Character then return end
    
    -- Create UI
    self.UI = UIManager.new()
    self.UI:Create()
    
    -- Movement (original camera-relative)
    self.Movement = Movement.new(self.Character)
    self.Movement:Start()
    
    -- Jump
    self.Jump = Jump.new(self.Character)
    self.Jump:Start()
    
    -- Dash
    self.Dash = Dash.new(self.Character)
    self.Dash:Start()
    
    -- Combo
    self.Combo = Combo.new()
    self.Combo:Start()
    
    -- Camera Controller
    self.CameraController = CameraController.new()
    self.CameraController:Start()
    
    -- Projectile Manager
    self.ProjectileManager = ProjectileManager.new()
    self.ProjectileManager:Start()
    
    -- Set up level callbacks
    self:SetupLevelCallbacks()
    
    -- Hit detection
    self:SetupHitDetection()
    
    -- Start game after delay
    task.delay(2, function()
        self:StartGame()
    end)
end

function GameManager:SetupLevelCallbacks()
    if not self.ProjectileManager or not self.ProjectileManager.LevelManager then return end
    
    local lm = self.ProjectileManager.LevelManager
    
    lm.OnLevelStart = function(level, config)
        self:OnLevelStart(level, config)
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
    
    lm.OnProgress = function(playerZ, levelLength)
        self:OnProgress(playerZ, levelLength)
    end
end

function GameManager:SetupHitDetection()
    if not self.Character then return end
    
    local rootPart = self.Character:WaitForChild("HumanoidRootPart")
    
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
    
    hitbox.Touched:Connect(function(otherPart)
        if otherPart.Name == "Projectile" then
            self:OnPlayerHit()
            otherPart:Destroy()
        end
    end)
end

function GameManager:StartGame()
    if self.IsGameOver then return end
    
    self.IsPlaying = true
    
    -- Set finish Z based on start position
    local rootPart = self.Character and self.Character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        self.StartZ = rootPart.Position.Z
    end
    
    if self.ProjectileManager then
        self.ProjectileManager:StartGame()
    end
    
    print("=== GAME STARTED ===")
    print("Controls: WASD=Move (camera-relative), Space=Jump, Q=Dash")
    print("Goal: Reach the finish line!")
end

function GameManager:OnLevelStart(level, config)
    local totalLevels = self.ProjectileManager.LevelManager:GetTotalLevels()
    self.UI:UpdateLevel(level, totalLevels)
    self.UI:ShowMessage("Level " .. level .. "\nRun to finish!", 2, Color3.fromRGB(100, 255, 200))
    self.UI:UpdateProgress(0)
    
    -- Set finish line Z position
    local rootPart = self.Character and self.Character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        self.StartZ = rootPart.Position.Z
        self.FinishZ = self.StartZ + config.length
    end
    
    -- Update projectile manager with positions
    if self.ProjectileManager then
        self.ProjectileManager:SetLevelBounds(self.StartZ, self.FinishZ)
    end
    
    -- Set camera zoom
    self.Player.CameraMinZoomDistance = 15
    self.Player.CameraMaxZoomDistance = 50
end

function GameManager:OnProgress(playerZ, levelLength)
    -- Calculate progress based on Z position
    local progress = math.clamp((playerZ - self.StartZ) / levelLength, 0, 1)
    self.UI:UpdateProgress(progress)
    
    -- Update timer
    if self.ProjectileManager and self.ProjectileManager.LevelManager then
        local timeRemaining = self.ProjectileManager.LevelManager:GetTimeRemaining()
        self.UI:UpdateTimer(timeRemaining)
    end
    
    -- Check if reached finish
    if playerZ >= self.FinishZ and self.IsPlaying then
        self:OnReachFinish()
    end
end

function GameManager:OnReachFinish()
    if not self.IsPlaying then return end
    
    -- Level complete!
    if self.ProjectileManager and self.ProjectileManager.LevelManager then
        self.ProjectileManager.LevelManager:LevelComplete()
    end
end

function GameManager:OnLevelComplete(level)
    self.UI:ShowMessage("Level " .. level .. " Complete!", 2, Color3.fromRGB(100, 255, 100))
    
    if self.Combo then
        self.Combo:BreakCombo()
    end
    
    if self.ProjectileManager then
        self.ProjectileManager:ClearAllProjectiles()
    end
    
    task.delay(3, function()
        if self.ProjectileManager and self.ProjectileManager.LevelManager then
            self.ProjectileManager.LevelManager:AdvanceToNextLevel()
        end
    end)
end

function GameManager:OnLevelFailed(level)
    self.UI:ShowMessage("Hit! Try Again", 2, Color3.fromRGB(255, 100, 100))
    
    if self.Combo then
        self.Combo:BreakCombo()
    end
    
    self:EndGame(level)
end

function GameManager:OnGameComplete()
    self.UI:ShowMessage("🎉 VICTORY! 🎉\nAll levels complete!", 4, Color3.fromRGB(255, 215, 0))
    
    self:ShowVictoryScreen()
    
    self.IsPlaying = false
    self.IsGameOver = true
end

function GameManager:OnPlayerHit()
    if not self.IsPlaying then return end
    
    if self.Combo then
        self.Combo:BreakCombo()
    end
    
    if self.ProjectileManager and self.ProjectileManager.LevelManager then
        self.ProjectileManager.LevelManager:LevelFailed()
    end
end

function GameManager:EndGame(failedLevel)
    self.IsPlaying = false
    
    if self.ProjectileManager then
        self.ProjectileManager:StopGame()
    end
    
    self:ShowGameOver(failedLevel or 1)
end

function GameManager:ShowGameOver(level)
    local playerGui = self.Player:WaitForChild("PlayerGui")
    
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
    subTitle.Text = "Failed at Level " .. tostring(level)
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
    self.IsGameOver = false
    self.IsPlaying = false
    
    if self.UI then
        self.UI:Destroy()
    end
    self.UI = UIManager.new()
    self.UI:Create()
    
    task.delay(1, function()
        self:StartGame()
    end)
end

function GameManager:TogglePause()
    -- TODO
end

function GameManager:Destroy()
    if self.ProjectileManager then
        self.ProjectileManager:Destroy()
    end
    if self.UI then
        self.UI:Destroy()
    end
    if self.Movement then
        self.Movement:Destroy()
    end
    if self.CameraController then
        self.CameraController:Destroy()
    end
end

return GameManager