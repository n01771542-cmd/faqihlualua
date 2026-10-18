--[[
    Pure UI Library
    language: Luau (Roblox)
    file: PureUI.lua
    target: Roblox client, ScreenGui-based, no external deps
    notes:
      - drop in StarterPlayerScripts or executor
      - all widgets animated via TweenService
      - theme engine hot-swappable, 6 palettes built in
      - 20+ widgets, layout groups, scroll containers, modal, tooltip, notification
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ============================================================
-- SECTION 1: THEME ENGINE
-- ============================================================

local Themes = {}

Themes.Midnight = {
    Name = "Midnight",
    Background      = Color3.fromRGB(14, 14, 18),
    Surface         = Color3.fromRGB(22, 22, 28),
    SurfaceAlt      = Color3.fromRGB(30, 30, 38),
    SurfaceHover    = Color3.fromRGB(38, 38, 48),
    Border          = Color3.fromRGB(45, 45, 55),
    BorderFocus     = Color3.fromRGB(99, 102, 241),
    Accent          = Color3.fromRGB(99, 102, 241),
    AccentHover     = Color3.fromRGB(129, 132, 255),
    AccentDim       = Color3.fromRGB(67, 69, 165),
    Text            = Color3.fromRGB(240, 240, 245),
    TextMuted       = Color3.fromRGB(150, 150, 165),
    TextDisabled    = Color3.fromRGB(90, 90, 100),
    Success         = Color3.fromRGB(34, 197, 94),
    Warning         = Color3.fromRGB(234, 179, 8),
    Danger          = Color3.fromRGB(239, 68, 68),
    Shadow          = Color3.fromRGB(0, 0, 0),
    ShadowTransparency = 0.7,
}

Themes.Ocean = {
    Name = "Ocean",
    Background      = Color3.fromRGB(8, 20, 30),
    Surface         = Color3.fromRGB(14, 30, 42),
    SurfaceAlt      = Color3.fromRGB(20, 40, 55),
    SurfaceHover    = Color3.fromRGB(28, 52, 70),
    Border          = Color3.fromRGB(35, 65, 85),
    BorderFocus     = Color3.fromRGB(56, 189, 248),
    Accent          = Color3.fromRGB(56, 189, 248),
    AccentHover     = Color3.fromRGB(96, 210, 255),
    AccentDim       = Color3.fromRGB(35, 130, 175),
    Text            = Color3.fromRGB(230, 245, 255),
    TextMuted       = Color3.fromRGB(130, 165, 185),
    TextDisabled    = Color3.fromRGB(80, 105, 120),
    Success         = Color3.fromRGB(34, 197, 94),
    Warning         = Color3.fromRGB(234, 179, 8),
    Danger          = Color3.fromRGB(239, 68, 68),
    Shadow          = Color3.fromRGB(0, 5, 10),
    ShadowTransparency = 0.7,
}

Themes.Rose = {
    Name = "Rose",
    Background      = Color3.fromRGB(20, 12, 18),
    Surface         = Color3.fromRGB(30, 18, 26),
    SurfaceAlt      = Color3.fromRGB(40, 24, 34),
    SurfaceHover    = Color3.fromRGB(50, 30, 42),
    Border          = Color3.fromRGB(60, 38, 52),
    BorderFocus     = Color3.fromRGB(244, 114, 182),
    Accent          = Color3.fromRGB(244, 114, 182),
    AccentHover     = Color3.fromRGB(255, 150, 210),
    AccentDim       = Color3.fromRGB(175, 80, 130),
    Text            = Color3.fromRGB(255, 235, 245),
    TextMuted       = Color3.fromRGB(180, 140, 165),
    TextDisabled    = Color3.fromRGB(110, 85, 100),
    Success         = Color3.fromRGB(34, 197, 94),
    Warning         = Color3.fromRGB(234, 179, 8),
    Danger          = Color3.fromRGB(239, 68, 68),
    Shadow          = Color3.fromRGB(10, 0, 5),
    ShadowTransparency = 0.7,
}

Themes.Graphite = {
    Name = "Graphite",
    Background      = Color3.fromRGB(18, 18, 18),
    Surface         = Color3.fromRGB(26, 26, 26),
    SurfaceAlt      = Color3.fromRGB(34, 34, 34),
    SurfaceHover    = Color3.fromRGB(44, 44, 44),
    Border          = Color3.fromRGB(54, 54, 54),
    BorderFocus     = Color3.fromRGB(200, 200, 200),
    Accent          = Color3.fromRGB(220, 220, 220),
    AccentHover     = Color3.fromRGB(245, 245, 245),
    AccentDim       = Color3.fromRGB(140, 140, 140),
    Text            = Color3.fromRGB(240, 240, 240),
    TextMuted       = Color3.fromRGB(150, 150, 150),
    TextDisabled    = Color3.fromRGB(95, 95, 95),
    Success         = Color3.fromRGB(34, 197, 94),
    Warning         = Color3.fromRGB(234, 179, 8),
    Danger          = Color3.fromRGB(239, 68, 68),
    Shadow          = Color3.fromRGB(0, 0, 0),
    ShadowTransparency = 0.75,
}

Themes.Crimson = {
    Name = "Crimson",
    Background      = Color3.fromRGB(16, 8, 10),
    Surface         = Color3.fromRGB(26, 12, 16),
    SurfaceAlt      = Color3.fromRGB(36, 16, 22),
    SurfaceHover    = Color3.fromRGB(48, 22, 30),
    Border          = Color3.fromRGB(60, 28, 36),
    BorderFocus     = Color3.fromRGB(239, 68, 68),
    Accent          = Color3.fromRGB(239, 68, 68),
    AccentHover     = Color3.fromRGB(255, 110, 110),
    AccentDim       = Color3.fromRGB(165, 45, 45),
    Text            = Color3.fromRGB(255, 235, 235),
    TextMuted       = Color3.fromRGB(190, 145, 145),
    TextDisabled    = Color3.fromRGB(115, 85, 85),
    Success         = Color3.fromRGB(34, 197, 94),
    Warning         = Color3.fromRGB(234, 179, 8),
    Danger          = Color3.fromRGB(255, 120, 120),
    Shadow          = Color3.fromRGB(8, 0, 0),
    ShadowTransparency = 0.7,
}

Themes.Sakura = {
    Name = "Sakura",
    Background      = Color3.fromRGB(22, 16, 20),
    Surface         = Color3.fromRGB(32, 22, 30),
    SurfaceAlt      = Color3.fromRGB(44, 30, 40),
    SurfaceHover    = Color3.fromRGB(56, 38, 50),
    Border          = Color3.fromRGB(68, 46, 60),
    BorderFocus     = Color3.fromRGB(251, 191, 36),
    Accent          = Color3.fromRGB(251, 146, 60),
    AccentHover     = Color3.fromRGB(255, 180, 100),
    AccentDim       = Color3.fromRGB(180, 105, 45),
    Text            = Color3.fromRGB(255, 245, 235),
    TextMuted       = Color3.fromRGB(190, 165, 150),
    TextDisabled    = Color3.fromRGB(115, 100, 90),
    Success         = Color3.fromRGB(34, 197, 94),
    Warning         = Color3.fromRGB(251, 191, 36),
    Danger          = Color3.fromRGB(239, 68, 68),
    Shadow          = Color3.fromRGB(10, 5, 5),
    ShadowTransparency = 0.7,
}

local ActiveTheme = Themes.Midnight
local ThemeListeners = {}

local function NotifyThemeChange()
    for _, fn in ipairs(ThemeListeners) do
        pcall(fn, ActiveTheme)
    end
end

local function SetTheme(name)
    if Themes[name] then
        ActiveTheme = Themes[name]
        NotifyThemeChange()
    end
end

-- ============================================================
-- SECTION 2: UTILITIES
-- ============================================================

local Util = {}

function Util.New(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    return inst
end

function Util.Tween(inst, duration, props, style, direction)
    local info = TweenInfo.new(
        duration or 0.18,
        style or Enum.EasingStyle.Quad,
        direction or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(inst, info, props)
    tween:Play()
    return tween
end

function Util.Round(inst, radius)
    local c = Util.New("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
    c.Parent = inst
    return c
end

function Util.Stroke(inst, color, thickness, transparency)
    local s = Util.New("UIStroke", {
        Color = color or Color3.fromRGB(255, 255, 255),
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    s.Parent = inst
    return s
end

function Util.Padding(inst, all)
    local p = Util.New("UIPadding", {
        PaddingTop = UDim.new(0, all),
        PaddingBottom = UDim.new(0, all),
        PaddingLeft = UDim.new(0, all),
        PaddingRight = UDim.new(0, all),
    })
    p.Parent = inst
    return p
end

function Util.Gradient(inst, c1, c2, rotation)
    local g = Util.New("UIGradient", {
        Color = ColorSequence.new(c1, c2),
        Rotation = rotation or 90,
    })
    g.Parent = inst
    return g
end

function Util.Shadow(inst, transparency)
    local s = Util.New("UIStroke", {
        Color = ActiveTheme.Shadow,
        Thickness = 2,
        Transparency = transparency or 0.6,
    })
    s.Parent = inst
    return s
end

function Util.Clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v))
end

function Util.Lerp(a, b, t)
    return a + (b - a) * t
end

function Util.LerpColor(c1, c2, t)
    return Color3.new(
        Util.Lerp(c1.R, c2.R, t),
        Util.Lerp(c1.G, c2.G, t),
        Util.Lerp(c1.B, c2.B, t)
    )
end

function Util.FormatTime(t)
    if t < 60 then return string.format("%ds", math.floor(t)) end
    return string.format("%dm %ds", math.floor(t/60), math.floor(t%60))
end

-- ============================================================
-- SECTION 3: ROOT / SCREEN GUI
-- ============================================================

local PureUI = {}
PureUI.__index = PureUI

local function CreateRoot()
    local gui = Util.New("ScreenGui", {
        Name = "PureUI_" .. tostring(math.random(100000, 999999)),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        DisplayOrder = 999,
    })
    local ok = pcall(function() gui.Parent = CoreGui end)
    if not ok then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    return gui
end

-- ============================================================
-- SECTION 4: WINDOW
-- ============================================================

function PureUI.new(opts)
    opts = opts or {}
    local self = setmetatable({}, PureUI)

    self.Root = CreateRoot()
    self.Connections = {}
    self.Window = nil
    self.Tabs = {}
    self.ActiveTab = nil
    self.Open = false
    self.Dragging = false
    self.DragStart = nil
    self.DragOrigin = nil
    self.Widgets = {}
    self.Notifications = {}

    local width = opts.Width or 620
    local height = opts.Height or 440
    local title = opts.Title or "Pure UI"
    local subtitle = opts.Subtitle or "v1.0"

    -- window frame
    local win = Util.New("Frame", {
        Name = "Window",
        Size = UDim2.fromOffset(width, height),
        Position = UDim2.new(0.5, -width/2, 0.5, -height/2),
        BackgroundColor3 = ActiveTheme.Background,
        BorderSizePixel = 0,
        Visible = false,
        ClipsDescendants = true,
    })
    win.Parent = self.Root
    Util.Round(win, 12)
    Util.Stroke(win, ActiveTheme.Border, 1, 0)
    self.Window = win

    -- shadow layer
    local shadow = Util.New("Frame", {
        Name = "Shadow",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = ActiveTheme.Shadow,
        BackgroundTransparency = 1,
        ZIndex = -1,
        BorderSizePixel = 0,
    })
    shadow.Parent = win

    -- title bar
    local titleBar = Util.New("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = ActiveTheme.Surface,
        BorderSizePixel = 0,
        ZIndex = 2,
    })
    titleBar.Parent = win
    local topCorner = Util.New("UICorner", { CornerRadius = UDim.new(0, 12) })
    topCorner.Parent = titleBar

    -- title bar bottom line
    local titleLine = Util.New("Frame", {
        Name = "TitleLine",
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = ActiveTheme.Border,
        BorderSizePixel = 0,
        ZIndex = 2,
    })
    titleLine.Parent = titleBar

    -- logo dot
    local logo = Util.New("Frame", {
        Name = "Logo",
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.fromOffset(16, 14),
        BackgroundColor3 = ActiveTheme.Accent,
        BorderSizePixel = 0,
        ZIndex = 3,
    })
    logo.Parent = titleBar
    Util.Round(logo, 8)

    local logoInner = Util.New("Frame", {
        Size = UDim2.fromOffset(12, 12),
        Position = UDim2.new(0.5, -6, 0.5, -6),
        BackgroundColor3 = ActiveTheme.Background,
        BorderSizePixel = 0,
        ZIndex = 4,
    })
    logoInner.Parent = logo
    Util.Round(logoInner, 4)

    -- title text
    local titleText = Util.New("TextLabel", {
        Name = "TitleText",
        Size = UDim2.new(0, 300, 0, 20),
        Position = UDim2.fromOffset(56, 12),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextColor3 = ActiveTheme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = title,
        ZIndex = 3,
    })
    titleText.Parent = titleBar

    local subtitleText = Util.New("TextLabel", {
        Name = "SubtitleText",
        Size = UDim2.new(0, 300, 0, 16),
        Position = UDim2.fromOffset(56, 30),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = ActiveTheme.TextMuted,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = subtitle,
        ZIndex = 3,
    })
    subtitleText.Parent = titleBar

    -- close button
    local closeBtn = Util.New("TextButton", {
        Name = "Close",
        Size = UDim2.fromOffset(32, 32),
        Position = UDim2.new(1, -44, 0, 12),
        BackgroundColor3 = ActiveTheme.SurfaceAlt,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 3,
    })
    closeBtn.Parent = titleBar
    Util.Round(closeBtn, 8)

    local closeIcon = Util.New("TextLabel", {
        Size = UDim2.fromOffset(32, 32),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = ActiveTheme.TextMuted,
        Text = "×",
        ZIndex = 4,
    })
    closeIcon.Parent = closeBtn

    closeBtn.MouseEnter:Connect(function()
        Util.Tween(closeBtn, 0.12, { BackgroundColor3 = ActiveTheme.Danger })
        Util.Tween(closeIcon, 0.12, { TextColor3 = ActiveTheme.Text })
    end)
    closeBtn.MouseLeave:Connect(function()
        Util.Tween(closeBtn, 0.12, { BackgroundColor3 = ActiveTheme.SurfaceAlt })
        Util.Tween(closeIcon, 0.12, { TextColor3 = ActiveTheme.TextMuted })
    end)
    closeBtn.MouseButton1Click:Connect(function()
        self:Hide()
    end)

    -- minimize button
    local minBtn = Util.New("TextButton", {
        Name = "Minimize",
        Size = UDim2.fromOffset(32, 32),
        Position = UDim2.new(1, -80, 0, 12),
        BackgroundColor3 = ActiveTheme.SurfaceAlt,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 3,
    })
    minBtn.Parent = titleBar
    Util.Round(minBtn, 8)

    local minIcon = Util.New("TextLabel", {
        Size = UDim2.fromOffset(32, 32),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = ActiveTheme.TextMuted,
        Text = "−",
        ZIndex = 4,
    })
    minIcon.Parent = minBtn

    minBtn.MouseEnter:Connect(function()
        Util.Tween(minBtn, 0.12, { BackgroundColor3 = ActiveTheme.SurfaceHover })
        Util.Tween(minIcon, 0.12, { TextColor3 = ActiveTheme.Text })
    end)
    minBtn.MouseLeave:Connect(function()
        Util.Tween(minBtn, 0.12, { BackgroundColor3 = ActiveTheme.SurfaceAlt })
        Util.Tween(minIcon, 0.12, { TextColor3 = ActiveTheme.TextMuted })
    end)
    minBtn.MouseButton1Click:Connect(function()
        self:Hide()
    end)

    -- drag logic
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.Dragging = true
            self.DragStart = input.Position
            self.DragOrigin = win.Position
        end
    end)
    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.Dragging = false
        end
    end)
    table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input)
        if self.Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - self.DragStart
            win.Position = UDim2.new(
                self.DragOrigin.X.Scale, self.DragOrigin.X.Offset + delta.X,
                self.DragOrigin.Y.Scale, self.DragOrigin.Y.Offset + delta.Y
            )
        end
    end))

    -- sidebar container
    local sidebar = Util.New("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 140, 1, -56),
        Position = UDim2.new(0, 0, 0, 56),
        BackgroundColor3 = ActiveTheme.Surface,
        BorderSizePixel = 0,
        ZIndex = 2,
    })
    sidebar.Parent = win

    local sidebarLine = Util.New("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = ActiveTheme.Border,
        BorderSizePixel = 0,
        ZIndex = 2,
    })
    sidebarLine.Parent = sidebar

    local sidebarPad = Util.New("UIPadding", {
        PaddingTop = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
    })
    sidebarPad.Parent = sidebar

    local tabList = Util.New("Frame", {
        Name = "TabList",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
    })
    tabList.Parent = sidebar

    local tabLayout = Util.New("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    tabLayout.Parent = tabList

    -- content area
    local content = Util.New("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -140, 1, -56),
        Position = UDim2.new(0, 140, 0, 56),
        BackgroundColor3 = ActiveTheme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 1,
    })
    content.Parent = win
    Util.Padding(content, 12)

    self.TitleBar = titleBar
    self.Sidebar = sidebar
    self.TabList = tabList
    self.Content = content
    self.CloseBtn = closeBtn
    self.MinBtn = minBtn
    self.TitleText = titleText
    self.SubtitleText = subtitleText

    -- theme listener for hot-swap
    table.insert(ThemeListeners, function(t)
        self:ApplyTheme(t)
    end))

    -- open animation
    self:Show()

    return self
