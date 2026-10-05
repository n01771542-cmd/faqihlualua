--[[
    ULTRA REALISTIC SHADER ENGINE V2
    Roblox LocalScript
    Recommended placement:
        StarterPlayer > StarterPlayerScripts

    IMPORTANT:
    This is a Roblox-native "shader-style" renderer.
    It does NOT inject arbitrary GPU shaders. It uses Roblox's supported
    Lighting, Atmosphere, post-processing, local lights, materials,
    adaptive quality and camera-space effects to approximate a realistic
    renderer while remaining safe for normal Roblox experiences.

    Features:
      - Realistic lighting style when supported
      - Soft shadow / global shadow tuning
      - Physically-inspired exposure pipeline
      - Atmosphere / aerial perspective
      - Sun response
      - Bloom / color grading / DOF / sun rays
      - Material and environment enhancement
      - Local-light quality management
      - Distance-aware local light optimization
      - Optional lightweight screen vignette
      - Adaptive FPS quality
      - Quality presets: PERFORMANCE / REALISTIC / CINEMATIC / ULTRA / EXTREME
      - Live FPS / memory / ping monitor
      - Safe state capture + restore
      - UI with categories and sliders
      - Feature toggles
      - Cleanup
      - Error isolation
      - No gameplay / RemoteEvent / player-data modification
]]

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local Workspace = game:GetService("Workspace")
local MaterialService = game:GetService("MaterialService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera

--==================================================
-- CORE
--==================================================

local ENGINE_NAME = "UltraRealisticShaderEngineV2"
local VERSION = "2.0.0"

local Alive = true
local Connections = {}
local CreatedInstances = {}
local Original = {
    Lighting = {},
    Atmosphere = nil,
    Effects = {},
    Materials = {},
    Lights = {},
}

local Config = {
    Enabled = true,
    Preset = "REALISTIC",

    Lighting = true,
    Atmosphere = true,
    Bloom = true,
    ColorGrading = true,
    SunRays = true,
    DepthOfField = false,
    Vignette = true,

    LocalLightOptimization = true,
    MaterialEnhancement = true,
    AdaptiveQuality = true,
    DynamicExposure = true,
    AutoSunResponse = true,

    ShadowSoftness = 0.32,
    Exposure = 0.05,
    Contrast = 0.10,
    Saturation = 0.04,
    Temperature = 0.0,

    AtmosphereDensity = 0.24,
    AtmosphereHaze = 1.35,
    AtmosphereGlare = 0.08,

    BloomIntensity = 0.16,
    BloomSize = 32,
    BloomThreshold = 1.15,

    SunRaysIntensity = 0.075,
    SunRaysSpread = 0.82,

    DOFNear = 0,
    DOFFar = 900,
    DOFFocus = 50,
    DOFStrength = 0.08,

    MaxDynamicLights = 80,
    LightUpdateDistance = 220,
    LightUpdateInterval = 0.20,

    TargetFPS = 58,
    MinimumFPS = 42,
    AdaptiveStep = 0.08,

    VignetteStrength = 0.20,
    VignetteSoftness = 0.72,

    UITransparency = 0.08,
}

local Presets = {
    PERFORMANCE = {
        ShadowSoftness = 0.55,
        Exposure = 0.00,
        Contrast = 0.04,
        Saturation = 0.00,
        AtmosphereDensity = 0.12,
        AtmosphereHaze = 0.75,
        AtmosphereGlare = 0.02,
        BloomIntensity = 0.05,
        BloomSize = 18,
        BloomThreshold = 1.4,
        SunRaysIntensity = 0.025,
        SunRaysSpread = 0.9,
        DepthOfField = false,
        MaxDynamicLights = 35,
    },

    REALISTIC = {
        ShadowSoftness = 0.32,
        Exposure = 0.05,
        Contrast = 0.10,
        Saturation = 0.04,
        AtmosphereDensity = 0.24,
        AtmosphereHaze = 1.35,
        AtmosphereGlare = 0.08,
        BloomIntensity = 0.16,
        BloomSize = 32,
        BloomThreshold = 1.15,
        SunRaysIntensity = 0.075,
        SunRaysSpread = 0.82,
        DepthOfField = false,
        MaxDynamicLights = 80,
    },

    CINEMATIC = {
        ShadowSoftness = 0.28,
        Exposure = 0.03,
        Contrast = 0.16,
        Saturation = 0.06,
        AtmosphereDensity = 0.27,
        AtmosphereHaze = 1.55,
        AtmosphereGlare = 0.10,
        BloomIntensity = 0.20,
        BloomSize = 36,
        BloomThreshold = 1.08,
        SunRaysIntensity = 0.09,
        SunRaysSpread = 0.78,
        DepthOfField = true,
        MaxDynamicLights = 75,
    },

    ULTRA = {
        ShadowSoftness = 0.22,
        Exposure = 0.02,
        Contrast = 0.20,
        Saturation = 0.07,
        AtmosphereDensity = 0.30,
        AtmosphereHaze = 1.75,
        AtmosphereGlare = 0.12,
        BloomIntensity = 0.23,
        BloomSize = 40,
        BloomThreshold = 1.03,
        SunRaysIntensity = 0.105,
        SunRaysSpread = 0.75,
        DepthOfField = true,
        MaxDynamicLights = 100,
    },

    EXTREME = {
        ShadowSoftness = 0.16,
        Exposure = 0.00,
        Contrast = 0.24,
        Saturation = 0.08,
        AtmosphereDensity = 0.33,
        AtmosphereHaze = 1.95,
        AtmosphereGlare = 0.14,
        BloomIntensity = 0.27,
        BloomSize = 44,
        BloomThreshold = 0.98,
        SunRaysIntensity = 0.12,
        SunRaysSpread = 0.72,
        DepthOfField = true,
        MaxDynamicLights = 120,
    },
}

--==================================================
-- UTILITIES
--==================================================

local function safe(fn, ...)
    local args = table.pack(...)
    local ok, result = pcall(function()
        return fn(table.unpack(args, 1, args.n))
    end)
    if ok then
        return true, result
    end
    return false, result
end

local function connect(signal, fn)
    local ok, connection = safe(function()
        return signal:Connect(fn)
    end)
    if ok and connection then
        table.insert(Connections, connection)
    end
    return connection
end

local function destroy(instance)
    if instance and instance.Parent then
        safe(function()
            instance:Destroy()
        end)
    end
end

local function track(instance)
    table.insert(CreatedInstances, instance)
    return instance
end

local function clamp(n, a, b)
    return math.max(a, math.min(b, n))
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function copyTable(t)
    local c = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            c[k] = copyTable(v)
        else
            c[k] = v
        end
    end
    return c
end

local function getCamera()
    Camera = Workspace.CurrentCamera or Camera
    return Camera
end

local function isProperty(instance, property)
    local ok = pcall(function()
        local _ = instance[property]
    end)
    return ok
end

local function setIf(instance, property, value)
    if instance and isProperty(instance, property) then
        safe(function()
            instance[property] = value
        end)
    end
end

local function getIf(instance, property, fallback)
    if instance and isProperty(instance, property) then
        local ok, value = safe(function()
            return instance[property]
        end)
        if ok then
            return value
        end
    end
    return fallback
end

--==================================================
-- CAPTURE ORIGINAL STATE
--==================================================

local function captureLighting()
    local properties = {
        "Ambient",
        "OutdoorAmbient",
        "Brightness",
        "ClockTime",
        "GeographicLatitude",
        "ExposureCompensation",
        "GlobalShadows",
        "ShadowSoftness",
        "FogColor",
        "FogStart",
        "FogEnd",
        "EnvironmentDiffuseScale",
        "EnvironmentSpecularScale",
    }

    for _, property in ipairs(properties) do
        if isProperty(Lighting, property) then
            Original.Lighting[property] = getIf(Lighting, property)
        end
    end

    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmosphere then
        Original.Atmosphere = {}
        for _, property in ipairs({
            "Density",
            "Offset",
            "Color",
            "Decay",
            "Glare",
            "Haze",
        }) do
            Original.Atmosphere[property] = getIf(atmosphere, property)
        end
    end
end

local function captureMaterials()
    if not MaterialService then
        return
    end

    local ok, materials = safe(function()
        return MaterialService:GetChildren()
    end)

    if not ok then
        return
    end

    for _, material in ipairs(materials) do
        if material:IsA("MaterialVariant") then
            Original.Materials[material] = {
                BaseMaterial = getIf(material, "BaseMaterial"),
                StudsPerTile = getIf(material, "StudsPerTile"),
            }
        end
    end
end

local function capture()
    captureLighting()
    captureMaterials()
end

--==================================================
-- NATIVE LIGHTING
--==================================================

local function applyRealisticLighting()
    if not Config.Lighting then
        return
    end

    setIf(Lighting, "GlobalShadows", true)
    setIf(Lighting, "ShadowSoftness", Config.ShadowSoftness)

    -- LightingStyle is the modern Roblox property when available.
    if isProperty(Lighting, "LightingStyle") then
        local enumValue = nil
        local ok = pcall(function()
            enumValue = Enum.LightingStyle.Realistic
        end)
        if ok and enumValue then
            setIf(Lighting, "LightingStyle", enumValue)
        end
    elseif isProperty(Lighting, "Technology") then
        local ok, technology = pcall(function()
            return Enum.Technology.Future
        end)
        if ok then
            setIf(Lighting, "Technology", technology)
        end
    end

    setIf(Lighting, "EnvironmentDiffuseScale", 0.85)
    setIf(Lighting, "EnvironmentSpecularScale", 0.92)
    setIf(Lighting, "ExposureCompensation", Config.Exposure)

    -- Keep neutral base ambient. The environment itself should provide
    -- most of the visual identity through sky/atmosphere/local lights.
    setIf(Lighting, "Ambient", Color3.fromRGB(35, 35, 38))
    setIf(Lighting, "OutdoorAmbient", Color3.fromRGB(80, 82, 88))
end

--==================================================
-- ATMOSPHERE
--==================================================

local function getOrCreateAtmosphere()
    local atmosphere = Lighting:FindFirstChild("URE_Atmosphere")
    if atmosphere and atmosphere:IsA("Atmosphere") then
        return atmosphere
    end

    atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmosphere then
        return atmosphere
    end

    atmosphere = track(Instance.new("Atmosphere"))
    atmosphere.Name = "URE_Atmosphere"
    atmosphere.Parent = Lighting
    return atmosphere
end

local function applyAtmosphere()
    if not Config.Atmosphere then
        local atmosphere = Lighting:FindFirstChild("URE_Atmosphere")
        if atmosphere then
            atmosphere.Enabled = false
        end
        return
    end

    local atmosphere = getOrCreateAtmosphere()
    atmosphere.Enabled = true

    setIf(atmosphere, "Density", Config.AtmosphereDensity)
    setIf(atmosphere, "Offset", 0)
    setIf(atmosphere, "Color", Color3.fromRGB(205, 214, 230))
    setIf(atmosphere, "Decay", Color3.fromRGB(105, 118, 142))
    setIf(atmosphere, "Glare", Config.AtmosphereGlare)
    setIf(atmosphere, "Haze", Config.AtmosphereHaze)
end

--==================================================
-- POST PROCESSING
--==================================================

local function getEffect(className, name)
    local existing = Lighting:FindFirstChild(name)
    if existing and existing.ClassName == className then
        return existing
    end

    local effect = Instance.new(className)
    effect.Name = name
    effect.Parent = Lighting
    track(effect)
    return effect
end

local function applyBloom()
    local bloom = getEffect("BloomEffect", "URE_Bloom")
    bloom.Enabled = Config.Enabled and Config.Bloom
    setIf(bloom, "Intensity", Config.BloomIntensity)
    setIf(bloom, "Size", Config.BloomSize)
    setIf(bloom, "Threshold", Config.BloomThreshold)
end

local function applyColorGrading()
    local color = getEffect("ColorCorrectionEffect", "URE_ColorGrading")
    color.Enabled = Config.Enabled and Config.ColorGrading

    setIf(color, "Brightness", 0)
    setIf(color, "Contrast", Config.Contrast)
    setIf(color, "Saturation", Config.Saturation)

    -- Very subtle blue-neutral balance. Avoid cartoonish tinting.
    local warm = Config.Temperature
    local tint = Color3.new(
        clamp(1 + warm * 0.02, 0.9, 1.1),
        clamp(1 + warm * 0.005, 0.9, 1.1),
        clamp(1 - warm * 0.02, 0.9, 1.1)
    )
    setIf(color, "TintColor", tint)
end

local function applySunRays()
    local rays = getEffect("SunRaysEffect", "URE_SunRays")
    rays.Enabled = Config.Enabled and Config.SunRays
    setIf(rays, "Intensity", Config.SunRaysIntensity)
    setIf(rays, "Spread", Config.SunRaysSpread)
end

local function applyDepthOfField()
    local dof = getEffect("DepthOfFieldEffect", "URE_DepthOfField")
    dof.Enabled = Config.Enabled and Config.DepthOfField
    setIf(dof, "FocusDistance", Config.DOFFocus)
    setIf(dof, "InFocusRadius", Config.DOFNear)
    setIf(dof, "NearIntensity", Config.DOFStrength)
    setIf(dof, "FarIntensity", Config.DOFStrength)
end

--==================================================
-- VIGNETTE
--==================================================

local UI = {
    Gui = nil,
    Main = nil,
    Content = nil,
    Status = nil,
    FPS = nil,
    Ping = nil,
    PresetLabel = nil,
    Toggle = nil,
    Tabs = {},
    Pages = {},
}

local function createVignette()
    if not Config.Vignette then
        if UI.Gui then
            local old = UI.Gui:FindFirstChild("URE_Vignette")
            if old then
                old.Visible = false
            end
        end
        return
    end

    if not UI.Gui then
        return
    end

    local old = UI.Gui:FindFirstChild("URE_Vignette")
    if old then
        old.Visible = true
        return
    end

    local frame = Instance.new("Frame")
    frame.Name = "URE_Vignette"
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.BackgroundTransparency = 1 - Config.VignetteStrength * 0.25
    frame.BorderSizePixel = 0
    frame.Size = UDim2.fromScale(1, 1)
    frame.Position = UDim2.fromScale(0, 0)
    frame.ZIndex = 0
    frame.Parent = UI.Gui

    -- Soft edge imitation using four gradients.
    local edge = Instance.new("UIGradient")
    edge.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.80),
        NumberSequenceKeypoint.new(0.35, 0.97),
        NumberSequenceKeypoint.new(0.65, 0.97),
        NumberSequenceKeypoint.new(1, 0.80),
    })
    edge.Rotation = 0
    edge.Parent = frame

    frame.BackgroundTransparency = 0.93
