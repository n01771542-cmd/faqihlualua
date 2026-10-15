local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
if not player then
    warn("[Sena UI Demo] Run this as a LocalScript.")
    return
end
local playerGui = player:WaitForChild("PlayerGui")
local GUI_NAME = "SenaUIReconstructTest"
local previous = playerGui:FindFirstChild(GUI_NAME)
if previous then previous:Destroy() end
local Theme = {
    background = Color3.fromRGB(10, 12, 16),
    surface = Color3.fromRGB(22, 22, 27),
    surfaceHi = Color3.fromRGB(32, 34, 42),
    cardBg = Color3.fromRGB(18, 18, 24),
    accent = Color3.fromRGB(26, 147, 250),
    accentLight = Color3.fromRGB(80, 190, 255),
    stroke = Color3.fromRGB(48, 50, 60),
    text = Color3.fromRGB(235, 236, 245),
    muted = Color3.fromRGB(156, 160, 174),
    btnBg = Color3.fromRGB(30, 30, 38),
    on = Color3.fromRGB(26, 147, 250),
    off = Color3.fromRGB(55, 57, 66),
    white = Color3.fromRGB(255, 255, 255),
}
local function make(className, props, parent)
    local obj = Instance.new(className)
    for key, value in pairs(props or {}) do obj[key] = value end
    obj.Parent = parent
    return obj
end
local function corner(parent, radius)
    make("UICorner", {CornerRadius = UDim.new(0, radius or 7)}, parent)
end
local function stroke(parent, color, thickness, transparency)
    return make("UIStroke", {
        Color = color or Theme.stroke,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
    }, parent)
end
local function padding(parent, top, bottom, left, right)
    make("UIPadding", {
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
    }, parent)
end
local screen = make("ScreenGui", {
    Name = GUI_NAME, ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 100,
}, playerGui)
local main = make("Frame", {
    Name = "MainWindow", Size = UDim2.fromOffset(540, 380),
    Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = Theme.background, BorderSizePixel = 0, Active = true,
}, screen)
corner(main, 15)
stroke(main, Color3.fromRGB(77, 132, 190), 1.2)
local scale = make("UIScale", {Scale = 1}, main)
local mainGradient = make("UIGradient", {
    Rotation = 90,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(17, 20, 28)),
        ColorSequenceKeypoint.new(0.48, Color3.fromRGB(10, 12, 16)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 9, 13)),
    }),
}, main)
local inset = make("Frame", {
    Name = "InsetBorder", Size = UDim2.new(1, -8, 1, -8),
    Position = UDim2.fromOffset(4, 4), BackgroundTransparency = 1,
    BorderSizePixel = 0, ZIndex = 0,
}, main)
corner(inset, 12)
stroke(inset, Color3.fromRGB(55, 67, 86), 1, 0.72)
local topGlow = make("Frame", {
    Name = "TopGlow", Size = UDim2.new(0.48, 0, 0, 2),
    Position = UDim2.new(0.26, 0, 0, 0), BackgroundColor3 = Theme.accentLight,
    BorderSizePixel = 0, ZIndex = 5,
}, main)
corner(topGlow, 2)
make("UIGradient", {
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 1),
    }),
}, topGlow)
local header = make("Frame", {
    Name = "Header", Size = UDim2.new(1, 0, 0, 48),
    BackgroundTransparency = 1, Active = true,
}, main)
local logo = make("TextLabel", {
    Name = "Logo", Size = UDim2.fromOffset(32, 32), Position = UDim2.fromOffset(12, 8),
    BackgroundColor3 = Theme.surfaceHi, Text = "S", Font = Enum.Font.GothamBlack,
    TextSize = 18, TextColor3 = Theme.accentLight,
}, header)
corner(logo, 8)
stroke(logo, Theme.stroke, 1)
make("TextLabel", {
    Name = "Title", Size = UDim2.fromOffset(200, 32), Position = UDim2.fromOffset(52, 8),
    BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Theme.text, Text = "Sena BETA |",
}, header)
make("TextLabel", {
    Name = "Subtitle", Size = UDim2.fromOffset(140, 32), Position = UDim2.fromOffset(255, 8),
    BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Theme.muted,
    Text = "Steal An Egg · UI Demo",
}, header)
local statusBadge = make("Frame", {
    Name = "StatusBadge", Size = UDim2.fromOffset(72, 22),
    Position = UDim2.new(1, -126, 0, 13), BackgroundColor3 = Color3.fromRGB(15, 42, 36),
    BorderSizePixel = 0,
}, header)
corner(statusBadge, 11)
stroke(statusBadge, Color3.fromRGB(35, 112, 87), 1, 0.25)
local statusDot = make("Frame", {
    Name = "StatusDot", Size = UDim2.fromOffset(6, 6),
    Position = UDim2.fromOffset(9, 8), BackgroundColor3 = Color3.fromRGB(80, 230, 155),
    BorderSizePixel = 0,
}, statusBadge)
corner(statusDot, 3)
make("TextLabel", {
    Name = "StatusText", Size = UDim2.new(1, -22, 1, 0), Position = UDim2.fromOffset(19, 0),
    BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 9,
    TextColor3 = Color3.fromRGB(135, 240, 190), Text = "DEMO MODE",
}, statusBadge)
local closeButton = make("TextButton", {
    Name = "CloseBtn", Size = UDim2.fromOffset(30, 30),
    Position = UDim2.new(1, -42, 0, 9), BackgroundColor3 = Theme.btnBg,
    Text = "✕", Font = Enum.Font.GothamBold, TextSize = 13,
    TextColor3 = Theme.text, AutoButtonColor = true,
}, header)
corner(closeButton, 6)
stroke(closeButton, Theme.stroke, 1)
make("Frame", {
    Name = "HeaderLine", Size = UDim2.new(1, -24, 0, 1),
    Position = UDim2.new(0, 12, 0, 47), BackgroundColor3 = Theme.stroke,
    BorderSizePixel = 0,
}, main)
local body = make("Frame", {
    Name = "Body", Size = UDim2.new(1, -24, 1, -56),
    Position = UDim2.fromOffset(12, 52), BackgroundTransparency = 1,
}, main)
local sidebar = make("ScrollingFrame", {
    Name = "Sidebar", Size = UDim2.new(0, 122, 1, 0),
    BackgroundColor3 = Theme.surface, BorderSizePixel = 0,
    ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.accent,
    AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
}, body)
corner(sidebar, 8)
stroke(sidebar, Color3.fromRGB(42, 47, 59), 1, 0.25)
make("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(25, 27, 35), Color3.fromRGB(16, 17, 22))}, sidebar)
padding(sidebar, 6, 6, 6, 6)
make("UIListLayout", {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder}, sidebar)
local content = make("Frame", {
    Name = "Content", Position = UDim2.new(0, 130, 0, 0),
    Size = UDim2.new(1, -130, 1, 0), BackgroundTransparency = 1,
}, body)
local contentTitle = make("TextLabel", {
    Name = "ContentTitle", Size = UDim2.new(1, 0, 0, 24),
    BackgroundTransparency = 1, ZIndex = 2, Font = Enum.Font.GothamBold, TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Theme.text, Text = "",
}, content)
local contentBackplate = make("Frame", {
    Name = "ContentBackplate", Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(),
    BackgroundColor3 = Color3.fromRGB(12, 13, 18), BorderSizePixel = 0, ZIndex = 0,
}, content)
corner(contentBackplate, 8)
stroke(contentBackplate, Color3.fromRGB(35, 39, 49), 1, 0.35)
make("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(15, 17, 23), Color3.fromRGB(10, 11, 15))}, contentBackplate)
local contentScroll = make("ScrollingFrame", {
    Name = "ContentScroll", Position = UDim2.fromOffset(8, 32),
    Size = UDim2.new(1, -8, 1, -36), BackgroundTransparency = 1,
    BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.accent,
    AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
}, content)
padding(contentScroll, 2, 4, 0, 4)
make("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, contentScroll)
local tabs, tabButtons = {}, {}
local activeTab
local function registerComponent(tabId, object)
    object.LayoutOrder = #tabs[tabId].components + 1
    object.Parent = nil
    table.insert(tabs[tabId].components, object)
    return object
end
local function clearContent()
    for _, tab in pairs(tabs) do
        for _, component in ipairs(tab.components) do
            if component.Parent == contentScroll then component.Parent = nil end
        end
    end
end
local function switchTab(tabId)
    if activeTab == tabId then return end
    local tab = tabs[tabId]
    if not tab then return end
    activeTab = tabId
    clearContent()
    contentTitle.Text = string.upper(tab.name)
    for _, component in ipairs(tab.components) do component.Parent = contentScroll end
    for id, data in pairs(tabButtons) do
        local selected = id == tabId
        data.frame.BackgroundColor3 = selected and Theme.surfaceHi or Theme.surface
        data.label.TextColor3 = selected and Theme.text or Theme.muted
        data.indicator.Visible = selected
        data.stroke.Enabled = selected
    end
    contentScroll.CanvasPosition = Vector2.zero
end
local function createTab(name, order)
    local id = name:lower():gsub("%s+", "_")
    local button = make("TextButton", {
        Name = "Tab_" .. id, Size = UDim2.new(1, 0, 0, 29),
        BackgroundColor3 = Theme.surface, Text = "", LayoutOrder = order, AutoButtonColor = false,
    }, sidebar)
    corner(button, 6)
    local outline = stroke(button, Theme.accent, 1)
    outline.Enabled = false
    local indicator = make("Frame", {
        Size = UDim2.fromOffset(3, 17), Position = UDim2.fromOffset(4, 6),
        BackgroundColor3 = Theme.accent, BorderSizePixel = 0, Visible = false,
    }, button)
    corner(indicator, 2)
    local iconMap = {
        admin_abuse = "✦", main = "⌂", auto = "⟳", pets = "◇", events = "✧",
        misc = "⚙", steal_players = "⇄", live_chat = "☷", donate = "♡",
        private_server = "▣", visual = "◈",
    }
    local icon = make("TextLabel", {
        Name = "TabIcon", Size = UDim2.fromOffset(16, 32), Position = UDim2.fromOffset(8, 0),
        BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13,
        TextColor3 = Theme.accentLight, Text = iconMap[id] or "•",
    }, button)
    local label = make("TextLabel", {
        Size = UDim2.new(1, -25, 1, 0), Position = UDim2.fromOffset(25, 0),
        BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Theme.muted,
        TextTruncate = Enum.TextTruncate.AtEnd, Text = name,
    }, button)
    tabs[id] = {name = name, components = {}}
    tabButtons[id] = {frame = button, label = label, indicator = indicator, stroke = outline}
    button.MouseEnter:Connect(function()
        if activeTab ~= id then
            TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(29, 31, 39)}):Play()
        end
    end)
    button.MouseLeave:Connect(function()
        if activeTab ~= id then
            TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = Theme.surface}):Play()
        end
    end)
    button.Activated:Connect(function() switchTab(id) end)
    return id
end
local function notify(title, message)
    print(("[Sena UI Demo] %s: %s"):format(title, tostring(message)))
end
local function addSection(tabId, title, isSub)
    local frame = make("Frame", {
        Name = (isSub and "SubSection_" or "Section_") .. title:gsub("%s+", "_"),
        Size = UDim2.new(1, -4, 0, isSub and 20 or 24), BackgroundTransparency = 1,
    })
    local rail = make("Frame", {
        Name = "SectionAccent",
        Size = UDim2.fromOffset(isSub and 2 or 3, isSub and 10 or 13),
        Position = UDim2.fromOffset(isSub and 1 or 0, isSub and 5 or 5),
        BackgroundColor3 = isSub and Color3.fromRGB(83, 135, 190) or Theme.accent,
        BorderSizePixel = 0,
    }, frame)
    corner(rail, 2)
    make("TextLabel", {
        Name = "SectionTitle",
        Size = UDim2.new(1, -18, 1, 0), Position = UDim2.fromOffset(isSub and 9 or 8, 0),
        BackgroundTransparency = 1, Font = isSub and Enum.Font.GothamMedium or Enum.Font.GothamBold,
        TextSize = isSub and 9 or 10, TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = isSub and Color3.fromRGB(153, 169, 192) or Color3.fromRGB(210, 220, 236),
        Text = isSub and title or string.upper(title),
    }, frame)
    local line = make("Frame", {
        Name = "SectionHairline",
        Size = UDim2.new(1, -10, 0, 1),
        Position = UDim2.new(0, 8, 1, -1),
        BackgroundColor3 = Color3.fromRGB(48, 57, 72),
        BackgroundTransparency = isSub and 0.72 or 0.48,
        BorderSizePixel = 0,
    }, frame)
    return registerComponent(tabId, frame)
end
local function addToggle(tabId, title, desc, default)
    local frame = make("Frame", {
        Name = "Toggle_" .. title:gsub("%s+", "_"), Size = UDim2.new(1, -4, 0, 44),
        BackgroundColor3 = Theme.cardBg, BorderSizePixel = 0,
    })
    corner(frame, 6); stroke(frame, Theme.stroke, 1, 0.28)
    make("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new(Color3.fromRGB(23, 24, 31), Color3.fromRGB(16, 17, 22)),
    }, frame)
    local edge = make("Frame", {
        Name = "AccentEdge", Size = UDim2.new(0, 2, 1, -14), Position = UDim2.fromOffset(0, 7),
        BackgroundColor3 = Theme.accent, BackgroundTransparency = 0.35, BorderSizePixel = 0,
    }, frame)
    corner(edge, 2)
    make("TextLabel", {
        Size = UDim2.new(1, -80, 0, 16), Position = UDim2.fromOffset(10, 6),
        BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        TextColor3 = Theme.text, Text = title,
    }, frame)
    make("TextLabel", {
        Size = UDim2.new(1, -80, 0, 14), Position = UDim2.fromOffset(10, 23),
        BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        TextColor3 = Theme.muted, Text = desc or "",
    }, frame)
    local state = default == true
    local toggle = make("TextButton", {
        Size = UDim2.fromOffset(44, 22), Position = UDim2.new(1, -54, 0.5, -11),
        BackgroundColor3 = state and Theme.on or Theme.off, Text = "", AutoButtonColor = false,
    }, frame)
    corner(toggle, 11)
    local knob = make("Frame", {
        Size = UDim2.fromOffset(18, 18),
        Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
        BackgroundColor3 = Theme.white, BorderSizePixel = 0,
    }, toggle)
    corner(knob, 9)
    toggle.Activated:Connect(function()
        state = not state
        toggle.BackgroundColor3 = state and Theme.on or Theme.off
        knob.Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        notify(title, state and "ON (demo only)" or "OFF (demo only)")
    end)
    return registerComponent(tabId, frame)
