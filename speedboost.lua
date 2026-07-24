-- ============================================
-- UNIVERSAL ESP - MODERN UI (Dark Teal #014d4e)
-- ALL ORIGINAL FUNCTIONS INTACT
-- Highlight-based ESP + Speed + Air Jump + FPS
-- ============================================

repeat wait() until game:IsLoaded() and game.Players and game.Players.LocalPlayer and game.Players.LocalPlayer.Character

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Camera = game:GetService("Workspace").CurrentCamera
local Teams = game:GetService("Teams")
local CoreGui = game:GetService("CoreGui")

-- ============================================
-- COLORS - DARK TEAL THEME (#014d4e)
-- ============================================
local BACKGROUND = Color3.fromRGB(1, 77, 78)        -- #014d4e - Main dark teal
local TOPBAR = Color3.fromRGB(2, 90, 91)            -- Slightly lighter dark teal
local TABBG = Color3.fromRGB(0, 60, 61)             -- Darker teal for tabs
local ELEMBG = Color3.fromRGB(2, 85, 86)            -- Element background
local ELEMBGHOVER = Color3.fromRGB(10, 105, 106)    -- Element hover
local ACCENT = Color3.fromRGB(0, 200, 195)          -- Bright teal accent
local BORDER = Color3.fromRGB(0, 160, 157)          -- Border color
local TEXT = Color3.fromRGB(255, 255, 255)          -- White text
local TEXTDIM = Color3.fromRGB(170, 220, 218)       -- Dim text

-- Detect platform
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ============================================
-- CONFIGURATION (INTACT)
-- ============================================
local Config = {
    Speed = 100,
    JumpPower = 80,
    MaxAirJumps = 5,
    ESPEnabled = true,
    MaxESPDistance = 2000
}

local Settings = {
    Minimized = false,
    ESPEnabled = true
}

local ScriptActive = true
local airJumpsLeft = 0
local isGrounded = false
local ESPObjects = {}
local espConnections = {}
local updateLoops = {}

-- FPS Tracking
local fpsCount, fps, lastFPSUpdate = 0, 0, tick()

-- Bounty
local CurrentBounty = "Searching..."

-- Clean up
if getgenv().UniversalESP_Loaded then
    getgenv().UniversalESP_Loaded = false
    pcall(function()
        if CoreGui:FindFirstChild("UniversalESP_GUI") then
            CoreGui.UniversalESP_GUI:Destroy()
        end
    end)
end
getgenv().UniversalESP_Loaded = true

-- ============================================
-- CORNER ROUNDING FUNCTION
-- ============================================
local function RoundCorners(frame, radius)
    local corner = Instance.new("UICorner")
    corner.Parent = frame
    corner.CornerRadius = UDim.new(0, radius or 14)
end

-- ============================================
-- TERMINATE FUNCTION (INTACT)
-- ============================================
local function terminateScript()
    ScriptActive = false
    Settings.ESPEnabled = false
    
    pcall(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = 16
            char.Humanoid.JumpPower = 50
        end
    end)
    
    if GUI then GUI:Destroy() end
    pcall(function()
        if CoreGui:FindFirstChild("ESP_MinimizeText") then
            CoreGui.ESP_MinimizeText:Destroy()
        end
    end)
    
    for _, esp in pairs(ESPObjects) do
        if esp and esp.Billboard then esp.Billboard:Destroy() end
        if esp and esp.Highlight then esp.Highlight:Destroy() end
    end
    ESPObjects = {}
    
    for _, conn in pairs(espConnections) do
        pcall(function() conn:Disconnect() end)
    end
    espConnections = {}
    
    for _, loop in pairs(updateLoops) do
        pcall(function() loop:Disconnect() end)
    end
    updateLoops = {}
    
    print("✓ ESP Terminated")
end

-- ============================================
-- FPS COUNTER (INTACT)
-- ============================================
local function getFPS()
    local fps = Stats:FindFirstChild("PerformanceStats")
    if fps then
        local f = fps:FindFirstChild("FPS")
        if f then return math.floor(f.Value) end
    end
    return 0
end

-- ============================================
-- GET TEAM COLOR (INTACT)
-- ============================================
local function getTeamColor(player)
    if player.Team then
        return player.Team.TeamColor.Color
    end
    return ACCENT
end

-- ============================================
-- BOUNTY SCANNER (INTACT)
-- ============================================
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
        
        if not bounty then
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                for _, child in pairs(playerGui:GetDescendants()) do
                    if child:IsA("TextLabel") or child:IsA("TextButton") then
                        local text = child.Text or ""
                        local textLower = string.lower(text)
                        if string.find(textLower, "bounty") then
                            local number = string.match(text, "[%d,]+")
                            if number then
                                bounty = number
                                break
                            else
                                local clean = text:gsub("Bounty", ""):gsub("bounty", ""):gsub("%s*:%s*", ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
                                if clean ~= "" then
                                    bounty = clean
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
    
    return bounty
end

-- ============================================
-- GUI CREATION - DARK TEAL UI
-- ============================================
local GUI = Instance.new("ScreenGui")
GUI.Name = "UniversalESP_GUI"
GUI.ResetOnSpawn = false
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.Parent = CoreGui

-- Main Frame
local Main = Instance.new("Frame")
Main.Name = "MainFrame"
Main.Size = UDim2.new(0, 640, 0, 480)
Main.Position = UDim2.new(0.5, -320, 0.5, -240)
Main.BackgroundColor3 = BACKGROUND
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Visible = true
Main.Parent = GUI
RoundCorners(Main, 14)
Instance.new("UIStroke", Main).Color = BORDER
Instance.new("UIStroke", Main).Thickness = 1
Instance.new("UIStroke", Main).Transparency = 0.3

-- Shadow
local Shadow = Instance.new("Frame")
Shadow.Parent = Main
Shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Shadow.BackgroundTransparency = 0.6
Shadow.BorderSizePixel = 0
Shadow.Position = UDim2.new(0, 8, 0, 8)
Shadow.Size = UDim2.new(1, -16, 1, -16)
RoundCorners(Shadow, 14)

-- ============================================
-- MINIMIZED BAR
-- ============================================
local MinBar = Instance.new("Frame")
MinBar.Name = "ESP_MinimizeText"
MinBar.Parent = GUI
MinBar.BackgroundColor3 = BACKGROUND
MinBar.BackgroundTransparency = 0
MinBar.BorderSizePixel = 0
MinBar.Position = UDim2.new(0.5, -150, 0.95, -20)
MinBar.Size = UDim2.new(0, 300, 0, 40)
MinBar.Visible = false
MinBar.ZIndex = 20
RoundCorners(MinBar, 14)
Instance.new("UIStroke", MinBar).Color = BORDER
Instance.new("UIStroke", MinBar).Thickness = 1
Instance.new("UIStroke", MinBar).Transparency = 0.3

local MinShadow = Instance.new("Frame")
MinShadow.Parent = MinBar
MinShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MinShadow.BackgroundTransparency = 0.6
MinShadow.BorderSizePixel = 0
MinShadow.Position = UDim2.new(0, 4, 0, 4)
MinShadow.Size = UDim2.new(1, -8, 1, -8)
RoundCorners(MinShadow, 14)

local MinIcon = Instance.new("TextLabel")
MinIcon.Parent = MinBar
MinIcon.BackgroundTransparency = 1
MinIcon.Position = UDim2.new(0, 12, 0, 0)
MinIcon.Size = UDim2.new(0, 25, 1, 0)
MinIcon.Font = Enum.Font.GothamBold
MinIcon.Text = "👁️"
MinIcon.TextColor3 = ACCENT
MinIcon.TextSize = 18

local MinTitle = Instance.new("TextLabel")
MinTitle.Parent = MinBar
MinTitle.BackgroundTransparency = 1
MinTitle.Position = UDim2.new(0, 42, 0, 0)
MinTitle.Size = UDim2.new(0, 150, 1, 0)
MinTitle.Font = Enum.Font.GothamBold
MinTitle.Text = "Universal ESP"
MinTitle.TextColor3 = TEXT
MinTitle.TextSize = 14
MinTitle.TextXAlignment = Enum.TextXAlignment.Left

local MinStatus = Instance.new("TextLabel")
MinStatus.Parent = MinBar
MinStatus.BackgroundTransparency = 1
MinStatus.Position = UDim2.new(0, 180, 0, 0)
MinStatus.Size = UDim2.new(0, 80, 1, 0)
MinStatus.Font = Enum.Font.Gotham
MinStatus.Text = "● Running"
MinStatus.TextColor3 = Color3.fromRGB(60, 200, 120)
MinStatus.TextSize = 11

local MinExpandBtn = Instance.new("TextButton")
MinExpandBtn.Parent = MinBar
MinExpandBtn.BackgroundColor3 = ACCENT
MinExpandBtn.BackgroundTransparency = 0.3
MinExpandBtn.BorderSizePixel = 0
MinExpandBtn.Position = UDim2.new(1, -45, 0.5, -15)
MinExpandBtn.Size = UDim2.new(0, 30, 0, 30)
MinExpandBtn.Font = Enum.Font.GothamBold
MinExpandBtn.Text = "□"
MinExpandBtn.TextColor3 = TEXT
MinExpandBtn.TextSize = 16
RoundCorners(MinExpandBtn, 15)

MinExpandBtn.MouseEnter:Connect(function()
    TweenService:Create(MinExpandBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.1}):Play()
end)
MinExpandBtn.MouseLeave:Connect(function()
    TweenService:Create(MinExpandBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.3}):Play()
end)

-- ============================================
-- TOP BAR
-- ============================================
local TopBar = Instance.new("Frame")
TopBar.Parent = Main
TopBar.BackgroundColor3 = TOPBAR
TopBar.BackgroundTransparency = 0
TopBar.BorderSizePixel = 0
TopBar.Size = UDim2.new(1, 0, 0, 55)
RoundCorners(TopBar, 14)

local AccentLine = Instance.new("Frame")
AccentLine.Parent = TopBar
AccentLine.BackgroundColor3 = ACCENT
AccentLine.BorderSizePixel = 0
AccentLine.Position = UDim2.new(0, 0, 1, -2)
AccentLine.Size = UDim2.new(1, 0, 0, 2)

-- FPS
local FPSDisplay = Instance.new("TextLabel")
FPSDisplay.Parent = TopBar
FPSDisplay.BackgroundTransparency = 1
FPSDisplay.Position = UDim2.new(1, -220, 0, 8)
FPSDisplay.Size = UDim2.new(0, 55, 0, 18)
FPSDisplay.Font = Enum.Font.GothamBold
FPSDisplay.Text = "FPS: --"
FPSDisplay.TextColor3 = Color3.fromRGB(0, 255, 100)
FPSDisplay.TextSize = 11
FPSDisplay.TextXAlignment = Enum.TextXAlignment.Right

-- Ping
local PingDisplay = Instance.new("TextLabel")
PingDisplay.Parent = TopBar
PingDisplay.BackgroundTransparency = 1
PingDisplay.Position = UDim2.new(1, -165, 0, 8)
PingDisplay.Size = UDim2.new(0, 65, 0, 18)
PingDisplay.Font = Enum.Font.GothamBold
PingDisplay.Text = "Ping: --"
PingDisplay.TextColor3 = Color3.fromRGB(100, 200, 255)
PingDisplay.TextSize = 11
PingDisplay.TextXAlignment = Enum.TextXAlignment.Right

-- Player Count
local PlayerCountDisplay = Instance.new("TextLabel")
PlayerCountDisplay.Parent = TopBar
PlayerCountDisplay.BackgroundTransparency = 1
PlayerCountDisplay.Position = UDim2.new(1, -100, 0, 8)
PlayerCountDisplay.Size = UDim2.new(0, 80, 0, 18)
PlayerCountDisplay.Font = Enum.Font.GothamBold
PlayerCountDisplay.Text = "👤 0"
PlayerCountDisplay.TextColor3 = Color3.fromRGB(100, 255, 100)
PlayerCountDisplay.TextSize = 11
PlayerCountDisplay.TextXAlignment = Enum.TextXAlignment.Right

-- Icon
local Icon = Instance.new("TextLabel")
Icon.Parent = TopBar
Icon.BackgroundTransparency = 1
Icon.Position = UDim2.new(0, 15, 0, 0)
Icon.Size = UDim2.new(0, 35, 1, 0)
Icon.Font = Enum.Font.GothamBold
Icon.Text = "👁️"
Icon.TextColor3 = ACCENT
Icon.TextSize = 22

-- Title
local Title = Instance.new("TextLabel")
Title.Parent = TopBar
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 55, 0, 0)
Title.Size = UDim2.new(0, 200, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "Universal ESP"
Title.TextColor3 = TEXT
Title.TextSize = 19
Title.TextXAlignment = Enum.TextXAlignment.Left

local Subtitle = Instance.new("TextLabel")
Subtitle.Parent = TopBar
Subtitle.BackgroundTransparency = 1
Subtitle.Position = UDim2.new(0, 55, 0, 26)
Subtitle.Size = UDim2.new(0, 200, 0, 20)
Subtitle.Font = Enum.Font.Gotham
Subtitle.Text = "by Maryyy | Highlight ESP"
Subtitle.TextColor3 = TEXTDIM
Subtitle.TextSize = 11
Subtitle.TextXAlignment = Enum.TextXAlignment.Left

-- Minimize Button
local MinBtn = Instance.new("TextButton")
MinBtn.Parent = TopBar
MinBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
MinBtn.BackgroundTransparency = 0.3
MinBtn.BorderSizePixel = 0
MinBtn.Position = UDim2.new(1, -45, 0.5, -15)
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Text = "─"
MinBtn.TextColor3 = TEXT
MinBtn.TextSize = 18
RoundCorners(MinBtn, 15)

MinBtn.MouseEnter:Connect(function()
    TweenService:Create(MinBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.1}):Play()
end)
MinBtn.MouseLeave:Connect(function()
    TweenService:Create(MinBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.3}):Play()
