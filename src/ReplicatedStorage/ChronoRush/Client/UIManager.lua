--[[
    ChronoRush - UI Manager
    Displays level info, progress bar, and game messages
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local UI = {}
UI.__index = UI

function UI.new()
    local self = setmetatable({}, UI)
    
    self.Player = Players.LocalPlayer
    self.ScreenGui = nil
    self.LevelLabel = nil
    self.ProgressBar = nil
    self.ProgressFill = nil
    self.TimerLabel = nil
    self.MessageLabel = nil
    
    return self
end

function UI:Create()
    -- Create ScreenGui
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "ChronoRushUI"
    self.ScreenGui.ResetOnSpawn = false
    
    local playerGui = self.Player:WaitForChild("PlayerGui")
    self.ScreenGui.Parent = playerGui
    
    -- Level indicator (top left)
    self.LevelLabel = self:CreateLabel("Level 1/10", UDim2.new(0.05, 0, 0.05, 0), 32, Color3.fromRGB(100, 255, 200))
    
    -- Progress bar (top center)
    self:CreateProgressBar()
    
    -- Timer (top right)
    self.TimerLabel = self:CreateLabel("30.0s", UDim2.new(0.9, 0, 0.05, 0), 28, Color3.fromRGB(255, 200, 100))
    self.TimerLabel.AnchorPoint = Vector2.new(1, 0)
    
    -- Token display (below timer)
    self.TokenLabel = self:CreateLabel("Tokens: 0", UDim2.new(0.9, 0, 0.1, 0), 24, Color3.fromRGB(255, 215, 0))
    self.TokenLabel.AnchorPoint = Vector2.new(1, 0)
    
    -- Message display (center)
    self.MessageLabel = self:CreateLabel("", UDim2.new(0.5, 0, 0.35, 0), 48, Color3.fromRGB(255, 255, 255))
    self.MessageLabel.BackgroundTransparency = 0.3
    self.MessageLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = self.MessageLabel
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 20)
    padding.PaddingRight = UDim.new(0, 20)
    padding.Parent = self.MessageLabel
    
    self.MessageLabel.TextTransparency = 1
    self.MessageLabel.BackgroundTransparency = 1
end

function UI:CreateLabel(text, position, textSize, textColor)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 200, 0, 50)
    label.Position = position
    label.AnchorPoint = Vector2.new(0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = textColor
    label.TextSize = textSize
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = self.ScreenGui
    
    return label
end

function UI:CreateProgressBar()
    -- Progress bar background
    local barBg = Instance.new("Frame")
    barBg.Name = "ProgressBar"
    barBg.Size = UDim2.new(0.3, 0, 0.02, 0)
    barBg.Position = UDim2.new(0.35, 0, 0.05, 0)
    barBg.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    barBg.BorderSizePixel = 0
    barBg.Parent = self.ScreenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = barBg
    
    -- Progress fill
    self.ProgressFill = Instance.new("Frame")
    self.ProgressFill.Size = UDim2.new(0, 0, 1, 0)
    self.ProgressFill.BackgroundColor3 = Color3.fromRGB(100, 255, 200)
    self.ProgressFill.BorderSizePixel = 0
    self.ProgressFill.Parent = barBg
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 5)
    fillCorner.Parent = self.ProgressFill
    
    -- Progress label
    local progressLabel = Instance.new("TextLabel")
    progressLabel.Size = UDim2.new(1, 0, 1, 0)
    progressLabel.BackgroundTransparency = 1
    progressLabel.Font = Enum.Font.GothamMedium
    progressLabel.Text = "0%"
    progressLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    progressLabel.TextSize = 16
    progressLabel.Parent = barBg
    
    self.ProgressBar = barBg
    self.ProgressLabel = progressLabel
end

function UI:UpdateLevel(level, totalLevels)
    self.LevelLabel.Text = "Level " .. tostring(level) .. "/" .. tostring(totalLevels)
end

function UI:UpdateProgress(progress)
    progress = math.clamp(progress, 0, 1)
    
    self.ProgressFill.Size = UDim2.new(progress, 0, 1, 0)
    self.ProgressLabel.Text = string.format("%.0f%%", progress * 100)
end

function UI:UpdateTimer(seconds)
    if seconds <= 0 then
        self.TimerLabel.Text = "TIME!"
        self.TimerLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    else
        self.TimerLabel.Text = string.format("%.1fs", math.max(0, seconds))
        self.TimerLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    end
end

function UI:UpdateTokens(tokens)
    self.TokenLabel.Text = "Tokens: " .. tostring(tokens)
end

function UI:ShowMessage(text, duration, color)
    color = color or Color3.fromRGB(255, 255, 255)
    
    self.MessageLabel.Text = text
    self.MessageLabel.TextColor3 = color
    self.MessageLabel.TextTransparency = 0
    self.MessageLabel.BackgroundTransparency = 0.3
    
    task.delay(duration, function()
        self:FadeOutMessage()
    end)
end

function UI:FadeOutMessage()
    local tween = TweenService:Create(
        self.MessageLabel,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad),
        {TextTransparency = 1, BackgroundTransparency = 1}
    )
    tween:Play()
end

function UI:Destroy()
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

return UI