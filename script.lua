--[[
    Script Name: faqih lua hub | Auto Steal & Fly Master Engine (Visual Character Lock Update + Auto Reset Revert)
    Credits: powered by faqih
    Feature Update: Fake Visual Character Lock + Free Camera 360° + Auto Hop Rarity & Safe Zone + Dynamic Character Swap
]]--

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    warn("[FAQIH HUB] LocalPlayer tidak ditemukan!")
    return
end

-- Target UI Container
local TargetGui
pcall(function() 
    TargetGui = CoreGui 
end)
if not TargetGui then 
    TargetGui = LocalPlayer:WaitForChild("PlayerGui", 5)
end
if not TargetGui then
    warn("[FAQIH HUB] TargetGui tidak dapat diakses!")
    return
end

-- Cleanup Old UI Instances
local oldUI = TargetGui:FindFirstChild("FaqihHubUI_v10") or TargetGui:FindFirstChild("FaluaLuaUI_v9")
if oldUI then oldUI:Destroy() end

-- System Variables & Constants
local SafeZoneBlock = nil
local IsFarming = false
local IsHopping = false
local CONFIG_FILE_NAME = "FaqihHub_AutoSteal_Config.json"

local FLY_SPEED_MIN = 10
local FLY_SPEED_MAX = 1000
local FLY_SPEED_DEFAULT = 100

-- Visual Lock / Fake Character Storage
local FakeCharacterModel = nil

-- Authoritative Areas
local VALID_AREAS = {
    "Meadow", "CoralReef", "Winter", "Desert", "CrystalMines",
    "Jungle", "MysticIsles", "Prehistoric", "CelestialHeights", "Savannah"
}

local AREA_DISPLAY_NAMES = {
    Meadow = "🍃 Meadow", CoralReef = "🪸 Coral Reef", Winter = "❄️ Winter",
    Desert = "🌵 Desert", CrystalMines = "💎 Crystal Mines", Jungle = "🌴 Jungle",
    MysticIsles = "🎯 Mystic Isles", Prehistoric = "🦖 Prehistoric",
    CelestialHeights = "☁️ Celestial Heights", Savannah = "🦁 Savannah"
}

local AREA_PATTERNS = {
    Meadow = {"meadow"}, CoralReef = {"coral", "reef"}, Winter = {"winter", "snow", "ice"},
    Desert = {"desert", "sand"}, CrystalMines = {"crystal", "mine"}, Jungle = {"jungle"},
    MysticIsles = {"mystic", "isle"}, Prehistoric = {"prehistoric", "dino"},
    CelestialHeights = {"celestial", "sky"}, Savannah = {"savannah"}
}

-- Rarity Lengkap untuk Filter Utama
local OrderedRarities = {
    "Ascended", "Eternal", "Celestial", "Divine", "Mythic",
    "Legendary", "Epic", "Rare", "Uncommon", "Common"
}

-- Hanya Rarity Mythic ke Atas untuk Auto Hop
local HopRaritiesList = {
    "Ascended", "Eternal", "Celestial", "Divine", "Mythic"
}

local RarityPriority = {
    Ascended = 10, Eternal = 9, Celestial = 8, Divine = 7,
    Mythic = 6, Legendary = 5, Epic = 4, Rare = 3, Uncommon = 2, Common = 1
}

local RarityColors = {
    Common = Color3.fromRGB(203, 213, 225), Uncommon = Color3.fromRGB(34, 197, 94),
    Rare = Color3.fromRGB(59, 130, 246), Epic = Color3.fromRGB(168, 85, 247),
    Legendary = Color3.fromRGB(251, 191, 36), Mythic = Color3.fromRGB(239, 68, 68),
    Divine = Color3.fromRGB(236, 72, 153), Celestial = Color3.fromRGB(6, 182, 212),
    Eternal = Color3.fromRGB(99, 102, 241), Ascended = Color3.fromRGB(244, 63, 94)
}

-- Configuration State Default
local PlayerState = {
    FlyUIVisible = false,
    IsFlying = false,     
    FlySpeed = FLY_SPEED_DEFAULT,
    AutoSteal = true,
    StealPriority = true,
    TargetMaxPlayers = 1,
    AutoHopAfterRarity = false,
    KeepAutoHopAfterServerHop = false,
    HopRarities = {
        Mythic = false, Divine = false, Celestial = false, Eternal = false, Ascended = false
    },
    SelectedAreas = {
        Meadow = true, CoralReef = true, Winter = true, Desert = true, CrystalMines = true,
        Jungle = true, MysticIsles = true, Prehistoric = true, CelestialHeights = true, Savannah = true
    },
    SelectedRarities = {
        Common = true, Uncommon = true, Rare = true, Epic = true, Legendary = true,
        Mythic = true, Divine = true, Celestial = true, Eternal = true, Ascended = true
    }
}

-- CONFIG SYSTEM
local function SaveConfig()
    if not writefile then return end
    local dataToSave = {
        FlyUIVisible = PlayerState.FlyUIVisible,
        FlySpeed = math.clamp(PlayerState.FlySpeed, FLY_SPEED_MIN, FLY_SPEED_MAX),
        AutoSteal = PlayerState.AutoSteal,
        StealPriority = PlayerState.StealPriority,
        TargetMaxPlayers = PlayerState.TargetMaxPlayers,
        AutoHopAfterRarity = PlayerState.AutoHopAfterRarity,
        KeepAutoHopAfterServerHop = PlayerState.KeepAutoHopAfterServerHop,
        HopRarities = PlayerState.HopRarities,
        SelectedAreas = PlayerState.SelectedAreas,
        SelectedRarities = PlayerState.SelectedRarities
    }
    pcall(function() writefile(CONFIG_FILE_NAME, HttpService:JSONEncode(dataToSave)) end)
end

local function LoadConfig()
    if not (readfile and isfile and isfile(CONFIG_FILE_NAME)) then return end
    local success, result = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE_NAME)) end)
    if success and type(result) == "table" then
        if result.FlyUIVisible ~= nil then PlayerState.FlyUIVisible = result.FlyUIVisible end
        if result.FlySpeed ~= nil then PlayerState.FlySpeed = math.clamp(result.FlySpeed, FLY_SPEED_MIN, FLY_SPEED_MAX) end
        if result.AutoSteal ~= nil then PlayerState.AutoSteal = result.AutoSteal end
        if result.StealPriority ~= nil then PlayerState.StealPriority = result.StealPriority end
        if result.TargetMaxPlayers ~= nil then PlayerState.TargetMaxPlayers = math.clamp(result.TargetMaxPlayers, 1, 6) end
        if result.AutoHopAfterRarity ~= nil then PlayerState.AutoHopAfterRarity = result.AutoHopAfterRarity end
        if result.KeepAutoHopAfterServerHop ~= nil then PlayerState.KeepAutoHopAfterServerHop = result.KeepAutoHopAfterServerHop end
        if type(result.HopRarities) == "table" then for k, v in pairs(result.HopRarities) do PlayerState.HopRarities[k] = v end end
        if type(result.SelectedAreas) == "table" then for k, v in pairs(result.SelectedAreas) do PlayerState.SelectedAreas[k] = v end end
        if type(result.SelectedRarities) == "table" then for k, v in pairs(result.SelectedRarities) do PlayerState.SelectedRarities[k] = v end end
    end
    PlayerState.IsFlying = false
end

LoadConfig()

local flyBodyVelocity, flyBodyGyro
local CustomToggleImageAsset = "rbxthumb://type=Asset&id=136902684546260&w=150&h=150"
local RAW_SCRIPT_URL = "https://raw.githubusercontent.com/n01771542-cmd/faqihlualua/refs/heads/main/script.lua"

