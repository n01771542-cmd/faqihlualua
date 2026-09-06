--[[
    Script Name: faqih lua hub | jump for a egg (Strict Multi-Select Area & Collapsible Panels - Fixed Scroll + Auto Sell)
    Credits: powered by faqih
    Status: Re-Layout Egg Farm & Integrated Auto Sell Engine (Independent Scrolling Panels)
]]--

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- Validasi LocalPlayer
if not LocalPlayer then
    warn("[FAQIH HUB] LocalPlayer tidak ditemukan!")
    return
end

-- Target UI Container dengan validasi
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

-- Cleanup Old UI
local oldUI = TargetGui:FindFirstChild("FaluaLuaUI_v7")
if oldUI then oldUI:Destroy() end

-- System Variables
local SafeZoneBlock = nil
local IsFarming = false
local CONFIG_FILE_NAME = "FaqihHub_JumpForEgg_Config.json"

-- Konstanta Bounds untuk FlySpeed
local FLY_SPEED_MIN = 10
local FLY_SPEED_MAX = 1000
local FLY_SPEED_DEFAULT = 350

-- Area Names - DEFINISI AUTHORITATIVE (Internal Keys)
local VALID_AREAS = {
    "Meadow",
    "CoralReef",
    "Winter",
    "Desert",
    "CrystalMines",
    "Jungle",
    "MysticIsles",
    "Prehistoric",
    "CelestialHeights",
    "Savannah"
}

-- Area Display Names
local AREA_DISPLAY_NAMES = {
    Meadow = "Meadow Area",
    CoralReef = "Coral Reef Area",
    Winter = "Winter Area",
    Desert = "Desert Area",
    CrystalMines = "Crystal Mines Area",
    Jungle = "Jungle Area",
    MysticIsles = "Mystic Isles Area",
    Prehistoric = "Prehistoric Area",
    CelestialHeights = "Celestial Heights Area",
    Savannah = "Savannah Area"
}

-- Area Detection Patterns (Flexible Matching)
local AREA_PATTERNS = {
    Meadow = {"meadow"},
    CoralReef = {"coral", "reef"},
    Winter = {"winter", "snow", "ice", "frozen"},
    Desert = {"desert", "sand", "dune"},
    CrystalMines = {"crystal", "mine", "gem"},
    Jungle = {"jungle", "rainforest", "tropical"},
    MysticIsles = {"mystic", "isle", "island"},
    Prehistoric = {"prehistoric", "dino", "ancient"},
    CelestialHeights = {"celestial", "heaven", "sky", "cloud"},
    Savannah = {"savannah", "safari", "grassland"}
}

-- Configuration State Default
local PlayerState = {
    FlyUIVisible = true,
    IsFlying = false,     
    FlySpeed = FLY_SPEED_DEFAULT,
    Noclip = false,
    AutoFarmEgg = false,
    AutoSellEgg = false,
    StealPriority = true,
    SelectedAreas = {
        Meadow = true,
        CoralReef = true,
        Winter = true,
        Desert = true,
        CrystalMines = true,
        Jungle = true,
        MysticIsles = true,
        Prehistoric = true,
        CelestialHeights = true,
        Savannah = true
    },
    SelectedRarities = {
        Common = true, Uncommon = true, Rare = true, Epic = true,
        Legendary = true, Mythic = true, Divine = true, Celestial = true,
        Eternal = true, Ascended = true
    },
    SelectedSellRarities = {
        Common = false, Uncommon = false, Rare = false, Epic = false,
        Legendary = false, Mythic = false, Divine = false, Celestial = false,
        Eternal = false, Ascended = false
    }
}

-- CONFIG SYSTEM
local function SaveConfig()
    if not writefile then return end
    
    local dataToSave = {
        FlyUIVisible = PlayerState.FlyUIVisible,
        FlySpeed = math.clamp(PlayerState.FlySpeed, FLY_SPEED_MIN, FLY_SPEED_MAX),
        Noclip = PlayerState.Noclip,
        AutoFarmEgg = PlayerState.AutoFarmEgg,
        AutoSellEgg = PlayerState.AutoSellEgg,
        StealPriority = PlayerState.StealPriority,
        SelectedAreas = PlayerState.SelectedAreas,
        SelectedRarities = PlayerState.SelectedRarities,
        SelectedSellRarities = PlayerState.SelectedSellRarities
    }
    
    pcall(function()
        writefile(CONFIG_FILE_NAME, HttpService:JSONEncode(dataToSave))
    end)
end

local function LoadConfig()
    if not (readfile and isfile and isfile(CONFIG_FILE_NAME)) then
        return
    end
    
    local success, result = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_FILE_NAME))
    end)
    
    if success and type(result) == "table" then
        if result.FlyUIVisible ~= nil then PlayerState.FlyUIVisible = result.FlyUIVisible end
        if result.FlySpeed ~= nil then 
            PlayerState.FlySpeed = math.clamp(result.FlySpeed, FLY_SPEED_MIN, FLY_SPEED_MAX)
        end
        if result.Noclip ~= nil then PlayerState.Noclip = result.Noclip end
        if result.AutoFarmEgg ~= nil then PlayerState.AutoFarmEgg = result.AutoFarmEgg end
        if result.AutoSellEgg ~= nil then PlayerState.AutoSellEgg = result.AutoSellEgg end
        if result.StealPriority ~= nil then PlayerState.StealPriority = result.StealPriority end
        if type(result.SelectedAreas) == "table" then
            for k, v in pairs(result.SelectedAreas) do PlayerState.SelectedAreas[k] = v end
        end
        if type(result.SelectedRarities) == "table" then
            for k, v in pairs(result.SelectedRarities) do PlayerState.SelectedRarities[k] = v end
        end
        if type(result.SelectedSellRarities) == "table" then
            for k, v in pairs(result.SelectedSellRarities) do PlayerState.SelectedSellRarities[k] = v end
        end
    end
    
    PlayerState.IsFlying = false
end

LoadConfig()

local flyBodyVelocity, flyBodyGyro
local CustomToggleImageAsset = "rbxthumb://type=Asset&id=136902684546260&w=150&h=150"
local RAW_SCRIPT_URL = "https://raw.githubusercontent.com/n01771542-cmd/faqihlualua/refs/heads/main/script.lua"

-- SERVER HOP
local HopStatusText = nil

