--[[ =============================================================================
  leon4951hub  -  script.lua   (LocalScript / StarterPlayerScripts)
  Visual-only: item, avatar, dan animasi yang dipilih langsung dipasang di
  karakter kamu.

  VERSI FULL (OPTIMAL v7): antrian render, katalog instan, tab ramping, bug UI fix.
    Tab: avatar | karakter | animasi | sepatu | favorit | dipakai
  UPDATE v7:
   - Kamera cermin sejajar tinggi kepala avatar. Tab karakter: bundle bagian tubuh dipasang kilat (tukar mesh + prefetch).
  UPDATE v6:
   - Cowo / Cewe jauh lebih cepat: gender dihitung di latar belakang untuk semua avatar (batch paralel).
   - Pencarian lebih cepat: 3 backend diadu bersamaan, hasil persis paralel, hasil teratas di-prefetch.
   - Kamera cermin menyesuaikan ukuran avatar (kecil / tinggi) dan ukuran panel.
  UPDATE v5:
   - CONFIG avatar: daftar avatar di tab avatar disimpan ke file (leon4951hub_avatars.json).
     Saat masuk lagi langsung muncul 100+ kartu sebelumnya lalu lanjut memuat. (butuh writefile/readfile)
   - Avatar yang diklik secepat mungkin terpasang: model donor 8 avatar teratas yang terlihat disiapkan
     lebih dulu (prefetch + cache), klik cepat berturut-turut diantre. Waktu pasang tampil di kartu & toast.
   - Tab DIPAKAI jauh lebih cepat: nama item diambil sekaligus (batch paralel), baris dipakai ulang.
  UPDATE v4 (SUPER CEPAT): 130 kartu avatar langsung muncul, jalur pasang cepat, cache + prefetch,
   bar loading, tab FAVORIT (tombol hati di kartu avatar & item, tersimpan ke file kalau ada writefile).
  UPDATE v2/v3: filter bacon / bacon cewe ketat, filter Cowo / Cewe sistem skor, kandidat dari teman/server.
  Tekan K untuk buka/tutup UI.
============================================================================= ]]

----------------------------------------------------------------------------
-- [1] SERVICES
----------------------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local AvatarEditorService = game:GetService("AvatarEditorService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("leon4951hub")
if old then
	old:Destroy()
end

local GEN = (tonumber(playerGui:GetAttribute("leon_gen")) or 0) + 1
playerGui:SetAttribute("leon_gen", GEN)
local function stale()
	return playerGui:GetAttribute("leon_gen") ~= GEN
end

local REMOTE_NAME = "AvatarStudioApply"
local PAGE_SIZE = 120
local MAX_ITEMS = 1000
local TOGGLE_KEY = Enum.KeyCode.K

----------------------------------------------------------------------------
-- [2] TABEL TIPE ITEM
----------------------------------------------------------------------------
local CLASSIC = {
	[11] = "Shirt", [12] = "Pants", [2] = "GraphicTShirt", [18] = "Face",
	[17] = "Head", [27] = "Torso", [28] = "RightArm", [29] = "LeftArm",
	[30] = "LeftLeg", [31] = "RightLeg",
	[48] = "ClimbAnimation", [50] = "FallAnimation", [51] = "IdleAnimation",
	[52] = "JumpAnimation", [53] = "RunAnimation", [54] = "SwimAnimation",
	[55] = "WalkAnimation", [78] = "MoodAnimation",
}

local ACC = {
	[8] = { "Hat", false }, [41] = { "Hair", false }, [42] = { "Face", false },
	[43] = { "Neck", false }, [44] = { "Shoulder", false }, [45] = { "Front", false },
	[46] = { "Back", false }, [47] = { "Waist", false },
	[64] = { "TShirt", true }, [65] = { "Shirt", true }, [66] = { "Pants", true },
	[67] = { "Jacket", true }, [68] = { "Sweater", true }, [69] = { "Shorts", true },
	[70] = { "LeftShoe", true }, [71] = { "RightShoe", true }, [72] = { "DressSkirt", true },
	[76] = { "Eyebrow", false }, [77] = { "Eyelash", false },
}

local ANIM_SLOT = {
	[51] = { "idle", { "Animation1", "Animation2" } },
	[55] = { "walk", { "WalkAnim" } },
	[53] = { "run", { "RunAnim" } },
	[52] = { "jump", { "JumpAnim" } },
	[50] = { "fall", { "FallAnim" } },
	[48] = { "climb", { "ClimbAnim" } },
	[54] = { "swim", { "Swim" } },
}

local NAME2TID = {
	Hat = 8, HairAccessory = 41, FaceAccessory = 42, NeckAccessory = 43, ShoulderAccessory = 44,
	FrontAccessory = 45, BackAccessory = 46, WaistAccessory = 47, TShirtAccessory = 64, ShirtAccessory = 65,
	PantsAccessory = 66, JacketAccessory = 67, SweaterAccessory = 68, ShortsAccessory = 69,
	LeftShoeAccessory = 70, RightShoeAccessory = 71, DressSkirtAccessory = 72, EyebrowAccessory = 76,
	EyelashAccessory = 77, Shirt = 11, Pants = 12, TShirt = 2, Face = 18, Head = 17, Torso = 27,
	RightArm = 28, LeftArm = 29, LeftLeg = 30, RightLeg = 31, ClimbAnimation = 48, FallAnimation = 50,
	IdleAnimation = 51, JumpAnimation = 52, RunAnimation = 53, SwimAnimation = 54, WalkAnimation = 55,
	MoodAnimation = 78,
}

local SERIAL_PROPS = {
	"Shirt", "Pants", "GraphicTShirt", "Face", "Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg",
	"ClimbAnimation", "FallAnimation", "IdleAnimation", "JumpAnimation", "RunAnimation", "SwimAnimation",
	"WalkAnimation", "MoodAnimation",
	"HeadColor", "TorsoColor", "LeftArmColor", "RightArmColor", "LeftLegColor", "RightLegColor",
	"HeightScale", "WidthScale", "DepthScale", "HeadScale", "ProportionScale", "BodyTypeScale",
}

local SCALE_VALUES = {
	Height = "BodyHeightScale", Width = "BodyWidthScale", Depth = "BodyDepthScale",
	Head = "HeadScale", Proportion = "BodyProportionScale", BodyType = "BodyTypeScale",
}
local SCALE_DESC = {
	Height = "HeightScale", Width = "WidthScale", Depth = "DepthScale",
	Head = "HeadScale", Proportion = "ProportionScale", BodyType = "BodyTypeScale",
}
local SKIN_NAME = "AS_Skin"
local LIMBS = { "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm",
	"RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot", "Torso",
	"Left Arm", "Right Arm", "Left Leg", "Right Leg" }
local function isBodyPart(name)
	if name == "Head" then
		return true
	end
	for _, n in ipairs(LIMBS) do
		if n == name then
			return true
		end
	end
	return false
end
local BODY_COLOR_PROPS = {
	"HeadColor3", "TorsoColor3", "LeftArmColor3", "RightArmColor3", "LeftLegColor3", "RightLegColor3",
}

----------------------------------------------------------------------------
-- [3] TEMA + HELPER UI
----------------------------------------------------------------------------
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local T = {
	Bg = rgb(13, 14, 21), Surface = rgb(21, 23, 33), Surface2 = rgb(31, 34, 49),
	Hover = rgb(42, 46, 66), Stroke = rgb(46, 50, 70), Text = rgb(240, 242, 250),
	Dim = rgb(146, 152, 178), Accent = rgb(108, 118, 255), Ok = rgb(72, 199, 142),
	Danger = rgb(238, 84, 100), Warn = rgb(245, 184, 68),
}

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
	for _, c in ipairs(kids or {}) do
		c.Parent = o
	end
	if parent then
		o.Parent = parent
	end
	return o
end

local function tween(o, props, t, style)
	local tw = TweenService:Create(o, TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quint), props)
	tw:Play()
	return tw
end

local function corner(o, r)
	return mk("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = o })
end

local function stroke(o, color, th, tr)
	return mk("UIStroke", {
		Color = color or T.Stroke, Thickness = th or 1, Transparency = tr or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = o,
	})
end

local function pad(o, l, t, r, b)
	return mk("UIPadding", {
		PaddingLeft = UDim.new(0, l or 0), PaddingTop = UDim.new(0, t or l or 0),
		PaddingRight = UDim.new(0, r or l or 0), PaddingBottom = UDim.new(0, b or t or l or 0),
		Parent = o,
	})
end

local function vlist(o, gap)
	return mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, gap or 0), Parent = o,
	})
end

local function label(parent, text, size, color, font, xalign)
	return mk("TextLabel", {
		BackgroundTransparency = 1, Text = text or "", TextSize = size or 14, TextColor3 = color or T.Text,
		Font = font or Enum.Font.GothamMedium, TextXAlignment = xalign or Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, (size or 14) + 6), Parent = parent,
	})
end

local function button(parent, o)
	local bg = o.bg or T.Surface2
	local b = mk("TextButton", {
		AutoButtonColor = false, Text = o.text or "", TextSize = o.textSize or 14, Font = Enum.Font.GothamBold,
		TextColor3 = o.color or T.Text, BackgroundColor3 = bg, BorderSizePixel = 0,
		Size = o.size or UDim2.new(1, 0, 0, 36), Position = o.position or UDim2.new(),
		AnchorPoint = o.anchor or Vector2.zero, LayoutOrder = o.order or 0, Parent = parent,
	})
	corner(b, o.radius or 10)
	b:SetAttribute("Base", bg)
	b.MouseEnter:Connect(function()
		local base = b:GetAttribute("Base") or bg
		tween(b, { BackgroundColor3 = base:Lerp(Color3.new(1, 1, 1), 0.12) }, 0.12)
	end)
	b.MouseLeave:Connect(function()
		tween(b, { BackgroundColor3 = b:GetAttribute("Base") or bg }, 0.15)
	end)
	if o.onClick then
		b.Activated:Connect(o.onClick)
	end
	return b
end

local function makeScroll(parent, size, position)
	return mk("ScrollingFrame", {
		Size = size or UDim2.new(1, 0, 1, 0), Position = position or UDim2.new(), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = T.Dim,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y, Parent = parent,
	})
end

local function thumbURL(kind, id, size)
	size = size or 150
	return "rbxthumb://type=" .. kind .. "&id=" .. string.format("%.0f", id) .. "&w=" .. size .. "&h=" .. size
end

local function commas(n)
	local s = tostring(math.floor(n))
	local r = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (r:gsub("^,", ""))
end

local function priceText(p)
	if p == false then
		return "…"
	elseif p == nil then
		return "Tidak dijual"
	elseif p == 0 then
		return "Gratis"
	end
	return "R$ " .. commas(p)
end

local function safeEnum(enumType, name)
	local ok, v = pcall(function()
		return enumType[name]
	end)
	if ok then
		return v
	end
	return nil
end

local function getProp(desc, key)
	local ok, v = pcall(function()
		return desc[key]
	end)
	if ok then
		return v
	end
	return nil
end

local function setProp(desc, key, value)
	pcall(function()
		desc[key] = value
	end)
end

----------------------------------------------------------------------------
-- [3b] KOMPATIBILITAS API  (Roblox v702, Des 2025: banyak fungsi diganti *Async)
----------------------------------------------------------------------------
local function callAny(obj, names, ...)
	local lastErr = "metode tidak ditemukan"
	local args = table.pack(...)
	for _, name in ipairs(names) do
		local okF, f = pcall(function()
			return obj[name]
		end)
		if okF and type(f) == "function" then
			local ok, res = pcall(function()
				return f(obj, table.unpack(args, 1, args.n))
			end)
			if ok then
				return true, res, name
			end
			lastErr = name .. ": " .. tostring(res)
		else
			lastErr = name .. " tidak ada"
		end
	end
	return false, lastErr
end

local function hasMember(obj, name)
	local ok, v = pcall(function()
		return obj[name]
	end)
	return ok and type(v) == "function"
end

local function productInfo(id, infoType)
	local ok, res = callAny(MarketplaceService, { "GetProductInfoAsync", "GetProductInfo" }, id, infoType)
	if ok then
		return res
	end
	return nil
end

local function descFromUser(uid)
	local ok, res = callAny(Players, { "GetHumanoidDescriptionFromUserIdAsync", "GetHumanoidDescriptionFromUserId" }, uid)
	if ok and res then
		return res
	end
	return nil, res
end

local function descFromOutfit(id)
	local ok, res = callAny(Players, { "GetHumanoidDescriptionFromOutfitIdAsync", "GetHumanoidDescriptionFromOutfitId" }, id)
	if ok and res then
		return res
	end
	return nil
end

local function batchDetails(ids, itemType)
	return callAny(AvatarEditorService, { "GetBatchItemDetailsAsync", "GetBatchItemDetails" }, ids, itemType)
end

local function appliedDesc(hum)
	local ok, d = callAny(hum, { "GetAppliedDescriptionAsync", "GetAppliedDescription" })
	if ok and d then
		return d
	end
	local d2 = descFromUser(player.UserId)
	if d2 then
		return d2
	end
	return Instance.new("HumanoidDescription")
end

local function urlenc(str)
	return (tostring(str):gsub("[^%w%-_%.~]", function(c)
		return string.format("%%%02X", string.byte(c))
	end))
end

-- ambil URL lewat: game:HttpGet (executor) -> request/http_request -> HttpService
local function httpGet(url)
	local why = {}
	local okG, body = pcall(function()
		return game:HttpGet(url)
	end)
	if okG and type(body) == "string" and #body > 0 then
		return body
	end
	table.insert(why, "HttpGet: " .. tostring(okG and "kosong" or body))
	local req = (syn and syn.request) or request or http_request or (http and http.request) or (fluxus and fluxus.request)
	if req then
		local okR, res = pcall(function()
			return req({ Url = url, Method = "GET" })
		end)
		if okR and type(res) == "table" and res.Body and (res.Success or res.StatusCode == 200) then
			return res.Body
		end
		table.insert(why, "request: " .. tostring(okR and ("status " .. tostring(res and res.StatusCode)) or res))
	else
		table.insert(why, "request: tidak ada")
	end
	local okH, b2 = pcall(function()
		return HttpService:GetAsync(url)
	end)
	if okH and type(b2) == "string" then
		return b2
	end
	table.insert(why, "HttpService: " .. tostring(b2))
	return nil, table.concat(why, " | ")
end

----------------------------------------------------------------------------
-- [4] TOAST
----------------------------------------------------------------------------
local LOG = {}
local logHook = nil

local function logf(fmt, ...)
	local line
	if select("#", ...) > 0 then
		local ok, r = pcall(string.format, fmt, ...)
		line = ok and r or tostring(fmt)
	else
		line = tostring(fmt)
	end
	line = os.date("%H:%M:%S") .. "  " .. line
	table.insert(LOG, line)
	while #LOG > 500 do
		table.remove(LOG, 1)
	end
	print("[leon4951hub] " .. line)
	if logHook then
		pcall(logHook)
	end
end

local toastHolder

local function toast(text, kind)
	logf("%s", tostring(text))
	if not toastHolder then
		return
	end
	local col = ({ danger = T.Danger, warn = T.Warn, ok = T.Ok })[kind or ""] or T.Accent
	local f = mk("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.Surface2,
		BackgroundTransparency = 1, TextColor3 = T.Text, TextTransparency = 1, Font = Enum.Font.GothamMedium,
		TextSize = 14, TextWrapped = true, Text = tostring(text), Parent = toastHolder,
	})
	corner(f, 10)
	pad(f, 14, 9, 14, 9)
	local st = stroke(f, col, 2, 1)
	tween(f, { BackgroundTransparency = 0, TextTransparency = 0 }, 0.2)
	tween(st, { Transparency = 0 }, 0.2)
	task.delay((kind == "danger" or kind == "warn") and 7 or 3, function()
		if f.Parent then
			tween(f, { BackgroundTransparency = 1, TextTransparency = 1 }, 0.3)
			tween(st, { Transparency = 1 }, 0.3)
			task.wait(0.35)
			f:Destroy()
		end
	end)
end

----------------------------------------------------------------------------
-- [5] ENGINE AVATAR  (inti: membuat item benar-benar muncul di karakter)
----------------------------------------------------------------------------
local E = {
	look = nil,
	original = nil,
	failed = {},
	types = {}, names = {},
	history = {}, redo = {},
	busy = false, remote = nil, lastMethod = "", injectFirst = false, cap = {}, useSkin = true, skinMode = "puppet", directIds = {},
	scales = {}, skin = nil, origColors = nil,
	listeners = {},
	bundleCache = {}, loadingBundles = 0, pendingClicks = 0,
	preCache = {}, preOrder = {}, preJobs = {},
}

function E.onChanged(fn)
	table.insert(E.listeners, fn)
end

local function fire()
	for _, fn in ipairs(E.listeners) do
		task.spawn(fn)
	end
end

function E.humanoid()
	local char = player.Character or player.CharacterAdded:Wait()
	return char:WaitForChild("Humanoid"), char
end

function E.assetType(id)
	if E.types[id] then
		return E.types[id]
	end
	local info = productInfo(id, Enum.InfoType.Asset)
	if info then
		E.types[id] = info.AssetTypeId
		E.names[id] = E.names[id] or info.Name
		return info.AssetTypeId
	end
	return nil
end

function E.name(id)
	if not E.names[id] then
		E.assetType(id)
	end
	return E.names[id] or ("Item #" .. id)
end

local function needReady()
	if E.look and E.original then
		return true
	end
	toast("Karakter masih disiapkan, coba lagi sebentar...", "warn")
	return false
end

local function collect(desc)
	local set, list = {}, {}
	if not desc then
		return set, list
	end
	local ok, accs = pcall(function()
		return desc:GetAccessories(true)
	end)
	if ok then
		for _, a in ipairs(accs) do
			set[a.AssetId] = true
			table.insert(list, { Id = a.AssetId, Label = a.AccessoryType.Name .. (a.IsLayered and " (layered)" or "") })
		end
	end
	for _, prop in pairs(CLASSIC) do
		local v = getProp(desc, prop)
		if type(v) == "number" and v > 0 and not set[v] then
			set[v] = true
			table.insert(list, { Id = v, Label = prop })
		end
	end
	table.sort(list, function(a, b)
		return a.Id < b.Id
	end)
	return set, list
end

function E.isWorn(id)
	local set = collect(E.look)
	return set[id] == true
end

function E.wornList()
	local _, list = collect(E.look)
	return list
end

local function removeFromDesc(desc, id)
	local out = {}
	for _, a in ipairs(desc:GetAccessories(true)) do
		if a.AssetId ~= id then
			table.insert(out, a)
		end
	end
	desc:SetAccessories(out, true)
	for _, prop in pairs(CLASSIC) do
		if getProp(desc, prop) == id then
			setProp(desc, prop, 0)
		end
	end
end

local function addToDesc(desc, id, tid)
	local acc = ACC[tid]
	if acc then
		local typeName, layered = acc[1], acc[2]
		local enumVal = safeEnum(Enum.AccessoryType, typeName)
		if not enumVal then
			return false
		end
		local out, order = {}, 1
		for _, a in ipairs(desc:GetAccessories(true)) do
			local drop = a.AssetId == id
			if (layered or typeName == "Eyebrow" or typeName == "Eyelash") and a.AccessoryType == enumVal then
				drop = true
			end
			if not drop then
				table.insert(out, a)
				if a.Order and a.Order >= order then
					order = a.Order + 1
				end
			end
		end
		table.insert(out, { AssetId = id, AccessoryType = enumVal, IsLayered = layered, Order = order })
		desc:SetAccessories(out, true)
		return true
	end
	local prop = CLASSIC[tid]
	if prop then
		setProp(desc, prop, id)
		return true
	end
	return false
end

local function mergeDescription(base, other)
	for _, prop in pairs(CLASSIC) do
		local v = getProp(other, prop)
		if type(v) == "number" and v > 0 then
			setProp(base, prop, v)
		end
	end
	local okO, otherAccs = pcall(function()
		return other:GetAccessories(true)
	end)
	if not okO then
		return
	end
	local baseAccs = base:GetAccessories(true)
	for _, oa in ipairs(otherAccs) do
		local out = {}
		for _, ba in ipairs(baseAccs) do
			local sameSlot = oa.IsLayered and ba.IsLayered and ba.AccessoryType == oa.AccessoryType
			if ba.AssetId ~= oa.AssetId and not sameSlot then
				table.insert(out, ba)
			end
		end
		table.insert(out, oa)
		baseAccs = out
	end
	base:SetAccessories(baseAccs, true)
end

local function serialize(desc)
	local t = { props = {}, accs = {} }
	for _, k in ipairs(SERIAL_PROPS) do
		local v = getProp(desc, k)
		if v ~= nil then
			t.props[k] = v
		end
	end
	local ok, list = pcall(function()
		return desc:GetAccessories(true)
	end)
	if ok then
		for _, a in ipairs(list) do
			table.insert(t.accs, {
				AssetId = a.AssetId, AccessoryType = a.AccessoryType.Name,
				IsLayered = a.IsLayered, Order = a.Order or 1,
			})
		end
	end
	return t
end

function E.withoutFailed(desc)
	local d = desc:Clone()
	for id in pairs(E.failed) do
		removeFromDesc(d, id)
	end
	return d
end

------------------------------------------------------------------------
-- INJECTOR (jalur cadangan): muat aset lalu pasang langsung ke karakter
------------------------------------------------------------------------
local function buildDonor(desc)
	local hum = E.humanoid()
	local rig = (hum.RigType == Enum.HumanoidRigType.R6) and Enum.HumanoidRigType.R6 or Enum.HumanoidRigType.R15
	local ok, m = callAny(Players, { "CreateHumanoidModelFromDescriptionAsync", "CreateHumanoidModelFromDescription" }, desc, rig)
	if ok and m then
		return m
	end
	logf("donor rig gagal: %s", tostring(m))
	return nil
end

-- kalau model donor untuk desc ini sudah disiapkan lebih awal (prefetch), pakai langsung
local function donorModel(desc)
	for i, uid in ipairs(E.preOrder) do
		local rec = E.preCache[uid]
		if rec and rec.desc == desc then
			table.remove(E.preOrder, i)
			E.preCache[uid] = nil
			return rec.model
		end
	end
	return buildDonor(desc)
end

local function loadAsset(id, tid)
	if E.cap.getObjects ~= false then
		local ok, objs = pcall(function()
			return game:GetObjects("rbxassetid://" .. tostring(id))
		end)
		if ok and type(objs) == "table" and #objs > 0 then
			return objs, "GetObjects"
		end
		logf("GetObjects gagal untuk %s: %s", tostring(id), ok and "hasil kosong" or tostring(objs))
	end
	if E.cap.insert ~= false then
		local ok2, model = pcall(function()
			return InsertService:LoadAsset(id)
		end)
		if ok2 and model then
			return { model }, "LoadAsset"
		end
		logf("LoadAsset gagal untuk %s: %s", tostring(id), ok2 and "kosong" or tostring(model))
	end
	if E.cap.donor ~= false and tid then
		local d = Instance.new("HumanoidDescription")
		if addToDesc(d, id, tid) then
			local m = donorModel(d)
			if m then
				return { m }, "donor"
			end
		end
	end
	return nil
end

local function findIn(objs, class)
	for _, o in ipairs(objs) do
		if o:IsA(class) then
			return o
		end
		local d = o:FindFirstChildWhichIsA(class, true)
		if d then
			return d
		end
	end
	return nil
end

local function restartAnimate(char, hum)
	local animate = char:FindFirstChild("Animate")
	if not animate then
		return
	end
	pcall(function()
		animate.Disabled = true
		local animator = hum:FindFirstChildOfClass("Animator")
		if animator then
			for _, tr in ipairs(animator:GetPlayingAnimationTracks()) do
				tr:Stop(0)
			end
		end
		task.wait()
		animate.Disabled = false
	end)
end

local function findBodyAttachment(char, name)
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("Attachment") and d.Name == name and d.Parent and d.Parent:IsA("BasePart") then
			return d
		end
	end
	return nil
end

