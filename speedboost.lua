--[[
    MODERN ESP - RAYFIELD STYLE UI
    Clean, modern, draggable UI with smooth animations
]]

repeat wait() until game:IsLoaded() and game.Players.LocalPlayer

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Camera = game:GetService("Workspace").CurrentCamera
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local TweenService = game:GetService("TweenService")
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
local UI = {}

-- Clean up
pcall(function()
    if game.CoreGui:FindFirstChild("ModernESP") then
        game.CoreGui.ModernESP:Destroy()
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

-- ============================================
-- MODERN UI CREATION (RAYFIELD STYLE)
-- ============================================
local function createModernUI()
    MainGUI = Instance.new("ScreenGui")
    MainGUI.Name = "ModernESP"
    MainGUI.ResetOnSpawn = false
    MainGUI.IgnoreGuiInset = true
    MainGUI.Parent = game.CoreGui
    
    -- Colors
    local Colors = {
        Background = Color3.fromRGB(25, 25, 30),
        Darker = Color3.fromRGB(20, 20, 25),
        Accent = Color3.fromRGB(0, 170, 255),
        Text = Color3.fromRGB(255, 255, 255),
        SubText = Color3.fromRGB(160, 160, 170),
        Red = Color3.fromRGB(255, 70, 70),
        Green = Color3.fromRGB(0, 255, 100),
        Yellow = Color3.fromRGB(255, 200, 0)
    }
    
    -- Window size
    local windowWidth = 340
    local windowHeight = 420
    
    -- Main Window
    local Window = Instance.new("Frame")
    Window.Name = "Window"
    Window.Size = UDim2.new(0, windowWidth, 0, windowHeight)
    Window.Position = UDim2.new(0.5, -windowWidth/2, 0.5, -windowHeight/2)
    Window.BackgroundColor3 = Colors.Background
    Window.BorderSizePixel = 0
    Window.ClipsDescendants = true
    Window.Parent = MainGUI
    
    -- Window Shadow
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.Size = UDim2.new(1, 60, 1, 60)
    Shadow.Position = UDim2.new(0, -30, 0, -30)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://6014261993"
    Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.ImageTransparency = 0.6
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    Shadow.ZIndex = -1
    Shadow.Parent = Window
    
    -- Window Corner
    local WindowCorner = Instance.new("UICorner")
    WindowCorner.CornerRadius = UDim.new(0, 12)
    WindowCorner.Parent = Window
    
    -- Window Stroke
    local WindowStroke = Instance.new("UIStroke")
    WindowStroke.Color = Color3.fromRGB(40, 40, 45)
    WindowStroke.Thickness = 1
    WindowStroke.Parent = Window
    
    -- ============================================
    -- TITLE BAR
    -- ============================================
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 45)
    TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = Window
    
    local TitleBarCorner = Instance.new("UICorner")
    TitleBarCorner.CornerRadius = UDim.new(0, 12)
    TitleBarCorner.Parent = TitleBar
    
    -- Fix top corners
    local TopFix = Instance.new("Frame")
    TopFix.Name = "TopFix"
    TopFix.Size = UDim2.new(1, 0, 0, 12)
    TopFix.Position = UDim2.new(0, 0, 0, 33)
    TopFix.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    TopFix.BorderSizePixel = 0
    TopFix.Parent = TitleBar
    
    -- Title Icon
    local TitleIcon = Instance.new("TextLabel")
    TitleIcon.Name = "TitleIcon"
    TitleIcon.Size = UDim2.new(0, 30, 0, 30)
    TitleIcon.Position = UDim2.new(0, 10, 0.5, -15)
    TitleIcon.BackgroundTransparency = 1
    TitleIcon.Text = "👁️"
    TitleIcon.TextColor3 = Colors.Accent
    TitleIcon.Font = Enum.Font.GothamBold
    TitleIcon.TextSize = 18
    TitleIcon.Parent = TitleBar
    
    -- Title Text
    local TitleText = Instance.new("TextLabel")
    TitleText.Name = "TitleText"
    TitleText.Size = UDim2.new(0, 150, 0, 30)
    TitleText.Position = UDim2.new(0, 45, 0.5, -15)
    TitleText.BackgroundTransparency = 1
    TitleText.Text = "Universal ESP"
    TitleText.TextColor3 = Colors.Text
    TitleText.Font = Enum.Font.GothamBold
    TitleText.TextSize = 16
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Parent = TitleBar
    
    -- Status Indicator
    local StatusIndicator = Instance.new("Frame")
    StatusIndicator.Name = "StatusIndicator"
    StatusIndicator.Size = UDim2.new(0, 8, 0, 8)
    StatusIndicator.Position = UDim2.new(0, 200, 0.5, -4)
    StatusIndicator.BackgroundColor3 = Colors.Green
    StatusIndicator.BorderSizePixel = 0
    StatusIndicator.Parent = TitleBar
    
    local StatusCorner = Instance.new("UICorner")
    StatusCorner.CornerRadius = UDim.new(1, 0)
    StatusCorner.Parent = StatusIndicator
    
    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "CloseBtn"
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -35, 0.5, -15)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Colors.Red
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 14
    CloseBtn.AutoButtonColor = false
    CloseBtn.Parent = TitleBar
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 6)
    CloseCorner.Parent = CloseBtn
    
    -- Close hover animation
    CloseBtn.MouseEnter:Connect(function()
        TweenService:Create(CloseBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 30, 30)}):Play()
    end)
    CloseBtn.MouseLeave:Connect(function()
        TweenService:Create(CloseBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 40)}):Play()
    end)
    CloseBtn.MouseButton1Click:Connect(terminateScript)
    
    -- ============================================
    -- CONTENT AREA
    -- ============================================
    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, -20, 1, -60)
    Content.Position = UDim2.new(0, 10, 0, 50)
    Content.BackgroundTransparency = 1
    Content.Parent = Window
    
    -- Scrolling Frame
    local ScrollingFrame = Instance.new("ScrollingFrame")
    ScrollingFrame.Name = "ScrollingFrame"
    ScrollingFrame.Size = UDim2.new(1, 0, 1, 0)
    ScrollingFrame.BackgroundTransparency = 1
    ScrollingFrame.ScrollBarThickness = 4
    ScrollingFrame.ScrollBarImageColor3 = Colors.Accent
    ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScrollingFrame.Parent = Content
    
    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Padding = UDim.new(0, 8)
    UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    UIListLayout.Parent = ScrollingFrame
    
    -- Auto-size canvas
    UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 20)
    end)
    
    -- ============================================
    -- UI ELEMENTS
    -- ============================================
    
    -- Section helper
    local function CreateSection(text)
        local Section = Instance.new("Frame")
        Section.Name = "Section"
        Section.Size = UDim2.new(0.95, 0, 0, 30)
        Section.BackgroundTransparency = 1
        Section.Parent = ScrollingFrame
        
        local SectionLine = Instance.new("Frame")
        SectionLine.Name = "SectionLine"
        SectionLine.Size = UDim2.new(1, 0, 0, 1)
        SectionLine.Position = UDim2.new(0, 0, 1, -1)
        SectionLine.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        SectionLine.BorderSizePixel = 0
        SectionLine.Parent = Section
        
        local SectionLabel = Instance.new("TextLabel")
        SectionLabel.Name = "SectionLabel"
        SectionLabel.Size = UDim2.new(1, -10, 1, 0)
        SectionLabel.Position = UDim2.new(0, 10, 0, 0)
        SectionLabel.BackgroundTransparency = 1
        SectionLabel.Text = text
        SectionLabel.TextColor3 = Colors.Accent
        SectionLabel.Font = Enum.Font.GothamBold
        SectionLabel.TextSize = 13
        SectionLabel.TextXAlignment = Enum.TextXAlignment.Left
        SectionLabel.Parent = Section
        
        return Section
    end
    
    -- Toggle helper
    local function CreateToggle(text, default, callback)
        local ToggleFrame = Instance.new("Frame")
        ToggleFrame.Name = "Toggle"
        ToggleFrame.Size = UDim2.new(0.95, 0, 0, 40)
        ToggleFrame.BackgroundColor3 = Colors.Darker
        ToggleFrame.BorderSizePixel = 0
        ToggleFrame.Parent = ScrollingFrame
        
        local ToggleCorner = Instance.new("UICorner")
        ToggleCorner.CornerRadius = UDim.new(0, 8)
        ToggleCorner.Parent = ToggleFrame
        
        local ToggleLabel = Instance.new("TextLabel")
        ToggleLabel.Name = "ToggleLabel"
        ToggleLabel.Size = UDim2.new(0.7, 0, 1, 0)
        ToggleLabel.Position = UDim2.new(0, 12, 0, 0)
        ToggleLabel.BackgroundTransparency = 1
        ToggleLabel.Text = text
        ToggleLabel.TextColor3 = Colors.Text
        ToggleLabel.Font = Enum.Font.Gotham
        ToggleLabel.TextSize = 14
        ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
        ToggleLabel.Parent = ToggleFrame
        
        -- Toggle Background
        local ToggleBg = Instance.new("Frame")
        ToggleBg.Name = "ToggleBg"
        ToggleBg.Size = UDim2.new(0, 44, 0, 22)
        ToggleBg.Position = UDim2.new(1, -54, 0.5, -11)
        ToggleBg.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
        ToggleBg.BorderSizePixel = 0
        ToggleBg.Parent = ToggleFrame
        
        local ToggleBgCorner = Instance.new("UICorner")
        ToggleBgCorner.CornerRadius = UDim.new(1, 0)
        ToggleBgCorner.Parent = ToggleBg
        
        -- Toggle Circle
        local ToggleCircle = Instance.new("Frame")
        ToggleCircle.Name = "ToggleCircle"
        ToggleCircle.Size = UDim2.new(0, 18, 0, 18)
        ToggleCircle.Position = UDim2.new(0, 2, 0.5, -9)
        ToggleCircle.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        ToggleCircle.BorderSizePixel = 0
        ToggleCircle.Parent = ToggleBg
        
        local ToggleCircleCorner = Instance.new("UICorner")
        ToggleCircleCorner.CornerRadius = UDim.new(1, 0)
        ToggleCircleCorner.Parent = ToggleCircle
        
        local toggled = default or false
        
        local function UpdateToggle()
            local targetColor = toggled and Colors.Accent or Color3.fromRGB(50, 50, 55)
            local targetPosition = toggled and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
            
            TweenService:Create(ToggleBg, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
            TweenService:Create(ToggleCircle, TweenInfo.new(0.2), {Position = targetPosition}):Play()
        end
        
        local ClickDetector = Instance.new("TextButton")
        ClickDetector.Name = "ClickDetector"
        ClickDetector.Size = UDim2.new(1, 0, 1, 0)
        ClickDetector.BackgroundTransparency = 1
        ClickDetector.Text = ""
        ClickDetector.Parent = ToggleFrame
        
        ClickDetector.MouseButton1Click:Connect(function()
            toggled = not toggled
            UpdateToggle()
            if callback then callback(toggled) end
        end)
        
        UpdateToggle()
        
        return ToggleFrame
    end
    
    -- Slider helper
    local function CreateSlider(text, min, max, default, suffix, callback)
        local SliderFrame = Instance.new("Frame")
        SliderFrame.Name = "Slider"
        SliderFrame.Size = UDim2.new(0.95, 0, 0, 60)
        SliderFrame.BackgroundColor3 = Colors.Darker
        SliderFrame.BorderSizePixel = 0
        SliderFrame.Parent = ScrollingFrame
        
        local SliderCorner = Instance.new("UICorner")
        SliderCorner.CornerRadius = UDim.new(0, 8)
        SliderCorner.Parent = SliderFrame
        
        local SliderLabel = Instance.new("TextLabel")
        SliderLabel.Name = "SliderLabel"
        SliderLabel.Size = UDim2.new(0.6, 0, 0.4, 0)
        SliderLabel.Position = UDim2.new(0, 12, 0, 6)
        SliderLabel.BackgroundTransparency = 1
        SliderLabel.Text = text
        SliderLabel.TextColor3 = Colors.Text
        SliderLabel.Font = Enum.Font.Gotham
        SliderLabel.TextSize = 14
        SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
        SliderLabel.Parent = SliderFrame
        
        local ValueLabel = Instance.new("TextLabel")
        ValueLabel.Name = "ValueLabel"
        ValueLabel.Size = UDim2.new(0.3, 0, 0.4, 0)
        ValueLabel.Position = UDim2.new(0.7, 0, 0, 6)
        ValueLabel.BackgroundTransparency = 1
        ValueLabel.Text = tostring(default) .. (suffix or "")
        ValueLabel.TextColor3 = Colors.Accent
        ValueLabel.Font = Enum.Font.GothamBold
        ValueLabel.TextSize = 14
        ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
        ValueLabel.Parent = SliderFrame
        
        -- Track
        local Track = Instance.new("Frame")
        Track.Name = "Track"
        Track.Size = UDim2.new(0.9, 0, 0, 4)
        Track.Position = UDim2.new(0.05, 0, 0.7, 0)
        Track.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
        Track.BorderSizePixel = 0
        Track.Parent = SliderFrame
        
        local TrackCorner = Instance.new("UICorner")
        TrackCorner.CornerRadius = UDim.new(1, 0)
        TrackCorner.Parent = Track
        
        -- Fill
        local Fill = Instance.new("Frame")
        Fill.Name = "Fill"
        Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        Fill.BackgroundColor3 = Colors.Accent
        Fill.BorderSizePixel = 0
        Fill.Parent = Track
        
        local FillCorner = Instance.new("UICorner")
        FillCorner.CornerRadius = UDim.new(1, 0)
        FillCorner.Parent = Fill
        
        -- Knob
        local Knob = Instance.new("Frame")
        Knob.Name = "Knob"
        Knob.Size = UDim2.new(0, 16, 0, 16)
        Knob.Position = UDim2.new(Fill.Size.X.Scale, -8, 0.5, -8)
        Knob.BackgroundColor3 = Colors.Accent
        Knob.BorderSizePixel = 0
        Knob.Parent = Track
        
        local KnobCorner = Instance.new("UICorner")
        KnobCorner.CornerRadius = UDim.new(1, 0)
        KnobCorner.Parent = Knob
        
        local dragging = false
        local currentValue = default
        
        local function UpdateSlider(input)
            local trackPos = Track.AbsolutePosition
            local trackSize = Track.AbsoluteSize.X
            local mouseX = input.Position.X
            local normalized = math.clamp((mouseX - trackPos.X) / trackSize, 0, 1)
            
            currentValue = math.floor(min + (max - min) * normalized)
            Fill.Size = UDim2.new(normalized, 0, 1, 0)
            Knob.Position = UDim2.new(normalized, -8, 0.5, -8)
            ValueLabel.Text = tostring(currentValue) .. (suffix or "")
            
            if callback then callback(currentValue) end
        end
        
        local ClickDetector = Instance.new("TextButton")
        ClickDetector.Name = "ClickDetector"
        ClickDetector.Size = UDim2.new(1, 0, 1, 0)
        ClickDetector.BackgroundTransparency = 1
        ClickDetector.Text = ""
        ClickDetector.Parent = SliderFrame
        
        ClickDetector.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                UpdateSlider(input)
            end
        end)
        
        ClickDetector.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                UpdateSlider(input)
            end
        end)
        
        return SliderFrame
    end
    
    -- Info card helper
    local function CreateInfoCard(text, value, color)
        local Card = Instance.new("Frame")
        Card.Name = "InfoCard"
        Card.Size = UDim2.new(0.95, 0, 0, 40)
        Card.BackgroundColor3 = Colors.Darker
        Card.BorderSizePixel = 0
        Card.Parent = ScrollingFrame
        
        local CardCorner = Instance.new("UICorner")
        CardCorner.CornerRadius = UDim.new(0, 8)
        CardCorner.Parent = Card
        
        local CardLabel = Instance.new("TextLabel")
        CardLabel.Name = "CardLabel"
        CardLabel.Size = UDim2.new(0.6, 0, 1, 0)
        CardLabel.Position = UDim2.new(0, 12, 0, 0)
        CardLabel.BackgroundTransparency = 1
        CardLabel.Text = text
        CardLabel.TextColor3 = Colors.SubText
        CardLabel.Font = Enum.Font.Gotham
        CardLabel.TextSize = 13
        CardLabel.TextXAlignment = Enum.TextXAlignment.Left
        CardLabel.Parent = Card
        
        local CardValue = Instance.new("TextLabel")
        CardValue.Name = "CardValue"
        CardValue.Size = UDim2.new(0.3, 0, 1, 0)
        CardValue.Position = UDim2.new(0.7, 0, 0, 0)
        CardValue.BackgroundTransparency = 1
        CardValue.Text = value
        CardValue.TextColor3 = color or Colors.Accent
        CardValue.Font = Enum.Font.GothamBold
        CardValue.TextSize = 13
        CardValue.TextXAlignment = Enum.TextXAlignment.Right
        CardValue.Parent = Card
        
        return Card, CardValue
    end
    
    -- Button helper
    local function CreateButton(text, color, callback)
        local ButtonFrame = Instance.new("Frame")
        ButtonFrame.Name = "Button"
        ButtonFrame.Size = UDim2.new(0.95, 0, 0, 45)
        ButtonFrame.BackgroundColor3 = color or Colors.Accent
        ButtonFrame.BorderSizePixel = 0
        ButtonFrame.Parent = ScrollingFrame
        
        local ButtonCorner = Instance.new("UICorner")
        ButtonCorner.CornerRadius = UDim.new(0, 8)
        ButtonCorner.Parent = ButtonFrame
        
        local ButtonLabel = Instance.new("TextLabel")
        ButtonLabel.Name = "ButtonLabel"
        ButtonLabel.Size = UDim2.new(1, 0, 1, 0)
        ButtonLabel.BackgroundTransparency = 1
        ButtonLabel.Text = text
        ButtonLabel.TextColor3 = Colors.Text
        ButtonLabel.Font = Enum.Font.GothamBold
        ButtonLabel.TextSize = 14
        ButtonLabel.Parent = ButtonFrame
        
        local ClickDetector = Instance.new("TextButton")
        ClickDetector.Name = "ClickDetector"
        ClickDetector.Size = UDim2.new(1, 0, 1, 0)
        ClickDetector.BackgroundTransparency = 1
        ClickDetector.Text = ""
        ClickDetector.Parent = ButtonFrame
        
        ClickDetector.MouseEnter:Connect(function()
            TweenService:Create(ButtonFrame, TweenInfo.new(0.2), {BackgroundColor3 = color and color:Lerp(Color3.fromRGB(255, 255, 255), 0.2) or Colors.Accent:Lerp(Color3.fromRGB(255, 255, 255), 0.2)}):Play()
        end)
        
        ClickDetector.MouseLeave:Connect(function()
            TweenService:Create(ButtonFrame, TweenInfo.new(0.2), {BackgroundColor3 = color or Colors.Accent}):Play()
        end)
        
        ClickDetector.MouseButton1Click:Connect(callback)
        
        return ButtonFrame
    end
    
    -- ============================================
    -- BUILD UI
    -- ============================================
    
    -- ESP Section
    CreateSection("ESP Settings")
    
    CreateToggle("ESP Enabled", Config.ESPEnabled, function(state)
        Config.ESPEnabled = state
        StatusIndicator.BackgroundColor3 = state and Colors.Green or Colors.Red
    end)
    
    CreateSlider("ESP Distance", 100, 5000, Config.MaxESPDistance, "m", function(value)
        Config.MaxESPDistance = value
    end)
    
    -- Player Section
    CreateSection("Player Settings")
    
    CreateSlider("Walk Speed", 16, 250, Config.Speed, "", function(value)
        Config.Speed = value
    end)
    
    CreateSlider("Jump Power", 50, 200, Config.JumpPower, "", function(value)
        Config.JumpPower = value
    end)
    
    CreateSlider("Air Jumps", 0, 20, Config.MaxAirJumps, "", function(value)
        Config.MaxAirJumps = value
    end)
    
    -- Info Section
    CreateSection("Information")
    
    local FPSInfo, FPSValue = CreateInfoCard("FPS", "--", Colors.Green)
    local BountyInfo, BountyValue = CreateInfoCard("Bounty", "Loading...", Colors.Yellow)
    local PlayersInfo, PlayersValue = CreateInfoCard("Players", "0", Colors.Accent)
    
    -- Health Bar
    local HealthSection = Instance.new("Frame")
    HealthSection.Name = "HealthSection"
    HealthSection.Size = UDim2.new(0.95, 0, 0, 50)
    HealthSection.BackgroundColor3 = Colors.Darker
    HealthSection.BorderSizePixel = 0
    HealthSection.Parent = ScrollingFrame
    
    local HealthCorner = Instance.new("UICorner")
    HealthCorner.CornerRadius = UDim.new(0, 8)
    HealthCorner.Parent = HealthSection
    
    local HealthLabel = Instance.new("TextLabel")
    HealthLabel.Name = "HealthLabel"
    HealthLabel.Size = UDim2.new(0.5, 0, 0.4, 0)
    HealthLabel.Position = UDim2.new(0, 12, 0, 5)
    HealthLabel.BackgroundTransparency = 1
    HealthLabel.Text = "Health"
    HealthLabel.TextColor3 = Colors.SubText
    HealthLabel.Font = Enum.Font.Gotham
    HealthLabel.TextSize = 13
    HealthLabel.TextXAlignment = Enum.TextXAlignment.Left
    HealthLabel.Parent = HealthSection
    
    local HealthValue = Instance.new("TextLabel")
    HealthValue.Name = "HealthValue"
    HealthValue.Size = UDim2.new(0.3, 0, 0.4, 0)
    HealthValue.Position = UDim2.new(0.7, 0, 0, 5)
    HealthValue.BackgroundTransparency = 1
    HealthValue.Text = "100%"
    HealthValue.TextColor3 = Colors.Green
    HealthValue.Font = Enum.Font.GothamBold
    HealthValue.TextSize = 13
    HealthValue.TextXAlignment = Enum.TextXAlignment.Right
    HealthValue.Parent = HealthSection
    
    local HealthBg = Instance.new("Frame")
    HealthBg.Name = "HealthBg"
    HealthBg.Size = UDim2.new(0.9, 0, 0, 8)
    HealthBg.Position = UDim2.new(0.05, 0, 0.6, 0)
    HealthBg.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    HealthBg.BorderSizePixel = 0
    HealthBg.Parent = HealthSection
    
    local HealthBgCorner = Instance.new("UICorner")
    HealthBgCorner.CornerRadius = UDim.new(1, 0)
    HealthBgCorner.Parent = HealthBg
    
    local HealthFill = Instance.new("Frame")
    HealthFill.Name = "HealthFill"
    HealthFill.Size = UDim2.new(1, 0, 1, 0)
    HealthFill.BackgroundColor3 = Colors.Green
    HealthFill.BorderSizePixel = 0
    HealthFill.Parent = HealthBg
    
    local HealthFillCorner = Instance.new("UICorner")
    HealthFillCorner.CornerRadius = UDim.new(1, 0)
    HealthFillCorner.Parent = HealthFill
    
    -- Danger Zone
    CreateSection("Danger Zone")
    
    CreateButton("⚠️ TERMINATE SCRIPT", Color3.fromRGB(180, 30, 30), terminateScript)
    
    -- ============================================
    -- WINDOW DRAGGING
    -- ============================================
    local dragging, dragInput, dragStart, startPos
    
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Window.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    return {
        FPSValue = FPSValue,
        BountyValue = BountyValue,
        PlayersValue = PlayersValue,
        HealthFill = HealthFill,
        HealthValue = HealthValue
    }