-- SERVER HOP ENGINE
local HopStatusText = nil
local function PerformServerHop(overrideTargetPlayers)
    if IsHopping then return end
    IsHopping = true
    
    if not PlayerState.KeepAutoHopAfterServerHop then
        PlayerState.AutoHopAfterRarity = false
    end
    SaveConfig()
    
    local targetPlayers = overrideTargetPlayers or PlayerState.TargetMaxPlayers
    local placeId, currentJobId = game.PlaceId, game.JobId
    if not placeId or not currentJobId then 
        IsHopping = false
        return 
    end
    
    if HopStatusText then
        HopStatusText.Text = string.format("⏳ Searching (%d Player)...", targetPlayers)
        HopStatusText.TextColor3 = Color3.fromRGB(251, 191, 36)
    end
    
    local queueFunc = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
    if typeof(queueFunc) == "function" then
        pcall(function()
            queueFunc(string.format([[
                repeat task.wait(1) until game:IsLoaded()
                task.wait(2)
                loadstring(game:HttpGet("%s"))()
            ]], RAW_SCRIPT_URL))
        end)
    end

    local maxRetries = 3
    for attempt = 1, maxRetries do
        local success, response = pcall(function()
            return game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/0?sortOrder=Asc&limit=100")
        end)
        
        if success and response then
            local decodeSuccess, result = pcall(function() return HttpService:JSONDecode(response) end)
            if decodeSuccess and result and result.data then
                local validServers = {}
                for _, server in ipairs(result.data) do
                    if server.id and server.id ~= currentJobId and server.playing then
                        if server.playing <= targetPlayers and server.playing < server.maxPlayers then
                            table.insert(validServers, server.id)
                        end
                    end
                end
                
                if #validServers > 0 then
                    if HopStatusText then
                        HopStatusText.Text = "✅ Teleporting..."
                        HopStatusText.TextColor3 = Color3.fromRGB(34, 197, 94)
                    end
                    task.wait(0.5)
                    TeleportService:TeleportToPlaceInstance(placeId, validServers[math.random(1, #validServers)], LocalPlayer)
                    return
                end
            end
        end
        task.wait(1)
    end

    if HopStatusText then
        HopStatusText.Text = "❌ Server Tidak Ditemukan"
        HopStatusText.TextColor3 = Color3.fromRGB(239, 68, 68)
    end
    IsHopping = false
end

-- SAFE ZONE ENGINE
local function CreateSafeZoneAtCurrentPos()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 5)
    if hrp then
        if SafeZoneBlock and SafeZoneBlock.Parent then SafeZoneBlock:Destroy() end
        SafeZoneBlock = Instance.new("Part")
        SafeZoneBlock.Name = "SafeZoneBlock_FaqihHub"
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

local function DropHeldItems()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then pcall(function() hum:UnequipTools() end) end
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") then
            pcall(function() item.CanBeDropped = true item.Parent = workspace end)
        end
    end
end

local function TeleportToSafeZone()
    if not SafeZoneBlock or not SafeZoneBlock.Parent then CreateSafeZoneAtCurrentPos() end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hrp and hum and hum.Health > 0 and SafeZoneBlock then
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = SafeZoneBlock.CFrame + Vector3.new(0, 3.5, 0)
        end)
        DropHeldItems()
    end
end

-- =================================================================
-- VISUAL LOCK & FAKE CHARACTER ENGINE
-- =================================================================
local function SetCharacterVisibility(char, visible)
    if not char then return end
    for _, child in ipairs(char:GetDescendants()) do
        if child:IsA("BasePart") or child:IsA("Decal") then
            if child.Name ~= "HumanoidRootPart" then
                child.Transparency = visible and 0 or 1
            end
        end
    end
end

local function EnableVisualLock()
    local char = LocalPlayer.Character
    if not char or FakeCharacterModel then return end
    
    char.Archivable = true
    FakeCharacterModel = char:Clone()
    FakeCharacterModel.Name = "VisualLock_FakeChar"
    
    for _, child in ipairs(FakeCharacterModel:GetDescendants()) do
        if child:IsA("Script") or child:IsA("LocalScript") then
            child:Destroy()
        elseif child:IsA("BasePart") then
            child.Anchored = true
            child.CanCollide = false
        end
    end
    
    if SafeZoneBlock then
        FakeCharacterModel:SetPrimaryPartCFrame(SafeZoneBlock.CFrame + Vector3.new(0, 3.5, 0))
    else
        FakeCharacterModel:SetPrimaryPartCFrame(char:GetPrimaryPartCFrame())
    end
    
    FakeCharacterModel.Parent = workspace
    SetCharacterVisibility(char, false)
    
    local cam = workspace.CurrentCamera
    local fakeHum = FakeCharacterModel:FindFirstChildOfClass("Humanoid")
    if cam and fakeHum then
        cam.CameraType = Enum.CameraType.Custom
        cam.CameraSubject = fakeHum
    end
end

local function DisableVisualLock()
    local char = LocalPlayer.Character
    if FakeCharacterModel then
        FakeCharacterModel:Destroy()
        FakeCharacterModel = nil
    end
    
    if char then
        SetCharacterVisibility(char, true)
        local cam = workspace.CurrentCamera
        local hum = char:FindFirstChildOfClass("Humanoid")
        if cam and hum then
            cam.CameraType = Enum.CameraType.Custom
            cam.CameraSubject = hum
        end
    end
end

-- AREA DETECTION ENGINE
local function DetectEggZone(eggModel)
    if not eggModel then return nil end
    local function MatchPattern(str)
        if not str then return nil end
        local lowerStr = string.lower(str)
        for areaKey, patterns in pairs(AREA_PATTERNS) do
            for _, pattern in ipairs(patterns) do
                if string.find(lowerStr, pattern) then return areaKey end
            end
        end
        return nil
    end

    local zoneAttr = eggModel:GetAttribute("Zone") or eggModel:GetAttribute("Area") or eggModel:GetAttribute("Location")
    local matched = MatchPattern(zoneAttr)
    if matched then return matched end
    
    local parent = eggModel.Parent
    while parent and parent ~= workspace do
        matched = MatchPattern(parent.Name)
        if matched then return matched end
        parent = parent.Parent
    end
    return MatchPattern(eggModel.Name)
end

-- AUTO STEAL ENGINE TARGET FINDER
local function GetValidEggTargets()
    local validTargets = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if not obj:IsA("ProximityPrompt") or not obj.Enabled then continue end
        local eggModel = obj.Parent
        while eggModel and eggModel ~= workspace and not eggModel:IsA("Model") do eggModel = eggModel.Parent end
        if not eggModel or not eggModel.Parent then continue end
        
        local zone = DetectEggZone(eggModel)
        if not zone or PlayerState.SelectedAreas[zone] ~= true then continue end
        
        local rarity = eggModel:GetAttribute("Rarity") or "Common"
        local modelName = string.lower(eggModel.Name)
        for rName, _ in pairs(PlayerState.SelectedRarities) do
            if string.find(modelName, string.lower(rName)) then rarity = rName end
        end
        
        if PlayerState.SelectedRarities[rarity] ~= true then continue end
        
        local part = obj.Parent:IsA("BasePart") and obj.Parent or eggModel:FindFirstChildWhichIsA("BasePart")
        if part and part.Parent then
            table.insert(validTargets, {
                Prompt = obj, Model = eggModel, Rarity = rarity, Zone = zone,
                Priority = RarityPriority[rarity] or 1, Part = part
            })
        end
    end
    
    if PlayerState.StealPriority then
        table.sort(validTargets, function(a, b) return a.Priority > b.Priority end)
    end
    return validTargets
end

-- =================================================================
-- AUTO STEAL ENGINE (DYNAMIC VISUAL LOCK & INTERNAL TELEPORT)
-- =================================================================
local isInitialTeleportDone = false

local function ProcessAutoSteal()
    if IsFarming or IsHopping or not PlayerState.AutoSteal then return end

    local targets = GetValidEggTargets()
    
    -- Jika TIDAK ADA EGG sama sekali, balikkan ke karakter utama
    if #targets == 0 then
        if isInitialTeleportDone then
            isInitialTeleportDone = false
            DisableVisualLock()
        end
        return
    end

    -- Jika ADA EGG yang sesuai, aktifkan Fake Character Lock di Safe Zone
    if not isInitialTeleportDone then
        TeleportToSafeZone()
        task.wait(0.3)
        EnableVisualLock()
        isInitialTeleportDone = true
    end

    local target = targets[1]
    if not target or not target.Part or not target.Prompt or not target.Prompt.Enabled then return end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if not hrp or not hum or hum.Health <= 0 then return end

    IsFarming = true

    local stolenSuccessfully = false
    local stolenRarity = target.Rarity

    pcall(function()
        DropHeldItems()

        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        hrp.CFrame = target.Part.CFrame + Vector3.new(0, 0.5, 0)

        local arrived = false
        local timeout = 0
        repeat
            task.wait(0.05)
            timeout = timeout + 0.05
            if not PlayerState.AutoSteal then break end
            if char and char:FindFirstChild("HumanoidRootPart") then
                local currentDist = (char.HumanoidRootPart.Position - target.Part.Position).Magnitude
                if currentDist <= 12 then
                    arrived = true
                    break
                else
                    char.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
                    char.HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero
                    char.HumanoidRootPart.CFrame = target.Part.CFrame + Vector3.new(0, 0.5, 0)
                end
            end
        until timeout >= 1.5

        if arrived and PlayerState.AutoSteal then
            task.wait(1.0)

            if PlayerState.AutoSteal and target.Prompt and target.Prompt.Parent and target.Prompt.Enabled then
                local prompt = target.Prompt
                prompt.HoldDuration = 0
                prompt.RequiresLineOfSight = false

                if fireproximityprompt then
                    fireproximityprompt(prompt)
                else
                    prompt:InputHoldBegin()
                    prompt:InputHoldEnd()
                end

                task.wait(0.15)
                stolenSuccessfully = true
            end
        end

        TeleportToSafeZone()
    end)

    if stolenSuccessfully and PlayerState.AutoSteal and PlayerState.AutoHopAfterRarity then
        local hasSelectedHopRarity = false
        for _, selected in pairs(PlayerState.HopRarities) do
            if selected == true then
                hasSelectedHopRarity = true
                break
            end
        end

        if hasSelectedHopRarity and PlayerState.HopRarities[stolenRarity] == true then
            DisableVisualLock()
            task.wait(0.5)
            IsFarming = false
            PerformServerHop(1)
            return
        end
    end

    task.wait(0.05)
    IsFarming = false
end

-- MAIN AUTO STEAL LOOP & SWITCH MONITOR
task.spawn(function()
    while task.wait(0.05) do
        if PlayerState.AutoSteal then
            if not IsFarming and not IsHopping then
                pcall(ProcessAutoSteal)
            end
        else
            if isInitialTeleportDone then
                isInitialTeleportDone = false
                DisableVisualLock()
            end
        end
    end
end)

-- FLY ENGINE
local function StartFlyEngine()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    pcall(function()
        hum.PlatformStand = true
        if not flyBodyVelocity or not flyBodyVelocity.Parent then
            flyBodyVelocity = Instance.new("BodyVelocity")
            flyBodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            flyBodyVelocity.Velocity = Vector3.zero
            flyBodyVelocity.Parent = hrp
        end

        if not flyBodyGyro or not flyBodyGyro.Parent then
            flyBodyGyro = Instance.new("BodyGyro")
            flyBodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
            flyBodyGyro.P = 9e4
            flyBodyGyro.CFrame = hrp.CFrame
            flyBodyGyro.Parent = hrp
        end
    end)
end

local function StopFlyEngine()
    pcall(function()
        if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
        if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end)
end

-- =================================================================
-- ROBLOX GUI ENGINE
-- =================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FaqihHubUI_v10"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = TargetGui

-- Mini Icon Toggle Button
local ToggleBtn = Instance.new("ImageButton", ScreenGui)
ToggleBtn.Name = "ToggleImageBtn"
ToggleBtn.Size = UDim2.new(0, 42, 0, 42)
ToggleBtn.Position = UDim2.new(0.02, 0, 0.15, 0)
ToggleBtn.BackgroundTransparency = 1
ToggleBtn.Image = CustomToggleImageAsset
ToggleBtn.Active = true
ToggleBtn.Draggable = true
ToggleBtn.Visible = false

local ToggleCorner = Instance.new("UICorner", ToggleBtn)
ToggleCorner.CornerRadius = UDim.new(0, 8)

-- Main Container Window
local MainWindow = Instance.new("Frame", ScreenGui)
MainWindow.Name = "MainWindow"
MainWindow.Size = UDim2.new(0, 520, 0, 410)
MainWindow.Position = UDim2.new(0.5, -260, 0.5, -205)
MainWindow.BackgroundColor3 = Color3.fromRGB(11, 18, 30)
MainWindow.BorderSizePixel = 0
MainWindow.Active = true
MainWindow.Draggable = true

local WindowCorner = Instance.new("UICorner", MainWindow)
WindowCorner.CornerRadius = UDim.new(0, 16)

local WindowStroke = Instance.new("UIStroke", MainWindow)
WindowStroke.Color = Color3.fromRGB(30, 41, 59)
WindowStroke.Thickness = 1

-- Header
local Header = Instance.new("Frame", MainWindow)
Header.Size = UDim2.new(1, -32, 0, 40)
Header.Position = UDim2.new(0, 16, 0, 12)
Header.BackgroundTransparency = 1

local IconBox = Instance.new("Frame", Header)
IconBox.Size = UDim2.new(0, 28, 0, 28)
IconBox.Position = UDim2.new(0, 0, 0.5, -14)
IconBox.BackgroundColor3 = Color3.fromRGB(37, 99, 235)

local IconCorner = Instance.new("UICorner", IconBox)
IconCorner.CornerRadius = UDim.new(0, 8)

local IconLabel = Instance.new("TextLabel", IconBox)
IconLabel.Size = UDim2.new(1, 0, 1, 0)
IconLabel.BackgroundTransparency = 1
IconLabel.Text = "🧊"
IconLabel.TextSize = 14

local TitleLabel = Instance.new("TextLabel", Header)
TitleLabel.Size = UDim2.new(1, -80, 1, 0)
TitleLabel.Position = UDim2.new(0, 36, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "FAQIH HUB <font color=\"#3B82F6\">— AUTO STEAL MASTER</font>"
TitleLabel.RichText = true
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 13
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -26, 0.5, -13)
CloseBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
CloseBtn.Text = "—"
CloseBtn.TextColor3 = Color3.fromRGB(148, 163, 184)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12

local CloseCorner = Instance.new("UICorner", CloseBtn)
CloseCorner.CornerRadius = UDim.new(0, 6)

-- Main 2-Column Container
local ContentGrid = Instance.new("Frame", MainWindow)
ContentGrid.Size = UDim2.new(1, -32, 1, -68)
ContentGrid.Position = UDim2.new(0, 16, 0, 56)
ContentGrid.BackgroundTransparency = 1

local LeftCol = Instance.new("ScrollingFrame", ContentGrid)
LeftCol.Size = UDim2.new(0.485, 0, 1, 0)
LeftCol.BackgroundTransparency = 1
LeftCol.BorderSizePixel = 0
LeftCol.ScrollBarThickness = 2
LeftCol.ScrollBarImageColor3 = Color3.fromRGB(51, 65, 85)

local LeftLayout = Instance.new("UIListLayout", LeftCol)
LeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
LeftLayout.Padding = UDim.new(0, 10)

local RightCol = Instance.new("ScrollingFrame", ContentGrid)
RightCol.Size = UDim2.new(0.485, 0, 1, 0)
RightCol.Position = UDim2.new(0.515, 0, 0, 0)
RightCol.BackgroundTransparency = 1
RightCol.BorderSizePixel = 0
RightCol.ScrollBarThickness = 2
RightCol.ScrollBarImageColor3 = Color3.fromRGB(51, 65, 85)

local RightLayout = Instance.new("UIListLayout", RightCol)
RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
RightLayout.Padding = UDim.new(0, 10)

-- Helpers
local function CreateCardBox(parent, height)
    local box = Instance.new("Frame", parent)
    box.Size = UDim2.new(1, -6, 0, height or 80)
    box.BackgroundColor3 = Color3.fromRGB(17, 25, 39)
    
    local corner = Instance.new("UICorner", box)
    corner.CornerRadius = UDim.new(0, 12)
    
    local stroke = Instance.new("UIStroke", box)
    stroke.Color = Color3.fromRGB(30, 41, 59)
    stroke.Thickness = 1
    return box
end

local function CreateSwitchToggle(parent, initialState, callback)
    local switchBg = Instance.new("TextButton", parent)
    switchBg.Size = UDim2.new(0, 40, 0, 20)
    switchBg.BackgroundColor3 = initialState and Color3.fromRGB(37, 99, 235) or Color3.fromRGB(51, 65, 85)
    switchBg.Text = ""
    
    local swCorner = Instance.new("UICorner", switchBg)
    swCorner.CornerRadius = UDim.new(1, 0)
    
    local knob = Instance.new("Frame", switchBg)
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = initialState and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    
    local knobCorner = Instance.new("UICorner", knob)
    knobCorner.CornerRadius = UDim.new(1, 0)
    
    local state = initialState
    
    local function SetState(newState)
        state = newState
        switchBg.BackgroundColor3 = state and Color3.fromRGB(37, 99, 235) or Color3.fromRGB(51, 65, 85)
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        }):Play()
    end

    switchBg.MouseButton1Click:Connect(function()
        SetState(not state)
        if callback then callback(state) end
    end)
    return switchBg, SetState