local function ServerHopByCount(targetPlayerCount)
    SaveConfig()
    
    local placeId = game.PlaceId
    local currentJobId = game.JobId
    
    if not placeId or not currentJobId then
        warn("[FAQIH HUB] PlaceId atau JobId tidak valid!")
        return
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

    local success, response = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/0?sortOrder=Asc&limit=100")
    end)
    
    if not success or not response then
        warn("[FAQIH HUB] Gagal mengambil data server dari Roblox API")
        if HopStatusText then
            HopStatusText.Text = "❌ Error: Gagal koneksi ke server API"
            HopStatusText.TextColor3 = Color3.fromRGB(239, 68, 68)
        end
        return
    end
    
    local decodeSuccess, result = pcall(function()
        return HttpService:JSONDecode(response)
    end)
    
    if decodeSuccess and result and result.data and type(result.data) == "table" then
        local matchedServers = {}
        local fallbackServers = {}
        
        for _, server in ipairs(result.data) do
            if type(server) == "table" and server.id and server.id ~= currentJobId and server.playing then
                if server.playing == targetPlayerCount then
                    table.insert(matchedServers, server.id)
                elseif server.playing < 7 then
                    table.insert(fallbackServers, server.id)
                end
            end
        end
        
        if #matchedServers > 0 then
            if HopStatusText then
                HopStatusText.Text = "✅ Server ditemukan! Teleporting..."
                HopStatusText.TextColor3 = Color3.fromRGB(34, 197, 94)
            end
            task.wait(0.5)
            pcall(function()
                TeleportService:TeleportToPlaceInstance(placeId, matchedServers[math.random(1, #matchedServers)], LocalPlayer)
            end)
            return
        elseif #fallbackServers > 0 then
            if HopStatusText then
                HopStatusText.Text = "⚠️ Server kepenuhan, menggunakan server alternatif..."
                HopStatusText.TextColor3 = Color3.fromRGB(251, 191, 36)
            end
            task.wait(0.5)
            pcall(function()
                TeleportService:TeleportToPlaceInstance(placeId, fallbackServers[math.random(1, #fallbackServers)], LocalPlayer)
            end)
            return
        else
            warn("[FAQIH HUB] Tidak ada server yang tersedia untuk kriteria yang diminta")
            if HopStatusText then
                HopStatusText.Text = "❌ Tidak ada server tersedia untuk kriteria ini"
                HopStatusText.TextColor3 = Color3.fromRGB(239, 68, 68)
            end
            return
        end
    else
        warn("[FAQIH HUB] Gagal mendecode response dari API")
        if HopStatusText then
            HopStatusText.Text = "❌ Error: Data server tidak valid"
            HopStatusText.TextColor3 = Color3.fromRGB(239, 68, 68)
        end
        return
    end
end

-- SAFE ZONE SETUP
local function CreateSafeZoneAtCurrentPos()
    local char = LocalPlayer.Character
    if not char then
        char = LocalPlayer.CharacterAdded:Wait()
    end
    
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        hrp = char:WaitForChild("HumanoidRootPart", 5)
    end
    
    if hrp then
        if SafeZoneBlock and SafeZoneBlock.Parent then 
            SafeZoneBlock:Destroy() 
        end
        
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

-- DROP HELD ITEMS
local function DropHeldItems()
    local char = LocalPlayer.Character
    if not char then return end
    
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then 
            pcall(function()
                hum:UnequipTools()
            end)
        end
        
        for _, item in ipairs(char:GetChildren()) do
            if item and item:IsA("Tool") then
                pcall(function()
                    item.CanBeDropped = true
                    item.Parent = workspace
                end)
            end
        end
    end
    
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item and item:IsA("Tool") then
                pcall(function()
                    item.CanBeDropped = true
                    item.Parent = workspace
                end)
            end
        end
    end
    
    local rep = ReplicatedStorage
    if rep then
        for _, name in ipairs({"DropItem", "Drop", "DropTool", "DropEgg", "RemoveItem"}) do
            local dropRemote = rep:FindFirstChild(name, true)
            if dropRemote and dropRemote:IsA("RemoteEvent") then
                pcall(function() dropRemote:FireServer() end)
            end
        end
    end
end

-- AUTO SELL SYSTEM (DENGAN FILTER SELECTED SELL RARITIES)
local function AutoSellEggs()
    if not PlayerState.AutoSellEgg then return end
    
    local char = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not char then return end
    
    -- Remote Detection
    local sellRemote = nil
    for _, name in ipairs({"SellEgg", "SellEggs", "SellItem", "Sell", "SellAll", "SellTools", "EggSell"}) do
        local remote = ReplicatedStorage:FindFirstChild(name, true)
        if remote and (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then
            sellRemote = remote
            break
        end
    end

    local itemsToProcess = {}
    
    local function CheckAndInsert(item)
        if not item or not item:IsA("Tool") then return end
        
        local rarity = item:GetAttribute("Rarity")
        if not rarity or type(rarity) ~= "string" then
            local lowerName = string.lower(item.Name)
            for rName, _ in pairs(PlayerState.SelectedSellRarities) do
                if string.find(lowerName, string.lower(rName)) then 
                    rarity = rName
                    break
                end
            end
        end
        
        if not rarity then rarity = "Common" end
        
        -- Hanya masukkan jika SelectedSellRarities[rarity] == true
        if PlayerState.SelectedSellRarities[rarity] == true then
            table.insert(itemsToProcess, item)
        end
    end

    for _, item in ipairs(char:GetChildren()) do CheckAndInsert(item) end
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do CheckAndInsert(item) end
    end

    if #itemsToProcess == 0 then return end

    for _, item in ipairs(itemsToProcess) do
        if not PlayerState.AutoSellEgg then break end
        pcall(function()
            if sellRemote then
                if sellRemote:IsA("RemoteEvent") then
                    sellRemote:FireServer(item)
                elseif sellRemote:IsA("RemoteFunction") then
                    sellRemote:InvokeServer(item)
                end
            else
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and item.Parent == backpack then
                    hum:EquipTool(item)
                    task.wait(0.02)
                end
                
                local interactRemote = item:FindFirstChildWhichIsA("RemoteEvent", true) or item:FindFirstChildWhichIsA("RemoteFunction", true)
                if interactRemote then
                    if interactRemote:IsA("RemoteEvent") then
                        interactRemote:FireServer("Sell")
                    else
                        interactRemote:InvokeServer("Sell")
                    end
                end
            end
        end)
    end
end

-- Loop Auto Sell
task.spawn(function()
    while task.wait(0.1) do
        if PlayerState.AutoSellEgg then
            pcall(AutoSellEggs)
        end
    end
end)

local function TeleportToSafeZone()
    if not SafeZoneBlock or not SafeZoneBlock.Parent then 
        CreateSafeZoneAtCurrentPos()
    end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    
    if hrp and hum and hum.Health > 0 and SafeZoneBlock then
        pcall(function()
            local targetCFrame = SafeZoneBlock.CFrame + Vector3.new(0, 3.5, 0)
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = targetCFrame
        end)
        
        if PlayerState.AutoSellEgg then
            AutoSellEggs()
        else
            DropHeldItems()
        end
    end
end

-- DETEKSI EGG IN INVENTORY
local function HasEggInInventory()
    local char = LocalPlayer.Character
    if not char then return false end
    
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    
    if char then
        for _, child in ipairs(char:GetChildren()) do
            if child and child:IsA("Tool") then return true end
        end
    end
    
    if backpack then
        for _, child in ipairs(backpack:GetChildren()) do
            if child and child:IsA("Tool") then return true end
        end
    end
    
    return false
end

-- AREA ZONE DETECTION
local function DetectEggZone(eggModel)
    if not eggModel then return nil end
    
    local function MatchPattern(str)
        if not str or type(str) ~= "string" then return nil end
        local lowerStr = string.lower(str)
        for areaKey, patterns in pairs(AREA_PATTERNS) do
            for _, pattern in ipairs(patterns) do
                if string.find(lowerStr, pattern) then
                    return areaKey
                end
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
    
    matched = MatchPattern(eggModel.Name)
    if matched then return matched end
    
    return nil
end

-- ADVANCED STEAL & VERIFIED TELEPORT ENGINE
local RarityPriority = {
    Ascended = 10, Eternal = 9, Celestial = 8, Divine = 7,
    Mythic = 6, Legendary = 5, Epic = 4, Rare = 3,
    Uncommon = 2, Common = 1
}

local function GetValidEggTargets()
    local validTargets = {}
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if not obj or not obj:IsA("ProximityPrompt") or not obj.Enabled then
            continue
        end
        
        local eggModel = obj.Parent
        while eggModel and eggModel ~= workspace and not eggModel:IsA("Model") do
            eggModel = eggModel.Parent
        end
        
        if not eggModel then continue end
        
        local zone = DetectEggZone(eggModel)
        if not zone or PlayerState.SelectedAreas[zone] ~= true then
            continue
        end
        
        local rarity = eggModel:GetAttribute("Rarity")
        if not rarity or type(rarity) ~= "string" then
            rarity = "Common"
        end
        
        local modelName = string.lower(eggModel.Name)
        for rName, _ in pairs(PlayerState.SelectedRarities) do
            if string.find(modelName, string.lower(rName)) then 
                rarity = rName 
            end
        end
        
        if PlayerState.SelectedRarities[rarity] ~= true then
            continue
        end
        
        local part = nil
        if obj.Parent:IsA("BasePart") then
            part = obj.Parent
        else
            part = eggModel:FindFirstChildWhichIsA("BasePart")
        end
        
        if part then
            table.insert(validTargets, {
                Prompt = obj,
                Model = eggModel,
                Rarity = rarity,
                Zone = zone,
                Priority = RarityPriority[rarity] or 1,
                Part = part
            })
        end
    end
    
    if PlayerState.StealPriority then
        table.sort(validTargets, function(a, b) 
            return a.Priority > b.Priority 
        end)
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
        pcall(function()
            if not PlayerState.AutoSellEgg then
                DropHeldItems()
            end
            task.wait(0.02)
            
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = target.Part.CFrame + Vector3.new(0, 0.5, 0)
            
            local prompt = target.Prompt
            if prompt then
                prompt.HoldDuration = 0
                prompt.RequiresLineOfSight = false
            end
            
            local maxRetries = 15
            local retryCount = 0
            local eggAcquired = false
            
            repeat
                retryCount = retryCount + 1
                
                if fireproximityprompt then
                    fireproximityprompt(prompt)
                else
                    if prompt then
                        prompt:InputHoldBegin()
                        prompt:InputHoldEnd()
                    end
                end
                
                task.wait(0.04)
                
                if HasEggInInventory() or not prompt or not prompt.Parent or not prompt.Enabled then
                    eggAcquired = true
                    break
                end
            until retryCount >= maxRetries
            
            if eggAcquired then
                TeleportToSafeZone()
                task.wait(0.04)
                if PlayerState.AutoSellEgg then
                    AutoSellEggs()
                else
                    DropHeldItems()
                end
            end
        end)
    end
    
    IsFarming = false
end

-- Loop Auto Farm
task.spawn(function()
    while task.wait(0.04) do
        if PlayerState.AutoFarmEgg then
            pcall(ProcessSmartEggTeleport)
        end
    end
end)

local function SetupPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    
    prompt.HoldDuration = 0
    prompt.RequiresLineOfSight = false
    
    pcall(function()
        prompt.Triggered:Connect(function(playerWhoTriggered)
            if playerWhoTriggered == LocalPlayer and not PlayerState.AutoFarmEgg then
                if PlayerState.AutoSellEgg then
                    AutoSellEggs()
                else
                    DropHeldItems()
                end
                TeleportToSafeZone()
            end
        end)
    end)
end

for _, prompt in pairs(workspace:GetDescendants()) do SetupPrompt(prompt) end
workspace.DescendantAdded:Connect(SetupPrompt)

-- FLY ENGINE
local function StartFlyEngine()
    local char = LocalPlayer.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    
    if not hrp or not hum then return end

    pcall(function()
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
    end)
end

local function StopFlyEngine()
    pcall(function()
        if flyBodyVelocity and flyBodyVelocity.Parent then 
            flyBodyVelocity:Destroy() 
        end
        flyBodyVelocity = nil
        
        if flyBodyGyro and flyBodyGyro.Parent then 
            flyBodyGyro:Destroy() 
        end
        flyBodyGyro = nil
    end)
    
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then 
            pcall(function()
                hum.PlatformStand = false
            end)
        end
        
        if not PlayerState.Noclip then
            for _, part in ipairs(char:GetChildren()) do
                if part and part:IsA("BasePart") then 
                    pcall(function()
                        part.CanCollide = true
                    end)
                end
            end
        end
    end
end

-- =================================================================
-- UI BASE SETUP
-- =================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FaluaLuaUI_v7"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = TargetGui

local ToggleBtn = Instance.new("ImageButton", ScreenGui)
ToggleBtn.Name = "ToggleImageBtn"
ToggleBtn.Size = UDim2.new(0, 42, 0, 42)
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

local TeleportWindow = Instance.new("Frame", ScreenGui)
TeleportWindow.Name = "TeleportWindow"
TeleportWindow.Size = UDim2.new(0, 470, 0, 330)
TeleportWindow.Position = UDim2.new(0.2, 0, 0.15, 0)
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

local TopBar = Instance.new("Frame", TeleportWindow)
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 28)
TopBar.BackgroundColor3 = Color3.fromRGB(12, 15, 22)
TopBar.BorderSizePixel = 0
TopBar.ZIndex = 2

local TopBarCorner = Instance.new("UICorner", TopBar)
TopBarCorner.CornerRadius = UDim.new(0, 10)

local AppTitle = Instance.new("TextLabel", TopBar)
AppTitle.Size = UDim2.new(1, -40, 1, 0)
AppTitle.Position = UDim2.new(0, 10, 0, 0)
AppTitle.BackgroundTransparency = 1
AppTitle.Text = "faqih lua hub  |  jump for a egg"
AppTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
AppTitle.Font = Enum.Font.GothamMedium
AppTitle.TextSize = 10
AppTitle.TextXAlignment = Enum.TextXAlignment.Left
AppTitle.ZIndex = 3

local CloseMainBtn = Instance.new("TextButton", TopBar)
CloseMainBtn.Size = UDim2.new(0, 20, 0, 20)
CloseMainBtn.Position = UDim2.new(1, -24, 0.5, -10)
CloseMainBtn.BackgroundTransparency = 1
CloseMainBtn.Text = "x"
CloseMainBtn.TextColor3 = Color3.fromRGB(220, 225, 235)
CloseMainBtn.Font = Enum.Font.GothamBold
CloseMainBtn.TextSize = 12
CloseMainBtn.ZIndex = 3

local Sidebar = Instance.new("Frame", TeleportWindow)
Sidebar.Size = UDim2.new(0, 100, 1, -28)
Sidebar.Position = UDim2.new(0, 0, 0, 28)
Sidebar.BackgroundColor3 = Color3.fromRGB(14, 17, 24)
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 2

local SidebarLayout = Instance.new("UIListLayout", Sidebar)
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Padding = UDim.new(0, 2)

local SidebarPadding = Instance.new("UIPadding", Sidebar)
SidebarPadding.PaddingTop = UDim.new(0, 6)
SidebarPadding.PaddingLeft = UDim.new(0, 5)

local function CreateTabBtn(name)
    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(1, -5, 0, 26)
    btn.BackgroundTransparency = 1
    btn.BackgroundColor3 = Color3.fromRGB(35, 42, 58)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(180, 190, 205)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 10
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.ZIndex = 3
    
    local pad = Instance.new("UIPadding", btn)
    pad.PaddingLeft = UDim.new(0, 8)
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 5)
    return btn
end

local MainTabBtn = CreateTabBtn("Main")
local EggFarmTabBtn = CreateTabBtn("Egg Farm")
local ServerHopTabBtn = CreateTabBtn("Server Hop")
local InfoTabBtn = CreateTabBtn("Info / Fitur")

-- MAIN TAB
local MainContent = Instance.new("Frame", TeleportWindow)
MainContent.Size = UDim2.new(1, -106, 1, -34)
MainContent.Position = UDim2.new(0, 103, 0, 30)
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

local WelcomeCard = Instance.new("Frame", CardsContainer)
WelcomeCard.Size = UDim2.new(1, -10, 0, 70)
WelcomeCard.BackgroundColor3 = Color3.fromRGB(28, 35, 48)
WelcomeCard.ZIndex = 3

local WelcomeCorner = Instance.new("UICorner", WelcomeCard)
WelcomeCorner.CornerRadius = UDim.new(0, 6)

local WelcomeTitle = Instance.new("TextLabel", WelcomeCard)
WelcomeTitle.Size = UDim2.new(1, -16, 0, 20)
WelcomeTitle.Position = UDim2.new(0, 10, 0, 8)
WelcomeTitle.BackgroundTransparency = 1
WelcomeTitle.Text = "Welcome to Faqih Lua Hub! 👋"
WelcomeTitle.TextColor3 = Color3.fromRGB(147, 197, 253)
WelcomeTitle.Font = Enum.Font.GothamBold
WelcomeTitle.TextSize = 11
WelcomeTitle.TextXAlignment = Enum.TextXAlignment.Left
WelcomeTitle.ZIndex = 4

local WelcomeDesc = Instance.new("TextLabel", WelcomeCard)
WelcomeDesc.Size = UDim2.new(1, -16, 0, 36)
WelcomeDesc.Position = UDim2.new(0, 10, 0, 28)
WelcomeDesc.BackgroundTransparency = 1
WelcomeDesc.Text = "Semua kontrol Egg Farm, Fly Engine, Auto Sell, & Balok Gaib telah disatukan di tab 'Egg Farm' agar lebih praktis."
WelcomeDesc.TextColor3 = Color3.fromRGB(200, 210, 225)
WelcomeDesc.Font = Enum.Font.Gotham
WelcomeDesc.TextSize = 9
WelcomeDesc.TextWrapped = true
WelcomeDesc.TextXAlignment = Enum.TextXAlignment.Left
WelcomeDesc.ZIndex = 4

-- =================================================================
-- EGG FARM TAB
-- =================================================================
local EggFarmContent = Instance.new("Frame", TeleportWindow)
EggFarmContent.Size = UDim2.new(1, -106, 1, -34)
EggFarmContent.Position = UDim2.new(0, 103, 0, 30)
EggFarmContent.BackgroundTransparency = 1
EggFarmContent.Visible = false
EggFarmContent.ZIndex = 2
EggFarmContent.ClipsDescendants = true

--------------------------------------------------------------------
-- SISI KIRI: CONTAINER FILTER (RARITY & AREA FILTER)
--------------------------------------------------------------------
local LeftFiltersFrame = Instance.new("Frame", EggFarmContent)
LeftFiltersFrame.Size = UDim2.new(0.48, -4, 1, -6)
LeftFiltersFrame.Position = UDim2.new(0, 2, 0, 3)
LeftFiltersFrame.BackgroundTransparency = 1
LeftFiltersFrame.ZIndex = 3

local LeftFiltersLayout = Instance.new("UIListLayout", LeftFiltersFrame)
LeftFiltersLayout.SortOrder = Enum.SortOrder.LayoutOrder
LeftFiltersLayout.Padding = UDim.new(0, 5)

-- HELPER: PEMBUATAN PANEL DENGAN INTERNAL SCROLLINGFRAME SENDIRI
local function CreateScrollableCollapsiblePanel(parentFrame, titleText, layoutOrder, maxHeight)
    maxHeight = maxHeight or 80

    local panelFrame = Instance.new("Frame", parentFrame)
    panelFrame.Size = UDim2.new(1, 0, 0, 26)
    panelFrame.BackgroundColor3 = Color3.fromRGB(24, 30, 42)
    panelFrame.BorderSizePixel = 0
    panelFrame.LayoutOrder = layoutOrder
    panelFrame.ClipsDescendants = true
    panelFrame.ZIndex = 4

    local panelCorner = Instance.new("UICorner", panelFrame)
    panelCorner.CornerRadius = UDim.new(0, 6)

    local panelStroke = Instance.new("UIStroke", panelFrame)
    panelStroke.Color = Color3.fromRGB(45, 55, 75)
    panelStroke.Thickness = 1

    -- Header Button
    local headerBtn = Instance.new("TextButton", panelFrame)
    headerBtn.Size = UDim2.new(1, 0, 0, 26)
    headerBtn.BackgroundColor3 = Color3.fromRGB(28, 35, 48)
    headerBtn.Text = ""
    headerBtn.ZIndex = 5

    local headerCorner = Instance.new("UICorner", headerBtn)
    headerCorner.CornerRadius = UDim.new(0, 6)

    local headerTitle = Instance.new("TextLabel", headerBtn)
    headerTitle.Size = UDim2.new(1, -25, 1, 0)
    headerTitle.Position = UDim2.new(0, 8, 0, 0)
    headerTitle.BackgroundTransparency = 1
    headerTitle.Text = titleText
    headerTitle.TextColor3 = Color3.fromRGB(147, 197, 253)
    headerTitle.Font = Enum.Font.GothamBold
    headerTitle.TextSize = 8.5
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    headerTitle.ZIndex = 6

    local arrowLabel = Instance.new("TextLabel", headerBtn)
    arrowLabel.Size = UDim2.new(0, 20, 1, 0)
    arrowLabel.Position = UDim2.new(1, -22, 0, 0)
    arrowLabel.BackgroundTransparency = 1
    arrowLabel.Text = "<>"
    arrowLabel.TextColor3 = Color3.fromRGB(147, 197, 253)
    arrowLabel.Font = Enum.Font.GothamBold
    arrowLabel.TextSize = 8.5
    arrowLabel.TextXAlignment = Enum.TextXAlignment.Center
    arrowLabel.ZIndex = 6

    -- Internal ScrollingFrame
    local scrollFrame = Instance.new("ScrollingFrame", panelFrame)
    scrollFrame.Size = UDim2.new(1, -6, 0, maxHeight)
    scrollFrame.Position = UDim2.new(0, 3, 0, 28)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 3
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(129, 140, 248)
    scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.Visible = false
    scrollFrame.ZIndex = 5

    local listLayout = Instance.new("UIListLayout", scrollFrame)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 3)

    local listPadding = Instance.new("UIPadding", scrollFrame)
    listPadding.PaddingRight = UDim.new(0, 3)

    local isOpen = false
    headerBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        scrollFrame.Visible = isOpen
        
        local targetSize = isOpen and UDim2.new(1, 0, 0, 32 + maxHeight) or UDim2.new(1, 0, 0, 26)
        TweenService:Create(panelFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = targetSize
        }):Play()
    end)

    return scrollFrame
end

-- 1. EGG RARITY FILTER PANEL (AUTO FARM)
local RarityScroll = CreateScrollableCollapsiblePanel(LeftFiltersFrame, "Egg Rarity Filter", 1, 75)

local OrderedRarities = {
    "Ascended", "Eternal", "Celestial", "Divine", "Mythic",
    "Legendary", "Epic", "Rare", "Uncommon", "Common"
}

for index, rName in ipairs(OrderedRarities) do
    local isEnabled = PlayerState.SelectedRarities[rName] == true
    
    local rBtn = Instance.new("TextButton", RarityScroll)
    rBtn.Size = UDim2.new(1, -4, 0, 20)
    rBtn.BackgroundColor3 = isEnabled and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(35, 42, 58)
    rBtn.Text = ""
    rBtn.LayoutOrder = index
    rBtn.ZIndex = 6
    
    local rCorner = Instance.new("UICorner", rBtn)
    rCorner.CornerRadius = UDim.new(0, 4)
    
    local rNameLabel = Instance.new("TextLabel", rBtn)
    rNameLabel.Size = UDim2.new(1, -32, 1, 0)
    rNameLabel.Position = UDim2.new(0, 6, 0, 0)
    rNameLabel.BackgroundTransparency = 1
    rNameLabel.Text = rName
    rNameLabel.TextColor3 = Color3.fromRGB(245, 245, 255)
    rNameLabel.Font = Enum.Font.GothamMedium
    rNameLabel.TextSize = 8.5
    rNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    rNameLabel.ZIndex = 7
    
    local rStatusLabel = Instance.new("TextLabel", rBtn)
    rStatusLabel.Size = UDim2.new(0, 28, 1, 0)
    rStatusLabel.Position = UDim2.new(1, -30, 0, 0)
    rStatusLabel.BackgroundTransparency = 1
    rStatusLabel.Text = isEnabled and "ON" or "OFF"
    rStatusLabel.TextColor3 = isEnabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 160, 175)
    rStatusLabel.Font = Enum.Font.GothamBold
    rStatusLabel.TextSize = 8
    rStatusLabel.TextXAlignment = Enum.TextXAlignment.Center
    rStatusLabel.ZIndex = 7
    
    rBtn.MouseButton1Click:Connect(function()
        local newState = not PlayerState.SelectedRarities[rName]
        PlayerState.SelectedRarities[rName] = newState
        
        rBtn.BackgroundColor3 = newState and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(35, 42, 58)
        rStatusLabel.Text = newState and "ON" or "OFF"
        rStatusLabel.TextColor3 = newState and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 160, 175)
        
        SaveConfig()
    end)
