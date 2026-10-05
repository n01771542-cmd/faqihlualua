--[[
    VISUAL REALISTIS V5
    Roblox LocalScript
    Taruh di: StarterPlayer > StarterPlayerScripts
    (Hapus skrip lama "Ultra Realistic Renderer V4" supaya tidak bentrok.)

    FITUR UTAMA
    -----------
    1. Suasana  : siang, pagi, sore, malam, mendung, hujan, dll.
    2. Sore     : "Sore Nostalgia" sekarang MASUK KE DUNIA GAME
                  (cahaya, warna benda, awan, debu cahaya, cahaya di karakter),
                  bukan lagi sekadar gambar yang ditempel di layar.
    3. Kabut    : 4 tingkat (Tipis, Sedang, Tebal, Super Tebal) berupa kabut
                  atmosfer + kabut asap nyata di sekitar pemain.
    4. Cahaya Telur : setiap tempat egg (sarang, slot, egg yang ditaruh)
                  diberi cahaya halus, paling terasa di mode malam gelap.

    BATAS TEKNIS
    ------------
    - Roblox tidak mengizinkan shader GPU custom dari LocalScript.
    - Jangkauan lampu (PointLight) maksimal 60 stud, jadi "sore di dunia"
      dibuat dari: Lighting + Atmosphere + warna benda + awan + partikel
      + lampu lokal. Bukan satu lampu raksasa.
    - Skrip ini hanya visual (tanpa remote, tanpa ubah data/gerakan pemain).

    PEMAKAIAN CEPAT (Console / skrip lain)
    --------------------------------------
      _G.VisualRealistis.SetMood("Sore Nostalgia")
      _G.VisualRealistis.SetMood("Malam Gelap Cahaya Telur")
      _G.VisualRealistis.SetFog(3)        -- 0 mati, 1 tipis, 2 sedang, 3 tebal, 4 super tebal
      _G.VisualRealistis.SetEggGlow(true)
      _G.VisualRealistis.SetQuality(10)
      _G.VisualRealistis.Restore()
    Tombol RightControl = sembunyikan / tampilkan panel.
]]

----------------------------------------------------------------
-- SERVICES
----------------------------------------------------------------

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera

local ROOT_NAME = "VisualRealistis"

----------------------------------------------------------------
-- BERSIHKAN VERSI LAMA
----------------------------------------------------------------

if _G.UltraRealisticRendererV4 and _G.UltraRealisticRendererV4.Restore then
    pcall(_G.UltraRealisticRendererV4.Restore)
end
if _G.VisualRealistis and _G.VisualRealistis.Restore then
    pcall(_G.VisualRealistis.Restore)
end

for _, name in ipairs({ "UltraRealisticRendererV4", "UltraRealisticRendererV4_Nostalgia", ROOT_NAME }) do
    local old = PlayerGui:FindFirstChild(name)
    if old then
        old:Destroy()
    end
end

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

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function scaleColor(c, f)
    return Color3.new(math.clamp(c.R * f, 0, 1), math.clamp(c.G * f, 0, 1), math.clamp(c.B * f, 0, 1))
end

----------------------------------------------------------------
-- KEADAAN ASLI (untuk Restore)
----------------------------------------------------------------

local Original = {
    Lighting = {},
    Parts = {},
    SurfaceAppearances = {},
    Created = {},
}

local LIGHTING_PROPS = {
    "Brightness", "ExposureCompensation", "GlobalShadows", "ShadowSoftness",
    "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "Ambient", "OutdoorAmbient",
    "ColorShift_Top", "ColorShift_Bottom", "ClockTime",
}

for _, property in ipairs(LIGHTING_PROPS) do
    Original.Lighting[property] = getProperty(Lighting, property, nil)
end

----------------------------------------------------------------
-- KUALITAS
----------------------------------------------------------------

local QualityNames = {
    "Rendah", "Dasar", "Seimbang", "Bagus", "Tinggi",
    "Sangat Tinggi", "Ultra", "Sinematik", "Ekstrem", "Maksimal",
}

local function qualityInfo(level)
    local t = (level - 1) / 9
    return {
        Name = QualityNames[level],
        DetailDistance = lerp(250, 700, t),
        LightDistance = lerp(220, 520, t),
        MaxLights = math.floor(lerp(20, 80, t)),
        Particles = lerp(0.35, 1, t),
        BloomScale = lerp(0.6, 1, t),
    }
end

----------------------------------------------------------------
-- TINGKAT KABUT
----------------------------------------------------------------
-- Density 0-1 dan Haze 0-10 adalah batas Atmosphere Roblox.

local FogLevels = {
    [1] = { Name = "Tipis",       Density = 0.22, Haze = 2.0, Dim = 0.95, Rate = 6,  Opacity = 0.10, Cover = 0.55 },
    [2] = { Name = "Sedang",      Density = 0.38, Haze = 4.0, Dim = 0.88, Rate = 10, Opacity = 0.16, Cover = 0.70 },
    [3] = { Name = "Tebal",       Density = 0.52, Haze = 6.5, Dim = 0.80, Rate = 16, Opacity = 0.22, Cover = 0.85 },
    [4] = { Name = "Super Tebal", Density = 0.72, Haze = 9.5, Dim = 0.70, Rate = 24, Opacity = 0.30, Cover = 1.00 },
}

----------------------------------------------------------------
-- DAFTAR SUASANA
----------------------------------------------------------------

local MoodDefaults = {
    Offset = 0.10, Haze = 0.10, Glare = 0.03, ShadowSoftness = 0.20,
    Bloom = 0.06, BloomSize = 24, BloomThreshold = 1.10, SunRays = 0.03,
    Contrast = 0.08, Saturation = 0.03, Tint = Color3.new(1, 1, 1),
    GradeBrightness = 0, WorldTintAmount = 0, EggGlow = 0.30,
    EggColor = Color3.fromRGB(255, 205, 140),
    DustColor = Color3.fromRGB(255, 214, 150),
}

local function M(t)
    return setmetatable(t, { __index = MoodDefaults })
end