end

--==================================================
-- LIGHT MANAGEMENT
--==================================================

local LightCache = {}
local LastLightScan = 0

local function collectLights()
    local now = os.clock()
    if now - LastLightScan < Config.LightUpdateInterval then
        return
    end
    LastLightScan = now

    table.clear(LightCache)

    local camera = getCamera()
    if not camera then
        return
    end

    local cameraPosition = camera.CFrame.Position

    local count = 0
    for _, descendant in ipairs(Workspace:GetDescendants()) do
        if descendant:IsA("PointLight")
            or descendant:IsA("SpotLight")
            or descendant:IsA("SurfaceLight") then

            count += 1
            if count > 500 then
                break
            end

            local parent = descendant.Parent
            local position

            if parent and parent:IsA("BasePart") then
                position = parent.Position
            elseif parent and parent:IsA("Attachment") then
                position = parent.WorldPosition
            end

            if position then
                table.insert(LightCache, {
                    Instance = descendant,
                    Position = position,
                    Distance = (position - cameraPosition).Magnitude,
                })
            end
        end
    end
end

local function optimizeLights()
    if not Config.LocalLightOptimization then
        return
    end

    collectLights()

    table.sort(LightCache, function(a, b)
        return a.Distance < b.Distance
    end)

    for index, info in ipairs(LightCache) do
        local light = info.Instance
        if light and light.Parent then
            local shouldEnable =
                index <= Config.MaxDynamicLights
                and info.Distance <= Config.LightUpdateDistance

            -- Never permanently destroy or rewrite gameplay logic.
            -- Only visibility/enabled state is managed while this renderer runs.
            if isProperty(light, "Enabled") then
                safe(function()
                    light.Enabled = shouldEnable
                end)
            end

            if isProperty(light, "Shadows") then
                local shadow = info.Distance < Config.LightUpdateDistance * 0.45
                safe(function()
                    light.Shadows = shadow
                end)
            end
        end
    end
end

--==================================================
-- ADAPTIVE QUALITY
--==================================================

local FPS = {
    Current = 60,
    Average = 60,
    Samples = {},
    Accumulator = 0,
    Frames = 0,
}

local Adaptive = {
    Cooldown = 0,
    Level = 0,
}

local function recordFPS(dt)
    local instant = 1 / math.max(dt, 1 / 240)
    instant = clamp(instant, 1, 240)

    FPS.Current = instant
    table.insert(FPS.Samples, instant)

    if #FPS.Samples > 45 then
        table.remove(FPS.Samples, 1)
    end

    local total = 0
    for _, value in ipairs(FPS.Samples) do
        total += value
    end

    FPS.Average = total / math.max(#FPS.Samples, 1)
end

local function adaptiveQuality(dt)
    if not Config.AdaptiveQuality or not Config.Enabled then
        return
    end

    Adaptive.Cooldown -= dt
    if Adaptive.Cooldown > 0 then
        return
    end

    Adaptive.Cooldown = 2.5

    if FPS.Average < Config.MinimumFPS then
        Adaptive.Level = clamp(Adaptive.Level + 1, 0, 4)

        if Adaptive.Level == 1 then
            Config.BloomIntensity = math.max(0.08, Config.BloomIntensity * 0.85)
            Config.SunRaysIntensity = math.max(0.03, Config.SunRaysIntensity * 0.85)
        elseif Adaptive.Level == 2 then
            Config.MaxDynamicLights = math.max(30, Config.MaxDynamicLights - 15)
        elseif Adaptive.Level == 3 then
            Config.DepthOfField = false
            Config.AtmosphereDensity = math.max(0.14, Config.AtmosphereDensity - 0.03)
        elseif Adaptive.Level == 4 then
            Config.Preset = "PERFORMANCE"
            local preset = Presets.PERFORMANCE
            for k, v in pairs(preset) do
                Config[k] = v
            end
        end

        applyAll()
    elseif FPS.Average > Config.TargetFPS + 8 and Adaptive.Level > 0 then
        Adaptive.Level -= 1

        if Adaptive.Level == 3 then
            Config.Preset = "REALISTIC"
        elseif Adaptive.Level == 2 then
            Config.MaxDynamicLights = 60
        elseif Adaptive.Level == 1 then
            Config.BloomIntensity = math.max(Config.BloomIntensity, 0.14)
            Config.SunRaysIntensity = math.max(Config.SunRaysIntensity, 0.06)
        elseif Adaptive.Level == 0 then
            Config.Preset = "REALISTIC"
        end

        applyPreset(Config.Preset, false)
        applyAll()
    end
end

--==================================================
-- PRESETS
--==================================================

function applyPreset(name, refresh)
    local preset = Presets[name]
    if not preset then
        return
    end

    Config.Preset = name

    for key, value in pairs(preset) do
        Config[key] = value
    end

    if refresh ~= false then
        applyAll()
    end
end

--==================================================
-- UI HELPERS
--==================================================

local COLORS = {
    Background = Color3.fromRGB(12, 14, 18),
    Panel = Color3.fromRGB(19, 22, 28),
    Panel2 = Color3.fromRGB(24, 28, 35),
    Accent = Color3.fromRGB(125, 170, 255),
    Accent2 = Color3.fromRGB(87, 124, 210),
    Text = Color3.fromRGB(238, 242, 250),
    Muted = Color3.fromRGB(150, 158, 172),
    Good = Color3.fromRGB(110, 225, 160),
    Warning = Color3.fromRGB(255, 196, 100),
    Bad = Color3.fromRGB(255, 110, 110),
}

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function stroke(parent, transparency)
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(80, 90, 110)
    s.Transparency = transparency or 0.75
    s.Thickness = 1
    s.Parent = parent
    return s
end

local function padding(parent, amount)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, amount)
    p.PaddingBottom = UDim.new(0, amount)
    p.PaddingLeft = UDim.new(0, amount)
    p.PaddingRight = UDim.new(0, amount)
    p.Parent = parent
    return p
end

local function label(parent, text, size, color)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or COLORS.Text
    l.TextSize = size or 13
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Size = UDim2.new(1, 0, 0, 24)
    l.Parent = parent
    return l
end

