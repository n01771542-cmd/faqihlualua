--[[
    LEON4951 SHADERS (UPDATED: SUN RAYS & BRIGHT ORANGE)
    Roblox LocalScript
    Letakkan di: StarterPlayer > StarterPlayerScripts

    PERUBAHAN TERBARU:
    1. Matahari sore lebih kecil, halus, dan sangat dominan oranye terang.
    2. Efek "Garis-garis Cahaya" (Lens Flare & Radial Rays) yang indah, 
       muncul dramatis HANYA saat kamu menatap langsung ke arah matahari.
    3. SunRaysEffect bawaan Roblox ditingkatkan saat menatap matahari.
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

local ROOT = "Leon4951Shaders"
local PREFIX = "L4_"
local rgb = Color3.fromRGB

----------------------------------------------------------------
-- BERSIHKAN VERSI LAMA
----------------------------------------------------------------

for _, globalName in ipairs({ "Leon4951Shaders", "VisualRealistis", "UltraRealisticRendererV4" }) do
    local old = _G[globalName]
    if old and old.Restore then
        pcall(old.Restore)
    end
end

for _, guiName in ipairs({
    ROOT, ROOT .. "_Lensa", ROOT .. "_Atmos",
    "VisualRealistis", "VisualRealistis_Lensa", "UltraRealisticRendererV4",
}) do
    local old = PlayerGui:FindFirstChild(guiName)
    if old then
        old:Destroy()
    end
end

for _, child in ipairs(Lighting:GetChildren()) do
    local n = child.Name
    if n:sub(1, 3) == "VR_" or n:sub(1, 3) == PREFIX or n:sub(1, 5) == "URV4_" then
        child:Destroy()
    end
end

for _, folderName in ipairs({ "VR_Dunia", "L4_Dunia" }) do
    local old = Workspace:FindFirstChild(folderName)
    if old then
        old:Destroy()
    end
end

local WorldFolder = Instance.new("Folder")
WorldFolder.Name = "L4_Dunia"
WorldFolder.Parent = Workspace

----------------------------------------------------------------
-- HELPER
----------------------------------------------------------------

local function safe(fn, fallback)
    local ok, result = pcall(fn)
    if ok then
        return result
    end
    return fallback
end

local function setProperty(instance, property, value)
    if not instance then return false end
    return safe(function()
        instance[property] = value
        return true
    end, false)
end

local function getProperty(instance, property, fallback)
    if not instance then return fallback end
    return safe(function()
        return instance[property]
    end, fallback)
end

local function hasProperty(instance, property)
    if not instance then return false end
    return safe(function()
        local _ = instance[property]
        return true
    end, false)
end

local function clamp01(v)
    return math.clamp(v, 0, 1)
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function wetColor(c)
    return Color3.new(c.R * 0.72, c.G * 0.70, c.B * 0.66)
end

local weakKeys = { __mode = "k" }

----------------------------------------------------------------
-- DATA ASLI (untuk Restore)
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
-- PENGATURAN
----------------------------------------------------------------

local Settings = {
    Quality = 8,
    StartMoods = { "Sore Keemasan" },
    ShowPanel = true,

    SunDistance = 900,
    SunFalloff = 1.6,
    SunSize = 220,           -- DIKECILKAN agar lebih halus dan proporsional

    ShadowSoftness = 0.1,
    MaxAccentLights = 80,
    LightDistance = 500,
    LightUpdateInterval = 0.12,

    EggRange = 15,
    EggBrightness = 1.0,
    EggMaxLights = 48,
    EggDistance = 320,
    EggColor = rgb(255, 176, 100),
}

----------------------------------------------------------------
-- DAFTAR SUASANA
----------------------------------------------------------------

local DEFAULT = {
    Shafts = 0, SunGlow = 0, Flare = 0, Sheen = 0, EggGlow = 0, Overlay = 0,
    OverlayTop = rgb(22, 9, 4), OverlayBottom = rgb(255, 140, 50),
    SunRaySpread = 0.8, SunRays = 0, BloomSize = 20, BloomThreshold = 1.2,
    ShadowSoftness = 0.2, ShaftColor = rgb(255, 205, 140),
}

local Moods = {
    {
        Name = "Siang Cerah",
        ClockTime = 11.0, Brightness = 2.40, Exposure = 0.03, ShadowSoftness = 0.20,
        Density = 0.25, Offset = 0.15, Haze = 0.5, Glare = 0.15,
        Color = rgb(205, 225, 255), Decay = rgb(190, 210, 240),
        Ambient = rgb(36, 40, 46), OutdoorAmbient = rgb(150, 160, 175),
        Top = rgb(255, 248, 235), Bottom = rgb(200, 205, 215),
        Bloom = 0.06, BloomSize = 18, BloomThreshold = 1.3,
        SunRays = 0.05, SunRaySpread = 0.8,
        Contrast = 0.08, Saturation = 0.03, Tint = rgb(255, 255, 255),
        Shafts = 0.15, SunGlow = 0.35, Flare = 0.15, Sheen = 0.03,
    },
    {
        -- SORE KEEMASAN: DIUPDATE untuk matahari oranye terang & garis cahaya indah
        Name = "Sore Keemasan",
        ClockTime = 17.3, Brightness = 2.35, Exposure = -0.22, ShadowSoftness = 0.04,
        Density = 0.37, Offset = 0.10, Haze = 1.9, Glare = 1.0,
        Color = rgb(255, 148, 78), Decay = rgb(226, 92, 38),
        Ambient = rgb(30, 18, 12), OutdoorAmbient = rgb(84, 56, 40),
        Top = rgb(255, 138, 58), Bottom = rgb(112, 70, 50),
        Bloom = 0.34, BloomSize = 24, BloomThreshold = 0.9,
        SunRays = 0.65, SunRaySpread = 0.9,       -- DITINGKATKAN untuk efek garis cahaya
        Contrast = 0.27, Saturation = 0.14, Tint = rgb(255, 204, 158),
        ShaftColor = rgb(255, 160, 80),
        Shafts = 1.0, SunGlow = 1.0, Flare = 1.2, Sheen = 0.13, -- Flare ditingkatkan
        Overlay = 0.8, OverlayTop = rgb(22, 9, 4), OverlayBottom = rgb(255, 138, 48),
        WarmBody = true,
        CloudColor = rgb(255, 140, 85), CloudCover = 0.45, CloudDensity = 0.5,
    },
    {
        Name = "Senja Jingga",
        ClockTime = 18.15, Brightness = 1.85, Exposure = -0.10, ShadowSoftness = 0.06,
        Density = 0.40, Offset = 0.08, Haze = 2.0, Glare = 1.0,
        Color = rgb(255, 170, 130), Decay = rgb(200, 88, 62),
        Ambient = rgb(44, 28, 28), OutdoorAmbient = rgb(108, 76, 80),
        Top = rgb(255, 154, 108), Bottom = rgb(140, 96, 100),
        Bloom = 0.30, BloomSize = 24, BloomThreshold = 0.95,
        SunRays = 0.34, SunRaySpread = 0.9,
        Contrast = 0.18, Saturation = 0.10, Tint = rgb(255, 222, 200),
        ShaftColor = rgb(255, 170, 115),
        Shafts = 0.85, SunGlow = 1.0, Flare = 0.85, Sheen = 0.08,
        Overlay = 0.6, OverlayTop = rgb(26, 10, 10), OverlayBottom = rgb(255, 120, 70),
        CloudColor = rgb(236, 120, 100), CloudCover = 0.5, CloudDensity = 0.5,
        EggGlow = 0.35,
    },
    {
        Name = "Sedikit Sore",
        ClockTime = 16.5, Brightness = 1.90, Exposure = -0.03, ShadowSoftness = 0.20,
        Density = 0.30, Offset = 0.08, Haze = 1.2, Glare = 0.0,
        Color = rgb(255, 205, 140), Decay = rgb(240, 150, 70),
        Ambient = rgb(52, 40, 28), OutdoorAmbient = rgb(120, 98, 72),
        Top = rgb(255, 200, 110), Bottom = rgb(190, 150, 100),
        Bloom = 0.10, BloomSize = 22, BloomThreshold = 1.1,
        Contrast = 0.12, Saturation = 0.08, Tint = rgb(255, 235, 200),
        Sheen = 0.06, HideSun = true,
        CloudColor = rgb(255, 200, 120), CloudCover = 0.55, CloudDensity = 0.5,
        EggGlow = 0.1,
    },
    {
        Fx = true, Name = "Kabut Halus",
        ClockTime = 9.5, Brightness = 1.55, Exposure = -0.12, ShadowSoftness = 0.30,
        Density = 0.54, Offset = 0.0, Haze = 2.4, Glare = 0.1,
        Color = rgb(176, 186, 198), Decay = rgb(116, 126, 144),
        Ambient = rgb(30, 33, 38), OutdoorAmbient = rgb(82, 90, 102),
        Top = rgb(200, 202, 202), Bottom = rgb(130, 136, 146),
        Bloom = 0.05, BloomSize = 22, BloomThreshold = 1.2,
        Contrast = 0.10, Saturation = -0.04, Tint = rgb(222, 228, 236),
        Overlay = 0.35, OverlayTop = rgb(30, 34, 40), OverlayBottom = rgb(120, 128, 140),
        CloudColor = rgb(160, 166, 176), CloudCover = 0.7, CloudDensity = 0.6, EggGlow = 0.3,
    },
    {
        Fx = true, Name = "Berkabut",
        ClockTime = 8.0, Brightness = 1.65, Exposure = -0.08, ShadowSoftness = 0.32,
        Density = 0.68, Offset = 0.0, Haze = 3.5, Glare = 0.2,
        Color = rgb(184, 194, 207), Decay = rgb(126, 138, 158),
        Ambient = rgb(38, 41, 46), OutdoorAmbient = rgb(96, 104, 116),
        Top = rgb(214, 212, 206), Bottom = rgb(150, 155, 165),
        Bloom = 0.06, BloomSize = 26, BloomThreshold = 1.2,
        SunRays = 0.06, SunRaySpread = 0.9,
        Contrast = 0.06, Saturation = -0.03, Tint = rgb(230, 236, 244),
        Shafts = 0.4, SunGlow = 0.25, Flare = 0.08,
        Overlay = 0.4, OverlayTop = rgb(34, 38, 44), OverlayBottom = rgb(130, 138, 150),
        CloudColor = rgb(200, 204, 212), CloudCover = 0.75, CloudDensity = 0.65, EggGlow = 0.3,
    },
    {
        Name = "Sedikit Gelap",
        ClockTime = 19.2, Brightness = 1.20, Exposure = -0.15, ShadowSoftness = 0.25,
        Density = 0.30, Offset = 0.10, Haze = 1.0, Glare = 0.0,
        Color = rgb(150, 160, 185), Decay = rgb(80, 90, 120),
        Ambient = rgb(24, 26, 34), OutdoorAmbient = rgb(70, 76, 96),
        Top = rgb(150, 160, 190), Bottom = rgb(70, 72, 92),
        Bloom = 0.05, BloomSize = 20, BloomThreshold = 1.1,
        Contrast = 0.14, Saturation = -0.02, Tint = rgb(225, 230, 245), EggGlow = 0.6,
    },
    {
        Fx = true, Name = "Hujan",
        ClockTime = 14.5, Brightness = 1.35, Exposure = -0.10, ShadowSoftness = 0.35,
        Density = 0.45, Offset = 0.02, Haze = 2.0, Glare = 0.0,
        Color = rgb(160, 166, 174), Decay = rgb(120, 127, 138),
        Ambient = rgb(40, 42, 46), OutdoorAmbient = rgb(88, 94, 102),
        Top = rgb(180, 184, 190), Bottom = rgb(115, 119, 126),
        Bloom = 0.05, BloomSize = 20, BloomThreshold = 1.2,
        Contrast = 0.12, Saturation = -0.03, Tint = rgb(225, 228, 233),
        Rain = true, Wet = true, Sheen = 0.12,
        CloudColor = rgb(120, 128, 140), CloudCover = 0.9, CloudDensity = 0.8, EggGlow = 0.4,
    },
    {
        Name = "Hutan Hijau",
        ClockTime = 9.3, Brightness = 2.15, Exposure = 0.015, ShadowSoftness = 0.2,
        Density = 0.35, Offset = 0.10, Haze = 1.1, Glare = 0.3,
        Color = rgb(185, 215, 190), Decay = rgb(105, 155, 115),
        Ambient = rgb(24, 38, 27), OutdoorAmbient = rgb(90, 125, 96),
        Top = rgb(255, 240, 200), Bottom = rgb(205, 225, 185),
        Bloom = 0.06, BloomSize = 20, BloomThreshold = 1.2,
        SunRays = 0.12, SunRaySpread = 0.85,
        Contrast = 0.10, Saturation = 0.07, Tint = rgb(238, 250, 236),
        ShaftColor = rgb(255, 240, 190),
        Shafts = 0.9, SunGlow = 0.5, Flare = 0.2, Sheen = 0.04,
    },
    {
        Name = "Pantai Tropis",
        ClockTime = 10.6, Brightness = 2.34, Exposure = 0.035, ShadowSoftness = 0.2,
        Density = 0.22, Offset = 0.14, Haze = 0.6, Glare = 0.2,
        Color = rgb(190, 225, 225), Decay = rgb(116, 185, 170),
        Ambient = rgb(27, 43, 37), OutdoorAmbient = rgb(125, 158, 143),
        Top = rgb(255, 248, 230), Bottom = rgb(218, 242, 206),
        Bloom = 0.065, BloomSize = 18, BloomThreshold = 1.25,
        SunRays = 0.06, Contrast = 0.09, Saturation = 0.08, Tint = rgb(244, 255, 245),
        Shafts = 0.2, SunGlow = 0.45, Flare = 0.2, Sheen = 0.06,
    },
    {
        Name = "Gurun Pasir",
        ClockTime = 15.5, Brightness = 2.30, Exposure = 0.04, ShadowSoftness = 0.18,
        Density = 0.30, Offset = 0.16, Haze = 1.0, Glare = 0.3,
        Color = rgb(238, 220, 188), Decay = rgb(202, 166, 113),
        Ambient = rgb(52, 43, 32), OutdoorAmbient = rgb(167, 145, 115),
        Top = rgb(255, 232, 190), Bottom = rgb(255, 213, 158),
        Bloom = 0.065, BloomSize = 20, BloomThreshold = 1.2,
        SunRays = 0.08, SunRaySpread = 0.85,
        Contrast = 0.10, Saturation = 0.065, Tint = rgb(255, 248, 232),
        ShaftColor = rgb(255, 220, 160),
        Shafts = 0.3, SunGlow = 0.6, Flare = 0.25, Sheen = 0.04,
    },
    {
        Name = "Gunung Berapi",
        ClockTime = 19.4, Brightness = 1.70, Exposure = 0.0, ShadowSoftness = 0.2,
        Density = 0.60, Offset = 0.06, Haze = 2.0, Glare = 0.2,
        Color = rgb(235, 150, 120), Decay = rgb(150, 52, 38),
        Ambient = rgb(42, 20, 18), OutdoorAmbient = rgb(110, 53, 45),
        Top = rgb(255, 170, 130), Bottom = rgb(205, 78, 44),
        Bloom = 0.12, BloomSize = 24, BloomThreshold = 1.0,
        Contrast = 0.16, Saturation = 0.10, Tint = rgb(255, 235, 220), EggGlow = 0.5,
    },
    {
        Name = "Malam Bulan",
        ClockTime = 0.35, Brightness = 1.30, Exposure = -0.05, ShadowSoftness = 0.22,
        Density = 0.25, Offset = 0.22, Haze = 0.5, Glare = 0.0,
        Color = rgb(140, 170, 220), Decay = rgb(76, 92, 135),
        Ambient = rgb(14, 18, 30), OutdoorAmbient = rgb(54, 65, 92),
        Top = rgb(150, 175, 230), Bottom = rgb(80, 90, 125),
        Bloom = 0.06, BloomSize = 20, BloomThreshold = 1.1,
        Contrast = 0.16, Saturation = 0.025, Tint = rgb(210, 225, 255), EggGlow = 1.0,
    },
    {
        Name = "Malam Gelap",
        ClockTime = 2.1, Brightness = 0.92, Exposure = -0.08, ShadowSoftness = 0.25,
        Density = 0.20, Offset = 0.26, Haze = 0.3, Glare = 0.0,
        Color = rgb(75, 100, 160), Decay = rgb(35, 46, 82),
        Ambient = rgb(7, 9, 18), OutdoorAmbient = rgb(27, 33, 57),
        Top = rgb(110, 130, 190), Bottom = rgb(42, 45, 68),
        Bloom = 0.05, BloomSize = 20, BloomThreshold = 1.0,
        Contrast = 0.18, Saturation = 0.01, Tint = rgb(190, 210, 255), EggGlow = 1.0,
    },
    {
        Name = "Malam Kota Neon",
        ClockTime = 22.1, Brightness = 1.15, Exposure = -0.025, ShadowSoftness = 0.22,
        Density = 0.28, Offset = 0.20, Haze = 0.6, Glare = 0.0,
        Color = rgb(110, 165, 220), Decay = rgb(70, 75, 150),
        Ambient = rgb(12, 17, 28), OutdoorAmbient = rgb(42, 54, 84),
        Top = rgb(120, 150, 210), Bottom = rgb(62, 65, 112),
        Bloom = 0.15, BloomSize = 24, BloomThreshold = 0.95,
        Contrast = 0.18, Saturation = 0.09, Tint = rgb(225, 235, 255), EggGlow = 1.0,
    },
}

local MoodByName = {}
for _, mood in ipairs(Moods) do
    setmetatable(mood, { __index = DEFAULT })
    MoodByName[mood.Name] = mood
end

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
    for i = 2, #list do
        acc = acc:Lerp(list[i][key], 1 / i)
    end
    return acc
end

local function mergeMoods(list)
    if #list == 1 then return list[1] end

    local base = list[1]
    for _, m in ipairs(list) do
        if not m.Fx then
            base = m
            break
        end
    end

    local out = setmetatable({}, { __index = DEFAULT })
    out.Name = "Gabungan"
    out.ClockTime = base.ClockTime

    for _, key in ipairs(NUM_KEYS) do
        local sum = 0
        for _, m in ipairs(list) do sum += m[key] end
        out[key] = sum / #list
    end

    for _, key in ipairs(COLOR_KEYS) do
        out[key] = averageColor(list, key)
    end

    local clouds = {}
    for _, m in ipairs(list) do
        out.Rain = out.Rain or m.Rain
        out.Wet = out.Wet or m.Wet
        out.WarmBody = out.WarmBody or m.WarmBody
        out.HideSun = out.HideSun or m.HideSun
        out.EggGlow = math.max(out.EggGlow, m.EggGlow)
        if m.CloudColor then table.insert(clouds, m) end
    end

    if #clouds > 0 then
        out.CloudColor = averageColor(clouds, "CloudColor")
        local cover, density = 0, 0
        for _, m in ipairs(clouds) do
            cover += m.CloudCover or 0.5
            density += m.CloudDensity or 0.5
        end
        out.CloudCover = cover / #clouds
        out.CloudDensity = density / #clouds
    end

    return out
end

----------------------------------------------------------------
-- STATE
----------------------------------------------------------------

local function qualityScale(level)
    return 0.35 + 0.65 * (level - 1) / 9
end

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
if #State.Selected == 0 then
    table.insert(State.Selected, Moods[1].Name)
end

local PartList = {}
local PartInfo = setmetatable({}, weakKeys)
local ScanDone = false

local function selectedLabel()
    return table.concat(State.Selected, " + ")
end

----------------------------------------------------------------
-- MATAHARI DIAM
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

    Sun.Timer += dt
    if Sun.Timer >= 0.08 then
        Sun.Timer = 0
        local offsets = {
            Vector3.zero, cf.RightVector * 0.04, -cf.RightVector * 0.04,
            cf.UpVector * 0.04, -cf.UpVector * 0.04,
        }
        local open = 0
        for _, offset in ipairs(offsets) do
            if not Workspace:Raycast(camPos, (dir + offset).Unit * dist, sunRay) then
                open += 1
            end
        end
        Sun.OpenTarget = open / #offsets
    end

    Sun.Open = lerp(Sun.Open, Sun.OpenTarget, math.min(1, dt * 5))
end

----------------------------------------------------------------
-- EFEK LIGHTING
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
    for _, property in ipairs({
        "Brightness", "ExposureCompensation", "GlobalShadows", "ShadowSoftness",
        "EnvironmentDiffuseScale", "EnvironmentSpecularScale",
        "Ambient", "OutdoorAmbient", "ColorShift_Top", "ColorShift_Bottom", "ClockTime",
    }) do
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
-- SKY
----------------------------------------------------------------

local SkyState = { Object = nil, Owned = false, Saved = nil }

local function restoreSky()
    if SkyState.Object then
        if SkyState.Owned then
            if SkyState.Object.Parent then SkyState.Object:Destroy() end
        elseif SkyState.Saved and SkyState.Object.Parent then
            for property, value in pairs(SkyState.Saved) do
                setProperty(SkyState.Object, property, value)
            end
        end
    end
    SkyState.Object = nil
    SkyState.Owned = false
    SkyState.Saved = nil
end

local function applySky(mood)
    if not (mood.HideSun or mood.SunGlow > 0.05) then
        restoreSky()
        return
    end

    if not SkyState.Object then
        local existing = Lighting:FindFirstChildOfClass("Sky")
        if existing then
            SkyState.Object = existing
            SkyState.Owned = false
            SkyState.Saved = { SunAngularSize = existing.SunAngularSize }
        else
            local sky = Instance.new("Sky")
            sky.Name = PREFIX .. "Sky"
            sky.Parent = Lighting
            SkyState.Object = sky
            SkyState.Owned = true
        end
    end
    setProperty(SkyState.Object, "SunAngularSize", 0)
end

----------------------------------------------------------------
-- KLASIFIKASI MATERIAL
----------------------------------------------------------------

local GROUND_MATERIALS = {
    [Enum.Material.Grass] = true, [Enum.Material.LeafyGrass] = true,
    [Enum.Material.Ground] = true, [Enum.Material.Mud] = true,
    [Enum.Material.Sand] = true, [Enum.Material.Sandstone] = true,
    [Enum.Material.Asphalt] = true, [Enum.Material.Pavement] = true,
    [Enum.Material.Concrete] = true, [Enum.Material.Cobblestone] = true,
    [Enum.Material.Brick] = true, [Enum.Material.Slate] = true,
    [Enum.Material.Rock] = true, [Enum.Material.Basalt] = true,
    [Enum.Material.Limestone] = true, [Enum.Material.Granite] = true,
    [Enum.Material.Pebble] = true, [Enum.Material.WoodPlanks] = true,
}

local BLOCKED_NAMES = {
    "hitbox", "hurtbox", "trigger", "zoneprobe", "collider", "collision",
    "invisible", "interactionbox", "promptpart", "clickdetector", "raycast",
}

local function isVisualPart(part)
    if not part:IsA("BasePart") or part:IsA("Terrain") then return false end
    if part.Transparency >= 0.98 then return false end
    if part:IsDescendantOf(WorldFolder) then return false end

    local name = string.lower(part.Name)
    for _, token in ipairs(BLOCKED_NAMES) do
        if name:find(token, 1, true) then return false end
    end

    local model = part:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChildOfClass("Humanoid") then return false end
    return true
end

local function classifyPart(part)
    local name = string.lower(part.Name)
    local material = part.Material
    local info = {
        Type = "DEFAULT", Base = 0, Factor = 0.25, Ground = false,
        SA = part:FindFirstChildOfClass("SurfaceAppearance"),
    }

    if material == Enum.Material.Neon then
        info.Type, info.Factor = "EMISSIVE", 0
        return info
    end

    if material == Enum.Material.Metal then
        info.Type, info.Base, info.Factor = "METAL", 0.14, 1.2
    elseif material == Enum.Material.Glass then
        info.Type, info.Base, info.Factor = "GLASS", 0.08, 1.0
    elseif name:find("gold") or name:find("coin") or name:find("treasure") or name:find("bronze") or name:find("brass") then
        info.Type, info.Base, info.Factor = "GOLD", 0.16, 1.2
    elseif name:find("steel") or name:find("iron") or name:find("blade") or name:find("machine") or name:find("metal") then
        info.Type, info.Base, info.Factor = "METAL", 0.14, 1.2
    elseif name:find("crystal") or name:find("gem") or name:find("diamond") then
        info.Type, info.Base, info.Factor = "CRYSTAL", 0.12, 1.0
    elseif name:find("water") or name:find("ocean") or name:find("river") or name:find("pool") then
        info.Type, info.Base, info.Factor = "WATER", 0.10, 0.6
    end

    if info.Type == "DEFAULT" then
        if material == Enum.Material.Wood or material == Enum.Material.WoodPlanks then
            info.Factor = 0.5
        end
        local size = part.Size
        local up = part.CFrame.UpVector.Y
        local area = size.X * size.Z
        local flatLarge = up > 0.9 and area >= 300
        local groundMaterial = GROUND_MATERIALS[material] and up > 0.85 and size.Y <= 8 and area >= 60

        if flatLarge or groundMaterial then
            info.Ground = true
            info.Factor = 0.4
        end
    end
    return info
end

----------------------------------------------------------------
-- CAHAYA TELUR
----------------------------------------------------------------

local Eggs = { Records = {}, Keys = setmetatable({}, weakKeys), Timer = 0 }
local eggRng = Random.new(77)
local GLOW_LAYERS = {
    { size = 1.00, alpha = 0.10 },
    { size = 0.62, alpha = 0.16 },
    { size = 0.30, alpha = 0.26 },
}

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

    local attachment = Instance.new("Attachment")
    attachment.Name = PREFIX .. "EggAttachment"
    attachment.Parent = lightPart
    attachment.WorldPosition = lightPart.Position + Vector3.new(0, kind == "spot" and 2.4 or 1.2, 0)

    local light = Instance.new("PointLight")
    light.Name = PREFIX .. "EggLight"
    light.Color = Settings.EggColor
    light.Range = Settings.EggRange
    light.Brightness = 0
    light.Shadows = false
    light.Enabled = false
    light.Parent = attachment

    local record = {
        Part = lightPart, Attachment = attachment, Light = light,
        Frames = {}, Phase = eggRng:NextNumber() * math.pi * 2, Level = 0, Wanted = false, Dist = math.huge,
    }

    if kind == "spot" then
        local glow = Instance.new("BillboardGui")
        glow.Name = PREFIX .. "EggGlow"
        glow.Adornee = attachment
        glow.Size = UDim2.fromScale(8, 8)
        glow.AlwaysOnTop = false
        glow.LightInfluence = 0
        glow.MaxDistance = 220
        glow.Enabled = false
        glow.Parent = lightPart

        for _, layer in ipairs(GLOW_LAYERS) do
            local f = Instance.new("Frame")
            f.BorderSizePixel = 0
            f.AnchorPoint = Vector2.new(0.5, 0.5)
            f.Position = UDim2.fromScale(0.5, 0.5)
            f.Size = UDim2.fromScale(layer.size, layer.size)
            f.BackgroundColor3 = Settings.EggColor
            f.BackgroundTransparency = 1
            f.Parent = glow
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(1, 0)
            corner.Parent = f
            table.insert(record.Frames, { Frame = f, Alpha = layer.alpha })
        end
        record.Glow = glow
    end
    table.insert(Eggs.Records, record)
    State.Stats.Eggs = #Eggs.Records
end

local function destroyEgg(record)
    if record.Light then record.Light:Destroy() end
    if record.Glow then record.Glow:Destroy() end
    if record.Attachment then record.Attachment:Destroy() end
end

local function updateEggs(dt)
    local mood = State.Mood
    local glow = mood and mood.EggGlow or 0
    local now = os.clock()

    Eggs.Timer += dt
    if Eggs.Timer >= 0.5 then
        Eggs.Timer = 0
        local cam = Workspace.CurrentCamera
        local camPos = cam and cam.CFrame.Position

        for i = #Eggs.Records, 1, -1 do
            local record = Eggs.Records[i]
            if not record.Part.Parent then
                destroyEgg(record)
                table.remove(Eggs.Records, i)
            else
                record.Dist = camPos and (record.Part.Position - camPos).Magnitude or math.huge
            end
        end

        local sorted = table.clone(Eggs.Records)
        table.sort(sorted, function(a, b) return a.Dist < b.Dist end)
        local maxLights = math.floor(Settings.EggMaxLights * (0.5 + 0.5 * State.Scale))
        for index, record in ipairs(sorted) do
            record.Wanted = index <= maxLights and record.Dist <= Settings.EggDistance
        end
        State.Stats.Eggs = #Eggs.Records
    end

    local speed = math.min(1, dt * 2)
    for _, record in ipairs(Eggs.Records) do
        local target = (glow > 0 and record.Wanted) and 1 or 0
        record.Level = lerp(record.Level, target, speed)

        if record.Level > 0.02 then
            local breathing = 1 + 0.05 * math.sin(now * 1.3 + record.Phase)
            local strength = record.Level * math.min(1, glow)
            record.Light.Brightness = strength * Settings.EggBrightness * breathing
            record.Light.Enabled = true
            if record.Glow then
                record.Glow.Enabled = true
                for _, item in ipairs(record.Frames) do
                    item.Frame.BackgroundTransparency = 1 - item.Alpha * strength * breathing
                end
            end
        else
            record.Light.Enabled = false
            if record.Glow then record.Glow.Enabled = false end
        end
    end
end

----------------------------------------------------------------
-- PROSES PART
----------------------------------------------------------------

local function processPart(part)
    if PartInfo[part] then return PartInfo[part] end
    if not isVisualPart(part) then return nil end

    rememberPart(part)
    local info = classifyPart(part)

    if info.Type == "DEFAULT" and not info.Ground and part.Material == Enum.Material.Plastic then
        local variant = getProperty(part, "MaterialVariant", "")
        if not variant or variant == "" then
            setProperty(part, "Material", Enum.Material.SmoothPlastic)
        end
    end
    setProperty(part, "CastShadow", true)
    if info.SA then rememberSurfaceAppearance(info.SA) end

    PartInfo[part] = info
    table.insert(PartList, part)
    State.Stats.Parts += 1
    if info.Ground then State.Stats.Ground += 1 end
    return info
end

local SLICK_MATERIALS = {
    [Enum.Material.Concrete] = true, [Enum.Material.Asphalt] = true,
    [Enum.Material.Pavement] = true, [Enum.Material.Cobblestone] = true,
    [Enum.Material.Brick] = true, [Enum.Material.Slate] = true,
    [Enum.Material.Granite] = true, [Enum.Material.Limestone] = true,
    [Enum.Material.WoodPlanks] = true, [Enum.Material.Plastic] = true,
}

local function stylePart(part, mood)
    local info = PartInfo[part]
    local original = Original.Parts[part]
    if not info or not original or not part.Parent then return end

    local sheen = mood.Sheen * State.Scale
    local wet = mood.Wet == true and info.Ground
    local add = 0

    if info.Type ~= "EMISSIVE" then
        add = info.Base + sheen * info.Factor
    end
    if wet then add = math.max(add, 0.5) end

    local originalReflectance = original.Reflectance or 0
    setProperty(part, "Reflectance", math.clamp(math.max(originalReflectance, add), 0, 0.6))

    local variant = getProperty(part, "MaterialVariant", "")
    if wet and not info.SA and SLICK_MATERIALS[original.Material] and (not variant or variant == "") then
        if part.Material ~= Enum.Material.SmoothPlastic then
            setProperty(part, "Material", Enum.Material.SmoothPlastic)
            info.Slick = true
        end
    elseif info.Slick then
        setProperty(part, "Material", original.Material)
        info.Slick = false
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
    for i = #PartList, 1, -1 do
        if not PartList[i].Parent then table.remove(PartList, i) end
    end
    for _, part in ipairs(PartList) do
        if myJob ~= styleJob or State.Restored then return end
        stylePart(part, mood)
        count += 1
        if count % 300 == 0 then task.wait() end
    end
end

local TERRAIN_MATERIALS = {
    Enum.Material.Grass, Enum.Material.LeafyGrass, Enum.Material.Ground, Enum.Material.Mud,
    Enum.Material.Sand, Enum.Material.Sandstone, Enum.Material.Asphalt, Enum.Material.Pavement,
    Enum.Material.Concrete, Enum.Material.Cobblestone, Enum.Material.Rock, Enum.Material.Slate,
    Enum.Material.Limestone, Enum.Material.Basalt,
}

local function setTerrainWet(on)
    for _, material in ipairs(TERRAIN_MATERIALS) do
        if Original.TerrainColors[material] == nil then
            Original.TerrainColors[material] = safe(function() return Terrain:GetMaterialColor(material) end, false)
        end
        local original = Original.TerrainColors[material]
        if original then
            local wanted = on and wetColor(original) or original
            safe(function() Terrain:SetMaterialColor(material, wanted) end)
        end
    end
end

local function scanWorld()
    local descendants = Workspace:GetDescendants()
    for i, object in ipairs(descendants) do
        if object:IsA("BasePart") then
            registerEgg(object)
            processPart(object)
        end
        if i % 500 == 0 then task.wait() end
    end
    ScanDone = true
end

----------------------------------------------------------------
-- LAMPU AKSEN
----------------------------------------------------------------

local LIGHT_TOKENS = {
    "lamp", "light", "lantern", "torch", "fire", "flame", "bulb", "neon",
    "screen", "monitor", "sign", "crystal", "portal", "glow", "energy", "lava",
}

local function isLightSourcePart(part)
    local name = string.lower(part.Name)
    for _, token in ipairs(LIGHT_TOKENS) do
        if name:find(token, 1, true) then return true end
    end
    return part.Material == Enum.Material.Neon
end

local function getLightColor(part)
    if part.Material == Enum.Material.Neon then return part.Color end
    local name = string.lower(part.Name)
    if name:find("fire") or name:find("flame") or name:find("torch") or name:find("lava") then
        return rgb(255, 170, 90)
    end
    if name:find("crystal") or name:find("ice") then return rgb(150, 210, 255) end
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
    clearAccentLights()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local camPos = cam.CFrame.Position
    local candidates = {}

    for _, part in ipairs(PartList) do
        if part.Parent and isLightSourcePart(part) then
            local distance = (part.Position - camPos).Magnitude
            if distance <= Settings.LightDistance then
                table.insert(candidates, { Part = part, Dist = distance })
            end
        end
    end

    table.sort(candidates, function(a, b) return a.Dist < b.Dist end)
    local maxLights = math.floor(Settings.MaxAccentLights * State.Scale)

    for _, candidate in ipairs(candidates) do
        if #State.AccentLights >= maxLights then break end
        local part = candidate.Part
        if not part:FindFirstChild(PREFIX .. "AccentAttachment") then
            local attachment = Instance.new("Attachment")
            attachment.Name = PREFIX .. "AccentAttachment"
            attachment.Parent = part

            local light = Instance.new("PointLight")
            light.Name = PREFIX .. "AccentLight"
            light.Color = getLightColor(part)
            light.Brightness = 0.65
            light.Range = 12
            light.Shadows = true
            light.Parent = attachment

            table.insert(State.AccentLights, { Source = part, Attachment = attachment, Light = light })
        end
    end
    State.Stats.Lights = #State.AccentLights
end

----------------------------------------------------------------
-- DUNIA 3D: MATAHARI, RAYS, HUJAN
----------------------------------------------------------------

local World = {}

do
    local MAX_SHAFTS = 36
    local MAX_PUDDLES = 70
    local RAIN_TEXTURE = ""
    local RAIN_SOUND_ID = ""
    local RAIN_SOUND_VOLUME = 0.5
    local rng = Random.new(1987)

    local anchor, sunPart, sunGui, sunStreak, lensFlareStreak
    local sunLayers = {}
    local sunExtras = {}
    local bokehPart, bokehEmitter
    local shafts = {}
    local puddles = {}
    local rainPart, rainEmitter, rainSound

    local mood
    local built = false
    local rayParams

    local rainLevel = 0
    local coverLevel = 1
    local coverTarget = 1
    local lastSeedPos, lastSeedSun, lastPuddlePos
    local timers = { Shaft = 0, Rain = 0 }
    local cloudsState
    local bodyAttachment, bodyLight
    local bodyBrightness = 0

    local function updateRayParams()
        rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.RespectCanCollide = false
        local list = { WorldFolder }
        if Player.Character then table.insert(list, Player.Character) end
        rayParams.FilterDescendantsInstances = list
        updateSunRay()
    end

    World.UpdateRayParams = updateRayParams

    -- DIUPDATE: Warna lebih terang, dominan oranye, dengan inti putih-panas
    local SUN_LAYERS = {
        { size = 0.70, alpha = 0.90, color = rgb(255, 140, 40) },  -- Outer soft orange
        { size = 0.45, alpha = 0.95, color = rgb(255, 110, 20) },  -- Mid vibrant orange
        { size = 0.20, alpha = 0.98, color = rgb(255, 180, 80) },  -- Inner bright orange
        { size = 0.08, alpha = 1.00, color = rgb(255, 235, 180) }, -- White-hot core
    }

    local function makeInvisiblePart(name)
        local p = Instance.new("Part")
        p.Name = name
        p.Anchored = true
        p.CanCollide = false
        p.CanQuery = false
        p.CanTouch = false
        p.CastShadow = false
        p.Transparency = 1
        p.Size = Vector3.new(0.2, 0.2, 0.2)
        p.Parent = WorldFolder
        return p
    end

    local function build()
        if built then return end
        built = true
        updateRayParams()

        anchor = makeInvisiblePart(PREFIX .. "Anchor")
        anchor.CFrame = CFrame.new(0, 0, 0)

        sunPart = makeInvisiblePart(PREFIX .. "Matahari")
        sunGui = Instance.new("BillboardGui")
        sunGui.Name = PREFIX .. "GlowMatahari"
        sunGui.Adornee = sunPart
        sunGui.AlwaysOnTop = false
        sunGui.LightInfluence = 0
        sunGui.MaxDistance = math.huge
        sunGui.Size = UDim2.fromScale(Settings.SunSize, Settings.SunSize)
        sunGui.Enabled = false
        sunGui.Parent = sunPart

        for _, def in ipairs(SUN_LAYERS) do
            local f = Instance.new("Frame")
            f.BorderSizePixel = 0
            f.AnchorPoint = Vector2.new(0.5, 0.5)
            f.Position = UDim2.fromScale(0.5, 0.5)
            f.Size = UDim2.fromScale(def.size, def.size)
            f.BackgroundColor3 = def.color
            f.BackgroundTransparency = 1
            f.Parent = sunGui
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(1, 0)
            corner.Parent = f
            table.insert(sunLayers, { Frame = f, Alpha = def.alpha })
        end

        sunStreak = Instance.new("Frame")
        sunStreak.BorderSizePixel = 0
        sunStreak.AnchorPoint = Vector2.new(0.5, 0.5)
        sunStreak.Position = UDim2.fromScale(0.5, 0.5)
        sunStreak.Size = UDim2.fromScale(1.5, 0.01)
        sunStreak.BackgroundColor3 = rgb(255, 205, 140)
        sunStreak.BackgroundTransparency = 1
        sunStreak.Parent = sunGui

        local streakGradient = Instance.new("UIGradient")
        streakGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0.3),
            NumberSequenceKeypoint.new(1, 1),
        })
        streakGradient.Parent = sunStreak

        -- DIUPDATE: Garis-garis cahaya radial yang lebih indah dan halus (8 garis)
        for i = 1, 8 do
            local f = Instance.new("Frame")
            f.BorderSizePixel = 0
            f.AnchorPoint = Vector2.new(0.5, 0.5)
            f.Position = UDim2.fromScale(0.5, 0.5)
            f.Size = UDim2.fromScale(2.5, 0.015) -- Lebih panjang dan tipis
            f.Rotation = (i - 1) * (180 / 8)
            f.BackgroundColor3 = rgb(255, 210, 120)
            f.BackgroundTransparency = 1
            f.Parent = sunGui

            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(1, 0)
            c.Parent = f

            local g = Instance.new("UIGradient")
            g.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.4, 0.2), -- Lebih lembut di tengah
                NumberSequenceKeypoint.new(0.6, 0.2),
                NumberSequenceKeypoint.new(1, 1),
            })
            g.Parent = f

            table.insert(sunExtras, { Frame = f, Alpha = 0.7 })
        end

        -- DIUPDATE: Lens flare horizontal tambahan saat menatap matahari
        lensFlareStreak = Instance.new("Frame")
        lensFlareStreak.BorderSizePixel = 0
        lensFlareStreak.AnchorPoint = Vector2.new(0.5, 0.5)
        lensFlareStreak.Position = UDim2.fromScale(0.5, 0.5)
        lensFlareStreak.Size = UDim2.fromScale(3.5, 0.02) -- Garis horizontal panjang
        lensFlareStreak.BackgroundColor3 = rgb(255, 220, 150)
        lensFlareStreak.BackgroundTransparency = 1
        lensFlareStreak.Parent = sunGui

        local lfGradient = Instance.new("UIGradient")
        lfGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0.4),
            NumberSequenceKeypoint.new(1, 1),
        })
        lfGradient.Parent = lensFlareStreak
        table.insert(sunExtras, { Frame = lensFlareStreak, Alpha = 0.5 })

        bokehPart = makeInvisiblePart(PREFIX .. "Bokeh")
        bokehPart.Size = Vector3.new(90, 40, 90)
        bokehEmitter = Instance.new("ParticleEmitter")
        bokehEmitter.Rate = 0
        bokehEmitter.Lifetime = NumberRange.new(4, 7)
        bokehEmitter.Speed = NumberRange.new(0.3, 1.2)
        bokehEmitter.SpreadAngle = Vector2.new(180, 180)
        bokehEmitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 1.1), NumberSequenceKeypoint.new(1, 0.4),
        })
        bokehEmitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.25, 0.55),
            NumberSequenceKeypoint.new(0.75, 0.65), NumberSequenceKeypoint.new(1, 1),
        })
        bokehEmitter.Color = ColorSequence.new(rgb(255, 150, 50), rgb(255, 205, 100))
        bokehEmitter.LightEmission = 1
        bokehEmitter.LightInfluence = 0
        bokehEmitter.LockedToPart = false
        bokehEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        bokehEmitter.Parent = bokehPart

        for _ = 1, MAX_SHAFTS do
            local a0 = Instance.new("Attachment")
            a0.Parent = anchor
            local a1 = Instance.new("Attachment")
            a1.Parent = anchor
            local beam = Instance.new("Beam")
            beam.Attachment0 = a0
            beam.Attachment1 = a1
            beam.FaceCamera = true
            beam.LightEmission = 1
            beam.LightInfluence = 0
            beam.Segments = 1
            beam.Transparency = NumberSequence.new(1)
            beam.Enabled = false
            beam.Parent = anchor
            table.insert(shafts, { Beam = beam, A0 = a0, A1 = a1, Active = false, Pos = Vector3.zero, Rand = 1 })
        end

        rainPart = makeInvisiblePart(PREFIX .. "Hujan")
        rainPart.Size = Vector3.new(100, 1, 100)
        rainEmitter = {}
        local texture = RAIN_TEXTURE ~= "" and RAIN_TEXTURE or "rbxasset://textures/particles/sparkles_main.dds"
        local rainLayers = {
            { weight = 0.40, size = 0.70, squash = -0.88, transparency = 0.45, speed = NumberRange.new(100, 125), life = NumberRange.new(0.7, 0.9) },
            { weight = 0.35, size = 0.50, squash = -0.85, transparency = 0.60, speed = NumberRange.new(85, 105), life = NumberRange.new(0.75, 0.95) },
            { weight = 0.25, size = 0.35, squash = -0.80, transparency = 0.70, speed = NumberRange.new(70, 90), life = NumberRange.new(0.8, 1.0) },
        }
        for _, layer in ipairs(rainLayers) do
            local e = Instance.new("ParticleEmitter")
            e.Rate = 0
            e.Lifetime = layer.life
            e.Speed = layer.speed
            e.EmissionDirection = Enum.NormalId.Bottom
            e.SpreadAngle = Vector2.new(2, 2)
            e.Size = NumberSequence.new(layer.size)
            e.Squash = NumberSequence.new(layer.squash)
            e.Transparency = NumberSequence.new(layer.transparency)
            e.Color = ColorSequence.new(rgb(205, 220, 238))
            e.LightEmission = 0.25
            e.LightInfluence = 0.5
            e.Acceleration = Vector3.new(6, 0, 3)
            e.LockedToPart = false
            e.Orientation = Enum.ParticleOrientation.VelocityParallel
            e.Texture = texture
            e.Parent = rainPart
            table.insert(rainEmitter, { Emitter = e, Weight = layer.weight })
        end

        if RAIN_SOUND_ID ~= "" then
            rainSound = Instance.new("Sound")
            rainSound.Name = PREFIX .. "SuaraHujan"
            rainSound.SoundId = RAIN_SOUND_ID
            rainSound.Looped = true
            rainSound.Volume = 0
            rainSound.Parent = SoundService
            rainSound:Play()
        end
    end

    local function applyClouds(m)
        if m and m.CloudColor ~= nil then
            if not cloudsState then
                local existing = Terrain:FindFirstChildOfClass("Clouds")
                if existing then
                    cloudsState = {
                        Object = existing, Owned = false,
                        Saved = { Color = existing.Color, Cover = existing.Cover, Density = existing.Density, Enabled = existing.Enabled },
                    }
                else
                    local c = Instance.new("Clouds")
                    c.Name = PREFIX .. "Awan"
                    c.Parent = Terrain
                    cloudsState = { Object = c, Owned = true }
                end
            end
            local c = cloudsState.Object
            setProperty(c, "Color", m.CloudColor)
            setProperty(c, "Cover", m.CloudCover or 0.5)
            setProperty(c, "Density", m.CloudDensity or 0.5)
            setProperty(c, "Enabled", true)
        elseif cloudsState then
            if cloudsState.Owned then
                if cloudsState.Object.Parent then cloudsState.Object:Destroy() end
            else
                for property, value in pairs(cloudsState.Saved) do
                    setProperty(cloudsState.Object, property, value)
                end
            end
            cloudsState = nil
        end
    end

    local function seedShafts(camPos)
        local sunDir = Sun.Dir
        local count = math.floor(MAX_SHAFTS * State.Scale)
        local color = mood.ShaftColor
        local flat = Vector3.new(sunDir.X, 0, sunDir.Z)
        local azimuth = rng:NextNumber(0, math.pi * 2)
        if flat.Magnitude > 0.01 then azimuth = math.atan2(flat.Z, flat.X) end
        local maxLen = 140

        for index, shaft in ipairs(shafts) do
            shaft.Active = false
            if index <= count then
                local angle = rng:NextNumber() < 0.7 and (azimuth + rng:NextNumber(-1.2, 1.2)) or rng:NextNumber(0, math.pi * 2)
                local radius = 20 + 150 * math.sqrt(rng:NextNumber())
                local origin = camPos + Vector3.new(math.cos(angle) * radius, 150, math.sin(angle) * radius)
                local hit = Workspace:Raycast(origin, Vector3.new(0, -400, 0), rayParams)

                if hit and hit.Normal.Y > 0.3 then
                    local ground = hit.Position + Vector3.new(0, 0.5 + rng:NextNumber(0, 2), 0)
                    local blocked = Workspace:Raycast(ground, sunDir * maxLen, rayParams)
                    local length = blocked and (blocked.Position - ground).Magnitude or maxLen

                    if length > 12 then
                        local width = rng:NextNumber(6, 14)
                        shaft.A0.Position = ground
                        shaft.A1.Position = ground + sunDir * length
                        shaft.Beam.Width0 = width
                        shaft.Beam.Width1 = width * 1.3
                        shaft.Beam.Color = ColorSequence.new(color)
                        shaft.Pos = ground
                        shaft.Rand = rng:NextNumber(0.6, 1.0)
                        shaft.Active = true
                    end
                end
            end
        end
        lastSeedPos = camPos
        lastSeedSun = sunDir
    end

    local function newGlassBlock()
        local p = Instance.new("Part")
        p.Name = PREFIX .. "GenanganKaca"
        p.Anchored = true
        p.CanCollide = false
        p.CanQuery = false
        p.CanTouch = false
        p.CastShadow = false
        p.Material = Enum.Material.Glass
        p.Color = rgb(214, 232, 246)
        p.Reflectance = 0.7
        p.Transparency = 1
        return p
    end

    local function setPuddlesTransparency(t)
        for _, puddle in ipairs(puddles) do
            for _, block in ipairs(puddle) do block.Transparency = t end
        end
    end

    local function hidePuddle(puddle)
        for _, block in ipairs(puddle) do block.Parent = nil end
    end

    local function placePuddles(center)
        local count = math.floor(MAX_PUDDLES * State.Scale)
        local below = Workspace:Raycast(center, Vector3.new(0, -300, 0), rayParams)
        local refY = below and below.Position.Y or (center.Y - 3)

        for index = 1, MAX_PUDDLES do
            local puddle = puddles[index]
            if index > count then
                if puddle then hidePuddle(puddle) end
            else
                if not puddle then puddle = { newGlassBlock(), newGlassBlock(), newGlassBlock() } end
                puddles[index] = puddle

                local angle = rng:NextNumber(0, math.pi * 2)
                local radius = 4 + 100 * math.sqrt(rng:NextNumber())
                local origin = center + Vector3.new(math.cos(angle) * radius, 120, math.sin(angle) * radius)
                local hit = Workspace:Raycast(origin, Vector3.new(0, -300, 0), rayParams)

                local valid = false
                if hit then
                    if hit.Instance:IsA("Terrain") then
                        valid = hit.Normal.Y > 0.88 and hit.Material ~= Enum.Material.Water
                    elseif hit.Normal.Y > 0.95 then
                        local info = PartInfo[hit.Instance]
                        valid = (info ~= nil and info.Ground) or math.abs(hit.Position.Y - refY) < 3
                    end
                    if valid and Workspace:Raycast(hit.Position + Vector3.new(0, 1, 0), Vector3.new(0, 40, 0), rayParams) then
                        valid = false
                    end
                end

                if valid then
                    local pos = hit.Position
                    local yaw = rng:NextNumber(0, math.pi)
                    local w = rng:NextNumber(4, 11)
                    local l = w * rng:NextNumber(0.55, 0.9)

                    puddle[1].Size = Vector3.new(w, 0.04, l)
                    puddle[1].CFrame = CFrame.new(pos + Vector3.new(0, 0.04, 0)) * CFrame.Angles(0, yaw, 0)

                    local s2 = Vector3.new(rng:NextNumber(-0.22, 0.22) * w, 0.052, rng:NextNumber(-0.22, 0.22) * l)
                    puddle[2].Size = Vector3.new(w * 0.62, 0.04, l * 1.3)
                    puddle[2].CFrame = CFrame.new(pos + s2) * CFrame.Angles(0, yaw + rng:NextNumber(0.5, 1.1), 0)

                    local s3 = Vector3.new(rng:NextNumber(-0.3, 0.3) * w, 0.064, rng:NextNumber(-0.3, 0.3) * l)
                    puddle[3].Size = Vector3.new(w * 0.4, 0.04, l * 0.55)
                    puddle[3].CFrame = CFrame.new(pos + s3) * CFrame.Angles(0, yaw - rng:NextNumber(0.4, 1.0), 0)

                    for _, block in ipairs(puddle) do block.Parent = WorldFolder end
                else
                    hidePuddle(puddle)
                end
            end
        end
        lastPuddlePos = center
    end

    local function updateBody(dt)
        local char = Player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        if not bodyAttachment or not bodyAttachment.Parent then
            bodyAttachment = Instance.new("Attachment")
            bodyAttachment.Name = PREFIX .. "CahayaTubuh"
            bodyAttachment.Parent = anchor
            bodyLight = Instance.new("PointLight")
            bodyLight.Name = PREFIX .. "CahayaTubuhLampu"
            bodyLight.Color = rgb(255, 150, 70)
            bodyLight.Range = 16
            bodyLight.Brightness = 0
            bodyLight.Shadows = false
            bodyLight.Parent = bodyAttachment
        end

        local sunDir = Sun.Dir
        bodyAttachment.Position = root.Position + sunDir * 7 + Vector3.new(0, 1.5, 0)
        local covered = Workspace:Raycast(root.Position + Vector3.new(0, 2, 0), sunDir * 300, rayParams) ~= nil
        local elevation = math.clamp(sunDir.Y * 4 + 0.35, 0, 1)
        local target = covered and 0 or (1.0 * elevation * (0.4 + 0.6 * math.min(1, Sun.Scale)))

        bodyBrightness = lerp(bodyBrightness, target, math.min(1, dt * 2.5))
        bodyLight.Brightness = bodyBrightness
    end

    function World.SetMood(m)
        build()
        mood = m
        lastSeedPos = nil
        lastPuddlePos = nil
        applyClouds(m)
        if not m.WarmBody and bodyLight then
            bodyLight.Brightness = 0
            bodyBrightness = 0
        end
    end

    function World.Update(dt)
        if not built or not mood then return end
        local cam = Workspace.CurrentCamera
        if not cam then return end

        local scale = State.Scale
        local sunDir = Sun.Dir
        local camPos = cam.CFrame.Position
        local facing = Sun.Facing
        local f2 = facing * facing
        local f3 = f2 * facing
        local distFade = clamp01(Sun.Scale)
        local sunSensitive = mood.SunGlow > 0 and 1 or 0
        local glow = mood.SunGlow * Sun.Elev

        sunGui.Enabled = glow > 0.01
        if sunGui.Enabled then
            sunPart.CFrame = CFrame.new(Sun.Pos)
            local a = clamp01(glow * (0.6 + 0.4 * facing))
            for _, layer in ipairs(sunLayers) do
                layer.Frame.BackgroundTransparency = 1 - (1 - layer.Alpha) * a
            end
            sunStreak.BackgroundTransparency = 1 - 0.75 * a * (0.3 + 0.7 * facing)

            -- DIUPDATE: Garis cahaya (sunExtras) HANYA muncul jelas saat menatap matahari (facing tinggi)
            for _, extra in ipairs(sunExtras) do
                local rayVisibility = extra.Alpha * a * (0.05 + 0.95 * facing) -- 0.95 * facing membuat efek ini sangat kuat saat dilihat langsung
                extra.Frame.BackgroundTransparency = 1 - rayVisibility
            end
        end

        local sens = Sun.Elev * Sun.Open * sunSensitive * distFade
        local bloom = State.Instances.Bloom
        if bloom and bloom.Parent then
            bloom.Intensity = State.Base.Bloom + 0.45 * f3 * sens
        end

        local rays = State.Instances.SunRays
        if rays and rays.Parent then
            -- DIUPDATE: SunRaysEffect bawaan Roblox ditingkatkan drastis saat menatap matahari
            local lookBonus = f3 * 1.5
            rays.Intensity = State.Base.SunRays + lookBonus * sens
        end

        local grade = State.Instances.Color
        if grade and grade.Parent then
            grade.TintColor = State.Base.Tint:Lerp(rgb(255, 200, 140), 0.25 * f2 * sens)
            grade.Saturation = State.Base.Saturation + 0.04 * f2 * sens
            grade.Brightness = 0.05 * f3 * sens
        end

        local atmosphere = State.Instances.Atmosphere
        if atmosphere and atmosphere.Parent then
            atmosphere.Glare = math.min(1, State.Base.Glare + 0.25 * f2 * sens)
        end

        timers.Shaft += dt
        if timers.Shaft >= 0.15 then
            timers.Shaft = 0
            local strength = mood.Shafts * scale * Sun.Elev * (0.45 + 0.55 * distFade)
            if strength <= 0.01 then
                lastSeedPos = nil
            elseif not lastSeedPos or (camPos - lastSeedPos).Magnitude > 45 or not lastSeedSun or lastSeedSun:Dot(sunDir) < 0.9997 then
                seedShafts(camPos)
            end

            for _, shaft in ipairs(shafts) do
                if shaft.Active and strength > 0.01 then
                    local distance = (shaft.Pos - camPos).Magnitude
                    local near = clamp01((distance - 10) / 25)
                    local amount = strength * (0.30 + 0.70 * facing) * shaft.Rand * 0.19 * near
                    local t = 1 - clamp01(amount)
                    shaft.Beam.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, t),
                        NumberSequenceKeypoint.new(0.6, math.min(1, t + (1 - t) * 0.5)), NumberSequenceKeypoint.new(1, 1),
                    })
                    shaft.Beam.Enabled = true
                else
                    shaft.Beam.Enabled = false
                end
            end
        end

        local rainTarget = mood.Rain and 1 or 0
        rainLevel = lerp(rainLevel, rainTarget, math.min(1, dt * 0.4))
        timers.Rain += dt
        if timers.Rain >= 0.2 then
            timers.Rain = 0
            local covered = Workspace:Raycast(camPos, Vector3.new(0, 90, 0), rayParams) ~= nil
            coverTarget = covered and 0.08 or 1

            if rainLevel > 0.03 then
                if not lastPuddlePos or (camPos - lastPuddlePos).Magnitude > 50 then placePuddles(camPos) end
                setPuddlesTransparency(1 - 0.55 * clamp01(rainLevel * 1.2))
            elseif lastPuddlePos then
                setPuddlesTransparency(1)
                lastPuddlePos = nil
            end
        end

        coverLevel = lerp(coverLevel, coverTarget, math.min(1, dt * 3))
        rainPart.CFrame = CFrame.new(camPos + Vector3.new(0, 42, 0))
        local totalRate = 4200 * scale * rainLevel * coverLevel
        for _, item in ipairs(rainEmitter) do
            item.Emitter.Rate = totalRate * item.Weight
        end
        if rainSound then
            rainSound.Volume = RAIN_SOUND_VOLUME * rainLevel * (0.35 + 0.65 * coverLevel)
        end

        if bokehPart and bokehEmitter then
            local flat = Vector3.new(sunDir.X, 0, sunDir.Z)
            flat = flat.Magnitude > 0.01 and flat.Unit or Vector3.new(0, 0, -1)
            bokehPart.CFrame = CFrame.new(camPos + flat * 40 + Vector3.new(0, 6, 0))
            local strength = mood.Flare * Sun.Elev * Sun.Open * distFade * (0.4 + 0.6 * facing) * scale
            bokehEmitter.Rate = 14 * strength
        end

        if mood.WarmBody then updateBody(dt) end
    end

    function World.Destroy()
        applyClouds(nil)
        if rainSound then rainSound:Destroy(); rainSound = nil end
        for _, puddle in ipairs(puddles) do
            for _, block in ipairs(puddle) do block:Destroy() end
        end
        table.clear(puddles)
        table.clear(shafts)
        table.clear(sunLayers)
        table.clear(sunExtras)
        bokehPart = nil
        bokehEmitter = nil
        WorldFolder:ClearAllChildren()
        bodyAttachment = nil
        bodyLight = nil
        built = false
        mood = nil
    end
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
    if #list == 0 then
        table.insert(list, Moods[1])
        State.Selected = { Moods[1].Name }
    end
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
    State.Quality = level
    State.Scale = qualityScale(level)
    applyMoods()
    task.spawn(scanAccentLights)
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
    State.Selected = { name }
    applyMoods()
    onSelectionChanged()
    return true
