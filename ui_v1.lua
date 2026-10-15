--==============================================================================
-- UI_RECONSTRUCTED_TEST.lua
-- Standalone UI-only demo reconstruction.
-- Run as a LocalScript in Roblox Studio (Play mode).
-- All feature callbacks are mocked; no game automation is performed.
--==============================================================================

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
    Name = "MainWindow", Size = UDim2.fromOffset(600, 430),
    Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = Theme.background, BorderSizePixel = 0, Active = true,
}, screen)
corner(main, 15)
stroke(main, Color3.fromRGB(77, 132, 190), 1.2)
local scale = make("UIScale", {Scale = 1}, main)

-- Layered background treatment: subtle gradient, soft top glow, and inset frame.
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
    -- A small accent rail gives every group a visual anchor without wasting space.
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
end)

buildTab("Live Chat", 8, function(id)
    section(id, "Global Chat")
    paragraph(id, "Live Chat", "[Demo] No chat service is connected.")
end)

buildTab("Donate", 9, function(id)
    section(id, "Support Sena")
    paragraph(id, "Support Card", "[Demo] Donation information is not configured.")
end)

buildTab("Private Server", 10, function(id)
    section(id, "Find Private Server")
    paragraph(id, "Current Server", "DEMO STATUS\nNo server hopping is performed.")
    dropdown(id, "Max Players", "Demo selection", {"1","2","3","4","5"}, false, "2")
    button(id, "Hop Server Now", "Demo action only.")
    toggle(id, "Auto Hop", "Demo toggle only.", false)
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

-- Drag support for mouse/touch.
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

-- Scale the fixed 720x520 design down on small viewports without changing its base size.
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
end)

switchTab("main")

print("=======================================================")
print(" SENA UI RECONSTRUCTION TEST - LOADED")
print(" Tabs: 11 | UI-only demo | Feature logic disabled")
print(" Controls only log mock interactions to Output.")
print("=======================================================")