end

-- =================================================================
-- INDEPENDENT FLY MINI CONTROLLER WINDOW
-- =================================================================
local FlyMiniUI = Instance.new("Frame", ScreenGui)
FlyMiniUI.Name = "FlyMiniController"
FlyMiniUI.Size = UDim2.new(0, 210, 0, 65)
FlyMiniUI.Position = UDim2.new(0.05, 0, 0.25, 0)
FlyMiniUI.BackgroundColor3 = Color3.fromRGB(17, 25, 39)
FlyMiniUI.Active = true
FlyMiniUI.Draggable = true
FlyMiniUI.Visible = PlayerState.FlyUIVisible

local MiniCorner = Instance.new("UICorner", FlyMiniUI)
MiniCorner.CornerRadius = UDim.new(0, 10)

local MiniStroke = Instance.new("UIStroke", FlyMiniUI)
MiniStroke.Color = Color3.fromRGB(37, 99, 235)
MiniStroke.Thickness = 1.5

local MiniTitle = Instance.new("TextLabel", FlyMiniUI)
MiniTitle.Size = UDim2.new(1, -12, 0, 16)
MiniTitle.Position = UDim2.new(0, 8, 0, 4)
MiniTitle.BackgroundTransparency = 1
MiniTitle.Text = "🕊️ Fly Mini Controller"
MiniTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
MiniTitle.Font = Enum.Font.GothamBold
MiniTitle.TextSize = 9.5
MiniTitle.TextXAlignment = Enum.TextXAlignment.Left