end)

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = TopBar
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.BackgroundTransparency = 0.3
CloseBtn.BorderSizePixel = 0
CloseBtn.Position = UDim2.new(1, -8, 0.5, -15)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = TEXT
CloseBtn.TextSize = 14
RoundCorners(CloseBtn, 15)

CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.1}):Play()
end)
CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.3}):Play()
end)

CloseBtn.MouseButton1Click:Connect(function()
    -- Confirmation dialog
    local confirm = Instance.new("Frame")
    confirm.Parent = Main
    confirm.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    confirm.BackgroundTransparency = 0.5
    confirm.BorderSizePixel = 0
    confirm.Position = UDim2.new(0, 0, 0, 0)
    confirm.Size = UDim2.new(1, 0, 1, 0)
    confirm.ZIndex = 999
    
    local box = Instance.new("Frame")
    box.Parent = confirm
    box.BackgroundColor3 = ELEMBG
    box.BackgroundTransparency = 0
    box.BorderSizePixel = 0
    box.Position = UDim2.new(0.5, -150, 0.5, -60)
    box.Size = UDim2.new(0, 300, 0, 120)
    RoundCorners(box, 12)
    box.ZIndex = 1000
    
    local warnLabel = Instance.new("TextLabel")
    warnLabel.Parent = box
    warnLabel.BackgroundTransparency = 1
    warnLabel.Position = UDim2.new(0, 0, 0, 10)
    warnLabel.Size = UDim2.new(1, 0, 0, 30)
    warnLabel.Font = Enum.Font.GothamBold
    warnLabel.Text = "⚠️ Terminate Script?"
    warnLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    warnLabel.TextSize = 18
    
    local descLabel = Instance.new("TextLabel")
    descLabel.Parent = box
    descLabel.BackgroundTransparency = 1
    descLabel.Position = UDim2.new(0, 10, 0, 45)
    descLabel.Size = UDim2.new(1, -20, 0, 20)
    descLabel.Font = Enum.Font.Gotham
    descLabel.Text = "This will stop all script execution."
    descLabel.TextColor3 = TEXTDIM
    descLabel.TextSize = 13
    
    local yesBtn = Instance.new("TextButton")
    yesBtn.Parent = box
    yesBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    yesBtn.BackgroundTransparency = 0
    yesBtn.BorderSizePixel = 0
    yesBtn.Position = UDim2.new(0.5, -110, 1, -45)
    yesBtn.Size = UDim2.new(0, 100, 0, 35)
    yesBtn.Font = Enum.Font.GothamBold
    yesBtn.Text = "Terminate"
    yesBtn.TextColor3 = TEXT
    yesBtn.TextSize = 14
    RoundCorners(yesBtn, 8)
    
    local noBtn = Instance.new("TextButton")
    noBtn.Parent = box
    noBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
    noBtn.BackgroundTransparency = 0
    noBtn.BorderSizePixel = 0
    noBtn.Position = UDim2.new(0.5, 10, 1, -45)
    noBtn.Size = UDim2.new(0, 100, 0, 35)
    noBtn.Font = Enum.Font.GothamBold
    noBtn.Text = "Cancel"
    noBtn.TextColor3 = TEXT
    noBtn.TextSize = 14
    RoundCorners(noBtn, 8)
    
    yesBtn.MouseButton1Click:Connect(function()
        confirm:Destroy()
        terminateScript()
    end)
    
    noBtn.MouseButton1Click:Connect(function()
        confirm:Destroy()
    end)
    
    confirm.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            confirm:Destroy()
        end
    end)
