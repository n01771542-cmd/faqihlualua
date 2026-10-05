--[[
    LEON4951 SHADERS: EDISI KETENANGAN (THE SERENITY UPDATE)
    Roblox LocalScript | StarterPlayer > StarterPlayerScripts

    FILOSOFI VISUAL:
    1. MATAHARI DIAM: Waktu berhenti di sore hari. Bayangan panjang yang menenangkan.
    2. CAHAYA YANG BERJIWA: Saat menatap matahari, yang muncul bukan flare kasar, 
       melainkan hembusan sinar oranye-kuning yang halus, hangat, dan menyapu map.
    3. DETAIL BAYANGAN: ShadowSoftness diperkecil agar detail arsitektur dan alam 
       terlihat tajam, namun Ambient light dijaga agar tetap nyaman di mata.
    4. PALET WARNA: Dominasi Oranye, Amber, dan Kuning hangat. Sedikit lebih gelap 
       untuk menciptakan kedalaman (depth) dan suasana yang intim.
    5. INTEGRASI MAP: Semua efek (kabut, sinar, bloom) dirancang untuk berinteraksi 
       dengan geometri map, bukan sekadar tempelan di layar (ScreenGui).
]]

----------------------------------------------------------------
-- SERVICES
----------------------------------------------------------------
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Terrain = Workspace:WaitForChild("Terrain")

local ROOT = "Leon4951Shaders_Serenity"
local PREFIX = "L4S_"
local rgb = Color3.fromRGB

----------------------------------------------------------------
-- BERSIHKAN VERSI LAMA
----------------------------------------------------------------
for _, globalName in ipairs({ "Leon4951Shaders", "VisualRealistis", "UltraRealisticRendererV4", "Leon4951Shaders_Serenity" }) do
    local old = _G[globalName]
    if old and old.Restore then pcall(old.Restore) end
end

for _, guiName in ipairs({ ROOT, ROOT .. "_Lensa", ROOT .. "_Atmos", "VisualRealistis", "UltraRealisticRendererV4" }) do
    local old = PlayerGui:FindFirstChild(guiName)
    if old then old:Destroy() end
end

