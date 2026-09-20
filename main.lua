-- ============================================================================
-- LEON4951 HUB v2 - SIDEBAR KATEGORI + FILTER SYSTEM + ELEGANT INFO ALL SCRIPT
-- ============================================================================

-- [ PRE-INITIALIZATION CLEANUP ]
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function DestroyOldUI(name)
    local old = CoreGui:FindFirstChild(name) or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild(name))
    if old then
        pcall(function() old:Destroy() end)
    end
end

DestroyOldUI("leon4951HubGuiV2")

-- [ 1. SERVICES ]
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- [ 2. CONFIGURASI & THEME ]
local Theme = {
    Background = Color3.fromRGB(11, 14, 21),
    CardBg = Color3.fromRGB(18, 24, 43),
    CardBgHover = Color3.fromRGB(26, 36, 64),
    AccentBlue = Color3.fromRGB(37, 120, 255),
    BadgeBg = Color3.fromRGB(18, 24, 43),
    BadgeBorder = Color3.fromRGB(34, 50, 86),
    RunPillBg = Color3.fromRGB(34, 50, 86),
    TextPrimary = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(140, 155, 180),
    TextMuted = Color3.fromRGB(107, 114, 128),
    BorderColor = Color3.fromRGB(28, 36, 52),
    GoldBadge = Color3.fromRGB(255, 185, 0),
    KeyTagBg = Color3.fromRGB(220, 53, 69),
    NoKeyTagBg = Color3.fromRGB(40, 167, 69),
    WaGreen = Color3.fromRGB(37, 211, 102),
    WaDarkGreen = Color3.fromRGB(18, 38, 28)
}

local WA_CHANNEL_LINK = "https://whatsapp.com/channel/0029VbDq74VHgZWbi0AdSa1L"

-- [ PRIVATE ARCHITECTURE LOADER CONFIG ]
-- TODO: Sambungkan ke private endpoint/server Anda 
local ScriptDataStealAnEgg = {
    { name = "PAYOMBOYZ", status = "No Key", recommended = false, url = "https://raw.githubusercontent.com/payomboyz333/Anime-Card-Farm/refs/heads/main/start.txt" },
    { name = "OTC", status = "No Key", recommended = false, url = "https://raw.githubusercontent.com/Aerlro/OTC/refs/heads/main/Steal%20an%20Egg/main.lua" },
    { name = "AKIPOX", status = "No Key", recommended = false, url = "https://raw.githubusercontent.com/akipox/Roblox/main/Mods/Games/StealanEgg.lua" },
    { name = "MENGHUB", status = "Key", recommended = false, url = "https://raw.githubusercontent.com/GrexXMeng/Mengs/refs/heads/main/StealAnEgg.lua" },
    { name = "MY HUB", status = "Key", recommended = false, url = "https://raw.githubusercontent.com/pespapankon-del/MyHub/main/Games/StealAnEgg.lua" },
    { name = "TUROK JAPAN HUB", status = "No Key", recommended = false, url = "https://raw.githubusercontent.com/lvjunling/r-s-zh/refs/heads/main/stealegg/lua_zh_mobile.lua" },
    { name = "FROST", status = "Key", recommended = false, url = "https://raw.githubusercontent.com/Frost-GG-Hud/Loader/main/src/Loader.luau" },
    { name = "SOLARIS", status = "Key", recommended = false, url = "https://api.obscuravm.com/scripts/1231452106622100334" },
    { name = "SEISEN V1", status = "Key", recommended = false, url = "https://api.jnkie.com/api/v1/luascripts/public/8ac2e97282ac0718aeeb3bb3856a2821d71dc9e57553690ab508ebdb0d1569da/download" },
    { name = "SELUX", status = "Key", recommended = false, url = "https://raw.githubusercontent.com/seltonmt012/sel01-rbx/main/loader.lua" },
    { name = "SYSCALL", status = "No Key", recommended = false, url = "https://raw.githubusercontent.com/enzukaix/Syscall/refs/heads/main/Loader.lua" },
    { name = "RBXZ HUB", status = "Key", recommended = false, url = "https://rbxscriptz.fun/RBXZ-HUB" },
    { name = "SEISEN V2", status = "No Key", recommended = false, url = "https://raw.githubusercontent.com/Mentos4/roblox/refs/heads/main/Script/Steal%20an%20Egg" },
    { name = "VOID SHELL HUB", status = "No Key", recommended = false, url = "https://raw.githubusercontent.com/VoidShell-null/VoidShell-Hub/refs/heads/main/Scripts/StealAnEgg.luau" },
    { name = "NOYCHOX", status = "No Key", recommended = false, url = "https://raw.githubusercontent.com/yNopaak/STEAL-AN-EGG-NOYCHOX/main/main.lua" },
    { name = "PELATICO", status = "No Key", recommended = false, url = "https://raw.githubusercontent.com/PELATICO/steal-an-egg-hub/main/main.lua" },
    { name = "XENON BYTE", status = "No Key", recommended = false, url = "https://raw.githubusercontent.com/fivetagz-prog/xenon-byte-steal-an-egg-script/refs/heads/main/xenon-byte-sac.lua" },
    { name = "VORTEX X SAGE", status = "No Key", recommended = false, url = "https://raw.githubusercontent.com/Israel-Vortex/vortex-x-scripts/refs/heads/main/Official-Vortex-Software/Dev-Project/StealAnEgg.lua" },
    { name = "PHUCMAX VIET", status = "No Key", recommended = false, url = "https://raw.githubusercontent.com/phucmax/THANHPHUC/refs/heads/main/PHUCMAX(2).lua" },
    { name = "DRAGON SECURITY HUB V2.5", status = "No Key", recommended = false, url = "https://raw.githubusercontent.com/conmemaynguhsjs/scrip/refs/heads/main/gemini-code-1789308407861.lua.txt" }
}

-- Deduplikasi jika FULL URL persis sama
local CleanedScripts = {}
local DuplicateTracker = {}
for _, s in ipairs(ScriptDataStealAnEgg) do
    local identifier = s.url
    if not DuplicateTracker[identifier] then
        DuplicateTracker[identifier] = true
        table.insert(CleanedScripts, s)
    end
end

-- [ SYSTEM CONFIG FAVORITE ]
local FavoriteConfigName = "leon4951hub_favorites.json"
local FavoriteList = {}

local function LoadFavorites()
    if readfile and pcall(readfile, FavoriteConfigName) then
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(FavoriteConfigName))
        end)
        if success and type(decoded) == "table" then
            FavoriteList = decoded
        end
    end
end

local function SaveFavorites()
    if writefile then
        pcall(function()
            writefile(FavoriteConfigName, HttpService:JSONEncode(FavoriteList))
        end)
    end
end

LoadFavorites()

local FavoriteScriptsData = {}
local function RefreshFavoritesData()
    FavoriteScriptsData = {}
    for _, s in ipairs(CleanedScripts) do
        local id = s.name .. "|" .. s.url
        if FavoriteList[id] then
            table.insert(FavoriteScriptsData, s)
        end
    end
end
RefreshFavoritesData()
-- [ CUSTOM SCRIPT DATABASE ]
local CustomScriptsData = {}