end

function API.SetMoods(names)
    local list = {}
    for _, name in ipairs(names) do
        if MoodByName[name] then table.insert(list, name) end
    end
    if #list == 0 then return false end
    State.Selected = list
    applyMoods()
    onSelectionChanged()
    return true
end

function API.ToggleMood(name)
    if not MoodByName[name] then return false end
    local index = table.find(State.Selected, name)
    if index then
        if #State.Selected > 1 then table.remove(State.Selected, index) end
    else
        table.insert(State.Selected, name)
    end
    applyMoods()
    onSelectionChanged()
    return true
end

function API.GetMood() return selectedLabel() end
function API.GetActive() return table.clone(State.Selected) end
function API.GetMoods()
    local names = {}
    for _, mood in ipairs(Moods) do table.insert(names, mood.Name) end
    return names
end
function API.GetStats() return State.Stats end
function API.SetSunAnchor(position) Sun.Anchor = position end
function API.ResetSunAnchor() Sun.Anchor = nil end

function API.Refresh()
    task.spawn(function()
        scanWorld()
        styleParts(State.Mood)
        scanAccentLights()
    end)
end

----------------------------------------------------------------
-- RESTORE
----------------------------------------------------------------

local function restoreOriginal()
    if State.Restored then return end
    State.Restored = true
    styleJob += 1

    for _, connection in ipairs(State.Connections) do connection:Disconnect() end
    table.clear(State.Connections)

    for property, value in pairs(Original.Lighting) do
        if value ~= nil then setProperty(Lighting, property, value) end
    end
    for part, data in pairs(Original.Parts) do
        if part and part.Parent then
            for property, value in pairs(data) do
                if value ~= nil then setProperty(part, property, value) end
            end
        end
    end
    for surface, data in pairs(Original.SurfaceAppearances) do
        if surface and surface.Parent then
            for property, value in pairs(data) do
                if value ~= nil then setProperty(surface, property, value) end
            end
        end
    end
    for material, color in pairs(Original.TerrainColors) do
        if color then safe(function() Terrain:SetMaterialColor(material, color) end) end
    end

    for _, record in ipairs(State.AccentLights) do
        if record.Light and record.Light.Parent then record.Light:Destroy() end
        if record.Attachment and record.Attachment.Parent then record.Attachment:Destroy() end
    end
    table.clear(State.AccentLights)

    for _, record in ipairs(Eggs.Records) do
        if record.Light then record.Light:Destroy() end
        if record.Glow then record.Glow:Destroy() end
        if record.Attachment then record.Attachment:Destroy() end
    end
    table.clear(Eggs.Records)

    if SkyState.Object then
        if SkyState.Owned then
            if SkyState.Object.Parent then SkyState.Object:Destroy() end
        elseif SkyState.Saved and SkyState.Object.Parent then
            for property, value in pairs(SkyState.Saved) do
                setProperty(SkyState.Object, property, value)
            end
        end
    end
    SkyState.Object = nil
    SkyState.Owned = false
    SkyState.Saved = nil

    World.Destroy()
    for _, instance in ipairs(Original.Created) do
        if instance and instance.Parent then instance:Destroy() end
    end
    for _, atmosphere in ipairs(Original.HiddenAtmospheres) do
        if atmosphere then atmosphere.Parent = Lighting end
    end
    if State.UI then State.UI:Destroy(); State.UI = nil end
    if WorldFolder then WorldFolder:Destroy() end
    if _G.Leon4951Shaders == API then _G.Leon4951Shaders = nil end
