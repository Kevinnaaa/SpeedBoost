--[[
    UNIVERSAL ESP - Standalone Tabbed UI
    No external libraries, clean Rayfield-style interface
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
    MaxESPDistance = 2000,
    Minimized = false,
    Hidden = false
}

-- =============================================
-- VARIABLES
-- =============================================
local ScriptActive = true
local airJumpsLeft = 0
local ESPObjects = {}
local espConnections = {}
local MainGUI = nil
local UI = nil
local selectedTab = 1
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Clean up any existing GUI
pcall(function()
    if game.CoreGui:FindFirstChild("ESP_TabbedUI") then
        game.CoreGui.ESP_TabbedUI:Destroy()
    end
    if game.CoreGui:FindFirstChild("ESP_MinText") then
        game.CoreGui.ESP_MinText:Destroy()
    end
end)

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
    if game.CoreGui:FindFirstChild("ESP_MinText") then
        game.CoreGui.ESP_MinText:Destroy()
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
-- FPS COUNTER
-- =============================================
local function getFPS()
    local fps = Stats:FindFirstChild("PerformanceStats")
    if fps then
        local f = fps:FindFirstChild("FPS")
        if f then return math.floor(f.Value) end
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
        local ls = LocalPlayer:FindFirstChild("leaderstats") or LocalPlayer:FindFirstChild("stats")
        if ls then
            for _, stat in pairs(ls:GetChildren()) do
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
-- CREATE TABBED UI (RAYFIELD STYLE)
-- =============================================
local function createUI()
    MainGUI = Instance.new("ScreenGui")
    MainGUI.Name = "ESP_TabbedUI"
    MainGUI.ResetOnSpawn = false
    MainGUI.IgnoreGuiInset = true
    MainGUI.Parent = game.CoreGui
    MainGUI.ZIndexBehavior = Enum.ZIndexBehavior.Global
    
    local w = isMobile and 340 or 400
    local h = isMobile and 320 or 360
    
    -- Main Window
    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, w, 0, h)
    Main.Position = UDim2.new(0.5, -w/2, 0.5, -h/2)
    Main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Main.BorderSizePixel = 1
    Main.BorderColor3 = Color3.fromRGB(40, 40, 40)
    Main.ClipsDescendants = true
    Main.Parent = MainGUI
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Main
    
    -- Minimize Text Button
    local MinText = Instance.new("TextButton")
    MinText.Name = "ESP_MinText"
    MinText.Size = UDim2.new(0, isMobile and 160 or 140, 0, isMobile and 34 or 30)
    MinText.Position = UDim2.new(0, 10, 0, isMobile and 120 or 100)
    MinText.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    MinText.BorderSizePixel = 1
    MinText.BorderColor3 = Color3.fromRGB(40, 40, 40)
    MinText.TextColor3 = Color3.fromRGB(0, 200, 255)
    MinText.Text = "👁️ Universal ESP"
    MinText.Font = Enum.Font.GothamBold
    MinText.TextSize = isMobile and 14 or 12
    MinText.AutoButtonColor = false
    MinText.Visible = false
    MinText.Active = true
    MinText.ZIndex = 20
    MinText.Parent = MainGUI
    
    local TCorner = Instance.new("UICorner")
    TCorner.CornerRadius = UDim.new(0, 6)
    TCorner.Parent = MinText
    
    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, isMobile and 30 or 28)
    TitleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = Main
    
    -- Title
    local TitleText = Instance.new("TextLabel")
    TitleText.Size = UDim2.new(1, -65, 1, 0)
    TitleText.Position = UDim2.new(0, 10, 0, 0)
    TitleText.BackgroundTransparency = 1
    TitleText.TextColor3 = Color3.fromRGB(0, 200, 255)
    TitleText.Text = "Universal ESP"
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Font = Enum.Font.GothamBold
    TitleText.TextSize = isMobile and 12 or 11
    TitleText.Parent = TitleBar
    
    -- FPS in Title
    local FPSLabel = Instance.new("TextLabel")
    FPSLabel.Size = UDim2.new(0, 55, 1, 0)
    FPSLabel.Position = UDim2.new(0, 80, 0, 0)
    FPSLabel.BackgroundTransparency = 1
    FPSLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    FPSLabel.Text = "FPS: --"
    FPSLabel.TextXAlignment = Enum.TextXAlignment.Left
    FPSLabel.Font = Enum.Font.GothamBold
    FPSLabel.TextSize = isMobile and 10 or 9
    FPSLabel.Parent = TitleBar
    
    -- Minimize Button
    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, isMobile and 24 or 22, 0, isMobile and 24 or 22)
    MinBtn.Position = UDim2.new(1, isMobile and -30 or -28, 0.5, isMobile and -12 or -11)
    MinBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    MinBtn.BorderSizePixel = 0
    MinBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    MinBtn.Text = "—"
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.TextSize = isMobile and 12 or 10
    MinBtn.AutoButtonColor = false
    MinBtn.Active = true
    MinBtn.ZIndex = 20
    MinBtn.Parent = TitleBar
    
    local MCorner = Instance.new("UICorner")
    MCorner.CornerRadius = UDim.new(0, 3)
    MCorner.Parent = MinBtn
    
    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, isMobile and 24 or 22, 0, isMobile and 24 or 22)
    CloseBtn.Position = UDim2.new(1, isMobile and -6 or -5, 0.5, isMobile and -12 or -11)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    CloseBtn.BorderSizePixel = 0
    CloseBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
    CloseBtn.Text = "✕"
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = isMobile and 10 or 8
    CloseBtn.AutoButtonColor = false
    CloseBtn.Active = true
    CloseBtn.ZIndex = 20
    CloseBtn.Parent = TitleBar
    
    local CCorner = Instance.new("UICorner")
    CCorner.CornerRadius = UDim.new(0, 3)
    CCorner.Parent = CloseBtn
    CloseBtn.Activated:Connect(terminateScript)
    
    -- Content
    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1, 0, 1, isMobile and -30 or -28)
    Content.Position = UDim2.new(0, 0, 0, isMobile and 30 or 28)
    Content.BackgroundTransparency = 1
    Content.Parent = Main
    
    -- Tabs
    local tabs = {"ESP", "Player", "Settings"}
    local tabIcons = {"👁️", "👤", "⚙️"}
    local tabButtons = {}
    local tabPanels = {}
    local tabHeight = isMobile and 28 or 24
    
    for i, name in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1/3, -1, 0, tabHeight)
        btn.Position = UDim2.new((i-1)/3, 1, 0, 2)
        btn.BackgroundColor3 = i == 1 and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(22, 22, 22)
        btn.BorderSizePixel = 0
        btn.TextColor3 = i == 1 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 140, 140)
        btn.Text = tabIcons[i] .. " " .. name
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = isMobile and 10 or 9
        btn.AutoButtonColor = false
        btn.Active = true
        btn.ZIndex = 10
        btn.Parent = Content
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 3)
        btnCorner.Parent = btn
        
        local panel = Instance.new("Frame")
        panel.Size = UDim2.new(1, 0, 1, -tabHeight - 4)
        panel.Position = UDim2.new(0, 0, 0, tabHeight + 4)
        panel.BackgroundTransparency = 1
        panel.Visible = (i == 1)
        panel.Parent = Content
        
        btn.Activated:Connect(function()
            for j = 1, #tabButtons do
                tabButtons[j].BackgroundColor3 = Color3.fromRGB(22, 22, 22)
                tabButtons[j].TextColor3 = Color3.fromRGB(140, 140, 140)
                tabPanels[j].Visible = false
            end
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            panel.Visible = true
            selectedTab = i
        end)
        
        table.insert(tabButtons, btn)
        table.insert(tabPanels, panel)
    end
    
    -- =============================================
    -- ESP TAB
    -- =============================================
    local espPanel = tabPanels[1]
    
    -- ESP Status
    local ESPStatus = Instance.new("TextLabel")
    ESPStatus.Size = UDim2.new(0.5, 0, 0, 18)
    ESPStatus.Position = UDim2.new(0, 10, 0, 4)
    ESPStatus.BackgroundTransparency = 1
    ESPStatus.TextColor3 = Color3.fromRGB(0, 255, 100)
    ESPStatus.Text = "● ESP Active"
    ESPStatus.TextXAlignment = Enum.TextXAlignment.Left
    ESPStatus.Font = Enum.Font.GothamBold
    ESPStatus.TextSize = isMobile and 10 or 9
    ESPStatus.Parent = espPanel
    
    -- Toggle Button
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, isMobile and 55 or 50, 0, isMobile and 22 or 20)
    ToggleBtn.Position = UDim2.new(1, isMobile and -65 or -60, 0, 4)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    ToggleBtn.BorderSizePixel = 0
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleBtn.Text = "ON"
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.TextSize = isMobile and 9 or 8
    ToggleBtn.AutoButtonColor = false
    ToggleBtn.Active = true
    ToggleBtn.ZIndex = 10
    ToggleBtn.Parent = espPanel
    
    local TCorner2 = Instance.new("UICorner")
    TCorner2.CornerRadius = UDim.new(0, 3)
    TCorner2.Parent = ToggleBtn
    
    ToggleBtn.Activated:Connect(function()
        Config.ESPEnabled = not Config.ESPEnabled
        ToggleBtn.Text = Config.ESPEnabled and "ON" or "OFF"
        ToggleBtn.BackgroundColor3 = Config.ESPEnabled and Color3.fromRGB(35, 35, 35) or Color3.fromRGB(55, 20, 20)
        ESPStatus.Text = Config.ESPEnabled and "● ESP Active" or "● ESP Off"
        ESPStatus.TextColor3 = Config.ESPEnabled and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(150, 150, 150)
    end)
    
    -- Helper function
    local function label(parent, text, y, color)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -20, 0, 16)
        l.Position = UDim2.new(0, 10, 0, y)
        l.BackgroundTransparency = 1
        l.TextColor3 = color or Color3.fromRGB(180, 180, 180)
        l.Text = text
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Font = Enum.Font.GothamBold
        l.TextSize = isMobile and 10 or 9
        l.Parent = parent
        return l
    end
    
    label(espPanel, "⚡ Speed: " .. Config.Speed, 28, Color3.fromRGB(0, 200, 255))
    label(espPanel, "🦘 Jump: " .. Config.JumpPower, 46, Color3.fromRGB(100, 200, 255))
    label(espPanel, "🔄 Air Jumps: " .. Config.MaxAirJumps, 64, Color3.fromRGB(200, 200, 100))
    label(espPanel, "📏 Range: " .. Config.MaxESPDistance .. "m", 82, Color3.fromRGB(255, 200, 0))
    label(espPanel, "👥 Players: 0", 100, Color3.fromRGB(100, 255, 100))
    
    -- =============================================
    -- PLAYER TAB
    -- =============================================
    local playerPanel = tabPanels[2]
    
    label(playerPanel, "👤 " .. LocalPlayer.Name, 4, Color3.fromRGB(255, 255, 255))
    
    local BountyLabel = label(playerPanel, "💰 Bounty: Searching...", 22, Color3.fromRGB(255, 200, 0))
    
    -- Separator
    local Sep = Instance.new("Frame")
    Sep.Size = UDim2.new(1, -20, 0, 1)
    Sep.Position = UDim2.new(0, 10, 0, 42)
    Sep.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Sep.BorderSizePixel = 0
    Sep.Parent = playerPanel
    
    label(playerPanel, "❤️ Health", 48, Color3.fromRGB(120, 120, 120))
    
    -- Health Bar
    local HealthBg = Instance.new("Frame")
    HealthBg.Size = UDim2.new(1, -20, 0, 12)
    HealthBg.Position = UDim2.new(0, 10, 0, 64)
    HealthBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    HealthBg.BorderSizePixel = 0
    HealthBg.Parent = playerPanel
    
    local HCorner = Instance.new("UICorner")
    HCorner.CornerRadius = UDim.new(0, 3)
    HCorner.Parent = HealthBg
    
    local HealthFill = Instance.new("Frame")
    HealthFill.Size = UDim2.new(1, 0, 1, 0)
    HealthFill.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
    HealthFill.BorderSizePixel = 0
    HealthFill.Parent = HealthBg
    
    local HFCorner = Instance.new("UICorner")
    HFCorner.CornerRadius = UDim.new(0, 3)
    HFCorner.Parent = HealthFill
    
    local HealthText = Instance.new("TextLabel")
    HealthText.Size = UDim2.new(1, 0, 1, 0)
    HealthText.BackgroundTransparency = 1
    HealthText.TextColor3 = Color3.fromRGB(255, 255, 255)
    HealthText.Text = "100%"
    HealthText.Font = Enum.Font.GothamBold
    HealthText.TextSize = 8
    HealthText.Parent = HealthFill
    
    -- =============================================
    -- SETTINGS TAB
    -- =============================================
    local settingsPanel = tabPanels[3]
    
    label(settingsPanel, "⚙️ Permanent Stats", 4, Color3.fromRGB(120, 120, 120))
    label(settingsPanel, "Speed: " .. Config.Speed, 22, Color3.fromRGB(0, 200, 255))
    label(settingsPanel, "Jump: " .. Config.JumpPower, 40, Color3.fromRGB(100, 200, 255))
    label(settingsPanel, "Air Jumps: " .. Config.MaxAirJumps, 58, Color3.fromRGB(200, 200, 100))
    label(settingsPanel, "Range: " .. Config.MaxESPDistance .. "m", 76, Color3.fromRGB(255, 200, 0))
    
    -- Separator
    local Sep2 = Instance.new("Frame")
    Sep2.Size = UDim2.new(1, -20, 0, 1)
    Sep2.Position = UDim2.new(0, 10, 0, 96)
    Sep2.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Sep2.BorderSizePixel = 0
    Sep2.Parent = settingsPanel
    
    -- Terminate Button
    local TermBtn = Instance.new("TextButton")
    TermBtn.Size = UDim2.new(1, -20, 0, isMobile and 30 or 26)
    TermBtn.Position = UDim2.new(0, 10, 0, 104)
    TermBtn.BackgroundColor3 = Color3.fromRGB(45, 15, 15)
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
    
    -- =============================================
    -- MINIMIZE FUNCTIONS
    -- =============================================
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
    local textDragStart = nil
    local textStartPos = nil
    local textMoved = false
    
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
            if math.abs(delta.X) > 3 or math.abs(delta.Y) > 3 then
                textMoved = true
            end
            MinText.Position = UDim2.new(textStartPos.X.Scale, textStartPos.X.Offset + delta.X, textStartPos.Y.Scale, textStartPos.Y.Offset + delta.Y)
        end
    end)
    
    MinText.InputEnded:Connect(function(input)
        if textDragging then
            if not textMoved then
                showMain()
            end
            textDragging = false
        end
    end)
    
    -- Window drag
    local dragActive = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil
    
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragActive = true
            dragStart = input.Position
            startPos = Main.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragActive = false
                end
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
        FPSLabel = FPSLabel,
        BountyLabel = BountyLabel,
        HealthFill = HealthFill,
        HealthText = HealthText,
        ESPStatus = ESPStatus,
        ToggleBtn = ToggleBtn,
        PlayerCountLabel = espPanel:FindFirstChildWhichIsA("TextLabel") and espPanel:FindFirstChildWhichIsA("TextLabel") or nil
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
            local h = char.Humanoid
            h.WalkSpeed = Config.Speed
            h.JumpPower = Config.JumpPower
        end
    end)
