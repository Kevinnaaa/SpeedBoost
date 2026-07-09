--[[
    UNIVERSAL ESP - Professional Edition
    Complete standalone - No dependencies
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

-- CONFIG
local Config = {
    Speed = 100,
    JumpPower = 80,
    MaxAirJumps = 5,
    ESPEnabled = true,
    MaxESPDistance = 2000
}

-- VARIABLES
local ScriptActive = true
local airJumpsLeft = 0
local ESPObjects = {}
local espConnections = {}
local MainGUI = nil
local selectedTab = 1
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Clean up any existing GUI
pcall(function()
    if game.CoreGui:FindFirstChild("ESP_Professional") then
        game.CoreGui.ESP_Professional:Destroy()
    end
    if game.CoreGui:FindFirstChild("ESP_MinText") then
        game.CoreGui.ESP_MinText:Destroy()
    end
end)

-- TERMINATE
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

-- FPS
local function getFPS()
    local fps = Stats:FindFirstChild("PerformanceStats")
    if fps then
        local f = fps:FindFirstChild("FPS")
        if f then return math.floor(f.Value) end
    end
    return 0
end

-- TEAM COLOR
local function getTeamColor(player)
    if player.Team then
        return player.Team.TeamColor.Color
    end
    return Color3.fromRGB(0, 150, 255)
end

-- BOUNTY
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
-- CREATE PROFESSIONAL UI
-- =============================================
local function createUI()
    MainGUI = Instance.new("ScreenGui")
    MainGUI.Name = "ESP_Professional"
    MainGUI.ResetOnSpawn = false
    MainGUI.IgnoreGuiInset = true
    MainGUI.Parent = game.CoreGui
    MainGUI.ZIndexBehavior = Enum.ZIndexBehavior.Global
    
    local w = isMobile and 340 or 400
    local h = isMobile and 380 or 420
    
    -- Main Window
    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, w, 0, h)
    Main.Position = UDim2.new(0.5, -w/2, 0.5, -h/2)
    Main.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
    Main.BorderSizePixel = 1
    Main.BorderColor3 = Color3.fromRGB(50, 50, 65)
    Main.ClipsDescendants = true
    Main.Parent = MainGUI
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 10)
    MainCorner.Parent = Main
    
    -- Glow Border
    local Glow = Instance.new("Frame")
    Glow.Size = UDim2.new(1, 6, 1, 6)
    Glow.Position = UDim2.new(0, -3, 0, -3)
    Glow.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
    Glow.BackgroundTransparency = 0.85
    Glow.BorderSizePixel = 0
    Glow.Parent = Main
    
    local GlowCorner = Instance.new("UICorner")
    GlowCorner.CornerRadius = UDim.new(0, 13)
    GlowCorner.Parent = Glow
    
    -- Minimize Text
    local MinText = Instance.new("TextButton")
    MinText.Name = "ESP_MinText"
    MinText.Size = UDim2.new(0, isMobile and 160 or 140, 0, isMobile and 36 or 32)
    MinText.Position = UDim2.new(0, 10, 0, isMobile and 150 or 130)
    MinText.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
    MinText.BorderSizePixel = 1
    MinText.BorderColor3 = Color3.fromRGB(50, 50, 65)
    MinText.TextColor3 = Color3.fromRGB(0, 200, 255)
    MinText.Text = "👁️ Universal ESP"
    MinText.Font = Enum.Font.GothamBold
    MinText.TextSize = isMobile and 14 or 12
    MinText.AutoButtonColor = false
    MinText.Visible = false
    MinText.Parent = MainGUI
    
    local MinTextCorner = Instance.new("UICorner")
    MinTextCorner.CornerRadius = UDim.new(0, 8)
    MinTextCorner.Parent = MinText
    
    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, isMobile and 34 or 30)
    TitleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = Main
    
    local TitleBarCorner = Instance.new("UICorner")
    TitleBarCorner.CornerRadius = UDim.new(0, 10)
    TitleBarCorner.Parent = TitleBar
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -70, 1, 0)
    Title.Position = UDim2.new(0, 12, 0, 0)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = Color3.fromRGB(0, 200, 255)
    Title.Text = "Universal ESP"
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = isMobile and 13 or 12
    Title.Parent = TitleBar
    
    -- FPS
    local FPSLabel = Instance.new("TextLabel")
    FPSLabel.Size = UDim2.new(0, 55, 1, 0)
    FPSLabel.Position = UDim2.new(0, 85, 0, 0)
    FPSLabel.BackgroundTransparency = 1
    FPSLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    FPSLabel.Text = "FPS: --"
    FPSLabel.TextXAlignment = Enum.TextXAlignment.Left
    FPSLabel.Font = Enum.Font.GothamBold
    FPSLabel.TextSize = isMobile and 10 or 9
    FPSLabel.Parent = TitleBar
    
    -- Min Button
    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, isMobile and 24 or 22, 0, isMobile and 24 or 22)
    MinBtn.Position = UDim2.new(1, isMobile and -34 or -30, 0.5, isMobile and -12 or -11)
    MinBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    MinBtn.BorderSizePixel = 0
    MinBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    MinBtn.Text = "—"
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.TextSize = isMobile and 14 or 12
    MinBtn.AutoButtonColor = false
    MinBtn.Parent = TitleBar
    
    local MinBtnCorner = Instance.new("UICorner")
    MinBtnCorner.CornerRadius = UDim.new(0, 4)
    MinBtnCorner.Parent = MinBtn
    
    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, isMobile and 24 or 22, 0, isMobile and 24 or 22)
    CloseBtn.Position = UDim2.new(1, isMobile and -8 or -6, 0.5, isMobile and -12 or -11)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    CloseBtn.BorderSizePixel = 0
    CloseBtn.TextColor3 = Color3.fromRGB(255, 60, 60)
    CloseBtn.Text = "✕"
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = isMobile and 11 or 9
    CloseBtn.AutoButtonColor = false
    CloseBtn.Parent = TitleBar
    
    local CloseBtnCorner = Instance.new("UICorner")
    CloseBtnCorner.CornerRadius = UDim.new(0, 4)
    CloseBtnCorner.Parent = CloseBtn
    
    -- Fix: Use MouseButton1Click instead of Activated
    CloseBtn.MouseButton1Click:Connect(terminateScript)
    
    -- Content
    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1, 0, 1, isMobile and -34 or -30)
    Content.Position = UDim2.new(0, 0, 0, isMobile and 34 or 30)
    Content.BackgroundTransparency = 1
    Content.Parent = Main
    
    -- Tabs
    local tabs = {"ESP", "Player", "Settings"}
    local tabIcons = {"👁️", "👤", "⚙️"}
    local tabButtons = {}
    local tabPanels = {}
    local tabHeight = isMobile and 32 or 28
    
    for i, name in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1/3, -2, 0, tabHeight)
        btn.Position = UDim2.new((i-1)/3, 1, 0, 4)
        btn.BackgroundColor3 = i == 1 and Color3.fromRGB(50, 50, 65) or Color3.fromRGB(25, 25, 35)
        btn.BorderSizePixel = 0
        btn.TextColor3 = i == 1 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 170)
        btn.Text = tabIcons[i] .. " " .. name
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = isMobile and 11 or 10
        btn.AutoButtonColor = false
        btn.Parent = Content
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = btn
        
        local panel = Instance.new("Frame")
        panel.Size = UDim2.new(1, 0, 1, -tabHeight - 8)
        panel.Position = UDim2.new(0, 0, 0, tabHeight + 8)
        panel.BackgroundTransparency = 1
        panel.Visible = (i == 1)
        panel.Parent = Content
        
        -- Fix: Use MouseButton1Click instead of Activated
        btn.MouseButton1Click:Connect(function()
            for j = 1, #tabButtons do
                tabButtons[j].BackgroundColor3 = Color3.fromRGB(25, 25, 35)
                tabButtons[j].TextColor3 = Color3.fromRGB(150, 150, 170)
                tabPanels[j].Visible = false
            end
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
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
    
    -- Status Bar
    local StatusBg = Instance.new("Frame")
    StatusBg.Size = UDim2.new(1, -20, 0, isMobile and 32 or 28)
    StatusBg.Position = UDim2.new(0, 10, 0, 4)
    StatusBg.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    StatusBg.BorderSizePixel = 0
    StatusBg.Parent = espPanel
    
    local StatusCorner = Instance.new("UICorner")
    StatusCorner.CornerRadius = UDim.new(0, 4)
    StatusCorner.Parent = StatusBg
    
    local Status = Instance.new("TextLabel")
    Status.Size = UDim2.new(0.5, 0, 1, 0)
    Status.Position = UDim2.new(0, 12, 0, 0)
    Status.BackgroundTransparency = 1
    Status.TextColor3 = Color3.fromRGB(0, 255, 100)
    Status.Text = "● ESP Active"
    Status.TextXAlignment = Enum.TextXAlignment.Left
    Status.Font = Enum.Font.GothamBold
    Status.TextSize = isMobile and 10 or 9
    Status.Parent = StatusBg
    
    local Toggle = Instance.new("TextButton")
    Toggle.Size = UDim2.new(0, isMobile and 55 or 50, 0, isMobile and 22 or 20)
    Toggle.Position = UDim2.new(1, isMobile and -62 or -56, 0.5, isMobile and -11 or -10)
    Toggle.BackgroundColor3 = Color3.fromRGB(40, 200, 60)
    Toggle.BorderSizePixel = 0
    Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    Toggle.Text = "ON"
    Toggle.Font = Enum.Font.GothamBold
    Toggle.TextSize = isMobile and 9 or 8
    Toggle.AutoButtonColor = false
    Toggle.Parent = StatusBg
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 4)
    ToggleCorner.Parent = Toggle
    
    -- Fix: Use MouseButton1Click instead of Activated
    Toggle.MouseButton1Click:Connect(function()
        Config.ESPEnabled = not Config.ESPEnabled
        Toggle.Text = Config.ESPEnabled and "ON" or "OFF"
        Toggle.BackgroundColor3 = Config.ESPEnabled and Color3.fromRGB(40, 200, 60) or Color3.fromRGB(180, 40, 40)
        Status.Text = Config.ESPEnabled and "● ESP Active" or "● ESP Off"
        Status.TextColor3 = Config.ESPEnabled and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(180, 80, 80)
    end)
    
    -- Stats Boxes
    local function statBox(parent, icon, text, y, color)
        local box = Instance.new("Frame")
        box.Size = UDim2.new(1, -20, 0, isMobile and 28 or 24)
        box.Position = UDim2.new(0, 10, 0, y)
        box.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
        box.BorderSizePixel = 0
        box.Parent = parent
        
        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = UDim.new(0, 4)
        boxCorner.Parent = box
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -16, 1, 0)
        label.Position = UDim2.new(0, 8, 0, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = color or Color3.fromRGB(200, 200, 210)
        label.Text = icon .. " " .. text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.GothamBold
        label.TextSize = isMobile and 10 or 9
        label.Parent = box
        
        return label
    end
    
    statBox(espPanel, "⚡", "Speed: " .. Config.Speed, 42, Color3.fromRGB(0, 200, 255))
    statBox(espPanel, "🦘", "Jump: " .. Config.JumpPower, 74, Color3.fromRGB(100, 200, 255))
    statBox(espPanel, "🔄", "Air Jumps: " .. Config.MaxAirJumps, 106, Color3.fromRGB(200, 200, 100))
    statBox(espPanel, "📏", "Range: " .. Config.MaxESPDistance .. "m", 138, Color3.fromRGB(255, 200, 0))
    
    local PlayerCountBox = statBox(espPanel, "👥", "Players: 0", 170, Color3.fromRGB(100, 255, 100))
    
    -- =============================================
    -- PLAYER TAB
    -- =============================================
    local playerPanel = tabPanels[2]
    
    -- Player Name
    local NameBg = Instance.new("Frame")
    NameBg.Size = UDim2.new(1, -20, 0, isMobile and 36 or 32)
    NameBg.Position = UDim2.new(0, 10, 0, 4)
    NameBg.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    NameBg.BorderSizePixel = 0
    NameBg.Parent = playerPanel
    
    local NameCorner = Instance.new("UICorner")
    NameCorner.CornerRadius = UDim.new(0, 4)
    NameCorner.Parent = NameBg
    
    local PlayerName = Instance.new("TextLabel")
    PlayerName.Size = UDim2.new(1, -16, 1, 0)
    PlayerName.Position = UDim2.new(0, 12, 0, 0)
    PlayerName.BackgroundTransparency = 1
    PlayerName.TextColor3 = Color3.fromRGB(255, 255, 255)
    PlayerName.Text = "👤 " .. LocalPlayer.Name
    PlayerName.TextXAlignment = Enum.TextXAlignment.Left
    PlayerName.Font = Enum.Font.GothamBold
    PlayerName.TextSize = isMobile and 12 or 11
    PlayerName.Parent = NameBg
    
    -- Bounty
    local BountyBg = Instance.new("Frame")
    BountyBg.Size = UDim2.new(1, -20, 0, isMobile and 36 or 32)
    BountyBg.Position = UDim2.new(0, 10, 0, 44)
    BountyBg.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    BountyBg.BorderSizePixel = 0
    BountyBg.Parent = playerPanel
    
    local BountyCorner = Instance.new("UICorner")
    BountyCorner.CornerRadius = UDim.new(0, 4)
    BountyCorner.Parent = BountyBg
    
    local Bounty = Instance.new("TextLabel")
    Bounty.Size = UDim2.new(1, -16, 1, 0)
    Bounty.Position = UDim2.new(0, 12, 0, 0)
    Bounty.BackgroundTransparency = 1
    Bounty.TextColor3 = Color3.fromRGB(255, 200, 0)
    Bounty.Text = "💰 Bounty: Searching..."
    Bounty.TextXAlignment = Enum.TextXAlignment.Left
    Bounty.Font = Enum.Font.GothamBold
    Bounty.TextSize = isMobile and 11 or 10
    Bounty.Parent = BountyBg
    
    -- Health Section
    local HealthLabel = Instance.new("TextLabel")
    HealthLabel.Size = UDim2.new(1, -20, 0, 16)
    HealthLabel.Position = UDim2.new(0, 10, 0, 88)
    HealthLabel.BackgroundTransparency = 1
    HealthLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
    HealthLabel.Text = "❤️ Health"
    HealthLabel.TextXAlignment = Enum.TextXAlignment.Left
    HealthLabel.Font = Enum.Font.GothamBold
    HealthLabel.TextSize = isMobile and 10 or 9
    HealthLabel.Parent = playerPanel
    
    -- Health Bar
    local Hbg = Instance.new("Frame")
    Hbg.Size = UDim2.new(1, -20, 0, isMobile and 16 or 14)
    Hbg.Position = UDim2.new(0, 10, 0, 108)
    Hbg.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    Hbg.BorderSizePixel = 0
    Hbg.Parent = playerPanel
    
    local HCorner = Instance.new("UICorner")
    HCorner.CornerRadius = UDim.new(0, 4)
    HCorner.Parent = Hbg
    
    local Hfill = Instance.new("Frame")
    Hfill.Size = UDim2.new(1, 0, 1, 0)
    Hfill.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
    Hfill.BorderSizePixel = 0
    Hfill.Parent = Hbg
    
    local HfCorner = Instance.new("UICorner")
    HfCorner.CornerRadius = UDim.new(0, 4)
    HfCorner.Parent = Hfill
    
    local Htext = Instance.new("TextLabel")
    Htext.Size = UDim2.new(1, 0, 1, 0)
    Htext.BackgroundTransparency = 1
    Htext.TextColor3 = Color3.fromRGB(255, 255, 255)
    Htext.Text = "100%"
    Htext.Font = Enum.Font.GothamBold
    Htext.TextSize = isMobile and 9 or 8
    Htext.Parent = Hfill
    
    -- =============================================
    -- SETTINGS TAB
    -- =============================================
    local settingsPanel = tabPanels[3]
    
    -- Stats Section
    local SettingsLabel = Instance.new("TextLabel")
    SettingsLabel.Size = UDim2.new(1, -20, 0, 16)
    SettingsLabel.Position = UDim2.new(0, 10, 0, 4)
    SettingsLabel.BackgroundTransparency = 1
    SettingsLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
    SettingsLabel.Text = "⚙️ Permanent Stats"
    SettingsLabel.TextXAlignment = Enum.TextXAlignment.Left
    SettingsLabel.Font = Enum.Font.GothamBold
    SettingsLabel.TextSize = isMobile and 10 or 9
    SettingsLabel.Parent = settingsPanel
    
    local statY = 24
    local settingsStats = {
        {text = "Walk Speed: " .. Config.Speed, color = Color3.fromRGB(0, 200, 255)},
        {text = "Jump Power: " .. Config.JumpPower, color = Color3.fromRGB(100, 200, 255)},
        {text = "Air Jumps: " .. Config.MaxAirJumps, color = Color3.fromRGB(200, 200, 100)},
        {text = "ESP Range: " .. Config.MaxESPDistance .. "m", color = Color3.fromRGB(255, 200, 0)}
    }
    
    for _, stat in ipairs(settingsStats) do
        local box = Instance.new("Frame")
        box.Size = UDim2.new(1, -20, 0, isMobile and 24 or 20)
        box.Position = UDim2.new(0, 10, 0, statY)
        box.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
        box.BorderSizePixel = 0
        box.Parent = settingsPanel
        
        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = UDim.new(0, 4)
        boxCorner.Parent = box
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -16, 1, 0)
        label.Position = UDim2.new(0, 8, 0, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = stat.color
        label.Text = stat.text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.GothamBold
        label.TextSize = isMobile and 9 or 8
        label.Parent = box
        
        statY = statY + (isMobile and 28 or 24)
    end
    
    -- Buttons
    local function createButton(parent, text, y, color, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -20, 0, isMobile and 32 or 28)
        btn.Position = UDim2.new(0, 10, 0, y)
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        btn.BorderSizePixel = 0
        btn.TextColor3 = color or Color3.fromRGB(255, 255, 255)
        btn.Text = text
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = isMobile and 10 or 9
        btn.AutoButtonColor = false
        btn.Parent = parent
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = btn
        
        -- Fix: Use MouseButton1Click instead of Activated
        btn.MouseButton1Click:Connect(callback)
        
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 55)}):Play()
        end)
        
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 45)}):Play()
        end)
        
        return btn
    end
    
    createButton(settingsPanel, "🔄 Toggle ESP", statY + 8, Color3.fromRGB(100, 200, 255), function()
        Config.ESPEnabled = not Config.ESPEnabled
        Toggle.Text = Config.ESPEnabled and "ON" or "OFF"
        Toggle.BackgroundColor3 = Config.ESPEnabled and Color3.fromRGB(40, 200, 60) or Color3.fromRGB(180, 40, 40)
        Status.Text = Config.ESPEnabled and "● ESP Active" or "● ESP Off"
        Status.TextColor3 = Config.ESPEnabled and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(180, 80, 80)
    end)
    
    local btnY = statY + (isMobile and 44 or 40)
    createButton(settingsPanel, "⚠️ Terminate Script", btnY, Color3.fromRGB(255, 80, 80), terminateScript)
    
    -- =============================================
    -- MINIMIZE FUNCTIONS
    -- =============================================
    local function showMain()
        Main.Visible = true
        MinText.Visible = false
    end
    
    local function showText()
        Main.Visible = false
        MinText.Visible = true
    end
    
    -- Fix: Use MouseButton1Click instead of Activated
    MinBtn.MouseButton1Click:Connect(showText)
    MinText.MouseButton1Click:Connect(showMain)
    
    -- Text drag
    local td, tds, tsp, tm = false
    
    MinText.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            td = true
            tm = false
            tds = input.Position
            tsp = MinText.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if td and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - tds
            if math.abs(delta.X) > 3 or math.abs(delta.Y) > 3 then tm = true end
            MinText.Position = UDim2.new(tsp.X.Scale, tsp.X.Offset + delta.X, tsp.Y.Scale, tsp.Y.Offset + delta.Y)
        end
    end)
    
    MinText.InputEnded:Connect(function(input)
        if td then
            if not tm then showMain() end
            td = false
        end
    end)
    
    -- Window drag
    local da, di, ds, sp = false
    
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            da = true
            ds = input.Position
            sp = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then da = false end
            end)
        end
    end)
    
    TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            di = input
        end
    end)
    
    RunService.RenderStepped:Connect(function()
        if da and di then
            local delta = di.Position - ds
            Main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + delta.X, sp.Y.Scale, sp.Y.Offset + delta.Y)
        end
    end)
    
    return {
        Main = Main,
        MinText = MinText,
        FPS = FPSLabel,
        Bounty = Bounty,
        PlayersCount = PlayerCountBox,
        Hfill = Hfill,
        Htext = Htext,
        Status = Status,
        Toggle = Toggle
    }