end
API.Restore = restoreOriginal

----------------------------------------------------------------
-- UI
----------------------------------------------------------------

local function createUI()
    if not Settings.ShowPanel then return end
    local ACCENT = rgb(255, 150, 60)
    local W = 200
    local TITLE_H = 28
    local BODY_H = 268
    local SCALES = { 0.8, 0.95, 1.15 }
    local scaleIndex = 2
    local tweenFast = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tweenSlow = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local gui = Instance.new("ScreenGui")
    gui.Name = ROOT
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 50
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = PlayerGui

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.AnchorPoint = Vector2.new(0, 0)
    panel.Position = UDim2.fromScale(0.012, 0.26)
    panel.Size = UDim2.fromOffset(W, TITLE_H + BODY_H)
    panel.BackgroundColor3 = rgb(16, 15, 18)
    panel.BackgroundTransparency = 0.08
    panel.BorderSizePixel = 0
    panel.ClipsDescendants = true
    panel.Parent = gui

    local uiScale = Instance.new("UIScale")
    uiScale.Scale = SCALES[scaleIndex]
    uiScale.Parent = panel
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = panel
    local stroke = Instance.new("UIStroke")
    stroke.Color = ACCENT
    stroke.Transparency = 0.7
    stroke.Thickness = 1
    stroke.Parent = panel

    local function makeButton(parent, text, x, y, w, h)
        local b = Instance.new("TextButton")
        b.AutoButtonColor = false
        b.Position = UDim2.fromOffset(x, y)
        b.Size = UDim2.fromOffset(w, h)
        b.BackgroundColor3 = rgb(34, 33, 38)
        b.BorderSizePixel = 0
        b.Font = Enum.Font.GothamBold
        b.TextSize = 11
        b.TextColor3 = rgb(215, 215, 222)
        b.Text = text
        b.Parent = parent
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = b
        return b
    end

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(10, 0)
    title.Size = UDim2.fromOffset(W - 74, TITLE_H)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = rgb(255, 232, 205)
    title.Text = "Leon4951 shaders"
    title.Parent = panel

    local sizeButton = makeButton(panel, "A", W - 62, 4, 24, 20)
    local collapseButton = makeButton(panel, "-", W - 34, 4, 24, 20)

    local body = Instance.new("Frame")
    body.BackgroundTransparency = 1
    body.Position = UDim2.fromOffset(0, TITLE_H)
    body.Size = UDim2.fromOffset(W, BODY_H)
    body.Parent = panel

    local qLabel = Instance.new("TextLabel")
    qLabel.BackgroundTransparency = 1
    qLabel.Position = UDim2.fromOffset(10, 2)
    qLabel.Size = UDim2.fromOffset(80, 22)
    qLabel.Font = Enum.Font.GothamMedium
    qLabel.TextSize = 10
    qLabel.TextXAlignment = Enum.TextXAlignment.Left
    qLabel.TextColor3 = rgb(170, 170, 180)
    qLabel.Text = "KUALITAS"
    qLabel.Parent = body

    local qMinus = makeButton(body, "-", W - 92, 3, 24, 20)
    local qValue = Instance.new("TextLabel")
    qValue.BackgroundTransparency = 1
    qValue.Position = UDim2.fromOffset(W - 66, 3)
    qValue.Size = UDim2.fromOffset(32, 20)
    qValue.Font = Enum.Font.GothamBold
    qValue.TextSize = 12
    qValue.TextColor3 = ACCENT
    qValue.Parent = body
    local qPlus = makeButton(body, "+", W - 34, 3, 24, 20)

    local function refreshQuality() qValue.Text = tostring(State.Quality) end
    refreshQuality()
    qMinus.MouseButton1Click:Connect(function() applyQuality(State.Quality - 1); refreshQuality() end)
    qPlus.MouseButton1Click:Connect(function() applyQuality(State.Quality + 1); refreshQuality() end)

    local listLabel = Instance.new("TextLabel")
    listLabel.BackgroundTransparency = 1
    listLabel.Position = UDim2.fromOffset(10, 28)
    listLabel.Size = UDim2.fromOffset(W - 20, 16)
    listLabel.Font = Enum.Font.GothamMedium
    listLabel.TextSize = 10
    listLabel.TextXAlignment = Enum.TextXAlignment.Left
    listLabel.TextColor3 = rgb(170, 170, 180)
    listLabel.Text = "SHADER  (tap beberapa = digabung)"
    listLabel.Parent = body

    local scroll = Instance.new("ScrollingFrame")
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.Position = UDim2.fromOffset(8, 46)
    scroll.Size = UDim2.fromOffset(W - 16, 190)
    scroll.ScrollBarThickness = 2
    scroll.ScrollBarImageColor3 = ACCENT
    scroll.CanvasSize = UDim2.fromOffset(0, 0)
    scroll.Parent = body

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 4)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = scroll
    local rows = {}

    local function refreshRows()
        for name, row in pairs(rows) do
            local on = table.find(State.Selected, name) ~= nil
            TweenService:Create(row.Button, tweenFast, {
                BackgroundColor3 = on and rgb(74, 44, 22) or rgb(28, 27, 32),
                TextColor3 = on and rgb(255, 236, 214) or rgb(180, 180, 190),
            }):Play()
            TweenService:Create(row.Dot, tweenFast, {
                BackgroundColor3 = on and ACCENT or rgb(70, 70, 78),
            }):Play()
        end
    end

    for index, mood in ipairs(Moods) do
        local button = Instance.new("TextButton")
        button.AutoButtonColor = false
        button.LayoutOrder = index
        button.Size = UDim2.new(1, -6, 0, 24)
        button.BackgroundColor3 = rgb(28, 27, 32)
        button.BorderSizePixel = 0
        button.Font = Enum.Font.GothamMedium
        button.TextSize = 11
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.TextColor3 = rgb(180, 180, 190)
        button.Text = "      " .. mood.Name .. (mood.Fx and "  +" or "")
        button.Parent = scroll
        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0, 6)
        bc.Parent = button
        local dot = Instance.new("Frame")
        dot.AnchorPoint = Vector2.new(0, 0.5)
        dot.Position = UDim2.new(0, 9, 0.5, 0)
        dot.Size = UDim2.fromOffset(7, 7)
        dot.BackgroundColor3 = rgb(70, 70, 78)
        dot.BorderSizePixel = 0
        dot.Parent = button
        local dc = Instance.new("UICorner")
        dc.CornerRadius = UDim.new(1, 0)
        dc.Parent = dot
        button.MouseButton1Click:Connect(function() API.ToggleMood(mood.Name) end)
        rows[mood.Name] = { Button = button, Dot = dot }
    end

    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.fromOffset(0, list.AbsoluteContentSize.Y + 6)
    end)

    local status = Instance.new("TextLabel")
    status.BackgroundTransparency = 1
    status.Position = UDim2.fromOffset(10, BODY_H - 26)
    status.Size = UDim2.fromOffset(W - 82, 22)
    status.Font = Enum.Font.Gotham
    status.TextSize = 9
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextTruncate = Enum.TextTruncate.AtEnd
    status.TextColor3 = rgb(135, 135, 148)
    status.Parent = body

    local offButton = makeButton(body, "Matikan", W - 68, BODY_H - 26, 58, 22)
    offButton.TextSize = 10
    offButton.MouseButton1Click:Connect(function() restoreOriginal() end)

    onSelectionChanged = refreshRows
    refreshRows()

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
        collapsed = not collapsed
        collapseButton.Text = collapsed and "+" or "-"
        if collapsed then
            local t = TweenService:Create(panel, tweenSlow, { Size = UDim2.fromOffset(W, TITLE_H) })
            t:Play()
            t.Completed:Connect(function() if collapsed then body.Visible = false end end)
        else
            body.Visible = true
            TweenService:Create(panel, tweenSlow, { Size = UDim2.fromOffset(W, TITLE_H + BODY_H) }):Play()
        end
    end)

    local dragging = false
    local dragStart, startAbs
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startAbs = panel.AbsolutePosition
        end
    end)
    title.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    table.insert(State.Connections, UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local screen = gui.AbsoluteSize
        local delta = input.Position - dragStart
        local panelSize = panel.AbsoluteSize
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
    fpsAccumulator += dt
    fpsFrames += 1
    if fpsAccumulator >= 1 then
        State.Stats.FPS = math.floor(fpsFrames / fpsAccumulator)
        fpsAccumulator = 0
        fpsFrames = 0
    end
end))

