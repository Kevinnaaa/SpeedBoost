--[[
    BLOX FRUIT ULTIMATE MOBILE WITH RAYFIELD UI
    Speed Boost + Air Jump + ESP + FPS Counter
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
-- ESP CONFIGURATION
-- =============================================
local ESPConfig = {
    Speed = 100,
    JumpPower = 80,
    MaxAirJumps = 5,
    ESPEnabled = true,
    BoxThickness = 2,
    ScanInterval = 0.1,
    TEXT_SIZE = 18,
    TEXT_FONT = Enum.Font.GothamBold,
    TEXT_OUTLINE = true,
    HIGHLIGHT_ENABLED = true,
    MaxESPDistance = 1000 -- EXACTLY 1000 meters range
}

-- =============================================
-- ESP VARIABLES
-- =============================================
local ScriptActive = true
local airJumpsLeft = 0
local isGrounded = false
local ESPObjects = {}
local espConnections = {}

-- =============================================
-- GET TEAM COLOR
-- =============================================
local function getTeamColor(player)
    if player.Team then
        return player.Team.TeamColor.Color
    end
    return Color3.new(0.5, 0.5, 0.5)
end

-- =============================================
-- TEAM-BASED BOX ESP SYSTEM
-- =============================================
local function createBoxESP(player)
    if player == LocalPlayer or not ScriptActive then return end
    
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
        
        local humanoid = character:WaitForChild("Humanoid", 5)
        local rootPart = character:WaitForChild("HumanoidRootPart", 5)
        local head = character:WaitForChild("Head", 5)
        
        if not humanoid or not rootPart or not head then 
            return 
        end
        
        local teamColor = getTeamColor(player)
        
        -- Create Highlight
        local highlight = nil
        if ESPConfig.HIGHLIGHT_ENABLED then
            highlight = Instance.new("Highlight")
            highlight.FillColor = teamColor
            highlight.OutlineColor = Color3.new(0, 0, 0)
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.Enabled = true
            highlight.Parent = character
        end
        
        -- Create Billboard GUI for nametag
        local billboard = Instance.new("BillboardGui")
        billboard.Adornee = head
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Enabled = true
        billboard.Parent = character
        billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        -- Name label with background
        local nameBg = Instance.new("Frame")
        nameBg.Size = UDim2.new(1, 0, 1, 0)
        nameBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        nameBg.BackgroundTransparency = 0.4
        nameBg.BorderSizePixel = 0
        nameBg.Parent = billboard
        
        local nameBgCorner = Instance.new("UICorner")
        nameBgCorner.CornerRadius = UDim.new(0, 4)
        nameBgCorner.Parent = nameBg
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.Name
        nameLabel.TextColor3 = teamColor
        nameLabel.TextSize = ESPConfig.TEXT_SIZE
        nameLabel.Font = ESPConfig.TEXT_FONT
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameLabel.Parent = billboard
        
        -- Create ScreenGui for box
        local container = Instance.new("ScreenGui")
        container.Name = "BoxESP_" .. player.Name
        container.ResetOnSpawn = false
        container.Parent = game.CoreGui
        container.Enabled = true
        container.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        container.DisplayOrder = 10
        
        local boxFrame = Instance.new("Frame")
        boxFrame.Size = UDim2.new(0, 0, 0, 0)
        boxFrame.Position = UDim2.new(0, 0, 0, 0)
        boxFrame.BackgroundTransparency = 1
        boxFrame.BorderSizePixel = 0
        boxFrame.Visible = false
        boxFrame.Parent = container
        
        -- Box lines
        local topLine = Instance.new("Frame")
        topLine.Size = UDim2.new(1, 0, 0, ESPConfig.BoxThickness)
        topLine.Position = UDim2.new(0, 0, 0, 0)
        topLine.BackgroundColor3 = teamColor
        topLine.BackgroundTransparency = 0.3
        topLine.BorderSizePixel = 0
        topLine.Parent = boxFrame
        
        local bottomLine = Instance.new("Frame")
        bottomLine.Size = UDim2.new(1, 0, 0, ESPConfig.BoxThickness)
        bottomLine.Position = UDim2.new(0, 0, 1, -ESPConfig.BoxThickness)
        bottomLine.BackgroundColor3 = teamColor
        bottomLine.BackgroundTransparency = 0.3
        bottomLine.BorderSizePixel = 0
        bottomLine.Parent = boxFrame
        
        local leftLine = Instance.new("Frame")
        leftLine.Size = UDim2.new(0, ESPConfig.BoxThickness, 1, 0)
        leftLine.Position = UDim2.new(0, 0, 0, 0)
        leftLine.BackgroundColor3 = teamColor
        leftLine.BackgroundTransparency = 0.3
        leftLine.BorderSizePixel = 0
        leftLine.Parent = boxFrame
        
        local rightLine = Instance.new("Frame")
        rightLine.Size = UDim2.new(0, ESPConfig.BoxThickness, 1, 0)
        rightLine.Position = UDim2.new(1, -ESPConfig.BoxThickness, 0, 0)
        rightLine.BackgroundColor3 = teamColor
        rightLine.BackgroundTransparency = 0.3
        rightLine.BorderSizePixel = 0
        rightLine.Parent = boxFrame
        
        -- Health bar
        local healthBg = Instance.new("Frame")
        healthBg.Size = UDim2.new(0, 6, 1, 0)
        healthBg.Position = UDim2.new(1, 4, 0, 0)
        healthBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        healthBg.BorderSizePixel = 1
        healthBg.BorderColor3 = Color3.fromRGB(0, 0, 0)
        healthBg.Parent = boxFrame
        
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
    
    if espData.TopLine then
        espData.TopLine.BackgroundColor3 = teamColor
        espData.BottomLine.BackgroundColor3 = teamColor
        espData.LeftLine.BackgroundColor3 = teamColor
        espData.RightLine.BackgroundColor3 = teamColor
    end
end

-- =============================================
-- MAIN ESP UPDATE LOOP - 1000m RANGE
-- =============================================
task.spawn(function()
    while ScriptActive do
        task.wait(ESPConfig.ScanInterval)
        
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
                    espData.Billboard.Enabled = true
                end
                
                -- Update highlight
                if espData.Highlight then
                    espData.Highlight.Parent = character
                    espData.Highlight.Enabled = true
                end
                
                espData.Container.Enabled = true
                
                -- Get player position on screen
                local pos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                
                -- Check distance - EXACTLY 1000m range
                local dist = (Camera.CFrame.Position - rootPart.Position).Magnitude
                local isInRange = dist <= ESPConfig.MaxESPDistance -- 1000 meters
                
                if onScreen and isInRange then
                    -- Show everything
                    espData.BoxFrame.Visible = true
                    
                    -- Calculate box size (adjusted for 1000m range)
                    local boxSize = math.clamp(600 / dist * 5, 20, 200)
                    
                    espData.BoxFrame.Size = UDim2.new(0, boxSize, 0, boxSize * 1.5)
                    espData.BoxFrame.Position = UDim2.new(0, pos.X - boxSize/2, 0, pos.Y - boxSize * 1.5/2)
                    
                    -- Update health
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
                        else
                            espData.NameLabel.Text = player.Name
                        end
                    else
                        espData.NameLabel.Text = player.Name
                    end
                else
                    -- Hide everything when player is off-screen or out of range (>1000m)
                    espData.BoxFrame.Visible = false
                    if espData.Billboard then espData.Billboard.Enabled = false end
                    if espData.Highlight then espData.Highlight.Enabled = false end
                end
            end
        end)
    end
end)

-- =============================================
-- SPEED & JUMP SYSTEM
-- =============================================
local function applyStats()
    if not ScriptActive then return end
    pcall(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            local humanoid = char.Humanoid
            humanoid.WalkSpeed = ESPConfig.Speed
            humanoid.JumpPower = ESPConfig.JumpPower
            
            if humanoid.FloorMaterial ~= Enum.Material.Air then
                isGrounded = true
                airJumpsLeft = ESPConfig.MaxAirJumps
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
            airJumpsLeft = ESPConfig.MaxAirJumps
            return
        end
        
        if airJumpsLeft > 0 and humanoid.FloorMaterial == Enum.Material.Air then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            airJumpsLeft = airJumpsLeft - 1
        end
    end)
end)