local function AddCustomScript(name, url, status)
    name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    url = tostring(url or ""):gsub("^%s+", ""):gsub("%s+$", "")
    status = status or "No Key"

    if name == "" or url == "" then
        return false, "Nama atau URL kosong"
    end

    for _, scriptData in ipairs(CustomScriptsData) do
        if scriptData.url == url then
            return false, "Script dengan URL tersebut sudah ada"
        end
    end

    table.insert(CustomScriptsData, {
        name = name,
        url = url,
        status = status,
    })

    return true
end

local function RemoveCustomScript(index)
    if CustomScriptsData[index] then
        table.remove(CustomScriptsData, index)
    end
end
local Categories = {
    {
        key = "StealAnEgg",
        name = "steal an egg",
        type = "script_list",
        scripts = CleanedScripts,
    },
    {
        key = "Favorite",
        name = "favorite",
        type = "script_list",
        scripts = FavoriteScriptsData,
    },
    {
        key = "InfoAllScript",
        name = "info/all script",
        type = "info",
        scripts = CleanedScripts,
    },
    {
        key = "CustomScript",
        name = "script milik mu",
        type = "custom_script",
        scripts = CustomScriptsData,
    },
    {
        key = "NewScript",
        name = "new script",
        type = "new_script",
        scripts = NewScriptsData,
        hasNotification = true,
    },
}

local activeCategoryIndex = 1
local activeFilter = "ALL"

-- [ 4. ROOT UI ]
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "leon4951HubGuiV2"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.fromOffset(620, 380)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.fromScale(0.5, 0.5)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = false
MainFrame.Active = true
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Theme.BorderColor
MainStroke.Thickness = 1
MainStroke.Parent = MainFrame

local MainScale = Instance.new("UIScale")
MainScale.Scale = 0
MainScale.Parent = MainFrame

-- [ 5. LOGO VEKTOR "F" ]
local function CreateFLogo(size, rotation)
    local container = Instance.new("Frame")
    container.Size = size
    container.BackgroundTransparency = 1
    container.Rotation = rotation or -12

    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, math.floor(size.Y.Offset * 0.28))
    topBar.BackgroundColor3 = Theme.AccentBlue
    topBar.BorderSizePixel = 0
    topBar.Parent = container
    Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 2)

    local midBar = Instance.new("Frame")
    midBar.Size = UDim2.new(0.68, 0, 0, math.floor(size.Y.Offset * 0.24))
    midBar.Position = UDim2.new(0.2, 0, 0.4, 0)
    midBar.BackgroundColor3 = Theme.AccentBlue
    midBar.BorderSizePixel = 0
    midBar.Parent = container
    Instance.new("UICorner", midBar).CornerRadius = UDim.new(0, 2)

    local stem = Instance.new("Frame")
    stem.Size = UDim2.new(0, math.floor(size.X.Offset * 0.28), 1, 0)
    stem.Position = UDim2.new(0.08, 0, 0, 0)
    stem.BackgroundColor3 = Theme.AccentBlue
    stem.BorderSizePixel = 0
    stem.Parent = container
    Instance.new("UICorner", stem).CornerRadius = UDim.new(0, 2)

    return container
end

-- [ 6. HEADER ]
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 46)
Header.BackgroundTransparency = 1
Header.Active = true
Header.Parent = MainFrame

local LogoF = CreateFLogo(UDim2.fromOffset(18, 18), -12)
LogoF.Position = UDim2.new(0, 14, 0, 10)
LogoF.Parent = Header

local Badge = Instance.new("TextLabel")
Badge.Name = "Badge"
Badge.Font = Enum.Font.GothamBold
Badge.TextSize = 9
Badge.TextColor3 = Color3.fromRGB(111, 168, 255)
Badge.BackgroundColor3 = Theme.BadgeBg
Badge.Size = UDim2.fromOffset(120, 18)
Badge.Position = UDim2.new(0, 40, 0, 26)
Badge.Text = "script steal an egg"
Badge.TextXAlignment = Enum.TextXAlignment.Center
Badge.Parent = Header

Instance.new("UICorner", Badge).CornerRadius = UDim.new(1, 0)
local BadgeStroke = Instance.new("UIStroke")
BadgeStroke.Color = Theme.BadgeBorder
BadgeStroke.Thickness = 1
BadgeStroke.Parent = Badge

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextColor3 = Theme.TextPrimary
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(0, 125, 0, 18)
Title.Position = UDim2.new(0, 40, 0, 6)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.RichText = true
Title.Text = "leon4951 <font color=\"rgb(37, 120, 255)\">Hub</font>"
Title.Parent = Header

local WaBtn = Instance.new("TextButton")
WaBtn.Name = "WaChannelBtn"
WaBtn.Size = UDim2.fromOffset(175, 26)
WaBtn.Position = UDim2.new(0, 172, 0, 10)
WaBtn.BackgroundColor3 = Theme.WaGreen
WaBtn.Text = "💬 LINK SALURAN WA (COPY)"
WaBtn.Font = Enum.Font.GothamBold
WaBtn.TextSize = 9
WaBtn.TextColor3 = Theme.TextPrimary
WaBtn.AutoButtonColor = false
WaBtn.Parent = Header

Instance.new("UICorner", WaBtn).CornerRadius = UDim.new(0, 6)

local WaStroke = Instance.new("UIStroke")
WaStroke.Color = Theme.WaDarkGreen
WaStroke.Thickness = 1.5
WaStroke.Parent = WaBtn

local WaTextStroke = Instance.new("UIStroke")
WaTextStroke.Color = Color3.fromRGB(0, 0, 0)
WaTextStroke.Thickness = 1.2
WaTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
WaTextStroke.Parent = WaBtn

WaBtn.MouseEnter:Connect(function()
    TweenService:Create(WaBtn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.WaDarkGreen }):Play()
end)

WaBtn.MouseLeave:Connect(function()
    TweenService:Create(WaBtn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.WaGreen }):Play()
end)

WaBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(WA_CHANNEL_LINK)
    elseif toclipboard then
        toclipboard(WA_CHANNEL_LINK)
    end
    
    local origText = WaBtn.Text
    WaBtn.Text = "✓ COPIED!"
    task.delay(1.5, function()
        if WaBtn and WaBtn.Parent then
            WaBtn.Text = origText
        end
    end)
end)

local ControlContainer = Instance.new("Frame")
ControlContainer.Size = UDim2.fromOffset(56, 24)
ControlContainer.Position = UDim2.new(1, -66, 0, 10)
ControlContainer.BackgroundTransparency = 1
ControlContainer.Parent = Header

local ControlLayout = Instance.new("UIListLayout")
ControlLayout.FillDirection = Enum.FillDirection.Horizontal
ControlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
ControlLayout.VerticalAlignment = Enum.VerticalAlignment.Center
ControlLayout.Padding = UDim.new(0, 6)
ControlLayout.Parent = ControlContainer

local function CreateHeaderButton(iconText, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(24, 24)
    btn.BackgroundColor3 = Theme.CardBg
    btn.Text = iconText
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 15
    btn.TextColor3 = Theme.TextPrimary
    btn.AutoButtonColor = false
    btn.Parent = ControlContainer
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.AccentBlue }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.CardBg }):Play()
    end)

    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- [ 7. BODY: SIDEBAR + KONTEN ]
local Body = Instance.new("Frame")
Body.Name = "Body"
Body.Size = UDim2.new(1, -24, 1, -54)
Body.Position = UDim2.new(0, 12, 0, 48)
Body.BackgroundTransparency = 1
Body.Parent = MainFrame

