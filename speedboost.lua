--[[
    BLOX FRUIT - ULTIMATE MOBILE
    Speed Boost + Air Jump + ESP
    All features automatically enabled
    Press E to toggle ESP
    Click STOP to terminate script
--]]

repeat wait() until game:IsLoaded() and game.Players.LocalPlayer

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Camera = game:GetService("Workspace").CurrentCamera
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- =============================================
-- CONFIGURATION
-- =============================================
local Config = {
    Speed = 100,
    JumpPower = 80,
    MaxAirJumps = 5,
    ESPEnabled = true
}

-- =============================================
-- VARIABLES
-- =============================================
local ScriptActive = true
local airJumpsLeft = 0
local isGrounded = false
local ESPObjects = {}
local espConnections = {}
local MainGUI = nil

-- =============================================
-- TERMINATE FUNCTION
-- =============================================
local function terminateScript()
    ScriptActive = false
    
    pcall(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = 16
            char.Humanoid.JumpPower = 50
        end
    end)
    
    if MainGUI then MainGUI:Destroy() end
    
    for _, esp in pairs(ESPObjects) do
        if esp and esp.Folder then esp.Folder:Destroy() end
    end
    ESPObjects = {}
    
    for _, conn in pairs(espConnections) do
        conn:Disconnect()
    end
    espConnections = {}
    
    print("⚡ Script Terminated")
end

-- =============================================
-- CREATE MODERN UI
-- =============================================
local function createUI()
    MainGUI = Instance.new("ScreenGui")
    MainGUI.Name = "BloxFruitGUI"
    MainGUI.ResetOnSpawn = false
    MainGUI.Parent = game.CoreGui
    MainGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Main Container
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(0, 320, 0, 90)
    Container.Position = UDim2.new(0.5, -160, 0.82, 0)
    Container.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    Container.BackgroundTransparency = 0.15
    Container.BorderSizePixel = 0
    Container.ClipsDescendants = true
    Container.Parent = MainGUI
    
    local ContainerCorner = Instance.new("UICorner")
    ContainerCorner.CornerRadius = UDim.new(0, 12)
    ContainerCorner.Parent = Container
    
    -- Glow Border
    local GlowBorder = Instance.new("Frame")
    GlowBorder.Size = UDim2.new(1, 4, 1, 4)
    GlowBorder.Position = UDim2.new(0, -2, 0, -2)
    GlowBorder.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    GlowBorder.BackgroundTransparency = 0.8
    GlowBorder.BorderSizePixel = 0
    GlowBorder.Parent = Container
    
    local GlowCorner = Instance.new("UICorner")
    GlowCorner.CornerRadius = UDim.new(0, 14)
    GlowCorner.Parent = GlowBorder
    
    -- Top Section (Speed)
    local SpeedFrame = Instance.new("Frame")
    SpeedFrame.Size = UDim2.new(1, -20, 0, 30)
    SpeedFrame.Position = UDim2.new(0, 10, 0, 8)
    SpeedFrame.BackgroundTransparency = 1
    SpeedFrame.Parent = Container
    
    local SpeedIcon = Instance.new("TextLabel")
    SpeedIcon.Size = UDim2.new(0, 30, 1, 0)
    SpeedIcon.Position = UDim2.new(0, 0, 0, 0)
    SpeedIcon.BackgroundTransparency = 1
    SpeedIcon.Text = "⚡"
    SpeedIcon.TextSize = 20
    SpeedIcon.TextColor3 = Color3.fromRGB(0, 255, 100)
    SpeedIcon.Font = Enum.Font.GothamBold
    SpeedIcon.TextXAlignment = Enum.TextXAlignment.Center
    SpeedIcon.Parent = SpeedFrame
    
    local SpeedLabel = Instance.new("TextLabel")
    SpeedLabel.Size = UDim2.new(1, -35, 1, 0)
    SpeedLabel.Position = UDim2.new(0, 35, 0, 0)
    SpeedLabel.BackgroundTransparency = 1
    SpeedLabel.Text = "SPEED: " .. Config.Speed
    SpeedLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    SpeedLabel.TextSize = 18
    SpeedLabel.Font = Enum.Font.GothamBold
    SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
    SpeedLabel.Parent = SpeedFrame
    
    -- Middle Section (Jump)
    local JumpFrame = Instance.new("Frame")
    JumpFrame.Size = UDim2.new(1, -20, 0, 30)
    JumpFrame.Position = UDim2.new(0, 10, 0, 42)
    JumpFrame.BackgroundTransparency = 1
    JumpFrame.Parent = Container
    
    local JumpIcon = Instance.new("TextLabel")
    JumpIcon.Size = UDim2.new(0, 30, 1, 0)
    JumpIcon.Position = UDim2.new(0, 0, 0, 0)
    JumpIcon.BackgroundTransparency = 1
    JumpIcon.Text = "🦘"
    JumpIcon.TextSize = 20
    JumpIcon.TextColor3 = Color3.fromRGB(100, 200, 255)
    JumpIcon.Font = Enum.Font.GothamBold
    JumpIcon.TextXAlignment = Enum.TextXAlignment.Center
    JumpIcon.Parent = JumpFrame
    
    local JumpLabel = Instance.new("TextLabel")
    JumpLabel.Size = UDim2.new(1, -35, 1, 0)
    JumpLabel.Position = UDim2.new(0, 35, 0, 0)
    JumpLabel.BackgroundTransparency = 1
    JumpLabel.Text = "JUMP: " .. Config.JumpPower .. " | AIR: " .. Config.MaxAirJumps
    JumpLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    JumpLabel.TextSize = 18
    JumpLabel.Font = Enum.Font.GothamBold
    JumpLabel.TextXAlignment = Enum.TextXAlignment.Left
    JumpLabel.Parent = JumpFrame
    
    -- ESP Status
    local ESPStatus = Instance.new("TextLabel")
    ESPStatus.Size = UDim2.new(0, 70, 0, 20)
    ESPStatus.Position = UDim2.new(1, -75, 0, 8)
    ESPStatus.BackgroundTransparency = 1
    ESPStatus.Text = "ESP ✓"
    ESPStatus.TextColor3 = Color3.fromRGB(0, 255, 0)
    ESPStatus.TextSize = 14
    ESPStatus.Font = Enum.Font.GothamBold
    ESPStatus.TextXAlignment = Enum.TextXAlignment.Right
    ESPStatus.Parent = Container
    
    -- Stop Button
    local StopBtn = Instance.new("TextButton")
    StopBtn.Size = UDim2.new(0, 60, 0, 24)
    StopBtn.Position = UDim2.new(1, -65, 1, -28)
    StopBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
    StopBtn.BackgroundTransparency = 0.2
    StopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    StopBtn.Text = "✕ STOP"
    StopBtn.TextSize = 14
    StopBtn.Font = Enum.Font.GothamBold
    StopBtn.BorderSizePixel = 0
    StopBtn.Parent = Container
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
    BtnCorner.Parent = StopBtn
    
    StopBtn.MouseEnter:Connect(function()
        TweenService:Create(StopBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
        TweenService:Create(StopBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 40, 40)}):Play()
    end)
    
    StopBtn.MouseLeave:Connect(function()
        TweenService:Create(StopBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.2}):Play()
        TweenService:Create(StopBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(200, 30, 30)}):Play()
    end)
    
    StopBtn.MouseButton1Click:Connect(terminateScript)
    
    -- Pulse Animation
    task.spawn(function()
        while ScriptActive and MainGUI do
            for i = 1, 2 do
                SpeedLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
                JumpLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
                task.wait(0.5)
                SpeedLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
                JumpLabel.TextColor3 = Color3.fromRGB(150, 220, 255)
                task.wait(0.5)
            end
            task.wait(1)
        end
    end)
    
    return {Container = Container, SpeedLabel = SpeedLabel, JumpLabel = JumpLabel, ESPStatus = ESPStatus}
