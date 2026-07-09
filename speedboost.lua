--[[
    UNIVERSAL ESP SCRIPT - Rayfield UI
    Highlight-based player detection + Speed Boost + Air Jump + FPS Counter
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
    TEXT_SIZE = 18,
    TEXT_FONT = Enum.Font.GothamBold,
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
local Window = nil
local CurrentBounty = "Searching..."
local RayfieldLoaded = false

-- =============================================
-- LOAD RAYFIELD WITH RETRY
-- =============================================
local function loadRayfield()
    local success, result = pcall(function()
        return loadstring(game:HttpGet('https://sirius.menu/rayfield', true))()
    end)
    
    if success and result then
        RayfieldLoaded = true
        return result
    else
        print("⚠️ Failed to load Rayfield, using fallback GUI")
        return nil
    end
end

local Rayfield = loadRayfield()

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
    
    if Window then
        pcall(function() 
            if RayfieldLoaded and Rayfield then
                Rayfield:Destroy()
            end
        end)
    end
    
    -- Clean up any leftover GUI
    pcall(function()
        if game.CoreGui:FindFirstChild("ESP_FallbackUI") then
            game.CoreGui.ESP_FallbackUI:Destroy()
        end
        if game.CoreGui:FindFirstChild("ESP_MainFrame") then
            game.CoreGui.ESP_MainFrame:Destroy()
        end
    end)
    
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
-- FALLBACK GUI (IF RAYFIELD FAILS)
-- =============================================
local function createFallbackUI()
    local MainGUI = Instance.new("ScreenGui")
    MainGUI.Name = "ESP_FallbackUI"
    MainGUI.ResetOnSpawn = false
    MainGUI.Parent = game.CoreGui
    
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 320, 0, 250)
    Frame.Position = UDim2.new(0.5, -160, 0.5, -125)
    Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Frame.BorderSizePixel = 1
    Frame.BorderColor3 = Color3.fromRGB(40, 40, 40)
    Frame.Parent = MainGUI
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Frame
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -20, 0, 30)
    Title.Position = UDim2.new(0, 10, 0, 5)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = Color3.fromRGB(0, 200, 255)
    Title.Text = "Universal ESP"
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 16
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Frame
    
    -- Close button
    local Close = Instance.new("TextButton")
    Close.Size = UDim2.new(0, 25, 0, 25)
    Close.Position = UDim2.new(1, -30, 0, 5)
    Close.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Close.BorderSizePixel = 0
    Close.TextColor3 = Color3.fromRGB(255, 50, 50)
    Close.Text = "✕"
    Close.Font = Enum.Font.GothamBold
    Close.TextSize = 14
    Close.AutoButtonColor = false
    Close.Parent = Frame
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 4)
    CloseCorner.Parent = Close
    
    Close.Activated:Connect(terminateScript)
    
    -- Separator
    local Sep = Instance.new("Frame")
    Sep.Size = UDim2.new(1, -20, 0, 1)
    Sep.Position = UDim2.new(0, 10, 0, 38)
    Sep.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Sep.BorderSizePixel = 0
    Sep.Parent = Frame
    
    -- FPS
    local FPSLabel = Instance.new("TextLabel")
    FPSLabel.Size = UDim2.new(0, 70, 0, 18)
    FPSLabel.Position = UDim2.new(0, 10, 0, 45)
    FPSLabel.BackgroundTransparency = 1
    FPSLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    FPSLabel.Text = "FPS: 60"
    FPSLabel.Font = Enum.Font.GothamBold
    FPSLabel.TextSize = 11
    FPSLabel.TextXAlignment = Enum.TextXAlignment.Left
    FPSLabel.Parent = Frame
    
    -- ESP Status
    local ESPStatus = Instance.new("TextLabel")
    ESPStatus.Size = UDim2.new(0.6, 0, 0, 18)
    ESPStatus.Position = UDim2.new(0, 10, 0, 65)
    ESPStatus.BackgroundTransparency = 1
    ESPStatus.TextColor3 = Color3.fromRGB(0, 255, 100)
    ESPStatus.Text = "● ESP Active"
    ESPStatus.Font = Enum.Font.GothamBold
    ESPStatus.TextSize = 11
    ESPStatus.TextXAlignment = Enum.TextXAlignment.Left
    ESPStatus.Parent = Frame
    
    -- Toggle ESP button
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 70, 0, 22)
    ToggleBtn.Position = UDim2.new(1, -80, 0, 64)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    ToggleBtn.BorderSizePixel = 0
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleBtn.Text = "ESP ON"
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.TextSize = 9
    ToggleBtn.AutoButtonColor = false
    ToggleBtn.Parent = Frame
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 4)
    ToggleCorner.Parent = ToggleBtn
    
    ToggleBtn.Activated:Connect(function()
        Config.ESPEnabled = not Config.ESPEnabled
        ToggleBtn.Text = Config.ESPEnabled and "ESP ON" or "ESP OFF"
        ToggleBtn.BackgroundColor3 = Config.ESPEnabled and Color3.fromRGB(35, 35, 35) or Color3.fromRGB(55, 25, 25)
        ESPStatus.Text = Config.ESPEnabled and "● ESP Active" or "● ESP Disabled"
        ESPStatus.TextColor3 = Config.ESPEnabled and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(150, 150, 150)
    end)
    
    -- Speed
    local SpeedLabel = Instance.new("TextLabel")
    SpeedLabel.Size = UDim2.new(1, -20, 0, 16)
    SpeedLabel.Position = UDim2.new(0, 10, 0, 88)
    SpeedLabel.BackgroundTransparency = 1
    SpeedLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
    SpeedLabel.Text = "⚡ Speed: " .. Config.Speed
    SpeedLabel.Font = Enum.Font.GothamBold
    SpeedLabel.TextSize = 10
    SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
    SpeedLabel.Parent = Frame
    
    -- Jump
    local JumpLabel = Instance.new("TextLabel")
    JumpLabel.Size = UDim2.new(1, -20, 0, 16)
    JumpLabel.Position = UDim2.new(0, 10, 0, 106)
    JumpLabel.BackgroundTransparency = 1
    JumpLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    JumpLabel.Text = "🦘 Jump: " .. Config.JumpPower .. " | Air: " .. Config.MaxAirJumps
    JumpLabel.Font = Enum.Font.GothamBold
    JumpLabel.TextSize = 10
    JumpLabel.TextXAlignment = Enum.TextXAlignment.Left
    JumpLabel.Parent = Frame
    
    -- Bounty
    local BountyLabel = Instance.new("TextLabel")
    BountyLabel.Size = UDim2.new(1, -20, 0, 16)
    BountyLabel.Position = UDim2.new(0, 10, 0, 124)
    BountyLabel.BackgroundTransparency = 1
    BountyLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    BountyLabel.Text = "💰 Bounty: Searching..."
    BountyLabel.Font = Enum.Font.GothamBold
    BountyLabel.TextSize = 10
    BountyLabel.TextXAlignment = Enum.TextXAlignment.Left
    BountyLabel.Parent = Frame
    
    -- Separator 2
    local Sep2 = Instance.new("Frame")
    Sep2.Size = UDim2.new(1, -20, 0, 1)
    Sep2.Position = UDim2.new(0, 10, 0, 145)
    Sep2.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Sep2.BorderSizePixel = 0
    Sep2.Parent = Frame
    
    -- Player name
    local PlayerName = Instance.new("TextLabel")
    PlayerName.Size = UDim2.new(1, -20, 0, 18)
    PlayerName.Position = UDim2.new(0, 10, 0, 150)
    PlayerName.BackgroundTransparency = 1
    PlayerName.TextColor3 = Color3.fromRGB(255, 255, 255)
    PlayerName.Text = "👤 " .. LocalPlayer.Name
    PlayerName.Font = Enum.Font.GothamBold
    PlayerName.TextSize = 12
    PlayerName.TextXAlignment = Enum.TextXAlignment.Left
    PlayerName.Parent = Frame
    
    -- Health bar background
    local HealthBg = Instance.new("Frame")
    HealthBg.Size = UDim2.new(1, -20, 0, 12)
    HealthBg.Position = UDim2.new(0, 10, 0, 172)
    HealthBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    HealthBg.BorderSizePixel = 0
    HealthBg.Parent = Frame
    
    local HealthCorner = Instance.new("UICorner")
    HealthCorner.CornerRadius = UDim.new(0, 4)
    HealthCorner.Parent = HealthBg
    
    -- Health fill
    local HealthFill = Instance.new("Frame")
    HealthFill.Size = UDim2.new(1, 0, 1, 0)
    HealthFill.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
    HealthFill.BorderSizePixel = 0
    HealthFill.Parent = HealthBg
    
    local HealthFillCorner = Instance.new("UICorner")
    HealthFillCorner.CornerRadius = UDim.new(0, 4)
    HealthFillCorner.Parent = HealthFill
    
    -- Health text
    local HealthText = Instance.new("TextLabel")
    HealthText.Size = UDim2.new(1, 0, 1, 0)
    HealthText.BackgroundTransparency = 1
    HealthText.TextColor3 = Color3.fromRGB(255, 255, 255)
    HealthText.Text = "100%"
    HealthText.Font = Enum.Font.GothamBold
    HealthText.TextSize = 9
    HealthText.Parent = HealthFill
    
    -- Player count
    local PlayerCount = Instance.new("TextLabel")
    PlayerCount.Size = UDim2.new(0, 80, 0, 16)
    PlayerCount.Position = UDim2.new(1, -90, 0, 190)
    PlayerCount.BackgroundTransparency = 1
    PlayerCount.TextColor3 = Color3.fromRGB(100, 255, 100)
    PlayerCount.Text = "👤 0"
    PlayerCount.Font = Enum.Font.GothamBold
    PlayerCount.TextSize = 10
    PlayerCount.TextXAlignment = Enum.TextXAlignment.Right
    PlayerCount.Parent = Frame
    
    return {
        Frame = Frame,
        FPSLabel = FPSLabel,
        BountyLabel = BountyLabel,
        HealthFill = HealthFill,
        HealthText = HealthText,
        PlayerCount = PlayerCount,
        ESPStatus = ESPStatus
    }
