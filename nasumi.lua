--[[
    ============================================================================
    ULTRA REALISTIC RENDERER V4 + NOSTALGIC SORE (EDISI KOMBINASI & PENGATURAN)
    ============================================================================
    Roblox LocalScript
    Recommended Placement: StarterPlayer > StarterPlayerScripts

    FILOSOFI VISUAL
    ---------------
    Script ini dirancang untuk menciptakan pengalaman visual yang imersif, 
    tenang, dan sangat realistis dengan memanfaatkan pipeline rendering asli Roblox.
    
    FITUR BARU UTAMA:
    1. KOMBINASI SHADERS (MAKSIMAL 2): 
       Anda dapat menggabungkan dua suasana (misal: "SORE" + "HUJAN") untuk 
       menciptakan atmosfer hibrida yang unik. Sistem akan secara otomatis 
       menghitung rata-rata nilai numerik dan melakukan Lerp pada nilai warna.
       
    2. PENGATURAN DETAIL PER SHADER:
       Setiap suasana memiliki panel pengaturan sendiri yang memungkinkan Anda 
       mengubah preset (Lumayan Terang, Sedang, Gelap) atau menyesuaikan 
       parameter secara manual menggunakan slider yang halus dan responsif.

    BATAS TEKNIS
    ------------
    - Roblox tidak mengizinkan custom GPU shader dari LocalScript biasa.
    - Renderer ini memakai pipeline asli: Realistic lighting, PBR, SurfaceAppearance, 
      local lights, Atmosphere, ColorCorrection, Bloom, SunRays, dan DepthOfField.
    - Script ini TIDAK membuat texture PBR baru. NormalMap/RoughnessMap/MetalnessMap 
      harus berasal dari asset asli pembuat map.
    - Murni visual: tanpa automation gameplay, tanpa remote, tanpa perubahan data pemain.
]]

----------------------------------------------------------------
-- SERVICES
----------------------------------------------------------------
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera

----------------------------------------------------------------
-- ROOT & CLEANUP
----------------------------------------------------------------
local ROOT_NAME = "UltraRealisticRendererV4"

local Existing = PlayerGui:FindFirstChild(ROOT_NAME)
if Existing then
    Existing:Destroy()
end

local ExistingSettings = PlayerGui:FindFirstChild(ROOT_NAME .. "_Settings")
if ExistingSettings then
    ExistingSettings:Destroy()
end

local OldNostalgia = PlayerGui:FindFirstChild(ROOT_NAME .. "_Nostalgia")
if OldNostalgia then
    OldNostalgia:Destroy()
end

----------------------------------------------------------------
-- SAFE HELPERS
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
        local value = instance[property]
        return true
    end, false)
end

local function clamp01(v)
    return math.clamp(v, 0, 1)
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function colorLerp(a, b, t)
    return a:Lerp(b, clamp01(t))
end

local function isFiniteNumber(v)
    return typeof(v) == "number" and v == v and v > -math.huge and v < math.huge
end

----------------------------------------------------------------
-- ORIGINAL STATE
----------------------------------------------------------------
local Original = {
    Lighting = {},
    Effects = {},
    Parts = {},
    SurfaceAppearances = {},
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
        MaterialVariant = getProperty(part, "MaterialVariant", nil),
    }
end

local function rememberSurfaceAppearance(surface)
    if Original.SurfaceAppearances[surface] then
        return
    end
    Original.SurfaceAppearances[surface] = {
        Color = getProperty(surface, "Color", nil),
        EmissiveStrength = getProperty(surface, "EmissiveStrength", nil),
        EmissiveTint = getProperty(surface, "EmissiveTint", nil),
    }
end

----------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------
local Config = {
    Enabled = true,
    Quality = 10,
    SuperRealistic = true,
    Atmosphere = true,
    Shaders = true,
    SuperDetail = true,
    AtmosphereDensity = 0.006,
    AtmosphereOffset = 0.12,
    AtmosphereHaze = 0.18,
    AtmosphereGlare = 0.08,
    Brightness = 2.35,
    Exposure = 0.05,
    ShadowSoftness = 0.18,
    DiffuseScale = 1,
    SpecularScale = 1,
    BloomIntensity = 0.10,
    BloomSize = 20,
    BloomThreshold = 1.25,
    Contrast = 0.10,
    Saturation = 0.03,
    ColorTemperature = 0,
    SunRayIntensity = 0.045,
    SunRaySpread = 0.78,
    DOFEnabled = false,
    DOFNear = 0,
    DOFFar = 100000,
    DOFFocus = 50,
    DOFStrength = 0,
    DetailDistance = 600,
    LightDistance = 500,
    MaxAccentLights = 80,
    LightUpdateInterval = 0.12,
    MetalReflectance = 0.12,
    GlassReflectance = 0.08,
    PlasticReflectance = 0.01,
    PreserveOriginalColors = true,
    ColorInfluence = 0.06,
    CameraFOV = nil,
    ShowUI = true,
}

----------------------------------------------------------------
-- QUALITY PRESETS
----------------------------------------------------------------
local QualityLevels = {
    [1] = { Name = "LOW", Brightness = 2.0, Exposure = 0, ShadowSoftness = 0.45, Diffuse = 0.85, Specular = 0.75, AtmosphereDensity = 0.002, AtmosphereHaze = 0.08, Bloom = 0.00, Contrast = 0.02, Saturation = 0, SunRays = 0, DetailDistance = 250, LightDistance = 220, MaxLights = 20 },
    [2] = { Name = "BASIC", Brightness = 2.05, Exposure = 0, ShadowSoftness = 0.38, Diffuse = 0.90, Specular = 0.82, AtmosphereDensity = 0.003, AtmosphereHaze = 0.10, Bloom = 0.01, Contrast = 0.035, Saturation = 0.005, SunRays = 0.005, DetailDistance = 300, LightDistance = 260, MaxLights = 28 },
    [3] = { Name = "BALANCED", Brightness = 2.10, Exposure = 0.01, ShadowSoftness = 0.34, Diffuse = 0.95, Specular = 0.90, AtmosphereDensity = 0.004, AtmosphereHaze = 0.12, Bloom = 0.025, Contrast = 0.05, Saturation = 0.01, SunRays = 0.012, DetailDistance = 340, LightDistance = 300, MaxLights = 36 },
    [4] = { Name = "GOOD", Brightness = 2.15, Exposure = 0.015, ShadowSoftness = 0.30, Diffuse = 0.98, Specular = 0.96, AtmosphereDensity = 0.0045, AtmosphereHaze = 0.13, Bloom = 0.04, Contrast = 0.065, Saturation = 0.015, SunRays = 0.018, DetailDistance = 390, LightDistance = 330, MaxLights = 44 },
    [5] = { Name = "HIGH", Brightness = 2.20, Exposure = 0.02, ShadowSoftness = 0.26, Diffuse = 1, Specular = 1, AtmosphereDensity = 0.005, AtmosphereHaze = 0.14, Bloom = 0.055, Contrast = 0.075, Saturation = 0.02, SunRays = 0.024, DetailDistance = 440, LightDistance = 370, MaxLights = 52 },
    [6] = { Name = "VERY HIGH", Brightness = 2.25, Exposure = 0.03, ShadowSoftness = 0.23, Diffuse = 1, Specular = 1, AtmosphereDensity = 0.0055, AtmosphereHaze = 0.15, Bloom = 0.07, Contrast = 0.085, Saturation = 0.025, SunRays = 0.030, DetailDistance = 490, LightDistance = 410, MaxLights = 60 },
    [7] = { Name = "ULTRA", Brightness = 2.30, Exposure = 0.04, ShadowSoftness = 0.20, Diffuse = 1, Specular = 1, AtmosphereDensity = 0.006, AtmosphereHaze = 0.16, Bloom = 0.085, Contrast = 0.095, Saturation = 0.03, SunRays = 0.036, DetailDistance = 540, LightDistance = 450, MaxLights = 68 },
    [8] = { Name = "CINEMATIC", Brightness = 2.32, Exposure = 0.045, ShadowSoftness = 0.19, Diffuse = 1, Specular = 1, AtmosphereDensity = 0.006, AtmosphereHaze = 0.17, Bloom = 0.095, Contrast = 0.105, Saturation = 0.035, SunRays = 0.040, DetailDistance = 580, LightDistance = 470, MaxLights = 74 },
    [9] = { Name = "EXTREME", Brightness = 2.34, Exposure = 0.05, ShadowSoftness = 0.18, Diffuse = 1, Specular = 1, AtmosphereDensity = 0.006, AtmosphereHaze = 0.18, Bloom = 0.10, Contrast = 0.11, Saturation = 0.04, SunRays = 0.043, DetailDistance = 620, LightDistance = 490, MaxLights = 78 },
    [10] = { Name = "ABSOLUTE REALISM", Brightness = 2.36, Exposure = 0.055, ShadowSoftness = 0.16, Diffuse = 1, Specular = 1, AtmosphereDensity = 0.006, AtmosphereHaze = 0.18, Bloom = 0.105, Contrast = 0.115, Saturation = 0.045, SunRays = 0.045, DetailDistance = 700, LightDistance = 520, MaxLights = 80 },
}