local Moods = {
    ["Siang Cerah"] = M({
        ClockTime = 10.2, Brightness = 2.36, Exposure = 0.04,
        Density = 0.004, Offset = 0.18, Haze = 0.08, Glare = 0.02,
        Color = Color3.fromRGB(225, 237, 255), Decay = Color3.fromRGB(200, 218, 245),
        Ambient = Color3.fromRGB(35, 38, 44), OutdoorAmbient = Color3.fromRGB(150, 160, 175),
        Top = Color3.fromRGB(205, 225, 255), Bottom = Color3.fromRGB(245, 240, 225),
        Bloom = 0.055, Contrast = 0.08, Saturation = 0.02,
    }),

    ["Pagi Segar"] = M({
        ClockTime = 7.6, Brightness = 2.42, Exposure = 0.045,
        Density = 0.004, Offset = 0.10, Haze = 0.06, Glare = 0.08,
        Color = Color3.fromRGB(210, 232, 255), Decay = Color3.fromRGB(188, 210, 240),
        Ambient = Color3.fromRGB(31, 38, 48), OutdoorAmbient = Color3.fromRGB(150, 166, 190),
        Top = Color3.fromRGB(190, 220, 255), Bottom = Color3.fromRGB(255, 238, 212),
        Bloom = 0.075, Contrast = 0.10, Saturation = 0.035,
        Tint = Color3.fromRGB(248, 252, 255),
    }),

    ["Pagi Hangat"] = M({
        ClockTime = 8.5, Brightness = 2.38, Exposure = 0.04,
        Density = 0.0045, Offset = 0.12, Haze = 0.09, Glare = 0.10,
        Color = Color3.fromRGB(226, 235, 255), Decay = Color3.fromRGB(245, 208, 165),
        Ambient = Color3.fromRGB(43, 39, 34), OutdoorAmbient = Color3.fromRGB(165, 156, 145),
        Top = Color3.fromRGB(215, 232, 255), Bottom = Color3.fromRGB(255, 225, 190),
        Bloom = 0.08, Contrast = 0.095, Saturation = 0.045,
        Tint = Color3.fromRGB(255, 249, 238),
    }),

    ["Tengah Hari"] = M({
        ClockTime = 12.1, Brightness = 2.40, Exposure = 0.035,
        Density = 0.003, Offset = 0.20, Haze = 0.05, Glare = 0.03,
        Color = Color3.fromRGB(225, 238, 255), Decay = Color3.fromRGB(215, 225, 242),
        Ambient = Color3.fromRGB(32, 34, 38), OutdoorAmbient = Color3.fromRGB(155, 160, 168),
        Top = Color3.fromRGB(218, 235, 255), Bottom = Color3.fromRGB(250, 247, 238),
        Bloom = 0.045, Contrast = 0.12, Saturation = 0.025,
    }),

    ["Sore Hangat"] = M({
        ClockTime = 15.3, Brightness = 2.33, Exposure = 0.045,
        Density = 0.0045, Offset = 0.15, Haze = 0.09, Glare = 0.05,
        Color = Color3.fromRGB(232, 238, 255), Decay = Color3.fromRGB(238, 205, 168),
        Ambient = Color3.fromRGB(43, 40, 38), OutdoorAmbient = Color3.fromRGB(164, 153, 142),
        Top = Color3.fromRGB(224, 233, 255), Bottom = Color3.fromRGB(255, 223, 190),
        Bloom = 0.07, Contrast = 0.105, Saturation = 0.05,
        Tint = Color3.fromRGB(255, 249, 240),
        WorldTint = Color3.fromRGB(255, 200, 140), WorldTintAmount = 0.06,
    }),

    ["Senja Emas"] = M({
        ClockTime = 17.25, Brightness = 2.28, Exposure = 0.03,
        Density = 0.005, Offset = 0.12, Haze = 0.13, Glare = 0.18,
        Color = Color3.fromRGB(255, 224, 190), Decay = Color3.fromRGB(220, 150, 92),
        Ambient = Color3.fromRGB(50, 38, 31), OutdoorAmbient = Color3.fromRGB(176, 139, 111),
        Top = Color3.fromRGB(255, 205, 155), Bottom = Color3.fromRGB(255, 172, 112),
        Bloom = 0.11, Contrast = 0.11, Saturation = 0.08,
        Tint = Color3.fromRGB(255, 244, 225), SunRays = 0.06,
        WorldTint = Color3.fromRGB(255, 180, 110), WorldTintAmount = 0.10,
        EggGlow = 0.45, BodyLight = true,
    }),

    -- Suasana utama: sekarang benar-benar ada di dalam dunia game.
    ["Sore Nostalgia"] = M({
        ClockTime = 17.35, Brightness = 1.85, Exposure = -0.02, ShadowSoftness = 0.10,
        Density = 0.012, Offset = 0.05, Haze = 1.2, Glare = 0.50,
        Color = Color3.fromRGB(255, 176, 100), Decay = Color3.fromRGB(232, 106, 52),
        Ambient = Color3.fromRGB(46, 30, 22), OutdoorAmbient = Color3.fromRGB(140, 100, 70),
        Top = Color3.fromRGB(255, 172, 100), Bottom = Color3.fromRGB(240, 128, 72),
        Bloom = 0.18, BloomSize = 36, BloomThreshold = 0.85, SunRays = 0.10,
        Contrast = 0.12, Saturation = 0.07,
        Tint = Color3.fromRGB(255, 222, 180), GradeBrightness = -0.025,
        WorldTint = Color3.fromRGB(255, 165, 90), WorldTintAmount = 0.16,
        EggGlow = 0.55, EggColor = Color3.fromRGB(255, 190, 110),
        DustColor = Color3.fromRGB(255, 205, 135),
        Dust = true, SunGlare = true, BodyLight = true,
        Clouds = { Color = Color3.fromRGB(255, 176, 120), Cover = 0.55, Density = 0.55 },
        DOFFar = 0.14, DOFFocus = 90, DOFRadius = 70,
        -- Matahari turun pelan, bolak-balik, seperti waktu berlalu.
        Drift = {
            Minutes = 14, Clock0 = 17.10, Clock1 = 17.95,
            Bright0 = 1.95, Bright1 = 1.50, Exp0 = 0.01, Exp1 = -0.06,
        },
    }),

    ["Matahari Terbenam"] = M({
        ClockTime = 18.05, Brightness = 2.18, Exposure = 0.015,
        Density = 0.006, Offset = 0.08, Haze = 0.18, Glare = 0.28,
        Color = Color3.fromRGB(255, 195, 166), Decay = Color3.fromRGB(198, 94, 74),
        Ambient = Color3.fromRGB(46, 31, 36), OutdoorAmbient = Color3.fromRGB(146, 106, 112),
        Top = Color3.fromRGB(255, 170, 146), Bottom = Color3.fromRGB(235, 105, 92),
        Bloom = 0.13, Contrast = 0.12, Saturation = 0.10,
        Tint = Color3.fromRGB(255, 235, 220),
        WorldTint = Color3.fromRGB(255, 140, 110), WorldTintAmount = 0.12,
        EggGlow = 0.60, BodyLight = true,
    }),

    ["Malam Biru"] = M({
        ClockTime = 19.0, Brightness = 1.88, Exposure = -0.015,
        Density = 0.006, Offset = 0.16, Haze = 0.11, Glare = 0.02,
        Color = Color3.fromRGB(150, 185, 235), Decay = Color3.fromRGB(90, 125, 185),
        Ambient = Color3.fromRGB(22, 29, 45), OutdoorAmbient = Color3.fromRGB(72, 94, 132),
        Top = Color3.fromRGB(90, 125, 190), Bottom = Color3.fromRGB(165, 160, 190),
        Bloom = 0.06, Contrast = 0.14, Saturation = 0.035,
        Tint = Color3.fromRGB(225, 235, 255), EggGlow = 0.9,
    }),

    ["Malam Bulan"] = M({
        ClockTime = 0.35, Brightness = 1.30, Exposure = -0.05,
        Density = 0.004, Offset = 0.22, Haze = 0.08, Glare = 0,
        Color = Color3.fromRGB(140, 170, 220), Decay = Color3.fromRGB(76, 92, 135),
        Ambient = Color3.fromRGB(14, 18, 30), OutdoorAmbient = Color3.fromRGB(54, 65, 92),
        Top = Color3.fromRGB(55, 75, 125), Bottom = Color3.fromRGB(80, 90, 125),
        Bloom = 0.045, Contrast = 0.16, Saturation = 0.025,
        Tint = Color3.fromRGB(210, 225, 255), EggGlow = 1.3,
    }),

    -- Mode gelap: tiap tempat egg punya cahaya halus.
    ["Malam Gelap Cahaya Telur"] = M({
        ClockTime = 0.0, Brightness = 0.55, Exposure = -0.12, ShadowSoftness = 0.30,
        Density = 0.010, Offset = 0.20, Haze = 0.8, Glare = 0,
        Color = Color3.fromRGB(60, 80, 130), Decay = Color3.fromRGB(20, 28, 56),
        Ambient = Color3.fromRGB(6, 8, 14), OutdoorAmbient = Color3.fromRGB(20, 26, 44),
        Top = Color3.fromRGB(30, 40, 80), Bottom = Color3.fromRGB(20, 22, 40),
        Bloom = 0.22, BloomSize = 40, BloomThreshold = 0.80,
        Contrast = 0.16, Saturation = 0.04, Tint = Color3.fromRGB(200, 215, 255),
        WorldTint = Color3.fromRGB(120, 150, 230), WorldTintAmount = 0.08,
        EggGlow = 2.4, EggColor = Color3.fromRGB(255, 210, 150),
    }),

    ["Mendung"] = M({
        ClockTime = 11.2, Brightness = 1.75, Exposure = -0.015,
        Density = 0.008, Offset = 0.05, Haze = 0.20, Glare = 0.01,
        Color = Color3.fromRGB(205, 214, 224), Decay = Color3.fromRGB(170, 180, 194),
        Ambient = Color3.fromRGB(48, 50, 54), OutdoorAmbient = Color3.fromRGB(112, 118, 126),
        Top = Color3.fromRGB(188, 198, 210), Bottom = Color3.fromRGB(198, 202, 204),
        Bloom = 0.025, Contrast = 0.055, Saturation = -0.025,
        Tint = Color3.fromRGB(238, 241, 244), EggGlow = 0.5,
    }),

    ["Hujan"] = M({
        ClockTime = 15.8, Brightness = 1.62, Exposure = -0.02,
        Density = 0.010, Offset = 0.02, Haze = 0.24, Glare = 0.01,
        Color = Color3.fromRGB(174, 194, 218), Decay = Color3.fromRGB(112, 132, 164),
        Ambient = Color3.fromRGB(35, 41, 51), OutdoorAmbient = Color3.fromRGB(90, 105, 125),
        Top = Color3.fromRGB(130, 155, 188), Bottom = Color3.fromRGB(150, 160, 175),
        Bloom = 0.02, Contrast = 0.10, Saturation = -0.02,
        Tint = Color3.fromRGB(225, 235, 250), EggGlow = 0.6,
    }),

    ["Kabut Tebal"] = M({
        ClockTime = 8.2, Brightness = 1.98, Exposure = 0,
        Density = 0.014, Offset = 0.01, Haze = 0.36, Glare = 0.08,
        Color = Color3.fromRGB(215, 225, 236), Decay = Color3.fromRGB(165, 180, 205),
        Ambient = Color3.fromRGB(47, 50, 54), OutdoorAmbient = Color3.fromRGB(120, 128, 140),
        Top = Color3.fromRGB(185, 205, 228), Bottom = Color3.fromRGB(205, 207, 210),
        Bloom = 0.045, Contrast = 0.035, Saturation = -0.01,
        Tint = Color3.fromRGB(245, 248, 252), Fog = 3, EggGlow = 0.7,
    }),

    ["Kabut Super Tebal"] = M({
        ClockTime = 7.0, Brightness = 1.80, Exposure = -0.02,
        Density = 0.014, Offset = 0.0, Haze = 0.36, Glare = 0.04,
        Color = Color3.fromRGB(210, 220, 232), Decay = Color3.fromRGB(160, 175, 200),
        Ambient = Color3.fromRGB(44, 47, 52), OutdoorAmbient = Color3.fromRGB(115, 124, 138),
        Top = Color3.fromRGB(180, 200, 224), Bottom = Color3.fromRGB(200, 204, 208),
        Bloom = 0.06, Contrast = 0.03, Saturation = -0.02,
        Tint = Color3.fromRGB(240, 245, 250), Fog = 4, EggGlow = 0.9,
    }),

    ["Pantai Tropis"] = M({
        ClockTime = 10.6, Brightness = 2.34, Exposure = 0.035,
        Density = 0.005, Offset = 0.14, Haze = 0.10, Glare = 0.06,
        Color = Color3.fromRGB(190, 225, 225), Decay = Color3.fromRGB(116, 185, 170),
        Ambient = Color3.fromRGB(27, 43, 37), OutdoorAmbient = Color3.fromRGB(125, 158, 143),
        Top = Color3.fromRGB(175, 225, 238), Bottom = Color3.fromRGB(218, 242, 206),
        Bloom = 0.065, Contrast = 0.09, Saturation = 0.08,
        Tint = Color3.fromRGB(244, 255, 245),
    }),

    ["Hutan Hijau"] = M({
        ClockTime = 9.3, Brightness = 2.18, Exposure = 0.015,
        Density = 0.007, Offset = 0.10, Haze = 0.17, Glare = 0.04,
        Color = Color3.fromRGB(185, 215, 190), Decay = Color3.fromRGB(105, 155, 115),
        Ambient = Color3.fromRGB(24, 38, 27), OutdoorAmbient = Color3.fromRGB(90, 125, 96),
        Top = Color3.fromRGB(160, 205, 175), Bottom = Color3.fromRGB(205, 225, 185),
        Bloom = 0.04, Contrast = 0.10, Saturation = 0.07,
        Tint = Color3.fromRGB(238, 250, 236),
    }),

    ["Gurun Pasir"] = M({
        ClockTime = 15.5, Brightness = 2.30, Exposure = 0.04,
        Density = 0.005, Offset = 0.16, Haze = 0.13, Glare = 0.09,
        Color = Color3.fromRGB(238, 220, 188), Decay = Color3.fromRGB(202, 166, 113),
        Ambient = Color3.fromRGB(52, 43, 32), OutdoorAmbient = Color3.fromRGB(167, 145, 115),
        Top = Color3.fromRGB(235, 215, 180), Bottom = Color3.fromRGB(255, 213, 158),
        Bloom = 0.065, Contrast = 0.10, Saturation = 0.065,
        Tint = Color3.fromRGB(255, 248, 232),
    }),

    ["Salju Dingin"] = M({
        ClockTime = 12.0, Brightness = 2.42, Exposure = 0.04,
        Density = 0.004, Offset = 0.18, Haze = 0.07, Glare = 0.03,
        Color = Color3.fromRGB(202, 230, 255), Decay = Color3.fromRGB(135, 185, 235),
        Ambient = Color3.fromRGB(27, 37, 49), OutdoorAmbient = Color3.fromRGB(122, 150, 180),
        Top = Color3.fromRGB(190, 225, 255), Bottom = Color3.fromRGB(225, 240, 255),
        Bloom = 0.055, Contrast = 0.10, Saturation = 0.02,
        Tint = Color3.fromRGB(236, 248, 255),
    }),

    ["Malam Mistis"] = M({
        ClockTime = 20.2, Brightness = 1.55, Exposure = -0.02,
        Density = 0.006, Offset = 0.16, Haze = 0.12, Glare = 0.05,
        Color = Color3.fromRGB(175, 160, 225), Decay = Color3.fromRGB(90, 70, 160),
        Ambient = Color3.fromRGB(29, 23, 48), OutdoorAmbient = Color3.fromRGB(76, 65, 118),
        Top = Color3.fromRGB(90, 78, 160), Bottom = Color3.fromRGB(140, 100, 180),
        Bloom = 0.085, Contrast = 0.13, Saturation = 0.055,
        Tint = Color3.fromRGB(240, 230, 255), EggGlow = 1.0,
        EggColor = Color3.fromRGB(215, 185, 255),
    }),

    ["Kota Neon"] = M({
        ClockTime = 22.1, Brightness = 1.15, Exposure = -0.025,
        Density = 0.004, Offset = 0.20, Haze = 0.07, Glare = 0.02,
        Color = Color3.fromRGB(110, 165, 220), Decay = Color3.fromRGB(70, 75, 150),
        Ambient = Color3.fromRGB(12, 17, 28), OutdoorAmbient = Color3.fromRGB(42, 54, 84),
        Top = Color3.fromRGB(35, 55, 105), Bottom = Color3.fromRGB(62, 65, 112),
        Bloom = 0.15, Contrast = 0.18, Saturation = 0.09,
        Tint = Color3.fromRGB(225, 235, 255), EggGlow = 1.4,
    }),

    ["Gunung Api"] = M({
        ClockTime = 19.4, Brightness = 1.70, Exposure = 0,
        Density = 0.009, Offset = 0.06, Haze = 0.24, Glare = 0.11,
        Color = Color3.fromRGB(235, 150, 120), Decay = Color3.fromRGB(150, 52, 38),
        Ambient = Color3.fromRGB(42, 20, 18), OutdoorAmbient = Color3.fromRGB(110, 53, 45),
        Top = Color3.fromRGB(125, 57, 48), Bottom = Color3.fromRGB(205, 78, 44),
        Bloom = 0.12, Contrast = 0.16, Saturation = 0.10,
        Tint = Color3.fromRGB(255, 235, 220),
        WorldTint = Color3.fromRGB(255, 120, 70), WorldTintAmount = 0.10,
        EggGlow = 0.9, EggColor = Color3.fromRGB(255, 170, 100),
    }),

    ["Dunia Mimpi"] = M({
        ClockTime = 16.8, Brightness = 2.16, Exposure = 0.02,
        Density = 0.007, Offset = 0.10, Haze = 0.15, Glare = 0.10,
        Color = Color3.fromRGB(220, 205, 240), Decay = Color3.fromRGB(190, 150, 215),
        Ambient = Color3.fromRGB(42, 33, 50), OutdoorAmbient = Color3.fromRGB(135, 112, 150),
        Top = Color3.fromRGB(210, 190, 245), Bottom = Color3.fromRGB(255, 190, 205),
        Bloom = 0.10, Contrast = 0.08, Saturation = 0.075,
        Tint = Color3.fromRGB(255, 242, 250),
        WorldTint = Color3.fromRGB(230, 170, 235), WorldTintAmount = 0.08,
        EggGlow = 0.8, EggColor = Color3.fromRGB(255, 190, 235),
    }),
}

