local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
if not player then
	player = Players.PlayerAdded:Wait()
end
local playerGui = player:WaitForChild("PlayerGui", 15)
if not playerGui then
	warn("[Source Hub Finder] PlayerGui not found - aborting")
	return
end

print("[Source Hub Finder] Loading...")

local API_URL = "https://privatedontleakorelsejejjkeo3333.lovable.app/api/getPets"
local REFRESH_INTERVAL = 1
local MAX_ITEMS = 300
local DEFAULT_RARITY = "Secret"
local FORCE_INTERVAL = 3
local TITLE = "Source Hub Finder"
local AUTHOR = "Sources Hub Team"
local DISCORD_LINK = "https://discord.gg/REbuVnr4qt"

local POST_URL = "https://privatedontleakorelsejejjkeo3333.lovable.app/api/addPet"
local AUTO_POST = true
local POST_MIN_VALUE = 50000000
local POST_SCAN_INTERVAL = 8
local POST_COOLDOWN = 300

-- Blacklist (persisted)
local blacklist = {} -- [petName] = true
local blacklistFile = "SourcesHub_Blacklist.json"
local blacklistMode = false
local showingBlacklistPanel = false

local function loadBlacklist()
	if isfile and readfile and isfile(blacklistFile) then
		local ok, data = pcall(function()
			return HttpService:JSONDecode(readfile(blacklistFile))
		end)
		if ok and type(data) == "table" then
			for _, name in ipairs(data) do
				if type(name) == "string" and name ~= "" then
					blacklist[name] = true
				end
			end
		end
	end
end

