--[[
    ChronoRush - Game Manager (Obstacle Course)
    Main game loop with lava floor obstacle, tokens, and equipment
    
    Game Flow:
    1. Start at beginning of obstacle course
    2. Complete obstacle to reach checkpoint
    3. Earn tokens from checkpoint
    4. Use tokens to buy equipment
    5. Equipment boosts speed when used
    6. Reach finish to complete level
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ChronoRushClient = ReplicatedStorage:WaitForChild("ChronoRush"):WaitForChild("Client")

local Movement = require(ChronoRushClient:WaitForChild("Movement"))
local Jump = require(ChronoRushClient:WaitForChild("Jump"))
local Dash = require(ChronoRushClient:WaitForChild("Dash"))
local Combo = require(ChronoRushClient:WaitForChild("Combo"))
local CameraController = require(ChronoRushClient:WaitForChild("CameraController"))
local UIManager = require(ChronoRushClient:WaitForChild("UIManager"))
local TokenManager = require(ChronoRushClient:WaitForChild("TokenManager"))
local EquipmentShop = require(ChronoRushClient:WaitForChild("EquipmentShop"))
local ObstacleManager = require(ChronoRushClient:WaitForChild("ObstacleManager"))

local GameManager = {}
GameManager.__index = GameManager

function GameManager.new()
    local self = setmetatable({}, GameManager)
    
    self.Player = Players.LocalPlayer
    self.Character = nil
    
    -- Game state
    self.IsPlaying = false
    self.IsGameOver = false
    self.CurrentLevel = 1
    
    -- Modules
    self.Movement = nil
    self.Jump = nil
    self.Dash = nil
    self.Combo = nil
    self.CameraController = nil
    self.UI = nil
    self.TokenManager = nil
    self.EquipmentShop = nil
    self.ObstacleManager = nil
    
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
    
    -- Open shop key
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.P then
            self:ToggleShop()
        end
    end)
end

function GameManager:OnCharacterAdded(character)
    self.Character = character
    
    -- Get starting position
    task.wait(0.5)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        self.StartZ = rootPart.Position.Z
    end
    
    self:InitializeModules()
end

function GameManager:InitializeModules()
    if not self.Character then return end
    
    -- Create UI first
    self.UI = UIManager.new()
    self.UI:Create()
    
    -- Token Manager
    self.TokenManager = TokenManager.new()
    self.TokenManager:Start()
    
    -- Update UI with token display
    self.UI:UpdateTokens(self.TokenManager:GetTokens())
    
    -- Equipment Shop
    self.EquipmentShop = EquipmentShop.new(self.TokenManager)
    self.EquipmentShop:Start()
    
    -- Equipment callbacks
    self.EquipmentShop.OnTokensChanged = function(tokens, lifetime)
        self.UI:UpdateTokens(tokens)
    end
    
    -- Movement
    self.Movement = Movement.new(self.Character)
    self.Movement:Start()
    
    -- Jump
    self.Jump = Jump.new(self.Character)
    self.Jump:Start()
    
    -- Dash
    self.Dash = Dash.new(self.Character)
    self.Dash:Start()
    
    -- Camera Controller
    self.CameraController = CameraController.new()
    self.CameraController:Start()
    
    -- Obstacle Manager
    self.ObstacleManager = ObstacleManager.new()
    self.ObstacleManager:SetCharacter(self.Character)
    self.ObstacleManager:Start()
    
    -- Obstacle callbacks
    self.ObstacleManager.OnObstacleComplete = function(obstacleType)
        self:OnObstacleComplete(obstacleType)
    end
    
    self.ObstacleManager.OnObstacleFailed = function(obstacleType)
        self:OnObstacleFailed(obstacleType)
    end
    
    -- Start game
    task.delay(2, function()
        self:StartGame()
    end)
end

function GameManager:StartGame()
    if self.IsGameOver then return end
    
    self.IsPlaying = true
    
    -- Set level finish position
    local rootPart = self.Character and self.Character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        self.StartZ = rootPart.Position.Z
        self.FinishZ = self.StartZ + 100 -- Level length
    end
    
    -- Start lava floor obstacle
    self:StartLevelObstacle()
    
    -- Update UI
    self.UI:ShowMessage("Level 1\nLava Floor - Jump to survive!", 3, Color3.fromRGB(255, 100, 50))
    
    print("=== GAME STARTED ===")
    print("Press P to open shop | WASD=Move | Space=Jump | Q=Dash")
end

function GameManager:StartLevelObstacle()
    -- Define lava floor obstacle
    local startZ = self.StartZ
    local endZ = self.StartZ + 80
    
    -- Platform positions (jumping stones)
    local platforms = {
        Vector3.new(0, 2, startZ + 15),    -- First jump
        Vector3.new(5, 3, startZ + 30),    -- Second jump
        Vector3.new(-5, 4, startZ + 45),    -- Third jump
        Vector3.new(0, 5, startZ + 60),    -- Fourth jump
        Vector3.new(3, 5, endZ - 10),      -- Final platform before checkpoint
    }
    
    -- Start lava floor obstacle
    self.ObstacleManager:StartLavaFloor(startZ, endZ, platforms)
    
    -- Set finish position (after checkpoint)
    self.FinishZ = endZ + 30
end

function GameManager:OnObstacleComplete(obstacleType)
    -- Award tokens (reduced for monetization)
    local tokenReward = 10 -- Checkpoint reward
    self.TokenManager:AddTokens(tokenReward)
    self.UI:UpdateTokens(self.TokenManager:GetTokens())
    
    -- Show reward message
    self.UI:ShowMessage("Checkpoint! +" .. tokenReward .. " tokens", 3, Color3.fromRGB(255, 215, 0))
    
    -- Break combo (survived!)
    if self.Combo then
        self.Combo:BreakCombo()
    end
    
    -- Check if level complete (reached finish)
    self:CheckLevelComplete()
end

function GameManager:OnObstacleFailed(obstacleType)
    -- Player died in obstacle
    self:EndGame("Level 1 Failed")
end

function GameManager:CheckLevelComplete()
    local rootPart = self.Character and self.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    if rootPart.Position.Z >= self.FinishZ then
        self:CompleteLevel()
    end
end

function GameManager:CompleteLevel()
    self.UI:ShowMessage("Level 1 Complete! +25 tokens", 4, Color3.fromRGB(100, 255, 100))
    self.TokenManager:AddTokens(25)
    
    -- Show victory for now (can expand later)
    task.delay(4, function()
        self:ShowVictoryScreen()
    end)
end

function GameManager:EndGame(message)
    self.IsPlaying = false
    
    if self.ObstacleManager then
        self.ObstacleManager:StopObstacle()
    end
    
    self:ShowGameOver(message)
end

function GameManager:ShowGameOver(message)
    local playerGui = self.Player:WaitForChild("PlayerGui")
    
    local existing = playerGui:FindFirstChild("GameOverScreen")
    if existing then existing:Destroy() end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GameOverScreen"
    screenGui.Parent = playerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.4, 0, 0.4, 0)
    frame.Position = UDim2.new(0.3, 0, 0.3, 0)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.3, 0)
    title.Position = UDim2.new(0, 0, 0.1, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "💀 " .. (message or "GAME OVER") .. " 💀"
    title.TextColor3 = Color3.fromRGB(255, 80, 80)
    title.TextSize = 42
    title.Parent = frame
    
    local tokenInfo = Instance.new("TextLabel")
    tokenInfo.Size = UDim2.new(1, 0, 0.2, 0)
    tokenInfo.Position = UDim2.new(0, 0, 0.4, 0)
    tokenInfo.BackgroundTransparency = 1
    tokenInfo.Font = Enum.Font.GothamMedium
    tokenInfo.Text = "Tokens saved: " .. self.TokenManager:GetLifetimeTokens()
    tokenInfo.TextColor3 = Color3.fromRGB(255, 215, 0)
    tokenInfo.TextSize = 28
    tokenInfo.Parent = frame
    
    local retryBtn = Instance.new("TextButton")
    retryBtn.Size = UDim2.new(0.5, 0, 0.15, 0)
    retryBtn.Position = UDim2.new(0.25, 0, 0.7, 0)
    retryBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 150)
    retryBtn.BorderSizePixel = 0
    retryBtn.Font = Enum.Font.GothamBold
    retryBtn.Text = "RETRY"
    retryBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    retryBtn.TextSize = 32
    retryBtn.Parent = frame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 10)
    btnCorner.Parent = retryBtn
    
    retryBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
        self:RestartGame()
    end)
