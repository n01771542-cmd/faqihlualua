--[[
  Leon4951 — Private Server Hop
  List quiet servers: Private server | N players  [Hop Now]
]]

local Players = game:GetService("Players")
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
local REFRESH_INTERVAL = 4
local MAX_ROWS = 40

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
-- SCAN: collect quiet servers (1P then 2P), bottom-to-mid order
--------------------------------------------------------------------------------
local maxPlayersPrefer = 2
local latestServers = {} -- { {id=, playing=, maxPlayers=}, ... }
local autoHop = false
local autoHopToken = 0

local function scanQuietServers()
	local cursor = ""
	local servers1P, servers2P = {}, {}

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
			if id and id ~= tostring(game.JobId) and not _G.LeonBlacklist[id] and (maxP - playing) >= 1 then
				local entry = { id = id, playing = playing, maxPlayers = maxP }
				if playing == 1 then
					servers1P[#servers1P + 1] = entry
				elseif playing == 2 and maxPlayersPrefer >= 2 then
					servers2P[#servers2P + 1] = entry
				end
			end
		end

		cursor = decoded.nextPageCursor or ""
		if cursor == "" then
			break
		end
	end

	-- bottom → mid preference: reverse each list, take from near end toward half
	local function orderTail(list)
		local out = {}
		if #list == 0 then
			return out
		end
		local startIndex = math.max(1, #list - 6)
		local minLimit = math.max(1, math.floor(#list * 0.5))
		for i = startIndex, minLimit, -1 do
			out[#out + 1] = list[i]
		end
		-- append rest (still quiet) so list is not empty
		local seen = {}
		for _, e in ipairs(out) do
			seen[e.id] = true
		end
		for i = #list, 1, -1 do
			local e = list[i]
			if not seen[e.id] then
				out[#out + 1] = e
				seen[e.id] = true
			end
		end
		return out
	end

	local ordered = orderTail(servers1P)
	if maxPlayersPrefer >= 2 then
		for _, e in ipairs(orderTail(servers2P)) do
			ordered[#ordered + 1] = e
		end
	end

	-- dedupe + cap
	local final, seen = {}, {}
	for _, e in ipairs(ordered) do
		if not seen[e.id] then
			seen[e.id] = true
			final[#final + 1] = e
			if #final >= MAX_ROWS then
				break
			end
		end
	end
	return final
end

local function joinServer(jobId)
	jobId = tostring(jobId or "")
	if jobId == "" or jobId == tostring(game.JobId) then
		return false
	end
	_G.LeonBlacklist[jobId] = true
	local ok = pcall(function()
		TeleportService:TeleportToPlaceInstance(PlaceId, jobId, player)
	end)
	if ok then
		return true
	end
	return pcall(function()
		TeleportService:TeleportToPlaceInstance(PlaceId, jobId)
	end)
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

-- Sidebar
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
local statusLabel = label(sidebar, "Scanning...", 9, FONT_MED, SUB_TEXT,
	UDim2.fromOffset(22, 44), UDim2.fromOffset(90, 16))

label(sidebar, "Max players", 9, FONT_MED, MUTED,
	UDim2.fromOffset(10, 72), UDim2.fromOffset(100, 14))

local maxValueLbl = label(sidebar, "2", 16, FONT_BOLD, WHITE,
	UDim2.fromOffset(10, 88), UDim2.fromOffset(30, 22))

local max1 = button(sidebar, {
	text = "1",
	textSize = 11,
	pos = UDim2.fromOffset(40, 88),
	size = UDim2.fromOffset(32, 24),
	c0 = ACCENT,
	c1 = ACCENT_DARK,
	strokeColor = ACCENT_HI,
	radius = 6,
})
local max2 = button(sidebar, {
	text = "2",
	textSize = 11,
	pos = UDim2.fromOffset(76, 88),
	size = UDim2.fromOffset(32, 24),
	c0 = ACCENT,
	c1 = ACCENT_DARK,
	strokeColor = ACCENT_HI,
	radius = 6,
})

local function setMax(n)
	maxPlayersPrefer = n
	maxValueLbl.Text = tostring(n)
end
max1.MouseButton1Click:Connect(function()
	setMax(1)
end)
max2.MouseButton1Click:Connect(function()
	setMax(2)
end)

local autoBtn = button(sidebar, {
	text = "Auto Hop: OFF",
	textSize = 10,
	pos = UDim2.fromOffset(6, 124),
	size = UDim2.fromOffset(108, 28),
	c0 = Color3.fromRGB(10, 30, 70),
	c1 = Color3.fromRGB(8, 14, 28),
	strokeColor = ACCENT,
	strokeTransparency = 0.25,
	radius = 8,
})

local refreshBtn = button(sidebar, {
	text = "Refresh",
	textSize = 10,
	pos = UDim2.fromOffset(6, 158),
	size = UDim2.fromOffset(108, 26),
	c0 = Color3.fromRGB(10, 30, 70),
	c1 = Color3.fromRGB(8, 14, 28),
	strokeColor = ACCENT,
	strokeTransparency = 0.3,
	radius = 8,
})

label(sidebar, "Author: " .. AUTHOR, 9, FONT_BOLD, SUB_TEXT,
	UDim2.fromOffset(10, 196), UDim2.fromOffset(100, 14))

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

-- Content
local content = new("Frame", {
	Name = "Content",
	Position = UDim2.fromOffset(128, 0),
	Size = UDim2.new(1, -128, 1, 0),
	BackgroundTransparency = 1,
}, main)

label(content, "PRIVATE SERVERS", 11, FONT_BOLD, ACCENT_HI,
	UDim2.fromOffset(10, 10), UDim2.fromOffset(160, 18))

local countLbl = label(content, "0 found", 9, FONT_MED, MUTED,
	UDim2.new(1, -90, 0, 12), UDim2.fromOffset(80, 16), Enum.TextXAlignment.Right)

local currentLbl = label(content,
	("You: %dP · %s"):format(#Players:GetPlayers(), tostring(game.JobId):sub(1, 8)),
	9, FONT_MED, MUTED,
	UDim2.fromOffset(10, 30), UDim2.new(1, -20, 0, 14))

local feedBox = new("Frame", {
	Position = UDim2.fromOffset(8, 50),
	Size = UDim2.new(1, -16, 1, -58),
	BackgroundColor3 = WHITE,
	BackgroundTransparency = 0.18,
	BorderSizePixel = 0,
}, content)
corner(feedBox, 10)
gradient(feedBox, Color3.fromRGB(6, 12, 24), Color3.fromRGB(5, 6, 10), 90)
stroke(feedBox, ACCENT, 1, 0.55)

local feed = new("ScrollingFrame", {
	Position = UDim2.fromOffset(6, 6),
	Size = UDim2.new(1, -12, 1, -12),
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
new("UIPadding", { PaddingRight = UDim.new(0, 4) }, feed)

local emptyLbl = label(feed, "Scanning quiet servers...", 11, FONT_MED, MUTED,
	UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 28), Enum.TextXAlignment.Center)

local function clearFeed()
	for _, c in ipairs(feed:GetChildren()) do
		if c:IsA("Frame") or (c:IsA("TextLabel") and c ~= emptyLbl) then
			c:Destroy()
		end
	end
end

local function addRow(entry, order)
	local row = new("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.06,
		BorderSizePixel = 0,
	}, feed)
	corner(row, 8)
	gradient(row, Color3.fromRGB(10, 32, 70), Color3.fromRGB(11, 16, 26), 0)
	accentStroke(row, 1, 0.45)

	-- left accent bar
	local bar = new("Frame", {
		Position = UDim2.fromOffset(5, 8),
		Size = UDim2.fromOffset(4, 32),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
	}, row)
	corner(bar, 2)
	gradient(bar, ACCENT_HI, ACCENT_DARK, 90)

	-- "Private server"
	label(row, "Private server", 12, FONT_BOLD, WHITE,
		UDim2.fromOffset(16, 6), UDim2.new(1, -100, 0, 18))

	-- player count
	local n = entry.playing or 0
	local countText = n == 1 and "1 player" or (tostring(n) .. " players")
	label(row, countText, 10, FONT_MED, SUB_TEXT,
		UDim2.fromOffset(16, 26), UDim2.new(1, -100, 0, 14))

	local hop = button(row, {
		text = "Hop Now",
		textSize = 10,
		anchor = Vector2.new(1, 0.5),
		pos = UDim2.new(1, -10, 0.5, 0),
		size = UDim2.fromOffset(72, 28),
		c0 = ACCENT,
		c1 = ACCENT_DARK,
		strokeColor = ACCENT_HI,
		strokeTransparency = 0.2,
		radius = 7,
	})
	hop.MouseButton1Click:Connect(function()
		statusLabel.Text = "Joining..."
		hop.Text = "..."
		joinServer(entry.id)
	end)
end

local function renderList(list)
	local scroll = feed.CanvasPosition
	clearFeed()
	if emptyLbl.Parent then
		emptyLbl.Visible = false
	end

	if not list or #list == 0 then
		if emptyLbl.Parent then
			emptyLbl.Visible = true
			emptyLbl.Text = "No quiet server found"
		end
		countLbl.Text = "0 found"
		return
	end

	for i, e in ipairs(list) do
		addRow(e, i)
	end
	countLbl.Text = #list .. " found"
	feed.CanvasPosition = scroll
end

local scanning = false
local function doScan()
	if scanning then
		return
	end
	scanning = true
	statusLabel.Text = "Scanning..."
	task.spawn(function()
		local ok, list = pcall(scanQuietServers)
		scanning = false
		if ok and type(list) == "table" then
			latestServers = list
			renderList(list)
			statusLabel.Text = #list > 0 and "Ready" or "Empty"
		else
			statusLabel.Text = "Scan fail"
			if emptyLbl.Parent then
				emptyLbl.Visible = true
				emptyLbl.Text = "Scan failed — retry"
			end
		end
	end)
end

refreshBtn.MouseButton1Click:Connect(doScan)

autoBtn.MouseButton1Click:Connect(function()
	autoHop = not autoHop
	if autoHop then
		autoBtn.Text = "Auto Hop: ON"
		autoHopToken += 1
		local my = autoHopToken
		task.spawn(function()
			while autoHop and autoHopToken == my and gui.Parent do
				if #latestServers > 0 then
					local target = latestServers[1]
					statusLabel.Text = "Auto join..."
					joinServer(target.id)
					task.wait(5)
				else
					doScan()
					task.wait(2)
				end
				task.wait(1)
			end
		end)
	else
		autoBtn.Text = "Auto Hop: OFF"
		autoHopToken += 1
		statusLabel.Text = "Ready"
	end
end)

TeleportService.TeleportInitFailed:Connect(function(_, result, err)
	warn("[Leon4951] Teleport failed:", result, err)
	statusLabel.Text = "Join failed"
end)

task.spawn(function()
	while gui.Parent do
		pcall(function()
			currentLbl.Text = ("You: %dP · %s"):format(
				#Players:GetPlayers(),
				tostring(game.JobId):sub(1, 8)
			)
		end)
		task.wait(1.5)
	end
end)

-- auto refresh list
task.spawn(function()
	doScan()
	while gui.Parent do
		task.wait(REFRESH_INTERVAL)
		if not autoHop then
			doScan()
		end
	end
end)

print("[Leon4951] Ready")
