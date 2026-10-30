-- Private Server Hop | UI gaya Leon-finder (hitam + biru) | 280x320 | 1 tombol
-- Logika hop disalin dari Sena V4 "Find Private Server" (Max Players = 1).
-- Tidak memakai queue_on_teleport, jadi script TIDAK jalan lagi setelah pindah server.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
if not player then
	player = Players.PlayerAdded:Wait()
end
local playerGui = player:WaitForChild("PlayerGui", 8)

-- ─── CONFIG ───────────────────────────────────────────────────────────────
local GUI_NAME = "Private Serverhop"
local TITLE = "Leon|Private server"
local W, H = 280, 310
local PRIVATE_MAX = 1       -- jumlah pemain maksimum yang diinginkan, termasuk kamu (Sena: Max Players)
local PAGES = 3              -- halaman daftar server yang diambil (100 server/halaman) - sama seperti Sena
local JOIN_TIMEOUT = 6       -- detik menunggu teleport sebelum dianggap gagal - sama seperti Sena
local AUTO_RETRY = true      -- true: tombol terus mencoba lagi tiap RETRY_WAIT detik (seperti Auto Hop Sena); tekan lagi untuk berhenti
local RETRY_WAIT = 5         -- jeda antar percobaan (Sena: 5 detik)
local LATE_FAIL_WINDOW = 15  -- detik tambahan memantau teleport yang gagal terlambat (tambahan, tidak ada di Sena)
local MAX_OPTIONS = 5        -- pilihan Players 1..5

-- ─── PALETTE ──────────────────────────────────────────────────────────────
local WHITE       = Color3.fromRGB(255, 255, 255)
local ACCENT_HI   = Color3.fromRGB(90, 170, 255)
local ACCENT      = Color3.fromRGB(40, 120, 255)
local ACCENT_DARK = Color3.fromRGB(20, 55, 130)
local SUB_TEXT    = Color3.fromRGB(160, 180, 210)
local MUTED       = Color3.fromRGB(100, 120, 150)
local BG_BLACK    = Color3.fromRGB(0, 0, 0)
local BG_PANEL    = Color3.fromRGB(6, 8, 13)
local OK_GREEN    = Color3.fromRGB(110, 240, 160)
local ERR_RED     = Color3.fromRGB(255, 120, 120)

local FONT_BOLD = Enum.Font.GothamBold
local FONT_MED  = Enum.Font.GothamMedium

-- ─── HELPERS UI ───────────────────────────────────────────────────────────
local function new(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do
		inst[k] = v
	end
	if parent then inst.Parent = parent end
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

-- ─── GUI ──────────────────────────────────────────────────────────────────
-- hapus UI lama kalau script dijalankan ulang
for _, root in ipairs({ CoreGui, playerGui }) do
	pcall(function()
		local old = root and root:FindFirstChild(GUI_NAME)
		if old then old:Destroy() end
	end)
end

local gui = new("ScreenGui", {
	Name = GUI_NAME,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = true,
	DisplayOrder = 50,
})
local parented = pcall(function() gui.Parent = CoreGui end)
if not parented or not gui.Parent then
	gui.Parent = playerGui
end

local SOFT_BLUE = Color3.fromRGB(55, 125, 235) -- outline biru halus
local CARD_BG   = Color3.fromRGB(14, 16, 22)
local LINE      = Color3.fromRGB(45, 50, 62)

local main = new("Frame", {
	Name = "Main",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(W, H),
	BackgroundColor3 = BG_BLACK,
	BorderSizePixel = 0,
	ClipsDescendants = true,
}, gui)
corner(main, 14)
stroke(main, SOFT_BLUE, 1.5, 0.35)

-- judul + subjudul
label(main, TITLE, 18, FONT_BOLD, WHITE,
	UDim2.fromOffset(16, 14), UDim2.new(1, -84, 0, 26))
local subtitleLabel = label(main, "Server Hopper · 1 pemain", 11, FONT_MED, MUTED,
	UDim2.fromOffset(16, 40), UDim2.new(1, -84, 0, 16))

-- tombol X (putih, besar) di kanan atas
local closeBg = new("Frame", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 12),
	Size = UDim2.fromOffset(46, 46),
	BackgroundColor3 = CARD_BG,
	BorderSizePixel = 0,
}, main)
corner(closeBg, 12)
stroke(closeBg, SOFT_BLUE, 1.3, 0.25)
local closeBtn = new("TextButton", {
	AutoButtonColor = false,
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = "X",
	TextSize = 28,
	Font = FONT_BOLD,
	TextColor3 = WHITE,
	BorderSizePixel = 0,
}, closeBg)

