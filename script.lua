--[[
    Script Name: faqih lua hub | jump for a egg (Auto-Execute & Smart Egg Farm Edition - Auto Drop & Fixed Interaction)
    Credits: powered by faqih
]]--

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- Target UI Container Safe Guard
local TargetGui
pcall(function() TargetGui = CoreGui end)
if not TargetGui then TargetGui = LocalPlayer:WaitForChild("PlayerGui") end

-- Cleanup Old UI
local oldUI = TargetGui:FindFirstChild("FaluaLuaUI_v7")
if oldUI then oldUI:Destroy() end

-- System Variables
local SafeZoneBlock = nil
local IsFarming = false

-- Configuration State
local PlayerState = {
    FlyUIVisible = false,
    IsFlying = false,
    FlySpeed = 350,
    Noclip = false,
    AutoFarmEgg = false,
    StealPriority = true,
    SelectedRarities = {
        Common = true, Uncommon = true, Rare = true, Epic = true,
        Legendary = true, Mythic = true, Divine = true, Celestial = true,
        Eternal = true, Ascended = true
    },
    SelectedZones = {
        Meadow = true, CoralReef = true, Winter = true, Desert = true,
        CrystalMines = true, Jungle = true, MysticIsles = true,
        Prehistoric = true, CelestialHeights = true
    }
}

-- Variabel Engine Controller untuk Fly
local flyBodyVelocity, flyBodyGyro

-- Asset & Texture IDs
local CustomToggleImageAsset = "rbxthumb://type=Asset&id=136902684546260&w=150&h=150"

-- URL Raw Script
local RAW_SCRIPT_URL = "https://raw.githubusercontent.com/n01771542-cmd/faqihlualua/refs/heads/main/script.lua"