end

-- 2. AREA FILTER PANEL
local AreaScroll = CreateScrollableCollapsiblePanel(LeftFiltersFrame, "Area Filter", 2, 75)

for index, areaKey in ipairs(VALID_AREAS) do
    local isSelected = PlayerState.SelectedAreas[areaKey] == true
    local displayName = AREA_DISPLAY_NAMES[areaKey] or areaKey
    
    local aBtn = Instance.new("TextButton", AreaScroll)
    aBtn.Size = UDim2.new(1, -4, 0, 20)
    aBtn.BackgroundColor3 = isSelected and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(35, 42, 58)
    aBtn.Text = ""
    aBtn.LayoutOrder = index
    aBtn.ZIndex = 6
    
    local aCorner = Instance.new("UICorner", aBtn)
    aCorner.CornerRadius = UDim.new(0, 4)
    
    local aNameLabel = Instance.new("TextLabel", aBtn)
    aNameLabel.Size = UDim2.new(1, -6, 1, 0)
    aNameLabel.Position = UDim2.new(0, 6, 0, 0)
    aNameLabel.BackgroundTransparency = 1
    aNameLabel.Text = (isSelected and "☑ " or "☐ ") .. displayName
    aNameLabel.TextColor3 = Color3.fromRGB(245, 245, 255)
    aNameLabel.Font = Enum.Font.GothamMedium
    aNameLabel.TextSize = 8.5
    aNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    aNameLabel.ZIndex = 7
    
    aBtn.MouseButton1Click:Connect(function()
        local newState = not PlayerState.SelectedAreas[areaKey]
        PlayerState.SelectedAreas[areaKey] = newState
        
        aBtn.BackgroundColor3 = newState and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(35, 42, 58)
        aNameLabel.Text = (newState and "☑ " or "☐ ") .. displayName
        
        SaveConfig()
    end)
