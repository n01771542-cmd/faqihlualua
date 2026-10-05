--[[
    LEON4951 SHADERS
    Roblox LocalScript
    Letakkan di: StarterPlayer > StarterPlayerScripts

    PERUBAHAN
    ---------
    1. Sore Keemasan: matahari DIAM di satu titik dunia. Makin jauh kamu dari
       titik itu, glow + lensa + sinar matahari makin kecil dan memudar.
    2. Suasana sore lebih gelap: oranye dominan, kuning halus, sedikit hitam.
       Cahaya dan bayangan dibuat lebih tegas. Matahari sedikit dikecilkan.
    3. UI kecil, halus, bisa digeser, dilipat, dan diganti ukurannya.
       Shader bisa DIGABUNG (tap beberapa sekaligus).
    4. Kabut lebih tebal dan sedikit lebih gelap.
    5. Malam: setiap tempat telur (nest, titik telur guard, telur yang
       ditaruh pemain) diberi cahaya hangat halus.
    6. Hujan: genangan tidak bulat, berupa lapisan kaca bening di lantai.
    7. Nama UI: Leon4951 shaders

    Semua efek hanya terlihat oleh pemain ini (client only).
    Restore(): mengembalikan semuanya.
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
    if not instance then
        return false
    end
    return safe(function()
        instance[property] = value
        return true
    end, false)
end

local function getProperty(instance, property, fallback)
    if not instance then
        return fallback
    end
    return safe(function()
        return instance[property]
    end, fallback)
end

local function hasProperty(instance, property)
    if not instance then
        return false
    end
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
    if Original.Lighting[property] ~= nil then
        return
    end
    Original.Lighting[property] = getProperty(Lighting, property, nil)
end

local function rememberPart(part)
    if Original.Parts[part] then
        return
    end
    Original.Parts[part] = {
        Material = getProperty(part, "Material", nil),
        Color = getProperty(part, "Color", nil),
        Reflectance = getProperty(part, "Reflectance", nil),
        CastShadow = getProperty(part, "CastShadow", nil),
    }
end

local function rememberSurfaceAppearance(surface)
    if Original.SurfaceAppearances[surface] then
        return
    end
    Original.SurfaceAppearances[surface] = {
        Color = getProperty(surface, "Color", nil),
    }
end

----------------------------------------------------------------
-- PENGATURAN
----------------------------------------------------------------

local Settings = {
    Quality = 8,                         -- 1 sampai 10
    StartMoods = { "Sore Keemasan" },    -- boleh lebih dari satu, contoh { "Sore Keemasan", "Hujan" }
    ShowPanel = true,

    -- Matahari diam di satu titik dunia
    SunDistance = 900,       -- jarak titik matahari dari titik awal (stud)
    SunFalloff = 1.6,        -- makin besar, efek makin cepat mengecil saat menjauh
    SunSize = 290,           -- ukuran glow matahari (stud), sedikit lebih kecil dari sebelumnya

    ShadowSoftness = 0.1,

    MaxAccentLights = 80,
    LightDistance = 500,
    LightUpdateInterval = 0.12,

    -- Cahaya telur (malam)
    EggRange = 15,
    EggBrightness = 1.0,
    EggMaxLights = 48,
    EggDistance = 320,
    EggColor = rgb(255, 176, 100),
}

----------------------------------------------------------------
-- DAFTAR SUASANA
----------------------------------------------------------------
-- Fx = true  -> efek tambahan (hujan, kabut); kalau digabung, jam & matahari
--               mengikuti suasana utama (non-Fx).
-- Overlay    -> lapisan warna halus di layar (oranye-hitam untuk sore)

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
        Name = "Pagi Segar",
        ClockTime = 7.2, Brightness = 2.30, Exposure = 0.03, ShadowSoftness = 0.18,
        Density = 0.30, Offset = 0.12, Haze = 0.9, Glare = 0.30,
        Color = rgb(210, 228, 255), Decay = rgb(240, 205, 170),
        Ambient = rgb(40, 40, 44), OutdoorAmbient = rgb(140, 148, 165),
        Top = rgb(255, 226, 190), Bottom = rgb(190, 190, 205),
        Bloom = 0.10, BloomSize = 22, BloomThreshold = 1.15,
        SunRays = 0.12, SunRaySpread = 0.85,
        Contrast = 0.09, Saturation = 0.04, Tint = rgb(252, 250, 248),
        ShaftColor = rgb(255, 225, 180),
        Shafts = 0.45, SunGlow = 0.6, Flare = 0.30, Sheen = 0.05,
    },
    {
        -- SORE KEEMASAN: gelap, oranye dominan, kuning halus, sedikit hitam,
        -- cahaya & bayangan lebih mencolok
        Name = "Sore Keemasan",
        ClockTime = 17.3, Brightness = 2.35, Exposure = -0.22, ShadowSoftness = 0.04,
        Density = 0.37, Offset = 0.10, Haze = 1.9, Glare = 1.0,
        Color = rgb(255, 148, 78), Decay = rgb(226, 92, 38),
        Ambient = rgb(30, 18, 12), OutdoorAmbient = rgb(84, 56, 40),
        Top = rgb(255, 138, 58), Bottom = rgb(112, 70, 50),
        Bloom = 0.34, BloomSize = 24, BloomThreshold = 0.9,
        SunRays = 0.46, SunRaySpread = 0.9,
        Contrast = 0.27, Saturation = 0.14, Tint = rgb(255, 204, 158),
        ShaftColor = rgb(255, 160, 80),
        Shafts = 1.0, SunGlow = 1.0, Flare = 1.0, Sheen = 0.13,
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
        -- KABUT: lebih tebal dan sedikit lebih gelap
        Fx = true,
        Name = "Kabut Halus",
        ClockTime = 9.5, Brightness = 1.55, Exposure = -0.12, ShadowSoftness = 0.30,
        Density = 0.54, Offset = 0.0, Haze = 2.4, Glare = 0.1,
        Color = rgb(176, 186, 198), Decay = rgb(116, 126, 144),
        Ambient = rgb(30, 33, 38), OutdoorAmbient = rgb(82, 90, 102),
        Top = rgb(200, 202, 202), Bottom = rgb(130, 136, 146),
        Bloom = 0.05, BloomSize = 22, BloomThreshold = 1.2,
        Contrast = 0.10, Saturation = -0.04, Tint = rgb(222, 228, 236),
        Overlay = 0.35, OverlayTop = rgb(30, 34, 40), OverlayBottom = rgb(120, 128, 140),
        CloudColor = rgb(160, 166, 176), CloudCover = 0.7, CloudDensity = 0.6,
        EggGlow = 0.3,
    },
    {
        Fx = true,
        Name = "Berkabut",
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
        CloudColor = rgb(200, 204, 212), CloudCover = 0.75, CloudDensity = 0.65,
        EggGlow = 0.3,
    },
    {
        Name = "Sedikit Gelap",
        ClockTime = 19.2, Brightness = 1.20, Exposure = -0.15, ShadowSoftness = 0.25,
        Density = 0.30, Offset = 0.10, Haze = 1.0, Glare = 0.0,
        Color = rgb(150, 160, 185), Decay = rgb(80, 90, 120),
        Ambient = rgb(24, 26, 34), OutdoorAmbient = rgb(70, 76, 96),
        Top = rgb(150, 160, 190), Bottom = rgb(70, 72, 92),
        Bloom = 0.05, BloomSize = 20, BloomThreshold = 1.1,
        Contrast = 0.14, Saturation = -0.02, Tint = rgb(225, 230, 245),
        EggGlow = 0.6,
    },
    {
        Fx = true,
        Name = "Hujan",
        ClockTime = 14.5, Brightness = 1.35, Exposure = -0.10, ShadowSoftness = 0.35,
        Density = 0.45, Offset = 0.02, Haze = 2.0, Glare = 0.0,
        Color = rgb(160, 166, 174), Decay = rgb(120, 127, 138),
        Ambient = rgb(40, 42, 46), OutdoorAmbient = rgb(88, 94, 102),
        Top = rgb(180, 184, 190), Bottom = rgb(115, 119, 126),
        Bloom = 0.05, BloomSize = 20, BloomThreshold = 1.2,
        Contrast = 0.12, Saturation = -0.03, Tint = rgb(225, 228, 233),
        Rain = true, Wet = true, Sheen = 0.12,
        CloudColor = rgb(120, 128, 140), CloudCover = 0.9, CloudDensity = 0.8,
        EggGlow = 0.4,
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
        SunRays = 0.06,
        Contrast = 0.09, Saturation = 0.08, Tint = rgb(244, 255, 245),
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
        Contrast = 0.16, Saturation = 0.10, Tint = rgb(255, 235, 220),
        EggGlow = 0.5,
    },
    {
        Name = "Malam Bulan",
        ClockTime = 0.35, Brightness = 1.30, Exposure = -0.05, ShadowSoftness = 0.22,
        Density = 0.25, Offset = 0.22, Haze = 0.5, Glare = 0.0,
        Color = rgb(140, 170, 220), Decay = rgb(76, 92, 135),
        Ambient = rgb(14, 18, 30), OutdoorAmbient = rgb(54, 65, 92),
        Top = rgb(150, 175, 230), Bottom = rgb(80, 90, 125),
        Bloom = 0.06, BloomSize = 20, BloomThreshold = 1.1,
        Contrast = 0.16, Saturation = 0.025, Tint = rgb(210, 225, 255),
        EggGlow = 1.0,
    },
    {
        Name = "Malam Gelap",
        ClockTime = 2.1, Brightness = 0.92, Exposure = -0.08, ShadowSoftness = 0.25,
        Density = 0.20, Offset = 0.26, Haze = 0.3, Glare = 0.0,
        Color = rgb(75, 100, 160), Decay = rgb(35, 46, 82),
        Ambient = rgb(7, 9, 18), OutdoorAmbient = rgb(27, 33, 57),
        Top = rgb(110, 130, 190), Bottom = rgb(42, 45, 68),
        Bloom = 0.05, BloomSize = 20, BloomThreshold = 1.0,
        Contrast = 0.18, Saturation = 0.01, Tint = rgb(190, 210, 255),
        EggGlow = 1.0,
    },
    {
        Name = "Malam Kota Neon",
        ClockTime = 22.1, Brightness = 1.15, Exposure = -0.025, ShadowSoftness = 0.22,
        Density = 0.28, Offset = 0.20, Haze = 0.6, Glare = 0.0,
        Color = rgb(110, 165, 220), Decay = rgb(70, 75, 150),
        Ambient = rgb(12, 17, 28), OutdoorAmbient = rgb(42, 54, 84),
        Top = rgb(120, 150, 210), Bottom = rgb(62, 65, 112),
        Bloom = 0.15, BloomSize = 24, BloomThreshold = 0.95,
        Contrast = 0.18, Saturation = 0.09, Tint = rgb(225, 235, 255),
        EggGlow = 1.0,
    },
}