end

UserInputService.JumpRequest:Connect(function()
    if not ScriptActive then return end
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local h = char:FindFirstChild("Humanoid")
        if not h then return end
        if h.FloorMaterial ~= Enum.Material.Air then
            airJumpsLeft = Config.MaxAirJumps
            return
        end
        if airJumpsLeft > 0 and h.FloorMaterial == Enum.Material.Air then
            h:ChangeState(Enum.HumanoidStateType.Jumping)
            airJumpsLeft = airJumpsLeft - 1
        end
    end)
end)

-- =============================================
-- ESP SYSTEM
-- =============================================
local function createESP(player)
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
        local h = character:FindFirstChild("Humanoid")
        local root = character:FindFirstChild("HumanoidRootPart")
        local head = character:FindFirstChild("Head")
        if not h or not root or not head then return end
        
        local color = getTeamColor(player)
        
        local highlight = Instance.new("Highlight")
        highlight.FillColor = color
        highlight.OutlineColor = Color3.new(1, 1, 1)
        highlight.FillTransparency = 0.35
        highlight.OutlineTransparency = 0
        highlight.Enabled = true
        highlight.Parent = character
        
        local billboard = Instance.new("BillboardGui")
        billboard.Adornee = head
        billboard.Size = UDim2.new(0, 180, 0, 60)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Enabled = true
        billboard.Parent = character
        
        local container = Instance.new("Frame", billboard)
        container.Size = UDim2.new(1, 0, 1, 0)
        container.BackgroundTransparency = 1
        
        local nameL = Instance.new("TextLabel", container)
        nameL.Size = UDim2.new(1, 0, 0, 16)
        nameL.Position = UDim2.new(0, 0, 0, 0)
        nameL.BackgroundTransparency = 1
        nameL.Text = player.Name
        nameL.TextColor3 = color
        nameL.TextSize = 16
        nameL.Font = Enum.Font.GothamBold
        nameL.TextStrokeTransparency = 0
        nameL.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameL.TextXAlignment = Enum.TextXAlignment.Center
        
        local healthBg = Instance.new("Frame", container)
        healthBg.Size = UDim2.new(0.9, 0, 0, 8)
        healthBg.Position = UDim2.new(0.05, 0, 0.3, 0)
        healthBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        healthBg.BorderSizePixel = 1
        healthBg.BorderColor3 = Color3.fromRGB(0, 0, 0)
        local c1 = Instance.new("UICorner", healthBg)
        c1.CornerRadius = UDim.new(0, 2)
        
        local healthFill = Instance.new("Frame", healthBg)
        healthFill.Size = UDim2.new(1, 0, 1, 0)
        healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        healthFill.BorderSizePixel = 0
        local c2 = Instance.new("UICorner", healthFill)
        c2.CornerRadius = UDim.new(0, 2)
        
        local distL = Instance.new("TextLabel", container)
        distL.Size = UDim2.new(1, 0, 0, 12)
        distL.Position = UDim2.new(0, 0, 0.6, 0)
        distL.BackgroundTransparency = 1
        distL.Text = "0m"
        distL.TextColor3 = Color3.fromRGB(255, 200, 0)
        distL.TextSize = 11
        distL.Font = Enum.Font.GothamBold
        distL.TextXAlignment = Enum.TextXAlignment.Center
        distL.TextStrokeTransparency = 0.5
        distL.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        
        ESPObjects[player.Name] = {
            Billboard = billboard,
            Highlight = highlight,
            HealthFill = healthFill,
            DistLabel = distL,
            Humanoid = h,
            RootPart = root
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
-- TEAM CHANGE
-- =============================================
local function onTeamChanged(player)
    if player == LocalPlayer then return end
    local esp = ESPObjects[player.Name]
    if esp and esp.Highlight then
        esp.Highlight.FillColor = getTeamColor(player)
    end
end

-- =============================================
-- MAIN ESP UPDATE LOOP
-- =============================================
task.spawn(function()
    while ScriptActive do
        task.wait(0.15)
        pcall(function()
            for name, esp in pairs(ESPObjects) do
                if not esp or not esp.Highlight then continue end
                local p = Players:FindFirstChild(name)
                if not p then
                    if esp.Billboard then esp.Billboard:Destroy() end
                    if esp.Highlight then esp.Highlight:Destroy() end
                    ESPObjects[name] = nil
                    continue
                end
                local char = p.Character
                if not char then
                    if esp.Highlight then esp.Highlight.Enabled = false end
                    if esp.Billboard then esp.Billboard.Enabled = false end
                    continue
                end
                local root = char:FindFirstChild("HumanoidRootPart")
                local h = char:FindFirstChild("Humanoid")
                local head = char:FindFirstChild("Head")
                if not root or not h or not head then
                    if esp.Highlight then esp.Highlight.Enabled = false end
                    if esp.Billboard then esp.Billboard.Enabled = false end
                    continue
                end
                if esp.Billboard then esp.Billboard.Adornee = head end
                if esp.Highlight then esp.Highlight.Parent = char end
                
                local dist = (Camera.CFrame.Position - root.Position).Magnitude
                local inRange = dist <= Config.MaxESPDistance
                
                if inRange and Config.ESPEnabled then
                    if esp.Highlight then esp.Highlight.Enabled = true end
                    if esp.Billboard then esp.Billboard.Enabled = true end
                    local hp = math.clamp(h.Health / h.MaxHealth, 0, 1)
                    if esp.HealthFill then
                        esp.HealthFill.Size = UDim2.new(hp, 0, 1, 0)
                        esp.HealthFill.BackgroundColor3 = hp > 0.5 and Color3.fromRGB(0, 255, 0) or (hp > 0.25 and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(255, 0, 0))
                    end
                    if esp.DistLabel and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local d = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude)
                        esp.DistLabel.Text = d .. "m"
                        esp.DistLabel.TextColor3 = d < 50 and Color3.fromRGB(0, 255, 0) or (d < 150 and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(255, 100, 100))
                    end
                else
                    if esp.Highlight then esp.Highlight.Enabled = false end
                    if esp.Billboard then esp.Billboard.Enabled = false end
                end
            end
        end)
    end
end)

