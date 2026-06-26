--[[
    BLOX FRUIT - SPEED BOOST + AIR JUMP + ESP
    Enhanced version with speed, jump, air jump, and player ESP
    ESP is automatically enabled on load
    Includes terminate button to stop the script
--]]

repeat wait() until game:IsLoaded() and game.Players.LocalPlayer

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Camera = game:GetService("Workspace").CurrentCamera
local UserInputService = game:GetService("UserInputService")

-- Settings
local ScriptActive = true
local SpeedValue = 100  -- Change this to your desired speed
local JumpPowerValue = 80  -- Change this to your desired jump power
local MaxAirJumps = 5  -- Maximum air jumps
local ESPEnabled = true  -- ESP is enabled by default

-- Variables for air jump
local airJumpsLeft = 0
local isGrounded = false

-- Threads to terminate
local threads = {}

-- Clean up old GUI
if game.CoreGui:FindFirstChild("BloxFruitSpeedGUI") then
    game.CoreGui.BloxFruitSpeedGUI:Destroy()
end

-- Clean up old ESP
if game.CoreGui:FindFirstChild("ESP") then
    game.CoreGui.ESP:Destroy()
end

-- =============================================
-- TERMINATE FUNCTION
-- =============================================
local function terminateScript()
    ScriptActive = false
    
    -- Reset character stats
    pcall(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            local humanoid = char.Humanoid
            humanoid.WalkSpeed = 16  -- Default speed
            humanoid.JumpPower = 50  -- Default jump power
        end
    end)
    
    -- Remove GUI
    if game.CoreGui:FindFirstChild("BloxFruitSpeedGUI") then
        game.CoreGui.BloxFruitSpeedGUI:Destroy()
    end
    
    -- Remove ESP
    for _, esp in pairs(ESPObjects) do
        if esp then
            esp:Destroy()
        end
    end
    ESPObjects = {}
    
    if game.CoreGui:FindFirstChild("ESP") then
        game.CoreGui.ESP:Destroy()
    end
    
    print("⚡ Script Terminated - All features stopped")
end

-- =============================================
-- SPEED & JUMP FUNCTIONS
-- =============================================
local function applyStats()
    if not ScriptActive then return end
    pcall(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            local humanoid = char.Humanoid
            humanoid.WalkSpeed = SpeedValue
            humanoid.JumpPower = JumpPowerValue
            
            -- Check if grounded for air jump reset
            if humanoid.FloorMaterial ~= Enum.Material.Air then
                isGrounded = true
                airJumpsLeft = MaxAirJumps
            else
                isGrounded = false
            end
        end
    end)
end

-- =============================================
-- AIR JUMP DETECTION
-- =============================================
UserInputService.JumpRequest:Connect(function()
    if not ScriptActive then return end
    
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        
        local humanoid = char:FindFirstChild("Humanoid")
        if not humanoid then return end
        
        -- If grounded, let the game handle jump
        if humanoid.FloorMaterial ~= Enum.Material.Air then
            airJumpsLeft = MaxAirJumps
            return
        end
        
        -- If in air and have air jumps left
        if airJumpsLeft > 0 and humanoid.FloorMaterial == Enum.Material.Air then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            airJumpsLeft = airJumpsLeft - 1
            
            -- Visual feedback for air jump
            if game.CoreGui:FindFirstChild("BloxFruitSpeedGUI") then
                local display = game.CoreGui.BloxFruitSpeedGUI:FindFirstChild("DisplayFrame")
                if display then
                    local text = display:FindFirstChild("SpeedText")
                    if text then
                        text.Text = "⚡ AIR JUMP! (" .. airJumpsLeft .. " left)"
                        task.wait(0.3)
                        text.Text = "⚡ SPEED: " .. SpeedValue
                    end
                end
            end
        end
    end)
end)

-- =============================================
-- ESP SYSTEM - AUTOMATICALLY ENABLED
-- =============================================
local ESPObjects = {}