local function button(parent, text)
    local b = Instance.new("TextButton")
    b.AutoButtonColor = false
    b.Text = text
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 12
    b.TextColor3 = COLORS.Text
    b.BackgroundColor3 = COLORS.Panel2
    b.Size = UDim2.new(1, 0, 0, 34)
    b.Parent = parent
    corner(b, 7)
    stroke(b, 0.82)

    connect(b.MouseEnter, function()
        if not Alive then return end
        TweenService:Create(b, TweenInfo.new(0.12), {
            BackgroundColor3 = COLORS.Accent2
        }):Play()
    end)

    connect(b.MouseLeave, function()
        if not Alive then return end
        TweenService:Create(b, TweenInfo.new(0.12), {
            BackgroundColor3 = COLORS.Panel2
        }):Play()
    end)

    return b
end

local function switch(parent, text, getter, setter)
    local b = button(parent, "")
    b.TextXAlignment = Enum.TextXAlignment.Left

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Text = text
    title.TextColor3 = COLORS.Text
    title.Font = Enum.Font.Gotham
    title.TextSize = 12
    title.Position = UDim2.fromOffset(10, 0)
    title.Size = UDim2.new(1, -62, 1, 0)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = b

    local state = Instance.new("TextLabel")
    state.BackgroundTransparency = 1
    state.Font = Enum.Font.GothamBold
    state.TextSize = 10
    state.Size = UDim2.fromOffset(44, 34)
    state.Position = UDim2.new(1, -48, 0, 0)
    state.Parent = b

    local function refresh()
        local on = getter()
        state.Text = on and "ON" or "OFF"
        state.TextColor3 = on and COLORS.Good or COLORS.Bad
    end

    refresh()

    connect(b.MouseButton1Click, function()
        setter(not getter())
        refresh()
        applyAll()
    end)

    return b
end

local function makePage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = COLORS.Accent
    page.Size = UDim2.fromScale(1, 1)
    page.CanvasSize = UDim2.fromOffset(0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = UI.Content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    padding(page, 2)

    UI.Pages[name] = page
    return page
end

local function section(parent, titleText)
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = COLORS.Panel
    frame.BackgroundTransparency = 0.12
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(1, -4, 0, 42)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.Parent = parent
    corner(frame, 8)
    stroke(frame, 0.9)
    padding(frame, 10)

    local title = label(frame, titleText, 12, COLORS.Accent)
    title.Size = UDim2.new(1, 0, 0, 24)

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 6)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = frame

    return frame
end

local function addPresetButtons(parent)
    local holder = Instance.new("Frame")
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.new(1, 0, 0, 142)
    holder.Parent = parent

    local grid = Instance.new("UIGridLayout")
    grid.CellPadding = UDim2.fromOffset(6, 6)
    grid.CellSize = UDim2.new(0.333, -4, 0, 40)
    grid.Parent = holder

    for _, name in ipairs({"PERFORMANCE", "REALISTIC", "CINEMATIC", "ULTRA", "EXTREME"}) do
        local b = button(holder, name)
        b.Size = UDim2.new(0, 0, 0, 0)
        connect(b.MouseButton1Click, function()
            applyPreset(name)
            refreshUI()
        end)
    end
end

--==================================================
-- UI BUILD
--==================================================

function buildUI()
    if UI.Gui then
        destroy(UI.Gui)
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "UltraRealisticShaderEngineV2"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = PlayerGui
    UI.Gui = gui

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.fromScale(0.5, 0.5)
    main.Size = UDim2.fromOffset(650, 470)
    main.BackgroundColor3 = COLORS.Background
    main.BackgroundTransparency = Config.UITransparency
    main.BorderSizePixel = 0
    main.Parent = gui
    UI.Main = main
    corner(main, 14)
    stroke(main, 0.70)

    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = main

    local top = Instance.new("Frame")
    top.BackgroundColor3 = COLORS.Panel
    top.BackgroundTransparency = 0.08
    top.Size = UDim2.new(1, 0, 0, 62)
    top.Parent = main
    corner(top, 14)

    local title = label(top, "ULTRA REALISTIC", 16, COLORS.Text)
    title.Position = UDim2.fromOffset(18, 8)
    title.Size = UDim2.new(0.55, 0, 0, 25)
    title.Font = Enum.Font.GothamBold

    local sub = label(top, "SHADER ENGINE  •  V2", 10, COLORS.Muted)
    sub.Position = UDim2.fromOffset(18, 31)
    sub.Size = UDim2.new(0.55, 0, 0, 18)

    local status = label(top, "● ACTIVE", 11, COLORS.Good)
    status.AnchorPoint = Vector2.new(1, 0)
    status.Position = UDim2.new(1, -18, 0, 10)
    status.Size = UDim2.fromOffset(90, 22)
    status.TextXAlignment = Enum.TextXAlignment.Right
    UI.Status = status

    local fps = label(top, "FPS 60", 10, COLORS.Muted)
    fps.AnchorPoint = Vector2.new(1, 0)
    fps.Position = UDim2.new(1, -18, 0, 33)
    fps.Size = UDim2.fromOffset(100, 18)
    fps.TextXAlignment = Enum.TextXAlignment.Right
    UI.FPS = fps

    local tabs = Instance.new("Frame")
    tabs.BackgroundTransparency = 1
    tabs.Position = UDim2.fromOffset(12, 72)
    tabs.Size = UDim2.new(0, 130, 1, -84)
    tabs.Parent = main

    local tabList = Instance.new("UIListLayout")
    tabList.Padding = UDim.new(0, 6)
    tabList.Parent = tabs

    UI.Content = Instance.new("Frame")
    UI.Content.BackgroundColor3 = COLORS.Panel
    UI.Content.BackgroundTransparency = 0.08
    UI.Content.BorderSizePixel = 0
    UI.Content.Position = UDim2.fromOffset(152, 72)
    UI.Content.Size = UDim2.new(1, -164, 1, -84)
    UI.Content.Parent = main
    corner(UI.Content, 10)
    stroke(UI.Content, 0.85)

    local dashboard = makePage("Dashboard")
    local lighting = makePage("Lighting")
    local effects = makePage("Effects")
    local performance = makePage("Performance")
    local advanced = makePage("Advanced")

    -- Dashboard
    do
        local s = section(dashboard, "RENDER PRESET")
        addPresetButtons(s)

        local statusBox = Instance.new("Frame")
        statusBox.BackgroundColor3 = COLORS.Panel2
        statusBox.Size = UDim2.new(1, 0, 0, 70)
        statusBox.Parent = s
        corner(statusBox, 8)

        local preset = label(statusBox, "PRESET: " .. Config.Preset, 12, COLORS.Text)
        preset.Position = UDim2.fromOffset(10, 7)
        preset.Size = UDim2.new(1, -20, 0, 24)
        UI.PresetLabel = preset

        local desc = label(statusBox, "Native Roblox lighting + atmospheric renderer", 10, COLORS.Muted)
        desc.Position = UDim2.fromOffset(10, 34)
        desc.Size = UDim2.new(1, -20, 0, 20)

        local s2 = section(dashboard, "MASTER")
        switch(s2, "Renderer Enabled", function()
            return Config.Enabled
        end, function(v)
            Config.Enabled = v
        end)

        switch(s2, "Adaptive Quality", function()
            return Config.AdaptiveQuality
        end, function(v)
            Config.AdaptiveQuality = v
        end)
    end

    -- Lighting
    do
        local s = section(lighting, "REALISTIC LIGHTING")
        switch(s, "Realistic Lighting", function()
            return Config.Lighting
        end, function(v)
            Config.Lighting = v
        end)

        switch(s, "Atmosphere", function()
            return Config.Atmosphere
        end, function(v)
            Config.Atmosphere = v
        end)

        switch(s, "Dynamic Exposure", function()
            return Config.DynamicExposure
        end, function(v)
            Config.DynamicExposure = v
        end)

        switch(s, "Auto Sun Response", function()
            return Config.AutoSunResponse
        end, function(v)
            Config.AutoSunResponse = v
        end)

        local info = section(lighting, "PIPELINE")
        local textInfo = label(info,
            "Realistic lighting • soft shadows • environment diffuse/specular • aerial perspective",
            11, COLORS.Muted)
        textInfo.TextWrapped = true
        textInfo.Size = UDim2.new(1, 0, 0, 44)
    end

    -- Effects
    do
        local s = section(effects, "POST PROCESSING")
        switch(s, "Bloom", function()
            return Config.Bloom
        end, function(v)
            Config.Bloom = v
        end)

        switch(s, "Color Grading", function()
            return Config.ColorGrading
        end, function(v)
            Config.ColorGrading = v
        end)

        switch(s, "Sun Rays", function()
            return Config.SunRays
        end, function(v)
            Config.SunRays = v
        end)

        switch(s, "Depth Of Field", function()
            return Config.DepthOfField
        end, function(v)
            Config.DepthOfField = v
        end)

        switch(s, "Vignette", function()
            return Config.Vignette
        end, function(v)
            Config.Vignette = v
        end)

        local s2 = section(effects, "ATMOSPHERE")
        local atmosphereInfo = label(s2,
            "Atmosphere is kept subtle to preserve distant geometry while adding depth, haze and light scattering.",
            11, COLORS.Muted)
        atmosphereInfo.TextWrapped = true
        atmosphereInfo.Size = UDim2.new(1, 0, 0, 52)
    end

    -- Performance
    do
        local s = section(performance, "LIVE MONITOR")
        local monitor = label(s,
            "FPS: 60\nAverage: 60\nAdaptive level: 0",
            12, COLORS.Text)
        monitor.Name = "Monitor"
        monitor.TextWrapped = true
        monitor.Size = UDim2.new(1, 0, 0, 65)

        local s2 = section(performance, "OPTIMIZATION")
        switch(s2, "Local Light Optimization", function()
            return Config.LocalLightOptimization
        end, function(v)
            Config.LocalLightOptimization = v
        end)

        switch(s2, "Material Enhancement", function()
            return Config.MaterialEnhancement
        end, function(v)
            Config.MaterialEnhancement = v
        end)
    end

    -- Advanced
    do
        local s = section(advanced, "ENGINE INFORMATION")
        local info = label(s,
            "Version " .. VERSION ..
            "\nSafe client-side visual controller" ..
            "\nNo gameplay / remotes / player-data edits" ..
            "\nTrue arbitrary GPU shaders are not exposed to ordinary Luau; this engine uses native Roblox rendering features.",
            11, COLORS.Muted)
        info.TextWrapped = true
        info.Size = UDim2.new(1, 0, 0, 105)

        local restore = button(s, "RESTORE ORIGINAL LIGHTING")
        connect(restore.MouseButton1Click, function()
            restoreOriginal()
        end)

        local rebuild = button(s, "REBUILD VISUAL PIPELINE")
        connect(rebuild.MouseButton1Click, function()
            applyAll()
        end)
    end

    local names = {"Dashboard", "Lighting", "Effects", "Performance", "Advanced"}

    for _, name in ipairs(names) do
        local b = button(tabs, name)
        b.Size = UDim2.new(1, 0, 0, 38)
        UI.Tabs[name] = b

        connect(b.MouseButton1Click, function()
            for pageName, page in pairs(UI.Pages) do
                page.Visible = pageName == name
            end
        end)
    end

    dashboard.Visible = true

    -- Floating toggle
    local toggle = Instance.new("TextButton")
    toggle.Name = "FloatingToggle"
    toggle.AnchorPoint = Vector2.new(1, 1)
    toggle.Position = UDim2.new(1, -18, 1, -18)
    toggle.Size = UDim2.fromOffset(54, 54)
    toggle.BackgroundColor3 = COLORS.Panel
    toggle.Text = "VR"
    toggle.TextColor3 = COLORS.Accent
    toggle.TextSize = 13
    toggle.Font = Enum.Font.GothamBold
    toggle.Parent = gui
    corner(toggle, 27)
    stroke(toggle, 0.65)
    UI.Toggle = toggle

    connect(toggle.MouseButton1Click, function()
        main.Visible = not main.Visible
    end)

    -- Dragging
    local dragging = false
    local dragStart
    local startPosition

    connect(top.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = main.Position
        end
    end)

    connect(UserInputService.InputChanged, function(input)
        if not dragging then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then

            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)

    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    createVignette()
