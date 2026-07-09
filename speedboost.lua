--[[
    SIMPLE ESP SCRIPT
    Highlight-based player detection + Speed Boost + Air Jump + FPS Counter
    No external links, no topbar, minimal GUI
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
local GuiService = game:GetService("GuiService")

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
    TEXT_SIZE = 18,
    TEXT_FONT = Enum.Font.GothamBold,
    TEXT_OUTLINE = true,
    HIGHLIGHT_ENABLED = true,
    MaxESPDistance = 2000
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
    
    print("✓ ESP Script Terminated")
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
-- CREATE MINIMAL GUI
-- =============================================
local function createUI()
    -- Create main GUI container - positioned at bottom center
    MainGUI = Instance.new("ScreenGui")
    MainGUI.Name = "SimpleESPUI"
    MainGUI.ResetOnSpawn = false
    MainGUI.Parent = game.CoreGui
    MainGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Main container - simple dark panel
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(0, 300, 0, 90)
    Container.Position = UDim2.new(0.5, -150, 1, -100)
    Container.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Container.BackgroundTransparency = 0.1
    Container.BorderSizePixel = 1
    Container.BorderColor3 = Color3.fromRGB(50, 50, 50)
    Container.Parent = MainGUI
    
    local ContainerCorner = Instance.new("UICorner")
    ContainerCorner.CornerRadius = UDim.new(0, 8)
    ContainerCorner.Parent = Container
    
    -- Speed label
    local SpeedLabel = Instance.new("TextLabel")
    SpeedLabel.Size = UDim2.new(0, 100, 0, 25)
    SpeedLabel.Position = UDim2.new(0.05, 0, 0.1, 0)
    SpeedLabel.BackgroundTransparency = 1
    SpeedLabel.Text = "⚡ " .. Config.Speed
    SpeedLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
    SpeedLabel.TextSize = 16
    SpeedLabel.Font = Enum.Font.GothamBold
    SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
    SpeedLabel.Parent = Container
    
    -- Jump label
    local JumpLabel = Instance.new("TextLabel")
    JumpLabel.Size = UDim2.new(0, 120, 0, 25)
    JumpLabel.Position = UDim2.new(0.37, 0, 0.1, 0)
    JumpLabel.BackgroundTransparency = 1
    JumpLabel.Text = "🦘 " .. Config.JumpPower
    JumpLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    JumpLabel.TextSize = 16
    JumpLabel.Font = Enum.Font.GothamBold
    JumpLabel.TextXAlignment = Enum.TextXAlignment.Left
    JumpLabel.Parent = Container
    
    -- Air jumps label
    local AirLabel = Instance.new("TextLabel")
    AirLabel.Size = UDim2.new(0, 70, 0, 25)
    AirLabel.Position = UDim2.new(0.67, 0, 0.1, 0)
    AirLabel.BackgroundTransparency = 1
    AirLabel.Text = "🔄 " .. Config.MaxAirJumps
    AirLabel.TextColor3 = Color3.fromRGB(200, 200, 100)
    AirLabel.TextSize = 16
    AirLabel.Font = Enum.Font.GothamBold
    AirLabel.TextXAlignment = Enum.TextXAlignment.Left
    AirLabel.Parent = Container
    
    -- FPS label
    local FPSLabel = Instance.new("TextLabel")
    FPSLabel.Size = UDim2.new(0, 80, 0, 25)
    FPSLabel.Position = UDim2.new(0.05, 0, 0.55, 0)
    FPSLabel.BackgroundTransparency = 1
    FPSLabel.Text = "FPS: 60"
    FPSLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    FPSLabel.TextSize = 15
    FPSLabel.Font = Enum.Font.GothamBold
    FPSLabel.TextXAlignment = Enum.TextXAlignment.Left
    FPSLabel.Parent = Container
    
    -- Player count label
    local PlayerCountLabel = Instance.new("TextLabel")
    PlayerCountLabel.Size = UDim2.new(0, 100, 0, 25)
    PlayerCountLabel.Position = UDim2.new(0.37, 0, 0.55, 0)
    PlayerCountLabel.BackgroundTransparency = 1
    PlayerCountLabel.Text = "👤 " .. #Players:GetPlayers()
    PlayerCountLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    PlayerCountLabel.TextSize = 15
    PlayerCountLabel.Font = Enum.Font.GothamBold
    PlayerCountLabel.TextXAlignment = Enum.TextXAlignment.Left
    PlayerCountLabel.Parent = Container
    
    -- Status indicator (simple dot)
    local StatusDot = Instance.new("Frame")
    StatusDot.Size = UDim2.new(0, 10, 0, 10)
    StatusDot.Position = UDim2.new(1, -20, 0.5, -5)
    StatusDot.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    StatusDot.BorderSizePixel = 0
    StatusDot.Parent = Container
    
    local DotCorner = Instance.new("UICorner")
    DotCorner.CornerRadius = UDim.new(0, 5)
    DotCorner.Parent = StatusDot
    
    -- Stop button (small X)
    local StopBtn = Instance.new("TextButton")
    StopBtn.Size = UDim2.new(0, 25, 0, 25)
    StopBtn.Position = UDim2.new(1, -30, 0.05, 0)
    StopBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
    StopBtn.BackgroundTransparency = 0.3
    StopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    StopBtn.Text = "✕"
    StopBtn.TextSize = 16
    StopBtn.Font = Enum.Font.GothamBold
    StopBtn.BorderSizePixel = 0
    StopBtn.Parent = Container
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 4)
    BtnCorner.Parent = StopBtn
    
    StopBtn.MouseEnter:Connect(function()
        TweenService:Create(StopBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
        TweenService:Create(StopBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 40, 40)}):Play()
    end)
    
    StopBtn.MouseLeave:Connect(function()
        TweenService:Create(StopBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.3}):Play()
        TweenService:Create(StopBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(200, 30, 30)}):Play()
    end)
    
    StopBtn.MouseButton1Click:Connect(terminateScript)
    
    -- Update FPS and player count
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
                
                PlayerCountLabel.Text = "👤 " .. #Players:GetPlayers()
            end)
            task.wait(1)
        end
    end)
    
    return {
        Container = Container,
        FPSLabel = FPSLabel,
        PlayerCountLabel = PlayerCountLabel,
        StatusDot = StatusDot
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
            highlight.FillTransparency = 0.35
            highlight.OutlineTransparency = 0
            highlight.Enabled = true
            highlight.Parent = character
        end
        
        -- Create Billboard GUI for name tag
        local billboard = Instance.new("BillboardGui")
        billboard.Adornee = head
        billboard.Size = UDim2.new(0, 200, 0, 70)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Enabled = true
        billboard.Parent = character
        billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        -- Container for all labels
        local mainContainer = Instance.new("Frame", billboard)
        mainContainer.Size = UDim2.new(1, 0, 1, 0)
        mainContainer.BackgroundTransparency = 1
        mainContainer.BorderSizePixel = 0
        
        -- Name label
        local nameLabel = Instance.new("TextLabel", mainContainer)
        nameLabel.Size = UDim2.new(1, 0, 0, 18)
        nameLabel.Position = UDim2.new(0, 0, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.Name
        nameLabel.TextColor3 = teamColor
        nameLabel.TextSize = Config.TEXT_SIZE
        nameLabel.Font = Config.TEXT_FONT
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameLabel.TextXAlignment = Enum.TextXAlignment.Center
        
        -- Health bar background
        local healthBarBg = Instance.new("Frame", mainContainer)
        healthBarBg.Size = UDim2.new(0.9, 0, 0, 10)
        healthBarBg.Position = UDim2.new(0.05, 0, 0.3, 0)
        healthBarBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        healthBarBg.BorderSizePixel = 1
        healthBarBg.BorderColor3 = Color3.fromRGB(0, 0, 0)
        local healthBgCorner = Instance.new("UICorner", healthBarBg)
        healthBgCorner.CornerRadius = UDim.new(0, 2)
        
        -- Health bar fill
        local healthBarFill = Instance.new("Frame", healthBarBg)
        healthBarFill.Size = UDim2.new(1, 0, 1, 0)
        healthBarFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        healthBarFill.BorderSizePixel = 0
        local healthFillCorner = Instance.new("UICorner", healthBarFill)
        healthFillCorner.CornerRadius = UDim.new(0, 2)
        
        -- Distance label
        local distanceLabel = Instance.new("TextLabel", mainContainer)
        distanceLabel.Size = UDim2.new(1, 0, 0, 14)
        distanceLabel.Position = UDim2.new(0, 0, 0.7, 0)
        distanceLabel.BackgroundTransparency = 1
        distanceLabel.Text = "0m"
        distanceLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        distanceLabel.TextSize = 12
        distanceLabel.Font = Enum.Font.GothamBold
        distanceLabel.TextXAlignment = Enum.TextXAlignment.Center
        distanceLabel.TextStrokeTransparency = 0.5
        distanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        
        ESPObjects[player.Name] = {
            Billboard = billboard,
            Highlight = highlight,
            NameLabel = nameLabel,
            HealthBarFill = healthBarFill,
            DistanceLabel = distanceLabel,
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
                
                -- Check distance
                local dist = (Camera.CFrame.Position - rootPart.Position).Magnitude
                local isInRange = dist <= Config.MaxESPDistance
                
                -- Show/hide based on range and ESP enabled
                if isInRange and Config.ESPEnabled then
                    if espData.Highlight then espData.Highlight.Enabled = true end
                    if espData.Billboard then espData.Billboard.Enabled = true end
                    
                    -- Update health bar
                    local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                    if espData.HealthBarFill then
                        espData.HealthBarFill.Size = UDim2.new(healthPercent, 0, 1, 0)
                    end
                    
                    -- Update health color based on percentage
                    if healthPercent > 0.5 then
                        if espData.HealthBarFill then espData.HealthBarFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0) end
                    elseif healthPercent > 0.25 then
                        if espData.HealthBarFill then espData.HealthBarFill.BackgroundColor3 = Color3.fromRGB(255, 255, 0) end
                    else
                        if espData.HealthBarFill then espData.HealthBarFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0) end
                    end
                    
                    -- Update distance
                    if espData.DistanceLabel and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local playerPos = LocalPlayer.Character.HumanoidRootPart.Position
                        local targetPos = rootPart.Position
                        local distance = math.floor((playerPos - targetPos).Magnitude)
                        
                        espData.DistanceLabel.Text = distance .. "m"
                        
                        -- Change distance color based on proximity
                        if distance < 50 then
                            espData.DistanceLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                        elseif distance < 150 then
                            espData.DistanceLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
                        else
                            espData.DistanceLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                        end
                    end
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

-- Simple startup message
print("✓ ESP Active | Speed: " .. Config.Speed .. " | Jump: " .. Config.JumpPower .. " | Air Jumps: " .. Config.MaxAirJumps)
