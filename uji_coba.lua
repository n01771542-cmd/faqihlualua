-- ============================================================================
-- LEON4951 HUB v2 - COMPACT & REFINED EDITION (BLUE ELEGAN THEME)
-- ============================================================================

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function DestroyOldUI(name)
    local old = CoreGui:FindFirstChild(name) or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild(name))
    if old then
        pcall(function() old:Destroy() end)
    end
end

DestroyOldUI("leon4951HubGuiV2")

-- [ 1. SERVICES ]
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- [ 2. CONFIGURASI & THEME (AMBIL DARI SCRIPT ACUAN) ]
local Theme = {
    Background = Color3.fromRGB(7, 10, 17),
    SidebarBg = Color3.fromRGB(10, 14, 23),
    CardBg = Color3.fromRGB(14, 20, 32),
    CardBorder = Color3.fromRGB(34, 48, 73),
    
    Accent = Color3.fromRGB(37, 120, 255),
    AccentLight = Color3.fromRGB(82, 151, 255),
    TabActiveBg = Color3.fromRGB(18, 48, 100),
    TabActiveBorder = Color3.fromRGB(37, 120, 255),
    CloseBtnBg = Color3.fromRGB(40, 20, 25),
    
    RunPillBg = Color3.fromRGB(20, 35, 60),
    
    TextPrimary = Color3.fromRGB(245, 247, 255),
    TextSecondary = Color3.fromRGB(180, 195, 225),
    TextMuted = Color3.fromRGB(130, 145, 175),
    BorderColor = Color3.fromRGB(34, 48, 73),
    
    GoldBadge = Color3.fromRGB(255, 185, 0),
    KeyTagBg = Color3.fromRGB(220, 53, 69),
    NoKeyTagBg = Color3.fromRGB(46, 146, 116),
    WaGreen = Color3.fromRGB(37, 211, 102),
    WaDarkGreen = Color3.fromRGB(18, 38, 28)
}

local WA_CHANNEL_LINK = "https://whatsapp.com/channel/0029VbDq74VHgZWbi0AdSa1L"