local MoodOrder = {
    "Siang Cerah", "Pagi Segar", "Pagi Hangat", "Tengah Hari",
    "Sore Hangat", "Senja Emas", "Sore Nostalgia", "Matahari Terbenam",
    "Malam Biru", "Malam Bulan", "Malam Gelap Cahaya Telur",
    "Mendung", "Hujan", "Kabut Tebal", "Kabut Super Tebal",
    "Pantai Tropis", "Hutan Hijau", "Gurun Pasir", "Salju Dingin",
    "Malam Mistis", "Kota Neon", "Gunung Api", "Dunia Mimpi",
}

----------------------------------------------------------------
-- STATE
----------------------------------------------------------------

local State = {
    Quality = 10,
    MoodName = "Sore Nostalgia",
    FogLevel = 0,
    EggGlowEnabled = true,
    Restored = false,
    Instances = {},
    AccentLights = {},
    Connections = {},
    TintVersion = 0,
    Stats = { Parts = 0, SurfaceAppearances = 0, LightsFound = 0, LightsCreated = 0, Eggs = 0 },
}

local function currentMood()
    return Moods[State.MoodName] or Moods["Siang Cerah"]
end

local function currentFog()
    return FogLevels[State.FogLevel]
end

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

local function fogColorFor(mood)
    local f = math.clamp(mood.Brightness / 2.3, 0.3, 1)
    local c = mood.Color:Lerp(Color3.fromRGB(215, 220, 228), 0.5)
    return scaleColor(c, f)
