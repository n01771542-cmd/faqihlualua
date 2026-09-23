-- ============================================================================
-- LEON4951 HUB - ANTI HIT
-- PREMIUM UI + MINIMIZE/MORPH ANIMATION + DRAG SYSTEM
--
-- UPDATE:
-- Toggle setelah minimize sekarang bergerak lebih dekat ke bagian paling atas.
-- Posisi toggle: 15px dari atas layar.
-- UI/fitur lainnya tetap dipertahankan.
-- ============================================================================

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- ============================================================================
-- TARGET SAFE ZONE
-- ============================================================================

local TARGET_POS = Vector3.new(491, 70, -371)

-- ============================================================================
-- CLEANUP
-- ============================================================================

local GUI_NAME = "LeonHubGui"

pcall(function()
	local oldCore = CoreGui:FindFirstChild(GUI_NAME)
	if oldCore then
		oldCore:Destroy()
	end
end)

pcall(function()
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if playerGui then
		local oldPlayer = playerGui:FindFirstChild(GUI_NAME)
		if oldPlayer then
			oldPlayer:Destroy()
		end
	end
end)

-- ============================================================================
-- STATE
-- ============================================================================

local isAntiHitActive = false
local isProcessing = false

local IsMinimized = false
local IsTransitioning = false

-- ============================================================================
-- THEME
-- ============================================================================

local Theme = {
	Background = Color3.fromRGB(7, 10, 17),
	Background2 = Color3.fromRGB(10, 14, 23),

	Card = Color3.fromRGB(14, 20, 32),
	CardHover = Color3.fromRGB(20, 29, 46),

	Accent = Color3.fromRGB(37, 120, 255),
	AccentLight = Color3.fromRGB(82, 151, 255),

	Text = Color3.fromRGB(245, 247, 255),
	TextSecondary = Color3.fromRGB(151, 163, 186),
	TextMuted = Color3.fromRGB(88, 100, 123),

	Border = Color3.fromRGB(34, 48, 73),

	Off = Color3.fromRGB(20, 27, 40),
	OffStroke = Color3.fromRGB(50, 64, 88),

	On = Color3.fromRGB(18, 48, 43),
	OnStroke = Color3.fromRGB(46, 146, 116),

	OnAccent = Color3.fromRGB(76, 220, 163),
}

-- ============================================================================
-- TWEEN HELPER
-- ============================================================================

local function Tween(object, duration, properties, style, direction)
	if not object or not object.Parent then
		return
	end

	local info = TweenInfo.new(
		duration or 0.2,
		style or Enum.EasingStyle.Quart,
		direction or Enum.EasingDirection.Out
	)

	local tween = TweenService:Create(object, info, properties)
	tween:Play()

	return tween
end

-- ============================================================================
-- SCREEN GUI
-- ============================================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999

local guiParented = false

pcall(function()
	ScreenGui.Parent = CoreGui
	guiParented = ScreenGui.Parent ~= nil
end)

if not guiParented then
	pcall(function()
		ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
		guiParented = ScreenGui.Parent ~= nil
	end)
end

if not guiParented then
	return
end

-- ============================================================================
-- MAIN UI CONFIG
-- ============================================================================

local MAIN_WIDTH = 350
local MAIN_HEIGHT = 190

local MAIN_HOME_POSITION = UDim2.fromScale(0.20, 0.43)

-- ============================================================================
-- MAIN FRAME
-- ============================================================================

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.fromOffset(MAIN_WIDTH, MAIN_HEIGHT)
MainFrame.Position = MAIN_HOME_POSITION
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 20)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Name = "MainStroke"
MainStroke.Color = Theme.Border
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.08
MainStroke.Parent = MainFrame

-- ============================================================================
-- BACKGROUND GRADIENT
-- ============================================================================

local BackgroundGradient = Instance.new("UIGradient")
BackgroundGradient.Rotation = 135
BackgroundGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(9, 13, 22)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(8, 12, 20)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 20, 34))
})
BackgroundGradient.Parent = MainFrame

-- ============================================================================
-- SOFT TOP ACCENT
-- ============================================================================

local TopAccent = Instance.new("Frame")
TopAccent.Name = "TopAccent"
TopAccent.Size = UDim2.new(0, 90, 0, 3)
TopAccent.Position = UDim2.new(0.5, -45, 0, 0)
TopAccent.BackgroundColor3 = Theme.Accent
TopAccent.BorderSizePixel = 0
TopAccent.ZIndex = 5
TopAccent.Parent = MainFrame