local function attachAccessory(acc, char)
	local handle = acc:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		acc.Parent = char
		return false, "Accessory tidak punya Handle"
	end
	for _, w in ipairs(handle:GetChildren()) do
		if w.Name == "AccessoryWeld" then
			w:Destroy()
		end
	end
	handle.Anchored = false
	handle.CanCollide = false
	handle.Massless = true
	local part1, c0, c1
	for _, att in ipairs(handle:GetChildren()) do
		if att:IsA("Attachment") then
			local target = findBodyAttachment(char, att.Name)
			if target then
				part1, c0, c1 = target.Parent, att.CFrame, target.CFrame
				break
			end
		end
	end
	local how = "attachment"
	if not part1 then
		how = "cadangan"
		local layered = acc:FindFirstChildWhichIsA("WrapLayer", true) ~= nil
		if layered then
			part1 = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
			c0, c1 = CFrame.new(), CFrame.new()
		else
			part1 = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
			if part1 then
				c0, c1 = CFrame.new(), CFrame.new(0, part1.Size.Y / 2, 0)
			end
		end
		if not part1 then
			acc.Parent = char
			return false, "tidak ada bagian tubuh untuk dilas"
		end
	end
	local w = Instance.new("Weld")
	w.Name = "AccessoryWeld"
	w.Part0 = handle
	w.Part1 = part1
	w.C0 = c0
	w.C1 = c1
	handle.CFrame = part1.CFrame * c1 * c0:Inverse()
	acc.Parent = char
	w.Parent = handle
	return true, how
end

local function harvestAccessory(donorAcc, char)
	local c = donorAcc:Clone()
	c:SetAttribute("ASU", true)
	local dh, ch = donorAcc:FindFirstChild("Handle"), c:FindFirstChild("Handle")
	local wired = false
	if dh and ch then
		local dw = dh:FindFirstChild("AccessoryWeld") or dh:FindFirstChildWhichIsA("Weld")
		local cw = ch:FindFirstChild("AccessoryWeld") or ch:FindFirstChildWhichIsA("Weld")
		if dw and cw and dw.Part1 then
			local tgt = char:FindFirstChild(dw.Part1.Name) or char:FindFirstChild(dw.Part1.Name, true)
			if tgt and tgt:IsA("BasePart") then
				cw.Part0 = ch
				cw.Part1 = tgt
				wired = true
			end
		end
	end
	if wired then
		c.Parent = char
	else
		local ok, how = attachAccessory(c, char)
		if not ok then
			logf("las aksesori gagal: %s", tostring(how))
		end
	end
	return c
end

local function copyBodyParts(model, char)
	for _, dp in ipairs(model:GetChildren()) do
		if dp:IsA("MeshPart") and dp.Name ~= "HumanoidRootPart" then
			local cp = char:FindFirstChild(dp.Name)
			if cp and cp:IsA("MeshPart") then
				pcall(function()
					if dp.MeshId ~= "" and cp.MeshId ~= dp.MeshId then
						cp.MeshId = dp.MeshId
					end
					cp.TextureID = dp.TextureID
				end)
				pcall(function()
					for _, x in ipairs(cp:GetChildren()) do
						if x:IsA("SurfaceAppearance") then
							x:Destroy()
						end
					end
					local sa = dp:FindFirstChildOfClass("SurfaceAppearance")
					if sa then
						sa:Clone().Parent = cp
					end
				end)
			end
		end
	end
end

local function pickAnim(anims, name, i)
	local lname = string.lower(name)
	for _, a in ipairs(anims) do
		if string.lower(a.Name) == lname then
			return a
		end
	end
	return anims[i] or anims[1]
end

local function injectCore(id, tid, objs, kind)
	local hum, char = E.humanoid()
	local tag = "AS_" .. tostring(id)

	if ACC[tid] then
		local acc = findIn(objs, "Accessory")
		if not acc then
			E.lastInjectErr = "aset bukan Accessory"
			return false
		end
		local c
		if kind == "donor" then
			c = harvestAccessory(acc, char)
			c:SetAttribute("ASU", nil)
		else
			c = acc:Clone()
			local okA, how = attachAccessory(c, char)
			if not okA then
				E.lastInjectErr = tostring(how)
			end
		end
		c.Name = tag
		c:SetAttribute("AS", id)
		return c.Parent == char
	elseif tid == 11 or tid == 12 or tid == 2 then
		local class = (tid == 11 and "Shirt") or (tid == 12 and "Pants") or "ShirtGraphic"
		local inst = findIn(objs, class)
		if not inst then
			return false
		end
		for _, ch in ipairs(char:GetChildren()) do
			if ch:IsA(class) then
				ch:Destroy()
			end
		end
		local c = inst:Clone()
		c.Name = tag
		c:SetAttribute("AS", id)
		c.Parent = char
		return true
	elseif tid == 18 then
		local decal = findIn(objs, "Decal")
		local head = char:FindFirstChild("Head")
		if not decal or not head then
			return false
		end
		local face = head:FindFirstChild("face") or head:FindFirstChildOfClass("Decal")
		if not face then
			face = Instance.new("Decal")
			face.Name = "face"
			face.Parent = head
		end
		face.Texture = decal.Texture
		char:SetAttribute("ASX_" .. tostring(id), true)
		return true
	elseif ANIM_SLOT[tid] then
		local animate = char:FindFirstChild("Animate")
		if not animate then
			return false
		end
		local slot = ANIM_SLOT[tid]
		local folder = animate:FindFirstChild(slot[1])
		if not folder then
			E.lastInjectErr = "karakter tidak punya folder animasi '" .. slot[1] .. "'"
			return false
		end
		if kind == "donor" then
			local dan = objs[1]:FindFirstChild("Animate")
			local df = dan and dan:FindFirstChild(slot[1])
			if not df then
				E.lastInjectErr = "donor rig tanpa Animate"
				return false
			end
			E.animState = E.animState or {}
			local rec2 = {}
			for _, name in ipairs(slot[2]) do
				local src, target = df:FindFirstChild(name), folder:FindFirstChild(name)
				if src and target and src:IsA("Animation") then
					target.AnimationId = src.AnimationId
					table.insert(rec2, { target, src.AnimationId })
				end
			end
			if #rec2 == 0 then
				E.lastInjectErr = "slot animasi kosong"
				return false
			end
			E.animState[id] = rec2
			restartAnimate(char, hum)
			char:SetAttribute("ASX_" .. tostring(id), true)
			return true
		end
		local anims = {}
		for _, o in ipairs(objs) do
			if o:IsA("Animation") then
				table.insert(anims, o)
			end
			for _, d in ipairs(o:GetDescendants()) do
				if d:IsA("Animation") then
					table.insert(anims, d)
				end
			end
		end
		if #anims == 0 then
			return false
		end
		E.animState = E.animState or {}
		local rec = {}
		for i, name in ipairs(slot[2]) do
			local target = folder:FindFirstChild(name)
			local src = pickAnim(anims, name, i)
			if target and src then
				target.AnimationId = src.AnimationId
				table.insert(rec, { target, src.AnimationId })
			end
		end
		E.animState[id] = rec
		restartAnimate(char, hum)
		char:SetAttribute("ASX_" .. tostring(id), true)
		return true
	end
	E.lastInjectErr = "tipe item ini tidak bisa dipasang lewat injector (bodypart hanya native/server)"
	return false
end

function E.inject(id, tid)
	E.lastInjectErr = nil
	local objs, kind = loadAsset(id, tid)
	if not objs then
		E.lastInjectErr = "semua pemuat gagal (GetObjects, LoadAsset, donor rig)"
		logf("inject %s gagal: %s", tostring(id), E.lastInjectErr)
		return false
	end
	local ok, res = pcall(injectCore, id, tid, objs, kind)
	if kind == "donor" then
		pcall(function()
			objs[1]:Destroy()
		end)
	end
	if not ok then
		E.lastInjectErr = tostring(res)
		res = false
	end
	if not res and not E.lastInjectErr then
		E.lastInjectErr = "aset termuat tapi bentuknya tidak sesuai / tidak menempel di karakter"
	end
	logf("inject %s (tipe %s) via %s -> %s%s", tostring(id), tostring(tid), kind, res and "BERHASIL" or "GAGAL",
		(not res and E.lastInjectErr) and (" : " .. E.lastInjectErr) or "")
	return res and true or false
end

function E.cleanInjected(char)
	for _, ch in ipairs(char:GetChildren()) do
		if ch:GetAttribute("AS") then
			ch:Destroy()
		end
	end
	for name in pairs(char:GetAttributes()) do
		if string.sub(name, 1, 4) == "ASX_" then
			char:SetAttribute(name, nil)
		end
	end
end

function E.hookChar(char)
	local pending = false
	char.ChildRemoved:Connect(function(ch)
		if ch:GetAttribute("AS") and not pending then
			pending = true
			task.delay(0.15, function()
				pending = false
				if E.injectFirst and not E.remote and not E.busy then
					pcall(E.guard)
				end
			end)
		end
	end)
end

function E.guard()
	if stale() then
		return
	end
	local char = player.Character
	if E.busy or not char or not char:FindFirstChildOfClass("Humanoid") or not E.look then
		return
	end
	local nowSet = collect(E.look)
	local present = {}
	for _, ch in ipairs(char:GetChildren()) do
		local a = ch:GetAttribute("AS")
		if a then
			present[a] = true
		end
	end
	for id in pairs(E.failed) do
		local intact = present[id] or (char:GetAttribute("ASX_" .. tostring(id)) ~= nil)
		local rec = E.animState and E.animState[id]
		if rec and char:GetAttribute("ASX_" .. tostring(id)) then
			for _, r in ipairs(rec) do
				if not r[1]:IsDescendantOf(char) or r[1].AnimationId ~= r[2] then
					intact = false
					char:SetAttribute("ASX_" .. tostring(id), nil)
					break
				end
			end
		end
		if nowSet[id] and not intact then
			local tid = E.assetType(id)
			if tid then
				E.inject(id, tid)
			end
		end
	end
	if not E.remote and E.skinActive and not char:FindFirstChild(SKIN_NAME) and os.clock() - (E.lastRenderAt or 0) > 6 then
		E.lastRenderAt = os.clock()
		task.spawn(E.rerender)
	end
	if not E.remote and (E.rendered or 0) > 0 and os.clock() - (E.lastRenderAt or 0) > 6 then
		local have = 0
		for _, ch in ipairs(char:GetChildren()) do
			if ch:IsA("Accessory") and ch:GetAttribute("ASU") then
				have = have + 1
			end
		end
		if have < E.rendered then
			E.lastRenderAt = os.clock()
			task.spawn(E.rerender)
		end
	end
end

local function countAccessories(char)
	local n = 0
	for _, ch in ipairs(char:GetChildren()) do
		if ch:IsA("Accessory") and not ch:GetAttribute("AS") then
			n = n + 1
		end
	end
	return n
end

local function waitAccessories(char, expected, timeout)
	local t0 = os.clock()
	local have = countAccessories(char)
	while have < expected and os.clock() - t0 < timeout do
		task.wait(0.2)
		have = countAccessories(char)
	end
	return have
end

------------------------------------------------------------------------
-- COMMIT: terapkan "look" baru ke karakter + verifikasi
------------------------------------------------------------------------
local function serverApply(desc)
	local okI, r = pcall(function()
		return E.remote:InvokeServer(serialize(desc))
	end)
	if okI and type(r) == "table" and r.ok then
		if r.missing then
			for _, mid in ipairs(r.missing) do
				E.failed[mid] = true
			end
		end
		return true
	end
	return false, okI and (type(r) == "table" and r.err or tostring(r)) or tostring(r)
end

local function matchAttachment(cp, dp)
	for _, da in ipairs(dp:GetChildren()) do
		if da:IsA("Attachment") and string.sub(da.Name, -13) == "RigAttachment" then
			local ca = cp:FindFirstChild(da.Name)
			if ca and ca:IsA("Attachment") then
				return ca, da
			end
		end
	end
	for _, da in ipairs(dp:GetChildren()) do
		if da:IsA("Attachment") then
			local ca = cp:FindFirstChild(da.Name)
			if ca and ca:IsA("Attachment") then
				return ca, da
			end
		end
	end
	return nil
end

function E.snapAnim(char)
	E.animOrig = {}
	local an = char:FindFirstChild("Animate")
	if not an then
		return
	end
	for _, slot in pairs(ANIM_SLOT) do
		local f = an:FindFirstChild(slot[1])
		if f then
			for _, name in ipairs(slot[2]) do
				local a = f:FindFirstChild(name)
				if a and a:IsA("Animation") then
					E.animOrig[slot[1] .. "/" .. name] = a.AnimationId
				end
			end
		end
	end
end

local function copyAnimations(model, char, hum, desc)
	local dan, can = model:FindFirstChild("Animate"), char:FindFirstChild("Animate")
	if not (dan and can) then
		return
	end
	E.animChanged = E.animChanged or {}
	local changed = false
	for tid, slot in pairs(ANIM_SLOT) do
		local prop = CLASSIC[tid]
		local v = prop and getProp(desc, prop)
		local cf = can:FindFirstChild(slot[1])
		if cf then
			if type(v) == "number" and v > 0 then
				local df = dan:FindFirstChild(slot[1])
				if df then
					local srcList = {}
					for _, a in ipairs(df:GetChildren()) do
						if a:IsA("Animation") then
							table.insert(srcList, a)
						end
					end
					for i, name in ipairs(slot[2]) do
						local b = cf:FindFirstChild(name)
						local a = df:FindFirstChild(name)
						if not (a and a:IsA("Animation")) then
							a = srcList[i] or srcList[1]
						end
						if a and b and b:IsA("Animation") then
							b.AnimationId = a.AnimationId
							changed = true
						end
					end
					E.animChanged[slot[1]] = true
				end
			elseif E.animChanged[slot[1]] then
				for _, name in ipairs(slot[2]) do
					local b = cf:FindFirstChild(name)
					local orig = E.animOrig and E.animOrig[slot[1] .. "/" .. name]
					if b and orig and b:IsA("Animation") then
						b.AnimationId = orig
						changed = true
					end
				end
				E.animChanged[slot[1]] = nil
			end
		end
	end
	if changed then
		restartAnimate(char, hum)
	end
end

function E.removeSkin()
	if E.skinConn then
		E.skinConn:Disconnect()
		E.skinConn = nil
	end
	local char = player.Character
	if char then
		local sk = char:FindFirstChild(SKIN_NAME)
		if sk then
			sk:Destroy()
		end
	end
	for part, tr in pairs(E.hidden or {}) do
		pcall(function()
			part.Transparency = tr
		end)
	end
	if char then
		for _, d in ipairs(char:GetDescendants()) do
			local ot = d:GetAttribute("AS_OT")
			if ot ~= nil then
				pcall(function()
					d.Transparency = ot
				end)
				d:SetAttribute("AS_OT", nil)
			end
		end
	end
	E.hidden = {}
	E.skinActive = false
end

function E.renderSkinWeld(desc)
	local hum, char = E.humanoid()
	local model = donorModel(desc)
	if not model then
		return false, "donor rig gagal dibuat (CreateHumanoidModelFromDescriptionAsync ditolak/diblokir)"
	end
	copyAnimations(model, char, hum, desc)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Motor6D") or d:IsA("LuaSourceContainer") then
			d:Destroy()
		end
	end
	local nAcc = 0
	for _, ch in ipairs(model:GetChildren()) do
		if ch:IsA("Accessory") then
			nAcc = nAcc + 1
		end
	end
	local dh = model:FindFirstChildOfClass("Humanoid")
	if dh then
		pcall(function()
			dh.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			dh.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
			dh.RequiresNeck = false
			dh.BreakJointsOnDeath = false
			dh.EvaluateStateMachine = false
		end)
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.Massless = true
		end
	end
	E.removeSkin()
	local welded = 0
	for _, dp in ipairs(model:GetChildren()) do
		if dp:IsA("BasePart") then
			local cp = char:FindFirstChild(dp.Name)
			if cp and cp:IsA("BasePart") then
				local c0, c1 = CFrame.new(), CFrame.new()
				local ca, da = matchAttachment(cp, dp)
				if ca then
					c0, c1 = ca.CFrame, da.CFrame
				end
				dp.CFrame = cp.CFrame * c0 * c1:Inverse()
				local w = Instance.new("Weld")
				w.Name = "AS_SkinWeld"
				w.Part0 = cp
				w.Part1 = dp
				w.C0 = c0
				w.C1 = c1
				w.Parent = dp
				welded = welded + 1
			else
				dp.Transparency = 1
			end
		end
	end
	if welded == 0 then
		model:Destroy()
		return false, "tidak ada bagian tubuh yang cocok untuk dilas (rig berbeda?)"
	end
	E.hidden = {}
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and not d:FindFirstAncestorOfClass("Tool") then
			local ot = d:GetAttribute("AS_OT")
			if ot == nil then
				ot = d.Transparency
				d:SetAttribute("AS_OT", ot)
			end
			E.hidden[d] = ot
			d.Transparency = 1
		end
	end
	model.Name = SKIN_NAME
	model.Parent = char
	E.skinActive = true
	E.skinAcc = nAcc
	E.rendered = 0
	E.lastRenderAt = os.clock()
	logf("skin overlay: %d bagian dilas, %d aksesori", welded, nAcc)
	task.delay(0.2, E.reapplyTweaks)
	return true
end

function E.attachDirect(id, host)
	if not host then
		return false
	end
	local objs
	local ok, o = pcall(function()
		return game:GetObjects("rbxassetid://" .. tostring(id))
	end)
	if ok and type(o) == "table" and #o > 0 then
		objs = o
	else
		local ok2, m = pcall(function()
			return InsertService:LoadAsset(id)
		end)
		if ok2 and m then
			objs = { m }
		end
	end
	if not objs then
		logf("muat langsung %s gagal (GetObjects & LoadAsset ditolak)", tostring(id))
		return false
	end
	local acc = findIn(objs, "Accessory")
	if not acc then
		logf("muat langsung %s: aset bukan Accessory", tostring(id))
		return false
	end
	local c = acc:Clone()
	c.Name = "AS_" .. tostring(id)
	local okA, how = attachAccessory(c, host)
	logf("muat langsung %s -> %s (%s)", tostring(id), tostring(okA), tostring(how))
	return okA
end

local function donorHas(id, tid)
	local d = Instance.new("HumanoidDescription")
	if not addToDesc(d, id, tid) then
		return false
	end
	local m = donorModel(d)
	if not m then
		return false
	end
	local has = m:FindFirstChildOfClass("Accessory") ~= nil
	pcall(function()
		m:Destroy()
	end)
	return has
end

local function directFallback(desc, added, model, nAcc)
	local expected = #desc:GetAccessories(true)
	if nAcc >= expected then
		return 0, {}
	end
	local dset = collect(desc)
	local cand = {}
	for id in pairs(E.directIds) do
		if dset[id] then
			cand[id] = true
		end
	end
	for _, id in ipairs(added or {}) do
		cand[id] = true
	end
	local n, failed = 0, {}
	for id in pairs(cand) do
		local tid = E.assetType(id)
		if tid and ACC[tid] then
			if not E.directIds[id] and donorHas(id, tid) then
				logf("aksesori %s dimuat donor sendiri", tostring(id))
			elseif E.attachDirect(id, model) then
				E.directIds[id] = true
				n = n + 1
			else
				logf("aksesori %s DITOLAK: donor membuangnya & muat langsung gagal", tostring(id))
				table.insert(failed, id)
			end
		end
	end
	return n, failed
end