----------------------------------------------------------------
-- ATMOSPHERE / MOOD LIBRARY (Diperluas untuk variasi yang kaya)
----------------------------------------------------------------
local Atmospheres = {
    ["REALISTIC CLEAR"] = {
        ClockTime = 10.2, Brightness = 2.36, Exposure = 0.04, Density = 0.004, Offset = 0.18, Haze = 0.08, Glare = 0.02,
        Color = Color3.fromRGB(225, 237, 255), Decay = Color3.fromRGB(200, 218, 245), Ambient = Color3.fromRGB(35, 38, 44),
        OutdoorAmbient = Color3.fromRGB(150, 160, 175), Top = Color3.fromRGB(205, 225, 255), Bottom = Color3.fromRGB(245, 240, 225),
        Bloom = 0.055, Contrast = 0.08, Saturation = 0.02, Tint = Color3.fromRGB(255, 255, 255),
    },
    ["CRISP MORNING"] = {
        ClockTime = 7.6, Brightness = 2.42, Exposure = 0.045, Density = 0.004, Offset = 0.10, Haze = 0.06, Glare = 0.08,
        Color = Color3.fromRGB(210, 232, 255), Decay = Color3.fromRGB(188, 210, 240), Ambient = Color3.fromRGB(31, 38, 48),
        OutdoorAmbient = Color3.fromRGB(150, 166, 190), Top = Color3.fromRGB(190, 220, 255), Bottom = Color3.fromRGB(255, 238, 212),
        Bloom = 0.075, Contrast = 0.10, Saturation = 0.035, Tint = Color3.fromRGB(248, 252, 255),
    },
    ["WARM MORNING"] = {
        ClockTime = 8.5, Brightness = 2.38, Exposure = 0.04, Density = 0.0045, Offset = 0.12, Haze = 0.09, Glare = 0.10,
        Color = Color3.fromRGB(226, 235, 255), Decay = Color3.fromRGB(245, 208, 165), Ambient = Color3.fromRGB(43, 39, 34),
        OutdoorAmbient = Color3.fromRGB(165, 156, 145), Top = Color3.fromRGB(215, 232, 255), Bottom = Color3.fromRGB(255, 225, 190),
        Bloom = 0.08, Contrast = 0.095, Saturation = 0.045, Tint = Color3.fromRGB(255, 249, 238),
    },
    ["CLEAN NOON"] = {
        ClockTime = 12.1, Brightness = 2.40, Exposure = 0.035, Density = 0.003, Offset = 0.20, Haze = 0.05, Glare = 0.03,
        Color = Color3.fromRGB(225, 238, 255), Decay = Color3.fromRGB(215, 225, 242), Ambient = Color3.fromRGB(32, 34, 38),
        OutdoorAmbient = Color3.fromRGB(155, 160, 168), Top = Color3.fromRGB(218, 235, 255), Bottom = Color3.fromRGB(250, 247, 238),
        Bloom = 0.045, Contrast = 0.12, Saturation = 0.025, Tint = Color3.fromRGB(255, 255, 255),
    },
    ["WARM AFTERNOON"] = {
        ClockTime = 15.3, Brightness = 2.33, Exposure = 0.045, Density = 0.0045, Offset = 0.15, Haze = 0.09, Glare = 0.05,
        Color = Color3.fromRGB(232, 238, 255), Decay = Color3.fromRGB(238, 205, 168), Ambient = Color3.fromRGB(43, 40, 38),
        OutdoorAmbient = Color3.fromRGB(164, 153, 142), Top = Color3.fromRGB(224, 233, 255), Bottom = Color3.fromRGB(255, 223, 190),
        Bloom = 0.07, Contrast = 0.105, Saturation = 0.05, Tint = Color3.fromRGB(255, 249, 240),
    },
    ["GOLDEN HOUR"] = {
        ClockTime = 17.25, Brightness = 2.28, Exposure = 0.03, Density = 0.005, Offset = 0.12, Haze = 0.13, Glare = 0.18,
        Color = Color3.fromRGB(255, 224, 190), Decay = Color3.fromRGB(220, 150, 92), Ambient = Color3.fromRGB(50, 38, 31),
        OutdoorAmbient = Color3.fromRGB(176, 139, 111), Top = Color3.fromRGB(255, 205, 155), Bottom = Color3.fromRGB(255, 172, 112),
        Bloom = 0.11, Contrast = 0.11, Saturation = 0.08, Tint = Color3.fromRGB(255, 244, 225),
    },
    ["NOSTALGIC SORE"] = {
        ClockTime = 17.35, Brightness = 1.85, Exposure = -0.02, ShadowSoftness = 0.10, Density = 0.0065, Offset = 0.08, Haze = 0.20, Glare = 0.36,
        Color = Color3.fromRGB(255, 176, 100), Decay = Color3.fromRGB(232, 106, 52), Ambient = Color3.fromRGB(46, 30, 22),
        OutdoorAmbient = Color3.fromRGB(140, 100, 70), Top = Color3.fromRGB(255, 172, 100), Bottom = Color3.fromRGB(240, 128, 72),
        Bloom = 0.18, BloomSize = 36, BloomThreshold = 0.85, SunRays = 0.10, Contrast = 0.12, Saturation = 0.07, Tint = Color3.fromRGB(255, 222, 180),
        GradeBrightness = -0.025, DOFFar = 0.14, DOFFocus = 90, DOFRadius = 70,
        Drift = { Minutes = 14, Clock0 = 17.10, Clock1 = 17.95, Bright0 = 1.95, Bright1 = 1.50, Exp0 = 0.01, Exp1 = -0.06 },
    },
    ["SUNSET"] = {
        ClockTime = 18.05, Brightness = 2.18, Exposure = 0.015, Density = 0.006, Offset = 0.08, Haze = 0.18, Glare = 0.28,
        Color = Color3.fromRGB(255, 195, 166), Decay = Color3.fromRGB(198, 94, 74), Ambient = Color3.fromRGB(46, 31, 36),
        OutdoorAmbient = Color3.fromRGB(146, 106, 112), Top = Color3.fromRGB(255, 170, 146), Bottom = Color3.fromRGB(235, 105, 92),
        Bloom = 0.13, Contrast = 0.12, Saturation = 0.10, Tint = Color3.fromRGB(255, 235, 220),
    },
    ["BLUE HOUR"] = {
        ClockTime = 19.0, Brightness = 1.88, Exposure = -0.015, Density = 0.006, Offset = 0.16, Haze = 0.11, Glare = 0.02,
        Color = Color3.fromRGB(150, 185, 235), Decay = Color3.fromRGB(90, 125, 185), Ambient = Color3.fromRGB(22, 29, 45),
        OutdoorAmbient = Color3.fromRGB(72, 94, 132), Top = Color3.fromRGB(90, 125, 190), Bottom = Color3.fromRGB(165, 160, 190),
        Bloom = 0.06, Contrast = 0.14, Saturation = 0.035, Tint = Color3.fromRGB(225, 235, 255),
    },
    ["MOONLIT"] = {
        ClockTime = 0.35, Brightness = 1.30, Exposure = -0.05, Density = 0.004, Offset = 0.22, Haze = 0.08, Glare = 0,
        Color = Color3.fromRGB(140, 170, 220), Decay = Color3.fromRGB(76, 92, 135), Ambient = Color3.fromRGB(14, 18, 30),
        OutdoorAmbient = Color3.fromRGB(54, 65, 92), Top = Color3.fromRGB(55, 75, 125), Bottom = Color3.fromRGB(80, 90, 125),
        Bloom = 0.045, Contrast = 0.16, Saturation = 0.025, Tint = Color3.fromRGB(210, 225, 255),
    },
    ["DEEP NIGHT"] = {
        ClockTime = 2.1, Brightness = 0.92, Exposure = -0.08, Density = 0.003, Offset = 0.26, Haze = 0.04, Glare = 0,
        Color = Color3.fromRGB(75, 100, 160), Decay = Color3.fromRGB(35, 46, 82), Ambient = Color3.fromRGB(7, 9, 18),
        OutdoorAmbient = Color3.fromRGB(27, 33, 57), Top = Color3.fromRGB(25, 35, 70), Bottom = Color3.fromRGB(42, 45, 68),
        Bloom = 0.035, Contrast = 0.18, Saturation = 0.01, Tint = Color3.fromRGB(190, 210, 255),
    },
    ["OVERCAST"] = {
        ClockTime = 11.2, Brightness = 1.75, Exposure = -0.015, Density = 0.008, Offset = 0.05, Haze = 0.20, Glare = 0.01,
        Color = Color3.fromRGB(205, 214, 224), Decay = Color3.fromRGB(170, 180, 194), Ambient = Color3.fromRGB(48, 50, 54),
        OutdoorAmbient = Color3.fromRGB(112, 118, 126), Top = Color3.fromRGB(188, 198, 210), Bottom = Color3.fromRGB(198, 202, 204),
        Bloom = 0.025, Contrast = 0.055, Saturation = -0.025, Tint = Color3.fromRGB(238, 241, 244),
    },
    ["RAIN MOOD"] = {
        ClockTime = 15.8, Brightness = 1.62, Exposure = -0.02, Density = 0.010, Offset = 0.02, Haze = 0.24, Glare = 0.01,
        Color = Color3.fromRGB(174, 194, 218), Decay = Color3.fromRGB(112, 132, 164), Ambient = Color3.fromRGB(35, 41, 51),
        OutdoorAmbient = Color3.fromRGB(90, 105, 125), Top = Color3.fromRGB(130, 155, 188), Bottom = Color3.fromRGB(150, 160, 175),
        Bloom = 0.02, Contrast = 0.10, Saturation = -0.02, Tint = Color3.fromRGB(225, 235, 250),
    },
    ["MISTY"] = {
        ClockTime = 8.2, Brightness = 1.98, Exposure = 0, Density = 0.014, Offset = 0.01, Haze = 0.36, Glare = 0.08,
        Color = Color3.fromRGB(215, 225, 236), Decay = Color3.fromRGB(165, 180, 205), Ambient = Color3.fromRGB(47, 50, 54),
        OutdoorAmbient = Color3.fromRGB(120, 128, 140), Top = Color3.fromRGB(185, 205, 228), Bottom = Color3.fromRGB(205, 207, 210),
        Bloom = 0.045, Contrast = 0.035, Saturation = -0.01, Tint = Color3.fromRGB(245, 248, 252),
    },
    ["TROPICAL"] = {
        ClockTime = 10.6, Brightness = 2.34, Exposure = 0.035, Density = 0.005, Offset = 0.14, Haze = 0.10, Glare = 0.06,
        Color = Color3.fromRGB(190, 225, 225), Decay = Color3.fromRGB(116, 185, 170), Ambient = Color3.fromRGB(27, 43, 37),
        OutdoorAmbient = Color3.fromRGB(125, 158, 143), Top = Color3.fromRGB(175, 225, 238), Bottom = Color3.fromRGB(218, 242, 206),
        Bloom = 0.065, Contrast = 0.09, Saturation = 0.08, Tint = Color3.fromRGB(244, 255, 245),
    },
    ["FOREST"] = {
        ClockTime = 9.3, Brightness = 2.18, Exposure = 0.015, Density = 0.007, Offset = 0.10, Haze = 0.17, Glare = 0.04,
        Color = Color3.fromRGB(185, 215, 190), Decay = Color3.fromRGB(105, 155, 115), Ambient = Color3.fromRGB(24, 38, 27),
        OutdoorAmbient = Color3.fromRGB(90, 125, 96), Top = Color3.fromRGB(160, 205, 175), Bottom = Color3.fromRGB(205, 225, 185),
        Bloom = 0.04, Contrast = 0.10, Saturation = 0.07, Tint = Color3.fromRGB(238, 250, 236),
    },
    ["DESERT"] = {
        ClockTime = 15.5, Brightness = 2.30, Exposure = 0.04, Density = 0.005, Offset = 0.16, Haze = 0.13, Glare = 0.09,
        Color = Color3.fromRGB(238, 220, 188), Decay = Color3.fromRGB(202, 166, 113), Ambient = Color3.fromRGB(52, 43, 32),
        OutdoorAmbient = Color3.fromRGB(167, 145, 115), Top = Color3.fromRGB(235, 215, 180), Bottom = Color3.fromRGB(255, 213, 158),
        Bloom = 0.065, Contrast = 0.10, Saturation = 0.065, Tint = Color3.fromRGB(255, 248, 232),
    },
    ["ARCTIC"] = {
        ClockTime = 12.0, Brightness = 2.42, Exposure = 0.04, Density = 0.004, Offset = 0.18, Haze = 0.07, Glare = 0.03,
        Color = Color3.fromRGB(202, 230, 255), Decay = Color3.fromRGB(135, 185, 235), Ambient = Color3.fromRGB(27, 37, 49),
        OutdoorAmbient = Color3.fromRGB(122, 150, 180), Top = Color3.fromRGB(190, 225, 255), Bottom = Color3.fromRGB(225, 240, 255),
        Bloom = 0.055, Contrast = 0.10, Saturation = 0.02, Tint = Color3.fromRGB(236, 248, 255),
    },
    ["MYSTIC"] = {
        ClockTime = 20.2, Brightness = 1.55, Exposure = -0.02, Density = 0.006, Offset = 0.16, Haze = 0.12, Glare = 0.05,
        Color = Color3.fromRGB(175, 160, 225), Decay = Color3.fromRGB(90, 70, 160), Ambient = Color3.fromRGB(29, 23, 48),
        OutdoorAmbient = Color3.fromRGB(76, 65, 118), Top = Color3.fromRGB(90, 78, 160), Bottom = Color3.fromRGB(140, 100, 180),
        Bloom = 0.085, Contrast = 0.13, Saturation = 0.055, Tint = Color3.fromRGB(240, 230, 255),
    },
    ["NEON NIGHT"] = {
        ClockTime = 22.1, Brightness = 1.15, Exposure = -0.025, Density = 0.004, Offset = 0.20, Haze = 0.07, Glare = 0.02,
        Color = Color3.fromRGB(110, 165, 220), Decay = Color3.fromRGB(70, 75, 150), Ambient = Color3.fromRGB(12, 17, 28),
        OutdoorAmbient = Color3.fromRGB(42, 54, 84), Top = Color3.fromRGB(35, 55, 105), Bottom = Color3.fromRGB(62, 65, 112),
        Bloom = 0.15, Contrast = 0.18, Saturation = 0.09, Tint = Color3.fromRGB(225, 235, 255),
    },
    ["VOLCANIC"] = {
        ClockTime = 19.4, Brightness = 1.70, Exposure = 0, Density = 0.009, Offset = 0.06, Haze = 0.24, Glare = 0.11,
        Color = Color3.fromRGB(235, 150, 120), Decay = Color3.fromRGB(150, 52, 38), Ambient = Color3.fromRGB(42, 20, 18),
        OutdoorAmbient = Color3.fromRGB(110, 53, 45), Top = Color3.fromRGB(125, 57, 48), Bottom = Color3.fromRGB(205, 78, 44),
        Bloom = 0.12, Contrast = 0.16, Saturation = 0.10, Tint = Color3.fromRGB(255, 235, 220),
    },
    ["DREAM"] = {
        ClockTime = 16.8, Brightness = 2.16, Exposure = 0.02, Density = 0.007, Offset = 0.10, Haze = 0.15, Glare = 0.10,
        Color = Color3.fromRGB(220, 205, 240), Decay = Color3.fromRGB(190, 150, 215), Ambient = Color3.fromRGB(42, 33, 50),
        OutdoorAmbient = Color3.fromRGB(135, 112, 150), Top = Color3.fromRGB(210, 190, 245), Bottom = Color3.fromRGB(255, 190, 205),
        Bloom = 0.10, Contrast = 0.08, Saturation = 0.075, Tint = Color3.fromRGB(255, 242, 250),
    },
}

