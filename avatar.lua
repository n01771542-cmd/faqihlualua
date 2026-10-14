--[[
================================================================================
  AVATAR STUDIO  -  script.lua (CRITICAL ENGINE MESH-BYPASS FIX)
  Kostum avatar lengkap (VISUAL ONLY / client-side)

  FITUR
  - Katalog Roblox LIVE (AvatarEditorService): aksesori, pakaian layered,
    pakaian klasik, bagian tubuh, animasi, bundle/set. Semua dimuat otomatis.
  - Klik item = pakai, klik lagi = lepas. Dipasang via HTTP Proxy Asset Engine!
  - Cari kata kunci, urutkan, filter gratis, muat otomatis saat scroll.
  - Favorit, riwayat terakhir dipakai, Undo / Redo.
  - Tab Avatar: coba avatar teman, pemain server, dan preset (tanpa ketik nama).
  - Outfit tersimpan (sesi ini), ukuran tubuh (slider), warna kulit.
  - Preview 3D yang bisa diputar, 6 tema warna, UI skala otomatis (HP/PC).
  - Tombol buka/tutup:  K   |   Undo: Ctrl+Z   |   Redo: Ctrl+Y
================================================================================
]]

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
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local OLD_GUI = playerGui:FindFirstChild("AvatarStudioUI")
if OLD_GUI then
	OLD_GUI:Destroy()
end

----------------------------------------------------------------------------
-- [2] CONFIG
----------------------------------------------------------------------------
local CONFIG = {
	ToggleKey = Enum.KeyCode.K,
	PageSize = 30,
	WindowSize = Vector2.new(940, 580),
	DefaultTheme = "Midnight",
	MaxHistory = 40,
	MaxRecent = 40,
	Presets = {
		{ Name = "Roblox", Id = 1 },
		{ Name = "builderman", Id = 156 },
		{ Name = "Shedletsky", Id = 261 },
	},
}

----------------------------------------------------------------------------
-- [3] THEMES
----------------------------------------------------------------------------
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local THEMES = {
	Midnight = {
		Background = rgb(13, 14, 21), Surface = rgb(21, 23, 33), SurfaceHigh = rgb(31, 34, 49),
		SurfaceHover = rgb(42, 46, 66), Stroke = rgb(46, 50, 70), Text = rgb(240, 242, 250),
		TextDim = rgb(146, 152, 178), Accent = rgb(108, 118, 255), AccentText = rgb(255, 255, 255),
		Success = rgb(72, 199, 142), Danger = rgb(238, 84, 100), Warning = rgb(245, 184, 68),
	},
	Ocean = {
		Background = rgb(8, 17, 27), Surface = rgb(13, 27, 41), SurfaceHigh = rgb(20, 40, 60),
		SurfaceHover = rgb(29, 54, 80), Stroke = rgb(35, 63, 92), Text = rgb(232, 245, 255),
		TextDim = rgb(125, 160, 190), Accent = rgb(40, 170, 255), AccentText = rgb(255, 255, 255),
		Success = rgb(64, 214, 160), Danger = rgb(255, 98, 108), Warning = rgb(255, 196, 80),
	},
	Sakura = {
		Background = rgb(27, 15, 23), Surface = rgb(40, 24, 35), SurfaceHigh = rgb(56, 34, 49),
		SurfaceHover = rgb(75, 46, 66), Stroke = rgb(86, 54, 76), Text = rgb(255, 238, 246),
		TextDim = rgb(190, 148, 172), Accent = rgb(255, 118, 170), AccentText = rgb(255, 255, 255),
		Success = rgb(110, 216, 160), Danger = rgb(255, 92, 110), Warning = rgb(255, 196, 96),
	},
	Emerald = {
		Background = rgb(9, 21, 17), Surface = rgb(15, 33, 27), SurfaceHigh = rgb(22, 48, 40),
		SurfaceHover = rgb(31, 65, 54), Stroke = rgb(38, 78, 65), Text = rgb(232, 255, 245),
		TextDim = rgb(128, 177, 157), Accent = rgb(52, 211, 153), AccentText = rgb(6, 30, 22),
		Success = rgb(96, 226, 170), Danger = rgb(244, 98, 110), Warning = rgb(247, 190, 74),
	},
	Sunset = {
		Background = rgb(24, 14, 14), Surface = rgb(38, 22, 20), SurfaceHigh = rgb(54, 32, 28),
		SurfaceHover = rgb(72, 43, 37), Stroke = rgb(86, 52, 44), Text = rgb(255, 242, 232),
		TextDim = rgb(190, 152, 134), Accent = rgb(255, 140, 66), AccentText = rgb(40, 16, 4),
		Success = rgb(112, 214, 148), Danger = rgb(255, 88, 88), Warning = rgb(255, 204, 84),
	},
	Light = {
		Background = rgb(240, 242, 249), Surface = rgb(255, 255, 255), SurfaceHigh = rgb(232, 235, 245),
		SurfaceHover = rgb(220, 224, 240), Stroke = rgb(210, 215, 232), Text = rgb(26, 29, 44),
		TextDim = rgb(104, 112, 140), Accent = rgb(88, 98, 240), AccentText = rgb(255, 255, 255),
		Success = rgb(34, 170, 110), Danger = rgb(226, 62, 82), Warning = rgb(224, 150, 20),
	},
}
local THEME_ORDER = { "Midnight", "Ocean", "Sakura", "Emerald", "Sunset", "Light" }

local Theme = {}
for k, v in pairs(THEMES[CONFIG.DefaultTheme]) do
	Theme[k] = v
end

----------------------------------------------------------------------------
-- [4] STATE
----------------------------------------------------------------------------
local State = {
	themeName = CONFIG.DefaultTheme,
	uiScale = 1,
	persist = true,        -- pertahankan tampilan saat respawn
	autoRotate = true,     -- preview berputar
	extendedScale = false, -- slider tubuh bebas
	searchToken = 0,
	tab = "catalog",
	cat = nil,
	keyword = "",
	sortKey = "relevance",
	freeOnly = false,
	scales = {},
	skin = nil,
	favorites = {},        -- [id] = item
	favOrder = {},
	recent = {},           -- list item (terbaru di depan)
	outfits = {},
	lastDesc = nil,
	open = true,
	minimized = false,
}

----------------------------------------------------------------------------
-- [5] HELPER DASAR
----------------------------------------------------------------------------
local themedList = {}
local themeHooks = {}

local function themed(inst, prop, key)
	inst[prop] = Theme[key]
	table.insert(themedList, { inst, prop, key })
	return inst
end

local function onTheme(fn)
	table.insert(themeHooks, fn)
	fn()
end

local function applyTheme(name)
	local def = THEMES[name]
	if not def then
		return
	end
	for k, v in pairs(def) do
		Theme[k] = v
	end
	State.themeName = name
	local alive = {}
	for _, e in ipairs(themedList) do
		local inst = e[1]
		if inst.Parent ~= nil then
			TweenService:Create(inst, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { [e[2]] = Theme[e[3]] }):Play()
			table.insert(alive, e)
		end
	end
	themedList = alive
	for _, fn in ipairs(themeHooks) do
		task.spawn(fn)
	end
end

local function New(class, props, children)
	local inst = Instance.new(class)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then
			parent = v
		else
			inst[k] = v
		end
	end
	for _, c in ipairs(children or {}) do
		c.Parent = inst
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function tween(inst, props, t, style, dir)
	local tw = TweenService:Create(
		inst,
		TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
		props
	)
	tw:Play()
	return tw
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

local function corner(inst, r)
	return New("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = inst })
end

local function stroke(inst, key, thickness, transparency)
	local s = New("UIStroke", {
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = inst,
	})
	themed(s, "Color", key or "Stroke")
	return s
end

local function pad(inst, l, t, r, b)
	return New("UIPadding", {
		PaddingLeft = UDim.new(0, l or 0),
		PaddingTop = UDim.new(0, t or l or 0),
		PaddingRight = UDim.new(0, r or l or 0),
		PaddingBottom = UDim.new(0, b or t or l or 0),
		Parent = inst,
	})
end

local function vlist(parent, gap, halign)
	return New("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, gap or 0),
		HorizontalAlignment = halign or Enum.HorizontalAlignment.Left,
		Parent = parent,
	})
end

local function hlist(parent, gap, valign)
	return New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, gap or 0),
		VerticalAlignment = valign or Enum.VerticalAlignment.Center,
		Parent = parent,
	})
end

local function label(parent, text, size, colorKey, font, xalign)
	local l = New("TextLabel", {
		BackgroundTransparency = 1,
		Text = text or "",
		TextSize = size or 14,
		Font = font or Enum.Font.GothamMedium,
		TextXAlignment = xalign or Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Size = UDim2.new(1, 0, 0, (size or 14) + 6),
		Parent = parent,
	})
	themed(l, "TextColor3", colorKey or "Text")
	return l
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

local function clone(t)
	local out = {}
	for k, v in pairs(t) do
		out[k] = v
	end
	return out
end

----------------------------------------------------------------------------
-- [6] TOAST (notifikasi)
----------------------------------------------------------------------------
local toastHolder

local function toast(text, kind)
	if not toastHolder then
		return
	end
	local key = ({ danger = "Danger", success = "Success", warn = "Warning" })[kind or ""] or "Accent"
	local root = New("CanvasGroup", {
		Size = UDim2.fromOffset(0, 42),
		AutomaticSize = Enum.AutomaticSize.X,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Parent = toastHolder,
	})
	themed(root, "BackgroundColor3", "SurfaceHigh")
	corner(root, 12)
	stroke(root, "Stroke", 1, 0.2)
	local bar = New("Frame", { Size = UDim2.new(0, 4, 1, 0), BorderSizePixel = 0, Parent = root })
	themed(bar, "BackgroundColor3", key)
	local lbl = label(root, text, 14, "Text", Enum.Font.GothamMedium)
	lbl.AutomaticSize = Enum.AutomaticSize.X
	lbl.Size = UDim2.new(0, 0, 1, 0)
	lbl.Position = UDim2.fromOffset(18, 0)
	lbl.TextWrapped = false
	New("UIPadding", { PaddingRight = UDim.new(0, 18), Parent = root })
	tween(root, { GroupTransparency = 0 }, 0.25)
	task.delay((kind == "danger" or kind == "warn") and 6.5 or 2.8, function()
		if root.Parent then
			tween(root, { GroupTransparency = 1 }, 0.35)
			task.wait(0.4)
			root:Destroy()
		end
	end)
end

----------------------------------------------------------------------------
-- [7] AVATAR SERVICE & CRITICAL MESH INJECTOR
----------------------------------------------------------------------------
local Avatar = {}

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

local SCALE_VALUES = {
	Height = "BodyHeightScale", Width = "BodyWidthScale", Depth = "BodyDepthScale",
	Head = "HeadScale", Proportion = "BodyProportionScale", BodyType = "BodyTypeScale",
}

local descCache = nil
local originalDesc = nil
local originalColors = nil
local wornSet, wornList = {}, {}
local history, redoStack = {}, {}
local listeners = {}
local busy = false
local typeCache = {}
local nameCache = {}

local function getProp(desc, key)
	local ok, v = pcall(function() return desc[key] end)
	if ok then return v end
	return nil
end

local function setProp(desc, key, value)
	pcall(function() desc[key] = value end)
end

function Avatar.onChanged(fn)
	table.insert(listeners, fn)
end

local function fire()
	for _, fn in ipairs(listeners) do
		task.spawn(fn)
	end
end

function Avatar.humanoid()
	local char = player.Character or player.CharacterAdded:Wait()
	return char:WaitForChild("Humanoid"), char
end

function Avatar.isWorn(id)
	return wornSet[id] == true
end

function Avatar.getWorn()
	return wornList
end

function Avatar.canUndo()
	return #history > 0
end

function Avatar.canRedo()
	return #redoStack > 0
end

function Avatar.refresh()
	local hum = Avatar.humanoid()
	local ok, d = pcall(function() return hum:GetAppliedDescription() end)
	if not ok or not d then return descCache end
	descCache = d
	wornSet, wornList = {}, {}
	local okA, accs = pcall(function() return d:GetAccessories(true) end)
	if okA then
		for _, a in ipairs(accs) do
			wornSet[a.AssetId] = true
			table.insert(wornList, { Id = a.AssetId, Kind = "acc", Acc = a.AccessoryType.Name, Layered = a.IsLayered })
		end
	end
	for tid, prop in pairs(CLASSIC) do
		local v = getProp(d, prop)
		if type(v) == "number" and v > 0 then
			wornSet[v] = true
			table.insert(wornList, { Id = v, Kind = "classic", Prop = prop, Tid = tid })
		end
	end
	table.sort(wornList, function(a, b) return a.Id < b.Id end)
	return d
end

function Avatar.itemName(id)
	if nameCache[id] then return nameCache[id] end
	local ok, info = pcall(function() return MarketplaceService:GetProductInfo(id, Enum.InfoType.Asset) end)
	if ok and info then
		nameCache[id] = info.Name or ("Item #" .. id)
		typeCache[id] = info.AssetTypeId
	else
		nameCache[id] = "Item #" .. id
	end
	return nameCache[id]