local MiniActiveBtn = Instance.new("TextButton", FlyMiniUI)
MiniActiveBtn.Size = UDim2.new(0, 95, 0, 26)
MiniActiveBtn.Position = UDim2.new(0, 8, 0, 26)
MiniActiveBtn.BackgroundColor3 = PlayerState.IsFlying and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(225, 29, 72)
MiniActiveBtn.Text = PlayerState.IsFlying and "FLYING : ON" or "FLYING : OFF"
MiniActiveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MiniActiveBtn.Font = Enum.Font.GothamBold
MiniActiveBtn.TextSize = 8.5

local MiniActiveCorner = Instance.new("UICorner", MiniActiveBtn)
MiniActiveCorner.CornerRadius = UDim.new(0, 6)

local MiniSpeedBox = Instance.new("TextBox", FlyMiniUI)
MiniSpeedBox.Size = UDim2.new(0, 85, 0, 26)
MiniSpeedBox.Position = UDim2.new(0, 110, 0, 26)
MiniSpeedBox.BackgroundColor3 = Color3.fromRGB(11, 18, 30)
MiniSpeedBox.Text = tostring(PlayerState.FlySpeed)
MiniSpeedBox.TextColor3 = Color3.fromRGB(59, 130, 246)
MiniSpeedBox.Font = Enum.Font.GothamBold
MiniSpeedBox.TextSize = 9.5

local MiniSpeedCorner = Instance.new("UICorner", MiniSpeedBox)
MiniSpeedCorner.CornerRadius = UDim.new(0, 6)

local MiniSpeedStroke = Instance.new("UIStroke", MiniSpeedBox)
MiniSpeedStroke.Color = Color3.fromRGB(30, 41, 59)

local function SyncFlyStateUI()
    MiniActiveBtn.BackgroundColor3 = PlayerState.IsFlying and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(225, 29, 72)
    MiniActiveBtn.Text = PlayerState.IsFlying and "FLYING : ON" or "FLYING : OFF"
    MiniSpeedBox.Text = tostring(PlayerState.FlySpeed)
end

MiniActiveBtn.MouseButton1Click:Connect(function()
    PlayerState.IsFlying = not PlayerState.IsFlying
    SyncFlyStateUI()
    if PlayerState.IsFlying then StartFlyEngine() else StopFlyEngine() end
end)

MiniSpeedBox.FocusLost:Connect(function()
    local val = tonumber(MiniSpeedBox.Text)
    if val then
        PlayerState.FlySpeed = math.clamp(val, FLY_SPEED_MIN, FLY_SPEED_MAX)
        SaveConfig()
    end
    SyncFlyStateUI()
end)

-- =================================================================
-- LEFT COLUMN CONTENT
-- =================================================================

-- 1. Fly Switch Box (Main Window)
local FlyBox = CreateCardBox(LeftCol, 60)

local FlyHeader = Instance.new("Frame", FlyBox)
FlyHeader.Size = UDim2.new(1, -20, 0, 36)
FlyHeader.Position = UDim2.new(0, 10, 0.5, -18)
FlyHeader.BackgroundTransparency = 1

local FlyBadge = Instance.new("TextLabel", FlyHeader)
FlyBadge.Size = UDim2.new(0, 30, 0, 30)
FlyBadge.BackgroundColor3 = Color3.fromRGB(30, 58, 138)
FlyBadge.Text = "🕊️"
FlyBadge.TextSize = 14

local FlyBadgeCorner = Instance.new("UICorner", FlyBadge)
FlyBadgeCorner.CornerRadius = UDim.new(1, 0)

local FlyTitle = Instance.new("TextLabel", FlyHeader)
FlyTitle.Size = UDim2.new(1, -85, 0, 16)
FlyTitle.Position = UDim2.new(0, 36, 0, 0)
FlyTitle.BackgroundTransparency = 1
FlyTitle.Text = "Fly Controller"
FlyTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
FlyTitle.Font = Enum.Font.GothamBold
FlyTitle.TextSize = 11
FlyTitle.TextXAlignment = Enum.TextXAlignment.Left

local FlySub = Instance.new("TextLabel", FlyHeader)
FlySub.Size = UDim2.new(1, -85, 0, 12)
FlySub.Position = UDim2.new(0, 36, 0, 16)
FlySub.BackgroundTransparency = 1
FlySub.Text = "Tampilkan Fly Controller melayang"
FlySub.TextColor3 = Color3.fromRGB(148, 163, 184)
FlySub.Font = Enum.Font.Gotham
FlySub.TextSize = 8
FlySub.TextXAlignment = Enum.TextXAlignment.Left

local FlySwitchHolder = Instance.new("Frame", FlyHeader)
FlySwitchHolder.Size = UDim2.new(0, 40, 0, 20)
FlySwitchHolder.Position = UDim2.new(1, -40, 0.5, -10)
FlySwitchHolder.BackgroundTransparency = 1

CreateSwitchToggle(FlySwitchHolder, PlayerState.FlyUIVisible, function(val)
    PlayerState.FlyUIVisible = val
    FlyMiniUI.Visible = val
    if not val then
        PlayerState.IsFlying = false
        StopFlyEngine()
        SyncFlyStateUI()
    end
    SaveConfig()
end)

