--[[
    BLOX FRUIT - SPEED BOOST + AURA KILL
    Speed boost display + Kill aura within 100 studs + Switch Buttons
--]]

repeat wait() until game:IsLoaded() and game.Players.LocalPlayer

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Settings
local ScriptActive = true
local SpeedValue = 100  -- Change this to your desired speed (default 100)
local AuraRange = 100   -- Kill aura range in studs
local AuraEnabled = true -- Toggle aura kill on/off
local SpeedEnabled = true -- Toggle speed on/off

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
            if SpeedEnabled then
                humanoid.WalkSpeed = SpeedValue
            else
                humanoid.WalkSpeed = 16  -- Default speed
            end
        end
    end)
end

-- =============================================
-- AURA KILL FUNCTION
-- =============================================
local function getNearbyEnemies()
    local enemies = {}
    local character = LocalPlayer.Character
    
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return enemies
    end
    
    local rootPos = character.HumanoidRootPart.Position
    
    -- Check all players
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local enemyChar = player.Character
            local enemyHumanoid = enemyChar:FindFirstChild("Humanoid")
            local enemyRoot = enemyChar:FindFirstChild("HumanoidRootPart")
            
            if enemyHumanoid and enemyRoot and enemyHumanoid.Health > 0 then
                local distance = (rootPos - enemyRoot.Position).Magnitude
                if distance <= AuraRange then
                    table.insert(enemies, {
                        Character = enemyChar,
                        Humanoid = enemyHumanoid,
                        Distance = distance,
                        Player = player
                    })
                end
            end
        end
    end
    
    -- Also check for NPCs/mobs
    for _, model in pairs(Workspace:GetDescendants()) do
        if model:IsA("Model") and model:FindFirstChild("Humanoid") and model:FindFirstChild("HumanoidRootPart") then
            local humanoid = model.Humanoid
            local rootPart = model.HumanoidRootPart
            
            -- Make sure it's not a player character
            if not Players:GetPlayerFromCharacter(model) and humanoid.Health > 0 then
                local distance = (rootPos - rootPart.Position).Magnitude
                if distance <= AuraRange then
                    table.insert(enemies, {
                        Character = model,
                        Humanoid = humanoid,
                        Distance = distance,
                        IsNPC = true
                    })
                end
            end
        end
    end
    
    -- Sort by distance (closest first)
    table.sort(enemies, function(a, b)
        return a.Distance < b.Distance
    end)
    
    return enemies
end