end

function Avatar.assetTypeId(id)
	if typeCache[id] then return typeCache[id] end
	local ok, info = pcall(function() return MarketplaceService:GetProductInfo(id, Enum.InfoType.Asset) end)
	if ok and info and info.AssetTypeId then
		typeCache[id] = info.AssetTypeId
		nameCache[id] = nameCache[id] or info.Name
		return info.AssetTypeId
	end
	return nil
end

function Avatar.typeLabel(entry)
	if entry.Kind == "acc" then
		return entry.Acc .. (entry.Layered and " (layered)" or "")
	end
	return entry.Prop
end

----------------------------------------------------------------------------
-- CRITICAL MESH INJECTOR ENGINE (BYPASS CLIENT LIMITATIONS)
----------------------------------------------------------------------------
local function forceAttachAccessory(character, accessory, targetPartName)
	local hum = character:FindFirstChildOfClass("Humanoid")
	local handle = accessory:FindFirstChild("Handle")
	if not handle or not hum then return end

	local targetPart = character:FindFirstChild(targetPartName) or character:FindFirstChild("Head") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
	if not targetPart then return end

	accessory.Parent = character
	handle.CFrame = targetPart.CFrame

	local attachment = handle:FindFirstChildOfClass("Attachment")
	local targetAttachment = attachment and targetPart:FindFirstChild(attachment.Name)

	if attachment and targetAttachment then
		handle.CFrame = targetAttachment.WorldCFrame * attachment.CFrame:Inverse()
	end

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = targetPart
	weld.Parent = handle
end

local function injectAssetToCharacter(id, tid)
	local hum, char = Avatar.humanoid()
	if not char or not hum then return end

	-- 1. Pakaian Klasik & Wajah Direct Engine
	if tid == 11 then
		local sh = char:FindFirstChildOfClass("Shirt") or Instance.new("Shirt", char)
		sh.ShirtTemplate = "rbxassetid://" .. tostring(id)
	elseif tid == 12 then
		local pa = char:FindFirstChildOfClass("Pants") or Instance.new("Pants", char)
		pa.PantsTemplate = "rbxassetid://" .. tostring(id)
	elseif tid == 2 then
		local tg = char:FindFirstChildOfClass("ShirtGraphic") or Instance.new("ShirtGraphic", char)
		tg.Graphic = "rbxassetid://" .. tostring(id)
	elseif tid == 18 then
		local head = char:FindFirstChild("Head")
		if head then
			local face = head:FindFirstChildOfClass("Decal") or Instance.new("Decal", head)
			face.Name = "face"
			face.Texture = "rbxassetid://" .. tostring(id)
		end
	end

	-- 2. Aksesori / Mesh Virtual Re-Assembly
	if ACC[tid] then
		task.spawn(function()
			local accName = "StudioAcc_" .. tostring(id)
			local existing = char:FindFirstChild(accName)
			if existing then existing:Destroy() end

			local newAcc = Instance.new("Accessory")
			newAcc.Name = accName

			local handle = Instance.new("Part")
			handle.Name = "Handle"
			handle.Size = Vector3.new(1, 1, 1)
			handle.CanCollide = false
			handle.Transparency = 0
			handle.Parent = newAcc

			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.FileMesh
			mesh.MeshId = "rbxassetid://" .. tostring(id)
			mesh.TextureId = "rbxassetid://" .. tostring(id)
			mesh.Parent = handle

			local targetPart = "Head"
			if tid == 46 or tid == 47 then targetPart = "Torso" end
			if tid == 44 then targetPart = "RightUpperArm" end

			forceAttachAccessory(char, newAcc, targetPart)
		end)
	end
end

local function removeInjectedAssetFromCharacter(id)
	local _, char = Avatar.humanoid()
	if not char then return end
	local targetName = "StudioAcc_" .. tostring(id)
	local acc = char:FindFirstChild(targetName)
	if acc then acc:Destroy() end
end

----------------------------------------------------------------------------
-- TWEAK LOKAL & APPLY
----------------------------------------------------------------------------
function Avatar.setScale(key, value)
	State.scales[key] = value
	local hum = Avatar.humanoid()
	local nv = hum:FindFirstChild(SCALE_VALUES[key])
	if nv and nv:IsA("NumberValue") then nv.Value = value end
end

function Avatar.resetScales()
	State.scales = {}
	if originalDesc then
		local map = { Height = "HeightScale", Width = "WidthScale", Depth = "DepthScale", Head = "HeadScale", Proportion = "ProportionScale", BodyType = "BodyTypeScale" }
		local hum = Avatar.humanoid()
		for key, prop in pairs(map) do
			local v = getProp(originalDesc, prop)
			local nv = hum:FindFirstChild(SCALE_VALUES[key])
			if v and nv and nv:IsA("NumberValue") then nv.Value = v end
		end
	end
end

local BODY_COLOR_PROPS = { "HeadColor3", "TorsoColor3", "LeftArmColor3", "RightArmColor3", "LeftLegColor3", "RightLegColor3" }

function Avatar.setSkin(color)
	State.skin = color
	local _, char = Avatar.humanoid()
	local bc = char:FindFirstChildOfClass("BodyColors")
	if bc then
		for _, prop in ipairs(BODY_COLOR_PROPS) do bc[prop] = color end
	end
end

function Avatar.resetSkin()
	State.skin = nil
	if originalColors then
		local _, char = Avatar.humanoid()
		local bc = char:FindFirstChildOfClass("BodyColors")
		if bc then
			for _, prop in ipairs(BODY_COLOR_PROPS) do bc[prop] = originalColors[prop] end
		end
	end
end

function Avatar.reapplyTweaks()
	for k, v in pairs(State.scales) do Avatar.setScale(k, v) end
	if State.skin then Avatar.setSkin(State.skin) end
end

local function pushHistory(list, desc, text)
	table.insert(list, { desc = desc, label = text })
	while #list > CONFIG.MaxHistory do table.remove(list, 1) end
end

local REMOTE_NAME = "AvatarStudioApply"
local remoteRef = nil

local function getRemote()
	if remoteRef and remoteRef.Parent then return remoteRef end
	remoteRef = ReplicatedStorage:WaitForChild(REMOTE_NAME, 3)
	return remoteRef
end

local SERIAL_PROPS = {
	"Shirt", "Pants", "GraphicTShirt", "Face", "Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg",
	"ClimbAnimation", "FallAnimation", "IdleAnimation", "JumpAnimation", "RunAnimation", "SwimAnimation",
	"WalkAnimation", "MoodAnimation", "HeadColor", "TorsoColor", "LeftArmColor", "RightArmColor", "LeftLegColor", "RightLegColor",
	"HeightScale", "WidthScale", "DepthScale", "HeadScale", "ProportionScale", "BodyTypeScale",
}

local function serializeDesc(desc)
	local t = { props = {}, accs = {} }
	for _, k in ipairs(SERIAL_PROPS) do
		local v = getProp(desc, k)
		if v ~= nil then t.props[k] = v end
	end
	local ok, list = pcall(function() return desc:GetAccessories(true) end)
	if ok then
		for _, a in ipairs(list) do
			table.insert(t.accs, { AssetId = a.AssetId, AccessoryType = a.AccessoryType.Name, IsLayered = a.IsLayered, Order = a.Order or 1 })
		end
	end
	return t
end

function Avatar.apply(desc, text, skipHistory)
	if busy then
		toast("Tunggu sebentar, avatar masih diproses...", "warn")
		return false
	end
	busy = true
	local hum, char = Avatar.humanoid()
	if not descCache then Avatar.refresh() end
	local before = descCache and descCache:Clone()
	local ok, err
	local remote = getRemote()

	if remote then
		local okInvoke, res = pcall(function() return remote:InvokeServer(serializeDesc(desc)) end)
		ok = okInvoke and type(res) == "table" and res.ok
	else
		ok, err = pcall(function() hum:ApplyDescription(desc) end)
		pcall(function()
			if char then
				local okAcc, accList = pcall(function() return desc:GetAccessories(true) end)
				if okAcc and accList then
					for _, accData in ipairs(accList) do
						injectAssetToCharacter(accData.AssetId, Avatar.assetTypeId(accData.AssetId) or 8)
					end
				end
				local sId = getProp(desc, "Shirt")
				if type(sId) == "number" and sId > 0 then injectAssetToCharacter(sId, 11) end
				local pId = getProp(desc, "Pants")
				if type(pId) == "number" and pId > 0 then injectAssetToCharacter(pId, 12) end
				local fId = getProp(desc, "Face")
				if type(fId) == "number" and fId > 0 then injectAssetToCharacter(fId, 18) end
			end
		end)
		ok = true
	end

	busy = false
	if not skipHistory and before then
		pushHistory(history, before, text)
		redoStack = {}
	end
	Avatar.refresh()
	State.lastDesc = descCache and descCache:Clone()
	task.delay(0.2, Avatar.reapplyTweaks)
	fire()
	return true
end

function Avatar.modify(fn, text)
	local base = descCache or Avatar.refresh()
	if not base then
		toast("Karakter belum siap", "danger")
		return false
	end
	local desc = base:Clone()
	local ok, err = pcall(fn, desc)
	if not ok then
		toast("Error: " .. tostring(err), "danger")
		return false
	end
	return Avatar.apply(desc, text)
end

function Avatar.undo()
	local entry = table.remove(history)
	if not entry then toast("Tidak ada yang bisa di-undo", "warn") return end
	if descCache then pushHistory(redoStack, descCache:Clone(), entry.label) end
	Avatar.apply(entry.desc, "undo", true)
	toast("Undo: " .. tostring(entry.label), "success")
end

function Avatar.redo()
	local entry = table.remove(redoStack)
	if not entry then toast("Tidak ada yang bisa di-redo", "warn") return end
	if descCache then pushHistory(history, descCache:Clone(), entry.label) end
	Avatar.apply(entry.desc, "redo", true)
	toast("Redo: " .. tostring(entry.label), "success")
end

function Avatar.reset()
	if not originalDesc then return end
	Avatar.apply(originalDesc:Clone(), "reset")
	Avatar.resetScales()
	Avatar.resetSkin()
	toast("Avatar dikembalikan seperti semula", "success")
end

local function removeAssetFromDesc(desc, id)
	local list = desc:GetAccessories(true)
	local out = {}
	for _, a in ipairs(list) do
		if a.AssetId ~= id then table.insert(out, a) end
	end
	desc:SetAccessories(out, true)
	for _, prop in pairs(CLASSIC) do
		if getProp(desc, prop) == id then setProp(desc, prop, 0) end
	end
	removeInjectedAssetFromCharacter(id)
end

local function addAssetToDesc(desc, id, tid)
	local acc = ACC[tid]
	if acc then
		local typeName, layered = acc[1], acc[2]
		local enumVal = safeEnum(Enum.AccessoryType, typeName)
		if not enumVal then return false end
		local list = desc:GetAccessories(true)
		local out = {}
		local order = 1
		for _, a in ipairs(list) do
			local drop = a.AssetId == id
			if (layered or typeName == "Eyebrow" or typeName == "Eyelash") and a.AccessoryType == enumVal then drop = true end
			if not drop then
				table.insert(out, a)
				if a.Order and a.Order >= order then order = a.Order + 1 end
			end
		end
		table.insert(out, { AssetId = id, AccessoryType = enumVal, IsLayered = layered, Order = order })
		desc:SetAccessories(out, true)
		injectAssetToCharacter(id, tid)
		return true
	end
	local prop = CLASSIC[tid]
	if prop then
		setProp(desc, prop, id)
		injectAssetToCharacter(id, tid)
		return true
	end
	return false
end

local function mergeDescription(base, other)
	for _, prop in pairs(CLASSIC) do
		local v = getProp(other, prop)
		if type(v) == "number" and v > 0 then setProp(base, prop, v) end
	end
	local okO, otherAccs = pcall(function() return other:GetAccessories(true) end)
	if not okO then return end
	local baseAccs = base:GetAccessories(true)
	for _, oa in ipairs(otherAccs) do
		local out = {}
		for _, ba in ipairs(baseAccs) do
			local sameSlot = oa.IsLayered and ba.IsLayered and ba.AccessoryType == oa.AccessoryType
			if ba.AssetId ~= oa.AssetId and not sameSlot then table.insert(out, ba) end
		end
		table.insert(out, oa)
		baseAccs = out
	end
	base:SetAccessories(baseAccs, true)
end

function Avatar.toggleAsset(id, itemName)
	local tid = Avatar.assetTypeId(id)
	if not tid then toast("Tidak bisa membaca info item ini", "danger") return false end
	if not ACC[tid] and not CLASSIC[tid] then toast("Tipe item ini belum didukung untuk dipakai langsung", "warn") return false end
	local worn = wornSet[id]
	local ok = Avatar.modify(function(desc)
		if worn then removeAssetFromDesc(desc, id) else addAssetToDesc(desc, id, tid) end
	end, (worn and "Lepas " or "Pakai ") .. (itemName or ("#" .. id)))
	if ok then
		toast((worn and "Dilepas: " or "Dipakai: ") .. (itemName or ("#" .. id)), worn and "warn" or "success")
	end
	return ok
