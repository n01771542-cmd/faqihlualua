--[[ =============================================================================
  leon4951hub AutoClicker - Compact UI 45x180
  Versi diperbaiki (bisa di-execute)
============================================================================= ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Hapus UI lama
local GUI_NAME = "leon4951hub_ac"
local old = playerGui:FindFirstChild(GUI_NAME)
if old then old:Destroy() end

local GEN = (tonumber(playerGui:GetAttribute("leon_ac_gen")) or 0) + 1
playerGui:SetAttribute("leon_ac_gen", GEN)

local function stale()
	return playerGui:GetAttribute("leon_ac_gen") \~= GEN
end

local CPS_MAX = 25

-- STATE
local S = {
	running = false,
	cps = 10,
	right = false,
	mode = "cursor",
	point = nil,
	limit = 0,
	key = Enum.KeyCode.F6,
	count = 0,
	startedAt = 0,
	binding = false,
	settingPoint = false,
	method = nil,
	destroyed = false,
	settingsOpen = false,
}

-- WARNA
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local T = {
	Bg = rgb(18, 20, 28),
	Surface = rgb(28, 30, 42),
	Surface2 = rgb(38, 42, 58),
	Stroke = rgb(55, 60, 85),
	Text = rgb(240, 242, 250),
	Dim = rgb(150, 155, 180),
	Accent = rgb(70, 130, 255),
	Ok = rgb(60, 200, 120),
	Danger = rgb(230, 70, 90),
}

-- HELPER
local function mk(class, props, kids)
	local o = Instance.new(class)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then
			parent = v
		else
			o[k] = v
		end
	end
	if kids then
		for _, c in ipairs(kids) do
			c.Parent = o
		end
	end
	if parent then
		o.Parent = parent
	end
	return o
end

local function corner(o, r)
	return mk("UICorner", {CornerRadius = UDim.new(0, r or 8), Parent = o})
end

local function stroke(o, color, th)
	return mk("UIStroke", {
		Color = color or T.Stroke,
		Thickness = th or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = o
	})
end

-- METODE KLIK
local VIM
pcall(function()
	VIM = game:GetService("VirtualInputManager")
end)

local function sendClick(x, y, right)
	local order = S.method and {S.method} or {"vim", "exec", "vu"}
	for _, m in ipairs(order) do
		local ok = false
		if m == "vim" and VIM then
			ok = pcall(function()
				local idx = right and 1 or 0
				VIM:SendMouseButtonEvent(x, y, idx, true, game, 0)
				VIM:SendMouseButtonEvent(x, y, idx, false, game, 0)
			end)
		elseif m == "exec" then
			local fn = right and mouse2click or mouse1click
			if fn then
				ok = pcall(function()
					if mousemoveabs and S.mode == "fixed" then
						mousemoveabs(x, y)
					end
					fn()
				end)
			end
		elseif m == "vu" then
			ok = pcall(function()
				local VU = game:GetService("VirtualUser")
				local cf = Workspace.CurrentCamera.CFrame
				local p = Vector2.new(x, y)
				if right then
					VU:Button2Down(p, cf)
					VU:Button2Up(p, cf)
				else
					VU:Button1Down(p, cf)
					VU:Button1Up(p, cf)
				end
			end)
		end
		if ok then
			S.method = m
			return m
		end
	end
	return nil
end

-- ===================== UI UTAMA (45 x 180) =====================
local W, H = 45, 180

local gui = mk("ScreenGui", {
	Name = GUI_NAME,
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 99,
	Parent = playerGui,
})

local bar = mk("Frame", {
	Size = UDim2.fromOffset(W, H),
	Position = UDim2.new(0, 12, 0.5, -H/2),
	BackgroundColor3 = T.Bg,
	BorderSizePixel = 0,
	Parent = gui,
})
corner(bar, 14)
stroke(bar, T.Stroke, 1.5)

mk("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Top,
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = bar,
})

mk("UIPadding", {
	PaddingTop = UDim.new(0, 10),
	PaddingBottom = UDim.new(0, 8),
	Parent = bar,
})

local function makeBtn(text, bg, order)
	local b = mk("TextButton", {
		Size = UDim2.fromOffset(33, 33),
		BackgroundColor3 = bg or T.Surface2,
		Text = text,
		TextSize = 15,
		Font = Enum.Font.GothamBold,
		TextColor3 = T.Text,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		LayoutOrder = order,
		Parent = bar,
	})
	corner(b, 9)
	return b
end

local startBtn   = makeBtn("▶", T.Ok, 1)
local plusBtn    = makeBtn("+", T.Surface2, 2)
local minusBtn   = makeBtn("−", T.Surface2, 3)
local setBtn     = makeBtn("⚙", T.Surface2, 4)
local expandBtn  = makeBtn("▣", T.Accent, 5)
local destroyBtn = makeBtn("✕", rgb(120, 40, 56), 6)

-- Status kecil di bawah
local statusL = mk("TextLabel", {
	Size = UDim2.fromOffset(45, 16),
	Position = UDim2.new(0, 0, 1, 2),
	BackgroundTransparency = 1,
	Text = "OFF",
	TextSize = 11,
	Font = Enum.Font.GothamBold,
	TextColor3 = T.Danger,
	Parent = bar,
})

local cpsL = mk("TextLabel", {
	Size = UDim2.fromOffset(45, 14),
	Position = UDim2.new(0, 0, 1, 16),
	BackgroundTransparency = 1,
	Text = "10/s",
	TextSize = 10,
	Font = Enum.Font.Gotham,
	TextColor3 = T.Dim,
	Parent = bar,
})

-- ===================== PANEL SETTING =====================
local setFrame = mk("Frame", {
	Size = UDim2.fromOffset(250, 320),
	Position = UDim2.new(0, 65, 0.5, -160),
	BackgroundColor3 = T.Bg,
	BorderSizePixel = 0,
	Visible = false,
	Parent = gui,
})
corner(setFrame, 12)
stroke(setFrame, T.Stroke, 1.5)

mk("TextLabel", {
	Size = UDim2.new(1, -40, 0, 28),
	Position = UDim2.fromOffset(12, 6),
	BackgroundTransparency = 1,
	Text = "Setting",
	TextSize = 15,
	Font = Enum.Font.GothamBold,
	TextColor3 = T.Text,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = setFrame,
})

local closeSet = mk("TextButton", {
	Size = UDim2.fromOffset(26, 26),
	Position = UDim2.new(1, -34, 0, 7),
	BackgroundColor3 = T.Surface2,
	Text = "✕",
	TextSize = 13,
	Font = Enum.Font.GothamBold,
	TextColor3 = T.Text,
	AutoButtonColor = false,
	Parent = setFrame,
})
corner(closeSet, 7)

local setContent = mk("ScrollingFrame", {
	Position = UDim2.fromOffset(0, 38),
	Size = UDim2.new(1, 0, 1, -46),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 3,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Parent = setFrame,
})

mk("UIPadding", {
	PaddingLeft = UDim.new(0, 12),
	PaddingRight = UDim.new(0, 12),
	PaddingTop = UDim.new(0, 4),
	PaddingBottom = UDim.new(0, 10),
	Parent = setContent,
})

mk("UIListLayout", {
	Padding = UDim.new(0, 7),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = setContent,
})

local function addLabel(txt)
	return mk("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Text = txt,
		TextSize = 11,
		Font = Enum.Font.GothamBold,
		TextColor3 = T.Dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = setContent,
	})