local MoodByName = {}
for _, mood in ipairs(Moods) do
    setmetatable(mood, { __index = DEFAULT })
    MoodByName[mood.Name] = mood
end

-- Menggabungkan beberapa suasana jadi satu (rata-rata halus).
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
    if #list == 1 then
        return list[1]
    end

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
        for _, m in ipairs(list) do
            sum += m[key]
        end
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
        if m.CloudColor then
            table.insert(clouds, m)
        end
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
    if MoodByName[name] then
        table.insert(State.Selected, name)
    end
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
-- MATAHARI DIAM (dipakai World & Lensa)
----------------------------------------------------------------

local Sun = {
    Anchor = nil,
    Dir = Vector3.new(0, 1, 0),
    Pos = Vector3.zero,
    Dist = 1,
    Look = 0,
    Facing = 0,
    Scale = 1,
    Elev = 0,
    Open = 0,
    Timer = 0,
    OpenTarget = 0,
}

local sunRay = RaycastParams.new()
sunRay.FilterType = Enum.RaycastFilterType.Exclude
sunRay.RespectCanCollide = false

local function updateSunRay()
    local list = { WorldFolder }
    if Player.Character then
        table.insert(list, Player.Character)
    end
    sunRay.FilterDescendantsInstances = list
end

local function updateSun(dt)
    local cam = Workspace.CurrentCamera
    if not cam then
        return
    end

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

    -- Apakah matahari terhalang bangunan/pohon (dicek berkala)
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

    if existing and existing:IsA(className) then
        return existing
    end
    if existing then
        existing:Destroy()
    end

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

    safe(function()
        Lighting.LightingStyle = Enum.LightingStyle.Realistic
    end)

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
-- SKY: sembunyikan piringan matahari bawaan
-- (matahari kita sendiri digambar diam di satu titik dunia)
----------------------------------------------------------------

local SkyState = { Object = nil, Owned = false, Saved = nil }

local function restoreSky()
    if SkyState.Object then
        if SkyState.Owned then
            if SkyState.Object.Parent then
                SkyState.Object:Destroy()
            end
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
-- OVERLAY ATMOSFER (oranye halus + sedikit hitam di tepi)
----------------------------------------------------------------

local Atmos = {}

do
    local gui, tint, tintGradient
    local edges = {}

    local function build()
        if gui then
            return
        end

        gui = Instance.new("ScreenGui")
        gui.Name = ROOT .. "_Atmos"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = -2
        gui.Parent = PlayerGui

        tint = Instance.new("Frame")
        tint.BorderSizePixel = 0
        tint.Size = UDim2.fromScale(1, 1)
        tint.BackgroundColor3 = Color3.new(1, 1, 1)
        tint.BackgroundTransparency = 1
        tint.Parent = gui

        tintGradient = Instance.new("UIGradient")
        tintGradient.Rotation = 90
        tintGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.05),
            NumberSequenceKeypoint.new(0.55, 0.78),
            NumberSequenceKeypoint.new(1, 0.45),
        })
        tintGradient.Parent = tint

        local defs = {
            { UDim2.fromScale(0, 0), Vector2.new(0, 0), UDim2.fromScale(1, 0.30), 90, 0, 1 },
            { UDim2.fromScale(0, 1), Vector2.new(0, 1), UDim2.fromScale(1, 0.34), 90, 1, 0 },
            { UDim2.fromScale(0, 0), Vector2.new(0, 0), UDim2.fromScale(0.20, 1), 0, 0, 1 },
            { UDim2.fromScale(1, 0), Vector2.new(1, 0), UDim2.fromScale(0.20, 1), 0, 1, 0 },
        }
        for _, d in ipairs(defs) do
            local f = Instance.new("Frame")
            f.BorderSizePixel = 0
            f.Position = d[1]
            f.AnchorPoint = d[2]
            f.Size = d[3]
            f.BackgroundColor3 = rgb(8, 3, 1)
            f.BackgroundTransparency = 1
            f.Parent = gui

            local g = Instance.new("UIGradient")
            g.Rotation = d[4]
            g.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, d[5]),
                NumberSequenceKeypoint.new(1, d[6]),
            })
            g.Parent = f
            table.insert(edges, f)
        end
    end

    function Atmos.Set(mood)
        build()
        local s = clamp01(mood.Overlay)

        gui.Enabled = s > 0.01
        tint.BackgroundTransparency = 1 - 0.62 * s
        tintGradient.Color = ColorSequence.new(mood.OverlayTop, mood.OverlayBottom)

        for _, f in ipairs(edges) do
            f.BackgroundTransparency = 1 - 0.5 * s
        end
    end

    function Atmos.Destroy()
        if gui then
            gui:Destroy()
            gui = nil
        end
        table.clear(edges)
    end
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
    if not part:IsA("BasePart") or part:IsA("Terrain") then
        return false
    end
    if part.Transparency >= 0.98 then
        return false
    end
    if part:IsDescendantOf(WorldFolder) then
        return false
    end

    local name = string.lower(part.Name)
    for _, token in ipairs(BLOCKED_NAMES) do
        if name:find(token, 1, true) then
            return false
        end
    end

    local model = part:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChildOfClass("Humanoid") then
        return false
    end

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
        info.Type = "EMISSIVE"
        info.Factor = 0
        return info
    end

    if material == Enum.Material.Metal then
        info.Type, info.Base, info.Factor = "METAL", 0.14, 1.2
    elseif material == Enum.Material.Glass then
        info.Type, info.Base, info.Factor = "GLASS", 0.08, 1.0
    elseif name:find("gold") or name:find("coin") or name:find("treasure")
        or name:find("bronze") or name:find("brass") then
        info.Type, info.Base, info.Factor = "GOLD", 0.16, 1.2
    elseif name:find("steel") or name:find("iron") or name:find("blade")
        or name:find("machine") or name:find("metal") then
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
-- CAHAYA TELUR (malam)
-- Dicari otomatis sesuai struktur workspace di file:
--   Workspace.World.Areas.GuardAreas.<Area>.Nests.NestModel.EggSpotBottom
--   Workspace.World.Areas.GuardAreas.<Area>.Guard.EggPoint
--   Workspace.PlacedEggRenders.<telur pemain>
-- (12 area x 5 nest = 60 tempat telur + titik telur guard)
----------------------------------------------------------------

