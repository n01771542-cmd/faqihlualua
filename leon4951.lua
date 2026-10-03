-- AUTO EXECUTE PAS TELEPORT / HOP SERVER
local queue = syn and syn.queue_on_teleport or queue_on_teleport or fluxus and fluxus.queue_on_teleport
if queue then queue('loadstring(game:HttpGet("https://raw.githubusercontent.com/n01771542-cmd/faqihlualua/main/leon4951.lua"))()') end

local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local PlaceId = game.PlaceId
local LocalPlayer = Players.LocalPlayer

--------------------------------------------------------------------------------
-- KOORDINAT TARGET & STATE FITUR
--------------------------------------------------------------------------------
local TARGET_POS = Vector3.new(491, 70, -371)
local WAYPOINT_POS = Vector3.new(618.43, 71.69, -394.05)
local safeZoneHoldDuration = 1.0

local isAntiHitGuardsActive = false
local isProcessingAntiHitV1 = false

local isInstantTpActive = false
local isProcessingInstantTp = false

-- AUTOMATIC ANTI-SLOW STATE
local lockedWalkSpeed = 16
local autoAntiSlowConnection = nil

if not _G.LeonBlacklist then
    _G.LeonBlacklist = {}
end
_G.LeonBlacklist[game.JobId] = true

local IsSearching = false

--------------------------------------------------------------------------------
-- THEME COLOR PALETTE
--------------------------------------------------------------------------------
local Theme = {
    Background = Color3.fromRGB(7, 10, 17),
    Card = Color3.fromRGB(14, 20, 32),
    Accent = Color3.fromRGB(37, 120, 255),
    AccentLight = Color3.fromRGB(82, 151, 255),
    Text = Color3.fromRGB(245, 247, 255),
    TextMuted = Color3.fromRGB(130, 145, 175),
    Border = Color3.fromRGB(34, 48, 73),
    Off = Color3.fromRGB(20, 27, 40),
    OffStroke = Color3.fromRGB(50, 64, 88),
    On = Color3.fromRGB(18, 48, 43),
    OnStroke = Color3.fromRGB(46, 146, 116),
}

--------------------------------------------------------------------------------
-- UI SETUP & NOTIFICATION BANNER
--------------------------------------------------------------------------------
local GUI_NAME = "LEON4951_HUB_ELEGANT"
pcall(function()
    local old = CoreGui:FindFirstChild(GUI_NAME) or (LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild(GUI_NAME))
    if old then old:Destroy() end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 1
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

-- NOTIFIKASI DI ATAS LAYAR
local TopNotifFrame = Instance.new("Frame")
TopNotifFrame.Name = "TopNotifFrame"
TopNotifFrame.Size = UDim2.fromOffset(320, 52)
TopNotifFrame.AnchorPoint = Vector2.new(0.5, 0)
TopNotifFrame.Position = UDim2.new(0.5, 0, 0, -70)
TopNotifFrame.BackgroundColor3 = Theme.Background
TopNotifFrame.BorderSizePixel = 0
TopNotifFrame.Parent = ScreenGui

local NotifCorner = Instance.new("UICorner")
NotifCorner.CornerRadius = UDim.new(0, 8)
NotifCorner.Parent = TopNotifFrame

local NotifStroke = Instance.new("UIStroke")
NotifStroke.Color = Theme.Accent
NotifStroke.Thickness = 1.5
NotifStroke.Transparency = 0.1
NotifStroke.Parent = TopNotifFrame

local SmallNoticeLabel = Instance.new("TextLabel")
SmallNoticeLabel.Size = UDim2.new(1, -16, 0, 16)
SmallNoticeLabel.Position = UDim2.fromOffset(8, 6)
SmallNoticeLabel.BackgroundTransparency = 1
SmallNoticeLabel.Text = "Pakai fitur ini jika anti hit guards delivery failed."
SmallNoticeLabel.TextColor3 = Theme.AccentLight
SmallNoticeLabel.Font = Enum.Font.GothamBold
SmallNoticeLabel.TextSize = 9
SmallNoticeLabel.TextScaled = true
SmallNoticeLabel.Parent = TopNotifFrame

local BigNoticeLabel = Instance.new("TextLabel")
BigNoticeLabel.Size = UDim2.new(1, -16, 0, 20)
BigNoticeLabel.Position = UDim2.fromOffset(8, 24)
BigNoticeLabel.BackgroundTransparency = 1
BigNoticeLabel.Text = "Drop egg, ambil egg kembali baru ke safe zone"
BigNoticeLabel.TextColor3 = Theme.Text
BigNoticeLabel.Font = Enum.Font.GothamBold
BigNoticeLabel.TextSize = 9.5
BigNoticeLabel.TextScaled = true
BigNoticeLabel.Parent = TopNotifFrame

local function ShowTopNotification()
    TopNotifFrame:TweenPosition(UDim2.new(0.5, 0, 0, 15), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.4, true)
    task.delay(8, function()
        TopNotifFrame:TweenPosition(UDim2.new(0.5, 0, 0, -70), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.3, true)
    end)
end

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS & AUTOMATIC ANTI-SLOW LOGIC
--------------------------------------------------------------------------------
local function WaitForCharacterRoot(char)
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 5)
    if root and root.Parent and char.Parent then
        return root
    end
    return nil