end

addLabel("KECEPATAN (1-25)")
local cpsBox = mk("TextBox", {
	Size = UDim2.new(1, 0, 0, 30),
	BackgroundColor3 = T.Surface,
	Text = "10",
	TextColor3 = T.Text,
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	ClearTextOnFocus = false,
	Parent = setContent,
})
corner(cpsBox, 7)

addLabel("TOMBOL MOUSE")
local mouseRow = mk("Frame", {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Parent = setContent})
mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), Parent = mouseRow})

local leftBtn = mk("TextButton", {
	Size = UDim2.new(0.5, -3, 1, 0),
	BackgroundColor3 = T.Accent,
	Text = "Kiri",
	TextSize = 12,
	Font = Enum.Font.GothamBold,
	TextColor3 = T.Text,
	AutoButtonColor = false,
	Parent = mouseRow,
})
corner(leftBtn, 7)

local rightBtn = mk("TextButton", {
	Size = UDim2.new(0.5, -3, 1, 0),
	BackgroundColor3 = T.Surface2,
	Text = "Kanan",
	TextSize = 12,
	Font = Enum.Font.GothamBold,
	TextColor3 = T.Text,
	AutoButtonColor = false,
	Parent = mouseRow,
})
corner(rightBtn, 7)

addLabel("POSISI KLIK")
local modeRow = mk("Frame", {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Parent = setContent})
mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), Parent = modeRow})