end)

-- ============================================
-- TABS
-- ============================================
local TabContainer = Instance.new("Frame")
TabContainer.Parent = Main
TabContainer.BackgroundColor3 = TABBG
TabContainer.BackgroundTransparency = 0
TabContainer.BorderSizePixel = 0
TabContainer.Position = UDim2.new(0, 0, 0, 55)
TabContainer.Size = UDim2.new(0, 160, 1, -55)

local Content = Instance.new("ScrollingFrame")
Content.Parent = Main
Content.BackgroundColor3 = BACKGROUND
Content.BackgroundTransparency = 0
Content.BorderSizePixel = 0
Content.Position = UDim2.new(0, 160, 0, 55)
Content.Size = UDim2.new(1, -160, 1, -55)
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.ScrollBarThickness = 4
Content.ScrollBarImageColor3 = BORDER

local currentTab = nil
local tabContents = {}

-- ============================================
-- UI ELEMENTS
-- ============================================
local function CreateTab(name, icon)
    local btn = Instance.new("TextButton")
    btn.Parent = TabContainer
    btn.BackgroundColor3 = TABBG
    btn.BackgroundTransparency = 0
    btn.BorderSizePixel = 0
    btn.Position = UDim2.new(0, 5, 0, #TabContainer:GetChildren() * 48 + 10)
    btn.Size = UDim2.new(1, -10, 0, 42)
    btn.Font = Enum.Font.Gotham
    btn.Text = "  " .. icon .. "  " .. name
    btn.TextColor3 = TEXTDIM
    btn.TextSize = 14
    btn.TextXAlignment = Enum.TextXAlignment.Left
    RoundCorners(btn, 8)
    
    local indicator = Instance.new("Frame")
    indicator.Parent = btn
    indicator.BackgroundColor3 = ACCENT
    indicator.BorderSizePixel = 0
    indicator.Position = UDim2.new(0, 0, 0.2, 0)
    indicator.Size = UDim2.new(0, 3, 0.6, 0)
    indicator.Visible = false
    RoundCorners(indicator, 2)
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = ELEMBGHOVER}):Play()
    end)
    btn.MouseLeave:Connect(function()
        if currentTab ~= name then
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = TABBG}):Play()
        end
    end)
    
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = name .. "Content"
    tabContainer.Parent = Content
    tabContainer.BackgroundTransparency = 1
    tabContainer.Size = UDim2.new(1, 0, 0, 0)
    tabContainer.Visible = false
    tabContainer.ZIndex = 15
    
    tabContents[name] = {
        container = tabContainer,
        yPos = 15,
        btn = btn,
        indicator = indicator
    }
    
    local function select()
        if currentTab == name then return end
        currentTab = name
        
        for _, data in pairs(tabContents) do
            data.container.Visible = false
            data.btn.BackgroundColor3 = TABBG
            data.btn.TextColor3 = TEXTDIM
            data.indicator.Visible = false
        end
        
        local data = tabContents[name]
        if data then
            data.container.Visible = true
            data.btn.BackgroundColor3 = ELEMBGHOVER
            data.btn.TextColor3 = TEXT
            data.indicator.Visible = true
            
            task.wait(0.05)
            Content.CanvasSize = UDim2.new(0, 0, 0, data.yPos + 30)
        end
    end
    
    btn.MouseButton1Click:Connect(select)
    
    return {
        select = select,
        container = tabContainer,
        getY = function() return tabContents[name].yPos end,
        setY = function(val) tabContents[name].yPos = val end
    }
