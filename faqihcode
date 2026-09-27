local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- Koordinat Target Safe Zone
local TARGET_POS = Vector3.new(527.05, 71.68, -368.57)

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

--------------------------------------------------------------------------------
-- INFINITE BLOCK GENERATOR & FLY SYSTEM
--------------------------------------------------------------------------------
local isFlyActive = false
local MOVE_SPEED = 60
local BLOCK_OFFSET_Y = 3.5
local activeBlock = nil

local function UpdateOrCreateBlock(position)
	if not activeBlock or not activeBlock.Parent then
		local block = Instance.new("Part")
		block.Name = "MovingDynamicBlock"
		block.Size = Vector3.new(6, 1, 6)
		block.Transparency = 1
		block.CanCollide = true
		block.Anchored = true
		block.Material = Enum.Material.SmoothPlastic
		block.Parent = workspace
		activeBlock = block
	end

	activeBlock.CFrame = CFrame.new(position)
	return activeBlock
end

local function RemoveBlock()
	if activeBlock and activeBlock.Parent then
		activeBlock:Destroy()
		activeBlock = nil
	end
end

local function ApplyFakeDeathState(character)
	if not character then return end

	local humanoid = character:WaitForChild("Humanoid", 5)
	local root = character:WaitForChild("HumanoidRootPart", 5)
	if not humanoid or not root then return end

	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
	humanoid.PlatformStand = isFlyActive

	humanoid.Health = humanoid.MaxHealth
	humanoid:GetPropertyChangedSignal("Health"):Connect(function()
		if humanoid.Health < humanoid.MaxHealth then
			humanoid.Health = humanoid.MaxHealth
		end
	end)

	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanTouch = true
			part.Touched:Connect(function(hit)
				if hit and hit.Parent then
					local lowerName = string.lower(hit.Name)
					local lowerParent = string.lower(hit.Parent.Name)
					
					if string.find(lowerName, "kill") or string.find(lowerName, "lava") or string.find(lowerName, "void") or string.find(lowerName, "anticheat") or string.find(lowerParent, "anticheat") then
						hit.CanTouch = false
					end
				end
			end)
		end
	end
end

-- METATABLE BYPASS
if getrawmetatable and setreadonly then
	local gmt = getrawmetatable(game)
	local oldNamecall = gmt.__namecall
	setreadonly(gmt, false)

	gmt.__namecall = newcclosure(function(self, ...)
		local method = getnamecallmethod()

		if method == "Kick" or method == "kick" then
			return nil
		end

		if method == "FireServer" or method == "InvokeServer" then
			local name = string.lower(tostring(self.Name))
			if string.find(name, "anticheat") or string.find(name, "ban") or string.find(name, "detect") or string.find(name, "check") or string.find(name, "flag") or string.find(name, "died") or string.find(name, "kill") then
				return nil
			end
		end

		return oldNamecall(self, ...)
	end)

	setreadonly(gmt, true)
end

-- RUNSERVICE FLY
RunService.Heartbeat:Connect(function(deltaTime)
	if not isFlyActive then 
		RemoveBlock()
		return 
	end

	local char = LocalPlayer.Character
	if not char then return end

	local root = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	local camera = workspace.CurrentCamera

	if root and hum and camera then
		hum.PlatformStand = true

		local moveDir = Vector3.zero

		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			moveDir = moveDir + Vector3.new(0, 0, -1)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			moveDir = moveDir + Vector3.new(0, 0, 1)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			moveDir = moveDir + Vector3.new(-1, 0, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			moveDir = moveDir + Vector3.new(1, 0, 0)
		end

		if moveDir.Magnitude == 0 and hum.MoveDirection.Magnitude > 0 then
			local localMove = camera.CFrame:VectorToObjectSpace(hum.MoveDirection)
			moveDir = Vector3.new(localMove.X, 0, localMove.Z)
		end

		local verticalMove = 0
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			verticalMove = verticalMove + 1
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			verticalMove = verticalMove - 1
		end

		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero

		if moveDir.Magnitude > 0 or verticalMove ~= 0 then
			if moveDir.Magnitude > 0 then
				moveDir = moveDir.Unit
			end

			local camCFrame = camera.CFrame
			local worldDirection = (camCFrame.RightVector * moveDir.X) 
			                      + (camCFrame.LookVector * -moveDir.Z) 
			                      + (Vector3.new(0, 1, 0) * verticalMove)

			if worldDirection.Magnitude > 0 then
				worldDirection = worldDirection.Unit
			end

			local targetPos = root.Position + (worldDirection * (MOVE_SPEED * deltaTime))
			local lookAtPos = targetPos + Vector3.new(camCFrame.LookVector.X, 0, camCFrame.LookVector.Z)
			
			root.CFrame = CFrame.new(targetPos, lookAtPos)
			UpdateOrCreateBlock(targetPos - Vector3.new(0, BLOCK_OFFSET_Y, 0))
		else
			UpdateOrCreateBlock(root.Position - Vector3.new(0, BLOCK_OFFSET_Y, 0))
		end
	end
end)

if LocalPlayer.Character then
	task.spawn(function()
		ApplyFakeDeathState(LocalPlayer.Character)
	end)
end

LocalPlayer.CharacterAdded:Connect(function(newChar)
	task.wait(0.2)
	ApplyFakeDeathState(newChar)
end)

--------------------------------------------------------------------------------
-- MAIN UI SETUP & LOGIC
--------------------------------------------------------------------------------
local isAntiHitActive = false
local isProcessing = false
local IsMinimized = false
local IsTransitioning = false

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

local function Tween(object, duration, properties, style, direction)
	if not object or not object.Parent then return end

	local info = TweenInfo.new(
		duration or 0.2,
		style or Enum.EasingStyle.Quart,
		direction or Enum.EasingDirection.Out
	)

	local tween = TweenService:Create(object, info, properties)
	tween:Play()

	return tween
end

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

if not guiParented then return end

local MAIN_WIDTH = 350
local MAIN_HEIGHT = 335
local MAIN_HOME_POSITION = UDim2.fromScale(0.20, 0.43)

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

local BackgroundGradient = Instance.new("UIGradient")
BackgroundGradient.Rotation = 135
BackgroundGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(9, 13, 22)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(8, 12, 20)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 20, 34))
})
BackgroundGradient.Parent = MainFrame

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