local Eggs = {
    Records = {},
    Keys = setmetatable({}, weakKeys),
    Timer = 0,
}

local eggRng = Random.new(77)

local GLOW_LAYERS = {
    { size = 1.00, alpha = 0.10 },
    { size = 0.62, alpha = 0.16 },
    { size = 0.30, alpha = 0.26 },
}

local function eggTarget(part)
    local name = part.Name

    if name == "EggSpotBottom" or name == "EggPoint" then
        return part, part, "spot"
    end

    local placed = Workspace:FindFirstChild("PlacedEggRenders")
    if placed and part:IsDescendantOf(placed) then
        local top = part
        while top.Parent and top.Parent ~= placed do
            top = top.Parent
        end
        return top, part, "placed"
    end

    return nil
end

local function registerEgg(part)
    local key, lightPart, kind = eggTarget(part)
    if not key or Eggs.Keys[key] then
        return
    end
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
        Part = lightPart,
        Attachment = attachment,
        Light = light,
        Frames = {},
        Phase = eggRng:NextNumber() * math.pi * 2,
        Level = 0,
        Wanted = false,
        Dist = math.huge,
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
    if record.Light then
        record.Light:Destroy()
    end
    if record.Glow then
        record.Glow:Destroy()
    end
    if record.Attachment then
        record.Attachment:Destroy()
    end
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
        table.sort(sorted, function(a, b)
            return a.Dist < b.Dist
        end)

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
            if record.Glow then
                record.Glow.Enabled = false
            end
        end
    end
end

----------------------------------------------------------------
-- PROSES PART (material + pantulan + becek)
----------------------------------------------------------------

local function processPart(part)
    if PartInfo[part] then
        return PartInfo[part]
    end
    if not isVisualPart(part) then
        return nil
    end

    rememberPart(part)
    local info = classifyPart(part)

    if info.Type == "DEFAULT" and not info.Ground and part.Material == Enum.Material.Plastic then
        local variant = getProperty(part, "MaterialVariant", "")
        if not variant or variant == "" then
            setProperty(part, "Material", Enum.Material.SmoothPlastic)
        end
    end

    setProperty(part, "CastShadow", true)

    if info.SA then
        rememberSurfaceAppearance(info.SA)
    end

    PartInfo[part] = info
    table.insert(PartList, part)

    State.Stats.Parts += 1
    if info.Ground then
        State.Stats.Ground += 1
    end

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

    if not info or not original or not part.Parent then
        return
    end

    local sheen = mood.Sheen * State.Scale
    local wet = mood.Wet == true and info.Ground

    local add = 0
    if info.Type ~= "EMISSIVE" then
        add = info.Base + sheen * info.Factor
    end
    if wet then
        add = math.max(add, 0.5)
    end

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
        if part.Color ~= wanted then
            setProperty(part, "Color", wanted)
        end
    end

    if info.SA and info.SA.Parent then
        local saOriginal = Original.SurfaceAppearances[info.SA]
        if saOriginal and saOriginal.Color then
            local wanted = wet and wetColor(saOriginal.Color) or saOriginal.Color
            if info.SA.Color ~= wanted then
                setProperty(info.SA, "Color", wanted)
            end
        end
    end
end

local styleJob = 0

local function styleParts(mood)
    styleJob += 1
    local myJob = styleJob

    local count = 0
    for i = #PartList, 1, -1 do
        if not PartList[i].Parent then
            table.remove(PartList, i)
        end
    end

    for _, part in ipairs(PartList) do
        if myJob ~= styleJob or State.Restored then
            return
        end
        stylePart(part, mood)

        count += 1
        if count % 300 == 0 then
            task.wait()
        end
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
            Original.TerrainColors[material] = safe(function()
                return Terrain:GetMaterialColor(material)
            end, false)
        end

        local original = Original.TerrainColors[material]
        if original then
            local wanted = on and wetColor(original) or original
            safe(function()
                Terrain:SetMaterialColor(material, wanted)
            end)
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

        if i % 500 == 0 then
            task.wait()
        end
    end

    ScanDone = true
end

----------------------------------------------------------------
-- LAMPU AKSEN (lampu, obor, neon, dll)
----------------------------------------------------------------

local LIGHT_TOKENS = {
    "lamp", "light", "lantern", "torch", "fire", "flame", "bulb", "neon",
    "screen", "monitor", "sign", "crystal", "portal", "glow", "energy", "lava",
}

local function isLightSourcePart(part)
    local name = string.lower(part.Name)
    for _, token in ipairs(LIGHT_TOKENS) do
        if name:find(token, 1, true) then
            return true
        end
    end
    return part.Material == Enum.Material.Neon
end

local function getLightColor(part)
    if part.Material == Enum.Material.Neon then
        return part.Color
    end

    local name = string.lower(part.Name)
    if name:find("fire") or name:find("flame") or name:find("torch") or name:find("lava") then
        return rgb(255, 170, 90)
    end
    if name:find("crystal") or name:find("ice") then
        return rgb(150, 210, 255)
    end
    return part.Color
end

local function clearAccentLights()
    for _, record in ipairs(State.AccentLights) do
        if record.Light and record.Light.Parent then
            record.Light:Destroy()
        end
        if record.Attachment and record.Attachment.Parent then
            record.Attachment:Destroy()
        end
    end
    table.clear(State.AccentLights)
end

local function scanAccentLights()
    clearAccentLights()

    local cam = Workspace.CurrentCamera
    if not cam then
        return
    end

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

    table.sort(candidates, function(a, b)
        return a.Dist < b.Dist
    end)

    local maxLights = math.floor(Settings.MaxAccentLights * State.Scale)

    for _, candidate in ipairs(candidates) do
        if #State.AccentLights >= maxLights then
            break
        end

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
-- DUNIA 3D: sun rays, glow matahari, hujan, genangan kaca
----------------------------------------------------------------

local World = {}

