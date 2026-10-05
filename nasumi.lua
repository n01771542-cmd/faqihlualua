--[[
    VISUAL REALISTIS (VERSI LENGKAP + LENSA MATAHARI)
    Roblox LocalScript
    Letakkan di: StarterPlayer > StarterPlayerScripts

    FITUR
    -----
    1. Suasana (cahaya + atmosfer + warna) yang mudah dipilih
    2. Sore Keemasan: sun rays / god rays 3D di dalam map, glow matahari 3D,
       pantulan cahaya di permukaan, ambient hangat, bayangan lembut
    3. LENSA MATAHARI: saat kamera menghadap matahari muncul inti putih panas,
       garis cahaya, sinar bintang, bokeh oranye/merah, bayangan gelap
       kemerahan, selimut hangat, dan blur halus (seperti foto referensi)
    4. Hujan: partikel hujan, tanah becek, genangan air
    5. Malam: setiap "egg" diberi cahaya hangat yang halus
    6. Kualitas 1-10

    CATATAN TEKNIS
    --------------
    - LocalScript tidak bisa membuat shader GPU custom. Skrip ini memakai
      pipeline asli Roblox (Realistic lighting, Atmosphere, Bloom, SunRays,
      ColorCorrection, Blur) + objek 3D lokal (Beam, BillboardGui, ParticleEmitter).
    - Semua objek buatan skrip hanya terlihat oleh pemain ini (client only).
    - Tidak mengubah gameplay, data pemain, atau movement.
    - Restore(): mengembalikan semua ke kondisi awal.
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

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Terrain = Workspace:WaitForChild("Terrain")

local ROOT_NAME = "VisualRealistis"

----------------------------------------------------------------
-- BERSIHKAN VERSI LAMA
----------------------------------------------------------------

for _, globalName in ipairs({ "VisualRealistis", "UltraRealisticRendererV4" }) do
    local old = _G[globalName]
    if old and old.Restore then
        pcall(old.Restore)
    end
end

for _, guiName in ipairs({
    ROOT_NAME,
    ROOT_NAME .. "_Flare",
    ROOT_NAME .. "_Lensa",
    "UltraRealisticRendererV4",
    "UltraRealisticRendererV4_Nostalgia",
}) do
    local old = PlayerGui:FindFirstChild(guiName)
    if old then
        old:Destroy()
    end
end

for _, child in ipairs(Lighting:GetChildren()) do
    if child.Name:sub(1, 3) == "VR_" or child.Name:sub(1, 5) == "URV4_" then
        child:Destroy()
    end
end

local oldFolder = Workspace:FindFirstChild("VR_Dunia")
if oldFolder then
    oldFolder:Destroy()
end

local WorldFolder = Instance.new("Folder")
WorldFolder.Name = "VR_Dunia"
WorldFolder.Parent = Workspace

----------------------------------------------------------------
-- HELPER AMAN
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
-- PENGATURAN UTAMA
----------------------------------------------------------------

local Settings = {
    Quality = 8,                   -- 1 sampai 10
    StartMood = "Sore Keemasan",
    ShowPanel = true,

    ShadowSoftness = 0.16,

    MaxAccentLights = 80,
    LightDistance = 500,
    LightUpdateInterval = 0.12,

    -- Cahaya hangat egg
    EggRange = 10,
    EggBrightness = 0.9,
    EggMaxLights = 60,
    EggDistance = 350,
    EggColor = Color3.fromRGB(255, 178, 104),
}

----------------------------------------------------------------
-- DAFTAR SUASANA
----------------------------------------------------------------
-- Field opsional:
--   Shafts     = kekuatan sun rays 3D di map (0 - 1)
--   SunGlow    = kekuatan glow matahari 3D (0 - 1)
--   Flare      = kekuatan LENSA MATAHARI di layar (0 - 1)
--   Sheen      = tambahan pantulan di permukaan
--   Rain / Wet = hujan dan tanah becek
--   EggGlow    = kekuatan cahaya hangat di egg (0 - 1)
--   Drift      = matahari turun pelan-pelan

local Moods = {
    {
        Name = "Siang Cerah",
        ClockTime = 11.0, Brightness = 2.40, Exposure = 0.03, ShadowSoftness = 0.20,
        Density = 0.25, Offset = 0.15, Haze = 0.5, Glare = 0.15,
        Color = Color3.fromRGB(205, 225, 255), Decay = Color3.fromRGB(190, 210, 240),
        Ambient = Color3.fromRGB(36, 40, 46), OutdoorAmbient = Color3.fromRGB(150, 160, 175),
        Top = Color3.fromRGB(255, 248, 235), Bottom = Color3.fromRGB(200, 205, 215),
        Bloom = 0.06, BloomSize = 18, BloomThreshold = 1.3,
        SunRays = 0.05, SunRaySpread = 0.8,
        Contrast = 0.08, Saturation = 0.03, Tint = Color3.fromRGB(255, 255, 255),
        Shafts = 0.15, SunGlow = 0.35, Flare = 0.15, Sheen = 0.03,
    },

    {
        Name = "Pagi Segar",
        ClockTime = 7.2, Brightness = 2.30, Exposure = 0.03, ShadowSoftness = 0.18,
        Density = 0.30, Offset = 0.12, Haze = 0.9, Glare = 0.30,
        Color = Color3.fromRGB(210, 228, 255), Decay = Color3.fromRGB(240, 205, 170),
        Ambient = Color3.fromRGB(40, 40, 44), OutdoorAmbient = Color3.fromRGB(140, 148, 165),
        Top = Color3.fromRGB(255, 226, 190), Bottom = Color3.fromRGB(190, 190, 205),
        Bloom = 0.10, BloomSize = 22, BloomThreshold = 1.15,
        SunRays = 0.12, SunRaySpread = 0.85,
        Contrast = 0.09, Saturation = 0.04, Tint = Color3.fromRGB(252, 250, 248),
        ShaftColor = Color3.fromRGB(255, 225, 180),
        Shafts = 0.45, SunGlow = 0.6, Flare = 0.30, Sheen = 0.05,
    },

    {
        Name = "Sore Keemasan",
        ClockTime = 17.3, Brightness = 2.55, Exposure = -0.10, ShadowSoftness = 0.10,
        Density = 0.34, Offset = 0.10, Haze = 1.7, Glare = 1.0,
        Color = Color3.fromRGB(255, 170, 100), Decay = Color3.fromRGB(240, 112, 52),
        Ambient = Color3.fromRGB(46, 32, 26), OutdoorAmbient = Color3.fromRGB(104, 78, 62),
        Top = Color3.fromRGB(255, 160, 80), Bottom = Color3.fromRGB(170, 120, 95),
        Bloom = 0.30, BloomSize = 22, BloomThreshold = 0.95,
        SunRays = 0.38, SunRaySpread = 0.9,
        Contrast = 0.18, Saturation = 0.10, Tint = Color3.fromRGB(255, 222, 190),
        ShaftColor = Color3.fromRGB(255, 170, 90),
        Shafts = 1.0, SunGlow = 1.0, Flare = 1.0, Sheen = 0.10,
        WarmBody = true,
        CloudColor = Color3.fromRGB(255, 150, 95), CloudCover = 0.45, CloudDensity = 0.5,
        EggGlow = 0.0,
        Drift = {
            Minutes = 14,
            Clock0 = 17.05, Clock1 = 17.85,
            Bright0 = 2.70, Bright1 = 2.10,
            Exp0 = -0.06, Exp1 = -0.14,
        },
    },

    {
        Name = "Senja Jingga",
        ClockTime = 18.15, Brightness = 2.0, Exposure = -0.02, ShadowSoftness = 0.12,
        Density = 0.38, Offset = 0.08, Haze = 1.9, Glare = 1.0,
        Color = Color3.fromRGB(255, 185, 150), Decay = Color3.fromRGB(205, 95, 70),
        Ambient = Color3.fromRGB(56, 38, 40), OutdoorAmbient = Color3.fromRGB(125, 92, 98),
        Top = Color3.fromRGB(255, 170, 125), Bottom = Color3.fromRGB(170, 120, 125),
        Bloom = 0.30, BloomSize = 24, BloomThreshold = 0.95,
        SunRays = 0.32, SunRaySpread = 0.9,
        Contrast = 0.12, Saturation = 0.08, Tint = Color3.fromRGB(255, 232, 215),
        ShaftColor = Color3.fromRGB(255, 180, 125),
        Shafts = 0.8, SunGlow = 1.0, Flare = 0.8, Sheen = 0.07,
        CloudColor = Color3.fromRGB(240, 130, 110), CloudCover = 0.5, CloudDensity = 0.5,
        EggGlow = 0.35,
    },

    {
        Name = "Sedikit Sore",
        ClockTime = 16.5, Brightness = 1.90, Exposure = -0.03, ShadowSoftness = 0.20,
        Density = 0.30, Offset = 0.08, Haze = 1.2, Glare = 0.0,
        Color = Color3.fromRGB(255, 205, 140), Decay = Color3.fromRGB(240, 150, 70),
        Ambient = Color3.fromRGB(52, 40, 28), OutdoorAmbient = Color3.fromRGB(120, 98, 72),
        Top = Color3.fromRGB(255, 200, 110), Bottom = Color3.fromRGB(190, 150, 100),
        Bloom = 0.10, BloomSize = 22, BloomThreshold = 1.1,
        SunRays = 0.0, SunRaySpread = 0.8,
        Contrast = 0.12, Saturation = 0.08, Tint = Color3.fromRGB(255, 235, 200),
        Shafts = 0, SunGlow = 0, Flare = 0, Sheen = 0.06,
        HideSun = true,
        CloudColor = Color3.fromRGB(255, 200, 120), CloudCover = 0.55, CloudDensity = 0.5,
        EggGlow = 0.1,
    },

    {
        Name = "Kabut Halus",
        ClockTime = 9.5, Brightness = 1.75, Exposure = -0.06, ShadowSoftness = 0.28,
        Density = 0.42, Offset = 0.0, Haze = 1.8, Glare = 0.1,
        Color = Color3.fromRGB(205, 215, 226), Decay = Color3.fromRGB(160, 172, 190),
        Ambient = Color3.fromRGB(38, 41, 46), OutdoorAmbient = Color3.fromRGB(100, 108, 120),
        Top = Color3.fromRGB(225, 225, 222), Bottom = Color3.fromRGB(160, 166, 176),
        Bloom = 0.05, BloomSize = 22, BloomThreshold = 1.2,
        SunRays = 0.04, SunRaySpread = 0.85,
        Contrast = 0.08, Saturation = -0.03, Tint = Color3.fromRGB(238, 242, 246),
        ShaftColor = Color3.fromRGB(235, 232, 220),
        Shafts = 0.2, SunGlow = 0.15, Flare = 0.05,
        CloudColor = Color3.fromRGB(190, 196, 206), CloudCover = 0.65, CloudDensity = 0.55,
        EggGlow = 0.2,
    },

    {
        Name = "Sedikit Gelap",
        ClockTime = 19.2, Brightness = 1.20, Exposure = -0.15, ShadowSoftness = 0.25,
        Density = 0.30, Offset = 0.10, Haze = 1.0, Glare = 0.0,
        Color = Color3.fromRGB(150, 160, 185), Decay = Color3.fromRGB(80, 90, 120),
        Ambient = Color3.fromRGB(24, 26, 34), OutdoorAmbient = Color3.fromRGB(70, 76, 96),
        Top = Color3.fromRGB(150, 160, 190), Bottom = Color3.fromRGB(70, 72, 92),
        Bloom = 0.05, BloomSize = 20, BloomThreshold = 1.1,
        SunRays = 0.0, SunRaySpread = 0.8,
        Contrast = 0.14, Saturation = -0.02, Tint = Color3.fromRGB(225, 230, 245),
        Shafts = 0, SunGlow = 0, Flare = 0,
        EggGlow = 0.6,
    },

    {
        Name = "Hujan",
        ClockTime = 14.5, Brightness = 1.35, Exposure = -0.10, ShadowSoftness = 0.35,
        Density = 0.45, Offset = 0.02, Haze = 2.0, Glare = 0.0,
        Color = Color3.fromRGB(160, 166, 174), Decay = Color3.fromRGB(120, 127, 138),
        Ambient = Color3.fromRGB(40, 42, 46), OutdoorAmbient = Color3.fromRGB(88, 94, 102),
        Top = Color3.fromRGB(180, 184, 190), Bottom = Color3.fromRGB(115, 119, 126),
        Bloom = 0.05, BloomSize = 20, BloomThreshold = 1.2,
        SunRays = 0.0, SunRaySpread = 0.8,
        Contrast = 0.12, Saturation = -0.03, Tint = Color3.fromRGB(225, 228, 233),
        Rain = true, Wet = true, Sheen = 0.12,
        CloudColor = Color3.fromRGB(120, 128, 140), CloudCover = 0.9, CloudDensity = 0.8,
        EggGlow = 0.4,
    },

    {
        Name = "Berkabut",
        ClockTime = 8.0, Brightness = 1.95, Exposure = 0.0, ShadowSoftness = 0.30,
        Density = 0.55, Offset = 0.0, Haze = 3.0, Glare = 0.2,
        Color = Color3.fromRGB(215, 225, 236), Decay = Color3.fromRGB(170, 182, 205),
        Ambient = Color3.fromRGB(47, 50, 54), OutdoorAmbient = Color3.fromRGB(120, 128, 140),
        Top = Color3.fromRGB(240, 238, 232), Bottom = Color3.fromRGB(190, 195, 205),
        Bloom = 0.06, BloomSize = 26, BloomThreshold = 1.2,
        SunRays = 0.08, SunRaySpread = 0.9,
        Contrast = 0.035, Saturation = -0.02, Tint = Color3.fromRGB(245, 248, 252),
        ShaftColor = Color3.fromRGB(240, 235, 220),
        Shafts = 0.5, SunGlow = 0.3, Flare = 0.1,
        CloudColor = Color3.fromRGB(225, 228, 234), CloudCover = 0.7, CloudDensity = 0.6,
        EggGlow = 0.2,
    },

    {
        Name = "Hutan Hijau",
        ClockTime = 9.3, Brightness = 2.15, Exposure = 0.015, ShadowSoftness = 0.2,
        Density = 0.35, Offset = 0.10, Haze = 1.1, Glare = 0.3,
        Color = Color3.fromRGB(185, 215, 190), Decay = Color3.fromRGB(105, 155, 115),
        Ambient = Color3.fromRGB(24, 38, 27), OutdoorAmbient = Color3.fromRGB(90, 125, 96),
        Top = Color3.fromRGB(255, 240, 200), Bottom = Color3.fromRGB(205, 225, 185),
        Bloom = 0.06, BloomSize = 20, BloomThreshold = 1.2,
        SunRays = 0.12, SunRaySpread = 0.85,
        Contrast = 0.10, Saturation = 0.07, Tint = Color3.fromRGB(238, 250, 236),
        ShaftColor = Color3.fromRGB(255, 240, 190),
        Shafts = 0.9, SunGlow = 0.5, Flare = 0.2, Sheen = 0.04,
    },

    {
        Name = "Pantai Tropis",
        ClockTime = 10.6, Brightness = 2.34, Exposure = 0.035, ShadowSoftness = 0.2,
        Density = 0.22, Offset = 0.14, Haze = 0.6, Glare = 0.2,
        Color = Color3.fromRGB(190, 225, 225), Decay = Color3.fromRGB(116, 185, 170),
        Ambient = Color3.fromRGB(27, 43, 37), OutdoorAmbient = Color3.fromRGB(125, 158, 143),
        Top = Color3.fromRGB(255, 248, 230), Bottom = Color3.fromRGB(218, 242, 206),
        Bloom = 0.065, BloomSize = 18, BloomThreshold = 1.25,
        SunRays = 0.06, SunRaySpread = 0.8,
        Contrast = 0.09, Saturation = 0.08, Tint = Color3.fromRGB(244, 255, 245),
        Shafts = 0.2, SunGlow = 0.45, Flare = 0.2, Sheen = 0.06,
    },

    {
        Name = "Gurun Pasir",
        ClockTime = 15.5, Brightness = 2.30, Exposure = 0.04, ShadowSoftness = 0.18,
        Density = 0.30, Offset = 0.16, Haze = 1.0, Glare = 0.3,
        Color = Color3.fromRGB(238, 220, 188), Decay = Color3.fromRGB(202, 166, 113),
        Ambient = Color3.fromRGB(52, 43, 32), OutdoorAmbient = Color3.fromRGB(167, 145, 115),
        Top = Color3.fromRGB(255, 232, 190), Bottom = Color3.fromRGB(255, 213, 158),
        Bloom = 0.065, BloomSize = 20, BloomThreshold = 1.2,
        SunRays = 0.08, SunRaySpread = 0.85,
        Contrast = 0.10, Saturation = 0.065, Tint = Color3.fromRGB(255, 248, 232),
        ShaftColor = Color3.fromRGB(255, 220, 160),
        Shafts = 0.3, SunGlow = 0.6, Flare = 0.25, Sheen = 0.04,
    },

    {
        Name = "Gunung Berapi",
        ClockTime = 19.4, Brightness = 1.70, Exposure = 0.0, ShadowSoftness = 0.2,
        Density = 0.60, Offset = 0.06, Haze = 2.0, Glare = 0.2,
        Color = Color3.fromRGB(235, 150, 120), Decay = Color3.fromRGB(150, 52, 38),
        Ambient = Color3.fromRGB(42, 20, 18), OutdoorAmbient = Color3.fromRGB(110, 53, 45),
        Top = Color3.fromRGB(255, 170, 130), Bottom = Color3.fromRGB(205, 78, 44),
        Bloom = 0.12, BloomSize = 24, BloomThreshold = 1.0,
        SunRays = 0.0, SunRaySpread = 0.8,
        Contrast = 0.16, Saturation = 0.10, Tint = Color3.fromRGB(255, 235, 220),
        EggGlow = 0.5,
    },

    {
        Name = "Malam Bulan",
        ClockTime = 0.35, Brightness = 1.30, Exposure = -0.05, ShadowSoftness = 0.22,
        Density = 0.25, Offset = 0.22, Haze = 0.5, Glare = 0.0,
        Color = Color3.fromRGB(140, 170, 220), Decay = Color3.fromRGB(76, 92, 135),
        Ambient = Color3.fromRGB(14, 18, 30), OutdoorAmbient = Color3.fromRGB(54, 65, 92),
        Top = Color3.fromRGB(150, 175, 230), Bottom = Color3.fromRGB(80, 90, 125),
        Bloom = 0.06, BloomSize = 20, BloomThreshold = 1.1,
        SunRays = 0.0, SunRaySpread = 0.8,
        Contrast = 0.16, Saturation = 0.025, Tint = Color3.fromRGB(210, 225, 255),
        Night = true, EggGlow = 1.0,
    },

    {
        Name = "Malam Gelap",
        ClockTime = 2.1, Brightness = 0.92, Exposure = -0.08, ShadowSoftness = 0.25,
        Density = 0.20, Offset = 0.26, Haze = 0.3, Glare = 0.0,
        Color = Color3.fromRGB(75, 100, 160), Decay = Color3.fromRGB(35, 46, 82),
        Ambient = Color3.fromRGB(7, 9, 18), OutdoorAmbient = Color3.fromRGB(27, 33, 57),
        Top = Color3.fromRGB(110, 130, 190), Bottom = Color3.fromRGB(42, 45, 68),
        Bloom = 0.05, BloomSize = 20, BloomThreshold = 1.0,
        SunRays = 0.0, SunRaySpread = 0.8,
        Contrast = 0.18, Saturation = 0.01, Tint = Color3.fromRGB(190, 210, 255),
        Night = true, EggGlow = 1.0,
    },

    {
        Name = "Malam Kota Neon",
        ClockTime = 22.1, Brightness = 1.15, Exposure = -0.025, ShadowSoftness = 0.22,
        Density = 0.28, Offset = 0.20, Haze = 0.6, Glare = 0.0,
        Color = Color3.fromRGB(110, 165, 220), Decay = Color3.fromRGB(70, 75, 150),
        Ambient = Color3.fromRGB(12, 17, 28), OutdoorAmbient = Color3.fromRGB(42, 54, 84),
        Top = Color3.fromRGB(120, 150, 210), Bottom = Color3.fromRGB(62, 65, 112),
        Bloom = 0.15, BloomSize = 24, BloomThreshold = 0.95,
        SunRays = 0.0, SunRaySpread = 0.8,
        Contrast = 0.18, Saturation = 0.09, Tint = Color3.fromRGB(225, 235, 255),
        Night = true, EggGlow = 1.0,
    },
}

local MoodByName = {}
for _, mood in ipairs(Moods) do
    MoodByName[mood.Name] = mood
end

if not MoodByName[Settings.StartMood] then
    Settings.StartMood = Moods[1].Name
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
    MoodName = Settings.StartMood,
    Mood = nil,

    Instances = {
        Atmosphere = nil,
        Bloom = nil,
        Color = nil,
        SunRays = nil,
    },

    Base = {
        Bloom = 0,
        SunRays = 0,
        Glare = 0,
        Tint = Color3.new(1, 1, 1),
        Saturation = 0,
        Brightness = 0,
    },

    AccentLights = {},
    Connections = {},
    UI = nil,
    Restored = false,

    Stats = {
        Parts = 0,
        Ground = 0,
        Lights = 0,
        Eggs = 0,
        FPS = 0,
    },
}

local PartList = {}
local PartInfo = setmetatable({}, weakKeys)
local ScanDone = false

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
        "Ambient", "OutdoorAmbient", "ColorShift_Top", "ColorShift_Bottom",
        "ClockTime",
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
        atmosphere = createEffect("Atmosphere", "VR_Atmosphere")
        State.Instances.Atmosphere = atmosphere
    end

    -- Hanya satu Atmosphere yang aktif, jadi Atmosphere bawaan map disimpan dulu.
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
        bloom = createEffect("BloomEffect", "VR_Bloom")
        State.Instances.Bloom = bloom
    end

    State.Base.Bloom = mood.Bloom * (0.6 + 0.4 * scale)
    setProperty(bloom, "Intensity", State.Base.Bloom)
    setProperty(bloom, "Size", mood.BloomSize or 20)
    setProperty(bloom, "Threshold", mood.BloomThreshold or 1.2)
    setProperty(bloom, "Enabled", true)

    local color = State.Instances.Color
    if not color then
        color = createEffect("ColorCorrectionEffect", "VR_Warna")
        State.Instances.Color = color
    end

    State.Base.Tint = mood.Tint
    State.Base.Saturation = mood.Saturation
    setProperty(color, "Brightness", 0)
    setProperty(color, "Contrast", mood.Contrast)
    setProperty(color, "Saturation", mood.Saturation)
    setProperty(color, "TintColor", mood.Tint)
    setProperty(color, "Enabled", true)

    local sun = State.Instances.SunRays
    if not sun then
        sun = createEffect("SunRaysEffect", "VR_SunRays")
        State.Instances.SunRays = sun
    end

    State.Base.SunRays = (mood.SunRays or 0) * (0.5 + 0.5 * scale)
    setProperty(sun, "Intensity", State.Base.SunRays)
    setProperty(sun, "Spread", mood.SunRaySpread or 0.8)
    setProperty(sun, "Enabled", true)
end

local function configureMoodLighting(mood)
    setProperty(Lighting, "ClockTime", mood.ClockTime)
    setProperty(Lighting, "Brightness", mood.Brightness)
    setProperty(Lighting, "ExposureCompensation", mood.Exposure)
    setProperty(Lighting, "ShadowSoftness", mood.ShadowSoftness or Settings.ShadowSoftness)

    setProperty(Lighting, "Ambient", mood.Ambient)
    setProperty(Lighting, "OutdoorAmbient", mood.OutdoorAmbient)
    setProperty(Lighting, "ColorShift_Top", mood.Top)
    setProperty(Lighting, "ColorShift_Bottom", mood.Bottom)

    configureAtmosphere(mood)
    configureShaders(mood)
end

----------------------------------------------------------------
-- KLASIFIKASI MATERIAL
----------------------------------------------------------------

local GROUND_MATERIALS = {
    [Enum.Material.Grass] = true,
    [Enum.Material.LeafyGrass] = true,
    [Enum.Material.Ground] = true,
    [Enum.Material.Mud] = true,
    [Enum.Material.Sand] = true,
    [Enum.Material.Sandstone] = true,
    [Enum.Material.Asphalt] = true,
    [Enum.Material.Pavement] = true,
    [Enum.Material.Concrete] = true,
    [Enum.Material.Cobblestone] = true,
    [Enum.Material.Brick] = true,
    [Enum.Material.Slate] = true,
    [Enum.Material.Rock] = true,
    [Enum.Material.Basalt] = true,
    [Enum.Material.Limestone] = true,
    [Enum.Material.Granite] = true,
    [Enum.Material.Pebble] = true,
    [Enum.Material.WoodPlanks] = true,
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
        Type = "DEFAULT",
        Base = 0,
        Factor = 0.25,
        Ground = false,
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
-- CAHAYA HANGAT EGG (malam)
----------------------------------------------------------------

local Eggs = {
    Records = {},
    Keys = setmetatable({}, weakKeys),
    Timer = 0,
}

local eggRng = Random.new(77)

local function findEggKey(part)
    local name = string.lower(part.Name)

    if name:find("egg", 1, true) and not name:find("legging", 1, true) and not name:find("eggplant", 1, true) then
        return part
    end

    local parent = part.Parent
    for _ = 1, 3 do
        if not parent or parent == Workspace then
            break
        end

        if parent:IsA("Model") then
            local modelName = string.lower(parent.Name)
            if modelName:find("egg", 1, true) and not modelName:find("legging", 1, true) and not modelName:find("eggplant", 1, true) then
                return parent
            end
        end

        parent = parent.Parent
    end

    return nil
end

local function registerEgg(part)
    local key = findEggKey(part)
    if not key or Eggs.Keys[key] then
        return
    end

    Eggs.Keys[key] = true

    local light = Instance.new("PointLight")
    light.Name = "VR_EggGlow"
    light.Color = Settings.EggColor
    light.Range = Settings.EggRange
    light.Brightness = 0
    light.Shadows = false
    light.Enabled = false
    light.Parent = part

    table.insert(Eggs.Records, {
        Part = part,
        Light = light,
        Phase = eggRng:NextNumber() * math.pi * 2,
        Level = 0,
        Wanted = false,
        Dist = math.huge,
    })

    State.Stats.Eggs = #Eggs.Records
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
                if record.Light then
                    record.Light:Destroy()
                end
                table.remove(Eggs.Records, i)
            else
                record.Dist = camPos and (record.Part.Position - camPos).Magnitude or math.huge
            end
        end

        local sorted = table.clone(Eggs.Records)
        table.sort(sorted, function(a, b)
            return a.Dist < b.Dist
        end)

        for index, record in ipairs(sorted) do
            record.Wanted = index <= Settings.EggMaxLights and record.Dist <= Settings.EggDistance
        end

        State.Stats.Eggs = #Eggs.Records
    end

    local speed = math.min(1, dt * 2)

    for _, record in ipairs(Eggs.Records) do
        local target = (glow > 0 and record.Wanted) and 1 or 0
        record.Level = lerp(record.Level, target, speed)

        if record.Level > 0.02 then
            local breathing = 1 + 0.05 * math.sin(now * 1.3 + record.Phase)
            record.Light.Brightness = record.Level * glow * Settings.EggBrightness * breathing
            record.Light.Enabled = true
        else
            record.Light.Enabled = false
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

    registerEgg(part)

    return info
end

local SLICK_MATERIALS = {
    [Enum.Material.Concrete] = true,
    [Enum.Material.Asphalt] = true,
    [Enum.Material.Pavement] = true,
    [Enum.Material.Cobblestone] = true,
    [Enum.Material.Brick] = true,
    [Enum.Material.Slate] = true,
    [Enum.Material.Granite] = true,
    [Enum.Material.Limestone] = true,
    [Enum.Material.WoodPlanks] = true,
    [Enum.Material.Plastic] = true,
}

local function stylePart(part, mood)
    local info = PartInfo[part]
    local original = Original.Parts[part]

    if not info or not original or not part.Parent then
        return
    end

    local sheen = (mood.Sheen or 0) * State.Scale
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

    -- Permukaan keras jadi licin (smooth) saat basah, dikembalikan saat kering.
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

-- Terrain: warna material digelapkan saat basah.
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
        return Color3.fromRGB(255, 170, 90)
    end

    if name:find("crystal") or name:find("ice") then
        return Color3.fromRGB(150, 210, 255)
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
        if not part:FindFirstChild("VR_AccentAttachment") then
            local attachment = Instance.new("Attachment")
            attachment.Name = "VR_AccentAttachment"
            attachment.Parent = part

            local light = Instance.new("PointLight")
            light.Name = "VR_AccentLight"
            light.Color = getLightColor(part)
            light.Brightness = 0.65
            light.Range = 12
            light.Shadows = true
            light.Parent = attachment

            table.insert(State.AccentLights, {
                Source = part,
                Attachment = attachment,
                Light = light,
            })
        end
    end

    State.Stats.Lights = #State.AccentLights
end

----------------------------------------------------------------
-- DUNIA 3D: sun rays, glow matahari, hujan, genangan
----------------------------------------------------------------

local World = {}

do
    local SUN_DISTANCE = 1800       -- jarak glow matahari dari kamera
    local MAX_SHAFTS = 36
    local MAX_PUDDLES = 80
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

    local sunDir = Vector3.new(0, 1, 0)
    local sunVis = 0
    local rainLevel = 0
    local coverLevel = 1
    local coverTarget = 1
    local driftClock = 0
    local elevationVis = 0

    local lastSeedPos, lastSeedSun, lastPuddlePos
    local timers = { Shaft = 0, Rain = 0 }

    local cloudsState
    local bodyAttachment, bodyLight
    local bodyBrightness = 0

    ------------------------------------------------------------
    -- Ray params
    ------------------------------------------------------------

    local function updateRayParams()
        rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.RespectCanCollide = false

        local list = { WorldFolder }
        if Player.Character then
            table.insert(list, Player.Character)
        end
        rayParams.FilterDescendantsInstances = list
    end

    World.UpdateRayParams = updateRayParams

    ------------------------------------------------------------
    -- Build
    ------------------------------------------------------------

    local SUN_LAYERS = {
        { size = 1.00, alpha = 0.960, color = Color3.fromRGB(255, 140, 60) },
        { size = 0.62, alpha = 0.920, color = Color3.fromRGB(255, 165, 70) },
        { size = 0.36, alpha = 0.840, color = Color3.fromRGB(255, 195, 95) },
        { size = 0.18, alpha = 0.650, color = Color3.fromRGB(255, 225, 130) },
        { size = 0.08, alpha = 0.300, color = Color3.fromRGB(255, 246, 200) },
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

        anchor = makeInvisiblePart("VR_Anchor")
        anchor.CFrame = CFrame.new(0, 0, 0)

        -- Glow matahari 3D (tertutup bangunan karena depth-tested)
        sunPart = makeInvisiblePart("VR_Matahari")

        sunGui = Instance.new("BillboardGui")
        sunGui.Name = "VR_GlowMatahari"
        sunGui.Adornee = sunPart
        sunGui.AlwaysOnTop = false
        sunGui.LightInfluence = 0
        sunGui.MaxDistance = math.huge
        sunGui.Size = UDim2.fromScale(SUN_DISTANCE * 0.5, SUN_DISTANCE * 0.5)
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
        sunStreak.Size = UDim2.fromScale(1.8, 0.012)
        sunStreak.BackgroundColor3 = Color3.fromRGB(255, 205, 140)
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

            table.insert(shafts, {
                Beam = beam,
                A0 = a0,
                A1 = a1,
                Active = false,
                Pos = Vector3.zero,
                Rand = 1,
            })
        end

        -- Hujan
        rainPart = makeInvisiblePart("VR_Hujan")
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
            e.Color = ColorSequence.new(Color3.fromRGB(205, 220, 238))
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
            rainSound.Name = "VR_SuaraHujan"
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
        local wantsClouds = m and m.CloudColor ~= nil

        if wantsClouds then
            if not cloudsState then
                local existing = Terrain:FindFirstChildOfClass("Clouds")
                if existing then
                    cloudsState = {
                        Object = existing,
                        Owned = false,
                        Saved = {
                            Color = existing.Color,
                            Cover = existing.Cover,
                            Density = existing.Density,
                            Enabled = existing.Enabled,
                        },
                    }
                else
                    local c = Instance.new("Clouds")
                    c.Name = "VR_Awan"
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
        local count = math.floor(MAX_SHAFTS * State.Scale)
        local color = mood.ShaftColor or Color3.fromRGB(255, 205, 140)

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
    -- Genangan air
    ------------------------------------------------------------

    local function newDisc(withSheen)
        local p = Instance.new("Part")
        p.Name = "VR_Genangan"
        p.Shape = Enum.PartType.Cylinder
        p.Anchored = true
        p.CanCollide = false
        p.CanQuery = false
        p.CanTouch = false
        p.CastShadow = false
        -- Kaca bening (tembus ke tanah) + pantulan kuat
        p.Material = Enum.Material.Glass
        p.Color = Color3.fromRGB(240, 246, 250)
        p.Reflectance = 1
        p.Transparency = 1

        if withSheen then
            -- Lapisan pantulan cahaya langit: terang, putih kebiruan tipis, bukan biru tua
            local sg = Instance.new("SurfaceGui")
            sg.Name = "VR_Pantulan"
            sg.Face = Enum.NormalId.Right
            sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
            sg.PixelsPerStud = 16
            sg.LightInfluence = 0.5
            sg.AlwaysOnTop = false
            sg.Enabled = false
            sg.Parent = p

            local f = Instance.new("Frame")
            f.BorderSizePixel = 0
            f.Size = UDim2.fromScale(1, 1)
            f.BackgroundColor3 = Color3.fromRGB(240, 246, 252)
            f.Parent = sg

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(1, 0)
            corner.Parent = f

            local gradient = Instance.new("UIGradient")
            gradient.Rotation = 40
            gradient.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.35),
                NumberSequenceKeypoint.new(0.5, 0.82),
                NumberSequenceKeypoint.new(1, 0.55),
            })
            gradient.Parent = f

            local rim = Instance.new("UIStroke")
            rim.Color = Color3.fromRGB(255, 255, 255)
            rim.Thickness = 2
            rim.Transparency = 0.45
            rim.Parent = f

            -- Kilau cahaya diagonal
            local glint = Instance.new("Frame")
            glint.BorderSizePixel = 0
            glint.AnchorPoint = Vector2.new(0.5, 0.5)
            glint.Position = UDim2.fromScale(0.36, 0.32)
            glint.Size = UDim2.fromScale(0.45, 0.05)
            glint.Rotation = -30
            glint.BackgroundColor3 = Color3.new(1, 1, 1)
            glint.BackgroundTransparency = 0.35
            glint.Parent = f

            local glintCorner = Instance.new("UICorner")
            glintCorner.CornerRadius = UDim.new(1, 0)
            glintCorner.Parent = glint
        end

        return p
    end

    local function setPuddlesTransparency(t)
        for _, puddle in ipairs(puddles) do
            puddle.A.Transparency = t
            puddle.B.Transparency = t

            local sheen = puddle.A:FindFirstChild("VR_Pantulan")
            if sheen then
                sheen.Enabled = t < 0.99 and puddle.A.Parent ~= nil
            end
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
                    puddle.A.Parent = nil
                    puddle.B.Parent = nil
                end
            else
                if not puddle then
                    puddle = { A = newDisc(true), B = newDisc(false) }
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

                    -- Tidak ada genangan di bawah atap rendah
                    if valid and Workspace:Raycast(hit.Position + Vector3.new(0, 1, 0), Vector3.new(0, 40, 0), rayParams) then
                        valid = false
                    end
                end

                if valid then
                    local d = rng:NextNumber(4, 16)
                    local yaw = rng:NextNumber(0, math.pi)
                    local pos = hit.Position + Vector3.new(0, 0.05, 0)

                    puddle.A.Size = Vector3.new(0.05, d, d * rng:NextNumber(0.7, 1))
                    puddle.A.CFrame = CFrame.new(pos) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(0, 0, math.pi / 2)

                    -- Bagian kedua menumpuk agar bentuknya tidak bulat sempurna
                    local shift = Vector3.new(rng:NextNumber(-0.3, 0.3) * d, 0.012, rng:NextNumber(-0.3, 0.3) * d)
                    local d2 = d * rng:NextNumber(0.5, 0.8)
                    puddle.B.Size = Vector3.new(0.05, d2, d2 * rng:NextNumber(0.7, 1))
                    puddle.B.CFrame = CFrame.new(pos + shift) * CFrame.Angles(0, yaw + 1.1, 0) * CFrame.Angles(0, 0, math.pi / 2)

                    puddle.A.Parent = WorldFolder
                    puddle.B.Parent = WorldFolder
                else
                    puddle.A.Parent = nil
                    puddle.B.Parent = nil
                end
            end
        end

        lastPuddlePos = center
    end

    ------------------------------------------------------------
    -- Cahaya hangat di tubuh karakter (sore)
    ------------------------------------------------------------

    local function updateBody(dt, strength)
        local char = Player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then
            return
        end

        if not bodyAttachment or not bodyAttachment.Parent then
            bodyAttachment = Instance.new("Attachment")
            bodyAttachment.Name = "VR_CahayaTubuh"
            bodyAttachment.Parent = anchor

            bodyLight = Instance.new("PointLight")
            bodyLight.Name = "VR_CahayaTubuhLampu"
            bodyLight.Color = Color3.fromRGB(255, 160, 80)
            bodyLight.Range = 16
            bodyLight.Brightness = 0
            bodyLight.Shadows = false
            bodyLight.Parent = bodyAttachment
        end

        bodyAttachment.Position = root.Position + sunDir * 7 + Vector3.new(0, 1.5, 0)

        local covered = Workspace:Raycast(root.Position + Vector3.new(0, 2, 0), sunDir * 300, rayParams) ~= nil
        local elevation = math.clamp(sunDir.Y * 4 + 0.35, 0, 1)
        local target = covered and 0 or (1.0 * elevation * strength)

        bodyBrightness = lerp(bodyBrightness, target, math.min(1, dt * 2.5))
        bodyLight.Brightness = bodyBrightness
    end

    ------------------------------------------------------------
    -- API
    ------------------------------------------------------------

    function World.SetMood(m)
        build()
        mood = m
        driftClock = 0
        lastSeedPos = nil
        lastPuddlePos = nil
        applyClouds(m)

        if not (m and m.WarmBody) and bodyLight then
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

        -- Matahari turun pelan (jika mood punya Drift)
        local drift = mood.Drift
        if drift then
            driftClock += dt

            local phase = (driftClock / (drift.Minutes * 60)) % 2
            local t = phase < 1 and phase or (2 - phase)
            t = t * t * (3 - 2 * t)

            local breathing = math.sin(os.clock() * 0.7) * 0.02

            setProperty(Lighting, "ClockTime", lerp(drift.Clock0, drift.Clock1, t))
            setProperty(Lighting, "Brightness", lerp(drift.Bright0, drift.Bright1, t) + breathing)
            setProperty(Lighting, "ExposureCompensation", lerp(drift.Exp0, drift.Exp1, t))
        end

        sunDir = Lighting:GetSunDirection()

        local camPos = cam.CFrame.Position
        local facing = clamp01(cam.CFrame.LookVector:Dot(sunDir))
        local f2 = facing * facing
        local f3 = f2 * facing

        elevationVis = clamp01((sunDir.Y + 0.05) / 0.12)

        local screenPoint, onScreen = cam:WorldToViewportPoint(camPos + sunDir * SUN_DISTANCE)
        local clearRays = 0
        local rayOffsets = {
            Vector3.zero,
            cam.CFrame.RightVector * 0.04,
            -cam.CFrame.RightVector * 0.04,
            cam.CFrame.UpVector * 0.04,
            -cam.CFrame.UpVector * 0.04,
        }
        for _, offset in ipairs(rayOffsets) do
            if not Workspace:Raycast(camPos, (sunDir + offset).Unit * 3000, rayParams) then
                clearRays += 1
            end
        end
        local visibleTarget = (onScreen and screenPoint.Z > 0) and clearRays / #rayOffsets or 0
        sunVis = lerp(sunVis, visibleTarget, math.min(1, dt * 4))

        local sunSensitive = (mood.SunGlow or 0) > 0 and 1 or 0

        ------------------------------------------------------------
        -- Glow matahari 3D
        ------------------------------------------------------------
        local glow = (mood.SunGlow or 0) * elevationVis
        sunGui.Enabled = glow > 0.01

        if sunGui.Enabled then
            sunPart.CFrame = CFrame.new(camPos + sunDir * SUN_DISTANCE)

            local a = clamp01(glow * (0.6 + 0.4 * facing))
            for _, layer in ipairs(sunLayers) do
                layer.Frame.BackgroundTransparency = 1 - (1 - layer.Alpha) * a
            end

            sunStreak.BackgroundTransparency = 1 - 0.75 * a * (0.3 + 0.7 * facing)
        end

        ------------------------------------------------------------
        -- Efek kamera: bloom / sun rays / glare naik saat menghadap matahari
        ------------------------------------------------------------
        local sens = elevationVis * sunVis * sunSensitive

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
            grade.TintColor = State.Base.Tint:Lerp(Color3.fromRGB(255, 205, 150), 0.25 * f2 * sens)
            grade.Saturation = State.Base.Saturation + 0.04 * f2 * sens
            grade.Brightness = 0.06 * f3 * sens
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

            local strength = (mood.Shafts or 0) * scale * elevationVis

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
                    local amount = strength * (0.30 + 0.70 * facing) * shaft.Rand * 0.17 * near
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
        -- Hujan + genangan
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

                setPuddlesTransparency(1 - 0.5 * clamp01(rainLevel * 1.2))
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

        ------------------------------------------------------------
        -- Cahaya hangat tubuh (sore)
        ------------------------------------------------------------
        if mood.WarmBody then
            updateBody(dt, 1)
        end
    end

    function World.Destroy()
        applyClouds(nil)

        if rainSound then
            rainSound:Destroy()
            rainSound = nil
        end

        for _, puddle in ipairs(puddles) do
            puddle.A:Destroy()
            puddle.B:Destroy()
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
-- LENSA MATAHARI (v2)
-- Meniru 3 foto referensi:
--  * inti putih panas + balok cahaya miring "\" (foto 1, 2, 3)
--  * sinar bintang tipis dan halo oranye lembut (foto 3)
--  * ghost merah-oranye kiri & kanan dengan tepi kehijauan (foto 3)
--  * ghost kecil + cincin kuning di bawah-kiri matahari (foto 3)
--  * bokeh oranye/kuning/merah di bawah matahari (foto 1, 2)
--  * bayangan gelap kemerahan di tepi + cincin bokeh di pinggirnya (foto 1, 2)
--  * langit memutih, selimut hangat, vignette gelap, blur lembut
----------------------------------------------------------------