local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 67)
Header.BackgroundTransparency = 1
Header.Active = true
Header.ZIndex = 10
Header.Parent = MainFrame

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
Subtitle.Text = "MAIN UTILITIES"
Subtitle.TextColor3 = Theme.TextMuted
Subtitle.Font = Enum.Font.GothamMedium
Subtitle.TextSize = 8
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.ZIndex = 11
Subtitle.Parent = Header

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

local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -30, 0, 250)
Content.Position = UDim2.fromOffset(15, 68)
Content.BackgroundTransparency = 1
Content.ZIndex = 5
Content.Parent = MainFrame

local FeatureLabel = Instance.new("TextLabel")
FeatureLabel.Size = UDim2.new(1, 0, 0, 16)
FeatureLabel.Position = UDim2.fromOffset(2, 0)
FeatureLabel.BackgroundTransparency = 1
FeatureLabel.Text = "FEATURES"
FeatureLabel.TextColor3 = Theme.TextMuted
FeatureLabel.Font = Enum.Font.GothamMedium
FeatureLabel.TextSize = 8
FeatureLabel.TextXAlignment = Enum.TextXAlignment.Left
FeatureLabel.ZIndex = 6
FeatureLabel.Parent = Content

--------------------------------------------------------------------------------
-- ANTI HIT GUARDS BUTTON (POSITION: TOP)
--------------------------------------------------------------------------------
local AntiHitButton = Instance.new("TextButton")
AntiHitButton.Name = "AntiHitButton"
AntiHitButton.Size = UDim2.new(1, 0, 0, 60)
AntiHitButton.Position = UDim2.fromOffset(0, 20)
AntiHitButton.BackgroundColor3 = Theme.Off
AntiHitButton.BorderSizePixel = 0
AntiHitButton.AutoButtonColor = false
AntiHitButton.Text = ""
AntiHitButton.ZIndex = 7
AntiHitButton.Parent = Content

local AntiHitCorner = Instance.new("UICorner")
AntiHitCorner.CornerRadius = UDim.new(0, 14)
AntiHitCorner.Parent = AntiHitButton

local AntiHitStroke = Instance.new("UIStroke")
AntiHitStroke.Name = "AntiHitStroke"
AntiHitStroke.Color = Theme.OffStroke
AntiHitStroke.Thickness = 1
AntiHitStroke.Transparency = 0.2
AntiHitStroke.Parent = AntiHitButton

local StatusDot = Instance.new("Frame")
StatusDot.Name = "StatusDot"
StatusDot.Size = UDim2.fromOffset(8, 8)
StatusDot.Position = UDim2.fromOffset(18, 26)
StatusDot.BackgroundColor3 = Color3.fromRGB(100, 111, 130)
StatusDot.BorderSizePixel = 0
StatusDot.ZIndex = 9
StatusDot.Parent = AntiHitButton

local StatusDotCorner = Instance.new("UICorner")
StatusDotCorner.CornerRadius = UDim.new(1, 0)
StatusDotCorner.Parent = StatusDot

local AntiHitTitle = Instance.new("TextLabel")
AntiHitTitle.Size = UDim2.new(1, -100, 0, 20)
AntiHitTitle.Position = UDim2.fromOffset(40, 11)
AntiHitTitle.BackgroundTransparency = 1
AntiHitTitle.Text = "ANTI HIT GUARDS"
AntiHitTitle.TextColor3 = Theme.Text
AntiHitTitle.Font = Enum.Font.GothamBold
AntiHitTitle.TextSize = 13
AntiHitTitle.TextXAlignment = Enum.TextXAlignment.Left
AntiHitTitle.ZIndex = 9
AntiHitTitle.Parent = AntiHitButton