local Sidebar = Instance.new("ScrollingFrame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 128, 1, 0)
Sidebar.BackgroundTransparency = 1
Sidebar.BorderSizePixel = 0
Sidebar.ScrollBarThickness = 2
Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
Sidebar.Parent = Body

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.Padding = UDim.new(0, 6)
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Parent = Sidebar

local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -136, 1, 0)
Content.Position = UDim2.new(0, 136, 0, 0)
Content.BackgroundTransparency = 1
Content.Parent = Body

local ContentHeader = Instance.new("Frame")
ContentHeader.Size = UDim2.new(1, 0, 0, 68)
ContentHeader.BackgroundTransparency = 1
ContentHeader.Parent = Content

local ContentLabel = Instance.new("TextLabel")
ContentLabel.Font = Enum.Font.GothamBold
ContentLabel.TextSize = 9
ContentLabel.TextColor3 = Theme.TextMuted
ContentLabel.BackgroundTransparency = 1
ContentLabel.Size = UDim2.new(1, 0, 0, 12)
ContentLabel.Position = UDim2.new(0, 0, 0, 0)
ContentLabel.TextXAlignment = Enum.TextXAlignment.Left
ContentLabel.Text = "STEAL AN EGG -- SCRIPTS"
ContentLabel.Parent = ContentHeader

local FilterContainer = Instance.new("Frame")
FilterContainer.Size = UDim2.new(1, 0, 0, 24)
FilterContainer.Position = UDim2.new(0, 0, 0, 16)
FilterContainer.BackgroundTransparency = 1
FilterContainer.Parent = ContentHeader

local FilterLayout = Instance.new("UIListLayout")
FilterLayout.FillDirection = Enum.FillDirection.Horizontal
FilterLayout.Padding = UDim.new(0, 4)
FilterLayout.SortOrder = Enum.SortOrder.LayoutOrder
FilterLayout.Parent = FilterContainer

local filterButtons = {}

local SearchBox = Instance.new("TextBox")
SearchBox.Name = "SearchBox"
SearchBox.Size = UDim2.new(1, 0, 0, 24)
SearchBox.Position = UDim2.new(0, 0, 0, 44)
SearchBox.BackgroundColor3 = Theme.CardBg
SearchBox.PlaceholderText = "🔍 Cari nama script..."
SearchBox.PlaceholderColor3 = Theme.TextMuted
SearchBox.Text = ""
SearchBox.TextColor3 = Theme.TextPrimary
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 10
SearchBox.Parent = ContentHeader
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 5)

local SearchStroke = Instance.new("UIStroke")
SearchStroke.Color = Theme.BorderColor
SearchStroke.Thickness = 1
SearchStroke.Parent = SearchBox

local ScriptScroll = Instance.new("ScrollingFrame")
ScriptScroll.Size = UDim2.new(1, 0, 1, -72)
ScriptScroll.Position = UDim2.new(0, 0, 0, 72)
ScriptScroll.BackgroundTransparency = 1
ScriptScroll.BorderSizePixel = 0
ScriptScroll.ScrollBarThickness = 3
ScriptScroll.ScrollBarImageColor3 = Theme.AccentBlue
ScriptScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ScriptScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScriptScroll.Parent = Content

local RenderSidebarTabs