local function saveBlacklist()
	if not writefile then
		return
	end
	local arr = {}
	for name in pairs(blacklist) do
		arr[#arr + 1] = name
	end
	table.sort(arr)
	pcall(function()
		writefile(blacklistFile, HttpService:JSONEncode(arr))
	end)
end

local function isBlacklisted(e)
	return e and e.name and blacklist[e.name] == true
end

loadBlacklist()

local rarityByName, colorByName = {}, {}
local displayByName, iconByName = {}, {}

local function findIcon(e)
	for _, k in ipairs({ "Icon", "IconId", "Image", "ImageId", "Thumbnail" }) do
		local v = e[k]
		if v ~= nil then
			local id = tostring(v):match("(%d%d%d%d%d+)")
			if id then
				return id
			end
		end
	end
	return nil
end

do
	local ok, err = pcall(function()
		local dataFolder = ReplicatedStorage:WaitForChild("Data", 5)
		if not dataFolder then
			error("Data folder missing")
		end
		local assetsModule = dataFolder:WaitForChild("Assets", 5)
		if not assetsModule then
			error("Assets module missing")
		end
		local Assets = require(assetsModule)
		if type(Assets) ~= "table" or type(Assets.Directory) ~= "table" then
			error("Assets.Directory missing")
		end
		for id, e in pairs(Assets.Directory) do
			if type(e) == "table" and type(e.Rarity) == "table" then
				local r = e.Rarity.DisplayName or e.Rarity._id
				local icon = findIcon(e)
				rarityByName[id] = r
				colorByName[id] = e.Rarity.Color
				displayByName[id] = e.DisplayName or tostring(id)
				iconByName[id] = icon
				if e.DisplayName then
					rarityByName[e.DisplayName] = r
					colorByName[e.DisplayName] = e.Rarity.Color
					displayByName[e.DisplayName] = e.DisplayName
					iconByName[e.DisplayName] = icon
				end
			end
		end
	end)
	if not ok then
		warn("[Source Hub Finder] Gagal load Assets (rarity pakai fallback API/default):", err)
	end
end

local function getRarity(petName)
	return rarityByName[petName]
end

local function getRarityColor(petName)
	local c = colorByName[petName]
	if typeof(c) == "Color3" then
		return c
	end
	return nil
end

local WHITE = Color3.fromRGB(255, 255, 255)
local ACCENT_HI = Color3.fromRGB(255, 70, 80)
local ACCENT = Color3.fromRGB(235, 35, 50)
local ACCENT_DARK = Color3.fromRGB(120, 10, 22)
local ACCENT_DEEP = Color3.fromRGB(60, 6, 12)
local SUB_TEXT = Color3.fromRGB(175, 150, 152)
local MUTED = Color3.fromRGB(130, 95, 98)

local FONT_BOLD = Enum.Font.GothamBold
local FONT_MED = Enum.Font.GothamMedium

local function new(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do
		inst[k] = v
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function corner(parent, radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function stroke(parent, color, thickness, transparency)
	return new("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

local function gradient(parent, c0, c1, rotation)
	return new("UIGradient", {
		Color = ColorSequence.new(c0, c1),
		Rotation = rotation or 0,
	}, parent)
end

local function accentStroke(parent, thickness, transparency)
	local s = stroke(parent, WHITE, thickness, transparency)
	gradient(s, ACCENT_HI, ACCENT_DARK, 90)
	return s
end

local function label(parent, text, size, font, color, pos, sz, alignX)
	return new("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		TextSize = size,
		Font = font,
		TextColor3 = color,
		Position = pos,
		Size = sz,
		TextXAlignment = alignX or Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, parent)
end

local function button(parent, o)
	local bg = new("Frame", {
		AnchorPoint = o.anchor or Vector2.new(0, 0),
		Position = o.pos,
		Size = o.size,
		BackgroundColor3 = WHITE,
		BackgroundTransparency = o.bgTransparency or 0,
		BorderSizePixel = 0,
	}, parent)
	corner(bg, o.radius or 8)
	gradient(bg, o.c0, o.c1, o.rotation or 90)
	if o.strokeColor then
		stroke(bg, o.strokeColor, o.strokeThickness or 1.2, o.strokeTransparency or 0)
	end
	local btn = new("TextButton", {
		AutoButtonColor = false,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = o.text,
		TextSize = o.textSize or 12,
		Font = FONT_BOLD,
		TextColor3 = o.textColor or WHITE,
		BorderSizePixel = 0,
	}, bg)
	return btn, bg
end

local function formatValue(v)
	local units = { { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }
	for _, u in ipairs(units) do
		if v >= u[1] then
			return ("$%.1f%s/s"):format(v / u[1], u[2])
		end
	end
	return ("$%d/s"):format(math.floor(v))
end

local function formatAge(tsMs)
	local s = math.max(0, math.floor(os.time() - tsMs / 1000))
	return ("%d:%02d"):format(math.floor(s / 60), s % 60)
end

local function richColor(c)
	return ("rgb(%d,%d,%d)"):format(
		math.floor(c.R * 255 + 0.5),
		math.floor(c.G * 255 + 0.5),
		math.floor(c.B * 255 + 0.5))
end

local function escapeRich(s)
	return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function httpGet(url)
	local okR, res = pcall(function()
		local fn = (syn and syn.request) or http_request or request
		if fn then
			return fn({ Url = url, Method = "GET" })
		end
		return nil
	end)
	if okR and res and res.Body then
		return res.Body
	end
	local ok, body = pcall(function()
		return game:HttpGet(url)
	end)
	if ok and body then
		return body
	end
	local ok2, body2 = pcall(function()
		return HttpService:GetAsync(url)
	end)
	if ok2 then
		return body2
	end
	return nil
end

local gui = new("ScreenGui", {
	Name = "SourceHubFinder",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = true,
}, playerGui)

local main = new("Frame", {
	Name = "Main",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(800, 502),
	BackgroundColor3 = WHITE,
	BackgroundTransparency = 0.06,
	BorderSizePixel = 0,
	ClipsDescendants = true,
}, gui)
corner(main, 14)
accentStroke(main, 1.6, 0)
new("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(52, 8, 16)),
		ColorSequenceKeypoint.new(0.45, Color3.fromRGB(14, 8, 10)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(4, 4, 5)),
	}),
	Rotation = 35,
}, main)
local uiScale = new("UIScale", { Scale = 1 }, main)

do
	local dragging, dragStart, startPos
	main.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

local sidebar = new("Frame", {
	Name = "Sidebar",
	Size = UDim2.new(0, 160, 1, 0),
	BackgroundColor3 = WHITE,
	BackgroundTransparency = 0.15,
	BorderSizePixel = 0,
}, main)
gradient(sidebar, Color3.fromRGB(8, 6, 7), Color3.fromRGB(58, 8, 17), 90)

local divider = new("Frame", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, 0),
	Size = UDim2.new(0, 1, 1, 0),
	BackgroundColor3 = WHITE,
	BorderSizePixel = 0,
}, sidebar)
gradient(divider, ACCENT_HI, ACCENT_DARK, 90)

local titleLabel = label(sidebar, TITLE, 13, FONT_BOLD, WHITE,
	UDim2.fromOffset(12, 20), UDim2.fromOffset(146, 20))
gradient(titleLabel, WHITE, ACCENT_HI, 0)

new("Frame", {
	Position = UDim2.fromOffset(16, 56),
	Size = UDim2.fromOffset(6, 6),
	BackgroundColor3 = ACCENT_HI,
	BorderSizePixel = 0,
}, sidebar)
local statusLabel = label(sidebar, "Connecting...", 9, FONT_MED, SUB_TEXT,
	UDim2.fromOffset(28, 51), UDim2.fromOffset(110, 16))

local blModeBtn = button(sidebar, {
	text = "Blacklist",
	textSize = 11,
	pos = UDim2.fromOffset(8, 70),
	size = UDim2.fromOffset(70, 32),
	c0 = ACCENT,
	c1 = ACCENT_DARK,
	rotation = 0,
	strokeColor = ACCENT_HI,
	strokeTransparency = 0.1,
	radius = 8,
})