end

-- =============================================
-- CREATE RAYFIELD UI (IF LOADED)
-- =============================================
local function createRayfieldUI()
    if not RayfieldLoaded or not Rayfield then return nil end
    
    Window = Rayfield:CreateWindow({
        Name = "Universal ESP",
        Icon = 0,
        LoadingTitle = "Loading ESP...",
        LoadingSubtitle = "by Universal Script",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "UniversalESP",
            FileName = "Settings"
        },
        Discord = {
            Enabled = false
        },
        KeySystem = false,
        Theme = "DarkBlue"
    })
    
    -- ESP Tab
    local ESPTab = Window:CreateTab("ESP", 0)
    ESPTab:CreateSection("ESP Controls")
    
    ESPTab:CreateToggle({
        Name = "Enable ESP",
        CurrentValue = true,
        Flag = "ESPEnabled",
        Callback = function(Value)
            Config.ESPEnabled = Value
        end
    })
    
    ESPTab:CreateToggle({
        Name = "Show FPS Counter",
        CurrentValue = true,
        Flag = "ShowFPS",
        Callback = function(Value)
            Config.ShowFPS = Value
        end
    })
    
    ESPTab:CreateSlider({
        Name = "ESP Range (meters)",
        Range = {500, 3000},
        Increment = 100,
        Suffix = "m",
        CurrentValue = 2000,
        Flag = "ESPRange",
        Callback = function(Value)
            Config.MaxESPDistance = Value
        end
    })
    
    ESPTab:CreateSlider({
        Name = "Scan Interval (seconds)",
        Range = {0.05, 0.5},
        Increment = 0.05,
        Suffix = "s",
        CurrentValue = 0.1,
        Flag = "ScanInterval",
        Callback = function(Value)
            Config.ScanInterval = Value
        end
    })
    
    ESPTab:CreateSection("Stats")
    ESPTab:CreateLabel("⚡ Speed: " .. Config.Speed)
    ESPTab:CreateLabel("🦘 Jump: " .. Config.JumpPower .. " | Air: " .. Config.MaxAirJumps)
    
    -- Player Tab
    local PlayerTab = Window:CreateTab("Player", 0)
    PlayerTab:CreateSection("Player Info")
    PlayerTab:CreateLabel("👤 " .. LocalPlayer.Name)
    local BountyLabel = PlayerTab:CreateLabel("💰 Bounty: Searching...")
    PlayerTab:CreateSection("Health")
    local HealthLabel = PlayerTab:CreateLabel("Health: 100%")
    
    -- Settings Tab
    local SettingsTab = Window:CreateTab("Settings", 0)
    SettingsTab:CreateSection("Permanent Stats")
    SettingsTab:CreateLabel("Walk Speed: " .. Config.Speed)
    SettingsTab:CreateLabel("Jump Power: " .. Config.JumpPower)
    SettingsTab:CreateLabel("Air Jumps: " .. Config.MaxAirJumps)
    
    SettingsTab:CreateSection("Controls")
    SettingsTab:CreateButton({
        Name = "Toggle ESP",
        Callback = function()
            Config.ESPEnabled = not Config.ESPEnabled
            if RayfieldLoaded and Rayfield then
                Rayfield:Notify({
                    Title = "ESP " .. (Config.ESPEnabled and "Enabled" or "Disabled"),
                    Content = "ESP is now " .. (Config.ESPEnabled and "active" or "inactive"),
                    Duration = 2
                })
            end
        end
    })
    
    SettingsTab:CreateButton({
        Name = "⚠️ Terminate Script",
        Callback = function()
            terminateScript()
        end
    })
    
    -- Clean up on close
    Rayfield:OnClose(function()
        terminateScript()
    end)
    
    return {BountyLabel = BountyLabel, HealthLabel = HealthLabel}
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