local function createESP(player)
    if player == LocalPlayer then return end
    if not ScriptActive then return end
    
    local function addESPToCharacter(character)
        if not character or not character:FindFirstChild("Humanoid") then return end
        if ESPObjects[player.Name] then
            ESPObjects[player.Name]:Destroy()
            ESPObjects[player.Name] = nil
        end
        
        local espFolder = Instance.new("Folder")
        espFolder.Name = "ESP_" .. player.Name
        espFolder.Parent = game.CoreGui
        
        -- Health bar
        local healthBar = Instance.new("Frame")
        healthBar.Size = UDim2.new(0, 100, 0, 8)
        healthBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        healthBar.BorderSizePixel = 0
        healthBar.Parent = espFolder
        
        local healthFill = Instance.new("Frame")
        healthFill.Size = UDim2.new(1, 0, 1, 0)
        healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        healthFill.BorderSizePixel = 0
        healthFill.Parent = healthBar
        
        -- Health background
        local healthBG = Instance.new("Frame")
        healthBG.Size = UDim2.new(1, 2, 1, 2)
        healthBG.Position = UDim2.new(0, -1, 0, -1)
        healthBG.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        healthBG.BackgroundTransparency = 0.5
        healthBG.BorderSizePixel = 0
        healthBG.Parent = healthBar
        
        -- Name and level
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0, 150, 0, 20)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.Text = player.Name
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextStrokeTransparency = 0.5
        nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameLabel.Parent = espFolder
        
        local levelLabel = Instance.new("TextLabel")
        levelLabel.Size = UDim2.new(0, 100, 0, 16)
        levelLabel.Position = UDim2.new(0, 0, 0, 18)
        levelLabel.BackgroundTransparency = 1
        levelLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        levelLabel.Text = "LEVEL: ?"
        levelLabel.TextScaled = true
        levelLabel.Font = Enum.Font.GothamBold
        levelLabel.TextStrokeTransparency = 0.5
        levelLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        levelLabel.Parent = espFolder
        
        ESPObjects[player.Name] = espFolder
        
        -- Update loop for position
        local thread = task.spawn(function()
            while espFolder and espFolder.Parent and ScriptActive do
                pcall(function()
                    if character and character:FindFirstChild("HumanoidRootPart") then
                        local pos, onScreen = Camera:WorldToViewportPoint(character.HumanoidRootPart.Position + Vector3.new(0, 3, 0))
                        if onScreen then
                            espFolder.Visible = true
                            healthBar.Position = UDim2.new(0, pos.X - 50, 0, pos.Y - 30)
                            nameLabel.Position = UDim2.new(0, pos.X - 75, 0, pos.Y - 50)
                            levelLabel.Position = UDim2.new(0, pos.X - 50, 0, pos.Y - 15)
                            
                            -- Update health
                            local humanoid = character:FindFirstChild("Humanoid")
                            if humanoid then
                                local healthPercent = humanoid.Health / humanoid.MaxHealth
                                healthFill.Size = UDim2.new(healthPercent, 0, 1, 0)
                                if healthPercent > 0.5 then
                                    healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                                elseif healthPercent > 0.25 then
                                    healthFill.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
                                else
                                    healthFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                                end
                            end
                            
                            -- Update level from leaderstats
                            local leaderstats = player:FindFirstChild("leaderstats")
                            if leaderstats then
                                local level = leaderstats:FindFirstChild("Level")
                                if level then
                                    levelLabel.Text = "LEVEL: " .. tostring(level.Value)
                                end
                            end
                        else
                            espFolder.Visible = false
                        end
                    end
                end)
                task.wait(0.1)
            end
        end)
        table.insert(threads, thread)
    end
    
    -- Connect to character added
    if player.Character then
        addESPToCharacter(player.Character)
    end
    player.CharacterAdded:Connect(function(character)
        addESPToCharacter(character)
    end)
end

-- =============================================
-- GUI CREATION - Enhanced with controls
-- =============================================
local GUI = Instance.new("ScreenGui")
GUI.Name = "BloxFruitSpeedGUI"
GUI.ResetOnSpawn = false
GUI.Parent = game.CoreGui
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Display Frame
local DisplayFrame = Instance.new("Frame")
DisplayFrame.Size = UDim2.new(0, 280, 0, 80)
DisplayFrame.Position = UDim2.new(0.5, -140, 0.85, 0)
DisplayFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
DisplayFrame.BackgroundTransparency = 0.3
DisplayFrame.BorderSizePixel = 0
DisplayFrame.Parent = GUI

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 8)
FrameCorner.Parent = DisplayFrame

-- Main Speed Text
local SpeedText = Instance.new("TextLabel")
SpeedText.Size = UDim2.new(1, 0, 0.4, 0)
SpeedText.Position = UDim2.new(0, 0, 0, 0)
SpeedText.BackgroundTransparency = 1
SpeedText.TextColor3 = Color3.fromRGB(100, 255, 100)
SpeedText.Text = "⚡ SPEED: " .. SpeedValue
SpeedText.TextScaled = true
SpeedText.Font = Enum.Font.GothamBold
SpeedText.Parent = DisplayFrame