end

-- =============================================
-- SPEED & JUMP SYSTEM
-- =============================================
local function applyStats()
    if not ScriptActive then return end
    pcall(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            local humanoid = char.Humanoid
            humanoid.WalkSpeed = Config.Speed
            humanoid.JumpPower = Config.JumpPower
            
            if humanoid.FloorMaterial ~= Enum.Material.Air then
                isGrounded = true
                airJumpsLeft = Config.MaxAirJumps
            else
                isGrounded = false
            end
        end
    end)
end

-- Air Jump
UserInputService.JumpRequest:Connect(function()
    if not ScriptActive then return end
    
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        
        local humanoid = char:FindFirstChild("Humanoid")
        if not humanoid then return end
        
        if humanoid.FloorMaterial ~= Enum.Material.Air then
            airJumpsLeft = Config.MaxAirJumps
            return
        end
        
        if airJumpsLeft > 0 and humanoid.FloorMaterial == Enum.Material.Air then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            airJumpsLeft = airJumpsLeft - 1
            
            -- Show air jump feedback
            if MainGUI then
                local container = MainGUI:FindFirstChild("Container")
                if container then
                    local jumpLabel = container:FindFirstChild("JumpFrame")
                    if jumpLabel then
                        local label = jumpLabel:FindFirstChild("JumpLabel")
                        if label then
                            label.Text = "🦘 AIR JUMP! (" .. airJumpsLeft .. " left)"
                            task.wait(0.3)
                            label.Text = "JUMP: " .. Config.JumpPower .. " | AIR: " .. Config.MaxAirJumps
                        end
                    end
                end
            end
        end
    end)
end)

