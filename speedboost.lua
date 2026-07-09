--[[
    UNIVERSAL ESP SCRIPT - Clean Standalone
    No external libraries, no TopbarPlus, pure standalone GUI
]]

repeat wait() until game:IsLoaded() and game.Players.LocalPlayer

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Camera = game:GetService("Workspace").CurrentCamera
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
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
    MaxESPDistance = 2000,
    Minimized = false
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
local CurrentBounty = "Searching..."
local selectedTab = 1

-- Clean up any existing GUI
pcall(function()
    if game.CoreGui:FindFirstChild("ESP_CleanGUI") then
        game.CoreGui.ESP_CleanGUI:Destroy()
    end
    if game.CoreGui:FindFirstChild("ESP_MinimizeText") then
        game.CoreGui.ESP_MinimizeText:Destroy()
    end
end)

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
-- BOUNTY SCANNER
-- =============================================
local function scanBounty()
    local bounty = nil
    pcall(function()
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats") or LocalPlayer:FindFirstChild("stats")
        if leaderstats then
            for _, stat in pairs(leaderstats:GetChildren()) do
                local name = string.lower(stat.Name)
                if string.find(name, "bounty") or string.find(name, "beli") then
                    if stat:IsA("IntValue") or stat:IsA("NumberValue") then
                        bounty = tostring(stat.Value)
                        break
                    end
                end
            end
        end
    end)
    return bounty
end

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
    if game.CoreGui:FindFirstChild("ESP_MinimizeText") then
        game.CoreGui.ESP_MinimizeText:Destroy()
    end
    
    for _, esp in pairs(ESPObjects) do
        if esp and esp.Billboard then esp.Billboard:Destroy() end
        if esp and esp.Highlight then esp.Highlight:Destroy() end
    end
    ESPObjects = {}
    
    for _, conn in pairs(espConnections) do
        conn:Disconnect()
    end
    espConnections = {}
    
    print("✓ ESP Terminated")
end