local unblBtn = button(sidebar, {
	text = "Unblacklist",
	textSize = 10,
	pos = UDim2.fromOffset(84, 70),
	size = UDim2.fromOffset(70, 32),
	c0 = Color3.fromRGB(44, 10, 15),
	c1 = Color3.fromRGB(14, 8, 9),
	strokeColor = ACCENT,
	strokeTransparency = 0.25,
	radius = 8,
})

-- Blacklist panel (overlay on content)
local blPanel = new("Frame", {
	Name = "BlacklistPanel",
	Position = UDim2.fromOffset(0, 0),
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(10, 8, 9),
	BackgroundTransparency = 0.05,
	Visible = false,
	ZIndex = 20,
}, main)
blPanel.Position = UDim2.fromOffset(182, 0)
blPanel.Size = UDim2.new(1, -182, 1, 0)
corner(blPanel, 8)
local blPanelTitle = label(blPanel, "BLACKLISTED PETS", 12, FONT_BOLD, ACCENT_HI,
	UDim2.fromOffset(12, 8), UDim2.new(1, -80, 0, 24))
local blClose = button(blPanel, {
	text = "Close",
	textSize = 10,
	anchor = Vector2.new(1, 0),
	pos = UDim2.new(1, -10, 0, 6),
	size = UDim2.fromOffset(60, 26),
	c0 = ACCENT_DARK,
	c1 = ACCENT_DEEP,
	strokeColor = ACCENT,
	radius = 6,
})
local blScroll = new("ScrollingFrame", {
	Position = UDim2.fromOffset(10, 40),
	Size = UDim2.new(1, -20, 1, -50),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = ACCENT,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ZIndex = 21,
}, blPanel)
new("UIListLayout", {
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.Name,
}, blScroll)

local function refreshBlacklistPanel()
	for _, c in ipairs(blScroll:GetChildren()) do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	local names = {}
	for name in pairs(blacklist) do
		names[#names + 1] = name
	end
	table.sort(names)
	if #names == 0 then
		label(blScroll, "No blacklisted pets", 12, FONT_MED, MUTED,
			UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 30))
		return
	end
	for _, name in ipairs(names) do
		local row = new("Frame", {
			Size = UDim2.new(1, -4, 0, 40),
			BackgroundColor3 = WHITE,
			BackgroundTransparency = 0.08,
			BorderSizePixel = 0,
			ZIndex = 22,
		}, blScroll)
		corner(row, 8)
		gradient(row, Color3.fromRGB(50, 12, 16), Color3.fromRGB(18, 10, 12), 0)
		label(row, name, 13, FONT_BOLD, WHITE,
			UDim2.fromOffset(12, 0), UDim2.new(1, -100, 1, 0))
		local ub = button(row, {
			text = "Unblacklist",
			textSize = 10,
			anchor = Vector2.new(1, 0.5),
			pos = UDim2.new(1, -8, 0.5, 0),
			size = UDim2.fromOffset(88, 28),
			c0 = ACCENT,
			c1 = ACCENT_DARK,
			strokeColor = ACCENT_HI,
			radius = 6,
		})
		ub.ZIndex = 23
		ub.MouseButton1Click:Connect(function()
			blacklist[name] = nil
			saveBlacklist()
			statusLabel.Text = "Unblacklisted: " .. tostring(name):sub(1, 16)
			refreshBlacklistPanel()
			render()
		end)
	end
end

-- blacklist button handlers connected after render is defined


local authorLabel = label(sidebar, "Author: " .. AUTHOR, 10, FONT_BOLD, SUB_TEXT,
	UDim2.fromOffset(12, 118), UDim2.fromOffset(142, 18))
gradient(authorLabel, WHITE, ACCENT_HI, 0)

local COPY_TEXT = "Copy Discord Link"
local copyBtn = button(sidebar, {
	text = COPY_TEXT,
	textSize = 10,
	pos = UDim2.fromOffset(8, 142),
	size = UDim2.fromOffset(146, 30),
	c0 = Color3.fromRGB(44, 10, 15),
	c1 = Color3.fromRGB(14, 8, 9),
	strokeColor = ACCENT,
	strokeTransparency = 0.25,
	radius = 10,
})

local copyToken = 0
copyBtn.MouseButton1Click:Connect(function()
	local fn = setclipboard or toclipboard
	local ok = fn and pcall(fn, DISCORD_LINK)
	copyToken += 1
	local myToken = copyToken
	copyBtn.Text = ok and "Copied!" or "Copy failed"
	if not ok then
		warn("[" .. TITLE .. "] Clipboard tidak didukung executor. Link: " .. DISCORD_LINK)
	end
	task.delay(1.5, function()
		if copyToken == myToken and copyBtn.Parent then
			copyBtn.Text = COPY_TEXT
		end
	end)
end)

