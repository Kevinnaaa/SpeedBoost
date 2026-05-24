--[[
    BLOX FRUIT - SPEED BOOST
    Simple display only - shows speed boost is active
--]]

repeat wait() until game:IsLoaded() and game.Players.LocalPlayer

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- Settings
local ScriptActive = true
local SpeedValue = 100  -- Change this to your desired speed (default 100)

-- Clean up old GUI
if game.CoreGui:FindFirstChild("BloxFruitSpeedGUI") then
    game.CoreGui.BloxFruitSpeedGUI:Destroy()
end

-- =============================================
-- SPEED FUNCTION
-- =============================================
local function applySpeed()
    pcall(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            local humanoid = char.Humanoid
            humanoid.WalkSpeed = SpeedValue
        end
    end)
end

-- =============================================
-- GUI CREATION - Just text display
-- =============================================
local GUI = Instance.new("ScreenGui")
GUI.Name = "BloxFruitSpeedGUI"
GUI.ResetOnSpawn = false
GUI.Parent = game.CoreGui
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Simple Text Display Frame
local DisplayFrame = Instance.new("Frame")
DisplayFrame.Size = UDim2.new(0, 220, 0, 40)
DisplayFrame.Position = UDim2.new(0.5, -110, 0.85, 0)  -- Bottom center of screen
DisplayFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
DisplayFrame.BackgroundTransparency = 0.3
DisplayFrame.BorderSizePixel = 0
DisplayFrame.Parent = GUI

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 8)
FrameCorner.Parent = DisplayFrame

-- Speed Text
local SpeedText = Instance.new("TextLabel")
SpeedText.Size = UDim2.new(1, 0, 1, 0)
SpeedText.BackgroundTransparency = 1
SpeedText.TextColor3 = Color3.fromRGB(100, 255, 100)
SpeedText.Text = "⚡ SPEED BOOST APPLIED (" .. SpeedValue .. ")"
SpeedText.TextScaled = true
SpeedText.Font = Enum.Font.GothamBold
SpeedText.Parent = DisplayFrame

-- Small glow effect
local Glow = Instance.new("Frame")
Glow.Size = UDim2.new(1, 20, 1, 10)
Glow.Position = UDim2.new(0, -10, 0, -5)
Glow.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
Glow.BackgroundTransparency = 0.9
Glow.BorderSizePixel = 0
Glow.Parent = DisplayFrame

local GlowCorner = Instance.new("UICorner")
GlowCorner.CornerRadius = UDim.new(0, 12)
GlowCorner.Parent = Glow

-- =============================================
-- PULSE ANIMATION (subtle)
-- =============================================
task.spawn(function()
    while ScriptActive do
        for i = 1, 2 do
            SpeedText.TextColor3 = Color3.fromRGB(100, 255, 100)
            task.wait(0.5)
            SpeedText.TextColor3 = Color3.fromRGB(150, 255, 150)
            task.wait(0.5)
        end
        task.wait(1)
    end
end)

-- =============================================
-- APPLY SPEED LOOP
-- =============================================
task.spawn(function()
    while ScriptActive do
        applySpeed()
        task.wait(0.3)
    end
end)

-- Handle character respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    applySpeed()
end)

print("⚡ Blox Fruit Speed Boost Applied! Speed: " .. SpeedValue)
print("   Display shows at bottom center of screen")