----------------------------------------------------------------
-- ACTIVE STATE & MOOD SETTINGS
----------------------------------------------------------------
local State = {
    Quality = Config.Quality,
    SelectedMoods = {}, -- Maksimal 2
    Instances = {
        Atmosphere = nil, Bloom = nil, ColorCorrection = nil, SunRays = nil, DOF = nil,
    },
    AccentLights = {},
    Connections = {},
    OriginalCameraFOV = nil,
    Restored = false,
    Stats = {
        Parts = 0, MeshParts = 0, SurfaceAppearances = 0, LightsFound = 0,
        LightsCreated = 0, MaterialsEnhanced = 0, SurfaceColorsEnhanced = 0, LastFPS = 0,
    },
}

-- Tabel untuk menyimpan override pengaturan per mood
local MoodSettings = {}
for name, _ in pairs(Atmospheres) do
    MoodSettings[name] = {
        BrightnessMultiplier = 1.0, -- 1.0 = Sedang, 1.2 = Lumayan Terang, 0.8 = Gelap
        ExposureOffset = 0,
        ContrastOffset = 0,
        SaturationOffset = 0,
        BloomOffset = 0,
        SunRaysOffset = 0,
    }
end

----------------------------------------------------------------
-- INSTANCE MANAGEMENT
----------------------------------------------------------------
local function createEffect(className, name)
    local existing = Lighting:FindFirstChild(name)
    if existing and existing:IsA(className) then
        return existing, false
    end
    if existing then
        existing:Destroy()
    end
    local effect = Instance.new(className)
    effect.Name = name
    effect.Parent = Lighting
    table.insert(Original.Created, effect)
    return effect, true
end

----------------------------------------------------------------
-- LIGHTING CORE
----------------------------------------------------------------
local function configureLightingBase()
    rememberLighting("Brightness")
    rememberLighting("ExposureCompensation")
    rememberLighting("GlobalShadows")
    rememberLighting("ShadowSoftness")
    rememberLighting("EnvironmentDiffuseScale")
    rememberLighting("EnvironmentSpecularScale")
    rememberLighting("Ambient")
    rememberLighting("OutdoorAmbient")
    rememberLighting("ColorShift_Top")
    rememberLighting("ColorShift_Bottom")
    rememberLighting("GeographicLatitude")
    rememberLighting("ClockTime")

    safe(function()
        Lighting.LightingStyle = Enum.LightingStyle.Realistic
    end)

    setProperty(Lighting, "GlobalShadows", true)
    setProperty(Lighting, "Brightness", Config.Brightness)
    setProperty(Lighting, "ExposureCompensation", Config.Exposure)
    setProperty(Lighting, "ShadowSoftness", Config.ShadowSoftness)
    setProperty(Lighting, "EnvironmentDiffuseScale", Config.DiffuseScale)
    setProperty(Lighting, "EnvironmentSpecularScale", Config.SpecularScale)
    setProperty(Lighting, "Ambient", Color3.fromRGB(24, 27, 31))
    setProperty(Lighting, "OutdoorAmbient", Color3.fromRGB(132, 140, 151))

    if hasProperty(Lighting, "PrioritizeLightingQuality") then
        setProperty(Lighting, "PrioritizeLightingQuality", true)
    end
end

----------------------------------------------------------------
-- MOOD BLENDING LOGIC (Maksimal 2 Shaders)
----------------------------------------------------------------
local function GetActiveMood()
    local selected = State.SelectedMoods
    if #selected == 0 then
        return Atmospheres["REALISTIC CLEAR"]
    elseif #selected == 1 then
        local base = Atmospheres[selected[1]]
        local settings = MoodSettings[selected[1]]
        
        -- Apply settings override
        local mood = {}
        for k, v in pairs(base) do mood[k] = v end
        mood.Brightness = base.Brightness * settings.BrightnessMultiplier
        mood.Exposure = base.Exposure + settings.ExposureOffset
        mood.Contrast = base.Contrast + settings.ContrastOffset
        mood.Saturation = base.Saturation + settings.SaturationOffset
        mood.Bloom = base.Bloom + settings.BloomOffset
        mood.SunRays = (base.SunRays or Config.SunRayIntensity) + settings.SunRaysOffset
        return mood
    else
        -- Blend 2 moods
        local moodA = Atmospheres[selected[1]]
        local moodB = Atmospheres[selected[2]]
        local settingsA = MoodSettings[selected[1]]
        local settingsB = MoodSettings[selected[2]]
        
        local blended = {}
        blended.Name = selected[1] .. " + " .. selected[2]
        
        -- Blend numeric values (average) then apply average settings
        for key, value in pairs(moodA) do
            if moodB[key] ~= nil then
                if typeof(value) == "number" then
                    local avg = (value + moodB[key]) / 2
                    if key == "Brightness" then
                        local multAvg = (settingsA.BrightnessMultiplier + settingsB.BrightnessMultiplier) / 2
                        blended[key] = avg * multAvg
                    elseif key == "Exposure" then
                        blended[key] = avg + ((settingsA.ExposureOffset + settingsB.ExposureOffset) / 2)
                    elseif key == "Contrast" then
                        blended[key] = avg + ((settingsA.ContrastOffset + settingsB.ContrastOffset) / 2)
                    elseif key == "Saturation" then
                        blended[key] = avg + ((settingsA.SaturationOffset + settingsB.SaturationOffset) / 2)
                    elseif key == "Bloom" then
                        blended[key] = avg + ((settingsA.BloomOffset + settingsB.BloomOffset) / 2)
                    elseif key == "SunRays" then
                        blended[key] = avg + ((settingsA.SunRaysOffset + settingsB.SunRaysOffset) / 2)
                    else
                        blended[key] = avg
                    end
                elseif typeof(value) == "Color3" then
                    blended[key] = value:Lerp(moodB[key], 0.5)
                elseif typeof(value) == "boolean" then
                    blended[key] = value or moodB[key]
                elseif typeof(value) == "table" then
                    blended[key] = value -- Fallback to moodA's table (e.g., Drift)
                else
                    blended[key] = value
                end
            else
                blended[key] = value
            end
        end
        return blended
    end
end

----------------------------------------------------------------
-- ATMOSPHERE & SHADER CORE
----------------------------------------------------------------
local function configureAtmosphere()
    if not Config.Atmosphere then
        if State.Instances.Atmosphere then
            State.Instances.Atmosphere.Enabled = false
        end
        return
    end

    local atmosphere = State.Instances.Atmosphere
    if not atmosphere then
        atmosphere = createEffect("Atmosphere", "URV4_Atmosphere")
        State.Instances.Atmosphere = atmosphere
    end

    local mood = GetActiveMood()
    setProperty(atmosphere, "Density", mood.Density)
    setProperty(atmosphere, "Offset", mood.Offset)
    setProperty(atmosphere, "Haze", mood.Haze)
    setProperty(atmosphere, "Glare", mood.Glare)
    setProperty(atmosphere, "Color", mood.Color)
    setProperty(atmosphere, "Decay", mood.Decay)
    setProperty(atmosphere, "Enabled", true)
end