end

local function StartAutoAntiSlow(char)
    if autoAntiSlowConnection then autoAntiSlowConnection:Disconnect() end

    local humanoid = char:WaitForChild("Humanoid", 5)
    if not humanoid then return end

    task.wait(0.2)
    if humanoid.WalkSpeed > 0 then
        lockedWalkSpeed = humanoid.WalkSpeed
    end

    autoAntiSlowConnection = RunService.PreRender:Connect(function()
        if humanoid and humanoid.Parent then
            if humanoid.WalkSpeed ~= lockedWalkSpeed and humanoid.WalkSpeed > 0 then
                humanoid.WalkSpeed = lockedWalkSpeed
            end
        else
            if autoAntiSlowConnection then autoAntiSlowConnection:Disconnect() end
        end
    end)
end

if LocalPlayer.Character then task.spawn(function() StartAutoAntiSlow(LocalPlayer.Character) end) end
LocalPlayer.CharacterAdded:Connect(function(newChar)
    task.spawn(function() StartAutoAntiSlow(newChar) end)
end)

-- ============================================================================
-- LOGIC FITUR 1: ANTI HIT GUARDS (Fake Visual & Real Teleport + Return)
-- ============================================================================
local function CreateFakeAndTeleportReal()
    local char = LocalPlayer.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    local realHumanoid = char:FindFirstChildOfClass("Humanoid")
    if not root or not realHumanoid then return end

    local originalCFrame = root.CFrame
    char.Archivable = true

    local fakeChar = char:Clone()
    char.Archivable = false
    fakeChar.Name = "FakeVisualPlayer"

    for _, part in ipairs(fakeChar:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.Anchored = true
        elseif part:IsA("Script") or part:IsA("LocalScript") then
            part:Destroy()
        end
    end

    fakeChar.Parent = workspace
    fakeChar:PivotTo(originalCFrame)

    local camera = workspace.CurrentCamera
    local fakeHumanoid = fakeChar:FindFirstChildOfClass("Humanoid")

    if fakeHumanoid and camera then
        camera.CameraSubject = fakeHumanoid
    end

    local targetCFrame = CFrame.new(TARGET_POS + Vector3.new(0, 3, 0))
    local startTime = os.clock()
    local holdConnection

    holdConnection = RunService.Heartbeat:Connect(function()
        if not char or not root or not root.Parent then
            if holdConnection then holdConnection:Disconnect() end
            return
        end

        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.CFrame = targetCFrame
        char:PivotTo(targetCFrame)

        if os.clock() - startTime >= 0.6 then
            holdConnection:Disconnect()
        end
    end)

    task.delay(0.6, function()
        if holdConnection then holdConnection:Disconnect() end

        if char and root and root.Parent then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = originalCFrame
            char:PivotTo(originalCFrame)
        end

        if fakeChar then fakeChar:Destroy() end
        if realHumanoid and camera then
            camera.CameraSubject = realHumanoid
        end
    end)
end

local function ExecuteDropAndTeleportAntiHitV1()
    if isProcessingAntiHitV1 or not isAntiHitGuardsActive then return end
    isProcessingAntiHitV1 = true

    task.wait(0.1)

    local char = LocalPlayer.Character
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") then
                item.Parent = workspace
            end
        end
        CreateFakeAndTeleportReal()
    end

    task.delay(0.8, function()
        isProcessingAntiHitV1 = false
    end)
end

-- ============================================================================
-- LOGIC FITUR 2: INSTANT TELEPORT TO WAYPOINT (TOGGLE)
-- ============================================================================
local function ExecuteTeleportToWaypoint()
    if isProcessingInstantTp or not isInstantTpActive then return end
    isProcessingInstantTp = true

    local char = LocalPlayer.Character
    if char then
        local root = WaitForCharacterRoot(char)
        if root then
            local targetWaypointCFrame = CFrame.new(WAYPOINT_POS)
            local startTime = os.clock()
            local holdConnection

            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = targetWaypointCFrame
            char:PivotTo(targetWaypointCFrame)

            holdConnection = RunService.Heartbeat:Connect(function()
                if not char or not root or not root.Parent then
                    if holdConnection then holdConnection:Disconnect() end
                    return
                end

                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
                root.CFrame = targetWaypointCFrame
                char:PivotTo(targetWaypointCFrame)

                if os.clock() - startTime >= safeZoneHoldDuration then
                    holdConnection:Disconnect()
                end
            end)

            task.wait(safeZoneHoldDuration)

            ShowTopNotification()
        end
    end

    task.delay(0.05, function()
        isProcessingInstantTp = false
    end)
end

--------------------------------------------------------------------------------
-- EVENT TRIGGERS (PROXIMITY & CHARACTER DETECTION)
--------------------------------------------------------------------------------
ProximityPromptService.PromptTriggered:Connect(function(prompt, playerWhoTriggered)
    if playerWhoTriggered == LocalPlayer then
        if isAntiHitGuardsActive then
            task.spawn(function() ExecuteDropAndTeleportAntiHitV1() end)
        end
        if isInstantTpActive then
            task.spawn(function() ExecuteTeleportToWaypoint() end)
        end
    end
end)

local function SetupCharacterDetection(char)
    char.ChildAdded:Connect(function(child)
        local name = string.lower(child.Name)
        local isEggOrTool = string.find(name, "egg") or string.find(name, "telur") or child:IsA("Tool")

        if isAntiHitGuardsActive and not child:IsA("Tool") then
            if string.find(name, "egg") or string.find(name, "telur") then
                task.spawn(function() ExecuteDropAndTeleportAntiHitV1() end)
            end
        end

        if isInstantTpActive and isEggOrTool then
            task.spawn(function() ExecuteTeleportToWaypoint() end)
        end
    end)
end

if LocalPlayer.Character then SetupCharacterDetection(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(function(newChar)
    task.wait(0.05)
    SetupCharacterDetection(newChar)
end)

--------------------------------------------------------------------------------
-- MAIN HUB UI STRUCTURE
--------------------------------------------------------------------------------
local FULL_HEIGHT = 168
local CLOSED_HEIGHT = 78
local MAIN_WIDTH = 180

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.fromOffset(MAIN_WIDTH, FULL_HEIGHT)
MainFrame.AnchorPoint = Vector2.new(1, 0)
MainFrame.Position = UDim2.new(1, 0, 0, 0)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Theme.Border
MainStroke.Thickness = 1.2
MainStroke.Transparency = 0.08
MainStroke.Parent = MainFrame

local TopAccent = Instance.new("Frame")
TopAccent.Size = UDim2.new(0, 45, 0, 2)
TopAccent.Position = UDim2.new(0.5, -22, 0, 0)
TopAccent.BackgroundColor3 = Theme.Accent
TopAccent.BorderSizePixel = 0
TopAccent.Parent = MainFrame

local TopAccentCorner = Instance.new("UICorner")
TopAccentCorner.CornerRadius = UDim.new(1, 0)
TopAccentCorner.Parent = TopAccent

-- HEADER / TITLE AREA
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 30)
Header.BackgroundTransparency = 1
Header.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.fromOffset(18, 18)
ToggleBtn.Position = UDim2.fromOffset(6, 6)
ToggleBtn.BackgroundColor3 = Theme.Card
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Text = "<"
ToggleBtn.TextColor3 = Theme.Text
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 12
ToggleBtn.Parent = Header

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 5)
ToggleCorner.Parent = ToggleBtn

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Theme.Border
ToggleStroke.Thickness = 1
ToggleStroke.Parent = ToggleBtn