-- [ 3. DATA KATEGORI & DAFTAR SCRIPT ]
local RawScriptDataStealAnEgg = {
    {"PET SPAWNER TERBAGUS","No Key",true,"https://raw.githubusercontent.com/bugxiefun/roblox-scripts/refs/heads/main/rblxscripts-stealanegg-spawner"},
    {"YANTO HUB KEY : YANTOHUB","Key",true,"https://raw.githubusercontent.com/YantoRoblox/Script-Free-YantoHUB/refs/heads/main/YantoHUB"},
    {"FYY HUB","No Key",true,"https://FyyCommunity.my.id"},
    {"SPEED HUB","Key",false,"https://raw.githubusercontent.com/AhmadV99/Speed-Hub-X/main/Speed%20Hub%20X.lua"},
    {"BIGFROOT HUB","Key",false,"https://raw.githubusercontent.com/hanniii1/Loader/refs/heads/main/BFLoader.lua"},
    {"CHIYO HUB","Key",false,"https://raw.githubusercontent.com/kaisenlmao/loader/refs/heads/main/chiyo.lua"},
    {"CLOVER HUB","Key",true,"https://cloverhub.app/clover.lua"},
    {"ZERO POINT HUB","No Key",false,"https://raw.githubusercontent.com/JaxRol/ZeroPoint/refs/heads/main/KeySystem"},
    {"UB HUB","No Key",false,"https://raw.githubusercontent.com/TeamUBHub/UBLoader/refs/heads/main/Loader.lua"},
    {"VALINC HUB","No Key",false,"https://api.valincsyndicate.com/v1/releases/5502cba03703f4a3628d522d396b80d8.lua"},
    {"OUROBOROS HUB","No Key",false,"https://raw.githubusercontent.com/joustingmatch/Ouroboros/main/loader.lua"},
    {"OMG HUB","Key",false,"https://raw.githubusercontent.com/Omgshit/Scripts/main/MainLoader.lua"},
    {"NASI RENDANG LUA","Key",true,"https://raw.githubusercontent.com/JualNasiRendang/loader/refs/heads/main/main.lua"},
    {"UNKNOWN HUB","Key",false,"https://unknownhub.win/api/projects/54474b4c5d5a4f459909c4cb70e7b4f3/loader"},
    {"RIFT","Key",false,"https://rifton.top/loader.lua"},
    {"AIR FLOW","Key",false,"https://airflowscript.com/loader"},
    {"SOLIX HUB","Key",false,"https://raw.githubusercontent.com/bao8jl/solixhub/main/loader"},
    {"HOSHI HUB","No Key",false,"https://hoshihub.site/loader.lua"},
    {"ZERO IMPACT","Key",false,"https://www.zeroimpact.online/raw/loader"},
    {"SNOWY HUB","Key",false,"https://flowauth.net/v1/ui/a87f00d9adf63658655fcd02ab86a4ef.lua"},
    {"AJJANS HUB","Key",true,"https://raw.githubusercontent.com/virtuososvisualedits-prog/Ww/refs/heads/main/final-obfuscated.lua"},
    {"NEMESIS HUB","Key",false,"https://raw.githubusercontent.com/x2zu/loader/main/freeloader.lua"},
    {"NIGHT HUB","No Key",false,"https://pastefy.app/J29hE5fR/raw"},
    {"LUMIN HUB","No Key",false,"http://luminon.top/loader.lua"},
    {"CIAO HUB SERVER HOP","No Key",false,"https://pastefy.app/YoZocJ8O/raw"},
    {"ZHENN HUB SPAWNER","Key",false,"https://raw.githubusercontent.com/ZhennHub/PetSpawner/refs/heads/main/lua"},
    {"DECODEX","No Key",false,"https://raw.githubusercontent.com/ItzYumi/Decode/refs/heads/main/DE%3ACODE.lua"},
    {"CRZ HUB","No Key",false,"https://flowauth.net/v1/loaders/3c4e87ed34813171b0f8d53a108a7d88.lua"},
    {"KEXXE HUB","Key",false,"https://raw.githubusercontent.com/premiumbuddy/kex/refs/heads/main/kexxxx"},
    {"NOVA HUB","Key",false,"https://raw.githubusercontent.com/NovaHubRBLX/NovaHub/refs/heads/main/novahub.lua"},
    {"VANTAGE","Key",false,"https://raw.githubusercontent.com/MisterNovitski/Vantage/refs/heads/main/mm2.txt"},
    {"SPORTSCLUB HUB","Key",false,"https://loader.sportsclub.fun/loader.luau"},
    {"SCRIPTVERSE HUB","Key",false,"https://scriptversekey.xyz/s/steal-an-egg"},
    {"GS HUB","Key",false,"https://gist.githubusercontent.com/spiritualgaming1123-beep/46ef55c5f8284e076aafc5ebd12233f4/raw/5b24749c3931c1838a76e64c9af508dcdd03700a/gistfile1.lua"},
    {"PROBEST","Key",false,"https://api.jnkie.com/api/v1/luascripts/public/0199b576f5c2d5a34159f0f9f4e1de0a566b4d1da5b1cfa5d2f71ade9bdcaa24/download"},
    {"SYSHUB FUN","Key",false,"https://syshub.fun/free"},
    {"FOXNAME","No Key",true,"https://raw.githubusercontent.com/caomod2077/Script/refs/heads/main/Fn-stealanegg.lua"},
    {"DUPE EGG + DUPE PET","No Key",false,"https://raw.githubusercontent.com/INF-Hub-PL/StealAEggScript/refs/heads/main/Pet_SpawnerV1"},
    {"RONNEI HUB","No Key",true,"https://raw.githubusercontent.com/elonmod/skibidi/refs/heads/main/Ronneihub-keyless.lua"},
    {"AXONIC HUB","Key",false,"https://raw.githubusercontent.com/Kenniel123/Steal-A-Egg/refs/heads/main/Steal%20A%20Egg"},
    {"NEOX HUB","Key",false,"https://raw.githubusercontent.com/hassanxzayn-lua/NEOXHUBMAIN/refs/heads/main/loader"},
    {"LENNON V5","No Key",true,"https://api.luarmor.net/files/v4/loaders/4595fe31a5f7a8b4f4dd7071f3119ef7.lua"},
    {"SAIOPS HUB","Key",false,"https://api.saiops.cc/scripts/Steal-An-Egg-Script.lua"},
    {"ZEROIN HUB","Key",false,"https://zeroinhub.com/api/script"},
    {"ONHUB VIET","Key",false,"https://raw.githubusercontent.com/ronnei/freemium/refs/heads/main/loader.lua"},
    {"MIRANDA HUB V4","No Key",true,"https://raw.githubusercontent.com/miirandahub/loader/refs/heads/main/stealeggies"},
    {"PROJECT-MADARA","No Key",false,"https://raw.githubusercontent.com/IsThisMe01/Project-Madara/refs/heads/main/stealanegg"},
    {"NEVERLOSE","Key",false,"https://raw.githubusercontent.com/inrate1337/NeverloseLoaderRoblox/refs/heads/main/main.luau"},
    {"SPIRITUAL GAMING HUB","Key",false,"https://gist.githubusercontent.com/spiritualgaming1123-beep/f2c8c4009b2c4d4dda1b3d5fcb263ef3/raw/121ff8c9b59476a7a362b543edc61499e5832937/gistfile1.lua"},
    {"CRYSTALIZED HUB","Key",false,"https://api.jnkie.com/api/v1/luascripts/public/a62237c6a75399adc9add4151ebeeb91c1f965fab665a650dcbc699a5622b37f/download"},
    {"OCTOPUS HUB","Key",false,"https://www.octopushub.xyz/loader"},
    {"SYSNEROX","Key",false,"https://raw.githubusercontent.com/DrakarDev/Hud/refs/heads/main/steal_an_egg.lua"},
    {"JINHUB","Key",false,"https://jinhub.my.id/scripts/Universal.lua"},
    {"OVERFLOW","Key",false,"https://overflow.cx/loader.lua"},
    {"BLYXO HUB","No Key",true,"https://flowauth.net/v1/loaders/69d3463240384f3a73fbe32c178093a2.lua"},
    {"SENA V5 beta","No Key",true,"https://senahub.xyz/raw/loader"},
    {"TOOLBOX","No Key",false,"https://raw.githubusercontent.com/Abdullahking20/loader-lua/main/loader"},
    {"SOLVEXGUI HUB","Key",false,"https://raw.githubusercontent.com/Solvexxxx/Scripts/refs/heads/main/SolvexGUI_SAE.lua"},
    {"SPEED BYPASS","No Key",false,"https://pastefy.app/iedWaiQX/raw"},
    {"SAKURA HUB","Key",false,"https://flowauth.net/v1/ui/d00ec69382de97372fc9559efc722298.lua"},
    {"LUNARIS HUB","Key",false,"https://jnkie.com/loaders/lunaris"},
    {"FORGE HUB","Key",false,"https://cdn.forgehub.store/loader"},
    {"BASEMENT HUB","Key",false,"https://thebsmt.xyz/BSMT"},
    {"KALI HUB","Key",false,"https://kalihub.xyz/loader.lua"},
    {"CORE HUB","Key",false,"https://getcore.lol/loader.lua"},
    {"INDRA HUB","Key",false,"https://api.jnkie.com/api/v1/luascripts/public/2b7d97ed2525cef705b26f22d6964b87dd4b64a1bf533ac61d9edf6df14e8471/download"},
    {"PET/EGG SPAWNER","No Key",false,"https://api.luarmor.net/files/v4/loaders/d8f1c691a58edb11ef782849f80e9b61.lua"},
    {"APEL HUB","Key",false,"https://apelhub.com/loader.lua"},
    {"PANDA HUB","Key",false,"https://raw.githubusercontent.com/Muhammad6196/Project-Infinity-X/refs/heads/main/main.lua"},
    {"LUCID HUB","Key",false,"https://gist.githubusercontent.com/IlyassSama/d4c20dcabe62c225b3e96a43cdb0eae9/raw/82020fd08fbff2ad69731e650d960f7d59a07fac/notifier.lua"},
    {"FISHY","Key",false,"https://jnkie.com/loaders/fishyhub"},
    {"SCRIPTFARMER","Key",false,"https://scriptfarmer.dpdns.org/loader/stealanegg-serverhoper"},
    {"VIVID LUA","Key",false,"https://vivid.vividhub.workers.dev/loader.lua"},
    {"BERRI HUB","Key",false,"https://raw.githubusercontent.com/moshixzn/ahhagdienavd/refs/heads/main/loader.lua.txt"},
    {"NOCTRUNHUB","Key",false,"https://raw.githubusercontent.com/insanecontenty2k-blip/scriptss/main/universalscriptsofop"},
    {"CITRA HUB","No Key",false,"https://raw.githubusercontent.com/gilgameshfate59/ohbfoosk8tid/main/CitraLoader.lua"},
    {"VINCI HUB","No Key",true,"https://raw.githubusercontent.com/tutorkah104-rgb/Steal-an-Egg/refs/heads/main/Vincitore.luau"},
    {"HORIZON HUB ANTI HIT","No Key",false,"script_key = \"Trial\"; loadstring(game:HttpGet(\"https://api.getpolsec.com/scripts/hosted/6582551b42d21c6b7eb55f1d76d8d50ce53cb35592093d6615b5e83437594dc0.lua\"))()"},
    {"CHILLI HUB","No Key",true,"https://raw.githubusercontent.com/tienkhanh1/spicy/main/Chilli.lua"},
    {"TSUO HUB","No Key",true,"https://raw.githubusercontent.com/Tsuo7/TsuoHub/main/stealanegg"},
    {"LKZ HUB","No Key",true,"https://raw.githubusercontent.com/LucasggkX/LKZ-Hub/refs/heads/main/Loader.lua"},
    {"REZZY HUB","Key",false,"https://raw.githubusercontent.com/Roman666Cabj/Nether/refs/heads/main/RezzyStealAnEgg.lua"},
    {"RAVANGE HUB","Key",false,"https://raw.githubusercontent.com/Revenge-Hub-Roblox/Scripts/refs/heads/main/Loader.lua"},
    {"ZNEX HUB","Key",false,"https://api.jnkie.com/api/v1/luascripts/public/181cfe2bd5df35ce78607b5ffb37c6666abd76eda11ff33b0f24a1b2d8ee935f/download"},
    {"ASVARA HUB","Key",false,"https://raw.githubusercontent.com/asvraRoblox/stealegg/refs/heads/main/main"},
    {"VSN","No Key",false,"https://raw.githubusercontent.com/NetNullv1/VSN/refs/heads/main/HUB"},
    {"SHADOW HUB","Key",false,"https://pastebin.com/raw/QAvDbBKa"},
    {"VELOX HUB","Key",false,"https://api.jnkie.com/api/v1/luascripts/public/f0b3ce85f588800ae7e46415fc4dd79ff2b0d09c9b6a8e19cea8a67b47f1bcbd/download"},
    {"KING VYPER (KEY: KV-FREE-TRIAL-WOKS)","Key",false,"https://kingvypers.site/raw/TrialLoader"},
    {"HIP-HUP","Key",true,"https://hiphub.cloud/api/script-roblox/loader"},
    {"BK HUB","No Key",true,"https://api.luarmor.net/files/v4/loaders/9ee4edde227ac85f50872bf9e4226508.lua"},
    {"AXURS","No Key",false,"https://raw.githubusercontent.com/XE3Scripts/Axur-sGamesHub/refs/heads/main/StealAnEgg"},
    {"POTATO HUB","Key",false,"https://raw.githubusercontent.com/potatohub67/potatoscripts/refs/heads/main/stealaegg.lua"},
    {"JANE HUB","No Key",false,"https://flowauth.net/v1/loaders/3c4e87ed34813171b0f8d53a108a7d88.lua"},
    {"WIS HUB","No Key",true,"https://api.wishub.cloud/files/loader.lua"},
    {"SENA V6 NEW","Key",true,"https://senahub.xyz/senav6"},
    {"VOIDHUB","No Key",false,"loadstring(game:HttpGet(\"https://voidon.top/api/loader/main\"))()"},
    {"LIMBO HUB","No Key",false,"loadstring(game:HttpGet(\"https://limbohub.my.id/loader.lua\"))()"},
    {"OXIDE HUB","No Key",false,"loadstring(game:HttpGet(\"https://raw.githubusercontent.com/xulfo/Oxide-Loader/main/Main.lua\"))()"},
    {"PULSE HUB","No Key",false,"loadstring(game:HttpGet(\"https://raw.githubusercontent.com/PulseZax/Loader/refs/heads/main/.lua\"))()"},
    {"YARHM HUB","No Key",false,"loadstring(game:HttpGet(\"https://yarhm.com\"))()"},
    {"RIFT GOHA","Key",false,"loadstring(game:HttpGet(\"https://raw.githubusercontent.com/Dodoyung24/script-core/main/Steal-An-Egg\"))()"},
    {"ATHERHUB","Key",false,"loadstring(game:HttpGet(\"https://api.luarmor.net/files/v3/loaders/2529a5f9dfddd5523ca4e22f21cceffa.lua\"))()"},
    {"VANITY HUB","Key",false,"loadstring(game:HttpGet(\"https://vanityscript.xyz/loader\"))()"},
    {"RONIX HUB","Key",false,"loadstring(game:HttpGet(\"https://api.luarmor.net/files/v3/loaders/fda9babd071d6b536a745774b6bc681c.lua\"))()"},
    {"MONARCHH","No Key",false,"loadstring(game:HttpGet(\"https://raw.githubusercontent.com/nobuxy/monarch.win/refs/heads/main/Monarch.lua\"))()"},
    {"UNREXL","Key",false,"loadstring(game:HttpGet(\"https://raw.githubusercontent.com/unrexl/Scripts/refs/heads/main/StealaEgg\"))()"},
    {"WADIDIS HUB","Key",false,"loadstring(game:HttpGet(\"https://api.jnkie.com/api/v1/luascripts/public/809c81e15814d1c016f44d9fe56587f5f38c55a97f203f11bc1a3f7cc3725c5f/download\"))()"},
    {"H4XSCRIPTS","Key",false,"loadstring(game:HttpGet(\"https://raw.githubusercontent.com/H4xScripts/Loader/refs/heads/main/loader.lua\", true))()"},
    {"RBX LIFE / DIVINE EGG","No Key",false,"loadstring(game:HttpGet(\"https://raw.githubusercontent.com/SynergyNetworkz/VULN/refs/heads/main/STEALANEGG.lua\"))()"},
    {"THAN HUB","Key",false,"loadstring(game:HttpGet(\"https://api.luarmor.net/files/v4/loaders/d1c82862a093e64c6bd82bb6d6f7a46b.lua\"))()"},
    {"TOKINU","No Key",false,"loadstring(game:HttpGet(\"https://raw.githubusercontent.com/Tokinu-Scripts/Steal-An-Egg/refs/heads/main/Instant/Tp\"))()"},
    {"NEVA HUB","No Key",false,"loadstring(game:HttpGet(\"https://raw.githubusercontent.com/VEZ2/NEVAHUB/main/2\"))()"},
    {"LEVON HUB","No Key",false,"loadstring(game:HttpGet('https://pastefy.app/nasHhfko/raw'))()"},
}

