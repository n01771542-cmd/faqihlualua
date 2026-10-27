-- language: Luau, file: sena_livechat_clone.lua
-- Sena-compatible global Live Chat (real senahub.xyz API)

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local genv = getgenv and getgenv() or _G

----------------------------------------------------------------------
local CFG = {
	Api = "https://senahub.xyz/api",
	Key = "sena_20VvixjHsd1OPPwgHYJAstpM",
	PollMin = 2.5,
	MaxBubbles = 80,
	Width = 400,
	Height = 460,
	HideName = true, -- seperti default Sena free
	Room = "general", -- general | indonesian | philippines | vietnam | brazilian

	Bg = Color3.fromRGB(16, 16, 20),
	Panel = Color3.fromRGB(26, 26, 32),
	Input = Color3.fromRGB(34, 34, 42),
	Accent = Color3.fromRGB(232, 232, 238),
	Text = Color3.fromRGB(228, 228, 234),
	Muted = Color3.fromRGB(130, 130, 142),
	Self = Color3.fromRGB(120, 180, 255),
	Donator = Color3.fromRGB(255, 200, 90),
	Owner = Color3.fromRGB(255, 120, 120),
	System = Color3.fromRGB(160, 200, 160),
	Stroke = Color3.fromRGB(50, 50, 60),
}

local ROOM_TAG = {
	indonesian = "[ID]",
	philippines = "[PH]",
	vietnam = "[VN]",
	brazilian = "[BR]",
}

----------------------------------------------------------------------
local Chat = {
	gui = nil, list = nil, input = nil, status = nil, roomLbl = nil,
	chatSince = 0, connected = false, running = true,
	seen = {}, messages = {}, interval = CFG.PollMin, gameName = "",
}

local function encode(s)
	return HttpService:UrlEncode(tostring(s or ""))
end

local function httpget(url)
	local ok, body = pcall(function()
		return game:HttpGet(url, true)
	end)
	if not ok or type(body) \~= "string" or body == "" then return nil end
	local ok2, data = pcall(HttpService.JSONDecode, HttpService, body)
	if ok2 and type(data) == "table" then return data end
	return nil
end

local function apiurl(path, params)
	local parts = {}
	for k, v in pairs(params or {}) do
		parts[#parts + 1] = tostring(k) .. "=" .. encode(v)
	end
	parts[#parts + 1] = "t=" .. tostring(os.time()) .. tostring(math.random(1000, 9999))
	return CFG.Api .. path .. "?" .. table.concat(parts, "&")
end

local function detectGame()
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(game.PlaceId)
	end)
	if ok and type(info) == "table" and type(info.Name) == "string" and info.Name \~= "" then
		return info.Name
	end
	return "PlaceId " .. tostring(game.PlaceId)
end

----------------------------------------------------------------------
-- UI helpers
----------------------------------------------------------------------
local function corner(p, r)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = p
end
local function stroke(p)
	local s = Instance.new("UIStroke"); s.Color = CFG.Stroke; s.Thickness = 1; s.Transparency = 0.4; s.Parent = p
end

local function scrollBottom()
	if not Chat.list then return end
	local lay = Chat.list:FindFirstChildOfClass("UIListLayout")
	if not lay then return end
	Chat.list.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 8)
	Chat.list.CanvasPosition = Vector2.new(0, math.max(0, lay.AbsoluteContentSize.Y))
end

