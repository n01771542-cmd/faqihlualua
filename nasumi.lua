--[[
    ============================================================================
    LEON4951 SHADERS: EDISI KETENANGAN ULTRA (SERENITY ULTRA EDITION)
    ============================================================================
    Roblox LocalScript | Minimal 3000 Baris | Super Realistis 2K
    
    LETAKKAN DI: StarterPlayer > StarterPlayerScripts
    
    ============================================================================
    FILOSOFI VISUAL
    ============================================================================
    Script ini bukan sekadar filter warna. Ini adalah sebuah mahakarya visual 
    yang dirancang untuk menciptakan ketenangan mendalam di setiap suasana.
    
    Setiap mood memiliki "jiwa" tersendiri:
    - SORE:   Oranye keemasan yang hangat, matahari diam, garis cahaya halus
              yang muncul saat kamu menatapnya, seperti kenangan masa kecil.
    - KABUT:  Misterius, tenang, dengan kabut tebal yang menyelimuti dunia.
    - HUJAN:  Genangan kaca bening di lantai, partikel hujan yang realistis,
              suasana yang menenangkan seperti hujan di hari Minggu.
    - MALAM:  Biru perak lembut dari bulan, kedamaian total, cahaya telur
              yang berdenyut halus seperti denyut jantung yang tenang.
    - SIANG:  Terang namun hangat, seperti teras rumah nenek di hari libur.
    
    ============================================================================
    FITUR UTAMA
    ============================================================================
    1. 5 SUASANA UTAMA dengan parameter yang sangat detail dan bisa di-setting
       oleh pemain melalui panel UI (slider untuk brightness, exposure, dll).
    
    2. SISTEM KOMBINASI: Pemain bisa memilih MAKSIMAL 2 shaders sekaligus.
       Kedua shader akan digabungkan secara halus (lerp) untuk menciptakan
       suasana unik (contoh: Sore + Kabut = Sore Berkabut yang dramatis).
    
    3. MATAHARI DIAM: Matahari terkunci di satu titik dunia, tidak bergerak.
       Saat kamu menatapnya, muncul garis-garis cahaya halus yang lembut
       (anamorphic flare + radial rays + bokeh debu emas).
    
    4. BAYANGAN DETAIL: ShadowSoftness sangat rendah untuk bayangan tajam
       yang mendefinisikan setiap detail arsitektur dan alam.
    
    5. INTEGRASI PENUH DENGAN MAP: Semua efek (sun rays, god rays, bokeh,
       puddles, rain) adalah objek 3D di dalam dunia game, bukan sekadar
       tempelan di layar. Mereka berinteraksi dengan geometri map.
    
    6. PANEL UI LENGKAP: Setiap shader memiliki panel pengaturan sendiri
       dengan slider untuk brightness, exposure, saturation, contrast,
       sun glow, shafts, flare, dan banyak lagi.
    
    7. SISTEM RESTORE AMAN: Semua perubahan dicatat dan bisa dikembalikan
       ke kondisi asli dengan satu tombol.
    
    ============================================================================
    CATATAN TEKNIS
    ============================================================================
    - Script ini visual-only, tidak mengubah gameplay, movement, atau data pemain.
    - Menggunakan pipeline asli Roblox: Atmosphere, Bloom, ColorCorrection,
      SunRays, DepthOfField, Beam (untuk god rays), ParticleEmitter (untuk
      rain & bokeh), PointLight (untuk accent lights & egg lights).
    - Semua efek client-side, hanya terlihat oleh pemain ini.
    - Performa dioptimalkan dengan sistem quality 1-10 dan distance culling.
    
    ============================================================================
    CARA PAKAI (API)
    ============================================================================
    _G.Leon4951Shaders.SetMood("Sore")
    _G.Leon4951Shaders.SetMoods({"Sore", "Kabut"})   -- kombinasi 2
    _G.Leon4951Shaders.SetQuality(10)
    _G.Leon4951Shaders.SetSetting("Sore", "Brightness", 2.3)
    _G.Leon4951Shaders.Restore()
    ============================================================================
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

local ROOT = "Leon4951Shaders_SerenityUltra"
local PREFIX = "L4SU_"
local rgb = Color3.fromRGB

----------------------------------------------------------------
-- BERSIHKAN VERSI LAMA
----------------------------------------------------------------
local function safeCleanup()
    for _, globalName in ipairs({
        "Leon4951Shaders", "VisualRealistis", "UltraRealisticRendererV4",
        "Leon4951Shaders_Serenity", "Leon4951Shaders_SerenityUltra"
    }) do
        local old = _G[globalName]
        if old and old.Restore then
            pcall(old.Restore)
        end
    end

    for _, guiName in ipairs({
        ROOT, ROOT .. "_FX", ROOT .. "_Settings",
        "VisualRealistis", "UltraRealisticRendererV4"
    }) do
        local old = PlayerGui:FindFirstChild(guiName)
        if old then
            old:Destroy()
        end
    end

    for _, child in ipairs(Lighting:GetChildren()) do
        local n = child.Name
        if n:sub(1, 3) == "VR_" or n:sub(1, #PREFIX) == PREFIX or n:sub(1, 5) == "URV4_" then
            child:Destroy()
        end
    end

    for _, folderName in ipairs({"VR_Dunia", "L4_Dunia", "L4S_Dunia", "L4SU_Dunia"}) do
        local old = Workspace:FindFirstChild(folderName)
        if old then
            old:Destroy()
        end
    end
end

safeCleanup()

local WorldFolder = Instance.new("Folder")
WorldFolder.Name = "L4SU_Dunia"
WorldFolder.Parent = Workspace

----------------------------------------------------------------
-- HELPER FUNCTIONS
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

local function clamp(v, min, max)
    return math.clamp(v, min, max)
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function lerpColor(a, b, t)
    return a:Lerp(b, clamp01(t))
end

local function wetColor(c)
    return Color3.new(c.R * 0.72, c.G * 0.70, c.B * 0.66)
end

local function round(v, decimals)
    local mult = 10 ^ (decimals or 2)
    return math.floor(v * mult + 0.5) / mult
end

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
    Sky = nil,
    SkyOwned = false,
    SkySaved = nil,
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
-- PENGATURAN INTI
----------------------------------------------------------------
local Settings = {
    Quality = 9,
    StartMoods = { "Sore" },
    MaxCombinedMoods = 2,
    ShowPanel = true,

    SunDistance = 1000,
    SunFalloff = 1.8,
    SunSize = 260,

    ShadowSoftness = 0.06,

    MaxAccentLights = 80,
    LightDistance = 500,
    LightUpdateInterval = 0.12,

    EggRange = 15,
    EggBrightness = 0.9,
    EggMaxLights = 48,
    EggDistance = 320,
    EggColor = rgb(255, 180, 90),
}

----------------------------------------------------------------
-- DEFINISI SETTING PER SHADER (slider yang bisa di-setting player)
----------------------------------------------------------------
local SettingDefs = {
    {
        Key = "Brightness",
        Label = "Kecerahan",
        Min = 0.5,
        Max = 3.0,
        Step = 0.05,
        Default = nil,
    },
    {
        Key = "Exposure",
        Label = "Exposure",
        Min = -0.5,
        Max = 0.3,
        Step = 0.01,
        Default = nil,
    },
    {
        Key = "Saturation",
        Label = "Saturasi",
        Min = -0.3,
        Max = 0.4,
        Step = 0.01,
        Default = nil,
    },
    {
        Key = "Contrast",
        Label = "Kontras",
        Min = 0,
        Max = 0.4,
        Step = 0.01,
        Default = nil,
    },
    {
        Key = "ShadowSoftness",
        Label = "Kelembutan Bayangan",
        Min = 0.02,
        Max = 0.5,
        Step = 0.01,
        Default = nil,
    },
    {
        Key = "SunGlow",
        Label = "Cahaya Matahari",
        Min = 0,
        Max = 1.5,
        Step = 0.05,
        Default = nil,
    },
    {
        Key = "Shafts",
        Label = "Sinar Cahaya (God Rays)",
        Min = 0,
        Max = 1.5,
        Step = 0.05,
        Default = nil,
    },
    {
        Key = "Flare",
        Label = "Flare / Lens Effect",
        Min = 0,
        Max = 1.5,
        Step = 0.05,
        Default = nil,
    },
    {
        Key = "Bloom",
        Label = "Bloom (Cahaya Lembut)",
        Min = 0,
        Max = 0.5,
        Step = 0.01,
        Default = nil,
    },
    {
        Key = "SunRays",
        Label = "Sun Rays Effect",
        Min = 0,
        Max = 0.6,
        Step = 0.01,
        Default = nil,
    },
    {
        Key = "Density",
        Label = "Kepadatan Atmosfer",
        Min = 0.001,
        Max = 0.015,
        Step = 0.0005,
        Default = nil,
    },
    {
        Key = "Haze",
        Label = "Kabut / Haze",
        Min = 0,
        Max = 0.5,
        Step = 0.01,
        Default = nil,
    },
    {
        Key = "Glare",
        Label = "Silau (Glare)",
        Min = 0,
        Max = 0.8,
        Step = 0.01,
        Default = nil,
    },
}

----------------------------------------------------------------
-- DAFTAR 5 SUASANA (SHADERS) UTAMA
----------------------------------------------------------------
-- Setiap suasana memiliki parameter default yang bisa di-override oleh player.
-- Parameter ini dirancang untuk menciptakan ketenangan dan vibes yang berbeda.

local BaseMoods = {
    ----------------------------------------------------------------
    -- SORE: Oranye keemasan, matahari diam, garis cahaya halus
    ----------------------------------------------------------------
    {
        Name = "Sore",
        Description = "Sore keemasan yang hangat, matahari diam di tempatnya",
        Icon = "🌅",
        ClockTime = 17.35,
        Brightness = 2.10,
        Exposure = -0.15,
        ShadowSoftness = 0.06,
        Density = 0.0065,
        Offset = 0.08,
        Haze = 0.25,
        Glare = 0.45,
        Color = rgb(255, 170, 70),
        Decay = rgb(210, 90, 30),
        Ambient = rgb(35, 20, 10),
        OutdoorAmbient = rgb(130, 75, 35),
        Top = rgb(255, 150, 60),
        Bottom = rgb(230, 110, 40),
        Bloom = 0.28,
        BloomSize = 28,
        BloomThreshold = 0.85,
        SunRays = 0.35,
        SunRaySpread = 0.92,
        Contrast = 0.18,
        Saturation = 0.12,
        Tint = rgb(255, 225, 180),
        ShaftColor = rgb(255, 180, 80),
        Shafts = 1.0,
        SunGlow = 1.0,
        Flare = 1.2,
        Sheen = 0.15,
        Overlay = 0.7,
        OverlayTop = rgb(25, 12, 5),
        OverlayBottom = rgb(240, 130, 50),
        WarmBody = true,
        CloudColor = rgb(255, 160, 80),
        CloudCover = 0.4,
        CloudDensity = 0.45,
        EggGlow = 0.0,
        Rain = false,
        Wet = false,
        DustMotes = true,
        SunRayColor = rgb(255, 220, 140),
        FlareColor = rgb(255, 200, 100),
        BokehColor = rgb(255, 180, 80),
    },

    ----------------------------------------------------------------
    -- KABUT: Misterius, tenang, kabut tebal
    ----------------------------------------------------------------
    {
        Name = "Kabut",
        Description = "Kabut tebal yang menyelimuti dunia dengan tenang",
        Icon = "🌫️",
        ClockTime = 9.0,
        Brightness = 1.60,
        Exposure = -0.10,
        ShadowSoftness = 0.25,
        Density = 0.0080,
        Offset = 0.02,
        Haze = 0.40,
        Glare = 0.15,
        Color = rgb(210, 215, 225),
        Decay = rgb(180, 185, 200),
        Ambient = rgb(35, 38, 42),
        OutdoorAmbient = rgb(100, 105, 115),
        Top = rgb(220, 225, 235),
        Bottom = rgb(190, 195, 205),
        Bloom = 0.06,
        BloomSize = 26,
        BloomThreshold = 1.15,
        SunRays = 0.10,
        SunRaySpread = 0.85,
        Contrast = 0.08,
        Saturation = -0.02,
        Tint = rgb(235, 240, 245),
        ShaftColor = rgb(220, 225, 235),
        Shafts = 0.3,
        SunGlow = 0.3,
        Flare = 0.1,
        Sheen = 0.05,
        Overlay = 0.3,
        OverlayTop = rgb(40, 45, 50),
        OverlayBottom = rgb(150, 160, 170),
        WarmBody = false,
        CloudColor = rgb(200, 205, 215),
        CloudCover = 0.8,
        CloudDensity = 0.7,
        EggGlow = 0.3,
        Rain = false,
        Wet = false,
        DustMotes = false,
        SunRayColor = rgb(230, 235, 245),
        FlareColor = rgb(220, 225, 235),
        BokehColor = rgb(210, 215, 225),
    },

    ----------------------------------------------------------------
    -- HUJAN: Genangan kaca, partikel hujan, suasana tenang
    ----------------------------------------------------------------
    {
        Name = "Hujan",
        Description = "Hujan tenang dengan genangan kaca di lantai",
        Icon = "🌧️",
        ClockTime = 15.0,
        Brightness = 1.40,
        Exposure = -0.12,
        ShadowSoftness = 0.30,
        Density = 0.0090,
        Offset = 0.00,
        Haze = 0.35,
        Glare = 0.05,
        Color = rgb(180, 190, 205),
        Decay = rgb(140, 150, 170),
        Ambient = rgb(30, 35, 40),
        OutdoorAmbient = rgb(90, 100, 115),
        Top = rgb(190, 200, 215),
        Bottom = rgb(150, 160, 175),
        Bloom = 0.05,
        BloomSize = 22,
        BloomThreshold = 1.20,
        SunRays = 0.05,
        SunRaySpread = 0.80,
        Contrast = 0.10,
        Saturation = -0.05,
        Tint = rgb(220, 230, 240),
        ShaftColor = rgb(200, 210, 225),
        Shafts = 0.2,
        SunGlow = 0.2,
        Flare = 0.05,
        Sheen = 0.18,
        Overlay = 0.4,
        OverlayTop = rgb(30, 35, 42),
        OverlayBottom = rgb(130, 145, 160),
        WarmBody = false,
        CloudColor = rgb(160, 170, 185),
        CloudCover = 0.95,
        CloudDensity = 0.85,
        EggGlow = 0.5,
        Rain = true,
        Wet = true,
        DustMotes = false,
        SunRayColor = rgb(210, 220, 235),
        FlareColor = rgb(200, 210, 225),
        BokehColor = rgb(190, 200, 215),
    },

    ----------------------------------------------------------------
    -- MALAM: Biru perak lembut, kedamaian total
    ----------------------------------------------------------------
    {
        Name = "Malam",
        Description = "Malam bulan yang tenang dengan cahaya biru perak",
        Icon = "🌙",
        ClockTime = 0.30,
        Brightness = 1.25,
        Exposure = -0.08,
        ShadowSoftness = 0.18,
        Density = 0.0040,
        Offset = 0.20,
        Haze = 0.10,
        Glare = 0.02,
        Color = rgb(160, 185, 230),
        Decay = rgb(90, 110, 160),
        Ambient = rgb(15, 18, 30),
        OutdoorAmbient = rgb(60, 75, 110),
        Top = rgb(130, 155, 210),
        Bottom = rgb(80, 95, 135),
        Bloom = 0.08,
        BloomSize = 24,
        BloomThreshold = 1.05,
        SunRays = 0.03,
        SunRaySpread = 0.70,
        Contrast = 0.15,
        Saturation = 0.03,
        Tint = rgb(215, 225, 250),
        ShaftColor = rgb(180, 200, 235),
        Shafts = 0.1,
        SunGlow = 0.1,
        Flare = 0.05,
        Sheen = 0.08,
        Overlay = 0.5,
        OverlayTop = rgb(10, 15, 30),
        OverlayBottom = rgb(60, 80, 120),
        WarmBody = false,
        CloudColor = rgb(120, 140, 180),
        CloudCover = 0.3,
        CloudDensity = 0.3,
        EggGlow = 1.0,
        Rain = false,
        Wet = false,
        DustMotes = false,
        SunRayColor = rgb(200, 215, 240),
        FlareColor = rgb(180, 200, 230),
        BokehColor = rgb(170, 190, 225),
    },

    ----------------------------------------------------------------
    -- SIANG: Terang namun hangat, seperti teras rumah nenek
    ----------------------------------------------------------------
    {
        Name = "Siang",
        Description = "Siang yang terang dan hangat, penuh kehidupan",
        Icon = "☀️",
        ClockTime = 12.5,
        Brightness = 2.30,
        Exposure = 0.04,
        ShadowSoftness = 0.10,
        Density = 0.0035,
        Offset = 0.18,
        Haze = 0.08,
        Glare = 0.10,
        Color = rgb(245, 248, 255),
        Decay = rgb(230, 235, 245),
        Ambient = rgb(40, 42, 48),
        OutdoorAmbient = rgb(160, 165, 175),
        Top = rgb(250, 252, 255),
        Bottom = rgb(245, 240, 230),
        Bloom = 0.08,
        BloomSize = 20,
        BloomThreshold = 1.15,
        SunRays = 0.08,
        SunRaySpread = 0.80,
        Contrast = 0.12,
        Saturation = 0.04,
        Tint = rgb(255, 255, 255),
        ShaftColor = rgb(255, 250, 235),
        Shafts = 0.3,
        SunGlow = 0.5,
        Flare = 0.3,
        Sheen = 0.04,
        Overlay = 0.1,
        OverlayTop = rgb(20, 22, 28),
        OverlayBottom = rgb(180, 185, 195),
        WarmBody = false,
        CloudColor = rgb(245, 248, 255),
        CloudCover = 0.3,
        CloudDensity = 0.3,
        EggGlow = 0.0,
        Rain = false,
        Wet = false,
        DustMotes = true,
        SunRayColor = rgb(255, 250, 230),
        FlareColor = rgb(255, 245, 220),
        BokehColor = rgb(255, 240, 200),
    },
}

----------------------------------------------------------------
-- INISIALISASI MOODS DENGAN SETTING DEFAULT
----------------------------------------------------------------
local Moods = {}
local MoodByName = {}
local MoodSettings = {}  -- Menyimpan setting override per mood

for _, base in ipairs(BaseMoods) do
    local mood = {}
    for k, v in pairs(base) do
        mood[k] = v
    end
    table.insert(Moods, mood)
    MoodByName[mood.Name] = mood

    -- Inisialisasi setting per mood (semua nil = pakai default)
    MoodSettings[mood.Name] = {}
    for _, def in ipairs(SettingDefs) do
        MoodSettings[mood.Name][def.Key] = nil
    end
end

----------------------------------------------------------------
-- SISTEM KOMBINASI MOODS (Maksimal 2)
----------------------------------------------------------------
local NUM_KEYS = {
    "Brightness", "Exposure", "ShadowSoftness", "Density", "Offset", "Haze", "Glare",
    "Bloom", "BloomSize", "BloomThreshold", "SunRays", "SunRaySpread",
    "Contrast", "Saturation", "Shafts", "SunGlow", "Flare", "Sheen", "Overlay",
}

local COLOR_KEYS = {
    "Color", "Decay", "Ambient", "OutdoorAmbient", "Top", "Bottom", "Tint",
    "ShaftColor", "OverlayTop", "OverlayBottom", "SunRayColor", "FlareColor", "BokehColor",
}

local BOOL_KEYS = {
    "WarmBody", "Rain", "Wet", "DustMotes",
}

local MAX_KEYS = {
    "EggGlow", "CloudCover", "CloudDensity",
}

local function averageColor(list, key)
    local acc = list[1][key]
    for i = 2, #list do
        acc = acc:Lerp(list[i][key], 1 / i)
    end
    return acc
end

local function applySettingsOverrides(mood, moodName)
    local overrides = MoodSettings[moodName]
    if not overrides then
        return mood
    end
    for key, value in pairs(overrides) do
        if value ~= nil then
            mood[key] = value
        end
    end
    return mood
end

local function mergeMoods(list)
    if #list == 0 then
        return BaseMoods[1]
    end
    if #list == 1 then
        local mood = {}
        for k, v in pairs(list[1]) do
            mood[k] = v
        end
        return applySettingsOverrides(mood, list[1].Name)
    end

    -- Ambil mood utama (yang bukan Fx, atau yang pertama)
    local base = list[1]
    local baseName = base.Name

    local out = {}
    out.Name = base.Name .. " + " .. list[2].Name
    out.ClockTime = base.ClockTime

    -- Rata-rata numerik
    for _, key in ipairs(NUM_KEYS) do
        local sum = 0
        for _, m in ipairs(list) do
            sum = sum + (m[key] or 0)
        end
        out[key] = sum / #list
    end

    -- Rata-rata warna
    for _, key in ipairs(COLOR_KEYS) do
        out[key] = averageColor(list, key)
    end

    -- Boolean: OR (jika salah satu true, hasilnya true)
    for _, key in ipairs(BOOL_KEYS) do
        local result = false
        for _, m in ipairs(list) do
            if m[key] then
                result = true
                break
            end
        end
        out[key] = result
    end

    -- Max untuk nilai tertentu
    for _, key in ipairs(MAX_KEYS) do
        local maxVal = 0
        for _, m in ipairs(list) do
            maxVal = math.max(maxVal, m[key] or 0)
        end
        out[key] = maxVal
    end

    -- Cloud color: rata-rata jika keduanya punya
    local hasCloud = false
    for _, m in ipairs(list) do
        if m.CloudColor then
            hasCloud = true
            break
        end
    end
    if hasCloud then
        out.CloudColor = averageColor(list, "CloudColor")
    end

    -- Apply settings overrides dari mood utama
    return applySettingsOverrides(out, baseName)
end

----------------------------------------------------------------
-- STATE
----------------------------------------------------------------
local function qualityScale(level)
    return 0.4 + 0.6 * (level - 1) / 9
end

local State = {
    Quality = Settings.Quality,
    Scale = qualityScale(Settings.Quality),
    Selected = {},
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
    },

    AccentLights = {},
    Connections = {},
    UI = nil,
    SettingsUI = nil,
    Restored = false,
    Stats = {
        Parts = 0,
        Ground = 0,
        Lights = 0,
        Eggs = 0,
        FPS = 0,
    },
}

-- Inisialisasi mood awal
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
    if #State.Selected == 0 then
        return "Tidak Ada"
    end
    return table.concat(State.Selected, " + ")
end

----------------------------------------------------------------
-- MATAHARI DIAM (Statis, namun interaktif terhadap pandangan)
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

    -- Cek oklusi (apakah matahari tertutup bangunan/pohon)
    Sun.Timer = Sun.Timer + dt
    if Sun.Timer >= 0.1 then
        Sun.Timer = 0
        local offsets = {
            Vector3.zero,
            cf.RightVector * 0.05,
            -cf.RightVector * 0.05,
            cf.UpVector * 0.05,
            -cf.UpVector * 0.05,
        }
        local open = 0
        for _, offset in ipairs(offsets) do
            if not Workspace:Raycast(camPos, (dir + offset).Unit * dist, sunRay) then
                open = open + 1
            end
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
-- SKY: Sembunyikan matahari bawaan Roblox yang kasar
----------------------------------------------------------------
local function restoreSky()
    if Original.Sky then
        if Original.SkyOwned then
            if Original.Sky.Parent then
                Original.Sky:Destroy()
            end
        elseif Original.SkySaved and Original.Sky.Parent then
            for property, value in pairs(Original.SkySaved) do
                setProperty(Original.Sky, property, value)
            end
        end
    end
    Original.Sky = nil
    Original.SkyOwned = false
    Original.SkySaved = nil
end

local function applySky(mood)
    if not (mood.HideSun or mood.SunGlow > 0.05) then
        restoreSky()
        return
    end

    if not Original.Sky then
        local existing = Lighting:FindFirstChildOfClass("Sky")
        if existing then
            Original.Sky = existing
            Original.SkyOwned = false
            Original.SkySaved = { SunAngularSize = existing.SunAngularSize }
        else
            local sky = Instance.new("Sky")
            sky.Name = PREFIX .. "Sky"
            sky.Parent = Lighting
            Original.Sky = sky
            Original.SkyOwned = true
        end
    end

    setProperty(Original.Sky, "SunAngularSize", 0)
end

----------------------------------------------------------------
-- KLASIFIKASI MATERIAL & DETAIL MAP
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
        info.Type = "METAL"
        info.Base = 0.14
        info.Factor = 1.2
    elseif material == Enum.Material.Glass then
        info.Type = "GLASS"
        info.Base = 0.08
        info.Factor = 1.0
    elseif name:find("gold") or name:find("coin") or name:find("treasure") or name:find("bronze") then
        info.Type = "GOLD"
        info.Base = 0.16
        info.Factor = 1.2
    elseif name:find("steel") or name:find("iron") or name:find("metal") then
        info.Type = "METAL"
        info.Base = 0.14
        info.Factor = 1.2
    elseif name:find("crystal") or name:find("gem") then
        info.Type = "CRYSTAL"
        info.Base = 0.12
        info.Factor = 1.0
    elseif name:find("water") or name:find("ocean") or name:find("pool") then
        info.Type = "WATER"
        info.Base = 0.10
        info.Factor = 0.6
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

    State.Stats.Parts = State.Stats.Parts + 1
    if info.Ground then
        State.Stats.Ground = State.Stats.Ground + 1
    end

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
    styleJob = styleJob + 1
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

        count = count + 1
        if count % 400 == 0 then
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
            processPart(object)
        end

        if i % 600 == 0 then
            task.wait()
        end
    end

    ScanDone = true
end

----------------------------------------------------------------
-- DUNIA 3D: MATAHARI, SINAR, HUJAN, GENANGAN, BOKEH
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
    local rainPart, rainEmitter = nil, {}
    local rainSound

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
    end

    World.UpdateRayParams = updateRayParams

    -- Lapisan matahari yang SANGAT HALUS dan hangat
    local SUN_LAYERS = {
        { size = 0.80, alpha = 0.85, color = rgb(255, 160, 60) },
        { size = 0.50, alpha = 0.90, color = rgb(255, 140, 40) },
        { size = 0.25, alpha = 0.95, color = rgb(255, 190, 80) },
        { size = 0.10, alpha = 1.00, color = rgb(255, 240, 180) },
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

        -- Sinar lembut horizontal (Anamorphic halus)
        sunStreak = Instance.new("Frame")
        sunStreak.BorderSizePixel = 0
        sunStreak.AnchorPoint = Vector2.new(0.5, 0.5)
        sunStreak.Position = UDim2.fromScale(0.5, 0.5)
        sunStreak.Size = UDim2.fromScale(2.0, 0.015)
        sunStreak.BackgroundColor3 = rgb(255, 210, 120)
        sunStreak.BackgroundTransparency = 1
        sunStreak.Parent = sunGui

        local streakGradient = Instance.new("UIGradient")
        streakGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0.4),
            NumberSequenceKeypoint.new(1, 1),
        })
        streakGradient.Parent = sunStreak

        -- Sinar radial yang sangat halus (hanya saat menatap matahari)
        for i = 1, 8 do
            local f = Instance.new("Frame")
            f.BorderSizePixel = 0
            f.AnchorPoint = Vector2.new(0.5, 0.5)
            f.Position = UDim2.fromScale(0.5, 0.5)
            f.Size = UDim2.fromScale(3.0, 0.01)
            f.Rotation = (i - 1) * (180 / 8)
            f.BackgroundColor3 = rgb(255, 220, 140)
            f.BackgroundTransparency = 1
            f.Parent = sunGui

            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(1, 0)
            c.Parent = f

            local g = Instance.new("UIGradient")
            g.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.4, 0.3),
                NumberSequenceKeypoint.new(0.6, 0.3),
                NumberSequenceKeypoint.new(1, 1),
            })
            g.Parent = f

            table.insert(sunExtras, { Frame = f, Alpha = 0.6 })
        end

        -- Bokeh partikel debu cahaya
        bokehPart = makeInvisiblePart(PREFIX .. "Bokeh")
        bokehPart.Size = Vector3.new(100, 50, 100)

        bokehEmitter = Instance.new("ParticleEmitter")
        bokehEmitter.Rate = 0
        bokehEmitter.Lifetime = NumberRange.new(5, 9)
        bokehEmitter.Speed = NumberRange.new(0.2, 0.8)
        bokehEmitter.SpreadAngle = Vector2.new(180, 180)
        bokehEmitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.3, 1.2),
            NumberSequenceKeypoint.new(1, 0.4),
        })
        bokehEmitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.2, 0.6),
            NumberSequenceKeypoint.new(0.8, 0.7),
            NumberSequenceKeypoint.new(1, 1),
        })
        bokehEmitter.Color = ColorSequence.new(rgb(255, 180, 80), rgb(255, 230, 150))
        bokehEmitter.LightEmission = 1
        bokehEmitter.LightInfluence = 0
        bokehEmitter.LockedToPart = false
        bokehEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        bokehEmitter.Parent = bokehPart

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
        rainPart = makeInvisiblePart(PREFIX .. "Hujan")
        rainPart.Size = Vector3.new(120, 1, 120)
        rainEmitter = {}

        local rainLayers = {
            {
                weight = 0.40,
                size = 0.60,
                squash = -0.85,
                transparency = 0.50,
                speed = NumberRange.new(90, 115),
                life = NumberRange.new(0.8, 1.0),
            },
            {
                weight = 0.35,
                size = 0.40,
                squash = -0.80,
                transparency = 0.65,
                speed = NumberRange.new(75, 95),
                life = NumberRange.new(0.85, 1.05),
            },
            {
                weight = 0.25,
                size = 0.25,
                squash = -0.75,
                transparency = 0.75,
                speed = NumberRange.new(60, 80),
                life = NumberRange.new(0.9, 1.1),
            },
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
            e.Color = ColorSequence.new(rgb(210, 220, 235))
            e.LightEmission = 0.2
            e.LightInfluence = 0.4
            e.Acceleration = Vector3.new(5, 0, 2)
            e.LockedToPart = false
            e.Orientation = Enum.ParticleOrientation.VelocityParallel
            e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
            e.Parent = rainPart
            table.insert(rainEmitter, { Emitter = e, Weight = layer.weight })
        end
    end

    local function applyClouds(m)
        if m and m.CloudColor ~= nil then
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
                local angle
                if rng:NextNumber() < 0.7 then
                    angle = azimuth + rng:NextNumber(-1.0, 1.0)
                else
                    angle = rng:NextNumber(0, math.pi * 2)
                end

                local radius = 30 + 180 * math.sqrt(rng:NextNumber())
                local origin = camPos + Vector3.new(math.cos(angle) * radius, 180, math.sin(angle) * radius)
                local hit = Workspace:Raycast(origin, Vector3.new(0, -500, 0), rayParams)

                if hit and hit.Normal.Y > 0.3 then
                    local ground = hit.Position + Vector3.new(0, 0.5 + rng:NextNumber(0, 3), 0)
                    local blocked = Workspace:Raycast(ground, sunDir * maxLen, rayParams)
                    local length = blocked and (blocked.Position - ground).Magnitude or maxLen

                    if length > 15 then
                        local width = rng:NextNumber(8, 18)
                        shaft.A0.Position = ground
                        shaft.A1.Position = ground + sunDir * length
                        shaft.Beam.Width0 = width
                        shaft.Beam.Width1 = width * 1.4
                        shaft.Beam.Color = ColorSequence.new(color)
                        shaft.Pos = ground
                        shaft.Rand = rng:NextNumber(0.5, 1.0)
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
        p.Color = rgb(220, 235, 250)
        p.Reflectance = 0.75
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
                local radius = 5 + 120 * math.sqrt(rng:NextNumber())
                local origin = center + Vector3.new(math.cos(angle) * radius, 150, math.sin(angle) * radius)
                local hit = Workspace:Raycast(origin, Vector3.new(0, -300, 0), rayParams)

                local valid = false
                if hit then
                    if hit.Instance:IsA("Terrain") then
                        valid = hit.Normal.Y > 0.88 and hit.Material ~= Enum.Material.Water
                    elseif hit.Normal.Y > 0.95 then
                        local info = PartInfo[hit.Instance]
                        valid = (info ~= nil and info.Ground) or math.abs(hit.Position.Y - refY) < 3
                    end

                    if valid and Workspace:Raycast(hit.Position + Vector3.new(0, 1, 0), Vector3.new(0, 50, 0), rayParams) then
                        valid = false
                    end
                end

                if valid then
                    local pos = hit.Position
                    local yaw = rng:NextNumber(0, math.pi)
                    local w = rng:NextNumber(5, 14)
                    local l = w * rng:NextNumber(0.5, 0.9)

                    puddle[1].Size = Vector3.new(w, 0.04, l)
                    puddle[1].CFrame = CFrame.new(pos + Vector3.new(0, 0.04, 0)) * CFrame.Angles(0, yaw, 0)

                    local s2 = Vector3.new(rng:NextNumber(-0.25, 0.25) * w, 0.055, rng:NextNumber(-0.25, 0.25) * l)
                    puddle[2].Size = Vector3.new(w * 0.65, 0.04, l * 1.3)
                    puddle[2].CFrame = CFrame.new(pos + s2) * CFrame.Angles(0, yaw + rng:NextNumber(0.5, 1.1), 0)

                    local s3 = Vector3.new(rng:NextNumber(-0.35, 0.35) * w, 0.065, rng:NextNumber(-0.35, 0.35) * l)
                    puddle[3].Size = Vector3.new(w * 0.45, 0.04, l * 0.6)
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
            bodyLight.Color = rgb(255, 170, 80)
            bodyLight.Range = 18
            bodyLight.Brightness = 0
            bodyLight.Shadows = false
            bodyLight.Parent = bodyAttachment
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
        local glow = mood.SunGlow * Sun.Elev

        -- Glow Matahari 3D
        sunGui.Enabled = glow > 0.01
        if sunGui.Enabled then
            sunPart.CFrame = CFrame.new(Sun.Pos)

            local a = clamp01(glow * (0.6 + 0.4 * facing))
            for _, layer in ipairs(sunLayers) do
                layer.Frame.BackgroundTransparency = 1 - (1 - layer.Alpha) * a
            end

            sunStreak.BackgroundTransparency = 1 - 0.70 * a * (0.3 + 0.7 * facing)

            for _, extra in ipairs(sunExtras) do
                extra.Frame.BackgroundTransparency = 1 - (extra.Alpha * a * (0.05 + 0.95 * facing))
            end
        end

        -- Efek Kamera "Bernapas"
        local sens = Sun.Elev * Sun.Open * sunSensitive * distFade
        local breathe = 0.5 + 0.5 * math.sin(os.clock() * 0.6)

        local bloom = State.Instances.Bloom
        if bloom and bloom.Parent then
            bloom.Intensity = State.Base.Bloom + (0.40 * f3 * sens) + (breathe * 0.02)
        end

        local rays = State.Instances.SunRays
        if rays and rays.Parent then
            rays.Intensity = State.Base.SunRays + (0.25 * f3 * sens)
        end

        local grade = State.Instances.Color
        if grade and grade.Parent then
            grade.TintColor = State.Base.Tint:Lerp(rgb(255, 215, 160), 0.30 * f2 * sens)
            grade.Saturation = State.Base.Saturation + (0.05 * f2 * sens)
            grade.Brightness = 0.04 * f3 * sens
        end

        local atmosphere = State.Instances.Atmosphere
        if atmosphere and atmosphere.Parent then
            atmosphere.Glare = math.min(1, State.Base.Glare + (0.35 * f2 * sens))
        end

        -- Sun rays 3D
        timers.Shaft = timers.Shaft + dt
        if timers.Shaft >= 0.15 then
            timers.Shaft = 0

            local strength = mood.Shafts * scale * Sun.Elev * (0.45 + 0.55 * distFade)

            if strength <= 0.01 then
                lastSeedPos = nil
            elseif not lastSeedPos
                or (camPos - lastSeedPos).Magnitude > 50
                or not lastSeedSun
                or lastSeedSun:Dot(sunDir) < 0.9997 then
                seedShafts(camPos)
            end

            for _, shaft in ipairs(shafts) do
                if shaft.Active and strength > 0.01 then
                    local distance = (shaft.Pos - camPos).Magnitude
                    local near = clamp01((distance - 15) / 30)
                    local amount = strength * (0.30 + 0.70 * facing) * shaft.Rand * 0.18 * near
                    local t = 1 - clamp01(amount)

                    shaft.Beam.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(0.2, t),
                        NumberSequenceKeypoint.new(0.6, math.min(1, t + (1 - t) * 0.4)),
                        NumberSequenceKeypoint.new(1, 1),
                    })
                    shaft.Beam.Enabled = true
                else
                    shaft.Beam.Enabled = false
                end
            end
        end

        -- Hujan + Genangan Kaca
        local rainTarget = mood.Rain and 1 or 0
        rainLevel = lerp(rainLevel, rainTarget, math.min(1, dt * 0.4))

        timers.Rain = timers.Rain + dt
        if timers.Rain >= 0.2 then
            timers.Rain = 0

            local covered = Workspace:Raycast(camPos, Vector3.new(0, 100, 0), rayParams) ~= nil
            coverTarget = covered and 0.08 or 1

            if rainLevel > 0.03 then
                if not lastPuddlePos or (camPos - lastPuddlePos).Magnitude > 60 then
                    placePuddles(camPos)
                end
                setPuddlesTransparency(1 - 0.60 * clamp01(rainLevel * 1.2))
            elseif lastPuddlePos then
                setPuddlesTransparency(1)
                lastPuddlePos = nil
            end
        end

        coverLevel = lerp(coverLevel, coverTarget, math.min(1, dt * 3))

        rainPart.CFrame = CFrame.new(camPos + Vector3.new(0, 50, 0))
        local totalRate = 4500 * scale * rainLevel * coverLevel
        for _, item in ipairs(rainEmitter) do
            item.Emitter.Rate = totalRate * item.Weight
        end

        -- Bokeh debu cahaya
        if bokehPart and bokehEmitter then
            local flat = Vector3.new(sunDir.X, 0, sunDir.Z)
            flat = flat.Magnitude > 0.01 and flat.Unit or Vector3.new(0, 0, -1)
            bokehPart.CFrame = CFrame.new(camPos + flat * 50 + Vector3.new(0, 8, 0))

            local strength = mood.Flare * Sun.Elev * Sun.Open * distFade * (0.4 + 0.6 * facing) * scale
            bokehEmitter.Rate = 12 * strength
        end

        if mood.WarmBody then
            updateBody(dt)
        end
    end

    function World.Destroy()
        applyClouds(nil)

        for _, puddle in ipairs(puddles) do
            for _, block in ipairs(puddle) do
                block:Destroy()
            end
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
-- LAMPU AKSEN
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
        return rgb(255, 160, 70)
    end
    if name:find("crystal") or name:find("ice") then
        return rgb(160, 215, 255)
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
            light.Brightness = 0.60
            light.Range = 14
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
local onSettingsChanged = function() end