-- =============================================
-- MAIN EXECUTION
-- =============================================

UI = createUI()

-- Apply stats
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
end)

-- FPS update
task.spawn(function()
    local fc = 0
    local last = tick()
    while ScriptActive do
        fc = fc + 1
        if tick() - last >= 0.5 then
            local fps = math.floor(fc / (tick() - last))
            fc = 0
            last = tick()
            if UI and UI.FPSLabel then
                UI.FPSLabel.Text = "FPS: " .. fps
                UI.FPSLabel.TextColor3 = fps >= 50 and Color3.fromRGB(0, 255, 100) or (fps >= 25 and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 80, 80))
            end
        end
        task.wait()
    end
end)

-- Health update
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

-- Bounty update
task.spawn(function()
    while ScriptActive do
        local bounty = scanBounty()
        if UI and UI.BountyLabel then
            UI.BountyLabel.Text = bounty and "💰 Bounty: " .. bounty or "💰 Bounty: Not found"
        end
        task.wait(3)
    end
end)

-- Player count update
task.spawn(function()
    while ScriptActive do
        if UI and UI.PlayerCountLabel then
            -- Find the player count label in ESP tab
            for _, child in pairs(UI.PlayerCountLabel.Parent:GetChildren()) do
                if child:IsA("TextLabel") and string.find(child.Text, "👥 Players:") then
                    child.Text = "👥 Players: " .. #Players:GetPlayers()
                end
            end
        end
        task.wait(1)
    end
end)