local function addBubble(msg)
	if not Chat.list then return end
	local id = tostring(msg.id or (tostring(msg.ts) .. ":" .. tostring(msg.name) .. ":" .. tostring(msg.text)))
	if Chat.seen[id] then return end
	Chat.seen[id] = true

	local isMine = msg.mine == true
	local nameCol = CFG.Text
	if msg.owner then nameCol = CFG.Owner
	elseif msg.donator or msg.tier == "donator" then nameCol = CFG.Donator
	elseif isMine then nameCol = CFG.Self end

	local display = tostring(msg.name or "?")
	if msg.staff then display = display .. " ★" end
	if msg.donator or msg.tier == "donator" then display = display .. " ◆" end

	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, -4, 0, 0)
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.Parent = Chat.list

	local head = Instance.new("TextLabel")
	head.BackgroundTransparency = 1
	head.Size = UDim2.new(1, 0, 0, 15)
	head.Font = Enum.Font.GothamMedium
	head.TextSize = 11
	head.TextColor3 = nameCol
	head.TextXAlignment = Enum.TextXAlignment.Left
	head.RichText = true
	local gameTag = msg.game and msg.game \~= "" and (" · " .. tostring(msg.game):sub(1, 18)) or ""
	head.Text = string.format("<b>%s</b><font color=\"#888898\">%s</font>", display, gameTag)
	head.Parent = row

	local body = Instance.new("TextLabel")
	body.BackgroundTransparency = 1
	body.Position = UDim2.new(0, 0, 0, 15)
	body.Size = UDim2.new(1, 0, 0, 0)
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.Font = Enum.Font.Gotham
	body.TextSize = 13
	body.TextColor3 = CFG.Text
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextWrapped = true
	body.Text = tostring(msg.text or "")
	body.Parent = row

	table.insert(Chat.messages, row)
	while #Chat.messages > CFG.MaxBubbles do
		local old = table.remove(Chat.messages, 1)
		if old then pcall(old.Destroy, old) end
	end
	task.defer(scrollBottom)
end

local function system(text)
	addBubble({ id = "sys:" .. os.clock(), name = "System", text = text, tier = "system" })
end

----------------------------------------------------------------------
-- transport (Sena protocol)
----------------------------------------------------------------------
local function sendChat(text)
	text = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if text == "" then return false, "empty" end

	-- block key-share patterns (sama Sena)
	local upper = text:upper()
	if upper:match("SENA%-[%w]+%-[%w]+%-[%w]+") or upper:match("TRIAL%-[%w]+%-[%w]+%-[%w]+") then
		return false, "Sharing key is prohibited"
	end

	local room = CFG.Room or "general"
	local sendtext = text
	local tag = ROOM_TAG[room]
	if tag and room \~= "general" and not sendtext:find("^%[") then
		sendtext = tag .. " " .. text
	end

	local lic = (genv.SenaKey) or (_G.SenaKey) or ""
	local data = httpget(apiurl("/chat/send", {
		uid = localPlayer.UserId,
		key = CFG.Key,
		name = localPlayer.Name,
		game = Chat.gameName,
		text = sendtext,
		room = room,
		donator = "0",
		trial = "0",
		owner = "0",
		tier = "free",
		lic = lic,
		hide = CFG.HideName and "1" or "0",
	}))
	if not data then return false, "no response" end
	if data.ok then return true end
	return false, tostring(data.error or "error")
end

local function syncOnce()
	local lic = (genv.SenaKey) or (_G.SenaKey) or ""
	local data = httpget(apiurl("/sync", {
		uid = localPlayer.UserId,
		key = CFG.Key,
		name = localPlayer.Name,
		display = localPlayer.DisplayName,
		game = Chat.gameName,
		place = game.PlaceId,
		donator = "0",
		trial = "0",
		lic = lic,
		chat_since = Chat.chatSince,
		ann_since = 0,
		dm_since = 0,
		join_since = 0,
	}))
	if not data then return false end

	if data.kick or data.blacklisted then
		Chat.running = false
		system("kicked/blacklisted by Sena backend")
		return false
	end

	Chat.connected = true
	if tonumber(data.poll) then
		Chat.interval = math.max(CFG.PollMin, tonumber(data.poll))
	end
	if data.chat_paused == true then
		if Chat.status then Chat.status.Text = "chat paused (maintenance)" end
	end

	if type(data.chat) == "table" then
		for _, msg in ipairs(data.chat) do
			local id = tonumber(msg.id) or 0
			if id > Chat.chatSince then Chat.chatSince = id end
			-- filter room if not general view-all; Sena shows all rooms in one feed usually
			addBubble(msg)
		end
	end
	return true
end