local postLabel = label(sidebar, "Scan:0 Post:0", 9, FONT_MED, MUTED,
	UDim2.fromOffset(12, 178), UDim2.fromOffset(142, 14))
postLabel.TextTruncate = Enum.TextTruncate.AtEnd

local W_MIN, W_MAX, H_MIN, H_MAX, MARGIN = 640, 800, 300, 502, 8
local userScale = 1

local zoomOut = button(sidebar, {
	text = "-",
	textSize = 16,
	anchor = Vector2.new(0, 1),
	pos = UDim2.new(0, 8, 1, -67),
	size = UDim2.fromOffset(40, 28),
	c0 = Color3.fromRGB(44, 10, 15),
	c1 = Color3.fromRGB(14, 8, 9),
	strokeColor = ACCENT,
	strokeTransparency = 0.25,
	radius = 8,
})
local zoomLabel = label(sidebar, "100%", 10, FONT_BOLD, WHITE,
	UDim2.new(0, 52, 1, -95), UDim2.fromOffset(58, 28), Enum.TextXAlignment.Center)
local zoomIn = button(sidebar, {
	text = "+",
	textSize = 16,
	anchor = Vector2.new(0, 1),
	pos = UDim2.new(0, 114, 1, -67),
	size = UDim2.fromOffset(40, 28),
	c0 = Color3.fromRGB(44, 10, 15),
	c1 = Color3.fromRGB(14, 8, 9),
	strokeColor = ACCENT,
	strokeTransparency = 0.25,
	radius = 8,
})

local function applyLayout()
	local vp = gui.AbsoluteSize
	if vp.X <= 0 or vp.Y <= 0 then
		return
	end
	local cap = math.min((vp.X - MARGIN * 2) / W_MIN, (vp.Y - MARGIN * 2) / H_MIN)
	local s = math.max(0.3, math.min(userScale, cap))
	uiScale.Scale = s
	main.Size = UDim2.fromOffset(
		math.clamp((vp.X - MARGIN * 2) / s, W_MIN, W_MAX),
		math.clamp((vp.Y - MARGIN * 2) / s, H_MIN, H_MAX))
	zoomLabel.Text = math.floor(s * 100 + 0.5) .. "%"
end

local function stepZoom(d)
	userScale = math.clamp(math.floor((uiScale.Scale + d) * 10 + 0.5) / 10, 0.4, 1.6)
	applyLayout()
end

zoomOut.MouseButton1Click:Connect(function()
	stepZoom(-0.1)
end)
zoomIn.MouseButton1Click:Connect(function()
	stepZoom(0.1)
end)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyLayout)
applyLayout()

local hideBtn = button(sidebar, {
	text = "Hide",
	textSize = 12,
	anchor = Vector2.new(0, 1),
	pos = UDim2.new(0, 11, 1, -23),
	size = UDim2.fromOffset(138, 36),
	c0 = Color3.fromRGB(44, 10, 15),
	c1 = Color3.fromRGB(14, 8, 9),
	strokeColor = ACCENT,
	strokeTransparency = 0.25,
	radius = 10,
})

local showBtn, showBg = button(gui, {
	text = TITLE,
	textSize = 12,
	anchor = Vector2.new(0.5, 0),
	pos = UDim2.new(0.5, 0, 0, 12),
	size = UDim2.fromOffset(150, 30),
	c0 = Color3.fromRGB(60, 10, 17),
	c1 = Color3.fromRGB(12, 8, 9),
	strokeColor = ACCENT,
	strokeTransparency = 0.15,
	radius = 10,
})
showBg.Visible = false

hideBtn.MouseButton1Click:Connect(function()
	main.Visible = false
	showBg.Visible = true
end)
showBtn.MouseButton1Click:Connect(function()
	main.Visible = true
	showBg.Visible = false
end)

local content = new("Frame", {
	Name = "Content",
	Position = UDim2.fromOffset(182, 0),
	Size = UDim2.new(1, -182, 1, 0),
	BackgroundTransparency = 1,
}, main)