end

local function AddSection(text)
    local data = tabContents[currentTab]
    if not data then return end
    
    local container = data.container
    local y = data.yPos
    
    local frame = Instance.new("Frame")
    frame.Parent = container
    frame.BackgroundTransparency = 1
    frame.Position = UDim2.new(0, 15, 0, y)
    frame.Size = UDim2.new(1, -30, 0, 30)
    
    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Font = Enum.Font.GothamBold
    label.Text = "▸ " .. text
    label.TextColor3 = TEXTDIM
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    data.yPos = data.yPos + 38
    return frame
end

local function AddDivider()
    local data = tabContents[currentTab]
    if not data then return end
    
    local container = data.container
    local y = data.yPos
    
    local frame = Instance.new("Frame")
    frame.Parent = container
    frame.BackgroundColor3 = BORDER
    frame.BackgroundTransparency = 0.5
    frame.BorderSizePixel = 0
    frame.Position = UDim2.new(0, 20, 0, y)
    frame.Size = UDim2.new(1, -40, 0, 1)
    
    data.yPos = data.yPos + 10
    return frame
end

local function AddLabel(text, color, size)
    local data = tabContents[currentTab]
    if not data then return end
    
    local container = data.container
    local y = data.yPos
    
    local frame = Instance.new("Frame")
    frame.Parent = container
    frame.BackgroundTransparency = 1
    frame.Position = UDim2.new(0, 15, 0, y)
    frame.Size = UDim2.new(1, -30, 0, 30)
    
    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = color or TEXT
    label.TextSize = size or 16
    label.TextXAlignment = Enum.TextXAlignment.Center
    
    data.yPos = data.yPos + 38
    return frame