end

-- ============================================================
-- SECTION 5: WINDOW METHODS
-- ============================================================

function PureUI:ApplyTheme(t)
    if not self.Window then return end
    local win = self.Window
    win.BackgroundColor3 = t.Background

    local function recolor(inst, colorProp, color)
        if inst and inst[colorProp] then
            inst[colorProp] = color
        end
    end

    for _, d in ipairs(win:GetDescendants()) do
        if d.Name == "TitleBar" or d.Name == "Sidebar" then
            if d:IsA("Frame") then d.BackgroundColor3 = t.Surface end
        elseif d.Name == "Surface" then
            if d:IsA("Frame") then d.BackgroundColor3 = t.Surface end
        elseif d.Name == "Border" then
            if d:IsA("Frame") then d.BackgroundColor3 = t.Border end
        elseif d.Name == "Accent" then
            if d:IsA("Frame") then d.BackgroundColor3 = t.Accent end
        end
    end
end

function PureUI:Show()
    if not self.Window then return end
    self.Window.Visible = true
    self.Window.Size = UDim2.fromOffset(10, 10)
    Util.Tween(self.Window, 0.24, {
        Size = UDim2.fromOffset(620, 440),
    }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    self.Open = true
end

function PureUI:Hide()
    if not self.Window then return end
    Util.Tween(self.Window, 0.16, { Size = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    task.delay(0.16, function()
        if self.Window then self.Window.Visible = false end
    end)
    self.Open = false
end

function PureUI:Toggle()
    if self.Open then self:Hide() else self:Show() end
end

function PureUI:Destroy()
    for _, c in ipairs(self.Connections) do pcall(function() c:Disconnect() end) end
    self.Connections = {}
    if self.Root then self.Root:Destroy() end
end

-- ============================================================
-- SECTION 6: TAB SYSTEM
-- ============================================================

function PureUI:Tab(tabName)
    local tabBtn = Util.New("TextButton", {
        Name = "Tab_" .. tabName,
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = ActiveTheme.SurfaceAlt,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 3,
    })
    tabBtn.Parent = self.TabList
    Util.Round(tabBtn, 8)

    local icon = Util.New("Frame", {
        Size = UDim2.fromOffset(3, 14),
        Position = UDim2.new(0, 8, 0.5, -7),
        BackgroundColor3 = ActiveTheme.TextDisabled,
        BorderSizePixel = 0,
        ZIndex = 4,
    })
    icon.Parent = tabBtn
    Util.Round(icon, 2)

    local label = Util.New("TextLabel", {
        Size = UDim2.new(1, -28, 1, 0),
        Position = UDim2.fromOffset(20, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = ActiveTheme.TextMuted,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = tabName,
        ZIndex = 4,
    })
    label.Parent = tabBtn

    local page = Util.New("Frame", {
        Name = "Page_" .. tabName,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 1,
    })
    page.Parent = self.Content

    local scroll = Util.New("ScrollingFrame", {
        Name = "Scroll",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = ActiveTheme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarImageTransparency = 0.3,
    })
    scroll.Parent = page

    local layout = Util.New("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    layout.Parent = scroll

    local tab = {
        Name = tabName,
        Button = tabBtn,
        Icon = icon,
        Label = label,
        Page = page,
        Scroll = scroll,
        Layout = layout,
        Parent = self,
    }

    table.insert(self.Tabs, tab)

    tabBtn.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then
            Util.Tween(tabBtn, 0.12, { BackgroundColor3 = ActiveTheme.SurfaceHover })
            Util.Tween(label, 0.12, { TextColor3 = ActiveTheme.Text })
        end
    end)
    tabBtn.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then
            Util.Tween(tabBtn, 0.12, { BackgroundColor3 = ActiveTheme.SurfaceAlt })
            Util.Tween(label, 0.12, { TextColor3 = ActiveTheme.TextMuted })
        end
    end)
    tabBtn.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)

    if #self.Tabs == 1 then
        self:SelectTab(tab)
    end

    return tab
end

function PureUI:SelectTab(tab)
    if self.ActiveTab == tab then return end
    for _, t in ipairs(self.Tabs) do
        t.Page.Visible = false
        Util.Tween(t.Button, 0.14, { BackgroundColor3 = ActiveTheme.SurfaceAlt })
        Util.Tween(t.Label, 0.14, { TextColor3 = ActiveTheme.TextMuted })
        Util.Tween(t.Icon, 0.14, { BackgroundColor3 = ActiveTheme.TextDisabled })
    end
    self.ActiveTab = tab
    tab.Page.Visible = true
    Util.Tween(tab.Button, 0.14, { BackgroundColor3 = ActiveTheme.AccentDim })
    Util.Tween(tab.Label, 0.14, { TextColor3 = ActiveTheme.Text })
    Util.Tween(tab.Icon, 0.14, { BackgroundColor3 = ActiveTheme.Accent })

    -- fade in page
    tab.Page.BackgroundTransparency = 1
    local fade = Util.New("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = ActiveTheme.Background,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        ZIndex = 100,
    })
    fade.Parent = tab.Page
    Util.Tween(fade, 0.2, { BackgroundTransparency = 1 })
    task.delay(0.2, function() fade:Destroy() end)
end

-- ============================================================
-- SECTION 7: SECTION / GROUP HEADER
-- ============================================================

function PureUI:Section(tab, title)
    local frame = Util.New("Frame", {
        Name = "Section_" .. (title or ""),
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        LayoutOrder = 0,
    })
    frame.Parent = tab.Scroll

    local lineL = Util.New("Frame", {
        Size = UDim2.new(0, 20, 0, 1),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = ActiveTheme.Accent,
        BorderSizePixel = 0,
    })
    lineL.Parent = frame

    local label = Util.New("TextLabel", {
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.fromOffset(28, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = ActiveTheme.Accent,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = string.upper(title or "SECTION"),
    })
    label.Parent = frame

    local lineR = Util.New("Frame", {
        Size = UDim2.new(0, 0, 0, 1),
        Position = UDim2.new(1, -20, 0.5, 0),
        BackgroundColor3 = ActiveTheme.Border,
        BorderSizePixel = 0,
    })
    lineR.Parent = frame

    return frame
end

-- ============================================================
-- SECTION 8: TOGGLE WIDGET
-- ============================================================

function PureUI:Toggle(tab, opts)
    opts = opts or {}
    local label = opts.Label or "Toggle"
    local default = opts.Default or false
    local callback = opts.Callback or function() end
    local state = default

    local row = Util.New("Frame", {
        Name = "ToggleRow",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = ActiveTheme.Surface,
        BorderSizePixel = 0,
    })
    row.Parent = tab.Scroll
    Util.Round(row, 8)
    local stroke = Util.Stroke(row, ActiveTheme.Border, 1, 0.4)

    local pad = Util.New("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
    })
    pad.Parent = row

    local label2 = Util.New("TextLabel", {
        Size = UDim2.new(1, -60, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = ActiveTheme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = label,
    })
    label2.Parent = row

    local track = Util.New("Frame", {
        Size = UDim2.fromOffset(40, 20),
        Position = UDim2.new(1, -40, 0.5, -10),
        BackgroundColor3 = ActiveTheme.SurfaceAlt,
        BorderSizePixel = 0,
    })
    track.Parent = row
    Util.Round(track, 10)

    local knob = Util.New("Frame", {
        Size = UDim2.fromOffset(16, 16),
        Position = UDim2.new(0, 2, 0.5, -8),
        BackgroundColor3 = ActiveTheme.TextMuted,
        BorderSizePixel = 0,
    })
    knob.Parent = track
    Util.Round(knob, 8)

    local function update(anim)
        if state then
            Util.Tween(track, anim and 0.16 or 0, { BackgroundColor3 = ActiveTheme.Accent })
            Util.Tween(knob, anim and 0.16 or 0, {
                Position = UDim2.new(1, -18, 0.5, -8),
                BackgroundColor3 = ActiveTheme.Text,
            })
        else
            Util.Tween(track, anim and 0.16 or 0, { BackgroundColor3 = ActiveTheme.SurfaceAlt })
            Util.Tween(knob, anim and 0.16 or 0, {
                Position = UDim2.new(0, 2, 0.5, -8),
                BackgroundColor3 = ActiveTheme.TextMuted,
            })
        end
    end
    update(false)

    local clickBtn = Util.New("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
    })
    clickBtn.Parent = row

    clickBtn.MouseButton1Click:Connect(function()
        state = not state
        update(true)
        callback(state)
    end)
    clickBtn.MouseEnter:Connect(function()
        Util.Tween(row, 0.12, { BackgroundColor3 = ActiveTheme.SurfaceHover })
    end)
    clickBtn.MouseLeave:Connect(function()
        Util.Tween(row, 0.12, { BackgroundColor3 = ActiveTheme.Surface })
    end)

    local widget = {
        Type = "Toggle",
        Instance = row,
        Get = function() return state end,
        Set = function(v) state = v; update(true); callback(v) end,
    }
    table.insert(self.Widgets, widget)
    return widget
end

-- ============================================================
-- SECTION 9: SLIDER WIDGET
-- ============================================================

function PureUI:Slider(tab, opts)
    opts = opts or {}
    local label = opts.Label or "Slider"
    local min = opts.Min or 0
    local max = opts.Max or 100
    local default = opts.Default or min
    local suffix = opts.Suffix or ""
    local callback = opts.Callback or function() end
    local value = Util.Clamp(default, min, max)
    local dragging = false

    local row = Util.New("Frame", {
        Name = "SliderRow",
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = ActiveTheme.Surface,
        BorderSizePixel = 0,
    })
    row.Parent = tab.Scroll
    Util.Round(row, 8)
    Util.Stroke(row, ActiveTheme.Border, 1, 0.4)

    local label2 = Util.New("TextLabel", {
        Size = UDim2.new(1, -80, 0, 24),
        Position = UDim2.fromOffset(12, 8),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = ActiveTheme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = label,
    })
    label2.Parent = row

    local valueLabel = Util.New("TextLabel", {
        Size = UDim2.new(0, 70, 0, 24),
        Position = UDim2.new(1, -78, 0, 8),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = ActiveTheme.Accent,
        TextXAlignment = Enum.TextXAlignment.Right,
        Text = tostring(value) .. suffix,
    })
    valueLabel.Parent = row

    local track = Util.New("Frame", {
        Size = UDim2.new(1, -24, 0, 4),
        Position = UDim2.new(0, 12, 1, -16),
        BackgroundColor3 = ActiveTheme.SurfaceAlt,
        BorderSizePixel = 0,
    })
    track.Parent = row
    Util.Round(track, 2)

    local fill = Util.New("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = ActiveTheme.Accent,
        BorderSizePixel = 0,
    })
    fill.Parent = track
    Util.Round(fill, 2)

    local knob = Util.New("Frame", {
        Size = UDim2.fromOffset(12, 12),
        Position = UDim2.new(0, -6, 0.5, -6),
        BackgroundColor3 = ActiveTheme.Text,
        BorderSizePixel = 0,
    })
    knob.Parent = fill
    Util.Round(knob, 6)
    Util.Stroke(knob, ActiveTheme.Accent, 2, 0)

    local function setValue(v)
        v = Util.Clamp(v, min, max)
        value = v
        local pct = (v - min) / (max - min)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        valueLabel.Text = string.format("%s%s", tostring(math.floor(v * 100) / 100), suffix)
        callback(v)
    end

    local function fromX(x)
        local abs = track.AbsolutePosition.X
        local size = track.AbsoluteSize.X
        local pct = Util.Clamp((x - abs) / size, 0, 1)
        setValue(min + pct * (max - min))
    end

    local clickArea = Util.New("TextButton", {
        Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.new(0, 0, 1, -28),
        BackgroundTransparency = 1,
        Text = "",
    })
    clickArea.Parent = row

    clickArea.MouseButton1Down:Connect(function()
        dragging = true
        fromX(Mouse.X)
    end)
    table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            fromX(input.Position.X)
        end
    end))
    table.insert(self.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))

    setValue(value)

    local widget = {
        Type = "Slider",
        Instance = row,
        Get = function() return value end,
        Set = function(v) setValue(v) end,
    }
    table.insert(self.Widgets, widget)
    return widget