local LogoHolder = Instance.new("Frame")
LogoHolder.Size = UDim2.fromOffset(18, 18)
LogoHolder.Position = UDim2.fromOffset(28, 6)
LogoHolder.BackgroundColor3 = Color3.fromRGB(10, 18, 32)
LogoHolder.BorderSizePixel = 0
LogoHolder.ClipsDescendants = true
LogoHolder.Parent = Header

local LogoCorner = Instance.new("UICorner")
LogoCorner.CornerRadius = UDim.new(0, 5)
LogoCorner.Parent = LogoHolder

local LogoStroke = Instance.new("UIStroke")
LogoStroke.Color = Theme.Accent
LogoStroke.Thickness = 1
LogoStroke.Transparency = 0.35
LogoStroke.Parent = LogoHolder

local FVertical = Instance.new("Frame")
FVertical.Size = UDim2.fromOffset(2.5, 9)
FVertical.Position = UDim2.fromOffset(5.5, 4.5)
FVertical.BackgroundColor3 = Theme.Accent
FVertical.BorderSizePixel = 0
FVertical.Rotation = -6
FVertical.Parent = LogoHolder

local FTop = Instance.new("Frame")
FTop.Size = UDim2.fromOffset(6.5, 2.5)
FTop.Position = UDim2.fromOffset(7, 4.5)
FTop.BackgroundColor3 = Theme.Accent
FTop.BorderSizePixel = 0
FTop.Rotation = -6
FTop.Parent = LogoHolder