local TopAccentCorner = Instance.new("UICorner")
TopAccentCorner.CornerRadius = UDim.new(1, 0)
TopAccentCorner.Parent = TopAccent

-- ============================================================================
-- HEADER
-- ============================================================================

local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 67)
Header.BackgroundTransparency = 1
Header.Active = true
Header.ZIndex = 10
Header.Parent = MainFrame

-- ============================================================================
-- CUSTOM F LOGO
-- ============================================================================

local LogoHolder = Instance.new("Frame")
LogoHolder.Name = "LogoHolder"
LogoHolder.Size = UDim2.fromOffset(42, 42)
LogoHolder.Position = UDim2.fromOffset(15, 12)
LogoHolder.BackgroundColor3 = Color3.fromRGB(10, 18, 32)
LogoHolder.BorderSizePixel = 0
LogoHolder.ZIndex = 11
LogoHolder.Parent = Header

local LogoCorner = Instance.new("UICorner")
LogoCorner.CornerRadius = UDim.new(0, 12)
LogoCorner.Parent = LogoHolder

local LogoStroke = Instance.new("UIStroke")
LogoStroke.Color = Theme.Accent
LogoStroke.Thickness = 1
LogoStroke.Transparency = 0.35
LogoStroke.Parent = LogoHolder

local FVertical = Instance.new("Frame")
FVertical.Size = UDim2.fromOffset(7, 27)
FVertical.Position = UDim2.fromOffset(12, 8)
FVertical.BackgroundColor3 = Theme.Accent
FVertical.BorderSizePixel = 0
FVertical.Rotation = -7
FVertical.ZIndex = 12
FVertical.Parent = LogoHolder

local FTop = Instance.new("Frame")
FTop.Size = UDim2.fromOffset(20, 7)
FTop.Position = UDim2.fromOffset(16, 7)
FTop.BackgroundColor3 = Theme.Accent
FTop.BorderSizePixel = 0
FTop.Rotation = -7
FTop.ZIndex = 12
FTop.Parent = LogoHolder

local FMiddle = Instance.new("Frame")
FMiddle.Size = UDim2.fromOffset(15, 6)
FMiddle.Position = UDim2.fromOffset(15, 18)
FMiddle.BackgroundColor3 = Theme.AccentLight
FMiddle.BorderSizePixel = 0
FMiddle.Rotation = -7
FMiddle.ZIndex = 12
FMiddle.Parent = LogoHolder

-- ============================================================================
-- TITLE
-- ============================================================================

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -125, 0, 24)
Title.Position = UDim2.fromOffset(69, 11)
Title.BackgroundTransparency = 1
Title.RichText = true
Title.Text = 'leon4951 <font color="rgb(65,135,255)">Hub</font>'
Title.TextColor3 = Theme.Text
Title.Font = Enum.Font.GothamBold
Title.TextSize = 17
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextYAlignment = Enum.TextYAlignment.Center
Title.ZIndex = 11
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Name = "Subtitle"
Subtitle.Size = UDim2.new(1, -125, 0, 16)
Subtitle.Position = UDim2.fromOffset(70, 35)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "ANTI HIT"
Subtitle.TextColor3 = Theme.TextMuted
Subtitle.Font = Enum.Font.GothamMedium
Subtitle.TextSize = 8
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.ZIndex = 11
Subtitle.Parent = Header

-- ============================================================================
-- MINUS BUTTON
-- ============================================================================

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Size = UDim2.fromOffset(38, 38)
MinimizeButton.Position = UDim2.new(1, -51, 0, 12)
MinimizeButton.BackgroundColor3 = Theme.Card
MinimizeButton.BorderSizePixel = 0
MinimizeButton.Text = "−"
MinimizeButton.TextColor3 = Theme.TextSecondary
MinimizeButton.Font = Enum.Font.GothamMedium
MinimizeButton.TextSize = 20
MinimizeButton.AutoButtonColor = false
MinimizeButton.ZIndex = 12
MinimizeButton.Parent = Header

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 12)
MinCorner.Parent = MinimizeButton

local MinStroke = Instance.new("UIStroke")
MinStroke.Color = Theme.Border
MinStroke.Thickness = 1
MinStroke.Transparency = 0.25
MinStroke.Parent = MinimizeButton

-- ============================================================================
-- CONTENT AREA
-- ============================================================================

local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -30, 0, 102)
Content.Position = UDim2.fromOffset(15, 72)
Content.BackgroundTransparency = 1
Content.ZIndex = 5
Content.Parent = MainFrame