-- Jump Info Text
local JumpText = Instance.new("TextLabel")
JumpText.Size = UDim2.new(1, 0, 0.35, 0)
JumpText.Position = UDim2.new(0, 0, 0.4, 0)
JumpText.BackgroundTransparency = 1
JumpText.TextColor3 = Color3.fromRGB(100, 200, 255)
JumpText.Text = "🦘 JUMP: " .. JumpPowerValue .. " | AIR: " .. MaxAirJumps
JumpText.TextScaled = true
JumpText.Font = Enum.Font.GothamBold
JumpText.Parent = DisplayFrame

-- ESP Status Text
local ESPText = Instance.new("TextLabel")
ESPText.Size = UDim2.new(0, 80, 0, 16)
ESPText.Position = UDim2.new(1, -85, 0, 2)
ESPText.BackgroundTransparency = 1
ESPText.TextColor3 = Color3.fromRGB(0, 255, 0)
ESPText.Text = "ESP ✓"
ESPText.TextScaled = true
ESPText.Font = Enum.Font.GothamBold
ESPText.Parent = DisplayFrame

-- =============================================
-- TERMINATE BUTTON
-- =============================================
local TerminateButton = Instance.new("TextButton")
TerminateButton.Size = UDim2.new(0, 60, 0, 20)
TerminateButton.Position = UDim2.new(1, -65, 1, -22)
TerminateButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
TerminateButton.BackgroundTransparency = 0.3
TerminateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TerminateButton.Text = "✕ STOP"
TerminateButton.TextScaled = true
TerminateButton.Font = Enum.Font.GothamBold
TerminateButton.BorderSizePixel = 0
TerminateButton.Parent = DisplayFrame

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 4)
ButtonCorner.Parent = TerminateButton

-- Button hover effect
TerminateButton.MouseEnter:Connect(function()
    TerminateButton.BackgroundTransparency = 0
    TerminateButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
end)

TerminateButton.MouseLeave:Connect(function()
    TerminateButton.BackgroundTransparency = 0.3
    TerminateButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
end)

-- Terminate function
TerminateButton.MouseButton1Click:Connect(function()
    terminateScript()
end)

-- Glow effect
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
-- PULSE ANIMATION
-- =============================================
local pulseThread = task.spawn(function()
    while ScriptActive do
        for i = 1, 2 do
            SpeedText.TextColor3 = Color3.fromRGB(100, 255, 100)
            JumpText.TextColor3 = Color3.fromRGB(100, 200, 255)
            task.wait(0.5)
            SpeedText.TextColor3 = Color3.fromRGB(150, 255, 150)
            JumpText.TextColor3 = Color3.fromRGB(150, 220, 255)
            task.wait(0.5)
        end
        task.wait(1)
    end
end)
table.insert(threads, pulseThread)

-- =============================================
-- APPLY STATS LOOP
-- =============================================
local statsThread = task.spawn(function()
    while ScriptActive do
        applyStats()
        task.wait(0.3)
    end
end)
table.insert(threads, statsThread)

-- Handle character respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    applyStats()
    airJumpsLeft = MaxAirJumps
    isGrounded = true
end)

-- =============================================
-- INITIALIZE ESP - AUTOMATICALLY
-- =============================================
-- ESP is enabled by default
for _, player in ipairs(Players:GetPlayers()) do
    createESP(player)
end

Players.PlayerAdded:Connect(function(player)
    createESP(player)
end)

-- =============================================
-- TOGGLE FUNCTIONS (Optional)
-- =============================================
-- Press 'E' to toggle ESP (Optional - can remove this section)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.E then
        ESPEnabled = not ESPEnabled
        for _, esp in pairs(ESPObjects) do
            esp.Enabled = ESPEnabled
        end
        -- Update ESP status text
        if game.CoreGui:FindFirstChild("BloxFruitSpeedGUI") then
            local display = game.CoreGui.BloxFruitSpeedGUI:FindFirstChild("DisplayFrame")
            if display then
                local espText = display:FindFirstChild("ESPText")
                if espText then
                    espText.Text = ESPEnabled and "ESP ✓" or "ESP ✗"
                    espText.TextColor3 = ESPEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                end
            end
        end
        print("ESP " .. (ESPEnabled and "Enabled" or "Disabled"))
    end
end)

-- =============================================
-- TERMINATE ON PLAYER LEAVE
-- =============================================
LocalPlayer.CharacterRemoving:Connect(function()
    if not ScriptActive then return end
    -- Don't terminate, just let it respawn
end)

print("⚡ BLOX FRUIT ENHANCED SCRIPT LOADED!")
print("   Speed: " .. SpeedValue)
print("   Jump Power: " .. JumpPowerValue)
print("   Air Jumps: " .. MaxAirJumps)
print("   ESP: ENABLED (Press 'E' to toggle)")
print("   ✓ All features active!")
print("   ✕ Click 'STOP' button to terminate script")