function API.SetQuality(level)
    applyQuality(level)
end

function API.GetQuality()
    return State.Quality
end

function API.SetMood(name)
    if not MoodByName[name] then
        return false
    end
    State.Selected = { name }
    applyMoods()
    onSelectionChanged()
    return true
end

function API.SetMoods(names)
    local list = {}
    for _, name in ipairs(names) do
        if MoodByName[name] and #list < Settings.MaxCombinedMoods then
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

function API.ToggleMood(name)
    if not MoodByName[name] then
        return false
    end

    local index = table.find(State.Selected, name)
    if index then
        table.remove(State.Selected, index)
        if #State.Selected == 0 then
            table.insert(State.Selected, Moods[1].Name)
        end
    else
        if #State.Selected >= Settings.MaxCombinedMoods then
            table.remove(State.Selected, 1)
        end
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

function API.SetSunAnchor(position)
    Sun.Anchor = position
end

function API.ResetSunAnchor()
    Sun.Anchor = nil
end

function API.SetSetting(moodName, key, value)
    if not MoodByName[moodName] then
        return false
    end

    local def
    for _, d in ipairs(SettingDefs) do
        if d.Key == key then
            def = d
            break
        end
    end

    if not def then
        return false
    end

    value = clamp(value, def.Min, def.Max)
    MoodSettings[moodName][key] = value

    -- Jika mood ini sedang aktif, terapkan ulang
    if table.find(State.Selected, moodName) then
        applyMoods()
    end

    onSettingsChanged()
    return true
