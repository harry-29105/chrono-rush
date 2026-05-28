--[[
    ChronoRush - Game Manager (Client)
    Main game loop and state management
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

local GameManager = {}
GameManager.__index = GameManager

function GameManager.new()
    local self = setmetatable({}, GameManager)
    
    self.Player = Players.LocalPlayer
    self.Character = nil
    
    -- Game state
    self.IsPlaying = false
    self.IsPaused = false
    
    -- Modules
    self.Movement = nil
    self.Jump = nil
    self.Dash = nil
    self.Combo = nil
    self.ProjectileManager = nil
    
    return self
end

function GameManager:Start()
    -- Wait for character
    self.Player.CharacterAdded:Connect(function(char)
        self:OnCharacterAdded(char)
    end)
    
    -- Check for existing character
    if self.Player.Character then
        self:OnCharacterAdded(self.Player.Character)
    end
    
    -- Listen for game start (from server)
    local remoteEvent = ReplicatedStorage:FindFirstChild("StartGame")
    if remoteEvent then
        remoteEvent.OnClientEvent:Connect(function()
            self:StartGame()
        end)
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
    
    -- Wait for character to fully load
    character.AncestryChanged:Connect(function()
        task.wait(0.5)
        self:InitializeModules()
    end)
    
    self:InitializeModules()
end

function GameManager:InitializeModules()
    if not self.Character then return end
    
    -- Initialize all modules
    self.Movement = Movement.new(self.Character)
    self.Movement:Start()
    
    self.Jump = Jump.new(self.Character)
    self.Jump:Start()
    
    self.Dash = Dash.new(self.Character)
    self.Dash:Start()
    
    self.Combo = Combo.new()
    self.Combo:Start()
    
    self.ProjectileManager = ProjectileManager.new()
    self.ProjectileManager:Start()
    
    -- Auto-start game for immediate testing (remove for production)
    task.delay(1, function()
        self:StartGame()
        print("Game auto-started - have fun dodging!")
    end)
    
    -- Set up hit detection
    self:SetupHitDetection()
end

function GameManager:SetupHitDetection()
    if not self.Character then return end
    
    local humanoid = self.Character:WaitForChild("Humanoid")
    local rootPart = self.Character:WaitForChild("HumanoidRootPart")
    
    -- Listen for taking damage
    humanoid.HealthChanged:Connect(function(newHealth)
        if newHealth < humanoid.MaxHealth then
            self:OnHit()
        end
    end)
    
    -- Projectile collision detection - make it invisible and properly sized
    local hitbox = Instance.new("Part")
    hitbox.Name = "Hitbox"
    hitbox.Size = Vector3.new(4, 4, 4) -- Smaller hitbox
    hitbox.Shape = Enum.PartType.Ball
    hitbox.Anchored = false
    hitbox.CanCollide = false
    hitbox.Transparency = 1 -- Fully invisible
    hitbox.Material = Enum.Material.Plastic
    hitbox.Color = Color3.new(0, 0, 0)
    hitbox.Parent = rootPart
    
    -- Weld to character
    local weld = Instance.new("Weld")
    weld.Part0 = rootPart
    weld.Part1 = hitbox
    weld.Parent = hitbox
    
    -- Touch detection
    local connection
    connection = hitbox.Touched:Connect(function(otherPart)
        if otherPart.Name == "Projectile" then
            self:OnHit()
            otherPart:Destroy()
        end
    end)
end

function GameManager:StartGame()
    self.IsPlaying = true
    
    if self.ProjectileManager then
        self.ProjectileManager:StartGame()
    end
    
    if self.Combo then
        self.Combo:Reset()
    end
    
    -- Notify server
    local remoteEvent = ReplicatedStorage:FindFirstChild("PlayerStartedGame")
    if remoteEvent then
        remoteEvent:FireServer()
    end
end

function GameManager:OnHit()
    if not self.IsPlaying then return end
    
    -- Break combo
    if self.Combo then
        self.Combo:BreakCombo()
    end
    
    -- End game
    self:EndGame()
end

function GameManager:EndGame()
    self.IsPlaying = false
    
    if self.ProjectileManager then
        self.ProjectileManager:StopGame()
    end
    
    -- Send final score to server
    local maxCombo = 0
    if self.Combo then
        maxCombo = self.Combo:GetMaxCombo()
    end
    
    local remoteEvent = ReplicatedStorage:FindFirstChild("PlayerDied")
    if remoteEvent then
        remoteEvent:FireServer(maxCombo)
    end
    
    -- Show game over screen
    self:ShowGameOver(maxCombo)
end

function GameManager:ShowGameOver(combo)
    -- Create simple game over UI
    local playerGui = self.Player:WaitForChild("PlayerGui")
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GameOver"
    screenGui.Parent = playerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.5, 0, 0.3, 0)
    frame.Position = UDim2.new(0.25, 0, 0.35, 0)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.4, 0)
    title.Position = UDim2.new(0, 0, 0.1, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "GAME OVER"
    title.TextColor3 = Color3.fromRGB(255, 100, 100)
    title.TextScaled = true
    title.Parent = frame
    
    local scoreLabel = Instance.new("TextLabel")
    scoreLabel.Size = UDim2.new(1, 0, 0.3, 0)
    scoreLabel.Position = UDim2.new(0, 0, 0.4, 0)
    scoreLabel.BackgroundTransparency = 1
    scoreLabel.Font = Enum.Font.GothamMedium
    scoreLabel.Text = "Max Combo: " .. tostring(combo)
    scoreLabel.TextColor3 = Color3.fromRGB(100, 255, 200)
    scoreLabel.TextScaled = true
    scoreLabel.Parent = frame
    
    local restartBtn = Instance.new("TextButton")
    restartBtn.Size = UDim2.new(0.6, 0, 0.2, 0)
    restartBtn.Position = UDim2.new(0.2, 0, 0.7, 0)
    restartBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 150)
    restartBtn.BorderSizePixel = 0
    restartBtn.Font = Enum.Font.GothamBold
    restartBtn.Text = "RESTART"
    restartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    restartBtn.TextScaled = true
    restartBtn.Parent = frame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 10)
    btnCorner.Parent = restartBtn
    
    restartBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
        self:StartGame()
    end)
end

function GameManager:TogglePause()
    self.IsPaused = not self.IsPaused
    -- TODO: Implement pause menu
end

return GameManager