local TRACK_OFF = Color3.fromRGB(38, 24, 26)
local function toggleCard(text, x, onChanged)
	local card = new("Frame", {
		Position = x == 0 and UDim2.new(0, 0, 0, 20) or UDim2.new(0.5, 6, 0, 20),
		Size = x == 0 and UDim2.new(0.5, -6, 0, 46) or UDim2.new(0.5, -24, 0, 46),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
	}, content)
	corner(card, 10)
	gradient(card, Color3.fromRGB(46, 9, 15), Color3.fromRGB(12, 9, 10), 0)
	accentStroke(card, 1.2, 0.2)

	label(card, text, 12, FONT_BOLD, WHITE,
		UDim2.fromOffset(14, 0), UDim2.new(1, -90, 1, 0))

	local track = new("TextButton", {
		AutoButtonColor = false,
		Text = "",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(48, 26),
		BackgroundColor3 = TRACK_OFF,
		BorderSizePixel = 0,
	}, card)
	corner(track, 13)
	stroke(track, ACCENT_DARK, 1, 0.2)
	gradient(track, WHITE, Color3.fromRGB(165, 165, 165), 90)

	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 4, 0.5, 0),
		Size = UDim2.fromOffset(20, 20),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
	}, track)
	corner(knob, 10)

	local state = false
	local info = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	track.MouseButton1Click:Connect(function()
		state = not state
		TweenService:Create(knob, info, {
			Position = state and UDim2.new(1, -24, 0.5, 0) or UDim2.new(0, 4, 0.5, 0),
		}):Play()
		TweenService:Create(track, info, {
			BackgroundColor3 = state and ACCENT or TRACK_OFF,
		}):Play()
		if onChanged then
			onChanged(state)
		end
	end)
	return card
end

local autoJoinState, autoForceState = false, false
local lastAutoJoinJob = nil
local forceKey, forceJobId, forceRun = nil, nil, 0
local render, startForce, stopForce

toggleCard("Auto-Join", 0, function(v)
	autoJoinState = v
	render()
end)
toggleCard("Auto-Force", 311, function(v)
	autoForceState = v
	if not v then
		stopForce()
	end
	render()
end)

label(content, "LIVE FEED", 9, FONT_BOLD, ACCENT_HI,
	UDim2.fromOffset(2, 74), UDim2.fromOffset(100, 16))

local detectedLabel = label(content, "0 detected", 8, FONT_MED, MUTED,
	UDim2.new(1, -98, 0, 74), UDim2.fromOffset(80, 16), Enum.TextXAlignment.Right)
detectedLabel.AnchorPoint = Vector2.new(1, 0)

local clearBtn = button(content, {
	text = "Clear",
	textSize = 9,
	anchor = Vector2.new(1, 0),
	pos = UDim2.new(1, -18, 0, 70),
	size = UDim2.fromOffset(49, 22),
	c0 = ACCENT_DARK,
	c1 = ACCENT_DEEP,
	strokeColor = ACCENT,
	strokeThickness = 1,
	strokeTransparency = 0.4,
})

local feedBox = new("Frame", {
	Position = UDim2.fromOffset(0, 96),
	Size = UDim2.new(1, -2, 1, -112),
	BackgroundColor3 = WHITE,
	BackgroundTransparency = 0.2,
	BorderSizePixel = 0,
}, content)
corner(feedBox, 12)
gradient(feedBox, Color3.fromRGB(16, 6, 8), Color3.fromRGB(5, 5, 6), 90)
stroke(feedBox, ACCENT, 1, 0.6)