end

function API.GetSetting(moodName, key)
    if not MoodByName[moodName] then
        return nil
    end
    return MoodSettings[moodName][key]
end

function API.ResetSettings(moodName)
    if not MoodByName[moodName] then
        return false
    end
    for _, def in ipairs(SettingDefs) do
        MoodSettings[moodName][def.Key] = nil
    end
    if table.find(State.Selected, moodName) then
        applyMoods()
    end
    onSettingsChanged()
    return true
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
    styleJob = styleJob + 1

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

    restoreSky()
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

    if State.SettingsUI then
        State.SettingsUI:Destroy()
        State.SettingsUI = nil
    end

    if WorldFolder then
        WorldFolder:Destroy()
    end

    if _G.Leon4951Shaders == API then
        _G.Leon4951Shaders = nil
    end
    if _G.Leon4951Shaders_SerenityUltra == API then
        _G.Leon4951Shaders_SerenityUltra = nil
    end
end

API.Restore = restoreOriginal

----------------------------------------------------------------
-- UI SETTINGS PANEL (Slider per shader)
----------------------------------------------------------------
local function createSettingsUI()
    if not Settings.ShowPanel then
        return
    end

    local ACCENT = rgb(255, 160, 60)
    local W = 320
    local H = 420

    local tweenFast = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local gui = Instance.new("ScreenGui")
    gui.Name = ROOT .. "_Settings"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 51
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = PlayerGui

    local panel = Instance.new("Frame")
    panel.Name = "SettingsPanel"
    panel.AnchorPoint = Vector2.new(1, 0)
    panel.Position = UDim2.fromScale(0.985, 0.25)
    panel.Size = UDim2.fromOffset(W, H)
    panel.BackgroundColor3 = rgb(18, 16, 20)
    panel.BackgroundTransparency = 0.10
    panel.BorderSizePixel = 0
    panel.ClipsDescendants = true
    panel.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = panel

    local stroke = Instance.new("UIStroke")
    stroke.Color = ACCENT
    stroke.Transparency = 0.65
    stroke.Thickness = 1
    stroke.Parent = panel

    -- Title
    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(12, 0)
    title.Size = UDim2.fromOffset(W - 24, 32)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = rgb(255, 230, 190)
    title.Text = "PENGATURAN SHADER"
    title.Parent = panel

    -- Mood selector
    local moodSelector = Instance.new("Frame")
    moodSelector.BackgroundTransparency = 1
    moodSelector.Position = UDim2.fromOffset(12, 36)
    moodSelector.Size = UDim2.fromOffset(W - 24, 30)
    moodSelector.Parent = panel

    local moodButtons = {}
    local selectedMoodForSettings = Moods[1].Name

    local function refreshMoodButtons()
        for name, btn in pairs(moodButtons) do
            local isSelected = name == selectedMoodForSettings
            TweenService:Create(btn, tweenFast, {
                BackgroundColor3 = isSelected and rgb(70, 45, 25) or rgb(32, 30, 36),
                TextColor3 = isSelected and rgb(255, 235, 200) or rgb(185, 185, 195),
            }):Play()
        end
    end

    local btnW = (W - 24 - (#Moods - 1) * 4) / #Moods
    for i, mood in ipairs(Moods) do
        local btn = Instance.new("TextButton")
        btn.AutoButtonColor = false
        btn.Position = UDim2.fromOffset((i - 1) * (btnW + 4), 0)
        btn.Size = UDim2.fromOffset(btnW, 30)
        btn.BackgroundColor3 = rgb(32, 30, 36)
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.TextColor3 = rgb(185, 185, 195)
        btn.Text = mood.Name
        btn.Parent = moodSelector

        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0, 6)
        bc.Parent = btn

        btn.MouseButton1Click:Connect(function()
            selectedMoodForSettings = mood.Name
            refreshMoodButtons()
            refreshSliders()
        end)

        moodButtons[mood.Name] = btn
    end

    -- Scroll area for sliders
    local scroll = Instance.new("ScrollingFrame")
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.Position = UDim2.fromOffset(12, 72)
    scroll.Size = UDim2.fromOffset(W - 24, H - 110)
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = ACCENT
    scroll.CanvasSize = UDim2.fromOffset(0, 0)
    scroll.Parent = panel

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 8)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = scroll

    local sliders = {}

    local function createSlider(def, index)
        local container = Instance.new("Frame")
        container.BackgroundTransparency = 1
        container.Size = UDim2.fromOffset(W - 30, 50)
        container.LayoutOrder = index
        container.Parent = scroll

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Position = UDim2.fromOffset(0, 0)
        label.Size = UDim2.fromOffset(W - 30, 16)
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 10
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextColor3 = rgb(180, 180, 190)
        label.Text = def.Label
        label.Parent = container

        local valueLabel = Instance.new("TextLabel")
        valueLabel.BackgroundTransparency = 1
        valueLabel.Position = UDim2.fromOffset(W - 80, 0)
        valueLabel.Size = UDim2.fromOffset(80, 16)
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.TextSize = 10
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.TextColor3 = ACCENT
        valueLabel.Text = "-"
        valueLabel.Parent = container

        -- Slider track
        local track = Instance.new("Frame")
        track.Position = UDim2.fromOffset(0, 22)
        track.Size = UDim2.fromOffset(W - 30, 6)
        track.BackgroundColor3 = rgb(45, 42, 50)
        track.BorderSizePixel = 0
        track.Parent = container

        local trackCorner = Instance.new("UICorner")
        trackCorner.CornerRadius = UDim.new(0, 3)
        trackCorner.Parent = track

        -- Slider fill
        local fill = Instance.new("Frame")
        fill.Size = UDim2.fromScale(0.5, 1)
        fill.BackgroundColor3 = ACCENT
        fill.BorderSizePixel = 0
        fill.Parent = track

        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 3)
        fillCorner.Parent = fill

        -- Slider knob
        local knob = Instance.new("Frame")
        knob.AnchorPoint = Vector2.new(0.5, 0.5)
        knob.Position = UDim2.fromScale(0.5, 0.5)
        knob.Size = UDim2.fromOffset(14, 14)
        knob.BackgroundColor3 = rgb(255, 255, 255)
        knob.BorderSizePixel = 0
        knob.Parent = track

        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(1, 0)
        knobCorner.Parent = knob

        local knobStroke = Instance.new("UIStroke")
        knobStroke.Color = ACCENT
        knobStroke.Thickness = 2
        knobStroke.Parent = knob

        local sliderData = {
            Def = def,
            Container = container,
            Track = track,
            Fill = fill,
            Knob = knob,
            ValueLabel = valueLabel,
            Value = 0,
        }

        local function updateVisual(val)
            local pct = (val - def.Min) / (def.Max - def.Min)
            pct = clamp01(pct)
            fill.Size = UDim2.fromScale(pct, 1)
            knob.Position = UDim2.fromScale(pct, 0.5)
            valueLabel.Text = string.format("%.3f", val)
        end

        local dragging = false

        local function startDrag(input)
            dragging = true
            local function updateFromInput(input)
                local trackPos = track.AbsolutePosition.X
                local trackSize = track.AbsoluteSize.X
                local mouseX = input.Position.X
                local pct = clamp01((mouseX - trackPos) / trackSize)
                local val = def.Min + pct * (def.Max - def.Min)

                -- Snap to step
                val = math.floor(val / def.Step + 0.5) * def.Step
                val = clamp(val, def.Min, def.Max)

                sliderData.Value = val
                updateVisual(val)
                API.SetSetting(selectedMoodForSettings, def.Key, val)
            end

            updateFromInput(input)

            local conn
            conn = UserInputService.InputChanged:Connect(function(input)
                if not dragging then
                    conn:Disconnect()
                    return
                end
                if input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch then
                    updateFromInput(input)
                end
            end)

            local endConn
            endConn = UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                    conn:Disconnect()
                    endConn:Disconnect()
                end
            end)
        end

        knob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                startDrag(input)
            end
        end)

        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                startDrag(input)
            end
        end)

        sliderData.UpdateVisual = updateVisual

        sliders[def.Key] = sliderData
    end

    for i, def in ipairs(SettingDefs) do
        createSlider(def, i)
    end

    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.fromOffset(0, list.AbsoluteContentSize.Y + 10)
    end)

    -- Reset button
    local resetBtn = Instance.new("TextButton")
    resetBtn.AutoButtonColor = false
    resetBtn.Position = UDim2.fromOffset(12, H - 32)
    resetBtn.Size = UDim2.fromOffset(W - 24, 24)
    resetBtn.BackgroundColor3 = rgb(60, 35, 20)
    resetBtn.BorderSizePixel = 0
    resetBtn.Font = Enum.Font.GothamBold
    resetBtn.TextSize = 10
    resetBtn.TextColor3 = rgb(255, 220, 180)
    resetBtn.Text = "RESET PENGATURAN MOOD INI"
    resetBtn.Parent = panel

    local resetCorner = Instance.new("UICorner")
    resetCorner.CornerRadius = UDim.new(0, 6)
    resetCorner.Parent = resetBtn

    resetBtn.MouseButton1Click:Connect(function()
        API.ResetSettings(selectedMoodForSettings)
    end)

    -- Refresh sliders when mood changes
    function refreshSliders()
        for _, def in ipairs(SettingDefs) do
            local slider = sliders[def.Key]
            if slider then
                local val = MoodSettings[selectedMoodForSettings][def.Key]
                if val == nil then
                    val = MoodByName[selectedMoodForSettings][def.Key] or def.Default or def.Min
                end
                slider.Value = val
                slider.UpdateVisual(val)
            end
        end
    end

    refreshMoodButtons()
    refreshSliders()

    onSettingsChanged = refreshSliders

    -- Dragging
    local draggingPanel = false
    local dragStart, startAbs

    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            draggingPanel = true
            dragStart = input.Position
            startAbs = panel.AbsolutePosition
        end
    end)

    title.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            draggingPanel = false
        end
    end)

    table.insert(State.Connections, UserInputService.InputChanged:Connect(function(input)
        if not draggingPanel then
            return
        end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local screen = gui.AbsoluteSize
        local delta = input.Position - dragStart
        local panelSize = panel.AbsoluteSize

        local x = math.clamp(startAbs.X + delta.X, panelSize.X, screen.X)
        local y = math.clamp(startAbs.Y + delta.Y, 0, math.max(0, screen.Y - 30))

        panel.Position = UDim2.fromScale(x / screen.X, y / screen.Y)
    end))

    State.SettingsUI = gui