-- [ 8. RENDER KONTEN ]
local function RenderContent(categoryIndex)
    local category = Categories[categoryIndex]
    
    for _, child in ipairs(ScriptScroll:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIGridLayout") then
            child:Destroy()
        end
    end

    local oldLayout = ScriptScroll:FindFirstChildOfClass("UIListLayout") or ScriptScroll:FindFirstChildOfClass("UIGridLayout")
    if oldLayout then oldLayout:Destroy() end

    if category.type == "custom_script" then
    FilterContainer.Visible = false
    SearchBox.Visible = false
    ContentLabel.Text = "SCRIPT MILIK MU -- CUSTOM COLLECTION"

    local CustomContainer = Instance.new("Frame")
    CustomContainer.Name = "CustomContainer"
    CustomContainer.Size = UDim2.new(1, 0, 0, 115)
    CustomContainer.BackgroundColor3 = Theme.CardBg
    CustomContainer.BorderSizePixel = 0
    CustomContainer.Parent = ScriptScroll

    Instance.new("UICorner", CustomContainer).CornerRadius = UDim.new(0, 8)

    local CustomStroke = Instance.new("UIStroke")
    CustomStroke.Color = Theme.BorderColor
    CustomStroke.Thickness = 1
    CustomStroke.Parent = CustomContainer

    local NameBox = Instance.new("TextBox")
    NameBox.Name = "NameBox"
    NameBox.Size = UDim2.new(1, -20, 0, 28)
    NameBox.Position = UDim2.new(0, 10, 0, 10)
    NameBox.BackgroundColor3 = Theme.Background
    NameBox.BorderSizePixel = 0
    NameBox.PlaceholderText = "Nama Script"
    NameBox.Text = ""
    NameBox.TextColor3 = Theme.TextPrimary
    NameBox.PlaceholderColor3 = Theme.TextSecondary
    NameBox.Font = Enum.Font.Gotham
    NameBox.TextSize = 11
    NameBox.ClearTextOnFocus = false
    NameBox.Parent = CustomContainer

    Instance.new("UICorner", NameBox).CornerRadius = UDim.new(0, 6)

    local UrlBox = Instance.new("TextBox")
    UrlBox.Name = "UrlBox"
    UrlBox.Size = UDim2.new(1, -20, 0, 28)
    UrlBox.Position = UDim2.new(0, 10, 0, 44)
    UrlBox.BackgroundColor3 = Theme.Background
    UrlBox.BorderSizePixel = 0
    UrlBox.PlaceholderText = "Loadstring URL"
    UrlBox.Text = ""
    UrlBox.TextColor3 = Theme.TextPrimary
    UrlBox.PlaceholderColor3 = Theme.TextSecondary
    UrlBox.Font = Enum.Font.Gotham
    UrlBox.TextSize = 11
    UrlBox.ClearTextOnFocus = false
    UrlBox.Parent = CustomContainer

    Instance.new("UICorner", UrlBox).CornerRadius = UDim.new(0, 6)

    local StatusBox = Instance.new("TextButton")
    StatusBox.Name = "StatusBox"
    StatusBox.Size = UDim2.fromOffset(80, 28)
    StatusBox.Position = UDim2.new(0, 10, 0, 78)
    StatusBox.BackgroundColor3 = Theme.Background
    StatusBox.BorderSizePixel = 0
    StatusBox.Text = "No Key"
    StatusBox.TextColor3 = Theme.TextPrimary
    StatusBox.Font = Enum.Font.GothamBold
    StatusBox.TextSize = 10
    StatusBox.AutoButtonColor = false
    StatusBox.Parent = CustomContainer

    Instance.new("UICorner", StatusBox).CornerRadius = UDim.new(0, 6)

    local currentStatus = "No Key"

    StatusBox.MouseButton1Click:Connect(function()
        if currentStatus == "No Key" then
            currentStatus = "Key"
        else
            currentStatus = "No Key"
        end

        StatusBox.Text = currentStatus
    end)

    local AddBtn = Instance.new("TextButton")
    AddBtn.Name = "AddButton"
    AddBtn.Size = UDim2.new(1, -100, 0, 28)
    AddBtn.Position = UDim2.new(0, 100, 0, 78)
    AddBtn.BackgroundColor3 = Theme.AccentBlue
    AddBtn.BorderSizePixel = 0
    AddBtn.Text = "+ TAMBAH SCRIPT"
    AddBtn.TextColor3 = Theme.TextPrimary
    AddBtn.Font = Enum.Font.GothamBold
    AddBtn.TextSize = 10
    AddBtn.AutoButtonColor = false
    AddBtn.Parent = CustomContainer

    Instance.new("UICorner", AddBtn).CornerRadius = UDim.new(0, 6)

local function ExecuteCustomScript(scriptData, executeButton)
    executeButton.Text = "LOADING..."

    task.spawn(function()
        local success, result = pcall(function()
            local source = game:HttpGet(scriptData.url)

            local compiled, compileError = loadstring(source)

            if not compiled then
                error(compileError or "Gagal compile script")
            end

            local executed, executeError = pcall(compiled)

            if not executed then
                error(executeError or "Gagal menjalankan script")
            end

            return true
        end)

        if success then
            executeButton.Text = "EXECUTE"
        else
            executeButton.Text = "ERROR"
            warn("[LEON4951 HUB] " .. tostring(result))

            task.wait(2)

            if executeButton and executeButton.Parent then
                executeButton.Text = "EXECUTE"
            end
        end
    end)
end

    local function RenderCustomScripts()
        for _, child in ipairs(ScriptScroll:GetChildren()) do
            if child.Name == "CustomScriptCard" then
                child:Destroy()
            end
        end

        for index, scriptData in ipairs(CustomScriptsData) do
            local Card = Instance.new("Frame")
            Card.Name = "CustomScriptCard"
            Card.Size = UDim2.new(1, 0, 0, 54)
            Card.BackgroundColor3 = Theme.CardBg
            Card.BorderSizePixel = 0
            Card.LayoutOrder = index + 1
            Card.Parent = ScriptScroll

            Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 8)

            local CardStroke = Instance.new("UIStroke")
            CardStroke.Color = Theme.BorderColor
            CardStroke.Thickness = 1
            CardStroke.Parent = Card

            local ScriptName = Instance.new("TextLabel")
            ScriptName.Size = UDim2.new(1, -210, 0, 24)
            ScriptName.Position = UDim2.new(0, 10, 0, 5)
            ScriptName.BackgroundTransparency = 1
            ScriptName.Text = scriptData.name
            ScriptName.TextColor3 = Theme.TextPrimary
            ScriptName.Font = Enum.Font.GothamBold
            ScriptName.TextSize = 11
            ScriptName.TextXAlignment = Enum.TextXAlignment.Left
            ScriptName.TextTruncate = Enum.TextTruncate.AtEnd
            ScriptName.Parent = Card

            local StatusLabel = Instance.new("TextLabel")
            StatusLabel.Size = UDim2.new(1, -210, 0, 18)
            StatusLabel.Position = UDim2.new(0, 10, 0, 29)
            StatusLabel.BackgroundTransparency = 1
            StatusLabel.Text = scriptData.status
            StatusLabel.TextColor3 = Theme.TextSecondary
            StatusLabel.Font = Enum.Font.Gotham
            StatusLabel.TextSize = 9
            StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
            StatusLabel.Parent = Card

            local ExecuteButton = Instance.new("TextButton")
            ExecuteButton.Size = UDim2.fromOffset(80, 32)
            ExecuteButton.Position = UDim2.new(1, -170, 0.5, -16)
            ExecuteButton.BackgroundColor3 = Theme.AccentBlue
            ExecuteButton.BorderSizePixel = 0
            ExecuteButton.Text = "EXECUTE"
            ExecuteButton.TextColor3 = Theme.TextPrimary
            ExecuteButton.Font = Enum.Font.GothamBold
            ExecuteButton.TextSize = 9
            ExecuteButton.AutoButtonColor = false
            ExecuteButton.Parent = Card

            Instance.new("UICorner", ExecuteButton).CornerRadius = UDim.new(0, 6)

            ExecuteButton.MouseButton1Click:Connect(function()
                ExecuteCustomScript(scriptData, ExecuteButton)
            end)

            local DeleteButton = Instance.new("TextButton")
            DeleteButton.Size = UDim2.fromOffset(32, 32)
            DeleteButton.Position = UDim2.new(1, -45, 0.5, -16)
            DeleteButton.BackgroundColor3 = Theme.Background
            DeleteButton.BorderSizePixel = 0
            DeleteButton.Text = "X"
            DeleteButton.TextColor3 = Theme.TextPrimary
            DeleteButton.Font = Enum.Font.GothamBold
            DeleteButton.TextSize = 10
            DeleteButton.AutoButtonColor = false
            DeleteButton.Parent = Card

            Instance.new("UICorner", DeleteButton).CornerRadius = UDim.new(0, 6)

            DeleteButton.MouseButton1Click:Connect(function()
                RemoveCustomScript(index)
                RenderCustomScripts()
            end)
        end
    end

    AddBtn.MouseButton1Click:Connect(function()
        local success, errorMessage = AddCustomScript(
            NameBox.Text,
            UrlBox.Text,
            currentStatus
        )

        if success then
            NameBox.Text = ""
            UrlBox.Text = ""
            currentStatus = "No Key"
            StatusBox.Text = "No Key"

            RenderCustomScripts()
        else
            warn("[LEON4951 HUB] " .. tostring(errorMessage))
        end
    end)

    RenderCustomScripts()
    ScriptScroll.CanvasPosition = Vector2.new(0, 0)

    return