for _, child in ipairs(Lighting:GetChildren()) do
    local n = child.Name
    if n:sub(1, 3) == "VR_" or n:sub(1, #PREFIX) == PREFIX or n:sub(1, 5) == "URV4_" then
        child:Destroy()
    end
end

for _, folderName in ipairs({ "VR_Dunia", "L4_Dunia", "L4S_Dunia" }) do
    local old = Workspace:FindFirstChild(folderName)
    if old then old:Destroy() end
end

local WorldFolder = Instance.new("Folder")
WorldFolder.Name = "L4S_Dunia"
WorldFolder.Parent = Workspace

----------------------------------------------------------------
-- HELPER FUNCTIONS
----------------------------------------------------------------
local function safe(fn, fallback)
    local ok, result = pcall(fn)
    return ok and result or fallback
end

local function setProperty(instance, property, value)
    if not instance then return false end
    return safe(function() instance[property] = value return true end, false)
end

local function getProperty(instance, property, fallback)
    if not instance then return fallback end
    return safe(function() return instance[property] end, fallback)
end

local function clamp01(v) return math.clamp(v, 0, 1) end
local function lerp(a, b, t) return a + (b - a) * t end
local function wetColor(c) return Color3.new(c.R * 0.72, c.G * 0.70, c.B * 0.66) end
local weakKeys = { __mode = "k" }

----------------------------------------------------------------
-- DATA ASLI (untuk Restore yang aman)
----------------------------------------------------------------
local Original = {
    Lighting = {},
    Parts = setmetatable({}, weakKeys),
    SurfaceAppearances = setmetatable({}, weakKeys),
    TerrainColors = {},
    HiddenAtmospheres = {},
    Created = {},
}

local function rememberLighting(property)
    if Original.Lighting[property] ~= nil then return end
    Original.Lighting[property] = getProperty(Lighting, property, nil)
end

local function rememberPart(part)
    if Original.Parts[part] then return end
    Original.Parts[part] = {
        Material = getProperty(part, "Material", nil),
        Color = getProperty(part, "Color", nil),
        Reflectance = getProperty(part, "Reflectance", nil),
        CastShadow = getProperty(part, "CastShadow", nil),
    }
end

local function rememberSurfaceAppearance(surface)
    if Original.SurfaceAppearances[surface] then return end
    Original.SurfaceAppearances[surface] = { Color = getProperty(surface, "Color", nil) }
end

----------------------------------------------------------------
-- PENGATURAN INTI
----------------------------------------------------------------
local Settings = {
    Quality = 9,                         -- 1 sampai 10 (Default tinggi untuk detail)
    StartMoods = { "Sore Keemasan" },
    ShowPanel = true,

    -- Matahari diam di satu titik dunia
    SunDistance = 1000,       -- Jauh agar efek perspektif lebih halus
    SunFalloff = 1.8,         -- Mengecil dengan sangat halus saat menjauh
    SunSize = 260,            -- Ukuran glow matahari yang proporsional dan lembut

    ShadowSoftness = 0.06,    -- Bayangan detail dan tajam, namun tetap natural

    MaxAccentLights = 80,
    LightDistance = 500,
    LightUpdateInterval = 0.12,

    -- Cahaya telur (malam) - hangat dan berdenyut pelan
    EggRange = 15,
    EggBrightness = 0.9,
    EggMaxLights = 48,
    EggDistance = 320,
    EggColor = rgb(255, 180, 90),
}

----------------------------------------------------------------
-- DAFTAR SUASANA (MOODS) - DIREVISI UNTUK KETENANGAN & DETAIL
----------------------------------------------------------------
local DEFAULT = {
    Shafts = 0, SunGlow = 0, Flare = 0, Sheen = 0, EggGlow = 0, Overlay = 0,
    OverlayTop = rgb(22, 9, 4), OverlayBottom = rgb(255, 140, 50),
    SunRaySpread = 0.85, SunRays = 0, BloomSize = 22, BloomThreshold = 1.1,
    ShadowSoftness = 0.15, ShaftColor = rgb(255, 210, 150),
}

local Moods = {
    {
        -- SORE KEEMASAN: Mahakarya utama. Oranye dominan, kuning halus, sedikit gelap, bayangan detail.
        Name = "Sore Keemasan",
        ClockTime = 17.35, 
        Brightness = 2.10, Exposure = -0.15, ShadowSoftness = 0.06, -- Bayangan sangat detail
        Density = 0.0065, Offset = 0.08, Haze = 0.25, Glare = 0.45, -- Atmosfer tebal dan hangat
        Color = rgb(255, 170, 70),       -- Oranye hangat dominan
        Decay = rgb(210, 90, 30),        -- Amber dalam di horizon
        Ambient = rgb(35, 20, 10),       -- Gelap hangat (bukan hitam mati)
        OutdoorAmbient = rgb(130, 75, 35),-- Pantulan cahaya oranye ke seluruh map
        Top = rgb(255, 150, 60), 
        Bottom = rgb(230, 110, 40),
        Bloom = 0.28, BloomSize = 28, BloomThreshold = 0.85, -- Bloom lembut dan luas
        SunRays = 0.35, SunRaySpread = 0.92, -- Sinar lembut yang menembus map
        Contrast = 0.18, Saturation = 0.12, 
        Tint = rgb(255, 225, 180),       -- Tint krem keemasan
        ShaftColor = rgb(255, 180, 80),
        Shafts = 1.0, SunGlow = 1.0, Flare = 1.2, Sheen = 0.15,
        Overlay = 0.7, OverlayTop = rgb(25, 12, 5), OverlayBottom = rgb(240, 130, 50),
        WarmBody = true,
        CloudColor = rgb(255, 160, 80), CloudCover = 0.4, CloudDensity = 0.45,
    },
    {
        Name = "Pagi Segar",
        ClockTime = 7.15, Brightness = 2.25, Exposure = 0.02, ShadowSoftness = 0.12,
        Density = 0.0045, Offset = 0.12, Haze = 0.15, Glare = 0.25,
        Color = rgb(230, 240, 255), Decay = rgb(255, 220, 180),
        Ambient = rgb(38, 40, 45), OutdoorAmbient = rgb(150, 160, 175),
        Top = rgb(240, 245, 255), Bottom = rgb(255, 230, 200),
        Bloom = 0.12, BloomSize = 24, BloomThreshold = 1.05,
        SunRays = 0.15, SunRaySpread = 0.88,
        Contrast = 0.10, Saturation = 0.05, Tint = rgb(250, 252, 255),
        ShaftColor = rgb(255, 235, 200),
        Shafts = 0.6, SunGlow = 0.7, Flare = 0.4, Sheen = 0.05,
    },
    {
        Name = "Siang Lembut",
        ClockTime = 12.5, Brightness = 2.30, Exposure = 0.04, ShadowSoftness = 0.10,
        Density = 0.0035, Offset = 0.18, Haze = 0.08, Glare = 0.10,
        Color = rgb(245, 248, 255), Decay = rgb(230, 235, 245),
        Ambient = rgb(40, 42, 48), OutdoorAmbient = rgb(160, 165, 175),
        Top = rgb(250, 252, 255), Bottom = rgb(245, 240, 230),
        Bloom = 0.08, BloomSize = 20, BloomThreshold = 1.15,
        SunRays = 0.08, SunRaySpread = 0.80,
        Contrast = 0.12, Saturation = 0.04, Tint = rgb(255, 255, 255),
        Shafts = 0.3, SunGlow = 0.5, Flare = 0.3, Sheen = 0.04,
    },
    {
        Name = "Senja Jingga",
        ClockTime = 18.10, Brightness = 1.90, Exposure = -0.08, ShadowSoftness = 0.08,
        Density = 0.0070, Offset = 0.06, Haze = 0.30, Glare = 0.50,
        Color = rgb(255, 150, 80), Decay = rgb(190, 70, 30),
        Ambient = rgb(30, 15, 10), OutdoorAmbient = rgb(110, 60, 30),
        Top = rgb(255, 130, 70), Bottom = rgb(210, 90, 40),
        Bloom = 0.32, BloomSize = 30, BloomThreshold = 0.80,
        SunRays = 0.40, SunRaySpread = 0.95,
        Contrast = 0.20, Saturation = 0.15, Tint = rgb(255, 210, 170),
        ShaftColor = rgb(255, 160, 70),
        Shafts = 0.9, SunGlow = 1.0, Flare = 1.0, Sheen = 0.10,
        Overlay = 0.6, OverlayTop = rgb(20, 8, 5), OverlayBottom = rgb(230, 110, 50),
        CloudColor = rgb(240, 130, 80), CloudCover = 0.5, CloudDensity = 0.5,
        EggGlow = 0.4,
    },
    {
        Fx = true, Name = "Kabut Halus",
        ClockTime = 9.0, Brightness = 1.60, Exposure = -0.10, ShadowSoftness = 0.25,
        Density = 0.0080, Offset = 0.02, Haze = 0.40, Glare = 0.15,
        Color = rgb(210, 215, 225), Decay = rgb(180, 185, 200),
        Ambient = rgb(35, 38, 42), OutdoorAmbient = rgb(100, 105, 115),
        Top = rgb(220, 225, 235), Bottom = rgb(190, 195, 205),
        Bloom = 0.06, BloomSize = 26, BloomThreshold = 1.15,
        Contrast = 0.08, Saturation = -0.02, Tint = rgb(235, 240, 245),
        Shafts = 0.5, SunGlow = 0.3, Flare = 0.1,
        Overlay = 0.3, OverlayTop = rgb(40, 45, 50), OverlayBottom = rgb(150, 160, 170),
        CloudColor = rgb(200, 205, 215), CloudCover = 0.8, CloudDensity = 0.7,
        EggGlow = 0.3,
    },
    {
        Fx = true, Name = "Hujan Tenang",
        ClockTime = 15.0, Brightness = 1.40, Exposure = -0.12, ShadowSoftness = 0.30,
        Density = 0.0090, Offset = 0.00, Haze = 0.35, Glare = 0.05,
        Color = rgb(180, 190, 205), Decay = rgb(140, 150, 170),
        Ambient = rgb(30, 35, 40), OutdoorAmbient = rgb(90, 100, 115),
        Top = rgb(190, 200, 215), Bottom = rgb(150, 160, 175),
        Bloom = 0.05, BloomSize = 22, BloomThreshold = 1.20,
        Contrast = 0.10, Saturation = -0.05, Tint = rgb(220, 230, 240),
        Rain = true, Wet = true, Sheen = 0.18,
        CloudColor = rgb(160, 170, 185), CloudCover = 0.95, CloudDensity = 0.85,
        EggGlow = 0.5,
    },
    {
        Name = "Hutan Damai",
        ClockTime = 9.5, Brightness = 2.10, Exposure = 0.01, ShadowSoftness = 0.15,
        Density = 0.0050, Offset = 0.10, Haze = 0.20, Glare = 0.20,
        Color = rgb(200, 225, 205), Decay = rgb(140, 180, 145),
        Ambient = rgb(25, 35, 28), OutdoorAmbient = rgb(100, 135, 105),
        Top = rgb(230, 245, 235), Bottom = rgb(190, 215, 195),
        Bloom = 0.08, BloomSize = 24, BloomThreshold = 1.10,
        SunRays = 0.20, SunRaySpread = 0.90,
        Contrast = 0.11, Saturation = 0.08, Tint = rgb(240, 250, 242),
        ShaftColor = rgb(240, 255, 220),
        Shafts = 0.8, SunGlow = 0.6, Flare = 0.3, Sheen = 0.05,
    },
    {
        Name = "Malam Bulan",
        ClockTime = 0.30, Brightness = 1.25, Exposure = -0.08, ShadowSoftness = 0.18,
        Density = 0.0040, Offset = 0.20, Haze = 0.10, Glare = 0.02,
        Color = rgb(160, 185, 230), Decay = rgb(90, 110, 160),
        Ambient = rgb(15, 18, 30), OutdoorAmbient = rgb(60, 75, 110),
        Top = rgb(130, 155, 210), Bottom = rgb(80, 95, 135),
        Bloom = 0.08, BloomSize = 24, BloomThreshold = 1.05,
        Contrast = 0.15, Saturation = 0.03, Tint = rgb(215, 225, 250),
        EggGlow = 1.0,
    },
    {
        Name = "Malam Gelap & Tenang",
        ClockTime = 2.15, Brightness = 0.85, Exposure = -0.12, ShadowSoftness = 0.20,
        Density = 0.0030, Offset = 0.25, Haze = 0.05, Glare = 0.00,
        Color = rgb(80, 105, 160), Decay = rgb(40, 55, 95),
        Ambient = rgb(8, 10, 18), OutdoorAmbient = rgb(30, 40, 65),
        Top = rgb(90, 115, 170), Bottom = rgb(45, 55, 80),
        Bloom = 0.06, BloomSize = 22, BloomThreshold = 0.95,
        Contrast = 0.18, Saturation = 0.02, Tint = rgb(195, 210, 250),
        EggGlow = 1.0,
    },
}

local MoodByName = {}
for _, mood in ipairs(Moods) do
    setmetatable(mood, { __index = DEFAULT })
    MoodByName[mood.Name] = mood
end

-- Menggabungkan suasana dengan rata-rata yang halus
local NUM_KEYS = {
    "Brightness", "Exposure", "ShadowSoftness", "Density", "Offset", "Haze", "Glare",
    "Bloom", "BloomSize", "BloomThreshold", "SunRays", "SunRaySpread",
    "Contrast", "Saturation", "Shafts", "SunGlow", "Flare", "Sheen", "Overlay",
}
local COLOR_KEYS = {
    "Color", "Decay", "Ambient", "OutdoorAmbient", "Top", "Bottom", "Tint",
    "ShaftColor", "OverlayTop", "OverlayBottom",
}

local function averageColor(list, key)
    local acc = list[1][key]
    for i = 2, #list do acc = acc:Lerp(list[i][key], 1 / i) end
    return acc
end

local function mergeMoods(list)
    if #list == 1 then return list[1] end
    local base = list[1]
    for _, m in ipairs(list) do if not m.Fx then base = m break end end

    local out = setmetatable({}, { __index = DEFAULT })
    out.Name = "Gabungan Harmonis"
    out.ClockTime = base.ClockTime

    for _, key in ipairs(NUM_KEYS) do
        local sum = 0
        for _, m in ipairs(list) do sum += m[key] end
        out[key] = sum / #list
    end
    for _, key in ipairs(COLOR_KEYS) do out[key] = averageColor(list, key) end

    local clouds = {}
    for _, m in ipairs(list) do
        out.Rain = out.Rain or m.Rain
        out.Wet = out.Wet or m.Wet
        out.WarmBody = out.WarmBody or m.WarmBody
        out.EggGlow = math.max(out.EggGlow, m.EggGlow)
        if m.CloudColor then table.insert(clouds, m) end
    end

    if #clouds > 0 then
        out.CloudColor = averageColor(clouds, "CloudColor")
        local cover, density = 0, 0
        for _, m in ipairs(clouds) do cover += m.CloudCover or 0.5; density += m.CloudDensity or 0.5 end
        out.CloudCover = cover / #clouds
        out.CloudDensity = density / #clouds
    end
    return out
end

----------------------------------------------------------------
-- STATE
----------------------------------------------------------------
local function qualityScale(level) return 0.4 + 0.6 * (level - 1) / 9 end

local State = {
    Quality = Settings.Quality,
    Scale = qualityScale(Settings.Quality),
    Selected = {},
    Mood = nil,
    Instances = { Atmosphere = nil, Bloom = nil, Color = nil, SunRays = nil },
    Base = { Bloom = 0, SunRays = 0, Glare = 0, Tint = Color3.new(1, 1, 1), Saturation = 0 },
    AccentLights = {},
    Connections = {},
    UI = nil,
    Restored = false,
    Stats = { Parts = 0, Ground = 0, Lights = 0, Eggs = 0, FPS = 0 },
}

for _, name in ipairs(Settings.StartMoods) do
    if MoodByName[name] then table.insert(State.Selected, name) end
end
if #State.Selected == 0 then table.insert(State.Selected, Moods[1].Name) end

local PartList = {}
local PartInfo = setmetatable({}, weakKeys)
local ScanDone = false
local function selectedLabel() return table.concat(State.Selected, " + ") end

----------------------------------------------------------------
-- MATAHARI DIAM (Statis, namun interaktif terhadap pandangan)
----------------------------------------------------------------
local Sun = {
    Anchor = nil, Dir = Vector3.new(0, 1, 0), Pos = Vector3.zero,
    Dist = 1, Look = 0, Facing = 0, Scale = 1, Elev = 0, Open = 0, Timer = 0, OpenTarget = 0,
}

local sunRay = RaycastParams.new()
sunRay.FilterType = Enum.RaycastFilterType.Exclude
sunRay.RespectCanCollide = false

local function updateSunRay()
    local list = { WorldFolder }
    if Player.Character then table.insert(list, Player.Character) end
    sunRay.FilterDescendantsInstances = list
end

local function updateSun(dt)
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local cf = cam.CFrame
    local camPos = cf.Position

    if not Sun.Anchor then
        local char = Player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        Sun.Anchor = root and root.Position or camPos
        updateSunRay()
    end

    local sunDir = Lighting:GetSunDirection()
    Sun.Dir = sunDir
    Sun.Pos = Sun.Anchor + sunDir * Settings.SunDistance

    local toSun = Sun.Pos - camPos
    local dist = math.max(toSun.Magnitude, 1)
    local dir = toSun / dist

    Sun.Dist = dist
    Sun.Look = cf.LookVector:Dot(dir)
    Sun.Facing = clamp01(Sun.Look)
    Sun.Scale = math.clamp((Settings.SunDistance / dist) ^ Settings.SunFalloff, 0.1, 1.4)
    Sun.Elev = clamp01((sunDir.Y + 0.05) / 0.12)

    -- Cek oklusi (apakah matahari tertutup bangunan/pohon)
    Sun.Timer += dt
    if Sun.Timer >= 0.1 then
        Sun.Timer = 0
        local offsets = { Vector3.zero, cf.RightVector * 0.05, -cf.RightVector * 0.05, cf.UpVector * 0.05, -cf.UpVector * 0.05 }
        local open = 0
        for _, offset in ipairs(offsets) do
            if not Workspace:Raycast(camPos, (dir + offset).Unit * dist, sunRay) then open += 1 end
        end
        Sun.OpenTarget = open / #offsets
    end
    Sun.Open = lerp(Sun.Open, Sun.OpenTarget, math.min(1, dt * 4))
end

----------------------------------------------------------------
-- EFEK LIGHTING CORE
----------------------------------------------------------------
local function createEffect(className, name)
    local existing = Lighting:FindFirstChild(name)
    if existing and existing:IsA(className) then return existing end
    if existing then existing:Destroy() end
    local effect = Instance.new(className)
    effect.Name = name
    effect.Parent = Lighting
    table.insert(Original.Created, effect)
    return effect
end

local function configureLightingBase()
    for _, property in ipairs({"Brightness", "ExposureCompensation", "GlobalShadows", "ShadowSoftness", "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "Ambient", "OutdoorAmbient", "ColorShift_Top", "ColorShift_Bottom", "ClockTime"}) do
        rememberLighting(property)
    end
    safe(function() Lighting.LightingStyle = Enum.LightingStyle.Realistic end)
    setProperty(Lighting, "GlobalShadows", true)
    setProperty(Lighting, "EnvironmentDiffuseScale", 1)
    setProperty(Lighting, "EnvironmentSpecularScale", 1)
    if hasProperty(Lighting, "PrioritizeLightingQuality") then
        setProperty(Lighting, "PrioritizeLightingQuality", true)
    end
end

local function configureAtmosphere(mood)
    local atmosphere = State.Instances.Atmosphere
    if not atmosphere then
        atmosphere = createEffect("Atmosphere", PREFIX .. "Atmosphere")
        State.Instances.Atmosphere = atmosphere
    end
    for _, child in ipairs(Lighting:GetChildren()) do
        if child:IsA("Atmosphere") and child ~= atmosphere then
            table.insert(Original.HiddenAtmospheres, child)
            child.Parent = nil
        end
    end
    setProperty(atmosphere, "Density", mood.Density)
    setProperty(atmosphere, "Offset", mood.Offset)
    setProperty(atmosphere, "Haze", mood.Haze)
    setProperty(atmosphere, "Glare", mood.Glare)
    setProperty(atmosphere, "Color", mood.Color)
    setProperty(atmosphere, "Decay", mood.Decay)
    State.Base.Glare = mood.Glare
end

local function configureShaders(mood)
    local scale = State.Scale
    local bloom = State.Instances.Bloom
    if not bloom then
        bloom = createEffect("BloomEffect", PREFIX .. "Bloom")
        State.Instances.Bloom = bloom
    end
    State.Base.Bloom = mood.Bloom * (0.6 + 0.4 * scale)
    setProperty(bloom, "Intensity", State.Base.Bloom)
    setProperty(bloom, "Size", mood.BloomSize)
    setProperty(bloom, "Threshold", mood.BloomThreshold)
    setProperty(bloom, "Enabled", true)

    local color = State.Instances.Color
    if not color then
        color = createEffect("ColorCorrectionEffect", PREFIX .. "Warna")
        State.Instances.Color = color
    end
    State.Base.Tint = mood.Tint
    State.Base.Saturation = mood.Saturation
    setProperty(color, "Brightness", 0)
    setProperty(color, "Contrast", mood.Contrast)
    setProperty(color, "Saturation", mood.Saturation)
    setProperty(color, "TintColor", mood.Tint)
    setProperty(color, "Enabled", true)

    local rays = State.Instances.SunRays
    if not rays then
        rays = createEffect("SunRaysEffect", PREFIX .. "SunRays")
        State.Instances.SunRays = rays
    end
    State.Base.SunRays = mood.SunRays * (0.5 + 0.5 * scale)
    setProperty(rays, "Intensity", State.Base.SunRays)
    setProperty(rays, "Spread", mood.SunRaySpread)
    setProperty(rays, "Enabled", true)
end

local function configureMoodLighting(mood)
    setProperty(Lighting, "ClockTime", mood.ClockTime)
    setProperty(Lighting, "Brightness", mood.Brightness)
    setProperty(Lighting, "ExposureCompensation", mood.Exposure)
    setProperty(Lighting, "ShadowSoftness", mood.ShadowSoftness)
    setProperty(Lighting, "Ambient", mood.Ambient)
    setProperty(Lighting, "OutdoorAmbient", mood.OutdoorAmbient)
    setProperty(Lighting, "ColorShift_Top", mood.Top)
    setProperty(Lighting, "ColorShift_Bottom", mood.Bottom)
    configureAtmosphere(mood)
    configureShaders(mood)
end

----------------------------------------------------------------
-- SKY: Sembunyikan matahari bawaan Roblox yang kasar
----------------------------------------------------------------
local SkyState = { Object = nil, Owned = false, Saved = nil }
local function restoreSky()
    if SkyState.Object then
        if SkyState.Owned then
            if SkyState.Object.Parent then SkyState.Object:Destroy() end
        elseif SkyState.Saved and SkyState.Object.Parent then
            for property, value in pairs(SkyState.Saved) do setProperty(SkyState.Object, property, value) end
        end
    end
    SkyState.Object = nil; SkyState.Owned = false; SkyState.Saved = nil
end

local function applySky(mood)
    if not (mood.HideSun or mood.SunGlow > 0.05) then restoreSky(); return end
    if not SkyState.Object then
        local existing = Lighting:FindFirstChildOfClass("Sky")
        if existing then
            SkyState.Object = existing; SkyState.Owned = false
            SkyState.Saved = { SunAngularSize = existing.SunAngularSize }
        else
            local sky = Instance.new("Sky"); sky.Name = PREFIX .. "Sky"; sky.Parent = Lighting
            SkyState.Object = sky; SkyState.Owned = true
        end
    end
    setProperty(SkyState.Object, "SunAngularSize", 0)
end

----------------------------------------------------------------
-- KLASIFIKASI MATERIAL & DETAIL MAP
----------------------------------------------------------------
local GROUND_MATERIALS = {
    [Enum.Material.Grass] = true, [Enum.Material.LeafyGrass] = true, [Enum.Material.Ground] = true,
    [Enum.Material.Mud] = true, [Enum.Material.Sand] = true, [Enum.Material.Sandstone] = true,
    [Enum.Material.Asphalt] = true, [Enum.Material.Pavement] = true, [Enum.Material.Concrete] = true,
    [Enum.Material.Cobblestone] = true, [Enum.Material.Brick] = true, [Enum.Material.Slate] = true,
    [Enum.Material.Rock] = true, [Enum.Material.Basalt] = true, [Enum.Material.Limestone] = true,
    [Enum.Material.Granite] = true, [Enum.Material.Pebble] = true, [Enum.Material.WoodPlanks] = true,
}

local function isVisualPart(part)
    if not part:IsA("BasePart") or part:IsA("Terrain") or part.Transparency >= 0.98 or part:IsDescendantOf(WorldFolder) then return false end
    local name = string.lower(part.Name)
    for _, token in ipairs({"hitbox", "hurtbox", "trigger", "zoneprobe", "collider", "collision", "invisible", "interactionbox", "promptpart", "clickdetector", "raycast"}) do
        if name:find(token, 1, true) then return false end
    end
    local model = part:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChildOfClass("Humanoid") then return false end
    return true
end

local function classifyPart(part)
    local name = string.lower(part.Name)
    local material = part.Material
    local info = { Type = "DEFAULT", Base = 0, Factor = 0.25, Ground = false, SA = part:FindFirstChildOfClass("SurfaceAppearance") }

    if material == Enum.Material.Neon then info.Type, info.Factor = "EMISSIVE", 0; return info end
    if material == Enum.Material.Metal then info.Type, info.Base, info.Factor = "METAL", 0.14, 1.2
    elseif material == Enum.Material.Glass then info.Type, info.Base, info.Factor = "GLASS", 0.08, 1.0
    elseif name:find("gold") or name:find("coin") or name:find("treasure") or name:find("bronze") then info.Type, info.Base, info.Factor = "GOLD", 0.16, 1.2
    elseif name:find("steel") or name:find("iron") or name:find("metal") then info.Type, info.Base, info.Factor = "METAL", 0.14, 1.2
    elseif name:find("crystal") or name:find("gem") then info.Type, info.Base, info.Factor = "CRYSTAL", 0.12, 1.0
    elseif name:find("water") or name:find("ocean") or name:find("pool") then info.Type, info.Base, info.Factor = "WATER", 0.10, 0.6 end

    if info.Type == "DEFAULT" then
        if material == Enum.Material.Wood or material == Enum.Material.WoodPlanks then info.Factor = 0.5 end
        local size = part.Size
        local up = part.CFrame.UpVector.Y
        local area = size.X * size.Z
        if (up > 0.9 and area >= 300) or (GROUND_MATERIALS[material] and up > 0.85 and size.Y <= 8 and area >= 60) then
            info.Ground = true; info.Factor = 0.4
        end
    end
    return info
end

local function processPart(part)
    if PartInfo[part] then return PartInfo[part] end
    if not isVisualPart(part) then return nil end
    rememberPart(part)
    local info = classifyPart(part)
    if info.Type == "DEFAULT" and not info.Ground and part.Material == Enum.Material.Plastic then
        local variant = getProperty(part, "MaterialVariant", "")
        if not variant or variant == "" then setProperty(part, "Material", Enum.Material.SmoothPlastic) end
    end
    setProperty(part, "CastShadow", true)
    if info.SA then rememberSurfaceAppearance(info.SA) end
    PartInfo[part] = info; table.insert(PartList, part)
    State.Stats.Parts += 1
    if info.Ground then State.Stats.Ground += 1 end
    return info
end

local SLICK_MATERIALS = { [Enum.Material.Concrete] = true, [Enum.Material.Asphalt] = true, [Enum.Material.Pavement] = true, [Enum.Material.Cobblestone] = true, [Enum.Material.Brick] = true, [Enum.Material.Slate] = true, [Enum.Material.Granite] = true, [Enum.Material.Limestone] = true, [Enum.Material.WoodPlanks] = true, [Enum.Material.Plastic] = true }

local function stylePart(part, mood)
    local info = PartInfo[part]
    local original = Original.Parts[part]
    if not info or not original or not part.Parent then return end

    local sheen = mood.Sheen * State.Scale
    local wet = mood.Wet == true and info.Ground
    local add = info.Type ~= "EMISSIVE" and (info.Base + sheen * info.Factor) or 0
    if wet then add = math.max(add, 0.5) end

    setProperty(part, "Reflectance", math.clamp(math.max(original.Reflectance or 0, add), 0, 0.6))
    local variant = getProperty(part, "MaterialVariant", "")
    if wet and not info.SA and SLICK_MATERIALS[original.Material] and (not variant or variant == "") then
        if part.Material ~= Enum.Material.SmoothPlastic then setProperty(part, "Material", Enum.Material.SmoothPlastic); info.Slick = true end
    elseif info.Slick then
        setProperty(part, "Material", original.Material); info.Slick = false
    end

    if original.Color then
        local wanted = wet and wetColor(original.Color) or original.Color
        if part.Color ~= wanted then setProperty(part, "Color", wanted) end
    end
    if info.SA and info.SA.Parent then
        local saOriginal = Original.SurfaceAppearances[info.SA]
        if saOriginal and saOriginal.Color then
            local wanted = wet and wetColor(saOriginal.Color) or saOriginal.Color
            if info.SA.Color ~= wanted then setProperty(info.SA, "Color", wanted) end
        end
    end
end

local styleJob = 0
local function styleParts(mood)
    styleJob += 1
    local myJob = styleJob
    local count = 0
    for i = #PartList, 1, -1 do if not PartList[i].Parent then table.remove(PartList, i) end end
    for _, part in ipairs(PartList) do
        if myJob ~= styleJob or State.Restored then return end
        stylePart(part, mood)
        count += 1
        if count % 400 == 0 then task.wait() end
    end
end

local TERRAIN_MATERIALS = { Enum.Material.Grass, Enum.Material.LeafyGrass, Enum.Material.Ground, Enum.Material.Mud, Enum.Material.Sand, Enum.Material.Sandstone, Enum.Material.Asphalt, Enum.Material.Pavement, Enum.Material.Concrete, Enum.Material.Cobblestone, Enum.Material.Rock, Enum.Material.Slate, Enum.Material.Limestone, Enum.Material.Basalt }
local function setTerrainWet(on)
    for _, material in ipairs(TERRAIN_MATERIALS) do
        if Original.TerrainColors[material] == nil then Original.TerrainColors[material] = safe(function() return Terrain:GetMaterialColor(material) end, false) end
        local original = Original.TerrainColors[material]
        if original then safe(function() Terrain:SetMaterialColor(material, on and wetColor(original) or original) end) end
    end
end

local function scanWorld()
    local descendants = Workspace:GetDescendants()
    for i, object in ipairs(descendants) do
        if object:IsA("BasePart") then processPart(object) end
        if i % 600 == 0 then task.wait() end
    end
    ScanDone = true
end

----------------------------------------------------------------
-- DUNIA 3D: MATAHARI, SINAR, HUJAN (INTEGRASI PENUH DENGAN MAP)
----------------------------------------------------------------
local World = {}
do
    local MAX_SHAFTS = 40
    local MAX_PUDDLES = 80
    local rng = Random.new(1987)
    local anchor, sunPart, sunGui, sunStreak
    local sunLayers = {}
    local sunExtras = {}
    local bokehPart, bokehEmitter
    local shafts = {}
    local puddles = {}
    local rainPart, rainEmitter, rainSound
    local mood, built = false, false
    local rayParams
    local rainLevel, coverLevel, coverTarget = 0, 1, 1
    local lastSeedPos, lastSeedSun, lastPuddlePos
    local timers = { Shaft = 0, Rain = 0 }
    local cloudsState, bodyAttachment, bodyLight, bodyBrightness = nil, nil, nil, 0

    local function updateRayParams()
        rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.RespectCanCollide = false
        local list = { WorldFolder }
        if Player.Character then table.insert(list, Player.Character) end
        rayParams.FilterDescendantsInstances = list
    end
    World.UpdateRayParams = updateRayParams

    -- Lapisan matahari yang SANGAT HALUS dan hangat (Oranye-Kuning)
    local SUN_LAYERS = {
        { size = 0.80, alpha = 0.85, color = rgb(255, 160, 60) },  -- Outer soft orange
        { size = 0.50, alpha = 0.90, color = rgb(255, 140, 40) },  -- Mid warm orange
        { size = 0.25, alpha = 0.95, color = rgb(255, 190, 80) },  -- Inner bright yellow-orange
        { size = 0.10, alpha = 1.00, color = rgb(255, 240, 180) }, -- White-hot core (halus)
    }

    local function makeInvisiblePart(name)
        local p = Instance.new("Part")
        p.Name = name; p.Anchored = true; p.CanCollide = false; p.CanQuery = false
        p.CanTouch = false; p.CastShadow = false; p.Transparency = 1
        p.Size = Vector3.new(0.2, 0.2, 0.2); p.Parent = WorldFolder
        return p
    end

    local function build()
        if built then return end
        built = true; updateRayParams()
        anchor = makeInvisiblePart(PREFIX .. "Anchor"); anchor.CFrame = CFrame.new(0, 0, 0)
        sunPart = makeInvisiblePart(PREFIX .. "Matahari")

        sunGui = Instance.new("BillboardGui")
        sunGui.Name = PREFIX .. "GlowMatahari"; sunGui.Adornee = sunPart
        sunGui.AlwaysOnTop = false; sunGui.LightInfluence = 0; sunGui.MaxDistance = math.huge
        sunGui.Size = UDim2.fromScale(Settings.SunSize, Settings.SunSize); sunGui.Enabled = false; sunGui.Parent = sunPart

        for _, def in ipairs(SUN_LAYERS) do
            local f = Instance.new("Frame")
            f.BorderSizePixel = 0; f.AnchorPoint = Vector2.new(0.5, 0.5); f.Position = UDim2.fromScale(0.5, 0.5)
            f.Size = UDim2.fromScale(def.size, def.size); f.BackgroundColor3 = def.color; f.BackgroundTransparency = 1; f.Parent = sunGui
            local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(1, 0); corner.Parent = f
            table.insert(sunLayers, { Frame = f, Alpha = def.alpha })
        end

        -- Sinar lembut horizontal (Anamorphic halus, bukan garis kasar)
        sunStreak = Instance.new("Frame")
        sunStreak.BorderSizePixel = 0; sunStreak.AnchorPoint = Vector2.new(0.5, 0.5); sunStreak.Position = UDim2.fromScale(0.5, 0.5)
        sunStreak.Size = UDim2.fromScale(2.0, 0.015); sunStreak.BackgroundColor3 = rgb(255, 210, 120); sunStreak.BackgroundTransparency = 1; sunStreak.Parent = sunGui
        local streakGradient = Instance.new("UIGradient")
        streakGradient.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.4), NumberSequenceKeypoint.new(1, 1) })
        streakGradient.Parent = sunStreak

        -- Sinar radial yang sangat halus dan jarang (hanya saat menatap matahari)
        for i = 1, 8 do
            local f = Instance.new("Frame")
            f.BorderSizePixel = 0; f.AnchorPoint = Vector2.new(0.5, 0.5); f.Position = UDim2.fromScale(0.5, 0.5)
            f.Size = UDim2.fromScale(3.0, 0.01); f.Rotation = (i - 1) * (180 / 8)
            f.BackgroundColor3 = rgb(255, 220, 140); f.BackgroundTransparency = 1; f.Parent = sunGui
            local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = f
            local g = Instance.new("UIGradient")
            g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, 0.3), NumberSequenceKeypoint.new(0.6, 0.3), NumberSequenceKeypoint.new(1, 1) })
            g.Parent = f
            table.insert(sunExtras, { Frame = f, Alpha = 0.6 })
        end

        -- Bokeh partikel debu cahaya yang melayang tenang
        bokehPart = makeInvisiblePart(PREFIX .. "Bokeh"); bokehPart.Size = Vector3.new(100, 50, 100)
        bokehEmitter = Instance.new("ParticleEmitter")
        bokehEmitter.Rate = 0; bokehEmitter.Lifetime = NumberRange.new(5, 9)
        bokehEmitter.Speed = NumberRange.new(0.2, 0.8); bokehEmitter.SpreadAngle = Vector2.new(180, 180)
        bokehEmitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 1.2), NumberSequenceKeypoint.new(1, 0.4) })
        bokehEmitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.6), NumberSequenceKeypoint.new(0.8, 0.7), NumberSequenceKeypoint.new(1, 1) })
        bokehEmitter.Color = ColorSequence.new(rgb(255, 180, 80), rgb(255, 230, 150))
        bokehEmitter.LightEmission = 1; bokehEmitter.LightInfluence = 0; bokehEmitter.LockedToPart = false
        bokehEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"; bokehEmitter.Parent = bokehPart

        -- Sun rays 3D (Beam) yang menembus map
        for _ = 1, MAX_SHAFTS do
            local a0 = Instance.new("Attachment"); a0.Parent = anchor
            local a1 = Instance.new("Attachment"); a1.Parent = anchor
            local beam = Instance.new("Beam")
            beam.Attachment0 = a0; beam.Attachment1 = a1; beam.FaceCamera = true
            beam.LightEmission = 1; beam.LightInfluence = 0; beam.Segments = 1
            beam.Transparency = NumberSequence.new(1); beam.Enabled = false; beam.Parent = anchor
            table.insert(shafts, { Beam = beam, A0 = a0, A1 = a1, Active = false, Pos = Vector3.zero, Rand = 1 })
        end

        -- Hujan
        rainPart = makeInvisiblePart(PREFIX .. "Hujan"); rainPart.Size = Vector3.new(120, 1, 120); rainEmitter = {}
        local rainLayers = {
            { weight = 0.40, size = 0.60, squash = -0.85, transparency = 0.50, speed = NumberRange.new(90, 115), life = NumberRange.new(0.8, 1.0) },
            { weight = 0.35, size = 0.40, squash = -0.80, transparency = 0.65, speed = NumberRange.new(75, 95), life = NumberRange.new(0.85, 1.05) },
            { weight = 0.25, size = 0.25, squash = -0.75, transparency = 0.75, speed = NumberRange.new(60, 80), life = NumberRange.new(0.9, 1.1) },
        }
        for _, layer in ipairs(rainLayers) do
            local e = Instance.new("ParticleEmitter")
            e.Rate = 0; e.Lifetime = layer.life; e.Speed = layer.speed; e.EmissionDirection = Enum.NormalId.Bottom
            e.SpreadAngle = Vector2.new(2, 2); e.Size = NumberSequence.new(layer.size); e.Squash = NumberSequence.new(layer.squash)
            e.Transparency = NumberSequence.new(layer.transparency); e.Color = ColorSequence.new(rgb(210, 220, 235))
            e.LightEmission = 0.2; e.LightInfluence = 0.4; e.Acceleration = Vector3.new(5, 0, 2)
            e.LockedToPart = false; e.Orientation = Enum.ParticleOrientation.VelocityParallel
            e.Texture = "rbxasset://textures/particles/sparkles_main.dds"; e.Parent = rainPart
            table.insert(rainEmitter, { Emitter = e, Weight = layer.weight })
        end
    end

    local function applyClouds(m)
        if m and m.CloudColor ~= nil then
            if not cloudsState then
                local existing = Terrain:FindFirstChildOfClass("Clouds")
                if existing then
                    cloudsState = { Object = existing, Owned = false, Saved = { Color = existing.Color, Cover = existing.Cover, Density = existing.Density, Enabled = existing.Enabled } }
                else
                    local c = Instance.new("Clouds"); c.Name = PREFIX .. "Awan"; c.Parent = Terrain
                    cloudsState = { Object = c, Owned = true }
                end
            end
            local c = cloudsState.Object
            setProperty(c, "Color", m.CloudColor); setProperty(c, "Cover", m.CloudCover or 0.5)
            setProperty(c, "Density", m.CloudDensity or 0.5); setProperty(c, "Enabled", true)
        elseif cloudsState then
            if cloudsState.Owned then if cloudsState.Object.Parent then cloudsState.Object:Destroy() end
            else for property, value in pairs(cloudsState.Saved) do setProperty(cloudsState.Object, property, value) end end
            cloudsState = nil
        end
    end

    local function seedShafts(camPos)
        local sunDir = Sun.Dir
        local count = math.floor(MAX_SHAFTS * State.Scale)
        local color = mood.ShaftColor
        local flat = Vector3.new(sunDir.X, 0, sunDir.Z)
        local azimuth = flat.Magnitude > 0.01 and math.atan2(flat.Z, flat.X) or rng:NextNumber(0, math.pi * 2)
        local maxLen = 160

        for index, shaft in ipairs(shafts) do
            shaft.Active = false
            if index <= count then
                local angle = rng:NextNumber() < 0.7 and (azimuth + rng:NextNumber(-1.0, 1.0)) or rng:NextNumber(0, math.pi * 2)
                local radius = 30 + 180 * math.sqrt(rng:NextNumber())
                local origin = camPos + Vector3.new(math.cos(angle) * radius, 180, math.sin(angle) * radius)
                local hit = Workspace:Raycast(origin, Vector3.new(0, -500, 0), rayParams)

                if hit and hit.Normal.Y > 0.3 then
                    local ground = hit.Position + Vector3.new(0, 0.5 + rng:NextNumber(0, 3), 0)
                    local blocked = Workspace:Raycast(ground, sunDir * maxLen, rayParams)
                    local length = blocked and (blocked.Position - ground).Magnitude or maxLen

                    if length > 15 then
                        local width = rng:NextNumber(8, 18)
                        shaft.A0.Position = ground; shaft.A1.Position = ground + sunDir * length
                        shaft.Beam.Width0 = width; shaft.Beam.Width1 = width * 1.4
                        shaft.Beam.Color = ColorSequence.new(color)
                        shaft.Pos = ground; shaft.Rand = rng:NextNumber(0.5, 1.0); shaft.Active = true
                    end
                end
            end
        end
        lastSeedPos = camPos; lastSeedSun = sunDir
    end

    local function newGlassBlock()
        local p = Instance.new("Part")
        p.Name = PREFIX .. "GenanganKaca"; p.Anchored = true; p.CanCollide = false; p.CanQuery = false
        p.CanTouch = false; p.CastShadow = false; p.Material = Enum.Material.Glass
        p.Color = rgb(220, 235, 250); p.Reflectance = 0.75; p.Transparency = 1
        return p
    end

    local function setPuddlesTransparency(t)
        for _, puddle in ipairs(puddles) do for _, block in ipairs(puddle) do block.Transparency = t end end
    end
    local function hidePuddle(puddle) for _, block in ipairs(puddle) do block.Parent = nil end end

    local function placePuddles(center)
        local count = math.floor(MAX_PUDDLES * State.Scale)
        local below = Workspace:Raycast(center, Vector3.new(0, -300, 0), rayParams)
        local refY = below and below.Position.Y or (center.Y - 3)

        for index = 1, MAX_PUDDLES do
            local puddle = puddles[index]
            if index > count then if puddle then hidePuddle(puddle) end
            else
                if not puddle then puddle = { newGlassBlock(), newGlassBlock(), newGlassBlock() }; puddles[index] = puddle end
                local angle = rng:NextNumber(0, math.pi * 2)
                local radius = 5 + 120 * math.sqrt(rng:NextNumber())
                local origin = center + Vector3.new(math.cos(angle) * radius, 150, math.sin(angle) * radius)
                local hit = Workspace:Raycast(origin, Vector3.new(0, -300, 0), rayParams)

                local valid = false
                if hit then
                    if hit.Instance:IsA("Terrain") then valid = hit.Normal.Y > 0.88 and hit.Material ~= Enum.Material.Water
                    elseif hit.Normal.Y > 0.95 then
                        local info = PartInfo[hit.Instance]
                        valid = (info ~= nil and info.Ground) or math.abs(hit.Position.Y - refY) < 3
                    end
                    if valid and Workspace:Raycast(hit.Position + Vector3.new(0, 1, 0), Vector3.new(0, 50, 0), rayParams) then valid = false end
                end

                if valid then
                    local pos = hit.Position; local yaw = rng:NextNumber(0, math.pi)
                    local w = rng:NextNumber(5, 14); local l = w * rng:NextNumber(0.5, 0.9)
                    puddle[1].Size = Vector3.new(w, 0.04, l); puddle[1].CFrame = CFrame.new(pos + Vector3.new(0, 0.04, 0)) * CFrame.Angles(0, yaw, 0)
                    local s2 = Vector3.new(rng:NextNumber(-0.25, 0.25) * w, 0.055, rng:NextNumber(-0.25, 0.25) * l)
                    puddle[2].Size = Vector3.new(w * 0.65, 0.04, l * 1.3); puddle[2].CFrame = CFrame.new(pos + s2) * CFrame.Angles(0, yaw + rng:NextNumber(0.5, 1.1), 0)
                    local s3 = Vector3.new(rng:NextNumber(-0.35, 0.35) * w, 0.065, rng:NextNumber(-0.35, 0.35) * l)
                    puddle[3].Size = Vector3.new(w * 0.45, 0.04, l * 0.6); puddle[3].CFrame = CFrame.new(pos + s3) * CFrame.Angles(0, yaw - rng:NextNumber(0.4, 1.0), 0)
                    for _, block in ipairs(puddle) do block.Parent = WorldFolder end
                else hidePuddle(puddle) end
            end
        end
        lastPuddlePos = center
    end

    local function updateBody(dt)
        local char = Player.Character; local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        if not bodyAttachment or not bodyAttachment.Parent then
            bodyAttachment = Instance.new("Attachment"); bodyAttachment.Name = PREFIX .. "CahayaTubuh"; bodyAttachment.Parent = anchor
            bodyLight = Instance.new("PointLight"); bodyLight.Name = PREFIX .. "CahayaTubuhLampu"
            bodyLight.Color = rgb(255, 170, 80); bodyLight.Range = 18; bodyLight.Brightness = 0
            bodyLight.Shadows = false; bodyLight.Parent = bodyAttachment
        end
        local sunDir = Sun.Dir
        bodyAttachment.Position = root.Position + sunDir * 8 + Vector3.new(0, 1.5, 0)
        local covered = Workspace:Raycast(root.Position + Vector3.new(0, 2, 0), sunDir * 300, rayParams) ~= nil
        local elevation = math.clamp(sunDir.Y * 4 + 0.35, 0, 1)
        local target = covered and 0 or (1.0 * elevation * (0.4 + 0.6 * math.min(1, Sun.Scale)))
        bodyBrightness = lerp(bodyBrightness, target, math.min(1, dt * 2.5))
        bodyLight.Brightness = bodyBrightness
    end

    function World.SetMood(m)
        build(); mood = m; lastSeedPos = nil; lastPuddlePos = nil; applyClouds(m)
        if not m.WarmBody and bodyLight then bodyLight.Brightness = 0; bodyBrightness = 0 end
    end

    function World.Update(dt)
        if not built or not mood then return end
        local cam = Workspace.CurrentCamera; if not cam then return end
        local scale = State.Scale; local sunDir = Sun.Dir; local camPos = cam.CFrame.Position
        local facing = Sun.Facing; local f2 = facing * facing; local f3 = f2 * facing
        local distFade = clamp01(Sun.Scale); local sunSensitive = mood.SunGlow > 0 and 1 or 0
        local glow = mood.SunGlow * Sun.Elev

        -- 1. Glow Matahari 3D (Diam, namun bereaksi halus terhadap pandangan)
        sunGui.Enabled = glow > 0.01
        if sunGui.Enabled then
            sunPart.CFrame = CFrame.new(Sun.Pos)
            local a = clamp01(glow * (0.6 + 0.4 * facing))
            for _, layer in ipairs(sunLayers) do layer.Frame.BackgroundTransparency = 1 - (1 - layer.Alpha) * a end
            sunStreak.BackgroundTransparency = 1 - 0.70 * a * (0.3 + 0.7 * facing)
            -- Sinar radial hanya muncul JELAS saat menatap matahari (facing tinggi), sangat halus
            for _, extra in ipairs(sunExtras) do
                extra.Frame.BackgroundTransparency = 1 - (extra.Alpha * a * (0.05 + 0.95 * facing))
            end
        end

        -- 2. Efek Kamera "Bernapas" saat menghadap matahari (Terintegrasi dengan map)
        local sens = Sun.Elev * Sun.Open * sunSensitive * distFade
        local breathe = 0.5 + 0.5 * math.sin(os.clock() * 0.6) -- Efek ketenangan (bernapas pelan)

        local bloom = State.Instances.Bloom
        if bloom and bloom.Parent then bloom.Intensity = State.Base.Bloom + (0.40 * f3 * sens) + (breathe * 0.02) end

        local rays = State.Instances.SunRays
        if rays and rays.Parent then
            -- SunRays bawaan Roblox ditingkatkan secara dramatis namun halus saat menatap matahari
            rays.Intensity = State.Base.SunRays + (0.25 * f3 * sens)
        end

        local grade = State.Instances.Color
        if grade and grade.Parent then
            grade.TintColor = State.Base.Tint:Lerp(rgb(255, 215, 160), 0.30 * f2 * sens)
            grade.Saturation = State.Base.Saturation + (0.05 * f2 * sens)
            grade.Brightness = 0.04 * f3 * sens
        end

        local atmosphere = State.Instances.Atmosphere
        if atmosphere and atmosphere.Parent then atmosphere.Glare = math.min(1, State.Base.Glare + (0.35 * f2 * sens)) end

        -- 3. Sun rays 3D (Beam) yang menembus celah map
        timers.Shaft += dt
        if timers.Shaft >= 0.15 then
            timers.Shaft = 0
            local strength = mood.Shafts * scale * Sun.Elev * (0.45 + 0.55 * distFade)
            if strength <= 0.01 then lastSeedPos = nil
            elseif not lastSeedPos or (camPos - lastSeedPos).Magnitude > 50 or not lastSeedSun or lastSeedSun:Dot(sunDir) < 0.9997 then
                seedShafts(camPos)
            end

            for _, shaft in ipairs(shafts) do
                if shaft.Active and strength > 0.01 then
                    local distance = (shaft.Pos - camPos).Magnitude
                    local near = clamp01((distance - 15) / 30)
                    local amount = strength * (0.30 + 0.70 * facing) * shaft.Rand * 0.18 * near
                    local t = 1 - clamp01(amount)
                    shaft.Beam.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, t),
                        NumberSequenceKeypoint.new(0.6, math.min(1, t + (1 - t) * 0.4)), NumberSequenceKeypoint.new(1, 1),
                    })
                    shaft.Beam.Enabled = true
                else shaft.Beam.Enabled = false end
            end
        end

        -- 4. Hujan + Genangan Kaca
        local rainTarget = mood.Rain and 1 or 0
        rainLevel = lerp(rainLevel, rainTarget, math.min(1, dt * 0.4))
        timers.Rain += dt
        if timers.Rain >= 0.2 then
            timers.Rain = 0
            local covered = Workspace:Raycast(camPos, Vector3.new(0, 100, 0), rayParams) ~= nil
            coverTarget = covered and 0.08 or 1
            if rainLevel > 0.03 then
                if not lastPuddlePos or (camPos - lastPuddlePos).Magnitude > 60 then placePuddles(camPos) end
                setPuddlesTransparency(1 - 0.60 * clamp01(rainLevel * 1.2))
            elseif lastPuddlePos then
                setPuddlesTransparency(1); lastPuddlePos = nil
            end
        end
        coverLevel = lerp(coverLevel, coverTarget, math.min(1, dt * 3))
        rainPart.CFrame = CFrame.new(camPos + Vector3.new(0, 50, 0))
        local totalRate = 4500 * scale * rainLevel * coverLevel
        for _, item in ipairs(rainEmitter) do item.Emitter.Rate = totalRate * item.Weight end

        -- 5. Bokeh debu cahaya (muncul tenang saat sore)
        if bokehPart and bokehEmitter then
            local flat = Vector3.new(sunDir.X, 0, sunDir.Z)
            flat = flat.Magnitude > 0.01 and flat.Unit or Vector3.new(0, 0, -1)
            bokehPart.CFrame = CFrame.new(camPos + flat * 50 + Vector3.new(0, 8, 0))
            local strength = mood.Flare * Sun.Elev * Sun.Open * distFade * (0.4 + 0.6 * facing) * scale
            bokehEmitter.Rate = 12 * strength
        end

        if mood.WarmBody then updateBody(dt) end
    end

    function World.Destroy()
        applyClouds(nil)
        for _, puddle in ipairs(puddles) do for _, block in ipairs(puddle) do block:Destroy() end end
        table.clear(puddles); table.clear(shafts); table.clear(sunLayers); table.clear(sunExtras)
        bokehPart = nil; bokehEmitter = nil; WorldFolder:ClearAllChildren()
        bodyAttachment = nil; bodyLight = nil; built = false; mood = nil
    end
