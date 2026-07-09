--[[
    UNIVERSAL ESP SCRIPT - Standalone
    Highlight-based player detection + Speed Boost + Air Jump + FPS Counter
    No external libraries - Pure standalone GUI
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

-- Detect platform
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

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
    HIGHLIGHT_ENABLED = true,
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
    if game.CoreGui:FindFirstChild("UniversalESPUI") then
        game.CoreGui.UniversalESPUI:Destroy()
    end
    if game.CoreGui:FindFirstChild("MinimizeText") then
        game.CoreGui.MinimizeText:Destroy()
    end
    if game.CoreGui:FindFirstChild("ESP_MainFrame") then
        game.CoreGui.ESP_MainFrame:Destroy()
    end
    if game.CoreGui:FindFirstChild("Rayfield") then
        game.CoreGui.Rayfield:Destroy()
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
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats") or LocalPlayer:FindFirstChild("stats") or LocalPlayer:FindFirstChild("Data")
        if leaderstats then
            for _, stat in pairs(leaderstats:GetChildren()) do
                local name = string.lower(stat.Name)
                if string.find(name, "bounty") or string.find(name, "beli") then
                    if stat:IsA("IntValue") or stat:IsA("NumberValue") then
                        bounty = tostring(stat.Value)
                        break
                    elseif stat:IsA("StringValue") then
                        bounty = stat.Value
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
    if game.CoreGui:FindFirstChild("MinimizeText") then
        game.CoreGui.MinimizeText:Destroy()
    end
    if game.CoreGui:FindFirstChild("ESP_MainFrame") then
        game.CoreGui.ESP_MainFrame:Destroy()
    end
    if game.CoreGui:FindFirstChild("Rayfield") then
        game.CoreGui.Rayfield:Destroy()
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
    
    print("✓ ESP Script Terminated")
end

-- =============================================
-- CREATE TABBED UI (SAILOR PIECE STYLE)
-- =============================================
local function createUI()
    MainGUI = Instance.new("ScreenGui")
    MainGUI.Name = "UniversalESPUI"
    MainGUI.ResetOnSpawn = false
    MainGUI.IgnoreGuiInset = true
    MainGUI.Parent = game.CoreGui
    MainGUI.ZIndexBehavior = Enum.ZIndexBehavior.Global
    
    local mainWidth = isMobile and 340 or 380
    local mainHeight = isMobile and 340 or 360
    
    -- Main Container
    local Main = Instance.new("Frame")
    Main.Name = "MainContainer"
    Main.Size = UDim2.new(0, mainWidth, 0, mainHeight)
    Main.Position = UDim2.new(0.5, -mainWidth/2, 0.5, -mainHeight/2)
    Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Main.BackgroundTransparency = 0.05
    Main.BorderSizePixel = 1
    Main.BorderColor3 = Color3.fromRGB(40, 40, 40)
    Main.ClipsDescendants = true
    Main.Parent = MainGUI
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = Main
    
    -- Minimize Text Button
    local MinimizeText = Instance.new("TextButton")
    MinimizeText.Name = "MinimizeText"
    MinimizeText.Size = UDim2.new(0, isMobile and 180 or 160, 0, isMobile and 40 or 35)
    MinimizeText.Position = UDim2.new(0, 10, 0, isMobile and 130 or 100)
    MinimizeText.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    MinimizeText.BackgroundTransparency = 0.1
    MinimizeText.BorderSizePixel = 1
    MinimizeText.BorderColor3 = Color3.fromRGB(40, 40, 40)
    MinimizeText.TextColor3 = Color3.fromRGB(0, 200, 255)
    MinimizeText.Text = "👁️ Universal ESP"
    MinimizeText.Font = Enum.Font.GothamBold
    MinimizeText.TextSize = isMobile and 15 or 13
    MinimizeText.AutoButtonColor = false
    MinimizeText.Visible = false
    MinimizeText.Active = true
    MinimizeText.ZIndex = 20
    MinimizeText.Parent = MainGUI
    
    local TextCorner = Instance.new("UICorner")
    TextCorner.CornerRadius = UDim.new(0, 6)
    TextCorner.Parent = MinimizeText
    
    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, isMobile and 30 or 26)
    TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
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
    
    -- Minimize Button
    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, isMobile and 24 or 22, 0, isMobile and 24 or 22)
    MinBtn.Position = UDim2.new(1, isMobile and -32 or -28, 0.5, isMobile and -12 or -11)
    MinBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MinBtn.BorderSizePixel = 0
    MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinBtn.Text = "—"
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.TextSize = isMobile and 14 or 12
    MinBtn.AutoButtonColor = false
    MinBtn.Active = true
    MinBtn.ZIndex = 20
    MinBtn.Parent = TitleBar
    
    local MinCorner = Instance.new("UICorner")
    MinCorner.CornerRadius = UDim.new(0, 3)
    MinCorner.Parent = MinBtn
    
    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, isMobile and 24 or 22, 0, isMobile and 24 or 22)
    CloseBtn.Position = UDim2.new(1, isMobile and -8 or -6, 0.5, isMobile and -12 or -11)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    CloseBtn.BorderSizePixel = 0
    CloseBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
    CloseBtn.Text = "✕"
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = isMobile and 12 or 10
    CloseBtn.AutoButtonColor = false
    CloseBtn.Active = true
    CloseBtn.ZIndex = 20
    CloseBtn.Parent = TitleBar
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 3)
    CloseCorner.Parent = CloseBtn
    
    CloseBtn.Activated:Connect(terminateScript)
    
    -- Content Area
    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1, 0, 1, isMobile and -30 or -26)
    Content.Position = UDim2.new(0, 0, 0, isMobile and 30 or 26)
    Content.BackgroundTransparency = 1
    Content.Parent = Main
    
    -- Tab System
    local tabs = {"ESP", "Player", "Settings"}
    local tabIcons = {"👁️", "👤", "⚙️"}
    local tabButtons = {}
    local tabContent = {}
    local tabHeight = isMobile and 26 or 22
    local tabY = 0
    
    -- Create Tab Buttons
    for i, tabName in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1/3, -2, 0, tabHeight)
        btn.Position = UDim2.new((i-1)/3, 1, 0, 0)
        btn.BackgroundColor3 = i == 1 and Color3.fromRGB(35, 35, 35) or Color3.fromRGB(20, 20, 20)
        btn.BorderSizePixel = 0
        btn.TextColor3 = i == 1 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
        btn.Text = tabIcons[i] .. " " .. tabName
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = isMobile and 10 or 9
        btn.AutoButtonColor = false
        btn.Active = true
        btn.ZIndex = 10
        btn.Parent = Content
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 3)
        btnCorner.Parent = btn
        
        -- Tab Content Frame
        local contentFrame = Instance.new("Frame")
        contentFrame.Size = UDim2.new(1, 0, 1, -tabHeight - 4)
        contentFrame.Position = UDim2.new(0, 0, 0, tabHeight + 2)
        contentFrame.BackgroundTransparency = 1
        contentFrame.Visible = (i == 1)
        contentFrame.Parent = Content
        
        btn.Activated:Connect(function()
            for j = 1, #tabButtons do
                tabButtons[j].BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                tabButtons[j].TextColor3 = Color3.fromRGB(150, 150, 150)
                tabContent[j].Visible = false
            end
            btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            contentFrame.Visible = true
            selectedTab = i
        end)
        
        table.insert(tabButtons, btn)
        table.insert(tabContent, contentFrame)
    end
    
    -- =============================================
    -- ESP TAB CONTENT
    -- =============================================
    local espTab = tabContent[1]
    
    -- ESP Status
    local ESPStatus = Instance.new("TextLabel")
    ESPStatus.Size = UDim2.new(0.6, 0, 0, 18)
    ESPStatus.Position = UDim2.new(0, 10, 0, 6)
    ESPStatus.BackgroundTransparency = 1
    ESPStatus.TextColor3 = Color3.fromRGB(0, 255, 100)
    ESPStatus.Text = "● ESP Active (1km)"
    ESPStatus.TextXAlignment = Enum.TextXAlignment.Left
    ESPStatus.Font = Enum.Font.GothamBold
    ESPStatus.TextSize = isMobile and 10 or 9
    ESPStatus.Parent = espTab
    
    -- Toggle ESP Button
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, isMobile and 70 or 60, 0, isMobile and 22 or 20)
    ToggleBtn.Position = UDim2.new(1, isMobile and -80 or -70, 0, 6)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    ToggleBtn.BorderSizePixel = 0
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleBtn.Text = "ESP ON"
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.TextSize = isMobile and 9 or 8
    ToggleBtn.AutoButtonColor = false
    ToggleBtn.Active = true
    ToggleBtn.ZIndex = 10
    ToggleBtn.Parent = espTab
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 3)
    ToggleCorner.Parent = ToggleBtn
    
    ToggleBtn.Activated:Connect(function()
        Config.ESPEnabled = not Config.ESPEnabled
        ToggleBtn.Text = Config.ESPEnabled and "ESP ON" or "ESP OFF"
        ToggleBtn.BackgroundColor3 = Config.ESPEnabled and Color3.fromRGB(35, 35, 35) or Color3.fromRGB(55, 25, 25)
        ESPStatus.Text = Config.ESPEnabled and "● ESP Active (1km)" or "● ESP Disabled"
        ESPStatus.TextColor3 = Config.ESPEnabled and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(150, 150, 150)
    end)
    
    -- Separator
    local Sep = Instance.new("Frame")
    Sep.Size = UDim2.new(1, -20, 0, 1)
    Sep.Position = UDim2.new(0, 10, 0, 34)
    Sep.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Sep.BorderSizePixel = 0
    Sep.Parent = espTab
    
    -- Speed
    local SpeedLabel = Instance.new("TextLabel")
    SpeedLabel.Size = UDim2.new(1, -20, 0, 16)
    SpeedLabel.Position = UDim2.new(0, 10, 0, 42)
    SpeedLabel.BackgroundTransparency = 1
    SpeedLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
    SpeedLabel.Text = "⚡ Speed: " .. Config.Speed
    SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
    SpeedLabel.Font = Enum.Font.GothamBold
    SpeedLabel.TextSize = isMobile and 10 or 9
    SpeedLabel.Parent = espTab
    
    -- Jump
    local JumpLabel = Instance.new("TextLabel")
    JumpLabel.Size = UDim2.new(1, -20, 0, 16)
    JumpLabel.Position = UDim2.new(0, 10, 0, 60)
    JumpLabel.BackgroundTransparency = 1
    JumpLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    JumpLabel.Text = "🦘 Jump: " .. Config.JumpPower .. " | Air: " .. Config.MaxAirJumps
    JumpLabel.TextXAlignment = Enum.TextXAlignment.Left
    JumpLabel.Font = Enum.Font.GothamBold
    JumpLabel.TextSize = isMobile and 10 or 9
    JumpLabel.Parent = espTab
    
    -- Range slider label
    local RangeLabel = Instance.new("TextLabel")
    RangeLabel.Size = UDim2.new(1, -20, 0, 16)
    RangeLabel.Position = UDim2.new(0, 10, 0, 82)
    RangeLabel.BackgroundTransparency = 1
    RangeLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    RangeLabel.Text = "📏 Range: " .. Config.MaxESPDistance .. "m"
    RangeLabel.TextXAlignment = Enum.TextXAlignment.Left
    RangeLabel.Font = Enum.Font.GothamBold
    RangeLabel.TextSize = isMobile and 10 or 9
    RangeLabel.Parent = espTab
    
    -- =============================================
    -- PLAYER TAB CONTENT
    -- =============================================
    local playerTab = tabContent[2]
    
    -- Player Name
    local PlayerName = Instance.new("TextLabel")
    PlayerName.Size = UDim2.new(1, -20, 0, 20)
    PlayerName.Position = UDim2.new(0, 10, 0, 6)
    PlayerName.BackgroundTransparency = 1
    PlayerName.TextColor3 = Color3.fromRGB(255, 255, 255)
    PlayerName.Text = "👤 " .. LocalPlayer.Name
    PlayerName.TextXAlignment = Enum.TextXAlignment.Left
    PlayerName.Font = Enum.Font.GothamBold
    PlayerName.TextSize = isMobile and 12 or 11
    PlayerName.Parent = playerTab
    
    -- Bounty
    local BountyLabel = Instance.new("TextLabel")
    BountyLabel.Size = UDim2.new(1, -20, 0, 18)
    BountyLabel.Position = UDim2.new(0, 10, 0, 30)
    BountyLabel.BackgroundTransparency = 1
    BountyLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    BountyLabel.Text = "💰 Bounty: Searching..."
    BountyLabel.TextXAlignment = Enum.TextXAlignment.Left
    BountyLabel.Font = Enum.Font.GothamBold
    BountyLabel.TextSize = isMobile and 11 or 10
    BountyLabel.Parent = playerTab
    
    -- Separator
    local Sep2 = Instance.new("Frame")
    Sep2.Size = UDim2.new(1, -20, 0, 1)
    Sep2.Position = UDim2.new(0, 10, 0, 54)
    Sep2.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Sep2.BorderSizePixel = 0
    Sep2.Parent = playerTab
    
    -- Health Section
    local HealthSection = Instance.new("TextLabel")
    HealthSection.Size = UDim2.new(1, -20, 0, 16)
    HealthSection.Position = UDim2.new(0, 10, 0, 60)
    HealthSection.BackgroundTransparency = 1
    HealthSection.TextColor3 = Color3.fromRGB(120, 120, 120)
    HealthSection.Text = "❤️ HEALTH"
    HealthSection.TextXAlignment = Enum.TextXAlignment.Left
    HealthSection.Font = Enum.Font.GothamBold
    HealthSection.TextSize = 9
    HealthSection.Parent = playerTab
    
    -- Health Bar Background
    local HealthBg = Instance.new("Frame")
    HealthBg.Size = UDim2.new(1, -20, 0, 14)
    HealthBg.Position = UDim2.new(0, 10, 0, 78)
    HealthBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    HealthBg.BorderSizePixel = 0
    HealthBg.Parent = playerTab
    
    local HealthCorner = Instance.new("UICorner")
    HealthCorner.CornerRadius = UDim.new(0, 3)
    HealthCorner.Parent = HealthBg
    
    -- Health Bar Fill
    local HealthFill = Instance.new("Frame")
    HealthFill.Size = UDim2.new(1, 0, 1, 0)
    HealthFill.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
    HealthFill.BorderSizePixel = 0
    HealthFill.Parent = HealthBg
    
    local HealthFillCorner = Instance.new("UICorner")
    HealthFillCorner.CornerRadius = UDim.new(0, 3)
    HealthFillCorner.Parent = HealthFill
    
    -- Health Text
    local HealthText = Instance.new("TextLabel")
    HealthText.Size = UDim2.new(1, 0, 1, 0)
    HealthText.BackgroundTransparency = 1
    HealthText.TextColor3 = Color3.fromRGB(255, 255, 255)
    HealthText.Text = "100%"
    HealthText.Font = Enum.Font.GothamBold
    HealthText.TextSize = 9
    HealthText.Parent = HealthFill
    
    -- Player Count
    local PlayerCount = Instance.new("TextLabel")
    PlayerCount.Size = UDim2.new(1, -20, 0, 16)
    PlayerCount.Position = UDim2.new(0, 10, 0, 98)
    PlayerCount.BackgroundTransparency = 1
    PlayerCount.TextColor3 = Color3.fromRGB(100, 255, 100)
    PlayerCount.Text = "👥 Players in game: " .. #Players:GetPlayers()
    PlayerCount.TextXAlignment = Enum.TextXAlignment.Left
    PlayerCount.Font = Enum.Font.GothamBold
    PlayerCount.TextSize = isMobile and 10 or 9
    PlayerCount.Parent = playerTab
    
    -- =============================================
    -- SETTINGS TAB CONTENT
    -- =============================================
    local settingsTab = tabContent[3]
    
    -- Stats Section
    local StatsSection = Instance.new("TextLabel")
    StatsSection.Size = UDim2.new(1, -20, 0, 16)
    StatsSection.Position = UDim2.new(0, 10, 0, 6)
    StatsSection.BackgroundTransparency = 1
    StatsSection.TextColor3 = Color3.fromRGB(120, 120, 120)
    StatsSection.Text = "⚙️ PERMANENT STATS"
    StatsSection.TextXAlignment = Enum.TextXAlignment.Left
    StatsSection.Font = Enum.Font.GothamBold
    StatsSection.TextSize = 9
    StatsSection.Parent = settingsTab
    
    -- Stat Labels
    local statY = 26
    local stats = {
        {text = "Walk Speed: " .. Config.Speed, color = Color3.fromRGB(0, 200, 255)},
        {text = "Jump Power: " .. Config.JumpPower, color = Color3.fromRGB(100, 200, 255)},
        {text = "Air Jumps: " .. Config.MaxAirJumps, color = Color3.fromRGB(200, 200, 100)},
        {text = "ESP Range: " .. Config.MaxESPDistance .. "m", color = Color3.fromRGB(255, 200, 0)}
    }
    
    for _, stat in pairs(stats) do
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 0, 14)
        label.Position = UDim2.new(0, 10, 0, statY)
        label.BackgroundTransparency = 1
        label.TextColor3 = stat.color
        label.Text = stat.text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.Gotham
        label.TextSize = isMobile and 9 or 8
        label.Parent = settingsTab
        statY = statY + 16
    end
    
    -- Separator
    local Sep3 = Instance.new("Frame")
    Sep3.Size = UDim2.new(1, -20, 0, 1)
    Sep3.Position = UDim2.new(0, 10, 0, statY + 4)
    Sep3.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Sep3.BorderSizePixel = 0
    Sep3.Parent = settingsTab
    
    -- Control buttons
    local btnY = statY + 14
    
    local function createSettingButton(text, yPos, color, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -20, 0, isMobile and 30 or 26)
        btn.Position = UDim2.new(0, 10, 0, yPos)
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        btn.BorderSizePixel = 0
        btn.TextColor3 = color or Color3.fromRGB(255, 255, 255)
        btn.Text = text
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = isMobile and 10 or 9
        btn.AutoButtonColor = false
        btn.Active = true
        btn.ZIndex = 10
        btn.Parent = settingsTab
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 3)
        btnCorner.Parent = btn
        
        btn.Activated:Connect(callback)
        return btn
    end
    
    createSettingButton("🔄 Toggle ESP", btnY, Color3.fromRGB(100, 200, 255), function()
        Config.ESPEnabled = not Config.ESPEnabled
        ToggleBtn.Text = Config.ESPEnabled and "ESP ON" or "ESP OFF"
        ToggleBtn.BackgroundColor3 = Config.ESPEnabled and Color3.fromRGB(35, 35, 35) or Color3.fromRGB(55, 25, 25)
        ESPStatus.Text = Config.ESPEnabled and "● ESP Active (1km)" or "● ESP Disabled"
        ESPStatus.TextColor3 = Config.ESPEnabled and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(150, 150, 150)
    end)
    
    btnY = btnY + (isMobile and 34 or 30)
    
    createSettingButton("⚠️ Terminate Script", btnY, Color3.fromRGB(255, 50, 50), terminateScript)
    
    -- =============================================
    -- MINIMIZE FUNCTIONALITY
    -- =============================================
    local function showMain()
        Main.Visible = true
        MinimizeText.Visible = false
        Config.Minimized = false
    end
    
    local function showText()
        Main.Visible = false
        MinimizeText.Visible = true
        Config.Minimized = true
    end
    
    MinBtn.Activated:Connect(showText)
    MinimizeText.Activated:Connect(showMain)
    
    -- Text button drag
    local textDragging = false
    local textDragStart
    local textStartPos
    local textMoved = false
    
    MinimizeText.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            textDragging = true
            textMoved = false
            textDragStart = input.Position
            textStartPos = MinimizeText.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if textDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - textDragStart
            if math.abs(delta.X) > 3 or math.abs(delta.Y) > 3 then
                textMoved = true
            end
            MinimizeText.Position = UDim2.new(textStartPos.X.Scale, textStartPos.X.Offset + delta.X, textStartPos.Y.Scale, textStartPos.Y.Offset + delta.Y)
        end
    end)
    
    MinimizeText.InputEnded:Connect(function(input)
        if textDragging then
            if not textMoved then
                showMain()
            end
            textDragging = false
        end
    end)
    
    -- Main window draggable
    local dragActive = false
    local dragInput
    local dragStart
    local startPos
    
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
        MinimizeText = MinimizeText,
        BountyLabel = BountyLabel,
        HealthFill = HealthFill,
        HealthText = HealthText,
        PlayerCount = PlayerCount,
        ESPStatus = ESPStatus,
        ToggleBtn = ToggleBtn,
        SpeedLabel = SpeedLabel,
        JumpLabel = JumpLabel,
        RangeLabel = RangeLabel
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
        
        local billboard = Instance.new("BillboardGui")
        billboard.Adornee = head
        billboard.Size = UDim2.new(0, 200, 0, 70)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Enabled = true
        billboard.Parent = character
        billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        local mainContainer = Instance.new("Frame", billboard)
        mainContainer.Size = UDim2.new(1, 0, 1, 0)
        mainContainer.BackgroundTransparency = 1
        mainContainer.BorderSizePixel = 0
        
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
        
        local healthBarBg = Instance.new("Frame", mainContainer)
        healthBarBg.Size = UDim2.new(0.9, 0, 0, 10)
        healthBarBg.Position = UDim2.new(0.05, 0, 0.3, 0)
        healthBarBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        healthBarBg.BorderSizePixel = 1
        healthBarBg.BorderColor3 = Color3.fromRGB(0, 0, 0)
        local healthBgCorner = Instance.new("UICorner", healthBarBg)
        healthBgCorner.CornerRadius = UDim.new(0, 2)
        
        local healthBarFill = Instance.new("Frame", healthBarBg)
        healthBarFill.Size = UDim2.new(1, 0, 1, 0)
        healthBarFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        healthBarFill.BorderSizePixel = 0
        local healthFillCorner = Instance.new("UICorner", healthBarFill)
        healthFillCorner.CornerRadius = UDim.new(0, 2)
        
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
                
                if espData.Billboard then
                    espData.Billboard.Adornee = head
                end
                
                if espData.Highlight then
                    espData.Highlight.Parent = character
                end
                
                local dist = (Camera.CFrame.Position - rootPart.Position).Magnitude
                local isInRange = dist <= Config.MaxESPDistance
                
                if isInRange and Config.ESPEnabled then
                    if espData.Highlight then espData.Highlight.Enabled = true end
                    if espData.Billboard then espData.Billboard.Enabled = true end
                    
                    local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                    if espData.HealthBarFill then
                        espData.HealthBarFill.Size = UDim2.new(healthPercent, 0, 1, 0)
                    end
                    
                    if healthPercent > 0.5 then
                        if espData.HealthBarFill then espData.HealthBarFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0) end
                    elseif healthPercent > 0.25 then
                        if espData.HealthBarFill then espData.HealthBarFill.BackgroundColor3 = Color3.fromRGB(255, 255, 0) end
                    else
                        if espData.HealthBarFill then espData.HealthBarFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0) end
                    end
                    
                    if espData.DistanceLabel and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local playerPos = LocalPlayer.Character.HumanoidRootPart.Position
                        local targetPos = rootPart.Position
                        local distance = math.floor((playerPos - targetPos).Magnitude)
                        
                        espData.DistanceLabel.Text = distance .. "m"
                        
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