local FMiddle = Instance.new("Frame")
FMiddle.Size = UDim2.fromOffset(5, 2)
FMiddle.Position = UDim2.fromOffset(6.5, 8)
FMiddle.BackgroundColor3 = Theme.AccentLight
FMiddle.BorderSizePixel = 0
FMiddle.Rotation = -6
FMiddle.Parent = LogoHolder

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -52, 0, 15)
Title.Position = UDim2.fromOffset(50, 2)
Title.BackgroundTransparency = 1
Title.RichText = true
Title.Text = 'leon4951 <font color="rgb(65,135,255)">Hub</font>'
Title.TextColor3 = Theme.Text
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1, -52, 0, 10)
Subtitle.Position = UDim2.fromOffset(50, 16)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "MAIN UTILITIES"
Subtitle.TextColor3 = Theme.TextMuted
Subtitle.Font = Enum.Font.GothamMedium
Subtitle.TextSize = 6.5
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

local ExtraFeatures = Instance.new("CanvasGroup")
ExtraFeatures.Name = "ExtraFeatures"
ExtraFeatures.Size = UDim2.new(1, 0, 0, 90)
ExtraFeatures.Position = UDim2.fromOffset(0, 78)
ExtraFeatures.BackgroundTransparency = 1
ExtraFeatures.BorderSizePixel = 0
ExtraFeatures.GroupTransparency = 0
ExtraFeatures.Parent = MainFrame