end
local function addButton(tabId, title, desc)
    local frame = make("Frame", {
        Name = "Button_" .. title:gsub("%s+", "_"), Size = UDim2.new(1, -4, 0, 40),
        BackgroundColor3 = Theme.cardBg, BorderSizePixel = 0,
    })
    corner(frame, 6); stroke(frame, Theme.stroke, 1, 0.28)
    make("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(23, 24, 31), Color3.fromRGB(16, 17, 22))}, frame)
    make("TextLabel", {
        Size = UDim2.new(1, -90, 0, 16), Position = UDim2.fromOffset(10, 5),
        BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        TextColor3 = Theme.text, Text = title,
    }, frame)
    make("TextLabel", {
        Size = UDim2.new(1, -90, 0, 12), Position = UDim2.fromOffset(10, 22),
        BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        TextColor3 = Theme.muted, Text = desc or "",
    }, frame)
    local btn = make("TextButton", {
        Size = UDim2.fromOffset(70, 26), Position = UDim2.new(1, -80, 0.5, -13),
        BackgroundColor3 = Theme.accent, Text = "TEST", Font = Enum.Font.GothamBold,
        TextSize = 10, TextColor3 = Theme.white, AutoButtonColor = true,
    }, frame)
    corner(btn, 6)
    btn.Activated:Connect(function() notify(title, "clicked (demo only)") end)
    return registerComponent(tabId, frame), btn
end
local function addDropdown(tabId, title, desc, options, multi, default)
    options = options or {}
    local selected = {}
    if type(default) == "table" then
        for _, value in ipairs(default) do selected[value] = true end
    elseif default ~= nil then selected[default] = true end
    local frame = make("Frame", {
        Name = "Dropdown_" .. title:gsub("%s+", "_"), Size = UDim2.new(1, -4, 0, 44),
        BackgroundColor3 = Theme.cardBg, BorderSizePixel = 0, ClipsDescendants = false, ZIndex = 2,
    })
    corner(frame, 6); stroke(frame, Theme.stroke, 1, 0.28)
    make("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(23, 24, 31), Color3.fromRGB(16, 17, 22))}, frame)
    make("TextLabel", {
        Size = UDim2.new(0.58, -10, 0, 16), Position = UDim2.fromOffset(10, 6),
        BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        TextColor3 = Theme.text, Text = title, ZIndex = 3,
    }, frame)
    make("TextLabel", {
        Size = UDim2.new(0.58, -10, 0, 12), Position = UDim2.fromOffset(10, 23),
        BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        TextColor3 = Theme.muted, Text = desc or "", ZIndex = 3,
    }, frame)
    local function summary()
        local names = {}
        for _, option in ipairs(options) do
            if selected[option] then table.insert(names, tostring(option)) end
        end
        if #names == 0 then return "Select..." end
        if multi and #names > 1 then return tostring(#names) .. " selected" end
        return names[1]
    end
    local btn = make("TextButton", {
        Size = UDim2.fromOffset(130, 26), Position = UDim2.new(1, -140, 0.5, -13),
        BackgroundColor3 = Theme.btnBg, Text = summary(), Font = Enum.Font.GothamBold,
        TextSize = 10, TextColor3 = Theme.text, TextTruncate = Enum.TextTruncate.AtEnd,
        AutoButtonColor = true, ZIndex = 4,
    }, frame)
    corner(btn, 6); stroke(btn, Theme.stroke, 1)
    local popup
    btn.Activated:Connect(function()
        if popup then popup:Destroy(); popup = nil; return end
        popup = make("Frame", {
            Name = "OptionsPopup",
            Size = UDim2.fromOffset(130, math.min(#options * 24 + 8, 168)),
            Position = UDim2.new(1, -140, 0.5, 16),
            BackgroundColor3 = Theme.surface, BorderSizePixel = 0, ZIndex = 20,
        }, frame)
        corner(popup, 6); stroke(popup, Theme.accent, 1)
        local scroll = make("ScrollingFrame", {
            Size = UDim2.new(1, -4, 1, -4), Position = UDim2.fromOffset(2, 2),
            BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
            AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 21,
        }, popup)
        make("UIListLayout", {Padding = UDim.new(0, 2)}, scroll)
        for _, option in ipairs(options) do
            local optionBtn = make("TextButton", {
                Size = UDim2.new(1, -2, 0, 22),
                BackgroundColor3 = selected[option] and Theme.surfaceHi or Theme.btnBg,
                Text = (selected[option] and "✓ " or "") .. tostring(option),
                Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Theme.text,
                TextTruncate = Enum.TextTruncate.AtEnd, AutoButtonColor = true, ZIndex = 22,
            }, scroll)
            corner(optionBtn, 4)
            optionBtn.Activated:Connect(function()
                if multi then
                    selected[option] = not selected[option] or nil
                    optionBtn.Text = (selected[option] and "✓ " or "") .. tostring(option)
                    optionBtn.BackgroundColor3 = selected[option] and Theme.surfaceHi or Theme.btnBg
                    btn.Text = summary()
                else
                    selected = {[option] = true}
                    btn.Text = summary()
                    popup:Destroy()
                    popup = nil
                end
                notify(title, summary())
            end)
        end
    end)
    return registerComponent(tabId, frame)
end
local function addSlider(tabId, title, desc, minValue, maxValue, default)
    maxValue = math.max(maxValue, minValue + 1)
    local value = math.clamp(tonumber(default) or minValue, minValue, maxValue)
    local frame = make("Frame", {
        Name = "Slider_" .. title:gsub("%s+", "_"), Size = UDim2.new(1, -4, 0, 50),
        BackgroundColor3 = Theme.cardBg, BorderSizePixel = 0,
    })
    corner(frame, 6); stroke(frame, Theme.stroke, 1, 0.28)
    make("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(23, 24, 31), Color3.fromRGB(16, 17, 22))}, frame)
    make("TextLabel", {
        Size = UDim2.new(0.75, -10, 0, 16), Position = UDim2.fromOffset(10, 6),
        BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        TextColor3 = Theme.text, Text = title,
    }, frame)
    local valueLabel = make("TextLabel", {
        Size = UDim2.fromOffset(50, 16), Position = UDim2.new(1, -60, 0, 6),
        BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = Theme.accent, Text = tostring(value),
    }, frame)
    make("TextLabel", {
        Size = UDim2.new(1, -20, 0, 10), Position = UDim2.fromOffset(10, 20),
        BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        TextColor3 = Theme.muted, Text = desc or "",
    }, frame)
    local bar = make("TextButton", {
        Size = UDim2.new(1, -20, 0, 6), Position = UDim2.new(0, 10, 1, -12),
        BackgroundColor3 = Theme.btnBg, Text = "", AutoButtonColor = false,
    }, frame)
    corner(bar, 3)
    local fill = make("Frame", {
        Size = UDim2.new((value - minValue) / (maxValue - minValue), 0, 1, 0),
        BackgroundColor3 = Theme.accent, BorderSizePixel = 0,
    }, bar)
    corner(fill, 3)
    local dragging = false
    local function update(x)
        local ratio = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        value = math.floor(minValue + ratio * (maxValue - minValue) + 0.5)
        fill.Size = UDim2.new((value - minValue) / (maxValue - minValue), 0, 1, 0)
        valueLabel.Text = tostring(value)
        notify(title, value)
    end
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input.Position.X)
        end
    end)
    local moveConn = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input.Position.X)
        end
    end)
    local endConn = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    screen.Destroying:Connect(function() moveConn:Disconnect(); endConn:Disconnect() end)
    return registerComponent(tabId, frame)
end
local function addInput(tabId, title, desc, placeholder, default)
    local frame = make("Frame", {
        Name = "Input_" .. title:gsub("%s+", "_"), Size = UDim2.new(1, -4, 0, 44),
        BackgroundColor3 = Theme.cardBg, BorderSizePixel = 0,
    })
    corner(frame, 6); stroke(frame, Theme.stroke, 1, 0.28)
    make("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(23, 24, 31), Color3.fromRGB(16, 17, 22))}, frame)
    make("TextLabel", {
        Size = UDim2.new(0.55, -10, 0, 16), Position = UDim2.fromOffset(10, 6),
        BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        TextColor3 = Theme.text, Text = title,
    }, frame)
    make("TextLabel", {
        Size = UDim2.new(0.55, -10, 0, 12), Position = UDim2.fromOffset(10, 23),
        BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        TextColor3 = Theme.muted, Text = desc or "",
    }, frame)
    local box = make("TextBox", {
        Size = UDim2.fromOffset(130, 26), Position = UDim2.new(1, -140, 0.5, -13),
        BackgroundColor3 = Theme.btnBg, Text = default or "", PlaceholderText = placeholder or "Type...",
        Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Theme.text,
        PlaceholderColor3 = Theme.muted, ClearTextOnFocus = false,
    }, frame)
    corner(box, 6); stroke(box, Theme.stroke, 1)
    box.FocusLost:Connect(function(enterPressed)
        if enterPressed then notify(title, box.Text) end
    end)
    return registerComponent(tabId, frame)
end
local function addParagraph(tabId, title, text)
    local frame = make("Frame", {
        Name = "Paragraph_" .. title:gsub("%s+", "_"), Size = UDim2.new(1, -4, 0, 50),
        BackgroundColor3 = Theme.cardBg, BorderSizePixel = 0,
    })
    corner(frame, 6); stroke(frame, Theme.stroke, 1, 0.28)
    make("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(23, 24, 31), Color3.fromRGB(16, 17, 22))}, frame)
    make("TextLabel", {
        Size = UDim2.new(1, -20, 0, 16), Position = UDim2.fromOffset(10, 6),
        BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Theme.text, Text = title,
    }, frame)
    make("TextLabel", {
        Size = UDim2.new(1, -20, 0, 26), Position = UDim2.fromOffset(10, 23),
        BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true, TextTruncate = Enum.TextTruncate.AtEnd,
        TextColor3 = Theme.muted, Text = text,
    }, frame)
    return registerComponent(tabId, frame)
end
local function buildTab(name, order, builder)
    local id = createTab(name, order)
    builder(id)
    return id
end
local function section(id, title) addSection(id, title, false) end
local function sub(id, title) addSection(id, title, true) end
local function toggle(id, title, desc, default) addToggle(id, title, desc, default) end
local function button(id, title, desc) return addButton(id, title, desc) end
local function dropdown(id, title, desc, opts, multi, default) addDropdown(id, title, desc, opts, multi, default) end
local function slider(id, title, desc, minV, maxV, default) addSlider(id, title, desc, minV, maxV, default) end
local function input(id, title, desc, placeholder, default) addInput(id, title, desc, placeholder, default) end
local function paragraph(id, title, text) addParagraph(id, title, text) end
local rarities = {"Common","Uncommon","Rare","Epic","Legendary","Mythic","Cosmic","Secret","Eternal","Divine"}
local areas = {"None","Forest","Lake","Jungle","Desert","Snow","Volcano","Abyss Ocean","Prehistoric","Cosmic","Cherry Blossom","Titan Temple","Light Dark","Enchanted Forest"}
local eggs = {"None","Dog","Cat","Unicorn","Dragon","Phoenix","Kitsune","Mosasaurus","Oni Tiger","Lunar Dragon","Gorilla King","Ice Dragon","Godzilla","Pegasus","ArchAngel","Skeleton Horse"}
local mutations = {"Golden","Rainbow","Shocked","Frozen","Burnt","Boss"}
local species = {"None","Dog","Cat","Unicorn","Dragon","Phoenix","Kitsune","Mosasaurus","Oni Tiger","Lunar Dragon"}
local modes = {"Low Speed User","High Speed User Normal","High Speed User (Fly)","Zig-Zag High Speed User"}
local priorities = {"Rarity","Highest Value","Heaviest"}
local butterflyTiers = {"Radiant","Amethyst","Sapphire","Emerald"}
local butterflyModes = {"Tween to Butterfly","Stand","Zigzag","Circle"}
local recipes = {"All Recipes","For Essence (shortfall only)","Emerald to Sapphire","Sapphire to Amethyst","Amethyst to Radiant"}
local shopItems = {"CashBooster","SpeedBoost","TreadmillBoost","MutationToken","RacingBat"}
local banners = {"Biohazard Pets","Experimental Pets","Unstable DNA"}
local waypoints = {"Respawn Point","Forest","Lake","Jungle","Desert","Snow","Volcano","Abyss Ocean","Prehistoric","Cosmic","Cherry Blossom","Titan Temple","Light Dark","Enchanted Forest"}
buildTab("Admin Abuse", 1, function(id)
    section(id, "Capture The Egg")
    toggle(id, "Auto Steal Capture", "Demo toggle only; no event action.", false)
    section(id, "Movement")
    toggle(id, "Admin Abuse Boost", "Demo toggle only.", false)
    toggle(id, "Fly For Capture", "Demo toggle only.", false)
    toggle(id, "Instant Grab", "Demo toggle only.", false)
    toggle(id, "Infinite Jump", "Demo toggle only.", false)
    toggle(id, "Noclip", "Demo toggle only.", false)
    section(id, "Ring Event")
    toggle(id, "Auto Ring Event", "Demo toggle only.", false)
    section(id, "Capture Settings")
    toggle(
        id,
        "Capture Mode",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Capture Range",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Capture Delay",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Capture Priority",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Capture Retry",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Capture Cooldown",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Capture Notifications",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Capture Sound",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Capture Highlight",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Capture Queue",
        "Demo preference only; no game action is connected.",
        false
    )
    section(id, "Movement Controls")
    toggle(
        id,
        "Movement Boost",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Movement Speed",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Movement Duration",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Movement Cooldown",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Movement Safety Check",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Movement Reset On Spawn",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Movement Status Alert",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Movement Keybind",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Movement Toggle Lock",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Movement Preset",
        "Demo preference only; no game action is connected.",
        false
    )
    section(id, "Ring Event Controls")
    toggle(
        id,
        "Ring Event Range",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Ring Event Delay",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Ring Event Retry",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Ring Event Priority",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Ring Event Notifications",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Ring Event Auto Stop",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Ring Event Cooldown",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Ring Event Sound",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Ring Event Highlight",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Ring Event Status",
        "Demo preference only; no game action is connected.",
        false
    )
end)
buildTab("Main", 2, function(id)
    section(id, "Auto Steal")
    toggle(id, "Auto Steal", "Demo only; no game actions.", false)
    toggle(id, "Help Friend", "Demo toggle only.", false)
    button(id, "Egg Checker", "Demo action only.")
    button(id, "Egg Spawn Analyst", "Demo action only.")
    toggle(id, "Aura Bat", "Demo toggle only.", true)
    dropdown(id, "Steal Mode", "Demo selection", modes, false, "High Speed User Normal")
    slider(id, "Low Speed Multiplier", "Demo value only", 1, 10, 5)
    paragraph(id, "Speed Advice", "Demo display only\nRecommended: 4–6")
    section(id, "Egg Filter"); sub(id, "Egg")
    dropdown(id, "Filter By Egg Name", "Demo selection", eggs, true)
    dropdown(id, "Filter By Rarity", "Demo selection", rarities, true)
    sub(id, "Area & Value")
    dropdown(id, "Select Area", "Demo selection", areas, true)
    input(id, "Steal By Value", "Demo input only", "e.g. 500k")
    dropdown(id, "Filter By Mutation", "Demo selection", mutations, true)
    input(id, "Steal By Weight", "Demo input only", "e.g. 12000")
    dropdown(id, "Steal Priority", "Demo selection", priorities, false, "Rarity")
    toggle(id, "Auto Index", "Demo toggle only.", false)
    section(id, "Egg ESP")
    toggle(id, "Egg ESP", "Demo toggle only.", false)
    dropdown(id, "ESP Details", "Demo selection", {"Name","Rarity","Value","Weight","Mutation","Placed Eggs","Icon"}, true)
    dropdown(id, "ESP Min Rarity", "Demo selection", {"Any", table.unpack(rarities)}, false, "Any")
    input(id, "ESP Min Value", "Demo input only", "e.g. 500k")
    toggle(id, "Backpack Value/s", "Demo toggle only.", false)
    section(id, "Steal Webhook")
    toggle(id, "Steal Webhook", "Demo toggle only; no network request.", false)
    input(id, "Webhook URL", "Demo input only; never transmitted.", "Webhook URL")
    toggle(id, "Disconnect Alert", "Demo toggle only.", false)
    sub(id, "Filter")
    dropdown(id, "Notify Rarities", "Demo selection", rarities, true)
    input(id, "Notify Minimum Value", "Demo input only", "e.g. 500k")
    button(id, "Test Webhook", "No webhook is sent.")
    section(id, "Steal Behavior")
    toggle(
        id,
        "Pause When Inventory Full",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Resume When Inventory Has Space",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Skip Already Processed Eggs",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Avoid Duplicate Targets",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Use Target Queue",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Enable Target Validation",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Enable Cooldown",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Enable Retry",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Enable Recovery",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Show Target Status",
        "Demo preference only; no game action is connected.",
        false
    )
    section(id, "Filter Presets")
    toggle(
        id,
        "Preset Common",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Preset Rare",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Preset Legendary",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Preset Mythic",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Preset Divine",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Preset Eternal",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Preset High Value",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Preset Heavy",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Preset Mutation",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Preset Custom",
        "Demo preference only; no game action is connected.",
        false
    )
    section(id, "ESP Appearance")
    toggle(
        id,
        "ESP Show Name",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "ESP Show Rarity",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "ESP Show Value",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "ESP Show Weight",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "ESP Show Mutation",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "ESP Show Distance",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "ESP Show Icon",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "ESP Highlight Target",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "ESP Compact Labels",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "ESP Fade Distance",
        "Demo preference only; no game action is connected.",
        false
    )
    section(id, "Webhook Preferences")
    toggle(
        id,
        "Webhook Notify Steal",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Webhook Notify Rare",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Webhook Notify Value",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Webhook Notify Mutation",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Webhook Include Weight",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Webhook Include Area",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Webhook Include Time",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Webhook Quiet Mode",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Webhook Retry Notice",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Webhook Test Preview",
        "Demo preference only; no game action is connected.",
        false
    )
end)
buildTab("Auto", 3, function(id)
    section(id, "Egg Automation"); sub(id, "Place")
    toggle(id, "Auto Place Egg", "Demo toggle only.", false)
    dropdown(id, "Place Egg Rarity", "Demo selection", rarities, true)
    sub(id, "Hatch")
    toggle(id, "Auto Hatch Egg", "Demo toggle only.", false)
    sub(id, "Mutate")
    dropdown(id, "Select Mutation", "Demo selection", {"Scrambled","Fractured"}, false, "Scrambled")
    dropdown(id, "Mutate Egg Name", "Demo selection", eggs, true)
    dropdown(id, "Mutate Egg Rarity", "Demo selection", rarities, true)
    input(id, "Mutate Min Value", "Demo input only", "e.g. 100k")
    toggle(id, "Retry Until Mutated", "Demo toggle only.", true)
    toggle(id, "Auto Apply Mutation", "Demo toggle only.", false)
    button(id, "Apply Mutation Now", "Demo action only.")
    section(id, "Equip & Collect")
    toggle(id, "Auto Equip Best", "Demo toggle only.", false)
    toggle(id, "Collect Offline Income", "Demo toggle only.", false)
    toggle(id, "Auto Upgrade Base", "Demo toggle only.", false)
    toggle(id, "Auto Claim Almanac", "Demo toggle only.", false)
    button(id, "Upgrade Base Now", "Demo action only.")
    section(id, "Treadmill")
    toggle(id, "Auto Treadmill", "Demo toggle only.", false)
    toggle(id, "Auto Upgrade Treadmill", "Demo toggle only.", false)
    section(id, "Egg Placement Rules")
    toggle(
        id,
        "Place Only Selected Rarity",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Place Only Selected Egg",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Place Avoid Duplicate",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Place Check Capacity",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Place Retry Failed",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Place Delay",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Place Max Per Cycle",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Place Notify Complete",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Place Pause On Full",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Place Reset Queue",
        "Demo preference only; no game action is connected.",
        false
    )
    section(id, "Hatch Rules")
    toggle(
        id,
        "Hatch Only Selected Rarity",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Hatch Check Capacity",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Hatch Skip Locked",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Hatch Retry Failed",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Hatch Delay",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Hatch Max Per Cycle",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Hatch Notify Complete",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Hatch Pause On Full",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Hatch Queue Mode",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Hatch Reset Queue",
        "Demo preference only; no game action is connected.",
        false
    )
    section(id, "Mutation Rules")
    toggle(
        id,
        "Mutation Preserve Favorites",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Mutation Skip Locked",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Mutation Check Value",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Mutation Retry Limit",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Mutation Delay",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Mutation Stop On Match",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Mutation Notify Match",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Mutation Save Preset",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Mutation Load Preset",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Mutation Reset Rules",
        "Demo preference only; no game action is connected.",
        false
    )
    section(id, "Collection Rules")
    toggle(
        id,
        "Collect Check Capacity",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Collect Prioritize Rare",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Collect Prioritize Value",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Collect Skip Full Slots",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Collect Retry Failed",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Collect Delay",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Collect Notify Complete",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Collect Max Per Cycle",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Collect Pause Toggle",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Collect Reset Queue",
        "Demo preference only; no game action is connected.",
        false
    )
end)
buildTab("Pets", 4, function(id)
    section(id, "Pet Selling")
    toggle(id, "Auto Sell Pet", "Demo toggle only.", false); sub(id, "Filter")
    dropdown(id, "Pet Name Filter", "Demo selection", {"None","All",table.unpack(species)}, true)
    dropdown(id, "Pet Rarity Filter", "Demo selection", {"None","All",table.unpack(rarities)}, true)
    input(id, "Sell By Value (max)", "Demo input only", "e.g. 100k")
    section(id, "Egg Selling")
    toggle(id, "Auto Sell Egg", "Demo toggle only.", false)
    dropdown(id, "Egg Rarity Filter", "Demo selection", {"None","All",table.unpack(rarities)}, true)
    input(id, "Sell Egg By Value (max)", "Demo input only", "e.g. 100k")
    section(id, "Pet Favorite")
    toggle(id, "Auto Favorite", "Demo toggle only.", false)
    dropdown(id, "Favorite Rule", "Demo selection", {"Rarity","Species"}, false, "Rarity")
    sub(id, "Only when Rule = Rarity")
    dropdown(id, "Rarities to Keep", "Demo selection", rarities, true)
    sub(id, "Only when Rule = Species")
    dropdown(id, "Species to Keep", "Demo selection", species, true)
    button(id, "Unfavorite Everything", "Demo action only.")
    section(id, "Pet Fusion")
    toggle(id, "Auto Fuse", "Demo toggle only.", false)
    dropdown(id, "Fusion Rule", "Demo selection", {"Any Species","Selected Species"}, false, "Any Species")
    dropdown(id, "Rarities to Fuse", "Demo selection", rarities, true)
    sub(id, "Only when Rule = Selected Species")
    dropdown(id, "Species to Fuse", "Demo selection", species, true)
    section(id, "Selling Rules")
    toggle(
        id,
        "Sell Skip Favorites",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Sell Skip Locked Pets",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Sell Skip Selected Species",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Sell Skip Selected Rarity",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Sell Below Value Only",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Sell Confirm Before Action",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Sell Preview Results",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Sell Notify Complete",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Sell Retry Failed",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Sell Reset Rules",
        "Demo preference only; no game action is connected.",
        false
    )
    section(id, "Favorite Rules")
    toggle(
        id,
        "Favorite Protect Mythic",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Favorite Protect Divine",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Favorite Protect Eternal",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Favorite Protect Selected Species",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Favorite Protect High Value",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Favorite Protect Heavy",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Favorite Auto Rule",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Favorite Notify Changes",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Favorite Preview Rules",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Favorite Reset Rules",
        "Demo preference only; no game action is connected.",
        false
    )
    section(id, "Fusion Rules")
    toggle(
        id,
        "Fusion Skip Favorites",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Fusion Require Same Species",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Fusion Require Same Rarity",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Fusion Preview Results",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Fusion Protect Selected",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Fusion Limit Per Cycle",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Fusion Delay",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Fusion Notify Complete",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Fusion Retry Failed",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Fusion Reset Rules",
        "Demo preference only; no game action is connected.",
        false
    )
end)
buildTab("Events", 5, function(id)
    section(id, "Butterfly Bloom")
    paragraph(id, "Bloom Status", "DEMO STATUS\nNo live event data is loaded.")
    toggle(id, "Auto Claim Net", "Demo toggle only.", false)
    toggle(id, "Auto Catch", "Demo toggle only.", false)
    dropdown(id, "Catch Mode", "Demo selection", butterflyModes, false, "Tween to Butterfly")
    dropdown(id, "Catch Tiers", "Demo selection", butterflyTiers, true)
    toggle(id, "Butterfly ESP", "Demo toggle only.", false)
    sub(id, "Trade & Craft")
    toggle(id, "Auto Trade Up", "Demo toggle only.", false)
    dropdown(id, "Trade Recipe", "Demo selection", recipes, false, "All Recipes")
    toggle(id, "Auto Craft Essence", "Demo toggle only.", false)
    button(id, "Claim Net Now", "Demo action only.")
    button(id, "Trade Up Now", "Demo action only.")
    button(id, "Craft Essence Now", "Demo action only.")
    section(id, "Dr Scramble Event")
    paragraph(id, "About This Event", "Demo only. No event actions are connected.")
    toggle(id, "Auto Buy Shop", "Demo toggle only.", false)
    dropdown(id, "Shop Buy List", "Demo selection", shopItems, true)
    sub(id, "Trade-In")
    toggle(id, "Auto Trade-In", "Demo toggle only.", false)
    toggle(id, "Auto Free Reroll", "Demo toggle only.", false)
    dropdown(id, "Target Banners", "Demo selection", banners, true)
    button(id, "Trade-In Once", "Demo action only.")
    button(id, "Use Free Reroll", "Demo action only.")
    button(id, "Open Trade-In UI", "Demo action only.")
    sub(id, "Boss Fight")
    toggle(id, "Auto Boss", "Demo toggle only.", false)
    paragraph(id, "Boss Status", "Demo status: idle.")
    section(id, "Butterfly Settings")
    toggle(
        id,
        "Butterfly Auto Pause",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Butterfly Prioritize Tier",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Butterfly Ignore Duplicates",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Butterfly Max Range",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Butterfly Retry Failed",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Butterfly Cooldown",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Butterfly Notify Catch",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Butterfly Show Markers",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Butterfly Compact Markers",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Butterfly Reset Rules",
        "Demo preference only; no game action is connected.",
        false
    )
    section(id, "Crafting Settings")
    toggle(
        id,
        "Craft Only Shortfall",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Craft Preserve Radiant",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Craft Check Materials",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Craft Queue Recipes",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Craft Retry Failed",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Craft Delay",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Craft Max Per Cycle",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Craft Notify Complete",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Craft Preview Cost",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Craft Reset Queue",
        "Demo preference only; no game action is connected.",
        false
    )
    section(id, "Boss Settings")
    toggle(
        id,
        "Boss Notify Spawn",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Boss Notify Defeat",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Boss Retry Strategy",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Boss Cooldown",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Boss Status Overlay",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Boss Show Health",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Boss Pause On Low Health",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Boss Target Priority",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Boss Max Attempts",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Boss Reset Rules",
        "Demo preference only; no game action is connected.",
        false
    )
end)
buildTab("Misc", 6, function(id)
    section(id, "Performance")
    toggle(id, "Startup Boost", "Demo toggle only.", true)
    toggle(id, "Boost FPS", "Demo toggle only.", false)
    toggle(id, "Uncap FPS", "Demo toggle only.", false)
    section(id, "Guard")
    toggle(id, "Anti Guard Knockback", "Demo toggle only.", true)
    toggle(id, "Anti Hit Guard", "Demo toggle only.", false)
    section(id, "Windows")
    button(id, "Egg Logs", "Demo action only."); button(id, "Egg Board", "Demo action only.")
    button(id, "Inventory & Base", "Demo action only."); button(id, "Egg Checker", "Demo action only.")
    button(id, "Egg Data & History", "Demo action only."); button(id, "Open All Windows", "Demo action only.")
    section(id, "Blocker")
    toggle(id, "Anti Treadmill", "Demo toggle only.", false)
    section(id, "Server Hop")
    toggle(id, "Hop When Nothing Matches", "Demo toggle only.", false)
    sub(id, "Limits"); slider(id, "Hop Cooldown", "Demo value only", 1, 60, 5)
    section(id, "Roaming")
    dropdown(id, "Waypoint", "Demo selection only", waypoints, false, "Respawn Point")
    button(id, "Teleport To Waypoint", "Demo action only.")
    section(id, "Run Once")
    button(id, "Place Everything Now", "Demo action only.")
    button(id, "Hatch Everything Ready", "Demo action only.")
    button(id, "Sell Pets Now", "Demo action only.")
    button(id, "Sell Eggs Now", "Demo action only.")
    section(id, "Session")
    toggle(id, "Botting Mode", "Demo toggle only.", false)
    toggle(id, "Anti Cutscene", "Demo toggle only.", false)
    button(id, "Rejoin This Server", "Demo action only.")
    local _, unloadButton = button(id, "Stop & Unload", "Closes this demo UI.")
    unloadButton.Activated:Connect(function() screen:Destroy() end)
    section(id, "Player")
    toggle(id, "Anti AFK", "Demo toggle only.", true)
    toggle(id, "Auto Reconnect", "Demo toggle only.", true)
    toggle(id, "Auto Execute (Rejoin)", "Demo toggle only.", false)
    section(id, "Performance Profile")
    toggle(
        id,
        "Performance Low Effects",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Performance Hide Particles",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Performance Reduce Shadows",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Performance Reduce Textures",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Performance Hide Decorations",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Performance Simplify UI",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Performance Show FPS",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Performance Show Ping",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Performance Save Profile",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Performance Reset Profile",
        "Demo preference only; no game action is connected.",
        false
    )
    section(id, "Guard Preferences")
    toggle(
        id,
        "Guard Alert Enabled",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Guard Alert Sound",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Guard Alert Flash",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Guard Alert Cooldown",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Guard Ignore Friends",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Guard Show Range",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Guard Show Status",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Guard Log Events",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Guard Auto Pause Demo",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Guard Reset Preferences",
        "Demo preference only; no game action is connected.",
        false
    )
    section(id, "Session Tools")
    toggle(
        id,
        "Session Show Runtime",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Session Show Server",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Session Show Player Count",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Session Notify Rejoin",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Session Confirm Unload",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Session Save UI State",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Session Restore UI State",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Session Reset UI State",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Session Quiet Mode",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Session Clear Logs",
        "Demo preference only; no game action is connected.",
        false
    )
end)
buildTab("Steal Players", 7, function(id)
    section(id, "Auto Steal")
    toggle(id, "Auto Steal From Players", "Demo toggle only.", false)
    dropdown(id, "Rarity Filter", "Demo selection", rarities, true)
    input(id, "Minimum Value", "Demo input only", "e.g. 500k")
    section(id, "Steal From Specific Player")
    paragraph(id, "Players in this server", "[Demo] Player list is not connected.")
    section(id, "Steal History")
    paragraph(id, "History", "[Demo] No history is loaded.")
    button(id, "Clear History", "Demo action only.")
    section(id, "Player Target Filters")
    toggle(
        id,
        "Target Skip Friends",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Target Skip Whitelist",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Target Skip Low Value",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Target Skip Protected",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Target Require Selected Rarity",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Target Require Minimum Value",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Target Sort By Value",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Target Sort By Rarity",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Target Sort By Name",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Target Reset Filters",
        "Demo preference only; no game action is connected.",
        false
    )
    section(id, "Player List Display")
    toggle(
        id,
        "Player List Show Name",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Player List Show Distance",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Player List Show Egg Count",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Player List Show Value",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Player List Show Status",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Player List Highlight Selected",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Player List Compact Rows",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Player List Search Enabled",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Player List Sort Enabled",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Player List Reset Display",
        "Demo preference only; no game action is connected.",
        false
    )
    section(id, "History Preferences")
    toggle(
        id,
        "History Record Timestamp",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "History Record Player",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "History Record Item",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "History Record Rarity",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "History Record Value",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "History Filter Enabled",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "History Search Enabled",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "History Export Preview",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "History Auto Limit",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "History Reset Preferences",
        "Demo preference only; no game action is connected.",
        false
    )
end)
buildTab("Live Chat", 8, function(id)
    section(id, "Global Chat")
    paragraph(id, "Live Chat", "[Demo] No chat service is connected.")
    section(id, "Chat Display")
    toggle(
        id,
        "Chat Show Timestamp",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Chat Show Username",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Chat Compact Messages",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Chat Wrap Long Messages",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Chat Highlight Mentions",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Chat Show System Messages",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Chat Filter Enabled",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Chat Search Enabled",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Chat Pause Scroll",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Chat Reset Display",
        "Demo preference only; no game action is connected.",
        false
    )
    section(id, "Chat Preferences")
    toggle(
        id,
        "Chat Sound Alerts",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Chat Quiet Mode",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Chat Notification Preview",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Chat Font Scale",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Chat Row Density",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Chat Message Limit",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Chat Timestamp Format",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Chat Username Color",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Chat Reset Preferences",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Chat Clear Local Preview",
        "Demo preference only; no game action is connected.",
        false
    )
end)
buildTab("Donate", 9, function(id)
    section(id, "Support Sena")
    paragraph(id, "Support Card", "[Demo] Donation information is not configured.")
    section(id, "Support Panel")
    toggle(
        id,
        "Support Show Goal",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Support Show Progress",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Support Show Recent Supporters",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Support Show Message",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Support Compact Card",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Support Highlight Goal",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Support Animate Progress",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Support Show Thanks",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Support Refresh Preview",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Support Reset Display",
        "Demo preference only; no game action is connected.",
        false
    )
    section(id, "Display Preferences")
    toggle(
        id,
        "Donate Card Style",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Donate Text Scale",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Donate Show Badge",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Donate Show Footer",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Donate Show Divider",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Donate Show Accent",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Donate Reduce Motion",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Donate Preview Layout",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Donate Restore Layout",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Donate Reset Preferences",
        "Demo preference only; no game action is connected.",
        false
    )
end)
buildTab("Private Server", 10, function(id)
    section(id, "Find Private Server")
    paragraph(id, "Current Server", "DEMO STATUS\nNo server hopping is performed.")
    dropdown(id, "Max Players", "Demo selection", {"1","2","3","4","5"}, false, "2")
    button(id, "Hop Server Now", "Demo action only.")
    toggle(id, "Auto Hop", "Demo toggle only.", false)
    section(id, "Server Search")
    toggle(
        id,
        "Server Search Small Capacity",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Server Search Low Ping",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Server Search Prefer Empty",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Server Search Avoid Full",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Server Search Refresh",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Server Search Sort By Players",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Server Search Sort By Ping",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Server Search Show Region",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Server Search Show Capacity",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Server Search Reset Filters",
        "Demo preference only; no game action is connected.",
        false
    )
    section(id, "Hop Preferences")
    toggle(
        id,
        "Hop Confirm Before Switch",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Hop Notify Before Switch",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Hop Notify After Switch",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Hop Cooldown Enabled",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Hop Retry Failed",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Hop Max Attempts",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Hop Preserve UI State",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Hop Preserve Filters",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Hop Status Overlay",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Hop Reset Preferences",
        "Demo preference only; no game action is connected.",
        false
    )
end)
buildTab("Visual", 11, function(id)
    section(id, "Fish It"); sub(id, "Rods")
    dropdown(id, "Select Rod", "Demo selection", {"Basic Rod","Silver Rod","Golden Rod","Diamond Rod","Mythic Rod","Forgotten Rod"}, false)
    button(id, "Spawn Rod", "Demo only; no item is created.")
    slider(id, "Rod Size", "Demo value only", 5, 20, 10)
    sub(id, "Fish")
    dropdown(id, "Select Fish", "Demo selection", {"Basic Fish","Silver Fish","Golden Fish","Diamond Fish","Mythic Fish","Forgotten Fish"}, false)
    button(id, "Spawn Fish", "Demo only; no item is created.")
    slider(id, "Fish Weight", "Demo value only", 0, 100, 0)
    sub(id, "Manage")
    paragraph(id, "Status", "Idle · demo mode")
    button(id, "Remove All Visual Items", "Demo action only.")
    section(id, "Steal an Egg")
    dropdown(id, "Type", "Demo selection", {"Egg","Pet"}, false, "Egg")
    dropdown(id, "Select Egg / Pet", "Demo selection", eggs, false)
    slider(id, "Size / Flex", "Demo value only", 1, 100, 50)
    button(id, "Hold in Hand", "Demo only; no model is spawned.")
    button(id, "Add to Backpack (Kg)", "Demo only; inventory is unchanged.")
    button(id, "Remove Egg / Pet Visuals", "Demo action only.")
end)
local dragging, dragStart, startPosition = false, nil, nil
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, startPosition = true, input.Position, main.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
local floating = make("TextButton", {
    Name = "FloatingToggle", Size = UDim2.fromOffset(40, 40),
    Position = UDim2.new(0, 16, 0.4, 0), BackgroundColor3 = Theme.background,
    Text = "S", Font = Enum.Font.GothamBlack, TextSize = 18,
    TextColor3 = Theme.accentLight, Visible = false, AutoButtonColor = true,
}, screen)
corner(floating, 10); stroke(floating, Theme.accent, 1.5)
make("UIGradient", {Rotation = 135, Color = ColorSequence.new(Color3.fromRGB(24, 35, 52), Color3.fromRGB(9, 11, 16))}, floating)
floating.MouseEnter:Connect(function()
    TweenService:Create(floating, TweenInfo.new(0.14), {Size = UDim2.fromOffset(43, 43)}):Play()
end)
floating.MouseLeave:Connect(function()
    TweenService:Create(floating, TweenInfo.new(0.14), {Size = UDim2.fromOffset(40, 40)}):Play()
end)
local function setVisible(show)
    if show then
        main.Visible = true
        floating.Visible = false
        scale.Scale = 0.92
        TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
    else
        main.Visible = false
        floating.Visible = true
    end
end
closeButton.Activated:Connect(function() setVisible(false) end)
floating.Activated:Connect(function() setVisible(true) end)
local function updateViewportScale()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    local fitX = (viewport.X - 20) / 600
    local fitY = (viewport.Y - 20) / 430
    scale.Scale = math.clamp(math.min(1, fitX, fitY), 0.48, 1)
end
updateViewportScale()
local cameraConnection
local function bindCamera()
    if cameraConnection then cameraConnection:Disconnect() end
    local camera = workspace.CurrentCamera
    if camera then cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateViewportScale) end
end
bindCamera()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
screen.Destroying:Connect(function()
    if cameraConnection then cameraConnection:Disconnect() end
    section(id, "Visual Styling")
    toggle(
        id,
        "Visual Outline Enabled",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Visual Soft Corners",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Visual Gradient Enabled",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Visual Surface Texture",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Visual Accent Glow",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Visual Compact Labels",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Visual High Contrast",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Visual Reduce Motion",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Visual Reset Appearance",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Visual Preview Appearance",
        "Demo preference only; no game action is connected.",
        false
    )
    section(id, "Item Preview")
    toggle(
        id,
        "Preview Show Name",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Preview Show Rarity",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Preview Show Weight",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Preview Show Size",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Preview Show Mutation",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Preview Rotate Model",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Preview Auto Fit",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Preview Background Grid",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Preview Shadow Enabled",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Preview Reset Settings",
        "Demo preference only; no game action is connected.",
        false
    )
    section(id, "Inventory Preview")
    toggle(
        id,
        "Inventory Show Count",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Inventory Show Capacity",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Inventory Show Weight",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Inventory Show Rarity",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Inventory Show Value",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Inventory Sort Enabled",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Inventory Filter Enabled",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Inventory Search Enabled",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Inventory Compact Cards",
        "Demo preference only; no game action is connected.",
        false
    )
    toggle(
        id,
        "Inventory Reset Display",
        "Demo preference only; no game action is connected.",
        false
    )
end)
local RuntimeState = {
    selectedTab = "main",
    visible = true,
    componentCount = 0,
    sessionStartedAt = os.clock(),
    preferences = {},
    notifications = {},
    cleanupTasks = {},
    revision = 1
}
local function normalizeText(value)
    if value == nil then return "" end
    return tostring(value):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
end
local function isUsableText(value)
    return normalizeText(value) ~= ""
end
local function clampNumber(value, minimum, maximum)
    local number = tonumber(value) or minimum
    if number < minimum then number = minimum end
    if number > maximum then number = maximum end
    return number
end
local function copyArray(source)
    local result = {}
    for index, value in ipairs(source or {}) do result[index] = value end
    return result
end
local function arrayContains(source, target)
    for _, value in ipairs(source or {}) do
        if value == target then return true end
    end
    return false
end
local function removeArrayValue(source, target)
    local result = {}
    for _, value in ipairs(source or {}) do
        if value ~= target then result[#result + 1] = value end
    end
    return result
end
local function countKeys(source)
    local count = 0
    for _ in pairs(source or {}) do count += 1 end
    return count
end
local function setPreference(key, value)
    if not isUsableText(key) then return false end
    RuntimeState.preferences[key] = value
    RuntimeState.revision += 1
    return true
end
local function getPreference(key, fallback)
    local value = RuntimeState.preferences[key]
    if value == nil then return fallback end
    return value
end
local function resetPreferences()
    table.clear(RuntimeState.preferences)
    RuntimeState.revision += 1
end
local function registerCleanup(taskFunction)
    if typeof(taskFunction) == "function" then
        RuntimeState.cleanupTasks[#RuntimeState.cleanupTasks + 1] = taskFunction
    end
end
local function runCleanupTasks()
    for index = #RuntimeState.cleanupTasks, 1, -1 do
        local taskFunction = RuntimeState.cleanupTasks[index]
        pcall(taskFunction)
        RuntimeState.cleanupTasks[index] = nil
    end
end
local function setRuntimeVisible(value)
    RuntimeState.visible = value == true
    if main and main.Parent then main.Visible = RuntimeState.visible end
    if floating and floating.Parent then floating.Visible = not RuntimeState.visible end
end
local function getRuntimeDuration()
    return math.max(0, os.clock() - RuntimeState.sessionStartedAt)
end
local function formatDuration(seconds)
    local whole = math.floor(math.max(0, seconds))
    local hours = math.floor(whole / 3600)
    local minutes = math.floor((whole % 3600) / 60)
    local remainder = whole % 60
    return string.format("%02d:%02d:%02d", hours, minutes, remainder)
end
local function safeDisconnect(connection)
    if connection and typeof(connection) == "RBXScriptConnection" then
        pcall(function() connection:Disconnect() end)
    end
end
local function safeDestroy(instance)
    if instance and typeof(instance) == "Instance" and instance.Parent then
        pcall(function() instance:Destroy() end)
    end
end
local function setAttributeSafe(instance, key, value)
    if instance and instance.Parent and isUsableText(key) then
        pcall(function() instance:SetAttribute(key, value) end)
    end
end
local function getAttributeSafe(instance, key, fallback)
    if not instance or not instance.Parent then return fallback end
    local ok, value = pcall(function() return instance:GetAttribute(key) end)
    if not ok or value == nil then return fallback end
    return value
end
local function setTextSafe(label, value)
    if label and label:IsA("TextLabel") then label.Text = normalizeText(value) end
end
local function setButtonEnabled(buttonObject, enabled)
    if not buttonObject or not buttonObject:IsA("GuiButton") then return end
    buttonObject.Active = enabled == true
    buttonObject.Selectable = enabled == true
    buttonObject.AutoButtonColor = enabled == true
    buttonObject.TextTransparency = enabled and 0 or 0.35
end
local function setComponentTransparency(instance, transparency)
    if not instance then return end
    local value = clampNumber(transparency, 0, 1)
    if instance:IsA("GuiObject") then
        if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
            instance.TextTransparency = value
        end
        if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
            instance.ImageTransparency = value
        end
    end
end
local function applyCornerRadius(instance, radius)
    if not instance or not instance:IsA("GuiObject") then return nil end
    local existing = instance:FindFirstChildOfClass("UICorner")
    if not existing then existing = Instance.new("UICorner"); existing.Parent = instance end
    existing.CornerRadius = UDim.new(0, clampNumber(radius, 0, 24))
    return existing
end
local function applyStrokeStyle(instance, color, thickness, transparency)
    if not instance or not instance:IsA("GuiObject") then return nil end
    local existing = instance:FindFirstChildOfClass("UIStroke")
    if not existing then existing = Instance.new("UIStroke"); existing.Parent = instance end
    existing.Color = color or Theme.stroke
    existing.Thickness = clampNumber(thickness or 1, 0, 4)
    existing.Transparency = clampNumber(transparency or 0, 0, 1)
    existing.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return existing
end
local function applyGradientStyle(instance, firstColor, secondColor, rotation)
    if not instance or not instance:IsA("GuiObject") then return nil end
    local gradient = instance:FindFirstChildOfClass("UIGradient")
    if not gradient then gradient = Instance.new("UIGradient"); gradient.Parent = instance end
    gradient.Color = ColorSequence.new(firstColor or Theme.surfaceHi, secondColor or Theme.surface)
    gradient.Rotation = clampNumber(rotation or 90, 0, 360)
    return gradient
end
local function createInsetLine(parent, yPosition, color, alpha)
    return make("Frame", {
        Name = "InsetLine",
        BorderSizePixel = 0,
        BackgroundColor3 = color or Theme.stroke,
        BackgroundTransparency = clampNumber(alpha or 0.2, 0, 1),
        Position = UDim2.new(0, 8, 0, yPosition),
        Size = UDim2.new(1, -16, 0, 1)
    }, parent)
end
local function createAccentDot(parent, position, size, color)
    local dot = make("Frame", {
        Name = "AccentDot",
        BorderSizePixel = 0,
        BackgroundColor3 = color or Theme.accent,
        Position = position,
        Size = UDim2.fromOffset(size, size)
    }, parent)
    applyCornerRadius(dot, size / 2)
    return dot
end
local function animateTransparency(instance, propertyName, target, duration)
    if not instance or not instance.Parent then return nil end
    local info = TweenInfo.new(clampNumber(duration or 0.12, 0.03, 0.5), Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local goal = {}
    goal[propertyName] = clampNumber(target, 0, 1)
    local tween = TweenService:Create(instance, info, goal)
    tween:Play()
    return tween
end
local function setSelectedTabState(tabId)
    RuntimeState.selectedTab = string.lower(normalizeText(tabId))
    RuntimeState.revision += 1
end
local function validateTabRegistry()
    local valid = 0
    for tabId, tabData in pairs(tabs) do
        if type(tabId) == "string" and type(tabData) == "table" then
            if tabData.frame and tabData.button then valid += 1 end
        end
    end
    return valid
end
local function collectTabNames()
    local names = {}
    for tabId, tabData in pairs(tabs) do
        names[#names + 1] = tabData.name or tabId
    end
    table.sort(names, function(a, b) return string.lower(a) < string.lower(b) end)
    return names
end
local function searchTextMatches(sourceText, query)
    local normalizedQuery = string.lower(normalizeText(query))
    if normalizedQuery == "" then return true end
    return string.find(string.lower(normalizeText(sourceText)), normalizedQuery, 1, true) ~= nil
end
local function makePreferenceKey(tabId, featureName)
    return string.lower(normalizeText(tabId)) .. "." .. string.lower(normalizeText(featureName))
end
local function recordDemoInteraction(tabId, featureName, value)
    local key = makePreferenceKey(tabId, featureName)
    setPreference(key, value)
    RuntimeState.notifications[#RuntimeState.notifications + 1] = {
        tab = tabId,
        feature = featureName,
        value = value,
        timestamp = os.clock()
    }
    while #RuntimeState.notifications > 100 do
        table.remove(RuntimeState.notifications, 1)
    end
end
local function getRecentInteractions(limit)
    local result = {}
    local count = clampNumber(limit or 20, 1, 100)
    local first = math.max(1, #RuntimeState.notifications - count + 1)
    for index = first, #RuntimeState.notifications do
        result[#result + 1] = RuntimeState.notifications[index]
    end
    return result
end
local function resetSessionRuntime()
    RuntimeState.selectedTab = "main"
    RuntimeState.visible = true
    RuntimeState.sessionStartedAt = os.clock()
    table.clear(RuntimeState.notifications)
    RuntimeState.revision += 1
end
local function getRuntimeSummary()
    return {
        tabs = validateTabRegistry(),
        preferences = countKeys(RuntimeState.preferences),
        interactions = #RuntimeState.notifications,
        uptime = formatDuration(getRuntimeDuration()),
        revision = RuntimeState.revision
    }
end
local function setThemeAccent(color)
    if typeof(color) ~= "Color3" then return false end
    Theme.accent = color
    RuntimeState.revision += 1
    return true
end
local function setThemeSurface(color)
    if typeof(color) ~= "Color3" then return false end
    Theme.surface = color
    RuntimeState.revision += 1
    return true
end
local function setThemeStroke(color)
    if typeof(color) ~= "Color3" then return false end
    Theme.stroke = color
    RuntimeState.revision += 1
    return true
end
local function getThemeSnapshot()
    return {
        background = Theme.background,
        surface = Theme.surface,
        surfaceHi = Theme.surfaceHi,
        cardBg = Theme.cardBg,
        accent = Theme.accent,
        accentLight = Theme.accentLight,
        stroke = Theme.stroke
    }
end
local function restoreThemeSnapshot(snapshot)
    if type(snapshot) ~= "table" then return false end
    for key, value in pairs(snapshot) do
        if Theme[key] ~= nil and typeof(value) == "Color3" then Theme[key] = value end
    end
    RuntimeState.revision += 1
    return true
end
local function getSafeViewportSize()
    local camera = workspace.CurrentCamera
    if not camera then return Vector2.new(800, 600) end
    local size = camera.ViewportSize
    return Vector2.new(math.max(1, size.X), math.max(1, size.Y))
end
local function getCompactScale(viewportSize)
    local widthScale = viewportSize.X / 720
    local heightScale = viewportSize.Y / 520
    return clampNumber(math.min(widthScale, heightScale, 1), 0.55, 1)
end
local function refreshCompactLayout()
    local viewport = getSafeViewportSize()
    if scale then scale.Scale = getCompactScale(viewport) end
    return viewport
end
local function makeAccessibleName(instance, name)
    if instance and instance:IsA("GuiObject") then
        instance:SetAttribute("AccessibleName", normalizeText(name))
    end
end
local function getAccessibleName(instance)
    return getAttributeSafe(instance, "AccessibleName", instance and instance.Name or "")
end
local function setControlState(instance, stateName, stateValue)
    if not instance or not instance.Parent then return false end
    setAttributeSafe(instance, stateName, stateValue)
    return true
end
local function getControlState(instance, stateName, fallback)
    return getAttributeSafe(instance, stateName, fallback)
end
local function setControlDescription(instance, description)
    if not instance or not instance.Parent then return false end
    setAttributeSafe(instance, "Description", normalizeText(description))
    return true
end
local function getControlDescription(instance)
    return getAttributeSafe(instance, "Description", "")
end
local function isGuiObjectVisible(instance)
    return instance ~= nil and instance.Parent ~= nil and instance:IsA("GuiObject") and instance.Visible
end
local function setGuiObjectVisible(instance, visible)
    if not instance or not instance.Parent or not instance:IsA("GuiObject") then return false end
    instance.Visible = visible == true
    return true
end
local function setGuiObjectPosition(instance, x, y)
    if not instance or not instance.Parent or not instance:IsA("GuiObject") then return false end
    instance.Position = UDim2.fromOffset(x, y)
    return true
end
local function setGuiObjectSize(instance, width, height)
    if not instance or not instance.Parent or not instance:IsA("GuiObject") then return false end
    instance.Size = UDim2.fromOffset(math.max(0, width), math.max(0, height))
    return true
end
local function setGuiObjectZIndex(instance, zIndex)
    if not instance or not instance.Parent or not instance:IsA("GuiObject") then return false end
    instance.ZIndex = clampNumber(zIndex, 1, 100)
    return true
end
local function setTextScaledSafe(instance, enabled)
    if not instance then return false end
    if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
        instance.TextScaled = enabled == true
        return true
    end
    return false
end
local function setTextSizeSafe(instance, size)
    if not instance then return false end
    if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
        instance.TextSize = clampNumber(size, 8, 24)
        return true
    end
    return false
end
local function setBackgroundSafe(instance, color)
    if not instance or not instance:IsA("GuiObject") or typeof(color) ~= "Color3" then return false end
    instance.BackgroundColor3 = color
    return true
end
local function setBackgroundAlphaSafe(instance, alpha)
    if not instance or not instance:IsA("GuiObject") then return false end
    instance.BackgroundTransparency = clampNumber(alpha, 0, 1)
    return true
end
local function setBorderSafe(instance, color, thickness)
    if not instance or not instance:IsA("GuiObject") then return false end
    instance.BorderColor3 = color or Theme.stroke
    instance.BorderSizePixel = clampNumber(thickness or 0, 0, 4)
    return true
end
local function applySoftSurface(instance)
    if not instance or not instance:IsA("GuiObject") then return false end
    applyCornerRadius(instance, 8)
    applyStrokeStyle(instance, Theme.stroke, 1, 0.15)
    return true
end
local function applyCardSurface(instance)
    if not instance or not instance:IsA("GuiObject") then return false end
    instance.BackgroundColor3 = Theme.cardBg
    applyCornerRadius(instance, 7)
    applyStrokeStyle(instance, Theme.stroke, 1, 0.22)
    return true
end
local function applyPanelSurface(instance)
    if not instance or not instance:IsA("GuiObject") then return false end
    instance.BackgroundColor3 = Theme.surface
    applyCornerRadius(instance, 10)
    applyStrokeStyle(instance, Theme.stroke, 1, 0.1)
    return true
end
local function applyAccentSurface(instance)
    if not instance or not instance:IsA("GuiObject") then return false end
    instance.BackgroundColor3 = Theme.accent
    applyCornerRadius(instance, 6)
    applyStrokeStyle(instance, Theme.accentLight, 1, 0.25)
    return true
end
local function applyMutedSurface(instance)
    if not instance or not instance:IsA("GuiObject") then return false end
    instance.BackgroundColor3 = Theme.surfaceHi
    applyCornerRadius(instance, 6)
    applyStrokeStyle(instance, Theme.stroke, 1, 0.3)
    return true
end
local function updateRevision()
    RuntimeState.revision += 1
    return RuntimeState.revision
end
local function getRevision()
    return RuntimeState.revision
end
local function setFloatingVisible(visible)
    if floating and floating.Parent then floating.Visible = visible == true end
end
local function toggleMainVisibility()
    setRuntimeVisible(not RuntimeState.visible)
end
local function isMainVisible()
    return RuntimeState.visible == true
end
local function clearInteractionHistory()
    table.clear(RuntimeState.notifications)
    updateRevision()
end
local function removePreference(key)
    if RuntimeState.preferences[key] == nil then return false end
    RuntimeState.preferences[key] = nil
    updateRevision()
    return true
end
local function listPreferenceKeys()
    local keys = {}
    for key in pairs(RuntimeState.preferences) do keys[#keys + 1] = key end
    table.sort(keys)
    return keys
end
local function validatePreferenceKey(key)
    local value = normalizeText(key)
    return #value > 0 and #value <= 120
end
local function validateDisplayText(value, maximumLength)
    local textValue = normalizeText(value)
    local limit = clampNumber(maximumLength or 160, 1, 500)
    if #textValue > limit then textValue = string.sub(textValue, 1, limit) end
    return textValue
end
local function makeStableId(prefix, value)
    local left = string.lower(validateDisplayText(prefix or "item", 32)):gsub("[^%w_%-]", "_")
    local right = string.lower(validateDisplayText(value or "entry", 64)):gsub("[^%w_%-]", "_")
    return left .. "_" .. right
end
local function isValidColor(value)
    return typeof(value) == "Color3"
end
local function colorWithAlpha(color, alpha)
    if not isValidColor(color) then color = Theme.surface end
    return color, clampNumber(alpha or 0, 0, 1)
end
local function getContrastTextColor(backgroundColor)
    if not isValidColor(backgroundColor) then return Color3.new(1, 1, 1) end
    local luminance = backgroundColor.R * 0.299 + backgroundColor.G * 0.587 + backgroundColor.B * 0.114
    if luminance > 0.62 then return Color3.fromRGB(16, 19, 25) end
    return Color3.fromRGB(240, 244, 250)
end
local function setAdaptiveTextColor(label, backgroundColor)
    if not label then return false end
    if label:IsA("TextLabel") or label:IsA("TextButton") or label:IsA("TextBox") then
        label.TextColor3 = getContrastTextColor(backgroundColor)
        return true
    end
    return false
end
local function getViewportInsets()
    local camera = workspace.CurrentCamera
    if not camera then return Vector2.new(0, 0) end
    local size = camera.ViewportSize
    return Vector2.new(math.max(0, size.X * 0.025), math.max(0, size.Y * 0.025))
end
local function keepPanelInsideViewport(instance)
    if not instance or not instance:IsA("GuiObject") then return false end
    local camera = workspace.CurrentCamera
    if not camera then return false end
    local viewport = camera.ViewportSize
    local position = instance.AbsolutePosition
    local size = instance.AbsoluteSize
    local margin = getViewportInsets()
    local x = math.clamp(position.X, margin.X, math.max(margin.X, viewport.X - size.X - margin.X))
    local y = math.clamp(position.Y, margin.Y, math.max(margin.Y, viewport.Y - size.Y - margin.Y))
    instance.Position = UDim2.fromOffset(x, y)
    return true
end
local function getTabComponentCount(tabId)
    local tabData = tabs[tabId]
    if not tabData or type(tabData.components) ~= "table" then return 0 end
    return #tabData.components
end
local function getAllComponentCounts()
    local result = {}
    for tabId in pairs(tabs) do result[tabId] = getTabComponentCount(tabId) end
    return result
end
local function findTabByName(name)
    local query = string.lower(normalizeText(name))
    for tabId, tabData in pairs(tabs) do
        if string.lower(tabData.name or tabId) == query then return tabId, tabData end
    end
    return nil, nil
end
local function hasTab(name)
    local tabId = findTabByName(name)
    return tabId ~= nil
end
local function getCurrentTabName()
    local tabData = tabs[RuntimeState.selectedTab]
    return tabData and (tabData.name or RuntimeState.selectedTab) or "Main"
end
local function getSessionStatus()
    if not screen or not screen.Parent then return "closed" end
    if RuntimeState.visible then return "visible" end
    return "hidden"
end
local function makeSessionSnapshot()
    return {
        selectedTab = RuntimeState.selectedTab,
        visible = RuntimeState.visible,
        preferences = table.clone(RuntimeState.preferences),
        revision = RuntimeState.revision
    }
end
local function restoreSessionSnapshot(snapshot)
    if type(snapshot) ~= "table" then return false end
    if type(snapshot.preferences) == "table" then RuntimeState.preferences = table.clone(snapshot.preferences) end
    if type(snapshot.selectedTab) == "string" and tabs[snapshot.selectedTab] then switchTab(snapshot.selectedTab) end
    setRuntimeVisible(snapshot.visible == true)
    updateRevision()
    return true
end
local function ensureControlDefaults(defaults)
    local result = {}
    for key, value in pairs(defaults or {}) do
        if validatePreferenceKey(key) then result[key] = value end
    end
    return result
end
local function mergePreferenceDefaults(defaults)
    for key, value in pairs(ensureControlDefaults(defaults)) do
        if RuntimeState.preferences[key] == nil then RuntimeState.preferences[key] = value end
    end
    updateRevision()
end
local function getBooleanPreference(key, fallback)
    local value = getPreference(key, fallback == true)
    return value == true
end
local function getNumberPreference(key, fallback, minimum, maximum)
    return clampNumber(getPreference(key, fallback), minimum, maximum)
end
local function getStringPreference(key, fallback)
    return validateDisplayText(getPreference(key, fallback or ""), 200)
end
local function setBooleanPreference(key, value)
    return setPreference(key, value == true)
end
local function setNumberPreference(key, value, minimum, maximum)
    return setPreference(key, clampNumber(value, minimum, maximum))
end
local function setStringPreference(key, value)
    return setPreference(key, validateDisplayText(value, 200))
end
local function getControlDefaults()
    return {
        compact = true,
        smoothCorners = true,
        accentGlow = true,
        reduceMotion = false,
        highContrast = false,
        showTooltips = true,
        showStatus = true,
        showFloatingButton = true
    }
end
local function applyControlDefaults()
    mergePreferenceDefaults(getControlDefaults())
end
local function setCompactMode(enabled)
    setBooleanPreference("ui.compact", enabled)
    if scale then scale.Scale = enabled and getCompactScale(getSafeViewportSize()) or 1 end
end
local function setReduceMotion(enabled)
    setBooleanPreference("ui.reduceMotion", enabled)
end
local function setHighContrast(enabled)
    setBooleanPreference("ui.highContrast", enabled)
end
local function setTooltipPreference(enabled)
    setBooleanPreference("ui.showTooltips", enabled)
end
local function setStatusPreference(enabled)
    setBooleanPreference("ui.showStatus", enabled)
end
local function setFloatingPreference(enabled)
    setBooleanPreference("ui.showFloatingButton", enabled)
    setFloatingVisible(enabled and not RuntimeState.visible)
end
local function getUIConfiguration()
    return {
        compact = getBooleanPreference("ui.compact", true),
        reduceMotion = getBooleanPreference("ui.reduceMotion", false),
        highContrast = getBooleanPreference("ui.highContrast", false),
        showTooltips = getBooleanPreference("ui.showTooltips", true),
        showStatus = getBooleanPreference("ui.showStatus", true),
        showFloatingButton = getBooleanPreference("ui.showFloatingButton", true)
    }
end
local function isRuntimeReady()
    return screen ~= nil and screen.Parent ~= nil and main ~= nil and main.Parent ~= nil
end
local function getRuntimeHealth()
    local summary = getRuntimeSummary()
    summary.ready = isRuntimeReady()
    summary.status = getSessionStatus()
    summary.activeTab = getCurrentTabName()
    return summary
end
local function runSafeCallback(callback, ...)
    if typeof(callback) ~= "function" then return false, "invalid callback" end
    local ok, result = pcall(callback, ...)
    if not ok then return false, tostring(result) end
    return true, result
end
local function scheduleSafeTask(callback, delaySeconds)
    if typeof(callback) ~= "function" then return nil end
    local delayValue = clampNumber(delaySeconds or 0, 0, 30)
    return task.delay(delayValue, function()
        if isRuntimeReady() then runSafeCallback(callback) end
    end)
end
local function createRuntimeToken()
    RuntimeState.revision += 1
    return tostring(RuntimeState.revision) .. ":" .. tostring(math.floor(os.clock() * 1000))
end
local function isRuntimeTokenCurrent(token)
    return type(token) == "string" and string.find(token, ":", 1, true) ~= nil
end
local function buildFeaturePath(tabName, groupName, featureName)
    return table.concat({
        makeStableId("tab", tabName),
        makeStableId("group", groupName),
        makeStableId("feature", featureName)
    }, ".")
end
local function validateFeatureDefinition(definition)
    if type(definition) ~= "table" then return false end
    if not isUsableText(definition.name) then return false end
    if not isUsableText(definition.group) then return false end
    if not isUsableText(definition.tab) then return false end
    return true
end
local function createFeatureDefinition(tabName, groupName, featureName, defaultValue)
    local definition = {
        tab = normalizeText(tabName),
        group = normalizeText(groupName),
        name = normalizeText(featureName),
        default = defaultValue == true
    }
    definition.path = buildFeaturePath(definition.tab, definition.group, definition.name)
    return definition
end
local function registerFeatureDefinition(registry, definition)
    if type(registry) ~= "table" or not validateFeatureDefinition(definition) then return false end
    registry[definition.path] = definition
    return true
end
local function createFeatureRegistry()
    return {}
end
local function getFeatureDefinition(registry, path)
    if type(registry) ~= "table" then return nil end
    return registry[path]
end
local function listFeatureDefinitions(registry)
    local result = {}
    for _, definition in pairs(registry or {}) do result[#result + 1] = definition end
    table.sort(result, function(a, b) return a.path < b.path end)
    return result
end
local function countFeatureDefinitions(registry)
    return countKeys(registry)
end
local function filterFeatureDefinitions(registry, query)
    local result = {}
    for _, definition in pairs(registry or {}) do
        if searchTextMatches(definition.name, query) or searchTextMatches(definition.group, query) or searchTextMatches(definition.tab, query) then
            result[#result + 1] = definition
        end
    end
    table.sort(result, function(a, b) return a.path < b.path end)
    return result
end
local function createTabSummary(tabId, tabData)
    return {
        id = tabId,
        name = tabData.name or tabId,
        components = getTabComponentCount(tabId),
        active = RuntimeState.selectedTab == tabId
    }
end
local function getTabSummaries()
    local result = {}
    for tabId, tabData in pairs(tabs) do result[#result + 1] = createTabSummary(tabId, tabData) end
    table.sort(result, function(a, b) return a.name < b.name end)
    return result
end
local function getTabSummary(tabId)
    local tabData = tabs[tabId]
    if not tabData then return nil end
    return createTabSummary(tabId, tabData)
end
local function getTabButton(tabId)
    local tabData = tabs[tabId]
    return tabData and tabData.button or nil
end
local function getTabFrame(tabId)
    local tabData = tabs[tabId]
    return tabData and tabData.frame or nil
end
local function setTabButtonEnabled(tabId, enabled)
    return setButtonEnabled(getTabButton(tabId), enabled)
end
local function setTabFrameVisible(tabId, visible)
    return setGuiObjectVisible(getTabFrame(tabId), visible)
end
local function refreshTabLayout(tabId)
    local tabFrame = getTabFrame(tabId)
    if not tabFrame then return false end
    local layout = tabFrame:FindFirstChildOfClass("UIListLayout")
    if layout then tabFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 16) end
    return true
end
local function refreshAllTabLayouts()
    for tabId in pairs(tabs) do refreshTabLayout(tabId) end
end
local function getCurrentViewportScale()
    return scale and scale.Scale or 1
end
local function setCurrentViewportScale(value)
    if not scale then return false end
    scale.Scale = clampNumber(value, 0.45, 1)
    return true
end
local function resetViewportScale()
    return setCurrentViewportScale(getCompactScale(getSafeViewportSize()))
end
local function setPanelCompactSize()
    if not main then return false end
    main.Size = UDim2.fromOffset(560, 390)
    resetViewportScale()
    return true
end
local function setPanelDefaultSize()
    if not main then return false end
    main.Size = UDim2.fromOffset(600, 430)
    resetViewportScale()
    return true
end
local function getPanelSize()
    if not main then return Vector2.new(0, 0) end
    return Vector2.new(main.AbsoluteSize.X, main.AbsoluteSize.Y)
end
local function getPanelPosition()
    if not main then return Vector2.new(0, 0) end
    return Vector2.new(main.AbsolutePosition.X, main.AbsolutePosition.Y)
end
local function setPanelPosition(x, y)
    if not main then return false end
    main.Position = UDim2.fromOffset(x, y)
    keepPanelInsideViewport(main)
    return true
end
local function setPanelOpacity(alpha)
    if not main then return false end
    main.BackgroundTransparency = clampNumber(alpha, 0, 0.5)
    return true
end
local function setPanelOutline(enabled)
    if not main then return false end
    local outline = main:FindFirstChildOfClass("UIStroke")
    if outline then outline.Enabled = enabled == true end
    return outline ~= nil
end
local function setPanelOutlineThickness(value)
    if not main then return false end
    local outline = main:FindFirstChildOfClass("UIStroke")
    if not outline then return false end
    outline.Thickness = clampNumber(value, 0.5, 3)
    return true
end
local function setPanelCornerRadius(value)
    if not main then return false end
    applyCornerRadius(main, value)
    return true
end
local function applyPremiumSurfaceDetails()
    if not screen or not screen.Parent then return end
    for _, instance in ipairs(screen:GetDescendants()) do
        if instance:IsA("Frame") and instance.Name:lower():find("card", 1, true) then
            applyCardSurface(instance)
        elseif instance:IsA("Frame") and instance.Name:lower():find("section", 1, true) then
            applySoftSurface(instance)
        end
    end
end
local function refreshRuntimeAppearance()
    if not isRuntimeReady() then return false end
    applyPremiumSurfaceDetails()
    refreshAllTabLayouts()
    return true
end
local function setRuntimePreference(name, value)
    return setPreference("runtime." .. makeStableId("setting", name), value)
end
local function getRuntimePreference(name, fallback)
    return getPreference("runtime." .. makeStableId("setting", name), fallback)
end
local function clearRuntimePreferences()
    for key in pairs(RuntimeState.preferences) do
        if string.sub(key, 1, 8) == "runtime." then RuntimeState.preferences[key] = nil end
    end
    updateRevision()
end
local function getRuntimePreferenceCount()
    local count = 0
    for key in pairs(RuntimeState.preferences) do
        if string.sub(key, 1, 8) == "runtime." then count += 1 end
    end
    return count
end
local function getInteractionCount()
    return #RuntimeState.notifications
end
local function getElapsedSessionSeconds()
    return math.floor(getRuntimeDuration())
end
local function getElapsedSessionText()
    return formatDuration(getElapsedSessionSeconds())
end
local function createStatusPayload()
    return {
        status = getSessionStatus(),
        tab = getCurrentTabName(),
        uptime = getElapsedSessionText(),
        interactions = getInteractionCount(),
        revision = getRevision()
    }
end
local function validateStatusPayload(payload)
    return type(payload) == "table" and type(payload.status) == "string" and type(payload.tab) == "string"
end
local function setStatusAttribute(payload)
    if not validateStatusPayload(payload) then return false end
    setAttributeSafe(screen, "RuntimeStatus", payload.status)
    setAttributeSafe(screen, "RuntimeTab", payload.tab)
    setAttributeSafe(screen, "RuntimeUptime", payload.uptime)
    setAttributeSafe(screen, "RuntimeRevision", payload.revision)
    return true
end
local function refreshStatusAttributes()
    return setStatusAttribute(createStatusPayload())
end
local function getRuntimeVersion()
    return "2.5.0"
end
local function getRuntimeName()
    return "SenaUIReconstructTest"
end
local function getRuntimeMetadata()
    return {
        name = getRuntimeName(),
        version = getRuntimeVersion(),
        tabs = validateTabRegistry(),
        mode = "UI_ONLY_DEMO",
        gameplayActionsEnabled = false
    }
end
local function assertRuntimeInvariant()
    if not screen or not screen.Parent then return false, "screen missing" end
    if not main or not main.Parent then return false, "panel missing" end
    if validateTabRegistry() == 0 then return false, "tabs missing" end
    return true, "ok"
end
local function runRuntimeSelfCheck()
    local valid, message = assertRuntimeInvariant()
    local report = getRuntimeHealth()
    report.valid = valid
    report.message = message
    report.metadata = getRuntimeMetadata()
    return report
end
local function resetRuntimeAppearance()
    restoreThemeSnapshot({
        background = Color3.fromRGB(10, 12, 16),
        surface = Color3.fromRGB(22, 22, 27),
        surfaceHi = Color3.fromRGB(32, 34, 42),
        cardBg = Color3.fromRGB(18, 18, 24),
        accent = Color3.fromRGB(26, 147, 250),
        accentLight = Color3.fromRGB(80, 190, 255),
        stroke = Color3.fromRGB(48, 50, 60)
    })
    setPanelCornerRadius(12)
    setPanelOutlineThickness(1)
    setPanelOpacity(0)
    resetViewportScale()
end
local function getThemeColor(name)
    local value = Theme[name]
    if typeof(value) == "Color3" then return value end
    return Theme.surface
end
local function setThemeColor(name, value)
    if Theme[name] == nil or typeof(value) ~= "Color3" then return false end
    Theme[name] = value
    updateRevision()
    return true
end
local function listThemeColorNames()
    local result = {}
    for name, value in pairs(Theme) do
        if typeof(value) == "Color3" then result[#result + 1] = name end
    end
    table.sort(result)
    return result
end
local function buildThemePalette()
    local palette = {}
    for _, name in ipairs(listThemeColorNames()) do palette[name] = Theme[name] end
    return palette
end
local function isFeatureActionAllowed()
    return false
end
local function getFeatureModeLabel()
    return isFeatureActionAllowed() and "CONNECTED" or "DEMO ONLY"
end
local function getFeatureModeColor()
    return isFeatureActionAllowed() and Color3.fromRGB(80, 220, 140) or Color3.fromRGB(150, 160, 175)
end
local function setFeatureDemoState(featureName, value)
    recordDemoInteraction(getCurrentTabName(), featureName, value)
    return {
        feature = featureName,
        value = value,
        mode = getFeatureModeLabel(),
        time = os.clock()
    }
end
local function getFeatureDemoState(featureName, fallback)
    local key = makePreferenceKey(getCurrentTabName(), featureName)
    return getPreference(key, fallback)
end
local function resetFeatureDemoStates()
    table.clear(RuntimeState.preferences)
    table.clear(RuntimeState.notifications)
    updateRevision()
end
local function getFeatureDemoStates()
    return table.clone(RuntimeState.preferences)
end
local function isFeatureNameValid(featureName)
    local name = normalizeText(featureName)
    return #name >= 2 and #name <= 100
end
local function makeFeatureDisplayName(featureName)
    local name = validateDisplayText(featureName, 100)
    return name:gsub("[%_%-]+", " ")
end
local function sortDisplayNames(names)
    table.sort(names, function(a, b) return string.lower(a) < string.lower(b) end)
    return names
end
local function filterDisplayNames(names, query)
    local result = {}
    for _, name in ipairs(names or {}) do
        if searchTextMatches(name, query) then result[#result + 1] = name end
    end
    return sortDisplayNames(result)
end
local function makeDropdownOptionList(options, includeNone)
    local result = {}
    if includeNone then result[#result + 1] = "None" end
    for _, option in ipairs(options or {}) do
        if isUsableText(option) and not arrayContains(result, option) then result[#result + 1] = option end
    end
    return result
end
local function normalizeSelection(selection, options, multiSelect)
    local validOptions = makeDropdownOptionList(options, false)
    if multiSelect then
        local result = {}
        for _, value in ipairs(selection or {}) do
            if arrayContains(validOptions, value) and not arrayContains(result, value) then result[#result + 1] = value end
        end
        return result
    end
    if arrayContains(validOptions, selection) then return selection end
    return validOptions[1]
end
local function getSelectionLabel(selection)
    if type(selection) == "table" then return table.concat(selection, ", ") end
    return normalizeText(selection)
end
local function validateSliderValue(value, minimum, maximum)
    return clampNumber(value, minimum, maximum)
end
local function formatSliderValue(value, precision)
    local places = clampNumber(precision or 0, 0, 4)
    return string.format("%." .. tostring(places) .. "f", tonumber(value) or 0)
end
local function parseNumericInput(value)
    if type(value) == "number" then return value end
    local cleaned = normalizeText(value):gsub(",", ""):gsub("_", "")
    local suffix = string.lower(string.sub(cleaned, -1))
    local multiplier = 1
    if suffix == "k" then multiplier = 1000; cleaned = string.sub(cleaned, 1, -2) end
    if suffix == "m" then multiplier = 1000000; cleaned = string.sub(cleaned, 1, -2) end
    if suffix == "b" then multiplier = 1000000000; cleaned = string.sub(cleaned, 1, -2) end
    local number = tonumber(cleaned)
    if not number then return nil end
    return number * multiplier
end
local function formatCompactNumber(value)
    local number = tonumber(value) or 0
    local absolute = math.abs(number)
    if absolute >= 1000000000 then return string.format("%.2fb", number / 1000000000) end
    if absolute >= 1000000 then return string.format("%.2fm", number / 1000000) end
    if absolute >= 1000 then return string.format("%.1fk", number / 1000) end
    return tostring(math.floor(number))
end
local function getOptionCount(options)
    return #(options or {})
end
local function areOptionsUnique(options)
    local seen = {}
    for _, value in ipairs(options or {}) do
        if seen[value] then return false end
        seen[value] = true
    end
    return true
end
local function sanitizeOptions(options)
    local result = {}
    for _, value in ipairs(options or {}) do
        local textValue = validateDisplayText(value, 80)
        if textValue ~= "" and not arrayContains(result, textValue) then result[#result + 1] = textValue end
    end
    return result
end
local function getSafePlaceholder(value)
    return validateDisplayText(value or "Enter value", 60)
end
local function getSafeDescription(value)
    return validateDisplayText(value or "", 180)
end
local function getSafeTitle(value)
    return validateDisplayText(value or "Untitled", 80)
end
local function getSafeIdentifier(value)
    return validateDisplayText(value or "item", 80):gsub("[^%w_%-]", "_")
end
local function setControlIdentifier(instance, identifier)
    if not instance or not instance.Parent then return false end
    instance.Name = getSafeIdentifier(identifier)
    return true
end
local function setControlTooltip(instance, tooltip)
    return setControlDescription(instance, tooltip)
end
local function getControlTooltip(instance)
    return getControlDescription(instance)
end
local function setControlGroup(instance, groupName)
    return setAttributeSafe(instance, "ControlGroup", normalizeText(groupName))
end
local function getControlGroup(instance)
    return getAttributeSafe(instance, "ControlGroup", "General")
end
local function setControlTab(instance, tabName)
    return setAttributeSafe(instance, "ControlTab", normalizeText(tabName))
end
local function getControlTab(instance)
    return getAttributeSafe(instance, "ControlTab", "Main")
end
local function isControlInGroup(instance, groupName)
    return string.lower(getControlGroup(instance)) == string.lower(normalizeText(groupName))
end
local function isControlInTab(instance, tabName)
    return string.lower(getControlTab(instance)) == string.lower(normalizeText(tabName))
end
local function createControlMetadata(tabName, groupName, controlName, description)
    return {
        tab = normalizeText(tabName),
        group = normalizeText(groupName),
        name = normalizeText(controlName),
        description = getSafeDescription(description),
        path = buildFeaturePath(tabName, groupName, controlName)
    }
end
local function validateControlMetadata(metadata)
    return type(metadata) == "table" and isUsableText(metadata.tab) and isUsableText(metadata.group) and isUsableText(metadata.name)
end
local function getControlMetadataLabel(metadata)
    if not validateControlMetadata(metadata) then return "Unknown control" end
    return metadata.tab .. " / " .. metadata.group .. " / " .. metadata.name
end
local function getTabOrder()
    local result = {}
    for tabId, tabData in pairs(tabs) do
        result[#result + 1] = { id = tabId, order = tabData.order or 999, name = tabData.name or tabId }
    end
    table.sort(result, function(a, b) return a.order < b.order end)
    return result
end
local function getOrderedTabIds()
    local result = {}
    for _, item in ipairs(getTabOrder()) do result[#result + 1] = item.id end
    return result
end
local function getNextTabId(currentId)
    local ordered = getOrderedTabIds()
    for index, tabId in ipairs(ordered) do
        if tabId == currentId then return ordered[index % #ordered + 1] end
    end
    return ordered[1]
end
local function getPreviousTabId(currentId)
    local ordered = getOrderedTabIds()
    for index, tabId in ipairs(ordered) do
        if tabId == currentId then return ordered[(index - 2) % #ordered + 1] end
    end
    return ordered[#ordered]
end
local function switchToNextTab()
    local tabId = getNextTabId(RuntimeState.selectedTab)
    if tabId then switchTab(tabId) end
end
local function switchToPreviousTab()
    local tabId = getPreviousTabId(RuntimeState.selectedTab)
    if tabId then switchTab(tabId) end
end
local function getCurrentTabIndex()
    local ordered = getOrderedTabIds()
    for index, tabId in ipairs(ordered) do if tabId == RuntimeState.selectedTab then return index end end
    return 1
end
local function getTotalTabCount()
    return #getOrderedTabIds()
end
local function getTabProgressText()
    return tostring(getCurrentTabIndex()) .. " / " .. tostring(getTotalTabCount())
end
local function setSelectedTabAttribute(tabId)
    setAttributeSafe(screen, "SelectedTab", tabId)
end
local function updateSelectedTabRuntime(tabId)
    setSelectedTabState(tabId)
    setSelectedTabAttribute(tabId)
    refreshStatusAttributes()
end
local function getThemeAccentPair()
    return Theme.accent, Theme.accentLight
end
local function getSurfacePair()
    return Theme.surface, Theme.surfaceHi
end
local function getTextPair()
    return Theme.text or Color3.fromRGB(240, 244, 250), Theme.muted or Color3.fromRGB(145, 154, 170)
end
local function isDarkTheme()
    local color = Theme.background
    local luminance = color.R * 0.299 + color.G * 0.587 + color.B * 0.114
    return luminance < 0.5
end
local function getThemeModeLabel()
    return isDarkTheme() and "DARK" or "LIGHT"
end
local function setThemeMode(mode)
    if string.lower(normalizeText(mode)) == "dark" then
        Theme.background = Color3.fromRGB(10, 12, 16)
        Theme.surface = Color3.fromRGB(22, 22, 27)
        Theme.surfaceHi = Color3.fromRGB(32, 34, 42)
        Theme.cardBg = Color3.fromRGB(18, 18, 24)
    elseif string.lower(normalizeText(mode)) == "light" then
        Theme.background = Color3.fromRGB(226, 232, 240)
        Theme.surface = Color3.fromRGB(245, 247, 250)
        Theme.surfaceHi = Color3.fromRGB(232, 237, 244)
        Theme.cardBg = Color3.fromRGB(255, 255, 255)
    else
        return false
    end
    updateRevision()
    return true
end
local function getComponentCount()
    local count = 0
    for _, tabData in pairs(tabs) do
        for _, component in ipairs(tabData.components or {}) do
            if component and component.Parent then count += 1 end
        end
    end
    return count
end
local function getVisibleComponentCount()
    local count = 0
    for _, tabData in pairs(tabs) do
        for _, component in ipairs(tabData.components or {}) do
            if isGuiObjectVisible(component) then count += 1 end
        end
    end
    return count
end
local function getVisibleTabCount()
    local count = 0
    for _, tabData in pairs(tabs) do
        if tabData.frame and tabData.frame.Visible then count += 1 end
    end
    return count
end
local function getMemoryStateSnapshot()
    return {
        preferenceCount = countKeys(RuntimeState.preferences),
        notificationCount = #RuntimeState.notifications,
        componentCount = getComponentCount(),
        visibleComponentCount = getVisibleComponentCount(),
        visibleTabCount = getVisibleTabCount()
    }
end
local function isPreferenceValueSupported(value)
    local valueType = typeof(value)
    return valueType == "boolean" or valueType == "number" or valueType == "string" or valueType == "Color3" or type(value) == "table"
end
local function sanitizePreferenceValue(value)
    if typeof(value) == "string" then return validateDisplayText(value, 500) end
    if typeof(value) == "number" then return clampNumber(value, -1000000000, 1000000000) end
    if typeof(value) == "boolean" or typeof(value) == "Color3" then return value end
    if type(value) == "table" then return table.clone(value) end
    return nil
end
local function setSanitizedPreference(key, value)
    if not validatePreferenceKey(key) or not isPreferenceValueSupported(value) then return false end
    return setPreference(key, sanitizePreferenceValue(value))
end
local function getSanitizedPreference(key, fallback)
    local value = RuntimeState.preferences[key]
    if value == nil then return fallback end
    return sanitizePreferenceValue(value)
end
local function exportPreferenceSnapshot()
    local snapshot = {}
    for key, value in pairs(RuntimeState.preferences) do
        if isPreferenceValueSupported(value) then snapshot[key] = sanitizePreferenceValue(value) end
    end
    return snapshot
end
local function importPreferenceSnapshot(snapshot)
    if type(snapshot) ~= "table" then return false end
    for key, value in pairs(snapshot) do
        if validatePreferenceKey(key) and isPreferenceValueSupported(value) then
            RuntimeState.preferences[key] = sanitizePreferenceValue(value)
        end
    end
    updateRevision()
    return true
end
local function countPreferenceTypes()
    local result = { boolean = 0, number = 0, string = 0, color = 0, table = 0 }
    for _, value in pairs(RuntimeState.preferences) do
        local valueType = typeof(value)
        if valueType == "boolean" then result.boolean += 1
        elseif valueType == "number" then result.number += 1
        elseif valueType == "string" then result.string += 1
        elseif valueType == "Color3" then result.color += 1
        elseif type(value) == "table" then result.table += 1 end
    end
    return result
end
local function getPreferenceSummary()
    local types = countPreferenceTypes()
    return string.format("%d settings · %d bool · %d number · %d text", countKeys(RuntimeState.preferences), types.boolean, types.number, types.string)
end
local function createSafeConnection(signal, callback)
    if not signal or typeof(callback) ~= "function" then return nil end
    local ok, connection = pcall(function() return signal:Connect(callback) end)
    if not ok then return nil end
    registerCleanup(function() safeDisconnect(connection) end)
    return connection
end
local function addCleanupForInstance(instance)
    registerCleanup(function() safeDestroy(instance) end)
end
local function cleanupRuntime()
    runCleanupTasks()
    resetSessionRuntime()
end
local function getCleanupTaskCount()
    return #RuntimeState.cleanupTasks
end
local function hasCleanupTasks()
    return getCleanupTaskCount() > 0
end
local function clearCleanupTasks()
    table.clear(RuntimeState.cleanupTasks)
end
local function setScreenAttribute(key, value)
    return setAttributeSafe(screen, key, value)
end
local function getScreenAttribute(key, fallback)
    return getAttributeSafe(screen, key, fallback)
end
local function setPanelAttribute(key, value)
    return setAttributeSafe(main, key, value)
end
local function getPanelAttribute(key, fallback)
    return getAttributeSafe(main, key, fallback)
end
local function setTabAttribute(tabId, key, value)
    local frame = getTabFrame(tabId)
    return setAttributeSafe(frame, key, value)
end
local function getTabAttribute(tabId, key, fallback)
    local frame = getTabFrame(tabId)
    return getAttributeSafe(frame, key, fallback)
end
local function setTabStatus(tabId, status)
    return setTabAttribute(tabId, "Status", normalizeText(status))
end
local function getTabStatus(tabId)
    return getTabAttribute(tabId, "Status", "idle")
end
local function setTabBadge(tabId, badgeText)
    return setTabAttribute(tabId, "Badge", validateDisplayText(badgeText, 24))
end
local function getTabBadge(tabId)
    return getTabAttribute(tabId, "Badge", "")
end
local function setTabEnabled(tabId, enabled)
    setTabButtonEnabled(tabId, enabled)
    setTabAttribute(tabId, "Enabled", enabled == true)
end
local function isTabEnabled(tabId)
    return getTabAttribute(tabId, "Enabled", true) == true
end
local function getEnabledTabIds()
    local result = {}
    for _, tabId in ipairs(getOrderedTabIds()) do
        if isTabEnabled(tabId) then result[#result + 1] = tabId end
    end
    return result
end
local function getEnabledTabCount()
    return #getEnabledTabIds()
end
local function resetTabStatuses()
    for tabId in pairs(tabs) do setTabStatus(tabId, "idle") end
end
local function setCurrentTabStatus(status)
    return setTabStatus(RuntimeState.selectedTab, status)
end
local function getCurrentTabStatus()
    return getTabStatus(RuntimeState.selectedTab)
end
local function markCurrentTabBusy()
    return setCurrentTabStatus("busy")
end
local function markCurrentTabIdle()
    return setCurrentTabStatus("idle")
end
local function markCurrentTabComplete()
    return setCurrentTabStatus("complete")
end
local function markCurrentTabError()
    return setCurrentTabStatus("error")
end
local function getStatusColor(status)
    local normalized = string.lower(normalizeText(status))
    if normalized == "complete" then return Color3.fromRGB(74, 201, 135) end
    if normalized == "busy" then return Theme.accent end
    if normalized == "error" then return Color3.fromRGB(235, 90, 95) end
    return Color3.fromRGB(140, 150, 165)
end
local function setStatusDot(dot, status)
    if not dot or not dot:IsA("GuiObject") then return false end
    dot.BackgroundColor3 = getStatusColor(status)
    return true
end
local function getInteractionByIndex(index)
    local numericIndex = clampNumber(index, 1, math.max(1, #RuntimeState.notifications))
    return RuntimeState.notifications[numericIndex]
end
local function removeInteractionByIndex(index)
    local numericIndex = clampNumber(index, 1, #RuntimeState.notifications)
    if #RuntimeState.notifications == 0 then return false end
    table.remove(RuntimeState.notifications, numericIndex)
    updateRevision()
    return true
end
local function filterInteractions(query)
    local result = {}
    for _, item in ipairs(RuntimeState.notifications) do
        if searchTextMatches(item.tab, query) or searchTextMatches(item.feature, query) or searchTextMatches(item.value, query) then
            result[#result + 1] = item
        end
    end
    return result
end
local function getInteractionSummary(item)
    if type(item) ~= "table" then return "Unknown interaction" end
    return tostring(item.tab) .. " · " .. tostring(item.feature) .. " · " .. tostring(item.value)
end
local function createNotificationPayload(title, message)
    return {
        title = getSafeTitle(title),
        message = validateDisplayText(message, 220),
        timestamp = os.clock(),
        mode = getFeatureModeLabel()
    }
end
local function isNotificationPayloadValid(payload)
    return type(payload) == "table" and isUsableText(payload.title) and isUsableText(payload.message)
end
local function recordNotification(title, message)
    local payload = createNotificationPayload(title, message)
    if not isNotificationPayloadValid(payload) then return false end
    RuntimeState.notifications[#RuntimeState.notifications + 1] = payload
    while #RuntimeState.notifications > 100 do table.remove(RuntimeState.notifications, 1) end
    return true
end
local function getNotificationHistory()
    return copyArray(RuntimeState.notifications)
end
local function clearNotificationHistory()
    clearInteractionHistory()
end
local function getNotificationCount()
    return #RuntimeState.notifications
end
local function setNotificationLimit(limit)
    local maximum = clampNumber(limit, 10, 250)
    while #RuntimeState.notifications > maximum do table.remove(RuntimeState.notifications, 1) end
    setPreference("notifications.limit", maximum)
end
local function getNotificationLimit()
    return getNumberPreference("notifications.limit", 100, 10, 250)
end
local function applyNotificationLimit()
    setNotificationLimit(getNotificationLimit())
end
local function getPanelSafeArea()
    local viewport = getSafeViewportSize()
    local margin = getViewportInsets()
    return { left = margin.X, top = margin.Y, right = viewport.X - margin.X, bottom = viewport.Y - margin.Y }
end
local function calculateCenteredPosition(width, height)
    local viewport = getSafeViewportSize()
    return UDim2.fromOffset(math.max(0, (viewport.X - width) / 2), math.max(0, (viewport.Y - height) / 2))
end
local function centerPanel()
    if not main then return false end
    main.Position = calculateCenteredPosition(main.AbsoluteSize.X, main.AbsoluteSize.Y)
    return true
end
local function resetPanelPosition()
    return centerPanel()
end
local function getScreenGui()
    return screen
end
local function getMainPanel()
    return main
end
local function getFloatingButton()
    return floating
end
local function getSidebar()
    return sidebar
end
local function getContentFrame()
    return content
end
local function getContentScrollFrame()
    return contentScroll
end
local function getHeaderFrame()
    return header
end
local function getStatusBadge()
    return statusBadge
end
local function isInstanceAlive(instance)
    return instance ~= nil and instance.Parent ~= nil
end
local function countDescendants(instance)
    if not isInstanceAlive(instance) then return 0 end
    return #instance:GetDescendants()
end
local function getScreenComplexity()
    return {
        descendants = countDescendants(screen),
        panelDescendants = countDescendants(main),
        sidebarDescendants = countDescendants(sidebar),
        contentDescendants = countDescendants(contentScroll)
    }
end
local function setPanelActive(active)
    if not main then return false end
    main.Active = active == true
    return true
end
local function setPanelSelectable(selectable)
    if not main then return false end
    main.Selectable = selectable == true
    return true
end
local function setSidebarScrollEnabled(enabled)
    if not sidebar then return false end
    sidebar.ScrollingEnabled = enabled == true
    return true
end
local function setContentScrollEnabled(enabled)
    if not contentScroll then return false end
    contentScroll.ScrollingEnabled = enabled == true
    return true
end
local function resetScrollPositions()
    if sidebar then sidebar.CanvasPosition = Vector2.zero end
    if contentScroll then contentScroll.CanvasPosition = Vector2.zero end
end
local function getScrollPositions()
    return {
        sidebar = sidebar and sidebar.CanvasPosition or Vector2.zero,
        content = contentScroll and contentScroll.CanvasPosition or Vector2.zero
    }
end
local function restoreScrollPositions(snapshot)
    if type(snapshot) ~= "table" then return false end
    if sidebar and typeof(snapshot.sidebar) == "Vector2" then sidebar.CanvasPosition = snapshot.sidebar end
    if contentScroll and typeof(snapshot.content) == "Vector2" then contentScroll.CanvasPosition = snapshot.content end
    return true
end
local function getUIStateSnapshot()
    return {
        session = makeSessionSnapshot(),
        scroll = getScrollPositions(),
        size = getPanelSize(),
        position = getPanelPosition(),
        scale = getCurrentViewportScale()
    }
end
local function restoreUIStateSnapshot(snapshot)
    if type(snapshot) ~= "table" then return false end
    if snapshot.session then restoreSessionSnapshot(snapshot.session) end
    if snapshot.scroll then restoreScrollPositions(snapshot.scroll) end
    if typeof(snapshot.size) == "Vector2" and main then main.Size = UDim2.fromOffset(snapshot.size.X, snapshot.size.Y) end
    if typeof(snapshot.position) == "Vector2" and main then main.Position = UDim2.fromOffset(snapshot.position.X, snapshot.position.Y) end
    if snapshot.scale then setCurrentViewportScale(snapshot.scale) end
    return true
end
local function setCompactDensity(enabled)
    setBooleanPreference("ui.compactDensity", enabled)
    local density = enabled and 26 or 32
    for _, descendant in ipairs(screen:GetDescendants()) do
        if descendant:IsA("TextButton") and descendant:GetAttribute("IsTabButton") then
            descendant.Size = UDim2.new(descendant.Size.X.Scale, descendant.Size.X.Offset, 0, density)
        end
    end
end
local function setOutlineContrast(enabled)
    setBooleanPreference("ui.outlineContrast", enabled)
    for _, descendant in ipairs(screen:GetDescendants()) do
        local outline = descendant:FindFirstChildOfClass("UIStroke")
        if outline then outline.Transparency = enabled and 0 or 0.22 end
    end
end
local function setSurfaceDepth(enabled)
    setBooleanPreference("ui.surfaceDepth", enabled)
    for _, descendant in ipairs(screen:GetDescendants()) do
        if descendant:IsA("Frame") and descendant.Name:lower():find("card", 1, true) then
            descendant.BackgroundTransparency = enabled and 0 or 0.08
        end
    end
end
local function setAccentGlow(enabled)
    setBooleanPreference("ui.accentGlow", enabled)
    if topGlow then topGlow.Visible = enabled == true end
end
local function setAnimationPreference(enabled)
    setBooleanPreference("ui.animations", enabled)
end
local function areAnimationsEnabled()
    return getBooleanPreference("ui.animations", true) and not getBooleanPreference("ui.reduceMotion", false)
end
local function getAnimationDuration(defaultDuration)
    return areAnimationsEnabled() and clampNumber(defaultDuration or 0.12, 0.03, 0.5) or 0.03
end
local function createHoverEffect(buttonObject)
    if not buttonObject or not buttonObject:IsA("GuiButton") then return false end
    local baseColor = buttonObject.BackgroundColor3
    createSafeConnection(buttonObject.MouseEnter, function()
        if areAnimationsEnabled() then
            TweenService:Create(buttonObject, TweenInfo.new(getAnimationDuration(0.1)), { BackgroundColor3 = Theme.surfaceHi }):Play()
        else
            buttonObject.BackgroundColor3 = Theme.surfaceHi
        end
    end)
    createSafeConnection(buttonObject.MouseLeave, function()
        if buttonObject.Parent then buttonObject.BackgroundColor3 = baseColor end
    end)
    return true
end
local function applyHoverEffects()
    for _, descendant in ipairs(screen:GetDescendants()) do
        if descendant:IsA("TextButton") then createHoverEffect(descendant) end
    end
end
local function getUISettingsSummary()
    local settings = getUIConfiguration()
    local active = {}
    for key, value in pairs(settings) do if value then active[#active + 1] = key end end
    table.sort(active)
    return #active == 0 and "Default appearance" or table.concat(active, ", ")
end
local function getRuntimeDiagnostics()
    local health = runRuntimeSelfCheck()
    health.complexity = getScreenComplexity()
    health.memory = getMemoryStateSnapshot()
    health.settings = getUISettingsSummary()
    health.preferenceSummary = getPreferenceSummary()
    return health
end
local function refreshDiagnosticsAttributes()
    local diagnostics = getRuntimeDiagnostics()
    setScreenAttribute("DiagnosticReady", diagnostics.valid)
    setScreenAttribute("DiagnosticTabs", diagnostics.tabs or 0)
    setScreenAttribute("DiagnosticComponents", diagnostics.memory.componentCount or 0)
    setScreenAttribute("DiagnosticUptime", diagnostics.uptime or "00:00:00")
    return diagnostics
end
local function finalizeUISetup()
    applyControlDefaults()
    refreshCompactLayout()
    refreshAllTabLayouts()
    refreshStatusAttributes()
    refreshDiagnosticsAttributes()
end
switchTab("main")