-- =============================================
-- ESP SYSTEM
-- =============================================
local function createESP(player)
    if player == LocalPlayer or not ScriptActive then return end
    
    if ESPObjects[player.Name] then
        ESPObjects[player.Name].Folder:Destroy()
        ESPObjects[player.Name] = nil
    end
    
    local function addESPToCharacter(character)
        if not character or not character:FindFirstChild("Humanoid") then return end
        
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        if ESPObjects[player.Name] then
            ESPObjects[player.Name].Folder:Destroy()
            ESPObjects[player.Name] = nil
        end
        
        local folder = Instance.new("Folder")
        folder.Name = "ESP_" .. player.Name
        folder.Parent = game.CoreGui
        folder.Enabled = Config.ESPEnabled
        
        -- Billboard GUI
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 200, 0, 70)
        billboard.Adornee = rootPart
        billboard.StudsOffset = Vector3.new(0, 3.5, 0)
        billboard.MaxDistance = 600
        billboard.AlwaysOnTop = true
        billboard.Parent = folder
        
        local main = Instance.new("Frame")
        main.Size = UDim2.new(1, 0, 1, 0)
        main.BackgroundTransparency = 1
        main.Parent = billboard
        
        -- Name with glow
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
        nameLabel.Position = UDim2.new(0, 0, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.Text = player.Name
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextStrokeTransparency = 0.2
        nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameLabel.Parent = main
        
        -- Level
        local levelLabel = Instance.new("TextLabel")
        levelLabel.Size = UDim2.new(1, 0, 0.3, 0)
        levelLabel.Position = UDim2.new(0, 0, 0.4, 0)
        levelLabel.BackgroundTransparency = 1
        levelLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        levelLabel.Text = "LEVEL: ?"
        levelLabel.TextScaled = true
        levelLabel.Font = Enum.Font.GothamBold
        levelLabel.TextStrokeTransparency = 0.2
        levelLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        levelLabel.Parent = main
        
        -- Health Bar BG
        local healthBg = Instance.new("Frame")
        healthBg.Size = UDim2.new(0.8, 0, 0.15, 0)
        healthBg.Position = UDim2.new(0.1, 0, 0.75, 0)
        healthBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        healthBg.BorderSizePixel = 1
        healthBg.BorderColor3 = Color3.fromRGB(0, 0, 0)
        healthBg.Parent = main
        
        local healthCorner = Instance.new("UICorner")
        healthCorner.CornerRadius = UDim.new(0, 2)
        healthCorner.Parent = healthBg
        
        -- Health Fill
        local healthFill = Instance.new("Frame")
        healthFill.Size = UDim2.new(1, 0, 1, 0)
        healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        healthFill.BorderSizePixel = 0
        healthFill.Parent = healthBg
        
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 2)
        fillCorner.Parent = healthFill
        
        ESPObjects[player.Name] = {
            Folder = folder,
            Billboard = billboard,
            NameLabel = nameLabel,
            LevelLabel = levelLabel,
            HealthFill = healthFill
        }
        
        -- Update loop
        task.spawn(function()
            while ScriptActive and ESPObjects[player.Name] and folder and folder.Parent do
                pcall(function()
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
                        
                        local leaderstats = player:FindFirstChild("leaderstats")
                        if leaderstats then
                            local level = leaderstats:FindFirstChild("Level")
                            if level then
                                levelLabel.Text = "LEVEL: " .. tostring(level.Value)
                            end
                        end
                    end
                end)
                task.wait(0.1)
            end
        end)
    end
    
    if player.Character then
        addESPToCharacter(player.Character)
    end
    
    local conn = player.CharacterAdded:Connect(addESPToCharacter)
    table.insert(espConnections, conn)
end

-- =============================================
-- MAIN EXECUTION
-- =============================================

-- Create UI
local UI = createUI()

-- Start stats loop
task.spawn(function()
    while ScriptActive do
        applyStats()
        task.wait(0.3)
    end
end)

-- Character respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    applyStats()
    airJumpsLeft = Config.MaxAirJumps
    isGrounded = true
end)

-- Initialize ESP
task.wait(0.5)
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        createESP(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        createESP(player)
    end
end)

-- ESP Toggle (E key)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.E then
        Config.ESPEnabled = not Config.ESPEnabled
        
        for _, espData in pairs(ESPObjects) do
            if espData and espData.Folder then
                espData.Folder.Enabled = Config.ESPEnabled
            end
        end
        
        if UI and UI.ESPStatus then
            UI.ESPStatus.Text = Config.ESPEnabled and "ESP ✓" or "ESP ✗"
            UI.ESPStatus.TextColor3 = Config.ESPEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
        end
    end
end)

-- =============================================
-- INITIALIZATION LOG
-- =============================================
print("")
print("╔══════════════════════════════════════╗")
print("║     BLOX FRUIT ULTIMATE MOBILE      ║")
print("╠══════════════════════════════════════╣")
print("║  ⚡ Speed: " .. Config.Speed .. "                      ║")
print("║  🦘 Jump: " .. Config.JumpPower .. " | Air: " .. Config.MaxAirJumps .. "   ║")
print("║  👁️  ESP: ENABLED                     ║")
print("╠══════════════════════════════════════╣")
print("║  Press 'E' to toggle ESP            ║")
print("║  Click 'STOP' to terminate          ║")
print("╚══════════════════════════════════════╝")
print("")