elseif category.type == "info" then
        FilterContainer.Visible = false
        SearchBox.Visible = false
        ContentLabel.Text = "ALL SCRIPTS DATABASE -- OVERVIEW"

        local ListLayout = Instance.new("UIListLayout")
        ListLayout.Padding = UDim.new(0, 10)
        ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ListLayout.Parent = ScriptScroll

        local totalCount = #category.scripts
        local keyCount = 0
        local noKeyCount = 0

        for _, s in ipairs(category.scripts) do
            if s.status == "Key" then keyCount = keyCount + 1 else noKeyCount = noKeyCount + 1 end
        end

        local StatsBanner = Instance.new("Frame")
        StatsBanner.Name = "StatsBanner"
        StatsBanner.Size = UDim2.new(1, 0, 0, 36)
        StatsBanner.BackgroundColor3 = Theme.CardBg
        StatsBanner.LayoutOrder = 1
        StatsBanner.Parent = ScriptScroll
        Instance.new("UICorner", StatsBanner).CornerRadius = UDim.new(0, 6)

        local BannerStroke = Instance.new("UIStroke")
        BannerStroke.Color = Theme.BorderColor
        BannerStroke.Thickness = 1
        BannerStroke.Parent = StatsBanner

        local StatsText = Instance.new("TextLabel")
        StatsText.Font = Enum.Font.GothamBold
        StatsText.TextSize = 10
        StatsText.TextColor3 = Theme.TextSecondary
        StatsText.BackgroundTransparency = 1
        StatsText.Size = UDim2.new(1, -20, 1, 0)
        StatsText.Position = UDim2.new(0, 10, 0, 0)
        StatsText.TextXAlignment = Enum.TextXAlignment.Left
        StatsText.RichText = true
        StatsText.Text = "📊 <font color=\"rgb(255, 255, 255)\">TOTAL SCRIPT:</font> " .. totalCount .. "   |   <font color=\"rgb(220, 53, 69)\">🔑 KEY:</font> " .. keyCount .. "   |   <font color=\"rgb(40, 167, 69)\">🔓 NO KEY:</font> " .. noKeyCount
        StatsText.Parent = StatsBanner

        local GridContainer = Instance.new("Frame")
        GridContainer.Name = "GridContainer"
        GridContainer.Size = UDim2.new(1, 0, 0, 0)
        GridContainer.AutomaticSize = Enum.AutomaticSize.Y
        GridContainer.BackgroundTransparency = 1
        GridContainer.LayoutOrder = 2
        GridContainer.Parent = ScriptScroll

        local GridLayout = Instance.new("UIGridLayout")
        GridLayout.CellSize = UDim2.new(0, 142, 0, 32)
        GridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
        GridLayout.SortOrder = Enum.SortOrder.LayoutOrder
        GridLayout.Parent = GridContainer

        for idx, scriptEntry in ipairs(category.scripts) do
            local card = Instance.new("Frame")
            card.Name = "Card_" .. idx
            card.BackgroundColor3 = Theme.CardBg
            card.Parent = GridContainer
            Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

            local cardStroke = Instance.new("UIStroke")
            cardStroke.Color = Theme.BorderColor
            cardStroke.Thickness = 1
            cardStroke.Parent = card

            local indicator = Instance.new("Frame")
            indicator.Size = UDim2.new(0, 3, 0, 16)
            indicator.Position = UDim2.new(0, 6, 0.5, -8)
            indicator.BackgroundColor3 = (scriptEntry.status == "Key") and Theme.KeyTagBg or Theme.NoKeyTagBg
            indicator.BorderSizePixel = 0
            indicator.Parent = card
            Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Font = Enum.Font.GothamBold
            nameLbl.TextSize = 10
            nameLbl.TextColor3 = Theme.TextPrimary
            nameLbl.BackgroundTransparency = 1
            nameLbl.Size = UDim2.new(1, -16, 1, 0)
            nameLbl.Position = UDim2.new(0, 14, 0, 0)
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            nameLbl.Text = scriptEntry.name
            nameLbl.Parent = card
        end

        ScriptScroll.CanvasPosition = Vector2.new(0, 0)
        return

    elseif category.type == "new_script" then
        FilterContainer.Visible = false
        SearchBox.Visible = false
        ContentLabel.Text = "NEW SCRIPTS -- UPDATES"

        local ListLayout = Instance.new("UIListLayout")
        ListLayout.Padding = UDim.new(0, 10)
        ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ListLayout.Parent = ScriptScroll

        if #category.scripts == 0 then
            local emptyCard = Instance.new("Frame")
            emptyCard.Size = UDim2.new(1, 0, 0, 50)
            emptyCard.BackgroundColor3 = Theme.CardBg
            emptyCard.Parent = ScriptScroll
            Instance.new("UICorner", emptyCard).CornerRadius = UDim.new(0, 7)

            local emptyStroke = Instance.new("UIStroke")
            emptyStroke.Color = Theme.BorderColor
            emptyStroke.Thickness = 1
            emptyStroke.Parent = emptyCard

            local emptyLbl = Instance.new("TextLabel")
            emptyLbl.Font = Enum.Font.GothamBold
            emptyLbl.TextSize = 11
            emptyLbl.TextColor3 = Theme.TextMuted
            emptyLbl.BackgroundTransparency = 1
            emptyLbl.Size = UDim2.new(1, 0, 1, 0)
            emptyLbl.TextXAlignment = Enum.TextXAlignment.Center
            emptyLbl.Text = "Belum Ada Script Baru"
            emptyLbl.Parent = emptyCard
        else
            for i, scriptEntry in ipairs(category.scripts) do
                local row = Instance.new("Frame")
                row.Name = "Row_" .. i
                row.Size = UDim2.new(1, 0, 0, 38)
                row.BackgroundColor3 = Theme.CardBg
                row.LayoutOrder = i
                row.Parent = ScriptScroll
                Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

                local nameLabel = Instance.new("TextLabel")
                nameLabel.Font = Enum.Font.GothamBold
                nameLabel.TextSize = 12
                nameLabel.TextColor3 = Theme.TextPrimary
                nameLabel.BackgroundTransparency = 1
                nameLabel.Size = UDim2.new(1, -170, 1, 0)
                nameLabel.Position = UDim2.new(0, 10, 0, 0)
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
                nameLabel.Text = scriptEntry.name
                nameLabel.Parent = row

                local runBtn = Instance.new("TextButton")
                runBtn.Size = UDim2.fromOffset(52, 24)
                runBtn.Position = UDim2.new(1, -58, 0.5, -12)
                runBtn.BackgroundColor3 = Theme.RunPillBg
                runBtn.Text = "run"
                runBtn.Font = Enum.Font.GothamBold
                runBtn.TextSize = 11
                runBtn.TextColor3 = Color3.fromRGB(111, 168, 255)
                runBtn.AutoButtonColor = false
                runBtn.Parent = row
                Instance.new("UICorner", runBtn).CornerRadius = UDim.new(1, 0)

                runBtn.MouseButton1Click:Connect(function()
                    if scriptEntry.url and scriptEntry.url ~= "" then
                        pcall(function()
                            if string.sub(scriptEntry.url, 1, 10) == "loadstring" then
                                loadstring(scriptEntry.url)()
                            else
                                loadstring(game:HttpGet(scriptEntry.url))()
                            end
                        end)
                    end
                end)

                local statusBadge = Instance.new("TextLabel")
                statusBadge.Size = UDim2.fromOffset(58, 20)
                statusBadge.Position = UDim2.new(1, -122, 0.5, -10)
                statusBadge.BackgroundColor3 = (scriptEntry.status == "Key") and Theme.KeyTagBg or Theme.NoKeyTagBg
                statusBadge.Text = scriptEntry.status
                statusBadge.Font = Enum.Font.GothamBold
                statusBadge.TextSize = 11
                statusBadge.TextColor3 = Theme.TextPrimary
                statusBadge.Parent = row
                Instance.new("UICorner", statusBadge).CornerRadius = UDim.new(0, 4)

                local favBtn = Instance.new("TextButton")
                favBtn.Size = UDim2.fromOffset(24, 24)
                favBtn.Position = UDim2.new(1, -152, 0.5, -12)
                favBtn.BackgroundColor3 = Theme.RunPillBg
                local fKeyId = scriptEntry.name .. "|" .. scriptEntry.url
                favBtn.Text = FavoriteList[fKeyId] and "★" or "☆"
                favBtn.Font = Enum.Font.GothamBold
                favBtn.TextSize = 14
                favBtn.TextColor3 = FavoriteList[fKeyId] and Theme.GoldBadge or Theme.TextSecondary
                favBtn.AutoButtonColor = false
                favBtn.Parent = row
                Instance.new("UICorner", favBtn).CornerRadius = UDim.new(0, 4)

                favBtn.MouseButton1Click:Connect(function()
                    if FavoriteList[fKeyId] then
                        FavoriteList[fKeyId] = nil
                        favBtn.Text = "☆"
                        favBtn.TextColor3 = Theme.TextSecondary
                    else
                        FavoriteList[fKeyId] = true
                        favBtn.Text = "★"
                        favBtn.TextColor3 = Theme.GoldBadge
                    end
                    SaveFavorites()
                    RefreshFavoritesData()
                end)
            end
        end

        ScriptScroll.CanvasPosition = Vector2.new(0, 0)
        return
    end

    FilterContainer.Visible = true
    SearchBox.Visible = true

    local ListLayout = Instance.new("UIListLayout")
    ListLayout.Padding = UDim.new(0, 6)
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Parent = ScriptScroll

    local searchText = string.lower(SearchBox.Text)
    local filteredScripts = {}

    for _, scriptEntry in ipairs(category.scripts) do
        local matchesFilter = false
        if activeFilter == "ALL" then
            matchesFilter = true
        elseif activeFilter == "Key" then
            matchesFilter = (scriptEntry.status == "Key")
        elseif activeFilter == "No Key" then
            matchesFilter = (scriptEntry.status == "No Key")
        elseif activeFilter == "Recommended" then
            matchesFilter = (scriptEntry.recommended == true)
        end

        local matchesSearch = (searchText == "") or (string.find(string.lower(scriptEntry.name), searchText, 1, true) ~= nil)
        
        if matchesFilter and matchesSearch then
            table.insert(filteredScripts, scriptEntry)
        end
    end

    local filterTag = ""
    if activeFilter == "Key" then filterTag = " KEY"
    elseif activeFilter == "No Key" then filterTag = " NO KEY"
    elseif activeFilter == "Recommended" then filterTag = " RECOMMENDED" end
    ContentLabel.Text = string.upper(category.name) .. " -- " .. #filteredScripts .. filterTag .. " SCRIPTS"

    if #filteredScripts == 0 then
        local empty = Instance.new("TextLabel")
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 11
        empty.TextColor3 = Theme.TextMuted
        empty.BackgroundTransparency = 1
        empty.Size = UDim2.new(1, 0, 0, 40)
        empty.Text = "Tidak ada script yang cocok."
        empty.Parent = ScriptScroll
        return
    end

    for i, scriptEntry in ipairs(filteredScripts) do
        local row = Instance.new("Frame")
        row.Name = "Row_" .. i
        row.Size = UDim2.new(1, 0, 0, 38)
        row.BackgroundColor3 = Theme.CardBg
        row.LayoutOrder = i
        row.Parent = ScriptScroll
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 12
        nameLabel.TextColor3 = Theme.TextPrimary
        nameLabel.BackgroundTransparency = 1
        local rightOffsetWidth = scriptEntry.recommended and 250 or 160
        nameLabel.Size = UDim2.new(1, -rightOffsetWidth, 1, 0)
        nameLabel.Position = UDim2.new(0, 10, 0, 0)
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Text = scriptEntry.name
        nameLabel.Parent = row

        local runBtn = Instance.new("TextButton")
        runBtn.Size = UDim2.fromOffset(52, 24)
        runBtn.Position = UDim2.new(1, -58, 0.5, -12)
        runBtn.BackgroundColor3 = Theme.RunPillBg
        runBtn.Text = "run"
        runBtn.Font = Enum.Font.GothamBold
        runBtn.TextSize = 11
        runBtn.TextColor3 = Color3.fromRGB(111, 168, 255)
        runBtn.AutoButtonColor = false
        runBtn.Parent = row
        Instance.new("UICorner", runBtn).CornerRadius = UDim.new(1, 0)

        runBtn.MouseEnter:Connect(function()
            TweenService:Create(runBtn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.AccentBlue }):Play()
        end)
        runBtn.MouseLeave:Connect(function()
            TweenService:Create(runBtn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.RunPillBg }):Play()
        end)

        runBtn.MouseButton1Click:Connect(function()
            if scriptEntry.url and scriptEntry.url ~= "" then
                pcall(function()
                    if string.sub(scriptEntry.url, 1, 10) == "loadstring" or string.find(scriptEntry.url, "script_key") then
                        loadstring(scriptEntry.url)()
                    else
                        loadstring(game:HttpGet(scriptEntry.url))()
                    end
                end)
            end
        end)

        local statusBadge = Instance.new("TextLabel")
        statusBadge.Size = UDim2.fromOffset(58, 20)
        statusBadge.Position = UDim2.new(1, -122, 0.5, -10)
        statusBadge.BackgroundColor3 = (scriptEntry.status == "Key") and Theme.KeyTagBg or Theme.NoKeyTagBg
        statusBadge.Text = scriptEntry.status
        statusBadge.Font = Enum.Font.GothamBold
        statusBadge.TextSize = 11
        statusBadge.TextColor3 = Theme.TextPrimary
        statusBadge.Parent = row
        Instance.new("UICorner", statusBadge).CornerRadius = UDim.new(0, 4)

        local favXPos = -152
        if scriptEntry.recommended then
            local recBadge = Instance.new("TextLabel")
            recBadge.Size = UDim2.fromOffset(92, 18)
            recBadge.Position = UDim2.new(1, -220, 0.5, -9)
            recBadge.BackgroundColor3 = Theme.GoldBadge
            recBadge.Text = "★ RECOMMENDED"
            recBadge.Font = Enum.Font.GothamBold
            recBadge.TextSize = 9
            recBadge.TextColor3 = Color3.fromRGB(0, 0, 0)
            recBadge.Parent = row
            Instance.new("UICorner", recBadge).CornerRadius = UDim.new(0, 4)
            favXPos = -250
        end

        local favBtn = Instance.new("TextButton")
        favBtn.Size = UDim2.fromOffset(24, 24)
        favBtn.Position = UDim2.new(1, favXPos, 0.5, -12)
        favBtn.BackgroundColor3 = Theme.RunPillBg
        local fKeyId = scriptEntry.name .. "|" .. scriptEntry.url
        favBtn.Text = FavoriteList[fKeyId] and "★" or "☆"
        favBtn.Font = Enum.Font.GothamBold
        favBtn.TextSize = 14
        favBtn.TextColor3 = FavoriteList[fKeyId] and Theme.GoldBadge or Theme.TextSecondary
        favBtn.AutoButtonColor = false
        favBtn.Parent = row
        Instance.new("UICorner", favBtn).CornerRadius = UDim.new(0, 4)

        favBtn.MouseButton1Click:Connect(function()
            if FavoriteList[fKeyId] then
                FavoriteList[fKeyId] = nil
                favBtn.Text = "☆"
                favBtn.TextColor3 = Theme.TextSecondary
            else
                FavoriteList[fKeyId] = true
                favBtn.Text = "★"
                favBtn.TextColor3 = Theme.GoldBadge
            end
            SaveFavorites()
            RefreshFavoritesData()
        end)
    end
    
    ScriptScroll.CanvasPosition = Vector2.new(0, 0)