function E.renderSkinPuppet(desc, added)
	local hum, char = E.humanoid()
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false, "karakter tanpa HumanoidRootPart"
	end
	local model = donorModel(desc)
	if not model then
		return false, "donor rig gagal dibuat (CreateHumanoidModelFromDescriptionAsync ditolak/diblokir)"
	end
	local dhrp = model:FindFirstChild("HumanoidRootPart")
	if not dhrp then
		model:Destroy()
		return false, "donor tanpa HumanoidRootPart"
	end
	copyAnimations(model, char, hum, desc)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("LuaSourceContainer") then
			d:Destroy()
		end
	end
	local nAcc = 0
	for _, ch in ipairs(model:GetChildren()) do
		if ch:IsA("Accessory") then
			nAcc = nAcc + 1
		end
	end
	local dh = model:FindFirstChildOfClass("Humanoid")
	if dh then
		pcall(function()
			dh.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			dh.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
			dh.BreakJointsOnDeath = false
			dh.EvaluateStateMachine = false
		end)
		pcall(function()
			dh:ChangeState(Enum.HumanoidStateType.Physics)
		end)
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.Massless = true
		end
	end
	local offY = 0
	if hum.RigType == Enum.HumanoidRigType.R15 and dh then
		local okH, v = pcall(function()
			return (dh.HipHeight + dhrp.Size.Y / 2) - (hum.HipHeight + hrp.Size.Y / 2)
		end)
		if okH and type(v) == "number" and math.abs(v) <= 6 then
			offY = v
		end
	end
	E.removeSkin()
	if not model.PrimaryPart then
		model.PrimaryPart = dhrp
	end
	model:PivotTo(hrp.CFrame * CFrame.new(0, offY, 0))
	local w = Instance.new("Weld")
	w.Name = "AS_SkinWeld"
	w.Part0 = hrp
	w.Part1 = dhrp
	w.C0 = CFrame.new(0, offY, 0)
	w.C1 = CFrame.new()
	w.Parent = dhrp
	local ours = {}
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("Motor6D") and not ours[d.Name] then
			ours[d.Name] = d
		end
	end
	local links = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Motor6D") and ours[d.Name] then
			table.insert(links, { ours[d.Name], d })
		end
	end
	if #links == 0 then
		model:Destroy()
		return false, "tidak ada sendi (Motor6D) yang cocok antara karakter dan donor"
	end
	E.hidden = {}
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and not d:FindFirstAncestorOfClass("Tool") then
			local ot = d:GetAttribute("AS_OT")
			if ot == nil then
				ot = d.Transparency
				d:SetAttribute("AS_OT", ot)
			end
			E.hidden[d] = ot
			d.Transparency = 1
		end
	end
	model.Name = SKIN_NAME
	model.Parent = char
	E.skinConn = RunService.RenderStepped:Connect(function()
		for _, l in ipairs(links) do
			l[2].Transform = l[1].Transform
		end
	end)
	E.skinActive = true
	E.skinAcc = nAcc
	E.rendered = 0
	E.lastRenderAt = os.clock()
	local direct, bad = directFallback(desc, added, model, nAcc)
	E.lastFailedIds = bad
	E.skinAcc = nAcc + direct
	logf("skin boneka: %d sendi disalin, %d aksesori dari donor, %d dimuat langsung, offset tinggi %.2f", #links, nAcc, direct, offY)
	task.delay(0.2, E.reapplyTweaks)
	return true
end

function E.skinRender(desc, added)
	E.lastFailedIds = {}
	if E.skinMode == "weld" then
		return E.renderSkinWeld(desc)
	end
	local ok, err = E.renderSkinPuppet(desc, added)
	if ok then
		return true
	end
	logf("skin boneka gagal: %s -> coba las per-bagian", tostring(err))
	return E.renderSkinWeld(desc)
end

function E.apply(desc)
	if E.useSkin and E.cap.donor ~= false then
		local ok, err = E.skinRender(desc)
		if ok then
			return true
		end
		logf("skin gagal: %s -> pakai render donor biasa", tostring(err))
	end
	E.removeSkin()
	return E.renderLook(desc)
end

function E.scheduleRerender()
	E.rrToken = (E.rrToken or 0) + 1
	local t = E.rrToken
	task.delay(0.7, function()
		if t == E.rrToken then
			E.rerender()
		end
	end)
end

function E.renderLook(desc)
	local hum, char = E.humanoid()
	local model = donorModel(desc)
	if not model then
		return false, "donor rig gagal dibuat (CreateHumanoidModelFromDescriptionAsync ditolak/diblokir)"
	end
	E.cleanInjected(char)
	for _, ch in ipairs(char:GetChildren()) do
		if ch:IsA("Accessory") or ch:IsA("Shirt") or ch:IsA("Pants") or ch:IsA("ShirtGraphic") then
			ch:Destroy()
		end
	end
	local nAcc = 0
	for _, ch in ipairs(model:GetChildren()) do
		if ch:IsA("Accessory") then
			harvestAccessory(ch, char)
			nAcc = nAcc + 1
		elseif ch:IsA("Shirt") or ch:IsA("Pants") or ch:IsA("ShirtGraphic") or ch:IsA("BodyColors") then
			if ch:IsA("BodyColors") then
				local oldBC = char:FindFirstChildOfClass("BodyColors")
				if oldBC then
					oldBC:Destroy()
				end
			end
			local c = ch:Clone()
			c.Parent = char
		end
	end
	local faceId = getProp(desc, "Face")
	local mh, head = model:FindFirstChild("Head"), char:FindFirstChild("Head")
	if mh and head and type(faceId) == "number" and faceId > 0 then
		local mf, f = mh:FindFirstChildOfClass("Decal"), head:FindFirstChildOfClass("Decal")
		if mf and f then
			f.Texture = mf.Texture
		end
	end
	copyAnimations(model, char, hum, desc)
	if E.copyBody then
		copyBodyParts(model, char)
	end
	model:Destroy()
	E.rendered = nAcc
	E.lastRenderAt = os.clock()
	logf("render donor: %d aksesori dipasang", nAcc)
	return true
end

function E.rerender()
	if E.busy or not E.look or E.remote then
		return
	end
	E.busy = true
	local ok, err = pcall(function()
		local r, e = E.apply(E.look)
		if not r then
			logf("render ulang gagal: %s", tostring(e))
		end
		E.failed = {}
	end)
	if not ok then
		logf("render ulang error: %s", tostring(err))
	end
	E.busy = false
	E.reapplyTweaks()
end

local function isInjectable(t)
	return t and (ACC[t] or t == 11 or t == 12 or t == 2 or t == 18 or ANIM_SLOT[t])
end

local FAST_CLASS = { [11] = "Shirt", [12] = "Pants", [2] = "ShirtGraphic" }

-- pasang/lepas 1-3 item langsung di boneka skin (tanpa render ulang donor)
function E.fastApply(added, removed)
	local total = #added + #removed
	if not E.skinActive or not E.useSkin or total == 0 or total > 3 then
		return false
	end
	local char = player.Character
	local skin = char and char:FindFirstChild(SKIN_NAME)
	if not skin then
		return false
	end
	local plan = {}
	for _, id in ipairs(removed) do
		local tagged
		for _, ch in ipairs(skin:GetChildren()) do
			if ch:GetAttribute("ASF") == id then
				tagged = ch
				break
			end
		end
		local tid = E.types[id]
		if tagged then
			table.insert(plan, { "del", id, tagged })
		elseif tid and FAST_CLASS[tid] then
			table.insert(plan, { "delclass", id, FAST_CLASS[tid] })
		else
			return false -- item dari render donor: pakai render penuh
		end
	end
	for _, id in ipairs(added) do
		local tid = E.types[id] or E.assetType(id)
		local acc = tid and ACC[tid]
		if acc and not acc[2] and tid ~= 76 and tid ~= 77 then
			table.insert(plan, { "acc", id, tid })
		elseif tid and FAST_CLASS[tid] then
			table.insert(plan, { "cls", id, tid })
		else
			return false -- layered / alis / bulu mata / bodypart / animasi: render penuh
		end
	end
	for _, p in ipairs(plan) do
		local kind, id = p[1], p[2]
		if kind == "del" then
			p[3]:Destroy()
		elseif kind == "delclass" then
			for _, ch in ipairs(skin:GetChildren()) do
				if ch:IsA(p[3]) then
					ch:Destroy()
				end
			end
		elseif kind == "acc" then
			if not E.attachDirect(id, skin) then
				return false
			end
			local c = skin:FindFirstChild("AS_" .. id)
			if c then
				c:SetAttribute("ASF", id)
			end
		else
			local class = FAST_CLASS[p[3]]
			local objs, how = loadAsset(id, p[3])
			if not objs then
				return false
			end
			local inst = findIn(objs, class)
			if not inst then
				if how == "donor" then
					pcall(function()
						objs[1]:Destroy()
					end)
				end
				return false
			end
			for _, ch in ipairs(skin:GetChildren()) do
				if ch:IsA(class) then
					ch:Destroy()
				end
			end
			local c = inst:Clone()
			c.Name = "AS_" .. id
			c:SetAttribute("ASF", id)
			c.Parent = skin
			if how == "donor" then
				pcall(function()
					objs[1]:Destroy()
				end)
			end
		end
	end
	return true
end

-- pastikan aksesori benar-benar ada di boneka; kalau kurang, pasang langsung
function E.ensureWorn(id)
	if E.remote or not E.skinActive then
		return true
	end
	local char = player.Character
	local skin = char and char:FindFirstChild(SKIN_NAME)
	if not skin then
		return false
	end
	local tid = E.types[id]
	if not (tid and ACC[tid]) then
		return true
	end
	local n = 0
	for _, ch in ipairs(skin:GetChildren()) do
		if ch:IsA("Accessory") then
			n = n + 1
		end
	end
	if n >= #E.look:GetAccessories(true) then
		return true
	end
	if skin:FindFirstChild("AS_" .. id) then
		return true
	end
	if E.attachDirect(id, skin) then
		local c = skin:FindFirstChild("AS_" .. id)
		if c then
			c:SetAttribute("ASF", id)
		end
		return true
	end
	return false
end

function E._commit(newLook, text, skipHist, force)
	local hum, char = E.humanoid()
	local prevSet = collect(E.look)
	local nowSet = collect(newLook)
	local added, removed = {}, {}
	for id in pairs(nowSet) do
		if not prevSet[id] then
			table.insert(added, id)
		end
	end
	for id in pairs(prevSet) do
		if not nowSet[id] then
			table.insert(removed, id)
		end
	end

	if not force and not E.remote and E.fastApply(added, removed) then
		E.lastMethod = "cepat"
		if not skipHist and E.look then
			table.insert(E.history, E.look)
			while #E.history > 40 do
				table.remove(E.history, 1)
			end
			E.redo = {}
		end
		E.look = newLook
		E.failed = {}
		task.delay(0.1, E.reapplyTweaks)
		fire()
		return true
	end

	local how
	if E.remote then
		E.cleanInjected(char)
		local ok, err = serverApply(newLook)
		if ok then
			how = "server"
			for id in pairs(E.failed) do
				if nowSet[id] then
					local tid = E.assetType(id)
					if tid then
						E.inject(id, tid)
					end
				end
			end
		else
			logf("server menolak (%s) -> jalur klien", tostring(err))
		end
	end

	if not how and E.useSkin and E.cap.donor ~= false then
		local okS, errS = E.skinRender(newLook, added)
		if okS then
			how = "skin"
			E.failed = {}
			for _, bid in ipairs(E.lastFailedIds or {}) do
				removeFromDesc(newLook, bid)
				toast("\"" .. E.name(bid) .. "\" ditolak Roblox (sering: item off-sale/UGC terbatas di rig klien) dan muat langsung juga gagal. Coba item lain.", "warn")
			end
			local expected = #newLook:GetAccessories(true)
			if (E.skinAcc or 0) < expected then
				toast(string.format("Hanya %d dari %d aksesori yang berhasil dirender (sisanya diblokir Roblox/map).",
					E.skinAcc or 0, expected), "warn")
			end
		else
			logf("skin gagal: %s (pakai jalur cadangan)", tostring(errS))
		end
	end

	if not how then
		if not force and (#added + #removed) > 0 then
			local canInc = true
			for _, id in ipairs(removed) do
				if not E.failed[id] then
					canInc = false
				end
			end
			for _, id in ipairs(added) do
				if not isInjectable(E.assetType(id)) then
					canInc = false
				end
			end
			if canInc then
				for _, id in ipairs(removed) do
					E.failed[id] = nil
					for _, ch in ipairs(char:GetChildren()) do
						if ch:GetAttribute("AS") == id then
							ch:Destroy()
						end
					end
					char:SetAttribute("ASX_" .. tostring(id), nil)
				end
				local bad = 0
				for _, id in ipairs(added) do
					E.failed[id] = true
					if not E.inject(id, E.assetType(id)) then
						E.failed[id] = nil
						bad = bad + 1
					end
				end
				if bad == 0 then
					how = "injector"
				else
					logf("injector gagal untuk %d item -> coba render donor", bad)
				end
			end
		end
		if not how then
			local ok, err = E.renderLook(newLook)
			if not ok then
				toast("Gagal memasang: " .. tostring(err) .. (E.lastInjectErr and (" | injector: " .. E.lastInjectErr) or ""), "danger")
				return false
			end
			E.failed = {}
			how = "donor-render"
			local expected = #newLook:GetAccessories(true)
			if (E.rendered or 0) < expected then
				toast(string.format("Hanya %d dari %d aksesori yang berhasil dirender (sisanya diblokir Roblox/map).",
					E.rendered or 0, expected), "warn")
			end
		end
	end

	E.lastMethod = how
	if not skipHist and E.look then
		table.insert(E.history, E.look)
		while #E.history > 40 do
			table.remove(E.history, 1)
		end
		E.redo = {}
	end
	E.look = newLook
	task.delay(0.3, E.reapplyTweaks)
	fire()
	return true
end

function E.commit(newLook, text, skipHist, force)
	if E.busy then
		toast("Tunggu sebentar, avatar masih diproses...", "warn")
		return false
	end
	E.busy = true
	local ok, res = pcall(E._commit, newLook, text, skipHist, force)
	E.busy = false
	if not ok then
		toast("Error: " .. tostring(res), "danger")
		return false
	end
	return res
end

------------------------------------------------------------------------
-- ANTRIAN RENDER: klik beruntun digabung, hanya hasil akhir yang dirender
------------------------------------------------------------------------
E.pending, E.pendingCbs, E.worker = nil, {}, false

function E.queueLook(nl, onDone)
	E.pending = nl
	if onDone then
		table.insert(E.pendingCbs, onDone)
	end
	if E.worker then
		return
	end
	E.worker = true
	task.spawn(function()
		while E.pending do
			local l, cbs = E.pending, E.pendingCbs
			E.pending, E.pendingCbs = nil, {}
			while E.busy do
				task.wait(0.05)
			end
			local ok = E.commit(l, "queue")
			for _, cb in ipairs(cbs) do
				pcall(cb, ok)
			end
		end
		E.worker = false
	end)
end

------------------------------------------------------------------------
-- API tingkat tinggi
------------------------------------------------------------------------
function E.toggleAsset(id, itemName, onDone)
	local function finish(ok)
		if onDone then
			onDone(ok)
		end
		return ok
	end
	if not needReady() then
		return finish(false)
	end
	local tid = E.assetType(id)
	if not tid then
		toast("Tidak bisa membaca info item ini", "danger")
		return finish(false)
	end
	if not ACC[tid] and not CLASSIC[tid] then
		toast("Tipe item ini belum didukung", "warn")
		return finish(false)
	end
	local t0 = os.clock()
	local base = E.pending or E.look
	local worn = (collect(base))[id] == true
	local nl = base:Clone()
	if worn then
		removeFromDesc(nl, id)
	else
		addToDesc(nl, id, tid)
	end
	E.queueLook(nl, function(ok)
		if ok then
			if worn then
				toast("Dilepas: " .. tostring(itemName or id), "warn")
			elseif E.isWorn(id) then
				local okW = E.ensureWorn(id)
				toast(string.format("Dipakai: %s  (%s, %.1f dtk)", tostring(itemName or id), E.lastMethod, os.clock() - t0), okW and "ok" or "warn")
			end
		end
		finish(ok)
	end)
	return true
end

function E.removeAsset(id)
	if not needReady() then
		return false
	end
	local nl = (E.pending or E.look):Clone()
	removeFromDesc(nl, id)
	E.queueLook(nl)
	return true
end

local BODY_PARTS = {
	[17] = { "Head" },
	[27] = { "UpperTorso", "LowerTorso" },
	[28] = { "RightUpperArm", "RightLowerArm", "RightHand" },
	[29] = { "LeftUpperArm", "LeftLowerArm", "LeftHand" },
	[30] = { "LeftUpperLeg", "LeftLowerLeg", "LeftFoot" },
	[31] = { "RightUpperLeg", "RightLowerLeg", "RightFoot" },
}
E.bodyPre, E.bodyPreOrder = {}, {}

local function bodyDesc(assets)
	local d = Instance.new("HumanoidDescription")
	for _, a in ipairs(assets) do
		addToDesc(d, a.id, a.tid)
	end
	return d
end

-- tukar mesh bagian tubuh langsung di boneka skin (tanpa render ulang seluruh avatar)
function E.fastBody(bundleId, assets)
	if E.remote or not E.skinActive then
		return false
	end
	local char = player.Character
	local skin = char and char:FindFirstChild(SKIN_NAME)
	local hum = E.humanoid()
	if not skin or hum.RigType ~= Enum.HumanoidRigType.R15 then
		return false
	end
	local model = E.bodyPre[bundleId]
	if model then
		E.bodyPre[bundleId] = nil
		for i, id in ipairs(E.bodyPreOrder) do
			if id == bundleId then
				table.remove(E.bodyPreOrder, i)
				break
			end
		end
	else
		model = buildDonor(bodyDesc(assets))
	end
	if not model then
		return false
	end
	local changed, n = {}, 0
	for _, a in ipairs(assets) do
		for _, pn in ipairs(BODY_PARTS[a.tid] or {}) do
			local dp, cp = model:FindFirstChild(pn), skin:FindFirstChild(pn)
			if dp and cp and dp:IsA("MeshPart") and cp:IsA("MeshPart") then
				pcall(function()
					cp.MeshId = dp.MeshId
					cp.TextureID = dp.TextureID
					cp.Size = dp.Size
				end)
				pcall(function()
					for _, x in ipairs(cp:GetChildren()) do
						if x:IsA("SurfaceAppearance") then
							x:Destroy()
						end
					end
					local sa = dp:FindFirstChildOfClass("SurfaceAppearance")
					if sa then
						sa:Clone().Parent = cp
					end
				end)
				for _, da in ipairs(dp:GetChildren()) do
					if da:IsA("Attachment") then
						local ca = cp:FindFirstChild(da.Name)
						if ca and ca:IsA("Attachment") then
							ca.CFrame = da.CFrame
						end
					end
				end
				changed[pn] = true
				n = n + 1
			end
		end
	end
	if n > 0 then
		local ours = {}
		for _, d in ipairs(skin:GetDescendants()) do
			if d:IsA("Motor6D") and not ours[d.Name] then
				ours[d.Name] = d
			end
		end
		for _, m in ipairs(model:GetDescendants()) do
			if m:IsA("Motor6D") and ours[m.Name] and m.Part0 and m.Part1 and (changed[m.Part0.Name] or changed[m.Part1.Name]) then
				pcall(function()
					ours[m.Name].C0 = m.C0
					ours[m.Name].C1 = m.C1
				end)
			end
		end
	end
	pcall(function()
		model:Destroy()
	end)
	return n > 0
end

function E.resolveBundle(bundleId)
	local c = E.bundleCache[bundleId]
	if c then
		local t0 = os.clock()
		while not c.done and os.clock() - t0 < 12 do
			task.wait()
		end
		if c.done and not c.failed then
			return c.results, c.n
		end
		return nil
	end
	c = { done = false }
	E.bundleCache[bundleId] = c
	local info = productInfo(bundleId, Enum.InfoType.Bundle)
	if not info or not info.Items then
		c.done, c.failed = true, true
		E.bundleCache[bundleId] = nil
		return nil
	end
	local n = #info.Items
	local results, left = {}, n
	for i, item in ipairs(info.Items) do
		task.spawn(function()
			pcall(function()
				if item.Type == "UserOutfit" then
					results[i] = { kind = "outfit", d = descFromOutfit(item.Id) }
				elseif item.Type == "Asset" then
					results[i] = { kind = "asset", id = item.Id, tid = E.assetType(item.Id) }
				end
			end)
			left = left - 1
		end)
	end
	local t0 = os.clock()
	while left > 0 and os.clock() - t0 < 12 do
		task.wait()
	end
	c.results, c.n, c.done = results, n, true
	return results, n
end

-- antrean prefetch bundle (3 paralel). Bundle bagian tubuh juga disiapkan model donornya (maks 6)
E.bQ, E.bWorkers = {}, 0
function E.prefetchBundle(id)
	if E.bundleCache[id] then
		return
	end
	table.insert(E.bQ, 1, id)
	while E.bWorkers < 3 and #E.bQ > 0 do
		E.bWorkers = E.bWorkers + 1
		task.spawn(function()
			while #E.bQ > 0 and not stale() do
				local b = table.remove(E.bQ, 1)
				if not E.bundleCache[b] then
					pcall(function()
						local results, n = E.resolveBundle(b)
						if results and not E.remote and E.skinActive and #E.bodyPreOrder < 6 and not E.bodyPre[b] then
							local assets, only = {}, true
							for i = 1, n do
								local r = results[i]
								if r and r.kind == "asset" and r.tid and BODY_PARTS[r.tid] then
									assets[#assets + 1] = { id = r.id, tid = r.tid }
								elseif r then
									only = false
								end
							end
							if only and #assets > 0 then
								local m = buildDonor(bodyDesc(assets))
								if m then
									E.bodyPre[b] = m
									table.insert(E.bodyPreOrder, b)
								end
							end
						end
					end)
				end
			end
			E.bWorkers = E.bWorkers - 1
		end)
	end
end

function E.equipBundle(bundleId, bundleName, onDone, slot, slotName)
	local function finish(ok)
		if onDone then
			onDone(ok)
		end
		return ok
	end
	if not needReady() then
		return finish(false)
	end
	local results, n = E.resolveBundle(bundleId)
	if not results then
		toast("Gagal membaca isi bundle", "danger")
		return finish(false)
	end
	local nl = (E.pending or E.look):Clone()
	local applied = 0
	local bodyAssets, onlyBody = {}, true
	for i = 1, n do
		local r = results[i]
		if r then
			if r.kind == "outfit" and r.d and not slot then
				mergeDescription(nl, r.d)
				applied = applied + 1
				onlyBody = false
			elseif r.kind == "asset" and r.tid and (not slot or r.tid == slot) then
				addToDesc(nl, r.id, r.tid)
				applied = applied + 1
				if BODY_PARTS[r.tid] then
					bodyAssets[#bodyAssets + 1] = { id = r.id, tid = r.tid }
				else
					onlyBody = false
				end
			end
		end
	end
	-- jalur kilat: bundle hanya berisi bagian tubuh -> tukar mesh di boneka (target ~2 detik)
	if applied > 0 and onlyBody and #bodyAssets > 0 and not E.remote and E.skinActive and not E.busy and not E.pending then
		local t0 = os.clock()
		E.busy = true
		local okF, resF = pcall(E.fastBody, bundleId, bodyAssets)
		E.busy = false
		if okF and resF then
			if E.look then
				table.insert(E.history, E.look)
				E.redo = {}
			end
			E.look = nl
			E.failed = {}
			E.lastMethod = "badan-cepat"
			fire()
			toast(string.format("%s dipakai: %s  (%.1f dtk)", tostring(slotName or "Bundle"), tostring(bundleName or bundleId), os.clock() - t0), "ok")
			return finish(true)
		end
	end
	if slot and applied == 0 then
		toast("Paket ini tidak punya " .. tostring(slotName or "bagian itu") .. ", coba paket lain", "warn")
		return finish(false)
	end
	E.queueLook(nl, function(ok)
		if ok then
			toast((slot and (tostring(slotName) .. " dipakai dari: ") or "Bundle dipakai: ") .. tostring(bundleName or bundleId), "ok")
		end
		finish(ok)
	end)
	return true
end

E.descCache, E.descOrder = {}, {}

function E.cacheDesc(uid, desc)
	if E.descCache[uid] then
		return
	end
	E.descCache[uid] = desc
	table.insert(E.descOrder, uid)
	if #E.descOrder > 250 then
		local oldId = table.remove(E.descOrder, 1)
		local d = E.descCache[oldId]
		E.descCache[oldId] = nil
		pcall(function()
			d:Destroy()
		end)
	end
end

function E.getDesc(uid)
	local c = E.descCache[uid]
	if c then
		return c:Clone()
	end
	local d, err = descFromUser(uid)
	if d then
		E.cacheDesc(uid, d)
		return d:Clone()
	end
	return nil, err
end

------------------------------------------------------------------------
-- PREFETCH AVATAR: boneka donor disiapkan lebih dulu, jadi saat kartu diklik
-- avatar langsung terpasang (tinggal pasang, tidak perlu menunggu download lagi)
------------------------------------------------------------------------
local PRE_MAX = 10

function E.preEvict()
	while #E.preOrder > PRE_MAX do
		local uid = table.remove(E.preOrder, 1)
		local rec = E.preCache[uid]
		E.preCache[uid] = nil
		if rec then
			pcall(function()
				rec.model:Destroy()
			end)
		end
	end
end

function E.prefetchUser(uid)
	if E.remote or E.preCache[uid] or E.preJobs[uid] then
		return
	end
	E.preJobs[uid] = true
	task.spawn(function()
		pcall(function()
			local d = E.getDesc(uid)
			if not d then
				return
			end
			local m = buildDonor(d)
			if not m then
				return
			end
			if E.preCache[uid] then
				pcall(function()
					m:Destroy()
				end)
				return
			end
			E.preCache[uid] = { desc = d, model = m }
			table.insert(E.preOrder, uid)
			E.preEvict()
		end)
		E.preJobs[uid] = nil
	end)
end

-- antrean prefetch latar belakang (maks 2 paralel) untuk kartu yang sedang terlihat
E.bgQ, E.bgWorkers = {}, 0
function E.prefetchBg(uid)
	if E.remote or E.preCache[uid] or E.preJobs[uid] then
		return
	end
	for _, q in ipairs(E.bgQ) do
		if q == uid then
			return
		end
	end
	table.insert(E.bgQ, uid)
	while E.bgWorkers < 2 and #E.bgQ > 0 do
		E.bgWorkers = E.bgWorkers + 1
		task.spawn(function()
			while #E.bgQ > 0 and not stale() do
				local u = table.remove(E.bgQ, 1)
				if not E.preCache[u] and not E.preJobs[u] then
					E.prefetchUser(u)
					local t0 = os.clock()
					while E.preJobs[u] and os.clock() - t0 < 10 do
						task.wait(0.05)
					end
				end
			end
			E.bgWorkers = E.bgWorkers - 1
		end)
	end
end

-- foto profil: antrean preload paralel (3 pekerja x 24 gambar) supaya semua kartu terisi secepat mungkin
E.thumbQ, E.thumbWorkers = {}, 0
function E.preloadImg(img)
	table.insert(E.thumbQ, img)
	while E.thumbWorkers < 3 and #E.thumbQ > 0 do
		E.thumbWorkers = E.thumbWorkers + 1
		task.spawn(function()
			local CP = game:GetService("ContentProvider")
			while #E.thumbQ > 0 and not stale() do
				local batch = {}
				for _ = 1, 24 do
					local im = table.remove(E.thumbQ, 1)
					if not im then
						break
					end
					if im.Parent and not im.IsLoaded then
						batch[#batch + 1] = im
					end
				end
				if #batch > 0 then
					pcall(function()
						CP:PreloadAsync(batch)
					end)
				end
			end
			E.thumbWorkers = E.thumbWorkers - 1
		end)
	end
end

function E.applyUserVisual(userId, displayName, keepLook)
	local desc, derr
	local rec = E.preCache[userId]
	if not rec and E.preJobs[userId] then
		local t0 = os.clock()
		while E.preJobs[userId] and os.clock() - t0 < 8 do
			task.wait(0.03)
		end
		rec = E.preCache[userId]
	end
	if rec then
		desc = rec.desc
	else
		desc, derr = E.getDesc(userId)
	end
	if not desc then
		logf("ambil avatar %s gagal: %s", tostring(userId), tostring(derr))
		return false, "gagal mengambil avatar: " .. tostring(derr)
	end
	local ok, err = E.apply(desc)
	if not ok then
		logf("render avatar %s gagal: %s", tostring(userId), tostring(err))
		return false, err
	end
	if not keepLook then
		if E.look then
			table.insert(E.history, E.look)
			E.redo = {}
		end
		E.look = desc
		E.failed = {}
		E.userVisual = userId
		fire()
	end
	task.delay(0.3, E.reapplyTweaks)
	return true
end

function E.applyUser(userId, displayName)
	if E.busy then
		E.nextUser = { userId, displayName } -- klik terakhir dipasang begitu yang sekarang selesai
		toast("Antre: " .. tostring(displayName or userId) .. " dipasang sesudah proses ini", "warn")
		return false
	end
	if E.remote then
		local desc = E.getDesc(userId)
		if not desc then
			toast("Avatar pemain tidak bisa dimuat", "danger")
			return false
		end
		local done = E.commit(desc, displayName)
		if done then
			toast("Avatar dipakai: " .. tostring(displayName or userId), "ok")
		end
		return done
	end
	local t0 = os.clock()
	E.busy = true
	local ok, res, why = pcall(E.applyUserVisual, userId, displayName)
	E.busy = false
	local nx = E.nextUser
	E.nextUser = nil
	if ok and res then
		E.lastMethod = "donor-render"
		toast(string.format("Avatar dipakai: %s  (%.1f dtk)", tostring(displayName or userId), os.clock() - t0), "ok")
	else
		toast("Avatar tidak bisa dipasang: " .. tostring(ok and why or res) .. "  (lihat output/console)", "danger")
	end
	if nx and nx[1] ~= userId then
		task.spawn(E.applyUser, nx[1], nx[2])
	end
	return ok and res and true or false
end

function E.removeAll()
	if not needReady() then
		return false
	end
	local nl = (E.pending or E.look):Clone()
	nl:SetAccessories({}, true)
	E.failed = {}
	E.queueLook(nl)
	return true
end

function E.undo()
	local entry = table.remove(E.history)
	if not entry then
		toast("Tidak ada yang bisa di-undo", "warn")
		return
	end
	table.insert(E.redo, E.look)
	E.commit(entry, "undo", true)
end

function E.doRedo()
	local entry = table.remove(E.redo)
	if not entry then
		toast("Tidak ada yang bisa di-redo", "warn")
		return
	end
	table.insert(E.history, E.look)
	E.commit(entry, "redo", true)
end

function E.reset()
	if not needReady() then
		return
	end
	E.pending = nil
	if E.skinActive then
		E.removeSkin()
		E.userVisual = nil
		E.failed = {}
		E.resetScales()
		E.resetSkin()
		E.look = E.original:Clone()
		E.history, E.redo = {}, {}
		fire()
		toast("Avatar dikembalikan seperti semula", "ok")
		return
	end
	pcall(E.restoreBody)
	E.userVisual = nil
	E.failed = {}
	E.resetScales()
	E.resetSkin()
	E.commit(E.original:Clone(), "reset")
	toast("Avatar dikembalikan seperti semula", "ok")
end

function E.setScale(key, value, noRender)
	E.scales[key] = value
	local hum = E.humanoid()
	local nv = hum:FindFirstChild(SCALE_VALUES[key])
	if nv and nv:IsA("NumberValue") then
		nv.Value = value
	end
	if E.skinActive and E.look and not noRender then
		setProp(E.look, SCALE_DESC[key], value)
		E.scheduleRerender()
	end
end

function E.resetScales()
	E.scales = {}
	if E.original then
		local hum = E.humanoid()
		for key, prop in pairs(SCALE_DESC) do
			local v = getProp(E.original, prop)
			local nv = hum:FindFirstChild(SCALE_VALUES[key])
			if v and nv and nv:IsA("NumberValue") then
				nv.Value = v
			end
			if E.skinActive and E.look and v then
				setProp(E.look, prop, v)
			end
		end
		if E.skinActive then
			E.scheduleRerender()
		end
	end
end

function E.setSkin(color)
	E.skin = color
	local _, char = E.humanoid()
	local bc = char:FindFirstChildOfClass("BodyColors")
	if bc then
		for _, prop in ipairs(BODY_COLOR_PROPS) do
			bc[prop] = color
		end
	end
	local sk = char:FindFirstChild(SKIN_NAME)
	if sk then
		for _, p in ipairs(sk:GetChildren()) do
			if p:IsA("BasePart") and isBodyPart(p.Name) then
				p.Color = color
			end
		end
	end
end

function E.resetSkin()
	E.skin = nil
	if E.skinActive then
		E.scheduleRerender()
	end
	if E.origColors then
		local _, char = E.humanoid()
		local bc = char:FindFirstChildOfClass("BodyColors")
		if bc then
			for _, prop in ipairs(BODY_COLOR_PROPS) do
				bc[prop] = E.origColors[prop]
			end
		end
	end
end

function E.reapplyTweaks()
	for k, v in pairs(E.scales) do
		E.setScale(k, v, true)
	end
	if E.skin then
		E.setSkin(E.skin)
	end
end

function E.diagnose()
	local hum = E.humanoid()
	toast("Rig: " .. hum.RigType.Name .. "  |  Server script: " .. (E.remote and "ADA" or "tidak ada"), "info")
	local ok = pcall(function()
		return game:GetObjects("rbxassetid://1028606")
	end)
	toast("Mode inject-first: " .. (E.injectFirst and "AKTIF" or "mati") .. "  |  game:GetObjects: " .. (ok and "tersedia" or "tidak tersedia")
		.. "  |  Mode terakhir: " .. (E.lastMethod ~= "" and E.lastMethod or "-"), "info")
end

function E.probe()
	local cap = {}
	local pending = 3
	task.spawn(function()
		local ok, r = pcall(function()
			return game:GetObjects("rbxassetid://1028606")
		end)
		if not ok then
			cap.getObjects = false
		elseif type(r) == "table" and #r > 0 then
			cap.getObjects = true
		end
		pending = pending - 1
	end)
	task.spawn(function()
		local ok2, m2 = pcall(function()
			return InsertService:LoadAsset(1028606)
		end)
		if not ok2 then
			cap.insert = false
		elseif m2 then
			cap.insert = true
			pcall(function()
				m2:Destroy()
			end)
		end
		pending = pending - 1
	end)
	task.spawn(function()
		local okD = pcall(function()
			local d = Instance.new("HumanoidDescription")
			addToDesc(d, 1028606, 8)
			local dm = donorModel(d)
			if dm then
				cap.donor = dm:FindFirstChildOfClass("Accessory") ~= nil or nil
				pcall(function()
					dm:Destroy()
				end)
			else
				cap.donor = false
			end
		end)
		if not okD then
			cap.donor = false
		end
		pending = pending - 1
	end)
	local t0 = os.clock()
	while pending > 0 and os.clock() - t0 < 5 do
		task.wait(0.05)
	end
	E.cap = cap
	E.injectFirst = (cap.getObjects ~= false) or (cap.insert ~= false) or (cap.donor ~= false)
	logf("probe: GetObjects=%s LoadAsset=%s Donor=%s -> inject-first=%s", tostring(cap.getObjects), tostring(cap.insert),
		tostring(cap.donor), tostring(E.injectFirst))
end

function E.snapBody(char)
	E.bodySnap = {}
	for _, n in ipairs(LIMBS) do
		local p = char:FindFirstChild(n)
		if p and p:IsA("BasePart") then
			local rec = { Transparency = p.Transparency }
			if p:IsA("MeshPart") then
				rec.MeshId = p.MeshId
				rec.TextureID = p.TextureID
			end
			local sa = p:FindFirstChildOfClass("SurfaceAppearance")
			if sa then
				rec.SA = sa:Clone()
			end
			E.bodySnap[n] = rec
		end
	end
end

function E.restoreBody()
	local _, char = E.humanoid()
	for n, rec in pairs(E.bodySnap or {}) do
		local p = char:FindFirstChild(n)
		if p and p:IsA("BasePart") then
			pcall(function()
				p.Transparency = rec.Transparency
				if rec.MeshId and p:IsA("MeshPart") then
					p.MeshId = rec.MeshId
					p.TextureID = rec.TextureID
				end
				for _, x in ipairs(p:GetChildren()) do
					if x:IsA("SurfaceAppearance") then
						x:Destroy()
					end
				end
				if rec.SA then
					rec.SA:Clone().Parent = p
				end
			end)
		end
	end
	toast("Badan/tangan/kaki dipulihkan ke bentuk awal", "ok")
end

function E.init()
	local hum, char = E.humanoid()
	E.snapBody(char)
	E.snapAnim(char)
	E.hookChar(char)
	E.remote = ReplicatedStorage:FindFirstChild(REMOTE_NAME) or ReplicatedStorage:WaitForChild(REMOTE_NAME, 1)
	local d, gotDesc = nil, false
	task.spawn(function()
		d = appliedDesc(hum)
		gotDesc = true
	end)
	E.probe()
	local tw = os.clock()
	while not gotDesc and os.clock() - tw < 10 do
		task.wait(0.05)
	end
	d = d or Instance.new("HumanoidDescription")
	E.original = d:Clone()
	E.look = d:Clone()
	E.origColors = {}
	local bc = char:FindFirstChildOfClass("BodyColors")
	if bc then
		for _, prop in ipairs(BODY_COLOR_PROPS) do
			E.origColors[prop] = bc[prop]
		end
	end
	player.CharacterAdded:Connect(function(newChar)
		newChar:WaitForChild("Humanoid")
		if stale() then
			return
		end
		E.hookChar(newChar)
		E.skinActive = false
		E.hidden = {}
		task.wait(1)
		if E.look then
			if E.remote then
				E.commit(E.look:Clone(), "respawn", true, true)
			elseif not E.busy then
				E.busy = true
				pcall(function()
					E.apply(E.look)
					E.failed = {}
				end)
				E.busy = false
				E.reapplyTweaks()
			end
		end
	end)
	task.spawn(function()
		while task.wait(1.2) do
			if stale() then
				break
			end
			if E.injectFirst and not E.remote and not E.busy then
				pcall(E.guard)
			end
		end
	end)
	fire()
end

----------------------------------------------------------------------------
-- [6] KATALOG  (Karakter/Tubuh, Animasi, Sepatu)
----------------------------------------------------------------------------
pcall(function()
	math.randomseed(os.time())
end)

local CATEGORIES = {}
-- variants (hanya untuk bundle, jalur web cadangan): { Category, Subcategory, kataKunciBawaan }
local function C(group, id, name, kind, list, variants, slot)
	table.insert(CATEGORIES, { group = group, id = id, name = name, kind = kind, list = list, httpVariants = variants, slot = slot })
end

C("KARAKTER / TUBUH", "b_body", "Paket Karakter", "bundle", { "BodyParts" }, { { 4, 37 }, { 4 } })
C("KARAKTER / TUBUH", "face", "Ekspresi Wajah", "asset", { "Face" })
C("KARAKTER / TUBUH", "head", "Kepala", "bundle", { "BodyParts" }, { { 4, 37 }, { 4 } }, 17)
C("KARAKTER / TUBUH", "torso", "Badan", "bundle", { "BodyParts" }, { { 4, 37 }, { 4 } }, 27)
C("KARAKTER / TUBUH", "rarm", "Lengan Kanan", "bundle", { "BodyParts" }, { { 4, 37 }, { 4 } }, 28)
C("KARAKTER / TUBUH", "larm", "Lengan Kiri", "bundle", { "BodyParts" }, { { 4, 37 }, { 4 } }, 29)
C("KARAKTER / TUBUH", "rleg", "Kaki Kanan", "bundle", { "BodyParts" }, { { 4, 37 }, { 4 } }, 31)
C("KARAKTER / TUBUH", "lleg", "Kaki Kiri", "bundle", { "BodyParts" }, { { 4, 37 }, { 4 } }, 30)
C("KARAKTER / TUBUH", "brow", "Alis", "asset", { "EyebrowAccessory" })
C("KARAKTER / TUBUH", "lash", "Bulu Mata", "asset", { "EyelashAccessory" })

C("ANIMASI", "b_anim", "Paket Animasi", "bundle", { "Animations" }, { { 12, 38 }, { 12 } })
C("ANIMASI", "a_idle", "Idle", "bundle", { "Animations" }, { { 12, 38 }, { 12 } }, 51)
C("ANIMASI", "a_walk", "Jalan", "bundle", { "Animations" }, { { 12, 38 }, { 12 } }, 55)
C("ANIMASI", "a_run", "Lari", "bundle", { "Animations" }, { { 12, 38 }, { 12 } }, 53)
C("ANIMASI", "a_jump", "Lompat", "bundle", { "Animations" }, { { 12, 38 }, { 12 } }, 52)
C("ANIMASI", "a_fall", "Jatuh", "bundle", { "Animations" }, { { 12, 38 }, { 12 } }, 50)
C("ANIMASI", "a_climb", "Panjat", "bundle", { "Animations" }, { { 12, 38 }, { 12 } }, 48)
C("ANIMASI", "a_swim", "Renang", "bundle", { "Animations" }, { { 12, 38 }, { 12 } }, 54)
C("ANIMASI", "a_mood", "Mood", "asset", { "MoodAnimation" })

C("SEPATU", "b_shoes", "Set Sepatu", "bundle", { "Shoes" }, { { 4, 37, "shoes" }, { 3, nil, "shoes" }, { 1, 37, "shoes" } })
C("SEPATU", "lshoe", "Sepatu Kiri", "asset", { "LeftShoeAccessory" })
C("SEPATU", "rshoe", "Sepatu Kanan", "asset", { "RightShoeAccessory" })

local SORTS = {
	{ name = "Relevansi", enum = "Relevance" },
	{ name = "Terfavorit", enum = "MostFavorited" },
	{ name = "Terlaris", enum = "Bestselling" },
	{ name = "Terbaru", enum = "RecentlyCreated" },
	{ name = "Termurah", enum = "PriceLowToHigh" },
	{ name = "Termahal", enum = "PriceHighToLow" },
}

local HOSTS = { "https://catalog.roblox.com", "https://catalog.roproxy.com" }

-- tipe aset -> Category katalog web (dipakai jalur HTTP v1 sebagai cadangan)
local function httpCategoryFor(tid)
	if tid == 8 or (tid and tid >= 41 and tid <= 47) or tid == 76 or tid == 77 then
		return 11
	elseif tid == 11 or tid == 12 or tid == 2 or (tid and tid >= 64 and tid <= 72) then
		return 3
	elseif tid == 18 or tid == 17 or (tid and tid >= 27 and tid <= 31) then
		return 4
	elseif tid and (tid >= 48 and tid <= 55 or tid == 78) then
		return 12
	end
	return 1
end

local function fetchDetails(ids, itemType)
	local out = {}
	if #ids == 0 then
		return out
	end
	local ok, res = batchDetails(ids, itemType)
	if ok and type(res) == "table" then
		for _, d in ipairs(res) do
			out[d.Id] = d
		end
	end
	return out
end

local Query = {}
Query.__index = Query

local function newQuery(cat, keyword, sortIdx, freeOnly)
	local okP, params = pcall(function()
		return CatalogSearchParams.new()
	end)
	if not okP then
		params = nil
	end
	setProp(params, "SearchKeyword", keyword or "")
	local se = safeEnum(Enum.CatalogSortType, SORTS[sortIdx].enum)
	if se then
		setProp(params, "SortType", se)
	end
	local assetTypes, bundleTypes = {}, {}
	if cat.kind == "asset" then
		for _, n in ipairs(cat.list) do
			local e = safeEnum(Enum.AvatarAssetType, n)
			if e then
				table.insert(assetTypes, e)
			end
		end
	elseif cat.kind == "bundle" then
		for _, n in ipairs(cat.list) do
			local e = safeEnum(Enum.BundleType, n)
			if e then
				table.insert(bundleTypes, e)
			end
		end
	end
	setProp(params, "AssetTypes", assetTypes)
	setProp(params, "BundleTypes", bundleTypes)
	setProp(params, "IncludeOffSale", false)
	if freeOnly then
		setProp(params, "MaxPrice", 0)
	end
	setProp(params, "Limit", PAGE_SIZE)
	local tid = (cat.kind == "asset" and cat.list and #cat.list == 1) and NAME2TID[cat.list[1]] or nil
	return setmetatable({ params = params, finished = false, pages = nil, total = 0, tid = tid, cat = cat,
		keyword = keyword or "", sortNum = (sortIdx or 1) - 1, freeOnly = freeOnly }, Query)
end

function Query:aesPage()
	if self.finished then
		return {}
	end
	if not self.params then
		return nil, "CatalogSearchParams tidak tersedia di lingkungan ini"
	end
	local ok, res = pcall(function()
		if not self.pages then
			local okS, r = callAny(AvatarEditorService, { "SearchCatalogAsync", "SearchCatalog" }, self.params)
			if not okS then
				local p2 = CatalogSearchParams.new()
				setProp(p2, "SearchKeyword", getProp(self.params, "SearchKeyword") or "")
				setProp(p2, "AssetTypes", getProp(self.params, "AssetTypes") or {})
				setProp(p2, "BundleTypes", getProp(self.params, "BundleTypes") or {})
				local ok2, r2 = callAny(AvatarEditorService, { "SearchCatalogAsync", "SearchCatalog" }, p2)
				if not ok2 then
					error(tostring(r) .. " | ulang: " .. tostring(r2))
				end
				r = r2
			end
			self.pages = r
		else
			self.pages:AdvanceToNextPageAsync()
		end
		return self.pages:GetCurrentPage()
	end)
	if not ok then
		return nil, tostring(res)
	end
	if self.pages.IsFinished then
		self.finished = true
	end
	-- daftar langsung ditampilkan; nama & harga menyusul di latar belakang
	local assetIds, bundleIds, items, byId = {}, {}, {}, {}
	for _, it in ipairs(res) do
		local isBundle = it.ItemType == "Bundle" or it.ItemType == Enum.AvatarItemType.Bundle
		table.insert(isBundle and bundleIds or assetIds, it.Id)
		self.total = self.total + 1
		local nm = it.Name or ("Item #" .. it.Id)
		local row = { Id = it.Id, Type = isBundle and "Bundle" or "Asset", Name = nm, Price = false, Order = self.total }
		byId[(isBundle and "B" or "A") .. it.Id] = row
		table.insert(items, row)
		if not isBundle then
			E.names[it.Id] = E.names[it.Id] or nm
			if self.tid then
				E.types[it.Id] = self.tid
			end
		end
	end
	local function fill(ids, itemType, prefix)
		if #ids == 0 then
			return
		end
		task.spawn(function()
			local det = fetchDetails(ids, itemType)
			for id, d in pairs(det) do
				local row = byId[prefix .. id]
				if row then
					row.Name = d.Name or row.Name
					row.Price = d.PriceInRobux
					if prefix == "A" and d.Name then
						E.names[id] = d.Name
					end
					if row.onUpdate then
						pcall(row.onUpdate)
					end
				end
			end
			for _, id in ipairs(ids) do
				local row = byId[prefix .. id]
				if row and row.Price == false then
					row.Price = nil
					if row.onUpdate then
						pcall(row.onUpdate)
					end
				end
			end
		end)
	end
	fill(assetIds, Enum.AvatarItemType.Asset, "A")
	fill(bundleIds, Enum.AvatarItemType.Bundle, "B")
	return items
end

-- jalur web cadangan. Bundle memakai Category + Subcategory (37 = Bundles, 38 = AnimationBundles)
function Query:httpPage()
	local cat = self.cat
	local base = "&Limit=" .. PAGE_SIZE .. "&SortType=" .. tostring(self.sortNum or 0)
	if self.freeOnly then
		base = base .. "&MaxPrice=0"
	end
	if self.cursor then
		base = base .. "&cursor=" .. urlenc(self.cursor)
	end
	local function withKeyword(kw)
		if kw and kw ~= "" then
			return base .. "&Keyword=" .. urlenc(kw)
		end
		return base
	end
	local urls = {}
	for _, host in ipairs(HOSTS) do
		if cat.kind == "asset" and self.tid then
			local c = withKeyword(self.keyword)
			table.insert(urls, host .. "/v2/search/items/details?assetTypeIds=" .. self.tid .. c)
			table.insert(urls, host .. "/v1/search/items/details?Category=" .. httpCategoryFor(self.tid) .. c)
		else
			for _, v in ipairs(cat.httpVariants or { { 1, 37 } }) do
				local q = "Category=" .. tostring(v[1])
				if v[2] then
					q = q .. "&Subcategory=" .. tostring(v[2])
				end
				local kw = (self.keyword ~= "") and self.keyword or v[3]
				table.insert(urls, host .. "/v1/search/items/details?" .. q .. withKeyword(kw))
			end
		end
	end
	local a, b = 1, #urls
	if self.httpIdx then
		a, b = self.httpIdx, self.httpIdx
	end
	local lastErr = "tidak ada URL"
	for i = a, b do
		local body, herr = httpGet(urls[i])
		if body then
			local okJ, data = pcall(function()
				return HttpService:JSONDecode(body)
			end)
			if okJ and type(data) == "table" and type(data.data) == "table" then
				local items = {}
				for _, d in ipairs(data.data) do
					local at = tonumber(d.assetType)
					local isBundle = d.itemType == "Bundle"
					local keep
					if cat.kind == "bundle" then
						keep = isBundle
					else
						keep = (not isBundle) and (at == nil or self.tid == nil or at == self.tid)
					end
					if keep and tonumber(d.id) then
						self.total = self.total + 1
						local price = d.price
						if price == nil then
							price = d.lowestPrice
						end
						table.insert(items, {
							Id = tonumber(d.id), Type = isBundle and "Bundle" or "Asset", Name = tostring(d.name or ("Item #" .. d.id)),
							Price = price, Order = self.total,
						})
						if not isBundle then
							E.names[tonumber(d.id)] = E.names[tonumber(d.id)] or tostring(d.name)
							E.types[tonumber(d.id)] = at or self.tid or E.types[tonumber(d.id)]
						end
					end
				end
				if #items > 0 or data.nextPageCursor or self.total > 0 or i == b then
					self.httpIdx = i
					self.cursor = data.nextPageCursor
					if not self.cursor then
						self.finished = true
					end
					return items
				end
				lastErr = "hasil kosong dari " .. urls[i]
			else
				lastErr = "JSON tidak valid dari " .. urls[i]
			end
		else
			lastErr = tostring(herr)
		end
	end
	return nil, lastErr
end

function Query:nextPage()
	if self.finished then
		return {}
	end
	local errs = {}
	if self.backend ~= "http" then
		local items, err = self:aesPage()
		if items and not (#items == 0 and self.total == 0 and self.backend == nil) then
			self.backend = "aes"
			return items
		end
		if self.backend == "aes" then
			return nil, err
		end
		table.insert(errs, "AvatarEditorService: " .. tostring(err or "hasil kosong"))
		self.finished = false
	end
	local items2, err2 = self:httpPage()
	if items2 then
		self.backend = "http"
		return items2
	end
	table.insert(errs, "Web: " .. tostring(err2))
	return nil, table.concat(errs, "\n")
end

----------------------------------------------------------------------------
-- [7] TEMA + FILTER BACON / BACON CEWE + ANALISIS (jumlah item, cowo/cewe)
----------------------------------------------------------------------------
-- ===== PENGATURAN FILTER (ubah angka ini kalau mau lebih longgar / lebih ketat) =====
local FILTER_POLOSAN = true  -- true = sembunyikan avatar bawaan Roblox (bacon / bacon cewe / dll) dari tab avatar. false = tampilkan semua
local MIN_REAL_ITEMS = 4     -- avatar dengan item kurang dari ini SELALU dianggap bacon (tersembunyi)
local MIN_FOREIGN_ITEMS = 2  -- avatar asli minimal punya segini item BUKAN buatan Roblox (kalau kurang = bacon / bacon cewe)
local ROBLOX_ONLY_MAX = 16   -- avatar dengan item sebanyak ini atau kurang yang cuma pakai item Roblox = bacon. Di atas ini langsung dianggap asli
local MOST_MIN_ITEMS = 6     -- mode "Item terbanyak": hanya avatar dengan minimal segini item yang tampil
local GENDER_MIN_DIFF = 2    -- selisih skor minimal untuk memastikan cowo/cewe (makin besar = makin teliti, hasil makin sedikit)
local ROBLOX_CREATORS = { [1] = true, [1200769] = true } -- ID akun / grup resmi Roblox

local PREWARM_SKIN = true -- render boneka sekali di awal supaya klik pertama sudah cepat (set false kalau avatar terlihat berubah di awal)
local FEED_FIRST = 130    -- kartu avatar yang langsung muncul
local FEED_MORE = 60      -- tambahan tiap gulir
local FEED_CONC = 24      -- pengecekan avatar paralel
local FEED_KEEP = 160     -- jumlah kartu avatar minimal yang dijaga tetap terisi di latar belakang
local AV_SAVE_MAX = 400   -- maksimal avatar yang disimpan ke file config (supaya saat masuk lagi langsung tampil)
local AV_FILE = "leon4951hub_avatars.json"

local Theme = {
	Background = rgb(7, 10, 17), CardBg = rgb(14, 20, 32), CardBorder = rgb(34, 48, 73),
	Accent = rgb(0, 122, 255), TabActiveBg = rgb(18, 32, 54), TabActiveBorder = rgb(0, 122, 255),
	TextPrimary = rgb(245, 247, 255), TextMuted = rgb(130, 145, 175),
	WaGreen = rgb(37, 211, 102), WaDarkGreen = rgb(18, 38, 28),
}
local WA_CHANNEL_LINK = "https://whatsapp.com/channel/0029VbDq74VHgZWbi0AdSa1L"

-- samakan warna helper lama (button, label, toast, kartu) dengan tema baru
T.Bg = Theme.Background
T.Surface = Theme.CardBg
T.Surface2 = rgb(22, 32, 50)
T.Hover = rgb(30, 44, 70)
T.Stroke = Theme.CardBorder
T.Text = Theme.TextPrimary
T.Dim = Theme.TextMuted
T.Accent = Theme.Accent

-- cache info item: nama (huruf kecil) + apakah buatan Roblox. Item default berulang, jadi cache menghemat banyak request
local itemInfo = {}
local itemMiss = {}
local plainCache = {}
local analysisCache = {}

local PLAIN_PROPS = {
	"Shirt", "Pants", "GraphicTShirt", "ClimbAnimation", "FallAnimation", "IdleAnimation",
	"JumpAnimation", "RunAnimation", "SwimAnimation", "WalkAnimation", "MoodAnimation",
}

local function robloxMade(creatorId, creatorName)
	local cid = tonumber(creatorId)
	if cid and ROBLOX_CREATORS[cid] then
		return true
	end
	return tostring(creatorName or "") == "Roblox"
end

-- nama dinormalkan: "bow tie" & "tie dye" dibuang supaya tidak salah dikira kata gender
local function normName(name)
	local s = string.lower(tostring(name or ""))
	s = s:gsub("bow%s*tie", " "):gsub("tie%s*%-?%s*dye", " ")
	return s
end

local function storeInfo(id, name, creatorId, creatorName)
	itemInfo[id] = { name = normName(name), roblox = robloxMade(creatorId, creatorName) }
end

-- isi itemInfo untuk semua id. Coba batch 2x, lalu cadangan GetProductInfo per item. return true kalau SEMUA id terisi
local function ensureDetails(ids)
	local function missing()
		local need, now = {}, os.clock()
		for _, id in ipairs(ids) do
			if itemInfo[id] == nil and (now - (itemMiss[id] or -100)) > 15 then
				table.insert(need, id)
			end
		end
		return need
	end
	for attempt = 1, 2 do
		local need = missing()
		if #need == 0 then
			break
		end
		for i = 1, #need, 50 do
			local chunk = {}
			for j = i, math.min(i + 49, #need) do
				table.insert(chunk, need[j])
			end
			local det = fetchDetails(chunk, Enum.AvatarItemType.Asset)
			for _, id in ipairs(chunk) do
				local dd = det[id]
				if dd then
					storeInfo(id, dd.Name, dd.CreatorTargetId, dd.CreatorName)
				end
			end
		end
		if attempt == 1 and #missing() > 0 then
			task.wait(0.4)
		end
	end
	local need = missing()
	for k, id in ipairs(need) do
		if k > 16 then
			break
		end
		local info = productInfo(id, Enum.InfoType.Asset)
		if info then
			local c = info.Creator or {}
			storeInfo(id, info.Name, c.Id or c.TargetId, c.Name)
		else
			itemMiss[id] = os.clock()
		end
	end
	for _, id in ipairs(ids) do
		if itemInfo[id] == nil then
			return false
		end
	end
	return true
end

-- hitung item pada avatar (aksesori + baju/celana/animasi), tentukan bacon / bacon cewe atau avatar asli.
-- Bagian tubuh klasik (kepala, badan, tangan, kaki, wajah) tidak dihitung, karena itu bawaan semua akun.
-- Aturan (semua harus lolos agar dianggap AVATAR ASLI):
--   1) item >= MIN_REAL_ITEMS
--   2) item > ROBLOX_ONLY_MAX  ATAU  minimal MIN_FOREIGN_ITEMS item buatan selain Roblox
-- Kalau info item gagal dimuat dan belum terbukti asli -> dianggap bacon + ditandai unsure (disembunyikan, aman).
local function analyzeDesc(desc)
	local ids, types, seen = {}, {}, {}
	local okA, accs = pcall(function()
		return desc:GetAccessories(true)
	end)
	if okA then
		for _, a in ipairs(accs) do
			if not seen[a.AssetId] then
				seen[a.AssetId] = true
				table.insert(ids, a.AssetId)
				types[a.AssetId] = a.AccessoryType.Name
			end
		end
	end
	for _, prop in ipairs(PLAIN_PROPS) do
		local v = getProp(desc, prop)
		if type(v) == "number" and v > 0 and not seen[v] then
			seen[v] = true
			table.insert(ids, v)
		end
	end
	local count = #ids
	local a = { count = count, ids = ids, types = types, plain = false, unsure = false, foreign = 0 }
	if count < MIN_REAL_ITEMS then
		a.plain = true
		return a
	end
	if count > ROBLOX_ONLY_MAX then
		a.foreign = count
		return a
	end
	local complete = ensureDetails(ids)
	local foreign = 0
	for _, id in ipairs(ids) do
		local inf = itemInfo[id]
		if inf and not inf.roblox then
			foreign = foreign + 1
		end
	end
	a.foreign = foreign
	if foreign >= MIN_FOREIGN_ITEMS then
		a.plain = false
	elseif complete then
		a.plain = true
	else
		a.plain = true
		a.unsure = true
	end
	return a
end

----------------------------------------------------------------------------
-- DETEKSI COWO / CEWE (sistem skor)
-- Roblox tidak menyimpan gender akun, jadi dinilai dari NAMA item + tipe aksesori.
-- {kata, bobot}: bobot 2 = petunjuk kuat, 1 = petunjuk lemah. Skor per item dibatasi maks 3.
-- Kalau selisih skor < GENDER_MIN_DIFF -> avatar dianggap "tidak jelas" dan TIDAK muncul di filter Cowo / Cewe.
----------------------------------------------------------------------------
local FEMALE_WORDS = {
	{ "girl", 2 }, { "female", 2 }, { "woman", 2 }, { "women", 2 }, { "lady", 2 }, { "dress", 2 }, { "skirt", 2 },
	{ "miniskirt", 2 }, { "sundress", 2 }, { "bikini", 2 }, { "ponytail", 2 }, { "pigtail", 2 }, { "twintail", 2 },
	{ "twin tail", 2 }, { "heel", 2 }, { "lipstick", 2 }, { "makeup", 2 }, { "princess", 2 }, { "braid", 2 },
	{ "blouse", 2 }, { "kawaii", 2 }, { "gyaru", 2 }, { "cewek", 2 }, { "wanita", 2 }, { "maid", 2 }, { "hime", 2 },
	{ "mermaid", 2 }, { "fairy", 2 }, { "queen", 2 }, { "bride", 2 }, { "lolita", 2 }, { "bra", 2 }, { "stocking", 2 },
	{ "tutu", 2 }, { "gown", 2 }, { "crop top", 2 }, { "corset", 2 }, { "babydoll", 2 }, { "waifu", 2 },
	{ "bunny", 1 }, { "legging", 1 }, { "lash", 1 }, { "eyelash", 1 }, { "bangs", 1 }, { "bun", 1 }, { "bob", 1 },
	{ "ribbon", 1 }, { "bow", 1 }, { "pink", 1 }, { "cute", 1 }, { "heart", 1 }, { "kitty", 1 }, { "pastel", 1 },
	{ "sparkle", 1 }, { "glitter", 1 }, { "floral", 1 }, { "flower", 1 }, { "angel", 1 }, { "idol", 1 },
}
local MALE_WORDS = {
	{ "boy", 2 }, { "male", 2 }, { "man", 2 }, { "men", 2 }, { "guy", 2 }, { "beard", 2 }, { "mustache", 2 },
	{ "moustache", 2 }, { "stubble", 2 }, { "dude", 2 }, { "gentleman", 2 }, { "king", 2 }, { "cowok", 2 },
	{ "pria", 2 }, { "goatee", 2 }, { "sideburn", 2 }, { "buzz cut", 2 }, { "crew cut", 2 }, { "undercut", 2 },
	{ "mohawk", 2 }, { "pompadour", 2 }, { "tuxedo", 2 },
	{ "bro", 1 }, { "suit", 1 }, { "necktie", 1 }, { "tie", 1 }, { "hoodie", 1 }, { "beanie", 1 }, { "cap", 1 },
	{ "snapback", 1 }, { "jeans", 1 }, { "jersey", 1 }, { "tracksuit", 1 }, { "muscle", 1 }, { "bandana", 1 },
	{ "skater", 1 }, { "streetwear", 1 }, { "sneaker", 1 }, { "bald", 1 }, { "spiky", 1 }, { "slick", 1 },
}

local function scoreWords(name, list)
	local s = 0
	for _, w in ipairs(list) do
		if string.find(name, "%f[%a]" .. w[1] .. "e?s?%f[%A]") then
			s = s + w[2]
		end
	end
	return s
end

-- return "cewe" / "cowo" / nil (tidak jelas)
local function genderOf(a)
	ensureDetails(a.ids)
	local f, m = 0, 0
	for _, id in ipairs(a.ids) do
		local inf = itemInfo[id]
		local fi, mi = 0, 0
		if inf then
			fi = scoreWords(inf.name, FEMALE_WORDS)
			mi = scoreWords(inf.name, MALE_WORDS)
		end
		local t = a.types[id]
		if t == "DressSkirt" then
			fi = fi + 3
		elseif t == "Eyelash" then
			fi = fi + 1
		end
		f = f + math.min(fi, 3)
		m = m + math.min(mi, 3)
	end
	if f - m >= GENDER_MIN_DIFF then
		return "cewe"
	end
	if m - f >= GENDER_MIN_DIFF then
		return "cowo"
	end
	return nil
end

-- return: polosan (bacon / bacon cewe)?, sudah-pasti?
local function isPlainAvatar(userId)
	if not FILTER_POLOSAN then
		return false, true
	end
	if plainCache[userId] ~= nil then
		return plainCache[userId], true
	end
	local desc = descFromUser(userId)
	if not desc then
		return false, false
	end
	local a = analyzeDesc(desc)
	pcall(function()
		desc:Destroy()
	end)
	if a.unsure then
		return true, false
	end
	plainCache[userId] = a.plain
	analysisCache[userId] = a
	return a.plain, true
end

----------------------------------------------------------------------------
-- [7b] FAVORIT + CONFIG AVATAR (tersimpan ke file kalau executor punya writefile)
----------------------------------------------------------------------------
local FAV_FILE = "leon4951hub_fav.json"
local FAV = { avatars = {}, items = {}, listeners = {} }

local function favSave()
	if type(writefile) ~= "function" then
		return
	end
	pcall(function()
		writefile(FAV_FILE, HttpService:JSONEncode({ avatars = FAV.avatars, items = FAV.items }))
	end)
end
pcall(function()
	if type(readfile) == "function" and type(isfile) == "function" and isfile(FAV_FILE) then
		local d = HttpService:JSONDecode(readfile(FAV_FILE))
		if type(d) == "table" then
			FAV.avatars = type(d.avatars) == "table" and d.avatars or {}
			FAV.items = type(d.items) == "table" and d.items or {}
		end
	end
end)

function FAV.listen(fn)
	table.insert(FAV.listeners, fn)
end
function FAV.fire()
	local i = 1
	while i <= #FAV.listeners do
		local ok, keep = pcall(FAV.listeners[i])
		if ok and keep == false then
			table.remove(FAV.listeners, i)
		else
			i = i + 1
		end
	end
end
function FAV.itemKey(item)
	return (item.Type == "Bundle" and "B" or "A") .. tostring(item.Id) .. ":" .. tostring(item.slot or 0)
end
function FAV.toggleAvatar(id, name)
	local k = tostring(id)
	if FAV.avatars[k] then
		FAV.avatars[k] = nil
	else
		FAV.avatars[k] = { id = id, name = tostring(name), t = os.time() }
	end
	favSave()
	FAV.fire()
end
function FAV.toggleItem(item)
	local k = FAV.itemKey(item)
	if FAV.items[k] then
		FAV.items[k] = nil
	else
		FAV.items[k] = {
			Id = item.Id, Type = item.Type, Name = item.Name, slot = item.slot, slotName = item.slotName,
			tid = item.Type == "Asset" and E.types[item.Id] or nil, t = os.time(),
		}
	end
	favSave()
	FAV.fire()
end

-- config daftar avatar: daftar kartu di tab avatar disimpan, saat masuk lagi langsung muncul & lanjut memuat
local function avLoad()
	local out = {}
	pcall(function()
		if type(readfile) == "function" and type(isfile) == "function" and isfile(AV_FILE) then
			local d = HttpService:JSONDecode(readfile(AV_FILE))
			if type(d) == "table" and type(d.list) == "table" then
				out = d.list
			end
		end
	end)
	return out
end
local function avSave(list)
	if type(writefile) ~= "function" then
		return
	end
	pcall(function()
		writefile(AV_FILE, HttpService:JSONEncode({ v = 1, list = list }))
	end)
end

local function addHeart(card, isFav, onToggle)
	local h = mk("TextButton", {
		Size = UDim2.fromOffset(20, 20), Position = UDim2.fromOffset(4, 4), BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45, BorderSizePixel = 0, Text = "♡", TextSize = 14, Font = Enum.Font.GothamBold,
		TextColor3 = T.Text, AutoButtonColor = false, ZIndex = 5, Parent = card,
	})
	corner(h, 10)
	local function paint()
		local f = isFav()
		h.Text = f and "♥" or "♡"
		h.TextColor3 = f and T.Danger or T.Text
	end
	paint()
	h.Activated:Connect(function()
		onToggle()
		paint()
	end)
	return paint
end

----------------------------------------------------------------------------
-- [8] KARTU KATALOG
----------------------------------------------------------------------------
local function makeCard(parent, item)
	local isBundle = item.Type == "Bundle"
	local card = mk("TextButton", {
		AutoButtonColor = false, Text = "", BackgroundColor3 = T.Surface, BorderSizePixel = 0,
		LayoutOrder = item.Order or 0, Parent = parent,
	})
	corner(card, 10)
	local st = stroke(card, T.Stroke, 1.5, 0.3)
	local img = mk("ImageLabel", {
		Size = UDim2.new(1, -8, 0, 64), Position = UDim2.fromOffset(4, 4), BackgroundColor3 = T.Surface2,
		BorderSizePixel = 0, ScaleType = Enum.ScaleType.Fit, Parent = card,
	})
	corner(img, 8)
	local nm = label(card, item.Name, 11, T.Text, Enum.Font.GothamBold)
	nm.Position = UDim2.fromOffset(5, 71)
	nm.Size = UDim2.new(1, -10, 0, 14)
	nm.TextTruncate = Enum.TextTruncate.AtEnd
	local pr = label(card, priceText(item.Price), 10, item.Price == 0 and T.Ok or T.Dim, Enum.Font.GothamMedium)
	pr.Position = UDim2.fromOffset(5, 88)
	pr.Size = UDim2.new(1, -10, 0, 12)
	item.onUpdate = function()
		if not card.Parent then
			return
		end
		nm.Text = item.Name
		pr.Text = priceText(item.Price)
		pr.TextColor3 = item.Price == 0 and T.Ok or T.Dim
	end
	local badge = mk("TextLabel", {
		Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 8),
		BackgroundColor3 = T.Ok, Text = "✓", TextColor3 = Color3.new(1, 1, 1), TextSize = 12, Font = Enum.Font.GothamBold,
		BorderSizePixel = 0, Visible = false, ZIndex = 3, Parent = card,
	})
	corner(badge, 9)
	local overlay = mk("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45,
		Text = "⏳", TextSize = 22, Visible = false, ZIndex = 6, Parent = card,
	})
	corner(overlay, 10)

	local obj = { card = card, item = item, loading = false, imgLoaded = false }
	function obj.loadImg()
		obj.imgLoaded = true
		img.Image = thumbURL(isBundle and "BundleThumbnail" or "Asset", item.Id, 150)
	end
	function obj.update(set)
		local worn = false
		if not isBundle then
			if set then
				worn = set[item.Id] == true
			else
				worn = E.isWorn(item.Id)
			end
		end
		badge.Text = "✓"
		badge.BackgroundColor3 = T.Ok
		badge.Visible = worn
		st.Color = worn and T.Ok or T.Stroke
		st.Transparency = worn and 0 or 0.3
	end
	obj.update()
	local paintHeart = addHeart(card, function() return FAV.items[FAV.itemKey(item)] ~= nil end, function() FAV.toggleItem(item) end)
	FAV.listen(function()
		if not card.Parent then
			return false
		end
		paintHeart()
	end)
	card.MouseEnter:Connect(function()
		tween(card, { BackgroundColor3 = T.Surface2 }, 0.12)
		if isBundle then
			E.prefetchBundle(item.Id)
		end
	end)
	card.MouseLeave:Connect(function() tween(card, { BackgroundColor3 = T.Surface }, 0.15) end)
	card.InputBegan:Connect(function(input)
		if isBundle and input.UserInputType == Enum.UserInputType.Touch then
			E.prefetchBundle(item.Id)
		end
	end)
	card.Activated:Connect(function()
		if isBundle then
			if obj.loading then
				return
			end
			obj.loading = true
			overlay.Visible = true
			E.loadingBundles = E.loadingBundles + 1
			task.spawn(E.equipBundle, item.Id, item.Name, function()
				overlay.Visible = false
				obj.loading = false
				E.loadingBundles = math.max(0, E.loadingBundles - 1)
			end, item.slot, item.slotName)
		else
			badge.Text = "⏳"
			badge.BackgroundColor3 = T.Warn
			badge.Visible = true
			E.pendingClicks = E.pendingClicks + 1
			task.spawn(E.toggleAsset, item.Id, item.Name, function()
				E.pendingClicks = math.max(0, E.pendingClicks - 1)
				obj.update()
			end)
		end
	end)
	return obj
end

-- satu halaman katalog untuk satu grup kategori (KARAKTER / TUBUH, ANIMASI, SEPATU)
local function buildCatalog(page, group)
	local cats = {}
	for _, c in ipairs(CATEGORIES) do
		if c.group == group then
			table.insert(cats, c)
		end
	end
	local st = { cat = cats[1], keyword = "", sortIdx = 1, freeOnly = false, token = 0 }
	local cards, loading, currentQuery = {}, false, nil

	-- baris kategori (chip, geser kiri-kanan)
	local chipBar = mk("ScrollingFrame", {
		Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(), ScrollingDirection = Enum.ScrollingDirection.X,
		Parent = page,
	})
	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center, Parent = chipBar,
	})

	-- baris cari | urut | gratis | refresh
	local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 32), BackgroundTransparency = 1, Parent = page })
	local sbFrame = mk("Frame", { Size = UDim2.new(1, -202, 1, 0), BackgroundColor3 = T.Surface, BorderSizePixel = 0, Parent = row })
	corner(sbFrame, 8)
	stroke(sbFrame, T.Stroke, 1)
	local sbBox = mk("TextBox", {
		Size = UDim2.new(1, -14, 1, 0), Position = UDim2.fromOffset(8, 0), BackgroundTransparency = 1, Text = "",
		PlaceholderText = "🔍 Cari (Enter)", PlaceholderColor3 = T.Dim, TextColor3 = T.Text, ClearTextOnFocus = false,
		TextSize = 12, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, Parent = sbFrame,
	})
	local startQuery
	sbBox.FocusLost:Connect(function(enter)
		if enter then
			st.keyword = sbBox.Text
			startQuery()
		end
	end)
	local sortBtn = button(row, { text = "↕ " .. SORTS[1].name, size = UDim2.fromOffset(84, 30), anchor = Vector2.new(1, 0),
		position = UDim2.new(1, -110, 0, 0), textSize = 10,
		onClick = function()
			st.sortIdx = st.sortIdx % #SORTS + 1
			startQuery()
		end })
	local freeBtn = button(row, { text = "Gratis", size = UDim2.fromOffset(52, 30), anchor = Vector2.new(1, 0),
		position = UDim2.new(1, -52, 0, 0), textSize = 11,
		onClick = function()
			st.freeOnly = not st.freeOnly
			startQuery()
		end })
	button(row, { text = "Ulang", size = UDim2.fromOffset(46, 30), anchor = Vector2.new(1, 0), position = UDim2.new(1, 0, 0, 0),
		textSize = 11, onClick = function() startQuery() end })

	-- grid
	local grid = makeScroll(page, UDim2.new(1, 0, 1, -68), UDim2.fromOffset(0, 68))
	mk("UIGridLayout", {
		CellSize = UDim2.fromOffset(84, 110), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = grid,
	})
	pad(grid, 0, 2, 0, 10)
	local msg = mk("TextLabel", {
		Size = UDim2.new(1, -16, 0, 90), Position = UDim2.fromOffset(8, 90), BackgroundTransparency = 1, Text = "",
		TextColor3 = T.Dim, TextSize = 12, Font = Enum.Font.GothamMedium, TextWrapped = true, Visible = false,
		ZIndex = 5, Parent = page,
	})

	local function clearGrid()
		msg.Visible = false
		cards = {}
		for _, c in ipairs(grid:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		grid.CanvasPosition = Vector2.new(0, 0)
	end
	local function showMsg(text)
		msg.Text = text
		msg.Visible = true
	end

	local function loadPage(token)
		if loading or not currentQuery or currentQuery.finished then
			return
		end
		loading = true
		local q = currentQuery
		local target = q.total + MAX_ITEMS
		task.spawn(function()
			while token == st.token and not q.finished and q.total < target do
				local items, err = q:nextPage()
				if token ~= st.token then
					return
				end
				if not items then
					logf("katalog gagal: %s", tostring(err))
					if q.total == 0 then
						showMsg("⚠ Gagal memuat katalog:\n" .. tostring(err))
					end
					break
				end
				msg.Visible = false
				for i, it in ipairs(items) do
					it.slot = st.cat.slot
					it.slotName = st.cat.name
					table.insert(cards, makeCard(grid, it))
					if i % 30 == 0 then
						task.wait()
						if token ~= st.token then
							return
						end
					end
				end
				if q.total == 0 then
					showMsg("🔎 Tidak ada hasil. Coba kata kunci lain atau matikan filter Gratis.")
					break
				end
			end
			if token == st.token then
				loading = false
			end
		end)
	end

	-- gambar kartu dimuat hanya yang dekat layar (supaya 1000 item tetap ringan)
	local function refreshImages()
		local top = grid.AbsolutePosition.Y
		local h = grid.AbsoluteWindowSize.Y
		if h <= 0 then
			return
		end
		for _, c in ipairs(cards) do
			if not c.imgLoaded and c.card.AbsoluteSize.Y > 0 then
				local y = c.card.AbsolutePosition.Y
				if y + 120 > top - 600 and y < top + h + 600 then
					c.loadImg()
				end
			end
			if c.item.Type == "Bundle" and not c.pf and c.card.AbsoluteSize.Y > 0 then
				local y = c.card.AbsolutePosition.Y
				if y + 120 > top and y < top + h + 120 then
					c.pf = true
					E.prefetchBundle(c.item.Id)
				end
			end
		end
	end
	task.spawn(function()
		while not stale() and page.Parent do
			task.wait(0.15)
			if page.Visible then
				pcall(refreshImages)
			end
		end
	end)

	startQuery = function()
		st.token = st.token + 1
		local token = st.token
		loading = false
		clearGrid()
		sortBtn.Text = "↕ " .. SORTS[st.sortIdx].name
		local fc = st.freeOnly and T.Ok or T.Surface2
		freeBtn.BackgroundColor3 = fc
		freeBtn:SetAttribute("Base", fc)
		freeBtn.Text = (st.freeOnly and "✓ " or "") .. "Gratis"
		showMsg("⏳ Memuat...")
		currentQuery = newQuery(st.cat, st.keyword, st.sortIdx, st.freeOnly)
		loadPage(token)
	end

	grid:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		if grid.CanvasPosition.Y + grid.AbsoluteWindowSize.Y >= grid.AbsoluteCanvasSize.Y - 600 then
			loadPage(st.token)
		end
	end)

	local chipRefs = {}
	local function markChips()
		for id, c in pairs(chipRefs) do
			local active = id == st.cat.id
			c.BackgroundColor3 = active and Theme.TabActiveBg or T.Surface2
			c.TextColor3 = active and T.Accent or T.Text
		end
	end
	local function selectCat(cat)
		st.cat = cat
		st.keyword = ""
		sbBox.Text = ""
		markChips()
		startQuery()
	end
	for i, cat in ipairs(cats) do
		local c = mk("TextButton", {
			Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = T.Surface2,
			BorderSizePixel = 0, Text = cat.name, TextSize = 11, Font = Enum.Font.GothamBold, TextColor3 = T.Text,
			AutoButtonColor = false, LayoutOrder = i, Parent = chipBar,
		})
		corner(c, 8)
		pad(c, 10, 0, 10, 0)
		chipRefs[cat.id] = c
		c.Activated:Connect(function()
			selectCat(cat)
		end)
	end

	selectCat(cats[1])
	return function()
		local set = collect(E.look)
		for _, c in ipairs(cards) do
			c.update(set)
		end
	end