-- ============================================================================
-- 1. TOMBOL ATAS: HOP SERVER
-- ============================================================================
local AutoHopBtn = Instance.new("TextButton")
AutoHopBtn.Name = "AutoHopButton"
AutoHopBtn.Size = UDim2.new(1, -12, 0, 38)
AutoHopBtn.Position = UDim2.fromOffset(6, 35)
AutoHopBtn.BackgroundColor3 = Theme.Off
AutoHopBtn.BorderSizePixel = 0
AutoHopBtn.AutoButtonColor = false
AutoHopBtn.Text = ""
AutoHopBtn.Parent = MainFrame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 8)
BtnCorner.Parent = AutoHopBtn

local BtnStroke = Instance.new("UIStroke")
BtnStroke.Color = Theme.OffStroke
BtnStroke.Thickness = 1
BtnStroke.Transparency = 0.2
BtnStroke.Parent = AutoHopBtn

local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.fromOffset(6, 6)
StatusDot.Position = UDim2.fromOffset(8, 16)
StatusDot.BackgroundColor3 = Theme.Accent
StatusDot.BorderSizePixel = 0
StatusDot.Parent = AutoHopBtn

local StatusDotCorner = Instance.new("UICorner")
StatusDotCorner.CornerRadius = UDim.new(1, 0)
StatusDotCorner.Parent = StatusDot

local BtnTitle = Instance.new("TextLabel")
BtnTitle.Size = UDim2.new(1, -20, 0, 15)
BtnTitle.Position = UDim2.fromOffset(18, 4)
BtnTitle.BackgroundTransparency = 1
BtnTitle.Text = "AUTO HOP SERVER"
BtnTitle.TextColor3 = Theme.Text
BtnTitle.Font = Enum.Font.GothamBold
BtnTitle.TextSize = 10
BtnTitle.TextXAlignment = Enum.TextXAlignment.Left
BtnTitle.Parent = AutoHopBtn

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 11)
StatusLabel.Position = UDim2.fromOffset(18, 18)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Status: Idle (1P -2 Rows)"
StatusLabel.TextColor3 = Theme.TextMuted
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.TextSize = 7
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = AutoHopBtn

-- ============================================================================
-- 2. TOMBOL TENGAH: ANTI HIT GUARDS
-- ============================================================================
local AntiHitGuardsBtn = Instance.new("TextButton")
AntiHitGuardsBtn.Name = "AntiHitGuardsBtn"
AntiHitGuardsBtn.Size = UDim2.new(1, -12, 0, 38)
AntiHitGuardsBtn.Position = UDim2.fromOffset(6, 0)
AntiHitGuardsBtn.BackgroundColor3 = Theme.Off
AntiHitGuardsBtn.BorderSizePixel = 0
AntiHitGuardsBtn.AutoButtonColor = false
AntiHitGuardsBtn.Text = ""
AntiHitGuardsBtn.Parent = ExtraFeatures

local AntiHitCorner = Instance.new("UICorner")
AntiHitCorner.CornerRadius = UDim.new(0, 8)
AntiHitCorner.Parent = AntiHitGuardsBtn

local AntiHitStroke = Instance.new("UIStroke")
AntiHitStroke.Color = Theme.OffStroke
AntiHitStroke.Thickness = 1
AntiHitStroke.Transparency = 0.2
AntiHitStroke.Parent = AntiHitGuardsBtn

local AntiHitDot = Instance.new("Frame")
AntiHitDot.Size = UDim2.fromOffset(6, 6)
AntiHitDot.Position = UDim2.fromOffset(8, 16)
AntiHitDot.BackgroundColor3 = Theme.TextMuted
AntiHitDot.BorderSizePixel = 0
AntiHitDot.Parent = AntiHitGuardsBtn

local AntiHitDotCorner = Instance.new("UICorner")
AntiHitDotCorner.CornerRadius = UDim.new(1, 0)
AntiHitDotCorner.Parent = AntiHitDot

