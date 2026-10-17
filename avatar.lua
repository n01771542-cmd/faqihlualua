--[[ =============================================================================
  leon4951hub  -  script.lua   (LocalScript / StarterPlayerScripts)
  Visual-only: item, avatar, dan animasi yang dipilih langsung dipasang di
  karakter kamu.

  CARA PAKAI (Roblox Studio, game milikmu sendiri):
    1. Taruh file ini sebagai LocalScript di StarterPlayer > StarterPlayerScripts
    2. (DISARANKAN) Taruh AvatarStudioServer.lua sebagai Script di
       ServerScriptService. Dengan ini item PASTI muncul (dipasang server).
    3. Play. Tekan K untuk buka/tutup UI.

  CARA KERJA PEMASANGAN (otomatis, urut):
    A. Server  : kalau AvatarStudioServer ada -> server yang memasang.
    B. Injector: 1 item -> dimuat (GetObjects / LoadAsset / donor rig) lalu
                 ditempel + DILAS manual ke karakter.
    C. Donor   : avatar/banyak item -> Roblox membangun rig donor dari
                 HumanoidDescription (klien boleh untuk rig buatan sendiri),
                 lalu aksesori/pakaian/animasinya dipindah ke karakter kamu.
  (ApplyDescription ke karakter sendiri dari klien DITOLAK Roblox, jadi tidak dipakai.)
  Hasilnya diverifikasi (jumlah aksesori dihitung ulang). Kalau item benar-benar
  tidak bisa ditampilkan, kamu diberi tahu dan item tidak ditandai "dipakai".
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

local REMOTE_NAME = "AvatarStudioApply"
local PAGE_SIZE = 30
local TOGGLE_KEY = Enum.KeyCode.K

----------------------------------------------------------------------------
-- [2] TABEL TIPE ITEM
----------------------------------------------------------------------------
-- AssetTypeId -> properti HumanoidDescription (pakaian klasik, bodypart, animasi)
local CLASSIC = {
	[11] = "Shirt", [12] = "Pants", [2] = "GraphicTShirt", [18] = "Face",
	[17] = "Head", [27] = "Torso", [28] = "RightArm", [29] = "LeftArm",
	[30] = "LeftLeg", [31] = "RightLeg",
	[48] = "ClimbAnimation", [50] = "FallAnimation", [51] = "IdleAnimation",
	[52] = "JumpAnimation", [53] = "RunAnimation", [54] = "SwimAnimation",
	[55] = "WalkAnimation", [78] = "MoodAnimation",
}

-- AssetTypeId -> { AccessoryType, layered }
local ACC = {
	[8] = { "Hat", false }, [41] = { "Hair", false }, [42] = { "Face", false },
	[43] = { "Neck", false }, [44] = { "Shoulder", false }, [45] = { "Front", false },
	[46] = { "Back", false }, [47] = { "Waist", false },
	[64] = { "TShirt", true }, [65] = { "Shirt", true }, [66] = { "Pants", true },
	[67] = { "Jacket", true }, [68] = { "Sweater", true }, [69] = { "Shorts", true },
	[70] = { "LeftShoe", true }, [71] = { "RightShoe", true }, [72] = { "DressSkirt", true },
	[76] = { "Eyebrow", false }, [77] = { "Eyelash", false },
}

-- slot animasi di script "Animate" bawaan Roblox
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
	b.MouseEnter:Connect(function()
		tween(b, { BackgroundColor3 = bg:Lerp(Color3.new(1, 1, 1), 0.12) }, 0.12)
	end)
	b.MouseLeave:Connect(function()
		tween(b, { BackgroundColor3 = bg }, 0.15)
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
	return string.format("rbxthumb://type=%s&id=%d&w=%d&h=%d", kind, id, size, size)
end

local function commas(n)
	local s = tostring(math.floor(n))
	local r = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (r:gsub("^,", ""))
end

local function priceText(p)
	if p == nil then
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
-- coba tiap nama metode berurutan (nama baru dulu); mengembalikan ok, hasil, namaYangDipakai
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
	look = nil,        -- HumanoidDescription "sumber kebenaran" (apa yang seharusnya dipakai)
	original = nil,
	failed = {},       -- [id]=true : item yang tidak bisa dipasang native -> dipasang injector
	types = {}, names = {},
	history = {}, redo = {},
	busy = false, remote = nil, lastMethod = "", injectFirst = false, cap = {}, useSkin = true, skinMode = "puppet", directIds = {},
	scales = {}, skin = nil, origColors = nil,
	listeners = {},
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

-- kumpulkan semua id yang ada di description
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
			-- pakaian layered / alis / bulu mata: 1 slot per jenis
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

-- deskripsi tanpa item yang diketahui gagal native
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
-- "Donor rig": Roblox sendiri membangun model karakter dari HumanoidDescription.
-- Kita ambil aksesori/pakaian/animasinya dari model itu -> tidak butuh GetObjects/LoadAsset.
local function donorModel(desc)
	local hum = E.humanoid()
	local rig = (hum.RigType == Enum.HumanoidRigType.R6) and Enum.HumanoidRigType.R6 or Enum.HumanoidRigType.R15
	local ok, m = callAny(Players, { "CreateHumanoidModelFromDescriptionAsync", "CreateHumanoidModelFromDescription" }, desc, rig)
	if ok and m then
		return m
	end
	logf("donor rig gagal: %s", tostring(m))
	return nil
end

-- mengembalikan (objs, metode)
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

-- Humanoid:AddAccessory di klien TIDAK membuat las (weld dibuat server) -> aksesori
-- tertinggal di posisi awal / tidak terlihat. Jadi kita las sendiri.
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

-- pindahkan aksesori dari rig donor ke karakter kita, las asli engine disambung ulang
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

-- salin tekstur/mesh bagian tubuh dari donor (best-effort; MeshId bisa diblokir)
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

-- penjaga: pasang ulang item injector yang dihapus/direset oleh map
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
	-- aksesori hasil render donor dihapus map? render ulang (maks 1x / 6 detik)
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

-- salin animasi dari donor (slot yang dipilih); slot yang dilepas dikembalikan ke aslinya
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

-- SKIN OVERLAY: seluruh rig donor (badan, tangan, kaki, kepala, pakaian, aksesori) dilas ke
-- bagian tubuh kita; bagian asli disembunyikan. Sendi/animasi karakter asli tidak disentuh.
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
			E.hidden[d] = d.Transparency
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

-- muat aksesori langsung (GetObjects/LoadAsset) lalu las ke rig skin: cadangan kalau donor menolak aset
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

-- apakah donor Roblox sanggup memuat aksesori ini sendirian? (false = aset dibuang diam-diam)
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

-- donor kekurangan aksesori: cari yang hilang, coba muat langsung; kembalikan (jumlahDimuat, daftarGagal)
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

-- SKIN BONEKA: rig donor utuh (sendi sendiri) dipasang di belakang HumanoidRootPart kita,
-- lalu Motor6D.Transform disalin tiap frame -> bentuk tubuh donor + gerakan karaktermu.
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
	-- samakan tinggi telapak kaki dengan karakter kita
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
	-- peta sendi: Motor6D karakter kita -> Motor6D donor (nama sama)
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
			E.hidden[d] = d.Transparency
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

-- RENDER DONOR: bangun rig donor dari description (diizinkan di klien untuk rig buatan sendiri),
-- lalu pindahkan aksesori / pakaian / wajah / animasi / warna ke karakter kita.
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

	local how
	-- 1) server (kalau AvatarStudioServer ada)
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
		-- 2) injector: tambah/lepas beberapa item saja, tanpa menyentuh yang lain
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
		-- 3) render donor: seluruh look dibangun ulang oleh Roblox sendiri
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
-- API tingkat tinggi
------------------------------------------------------------------------
function E.toggleAsset(id, itemName)
	local tid = E.assetType(id)
	if not tid then
		toast("Tidak bisa membaca info item ini", "danger")
		return false
	end
	if not ACC[tid] and not CLASSIC[tid] then
		toast("Tipe item ini belum didukung", "warn")
		return false
	end
	local worn = E.isWorn(id)
	local nl = E.look:Clone()
	if worn then
		removeFromDesc(nl, id)
	else
		addToDesc(nl, id, tid)
	end
	local ok = E.commit(nl, itemName)
	if ok then
		if worn then
			toast("Dilepas: " .. tostring(itemName or id), "warn")
		elseif E.isWorn(id) then
			toast("Dipakai: " .. tostring(itemName or id) .. "  (" .. E.lastMethod .. ")", "ok")
		end
	end
	return ok