local AntiHitSub = Instance.new("TextLabel")
AntiHitSub.Size = UDim2.new(1, -100, 0, 16)
AntiHitSub.Position = UDim2.fromOffset(40, 31)
AntiHitSub.BackgroundTransparency = 1
AntiHitSub.Text = "Protection disabled"
AntiHitSub.TextColor3 = Theme.TextMuted
AntiHitSub.Font = Enum.Font.GothamMedium
AntiHitSub.TextSize = 8
AntiHitSub.TextXAlignment = Enum.TextXAlignment.Left
AntiHitSub.ZIndex = 9
AntiHitSub.Parent = AntiHitButton

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.fromOffset(55, 20)
StatusText.Position = UDim2.new(1, -72, 0, 20)
StatusText.BackgroundTransparency = 1
StatusText.Text = "OFF"
StatusText.TextColor3 = Theme.TextMuted
StatusText.Font = Enum.Font.GothamBold
StatusText.TextSize = 9
StatusText.TextXAlignment = Enum.TextXAlignment.Right
StatusText.ZIndex = 9
StatusText.Parent = AntiHitButton

--------------------------------------------------------------------------------
-- FLY FOR AA TOGGLE BUTTON (POSITION: MIDDLE)
--------------------------------------------------------------------------------
local FlyBetaButton = Instance.new("TextButton")
FlyBetaButton.Name = "FlyBetaButton"
FlyBetaButton.Size = UDim2.new(1, 0, 0, 60)
FlyBetaButton.Position = UDim2.fromOffset(0, 88)
FlyBetaButton.BackgroundColor3 = Theme.Off
FlyBetaButton.BorderSizePixel = 0
FlyBetaButton.AutoButtonColor = false
FlyBetaButton.Text = ""
FlyBetaButton.ZIndex = 7
FlyBetaButton.Parent = Content

local FlyBetaCorner = Instance.new("UICorner")
FlyBetaCorner.CornerRadius = UDim.new(0, 14)
FlyBetaCorner.Parent = FlyBetaButton

local FlyBetaStroke = Instance.new("UIStroke")
FlyBetaStroke.Name = "FlyBetaStroke"
FlyBetaStroke.Color = Theme.OffStroke
FlyBetaStroke.Thickness = 1
FlyBetaStroke.Transparency = 0.2
FlyBetaStroke.Parent = FlyBetaButton

local FlyStatusDot = Instance.new("Frame")
FlyStatusDot.Name = "FlyStatusDot"
FlyStatusDot.Size = UDim2.fromOffset(8, 8)
FlyStatusDot.Position = UDim2.fromOffset(18, 26)
FlyStatusDot.BackgroundColor3 = Color3.fromRGB(100, 111, 130)
FlyStatusDot.BorderSizePixel = 0
FlyStatusDot.ZIndex = 9
FlyStatusDot.Parent = FlyBetaButton

local FlyStatusDotCorner = Instance.new("UICorner")
FlyStatusDotCorner.CornerRadius = UDim.new(1, 0)
FlyStatusDotCorner.Parent = FlyStatusDot

local FlyBetaTitle = Instance.new("TextLabel")
FlyBetaTitle.Size = UDim2.new(1, -100, 0, 20)
FlyBetaTitle.Position = UDim2.fromOffset(40, 11)
FlyBetaTitle.BackgroundTransparency = 1
FlyBetaTitle.Text = "FLY FOR AA"
FlyBetaTitle.TextColor3 = Theme.Text
FlyBetaTitle.Font = Enum.Font.GothamBold
FlyBetaTitle.TextSize = 13
FlyBetaTitle.TextXAlignment = Enum.TextXAlignment.Left
FlyBetaTitle.ZIndex = 9
FlyBetaTitle.Parent = FlyBetaButton

local FlyBetaSub = Instance.new("TextLabel")
FlyBetaSub.Size = UDim2.new(1, -100, 0, 16)
FlyBetaSub.Position = UDim2.fromOffset(40, 31)
FlyBetaSub.BackgroundTransparency = 1
FlyBetaSub.Text = "Toggle fly mode"
FlyBetaSub.TextColor3 = Theme.TextMuted
FlyBetaSub.Font = Enum.Font.GothamMedium
FlyBetaSub.TextSize = 8
FlyBetaSub.TextXAlignment = Enum.TextXAlignment.Left
FlyBetaSub.ZIndex = 9
FlyBetaSub.Parent = FlyBetaButton