end

-- 3. EGG RARITY TO SELL PANEL (DESAIN BARU UNTUK AUTO SELL FILTER)
local SellRarityScroll = CreateScrollableCollapsiblePanel(LeftFiltersFrame, "Egg Rarity to Sell", 3, 75)

for index, rName in ipairs(OrderedRarities) do
    local isEnabled = PlayerState.SelectedSellRarities[rName] == true
    
    local srBtn = Instance.new("TextButton", SellRarityScroll)
    srBtn.Size = UDim2.new(1, -4, 0, 20)
    srBtn.BackgroundColor3 = isEnabled and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(35, 42, 58)
    srBtn.Text = ""
    srBtn.LayoutOrder = index
    srBtn.ZIndex = 6
    
    local srCorner = Instance.new("UICorner", srBtn)
    srCorner.CornerRadius = UDim.new(0, 4)
    
    local srNameLabel = Instance.new("TextLabel", srBtn)
    srNameLabel.Size = UDim2.new(1, -32, 1, 0)
    srNameLabel.Position = UDim2.new(0, 6, 0, 0)
    srNameLabel.BackgroundTransparency = 1
    srNameLabel.Text = (isEnabled and "☑ " or "☐ ") .. rName
    srNameLabel.TextColor3 = Color3.fromRGB(245, 245, 255)
    srNameLabel.Font = Enum.Font.GothamMedium
    srNameLabel.TextSize = 8.5
    srNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    srNameLabel.ZIndex = 7
    
    srBtn.MouseButton1Click:Connect(function()
        local newState = not PlayerState.SelectedSellRarities[rName]
        PlayerState.SelectedSellRarities[rName] = newState
        
        srBtn.BackgroundColor3 = newState and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(35, 42, 58)
        srNameLabel.Text = (newState and "☑ " or "☐ ") .. rName
        
        SaveConfig()
    end)