end

function E.removeAsset(id)
	local nl = E.look:Clone()
	removeFromDesc(nl, id)
	return E.commit(nl, "lepas")
end

function E.equipBundle(bundleId, bundleName)
	local info = productInfo(bundleId, Enum.InfoType.Bundle)
	if not info or not info.Items then
		toast("Gagal membaca isi bundle", "danger")
		return false
	end
	local nl = E.look:Clone()
	for _, item in ipairs(info.Items) do
		if item.Type == "UserOutfit" then
			local od = descFromOutfit(item.Id)
			if od then
				mergeDescription(nl, od)
			end
		elseif item.Type == "Asset" then
			local tid = E.assetType(item.Id)
			if tid then
				addToDesc(nl, item.Id, tid)
			end
		end
	end
	local done = E.commit(nl, bundleName)
	if done then
		toast("Bundle dipakai: " .. tostring(bundleName or bundleId), "ok")
	end
	return done
end

function E.applyUserVisual(userId, displayName, keepLook)
	local desc, derr = descFromUser(userId)
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
		toast("Tunggu sebentar, avatar masih diproses...", "warn")
		return false
	end
	if E.remote then
		local desc = descFromUser(userId)
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
	E.busy = true
	local ok, res, why = pcall(E.applyUserVisual, userId, displayName)
	E.busy = false
	if ok and res then
		E.lastMethod = "donor-render"
		toast("Avatar dipakai: " .. tostring(displayName or userId) .. "  (donor-render)", "ok")
		return true
	end
	toast("Avatar tidak bisa dipasang: " .. tostring(ok and why or res) .. "  (lihat tab Log)", "danger")
	return false
end

function E.removeAll()
	local nl = E.look:Clone()
	nl:SetAccessories({}, true)
	E.failed = {}
	return E.commit(nl, "lepas semua")
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

-- ukuran tubuh & warna kulit (langsung, tanpa ApplyDescription)
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
	if not E.remote and not ok then
		toast("Hanya jalur native yang aktif. Untuk hasil paling pasti, pasang AvatarStudioServer.lua di ServerScriptService.", "warn")
	end
end

-- deteksi kemampuan lingkungan (false = pasti tidak bisa, true = bisa, nil = belum pasti)
function E.probe()
	local cap = {}
	local ok, r = pcall(function()
		return game:GetObjects("rbxassetid://1028606")
	end)
	if not ok then
		cap.getObjects = false
	elseif type(r) == "table" and #r > 0 then
		cap.getObjects = true
	end
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
	E.cap = cap
	E.injectFirst = (cap.getObjects ~= false) or (cap.insert ~= false) or (cap.donor ~= false)
	logf("probe: GetObjects=%s LoadAsset=%s Donor=%s -> inject-first=%s", tostring(cap.getObjects), tostring(cap.insert),
		tostring(cap.donor), tostring(E.injectFirst))
end