end

-- =============================================
-- SPEED & JUMP
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
            if ESPObjects[player.Name].Billboard then ESPObjects[player.Name].Billboard:Destroy() end
            if ESPObjects[player.Name].Highlight then ESPObjects[player.Name].Highlight:Destroy() end
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
            DistLabel = distL
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
    local esp = ESPObjects[player.Name]
    if esp and esp.Highlight then
        esp.Highlight.FillColor = getTeamColor(player)
    end
end

-- =============================================
-- UPDATE LOOP
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
end)

-- FPS
task.spawn(function()
    local fc, last = 0, tick()
    while ScriptActive do
        fc = fc + 1
        if tick() - last >= 0.5 then
            local fps = math.floor(fc / (tick() - last))
            fc, last = 0, tick()
            if UI and UI.FPS then
                UI.FPS.Text = "FPS: " .. fps
                UI.FPS.TextColor3 = fps >= 50 and Color3.fromRGB(0, 255, 100) or (fps >= 25 and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 80, 80))
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
                UI.Hfill.Size = UDim2.new(pct, 0, 1, 0)
                UI.Htext.Text = math.floor(pct * 100) .. "%"
                UI.Hfill.BackgroundColor3 = pct > 0.5 and Color3.fromRGB(60, 200, 60) or (pct > 0.25 and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 50, 50))
            end
        end)
        task.wait(0.3)
    end