local RawNewScriptsData = {
    {"OTC","No Key",true,"loadstring(game:HttpGet(\"https://raw.githubusercontent.com/Aerlro/OTC/refs/heads/main/Steal%20an%20Egg/main.lua\"))()"},
    {"AKIPOX","No Key",false,"loadstring(game:HttpGet(\"https://raw.githubusercontent.com/akipox/Roblox/main/Mods/Games/StealanEgg.lua\"))()"},
    {"MENGHUB","Key",false,"loadstring(game:HttpGet(\"https://raw.githubusercontent.com/GrexXMeng/Mengs/refs/heads/main/StealAnEgg.lua\"))()"},
    {"MY HUB","No Key",false,"loadstring(game:HttpGet(\"https://raw.githubusercontent.com/pespapankon-del/MyHub/main/Games/StealAnEgg.lua\"))()"},
    {"TUROK JAPAN HUB","No Key",false,"loadstring(game:HttpGet(\"https://raw.githubusercontent.com/lvjunling/r-s-zh/refs/heads/main/stealegg/lua_zh_mobile.lua\"))()"},
    {"FROST","Key",false,"loadstring(game:HttpGet(\"https://raw.githubusercontent.com/Frost-GG-Hud/Loader/main/src/Loader.luau\"))()"},
    {"SOLARIS","Key",false,"loadstring(game:HttpGet(\"https://api.obscuravm.com/scripts/1231452106622100334\"))()"},
    {"SEISEN V1","Key",false,"loadstring(game:HttpGet(\"https://api.jnkie.com/api/v1/luascripts/public/8ac2e97282ac0718aeeb3bb3856a2821d71dc9e57553690ab508ebdb0d1569da/download\"))()"},
    {"SELUX","Key",false,"loadstring(game:HttpGet(\"https://raw.githubusercontent.com/seltonmt012/sel01-rbx/main/loader.lua\"))()"},
    {"SYSCALL","No Key",false,"loadstring(game:HttpGet(\"https://raw.githubusercontent.com/enzukaix/Syscall/refs/heads/main/Loader.lua\"))()"},
    {"RBXZ HUB","Key",false,"loadstring(game:HttpGet(\"https://rbxscriptz.fun/RBXZ-HUB\"))()"},
    {"SEISEN V2","No Key",false,"loadstring(game:HttpGet(\"https://raw.githubusercontent.com/Mentos4/roblox/refs/heads/main/Script/Steal%20an%20Egg\"))()"},
    {"VOID SHELL HUB","No Key",false,"loadstring(game:HttpGet(\"https://raw.githubusercontent.com/VoidShell-null/VoidShell-Hub/refs/heads/main/Scripts/StealAnEgg.luau\"))()"},
    {"NOYCHOX","No Key",false,"loadstring(game:HttpGet(\"https://raw.githubusercontent.com/yNopaak/STEAL-AN-EGG-NOYCHOX/main/main.lua\"))()"},
    {"PELATICO","No Key",false,"loadstring(game:HttpGet(\"https://raw.githubusercontent.com/PELATICO/steal-an-egg-hub/main/main.lua\"))()"},
    {"XENON BYTE","No Key",false,"loadstring(game:HttpGet(\"https://raw.githubusercontent.com/fivetagz-prog/xenon-byte-steal-an-egg/refs/heads/main/xenon-byte-sac.lua\"))()"},
    {"VORTEX X SAGE","No Key",false,"loadstring(game:HttpGet(\"https://raw.githubusercontent.com/Israel-Vortex/vortex-x-scripts/refs/heads/main/Official-Vortex-Software/Dev-Project/StealAnEgg.lua\"))()"},
    {"PHUCMAX VIET","No Key",false,"loadstring(game:HttpGet(\"https://raw.githubusercontent.com/phucmax/THANHPHUC/refs/heads/main/PHUCMAX(2).lua\"))()"},
    {"DRAGON SECURITY HUB V2.5","No Key",false,"loadstring(game:HttpGet(\"https://raw.githubusercontent.com/conmemaynguhsjs/scrip/refs/heads/main/gemini-code-1789308407861.lua.txt\"))()"},
    {"BUGXIE Visual Spawner","No Key",false,"loadstring(game:HttpGet(\"https://raw.githubusercontent.com/bugxiefun/roblox-scripts/refs/heads/main/rblxscripts-stealanegg-spawner\"))()"},
    {"BUGXIE Hit Aura","No Key",false,"loadstring(game:HttpGet(\"https://raw.githubusercontent.com/bugxiefun/roblox-scripts/refs/heads/main/steal%20an%20egg%20hit%20aura-obfuscated.lua\"))()"},
    {"CLOUT HUB","No Key",false,"loadstring(game:HttpGet(\"https://raw.githubusercontent.com/ClouthubOnTop/Loader/main/main.lua\"))()"},
    {"LUXY","No Key",false,"loadstring(game:HttpGet(\"https://flowauth.net/v1/loaders/16b55b285584ec6d065913f5d59fb105.lua\"))()"},
    {"OJIASA","No Key",false,"loadstring(game:HttpGet(\"https://raw.githubusercontent.com/ojiasa/Steal-an-egg/main/main.lua\"))()"},
    {"DODOYUNG24","No Key",false,"loadstring(game:HttpGet(\"https://raw.githubusercontent.com/Dodoyung24/script-core/main/Steal-An-Egg\"))()"},
    {"MIRACLE HUB","No Key",false,"loadstring(game:HttpGet(\"https://raw.githubusercontent.com/miracleverytime/miraclehub-shared/main/loader.lua\"))()"},
}