end

local function baseBrightness(mood)
    local fog = currentFog()
    return mood.Brightness * (fog and fog.Dim or 1)
end

----------------------------------------------------------------
-- LIGHTING DASAR
----------------------------------------------------------------

local function configureLightingBase()
    safe(function()
        Lighting.LightingStyle = Enum.LightingStyle.Realistic
    end)
    setProperty(Lighting, "GlobalShadows", true)
    setProperty(Lighting, "EnvironmentDiffuseScale", 1)
    setProperty(Lighting, "EnvironmentSpecularScale", 1)
    setProperty(Lighting, "PrioritizeLightingQuality", true)
end

----------------------------------------------------------------
-- ATMOSFER + KABUT ATMOSFER
----------------------------------------------------------------

local function configureAtmosphere()
    local mood = currentMood()
    local fog = currentFog()

    local atmosphere = State.Instances.Atmosphere or createEffect("Atmosphere", "VR_Atmosphere")
    State.Instances.Atmosphere = atmosphere

    if fog then
        local fogColor = fogColorFor(mood)
        setProperty(atmosphere, "Density", fog.Density)
        setProperty(atmosphere, "Offset", 0)
        setProperty(atmosphere, "Haze", fog.Haze)
        setProperty(atmosphere, "Glare", mood.Glare * 0.3)
        setProperty(atmosphere, "Color", fogColor)
        setProperty(atmosphere, "Decay", scaleColor(mood.Decay:Lerp(fogColor, 0.6), 0.9))
    else
        setProperty(atmosphere, "Density", mood.Density)
        setProperty(atmosphere, "Offset", mood.Offset)
        setProperty(atmosphere, "Haze", mood.Haze)
        setProperty(atmosphere, "Glare", mood.Glare)
        setProperty(atmosphere, "Color", mood.Color)
        setProperty(atmosphere, "Decay", mood.Decay)
    end

    setProperty(atmosphere, "Enabled", true)
end

----------------------------------------------------------------
-- POST-PROCESSING
----------------------------------------------------------------

local function configurePostEffects()
    local mood = currentMood()
    local fog = currentFog()
    local q = qualityInfo(State.Quality)

    local bloom = State.Instances.Bloom or createEffect("BloomEffect", "VR_Bloom")
    State.Instances.Bloom = bloom
    setProperty(bloom, "Intensity", (mood.Bloom + (fog and 0.03 or 0)) * q.BloomScale)
    setProperty(bloom, "Size", mood.BloomSize)
    setProperty(bloom, "Threshold", mood.BloomThreshold)
    setProperty(bloom, "Enabled", true)

    local grade = State.Instances.Grade or createEffect("ColorCorrectionEffect", "VR_ColorGrade")
    State.Instances.Grade = grade
    setProperty(grade, "Brightness", mood.GradeBrightness)
    setProperty(grade, "Contrast", fog and mood.Contrast * 0.6 or mood.Contrast)
    setProperty(grade, "Saturation", fog and mood.Saturation - 0.03 or mood.Saturation)
    setProperty(grade, "TintColor", mood.Tint)
    setProperty(grade, "Enabled", true)

    local sun = State.Instances.SunRays or createEffect("SunRaysEffect", "VR_SunRays")
    State.Instances.SunRays = sun
    setProperty(sun, "Intensity", mood.SunRays * (fog and 0.4 or 1))
    setProperty(sun, "Spread", 0.78)
    setProperty(sun, "Enabled", true)

    local dof = State.Instances.DOF or createEffect("DepthOfFieldEffect", "VR_DepthOfField")
    State.Instances.DOF = dof
    setProperty(dof, "FocusDistance", mood.DOFFocus or 50)
    setProperty(dof, "InFocusRadius", mood.DOFRadius or 0)
    setProperty(dof, "NearIntensity", 0)
    setProperty(dof, "FarIntensity", mood.DOFFar or 0)
    setProperty(dof, "Enabled", mood.DOFFar ~= nil and not fog)
end

----------------------------------------------------------------
-- LIGHTING SUASANA
----------------------------------------------------------------

local function configureMoodLighting()
    local mood = currentMood()

    setProperty(Lighting, "ClockTime", mood.ClockTime)
    setProperty(Lighting, "Brightness", baseBrightness(mood))
    setProperty(Lighting, "ExposureCompensation", mood.Exposure)
    setProperty(Lighting, "ShadowSoftness", mood.ShadowSoftness)
    setProperty(Lighting, "Ambient", mood.Ambient)
    setProperty(Lighting, "OutdoorAmbient", mood.OutdoorAmbient)
    setProperty(Lighting, "ColorShift_Top", mood.Top)
    setProperty(Lighting, "ColorShift_Bottom", mood.Bottom)

    configureAtmosphere()
    configurePostEffects()
end

----------------------------------------------------------------
-- AWAN DI DUNIA
----------------------------------------------------------------

local cloudsState

local function applyClouds()
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if not terrain then
        return
    end

    local mood = currentMood()
    local fog = currentFog()
    local spec = mood.Clouds

    if fog then
        spec = {
            Color = scaleColor(fogColorFor(mood), 1.05),
            Cover = fog.Cover,
            Density = math.min(1, 0.5 + fog.Density * 0.6),
        }
    end

    if spec then
        if not cloudsState then
            local existing = terrain:FindFirstChildOfClass("Clouds")
            if existing then
                cloudsState = {
                    Object = existing, Owned = false,
                    Saved = {
                        Color = existing.Color, Cover = existing.Cover,
                        Density = existing.Density, Enabled = existing.Enabled,
                    },
                }
            else
                local c = Instance.new("Clouds")
                c.Name = "VR_Clouds"
                c.Parent = terrain
                cloudsState = { Object = c, Owned = true }
            end
        end
        local c = cloudsState.Object
        setProperty(c, "Color", spec.Color)
        setProperty(c, "Cover", spec.Cover)
        setProperty(c, "Density", spec.Density)
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

----------------------------------------------------------------
-- PARTIKEL DUNIA (kabut asap + debu cahaya) - NYATA DI MAP
----------------------------------------------------------------

local WorldFX = {}