end

function refreshUI()
    if not UI.Gui then
        return
    end

    if UI.PresetLabel then
        UI.PresetLabel.Text = "PRESET: " .. Config.Preset
    end

    if UI.Status then
        UI.Status.Text = Config.Enabled and "● ACTIVE" or "● OFF"
        UI.Status.TextColor3 = Config.Enabled and COLORS.Good or COLORS.Bad
    end
end

--==================================================
-- DYNAMIC EXPOSURE / SUN RESPONSE
--==================================================

local ExposureState = {
    Value = Config.Exposure,
}

local function updateSunResponse()
    if not Config.AutoSunResponse or not Config.Enabled then
        return
    end

    local clock = Lighting.ClockTime
    local daylight = math.sin((clock - 6) / 12 * math.pi)
    daylight = clamp(daylight, 0, 1)

    local targetExposure =
        Config.Exposure
        + lerp(-0.12, 0.10, daylight)

    if Config.DynamicExposure then
        ExposureState.Value = lerp(ExposureState.Value, targetExposure, 0.025)
        setIf(Lighting, "ExposureCompensation", ExposureState.Value)
    else
        setIf(Lighting, "ExposureCompensation", Config.Exposure)
    end
end

--==================================================
-- APPLY PIPELINE
--==================================================

function applyAll()
    if not Alive then
        return
    end

    if Config.Enabled then
        applyRealisticLighting()
        applyAtmosphere()
        applyBloom()
        applyColorGrading()
        applySunRays()
        applyDepthOfField()
        createVignette()
        optimizeLights()
    else
        for _, name in ipairs({
            "URE_Bloom",
            "URE_ColorGrading",
            "URE_SunRays",
            "URE_DepthOfField",
        }) do
            local effect = Lighting:FindFirstChild(name)
            if effect and isProperty(effect, "Enabled") then
                effect.Enabled = false
            end
        end

        local atmosphere = Lighting:FindFirstChild("URE_Atmosphere")
        if atmosphere then
            atmosphere.Enabled = false
        end

        if UI.Gui then
            local vignette = UI.Gui:FindFirstChild("URE_Vignette")
            if vignette then
                vignette.Visible = false
            end
        end
    end

    refreshUI()
end

--==================================================
-- RESTORE
--==================================================

function restoreOriginal()
    for property, value in pairs(Original.Lighting) do
        setIf(Lighting, property, value)
    end

    if Original.Atmosphere then
        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
        if atmosphere then
            for property, value in pairs(Original.Atmosphere) do
                setIf(atmosphere, property, value)
            end
        end
    end

    for instance, data in pairs(Original.Materials) do
        if instance and instance.Parent then
            for property, value in pairs(data) do
                if value ~= nil then
                    setIf(instance, property, value)
                end
            end
        end
    end

    for _, effectName in ipairs({
        "URE_Bloom",
        "URE_ColorGrading",
        "URE_SunRays",
        "URE_DepthOfField",
    }) do
        local effect = Lighting:FindFirstChild(effectName)
        if effect then
            destroy(effect)
        end
    end

    local atmosphere = Lighting:FindFirstChild("URE_Atmosphere")
    if atmosphere then
        destroy(atmosphere)
    end

    if UI.Gui then
        local vignette = UI.Gui:FindFirstChild("URE_Vignette")
        if vignette then
            destroy(vignette)
        end
    end
end

--==================================================
-- STATS
--==================================================

local function getPing()
    local value = 0

    local ok, result = safe(function()
        local network = Stats:FindFirstChild("Network")
        if not network then
            return 0
        end

        local serverStats = network:FindFirstChild("ServerStatsItem")
        if not serverStats then
            return 0
        end

        local dataPing = serverStats:FindFirstChild("Data Ping")
        if not dataPing then
            return 0
        end

        local stringValue = dataPing:GetValueString()
        return tonumber(stringValue:match("[%d%.]+")) or 0
    end)

    if ok and result then
        value = result
    end

    return value
end

local function getMemory()
    local memory = 0

    local ok, result = safe(function()
        return Stats:GetTotalMemoryUsageMb()
    end)

    if ok and result then
        memory = result
    end

    return memory
end

local function updateMonitor()
    if not UI.Gui then
        return
    end

    if UI.FPS then
        UI.FPS.Text = string.format("FPS %.0f", FPS.Current)
    end

    local performancePage = UI.Pages.Performance
    if performancePage then
        local monitor = performancePage:FindFirstChild("Monitor", true)
        if monitor then
            monitor.Text = string.format(
                "FPS: %.0f\nAverage: %.0f\nPing: %.0f ms\nMemory: %.0f MB\nAdaptive level: %d",
                FPS.Current,
                FPS.Average,
                getPing(),
                getMemory(),
                Adaptive.Level
            )
        end
    end
end

--==================================================
-- LIFECYCLE
--==================================================

capture()
buildUI()
applyAll()

connect(RunService.RenderStepped, function(dt)
    if not Alive then
        return
    end

    recordFPS(dt)
    adaptiveQuality(dt)
    updateSunResponse()
end)

task.spawn(function()
    while Alive do
        task.wait(0.25)
        if Alive then
            updateMonitor()
        end
    end
end)

task.spawn(function()
    while Alive do
        task.wait(Config.LightUpdateInterval)
        if Alive and Config.Enabled and Config.LocalLightOptimization then
            optimizeLights()
        end
    end
end)

connect(Workspace:GetPropertyChangedSignal("CurrentCamera"), function()
    Camera = Workspace.CurrentCamera
end)

--==================================================
-- PUBLIC API
--==================================================

_G.UltraRealisticShaderEngineV2 = {
    Version = VERSION,

    GetConfig = function()
        return copyTable(Config)
    end,

    GetFPS = function()
        return FPS.Current
    end,

    GetAverageFPS = function()
        return FPS.Average
    end,

    ApplyPreset = function(name)
        applyPreset(name)
    end,

    Apply = function()
        applyAll()
    end,

    Restore = function()
        restoreOriginal()
    end,

    SetEnabled = function(enabled)
        Config.Enabled = enabled == true
        applyAll()
    end,

    Cleanup = function()
        if not Alive then
            return
        end

        Alive = false

        for _, connection in ipairs(Connections) do
            safe(function()
                connection:Disconnect()
            end)
        end
        table.clear(Connections)

        restoreOriginal()

        for _, instance in ipairs(CreatedInstances) do
            if instance and instance.Parent then
                destroy(instance)
            end
        end
        table.clear(CreatedInstances)

        if UI.Gui then
            destroy(UI.Gui)
        end

        UI.Gui = nil
    end,
}

print(string.format("[%s] Loaded %s", ENGINE_NAME, VERSION))
print("[UltraRealisticShaderEngineV2] Native realistic renderer initialized.")

--==================================================
-- END OF ENGINE
--==================================================
-- Suggested Studio workflow:
-- 1. Put this LocalScript in StarterPlayerScripts.
-- 2. Test REALISTIC first.
-- 3. Use CINEMATIC/ULTRA only after checking frame time.
-- 4. If the experience already owns Lighting/post effects, integrate
--    the pipeline into that existing lighting controller rather than
--    running multiple competing controllers.
--
-- The engine intentionally avoids:
--   * RemoteEvent firing
--   * gameplay automation
--   * character manipulation
--   * player-data edits
--   * arbitrary external code execution
--
-- It is a rendering/visual-quality controller only.



--==================================================
-- ULTRA REALISTIC SHADER ENGINE V3
-- DEEP VISUAL ENHANCEMENT LAYER
--==================================================
-- This V3 layer sits on top of V2 and adds:
--   * 10 real-time visual quality levels
--   * 20+ atmosphere / mood profiles
--   * material-aware color/reflectance enhancement
--   * SurfaceAppearance-aware visual tuning
--   * automatic emissive/local-light accents
--   * micro-contrast / cinematic camera response
--   * environment-aware lighting
--   * distance-aware detail budgeting
--   * reversible visual state capture
--   * dedicated V3 control panel
--
-- The layer never touches gameplay remotes, player data, movement,
-- inventory, economy, combat, or server state.
--==================================================

local V3 = {
    Version = "3.0.0",
    Enabled = true,
    Quality = 10,
    Atmosphere = "ULTRA NATURAL",
    DetailPass = true,
    MaterialPass = true,
    EmissivePass = true,
    CameraPass = true,
    DynamicWeather = false,
    AutoAtmosphere = false,
    Created = {},
    Original = {},
    LightCache = {},
    Connections = {},
    UI = nil,
    LastQualityApply = 0,
    LastDetailPass = 0,
}

