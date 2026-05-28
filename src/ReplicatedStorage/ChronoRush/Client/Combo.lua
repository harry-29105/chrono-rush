--[[
    ChronoRush - Combo System
    Tracks and displays combo during gameplay
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage:WaitForChild("ChronoRush"):WaitForChild("Shared"):WaitForChild("Constants"))

local Combo = {}
Combo.__index = Combo

function Combo.new()
    local self = setmetatable({}, Combo)
    
    self.Player = Players.LocalPlayer
    self.PlayerGui = self.Player:WaitForChild("PlayerGui")
    
    -- Combo state
    self.CurrentCombo = 0
    self.MaxCombo = 0
    self.IsActive = true
    
    -- UI references
    self.Gui = nil
    self.ComboLabel = nil
    self.ComboText = nil
    
    return self
end

function Combo:Start()
    self:CreateUI()
end

function Combo:CreateUI()
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ChronoRushUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = self.PlayerGui
    
    self.Gui = screenGui
    
    -- Combo counter (top center)
    local comboFrame = Instance.new("Frame")
    comboFrame.Name = "ComboFrame"
    comboFrame.Size = UDim2.new(0, 300, 0, 100)
    comboFrame.Position = UDim2.new(0.5, -150, 0, 0.1)
    comboFrame.BackgroundTransparency = 1
    comboFrame.Parent = screenGui
    
    -- Combo number
    local comboLabel = Instance.new("TextLabel")
    comboLabel.Name = "ComboLabel"
    comboLabel.Size = UDim2.new(1, 0, 0.6, 0)
    comboLabel.Position = UDim2.new(0, 0, 0, 0)
    comboLabel.BackgroundTransparency = 1
    comboLabel.Font = Enum.Font.GothamBold
    comboLabel.Text = "0"
    comboLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    comboLabel.TextScaled = true
    comboLabel.TextStrokeTransparency = 0.5
    comboLabel.Parent = comboFrame
    
    self.ComboLabel = comboLabel
    
    -- "COMBO" text below
    local comboText = Instance.new("TextLabel")
    comboText.Name = "ComboText"
    comboText.Size = UDim2.new(1, 0, 0.4, 0)
    comboText.Position = UDim2.new(0, 0, 0.6, 0)
    comboText.BackgroundTransparency = 1
    comboText.Font = Enum.Font.GothamMedium
    comboText.Text = "COMBO"
    comboText.TextColor3 = Color3.fromRGB(100, 255, 200)
    comboText.TextScaled = true
    comboText.TextTransparency = 0.3
    comboText.Parent = comboFrame
    
    self.ComboText = comboText
end

function Combo:AddHit()
    -- Increment combo on successful dodge
    self.CurrentCombo = self.CurrentCombo + 1
    self.MaxCombo = math.max(self.MaxCombo, self.CurrentCombo)
    
    self:UpdateDisplay()
    self:AnimateCombo()
end

function Combo:BreakCombo()
    -- Combo broken on hit
    self.CurrentCombo = 0
    self:UpdateDisplay()
end

function Combo:UpdateDisplay()
    if not self.ComboLabel then return end
    
    -- Update text
    self.ComboLabel.Text = tostring(self.CurrentCombo)
    
    -- Color based on combo level
    local hue = math.clamp(self.CurrentCombo / 50, 0, 0.3) -- Blue to cyan to green
    local color = Color3.fromHSV(0.5 - hue, 0.8, 1)
    self.ComboLabel.TextColor3 = color
end

function Combo:AnimateCombo()
    if not self.ComboLabel then return end
    
    -- Pop animation on combo increase
    local tween = TweenService:Create(
        self.ComboLabel,
        TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {TextSize = 72}
    )
    tween:Play()
    
    task.delay(0.1, function()
        if self.ComboLabel then
            self.ComboLabel.TextSize = 60
        end
    end)
end

function Combo:GetCombo()
    return self.CurrentCombo
end

function Combo:GetMaxCombo()
    return self.MaxCombo
end

function Combo:Reset()
    self.CurrentCombo = 0
    self.MaxCombo = 0
    self:UpdateDisplay()
end

function Combo:Destroy()
    if self.Gui then
        self.Gui:Destroy()
    end
end

return Combo