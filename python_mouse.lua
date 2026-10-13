--[[
    FPS BOOST / PERFORMANCE ONLY
    Diambil APA ADANYA dari SENA_LUA_SCRIPT, jalur:
      Misc > Performance > Startup Boost / Boost FPS / Uncap FPS

    Isi kode di bawah adalah kode asli (v390/t15.revert = Startup Boost,
    v391 = Boost FPS, v4720 = Uncap FPS). Yang dibuang: UI hub, auto steal,
    anti guard, anti trap, fly, visual spoof, dan semua logic exploit lain.

    Nilai default sama seperti hub:
      Startup Boost = ON, Uncap FPS = ON, Boost FPS = OFF (di sini diaktifkan,
      ubah Config.BoostFps kalau mau default aslinya).
]]

local Config = {
	StartupBoost = true,
	BoostFps     = true,
	UncapFps     = true,
}

---------------------------------------------------------------------
-- DEPENDENSI (dulu dibuat di bagian atas script hub)
---------------------------------------------------------------------
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer       = Players.LocalPlayer
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")

local genv = getgenv and getgenv() or _G
local senaV4Config = {}                       -- tabel state (_fps*, StartupBoost)
local v14 = function()                        -- folder world milik game
	return Workspace:FindFirstChild("World") or Workspace:FindFirstChild("__OBJECTS")
end
local v16 = function() return true end        -- cek session hub (selalu aktif)

---------------------------------------------------------------------
-- UNCAP FPS: helper setfpscap (asli)
---------------------------------------------------------------------
genv.__SenaV4SetCapFps = function(p1)
local v37 = math.clamp(math.floor(tonumber(p1) or 240), 1, 999)
local setfpscap_ = rawget(_G, "setfpscap") or rawget(_G, "set_fps_cap") or type(setfpscap) == "function" and setfpscap
if type(setfpscap_) == "function" then
return pcall(setfpscap_, v37)
end
return false
end