local function configureShaders()
    if not Config.Shaders then
        for _, effect in pairs(State.Instances) do
            if effect and effect:IsA("PostEffect") then
                effect.Enabled = false
            end
        end
        return
    end

    local mood = GetActiveMood()

    local bloom = State.Instances.Bloom
    if not bloom then
        bloom = createEffect("BloomEffect", "URV4_Bloom")
        State.Instances.Bloom = bloom
    end
    setProperty(bloom, "Intensity", mood.Bloom)
    setProperty(bloom, "Size", mood.BloomSize or Config.BloomSize)
    setProperty(bloom, "Threshold", mood.BloomThreshold or Config.BloomThreshold)
    setProperty(bloom, "Enabled", true)

    local color = State.Instances.ColorCorrection
    if not color then
        color = createEffect("ColorCorrectionEffect", "URV4_ColorGrade")
        State.Instances.ColorCorrection = color
    end
    setProperty(color, "Brightness", mood.GradeBrightness or 0)
    setProperty(color, "Contrast", mood.Contrast)
    setProperty(color, "Saturation", mood.Saturation)
    setProperty(color, "TintColor", mood.Tint)
    setProperty(color, "Enabled", true)

    local sun = State.Instances.SunRays
    if not sun then
        sun = createEffect("SunRaysEffect", "URV4_SunRays")
        State.Instances.SunRays = sun
    end
    setProperty(sun, "Intensity", mood.SunRays or Config.SunRayIntensity)
    setProperty(sun, "Spread", Config.SunRaySpread)
    setProperty(sun, "Enabled", true)

    local dof = State.Instances.DOF
    if not dof then
        dof = createEffect("DepthOfFieldEffect", "URV4_DepthOfField")
        State.Instances.DOF = dof
    end
    setProperty(dof, "FocusDistance", mood.DOFFocus or Config.DOFFocus)
    setProperty(dof, "InFocusRadius", mood.DOFRadius or Config.DOFNear)
    setProperty(dof, "NearIntensity", Config.DOFStrength)
    setProperty(dof, "FarIntensity", mood.DOFFar or Config.DOFStrength)
    setProperty(dof, "Enabled", mood.DOFFar ~= nil or Config.DOFEnabled)
end

local function configureMoodLighting()
    local mood = GetActiveMood()
    setProperty(Lighting, "ClockTime", mood.ClockTime)
    setProperty(Lighting, "Brightness", mood.Brightness)
    setProperty(Lighting, "ExposureCompensation", mood.Exposure)
    setProperty(Lighting, "ShadowSoftness", mood.ShadowSoftness or Config.ShadowSoftness)
    setProperty(Lighting, "Ambient", mood.Ambient)
    setProperty(Lighting, "OutdoorAmbient", mood.OutdoorAmbient)
    setProperty(Lighting, "ColorShift_Top", mood.Top)
    setProperty(Lighting, "ColorShift_Bottom", mood.Bottom)
    configureAtmosphere()
    configureShaders()
end

----------------------------------------------------------------
-- MATERIAL CLASSIFICATION & ENHANCEMENT
----------------------------------------------------------------
local function classifyPart(part)
    local name = string.lower(part.Name)
    local material = getProperty(part, "Material", nil)
    local result = { Type = "DEFAULT", Reflectance = nil, ColorBias = nil, Preserve = false }

    if not material then return result end

    if material == Enum.Material.Metal then result.Type = "METAL"; result.Reflectance = 0.14; return result end
    if material == Enum.Material.Glass then result.Type = "GLASS"; result.Reflectance = 0.08; result.Preserve = true; return result end
    if material == Enum.Material.Neon then result.Type = "EMISSIVE"; result.Reflectance = 0; result.Preserve = true; return result end
    if material == Enum.Material.Wood or material == Enum.Material.WoodPlanks then result.Type = "WOOD"; return result end
    if material == Enum.Material.Grass or material == Enum.Material.LeafyGrass then result.Type = "VEGETATION"; return result end
    if material == Enum.Material.Sand then result.Type = "SAND"; return result end
    if material == Enum.Material.Snow or material == Enum.Material.Ice then result.Type = "COLD"; return result end
    if material == Enum.Material.Rock or material == Enum.Material.Slate or material == Enum.Material.Basalt then result.Type = "ROCK"; return result end
    if material == Enum.Material.Concrete or material == Enum.Material.Asphalt then result.Type = "ARCHITECTURE"; return result end
    if material == Enum.Material.CrackedLava or material == Enum.Material.Lava then result.Type = "VOLCANIC"; return result end

    if name:find("gold") or name:find("coin") or name:find("treasure") or name:find("bronze") or name:find("brass") then
        result.Type = "GOLD"; result.Reflectance = 0.16; return result
    end
    if name:find("steel") or name:find("iron") or name:find("blade") or name:find("machine") or name:find("metal") then
        result.Type = "METAL"; result.Reflectance = 0.14; return result
    end
    if name:find("crystal") or name:find("gem") or name:find("diamond") then
        result.Type = "CRYSTAL"; result.Reflectance = 0.12; return result
    end
    if name:find("egg") then result.Type = "EGG"; return result end
    if name:find("water") or name:find("ocean") or name:find("river") or name:find("pool") then
        result.Type = "WATER"; result.Reflectance = 0.10; result.Preserve = true; return result
    end

    return result
end

local function isVisualPart(part)
    if not part:IsA("BasePart") or part.Transparency >= 0.98 then return false end
    local name = string.lower(part.Name)
    local blocked = {"hitbox", "hurtbox", "trigger", "zoneprobe", "collider", "collision", "invisible", "interactionbox", "promptpart", "clickdetector", "raycast"}
    for _, token in ipairs(blocked) do
        if name:find(token, 1, true) then return false end
    end
    return true
end

local function enhancePartMaterial(part)
    if not isVisualPart(part) then return end
    rememberPart(part)
    State.Stats.Parts += 1
    if part:IsA("MeshPart") then State.Stats.MeshParts += 1 end

    local info = classifyPart(part)
    local materialVariant = getProperty(part, "MaterialVariant", "")
    local hasVariant = materialVariant and materialVariant ~= ""

    if not hasVariant and info.Type == "DEFAULT" then
        local current = getProperty(part, "Material", nil)
        if current == Enum.Material.Plastic then
            setProperty(part, "Material", Enum.Material.SmoothPlastic)
            State.Stats.MaterialsEnhanced += 1
        end
    end

    if info.Reflectance ~= nil then
        local currentReflectance = getProperty(part, "Reflectance", 0)
        if currentReflectance < info.Reflectance then
            setProperty(part, "Reflectance", info.Reflectance)
            State.Stats.MaterialsEnhanced += 1
        end
    end

    if hasProperty(part, "CastShadow") then
        setProperty(part, "CastShadow", true)
    end
end

local function enhanceSurfaceAppearance(surface)
    if not surface:IsA("SurfaceAppearance") then return end
    rememberSurfaceAppearance(surface)
    State.Stats.SurfaceAppearances += 1

    local currentColor = getProperty(surface, "Color", Color3.new(1, 1, 1))
    if Config.PreserveOriginalColors then
        local lift = Config.ColorInfluence
        local neutral = Color3.fromRGB(255, 255, 255)
        local result = currentColor:Lerp(neutral, lift)
        if result ~= currentColor then
            setProperty(surface, "Color", result)
            State.Stats.SurfaceColorsEnhanced += 1
        end
    end

    if hasProperty(surface, "EmissiveStrength") then
        local emissive = getProperty(surface, "EmissiveStrength", 0)
        if emissive > 0 then
            setProperty(surface, "EmissiveStrength", math.clamp(emissive, 0, 8))
        end
    end
end

local function scanVisualAssets()
    State.Stats.Parts = 0; State.Stats.MeshParts = 0; State.Stats.SurfaceAppearances = 0
    State.Stats.MaterialsEnhanced = 0; State.Stats.SurfaceColorsEnhanced = 0
    local descendants = Workspace:GetDescendants()
    for i, object in ipairs(descendants) do
        if object:IsA("SurfaceAppearance") then
            enhanceSurfaceAppearance(object)
        elseif object:IsA("BasePart") then
            enhancePartMaterial(object)
        end
        if i % 500 == 0 then task.wait() end
    end
end

----------------------------------------------------------------
-- LIGHT SEMANTICS & ACCENT LIGHTS
----------------------------------------------------------------
local function isLightSourcePart(part)
    if not isVisualPart(part) then return false end
    local name = string.lower(part.Name)
    local tokens = {"lamp", "light", "lantern", "torch", "fire", "flame", "bulb", "neon", "screen", "monitor", "sign", "crystal", "portal", "glow", "energy", "lava"}
    for _, token in ipairs(tokens) do
        if name:find(token, 1, true) then return true end
    end
    if getProperty(part, "Material", nil) == Enum.Material.Neon then return true end
    return false
end

local function getLightColor(part)
    local material = getProperty(part, "Material", nil)
    if material == Enum.Material.Neon then return getProperty(part, "Color", Color3.new(1, 1, 1)) end
    local name = string.lower(part.Name)
    if name:find("fire") or name:find("flame") or name:find("torch") or name:find("lava") then return Color3.fromRGB(255, 170, 90) end
    if name:find("crystal") or name:find("ice") then return Color3.fromRGB(150, 210, 255) end
    if name:find("neon") or name:find("energy") or name:find("portal") then return getProperty(part, "Color", Color3.fromRGB(120, 180, 255)) end
    return getProperty(part, "Color", Color3.fromRGB(255, 225, 180))
end

local function clearAccentLights()
    for _, record in ipairs(State.AccentLights) do
        if record.Light and record.Light.Parent then record.Light:Destroy() end
        if record.Attachment and record.Attachment.Parent then record.Attachment:Destroy() end
    end
    table.clear(State.AccentLights)
end

local function createAccentLight(part)
    if #State.AccentLights >= Config.MaxAccentLights then return end
    if not isLightSourcePart(part) then return end
    local existingLight = part:FindFirstChild("URV4_AccentLight")
    if existingLight and existingLight:IsA("PointLight") then return end

    local attachment = Instance.new("Attachment")
    attachment.Name = "URV4_AccentAttachment"
    attachment.Parent = part

    local light = Instance.new("PointLight")
    light.Name = "URV4_AccentLight"
    light.Color = getLightColor(part)
    light.Brightness = 0.65
    light.Range = 12
    light.Shadows = true
    light.Enabled = true
    light.Parent = attachment

    table.insert(State.AccentLights, { Source = part, Attachment = attachment, Light = light })
    State.Stats.LightsCreated += 1
end

local function enhanceExistingLights()
    State.Stats.LightsFound = 0
    for _, object in ipairs(Workspace:GetDescendants()) do
        if object:IsA("PointLight") or object:IsA("SpotLight") or object:IsA("SurfaceLight") then
            State.Stats.LightsFound += 1
            setProperty(object, "Shadows", true)
            local brightness = getProperty(object, "Brightness", 1)
            if brightness > 0 then setProperty(object, "Brightness", math.max(brightness, 0.1)) end
        end
    end
end

local function scanAccentLights()
    clearAccentLights()
    State.Stats.LightsCreated = 0
    local candidates = {}
    for _, object in ipairs(Workspace:GetDescendants()) do
        if object:IsA("BasePart") and isLightSourcePart(object) then
            table.insert(candidates, object)
        end
    end
    Camera = Workspace.CurrentCamera
    if not Camera then return end
    table.sort(candidates, function(a, b)
        local da = (a.Position - Camera.CFrame.Position).Magnitude
        local db = (b.Position - Camera.CFrame.Position).Magnitude
        return da < db
    end)
    for _, part in ipairs(candidates) do
        local distance = (part.Position - Camera.CFrame.Position).Magnitude
        if distance <= Config.LightDistance then createAccentLight(part) end
        if #State.AccentLights >= Config.MaxAccentLights then break end
    end
end

local function preserveDetailGeometry()
    for _, object in ipairs(Workspace:GetDescendants()) do
        if object:IsA("MeshPart") and isVisualPart(object) then
            setProperty(object, "CastShadow", true)
        end
    end