local AntiHitTitleLabel = Instance.new("TextLabel")
AntiHitTitleLabel.Size = UDim2.new(1, -20, 0, 15)
AntiHitTitleLabel.Position = UDim2.fromOffset(18, 4)
AntiHitTitleLabel.BackgroundTransparency = 1
AntiHitTitleLabel.Text = "ANTI HIT GUARDS"
AntiHitTitleLabel.TextColor3 = Theme.Text
AntiHitTitleLabel.Font = Enum.Font.GothamBold
AntiHitTitleLabel.TextSize = 10
AntiHitTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
AntiHitTitleLabel.Parent = AntiHitGuardsBtn

local AntiHitStatusLabel = Instance.new("TextLabel")
AntiHitStatusLabel.Size = UDim2.new(1, -20, 0, 11)
AntiHitStatusLabel.Position = UDim2.fromOffset(18, 18)
AntiHitStatusLabel.BackgroundTransparency = 1
AntiHitStatusLabel.Text = "Status: OFF"
AntiHitStatusLabel.TextColor3 = Theme.TextMuted
AntiHitStatusLabel.Font = Enum.Font.GothamMedium
AntiHitStatusLabel.TextSize = 7
AntiHitStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
AntiHitStatusLabel.Parent = AntiHitGuardsBtn

-- ============================================================================
-- 3. TOMBOL BAWAH: INSTANT TELEPORT
-- ============================================================================
local InstantTpBtn = Instance.new("TextButton")
InstantTpBtn.Name = "InstantTpBtn"
InstantTpBtn.Size = UDim2.new(1, -12, 0, 42)
InstantTpBtn.Position = UDim2.fromOffset(6, 43)
InstantTpBtn.BackgroundColor3 = Theme.Off
InstantTpBtn.BorderSizePixel = 0
InstantTpBtn.AutoButtonColor = false
InstantTpBtn.Text = ""
InstantTpBtn.Parent = ExtraFeatures

local InstantTpCorner = Instance.new("UICorner")
InstantTpCorner.CornerRadius = UDim.new(0, 8)
InstantTpCorner.Parent = InstantTpBtn

local InstantTpStroke = Instance.new("UIStroke")
InstantTpStroke.Color = Theme.OffStroke
InstantTpStroke.Thickness = 1
InstantTpStroke.Transparency = 0.2
InstantTpStroke.Parent = InstantTpBtn

local InstantTpDot = Instance.new("Frame")
InstantTpDot.Size = UDim2.fromOffset(6, 6)
InstantTpDot.Position = UDim2.fromOffset(8, 18)
InstantTpDot.BackgroundColor3 = Theme.TextMuted
InstantTpDot.BorderSizePixel = 0
InstantTpDot.Parent = InstantTpBtn

local InstantTpDotCorner = Instance.new("UICorner")
InstantTpDotCorner.CornerRadius = UDim.new(1, 0)
InstantTpDotCorner.Parent = InstantTpDot

local InstantTpTitleLabel = Instance.new("TextLabel")
InstantTpTitleLabel.Size = UDim2.new(1, -20, 0, 24)
InstantTpTitleLabel.Position = UDim2.fromOffset(18, 3)
InstantTpTitleLabel.BackgroundTransparency = 1
InstantTpTitleLabel.Text = "Instant teleport gunakan jika anti hit guards delivery failed"
InstantTpTitleLabel.TextColor3 = Theme.Text
InstantTpTitleLabel.Font = Enum.Font.GothamBold
InstantTpTitleLabel.TextSize = 7.5
InstantTpTitleLabel.TextWrapped = true
InstantTpTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
InstantTpTitleLabel.Parent = InstantTpBtn