end

function Avatar.removeAsset(id, itemName)
	return Avatar.modify(function(desc) removeAssetFromDesc(desc, id) end, "Lepas " .. (itemName or ("#" .. id)))
end

function Avatar.equipBundle(bundleId, bundleName)
	local ok, info = pcall(function() return MarketplaceService:GetProductInfo(bundleId, Enum.InfoType.Bundle) end)
	if not ok or not info or not info.Items then toast("Gagal membaca isi bundle", "danger") return false end
	local count = 0
	local done = Avatar.modify(function(desc)
		for _, item in ipairs(info.Items) do
			if item.Type == "UserOutfit" then
				local ok2, od = pcall(function() return Players:GetHumanoidDescriptionFromOutfitId(item.Id) end)
				if ok2 and od then mergeDescription(desc, od) count = count + 1 end
			elseif item.Type == "Asset" then
				local tid = Avatar.assetTypeId(item.Id)
				if tid and addAssetToDesc(desc, item.Id, tid) then count = count + 1 end
			end
		end
	end, "Bundle " .. (bundleName or ("#" .. bundleId)))
	if done then toast("Bundle dipakai: " .. (bundleName or ("#" .. bundleId)), "success") end
	return done
end

function Avatar.applyUser(userId, displayName)
	local ok, desc = pcall(function() return Players:GetHumanoidDescriptionFromUserId(userId) end)
	if not ok or not desc then toast("Avatar pemain tidak bisa dimuat", "danger") return false end
	local done = Avatar.apply(desc, "Avatar " .. (displayName or userId))
	if done then toast("Avatar: " .. (displayName or tostring(userId)), "success") end
	return done
end

function Avatar.addMany(list, text)
	return Avatar.modify(function(desc)
		for _, it in ipairs(list) do
			local tid = Avatar.assetTypeId(it.Id)
			if tid then addAssetToDesc(desc, it.Id, tid) end
		end
	end, text or "Acak")
end

function Avatar.removeAllAccessories()
	return Avatar.modify(function(desc)
		desc:SetAccessories({}, true)
		local _, char = Avatar.humanoid()
		if char then
			for _, child in ipairs(char:GetChildren()) do
				if child:IsA("Accessory") or string.sub(child.Name, 1, 10) == "StudioAcc_" then
					child:Destroy()
				end
			end
		end
	end, "Lepas semua aksesori")
end

function Avatar.snapshotDescription() return descCache and descCache:Clone() end
function Avatar.applySnapshot(desc, text) return Avatar.apply(desc:Clone(), text) end

function Avatar.diagnose()
	local hum = Avatar.humanoid()
	toast("Rig karakter: " .. hum.RigType.Name, "info")
	toast("Modul Mesh Injector Aktif (Map Orang Support)", "success")
end

function Avatar.init()
	local hum, char = Avatar.humanoid()
	Avatar.refresh()
	originalDesc = descCache and descCache:Clone()
	State.lastDesc = originalDesc and originalDesc:Clone()
	local bc = char:FindFirstChildOfClass("BodyColors")
	originalColors = {}
	if bc then
		for _, prop in ipairs(BODY_COLOR_PROPS) do originalColors[prop] = bc[prop] end
	end
	player.CharacterAdded:Connect(function(newChar)
		newChar:WaitForChild("Humanoid")
		task.wait(1)
		if State.persist and State.lastDesc then
			Avatar.apply(State.lastDesc:Clone(), "respawn", true)
		else
			Avatar.refresh()
			fire()
		end
	end)
	fire()
end

----------------------------------------------------------------------------
-- [8] CATALOG SERVICE
----------------------------------------------------------------------------
local Catalog = {}
local CATEGORIES = {}
local function C(group, id, name, icon, kind, list)
	table.insert(CATEGORIES, { group = group, id = id, name = name, icon = icon, kind = kind, list = list })
end

C("KOLEKSI", "fav", "Favorit", "★", "fav")
C("KOLEKSI", "recent", "Terakhir dipakai", "🕘", "recent")
C("SET & BUNDLE", "b_body", "Karakter / Tubuh", "🧍", "bundle", { "BodyParts" })
C("SET & BUNDLE", "b_head", "Kepala Dinamis", "🗿", "bundle", { "DynamicHead", "DynamicHeadAvatar" })
C("SET & BUNDLE", "b_anim", "Paket Animasi", "🏃", "bundle", { "Animations" })
C("SET & BUNDLE", "b_shoes", "Set Sepatu", "👟", "bundle", { "Shoes" })
C("AKSESORI", "hat", "Topi", "🎩", "asset", { "Hat" })
C("AKSESORI", "hair", "Rambut", "💇", "asset", { "HairAccessory" })
C("AKSESORI", "face_acc", "Wajah", "🕶", "asset", { "FaceAccessory" })
C("AKSESORI", "neck", "Leher", "📿", "asset", { "NeckAccessory" })
C("AKSESORI", "shoulder", "Bahu", "🦜", "asset", { "ShoulderAccessory" })
C("AKSESORI", "front", "Depan", "🎗", "asset", { "FrontAccessory" })
C("AKSESORI", "back", "Punggung", "🎒", "asset", { "BackAccessory" })
C("AKSESORI", "waist", "Pinggang", "🩳", "asset", { "WaistAccessory" })
C("PAKAIAN LAYERED", "jacket", "Jaket", "🧥", "asset", { "JacketAccessory" })
C("PAKAIAN LAYERED", "sweater", "Sweater", "🧶", "asset", { "SweaterAccessory" })
C("PAKAIAN LAYERED", "l_shirt", "Kemeja", "👔", "asset", { "ShirtAccessory" })
C("PAKAIAN LAYERED", "l_tshirt", "Kaos", "👕", "asset", { "TShirtAccessory" })
C("PAKAIAN LAYERED", "l_pants", "Celana", "👖", "asset", { "PantsAccessory" })
C("PAKAIAN LAYERED", "shorts", "Celana Pendek", "🩲", "asset", { "ShortsAccessory" })
C("PAKAIAN LAYERED", "dress", "Gaun / Rok", "👗", "asset", { "DressSkirtAccessory" })
C("PAKAIAN LAYERED", "lshoe", "Sepatu Kiri", "👞", "asset", { "LeftShoeAccessory" })
C("PAKAIAN LAYERED", "rshoe", "Sepatu Kanan", "👞", "asset", { "RightShoeAccessory" })
C("PAKAIAN KLASIK", "shirt", "Kemeja Klasik", "🎽", "asset", { "Shirt" })
C("PAKAIAN KLASIK", "pants", "Celana Klasik", "👖", "asset", { "Pants" })
C("PAKAIAN KLASIK", "tshirt", "Kaos Grafis", "🖼", "asset", { "TShirt" })
C("TUBUH", "face", "Ekspresi Wajah", "😀", "asset", { "Face" })
C("TUBUH", "head", "Kepala", "🙂", "asset", { "Head" })
C("TUBUH", "torso", "Badan", "🫁", "asset", { "Torso" })
C("TUBUH", "rarm", "Lengan Kanan", "💪", "asset", { "RightArm" })
C("TUBUH", "larm", "Lengan Kiri", "💪", "asset", { "LeftArm" })
C("TUBUH", "rleg", "Kaki Kanan", "🦵", "asset", { "RightLeg" })
C("TUBUH", "lleg", "Kaki Kiri", "🦵", "asset", { "LeftLeg" })
C("TUBUH", "brow", "Alis", "🤨", "asset", { "EyebrowAccessory" })
C("TUBUH", "lash", "Bulu Mata", "👁", "asset", { "EyelashAccessory" })
C("ANIMASI", "a_idle", "Idle", "🧘", "asset", { "IdleAnimation" })
C("ANIMASI", "a_walk", "Jalan", "🚶", "asset", { "WalkAnimation" })
C("ANIMASI", "a_run", "Lari", "🏃", "asset", { "RunAnimation" })
C("ANIMASI", "a_jump", "Lompat", "🦘", "asset", { "JumpAnimation" })
C("ANIMASI", "a_fall", "Jatuh", "🪂", "asset", { "FallAnimation" })
C("ANIMASI", "a_climb", "Panjat", "🧗", "asset", { "ClimbAnimation" })
C("ANIMASI", "a_swim", "Renang", "🏊", "asset", { "SwimAnimation" })
C("ANIMASI", "a_mood", "Mood", "🎭", "asset", { "MoodAnimation" })

local SORTS = {
	{ key = "relevance", name = "Relevansi", enum = "Relevance" },
	{ key = "favorited", name = "Terfavorit", enum = "MostFavorited" },
	{ key = "bestselling", name = "Terlaris", enum = "Bestselling" },
	{ key = "recent", name = "Terbaru", enum = "RecentlyCreated" },
	{ key = "priceLow", name = "Harga termurah", enum = "PriceLowToHigh" },
	{ key = "priceHigh", name = "Harga termahal", enum = "PriceHighToLow" },
}
local SORT_BY_KEY = {}
for _, s in ipairs(SORTS) do SORT_BY_KEY[s.key] = s end

Catalog.categories = CATEGORIES
Catalog.sorts = SORTS

local function fetchDetails(ids, itemType)
	local out = {}
	if #ids == 0 then return out end
	local ok, res = pcall(function() return AvatarEditorService:GetBatchItemDetails(ids, itemType) end)
	if ok and type(res) == "table" then
		for _, d in ipairs(res) do out[d.Id] = d end
	end
	return out
end

local Query = {}
Query.__index = Query

function Catalog.newQuery(cat, keyword, sortKey, freeOnly)
	local params = CatalogSearchParams.new()
	params.SearchKeyword = keyword or ""
	local sortDef = SORT_BY_KEY[sortKey] or SORTS[1]
	local se = safeEnum(Enum.CatalogSortType, sortDef.enum)
	if se then params.SortType = se end
	local assetTypes, bundleTypes = {}, {}
	if cat.kind == "asset" then
		for _, n in ipairs(cat.list) do
			local e = safeEnum(Enum.AvatarAssetType, n)
			if e then table.insert(assetTypes, e) end
		end
	elseif cat.kind == "bundle" then
		for _, n in ipairs(cat.list) do
			local e = safeEnum(Enum.BundleType, n)
			if e then table.insert(bundleTypes, e) end
		end
	end
	params.AssetTypes = assetTypes
	params.BundleTypes = bundleTypes
	params.IncludeOffSale = false
	if freeOnly then params.MaxPrice = 0 end
	params.Limit = CONFIG.PageSize
	return setmetatable({ params = params, finished = false, pages = nil, total = 0 }, Query)
end

function Query:nextPage()
	if self.finished then return {} end
	local ok, res = pcall(function()
		if not self.pages then
			self.pages = AvatarEditorService:SearchCatalog(self.params)
		else
			self.pages:AdvanceToNextPageAsync()
		end
		return self.pages:GetCurrentPage()
	end)
	if not ok then return nil, tostring(res) end
	if self.pages.IsFinished then self.finished = true end
	local assetIds, bundleIds = {}, {}
	for _, it in ipairs(res) do
		if it.ItemType == "Bundle" then table.insert(bundleIds, it.Id) else table.insert(assetIds, it.Id) end
	end
	local aDetails = fetchDetails(assetIds, Enum.AvatarItemType.Asset)
	local bDetails = fetchDetails(bundleIds, Enum.AvatarItemType.Bundle)
	local items = {}
	for _, it in ipairs(res) do
		local isBundle = it.ItemType == "Bundle"
		local d = (isBundle and bDetails or aDetails)[it.Id] or {}
		self.total = self.total + 1
		table.insert(items, {
			Id = it.Id,
			Type = isBundle and "Bundle" or "Asset",
			Name = d.Name or it.Name or ("Item #" .. it.Id),
			Price = d.PriceInRobux,
			Creator = d.CreatorName,
			Order = self.total,
		})
		nameCache[it.Id] = nameCache[it.Id] or (d.Name or it.Name)
	end
	return items
end

