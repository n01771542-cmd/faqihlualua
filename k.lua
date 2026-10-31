-- Private Server Hop | UI gaya Leon-finder (hitam + biru) | 280x310 | 1 tombol
-- Logika hop disalin dari Sena V4 "Find Private Server" (selalu Players 1).
-- Tidak memakai queue_on_teleport, jadi script TIDAK jalan lagi setelah pindah server
-- (pakai auto-execute executor kalau mau otomatis jalan lagi).

local Players = game:GetService("Players")
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
local GUI_NAME = "PrivateServerHop"
local TITLE = "Leon | Private server"
local W, H = 280, 310
local PRIVATE_MAX = 1        -- selalu Players 1 (termasuk kamu)
local PAGES = 3              -- halaman daftar server yang diambil (100 server/halaman)
local JOIN_TIMEOUT = 6       -- detik menunggu teleport sebelum dianggap gagal
local HTTP_TIMEOUT = 6       -- detik menunggu satu request daftar server (anti macet di "Mencari...")
local HTTP_ATTEMPTS = 2      -- percobaan per halaman kalau request gagal / timeout / kena limit
local AUTO_RETRY = true      -- true: terus mencoba lagi tiap RETRY_WAIT detik; tekan lagi untuk berhenti
local RETRY_WAIT = 5         -- jeda antar percobaan
local LATE_FAIL_WINDOW = 15  -- detik tambahan memantau teleport yang gagal terlambat

-- ─── PALETTE ──────────────────────────────────────────────────────────────
local WHITE       = Color3.fromRGB(255, 255, 255)
local ACCENT_HI   = Color3.fromRGB(90, 170, 255)
local SUB_TEXT    = Color3.fromRGB(160, 180, 210)
local MUTED       = Color3.fromRGB(100, 120, 150)
local BG_BLACK    = Color3.fromRGB(0, 0, 0)
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

local SOFT_BLUE = Color3.fromRGB(55, 125, 235)
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

label(main, TITLE, 18, FONT_BOLD, WHITE,
        UDim2.fromOffset(16, 14), UDim2.new(1, -84, 0, 26))
label(main, "Server Hopper", 11, FONT_MED, MUTED,
        UDim2.fromOffset(16, 40), UDim2.new(1, -84, 0, 16))

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

local card = new("Frame", {
        Position = UDim2.fromOffset(12, 72),
        Size = UDim2.new(1, -24, 0, 174),
        BackgroundColor3 = CARD_BG,
        BorderSizePixel = 0,
}, main)
corner(card, 12)
stroke(card, SOFT_BLUE, 1.2, 0.4)

label(card, "PEMAIN DI SERVER", 10, FONT_MED, MUTED,
        UDim2.fromOffset(16, 10), UDim2.new(1, -32, 0, 14))
local playersLabel = label(card, "-", 26, FONT_BOLD, WHITE,
        UDim2.fromOffset(16, 24), UDim2.new(1, -32, 0, 40))

new("Frame", {
        Position = UDim2.fromOffset(16, 68),
        Size = UDim2.new(1, -32, 0, 1),
        BackgroundColor3 = LINE,
        BorderSizePixel = 0,
}, card)

label(card, "AKURASI HOP", 10, FONT_MED, MUTED,
        UDim2.fromOffset(16, 78), UDim2.new(0.5, -16, 0, 14))
label(card, "Server sepi", 13, FONT_BOLD, WHITE,
        UDim2.fromOffset(16, 94), UDim2.new(0.5, -16, 0, 30))

label(card, "STATUS", 10, FONT_MED, MUTED,
        UDim2.new(0.5, 0, 0, 78), UDim2.new(0.5, -16, 0, 14))
local statusLabel = label(card, "Siap", 12, FONT_BOLD, WHITE,
        UDim2.new(0.5, 0, 0, 94), UDim2.new(0.5, -16, 0, 30))
statusLabel.TextWrapped = true
statusLabel.TextTruncate = Enum.TextTruncate.AtEnd

local accNote = label(card, "Pindah ke server dengan pemain paling sedikit. Server penuh atau gagal dilewati, lalu coba server lain.",
        10, FONT_MED, MUTED, UDim2.fromOffset(16, 128), UDim2.new(1, -32, 0, 36))
accNote.TextWrapped = true
accNote.TextYAlignment = Enum.TextYAlignment.Top

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

-- drag dari area atas (judul)
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

local hopping, stopRequested = false, false

closeBtn.MouseButton1Click:Connect(function()
        stopRequested = true
        gui:Destroy()
end)

local function setStatus(text, color)
        statusLabel.Text = text
        statusLabel.TextColor3 = color or WHITE
end