local FeatureLabel = Instance.new("TextLabel")
FeatureLabel.Size = UDim2.new(1, 0, 0, 18)
FeatureLabel.Position = UDim2.fromOffset(2, 0)
FeatureLabel.BackgroundTransparency = 1
FeatureLabel.Text = "PROTECTION"
FeatureLabel.TextColor3 = Theme.TextMuted
FeatureLabel.Font = Enum.Font.GothamMedium
FeatureLabel.TextSize = 8
FeatureLabel.TextXAlignment = Enum.TextXAlignment.Left
FeatureLabel.ZIndex = 6
FeatureLabel.Parent = Content

-- ============================================================================
-- ANTI HIT BUTTON
-- ============================================================================

local AntiHitButton = Instance.new("TextButton")
AntiHitButton.Name = "AntiHitButton"
AntiHitButton.Size = UDim2.new(1, 0, 0, 65)
AntiHitButton.Position = UDim2.fromOffset(0, 22)
AntiHitButton.BackgroundColor3 = Theme.Off
AntiHitButton.BorderSizePixel = 0
AntiHitButton.AutoButtonColor = false
AntiHitButton.Text = ""
AntiHitButton.ZIndex = 7
AntiHitButton.Parent = Content

local AntiHitCorner = Instance.new("UICorner")
AntiHitCorner.CornerRadius = UDim.new(0, 15)
AntiHitCorner.Parent = AntiHitButton

local AntiHitStroke = Instance.new("UIStroke")
AntiHitStroke.Name = "AntiHitStroke"
AntiHitStroke.Color = Theme.OffStroke
AntiHitStroke.Thickness = 1
AntiHitStroke.Transparency = 0.2
AntiHitStroke.Parent = AntiHitButton

local ButtonGradient = Instance.new("UIGradient")
ButtonGradient.Rotation = 90
ButtonGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(21, 29, 43)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 21, 32))
})
ButtonGradient.Parent = AntiHitButton

-- ============================================================================
-- STATUS DOT
-- ============================================================================

local StatusDot = Instance.new("Frame")
StatusDot.Name = "StatusDot"
StatusDot.Size = UDim2.fromOffset(8, 8)
StatusDot.Position = UDim2.fromOffset(18, 28)
StatusDot.BackgroundColor3 = Color3.fromRGB(100, 111, 130)
StatusDot.BorderSizePixel = 0
StatusDot.ZIndex = 9
StatusDot.Parent = AntiHitButton

local StatusDotCorner = Instance.new("UICorner")
StatusDotCorner.CornerRadius = UDim.new(1, 0)
StatusDotCorner.Parent = StatusDot

-- ============================================================================
-- STATUS TEXT
-- ============================================================================

local AntiHitTitle = Instance.new("TextLabel")
AntiHitTitle.Size = UDim2.new(1, -100, 0, 21)
AntiHitTitle.Position = UDim2.fromOffset(40, 12)
AntiHitTitle.BackgroundTransparency = 1
AntiHitTitle.Text = "ANTI HIT"
AntiHitTitle.TextColor3 = Theme.Text
AntiHitTitle.Font = Enum.Font.GothamBold
AntiHitTitle.TextSize = 13
AntiHitTitle.TextXAlignment = Enum.TextXAlignment.Left
AntiHitTitle.ZIndex = 9
AntiHitTitle.Parent = AntiHitButton

local AntiHitSub = Instance.new("TextLabel")
AntiHitSub.Size = UDim2.new(1, -100, 0, 16)
AntiHitSub.Position = UDim2.fromOffset(40, 33)
AntiHitSub.BackgroundTransparency = 1
AntiHitSub.Text = "Protection disabled"
AntiHitSub.TextColor3 = Theme.TextMuted
AntiHitSub.Font = Enum.Font.GothamMedium
AntiHitSub.TextSize = 8
AntiHitSub.TextXAlignment = Enum.TextXAlignment.Left
AntiHitSub.ZIndex = 9
AntiHitSub.Parent = AntiHitButton

-- ============================================================================
-- ON / OFF INDICATOR
-- ============================================================================

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.fromOffset(55, 20)
StatusText.Position = UDim2.new(1, -72, 0, 22)
StatusText.BackgroundTransparency = 1
StatusText.Text = "OFF"
StatusText.TextColor3 = Theme.TextMuted
StatusText.Font = Enum.Font.GothamBold
StatusText.TextSize = 9
StatusText.TextXAlignment = Enum.TextXAlignment.Right
StatusText.ZIndex = 9
StatusText.Parent = AntiHitButton