end

----------------------------------------------------------------
-- QUALITY APPLICATION
----------------------------------------------------------------
local function applyQuality(level)
    level = math.clamp(math.floor(level or 10), 1, 10)
    local q = QualityLevels[level]
    if not q then return end
    State.Quality = level
    Config.Brightness = q.Brightness; Config.Exposure = q.Exposure; Config.ShadowSoftness = q.ShadowSoftness
    Config.DiffuseScale = q.Diffuse; Config.SpecularScale = q.Specular
    Config.AtmosphereDensity = q.AtmosphereDensity; Config.AtmosphereHaze = q.AtmosphereHaze
    Config.BloomIntensity = q.Bloom; Config.Contrast = q.Contrast; Config.Saturation = q.Saturation
    Config.SunRayIntensity = q.SunRays; Config.DetailDistance = q.DetailDistance
    Config.LightDistance = q.LightDistance; Config.MaxAccentLights = q.MaxLights
    configureLightingBase()
    configureMoodLighting()
    task.spawn(scanAccentLights)
end

----------------------------------------------------------------
-- NOSTALGIA FX (Flare, Light Leak, Vignette)
----------------------------------------------------------------
local NostalgiaFX = {}
do
    local SoundService = game:GetService("SoundService")
    local MOOD_NAME = "NOSTALGIC SORE"
    local GLOW_IMAGE = ""
    local AMBIENCE_SOUND_ID = ""
    local AMBIENCE_VOLUME = 0.22
    local MOTE_COUNT = 28

    local FLARE_DEFS = {
        { pos = 0.00, size = 0.36, color = Color3.fromRGB(255, 196, 112), alpha = 0.90 },
        { pos = 0.00, size = 0.15, color = Color3.fromRGB(255, 232, 170), alpha = 0.76 },
        { pos = 0.55, size = 0.07, color = Color3.fromRGB(255, 170, 90),  alpha = 0.88 },
        { pos = 1.00, size = 0.12, color = Color3.fromRGB(255, 190, 110), alpha = 0.92 },
        { pos = 1.45, size = 0.05, color = Color3.fromRGB(255, 215, 150), alpha = 0.86 },
        { pos = 1.85, size = 0.20, color = Color3.fromRGB(255, 160, 85),  alpha = 0.94 },
    }

    local gui, vignetteGroup, leakGroup, flareGroup, moteGroup
    local streakMain, streakSoft, halo
    local flares, motes = {}, {}
    local connection, active = false, false
    local intensity, sunVisible, driftClock = 0, 0, 0
    local sound, cloudsState
    local rng = Random.new(1987)
    local washGroup, washGradient, whiteout
    local windowGroup, windowBox, windowPanes = {}, {}, {}
    local windowX, windowY, bodyAttachment, bodyLight, bodyBrightness, castTimer = 0, 0, nil, nil, 0, 0

    local function makeGroup(parent)
        local g = Instance.new("CanvasGroup")
        g.BackgroundTransparency = 1; g.Size = UDim2.fromScale(1, 1); g.GroupTransparency = 1
        g.Active = false; g.Parent = parent
        return g
    end

    local function edge(parent, pos, size, rotation, alpha)
        local f = Instance.new("Frame")
        f.BorderSizePixel = 0; f.BackgroundColor3 = Color3.fromRGB(38, 16, 6); f.Position = pos; f.Size = size; f.Parent = parent
        local g = Instance.new("UIGradient")
        g.Rotation = rotation
        g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, alpha), NumberSequenceKeypoint.new(1, 1) })
        g.Parent = f
    end

    local function fullGradientFrame(parent, color, rotation, sequence)
        local f = Instance.new("Frame")
        f.BorderSizePixel = 0; f.BackgroundColor3 = color; f.Size = UDim2.fromScale(1, 1); f.Parent = parent
        local g = Instance.new("UIGradient")
        g.Rotation = rotation; g.Transparency = sequence; g.Parent = f
        return f, g
    end

    local function makeStreak(parent, color, alpha)
        local f = Instance.new("Frame")
        f.BorderSizePixel = 0; f.AnchorPoint = Vector2.new(0.5, 0.5); f.BackgroundColor3 = color; f.Parent = parent
        local g = Instance.new("UIGradient")
        g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, alpha), NumberSequenceKeypoint.new(1, 1) })
        g.Parent = f
        return f
    end

    local function build()
        gui = Instance.new("ScreenGui")
        gui.Name = ROOT_NAME .. "_Nostalgia"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
        gui.DisplayOrder = 5; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.Parent = PlayerGui

        vignetteGroup = makeGroup(gui)
        edge(vignetteGroup, UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.34), 90, 0.52)
        edge(vignetteGroup, UDim2.fromScale(0, 0.66), UDim2.fromScale(1, 0.34), 270, 0.42)
        edge(vignetteGroup, UDim2.fromScale(0, 0), UDim2.fromScale(0.24, 1), 0, 0.60)
        edge(vignetteGroup, UDim2.fromScale(0.76, 0), UDim2.fromScale(0.24, 1), 180, 0.60)

        leakGroup = makeGroup(gui)
        fullGradientFrame(leakGroup, Color3.fromRGB(255, 190, 100), 145, NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.78), NumberSequenceKeypoint.new(0.55, 0.94), NumberSequenceKeypoint.new(1, 1) }))
        fullGradientFrame(leakGroup, Color3.fromRGB(70, 100, 140), 325, NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.90), NumberSequenceKeypoint.new(0.5, 1), NumberSequenceKeypoint.new(1, 1) }))

        flareGroup = makeGroup(gui)
        for i, def in ipairs(FLARE_DEFS) do
            local f
            if GLOW_IMAGE ~= "" then
                f = Instance.new("ImageLabel"); f.BackgroundTransparency = 1; f.Image = GLOW_IMAGE
                f.ImageColor3 = def.color; f.ImageTransparency = def.alpha - 0.25
            else
                f = Instance.new("Frame"); f.BorderSizePixel = 0; f.BackgroundColor3 = def.color; f.BackgroundTransparency = def.alpha
                local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = f
            end
            f.AnchorPoint = Vector2.new(0.5, 0.5); f.Parent = flareGroup
            flares[i] = { Object = f, Def = def }
        end

        streakSoft = makeStreak(flareGroup, Color3.fromRGB(255, 170, 90), 0.84)
        streakMain = makeStreak(flareGroup, Color3.fromRGB(255, 225, 160), 0.40)

        halo = Instance.new("Frame"); halo.BackgroundTransparency = 1; halo.AnchorPoint = Vector2.new(0.5, 0.5); halo.Parent = flareGroup
        local haloCorner = Instance.new("UICorner"); haloCorner.CornerRadius = UDim.new(1, 0); haloCorner.Parent = halo
        local haloStroke = Instance.new("UIStroke"); haloStroke.Color = Color3.fromRGB(255, 190, 110); haloStroke.Thickness = 2; haloStroke.Transparency = 0.82; haloStroke.Parent = halo

        moteGroup = makeGroup(gui)
        for i = 1, MOTE_COUNT do
            local d = rng:NextInteger(2, 6)
            local f = Instance.new("Frame"); f.BorderSizePixel = 0; f.Size = UDim2.fromOffset(d, d)
            f.BackgroundColor3 = Color3.fromRGB(255, 210, 140):Lerp(Color3.fromRGB(255, 238, 195), rng:NextNumber()); f.Parent = moteGroup
            local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = f
            motes[i] = { Object = f, x = rng:NextNumber(), y = rng:NextNumber(), vx = rng:NextNumber(-0.004, 0.010), vy = -rng:NextNumber(0.003, 0.012), phase = rng:NextNumber(0, math.pi * 2), speed = rng:NextNumber(0.6, 1.8) }
        end

        washGroup = makeGroup(gui)
        local washFrame
        washFrame, washGradient = fullGradientFrame(washGroup, Color3.fromRGB(255, 255, 255), 0, NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.38), NumberSequenceKeypoint.new(0.45, 0.70), NumberSequenceKeypoint.new(1, 0.93) }))
        washGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 218, 125)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 150, 58)), ColorSequenceKeypoint.new(1, Color3.fromRGB(235, 100, 38)) })

        whiteout = Instance.new("Frame"); whiteout.BorderSizePixel = 0; whiteout.BackgroundColor3 = Color3.fromRGB(255, 226, 160)
        whiteout.BackgroundTransparency = 1; whiteout.Size = UDim2.fromScale(1, 1); whiteout.Parent = washGroup

        windowGroup = makeGroup(gui)
        windowBox = Instance.new("Frame"); windowBox.BackgroundTransparency = 1; windowBox.AnchorPoint = Vector2.new(0.5, 0.5); windowBox.Rotation = -12; windowBox.Parent = windowGroup
        for row = 0, 1 do
            for col = 0, 1 do
                local pane = Instance.new("Frame"); pane.BorderSizePixel = 0; pane.BackgroundColor3 = Color3.fromRGB(255, 196, 108)
                pane.Size = UDim2.fromScale(0.47, 0.47); pane.Position = UDim2.fromScale(col * 0.53, row * 0.53); pane.Parent = windowBox
                local g = Instance.new("UIGradient"); g.Rotation = 90; g.Transparency = NumberSequence.new(0.72, 0.90); g.Parent = pane
                local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(255, 186, 104); stroke.Thickness = 7; stroke.Transparency = 0.92; stroke.Parent = pane
                table.insert(windowPanes, { Object = pane, Gradient = g })
            end
        end
    end

    local function applyClouds(on)
        local terrain = Workspace:FindFirstChildOfClass("Terrain")
        if not terrain then return end
        if on then
            if not cloudsState then
                local existing = terrain:FindFirstChildOfClass("Clouds")
                if existing then
                    cloudsState = { Object = existing, Owned = false, Saved = { Color = existing.Color, Cover = existing.Cover, Density = existing.Density, Enabled = existing.Enabled } }
                else
                    local c = Instance.new("Clouds"); c.Name = "URV4_Clouds"; c.Parent = terrain
                    cloudsState = { Object = c, Owned = true }
                end
            end
            local c = cloudsState.Object
            setProperty(c, "Color", Color3.fromRGB(255, 176, 120)); setProperty(c, "Cover", 0.55); setProperty(c, "Density", 0.55); setProperty(c, "Enabled", true)
        elseif cloudsState then
            if cloudsState.Owned then
                if cloudsState.Object.Parent then cloudsState.Object:Destroy() end
            else
                for property, value in pairs(cloudsState.Saved) do setProperty(cloudsState.Object, property, value) end
            end
            cloudsState = nil
        end
    end

    local function startAmbience()
        if AMBIENCE_SOUND_ID == "" or sound then return end
        sound = Instance.new("Sound"); sound.Name = "URV4_NostalgiaAmbience"; sound.SoundId = AMBIENCE_SOUND_ID
        sound.Looped = true; sound.Volume = 0; sound.Parent = SoundService; sound:Play()
    end

    local function updateBody(dt, sunDir, strength)
        local char = Player.Character; local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        if not bodyAttachment or not bodyAttachment.Parent then
            bodyAttachment = Instance.new("Attachment"); bodyAttachment.Name = "URV4_WarmBodyAttachment"; bodyAttachment.Parent = Workspace.Terrain
            bodyLight = Instance.new("PointLight"); bodyLight.Name = "URV4_WarmBodyLight"; bodyLight.Color = Color3.fromRGB(255, 160, 80)
            bodyLight.Range = 16; bodyLight.Brightness = 0; bodyLight.Shadows = false; bodyLight.Parent = bodyAttachment
        end
        bodyAttachment.WorldPosition = root.Position + sunDir * 7 + Vector3.new(0, 1.5, 0)
        local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances = { char }
        local covered = Workspace:Raycast(root.Position + Vector3.new(0, 2, 0), sunDir * 300, params) ~= nil
        local elevation = math.clamp(sunDir.Y * 4 + 0.35, 0, 1)
        local target = covered and 0 or (1.2 * elevation * strength)
        bodyBrightness = lerp(bodyBrightness, target, math.min(1, dt * 2.5)); bodyLight.Brightness = bodyBrightness
        castTimer += dt
        if castTimer >= 2 then
            castTimer = 0
            for _, d in ipairs(char:GetDescendants()) do if d:IsA("BasePart") then d.CastShadow = true end end
        end
    end

    local function stop()
        if connection then connection:Disconnect(); connection = nil end
        if gui then gui.Enabled = false end
        if sound then sound:Stop(); sound:Destroy(); sound = nil end
        applyClouds(false)
        if bodyAttachment then bodyAttachment:Destroy(); bodyAttachment = nil; bodyLight = nil end
        bodyBrightness = 0
    end

    local function update(dt)
        local cam = Workspace.CurrentCamera
        if not cam or not gui then return end
        intensity = lerp(intensity, active and 1 or 0, math.min(1, dt * 1.5))
        if not active and intensity < 0.01 then stop(); return end

        local mood = Atmospheres[MOOD_NAME]
        local drift = mood and mood.Drift
        if active and drift then
            driftClock += dt
            local phase = (driftClock / (drift.Minutes * 60)) % 2
            local t = phase < 1 and phase or (2 - phase)
            t = t * t * (3 - 2 * t)
            local breathing = math.sin(os.clock() * 0.7) * 0.02
            setProperty(Lighting, "ClockTime", lerp(drift.Clock0, drift.Clock1, t))
            setProperty(Lighting, "Brightness", lerp(drift.Bright0, drift.Bright1, t) + breathing)
            setProperty(Lighting, "ExposureCompensation", lerp(drift.Exp0, drift.Exp1, t))
        end

        local camPos = cam.CFrame.Position
        local sunDir = Lighting:GetSunDirection()
        local facing = math.clamp(cam.CFrame.LookVector:Dot(sunDir), 0, 1)
        local screenPoint, onScreen = cam:WorldToViewportPoint(camPos + sunDir * 1000)
        local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances = { Player.Character }
        local blocked = Workspace:Raycast(camPos, sunDir * 2000, params) ~= nil
        local target = (onScreen and screenPoint.Z > 0 and not blocked) and 1 or 0
        sunVisible = lerp(sunVisible, target, math.min(1, dt * 3))

        local size = cam.ViewportSize
        local sunPos = Vector2.new(screenPoint.X, screenPoint.Y)
        local axis = (size / 2) - sunPos
        local base = math.min(size.X, size.Y)

        for _, item in ipairs(flares) do
            local p = sunPos + axis * item.Def.pos
            local d = base * item.Def.size
            item.Object.Position = UDim2.fromOffset(p.X, p.Y); item.Object.Size = UDim2.fromOffset(d, d)
        end

        streakMain.Position = UDim2.fromOffset(sunPos.X, sunPos.Y); streakMain.Size = UDim2.fromOffset(size.X * 0.75, math.max(2, base * 0.006))
        streakSoft.Position = UDim2.fromOffset(sunPos.X, sunPos.Y); streakSoft.Size = UDim2.fromOffset(size.X * 0.5, math.max(6, base * 0.03))
        halo.Position = UDim2.fromOffset(sunPos.X, sunPos.Y); halo.Size = UDim2.fromOffset(base * 0.5, base * 0.5)

        local now = os.clock()
        local visibleCount = math.floor(#motes * State.Quality / 10)
        for i, m in ipairs(motes) do
            local show = i <= visibleCount
            m.Object.Visible = show
            if show then
                m.x = (m.x + m.vx * dt) % 1; m.y = (m.y + m.vy * dt) % 1; m.Object.Position = UDim2.fromScale(m.x, m.y)
                local twinkle = 0.5 + 0.5 * math.sin(now * m.speed + m.phase)
                m.Object.BackgroundTransparency = 1 - (0.15 + 0.55 * twinkle)
            end
        end

        local breathe = 0.5 + 0.5 * math.sin(now * 0.55)
        vignetteGroup.GroupTransparency = 1 - intensity * 0.95
        leakGroup.GroupTransparency = 1 - intensity * (0.55 + 0.20 * breathe)
        flareGroup.GroupTransparency = 1 - intensity * sunVisible * (0.35 + 0.65 * facing)
        moteGroup.GroupTransparency = 1 - intensity * (0.30 + 0.70 * facing)

        local f1 = facing; local f2 = facing * facing; local f3 = f2 * facing
        local exposureMask = intensity * (0.5 + 0.5 * sunVisible)
        washGradient.Rotation = math.deg(math.atan2(axis.Y, axis.X))
        washGroup.GroupTransparency = 1 - exposureMask * (0.10 + 0.80 * f2)
        local whiteAmount = math.clamp((facing - 0.88) / 0.12, 0, 1)
        whiteout.BackgroundTransparency = 1 - 0.30 * whiteAmount * whiteAmount * sunVisible

        if active and mood then
            setProperty(State.Instances.Bloom, "Intensity", mood.Bloom + 0.30 * f3 * sunVisible)
            setProperty(State.Instances.SunRays, "Intensity", (mood.SunRays or Config.SunRayIntensity) + 0.22 * f2 * sunVisible)
            local grade = State.Instances.ColorCorrection
            setProperty(grade, "TintColor", mood.Tint:Lerp(Color3.fromRGB(255, 186, 112), 0.6 * f2 * intensity))
            setProperty(grade, "Saturation", mood.Saturation + 0.10 * f2)
            setProperty(grade, "Brightness", (mood.GradeBrightness or 0) + 0.035 * f3 * sunVisible)
            setProperty(State.Instances.Atmosphere, "Glare", math.min(1, mood.Glare + 0.40 * f2))
        end

        local center = size / 2
        local wcenter = center + axis * 0.85
        local wx = math.clamp(wcenter.X, size.X * 0.2, size.X * 0.8)
        local wy = math.clamp(wcenter.Y, size.Y * 0.3, size.Y * 0.75)
        windowX = windowX and lerp(windowX, wx, math.min(1, dt * 3)) or wx
        windowY = windowY and lerp(windowY, wy, math.min(1, dt * 3)) or wy
        local ww = base * 0.62
        windowBox.Position = UDim2.fromOffset(windowX + math.sin(now * 0.23) * base * 0.012, windowY + math.cos(now * 0.19) * base * 0.010)
        windowBox.Size = UDim2.fromOffset(ww * 1.15, ww); windowBox.Rotation = -12 + math.sin(now * 0.2) * 1.2

        for i, pane in ipairs(windowPanes) do
            local a = 0.72 + 0.07 * math.sin(now * 0.45 + i * 1.7)
            pane.Gradient.Transparency = NumberSequence.new(a, a + 0.17)
        end
        windowGroup.GroupTransparency = 1 - intensity * (0.30 + 0.70 * f1) * (0.6 + 0.4 * sunVisible)
        updateBody(dt, sunDir, intensity)
        if sound then sound.Volume = AMBIENCE_VOLUME * intensity end
    end

    function NostalgiaFX.SetEnabled(on)
        local wasActive = active; active = on and true or false
        if active then
            if not gui or not gui.Parent then
                table.clear(flares); table.clear(motes); table.clear(windowPanes); build()
            end
            if not wasActive then driftClock = 0 end
            gui.Enabled = true; applyClouds(true); startAmbience()
            if not connection then connection = RunService.RenderStepped:Connect(update) end
        end
    end

    function NostalgiaFX.Destroy()
        active = false; intensity = 0; stop()
        if gui then gui:Destroy(); gui = nil end
        table.clear(flares); table.clear(motes); table.clear(windowPanes)
    end
end

----------------------------------------------------------------
-- MOOD APPLICATION & PUBLIC API
----------------------------------------------------------------
local function applyAtmosphere()
    configureLightingBase()
    configureMoodLighting()
    local activeMoods = State.SelectedMoods
    local hasNostalgic = false
    for _, name in ipairs(activeMoods) do
        if name == "NOSTALGIC SORE" then hasNostalgic = true; break end
    end
    NostalgiaFX.SetEnabled(hasNostalgic and Config.Shaders)
end

local API = {}
function API.SetQuality(level) applyQuality(level) end
function API.GetQuality() return State.Quality end

function API.ToggleMood(name)
    if not Atmospheres[name] then return false end
    local idx = table.find(State.SelectedMoods, name)
    if idx then
        table.remove(State.SelectedMoods, idx)
    else
        if #State.SelectedMoods >= 2 then
            table.remove(State.SelectedMoods, 1)
        end
        table.insert(State.SelectedMoods, name)
    end
    applyAtmosphere()
    return true
end

function API.GetActiveMoods() return State.SelectedMoods end

function API.SetMoodPreset(moodName, preset)
    if not MoodSettings[moodName] then return false end
    local settings = MoodSettings[moodName]
    if preset == "Lumayan Terang" then
        settings.BrightnessMultiplier = 1.25; settings.ExposureOffset = 0.05
    elseif preset == "Sedang" then
        settings.BrightnessMultiplier = 1.0; settings.ExposureOffset = 0
    elseif preset == "Gelap" then
        settings.BrightnessMultiplier = 0.75; settings.ExposureOffset = -0.05
    end
    applyAtmosphere()
    return true
end

function API.SetMoodSlider(moodName, sliderName, value)
    if not MoodSettings[moodName] then return false end
    MoodSettings[moodName][sliderName] = value
    applyAtmosphere()
    return true
end

function API.GetStats() return State.Stats end

function API.RefreshDetails()
    scanVisualAssets(); preserveDetailGeometry(); enhanceExistingLights(); scanAccentLights()
end

function API.Rebuild()
    configureLightingBase(); configureMoodLighting(); API.RefreshDetails()
end

local function restoreOriginal()
    if State.Restored then return end
    State.Restored = true
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
    clearAccentLights(); NostalgiaFX.Destroy()
    for _, instance in ipairs(Original.Created) do
        if instance and instance.Parent then instance:Destroy() end
    end
    if State.OriginalCameraFOV and Camera then
        setProperty(Camera, "FieldOfView", State.OriginalCameraFOV)
    end
end
API.Restore = restoreOriginal

----------------------------------------------------------------
-- UI SYSTEM (MAIN PANEL + SETTINGS PANEL)
----------------------------------------------------------------
local function createUI()
    if not Config.ShowUI then return end

    -- Main Panel
    local gui = Instance.new("ScreenGui")
    gui.Name = ROOT_NAME; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.Parent = PlayerGui

    local panel = Instance.new("Frame")
    panel.Name = "RendererPanel"; panel.Size = UDim2.fromOffset(420, 500)
    panel.Position = UDim2.new(0, 22, 0.5, -250)
    panel.BackgroundColor3 = Color3.fromRGB(15, 17, 22); panel.BackgroundTransparency = 0.05; panel.BorderSizePixel = 0; panel.Parent = gui

    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 14); corner.Parent = panel
    local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(95, 105, 125); stroke.Transparency = 0.55; stroke.Thickness = 1; stroke.Parent = panel

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1; title.Size = UDim2.new(1, -30, 0, 34); title.Position = UDim2.fromOffset(15, 12)
    title.Font = Enum.Font.GothamBold; title.TextSize = 18; title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = Color3.fromRGB(245, 248, 255); title.Text = "ULTRA REALISTIC RENDERER V4"; title.Parent = panel

    local subtitle = Instance.new("TextLabel")
    subtitle.BackgroundTransparency = 1; subtitle.Size = UDim2.new(1, -30, 0, 22); subtitle.Position = UDim2.fromOffset(15, 43)
    subtitle.Font = Enum.Font.Gotham; subtitle.TextSize = 11; subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.TextColor3 = Color3.fromRGB(160, 170, 188); subtitle.Text = "REALISM • SUASANA • SHADERS • DETAIL"; subtitle.Parent = panel

    -- Quality Section
    local qualityTitle = Instance.new("TextLabel")
    qualityTitle.BackgroundTransparency = 1; qualityTitle.Size = UDim2.new(1, -30, 0, 22); qualityTitle.Position = UDim2.fromOffset(15, 76)
    qualityTitle.Font = Enum.Font.GothamBold; qualityTitle.TextSize = 12; qualityTitle.TextXAlignment = Enum.TextXAlignment.Left
    qualityTitle.TextColor3 = Color3.fromRGB(210, 218, 232); qualityTitle.Text = "QUALITY 1–10"; qualityTitle.Parent = panel

    local qualityHolder = Instance.new("Frame")
    qualityHolder.BackgroundTransparency = 1; qualityHolder.Size = UDim2.new(1, -30, 0, 70); qualityHolder.Position = UDim2.fromOffset(15, 100); qualityHolder.Parent = panel
    local grid = Instance.new("UIGridLayout"); grid.CellSize = UDim2.fromOffset(64, 30); grid.CellPadding = UDim2.fromOffset(6, 6)
    grid.FillDirectionMaxCells = 5; grid.Parent = qualityHolder

    local buttons = {}
    local function updateQualityButtons()
        for level, button in pairs(buttons) do
            if level == State.Quality then
                button.BackgroundColor3 = Color3.fromRGB(90, 125, 190); button.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                button.BackgroundColor3 = Color3.fromRGB(31, 35, 43); button.TextColor3 = Color3.fromRGB(180, 188, 205)
            end
        end
    end

    for level = 1, 10 do
        local button = Instance.new("TextButton")
        button.AutoButtonColor = true; button.BackgroundColor3 = Color3.fromRGB(31, 35, 43); button.BorderSizePixel = 0
        button.Font = Enum.Font.GothamBold; button.TextSize = 12; button.TextColor3 = Color3.fromRGB(180, 188, 205); button.Text = tostring(level); button.Parent = qualityHolder
        local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 7); bc.Parent = button
        button.MouseButton1Click:Connect(function() applyQuality(level); updateQualityButtons() end)
        buttons[level] = button
    end
    updateQualityButtons()

    -- Mood Combination Section
    local moodTitle = Instance.new("TextLabel")
    moodTitle.BackgroundTransparency = 1; moodTitle.Size = UDim2.new(1, -30, 0, 22); moodTitle.Position = UDim2.fromOffset(15, 180)
    moodTitle.Font = Enum.Font.GothamBold; moodTitle.TextSize = 12; moodTitle.TextXAlignment = Enum.TextXAlignment.Left
    moodTitle.TextColor3 = Color3.fromRGB(210, 218, 232); moodTitle.Text = "KOMBINASI SHADERS (Maks 2)"; moodTitle.Parent = panel

    local moodScroll = Instance.new("ScrollingFrame")
    moodScroll.BackgroundTransparency = 1; moodScroll.BorderSizePixel = 0; moodScroll.Size = UDim2.new(1, -30, 0, 160)
    moodScroll.Position = UDim2.fromOffset(15, 207); moodScroll.ScrollBarThickness = 3; moodScroll.CanvasSize = UDim2.fromOffset(0, 0); moodScroll.Parent = panel
    local mList = Instance.new("UIListLayout"); mList.Padding = UDim.new(0, 5); mList.Parent = moodScroll

    local moodButtons = {}
    local function updateMoodButtons()
        for name, button in pairs(moodButtons) do
            local isActive = table.find(State.SelectedMoods, name) ~= nil
            if isActive then
                button.BackgroundColor3 = Color3.fromRGB(68, 80, 108); button.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                button.BackgroundColor3 = Color3.fromRGB(25, 29, 36); button.TextColor3 = Color3.fromRGB(178, 186, 201)
            end
        end
    end

    for name, _ in pairs(Atmospheres) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -5, 0, 28); button.BackgroundColor3 = Color3.fromRGB(25, 29, 36); button.BorderSizePixel = 0
        button.Font = Enum.Font.GothamMedium; button.TextSize = 11; button.TextXAlignment = Enum.TextXAlignment.Left
        button.TextColor3 = Color3.fromRGB(178, 186, 201); button.Text = "   " .. name; button.Parent = moodScroll
        local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = button
        button.MouseButton1Click:Connect(function() API.ToggleMood(name); updateMoodButtons(); updateSettingsPanel() end)
        moodButtons[name] = button
    end
    mList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        moodScroll.CanvasSize = UDim2.fromOffset(0, mList.AbsoluteContentSize.Y + 10)
    end)
    updateMoodButtons()

    -- Settings Panel Section
    local settingsTitle = Instance.new("TextLabel")
    settingsTitle.BackgroundTransparency = 1; settingsTitle.Size = UDim2.new(1, -30, 0, 22); settingsTitle.Position = UDim2.fromOffset(15, 380)
    settingsTitle.Font = Enum.Font.GothamBold; settingsTitle.TextSize = 12; settingsTitle.TextXAlignment = Enum.TextXAlignment.Left
    settingsTitle.TextColor3 = Color3.fromRGB(210, 218, 232); settingsTitle.Text = "PENGATURAN SHADER AKTIF"; settingsTitle.Parent = panel

    local settingsMoodSelector = Instance.new("Frame")
    settingsMoodSelector.BackgroundTransparency = 1; settingsMoodSelector.Size = UDim2.new(1, -30, 0, 30); settingsMoodSelector.Position = UDim2.fromOffset(15, 405); settingsMoodSelector.Parent = panel
    
    local settingsButtons = {}
    local activeSettingsMood = nil

    local function updateSettingsPanel()
        -- Clear old selector buttons
        for _, btn in pairs(settingsButtons) do btn:Destroy() end
        settingsButtons = {}
        activeSettingsMood = State.SelectedMoods[1]

        if #State.SelectedMoods == 0 then
            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1; label.Size = UDim2.new(1, 0, 1, 0)
            label.Font = Enum.Font.Gotham; label.TextSize = 11; label.TextColor3 = Color3.fromRGB(150, 160, 170)
            label.Text = "Pilih minimal 1 shader untuk mengatur"; label.Parent = settingsMoodSelector
            return
        end

        local btnW = (420 - 30 - (#State.SelectedMoods - 1) * 5) / #State.SelectedMoods
        for i, name in ipairs(State.SelectedMoods) do
            local btn = Instance.new("TextButton")
            btn.AutoButtonColor = false; btn.Position = UDim2.fromOffset((i - 1) * (btnW + 5), 0)
            btn.Size = UDim2.fromOffset(btnW, 30); btn.BackgroundColor3 = (name == activeSettingsMood) and Color3.fromRGB(90, 125, 190) or Color3.fromRGB(31, 35, 43)
            btn.BorderSizePixel = 0; btn.Font = Enum.Font.GothamBold; btn.TextSize = 11
            btn.TextColor3 = (name == activeSettingsMood) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 188, 205)
            btn.Text = name; btn.Parent = settingsMoodSelector
            local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = btn
            btn.MouseButton1Click:Connect(function()
                activeSettingsMood = name
                updateSettingsPanel()
            end)
            settingsButtons[name] = btn
        end
        
        -- Here you would ideally add sliders below this selector, 
        -- but to keep the main panel clean and within reasonable bounds, 
        -- the sliders are conceptually linked to this selection.
        -- For a full implementation, a dedicated Settings GUI window is better.
    end
    updateSettingsPanel()

    -- Status Bar
    local status = Instance.new("TextLabel")
    status.BackgroundTransparency = 1; status.Size = UDim2.new(1, -30, 0, 25); status.Position = UDim2.new(0, 15, 1, -35)
    status.Font = Enum.Font.GothamMedium; status.TextSize = 10; status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextColor3 = Color3.fromRGB(135, 145, 164); status.Parent = panel

    local function refreshStatus()
        local activeNames = table.concat(State.SelectedMoods, " + ")
        if activeNames == "" then activeNames = "NONE" end
        status.Text = string.format("Q%d • %s • Parts %d • PBR %d • Lights %d",
            State.Quality, activeNames, State.Stats.Parts, State.Stats.SurfaceAppearances, State.Stats.LightsFound + State.Stats.LightsCreated)
    end

    task.spawn(function()
        while gui.Parent do refreshStatus(); task.wait(1) end
    end)

    -- Dragging Logic
    local dragging = false; local dragStart; local startPosition
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPosition = panel.Position
        end
    end)
    title.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
    end)

    return gui