do
    local folder, dustPart, dustEm, lowPart, lowEm, highPart, highEm

    local function makePart(name, size)
        local p = Instance.new("Part")
        p.Name = name
        p.Anchored = true
        p.CanCollide = false
        p.CanQuery = false
        p.CanTouch = false
        p.CastShadow = false
        p.Transparency = 1
        p.Size = size
        p.Parent = folder
        return p
    end

    local function makeEmitter(parent, name)
        local e = Instance.new("ParticleEmitter")
        e.Name = name
        e.Enabled = false
        e.Rate = 0
        e.SpreadAngle = Vector2.new(180, 180)
        pcall(function()
            e.Shape = Enum.ParticleEmitterShape.Box
            e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
        end)
        e.Parent = parent
        return e
    end

    local function ensure()
        if folder and folder.Parent then
            return
        end

        folder = Instance.new("Folder")
        folder.Name = "VR_WorldFX"
        folder.Parent = Workspace

        dustPart = makePart("VR_DustVolume", Vector3.new(90, 38, 90))
        lowPart = makePart("VR_FogLow", Vector3.new(170, 7, 170))
        highPart = makePart("VR_FogHigh", Vector3.new(170, 34, 170))

        dustEm = makeEmitter(dustPart, "VR_Dust")
        lowEm = makeEmitter(lowPart, "VR_FogLowEmitter")
        highEm = makeEmitter(highPart, "VR_FogHighEmitter")
    end

    local function styleFog(em, rate, size, color, opacity, lifeMin, lifeMax)
        em.Texture = "rbxasset://textures/particles/smoke_main.dds"
        em.Color = ColorSequence.new(color)
        em.LightEmission = 0.05
        em.LightInfluence = 0.7
        em.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, size * 0.7),
            NumberSequenceKeypoint.new(1, size * 1.2),
        })
        em.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.25, 1 - opacity),
            NumberSequenceKeypoint.new(0.75, 1 - opacity),
            NumberSequenceKeypoint.new(1, 1),
        })
        em.Lifetime = NumberRange.new(lifeMin, lifeMax)
        em.Speed = NumberRange.new(0.5, 1.5)
        em.Rotation = NumberRange.new(0, 360)
        em.RotSpeed = NumberRange.new(-6, 6)
        em.Drag = 0.5
        em.Rate = rate
    end

    function WorldFX.Configure()
        ensure()

        local mood = currentMood()
        local fog = currentFog()
        local q = qualityInfo(State.Quality)

        -- Debu cahaya melayang (khusus mood yang meminta)
        if mood.Dust and not fog then
            dustEm.Texture = "rbxasset://textures/particles/sparkles_main.dds"
            dustEm.Color = ColorSequence.new(mood.DustColor)
            dustEm.LightEmission = 1
            dustEm.LightInfluence = 0
            dustEm.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.1),
                NumberSequenceKeypoint.new(0.5, 0.35),
                NumberSequenceKeypoint.new(1, 0.1),
            })
            dustEm.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.2, 0.45),
                NumberSequenceKeypoint.new(0.8, 0.55),
                NumberSequenceKeypoint.new(1, 1),
            })
            dustEm.Lifetime = NumberRange.new(6, 12)
            dustEm.Speed = NumberRange.new(0.2, 0.8)
            dustEm.Acceleration = Vector3.new(0.25, 0.15, 0)
            dustEm.Rate = 18 * q.Particles
            dustEm.Enabled = true
        else
            dustEm.Enabled = false
        end

        -- Kabut asap nyata di sekitar pemain
        if fog then
            local color = fogColorFor(mood)
            styleFog(lowEm, fog.Rate * q.Particles, 34, color, 0.10 + fog.Opacity * 1.6, 10, 16)
            styleFog(highEm, fog.Rate * 0.5 * q.Particles, 46, color, fog.Opacity * 1.1, 12, 18)
            lowEm.Enabled = true
            highEm.Enabled = true
            lowEm:Emit(math.floor(40 * q.Particles))
            highEm:Emit(math.floor(20 * q.Particles))
        else
            lowEm.Enabled = false
            highEm.Enabled = false
        end
    end

    function WorldFX.Follow()
        if not folder or not folder.Parent then
            return
        end
        local cam = Workspace.CurrentCamera
        if not cam then
            return
        end

        local camPos = cam.CFrame.Position
        local char = Player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local ground = root and (root.Position - Vector3.new(0, 2, 0)) or (camPos - Vector3.new(0, 4, 0))

        dustPart.CFrame = CFrame.new(camPos)
        lowPart.CFrame = CFrame.new(ground + Vector3.new(0, 3, 0))
        highPart.CFrame = CFrame.new(ground + Vector3.new(0, 18, 0))
    end

    function WorldFX.Destroy()
        if folder then
            folder:Destroy()
            folder = nil
        end
    end
end

----------------------------------------------------------------
-- WARNA DUNIA (tint hangat/dingin langsung di benda map)
----------------------------------------------------------------

local function rememberPart(part, tintable)
    if Original.Parts[part] then
        return
    end
    Original.Parts[part] = {
        Material = getProperty(part, "Material", nil),
        Color = getProperty(part, "Color", nil),
        Reflectance = getProperty(part, "Reflectance", nil),
        CastShadow = getProperty(part, "CastShadow", nil),
        Tintable = tintable,
    }
end

local function applyWorldTint()
    State.TintVersion += 1
    local version = State.TintVersion

    local mood = currentMood()
    local color = mood.WorldTint or Color3.new(1, 1, 1)
    local amount = mood.WorldTintAmount

    task.spawn(function()
        local n = 0

        for part, data in pairs(Original.Parts) do
            if version ~= State.TintVersion then
                return
            end
            if data.Tintable and part.Parent and data.Color then
                part.Color = data.Color:Lerp(color, amount)
            end
            n += 1
            if n % 400 == 0 then
                task.wait()
            end
        end

        for surface, data in pairs(Original.SurfaceAppearances) do
            if version ~= State.TintVersion then
                return
            end
            if surface.Parent and data.Color then
                surface.Color = data.Color:Lerp(color, amount)
            end
            n += 1
            if n % 400 == 0 then
                task.wait()
            end
        end
    end)
end

----------------------------------------------------------------
-- SCAN MATERIAL
----------------------------------------------------------------

local BLOCKED_TOKENS = {
    "hitbox", "hurtbox", "trigger", "zoneprobe", "collider", "collision",
    "invisible", "interactionbox", "promptpart", "clickdetector", "raycast",
}

local function isVisualPart(part)
    if not part:IsA("BasePart") or part.Transparency >= 0.98 then
        return false
    end
    local name = string.lower(part.Name)
    for _, token in ipairs(BLOCKED_TOKENS) do
        if name:find(token, 1, true) then
            return false
        end
    end
    return true
end

local function classifyPart(part)
    local name = string.lower(part.Name)
    local material = getProperty(part, "Material", nil)

    if material == Enum.Material.Metal then
        return 0.14, true
    end
    if material == Enum.Material.Glass or material == Enum.Material.Neon
        or material == Enum.Material.ForceField then
        return nil, false
    end
    if name:find("gold") or name:find("coin") or name:find("brass") then
        return 0.16, true
    end
    if name:find("steel") or name:find("iron") or name:find("metal") or name:find("machine") then
        return 0.14, true
    end
    if name:find("water") or name:find("ocean") or name:find("river")
        or name:find("glow") or name:find("neon") or name:find("lava") then
        return nil, false
    end
    return nil, true
end

local function enhancePart(part)
    if not isVisualPart(part) then
        return
    end

    local reflectance, tintable = classifyPart(part)
    rememberPart(part, tintable)
    State.Stats.Parts += 1

    if reflectance then
        local current = getProperty(part, "Reflectance", 0)
        if current < reflectance then
            setProperty(part, "Reflectance", reflectance)
        end
    end

    setProperty(part, "CastShadow", true)
end

local function trackSurface(surface)
    if Original.SurfaceAppearances[surface] then
        return
    end
    Original.SurfaceAppearances[surface] = {
        Color = getProperty(surface, "Color", nil),
    }
    State.Stats.SurfaceAppearances += 1