end

-- [ 9. CREATING FILTER TABS ]
local filterDefs = {
    { id = "ALL", text = "ALL" },
    { id = "Key", text = "🔑 KEY" },
    { id = "No Key", text = "🔓 NO KEY" },
    { id = "Recommended", text = "🌟 RECOMEND" }
}

for _, fDef in ipairs(filterDefs) do
    local fBtn = Instance.new("TextButton")
    fBtn.Name = "Filter_" .. fDef.id
    fBtn.Size = UDim2.fromOffset(82, 22)
    fBtn.BackgroundColor3 = (activeFilter == fDef.id) and Theme.AccentBlue or Theme.CardBg
    fBtn.Text = fDef.text
    fBtn.Font = Enum.Font.GothamBold
    fBtn.TextSize = 9
    fBtn.TextColor3 = (activeFilter == fDef.id) and Theme.TextPrimary or Theme.TextSecondary
    fBtn.AutoButtonColor = false
    fBtn.Parent = FilterContainer
    Instance.new("UICorner", fBtn).CornerRadius = UDim.new(0, 5)

    filterButtons[fDef.id] = fBtn

    fBtn.MouseButton1Click:Connect(function()
        activeFilter = fDef.id
        for id, btn in pairs(filterButtons) do
            local isActive = (id == activeFilter)
            TweenService:Create(btn, TweenInfo.new(0.12), {
                BackgroundColor3 = isActive and Theme.AccentBlue or Theme.CardBg
            }):Play()
            btn.TextColor3 = isActive and Theme.TextPrimary or Theme.TextSecondary
        end
        RenderContent(activeCategoryIndex)
    end)