end

local function AddSmallLabel(text, color)
    local data = tabContents[currentTab]
    if not data then return end
    
    local container = data.container
    local y = data.yPos
    
    local frame = Instance.new("Frame")
    frame.Parent = container
    frame.BackgroundTransparency = 1
    frame.Position = UDim2.new(0, 15, 0, y)
    frame.Size = UDim2.new(1, -30, 0, 25)
    
    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = color or TEXTDIM
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Center
    
    data.yPos = data.yPos + 30
    return frame
end

local function AddToggle(text, default, callback)
    local data = tabContents[currentTab]
    if not data then return end
    
    local container = data.container
    local y = data.yPos
    local state = default or false
    
    local frame = Instance.new("Frame")
    frame.Parent = container
    frame.BackgroundColor3 = ELEMBG
    frame.BackgroundTransparency = 0
    frame.BorderSizePixel = 0
    frame.Position = UDim2.new(0, 15, 0, y)
    frame.Size = UDim2.new(1, -30, 0, 45)
    RoundCorners(frame, 10)
    Instance.new("UIStroke", frame).Color = BORDER
    Instance.new("UIStroke", frame).Thickness = 1
    Instance.new("UIStroke", frame).Transparency = 0.3
    
    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 12, 0, 0)
    label.Size = UDim2.new(0, 280, 1, 0)
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = TEXT
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local toggle = Instance.new("Frame")
    toggle.Parent = frame
    toggle.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
    toggle.BackgroundTransparency = 0
    toggle.BorderSizePixel = 0
    toggle.Position = UDim2.new(1, -55, 0.5, -15)
    toggle.Size = UDim2.new(0, 40, 0, 30)
    RoundCorners(toggle, 15)
    
    local indicator = Instance.new("Frame")
    indicator.Parent = toggle
    indicator.BackgroundColor3 = Color3.fromRGB(200, 200, 220)
    indicator.BorderSizePixel = 0
    indicator.Position = UDim2.new(0, 3, 0.5, -12)
    indicator.Size = UDim2.new(0, 24, 0, 24)
    RoundCorners(indicator, 12)
    
    local function update(val)
        state = val
        if state then
            TweenService:Create(toggle, TweenInfo.new(0.3), {BackgroundColor3 = ACCENT}):Play()
            TweenService:Create(indicator, TweenInfo.new(0.3), {Position = UDim2.new(1, -27, 0.5, -12)}):Play()
        else
            TweenService:Create(toggle, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(80, 80, 100)}):Play()
            TweenService:Create(indicator, TweenInfo.new(0.3), {Position = UDim2.new(0, 3, 0.5, -12)}):Play()
        end
        if callback then callback(state) end
    end
    
    toggle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            update(not state)
        end
    end)
    
    update(state)
    data.yPos = data.yPos + 53
    return frame
end

local function AddButton(text, callback)
    local data = tabContents[currentTab]
    if not data then return end
    
    local container = data.container
    local y = data.yPos
    
    local frame = Instance.new("Frame")
    frame.Parent = container
    frame.BackgroundColor3 = ELEMBG
    frame.BackgroundTransparency = 0
    frame.BorderSizePixel = 0
    frame.Position = UDim2.new(0, 15, 0, y)
    frame.Size = UDim2.new(1, -30, 0, 45)
    RoundCorners(frame, 10)
    Instance.new("UIStroke", frame).Color = BORDER
    Instance.new("UIStroke", frame).Thickness = 1
    Instance.new("UIStroke", frame).Transparency = 0.3
    
    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 12, 0, 0)
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = TEXT
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local btn = Instance.new("TextButton")
    btn.Parent = frame
    btn.BackgroundColor3 = ACCENT
    btn.BackgroundTransparency = 0
    btn.BorderSizePixel = 0
    btn.Position = UDim2.new(1, -95, 0.5, -16)
    btn.Size = UDim2.new(0, 80, 0, 32)
    btn.Font = Enum.Font.GothamBold
    btn.Text = "Execute"
    btn.TextColor3 = TEXT
    btn.TextSize = 13
    RoundCorners(btn, 8)
    
    btn.MouseButton1Click:Connect(callback)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 220, 215)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = ACCENT}):Play()
    end)
    
    data.yPos = data.yPos + 53
    return frame