-- kartu info
local card = new("Frame", {
	Position = UDim2.fromOffset(12, 72),
	Size = UDim2.new(1, -24, 0, 174),
	BackgroundColor3 = CARD_BG,
	BorderSizePixel = 0,
}, main)
corner(card, 12)
stroke(card, SOFT_BLUE, 1.2, 0.4)

label(card, "PEMAIN DI SERVER", 10, FONT_MED, MUTED,
	UDim2.fromOffset(16, 10), UDim2.new(1, -150, 0, 14))
local playersLabel = label(card, "-", 26, FONT_BOLD, WHITE,
	UDim2.fromOffset(16, 24), UDim2.new(1, -150, 0, 40))

new("Frame", {
	Position = UDim2.fromOffset(16, 68),
	Size = UDim2.new(1, -32, 0, 1),
	BackgroundColor3 = LINE,
	BorderSizePixel = 0,
}, card)

label(card, "AKURASI HOP", 10, FONT_MED, MUTED,
	UDim2.fromOffset(16, 78), UDim2.new(0.5, -16, 0, 14))
local targetLabel = label(card, "Maks 1 pemain", 13, FONT_BOLD, WHITE,
	UDim2.fromOffset(16, 94), UDim2.new(0.5, -16, 0, 30))

label(card, "STATUS", 10, FONT_MED, MUTED,
	UDim2.new(0.5, 0, 0, 78), UDim2.new(0.5, -16, 0, 14))
local statusLabel = label(card, "Siap", 12, FONT_BOLD, WHITE,
	UDim2.new(0.5, 0, 0, 94), UDim2.new(0.5, -16, 0, 30))
statusLabel.TextWrapped = true
statusLabel.TextTruncate = Enum.TextTruncate.AtEnd

local accNote = label(card, "Cari server dengan pemain paling sedikit sampai sesuai pilihanmu. Server penuh atau gagal dilewati, lalu coba server lain.",
	10, FONT_MED, MUTED, UDim2.fromOffset(16, 128), UDim2.new(1, -32, 0, 36))
accNote.TextWrapped = true
accNote.TextYAlignment = Enum.TextYAlignment.Top

-- pilihan jumlah pemain (Players 1-5): tekan tombol ▲▼, daftar muncul ke bawah
local ARROW_UP, ARROW_DOWN = "▲", "▼" -- kalau di executor tampil kotak, ganti teksnya
PRIVATE_MAX = math.clamp(math.floor(tonumber(PRIVATE_MAX) or 1), 1, MAX_OPTIONS)

label(card, "MAKS PEMAIN", 10, FONT_MED, MUTED,
	UDim2.new(1, -116, 0, 6), UDim2.fromOffset(100, 12))

local selBg = new("Frame", {
	Position = UDim2.new(1, -116, 0, 20),
	Size = UDim2.fromOffset(100, 34),
	BackgroundColor3 = Color3.fromRGB(24, 28, 40),
	BorderSizePixel = 0,
}, card)
corner(selBg, 8)
stroke(selBg, SOFT_BLUE, 1.2, 0.25)
local selBtn = new("TextButton", {
	AutoButtonColor = false,
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = "Players " .. PRIVATE_MAX,
	TextSize = 12,
	Font = FONT_BOLD,
	TextColor3 = WHITE,
	TextXAlignment = Enum.TextXAlignment.Left,
	BorderSizePixel = 0,
}, selBg)
new("UIPadding", { PaddingLeft = UDim.new(0, 10) }, selBtn)
label(selBg, ARROW_UP .. "\n" .. ARROW_DOWN, 8, FONT_BOLD, ACCENT_HI,
	UDim2.new(1, -24, 0, 0), UDim2.fromOffset(18, 34), Enum.TextXAlignment.Center)

-- daftar pilihan (di atas semua elemen, tepat di bawah tombol)
local popup = new("Frame", {
	Position = UDim2.new(1, -128, 0, 130),
	Size = UDim2.fromOffset(100, MAX_OPTIONS * 24 + 6),
	BackgroundColor3 = Color3.fromRGB(18, 21, 30),
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 20,
}, main)
corner(popup, 8)
stroke(popup, SOFT_BLUE, 1.2, 0.25)