end

local function scanVisualAssets()
    State.Stats.Parts = 0
    State.Stats.SurfaceAppearances = 0

    local list = Workspace:GetDescendants()

    for i, object in ipairs(list) do
        if object:IsA("SurfaceAppearance") then
            trackSurface(object)
        elseif object:IsA("BasePart") then
            enhancePart(object)
        end
        if i % 500 == 0 then
            task.wait()
        end
    end
end

----------------------------------------------------------------
-- CAHAYA TELUR (cahaya halus di setiap tempat egg)
----------------------------------------------------------------

local EggGlow = {}

do
    local records = {}
    local seen = {}
    local EGG_RANGE = 220
    local AURA_RANGE = 120

    -- Folder di Workspace yang isinya egg (model) yang ditaruh / ditampilkan.
    local EGG_CONTAINERS = {
        PlacedEggRenders = true,
        AreaEggSlotsClient = true,
        Eggs = true,
    }

    -- Part penanda posisi egg (nama sesuai struktur map).
    local EGG_MARKERS = {
        EggSpotBottom = Vector3.new(0, 2.2, 0),
        EggPoint = Vector3.new(0, 2.5, 0),
        AdminAbuseEggSpawn = Vector3.new(0, 4, 0),
        CaptureTheEggSpawn = Vector3.new(0, 4, 0),
    }

    local function add(part, offset)
        if seen[part] then
            return
        end
        seen[part] = true

        local attachment = Instance.new("Attachment")
        attachment.Name = "VR_EggGlowAttachment"
        attachment.Position = offset
        attachment.Parent = part

        local light = Instance.new("PointLight")
        light.Name = "VR_EggGlow"
        light.Shadows = false
        light.Brightness = 0
        light.Range = 12
        light.Color = Color3.fromRGB(255, 205, 140)
        light.Enabled = false
        light.Parent = attachment

        local aura = Instance.new("ParticleEmitter")
        aura.Name = "VR_EggGlowAura"
        aura.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        aura.LightEmission = 1
        aura.LightInfluence = 0
        aura.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.15),
            NumberSequenceKeypoint.new(0.5, 0.4),
            NumberSequenceKeypoint.new(1, 0.1),
        })
        aura.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.3, 0.5),
            NumberSequenceKeypoint.new(1, 1),
        })
        aura.Lifetime = NumberRange.new(2.5, 4)
        aura.Speed = NumberRange.new(0.3, 0.8)
        aura.Acceleration = Vector3.new(0, 0.5, 0)
        aura.SpreadAngle = Vector2.new(180, 180)
        aura.Rate = 0
        aura.Enabled = false
        aura.Parent = attachment

        table.insert(records, {
            Part = part,
            Attachment = attachment,
            Light = light,
            Aura = aura,
            Phase = math.random() * math.pi * 2,
        })
        State.Stats.Eggs = #records
    end

    function EggGlow.Consider(inst)
        if inst:IsA("BasePart") then
            local offset = EGG_MARKERS[inst.Name]
            if offset then
                add(inst, offset)
                return
            end
        end

        if inst:IsA("Model") then
            local parent = inst.Parent
            if parent and EGG_CONTAINERS[parent.Name] and parent.Parent == Workspace then
                local part = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
                if part then
                    add(part, Vector3.new(0, 1.5, 0))
                end
            end
        end
    end

    function EggGlow.Scan()
        for i, inst in ipairs(Workspace:GetDescendants()) do
            EggGlow.Consider(inst)
            if i % 800 == 0 then
                task.wait()
            end
        end
    end

    function EggGlow.Update(clock)
        local cam = Workspace.CurrentCamera
        if not cam then
            return
        end

        local mood = currentMood()
        local strength = State.EggGlowEnabled and mood.EggGlow or 0
        local camPos = cam.CFrame.Position
        local range = math.clamp(10 + 7 * strength, 10, 38)

        for i = #records, 1, -1 do
            local r = records[i]

            if not r.Part.Parent then
                if r.Attachment.Parent then
                    r.Attachment:Destroy()
                end
                seen[r.Part] = nil
                table.remove(records, i)
            else
                local dist = (r.Part.Position - camPos).Magnitude

                if strength <= 0 or dist > EGG_RANGE then
                    r.Light.Enabled = false
                    r.Aura.Enabled = false
                else
                    local fade = 1 - math.clamp((dist - EGG_RANGE * 0.6) / (EGG_RANGE * 0.4), 0, 1)
                    local pulse = 0.85 + 0.15 * math.sin(clock * 1.3 + r.Phase)

                    r.Light.Color = mood.EggColor
                    r.Light.Range = range
                    r.Light.Brightness = 0.6 * strength * pulse * fade
                    r.Light.Enabled = true

                    r.Aura.Color = ColorSequence.new(mood.EggColor)
                    r.Aura.Rate = (dist < AURA_RANGE and strength >= 0.5) and (2 * strength) or 0
                    r.Aura.Enabled = r.Aura.Rate > 0
                end
            end
        end

        State.Stats.Eggs = #records
    end

    function EggGlow.Destroy()
        for _, r in ipairs(records) do
            if r.Attachment and r.Attachment.Parent then
                r.Attachment:Destroy()
            end
        end
        table.clear(records)
        table.clear(seen)
    end
end

----------------------------------------------------------------
-- LAMPU AKSEN (lampu, obor, kristal, layar, dll.)
----------------------------------------------------------------

local LIGHT_TOKENS = {
    "lamp", "light", "lantern", "torch", "fire", "flame", "bulb", "neon",
    "screen", "monitor", "sign", "crystal", "portal", "glow", "energy", "lava",
}

local function isLightSourcePart(part)
    if not isVisualPart(part) then
        return false
    end
    if string.sub(part.Name, 1, 3) == "VR_" then
        return false
    end
    local name = string.lower(part.Name)
    for _, token in ipairs(LIGHT_TOKENS) do
        if name:find(token, 1, true) then
            return true
        end
    end
    return getProperty(part, "Material", nil) == Enum.Material.Neon
end

local function accentColor(part)
    local name = string.lower(part.Name)
    if name:find("fire") or name:find("flame") or name:find("torch") or name:find("lava") then
        return Color3.fromRGB(255, 170, 90)
    end
    if name:find("crystal") or name:find("ice") then
        return Color3.fromRGB(150, 210, 255)
    end
    return getProperty(part, "Color", Color3.fromRGB(255, 225, 180))
end

local function clearAccentLights()
    for _, record in ipairs(State.AccentLights) do
        if record.Attachment and record.Attachment.Parent then
            record.Attachment:Destroy()
        end
    end
    table.clear(State.AccentLights)
end

local function scanAccentLights()
    clearAccentLights()
    State.Stats.LightsCreated = 0

    local cam = Workspace.CurrentCamera
    if not cam then
        return
    end

    local q = qualityInfo(State.Quality)
    local candidates = {}

    for _, object in ipairs(Workspace:GetDescendants()) do
        if object:IsA("BasePart") and isLightSourcePart(object) then
            table.insert(candidates, object)
        end
    end

    local origin = cam.CFrame.Position
    table.sort(candidates, function(a, b)
        return (a.Position - origin).Magnitude < (b.Position - origin).Magnitude
    end)

    for _, part in ipairs(candidates) do
        if #State.AccentLights >= q.MaxLights then
            break
        end
        if (part.Position - origin).Magnitude <= q.LightDistance then
            local attachment = Instance.new("Attachment")
            attachment.Name = "VR_AccentAttachment"
            attachment.Parent = part

            local light = Instance.new("PointLight")
            light.Name = "VR_AccentLight"
            light.Color = accentColor(part)
            light.Brightness = 0.65
            light.Range = 12
            light.Shadows = true
            light.Parent = attachment

            table.insert(State.AccentLights, { Source = part, Attachment = attachment, Light = light })
            State.Stats.LightsCreated += 1
        end
    end
end

local function enhanceExistingLights()
    State.Stats.LightsFound = 0
    for _, object in ipairs(Workspace:GetDescendants()) do
        if object:IsA("PointLight") or object:IsA("SpotLight") or object:IsA("SurfaceLight") then
            State.Stats.LightsFound += 1
            setProperty(object, "Shadows", true)
        end
    end