end

----------------------------------------------------------------
-- CAHAYA TELUR (Malam) - Halus dan Berdenyut
----------------------------------------------------------------
local Eggs = { Records = {}, Keys = setmetatable({}, weakKeys), Timer = 0 }
local eggRng = Random.new(77)
local GLOW_LAYERS = { { size = 1.00, alpha = 0.10 }, { size = 0.62, alpha = 0.16 }, { size = 0.30, alpha = 0.26 } }

local function eggTarget(part)
    local name = part.Name
    if name == "EggSpotBottom" or name == "EggPoint" then return part, part, "spot" end
    local placed = Workspace:FindFirstChild("PlacedEggRenders")
    if placed and part:IsDescendantOf(placed) then
        local top = part
        while top.Parent and top.Parent ~= placed do top = top.Parent end
        return top, part, "placed"
    end
    return nil
end

local function registerEgg(part)
    local key, lightPart, kind = eggTarget(part)
    if not key or Eggs.Keys[key] then return end
    Eggs.Keys[key] = true
    local attachment = Instance.new("Attachment"); attachment.Name = PREFIX .. "EggAttachment"
    attachment.Parent = lightPart; attachment.WorldPosition = lightPart.Position + Vector3.new(0, kind == "spot" and 2.4 or 1.2, 0)
    local light = Instance.new("PointLight"); light.Name = PREFIX .. "EggLight"
    light.Color = Settings.EggColor; light.Range = Settings.EggRange; light.Brightness = 0
    light.Shadows = false; light.Enabled = false; light.Parent = attachment

    local record = { Part = lightPart, Attachment = attachment, Light = light, Frames = {}, Phase = eggRng:NextNumber() * math.pi * 2, Level = 0, Wanted = false, Dist = math.huge }
    if kind == "spot" then
        local glow = Instance.new("BillboardGui"); glow.Name = PREFIX .. "EggGlow"; glow.Adornee = attachment
        glow.Size = UDim2.fromScale(8, 8); glow.AlwaysOnTop = false; glow.LightInfluence = 0
        glow.MaxDistance = 220; glow.Enabled = false; glow.Parent = lightPart
        for _, layer in ipairs(GLOW_LAYERS) do
            local f = Instance.new("Frame"); f.BorderSizePixel = 0; f.AnchorPoint = Vector2.new(0.5, 0.5)
            f.Position = UDim2.fromScale(0.5, 0.5); f.Size = UDim2.fromScale(layer.size, layer.size)
            f.BackgroundColor3 = Settings.EggColor; f.BackgroundTransparency = 1; f.Parent = glow
            local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(1, 0); corner.Parent = f
            table.insert(record.Frames, { Frame = f, Alpha = layer.alpha })
        end
        record.Glow = glow
    end
    table.insert(Eggs.Records, record); State.Stats.Eggs = #Eggs.Records