local optionBtns = {}
local function selectMax(n)
	PRIVATE_MAX = n
	selBtn.Text = "Players " .. n
	targetLabel.Text = "Maks " .. n .. " pemain"
	subtitleLabel.Text = "Server Hopper · " .. n .. " pemain"
	for i, b in ipairs(optionBtns) do
		b.BackgroundTransparency = (i == n) and 0.55 or 1
	end
	popup.Visible = false
end
for i = 1, MAX_OPTIONS do
	local b = new("TextButton", {
		AutoButtonColor = false,
		Position = UDim2.fromOffset(4, 3 + (i - 1) * 24),
		Size = UDim2.new(1, -8, 0, 22),
		BackgroundColor3 = SOFT_BLUE,
		BackgroundTransparency = 1,
		Text = "Players " .. i,
		TextSize = 12,
		Font = FONT_MED,
		TextColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 21,
	}, popup)
	corner(b, 6)
	b.MouseButton1Click:Connect(function()
		selectMax(i)
	end)
	optionBtns[i] = b
end
selectMax(PRIVATE_MAX)
selBtn.MouseButton1Click:Connect(function()
	popup.Visible = not popup.Visible
end)

-- tombol hop (satu-satunya tombol aksi)
local hopBg = new("Frame", {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 12, 1, -14),
	Size = UDim2.new(1, -24, 0, 50),
	BackgroundColor3 = WHITE,
	BorderSizePixel = 0,
}, main)
corner(hopBg, 12)
gradient(hopBg, Color3.fromRGB(30, 38, 58), Color3.fromRGB(12, 14, 20), 90)
stroke(hopBg, SOFT_BLUE, 1.5, 0.25)
local hopBtn = new("TextButton", {
	AutoButtonColor = false,
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = "HOP SERVER",
	TextSize = 14,
	Font = FONT_BOLD,
	TextColor3 = WHITE,
	BorderSizePixel = 0,
}, hopBg)

-- drag dari area atas (judul) supaya tidak bentrok dengan tombol
do
	local dragging, dragStart, startPos
	main.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			local rel = Vector2.new(input.Position.X, input.Position.Y) - main.AbsolutePosition
			if rel.Y < 68 then
				dragging = true
				dragStart = input.Position
				startPos = main.Position
			end
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

closeBtn.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

local function setStatus(text, color)
	statusLabel.Text = text
	statusLabel.TextColor3 = color or WHITE
end

