--[[
    UNIVERSAL ESP SCRIPT - Rayfield UI
    Highlight-based player detection + Speed Boost + Air Jump + FPS Counter
    Powered by Rayfield UI Library
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

-- Load Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

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

-- Clean up function
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
        pcall(function() Rayfield:Destroy() end)
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
-- CREATE RAYFIELD UI
-- =============================================
local function createUI()
    Window = Rayfield:CreateWindow({
        Name = "Universal ESP",
        Icon = 0, -- No icon
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
        Theme = "DarkBlue" -- Dark theme matches ESP style
    })
    
    -- =============================================
    -- ESP TAB
    -- =============================================
    local ESPTab = Window:CreateTab("ESP", 0) -- Eye icon
    
    local ESPSection = ESPTab:CreateSection("ESP Controls")
    
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
    
    local StatsSection = ESPTab:CreateSection("Stats")
    
    ESPTab:CreateLabel("⚡ Speed: " .. Config.Speed)
    ESPTab:CreateLabel("🦘 Jump: " .. Config.JumpPower .. " | Air: " .. Config.MaxAirJumps)
    
    -- =============================================
    -- PLAYER TAB
    -- =============================================
    local PlayerTab = Window:CreateTab("Player", 0) -- User icon
    
    local InfoSection = PlayerTab:CreateSection("Player Info")
    
    PlayerTab:CreateLabel("👤 " .. LocalPlayer.Name)
    
    local BountyLabel = PlayerTab:CreateLabel("💰 Bounty: Searching...")
    
    PlayerTab:CreateSection("Health")
    
    local HealthLabel = PlayerTab:CreateLabel("Health: 100%")
    
    -- =============================================
    -- SETTINGS TAB
    -- =============================================
    local SettingsTab = Window:CreateTab("Settings", 0) -- Gear icon
    
    local StatsSection2 = SettingsTab:CreateSection("Permanent Stats")
    
    SettingsTab:CreateLabel("Walk Speed: " .. Config.Speed)
    SettingsTab:CreateLabel("Jump Power: " .. Config.JumpPower)
    SettingsTab:CreateLabel("Air Jumps: " .. Config.MaxAirJumps)
    
    local ControlSection = SettingsTab:CreateSection("Controls")
    
    SettingsTab:CreateButton({
        Name = "Toggle ESP",
        Callback = function()
            Config.ESPEnabled = not Config.ESPEnabled
            Rayfield:Notify({
                Title = "ESP " .. (Config.ESPEnabled and "Enabled" or "Disabled"),
                Content = "ESP is now " .. (Config.ESPEnabled and "active" or "inactive"),
                Duration = 2
            })
        end
    })
    
    SettingsTab:CreateButton({
        Name = "⚠️ Terminate Script",
        Callback = function()
            terminateScript()
        end
    })
    
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

-- FPS update (shown in Rayfield title bar)
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
                    if Window then
                        Window:SetSubtitle("FPS: " .. fps)
                    end
                end)
            else
                pcall(function()
                    if Window then
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
            if char and char:FindFirstChild("Humanoid") and UI and UI.HealthLabel then
                local humanoid = char.Humanoid
                local percent = math.floor((humanoid.Health / humanoid.MaxHealth) * 100)
                UI.HealthLabel:Set("Health: " .. percent .. "%")
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
            UI.BountyLabel:Set(bounty and "💰 Bounty: " .. bounty or "💰 Bounty: Not found")
        end
        task.wait(3)
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

-- Clean up when Rayfield closes
Rayfield:OnClose(function()
    terminateScript()
end)

print("")
print("╔══════════════════════════════════════╗")
print("║     UNIVERSAL ESP - Rayfield UI     ║")
print("╠══════════════════════════════════════╣")
print("║  ⚡ Speed: " .. Config.Speed .. "                      ║")
print("║  🦘 Jump: " .. Config.JumpPower .. " | Air: " .. Config.MaxAirJumps .. "   ║")
print("║  👁️  HIGHLIGHT ESP (1km)             ║")
print("║  📊 FPS: ENABLED                     ║")
print("║  📍 Scan Rate: 0.1s                  ║")
print("║  📏 Max Distance: 2000m              ║")
print("╠══════════════════════════════════════╣")
print("║  Works on ANY Roblox Game!          ║")
print("║  Powered by Rayfield UI Library     ║")
print("╚══════════════════════════════════════╝")
print("")