-- 2. Safe Zone Box
local SafeBox = CreateCardBox(LeftCol, 60)

local SafeIcon = Instance.new("TextLabel", SafeBox)
SafeIcon.Size = UDim2.new(0, 30, 0, 30)
SafeIcon.Position = UDim2.new(0, 10, 0.5, -15)
SafeIcon.BackgroundColor3 = Color3.fromRGB(88, 28, 135)
SafeIcon.Text = "🔄"
SafeIcon.TextSize = 13

local SafeIconCorner = Instance.new("UICorner", SafeIcon)
SafeIconCorner.CornerRadius = UDim.new(1, 0)

local SafeTitle = Instance.new("TextLabel", SafeBox)
SafeTitle.Size = UDim2.new(1, -130, 0, 16)
SafeTitle.Position = UDim2.new(0, 48, 0, 13)
SafeTitle.BackgroundTransparency = 1
SafeTitle.Text = "Menaruh Ulang Balok"
SafeTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
SafeTitle.Font = Enum.Font.GothamBold
SafeTitle.TextSize = 10
SafeTitle.TextXAlignment = Enum.TextXAlignment.Left

local SafeSub = Instance.new("TextLabel", SafeBox)
SafeSub.Size = UDim2.new(1, -130, 0, 12)
SafeSub.Position = UDim2.new(0, 48, 0, 29)
SafeSub.BackgroundTransparency = 1
SafeSub.Text = "Letakkan balok ke posisi"
SafeSub.TextColor3 = Color3.fromRGB(148, 163, 184)
SafeSub.Font = Enum.Font.Gotham
SafeSub.TextSize = 8
SafeSub.TextXAlignment = Enum.TextXAlignment.Left

local ResetBalokBtn = Instance.new("TextButton", SafeBox)
ResetBalokBtn.Size = UDim2.new(0, 65, 0, 26)
ResetBalokBtn.Position = UDim2.new(1, -73, 0.5, -13)
ResetBalokBtn.BackgroundColor3 = Color3.fromRGB(79, 70, 229)
ResetBalokBtn.Text = "Reset"
ResetBalokBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ResetBalokBtn.Font = Enum.Font.GothamBold
ResetBalokBtn.TextSize = 9

local ResetCorner = Instance.new("UICorner", ResetBalokBtn)
ResetCorner.CornerRadius = UDim.new(0, 6)

ResetBalokBtn.MouseButton1Click:Connect(function()
    CreateSafeZoneAtCurrentPos()
    if FakeCharacterModel and SafeZoneBlock then
        FakeCharacterModel:SetPrimaryPartCFrame(SafeZoneBlock.CFrame + Vector3.new(0, 3.5, 0))
    end
    ResetBalokBtn.Text = "✔ Done!"
    ResetBalokBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
    task.wait(1.2)
    ResetBalokBtn.Text = "Reset"
    ResetBalokBtn.BackgroundColor3 = Color3.fromRGB(79, 70, 229)
end)

-- 3. Server Hop Box
local HopBox = CreateCardBox(LeftCol, 115)

local HopHeader = Instance.new("Frame", HopBox)
HopHeader.Size = UDim2.new(1, -20, 0, 36)
HopHeader.Position = UDim2.new(0, 10, 0, 8)
HopHeader.BackgroundTransparency = 1

local HopIcon = Instance.new("TextLabel", HopHeader)
HopIcon.Size = UDim2.new(0, 30, 0, 30)
HopIcon.BackgroundColor3 = Color3.fromRGB(6, 78, 59)
HopIcon.Text = "🌐"
HopIcon.TextSize = 13

local HopIconCorner = Instance.new("UICorner", HopIcon)
HopIconCorner.CornerRadius = UDim.new(1, 0)

local HopTitle = Instance.new("TextLabel", HopHeader)
HopTitle.Size = UDim2.new(1, -40, 0, 16)
HopTitle.Position = UDim2.new(0, 38, 0, 0)
HopTitle.BackgroundTransparency = 1
HopTitle.Text = "Server Hop"
HopTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
HopTitle.Font = Enum.Font.GothamBold
HopTitle.TextSize = 11
HopTitle.TextXAlignment = Enum.TextXAlignment.Left

local HopSub = Instance.new("TextLabel", HopHeader)
HopSub.Size = UDim2.new(1, -40, 0, 12)
HopSub.Position = UDim2.new(0, 38, 0, 16)
HopSub.BackgroundTransparency = 1
HopSub.Text = "Cari server lain dengan pemain baru"
HopSub.TextColor3 = Color3.fromRGB(148, 163, 184)
HopSub.Font = Enum.Font.Gotham
HopSub.TextSize = 8
HopSub.TextXAlignment = Enum.TextXAlignment.Left

local HopSelector = Instance.new("Frame", HopBox)
HopSelector.Size = UDim2.new(1, -20, 0, 26)
HopSelector.Position = UDim2.new(0, 10, 0, 46)
HopSelector.BackgroundColor3 = Color3.fromRGB(11, 18, 30)

local HopSelectorCorner = Instance.new("UICorner", HopSelector)
HopSelectorCorner.CornerRadius = UDim.new(0, 6)

local BtnPrev = Instance.new("TextButton", HopSelector)
BtnPrev.Size = UDim2.new(0, 24, 1, 0)
BtnPrev.BackgroundTransparency = 1
BtnPrev.Text = "◄"
BtnPrev.TextColor3 = Color3.fromRGB(148, 163, 184)
BtnPrev.Font = Enum.Font.GothamBold
BtnPrev.TextSize = 9

local BtnNext = Instance.new("TextButton", HopSelector)
BtnNext.Size = UDim2.new(0, 24, 1, 0)
BtnNext.Position = UDim2.new(1, -24, 0, 0)
BtnNext.BackgroundTransparency = 1
BtnNext.Text = "►"
BtnNext.TextColor3 = Color3.fromRGB(148, 163, 184)
BtnNext.Font = Enum.Font.GothamBold
BtnNext.TextSize = 9

local PlayerCountText = Instance.new("TextLabel", HopSelector)
PlayerCountText.Size = UDim2.new(1, -48, 1, 0)
PlayerCountText.Position = UDim2.new(0, 24, 0, 0)
PlayerCountText.BackgroundTransparency = 1
PlayerCountText.Text = string.format("%d Player", PlayerState.TargetMaxPlayers)
PlayerCountText.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayerCountText.Font = Enum.Font.GothamMedium
PlayerCountText.TextSize = 9

BtnPrev.MouseButton1Click:Connect(function()
    if PlayerState.TargetMaxPlayers > 1 then
        PlayerState.TargetMaxPlayers = PlayerState.TargetMaxPlayers - 1
        PlayerCountText.Text = string.format("%d Player", PlayerState.TargetMaxPlayers)
        SaveConfig()
    end
end)

BtnNext.MouseButton1Click:Connect(function()
    if PlayerState.TargetMaxPlayers < 6 then
        PlayerState.TargetMaxPlayers = PlayerState.TargetMaxPlayers + 1
        PlayerCountText.Text = string.format("%d Player", PlayerState.TargetMaxPlayers)
        SaveConfig()
    end
end)

local ExecuteHopBtn = Instance.new("TextButton", HopBox)
ExecuteHopBtn.Size = UDim2.new(1, -20, 0, 24)
ExecuteHopBtn.Position = UDim2.new(0, 10, 0, 78)
ExecuteHopBtn.BackgroundColor3 = Color3.fromRGB(37, 99, 235)
ExecuteHopBtn.Text = "Cari Server"
ExecuteHopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ExecuteHopBtn.Font = Enum.Font.GothamBold
ExecuteHopBtn.TextSize = 9

local ExecuteCorner = Instance.new("UICorner", ExecuteHopBtn)
ExecuteCorner.CornerRadius = UDim.new(0, 6)

