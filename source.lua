--[[
  Leon4951 — Private Server Hop
  Quiet-server finder (1P preferred, then 2P). Bottom-to-mid scan + blacklist.
  Load: UI first, network in background.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
if not player then
	player = Players.PlayerAdded:Wait()
end

local playerGui = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 2)
if not playerGui then
	warn("[Leon4951] PlayerGui not found - aborting")
	return
end

print("[Leon4951] Loading...")

local PlaceId = game.PlaceId
local TITLE = "Leon4951"
local AUTHOR = "Leon4951"
local DISCORD_LINK = "https://discord.gg/REbuVnr4qt"
local MAX_SCAN_PAGES = 10

if not _G.LeonBlacklist then
	_G.LeonBlacklist = {}
end
_G.LeonBlacklist[tostring(game.JobId)] = true

local WHITE = Color3.fromRGB(255, 255, 255)
local ACCENT_HI = Color3.fromRGB(70, 140, 255)
local ACCENT = Color3.fromRGB(35, 100, 235)
local ACCENT_DARK = Color3.fromRGB(10, 40, 120)
local ACCENT_DEEP = Color3.fromRGB(6, 20, 60)
local SUB_TEXT = Color3.fromRGB(150, 165, 190)
local MUTED = Color3.fromRGB(95, 110, 140)

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

local function RequestAPI(options)
	local req = (syn and syn.request) or http_request or request or (http and http.request)
	if not req then
		return nil
	end
	local ok, res = pcall(req, options)
	if ok then
		return res
	end
	return nil
end

--------------------------------------------------------------------------------
-- HOP LOGIC (your bottom-to-mid 1P then 2P)
--------------------------------------------------------------------------------
local IsSearching = false
local hopAttempt = 0
local maxPlayersPrefer = 2

local function FindLowestTailServer()
	local cursor = ""
	local servers1P = {}
	local servers2P = {}

	for _ = 1, MAX_SCAN_PAGES do
		local url = string.format(
			"https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100",
			PlaceId
		)
		if cursor ~= "" then
			url = url .. "&cursor=" .. cursor
		end

		local res = RequestAPI({ Url = url, Method = "GET" })
		if not (res and res.Body) then
			break
		end

		local ok, decoded = pcall(function()
			return HttpService:JSONDecode(res.Body)
		end)
		if not ok or type(decoded) ~= "table" or type(decoded.data) ~= "table" then
			break
		end

		for _, server in ipairs(decoded.data) do
			local playing = tonumber(server.playing) or 0
			local maxP = tonumber(server.maxPlayers) or 0
			local id = server.id and tostring(server.id) or nil
			if id and not _G.LeonBlacklist[id] and (maxP - playing) >= 1 then
				if playing == 1 then
					servers1P[#servers1P + 1] = server
				elseif playing == 2 and maxPlayersPrefer >= 2 then
					servers2P[#servers2P + 1] = server
				end
			end
		end

		cursor = decoded.nextPageCursor or ""
		if cursor == "" then
			break
		end
	end

	local function pickFromTail(list)
		if #list == 0 then
			return nil, nil
		end
		local startIndex = #list - 6
		if startIndex < 1 then
			startIndex = #list
		end
		local minLimit = math.floor(#list * 0.5)
		if minLimit < 1 then
			minLimit = 1
		end
		for i = startIndex, minLimit, -1 do
			local s = list[i]
			if s and s.id and not _G.LeonBlacklist[tostring(s.id)] then
				return tostring(s.id), tonumber(s.playing) or 0
			end
		end
		for i = #list, 1, -1 do
			local s = list[i]
			if s and s.id and not _G.LeonBlacklist[tostring(s.id)] then
				return tostring(s.id), tonumber(s.playing) or 0
			end
		end
		return nil, nil
	end

	local id, n = pickFromTail(servers1P)
	if id then
		return id, n
	end
	if maxPlayersPrefer >= 2 then
		return pickFromTail(servers2P)
	end
	return nil, nil
end

local function joinServer(jobId)
	jobId = tostring(jobId or "")
	if jobId == "" or jobId == "nil" then
		return false
	end
	if jobId == tostring(game.JobId) then
		return false
	end
	_G.LeonBlacklist[jobId] = true
	local ok = pcall(function()
		TeleportService:TeleportToPlaceInstance(PlaceId, jobId, player)
	end)
	if ok then
		return true
	end
	ok = pcall(function()
		TeleportService:TeleportToPlaceInstance(PlaceId, jobId)
	end)
	return ok
end

--------------------------------------------------------------------------------
-- UI
--------------------------------------------------------------------------------
local gui = new("ScreenGui", {
	Name = "Leon4951Finder",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = true,
}, playerGui)

local main = new("Frame", {
	Name = "Main",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(450, 300),
	BackgroundColor3 = WHITE,
	BackgroundTransparency = 0.06,
	BorderSizePixel = 0,
	ClipsDescendants = true,
}, gui)
corner(main, 14)
accentStroke(main, 1.6, 0)
new("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(8, 20, 52)),
		ColorSequenceKeypoint.new(0.45, Color3.fromRGB(8, 12, 22)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(4, 5, 8)),
	}),
	Rotation = 35,
}, main)

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
			main.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y
			)
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
	Size = UDim2.new(0, 120, 1, 0),
	BackgroundColor3 = WHITE,
	BackgroundTransparency = 0.15,
	BorderSizePixel = 0,
}, main)
gradient(sidebar, Color3.fromRGB(6, 8, 14), Color3.fromRGB(8, 30, 70), 90)