end

----------------------------------------------------------------------------
-- [9] KARTU PEMAIN + PENCARIAN (halaman AVATAR)
----------------------------------------------------------------------------
local PRESETS = { { "Roblox", 1 }, { "builderman", 156 }, { "Shedletsky", 261 }, { "Aku (asli)", player.UserId } }

-- apakah GUI benar-benar terlihat (semua induk Visible)
local function UI_SHOWN(g)
	while g and g:IsA("GuiObject") do
		if not g.Visible then
			return false
		end
		g = g.Parent
	end
	return g ~= nil
end

local function userCard(parent, userId, name, order, sub)
	local card = mk("TextButton", { BackgroundColor3 = T.Surface, BorderSizePixel = 0, AutoButtonColor = false, Text = "", LayoutOrder = order or 0, Parent = parent })
	corner(card, 10)
	local img = mk("ImageLabel", { Size = UDim2.fromOffset(54, 54), Position = UDim2.new(0.5, -27, 0, 5), BackgroundColor3 = T.Surface2,
		BorderSizePixel = 0, Parent = card })
	corner(img, 27)
	-- foto profil: ukuran kecil (cepat) + preload paralel + huruf pengganti selagi memuat
	local initial = mk("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		Text = string.upper(string.sub(tostring(name), 1, 1)), TextColor3 = T.Dim, TextSize = 20, Font = Enum.Font.GothamBold, Parent = img })
	img.Image = thumbURL("AvatarHeadShot", userId, 100)
	img:GetPropertyChangedSignal("IsLoaded"):Connect(function()
		if img.IsLoaded then
			initial.Visible = false
		end
	end)
	E.preloadImg(img)
	task.spawn(function()
		-- cadangan: kalau belum jadi, ulangi dengan ukuran lain
		local sizes = { 150, 60, 180, 100, 352 }
		local tries, lastSet = 0, os.clock()
		while img.Parent and not img.IsLoaded and tries < #sizes do
			task.wait(0.5)
			if img.Parent and not img.IsLoaded then
				if UI_SHOWN(img) then
					if os.clock() - lastSet > 2.5 then
						tries = tries + 1
						img.Image = thumbURL("AvatarHeadShot", userId, sizes[tries])
						lastSet = os.clock()
						E.preloadImg(img)
					end
				else
					lastSet = os.clock() -- tab tersembunyi: tunggu sampai terlihat
				end
			end
		end
		if img.IsLoaded then
			initial.Visible = false
		end
	end)
	local nm = label(card, name, 11, T.Text, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
	nm.Position = UDim2.fromOffset(3, 61)
	nm.Size = UDim2.new(1, -6, 0, 14)
	nm.TextTruncate = Enum.TextTruncate.AtEnd
	local idleText = sub or "klik untuk pakai"
	local hint = label(card, idleText, 9, T.Dim, Enum.Font.Gotham, Enum.TextXAlignment.Center)
	hint.Position = UDim2.fromOffset(3, 76)
	hint.Size = UDim2.new(1, -6, 0, 12)
	hint.TextTruncate = Enum.TextTruncate.AtEnd
	hint.Name = "HintLbl"
	card:SetAttribute("Idle", idleText)

	local paintHeart = addHeart(card, function() return FAV.avatars[tostring(userId)] ~= nil end, function() FAV.toggleAvatar(userId, name) end)
	FAV.listen(function()
		if not card.Parent then
			return false
		end
		paintHeart()
	end)

	local hoverTok = 0
	card.MouseEnter:Connect(function()
		tween(card, { BackgroundColor3 = T.Surface2 }, 0.12)
		if userId ~= player.UserId then
			hoverTok = hoverTok + 1
			local t = hoverTok
			task.delay(0.05, function()
				if t == hoverTok then
					E.prefetchUser(userId)
				end
			end)
		end
	end)
	card.MouseLeave:Connect(function()
		hoverTok = hoverTok + 1
		tween(card, { BackgroundColor3 = T.Surface }, 0.15)
	end)
	card.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch and userId ~= player.UserId then
			E.prefetchUser(userId)
		end
	end)

	local busyCard = false
	card.Activated:Connect(function()
		if busyCard then
			return
		end
		busyCard = true
		local t0 = os.clock()
		task.spawn(function()
			while busyCard do
				hint.Text = string.format("memuat %.1f dtk", os.clock() - t0)
				task.wait(0.1)
			end
		end)
		task.spawn(function()
			local ok = true
			if userId == player.UserId then
				E.reset()
			else
				ok = E.applyUser(userId, name)
			end
			busyCard = false
			hint.Text = ok and string.format("✓ %.1f dtk", os.clock() - t0) or (card:GetAttribute("Idle") or idleText)
			task.delay(1.5, function()
				if card.Parent and not busyCard then
					hint.Text = card:GetAttribute("Idle") or idleText
				end
			end)
		end)
	end)
	return card
end

local function nameFromId(uid)
	local ok, n = callAny(Players, { "GetNameFromUserIdAsync" }, uid)
	if ok and type(n) == "string" then
		return n
	end
	return nil
end

local function idFromName(name)
	local ok, id = callAny(Players, { "GetUserIdFromNameAsync" }, name)
	if ok and type(id) == "number" and id > 0 then
		return id
	end
	return nil
end

local SESSION_ID = "leon-" .. tostring(os.time())
pcall(function()
	SESSION_ID = HttpService:GenerateGUID(false)
end)

local SEARCH_BUILDERS = {
	function(kw, cur)
		return "https://users.roblox.com/v1/users/search?keyword=" .. urlenc(kw) .. "&limit=25" .. (cur and ("&cursor=" .. urlenc(cur)) or "")
	end,
	function(kw, cur)
		return "https://users.roproxy.com/v1/users/search?keyword=" .. urlenc(kw) .. "&limit=25" .. (cur and ("&cursor=" .. urlenc(cur)) or "")
	end,
	function(kw, cur)
		return "https://apis.roblox.com/search-api/omni-search?searchQuery=" .. urlenc(kw) .. "&pageType=all&sessionId="
			.. urlenc(SESSION_ID) .. (cur and ("&pageToken=" .. urlenc(cur)) or "")
	end,
}

local function parseUserList(bodyTxt)
	local ok, data = pcall(function()
		return HttpService:JSONDecode(bodyTxt)
	end)
	if not ok or type(data) ~= "table" then
		return nil
	end
	local out = {}
	if type(data.data) == "table" then
		for _, u in ipairs(data.data) do
			if tonumber(u.id) then
				table.insert(out, { id = tonumber(u.id), name = tostring(u.name), display = tostring(u.displayName or u.name) })
			end
		end
		return out, data.nextPageCursor
	end
	if type(data.searchResults) == "table" then
		for _, grp in ipairs(data.searchResults) do
			if type(grp.contents) == "table" then
				for _, c in ipairs(grp.contents) do
					if (c.contentType == "User" or grp.contentGroupType == "User") and tonumber(c.contentId) then
						table.insert(out, {
							id = tonumber(c.contentId), name = tostring(c.username or c.contentId),
							display = tostring(c.displayName or c.username or c.contentId),
						})
					end
				end
			end
		end
		return out, data.nextPageToken
	end
	return nil
end

-- 3 backend diadu bersamaan untuk halaman pertama (yang tercepat dipakai); halaman berikutnya pakai backend yang sama
local function searchUsersWeb(keyword, state)
	state = state or {}
	if state.idx then
		local bodyTxt, err = httpGet(SEARCH_BUILDERS[state.idx](keyword, state.cursor))
		if bodyTxt then
			local list, nextCur = parseUserList(bodyTxt)
			if list then
				return list, { idx = state.idx, cursor = nextCur }
			end
			return nil, "balasan tidak dikenali"
		end
		return nil, tostring(err)
	end
	local result, left, lastErr = nil, #SEARCH_BUILDERS, "tidak ada hasil"
	for i = 1, #SEARCH_BUILDERS do
		task.spawn(function()
			local bodyTxt, err = httpGet(SEARCH_BUILDERS[i](keyword, nil))
			if bodyTxt then
				local list, nextCur = parseUserList(bodyTxt)
				if list and #list > 0 and not result then
					result = { list, { idx = i, cursor = nextCur } }
				elseif not list then
					lastErr = "balasan backend " .. i .. " tidak dikenali"
				end
			else
				lastErr = tostring(err)
			end
			left = left - 1
		end)
	end
	local t0 = os.clock()
	while not result and left > 0 and os.clock() - t0 < 10 do
		task.wait(0.03)
	end
	if result then
		return result[1], result[2]
	end
	return nil, lastErr
end

local function buildAvatars(page)
	local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Parent = page })
	local sbFrame = mk("Frame", { Size = UDim2.new(1, -120, 1, 0), BackgroundColor3 = T.Surface, BorderSizePixel = 0, Parent = row })
	corner(sbFrame, 8)
	stroke(sbFrame, T.Stroke, 1)
	local box = mk("TextBox", {
		Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1, Text = "",
		PlaceholderText = "🔍 Username / nama / UserId", PlaceholderColor3 = T.Dim, TextColor3 = T.Text,
		ClearTextOnFocus = false, TextSize = 12, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left,
		Parent = sbFrame,
	})
	local searchBtn = button(row, { text = "Cari", size = UDim2.fromOffset(60, 30), anchor = Vector2.new(1, 0),
		position = UDim2.new(1, -50, 0, 0), bg = T.Accent, textSize = 12 })
	local randBtn = button(row, { text = "Acak", size = UDim2.fromOffset(44, 30), anchor = Vector2.new(1, 0),
		position = UDim2.new(1, 0, 0, 0), textSize = 11 })

	local status = label(page, "", 10, T.Dim, Enum.Font.Gotham, Enum.TextXAlignment.Right)
	status.Position = UDim2.fromOffset(248, 34)
	status.Size = UDim2.new(1, -248, 0, 24)
	status.TextTruncate = Enum.TextTruncate.AtEnd
	local chipRow = mk("Frame", { Size = UDim2.new(0, 240, 0, 24), Position = UDim2.fromOffset(0, 34), BackgroundTransparency = 1, ZIndex = 2, Parent = page })
	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = chipRow,
	})

	-- baris filter urutan (hanya untuk tab "Semua"): item terbanyak / cowo / cewe
	local sortMode = "most" -- "most" | "cowo" | "cewe"
	local entries, seqN = {}, 0
	local modeRow = mk("Frame", { Size = UDim2.new(1, 0, 0, 24), Position = UDim2.fromOffset(0, 62), BackgroundTransparency = 1, ZIndex = 2, Parent = page })
	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = modeRow,
	})
	local modeChips = {}
	local MODE_DEFS = { { "most", "🏆 Item terbanyak" }, { "cowo", "♂ Cowo" }, { "cewe", "♀ Cewe" } }
	local function markModes()
		for k, c in pairs(modeChips) do
			local active = k == sortMode
			c.BackgroundColor3 = active and Theme.TabActiveBg or T.Surface2
			c.TextColor3 = active and T.Accent or T.Text
		end
	end
	for i, d in ipairs(MODE_DEFS) do
		local c = mk("TextButton", {
			Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = T.Surface2,
			BorderSizePixel = 0, Text = d[2], TextSize = 11, Font = Enum.Font.GothamBold, TextColor3 = T.Text,
			AutoButtonColor = false, LayoutOrder = i, Parent = modeRow,
		})
		corner(c, 8)
		pad(c, 10, 0, 10, 0)
		modeChips[d[1]] = c
	end
	markModes()

	local secs, chips = {}, {}
	local function makeSection(key)
		local sc = makeScroll(page, UDim2.new(1, 0, 1, -64), UDim2.fromOffset(0, 64))
		mk("UIGridLayout", {
			CellSize = UDim2.fromOffset(84, 96), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = sc,
		})
		pad(sc, 0, 2, 0, 10)
		sc.Visible = false
		secs[key] = sc
		return sc
	end
	local allSc = makeSection("all")
	allSc.Position = UDim2.fromOffset(0, 90)
	allSc.Size = UDim2.new(1, 0, 1, -90)
	local presetSc = makeSection("preset")
	local serverSc = makeSection("server")
	local friendSc = makeSection("friends")

	local refreshServer, loadFriends
	local function showSection(key)
		for k, sc in pairs(secs) do
			sc.Visible = k == key
		end
		for k, c in pairs(chips) do
			c.BackgroundColor3 = (k == key) and T.Accent or T.Surface2
		end
		status.Visible = key == "all"
		modeRow.Visible = key == "all"
		if key == "server" and refreshServer then
			refreshServer()
		elseif key == "friends" and loadFriends then
			loadFriends()
		end
	end
	local chipDefs = { { "all", "Semua" }, { "preset", "Preset" }, { "server", "Server" }, { "friends", "Teman" } }
	for i, d in ipairs(chipDefs) do
		local c = mk("TextButton", {
			Size = UDim2.fromOffset(58, 24), BackgroundColor3 = T.Surface2, BorderSizePixel = 0, Text = d[2], TextSize = 11,
			Font = Enum.Font.GothamBold, TextColor3 = T.Text, AutoButtonColor = false, LayoutOrder = i, Parent = chipRow,
		})
		corner(c, 8)
		chips[d[1]] = c
		c.Activated:Connect(function()
			showSection(d[1])
		end)
	end

	-- ===== SEMUA PEMAIN ROBLOX (bacon & bacon cewe disaring, urut item terbanyak) =====
	local token, loading, mode, searchState, keyword = 0, false, "feed", nil, ""
	local count, seen = 0, {}

	local function setStatus(t)
		status.Text = t
	end
	local function clearAll()
		for _, c in ipairs(allSc:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		allSc.CanvasPosition = Vector2.new(0, 0)
		count, seen = 0, {}
		entries, seqN = {}, 0
	end
	-- mode "most": hanya avatar dengan item >= MOST_MIN_ITEMS. mode cowo/cewe: hanya yang gendernya pasti cocok
	local function visibleFor(g, cnt, pending)
		if pending then
			return sortMode == "most"
		end
		if sortMode == "most" then
			return (cnt or 0) >= MOST_MIN_ITEMS
		end
		return g == sortMode
	end
	local function countVisible()
		local n = 0
		for _, e in pairs(entries) do
			if e.card and e.card.Parent and visibleFor(e.gender, e.count, e.pending) then
				n = n + 1
			end
		end
		return n
	end
	-- info (opsional): { count = jumlah item, gender = "cowo"/"cewe"/nil } -> dipakai untuk urutan + filter
	local function addUser(id, name, sub, front, info)
		if seen[id] then
			return false
		end
		seen[id] = true
		count = count + 1
		local ord = front and (-1000 + count) or count
		local e
		if info then
			seqN = seqN + 1
			e = { count = info.count or 0, gender = info.gender, seq = seqN, pending = info.pending, name = name }
			ord = -(e.count) * 100000 + e.seq
		end
		local card = userCard(allSc, id, name, ord, sub)
		if e then
			e.card = card
			entries[id] = e
			card.Visible = visibleFor(e.gender, e.count, e.pending)
		end
		return true
	end
	-- urutkan ulang kartu sesuai mode: terbanyak di atas, cowo/cewe hanya yang cocok
	local function applyMode()
		for _, e in pairs(entries) do
			if e.card and e.card.Parent then
				e.card.Visible = visibleFor(e.gender, e.count, e.pending)
				e.card.LayoutOrder = -(e.count) * 100000 + e.seq
			end
		end
		allSc.CanvasPosition = Vector2.new(0, 0)
	end

	-- hasil pencarian: tampilkan semua (tidak disaring, bacon / bacon cewe tetap muncul di sini)
	local function addAll(list, myToken)
		for _, u in ipairs(list) do
			if myToken ~= token then
				return
			end
			addUser(u.id, u.display, "@" .. u.name)
		end
	end

	local tried = {}

	-- ===== POOL KANDIDAT (jalur cepat) =====
	-- Dipakai duluan: teman akun ini, pemain di server, lalu teman-dari-teman avatar yang lolos filter.
	-- Hampir semuanya akun asli + nama sudah ada (tanpa tebak ID acak yang banyak kosong), jadi kartu muncul jauh lebih cepat.
	local pool, poolSeen, expanded, expanding = {}, {}, {}, 0
	local feedConc = 24

	local function poolPush(id, name)
		id = tonumber(id)
		if not id or poolSeen[id] or tried[id] or #pool > 1500 then
			return
		end
		poolSeen[id] = true
		pool[#pool + 1] = { id = id, name = tostring(name or "") }
	end
	local function poolPop()
		local n = #pool
		if n == 0 then
			return nil
		end
		local i = math.random(1, n)
		local v = pool[i]
		pool[i] = pool[n]
		pool[n] = nil
		return v
	end
	local function expandFriends(uid, force)
		if expanded[uid] or (not force and (expanding >= 6 or #pool > 600)) then
			return
		end
		expanded[uid] = true
		expanding = expanding + 1
		task.spawn(function()
			local ok, pages = pcall(function()
				return Players:GetFriendsAsync(uid)
			end)
			local n = 0
			while ok and pages and n < 3 do
				n = n + 1
				local okP, cur = pcall(function()
					return pages:GetCurrentPage()
				end)
				if okP and type(cur) == "table" then
					for _, f in ipairs(cur) do
						poolPush(f.Id, f.DisplayName or f.Username)
					end
				end
				if pages.IsFinished or not pcall(function() pages:AdvanceToNextPageAsync() end) then
					break
				end
			end
			expanding = expanding - 1
		end)
	end
	local function seedPool()
		local n = 0
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player then
				poolPush(p.UserId, p.DisplayName)
				if n < 6 then
					n = n + 1
					expandFriends(p.UserId, true)
				end
			end
		end
		expandFriends(player.UserId, true)
	end

	local function setSub(card, text)
		card:SetAttribute("Idle", text)
		local h = card:FindFirstChild("HintLbl")
		if h and h.Text ~= "memuat..." then
			h.Text = text
		end
	end
	local function genderSym(g)
		return (g == "cewe" and "♀") or (g == "cowo" and "♂") or "•"
	end

	-- deklarasi awal: dipakai feedBatchRandom, diisi di bagian pipeline di bawah
	local queueGender

	-- kartu langsung tampil begitu lolos filter bacon; gender dihitung menyusul di latar belakang (batch paralel)
	local function feedBatchRandom(myToken, n)
		loading = true
		setStatus("Memuat pemain Roblox...")
		local found, attempts, inflight, throttled = 0, 0, 0, 0
		local maxAttempts = n * 40
		while myToken == token and found < n and attempts < maxAttempts do
			if throttled >= 5 then
				setStatus("Roblox membatasi permintaan, menunggu...")
				feedConc = math.max(8, feedConc - 6)
				task.wait(2)
				throttled = 0
			end
			while myToken == token and inflight < feedConc and found < n and attempts < maxAttempts do
				attempts = attempts + 1
				inflight = inflight + 1
				task.spawn(function()
					local cand = (math.random() < 0.92) and poolPop() or nil
					local id = cand and cand.id or (math.floor(math.random() * 5000000000) + 100000)
					if not tried[id] then
						tried[id] = true
						-- cek avatar dulu (gagal cepat untuk akun tidak ada / bacon), nama hanya untuk yang lolos
						local desc, derr = descFromUser(id)
						if desc then
							local a = analyzeDesc(desc)
							local plain = FILTER_POLOSAN and a.plain or false
							if plain then
								pcall(function()
									desc:Destroy()
								end)
							else
								E.cacheDesc(id, desc)
							end
							if not a.unsure then
								plainCache[id] = plain
							end
							if not plain and myToken == token then
								expandFriends(id)
								local nm = (cand and cand.name ~= "" and cand.name) or nil
								if not nm then
									nm = nameFromId(id)
								end
								if nm and myToken == token then
									analysisCache[id] = a
									if addUser(id, nm, a.count .. " item •", nil, { count = a.count, gender = nil }) then
										found = found + 1
										local e = entries[id]
										if e then
											e.a = a
										end
										queueGender(id)
										setStatus(countVisible() .. " pemain • memuat...")
									end
								end
							end
						else
							local sErr = string.lower(tostring(derr))
							if sErr:find("429") or sErr:find("too many") or sErr:find("throttl") or sErr:find("limit") then
								throttled = throttled + 1
							end
						end
					end
					inflight = inflight - 1
				end)
			end
			task.wait(0.03)
		end
		local t0 = os.clock()
		while inflight > 0 and os.clock() - t0 < 1.5 and myToken == token do
			task.wait(0.05)
		end
		if myToken == token then
			loading = false
			local vis = countVisible()
			if found == 0 and vis == 0 then
				setStatus("Belum ketemu avatar yang cocok, tekan Acak / gulir")
			else
				setStatus(vis .. " pemain • gulir untuk lagi")
			end
		end
	end

	-- ===== PIPELINE CEPAT: kartu tampil dulu, dicek di latar belakang =====
	local aQueue, aWorkers = {}, 0
	local gQueue, gWorkers = {}, 0

	-- gender: 6 pekerja, tiap pekerja mengambil detail item banyak avatar sekaligus (1 panggilan batch)
	local function genderPump()
		while gWorkers < 6 and #gQueue > 0 do
			gWorkers = gWorkers + 1
			task.spawn(function()
				while #gQueue > 0 and not stale() do
					local batch, ids, idSeen = {}, {}, {}
					while #gQueue > 0 and #batch < 8 do
						local id = table.remove(gQueue, 1)
						local e = entries[id]
						if e and e.a and not e.gdone and e.card and e.card.Parent then
							e.gdone = true
							batch[#batch + 1] = id
							for _, iid in ipairs(e.a.ids) do
								if not idSeen[iid] and itemInfo[iid] == nil then
									idSeen[iid] = true
									ids[#ids + 1] = iid
								end
							end
						end
					end
					if #ids > 0 then
						pcall(ensureDetails, ids) -- 1 panggilan untuk banyak avatar
					end
					for _, id in ipairs(batch) do
						local e = entries[id]
						if e and e.card and e.card.Parent then
							e.gender = genderOf(e.a)
							e.a.gender = e.gender
							e.card.Visible = visibleFor(e.gender, e.count, e.pending)
							setSub(e.card, e.count .. " item " .. genderSym(e.gender))
						end
					end
				end
				gWorkers = gWorkers - 1
			end)
		end
	end
	queueGender = function(id)
		table.insert(gQueue, id)
		genderPump()
	end

	local function settleEntry(id, a)
		local e = entries[id]
		if not e or not e.card or not e.card.Parent then
			return
		end
		if FILTER_POLOSAN and a.plain then
			e.card:Destroy()
			entries[id] = nil
			return
		end
		e.pending, e.count, e.a = false, a.count, a
		if a.gender ~= nil then
			e.gender, e.gdone = a.gender, true
		end
		e.card.LayoutOrder = -(a.count) * 100000 + e.seq
		e.card.Visible = visibleFor(e.gender, e.count, false)
		setSub(e.card, a.count .. " item " .. genderSym(e.gender))
		expandFriends(id)
		if not e.gdone then
			queueGender(id)
		end
	end

	local function analyzeWorker(myToken)
		while myToken == token do
			local id = table.remove(aQueue, 1)
			if not id then
				break
			end
			local a = analysisCache[id]
			if not a then
				local desc, derr = descFromUser(id)
				if desc then
					a = analyzeDesc(desc)
					if not a.unsure then
						analysisCache[id] = a
						plainCache[id] = a.plain
					end
					if a.plain then
						pcall(function()
							desc:Destroy()
						end)
					else
						E.cacheDesc(id, desc) -- klik nanti tidak perlu download lagi
					end
				else
					local s = string.lower(tostring(derr))
					if s:find("429") or s:find("too many") or s:find("throttl") or s:find("limit") then
						table.insert(aQueue, id)
						feedConc = math.max(8, feedConc - 4)
						task.wait(1.5)
					else
						local e = entries[id]
						if e and e.card then
							e.card:Destroy()
						end
						entries[id] = nil
					end
				end
			end
			if a and myToken == token then
				settleEntry(id, a)
				setStatus(countVisible() .. " pemain • gulir untuk lagi")
			end
		end
		aWorkers = aWorkers - 1
	end
	local function pumpAnalysis(myToken)
		while aWorkers < feedConc and #aQueue > 0 do
			aWorkers = aWorkers + 1
			task.spawn(analyzeWorker, myToken)
		end
	end

	local function feedBatch(myToken, n)
		if myToken ~= token then
			return
		end
		local added, guard = 0, 0
		while added < n and #pool > 0 and guard < n * 4 do
			guard = guard + 1
			local c = poolPop()
			if c and not tried[c.id] then
				tried[c.id] = true
				local nm = (c.name ~= "" and c.name) or tostring(c.id)
				if addUser(c.id, nm, "memeriksa...", nil, { count = 0, pending = true }) then
					added = added + 1
					table.insert(aQueue, c.id)
					if added % 40 == 0 then
						pumpAnalysis(myToken)
						task.wait()
						if myToken ~= token then
							return
						end
					end
				end
			end
		end
		pumpAnalysis(myToken)
		if added == 0 and #pool == 0 and not loading then
			task.spawn(feedBatchRandom, myToken, 8)
		end
		setStatus(countVisible() .. " pemain • memeriksa...")
	end

	-- ===== CONFIG: pulihkan daftar avatar dari file (langsung tampil tanpa dicek ulang) =====
	local function restoreFeed(myToken)
		local list = avLoad()
		local n = 0
		for _, r in ipairs(list) do
			if myToken ~= token then
				return n
			end
			local id, cnt = tonumber(r.id), tonumber(r.count)
			if id and cnt and r.name and not seen[id] then
				tried[id] = true
				plainCache[id] = false
				if addUser(id, tostring(r.name), cnt .. " item " .. genderSym(r.gender), nil, { count = cnt, gender = r.gender }) then
					n = n + 1
					if n % 40 == 0 then
						task.wait()
					end
				end
			end
		end
		return n
	end

	local function startFeed(keep)
		token = token + 1
		local myToken = token
		clearAll()
		mode, searchState, keyword = "feed", nil, ""
		feedConc = FEED_CONC
		aQueue, gQueue = {}, {}
		showSection("all")
		local restoredN = 0
		if keep then
			restoredN = restoreFeed(myToken)
			if restoredN > 0 and myToken == token then
				setStatus(countVisible() .. " pemain (tersimpan) • memuat lagi...")
			end
		end
		seedPool()
		task.spawn(function()
			local t0 = os.clock()
			while myToken == token and restoredN == 0 and #pool < 20 and os.clock() - t0 < 1.5 do
				task.wait(0.05)
			end
			feedBatch(myToken, restoredN > 0 and 40 or FEED_FIRST)
			-- pengisi otomatis: jaga minimal FEED_KEEP kartu tampil dan terus berlanjut
			while myToken == token and mode == "feed" and not stale() do
				task.wait(0.3)
				if count < 900 and countVisible() < FEED_KEEP then
					if #pool > 0 then
						feedBatch(myToken, sortMode ~= "most" and 90 or 50)
					elseif not loading then
						task.spawn(feedBatchRandom, myToken, 8)
					end
				end
				if #pool < 60 then
					local n = 0
					for id in pairs(entries) do
						if n >= 3 then
							break
						end
						if not expanded[id] then
							expandFriends(id, true)
							n = n + 1
						end
					end
				end
			end
		end)
	end

	local function setSortMode(m)
		if sortMode == m then
			return
		end
		sortMode = m
		markModes()
		if m ~= "most" then
			for id, e in pairs(entries) do
				if e.a and not e.gdone then
					queueGender(id)
				end
			end
		end
		if mode == "feed" then
			applyMode()
			local vis = countVisible()
			setStatus(vis .. " pemain • gulir untuk lagi")
			if vis < 12 and not loading then
				task.spawn(feedBatch, token, 12)
			end
		else
			startFeed(true)
		end
	end
	for k, c in pairs(modeChips) do
		c.Activated:Connect(function()
			setSortMode(k)
		end)
	end

	local function doSearch()
		local kw = box.Text:match("^%s*(.-)%s*$")
		if kw == "" then
			startFeed(true)
			return
		end
		token = token + 1
		local myToken = token
		clearAll()
		mode, searchState, keyword, loading = "search", nil, kw, true
		showSection("all")
		setStatus("Mencari \"" .. kw .. "\"...")
		local jobs, errMsg = 2, nil
		local function jobDone()
			jobs = jobs - 1
			if jobs == 0 and myToken == token then
				loading = false
				if count > 0 then
					setStatus(count .. " pemain" .. ((searchState and searchState.cursor) and "+" or "") .. " hasil")
				else
					setStatus("⚠ " .. string.sub(tostring(errMsg or "tidak ada hasil"), 1, 60))
				end
			end
		end
		task.spawn(function() -- hasil persis (paralel)
			pcall(function()
				local exactId = tonumber(kw)
				local exactName
				if exactId then
					exactName = nameFromId(exactId)
				else
					exactId = idFromName(kw)
					if exactId then
						exactName = nameFromId(exactId) or kw
					end
				end
				if exactId and exactName and myToken == token then
					addUser(exactId, exactName, "ID " .. exactId, true) -- hasil persis tidak disaring
					E.prefetchUser(exactId)
				end
			end)
			jobDone()
		end)
		task.spawn(function() -- pencarian luas (paralel)
			local list, st = searchUsersWeb(kw, nil)
			if myToken == token then
				if list then
					searchState = st
					addAll(list, myToken)
					for i = 1, math.min(6, #list) do
						E.prefetchBg(list[i].id)
					end
				else
					errMsg = st
				end
			end
			jobDone()
		end)
	end

	local function loadMore()
		if loading then
			return
		end
		local myToken = token
		if mode == "feed" then
			task.spawn(feedBatch, myToken, FEED_MORE)
		elseif mode == "search" and searchState and searchState.cursor then
			loading = true
			task.spawn(function()
				local list, st = searchUsersWeb(keyword, searchState)
				if myToken ~= token then
					return
				end
				if list then
					searchState = st
					addAll(list, myToken)
					if myToken ~= token then
						return
					end
					setStatus(count .. " pemain" .. (st.cursor and "+" or "") .. " hasil")
				else
					searchState = nil
				end
				loading = false
			end)
		end
	end

	allSc:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		if allSc.Visible and allSc.CanvasPosition.Y + allSc.AbsoluteWindowSize.Y >= allSc.AbsoluteCanvasSize.Y - 120 then
			loadMore()
		end
	end)
	searchBtn.Activated:Connect(doSearch)
	box.FocusLost:Connect(function(enter)
		if enter then
			doSearch()
		end
	end)
	randBtn.Activated:Connect(function()
		box.Text = ""
		startFeed(false)
	end)

	-- ===== PRESET =====
	for i, p in ipairs(PRESETS) do
		userCard(presetSc, p[2], p[1], i, p[2] == player.UserId and "avatar asli" or nil)
	end

	-- ===== DAFTAR SERVER & TEMAN: dimuat sejak awal, kartu langsung tampil =====
	local listCards = { server = {}, friends = {} }
	local listCount = { server = 0, friends = 0 }
	local listSc = { server = serverSc, friends = friendSc }
	local listInfo = {}
	local listState = { server = "", friends = "Memuat teman..." }
	local listSeq = 0

	local function syncInfo(key)
		local lbl = listInfo[key]
		if not lbl then
			return
		end
		lbl.Text = listState[key]
		lbl.Visible = listSc[key].Visible and listCount[key] == 0 and listState[key] ~= ""
	end
	for key, sc in pairs(listSc) do
		listInfo[key] = mk("TextLabel", {
			Size = UDim2.new(1, -16, 0, 30), Position = UDim2.fromOffset(8, 72), BackgroundTransparency = 1, Text = "",
			TextColor3 = T.Dim, TextSize = 12, Font = Enum.Font.GothamMedium, TextWrapped = true, Visible = false,
			ZIndex = 5, Parent = page,
		})
		sc:GetPropertyChangedSignal("Visible"):Connect(function()
			syncInfo(key)
		end)
	end

	-- pemeriksa bacon di latar belakang (server didahulukan, paralel, hasil dicache)
	local checkQ, checkWorkers = {}, 0
	local function dropCard(key, id)
		local c = listCards[key][id]
		if c then
			listCards[key][id] = nil
			listCount[key] = listCount[key] - 1
			if c.Parent then
				c:Destroy()
			end
			syncInfo(key)
		end
	end
	local function checkWorker()
		while #checkQ > 0 and not stale() do
			local job = table.remove(checkQ, 1)
			local key, id = job[1], job[2]
			if listCards[key][id] then
				local plain
				if plainCache[id] ~= nil then
					plain = plainCache[id]
				else
					local desc, derr = descFromUser(id)
					if desc then
						local a = analyzeDesc(desc)
						if not a.unsure then
							plainCache[id] = a.plain
							analysisCache[id] = a
						end
						plain = a.plain and not a.unsure -- info gagal dimuat -> jangan disembunyikan
						if plain then
							pcall(function()
								desc:Destroy()
							end)
						else
							E.cacheDesc(id, desc)
						end
					else
						local se = string.lower(tostring(derr))
						if se:find("429") or se:find("too many") or se:find("throttl") or se:find("limit") then
							table.insert(checkQ, job)
							task.wait(1.5)
						end
					end
				end
				if plain then
					dropCard(key, id)
				end
			end
		end
		checkWorkers = checkWorkers - 1
	end
	local function queueCheck(key, id)
		if not FILTER_POLOSAN then
			return
		end
		local job = { key, id }
		if key == "server" then
			table.insert(checkQ, 1, job)
		else
			table.insert(checkQ, job)
		end
		while checkWorkers < 20 and #checkQ > 0 do
			checkWorkers = checkWorkers + 1
			task.spawn(checkWorker)
		end
	end

	local function listAdd(key, id, name)
		if listCards[key][id] then
			return
		end
		listSeq = listSeq + 1
		listCards[key][id] = userCard(listSc[key], id, name, listSeq)
		listCount[key] = listCount[key] + 1
		syncInfo(key)
		queueCheck(key, id)
	end

	-- ===== PEMAIN DI SERVER (live: ikut berubah saat ada yang masuk / keluar) =====
	listState.server = "Tidak ada pemain lain di server ini."
	local function addServerPlayer(p)
		if p ~= player and not stale() then
			listAdd("server", p.UserId, p.DisplayName)
		end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		addServerPlayer(p)
	end
	Players.PlayerAdded:Connect(addServerPlayer)
	Players.PlayerRemoving:Connect(function(p)
		if not stale() then
			dropCard("server", p.UserId)
		end
	end)
	refreshServer = function()
		syncInfo("server")
	end

	-- ===== TEMAN (dimuat di latar belakang sejak script jalan, bukan saat tab dibuka) =====
	loadFriends = function()
		syncInfo("friends")
	end
	task.spawn(function()
		local ok, pages = pcall(function()
			return Players:GetFriendsAsync(player.UserId)
		end)
		if not ok or not pages then
			listState.friends = "Daftar teman tidak bisa dimuat."
			syncInfo("friends")
			return
		end
		local n = 0
		while not stale() and n < 4 do
			n = n + 1
			local okP, cur = pcall(function()
				return pages:GetCurrentPage()
			end)
			if okP and type(cur) == "table" then
				for i, f in ipairs(cur) do
					listAdd("friends", f.Id, f.DisplayName or f.Username)
					if i % 40 == 0 then
						task.wait()
					end
				end
			end
			if pages.IsFinished or not pcall(function() pages:AdvanceToNextPageAsync() end) then
				break
			end
		end
		listState.friends = "Belum ada teman di akun ini."
		syncInfo("friends")
	end)

	-- ===== CONFIG: simpan daftar avatar ke file secara berkala (hanya saat mode feed, bukan hasil pencarian) =====
	local savedSig = ""
	task.spawn(function()
		while not stale() and page.Parent do
			task.wait(5)
			if mode == "feed" then
				local list, g = {}, 0
				for id, e in pairs(entries) do
					if e.card and e.card.Parent and not e.pending and (e.count or 0) > 0 and e.name then
						list[#list + 1] = { id = id, name = e.name, count = e.count, gender = e.gender, seq = e.seq }
						if e.gender then
							g = g + 1
						end
					end
				end
				local sig = #list .. ":" .. g
				if #list >= 5 and sig ~= savedSig then
					savedSig = sig
					table.sort(list, function(a, b)
						if a.count ~= b.count then
							return a.count > b.count
						end
						return a.seq < b.seq
					end)
					while #list > AV_SAVE_MAX do
						list[#list] = nil
					end
					for _, r in ipairs(list) do
						r.seq = nil
					end
					avSave(list)
				end
			end
		end
	end)

	-- ===== PREFETCH: 8 avatar paling atas yang terlihat disiapkan lebih dulu, jadi klik langsung terpasang =====
	task.spawn(function()
		while not stale() and page.Parent do
			task.wait(1)
			if not E.remote and UI_SHOWN(allSc) then
				local top = allSc.AbsolutePosition.Y
				local h = allSc.AbsoluteWindowSize.Y
				local vis = {}
				for id, e in pairs(entries) do
					local c = e.card
					if c and c.Parent and c.Visible and not e.pending then
						local pos = c.AbsolutePosition
						if pos.Y >= top - 20 and pos.Y < top + h then
							vis[#vis + 1] = { id = id, y = pos.Y, x = pos.X }
						end
					end
				end
				table.sort(vis, function(a, b)
					if math.abs(a.y - b.y) > 5 then
						return a.y < b.y
					end
					return a.x < b.x
				end)
				for i = 1, math.min(8, #vis) do
					E.prefetchBg(vis[i].id)
				end
			end
		end
	end)

	startFeed(true)
end

----------------------------------------------------------------------------
-- [10] HALAMAN SEDANG DI PAKAI (nama item diambil sekaligus, baris dipakai ulang = cepat)
----------------------------------------------------------------------------
-- isi nama banyak item sekaligus (batch paralel, cadangan GetProductInfo)
function E.fillNames(ids)
	local need = {}
	for _, id in ipairs(ids) do
		if not E.names[id] then
			need[#need + 1] = id
		end
	end
	if #need == 0 then
		return
	end
	local left = 0
	for i = 1, #need, 50 do
		left = left + 1
		local chunk = table.move(need, i, math.min(i + 49, #need), 1, {})
		task.spawn(function()
			local det = fetchDetails(chunk, Enum.AvatarItemType.Asset)
			for id, d in pairs(det) do
				if d.Name then
					E.names[id] = d.Name
				end
			end
			left = left - 1
		end)
	end
	local t0 = os.clock()
	while left > 0 and os.clock() - t0 < 8 do
		task.wait()
	end
	local rest = {}
	for _, id in ipairs(need) do
		if not E.names[id] then
			rest[#rest + 1] = id
		end
	end
	local left2 = math.min(#rest, 12)
	for k = 1, left2 do
		local id = rest[k]
		task.spawn(function()
			local info = productInfo(id, Enum.InfoType.Asset)
			if info then
				E.names[id] = info.Name
				E.types[id] = E.types[id] or info.AssetTypeId
			end
			left2 = left2 - 1
		end)
	end
	t0 = os.clock()
	while left2 > 0 and os.clock() - t0 < 6 do
		task.wait()
	end
end

local function buildWorn(page)
	local head = mk("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = page })
	label(head, "Sedang dipakai", 15, T.Text, Enum.Font.GothamBold).Size = UDim2.new(0.5, 0, 0, 22)
	local sub = label(head, "", 11, T.Dim, Enum.Font.Gotham)
	sub.Position = UDim2.fromOffset(0, 20)
	sub.Size = UDim2.new(0.5, 0, 0, 14)
	button(head, { text = "Lepas semua", size = UDim2.fromOffset(96, 28), anchor = Vector2.new(1, 0),
		position = UDim2.new(1, 0, 0, 2), bg = T.Danger, textSize = 12,
		onClick = function() task.spawn(E.removeAll) end })
	button(head, { text = "Reset", size = UDim2.fromOffset(72, 28), anchor = Vector2.new(1, 0),
		position = UDim2.new(1, -102, 0, 2), textSize = 12, onClick = function() task.spawn(E.reset) end })

	local list = makeScroll(page, UDim2.new(1, 0, 1, -42), UDim2.fromOffset(0, 42))
	vlist(list, 6)
	pad(list, 0, 0, 8, 10)

	local rows = {}

	local function makeRow(e)
		local r = mk("Frame", { Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = T.Surface, BorderSizePixel = 0, Parent = list })
		corner(r, 10)
		local img = mk("ImageLabel", { Size = UDim2.fromOffset(36, 36), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = T.Surface2,
			BorderSizePixel = 0, Image = thumbURL("Asset", e.Id, 150), Parent = r })
		corner(img, 8)
		local nameL = label(r, E.names[e.Id] or "Memuat nama...", 12, T.Text, Enum.Font.GothamBold)
		nameL.Position = UDim2.fromOffset(50, 6)
		nameL.Size = UDim2.new(1, -124, 0, 18)
		nameL.TextTruncate = Enum.TextTruncate.AtEnd
		local typeL = label(r, e.Label, 10, T.Dim, Enum.Font.Gotham)
		typeL.Position = UDim2.fromOffset(50, 26)
		typeL.Size = UDim2.new(1, -124, 0, 14)
		button(r, { text = "Lepas", size = UDim2.fromOffset(60, 28), anchor = Vector2.new(1, 0.5), position = UDim2.new(1, -8, 0.5, 0),
			textSize = 12, onClick = function() task.spawn(E.removeAsset, e.Id) end })
		return { frame = r, nameL = nameL, typeL = typeL }
	end

	local function refresh()
		local items = E.wornList()
		sub.Text = #items .. " item aktif pada karakter"
		local want = {}
		for _, e in ipairs(items) do
			want[e.Id] = true
		end
		for id, r in pairs(rows) do
			if not want[id] then
				r.frame:Destroy()
				rows[id] = nil
			end
		end
		local need = {}
		for n, e in ipairs(items) do
			local r = rows[e.Id]
			if not r then
				r = makeRow(e)
				rows[e.Id] = r
			end
			r.frame.LayoutOrder = n
			r.typeL.Text = e.Label .. (E.failed[e.Id] and "  •  injector" or "")
			if E.names[e.Id] then
				r.nameL.Text = E.names[e.Id]
			else
				need[#need + 1] = e.Id
			end
		end
		if #need > 0 then
			task.spawn(function()
				E.fillNames(need)
				for _, id in ipairs(need) do
					local r = rows[id]
					if r and r.frame.Parent then
						r.nameL.Text = E.names[id] or ("Item #" .. id)
					end
				end
			end)
		end
	end
	refresh()
	return refresh
end

----------------------------------------------------------------------------
-- [10b] HALAMAN FAVORIT
----------------------------------------------------------------------------
local function buildFavorites(page)
	local chipRow = mk("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Parent = page })
	mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = chipRow })
	local function newGrid(cell)
		local sc = makeScroll(page, UDim2.new(1, 0, 1, -30), UDim2.fromOffset(0, 30))
		mk("UIGridLayout", { CellSize = cell, CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = sc })
		pad(sc, 0, 2, 0, 10)
		return sc
	end
	local avSc, itSc = newGrid(UDim2.fromOffset(84, 96)), newGrid(UDim2.fromOffset(84, 110))
	local emptyMsg = mk("TextLabel", { Size = UDim2.new(1, -16, 0, 60), Position = UDim2.fromOffset(8, 60), BackgroundTransparency = 1,
		TextColor3 = T.Dim, TextSize = 12, Font = Enum.Font.GothamMedium, TextWrapped = true, Visible = false, Parent = page })
	local cur, dirty, cards, chips = "avatar", true, {}, {}
	local nAv, nIt = 0, 0

	local function show(k)
		cur = k
		avSc.Visible, itSc.Visible = k == "avatar", k == "item"
		for kk, c in pairs(chips) do
			c.BackgroundColor3 = kk == k and Theme.TabActiveBg or T.Surface2
			c.TextColor3 = kk == k and T.Accent or T.Text
		end
		local empty = (k == "avatar" and nAv == 0) or (k == "item" and nIt == 0)
		emptyMsg.Visible = empty
		emptyMsg.Text = k == "avatar" and "Belum ada avatar favorit.\nTekan ♡ di kartu avatar."
			or "Belum ada item favorit.\nTekan ♡ di kartu item (karakter / animasi / sepatu)."
	end
	for i, d in ipairs({ { "avatar", "Avatar" }, { "item", "Item" } }) do
		local c = mk("TextButton", { Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = T.Surface2,
			BorderSizePixel = 0, Text = d[2], TextSize = 11, Font = Enum.Font.GothamBold, TextColor3 = T.Text, AutoButtonColor = false,
			LayoutOrder = i, Parent = chipRow })
		corner(c, 8)
		pad(c, 10, 0, 10, 0)
		chips[d[1]] = c
		c.Activated:Connect(function()
			show(d[1])
		end)
	end

	local function clear(sc)
		for _, c in ipairs(sc:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
	end
	local function sorted(map)
		local l = {}
		for _, r in pairs(map) do
			table.insert(l, r)
		end
		table.sort(l, function(a, b)
			return (a.t or 0) > (b.t or 0)
		end)
		return l
	end

	local function rebuild()
		dirty = false
		clear(avSc)
		clear(itSc)
		cards = {}
		local avs, its = sorted(FAV.avatars), sorted(FAV.items)
		nAv, nIt = #avs, #its
		chips.avatar.Text = "Avatar (" .. nAv .. ")"
		chips.item.Text = "Item (" .. nIt .. ")"
		for i, r in ipairs(avs) do
			userCard(avSc, r.id, r.name, i, "favorit")
		end
		local rows = {}
		for i, r in ipairs(its) do
			local row = { Id = r.Id, Type = r.Type, Name = r.Name, Price = false, Order = i, slot = r.slot, slotName = r.slotName }
			if r.Type == "Asset" then
				E.names[r.Id] = E.names[r.Id] or r.Name
				if r.tid then
					E.types[r.Id] = r.tid
				end
			end
			table.insert(rows, row)
			local c = makeCard(itSc, row)
			c.loadImg()
			table.insert(cards, c)
		end
		show(cur)
		-- harga & nama terbaru di latar belakang
		task.spawn(function()
			local packs = { A = { ids = {}, type = Enum.AvatarItemType.Asset }, B = { ids = {}, type = Enum.AvatarItemType.Bundle } }
			local byKey = {}
			for _, row in ipairs(rows) do
				local p = row.Type == "Bundle" and "B" or "A"
				table.insert(packs[p].ids, row.Id)
				byKey[p .. row.Id] = row
			end
			for p, pack in pairs(packs) do
				for i = 1, #pack.ids, 50 do
					local chunk = table.move(pack.ids, i, math.min(i + 49, #pack.ids), 1, {})
					local det = fetchDetails(chunk, pack.type)
					for _, id in ipairs(chunk) do
						local row, d = byKey[p .. id], det[id]
						if row then
							if d then
								row.Name = d.Name or row.Name
								row.Price = d.PriceInRobux
							else
								row.Price = nil
							end
							if row.onUpdate then
								pcall(row.onUpdate)
							end
						end
					end
				end
			end
		end)
	end

	FAV.listen(function()
		if not page.Parent then
			return false
		end
		if page.Visible then
			rebuild()
		else
			dirty = true
		end
	end)
	show("avatar")
	rebuild()
	return function()
		if dirty then
			if page.Visible then
				rebuild()
			end
			return
		end
		local set = collect(E.look)
		for _, c in ipairs(cards) do
			c.update(set)
		end
	end
end

----------------------------------------------------------------------------
-- [11] SHELL UI (gaya LEON4951 HUB v2): header, sidebar 5 tab, drag, resize
----------------------------------------------------------------------------
local MAIN_W, MAIN_H = 660, 360
local State = { tab = "avatars", open = false, sbw = 78 }
local UI = { builders = {}, built = {}, pages = {}, refreshers = {} }

UI.gui = mk("ScreenGui", {
	Name = "leon4951hub", ResetOnSpawn = false, IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 50, Parent = playerGui,
})

toastHolder = mk("Frame", {
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 14), Size = UDim2.fromOffset(420, 300),
	BackgroundTransparency = 1, ZIndex = 200, Parent = UI.gui,
})
mk("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
	HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = toastHolder,
})

local mainFrame = mk("Frame", {
	Name = "MainFrame", Size = UDim2.fromOffset(MAIN_W, MAIN_H), AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = Theme.Background, BorderSizePixel = 0,
	Active = true, Visible = false, Parent = UI.gui,
})
corner(mainFrame, 20)
stroke(mainFrame, Theme.Accent, 3)
local mainScale = mk("UIScale", { Scale = 0, Parent = mainFrame })

local function computeScale()
	local cam = Workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	return math.clamp(math.min((vp.X - 20) / MAIN_W, (vp.Y - 20) / MAIN_H), 0.4, 1)
end

-- logo "F"
local function createLogo(size, rotation)
	local box = mk("Frame", { Size = size, BackgroundTransparency = 1, Rotation = rotation or -12 })
	local function bar(sz, pos)
		local f = mk("Frame", { Size = sz, Position = pos, BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = box })
		corner(f, 2)
	end
	bar(UDim2.new(1, 0, 0, math.floor(size.Y.Offset * 0.28)), UDim2.new())
	bar(UDim2.new(0.68, 0, 0, math.floor(size.Y.Offset * 0.24)), UDim2.new(0.2, 0, 0.4, 0))
	bar(UDim2.new(0, math.floor(size.X.Offset * 0.28), 1, 0), UDim2.new(0.08, 0, 0, 0))
	return box
end

-- header
local header = mk("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, Active = true, Parent = mainFrame })
local logo = createLogo(UDim2.fromOffset(26, 26), -12)
logo.Position = UDim2.new(0, 16, 0, 13)
logo.Parent = header
local logBtn = mk("TextButton", { Size = UDim2.fromOffset(30, 30), Position = UDim2.new(0, 14, 0, 11), BackgroundTransparency = 1, Text = "", ZIndex = 5, Parent = header })
logBtn.Activated:Connect(function()
	local okC = pcall(function()
		local txt = table.concat(LOG, "\n")
		if setclipboard then
			setclipboard(txt)
		elseif toclipboard then
			toclipboard(txt)
		else
			error("tidak ada clipboard")
		end
	end)
	toast(okC and "Log disalin ke clipboard (tempel ke chat kalau ada error)" or "Clipboard tidak ada di executor ini, lihat Output/F9", okC and "ok" or "warn")
end)
mk("TextLabel", {
	Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = Theme.Accent, BackgroundTransparency = 1,
	Size = UDim2.new(0, 200, 0, 26), Position = UDim2.new(0, 50, 0, 13), TextXAlignment = Enum.TextXAlignment.Left,
	Text = "LEON4951 HUB", Parent = header,
})

local ToggleMainUI

local closeBtn = mk("TextButton", {
	Size = UDim2.fromOffset(36, 36), Position = UDim2.new(1, -44, 0, 8), BackgroundColor3 = Theme.CardBg, Text = "X",
	Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Theme.TextPrimary, AutoButtonColor = false, Parent = header,
})
corner(closeBtn, 10)
stroke(closeBtn, Theme.CardBorder, 1.5)
closeBtn.Activated:Connect(function()
	ToggleMainUI(false)
end)

local waBtn = mk("TextButton", {
	Size = UDim2.fromOffset(120, 26), Position = UDim2.new(1, -175, 0, 13), BackgroundColor3 = Theme.WaGreen,
	Text = "💬 SALURAN WA", Font = Enum.Font.GothamBold, TextSize = 9, TextColor3 = Theme.TextPrimary,
	AutoButtonColor = false, Parent = header,
})
corner(waBtn, 8)
stroke(waBtn, Theme.WaDarkGreen, 1.5)
waBtn.Activated:Connect(function()
	pcall(function()
		if setclipboard then
			setclipboard(WA_CHANNEL_LINK)
		elseif toclipboard then
			toclipboard(WA_CHANNEL_LINK)
		end
	end)
	local orig = "💬 SALURAN WA"
	waBtn.Text = "✓ COPIED!"
	task.delay(1.5, function()
		if waBtn.Parent then
			waBtn.Text = orig
		end
	end)
end)

mk("Frame", { Size = UDim2.new(1, -32, 0, 1), Position = UDim2.new(0, 16, 0, 48), BackgroundColor3 = Theme.CardBorder, BorderSizePixel = 0, Parent = mainFrame })
-- bar loading di bawah header (aktif saat avatar / item sedang diproses)
local loadTrack = mk("Frame", { Size = UDim2.new(1, -32, 0, 3), Position = UDim2.new(0, 16, 0, 47), BackgroundTransparency = 1,
	ClipsDescendants = true, ZIndex = 8, Parent = mainFrame })
local loadBar = mk("Frame", { Size = UDim2.fromScale(0.35, 1), Position = UDim2.fromScale(-0.35, 0), BackgroundColor3 = Theme.Accent,
	BorderSizePixel = 0, Visible = false, ZIndex = 8, Parent = loadTrack })
corner(loadBar, 2)
task.spawn(function()
	local x = -0.35
	while not stale() and UI.gui.Parent do
		if E.busy or E.worker or E.pending ~= nil or E.loadingBundles > 0 or E.pendingClicks > 0 then
			loadBar.Visible = true
			x = x + 0.045
			if x > 1 then
				x = -0.35
			end
			loadBar.Position = UDim2.fromScale(x, 0)
			task.wait(0.016)
		else
			loadBar.Visible = false
			task.wait(0.1)
		end
	end
end)

-- body: sidebar + content
local bodyFrame = mk("Frame", { Name = "Body", Size = UDim2.new(1, -32, 1, -56), Position = UDim2.new(0, 16, 0, 52), BackgroundTransparency = 1, Parent = mainFrame })
local sidebar = mk("ScrollingFrame", {
	Name = "Sidebar", Size = UDim2.new(0, State.sbw, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
	AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = bodyFrame,
})
mk("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = sidebar })

local contentFrame = mk("Frame", {
	Name = "Content", Size = UDim2.new(1, -(State.sbw + 8) - 180, 1, 0), Position = UDim2.new(0, State.sbw + 8, 0, 0),
	BackgroundTransparency = 1, ClipsDescendants = true, Parent = bodyFrame,
})
local contentTitle = mk("TextLabel", {
	Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Theme.TextPrimary, BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 20), TextXAlignment = Enum.TextXAlignment.Left, Text = "AVATAR", Parent = contentFrame,
})
local contentSub = mk("TextLabel", {
	Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Theme.TextMuted, BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 0, 22), TextXAlignment = Enum.TextXAlignment.Left,
	Text = "", Parent = contentFrame,
})
local pageHolder = mk("Frame", { Size = UDim2.new(1, 0, 1, -46), Position = UDim2.fromOffset(0, 46), BackgroundTransparency = 1, Parent = contentFrame })

local function updateSub()
	local n = #E.wornList()
	contentSub.Text = n .. " item dipakai  •  mode: " .. (E.lastMethod ~= "" and E.lastMethod or (E.remote and "server" or "native"))
end

-- daftar tab
local TABS = {
	{ key = "avatars", name = "avatar" },
	{ key = "karakter", name = "karakter", group = "KARAKTER / TUBUH" },
	{ key = "animasi", name = "animasi", group = "ANIMASI" },
	{ key = "sepatu", name = "sepatu", group = "SEPATU" },
	{ key = "favorit", name = "favorit", title = "FAVORIT" },
	{ key = "worn", name = "dipakai", title = "SEDANG DI PAKAI" },
}

UI.builders.avatars = buildAvatars
UI.builders.favorit = function(p)
	UI.refreshers.favorit = buildFavorites(p)
end
UI.builders.worn = function(p)
	UI.refreshers.worn = buildWorn(p)
end
for _, tab in ipairs(TABS) do
	if tab.group then
		UI.builders[tab.key] = function(p)
			UI.refreshers[tab.key] = buildCatalog(p, tab.group)
		end
	end
end

local tabBtns = {}
local function setTab(index)
	local tab = TABS[index]
	State.tab = tab.key
	for i, b in ipairs(tabBtns) do
		local active = i == index
		b.frame.BackgroundTransparency = active and 0 or 1
		b.frame.BackgroundColor3 = Theme.TabActiveBg
		b.stroke.Enabled = active
		b.label.TextColor3 = active and Theme.TextPrimary or Theme.TextMuted
		b.indicator.Visible = active
	end
	for k, p in pairs(UI.pages) do
		p.Visible = k == tab.key
	end
	contentTitle.Text = tab.title or string.upper(tab.name)
	updateSub()
	if not UI.built[tab.key] then
		UI.built[tab.key] = true
		local okB, errB = pcall(UI.builders[tab.key], UI.pages[tab.key])
		if not okB then
			logf("GAGAL membuat halaman %s: %s", tab.key, tostring(errB))
			mk("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, TextWrapped = true, TextColor3 = T.Danger,
				TextSize = 12, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top, Text = "⚠ Halaman gagal dibuat:\n" .. tostring(errB),
				Parent = UI.pages[tab.key],
			})
		end
	elseif UI.refreshers[tab.key] then
		pcall(UI.refreshers[tab.key])
	end
end

for i, tab in ipairs(TABS) do
	local b = mk("TextButton", {
		Name = "Tab_" .. tab.key, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.TabActiveBg, BackgroundTransparency = 1,
		Text = "", AutoButtonColor = false, LayoutOrder = i, Parent = sidebar,
	})
	corner(b, 8)
	local sk = stroke(b, Theme.TabActiveBorder, 1)
	sk.Enabled = false
	local ind = mk("Frame", {
		Size = UDim2.new(0, 3, 0, 16), Position = UDim2.new(0, 4, 0.5, -8), BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0, Visible = false, Parent = b,
	})
	corner(ind, 99)
	local lb = mk("TextLabel", {
		Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = Theme.TextMuted, BackgroundTransparency = 1,
		Size = UDim2.new(1, -14, 1, 0), Position = UDim2.new(0, 12, 0, 0), TextXAlignment = Enum.TextXAlignment.Left,
		Text = string.upper(tab.name), Parent = b,
	})
	table.insert(tabBtns, { frame = b, stroke = sk, label = lb, indicator = ind })
	b.Activated:Connect(function()
		setTab(i)
	end)
	UI.pages[tab.key] = mk("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, Parent = pageHolder })
end

----------------------------------------------------------------------------
-- [11b] CERMIN  -  pratinjau karakter (ViewportFrame) seperti etalase avatar shop
--   Menyalin karakter yang SEDANG tampil di layar, jadi isi cermin = yang kamu lihat.
--   Otomatis ikut berubah saat item/avatar dipilih. Geser untuk memutar.
--   Kamera otomatis menyesuaikan ukuran avatar (kecil / tinggi) dan ukuran panel.
----------------------------------------------------------------------------
do
local MIRROR_W = 170
local Mirror = { on = true, spin = 0, auto = true, dragging = false, pauseUntil = 0, sig = nil, stage = nil, model = nil, token = 0 }

local mirrorPanel = mk("Frame", {
	Name = "Mirror", Size = UDim2.new(0, MIRROR_W, 1, 0), Position = UDim2.new(1, -MIRROR_W, 0, 0),
	BackgroundColor3 = Theme.CardBg, BorderSizePixel = 0, ClipsDescendants = true, Parent = bodyFrame,
})
corner(mirrorPanel, 14)
stroke(mirrorPanel, Theme.Accent, 2)
mk("UIGradient", {
	Color = ColorSequence.new(Color3.fromRGB(36, 40, 66), Color3.fromRGB(14, 15, 26)),
	Rotation = 90, Parent = mirrorPanel,
})

mk("TextLabel", {
	Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Theme.Accent, BackgroundTransparency = 1,
	Size = UDim2.new(1, -16, 0, 20), Position = UDim2.new(0, 10, 0, 6), TextXAlignment = Enum.TextXAlignment.Left,
	Text = "CERMIN", Parent = mirrorPanel,
})

local mirrorVP = mk("ViewportFrame", {
	Name = "MirrorVP", Size = UDim2.new(1, -12, 1, -72), Position = UDim2.new(0, 6, 0, 28),
	BackgroundTransparency = 1, Active = true,
	Ambient = Color3.fromRGB(175, 175, 190), LightColor = Color3.fromRGB(255, 255, 255),
	LightDirection = Vector3.new(-0.5, -0.8, -0.6), Parent = mirrorPanel,
})
local mirrorCam = mk("Camera", { FieldOfView = 40, Parent = mirrorVP })
mirrorVP.CurrentCamera = mirrorCam

local mirrorMsg = mk("TextLabel", {
	Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = Theme.TextMuted, BackgroundTransparency = 1,
	Size = UDim2.new(1, -20, 0, 40), Position = UDim2.new(0, 10, 0.5, -20), TextWrapped = true,
	Text = "Memuat karakter...", Parent = mirrorPanel,
})


local function charSignature()
	local char = player.Character
	if not char then
		return "none"
	end
	local n = 0
	for _ in ipairs(char:GetDescendants()) do
		n = n + 1
	end
	local ext = ""
	pcall(function()
		local s = char:GetExtentsSize()
		ext = string.format("%.1f,%.1f", s.Y, math.max(s.X, s.Z))
	end)
	return n .. "|" .. tostring(char:FindFirstChild(SKIN_NAME) ~= nil) .. "|" .. tostring(E.lastMethod) .. "|" .. ext
end

-- ukur bagian yang TERLIHAT saja: tinggi + radius putar dari sumbu tengah
local function measure(model)
	local minY, maxY, rad = math.huge, -math.huge, 0
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Transparency < 0.95 then
			local cf, h = d.CFrame, d.Size / 2
			for sx = -1, 1, 2 do
				for sy = -1, 1, 2 do
					for sz = -1, 1, 2 do
						local p = cf:PointToWorldSpace(Vector3.new(h.X * sx, h.Y * sy, h.Z * sz))
						minY = math.min(minY, p.Y)
						maxY = math.max(maxY, p.Y)
						rad = math.max(rad, math.sqrt(p.X * p.X + p.Z * p.Z))
					end
				end
			end
		end
	end
	if minY == math.huge then
		local cf, size = model:GetBoundingBox()
		minY, maxY = cf.Position.Y - size.Y / 2, cf.Position.Y + size.Y / 2
		rad = math.max(size.X, size.Z) / 2
	end
	local headY, headH
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == "Head" and d.Transparency < 0.95 then
			headY, headH = d.Position.Y, d.Size.Y
			break
		end
	end
	if not headY then
		headY, headH = maxY - 0.6, 1.2
	end
	return { minY = minY, maxY = maxY, height = math.max(maxY - minY, 0.5), cy = (minY + maxY) / 2,
		radius = math.max(rad, 0.5), headY = headY, headH = headH }
end

local function mirrorBuild()
	local char = player.Character
	if not char or not char.Parent then
		return nil, "karakter belum siap"
	end
	local wasArch = char.Archivable
	char.Archivable = true
	local okC, clone = pcall(function()
		return char:Clone()
	end)
	char.Archivable = wasArch
	if not okC or not clone then
		return nil, "gagal menyalin karakter"
	end
	for _, d in ipairs(clone:GetDescendants()) do
		pcall(function()
			if d:IsA("LuaSourceContainer") or d:IsA("Sound") or d:IsA("BillboardGui") then
				d:Destroy()
			elseif d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
			end
		end)
	end
	local hum = clone:FindFirstChildOfClass("Humanoid")
	if hum then
		pcall(function()
			hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		end)
	end
	local hrp = clone:FindFirstChild("HumanoidRootPart")
	if hrp and not clone.PrimaryPart then
		clone.PrimaryPart = hrp
	end
	clone:PivotTo(CFrame.new())

	local b = measure(clone)

	local stage = Instance.new("Folder")
	stage.Name = "Stage"
	local d = math.max(b.radius * 2 * 1.15, 2)
	local base = Instance.new("Part")
	base.Name = "Platform"
	base.Shape = Enum.PartType.Cylinder
	base.Size = Vector3.new(0.2, d, d)
	base.CFrame = CFrame.new(0, b.minY - 0.1, 0) * CFrame.Angles(0, 0, math.pi / 2)
	base.Anchored = true
	base.CanCollide = false
	base.Material = Enum.Material.Neon
	base.Color = Theme.Accent
	base.Transparency = 0.55
	base.Parent = stage
	clone.Parent = stage
	return stage, clone, b
end

-- atur jarak kamera supaya seluruh avatar (kecil / tinggi) pas di panel
function Mirror.fit()
	local b = Mirror.bounds
	if not b then
		return
	end
	local vs = mirrorVP.AbsoluteSize
	local aspect = math.max(vs.X, 1) / math.max(vs.Y, 1)
	local tanV = math.tan(math.rad(mirrorCam.FieldOfView) / 2)
	local tanH = tanV * aspect
	-- kamera sejajar tinggi kepala; titik pandang di antara kepala & tengah badan supaya seluruh avatar tetap masuk
	local camY = b.headY
	local lookY = (b.headY + b.cy) / 2
	local halfH = math.max(b.maxY - lookY, lookY - b.minY, b.headH) * 1.12
	local dist = math.max(halfH / tanV, (b.radius * 1.12) / tanH) + b.radius
	local target = CFrame.lookAt(Vector3.new(0, camY, dist), Vector3.new(0, lookY, 0))
	if Mirror.fitted then
		tween(mirrorCam, { CFrame = target }, 0.25)
	else
		mirrorCam.CFrame = target
		Mirror.fitted = true
	end
end
mirrorVP:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	Mirror.fit()
end)

function Mirror.refresh()
	if stale() or not mirrorVP.Parent then
		return
	end
	local ok, stage, model, bounds = pcall(mirrorBuild)
	if not ok then
		logf("cermin gagal: %s", tostring(stage))
		mirrorMsg.Text = "Cermin gagal: " .. tostring(stage)
		mirrorMsg.Visible = true
		return
	end
	if not stage then
		mirrorMsg.Text = tostring(model)
		mirrorMsg.Visible = true
		return
	end
	local old = Mirror.stage
	stage.Parent = mirrorVP
	Mirror.stage, Mirror.model, Mirror.bounds = stage, model, bounds
	Mirror.sig = charSignature()
	Mirror.fit()
	mirrorMsg.Visible = false
	if old then
		old:Destroy()
	end
end

function Mirror.queue(delay)
	Mirror.token = Mirror.token + 1
	local t = Mirror.token
	task.delay(delay or 0.6, function()
		if t == Mirror.token then
			Mirror.refresh()
		end
	end)
end

-- geser untuk memutar
mirrorVP.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		Mirror.dragging = true
		Mirror.lastX = input.Position.X
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				Mirror.dragging = false
				Mirror.pauseUntil = os.clock() + 2
			end
		end)
	end
end)
mirrorVP.InputChanged:Connect(function(input)
	if Mirror.dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local x = input.Position.X
		Mirror.spin = Mirror.spin + (x - (Mirror.lastX or x)) * 0.012
		Mirror.lastX = x
	end
end)

-- tombol bawah: putar otomatis
local mirrorAutoBtn = button(mirrorPanel, {
	text = "⏸ Putar", textSize = 11, bg = Theme.CardBg, size = UDim2.new(1, -12, 0, 26),
	position = UDim2.new(0, 6, 1, -32), radius = 8, onClick = function() end,
})
mirrorAutoBtn.Activated:Connect(function()
	Mirror.auto = not Mirror.auto
	mirrorAutoBtn.Text = Mirror.auto and "⏸ Putar" or "▶ Putar"
end)


-- animasi putar
do
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		if stale() or not UI.gui.Parent then
			conn:Disconnect()
			return
		end
		if not Mirror.model or not Mirror.model.Parent or not mirrorPanel.Visible or not State.open then
			return
		end
		if Mirror.auto and not Mirror.dragging and os.clock() > Mirror.pauseUntil then
			Mirror.spin = Mirror.spin + dt * 0.8
		end
		pcall(function()
			Mirror.model:PivotTo(CFrame.Angles(0, math.pi + Mirror.spin, 0))
		end)
	end)
end

-- ikuti perubahan avatar
E.onChanged(function()
	Mirror.queue(0.8)
end)
player.CharacterAdded:Connect(function()
	Mirror.sig = nil
	Mirror.queue(2)
end)

-- pemeriksa berkala (menangkap perubahan susulan: aksesori yang baru selesai dimuat, dll)
task.spawn(function()
	local last = 0
	while not stale() and UI.gui.Parent do
		task.wait(2)
		if State.open and mirrorPanel.Visible then
			if charSignature() ~= Mirror.sig or os.clock() - last > 8 then
				last = os.clock()
				Mirror.refresh()
			end
		end
	end
end)
Mirror.queue(1.5)
end

-- tombol mengambang (muncul saat UI ditutup)
local fab = mk("TextButton", {
	Name = "FloatingToggleBtn", Size = UDim2.fromOffset(44, 44), AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 20, 0.4, 0), BackgroundColor3 = Theme.Background, BorderSizePixel = 0,
	Visible = false, Active = true, Text = "", ZIndex = 20, Parent = UI.gui,
})
corner(fab, 11)
stroke(fab, Theme.Accent, 1.5)
local fabLogo = createLogo(UDim2.fromOffset(20, 20), -12)
fabLogo.Position = UDim2.new(0.5, -10, 0.5, -10)
fabLogo.Parent = fab

-- resize handle
local resizeHandle = mk("TextButton", {
	Name = "ResizeHandle", Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = Theme.Accent, Text = "◢", Font = Enum.Font.GothamBold, TextSize = 9, TextColor3 = Theme.Background,
	AutoButtonColor = false, ZIndex = 10, Parent = mainFrame,
})
corner(resizeHandle, 5)

-- drag / resize / drag tombol mengambang
local dragging, dragStart, dragOrigin
local resizing, resizeStart, sizeOrigin
local floating, floatStart, floatOrigin, floatMoved = false, nil, nil, false

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging, dragStart, dragOrigin = true, input.Position, mainFrame.Position
	end
end)
resizeHandle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		resizing, resizeStart, sizeOrigin = true, input.Position, mainFrame.Size
	end
end)
fab.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		floating, floatStart, floatOrigin, floatMoved = true, input.Position, fab.Position, false
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if stale() then
		return
	end
	local moveType = input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
	if not moveType then
		return
	end
	if dragging then
		local d = input.Position - dragStart
		mainFrame.Position = UDim2.new(dragOrigin.X.Scale, dragOrigin.X.Offset + d.X, dragOrigin.Y.Scale, dragOrigin.Y.Offset + d.Y)
	end
	if resizing then
		local d = (input.Position - resizeStart) / math.max(mainScale.Scale, 0.1)
		mainFrame.Size = UDim2.fromOffset(
			math.clamp(sizeOrigin.X.Offset + d.X, 560, 1000),
			math.clamp(sizeOrigin.Y.Offset + d.Y, 300, 650)
		)
	end
	if floating then
		local d = input.Position - floatStart
		if math.abs(d.X) + math.abs(d.Y) > 8 then
			floatMoved = true
		end
		if floatMoved then
			fab.Position = UDim2.new(floatOrigin.X.Scale, floatOrigin.X.Offset + d.X, floatOrigin.Y.Scale, floatOrigin.Y.Offset + d.Y)
		end
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging, resizing, floating = false, false, false
	end
end)
fab.Activated:Connect(function()
	if not floatMoved then
		ToggleMainUI(true)
	end
end)

ToggleMainUI = function(show)
	State.open = show
	if show then
		mainFrame.Visible = true
		mainScale.Scale = 0
		fab.Visible = false
		tween(mainScale, { Scale = computeScale() }, 0.22, Enum.EasingStyle.Back)
	else
		mainScale.Scale = 0
		mainFrame.Visible = false
		fab.Visible = true
	end
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp or E.uiDestroyed or stale() then
		return
	end
	if input.KeyCode == TOGGLE_KEY then
		ToggleMainUI(not State.open)
		return
	end
	local ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
	if ctrl and State.open then
		if input.KeyCode == Enum.KeyCode.Z then
			task.spawn(E.undo)
		elseif input.KeyCode == Enum.KeyCode.Y then
			task.spawn(E.doRedo)
		end
	end
end)

do
	local cam = Workspace.CurrentCamera
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if State.open then
				mainScale.Scale = computeScale()
			end
		end)
	end
end

-- segarkan kartu/daftar saat avatar berubah
E.onChanged(function()
	updateSub()
	-- nama item yang dipakai disiapkan lebih awal supaya tab DIPAKAI langsung terisi
	task.spawn(function()
		local ids = {}
		for _, e in ipairs(E.wornList()) do
			if not E.names[e.Id] then
				ids[#ids + 1] = e.Id
			end
		end
		if #ids > 0 then
			pcall(E.fillNames, ids)
		end
	end)
	for key, fn in pairs(UI.refreshers) do
		if key == State.tab or key ~= "worn" then
			pcall(fn)
		end
	end
end)

----------------------------------------------------------------------------
-- [12] BOOT + START
----------------------------------------------------------------------------
setTab(1)
ToggleMainUI(true)

task.spawn(function()
	local ok, err = pcall(E.init)
	if not ok then
		toast("Gagal menyiapkan karakter: " .. tostring(err), "danger")
		return
	end
	toast("leon4951hub siap! K = buka/tutup  •  mode: " .. (E.remote and "SERVER" or (E.injectFirst and "INJECTOR (visual klien)" or "native")), "ok")
	if PREWARM_SKIN and not E.remote and E.useSkin and E.cap.donor ~= false and E.look then
		E.busy = true
		pcall(E.apply, E.look)
		E.busy = false
		E.reapplyTweaks()
	end
end)

-- muat tab katalog lain diam-diam supaya saat dibuka sudah terisi
task.delay(3, function()
	for _, tab in ipairs(TABS) do
		if stale() then
			return
		end
		if tab.group and not UI.built[tab.key] then
			UI.built[tab.key] = true
			pcall(UI.builders[tab.key], UI.pages[tab.key])
			task.wait(0.8)
		end
	end
end)