-- =============================================
-- CHARACTER RESPAWN HANDLER
-- =============================================
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    applyStats()
    airJumpsLeft = ESPConfig.MaxAirJumps
    isGrounded = true
end)

-- =============================================
-- INITIALIZE ESP FOR ALL PLAYERS
-- =============================================
task.wait(1)
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        createBoxESP(player)
        player:GetPropertyChangedSignal("Team"):Connect(function()
            onTeamChanged(player)
        end)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        task.wait(1)
        createBoxESP(player)
        player:GetPropertyChangedSignal("Team"):Connect(function()
            onTeamChanged(player)
        end)
    end
end)

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

-- =============================================
-- RAYFIELD UI INTEGRATION
-- =============================================
local RayfieldLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/Rayfield.lua"))()

-- Create the Rayfield Window
local Window = RayfieldLibrary:CreateWindow({
    Name = "Blox Fruit ESP",
    LoadingTitle = "Blox Fruit Ultimate Mobile",
    LoadingSubtitle = "1km ESP Range",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "BloxFruitESP",
        FileName = "Settings"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true
    },
    KeySystem = false,
    Theme = "DarkBlue",
    Icon = 0
})

-- =============================================
-- CREATE UI TABS
-- =============================================

-- Main Tab
local MainTab = Window:CreateTab("Main", "home")

-- ESP Controls Section
local ESPControls = MainTab:CreateSection("ESP Controls (1km Range)")