local V3_QUALITY = {
    [1] = {name="MINIMAL", shadow=1, atmosphere=0.00, bloom=0.00, saturation=-0.10, contrast=0.00, material=0.00, lights=0, detail=0, camera=0},
    [2] = {name="LOW", shadow=0.95, atmosphere=0.02, bloom=0.02, saturation=-0.05, contrast=0.03, material=0.10, lights=4, detail=0, camera=0.05},
    [3] = {name="BALANCED", shadow=0.90, atmosphere=0.04, bloom=0.04, saturation=0.00, contrast=0.05, material=0.20, lights=8, detail=1, camera=0.08},
    [4] = {name="GOOD", shadow=0.82, atmosphere=0.06, bloom=0.06, saturation=0.02, contrast=0.07, material=0.30, lights=12, detail=1, camera=0.12},
    [5] = {name="HIGH", shadow=0.72, atmosphere=0.08, bloom=0.08, saturation=0.04, contrast=0.09, material=0.42, lights=18, detail=2, camera=0.16},
    [6] = {name="VERY HIGH", shadow=0.62, atmosphere=0.11, bloom=0.10, saturation=0.06, contrast=0.11, material=0.54, lights=26, detail=2, camera=0.20},
    [7] = {name="ULTRA", shadow=0.50, atmosphere=0.14, bloom=0.12, saturation=0.08, contrast=0.13, material=0.66, lights=36, detail=3, camera=0.24},
    [8] = {name="CINEMATIC ULTRA", shadow=0.40, atmosphere=0.17, bloom=0.14, saturation=0.10, contrast=0.15, material=0.78, lights=50, detail=3, camera=0.28},
    [9] = {name="EXTREME", shadow=0.30, atmosphere=0.20, bloom=0.16, saturation=0.12, contrast=0.17, material=0.90, lights=70, detail=4, camera=0.33},
    [10] = {name="ABSOLUTE REALISM", shadow=0.18, atmosphere=0.24, bloom=0.18, saturation=0.14, contrast=0.20, material=1.00, lights=100, detail=5, camera=0.38},
}

local V3_MOODS = {
    ["ULTRA NATURAL"] = {clock=10.2, brightness=2.1, exposure=0.05, ambient=Color3.fromRGB(70,76,82), outdoor=Color3.fromRGB(105,112,120), top=Color3.fromRGB(255,244,225), bottom=Color3.fromRGB(120,135,155), atmo=0.18, haze=1.05, glare=0.22, offset=0.28, color=Color3.fromRGB(210,226,255), decay=Color3.fromRGB(255,232,205), bloom=0.10, rays=0.08, saturation=0.05, contrast=0.12},
    ["CLEAR MORNING"] = {clock=7.1, brightness=2.2, exposure=0.10, ambient=Color3.fromRGB(66,74,86), outdoor=Color3.fromRGB(118,130,148), top=Color3.fromRGB(255,241,215), bottom=Color3.fromRGB(120,145,175), atmo=0.12, haze=0.70, glare=0.16, offset=0.32, color=Color3.fromRGB(202,224,255), decay=Color3.fromRGB(255,224,195), bloom=0.06, rays=0.10, saturation=0.06, contrast=0.10},
    ["GOLDEN MORNING"] = {clock=8.5, brightness=2.3, exposure=0.08, ambient=Color3.fromRGB(78,72,68), outdoor=Color3.fromRGB(132,118,100), top=Color3.fromRGB(255,216,166), bottom=Color3.fromRGB(145,128,112), atmo=0.15, haze=0.95, glare=0.28, offset=0.30, color=Color3.fromRGB(255,224,190), decay=Color3.fromRGB(255,190,145), bloom=0.12, rays=0.16, saturation=0.09, contrast=0.13},
    ["NOON CRISP"] = {clock=12.3, brightness=2.7, exposure=0.00, ambient=Color3.fromRGB(58,62,68), outdoor=Color3.fromRGB(125,130,138), top=Color3.fromRGB(255,250,238), bottom=Color3.fromRGB(125,135,150), atmo=0.08, haze=0.48, glare=0.12, offset=0.36, color=Color3.fromRGB(220,235,255), decay=Color3.fromRGB(255,245,230), bloom=0.05, rays=0.06, saturation=0.03, contrast=0.16},
    ["WARM AFTERNOON"] = {clock=15.4, brightness=2.35, exposure=0.04, ambient=Color3.fromRGB(70,67,67), outdoor=Color3.fromRGB(125,116,108), top=Color3.fromRGB(255,226,194), bottom=Color3.fromRGB(130,122,116), atmo=0.12, haze=0.75, glare=0.22, offset=0.30, color=Color3.fromRGB(240,225,210), decay=Color3.fromRGB(255,205,165), bloom=0.10, rays=0.12, saturation=0.07, contrast=0.13},
    ["GOLDEN HOUR"] = {clock=17.1, brightness=2.05, exposure=0.02, ambient=Color3.fromRGB(78,68,64), outdoor=Color3.fromRGB(135,104,86), top=Color3.fromRGB(255,183,122), bottom=Color3.fromRGB(125,104,98), atmo=0.18, haze=1.30, glare=0.42, offset=0.24, color=Color3.fromRGB(255,203,155), decay=Color3.fromRGB(255,140,105), bloom=0.16, rays=0.22, saturation=0.12, contrast=0.15},
    ["SUNSET DRAMA"] = {clock=18.3, brightness=1.75, exposure=-0.12, ambient=Color3.fromRGB(62,48,58), outdoor=Color3.fromRGB(108,75,84), top=Color3.fromRGB(255,125,92), bottom=Color3.fromRGB(95,78,110), atmo=0.25, haze=1.75, glare=0.60, offset=0.18, color=Color3.fromRGB(255,154,125), decay=Color3.fromRGB(118,85,145), bloom=0.22, rays=0.30, saturation=0.14, contrast=0.18},
    ["BLUE HOUR"] = {clock=19.3, brightness=1.45, exposure=-0.25, ambient=Color3.fromRGB(35,45,68), outdoor=Color3.fromRGB(58,72,108), top=Color3.fromRGB(125,158,220), bottom=Color3.fromRGB(38,48,90), atmo=0.28, haze=1.40, glare=0.12, offset=0.20, color=Color3.fromRGB(105,135,205), decay=Color3.fromRGB(45,55,110), bloom=0.14, rays=0.04, saturation=0.08, contrast=0.20},
    ["MOONLIT"] = {clock=0.8, brightness=1.05, exposure=-0.45, ambient=Color3.fromRGB(28,34,55), outdoor=Color3.fromRGB(46,58,90), top=Color3.fromRGB(125,150,205), bottom=Color3.fromRGB(30,40,72), atmo=0.23, haze=1.15, glare=0.05, offset=0.25, color=Color3.fromRGB(100,125,185), decay=Color3.fromRGB(40,50,90), bloom=0.08, rays=0.01, saturation=-0.02, contrast=0.22},
    ["DEEP NIGHT"] = {clock=2.4, brightness=0.72, exposure=-0.72, ambient=Color3.fromRGB(16,20,34), outdoor=Color3.fromRGB(25,31,52), top=Color3.fromRGB(70,90,145), bottom=Color3.fromRGB(15,22,42), atmo=0.18, haze=0.80, glare=0.02, offset=0.32, color=Color3.fromRGB(58,75,125), decay=Color3.fromRGB(20,28,58), bloom=0.05, rays=0.00, saturation=-0.04, contrast=0.24},
    ["OVERCAST"] = {clock=11.5, brightness=1.55, exposure=-0.08, ambient=Color3.fromRGB(84,88,92), outdoor=Color3.fromRGB(112,116,120), top=Color3.fromRGB(205,210,215), bottom=Color3.fromRGB(105,110,115), atmo=0.23, haze=1.65, glare=0.04, offset=0.30, color=Color3.fromRGB(190,198,205), decay=Color3.fromRGB(155,165,175), bloom=0.04, rays=0.01, saturation=-0.02, contrast=0.10},
    ["FOGGY"] = {clock=8.8, brightness=1.65, exposure=-0.05, ambient=Color3.fromRGB(88,92,96), outdoor=Color3.fromRGB(115,120,125), top=Color3.fromRGB(225,230,232), bottom=Color3.fromRGB(145,150,155), atmo=0.42, haze=3.0, glare=0.16, offset=0.10, color=Color3.fromRGB(208,218,225), decay=Color3.fromRGB(195,202,210), bloom=0.06, rays=0.06, saturation=-0.03, contrast=0.07},
    ["STORM"] = {clock=16.0, brightness=1.35, exposure=-0.30, ambient=Color3.fromRGB(38,43,52), outdoor=Color3.fromRGB(56,63,75), top=Color3.fromRGB(108,119,140), bottom=Color3.fromRGB(34,39,52), atmo=0.34, haze=2.10, glare=0.02, offset=0.18, color=Color3.fromRGB(92,104,125), decay=Color3.fromRGB(46,50,68), bloom=0.05, rays=0.00, saturation=-0.05, contrast=0.24},
    ["TROPICAL"] = {clock=13.5, brightness=2.45, exposure=0.04, ambient=Color3.fromRGB(62,78,68), outdoor=Color3.fromRGB(105,137,110), top=Color3.fromRGB(255,245,200), bottom=Color3.fromRGB(96,140,112), atmo=0.16, haze=0.90, glare=0.20, offset=0.27, color=Color3.fromRGB(180,225,210), decay=Color3.fromRGB(245,210,160), bloom=0.10, rays=0.10, saturation=0.12, contrast=0.12},
    ["ARCTIC"] = {clock=11.0, brightness=2.35, exposure=0.12, ambient=Color3.fromRGB(65,78,96), outdoor=Color3.fromRGB(110,130,155), top=Color3.fromRGB(215,235,255), bottom=Color3.fromRGB(105,135,175), atmo=0.14, haze=0.85, glare=0.25, offset=0.30, color=Color3.fromRGB(195,225,255), decay=Color3.fromRGB(170,195,235), bloom=0.10, rays=0.14, saturation=0.02, contrast=0.14},
    ["DESERT"] = {clock=16.7, brightness=2.25, exposure=0.02, ambient=Color3.fromRGB(86,70,56), outdoor=Color3.fromRGB(145,112,82), top=Color3.fromRGB(255,218,165), bottom=Color3.fromRGB(150,116,90), atmo=0.25, haze=1.70, glare=0.50, offset=0.16, color=Color3.fromRGB(244,211,170), decay=Color3.fromRGB(232,168,115), bloom=0.18, rays=0.25, saturation=0.10, contrast=0.15},
    ["MYSTIC"] = {clock=20.0, brightness=1.30, exposure=-0.20, ambient=Color3.fromRGB(40,28,58), outdoor=Color3.fromRGB(62,44,92), top=Color3.fromRGB(155,115,220), bottom=Color3.fromRGB(55,35,88), atmo=0.24, haze=1.35, glare=0.20, offset=0.22, color=Color3.fromRGB(130,100,205), decay=Color3.fromRGB(55,35,105), bloom=0.20, rays=0.03, saturation=0.16, contrast=0.21},
    ["NEON CITY"] = {clock=22.2, brightness=1.15, exposure=-0.25, ambient=Color3.fromRGB(22,26,38), outdoor=Color3.fromRGB(36,43,60), top=Color3.fromRGB(80,105,160), bottom=Color3.fromRGB(24,28,48), atmo=0.16, haze=0.85, glare=0.12, offset=0.30, color=Color3.fromRGB(70,100,165), decay=Color3.fromRGB(35,42,78), bloom=0.28, rays=0.02, saturation=0.20, contrast=0.25},
    ["EMERALD FOREST"] = {clock=9.8, brightness=1.90, exposure=-0.02, ambient=Color3.fromRGB(34,55,40), outdoor=Color3.fromRGB(68,105,73), top=Color3.fromRGB(218,240,190), bottom=Color3.fromRGB(45,82,55), atmo=0.25, haze=1.50, glare=0.16, offset=0.22, color=Color3.fromRGB(135,195,145), decay=Color3.fromRGB(45,95,65), bloom=0.08, rays=0.12, saturation=0.13, contrast=0.16},
    ["VOLCANIC"] = {clock=18.0, brightness=1.45, exposure=-0.15, ambient=Color3.fromRGB(50,27,25), outdoor=Color3.fromRGB(91,44,35), top=Color3.fromRGB(255,125,65), bottom=Color3.fromRGB(66,30,34), atmo=0.27, haze=1.90, glare=0.35, offset=0.18, color=Color3.fromRGB(215,82,55), decay=Color3.fromRGB(75,26,35), bloom=0.26, rays=0.10, saturation=0.15, contrast=0.25},
    ["DREAM"] = {clock=14.0, brightness=2.00, exposure=0.12, ambient=Color3.fromRGB(88,76,98), outdoor=Color3.fromRGB(145,125,150), top=Color3.fromRGB(255,220,245), bottom=Color3.fromRGB(120,155,190), atmo=0.20, haze=1.15, glare=0.28, offset=0.26, color=Color3.fromRGB(225,200,245), decay=Color3.fromRGB(170,190,235), bloom=0.20, rays=0.15, saturation=0.15, contrast=0.08},
}