local function killTarget(target)
    pcall(function()
        if target and target.Character and target.Humanoid then
            -- Method 1: Set health to 0
            target.Humanoid.Health = 0
            
            -- Method 2: Try to break joints (backup)
            if target.Humanoid.Health > 0 then
                for _, part in pairs(target.Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part:BreakJoints()
                    end
                end
            end
            
            -- Method 3: Try damage via remotes (if available)
            if target.Player and ReplicatedStorage:FindFirstChild("Remotes") then
                local remotes = ReplicatedStorage.Remotes
                if remotes:FindFirstChild("Damage") then
                    remotes.Damage:FireServer(target.Character, 999999)
                end
            end
        end
    end)
end

local function auraKillLoop()
    while ScriptActive and AuraEnabled do
        local enemies = getNearbyEnemies()
        
        for _, enemy in pairs(enemies) do
            if enemy.Humanoid.Health > 0 then
                killTarget(enemy)
            end
        end
        
        task.wait(0.1) -- Check every 0.1 seconds
    end
end

-- =============================================
-- SWITCH BUTTON FUNCTION
-- =============================================
local function createSwitchButton(parent, position, initialState, onText, offText, callback)
    -- Switch Background
    local SwitchFrame = Instance.new("Frame")
    SwitchFrame.Size = UDim2.new(0, 140, 0, 35)
    SwitchFrame.Position = position
    SwitchFrame.BackgroundColor3 = initialState and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    SwitchFrame.BorderSizePixel = 0
    SwitchFrame.Parent = parent
    
    local SwitchCorner = Instance.new("UICorner")
    SwitchCorner.CornerRadius = UDim.new(0, 17)
    SwitchCorner.Parent = SwitchFrame
    
    -- Switch Knob
    local SwitchKnob = Instance.new("Frame")
    SwitchKnob.Size = UDim2.new(0, 30, 0, 30)
    SwitchKnob.Position = initialState and UDim2.new(1, -33, 0.5, -15) or UDim2.new(0, 3, 0.5, -15)
    SwitchKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SwitchKnob.BorderSizePixel = 0
    SwitchKnob.Parent = SwitchFrame
    
    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(1, 0)
    KnobCorner.Parent = SwitchKnob
    
    -- Switch Text
    local SwitchText = Instance.new("TextLabel")
    SwitchText.Size = UDim2.new(1, 0, 1, 0)
    SwitchText.BackgroundTransparency = 1
    SwitchText.Text = initialState and onText or offText
    SwitchText.TextColor3 = Color3.fromRGB(255, 255, 255)
    SwitchText.TextScaled = true
    SwitchText.Font = Enum.Font.GothamBold
    SwitchText.Parent = SwitchFrame
    
    -- Switch Logic
    local isOn = initialState
    
    local function updateSwitch()
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        
        if isOn then
            -- Turn OFF
            local knobTween = TweenService:Create(SwitchKnob, tweenInfo, {Position = UDim2.new(0, 3, 0.5, -15)})
            local colorTween = TweenService:Create(SwitchFrame, tweenInfo, {BackgroundColor3 = Color3.fromRGB(200, 50, 50)})
            knobTween:Play()
            colorTween:Play()
            SwitchText.Text = offText
        else
            -- Turn ON
            local knobTween = TweenService:Create(SwitchKnob, tweenInfo, {Position = UDim2.new(1, -33, 0.5, -15)})
            local colorTween = TweenService:Create(SwitchFrame, tweenInfo, {BackgroundColor3 = Color3.fromRGB(50, 200, 50)})
            knobTween:Play()
            colorTween:Play()
            SwitchText.Text = onText
        end
        
        isOn = not isOn
        callback(isOn)
    end
    
    -- Make the switch clickable
    local SwitchButton = Instance.new("TextButton")
    SwitchButton.Size = UDim2.new(1, 0, 1, 0)
    SwitchButton.BackgroundTransparency = 1
    SwitchButton.Text = ""
    SwitchButton.Parent = SwitchFrame
    SwitchButton.ZIndex = 2
    
    SwitchButton.MouseButton1Click:Connect(updateSwitch)
    
    -- Return function to get current state
    return {
        GetState = function() return isOn end,
        SetState = function(state)
            if state ~= isOn then
                updateSwitch()
            end
        end
    }
end

-- =============================================
-- GUI CREATION - Control Panel with Switches
-- =============================================
local GUI = Instance.new("ScreenGui")
GUI.Name = "BloxFruitSpeedGUI"
GUI.ResetOnSpawn = false
GUI.Parent = game.CoreGui
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Control Panel
local ControlPanel = Instance.new("Frame")
ControlPanel.Size = UDim2.new(0, 240, 0, 180)
ControlPanel.Position = UDim2.new(0.95, -240, 0.05, 0)  -- Top right corner
ControlPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ControlPanel.BackgroundTransparency = 0.2
ControlPanel.BorderSizePixel = 0
ControlPanel.Parent = GUI

local PanelCorner = Instance.new("UICorner")
PanelCorner.CornerRadius = UDim.new(0, 12)
PanelCorner.Parent = ControlPanel

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Position = UDim2.new(0, 0, 0, 10)
Title.BackgroundTransparency = 1
Title.Text = "⚡ BLOX FRUIT CHEATS"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.Parent = ControlPanel

-- Speed Switch
local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(0, 80, 0, 20)
SpeedLabel.Position = UDim2.new(0, 15, 0, 50)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "⚡ Speed"
SpeedLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
SpeedLabel.TextScaled = true
SpeedLabel.Font = Enum.Font.GothamBold
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
SpeedLabel.Parent = ControlPanel

local SpeedSwitch = createSwitchButton(
    ControlPanel,
    UDim2.new(0, 85, 0, 50),
    true,
    "ON",
    "OFF",
    function(state)
        SpeedEnabled = state
        applySpeed()
        print("⚡ Speed Boost: " .. (state and "ENABLED" or "DISABLED"))
    end
)

-- Aura Kill Switch
local AuraLabel = Instance.new("TextLabel")
AuraLabel.Size = UDim2.new(0, 80, 0, 20)
AuraLabel.Position = UDim2.new(0, 15, 0, 95)
AuraLabel.BackgroundTransparency = 1
AuraLabel.Text = "💀 Aura Kill"
AuraLabel.TextColor3 = Color3.fromRGB(255, 150, 150)
AuraLabel.TextScaled = true
AuraLabel.Font = Enum.Font.GothamBold
AuraLabel.TextXAlignment = Enum.TextXAlignment.Left
AuraLabel.Parent = ControlPanel

local AuraSwitch = createSwitchButton(
    ControlPanel,
    UDim2.new(0, 85, 0, 95),
    true,
    "ON",
    "OFF",
    function(state)
        AuraEnabled = state
        if AuraEnabled then
            task.spawn(auraKillLoop)
        end
        print("💀 Aura Kill: " .. (state and "ENABLED" or "DISABLED"))
    end
)

-- Kill Counter
local KillCount = 0
local KillCountLabel = Instance.new("TextLabel")
KillCountLabel.Size = UDim2.new(1, -20, 0, 20)
KillCountLabel.Position = UDim2.new(0, 10, 0, 140)
KillCountLabel.BackgroundTransparency = 1
KillCountLabel.Text = "💀 Kills: " .. KillCount
KillCountLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
KillCountLabel.TextScaled = true
KillCountLabel.Font = Enum.Font.GothamBold
KillCountLabel.Parent = ControlPanel

-- Terminate Button
local TerminateButton = Instance.new("TextButton")
TerminateButton.Size = UDim2.new(0, 30, 0, 30)
TerminateButton.Position = UDim2.new(1, -35, 0, 5)
TerminateButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
TerminateButton.BorderSizePixel = 0
TerminateButton.Text = "✕"
TerminateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TerminateButton.TextScaled = true
TerminateButton.Font = Enum.Font.GothamBold
TerminateButton.Parent = ControlPanel
TerminateButton.ZIndex = 10

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 8)
ButtonCorner.Parent = TerminateButton