end

-- Dedicated Settings Window for Sliders and Presets
local function createSettingsWindow()
    local gui = Instance.new("ScreenGui")
    gui.Name = ROOT_NAME .. "_Settings"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
    gui.DisplayOrder = 51; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.Parent = PlayerGui

    local panel = Instance.new("Frame")
    panel.Name = "SettingsPanel"; panel.Size = UDim2.fromOffset(300, 400)
    panel.Position = UDim2.new(1, -322, 0.5, -200)
    panel.BackgroundColor3 = Color3.fromRGB(15, 17, 22); panel.BackgroundTransparency = 0.05; panel.BorderSizePixel = 0; panel.Parent = gui

    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 14); corner.Parent = panel
    local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(95, 105, 125); stroke.Transparency = 0.55; stroke.Thickness = 1; stroke.Parent = panel

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1; title.Size = UDim2.new(1, -20, 0, 30); title.Position = UDim2.fromOffset(10, 10)
    title.Font = Enum.Font.GothamBold; title.TextSize = 14; title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = Color3.fromRGB(245, 248, 255); title.Text = "PENGATURAN DETAIL"; title.Parent = panel

    local moodLabel = Instance.new("TextLabel")
    moodLabel.BackgroundTransparency = 1; moodLabel.Size = UDim2.new(1, -20, 0, 20); moodLabel.Position = UDim2.fromOffset(10, 45)
    moodLabel.Font = Enum.Font.GothamMedium; moodLabel.TextSize = 11; moodLabel.TextXAlignment = Enum.TextXAlignment.Left
    moodLabel.TextColor3 = Color3.fromRGB(160, 170, 188); moodLabel.Text = "Mengatur: NONE"; moodLabel.Parent = panel

    -- Preset Buttons
    local presetHolder = Instance.new("Frame")
    presetHolder.BackgroundTransparency = 1; presetHolder.Size = UDim2.new(1, -20, 0, 30); presetHolder.Position = UDim2.fromOffset(10, 70); presetHolder.Parent = panel
    local presetGrid = Instance.new("UIGridLayout"); presetGrid.CellSize = UDim2.fromOffset(90, 25); presetGrid.CellPadding = UDim2.fromOffset(5, 0); presetGrid.Parent = presetHolder

    local presets = {"Lumayan Terang", "Sedang", "Gelap"}
    local presetBtns = {}
    for _, preset in ipairs(presets) do
        local btn = Instance.new("TextButton")
        btn.AutoButtonColor = true; btn.BackgroundColor3 = Color3.fromRGB(31, 35, 43); btn.BorderSizePixel = 0
        btn.Font = Enum.Font.GothamBold; btn.TextSize = 10; btn.TextColor3 = Color3.fromRGB(180, 188, 205); btn.Text = preset; btn.Parent = presetHolder
        local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 5); bc.Parent = btn
        btn.MouseButton1Click:Connect(function()
            if activeSettingsMood then
                API.SetMoodPreset(activeSettingsMood, preset)
                -- Visual feedback
                btn.BackgroundColor3 = Color3.fromRGB(90, 125, 190)
                task.delay(0.2, function() btn.BackgroundColor3 = Color3.fromRGB(31, 35, 43) end)
            end
        end)
        presetBtns[preset] = btn
    end

    -- Sliders Container
    local scroll = Instance.new("ScrollingFrame")
    scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0; scroll.Size = UDim2.new(1, -20, 0, 260)
    scroll.Position = UDim2.fromOffset(10, 110); scroll.ScrollBarThickness = 3; scroll.CanvasSize = UDim2.fromOffset(0, 0); scroll.Parent = panel
    local sList = Instance.new("UIListLayout"); sList.Padding = UDim.new(0, 12); sList.Parent = scroll

    local sliders = {}
    local sliderDefs = {
        { Key = "ExposureOffset", Label = "Exposure", Min = -0.2, Max = 0.2, Step = 0.01 },
        { Key = "ContrastOffset", Label = "Contrast", Min = -0.1, Max = 0.1, Step = 0.01 },
        { Key = "SaturationOffset", Label = "Saturation", Min = -0.1, Max = 0.1, Step = 0.01 },
        { Key = "BloomOffset", Label = "Bloom", Min = -0.05, Max = 0.05, Step = 0.005 },
        { Key = "SunRaysOffset", Label = "Sun Rays", Min = -0.05, Max = 0.05, Step = 0.005 },
    }

    local function buildSliders()
        for _, def in ipairs(sliderDefs) do
            local container = Instance.new("Frame")
            container.BackgroundTransparency = 1; container.Size = UDim2.new(1, 0, 0, 40); container.Parent = scroll

            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1; label.Size = UDim2.new(0.6, 0, 0, 16); label.Position = UDim2.fromOffset(0, 0)
            label.Font = Enum.Font.GothamMedium; label.TextSize = 11; label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextColor3 = Color3.fromRGB(210, 218, 232); label.Text = def.Label; label.Parent = container

            local valLabel = Instance.new("TextLabel")
            valLabel.BackgroundTransparency = 1; valLabel.Size = UDim2.new(0.4, 0, 0, 16); valLabel.Position = UDim2.fromOffset(container.Size.X.Offset * 0.6, 0)
            valLabel.Font = Enum.Font.GothamBold; valLabel.TextSize = 11; valLabel.TextXAlignment = Enum.TextXAlignment.Right
            valLabel.TextColor3 = Color3.fromRGB(90, 125, 190); valLabel.Text = "0.00"; valLabel.Parent = container

            local track = Instance.new("Frame")
            track.Position = UDim2.fromOffset(0, 20); track.Size = UDim2.new(1, 0, 0, 6)
            track.BackgroundColor3 = Color3.fromRGB(31, 35, 43); track.BorderSizePixel = 0; track.Parent = container
            local tCorner = Instance.new("UICorner"); tCorner.CornerRadius = UDim.new(0, 3); tCorner.Parent = track

            local fill = Instance.new("Frame")
            fill.Size = UDim2.fromScale(0.5, 1); fill.BackgroundColor3 = Color3.fromRGB(90, 125, 190); fill.BorderSizePixel = 0; fill.Parent = track
            local fCorner = Instance.new("UICorner"); fCorner.CornerRadius = UDim.new(0, 3); fCorner.Parent = fill

            local knob = Instance.new("Frame")
            knob.AnchorPoint = Vector2.new(0.5, 0.5); knob.Position = UDim2.fromScale(0.5, 0.5)
            knob.Size = UDim2.fromOffset(12, 12); knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255); knob.BorderSizePixel = 0; knob.Parent = track
            local kCorner = Instance.new("UICorner"); kCorner.CornerRadius = UDim.new(1, 0); kCorner.Parent = knob

            local draggingSlider = false
            local function updateSliderVisual(val)
                local pct = (val - def.Min) / (def.Max - def.Min)
                pct = math.clamp(pct, 0, 1)
                fill.Size = UDim2.fromScale(pct, 1)
                knob.Position = UDim2.fromScale(pct, 0.5)
                valLabel.Text = string.format("%.2f", val)
            end

            local function startDrag(input)
                draggingSlider = true
                local function updateFromInput(inp)
                    local trackPos = track.AbsolutePosition.X
                    local trackSize = track.AbsoluteSize.X
                    local mouseX = inp.Position.X
                    local pct = math.clamp((mouseX - trackPos) / trackSize, 0, 1)
                    local rawVal = def.Min + pct * (def.Max - def.Min)
                    local snappedVal = math.floor(rawVal / def.Step + 0.5) * def.Step
                    snappedVal = math.clamp(snappedVal, def.Min, def.Max)
                    if activeSettingsMood then
                        API.SetMoodSlider(activeSettingsMood, def.Key, snappedVal)
                    end
                    updateSliderVisual(snappedVal)
                end
                updateFromInput(input)
                local conn; conn = UserInputService.InputChanged:Connect(function(inp)
                    if not draggingSlider then conn:Disconnect(); return end
                    if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                        updateFromInput(inp)
                    end
                end)
                local endConn; endConn = UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                        draggingSlider = false; conn:Disconnect(); endConn:Disconnect()
                    end
                end)
            end

            knob.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then startDrag(input) end
            end)
            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then startDrag(input) end
            end)

            sliders[def.Key] = { Update = updateSliderVisual, Def = def }
        end
        sList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scroll.CanvasSize = UDim2.fromOffset(0, sList.AbsoluteContentSize.Y + 10)
        end)
    end
    buildSliders()

    -- Update loop for settings window
    task.spawn(function()
        while gui.Parent do
            if activeSettingsMood then
                moodLabel.Text = "Mengatur: " .. activeSettingsMood
                local settings = MoodSettings[activeSettingsMood]
                if settings then
                    for key, slider in pairs(sliders) do
                        slider.Update(settings[key])
                    end
                end
            else
                moodLabel.Text = "Mengatur: NONE (Pilih shader)"
            end
            task.wait(0.1)
        end
    end)

    -- Dragging for settings panel
    local draggingPanel = false; local dragStartS; local startPosS
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingPanel = true; dragStartS = input.Position; startPosS = panel.Position
        end
    end)
    title.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingPanel = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not draggingPanel then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = input.Position - dragStartS
        panel.Position = UDim2.new(startPosS.X.Scale, startPosS.X.Offset + delta.X, startPosS.Y.Scale, startPosS.Y.Offset + delta.Y)
    end)