do
    local MAX_SHAFTS = 36
    local MAX_PUDDLES = 70
    local RAIN_TEXTURE = ""         -- opsional: asset id tekstur garis hujan
    local RAIN_SOUND_ID = ""        -- opsional: asset id suara hujan
    local RAIN_SOUND_VOLUME = 0.5

    local rng = Random.new(1987)

    local anchor, sunPart, sunGui, sunStreak
    local sunLayers = {}
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
        if Player.Character then
            table.insert(list, Player.Character)
        end
        rayParams.FilterDescendantsInstances = list

        updateSunRay()
    end

    World.UpdateRayParams = updateRayParams

    local SUN_LAYERS = {
        { size = 0.86, alpha = 0.960, color = rgb(255, 128, 52) },
        { size = 0.54, alpha = 0.920, color = rgb(255, 156, 62) },
        { size = 0.31, alpha = 0.850, color = rgb(255, 190, 92) },
        { size = 0.15, alpha = 0.680, color = rgb(255, 222, 128) },
        { size = 0.065, alpha = 0.320, color = rgb(255, 245, 200) },
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
        if built then
            return
        end
        built = true

        updateRayParams()

        anchor = makeInvisiblePart(PREFIX .. "Anchor")
        anchor.CFrame = CFrame.new(0, 0, 0)

        -- Glow matahari 3D: diam di satu titik dunia (ukuran dalam stud,
        -- jadi otomatis mengecil saat kamu menjauh)
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

        -- Sun rays 3D (Beam)
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

        -- Hujan
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

    ------------------------------------------------------------
    -- Awan
    ------------------------------------------------------------

    local function applyClouds(m)
        if m and m.CloudColor ~= nil then
            if not cloudsState then
                local existing = Terrain:FindFirstChildOfClass("Clouds")
                if existing then
                    cloudsState = {
                        Object = existing,
                        Owned = false,
                        Saved = {
                            Color = existing.Color, Cover = existing.Cover,
                            Density = existing.Density, Enabled = existing.Enabled,
                        },
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
                if cloudsState.Object.Parent then
                    cloudsState.Object:Destroy()
                end
            else
                for property, value in pairs(cloudsState.Saved) do
                    setProperty(cloudsState.Object, property, value)
                end
            end
            cloudsState = nil
        end
    end

    ------------------------------------------------------------
    -- Sun rays 3D: penempatan
    ------------------------------------------------------------

    local function seedShafts(camPos)
        local sunDir = Sun.Dir
        local count = math.floor(MAX_SHAFTS * State.Scale)
        local color = mood.ShaftColor

        local flat = Vector3.new(sunDir.X, 0, sunDir.Z)
        local azimuth = rng:NextNumber(0, math.pi * 2)
        if flat.Magnitude > 0.01 then
            azimuth = math.atan2(flat.Z, flat.X)
        end

        local maxLen = 140

        for index, shaft in ipairs(shafts) do
            shaft.Active = false

            if index <= count then
                local angle
                if rng:NextNumber() < 0.7 then
                    angle = azimuth + rng:NextNumber(-1.2, 1.2)
                else
                    angle = rng:NextNumber(0, math.pi * 2)
                end

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

    ------------------------------------------------------------
    -- Genangan: lapisan kaca bening, bentuk tidak bulat
    -- (3 pecahan persegi panjang tipis yang diputar & ditumpuk,
    -- bagian tengah terlihat lebih "dalam")
    ------------------------------------------------------------

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
            for _, block in ipairs(puddle) do
                block.Transparency = t
            end
        end
    end

    local function hidePuddle(puddle)
        for _, block in ipairs(puddle) do
            block.Parent = nil
        end
    end

    local function placePuddles(center)
        local count = math.floor(MAX_PUDDLES * State.Scale)

        local below = Workspace:Raycast(center, Vector3.new(0, -300, 0), rayParams)
        local refY = below and below.Position.Y or (center.Y - 3)

        for index = 1, MAX_PUDDLES do
            local puddle = puddles[index]

            if index > count then
                if puddle then
                    hidePuddle(puddle)
                end
            else
                if not puddle then
                    puddle = { newGlassBlock(), newGlassBlock(), newGlassBlock() }
                    puddles[index] = puddle
                end

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

                    -- tidak ada genangan di bawah atap
                    if valid and Workspace:Raycast(hit.Position + Vector3.new(0, 1, 0), Vector3.new(0, 40, 0), rayParams) then
                        valid = false
                    end
                end

                if valid then
                    local pos = hit.Position
                    local yaw = rng:NextNumber(0, math.pi)
                    local w = rng:NextNumber(4, 11)
                    local l = w * rng:NextNumber(0.55, 0.9)

                    -- lapisan dasar (paling besar)
                    puddle[1].Size = Vector3.new(w, 0.04, l)
                    puddle[1].CFrame = CFrame.new(pos + Vector3.new(0, 0.04, 0)) * CFrame.Angles(0, yaw, 0)

                    -- pecahan kedua: lebih panjang, diputar dan digeser
                    local s2 = Vector3.new(rng:NextNumber(-0.22, 0.22) * w, 0.052, rng:NextNumber(-0.22, 0.22) * l)
                    puddle[2].Size = Vector3.new(w * 0.62, 0.04, l * 1.3)
                    puddle[2].CFrame = CFrame.new(pos + s2) * CFrame.Angles(0, yaw + rng:NextNumber(0.5, 1.1), 0)

                    -- pecahan ketiga: kecil, di dekat tengah
                    local s3 = Vector3.new(rng:NextNumber(-0.3, 0.3) * w, 0.064, rng:NextNumber(-0.3, 0.3) * l)
                    puddle[3].Size = Vector3.new(w * 0.4, 0.04, l * 0.55)
                    puddle[3].CFrame = CFrame.new(pos + s3) * CFrame.Angles(0, yaw - rng:NextNumber(0.4, 1.0), 0)

                    for _, block in ipairs(puddle) do
                        block.Parent = WorldFolder
                    end
                else
                    hidePuddle(puddle)
                end
            end
        end

        lastPuddlePos = center
    end

    ------------------------------------------------------------
    -- Cahaya hangat di tubuh karakter (sore)
    ------------------------------------------------------------

    local function updateBody(dt)
        local char = Player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then
            return
        end

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

    ------------------------------------------------------------
    -- API
    ------------------------------------------------------------

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
        if not built or not mood then
            return
        end

        local cam = Workspace.CurrentCamera
        if not cam then
            return
        end

        local scale = State.Scale
        local sunDir = Sun.Dir
        local camPos = cam.CFrame.Position

        local facing = Sun.Facing
        local f2 = facing * facing
        local f3 = f2 * facing
        local distFade = clamp01(Sun.Scale)

        local sunSensitive = mood.SunGlow > 0 and 1 or 0

        ------------------------------------------------------------
        -- Glow matahari 3D (diam di tempatnya)
        ------------------------------------------------------------
        local glow = mood.SunGlow * Sun.Elev
        sunGui.Enabled = glow > 0.01

        if sunGui.Enabled then
            sunPart.CFrame = CFrame.new(Sun.Pos)

            local a = clamp01(glow * (0.6 + 0.4 * facing))
            for _, layer in ipairs(sunLayers) do
                layer.Frame.BackgroundTransparency = 1 - (1 - layer.Alpha) * a
            end

            sunStreak.BackgroundTransparency = 1 - 0.75 * a * (0.3 + 0.7 * facing)
        end

        ------------------------------------------------------------
        -- Efek kamera naik saat menghadap matahari (mengecil saat jauh)
        ------------------------------------------------------------
        local sens = Sun.Elev * Sun.Open * sunSensitive * distFade

        local bloom = State.Instances.Bloom
        if bloom and bloom.Parent then
            bloom.Intensity = State.Base.Bloom + 0.45 * f3 * sens
        end

        local rays = State.Instances.SunRays
        if rays and rays.Parent then
            rays.Intensity = State.Base.SunRays + 0.10 * f2 * sens
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

        ------------------------------------------------------------
        -- Sun rays 3D
        ------------------------------------------------------------
        timers.Shaft += dt
        if timers.Shaft >= 0.15 then
            timers.Shaft = 0

            local strength = mood.Shafts * scale * Sun.Elev * (0.45 + 0.55 * distFade)

            if strength <= 0.01 then
                lastSeedPos = nil
            elseif not lastSeedPos
                or (camPos - lastSeedPos).Magnitude > 45
                or not lastSeedSun
                or lastSeedSun:Dot(sunDir) < 0.9997 then
                seedShafts(camPos)
            end

            for _, shaft in ipairs(shafts) do
                if shaft.Active and strength > 0.01 then
                    local distance = (shaft.Pos - camPos).Magnitude
                    local near = clamp01((distance - 10) / 25)
                    local amount = strength * (0.30 + 0.70 * facing) * shaft.Rand * 0.19 * near
                    local t = 1 - clamp01(amount)

                    shaft.Beam.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(0.15, t),
                        NumberSequenceKeypoint.new(0.6, math.min(1, t + (1 - t) * 0.5)),
                        NumberSequenceKeypoint.new(1, 1),
                    })
                    shaft.Beam.Enabled = true
                else
                    shaft.Beam.Enabled = false
                end
            end
        end

        ------------------------------------------------------------
        -- Hujan + genangan kaca
        ------------------------------------------------------------
        local rainTarget = mood.Rain and 1 or 0
        rainLevel = lerp(rainLevel, rainTarget, math.min(1, dt * 0.4))

        timers.Rain += dt
        if timers.Rain >= 0.2 then
            timers.Rain = 0

            local covered = Workspace:Raycast(camPos, Vector3.new(0, 90, 0), rayParams) ~= nil
            coverTarget = covered and 0.08 or 1

            if rainLevel > 0.03 then
                if not lastPuddlePos or (camPos - lastPuddlePos).Magnitude > 50 then
                    placePuddles(camPos)
                end
                -- makin hujan makin bening-pantul (transparansi turun ke ~0.45)
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

        if mood.WarmBody then
            updateBody(dt)
        end
    end

    function World.Destroy()
        applyClouds(nil)

        if rainSound then
            rainSound:Destroy()
            rainSound = nil
        end

        for _, puddle in ipairs(puddles) do
            for _, block in ipairs(puddle) do
                block:Destroy()
            end
        end
        table.clear(puddles)
        table.clear(shafts)
        table.clear(sunLayers)

        WorldFolder:ClearAllChildren()

        bodyAttachment = nil
        bodyLight = nil
        built = false
        mood = nil
    end