local FlyStatusText = Instance.new("TextLabel")
FlyStatusText.Size = UDim2.fromOffset(55, 20)
FlyStatusText.Position = UDim2.new(1, -72, 0, 20)
FlyStatusText.BackgroundTransparency = 1
FlyStatusText.Text = "OFF"
FlyStatusText.TextColor3 = Theme.TextMuted
FlyStatusText.Font = Enum.Font.GothamBold
FlyStatusText.TextSize = 9
FlyStatusText.TextXAlignment = Enum.TextXAlignment.Right
FlyStatusText.ZIndex = 9
FlyStatusText.Parent = FlyBetaButton

--------------------------------------------------------------------------------
-- FLY SPEED SLIDER (1 - 450)
--------------------------------------------------------------------------------
local SliderCard = Instance.new("Frame")
SliderCard.Name = "SliderCard"
SliderCard.Size = UDim2.new(1, 0, 0, 60)
SliderCard.Position = UDim2.fromOffset(0, 156)
SliderCard.BackgroundColor3 = Theme.Off
SliderCard.BorderSizePixel = 0
SliderCard.ZIndex = 7
SliderCard.Parent = Content

local SliderCorner = Instance.new("UICorner")
SliderCorner.CornerRadius = UDim.new(0, 14)
SliderCorner.Parent = SliderCard

local SliderStroke = Instance.new("UIStroke")
SliderStroke.Name = "SliderStroke"
SliderStroke.Color = Theme.OffStroke
SliderStroke.Thickness = 1
SliderStroke.Transparency = 0.2
SliderStroke.Parent = SliderCard

local SliderDot = Instance.new("Frame")
SliderDot.Name = "SliderDot"
SliderDot.Size = UDim2.fromOffset(8, 8)
SliderDot.Position = UDim2.fromOffset(18, 16)
SliderDot.BackgroundColor3 = Theme.Accent
SliderDot.BorderSizePixel = 0
SliderDot.ZIndex = 9
SliderDot.Parent = SliderCard

local SliderDotCorner = Instance.new("UICorner")
SliderDotCorner.CornerRadius = UDim.new(1, 0)
SliderDotCorner.Parent = SliderDot

local SliderTitle = Instance.new("TextLabel")
SliderTitle.Size = UDim2.new(1, -100, 0, 18)
SliderTitle.Position = UDim2.fromOffset(36, 11)
SliderTitle.BackgroundTransparency = 1
SliderTitle.Text = "FLY SPEED"
SliderTitle.TextColor3 = Theme.Text
SliderTitle.Font = Enum.Font.GothamBold
SliderTitle.TextSize = 12
SliderTitle.TextXAlignment = Enum.TextXAlignment.Left
SliderTitle.ZIndex = 9
SliderTitle.Parent = SliderCard

local SliderValueLabel = Instance.new("TextLabel")
SliderValueLabel.Size = UDim2.fromOffset(60, 18)
SliderValueLabel.Position = UDim2.new(1, -72, 0, 11)
SliderValueLabel.BackgroundTransparency = 1
SliderValueLabel.Text = tostring(MOVE_SPEED)
SliderValueLabel.TextColor3 = Theme.AccentLight
SliderValueLabel.Font = Enum.Font.GothamBold
SliderValueLabel.TextSize = 12
SliderValueLabel.TextXAlignment = Enum.TextXAlignment.Right
SliderValueLabel.ZIndex = 9
SliderValueLabel.Parent = SliderCard

local SliderTrack = Instance.new("TextButton")
SliderTrack.Name = "SliderTrack"
SliderTrack.Size = UDim2.new(1, -36, 0, 8)
SliderTrack.Position = UDim2.fromOffset(18, 38)
SliderTrack.BackgroundColor3 = Color3.fromRGB(12, 17, 27)
SliderTrack.BorderSizePixel = 0
SliderTrack.AutoButtonColor = false
SliderTrack.Text = ""
SliderTrack.ZIndex = 9
SliderTrack.Parent = SliderCard

local TrackCorner = Instance.new("UICorner")
TrackCorner.CornerRadius = UDim.new(1, 0)
TrackCorner.Parent = SliderTrack

local TrackStroke = Instance.new("UIStroke")
TrackStroke.Color = Theme.Border
TrackStroke.Thickness = 1
TrackStroke.Transparency = 0.5
TrackStroke.Parent = SliderTrack

local SliderFill = Instance.new("Frame")
SliderFill.Name = "SliderFill"
SliderFill.Size = UDim2.new((MOVE_SPEED - 1) / (450 - 1), 0, 1, 0)
SliderFill.BackgroundColor3 = Theme.Accent
SliderFill.BorderSizePixel = 0
SliderFill.ZIndex = 10
SliderFill.Parent = SliderTrack

local FillCorner = Instance.new("UICorner")
FillCorner.CornerRadius = UDim.new(1, 0)
FillCorner.Parent = SliderFill

local SliderKnob = Instance.new("Frame")
SliderKnob.Name = "SliderKnob"
SliderKnob.Size = UDim2.fromOffset(14, 14)
SliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
SliderKnob.Position = UDim2.new(1, 0, 0.5, 0)
SliderKnob.BackgroundColor3 = Theme.Text
SliderKnob.BorderSizePixel = 0
SliderKnob.ZIndex = 11
SliderKnob.Parent = SliderFill