-- tes lengkap: mencari penyebab item/avatar/animasi tidak muncul
function E.fullTest()
	if E.testing then
		return
	end
	E.testing = true
	local function res(name, ok, detail)
		logf("%s  %s%s", ok and "[ OK ]" or "[GAGAL]", name, detail and (" -> " .. tostring(detail)) or "")
	end
	local okAll, err = pcall(function()
		logf("===== TES PENYEBAB =====")
		local exName = "tidak diketahui"
		pcall(function()
			if identifyexecutor then
				exName = tostring((identifyexecutor()))
			end
		end)
		logf("Executor: %s | PlaceId: %s | Server script: %s", exName, tostring(game.PlaceId), E.remote and "ADA" or "tidak ada")
		logf("API baru: ApplyDescriptionAsync=%s | CreateHumanoidModelFromDescriptionAsync=%s | GetHumanoidDescriptionFromUserIdAsync=%s | GetProductInfoAsync=%s",
			tostring(hasMember(Instance.new("Humanoid"), "ApplyDescriptionAsync")),
			tostring(hasMember(Players, "CreateHumanoidModelFromDescriptionAsync")),
			tostring(hasMember(Players, "GetHumanoidDescriptionFromUserIdAsync")),
			tostring(hasMember(MarketplaceService, "GetProductInfoAsync")))
		local hum, char = E.humanoid()
		res("Karakter & Humanoid", true, "rig " .. hum.RigType.Name .. ", aksesori " .. countAccessories(char)
			.. ", Animate " .. (char:FindFirstChild("Animate") and "ada" or "TIDAK ADA"))

		local ok1, r1 = pcall(function()
			return game:GetObjects("rbxassetid://1028606")
		end)
		local gObj = ok1 and type(r1) == "table" and #r1 > 0
		res("game:GetObjects", gObj, ok1 and ("kelas: " .. ((r1 and r1[1]) and r1[1].ClassName or "kosong")) or tostring(r1))

		local ok2, r2 = pcall(function()
			return InsertService:LoadAsset(1028606)
		end)
		local gIns = ok2 and r2 ~= nil
		res("InsertService:LoadAsset", gIns, ok2 and "bisa" or tostring(r2))
		if ok2 and r2 then
			r2:Destroy()
		end

		local dd = Instance.new("HumanoidDescription")
		addToDesc(dd, 1028606, 8)
		local dm = donorModel(dd)
		local gDon = dm ~= nil and dm:FindFirstChildOfClass("Accessory") ~= nil
		res("Donor rig (CreateHumanoidModelFromDescription)", gDon, dm and "model terbentuk" or "gagal / diblokir")
		if dm then
			dm:Destroy()
		end

		local ok4, r4 = pcall(function()
			return Players:GetCharacterAppearanceAsync(1)
		end)
		res("GetCharacterAppearanceAsync", ok4 and r4 ~= nil, ok4 and "bisa" or tostring(r4))
		if ok4 and r4 then
			r4:Destroy()
		end

		local r5 = productInfo(1028606, Enum.InfoType.Asset)
		local ok5 = r5 ~= nil
		res("MarketplaceService:GetProductInfo", ok5 and r5 ~= nil, ok5 and "bisa" or tostring(r5))

		local ok6, r6 = pcall(function()
			local prm = CatalogSearchParams.new()
			prm.SearchKeyword = "cap"
			local pg = AvatarEditorService:SearchCatalog(prm)
			return #pg:GetCurrentPage()
		end)
		res("AvatarEditorService:SearchCatalog", ok6 and r6 and r6 > 0, ok6 and (tostring(r6) .. " hasil") or tostring(r6))

		local hb, he = httpGet("https://catalog.roblox.com/v2/search/items/details?assetTypeIds=8&Limit=10")
		res("Katalog via web (HttpGet/request)", hb ~= nil and string.find(hb, "data", 1, true) ~= nil,
			hb and ("respons " .. #hb .. " byte") or tostring(he))

		local ok7, r7 = callAny(hum, { "ApplyDescriptionAsync", "ApplyDescription" }, appliedDesc(hum))
		res("ApplyDescription ke karakter sendiri (biasanya DITOLAK di klien)", ok7, ok7 and "tidak error" or tostring(r7))

		E.cap = { getObjects = ok1 and (gObj or nil) or false, insert = ok2 and (gIns or nil) or false, donor = gDon or false }
		E.injectFirst = (E.cap.getObjects ~= false) or (E.cap.insert ~= false) or (E.cap.donor ~= false)

		-- uji pemasangan topi sungguhan
		local injOk = E.inject(1028606, 8)
		task.wait(1.2)
		local c = char:FindFirstChild("AS_1028606")
		local handle = c and c:FindFirstChild("Handle")
		local detail
		local tooFar = false
		if not injOk then
			detail = E.lastInjectErr or "inject mengembalikan gagal"
		elseif not c then
			detail = "topi HILANG setelah 1 detik (map menghapusnya?)"
		else
			local mesh = handle and handle:FindFirstChildOfClass("SpecialMesh")
			local head = char:FindFirstChild("Head")
			local dist = (handle and head) and (handle.Position - head.Position).Magnitude or nil
			detail = "handle=" .. (handle and "ada" or "TIDAK ADA") .. ", weld="
				.. ((handle and handle:FindFirstChildOfClass("Weld")) and "ada" or "TIDAK ADA")
				.. ", mesh=" .. tostring(handle and (handle:IsA("MeshPart") and handle.MeshId or (mesh and mesh.MeshId)) or "-")
				.. ", jarak ke kepala=" .. (dist and string.format("%.1f", dist) or "?") .. " studs"
			if dist and dist > 8 then
				tooFar = true
				detail = detail .. "  <-- TIDAK MENEMPEL (las gagal)"
			end
		end
		res("Pasang topi uji (inject)", injOk and c ~= nil and not tooFar, detail)
		if c then
			c:Destroy()
		end
		char:SetAttribute("ASX_1028606", nil)

		logf("----- KESIMPULAN -----")
		if not (gObj or gIns or gDon) then
			logf("Tidak ada pemuat aset yang jalan di sini -> item katalog TIDAK bisa dipasang oleh script ini.")
		elseif tooFar then
			logf("Aksesori masuk ke karakter tapi TIDAK menempel (las gagal / rig tidak cocok).")
		elseif not injOk then
			logf("Pemuat ada, tapi pemasangan gagal: %s", tostring(E.lastInjectErr))
		else
			logf("Pemasangan topi uji BERHASIL. Jika item lain tetap tidak muncul, kirim baris log 'inject ... GAGAL'.")
		end
		if hum.RigType == Enum.HumanoidRigType.R6 then
			logf("Rig R6: pakaian layered tidak akan terlihat; aksesori biasa & pakaian klasik masih bisa.")
		end
	end)
	if not okAll then
		logf("[ERROR TES] %s", tostring(err))
	end
	E.testing = false
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
	E.remote = ReplicatedStorage:FindFirstChild(REMOTE_NAME) or ReplicatedStorage:WaitForChild(REMOTE_NAME, 2)
	E.probe()
	local d = appliedDesc(hum)
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
		while task.wait(0.75) do
			if E.injectFirst and not E.remote and not E.busy then
				pcall(E.guard)
			end
		end
	end)
	fire()
end

----------------------------------------------------------------------------
-- [6] KATALOG
----------------------------------------------------------------------------
local CATEGORIES = {}
local function C(group, id, name, kind, list)
	table.insert(CATEGORIES, { group = group, id = id, name = name, kind = kind, list = list })
end

C("KOLEKSI", "fav", "★ Favorit", "fav")
C("KOLEKSI", "recent", "Terakhir dipakai", "recent")
C("SET & BUNDLE", "b_body", "Karakter / Tubuh", "bundle", { "BodyParts" })
C("SET & BUNDLE", "b_anim", "Paket Animasi", "bundle", { "Animations" })
C("SET & BUNDLE", "b_shoes", "Set Sepatu", "bundle", { "Shoes" })
C("AKSESORI", "hat", "Topi", "asset", { "Hat" })
C("AKSESORI", "hair", "Rambut", "asset", { "HairAccessory" })
C("AKSESORI", "face_acc", "Wajah", "asset", { "FaceAccessory" })
C("AKSESORI", "neck", "Leher", "asset", { "NeckAccessory" })
C("AKSESORI", "shoulder", "Bahu", "asset", { "ShoulderAccessory" })
C("AKSESORI", "front", "Depan", "asset", { "FrontAccessory" })
C("AKSESORI", "back", "Punggung", "asset", { "BackAccessory" })
C("AKSESORI", "waist", "Pinggang", "asset", { "WaistAccessory" })
C("PAKAIAN LAYERED", "jacket", "Jaket", "asset", { "JacketAccessory" })
C("PAKAIAN LAYERED", "sweater", "Sweater", "asset", { "SweaterAccessory" })
C("PAKAIAN LAYERED", "l_shirt", "Kemeja", "asset", { "ShirtAccessory" })
C("PAKAIAN LAYERED", "l_tshirt", "Kaos", "asset", { "TShirtAccessory" })
C("PAKAIAN LAYERED", "l_pants", "Celana", "asset", { "PantsAccessory" })
C("PAKAIAN LAYERED", "shorts", "Celana Pendek", "asset", { "ShortsAccessory" })
C("PAKAIAN LAYERED", "dress", "Gaun / Rok", "asset", { "DressSkirtAccessory" })
C("PAKAIAN LAYERED", "lshoe", "Sepatu Kiri", "asset", { "LeftShoeAccessory" })
C("PAKAIAN LAYERED", "rshoe", "Sepatu Kanan", "asset", { "RightShoeAccessory" })
C("PAKAIAN KLASIK", "shirt", "Kemeja Klasik", "asset", { "Shirt" })
C("PAKAIAN KLASIK", "pants", "Celana Klasik", "asset", { "Pants" })
C("PAKAIAN KLASIK", "tshirt", "Kaos Grafis", "asset", { "TShirt" })
C("TUBUH", "face", "Ekspresi Wajah", "asset", { "Face" })
C("TUBUH", "head", "Kepala", "asset", { "Head" })
C("TUBUH", "torso", "Badan", "asset", { "Torso" })
C("TUBUH", "rarm", "Lengan Kanan", "asset", { "RightArm" })
C("TUBUH", "larm", "Lengan Kiri", "asset", { "LeftArm" })
C("TUBUH", "rleg", "Kaki Kanan", "asset", { "RightLeg" })
C("TUBUH", "lleg", "Kaki Kiri", "asset", { "LeftLeg" })
C("TUBUH", "brow", "Alis", "asset", { "EyebrowAccessory" })
C("TUBUH", "lash", "Bulu Mata", "asset", { "EyelashAccessory" })
C("ANIMASI", "a_idle", "Idle", "asset", { "IdleAnimation" })
C("ANIMASI", "a_walk", "Jalan", "asset", { "WalkAnimation" })
C("ANIMASI", "a_run", "Lari", "asset", { "RunAnimation" })
C("ANIMASI", "a_jump", "Lompat", "asset", { "JumpAnimation" })
C("ANIMASI", "a_fall", "Jatuh", "asset", { "FallAnimation" })
C("ANIMASI", "a_climb", "Panjat", "asset", { "ClimbAnimation" })
C("ANIMASI", "a_swim", "Renang", "asset", { "SwimAnimation" })
C("ANIMASI", "a_mood", "Mood", "asset", { "MoodAnimation" })

local SORTS = {
	{ name = "Relevansi", enum = "Relevance" },
	{ name = "Terfavorit", enum = "MostFavorited" },
	{ name = "Terlaris", enum = "Bestselling" },
	{ name = "Terbaru", enum = "RecentlyCreated" },
	{ name = "Termurah", enum = "PriceLowToHigh" },
	{ name = "Termahal", enum = "PriceHighToLow" },
}

for _, c in ipairs(CATEGORIES) do
	if c.id == "b_body" then
		c.httpCat = 4
	elseif c.id == "b_anim" then
		c.httpCat = 12
	elseif c.id == "b_shoes" then
		c.httpCat = 3
	end
end

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
	local assetIds, bundleIds = {}, {}
	for _, it in ipairs(res) do
		if it.ItemType == "Bundle" or it.ItemType == Enum.AvatarItemType.Bundle then
			table.insert(bundleIds, it.Id)
		else
			table.insert(assetIds, it.Id)
		end
	end
	local aD = fetchDetails(assetIds, Enum.AvatarItemType.Asset)
	local bD = fetchDetails(bundleIds, Enum.AvatarItemType.Bundle)
	local items = {}
	for _, it in ipairs(res) do
		local isBundle = it.ItemType == "Bundle" or it.ItemType == Enum.AvatarItemType.Bundle
		local d = (isBundle and bD or aD)[it.Id] or {}
		self.total = self.total + 1
		local nm = d.Name or it.Name or ("Item #" .. it.Id)
		table.insert(items, {
			Id = it.Id, Type = isBundle and "Bundle" or "Asset", Name = nm,
			Price = d.PriceInRobux, Order = self.total,
		})
		if not isBundle then
			E.names[it.Id] = E.names[it.Id] or nm
			if self.tid then
				E.types[it.Id] = self.tid
			end
		end
	end
	return items
end

function Query:httpPage()
	local cat = self.cat
	local common = "&Limit=" .. PAGE_SIZE .. "&SortType=" .. tostring(self.sortNum or 0)
	if self.keyword ~= "" then
		common = common .. "&Keyword=" .. urlenc(self.keyword)
	end
	if self.freeOnly then
		common = common .. "&MaxPrice=0"
	end
	if self.cursor then
		common = common .. "&cursor=" .. urlenc(self.cursor)
	end
	local urls = {}
	for _, host in ipairs({ "https://catalog.roblox.com", "https://catalog.roproxy.com" }) do
		if cat.kind == "asset" and self.tid then
			table.insert(urls, host .. "/v2/search/items/details?assetTypeIds=" .. self.tid .. common)
			table.insert(urls, host .. "/v1/search/items/details?Category=" .. httpCategoryFor(self.tid) .. common)
		else
			table.insert(urls, host .. "/v1/search/items/details?Category=" .. tostring(cat.httpCat or 1) .. common)
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
-- [7] WINDOW
----------------------------------------------------------------------------
local W, H = 860, 520
local UI = {}
local State = { tab = "catalog", cat = nil, keyword = "", sortIdx = 1, freeOnly = false, open = true,
	favorites = {}, favOrder = {}, recent = {}, token = 0 }

UI.gui = mk("ScreenGui", {
	Name = "leon4951hub", ResetOnSpawn = false, IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 50, Parent = playerGui,
})

toastHolder = mk("Frame", {
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 14), Size = UDim2.fromOffset(440, 300),
	BackgroundTransparency = 1, ZIndex = 200, Parent = UI.gui,
})
mk("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
	HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = toastHolder,
})