local SunLens = {}

do
    local LENS_INTENSITY = 1.0   -- naikkan (mis. 1.3) kalau mau lebih kuat
    local TILT = -22             -- kemiringan balok cahaya; negatif = "\" seperti foto
    local rgb = Color3.fromRGB

    local gui, blur
    local rig, beam
    local ghostL, ghostR
    local occluder, occGradient, rimGlow
    local layers, spots = {}, {}
    local level = 0
    local built = false
    local sideCache = 0

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.RespectCanCollide = false

    -- Jumlah lapisan ikut kualitas (makin rendah makin ringan)
    local function steps(n)
        return math.max(4, math.floor(n * (0.55 + 0.45 * State.Scale) + 0.5))
    end

    -- Setiap lapisan: opacity penuh (Op) dan batas kemunculan (Gate 0-1)
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

    -- Tumpukan elips berlapis = gradasi radial lembut (tanpa shader)
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

    -- Balok cahaya panjang: pinggir lebar oranye, tengah sempit kuning-putih,
    -- ujung atas/bawah memudar
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

    -- Lingkaran bokeh / ghost yang posisinya dihitung tiap frame
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
        gui.Name = ROOT_NAME .. "_Lensa"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = -1
        gui.Enabled = false
        gui.Parent = PlayerGui

        ------------------------------------------------------------
        -- 1. Selimut hangat: atas kuning pucat, bawah oranye tua
        ------------------------------------------------------------
        local wash = newFrame(gui)
        wash.AnchorPoint = Vector2.new(0, 0)
        wash.Position = UDim2.fromScale(0, 0)
        wash.Size = UDim2.fromScale(1, 1)
        gradient(wash, 90,
            ColorSequence.new(rgb(255, 196, 90), rgb(190, 80, 16)),
            seq({ 0, 0.1 }, { 1, 0 }))
        register(wash, "BackgroundTransparency", 0.58, 0)

        -- Langit memutih di bagian atas (foto 1 & 2)
        local sky = newFrame(gui, rgb(255, 242, 175))
        sky.AnchorPoint = Vector2.new(0, 0)
        sky.Position = UDim2.fromScale(0, 0)
        sky.Size = UDim2.fromScale(1, 0.6)
        gradient(sky, 90, nil, seq({ 0, 0.2 }, { 1, 1 }))
        register(sky, "BackgroundTransparency", 0.75, 0.25)

        ------------------------------------------------------------
        -- 2. Ghost merah-oranye kiri & kanan (foto 3)
        ------------------------------------------------------------
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

        ------------------------------------------------------------
        -- 3. Bayangan gelap kemerahan di tepi + cahaya pinggirnya (foto 1 & 2)
        ------------------------------------------------------------
        occluder = newFrame(gui)
        occluder.Size = UDim2.fromScale(0.34, 1)

        local body = newFrame(occluder, rgb(58, 16, 4))
        body.AnchorPoint = Vector2.new(0, 0)
        body.Position = UDim2.fromScale(0, 0)
        body.Size = UDim2.fromScale(1, 1)
        occGradient = gradient(body, 0, nil, seq({ 0, 1 }, { 0.22, 0.45 }, { 0.5, 0.12 }, { 1, 0.1 }))
        register(body, "BackgroundTransparency", 0.8, 0.45)

        rimGlow = newFrame(occluder, rgb(255, 105, 20))
        rimGlow.Size = UDim2.fromScale(0.36, 1)
        gradient(rimGlow, 0, nil, seq({ 0, 1 }, { 0.5, 0.2 }, { 1, 1 }))
        register(rimGlow, "BackgroundTransparency", 0.72, 0.45)

        ------------------------------------------------------------
        -- 4. Rig matahari (ikut posisi matahari di layar)
        ------------------------------------------------------------
        rig = newFrame(gui)

        -- Halo oranye besar lalu halo kuning
        softStack(rig, 0.5, 0.5, 2.6, 2.6, 0, rgb(225, 85, 15), rgb(255, 170, 40), 18, 0.78, 0, 1, 1.5)
        softStack(rig, 0.5, 0.5, 1.15, 1.15, 0, rgb(255, 160, 35), rgb(255, 225, 120), 14, 0.85, 0, 1, 1.5)

        -- Langit putih menyilaukan di sekitar matahari
        softStack(rig, 0.5, 0.5, 1.0, 1.0, 0, rgb(255, 235, 170), rgb(255, 255, 245), 10, 0.55, 0.2, 1, 1.5)

        -- Sinar bintang (mutlak, tidak ikut miring balok)
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

        -- Balok cahaya miring "\" + inti putih
        beam = newFrame(rig)
        beam.Size = UDim2.fromScale(1, 1)

        column(beam, 0.40, 2.8, rgb(255, 125, 15), rgb(255, 215, 80), 12, 0.9, 0.05)
        column(beam, 0.14, 2.2, rgb(255, 200, 60), rgb(255, 245, 190), 8, 0.85, 0.05)
        column(beam, 0.012, 2.5, rgb(255, 250, 230), rgb(255, 255, 250), 4, 0.7, 0.1)

        softStack(beam, 0.5, 0.5, 0.20, 0.52, 0, rgb(255, 215, 90), rgb(255, 255, 248), 9, 0.99, 0, 1, 1.2)

        -- Serpihan tak beraturan di tepi inti (foto 3)
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

        ------------------------------------------------------------
        -- 5. Ghost kecil + bokeh (sejajar garis matahari -> tengah layar)
        ------------------------------------------------------------
        local axisSpots = {
            -- ghost kecil (foto 3)
            { D = 0.19, Off = 0.000, Size = 0.065, Color = rgb(255, 214, 70), Op = 0.62, Rim = rgb(255, 242, 160), RimOp = 0.85, Gate = 0.2 },
            { D = 0.24, Off = 0.015, Size = 0.018, Color = rgb(200, 140, 210), Op = 0.45, Gate = 0.25 },
            { D = 0.37, Off = -0.005, Size = 0.050, Color = rgb(255, 150, 30), Op = 0.50, Gate = 0.25 },
            { D = 0.53, Off = 0.030, Size = 0.060, Color = rgb(235, 60, 20), Op = 0.60, Gate = 0.3 },
            -- bokeh oranye lonjong (foto 1)
            { D = 0.30, Off = -0.12, Size = 0.060, Asp = 2.0, Rot = 12, Color = rgb(255, 190, 50), Op = 0.35, Gate = 0.4 },
            { D = 0.36, Off = -0.02, Size = 0.080, Asp = 1.6, Rot = 10, Color = rgb(255, 185, 40), Op = 0.45, Gate = 0.4 },
            { D = 0.42, Off = 0.06, Size = 0.110, Asp = 1.4, Rot = 8, Color = rgb(255, 200, 60), Op = 0.40, Gate = 0.45 },
            { D = 0.50, Off = -0.10, Size = 0.090, Color = rgb(255, 170, 40), Op = 0.50, Gate = 0.45 },
            { D = 0.55, Off = 0.12, Size = 0.045, Color = rgb(255, 200, 60), Op = 0.50, Gate = 0.45 },
            -- bokeh merah bawah (foto 2)
            { D = 0.62, Off = -0.16, Size = 0.070, Color = rgb(240, 50, 20), Op = 0.70, Rim = rgb(255, 110, 60), RimOp = 0.5, Gate = 0.5 },
            { D = 0.60, Off = 0.05, Size = 0.065, Color = rgb(240, 45, 20), Op = 0.70, Rim = rgb(255, 110, 60), RimOp = 0.5, Gate = 0.5 },
            { D = 0.66, Off = -0.04, Size = 0.030, Color = rgb(240, 60, 25), Op = 0.65, Gate = 0.5 },
            { D = 0.74, Off = 0.22, Size = 0.050, Color = rgb(235, 60, 25), Op = 0.60, Gate = 0.5 },
        }
        for _, def in ipairs(axisSpots) do
            def.Mode = "axis"
            addSpot(def)
        end

        -- Bokeh di pinggir bayangan gelap (foto 1 & 2): X dalam pecahan layar (sisi kanan)
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

        ------------------------------------------------------------
        -- 6. Vignette gelap di empat tepi (paling atas)
        ------------------------------------------------------------
        local vignette = {
            { pos = UDim2.fromScale(0, 0), anchor = Vector2.new(0, 0), size = UDim2.fromScale(1, 0.28), rot = 90, a = 0, b = 1 },
            { pos = UDim2.fromScale(0, 1), anchor = Vector2.new(0, 1), size = UDim2.fromScale(1, 0.34), rot = 90, a = 1, b = 0 },
            { pos = UDim2.fromScale(0, 0), anchor = Vector2.new(0, 0), size = UDim2.fromScale(0.22, 1), rot = 0, a = 0, b = 1 },
            { pos = UDim2.fromScale(1, 0), anchor = Vector2.new(1, 0), size = UDim2.fromScale(0.22, 1), rot = 0, a = 1, b = 0 },
        }
        for _, v in ipairs(vignette) do
            local f = newFrame(gui, rgb(35, 12, 2))
            f.AnchorPoint = v.anchor
            f.Position = v.pos
            f.Size = v.size
            gradient(f, v.rot, nil, seq({ 0, v.a }, { 1, v.b }))
            register(f, "BackgroundTransparency", 0.55, 0.05)
        end

        ------------------------------------------------------------
        -- 7. Blur lembut (kamera sedikit tidak fokus saat silau)
        ------------------------------------------------------------
        blur = Instance.new("BlurEffect")
        blur.Name = "VR_BlurLensa"
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

        local sunDir = Lighting:GetSunDirection()
        local cf = cam.CFrame
        local camPos = cf.Position

        local target = 0
        local flare = mood.Flare or 0
        local screenPoint = cam:WorldToViewportPoint(camPos + sunDir * 1000)
        local elevation = clamp01((sunDir.Y + 0.05) / 0.12)

        if flare > 0 and elevation > 0 and screenPoint.Z > 0 then
            local aim = clamp01((cf.LookVector:Dot(sunDir) - 0.55) / 0.4)
            aim = aim * aim * (3 - 2 * aim)

            local list = { WorldFolder }
            if Player.Character then
                table.insert(list, Player.Character)
            end
            rayParams.FilterDescendantsInstances = list

            -- Daun/pohon menutup sebagian matahari: cahaya tetap tembus sebagian
            local offsets = {
                Vector3.zero, cf.RightVector * 0.05, -cf.RightVector * 0.05,
                cf.UpVector * 0.05, -cf.UpVector * 0.05,
            }
            local open = 0
            for _, offset in ipairs(offsets) do
                if not Workspace:Raycast(camPos, (sunDir + offset).Unit * 3000, rayParams) then
                    open += 1
                end
            end

            target = aim * (0.3 + 0.7 * open / #offsets) * elevation * flare
        end

        level = lerp(level, target, math.min(1, dt * 5))
        local s = clamp01(level * LENS_INTENSITY * (0.75 + 0.25 * State.Scale))

        if s <= 0.005 then
            gui.Enabled = false
            blur.Size = 0
            return
        end

        gui.Enabled = true
        blur.Size = 6 * s

        local size = cam.ViewportSize
        local W, H = size.X, size.Y
        local center = size / 2
        local sunPos = Vector2.new(screenPoint.X, screenPoint.Y)
        local now = os.clock()

        -- Rig matahari + kemiringan balok
        rig.Position = UDim2.fromOffset(sunPos.X, sunPos.Y)
        rig.Size = UDim2.fromOffset(H, H)
        beam.Rotation = TILT + math.sin(now * 0.5) * 1.2

        -- Ghost kiri/kanan bergeser berlawanan arah matahari (seperti ghost lensa asli)
        local shift = (center - sunPos) * 0.45
        ghostL.Position = UDim2.fromOffset(center.X + shift.X - W * 0.33, center.Y + shift.Y - H * 0.26)
        ghostL.Size = UDim2.fromOffset(W * 0.36, H * 0.19)
        ghostR.Position = UDim2.fromOffset(center.X + shift.X + W * 0.38, center.Y + shift.Y - H * 0.15)
        ghostR.Size = UDim2.fromOffset(W * 0.24, H * 0.33)

        -- Bayangan gelap di sisi berlawanan dari matahari (dengan histeresis)
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

        -- Bokeh & ghost kecil
        local axis = center - sunPos
        local dir = axis.Magnitude > H * 0.05 and axis.Unit or Vector2.new(-0.5, 0.86).Unit
        local perp = Vector2.new(-dir.Y, dir.X)

        for _, sp in ipairs(spots) do
            local sway = Vector2.new(math.sin(now * 0.55 + sp.Seed), math.cos(now * 0.45 + sp.Seed * 1.3)) * H * 0.006
            local p

            if sp.Mode == "axis" then
                p = sunPos + dir * H * sp.D + perp * H * sp.Off + sway
            else
                local x = side == 1 and sp.X or (1 - sp.X)
                p = Vector2.new(W * x, H * sp.Y) + sway
            end

            local d = H * sp.Size
            sp.F.Position = UDim2.fromOffset(p.X, p.Y)
            sp.F.Size = UDim2.fromOffset(d, d * (sp.Asp or 1))
            sp.F.Rotation = sp.Rot or 0
        end

        -- Fade tiap lapisan menurut kekuatan & batas kemunculannya
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

----------------------------------------------------------------
-- SKY: sembunyikan piringan matahari untuk suasana HideSun
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
    if not mood.HideSun then
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
            sky.Name = "VR_Sky"
            sky.Parent = Lighting
            SkyState.Object = sky
            SkyState.Owned = true
        end
    end

    setProperty(SkyState.Object, "SunAngularSize", 0)
end

local function applyMood(name)
    local mood = MoodByName[name]
    if not mood then
        return false
    end

    State.MoodName = name
    State.Mood = mood

    configureLightingBase()
    configureMoodLighting(mood)
    applySky(mood)

    World.SetMood(mood)
    setTerrainWet(mood.Wet == true)

    task.spawn(styleParts, mood)

    return true
end

local function applyQuality(level)
    level = math.clamp(math.floor(level or 8), 1, 10)

    State.Quality = level
    State.Scale = qualityScale(level)

    -- Bangun ulang lensa agar jumlah lapisan mengikuti kualitas
    SunLens.Destroy()

    applyMood(State.MoodName)
    task.spawn(scanAccentLights)
end

----------------------------------------------------------------
-- API PUBLIK
----------------------------------------------------------------

local API = {}

function API.SetQuality(level)
    applyQuality(level)
end

function API.GetQuality()
    return State.Quality
end

function API.SetMood(name)
    return applyMood(name)
end

function API.GetMood()
    return State.MoodName
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
        if record.Light then
            record.Light:Destroy()
        end
    end
    table.clear(Eggs.Records)

    restoreSky()
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
end

API.Restore = restoreOriginal

----------------------------------------------------------------
-- PANEL SEDERHANA
----------------------------------------------------------------

local function createUI()
    if not Settings.ShowPanel then
        return
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = ROOT_NAME
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = PlayerGui

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.fromOffset(340, 440)
    panel.Position = UDim2.new(0, 16, 0.5, -220)
    panel.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
    panel.BackgroundTransparency = 0.05
    panel.BorderSizePixel = 0
    panel.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = panel

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(95, 105, 125)
    stroke.Transparency = 0.55
    stroke.Parent = panel

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, -60, 0, 34)
    title.Position = UDim2.fromOffset(15, 10)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 17
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = Color3.fromRGB(245, 248, 255)
    title.Text = "VISUAL REALISTIS"
    title.Parent = panel

    local content = Instance.new("Frame")
    content.BackgroundTransparency = 1
    content.Size = UDim2.new(1, 0, 1, -48)
    content.Position = UDim2.fromOffset(0, 48)
    content.Parent = panel

    local collapse = Instance.new("TextButton")
    collapse.Size = UDim2.fromOffset(30, 26)
    collapse.Position = UDim2.new(1, -42, 0, 14)
    collapse.BackgroundColor3 = Color3.fromRGB(31, 35, 43)
    collapse.BorderSizePixel = 0
    collapse.Font = Enum.Font.GothamBold
    collapse.TextSize = 16
    collapse.TextColor3 = Color3.fromRGB(200, 208, 225)
    collapse.Text = "-"
    collapse.Parent = panel

    local collapseCorner = Instance.new("UICorner")
    collapseCorner.CornerRadius = UDim.new(0, 7)
    collapseCorner.Parent = collapse

    local collapsed = false
    collapse.MouseButton1Click:Connect(function()
        collapsed = not collapsed
        content.Visible = not collapsed
        panel.Size = collapsed and UDim2.fromOffset(340, 48) or UDim2.fromOffset(340, 440)
        collapse.Text = collapsed and "+" or "-"
    end)

    local qualityTitle = Instance.new("TextLabel")
    qualityTitle.BackgroundTransparency = 1
    qualityTitle.Size = UDim2.new(1, -30, 0, 20)
    qualityTitle.Position = UDim2.fromOffset(15, 0)
    qualityTitle.Font = Enum.Font.GothamBold
    qualityTitle.TextSize = 12
    qualityTitle.TextXAlignment = Enum.TextXAlignment.Left
    qualityTitle.TextColor3 = Color3.fromRGB(210, 218, 232)
    qualityTitle.Text = "KUALITAS (1-10)"
    qualityTitle.Parent = content

    local qualityHolder = Instance.new("Frame")
    qualityHolder.BackgroundTransparency = 1
    qualityHolder.Size = UDim2.new(1, -30, 0, 70)
    qualityHolder.Position = UDim2.fromOffset(15, 24)
    qualityHolder.Parent = content

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.fromOffset(56, 30)
    grid.CellPadding = UDim2.fromOffset(6, 6)
    grid.FillDirectionMaxCells = 5
    grid.Parent = qualityHolder

    local qualityButtons = {}

    local function refreshQuality()
        for level, button in pairs(qualityButtons) do
            if level == State.Quality then
                button.BackgroundColor3 = Color3.fromRGB(90, 125, 190)
                button.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                button.BackgroundColor3 = Color3.fromRGB(31, 35, 43)
                button.TextColor3 = Color3.fromRGB(180, 188, 205)
            end
        end
    end

    for level = 1, 10 do
        local button = Instance.new("TextButton")
        button.BackgroundColor3 = Color3.fromRGB(31, 35, 43)
        button.BorderSizePixel = 0
        button.Font = Enum.Font.GothamBold
        button.TextSize = 12
        button.Text = tostring(level)
        button.Parent = qualityHolder

        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0, 7)
        bc.Parent = button

        button.MouseButton1Click:Connect(function()
            applyQuality(level)
            refreshQuality()
        end)

        qualityButtons[level] = button
    end

    refreshQuality()

    local moodTitle = Instance.new("TextLabel")
    moodTitle.BackgroundTransparency = 1
    moodTitle.Size = UDim2.new(1, -30, 0, 20)
    moodTitle.Position = UDim2.fromOffset(15, 104)
    moodTitle.Font = Enum.Font.GothamBold
    moodTitle.TextSize = 12
    moodTitle.TextXAlignment = Enum.TextXAlignment.Left
    moodTitle.TextColor3 = Color3.fromRGB(210, 218, 232)
    moodTitle.Text = "SUASANA"
    moodTitle.Parent = content

    local scroll = Instance.new("ScrollingFrame")
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.Size = UDim2.new(1, -30, 0, 215)
    scroll.Position = UDim2.fromOffset(15, 128)
    scroll.ScrollBarThickness = 3
    scroll.CanvasSize = UDim2.fromOffset(0, 0)
    scroll.Parent = content

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 5)
    list.Parent = scroll

    local moodButtons = {}

    local function refreshMoods()
        for name, button in pairs(moodButtons) do
            if name == State.MoodName then
                button.BackgroundColor3 = Color3.fromRGB(68, 80, 108)
                button.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                button.BackgroundColor3 = Color3.fromRGB(25, 29, 36)
                button.TextColor3 = Color3.fromRGB(178, 186, 201)
            end
        end
    end

    for index, mood in ipairs(Moods) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -5, 0, 28)
        button.LayoutOrder = index
        button.BackgroundColor3 = Color3.fromRGB(25, 29, 36)
        button.BorderSizePixel = 0
        button.Font = Enum.Font.GothamMedium
        button.TextSize = 12
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.Text = "   " .. mood.Name
        button.Parent = scroll

        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0, 6)
        bc.Parent = button

        button.MouseButton1Click:Connect(function()
            applyMood(mood.Name)
            refreshMoods()
        end)

        moodButtons[mood.Name] = button
    end

    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.fromOffset(0, list.AbsoluteContentSize.Y + 10)
    end)

    refreshMoods()

    local status = Instance.new("TextLabel")
    status.BackgroundTransparency = 1
    status.Size = UDim2.new(1, -30, 0, 22)
    status.Position = UDim2.new(0, 15, 1, -30)
    status.Font = Enum.Font.GothamMedium
    status.TextSize = 10
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextColor3 = Color3.fromRGB(135, 145, 164)
    status.Parent = content

    task.spawn(function()
        while gui.Parent do
            status.Text = string.format(
                "%s | Part %d | Egg %d | FPS %d",
                State.MoodName,
                State.Stats.Parts,
                State.Stats.Eggs,
                State.Stats.FPS
            )
            task.wait(1)
        end
    end)

    -- Geser panel lewat judul
    local dragging = false
    local dragStart, startPosition

    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = panel.Position
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

        local delta = input.Position - dragStart
        panel.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
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
    if not ScanDone or State.Restored or not object:IsA("BasePart") then
        return
    end

    task.defer(function()
        if processPart(object) and State.Mood then
            stylePart(object, State.Mood)
        end
    end)
end))

----------------------------------------------------------------
-- MULAI
----------------------------------------------------------------

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
-- CARA PAKAI (dari console / script lain)
----------------------------------------------------------------
--   _G.VisualRealistis.SetMood("Sore Keemasan")
--   _G.VisualRealistis.SetMood("Hujan")
--   _G.VisualRealistis.SetMood("Malam Bulan")
--   _G.VisualRealistis.SetQuality(10)
--   _G.VisualRealistis.Refresh()
--   _G.VisualRealistis.Restore()
----------------------------------------------------------------