local KnobCorner = Instance.new("UICorner")
KnobCorner.CornerRadius = UDim.new(1, 0)
KnobCorner.Parent = SliderKnob

local KnobStroke = Instance.new("UIStroke")
KnobStroke.Color = Theme.Accent
KnobStroke.Thickness = 1.5
KnobStroke.Parent = SliderKnob

local MIN_SPEED = 1
local MAX_SPEED = 450
local isDraggingSlider = false

local function UpdateSliderInput(input)
	local trackAbsoluteSize = SliderTrack.AbsoluteSize.X
	local trackAbsolutePosition = SliderTrack.AbsolutePosition.X
	local mouseX = input.Position.X

	local relativeX = math.clamp(mouseX - trackAbsolutePosition, 0, trackAbsoluteSize)
	local alpha = relativeX / trackAbsoluteSize

	local calculatedSpeed = math.floor(MIN_SPEED + (alpha * (MAX_SPEED - MIN_SPEED)))
	MOVE_SPEED = math.clamp(calculatedSpeed, MIN_SPEED, MAX_SPEED)

	SliderFill.Size = UDim2.new((MOVE_SPEED - MIN_SPEED) / (MAX_SPEED - MIN_SPEED), 0, 1, 0)
	SliderValueLabel.Text = tostring(MOVE_SPEED)
end

SliderTrack.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		isDraggingSlider = true
		Tween(SliderStroke, 0.15, { Color = Theme.Accent, Transparency = 0 })
		UpdateSliderInput(input)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if isDraggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		UpdateSliderInput(input)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if isDraggingSlider then
			isDraggingSlider = false
			Tween(SliderStroke, 0.18, { Color = Theme.OffStroke, Transparency = 0.2 })
		end
	end
end)

FlyBetaButton.MouseEnter:Connect(function()
	if IsTransitioning then return end
	Tween(FlyBetaButton, 0.16, { BackgroundColor3 = isFlyActive and Color3.fromRGB(22, 58, 51) or Theme.CardHover })
	Tween(FlyBetaStroke, 0.16, { Transparency = 0, Color = isFlyActive and Theme.OnStroke or Theme.Accent })
end)

FlyBetaButton.MouseLeave:Connect(function()
	if isFlyActive then
		Tween(FlyBetaButton, 0.18, { BackgroundColor3 = Theme.On })
		Tween(FlyBetaStroke, 0.18, { Color = Theme.OnStroke, Transparency = 0.15 })
	else
		Tween(FlyBetaButton, 0.18, { BackgroundColor3 = Theme.Off })
		Tween(FlyBetaStroke, 0.18, { Color = Theme.OffStroke, Transparency = 0.2 })
	end
end)

AntiHitButton.MouseEnter:Connect(function()
	if IsTransitioning then return end
	Tween(AntiHitButton, 0.16, { BackgroundColor3 = isAntiHitActive and Color3.fromRGB(22, 58, 51) or Theme.CardHover })
	Tween(AntiHitStroke, 0.16, { Transparency = 0, Color = isAntiHitActive and Theme.OnStroke or Theme.Accent })
end)

AntiHitButton.MouseLeave:Connect(function()
	if isAntiHitActive then
		Tween(AntiHitButton, 0.18, { BackgroundColor3 = Theme.On })
		Tween(AntiHitStroke, 0.18, { Color = Theme.OnStroke, Transparency = 0.15 })
	else
		Tween(AntiHitButton, 0.18, { BackgroundColor3 = Theme.Off })
		Tween(AntiHitStroke, 0.18, { Color = Theme.OffStroke, Transparency = 0.2 })
	end
end)

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
ToggleSubtitle.Text = "MAIN UTILITIES"
ToggleSubtitle.TextColor3 = Theme.TextMuted
ToggleSubtitle.Font = Enum.Font.GothamMedium
ToggleSubtitle.TextSize = 7
ToggleSubtitle.TextXAlignment = Enum.TextXAlignment.Left
ToggleSubtitle.ZIndex = 501
ToggleSubtitle.Parent = ToggleButton

local MainDragging, MainDragStart, MainStartPosition, MainDragInput = false, nil, nil, nil

Header.InputBegan:Connect(function(input)
	if IsTransitioning then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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
	if not MainDragging then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		if not MainDragStart or not MainStartPosition then return end
		local delta = input.Position - MainDragStart
		MainFrame.Position = UDim2.new(MainStartPosition.X.Scale, MainStartPosition.X.Offset + delta.X, MainStartPosition.Y.Scale, MainStartPosition.Y.Offset + delta.Y)
	end
end)

local ToggleDragging, ToggleDragStart, ToggleStartPosition, ToggleMoved = false, nil, nil, false