UI.window = mk("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.fromOffset(W, H),
	BackgroundColor3 = T.Bg, BorderSizePixel = 0, ClipsDescendants = true, Parent = UI.gui,
})
corner(UI.window, 16)
stroke(UI.window, T.Stroke, 1.5)
UI.scale = mk("UIScale", { Parent = UI.window })

local function computeScale()
	local cam = Workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	return math.max(math.min((vp.X - 20) / W, (vp.Y - 20) / H, 1.1), 0.4)
end
UI.scale.Scale = computeScale()

-- titlebar
local TITLE_H = 52
local titlebar = mk("Frame", { Size = UDim2.new(1, 0, 0, TITLE_H), BackgroundColor3 = T.Surface, BorderSizePixel = 0, Parent = UI.window })
local tl = label(titlebar, "leon4951hub", 18, T.Text, Enum.Font.GothamBold)
tl.Position = UDim2.fromOffset(16, 6)
tl.Size = UDim2.new(0, 260, 0, 22)
UI.subtitle = label(titlebar, "Memuat karakter...", 12, T.Dim, Enum.Font.Gotham)
UI.subtitle.Position = UDim2.fromOffset(16, 28)
UI.subtitle.Size = UDim2.new(0, 420, 0, 16)

local tbBtns = mk("Frame", {
	Size = UDim2.fromOffset(200, 36), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
	BackgroundTransparency = 1, Parent = titlebar,
})
mk("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
	HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center,
	Parent = tbBtns,
})
UI.undoBtn = button(tbBtns, { text = "↶", size = UDim2.fromOffset(40, 34), textSize = 18, order = 1,
	onClick = function() task.spawn(E.undo) end })
UI.redoBtn = button(tbBtns, { text = "↷", size = UDim2.fromOffset(40, 34), textSize = 18, order = 2,
	onClick = function() task.spawn(E.doRedo) end })
UI.closeBtn = button(tbBtns, { text = "✕", size = UDim2.fromOffset(40, 34), bg = T.Danger, order = 3 })

-- drag
do
	local dragging, dragStart, startPos = false, nil, nil
	titlebar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, dragStart, startPos = true, input.Position, UI.window.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			UI.window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