-- =================================================================
-- ADVANCED SERVER HOP ENGINE
-- =================================================================
local function ServerHopByCount(targetPlayerCount)
    local placeId = game.PlaceId
    local currentJobId = game.JobId
    
    local queueFunc = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
    if queueFunc then
        queueFunc(string.format([[
            repeat task.wait(1) until game:IsLoaded()
            task.wait(2)
            loadstring(game:HttpGet("%s"))()
        ]], RAW_SCRIPT_URL))
    end

    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/0?sortOrder=Asc&limit=100"))
    end)
    
    if success and result and result.data then
        local matchedServers = {}
        local fallbackServers = {}
        
        for _, server in ipairs(result.data) do
            if type(server) == "table" and server.id ~= currentJobId then
                if server.playing == targetPlayerCount then
                    table.insert(matchedServers, server.id)
                elseif server.playing < 7 then
                    table.insert(fallbackServers, server.id)
                end
            end
        end
        
        if #matchedServers > 0 then
            local targetServer = matchedServers[math.random(1, #matchedServers)]
            TeleportService:TeleportToPlaceInstance(placeId, targetServer, LocalPlayer)
        elseif #fallbackServers > 0 then
            local targetServer = fallbackServers[math.random(1, #fallbackServers)]
            TeleportService:TeleportToPlaceInstance(placeId, targetServer, LocalPlayer)
        else
            TeleportService:Teleport(placeId, LocalPlayer)
        end
    else
        TeleportService:Teleport(placeId, LocalPlayer)
    end
end

-- =================================================================
-- AUTO CREATE SAFE ZONE BLOCK
-- =================================================================
local function CreateSafeZoneAtCurrentPos()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    
    if hrp then
        if SafeZoneBlock then SafeZoneBlock:Destroy() end
        
        SafeZoneBlock = Instance.new("Part")
        SafeZoneBlock.Name = "SafeZoneBlock_Abdillah"
        SafeZoneBlock.Size = Vector3.new(12, 1, 12)
        SafeZoneBlock.CFrame = hrp.CFrame - Vector3.new(0, 2.5, 0)
        SafeZoneBlock.Anchored = true
        SafeZoneBlock.CanCollide = true
        SafeZoneBlock.Transparency = 1
        SafeZoneBlock.Parent = workspace
    end
end

task.spawn(CreateSafeZoneAtCurrentPos)
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    CreateSafeZoneAtCurrentPos()
end)

-- =================================================================
-- SAFE DROP ITEM ENGINE
-- =================================================================
local function DropHeldItems()
    local char = LocalPlayer.Character
    if not char then return end
    
    local heldTool = char:FindFirstChildOfClass("Tool")
    if heldTool then
        heldTool.CanBeDropped = true
        heldTool.Parent = workspace
    end
    
    local rep = game:GetService("ReplicatedStorage")
    local dropRemote = rep:FindFirstChild("DropItem", true) or rep:FindFirstChild("Drop", true) or rep:FindFirstChild("DropTool", true)
    if dropRemote and dropRemote:IsA("RemoteEvent") then
        pcall(function() dropRemote:FireServer(heldTool) end)
    end
end

-- =================================================================
-- TELEPORT INSTANT TO SAFE ZONE BLOCK
-- =================================================================
local function TeleportToSafeZone()
    if not SafeZoneBlock or not SafeZoneBlock.Parent then 
        CreateSafeZoneAtCurrentPos()
        task.wait(0.1)
    end
    
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if hrp and hum and hum.Health > 0 then
        local targetCFrame = SafeZoneBlock.CFrame + Vector3.new(0, 3.5, 0)
        
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        hrp.CFrame = targetCFrame
        
        task.wait(0.1)
        DropHeldItems()
    end
end

-- =================================================================
-- SMART EGG SCANNER & TELEPORT ENGINE (FIXED: DROP FIRST & 1x PRESS)
-- =================================================================
local RarityPriority = {
    Ascended = 10, Eternal = 9, Celestial = 8, Divine = 7,
    Mythic = 6, Legendary = 5, Epic = 4, Rare = 3,
    Uncommon = 2, Common = 1
}

local function GetValidEggTargets()
    local validTargets = {}
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local eggModel = obj.Parent
            while eggModel and eggModel ~= workspace and not eggModel:IsA("Model") do
                eggModel = eggModel.Parent
            end
            
            if eggModel then
                local rarity = eggModel:GetAttribute("Rarity") or "Common"
                local zone = eggModel:GetAttribute("Zone") or "Meadow"
                
                for rName, _ in pairs(PlayerState.SelectedRarities) do
                    if string.find(string.lower(eggModel.Name), string.lower(rName)) then rarity = rName end
                end
                for zName, _ in pairs(PlayerState.SelectedZones) do
                    if string.find(string.lower(eggModel.Name), string.lower(zName)) then zone = zName end
                end
                
                if PlayerState.SelectedRarities[rarity] and PlayerState.SelectedZones[zone] then
                    table.insert(validTargets, {
                        Prompt = obj,
                        Model = eggModel,
                        Rarity = rarity,
                        Priority = RarityPriority[rarity] or 1,
                        Part = obj.Parent:IsA("BasePart") and obj.Parent or eggModel:FindFirstChildWhichIsA("BasePart")
                    })
                end
            end
        end
    end
    
    if PlayerState.StealPriority then
        table.sort(validTargets, function(a, b) return a.Priority > b.Priority end)
    end
    
    return validTargets
end

local function ProcessSmartEggTeleport()
    if IsFarming or not PlayerState.AutoFarmEgg then return end
    
    local targets = GetValidEggTargets()
    if #targets == 0 then return end
    
    local target = targets[1]
    if not target or not target.Part or not target.Prompt then return end
    
    IsFarming = true
    
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    if hrp then
        -- 1. Auto Drop item sebelum TP agar slot tangan kosong
        DropHeldItems()
        task.wait(0.1)
        
        -- 2. Teleport ke Lokasi Telur
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        hrp.CFrame = target.Part.CFrame + Vector3.new(0, 1.5, 0)
        
        -- 3. Jeda sejenak agar server mengonfirmasi posisi karakter
        task.wait(0.25)
        
        -- 4. Eksekusi Interaksi 1 Kali Sahaja
        local prompt = target.Prompt
        if fireproximityprompt then
            fireproximityprompt(prompt)
        else
            pcall(function()
                prompt:InputHoldBegin()
                task.wait(0.1)
                prompt:InputHoldEnd()
            end)
        end
        
        -- 5. Beri waktu agar server memproses telur ke tangan
        task.wait(0.4)
        
        -- 6. Teleport balik ke Balok Gaib / Safe Zone
        TeleportToSafeZone()
        task.wait(0.2)
    end
    
    IsFarming = false
end

-- Loop Auto Farm
task.spawn(function()
    while task.wait(0.4) do
        if PlayerState.AutoFarmEgg then
            pcall(ProcessSmartEggTeleport)
        end
    end
end)

-- Setup Manual Interaction (Bila mendekati telur secara manual/pake fly)
local function SetupPrompt(prompt)
    if prompt:IsA("ProximityPrompt") then
        prompt.HoldDuration = 0 -- Mempercepat interaksi manual
        prompt.RequiresLineOfSight = false
        
        prompt.Triggered:Connect(function(playerWhoTriggered)
            if playerWhoTriggered == LocalPlayer and not PlayerState.AutoFarmEgg then
                DropHeldItems()
                task.wait(0.4)
                TeleportToSafeZone()
            end
        end)
    end
end

for _, prompt in pairs(workspace:GetDescendants()) do SetupPrompt(prompt) end
workspace.DescendantAdded:Connect(SetupPrompt)

-- =================================================================
-- FLY ENGINE
-- =================================================================
local function StartFlyEngine()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    hum.PlatformStand = true

    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    flyBodyVelocity.Velocity = Vector3.zero
    flyBodyVelocity.Parent = hrp

    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    flyBodyGyro.P = 9e4
    flyBodyGyro.CFrame = hrp.CFrame
    flyBodyGyro.Parent = hrp
end

local function StopFlyEngine()
    if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
    if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
        if not PlayerState.Noclip then
            for _, part in ipairs(char:GetChildren()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end
end

-- =================================================================
-- GUI BASE SETUP
-- =================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FaluaLuaUI_v7"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = TargetGui

-- Toggle Button (Logo Aplikasi)
local ToggleBtn = Instance.new("ImageButton", ScreenGui)
ToggleBtn.Name = "ToggleImageBtn"
ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
ToggleBtn.Position = UDim2.new(0.02, 0, 0.2, 0)
ToggleBtn.BackgroundTransparency = 1
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Image = CustomToggleImageAsset
ToggleBtn.ScaleType = Enum.ScaleType.Fit
ToggleBtn.Active = true
ToggleBtn.Draggable = true
ToggleBtn.Visible = false

local ToggleCorner = Instance.new("UICorner", ToggleBtn)
ToggleCorner.CornerRadius = UDim.new(0, 8)

-- Panel Utama
local TeleportWindow = Instance.new("Frame", ScreenGui)
TeleportWindow.Name = "TeleportWindow"
TeleportWindow.Size = UDim2.new(0, 440, 0, 280)
TeleportWindow.Position = UDim2.new(0.3, 0, 0.25, 0)
TeleportWindow.BackgroundColor3 = Color3.fromRGB(20, 24, 33)
TeleportWindow.ClipsDescendants = true
TeleportWindow.BorderSizePixel = 0
TeleportWindow.Active = true
TeleportWindow.Draggable = true
TeleportWindow.Visible = true

local WindowCorner = Instance.new("UICorner", TeleportWindow)
WindowCorner.CornerRadius = UDim.new(0, 10)

local WindowStroke = Instance.new("UIStroke", TeleportWindow)
WindowStroke.Color = Color3.fromRGB(70, 85, 110)
WindowStroke.Thickness = 1

-- Header Bar
local TopBar = Instance.new("Frame", TeleportWindow)
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 32)
TopBar.BackgroundColor3 = Color3.fromRGB(12, 15, 22)
TopBar.BorderSizePixel = 0
TopBar.ZIndex = 2

local TopBarCorner = Instance.new("UICorner", TopBar)
TopBarCorner.CornerRadius = UDim.new(0, 10)

local AppTitle = Instance.new("TextLabel", TopBar)
AppTitle.Size = UDim2.new(1, -40, 1, 0)
AppTitle.Position = UDim2.new(0, 12, 0, 0)
AppTitle.BackgroundTransparency = 1
AppTitle.Text = "faqih lua hub  |  jump for a egg"
AppTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
AppTitle.Font = Enum.Font.GothamMedium
AppTitle.TextSize = 11
AppTitle.TextXAlignment = Enum.TextXAlignment.Left
AppTitle.ZIndex = 3

local CloseMainBtn = Instance.new("TextButton", TopBar)
CloseMainBtn.Size = UDim2.new(0, 20, 0, 20)
CloseMainBtn.Position = UDim2.new(1, -26, 0.5, -10)
CloseMainBtn.BackgroundTransparency = 1
CloseMainBtn.Text = "x"
CloseMainBtn.TextColor3 = Color3.fromRGB(220, 225, 235)
CloseMainBtn.Font = Enum.Font.GothamBold
CloseMainBtn.TextSize = 13
CloseMainBtn.ZIndex = 3

-- Sidebar Left Panel
local Sidebar = Instance.new("Frame", TeleportWindow)
Sidebar.Size = UDim2.new(0, 110, 1, -32)
Sidebar.Position = UDim2.new(0, 0, 0, 32)
Sidebar.BackgroundColor3 = Color3.fromRGB(14, 17, 24)
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 2

local SidebarLayout = Instance.new("UIListLayout", Sidebar)
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Padding = UDim.new(0, 2)

local SidebarPadding = Instance.new("UIPadding", Sidebar)
SidebarPadding.PaddingTop = UDim.new(0, 8)
SidebarPadding.PaddingLeft = UDim.new(0, 6)

local function CreateTabBtn(name)
    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(1, -6, 0, 28)
    btn.BackgroundTransparency = 1
    btn.BackgroundColor3 = Color3.fromRGB(35, 42, 58)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(180, 190, 205)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 11
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.ZIndex = 3
    
    local pad = Instance.new("UIPadding", btn)
    pad.PaddingLeft = UDim.new(0, 10)
    
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 6)
    return btn
end

local MainTabBtn = CreateTabBtn("Main")
local EggFarmTabBtn = CreateTabBtn("Egg Farm")
local ServerHopTabBtn = CreateTabBtn("Server Hop")
local InfoTabBtn = CreateTabBtn("Info / Fitur")

-- =================================================================
-- CONTENT PANELS
-- =================================================================

-- 1. MAIN TAB CONTENT
local MainContent = Instance.new("Frame", TeleportWindow)
MainContent.Size = UDim2.new(1, -122, 1, -40)
MainContent.Position = UDim2.new(0, 116, 0, 36)
MainContent.BackgroundTransparency = 1
MainContent.Visible = true
MainContent.ZIndex = 2

local CardsContainer = Instance.new("Frame", MainContent)
CardsContainer.Size = UDim2.new(1, 0, 1, 0)
CardsContainer.BackgroundTransparency = 1
CardsContainer.ZIndex = 2

local CardsLayout = Instance.new("UIListLayout", CardsContainer)
CardsLayout.SortOrder = Enum.SortOrder.LayoutOrder
CardsLayout.Padding = UDim.new(0, 6)

local PlaceBlockBtn = Instance.new("TextButton", CardsContainer)
PlaceBlockBtn.Size = UDim2.new(1, -10, 0, 36)
PlaceBlockBtn.BackgroundColor3 = Color3.fromRGB(28, 35, 48)
PlaceBlockBtn.Text = ""
PlaceBlockBtn.ZIndex = 3

local PlaceCorner = Instance.new("UICorner", PlaceBlockBtn)
PlaceCorner.CornerRadius = UDim.new(0, 6)

local PlaceTitle = Instance.new("TextLabel", PlaceBlockBtn)
PlaceTitle.Size = UDim2.new(1, -10, 1, 0)
PlaceTitle.Position = UDim2.new(0, 10, 0, 0)
PlaceTitle.BackgroundTransparency = 1
PlaceTitle.Text = "Reset/Atur Ulang Balok Gaib"
PlaceTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
PlaceTitle.Font = Enum.Font.GothamMedium
PlaceTitle.TextSize = 11
PlaceTitle.TextXAlignment = Enum.TextXAlignment.Left
PlaceTitle.ZIndex = 4

local FlyMainToggleBtn = Instance.new("TextButton", CardsContainer)
FlyMainToggleBtn.Size = UDim2.new(1, -10, 0, 36)
FlyMainToggleBtn.BackgroundColor3 = Color3.fromRGB(28, 35, 48)
FlyMainToggleBtn.Text = ""
FlyMainToggleBtn.ZIndex = 3

local FlyMainCorner = Instance.new("UICorner", FlyMainToggleBtn)
FlyMainCorner.CornerRadius = UDim.new(0, 6)

local FlyMainTitle = Instance.new("TextLabel", FlyMainToggleBtn)
FlyMainTitle.Size = UDim2.new(1, -70, 1, 0)
FlyMainTitle.Position = UDim2.new(0, 10, 0, 0)
FlyMainTitle.BackgroundTransparency = 1
FlyMainTitle.Text = "Fly Controller Engine"
FlyMainTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
FlyMainTitle.Font = Enum.Font.GothamMedium
FlyMainTitle.TextSize = 11
FlyMainTitle.TextXAlignment = Enum.TextXAlignment.Left
FlyMainTitle.ZIndex = 4

local FlyStatusLabel = Instance.new("TextLabel", FlyMainToggleBtn)
FlyStatusLabel.Size = UDim2.new(0, 45, 1, 0)
FlyStatusLabel.Position = UDim2.new(1, -50, 0, 0)
FlyStatusLabel.BackgroundTransparency = 1
FlyStatusLabel.Text = "OFF"
FlyStatusLabel.TextColor3 = Color3.fromRGB(239, 68, 68)
FlyStatusLabel.Font = Enum.Font.GothamBold
FlyStatusLabel.TextSize = 11
FlyStatusLabel.TextXAlignment = Enum.TextXAlignment.Right
FlyStatusLabel.ZIndex = 4

-- 2. EGG FARM TAB CONTENT
local EggFarmContent = Instance.new("Frame", TeleportWindow)
EggFarmContent.Size = UDim2.new(1, -122, 1, -40)
EggFarmContent.Position = UDim2.new(0, 116, 0, 36)
EggFarmContent.BackgroundTransparency = 1
EggFarmContent.Visible = false
EggFarmContent.ZIndex = 2

local ScrollEgg = Instance.new("ScrollingFrame", EggFarmContent)
ScrollEgg.Size = UDim2.new(1, -5, 1, 0)
ScrollEgg.BackgroundTransparency = 1
ScrollEgg.BorderSizePixel = 0
ScrollEgg.ScrollBarThickness = 3
ScrollEgg.CanvasSize = UDim2.new(0, 0, 0, 360)
ScrollEgg.ZIndex = 3

local ScrollEggLayout = Instance.new("UIListLayout", ScrollEgg)
ScrollEggLayout.SortOrder = Enum.SortOrder.LayoutOrder
ScrollEggLayout.Padding = UDim.new(0, 6)

-- Master Toggle Farm
local FarmMasterBtn = Instance.new("TextButton", ScrollEgg)
FarmMasterBtn.Size = UDim2.new(1, -10, 0, 36)
FarmMasterBtn.BackgroundColor3 = Color3.fromRGB(28, 35, 48)
FarmMasterBtn.Text = ""
FarmMasterBtn.ZIndex = 4

local FarmMasterCorner = Instance.new("UICorner", FarmMasterBtn)
FarmMasterCorner.CornerRadius = UDim.new(0, 6)

local FarmMasterTitle = Instance.new("TextLabel", FarmMasterBtn)
FarmMasterTitle.Size = UDim2.new(1, -70, 1, 0)
FarmMasterTitle.Position = UDim2.new(0, 10, 0, 0)
FarmMasterTitle.BackgroundTransparency = 1
FarmMasterTitle.Text = "⚡ Auto Teleport Egg (Farm)"
FarmMasterTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
FarmMasterTitle.Font = Enum.Font.GothamBold
FarmMasterTitle.TextSize = 11
FarmMasterTitle.TextXAlignment = Enum.TextXAlignment.Left
FarmMasterTitle.ZIndex = 5

local FarmStatusLabel = Instance.new("TextLabel", FarmMasterBtn)
FarmStatusLabel.Size = UDim2.new(0, 45, 1, 0)
FarmStatusLabel.Position = UDim2.new(1, -50, 0, 0)
FarmStatusLabel.BackgroundTransparency = 1
FarmStatusLabel.Text = "OFF"
FarmStatusLabel.TextColor3 = Color3.fromRGB(239, 68, 68)
FarmStatusLabel.Font = Enum.Font.GothamBold
FarmStatusLabel.TextSize = 11
FarmStatusLabel.TextXAlignment = Enum.TextXAlignment.Right
FarmStatusLabel.ZIndex = 5

-- Steal Toggle
local StealToggleBtn = Instance.new("TextButton", ScrollEgg)
StealToggleBtn.Size = UDim2.new(1, -10, 0, 32)
StealToggleBtn.BackgroundColor3 = Color3.fromRGB(28, 35, 48)
StealToggleBtn.Text = ""
StealToggleBtn.ZIndex = 4

local StealCorner = Instance.new("UICorner", StealToggleBtn)
StealCorner.CornerRadius = UDim.new(0, 6)

local StealTitle = Instance.new("TextLabel", StealToggleBtn)
StealTitle.Size = UDim2.new(1, -70, 1, 0)
StealTitle.Position = UDim2.new(0, 10, 0, 0)
StealTitle.BackgroundTransparency = 1
StealTitle.Text = "🔥 Steal Priority (Highest Rarity)"
StealTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
StealTitle.Font = Enum.Font.GothamMedium
StealTitle.TextSize = 10
StealTitle.TextXAlignment = Enum.TextXAlignment.Left
StealTitle.ZIndex = 5

local StealStatusLabel = Instance.new("TextLabel", StealToggleBtn)
StealStatusLabel.Size = UDim2.new(0, 45, 1, 0)
StealStatusLabel.Position = UDim2.new(1, -50, 0, 0)
StealStatusLabel.BackgroundTransparency = 1
StealStatusLabel.Text = "ON"
StealStatusLabel.TextColor3 = Color3.fromRGB(16, 185, 129)
StealStatusLabel.Font = Enum.Font.GothamBold
StealStatusLabel.TextSize = 10
StealStatusLabel.TextXAlignment = Enum.TextXAlignment.Right
StealStatusLabel.ZIndex = 5

-- Rarity Selection Info
local RarityLabel = Instance.new("TextLabel", ScrollEgg)
RarityLabel.Size = UDim2.new(1, -10, 0, 18)
RarityLabel.BackgroundTransparency = 1
RarityLabel.Text = "Filter Rarity Egg:"
RarityLabel.TextColor3 = Color3.fromRGB(147, 197, 253)
RarityLabel.Font = Enum.Font.GothamBold
RarityLabel.TextSize = 10
RarityLabel.TextXAlignment = Enum.TextXAlignment.Left
RarityLabel.ZIndex = 4

-- Grid Rarity Toggles
local RarityGrid = Instance.new("Frame", ScrollEgg)
RarityGrid.Size = UDim2.new(1, -10, 0, 110)
RarityGrid.BackgroundTransparency = 1
RarityGrid.ZIndex = 4

local RarityGridLayout = Instance.new("UIGridLayout", RarityGrid)
RarityGridLayout.CellSize = UDim2.new(0.48, -4, 0, 24)
RarityGridLayout.CellPadding = UDim2.new(0.04, 0, 0, 4)

for rName, enabled in pairs(PlayerState.SelectedRarities) do
    local rBtn = Instance.new("TextButton", RarityGrid)
    rBtn.BackgroundColor3 = enabled and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(40, 48, 64)
    rBtn.Text = rName
    rBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    rBtn.Font = Enum.Font.GothamMedium
    rBtn.TextSize = 9
    rBtn.ZIndex = 5
    
    local rCorner = Instance.new("UICorner", rBtn)
    rCorner.CornerRadius = UDim.new(0, 4)
    
    rBtn.MouseButton1Click:Connect(function()
        PlayerState.SelectedRarities[rName] = not PlayerState.SelectedRarities[rName]
        rBtn.BackgroundColor3 = PlayerState.SelectedRarities[rName] and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(40, 48, 64)
    end)
end

-- 3. SERVER HOP TAB CONTENT
local HopContent = Instance.new("Frame", TeleportWindow)
HopContent.Size = UDim2.new(1, -122, 1, -40)
HopContent.Position = UDim2.new(0, 116, 0, 36)
HopContent.BackgroundTransparency = 1
HopContent.Visible = false
HopContent.ZIndex = 2

local HopTitle = Instance.new("TextLabel", HopContent)
HopTitle.Size = UDim2.new(1, 0, 0, 20)
HopTitle.BackgroundTransparency = 1
HopTitle.Text = "Server Hop (Pilih Jumlah Player)"
HopTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
HopTitle.Font = Enum.Font.GothamBold
HopTitle.TextSize = 12
HopTitle.TextXAlignment = Enum.TextXAlignment.Left
HopTitle.ZIndex = 3

local HopStatusText = Instance.new("TextLabel", HopContent)
HopStatusText.Size = UDim2.new(1, -10, 0, 18)
HopStatusText.Position = UDim2.new(0, 0, 0, 22)
HopStatusText.BackgroundTransparency = 1
HopStatusText.Text = "Pilih server berdasarkan target pemain:"
HopStatusText.TextColor3 = Color3.fromRGB(180, 190, 205)
HopStatusText.Font = Enum.Font.Gotham
HopStatusText.TextSize = 10
HopStatusText.TextXAlignment = Enum.TextXAlignment.Left
HopStatusText.ZIndex = 3

local GridHopContainer = Instance.new("Frame", HopContent)
GridHopContainer.Size = UDim2.new(1, -10, 1, -48)
GridHopContainer.Position = UDim2.new(0, 0, 0, 44)
GridHopContainer.BackgroundTransparency = 1
GridHopContainer.ZIndex = 3

local GridHopLayout = Instance.new("UIGridLayout", GridHopContainer)
GridHopLayout.CellSize = UDim2.new(0.48, -4, 0, 36)
GridHopLayout.CellPadding = UDim2.new(0.04, 0, 0, 8)

for i = 1, 6 do
    local HopOptionBtn = Instance.new("TextButton", GridHopContainer)
    HopOptionBtn.Name = "HopBtn_" .. tostring(i)
    HopOptionBtn.BackgroundColor3 = Color3.fromRGB(28, 35, 48)
    HopOptionBtn.Text = "👤 " .. tostring(i) .. " Player"
    HopOptionBtn.TextColor3 = Color3.fromRGB(240, 245, 255)
    HopOptionBtn.Font = Enum.Font.GothamMedium
    HopOptionBtn.TextSize = 11
    HopOptionBtn.ZIndex = 4
    
    local hCorner = Instance.new("UICorner", HopOptionBtn)
    hCorner.CornerRadius = UDim.new(0, 6)
    
    HopOptionBtn.MouseButton1Click:Connect(function()
        HopStatusText.Text = "⏳ Teleporting + Auto Execute..."
        HopStatusText.TextColor3 = Color3.fromRGB(251, 191, 36)
        ServerHopByCount(i)
    end)
end

-- 4. INFO TAB CONTENT
local InfoContent = Instance.new("Frame", TeleportWindow)
InfoContent.Size = UDim2.new(1, -122, 1, -40)
InfoContent.Position = UDim2.new(0, 116, 0, 36)
InfoContent.BackgroundTransparency = 1
InfoContent.Visible = false
InfoContent.ZIndex = 2

local ScrollInfo = Instance.new("ScrollingFrame", InfoContent)
ScrollInfo.Size = UDim2.new(1, -5, 1, 0)
ScrollInfo.BackgroundTransparency = 1
ScrollInfo.BorderSizePixel = 0
ScrollInfo.ScrollBarThickness = 3
ScrollInfo.CanvasSize = UDim2.new(0, 0, 0, 280)
ScrollInfo.ZIndex = 3

local InfoLayout = Instance.new("UIListLayout", ScrollInfo)
InfoLayout.SortOrder = Enum.SortOrder.LayoutOrder
InfoLayout.Padding = UDim.new(0, 6)

local function AddInfoCard(titleText, descText)
    local card = Instance.new("Frame", ScrollInfo)
    card.Size = UDim2.new(1, -10, 0, 52)
    card.BackgroundColor3 = Color3.fromRGB(28, 35, 48)
    card.ZIndex = 4
    
    local cCorner = Instance.new("UICorner", card)
    cCorner.CornerRadius = UDim.new(0, 6)
    
    local tLabel = Instance.new("TextLabel", card)
    tLabel.Size = UDim2.new(1, -16, 0, 18)
    tLabel.Position = UDim2.new(0, 8, 0, 4)
    tLabel.BackgroundTransparency = 1
    tLabel.Text = titleText
    tLabel.TextColor3 = Color3.fromRGB(147, 197, 253)
    tLabel.Font = Enum.Font.GothamBold
    tLabel.TextSize = 10
    tLabel.TextXAlignment = Enum.TextXAlignment.Left
    tLabel.ZIndex = 5
    
    local dLabel = Instance.new("TextLabel", card)
    dLabel.Size = UDim2.new(1, -16, 0, 28)
    dLabel.Position = UDim2.new(0, 8, 0, 20)
    dLabel.BackgroundTransparency = 1
    dLabel.Text = descText
    dLabel.TextColor3 = Color3.fromRGB(220, 225, 235)
    dLabel.Font = Enum.Font.Gotham
    dLabel.TextSize = 9
    dLabel.TextWrapped = true
    dLabel.TextXAlignment = Enum.TextXAlignment.Left
    dLabel.TextYAlignment = Enum.TextYAlignment.Top
    dLabel.ZIndex = 5
end

AddInfoCard("⚡ Smart Egg Teleport", "Otomatis memindai Egg terdekat/paling langka, TP, hold, drop ke base, lalu TP balik.")
AddInfoCard("🎯 Filter Rarity & Priority", "Hanya memburu Rarity Egg yang di-aktifkan dan memprioritaskan Rarity tertinggi (Steal).")
AddInfoCard("🔄 Auto Execute", "Script otomatis berjalan kembali setelah Server Hop.")

-- Switch Tab Manager
local function SetActiveTab(selectedTab)
    MainTabBtn.BackgroundTransparency = 1
    MainTabBtn.TextColor3 = Color3.fromRGB(180, 190, 205)
    EggFarmTabBtn.BackgroundTransparency = 1
    EggFarmTabBtn.TextColor3 = Color3.fromRGB(180, 190, 205)
    ServerHopTabBtn.BackgroundTransparency = 1
    ServerHopTabBtn.TextColor3 = Color3.fromRGB(180, 190, 205)
    InfoTabBtn.BackgroundTransparency = 1
    InfoTabBtn.TextColor3 = Color3.fromRGB(180, 190, 205)
    
    MainContent.Visible = false
    EggFarmContent.Visible = false
    HopContent.Visible = false
    InfoContent.Visible = false
    
    if selectedTab == "Main" then
        MainTabBtn.BackgroundTransparency = 0
        MainTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        MainContent.Visible = true
    elseif selectedTab == "Farm" then
        EggFarmTabBtn.BackgroundTransparency = 0
        EggFarmTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        EggFarmContent.Visible = true
    elseif selectedTab == "Hop" then
        ServerHopTabBtn.BackgroundTransparency = 0
        ServerHopTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        HopContent.Visible = true
    elseif selectedTab == "Info" then
        InfoTabBtn.BackgroundTransparency = 0
        InfoTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        InfoContent.Visible = true
    end
end

MainTabBtn.MouseButton1Click:Connect(function() SetActiveTab("Main") end)
EggFarmTabBtn.MouseButton1Click:Connect(function() SetActiveTab("Farm") end)
ServerHopTabBtn.MouseButton1Click:Connect(function() SetActiveTab("Hop") end)
InfoTabBtn.MouseButton1Click:Connect(function() SetActiveTab("Info") end)
SetActiveTab("Main")

-- =================================================================
-- FLY MINI CONTROLLER FRAME
-- =================================================================
local FlyMiniFrame = Instance.new("Frame", ScreenGui)
FlyMiniFrame.Name = "FlyMiniFrame"
FlyMiniFrame.Size = UDim2.new(0, 165, 0, 110)
FlyMiniFrame.Position = UDim2.new(0.02, 0, 0.4, 0)
FlyMiniFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 33)
FlyMiniFrame.Active = true
FlyMiniFrame.Draggable = true
FlyMiniFrame.Visible = false
FlyMiniFrame.ZIndex = 100

local FlyMiniCorner = Instance.new("UICorner", FlyMiniFrame)
FlyMiniCorner.CornerRadius = UDim.new(0, 8)

local FlyStroke = Instance.new("UIStroke", FlyMiniFrame)
FlyStroke.Color = Color3.fromRGB(129, 140, 248)
FlyStroke.Thickness = 1.5

local FlyMiniTitle = Instance.new("TextLabel", FlyMiniFrame)
FlyMiniTitle.Size = UDim2.new(1, -12, 0, 28)
FlyMiniTitle.Position = UDim2.new(0, 10, 0, 2)
FlyMiniTitle.BackgroundTransparency = 1
FlyMiniTitle.Text = "🕊️ Fly Controller"
FlyMiniTitle.TextColor3 = Color3.fromRGB(240, 240, 255)
FlyMiniTitle.Font = Enum.Font.GothamBold
FlyMiniTitle.TextSize = 11
FlyMiniTitle.TextXAlignment = Enum.TextXAlignment.Left
FlyMiniTitle.ZIndex = 101

local FlyToggleBtn = Instance.new("TextButton", FlyMiniFrame)
FlyToggleBtn.Size = UDim2.new(0.88, 0, 0, 30)
FlyToggleBtn.Position = UDim2.new(0.06, 0, 0, 32)
FlyToggleBtn.BackgroundColor3 = Color3.fromRGB(225, 29, 72)
FlyToggleBtn.Text = "FLY : OFF"
FlyToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FlyToggleBtn.Font = Enum.Font.GothamBold
FlyToggleBtn.TextSize = 11
FlyToggleBtn.BorderSizePixel = 0
FlyToggleBtn.ZIndex = 101

local FlyToggleCorner = Instance.new("UICorner", FlyToggleBtn)
FlyToggleCorner.CornerRadius = UDim.new(0, 6)

local SpeedFrame = Instance.new("Frame", FlyMiniFrame)
SpeedFrame.Size = UDim2.new(0.88, 0, 0, 28)
SpeedFrame.Position = UDim2.new(0.06, 0, 0, 68)
SpeedFrame.BackgroundTransparency = 1
SpeedFrame.ZIndex = 101

local SpeedMinus = Instance.new("TextButton", SpeedFrame)
SpeedMinus.Size = UDim2.new(0.28, 0, 1, 0)
SpeedMinus.Position = UDim2.new(0, 0, 0, 0)
SpeedMinus.BackgroundColor3 = Color3.fromRGB(27, 33, 45)
SpeedMinus.Text = "-"
SpeedMinus.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedMinus.Font = Enum.Font.GothamBold
SpeedMinus.TextSize = 14
SpeedMinus.BorderSizePixel = 0
SpeedMinus.ZIndex = 102

local SpeedMinusCorner = Instance.new("UICorner", SpeedMinus)
SpeedMinusCorner.CornerRadius = UDim.new(0, 4)

local SpeedLabel = Instance.new("TextLabel", SpeedFrame)
SpeedLabel.Size = UDim2.new(0.44, 0, 1, 0)
SpeedLabel.Position = UDim2.new(0.28, 0, 0, 0)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "Spd: " .. tostring(PlayerState.FlySpeed)
SpeedLabel.TextColor3 = Color3.fromRGB(129, 140, 248)
SpeedLabel.Font = Enum.Font.GothamBold
SpeedLabel.TextSize = 10
SpeedLabel.ZIndex = 102

local SpeedPlus = Instance.new("TextButton", SpeedFrame)
SpeedPlus.Size = UDim2.new(0.28, 0, 1, 0)
SpeedPlus.Position = UDim2.new(0.72, 0, 0, 0)
SpeedPlus.BackgroundColor3 = Color3.fromRGB(27, 33, 45)
SpeedPlus.Text = "+"
SpeedPlus.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedPlus.Font = Enum.Font.GothamBold
SpeedPlus.TextSize = 14
SpeedPlus.BorderSizePixel = 0
SpeedPlus.ZIndex = 102

local SpeedPlusCorner = Instance.new("UICorner", SpeedPlus)
SpeedPlusCorner.CornerRadius = UDim.new(0, 4)

-- =================================================================
-- HELPER FUNCTIONS & EVENT LISTENERS
-- =================================================================

local function UpdateFlyUI()
    if PlayerState.IsFlying then
        FlyToggleBtn.Text = "FLY : ON"
        FlyToggleBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
        FlyStatusLabel.Text = "ON"
        FlyStatusLabel.TextColor3 = Color3.fromRGB(16, 185, 129)
        FlyMiniFrame.Visible = true
        StartFlyEngine()
    else
        FlyToggleBtn.Text = "FLY : OFF"
        FlyToggleBtn.BackgroundColor3 = Color3.fromRGB(225, 29, 72)
        FlyStatusLabel.Text = "OFF"
        FlyStatusLabel.TextColor3 = Color3.fromRGB(239, 68, 68)
        StopFlyEngine()
    end
end

ToggleBtn.MouseButton1Click:Connect(function()
    TeleportWindow.Visible = true
    ToggleBtn.Visible = false
end)

CloseMainBtn.MouseButton1Click:Connect(function()
    TeleportWindow.Visible = false
    ToggleBtn.Visible = true
end)

PlaceBlockBtn.MouseButton1Click:Connect(function()
    CreateSafeZoneAtCurrentPos()
    PlaceTitle.Text = "✔ Balok Gaib Diperbarui!"
    PlaceTitle.TextColor3 = Color3.fromRGB(16, 185, 129)
    task.wait(1.2)
    PlaceTitle.Text = "Reset/Atur Ulang Balok Gaib"
    PlaceTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
end)

FarmMasterBtn.MouseButton1Click:Connect(function()
    PlayerState.AutoFarmEgg = not PlayerState.AutoFarmEgg
    if PlayerState.AutoFarmEgg then
        FarmStatusLabel.Text = "ON"
        FarmStatusLabel.TextColor3 = Color3.fromRGB(16, 185, 129)
    else
        FarmStatusLabel.Text = "OFF"
        FarmStatusLabel.TextColor3 = Color3.fromRGB(239, 68, 68)
    end
end)

StealToggleBtn.MouseButton1Click:Connect(function()
    PlayerState.StealPriority = not PlayerState.StealPriority
    if PlayerState.StealPriority then
        StealStatusLabel.Text = "ON"
        StealStatusLabel.TextColor3 = Color3.fromRGB(16, 185, 129)
    else
        StealStatusLabel.Text = "OFF"
        StealStatusLabel.TextColor3 = Color3.fromRGB(239, 68, 68)
    end
end)

FlyMainToggleBtn.MouseButton1Click:Connect(function()
    PlayerState.IsFlying = not PlayerState.IsFlying
    UpdateFlyUI()
    if not PlayerState.IsFlying then
        FlyMiniFrame.Visible = false
    end
end)

FlyToggleBtn.MouseButton1Click:Connect(function()
    PlayerState.IsFlying = not PlayerState.IsFlying
    UpdateFlyUI()
    FlyMiniFrame.Visible = true
end)

SpeedPlus.MouseButton1Click:Connect(function()
    PlayerState.FlySpeed = PlayerState.FlySpeed + 10
    SpeedLabel.Text = "Spd: " .. tostring(PlayerState.FlySpeed)
end)

SpeedMinus.MouseButton1Click:Connect(function()
    if PlayerState.FlySpeed > 10 then
        PlayerState.FlySpeed = PlayerState.FlySpeed - 10
        SpeedLabel.Tet = "Spd: " .. tostring(PlayerState.FlySpeed)
    end
end)

RunService.RenderStepped:Connect(function()
    if PlayerState.IsFlying and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local cam = workspace.CurrentCamera

        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero

        if flyBodyVelocity and flyBodyGyro and hum and cam then
            flyBodyGyro.CFrame = cam.CFrame
            local moveDir = hum.MoveDirection
            if moveDir.Magnitude > 0 then
                local camFrame = cam.CFrame
                local localMove = camFrame:VectorToObjectSpace(moveDir)
                local finalVelocity = (camFrame.LookVector * -localMove.Z) + (camFrame.RightVector * localMove.X)
                flyBodyVelocity.Velocity = finalVelocity.Unit * PlayerState.FlySpeed
            else
                flyBodyVelocity.Velocity = Vector3.zero
            end
        end
    end
end)

RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end

    if PlayerState.IsFlying or PlayerState.Noclip then
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)