end

function GameManager:ShowVictoryScreen()
    local playerGui = self.Player:WaitForChild("PlayerGui")
    
    local existing = playerGui:FindFirstChild("VictoryScreen")
    if existing then existing:Destroy() end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "VictoryScreen"
    screenGui.Parent = playerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.5, 0, 0.45, 0)
    frame.Position = UDim2.new(0.25, 0, 0.28, 0)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 20)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.35, 0)
    title.Position = UDim2.new(0, 0, 0.05, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "🎉 LEVEL 1 COMPLETE! 🎉"
    title.TextColor3 = Color3.fromRGB(255, 215, 0)
    title.TextSize = 48
    title.Parent = frame
    
    local tokenInfo = Instance.new("TextLabel")
    tokenInfo.Size = UDim2.new(1, 0, 0.25, 0)
    tokenInfo.Position = UDim2.new(0, 0, 0.35, 0)
    tokenInfo.BackgroundTransparency = 1
    tokenInfo.Font = Enum.Font.GothamMedium
    tokenInfo.Text = "Total Tokens: " .. self.TokenManager:GetLifetimeTokens()
    tokenInfo.TextColor3 = Color3.fromRGB(200, 255, 200)
    tokenInfo.TextSize = 32
    tokenInfo.Parent = frame
    
    local shopBtn = Instance.new("TextButton")
    shopBtn.Size = UDim2.new(0.6, 0, 0.15, 0)
    shopBtn.Position = UDim2.new(0.2, 0, 0.65, 0)
    shopBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
    shopBtn.BorderSizePixel = 0
    shopBtn.Font = Enum.Font.GothamBold
    shopBtn.Text = "OPEN SHOP (P)"
    shopBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    shopBtn.TextSize = 28
    shopBtn.Parent = frame
    
    local shopCorner = Instance.new("UICorner")
    shopCorner.CornerRadius = UDim.new(0, 10)
    shopCorner.Parent = shopBtn
    
    shopBtn.MouseButton1Click:Connect(function()
        self:ToggleShop()
    end)
end

function GameManager:ToggleShop()
    -- Create or show shop UI
    local playerGui = self.Player:WaitForChild("PlayerGui")
    
    local existing = playerGui:FindFirstChild("ShopScreen")
    if existing then
        existing:Destroy()
        return
    end
    
    -- Create shop UI
    self:ShowShopUI(playerGui)
end

function GameManager:ShowShopUI(playerGui)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ShopScreen"
    screenGui.Parent = playerGui
    
    -- Background
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0.5, 0, 0.6, 0)
    bg.Position = UDim2.new(0.25, 0, 0.2, 0)
    bg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    bg.BorderSizePixel = 0
    bg.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = bg
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.15, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "EQUIPMENT SHOP"
    title.TextColor3 = Color3.fromRGB(255, 215, 0)
    title.TextSize = 36
    title.Parent = bg
    
    -- Token display
    local tokenDisplay = Instance.new("TextLabel")
    tokenDisplay.Size = UDim2.new(1, 0, 0.1, 0)
    tokenDisplay.Position = UDim2.new(0, 0, 0.15, 0)
    tokenDisplay.BackgroundTransparency = 1
    tokenDisplay.Font = Enum.Font.GothamMedium
    tokenDisplay.Text = "Your Tokens: " .. self.TokenManager:GetTokens()
    tokenDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
    tokenDisplay.TextSize = 24
    tokenDisplay.Parent = bg
    
    -- Equipment list
    local catalog = self.EquipmentShop:GetCatalog()
    local yPos = 0.28
    
    for i, equipment in ipairs(catalog) do
        local itemFrame = self:CreateShopItem(bg, equipment, yPos)
        yPos = yPos + 0.14
    end
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0.2, 0, 0.08, 0)
    closeBtn.Position = UDim2.new(0.4, 0, 0.9, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    closeBtn.Text = "CLOSE (P)"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 20
    closeBtn.Parent = bg
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
end

function GameManager:CreateShopItem(parent, equipment, yPos)
    local itemFrame = Instance.new("Frame")
    itemFrame.Size = UDim2.new(0.9, 0, 0.12, 0)
    itemFrame.Position = UDim2.new(0.05, 0, yPos, 0)
    itemFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    itemFrame.BorderSizePixel = 0
    itemFrame.Parent = parent
    
    local itemCorner = Instance.new("UICorner")
    itemCorner.CornerRadius = UDim.new(0, 8)
    itemCorner.Parent = itemFrame
    
    -- Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.5, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Text = equipment.name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 20
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = itemFrame
    
    -- Boost amount
    local boostLabel = Instance.new("TextLabel")
    boostLabel.Size = UDim2.new(0.3, 0, 0.5, 0)
    boostLabel.Position = UDim2.new(0.5, 0, 0, 0)
    boostLabel.BackgroundTransparency = 1
    boostLabel.Font = Enum.Font.GothamMedium
    boostLabel.Text = "+" .. (equipment.speedBoost * 100) .. "% speed"
    boostLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    boostLabel.TextSize = 18
    boostLabel.TextXAlignment = Enum.TextXAlignment.Left
    boostLabel.Parent = itemFrame
    
    -- Buy button
    local buyBtn = Instance.new("TextButton")
    buyBtn.Size = UDim2.new(0.2, 0, 0.7, 0)
    buyBtn.Position = UDim2.new(0.75, 0, 0.15, 0)
    buyBtn.BackgroundColor3 = self.EquipmentShop:IsOwned(equipment.id) and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(255, 200, 50)
    buyBtn.Text = self.EquipmentShop:IsOwned(equipment.id) and "OWNED" or (equipment.tokenCost .. " tokens")
    buyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    buyBtn.TextSize = 16
    buyBtn.Parent = itemFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = buyBtn
    
    -- Button click
    buyBtn.MouseButton1Click:Connect(function()
        if not self.EquipmentShop:IsOwned(equipment.id) then
            local success = self.EquipmentShop:PurchaseEquipment(equipment.id)
            if success then
                self.UI:UpdateTokens(self.TokenManager:GetTokens())
                -- Refresh shop
                self:ToggleShop()
            else
                print("Not enough tokens!")
            end
        end
    end)
    
    return itemFrame
end

function GameManager:RestartGame()
    self.IsGameOver = false
    self.IsPlaying = false
    
    if self.UI then
        self.UI:Destroy()
    end
    self.UI = UIManager.new()
    self.UI:Create()
    
    self.UI:UpdateTokens(self.TokenManager:GetTokens())
    
    -- Reinitialize character modules
    if self.ObstacleManager then
        self.ObstacleManager:SetCharacter(self.Character)
    end
    
    task.delay(1, function()
        self:StartGame()
    end)
end

function GameManager:Destroy()
    if self.ObstacleManager then
        self.ObstacleManager:Destroy()
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