-- Try Rayfield, fallback to custom GUI if it fails
local UI
if RayfieldLoaded and Rayfield then
    UI = createRayfieldUI()
else
    UI = createFallbackUI()
end

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
                    if Window and RayfieldLoaded then
                        Window:SetSubtitle("FPS: " .. fps)
                    elseif UI and UI.FPSLabel then
                        UI.FPSLabel.Text = "FPS: " .. fps
                        UI.FPSLabel.TextColor3 = fps >= 50 and Color3.fromRGB(0, 255, 100) or (fps >= 25 and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 80, 80))
                    end
                end)
            else
                pcall(function()
                    if Window and RayfieldLoaded then
                        Window:SetSubtitle("")
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
            if char and char:FindFirstChild("Humanoid") then
                local humanoid = char.Humanoid
                local percent = math.floor((humanoid.Health / humanoid.MaxHealth) * 100)
                
                if UI and UI.HealthLabel and RayfieldLoaded then
                    UI.HealthLabel:Set("Health: " .. percent .. "%")
                elseif UI and UI.HealthFill then
                    UI.HealthFill.Size = UDim2.new(math.clamp(percent / 100, 0, 1), 0, 1, 0)
                    UI.HealthText.Text = percent .. "%"
                    UI.HealthFill.BackgroundColor3 = percent > 50 and Color3.fromRGB(60, 200, 60) or (percent > 25 and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 50, 50))
                end
            end
        end)
        task.wait(0.3)
    end
end)

-- Bounty update
task.spawn(function()
    while ScriptActive do
        local bounty = scanBounty()
        if UI then
            if UI.BountyLabel and RayfieldLoaded then
                UI.BountyLabel:Set(bounty and "💰 Bounty: " .. bounty or "💰 Bounty: Not found")
            elseif UI.BountyLabel and not RayfieldLoaded then
                UI.BountyLabel.Text = bounty and "💰 Bounty: " .. bounty or "💰 Bounty: Not found"
            end
        end
        task.wait(3)
    end
end)

-- Player count update (fallback only)
task.spawn(function()
    while ScriptActive do
        if UI and UI.PlayerCount then
            local count = #Players:GetPlayers()
            UI.PlayerCount.Text = "👤 " .. count
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
if RayfieldLoaded then
    print("║  UI: Rayfield (Professional)       ║")
else
    print("║  UI: Fallback (Standalone)         ║")
end
print("║  Click '✕' to terminate             ║")
print("╚══════════════════════════════════════╝")
print("")