local InstantTpStatusLabel = Instance.new("TextLabel")
InstantTpStatusLabel.Size = UDim2.new(1, -20, 0, 11)
InstantTpStatusLabel.Position = UDim2.fromOffset(18, 27)
InstantTpStatusLabel.BackgroundTransparency = 1
InstantTpStatusLabel.Text = "Status: OFF"
InstantTpStatusLabel.TextColor3 = Theme.TextMuted
InstantTpStatusLabel.Font = Enum.Font.GothamMedium
InstantTpStatusLabel.TextSize = 6.5
InstantTpStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
InstantTpStatusLabel.Parent = InstantTpBtn

--------------------------------------------------------------------------------
-- LOGIKA TELEPORTATION (TARGET: 2 BARIS SEBELUM BARIS TERAKHIR 1 PLAYER)
--------------------------------------------------------------------------------
local function RequestAPI(options)
    local req = request or http_request or (syn and syn.request) or (http and http.request)
    if req then return req(options) end
    return nil
end

local function FindLowestTailServer()
    local cursor = ""
    local servers1P = {}
    local servers2P = {}

    -- Ambil seluruh daftar server terurut Ascending (Paling Sedikit Pemain)[span_1](start_span)[span_1](end_span)
    for page = 1, 10 do
        local url = string.format("https://games.roblox.com/v1/games/%d/servers/0?sortOrder=Asc&limit=100", PlaceId)
        if cursor ~= "" then url = url .. "&cursor=" .. cursor end

        local res = RequestAPI({Url = url, Method = "GET"})
        if res and res.Body then
            local decoded = HttpService:JSONDecode(res.Body)
            if decoded and decoded.data then
                for _, server in ipairs(decoded.data) do
                    local playing = server.playing or 0
                    local maxPlayers = server.maxPlayers or 0

                    if server.id and not _G.LeonBlacklist[server.id] and (maxPlayers - playing) >= 1 then
                        if playing == 1 then
                            table.insert(servers1P, server)
                        elseif playing == 2 then
                            table.insert(servers2P, server)
                        end
                    end
                end

                cursor = decoded.nextPageCursor or ""
                if cursor == "" then break end
            else break end
        else break end
    end

    -- LOGIKA TARGET: 2 Baris sebelum baris terakhir list 1 Player
    -- (1 baris isi 2 server, jadi 2 baris sebelum paling bawah = offset -4)
    if #servers1P > 0 then
        local targetIndex = #servers1P - 4
        
        if targetIndex < 1 then
            targetIndex = 1
        end

        for i = targetIndex, 1, -1 do
            local s = servers1P[i]
            if s and not _G.LeonBlacklist[s.id] then
                return s.id, s.playing
            end
        end
    end

    -- FALLBACK: Jika server 1P habis, ambil dari 2 Player (offset 2 baris dari bawah juga)
    if #servers2P > 0 then
        local targetIndex2P = #servers2P - 4
        if targetIndex2P < 1 then targetIndex2P = 1 end

        for i = targetIndex2P, 1, -1 do
            local s = servers2P[i]
            if s and not _G.LeonBlacklist[s.id] then
                return s.id, s.playing
            end
        end
    end

    return nil, nil
end

local function StartAutoHop()
    if IsSearching then
        IsSearching = false
        BtnTitle.Text = "AUTO HOP SERVER"
        BtnTitle.TextColor3 = Theme.Text
        StatusLabel.Text = "Status: Idle (1P -2 Rows)"
        StatusDot.BackgroundColor3 = Theme.Accent
        BtnStroke.Color = Theme.OffStroke
        return
    end

    IsSearching = true
    BtnTitle.Text = "STOP SEARCHING"
    BtnTitle.TextColor3 = Color3.fromRGB(255, 100, 100)
    StatusDot.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    BtnStroke.Color = Color3.fromRGB(180, 50, 50)

    task.spawn(function()
        local attempt = 1

        while IsSearching do
            StatusLabel.Text = string.format("Scanning target... (#%d)", attempt)

            local foundJobId, playerCount = FindLowestTailServer()

            if foundJobId then
                _G.LeonBlacklist[foundJobId] = true
                StatusLabel.Text = string.format("Found %dP! Joining...", playerCount)
                BtnTitle.Text = "JOINING..."

                local failConn
                failConn = TeleportService.TeleportInitFailed:Connect(function()
                    failConn:Disconnect()
                    StatusLabel.Text = "Failed! Retrying..."
                    task.wait(0.5)
                end)

                TeleportService:TeleportToPlaceInstance(PlaceId, foundJobId, LocalPlayer)
                task.wait(5)
            else
                StatusLabel.Text = string.format("Retrying... (#%d)", attempt)
                attempt = attempt + 1
                task.wait(0.3)
            end
        end

        BtnTitle.Text = "AUTO HOP SERVER"
        BtnTitle.TextColor3 = Theme.Text
        StatusDot.BackgroundColor3 = Theme.Accent
        BtnStroke.Color = Theme.OffStroke
    end)