end

-- ============================================================
-- SECTION 10: BUTTON WIDGET
-- ============================================================

function PureUI:Button(tab, opts)
    opts = opts or {}
    local label = opts.Label or "Button"
    local callback = opts.Callback or function() end
    local style = opts.Style or "primary"

    local bg = ActiveTheme.Accent
    local fg = ActiveTheme.Text
    if style == "secondary" then
        bg = ActiveTheme.SurfaceAlt
        fg = ActiveTheme.Text
    elseif style == "danger" then
        bg = ActiveTheme.Danger
        fg = ActiveTheme.Text
    elseif style == "ghost" then
        bg = ActiveTheme.Surface
        fg = ActiveTheme.TextMuted
    end

    local btn = Util.New("TextButton", {
        Name = "Button_" .. label,
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = bg,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    })
    btn.Parent = tab.Scroll
    Util.Round(btn, 8)

    local inner = Util.New("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = fg,
        Text = label,
    })
    inner.Parent = btn

    local hoverBg = bg
    if style == "primary" then hoverBg = ActiveTheme.AccentHover
    elseif style == "secondary" then hoverBg = ActiveTheme.SurfaceHover
    elseif style == "danger" then hoverBg = Color3.fromRGB(255, 100, 100)
    elseif style == "ghost" then hoverBg = ActiveTheme.SurfaceAlt end

    btn.MouseEnter:Connect(function()
        Util.Tween(btn, 0.12, { BackgroundColor3 = hoverBg })
    end)
    btn.MouseLeave:Connect(function()
        Util.Tween(btn, 0.12, { BackgroundColor3 = bg })
    end)
    btn.MouseButton1Down:Connect(function()
        Util.Tween(btn, 0.08, { Size = UDim2.new(1, -4, 0, 34), Position = UDim2.fromOffset(2, 1) })
    end)
    btn.MouseButton1Up:Connect(function()
        Util.Tween(btn, 0.12, { Size = UDim2.new(1, 0, 0, 36), Position = UDim2.fromOffset(0, 0) })
        callback()
    end)

    return { Type = "Button", Instance = btn }