end

----------------------------------------------------------------
-- LENSA MATAHARI
-- Matahari diam di satu titik dunia, jadi semua elemen lensa
-- (inti, sinar, ghost, bokeh) mengecil dan memudar saat menjauh.
----------------------------------------------------------------

local SunLens = {}

do
    local LENS_INTENSITY = 1.0
    local TILT = -22

    local gui, blur
    local rig, beam
    local ghostL, ghostR
    local occluder, occGradient, rimGlow
    local layers, spots = {}, {}
    local level = 0
    local built = false
    local sideCache = 0

    local function steps(n)
        return math.max(4, math.floor(n * (0.55 + 0.45 * State.Scale) + 0.5))
    end

    local function register(object, property, opacity, gate)
        object[property] = 1
        table.insert(layers, { Obj = object, Prop = property, Op = opacity, Gate = gate or 0, Last = -1 })
    end

    local function newFrame(parent, color)
        local f = Instance.new("Frame")
        f.BorderSizePixel = 0
        f.Active = false
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.Position = UDim2.fromScale(0.5, 0.5)
        f.BackgroundColor3 = color or Color3.new(1, 1, 1)
        f.BackgroundTransparency = 1
        f.Parent = parent
        return f
    end

    local function round(frame, scale)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(scale or 1, 0)
        c.Parent = frame
    end

    local function seq(...)
        local points = {}
        for _, p in ipairs({ ... }) do
            table.insert(points, NumberSequenceKeypoint.new(p[1], p[2]))
        end
        return NumberSequence.new(points)
    end

    local function gradient(frame, rotation, colors, transparency)
        local g = Instance.new("UIGradient")
        g.Rotation = rotation
        if colors then
            g.Color = colors
        end
        if transparency then
            g.Transparency = transparency
        end
        g.Parent = frame
        return g
    end

    local function softStack(parent, cx, cy, w, h, rot, outer, inner, count, total, gate, radius, power)
        count = steps(count)
        local per = 1 - (1 - total) ^ (1 / count)

        for i = 0, count - 1 do
            local k = count > 1 and i / (count - 1) or 0
            local scale = (1 - i / count) ^ (power or 1.5)

            local f = newFrame(parent, outer:Lerp(inner, k))
            f.Position = UDim2.fromScale(cx, cy)
            f.Size = UDim2.fromScale(w * scale, h * scale)
            f.Rotation = rot
            round(f, radius)
            register(f, "BackgroundTransparency", per, gate)
        end
    end

    local function column(parent, w, len, outer, inner, count, total, gate)
        count = steps(count)
        local per = 1 - (1 - total) ^ (1 / count)

        for i = 0, count - 1 do
            local k = count > 1 and i / (count - 1) or 0
            local scale = (1 - i / count) ^ 1.25

            local f = newFrame(parent, outer:Lerp(inner, k))
            f.Size = UDim2.fromScale(w * scale, len * (0.55 + 0.45 * scale))
            round(f, 1)
            gradient(f, 90, nil, seq({ 0, 1 }, { 0.26, 0.55 }, { 0.5, 0 }, { 0.74, 0.55 }, { 1, 1 }))
            register(f, "BackgroundTransparency", per, gate)
        end
    end

    local function addSpot(def)
        local f = newFrame(gui, def.Color)
        round(f, 1)
        register(f, "BackgroundTransparency", def.Op, def.Gate)

        if def.Rim then
            local stroke = Instance.new("UIStroke")
            stroke.Color = def.Rim
            stroke.Thickness = 2
            stroke.Parent = f
            register(stroke, "Transparency", def.RimOp or 0.6, def.Gate)
        end

        def.F = f
        def.Seed = #spots * 1.37 + 0.5
        table.insert(spots, def)
    end

    local function build()
        if built then
            return
        end
        built = true

        gui = Instance.new("ScreenGui")
        gui.Name = ROOT .. "_Lensa"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = -1
        gui.Enabled = false
        gui.Parent = PlayerGui

        -- 1. Selimut hangat
        local wash = newFrame(gui)
        wash.AnchorPoint = Vector2.new(0, 0)
        wash.Position = UDim2.fromScale(0, 0)
        wash.Size = UDim2.fromScale(1, 1)
        gradient(wash, 90, ColorSequence.new(rgb(255, 180, 80), rgb(180, 70, 14)), seq({ 0, 0.1 }, { 1, 0 }))
        register(wash, "BackgroundTransparency", 0.58, 0)

        local sky = newFrame(gui, rgb(255, 236, 165))
        sky.AnchorPoint = Vector2.new(0, 0)
        sky.Position = UDim2.fromScale(0, 0)
        sky.Size = UDim2.fromScale(1, 0.6)
        gradient(sky, 90, nil, seq({ 0, 0.2 }, { 1, 1 }))
        register(sky, "BackgroundTransparency", 0.75, 0.25)

        -- 2. Ghost kiri & kanan
        ghostL = newFrame(gui)
        ghostL.Rotation = 18
        softStack(ghostL, 0.5, 0.5, 1, 1, 0, rgb(150, 45, 10), rgb(225, 85, 20), 9, 0.62, 0.25, 0.5, 1.2)

        local fringeL = newFrame(ghostL)
        fringeL.Size = UDim2.fromScale(0.98, 0.98)
        round(fringeL, 0.5)
        local strokeL = Instance.new("UIStroke")
        strokeL.Color = rgb(170, 165, 40)
        strokeL.Thickness = 3
        strokeL.Parent = fringeL
        register(strokeL, "Transparency", 0.35, 0.25)

        ghostR = newFrame(gui)
        ghostR.Rotation = -6
        softStack(ghostR, 0.5, 0.5, 1, 1, 0, rgb(150, 35, 8), rgb(215, 60, 12), 9, 0.7, 0.25, 0.3, 1.2)

        local fringeR = newFrame(ghostR)
        fringeR.Size = UDim2.fromScale(0.98, 0.98)
        round(fringeR, 0.3)
        local strokeR = Instance.new("UIStroke")
        strokeR.Color = rgb(150, 160, 40)
        strokeR.Thickness = 3
        strokeR.Parent = fringeR
        register(strokeR, "Transparency", 0.35, 0.25)

        -- 3. Bayangan gelap kemerahan di tepi
        occluder = newFrame(gui)
        occluder.Size = UDim2.fromScale(0.34, 1)

        local body = newFrame(occluder, rgb(50, 13, 3))
        body.AnchorPoint = Vector2.new(0, 0)
        body.Position = UDim2.fromScale(0, 0)
        body.Size = UDim2.fromScale(1, 1)
        occGradient = gradient(body, 0, nil, seq({ 0, 1 }, { 0.22, 0.45 }, { 0.5, 0.12 }, { 1, 0.1 }))
        register(body, "BackgroundTransparency", 0.8, 0.45)

        rimGlow = newFrame(occluder, rgb(255, 105, 20))
        rimGlow.Size = UDim2.fromScale(0.36, 1)
        gradient(rimGlow, 0, nil, seq({ 0, 1 }, { 0.5, 0.2 }, { 1, 1 }))
        register(rimGlow, "BackgroundTransparency", 0.72, 0.45)

        -- 4. Rig matahari
        rig = newFrame(gui)

        softStack(rig, 0.5, 0.5, 2.6, 2.6, 0, rgb(225, 85, 15), rgb(255, 170, 40), 18, 0.78, 0, 1, 1.5)
        softStack(rig, 0.5, 0.5, 1.15, 1.15, 0, rgb(255, 160, 35), rgb(255, 225, 120), 14, 0.85, 0, 1, 1.5)
        softStack(rig, 0.5, 0.5, 1.0, 1.0, 0, rgb(255, 235, 170), rgb(255, 255, 245), 10, 0.55, 0.2, 1, 1.5)

        local rs = Random.new(41)
        for i = 1, 28 do
            local wide = i <= 10

            local f = newFrame(rig, wide and rgb(255, 190, 70) or rgb(255, 235, 160))
            f.Size = UDim2.fromScale(
                wide and rs:NextNumber(1.0, 1.8) or rs:NextNumber(0.5, 1.5),
                wide and 0.022 or 0.004
            )
            f.Rotation = wide and (i - 1) * 18 or (i * 37) % 180
            round(f, 1)
            gradient(f, 0, nil, seq({ 0, 1 }, { 0.35, 0.7 }, { 0.5, 0.15 }, { 0.65, 0.7 }, { 1, 1 }))
            register(f, "BackgroundTransparency", wide and 0.18 or 0.5, 0.1)
        end

        beam = newFrame(rig)
        beam.Size = UDim2.fromScale(1, 1)

        column(beam, 0.40, 2.8, rgb(255, 125, 15), rgb(255, 215, 80), 12, 0.9, 0.05)
        column(beam, 0.14, 2.2, rgb(255, 200, 60), rgb(255, 245, 190), 8, 0.85, 0.05)
        column(beam, 0.012, 2.5, rgb(255, 250, 230), rgb(255, 255, 250), 4, 0.7, 0.1)

        softStack(beam, 0.5, 0.5, 0.20, 0.52, 0, rgb(255, 215, 90), rgb(255, 255, 248), 9, 0.99, 0, 1, 1.2)

        local bits = {
            { -0.045, -0.12, 0.035 }, { 0.020, 0.02, 0.050 }, { 0.050, -0.20, 0.030 },
            { -0.050, 0.08, 0.040 }, { 0.030, 0.18, 0.040 }, { 0.060, 0.10, 0.030 },
            { -0.030, -0.22, 0.025 },
        }
        for _, b in ipairs(bits) do
            local f = newFrame(beam, rgb(255, 252, 235))
            f.Position = UDim2.fromScale(0.5 + b[1], 0.5 + b[2])
            f.Size = UDim2.fromScale(b[3], b[3] * 1.4)
            round(f, 1)
            register(f, "BackgroundTransparency", 0.55, 0)
        end

        -- 5. Ghost kecil + bokeh
        local axisSpots = {
            { D = 0.19, Off = 0.000, Size = 0.065, Color = rgb(255, 214, 70), Op = 0.62, Rim = rgb(255, 242, 160), RimOp = 0.85, Gate = 0.2 },
            { D = 0.24, Off = 0.015, Size = 0.018, Color = rgb(200, 140, 210), Op = 0.45, Gate = 0.25 },
            { D = 0.37, Off = -0.005, Size = 0.050, Color = rgb(255, 150, 30), Op = 0.50, Gate = 0.25 },
            { D = 0.53, Off = 0.030, Size = 0.060, Color = rgb(235, 60, 20), Op = 0.60, Gate = 0.3 },
            { D = 0.30, Off = -0.12, Size = 0.060, Asp = 2.0, Rot = 12, Color = rgb(255, 190, 50), Op = 0.35, Gate = 0.4 },
            { D = 0.36, Off = -0.02, Size = 0.080, Asp = 1.6, Rot = 10, Color = rgb(255, 185, 40), Op = 0.45, Gate = 0.4 },
            { D = 0.42, Off = 0.06, Size = 0.110, Asp = 1.4, Rot = 8, Color = rgb(255, 200, 60), Op = 0.40, Gate = 0.45 },
            { D = 0.50, Off = -0.10, Size = 0.090, Color = rgb(255, 170, 40), Op = 0.50, Gate = 0.45 },
            { D = 0.55, Off = 0.12, Size = 0.045, Color = rgb(255, 200, 60), Op = 0.50, Gate = 0.45 },
            { D = 0.62, Off = -0.16, Size = 0.070, Color = rgb(240, 50, 20), Op = 0.70, Rim = rgb(255, 110, 60), RimOp = 0.5, Gate = 0.5 },
            { D = 0.60, Off = 0.05, Size = 0.065, Color = rgb(240, 45, 20), Op = 0.70, Rim = rgb(255, 110, 60), RimOp = 0.5, Gate = 0.5 },
            { D = 0.66, Off = -0.04, Size = 0.030, Color = rgb(240, 60, 25), Op = 0.65, Gate = 0.5 },
            { D = 0.74, Off = 0.22, Size = 0.050, Color = rgb(235, 60, 25), Op = 0.60, Gate = 0.5 },
        }
        for _, def in ipairs(axisSpots) do
            def.Mode = "axis"
            addSpot(def)
        end

        local rimSpots = {
            { X = 0.763, Y = 0.280, Size = 0.040 }, { X = 0.757, Y = 0.400, Size = 0.075 },
            { X = 0.705, Y = 0.185, Size = 0.035 }, { X = 0.684, Y = 0.260, Size = 0.030 },
            { X = 0.730, Y = 0.500, Size = 0.035 }, { X = 0.700, Y = 0.080, Size = 0.030 },
            { X = 0.770, Y = 0.170, Size = 0.028 }, { X = 0.660, Y = 0.350, Size = 0.025 },
        }
        for i, def in ipairs(rimSpots) do
            def.Mode = "rim"
            def.Color = i % 3 == 0 and rgb(255, 150, 30) or rgb(255, 190, 45)
            def.Op = 0.55
            def.Rim = rgb(255, 225, 120)
            def.RimOp = 0.35
            def.Gate = 0.5
            addSpot(def)
        end

        -- 6. Vignette gelap
        local vignette = {
            { pos = UDim2.fromScale(0, 0), anchor = Vector2.new(0, 0), size = UDim2.fromScale(1, 0.28), rot = 90, a = 0, b = 1 },
            { pos = UDim2.fromScale(0, 1), anchor = Vector2.new(0, 1), size = UDim2.fromScale(1, 0.34), rot = 90, a = 1, b = 0 },
            { pos = UDim2.fromScale(0, 0), anchor = Vector2.new(0, 0), size = UDim2.fromScale(0.22, 1), rot = 0, a = 0, b = 1 },
            { pos = UDim2.fromScale(1, 0), anchor = Vector2.new(1, 0), size = UDim2.fromScale(0.22, 1), rot = 0, a = 1, b = 0 },
        }
        for _, v in ipairs(vignette) do
            local f = newFrame(gui, rgb(30, 10, 2))
            f.AnchorPoint = v.anchor
            f.Position = v.pos
            f.Size = v.size
            gradient(f, v.rot, nil, seq({ 0, v.a }, { 1, v.b }))
            register(f, "BackgroundTransparency", 0.55, 0.05)
        end

        -- 7. Blur lembut
        blur = Instance.new("BlurEffect")
        blur.Name = PREFIX .. "BlurLensa"
        blur.Size = 0
        blur.Parent = Lighting
        table.insert(Original.Created, blur)
    end

    local function setSide(side)
        sideCache = side

        if side == 1 then
            occluder.AnchorPoint = Vector2.new(1, 0.5)
            occluder.Position = UDim2.fromScale(1, 0.5)
            occGradient.Rotation = 0
            rimGlow.Position = UDim2.fromScale(0, 0.5)
        else
            occluder.AnchorPoint = Vector2.new(0, 0.5)
            occluder.Position = UDim2.fromScale(0, 0.5)
            occGradient.Rotation = 180
            rimGlow.Position = UDim2.fromScale(1, 0.5)
        end
    end

    function SunLens.Update(dt)
        build()

        local mood = State.Mood
        local cam = Workspace.CurrentCamera
        if not mood or not cam then
            return
        end

        local flare = mood.Flare
        local screenPoint = cam:WorldToViewportPoint(Sun.Pos)

        local target = 0
        if flare > 0 and Sun.Elev > 0 and screenPoint.Z > 0 then
            local aim = clamp01((Sun.Look - 0.55) / 0.4)
            aim = aim * aim * (3 - 2 * aim)

            -- makin jauh dari titik matahari, lensa makin pudar
            local distFade = clamp01(Sun.Scale ^ 0.9)

            target = aim * (0.3 + 0.7 * Sun.Open) * Sun.Elev * flare * distFade
        end

        level = lerp(level, target, math.min(1, dt * 5))
        local s = clamp01(level * LENS_INTENSITY * (0.75 + 0.25 * State.Scale))

        if s <= 0.005 then
            gui.Enabled = false
            blur.Size = 0
            return
        end

        gui.Enabled = true
        blur.Size = 5 * s

        local size = cam.ViewportSize
        local W, H = size.X, size.Y
        local center = size / 2
        local sunPos = Vector2.new(screenPoint.X, screenPoint.Y)
        local now = os.clock()

        -- Ukuran seluruh lensa ikut jarak ke titik matahari
        local S = Sun.Scale
        local sizeScale = math.clamp(S, 0.15, 1.2)

        rig.Position = UDim2.fromOffset(sunPos.X, sunPos.Y)
        rig.Size = UDim2.fromOffset(H * sizeScale, H * sizeScale)
        beam.Rotation = TILT + math.sin(now * 0.5) * 1.2

        local shift = (center - sunPos) * 0.45
        local gs = 0.4 + 0.6 * sizeScale
        ghostL.Position = UDim2.fromOffset(center.X + shift.X - W * 0.33, center.Y + shift.Y - H * 0.26)
        ghostL.Size = UDim2.fromOffset(W * 0.36 * gs, H * 0.19 * gs)
        ghostR.Position = UDim2.fromOffset(center.X + shift.X + W * 0.38, center.Y + shift.Y - H * 0.15)
        ghostR.Size = UDim2.fromOffset(W * 0.24 * gs, H * 0.33 * gs)

        local side = sideCache
        if side == 0 then
            side = sunPos.X < W * 0.62 and 1 or -1
        elseif side == 1 and sunPos.X > W * 0.68 then
            side = -1
        elseif side == -1 and sunPos.X < W * 0.56 then
            side = 1
        end
        if side ~= sideCache then
            setSide(side)
        end

        local axis = center - sunPos
        local dir = axis.Magnitude > H * 0.05 and axis.Unit or Vector2.new(-0.5, 0.86).Unit
        local perp = Vector2.new(-dir.Y, dir.X)
        local spread = 0.5 + 0.5 * sizeScale
        local spotScale = 0.35 + 0.65 * sizeScale

        for _, sp in ipairs(spots) do
            local sway = Vector2.new(math.sin(now * 0.55 + sp.Seed), math.cos(now * 0.45 + sp.Seed * 1.3)) * H * 0.006
            local p

            if sp.Mode == "axis" then
                p = sunPos + dir * H * sp.D * spread + perp * H * sp.Off * spread + sway
            else
                local x = side == 1 and sp.X or (1 - sp.X)
                p = Vector2.new(W * x, H * sp.Y) + sway
            end

            local d = H * sp.Size * spotScale
            sp.F.Position = UDim2.fromOffset(p.X, p.Y)
            sp.F.Size = UDim2.fromOffset(d, d * (sp.Asp or 1))
            sp.F.Rotation = sp.Rot or 0
        end

        for _, layer in ipairs(layers) do
            local e = clamp01((s - layer.Gate) / (1 - layer.Gate))
            local t = 1 - layer.Op * e

            if math.abs(t - layer.Last) > 0.004 then
                layer.Last = t
                layer.Obj[layer.Prop] = t
            end
        end
    end

    function SunLens.Destroy()
        if gui then
            gui:Destroy()
            gui = nil
        end
        if blur then
            blur:Destroy()
            blur = nil
        end
        table.clear(layers)
        table.clear(spots)
        built = false
        level = 0
        sideCache = 0
    end