end

--------------------------------------------------------------------
-- SISI KANAN: CONTROLS
--------------------------------------------------------------------
local RightControlsFrame = Instance.new("Frame", EggFarmContent)
RightControlsFrame.Size = UDim2.new(0.50, -4, 1, -6)
RightControlsFrame.Position = UDim2.new(0.50, 2, 0, 3)
RightControlsFrame.BackgroundTransparency = 1
RightControlsFrame.ZIndex = 3

local RightControlsLayout = Instance.new("UIListLayout", RightControlsFrame)
RightControlsLayout.SortOrder = Enum.SortOrder.LayoutOrder
RightControlsLayout.Padding = UDim.new(0, 5)

-- 1. Auto Farm Master Toggle
local FarmMasterBtn = Instance.new("TextButton", RightControlsFrame)
FarmMasterBtn.Size = UDim2.new(1, -4, 0, 28)
FarmMasterBtn.BackgroundColor3 = Color3.fromRGB(28, 35, 48)
FarmMasterBtn.Text = ""
FarmMasterBtn.LayoutOrder = 1
FarmMasterBtn.ZIndex = 4

local FarmMasterCorner = Instance.new("UICorner", FarmMasterBtn)
FarmMasterCorner.CornerRadius = UDim.new(0, 6)

local FarmMasterTitle = Instance.new("TextLabel", FarmMasterBtn)
FarmMasterTitle.Size = UDim2.new(1, -45, 1, 0)
FarmMasterTitle.Position = UDim2.new(0, 8, 0, 0)
FarmMasterTitle.BackgroundTransparency = 1
FarmMasterTitle.Text = "⚡ Auto Farm"
FarmMasterTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
FarmMasterTitle.Font = Enum.Font.GothamBold
FarmMasterTitle.TextSize = 9.5
FarmMasterTitle.TextXAlignment = Enum.TextXAlignment.Left
FarmMasterTitle.ZIndex = 5