function Catalog.randomItems(catIds, perCat)
	local picked = {}
	for _, cid in ipairs(catIds) do
		for _, cat in ipairs(CATEGORIES) do
			if cat.id == cid and cat.kind == "asset" then
				local q = Catalog.newQuery(cat, "", "relevance", false)
				local items = q:nextPage()
				if items and #items > 0 then
					for _ = 1, perCat or 1 do table.insert(picked, items[math.random(1, #items)]) end
				end
			end
		end
	end
	return picked
end

----------------------------------------------------------------------------
-- [9] KOMPONEN UI
----------------------------------------------------------------------------
local UI = {}
local randomLook, saveCurrentOutfit

local function makeScroll(parent, o)
	o = o or {}
	local s = New("ScrollingFrame", {
		Size = o.size or UDim2.new(1, 0, 1, 0), Position = o.position or UDim2.new(),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
		ScrollBarImageTransparency = 0.4, AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(), ScrollingDirection = Enum.ScrollingDirection.Y,
		ElasticBehavior = Enum.ElasticBehavior.Never, Parent = parent,
	})
	themed(s, "ScrollBarImageColor3", "TextDim")
	return s
end

local function button(parent, o)
	o = o or {}
	local style = o.style or "soft"
	local bgKey = ({ primary = "Accent", soft = "SurfaceHigh", ghost = "Surface", danger = "Danger", success = "Success" })[style]
	local txtKey = (style == "primary" or style == "danger" or style == "success") and "AccentText" or (style == "ghost" and "TextDim" or "Text")
	local b = New("TextButton", {
		Name = o.name or "Button", AutoButtonColor = false, Text = o.text or "", TextSize = o.textSize or 14,
		Font = Enum.Font.GothamBold, Size = o.size or UDim2.new(1, 0, 0, 36), Position = o.position or UDim2.new(),
		AnchorPoint = o.anchor or Vector2.zero, BorderSizePixel = 0, LayoutOrder = o.order or 0, Parent = parent,
	})
	themed(b, "BackgroundColor3", bgKey)
	themed(b, "TextColor3", txtKey)
	if style == "ghost" then b.BackgroundTransparency = 1 end
	corner(b, o.radius or 10)
	local sc = New("UIScale", { Parent = b })
	b.MouseEnter:Connect(function()
		if style == "soft" then tween(b, { BackgroundColor3 = Theme.SurfaceHover }, 0.15)
		elseif style == "ghost" then tween(b, { BackgroundTransparency = 0, BackgroundColor3 = Theme.SurfaceHigh }, 0.15)
		else tween(b, { BackgroundColor3 = Theme[bgKey]:Lerp(Color3.new(1, 1, 1), 0.15) }, 0.15) end
	end)
	b.MouseLeave:Connect(function()
		if style == "ghost" then tween(b, { BackgroundTransparency = 1 }, 0.2)
		else tween(b, { BackgroundColor3 = Theme[bgKey] }, 0.2) end
		tween(sc, { Scale = 1 }, 0.15)
	end)
	b.MouseButton1Down:Connect(function() tween(sc, { Scale = 0.96 }, 0.08) end)
	b.MouseButton1Up:Connect(function() tween(sc, { Scale = 1 }, 0.14, Enum.EasingStyle.Back) end)
	if o.onClick then b.Activated:Connect(o.onClick) end
	return b
end

local function sectionHeader(parent, text, order)
	local l = label(parent, text, 12, "TextDim", Enum.Font.GothamBold)
	l.Size = UDim2.new(1, 0, 0, 22)
	l.LayoutOrder = order or 0
	return l
end

local function searchBox(parent, o)
	local f = New("Frame", { Size = o.size or UDim2.new(1, 0, 0, 40), Position = o.position or UDim2.new(), BorderSizePixel = 0, Parent = parent })
	themed(f, "BackgroundColor3", "Surface")
	corner(f, 10)
	local st = stroke(f, "Stroke", 1, 0)
	local icon = New("TextLabel", { BackgroundTransparency = 1, Text = "🔍", TextSize = 15, Size = UDim2.fromOffset(30, 40), Position = UDim2.fromOffset(6, 0), Parent = f })
	local box = New("TextBox", {
		Size = UDim2.new(1, -72, 1, 0), Position = UDim2.fromOffset(36, 0), BackgroundTransparency = 1, Text = "",
		PlaceholderText = o.placeholder or "Cari...", ClearTextOnFocus = false, TextSize = 14, Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = f,
	})
	themed(box, "TextColor3", "Text")
	themed(box, "PlaceholderColor3", "TextDim")
	local clear = New("TextButton", {
		Size = UDim2.fromOffset(28, 28), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0),
		BackgroundTransparency = 1, Text = "✕", TextSize = 13, Font = Enum.Font.GothamBold, Visible = false, Parent = f,
	})
	themed(clear, "TextColor3", "TextDim")
	box.Focused:Connect(function() tween(st, { Color = Theme.Accent }, 0.2) end)
	box.FocusLost:Connect(function(enter)
		tween(st, { Color = Theme.Stroke }, 0.2)
		if enter and o.onSubmit then o.onSubmit(box.Text) end
	end)
	box:GetPropertyChangedSignal("Text"):Connect(function() clear.Visible = box.Text ~= "" end)
	clear.Activated:Connect(function()
		box.Text = ""
		if o.onSubmit then o.onSubmit("") end
	end)
	return f, box
end

local function toggle(parent, o)
	local holder = New("Frame", { Size = UDim2.new(1, 0, 0, o.sub and 52 or 38), BackgroundTransparency = 1, LayoutOrder = o.order or 0, Parent = parent })
	local t = label(holder, o.text, 14, "Text", Enum.Font.GothamMedium)
	t.Size = UDim2.new(1, -64, 0, 20)
	t.Position = UDim2.fromOffset(0, o.sub and 4 or 9)
	if o.sub then
		local s = label(holder, o.sub, 12, "TextDim", Enum.Font.Gotham)
		s.Size = UDim2.new(1, -64, 0, 16)
		s.Position = UDim2.fromOffset(0, 26)
	end
	local track = New("TextButton", { Size = UDim2.fromOffset(46, 26), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Text = "", AutoButtonColor = false, BorderSizePixel = 0, Parent = holder })
	corner(track, 13)
	local knob = New("Frame", { Size = UDim2.fromOffset(20, 20), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = track })
	corner(knob, 10)
	local on = o.value and true or false
	local function render(animate)
		local c = on and Theme.Accent or Theme.SurfaceHigh
		local p = on and UDim2.new(0, 23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
		if animate then tween(track, { BackgroundColor3 = c }, 0.2) tween(knob, { Position = p }, 0.22, Enum.EasingStyle.Back)
		else track.BackgroundColor3 = c knob.Position = p end
	end
	render(false)
	onTheme(function() render(false) end)
	track.Activated:Connect(function()
		on = not on
		render(true)
		if o.onChange then o.onChange(on) end
	end)
	return { Frame = holder, Set = function(v) on = v and true or false render(true) end }
end

local function slider(parent, o)
	local min, max, step = o.min, o.max, o.step or 0.01
	local value = o.value or min
	local holder = New("Frame", { Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1, LayoutOrder = o.order or 0, Parent = parent })
	local title = label(holder, o.text or "", 13, "Text", Enum.Font.GothamMedium)
	title.Size = UDim2.new(0.6, 0, 0, 20)
	local valLbl = label(holder, "", 13, "TextDim", Enum.Font.GothamBold, Enum.TextXAlignment.Right)
	valLbl.Size = UDim2.new(0.4, 0, 0, 20)
	valLbl.Position = UDim2.new(0.6, 0, 0, 0)
	local track = New("Frame", { Size = UDim2.new(1, 0, 0, 6), Position = UDim2.fromOffset(0, 32), BorderSizePixel = 0, Parent = holder })
	themed(track, "BackgroundColor3", "SurfaceHigh")
	corner(track, 3)
	local fill = New("Frame", { Size = UDim2.new(0, 0, 1, 0), BorderSizePixel = 0, Parent = track })
	themed(fill, "BackgroundColor3", "Accent")
	corner(fill, 3)
	local knob = New("Frame", { Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), BorderSizePixel = 0, ZIndex = 2, Parent = track })
	themed(knob, "BackgroundColor3", "Text")
	corner(knob, 8)
	stroke(knob, "Accent", 2, 0)
	local hit = New("TextButton", { Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 20), BackgroundTransparency = 1, Text = "", Parent = holder })
	local function setValue(v, doFire)
		v = math.clamp(v, min, max)
		v = math.floor(v / step + 0.5) * step
		value = v
		local a = (max - min) > 0 and (v - min) / (max - min) or 0
		fill.Size = UDim2.new(a, 0, 1, 0)
		knob.Position = UDim2.new(a, 0, 0.5, 0)
		valLbl.Text = o.format and o.format(v) or string.format("%.2f", v)
		if doFire and o.onChange then o.onChange(v) end
	end
	local dragging = false
	local function fromInput(input)
		local a = math.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		setValue(min + (max - min) * a, true)
	end
	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			tween(knob, { Size = UDim2.fromOffset(20, 20) }, 0.12)
			fromInput(input)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then fromInput(input) end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if dragging then dragging = false tween(knob, { Size = UDim2.fromOffset(16, 16) }, 0.12) end
		end
	end)
	setValue(value, false)
	return { Frame = holder, Set = function(v) setValue(v, false) end, SetRange = function(a, b) min, max = a, b setValue(value, false) end, Get = function() return value end }
end

