--[[
    Leon4951hub — UI STANDALONE (library + shell)
    Latar hitam, outline biru tipis, sidebar tab, kolom Search, footer FPS / ms.

    Bisa langsung di-execute sendiri. Tab "Performance" otomatis terhubung ke
    FPS Boost kalau script.lua (FPS Boost) sudah dijalankan lebih dulu.

    API (kalau mau menambah tab sendiri):
        local hub = getgenv().LeonHub                 -- window yang sudah jadi
        local tab = hub:AddTab({ Name = "Nama Tab" })
        tab:AddSection("Judul Section")
        tab:AddParagraph({ Title = "..", Content = ".." })      -- :Set(title, content)
        tab:AddToggle({ Title = "..", Content = "..", Default = false, Callback = function(v) end })
        tab:AddButton({ Title = "..", Content = "..", ButtonText = "Run", Callback = function() end })
        tab:AddSlider({ Title = "..", Min = 0, Max = 100, Step = 1, Default = 50, Callback = function(v) end })
        tab:AddDropdown({ Title = "..", Options = {"A","B"}, Default = "A", Multi = false, Callback = function(v) end })
        tab:AddInput({ Title = "..", Placeholder = "..", Default = "", Callback = function(text) end })
        hub:Notify("pesan", 2.5)
        hub:Destroy()
    Library mentah: getgenv().LeonHubLib.Window({ Title = "Nama", Width = 560, Height = 360 })

    Catatan: ini library UI buatan sendiri. UI asli Sena tidak ada di dalam file-nya
    (dimuat dari luar lewat loadstring), jadi tidak ada kode UI yang bisa disalin.
]]

local genv = (getgenv and getgenv()) or _G

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local Stats            = game:GetService("Stats")
local LocalPlayer      = Players.LocalPlayer

-- bersihkan eksekusi sebelumnya
if genv.__LeonHubGui then
	pcall(function() genv.__LeonHubGui:Destroy() end)
end
if genv.__LeonHubConns then
	for _, c in ipairs(genv.__LeonHubConns) do
		pcall(function() c:Disconnect() end)
	end