local feed = new("ScrollingFrame", {
	Position = UDim2.fromOffset(7, 7),
	Size = UDim2.new(1, -14, 1, -14),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = ACCENT,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, feedBox)
new("UIListLayout", {
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, feed)
new("UIPadding", { PaddingRight = UDim.new(0, 8) }, feed)

TeleportService.TeleportInitFailed:Connect(function(_, result, errorMessage)
	warn("[" .. TITLE .. "] TeleportInitFailed:", tostring(result), tostring(errorMessage))
	if statusLabel and statusLabel.Parent then
		statusLabel.Text = "Join failed"
	end
end)

local function joinServer(jobId)
	jobId = tostring(jobId or "")
	if jobId == "" or jobId == "nil" then
		warn("[" .. TITLE .. "] Join failed: empty jobId")
		return
	end
	if jobId == tostring(game.JobId) then
		warn("[" .. TITLE .. "] Already in this server")
		return
	end

	local placeId = game.PlaceId
	statusLabel.Text = "Joining..."

	-- Method 1: TeleportToPlaceInstance (player arg)
	local ok, err = pcall(function()
		TeleportService:TeleportToPlaceInstance(placeId, jobId, player)
	end)
	if ok then
		return
	end
	warn("[" .. TITLE .. "] Join method 1 failed:", err)

	-- Method 2: TeleportToPlaceInstance (no player arg)
	ok, err = pcall(function()
		TeleportService:TeleportToPlaceInstance(placeId, jobId)
	end)
	if ok then
		return
	end
	warn("[" .. TITLE .. "] Join method 2 failed:", err)

	-- Method 3: request-based (some executors)
	local fn = (syn and syn.request) or http_request or request
	if fn then
		ok, err = pcall(function()
			fn({
				Url = "https://gamejoin.roblox.com/v1/join-game-instance",
				Method = "POST",
				Headers = {
					["Content-Type"] = "application/json",
					["User-Agent"] = "Roblox/WinInet",
				},
				Body = HttpService:JSONEncode({
					placeId = placeId,
					gameId = jobId,
				}),
			})
		end)
		if ok then
			-- Still need TeleportService after ticket in most cases; try again
			pcall(function()
				TeleportService:TeleportToPlaceInstance(placeId, jobId, player)
			end)
			return
		end
		warn("[" .. TITLE .. "] Join method 3 failed:", err)
	end

	statusLabel.Text = "Join failed"
	warn("[" .. TITLE .. "] All join methods failed for jobId:", jobId)
end

stopForce = function()
	forceRun += 1
	forceKey, forceJobId = nil, nil
end

startForce = function(key, jobId)
	forceRun += 1
	local myRun = forceRun
	forceKey, forceJobId = key, jobId
	task.spawn(function()
		while forceRun == myRun and autoForceState and gui.Parent do
			if jobId == game.JobId then
				stopForce()
				render()
				break
			end
			joinServer(jobId)
			task.wait(FORCE_INTERVAL)
		end
	end)
end

local ageLabels = {}

local function clearRows()
	for _, c in ipairs(feed:GetChildren()) do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	table.clear(ageLabels)
end

local function subText(entry)
	local parts = {}
	table.insert(parts, formatAge(entry.ts))

	local rarityText = escapeRich(entry.rarity)
	if entry.rarityColor then
		rarityText = ("<font color=\"%s\">%s</font>"):format(richColor(entry.rarityColor), rarityText)
	end
	table.insert(parts, rarityText)
	return table.concat(parts, " • ")
end

local function addRow(data, order)
	local row = new("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
	}, feed)
	corner(row, 10)
	gradient(row, Color3.fromRGB(58, 10, 17), Color3.fromRGB(15, 11, 12), 0)
	accentStroke(row, 1, 0.5)

	local bar = new("Frame", {
		Position = UDim2.fromOffset(6, 6),
		Size = UDim2.fromOffset(6, 48),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
	}, row)
	corner(bar, 3)
	gradient(bar, ACCENT_HI, ACCENT_DARK, 90)

	new("ImageLabel", {
		Position = UDim2.fromOffset(20, 8),
		Size = UDim2.fromOffset(44, 44),
		BackgroundTransparency = 1,
		Image = data.iconId and ("rbxassetid://" .. tostring(data.iconId)) or "",
		ScaleType = Enum.ScaleType.Fit,
	}, row)

	local title = label(row, "", 18, FONT_BOLD, WHITE,
		UDim2.fromOffset(71, 7), UDim2.new(1, -220, 0, 26))
	title.RichText = true
	title.TextScaled = true
	new("UITextSizeConstraint", { MaxTextSize = 18, MinTextSize = 9 }, title)
	title.Text = ("%s  <font color=\"rgb(255,70,80)\">[ %s ]</font>"):format(
		escapeRich(data.name), formatValue(data.value))

	local sub = label(row, "", 11, FONT_BOLD, SUB_TEXT,
		UDim2.fromOffset(71, 33), UDim2.new(1, -220, 0, 16))
	sub.RichText = true
	sub.TextTruncate = Enum.TextTruncate.AtEnd
	sub.Text = subText(data)
	table.insert(ageLabels, { label = sub, entry = data })

	local join = button(row, {
		text = "JOIN",
		textSize = 8,
		anchor = Vector2.new(1, 0.5),
		pos = UDim2.new(1, -78, 0.5, 0),
		size = UDim2.fromOffset(48, 26),
		c0 = ACCENT,
		c1 = ACCENT_DARK,
		strokeColor = ACCENT_HI,
		strokeTransparency = 0.2,
	})

	local canForce = autoForceState
	local selected = canForce and forceKey == data.key
	local fc0, fc1, ftext, fstroke, fstrokeT
	if selected then
		fc0, fc1, ftext = ACCENT_HI, ACCENT, WHITE
		fstroke, fstrokeT = WHITE, 0.3
	elseif canForce then
		fc0, fc1, ftext = Color3.fromRGB(44, 11, 16), Color3.fromRGB(16, 9, 10), WHITE
		fstroke, fstrokeT = ACCENT, 0.15
	else
		fc0, fc1, ftext = Color3.fromRGB(34, 26, 27), Color3.fromRGB(24, 19, 20), Color3.fromRGB(95, 75, 76)
		fstroke, fstrokeT = nil, nil
	end
	local force = button(row, {
		text = "FORCE",
		textSize = 8,
		textColor = ftext,
		anchor = Vector2.new(1, 0.5),
		pos = UDim2.new(1, -12, 0.5, 0),
		size = UDim2.fromOffset(44, 26),
		c0 = fc0,
		c1 = fc1,
		strokeColor = fstroke,
		strokeTransparency = fstrokeT,
	})

	join.MouseButton1Click:Connect(function()
		joinServer(data.jobId)
	end)

	force.MouseButton1Click:Connect(function()
		if not autoForceState then
			return
		end
		if forceKey == data.key then
			stopForce()
		else
			startForce(data.key, data.jobId)
		end
		render()
	end)

	-- Blacklist mode: click row (or BL button) to blacklist this pet name
	local blBtn = button(row, {
		text = "BL",
		textSize = 8,
		anchor = Vector2.new(1, 0.5),
		pos = UDim2.new(1, -130, 0.5, 0),
		size = UDim2.fromOffset(28, 26),
		c0 = Color3.fromRGB(80, 20, 20),
		c1 = Color3.fromRGB(40, 10, 10),
		strokeColor = ACCENT,
		strokeTransparency = 0.3,
	})
	blBtn.MouseButton1Click:Connect(function()
		if data.name and data.name ~= "" then
			blacklist[data.name] = true
			saveBlacklist()
			statusLabel.Text = "Blacklisted: " .. tostring(data.name):sub(1, 18)
			render()
		end
	end)

	if blacklistMode then
		row.BackgroundTransparency = 0
		local pick = new("TextButton", {
			AutoButtonColor = false,
			Text = "TAP TO BLACKLIST",
			TextSize = 11,
			Font = FONT_BOLD,
			TextColor3 = WHITE,
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(180, 30, 40),
			BackgroundTransparency = 0.35,
			ZIndex = 5,
			BorderSizePixel = 0,
		}, row)
		pick.MouseButton1Click:Connect(function()
			if data.name and data.name ~= "" then
				blacklist[data.name] = true
				saveBlacklist()
				blacklistMode = false
				statusLabel.Text = "Blacklisted: " .. tostring(data.name):sub(1, 18)
				render()
			end
		end)
	end
end

local hidden = {}
local latest = {}

local function keyOf(e)
	return e.jobId .. "|" .. e.name .. "|" .. tostring(e.ts)
end

function render()
	local scroll = feed.CanvasPosition
	clearRows()

	local shown = 0
	for _, e in ipairs(latest) do
		if not hidden[keyOf(e)] and not isBlacklisted(e) then
			shown += 1
			if shown <= MAX_ITEMS then
				addRow(e, shown)
			end
		end
	end
	detectedLabel.Text = shown .. " detected"
	feed.CanvasPosition = scroll

	-- Auto-Join: teleport once to top pet not in current server
	if autoJoinState and #latest > 0 then
		for _, e in ipairs(latest) do
			local jid = tostring(e.jobId)
			if not hidden[keyOf(e)] and not isBlacklisted(e) and jid ~= tostring(game.JobId) and jid ~= lastAutoJoinJob then
				lastAutoJoinJob = jid
				joinServer(jid)
				break
			end
		end
	end
end

clearBtn.MouseButton1Click:Connect(function()
	for _, e in ipairs(latest) do
		hidden[keyOf(e)] = true
	end
	render()
end)

blClose.MouseButton1Click:Connect(function()
	blPanel.Visible = false
	showingBlacklistPanel = false
end)

blModeBtn.MouseButton1Click:Connect(function()
	blacklistMode = not blacklistMode
	blPanel.Visible = false
	showingBlacklistPanel = false
	if blacklistMode then
		blModeBtn.Text = "Pick log..."
		statusLabel.Text = "Click a log to blacklist"
	else
		blModeBtn.Text = "Blacklist"
		statusLabel.Text = "Connected"
	end
	render()
end)

unblBtn.MouseButton1Click:Connect(function()
	blacklistMode = false
	blModeBtn.Text = "Blacklist"
	showingBlacklistPanel = not showingBlacklistPanel
	blPanel.Visible = showingBlacklistPanel
	if showingBlacklistPanel then
		refreshBlacklistPanel()
		statusLabel.Text = "Blacklist manager"
	else
		statusLabel.Text = "Connected"
	end
end)

local function fetchPets()
	local body = httpGet(API_URL)
	if not body then
		return false
	end
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(body)
	end)
	if not ok or type(decoded) ~= "table" then
		return false
	end

	local list = {}
	for _, p in ipairs(decoded) do
		if p.petName and p.jobId and tonumber(p.value) then
			local name = tostring(p.petName)
			local rarity = getRarity(name)
				or (p.rarity and tostring(p.rarity))
				or DEFAULT_RARITY
			table.insert(list, {
				name = name,
				value = tonumber(p.value),
				jobId = tostring(p.jobId),
				iconId = p.iconId,
				key = tostring(p.jobId) .. "|" .. name .. "|" .. tostring(p.timestamp),
				ts = tonumber(p.timestamp) or (os.time() * 1000),
				rarity = rarity,
				rarityColor = getRarityColor(name),
			})
		end
	end
	table.sort(list, function(a, b)
		return (a.ts or 0) > (b.ts or 0)
	end)
	latest = list
	return true
