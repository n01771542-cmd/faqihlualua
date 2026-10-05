--[[
    VISUAL REALISTIS
    Roblox LocalScript
    Letakkan di: StarterPlayer > StarterPlayerScripts

    FITUR
    -----
    1. Suasana (cahaya + atmosfer + warna) yang mudah dipilih
    2. Sore Keemasan: sun rays / god rays 3D di dalam map, glow matahari 3D,
       pantulan cahaya di permukaan, ambient hangat, bayangan lembut
    3. Hujan: partikel hujan, tanah becek, genangan air
    4. Malam: setiap "egg" diberi cahaya hangat yang halus
    5. Kualitas 1-10

    CATATAN TEKNIS
    --------------
    - LocalScript tidak bisa membuat shader GPU custom. Skrip ini memakai
      pipeline asli Roblox (Realistic lighting, Atmosphere, Bloom, SunRays,
      ColorCorrection) + objek 3D lokal (Beam, BillboardGui, ParticleEmitter).
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
--   Flare      = kekuatan lens flare layar (0 - 1, tipis)
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
        ClockTime = 17.3, Brightness = 2.30, Exposure = 0.0, ShadowSoftness = 0.12,
        Density = 0.32, Offset = 0.10, Haze = 1.5, Glare = 0.8,
        Color = Color3.fromRGB(255, 205, 155), Decay = Color3.fromRGB(235, 140, 85),
        Ambient = Color3.fromRGB(60, 46, 40), OutdoorAmbient = Color3.fromRGB(125, 103, 92),
        Top = Color3.fromRGB(255, 196, 130), Bottom = Color3.fromRGB(185, 150, 130),
        Bloom = 0.26, BloomSize = 22, BloomThreshold = 1.0,
        SunRays = 0.30, SunRaySpread = 0.85,
        Contrast = 0.10, Saturation = 0.06, Tint = Color3.fromRGB(255, 240, 222),
        ShaftColor = Color3.fromRGB(255, 205, 140),
        Shafts = 1.0, SunGlow = 1.0, Flare = 0.55, Sheen = 0.08,
        WarmBody = true,
        CloudColor = Color3.fromRGB(255, 185, 140), CloudCover = 0.45, CloudDensity = 0.5,
        EggGlow = 0.0,
        Drift = {
            Minutes = 14,
            Clock0 = 17.05, Clock1 = 17.85,
            Bright0 = 2.40, Bright1 = 1.95,
            Exp0 = 0.02, Exp1 = -0.05,
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
        Shafts = 0.8, SunGlow = 1.0, Flare = 0.5, Sheen = 0.07,
        CloudColor = Color3.fromRGB(240, 130, 110), CloudCover = 0.5, CloudDensity = 0.5,
        EggGlow = 0.35,
    },

    {
        Name = "Hujan",
        ClockTime = 14.5, Brightness = 1.5, Exposure = -0.04, ShadowSoftness = 0.35,
        Density = 0.50, Offset = 0.02, Haze = 2.4, Glare = 0.0,
        Color = Color3.fromRGB(170, 185, 205), Decay = Color3.fromRGB(110, 125, 150),
        Ambient = Color3.fromRGB(38, 43, 52), OutdoorAmbient = Color3.fromRGB(95, 108, 128),
        Top = Color3.fromRGB(200, 210, 225), Bottom = Color3.fromRGB(130, 140, 155),
        Bloom = 0.04, BloomSize = 20, BloomThreshold = 1.3,
        SunRays = 0.0, SunRaySpread = 0.8,
        Contrast = 0.10, Saturation = -0.04, Tint = Color3.fromRGB(225, 235, 248),
        Rain = true, Wet = true, Sheen = 0.0,
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

        local flatLarge = up > 0.9 and size.Y <= 4 and area >= 300
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
        add = math.max(add, 0.32)
    end

    local originalReflectance = original.Reflectance or 0
    setProperty(part, "Reflectance", math.clamp(math.max(originalReflectance, add), 0, 0.6))

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
-- DUNIA 3D: sun rays, glow matahari, lens flare, hujan, genangan
----------------------------------------------------------------

local World = {}

do
    local SUN_DISTANCE = 1800       -- jarak glow matahari dari kamera
    local MAX_SHAFTS = 36
    local MAX_PUDDLES = 45
    local RAIN_TEXTURE = ""         -- opsional: asset id tekstur garis hujan
    local RAIN_SOUND_ID = ""        -- opsional: asset id suara hujan
    local RAIN_SOUND_VOLUME = 0.5

    local rng = Random.new(1987)

    local anchor, sunPart, sunGui, sunStreak
    local flareGui
    local sunLayers = {}
    local ghosts = {}
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
        { size = 1.00, alpha = 0.965, color = Color3.fromRGB(255, 160, 80) },
        { size = 0.62, alpha = 0.930, color = Color3.fromRGB(255, 175, 95) },
        { size = 0.36, alpha = 0.860, color = Color3.fromRGB(255, 195, 120) },
        { size = 0.18, alpha = 0.700, color = Color3.fromRGB(255, 220, 160) },
        { size = 0.08, alpha = 0.350, color = Color3.fromRGB(255, 244, 215) },
    }

    local GHOST_DEFS = {
        { pos = 0.45, size = 0.050, alpha = 0.93, color = Color3.fromRGB(255, 190, 120) },
        { pos = 0.90, size = 0.100, alpha = 0.95, color = Color3.fromRGB(255, 200, 130) },
        { pos = 1.35, size = 0.040, alpha = 0.92, color = Color3.fromRGB(255, 215, 150) },
        { pos = 1.80, size = 0.160, alpha = 0.96, color = Color3.fromRGB(255, 175, 100), ring = true },
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

        -- Lens flare tipis (hantu lensa, memang efek kamera di layar)
        flareGui = Instance.new("ScreenGui")
        flareGui.Name = ROOT_NAME .. "_Flare"
        flareGui.ResetOnSpawn = false
        flareGui.IgnoreGuiInset = true
        flareGui.DisplayOrder = 4
        flareGui.Enabled = false
        flareGui.Parent = PlayerGui

        for _, def in ipairs(GHOST_DEFS) do
            local f = Instance.new("Frame")
            f.BorderSizePixel = 0
            f.AnchorPoint = Vector2.new(0.5, 0.5)
            f.Active = false

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(1, 0)
            corner.Parent = f

            local stroke
            if def.ring then
                f.BackgroundTransparency = 1
                stroke = Instance.new("UIStroke")
                stroke.Color = def.color
                stroke.Thickness = 2
                stroke.Transparency = 1
                stroke.Parent = f
            else
                f.BackgroundColor3 = def.color
                f.BackgroundTransparency = 1
            end

            f.Parent = flareGui
            table.insert(ghosts, { Frame = f, Stroke = stroke, Def = def })
        end

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

        rainEmitter = Instance.new("ParticleEmitter")
        rainEmitter.Rate = 0
        rainEmitter.Lifetime = NumberRange.new(0.7, 0.9)
        rainEmitter.Speed = NumberRange.new(90, 110)
        rainEmitter.EmissionDirection = Enum.NormalId.Bottom
        rainEmitter.SpreadAngle = Vector2.new(2, 2)
        rainEmitter.Size = NumberSequence.new(0.6)
        rainEmitter.Squash = NumberSequence.new(-0.85)
        rainEmitter.Transparency = NumberSequence.new(0.55)
        rainEmitter.Color = ColorSequence.new(Color3.fromRGB(200, 215, 235))
        rainEmitter.LightEmission = 0.25
        rainEmitter.LightInfluence = 0.5
        rainEmitter.Acceleration = Vector3.new(6, 0, 3)
        rainEmitter.LockedToPart = false
        rainEmitter.Orientation = Enum.ParticleOrientation.VelocityParallel
        rainEmitter.Texture = RAIN_TEXTURE ~= "" and RAIN_TEXTURE or "rbxasset://textures/particles/sparkles_main.dds"
        rainEmitter.Parent = rainPart

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

    local function placePuddles(center)
        local count = math.floor(MAX_PUDDLES * State.Scale)

        for index = 1, MAX_PUDDLES do
            local puddle = puddles[index]

            if index > count then
                if puddle then
                    puddle.Parent = nil
                end
            else
                if not puddle then
                    puddle = Instance.new("Part")
                    puddle.Name = "VR_Genangan"
                    puddle.Shape = Enum.PartType.Cylinder
                    puddle.Anchored = true
                    puddle.CanCollide = false
                    puddle.CanQuery = false
                    puddle.CanTouch = false
                    puddle.CastShadow = false
                    puddle.Material = Enum.Material.SmoothPlastic
                    puddle.Color = Color3.fromRGB(28, 34, 44)
                    puddle.Reflectance = 0.7
                    puddle.Transparency = 1
                    puddles[index] = puddle
                end

                local angle = rng:NextNumber(0, math.pi * 2)
                local radius = 5 + 85 * math.sqrt(rng:NextNumber())
                local origin = center + Vector3.new(math.cos(angle) * radius, 120, math.sin(angle) * radius)
                local hit = Workspace:Raycast(origin, Vector3.new(0, -300, 0), rayParams)

                local valid = false
                if hit and hit.Normal.Y > 0.97 then
                    if hit.Instance:IsA("Terrain") then
                        valid = hit.Material ~= Enum.Material.Water
                    else
                        local info = PartInfo[hit.Instance]
                        valid = info ~= nil and info.Ground
                    end
                end

                if valid then
                    local diameter = rng:NextNumber(3, 11)
                    puddle.Size = Vector3.new(0.06, diameter, diameter)
                    puddle.CFrame = CFrame.new(hit.Position + Vector3.new(0, 0.04, 0)) * CFrame.Angles(0, 0, math.pi / 2)
                    puddle.Parent = WorldFolder
                else
                    puddle.Parent = nil
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
        local blocked = Workspace:Raycast(camPos, sunDir * 3000, rayParams) ~= nil
        local visibleTarget = (onScreen and screenPoint.Z > 0 and not blocked) and 1 or 0
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
        -- Lens flare tipis
        ------------------------------------------------------------
        local flareStrength = (mood.Flare or 0) * elevationVis * sunVis * facing ^ 1.5
        flareGui.Enabled = flareStrength > 0.01

        if flareGui.Enabled then
            local size = cam.ViewportSize
            local sunPos = Vector2.new(screenPoint.X, screenPoint.Y)
            local axis = (size / 2) - sunPos
            local base = math.min(size.X, size.Y)

            for _, ghost in ipairs(ghosts) do
                local p = sunPos + axis * ghost.Def.pos
                local d = base * ghost.Def.size
                ghost.Frame.Position = UDim2.fromOffset(p.X, p.Y)
                ghost.Frame.Size = UDim2.fromOffset(d, d)

                local alpha = 1 - (1 - ghost.Def.alpha) * flareStrength
                if ghost.Stroke then
                    ghost.Stroke.Transparency = 1 - 0.15 * flareStrength
                else
                    ghost.Frame.BackgroundTransparency = alpha
                end
            end
        end

        ------------------------------------------------------------
        -- Efek kamera: bloom / sun rays / glare naik tipis saat menghadap matahari
        ------------------------------------------------------------
        local sens = elevationVis * sunVis * sunSensitive

        local bloom = State.Instances.Bloom
        if bloom and bloom.Parent then
            bloom.Intensity = State.Base.Bloom + 0.10 * f3 * sens
        end

        local rays = State.Instances.SunRays
        if rays and rays.Parent then
            rays.Intensity = State.Base.SunRays + 0.10 * f2 * sens
        end

        local grade = State.Instances.Color
        if grade and grade.Parent then
            grade.TintColor = State.Base.Tint:Lerp(Color3.fromRGB(255, 205, 150), 0.25 * f2 * sens)
            grade.Saturation = State.Base.Saturation + 0.04 * f2 * sens
            grade.Brightness = 0.015 * f3 * sens
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

                local t = 1 - 0.88 * clamp01(rainLevel * 1.2)
                for _, puddle in ipairs(puddles) do
                    puddle.Transparency = t
                end
            elseif lastPuddlePos then
                for _, puddle in ipairs(puddles) do
                    puddle.Transparency = 1
                end
                lastPuddlePos = nil
            end
        end

        coverLevel = lerp(coverLevel, coverTarget, math.min(1, dt * 3))

        rainPart.CFrame = CFrame.new(camPos + Vector3.new(0, 42, 0))
        rainEmitter.Rate = 950 * scale * rainLevel * coverLevel

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

        if flareGui then
            flareGui:Destroy()
            flareGui = nil
        end

        for _, puddle in ipairs(puddles) do
            puddle:Destroy()
        end
        table.clear(puddles)

        table.clear(shafts)
        table.clear(sunLayers)
        table.clear(ghosts)

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

local function applyMood(name)
    local mood = MoodByName[name]
    if not mood then
        return false
    end

    State.MoodName = name
    State.Mood = mood

    configureLightingBase()
    configureMoodLighting(mood)

    World.SetMood(mood)
    setTerrainWet(mood.Wet == true)

    task.spawn(styleParts, mood)

    return true
end

local function applyQuality(level)
    level = math.clamp(math.floor(level or 8), 1, 10)

    State.Quality = level
    State.Scale = qualityScale(level)

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