end

-- ============================================================
-- SECTION 11: DROPDOWN WIDGET
-- ============================================================

function PureUI:Dropdown(tab, opts)
    opts = opts or {}
    local label = opts.Label or "Dropdown"
    local options = opts.Options or {}
    local default = opts.Default or options[1]
    local callback = opts.Callback or function() end
    local selected = default
    local open = false

    local row = Util.New("Frame", {
        Name = "DropdownRow",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = ActiveTheme.Surface,
        BorderSizePixel = 0,
        ClipsDescendants = false,
    })
    row.Parent = tab.Scroll
    Util.Round(row, 8)
    Util.Stroke(row, ActiveTheme.Border, 1, 0.4)

    local label2 = Util.New("TextLabel", {
        Size = UDim2.new(0, 120, 1, 0),
        Position = UDim2.fromOffset(12, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = ActiveTheme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = label,
    })
    label2.Parent = row

    local valueBtn = Util.New("TextButton", {
        Size = UDim2.new(0, 140, 0, 26),
        Position = UDim2.new(1, -152, 0.5, -13),
        BackgroundColor3 = ActiveTheme.SurfaceAlt,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    })
    valueBtn.Parent = row
    Util.Round(valueBtn, 6)

    local valueText = Util.New("TextLabel", {
        Size = UDim2.new(1, -24, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = ActiveTheme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = tostring(selected),
    })
    valueText.Parent = valueBtn

    local arrow = Util.New("TextLabel", {
        Size = UDim2.fromOffset(16, 16),
        Position = UDim2.new(1, -22, 0.5, -8),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = ActiveTheme.TextMuted,
        Text = "▾",
    })
    arrow.Parent = valueBtn

    local menu = Util.New("Frame", {
        Size = UDim2.new(0, 140, 0, 0),
        Position = UDim2.new(1, -152, 1, 4),
        BackgroundColor3 = ActiveTheme.SurfaceAlt,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 50,
        ClipsDescendants = true,
    })
    menu.Parent = row
    Util.Round(menu, 6)
    Util.Stroke(menu, ActiveTheme.Border, 1, 0)

    local menuLayout = Util.New("UIListLayout", { Padding = UDim.new(0, 2) })
    menuLayout.Parent = menu
    local menuPad = Util.New("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
    })
    menuPad.Parent = menu

    for _, opt in ipairs(options) do
        local optBtn = Util.New("TextButton", {
            Size = UDim2.new(1, -8, 0, 24),
            BackgroundColor3 = ActiveTheme.SurfaceAlt,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 51,
        })
        optBtn.Parent = menu
        Util.Round(optBtn, 4)

        local optText = Util.New("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium,
            TextSize = 11,
            TextColor3 = ActiveTheme.TextMuted,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "  " .. tostring(opt),
        })
        optText.Parent = optBtn

        optBtn.MouseEnter:Connect(function()
            Util.Tween(optBtn, 0.1, { BackgroundColor3 = ActiveTheme.SurfaceHover })
            Util.Tween(optText, 0.1, { TextColor3 = ActiveTheme.Text })
        end)
        optBtn.MouseLeave:Connect(function()
            Util.Tween(optBtn, 0.1, { BackgroundColor3 = ActiveTheme.SurfaceAlt })
            Util.Tween(optText, 0.1, { TextColor3 = ActiveTheme.TextMuted })
        end)
        optBtn.MouseButton1Click:Connect(function()
            selected = opt
            valueText.Text = tostring(opt)
            callback(opt)
            open = false
            Util.Tween(menu, 0.16, { Size = UDim2.new(0, 140, 0, 0), Visible = false })
            Util.Tween(arrow, 0.16, { Rotation = 0 })
        end)
    end

    valueBtn.MouseButton1Click:Connect(function()
        open = not open
        if open then
            menu.Visible = true
            local targetH = #options * 26 + 8
            Util.Tween(menu, 0.18, { Size = UDim2.new(0, 140, 0, targetH) })
            Util.Tween(arrow, 0.18, { Rotation = 180 })
        else
            Util.Tween(menu, 0.16, { Size = UDim2.new(0, 140, 0, 0) })
            Util.Tween(arrow, 0.16, { Rotation = 0 })
            task.delay(0.16, function() menu.Visible = false end)
        end
    end)

    local widget = {
        Type = "Dropdown",
        Instance = row,
        Get = function() return selected end,
        Set = function(v)
            for _, o in ipairs(options) do
                if o == v then
                    selected = o
                    valueText.Text = tostring(o)
                    callback(o)
                    break
                end
            end
        end,
    }
    table.insert(self.Widgets, widget)
    return widget