local cursorBtn = mk("TextButton", {
	Size = UDim2.new(0.5, -3, 1, 0),
	BackgroundColor3 = T.Accent,
	Text = "Ikuti Kursor",
	TextSize = 11,
	Font = Enum.Font.GothamBold,
	TextColor3 = T.Text,
	AutoButtonColor = false,
	Parent = modeRow,
})
corner(cursorBtn, 7)

local fixedBtn = mk("TextButton", {
	Size = UDim2.new(0.5, -3, 1, 0),
	BackgroundColor3 = T.Surface2,
	Text = "Titik Tetap",
	TextSize = 11,
	Font = Enum.Font.GothamBold,
	TextColor3 = T.Text,
	AutoButtonColor = false,
	Parent = modeRow,
})
corner(fixedBtn, 7)

local pointInfo = mk("TextLabel", {
	Size = UDim2.new(1, 0, 0, 15),
	BackgroundTransparency = 1,
	Text = "Mengikuti kursor",
	TextSize = 11,
	Font = Enum.Font.Gotham,
	TextColor3 = T.Dim,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = setContent,
})

local setPointBtn = mk("TextButton", {
	Size = UDim2.new(1, 0, 0, 28),
	BackgroundColor3 = T.Surface2,
	Text = "🎯 Atur Titik",
	TextSize = 12,
	Font = Enum.Font.GothamBold,
	TextColor3 = T.Text,
	AutoButtonColor = false,
	Visible = false,
	Parent = setContent,
})
corner(setPointBtn, 7)

addLabel("BATAS KLIK (0 = unlimited)")
local limitBox = mk("TextBox", {
	Size = UDim2.new(1, 0, 0, 30),
	BackgroundColor3 = T.Surface,
	Text = "0",
	TextColor3 = T.Text,
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	ClearTextOnFocus = false,
	Parent = setContent,
})
corner(limitBox, 7)

addLabel("HOTKEY")
local keyBtn = mk("TextButton", {
	Size = UDim2.new(1, 0, 0, 30),
	BackgroundColor3 = T.Surface2,
	Text = "F6",
	TextSize = 13,
	Font = Enum.Font.GothamBold,
	TextColor3 = T.Text,
	AutoButtonColor = false,
	Parent = setContent,
})
corner(keyBtn, 7)

-- Marker titik
local marker = mk("Frame", {
	Size = UDim2.fromOffset(18, 18),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 100,
	Parent = gui,
})
corner(marker, 9)
stroke(marker, T.Danger, 2)
mk("Frame", {
	Size = UDim2.fromOffset(4, 4),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	BackgroundColor3 = T.Danger,
	BorderSizePixel = 0,
	Parent = marker,
})

-- ===================== FUNGSI =====================
local function paintMouse()
	leftBtn.BackgroundColor3 = (not S.right) and T.Accent or T.Surface2
	rightBtn.BackgroundColor3 = S.right and T.Accent or T.Surface2
end

local function paintMode()
	cursorBtn.BackgroundColor3 = (S.mode == "cursor") and T.Accent or T.Surface2
	fixedBtn.BackgroundColor3 = (S.mode == "fixed") and T.Accent or T.Surface2
	setPointBtn.Visible = (S.mode == "fixed")
	if S.mode == "fixed" and S.point then
		pointInfo.Text = string.format("Titik: %d, %d", S.point.X, S.point.Y)
		marker.Position = UDim2.fromOffset(S.point.X, S.point.Y)
		marker.Visible = true
	else
		pointInfo.Text = (S.mode == "fixed") and "Titik belum diatur" or "Mengikuti kursor"
		marker.Visible = false
	end
end

local function refreshStatus()
	if S.running then
		startBtn.Text = "■"
		startBtn.BackgroundColor3 = T.Danger
		statusL.Text = "ON"
		statusL.TextColor3 = T.Ok
	else
		startBtn.Text = "▶"
		startBtn.BackgroundColor3 = T.Ok
		statusL.Text = "OFF"
		statusL.TextColor3 = T.Danger
	end
	cpsL.Text = S.cps .. "/s"
	cpsBox.Text = tostring(S.cps)
end

function S.setRunning(on)
	if on and not S.running then
		S.count = 0
		S.startedAt = os.clock()
	end
	S.running = on
	refreshStatus()
end

function S.toggle()
	S.setRunning(not S.running)
end

-- Event tombol
startBtn.Activated:Connect(function()
	S.toggle()
end)

