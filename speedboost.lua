--[[
    UNIVERSAL ESP SCRIPT
    Highlight-based player detection + Speed Boost + Air Jump + FPS Counter
    Works on any Roblox game
]]

repeat wait() until game:IsLoaded() and game.Players.LocalPlayer

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Camera = game:GetService("Workspace").CurrentCamera
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local Workspace = game:GetService("Workspace")
local Teams = game:GetService("Teams")

-- =============================================
-- CONFIGURATION
-- =============================================
local Config = {
    Speed = 100,
    JumpPower = 80,
    MaxAirJumps = 5,
    ESPEnabled = true,
    ShowFPS = true,
    ScanInterval = 0.1,
    TEXT_SIZE = 14,
    TEXT_FONT = Enum.Font.GothamBold,
    TEXT_OUTLINE = true,
    HIGHLIGHT_ENABLED = true,
    MaxESPDistance = 1000
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
local fpsCounter = 0
local fpsUpdateTime = 0

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
        if esp and esp.Billboard then esp.Billboard:Destroy() end
        if esp and esp.Highlight then esp.Highlight:Destroy() end
    end
    ESPObjects = {}
    
    for _, conn in pairs(espConnections) do
        conn:Disconnect()
    end
    espConnections = {}
    
    print("✓ Universal ESP Script Terminated")
end

-- =============================================
-- FPS COUNTER
-- =============================================
local function getFPS()
    local fps = Stats:FindFirstChild("PerformanceStats")
    if fps then
        local fpsValue = fps:FindFirstChild("FPS")
        if fpsValue then
            return math.floor(fpsValue.Value)
        end
    end
    return 0
end

-- =============================================
-- GET TEAM COLOR
-- =============================================
local function getTeamColor(player)
    if player.Team then
        return player.Team.TeamColor.Color
    end
    return Color3.fromRGB(0, 150, 255)
end

-- =============================================
-- CREATE MODERN UI
-- =============================================
local function createUI()
    MainGUI = Instance.new("ScreenGui")
    MainGUI.Name = "UniversalESPGUI"
    MainGUI.ResetOnSpawn = false
    MainGUI.Parent = game.CoreGui
    MainGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(0, 340, 0, 110)
    Container.Position = UDim2.new(0.5, -170, 0.80, 0)
    Container.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    Container.BackgroundTransparency = 0.15
    Container.BorderSizePixel = 0
    Container.ClipsDescendants = true
    Container.Parent = MainGUI
    
    local ContainerCorner = Instance.new("UICorner")
    ContainerCorner.CornerRadius = UDim.new(0, 12)
    ContainerCorner.Parent = Container
    
    local GlowBorder = Instance.new("Frame")
    GlowBorder.Size = UDim2.new(1, 4, 1, 4)
    GlowBorder.Position = UDim2.new(0, -2, 0, -2)
    GlowBorder.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    GlowBorder.BackgroundTransparency = 0.8
    GlowBorder.BorderSizePixel = 0
    GlowBorder.Parent = Container
    
    local GlowCorner = Instance.new("UICorner")
    GlowCorner.CornerRadius = UDim.new(0, 14)
    GlowCorner.Parent = GlowBorder
    
    local SpeedFrame = Instance.new("Frame")
    SpeedFrame.Size = UDim2.new(1, -20, 0, 25)
    SpeedFrame.Position = UDim2.new(0, 10, 0, 6)
    SpeedFrame.BackgroundTransparency = 1
    SpeedFrame.Parent = Container
    
    local SpeedIcon = Instance.new("TextLabel")
    SpeedIcon.Size = UDim2.new(0, 25, 1, 0)
    SpeedIcon.Position = UDim2.new(0, 0, 0, 0)
    SpeedIcon.BackgroundTransparency = 1
    SpeedIcon.Text = "⚡"
    SpeedIcon.TextSize = 18
    SpeedIcon.TextColor3 = Color3.fromRGB(0, 200, 255)
    SpeedIcon.Font = Enum.Font.GothamBold
    SpeedIcon.TextXAlignment = Enum.TextXAlignment.Center
    SpeedIcon.Parent = SpeedFrame
    
    local SpeedLabel = Instance.new("TextLabel")
    SpeedLabel.Size = UDim2.new(1, -35, 1, 0)
    SpeedLabel.Position = UDim2.new(0, 35, 0, 0)
    SpeedLabel.BackgroundTransparency = 1
    SpeedLabel.Text = "SPEED: " .. Config.Speed
    SpeedLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
    SpeedLabel.TextSize = 16
    SpeedLabel.Font = Enum.Font.GothamBold
    SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
    SpeedLabel.Parent = SpeedFrame
    
    local JumpFrame = Instance.new("Frame")
    JumpFrame.Size = UDim2.new(1, -20, 0, 25)
    JumpFrame.Position = UDim2.new(0, 10, 0, 35)
    JumpFrame.BackgroundTransparency = 1
    JumpFrame.Parent = Container
    
    local JumpIcon = Instance.new("TextLabel")
    JumpIcon.Size = UDim2.new(0, 25, 1, 0)
    JumpIcon.Position = UDim2.new(0, 0, 0, 0)
    JumpIcon.BackgroundTransparency = 1
    JumpIcon.Text = "🦘"
    JumpIcon.TextSize = 18
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
    JumpLabel.TextSize = 16
    JumpLabel.Font = Enum.Font.GothamBold
    JumpLabel.TextXAlignment = Enum.TextXAlignment.Left
    JumpLabel.Parent = JumpFrame
    
    local FPSFrame = Instance.new("Frame")
    FPSFrame.Size = UDim2.new(0, 80, 0, 25)
    FPSFrame.Position = UDim2.new(0, 10, 0, 64)
    FPSFrame.BackgroundTransparency = 1
    FPSFrame.Parent = Container
    
    local FPSIcon = Instance.new("TextLabel")
    FPSIcon.Size = UDim2.new(0, 25, 1, 0)
    FPSIcon.Position = UDim2.new(0, 0, 0, 0)
    FPSIcon.BackgroundTransparency = 1
    FPSIcon.Text = "📊"
    FPSIcon.TextSize = 16
    FPSIcon.TextColor3 = Color3.fromRGB(255, 200, 100)
    FPSIcon.Font = Enum.Font.GothamBold
    FPSIcon.TextXAlignment = Enum.TextXAlignment.Center
    FPSIcon.Parent = FPSFrame
    
    local FPSLabel = Instance.new("TextLabel")
    FPSLabel.Size = UDim2.new(1, -35, 1, 0)
    FPSLabel.Position = UDim2.new(0, 35, 0, 0)
    FPSLabel.BackgroundTransparency = 1
    FPSLabel.Text = "FPS: 60"
    FPSLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    FPSLabel.TextSize = 16
    FPSLabel.Font = Enum.Font.GothamBold
    FPSLabel.TextXAlignment = Enum.TextXAlignment.Left
    FPSLabel.Parent = FPSFrame
    
    local ESPStatus = Instance.new("TextLabel")
    ESPStatus.Size = UDim2.new(0, 90, 0, 20)
    ESPStatus.Position = UDim2.new(1, -95, 0, 6)
    ESPStatus.BackgroundTransparency = 1
    ESPStatus.Text = "ESP ✓ (1km)"
    ESPStatus.TextColor3 = Color3.fromRGB(0, 255, 100)
    ESPStatus.TextSize = 14
    ESPStatus.Font = Enum.Font.GothamBold
    ESPStatus.TextXAlignment = Enum.TextXAlignment.Right
    ESPStatus.Parent = Container
    
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
    
    task.spawn(function()
        while ScriptActive and MainGUI do
            pcall(function()
                local fps = getFPS()
                if fps > 0 then
                    FPSLabel.Text = "FPS: " .. fps
                    
                    if fps >= 60 then
                        FPSLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
                    elseif fps >= 30 then
                        FPSLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
                    else
                        FPSLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
                    end
                end
            end)
            task.wait(0.5)
        end
    end)
    
    return {
        Container = Container, 
        SpeedLabel = SpeedLabel, 
        JumpLabel = JumpLabel, 
        ESPStatus = ESPStatus,
        FPSLabel = FPSLabel
    }
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
        end
    end)