end

local function destroyEgg(record)
    if record.Light then record.Light:Destroy() end
    if record.Glow then record.Glow:Destroy() end
    if record.Attachment then record.Attachment:Destroy() end
end

local function updateEggs(dt)
    local mood = State.Mood; local glow = mood and mood.EggGlow or 0; local now = os.clock()
    Eggs.Timer += dt
    if Eggs.Timer >= 0.5 then
        Eggs.Timer = 0; local cam = Workspace.CurrentCamera; local camPos = cam and cam.CFrame.Position
        for i = #Eggs.Records, 1, -1 do
            local record = Eggs.Records[i]
            if not record.Part.Parent then destroyEgg(record); table.remove(Eggs.Records, i)
            else record.Dist = camPos and (record.Part.Position - camPos).Magnitude or math.huge end
        end
        local sorted = table.clone(Eggs.Records); table.sort(sorted, function(a, b) return a.Dist < b.Dist end)
        local maxLights = math.floor(Settings.EggMaxLights * (0.5 + 0.5 * State.Scale))
        for index, record in ipairs(sorted) do record.Wanted = index <= maxLights and record.Dist <= Settings.EggDistance end
        State.Stats.Eggs = #Eggs.Records
    end
    local speed = math.min(1, dt * 2)
    for _, record in ipairs(Eggs.Records) do
        local target = (glow > 0 and record.Wanted) and 1 or 0
        record.Level = lerp(record.Level, target, speed)
        if record.Level > 0.02 then
            local breathing = 1 + 0.06 * math.sin(now * 1.2 + record.Phase) -- Denyut sangat pelan dan tenang
            local strength = record.Level * math.min(1, glow)
            record.Light.Brightness = strength * Settings.EggBrightness * breathing; record.Light.Enabled = true
            if record.Glow then
                record.Glow.Enabled = true
                for _, item in ipairs(record.Frames) do item.Frame.BackgroundTransparency = 1 - item.Alpha * strength * breathing end
            end
        else record.Light.Enabled = false; if record.Glow then record.Glow.Enabled = false end end
    end