plusBtn.Activated:Connect(function()
	S.cps = math.min(S.cps + 1, CPS_MAX)
	refreshStatus()
end)

minusBtn.Activated:Connect(function()
	S.cps = math.max(S.cps - 1, 1)
	refreshStatus()
end)

setBtn.Activated:Connect(function()
	S.settingsOpen = not S.settingsOpen
	setFrame.Visible = S.settingsOpen
end)

expandBtn.Activated:Connect(function()
	S.settingsOpen = true
	setFrame.Visible = true
end)

closeSet.Activated:Connect(function()
	S.settingsOpen = false
	setFrame.Visible = false
end)

-- Hapus UI (klik 2 kali)
do
	local lastClick = 0
	destroyBtn.Activated:Connect(function()
		if os.clock() - lastClick < 2 then
			S.running = false
			S.destroyed = true
			gui:Destroy()
		else
			lastClick = os.clock()
			destroyBtn.Text = "?"
			task.delay(2, function()
				if destroyBtn and destroyBtn.Parent then
					destroyBtn.Text = "✕"
				end
			end)
		end
	end)
end

-- Setting events
cpsBox.FocusLost:Connect(function()
	local v = tonumber(cpsBox.Text)
	if v then
		S.cps = math.clamp(math.floor(v), 1, CPS_MAX)
	end
	refreshStatus()
end)

leftBtn.Activated:Connect(function()
	S.right = false
	paintMouse()
end)
rightBtn.Activated:Connect(function()
	S.right = true
	paintMouse()
end)

cursorBtn.Activated:Connect(function()
	S.mode = "cursor"
	paintMode()
end)
fixedBtn.Activated:Connect(function()
	S.mode = "fixed"
	paintMode()
end)

setPointBtn.Activated:Connect(function()
	S.settingPoint = true
	pointInfo.Text = "Klik di layar sekarang..."
end)

limitBox.FocusLost:Connect(function()
	S.limit = math.max(math.floor(tonumber(limitBox.Text) or 0), 0)
	limitBox.Text = tostring(S.limit)
end)

keyBtn.Activated:Connect(function()
	S.binding = true
	keyBtn.Text = "Tekan tombol..."
end)

-- Drag bar
do
	local dragging, dragStart, startPos
	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = bar.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			bar.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

-- Cek apakah klik di UI sendiri
local function overOwnUI(pos)
	local function inside(guiObj)
		if not guiObj or not guiObj.Visible then return false end
		local ap = guiObj.AbsolutePosition
		local sz = guiObj.AbsoluteSize
		return pos.X >= ap.X and pos.X <= ap.X + sz.X and pos.Y >= ap.Y and pos.Y <= ap.Y + sz.Y
	end
	return inside(bar) or inside(setFrame)
end

-- Loop klik
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	if stale() or S.destroyed then return end
	if not S.running then return end
	if UserInputService:GetFocusedTextBox() then return end
	if S.mode == "fixed" and not S.point then
		S.setRunning(false)
		return
	end

	local interval = 1 / S.cps
	acc = acc + dt
	local n = 0
	while acc >= interval and n < 4 do
		acc = acc - interval
		n = n + 1
		local pos = (S.mode == "fixed") and S.point or UserInputService:GetMouseLocation()
		if overOwnUI(pos) then break end
		if not sendClick(pos.X, pos.Y, S.right) then
			S.setRunning(false)
			return
		end
		S.count = S.count + 1
		if S.limit > 0 and S.count >= S.limit then
			S.setRunning(false)
			return
		end
	end
	if acc > interval * 4 then acc = 0 end
end)

-- Input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if stale() or S.destroyed then return end

	if S.binding then
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode \~= Enum.KeyCode.Escape then
				S.key = input.KeyCode
			end
			S.binding = false
			keyBtn.Text = S.key.Name
		end
		return
	end

	if S.settingPoint and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		local pos
		if input.UserInputType == Enum.UserInputType.Touch then
			local inset = GuiService:GetGuiInset()
			pos = Vector2.new(input.Position.X + inset.X, input.Position.Y + inset.Y)
		else
			pos = UserInputService:GetMouseLocation()
		end
		if not overOwnUI(pos) then
			S.settingPoint = false
			S.point = pos
			paintMode()
		end
		return
	end

	if gameProcessed then return end
	if input.KeyCode == S.key then
		S.toggle()
	end
end)

-- Init
paintMouse()
paintMode()
refreshStatus()

print("[leon4951hub] AutoClicker loaded - UI Compact 45x180")