-- jumlah pemain di server saat ini (live)
task.spawn(function()
	while gui.Parent do
		playersLabel.Text = ("%d / %d"):format(#Players:GetPlayers(), Players.MaxPlayers)
		task.wait(2)
	end
end)

-- ─── LOGIKA HOP SERVER (disalin dari Sena V4: Find Private Server) ──────────
-- Dilewati dari Sena: hubBusy (cek steal/place), fn2 (sesi hub), HopNoMatch,
-- Rare Egg Hop, dan semua queue_on_teleport / auto execute.

local function privateMax()
	return math.max(1, math.floor(tonumber(PRIVATE_MAX) or 1))
end

-- HttpGet dulu (seperti Sena), lalu request executor sebagai cadangan
local function httpGet(url)
	local ok, body = pcall(function() return game:HttpGet(url) end)
	if ok and body then return body end
	local okR, res = pcall(function()
		local fn = (syn and syn.request) or http_request or request
		if fn then
			return fn({ Url = url, Method = "GET" })
		end
		return nil
	end)
	if okR and type(res) == "table" and res.Body then return res.Body end
	return nil
end

-- deteksi teleport gagal (Sena: hanya untuk LocalPlayer)
local hopFailed = false
pcall(function()
	TeleportService.TeleportInitFailed:Connect(function(plr)
		if plr == player then
			hopFailed = true
		end
	end)
end)

-- Sena: collectServers
local function collectServers(maxFilter)
	local list = {}
	local cursor = ""

	for _ = 1, PAGES do
		local ok, result = pcall(function()
			local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100&excludeFullGames=true"):format(game.PlaceId)
			if cursor ~= "" then
				url = url .. "&cursor=" .. cursor
			end
			return HttpService:JSONDecode(httpGet(url))
		end)

		if not ok or type(result) ~= "table" then break end

		for _, s in ipairs(result.data or {}) do
			if tostring(s.id) ~= game.JobId
				and s.playing
				and s.maxPlayers
				and s.playing < s.maxPlayers
				and (not maxFilter or s.playing <= maxFilter)
			then
				list[#list + 1] = { id = tostring(s.id), playing = s.playing }
			end
		end

		cursor = result.nextPageCursor or ""
		if cursor == "" then break end
	end

	table.sort(list, function(a, b)
		return a.playing < b.playing
	end)

	return list
end

-- Sena: hopToList
local function hopToList(list)
	if type(list) ~= "table" or #list == 0 then
		return false
	end

	for i, srv in ipairs(list) do
		hopFailed = false
		setStatus(("Teleport %d/%d (%d pemain)"):format(i, #list, srv.playing), ACCENT_HI)

		if pcall(function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, player)
		end) then
			local t0 = os.clock()
			while not hopFailed and os.clock() - t0 < JOIN_TIMEOUT do
				task.wait(0.25)
			end

			if not hopFailed then
				return true
			end
		end

		task.wait(0.3)
	end

	return false
end

-- Sena: findPrivateTargets
local function findPrivateTargets()
	local maxWanted = privateMax()
	local all = collectServers(nil)
	if #all == 0 then
		return nil
	end

	local good = {}
	for _, s in ipairs(all) do
		if s.playing + 1 <= maxWanted then
			good[#good + 1] = s
		end
	end

	-- tidak ada yang memenuhi: pakai server dengan pemain paling sedikit
	if #good == 0 then
		local lowest = all[1].playing
		-- TAMBAHAN (tidak ada di Sena): jangan pindah ke server yang tidak lebih sepi dari sekarang
		if lowest + 1 >= #Players:GetPlayers() then
			return {}
		end
		for _, s in ipairs(all) do
			if s.playing == lowest then
				good[#good + 1] = s
			end
		end
	end

	-- acak, ambil maksimal 5 target
	local targets = {}
	while #good > 0 and #targets < 5 do
		targets[#targets + 1] = table.remove(good, math.random(1, #good))
	end

	return targets
end

-- Sena: hopPrivateOnce -> mengembalikan (berhasil_teleport, alasan)
local function hopPrivateOnce()
	local maxWanted = privateMax()
	local current = #Players:GetPlayers()

	if current <= maxWanted then
		setStatus(("Server sudah sepi (%d pemain)"):format(current), OK_GREEN)
		return false, "good"
	end

	setStatus("Mencari server lebih sepi...", ACCENT_HI)
	local targets = findPrivateTargets()

	if not targets then
		setStatus("Gagal memuat daftar server", ERR_RED)
		return false, "nolist"
	end
	if #targets == 0 then
		setStatus("Belum ada server lebih sepi", ERR_RED)
		return false, "nobetter"
	end

	if hopToList(targets) then
		return true, "teleporting"
	end

	setStatus("Teleport gagal, coba lagi", ERR_RED)
	return false, "failed"
end

-- satu tombol: jalankan hopPrivateOnce; kalau AUTO_RETRY, ulangi seperti Auto Hop Sena
local hopping, stopRequested = false, false
local function hop()
	if hopping then
		stopRequested = true
		setStatus("Menghentikan...", SUB_TEXT)
		return
	end
	hopping, stopRequested = true, false
	popup.Visible = false
	hopBtn.Text = AUTO_RETRY and "BERHENTI" or "MENCARI..."

	while gui.Parent do
		local okCall, done, reason = pcall(hopPrivateOnce)
		if not okCall then
			warn("[" .. TITLE .. "] Hop error:", done)
			setStatus("Error, coba lagi", ERR_RED)
		elseif reason == "good" then
			break
		elseif done then
			-- teleport berjalan. Kalau ternyata gagal belakangan (lewat jendela 6 detik), coba lagi.
			if not AUTO_RETRY then break end
			local w0 = os.clock()
			while not hopFailed and not stopRequested and gui.Parent
				and os.clock() - w0 < LATE_FAIL_WINDOW do
				task.wait(0.25)
			end
			if not hopFailed then break end
			setStatus("Teleport gagal, coba lagi", ERR_RED)
		end

		if not AUTO_RETRY or stopRequested then break end

		local t0 = os.clock()
		while gui.Parent and not stopRequested and os.clock() - t0 < RETRY_WAIT do
			task.wait(0.25)
		end
		if stopRequested then break end
	end

	if gui.Parent then
		if stopRequested then
			setStatus("Dihentikan", SUB_TEXT)
		end
		hopBtn.Text = "HOP SERVER"
	end
	hopping = false
end

hopBtn.MouseButton1Click:Connect(function()
	task.spawn(hop)
end)

setStatus("Siap", OK_GREEN)