ToggleButton.InputBegan:Connect(function(input)
	if IsTransitioning then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		ToggleDragging = true
		ToggleMoved = false
		ToggleDragStart = input.Position
		ToggleStartPosition = ToggleButton.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not ToggleDragging then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		if not ToggleDragStart or not ToggleStartPosition then return end
		local delta = input.Position - ToggleDragStart
		if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then ToggleMoved = true end
		ToggleButton.Position = UDim2.new(ToggleStartPosition.X.Scale, ToggleStartPosition.X.Offset + delta.X, ToggleStartPosition.Y.Scale, ToggleStartPosition.Y.Offset + delta.Y)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		ToggleDragging = false
	end
end)

ToggleButton.MouseEnter:Connect(function()
	if ToggleDragging or IsTransitioning then return end
	Tween(ToggleButton, 0.15, { Size = UDim2.fromOffset(252, 52) })
	Tween(ToggleStroke, 0.15, { Color = Theme.Accent, Transparency = 0 })
end)

ToggleButton.MouseLeave:Connect(function()
	if ToggleDragging then return end
	Tween(ToggleButton, 0.15, { Size = UDim2.fromOffset(245, 50) })
	Tween(ToggleStroke, 0.15, { Color = Theme.Border, Transparency = 0.05 })
end)

local function GetViewport()
	local camera = workspace.CurrentCamera
	return camera and camera.ViewportSize or Vector2.new(1920, 1080)
end

local function GetCenterPosition()
	local viewport = GetViewport()
	return UDim2.fromOffset(viewport.X * 0.5, viewport.Y * 0.5)
end

local function GetTopTogglePosition()
	local viewport = GetViewport()
	return UDim2.fromOffset(viewport.X * 0.5, -5)
end

local function GetTopRightTogglePosition()
	local viewport = GetViewport()
	return UDim2.fromOffset(viewport.X - 10, -5)
end