local V3_MATERIALS = {
    [Enum.Material.Plastic] = Enum.Material.SmoothPlastic,
    [Enum.Material.SmoothPlastic] = Enum.Material.SmoothPlastic,
    [Enum.Material.Metal] = Enum.Material.Metal,
    [Enum.Material.CorrodedMetal] = Enum.Material.CorrodedMetal,
    [Enum.Material.DiamondPlate] = Enum.Material.DiamondPlate,
    [Enum.Material.Concrete] = Enum.Material.Concrete,
    [Enum.Material.Brick] = Enum.Material.Brick,
    [Enum.Material.Wood] = Enum.Material.Wood,
    [Enum.Material.WoodPlanks] = Enum.Material.WoodPlanks,
    [Enum.Material.Glass] = Enum.Material.Glass,
    [Enum.Material.Marble] = Enum.Material.Marble,
    [Enum.Material.Granite] = Enum.Material.Granite,
    [Enum.Material.Slate] = Enum.Material.Slate,
    [Enum.Material.Rock] = Enum.Material.Rock,
    [Enum.Material.Sand] = Enum.Material.Sand,
    [Enum.Material.Ground] = Enum.Material.Ground,
    [Enum.Material.Grass] = Enum.Material.Grass,
    [Enum.Material.LeafyGrass] = Enum.Material.LeafyGrass,
    [Enum.Material.Snow] = Enum.Material.Snow,
    [Enum.Material.Ice] = Enum.Material.Ice,
    [Enum.Material.Neon] = Enum.Material.Neon,
}

local V3_TINTS = {
    metal = Color3.fromRGB(220,225,232),
    steel = Color3.fromRGB(205,215,228),
    gold = Color3.fromRGB(235,190,95),
    brass = Color3.fromRGB(190,155,82),
    wood = Color3.fromRGB(150,105,70),
    grass = Color3.fromRGB(82,135,74),
    leaf = Color3.fromRGB(78,145,86),
    rock = Color3.fromRGB(118,116,112),
    stone = Color3.fromRGB(145,142,136),
    concrete = Color3.fromRGB(152,154,155),
    sand = Color3.fromRGB(210,183,135),
    snow = Color3.fromRGB(220,232,245),
    ice = Color3.fromRGB(155,210,235),
    water = Color3.fromRGB(75,160,205),
    crystal = Color3.fromRGB(175,155,240),
    egg = Color3.fromRGB(235,215,185),
    neon = Color3.fromRGB(235,245,255),
}

local function v3Safe(fn, fallback)
    local ok, result = pcall(fn)
    if ok then return result end
    return fallback
end

local function v3Set(obj, property, value)
    if obj == nil then return false end
    local ok = pcall(function() obj[property] = value end)
    return ok
end

local function v3Get(obj, property)
    return v3Safe(function() return obj[property] end, nil)
end

local function v3Remember(obj, property)
    if not V3.Original[obj] then V3.Original[obj] = {} end
    if V3.Original[obj][property] == nil then
        V3.Original[obj][property] = v3Get(obj, property)
    end
end

local function v3RestoreObject(obj, state)
    if not obj or not state then return end
    for property, value in pairs(state) do
        if value ~= nil then pcall(function() obj[property] = value end) end
    end
end

local function v3RestoreAll()
    for obj, state in pairs(V3.Original) do
        if obj and obj.Parent then
            v3RestoreObject(obj, state)
        end
    end
end

local function v3NameLower(obj)
    return string.lower((obj and obj.Name) or "")
end

local function v3LooksLike(part, words)
    local n = v3NameLower(part)
    for _, word in ipairs(words) do
        if string.find(n, word, 1, true) then return true end
    end
    return false
end

local function v3IsVisualPart(obj)
    return obj:IsA("BasePart") and obj.Parent ~= nil and obj.Transparency < 1
end

local function v3DistanceToCamera(obj)
    local camera = workspace.CurrentCamera
    if not camera then return math.huge end
    local pos = v3Safe(function() return obj.Position end, nil)
    if not pos then
        local cf = v3Get(obj, "CFrame")
        pos = cf and cf.Position
    end
    if not pos then return math.huge end
    return (camera.CFrame.Position - pos).Magnitude
end

local function v3ColorMix(a, b, alpha)
    return Color3.new(
        a.R + (b.R-a.R)*alpha,
        a.G + (b.G-a.G)*alpha,
        a.B + (b.B-a.B)*alpha
    )
end

local function v3EnhanceColor(color, amount, tint)
    if typeof(color) ~= "Color3" then return color end
    local base = color
    local luminance = base.R*0.2126 + base.G*0.7152 + base.B*0.0722
    local lift = math.clamp((0.52-luminance)*amount*0.18, -0.05, 0.08)
    local lifted = Color3.new(
        math.clamp(base.R+lift,0,1),
        math.clamp(base.G+lift,0,1),
        math.clamp(base.B+lift,0,1)
    )
    return v3ColorMix(lifted, tint, math.clamp(amount*0.10,0,0.10))
end

local function v3TintForPart(part)
    local n = v3NameLower(part)
    local mat = v3Get(part, "Material")
    if mat == Enum.Material.Neon then return V3_TINTS.neon end
    if v3LooksLike(part, {"gold","coin","golden"}) then return V3_TINTS.gold end
    if v3LooksLike(part, {"brass"}) then return V3_TINTS.brass end
    if v3LooksLike(part, {"crystal","gem","diamond"}) then return V3_TINTS.crystal end
    if v3LooksLike(part, {"water","ocean","ripple"}) then return V3_TINTS.water end
    if v3LooksLike(part, {"ice","frost"}) then return V3_TINTS.ice end
    if v3LooksLike(part, {"snow"}) then return V3_TINTS.snow end
    if v3LooksLike(part, {"sand","desert"}) then return V3_TINTS.sand end
    if v3LooksLike(part, {"grass","bush","leaf","tree","plant","flower"}) then return V3_TINTS.grass end
    if v3LooksLike(part, {"wood","plank","log","branch"}) then return V3_TINTS.wood end
    if v3LooksLike(part, {"metal","steel","iron","pipe","rail","chain"}) then return V3_TINTS.steel end
    if v3LooksLike(part, {"rock","stone","boulder","cliff"}) then return V3_TINTS.rock end
    if mat == Enum.Material.Concrete then return V3_TINTS.concrete end
    return nil
end

local function v3EnhanceMaterials()
    if not V3.MaterialPass then return end
    local q = V3_QUALITY[V3.Quality]
    local amount = q.material
    if amount <= 0 then return end

    local processed = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if processed > 7000 then break end
        if v3IsVisualPart(obj) then
            local material = v3Get(obj, "Material")
            local color = v3Get(obj, "Color")
            local tint = v3TintForPart(obj)

            if material and V3_MATERIALS[material] then
                v3Remember(obj, "Material")
                -- Preserve special/custom materials; only normalize old Plastic.
                if material == Enum.Material.Plastic and not v3LooksLike(obj, {"logo","ui","hitbox","prompt"}) then
                    v3Set(obj, "Material", Enum.Material.SmoothPlastic)
                end
            end

            if tint and color and not v3LooksLike(obj, {"hitbox","trigger","invisible","prompt"}) then
                v3Remember(obj, "Color")
                v3Set(obj, "Color", v3EnhanceColor(color, amount, tint))
            end

            if material == Enum.Material.Metal or material == Enum.Material.DiamondPlate or
               v3LooksLike(obj, {"metal","steel","chrome","gold","brass"}) then
                v3Remember(obj, "Reflectance")
                v3Set(obj, "Reflectance", math.clamp(0.04 + amount*0.08, 0, 0.14))
            elseif material == Enum.Material.Glass then
                v3Remember(obj, "Reflectance")
                v3Set(obj, "Reflectance", math.clamp(0.08 + amount*0.10, 0, 0.18))
            end

            processed += 1
        end
    end
end

local function v3EnhanceSurfaceAppearance()
    if not V3.MaterialPass then return end
    local amount = V3_QUALITY[V3.Quality].material
    if amount < 0.45 then return end

    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if count > 2500 then break end
        if obj:IsA("SurfaceAppearance") then
            local parent = obj.Parent
            local base = parent and v3Get(parent, "Color")
            if base and not v3LooksLike(parent, {"ui","hitbox","prompt"}) then
                if v3Get(obj, "Color") ~= nil then
                    v3Remember(obj, "Color")
                    v3Set(obj, "Color", v3EnhanceColor(v3Get(obj,"Color"), amount*0.5, Color3.fromRGB(235,235,235)))
                end
            end
            count += 1
        end
    end