local function dropdown(parent, o)
	local current = o.value
	local function nameOf(key)
		for _, opt in ipairs(o.options) do if opt.key == key then return opt.name end end
		return "-"
	end
	local btn = button(parent, { text = "", size = o.size, position = o.position, style = "soft", radius = 10, name = "Dropdown" })
	btn.TextXAlignment = Enum.TextXAlignment.Left
	pad(btn, 12, 0, 28, 0)
	local arrow = New("TextLabel", { BackgroundTransparency = 1, Text = "▾", TextSize = 14, Font = Enum.Font.GothamBold, Size = UDim2.fromOffset(20, 20), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 6, 0.5, 0), Parent = btn })
	themed(arrow, "TextColor3", "TextDim")
	local function render() btn.Text = (o.prefix or "") .. nameOf(current) end
	render()
	local opened
	local function close() if opened then opened:Destroy() opened = nil end end
	btn.Activated:Connect(function()
		if opened then close() return end
		local sc = UI.winScale.Scale
		local rel = (btn.AbsolutePosition - UI.window.AbsolutePosition) / sc
		local holder = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 60, Parent = UI.window })
		opened = holder
		local blocker = New("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 60, Parent = holder })
		blocker.Activated:Connect(close)
		local list = New("Frame", { Size = UDim2.fromOffset(math.max(btn.AbsoluteSize.X / sc, 170), #o.options * 34 + 12), Position = UDim2.fromOffset(rel.X, rel.Y + btn.AbsoluteSize.Y / sc + 4), BorderSizePixel = 0, ZIndex = 61, Parent = holder })
		themed(list, "BackgroundColor3", "SurfaceHigh")
		corner(list, 12) stroke(list, "Stroke", 1, 0) pad(list, 6) vlist(list, 0)
		for i, opt in ipairs(o.options) do
			local row = New("TextButton", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Text = opt.name, TextSize = 14, Font = opt.key == current and Enum.Font.GothamBold or Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, ZIndex = 62, LayoutOrder = i, Parent = list })
			themed(row, "TextColor3", opt.key == current and "Accent" or "Text")
			themed(row, "BackgroundColor3", "SurfaceHover")
			corner(row, 8) pad(row, 10, 0, 6, 0)
			row.MouseEnter:Connect(function() tween(row, { BackgroundTransparency = 0 }, 0.1) end)
			row.MouseLeave:Connect(function() tween(row, { BackgroundTransparency = 1 }, 0.1) end)
			row.Activated:Connect(function() current = opt.key render() close() if o.onSelect then o.onSelect(opt.key) end end)
		end
	end)
	return btn
end

local function emptyState(parent, icon, title, sub)
	local f = New("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = parent })
	local i = New("TextLabel", { BackgroundTransparency = 1, Text = icon, TextSize = 46, Size = UDim2.new(1, 0, 0, 60), Position = UDim2.new(0, 0, 0.5, -70), Parent = f })
	local t = label(f, title, 17, "Text", Enum.Font.GothamBold, Enum.TextXAlignment.Center)
	t.Position = UDim2.new(0, 0, 0.5, -6)
	if sub then
		local s = label(f, sub, 13, "TextDim", Enum.Font.Gotham, Enum.TextXAlignment.Center)
		s.Size = UDim2.new(1, -40, 0, 40) s.Position = UDim2.new(0, 20, 0.5, 22) s.TextWrapped = true s.TextYAlignment = Enum.TextYAlignment.Top
	end
	return f
end

----------------------------------------------------------------------------
-- [10] WINDOW UTAMA
----------------------------------------------------------------------------
local W, H = CONFIG.WindowSize.X, CONFIG.WindowSize.Y

UI.gui = New("ScreenGui", { Name = "AvatarStudioUI", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 50, Parent = playerGui })
toastHolder = New("Frame", { Name = "Toasts", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 18), Size = UDim2.fromOffset(420, 300), BackgroundTransparency = 1, ZIndex = 200, Parent = UI.gui })
New("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Top, Parent = toastHolder })

UI.window = New("Frame", { Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.fromOffset(W, H), BorderSizePixel = 0, ClipsDescendants = true, Parent = UI.gui })
themed(UI.window, "BackgroundColor3", "Background")
corner(UI.window, 18) stroke(UI.window, "Stroke", 1.5, 0)
UI.winScale = New("UIScale", { Parent = UI.window })

local function computeScale()
	local cam = Workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	local s = math.min((vp.X - 24) / W, (vp.Y - 24) / H, 1.15)
	return math.max(s, 0.45) * State.uiScale
end

function UI.rescale()
	UI.baseScale = computeScale()
	if State.open then tween(UI.winScale, { Scale = UI.baseScale }, 0.2) end
end
UI.baseScale = computeScale()
UI.winScale.Scale = UI.baseScale

local TITLE_H = 56
UI.titlebar = New("Frame", { Name = "Titlebar", Size = UDim2.new(1, 0, 0, TITLE_H), BorderSizePixel = 0, Parent = UI.window })
themed(UI.titlebar, "BackgroundColor3", "Surface")
local tbLine = New("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BorderSizePixel = 0, Parent = UI.titlebar })
themed(tbLine, "BackgroundColor3", "Stroke")

local logo = New("Frame", { Size = UDim2.fromOffset(36, 36), Position = UDim2.fromOffset(16, 10), BorderSizePixel = 0, Parent = UI.titlebar })
themed(logo, "BackgroundColor3", "Accent")
corner(logo, 11)
New("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(150, 150, 150)), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 0.9) }), Rotation = 60, Parent = logo })
New("TextLabel", { BackgroundTransparency = 1, Text = "👗", TextSize = 20, Size = UDim2.fromScale(1, 1), Parent = logo })
local titleLbl = label(UI.titlebar, "Avatar Studio", 18, "Text", Enum.Font.GothamBold)
titleLbl.Position = UDim2.fromOffset(62, 8) titleLbl.Size = UDim2.new(0, 260, 0, 22)
UI.subtitle = label(UI.titlebar, "Memuat karakter...", 12, "TextDim", Enum.Font.Gotham)
UI.subtitle.Position = UDim2.fromOffset(62, 30) UI.subtitle.Size = UDim2.new(0, 320, 0, 16)

local tbButtons = New("Frame", { Size = UDim2.fromOffset(180, 40), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), BackgroundTransparency = 1, Parent = UI.titlebar })
hlist(tbButtons, 6).HorizontalAlignment = Enum.HorizontalAlignment.Right
UI.undoBtn = button(tbButtons, { text = "↶", size = UDim2.fromOffset(38, 34), style = "ghost", textSize = 18, order = 1, onClick = function() Avatar.undo() end })
UI.redoBtn = button(tbButtons, { text = "↷", size = UDim2.fromOffset(38, 34), style = "ghost", textSize = 18, order = 2, onClick = function() Avatar.redo() end })
UI.minBtn = button(tbButtons, { text = "—", size = UDim2.fromOffset(38, 34), style = "ghost", order = 3 })
UI.closeBtn = button(tbButtons, { text = "✕", size = UDim2.fromOffset(38, 34), style = "danger", order = 4 })

do
	local dragging, dragStart, startPos = false, nil, nil
	UI.titlebar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true dragStart = input.Position startPos = UI.window.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			UI.window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
end

UI.body = New("Frame", { Name = "Body", Position = UDim2.fromOffset(0, TITLE_H), Size = UDim2.new(1, 0, 1, -TITLE_H), BackgroundTransparency = 1, Parent = UI.window })
local RAIL_W, SIDE_W = 78, 236

UI.rail = New("Frame", { Name = "Rail", Size = UDim2.new(0, RAIL_W, 1, 0), BorderSizePixel = 0, Parent = UI.body })
themed(UI.rail, "BackgroundColor3", "Surface")
local railLine = New("Frame", { Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), BorderSizePixel = 0, Parent = UI.rail })
themed(railLine, "BackgroundColor3", "Stroke")
local railList = New("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = UI.rail })
vlist(railList, 4, Enum.HorizontalAlignment.Center) pad(railList, 0, 10, 0, 10)

UI.content = New("Frame", { Name = "Content", Position = UDim2.fromOffset(RAIL_W, 0), Size = UDim2.new(1, -(RAIL_W + SIDE_W), 1, 0), BackgroundTransparency = 1, ClipsDescendants = true, Parent = UI.body })

UI.side = New("Frame", { Name = "Side", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, SIDE_W, 1, 0), BorderSizePixel = 0, Parent = UI.body })
themed(UI.side, "BackgroundColor3", "Surface")
local sideLine = New("Frame", { Size = UDim2.new(0, 1, 1, 0), BorderSizePixel = 0, Parent = UI.side })
themed(sideLine, "BackgroundColor3", "Stroke")

local TABS = {
	{ key = "catalog", icon = "🛍", name = "Katalog" },
	{ key = "worn", icon = "👕", name = "Dipakai" },
	{ key = "avatars", icon = "👥", name = "Avatar" },
	{ key = "outfits", icon = "💾", name = "Outfit" },
	{ key = "body", icon = "📏", name = "Tubuh" },
	{ key = "color", icon = "🎨", name = "Warna" },
	{ key = "settings", icon = "⚙", name = "Setelan" },
}
UI.pages = {} UI.builders = {} UI.built = {} UI.railButtons = {}

function UI.addPage(key)
	local p = New("Frame", { Name = "Page_" .. key, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, Parent = UI.content })
	pad(p, 16) UI.pages[key] = p return p
end

for i, tab in ipairs(TABS) do
	local b = New("TextButton", { Name = "Tab_" .. tab.key, Size = UDim2.new(1, -14, 0, 62), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = i, Parent = railList })
	themed(b, "BackgroundColor3", "SurfaceHigh") corner(b, 14)
	local ic = New("TextLabel", { BackgroundTransparency = 1, Text = tab.icon, TextSize = 22, Size = UDim2.new(1, 0, 0, 28), Position = UDim2.fromOffset(0, 8), Parent = b })
	local tx = label(b, tab.name, 11, "TextDim", Enum.Font.GothamBold, Enum.TextXAlignment.Center)
	tx.Size = UDim2.new(1, 0, 0, 16) tx.Position = UDim2.fromOffset(0, 38)
	local bar = New("Frame", { Size = UDim2.fromOffset(4, 0), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -7, 0.5, 0), BorderSizePixel = 0, Parent = b })
	themed(bar, "BackgroundColor3", "Accent") corner(bar, 2)
	UI.railButtons[tab.key] = { btn = b, text = tx, bar = bar }
	b.MouseEnter:Connect(function() if State.tab ~= tab.key then tween(b, { BackgroundTransparency = 0.5 }, 0.15) end end)
	b.MouseLeave:Connect(function() if State.tab ~= tab.key then tween(b, { BackgroundTransparency = 1 }, 0.15) end end)
	b.Activated:Connect(function() UI.showTab(tab.key) end)
end

function UI.showTab(key)
	State.tab = key
	for k, rb in pairs(UI.railButtons) do
		local active = k == key
		tween(rb.btn, { BackgroundTransparency = active and 0 or 1 }, 0.2)
		tween(rb.bar, { Size = UDim2.fromOffset(4, active and 30 or 0) }, 0.25, Enum.EasingStyle.Back)
		rb.text.TextColor3 = active and Theme.Accent or Theme.TextDim
	end
	for k, page in pairs(UI.pages) do if k ~= key then page.Visible = false end end
	local page = UI.pages[key]
	if not page then return end
	if not UI.built[key] and UI.builders[key] then UI.built[key] = true UI.builders[key](page) end
	page.Position = UDim2.fromOffset(0, 10) page.Visible = true
	tween(page, { Position = UDim2.fromOffset(0, 0) }, 0.3)
	if UI.onTabShown and UI.onTabShown[key] then UI.onTabShown[key]() end
end
UI.onTabShown = {}

onTheme(function()
	for k, rb in pairs(UI.railButtons) do rb.text.TextColor3 = (k == State.tab) and Theme.Accent or Theme.TextDim end
end)

for _, tab in ipairs(TABS) do UI.addPage(tab.key) end

----------------------------------------------------------------------------
-- [11] PRATINJAU 3D + PANEL KANAN
----------------------------------------------------------------------------
local Preview = { angle = 0, dragging = false, token = 0 }

do
	local inner = New("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = UI.side })
	pad(inner, 14, 12, 14, 12) vlist(inner, 8)
	sectionHeader(inner, "PRATINJAU", 1)

	local holder = New("Frame", { Size = UDim2.new(1, 0, 0, 262), BorderSizePixel = 0, LayoutOrder = 2, Parent = inner })
	themed(holder, "BackgroundColor3", "SurfaceHigh") corner(holder, 16) stroke(holder, "Stroke", 1, 0.2)
	New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 0) }), Parent = holder })

	local vp = New("ViewportFrame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Ambient = Color3.fromRGB(175, 178, 195), LightColor = Color3.fromRGB(255, 252, 245), LightDirection = Vector3.new(0.35, -0.55, 1), Parent = holder })
	local cam = New("Camera", { FieldOfView = 35, Parent = vp })
	vp.CurrentCamera = cam
	Preview.vp, Preview.cam = vp, cam

	local hint = label(holder, "geser untuk memutar", 11, "TextDim", Enum.Font.Gotham, Enum.TextXAlignment.Center)
	hint.AnchorPoint = Vector2.new(0.5, 1) hint.Position = UDim2.new(0.5, 0, 1, -6) hint.Size = UDim2.new(1, 0, 0, 14)

	local nameL = label(inner, player.DisplayName, 16, "Text", Enum.Font.GothamBold, Enum.TextXAlignment.Center)
	nameL.LayoutOrder = 3 nameL.Size = UDim2.new(1, 0, 0, 20)
	Preview.stat = label(inner, "0 item dipakai", 12, "TextDim", Enum.Font.Gotham, Enum.TextXAlignment.Center)
	Preview.stat.LayoutOrder = 4 Preview.stat.Size = UDim2.new(1, 0, 0, 14)

	local row = New("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, LayoutOrder = 5, Parent = inner })
	button(row, { text = "🎲 Acak", size = UDim2.new(0.5, -4, 1, 0), style = "primary", textSize = 13, onClick = function() if randomLook then randomLook() end end })
	button(row, { text = "💾 Simpan", size = UDim2.new(0.5, -4, 1, 0), position = UDim2.new(0.5, 4, 0, 0), style = "soft", textSize = 13, onClick = function() if saveCurrentOutfit then saveCurrentOutfit() end end })
	button(inner, { text = "Lepas semua aksesori", size = UDim2.new(1, 0, 0, 34), style = "soft", textSize = 13, order = 6, onClick = function() task.spawn(function() if Avatar.removeAllAccessories() then toast("Semua aksesori dilepas", "warn") end end) end })
	button(inner, { text = "↺ Reset ke avatar asli", size = UDim2.new(1, 0, 0, 34), style = "danger", textSize = 13, order = 7, onClick = function() task.spawn(Avatar.reset) end })

	local lastX
	vp.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then Preview.dragging = true lastX = input.Position.X end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if Preview.dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then Preview.angle = Preview.angle + (input.Position.X - lastX) * 0.012 lastX = input.Position.X end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then Preview.dragging = false end
	end)
end

function Preview.refresh()
	Preview.token = Preview.token + 1
	local my = Preview.token
	task.delay(0.35, function()
		if my ~= Preview.token or not Preview.vp then return end
		local _, char = Avatar.humanoid()
		local oldArch = char.Archivable char.Archivable = true
		local m = char:Clone() char.Archivable = oldArch
		if not m then return end
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("Script") or d:IsA("LocalScript") then d:Destroy() elseif d:IsA("BasePart") then d.Anchored = true end
		end
		local hum = m:FindFirstChildOfClass("Humanoid")
		if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
		if Preview.model then Preview.model:Destroy() end
		m.Parent = Preview.vp Preview.model = m m:PivotTo(CFrame.new(0, 0, 0))
		local cf, size = m:GetBoundingBox()
		local dist = (size.Y / 2) / math.tan(math.rad(17.5)) * 1.2 + 2
		Preview.cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0, size.Y * 0.04, -dist), cf.Position)
	end)
end

RunService.RenderStepped:Connect(function(dt)
	if Preview.model and State.open and not State.minimized then
		if State.autoRotate and not Preview.dragging then Preview.angle = Preview.angle + dt * 0.9 end
		Preview.model:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, Preview.angle, 0))
	end
end)

----------------------------------------------------------------------------
-- [12] KATALOG & PAGE BUILDERS
----------------------------------------------------------------------------
local activeCards = {}

local function addRecent(item)
	for i, r in ipairs(State.recent) do
		if r.Id == item.Id then table.remove(State.recent, i) break end
	end
	table.insert(State.recent, 1, item)
	while #State.recent > CONFIG.MaxRecent do table.remove(State.recent) end
end

local function toggleFavorite(item)
	if State.favorites[item.Id] then
		State.favorites[item.Id] = nil
		for i, id in ipairs(State.favOrder) do if id == item.Id then table.remove(State.favOrder, i) break end end
		toast("Dihapus dari favorit", "warn")
	else
		State.favorites[item.Id] = item table.insert(State.favOrder, 1, item.Id)
		toast("Ditambahkan ke favorit ★", "success")
	end
end