-- Initialize ESP
task.wait(1)
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        createESP(p)
        p:GetPropertyChangedSignal("Team"):Connect(function() onTeamChanged(p) end)
    end
end

Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then
        task.wait(1)
        createESP(p)
        p:GetPropertyChangedSignal("Team"):Connect(function() onTeamChanged(p) end)
    end
end)

Players.PlayerRemoving:Connect(function(p)
    if ESPObjects[p.Name] then
        pcall(function()
            if ESPObjects[p.Name].Billboard then ESPObjects[p.Name].Billboard:Destroy() end
            if ESPObjects[p.Name].Highlight then ESPObjects[p.Name].Highlight:Destroy() end
        end)
        ESPObjects[p.Name] = nil
    end
end)

print("")
print("╔══════════════════════════════════════╗")
print("║     UNIVERSAL ESP - Tabbed UI       ║")
print("╠══════════════════════════════════════╣")
print("║  ⚡ Speed: " .. Config.Speed .. "                      ║")
print("║  🦘 Jump: " .. Config.JumpPower .. " | Air: " .. Config.MaxAirJumps .. "   ║")
print("║  👁️  ESP Active                      ║")
print("║  📏 Range: " .. Config.MaxESPDistance .. "m              ║")
print("╠══════════════════════════════════════╣")
print("║  Zero Dependencies - Pure Standalone║")
print("║  Tabbed UI (ESP | Player | Settings)║")
print("║  Click '—' to minimize              ║")
print("║  Click '✕' to terminate             ║")
print("╚══════════════════════════════════════╝")
print("")