end

-- ============================================
-- CREATE TABS
-- ============================================
local espTab = CreateTab("ESP", "👁️")
local playerTab = CreateTab("Player", "👤")
local settingsTab = CreateTab("Settings", "⚙️")

-- ============================================
-- ESP TAB
-- ============================================
espTab.select()

AddLabel("═══════════════════════════════════", ACCENT, 14)
AddLabel("👁️ ESP CONTROLS", ACCENT, 18)
AddLabel("═══════════════════════════════════", ACCENT, 14)

AddDivider()

local espStatusLabel = AddSmallLabel("● ESP Active", Color3.fromRGB(0, 255, 100))

AddToggle("Enable ESP", true, function(state)
    Config.ESPEnabled = state
    espStatusLabel.Text = state and "● ESP Active" or "● ESP Disabled"
    espStatusLabel.TextColor3 = state and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(150, 150, 150)
end)

AddDivider()
AddSection("STATS")
AddSmallLabel("⚡ Speed: " .. Config.Speed, Color3.fromRGB(0, 200, 255))
AddSmallLabel("🦘 Jump: " .. Config.JumpPower .. " | Air: " .. Config.MaxAirJumps, Color3.fromRGB(100, 200, 255))
AddSmallLabel("📏 Range: " .. Config.MaxESPDistance .. "m", Color3.fromRGB(255, 200, 0))

-- ============================================
-- PLAYER TAB
-- ============================================
playerTab.select()

AddLabel("═══════════════════════════════════", ACCENT, 14)
AddLabel("👤 PLAYER INFO", ACCENT, 18)
AddLabel("═══════════════════════════════════", ACCENT, 14)

AddDivider()
AddSection("Profile")
AddSmallLabel("👤 " .. LocalPlayer.Name, TEXT)

-- Bounty Display
local bountyFrame = Instance.new("Frame")
bountyFrame.Parent = playerTab.container
bountyFrame.BackgroundColor3 = ELEMBG
bountyFrame.BackgroundTransparency = 0
bountyFrame.BorderSizePixel = 0
bountyFrame.Position = UDim2.new(0, 15, 0, playerTab.getY())
bountyFrame.Size = UDim2.new(1, -30, 0, 60)
RoundCorners(bountyFrame, 10)
Instance.new("UIStroke", bountyFrame).Color = BORDER
Instance.new("UIStroke", bountyFrame).Thickness = 1
Instance.new("UIStroke", bountyFrame).Transparency = 0.3

local bountyLabel = Instance.new("TextLabel")
bountyLabel.Parent = bountyFrame
bountyLabel.BackgroundTransparency = 1
bountyLabel.Position = UDim2.new(0, 12, 0, 5)
bountyLabel.Size = UDim2.new(1, -20, 0, 16)
bountyLabel.Font = Enum.Font.GothamBold
bountyLabel.Text = "BOUNTY"
bountyLabel.TextColor3 = TEXTDIM
bountyLabel.TextSize = 10
bountyLabel.TextXAlignment = Enum.TextXAlignment.Left

local bountyValue = Instance.new("TextLabel")
bountyValue.Parent = bountyFrame
bountyValue.BackgroundTransparency = 1
bountyValue.Position = UDim2.new(0, 12, 0, 24)
bountyValue.Size = UDim2.new(1, -20, 0, 28)
bountyValue.Font = Enum.Font.GothamBold
bountyValue.Text = "Searching..."
bountyValue.TextColor3 = Color3.fromRGB(255, 200, 0)
bountyValue.TextSize = 18
bountyValue.TextXAlignment = Enum.TextXAlignment.Left

playerTab.setY(playerTab.getY() + 70)

AddDivider()
AddSection("Health")

local healthBg = Instance.new("Frame")
healthBg.Parent = playerTab.container
healthBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
healthBg.BackgroundTransparency = 0
healthBg.BorderSizePixel = 0
healthBg.Position = UDim2.new(0, 15, 0, playerTab.getY())
healthBg.Size = UDim2.new(1, -30, 0, 24)
RoundCorners(healthBg, 4)

local healthBar = Instance.new("Frame")
healthBar.Parent = healthBg
healthBar.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
healthBar.BorderSizePixel = 0
healthBar.Size = UDim2.new(1, 0, 1, 0)
RoundCorners(healthBar, 4)

local healthText = Instance.new("TextLabel")
healthText.Parent = healthBar
healthText.BackgroundTransparency = 1
healthText.Size = UDim2.new(1, 0, 1, 0)
healthText.Font = Enum.Font.GothamBold
healthText.Text = "100%"
healthText.TextColor3 = TEXT
healthText.TextSize = 11

playerTab.setY(playerTab.getY() + 34)