end

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    RenderContent(activeCategoryIndex)
end)

-- [ 10. RENDER TAB SIDEBAR ]
local sidebarTabButtons = {}

local function SetActiveCategory(index)
    activeCategoryIndex = index

    RefreshFavoritesData()
    Categories[2].scripts = FavoriteScriptsData

    for i, btnData in ipairs(sidebarTabButtons) do
        local isActive = (i == index)
        TweenService:Create(btnData.frame, TweenInfo.new(0.15), {
            BackgroundColor3 = isActive and Theme.AccentBlue or Theme.CardBg
        }):Play()
        btnData.label.TextColor3 = isActive and Theme.TextPrimary or Theme.TextSecondary

        if isActive and Categories[i].hasNotification then
            Categories[i].hasNotification = false
            if btnData.notifBadge then
                TweenService:Create(btnData.notifBadge, TweenInfo.new(0.15), { TextTransparency = 1 }):Play()
                task.delay(0.15, function()
                    if btnData.notifBadge then btnData.notifBadge:Destroy() end
                end)
            end
        end
    end

    RenderContent(index)
end

RenderSidebarTabs = function()
    for _, child in ipairs(Sidebar:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
    sidebarTabButtons = {}

    for i, category in ipairs(Categories) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = "Tab_" .. category.key
        tabBtn.Size = UDim2.new(1, 0, 0, 42)
        tabBtn.BackgroundColor3 = (i == activeCategoryIndex) and Theme.AccentBlue or Theme.CardBg
        tabBtn.Text = ""
        tabBtn.AutoButtonColor = false
        tabBtn.LayoutOrder = i
        tabBtn.Parent = Sidebar
        Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 8)

        local dot = Instance.new("Frame")
        dot.Size = UDim2.fromOffset(7, 7)
        dot.Position = UDim2.new(0, 12, 0.5, -3.5)
        dot.BackgroundColor3 = Theme.TextPrimary
        dot.BorderSizePixel = 0
        dot.Parent = tabBtn
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

        local label = Instance.new("TextLabel")
        label.Font = Enum.Font.GothamBold
        label.TextSize = 12
        label.TextColor3 = (i == activeCategoryIndex) and Theme.TextPrimary or Theme.TextSecondary
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, -30, 1, 0)
        label.Position = UDim2.new(0, 26, 0, 0)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextWrapped = true
        label.Text = category.name
        label.Parent = tabBtn

        local notifBadge = nil
        if category.hasNotification then
            notifBadge = Instance.new("TextLabel")
            notifBadge.Name = "NotifBadge"
            notifBadge.Size = UDim2.fromOffset(18, 18)
            notifBadge.AnchorPoint = Vector2.new(1, 0.5)
            notifBadge.Position = UDim2.new(1, -8, 0.5, 0)
            notifBadge.BackgroundColor3 = Theme.KeyTagBg
            notifBadge.Text = "!"
            notifBadge.Font = Enum.Font.GothamBold
            notifBadge.TextSize = 11
            notifBadge.TextColor3 = Theme.TextPrimary
            notifBadge.Parent = tabBtn
            Instance.new("UICorner", notifBadge).CornerRadius = UDim.new(1, 0)

            local notifStroke = Instance.new("UIStroke")
            notifStroke.Color = Theme.TextPrimary
            notifStroke.Thickness = 1
            notifStroke.Parent = notifBadge
        end

        table.insert(sidebarTabButtons, { frame = tabBtn, label = label, notifBadge = notifBadge })

        tabBtn.MouseButton1Click:Connect(function()
            SetActiveCategory(i)
        end)
    end
end

RenderSidebarTabs()
RenderContent(activeCategoryIndex)

-- [ 11. DRAG SYSTEM (HEADER) ]
local isDragging = false
local dragStartPos = Vector3.new()
local startFramePos = UDim2.new()
local currentDragInput = nil

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStartPos = input.Position
        startFramePos = MainFrame.Position
        currentDragInput = input
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input == currentDragInput or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
        currentDragInput = nil
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input == currentDragInput or input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStartPos
        MainFrame.Position = UDim2.new(
            startFramePos.X.Scale,
            startFramePos.X.Offset + delta.X,
            startFramePos.Y.Scale,
            startFramePos.Y.Offset + delta.Y
        )
    end
end)

-- [ 11.5 RESIZE SYSTEM ]
local ResizeHandle = Instance.new("TextButton")
ResizeHandle.Name = "ResizeHandle"
ResizeHandle.Size = UDim2.fromOffset(20, 20)
ResizeHandle.AnchorPoint = Vector2.new(1, 1)
ResizeHandle.Position = UDim2.new(1, 0, 1, 0)
ResizeHandle.BackgroundColor3 = Theme.AccentBlue
ResizeHandle.Text = "◢"
ResizeHandle.Font = Enum.Font.GothamBold
ResizeHandle.TextSize = 10
ResizeHandle.TextColor3 = Theme.TextPrimary
ResizeHandle.AutoButtonColor = false
ResizeHandle.Parent = MainFrame

Instance.new("UICorner", ResizeHandle).CornerRadius = UDim.new(0, 4)

local isResizing = false
local resizeStartPos = Vector3.new()
local startSize = UDim2.new()

ResizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isResizing = true
        resizeStartPos = input.Position
        startSize = MainFrame.Size
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isResizing = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isResizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - resizeStartPos
        local newWidth = math.clamp(startSize.X.Offset + delta.X, 450, 900)
        local newHeight = math.clamp(startSize.Y.Offset + delta.Y, 250, 600)
        MainFrame.Size = UDim2.fromOffset(newWidth, newHeight)
    end
end)

-- [ 12. FLOATING TOGGLE BUTTON (F) ]
local FloatingBtn = Instance.new("TextButton")
FloatingBtn.Name = "FloatingToggleBtn"
FloatingBtn.Size = UDim2.fromOffset(44, 44)
FloatingBtn.AnchorPoint = Vector2.new(0, 0.5)
FloatingBtn.Position = UDim2.new(0, 20, 0.4, 0)
FloatingBtn.BackgroundColor3 = Theme.Background
FloatingBtn.BorderSizePixel = 0
FloatingBtn.Visible = false
FloatingBtn.Active = true
FloatingBtn.Text = ""
FloatingBtn.Parent = ScreenGui