end)

-- =============================================
-- HIGHLIGHT-BASED ESP SYSTEM
-- =============================================
local function createHighlightESP(player)
    if player == LocalPlayer or not ScriptActive then return end
    
    if ESPObjects[player.Name] then
        pcall(function()
            if ESPObjects[player.Name].Billboard then
                ESPObjects[player.Name].Billboard:Destroy()
            end
            if ESPObjects[player.Name].Highlight then
                ESPObjects[player.Name].Highlight:Destroy()
            end
        end)
        ESPObjects[player.Name] = nil
    end
    
    local function addESP(character)
        if not character then return end
        
        local humanoid = character:WaitForChild("Humanoid", 5)
        local rootPart = character:WaitForChild("HumanoidRootPart", 5)
        local head = character:WaitForChild("Head", 5)
        
        if not humanoid or not rootPart or not head then 
            return 
        end
        
        local teamColor = getTeamColor(player)
        
        -- Create Highlight for player
        local highlight = nil
        if Config.HIGHLIGHT_ENABLED then
            highlight = Instance.new("Highlight")
            highlight.FillColor = teamColor
            highlight.OutlineColor = Color3.new(1, 1, 1)
            highlight.FillTransparency = 0.3
            highlight.OutlineTransparency = 0
            highlight.Enabled = true
            highlight.Parent = character
        end
        
        -- Create Billboard GUI for name tag
        local billboard = Instance.new("BillboardGui")
        billboard.Adornee = head
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Enabled = true
        billboard.Parent = character
        billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        -- Name label
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.Name
        nameLabel.TextColor3 = teamColor
        nameLabel.TextSize = Config.TEXT_SIZE
        nameLabel.Font = Config.TEXT_FONT
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameLabel.Parent = billboard
        
        ESPObjects[player.Name] = {
            Billboard = billboard,
            Highlight = highlight,
            NameLabel = nameLabel,
            Humanoid = humanoid,
            RootPart = rootPart
        }
    end
    
    if player.Character then
        addESP(player.Character)
    end
    
    local conn = player.CharacterAdded:Connect(function(character)
        task.wait(0.5)
        addESP(character)
    end)
    table.insert(espConnections, conn)