-- ============================================================================
-- HOVER
-- ============================================================================

AntiHitButton.MouseEnter:Connect(function()
	if IsTransitioning then
		return
	end

	Tween(
		AntiHitButton,
		0.16,
		{
			BackgroundColor3 = isAntiHitActive
				and Color3.fromRGB(22, 58, 51)
				or Theme.CardHover
		},
		Enum.EasingStyle.Quart
	)

	Tween(
		AntiHitStroke,
		0.16,
		{
			Transparency = 0,
			Color = isAntiHitActive
				and Theme.OnStroke
				or Theme.Accent
		}
	)
end)

AntiHitButton.MouseLeave:Connect(function()
	if isAntiHitActive then
		Tween(AntiHitButton, 0.18, {
			BackgroundColor3 = Theme.On
		})

		Tween(AntiHitStroke, 0.18, {
			Color = Theme.OnStroke,
			Transparency = 0.15
		})
	else
		Tween(AntiHitButton, 0.18, {
			BackgroundColor3 = Theme.Off
		})

		Tween(AntiHitStroke, 0.18, {
			Color = Theme.OffStroke,
			Transparency = 0.2
		})
	end
end)

-- ============================================================================
-- TOGGLE BUTTON
-- ============================================================================

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "MinimizedToggle"
ToggleButton.Size = UDim2.fromOffset(245, 50)
ToggleButton.Position = UDim2.fromScale(0.5, 0.5)
ToggleButton.AnchorPoint = Vector2.new(0.5, 0.5)
ToggleButton.BackgroundColor3 = Theme.Background
ToggleButton.BorderSizePixel = 0
ToggleButton.Text = ""
ToggleButton.Visible = false
ToggleButton.AutoButtonColor = false
ToggleButton.Active = true
ToggleButton.ZIndex = 500
ToggleButton.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 18)
ToggleCorner.Parent = ToggleButton

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Theme.Border
ToggleStroke.Thickness = 1.5
ToggleStroke.Transparency = 0.05
ToggleStroke.Parent = ToggleButton

local ToggleGradient = Instance.new("UIGradient")
ToggleGradient.Rotation = 90
ToggleGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(11, 16, 26)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 9, 15))
})
ToggleGradient.Parent = ToggleButton

-- ============================================================================
-- TOGGLE LOGO
-- ============================================================================

local ToggleLogo = Instance.new("Frame")
ToggleLogo.Name = "ToggleLogo"
ToggleLogo.Size = UDim2.fromOffset(34, 34)
ToggleLogo.Position = UDim2.fromOffset(8, 8)
ToggleLogo.BackgroundColor3 = Color3.fromRGB(10, 18, 32)
ToggleLogo.BorderSizePixel = 0
ToggleLogo.ZIndex = 501
ToggleLogo.Parent = ToggleButton

local ToggleLogoCorner = Instance.new("UICorner")
ToggleLogoCorner.CornerRadius = UDim.new(0, 10)
ToggleLogoCorner.Parent = ToggleLogo

local ToggleLogoStroke = Instance.new("UIStroke")
ToggleLogoStroke.Color = Theme.Accent
ToggleLogoStroke.Thickness = 1
ToggleLogoStroke.Transparency = 0.35
ToggleLogoStroke.Parent = ToggleLogo

local ToggleFVertical = Instance.new("Frame")
ToggleFVertical.Size = UDim2.fromOffset(6, 22)
ToggleFVertical.Position = UDim2.fromOffset(9, 6)
ToggleFVertical.BackgroundColor3 = Theme.Accent
ToggleFVertical.BorderSizePixel = 0
ToggleFVertical.Rotation = -7
ToggleFVertical.ZIndex = 502
ToggleFVertical.Parent = ToggleLogo

local ToggleFTop = Instance.new("Frame")
ToggleFTop.Size = UDim2.fromOffset(17, 6)
ToggleFTop.Position = UDim2.fromOffset(13, 5)
ToggleFTop.BackgroundColor3 = Theme.Accent
ToggleFTop.BorderSizePixel = 0
ToggleFTop.Rotation = -7
ToggleFTop.ZIndex = 502
ToggleFTop.Parent = ToggleLogo

local ToggleFMiddle = Instance.new("Frame")
ToggleFMiddle.Size = UDim2.fromOffset(13, 5)
ToggleFMiddle.Position = UDim2.fromOffset(12, 14)
ToggleFMiddle.BackgroundColor3 = Theme.AccentLight
ToggleFMiddle.BorderSizePixel = 0
ToggleFMiddle.Rotation = -7
ToggleFMiddle.ZIndex = 502
ToggleFMiddle.Parent = ToggleLogo