--[[
===============================================================================
UI DETAIL SPECIFICATION / COMPONENT CATALOG
===============================================================================
This appendix is intentionally part of the source file so future UI-only edits
can preserve consistent grouping, spacing, naming, and demo-only behavior.
No entry in this catalog activates a Roblox gameplay feature or sends a request.
All actual widgets are created by the component factories above.
===============================================================================

-------------------------------------------------------------------------------
TAB: ADMIN ABUSE
-------------------------------------------------------------------------------
Tab purpose: keep related controls discoverable without crowding the compact panel.
Layout contract: one vertical scroll column; groups stay in their declared order.
Navigation contract: the sidebar selects this tab and resets scroll to the top.
Visual contract: use dark layered surfaces, muted labels, and blue accent rails.
Input contract: controls change only their local demo state or print a mock message.
Safety contract: no gameplay remotes, network requests, or automation are attached.

  GROUP: Capture The Egg
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Auto Steal Capture
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Capture The Egg.
    Parent tab: Admin Abuse.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

  GROUP: Movement
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Admin Abuse Boost
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Movement.
    Parent tab: Admin Abuse.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Fly For Capture
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Movement.
    Parent tab: Admin Abuse.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Instant Grab
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Movement.
    Parent tab: Admin Abuse.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Infinite Jump
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Movement.
    Parent tab: Admin Abuse.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Noclip
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Movement.
    Parent tab: Admin Abuse.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

  GROUP: Ring Event
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Auto Ring Event
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Ring Event.
    Parent tab: Admin Abuse.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

-------------------------------------------------------------------------------
TAB: MAIN
-------------------------------------------------------------------------------
Tab purpose: keep related controls discoverable without crowding the compact panel.
Layout contract: one vertical scroll column; groups stay in their declared order.
Navigation contract: the sidebar selects this tab and resets scroll to the top.
Visual contract: use dark layered surfaces, muted labels, and blue accent rails.
Input contract: controls change only their local demo state or print a mock message.
Safety contract: no gameplay remotes, network requests, or automation are attached.

  GROUP: Auto Steal
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Auto Steal
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Auto Steal.
    Parent tab: Main.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Help Friend
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Auto Steal.
    Parent tab: Main.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Egg Checker
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Auto Steal.
    Parent tab: Main.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Egg Spawn Analyst
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Auto Steal.
    Parent tab: Main.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Aura Bat
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Auto Steal.
    Parent tab: Main.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Steal Mode
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Auto Steal.
    Parent tab: Main.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Low Speed Multiplier
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Auto Steal.
    Parent tab: Main.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Speed Advice
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Auto Steal.
    Parent tab: Main.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

  GROUP: Egg Filter / Egg
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Filter By Egg Name
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Egg Filter / Egg.
    Parent tab: Main.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Filter By Rarity
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Egg Filter / Egg.
    Parent tab: Main.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

  GROUP: Egg Filter / Area & Value
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Select Area
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Egg Filter / Area & Value.
    Parent tab: Main.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Steal By Value
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Egg Filter / Area & Value.
    Parent tab: Main.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Filter By Mutation
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Egg Filter / Area & Value.
    Parent tab: Main.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Steal By Weight
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Egg Filter / Area & Value.
    Parent tab: Main.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Steal Priority
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Egg Filter / Area & Value.
    Parent tab: Main.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Auto Index
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Egg Filter / Area & Value.
    Parent tab: Main.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

  GROUP: Egg ESP
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Egg ESP
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Egg ESP.
    Parent tab: Main.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: ESP Details
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Egg ESP.
    Parent tab: Main.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: ESP Min Rarity
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Egg ESP.
    Parent tab: Main.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: ESP Min Value
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Egg ESP.
    Parent tab: Main.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Backpack Value/s
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Egg ESP.
    Parent tab: Main.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

  GROUP: Steal Webhook
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Steal Webhook
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Steal Webhook.
    Parent tab: Main.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Webhook URL
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Steal Webhook.
    Parent tab: Main.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Disconnect Alert
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Steal Webhook.
    Parent tab: Main.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Notify Rarities
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Steal Webhook.
    Parent tab: Main.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Notify Minimum Value
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Steal Webhook.
    Parent tab: Main.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Test Webhook
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Steal Webhook.
    Parent tab: Main.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

-------------------------------------------------------------------------------
TAB: AUTO
-------------------------------------------------------------------------------
Tab purpose: keep related controls discoverable without crowding the compact panel.
Layout contract: one vertical scroll column; groups stay in their declared order.
Navigation contract: the sidebar selects this tab and resets scroll to the top.
Visual contract: use dark layered surfaces, muted labels, and blue accent rails.
Input contract: controls change only their local demo state or print a mock message.
Safety contract: no gameplay remotes, network requests, or automation are attached.

  GROUP: Egg Automation / Place
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Auto Place Egg
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Egg Automation / Place.
    Parent tab: Auto.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Place Egg Rarity
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Egg Automation / Place.
    Parent tab: Auto.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

  GROUP: Egg Automation / Hatch
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Auto Hatch Egg
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Egg Automation / Hatch.
    Parent tab: Auto.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

  GROUP: Egg Automation / Mutate
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Select Mutation
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Egg Automation / Mutate.
    Parent tab: Auto.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Mutate Egg Name
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Egg Automation / Mutate.
    Parent tab: Auto.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Mutate Egg Rarity
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Egg Automation / Mutate.
    Parent tab: Auto.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Mutate Min Value
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Egg Automation / Mutate.
    Parent tab: Auto.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Retry Until Mutated
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Egg Automation / Mutate.
    Parent tab: Auto.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Auto Apply Mutation
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Egg Automation / Mutate.
    Parent tab: Auto.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Apply Mutation Now
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Egg Automation / Mutate.
    Parent tab: Auto.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

  GROUP: Equip & Collect
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Auto Equip Best
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Equip & Collect.
    Parent tab: Auto.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Collect Offline Income
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Equip & Collect.
    Parent tab: Auto.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Auto Upgrade Base
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Equip & Collect.
    Parent tab: Auto.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Auto Claim Almanac
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Equip & Collect.
    Parent tab: Auto.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Upgrade Base Now
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Equip & Collect.
    Parent tab: Auto.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

  GROUP: Treadmill
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Auto Treadmill
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Treadmill.
    Parent tab: Auto.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Auto Upgrade Treadmill
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Treadmill.
    Parent tab: Auto.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

-------------------------------------------------------------------------------
TAB: PETS
-------------------------------------------------------------------------------
Tab purpose: keep related controls discoverable without crowding the compact panel.
Layout contract: one vertical scroll column; groups stay in their declared order.
Navigation contract: the sidebar selects this tab and resets scroll to the top.
Visual contract: use dark layered surfaces, muted labels, and blue accent rails.
Input contract: controls change only their local demo state or print a mock message.
Safety contract: no gameplay remotes, network requests, or automation are attached.

  GROUP: Pet Selling
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Auto Sell Pet
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Pet Selling.
    Parent tab: Pets.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Pet Name Filter
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Pet Selling.
    Parent tab: Pets.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Pet Rarity Filter
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Pet Selling.
    Parent tab: Pets.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Sell By Value (max)
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Pet Selling.
    Parent tab: Pets.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

  GROUP: Egg Selling
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Auto Sell Egg
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Egg Selling.
    Parent tab: Pets.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Egg Rarity Filter
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Egg Selling.
    Parent tab: Pets.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Sell Egg By Value (max)
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Egg Selling.
    Parent tab: Pets.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

  GROUP: Pet Favorite
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Auto Favorite
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Pet Favorite.
    Parent tab: Pets.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Favorite Rule
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Pet Favorite.
    Parent tab: Pets.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Rarities to Keep
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Pet Favorite.
    Parent tab: Pets.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Species to Keep
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Pet Favorite.
    Parent tab: Pets.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Unfavorite Everything
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Pet Favorite.
    Parent tab: Pets.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

  GROUP: Pet Fusion
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Auto Fuse
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Pet Fusion.
    Parent tab: Pets.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Fusion Rule
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Pet Fusion.
    Parent tab: Pets.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Rarities to Fuse
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Pet Fusion.
    Parent tab: Pets.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Species to Fuse
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Pet Fusion.
    Parent tab: Pets.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

-------------------------------------------------------------------------------
TAB: EVENTS
-------------------------------------------------------------------------------
Tab purpose: keep related controls discoverable without crowding the compact panel.
Layout contract: one vertical scroll column; groups stay in their declared order.
Navigation contract: the sidebar selects this tab and resets scroll to the top.
Visual contract: use dark layered surfaces, muted labels, and blue accent rails.
Input contract: controls change only their local demo state or print a mock message.
Safety contract: no gameplay remotes, network requests, or automation are attached.

  GROUP: Butterfly Bloom
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Bloom Status
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Butterfly Bloom.
    Parent tab: Events.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Auto Claim Net
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Butterfly Bloom.
    Parent tab: Events.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Auto Catch
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Butterfly Bloom.
    Parent tab: Events.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Catch Mode
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Butterfly Bloom.
    Parent tab: Events.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Catch Tiers
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Butterfly Bloom.
    Parent tab: Events.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Butterfly ESP
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Butterfly Bloom.
    Parent tab: Events.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Auto Trade Up
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Butterfly Bloom.
    Parent tab: Events.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Trade Recipe
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Butterfly Bloom.
    Parent tab: Events.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Auto Craft Essence
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Butterfly Bloom.
    Parent tab: Events.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Claim Net Now
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Butterfly Bloom.
    Parent tab: Events.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Trade Up Now
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Butterfly Bloom.
    Parent tab: Events.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Craft Essence Now
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Butterfly Bloom.
    Parent tab: Events.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

  GROUP: Dr Scramble Event
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: About This Event
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Dr Scramble Event.
    Parent tab: Events.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Auto Buy Shop
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Dr Scramble Event.
    Parent tab: Events.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Shop Buy List
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Dr Scramble Event.
    Parent tab: Events.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Auto Trade-In
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Dr Scramble Event.
    Parent tab: Events.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Auto Free Reroll
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Dr Scramble Event.
    Parent tab: Events.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Target Banners
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Dr Scramble Event.
    Parent tab: Events.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Trade-In Once
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Dr Scramble Event.
    Parent tab: Events.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Use Free Reroll
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Dr Scramble Event.
    Parent tab: Events.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Open Trade-In UI
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Dr Scramble Event.
    Parent tab: Events.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Auto Boss
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Dr Scramble Event.
    Parent tab: Events.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Boss Status
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Dr Scramble Event.
    Parent tab: Events.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

-------------------------------------------------------------------------------
TAB: MISC
-------------------------------------------------------------------------------
Tab purpose: keep related controls discoverable without crowding the compact panel.
Layout contract: one vertical scroll column; groups stay in their declared order.
Navigation contract: the sidebar selects this tab and resets scroll to the top.
Visual contract: use dark layered surfaces, muted labels, and blue accent rails.
Input contract: controls change only their local demo state or print a mock message.
Safety contract: no gameplay remotes, network requests, or automation are attached.

  GROUP: Performance
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Startup Boost
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Performance.
    Parent tab: Misc.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Boost FPS
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Performance.
    Parent tab: Misc.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Uncap FPS
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Performance.
    Parent tab: Misc.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

  GROUP: Guard
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Anti Guard Knockback
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Guard.
    Parent tab: Misc.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Anti Hit Guard
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Guard.
    Parent tab: Misc.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

  GROUP: Windows
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Egg Logs
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Windows.
    Parent tab: Misc.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Egg Board
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Windows.
    Parent tab: Misc.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Inventory & Base
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Windows.
    Parent tab: Misc.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Egg Checker
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Windows.
    Parent tab: Misc.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Egg Data & History
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Windows.
    Parent tab: Misc.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Open All Windows
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Windows.
    Parent tab: Misc.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

  GROUP: Blocker
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Anti Treadmill
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Blocker.
    Parent tab: Misc.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

  GROUP: Server Hop
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Hop When Nothing Matches
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Server Hop.
    Parent tab: Misc.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Hop Cooldown
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Server Hop.
    Parent tab: Misc.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

  GROUP: Roaming
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Waypoint
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Roaming.
    Parent tab: Misc.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Teleport To Waypoint
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Roaming.
    Parent tab: Misc.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

  GROUP: Run Once
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Place Everything Now
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Run Once.
    Parent tab: Misc.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Hatch Everything Ready
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Run Once.
    Parent tab: Misc.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Sell Pets Now
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Run Once.
    Parent tab: Misc.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Sell Eggs Now
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Run Once.
    Parent tab: Misc.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

  GROUP: Session
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Botting Mode
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Session.
    Parent tab: Misc.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Anti Cutscene
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Session.
    Parent tab: Misc.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Rejoin This Server
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Session.
    Parent tab: Misc.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Stop & Unload
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Session.
    Parent tab: Misc.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

  GROUP: Player
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Anti AFK
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Player.
    Parent tab: Misc.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Auto Reconnect
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Player.
    Parent tab: Misc.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Auto Execute (Rejoin)
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Player.
    Parent tab: Misc.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

-------------------------------------------------------------------------------
TAB: STEAL PLAYERS
-------------------------------------------------------------------------------
Tab purpose: keep related controls discoverable without crowding the compact panel.
Layout contract: one vertical scroll column; groups stay in their declared order.
Navigation contract: the sidebar selects this tab and resets scroll to the top.
Visual contract: use dark layered surfaces, muted labels, and blue accent rails.
Input contract: controls change only their local demo state or print a mock message.
Safety contract: no gameplay remotes, network requests, or automation are attached.

  GROUP: Auto Steal
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Auto Steal From Players
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Auto Steal.
    Parent tab: Steal Players.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Rarity Filter
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Auto Steal.
    Parent tab: Steal Players.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Minimum Value
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Auto Steal.
    Parent tab: Steal Players.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

  GROUP: Steal From Specific Player
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Players in this server
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Steal From Specific Player.
    Parent tab: Steal Players.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

  GROUP: Steal History
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: History
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Steal History.
    Parent tab: Steal Players.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Clear History
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Steal History.
    Parent tab: Steal Players.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

-------------------------------------------------------------------------------
TAB: LIVE CHAT
-------------------------------------------------------------------------------
Tab purpose: keep related controls discoverable without crowding the compact panel.
Layout contract: one vertical scroll column; groups stay in their declared order.
Navigation contract: the sidebar selects this tab and resets scroll to the top.
Visual contract: use dark layered surfaces, muted labels, and blue accent rails.
Input contract: controls change only their local demo state or print a mock message.
Safety contract: no gameplay remotes, network requests, or automation are attached.

  GROUP: Global Chat
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Live Chat
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Global Chat.
    Parent tab: Live Chat.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

-------------------------------------------------------------------------------
TAB: DONATE
-------------------------------------------------------------------------------
Tab purpose: keep related controls discoverable without crowding the compact panel.
Layout contract: one vertical scroll column; groups stay in their declared order.
Navigation contract: the sidebar selects this tab and resets scroll to the top.
Visual contract: use dark layered surfaces, muted labels, and blue accent rails.
Input contract: controls change only their local demo state or print a mock message.
Safety contract: no gameplay remotes, network requests, or automation are attached.

  GROUP: Support Sena
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Support Card
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Support Sena.
    Parent tab: Donate.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

-------------------------------------------------------------------------------
TAB: PRIVATE SERVER
-------------------------------------------------------------------------------
Tab purpose: keep related controls discoverable without crowding the compact panel.
Layout contract: one vertical scroll column; groups stay in their declared order.
Navigation contract: the sidebar selects this tab and resets scroll to the top.
Visual contract: use dark layered surfaces, muted labels, and blue accent rails.
Input contract: controls change only their local demo state or print a mock message.
Safety contract: no gameplay remotes, network requests, or automation are attached.

  GROUP: Find Private Server
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Current Server
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Find Private Server.
    Parent tab: Private Server.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Max Players
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Find Private Server.
    Parent tab: Private Server.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Hop Server Now
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Find Private Server.
    Parent tab: Private Server.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Auto Hop
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Find Private Server.
    Parent tab: Private Server.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

-------------------------------------------------------------------------------
TAB: VISUAL
-------------------------------------------------------------------------------
Tab purpose: keep related controls discoverable without crowding the compact panel.
Layout contract: one vertical scroll column; groups stay in their declared order.
Navigation contract: the sidebar selects this tab and resets scroll to the top.
Visual contract: use dark layered surfaces, muted labels, and blue accent rails.
Input contract: controls change only their local demo state or print a mock message.
Safety contract: no gameplay remotes, network requests, or automation are attached.

  GROUP: Fish It / Rods
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Select Rod
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Fish It / Rods.
    Parent tab: Visual.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Spawn Rod
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Fish It / Rods.
    Parent tab: Visual.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Rod Size
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Fish It / Rods.
    Parent tab: Visual.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

  GROUP: Fish It / Fish
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Select Fish
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Fish It / Fish.
    Parent tab: Visual.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Spawn Fish
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Fish It / Fish.
    Parent tab: Visual.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Fish Weight
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Fish It / Fish.
    Parent tab: Visual.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

  GROUP: Fish It / Manage
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Status
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Fish It / Manage.
    Parent tab: Visual.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Remove All Visual Items
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Fish It / Manage.
    Parent tab: Visual.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

  GROUP: Steal an Egg
  -----------------------------------------------------------------------------
  Grouping rationale: related controls are placed together to reduce scanning.
  Heading style: compact uppercase title with a thin low-contrast divider.
  Spacing style: consistent vertical rhythm; avoid oversized empty containers.
  Card style: rounded dark gradient, fine outline, subtle accent on the leading edge.
  Responsive style: the main panel scales down to fit narrow viewports.

    COMPONENT: Type
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Steal an Egg.
    Parent tab: Visual.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Select Egg / Pet
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Steal an Egg.
    Parent tab: Visual.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Size / Flex
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Steal an Egg.
    Parent tab: Visual.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Hold in Hand
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Steal an Egg.
    Parent tab: Visual.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Add to Backpack (Kg)
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Steal an Egg.
    Parent tab: Visual.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

    COMPONENT: Remove Egg / Pet Visuals
    Component identity: preserve this label unless the feature specification changes.
    Parent group: Steal an Egg.
    Parent tab: Visual.
    Layout rule: align the title with other controls in the same group.
    Typography rule: use Gotham-family fonts and compact readable sizing.
    Surface rule: keep contrast sufficient against the charcoal background.
    Border rule: prefer smooth rounded corners and thin low-contrast outlines.
    Accent rule: blue is reserved for active, selected, or highlighted states.
    Interaction rule: hover/pressed states should be subtle and quick.
    State rule: toggles and selectors represent local demo state only.
    Feedback rule: buttons report mock interactions rather than running game actions.
    Scroll rule: component height must remain small enough for a dense settings list.
    Grouping rule: do not move this control outside its named feature group.
    Maintenance rule: update this catalog if the control is renamed or relocated.
    Accessibility rule: avoid relying on color alone to communicate selection.
    Consistency rule: use the shared component factory instead of ad-hoc styling.
    Performance rule: avoid adding per-frame loops for purely decorative effects.
    Scope rule: this component must remain part of the UI reconstruction demo.

===============================================================================
GLOBAL VISUAL QA CHECKLIST
===============================================================================

QA-001: Main panel uses a compact fixed base size of 600 by 430 pixels.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-002: Viewport fitting scales the panel down when the screen is smaller than the base size.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-003: Outer corners use a smooth rounded radius with a restrained blue-gray outline.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-004: Inner inset border separates the panel from the background without a heavy frame.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-005: Header remains short and avoids consuming space needed by tab content.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-006: Sidebar remains narrower than the content region to prioritize settings readability.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-007: Sidebar is scrollable so all eleven tabs remain reachable on short displays.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-008: Content region uses its own scroll container and resets position when changing tabs.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-009: Selected tab has an indicator rail and stronger label contrast.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-010: Inactive tabs use muted text and restrained hover feedback.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-011: Group headings use a small accent rail and hairline divider.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-012: Cards use a subtle gradient rather than a flat empty fill.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-013: Card borders are thin and softened to avoid a harsh boxed-in appearance.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-014: Blue accents are used sparingly to preserve visual hierarchy.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-015: Status badges remain distinct from ordinary settings controls.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-016: Close button remains visible in the header.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-017: Floating toggle allows the panel to be reopened after hiding it.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-018: Mouse and touch dragging remain supported.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-019: All tab component containers are detached and reattached when switching tabs.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-020: Dropdown menus remain inside the owning screen GUI.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-021: Long option lists use scrolling rather than extending beyond the viewport.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-022: Text inputs retain placeholder text and local-only values.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-023: Sliders update their visual fill and displayed demo value.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-024: Toggle controls visually distinguish on and off states.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-025: Buttons provide feedback through the demo notification/output path.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-026: Descriptions clearly indicate that feature behavior is not connected.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-027: No actual exploit, game automation, remote invocation, or network transmission exists.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-028: No third-party image URL is assumed to be a Roblox asset identifier.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-029: Decorative gradients use native Roblox UIGradient instances.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-030: Rounded corners use UICorner instances rather than raster images.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-031: Borders use UIStroke with low thickness.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-032: Decorative elements should not cover labels or block button input.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-033: ZIndex should keep decorative elements behind text and interactive controls.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-034: Text should truncate gracefully when the panel is scaled down.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-035: Tab labels should remain legible at the compact panel's normal scale.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-036: Feature groups should remain in their existing semantic order.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-037: Do not introduce extra tabs without updating the catalog and icon map.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-038: Do not add unrequested features merely to fill empty space.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-039: Use shared helpers for consistent corner, stroke, padding, and object creation.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-040: Keep cleanup connections scoped to the ScreenGui lifetime.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-041: Recheck camera viewport binding if viewport scaling is changed.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-042: Keep this source runnable as a Roblox Studio LocalScript.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-043: Prefer maintainable names for UI instances and helper functions.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-044: Use consistent capitalization for component names and tab labels.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-045: Keep the dark palette neutral; avoid turning the interface purple.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-046: Use the existing blue accent as the primary interactive color.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-047: Use a white/gray text hierarchy rather than multiple bright text colors.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-048: Keep hover animations short so the interface feels responsive.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-049: Keep the floating icon visually related to the main panel.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-050: Do not add external web calls to a UI-only LocalScript.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

QA-051: Keep each feature's callbacks mocked and clearly identified as such.
Verification note: inspect this item whenever the corresponding UI area is edited.
Regression note: visual polish must not alter the demo-only behavior contract.

END OF UI DETAIL SPECIFICATION
]]