end

local postedAt = {}
local postOk, postFail, scanCount, lastPostStatus = 0, 0, 0, "-"
local postPauseUntil = 0

local VALUE_PATTERN = "^%s*%$?%s*([%d%.,]+)%s*([KkMmBbTt]?)%s*/%s*[sS]%s*$"
local UNIT_MUL = { K = 1e3, M = 1e6, B = 1e9, T = 1e12 }

local function parseValue(text)
	local clean = tostring(text):gsub("<[^>]+>", "")
	local num, unit = clean:match(VALUE_PATTERN)
	if not num then
		return nil
	end
	local n = tonumber((num:gsub(",", "")))
	if not n then
		return nil
	end
	return n * (UNIT_MUL[unit:upper()] or 1)
end

local function resolveName(inst)
	local cur = inst.Parent
	for _ = 1, 8 do
		if not cur or cur == workspace then
			return nil
		end
		local key = displayByName[cur.Name] and cur.Name or nil
		if not key then
			for _, ch in ipairs(cur:GetChildren()) do
				if ch:IsA("TextLabel") then
					local t = tostring(ch.Text):gsub("<[^>]+>", "")
					t = t:match("^%s*(.-)%s*$")
					if displayByName[t] then
						key = t
						break
					end
				end
			end
		end
		if key then
			return displayByName[key], iconByName[key]
		end
		cur = cur.Parent
	end
	return nil