local FarmStatusLabel = Instance.new("TextLabel", FarmMasterBtn)
FarmStatusLabel.Size = UDim2.new(0, 35, 1, 0)
FarmStatusLabel.Position = UDim2.new(1, -40, 0, 0)
FarmStatusLabel.BackgroundTransparency = 1
FarmStatusLabel.Text = PlayerState.AutoFarmEgg and "ON" or "OFF"
FarmStatusLabel.TextColor3 = PlayerState.AutoFarmEgg and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(239, 68, 68)
FarmStatusLabel.Font = Enum.Font.GothamBold
FarmStatusLabel.TextSize = 9.5
FarmStatusLabel.TextXAlignment = Enum.TextXAlignment.Right
FarmStatusLabel.ZIndex = 5

-- 2. Auto Sell Egg Toggle
local SellToggleBtn = Instance.new("TextButton", RightControlsFrame)
SellToggleBtn.Size = UDim2.new(1, -4, 0, 28)
SellToggleBtn.BackgroundColor3 = Color3.fromRGB(28, 35, 48)
SellToggleBtn.Text = ""
SellToggleBtn.LayoutOrder = 2
SellToggleBtn.ZIndex = 4

local SellCorner = Instance.new("UICorner", SellToggleBtn)
SellCorner.CornerRadius = UDim.new(0, 6)

local SellTitle = Instance.new("TextLabel", SellToggleBtn)
SellTitle.Size = UDim2.new(1, -45, 1, 0)
SellTitle.Position = UDim2.new(0, 8, 0, 0)
SellTitle.BackgroundTransparency = 1
SellTitle.Text = "💰 Auto Sell Egg"
SellTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
SellTitle.Font = Enum.Font.GothamBold
SellTitle.TextSize = 9.5
SellTitle.TextXAlignment = Enum.TextXAlignment.Left
SellTitle.ZIndex = 5

local SellStatusLabel = Instance.new("TextLabel", SellToggleBtn)
SellStatusLabel.Size = UDim2.new(0, 35, 1, 0)
SellStatusLabel.Position = UDim2.new(1, -40, 0, 0)
SellStatusLabel.BackgroundTransparency = 1
SellStatusLabel.Text = PlayerState.AutoSellEgg and "ON" or "OFF"
SellStatusLabel.TextColor3 = PlayerState.AutoSellEgg and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(239, 68, 68)
SellStatusLabel.Font = Enum.Font.GothamBold
SellStatusLabel.TextSize = 9.5
SellStatusLabel.TextXAlignment = Enum.TextXAlignment.Right
SellStatusLabel.ZIndex = 5

-- 3. Steal Priority Toggle
local StealToggleBtn = Instance.new("TextButton", RightControlsFrame)
StealToggleBtn.Size = UDim2.new(1, -4, 0, 28)
StealToggleBtn.BackgroundColor3 = Color3.fromRGB(28, 35, 48)
StealToggleBtn.Text = ""
StealToggleBtn.LayoutOrder = 3
StealToggleBtn.ZIndex = 4

local StealCorner = Instance.new("UICorner", StealToggleBtn)
StealCorner.CornerRadius = UDim.new(0, 6)

local StealTitle = Instance.new("TextLabel", StealToggleBtn)
StealTitle.Size = UDim2.new(1, -45, 1, 0)
StealTitle.Position = UDim2.new(0, 8, 0, 0)
StealTitle.BackgroundTransparency = 1
StealTitle.Text = "🔥 Steal Priority"
StealTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
StealTitle.Font = Enum.Font.GothamMedium
StealTitle.TextSize = 9.5
StealTitle.TextXAlignment = Enum.TextXAlignment.Left
StealTitle.ZIndex = 5

local StealStatusLabel = Instance.new("TextLabel", StealToggleBtn)
StealStatusLabel.Size = UDim2.new(0, 35, 1, 0)
StealStatusLabel.Position = UDim2.new(1, -40, 0, 0)
StealStatusLabel.BackgroundTransparency = 1
StealStatusLabel.Text = PlayerState.StealPriority and "ON" or "OFF"
StealStatusLabel.TextColor3 = PlayerState.StealPriority and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(239, 68, 68)
StealStatusLabel.Font = Enum.Font.GothamBold
StealStatusLabel.TextSize = 9.5
StealStatusLabel.TextXAlignment = Enum.TextXAlignment.Right
StealStatusLabel.ZIndex = 5

-- 4. Fly Controller Engine Toggle
local FlyMainToggleBtn = Instance.new("TextButton", RightControlsFrame)
FlyMainToggleBtn.Size = UDim2.new(1, -4, 0, 28)
FlyMainToggleBtn.BackgroundColor3 = Color3.fromRGB(28, 35, 48)
FlyMainToggleBtn.Text = ""
FlyMainToggleBtn.LayoutOrder = 4
FlyMainToggleBtn.ZIndex = 4

local FlyMainCorner = Instance.new("UICorner", FlyMainToggleBtn)
FlyMainCorner.CornerRadius = UDim.new(0, 6)

local FlyMainTitle = Instance.new("TextLabel", FlyMainToggleBtn)
FlyMainTitle.Size = UDim2.new(1, -55, 1, 0)
FlyMainTitle.Position = UDim2.new(0, 8, 0, 0)
FlyMainTitle.BackgroundTransparency = 1
FlyMainTitle.Text = "🕊️ Fly Controller Engine"
FlyMainTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
FlyMainTitle.Font = Enum.Font.GothamMedium
FlyMainTitle.TextSize = 9.5
FlyMainTitle.TextXAlignment = Enum.TextXAlignment.Left
FlyMainTitle.ZIndex = 5

local FlyStatusLabel = Instance.new("TextLabel", FlyMainToggleBtn)
FlyStatusLabel.Size = UDim2.new(0, 40, 1, 0)
FlyStatusLabel.Position = UDim2.new(1, -45, 0, 0)
FlyStatusLabel.BackgroundTransparency = 1
FlyStatusLabel.Text = PlayerState.FlyUIVisible and "ON" or "OFF"
FlyStatusLabel.TextColor3 = PlayerState.FlyUIVisible and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(239, 68, 68)
FlyStatusLabel.Font = Enum.Font.GothamBold
FlyStatusLabel.TextSize = 9.5
FlyStatusLabel.TextXAlignment = Enum.TextXAlignment.Right
FlyStatusLabel.ZIndex = 5

-- 5. Reset/Atur Ulang Balok Gaib
local PlaceBlockBtn = Instance.new("TextButton", RightControlsFrame)
PlaceBlockBtn.Size = UDim2.new(1, -4, 0, 28)
PlaceBlockBtn.BackgroundColor3 = Color3.fromRGB(28, 35, 48)
PlaceBlockBtn.Text = ""
PlaceBlockBtn.LayoutOrder = 5
PlaceBlockBtn.ZIndex = 4

local PlaceCorner = Instance.new("UICorner", PlaceBlockBtn)
PlaceCorner.CornerRadius = UDim.new(0, 6)

local PlaceTitle = Instance.new("TextLabel", PlaceBlockBtn)
PlaceTitle.Size = UDim2.new(1, -10, 1, 0)
PlaceTitle.Position = UDim2.new(0, 8, 0, 0)
PlaceTitle.BackgroundTransparency = 1
PlaceTitle.Text = "🧱 Reset/Atur Balok Gaib"
PlaceTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
PlaceTitle.Font = Enum.Font.GothamMedium
PlaceTitle.TextSize = 9.5
PlaceTitle.TextXAlignment = Enum.TextXAlignment.Left
PlaceTitle.ZIndex = 5