AddDivider()
AddSection("Players")
local playerCountLabel = AddSmallLabel("Players in game: " .. #Players:GetPlayers(), Color3.fromRGB(100, 255, 100))

-- ============================================
-- SETTINGS TAB
-- ============================================
settingsTab.select()

AddLabel("═══════════════════════════════════", ACCENT, 14)
AddLabel("⚙️ SETTINGS", ACCENT, 18)
AddLabel("═══════════════════════════════════", ACCENT, 14)

AddDivider()
AddSection("Permanent Stats")
AddSmallLabel("Walk Speed: " .. Config.Speed, Color3.fromRGB(0, 200, 255))
AddSmallLabel("Jump Power: " .. Config.JumpPower, Color3.fromRGB(100, 200, 255))
AddSmallLabel("Air Jumps: " .. Config.MaxAirJumps, Color3.fromRGB(200, 200, 100))
AddSmallLabel("ESP Range: " .. Config.MaxESPDistance .. "m", Color3.fromRGB(255, 200, 0))

AddDivider()
AddSection("Controls")
AddButton("🔄 Toggle ESP", function()
    Config.ESPEnabled = not Config.ESPEnabled
    espStatusLabel.Text = Config.ESPEnabled and "● ESP Active" or "● ESP Disabled"
    espStatusLabel.TextColor3 = Config.ESPEnabled and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(150, 150, 150)
end)

AddDivider()
AddSection("Terminate")
local termBtn = Instance.new("Frame")
termBtn.Parent = settingsTab.container
termBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
termBtn.BackgroundTransparency = 0
termBtn.BorderSizePixel = 0
termBtn.Position = UDim2.new(0, 15, 0, settingsTab.getY())
termBtn.Size = UDim2.new(1, -30, 0, 50)
RoundCorners(termBtn, 10)

local termLabel = Instance.new("TextLabel")
termLabel.Parent = termBtn
termLabel.BackgroundTransparency = 1
termLabel.Size = UDim2.new(1, 0, 1, 0)
termLabel.Font = Enum.Font.GothamBold
termLabel.Text = "⚠️ TERMINATE SCRIPT"
termLabel.TextColor3 = TEXT
termLabel.TextSize = 16
termLabel.TextXAlignment = Enum.TextXAlignment.Center

termBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        -- Same confirmation dialog as close button
        local confirm = Instance.new("Frame")
        confirm.Parent = Main
        confirm.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        confirm.BackgroundTransparency = 0.5
        confirm.BorderSizePixel = 0
        confirm.Position = UDim2.new(0, 0, 0, 0)
        confirm.Size = UDim2.new(1, 0, 1, 0)
        confirm.ZIndex = 999
        
        local box = Instance.new("Frame")
        box.Parent = confirm
        box.BackgroundColor3 = ELEMBG
        box.BackgroundTransparency = 0
        box.BorderSizePixel = 0
        box.Position = UDim2.new(0.5, -150, 0.5, -60)
        box.Size = UDim2.new(0, 300, 0, 120)
        RoundCorners(box, 12)
        box.ZIndex = 1000
        
        local warnLabel = Instance.new("TextLabel")
        warnLabel.Parent = box
        warnLabel.BackgroundTransparency = 1
        warnLabel.Position = UDim2.new(0, 0, 0, 10)
        warnLabel.Size = UDim2.new(1, 0, 0, 30)
        warnLabel.Font = Enum.Font.GothamBold
        warnLabel.Text = "⚠️ Terminate Script?"
        warnLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        warnLabel.TextSize = 18
        
        local descLabel = Instance.new("TextLabel")
        descLabel.Parent = box
        descLabel.BackgroundTransparency = 1
        descLabel.Position = UDim2.new(0, 10, 0, 45)
        descLabel.Size = UDim2.new(1, -20, 0, 20)
        descLabel.Font = Enum.Font.Gotham
        descLabel.Text = "This will stop all script execution."
        descLabel.TextColor3 = TEXTDIM
        descLabel.TextSize = 13
        
        local yesBtn = Instance.new("TextButton")
        yesBtn.Parent = box
        yesBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
        yesBtn.BackgroundTransparency = 0
        yesBtn.BorderSizePixel = 0
        yesBtn.Position = UDim2.new(0.5, -110, 1, -45)
        yesBtn.Size = UDim2.new(0, 100, 0, 35)
        yesBtn.Font = Enum.Font.GothamBold
        yesBtn.Text = "Terminate"
        yesBtn.TextColor3 = TEXT
        yesBtn.TextSize = 14
        RoundCorners(yesBtn, 8)
        
        local noBtn = Instance.new("TextButton")
        noBtn.Parent = box
        noBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
        noBtn.BackgroundTransparency = 0
        noBtn.BorderSizePixel = 0
        noBtn.Position = UDim2.new(0.5, 10, 1, -45)
        noBtn.Size = UDim2.new(0, 100, 0, 35)
        noBtn.Font = Enum.Font.GothamBold
        noBtn.Text = "Cancel"
        noBtn.TextColor3 = TEXT
        noBtn.TextSize = 14
        RoundCorners(noBtn, 8)
        
        yesBtn.MouseButton1Click:Connect(function()
            confirm:Destroy()
            terminateScript()
        end)
        
        noBtn.MouseButton1Click:Connect(function()
            confirm:Destroy()
        end)
        
        confirm.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                confirm:Destroy()
            end
        end)
    end
end)

settingsTab.setY(settingsTab.getY() + 58)

AddDivider()
AddSmallLabel("Made with ❤️ by Maryyy", Color3.fromRGB(100, 200, 195))
AddSmallLabel("Click '─' to minimize", TEXTDIM)

-- ============================================
-- SELECT DEFAULT TAB
-- ============================================
espTab.select()