-- ESP Toggle
local ESPToggle = MainTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = true,
    Flag = "ESPToggle",
    Callback = function(Value)
        ESPConfig.ESPEnabled = Value
        for _, espData in pairs(ESPObjects) do
            if espData and espData.Container then
                espData.Container.Enabled = Value
            end
            if espData and espData.Billboard then
                espData.Billboard.Enabled = Value
            end
            if espData and espData.Highlight then
                espData.Highlight.Enabled = Value
            end
        end
    end
})

-- Distance Info Label
local DistanceInfo = MainTab:CreateLabel("ESP Range: 1000 meters")

-- Speed Section
local SpeedSection = MainTab:CreateSection("Movement")

-- Speed Slider
local SpeedSlider = MainTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 250},
    Increment = 1,
    Suffix = "",
    CurrentValue = 100,
    Flag = "WalkSpeed",
    Callback = function(Value)
        ESPConfig.Speed = Value
        applyStats()
    end
})

-- Jump Power Slider
local JumpSlider = MainTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 200},
    Increment = 5,
    Suffix = "",
    CurrentValue = 80,
    Flag = "JumpPower",
    Callback = function(Value)
        ESPConfig.JumpPower = Value
        applyStats()
    end
})

-- Air Jumps Slider
local AirJumpsSlider = MainTab:CreateSlider({
    Name = "Air Jumps",
    Range = {0, 10},
    Increment = 1,
    Suffix = "",
    CurrentValue = 5,
    Flag = "AirJumps",
    Callback = function(Value)
        ESPConfig.MaxAirJumps = Value
        airJumpsLeft = Value
    end
})

-- Players Tab
local PlayersTab = Window:CreateTab("Players", "users")

-- Player List Section
local PlayerListSection = PlayersTab:CreateSection("Player List")

-- Create a label for player count
local PlayerCountLabel = PlayersTab:CreateLabel("Players Online: 0")

-- Function to update player list
local function UpdatePlayerList()
    local players = Players:GetPlayers()
    local count = #players - 1 -- Exclude local player
    PlayerCountLabel:Set("Players Online: " .. count)
end

-- Update player list every 2 seconds
task.spawn(function()
    while ScriptActive do
        UpdatePlayerList()
        task.wait(2)
    end
end)

-- Colors Tab
local ColorsTab = Window:CreateTab("Colors", "palette")

-- Team Colors Section
local TeamColorsSection = ColorsTab:CreateSection("Team Colors")

-- Team Color Display
local function CreateTeamColorDisplay(teamName, team)
    local color = team and team.TeamColor.Color or Color3.fromRGB(128, 128, 128)
    local displayLabel = ColorsTab:CreateLabel(
        teamName .. ": " .. (team and team.Name or "No Team"),
        nil,
        color,
        true
    )
    return displayLabel
end

-- Display all teams
for _, team in ipairs(Teams:GetTeams()) do
    CreateTeamColorDisplay(team.Name, team)
end

-- Toggle Highlight
local HighlightToggle = ColorsTab:CreateToggle({
    Name = "Enable Highlight",
    CurrentValue = true,
    Flag = "HighlightToggle",
    Callback = function(Value)
        ESPConfig.HIGHLIGHT_ENABLED = Value
        for _, espData in pairs(ESPObjects) do
            if espData and espData.Highlight then
                espData.Highlight.Enabled = Value and ESPConfig.ESPEnabled
            end
        end
    end
})

-- Info Tab
local InfoTab = Window:CreateTab("Info", "info")

-- Info Section
local InfoSection = InfoTab:CreateSection("About")

InfoTab:CreateLabel("Blox Fruit Ultimate Mobile")
InfoTab:CreateLabel("Version: 1.0")
InfoTab:CreateLabel("ESP Range: 1000m")
InfoTab:CreateLabel("Features:")
InfoTab:CreateLabel("• Team-based ESP")
InfoTab:CreateLabel("• Speed Boost")
InfoTab:CreateLabel("• Air Jump")
InfoTab:CreateLabel("• Player Tracking")

-- Credits
local CreditsSection = InfoTab:CreateSection("Credits")
InfoTab:CreateLabel("Developed with Rayfield UI")

-- =============================================
-- INITIALIZATION LOG
-- =============================================
print("")
print("╔══════════════════════════════════════╗")
print("║     BLOX FRUIT ULTIMATE MOBILE      ║")
print("╠══════════════════════════════════════╣")
print("║  ⚡ Speed: " .. ESPConfig.Speed .. "                      ║")
print("║  🦘 Jump: " .. ESPConfig.JumpPower .. " | Air: " .. ESPConfig.MaxAirJumps .. "   ║")
print("║  👁️  TEAM ESP: ENABLED (1km)         ║")
print("║  📍 Scan Rate: 0.1s                  ║")
print("║  📏 Max Distance: 1000m              ║")
print("╠══════════════════════════════════════╣")
print("║  Use Rayfield UI to control settings ║")
print("╚══════════════════════════════════════╝")
print("")