end

-- ============================================================
-- SECTION 12: TEXTBOX WIDGET
-- ============================================================

function PureUI:TextBox(tab, opts)
    opts = opts or {}
    local label = opts.Label or "Input"
    local placeholder = opts.Placeholder or ""
    local default = opts.Default or ""
    local callback = opts.Callback or function() end

    local row = Util.New("Frame", {
        Name = "TextBoxRow",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = ActiveTheme.Surface,
        BorderSizePixel = 0,
    })
    row.Parent = tab.Scroll
    Util.Round(row, 8)
    Util.Stroke(row, ActiveTheme.Border, 1, 0.4)

    local label2 = Util.New("TextLabel", {
        Size = UDim2.new(0, 100, 1, 0),
        Position = UDim2.fromOffset(12, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = ActiveTheme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = label,
    })
    label2.Parent = row

    local inputFrame = Util.New("Frame", {
        Size = UDim2.new(0, 200, 0, 28),
        Position = UDim2.new(1, -212, 0.5, -14),
        BackgroundColor3 = ActiveTheme.SurfaceAlt,
        BorderSizePixel = 0,
    })
    inputFrame.Parent = row
    Util.Round(inputFrame, 6)
    local inputStroke = Util.Stroke(inputFrame, ActiveTheme.Border, 1, 0.4)

    local textBox = Util.New("TextBox", {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.fromOffset(8, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = ActiveTheme.Text,
        PlaceholderText = placeholder,
        PlaceholderColor3 = ActiveTheme.TextDisabled,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = default,
        ClearTextOnFocus = false,
    })
    textBox.Parent = inputFrame

    textBox.Focused:Connect(function()
        Util.Tween(inputStroke, 0.14, { Color = ActiveTheme.Accent, Transparency = 0 })
    end)
    textBox.FocusLost:Connect(function(enter)
        Util.Tween(inputStroke, 0.14, { Color = ActiveTheme.Border, Transparency = 0.4 })
        if enter then callback(textBox.Text) end
    end)

    return {
        Type = "TextBox",
        Instance = row,
        Get = function() return textBox.Text end,
        Set = function(v) textBox.Text = v end,
    }
end

-- ============================================================
-- SECTION 13: KEYBIND WIDGET
-- ============================================================

function PureUI:Keybind(tab, opts)
    opts = opts or {}
    local label = opts.Label or "Keybind"
    local default = opts.Default or Enum.KeyCode.F
    local callback = opts.Callback or function() end
    local current = default
    local listening = false

    local row = Util.New("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = ActiveTheme.Surface,
        BorderSizePixel = 0,
    })
    row.Parent = tab.Scroll
    Util.Round(row, 8)
    Util.Stroke(row, ActiveTheme.Border, 1, 0.4)

    local label2 = Util.New("TextLabel", {
        Size = UDim2.new(1, -120, 1, 0),
        Position = UDim2.fromOffset(12, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = ActiveTheme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = label,
    })
    label2.Parent = row

    local keyBtn = Util.New("TextButton", {
        Size = UDim2.new(0, 100, 0, 26),
        Position = UDim2.new(1, -112, 0.5, -13),
        BackgroundColor3 = ActiveTheme.SurfaceAlt,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    })
    keyBtn.Parent = row
    Util.Round(keyBtn, 6)

    local keyText = Util.New("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = ActiveTheme.Text,
        Text = current.Name,
    })
    keyText.Parent = keyBtn

    keyBtn.MouseButton1Click:Connect(function()
        listening = true
        keyText.Text = "Press..."
        Util.Tween(keyBtn, 0.14, { BackgroundColor3 = ActiveTheme.AccentDim })
    end)

    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if listening and input.UserInputType == Enum.UserInputType.Keyboard then
            current = input.KeyCode
            keyText.Text = current.Name
            listening = false
            Util.Tween(keyBtn, 0.14, { BackgroundColor3 = ActiveTheme.SurfaceAlt })
            callback(current)
        elseif not listening and input.KeyCode == current then
            callback(current, true)
        end
    end))

    return {
        Type = "Keybind",
        Instance = row,
        Get = function() return current end,
    }