Instance.new("UICorner", FloatingBtn).CornerRadius = UDim.new(0, 11)

local FloatingStroke = Instance.new("UIStroke")
FloatingStroke.Color = Theme.AccentBlue
FloatingStroke.Thickness = 1.5
FloatingStroke.Parent = FloatingBtn

local FloatingLogo = CreateFLogo(UDim2.fromOffset(20, 20), -12)
FloatingLogo.Position = UDim2.new(0.5, -10, 0.5, -10)
FloatingLogo.Parent = FloatingBtn

local FloatingScale = Instance.new("UIScale")
FloatingScale.Scale = 1
FloatingScale.Parent = FloatingBtn

local floatDragging = false
local floatDragStart = Vector3.new()
local floatStartPos = UDim2.new()
local floatInputObj = nil

FloatingBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        floatDragging = true
        floatDragStart = input.Position
        floatStartPos = FloatingBtn.Position
        floatInputObj = input
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input == floatInputObj or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        floatDragging = false
        floatInputObj = nil
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if floatDragging and (input == floatInputObj or input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - floatDragStart
        FloatingBtn.Position = UDim2.new(
            floatStartPos.X.Scale,
            floatStartPos.X.Offset + delta.X,
            floatStartPos.Y.Scale,
            floatStartPos.Y.Offset + delta.Y
        )
    end
end)

-- [ 13. TOGGLE UI <-> FLOATING BUTTON ]
local function ToggleMainUI(show)
    if show then
        MainFrame.Size = UDim2.fromOffset(620, 380)
        MainFrame.Visible = true
        MainScale.Scale = 0

        TweenService:Create(FloatingScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Scale = 0
        }):Play()

        TweenService:Create(MainScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Scale = 1
        }):Play()

        task.delay(0.12, function()
            FloatingBtn.Visible = false
        end)
    else
        TweenService:Create(MainScale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Scale = 0
        }):Play()

        task.delay(0.16, function()
            MainFrame.Visible = false
            FloatingBtn.Visible = true
            FloatingScale.Scale = 0

            TweenService:Create(FloatingScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Scale = 1
            }):Play()
        end)
    end
end

FloatingBtn.MouseButton1Click:Connect(function()
    ToggleMainUI(true)
end)

local isMinimized = false

CreateHeaderButton("-", function()
    isMinimized = not isMinimized
    if isMinimized then
        TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(620, 46)
        }):Play()
    else
        TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(620, 380)
        }):Play()
    end
end)

CreateHeaderButton("X", function()
    ToggleMainUI(false)
end)

-- [ 14. BOOT LOADING SCREEN ]
local BootScreen = Instance.new("CanvasGroup")
BootScreen.Name = "BootScreen"
BootScreen.Size = UDim2.fromOffset(280, 130)
BootScreen.AnchorPoint = Vector2.new(0.5, 0.5)
BootScreen.Position = UDim2.fromScale(0.5, 0.5)
BootScreen.BackgroundColor3 = Theme.Background
BootScreen.GroupTransparency = 0
BootScreen.ZIndex = 100
BootScreen.Parent = ScreenGui

Instance.new("UICorner", BootScreen).CornerRadius = UDim.new(0, 12)

local BootStroke = Instance.new("UIStroke")
BootStroke.Color = Theme.BorderColor
BootStroke.Thickness = 1
BootStroke.Parent = BootScreen

local BootLogo = CreateFLogo(UDim2.new(0, 30, 0, 30), -12)
BootLogo.Position = UDim2.new(0.5, -15, 0, 16)
BootLogo.Parent = BootScreen

local BootTitle = Instance.new("TextLabel")
BootTitle.Font = Enum.Font.GothamBold
BootTitle.TextSize = 16
BootTitle.TextColor3 = Theme.TextPrimary
BootTitle.BackgroundTransparency = 1
BootTitle.Size = UDim2.new(1, -20, 0, 20)
BootTitle.Position = UDim2.new(0, 10, 0, 54)
BootTitle.RichText = true
BootTitle.Text = "leon4951 <font color=\"rgb(37, 120, 255)\">Hub</font>"
BootTitle.Parent = BootScreen

local BootSubText = Instance.new("TextLabel")
BootSubText.Font = Enum.Font.Gotham
BootSubText.TextSize = 10
BootSubText.TextColor3 = Theme.TextSecondary
BootSubText.BackgroundTransparency = 1
BootSubText.Size = UDim2.new(1, -20, 0, 14)
BootSubText.Position = UDim2.new(0, 10, 0, 76)
BootSubText.Text = "Loading..."
BootSubText.Parent = BootScreen

local BootTrack = Instance.new("Frame")
BootTrack.Size = UDim2.new(1, -40, 0, 8)
BootTrack.Position = UDim2.new(0, 20, 1, -30)
BootTrack.BackgroundColor3 = Theme.RunPillBg
BootTrack.BorderSizePixel = 0
BootTrack.Parent = BootScreen
Instance.new("UICorner", BootTrack).CornerRadius = UDim.new(1, 0)

local BootFill = Instance.new("Frame")
BootFill.Size = UDim2.new(0, 0, 1, 0)
BootFill.BackgroundColor3 = Theme.AccentBlue
BootFill.BorderSizePixel = 0
BootFill.Parent = BootTrack
Instance.new("UICorner", BootFill).CornerRadius = UDim.new(1, 0)

local BootPercentLabel = Instance.new("TextLabel")
BootPercentLabel.Font = Enum.Font.GothamBold
BootPercentLabel.TextSize = 11
BootPercentLabel.TextColor3 = Theme.TextPrimary
BootPercentLabel.BackgroundTransparency = 1
BootPercentLabel.TextXAlignment = Enum.TextXAlignment.Right
BootPercentLabel.Size = UDim2.new(1, -40, 0, 14)
BootPercentLabel.Position = UDim2.new(0, 20, 1, -46)
BootPercentLabel.Text = "0%"
BootPercentLabel.Parent = BootScreen

local BootStatuses = {
    { 0.00, "Initializing..." },
    { 0.20, "Loading UI Components..." },
    { 0.40, "Filtering Script Database..." },
    { 0.65, "Preparing Categories..." },
    { 0.85, "Finalizing UI..." },
}

local bootDuration = 2.0
local bootStartTime = os.clock()
local bootConn

bootConn = RunService.Heartbeat:Connect(function()
    local elapsed = os.clock() - bootStartTime
    local pct = math.clamp(elapsed / bootDuration, 0, 1)

    BootFill.Size = UDim2.new(pct, 0, 1, 0)
    BootPercentLabel.Text = math.floor(pct * 100) .. "%"

    for _, status in ipairs(BootStatuses) do
        if pct >= status[1] then
            BootSubText.Text = status[2]
        end
    end

    if pct >= 1 then
        bootConn:Disconnect()
        bootConn = nil
        BootSubText.Text = "✓ Ready"

        task.spawn(function()
            task.wait(0.4)

            TweenService:Create(BootScreen, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                GroupTransparency = 1
            }):Play()

            task.delay(0.25, function()
                BootScreen:Destroy()

                MainFrame.Visible = true
                MainScale.Scale = 0
                TweenService:Create(MainScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Scale = 1
                }):Play()
            end)
        end)
    end
end)