-- ============================================================================
-- TOGGLE TITLE
-- ============================================================================

local ToggleTitle = Instance.new("TextLabel")
ToggleTitle.Size = UDim2.new(1, -65, 0, 22)
ToggleTitle.Position = UDim2.fromOffset(51, 8)
ToggleTitle.BackgroundTransparency = 1
ToggleTitle.RichText = true
ToggleTitle.Text = 'leon4951 <font color="rgb(65,135,255)">Hub</font>'
ToggleTitle.TextColor3 = Theme.Text
ToggleTitle.Font = Enum.Font.GothamBold
ToggleTitle.TextSize = 13
ToggleTitle.TextXAlignment = Enum.TextXAlignment.Left
ToggleTitle.ZIndex = 501
ToggleTitle.Parent = ToggleButton

local ToggleSubtitle = Instance.new("TextLabel")
ToggleSubtitle.Size = UDim2.new(1, -65, 0, 13)
ToggleSubtitle.Position = UDim2.fromOffset(52, 29)
ToggleSubtitle.BackgroundTransparency = 1
ToggleSubtitle.Text = "ANTI HIT"
ToggleSubtitle.TextColor3 = Theme.TextMuted
ToggleSubtitle.Font = Enum.Font.GothamMedium
ToggleSubtitle.TextSize = 7
ToggleSubtitle.TextXAlignment = Enum.TextXAlignment.Left
ToggleSubtitle.ZIndex = 501
ToggleSubtitle.Parent = ToggleButton

-- ============================================================================
-- MAIN UI DRAG
-- ============================================================================

local MainDragging = false
local MainDragStart = nil
local MainStartPosition = nil
local MainDragInput = nil

Header.InputBegan:Connect(function(input)
	if IsTransitioning then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		MainDragging = true
		MainDragStart = input.Position
		MainStartPosition = MainFrame.Position
		MainDragInput = input
	end
end)

Header.InputEnded:Connect(function(input)
	if input == MainDragInput then
		MainDragging = false
		MainDragInput = nil
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not MainDragging then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then

		if not MainDragStart or not MainStartPosition then
			return
		end

		local delta = input.Position - MainDragStart

		MainFrame.Position = UDim2.new(
			MainStartPosition.X.Scale,
			MainStartPosition.X.Offset + delta.X,
			MainStartPosition.Y.Scale,
			MainStartPosition.Y.Offset + delta.Y
		)
	end
end)

-- ============================================================================
-- TOGGLE DRAG
-- ============================================================================

local ToggleDragging = false
local ToggleDragStart = nil
local ToggleStartPosition = nil
local ToggleMoved = false