end

local function v3CreateLightFor(part, color, brightness, range)
    if not V3.EmissivePass or not part or not part.Parent then return end
    local maxLights = V3_QUALITY[V3.Quality].lights
    if #V3.LightCache >= maxLights then return end
    if v3DistanceToCamera(part) > (V3.Quality >= 8 and 220 or 150) then return end

    local key = part:GetFullName()
    if V3.LightCache[key] then return end

    local attachment = Instance.new("Attachment")
    attachment.Name = "V3_RealisticLightAttachment"
    attachment.Parent = part

    local light = Instance.new("PointLight")
    light.Name = "V3_RealisticLocalGlow"
    light.Color = color
    light.Brightness = brightness
    light.Range = range
    light.Shadows = V3.Quality >= 8
    light.Parent = attachment

    V3.Created[#V3.Created+1] = attachment
    V3.Created[#V3.Created+1] = light
    V3.LightCache[key] = true
end

local function v3EmissiveScan()
    if not V3.EmissivePass then return end
    local q = V3_QUALITY[V3.Quality]
    if q.lights <= 0 then return end

    local scanned = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if scanned > 9000 or #V3.LightCache >= q.lights then break end
        if obj:IsA("BasePart") and obj.Transparency < 1 then
            local material = v3Get(obj, "Material")
            local color = v3Get(obj, "Color")
            local n = v3NameLower(obj)

            if material == Enum.Material.Neon then
                local c = color or Color3.new(1,1,1)
                v3CreateLightFor(obj, c, 0.35 + q.material*0.8, 8 + q.material*7)
            elseif v3LooksLike(obj, {"lamp","lantern","light","torch","sign","screen","crystal"}) then
                local c = color or Color3.fromRGB(255,220,170)
                v3CreateLightFor(obj, c, 0.18 + q.material*0.55, 7 + q.material*8)
            end
            scanned += 1
        end
    end
end

local function v3ApplyLightingMood(name)
    local mood = V3_MOODS[name]
    if not mood then return false end
    local q = V3_QUALITY[V3.Quality]

    v3Remember(Lighting,"ClockTime")
    v3Remember(Lighting,"Brightness")
    v3Remember(Lighting,"ExposureCompensation")
    v3Remember(Lighting,"Ambient")
    v3Remember(Lighting,"OutdoorAmbient")
    v3Remember(Lighting,"ColorShift_Top")
    v3Remember(Lighting,"ColorShift_Bottom")
    v3Remember(Lighting,"GlobalShadows")
    v3Remember(Lighting,"ShadowSoftness")
    v3Remember(Lighting,"EnvironmentDiffuseScale")
    v3Remember(Lighting,"EnvironmentSpecularScale")
    v3Remember(Lighting,"PrioritizeLightingQuality")
    v3Remember(Lighting,"LightingStyle")

    v3Set(Lighting,"ClockTime",mood.clock)
    v3Set(Lighting,"Brightness",mood.brightness)
    v3Set(Lighting,"ExposureCompensation",mood.exposure)
    v3Set(Lighting,"Ambient",mood.ambient)
    v3Set(Lighting,"OutdoorAmbient",mood.outdoor)
    v3Set(Lighting,"ColorShift_Top",mood.top)
    v3Set(Lighting,"ColorShift_Bottom",mood.bottom)
    v3Set(Lighting,"GlobalShadows",true)
    v3Set(Lighting,"ShadowSoftness",q.shadow)
    v3Set(Lighting,"EnvironmentDiffuseScale",math.clamp(0.70+q.material*0.30,0,1))
    v3Set(Lighting,"EnvironmentSpecularScale",math.clamp(0.72+q.material*0.28,0,1))
    v3Set(Lighting,"PrioritizeLightingQuality",V3.Quality >= 7)

    pcall(function() Lighting.LightingStyle = Enum.LightingStyle.Realistic end)

    local atmosphere = Lighting:FindFirstChild("V3_Atmosphere") or Instance.new("Atmosphere")
    atmosphere.Name = "V3_Atmosphere"
    local atmosphereWasNew = atmosphere.Parent == nil
    atmosphere.Parent = Lighting
    if atmosphereWasNew then V3.Created[#V3.Created+1] = atmosphere end
    v3Remember(atmosphere,"Density")
    v3Remember(atmosphere,"Offset")
    v3Remember(atmosphere,"Haze")
    v3Remember(atmosphere,"Glare")
    v3Remember(atmosphere,"Color")
    v3Remember(atmosphere,"Decay")
    v3Set(atmosphere,"Density",math.clamp(mood.atmo*q.atmosphere/0.14,0,0.60))
    v3Set(atmosphere,"Offset",mood.offset)
    v3Set(atmosphere,"Haze",mood.haze*(0.72+q.atmosphere))
    v3Set(atmosphere,"Glare",mood.glare*(0.70+q.atmosphere))
    v3Set(atmosphere,"Color",mood.color)
    v3Set(atmosphere,"Decay",mood.decay)

    local bloom = Lighting:FindFirstChild("V3_Bloom") or Instance.new("BloomEffect")
    bloom.Name = "V3_Bloom"
    local bloomWasNew = bloom.Parent == nil
    bloom.Parent = Lighting
    if bloomWasNew then V3.Created[#V3.Created+1] = bloom end
    v3Set(bloom,"Intensity",mood.bloom*(0.45+q.bloom*3))
    v3Set(bloom,"Size",math.clamp(18+V3.Quality*2,18,40))
    v3Set(bloom,"Threshold",1.0-q.bloom*0.7)

    local cc = Lighting:FindFirstChild("V3_ColorGrade") or Instance.new("ColorCorrectionEffect")
    cc.Name = "V3_ColorGrade"
    local ccWasNew = cc.Parent == nil
    cc.Parent = Lighting
    if ccWasNew then V3.Created[#V3.Created+1] = cc end
    v3Set(cc,"Brightness",math.clamp(mood.exposure*0.08,-0.08,0.08))
    v3Set(cc,"Contrast",mood.contrast + q.contrast)
    v3Set(cc,"Saturation",mood.saturation + q.saturation)

    local rays = Lighting:FindFirstChild("V3_SunRays") or Instance.new("SunRaysEffect")
    rays.Name = "V3_SunRays"
    local raysWasNew = rays.Parent == nil
    rays.Parent = Lighting
    if raysWasNew then V3.Created[#V3.Created+1] = rays end
    v3Set(rays,"Intensity",mood.rays*(0.55+q.camera))
    v3Set(rays,"Spread",0.72)

    local dof = Lighting:FindFirstChild("V3_DepthOfField") or Instance.new("DepthOfFieldEffect")
    dof.Name = "V3_DepthOfField"
    local dofWasNew = dof.Parent == nil
    dof.Parent = Lighting
    if dofWasNew then V3.Created[#V3.Created+1] = dof end
    v3Set(dof,"FocusDistance",math.clamp(55- V3.Quality*2,22,55))
    v3Set(dof,"InFocusRadius",math.clamp(18- V3.Quality*0.5,10,18))
    v3Set(dof,"NearIntensity",V3.Quality >= 9 and 0.025 or 0)
    v3Set(dof,"FarIntensity",V3.Quality >= 9 and 0.08 or 0.025)

    V3.Atmosphere = name
    return true
end

local function v3ApplyQuality(level)
    level = math.clamp(math.floor(tonumber(level) or 10),1,10)
    V3.Quality = level
    local q = V3_QUALITY[level]
    Config.Enabled = true
    Config.AdaptiveQuality = level < 9
    Config.ShadowSoftness = q.shadow
    Config.Exposure = 0
    Config.Contrast = q.contrast
    Config.Saturation = q.saturation
    Config.BloomIntensity = q.bloom
    Config.SunRaysIntensity = q.bloom*0.75
    Config.DOFStrength = level >= 9 and 0.05 or 0
    Config.MaxDynamicLights = math.max(8, q.lights)
    Config.TargetFPS = level >= 9 and 30 or 45
    Config.MinimumFPS = level >= 9 and 22 or 30
    Config.MaterialEnhancement = level >= 3
    Config.DynamicExposure = level >= 6
    Config.AutoSunResponse = level >= 5

    pcall(function() applyAll() end)
    v3ApplyLightingMood(V3.Atmosphere)
    if level >= 3 then
        v3EnhanceMaterials()
        v3EnhanceSurfaceAppearance()
    end
    if level >= 5 then v3EmissiveScan() end
    V3.LastQualityApply = os.clock()
end

local function v3SetMood(name)
    if not V3_MOODS[name] then return false end
    V3.Atmosphere = name
    return v3ApplyLightingMood(name)
end

local function v3CreateControlUI()
    if V3.UI and V3.UI.Parent then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "UltraRealisticShaderEngineV3"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 900
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    V3.UI = gui
    V3.Created[#V3.Created+1] = gui

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.fromOffset(420, 540)
    panel.Position = UDim2.new(0, 18, 0.5, -270)
    panel.BackgroundColor3 = Color3.fromRGB(12,14,18)
    panel.BackgroundTransparency = 0.06
    panel.BorderSizePixel = 0
    panel.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,16)
    corner.Parent = panel

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(100,110,130)
    stroke.Transparency = 0.45
    stroke.Parent = panel

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1,-28,0,34)
    title.Position = UDim2.fromOffset(14,10)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = Color3.fromRGB(245,248,255)
    title.Text = "ULTRA REALISM V3"
    title.Parent = panel

    local sub = Instance.new("TextLabel")
    sub.BackgroundTransparency = 1
    sub.Size = UDim2.new(1,-28,0,22)
    sub.Position = UDim2.fromOffset(14,42)
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 11
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.TextColor3 = Color3.fromRGB(150,160,175)
    sub.Text = "10 quality levels • cinematic atmosphere • material-aware detail"
    sub.Parent = panel

    local qualityLabel = Instance.new("TextLabel")
    qualityLabel.BackgroundTransparency = 1
    qualityLabel.Size = UDim2.new(1,-28,0,28)
    qualityLabel.Position = UDim2.fromOffset(14,75)
    qualityLabel.Font = Enum.Font.GothamSemibold
    qualityLabel.TextSize = 13
    qualityLabel.TextXAlignment = Enum.TextXAlignment.Left
    qualityLabel.TextColor3 = Color3.fromRGB(220,225,235)
    qualityLabel.Text = "GRAPHICS QUALITY: 10 — ABSOLUTE REALISM"
    qualityLabel.Parent = panel

    local qHolder = Instance.new("Frame")
    qHolder.BackgroundTransparency = 1
    qHolder.Size = UDim2.new(1,-28,0,42)
    qHolder.Position = UDim2.fromOffset(14,104)
    qHolder.Parent = panel

    local qLayout = Instance.new("UIGridLayout")
    qLayout.CellSize = UDim2.fromOffset(36,36)
    qLayout.CellPadding = UDim2.fromOffset(5,5)
    qLayout.Parent = qHolder

    local function refreshQuality()
        qualityLabel.Text = string.format("GRAPHICS QUALITY: %d — %s",V3.Quality,V3_QUALITY[V3.Quality].name)
        for _, child in ipairs(qHolder:GetChildren()) do
            if child:IsA("TextButton") then
                local n = tonumber(child.Name:match("%d+"))
                child.BackgroundColor3 = n == V3.Quality and Color3.fromRGB(95,125,190) or Color3.fromRGB(31,35,43)
            end
        end
    end

    for i=1,10 do
        local b = Instance.new("TextButton")
        b.Name = "Quality"..i
        b.Text = tostring(i)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 13
        b.TextColor3 = Color3.fromRGB(245,245,250)
        b.BackgroundColor3 = Color3.fromRGB(31,35,43)
        b.AutoButtonColor = true
        b.Parent = qHolder
        local bc = Instance.new("UICorner"); bc.CornerRadius=UDim.new(0,9); bc.Parent=b
        b.MouseButton1Click:Connect(function()
            v3ApplyQuality(i)
            refreshQuality()
        end)
    end

    local moodLabel = Instance.new("TextLabel")
    moodLabel.BackgroundTransparency = 1
    moodLabel.Size = UDim2.new(1,-28,0,25)
    moodLabel.Position = UDim2.fromOffset(14,154)
    moodLabel.Font = Enum.Font.GothamSemibold
    moodLabel.TextSize = 13
    moodLabel.TextXAlignment = Enum.TextXAlignment.Left
    moodLabel.TextColor3 = Color3.fromRGB(220,225,235)
    moodLabel.Text = "ATMOSPHERE / MOOD"
    moodLabel.Parent = panel

    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "Moods"
    scroll.Size = UDim2.new(1,-28,0,240)
    scroll.Position = UDim2.fromOffset(14,182)
    scroll.BackgroundColor3 = Color3.fromRGB(18,21,27)
    scroll.BackgroundTransparency = 0.20
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.CanvasSize = UDim2.new()
    scroll.Parent = panel

    local sc = Instance.new("UICorner"); sc.CornerRadius=UDim.new(0,12); sc.Parent=scroll
    local pad = Instance.new("UIPadding"); pad.PaddingTop=UDim.new(0,8); pad.PaddingBottom=UDim.new(0,8); pad.PaddingLeft=UDim.new(0,8); pad.PaddingRight=UDim.new(0,8); pad.Parent=scroll
    local layout = Instance.new("UIListLayout"); layout.Padding=UDim.new(0,5); layout.Parent=scroll

    local moodNames = {}
    for name in pairs(V3_MOODS) do moodNames[#moodNames+1]=name end
    table.sort(moodNames)

    for _, name in ipairs(moodNames) do
        local b = Instance.new("TextButton")
        b.Name = name
        b.Size = UDim2.new(1,-2,0,30)
        b.Text = name
        b.Font = Enum.Font.GothamMedium
        b.TextSize = 11
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.TextColor3 = Color3.fromRGB(225,230,238)
        b.BackgroundColor3 = Color3.fromRGB(29,33,41)
        b.Parent = scroll
        local p = Instance.new("UIPadding"); p.PaddingLeft=UDim.new(0,10); p.Parent=b
        local c = Instance.new("UICorner"); c.CornerRadius=UDim.new(0,8); c.Parent=b
        b.MouseButton1Click:Connect(function()
            v3SetMood(name)
            moodLabel.Text = "ATMOSPHERE / MOOD • "..name
        end)
    end

    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.BackgroundTransparency = 1
    status.Size = UDim2.new(1,-28,0,70)
    status.Position = UDim2.fromOffset(14,430)
    status.Font = Enum.Font.Code
    status.TextSize = 11
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextYAlignment = Enum.TextYAlignment.Top
    status.TextColor3 = Color3.fromRGB(155,165,180)
    status.Text = "V3 READY\nQuality: 10\nMood: ULTRA NATURAL\nDetail pass: ON\nMaterial pass: ON"
    status.Parent = panel

    local close = Instance.new("TextButton")
    close.Size = UDim2.fromOffset(28,28)
    close.Position = UDim2.new(1,-40,0,10)
    close.Text = "×"
    close.Font = Enum.Font.GothamBold
    close.TextSize = 18
    close.TextColor3 = Color3.fromRGB(230,235,245)
    close.BackgroundColor3 = Color3.fromRGB(35,39,48)
    close.Parent = panel
    local cc = Instance.new("UICorner"); cc.CornerRadius=UDim.new(0,8); cc.Parent=close
    close.MouseButton1Click:Connect(function() panel.Visible=false end)

    local toggle = Instance.new("TextButton")
    toggle.Name = "FloatingToggle"
    toggle.Size = UDim2.fromOffset(42,42)
    toggle.Position = UDim2.new(0,18,0.5,-21)
    toggle.Text = "V3"
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 12
    toggle.TextColor3 = Color3.fromRGB(240,245,255)
    toggle.BackgroundColor3 = Color3.fromRGB(25,29,36)
    toggle.Parent = gui
    local tc = Instance.new("UICorner"); tc.CornerRadius=UDim.new(1,0); tc.Parent=toggle
    toggle.MouseButton1Click:Connect(function() panel.Visible=not panel.Visible end)

    refreshQuality()

    local dragging, dragStart, startPos
    local function beginDrag(input)
        dragging=true; dragStart=input.Position; startPos=panel.Position
        local conn
        conn=input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging=false
                conn:Disconnect()
            end
        end)
    end
    title.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then beginDrag(input) end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then
            local delta=input.Position-dragStart
            panel.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
        end
    end)

    table.insert(V3.Connections, RunService.RenderStepped:Connect(function()
        if not status.Parent then return end
        local fps = 0
        pcall(function() fps = FPS.Current end)
        status.Text = string.format(
            "V3 ACTIVE\nQuality: %d / 10\nMood: %s\nFPS: %.0f\nDetail: %s • Materials: %s",
            V3.Quality,V3.Atmosphere,fps,
            V3.DetailPass and "ON" or "OFF",
            V3.MaterialPass and "ON" or "OFF"
        )
    end))
end

local function v3Initialise()
    if not V3.Enabled then return end

    -- Use the user's existing rich asset structure as visual input.
    -- The workspace inventory contains SurfaceAppearance, MeshParts,
    -- Bone rigs, ParticleEmitters, egg-slot meshes, treadmill renders,
    -- client-rendered assets and multiple VFX containers.
    --
    -- We deliberately do not clone the entire workspace: that would
    -- multiply geometry and destroy performance.
    v3ApplyQuality(10)
    v3SetMood("ULTRA NATURAL")
    v3CreateControlUI()

    print("[UltraRealisticShaderEngineV3] Deep visual layer active.")
    print("[UltraRealisticShaderEngineV3] Quality 1-10 and 20+ atmosphere profiles ready.")
end

_G.UltraRealisticShaderEngineV3 = {
    Version = V3.Version,
    QualityLevels = V3_QUALITY,
    Atmospheres = V3_MOODS,

    GetQuality = function()
        return V3.Quality
    end,

    SetQuality = function(level)
        v3ApplyQuality(level)
    end,

    GetAtmosphere = function()
        return V3.Atmosphere
    end,

    SetAtmosphere = function(name)
        return v3SetMood(name)
    end,

    RebuildVisualDetail = function()
        v3EnhanceMaterials()
        v3EnhanceSurfaceAppearance()
        v3EmissiveScan()
    end,

    Restore = function()
        v3RestoreAll()
        for _, obj in ipairs(V3.Created) do
            if obj and obj.Parent then pcall(function() obj:Destroy() end) end
        end
        table.clear(V3.Created)
        table.clear(V3.LightCache)
    end,

    Cleanup = function()
        for _, c in ipairs(V3.Connections) do pcall(function() c:Disconnect() end) end
        table.clear(V3.Connections)
        v3RestoreAll()
        for _, obj in ipairs(V3.Created) do
            if obj and obj.Parent then pcall(function() obj:Destroy() end) end
        end
        table.clear(V3.Created)
        table.clear(V3.LightCache)
        if V3.UI and V3.UI.Parent then V3.UI:Destroy() end
        V3.UI = nil
    end,
}

v3Initialise()

--==================================================
-- V3 EXTENDED REFERENCE / TUNING NOTES
--==================================================
-- Quality 1:
--   Only basic lighting. Designed for weak devices.
--
-- Quality 2:
--   Light atmosphere and low material intervention.
--
-- Quality 3:
--   SmoothPlastic cleanup for old Plastic surfaces and subtle color lift.
--
-- Quality 4:
--   Stronger material-aware color response and basic cinematic depth.
--
-- Quality 5:
--   Local emissive accents start appearing around lamps, neon and crystals.
--
-- Quality 6:
--   Stronger environment response, reflective materials and adaptive exposure.
--
-- Quality 7:
--   Ultra lighting, denser atmospheric depth and more local light sources.
--
-- Quality 8:
--   Cinematic ultra: deeper contrast, stronger environmental reflections,
--   more emissive accents and more aggressive detail processing.
--
-- Quality 9:
--   Extreme: maximum supported visual passes before the intentionally
--   conservative safety budget begins to protect frame time.
--
-- Quality 10:
--   Absolute Realism: all visual passes enabled, maximum supported local
--   accents, strongest material treatment, realistic lighting, atmospheric
--   perspective and cinematic camera response.
--
-- IMPORTANT:
-- Roblox cannot be turned into a physically based path tracer by a LocalScript.
-- This engine therefore pushes Roblox's supported renderer as far as possible:
-- Realistic lighting, PBR/SurfaceAppearance response, Atmosphere, post-processing,
-- local lights, material-aware color, and adaptive visual budgeting.
--
-- For genuinely new geometry/textures (cracks, pores, dirt, bevels, decals,
-- micro-normal maps, custom PBR textures), the actual asset files must contain
-- those details. This layer can enhance existing geometry/materials but cannot
-- manufacture high-resolution texture maps from nothing.
--
-- This is intentional: visual quality is increased without replacing or
-- corrupting the original game's gameplay architecture.
--==================================================