HopStatusText = Instance.new("TextLabel", HopBox)
HopStatusText.Size = UDim2.new(1, 0, 0, 10)
HopStatusText.Position = UDim2.new(0, 0, 1, -12)
HopStatusText.BackgroundTransparency = 1
HopStatusText.Text = "Pilih jumlah pemain (1 - 6)"
HopStatusText.TextColor3 = Color3.fromRGB(100, 116, 139)
HopStatusText.Font = Enum.Font.Gotham
HopStatusText.TextSize = 7.5

ExecuteHopBtn.MouseButton1Click:Connect(function()
    PerformServerHop()
end)

-- 4. Auto Hop Server After Rarity Box (HANYA MYTHIC KE ATAS)
local HopRarityBox = CreateCardBox(LeftCol, 185)

local HopRarityHeader = Instance.new("Frame", HopRarityBox)
HopRarityHeader.Size = UDim2.new(1, -20, 0, 36)
HopRarityHeader.Position = UDim2.new(0, 10, 0, 8)
HopRarityHeader.BackgroundTransparency = 1

local HopRarityIcon = Instance.new("TextLabel", HopRarityHeader)
HopRarityIcon.Size = UDim2.new(0, 30, 0, 30)
HopRarityIcon.BackgroundColor3 = Color3.fromRGB(217, 119, 6)
HopRarityIcon.Text = "⚡"
HopRarityIcon.TextSize = 13

local HopRarityIconCorner = Instance.new("UICorner", HopRarityIcon)
HopRarityIconCorner.CornerRadius = UDim.new(1, 0)

local HopRarityTitle = Instance.new("TextLabel", HopRarityHeader)
HopRarityTitle.Size = UDim2.new(1, -90, 0, 16)
HopRarityTitle.Position = UDim2.new(0, 38, 0, 0)
HopRarityTitle.BackgroundTransparency = 1
HopRarityTitle.Text = "Auto Hop Server"
HopRarityTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
HopRarityTitle.Font = Enum.Font.GothamBold
HopRarityTitle.TextSize = 10
HopRarityTitle.TextXAlignment = Enum.TextXAlignment.Left

local HopRaritySub = Instance.new("TextLabel", HopRarityHeader)
HopRaritySub.Size = UDim2.new(1, -90, 0, 12)
HopRaritySub.Position = UDim2.new(0, 38, 0, 16)
HopRaritySub.BackgroundTransparency = 1
HopRaritySub.Text = "Hop saat dapat Rarity tertentu"
HopRaritySub.TextColor3 = Color3.fromRGB(148, 163, 184)
HopRaritySub.Font = Enum.Font.Gotham
HopRaritySub.TextSize = 8
HopRaritySub.TextXAlignment = Enum.TextXAlignment.Left

local HopRaritySwitchHolder = Instance.new("Frame", HopRarityHeader)
HopRaritySwitchHolder.Size = UDim2.new(0, 40, 0, 20)
HopRaritySwitchHolder.Position = UDim2.new(1, -40, 0.5, -10)
HopRaritySwitchHolder.BackgroundTransparency = 1

CreateSwitchToggle(HopRaritySwitchHolder, PlayerState.AutoHopAfterRarity, function(val)
    PlayerState.AutoHopAfterRarity = val
    SaveConfig()
end)

local HopRarityCollapseBtn = Instance.new("TextButton", HopRarityHeader)
HopRarityCollapseBtn.Size = UDim2.new(0, 24, 0, 24)
HopRarityCollapseBtn.Position = UDim2.new(1, -70, 0.5, -12)
HopRarityCollapseBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
HopRarityCollapseBtn.Text = "v"
HopRarityCollapseBtn.TextColor3 = Color3.fromRGB(148, 163, 184)
HopRarityCollapseBtn.Font = Enum.Font.GothamBold
HopRarityCollapseBtn.TextSize = 10

local HopRarityBtnCorner = Instance.new("UICorner", HopRarityCollapseBtn)
HopRarityBtnCorner.CornerRadius = UDim.new(0, 6)

-- Keep Auto Hop Option
local KeepHopFrame = Instance.new("Frame", HopRarityBox)
KeepHopFrame.Size = UDim2.new(1, -20, 0, 32)
KeepHopFrame.Position = UDim2.new(0, 10, 0, 46)
KeepHopFrame.BackgroundColor3 = Color3.fromRGB(11, 18, 30)

local KeepHopCorner = Instance.new("UICorner", KeepHopFrame)
KeepHopCorner.CornerRadius = UDim.new(0, 6)

local KeepHopLabel = Instance.new("TextLabel", KeepHopFrame)
KeepHopLabel.Size = UDim2.new(1, -50, 1, 0)
KeepHopLabel.Position = UDim2.new(0, 8, 0, 0)
KeepHopLabel.BackgroundTransparency = 1
KeepHopLabel.Text = "Keep Auto Hop After Server Hop"
KeepHopLabel.TextColor3 = Color3.fromRGB(226, 232, 240)
KeepHopLabel.Font = Enum.Font.GothamMedium
KeepHopLabel.TextSize = 8
KeepHopLabel.TextXAlignment = Enum.TextXAlignment.Left

local KeepHopSwitchHolder = Instance.new("Frame", KeepHopFrame)
KeepHopSwitchHolder.Size = UDim2.new(0, 40, 0, 20)
KeepHopSwitchHolder.Position = UDim2.new(1, -44, 0.5, -10)
KeepHopSwitchHolder.BackgroundTransparency = 1

CreateSwitchToggle(KeepHopSwitchHolder, PlayerState.KeepAutoHopAfterServerHop, function(val)
    PlayerState.KeepAutoHopAfterServerHop = val
    SaveConfig()
end)

local HopRarityScroll = Instance.new("ScrollingFrame", HopRarityBox)
HopRarityScroll.Size = UDim2.new(1, -20, 0, 90)
HopRarityScroll.Position = UDim2.new(0, 10, 0, 84)
HopRarityScroll.BackgroundTransparency = 1
HopRarityScroll.BorderSizePixel = 0
HopRarityScroll.ScrollBarThickness = 2

local HopRarityGrid = Instance.new("UIGridLayout", HopRarityScroll)
HopRarityGrid.CellSize = UDim2.new(0.48, 0, 0, 24)
HopRarityGrid.CellPadding = UDim2.new(0.04, 0, 0, 4)

local isHopRarityExpanded = true
HopRarityCollapseBtn.MouseButton1Click:Connect(function()
    isHopRarityExpanded = not isHopRarityExpanded
    HopRarityScroll.Visible = isHopRarityExpanded
    KeepHopFrame.Visible = isHopRarityExpanded
    HopRarityCollapseBtn.Text = isHopRarityExpanded and "v" or "^"
    TweenService:Create(HopRarityBox, TweenInfo.new(0.2), {
        Size = isHopRarityExpanded and UDim2.new(1, -6, 0, 185) or UDim2.new(1, -6, 0, 52)
    }):Play()
end)

for _, rName in ipairs(HopRaritiesList) do
    local isChecked = PlayerState.HopRarities[rName] == true
    
    local itemFrame = Instance.new("TextButton", HopRarityScroll)
    itemFrame.BackgroundColor3 = Color3.fromRGB(11, 18, 30)
    itemFrame.Text = ""
    
    local itemCorner = Instance.new("UICorner", itemFrame)
    itemCorner.CornerRadius = UDim.new(0, 6)
    
    local dot = Instance.new("Frame", itemFrame)
    dot.Size = UDim2.new(0, 6, 0, 6)
    dot.Position = UDim2.new(0, 8, 0.5, -3)
    dot.BackgroundColor3 = RarityColors[rName] or Color3.fromRGB(255, 255, 255)
    
    local dotCorner = Instance.new("UICorner", dot)
    dotCorner.CornerRadius = UDim.new(1, 0)
    
    local itemLabel = Instance.new("TextLabel", itemFrame)
    itemLabel.Size = UDim2.new(1, -34, 1, 0)
    itemLabel.Position = UDim2.new(0, 18, 0, 0)
    itemLabel.BackgroundTransparency = 1
    itemLabel.Text = rName
    itemLabel.TextColor3 = Color3.fromRGB(226, 232, 240)
    itemLabel.Font = Enum.Font.GothamMedium
    itemLabel.TextSize = 8
    itemLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local chkBox = Instance.new("Frame", itemFrame)
    chkBox.Size = UDim2.new(0, 12, 0, 12)
    chkBox.Position = UDim2.new(1, -16, 0.5, -6)
    chkBox.BackgroundColor3 = isChecked and Color3.fromRGB(37, 99, 235) or Color3.fromRGB(30, 41, 59)
    
    local chkCorner = Instance.new("UICorner", chkBox)
    chkCorner.CornerRadius = UDim.new(0, 3)
    
    itemFrame.MouseButton1Click:Connect(function()
        local newState = not PlayerState.HopRarities[rName]
        PlayerState.HopRarities[rName] = newState
        chkBox.BackgroundColor3 = newState and Color3.fromRGB(37, 99, 235) or Color3.fromRGB(30, 41, 59)
        SaveConfig()
    end)