local function makeCard(parent, item, onFavChanged)
	local isBundle = item.Type == "Bundle"
	local card = New("TextButton", { Name = "Card", AutoButtonColor = false, Text = "", BorderSizePixel = 0, LayoutOrder = item.Order or 0, Parent = parent })
	themed(card, "BackgroundColor3", "Surface") corner(card, 12)
	local st = stroke(card, "Stroke", 1, 0.3)
	local img = New("ImageLabel", { Size = UDim2.new(1, -12, 0, 106), Position = UDim2.fromOffset(6, 6), BorderSizePixel = 0, ScaleType = Enum.ScaleType.Fit, Image = thumbURL(isBundle and "BundleThumbnail" or "Asset", item.Id, 150), Parent = card })
	themed(img, "BackgroundColor3", "SurfaceHigh") corner(img, 9)

	local nameL = label(card, item.Name, 12, "Text", Enum.Font.GothamBold)
	nameL.Position = UDim2.fromOffset(8, 116) nameL.Size = UDim2.new(1, -16, 0, 16) nameL.TextTruncate = Enum.TextTruncate.AtEnd
	local priceL = label(card, priceText(item.Price), 11, item.Price == 0 and "Success" or "TextDim", Enum.Font.GothamMedium)
	priceL.Position = UDim2.fromOffset(8, 134) priceL.Size = UDim2.new(1, -16, 0, 14)

	local badge = New("Frame", { Size = UDim2.fromOffset(22, 22), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12), BorderSizePixel = 0, Visible = false, ZIndex = 3, Parent = card })
	themed(badge, "BackgroundColor3", "Success") corner(badge, 11)
	New("TextLabel", { BackgroundTransparency = 1, Text = "✓", TextSize = 14, Font = Enum.Font.GothamBold, TextColor3 = Color3.new(1, 1, 1), Size = UDim2.fromScale(1, 1), ZIndex = 4, Parent = badge })

	if isBundle then
		local tag = New("TextLabel", { Size = UDim2.fromOffset(34, 16), AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -12, 0, 106), Text = "SET", TextSize = 10, Font = Enum.Font.GothamBold, BorderSizePixel = 0, ZIndex = 3, Parent = card })
		themed(tag, "BackgroundColor3", "Accent") themed(tag, "TextColor3", "AccentText") corner(tag, 8)
	end

	local fav = New("TextButton", { Size = UDim2.fromOffset(26, 26), Position = UDim2.fromOffset(10, 10), BackgroundTransparency = 0.35, BackgroundColor3 = Color3.new(0, 0, 0), Text = "♡", TextSize = 16, Font = Enum.Font.GothamBold, TextColor3 = Color3.new(1, 1, 1), AutoButtonColor = false, ZIndex = 3, Parent = card })
	corner(fav, 13)

	local overlay = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Visible = false, ZIndex = 6, Parent = card })
	corner(overlay, 12)
	local spin = New("TextLabel", { BackgroundTransparency = 1, Text = "⏳", TextSize = 26, Size = UDim2.fromScale(1, 1), ZIndex = 7, Parent = overlay })

	local obj = { card = card, item = item, loading = false }
	function obj.update()
		local worn = (not isBundle) and Avatar.isWorn(item.Id)
		badge.Visible = worn st.Transparency = worn and 0 or 0.3
		if worn then st.Color = Theme.Success else st.Color = Theme.Stroke end
		local isFav = State.favorites[item.Id] ~= nil
		fav.Text = isFav and "♥" or "♡" fav.TextColor3 = isFav and Theme.Danger or Color3.new(1, 1, 1)
	end
	obj.update()

	card.MouseEnter:Connect(function() tween(card, { BackgroundColor3 = Theme.SurfaceHigh }, 0.15) tween(img, { Position = UDim2.fromOffset(6, 3) }, 0.2) end)
	card.MouseLeave:Connect(function() tween(card, { BackgroundColor3 = Theme.Surface }, 0.2) tween(img, { Position = UDim2.fromOffset(6, 6) }, 0.2) end)

	fav.Activated:Connect(function() toggleFavorite(item) obj.update() if onFavChanged then onFavChanged() end end)

	card.Activated:Connect(function()
		if obj.loading then return end
		obj.loading = true overlay.Visible = true tween(overlay, { BackgroundTransparency = 0.45 }, 0.15)
		task.spawn(function()
			local ok
			if isBundle then ok = Avatar.equipBundle(item.Id, item.Name) else ok = Avatar.toggleAsset(item.Id, item.Name) end
			if ok and (isBundle or Avatar.isWorn(item.Id)) then addRecent(item) end
			tween(overlay, { BackgroundTransparency = 1 }, 0.15) task.wait(0.15) overlay.Visible = false obj.loading = false
		end)
	end)
	return obj
end

