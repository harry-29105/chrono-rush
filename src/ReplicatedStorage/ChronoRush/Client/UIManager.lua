--[[
    ChronoRush - UI Manager
    Displays level info, wave status, and game messages
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
    self.WaveLabel = nil
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
    
    -- Level indicator (top center)
    self.LevelLabel = self:CreateLabel("Level 1", UDim2.new(0.5, 0, 0.05, 0), 48, Color3.fromRGB(100, 255, 200))
    
    -- Wave indicator (below level)
    self.WaveLabel = self:CreateLabel("Wave 0/3", UDim2.new(0.5, 0, 0.12, 0), 32, Color3.fromRGB(255, 255, 255))
    
    -- Timer (top right)
    self.TimerLabel = self:CreateLabel("", UDim2.new(0.9, 0, 0.05, 0), 28, Color3.fromRGB(255, 200, 100))
    
    -- Message display (center)
    self.MessageLabel = self:CreateLabel("", UDim2.new(0.5, 0, 0.4, 0), 56, Color3.fromRGB(255, 255, 255))
    self.MessageLabel.BackgroundTransparency = 0.5
    self.MessageLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = self.MessageLabel
    
    self.MessageLabel.TextTransparency = 1
    self.MessageLabel.BackgroundTransparency = 1
end

function UI:CreateLabel(text, position, textSize, textColor)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 300, 0, 60)
    label.Position = position
    label.AnchorPoint = Vector2.new(0.5, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = textColor
    label.TextSize = textSize
    label.TextScaled = false
    label.Parent = self.ScreenGui
    
    return label
end

function UI:UpdateLevel(level, totalLevels)
    self.LevelLabel.Text = "Level " .. tostring(level) .. "/" .. tostring(totalLevels)
end

function UI:UpdateWave(current, total)
    self.WaveLabel.Text = "Wave " .. tostring(current) .. "/" .. tostring(total)
end

function UI:UpdateTimer(seconds)
    if seconds <= 0 then
        self.TimerLabel.Text = ""
    else
        self.TimerLabel.Text = string.format("%.1f", seconds) .. "s"
    end
end

function UI:ShowMessage(text, duration, color)
    color = color or Color3.fromRGB(255, 255, 255)
    
    self.MessageLabel.Text = text
    self.MessageLabel.TextColor3 = color
    self.MessageLabel.TextTransparency = 0
    self.MessageLabel.BackgroundTransparency = 0.3
    
    -- Fade out
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

function UI:ShowLevelStart(level)
    self:ShowMessage("Level " .. tostring(level), 2, Color3.fromRGB(100, 255, 200))
end

function UI:ShowWaveStart(wave, total)
    self:ShowMessage("Wave " .. tostring(wave), 1.5, Color3.fromRGB(255, 200, 100))
end

function UI:ShowLevelComplete(level)
    self:ShowMessage("Level " .. tostring(level) .. " Complete!", 3, Color3.fromRGB(100, 255, 100))
end

function UI:ShowGameComplete()
    self:ShowMessage("🎉 VICTORY! 🎉\nAll levels complete!", 5, Color3.fromRGB(255, 215, 0))
end

function UI:ShowGameOver(level)
    self:ShowMessage("💀 Hit! 💀\nRetry Level " .. tostring(level), 2, Color3.fromRGB(255, 100, 100))
end

function UI:Destroy()
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

return UI