local function NormalizeScriptData(raw)
    local result = {}
    for i, entry in ipairs(raw) do
        result[i] = {
            name = entry[1],
            status = entry[2],
            recommended = entry[3],
            url = entry[4],
        }
    end
    return result
end

local ScriptDataStealAnEgg = NormalizeScriptData(RawScriptDataStealAnEgg)
local NewScriptsData = NormalizeScriptData(RawNewScriptsData)
for _, newScript in ipairs(NewScriptsData) do
    table.insert(ScriptDataStealAnEgg, newScript)
end

local CleanedScripts = ScriptDataStealAnEgg

-- [ FAVORITES SYSTEM ]
local FavoriteConfigName = "leon4951hub_favorites.json"
local FavoriteList = {}

local function LoadFavorites()
    if not readfile then return end
    local success, raw = pcall(readfile, FavoriteConfigName)
    if not success or type(raw) ~= "string" or raw == "" then return end
    local decodedOk, decoded = pcall(function()
        return HttpService:JSONDecode(raw)
    end)
    if decodedOk and type(decoded) == "table" then
        FavoriteList = decoded
    end
end

local function SaveFavorites()
    if writefile then
        pcall(function()
            writefile(FavoriteConfigName, HttpService:JSONEncode(FavoriteList))
        end)
    end
end

LoadFavorites()

local FavoriteScriptsData = {}
local function RefreshFavoritesData()
    FavoriteScriptsData = {}
    for _, s in ipairs(CleanedScripts) do
        local id = s.name .. "|" .. s.url
        if FavoriteList[id] then
            table.insert(FavoriteScriptsData, s)
        end
    end
end
RefreshFavoritesData()

local Categories = {
    { key = "StealAnEgg", name = "steal an egg", type = "script_list", scripts = CleanedScripts },
    { key = "Favorite", name = "favorite", type = "script_list", scripts = FavoriteScriptsData },
    { key = "InfoAllScript", name = "info/all script", type = "info", scripts = CleanedScripts },
    { key = "NewScript", name = "new script", type = "new_script", scripts = NewScriptsData, hasNotification = true },
}

local activeCategoryIndex = 1
local activeFilter = "ALL"

-- [ 4. ROOT UI ]
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "leon4951HubGuiV2"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Frame Utama Diperkecil: 520x330 (dari 630x420)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.fromOffset(520, 330)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.fromScale(0.5, 0.5)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = false
MainFrame.Active = true
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Theme.BorderColor
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

local MainScale = Instance.new("UIScale")
MainScale.Scale = 0
MainScale.Parent = MainFrame