end

----------------------------------------------------------------
-- LAMPU AKSEN
----------------------------------------------------------------
local LIGHT_TOKENS = { "lamp", "light", "lantern", "torch", "fire", "flame", "bulb", "neon", "screen", "monitor", "sign", "crystal", "portal", "glow", "energy", "lava" }
local function isLightSourcePart(part)
    local name = string.lower(part.Name)
    for _, token in ipairs(LIGHT_TOKENS) do if name:find(token, 1, true) then return true end end
    return part.Material == Enum.Material.Neon
end
local function getLightColor(part)
    if part.Material == Enum.Material.Neon then return part.Color end
    local name = string.lower(part.Name)
    if name:find("fire") or name:find("flame") or name:find("torch") or name:find("lava") then return rgb(255, 160, 70) end
    if name:find("crystal") or name:find("ice") then return rgb(160, 215, 255) end
    return part.Color
end
local function clearAccentLights()
    for _, record in ipairs(State.AccentLights) do
        if record.Light and record.Light.Parent then record.Light:Destroy() end
        if record.Attachment and record.Attachment.Parent then record.Attachment:Destroy() end
    end
    table.clear(State.AccentLights)
end
local function scanAccentLights()
    clearAccentLights(); local cam = Workspace.CurrentCamera; if not cam then return end
    local camPos = cam.CFrame.Position; local candidates = {}
    for _, part in ipairs(PartList) do
        if part.Parent and isLightSourcePart(part) then
            local distance = (part.Position - camPos).Magnitude
            if distance <= Settings.LightDistance then table.insert(candidates, { Part = part, Dist = distance }) end
        end
    end
    table.sort(candidates, function(a, b) return a.Dist < b.Dist end)
    local maxLights = math.floor(Settings.MaxAccentLights * State.Scale)
    for _, candidate in ipairs(candidates) do
        if #State.AccentLights >= maxLights then break end
        local part = candidate.Part
        if not part:FindFirstChild(PREFIX .. "AccentAttachment") then
            local attachment = Instance.new("Attachment"); attachment.Name = PREFIX .. "AccentAttachment"; attachment.Parent = part
            local light = Instance.new("PointLight"); light.Name = PREFIX .. "AccentLight"
            light.Color = getLightColor(part); light.Brightness = 0.60; light.Range = 14
            light.Shadows = true; light.Parent = attachment
            table.insert(State.AccentLights, { Source = part, Attachment = attachment, Light = light })
        end
    end
    State.Stats.Lights = #State.AccentLights
