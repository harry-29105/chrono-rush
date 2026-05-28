--[[
    ChronoRush - Equipment Shop
    Handles equipment purchases and speed boosts
    
    Equipment Types:
    - Treadmill (place in game, stand on to boost speed)
    - Speed Pad
    - Rocket Boosters
    - Teleport Pads
    
    Each equipment has:
    - Name
    - Token cost
    - Speed boost percentage
    - Visual model (to be placed in workspace)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EquipmentShop = {}
EquipmentShop.__index = EquipmentShop

-- Equipment catalog
local EQUIPMENT_CATALOG = {
    {
        id = "basic_treadmill",
        name = "Basic Treadmill",
        description = "Stand on it to boost speed by 5%",
        tokenCost = 100,
        speedBoost = 0.05, -- 5% speed increase
        iconColor = Color3.fromRGB(100, 200, 100)
    },
    {
        id = "advanced_treadmill",
        name = "Advanced Treadmill",
        description = "Stand on it to boost speed by 10%",
        tokenCost = 250,
        speedBoost = 0.10,
        iconColor = Color3.fromRGB(100, 150, 255)
    },
    {
        id = "speed_pad",
        name = "Speed Pad",
        description = "Stand on it to boost speed by 15%",
        tokenCost = 500,
        speedBoost = 0.15,
        iconColor = Color3.fromRGB(255, 200, 100)
    },
    {
        id = "rocket_boosters",
        name = "Rocket Boosters",
        description = "Stand on it to boost speed by 25%",
        tokenCost = 1000,
        speedBoost = 0.25,
        iconColor = Color3.fromRGB(255, 100, 100)
    },
    {
        id = "teleport_pads",
        name = "Teleport Pads",
        description = "Stand on it to boost speed by 30%",
        tokenCost = 2000,
        speedBoost = 0.30,
        iconColor = Color3.fromRGB(200, 100, 255)
    }
}

function EquipmentShop.new(tokenManager)
    local self = setmetatable({}, EquipmentShop)
    
    self.Player = Players.LocalPlayer
    self.TokenManager = tokenManager
    
    -- Track owned equipment
    self.OwnedEquipment = {}
    
    -- Track active equipment (currently in use)
    self.ActiveEquipment = {}
    
    -- Base speed (before equipment boost)
    self.BaseSpeed = 20
    
    -- Current speed multiplier
    self.SpeedMultiplier = 1.0
    
    -- Callbacks
    self.OnEquipmentPurchased = nil
    self.OnEquipmentActivated = nil
    
    return self
end

function EquipmentShop:Start()
    print("Equipment Shop started - " .. #EQUIPMENT_CATALOG .. " items available")
end

function EquipmentShop:GetCatalog()
    return EQUIPMENT_CATALOG
end

function EquipmentShop:GetEquipmentById(id)
    for _, equipment in ipairs(EQUIPMENT_CATALOG) do
        if equipment.id == id then
            return equipment
        end
    end
    return nil
end

function EquipmentShop:PurchaseEquipment(equipmentId)
    local equipment = self:GetEquipmentById(equipmentId)
    if not equipment then
        print("Equipment not found: " .. equipmentId)
        return false
    end
    
    -- Check if already owned
    if self.OwnedEquipment[equipmentId] then
        print("Already own: " .. equipment.name)
        return false
    end
    
    -- Check if have enough tokens
    if not self.TokenManager:SpendTokens(equipment.tokenCost) then
        print("Not enough tokens for: " .. equipment.name)
        return false
    end
    
    -- Purchase successful
    self.OwnedEquipment[equipmentId] = true
    
    print("Purchased: " .. equipment.name .. " (+" .. (equipment.speedBoost * 100) .. "% speed)")
    
    if self.OnEquipmentPurchased then
        self.OnEquipmentPurchased(equipment)
    end
    
    return true
end

function EquipmentShop:ActivateEquipment(equipmentId)
    if not self.OwnedEquipment[equipmentId] then
        return false
    end
    
    local equipment = self:GetEquipmentById(equipmentId)
    if not equipment then return false end
    
    -- Add to active equipment
    self.ActiveEquipment[equipmentId] = equipment
    
    -- Recalculate speed multiplier
    self:RecalculateSpeedMultiplier()
    
    print("Activated: " .. equipment.name .. " (Current boost: " .. ((self.SpeedMultiplier - 1) * 100) .. "%)")
    
    if self.OnEquipmentActivated then
        self.OnEquipmentActivated(equipment, self.SpeedMultiplier)
    end
    
    return true
end

function EquipmentShop:DeactivateEquipment(equipmentId)
    if self.ActiveEquipment[equipmentId] then
        self.ActiveEquipment[equipmentId] = nil
        self:RecalculateSpeedMultiplier()
        return true
    end
    return false
end

function EquipmentShop:RecalculateSpeedMultiplier()
    self.SpeedMultiplier = 1.0
    
    -- Sum up all active equipment boosts
    for _, equipment in pairs(self.ActiveEquipment) do
        self.SpeedMultiplier = self.SpeedMultiplier + equipment.speedBoost
    end
    
    -- Cap at 3x max speed
    if self.SpeedMultiplier > 3.0 then
        self.SpeedMultiplier = 3.0
    end
end

function EquipmentShop:GetCurrentSpeedMultiplier()
    return self.SpeedMultiplier
end

function EquipmentShop:GetCurrentSpeed()
    return self.BaseSpeed * self.SpeedMultiplier
end

function EquipmentShop:GetOwnedEquipment()
    return self.OwnedEquipment
end

function EquipmentShop:GetActiveEquipment()
    local activeList = {}
    for _, equipment in pairs(self.ActiveEquipment) do
        table.insert(activeList, equipment)
    end
    return activeList
end

function EquipmentShop:IsOwned(equipmentId)
    return self.OwnedEquipment[equipmentId] == true
end

function EquipmentShop:IsActive(equipmentId)
    return self.ActiveEquipment[equipmentId] ~= nil
end

function EquipmentShop:BuyAndActivate(equipmentId)
    -- If not owned, purchase first
    if not self:IsOwned(equipmentId) then
        if not self:PurchaseEquipment(equipmentId) then
            return false
        end
    end
    
    -- Then activate
    return self:ActivateEquipment(equipmentId)
end

return EquipmentShop