-- [ 5. LOGIC LOGO "F" PERSIS SCRIPT ACUAN (SKWED / ROTATED PARTS) ]
local function CreateFLogo(size)
    local LogoHolder = Instance.new("Frame")
    LogoHolder.Size = size
    LogoHolder.BackgroundColor3 = Color3.fromRGB(10, 18, 32)
    LogoHolder.BorderSizePixel = 0
    LogoHolder.ClipsDescendants = true
    Instance.new("UICorner", LogoHolder).CornerRadius = UDim.new(0, 5)

    local LogoStroke = Instance.new("UIStroke")
    LogoStroke.Color = Theme.Accent
    LogoStroke.Thickness = 1
    LogoStroke.Transparency = 0.35
    LogoStroke.Parent = LogoHolder

    local scaleX = size.X.Offset / 18
    local scaleY = size.Y.Offset / 18

    local FVertical = Instance.new("Frame")
    FVertical.Size = UDim2.fromOffset(2.5 * scaleX, 9 * scaleY)
    FVertical.Position = UDim2.fromOffset(5.5 * scaleX, 4.5 * scaleY)
    FVertical.BackgroundColor3 = Theme.Accent
    FVertical.BorderSizePixel = 0
    FVertical.Rotation = -6
    FVertical.Parent = LogoHolder

    local FTop = Instance.new("Frame")
    FTop.Size = UDim2.fromOffset(6.5 * scaleX, 2.5 * scaleY)
    FTop.Position = UDim2.fromOffset(7 * scaleX, 4.5 * scaleY)
    FTop.BackgroundColor3 = Theme.Accent
    FTop.BorderSizePixel = 0
    FTop.Rotation = -6
    FTop.Parent = LogoHolder

    local FMiddle = Instance.new("Frame")
    FMiddle.Size = UDim2.fromOffset(5 * scaleX, 2 * scaleY)
    FMiddle.Position = UDim2.fromOffset(6.5 * scaleX, 8 * scaleY)
    FMiddle.BackgroundColor3 = Theme.AccentLight
    FMiddle.BorderSizePixel = 0
    FMiddle.Rotation = -6
    FMiddle.Parent = LogoHolder

    return LogoHolder
end

-- [ 6. HEADER ]
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 44)
Header.BackgroundTransparency = 1
Header.Active = true
Header.Parent = MainFrame

local LogoF = CreateFLogo(UDim2.fromOffset(20, 20))
LogoF.Position = UDim2.new(0, 12, 0, 12)
LogoF.Parent = Header

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextColor3 = Theme.TextPrimary
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(0, 150, 0, 20)
Title.Position = UDim2.new(0, 38, 0, 12)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.RichText = true
Title.Text = 'leon4951 <font color="rgb(37,120,255)">Hub</font>'
Title.Parent = Header

local WaBtn = Instance.new("TextButton")
WaBtn.Name = "WaChannelBtn"
WaBtn.Size = UDim2.fromOffset(130, 22)
WaBtn.Position = UDim2.new(0, 175, 0, 11)
WaBtn.BackgroundColor3 = Theme.WaGreen
WaBtn.Text = "💬 SALURAN WA"
WaBtn.Font = Enum.Font.GothamBold
WaBtn.TextSize = 9
WaBtn.TextColor3 = Theme.TextPrimary
WaBtn.AutoButtonColor = false
WaBtn.Parent = Header

Instance.new("UICorner", WaBtn).CornerRadius = UDim.new(0, 6)

WaBtn.MouseButton1Click:Connect(function()
    if setclipboard then setclipboard(WA_CHANNEL_LINK)
    elseif toclipboard then toclipboard(WA_CHANNEL_LINK) end

    local origText = WaBtn.Text
    WaBtn.Text = "✓ COPIED!"
    task.delay(1.5, function()
        if WaBtn and WaBtn.Parent then WaBtn.Text = origText end
    end)
end)

local ControlContainer = Instance.new("Frame")
ControlContainer.Size = UDim2.fromOffset(70, 28)
ControlContainer.Position = UDim2.new(1, -76, 0, 8)
ControlContainer.BackgroundTransparency = 1
ControlContainer.Parent = Header

local ControlLayout = Instance.new("UIListLayout")
ControlLayout.FillDirection = Enum.FillDirection.Horizontal
ControlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
ControlLayout.VerticalAlignment = Enum.VerticalAlignment.Center
ControlLayout.Padding = UDim.new(0, 6)
ControlLayout.Parent = ControlContainer

local function CreateHeaderButton(iconText, callback, isClose)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(26, 26)
    btn.BackgroundColor3 = isClose and Theme.CloseBtnBg or Theme.CardBg
    btn.Text = iconText
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.TextColor3 = Theme.TextPrimary
    btn.AutoButtonColor = false
    btn.Parent = ControlContainer
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local stroke = Instance.new("UIStroke")
    stroke.Color = isClose and Theme.KeyTagBg or Theme.CardBorder
    stroke.Thickness = 1
    stroke.Parent = btn

    btn.MouseButton1Click:Connect(callback)
    return btn
end

local HeaderLine = Instance.new("Frame")
HeaderLine.Size = UDim2.new(1, -24, 0, 1)
HeaderLine.Position = UDim2.new(0, 12, 0, 44)
HeaderLine.BackgroundColor3 = Theme.CardBorder
HeaderLine.BorderSizePixel = 0
HeaderLine.Parent = MainFrame

-- [ 7. BODY: SIDEBAR + KONTEN ]
local Body = Instance.new("Frame")
Body.Name = "Body"
Body.Size = UDim2.new(1, -24, 1, -54)
Body.Position = UDim2.new(0, 12, 0, 48)
Body.BackgroundTransparency = 1
Body.Parent = MainFrame

local Sidebar = Instance.new("ScrollingFrame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 120, 1, 0)
Sidebar.BackgroundTransparency = 1
Sidebar.BorderSizePixel = 0
Sidebar.ScrollBarThickness = 0
Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
Sidebar.Parent = Body

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.Padding = UDim.new(0, 6)
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Parent = Sidebar

local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -128, 1, 0)
Content.Position = UDim2.new(0, 128, 0, 0)
Content.BackgroundTransparency = 1
Content.Parent = Body

local ContentHeader = Instance.new("Frame")
ContentHeader.Size = UDim2.new(1, 0, 0, 46)
ContentHeader.BackgroundTransparency = 1
ContentHeader.Parent = Content

local ContentTitle = Instance.new("TextLabel")
ContentTitle.Font = Enum.Font.GothamBold
ContentTitle.TextSize = 13
ContentTitle.TextColor3 = Theme.TextPrimary
ContentTitle.BackgroundTransparency = 1
ContentTitle.Size = UDim2.new(1, 0, 0, 16)
ContentTitle.Position = UDim2.new(0, 0, 0, 0)
ContentTitle.TextXAlignment = Enum.TextXAlignment.Left
ContentTitle.Text = "SCRIPTS"
ContentTitle.Parent = ContentHeader