UI.builders.catalog = function(page)
	local CAT_W = 172
	local catPanel = New("Frame", { Size = UDim2.new(0, CAT_W, 1, 0), BorderSizePixel = 0, Parent = page })
	themed(catPanel, "BackgroundColor3", "Surface") corner(catPanel, 14) stroke(catPanel, "Stroke", 1, 0.3)
	local catScroll = makeScroll(catPanel) pad(catScroll, 8, 8, 8, 8) vlist(catScroll, 3)

	local main = New("Frame", { Position = UDim2.fromOffset(CAT_W + 12, 0), Size = UDim2.new(1, -(CAT_W + 12), 1, 0), BackgroundTransparency = 1, Parent = page })
	local row1 = New("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = main })
	local sbFrame, sbBox local startQuery
	sbFrame, sbBox = searchBox(row1, { size = UDim2.new(1, -48, 1, 0), placeholder = "Cari di kategori ini...", onSubmit = function(t) State.keyword = t startQuery() end })
	button(row1, { text = "⟳", size = UDim2.fromOffset(40, 40), position = UDim2.new(1, -40, 0, 0), style = "soft", textSize = 20, onClick = function() startQuery() end })

	local row2 = New("Frame", { Size = UDim2.new(1, 0, 0, 34), Position = UDim2.fromOffset(0, 46), BackgroundTransparency = 1, Parent = main })
	local sortOptions = {}
	for _, s in ipairs(Catalog.sorts) do table.insert(sortOptions, { key = s.key, name = s.name }) end
	dropdown(row2, { options = sortOptions, value = State.sortKey, prefix = "↕  ", size = UDim2.fromOffset(176, 34), onSelect = function(k) State.sortKey = k startQuery() end })
	local freeBtn
	local function renderFree()
		freeBtn.Text = (State.freeOnly and "✓ " or "") .. "Gratis"
		freeBtn.BackgroundColor3 = State.freeOnly and Theme.Success or Theme.SurfaceHigh
		freeBtn.TextColor3 = State.freeOnly and Color3.new(1, 1, 1) or Theme.Text
	end
	freeBtn = button(row2, { text = "Gratis", size = UDim2.fromOffset(86, 34), position = UDim2.fromOffset(184, 0), style = "soft", textSize = 13, onClick = function() State.freeOnly = not State.freeOnly renderFree() startQuery() end })
	local countL = label(row2, "", 12, "TextDim", Enum.Font.GothamMedium, Enum.TextXAlignment.Right)
	countL.Size = UDim2.new(1, -278, 1, 0) countL.Position = UDim2.fromOffset(278, 0)

	local gridScroll = makeScroll(main, { position = UDim2.fromOffset(0, 88), size = UDim2.new(1, 0, 1, -88) })
	New("UIGridLayout", { CellSize = UDim2.fromOffset(124, 164), CellPadding = UDim2.fromOffset(7, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = gridScroll })
	pad(gridScroll, 0, 2, 0, 12)

	local stateHolder = New("Frame", { Position = UDim2.fromOffset(0, 88), Size = UDim2.new(1, 0, 1, -88), BackgroundTransparency = 1, Visible = false, ZIndex = 5, Parent = main })
	local currentQuery, loading = nil, false local skeletons, skeletonTweens = {}, {}

	local function clearState() stateHolder.Visible = false for _, c in ipairs(stateHolder:GetChildren()) do c:Destroy() end end
	local function clearSkeleton() for _, t in ipairs(skeletonTweens) do t:Cancel() end for _, s in ipairs(skeletons) do s:Destroy() end skeletons, skeletonTweens = {}, {} end
	local function clearGrid() clearState() clearSkeleton() activeCards = {} for _, c in ipairs(gridScroll:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end gridScroll.CanvasPosition = Vector2.new(0, 0) end

	local function showSkeleton()
		for i = 1, 9 do
			local f = New("Frame", { Name = "Skeleton", BorderSizePixel = 0, LayoutOrder = 100000 + i, Parent = gridScroll })
			f.BackgroundColor3 = Theme.Surface corner(f, 12)
			local tw = TweenService:Create(f, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { BackgroundColor3 = Theme.SurfaceHigh })
			tw:Play() table.insert(skeletons, f) table.insert(skeletonTweens, tw)
		end
	end

	local function showState(icon, title, sub, retry)
		clearState() stateHolder.Visible = true emptyState(stateHolder, icon, title, sub)
		if retry then button(stateHolder, { text = "Coba lagi", size = UDim2.fromOffset(140, 36), anchor = Vector2.new(0.5, 0), style = "primary", position = UDim2.new(0.5, 0, 0.5, 70), onClick = function() startQuery() end }) end
	end

	local function addCard(item)
		local obj = makeCard(gridScroll, item, function() if State.cat.kind == "fav" then startQuery() end end)
		table.insert(activeCards, obj)
	end

	local function loadPage(token)
		if loading or not currentQuery or currentQuery.finished then return end
		loading = token local q = currentQuery
		task.spawn(function()
			local items, err = q:nextPage()
			if token ~= State.searchToken then return end
			loading = false clearSkeleton()
			if not items then showState("⚠", "Gagal memuat katalog", tostring(err) .. "\nPastikan game dipublish / Play Solo di Studio.", true) return end
			for _, it in ipairs(items) do addCard(it) end
			if q.total == 0 then showState("🔎", "Tidak ada hasil", "Coba kata kunci lain atau matikan filter Gratis.") end
			countL.Text = q.total .. " item" .. (q.finished and "" or "+")
		end)
	end

	startQuery = function()
		State.searchToken = State.searchToken + 1
		local token = State.searchToken loading = false clearGrid() local cat = State.cat
		if cat.kind == "fav" or cat.kind == "recent" then
			currentQuery = nil local src = {}
			if cat.kind == "fav" then for _, id in ipairs(State.favOrder) do if State.favorites[id] then table.insert(src, State.favorites[id]) end end else src = State.recent end
			local kw = string.lower(State.keyword or "") local n = 0
			for _, it in ipairs(src) do
				if kw == "" or string.find(string.lower(it.Name), kw, 1, true) then n = n + 1 local copy = clone(it) copy.Order = n addCard(copy) end
			end
			countL.Text = n .. " item"
			if n == 0 then
				if cat.kind == "fav" then showState("★", "Belum ada favorit", "Tekan ♡ pada item mana pun untuk menyimpannya di sini.") else showState("🕘", "Belum ada riwayat", "Item yang kamu pakai akan muncul di sini.") end
			end
			return
		end
		countL.Text = "memuat..." showSkeleton() currentQuery = Catalog.newQuery(cat, State.keyword, State.sortKey, State.freeOnly) loadPage(token)
	end

	gridScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		if gridScroll.CanvasPosition.Y + gridScroll.AbsoluteWindowSize.Y >= gridScroll.AbsoluteCanvasSize.Y - 260 then loadPage(State.searchToken) end
	end)

	local catRows = {}
	local function markCat()
		for id, r in pairs(catRows) do
			local active = id == State.cat.id
			tween(r.btn, { BackgroundTransparency = active and 0 or 1 }, 0.15)
			r.txt.TextColor3 = active and Theme.Accent or Theme.Text r.txt.Font = active and Enum.Font.GothamBold or Enum.Font.GothamMedium
		end
	end
	local function selectCat(cat) State.cat = cat State.keyword = "" sbBox.Text = "" markCat() startQuery() end

	local order, lastGroup = 0, nil
	for _, cat in ipairs(Catalog.categories) do
		if cat.group ~= lastGroup then
			lastGroup = cat.group order = order + 1
			local h = sectionHeader(catScroll, cat.group, order) h.Size = UDim2.new(1, 0, 0, 26) h.TextYAlignment = Enum.TextYAlignment.Bottom
		end
		order = order + 1
		local b = New("TextButton", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = order, Parent = catScroll })
		themed(b, "BackgroundColor3", "SurfaceHigh") corner(b, 9)
		New("TextLabel", { BackgroundTransparency = 1, Text = cat.icon, TextSize = 15, Size = UDim2.fromOffset(28, 32), Position = UDim2.fromOffset(4, 0), Parent = b })
		local t = label(b, cat.name, 13, "Text", Enum.Font.GothamMedium) t.Size = UDim2.new(1, -38, 1, 0) t.Position = UDim2.fromOffset(34, 0) t.TextTruncate = Enum.TextTruncate.AtEnd
		catRows[cat.id] = { btn = b, txt = t }
		b.MouseEnter:Connect(function() if State.cat.id ~= cat.id then tween(b, { BackgroundTransparency = 0.6 }, 0.12) end end)
		b.MouseLeave:Connect(function() if State.cat.id ~= cat.id then tween(b, { BackgroundTransparency = 1 }, 0.12) end end)
		b.Activated:Connect(function() selectCat(cat) end)
	end

	onTheme(function() renderFree() if State.cat then markCat() end end)
	UI.refreshCards = function() for _, c in ipairs(activeCards) do c.update() end end
	UI.onTabShown.catalog = UI.refreshCards

	for _, cat in ipairs(Catalog.categories) do if cat.id == "hat" then selectCat(cat) break end end
end

UI.builders.worn = function(page)
	local head = New("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = page })
	local title = label(head, "Sedang dipakai", 20, "Text", Enum.Font.GothamBold) title.Size = UDim2.new(0.6, 0, 0, 26)
	local sub = label(head, "", 12, "TextDim", Enum.Font.Gotham) sub.Position = UDim2.fromOffset(0, 24) sub.Size = UDim2.new(0.8, 0, 0, 16)
	button(head, { text = "Lepas semua", size = UDim2.fromOffset(110, 32), anchor = Vector2.new(1, 0), position = UDim2.new(1, 0, 0, 2), style = "danger", textSize = 13, onClick = function() task.spawn(Avatar.removeAllAccessories) end })

	local list = makeScroll(page, { position = UDim2.fromOffset(0, 52), size = UDim2.new(1, 0, 1, -52) })
	vlist(list, 8) pad(list, 0, 0, 8, 10)

	UI.refreshWorn = function()
		for _, c in ipairs(list:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
		local seen, n = {}, 0
		for _, e in ipairs(Avatar.getWorn()) do
			if not seen[e.Id] then
				seen[e.Id] = true n = n + 1
				local row = New("Frame", { Size = UDim2.new(1, 0, 0, 62), BorderSizePixel = 0, LayoutOrder = n, Parent = list })
				themed(row, "BackgroundColor3", "Surface") corner(row, 12) stroke(row, "Stroke", 1, 0.3)
				local img = New("ImageLabel", { Size = UDim2.fromOffset(46, 46), Position = UDim2.fromOffset(8, 8), BorderSizePixel = 0, Image = thumbURL("Asset", e.Id, 150), Parent = row })
				themed(img, "BackgroundColor3", "SurfaceHigh") corner(img, 9)
				local nameL = label(row, "Memuat nama...", 14, "Text", Enum.Font.GothamBold) nameL.Position = UDim2.fromOffset(64, 11) nameL.Size = UDim2.new(1, -170, 0, 20) nameL.TextTruncate = Enum.TextTruncate.AtEnd
				local typeL = label(row, Avatar.typeLabel(e), 12, "TextDim", Enum.Font.Gotham) typeL.Position = UDim2.fromOffset(64, 32) typeL.Size = UDim2.new(1, -170, 0, 16)
				button(row, { text = "Lepas", size = UDim2.fromOffset(76, 32), anchor = Vector2.new(1, 0.5), position = UDim2.new(1, -10, 0.5, 0), style = "soft", textSize = 13, onClick = function() task.spawn(function() Avatar.removeAsset(e.Id, nameL.Text) end) end })
				task.spawn(function() local nm = Avatar.itemName(e.Id) if nameL.Parent then nameL.Text = nm end end)
			end
		end
		sub.Text = n .. " item aktif pada karakter"
		if n == 0 then local es = emptyState(list, "🧍", "Belum ada item", "Buka tab Katalog lalu klik item untuk memakainya.") es.Size = UDim2.new(1, 0, 0, 260) end
	end
	UI.onTabShown.worn = UI.refreshWorn UI.refreshWorn()
end

local function userCard(parent, userId, name, order)
	local card = New("TextButton", { Size = UDim2.fromOffset(92, 122), BorderSizePixel = 0, AutoButtonColor = false, Text = "", LayoutOrder = order or 0, Parent = parent })
	themed(card, "BackgroundColor3", "Surface") corner(card, 12) local st = stroke(card, "Stroke", 1, 0.3)
	local img = New("ImageLabel", { Size = UDim2.fromOffset(76, 76), Position = UDim2.fromOffset(8, 8), BorderSizePixel = 0, Image = thumbURL("AvatarHeadShot", userId, 150), Parent = card })
	themed(img, "BackgroundColor3", "SurfaceHigh") corner(img, 38)
	local nm = label(card, name, 12, "Text", Enum.Font.GothamBold, Enum.TextXAlignment.Center) nm.Position = UDim2.fromOffset(4, 88) nm.Size = UDim2.new(1, -8, 0, 16) nm.TextTruncate = Enum.TextTruncate.AtEnd
	local hint = label(card, "klik untuk pakai", 10, "TextDim", Enum.Font.Gotham, Enum.TextXAlignment.Center) hint.Position = UDim2.fromOffset(4, 104) hint.Size = UDim2.new(1, -8, 0, 14)
	card.MouseEnter:Connect(function() tween(card, { BackgroundColor3 = Theme.SurfaceHigh }, 0.15) tween(st, { Transparency = 0, Color = Theme.Accent }, 0.15) end)
	card.MouseLeave:Connect(function() tween(card, { BackgroundColor3 = Theme.Surface }, 0.2) tween(st, { Transparency = 0.3, Color = Theme.Stroke }, 0.2) end)
	local busyCard = false
	card.Activated:Connect(function()
		if busyCard then return end busyCard = true hint.Text = "memuat..."
		task.spawn(function() Avatar.applyUser(userId, name) hint.Text = "klik untuk pakai" busyCard = false end)
	end)
	return card
end

local function userGrid(parent, order)
	local g = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = order, Parent = parent })
	New("UIGridLayout", { CellSize = UDim2.fromOffset(92, 122), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = g })
	return g
end

UI.builders.avatars = function(page)
	local scroll = makeScroll(page) vlist(scroll, 8) pad(scroll, 0, 0, 8, 12)
	local t = label(scroll, "Coba avatar pemain lain", 20, "Text", Enum.Font.GothamBold) t.LayoutOrder = 1 t.Size = UDim2.new(1, 0, 0, 26)
	local s = label(scroll, "Tanpa mengetik nama. Cukup klik kartu untuk meniru tampilannya (hanya di layarmu).", 12, "TextDim", Enum.Font.Gotham) s.LayoutOrder = 2 s.TextWrapped = true s.Size = UDim2.new(1, 0, 0, 30) s.TextYAlignment = Enum.TextYAlignment.Top

	sectionHeader(scroll, "PRESET", 3) local presetGrid = userGrid(scroll, 4)
	for i, p in ipairs(CONFIG.Presets) do userCard(presetGrid, p.Id, p.Name, i) end
	local meCard = userCard(presetGrid, player.UserId, "Aku (asli)", 99) meCard.Activated:Connect(function() end)

	sectionHeader(scroll, "PEMAIN DI SERVER INI", 5) local serverGrid = userGrid(scroll, 6)
	local serverEmpty = label(scroll, "Belum ada pemain lain di server.", 12, "TextDim", Enum.Font.Gotham) serverEmpty.LayoutOrder = 7

	local function refreshServer()
		for _, c in ipairs(serverGrid:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
		local n = 0
		for _, p in ipairs(Players:GetPlayers()) do if p ~= player then n = n + 1 userCard(serverGrid, p.UserId, p.DisplayName, n) end end
		serverEmpty.Visible = n == 0
	end

	sectionHeader(scroll, "TEMAN", 8) local friendGrid = userGrid(scroll, 9)
	local friendStatus = label(scroll, "Memuat daftar teman...", 12, "TextDim", Enum.Font.Gotham) friendStatus.LayoutOrder = 10

	task.spawn(function()
		local ok, pages = pcall(function() return Players:GetFriendsAsync(player.UserId) end)
		if not ok or not pages then friendStatus.Text = "Daftar teman tidak bisa dimuat." return end
		local count, done = 0, false
		while not done and count < 72 do
			for _, f in ipairs(pages:GetCurrentPage()) do count = count + 1 userCard(friendGrid, f.Id, f.DisplayName or f.Username, count) end
			if pages.IsFinished then done = true else local okAdv = pcall(function() pages:AdvanceToNextPageAsync() end) if not okAdv then done = true end end
		end
		friendStatus.Text = count == 0 and "Kamu belum punya teman di akun ini." or (count .. " teman dimuat")
	end)

	UI.onTabShown.avatars = refreshServer refreshServer()
end

UI.builders.outfits = function(page)
	local head = New("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = page })
	local title = label(head, "Outfit tersimpan", 20, "Text", Enum.Font.GothamBold) title.Size = UDim2.new(0.6, 0, 0, 26)
	local sub = label(head, "Tersimpan selama sesi bermain ini.", 12, "TextDim", Enum.Font.Gotham) sub.Position = UDim2.fromOffset(0, 24) sub.Size = UDim2.new(0.7, 0, 0, 16)
	button(head, { text = "＋ Simpan sekarang", size = UDim2.fromOffset(150, 34), anchor = Vector2.new(1, 0), position = UDim2.new(1, 0, 0, 2), style = "primary", textSize = 13, onClick = function() if saveCurrentOutfit then saveCurrentOutfit() end end })

	local list = makeScroll(page, { position = UDim2.fromOffset(0, 54), size = UDim2.new(1, 0, 1, -54) })
	vlist(list, 8) pad(list, 0, 0, 8, 10)

	UI.refreshOutfits = function()
		for _, c in ipairs(list:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
		if #State.outfits == 0 then local es = emptyState(list, "💾", "Belum ada outfit", "Atur tampilan lalu tekan Simpan.") es.Size = UDim2.new(1, 0, 0, 260) return end
		for i, o in ipairs(State.outfits) do
			local row = New("Frame", { Size = UDim2.new(1, 0, 0, 66), BorderSizePixel = 0, LayoutOrder = i, Parent = list })
			themed(row, "BackgroundColor3", "Surface") corner(row, 12) stroke(row, "Stroke", 1, 0.3)
			local ico = New("Frame", { Size = UDim2.fromOffset(46, 46), Position = UDim2.fromOffset(10, 10), BorderSizePixel = 0, Parent = row })
			themed(ico, "BackgroundColor3", "Accent") corner(ico, 12)
			New("TextLabel", { BackgroundTransparency = 1, Text = tostring(i), TextSize = 20, Font = Enum.Font.GothamBold, Size = UDim2.fromScale(1, 1), Parent = ico }).TextColor3 = Color3.new(1, 1, 1)
			local nm = label(row, o.name, 15, "Text", Enum.Font.GothamBold) nm.Position = UDim2.fromOffset(66, 12) nm.Size = UDim2.new(1, -230, 0, 20)
			local info = label(row, o.count .. " aksesori  •  " .. o.time, 12, "TextDim", Enum.Font.Gotham) info.Position = UDim2.fromOffset(66, 34) info.Size = UDim2.new(1, -230, 0, 16)
			button(row, { text = "Hapus", size = UDim2.fromOffset(64, 32), anchor = Vector2.new(1, 0.5), position = UDim2.new(1, -10, 0.5, 0), style = "ghost", textSize = 13, onClick = function() table.remove(State.outfits, i) UI.refreshOutfits() toast("Outfit dihapus", "warn") end })
			button(row, { text = "Pakai", size = UDim2.fromOffset(72, 32), anchor = Vector2.new(1, 0.5), position = UDim2.new(1, -80, 0.5, 0), style = "primary", textSize = 13, onClick = function() task.spawn(function() if Avatar.applySnapshot(o.desc, "Outfit " .. o.name) then toast("Outfit dipakai: " .. o.name, "success") end end) end })
		end
	end
	UI.onTabShown.outfits = UI.refreshOutfits UI.refreshOutfits()
end

UI.builders.body = function(page)
	local scroll = makeScroll(page) vlist(scroll, 6) pad(scroll, 0, 0, 10, 12)
	local t = label(scroll, "Ukuran tubuh", 20, "Text", Enum.Font.GothamBold) t.LayoutOrder = 1 t.Size = UDim2.new(1, 0, 0, 26)
	local s = label(scroll, "Geser slider, perubahan langsung terlihat pada karakter.", 12, "TextDim", Enum.Font.Gotham) s.LayoutOrder = 2 s.Size = UDim2.new(1, 0, 0, 18)

	local defs = {
		{ key = "Height", text = "Tinggi", std = { 0.9, 1.05 }, ext = { 0.5, 2.0 } },
		{ key = "Width", text = "Lebar", std = { 0.7, 1.0 }, ext = { 0.4, 2.0 } },
		{ key = "Depth", text = "Ketebalan", std = { 0.7, 1.0 }, ext = { 0.4, 2.0 } },
		{ key = "Head", text = "Ukuran kepala", std = { 0.95, 1.0 }, ext = { 0.4, 2.0 } },
		{ key = "Proportion", text = "Proporsi", std = { 0, 1 }, ext = { 0, 1 } },
		{ key = "BodyType", text = "Tipe tubuh", std = { 0, 1 }, ext = { 0, 1 } },
	}
	local sliders = {}
	for i, d in ipairs(defs) do
		local sl = slider(scroll, { text = d.text, min = d.std[1], max = d.std[2], value = 1, order = 10 + i, onChange = function(v) Avatar.setScale(d.key, v) end })
		sliders[d.key] = sl
	end

	local function setRanges()
		for _, d in ipairs(defs) do local r = State.extendedScale and d.ext or d.std sliders[d.key].SetRange(r[1], r[2]) end
	end

	local tg = toggle(scroll, { text = "Mode bebas", sub = "Izinkan rentang ukuran di luar batas standar Roblox", value = State.extendedScale, order = 30, onChange = function(v) State.extendedScale = v setRanges() end })
	local rb = button(scroll, { text = "Reset ukuran", size = UDim2.new(1, 0, 0, 36), style = "soft", order = 31, onClick = function() Avatar.resetScales() UI.syncBody() toast("Ukuran tubuh direset", "success") end })

	function UI.syncBody()
		local hum = Avatar.humanoid()
		for key, nvName in pairs({ Height = "BodyHeightScale", Width = "BodyWidthScale", Depth = "BodyDepthScale", Head = "HeadScale", Proportion = "BodyProportionScale", BodyType = "BodyTypeScale" }) do
			local nv = hum:FindFirstChild(nvName) if nv and nv:IsA("NumberValue") and sliders[key] then sliders[key].Set(nv.Value) end
		end
	end
	UI.onTabShown.body = UI.syncBody setRanges() UI.syncBody()
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
	local scroll = makeScroll(page) vlist(scroll, 8) pad(scroll, 0, 0, 10, 12)
	local t = label(scroll, "Warna kulit", 20, "Text", Enum.Font.GothamBold) t.LayoutOrder = 1 t.Size = UDim2.new(1, 0, 0, 26)
	local s = label(scroll, "Pilih warna dari palet atau campur sendiri dengan slider RGB.", 12, "TextDim", Enum.Font.Gotham) s.LayoutOrder = 2 s.Size = UDim2.new(1, 0, 0, 18)

	local grid = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 3, Parent = scroll })
	New("UIGridLayout", { CellSize = UDim2.fromOffset(54, 54), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })

	local preview = New("Frame", { Size = UDim2.new(1, 0, 0, 56), BorderSizePixel = 0, LayoutOrder = 10, Parent = scroll }) corner(preview, 12) stroke(preview, "Stroke", 1, 0)
	local hexL = New("TextLabel", { BackgroundTransparency = 1, Text = "", TextSize = 15, Font = Enum.Font.GothamBold, Size = UDim2.fromScale(1, 1), Parent = preview })

	local r, g, b = 255, 204, 153 local sr, sg, sb
	local function render(fireApply)
		local c = Color3.fromRGB(r, g, b) preview.BackgroundColor3 = c
		local lum = (r * 0.299 + g * 0.587 + b * 0.114)
		hexL.TextColor3 = lum > 140 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1) hexL.Text = string.format("#%02X%02X%02X", r, g, b)
		if fireApply then Avatar.setSkin(c) end
	end
	local function setRGB(c, fireApply)
		r, g, b = math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)
		sr.Set(r) sg.Set(g) sb.Set(b) render(fireApply)
	end

	for i, c in ipairs(PALETTE) do
		local sw = New("TextButton", { BackgroundColor3 = c, Text = "", AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = i, Parent = grid })
		corner(sw, 14) local st = stroke(sw, "Stroke", 2, 0.4) local sc = New("UIScale", { Parent = sw })
		sw.MouseEnter:Connect(function() tween(sc, { Scale = 1.08 }, 0.15, Enum.EasingStyle.Back) tween(st, { Transparency = 0, Color = Theme.Accent }, 0.15) end)
		sw.MouseLeave:Connect(function() tween(sc, { Scale = 1 }, 0.15) tween(st, { Transparency = 0.4, Color = Theme.Stroke }, 0.15) end)
		sw.Activated:Connect(function() setRGB(c, true) end)
	end

	local function rgbSlider(text, order, onChange)
		return slider(scroll, { text = text, min = 0, max = 255, step = 1, value = 200, order = order, format = function(v) return tostring(math.floor(v)) end, onChange = onChange })
	end
	sr = rgbSlider("Merah", 11, function(v) r = v render(true) end)
	sg = rgbSlider("Hijau", 12, function(v) g = v render(true) end)
	sb = rgbSlider("Biru", 13, function(v) b = v render(true) end)
	button(scroll, { text = "Kembalikan warna asli", size = UDim2.new(1, 0, 0, 36), style = "soft", order = 14, onClick = function() Avatar.resetSkin() toast("Warna kulit dikembalikan", "success") end })
	setRGB(Color3.fromRGB(255, 204, 153), false)