-- =================================================================
-- SERVER HOP TAB
-- =================================================================
local HopContent = Instance.new("Frame", TeleportWindow)
HopContent.Size = UDim2.new(1, -106, 1, -34)
HopContent.Position = UDim2.new(0, 103, 0, 30)
HopContent.BackgroundTransparency = 1
HopContent.Visible = false
HopContent.ZIndex = 2

local HopTitle = Instance.new("TextLabel", HopContent)
HopTitle.Size = UDim2.new(1, 0, 0, 18)
HopTitle.BackgroundTransparency = 1
HopTitle.Text = "Server Hop (Pilih Jumlah Player)"
HopTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
HopTitle.Font = Enum.Font.GothamBold
HopTitle.TextSize = 10.5
HopTitle.TextXAlignment = Enum.TextXAlignment.Left
HopTitle.ZIndex = 3

HopStatusText = Instance.new("TextLabel", HopContent)
HopStatusText.Size = UDim2.new(1, -10, 0, 16)
HopStatusText.Position = UDim2.new(0, 0, 0, 18)
HopStatusText.BackgroundTransparency = 1
HopStatusText.Text = "Pilih server berdasarkan target pemain:"
HopStatusText.TextColor3 = Color3.fromRGB(180, 190, 205)
HopStatusText.Font = Enum.Font.Gotham
HopStatusText.TextSize = 8.5
HopStatusText.TextXAlignment = Enum.TextXAlignment.Left
HopStatusText.ZIndex = 3

local GridHopContainer = Instance.new("Frame", HopContent)
GridHopContainer.Size = UDim2.new(1, -10, 1, -40)
GridHopContainer.Position = UDim2.new(0, 0, 0, 36)
GridHopContainer.BackgroundTransparency = 1
GridHopContainer.ZIndex = 3

local GridHopLayout = Instance.new("UIGridLayout", GridHopContainer)
GridHopLayout.CellSize = UDim2.new(0.48, -4, 0, 30)
GridHopLayout.CellPadding = UDim2.new(0.04, 0, 0, 6)

for i = 1, 6 do
    local HopOptionBtn = Instance.new("TextButton", GridHopContainer)
    HopOptionBtn.Name = "HopBtn_" .. tostring(i)
    HopOptionBtn.BackgroundColor3 = Color3.fromRGB(28, 35, 48)
    HopOptionBtn.Text = "👤 " .. tostring(i) .. " Player"
    HopOptionBtn.TextColor3 = Color3.fromRGB(240, 245, 255)
    HopOptionBtn.Font = Enum.Font.GothamMedium
    HopOptionBtn.TextSize = 9.5
    HopOptionBtn.ZIndex = 4
    
    local hCorner = Instance.new("UICorner", HopOptionBtn)
    hCorner.CornerRadius = UDim.new(0, 6)
    
    HopOptionBtn.MouseButton1Click:Connect(function()
        HopStatusText.Text = "⏳ Saving Config & Teleporting..."
        HopStatusText.TextColor3 = Color3.fromRGB(251, 191, 36)
        ServerHopByCount(i)
    end)
end

-- =================================================================
-- INFO TAB
-- =================================================================
local InfoContent = Instance.new("Frame", TeleportWindow)
InfoContent.Size = UDim2.new(1, -106, 1, -34)
InfoContent.Position = UDim2.new(0, 103, 0, 30)
InfoContent.BackgroundTransparency = 1
InfoContent.Visible = false
InfoContent.ZIndex = 2

local ScrollInfo = Instance.new("ScrollingFrame", InfoContent)
ScrollInfo.Size = UDim2.new(1, -5, 1, 0)
ScrollInfo.BackgroundTransparency = 1
ScrollInfo.BorderSizePixel = 0
ScrollInfo.ScrollBarThickness = 3
ScrollInfo.CanvasSize = UDim2.new(0, 0, 0, 260)
ScrollInfo.ZIndex = 3

local InfoLayout = Instance.new("UIListLayout", ScrollInfo)
InfoLayout.SortOrder = Enum.SortOrder.LayoutOrder
InfoLayout.Padding = UDim.new(0, 5)

local function AddInfoCard(titleText, descText)
    local card = Instance.new("Frame", ScrollInfo)
    card.Size = UDim2.new(1, -10, 0, 46)
    card.BackgroundColor3 = Color3.fromRGB(28, 35, 48)
    card.ZIndex = 4
    
    local cCorner = Instance.new("UICorner", card)
    cCorner.CornerRadius = UDim.new(0, 6)
    
    local tLabel = Instance.new("TextLabel", card)
    tLabel.Size = UDim2.new(1, -12, 0, 16)
    tLabel.Position = UDim2.new(0, 6, 0, 4)
    tLabel.BackgroundTransparency = 1
    tLabel.Text = titleText
    tLabel.TextColor3 = Color3.fromRGB(147, 197, 253)
    tLabel.Font = Enum.Font.GothamBold
    tLabel.TextSize = 8.5
    tLabel.TextXAlignment = Enum.TextXAlignment.Left
    tLabel.ZIndex = 5
    
    local dLabel = Instance.new("TextLabel", card)
    dLabel.Size = UDim2.new(1, -12, 0, 22)
    dLabel.Position = UDim2.new(0, 6, 0, 18)
    dLabel.BackgroundTransparency = 1
    dLabel.Text = descText
    dLabel.TextColor3 = Color3.fromRGB(220, 225, 235)
    dLabel.Font = Enum.Font.Gotham
    dLabel.TextSize = 7.5
    dLabel.TextWrapped = true
    dLabel.TextXAlignment = Enum.TextXAlignment.Left
    dLabel.TextYAlignment = Enum.TextYAlignment.Top
    dLabel.ZIndex = 5
end

AddInfoCard("💰 Independent Auto Sell Engine", "Menjual egg secara selektif menggunakan filter 'Egg Rarity to Sell' terpisah.")
AddInfoCard("⚡ Instant Teleport & Drop", "Sistem drop otomatis mengosongkan slot hotbar agar tidak melebihi kapasitas.")
AddInfoCard("🕊️ Safe Zone Active", "Setelah mengambil telur, karakter langsung balik ke SafeZone secara stabil.")
AddInfoCard("🎯 Independent Scroll Filter", "Panel Area & Rarity masing-masing memiliki ScrollBar internal sendiri.")
AddInfoCard("✅ Strict Validation", "Auto Steal memfilter area & rarity secara bersamaan sebelum memilih target.")

-- TAB MANAGER
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
SetActiveTab("Farm")

-- FLY MINI FRAME
local FlyMiniFrame = Instance.new("Frame", ScreenGui)
FlyMiniFrame.Name = "FlyMiniFrame"
FlyMiniFrame.Size = UDim2.new(0, 140, 0, 95)
FlyMiniFrame.Position = UDim2.new(0.02, 0, 0.4, 0)
FlyMiniFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 33)
FlyMiniFrame.Active = true
FlyMiniFrame.Draggable = true
FlyMiniFrame.Visible = PlayerState.FlyUIVisible
FlyMiniFrame.ZIndex = 100

local FlyMiniCorner = Instance.new("UICorner", FlyMiniFrame)
FlyMiniCorner.CornerRadius = UDim.new(0, 8)

local FlyStroke = Instance.new("UIStroke", FlyMiniFrame)
FlyStroke.Color = Color3.fromRGB(129, 140, 248)
FlyStroke.Thickness = 1.5