-- jumlah pemain di server saat ini (live), karakter kita tidak dihitung
task.spawn(function()
        while gui.Parent do
                playersLabel.Text = ("%d / %d"):format(math.max(0, #Players:GetPlayers() - 1), Players.MaxPlayers)
                task.wait(1)
        end
end)

-- ─── LOGIKA HOP SERVER (dari Sena V4: Find Private Server) ─────────────────
local function privateMax()
        return math.max(1, math.floor(tonumber(PRIVATE_MAX) or 1))
end

-- HttpGet dan request executor dijalankan bersamaan; yang duluan berhasil dipakai.
-- Ada batas waktu supaya tidak menggantung di "Mencari...".
local function httpGet(url, timeout)
        local result, running = nil, 2

        task.spawn(function()
                local ok, body = pcall(function() return game:HttpGet(url) end)
                if ok and type(body) == "string" and body ~= "" and not result then
                        result = body
                end
                running = running - 1
        end)

        task.spawn(function()
                local ok, res = pcall(function()
                        local fn = (syn and syn.request) or http_request or request
                        if fn then
                                return fn({ Url = url, Method = "GET" })
                        end
                        return nil
                end)
                if ok and type(res) == "table" and res.Body and res.Body ~= ""
                        and (res.StatusCode == nil or res.StatusCode == 200) and not result then
                        result = res.Body
                end
                running = running - 1
        end)

        local t0 = os.clock()
        while not result and running > 0 and os.clock() - t0 < timeout do
                task.wait(0.1)
        end
        return result
end

-- deteksi teleport gagal (hanya untuk LocalPlayer)
local hopFailed = false
pcall(function()
        TeleportService.TeleportInitFailed:Connect(function(plr)
                if plr == player then
                        hopFailed = true
                end
        end)
end)

-- Sena: collectServers (dengan timeout + ulang per halaman)
local function collectServers(maxFilter)
        local list = {}
        local cursor = ""

        for page = 1, PAGES do
                if stopRequested or not gui.Parent then break end
                setStatus(("Mencari... (%d/%d)"):format(page, PAGES), ACCENT_HI)

                local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100&excludeFullGames=true"):format(game.PlaceId)
                if cursor ~= "" then
                        url = url .. "&cursor=" .. cursor
                end

                local result
                for attempt = 1, HTTP_ATTEMPTS do
                        local body = httpGet(url, HTTP_TIMEOUT)
                        if body then
                                local ok, decoded = pcall(function() return HttpService:JSONDecode(body) end)
                                if ok and type(decoded) == "table" and type(decoded.data) == "table" then
                                        result = decoded
                                        break
                                end
                        end
                        if attempt < HTTP_ATTEMPTS then
                                task.wait(2)
                        end
                end

                if not result then break end

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
                if stopRequested or not gui.Parent then return false end

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
-- Tanpa pengecekan "server saat ini sudah sepi": tetap pindah ke server sepi lain
-- (server sekarang sudah dikecualikan lewat game.JobId di collectServers).
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
                for _, s in ipairs(all) do
                        if s.playing == lowest then
                                good[#good + 1] = s
                        end
                end
        end

        -- acak, ambil maksimal 5 target
        local targets = {}
        local picked = {}
        while #good > 0 and #targets < 5 do
                local s = table.remove(good, math.random(1, #good))
                targets[#targets + 1] = s
                picked[s.id] = true
        end

        -- cadangan: kalau kurang dari 5, isi dengan server tersepi berikutnya
        for _, s in ipairs(all) do
                if #targets >= 5 then break end
                if not picked[s.id] then
                        targets[#targets + 1] = s
                        picked[s.id] = true
                end
        end

        return targets
end

-- Sena: hopPrivateOnce -> mengembalikan (berhasil_teleport, alasan)
local function hopPrivateOnce()
        setStatus("Mencari... (1/" .. PAGES .. ")", ACCENT_HI)
        local targets = findPrivateTargets()

        if stopRequested or not gui.Parent then
                return false, "stopped"
        end
        if not targets then
                setStatus("Gagal memuat daftar server", ERR_RED)
                return false, "nolist"
        end
        if #targets == 0 then
                setStatus("Tidak ada server lain", ERR_RED)
                return false, "noserver"
        end

        if hopToList(targets) then
                setStatus("Pindah server...", OK_GREEN)
                return true, "teleporting"
        end

        if stopRequested or not gui.Parent then
                return false, "stopped"
        end
        setStatus("Teleport gagal, coba lagi", ERR_RED)
        return false, "failed"
end

-- satu tombol: jalankan hopPrivateOnce; kalau AUTO_RETRY, ulangi seperti Auto Hop Sena
local function hop()
        if hopping then
                stopRequested = true
                setStatus("Menghentikan...", SUB_TEXT)
                return
        end
        hopping, stopRequested = true, false
        hopBtn.Text = AUTO_RETRY and "BERHENTI" or "MENCARI..."

        while gui.Parent do
                local okCall, done, reason = pcall(hopPrivateOnce)
                if not okCall then
                        warn("[" .. TITLE .. "] Hop error:", done)
                        setStatus("Error, coba lagi", ERR_RED)
                elseif reason == "stopped" then
                        break
                elseif done then
                        -- teleport berjalan. Kalau ternyata gagal belakangan, coba lagi.
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