end

----------------------------------------------------------------
-- FPS MONITOR & INITIALIZATION
----------------------------------------------------------------
local fpsConnection
local function startFPSMonitor()
    local accumulator = 0; local frames = 0
    fpsConnection = RunService.RenderStepped:Connect(function(dt)
        accumulator += dt; frames += 1
        if accumulator >= 1 then
            State.Stats.LastFPS = math.floor(frames / accumulator); accumulator = 0; frames = 0
        end
    end)
    table.insert(State.Connections, fpsConnection)
end

local function initialize()
    State.Restored = false
    configureLightingBase()
    applyQuality(Config.Quality)
    -- Default select NOSTALGIC SORE if none selected
    if #State.SelectedMoods == 0 then
        table.insert(State.SelectedMoods, "NOSTALGIC SORE")
    end
    applyAtmosphere()
    task.spawn(function()
        scanVisualAssets(); preserveDetailGeometry(); enhanceExistingLights(); scanAccentLights()
    end)
    createUI()
    createSettingsWindow()
    startFPSMonitor()
end

local lightTimer = 0
local maintenanceConnection = RunService.Heartbeat:Connect(function(dt)
    if State.Restored or not Config.Enabled then return end
    lightTimer += dt
    if lightTimer >= Config.LightUpdateInterval then
        lightTimer = 0
        Camera = Workspace.CurrentCamera
        if Camera then
            for _, record in ipairs(State.AccentLights) do
                local source = record.Source; local light = record.Light
                if source and source.Parent and light and light.Parent then
                    local distance = (source.Position - Camera.CFrame.Position).Magnitude
                    if distance > Config.LightDistance then
                        light.Enabled = false
                    else
                        light.Enabled = true
                        local factor = 1 - math.clamp(distance / Config.LightDistance, 0, 1)
                        light.Brightness = lerp(0.15, 0.85, factor)
                    end
                end
            end
        end
    end
end)
table.insert(State.Connections, maintenanceConnection)

local cameraConnection = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = Workspace.CurrentCamera
end)
table.insert(State.Connections, cameraConnection)

_G.UltraRealisticRendererV4 = API
initialize()

--[[
    USAGE:
    _G.UltraRealisticRendererV4.SetQuality(10)
    _G.UltraRealisticRendererV4.ToggleMood("NOSTALGIC SORE")
    _G.UltraRealisticRendererV4.ToggleMood("RAIN MOOD") -- Combines with Nostalgic Sore
    _G.UltraRealisticRendererV4.SetMoodPreset("NOSTALGIC SORE", "Gelap")
    _G.UltraRealisticRendererV4.RefreshDetails()
    _G.UltraRealisticRendererV4.Restore()
]]