end)

-- Bounty
task.spawn(function()
    while ScriptActive do
        local bounty = scanBounty()
        if UI and UI.Bounty then
            UI.Bounty.Text = bounty and "💰 Bounty: " .. bounty or "💰 Bounty: Not found"
        end
        task.wait(3)
    end
end)

-- Players count
task.spawn(function()
    while ScriptActive do
        if UI and UI.PlayersCount then
            UI.PlayersCount.Text = "👥 Players: " .. #Players:GetPlayers()
        end
        task.wait(1)
    end
end)

-- Init
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
print("║     UNIVERSAL ESP - Professional    ║")
print("╠══════════════════════════════════════╣")
print("║  ⚡ Speed: " .. Config.Speed .. "                      ║")
print("║  🦘 Jump: " .. Config.JumpPower .. " | Air: " .. Config.MaxAirJumps .. "   ║")
print("║  👁️  ESP Active                      ║")
print("║  📏 Range: " .. Config.MaxESPDistance .. "m              ║")
print("╠══════════════════════════════════════╣")
print("║  Zero Dependencies - 100% Standalone║")
print("║  Professional Tabbed UI             ║")
print("║  Click '—' to minimize              ║")
print("║  Click '✕' to terminate             ║")
print("╚══════════════════════════════════════╝")
print("")