end

----------------------------------------------------------------
-- TERAPKAN SUASANA & KUALITAS
----------------------------------------------------------------
local function activeMoods()
    local list = {}
    for _, name in ipairs(State.Selected) do
        local mood = MoodByName[name]
        if mood then table.insert(list, mood) end
    end
    if #list == 0 then table.insert(list, Moods[1]); State.Selected = { Moods[1].Name } end
    return list
end

local function applyMoods()
    local mood = mergeMoods(activeMoods())
    State.Mood = mood
    configureLightingBase()
    configureMoodLighting(mood)
    applySky(mood)
    World.SetMood(mood)
    setTerrainWet(mood.Wet == true)
    task.spawn(styleParts, mood)
end

local function applyQuality(level)
    level = math.clamp(math.floor(level or 8), 1, 10)
    State.Quality = level; State.Scale = qualityScale(level)
    applyMoods(); task.spawn(scanAccentLights)
end

----------------------------------------------------------------
-- API PUBLIK
----------------------------------------------------------------
local API = {}
local onSelectionChanged = function() end

function API.SetQuality(level) applyQuality(level) end
function API.GetQuality() return State.Quality end
function API.SetMood(name)
    if not MoodByName[name] then return false end
    State.Selected = { name }; applyMoods(); onSelectionChanged(); return true