end

----------------------------------------------------------------
-- DINAMIS: matahari turun pelan, silau saat menghadap matahari,
-- cahaya hangat di karakter, ikut-gerak partikel
----------------------------------------------------------------

local Dynamic = {
    DriftClock = 0,
    SunVisible = 0,
    Facing = 0,
    BodyBrightness = 0,
    BodyAttachment = nil,
    BodyLight = nil,
    CastTimer = 0,
    SunTimer = 0,
    SunTarget = 0,
}

local function updateBodyLight(dt, mood)
    local char = Player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if not mood.BodyLight or not root then
        Dynamic.BodyBrightness = lerp(Dynamic.BodyBrightness, 0, math.min(1, dt * 3))
        if Dynamic.BodyLight then
            Dynamic.BodyLight.Brightness = Dynamic.BodyBrightness
        end
        return
    end

    if not Dynamic.BodyAttachment or not Dynamic.BodyAttachment.Parent then
        Dynamic.BodyAttachment = Instance.new("Attachment")
        Dynamic.BodyAttachment.Name = "VR_WarmBodyAttachment"
        Dynamic.BodyAttachment.Parent = Workspace.Terrain

        Dynamic.BodyLight = Instance.new("PointLight")
        Dynamic.BodyLight.Name = "VR_WarmBodyLight"
        Dynamic.BodyLight.Color = Color3.fromRGB(255, 160, 80)
        Dynamic.BodyLight.Range = 16
        Dynamic.BodyLight.Brightness = 0
        Dynamic.BodyLight.Shadows = false
        Dynamic.BodyLight.Parent = Dynamic.BodyAttachment
    end

    local sunDir = Lighting:GetSunDirection()
    Dynamic.BodyAttachment.WorldPosition = root.Position + sunDir * 7 + Vector3.new(0, 1.5, 0)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { char }
    local covered = Workspace:Raycast(root.Position + Vector3.new(0, 2, 0), sunDir * 300, params) ~= nil

    local elevation = math.clamp(sunDir.Y * 4 + 0.35, 0, 1)
    local target = covered and 0 or (1.2 * elevation)

    Dynamic.BodyBrightness = lerp(Dynamic.BodyBrightness, target, math.min(1, dt * 2.5))
    Dynamic.BodyLight.Brightness = Dynamic.BodyBrightness

    Dynamic.CastTimer += dt
    if Dynamic.CastTimer >= 2 then
        Dynamic.CastTimer = 0
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("BasePart") then
                d.CastShadow = true
            end
        end
    end
end

local function dynamicUpdate(dt)
    local mood = currentMood()
    local fog = currentFog()
    local cam = Workspace.CurrentCamera
    if not cam then
        return
    end

    -- 1. Matahari turun pelan
    if mood.Drift then
        local d = mood.Drift
        Dynamic.DriftClock += dt

        local phase = (Dynamic.DriftClock / (d.Minutes * 60)) % 2
        local t = phase < 1 and phase or (2 - phase)
        t = t * t * (3 - 2 * t)

        local breathing = math.sin(os.clock() * 0.7) * 0.02
        local dim = fog and fog.Dim or 1

        setProperty(Lighting, "ClockTime", lerp(d.Clock0, d.Clock1, t))
        setProperty(Lighting, "Brightness", (lerp(d.Bright0, d.Bright1, t) + breathing) * dim)
        setProperty(Lighting, "ExposureCompensation", lerp(d.Exp0, d.Exp1, t))
    end

    -- 2. Silau saat menghadap matahari (efek kamera dari pencahayaan dunia)
    if mood.SunGlare then
        Dynamic.SunTimer += dt
        if Dynamic.SunTimer >= 0.1 then
            Dynamic.SunTimer = 0

            local sunDir = Lighting:GetSunDirection()
            Dynamic.Facing = math.clamp(cam.CFrame.LookVector:Dot(sunDir), 0, 1)

            local _, onScreen = cam:WorldToViewportPoint(cam.CFrame.Position + sunDir * 1000)

            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = { Player.Character }
            local blocked = Workspace:Raycast(cam.CFrame.Position, sunDir * 2000, params) ~= nil

            Dynamic.SunTarget = (onScreen and not blocked) and 1 or 0
        end

        Dynamic.SunVisible = lerp(Dynamic.SunVisible, Dynamic.SunTarget, math.min(1, dt * 3))

        local f2 = Dynamic.Facing * Dynamic.Facing
        local f3 = f2 * Dynamic.Facing
        local sv = Dynamic.SunVisible
        local q = qualityInfo(State.Quality)

        setProperty(State.Instances.Bloom, "Intensity", (mood.Bloom + 0.30 * f3 * sv) * q.BloomScale)
        setProperty(State.Instances.SunRays, "Intensity", mood.SunRays + 0.22 * f2 * sv)

        local grade = State.Instances.Grade
        setProperty(grade, "TintColor", mood.Tint:Lerp(Color3.fromRGB(255, 186, 112), 0.6 * f2))
        setProperty(grade, "Saturation", mood.Saturation + 0.10 * f2)
        setProperty(grade, "Brightness", mood.GradeBrightness + 0.035 * f3 * sv)

        if not fog then
            setProperty(State.Instances.Atmosphere, "Glare", math.min(1, mood.Glare + 0.40 * f2))
        end
    end

    -- 3. Cahaya hangat di karakter
    updateBodyLight(dt, mood)
end

----------------------------------------------------------------
-- TERAPKAN SEMUA
----------------------------------------------------------------

local function configureAll()
    configureLightingBase()
    configureMoodLighting()
    applyClouds()
    WorldFX.Configure()
    applyWorldTint()
end

local function applyQuality(level)
    State.Quality = math.clamp(math.floor(level or 10), 1, 10)
    configureAll()
    task.spawn(scanAccentLights)
end

local function applyMood(name)
    if not Moods[name] then
        return false
    end

    State.MoodName = name

    local mood = Moods[name]
    if mood.Fog then
        State.FogLevel = mood.Fog
    end

    Dynamic.DriftClock = 0
    configureAll()
    return true
end

local function applyFog(level)
    State.FogLevel = math.clamp(math.floor(level or 0), 0, 4)
    configureAll()
end

local function applyEggGlow(enabled)
    State.EggGlowEnabled = enabled and true or false
end

----------------------------------------------------------------
-- PUBLIC API
----------------------------------------------------------------

local API = {}

function API.SetQuality(level) applyQuality(level) end
function API.GetQuality() return State.Quality end
function API.SetMood(name) return applyMood(name) end
function API.GetMood() return State.MoodName end
function API.SetFog(level) applyFog(level) end
function API.GetFog() return State.FogLevel end
function API.SetEggGlow(on) applyEggGlow(on) end
function API.GetStats() return State.Stats end