end

local function scanPets()
	local found, seen, n = {}, {}, 0
	for _, d in ipairs(workspace:GetDescendants()) do
		n += 1
		if n % 3000 == 0 then
			task.wait()
		end
		if d:IsA("TextLabel") then
			local value = parseValue(d.Text)
			if value and value >= POST_MIN_VALUE then
				local name, icon = resolveName(d)
				if name then
					local k = name .. "|" .. math.floor(value)
					if not seen[k] then
						seen[k] = true
						table.insert(found, { name = name, value = value, icon = icon })
					end
				end
			end
		end
	end
	return found
end

local function alreadyListed(name, value)
	for _, e in ipairs(latest) do
		if e.jobId == game.JobId and e.name == name and math.abs(e.value - value) <= value * 0.05 then
			return true
		end
	end
	return false
end

local function httpPost(url, body)
	local fn = (syn and syn.request) or http_request or request
	if not fn then
		return nil, "no request fn"
	end
	local ok, res = pcall(fn, {
		Url = url,
		Method = "POST",
		Headers = { ["Content-Type"] = "application/json" },
		Body = body,
	})
	if ok and type(res) == "table" then
		return tonumber(res.StatusCode), res.Body
	end
	return nil, tostring(res)
end

task.spawn(function()
	while gui.Parent do
		if not AUTO_POST or game.JobId == "" then
			postLabel.Text = "Post: off"
		elseif os.clock() >= postPauseUntil then
			local ok, found = pcall(scanPets)
			if ok then
				scanCount = #found
				for _, pet in ipairs(found) do
					local key = game.JobId .. "|" .. pet.name .. "|" .. math.floor(pet.value)
					local last = postedAt[key]
					if (not last or os.clock() - last > POST_COOLDOWN) and not alreadyListed(pet.name, pet.value) then
						postedAt[key] = os.clock()
						local body = HttpService:JSONEncode({
							petName = pet.name,
							value = pet.value,
							jobId = game.JobId,
							iconId = pet.icon and tostring(pet.icon) or "",
							timestamp = os.time() * 1000,
						})
						local status, resp = httpPost(POST_URL, body)
						if status and status >= 200 and status < 300 then
							postOk += 1
						else
							postFail += 1
							postedAt[key] = os.clock() - POST_COOLDOWN + 60
							if status == 429 then
								postPauseUntil = os.clock() + 30
							end
						end
						lastPostStatus = status and tostring(status) or tostring(resp):sub(1, 14)
						if status == 429 then
							break
						end
						task.wait(0.5)
					end
				end
			else
				warn("[" .. TITLE .. "] Scan gagal:", found)
			end
			postLabel.Text = ("Scan:%d Post:%d/%d (%s)"):format(scanCount, postOk, postOk + postFail, lastPostStatus)
		end
		task.wait(POST_SCAN_INTERVAL)
	end
end)

task.spawn(function()
	while gui.Parent do
		for _, item in ipairs(ageLabels) do
			if item.label.Parent then
				item.label.Text = subText(item.entry)
			end
		end
		task.wait(1)
	end
end)

task.spawn(function()
	while gui.Parent do
		local ok = fetchPets()
		statusLabel.Text = ok and "Connected" or "Disconnected"
		if ok then
			render()
		end
		task.wait(REFRESH_INTERVAL)
	end
end)