-- body
local RAIL_W = 80
local body = mk("Frame", { Position = UDim2.fromOffset(0, TITLE_H), Size = UDim2.new(1, 0, 1, -TITLE_H), BackgroundTransparency = 1, Parent = UI.window })
local rail = mk("Frame", { Size = UDim2.new(0, RAIL_W, 1, 0), BackgroundColor3 = T.Surface, BorderSizePixel = 0, Parent = body })
local railList = mk("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = rail })
vlist(railList, 4)
pad(railList, 6, 8, 6, 8)
UI.content = mk("Frame", {
	Position = UDim2.fromOffset(RAIL_W, 0), Size = UDim2.new(1, -RAIL_W, 1, 0), BackgroundTransparency = 1,
	ClipsDescendants = true, Parent = body,
})

local TABS = {
	{ key = "catalog", icon = "🛍", name = "Katalog" },
	{ key = "worn", icon = "👕", name = "Dipakai" },
	{ key = "avatars", icon = "👥", name = "Avatar" },
	{ key = "body", icon = "📏", name = "Tubuh" },
	{ key = "color", icon = "🎨", name = "Warna" },
	{ key = "log", icon = "📋", name = "Log" },
	{ key = "info", icon = "⚙", name = "Setelan" },
}
UI.pages, UI.builders, UI.built, UI.railBtns, UI.onShow = {}, {}, {}, {}, {}

function UI.showTab(key)
	State.tab = key
	for k, rb in pairs(UI.railBtns) do
		local active = k == key
		rb.btn.BackgroundTransparency = active and 0 or 1
		rb.txt.TextColor3 = active and T.Accent or T.Dim
	end
	for k, p in pairs(UI.pages) do
		p.Visible = k == key
	end
	if not UI.built[key] and UI.builders[key] then
		UI.built[key] = true
		UI.builders[key](UI.pages[key])
	end
	if UI.onShow[key] then
		UI.onShow[key]()
	end
end

for i, tab in ipairs(TABS) do
	local b = mk("TextButton", {
		Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = T.Surface2, BackgroundTransparency = 1, Text = "",
		AutoButtonColor = false, LayoutOrder = i, Parent = railList,
	})
	corner(b, 12)
	mk("TextLabel", { BackgroundTransparency = 1, Text = tab.icon, TextSize = 21, Size = UDim2.new(1, 0, 0, 28), Position = UDim2.fromOffset(0, 6), Parent = b })
	local tx = label(b, tab.name, 11, T.Dim, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
	tx.Size = UDim2.new(1, 0, 0, 16)
	tx.Position = UDim2.fromOffset(0, 36)
	UI.railBtns[tab.key] = { btn = b, txt = tx }
	b.Activated:Connect(function()
		UI.showTab(tab.key)
	end)
	local p = mk("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, Parent = UI.content })
	pad(p, 14)
	UI.pages[tab.key] = p
end

----------------------------------------------------------------------------
-- [8] HALAMAN KATALOG
----------------------------------------------------------------------------
local activeCards = {}

local function addRecent(item)
	for i, r in ipairs(State.recent) do
		if r.Id == item.Id then
			table.remove(State.recent, i)
			break
		end
	end
	table.insert(State.recent, 1, item)
	while #State.recent > 40 do
		table.remove(State.recent)
	end
end

local function toggleFavorite(item)
	if State.favorites[item.Id] then
		State.favorites[item.Id] = nil
		for i, id in ipairs(State.favOrder) do
			if id == item.Id then
				table.remove(State.favOrder, i)
				break
			end
		end
	else
		State.favorites[item.Id] = item
		table.insert(State.favOrder, 1, item.Id)
	end
end

local function makeCard(parent, item, onFav)
	local isBundle = item.Type == "Bundle"
	local card = mk("TextButton", {
		AutoButtonColor = false, Text = "", BackgroundColor3 = T.Surface, BorderSizePixel = 0,
		LayoutOrder = item.Order or 0, Parent = parent,
	})
	corner(card, 12)
	local st = stroke(card, T.Stroke, 1.5, 0.3)
	local img = mk("ImageLabel", {
		Size = UDim2.new(1, -12, 0, 100), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = T.Surface2,
		BorderSizePixel = 0, ScaleType = Enum.ScaleType.Fit,
		Image = thumbURL(isBundle and "BundleThumbnail" or "Asset", item.Id, 150), Parent = card,
	})
	corner(img, 9)
	local nm = label(card, item.Name, 12, T.Text, Enum.Font.GothamBold)
	nm.Position = UDim2.fromOffset(8, 110)
	nm.Size = UDim2.new(1, -16, 0, 16)
	nm.TextTruncate = Enum.TextTruncate.AtEnd
	local pr = label(card, priceText(item.Price), 11, item.Price == 0 and T.Ok or T.Dim, Enum.Font.GothamMedium)
	pr.Position = UDim2.fromOffset(8, 128)
	pr.Size = UDim2.new(1, -16, 0, 14)

	local badge = mk("TextLabel", {
		Size = UDim2.fromOffset(22, 22), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10),
		BackgroundColor3 = T.Ok, Text = "✓", TextColor3 = Color3.new(1, 1, 1), TextSize = 14, Font = Enum.Font.GothamBold,
		BorderSizePixel = 0, Visible = false, ZIndex = 3, Parent = card,
	})
	corner(badge, 11)
	local fav = mk("TextButton", {
		Size = UDim2.fromOffset(26, 26), Position = UDim2.fromOffset(10, 10), BackgroundTransparency = 0.35,
		BackgroundColor3 = Color3.new(0, 0, 0), Text = "♡", TextSize = 16, Font = Enum.Font.GothamBold,
		TextColor3 = Color3.new(1, 1, 1), AutoButtonColor = false, ZIndex = 3, Parent = card,
	})
	corner(fav, 13)
	local overlay = mk("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45,
		Text = "⏳", TextSize = 26, Visible = false, ZIndex = 6, Parent = card,
	})
	corner(overlay, 12)

	local obj = { card = card, item = item, loading = false }
	function obj.update()
		local worn = (not isBundle) and E.isWorn(item.Id)
		badge.Visible = worn
		st.Color = worn and T.Ok or T.Stroke
		st.Transparency = worn and 0 or 0.3
		local isFav = State.favorites[item.Id] ~= nil
		fav.Text = isFav and "♥" or "♡"
		fav.TextColor3 = isFav and T.Danger or Color3.new(1, 1, 1)
	end
	obj.update()

	card.MouseEnter:Connect(function() tween(card, { BackgroundColor3 = T.Surface2 }, 0.12) end)
	card.MouseLeave:Connect(function() tween(card, { BackgroundColor3 = T.Surface }, 0.15) end)
	fav.Activated:Connect(function()
		toggleFavorite(item)
		obj.update()
		if onFav then
			onFav()
		end
	end)
	card.Activated:Connect(function()
		if obj.loading then
			return
		end
		obj.loading = true
		overlay.Visible = true
		task.spawn(function()
			local ok
			if isBundle then
				ok = E.equipBundle(item.Id, item.Name)
			else
				ok = E.toggleAsset(item.Id, item.Name)
			end
			if ok and (isBundle or E.isWorn(item.Id)) then
				addRecent(item)
			end
			overlay.Visible = false
			obj.loading = false
		end)
	end)
	return obj
end

UI.builders.catalog = function(page)
	local CAT_W = 160
	local catPanel = mk("Frame", { Size = UDim2.new(0, CAT_W, 1, 0), BackgroundColor3 = T.Surface, BorderSizePixel = 0, Parent = page })
	corner(catPanel, 12)
	local catScroll = makeScroll(catPanel)
	pad(catScroll, 6, 6, 6, 6)
	vlist(catScroll, 2)

	local main = mk("Frame", {
		Position = UDim2.fromOffset(CAT_W + 10, 0), Size = UDim2.new(1, -(CAT_W + 10), 1, 0),
		BackgroundTransparency = 1, Parent = page,
	})

	-- baris 1: cari + refresh
	local row1 = mk("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Parent = main })
	local sbFrame = mk("Frame", { Size = UDim2.new(1, -46, 1, 0), BackgroundColor3 = T.Surface, BorderSizePixel = 0, Parent = row1 })
	corner(sbFrame, 10)
	stroke(sbFrame, T.Stroke, 1)
	local sbBox = mk("TextBox", {
		Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(12, 0), BackgroundTransparency = 1, Text = "",
		PlaceholderText = "🔍 Cari di kategori ini (Enter)...", PlaceholderColor3 = T.Dim, TextColor3 = T.Text,
		ClearTextOnFocus = false, TextSize = 14, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left,
		Parent = sbFrame,
	})
	local startQuery
	sbBox.FocusLost:Connect(function(enter)
		if enter then
			State.keyword = sbBox.Text
			startQuery()
		end
	end)
	button(row1, { text = "⟳", size = UDim2.fromOffset(38, 38), position = UDim2.new(1, -38, 0, 0), textSize = 20,
		onClick = function() startQuery() end })

	-- baris 2: sort, gratis, jumlah
	local row2 = mk("Frame", { Size = UDim2.new(1, 0, 0, 32), Position = UDim2.fromOffset(0, 44), BackgroundTransparency = 1, Parent = main })
	local sortBtn = button(row2, { text = "↕ " .. SORTS[1].name, size = UDim2.fromOffset(150, 32), textSize = 13,
		onClick = function()
			State.sortIdx = State.sortIdx % #SORTS + 1
			startQuery()
		end })
	local freeBtn
	freeBtn = button(row2, { text = "Gratis", size = UDim2.fromOffset(86, 32), position = UDim2.fromOffset(158, 0), textSize = 13,
		onClick = function()
			State.freeOnly = not State.freeOnly
			startQuery()
		end })
	local countL = label(row2, "", 12, T.Dim, Enum.Font.GothamMedium, Enum.TextXAlignment.Right)
	countL.Size = UDim2.new(1, -440, 1, 0)
	countL.Position = UDim2.fromOffset(252, 0)
	local idBox = mk("TextBox", { Size = UDim2.fromOffset(112, 32), Position = UDim2.new(1, -184, 0, 0), BackgroundColor3 = T.Surface,
		BorderSizePixel = 0, Text = "", PlaceholderText = "ID item", PlaceholderColor3 = T.Dim, TextColor3 = T.Text,
		ClearTextOnFocus = false, TextSize = 13, Font = Enum.Font.GothamMedium, Parent = row2 })
	corner(idBox, 8)
	button(row2, { text = "Pakai", size = UDim2.fromOffset(64, 32), position = UDim2.new(1, -64, 0, 0), bg = T.Accent, textSize = 13,
		onClick = function()
			local id = tonumber(idBox.Text)
			if not id then
				toast("Isi ID angka dulu", "warn")
				return
			end
			task.spawn(function()
				if not E.assetType(id) then
					local t = State.cat and State.cat.list and NAME2TID[State.cat.list[1]]
					if t then
						E.types[id] = t
					end
				end
				E.toggleAsset(id, "ID " .. id)
			end)
		end })

	-- grid
	local grid = makeScroll(main, UDim2.new(1, 0, 1, -84), UDim2.fromOffset(0, 84))
	mk("UIGridLayout", {
		CellSize = UDim2.fromOffset(118, 150), CellPadding = UDim2.fromOffset(7, 8), SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = grid,
	})
	pad(grid, 0, 2, 0, 12)
	local msg = mk("TextLabel", {
		Size = UDim2.new(1, -20, 0, 80), Position = UDim2.fromOffset(10, 110), BackgroundTransparency = 1, Text = "",
		TextColor3 = T.Dim, TextSize = 14, Font = Enum.Font.GothamMedium, TextWrapped = true, Visible = false,
		ZIndex = 5, Parent = main,
	})

	local currentQuery, loading = nil, false

	local function clearGrid()
		msg.Visible = false
		activeCards = {}
		for _, c in ipairs(grid:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		grid.CanvasPosition = Vector2.new(0, 0)
	end

	local function addCard(item)
		table.insert(activeCards, makeCard(grid, item, function()
			if State.cat.kind == "fav" then
				startQuery()
			end
		end))
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
		task.spawn(function()
			local items, err = q:nextPage()
			if token ~= State.token then
				return
			end
			loading = false
			if not items then
				logf("katalog gagal: %s", tostring(err))
				showMsg("⚠ Gagal memuat katalog:\n" .. tostring(err) .. "\n(Di Studio: pakai Play Solo & game harus punya akses API)")
				countL.Text = ""
				return
			end
			msg.Visible = false
			for _, it in ipairs(items) do
				addCard(it)
			end
			if q.total == 0 then
				showMsg("🔎 Tidak ada hasil. Coba kata kunci lain atau matikan filter Gratis.")
			end
			countL.Text = q.total .. " item" .. (q.finished and "" or "+") .. (q.backend and ("  •  " .. q.backend) or "")
		end)
	end

	startQuery = function()
		State.token = State.token + 1
		local token = State.token
		loading = false
		clearGrid()
		sortBtn.Text = "↕ " .. SORTS[State.sortIdx].name
		freeBtn.BackgroundColor3 = State.freeOnly and T.Ok or T.Surface2
		freeBtn.Text = (State.freeOnly and "✓ " or "") .. "Gratis"
		local cat = State.cat
		if cat.kind == "fav" or cat.kind == "recent" then
			currentQuery = nil
			local src = {}
			if cat.kind == "fav" then
				for _, id in ipairs(State.favOrder) do
					if State.favorites[id] then
						table.insert(src, State.favorites[id])
					end
				end
			else
				src = State.recent
			end
			local kw = string.lower(State.keyword or "")
			local n = 0
			for _, it in ipairs(src) do
				if kw == "" or string.find(string.lower(it.Name), kw, 1, true) then
					n = n + 1
					local copy = {}
					for k, v in pairs(it) do
						copy[k] = v
					end
					copy.Order = n
					addCard(copy)
				end
			end
			countL.Text = n .. " item"
			if n == 0 then
				showMsg(cat.kind == "fav" and "★ Belum ada favorit. Tekan ♡ pada item." or "🕘 Belum ada riwayat pemakaian.")
			end
			return
		end
		countL.Text = "memuat..."
		currentQuery = newQuery(cat, State.keyword, State.sortIdx, State.freeOnly)
		loadPage(token)
	end

	grid:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		if grid.CanvasPosition.Y + grid.AbsoluteWindowSize.Y >= grid.AbsoluteCanvasSize.Y - 260 then
			loadPage(State.token)
		end
	end)

	-- daftar kategori
	local catRows = {}
	local function markCat()
		for id, r in pairs(catRows) do
			local active = id == State.cat.id
			r.btn.BackgroundTransparency = active and 0 or 1
			r.txt.TextColor3 = active and T.Accent or T.Text
		end
	end
	local function selectCat(cat)
		State.cat = cat
		State.keyword = ""
		sbBox.Text = ""
		markCat()
		startQuery()
	end

	local order, lastGroup = 0, nil
	for _, cat in ipairs(CATEGORIES) do
		if cat.group ~= lastGroup then
			lastGroup = cat.group
			order = order + 1
			local h = label(catScroll, cat.group, 11, T.Dim, Enum.Font.GothamBold)
			h.LayoutOrder = order
			h.Size = UDim2.new(1, 0, 0, 24)
			h.TextYAlignment = Enum.TextYAlignment.Bottom
		end
		order = order + 1
		local b = mk("TextButton", {
			Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = T.Surface2, BackgroundTransparency = 1, Text = "",
			AutoButtonColor = false, LayoutOrder = order, Parent = catScroll,
		})
		corner(b, 8)
		local t = label(b, cat.name, 13, T.Text, Enum.Font.GothamMedium)
		t.Size = UDim2.new(1, -16, 1, 0)
		t.Position = UDim2.fromOffset(10, 0)
		t.TextTruncate = Enum.TextTruncate.AtEnd
		catRows[cat.id] = { btn = b, txt = t }
		b.Activated:Connect(function()
			selectCat(cat)
		end)
	end

	UI.refreshCards = function()
		for _, c in ipairs(activeCards) do
			c.update()
		end
	end
	UI.onShow.catalog = UI.refreshCards

	for _, cat in ipairs(CATEGORIES) do
		if cat.id == "hat" then
			selectCat(cat)
			break
		end
	end
end

----------------------------------------------------------------------------
-- [9] HALAMAN DIPAKAI
----------------------------------------------------------------------------
UI.builders.worn = function(page)
	local head = mk("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = page })
	label(head, "Sedang dipakai", 20, T.Text, Enum.Font.GothamBold).Size = UDim2.new(0.6, 0, 0, 26)
	local sub = label(head, "", 12, T.Dim, Enum.Font.Gotham)
	sub.Position = UDim2.fromOffset(0, 24)
	sub.Size = UDim2.new(0.7, 0, 0, 16)
	button(head, { text = "Lepas semua aksesori", size = UDim2.fromOffset(170, 32), anchor = Vector2.new(1, 0),
		position = UDim2.new(1, 0, 0, 2), bg = T.Danger, textSize = 13,
		onClick = function() task.spawn(E.removeAll) end })
	button(head, { text = "↺ Reset", size = UDim2.fromOffset(80, 32), anchor = Vector2.new(1, 0),
		position = UDim2.new(1, -178, 0, 2), textSize = 13, onClick = function() task.spawn(E.reset) end })

	local list = makeScroll(page, UDim2.new(1, 0, 1, -50), UDim2.fromOffset(0, 50))
	vlist(list, 8)
	pad(list, 0, 0, 8, 10)

	UI.refreshWorn = function()
		for _, c in ipairs(list:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		local items = E.wornList()
		sub.Text = #items .. " item aktif pada karakter"
		for n, e in ipairs(items) do
			local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = T.Surface, BorderSizePixel = 0, LayoutOrder = n, Parent = list })
			corner(row, 12)
			local img = mk("ImageLabel", { Size = UDim2.fromOffset(42, 42), Position = UDim2.fromOffset(8, 8), BackgroundColor3 = T.Surface2,
				BorderSizePixel = 0, Image = thumbURL("Asset", e.Id, 150), Parent = row })
			corner(img, 8)
			local nameL = label(row, "Memuat nama...", 14, T.Text, Enum.Font.GothamBold)
			nameL.Position = UDim2.fromOffset(60, 10)
			nameL.Size = UDim2.new(1, -160, 0, 20)
			nameL.TextTruncate = Enum.TextTruncate.AtEnd
			local typeL = label(row, e.Label .. (E.failed[e.Id] and "  •  injector" or ""), 12, T.Dim, Enum.Font.Gotham)
			typeL.Position = UDim2.fromOffset(60, 30)
			typeL.Size = UDim2.new(1, -160, 0, 16)
			button(row, { text = "Lepas", size = UDim2.fromOffset(72, 30), anchor = Vector2.new(1, 0.5), position = UDim2.new(1, -10, 0.5, 0),
				textSize = 13, onClick = function() task.spawn(E.removeAsset, e.Id) end })
			task.spawn(function()
				local nm = E.name(e.Id)
				if nameL.Parent then
					nameL.Text = nm
				end
			end)
		end
	end
	UI.onShow.worn = UI.refreshWorn
	UI.refreshWorn()
end

----------------------------------------------------------------------------
-- [10] HALAMAN AVATAR (preset, server, teman)
----------------------------------------------------------------------------
local PRESETS = { { "Roblox", 1 }, { "builderman", 156 }, { "Shedletsky", 261 }, { "Aku (asli)", player.UserId } }

local function userCard(parent, userId, name, order)
	local card = mk("TextButton", { BackgroundColor3 = T.Surface, BorderSizePixel = 0, AutoButtonColor = false, Text = "", LayoutOrder = order or 0, Parent = parent })
	corner(card, 12)
	local img = mk("ImageLabel", { Size = UDim2.fromOffset(70, 70), Position = UDim2.fromOffset(11, 8), BackgroundColor3 = T.Surface2,
		BorderSizePixel = 0, Image = thumbURL("AvatarHeadShot", userId, 150), Parent = card })
	corner(img, 35)
	local nm = label(card, name, 12, T.Text, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
	nm.Position = UDim2.fromOffset(4, 82)
	nm.Size = UDim2.new(1, -8, 0, 16)
	nm.TextTruncate = Enum.TextTruncate.AtEnd
	local hint = label(card, "klik untuk pakai", 10, T.Dim, Enum.Font.Gotham, Enum.TextXAlignment.Center)
	hint.Position = UDim2.fromOffset(4, 98)
	hint.Size = UDim2.new(1, -8, 0, 14)
	card.MouseEnter:Connect(function() tween(card, { BackgroundColor3 = T.Surface2 }, 0.12) end)
	card.MouseLeave:Connect(function() tween(card, { BackgroundColor3 = T.Surface }, 0.15) end)
	local busyCard = false
	card.Activated:Connect(function()
		if busyCard then
			return
		end
		busyCard = true
		hint.Text = "memuat..."
		task.spawn(function()
			if userId == player.UserId then
				E.reset()
			else
				E.applyUser(userId, name)
			end
			hint.Text = "klik untuk pakai"
			busyCard = false
		end)
	end)
	return card
end

local function userGrid(parent, order)
	local g = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = order, Parent = parent })
	mk("UIGridLayout", { CellSize = UDim2.fromOffset(92, 118), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = g })
	return g
end

UI.builders.avatars = function(page)
	local scroll = makeScroll(page)
	vlist(scroll, 8)
	pad(scroll, 0, 0, 8, 12)
	local t = label(scroll, "Coba avatar pemain lain", 20, T.Text, Enum.Font.GothamBold)
	t.LayoutOrder = 1
	t.Size = UDim2.new(1, 0, 0, 26)

	local h1 = label(scroll, "PRESET", 12, T.Dim, Enum.Font.GothamBold)
	h1.LayoutOrder = 3
	local presetGrid = userGrid(scroll, 4)
	for i, p in ipairs(PRESETS) do
		userCard(presetGrid, p[2], p[1], i)
	end

	local h2 = label(scroll, "PEMAIN DI SERVER INI", 12, T.Dim, Enum.Font.GothamBold)
	h2.LayoutOrder = 5
	local serverGrid = userGrid(scroll, 6)
	local function refreshServer()
		for _, c in ipairs(serverGrid:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		local n = 0
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player then
				n = n + 1
				userCard(serverGrid, p.UserId, p.DisplayName, n)
			end
		end
	end
	UI.onShow.avatars = refreshServer
	refreshServer()

	local h3 = label(scroll, "TEMAN", 12, T.Dim, Enum.Font.GothamBold)
	h3.LayoutOrder = 8
	local friendGrid = userGrid(scroll, 9)
	local status = label(scroll, "Memuat daftar teman...", 12, T.Dim, Enum.Font.Gotham)
	status.LayoutOrder = 10
	task.spawn(function()
		local ok, pages = pcall(function()
			return Players:GetFriendsAsync(player.UserId)
		end)
		if not ok or not pages then
			status.Text = "Daftar teman tidak bisa dimuat."
			return
		end
		local count, done = 0, false
		while not done and count < 72 do
			for _, f in ipairs(pages:GetCurrentPage()) do
				count = count + 1
				userCard(friendGrid, f.Id, f.DisplayName or f.Username, count)
			end
			if pages.IsFinished then
				done = true
			elseif not pcall(function() pages:AdvanceToNextPageAsync() end) then
				done = true
			end
		end
		status.Text = count == 0 and "Belum ada teman di akun ini." or (count .. " teman dimuat")
	end)
end

----------------------------------------------------------------------------
-- [11] HALAMAN TUBUH & WARNA
----------------------------------------------------------------------------
local function slider(parent, o)
	local min, max, step = o.min, o.max, o.step or 0.01
	local value = o.value or min
	local holder = mk("Frame", { Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1, LayoutOrder = o.order or 0, Parent = parent })
	label(holder, o.text or "", 13, T.Text, Enum.Font.GothamMedium).Size = UDim2.new(0.6, 0, 0, 20)
	local valL = label(holder, "", 13, T.Dim, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
	valL.Size = UDim2.new(0.4, 0, 0, 20)
	valL.Position = UDim2.new(0.6, 0, 0, 0)
	local track = mk("Frame", { Size = UDim2.new(1, 0, 0, 6), Position = UDim2.fromOffset(0, 32), BackgroundColor3 = T.Surface2, BorderSizePixel = 0, Parent = holder })
	corner(track, 3)
	local fill = mk("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = T.Accent, BorderSizePixel = 0, Parent = track })
	corner(fill, 3)
	local knob = mk("Frame", { Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = T.Text, BorderSizePixel = 0, ZIndex = 2, Parent = track })
	corner(knob, 8)
	local hit = mk("TextButton", { Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 20), BackgroundTransparency = 1, Text = "", Parent = holder })

	local function setValue(v, doFire)
		v = math.clamp(v, min, max)
		v = math.floor(v / step + 0.5) * step
		value = v
		local a = (max - min) > 0 and (v - min) / (max - min) or 0
		fill.Size = UDim2.new(a, 0, 1, 0)
		knob.Position = UDim2.new(a, 0, 0.5, 0)
		valL.Text = o.format and o.format(v) or string.format("%.2f", v)
		if doFire and o.onChange then
			o.onChange(v)
		end
	end
	local dragging = false
	local function fromInput(input)
		local a = math.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		setValue(min + (max - min) * a, true)
	end
	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			fromInput(input)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			fromInput(input)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	setValue(value, false)
	return { Set = function(v) setValue(v, false) end }
end

UI.builders.body = function(page)
	local scroll = makeScroll(page)
	vlist(scroll, 6)
	pad(scroll, 0, 0, 10, 12)
	local t = label(scroll, "Ukuran tubuh", 20, T.Text, Enum.Font.GothamBold)
	t.LayoutOrder = 1
	t.Size = UDim2.new(1, 0, 0, 26)
	local s = label(scroll, "Geser slider, perubahan langsung terlihat (hanya rig R15).", 12, T.Dim, Enum.Font.Gotham)
	s.LayoutOrder = 2
	local defs = {
		{ "Height", "Tinggi", 0.9, 1.05 }, { "Width", "Lebar", 0.7, 1.0 }, { "Depth", "Ketebalan", 0.7, 1.0 },
		{ "Head", "Ukuran kepala", 0.95, 1.0 }, { "Proportion", "Proporsi", 0, 1 }, { "BodyType", "Tipe tubuh", 0, 1 },
	}
	local sliders = {}
	for i, d in ipairs(defs) do
		sliders[d[1]] = slider(scroll, { text = d[2], min = d[3], max = d[4], value = 1, order = 10 + i,
			onChange = function(v) E.setScale(d[1], v) end })
	end
	button(scroll, { text = "Reset ukuran", size = UDim2.new(1, 0, 0, 36), order = 30, onClick = function()
		E.resetScales()
		toast("Ukuran tubuh direset", "ok")
	end })
	UI.onShow.body = function()
		local hum = E.humanoid()
		for key, nvName in pairs(SCALE_VALUES) do
			local nv = hum:FindFirstChild(nvName)
			if nv and nv:IsA("NumberValue") and sliders[key] then
				sliders[key].Set(nv.Value)
			end
		end
	end
	UI.onShow.body()
end

local PALETTE = {
	rgb(255, 224, 189), rgb(255, 205, 148), rgb(234, 184, 146), rgb(224, 172, 105), rgb(204, 142, 105),
	rgb(198, 134, 66), rgb(160, 95, 53), rgb(141, 85, 36), rgb(124, 92, 70), rgb(105, 64, 40),
	rgb(86, 52, 32), rgb(62, 39, 25), rgb(253, 234, 141), rgb(245, 205, 48), rgb(218, 133, 65),
	rgb(196, 40, 28), rgb(255, 152, 220), rgb(167, 94, 155), rgb(98, 71, 170), rgb(13, 105, 172),
	rgb(18, 238, 212), rgb(75, 151, 75), rgb(164, 189, 71), rgb(163, 162, 165), rgb(205, 205, 205),
	rgb(242, 243, 243), rgb(99, 95, 98), rgb(27, 42, 53),
}

UI.builders.color = function(page)
	local scroll = makeScroll(page)
	vlist(scroll, 8)
	pad(scroll, 0, 0, 10, 12)
	local t = label(scroll, "Warna kulit", 20, T.Text, Enum.Font.GothamBold)
	t.LayoutOrder = 1
	t.Size = UDim2.new(1, 0, 0, 26)
	local grid = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 3, Parent = scroll })
	mk("UIGridLayout", { CellSize = UDim2.fromOffset(52, 52), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
	for i, c in ipairs(PALETTE) do
		local sw = mk("TextButton", { BackgroundColor3 = c, Text = "", AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = i, Parent = grid })
		corner(sw, 14)
		stroke(sw, T.Stroke, 2, 0.3)
		sw.Activated:Connect(function()
			E.setSkin(c)
		end)
	end
	button(scroll, { text = "Kembalikan warna asli", size = UDim2.new(1, 0, 0, 36), order = 14, onClick = function()
		E.resetSkin()
		toast("Warna kulit dikembalikan", "ok")
	end })
end

----------------------------------------------------------------------------
-- [12] HALAMAN SETELAN
----------------------------------------------------------------------------
UI.builders.log = function(page)
	local head = mk("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = page })
	label(head, "Log & Tes Penyebab", 20, T.Text, Enum.Font.GothamBold).Size = UDim2.new(1, 0, 0, 26)
	local sub = label(head, "Jalankan tes, lalu salin log dan kirim ke pembuat script.", 12, T.Dim, Enum.Font.Gotham)
	sub.Position = UDim2.fromOffset(0, 24)
	local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 34), Position = UDim2.fromOffset(0, 46), BackgroundTransparency = 1, Parent = page })
	button(row, { text = "▶ Jalankan Tes Penyebab", size = UDim2.new(0.42, -4, 1, 0), bg = T.Accent, textSize = 13,
		onClick = function() task.spawn(E.fullTest) end })
	button(row, { text = "📋 Salin", size = UDim2.new(0.29, -4, 1, 0), position = UDim2.new(0.42, 0, 0, 0), textSize = 13,
		onClick = function()
			local ok = pcall(function()
				setclipboard(table.concat(LOG, "\n"))
			end)
			toast(ok and "Log disalin ke clipboard" or "setclipboard tidak ada di executor ini: blok lalu salin manual dari kotak log", ok and "ok" or "warn")
		end })
	button(row, { text = "Bersihkan", size = UDim2.new(0.29, 0, 1, 0), position = UDim2.new(0.71, 0, 0, 0), textSize = 13,
		onClick = function()
			for i = #LOG, 1, -1 do
				LOG[i] = nil
			end
			if logHook then
				logHook()
			end
		end })
	local sc = makeScroll(page, UDim2.new(1, 0, 1, -88), UDim2.fromOffset(0, 88))
	local box = mk("TextBox", {
		Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.Surface, BorderSizePixel = 0,
		TextColor3 = T.Text, Font = Enum.Font.Code, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, MultiLine = true, TextEditable = false,
		ClearTextOnFocus = false, Text = "", Parent = sc,
	})
	corner(box, 8)
	pad(box, 8, 8, 8, 8)
	logHook = function()
		box.Text = table.concat(LOG, "\n")
		sc.CanvasPosition = Vector2.new(0, 100000)
	end
	logHook()
end

UI.builders.info = function(page)
	local scroll = makeScroll(page)
	vlist(scroll, 8)
	pad(scroll, 0, 0, 10, 12)
	local t = label(scroll, "Setelan & diagnostik", 20, T.Text, Enum.Font.GothamBold)
	t.LayoutOrder = 1
	t.Size = UDim2.new(1, 0, 0, 26)
	local txt = label(scroll,
		"K  buka / tutup UI\nCtrl+Z  undo   •   Ctrl+Y  redo\n\nJika item tidak muncul: tekan Diagnostik, lalu pasang "
		.. "AvatarStudioServer.lua di ServerScriptService (jalur paling pasti).", 13, T.Dim, Enum.Font.GothamMedium)
	txt.LayoutOrder = 2
	txt.TextWrapped = true
	txt.TextYAlignment = Enum.TextYAlignment.Top
	txt.Size = UDim2.new(1, 0, 0, 90)
	button(scroll, { text = "🩺 Tes penyebab (buka Log)", size = UDim2.new(1, 0, 0, 36), bg = T.Accent, order = 3,
		onClick = function() UI.showTab("log") task.spawn(E.fullTest) end })
	local mb
	mb = button(scroll, { text = "Gaya skin: BONEKA (bentuk tubuh donor utuh)", size = UDim2.new(1, 0, 0, 36), order = 3,
		onClick = function()
			E.skinMode = (E.skinMode == "puppet") and "weld" or "puppet"
			mb.Text = "Gaya skin: " .. (E.skinMode == "puppet" and "BONEKA (bentuk tubuh donor utuh)" or "LAS PER-BAGIAN")
			task.spawn(E.rerender)
		end })
	local sb
	sb = button(scroll, { text = "Mode kulit overlay (badan ikut berubah): HIDUP", size = UDim2.new(1, 0, 0, 36), order = 3,
		onClick = function()
			E.useSkin = not E.useSkin
			sb.Text = "Mode kulit overlay (badan ikut berubah): " .. (E.useSkin and "HIDUP" or "MATI")
			task.spawn(E.rerender)
		end })
	button(scroll, { text = "🦴 Pulihkan badan/tangan/kaki", size = UDim2.new(1, 0, 0, 36), order = 3,
		onClick = function() task.spawn(E.restoreBody) end })
	local cb
	cb = button(scroll, { text = "Salin bentuk tubuh donor: MATI", size = UDim2.new(1, 0, 0, 36), order = 3,
		onClick = function()
			E.copyBody = not E.copyBody
			cb.Text = "Salin bentuk tubuh donor: " .. (E.copyBody and "HIDUP (eksperimental)" or "MATI")
		end })
	button(scroll, { text = "↻ Render ulang avatar (jika item hilang)", size = UDim2.new(1, 0, 0, 36), order = 3,
		onClick = function() task.spawn(E.rerender) end })
	button(scroll, { text = "Tutup UI", size = UDim2.new(1, 0, 0, 36), order = 4, onClick = function() UI.setOpen(false) end })
	button(scroll, { text = "Hapus UI sepenuhnya", size = UDim2.new(1, 0, 0, 36), bg = T.Danger, order = 5,
		onClick = function() UI.gui:Destroy() end })
end

----------------------------------------------------------------------------
-- [13] BUKA/TUTUP, KEYBIND, REAKSI
----------------------------------------------------------------------------
UI.fab = mk("TextButton", {
	Size = UDim2.fromOffset(54, 54), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0), Text = "👗",
	TextSize = 26, AutoButtonColor = false, BackgroundColor3 = T.Accent, BorderSizePixel = 0, Visible = false, ZIndex = 20, Parent = UI.gui,
})
corner(UI.fab, 27)
-- tombol 👗 bisa digeser; sentuh/klik tanpa geser = buka UI
do
	local fab = UI.fab
	local dragging, moved, startPos, startAbs = false, false, nil, nil
	fab.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, moved = true, false
			startPos = input.Position
			startAbs = fab.AbsolutePosition
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local dx, dy = input.Position.X - startPos.X, input.Position.Y - startPos.Y
			if math.abs(dx) + math.abs(dy) > 8 then
				moved = true
			end
			if moved then
				local cam2 = Workspace.CurrentCamera
				local vp = cam2 and cam2.ViewportSize or Vector2.new(1280, 720)
				local x = math.clamp(startAbs.X + dx, 0, vp.X - fab.AbsoluteSize.X)
				local y = math.clamp(startAbs.Y + dy, 0, vp.Y - fab.AbsoluteSize.Y)
				fab.AnchorPoint = Vector2.zero
				fab.Position = UDim2.fromOffset(x, y)
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			if not moved then
				UI.setOpen(true)
			end
		end
	end)