function API.Refresh()
    task.spawn(function()
        scanVisualAssets()
        enhanceExistingLights()
        scanAccentLights()
        EggGlow.Scan()
        applyWorldTint()
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
    State.TintVersion += 1

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
            setProperty(part, "Material", data.Material)
            setProperty(part, "Color", data.Color)
            setProperty(part, "Reflectance", data.Reflectance)
            setProperty(part, "CastShadow", data.CastShadow)
        end
    end

    for surface, data in pairs(Original.SurfaceAppearances) do
        if surface and surface.Parent and data.Color then
            setProperty(surface, "Color", data.Color)
        end
    end

    clearAccentLights()
    EggGlow.Destroy()
    WorldFX.Destroy()

    State.MoodName = "Siang Cerah"
    State.FogLevel = 0
    applyClouds()

    if Dynamic.BodyAttachment then
        Dynamic.BodyAttachment:Destroy()
        Dynamic.BodyAttachment = nil
        Dynamic.BodyLight = nil
    end

    for _, instance in ipairs(Original.Created) do
        if instance and instance.Parent then
            instance:Destroy()
        end
    end

    local gui = PlayerGui:FindFirstChild(ROOT_NAME)
    if gui then
        gui:Destroy()
    end
end

API.Restore = restoreOriginal

----------------------------------------------------------------
-- PANEL UI
----------------------------------------------------------------

local function createUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = ROOT_NAME
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = PlayerGui

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.fromOffset(390, 535)
    panel.Position = UDim2.new(0, 22, 0.5, -267)
    panel.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
    panel.BackgroundTransparency = 0.05
    panel.BorderSizePixel = 0
    panel.Parent = gui

    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(95, 105, 125)
    stroke.Transparency = 0.55
    stroke.Parent = panel

    local function label(text, y, size, bold, color)
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Size = UDim2.new(1, -30, 0, size + 8)
        l.Position = UDim2.fromOffset(15, y)
        l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
        l.TextSize = size
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextColor3 = color
        l.Text = text
        l.Parent = panel
        return l
    end

    local title = label("VISUAL REALISTIS", 12, 18, true, Color3.fromRGB(245, 248, 255))
    label("SUASANA • KABUT • CAHAYA TELUR   (RightCtrl = sembunyikan)", 42, 10, false, Color3.fromRGB(160, 170, 188))

    local function styleButton(button, active)
        button.BackgroundColor3 = active and Color3.fromRGB(90, 125, 190) or Color3.fromRGB(31, 35, 43)
        button.TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 188, 205)
    end

    local function makeButton(parent, text, size)
        local b = Instance.new("TextButton")
        b.Size = size
        b.BorderSizePixel = 0
        b.Font = Enum.Font.GothamBold
        b.TextSize = 12
        b.Text = text
        b.Parent = parent
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
        return b
    end

    -- KUALITAS
    label("KUALITAS (1–10)", 72, 12, true, Color3.fromRGB(210, 218, 232))

    local qualityHolder = Instance.new("Frame")
    qualityHolder.BackgroundTransparency = 1
    qualityHolder.Size = UDim2.new(1, -30, 0, 70)
    qualityHolder.Position = UDim2.fromOffset(15, 98)
    qualityHolder.Parent = panel

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.fromOffset(64, 30)
    grid.CellPadding = UDim2.fromOffset(6, 6)
    grid.Parent = qualityHolder

    local qualityButtons = {}
    local function refreshQuality()
        for level, b in pairs(qualityButtons) do
            styleButton(b, level == State.Quality)
        end
    end

    for level = 1, 10 do
        local b = makeButton(qualityHolder, tostring(level), UDim2.fromOffset(64, 30))
        b.MouseButton1Click:Connect(function()
            applyQuality(level)
            refreshQuality()
        end)
        qualityButtons[level] = b
    end
    refreshQuality()

    -- SUASANA
    label("SUASANA", 176, 12, true, Color3.fromRGB(210, 218, 232))

    local scroll = Instance.new("ScrollingFrame")
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.Size = UDim2.new(1, -30, 0, 170)
    scroll.Position = UDim2.fromOffset(15, 202)
    scroll.ScrollBarThickness = 3
    scroll.Parent = panel

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 5)
    list.Parent = scroll

    local moodButtons = {}
    local function refreshMoods()
        for name, b in pairs(moodButtons) do
            b.BackgroundColor3 = (name == State.MoodName) and Color3.fromRGB(68, 80, 108) or Color3.fromRGB(25, 29, 36)
            b.TextColor3 = (name == State.MoodName) and Color3.new(1, 1, 1) or Color3.fromRGB(178, 186, 201)
        end
    end

    local fogButtons = {}
    local function refreshFog()
        for level, b in pairs(fogButtons) do
            styleButton(b, level == State.FogLevel)
        end
    end

    for _, name in ipairs(MoodOrder) do
        local b = makeButton(scroll, "   " .. name, UDim2.new(1, -5, 0, 28))
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.Font = Enum.Font.GothamMedium
        b.TextSize = 11
        b.MouseButton1Click:Connect(function()
            applyMood(name)
            refreshMoods()
            refreshFog()
        end)
        moodButtons[name] = b
    end
    refreshMoods()

    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.fromOffset(0, list.AbsoluteContentSize.Y + 10)
    end)

    -- KABUT
    label("KABUT", 382, 12, true, Color3.fromRGB(210, 218, 232))

    local fogHolder = Instance.new("Frame")
    fogHolder.BackgroundTransparency = 1
    fogHolder.Size = UDim2.new(1, -30, 0, 66)
    fogHolder.Position = UDim2.fromOffset(15, 408)
    fogHolder.Parent = panel

    local fogGrid = Instance.new("UIGridLayout")
    fogGrid.CellSize = UDim2.fromOffset(110, 30)
    fogGrid.CellPadding = UDim2.fromOffset(6, 6)
    fogGrid.Parent = fogHolder

    local fogNames = { [0] = "Mati", "Tipis", "Sedang", "Tebal", "Super Tebal" }
    for level = 0, 4 do
        local b = makeButton(fogHolder, fogNames[level], UDim2.fromOffset(110, 30))
        b.MouseButton1Click:Connect(function()
            applyFog(level)
            refreshFog()
        end)
        fogButtons[level] = b
    end
    refreshFog()

    -- CAHAYA TELUR
    local eggButton = makeButton(panel, "", UDim2.new(1, -30, 0, 30))
    eggButton.Position = UDim2.fromOffset(15, 480)

    local function refreshEgg()
        eggButton.Text = State.EggGlowEnabled and "CAHAYA TELUR: HIDUP" or "CAHAYA TELUR: MATI"
        styleButton(eggButton, State.EggGlowEnabled)
    end
    eggButton.MouseButton1Click:Connect(function()
        applyEggGlow(not State.EggGlowEnabled)
        refreshEgg()
    end)
    refreshEgg()

    local status = label("", 513, 10, false, Color3.fromRGB(135, 145, 164))
    task.spawn(function()
        while gui.Parent do
            status.Text = string.format(
                "Q%d %s • Telur %d • Lampu %d • Benda %d",
                State.Quality, QualityNames[State.Quality],
                State.Stats.Eggs, State.Stats.LightsCreated, State.Stats.Parts
            )
            task.wait(1)
        end
    end)

    -- Geser panel
    local dragging, dragStart, startPosition = false, nil, nil

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
            startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
        )
    end))

    table.insert(State.Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == Enum.KeyCode.RightControl then
            panel.Visible = not panel.Visible
        end
    end))
end

----------------------------------------------------------------
-- MULAI
----------------------------------------------------------------

_G.VisualRealistis = API

local function initialize()
    State.Restored = false

    configureAll()
    createUI()

    -- Egg baru (ditaruh / muncul belakangan) otomatis dapat cahaya.
    table.insert(State.Connections, Workspace.DescendantAdded:Connect(function(inst)
        if State.Restored then
            return
        end
        task.defer(EggGlow.Consider, inst)
    end))

    -- Loop utama.
    local eggTimer = 0
    table.insert(State.Connections, RunService.Heartbeat:Connect(function(dt)
        if State.Restored then
            return
        end

        WorldFX.Follow()
        dynamicUpdate(dt)

        eggTimer += dt
        if eggTimer >= 0.1 then
            eggTimer = 0
            EggGlow.Update(os.clock())
        end
    end))

    -- Lampu aksen: atur ulang sesuai jarak.
    local lightTimer = 0
    table.insert(State.Connections, RunService.Heartbeat:Connect(function(dt)
        if State.Restored then
            return
        end
        lightTimer += dt
        if lightTimer < 0.15 then
            return
        end
        lightTimer = 0

        local cam = Workspace.CurrentCamera
        if not cam then
            return
        end

        local q = qualityInfo(State.Quality)
        for _, record in ipairs(State.AccentLights) do
            local source, light = record.Source, record.Light
            if source and source.Parent and light and light.Parent then
                local distance = (source.Position - cam.CFrame.Position).Magnitude
                if distance > q.LightDistance then
                    light.Enabled = false
                else
                    light.Enabled = true
                    light.Brightness = lerp(0.15, 0.85, 1 - math.clamp(distance / q.LightDistance, 0, 1))
                end
            end
        end
    end))

    task.spawn(function()
        scanVisualAssets()
        applyWorldTint()
        enhanceExistingLights()
        scanAccentLights()
        EggGlow.Scan()
    end)
end

initialize()