local divider = new("Frame", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, 0),
	Size = UDim2.new(0, 1, 1, 0),
	BackgroundColor3 = WHITE,
	BorderSizePixel = 0,
}, sidebar)
gradient(divider, ACCENT_HI, ACCENT_DARK, 90)

local titleLabel = label(sidebar, TITLE, 13, FONT_BOLD, WHITE,
	UDim2.fromOffset(10, 16), UDim2.fromOffset(100, 20))
gradient(titleLabel, WHITE, ACCENT_HI, 0)

new("Frame", {
	Position = UDim2.fromOffset(12, 48),
	Size = UDim2.fromOffset(6, 6),
	BackgroundColor3 = ACCENT_HI,
	BorderSizePixel = 0,
}, sidebar)
local statusLabel = label(sidebar, "Ready", 9, FONT_MED, SUB_TEXT,
	UDim2.fromOffset(22, 44), UDim2.fromOffset(90, 16))

label(sidebar, "Author: " .. AUTHOR, 9, FONT_BOLD, SUB_TEXT,
	UDim2.fromOffset(10, 100), UDim2.fromOffset(100, 16))

local copyBtn = button(sidebar, {
	text = "Copy Discord",
	textSize = 10,
	pos = UDim2.fromOffset(6, 124),
	size = UDim2.fromOffset(108, 28),
	c0 = Color3.fromRGB(10, 30, 70),
	c1 = Color3.fromRGB(8, 14, 28),
	strokeColor = ACCENT,
	strokeTransparency = 0.25,
	radius = 8,
})
copyBtn.MouseButton1Click:Connect(function()
	local fn = setclipboard or toclipboard
	if fn and pcall(fn, DISCORD_LINK) then
		copyBtn.Text = "Copied!"
	else
		copyBtn.Text = "Failed"
	end
	task.delay(1.2, function()
		if copyBtn.Parent then
			copyBtn.Text = "Copy Discord"
		end
	end)
end)