end

----------------------------------------------------------------
-- TERAPKAN SUASANA & KUALITAS
----------------------------------------------------------------

local function activeMoods()
    local list = {}
    for _, name in ipairs(State.Selected) do
        local mood = MoodByName[name]
        if mood then
            table.insert(list, mood)
        end
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
    Atmos.Set(mood)

    World.SetMood(mood)
    setTerrainWet(mood.Wet == true)

    task.spawn(styleParts, mood)
end

local function applyQuality(level)
    level = math.clamp(math.floor(level or 8), 1, 10)

    State.Quality = level
    State.Scale = qualityScale(level)

    SunLens.Destroy()
    applyMoods()
    task.spawn(scanAccentLights)
end

----------------------------------------------------------------
-- API PUBLIK
----------------------------------------------------------------

local API = {}

local onSelectionChanged = function() end

function API.SetQuality(level)
    applyQuality(level)
end

function API.GetQuality()
    return State.Quality
end

-- Satu suasana saja
function API.SetMood(name)
    if not MoodByName[name] then
        return false
    end
    State.Selected = { name }
    applyMoods()
    onSelectionChanged()
    return true
end

-- Beberapa suasana sekaligus, contoh: API.SetMoods({ "Sore Keemasan", "Hujan" })
function API.SetMoods(names)
    local list = {}
    for _, name in ipairs(names) do
        if MoodByName[name] then
            table.insert(list, name)
        end
    end
    if #list == 0 then
        return false
    end
    State.Selected = list
    applyMoods()
    onSelectionChanged()
    return true