-- Apply stats loop
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

-- FPS update
task.spawn(function()
    local fpsCount = 0
    local lastFPSUpdate = tick()
    while ScriptActive do
        fpsCount = fpsCount + 1
        if tick() - lastFPSUpdate >= 0.5 then
            local fps = math.floor(fpsCount / (tick() - lastFPSUpdate))
            fpsCount = 0
            lastFPSUpdate = tick()
            if Config.ShowFPS then
                pcall(function()
                    if MainGUI and MainGUI.Parent then
                        -- Update title bar with FPS
                        local titleBar = MainGUI:FindFirstChild("MainContainer")
                        if titleBar then
                            local titleText = titleBar:FindFirstChild("TitleBar")
                            if titleText then
                                local fpsLabel = titleText:FindFirstChild("FPSLabel")
                                if not fpsLabel then
                                    fpsLabel = Instance.new("TextLabel")
                                    fpsLabel.Name = "FPSLabel"
                                    fpsLabel.Size = UDim2.new(0, 55, 1, 0)
                                    fpsLabel.Position = UDim2.new(0, 8, 0, 0)
                                    fpsLabel.BackgroundTransparency = 1
                                    fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
                                    fpsLabel.Font = Enum.Font.GothamBold
                                    fpsLabel.TextSize = isMobile and 11 or 10
                                    fpsLabel.Parent = titleText
                                end
                                fpsLabel.Text = "FPS: " .. fps
                                fpsLabel.TextColor3 = fps >= 50 and Color3.fromRGB(0, 255, 100) or (fps >= 25 and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 80, 80))
                            end
                        end
                    end
                end)
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
                local humanoid = char.Humanoid
                local percent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                UI.HealthFill.Size = UDim2.new(percent, 0, 1, 0)
                UI.HealthText.Text = math.floor(percent * 100) .. "%"
                UI.HealthFill.BackgroundColor3 = percent > 0.5 and Color3.fromRGB(60, 200, 60) or (percent > 0.25 and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 50, 50))
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
        if UI and UI.PlayerCount then
            local count = #Players:GetPlayers()
            UI.PlayerCount.Text = "👥 Players in game: " .. count
        end
        task.wait(1)
    end
end)

-- Initialize ESP for existing players
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
print("║     UNIVERSAL ESP SCRIPT            ║")
print("╠══════════════════════════════════════╣")
print("║  ⚡ Speed: " .. Config.Speed .. "                      ║")
print("║  🦘 Jump: " .. Config.JumpPower .. " | Air: " .. Config.MaxAirJumps .. "   ║")
print("║  👁️  HIGHLIGHT ESP (1km)             ║")
print("║  📊 FPS: ENABLED                     ║")
print("║  📍 Scan Rate: 0.1s                  ║")
print("║  📏 Max Distance: 2000m              ║")
print("╠══════════════════════════════════════╣")
print("║  Works on ANY Roblox Game!          ║")
print("║  Tabbed UI with 3 tabs              ║")
print("║  Click '—' to minimize to text      ║")
print("║  Tap text to restore GUI            ║")
print("║  Click '✕' to terminate             ║")
print("╚══════════════════════════════════════╝")
print("")