local hideBtn = button(sidebar, {
	text = "Hide",
	textSize = 11,
	anchor = Vector2.new(0, 1),
	pos = UDim2.new(0, 6, 1, -12),
	size = UDim2.fromOffset(108, 32),
	c0 = Color3.fromRGB(10, 30, 70),
	c1 = Color3.fromRGB(8, 14, 28),
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
	c0 = Color3.fromRGB(10, 35, 80),
	c1 = Color3.fromRGB(8, 14, 28),
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
	Position = UDim2.fromOffset(128, 0),
	Size = UDim2.new(1, -128, 1, 0),
	BackgroundTransparency = 1,
}, main)

label(content, "PRIVATE SERVER HOP", 11, FONT_BOLD, ACCENT_HI,
	UDim2.fromOffset(10, 12), UDim2.fromOffset(220, 18))

local currentLbl = label(content,
	("Now: %d player(s)  ·  Job %s"):format(#Players:GetPlayers(), tostring(game.JobId):sub(1, 8)),
	10, FONT_MED, MUTED,
	UDim2.fromOffset(10, 32), UDim2.new(1, -20, 0, 16))

local maxCard = new("Frame", {
	Position = UDim2.fromOffset(10, 56),
	Size = UDim2.new(1, -20, 0, 40),
	BackgroundColor3 = WHITE,
	BackgroundTransparency = 0.08,
	BorderSizePixel = 0,
}, content)
corner(maxCard, 8)
gradient(maxCard, Color3.fromRGB(9, 28, 55), Color3.fromRGB(9, 14, 22), 0)
accentStroke(maxCard, 1, 0.35)

label(maxCard, "Max players (you included)", 10, FONT_MED, SUB_TEXT,
	UDim2.fromOffset(12, 4), UDim2.new(0.55, 0, 0, 14))

local maxValueLbl = label(maxCard, "2", 14, FONT_BOLD, WHITE,
	UDim2.fromOffset(12, 18), UDim2.fromOffset(40, 18))

local function setMax(n)
	maxPlayersPrefer = n
	maxValueLbl.Text = tostring(n)
end

local max1 = button(maxCard, {
	text = "1",
	textSize = 11,
	anchor = Vector2.new(1, 0.5),
	pos = UDim2.new(1, -56, 0.5, 0),
	size = UDim2.fromOffset(36, 26),
	c0 = ACCENT,
	c1 = ACCENT_DARK,
	strokeColor = ACCENT_HI,
	radius = 6,
})
local max2 = button(maxCard, {
	text = "2",
	textSize = 11,
	anchor = Vector2.new(1, 0.5),
	pos = UDim2.new(1, -14, 0.5, 0),
	size = UDim2.fromOffset(36, 26),
	c0 = ACCENT,
	c1 = ACCENT_DARK,
	strokeColor = ACCENT_HI,
	radius = 6,
})
max1.MouseButton1Click:Connect(function()
	setMax(1)
end)
max2.MouseButton1Click:Connect(function()
	setMax(2)
end)

local hopBtn = button(content, {
	text = "START AUTO HOP",
	textSize = 13,
	pos = UDim2.fromOffset(10, 108),
	size = UDim2.new(1, -20, 0, 44),
	c0 = ACCENT,
	c1 = ACCENT_DARK,
	strokeColor = ACCENT_HI,
	strokeTransparency = 0.15,
	radius = 10,
})

local hopDetail = label(content, "Status: Idle  ·  Target: 1P then 2P (bottom → mid)", 10, FONT_MED, MUTED,
	UDim2.fromOffset(10, 160), UDim2.new(1, -20, 0, 16))

local logBox = new("Frame", {
	Position = UDim2.fromOffset(10, 184),
	Size = UDim2.new(1, -20, 1, -196),
	BackgroundColor3 = WHITE,
	BackgroundTransparency = 0.15,
	BorderSizePixel = 0,
}, content)
corner(logBox, 10)
gradient(logBox, Color3.fromRGB(6, 12, 24), Color3.fromRGB(5, 6, 10), 90)
stroke(logBox, ACCENT, 1, 0.55)

local logScroll = new("ScrollingFrame", {
	Position = UDim2.fromOffset(6, 6),
	Size = UDim2.new(1, -12, 1, -12),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = ACCENT,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, logBox)
new("UIListLayout", {
	Padding = UDim.new(0, 4),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, logScroll)

local logOrder = 0
local function addLog(text)
	logOrder += 1
	local row = label(logScroll, text, 10, FONT_MED, SUB_TEXT,
		UDim2.fromOffset(0, 0), UDim2.new(1, -4, 0, 16))
	row.LayoutOrder = logOrder
	local kids = {}
	for _, c in ipairs(logScroll:GetChildren()) do
		if c:IsA("TextLabel") then
			kids[#kids + 1] = c
		end
	end
	if #kids > 40 then
		for i = 1, #kids - 40 do
			kids[i]:Destroy()
		end
	end
end

local function setHopUI(searching)
	if searching then
		hopBtn.Text = "STOP SEARCHING"
		hopBtn.TextColor3 = Color3.fromRGB(255, 160, 160)
		statusLabel.Text = "Hopping..."
	else
		hopBtn.Text = "START AUTO HOP"
		hopBtn.TextColor3 = WHITE
		statusLabel.Text = "Ready"
	end
end

local function StartAutoHop()
	if IsSearching then
		IsSearching = false
		setHopUI(false)
		hopDetail.Text = "Status: Stopped"
		addLog("Stopped by user")
		return
	end

	IsSearching = true
	hopAttempt = 0
	setHopUI(true)
	addLog("Scan started · max " .. tostring(maxPlayersPrefer) .. "P · bottom→mid")

	task.spawn(function()
		while IsSearching and gui.Parent do
			hopAttempt += 1
			hopDetail.Text = string.format("Scanning... (#%d)  ·  prefer ≤%dP", hopAttempt, maxPlayersPrefer)
			statusLabel.Text = "Scan #" .. hopAttempt

			local foundJobId, playerCount = FindLowestTailServer()

			if foundJobId then
				_G.LeonBlacklist[foundJobId] = true
				hopDetail.Text = string.format("Found %dP · joining %s", playerCount, foundJobId:sub(1, 8))
				addLog(string.format("Found %dP → %s", playerCount, foundJobId:sub(1, 12)))
				statusLabel.Text = "Joining..."

				local failConn
				failConn = TeleportService.TeleportInitFailed:Connect(function(_, result, err)
					if failConn then
						failConn:Disconnect()
					end
					addLog("Teleport failed: " .. tostring(result or err))
					hopDetail.Text = "Failed — retrying..."
					statusLabel.Text = "Retry"
				end)

				joinServer(foundJobId)
				task.wait(5)
				if failConn then
					pcall(function()
						failConn:Disconnect()
					end)
				end
			else
				hopDetail.Text = string.format("No match · retry (#%d)", hopAttempt)
				addLog("No quiet server this pass")
				task.wait(0.35)
			end
		end

		if gui.Parent then
			setHopUI(false)
			if not hopDetail.Text:find("Stopped") then
				hopDetail.Text = "Status: Idle"
			end
		end
	end)
end

hopBtn.MouseButton1Click:Connect(StartAutoHop)

TeleportService.TeleportInitFailed:Connect(function(_, result, errorMessage)
	warn("[Leon4951] TeleportInitFailed:", tostring(result), tostring(errorMessage))
	if statusLabel and statusLabel.Parent then
		statusLabel.Text = "Join failed"
	end
end)

task.spawn(function()
	while gui.Parent do
		pcall(function()
			currentLbl.Text = ("Now: %d player(s)  ·  Job %s"):format(
				#Players:GetPlayers(),
				tostring(game.JobId):sub(1, 8)
			)
		end)
		task.wait(1.5)
	end
end)

addLog("UI ready · private hop logic loaded")
print("[Leon4951] Ready")