end

-- ============================================
-- SPEED & JUMP
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
-- ESP SYSTEM
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
        addESP(character)
    end)
    table.insert(espConnections, conn)
end

-- TEAM CHANGE
local function onTeamChanged(player)
    if player == LocalPlayer then return end
    local esp = ESPObjects[player.Name]
    if esp and esp.Highlight then
        esp.Highlight.FillColor = getTeamColor(player)
    end
end

-- ============================================
-- UPDATE LOOPS
-- ============================================

-- ESP Update
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

-- ============================================
-- INITIALIZE
-- ============================================
UI = createModernUI()

-- Stats apply loop
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

-- FPS counter
task.spawn(function()
    local fc, last = 0, tick()
    while ScriptActive do
        fc = fc + 1
        if tick() - last >= 0.5 then
            local fps = math.floor(fc / (tick() - last))
            fc, last = 0, tick()
            if UI and UI.FPSValue then
                UI.FPSValue.Text = tostring(fps)
                UI.FPSValue.TextColor3 = fps >= 50 and Color3.fromRGB(0, 255, 100) or (fps >= 25 and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 80, 80))
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
                UI.HealthValue.Text = math.floor(pct * 100) .. "%"
                UI.HealthFill.BackgroundColor3 = pct > 0.5 and Color3.fromRGB(0, 255, 100) or (pct > 0.25 and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 50, 50))
            end
        end)
        task.wait(0.3)
    end
end)

-- Bounty update
task.spawn(function()
    while ScriptActive do
        local bounty = scanBounty()
        if UI and UI.BountyValue then
            UI.BountyValue.Text = bounty or "Not found"
        end
        task.wait(3)
    end
end)

-- Players count
task.spawn(function()
    while ScriptActive do
        if UI and UI.PlayersValue then
            UI.PlayersValue.Text = tostring(#Players:GetPlayers())
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

print("✓ Modern ESP Loaded | Speed: " .. Config.Speed .. " | Jump: " .. Config.JumpPower .. " | Air: " .. Config.MaxAirJumps)