end

function UI.setOpen(open)
	State.open = open
	UI.window.Visible = open
	UI.fab.Visible = not open
end
UI.closeBtn.Activated:Connect(function()
	UI.setOpen(false)
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	if input.KeyCode == TOGGLE_KEY then
		UI.setOpen(not State.open)
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

local cam = Workspace.CurrentCamera
if cam then
	cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		UI.scale.Scale = computeScale()
	end)
end

E.onChanged(function()
	local n = #E.wornList()
	UI.subtitle.Text = n .. " item dipakai  •  mode: " .. (E.lastMethod ~= "" and E.lastMethod or (E.remote and "server" or "native"))
	UI.undoBtn.TextTransparency = #E.history > 0 and 0 or 0.65
	UI.redoBtn.TextTransparency = #E.redo > 0 and 0 or 0.65
	if UI.refreshCards then
		UI.refreshCards()
	end
	if UI.refreshWorn and State.tab == "worn" then
		UI.refreshWorn()
	end
end)

----------------------------------------------------------------------------
-- [14] START
----------------------------------------------------------------------------
UI.showTab("catalog")
UI.setOpen(true)

task.spawn(function()
	local ok, err = pcall(E.init)
	if not ok then
		toast("Gagal menyiapkan karakter: " .. tostring(err), "danger")
		return
	end
	toast("leon4951hub siap! K = buka/tutup  •  mode: " .. (E.remote and "SERVER" or (E.injectFirst and "INJECTOR (visual klien)" or "native")), "ok")
end)