-- Hover effect for terminate button
TerminateButton.MouseEnter:Connect(function()
    TerminateButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
end)

TerminateButton.MouseLeave:Connect(function()
    TerminateButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
end)

-- Terminate button functionality
TerminateButton.MouseButton1Click:Connect(function()
    -- Reset speed to default
    pcall(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = 16  -- Default Roblox walkspeed
        end
    end)
    
    -- Destroy GUI
    GUI:Destroy()
    
    -- Set ScriptActive to false to stop all loops
    ScriptActive = false
    AuraEnabled = false
    
    print("Script terminated! All features disabled.")
end)

-- =============================================
-- KILL COUNT UPDATE
-- =============================================
task.spawn(function()
    local lastEnemies = {}
    while ScriptActive and AuraEnabled do
        local currentEnemies = getNearbyEnemies()
        
        -- Check for dead enemies that weren't dead before
        for _, enemy in pairs(currentEnemies) do
            if enemy.Humanoid.Health <= 0 and not lastEnemies[enemy] then
                KillCount = KillCount + 1
                KillCountLabel.Text = "💀 Kills: " .. KillCount
            end
        end
        
        lastEnemies = {}
        for _, enemy in pairs(currentEnemies) do
            lastEnemies[enemy] = true
        end
        
        task.wait(0.5)
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

-- Start aura kill
task.spawn(auraKillLoop)

-- Handle character respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    applySpeed()
end)

print("⚡ Blox Fruit Control Panel Loaded!")
print("   💡 Use switches to toggle features on/off")
print("   🚫 Click '✕' to terminate script completely")