ToggleButton.InputBegan:Connect(function(input)
	if IsTransitioning then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		ToggleDragging = true
		ToggleMoved = false
		ToggleDragStart = input.Position
		ToggleStartPosition = ToggleButton.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not ToggleDragging then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then

		if not ToggleDragStart or not ToggleStartPosition then
			return
		end

		local delta = input.Position - ToggleDragStart

		if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then
			ToggleMoved = true
		end

		ToggleButton.Position = UDim2.new(
			ToggleStartPosition.X.Scale,
			ToggleStartPosition.X.Offset + delta.X,
			ToggleStartPosition.Y.Scale,
			ToggleStartPosition.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		ToggleDragging = false
	end
end)

-- ============================================================================
-- TOGGLE HOVER
-- ============================================================================

ToggleButton.MouseEnter:Connect(function()
	if ToggleDragging or IsTransitioning then
		return
	end

	Tween(
		ToggleButton,
		0.15,
		{
			Size = UDim2.fromOffset(252, 52)
		},
		Enum.EasingStyle.Quart
	)

	Tween(
		ToggleStroke,
		0.15,
		{
			Color = Theme.Accent,
			Transparency = 0
		}
	)
end)

ToggleButton.MouseLeave:Connect(function()
	if ToggleDragging then
		return
	end

	Tween(
		ToggleButton,
		0.15,
		{
			Size = UDim2.fromOffset(245, 50)
		},
		Enum.EasingStyle.Quart
	)

	Tween(
		ToggleStroke,
		0.15,
		{
			Color = Theme.Border,
			Transparency = 0.05
		}
	)
end)

-- ============================================================================
-- VIEWPORT CENTER
-- ============================================================================

local function GetViewport()
	local camera = workspace.CurrentCamera

	if camera then
		return camera.ViewportSize
	end

	return Vector2.new(1920, 1080)
end

local function GetCenterPosition()
	local viewport = GetViewport()

	return UDim2.fromOffset(
		viewport.X * 0.5,
		viewport.Y * 0.5
	)
end

-- ============================================================================
-- TOP TOGGLE POSITION
-- ============================================================================
-- DIUBAH:
-- sebelumnya 38px dari atas
-- sekarang 15px dari atas
-- ============================================================================

local function GetTopTogglePosition()
	local viewport = GetViewport()

	return UDim2.fromOffset(
		viewport.X * 0.5,
		-5
	)
end

-- ============================================================================
-- MINIMIZE ANIMATION
-- ============================================================================

local function MinimizeUI()
	if IsTransitioning or IsMinimized then
		return
	end

	IsTransitioning = true
	IsMinimized = true

	MinimizeButton.Active = false
	AntiHitButton.Active = false

	local centerPosition = GetCenterPosition()

	-- STEP 1:
	-- Main UI bergerak ke tengah
	Tween(
		MainFrame,
		0.45,
		{
			Position = centerPosition
		},
		Enum.EasingStyle.Quart,
		Enum.EasingDirection.InOut
	)

	task.wait(0.47)

	-- STEP 2:
	-- Pause di tengah
	task.wait(0.30)

	-- STEP 3:
	-- Main UI mengecil menjadi bentuk toggle
	Tween(
		MainFrame,
		0.40,
		{
			Size = UDim2.fromOffset(245, 50)
		},
		Enum.EasingStyle.Quart,
		Enum.EasingDirection.InOut
	)

	task.wait(0.42)

	-- STEP 4:
	-- Hide main UI
	MainFrame.Visible = false

	-- STEP 5:
	-- Munculkan toggle tepat di tengah
	ToggleButton.Position = centerPosition
	ToggleButton.Size = UDim2.fromOffset(245, 50)
	ToggleButton.Visible = true

	-- STEP 6:
	-- Toggle bergerak ke bagian paling atas
	task.wait(0.05)

	local topPosition = GetTopTogglePosition()

	Tween(
		ToggleButton,
		0.55,
		{
			Position = topPosition
		},
		Enum.EasingStyle.Quart,
		Enum.EasingDirection.Out
	)

	task.wait(0.58)

	ToggleButton.Active = true
	IsTransitioning = false
end

-- ============================================================================
-- RESTORE ANIMATION
-- ============================================================================

local function RestoreUI()
	if IsTransitioning or not IsMinimized then
		return
	end

	IsTransitioning = true

	ToggleButton.Active = false

	local centerPosition = GetCenterPosition()

	-- STEP 1:
	-- Toggle turun ke tengah
	Tween(
		ToggleButton,
		0.55,
		{
			Position = centerPosition
		},
		Enum.EasingStyle.Quart,
		Enum.EasingDirection.InOut
	)

	task.wait(0.58)

	-- STEP 2:
	-- Pause di tengah
	task.wait(0.30)

	-- STEP 3:
	-- Hide toggle
	ToggleButton.Visible = false

	-- STEP 4:
	-- Main UI muncul dalam bentuk kecil
	MainFrame.Visible = true
	MainFrame.Position = centerPosition
	MainFrame.Size = UDim2.fromOffset(245, 50)

	-- STEP 5:
	-- Morph menjadi panel
	Tween(
		MainFrame,
		0.45,
		{
			Size = UDim2.fromOffset(MAIN_WIDTH, MAIN_HEIGHT)
		},
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out
	)

	task.wait(0.48)

	-- STEP 6:
	-- Bergerak kembali ke posisi kiri
	Tween(
		MainFrame,
		0.55,
		{
			Position = MAIN_HOME_POSITION
		},
		Enum.EasingStyle.Quart,
		Enum.EasingDirection.Out
	)

	task.wait(0.58)

	IsMinimized = false
	IsTransitioning = false

	MinimizeButton.Active = true
	AntiHitButton.Active = true
end

-- ============================================================================
-- MINUS BUTTON
-- ============================================================================

MinimizeButton.MouseEnter:Connect(function()
	if IsTransitioning then
		return
	end

	Tween(
		MinimizeButton,
		0.15,
		{
			BackgroundColor3 = Theme.CardHover
		}
	)

	Tween(
		MinStroke,
		0.15,
		{
			Color = Theme.Accent,
			Transparency = 0
		}
	)
end)

MinimizeButton.MouseLeave:Connect(function()
	Tween(
		MinimizeButton,
		0.15,
		{
			BackgroundColor3 = Theme.Card
		}
	)

	Tween(
		MinStroke,
		0.15,
		{
			Color = Theme.Border,
			Transparency = 0.25
		}
	)
end)

MinimizeButton.MouseButton1Click:Connect(function()
	MinimizeUI()
end)

-- ============================================================================
-- TOGGLE CLICK
-- ============================================================================

ToggleButton.MouseButton1Click:Connect(function()
	if ToggleMoved then
		ToggleMoved = false
		return
	end

	RestoreUI()
end)

-- ============================================================================
-- ANTI HIT UI STATE
-- ============================================================================

local function UpdateAntiHitUI()
	if isAntiHitActive then

		StatusText.Text = "ON"
		StatusText.TextColor3 = Theme.OnAccent

		AntiHitSub.Text = "Protection enabled"

		StatusDot.BackgroundColor3 = Theme.OnAccent

		Tween(
			AntiHitButton,
			0.22,
			{
				BackgroundColor3 = Theme.On
			},
			Enum.EasingStyle.Quart
		)

		Tween(
			AntiHitStroke,
			0.22,
			{
				Color = Theme.OnStroke,
				Transparency = 0.1
			}
		)

	else

		StatusText.Text = "OFF"
		StatusText.TextColor3 = Theme.TextMuted

		AntiHitSub.Text = "Protection disabled"

		StatusDot.BackgroundColor3 = Color3.fromRGB(100, 111, 130)

		Tween(
			AntiHitButton,
			0.22,
			{
				BackgroundColor3 = Theme.Off
			},
			Enum.EasingStyle.Quart
		)

		Tween(
			AntiHitStroke,
			0.22,
			{
				Color = Theme.OffStroke,
				Transparency = 0.2
			}
		)
	end
end

-- ============================================================================
-- ANTI HIT TOGGLE
-- ============================================================================

AntiHitButton.MouseButton1Click:Connect(function()
	if IsTransitioning then
		return
	end

	isAntiHitActive = not isAntiHitActive

	UpdateAntiHitUI()

	Tween(
		AntiHitButton,
		0.07,
		{
			Size = UDim2.new(1, -4, 0, 63),
			Position = UDim2.fromOffset(2, 23)
		},
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)

	task.delay(0.08, function()
		if AntiHitButton.Parent then
			Tween(
				AntiHitButton,
				0.10,
				{
					Size = UDim2.new(1, 0, 0, 65),
					Position = UDim2.fromOffset(0, 22)
				},
				Enum.EasingStyle.Back,
				Enum.EasingDirection.Out
			)
		end
	end)
end)

-- ============================================================================
-- ANTI HIT LOGIC
-- ============================================================================

local function CreateFakeAndTeleportReal()
	local char = LocalPlayer.Character
	if not char then
		return
	end

	local root = char:FindFirstChild("HumanoidRootPart")
	local realHumanoid = char:FindFirstChildOfClass("Humanoid")

	if not root or not realHumanoid then
		return
	end

	local originalCFrame = root.CFrame

	char.Archivable = true

	local fakeChar = char:Clone()

	char.Archivable = false

	fakeChar.Name = "FakeVisualPlayer"

	for _, part in ipairs(fakeChar:GetDescendants()) do
		if part:IsA("BasePart") then

			part.CanCollide = false
			part.Anchored = true

		elseif part:IsA("Script") or part:IsA("LocalScript") then

			part:Destroy()
		end
	end

	fakeChar.Parent = workspace
	fakeChar:PivotTo(originalCFrame)

	local camera = workspace.CurrentCamera

	local fakeHumanoid = fakeChar:FindFirstChildOfClass("Humanoid")

	if fakeHumanoid and camera then
		camera.CameraSubject = fakeHumanoid
	end

	local targetCFrame = CFrame.new(
		TARGET_POS + Vector3.new(0, 3, 0)
	)

	local startTime = os.clock()

	local holdConnection

	holdConnection = RunService.Heartbeat:Connect(function()

		if not char
			or not root
			or not root.Parent then

			if holdConnection then
				holdConnection:Disconnect()
			end

			return
		end

		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero

		root.CFrame = targetCFrame
		char:PivotTo(targetCFrame)

		if os.clock() - startTime >= 0.5 then
			holdConnection:Disconnect()
		end
	end)

	task.delay(0.5, function()

		if fakeChar then
			fakeChar:Destroy()
		end

		if realHumanoid and camera then
			camera.CameraSubject = realHumanoid
		end
	end)
end

-- ============================================================================
-- EXECUTE ANTI HIT
-- ============================================================================

local function ExecuteDropAndTeleport()

	if isProcessing or not isAntiHitActive then
		return
	end

	isProcessing = true

	task.wait(0.2)

	local char = LocalPlayer.Character

	if char then

		for _, item in ipairs(char:GetChildren()) do

			if item:IsA("Tool") then
				item.Parent = workspace
			end
		end

		CreateFakeAndTeleportReal()
	end

	task.delay(0.8, function()
		isProcessing = false
	end)
end

-- ============================================================================
-- PROXIMITY PROMPT
-- ============================================================================

ProximityPromptService.PromptTriggered:Connect(function(
	prompt,
	playerWhoTriggered
)

	if isAntiHitActive
		and playerWhoTriggered == LocalPlayer then

		task.spawn(function()
			ExecuteDropAndTeleport()
		end)
	end
end)

-- ============================================================================
-- CHARACTER DETECTION
-- ============================================================================

local function SetupCharacterDetection(char)

	char.ChildAdded:Connect(function(child)

		if isAntiHitActive
			and not child:IsA("Tool") then

			local name = string.lower(child.Name)

			if string.find(name, "egg")
				or string.find(name, "telur") then

				task.spawn(function()
					ExecuteDropAndTeleport()
				end)
			end
		end
	end)
end

if LocalPlayer.Character then
	SetupCharacterDetection(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(function(newChar)

	task.wait(0.2)

	SetupCharacterDetection(newChar)
end)

-- ============================================================================
-- INITIAL UI STATE
-- ============================================================================

UpdateAntiHitUI()

-- ============================================================================
-- OPEN ANIMATION
-- ============================================================================

MainFrame.Size = UDim2.fromOffset(30, 30)
MainFrame.BackgroundTransparency = 1

MainStroke.Transparency = 1
TopAccent.BackgroundTransparency = 1

LogoHolder.BackgroundTransparency = 1
LogoStroke.Transparency = 1

Title.TextTransparency = 1
Subtitle.TextTransparency = 1
MinimizeButton.BackgroundTransparency = 1
MinimizeButton.TextTransparency = 1
MinStroke.Transparency = 1

Content.BackgroundTransparency = 1
FeatureLabel.TextTransparency = 1
AntiHitButton.BackgroundTransparency = 1
AntiHitStroke.Transparency = 1
AntiHitTitle.TextTransparency = 1
AntiHitSub.TextTransparency = 1
StatusText.TextTransparency = 1
StatusDot.BackgroundTransparency = 1

Tween(
	MainFrame,
	0.55,
	{
		Size = UDim2.fromOffset(MAIN_WIDTH, MAIN_HEIGHT),
		BackgroundTransparency = 0
	},
	Enum.EasingStyle.Back,
	Enum.EasingDirection.Out
)

task.delay(0.05, function()

	Tween(
		MainStroke,
		0.4,
		{
			Transparency = 0.08
		}
	)

	Tween(
		TopAccent,
		0.4,
		{
			BackgroundTransparency = 0
		}
	)

	Tween(
		LogoHolder,
		0.35,
		{
			BackgroundTransparency = 0
		}
	)

	Tween(
		LogoStroke,
		0.35,
		{
			Transparency = 0.35
		}
	)
end)

task.delay(0.12, function()

	Tween(
		Title,
		0.35,
		{
			TextTransparency = 0
		}
	)

	Tween(
		Subtitle,
		0.35,
		{
			TextTransparency = 0
		}
	)

	Tween(
		MinimizeButton,
		0.35,
		{
			BackgroundTransparency = 0,
			TextTransparency = 0
		}
	)

	Tween(
		MinStroke,
		0.35,
		{
			Transparency = 0.25
		}
	)
end)

task.delay(0.22, function()

	Tween(
		FeatureLabel,
		0.3,
		{
			TextTransparency = 0
		}
	)

	Tween(
		AntiHitButton,
		0.35,
		{
			BackgroundTransparency = 0
		},
		Enum.EasingStyle.Quart
	)

	Tween(
		AntiHitStroke,
		0.35,
		{
			Transparency = 0.2
		}
	)

	Tween(
		AntiHitTitle,
		0.3,
		{
			TextTransparency = 0
		}
	)

	Tween(
		AntiHitSub,
		0.3,
		{
			TextTransparency = 0
		}
	)

	Tween(
		StatusText,
		0.3,
		{
			TextTransparency = 0
		}
	)

	Tween(
		StatusDot,
		0.3,
		{
			BackgroundTransparency = 0
		}
	)
end)