end

--------------------------------------------------------------------------------
-- ANIMASI MINIMIZE / EXPAND TOGGLE
--------------------------------------------------------------------------------
local isCollapsed = false
local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

ToggleBtn.MouseButton1Click:Connect(function()
    isCollapsed = not isCollapsed

    if isCollapsed then
        ToggleBtn.Text = ">"

        TweenService:Create(ExtraFeatures, tweenInfo, {GroupTransparency = 1}):Play()
        TweenService:Create(MainFrame, tweenInfo, {Size = UDim2.fromOffset(MAIN_WIDTH, CLOSED_HEIGHT)}):Play()

        task.delay(0.3, function()
            if isCollapsed then
                ExtraFeatures.Visible = false
            end
        end)
    else
        ToggleBtn.Text = "<"
        ExtraFeatures.Visible = true

        TweenService:Create(MainFrame, tweenInfo, {Size = UDim2.fromOffset(MAIN_WIDTH, FULL_HEIGHT)}):Play()
        TweenService:Create(ExtraFeatures, tweenInfo, {GroupTransparency = 0}):Play()
    end
end)

--------------------------------------------------------------------------------
-- EVENT CLICK HANDLERS
--------------------------------------------------------------------------------
AutoHopBtn.MouseButton1Click:Connect(StartAutoHop)

AntiHitGuardsBtn.MouseButton1Click:Connect(function()
    isAntiHitGuardsActive = not isAntiHitGuardsActive
    if isAntiHitGuardsActive then
        AntiHitStatusLabel.Text = "Status: ON"
        AntiHitStatusLabel.TextColor3 = Color3.fromRGB(76, 220, 163)
        AntiHitDot.BackgroundColor3 = Color3.fromRGB(76, 220, 163)
        AntiHitGuardsBtn.BackgroundColor3 = Theme.On
        AntiHitStroke.Color = Theme.OnStroke
    else
        AntiHitStatusLabel.Text = "Status: OFF"
        AntiHitStatusLabel.TextColor3 = Theme.TextMuted
        AntiHitDot.BackgroundColor3 = Theme.TextMuted
        AntiHitGuardsBtn.BackgroundColor3 = Theme.Off
        AntiHitStroke.Color = Theme.OffStroke
    end
end)

InstantTpBtn.MouseButton1Click:Connect(function()
    isInstantTpActive = not isInstantTpActive
    if isInstantTpActive then
        InstantTpStatusLabel.Text = "Status: ON"
        InstantTpStatusLabel.TextColor3 = Color3.fromRGB(76, 220, 163)
        InstantTpDot.BackgroundColor3 = Color3.fromRGB(76, 220, 163)
        InstantTpBtn.BackgroundColor3 = Theme.On
        InstantTpStroke.Color = Theme.OnStroke
    else
        InstantTpStatusLabel.Text = "Status: OFF"
        InstantTpStatusLabel.TextColor3 = Theme.TextMuted
        InstantTpDot.BackgroundColor3 = Theme.TextMuted
        InstantTpBtn.BackgroundColor3 = Theme.Off
        InstantTpStroke.Color = Theme.OffStroke
    end
end)