end

-- Nyalakan / matikan satu suasana tanpa mengganggu yang lain
function API.ToggleMood(name)
    if not MoodByName[name] then
        return false
    end

    local index = table.find(State.Selected, name)
    if index then
        if #State.Selected > 1 then
            table.remove(State.Selected, index)
        end
    else
        table.insert(State.Selected, name)
    end

    applyMoods()
    onSelectionChanged()
    return true
end

function API.GetMood()
    return selectedLabel()
end

function API.GetActive()
    return table.clone(State.Selected)
end

function API.GetMoods()
    local names = {}
    for _, mood in ipairs(Moods) do
        table.insert(names, mood.Name)
    end
    return names
end

function API.GetStats()
    return State.Stats
end

-- Pindahkan titik matahari (default: tempat kamu mulai)
function API.SetSunAnchor(position)
    Sun.Anchor = position
end

function API.ResetSunAnchor()
    Sun.Anchor = nil
end

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
    if State.Restored then
        return
    end

    State.Restored = true
    styleJob += 1

    for _, connection in ipairs(State.Connections) do
        connection:Disconnect()
    end
    table.clear(State.Connections)

    for property, value in pairs(Original.Lighting) do
        if value ~= nil then
            setProperty(Lighting, property, value)
        end
    end

    for part, data in pairs(Original.Parts) do
        if part and part.Parent then
            for property, value in pairs(data) do
                if value ~= nil then
                    setProperty(part, property, value)
                end
            end
        end
    end

    for surface, data in pairs(Original.SurfaceAppearances) do
        if surface and surface.Parent then
            for property, value in pairs(data) do
                if value ~= nil then
                    setProperty(surface, property, value)
                end
            end
        end
    end

    for material, color in pairs(Original.TerrainColors) do
        if color then
            safe(function()
                Terrain:SetMaterialColor(material, color)
            end)
        end
    end

    clearAccentLights()

    for _, record in ipairs(Eggs.Records) do
        destroyEgg(record)
    end
    table.clear(Eggs.Records)

    restoreSky()
    Atmos.Destroy()
    SunLens.Destroy()
    World.Destroy()

    for _, instance in ipairs(Original.Created) do
        if instance and instance.Parent then
            instance:Destroy()
        end
    end

    for _, atmosphere in ipairs(Original.HiddenAtmospheres) do
        if atmosphere then
            atmosphere.Parent = Lighting
        end
    end

    if State.UI then
        State.UI:Destroy()
        State.UI = nil
    end

    if WorldFolder then
        WorldFolder:Destroy()
    end

    if _G.Leon4951Shaders == API then
        _G.Leon4951Shaders = nil
    end