local ContentSub = Instance.new("TextLabel")
ContentSub.Font = Enum.Font.Gotham
ContentSub.TextSize = 9
ContentSub.TextColor3 = Theme.TextMuted
ContentSub.BackgroundTransparency = 1
ContentSub.Size = UDim2.new(1, 0, 0, 12)
ContentSub.Position = UDim2.new(0, 0, 0, 16)
ContentSub.TextXAlignment = Enum.TextXAlignment.Left
ContentSub.Text = "Click run to execute a script!"
ContentSub.Parent = ContentHeader

local FilterContainer = Instance.new("Frame")
FilterContainer.Size = UDim2.new(1, 0, 0, 18)
FilterContainer.Position = UDim2.new(0, 0, 0, 28)
FilterContainer.BackgroundTransparency = 1
FilterContainer.Parent = ContentHeader

local FilterLayout = Instance.new("UIListLayout")
FilterLayout.FillDirection = Enum.FillDirection.Horizontal
FilterLayout.Padding = UDim.new(0, 4)
FilterLayout.SortOrder = Enum.SortOrder.LayoutOrder
FilterLayout.Parent = FilterContainer

local filterButtons = {}

local SearchBox = Instance.new("TextBox")
SearchBox.Name = "SearchBox"
SearchBox.Size = UDim2.new(1, 0, 0, 18)
SearchBox.Position = UDim2.new(0, 0, 0, 28)
SearchBox.BackgroundColor3 = Theme.CardBg
SearchBox.PlaceholderText = "🔍 Cari nama script..."
SearchBox.PlaceholderColor3 = Theme.TextMuted
SearchBox.Text = ""
SearchBox.TextColor3 = Theme.TextPrimary
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 9
SearchBox.Visible = false
SearchBox.Parent = ContentHeader
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 4)

local ScriptScroll = Instance.new("ScrollingFrame")
ScriptScroll.Size = UDim2.new(1, 0, 1, -50)
ScriptScroll.Position = UDim2.new(0, 0, 0, 50)
ScriptScroll.BackgroundTransparency = 1
ScriptScroll.BorderSizePixel = 0
ScriptScroll.ScrollBarThickness = 2
ScriptScroll.ScrollBarImageColor3 = Theme.Accent
ScriptScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ScriptScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScriptScroll.Parent = Content