-- =============================================
-- CREATE MINIMAL STANDALONE GUI
-- =============================================
local function createUI()
    MainGUI = Instance.new("ScreenGui")
    MainGUI.Name = "ESP_CleanGUI"
    MainGUI.ResetOnSpawn = false
    MainGUI.IgnoreGuiInset = true
    MainGUI.Parent = game.CoreGui
    MainGUI.ZIndexBehavior = Enum.ZIndexBehavior.Global
    
    local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    local w = isMobile and 320 or 360
    local h = isMobile and 280 or 300
    
    -- Main Window
    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, w, 0, h)
    Main.Position = UDim2.new(0.5, -w/2, 0.5, -h/2)
    Main.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    Main.BorderSizePixel = 1
    Main.BorderColor3 = Color3.fromRGB(35, 35, 35)
    Main.ClipsDescendants = true
    Main.Parent = MainGUI
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Main
    
    -- Minimize Text Button
    local MinText = Instance.new("TextButton")
    MinText.Name = "ESP_MinimizeText"
    MinText.Size = UDim2.new(0, isMobile and 160 or 140, 0, isMobile and 36 or 30)
    MinText.Position = UDim2.new(0, 10, 0, isMobile and 110 or 80)
    MinText.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    MinText.BorderSizePixel = 1
    MinText.BorderColor3 = Color3.fromRGB(35, 35, 35)
    MinText.TextColor3 = Color3.fromRGB(0, 200, 255)
    MinText.Text = "👁️ Universal ESP"
    MinText.Font = Enum.Font.GothamBold
    MinText.TextSize = isMobile and 14 or 12
    MinText.AutoButtonColor = false
    MinText.Visible = false
    MinText.Active = true
    MinText.ZIndex = 20
    MinText.Parent = MainGUI
    
    local TextCorner = Instance.new("UICorner")
    TextCorner.CornerRadius = UDim.new(0, 6)
    TextCorner.Parent = MinText
    
    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, isMobile and 28 or 24)
    TitleBar.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = Main
    
    local TitleText = Instance.new("TextLabel")
    TitleText.Size = UDim2.new(1, -50, 1, 0)
    TitleText.Position = UDim2.new(0, 8, 0, 0)
    TitleText.BackgroundTransparency = 1
    TitleText.TextColor3 = Color3.fromRGB(0, 200, 255)
    TitleText.Text = "Universal ESP"
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Font = Enum.Font.GothamBold
    TitleText.TextSize = isMobile and 11 or 10
    TitleText.Parent = TitleBar
    
    -- Minimize Button
    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, isMobile and 22 or 20, 0, isMobile and 22 or 20)
    MinBtn.Position = UDim2.new(1, isMobile and -28 or -24, 0.5, isMobile and -11 or -10)
    MinBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    MinBtn.BorderSizePixel = 0
    MinBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    MinBtn.Text = "—"
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.TextSize = isMobile and 12 or 10
    MinBtn.AutoButtonColor = false
    MinBtn.Active = true
    MinBtn.ZIndex = 20
    MinBtn.Parent = TitleBar
    
    local MinCorner = Instance.new("UICorner")
    MinCorner.CornerRadius = UDim.new(0, 3)
    MinCorner.Parent = MinBtn
    
    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, isMobile and 22 or 20, 0, isMobile and 22 or 20)
    CloseBtn.Position = UDim2.new(1, isMobile and -6 or -4, 0.5, isMobile and -11 or -10)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    CloseBtn.BorderSizePixel = 0
    CloseBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
    CloseBtn.Text = "✕"
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = isMobile and 10 or 8
    CloseBtn.AutoButtonColor = false
    CloseBtn.Active = true
    CloseBtn.ZIndex = 20
    CloseBtn.Parent = TitleBar
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 3)
    CloseCorner.Parent = CloseBtn
    CloseBtn.Activated:Connect(terminateScript)
    
    -- Content
    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1, 0, 1, isMobile and -28 or -24)
    Content.Position = UDim2.new(0, 0, 0, isMobile and 28 or 24)
    Content.BackgroundTransparency = 1
    Content.Parent = Main
    
    -- Tab buttons
    local tabs = {"ESP", "Player", "Settings"}
    local tabIcons = {"👁️", "👤", "⚙️"}
    local tabButtons = {}
    local tabPanels = {}
    local th = isMobile and 24 or 20
    
    for i, name in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1/3, -1, 0, th)
        btn.Position = UDim2.new((i-1)/3, 1, 0, 2)
        btn.BackgroundColor3 = i == 1 and Color3.fromRGB(30, 30, 30) or Color3.fromRGB(15, 15, 15)
        btn.BorderSizePixel = 0
        btn.TextColor3 = i == 1 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(120, 120, 120)
        btn.Text = tabIcons[i] .. " " .. name
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = isMobile and 9 or 8
        btn.AutoButtonColor = false
        btn.Active = true
        btn.ZIndex = 10
        btn.Parent = Content
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 3)
        btnCorner.Parent = btn
        
        local panel = Instance.new("Frame")
        panel.Size = UDim2.new(1, 0, 1, -th - 4)
        panel.Position = UDim2.new(0, 0, 0, th + 4)
        panel.BackgroundTransparency = 1
        panel.Visible = (i == 1)
        panel.Parent = Content
        
        btn.Activated:Connect(function()
            for j = 1, #tabButtons do
                tabButtons[j].BackgroundColor3 = Color3.fromRGB(15, 15, 15)
                tabButtons[j].TextColor3 = Color3.fromRGB(120, 120, 120)
                tabPanels[j].Visible = false
            end
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            panel.Visible = true
            selectedTab = i
        end)
        
        table.insert(tabButtons, btn)
        table.insert(tabPanels, panel)
    end
    
    -- ===== ESP TAB =====
    local espPanel = tabPanels[1]
    
    local ESPStatus = Instance.new("TextLabel")
    ESPStatus.Size = UDim2.new(0.55, 0, 0, 16)
    ESPStatus.Position = UDim2.new(0, 8, 0, 4)
    ESPStatus.BackgroundTransparency = 1
    ESPStatus.TextColor3 = Color3.fromRGB(0, 255, 100)
    ESPStatus.Text = "● Active"
    ESPStatus.TextXAlignment = Enum.TextXAlignment.Left
    ESPStatus.Font = Enum.Font.GothamBold
    ESPStatus.TextSize = isMobile and 9 or 8
    ESPStatus.Parent = espPanel
    
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, isMobile and 55 or 50, 0, isMobile and 18 or 16)
    ToggleBtn.Position = UDim2.new(1, isMobile and -63 or -58, 0, 4)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    ToggleBtn.BorderSizePixel = 0
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleBtn.Text = "ON"
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.TextSize = isMobile and 8 or 7
    ToggleBtn.AutoButtonColor = false
    ToggleBtn.Active = true
    ToggleBtn.ZIndex = 10
    ToggleBtn.Parent = espPanel
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 3)
    ToggleCorner.Parent = ToggleBtn
    
    ToggleBtn.Activated:Connect(function()
        Config.ESPEnabled = not Config.ESPEnabled
        ToggleBtn.Text = Config.ESPEnabled and "ON" or "OFF"
        ToggleBtn.BackgroundColor3 = Config.ESPEnabled and Color3.fromRGB(30, 30, 30) or Color3.fromRGB(50, 20, 20)
        ESPStatus.Text = Config.ESPEnabled and "● Active" or "● Off"
        ESPStatus.TextColor3 = Config.ESPEnabled and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(150, 150, 150)
    end)
    
    local function makeLabel(parent, text, y, color)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -16, 0, 14)
        l.Position = UDim2.new(0, 8, 0, y)
        l.BackgroundTransparency = 1
        l.TextColor3 = color or Color3.fromRGB(180, 180, 180)
        l.Text = text
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Font = Enum.Font.GothamBold
        l.TextSize = isMobile and 9 or 8
        l.Parent = parent
        return l
    end
    
    makeLabel(espPanel, "⚡ Speed: " .. Config.Speed, 24, Color3.fromRGB(0, 200, 255))
    makeLabel(espPanel, "🦘 Jump: " .. Config.JumpPower, 40, Color3.fromRGB(100, 200, 255))
    makeLabel(espPanel, "🔄 Air: " .. Config.MaxAirJumps, 56, Color3.fromRGB(200, 200, 100))
    makeLabel(espPanel, "📏 Range: " .. Config.MaxESPDistance .. "m", 72, Color3.fromRGB(255, 200, 0))
    
    -- ===== PLAYER TAB =====
    local playerPanel = tabPanels[2]
    
    makeLabel(playerPanel, "👤 " .. LocalPlayer.Name, 4, Color3.fromRGB(255, 255, 255))
    local BountyLabel = makeLabel(playerPanel, "💰 Bounty: Searching...", 22, Color3.fromRGB(255, 200, 0))
    
    local sep = Instance.new("Frame")
    sep.Size = UDim2.new(1, -16, 0, 1)
    sep.Position = UDim2.new(0, 8, 0, 42)
    sep.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    sep.BorderSizePixel = 0
    sep.Parent = playerPanel
    
    makeLabel(playerPanel, "❤️ Health", 48, Color3.fromRGB(120, 120, 120))
    
    local HealthBg = Instance.new("Frame")
    HealthBg.Size = UDim2.new(1, -16, 0, 12)
    HealthBg.Position = UDim2.new(0, 8, 0, 64)
    HealthBg.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    HealthBg.BorderSizePixel = 0
    HealthBg.Parent = playerPanel
    
    local HealthCorner = Instance.new("UICorner")
    HealthCorner.CornerRadius = UDim.new(0, 3)
    HealthCorner.Parent = HealthBg
    
    local HealthFill = Instance.new("Frame")
    HealthFill.Size = UDim2.new(1, 0, 1, 0)
    HealthFill.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
    HealthFill.BorderSizePixel = 0
    HealthFill.Parent = HealthBg
    
    local HealthFillCorner = Instance.new("UICorner")
    HealthFillCorner.CornerRadius = UDim.new(0, 3)
    HealthFillCorner.Parent = HealthFill
    
    local HealthText = Instance.new("TextLabel")
    HealthText.Size = UDim2.new(1, 0, 1, 0)
    HealthText.BackgroundTransparency = 1
    HealthText.TextColor3 = Color3.fromRGB(255, 255, 255)
    HealthText.Text = "100%"
    HealthText.Font = Enum.Font.GothamBold
    HealthText.TextSize = 8
    HealthText.Parent = HealthFill
    
    local PlayerCount = makeLabel(playerPanel, "👥 Players: " .. #Players:GetPlayers(), 82, Color3.fromRGB(100, 255, 100))
    
    -- ===== SETTINGS TAB =====
    local settingsPanel = tabPanels[3]
    
    makeLabel(settingsPanel, "⚙️ Permanent Stats", 4, Color3.fromRGB(120, 120, 120))
    makeLabel(settingsPanel, "Speed: " .. Config.Speed, 20, Color3.fromRGB(0, 200, 255))
    makeLabel(settingsPanel, "Jump: " .. Config.JumpPower, 36, Color3.fromRGB(100, 200, 255))
    makeLabel(settingsPanel, "Air Jumps: " .. Config.MaxAirJumps, 52, Color3.fromRGB(200, 200, 100))
    makeLabel(settingsPanel, "Range: " .. Config.MaxESPDistance .. "m", 68, Color3.fromRGB(255, 200, 0))
    
    local sep2 = Instance.new("Frame")
    sep2.Size = UDim2.new(1, -16, 0, 1)
    sep2.Position = UDim2.new(0, 8, 0, 86)
    sep2.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    sep2.BorderSizePixel = 0
    sep2.Parent = settingsPanel
    
    -- Terminate Button
    local TermBtn = Instance.new("TextButton")
    TermBtn.Size = UDim2.new(1, -16, 0, isMobile and 28 or 24)
    TermBtn.Position = UDim2.new(0, 8, 0, 94)
    TermBtn.BackgroundColor3 = Color3.fromRGB(40, 15, 15)
    TermBtn.BorderSizePixel = 0
    TermBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    TermBtn.Text = "⚠️ Terminate Script"
    TermBtn.Font = Enum.Font.GothamBold
    TermBtn.TextSize = isMobile and 10 or 9
    TermBtn.AutoButtonColor = false
    TermBtn.Active = true
    TermBtn.ZIndex = 10
    TermBtn.Parent = settingsPanel
    
    local TermCorner = Instance.new("UICorner")
    TermCorner.CornerRadius = UDim.new(0, 3)
    TermCorner.Parent = TermBtn
    TermBtn.Activated:Connect(terminateScript)
    
    -- ===== Minimize Functions =====
    local function showMain()
        Main.Visible = true
        MinText.Visible = false
        Config.Minimized = false
    end
    
    local function showText()
        Main.Visible = false
        MinText.Visible = true
        Config.Minimized = true
    end
    
    MinBtn.Activated:Connect(showText)
    MinText.Activated:Connect(showMain)
    
    -- Text drag
    local textDragging = false
    local textDragStart, textStartPos, textMoved = false
    
    MinText.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            textDragging = true
            textMoved = false
            textDragStart = input.Position
            textStartPos = MinText.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if textDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - textDragStart
            if math.abs(delta.X) > 3 or math.abs(delta.Y) > 3 then textMoved = true end
            MinText.Position = UDim2.new(textStartPos.X.Scale, textStartPos.X.Offset + delta.X, textStartPos.Y.Scale, textStartPos.Y.Offset + delta.Y)
        end
    end)
    
    MinText.InputEnded:Connect(function(input)
        if textDragging then
            if not textMoved then showMain() end
            textDragging = false
        end
    end)
    
    -- Window drag
    local dragActive, dragInput, dragStart, startPos = false
    
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragActive = true
            dragStart = input.Position
            startPos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragActive = false end
            end)
        end
    end)
    
    TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    RunService.RenderStepped:Connect(function()
        if dragActive and dragInput then
            local delta = dragInput.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    return {
        Main = Main,
        MinText = MinText,
        BountyLabel = BountyLabel,
        HealthFill = HealthFill,
        HealthText = HealthText,
        PlayerCount = PlayerCount,
        ESPStatus = ESPStatus,
        ToggleBtn = ToggleBtn
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
-- ESP SYSTEM
-- =============================================
local function createHighlightESP(player)
    if player == LocalPlayer or not ScriptActive then return end
    
    if ESPObjects[player.Name] then
        pcall(function()
            if ESPObjects[player.Name].Billboard then ESPObjects[player.Name].Billboard:Destroy() end
            if ESPObjects[player.Name].Highlight then ESPObjects[player.Name].Highlight:Destroy() end
        end)
        ESPObjects[player.Name] = nil
    end
    
    local function addESP(character)
        if not character then return end
        local humanoid = character:WaitForChild("Humanoid", 5)
        local rootPart = character:WaitForChild("HumanoidRootPart", 5)
        local head = character:WaitForChild("Head", 5)
        if not humanoid or not rootPart or not head then return end
        
        local teamColor = getTeamColor(player)
        
        local highlight = Instance.new("Highlight")
        highlight.FillColor = teamColor
        highlight.OutlineColor = Color3.new(1, 1, 1)
        highlight.FillTransparency = 0.35
        highlight.OutlineTransparency = 0
        highlight.Enabled = true
        highlight.Parent = character
        
        local billboard = Instance.new("BillboardGui")
        billboard.Adornee = head
        billboard.Size = UDim2.new(0, 200, 0, 70)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Enabled = true
        billboard.Parent = character
        billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        local container = Instance.new("Frame", billboard)
        container.Size = UDim2.new(1, 0, 1, 0)
        container.BackgroundTransparency = 1
        
        local nameLabel = Instance.new("TextLabel", container)
        nameLabel.Size = UDim2.new(1, 0, 0, 18)
        nameLabel.Position = UDim2.new(0, 0, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.Name
        nameLabel.TextColor3 = teamColor
        nameLabel.TextSize = 18
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameLabel.TextXAlignment = Enum.TextXAlignment.Center
        
        local healthBg = Instance.new("Frame", container)
        healthBg.Size = UDim2.new(0.9, 0, 0, 10)
        healthBg.Position = UDim2.new(0.05, 0, 0.3, 0)
        healthBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        healthBg.BorderSizePixel = 1
        healthBg.BorderColor3 = Color3.fromRGB(0, 0, 0)
        local hCorner = Instance.new("UICorner", healthBg)
        hCorner.CornerRadius = UDim.new(0, 2)
        
        local healthFill = Instance.new("Frame", healthBg)
        healthFill.Size = UDim2.new(1, 0, 1, 0)
        healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        healthFill.BorderSizePixel = 0
        local hfCorner = Instance.new("UICorner", healthFill)
        hfCorner.CornerRadius = UDim.new(0, 2)
        
        local distLabel = Instance.new("TextLabel", container)
        distLabel.Size = UDim2.new(1, 0, 0, 14)
        distLabel.Position = UDim2.new(0, 0, 0.7, 0)
        distLabel.BackgroundTransparency = 1
        distLabel.Text = "0m"
        distLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        distLabel.TextSize = 12
        distLabel.Font = Enum.Font.GothamBold
        distLabel.TextXAlignment = Enum.TextXAlignment.Center
        distLabel.TextStrokeTransparency = 0.5
        distLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        
        ESPObjects[player.Name] = {
            Billboard = billboard,
            Highlight = highlight,
            HealthBarFill = healthFill,
            DistanceLabel = distLabel,
            Humanoid = humanoid,
            RootPart = rootPart
        }
    end
    
    if player.Character then addESP(player.Character) end
    local conn = player.CharacterAdded:Connect(function(character)
        task.wait(0.5)
        addESP(character)
    end)
    table.insert(espConnections, conn)
end

-- =============================================
-- TEAM CHANGE
-- =============================================
local function onTeamChanged(player)
    if player == LocalPlayer then return end
    local espData = ESPObjects[player.Name]
    if not espData then return end
    local teamColor = getTeamColor(player)
    if espData.Highlight then espData.Highlight.FillColor = teamColor end
end

-- =============================================
-- MAIN UPDATE LOOP
-- =============================================
task.spawn(function()
    while ScriptActive do
        task.wait(Config.ScanInterval or 0.1)
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
                if espData.Billboard then espData.Billboard.Adornee = head end
                if espData.Highlight then espData.Highlight.Parent = character end
                
                local dist = (Camera.CFrame.Position - rootPart.Position).Magnitude
                local inRange = dist <= Config.MaxESPDistance
                
                if inRange and Config.ESPEnabled then
                    if espData.Highlight then espData.Highlight.Enabled = true end
                    if espData.Billboard then espData.Billboard.Enabled = true end
                    local hp = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                    if espData.HealthBarFill then
                        espData.HealthBarFill.Size = UDim2.new(hp, 0, 1, 0)
                        espData.HealthBarFill.BackgroundColor3 = hp > 0.5 and Color3.fromRGB(0, 255, 0) or (hp > 0.25 and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(255, 0, 0))
                    end
                    if espData.DistanceLabel and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local d = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude)
                        espData.DistanceLabel.Text = d .. "m"
                        espData.DistanceLabel.TextColor3 = d < 50 and Color3.fromRGB(0, 255, 0) or (d < 150 and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(255, 100, 100))
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

-- Stats
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

-- FPS
task.spawn(function()
    local fc, last = 0, tick()
    while ScriptActive do
        fc = fc + 1
        if tick() - last >= 0.5 then
            local fps = math.floor(fc / (tick() - last))
            fc, last = 0, tick()
            if Config.ShowFPS then
                pcall(function()
                    if MainGUI and MainGUI.Parent then
                        local main = MainGUI:FindFirstChild("ESP_CleanGUI_Main") or MainGUI:FindFirstChildWhichIsA("Frame")
                        if main then
                            local tb = main:FindFirstChild("TitleBar")
                            if tb then
                                local fl = tb:FindFirstChild("FPSLabel")
                                if not fl then
                                    fl = Instance.new("TextLabel")
                                    fl.Name = "FPSLabel"
                                    fl.Size = UDim2.new(0, 50, 1, 0)
                                    fl.Position = UDim2.new(0, 65, 0, 0)
                                    fl.BackgroundTransparency = 1
                                    fl.TextXAlignment = Enum.TextXAlignment.Left
                                    fl.Font = Enum.Font.GothamBold
                                    fl.TextSize = UserInputService.TouchEnabled and 9 or 8
                                    fl.Parent = tb
                                end
                                fl.Text = "FPS: " .. fps
                                fl.TextColor3 = fps >= 50 and Color3.fromRGB(0, 255, 100) or (fps >= 25 and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 80, 80))
                            end
                        end
                    end
                end)
            end
        end
        task.wait()
    end
end)

-- Health
task.spawn(function()
    while ScriptActive do
        pcall(function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") and UI then
                local h = char.Humanoid
                local pct = math.clamp(h.Health / h.MaxHealth, 0, 1)
                UI.HealthFill.Size = UDim2.new(pct, 0, 1, 0)
                UI.HealthText.Text = math.floor(pct * 100) .. "%"
                UI.HealthFill.BackgroundColor3 = pct > 0.5 and Color3.fromRGB(60, 200, 60) or (pct > 0.25 and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 50, 50))
            end
        end)
        task.wait(0.3)
    end
end)

-- Bounty
task.spawn(function()
    while ScriptActive do
        local bounty = scanBounty()
        if UI and UI.BountyLabel then
            UI.BountyLabel.Text = bounty and "💰 Bounty: " .. bounty or "💰 Bounty: Not found"
        end
        task.wait(3)
    end
end)

-- Player count
task.spawn(function()
    while ScriptActive do
        if UI and UI.PlayerCount then
            UI.PlayerCount.Text = "👥 Players: " .. #Players:GetPlayers()
        end
        task.wait(1)
    end
end)

-- Init ESP
task.wait(1)
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        createHighlightESP(player)
        player:GetPropertyChangedSignal("Team"):Connect(function() onTeamChanged(player) end)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        task.wait(1)
        createHighlightESP(player)
        player:GetPropertyChangedSignal("Team"):Connect(function() onTeamChanged(player) end)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player.Name] then
        pcall(function()
            if ESPObjects[player.Name].Billboard then ESPObjects[player.Name].Billboard:Destroy() end
            if ESPObjects[player.Name].Highlight then ESPObjects[player.Name].Highlight:Destroy() end
        end)
        ESPObjects[player.Name] = nil
    end
end)

print("")
print("╔══════════════════════════════════════╗")
print("║     UNIVERSAL ESP SCRIPT            ║")
print("╠══════════════════════════════════════╣")
print("║  ⚡ Speed: " .. Config.Speed .. "                      ║")
print("║  🦘 Jump: " .. Config.JumpPower .. " | Air: " .. Config.MaxAirJumps .. "   ║")
print("║  👁️  HIGHLIGHT ESP                   ║")
print("║  📊 FPS: ENABLED                     ║")
print("║  📏 Range: " .. Config.MaxESPDistance .. "m              ║")
print("╠══════════════════════════════════════╣")
print("║  Standalone - No external libs      ║")
print("║  Click '—' to minimize              ║")
print("║  Tap text to restore                ║")
print("║  Click '✕' to terminate             ║")
print("╚══════════════════════════════════════╝")
print("")