end
local conns = {}
genv.__LeonHubConns = conns
local function track(c)
	conns[#conns + 1] = c
	return c
end

---------------------------------------------------------------------
-- TEMA: hitam + outline biru
---------------------------------------------------------------------
local Theme = {
	bg        = Color3.fromRGB(0, 0, 0),
	panel     = Color3.fromRGB(10, 10, 14),
	card      = Color3.fromRGB(17, 17, 23),
	cardHover = Color3.fromRGB(24, 24, 32),
	accent    = Color3.fromRGB(0, 140, 255),
	accentDim = Color3.fromRGB(0, 82, 160),
	text      = Color3.fromRGB(242, 244, 250),
	sub       = Color3.fromRGB(150, 156, 172),
	off       = Color3.fromRGB(44, 46, 58),
	ok        = Color3.fromRGB(74, 222, 128),
	warn      = Color3.fromRGB(245, 196, 81),
	bad       = Color3.fromRGB(248, 113, 113),
}

---------------------------------------------------------------------
-- HELPER
---------------------------------------------------------------------
local function create(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do
		o[k] = v
	end
	if parent then
		o.Parent = parent
	end
	return o
end

local function round(o, r)
	return create("UICorner", { CornerRadius = UDim.new(0, r) }, o)
end

local function outline(o, color, thickness, transparency)
	return create("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, o)
end

local function tween(o, props, t)
	TweenService:Create(o, TweenInfo.new(t or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function guiParent()
	local ok, p = pcall(function()
		return (gethui and gethui()) or game:GetService("CoreGui")
	end)
	if ok and p then
		return p
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end

---------------------------------------------------------------------
-- WINDOW
---------------------------------------------------------------------
local function createWindow(opts)
	opts = opts or {}
	local W, H = opts.Width or 560, opts.Height or 360
	local HEADER_H, FOOTER_H, SIDE_W = 42, 34, 150

	local gui = create("ScreenGui", {
		Name = "Leon4951hub",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 99999,
	}, guiParent())
	genv.__LeonHubGui = gui

	-- luar: tampilan (hitam + outline biru); dalam: konten yang diskalakan untuk layar kecil
	local main = create("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(W, H),
		BackgroundColor3 = Theme.bg,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Active = true,
	}, gui)
	round(main, 12)
	outline(main, Theme.accent, 1.5, 0.1)

	local ui = create("Frame", {
		Name = "UI",
		Size = UDim2.fromOffset(W, H),
		BackgroundTransparency = 1,
	}, main)
	local scale = create("UIScale", { Scale = 1 }, ui)

	local collapsed = false
	local currentScale = 1
	local function targetSize()
		return UDim2.fromOffset(W * currentScale, (collapsed and (HEADER_H + 2) or H) * currentScale)
	end
	local function fit()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		currentScale = math.clamp(math.min(vp.X * 0.92 / W, vp.Y * 0.86 / H), 0.5, 1)
		scale.Scale = currentScale
		main.Size = targetSize()
	end
	fit()
	local cam0 = workspace.CurrentCamera
	if cam0 then
		track(cam0:GetPropertyChangedSignal("ViewportSize"):Connect(fit))
	end

	---------------- header ----------------
	local header = create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, HEADER_H),
		BackgroundTransparency = 1,
	}, ui)

	create("Frame", {
		Position = UDim2.fromOffset(14, 14),
		Size = UDim2.fromOffset(4, 14),
		BackgroundColor3 = Theme.accent,
		BorderSizePixel = 0,
	}, header)

	create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(26, 0),
		Size = UDim2.new(0, 190, 1, 0),
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.text,
		Text = opts.Title or "Leon4951hub",
	}, header)

	local searchBox = create("TextBox", {
		Name = "Search",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -84, 0.5, 0),
		Size = UDim2.fromOffset(150, 26),
		BackgroundColor3 = Theme.card,
		BorderSizePixel = 0,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = Theme.text,
		PlaceholderText = "Search",
		PlaceholderColor3 = Theme.sub,
		Text = "",
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, header)
	round(searchBox, 13)
	outline(searchBox, Theme.accent, 1, 0.7)
	create("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 8),
	}, searchBox)

	local function headerButton(text, x)
		local b = create("TextButton", {
			AutoButtonColor = false,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, x, 0.5, 0),
			Size = UDim2.fromOffset(26, 26),
			BackgroundColor3 = Theme.card,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextColor3 = Theme.text,
			Text = text,
		}, header)
		round(b, 13)
		b.MouseEnter:Connect(function() tween(b, { BackgroundColor3 = Theme.cardHover }, 0.12) end)
		b.MouseLeave:Connect(function() tween(b, { BackgroundColor3 = Theme.card }, 0.12) end)
		return b
	end
	local closeBtn = headerButton("x", -12)
	local minBtn = headerButton("-", -44)

	create("Frame", {
		Position = UDim2.fromOffset(0, HEADER_H),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Theme.accent,
		BackgroundTransparency = 0.75,
		BorderSizePixel = 0,
	}, ui)

	---------------- body ----------------
	local body = create("Frame", {
		Name = "Body",
		Position = UDim2.fromOffset(0, HEADER_H + 1),
		Size = UDim2.new(1, 0, 1, -(HEADER_H + 1 + FOOTER_H)),
		BackgroundTransparency = 1,
	}, ui)

	local sideList = create("ScrollingFrame", {
		Name = "Sidebar",
		Size = UDim2.new(0, SIDE_W, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
	}, body)
	create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, sideList)
	create("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	}, sideList)

	create("Frame", {
		Position = UDim2.fromOffset(SIDE_W, 8),
		Size = UDim2.new(0, 1, 1, -16),
		BackgroundColor3 = Theme.accent,
		BackgroundTransparency = 0.8,
		BorderSizePixel = 0,
	}, body)

	local content = create("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(SIDE_W + 1, 0),
		Size = UDim2.new(1, -(SIDE_W + 1), 1, 0),
		BackgroundTransparency = 1,
	}, body)

	---------------- footer ----------------
	local footer = create("Frame", {
		Name = "Footer",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, FOOTER_H),
		BackgroundTransparency = 1,
	}, ui)
	create("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Theme.accent,
		BackgroundTransparency = 0.75,
		BorderSizePixel = 0,
	}, footer)
	create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(0.5, 0, 1, 0),
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.sub,
		Text = "Welcome, " .. tostring(LocalPlayer and LocalPlayer.DisplayName or "player"),
	}, footer)

	local function chip(x)
		local c = create("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, x, 0.5, 1),
			Size = UDim2.fromOffset(74, 22),
			BackgroundColor3 = Theme.card,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			TextColor3 = Theme.text,
			Text = "--",
		}, footer)
		round(c, 11)
		outline(c, Theme.accent, 1, 0.8)
		return c
	end
	local pingChip = chip(-12)
	local fpsChip = chip(-92)

	do
		local frames, acc = 0, 0
		track(RunService.RenderStepped:Connect(function(dt)
			frames = frames + 1
			acc = acc + dt
			if acc < 0.5 then
				return
			end
			local fps = math.floor(frames / acc + 0.5)
			frames, acc = 0, 0
			fpsChip.Text = fps .. " FPS"
			fpsChip.TextColor3 = fps >= 50 and Theme.ok or (fps >= 30 and Theme.warn or Theme.bad)
			local ms
			pcall(function()
				ms = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5)
			end)
			pingChip.Text = (ms and tostring(ms) or "--") .. " ms"
		end))
	end

	---------------- toast ----------------
	local toast = create("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -(FOOTER_H + 10)),
		Size = UDim2.fromOffset(300, 28),
		BackgroundColor3 = Theme.panel,
		BackgroundTransparency = 1,
		TextTransparency = 1,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = Theme.text,
		Text = "",
		ZIndex = 20,
	}, ui)
	round(toast, 8)
	local toastId = 0

	---------------- window object ----------------
	local win = {}
	local tabs = {}
	local currentTab

	local function applySearch()
		local q = string.lower(searchBox.Text or "")
		for _, t in ipairs(tabs) do
			for _, it in ipairs(t.items) do
				it.frame.Visible = (q == "") or (string.find(it.key, q, 1, true) ~= nil)
			end
			for _, s in ipairs(t.sections) do
				s.Visible = (q == "")
			end
		end
	end
	track(searchBox:GetPropertyChangedSignal("Text"):Connect(applySearch))

	local function selectTab(tab)
		for _, t in ipairs(tabs) do
			local on = (t == tab)
			t.page.Visible = on
			t.bar.Visible = on
			tween(t.btn, {
				BackgroundTransparency = on and 0.7 or 1,
				TextColor3 = on and Theme.text or Theme.sub,
			}, 0.15)
		end
		currentTab = tab
		applySearch()
	end

	function win:Notify(text, secs)
		toastId = toastId + 1
		local id = toastId
		toast.Text = tostring(text)
		tween(toast, { BackgroundTransparency = 0.05, TextTransparency = 0 }, 0.2)
		task.delay(secs or 2.5, function()
			if id == toastId then
				tween(toast, { BackgroundTransparency = 1, TextTransparency = 1 }, 0.3)
			end
		end)
	end

	function win:Destroy()
		for _, c in ipairs(conns) do
			pcall(function() c:Disconnect() end)
		end
		pcall(function() gui:Destroy() end)
	end

	function win:SelectTab(tab)
		selectTab(tab)
	end

	---------------- kartu komponen ----------------
	local function makeCard(tab, o, rightW)
		tab.order = tab.order + 1
		local card = create("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Theme.card,
			BorderSizePixel = 0,
			LayoutOrder = tab.order,
		}, tab.page)
		round(card, 8)
		outline(card, Theme.accent, 1, 0.85)
		create("UIPadding", {
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
		}, card)
		create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, card)

		local row = create("Frame", {
			Size = UDim2.new(1, 0, 0, 26),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, card)
		local holder = create("Frame", {
			Size = UDim2.new(1, -(rightW or 0), 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
		}, row)
		create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, holder)

		local titleLbl = create("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			TextSize = 15,
			TextColor3 = Theme.text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			Text = o.Title or "",
			LayoutOrder = 1,
		}, holder)

		local contentLbl
		if o.Content and o.Content ~= "" then
			contentLbl = create("TextLabel", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Font = Enum.Font.Gotham,
				TextSize = 13,
				TextColor3 = Theme.sub,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				Text = o.Content,
				LayoutOrder = 2,
			}, holder)
		end

		tab.items[#tab.items + 1] = {
			frame = card,
			key = string.lower((o.Title or "") .. " " .. (o.Content or "")),
		}
		return card, row, titleLbl, contentLbl, holder
	end

	---------------- tab ----------------
	function win:AddTab(o)
		o = o or {}
		local tab = { Name = o.Name or "Tab", items = {}, sections = {}, order = 0 }

		local btn = create("TextButton", {
			AutoButtonColor = false,
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundColor3 = Theme.accentDim,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamMedium,
			TextSize = 14,
			TextColor3 = Theme.sub,
			Text = tab.Name,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = o.LayoutOrder or (#tabs + 1),
		}, sideList)
		round(btn, 8)
		create("UIPadding", { PaddingLeft = UDim.new(0, 16) }, btn)
		local bar = create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, -12, 0.5, 0),
			Size = UDim2.fromOffset(3, 18),
			BackgroundColor3 = Theme.accent,
			BorderSizePixel = 0,
			Visible = false,
		}, btn)
		round(bar, 2)

		local page = create("ScrollingFrame", {
			Name = tab.Name,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.accent,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			Visible = false,
		}, content)
		create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
		create("UIPadding", {
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 14),
		}, page)

		tab.btn, tab.bar, tab.page = btn, bar, page
		tabs[#tabs + 1] = tab
		btn.MouseButton1Click:Connect(function()
			selectTab(tab)
		end)

		---------- Section ----------
		function tab:AddSection(title)
			tab.order = tab.order + 1
			local lbl = create("TextLabel", {
				Size = UDim2.new(1, 0, 0, 22),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				TextSize = 13,
				TextColor3 = Theme.accent,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = string.upper(tostring(title or "")),
				LayoutOrder = tab.order,
			}, page)
			tab.sections[#tab.sections + 1] = lbl
			return lbl
		end

		---------- Paragraph ----------
		function tab:AddParagraph(opt)
			opt = opt or {}
			opt.Content = opt.Content or " "
			local _, _, titleLbl, contentLbl = makeCard(tab, opt, 0)
			local obj = {}
			function obj:Set(title, text)
				if title ~= nil then
					titleLbl.Text = tostring(title)
				end
				if text ~= nil and contentLbl then
					contentLbl.Text = tostring(text)
				end
			end
			return obj
		end

		---------- Toggle ----------
		function tab:AddToggle(opt)
			opt = opt or {}
			local _, row = makeCard(tab, opt, 56)
			local rail = create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(44, 24),
				BackgroundColor3 = Theme.off,
				BorderSizePixel = 0,
			}, row)
			round(rail, 12)
			outline(rail, Theme.accent, 1, 0.7)
			local knob = create("Frame", {
				Size = UDim2.fromOffset(18, 18),
				Position = UDim2.fromOffset(3, 3),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
			}, rail)
			round(knob, 9)
			local hit = create("TextButton", {
				BackgroundTransparency = 1,
				Text = "",
				Size = UDim2.fromScale(1, 1),
				ZIndex = 5,
			}, row)

			local obj = { Value = opt.Default == true }
			local function render(animated)
				local t = animated and 0.18 or 0
				tween(rail, { BackgroundColor3 = obj.Value and Theme.accent or Theme.off }, t)
				tween(knob, { Position = obj.Value and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3) }, t)
			end
			render(false)

			function obj:Set(v, silent)
				obj.Value = v and true or false
				render(true)
				if not silent and opt.Callback then
					task.spawn(opt.Callback, obj.Value)
				end
			end
			hit.MouseButton1Click:Connect(function()
				obj:Set(not obj.Value)
			end)
			return obj
		end

		---------- Button ----------
		function tab:AddButton(opt)
			opt = opt or {}
			local _, row = makeCard(tab, opt, 96)
			local b = create("TextButton", {
				AutoButtonColor = false,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(88, 28),
				BackgroundColor3 = Theme.accentDim,
				BorderSizePixel = 0,
				Font = Enum.Font.GothamMedium,
				TextSize = 13,
				TextColor3 = Theme.text,
				Text = opt.ButtonText or "Run",
			}, row)
			round(b, 6)
			b.MouseEnter:Connect(function() tween(b, { BackgroundColor3 = Theme.accent }, 0.12) end)
			b.MouseLeave:Connect(function() tween(b, { BackgroundColor3 = Theme.accentDim }, 0.12) end)
			b.MouseButton1Click:Connect(function()
				if opt.Callback then
					task.spawn(opt.Callback)
				end
			end)
			local obj = {}
			function obj:SetText(t)
				b.Text = tostring(t)
			end
			return obj
		end

		---------- Slider ----------
		function tab:AddSlider(opt)
			opt = opt or {}
			local min, max = opt.Min or 0, opt.Max or 100
			local step = opt.Step or 1
			local card, row = makeCard(tab, opt, 58)

			local valLbl = create("TextLabel", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, 0, 0, 0),
				Size = UDim2.fromOffset(50, 22),
				BackgroundColor3 = Theme.panel,
				BorderSizePixel = 0,
				Font = Enum.Font.GothamMedium,
				TextSize = 13,
				TextColor3 = Theme.text,
				Text = "",
			}, row)
			round(valLbl, 6)

			local area = create("Frame", {
				Size = UDim2.new(1, 0, 0, 18),
				BackgroundTransparency = 1,
				LayoutOrder = 2,
			}, card)
			local rail = create("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.new(1, 0, 0, 4),
				BackgroundColor3 = Theme.off,
				BorderSizePixel = 0,
			}, area)
			round(rail, 2)
			local fill = create("Frame", {
				Size = UDim2.fromScale(0, 1),
				BackgroundColor3 = Theme.accent,
				BorderSizePixel = 0,
			}, rail)
			round(fill, 2)
			local knob = create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.fromOffset(14, 14),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
			}, rail)
			round(knob, 7)
			local hit = create("TextButton", {
				BackgroundTransparency = 1,
				Text = "",
				Size = UDim2.fromScale(1, 1),
				ZIndex = 5,
			}, area)

			local obj = { Value = math.clamp(opt.Default or min, min, max) }
			local function setValue(v, silent)
				v = math.clamp(math.floor((v - min) / step + 0.5) * step + min, min, max)
				v = math.floor(v * 1000 + 0.5) / 1000
				obj.Value = v
				local a = (max == min) and 0 or (v - min) / (max - min)
				fill.Size = UDim2.fromScale(a, 1)
				knob.Position = UDim2.fromScale(a, 0.5)
				valLbl.Text = tostring(v)
				if not silent and opt.Callback then
					task.spawn(opt.Callback, v)
				end
			end
			setValue(obj.Value, true)
			function obj:Set(v, silent)
				setValue(v, silent)
			end

			local dragging = false
			local function fromX(x)
				local a = math.clamp((x - rail.AbsolutePosition.X) / math.max(rail.AbsoluteSize.X, 1), 0, 1)
				setValue(min + a * (max - min))
			end
			hit.InputBegan:Connect(function(i)
				if isPress(i) then
					dragging = true
					fromX(i.Position.X)
				end
			end)
			track(UserInputService.InputChanged:Connect(function(i)
				if dragging and isMove(i) then
					fromX(i.Position.X)
				end
			end))
			track(UserInputService.InputEnded:Connect(function(i)
				if isPress(i) then
					dragging = false
				end
			end))
			return obj
		end

		---------- Dropdown (single / multi) ----------
		function tab:AddDropdown(opt)
			opt = opt or {}
			local options = opt.Options or {}
			local multi = opt.Multi == true
			local card, row = makeCard(tab, opt, 154)

			local btn = create("TextButton", {
				AutoButtonColor = false,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(146, 28),
				BackgroundColor3 = Theme.panel,
				BorderSizePixel = 0,
				Text = "",
			}, row)
			round(btn, 6)
			outline(btn, Theme.accent, 1, 0.7)
			local lbl = create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(8, 0),
				Size = UDim2.new(1, -28, 1, 0),
				Font = Enum.Font.Gotham,
				TextSize = 13,
				TextColor3 = Theme.text,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = "",
			}, btn)
			local arrow = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 0),
				Size = UDim2.fromOffset(14, 14),
				Font = Enum.Font.GothamBold,
				TextSize = 12,
				TextColor3 = Theme.sub,
				Text = "v",
			}, btn)

			local list = create("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Visible = false,
				LayoutOrder = 2,
			}, card)
			create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, list)

			local obj = { Value = nil }
			local selected = {}
			local current = nil
			if multi then
				for _, name in ipairs(opt.Default or {}) do
					selected[name] = true
				end
			else
				current = opt.Default
			end

			local optButtons = {}
			local function collect()
				local picked = {}
				for _, name in ipairs(options) do
					if selected[name] then
						picked[#picked + 1] = name
					end
				end
				return picked
			end
			local function refresh()
				if multi then
					local picked = collect()
					local names = {}
					for _, name in ipairs(picked) do
						names[#names + 1] = tostring(name)
					end
					lbl.Text = (#names > 0) and table.concat(names, ", ") or (opt.Placeholder or "Select Options")
					obj.Value = picked
				else
					lbl.Text = (current ~= nil) and tostring(current) or (opt.Placeholder or "Select")
					obj.Value = current
				end
				for name, b in pairs(optButtons) do
					local on
					if multi then
						on = selected[name] == true
					else
						on = (current == name)
					end
					b.BackgroundColor3 = on and Theme.accentDim or Theme.panel
				end
			end

			for i, name in ipairs(options) do
				local ob = create("TextButton", {
					AutoButtonColor = false,
					Size = UDim2.new(1, 0, 0, 26),
					BackgroundColor3 = Theme.panel,
					BorderSizePixel = 0,
					Font = Enum.Font.Gotham,
					TextSize = 13,
					TextColor3 = Theme.text,
					Text = tostring(name),
					LayoutOrder = i,
				}, list)
				round(ob, 6)
				optButtons[name] = ob
				ob.MouseButton1Click:Connect(function()
					if multi then
						selected[name] = (not selected[name]) or nil
					else
						current = name
						list.Visible = false
						arrow.Text = "v"
					end
					refresh()
					if opt.Callback then
						task.spawn(opt.Callback, obj.Value)
					end
				end)
			end
			refresh()

			btn.MouseButton1Click:Connect(function()
				list.Visible = not list.Visible
				arrow.Text = list.Visible and "^" or "v"
			end)

			function obj:Set(v, silent)
				if multi then
					selected = {}
					for _, name in ipairs(v or {}) do
						selected[name] = true
					end
				else
					current = v
				end
				refresh()
				if not silent and opt.Callback then
					task.spawn(opt.Callback, obj.Value)
				end
			end
			return obj
		end

		---------- Input ----------
		function tab:AddInput(opt)
			opt = opt or {}
			local card = makeCard(tab, opt, 0)
			local box = create("TextBox", {
				Size = UDim2.new(1, 0, 0, 30),
				BackgroundColor3 = Theme.panel,
				BorderSizePixel = 0,
				Font = Enum.Font.Gotham,
				TextSize = 13,
				TextColor3 = Theme.text,
				PlaceholderText = opt.Placeholder or "",
				PlaceholderColor3 = Theme.sub,
				Text = opt.Default or "",
				ClearTextOnFocus = false,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 2,
			}, card)
			round(box, 6)
			outline(box, Theme.accent, 1, 0.7)
			create("UIPadding", {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			}, box)
			box.FocusLost:Connect(function()
				if opt.Callback then
					task.spawn(opt.Callback, box.Text)
				end
			end)
			local obj = {}
			function obj:Set(text)
				box.Text = tostring(text)
			end
			function obj:Get()
				return box.Text
			end
			return obj
		end

		if not currentTab then
			selectTab(tab)
		end
		return tab
	end

	---------------- kontrol window ----------------
	local function setCollapsed(v)
		collapsed = v
		minBtn.Text = v and "+" or "-"
		tween(main, { Size = targetSize() }, 0.22)
	end
	minBtn.MouseButton1Click:Connect(function()
		setCollapsed(not collapsed)
	end)
	closeBtn.MouseButton1Click:Connect(function()
		win:Destroy()
	end)

	-- geser lewat header (mouse & layar sentuh)
	do
		local dragging, dragStart, startPos
		header.InputBegan:Connect(function(i)
			if isPress(i) then
				dragging = true
				dragStart = i.Position
				startPos = main.Position
				i.Changed:Connect(function()
					if i.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)
		track(UserInputService.InputChanged:Connect(function(i)
			if dragging and isMove(i) then
				local d = i.Position - dragStart
				main.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + d.X,
					startPos.Y.Scale, startPos.Y.Offset + d.Y
				)
			end
		end))
	end

	-- RightShift: sembunyikan / tampilkan (PC)
	track(UserInputService.InputBegan:Connect(function(i, processed)
		if not processed and i.KeyCode == Enum.KeyCode.RightShift then
			main.Visible = not main.Visible
		end
	end))

	-- animasi muncul
	main.Size = UDim2.fromOffset(W * currentScale * 0.94, H * currentScale * 0.94)
	tween(main, { Size = targetSize() }, 0.25)

	return win
end

local Library = { Window = createWindow }
genv.LeonHubLib = Library

---------------------------------------------------------------------
-- SHELL: Leon4951hub
---------------------------------------------------------------------
local Hub = Library.Window({ Title = "Leon4951hub" })
genv.LeonHub = Hub

-- HOME
local home = Hub:AddTab({ Name = "Home" })
home:AddSection("Leon4951hub")
home:AddParagraph({
	Title = "Selamat datang",
	Content = "UI standalone: latar hitam, outline biru. Pilih tab di sebelah kiri. Kolom Search memfilter isi tab yang sedang dibuka.",
})
home:AddParagraph({
	Title = "Kontrol",
	Content = "Geser lewat header. Tombol '-' menciutkan, 'x' menutup. RightShift menyembunyikan / menampilkan (PC).",
})

-- PERFORMANCE (terhubung ke FPS Boost di script.lua)
local perf = Hub:AddTab({ Name = "Performance" })
perf:AddSection("FPS Boost")
local perfStatus = perf:AddParagraph({
	Title = "Status",
	Content = genv.FPSBoost and "Siap. Tekan tombol di bawah." or "script.lua (FPS Boost) belum dijalankan. Jalankan dulu, lalu tombol di bawah aktif.",
})
local running = false
perf:AddButton({
	Title = "Jalankan FPS Boost",
	Content = "Startup Boost + Boost FPS + Uncap FPS (sekitar 5 detik), lalu otomatis nonaktif.",
	ButtonText = "Jalankan",
	Callback = function()
		local fp = genv.FPSBoost
		if not (fp and fp.Run) then
			Hub:Notify("Jalankan script.lua (FPS Boost) dulu")
			return
		end
		if running then
			Hub:Notify("Masih berjalan...")
			return
		end
		running = true
		perfStatus:Set(nil, "Memproses...")
		local dt = fp.Run()
		running = false
		if dt then
			perfStatus:Set(nil, string.format("Selesai (%.1f dtk). Hasil optimasi tetap bertahan.", dt))
			Hub:Notify(string.format("FPS Boost selesai (%.1f dtk)", dt))
		else
			perfStatus:Set(nil, "Dibatalkan.")
		end
	end,
})
perf:AddButton({
	Title = "Kembalikan grafis",
	Content = "Mengembalikan grafis & cap FPS. Objek yang sudah dihapus baru kembali setelah rejoin.",
	ButtonText = "Restore",
	Callback = function()
		local fp = genv.FPSBoost
		if not (fp and fp.Restore) then
			Hub:Notify("Jalankan script.lua (FPS Boost) dulu")
			return
		end
		fp.Restore()
		perfStatus:Set(nil, "Grafis dikembalikan.")
		Hub:Notify("Grafis dikembalikan")
	end,
})
perf:AddToggle({
	Title = "Uncap FPS",
	Content = "ON = batas 240 FPS, OFF = 60 FPS.",
	Default = false,
	Callback = function(v)
		local fp = genv.FPSBoost
		if fp and fp.UncapFps then
			fp.UncapFps(v)
		else
			Hub:Notify("Jalankan script.lua (FPS Boost) dulu")
		end
	end,
})

-- COMPONENTS (contoh semua komponen)
local demo = Hub:AddTab({ Name = "Components" })
demo:AddSection("Contoh komponen")
demo:AddToggle({
	Title = "Toggle",
	Content = "Contoh toggle ON / OFF.",
	Default = false,
	Callback = function(v) Hub:Notify("Toggle: " .. tostring(v), 1.5) end,
})
demo:AddButton({
	Title = "Button",
	Content = "Contoh tombol.",
	ButtonText = "Klik",
	Callback = function() Hub:Notify("Tombol ditekan", 1.5) end,
})
demo:AddSlider({
	Title = "Slider",
	Content = "Geser untuk mengubah nilai.",
	Min = 0, Max = 100, Step = 5, Default = 50,
	Callback = function(v) print("[Leon4951hub] slider =", v) end,
})
demo:AddDropdown({
	Title = "Dropdown",
	Content = "Pilih satu opsi.",
	Options = { "Satu", "Dua", "Tiga" },
	Default = "Satu",
	Callback = function(v) Hub:Notify("Dipilih: " .. tostring(v), 1.5) end,
})
demo:AddDropdown({
	Title = "Dropdown (multi)",
	Content = "Pilih beberapa opsi.",
	Options = { "Merah", "Hijau", "Biru", "Kuning" },
	Multi = true,
	Default = { "Biru" },
	Callback = function(v) print("[Leon4951hub] multi =", table.concat(v, ", ")) end,
})
demo:AddInput({
	Title = "Input",
	Content = "Ketik lalu tekan Enter / klik di luar.",
	Placeholder = "Ketik di sini...",
	Callback = function(text) Hub:Notify("Input: " .. tostring(text), 1.5) end,
})

print("[Leon4951hub] siap")