local lightTimer = 0
table.insert(State.Connections, RunService.Heartbeat:Connect(function(dt)
    if State.Restored then return end
    updateEggs(dt)
    lightTimer += dt
    if lightTimer < Settings.LightUpdateInterval then return end
    lightTimer = 0
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local camPos = cam.CFrame.Position
    for _, record in ipairs(State.AccentLights) do
        local source = record.Source
        local light = record.Light
        if source and source.Parent and light and light.Parent then
            local distance = (source.Position - camPos).Magnitude
            if distance > Settings.LightDistance then
                light.Enabled = false
            else
                light.Enabled = true
                local factor = 1 - math.clamp(distance / Settings.LightDistance, 0, 1)
                light.Brightness = lerp(0.15, 0.85, factor)
            end
        end
    end
end))

table.insert(State.Connections, Player.CharacterAdded:Connect(function() World.UpdateRayParams() end))
table.insert(State.Connections, Workspace.DescendantAdded:Connect(function(object)
    if State.Restored or not object:IsA("BasePart") then return end
    task.defer(function()
        registerEgg(object)
        if ScanDone and processPart(object) and State.Mood then stylePart(object, State.Mood) end
    end)
end))

----------------------------------------------------------------
-- MULAI
----------------------------------------------------------------

_G.Leon4951Shaders = API
_G.VisualRealistis = API
configureLightingBase()
applyQuality(Settings.Quality)
task.spawn(function()
    scanWorld()
    styleParts(State.Mood)
    scanAccentLights()
end)
createUI()