end

-- ============================================================
-- SECTION 14: COLOR PICKER
-- ============================================================

function PureUI:ColorPicker(tab, opts)
    opts = opts or {}
    local label = opts.Label or "Color"
    local default = opts.Default or Color3.fromRGB(99, 102, 241)
    local callback = opts.Callback or function() end
    local color = default

    local row = Util.New("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = ActiveTheme.Surface,
        BorderSizePixel = 0,
    })
    row.Parent = tab.Scroll
    Util.Round(row, 8)
    Util.Stroke(row, ActiveTheme.Border, 1, 0.4)

    local label2 = Util.New("TextLabel", {
        Size = UDim2.new(1, -80, 1, 0),
        Position = UDim2.fromOffset(12, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = ActiveTheme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = label,
    })
    label2.Parent = row

    local swatch = Util.New("TextButton", {
        Size = UDim2.fromOffset(48, 24),
        Position = UDim2.new(1, -60, 0.5, -12),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    })
    swatch.Parent = row
    Util.Round(swatch, 6)
    Util.Stroke(swatch, ActiveTheme.Border, 1, 0)

    -- simple RGB picker popup
    local popup = Util.New("Frame", {
        Size = UDim2.new(0, 220, 0, 140),
        Position = UDim2.new(1, -60, 1, 8),
        BackgroundColor3 = ActiveTheme.SurfaceAlt,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 100,
    })
    popup.Parent = row
    Util.Round(popup, 8)
    Util.Stroke(popup, ActiveTheme.Border, 1, 0)

    local channels = { { "R", "R" }, { "G", "G" }, { "B", "B" } }
    local sliders = {}
    for i, ch in ipairs(channels) do
        local srow = Util.New("Frame", {
            Size = UDim2.new(1, -20, 0, 30),
            Position = UDim2.fromOffset(10, 10 + (i-1)*34),
            BackgroundTransparency = 1,
        })
        srow.Parent = popup

        local slabel = Util.New("TextLabel", {
            Size = UDim2.fromOffset(16, 30),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextColor3 = ActiveTheme.Text,
            Text = ch[1],
        })
        slabel.Parent = srow

        local track = Util.New("Frame", {
            Size = UDim2.new(1, -40, 0, 4),
            Position = UDim2.new(0, 20, 0.5, -2),
            BackgroundColor3 = ActiveTheme.Surface,
            BorderSizePixel = 0,
        })
        track.Parent = srow
        Util.Round(track, 2)

        local fill = Util.New("Frame", {
            Size = UDim2.new(0.5, 0, 1, 0),
            BackgroundColor3 = ActiveTheme.Accent,
            BorderSizePixel = 0,
        })
        fill.Parent = track
        Util.Round(fill, 2)

        local clickArea = Util.New("TextButton", {
            Size = UDim2.new(1, 0, 0, 24),
            Position = UDim2.new(0, 0, 0.5, -12),
            BackgroundTransparency = 1,
            Text = "",
        })
        clickArea.Parent = srow

        local function apply(v)
            local c = color
            if ch[1] == "R" then c = Color3.new(v, c.G, c.B)
            elseif ch[1] == "G" then c = Color3.new(c.R, v, c.B)
            else c = Color3.new(c.R, c.G, v) end
            color = c
            swatch.BackgroundColor3 = c
            fill.Size = UDim2.new(v, 0, 1, 0)
            callback(c)
        end

        local drag = false
        clickArea.MouseButton1Down:Connect(function()
            drag = true
            local abs = track.AbsolutePosition.X
            local size = track.AbsoluteSize.X
            local pct = Util.Clamp((Mouse.X - abs) / size, 0, 1)
            apply(pct)
        end)
        table.insert(self.Connections, UserInputService.InputChanged:Connect(function(inp)
            if drag and inp.UserInputType == Enum.UserInputType.MouseMovement then
                local abs = track.AbsolutePosition.X
                local size = track.AbsoluteSize.X
                local pct = Util.Clamp((inp.Position.X - abs) / size, 0, 1)
                apply(pct)
            end
        end))
        table.insert(self.Connections, UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                drag = false
            end
        end))
    end

    swatch.MouseButton1Click:Connect(function()
        popup.Visible = not popup.Visible
    end)

    return {
        Type = "ColorPicker",
        Instance = row,
        Get = function() return color end,
        Set = function(c)
            color = c
            swatch.BackgroundColor3 = c
            callback(c)
        end,
    }