----------------------------------------------------------------------
-- build UI
----------------------------------------------------------------------
local function destroyOld()
	for _, parent in ipairs({ playerGui, gethui and gethui() or nil }) do
		if parent then
			local old = parent:FindFirstChild("SenaLiveChatClone")
			if old then pcall(old.Destroy, old) end
		end
	end
end

local function build()
	destroyOld()
	Chat.gameName = detectGame()

	local gui = Instance.new("ScreenGui")
	gui.Name = "SenaLiveChatClone"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 130
	gui.Parent = (gethui and gethui()) or playerGui
	Chat.gui = gui

	local root = Instance.new("Frame")
	root.Size = UDim2.fromOffset(CFG.Width, CFG.Height)
	root.Position = UDim2.new(1, -CFG.Width - 14, 1, -CFG.Height - 14)
	root.BackgroundColor3 = CFG.Bg
	root.BorderSizePixel = 0
	root.Active = true
	root.Parent = gui
	corner(root, 10); stroke(root)

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 40)
	header.BackgroundColor3 = CFG.Panel
	header.BorderSizePixel = 0
	header.Parent = root
	corner(header, 10)
	local hc = Instance.new("Frame")
	hc.Size = UDim2.new(1, 0, 0, 12)
	hc.Position = UDim2.new(0, 0, 1, -12)
	hc.BackgroundColor3 = CFG.Panel
	hc.BorderSizePixel = 0
	hc.Parent = header

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -80, 0, 18)
	title.Position = UDim2.new(0, 12, 0, 4)
	title.Font = Enum.Font.GothamMedium
	title.TextSize = 14
	title.TextColor3 = CFG.Accent
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "Sena Live Chat"
	title.Parent = header

	Chat.status = Instance.new("TextLabel")
	Chat.status.BackgroundTransparency = 1
	Chat.status.Size = UDim2.new(1, -80, 0, 12)
	Chat.status.Position = UDim2.new(0, 12, 0, 22)
	Chat.status.Font = Enum.Font.Gotham
	Chat.status.TextSize = 10
	Chat.status.TextColor3 = CFG.Muted
	Chat.status.TextXAlignment = Enum.TextXAlignment.Left
	Chat.status.Text = "connecting..."
	Chat.status.Parent = header

	local function ibtn(x, txt, bg, fg)
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(28, 28)
		b.Position = UDim2.new(1, x, 0, 6)
		b.BackgroundColor3 = bg
		b.Text = txt
		b.TextColor3 = fg
		b.Font = Enum.Font.GothamBold
		b.TextSize = 16
		b.BorderSizePixel = 0
		b.Parent = header
		corner(b, 6)
		return b
	end
	local closeBtn = ibtn(-34, "×", Color3.fromRGB(50, 30, 30), Color3.fromRGB(255, 150, 150))
	local minBtn = ibtn(-66, "–", Color3.fromRGB(40, 40, 48), CFG.Muted)

	local list = Instance.new("ScrollingFrame")
	list.Position = UDim2.new(0, 8, 0, 48)
	list.Size = UDim2.new(1, -16, 1, -100)
	list.BackgroundColor3 = CFG.Panel
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 4
	list.ScrollBarImageColor3 = CFG.Muted
	list.CanvasSize = UDim2.new(0, 0, 0, 0)
	list.Parent = root
	corner(list, 8)
	Chat.list = list

	local lay = Instance.new("UIListLayout")
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Padding = UDim.new(0, 5)
	lay.Parent = list
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 6); pad.PaddingBottom = UDim.new(0, 6)
	pad.PaddingLeft = UDim.new(0, 6); pad.PaddingRight = UDim.new(0, 6)
	pad.Parent = list
	lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(scrollBottom)

	-- room strip
	local roomBar = Instance.new("Frame")
	roomBar.Position = UDim2.new(0, 8, 1, -48)
	roomBar.Size = UDim2.new(1, -16, 0, 18)
	roomBar.BackgroundTransparency = 1
	roomBar.Parent = root
	Chat.roomLbl = Instance.new("TextLabel")
	Chat.roomLbl.BackgroundTransparency = 1
	Chat.roomLbl.Size = UDim2.new(1, 0, 1, 0)
	Chat.roomLbl.Font = Enum.Font.Gotham
	Chat.roomLbl.TextSize = 11
	Chat.roomLbl.TextColor3 = CFG.Muted
	Chat.roomLbl.TextXAlignment = Enum.TextXAlignment.Left
	Chat.roomLbl.Text = "room: " .. CFG.Room .. "  ·  hide name: " .. tostring(CFG.HideName)
	Chat.roomLbl.Parent = roomBar

	local inputBar = Instance.new("Frame")
	inputBar.Position = UDim2.new(0, 8, 1, -28)
	inputBar.Size = UDim2.new(1, -16, 0, 24)
	inputBar.BackgroundColor3 = CFG.Input
	inputBar.BorderSizePixel = 0
	inputBar.Parent = root
	corner(inputBar, 6)

	local input = Instance.new("TextBox")
	input.Size = UDim2.new(1, -40, 1, 0)
	input.Position = UDim2.new(0, 8, 0, 0)
	input.BackgroundTransparency = 1
	input.Font = Enum.Font.Gotham
	input.TextSize = 13
	input.TextColor3 = CFG.Text
	input.PlaceholderText = "message to Sena global..."
	input.PlaceholderColor3 = CFG.Muted
	input.Text = ""
	input.ClearTextOnFocus = false
	input.TextXAlignment = Enum.TextXAlignment.Left
	input.Parent = inputBar
	Chat.input = input

	local sendBtn = Instance.new("TextButton")
	sendBtn.Size = UDim2.fromOffset(28, 20)
	sendBtn.Position = UDim2.new(1, -30, 0, 2)
	sendBtn.BackgroundColor3 = Color3.fromRGB(55, 85, 130)
	sendBtn.Text = "▶"
	sendBtn.TextColor3 = CFG.Accent
	sendBtn.Font = Enum.Font.GothamBold
	sendBtn.TextSize = 11
	sendBtn.BorderSizePixel = 0
	sendBtn.Parent = inputBar
	corner(sendBtn, 5)

	local function doSend()
		local text = (input.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if text == "" then return end
		input.Text = ""
		-- optimistic local echo
		addBubble({
			id = "local:" .. os.clock(),
			name = CFG.HideName and (localPlayer.Name:sub(1, 2) .. "****") or localPlayer.Name,
			text = text,
			mine = true,
			game = Chat.gameName,
		})
		task.spawn(function()
			local ok, err = sendChat(text)
			if not ok then
				system("send failed: " .. tostring(err))
			end
		end)
	end
	sendBtn.MouseButton1Click:Connect(doSend)
	input.FocusLost:Connect(function(enter) if enter then doSend() end end)

	-- drag
	local dragging, dragStart, startPos
	header.InputBegan:Connect(function(io)
		if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragStart = io.Position; startPos = root.Position
			io.Changed:Connect(function()
				if io.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(io)
		if dragging and (io.UserInputType == Enum.UserInputType.MouseMovement or io.UserInputType == Enum.UserInputType.Touch) then
			local d = io.Position - dragStart
			root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)

	local minimized = false
	minBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		list.Visible = not minimized
		inputBar.Visible = not minimized
		roomBar.Visible = not minimized
		root.Size = minimized and UDim2.fromOffset(CFG.Width, 40) or UDim2.fromOffset(CFG.Width, CFG.Height)
	end)
	closeBtn.MouseButton1Click:Connect(function()
		Chat.running = false
		gui.Enabled = false
	end)

	-- poll loop
	task.spawn(function()
		system("connecting to senahub.xyz ...")
		while Chat.running and gui.Parent do
			local ok = pcall(syncOnce)
			if Chat.status then
				Chat.status.Text = Chat.connected
					and ("online · room " .. CFG.Room .. " · poll " .. string.format("%.1fs", Chat.interval))
					or "reconnecting..."
			end
			task.wait(Chat.interval)
		end
	end)

	return Chat
end

local ui = build()
genv.__SenaLiveChatClone = Chat
return Chat