---------------------------------------------------------------------
-- STARTUP BOOST + BOOST FPS (asli): t15 / v390 / v391
---------------------------------------------------------------------
if type(genv.__SenaV4DecomBoostCleanup) == "function" then
pcall(genv.__SenaV4DecomBoostCleanup) end
local t15, v390, v391
do
local t16 = {}
local u393 = false
genv.__SenaV4DecomBoostCleanup = function()
for _, v in ipairs(t16) do
pcall(function()
v:Disconnect()
end)
end
table.clear(t16)
u393 = false
end
local function v396()
local ClientRenderedAssets = workspace:FindFirstChild("ClientRenderedAssets")
if not ClientRenderedAssets then
return
end
for _, child in ipairs(ClientRenderedAssets:GetChildren()) do
pcall(function()
child.Parent = nil
end)
end
end
local function v400(p82)
return string.sub(p82.Name, 1, #tostring(LocalPlayer.UserId) + 1) == tostring(LocalPlayer.UserId) .. "_"
end
local function v401()
for _, child in ipairs(workspace:GetChildren()) do
if child.Name == "PlacedEggRenders" then
for _, child2 in ipairs(child:GetChildren()) do
pcall(function()
if not child2:FindFirstChildOfClass("ProximityPrompt") then
if not v400(child2) then
child2.Parent = nil
end
end
end)
end
end
end
end
local function v406()
for _, v in ipairs({
"Transient",
"__DEBRIS"
}) do
local v409 = workspace:FindFirstChild(v)
if v409 then
for _, child in ipairs(v409:GetChildren()) do
if child.Name ~= "PlayerTrap" then
if not child.Name:lower():find("trap") then
continue
end
end
pcall(function()
child:Destroy()
end)
end
end
end
end
local function v412(p83)
if not p83:FindFirstAncestor("SenaVisualBack") then
if not p83:FindFirstAncestor("SenaVisualRemote") then
local Tool = p83:FindFirstAncestorWhichIsA("Tool")
return Tool ~= nil and Tool:GetAttribute("SenaVisual") ~= nil
end
end
return true
end
t15 = {
effects = {},
parts = {},
decals = {},
snapshot = nil
}
local t17 = {
PlusOne = true,
SpeedGainPopup = true,
SellPayout = true,
SyncedIncomeCash = true
}
local t18 = {
PlayerPlotSign = true,
CanUpgrade = true,
AlertGui = true,
OfflineMoneyClaimBillboard = true
}
local function v416(descendant)
pcall(function()
if v412(descendant) then
return
end
if t17[descendant.Name] then
descendant:Destroy()
return
end
if descendant:IsA("BillboardGui") and t18[descendant.Name] then
if descendant.Enabled then
t15.effects[descendant] = true
end
descendant.Enabled = false
return
end
if descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") or descendant:IsA("Beam") or descendant:IsA("Sparkles") or descendant:IsA("Fire") or descendant:IsA("Smoke") or descendant:IsA("PostEffect") then
if descendant.Enabled then
t15.effects[descendant] = true
end
descendant.Enabled = false
end
end)
end
local function v417()
if u393 then
return
end
u393 = true
table.insert(t16, game.DescendantAdded:Connect(v416))
table.insert(t16, workspace.ChildAdded:Connect(function(child)
if child.Name == "ClientRenderedAssets" then
v396()
table.insert(t16, child.ChildAdded:Connect(function(child2)
pcall(function()
child2.Parent = nil
end)
end))
elseif child.Name == "PlacedEggRenders" then
v401()
table.insert(t16, child.ChildAdded:Connect(function(child2)
pcall(function()
if not child2:FindFirstChildOfClass("ProximityPrompt") and not v400(child2) then
child2.Parent = nil
end
end)
end))
elseif child.Name == "__DEBRIS" or child.Name == "Transient" then
table.insert(t16, child.ChildAdded:Connect(function(child2)
if child2.Name == "PlayerTrap" then
pcall(function()
child2:Destroy()
end)
return
elseif child2.Name:lower():find("trap") then
pcall(function()
child2:Destroy()
end)
end
end))
end
end))
local ClientRenderedAssets = workspace:FindFirstChild("ClientRenderedAssets")
if ClientRenderedAssets then
table.insert(t16, ClientRenderedAssets.ChildAdded:Connect(function(child)
pcall(function()
child.Parent = nil
end)
end))
end
for _, child in ipairs(workspace:GetChildren()) do
if child.Name == "PlacedEggRenders" then
table.insert(t16, child.ChildAdded:Connect(function(child2)
pcall(function()
if not child2:FindFirstChildOfClass("ProximityPrompt") then
if not v400(child2) then
child2.Parent = nil
end
end
end)
end))
end
end
end
local u421 = false
v390 = function()
if u421 then
return
end
u421 = true
local Lighting = game:GetService("Lighting")
if not t15.snapshot then
local t19 = {}
pcall(function()
t19.quality = settings().Rendering.QualityLevel
t19.throttle = settings().Physics.PhysicsEnvironmentalThrottle
t19.technology = Lighting.Technology
t19.shadows = Lighting.GlobalShadows
t19.fogEnd = Lighting.FogEnd
t19.brightness = Lighting.Brightness
t19.ambient = Lighting.Ambient
t19.outdoorAmbient = Lighting.OutdoorAmbient
end)
local Terrain = workspace:FindFirstChildOfClass("Terrain")
if Terrain then
pcall(function()
t19.terrain = {
WaterWaveSize = Terrain.WaterWaveSize,
WaterWaveSpeed = Terrain.WaterWaveSpeed,
WaterReflectance = Terrain.WaterReflectance,
WaterTransparency = Terrain.WaterTransparency,
Decoration = Terrain.Decoration
}
end)
pcall(function()
local Clouds = Terrain:FindFirstChildOfClass("Clouds")
if Clouds then
t19.cloudsEnabled = Clouds.Enabled
end
end)
end
pcall(function()
local Preferences = ReplicatedStorage.Shared:FindFirstChild("Preferences")
if Preferences then
local module = require(Preferences)
t19.prefs = {
HideOtherPets = module.IsOn("HideOtherPets"),
DisableVideos = module.IsOn("DisableVideos")
}
end
end)
if t19.quality == Enum.QualityLevel.Level01 then
t19.quality = Enum.QualityLevel.Automatic
end
t15.snapshot = genv.__SenaV4DecomSnapshot or t19
genv.__SenaV4DecomSnapshot = t15.snapshot
end
pcall(function()
settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Always
Lighting.Technology = Enum.Technology.Compatibility
Lighting.GlobalShadows = false
Lighting.FogEnd = 9e9
Lighting.Brightness = 2
Lighting.Ambient = Color3.new(1, 1, 1)
Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
end)
local now = os.clock()
for _, v in ipairs({
workspace,
Lighting
}) do
for _, descendant in ipairs(v:GetDescendants()) do
if not v412(descendant) then
if descendant:IsA("BasePart") then
pcall(function()
if not t15.parts[descendant] then
t15.parts[descendant] = {
descendant.Material,
descendant.CastShadow,
descendant:IsA("MeshPart") and descendant.RenderFidelity or nil
}
end
descendant.Material = Enum.Material.SmoothPlastic
descendant.CastShadow = false
if descendant:IsA("MeshPart") then
descendant.RenderFidelity = Enum.RenderFidelity.Performance
end
end)
else
if descendant:IsA("Decal") then
pcall(function()
if descendant.Texture ~= "" and not t15.decals[descendant] then
t15.decals[descendant] = descendant.Texture
end
descendant.Texture = ""
end)
if os.clock() - now > 0.004 then
task.wait()
now = os.clock()
end
continue
end
if descendant:IsA("Texture") then
pcall(function()
if descendant.Texture ~= "" and not t15.decals[descendant] then
t15.decals[descendant] = descendant.Texture
end
descendant.Texture = ""
end)
else
v416(descendant)
end
end
if os.clock() - now > 0.004 then
task.wait()
now = os.clock()
end
end
end
end
local Terrain = workspace:FindFirstChildOfClass("Terrain")
if Terrain then
pcall(function()
Terrain.WaterWaveSize = 0
Terrain.WaterWaveSpeed = 0
Terrain.WaterReflectance = 0
Terrain.WaterTransparency = 1
Terrain.Decoration = false
local Clouds = Terrain:FindFirstChildOfClass("Clouds")
if Clouds then
Clouds.Enabled = false
end
end)
end
pcall(function()
local Shared = ReplicatedStorage.Shared
local Preferences = Shared:FindFirstChild("Preferences")
if Preferences then
local module = require(Preferences)
module.Set("HideOtherPets", true)
module.Set("DisableVideos", true)
else
local SettingsCmds = require(Shared.SettingsCmds)
SettingsCmds.Write("HideOtherPets", true)
SettingsCmds.Write("DisableVideos", true)
end
end)
v396()
v401()
v406()
v417()
u421 = false
end
t15.revert = function()
for _, v in ipairs(t16) do
pcall(function()
v:Disconnect()
end)
end
table.clear(t16)
u393 = false
local snapshot = t15.snapshot
local Lighting = game:GetService("Lighting")
if snapshot then
pcall(function()
settings().Rendering.QualityLevel = snapshot.quality or Enum.QualityLevel.Automatic
end)
pcall(function()
settings().Physics.PhysicsEnvironmentalThrottle = snapshot.throttle
end)
pcall(function()
Lighting.Technology = snapshot.technology
Lighting.GlobalShadows = snapshot.shadows
Lighting.FogEnd = snapshot.fogEnd
Lighting.Brightness = snapshot.brightness
Lighting.Ambient = snapshot.ambient
Lighting.OutdoorAmbient = snapshot.outdoorAmbient
end)
local Terrain = workspace:FindFirstChildOfClass("Terrain")
if Terrain and snapshot.terrain then
for k, v in pairs(snapshot.terrain) do
pcall(function()
Terrain[k] = v
end)
end
if snapshot.cloudsEnabled ~= nil then
pcall(function()
local Clouds = Terrain:FindFirstChildOfClass("Clouds")
if Clouds then
Clouds.Enabled = snapshot.cloudsEnabled
end
end)
end
end
if snapshot.prefs then
pcall(function()
local Preferences = require(ReplicatedStorage.Shared.Preferences)
for k, pref in pairs(snapshot.prefs) do
Preferences.Set(k, pref)
end
end)
end
end
local n10 = 0
for k, part in pairs(t15.parts) do
if k.Parent then
pcall(function()
k.Material = part[1]
k.CastShadow = part[2]
if part[3] ~= nil and k:IsA("MeshPart") then
k.RenderFidelity = part[3]
end
end)
end
n10 += 1
if n10 % 400 == 0 then
task.wait()
end
end
for k, decal in pairs(t15.decals) do
if k.Parent then
pcall(function()
k.Texture = decal
end)
end
end
for k in pairs(t15.effects) do
if k.Parent then
pcall(function()
k.Enabled = true
end)
end
end
t15.parts = {}
t15.decals = {}
t15.effects = {}
t15.snapshot = nil
end
genv.__SenaV4DecomBoostUndo = t15
local u456 = false
local function v457(p84)
if not p84 or not p84:IsA("Model") then
return
end
local match = p84.Name:match("^(%d+)_")
local v459 = match and tonumber(match)
if not v459 or v459 == LocalPlayer.UserId then
return
end
for _, descendant in ipairs(p84:GetDescendants()) do
if descendant:IsA("BasePart") then
descendant.Transparency = 1
descendant.CanCollide = false
elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
descendant.Transparency = 1
elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") or descendant:IsA("Beam") then
descendant.Enabled = false
elseif descendant:IsA("BillboardGui") or descendant:IsA("SurfaceGui") then
descendant.Enabled = false
end
end
end
local function v462()
if senaV4Config._fpsEggsReady then
return true
end
local u463 = false
local ok, result = pcall(function()
local v466 = require(game:GetService("ReplicatedStorage").Shared.Eggs.PlacedEggRenderer).GetRenderFolder()
if not v466 then
return
end
local children = v466:GetChildren()
for _, child in ipairs(children) do
v457(child)
end
v466.ChildAdded:Connect(function(child)
task.defer(v457, child)
end)
u463 = true
end)
if not ok then
warn("[FPSBoost] Gagal hide egg pemain lain:", result)
return false
end
return u463
end
local function v470(p85)
if not p85 then
return
end
pcall(function()
p85.Parent = nil
end)
end
local function v471()
if senaV4Config._fpsPetsReady then
return true
end
local IsOn
local ok, result = pcall(function()
local Shared = game:GetService("ReplicatedStorage").Shared
local Preferences = Shared:FindFirstChild("Preferences")
if Preferences then
local module = require(Preferences)
module.Set("HideOtherPets", true)
IsOn = module.IsOn
else
local SettingsCmds = require(Shared.SettingsCmds)
SettingsCmds.Write("HideOtherPets", true)
IsOn = SettingsCmds.Allows
end
end)
local v479 = false
if ok and IsOn then
local ok2, result2 = pcall(IsOn, "HideOtherPets")
v479 = ok2 and result2 == true
end
if ok then
if v479 then
local u482 = false
local ok2, result2 = pcall(function()
local ClientRenderedAssets = workspace:FindFirstChild("ClientRenderedAssets") or workspace:WaitForChild("ClientRenderedAssets", 10)
if not ClientRenderedAssets then
return
end
local children = ClientRenderedAssets:GetChildren()
for _, child in ipairs(children) do
v470(child)
end
ClientRenderedAssets.ChildAdded:Connect(function(child)
task.defer(v470, child)
end)
u482 = true
end)
if not ok2 then
warn("[FPSBoost] Gagal hide pet (manual):", result2)
return false
end
return u482
end
end
warn("[FPSBoost] Gagal set HideOtherPets bawaan game:", result or "setting belum aktif")
return false
end
local function v489()
if type(genv.__SenaV4SetCapFps) == "function" then
pcall(genv.__SenaV4SetCapFps, 240)
end
pcall(function()
settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
end)
local function v490()
UserSettings():GetService("UserGameSettings").SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
end
pcall(v490)
pcall(function()
require(game:GetService("ReplicatedStorage").Client.LightingsController):SetModifier("FPSBoost", function(p86)
local v491 = table.clone(p86)
v491.Bloom = nil
v491.ColorCorrection = nil
v491.SunRays = nil
v491.DepthOfField = nil
v491.Blur = nil
v491.Clouds = nil
v491.Atmosphere = nil
v491.ShadowSoftness = 1
return v491
end, 100, 0)
end)
pcall(function()
local Lighting = game:GetService("Lighting")
Lighting.GlobalShadows = false
Lighting.Technology = Enum.Technology.Compatibility
Lighting.FogEnd = 9e9
Lighting.Brightness = 2
end)
pcall(function()
local Terrain = workspace:FindFirstChildOfClass("Terrain")
if Terrain then
Terrain.WaterWaveSize = 0
Terrain.WaterWaveSpeed = 0
Terrain.WaterReflectance = 0
Terrain.WaterTransparency = 1
Terrain.Decoration = false
end
end)
pcall(function()
local __DEBRIS = workspace:FindFirstChild("__DEBRIS")
if __DEBRIS then
for _, child in ipairs(__DEBRIS:GetChildren()) do
if child.Name == "PlayerTrap" then
pcall(function()
child:Destroy()
end)
end
end
end
end)
end
local color3 = Color3.fromRGB(120, 120, 120)
local function v498(p87)
if not p87 or not p87:IsA("BasePart") then
return
end
p87.Material = Enum.Material.SmoothPlastic
p87.Color = color3
p87.CastShadow = false
end
local function v499(p88)
if p88:IsA("ParticleEmitter") then
p88.Enabled = false
p88.Rate = 0
pcall(function()
p88:Clear()
end)
elseif p88:IsA("Trail") or p88:IsA("Beam") or p88:IsA("Smoke") or p88:IsA("Fire") or p88:IsA("Sparkles") or p88:IsA("PostEffect") or p88:IsA("Light") or p88:IsA("Highlight") or p88:IsA("Clouds") then
p88.Enabled = false
elseif p88:IsA("Atmosphere") then
p88.Density = 0
p88.Haze = 0
p88.Glare = 0
elseif p88:IsA("Explosion") then
pcall(function()
p88.Visible = false
end)
end
end
local function v500()
if senaV4Config._fpsWorldReady then
return true
end
local u501 = false
local t20 = {}
local ok, result = pcall(function()
local function v505(p89)
if v412(p89) then
return
end
v498(p89)
v499(p89)
end
local t21 = {
workspace,
game:GetService("Lighting")
}
for _, v in ipairs(t21) do
table.insert(t20, v.DescendantAdded:Connect(function(descendant)
task.defer(v505, descendant)
end))
end
local t22 = {}
for _, v in ipairs(t21) do
for _, child in ipairs(v:GetChildren()) do
table.insert(t22, child)
end
end
local n11 = 0
while #t22 > 0 do
local v515 = table.remove(t22)
v505(v515)
for _, child in ipairs(v515:GetChildren()) do
table.insert(t22, child)
end
n11 += 1
if n11 >= 250 and #t22 > 0 then
n11 = 0
RunService.Heartbeat:Wait()
end
end
u501 = true
end)
if ok then
return u501
end
for _, v in ipairs(t20) do
v:Disconnect()
end
warn("[FPSBoost] Gagal flatten material workspace:", result)
return false
end
local function v520()
if senaV4Config._fpsAreasReady then
return true
end
local v521 = v14()
local Areas = v521 and v521:FindFirstChild("Areas")
local GuardAreas = Areas and Areas:FindFirstChild("GuardAreas")
local Build = v521 and v521:FindFirstChild("Build")
if not GuardAreas or not Build then
return false
end
for _, child in ipairs(GuardAreas:GetChildren()) do
local RequiredSpeedSign = child:FindFirstChild("RequiredSpeedSign")
if RequiredSpeedSign then
pcall(function()
RequiredSpeedSign:Destroy()
end)
end
end
local MainMap = Build:FindFirstChild("MainMap")
local Bases = MainMap and MainMap:FindFirstChild("Bases")
local function v530(p90)
if Bases and p90:IsDescendantOf(Bases) then
return p90.Size.Y <= 5 and not string.find(string.upper(p90.Name), "WALL", 1, true)
end
local Parent = p90
while true do
if not Parent or Parent == Build then
return false
end
if not string.find(string.upper(Parent.Name), "BOTTOM", 1, true) then
Parent = Parent.Parent
continue
end
break
end
return true
end
local t23 = {
"ENCHANTED",
"FUSEBIOME",
"WISP",
"BUTTERFLY",
"MARKERS",
"PORTAL",
"TRIGGER"
}
local function v533(p91)
if p91:FindFirstChildOfClass("TouchTransmitter") or p91:FindFirstChildWhichIsA("ProximityPrompt", true) then
return true
end
local Parent = p91
while true do
if not Parent then
return false
end
if Parent == Build then
return false
end
local v535 = string.upper(Parent.Name)
for _, v in ipairs(t23) do
if string.find(v535, v, 1, true) then
return true
end
end
Parent = Parent.Parent
end
end
local function v538(p92)
if not p92:IsA("BasePart") then
return
end
if v533(p92) then
return
end
if v530(p92) then
v498(p92)
else
pcall(function()
p92:Destroy()
end)
end
end
local connection = Build.DescendantAdded:Connect(function(descendant)
task.defer(v538, descendant)
end)
local n12 = 0
local fpsAreaDeleted = 0
for _, descendant in ipairs(Build:GetDescendants()) do
local v544 = descendant.Parent ~= nil
v538(descendant)
if v544 and descendant.Parent == nil then
fpsAreaDeleted += 1
end
n12 += 1
if n12 >= 250 then
n12 = 0
RunService.Heartbeat:Wait()
end
end
senaV4Config._fpsAreaListener = connection
senaV4Config._fpsAreaDeleted = fpsAreaDeleted
senaV4Config._fpsAreasReady = true
return true
end
local function v545()
if senaV4Config._fpsPlotsReady then
return true
end
local u546 = false
local ok, result = pcall(function()
local PlotState2 = require(game:GetService("ReplicatedStorage").Client.PlotState)
if PlotState2.GetMySlot() == nil then
warn("[FPSBoost] Slot plot kita belum ke-resolve, skip delete plot dulu (biar aman).")
return
end
local function v550(p93)
local v551 = PlotState2.GetMySlot()
return v551 ~= nil and p93.Name == tostring(v551)
end
local Plots = PlotState2.GetPlotsFolder() or workspace:WaitForChild("Plots", 10)
if not Plots then
warn("[FPSBoost] workspace.Plots gak ketemu sama sekali.")
return
end
local children = Plots:GetChildren()
local n13 = 0
for _, child in ipairs(children) do
if not v550(child) and pcall(function()
child:Destroy()
end) then
n13 += 1
end
end
Plots.ChildAdded:Connect(function(child)
task.defer(function()
if child.Parent then
if not v550(child) then
pcall(function()
child:Destroy()
end)
end
end
end)
end)
u546 = true
end)
if ok then
return u546
end
warn("[FPSBoost] Gagal delete plot pemain lain:", result)
return false
end
local function v557()
if senaV4Config._fpsTreadmillsReady then
return true
end
local u558 = false
local ok, result = pcall(function()
local ReplicatedStorage2 = game:GetService("ReplicatedStorage")
local PlotState2 = require(ReplicatedStorage2.Client.PlotState)
local v563
local Modules = ReplicatedStorage2.Client:FindFirstChild("Modules") or ReplicatedStorage2.Client:WaitForChild("Modules", 10)
local RuntimeInstanceRegistry = Modules and (Modules:FindFirstChild("RuntimeInstanceRegistry") or Modules:WaitForChild("RuntimeInstanceRegistry", 10))
if RuntimeInstanceRegistry then
local ok, result = pcall(require, RuntimeInstanceRegistry)
if ok then
v563 = result
end
end
local __ClientTreadmillRenders = workspace:FindFirstChild("__ClientTreadmillRenders") or workspace:WaitForChild("__ClientTreadmillRenders", 10)
if not __ClientTreadmillRenders then
return
end
local function v569()
local v570 = PlotState2.GetMySlot()
if v570 == nil then
return nil
end
local v571 = __ClientTreadmillRenders:FindFirstChild("TreadmillRender_" .. tostring(v570))
if v571 then
return v571
end
local Peek = v563 and (v563.Peek or v563.Get)
if not Peek then
return nil
end
local ok, result = pcall(Peek, "TreadmillPlotRender", tostring(v570))
if ok then
return result
end
return nil
end
local function v575(p94)
local v576 = v569()
if v576 and p94 == v576 then
return true
end
local ok, result = pcall(function()
return p94:GetPivot().Position
end)
if not ok then
return true
end
local ok2, result2 = pcall(PlotState2.IsWorldPositionWithinLocalPlotBounds, result)
local v581 = ok2 and result2
return v581
end
local children = __ClientTreadmillRenders:GetChildren()
local n14 = 0
for _, child in ipairs(children) do
if child:IsA("Model") and not v575(child) and pcall(function()
child:Destroy()
end) then
n14 += 1
end
end
__ClientTreadmillRenders.ChildAdded:Connect(function(child)
task.defer(function()
if child.Parent and child:IsA("Model") and not v575(child) then
pcall(function()
child:Destroy()
end)
end
end)
end)
u558 = true
end)
if ok then
return u558
end
warn("[FPSBoost] Gagal delete treadmill pemain lain:", result)
return false
end
v391 = function()
if u456 or senaV4Config._fpsBoostApplying then
return
end
senaV4Config._fpsBoostApplying = true
local ok, result = pcall(function()
v489()
senaV4Config._fpsPlotsReady = v545() == true
senaV4Config._fpsTreadmillsReady = v557() == true
senaV4Config._fpsAreasReady = v520() == true
senaV4Config._fpsWorldReady = v500() == true
senaV4Config._fpsPetsReady = v471() == true
senaV4Config._fpsEggsReady = v462() == true
u456 = senaV4Config._fpsEggsReady and senaV4Config._fpsPetsReady and senaV4Config._fpsWorldReady and senaV4Config._fpsPlotsReady and senaV4Config._fpsTreadmillsReady and senaV4Config._fpsAreasReady
end)
senaV4Config._fpsBoostApplying = nil
if not ok then
warn("[FPSBoost] Gagal menerapkan FPS Boost:", result)
end
end end

---------------------------------------------------------------------
-- CALLBACK TOGGLE (asli): v4717 Startup Boost, v4719 Boost FPS, v4720 Uncap FPS
---------------------------------------------------------------------
local u4716 = false
local function v4717(p1043)
local v4718 = senaV4Config.StartupBoost == true
senaV4Config.StartupBoost = p1043 == true
if not senaV4Config.StartupBoost then
u4716 = false
if v4718 or t15.snapshot then
task.spawn(t15.revert)
end
return
end
if senaV4Config.StartupBoost and not u4716 then
u4716 = true
task.spawn(function()
task.wait(1.5)
if v16() and senaV4Config.StartupBoost then
v390()
end
task.wait(4)
if v16() and senaV4Config.StartupBoost then
v390()
end
end)
end
end
local function v4719(p1044)
if p1044 == true then
task.spawn(v391)
end
end
local function v4720(p1045)
local __SenaV4SetCapFps = genv.__SenaV4SetCapFps
if type(__SenaV4SetCapFps) == "function" then
__SenaV4SetCapFps(p1045 == true and 240 or 60)
end
end

---------------------------------------------------------------------
-- JALANKAN (sama seperti toggle hub saat load)
---------------------------------------------------------------------
v4720(Config.UncapFps)
v4717(Config.StartupBoost)
v4719(Config.BoostFps)

genv.FPSBoost = {
	StartupBoost = v4717,
	BoostFps     = v4719,
	UncapFps     = v4720,
}

---------------------------------------------------------------------
-- UI KECIL: "Leon4951 | performance"
---------------------------------------------------------------------
local UserInputService = game:GetService("UserInputService")

if genv.__FPSBoostGui then
	pcall(function() genv.__FPSBoostGui:Destroy() end)
end

local gui = Instance.new("ScreenGui")
gui.Name = "LeonPerformance"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local okParent = pcall(function()
	gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
end)
if not okParent or not gui.Parent then
	gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end
genv.__FPSBoostGui = gui

local ROW_H, TOP_H, PAD = 26, 28, 6
local WIDTH = 210

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(WIDTH, TOP_H + PAD)
main.Position = UDim2.new(0, 12, 0.5, -60)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(60, 60, 70)
stroke.Thickness = 1

local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, TOP_H)
bar.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
bar.BorderSizePixel = 0
bar.Parent = main

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(10, 0)
title.Size = UDim2.new(1, -40, 1, 0)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(240, 240, 245)
title.Text = "Leon4951 | performance"
title.Parent = bar