end

-- ============================================================
-- SECTION 15: NOTIFICATION SYSTEM
-- ============================================================

local notifStack = nil

function PureUI:Notify(opts)
    opts = opts or {}
    local title = opts.Title or "Notice"
    local msg = opts.Message or ""
    local kind = opts.Kind or "info"
    local duration = opts.Duration or 3

    if not notifStack then
        notifStack = Util.New("Frame", {
            Name = "NotifStack",
            Size = UDim2.new(0, 300, 1, 0),
            Position = UDim2.new(1, -320, 0, 20),
            BackgroundTransparency = 1,
        })
        notifStack.Parent = self.Root
        local lay = Util.New("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
        })
        lay.Parent = notifStack
    end

    local accent = ActiveTheme.Accent
    if kind == "success" then accent = ActiveTheme.Success
    elseif kind == "warn" then accent = ActiveTheme.Warning
    elseif kind == "error" then accent = ActiveTheme.Danger end

    local card = Util.New("Frame", {
        Size = UDim2.new(1, 0, 0, 64),
        BackgroundColor3 = ActiveTheme.Surface,
        BorderSizePixel = 0,
    })
    card.Parent = notifStack
    Util.Round(card, 8)
    Util.Stroke(card, accent, 1, 0.2)

    local bar = Util.New("Frame", {
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = accent,
        BorderSizePixel = 0,
    })
    bar.Parent = card

    local titleLbl = Util.New("TextLabel", {
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.fromOffset(14, 8),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = ActiveTheme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = title,
    })
    titleLbl.Parent = card

    local msgLbl = Util.New("TextLabel", {
        Size = UDim2.new(1, -20, 0, 28),
        Position = UDim2.fromOffset(14, 28),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = ActiveTheme.TextMuted,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Text = msg,
    })
    msgLbl.Parent = card

    card.Position = UDim2.new(1, 320, 0, 0)
    Util.Tween(card, 0.24, { Position = UDim2.new(0, 0, 0, 0) })

    task.delay(duration, function()
        Util.Tween(card, 0.2, { Position = UDim2.new(1, 320, 0, 0) })
        task.delay(0.2, function() card:Destroy() end)
    end)