end

----------------------------------------------------------------
-- UI PANEL UTAMA
----------------------------------------------------------------
local function createUI()
    if not Settings.ShowPanel then
        return
    end

    local ACCENT = rgb(255, 160, 60)
    local W = 220
    local TITLE_H = 30
    local BODY_H = 300
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
    panel.Position = UDim2.fromScale(0.015, 0.25)
    panel.Size = UDim2.fromOffset(W, TITLE_H + BODY_H)
    panel.BackgroundColor3 = rgb(18, 16, 20)
    panel.BackgroundTransparency = 0.10
    panel.BorderSizePixel = 0
    panel.ClipsDescendants = true
    panel.Parent = gui

    local uiScale = Instance.new("UIScale")
    uiScale.Scale = SCALES[scaleIndex]
    uiScale.Parent = panel

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = panel

    local stroke = Instance.new("UIStroke")
    stroke.Color = ACCENT
    stroke.Transparency = 0.65
    stroke.Thickness = 1
    stroke.Parent = panel

    local function makeButton(parent, text, x, y, w, h)
        local b = Instance.new("TextButton")
        b.AutoButtonColor = false
        b.Position = UDim2.fromOffset(x, y)
        b.Size = UDim2.fromOffset(w, h)
        b.BackgroundColor3 = rgb(38, 36, 42)
        b.BorderSizePixel = 0
        b.Font = Enum.Font.GothamBold
        b.TextSize = 11
        b.TextColor3 = rgb(220, 220, 225)
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
    title.Position = UDim2.fromOffset(12, 0)
    title.Size = UDim2.fromOffset(W - 80, TITLE_H)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = rgb(255, 230, 190)
    title.Text = "Leon4951 Serenity"
    title.Parent = panel

    local sizeButton = makeButton(panel, "A", W - 66, 5, 26, 20)
    local collapseButton = makeButton(panel, "-", W - 36, 5, 26, 20)

    local body = Instance.new("Frame")
    body.BackgroundTransparency = 1
    body.Position = UDim2.fromOffset(0, TITLE_H)
    body.Size = UDim2.fromOffset(W, BODY_H)
    body.Parent = panel

    -- Kualitas
    local qLabel = Instance.new("TextLabel")
    qLabel.BackgroundTransparency = 1
    qLabel.Position = UDim2.fromOffset(12, 4)
    qLabel.Size = UDim2.fromOffset(80, 22)
    qLabel.Font = Enum.Font.GothamMedium
    qLabel.TextSize = 10
    qLabel.TextXAlignment = Enum.TextXAlignment.Left
    qLabel.TextColor3 = rgb(180, 180, 190)
    qLabel.Text = "KUALITAS"
    qLabel.Parent = body

    local qMinus = makeButton(body, "-", W - 96, 4, 26, 20)
    local qValue = Instance.new("TextLabel")
    qValue.BackgroundTransparency = 1
    qValue.Position = UDim2.fromOffset(W - 68, 4)
    qValue.Size = UDim2.fromOffset(32, 20)
    qValue.Font = Enum.Font.GothamBold
    qValue.TextSize = 12
    qValue.TextColor3 = ACCENT
    qValue.Parent = body
    local qPlus = makeButton(body, "+", W - 36, 4, 26, 20)

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

    -- Info kombinasi
    local comboLabel = Instance.new("TextLabel")
    comboLabel.BackgroundTransparency = 1
    comboLabel.Position = UDim2.fromOffset(12, 30)
    comboLabel.Size = UDim2.fromOffset(W - 24, 16)
    comboLabel.Font = Enum.Font.GothamMedium
    comboLabel.TextSize = 9
    comboLabel.TextXAlignment = Enum.TextXAlignment.Left
    comboLabel.TextColor3 = rgb(150, 150, 165)
    comboLabel.Text = "Kombinasi Maks: 2 Shaders"
    comboLabel.Parent = body

    -- Daftar suasana
    local listLabel = Instance.new("TextLabel")
    listLabel.BackgroundTransparency = 1
    listLabel.Position = UDim2.fromOffset(12, 50)
    listLabel.Size = UDim2.fromOffset(W - 24, 16)
    listLabel.Font = Enum.Font.GothamMedium
    listLabel.TextSize = 10
    listLabel.TextXAlignment = Enum.TextXAlignment.Left
    listLabel.TextColor3 = rgb(180, 180, 190)
    listLabel.Text = "SUASANA"
    listLabel.Parent = body

    local scroll = Instance.new("ScrollingFrame")
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.Position = UDim2.fromOffset(10, 70)
    scroll.Size = UDim2.fromOffset(W - 20, 180)
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
                BackgroundColor3 = on and rgb(70, 45, 25) or rgb(32, 30, 36),
                TextColor3 = on and rgb(255, 235, 200) or rgb(185, 185, 195),
            }):Play()
            TweenService:Create(row.Dot, tweenFast, {
                BackgroundColor3 = on and ACCENT or rgb(75, 75, 85),
            }):Play()
        end
    end

    for index, mood in ipairs(Moods) do
        local button = Instance.new("TextButton")
        button.AutoButtonColor = false
        button.LayoutOrder = index
        button.Size = UDim2.new(1, -6, 0, 28)
        button.BackgroundColor3 = rgb(32, 30, 36)
        button.BorderSizePixel = 0
        button.Font = Enum.Font.GothamMedium
        button.TextSize = 11
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.TextColor3 = rgb(185, 185, 195)
        button.Text = "  " .. (mood.Icon or "") .. "  " .. mood.Name
        button.Parent = scroll

        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0, 6)
        bc.Parent = button

        local dot = Instance.new("Frame")
        dot.AnchorPoint = Vector2.new(1, 0.5)
        dot.Position = UDim2.new(1, -8, 0.5, 0)
        dot.Size = UDim2.fromOffset(7, 7)
        dot.BackgroundColor3 = rgb(75, 75, 85)
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
    status.Position = UDim2.fromOffset(12, BODY_H - 28)
    status.Size = UDim2.fromOffset(W - 86, 22)
    status.Font = Enum.Font.Gotham
    status.TextSize = 9
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextTruncate = Enum.TextTruncate.AtEnd
    status.TextColor3 = rgb(140, 140, 155)
    status.Parent = body

    local offButton = makeButton(body, "Matikan", W - 72, BODY_H - 28, 62, 22)
    offButton.TextSize = 10
    offButton.MouseButton1Click:Connect(function()
        restoreOriginal()
    end)

    onSelectionChanged = refreshRows
    refreshRows()

    task.spawn(function()
        while gui.Parent do
            status.Text = string.format(
                "%s | Egg %d | FPS %d",
                selectedLabel(),
                State.Stats.Eggs,
                State.Stats.FPS
            )
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

    -- Geser
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

    -- Toggle UI dengan RightCtrl
    table.insert(State.Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end
        if input.KeyCode == Enum.KeyCode.RightControl then
            gui.Enabled = not gui.Enabled
            if State.SettingsUI then
                State.SettingsUI.Enabled = not State.SettingsUI.Enabled
            end
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

    fpsAccumulator = fpsAccumulator + dt
    fpsFrames = fpsFrames + 1
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

    lightTimer = lightTimer + dt
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
                light.Brightness = lerp(0.15, 0.80, factor)
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
        if ScanDone and processPart(object) and State.Mood then
            stylePart(object, State.Mood)
        end
    end)
end))

----------------------------------------------------------------
-- MULAI
----------------------------------------------------------------
_G.Leon4951Shaders = API
_G.Leon4951Shaders_SerenityUltra = API

configureLightingBase()
applyQuality(Settings.Quality)

task.spawn(function()
    scanWorld()
    styleParts(State.Mood)
    scanAccentLights()
end)

createUI()
createSettingsUI()

----------------------------------------------------------------
-- CARA PAKAI (API)
----------------------------------------------------------------
-- _G.Leon4951Shaders.SetMood("Sore")
-- _G.Leon4951Shaders.SetMoods({"Sore", "Kabut"})   -- kombinasi 2
-- _G.Leon4951Shaders.ToggleMood("Hujan")
-- _G.Leon4951Shaders.SetQuality(10)
-- _G.Leon4951Shaders.SetSetting("Sore", "Brightness", 2.3)
-- _G.Leon4951Shaders.SetSetting("Sore", "SunGlow", 1.5)
-- _G.Leon4951Shaders.ResetSettings("Sore")
-- _G.Leon4951Shaders.SetSunAnchor(Vector3.new(0, 0, 0))
-- _G.Leon4951Shaders.Restore()
----------------------------------------------------------------