local minBtn = Instance.new("TextButton")
minBtn.BackgroundTransparency = 1
minBtn.Position = UDim2.new(1, -28, 0, 0)
minBtn.Size = UDim2.fromOffset(28, TOP_H)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
minBtn.Text = "-"
minBtn.Parent = bar

local list = Instance.new("Frame")
list.BackgroundTransparency = 1
list.Position = UDim2.fromOffset(0, TOP_H + PAD)
list.Size = UDim2.new(1, 0, 0, 0)
list.Parent = main

local rows = 0
local expandedHeight

local function addToggle(text, default, callback)
	rows += 1
	local y = (rows - 1) * ROW_H

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(10, y)
	label.Size = UDim2.new(1, -64, 0, ROW_H)
	label.Font = Enum.Font.Gotham
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Color3.fromRGB(220, 220, 228)
	label.Text = text
	label.Parent = list

	local sw = Instance.new("TextButton")
	sw.AutoButtonColor = false
	sw.Text = ""
	sw.Size = UDim2.fromOffset(38, 18)
	sw.Position = UDim2.new(1, -48, 0, y + (ROW_H - 18) / 2)
	sw.Parent = list
	Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(14, 14)
	knob.BackgroundColor3 = Color3.new(1, 1, 1)
	knob.BorderSizePixel = 0
	knob.Parent = sw
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

	local state = default == true
	local function render()
		sw.BackgroundColor3 = state and Color3.fromRGB(60, 190, 110) or Color3.fromRGB(70, 70, 80)
		knob.Position = state and UDim2.fromOffset(22, 2) or UDim2.fromOffset(2, 2)
	end
	render()

	sw.MouseButton1Click:Connect(function()
		state = not state
		render()
		task.spawn(callback, state)
	end)

	list.Size = UDim2.new(1, 0, 0, rows * ROW_H)
	expandedHeight = TOP_H + PAD + rows * ROW_H + PAD
end

addToggle("Startup Boost", Config.StartupBoost, v4717)
addToggle("Boost FPS",     Config.BoostFps,     v4719)
addToggle("Uncap FPS",     Config.UncapFps,     v4720)

local collapsed = false
local function resize()
	main.Size = UDim2.fromOffset(WIDTH, collapsed and (TOP_H + 2) or expandedHeight)
	minBtn.Text = collapsed and "+" or "-"
end
resize()

minBtn.MouseButton1Click:Connect(function()
	collapsed = not collapsed
	resize()
end)

-- Bisa digeser (mouse & layar sentuh)
do
	local dragging, dragStart, startPos
	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end