local function MinimizeUI()
	if IsTransitioning or IsMinimized then return end
	IsTransitioning = true
	IsMinimized = true

	MinimizeButton.Active = false
	FlyBetaButton.Active = false
	AntiHitButton.Active = false

	local centerPosition = GetCenterPosition()

	Tween(MainFrame, 0.45, { Position = centerPosition }, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
	task.wait(0.47)
	task.wait(0.30)

	Tween(MainFrame, 0.40, { Size = UDim2.fromOffset(245, 50) }, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
	task.wait(0.42)

	MainFrame.Visible = false
	ToggleButton.AnchorPoint = Vector2.new(0.5, 0.5)
	ToggleButton.Position = centerPosition
	ToggleButton.Size = UDim2.fromOffset(245, 50)
	ToggleButton.Visible = true

	task.wait(0.05)
	local topPosition = GetTopTogglePosition()

	Tween(ToggleButton, 0.55, { Position = topPosition }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	task.wait(0.58)

	ToggleButton.AnchorPoint = Vector2.new(1, 0.5)
	local topRightPosition = GetTopRightTogglePosition()
	Tween(ToggleButton, 0.45, { Position = topRightPosition }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	task.wait(0.48)

	ToggleButton.Active = true
	IsTransitioning = false
end

local function RestoreUI()
	if IsTransitioning or not IsMinimized then return end
	IsTransitioning = true
	ToggleButton.Active = false

	local topPosition = GetTopTogglePosition()
	local centerPosition = GetCenterPosition()

	ToggleButton.AnchorPoint = Vector2.new(0.5, 0.5)
	Tween(ToggleButton, 0.40, { Position = topPosition }, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
	task.wait(0.42)

	Tween(ToggleButton, 0.50, { Position = centerPosition }, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
	task.wait(0.53)
	task.wait(0.20)

	ToggleButton.Visible = false
	MainFrame.Visible = true
	MainFrame.Position = centerPosition
	MainFrame.Size = UDim2.fromOffset(245, 50)

	Tween(MainFrame, 0.45, { Size = UDim2.fromOffset(MAIN_WIDTH, MAIN_HEIGHT) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	task.wait(0.48)

	Tween(MainFrame, 0.55, { Position = MAIN_HOME_POSITION }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	task.wait(0.58)

	IsMinimized = false
	IsTransitioning = false

	MinimizeButton.Active = true
	FlyBetaButton.Active = true
	AntiHitButton.Active = true
end

MinimizeButton.MouseEnter:Connect(function()
	if IsTransitioning then return end
	Tween(MinimizeButton, 0.15, { BackgroundColor3 = Theme.CardHover })
	Tween(MinStroke, 0.15, { Color = Theme.Accent, Transparency = 0 })
end)

MinimizeButton.MouseLeave:Connect(function()
	Tween(MinimizeButton, 0.15, { BackgroundColor3 = Theme.Card })
	Tween(MinStroke, 0.15, { Color = Theme.Border, Transparency = 0.25 })
end)

MinimizeButton.MouseButton1Click:Connect(function() MinimizeUI() end)
ToggleButton.MouseButton1Click:Connect(function()
	if ToggleMoved then
		ToggleMoved = false
		return
	end
	RestoreUI()
end)

local function UpdateFlyBetaUI()
	if isFlyActive then
		FlyStatusText.Text = "ON"
		FlyStatusText.TextColor3 = Theme.OnAccent
		FlyBetaSub.Text = "Fly mode active"
		FlyStatusDot.BackgroundColor3 = Theme.OnAccent
		Tween(FlyBetaButton, 0.22, { BackgroundColor3 = Theme.On }, Enum.EasingStyle.Quart)
		Tween(FlyBetaStroke, 0.22, { Color = Theme.OnStroke, Transparency = 0.1 })
	else
		FlyStatusText.Text = "OFF"
		FlyStatusText.TextColor3 = Theme.TextMuted
		FlyBetaSub.Text = "Toggle fly mode"
		FlyStatusDot.BackgroundColor3 = Color3.fromRGB(100, 111, 130)
		Tween(FlyBetaButton, 0.22, { BackgroundColor3 = Theme.Off }, Enum.EasingStyle.Quart)
		Tween(FlyBetaStroke, 0.22, { Color = Theme.OffStroke, Transparency = 0.2 })

		local char = LocalPlayer.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.PlatformStand = false
			end
		end
		RemoveBlock()
	end
end

local function UpdateAntiHitUI()
	if isAntiHitActive then
		StatusText.Text = "ON"
		StatusText.TextColor3 = Theme.OnAccent
		AntiHitSub.Text = "Protection enabled"
		StatusDot.BackgroundColor3 = Theme.OnAccent
		Tween(AntiHitButton, 0.22, { BackgroundColor3 = Theme.On }, Enum.EasingStyle.Quart)
		Tween(AntiHitStroke, 0.22, { Color = Theme.OnStroke, Transparency = 0.1 })
	else
		StatusText.Text = "OFF"
		StatusText.TextColor3 = Theme.TextMuted
		AntiHitSub.Text = "Protection disabled"
		StatusDot.BackgroundColor3 = Color3.fromRGB(100, 111, 130)
		Tween(AntiHitButton, 0.22, { BackgroundColor3 = Theme.Off }, Enum.EasingStyle.Quart)
		Tween(AntiHitStroke, 0.22, { Color = Theme.OffStroke, Transparency = 0.2 })
	end
end

FlyBetaButton.MouseButton1Click:Connect(function()
	if IsTransitioning then return end
	isFlyActive = not isFlyActive
	UpdateFlyBetaUI()

	Tween(FlyBetaButton, 0.07, { Size = UDim2.new(1, -4, 0, 58), Position = UDim2.fromOffset(2, 89) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	task.delay(0.08, function()
		if FlyBetaButton.Parent then
			Tween(FlyBetaButton, 0.10, { Size = UDim2.new(1, 0, 0, 60), Position = UDim2.fromOffset(0, 88) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end
	end)
end)

AntiHitButton.MouseButton1Click:Connect(function()
	if IsTransitioning then return end
	isAntiHitActive = not isAntiHitActive
	UpdateAntiHitUI()

	Tween(AntiHitButton, 0.07, { Size = UDim2.new(1, -4, 0, 58), Position = UDim2.fromOffset(2, 21) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	task.delay(0.08, function()
		if AntiHitButton.Parent then
			Tween(AntiHitButton, 0.10, { Size = UDim2.new(1, 0, 0, 60), Position = UDim2.fromOffset(0, 20) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end
	end)
end)

--------------------------------------------------------------------------------
-- LOGIKA TELEPORT SAFE ZONE (ANTI HIT)
--------------------------------------------------------------------------------
local function ExecuteDropAndTeleport()
	if isProcessing or not isAntiHitActive then return end
	isProcessing = true
	
	local char = LocalPlayer.Character
	if char then
		local root = char:FindFirstChild("HumanoidRootPart")
		if root then
			local originalCFrame = root.CFrame

			for _, item in ipairs(char:GetChildren()) do
				if item:IsA("Tool") then
					item.Parent = workspace
				end
			end

			local targetSafeZoneCFrame = CFrame.new(TARGET_POS + Vector3.new(0, 3, 0))

			local startTime = os.clock()
			local holdConnection

			holdConnection = RunService.Heartbeat:Connect(function()
				if not char or not root or not root.Parent then
					if holdConnection then holdConnection:Disconnect() end
					return
				end

				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
				root.CFrame = targetSafeZoneCFrame
				char:PivotTo(targetSafeZoneCFrame)

				if os.clock() - startTime >= 0.6 then
					holdConnection:Disconnect()
				end
			end)

			task.delay(0.6, function()
				if char and root and root.Parent then
					root.AssemblyLinearVelocity = Vector3.zero
					root.AssemblyAngularVelocity = Vector3.zero
					root.CFrame = originalCFrame
					char:PivotTo(originalCFrame)
				end
			end)
		end
	end

	task.delay(0.7, function()
		isProcessing = false
	end)
end

ProximityPromptService.PromptTriggered:Connect(function(prompt, playerWhoTriggered)
	if isAntiHitActive and playerWhoTriggered == LocalPlayer then
		task.spawn(function() ExecuteDropAndTeleport() end)
	end
end)

local function SetupCharacterDetection(char)
	char.ChildAdded:Connect(function(child)
		if isAntiHitActive and not child:IsA("Tool") then
			local name = string.lower(child.Name)
			if string.find(name, "egg") or string.find(name, "telur") then
				task.spawn(function() ExecuteDropAndTeleport() end)
			end
		end
	end)
end

if LocalPlayer.Character then SetupCharacterDetection(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(function(newChar)
	task.wait(0.1)
	SetupCharacterDetection(newChar)
end)

UpdateFlyBetaUI()
UpdateAntiHitUI()

-- Intro Animasi UI
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

FlyBetaButton.BackgroundTransparency = 1
FlyBetaStroke.Transparency = 1
FlyBetaTitle.TextTransparency = 1
FlyBetaSub.TextTransparency = 1
FlyStatusText.TextTransparency = 1
FlyStatusDot.BackgroundTransparency = 1

AntiHitButton.BackgroundTransparency = 1
AntiHitStroke.Transparency = 1
AntiHitTitle.TextTransparency = 1
AntiHitSub.TextTransparency = 1
StatusText.TextTransparency = 1
StatusDot.BackgroundTransparency = 1

SliderCard.BackgroundTransparency = 1
SliderStroke.Transparency = 1
SliderTitle.TextTransparency = 1
SliderValueLabel.TextTransparency = 1
SliderTrack.BackgroundTransparency = 1
TrackStroke.Transparency = 1
SliderFill.BackgroundTransparency = 1
SliderKnob.BackgroundTransparency = 1
KnobStroke.Transparency = 1
SliderDot.BackgroundTransparency = 1

Tween(MainFrame, 0.55, { Size = UDim2.fromOffset(MAIN_WIDTH, MAIN_HEIGHT), BackgroundTransparency = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

task.delay(0.05, function()
	Tween(MainStroke, 0.4, { Transparency = 0.08 })
	Tween(TopAccent, 0.4, { BackgroundTransparency = 0 })
	Tween(LogoHolder, 0.35, { BackgroundTransparency = 0 })
	Tween(LogoStroke, 0.35, { Transparency = 0.35 })
end)

task.delay(0.12, function()
	Tween(Title, 0.35, { TextTransparency = 0 })
	Tween(Subtitle, 0.35, { TextTransparency = 0 })
	Tween(MinimizeButton, 0.35, { BackgroundTransparency = 0, TextTransparency = 0 })
	Tween(MinStroke, 0.35, { Transparency = 0.25 })
end)

task.delay(0.22, function()
	Tween(FeatureLabel, 0.3, { TextTransparency = 0 })

	Tween(FlyBetaButton, 0.35, { BackgroundTransparency = 0 }, Enum.EasingStyle.Quart)
	Tween(FlyBetaStroke, 0.35, { Transparency = 0.2 })
	Tween(FlyBetaTitle, 0.3, { TextTransparency = 0 })
	Tween(FlyBetaSub, 0.3, { TextTransparency = 0 })
	Tween(FlyStatusText, 0.3, { TextTransparency = 0 })
	Tween(FlyStatusDot, 0.3, { BackgroundTransparency = 0 })

	Tween(AntiHitButton, 0.35, { BackgroundTransparency = 0 }, Enum.EasingStyle.Quart)
	Tween(AntiHitStroke, 0.35, { Transparency = 0.2 })
	Tween(AntiHitTitle, 0.3, { TextTransparency = 0 })
	Tween(AntiHitSub, 0.3, { TextTransparency = 0 })
	Tween(StatusText, 0.3, { TextTransparency = 0 })
	Tween(StatusDot, 0.3, { BackgroundTransparency = 0 })

	Tween(SliderCard, 0.35, { BackgroundTransparency = 0 }, Enum.EasingStyle.Quart)
	Tween(SliderStroke, 0.35, { Transparency = 0.2 })
	Tween(SliderTitle, 0.3, { TextTransparency = 0 })
	Tween(SliderValueLabel, 0.3, { TextTransparency = 0 })
	Tween(SliderTrack, 0.3, { BackgroundTransparency = 0 })
	Tween(TrackStroke, 0.3, { Transparency = 0.5 })
	Tween(SliderFill, 0.3, { BackgroundTransparency = 0 })
	Tween(SliderKnob, 0.3, { BackgroundTransparency = 0 })
	Tween(KnobStroke, 0.3, { Transparency = 0 })
	Tween(SliderDot, 0.3, { BackgroundTransparency = 0 })
end)