end

-- =================================================================
-- RIGHT COLUMN CONTENT
-- =================================================================

-- 1. Auto Steal Box
local StealBox = CreateCardBox(RightCol, 60)

local StealIcon = Instance.new("TextLabel", StealBox)
StealIcon.Size = UDim2.new(0, 30, 0, 30)
StealIcon.Position = UDim2.new(0, 10, 0.5, -15)
StealIcon.BackgroundColor3 = Color3.fromRGB(6, 78, 59)
StealIcon.Text = "🥷"
StealIcon.TextSize = 13

local StealIconCorner = Instance.new("UICorner", StealIcon)
StealIconCorner.CornerRadius = UDim.new(1, 0)

local StealTitle = Instance.new("TextLabel", StealBox)
StealTitle.Size = UDim2.new(1, -90, 0, 16)
StealTitle.Position = UDim2.new(0, 48, 0, 13)
StealTitle.BackgroundTransparency = 1
StealTitle.Text = "Auto Steal"
StealTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
StealTitle.Font = Enum.Font.GothamBold
StealTitle.TextSize = 10
StealTitle.TextXAlignment = Enum.TextXAlignment.Left

local StealSub = Instance.new("TextLabel", StealBox)
StealSub.Size = UDim2.new(1, -90, 0, 12)
StealSub.Position = UDim2.new(0, 48, 0, 29)
StealSub.BackgroundTransparency = 1
StealSub.Text = "Otomatis mencuri Egg"
StealSub.TextColor3 = Color3.fromRGB(148, 163, 184)
StealSub.Font = Enum.Font.Gotham
StealSub.TextSize = 8
StealSub.TextXAlignment = Enum.TextXAlignment.Left

local StealSwitchHolder = Instance.new("Frame", StealBox)
StealSwitchHolder.Size = UDim2.new(0, 40, 0, 20)
StealSwitchHolder.Position = UDim2.new(1, -48, 0.5, -10)
StealSwitchHolder.BackgroundTransparency = 1

CreateSwitchToggle(StealSwitchHolder, PlayerState.AutoSteal, function(val)
    PlayerState.AutoSteal = val
    SaveConfig()
end)

-- 2. Collapsible Area Filter Box
local AreaBox = CreateCardBox(RightCol, 175)

local AreaHeader = Instance.new("Frame", AreaBox)
AreaHeader.Size = UDim2.new(1, -20, 0, 36)
AreaHeader.Position = UDim2.new(0, 10, 0, 8)
AreaHeader.BackgroundTransparency = 1

local AreaIcon = Instance.new("TextLabel", AreaHeader)
AreaIcon.Size = UDim2.new(0, 30, 0, 30)
AreaIcon.BackgroundColor3 = Color3.fromRGB(30, 58, 138)
AreaIcon.Text = "📍"
AreaIcon.TextSize = 13

local AreaIconCorner = Instance.new("UICorner", AreaIcon)
AreaIconCorner.CornerRadius = UDim.new(1, 0)

local AreaTitle = Instance.new("TextLabel", AreaHeader)
AreaTitle.Size = UDim2.new(1, -70, 0, 16)
AreaTitle.Position = UDim2.new(0, 38, 0, 0)
AreaTitle.BackgroundTransparency = 1
AreaTitle.Text = "Area Egg"
AreaTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
AreaTitle.Font = Enum.Font.GothamBold
AreaTitle.TextSize = 10
AreaTitle.TextXAlignment = Enum.TextXAlignment.Left

local AreaSub = Instance.new("TextLabel", AreaHeader)
AreaSub.Size = UDim2.new(1, -70, 0, 12)
AreaSub.Position = UDim2.new(0, 38, 0, 16)
AreaSub.BackgroundTransparency = 1
AreaSub.Text = "Pilih area yang diizinkan"
AreaSub.TextColor3 = Color3.fromRGB(148, 163, 184)
AreaSub.Font = Enum.Font.Gotham
AreaSub.TextSize = 8
AreaSub.TextXAlignment = Enum.TextXAlignment.Left

local AreaCollapseBtn = Instance.new("TextButton", AreaHeader)
AreaCollapseBtn.Size = UDim2.new(0, 24, 0, 24)
AreaCollapseBtn.Position = UDim2.new(1, -24, 0.5, -12)
AreaCollapseBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
AreaCollapseBtn.Text = "v"
AreaCollapseBtn.TextColor3 = Color3.fromRGB(148, 163, 184)
AreaCollapseBtn.Font = Enum.Font.GothamBold
AreaCollapseBtn.TextSize = 10

local AreaBtnCorner = Instance.new("UICorner", AreaCollapseBtn)
AreaBtnCorner.CornerRadius = UDim.new(0, 6)

local AreaScroll = Instance.new("ScrollingFrame", AreaBox)
AreaScroll.Size = UDim2.new(1, -20, 0, 120)
AreaScroll.Position = UDim2.new(0, 10, 0, 46)
AreaScroll.BackgroundTransparency = 1
AreaScroll.BorderSizePixel = 0
AreaScroll.ScrollBarThickness = 2

local AreaGrid = Instance.new("UIGridLayout", AreaScroll)
AreaGrid.CellSize = UDim2.new(0.48, 0, 0, 24)
AreaGrid.CellPadding = UDim2.new(0.04, 0, 0, 4)

local isAreaExpanded = true
AreaCollapseBtn.MouseButton1Click:Connect(function()
    isAreaExpanded = not isAreaExpanded
    AreaScroll.Visible = isAreaExpanded
    AreaCollapseBtn.Text = isAreaExpanded and "v" or "^"
    TweenService:Create(AreaBox, TweenInfo.new(0.2), {
        Size = isAreaExpanded and UDim2.new(1, -6, 0, 175) or UDim2.new(1, -6, 0, 52)
    }):Play()
end)

for _, areaKey in ipairs(VALID_AREAS) do
    local isChecked = PlayerState.SelectedAreas[areaKey] == true
    local dispName = AREA_DISPLAY_NAMES[areaKey] or areaKey
    
    local itemFrame = Instance.new("TextButton", AreaScroll)
    itemFrame.BackgroundColor3 = Color3.fromRGB(11, 18, 30)
    itemFrame.Text = ""
    
    local itemCorner = Instance.new("UICorner", itemFrame)
    itemCorner.CornerRadius = UDim.new(0, 6)
    
    local itemLabel = Instance.new("TextLabel", itemFrame)
    itemLabel.Size = UDim2.new(1, -22, 1, 0)
    itemLabel.Position = UDim2.new(0, 6, 0, 0)
    itemLabel.BackgroundTransparency = 1
    itemLabel.Text = dispName
    itemLabel.TextColor3 = Color3.fromRGB(226, 232, 240)
    itemLabel.Font = Enum.Font.GothamMedium
    itemLabel.TextSize = 8
    itemLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local chkBox = Instance.new("Frame", itemFrame)
    chkBox.Size = UDim2.new(0, 12, 0, 12)
    chkBox.Position = UDim2.new(1, -16, 0.5, -6)
    chkBox.BackgroundColor3 = isChecked and Color3.fromRGB(37, 99, 235) or Color3.fromRGB(30, 41, 59)
    
    local chkCorner = Instance.new("UICorner", chkBox)
    chkCorner.CornerRadius = UDim.new(0, 3)
    
    itemFrame.MouseButton1Click:Connect(function()
        local newState = not PlayerState.SelectedAreas[areaKey]
        PlayerState.SelectedAreas[areaKey] = newState
        chkBox.BackgroundColor3 = newState and Color3.fromRGB(37, 99, 235) or Color3.fromRGB(30, 41, 59)
        SaveConfig()
    end)