end
function API.SetMoods(names)
    local list = {}
    for _, name in ipairs(names) do if MoodByName[name] then table.insert(list, name) end end
    if #list == 0 then return false end
    State.Selected = list; applyMoods(); onSelectionChanged(); return true
end
function API.ToggleMood(name)
    if not MoodByName[name] then return false end
    local index = table.find(State.Selected, name)
    if index then if #State.Selected > 1 then table.remove(State.Selected, index) end
    else table.insert(State.Selected, name) end
    applyMoods(); onSelectionChanged(); return true
end
function API.GetMood() return selectedLabel() end
function API.GetActive() return table.clone(State.Selected) end
function API.GetMoods() local names = {}; for _, mood in ipairs(Moods) do table.insert(names, mood.Name) end; return names end
function API.GetStats() return State.Stats end
function API.SetSunAnchor(position) Sun.Anchor = position end
function API.ResetSunAnchor() Sun.Anchor = nil end
function API.Refresh()
    task.spawn(function() scanWorld(); styleParts(State.Mood); scanAccentLights() end)
end

----------------------------------------------------------------
-- RESTORE
----------------------------------------------------------------
local function restoreOriginal()
    if State.Restored then return end
    State.Restored = true; styleJob += 1
    for _, connection in ipairs(State.Connections) do connection:Disconnect() end
    table.clear(State.Connections)
    for property, value in pairs(Original.Lighting) do if value ~= nil then setProperty(Lighting, property, value) end end
    for part, data in pairs(Original.Parts) do
        if part and part.Parent then for property, value in pairs(data) do if value ~= nil then setProperty(part, property, value) end end end
    end
    for surface, data in pairs(Original.SurfaceAppearances) do
        if surface and surface.Parent then for property, value in pairs(data) do if value ~= nil then setProperty(surface, property, value) end end end
    end
    for material, color in pairs(Original.TerrainColors) do
        if color then safe(function() Terrain:SetMaterialColor(material, color) end) end
    end
    clearAccentLights()
    for _, record in ipairs(Eggs.Records) do destroyEgg(record) end
    table.clear(Eggs.Records)
    restoreSky(); World.Destroy()
    for _, instance in ipairs(Original.Created) do if instance and instance.Parent then instance:Destroy() end end
    for _, atmosphere in ipairs(Original.HiddenAtmospheres) do if atmosphere then atmosphere.Parent = Lighting end end
    if State.UI then State.UI:Destroy(); State.UI = nil end
    if WorldFolder then WorldFolder:Destroy() end
    if _G.Leon4951Shaders == API then _G.Leon4951Shaders = nil end
    if _G.Leon4951Shaders_Serenity == API then _G.Leon4951Shaders_Serenity = nil end
end
API.Restore = restoreOriginal