-- ============================================
-- MINIMIZE / EXPAND FUNCTIONS
-- ============================================
local function MinimizeUI()
    if Settings.Minimized then return end
    Settings.Minimized = true
    
    TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 0, 0, 0)
    }):Play()
    
    task.wait(0.2)
    Main.Visible = false
    
    MinBar.Visible = true
    MinBar.Position = UDim2.new(0.5, -150, 0.95, 20)
    MinBar.Size = UDim2.new(0, 0, 0, 40)
    MinBar.BackgroundTransparency = 1
    
    TweenService:Create(MinBar, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -150, 0.95, -20),
        Size = UDim2.new(0, 300, 0, 40),
        BackgroundTransparency = 0
    }):Play()
end

local function ExpandUI()
    if not Settings.Minimized then return end
    Settings.Minimized = false
    
    TweenService:Create(MinBar, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 0, 0, 40),
        BackgroundTransparency = 1
    }):Play()
    
    task.wait(0.2)
    MinBar.Visible = false
    
    Main.Visible = true
    Main.Size = UDim2.new(0, 0, 0, 0)
    Main.BackgroundTransparency = 1
    Main.Position = UDim2.new(0.5, -320, 0.5, -240)
    
    TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 640, 0, 480),
        BackgroundTransparency = 0
    }):Play()
end

MinBtn.MouseButton1Click:Connect(MinimizeUI)
MinExpandBtn.MouseButton1Click:Connect(ExpandUI)

-- ============================================
-- DRAGGABLE WINDOW
-- ============================================
local dragging = false
local dragInput, dragStart, startPos

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

MinBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MinBar.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

MinBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        if Settings.Minimized then
            MinBar.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        else
            Main.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end
end)

-- ============================================
-- SPEED & JUMP SYSTEM (INTACT)
-- ============================================
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

-- ============================================
-- HIGHLIGHT-BASED ESP SYSTEM (INTACT)
-- ============================================
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
        if ScriptActive then
            addESP(character)
        end
    end)
    table.insert(espConnections, conn)
end

-- ============================================
-- TEAM CHANGE (INTACT)
-- ============================================
local function onTeamChanged(player)
    if player == LocalPlayer then return end
    local esp = ESPObjects[player.Name]
    if esp and esp.Highlight then
        esp.Highlight.FillColor = getTeamColor(player)
    end
end

-- ============================================
-- UPDATE LOOPS (INTACT)
-- ============================================

-- FPS
table.insert(updateLoops, task.spawn(function()
    while ScriptActive do
        local fps = getFPS()
        FPSDisplay.Text = "FPS: " .. fps
        FPSDisplay.TextColor3 = fps >= 50 and Color3.fromRGB(0, 255, 100) or (fps >= 25 and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 80, 80))
        task.wait(0.5)
    end
end))

-- Ping
table.insert(updateLoops, task.spawn(function()
    while ScriptActive do
        pcall(function()
            local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
            PingDisplay.Text = "Ping: " .. ping .. "ms"
            PingDisplay.TextColor3 = ping <= 80 and Color3.fromRGB(100, 200, 255) or (ping <= 150 and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 100, 100))
        end)
        task.wait(1)
    end
end))

-- Player count
table.insert(updateLoops, task.spawn(function()
    while ScriptActive do
        local count = #Players:GetPlayers()
        PlayerCountDisplay.Text = "👤 " .. count
        playerCountLabel.Text = "Players in game: " .. count
        task.wait(1)
    end
end))

-- Health
table.insert(updateLoops, task.spawn(function()
    while ScriptActive do
        pcall(function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                local hp = char.Humanoid.Health
                local maxHP = char.Humanoid.MaxHealth
                local percent = hp / maxHP
                healthBar.Size = UDim2.new(percent, 0, 1, 0)
                healthText.Text = math.floor(percent * 100) .. "%"
                healthBar.BackgroundColor3 = percent > 0.5 and Color3.fromRGB(60, 200, 60) or (percent > 0.25 and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 50, 50))
            end
        end)
        task.wait(0.3)
    end
end))

-- Bounty
table.insert(updateLoops, task.spawn(function()
    while ScriptActive do
        local bounty = scanBounty()
        if bounty then
            CurrentBounty = bounty
            bountyValue.Text = bounty
        else
            bountyValue.Text = "Not found"
        end
        task.wait(3)
    end
end))

-- Apply Stats
table.insert(updateLoops, task.spawn(function()
    while ScriptActive do
        applyStats()
        task.wait(0.3)
    end
end))

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if ScriptActive then
        applyStats()
        airJumpsLeft = Config.MaxAirJumps
    end
end)

-- ============================================
-- MAIN ESP UPDATE LOOP (INTACT)
-- ============================================
table.insert(updateLoops, task.spawn(function()
    while ScriptActive do
        task.wait(0.15)
        if not ScriptActive then break end
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
end))

-- ============================================
-- INITIALIZE ESP (INTACT)
-- ============================================
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
print("║     UNIVERSAL ESP - Modern UI       ║")
print("╠══════════════════════════════════════╣")
print("║  ⚡ Speed: " .. Config.Speed .. "                      ║")
print("║  🦘 Jump: " .. Config.JumpPower .. " | Air: " .. Config.MaxAirJumps .. "   ║")
print("║  👁️  ESP Active                      ║")
print("║  📏 Range: " .. Config.MaxESPDistance .. "m              ║")
print("╠══════════════════════════════════════╣")
print("║  🎨 Theme: Dark Teal #014d4e        ║")
print("║  Click '─' to minimize to text      ║")
print("║  Click '✕' to terminate             ║")
print("╚══════════════════════════════════════╝")
print("")