end

-- =============================================
-- TEAM CHANGE HANDLER
-- =============================================
local function onTeamChanged(player)
    if player == LocalPlayer then return end
    
    local espData = ESPObjects[player.Name]
    if not espData then return end
    
    local teamColor = getTeamColor(player)
    
    if espData.Highlight then
        espData.Highlight.FillColor = teamColor
    end
    
    if espData.NameLabel then
        espData.NameLabel.TextColor3 = teamColor
    end
end

-- =============================================
-- MAIN ESP UPDATE LOOP
-- =============================================
task.spawn(function()
    while ScriptActive do
        task.wait(Config.ScanInterval)
        
        pcall(function()
            for playerName, espData in pairs(ESPObjects) do
                if not espData or not espData.Highlight then continue end
                
                local player = Players:FindFirstChild(playerName)
                if not player then 
                    if espData.Billboard then espData.Billboard:Destroy() end
                    if espData.Highlight then espData.Highlight:Destroy() end
                    ESPObjects[playerName] = nil
                    continue
                end
                
                local character = player.Character
                if not character then 
                    if espData.Highlight then espData.Highlight.Enabled = false end
                    if espData.Billboard then espData.Billboard.Enabled = false end
                    continue
                end
                
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                local humanoid = character:FindFirstChild("Humanoid")
                local head = character:FindFirstChild("Head")
                
                if not rootPart or not humanoid or not head then 
                    if espData.Highlight then espData.Highlight.Enabled = false end
                    if espData.Billboard then espData.Billboard.Enabled = false end
                    continue
                end
                
                -- Update billboard attachment
                if espData.Billboard then
                    espData.Billboard.Adornee = head
                end
                
                -- Update highlight parent
                if espData.Highlight then
                    espData.Highlight.Parent = character
                end
                
                -- Check distance - 1000m max
                local dist = (Camera.CFrame.Position - rootPart.Position).Magnitude
                local isInRange = dist <= Config.MaxESPDistance
                
                -- Show/hide based on range and ESP enabled
                if isInRange and Config.ESPEnabled then
                    if espData.Highlight then espData.Highlight.Enabled = true end
                    if espData.Billboard then espData.Billboard.Enabled = true end
                    
                    -- Update name with health
                    local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                    espData.NameLabel.Text = player.Name .. " [" .. math.floor(healthPercent * 100) .. "%]"
                else
                    if espData.Highlight then espData.Highlight.Enabled = false end
                    if espData.Billboard then espData.Billboard.Enabled = false end
                end
            end
        end)
    end
end)

-- =============================================
-- MAIN EXECUTION
-- =============================================

local UI = createUI()

task.spawn(function()
    while ScriptActive do
        applyStats()
        task.wait(0.3)
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    applyStats()
    airJumpsLeft = Config.MaxAirJumps
    isGrounded = true
end)

task.wait(1)
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        createHighlightESP(player)
        player:GetPropertyChangedSignal("Team"):Connect(function()
            onTeamChanged(player)
        end)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        task.wait(1)
        createHighlightESP(player)
        player:GetPropertyChangedSignal("Team"):Connect(function()
            onTeamChanged(player)
        end)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player.Name] then
        pcall(function()
            if ESPObjects[player.Name].Billboard then
                ESPObjects[player.Name].Billboard:Destroy()
            end
            if ESPObjects[player.Name].Highlight then
                ESPObjects[player.Name].Highlight:Destroy()
            end
        end)
        ESPObjects[player.Name] = nil
    end
end)

print("")
print("╔══════════════════════════════════════╗")
print("║     UNIVERSAL ESP SCRIPT v1.0       ║")
print("╠══════════════════════════════════════╣")
print("║  ⚡ Speed: " .. Config.Speed .. "                      ║")
print("║  🦘 Jump: " .. Config.JumpPower .. " | Air: " .. Config.MaxAirJumps .. "   ║")
print("║  👁️  HIGHLIGHT ESP (1km)             ║")
print("║  📊 FPS: ENABLED                     ║")
print("║  📍 Scan Rate: 0.1s                  ║")
print("║  📏 Max Distance: 1000m              ║")
print("╠══════════════════════════════════════╣")
print("║  Works on ANY Roblox Game!          ║")
print("║  Click 'STOP' to terminate          ║")
print("╚══════════════════════════════════════╝")
print("")
