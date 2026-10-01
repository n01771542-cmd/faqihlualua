-- AUTO EXECUTE PAS TELEPORT / HOP SERVER
local queue = syn and syn.queue_on_teleport or queue_on_teleport or fluxus and fluxus.queue_on_teleport
if queue then queue('loadstring(game:HttpGet("https://raw.githubusercontent.com/n01771542-cmd/faqihlualua/main/leon4951.lua"))()') end

local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local PlaceId = game.PlaceId
local LocalPlayer = Players.LocalPlayer

if not _G.LeonBlacklist then
    _G.LeonBlacklist = {}
end
_G.LeonBlacklist[game.JobId] = true

local IsSearching = false

-- THEME COLOR PALETTE
local Theme = {
    Background = Color3.fromRGB(7, 10, 17),
    Card = Color3.fromRGB(14, 20, 32),
    Accent = Color3.fromRGB(37, 120, 255),
    AccentLight = Color3.fromRGB(82, 151, 255),
    Text = Color3.fromRGB(245, 247, 255),
    TextMuted = Color3.fromRGB(88, 100, 123),
    Border = Color3.fromRGB(34, 48, 73),
    Off = Color3.fromRGB(20, 27, 40),
    OffStroke = Color3.fromRGB(50, 64, 88),
}

-- UI SETUP
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

local MAIN_WIDTH = 180
local MAIN_HEIGHT = 80

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.fromOffset(MAIN_WIDTH, MAIN_HEIGHT)
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

-- LOGO ICON
local LogoHolder = Instance.new("Frame")
LogoHolder.Size = UDim2.fromOffset(18, 18)
LogoHolder.Position = UDim2.fromOffset(8, 6)
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

-- TITLE
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -34, 0, 15)
Title.Position = UDim2.fromOffset(32, 2)
Title.BackgroundTransparency = 1
Title.RichText = true
Title.Text = 'leon4951 <font color="rgb(65,135,255)">Hub</font>'
Title.TextColor3 = Theme.Text
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- SUBTITLE
local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1, -34, 0, 10)
Subtitle.Position = UDim2.fromOffset(32, 16)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "SERVER HOPPER"
Subtitle.TextColor3 = Theme.TextMuted
Subtitle.Font = Enum.Font.GothamMedium
Subtitle.TextSize = 6.5
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

-- MAIN BUTTON
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
StatusLabel.Text = "Status: Idle (1-2 Players)"
StatusLabel.TextColor3 = Theme.TextMuted
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.TextSize = 7
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = AutoHopBtn

--------------------------------------------------------------------------------
-- LOGIKA TELEPORTATION
--------------------------------------------------------------------------------
local function RequestAPI(options)
    local req = request or http_request or (syn and syn.request) or (http and http.request)
    if req then return req(options) end
    return nil
end

local function FindLowestTailServer()
    local cursor = ""
    local pages = {}

    for page = 1, 8 do
        local url = string.format("https://games.roblox.com/v1/games/%d/servers/0?sortOrder=Asc&limit=100", PlaceId)
        if cursor ~= "" then url = url .. "&cursor=" .. cursor end

        local res = RequestAPI({Url = url, Method = "GET"})
        if res and res.Body then
            local decoded = HttpService:JSONDecode(res.Body)
            if decoded and decoded.data then
                table.insert(pages, decoded.data)
                cursor = decoded.nextPageCursor or ""
                if cursor == "" then break end
            else break end
        else break end
    end

    for p = #pages, 1, -1 do
        local currentList = pages[p]
        for b = #currentList, 1, -1 do
            local server = currentList[b]
            local playing = server.playing or 0
            local maxPlayers = server.maxPlayers or 0

            if server.id 
               and not _G.LeonBlacklist[server.id] 
               and (playing == 1 or playing == 2) 
               and (maxPlayers - playing) >= 2 then
                
                return server.id, playing
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
        StatusLabel.Text = "Status: Idle (1-2 Players)"
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
            StatusLabel.Text = string.format("Scanning tail... (#%d)", attempt)
            
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

AutoHopBtn.MouseButton1Click:Connect(StartAutoHop)
