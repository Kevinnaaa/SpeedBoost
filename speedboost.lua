--[[
    BLOX FRUIT - ULTIMATE MOBILE
    Speed Boost + Air Jump + ESP + FPS Counter
    Team-based Box ESP with Highlights - PERMANENT
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
    ESPEnabled = true, -- Always true, never toggled
    ShowFPS = true,
    BoxThickness = 2,
    ScanInterval = 0.1,
    TEXT_SIZE = 18,
    TEXT_FONT = Enum.Font.GothamBold,
    TEXT_OUTLINE = true,
    HIGHLIGHT_ENABLED = true,
    MaxESPDistance = 2000 -- Maximum distance to show ESP (2000 studs)
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
        if esp and esp.Container then esp.Container:Destroy() end
        if esp and esp.Highlight then esp.Highlight:Destroy() end
    end
    ESPObjects = {}
    
    for _, conn in pairs(espConnections) do
        conn:Disconnect()
    end
    espConnections = {}
    
    print("⚡ Script Terminated")
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
    return Color3.new(0.5, 0.5, 0.5) -- Gray for no team
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
    SpeedLabel.TextSize = 16
    SpeedLabel.Font = Enum.Font.GothamBold
    SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
    SpeedLabel.Parent = SpeedFrame
    
    -- Middle Section (Jump)
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
    
    -- FPS Counter
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
    
    -- ESP Status (Now just shows permanent status)
    local ESPStatus = Instance.new("TextLabel")
    ESPStatus.Size = UDim2.new(0, 70, 0, 20)
    ESPStatus.Position = UDim2.new(1, -75, 0, 6)
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
    
    -- FPS Update Loop
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
            
            if MainGUI then
                local container = MainGUI:FindFirstChild("Container")
                if container then
                    local jumpFrame = container:FindFirstChild("JumpFrame")
                    if jumpFrame then
                        local label = jumpFrame:FindFirstChild("JumpLabel")
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
-- TEAM-BASED BOX ESP SYSTEM - PERMANENT
-- =============================================
local function createBoxESP(player)
    if player == LocalPlayer or not ScriptActive then return end
    
    -- Clean up existing ESP
    if ESPObjects[player.Name] then
        pcall(function()
            if ESPObjects[player.Name].Container then
                ESPObjects[player.Name].Container:Destroy()
            end
            if ESPObjects[player.Name].Highlight then
                ESPObjects[player.Name].Highlight:Destroy()
            end
        end)
        ESPObjects[player.Name] = nil
    end
    
    local function addESP(character)
        if not character then return end
        
        -- Wait for character to load
        local humanoid = character:WaitForChild("Humanoid", 5)
        local rootPart = character:WaitForChild("HumanoidRootPart", 5)
        local head = character:WaitForChild("Head", 5)
        
        if not humanoid or not rootPart or not head then 
            print("[!] " .. player.Name .. " character not fully loaded")
            return 
        end
        
        -- Get team color
        local teamColor = getTeamColor(player)
        
        -- Create Highlight (Always enabled)
        local highlight = nil
        if Config.HIGHLIGHT_ENABLED then
            highlight = Instance.new("Highlight")
            highlight.FillColor = teamColor
            highlight.OutlineColor = Color3.new(0, 0, 0)
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.Enabled = true -- Always enabled
            highlight.Parent = character
        end
        
        -- Create Billboard GUI for nametag
        local billboard = Instance.new("BillboardGui")
        billboard.Adornee = head
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 4, 0)
        billboard.AlwaysOnTop = true
        billboard.Enabled = true -- Always enabled
        billboard.Parent = character
        
        -- Name label
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.Name
        nameLabel.TextColor3 = teamColor
        nameLabel.TextSize = Config.TEXT_SIZE
        nameLabel.Font = Config.TEXT_FONT
        nameLabel.Parent = billboard
        
        if Config.TEXT_OUTLINE then
            local outline = Instance.new("UIStroke")
            outline.Color = Color3.new(0, 0, 0)
            outline.Thickness = 1.5
            outline.Parent = nameLabel
        end
        
        -- Create ScreenGui for box
        local container = Instance.new("ScreenGui")
        container.Name = "BoxESP_" .. player.Name
        container.ResetOnSpawn = false
        container.Parent = game.CoreGui
        container.Enabled = true -- Always enabled
        container.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        container.DisplayOrder = 10
        
        -- Main box frame
        local boxFrame = Instance.new("Frame")
        boxFrame.Size = UDim2.new(0, 0, 0, 0)
        boxFrame.Position = UDim2.new(0, 0, 0, 0)
        boxFrame.BackgroundTransparency = 1
        boxFrame.BorderSizePixel = 0
        boxFrame.Visible = false
        boxFrame.Parent = container
        
        -- Box lines
        local topLine = Instance.new("Frame")
        topLine.Size = UDim2.new(1, 0, 0, Config.BoxThickness)
        topLine.Position = UDim2.new(0, 0, 0, 0)
        topLine.BackgroundColor3 = teamColor
        topLine.BackgroundTransparency = 0.3
        topLine.BorderSizePixel = 0
        topLine.Parent = boxFrame
        
        local bottomLine = Instance.new("Frame")
        bottomLine.Size = UDim2.new(1, 0, 0, Config.BoxThickness)
        bottomLine.Position = UDim2.new(0, 0, 1, -Config.BoxThickness)
        bottomLine.BackgroundColor3 = teamColor
        bottomLine.BackgroundTransparency = 0.3
        bottomLine.BorderSizePixel = 0
        bottomLine.Parent = boxFrame
        
        local leftLine = Instance.new("Frame")
        leftLine.Size = UDim2.new(0, Config.BoxThickness, 1, 0)
        leftLine.Position = UDim2.new(0, 0, 0, 0)
        leftLine.BackgroundColor3 = teamColor
        leftLine.BackgroundTransparency = 0.3
        leftLine.BorderSizePixel = 0
        leftLine.Parent = boxFrame
        
        local rightLine = Instance.new("Frame")
        rightLine.Size = UDim2.new(0, Config.BoxThickness, 1, 0)
        rightLine.Position = UDim2.new(1, -Config.BoxThickness, 0, 0)
        rightLine.BackgroundColor3 = teamColor
        rightLine.BackgroundTransparency = 0.3
        rightLine.BorderSizePixel = 0
        rightLine.Parent = boxFrame
        
        -- Health bar background
        local healthBg = Instance.new("Frame")
        healthBg.Size = UDim2.new(0, 6, 1, 0)
        healthBg.Position = UDim2.new(1, 4, 0, 0)
        healthBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        healthBg.BorderSizePixel = 1
        healthBg.BorderColor3 = Color3.fromRGB(0, 0, 0)
        healthBg.Parent = boxFrame
        
        -- Health bar fill
        local healthFill = Instance.new("Frame")
        healthFill.Size = UDim2.new(1, 0, 1, 0)
        healthFill.Position = UDim2.new(0, 0, 0, 0)
        healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        healthFill.BorderSizePixel = 0
        healthFill.Parent = healthBg
        
        -- Distance label
        local distLabel = Instance.new("TextLabel")
        distLabel.Size = UDim2.new(1, 0, 0, 16)
        distLabel.Position = UDim2.new(0, 0, 1, 2)
        distLabel.BackgroundTransparency = 1
        distLabel.Text = "0m"
        distLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        distLabel.TextSize = 12
        distLabel.Font = Enum.Font.GothamBold
        distLabel.TextStrokeTransparency = 0.3
        distLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        distLabel.TextXAlignment = Enum.TextXAlignment.Center
        distLabel.Parent = boxFrame
        
        -- Health text
        local healthLabel = Instance.new("TextLabel")
        healthLabel.Size = UDim2.new(0, 30, 0, 14)
        healthLabel.Position = UDim2.new(1, 8, 0, 0)
        healthLabel.BackgroundTransparency = 1
        healthLabel.Text = "100%"
        healthLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        healthLabel.TextSize = 11
        healthLabel.Font = Enum.Font.GothamBold
        healthLabel.TextStrokeTransparency = 0.3
        healthLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        healthLabel.TextXAlignment = Enum.TextXAlignment.Left
        healthLabel.Parent = boxFrame
        
        -- Position label
        local posLabel = Instance.new("TextLabel")
        posLabel.Size = UDim2.new(1, 0, 0, 14)
        posLabel.Position = UDim2.new(0, 0, 1, 18)
        posLabel.BackgroundTransparency = 1
        posLabel.Text = "X:0 Y:0 Z:0"
        posLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
        posLabel.TextSize = 10
        posLabel.Font = Enum.Font.Gotham
        posLabel.TextStrokeTransparency = 0.3
        posLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        posLabel.TextXAlignment = Enum.TextXAlignment.Center
        posLabel.Parent = boxFrame
        
        ESPObjects[player.Name] = {
            Container = container,
            BoxFrame = boxFrame,
            TopLine = topLine,
            BottomLine = bottomLine,
            LeftLine = leftLine,
            RightLine = rightLine,
            HealthFill = healthFill,
            DistLabel = distLabel,
            HealthLabel = healthLabel,
            PosLabel = posLabel,
            NameLabel = nameLabel,
            Billboard = billboard,
            Highlight = highlight,
            Humanoid = humanoid,
            RootPart = rootPart
        }
        
        print("[+] ESP created for " .. player.Name)
    end
    
    -- Add ESP to existing character
    if player.Character then
        addESP(player.Character)
    end
    
    -- Connect to character added
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
    
    -- Update highlight color
    if espData.Highlight then
        espData.Highlight.FillColor = teamColor
    end
    
    -- Update nametag color
    if espData.NameLabel then
        espData.NameLabel.TextColor3 = teamColor
    end
    
    -- Update box colors
    if espData.TopLine then
        espData.TopLine.BackgroundColor3 = teamColor
        espData.BottomLine.BackgroundColor3 = teamColor
        espData.LeftLine.BackgroundColor3 = teamColor
        espData.RightLine.BackgroundColor3 = teamColor
    end
end

-- =============================================
-- MAIN ESP UPDATE LOOP - PERMANENT WITH HIDING
-- =============================================
task.spawn(function()
    while ScriptActive do
        task.wait(Config.ScanInterval)
        
        pcall(function()
            for playerName, espData in pairs(ESPObjects) do
                if not espData or not espData.Container then continue end
                
                local player = Players:FindFirstChild(playerName)
                if not player then 
                    espData.Container:Destroy()
                    if espData.Highlight then espData.Highlight:Destroy() end
                    ESPObjects[playerName] = nil
                    continue
                end
                
                local character = player.Character
                if not character then 
                    -- Hide everything when character is not loaded
                    espData.BoxFrame.Visible = false
                    if espData.Billboard then espData.Billboard.Enabled = false end
                    if espData.Highlight then espData.Highlight.Enabled = false end
                    continue
                end
                
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                local humanoid = character:FindFirstChild("Humanoid")
                local head = character:FindFirstChild("Head")
                
                if not rootPart or not humanoid or not head then 
                    espData.BoxFrame.Visible = false
                    if espData.Billboard then espData.Billboard.Enabled = false end
                    if espData.Highlight then espData.Highlight.Enabled = false end
                    continue
                end
                
                -- Update billboard attachment
                if espData.Billboard then
                    espData.Billboard.Adornee = head
                end
                
                -- Update highlight
                if espData.Highlight then
                    espData.Highlight.Parent = character
                end
                
                -- Always enabled
                espData.Container.Enabled = true
                
                -- Get player position on screen
                local pos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                
                -- Check if player is within range (2000 studs)
                local dist = (Camera.CFrame.Position - rootPart.Position).Magnitude
                local isInRange = dist <= Config.MaxESPDistance
                
                if onScreen and isInRange then
                    -- Show ESP elements
                    espData.BoxFrame.Visible = true
                    if espData.Billboard then espData.Billboard.Enabled = true end
                    if espData.Highlight then espData.Highlight.Enabled = true end
                    
                    -- Calculate box size based on distance (adjust for 2000 studs)
                    local boxSize = math.clamp(800 / dist * 5, 20, 200)
                    
                    espData.BoxFrame.Size = UDim2.new(0, boxSize, 0, boxSize * 1.5)
                    espData.BoxFrame.Position = UDim2.new(0, pos.X - boxSize/2, 0, pos.Y - boxSize * 1.5/2)
                    
                    -- Update health bar
                    local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                    
                    espData.HealthFill.Size = UDim2.new(1, 0, healthPercent, 0)
                    espData.HealthFill.Position = UDim2.new(0, 0, 1 - healthPercent, 0)
                    
                    if healthPercent > 0.5 then
                        espData.HealthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                        espData.HealthLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                    elseif healthPercent > 0.25 then
                        espData.HealthFill.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
                        espData.HealthLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
                    else
                        espData.HealthFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                        espData.HealthLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                    end
                    
                    espData.HealthLabel.Text = math.floor(healthPercent * 100) .. "%"
                    
                    -- Update distance
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
                        local theirPos = rootPart.Position
                        local distance = (myPos - theirPos).Magnitude
                        espData.DistLabel.Text = math.floor(distance) .. "m"
                        
                        if distance < 50 then
                            espData.DistLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                        elseif distance < 150 then
                            espData.DistLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
                        else
                            espData.DistLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                        end
                    end
                    
                    -- Update position
                    local px = math.floor(rootPart.Position.X)
                    local py = math.floor(rootPart.Position.Y)
                    local pz = math.floor(rootPart.Position.Z)
                    espData.PosLabel.Text = string.format("X:%d Y:%d Z:%d", px, py, pz)
                    
                    -- Update name with level
                    local leaderstats = player:FindFirstChild("leaderstats")
                    if leaderstats then
                        local level = leaderstats:FindFirstChild("Level")
                        if level then
                            espData.NameLabel.Text = player.Name .. " [Lv." .. tostring(level.Value) .. "]"
                        end
                    end
                else
                    -- Hide everything when player is off-screen or out of range
                    espData.BoxFrame.Visible = false
                    if espData.Billboard then espData.Billboard.Enabled = false end
                    if espData.Highlight then espData.Highlight.Enabled = false end
                end
            end
        end)
    end
end)

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

-- Initialize ESP for all players
task.wait(1)
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        createBoxESP(player)
        
        -- Watch for team changes
        player:GetPropertyChangedSignal("Team"):Connect(function()
            onTeamChanged(player)
        end)
    end
end

-- Connect for new players
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        task.wait(1)
        createBoxESP(player)
        
        player:GetPropertyChangedSignal("Team"):Connect(function()
            onTeamChanged(player)
        end)
    end
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player.Name] then
        pcall(function()
            if ESPObjects[player.Name].Container then
                ESPObjects[player.Name].Container:Destroy()
            end
            if ESPObjects[player.Name].Highlight then
                ESPObjects[player.Name].Highlight:Destroy()
            end
        end)
        ESPObjects[player.Name] = nil
    end
end)

-- REMOVED: ESP Toggle (E key) - No longer needed since ESP is permanent

-- =============================================
-- INITIALIZATION LOG
-- =============================================
print("")
print("╔══════════════════════════════════════╗")
print("║     BLOX FRUIT ULTIMATE MOBILE      ║")
print("╠══════════════════════════════════════╣")
print("║  ⚡ Speed: " .. Config.Speed .. "                      ║")
print("║  🦘 Jump: " .. Config.JumpPower .. " | Air: " .. Config.MaxAirJumps .. "   ║")
print("║  👁️  TEAM ESP: PERMANENT             ║")
print("║  📊 FPS: ENABLED                     ║")
print("║  📍 Scan Rate: 0.1s                  ║")
print("║  📏 Max Distance: 2000m              ║")
print("╠══════════════════════════════════════╣")
print("║  Click 'STOP' to terminate          ║")
print("╚══════════════════════════════════════╝")
print("")