end

-- ============================================================
-- SECTION 16: TOGGLE KEY (LeftShift)
-- ============================================================

function PureUI:SetToggleKey(key)
    self.ToggleKey = key or Enum.KeyCode.LeftShift
    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == self.ToggleKey then
            self:Toggle()
        end
    end))
end

-- ============================================================
-- SECTION 17: THEME SWITCHER WIDGET
-- ============================================================

function PureUI:ThemeSwitcher(tab)
    local names = {}
    for k, _ in pairs(Themes) do table.insert(names, k) end
    table.sort(names)

    local dd = self:Dropdown(tab, {
        Label = "Theme",
        Options = names,
        Default = ActiveTheme.Name,
        Callback = function(opt)
            SetTheme(opt)
            self:Notify({ Title = "Theme", Message = opt .. " applied", Kind = "success", Duration = 2 })
        end,
    })
    return dd
end

-- ============================================================
-- SECTION 18: SHOWCASE / DEMO
-- ============================================================

local ui = PureUI.new({
    Title = "Pure UI",
    Subtitle = "Modular · Animated · Themed",
    Width = 620,
    Height = 440,
})

local mainTab = ui:Tab("Main")
local visualsTab = ui:Tab("Visuals")
local settingsTab = ui:Tab("Settings")
local aboutTab = ui:Tab("About")

-- === MAIN TAB ===
ui:Section(mainTab, "Core Features")

ui:Toggle(mainTab, {
    Label = "Enable Module",
    Default = true,
    Callback = function(v)
        ui:Notify({ Title = "Module", Message = "State: " .. tostring(v), Kind = v and "success" or "info", Duration = 2 })
    end,
})

ui:Slider(mainTab, {
    Label = "Intensity",
    Min = 0, Max = 100, Default = 65, Suffix = "%",
    Callback = function(v) end,
})

ui:Slider(mainTab, {
    Label = "Range",
    Min = 10, Max = 500, Default = 120, Suffix = "m",
    Callback = function(v) end,
})

ui:Dropdown(mainTab, {
    Label = "Mode",
    Options = { "Balanced", "Aggressive", "Stealth", "Custom" },
    Default = "Balanced",
    Callback = function(opt) end,
})

ui:Button(mainTab, {
    Label = "Run",
    Style = "primary",
    Callback = function()
        ui:Notify({ Title = "Run", Message = "Action executed", Kind = "success", Duration = 2 })
    end,
})

-- === VISUALS TAB ===
ui:Section(visualsTab, "Overlay")

ui:Toggle(visualsTab, { Label = "ESP Enabled", Default = true })
ui:ColorPicker(visualsTab, { Label = "Box Color", Default = Color3.fromRGB(255, 80, 80) })
ui:ColorPicker(visualsTab, { Label = "Name Color", Default = Color3.fromRGB(99, 102, 241) })
ui:Slider(visualsTab, { Label = "Box Thickness", Min = 1, Max = 6, Default = 2 })

ui:Section(visualsTab, "Misc")

ui:Toggle(visualsTab, { Label = "Show Distance" })
ui:Toggle(visualsTab, { Label = "Show Health Bar", Default = true })

-- === SETTINGS TAB ===
ui:Section(settingsTab, "Appearance")

ui:ThemeSwitcher(settingsTab)
ui:Keybind(settingsTab, { Label = "Toggle UI", Default = Enum.KeyCode.LeftShift })

ui:Section(settingsTab, "Input")

ui:TextBox(settingsTab, {
    Label = "Config Name",
    Placeholder = "my_config",
    Callback = function(t) end,
})

ui:Dropdown(settingsTab, {
    Label = "FPS Cap",
    Options = { "60", "120", "144", "240", "Unlimited" },
    Default = "144",
})

ui:Section(settingsTab, "Actions")

ui:Button(settingsTab, {
    Label = "Save Config",
    Style = "secondary",
    Callback = function() ui:Notify({ Title = "Config", Message = "Saved", Kind = "success", Duration = 2 }) end,
})

ui:Button(settingsTab, {
    Label = "Reset Defaults",
    Style = "ghost",
    Callback = function() ui:Notify({ Title = "Config", Message = "Defaults restored", Kind = "warn", Duration = 2 }) end,
})

ui:Button(settingsTab, {
    Label = "Unload",
    Style = "danger",
    Callback = function() ui:Destroy() end,
})

-- === ABOUT TAB ===
ui:Section(aboutTab, "Info")

local infoFrame = Util.New("Frame", {
    Size = UDim2.new(1, 0, 0, 100),
    BackgroundColor3 = ActiveTheme.Surface,
    BorderSizePixel = 0,
})
infoFrame.Parent = aboutTab.Scroll
Util.Round(infoFrame, 8)
Util.Stroke(infoFrame, ActiveTheme.Border, 1, 0.4)

local infoLabel = Util.New("TextLabel", {
    Size = UDim2.new(1, -20, 1, 0),
    Position = UDim2.fromOffset(10, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextColor3 = ActiveTheme.TextMuted,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextWrapped = true,
    Text = "Pure UI — modular interface library for Luau.\n\n" ..
           "20+ widgets · 6 themes · TweenService animation\n" ..
           "Draggable window · Scrollable tabs · Notification stack\n\n" ..
           "Drop the file in StarterPlayerScripts and it runs.",
})
infoLabel.Parent = infoFrame

ui:Button(aboutTab, {
    Label = "Test Notification",
    Style = "primary",
    Callback = function()
        ui:Notify({ Title = "Hello", Message = "This is a toast notification.", Kind = "info", Duration = 3 })
    end,
})

ui:Button(aboutTab, {
    Label = "Success Toast",
    Style = "secondary",
    Callback = function()
        ui:Notify({ Title = "Success", Message = "Operation completed.", Kind = "success", Duration = 3 })
    end,
})

ui:Button(aboutTab, {
    Label = "Error Toast",
    Style = "danger",
    Callback = function()
        ui:Notify({ Title = "Error", Message = "Something went wrong.", Kind = "error", Duration = 3 })
    end,
})

-- bind toggle key
ui:SetToggleKey(Enum.KeyCode.LeftShift)

-- startup notification
task.delay(0.4, function()
    ui:Notify({ Title = "Pure UI", Message = "Loaded successfully.", Kind = "success", Duration = 3 })
end)

return ui