-- [ 8. RENDER KONTEN (CARD COMPACT GRID) ]
local function RenderContent(categoryIndex)
    local category = Categories[categoryIndex]

    for _, child in ipairs(ScriptScroll:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIGridLayout") then
            child:Destroy()
        end
    end

    local oldLayout = ScriptScroll:FindFirstChildOfClass("UIListLayout") or ScriptScroll:FindFirstChildOfClass("UIGridLayout")
    if oldLayout then oldLayout:Destroy() end

    ContentTitle.Text = string.upper(category.name)

    if category.type == "info" then
        FilterContainer.Visible = false
        SearchBox.Visible = false
        ContentSub.Text = "Database Overview & Statistics"

        local ListLayout = Instance.new("UIListLayout")
        ListLayout.Padding = UDim.new(0, 8)
        ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ListLayout.Parent = ScriptScroll

        local totalCount = #category.scripts
        local keyCount = 0
        local noKeyCount = 0

        for _, s in ipairs(category.scripts) do
            if s.status == "Key" then keyCount = keyCount + 1
            elseif s.status == "No Key" then noKeyCount = noKeyCount + 1 end
        end

        local StatsBanner = Instance.new("Frame")
        StatsBanner.Name = "StatsBanner"
        StatsBanner.Size = UDim2.new(1, 0, 0, 28)
        StatsBanner.BackgroundColor3 = Theme.CardBg
        StatsBanner.LayoutOrder = 1
        StatsBanner.Parent = ScriptScroll
        Instance.new("UICorner", StatsBanner).CornerRadius = UDim.new(0, 6)

        local StatsText = Instance.new("TextLabel")
        StatsText.Font = Enum.Font.GothamBold
        StatsText.TextSize = 9
        StatsText.TextColor3 = Theme.TextSecondary
        StatsText.BackgroundTransparency = 1
        StatsText.Size = UDim2.new(1, -16, 1, 0)
        StatsText.Position = UDim2.new(0, 8, 0, 0)
        StatsText.TextXAlignment = Enum.TextXAlignment.Left
        StatsText.RichText = true
        StatsText.Text = "📊 <font color=\"rgb(255, 255, 255)\">TOTAL:</font> " .. totalCount .. " | <font color=\"rgb(220, 53, 69)\">🔑 KEY:</font> " .. keyCount .. " | <font color=\"rgb(46, 146, 116)\">🔓 NO KEY:</font> " .. noKeyCount
        StatsText.Parent = StatsBanner

        local GridContainer = Instance.new("Frame")
        GridContainer.Size = UDim2.new(1, 0, 0, 0)
        GridContainer.AutomaticSize = Enum.AutomaticSize.Y
        GridContainer.BackgroundTransparency = 1
        GridContainer.LayoutOrder = 2
        GridContainer.Parent = ScriptScroll

        local GridLayout = Instance.new("UIGridLayout")
        GridLayout.CellSize = UDim2.new(0.48, 0, 0, 30)
        GridLayout.CellPadding = UDim2.new(0.03, 0, 0, 6)
        GridLayout.Parent = GridContainer

        for idx, scriptEntry in ipairs(category.scripts) do
            local card = Instance.new("Frame")
            card.BackgroundColor3 = Theme.CardBg
            card.Parent = GridContainer
            Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

            local indicator = Instance.new("Frame")
            indicator.Size = UDim2.new(0, 3, 0, 14)
            indicator.Position = UDim2.new(0, 6, 0.5, -7)
            indicator.BackgroundColor3 = (scriptEntry.status == "Key") and Theme.KeyTagBg or Theme.NoKeyTagBg
            indicator.BorderSizePixel = 0
            indicator.Parent = card
            Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Font = Enum.Font.GothamBold
            nameLbl.TextSize = 9
            nameLbl.TextColor3 = Theme.TextPrimary
            nameLbl.BackgroundTransparency = 1
            nameLbl.Size = UDim2.new(1, -16, 1, 0)
            nameLbl.Position = UDim2.new(0, 12, 0, 0)
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            nameLbl.Text = scriptEntry.name
            nameLbl.Parent = card
        end

        ScriptScroll.CanvasPosition = Vector2.new(0, 0)
        return
    end

    FilterContainer.Visible = true
    ContentSub.Text = "Click run to execute a script!"

    local GridLayout = Instance.new("UIGridLayout")
    GridLayout.CellSize = UDim2.new(0.485, 0, 0, 52)
    GridLayout.CellPadding = UDim2.new(0.03, 0, 0, 6)
    GridLayout.Parent = ScriptScroll

    local searchText = string.lower(SearchBox.Text)
    local filteredScripts = {}

    for _, scriptEntry in ipairs(category.scripts) do
        local matchesFilter = (activeFilter == "ALL") or 
                              (activeFilter == "Key" and scriptEntry.status == "Key") or 
                              (activeFilter == "No Key" and scriptEntry.status == "No Key") or 
                              (activeFilter == "Recommended" and scriptEntry.recommended == true)

        local matchesSearch = (searchText == "") or (string.find(string.lower(scriptEntry.name), searchText, 1, true) ~= nil)

        if matchesFilter and matchesSearch then
            table.insert(filteredScripts, scriptEntry)
        end
    end

    for i, scriptEntry in ipairs(filteredScripts) do
        local card = Instance.new("Frame")
        card.BackgroundColor3 = Theme.CardBg
        card.Parent = ScriptScroll
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

        local cardStroke = Instance.new("UIStroke")
        cardStroke.Color = Theme.CardBorder
        cardStroke.Thickness = 1
        cardStroke.Parent = card

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 10
        nameLabel.TextColor3 = Theme.TextPrimary
        nameLabel.BackgroundTransparency = 1
        nameLabel.Size = UDim2.new(1, -32, 0, 16)
        nameLabel.Position = UDim2.new(0, 8, 0, 8)
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Text = scriptEntry.name
        nameLabel.Parent = card

        local statusText = Instance.new("TextLabel")
        statusText.Font = Enum.Font.GothamBold
        statusText.TextSize = 8
        statusText.TextColor3 = (scriptEntry.status == "Key") and Theme.KeyTagBg or Theme.NoKeyTagBg
        statusText.BackgroundTransparency = 1
        statusText.Size = UDim2.new(1, -32, 0, 12)
        statusText.Position = UDim2.new(0, 8, 0, 26)
        statusText.TextXAlignment = Enum.TextXAlignment.Left
        statusText.Text = string.upper(scriptEntry.status)
        statusText.Parent = card

        local runBtn = Instance.new("TextButton")
        runBtn.Size = UDim2.fromOffset(36, 18)
        runBtn.Position = UDim2.new(1, -42, 0.5, -9)
        runBtn.BackgroundColor3 = Theme.RunPillBg
        runBtn.Text = "run"
        runBtn.Font = Enum.Font.GothamBold
        runBtn.TextSize = 9
        runBtn.TextColor3 = Theme.AccentLight
        runBtn.AutoButtonColor = false
        runBtn.Parent = card
        Instance.new("UICorner", runBtn).CornerRadius = UDim.new(1, 0)

        runBtn.MouseButton1Click:Connect(function()
            if scriptEntry.url and scriptEntry.url ~= "" then
                pcall(function()
                    if string.sub(scriptEntry.url, 1, 10) == "loadstring" or string.find(scriptEntry.url, "script_key") then
                        loadstring(scriptEntry.url)()
                    else
                        loadstring(game:HttpGet(scriptEntry.url))()
                    end
                end)
            end
        end)

        local favBtn = Instance.new("TextButton")
        favBtn.Size = UDim2.fromOffset(16, 16)
        favBtn.Position = UDim2.new(1, -20, 0, 4)
        favBtn.BackgroundTransparency = 1
        local fKeyId = scriptEntry.name .. "|" .. scriptEntry.url
        favBtn.Text = FavoriteList[fKeyId] and "★" or "☆"
        favBtn.Font = Enum.Font.GothamBold
        favBtn.TextSize = 11
        favBtn.TextColor3 = FavoriteList[fKeyId] and Theme.GoldBadge or Theme.TextMuted
        favBtn.Parent = card

        favBtn.MouseButton1Click:Connect(function()
            if FavoriteList[fKeyId] then
                FavoriteList[fKeyId] = nil
                favBtn.Text = "☆"
                favBtn.TextColor3 = Theme.TextMuted
            else
                FavoriteList[fKeyId] = true
                favBtn.Text = "★"
                favBtn.TextColor3 = Theme.GoldBadge
            end
            SaveFavorites()
            RefreshFavoritesData()
            Categories[2].scripts = FavoriteScriptsData
        end)
    end

    ScriptScroll.CanvasPosition = Vector2.new(0, 0)
end

-- [ 9. CREATING FILTER TABS ]
local filterDefs = {
    { id = "ALL", text = "ALL" },
    { id = "Key", text = "🔑 KEY" },
    { id = "No Key", text = "🔓 NO KEY" },
    { id = "Recommended", text = "🌟 REC" }
}

for _, fDef in ipairs(filterDefs) do
    local fBtn = Instance.new("TextButton")
    fBtn.Size = UDim2.fromOffset(52, 16)
    fBtn.BackgroundColor3 = (activeFilter == fDef.id) and Theme.TabActiveBg or Theme.CardBg
    fBtn.Text = fDef.text
    fBtn.Font = Enum.Font.GothamBold
    fBtn.TextSize = 7
    fBtn.TextColor3 = (activeFilter == fDef.id) and Theme.TextPrimary or Theme.TextMuted
    fBtn.Parent = FilterContainer
    Instance.new("UICorner", fBtn).CornerRadius = UDim.new(0, 4)

    filterButtons[fDef.id] = fBtn

    fBtn.MouseButton1Click:Connect(function()
        activeFilter = fDef.id
        for id, btn in pairs(filterButtons) do
            btn.BackgroundColor3 = (id == activeFilter) and Theme.TabActiveBg or Theme.CardBg
            btn.TextColor3 = (id == activeFilter) and Theme.TextPrimary or Theme.TextMuted
        end
        RenderContent(activeCategoryIndex)
    end)
end

-- [ 10. RENDER SIDEBAR TABS ]
local sidebarTabButtons = {}

local function SetActiveCategory(index)
    activeCategoryIndex = index
    RefreshFavoritesData()
    Categories[2].scripts = FavoriteScriptsData

    for i, btnData in ipairs(sidebarTabButtons) do
        local isActive = (i == index)
        btnData.frame.BackgroundColor3 = isActive and Theme.TabActiveBg or Theme.Background
        btnData.frame.BackgroundTransparency = isActive and 0 or 1
        btnData.label.TextColor3 = isActive and Theme.TextPrimary or Theme.TextMuted
        btnData.indicator.Visible = isActive
    end

    RenderContent(index)
end

local function RenderSidebarTabs()
    for _, child in ipairs(Sidebar:GetChildren()) do
        if not child:IsA("UIListLayout") then child:Destroy() end
    end
    sidebarTabButtons = {}

    for i, category in ipairs(Categories) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, 0, 0, 32)
        tabBtn.BackgroundColor3 = (i == activeCategoryIndex) and Theme.TabActiveBg or Theme.Background
        tabBtn.BackgroundTransparency = (i == activeCategoryIndex) and 0 or 1
        tabBtn.Text = ""
        tabBtn.Parent = Sidebar
        Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 8)

        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(0, 3, 0, 18)
        indicator.Position = UDim2.new(0, 4, 0.5, -9)
        indicator.BackgroundColor3 = Theme.Accent
        indicator.BorderSizePixel = 0
        indicator.Visible = (i == activeCategoryIndex)
        indicator.Parent = tabBtn
        Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)

        local label = Instance.new("TextLabel")
        label.Font = Enum.Font.GothamBold
        label.TextSize = 9
        label.TextColor3 = (i == activeCategoryIndex) and Theme.TextPrimary or Theme.TextMuted
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, -16, 1, 0)
        label.Position = UDim2.new(0, 12, 0, 0)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextWrapped = true
        label.Text = string.upper(category.name)
        label.Parent = tabBtn

        table.insert(sidebarTabButtons, { frame = tabBtn, label = label, indicator = indicator })

        tabBtn.MouseButton1Click:Connect(function()
            SetActiveCategory(i)
        end)
    end