local FlyMiniTitle = Instance.new("TextLabel", FlyMiniFrame)
FlyMiniTitle.Size = UDim2.new(1, -10, 0, 22)
FlyMiniTitle.Position = UDim2.new(0, 8, 0, 2)
FlyMiniTitle.BackgroundTransparency = 1
FlyMiniTitle.Text = "🕊️ Fly Controller"
FlyMiniTitle.TextColor3 = Color3.fromRGB(240, 240, 255)
FlyMiniTitle.Font = Enum.Font.GothamBold
FlyMiniTitle.TextSize = 9.5
FlyMiniTitle.TextXAlignment = Enum.TextXAlignment.Left
FlyMiniTitle.ZIndex = 101

local FlyToggleBtn = Instance.new("TextButton", FlyMiniFrame)
FlyToggleBtn.Size = UDim2.new(0.88, 0, 0, 24)
FlyToggleBtn.Position = UDim2.new(0.06, 0, 0, 26)
FlyToggleBtn.BackgroundColor3 = Color3.fromRGB(225, 29, 72)
FlyToggleBtn.Text = "FLY : OFF"
FlyToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FlyToggleBtn.Font = Enum.Font.GothamBold
FlyToggleBtn.TextSize = 9.5
FlyToggleBtn.BorderSizePixel = 0
FlyToggleBtn.ZIndex = 101

local FlyToggleCorner = Instance.new("UICorner", FlyToggleBtn)
FlyToggleCorner.CornerRadius = UDim.new(0, 5)

local SpeedFrame = Instance.new("Frame", FlyMiniFrame)
SpeedFrame.Size = UDim2.new(0.88, 0, 0, 22)
SpeedFrame.Position = UDim2.new(0.06, 0, 0, 58)
SpeedFrame.BackgroundTransparency = 1
SpeedFrame.ZIndex = 101

local SpeedMinus = Instance.new("TextButton", SpeedFrame)
SpeedMinus.Size = UDim2.new(0.28, 0, 1, 0)
SpeedMinus.Position = UDim2.new(0, 0, 0, 0)
SpeedMinus.BackgroundColor3 = Color3.fromRGB(27, 33, 45)
SpeedMinus.Text = "-"
SpeedMinus.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedMinus.Font = Enum.Font.GothamBold
SpeedMinus.TextSize = 11
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
SpeedLabel.TextSize = 8.5
SpeedLabel.ZIndex = 102

local SpeedPlus = Instance.new("TextButton", SpeedFrame)
SpeedPlus.Size = UDim2.new(0.28, 0, 1, 0)
SpeedPlus.Position = UDim2.new(0.72, 0, 0, 0)
SpeedPlus.BackgroundColor3 = Color3.fromRGB(27, 33, 45)
SpeedPlus.Text = "+"
SpeedPlus.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedPlus.Font = Enum.Font.GothamBold
SpeedPlus.TextSize = 11
SpeedPlus.BorderSizePixel = 0
SpeedPlus.ZIndex = 102

local SpeedPlusCorner = Instance.new("UICorner", SpeedPlus)
SpeedPlusCorner.CornerRadius = UDim.new(0, 4)

-- EVENT LISTENERS
local function SynchronizeFlyStates()
    if PlayerState.IsFlying then
        FlyToggleBtn.Text = "FLY : ON"
        FlyToggleBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
        StartFlyEngine()
    else
        FlyToggleBtn.Text = "FLY : OFF"
        FlyToggleBtn.BackgroundColor3 = Color3.fromRGB(225, 29, 72)
        StopFlyEngine()
    end
end

ToggleBtn.MouseButton1Click:Connect(function()
    if TeleportWindow then
        TeleportWindow.Visible = true
        ToggleBtn.Visible = false
    end
end)

CloseMainBtn.MouseButton1Click:Connect(function()
    if TeleportWindow then
        TeleportWindow.Visible = false
        ToggleBtn.Visible = true
    end
end)

PlaceBlockBtn.MouseButton1Click:Connect(function()
    CreateSafeZoneAtCurrentPos()
    PlaceTitle.Text = "✔ Balok Gaib Diperbarui!"
    PlaceTitle.TextColor3 = Color3.fromRGB(16, 185, 129)
    task.wait(1.2)
    PlaceTitle.Text = "🧱 Reset/Atur Balok Gaib"
    PlaceTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
end)

FarmMasterBtn.MouseButton1Click:Connect(function()
    PlayerState.AutoFarmEgg = not PlayerState.AutoFarmEgg
    FarmStatusLabel.Text = PlayerState.AutoFarmEgg and "ON" or "OFF"
    FarmStatusLabel.TextColor3 = PlayerState.AutoFarmEgg and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(239, 68, 68)
    SaveConfig()
end)

SellToggleBtn.MouseButton1Click:Connect(function()
    PlayerState.AutoSellEgg = not PlayerState.AutoSellEgg
    SellStatusLabel.Text = PlayerState.AutoSellEgg and "ON" or "OFF"
    SellStatusLabel.TextColor3 = PlayerState.AutoSellEgg and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(239, 68, 68)
    SaveConfig()
end)

StealToggleBtn.MouseButton1Click:Connect(function()
    PlayerState.StealPriority = not PlayerState.StealPriority
    StealStatusLabel.Text = PlayerState.StealPriority and "ON" or "OFF"
    StealStatusLabel.TextColor3 = PlayerState.StealPriority and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(239, 68, 68)
    SaveConfig()
end)

FlyMainToggleBtn.MouseButton1Click:Connect(function()
    PlayerState.FlyUIVisible = not PlayerState.FlyUIVisible
    if FlyMiniFrame then
        FlyMiniFrame.Visible = PlayerState.FlyUIVisible
    end
    
    if PlayerState.FlyUIVisible then
        FlyStatusLabel.Text = "ON"
        FlyStatusLabel.TextColor3 = Color3.fromRGB(16, 185, 129)
    else
        FlyStatusLabel.Text = "OFF"
        FlyStatusLabel.TextColor3 = Color3.fromRGB(239, 68, 68)
        PlayerState.IsFlying = false
        SynchronizeFlyStates()
    end
    SaveConfig()
end)

FlyToggleBtn.MouseButton1Click:Connect(function()
    PlayerState.IsFlying = not PlayerState.IsFlying
    SynchronizeFlyStates()
end)

SpeedPlus.MouseButton1Click:Connect(function()
    PlayerState.FlySpeed = math.clamp(PlayerState.FlySpeed + 10, FLY_SPEED_MIN, FLY_SPEED_MAX)
    SpeedLabel.Text = "Spd: " .. tostring(PlayerState.FlySpeed)
    SaveConfig()
end)

SpeedMinus.MouseButton1Click:Connect(function()
    PlayerState.FlySpeed = math.clamp(PlayerState.FlySpeed - 10, FLY_SPEED_MIN, FLY_SPEED_MAX)
    SpeedLabel.Text = "Spd: " .. tostring(PlayerState.FlySpeed)
    SaveConfig()
end)

RunService.RenderStepped:Connect(function()
    if PlayerState.IsFlying and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        local cam = workspace.CurrentCamera
        
        if not hum or not cam then return end

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
end)

RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end

    if PlayerState.IsFlying or PlayerState.Noclip then
        for _, part in ipairs(char:GetChildren()) do
            if part and part:IsA("BasePart") then 
                pcall(function()
                    part.CanCollide = false
                end)
            end
        end
    end
end)

print("[FAQIH HUB] Script loaded successfully! ✅")
print("[EggFarm UI] Auto Sell Engine, Dynamic Config & Compact Internal Scroll UI Implemented!")