end

API.Restore = restoreOriginal

----------------------------------------------------------------
-- UI: kecil, halus, fleksibel (geser / lipat / ganti ukuran)
----------------------------------------------------------------

local function createUI()
    if not Settings.ShowPanel then
        return
    end

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

    -- Judul
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

    -- Kualitas
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

    local function refreshQuality()
        qValue.Text = tostring(State.Quality)
    end
    refreshQuality()

    qMinus.MouseButton1Click:Connect(function()
        applyQuality(State.Quality - 1)
        refreshQuality()
    end)
    qPlus.MouseButton1Click:Connect(function()
        applyQuality(State.Quality + 1)
        refreshQuality()
    end)

    -- Daftar suasana (bisa digabung)
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

        button.MouseButton1Click:Connect(function()
            API.ToggleMood(mood.Name)
        end)

        rows[mood.Name] = { Button = button, Dot = dot }
    end

    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.fromOffset(0, list.AbsoluteContentSize.Y + 6)
    end)

    -- Footer
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
    offButton.MouseButton1Click:Connect(function()
        restoreOriginal()
    end)

    onSelectionChanged = refreshRows
    refreshRows()

    task.spawn(function()
        while gui.Parent do
            status.Text = string.format("%d aktif | Egg %d | FPS %d", #State.Selected, State.Stats.Eggs, State.Stats.FPS)
            task.wait(1)
        end
    end)

    -- Ganti ukuran
    sizeButton.MouseButton1Click:Connect(function()
        scaleIndex = scaleIndex % #SCALES + 1
        TweenService:Create(uiScale, tweenSlow, { Scale = SCALES[scaleIndex] }):Play()
    end)

    -- Lipat / buka
    local collapsed = false
    collapseButton.MouseButton1Click:Connect(function()
        collapsed = not collapsed
        collapseButton.Text = collapsed and "+" or "-"

        if collapsed then
            local t = TweenService:Create(panel, tweenSlow, { Size = UDim2.fromOffset(W, TITLE_H) })
            t:Play()
            t.Completed:Connect(function()
                if collapsed then
                    body.Visible = false
                end
            end)
        else
            body.Visible = true
            TweenService:Create(panel, tweenSlow, { Size = UDim2.fromOffset(W, TITLE_H + BODY_H) }):Play()
        end
    end)

    -- Geser lewat judul (posisi disimpan sebagai pecahan layar,
    -- jadi tidak terpengaruh ukuran UI)
    local dragging = false
    local dragStart, startAbs

    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startAbs = panel.AbsolutePosition
        end
    end)

    title.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    table.insert(State.Connections, UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local screen = gui.AbsoluteSize
        local delta = input.Position - dragStart
        local panelSize = panel.AbsoluteSize

        local x = math.clamp(startAbs.X + delta.X, 0, math.max(0, screen.X - panelSize.X))
        local y = math.clamp(startAbs.Y + delta.Y, 0, math.max(0, screen.Y - 30))

        panel.Position = UDim2.fromScale(x / screen.X, y / screen.Y)
    end))

    -- Tombol RightCtrl: tampil / sembunyikan panel
    table.insert(State.Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end
        if input.KeyCode == Enum.KeyCode.RightControl then
            gui.Enabled = not gui.Enabled
        end
    end))

    State.UI = gui
end

----------------------------------------------------------------
-- LOOP UTAMA
----------------------------------------------------------------

local fpsAccumulator, fpsFrames = 0, 0

table.insert(State.Connections, RunService.RenderStepped:Connect(function(dt)
    if State.Restored then
        return
    end

    updateSun(dt)
    World.Update(dt)
    SunLens.Update(dt)

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
    if State.Restored then
        return
    end

    updateEggs(dt)

    lightTimer += dt
    if lightTimer < Settings.LightUpdateInterval then
        return
    end
    lightTimer = 0

    local cam = Workspace.CurrentCamera
    if not cam then
        return
    end

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

table.insert(State.Connections, Player.CharacterAdded:Connect(function()
    World.UpdateRayParams()
end))

table.insert(State.Connections, Workspace.DescendantAdded:Connect(function(object)
    if State.Restored or not object:IsA("BasePart") then
        return
    end

    task.defer(function()
        -- telur / nest yang baru muncul (streaming atau telur baru ditaruh)
        registerEgg(object)

        if ScanDone and processPart(object) and State.Mood then
            stylePart(object, State.Mood)
        end
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

----------------------------------------------------------------
-- CARA PAKAI (console / script lain)
----------------------------------------------------------------
--   _G.Leon4951Shaders.SetMood("Sore Keemasan")
--   _G.Leon4951Shaders.SetMoods({ "Sore Keemasan", "Hujan" })   -- digabung
--   _G.Leon4951Shaders.ToggleMood("Berkabut")
--   _G.Leon4951Shaders.SetQuality(10)
--   _G.Leon4951Shaders.SetSunAnchor(Vector3.new(0, 0, 0))       -- pindah titik matahari
--   _G.Leon4951Shaders.Restore()
----------------------------------------------------------------