end

-- 3. Collapsible Rarity Filter Box
local RarityBox = CreateCardBox(RightCol, 175)

local RarityHeader = Instance.new("Frame", RarityBox)
RarityHeader.Size = UDim2.new(1, -20, 0, 36)
RarityHeader.Position = UDim2.new(0, 10, 0, 8)
RarityHeader.BackgroundTransparency = 1

local RarityIcon = Instance.new("TextLabel", RarityHeader)
RarityIcon.Size = UDim2.new(0, 30, 0, 30)
RarityIcon.BackgroundColor3 = Color3.fromRGB(88, 28, 135)
RarityIcon.Text = "💎"
RarityIcon.TextSize = 13

local RarityIconCorner = Instance.new("UICorner", RarityIcon)
RarityIconCorner.CornerRadius = UDim.new(1, 0)

local RarityTitle = Instance.new("TextLabel", RarityHeader)
RarityTitle.Size = UDim2.new(1, -70, 0, 16)
RarityTitle.Position = UDim2.new(0, 38, 0, 0)
RarityTitle.BackgroundTransparency = 1
RarityTitle.Text = "Egg Rarity"
RarityTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
RarityTitle.Font = Enum.Font.GothamBold
RarityTitle.TextSize = 10
RarityTitle.TextXAlignment = Enum.TextXAlignment.Left

local RaritySub = Instance.new("TextLabel", RarityHeader)
RaritySub.Size = UDim2.new(1, -70, 0, 12)
RaritySub.Position = UDim2.new(0, 38, 0, 16)
RaritySub.BackgroundTransparency = 1
RaritySub.Text = "Pilih rarity Egg yang diizinkan"
RaritySub.TextColor3 = Color3.fromRGB(148, 163, 184)
RaritySub.Font = Enum.Font.Gotham
RaritySub.TextSize = 8
RaritySub.TextXAlignment = Enum.TextXAlignment.Left

local RarityCollapseBtn = Instance.new("TextButton", RarityHeader)
RarityCollapseBtn.Size = UDim2.new(0, 24, 0, 24)
RarityCollapseBtn.Position = UDim2.new(1, -24, 0.5, -12)
RarityCollapseBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
RarityCollapseBtn.Text = "v"
RarityCollapseBtn.TextColor3 = Color3.fromRGB(148, 163, 184)
RarityCollapseBtn.Font = Enum.Font.GothamBold
RarityCollapseBtn.TextSize = 10

local RarityBtnCorner = Instance.new("UICorner", RarityCollapseBtn)
RarityBtnCorner.CornerRadius = UDim.new(0, 6)

local RarityScroll = Instance.new("ScrollingFrame", RarityBox)
RarityScroll.Size = UDim2.new(1, -20, 0, 120)
RarityScroll.Position = UDim2.new(0, 10, 0, 46)
RarityScroll.BackgroundTransparency = 1
RarityScroll.BorderSizePixel = 0
RarityScroll.ScrollBarThickness = 2

local RarityGrid = Instance.new("UIGridLayout", RarityScroll)
RarityGrid.CellSize = UDim2.new(0.48, 0, 0, 24)
RarityGrid.CellPadding = UDim2.new(0.04, 0, 0, 4)

local isRarityExpanded = true
RarityCollapseBtn.MouseButton1Click:Connect(function()
    isRarityExpanded = not isRarityExpanded
    RarityScroll.Visible = isRarityExpanded
    RarityCollapseBtn.Text = isRarityExpanded and "v" or "^"
    TweenService:Create(RarityBox, TweenInfo.new(0.2), {
        Size = isRarityExpanded and UDim2.new(1, -6, 0, 175) or UDim2.new(1, -6, 0, 52)
    }):Play()
end)

for _, rName in ipairs(OrderedRarities) do
    local isChecked = PlayerState.SelectedRarities[rName] == true
    
    local itemFrame = Instance.new("TextButton", RarityScroll)
    itemFrame.BackgroundColor3 = Color3.fromRGB(11, 18, 30)
    itemFrame.Text = ""
    
    local itemCorner = Instance.new("UICorner", itemFrame)
    itemCorner.CornerRadius = UDim.new(0, 6)
    
    local dot = Instance.new("Frame", itemFrame)
    dot.Size = UDim2.new(0, 6, 0, 6)
    dot.Position = UDim2.new(0, 8, 0.5, -3)
    dot.BackgroundColor3 = RarityColors[rName] or Color3.fromRGB(255, 255, 255)
    
    local dotCorner = Instance.new("UICorner", dot)
    dotCorner.CornerRadius = UDim.new(1, 0)
    
    local itemLabel = Instance.new("TextLabel", itemFrame)
    itemLabel.Size = UDim2.new(1, -34, 1, 0)
    itemLabel.Position = UDim2.new(0, 18, 0, 0)
    itemLabel.BackgroundTransparency = 1
    itemLabel.Text = rName
    itemLabel.TextColor3 = Color3.fromRGB(226, 232, 240)
    itemLabel.Font = Enum.Font.GothamMedium
    itemLabel.TextSize = 8
    itemLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local chkBox = Instance.new("Frame", itemFrame)
    chkBox.Size = UDim2.new(0, 12, 0, 12)
    chkBox.Position = UDim2.new(1, -16, 0.5, -6)
    chkBox.BackgroundColor3 = isChecked and Color3.fromRGB(37, 99, 235) or Color3.fromRGB(30, 41, 59)
    
    local chkCorner = Instance.new("UICorner", chkBox)
    chkCorner.CornerRadius = UDim.new(0, 3)
    
    itemFrame.MouseButton1Click:Connect(function()
        local newState = not PlayerState.SelectedRarities[rName]
        PlayerState.SelectedRarities[rName] = newState
        chkBox.BackgroundColor3 = newState and Color3.fromRGB(37, 99, 235) or Color3.fromRGB(30, 41, 59)
        SaveConfig()
    end)
end

-- =================================================================
-- TOGGLE MAIN WINDOW LOGIC
-- =================================================================
CloseBtn.MouseButton1Click:Connect(function()
    MainWindow.Visible = false
    ToggleBtn.Visible = true
end)

ToggleBtn.MouseButton1Click:Connect(function()
    MainWindow.Visible = true
    ToggleBtn.Visible = false
end)

-- RUNSERVICE ENGINE LOOPS
RunService.RenderStepped:Connect(function()
    if PlayerState.IsFlying and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        local cam = workspace.CurrentCamera
        
        if hrp and hum and cam then
            pcall(function()
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero

                if flyBodyVelocity and flyBodyGyro then
                    flyBodyGyro.CFrame = cam.CFrame
                    local moveDir = hum.MoveDirection
                    if moveDir.Magnitude > 0 then
                        local camFrame = cam.CFrame
                        local localMove = camFrame:VectorToObjectSpace(moveDir)
                        local finalVelocity = (camFrame.LookVector * -localMove.Z) + (camFrame.RightVector * localMove.X)
                        flyBodyVelocity.Velocity = finalVelocity.Unit * math.clamp(PlayerState.FlySpeed, FLY_SPEED_MIN, FLY_SPEED_MAX)
                    else
                        flyBodyVelocity.Velocity = Vector3.zero
                    end
                end
            end)
        end
    end
end)

print("[FAQIH HUB] Dynamic Visual Character Lock active! Switches back to real char when no eggs are left. ✅")