end

RenderSidebarTabs()
RenderContent(activeCategoryIndex)

-- [ 11. DRAG SYSTEM ]
local isDragging, dragStartPos, startFramePos, currentDragInput
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStartPos = input.Position
        startFramePos = MainFrame.Position
        currentDragInput = input
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input == currentDragInput then isDragging = false end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input == currentDragInput or input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStartPos
        MainFrame.Position = UDim2.new(startFramePos.X.Scale, startFramePos.X.Offset + delta.X, startFramePos.Y.Scale, startFramePos.Y.Offset + delta.Y)
    end
end)

-- [ 12. FLOATING TOGGLE BUTTON (LOGIC LOGO "F" PERSIS SCRIPT ACUAN) ]
local FloatingBtn = Instance.new("TextButton")
FloatingBtn.Size = UDim2.fromOffset(36, 36)
FloatingBtn.Position = UDim2.new(0, 15, 0.4, 0)
FloatingBtn.BackgroundColor3 = Theme.Background
FloatingBtn.BorderSizePixel = 0
FloatingBtn.Visible = false
FloatingBtn.Text = ""
FloatingBtn.Parent = ScreenGui

Instance.new("UICorner", FloatingBtn).CornerRadius = UDim.new(0, 10)

local FloatingStroke = Instance.new("UIStroke")
FloatingStroke.Color = Theme.Accent
FloatingStroke.Thickness = 1.5
FloatingStroke.Parent = FloatingBtn

local FloatingLogo = CreateFLogo(UDim2.fromOffset(20, 20))
FloatingLogo.Position = UDim2.new(0.5, -10, 0.5, -10)
FloatingLogo.Parent = FloatingBtn

local FloatingScale = Instance.new("UIScale")
FloatingScale.Scale = 1
FloatingScale.Parent = FloatingBtn

-- [ 13. TOGGLE MAIN UI ]
local function ToggleMainUI(show)
    if show then
        MainFrame.Visible = true
        TweenService:Create(FloatingScale, TweenInfo.new(0.1), { Scale = 0 }):Play()
        TweenService:Create(MainScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
        task.delay(0.1, function() FloatingBtn.Visible = false end)
    else
        TweenService:Create(MainScale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0 }):Play()
        task.delay(0.15, function()
            MainFrame.Visible = false
            FloatingBtn.Visible = true
            TweenService:Create(FloatingScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
        end)
    end
end

FloatingBtn.MouseButton1Click:Connect(function() ToggleMainUI(true) end)

CreateHeaderButton("-", function()
    MainFrame.Visible = not MainFrame.Visible
end, false)

CreateHeaderButton("✕", function() ToggleMainUI(false) end, true)

-- [ 14. BOOT LOADING SCREEN ]
local BootScreen = Instance.new("CanvasGroup")
BootScreen.Size = UDim2.fromOffset(220, 110)
BootScreen.AnchorPoint = Vector2.new(0.5, 0.5)
BootScreen.Position = UDim2.fromScale(0.5, 0.5)
BootScreen.BackgroundColor3 = Theme.Background
BootScreen.Parent = ScreenGui

Instance.new("UICorner", BootScreen).CornerRadius = UDim.new(0, 12)

local BootStroke = Instance.new("UIStroke")
BootStroke.Color = Theme.Accent
BootStroke.Thickness = 1.5
BootStroke.Parent = BootScreen

local BootLogo = CreateFLogo(UDim2.fromOffset(22, 22))
BootLogo.Position = UDim2.new(0.5, -11, 0, 12)
BootLogo.Parent = BootScreen

local BootTitle = Instance.new("TextLabel")
BootTitle.Font = Enum.Font.GothamBold
BootTitle.TextSize = 12
BootTitle.TextColor3 = Theme.TextPrimary
BootTitle.BackgroundTransparency = 1
BootTitle.Size = UDim2.new(1, 0, 0, 16)
BootTitle.Position = UDim2.new(0, 0, 0, 38)
BootTitle.RichText = true
BootTitle.Text = 'leon4951 <font color="rgb(37,120,255)">Hub</font>'
BootTitle.Parent = BootScreen

local BootSubText = Instance.new("TextLabel")
BootSubText.Font = Enum.Font.Gotham
BootSubText.TextSize = 8
BootSubText.TextColor3 = Theme.TextMuted
BootSubText.BackgroundTransparency = 1
BootSubText.Size = UDim2.new(1, 0, 0, 12)
BootSubText.Position = UDim2.new(0, 0, 0, 56)
BootSubText.Text = "Loading..."
BootSubText.Parent = BootScreen

local BootTrack = Instance.new("Frame")
BootTrack.Size = UDim2.new(1, -30, 0, 4)
BootTrack.Position = UDim2.new(0, 15, 1, -20)
BootTrack.BackgroundColor3 = Theme.CardBg
BootTrack.Parent = BootScreen
Instance.new("UICorner", BootTrack).CornerRadius = UDim.new(1, 0)

local BootFill = Instance.new("Frame")
BootFill.Size = UDim2.new(0, 0, 1, 0)
BootFill.BackgroundColor3 = Theme.Accent
BootFill.Parent = BootTrack
Instance.new("UICorner", BootFill).CornerRadius = UDim.new(1, 0)

local bootDuration = 1.2
local bootStartTime = os.clock()
local bootConn

bootConn = RunService.Heartbeat:Connect(function()
    local elapsed = os.clock() - bootStartTime
    local pct = math.clamp(elapsed / bootDuration, 0, 1)

    BootFill.Size = UDim2.new(pct, 0, 1, 0)

    if pct >= 1 then
        bootConn:Disconnect()
        BootSubText.Text = "✓ Ready"

        task.spawn(function()
            task.wait(0.2)
            TweenService:Create(BootScreen, TweenInfo.new(0.2), { GroupTransparency = 1 }):Play()
            task.delay(0.2, function()
                BootScreen:Destroy()
                MainFrame.Visible = true
                TweenService:Create(MainScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
            end)
        end)
    end
end)