end

UI.builders.settings = function(page)
	local scroll = makeScroll(page) vlist(scroll, 8) pad(scroll, 0, 0, 10, 12)
	local t = label(scroll, "Setelan", 20, "Text", Enum.Font.GothamBold) t.LayoutOrder = 1 t.Size = UDim2.new(1, 0, 0, 26)

	sectionHeader(scroll, "TEMA WARNA", 2)
	local themeRow = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 3, Parent = scroll })
	New("UIGridLayout", { CellSize = UDim2.fromOffset(112, 42), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = themeRow })
	local themeBtns = {}
	local function markThemes()
		for name, b in pairs(themeBtns) do local active = name == State.themeName b.stroke.Transparency = active and 0 or 1 b.stroke.Color = THEMES[name].Accent end
	end
	for i, name in ipairs(THEME_ORDER) do
		local def = THEMES[name]
		local b = New("TextButton", { BackgroundColor3 = def.Surface, Text = "", AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = i, Parent = themeRow })
		corner(b, 12) local st = New("UIStroke", { Thickness = 2, Transparency = 1, Color = def.Accent, Parent = b })
		local dot = New("Frame", { Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(12, 13), BackgroundColor3 = def.Accent, BorderSizePixel = 0, Parent = b })
		corner(dot, 8)
		New("TextLabel", { BackgroundTransparency = 1, Text = name, TextSize = 13, Font = Enum.Font.GothamBold, TextColor3 = def.Text, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -40, 1, 0), Position = UDim2.fromOffset(36, 0), Parent = b })
		themeBtns[name] = { btn = b, stroke = st }
		b.Activated:Connect(function() applyTheme(name) markThemes() UI.showTab(State.tab) end)
	end
	markThemes()

	sectionHeader(scroll, "TAMPILAN", 4)
	slider(scroll, { text = "Skala UI", min = 0.7, max = 1.3, step = 0.05, value = State.uiScale, order = 5, format = function(v) return string.format("%d%%", math.floor(v * 100 + 0.5)) end, onChange = function(v) State.uiScale = v UI.rescale() end })
	toggle(scroll, { text = "Putar pratinjau otomatis", value = State.autoRotate, order = 6, onChange = function(v) State.autoRotate = v end })

	sectionHeader(scroll, "AVATAR", 7)
	toggle(scroll, { text = "Pertahankan tampilan saat respawn", sub = "Avatar kostum dipasang lagi setelah karakter muncul ulang", value = State.persist, order = 8, onChange = function(v) State.persist = v end })

	sectionHeader(scroll, "PINTASAN", 9)
	local keys = label(scroll, "K  buka / tutup UI\nCtrl+Z  undo\nCtrl+Y  redo", 13, "TextDim", Enum.Font.GothamMedium) keys.LayoutOrder = 10 keys.Size = UDim2.new(1, 0, 0, 56) keys.TextWrapped = true keys.TextYAlignment = Enum.TextYAlignment.Top

	button(scroll, { text = "🩺 Diagnostik avatar", size = UDim2.new(1, 0, 0, 36), style = "primary", order = 10, onClick = function() task.spawn(Avatar.diagnose) end })
	button(scroll, { text = "Tutup UI", size = UDim2.new(1, 0, 0, 36), style = "soft", order = 11, onClick = function() UI.setOpen(false) end })
	button(scroll, { text = "Hapus UI sepenuhnya", size = UDim2.new(1, 0, 0, 36), style = "danger", order = 12, onClick = function() UI.gui:Destroy() end })
end

----------------------------------------------------------------------------
-- [19] FITUR GABUNGAN: ACAK & SIMPAN OUTFIT
----------------------------------------------------------------------------
State.outfitCounter = 0

randomLook = function()
	toast("Mengacak gaya dari katalog...", "info")
	task.spawn(function()
		local pool = { "hat", "hair", "face_acc", "back", "neck", "jacket", "l_shirt", "l_pants", "shoulder", "waist" }
		for i = #pool, 2, -1 do local j = math.random(1, i) pool[i], pool[j] = pool[j], pool[i] end
		local chosen = {} for i = 1, 5 do table.insert(chosen, pool[i]) end
		local picked = Catalog.randomItems(chosen, 1)
		if #picked == 0 then toast("Katalog tidak bisa dimuat untuk mengacak", "danger") return end
		if Avatar.addMany(picked, "Acak gaya") then
			for _, it in ipairs(picked) do addRecent(it) end
			toast("Gaya acak diterapkan (" .. #picked .. " item)", "success")
		end
	end)
end

saveCurrentOutfit = function()
	local d = Avatar.snapshotDescription()
	if not d then toast("Karakter belum siap", "danger") return end
	State.outfitCounter = State.outfitCounter + 1
	local ok, accs = pcall(function() return d:GetAccessories(true) end)
	table.insert(State.outfits, { name = "Outfit " .. State.outfitCounter, desc = d, count = ok and #accs or 0, time = os.date("%H:%M") })
	if UI.refreshOutfits then UI.refreshOutfits() end
	toast("Outfit " .. State.outfitCounter .. " disimpan", "success")
end

----------------------------------------------------------------------------
-- [20] BUKA / TUTUP / MINIMIZE
----------------------------------------------------------------------------
UI.fab = New("TextButton", { Name = "OpenButton", Size = UDim2.fromOffset(56, 56), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 16, 0.5, 0), Text = "👗", TextSize = 26, AutoButtonColor = false, BorderSizePixel = 0, Visible = false, ZIndex = 20, Parent = UI.gui })
themed(UI.fab, "BackgroundColor3", "Accent") corner(UI.fab, 28) stroke(UI.fab, "Text", 2, 0.7)
do
	local fs = New("UIScale", { Parent = UI.fab })
	UI.fab.MouseEnter:Connect(function() tween(fs, { Scale = 1.1 }, 0.15, Enum.EasingStyle.Back) end)
	UI.fab.MouseLeave:Connect(function() tween(fs, { Scale = 1 }, 0.15) end)
end
UI.fab.Activated:Connect(function() UI.setOpen(true) end)

function UI.setOpen(open)
	State.open = open
	if open then
		UI.fab.Visible = false UI.window.Visible = true UI.winScale.Scale = UI.baseScale * 0.9 tween(UI.winScale, { Scale = UI.baseScale }, 0.4, Enum.EasingStyle.Back)
	else
		tween(UI.winScale, { Scale = UI.baseScale * 0.9 }, 0.2)
		task.delay(0.2, function() if not State.open then UI.window.Visible = false UI.fab.Visible = true end end)
	end
end

function UI.setMinimized(min)
	State.minimized = min
	if min then
		UI.body.Visible = false tween(UI.window, { Size = UDim2.fromOffset(W, TITLE_H) }, 0.3) UI.minBtn.Text = "▢"
	else
		tween(UI.window, { Size = UDim2.fromOffset(W, H) }, 0.3, Enum.EasingStyle.Back)
		task.delay(0.12, function() if not State.minimized then UI.body.Visible = true end end)
		UI.minBtn.Text = "—"
	end
end

UI.closeBtn.Activated:Connect(function() UI.setOpen(false) end)
UI.minBtn.Activated:Connect(function() UI.setMinimized(not State.minimized) end)

----------------------------------------------------------------------------
-- [21] KEYBIND
----------------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == CONFIG.ToggleKey then UI.setOpen(not State.open) return end
	local ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
	if ctrl and State.open then
		if input.KeyCode == Enum.KeyCode.Z then task.spawn(Avatar.undo)
		elseif input.KeyCode == Enum.KeyCode.Y then task.spawn(Avatar.redo) end
	end
end)

local camera = Workspace.CurrentCamera
if camera then
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(function() UI.rescale() end)
end

----------------------------------------------------------------------------
-- [22] REAKSI PERUBAHAN AVATAR
----------------------------------------------------------------------------
local function updateHistoryButtons()
	UI.undoBtn.TextTransparency = Avatar.canUndo() and 0 or 0.65
	UI.redoBtn.TextTransparency = Avatar.canRedo() and 0 or 0.65
end

Avatar.onChanged(function()
	local n = #Avatar.getWorn()
	UI.subtitle.Text = n .. " item dipakai  •  tema " .. State.themeName
	Preview.stat.Text = n .. " item dipakai"
	if UI.refreshCards then UI.refreshCards() end
	if UI.refreshWorn and State.tab == "worn" then UI.refreshWorn() end
	updateHistoryButtons() Preview.refresh()
end)
updateHistoryButtons()

----------------------------------------------------------------------------
-- [23] START
----------------------------------------------------------------------------
UI.showTab("catalog")
UI.setOpen(true)

task.spawn(function()
	local ok, err = pcall(Avatar.init)
	if not ok then toast("Gagal menyiapkan karakter: " .. tostring(err), "danger") return end
	Preview.refresh()
	toast("Avatar Studio siap! Tekan K untuk buka/tutup", "success")
end)