----------------------------------------------------------------
-- UI: Minimalis, Halus, Bisa Digeser
----------------------------------------------------------------
local function createUI()
    if not Settings.ShowPanel then return end
    local ACCENT = rgb(255, 160, 60)
    local W = 210; local TITLE_H = 30; local BODY_H = 280
    local SCALES = { 0.8, 0.95, 1.15 }; local scaleIndex = 2
    local tweenFast = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tweenSlow = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local gui = Instance.new("ScreenGui"); gui.Name = ROOT; gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true; gui.DisplayOrder = 50; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.Parent = PlayerGui

    local panel = Instance.new("Frame"); panel.Name = "Panel"; panel.AnchorPoint = Vector2.new(0, 0)
    panel.Position = UDim2.fromScale(0.015, 0.25); panel.Size = UDim2.fromOffset(W, TITLE_H + BODY_H)
    panel.BackgroundColor3 = rgb(18, 16, 20); panel.BackgroundTransparency = 0.10
    panel.BorderSizePixel = 0; panel.ClipsDescendants = true; panel.Parent = gui

    local uiScale = Instance.new("UIScale"); uiScale.Scale = SCALES[scaleIndex]; uiScale.Parent = panel
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 12); corner.Parent = panel
    local stroke = Instance.new("UIStroke"); stroke.Color = ACCENT; stroke.Transparency = 0.65; stroke.Thickness = 1; stroke.Parent = panel

    local function makeButton(parent, text, x, y, w, h)
        local b = Instance.new("TextButton"); b.AutoButtonColor = false
        b.Position = UDim2.fromOffset(x, y); b.Size = UDim2.fromOffset(w, h)
        b.BackgroundColor3 = rgb(38, 36, 42); b.BorderSizePixel = 0
        b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.TextColor3 = rgb(220, 220, 225); b.Text = text; b.Parent = parent
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = b
        return b
    end

    local title = Instance.new("TextLabel"); title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(12, 0); title.Size = UDim2.fromOffset(W - 80, TITLE_H)
    title.Font = Enum.Font.GothamBold; title.TextSize = 12; title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = rgb(255, 230, 190); title.Text = "Leon4951 Serenity"; title.Parent = panel

    local sizeButton = makeButton(panel, "A", W - 66, 5, 26, 20)
    local collapseButton = makeButton(panel, "-", W - 36, 5, 26, 20)

    local body = Instance.new("Frame"); body.BackgroundTransparency = 1
    body.Position = UDim2.fromOffset(0, TITLE_H); body.Size = UDim2.fromOffset(W, BODY_H); body.Parent = panel

    local qLabel = Instance.new("TextLabel"); qLabel.BackgroundTransparency = 1
    qLabel.Position = UDim2.fromOffset(12, 4); qLabel.Size = UDim2.fromOffset(80, 22)
    qLabel.Font = Enum.Font.GothamMedium; qLabel.TextSize = 10; qLabel.TextXAlignment = Enum.TextXAlignment.Left
    qLabel.TextColor3 = rgb(180, 180, 190); qLabel.Text = "KUALITAS"; qLabel.Parent = body

    local qMinus = makeButton(body, "-", W - 96, 4, 26, 20)
    local qValue = Instance.new("TextLabel"); qValue.BackgroundTransparency = 1
    qValue.Position = UDim2.fromOffset(W - 68, 4); qValue.Size = UDim2.fromOffset(32, 20)
    qValue.Font = Enum.Font.GothamBold; qValue.TextSize = 12; qValue.TextColor3 = ACCENT; qValue.Parent = body
    local qPlus = makeButton(body, "+", W - 36, 4, 26, 20)

    local function refreshQuality() qValue.Text = tostring(State.Quality) end
    refreshQuality()
    qMinus.MouseButton1Click:Connect(function() applyQuality(State.Quality - 1); refreshQuality() end)
    qPlus.MouseButton1Click:Connect(function() applyQuality(State.Quality + 1); refreshQuality() end)

    local listLabel = Instance.new("TextLabel"); listLabel.BackgroundTransparency = 1
    listLabel.Position = UDim2.fromOffset(12, 30); listLabel.Size = UDim2.fromOffset(W - 24, 16)
    listLabel.Font = Enum.Font.GothamMedium; listLabel.TextSize = 10; listLabel.TextXAlignment = Enum.TextXAlignment.Left
    listLabel.TextColor3 = rgb(180, 180, 190); listLabel.Text = "SUASANA (tap untuk gabung)"; listLabel.Parent = body

    local scroll = Instance.new("ScrollingFrame"); scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
    scroll.Position = UDim2.fromOffset(10, 48); scroll.Size = UDim2.fromOffset(W - 20, 200)
    scroll.ScrollBarThickness = 2; scroll.ScrollBarImageColor3 = ACCENT; scroll.CanvasSize = UDim2.fromOffset(0, 0); scroll.Parent = body

    local list = Instance.new("UIListLayout"); list.Padding = UDim.new(0, 4); list.SortOrder = Enum.SortOrder.LayoutOrder; list.Parent = scroll
    local rows = {}

    local function refreshRows()
        for name, row in pairs(rows) do
            local on = table.find(State.Selected, name) ~= nil
            TweenService:Create(row.Button, tweenFast, {
                BackgroundColor3 = on and rgb(70, 45, 25) or rgb(32, 30, 36),
                TextColor3 = on and rgb(255, 235, 200) or rgb(185, 185, 195),
            }):Play()
            TweenService:Create(row.Dot, tweenFast, { BackgroundColor3 = on and ACCENT or rgb(75, 75, 85) }):Play()
        end
    end

    for index, mood in ipairs(Moods) do
        local button = Instance.new("TextButton"); button.AutoButtonColor = false
        button.LayoutOrder = index; button.Size = UDim2.new(1, -6, 0, 24)
        button.BackgroundColor3 = rgb(32, 30, 36); button.BorderSizePixel = 0
        button.Font = Enum.Font.GothamMedium; button.TextSize = 11; button.TextXAlignment = Enum.TextXAlignment.Left
        button.TextColor3 = rgb(185, 185, 195); button.Text = "      " .. mood.Name .. (mood.Fx and "  +" or ""); button.Parent = scroll
        local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = button
        local dot = Instance.new("Frame"); dot.AnchorPoint = Vector2.new(0, 0.5); dot.Position = UDim2.new(0, 10, 0.5, 0)
        dot.Size = UDim2.fromOffset(7, 7); dot.BackgroundColor3 = rgb(75, 75, 85); dot.BorderSizePixel = 0; dot.Parent = button
        local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(1, 0); dc.Parent = dot
        button.MouseButton1Click:Connect(function() API.ToggleMood(mood.Name) end)
        rows[mood.Name] = { Button = button, Dot = dot }
    end

    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.fromOffset(0, list.AbsoluteContentSize.Y + 6)
    end)

    local status = Instance.new("TextLabel"); status.BackgroundTransparency = 1
    status.Position = UDim2.fromOffset(12, BODY_H - 28); status.Size = UDim2.fromOffset(W - 86, 22)
    status.Font = Enum.Font.Gotham; status.TextSize = 9; status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextTruncate = Enum.TextTruncate.AtEnd; status.TextColor3 = rgb(140, 140, 155); status.Parent = body

    local offButton = makeButton(body, "Matikan", W - 72, BODY_H - 28, 62, 22)
    offButton.TextSize = 10; offButton.MouseButton1Click:Connect(function() restoreOriginal() end)

    onSelectionChanged = refreshRows; refreshRows()

    task.spawn(function()
        while gui.Parent do
            status.Text = string.format("%d aktif | Egg %d | FPS %d", #State.Selected, State.Stats.Eggs, State.Stats.FPS)
            task.wait(1)
        end
    end)

    sizeButton.MouseButton1Click:Connect(function()
        scaleIndex = scaleIndex % #SCALES + 1
        TweenService:Create(uiScale, tweenSlow, { Scale = SCALES[scaleIndex] }):Play()
    end)

    local collapsed = false
    collapseButton.MouseButton1Click:Connect(function()
        collapsed = not collapsed; collapseButton.Text = collapsed and "+" or "-"
        if collapsed then
            local t = TweenService:Create(panel, tweenSlow, { Size = UDim2.fromOffset(W, TITLE_H) })
            t:Play(); t.Completed:Connect(function() if collapsed then body.Visible = false end end)
        else
            body.Visible = true; TweenService:Create(panel, tweenSlow, { Size = UDim2.fromOffset(W, TITLE_H + BODY_H) }):Play()
        end
    end)

    local dragging, dragStart, startAbs = false, nil, nil
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startAbs = panel.AbsolutePosition
        end
    end)
    title.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)

    table.insert(State.Connections, UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local screen = gui.AbsoluteSize; local delta = input.Position - dragStart; local panelSize = panel.AbsoluteSize
        local x = math.clamp(startAbs.X + delta.X, 0, math.max(0, screen.X - panelSize.X))
        local y = math.clamp(startAbs.Y + delta.Y, 0, math.max(0, screen.Y - 30))
        panel.Position = UDim2.fromScale(x / screen.X, y / screen.Y)
    end))

    table.insert(State.Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.RightControl then gui.Enabled = not gui.Enabled end
    end))

    State.UI = gui
end

----------------------------------------------------------------
-- LOOP UTAMA
----------------------------------------------------------------
local fpsAccumulator, fpsFrames = 0, 0
table.insert(State.Connections, RunService.RenderStepped:Connect(function(dt)
    if State.Restored then return end
    updateSun(dt)
    World.Update(dt)
    fpsAccumulator += dt; fpsFrames += 1
    if fpsAccumulator >= 1 then
        State.Stats.FPS = math.floor(fpsFrames / fpsAccumulator)
        fpsAccumulator = 0; fpsFrames = 0
    end
end))

local lightTimer = 0
table.insert(State.Connections, RunService.Heartbeat:Connect(function(dt)
    if State.Restored then return end
    updateEggs(dt)
    lightTimer += dt
    if lightTimer < Settings.LightUpdateInterval then return end
    lightTimer = 0
    local cam = Workspace.CurrentCamera; if not cam then return end
    local camPos = cam.CFrame.Position
    for _, record in ipairs(State.AccentLights) do
        local source = record.Source; local light = record.Light
        if source and source.Parent and light and light.Parent then
            local distance = (source.Position - camPos).Magnitude
            if distance > Settings.LightDistance then light.Enabled = false
            else
                light.Enabled = true
                local factor = 1 - math.clamp(distance / Settings.LightDistance, 0, 1)
                light.Brightness = lerp(0.15, 0.80, factor)
            end
        end
    end
end))

table.insert(State.Connections, Player.CharacterAdded:Connect(function() World.UpdateRayParams() end))
table.insert(State.Connections, Workspace.DescendantAdded:Connect(function(object)
    if State.Restored or not object:IsA("BasePart") then return end
    task.defer(function()
        if ScanDone and processPart(object) and State.Mood then stylePart(object, State.Mood) end
    end)
end))

----------------------------------------------------------------
-- MULAI
----------------------------------------------------------------
_G.Leon4951Shaders = API
_G.Leon4951Shaders_Serenity = API

configureLightingBase()
applyQuality(Settings.Quality)

task.spawn(function()
    scanWorld()
    styleParts(State.Mood)
    scanAccentLights()
end)

createUI()