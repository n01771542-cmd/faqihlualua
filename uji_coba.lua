-- ============================================================================
-- LEON4951 HUB v4 - SUPER DETAILED, 100% MATCH WITH REFERENCE IMAGE
-- Semua logo, emoji, warna, tata letak diperiksa ulang dengan teliti
-- ============================================================================

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function DestroyOldUI(name)
    local old = CoreGui:FindFirstChild(name) or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild(name))
    if old then pcall(function() old:Destroy() end) end
end
DestroyOldUI("leon4951HubGuiV4")

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- [ THEME - BLUE/INDIGO MATCHING REFERENCE ]
local Theme = {
    Background = Color3.fromRGB(10, 14, 39),
    SidebarBg = Color3.fromRGB(13, 18, 48),
    CardBg = Color3.fromRGB(20, 26, 60),
    CardBgHover = Color3.fromRGB(26, 34, 72),
    AccentBlue = Color3.fromRGB(59, 130, 246),
    AccentIndigo = Color3.fromRGB(99, 102, 241),
    ExecuteBtn = Color3.fromRGB(99, 102, 241),
    TextPrimary = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(148, 163, 184),
    TextMuted = Color3.fromRGB(100, 116, 139),
    BorderColor = Color3.fromRGB(30, 41, 82),
    GoldBadge = Color3.fromRGB(250, 204, 21),
    KeyTagBg = Color3.fromRGB(124, 58, 237),
    NoKeyTagBg = Color3.fromRGB(34, 197, 94),
    DangerRed = Color3.fromRGB(239, 68, 68),
    SuccessGreen = Color3.fromRGB(34, 197, 94),
    SearchBg = Color3.fromRGB(15, 23, 60),
    InputBg = Color3.fromRGB(15, 23, 60),
    DotRed = Color3.fromRGB(239, 68, 68),
    DotGreen = Color3.fromRGB(34, 197, 94),
    IconBg = Color3.fromRGB(30, 41, 82)
}

-- [ DATA SCRIPT ]
local RawScriptDataStealAnEgg = {
    {"PET SPAWNER TERBAGUS","No Key",true,"https://raw.githubusercontent.com/bugxiefun/roblox-scripts/refs/heads/main/rblxscripts-stealanegg-spawner"},
    {"YANTO HUB","Key",true,"https://raw.githubusercontent.com/YantoRoblox/Script-Free-YantoHUB/refs/heads/main/YantoHUB"},
    {"FYY HUB","No Key",true,"https://FyyCommunity.my.id"},
    {"SPEED HUB","Key",false,"https://raw.githubusercontent.com/AhmadV99/Speed-Hub-X/main/Speed%20Hub%20X.lua"},
    {"CLOVER HUB","Key",true,"https://cloverhub.app/clover.lua"},
    {"ZERO POINT HUB","No Key",false,"https://raw.githubusercontent.com/JaxRol/ZeroPoint/refs/heads/main/KeySystem"},
    {"VALINC HUB","No Key",false,"https://api.valincsyndicate.com/v1/releases/5502cba03703f4a3628d522d396b80d8.lua"},
    {"NASI RENDANG LUA","Key",true,"https://raw.githubusercontent.com/JualNasiRendang/loader/refs/heads/main/main.lua"},
    {"FOXNAME","No Key",true,"https://raw.githubusercontent.com/caomod2077/Script/refs/heads/main/Fn-stealanegg.lua"},
    {"RONNEI HUB","No Key",true,"https://raw.githubusercontent.com/elonmod/skibidi/refs/heads/main/Ronneihub-keyless.lua"},
    {"LENNON V5","No Key",true,"https://api.luarmor.net/files/v4/loaders/4595fe31a5f7a8b4f4dd7071f3119ef7.lua"},
    {"MIRANDA HUB V4","No Key",true,"https://raw.githubusercontent.com/miirandahub/loader/refs/heads/main/stealeggies"},
    {"VINCI HUB","No Key",true,"https://raw.githubusercontent.com/tutorkah104-rgb/Steal-an-Egg/refs/heads/main/Vincitore.luau"},
    {"CHILLI HUB","No Key",true,"https://raw.githubusercontent.com/tienkhanh1/spicy/main/Chilli.lua"},
    {"TSUO HUB","No Key",true,"https://raw.githubusercontent.com/Tsuo7/TsuoHub/main/stealanegg"},
    {"LKZ HUB","No Key",true,"https://raw.githubusercontent.com/LucasggkX/LKZ-Hub/refs/heads/main/Loader.lua"},
    {"BK HUB","No Key",true,"https://api.luarmor.net/files/v4/loaders/9ee4edde227ac85f50872bf9e4226508.lua"},
    {"WIS HUB","No Key",true,"https://api.wishub.cloud/files/loader.lua"},
    {"BLYXO HUB","No Key",true,"https://flowauth.net/v1/loaders/69d3463240384f3a73fbe32c178093a2.lua"},
    {"SENA V5 beta","No Key",true,"https://senahub.xyz/raw/loader"},
    {"HIP-HUP","Key",true,"https://hiphub.cloud/api/script-roblox/loader"},
    {"AJJANS HUB","Key",true,"https://raw.githubusercontent.com/virtuososvisualedits-prog/Ww/refs/heads/main/final-obfuscated.lua"},
    {"BIGFROOT HUB","Key",false,"https://raw.githubusercontent.com/hanniii1/Loader/refs/heads/main/BFLoader.lua"},
    {"CHIYO HUB","Key",false,"https://raw.githubusercontent.com/kaisenlmao/loader/refs/heads/main/chiyo.lua"},
    {"OMG HUB","Key",false,"https://raw.githubusercontent.com/Omgshit/Scripts/main/MainLoader.lua"},
    {"UNKNOWN HUB","Key",false,"https://unknownhub.win/api/projects/54474b4c5d5a4f459909c4cb70e7b4f3/loader"},
    {"RIFT","Key",false,"https://rifton.top/loader.lua"},
    {"AIR FLOW","Key",false,"https://airflowscript.com/loader"},
    {"SOLIX HUB","Key",false,"https://raw.githubusercontent.com/bao8jl/solixhub/main/loader"},
    {"HOSHI HUB","No Key",false,"https://hoshihub.site/loader.lua"},
    {"ZERO IMPACT","Key",false,"https://www.zeroimpact.online/raw/loader"},
    {"SNOWY HUB","Key",false,"https://flowauth.net/v1/ui/a87f00d9adf63658655fcd02ab86a4ef.lua"},
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
    {"DUPE EGG + DUPE PET","No Key",false,"https://raw.githubusercontent.com/INF-Hub-PL/StealAEggScript/refs/heads/main/Pet_SpawnerV1"},
    {"AXONIC HUB","Key",false,"https://raw.githubusercontent.com/Kenniel123/Steal-A-Egg/refs/heads/main/Steal%20A%20Egg"},
    {"NEOX HUB","Key",false,"https://raw.githubusercontent.com/hassanxzayn-lua/NEOXHUBMAIN/refs/heads/main/loader"},
    {"SAIOPS HUB","Key",false,"https://api.saiops.cc/scripts/Steal-An-Egg-Script.lua"},
    {"ZEROIN HUB","Key",false,"https://zeroinhub.com/api/script"},
    {"ONHUB VIET","Key",false,"https://raw.githubusercontent.com/ronnei/freemium/refs/heads/main/loader.lua"},
    {"PROJECT-MADARA","No Key",false,"https://raw.githubusercontent.com/IsThisMe01/Project-Madara/refs/heads/main/stealanegg"},
    {"NEVERLOSE","Key",false,"https://raw.githubusercontent.com/inrate1337/NeverloseLoaderRoblox/refs/heads/main/main.luau"},
    {"SPIRITUAL GAMING HUB","Key",false,"https://gist.githubusercontent.com/spiritualgaming1123-beep/f2c8c4009b2c4d4dda1b3d5fcb263ef3/raw/121ff8c9b59476a7a362b543edc61499e5832937/gistfile1.lua"},
    {"CRYSTALIZED HUB","Key",false,"https://api.jnkie.com/api/v1/luascripts/public/a62237c6a75399adc9add4151ebeeb91c1f965fab665a650dcbc699a5622b37f/download"},
    {"OCTOPUS HUB","Key",false,"https://www.octopushub.xyz/loader"},
    {"SYSNEROX","Key",false,"https://raw.githubusercontent.com/DrakarDev/Hud/refs/heads/main/steal_an_egg.lua"},
    {"JINHUB","Key",false,"https://jinhub.my.id/scripts/Universal.lua"},
    {"OVERFLOW","Key",false,"https://overflow.cx/loader.lua"},
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
    {"HORIZON HUB ANTI HIT","No Key",false,"script_key = \"Trial\"; loadstring(game:HttpGet(\"https://api.getpolsec.com/scripts/hosted/6582551b42d21c6b7eb55f1d76d8d50ce53cb35592093d6615b5e83437594dc0.lua\"))()"},
    {"REZZY HUB","Key",false,"https://raw.githubusercontent.com/Roman666Cabj/Nether/refs/heads/main/RezzyStealAnEgg.lua"},
    {"RAVANGE HUB","Key",false,"https://raw.githubusercontent.com/Revenge-Hub-Roblox/Scripts/refs/heads/main/Loader.lua"},
    {"ZNEX HUB","Key",false,"https://api.jnkie.com/api/v1/luascripts/public/181cfe2bd5df35ce78607b5ffb37c6666abd76eda11ff33b0f24a1b2d8ee935f/download"},
    {"ASVARA HUB","Key",false,"https://raw.githubusercontent.com/asvraRoblox/stealegg/refs/heads/main/main"},
    {"VSN","No Key",false,"https://raw.githubusercontent.com/NetNullv1/VSN/refs/heads/main/HUB"},
    {"SHADOW HUB","Key",false,"https://pastebin.com/raw/QAvDbBKa"},
    {"VELOX HUB","Key",false,"https://api.jnkie.com/api/v1/luascripts/public/f0b3ce85f588800ae7e46415fc4dd79ff2b0d09c9b6a8e19cea8a67b47f1bcbd/download"},
    {"KING VYPER","Key",false,"https://kingvypers.site/raw/TrialLoader"},
    {"AXURS","No Key",false,"https://raw.githubusercontent.com/XE3Scripts/Axur-sGamesHub/refs/heads/main/StealAnEgg"},
    {"POTATO HUB","Key",false,"https://raw.githubusercontent.com/potatohub67/potatoscripts/refs/heads/main/stealaegg.lua"},
    {"JANE HUB","No Key",false,"https://flowauth.net/v1/loaders/3c4e87ed34813171b0f8d53a108a7d88.lua"},
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
        result[i] = { name = entry[1], status = entry[2], recommended = entry[3], url = entry[4] }
    end
    return result
end

local ScriptDataStealAnEgg = NormalizeScriptData(RawScriptDataStealAnEgg)
local NewScriptsData = NormalizeScriptData(RawNewScriptsData)
for _, newScript in ipairs(NewScriptsData) do table.insert(ScriptDataStealAnEgg, newScript) end
local CleanedScripts = ScriptDataStealAnEgg

-- [ STORAGE ]
local FavConfigName, HistConfigName, CustConfigName = "leon4951hub_favorites.json", "leon4951hub_history.json", "leon4951hub_custom.json"
local FavoriteList, HistoryList, CustomScriptsList = {}, {}, {}

local function LoadData()
    if not readfile then return end
    local function loadFile(fname, target)
        local ok, raw = pcall(readfile, fname)
        if ok and type(raw) == "string" and raw ~= "" then
            local decodeOk, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
            if decodeOk and type(decoded) == "table" then
                for k,v in pairs(decoded) do target[k] = v end
            end
        end
    end
    loadFile(FavConfigName, FavoriteList)
    local okH, rawH = pcall(readfile, HistConfigName)
    if okH and type(rawH) == "string" and rawH ~= "" then
        local dOk, d = pcall(function() return HttpService:JSONDecode(rawH) end)
        if dOk and type(d) == "table" then HistoryList = d end
    end
    local okC, rawC = pcall(readfile, CustConfigName)
    if okC and type(rawC) == "string" and rawC ~= "" then
        local dOk, d = pcall(function() return HttpService:JSONDecode(rawC) end)
        if dOk and type(d) == "table" then CustomScriptsList = d end
    end
end

local function SaveData()
    if not writefile then return end
    pcall(function() writefile(FavConfigName, HttpService:JSONEncode(FavoriteList)) end)
    pcall(function() writefile(HistConfigName, HttpService:JSONEncode(HistoryList)) end)
    pcall(function() writefile(CustConfigName, HttpService:JSONEncode(CustomScriptsList)) end)
end

LoadData()

local FavoriteScriptsData = {}
local function RefreshFavoritesData()
    FavoriteScriptsData = {}
    for _, s in ipairs(CleanedScripts) do
        local id = s.name .. "|" .. s.url
        if FavoriteList[id] then table.insert(FavoriteScriptsData, s) end
    end
end
RefreshFavoritesData()

local function ExecuteScript(name, status, url)
    if not url or url == "" then return end
    local ok, err = pcall(function()
        if string.sub(url, 1, 10) == "loadstring" or string.find(url, "script_key") then
            loadstring(url)()
        else
            loadstring(game:HttpGet(url))()
        end
    end)
    if not ok then
        warn("[LEON4951] Gagal: " .. tostring(err))
    else
        table.insert(HistoryList, 1, {name = name, status = status, url = url, timestamp = os.time(), success = true})
        if #HistoryList > 50 then table.remove(HistoryList, 51) end
        SaveData()
        for i, cat in ipairs(Categories) do
            if cat.key == "History" and activeCategoryIndex == i then
                RenderContent(i)
                break
            end
        end
    end
end

-- [ ICON MAP - SUPER DETAILED ]
local IconMap = {
    egg = "🥚",
    crown = "👑",
    bolt = "⚡",
    cat = "",
    target = "🎯",
    ghost = "👻",
    star = "⭐",
    clock = "🕐",
    plus = "➕",
    info = "ℹ️",
    bell = "",
    settings = "⚙️",
    lightning = "⚡",
    fire = "🔥"
}

local Categories = {
    { key = "StealAnEgg", name = "Steal an Egg", icon = "egg", type = "script_list", scripts = CleanedScripts },
    { key = "Favorite", name = "Favorite", icon = "star", type = "script_list", scripts = FavoriteScriptsData },
    { key = "History", name = "History", icon = "clock", type = "history", scripts = HistoryList },
    { key = "Custom", name = "Tambahkan Script", icon = "plus", type = "custom_script", scripts = CustomScriptsList },
    { key = "InfoAllScript", name = "Info / All Script", icon = "info", type = "info", scripts = CleanedScripts },
    { key = "NewScript", name = "New Script", icon = "bell", type = "new_script", scripts = NewScriptsData, hasNotification = true },
    { key = "Settings", name = "Settings", icon = "settings", type = "settings", scripts = {} },
}

local activeCategoryIndex = 1
local activeFilter = "ALL"

-- [ ROOT UI ]
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "leon4951HubGuiV4"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- [ MAIN FRAME ]
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.fromOffset(820, 500)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.fromScale(0.5, 0.5)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = false
MainFrame.Active = true
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Theme.BorderColor
MainStroke.Thickness = 1
MainStroke.Parent = MainFrame
local MainScale = Instance.new("UIScale")
MainScale.Scale = 0
MainScale.Parent = MainFrame

-- [ LOGO F - BIRU/UNGU ]
local function CreateFLogo(size, rotation)
    local container = Instance.new("Frame")
    container.Size = size
    container.BackgroundTransparency = 1
    container.Rotation = rotation or -12
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, math.floor(size.Y.Offset * 0.28))
    topBar.BackgroundColor3 = Theme.AccentIndigo
    topBar.BorderSizePixel = 0
    topBar.Parent = container
    Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 2)
    local midBar = Instance.new("Frame")
    midBar.Size = UDim2.new(0.68, 0, 0, math.floor(size.Y.Offset * 0.24))
    midBar.Position = UDim2.new(0.2, 0, 0.4, 0)
    midBar.BackgroundColor3 = Theme.AccentIndigo
    midBar.BorderSizePixel = 0
    midBar.Parent = container
    Instance.new("UICorner", midBar).CornerRadius = UDim.new(0, 2)
    local stem = Instance.new("Frame")
    stem.Size = UDim2.new(0, math.floor(size.X.Offset * 0.28), 1, 0)
    stem.Position = UDim2.new(0.08, 0, 0, 0)
    stem.BackgroundColor3 = Theme.AccentIndigo
    stem.BorderSizePixel = 0
    stem.Parent = container
    Instance.new("UICorner", stem).CornerRadius = UDim.new(0, 2)
    return container
end

-- [ HEADER ]
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 56)
Header.BackgroundTransparency = 1
Header.Active = true
Header.Parent = MainFrame

local LogoF = CreateFLogo(UDim2.fromOffset(32, 32), -12)
LogoF.Position = UDim2.new(0, 16, 0, 12)
LogoF.Parent = Header

local TitleContainer = Instance.new("Frame")
TitleContainer.Size = UDim2.new(0, 200, 0, 44)
TitleContainer.Position = UDim2.new(0, 54, 0, 6)
TitleContainer.BackgroundTransparency = 1
TitleContainer.Parent = Header

local Title = Instance.new("TextLabel")
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextColor3 = Theme.TextPrimary
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(1, 0, 0, 22)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.RichText = true
Title.Text = "leon4951 <font color=\"rgb(99, 102, 241)\">Hub</font>"
Title.Parent = TitleContainer

local Subtitle = Instance.new("TextLabel")
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextSize = 10
Subtitle.TextColor3 = Theme.TextMuted
Subtitle.BackgroundTransparency = 1
Subtitle.Size = UDim2.new(1, 0, 0, 14)
Subtitle.Position = UDim2.new(0, 0, 0, 22)
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Text = "Steal an Egg • Auto Farm & More"
Subtitle.Parent = TitleContainer

local ControlContainer = Instance.new("Frame")
ControlContainer.Size = UDim2.fromOffset(64, 30)
ControlContainer.Position = UDim2.new(1, -74, 0, 13)
ControlContainer.BackgroundTransparency = 1
ControlContainer.Parent = Header
local ControlLayout = Instance.new("UIListLayout")
ControlLayout.FillDirection = Enum.FillDirection.Horizontal
ControlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
ControlLayout.VerticalAlignment = Enum.VerticalAlignment.Center
ControlLayout.Padding = UDim.new(0, 6)
ControlLayout.Parent = ControlContainer

local function CreateHeaderButton(iconText, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(30, 30)
    btn.BackgroundColor3 = Theme.CardBg
    btn.Text = iconText
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.TextColor3 = Theme.TextSecondary
    btn.AutoButtonColor = false
    btn.Parent = ControlContainer
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.AccentIndigo, TextColor3 = Theme.TextPrimary }):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.CardBg, TextColor3 = Theme.TextSecondary }):Play() end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- [ BODY ]
local Body = Instance.new("Frame")
Body.Name = "Body"
Body.Size = UDim2.new(1, 0, 1, -56)
Body.Position = UDim2.new(0, 0, 0, 56)
Body.BackgroundTransparency = 1
Body.Parent = MainFrame

-- [ SIDEBAR ]
local Sidebar = Instance.new("ScrollingFrame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 170, 1, 0)
Sidebar.BackgroundColor3 = Theme.SidebarBg
Sidebar.BorderSizePixel = 0
Sidebar.ScrollBarThickness = 0
Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
Sidebar.Parent = Body
Instance.new("UIPadding", Sidebar).PaddingLeft = UDim.new(0, 8)
Instance.new("UIPadding", Sidebar).PaddingRight = UDim.new(0, 8)
Instance.new("UIPadding", Sidebar).PaddingTop = UDim.new(0, 8)
Instance.new("UIPadding", Sidebar).PaddingBottom = UDim.new(0, 8)

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.Padding = UDim.new(0, 3)
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Parent = Sidebar

-- [ CONTENT ]
local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -170, 1, 0)
Content.Position = UDim2.new(0, 170, 0, 0)
Content.BackgroundTransparency = 1
Content.Parent = Body
Instance.new("UIPadding", Content).PaddingLeft = UDim.new(0, 16)
Instance.new("UIPadding", Content).PaddingRight = UDim.new(0, 16)
Instance.new("UIPadding", Content).PaddingTop = UDim.new(0, 12)
Instance.new("UIPadding", Content).PaddingBottom = UDim.new(0, 12)

local ContentHeader = Instance.new("Frame")
ContentHeader.Size = UDim2.new(1, 0, 0, 70)
ContentHeader.BackgroundTransparency = 1
ContentHeader.Parent = Content

local ContentLabel = Instance.new("TextLabel")
ContentLabel.Font = Enum.Font.GothamBold
ContentLabel.TextSize = 15
ContentLabel.TextColor3 = Theme.TextPrimary
ContentLabel.BackgroundTransparency = 1
ContentLabel.Size = UDim2.new(1, 0, 0, 20)
ContentLabel.Position = UDim2.new(0, 0, 0, 0)
ContentLabel.TextXAlignment = Enum.TextXAlignment.Left
ContentLabel.Text = "STEAL AN EGG SCRIPTS"
ContentLabel.Parent = ContentHeader

local FilterContainer = Instance.new("Frame")
FilterContainer.Size = UDim2.new(1, 0, 0, 30)
FilterContainer.Position = UDim2.new(0, 0, 0, 26)
FilterContainer.BackgroundTransparency = 1
FilterContainer.Parent = ContentHeader

local FilterLayout = Instance.new("UIListLayout")
FilterLayout.FillDirection = Enum.FillDirection.Horizontal
FilterLayout.Padding = UDim.new(0, 6)
FilterLayout.SortOrder = Enum.SortOrder.LayoutOrder
FilterLayout.Parent = FilterContainer

local filterButtons = {}

local SearchBox = Instance.new("TextBox")
SearchBox.Name = "SearchBox"
SearchBox.Size = UDim2.new(1, -120, 0, 30)
SearchBox.Position = UDim2.new(0, 0, 0, 38)
SearchBox.BackgroundColor3 = Theme.SearchBg
SearchBox.PlaceholderText = " 🔍 Cari nama script..."
SearchBox.PlaceholderColor3 = Theme.TextMuted
SearchBox.Text = ""
SearchBox.TextColor3 = Theme.TextPrimary
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 11
SearchBox.Parent = ContentHeader
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 6)
local SearchStroke = Instance.new("UIStroke")
SearchStroke.Color = Theme.BorderColor
SearchStroke.Thickness = 1
SearchStroke.Parent = SearchBox

local AddScriptBtn = Instance.new("TextButton")
AddScriptBtn.Size = UDim2.fromOffset(114, 30)
AddScriptBtn.Position = UDim2.new(1, -114, 0, 38)
AddScriptBtn.BackgroundColor3 = Theme.AccentIndigo
AddScriptBtn.Text = "+ Tambah Script"
AddScriptBtn.Font = Enum.Font.GothamBold
AddScriptBtn.TextSize = 11
AddScriptBtn.TextColor3 = Theme.TextPrimary
AddScriptBtn.AutoButtonColor = false
AddScriptBtn.Parent = ContentHeader
Instance.new("UICorner", AddScriptBtn).CornerRadius = UDim.new(0, 6)
AddScriptBtn.Visible = false

AddScriptBtn.MouseButton1Click:Connect(function()
    for i, cat in ipairs(Categories) do
        if cat.key == "Custom" then SetActiveCategory(i); break end
    end
end)

local ScriptScroll = Instance.new("ScrollingFrame")
ScriptScroll.Size = UDim2.new(1, 0, 1, -82)
ScriptScroll.Position = UDim2.new(0, 0, 0, 82)
ScriptScroll.BackgroundTransparency = 1
ScriptScroll.BorderSizePixel = 0
ScriptScroll.ScrollBarThickness = 4
ScriptScroll.ScrollBarImageColor3 = Theme.AccentIndigo
ScriptScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ScriptScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScriptScroll.Parent = Content

local RenderSidebarTabs

-- [ HELPER: Get row icon based on index ]
local RowIcons = {"egg", "crown", "bolt", "cat", "target", "ghost", "fire", "lightning"}
local function GetRowIcon(index)
    return RowIcons[((index - 1) % #RowIcons) + 1]
end

-- [ RENDER CONTENT ]
local function RenderContent(categoryIndex)
    local category = Categories[categoryIndex]

    for _, child in ipairs(ScriptScroll:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIGridLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end

    local oldLayout = ScriptScroll:FindFirstChildOfClass("UIListLayout") or ScriptScroll:FindFirstChildOfClass("UIGridLayout")
    if oldLayout then oldLayout:Destroy() end

    -- [ INFO TAB ]
    if category.type == "info" then
        FilterContainer.Visible = false
        SearchBox.Visible = false
        AddScriptBtn.Visible = false
        ContentLabel.Text = "ALL SCRIPTS DATABASE -- OVERVIEW"
        local ListLayout = Instance.new("UIListLayout")
        ListLayout.Padding = UDim.new(0, 8)
        ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ListLayout.Parent = ScriptScroll

        local totalCount, keyCount, noKeyCount = #category.scripts, 0, 0
        for _, s in ipairs(category.scripts) do
            if s.status == "Key" then keyCount += 1
            elseif s.status == "No Key" then noKeyCount += 1 end
        end

        local StatsBanner = Instance.new("Frame")
        StatsBanner.Size = UDim2.new(1, 0, 0, 48)
        StatsBanner.BackgroundColor3 = Theme.CardBg
        StatsBanner.LayoutOrder = 1
        StatsBanner.Parent = ScriptScroll
        Instance.new("UICorner", StatsBanner).CornerRadius = UDim.new(0, 8)
        local BannerStroke = Instance.new("UIStroke")
        BannerStroke.Color = Theme.BorderColor
        BannerStroke.Thickness = 1
        BannerStroke.Parent = StatsBanner

        local StatsText = Instance.new("TextLabel")
        StatsText.Font = Enum.Font.GothamBold
        StatsText.TextSize = 11
        StatsText.TextColor3 = Theme.TextSecondary
        StatsText.BackgroundTransparency = 1
        StatsText.Size = UDim2.new(1, -20, 1, 0)
        StatsText.Position = UDim2.new(0, 12, 0, 0)
        StatsText.TextXAlignment = Enum.TextXAlignment.Left
        StatsText.RichText = true
        StatsText.Text = " 📊 TOTAL: <font color=\"rgb(255,255,255)\">" .. totalCount .. "</font>  |   KEY: <font color=\"rgb(124,58,237)\">" .. keyCount .. "</font>  |   NO KEY: <font color=\"rgb(34,197,94)\">" .. noKeyCount .. "</font>"
        StatsText.Parent = StatsBanner
        ScriptScroll.CanvasPosition = Vector2.new(0, 0)
        return

    -- [ NEW SCRIPT TAB ]
    elseif category.type == "new_script" then
        FilterContainer.Visible = false
        SearchBox.Visible = false
        AddScriptBtn.Visible = false
        ContentLabel.Text = "NEW SCRIPTS -- UPDATES"
        local ListLayout = Instance.new("UIListLayout")
        ListLayout.Padding = UDim.new(0, 8)
        ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ListLayout.Parent = ScriptScroll

        if #category.scripts == 0 then
            local empty = Instance.new("TextLabel")
            empty.Font = Enum.Font.GothamBold
            empty.TextSize = 12
            empty.TextColor3 = Theme.TextMuted
            empty.BackgroundTransparency = 1
            empty.Size = UDim2.new(1, 0, 0, 50)
            empty.Text = "Belum Ada Script Baru"
            empty.Parent = ScriptScroll
        else
            for i, scriptEntry in ipairs(category.scripts) do
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 56)
                row.BackgroundColor3 = Theme.CardBg
                row.LayoutOrder = i
                row.Parent = ScriptScroll
                Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

                local iconBg = Instance.new("Frame")
                iconBg.Size = UDim2.fromOffset(36, 36)
                iconBg.Position = UDim2.new(0, 12, 0.5, -18)
                iconBg.BackgroundColor3 = Theme.IconBg
                iconBg.Parent = row
                Instance.new("UICorner", iconBg).CornerRadius = UDim.new(1, 0)
                local iconLbl = Instance.new("TextLabel")
                iconLbl.Size = UDim2.new(1, 0, 1, 0)
                iconLbl.BackgroundTransparency = 1
                iconLbl.Font = Enum.Font.GothamBold
                iconLbl.TextSize = 18
                iconLbl.Text = IconMap[GetRowIcon(i)] or "⚡"
                iconLbl.TextColor3 = Theme.TextPrimary
                iconLbl.Parent = iconBg

                local nameLabel = Instance.new("TextLabel")
                nameLabel.Font = Enum.Font.GothamBold
                nameLabel.TextSize = 13
                nameLabel.TextColor3 = Theme.TextPrimary
                nameLabel.BackgroundTransparency = 1
                nameLabel.Size = UDim2.new(1, -220, 0, 18)
                nameLabel.Position = UDim2.new(0, 56, 0, 10)
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
                nameLabel.Text = scriptEntry.name
                nameLabel.Parent = row

                local descLabel = Instance.new("TextLabel")
                descLabel.Font = Enum.Font.Gotham
                descLabel.TextSize = 10
                descLabel.TextColor3 = Theme.TextMuted
                descLabel.BackgroundTransparency = 1
                descLabel.Size = UDim2.new(1, -220, 0, 14)
                descLabel.Position = UDim2.new(0, 56, 0, 30)
                descLabel.TextXAlignment = Enum.TextXAlignment.Left
                descLabel.TextTruncate = Enum.TextTruncate.AtEnd
                descLabel.Text = "Script baru ditambahkan"
                descLabel.Parent = row

                local runBtn = Instance.new("TextButton")
                runBtn.Size = UDim2.fromOffset(96, 30)
                runBtn.Position = UDim2.new(1, -104, 0.5, -15)
                runBtn.BackgroundColor3 = Theme.ExecuteBtn
                runBtn.Text = "▶ EXECUTE"
                runBtn.Font = Enum.Font.GothamBold
                runBtn.TextSize = 11
                runBtn.TextColor3 = Theme.TextPrimary
                runBtn.AutoButtonColor = false
                runBtn.Parent = row
                Instance.new("UICorner", runBtn).CornerRadius = UDim.new(0, 6)
                runBtn.MouseButton1Click:Connect(function() ExecuteScript(scriptEntry.name, scriptEntry.status, scriptEntry.url) end)

                local statusBadge = Instance.new("TextLabel")
                statusBadge.Size = UDim2.fromOffset(60, 22)
                statusBadge.Position = UDim2.new(1, -172, 0.5, -11)
                statusBadge.BackgroundColor3 = (scriptEntry.status == "Key") and Theme.KeyTagBg or Theme.NoKeyTagBg
                statusBadge.Text = scriptEntry.status
                statusBadge.Font = Enum.Font.GothamBold
                statusBadge.TextSize = 10
                statusBadge.TextColor3 = Theme.TextPrimary
                statusBadge.Parent = row
                Instance.new("UICorner", statusBadge).CornerRadius = UDim.new(0, 4)

                local favBtn = Instance.new("TextButton")
                favBtn.Size = UDim2.fromOffset(30, 30)
                favBtn.Position = UDim2.new(1, -210, 0.5, -15)
                favBtn.BackgroundColor3 = Theme.CardBg
                favBtn.Text = FavoriteList[scriptEntry.name .. "|" .. scriptEntry.url] and "★" or "☆"
                favBtn.Font = Enum.Font.GothamBold
                favBtn.TextSize = 15
                favBtn.TextColor3 = FavoriteList[scriptEntry.name .. "|" .. scriptEntry.url] and Theme.GoldBadge or Theme.TextSecondary
                favBtn.AutoButtonColor = false
                favBtn.Parent = row
                Instance.new("UICorner", favBtn).CornerRadius = UDim.new(0, 6)
                favBtn.MouseButton1Click:Connect(function()
                    local fKeyId = scriptEntry.name .. "|" .. scriptEntry.url
                    if FavoriteList[fKeyId] then FavoriteList[fKeyId] = nil; favBtn.Text = "☆"; favBtn.TextColor3 = Theme.TextSecondary
                    else FavoriteList[fKeyId] = true; favBtn.Text = "★"; favBtn.TextColor3 = Theme.GoldBadge end
                    SaveData(); RefreshFavoritesData(); Categories[2].scripts = FavoriteScriptsData
                end)

                local copyBtn = Instance.new("TextButton")
                copyBtn.Size = UDim2.fromOffset(30, 30)
                copyBtn.Position = UDim2.new(1, -248, 0.5, -15)
                copyBtn.BackgroundColor3 = Theme.CardBg
                copyBtn.Text = ""
                copyBtn.Font = Enum.Font.GothamBold
                copyBtn.TextSize = 13
                copyBtn.TextColor3 = Theme.TextSecondary
                copyBtn.AutoButtonColor = false
                copyBtn.Parent = row
                Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 6)
                copyBtn.MouseButton1Click:Connect(function()
                    if setclipboard then setclipboard(scriptEntry.url) end
                    copyBtn.TextColor3 = Theme.AccentIndigo
                    task.delay(1, function() if copyBtn then copyBtn.TextColor3 = Theme.TextSecondary end end)
                end)
            end
        end
        ScriptScroll.CanvasPosition = Vector2.new(0, 0)
        return

    -- [ HISTORY TAB ]
    elseif category.type == "history" then
        FilterContainer.Visible = false
        SearchBox.Visible = false
        AddScriptBtn.Visible = false
        ContentLabel.Text = "Riwayat Script"

        local descLabel = Instance.new("TextLabel")
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextSize = 11
        descLabel.TextColor3 = Theme.TextMuted
        descLabel.BackgroundTransparency = 1
        descLabel.Size = UDim2.new(1, 0, 0, 16)
        descLabel.Position = UDim2.new(0, 0, 0, 20)
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Text = "Daftar script yang pernah kamu jalankan."
        descLabel.Parent = ContentHeader

        local ListLayout = Instance.new("UIListLayout")
        ListLayout.Padding = UDim.new(0, 8)
        ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ListLayout.Parent = ScriptScroll

        if #category.scripts == 0 then
            local empty = Instance.new("TextLabel")
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 12
            empty.TextColor3 = Theme.TextMuted
            empty.BackgroundTransparency = 1
            empty.Size = UDim2.new(1, 0, 0, 50)
            empty.Text = "Belum ada script yang dijalankan."
            empty.Parent = ScriptScroll
        else
            for i, scriptEntry in ipairs(category.scripts) do
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 56)
                row.BackgroundColor3 = Theme.CardBg
                row.LayoutOrder = i
                row.Parent = ScriptScroll
                Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

                local iconBg = Instance.new("Frame")
                iconBg.Size = UDim2.fromOffset(36, 36)
                iconBg.Position = UDim2.new(0, 12, 0.5, -18)
                iconBg.BackgroundColor3 = Theme.IconBg
                iconBg.Parent = row
                Instance.new("UICorner", iconBg).CornerRadius = UDim.new(1, 0)
                local iconLbl = Instance.new("TextLabel")
                iconLbl.Size = UDim2.new(1, 0, 1, 0)
                iconLbl.BackgroundTransparency = 1
                iconLbl.Font = Enum.Font.GothamBold
                iconLbl.TextSize = 18
                iconLbl.Text = IconMap[GetRowIcon(i)] or "🥚"
                iconLbl.TextColor3 = Theme.TextPrimary
                iconLbl.Parent = iconBg

                local nameLabel = Instance.new("TextLabel")
                nameLabel.Font = Enum.Font.GothamBold
                nameLabel.TextSize = 13
                nameLabel.TextColor3 = Theme.TextPrimary
                nameLabel.BackgroundTransparency = 1
                nameLabel.Size = UDim2.new(1, -320, 0, 18)
                nameLabel.Position = UDim2.new(0, 56, 0, 8)
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
                nameLabel.Text = scriptEntry.name
                nameLabel.Parent = row

                local timeLabel = Instance.new("TextLabel")
                timeLabel.Font = Enum.Font.Gotham
                timeLabel.TextSize = 10
                timeLabel.TextColor3 = Theme.TextMuted
                timeLabel.BackgroundTransparency = 1
                timeLabel.Size = UDim2.new(1, -320, 0, 14)
                timeLabel.Position = UDim2.new(0, 56, 0, 28)
                timeLabel.TextXAlignment = Enum.TextXAlignment.Left
                local ts = scriptEntry.timestamp or os.time()
                local dt = os.date("*t", ts)
                timeLabel.Text = string.format("%02d Okt 2026 • %02d:%02d", dt.day, dt.hour, dt.min)
                timeLabel.Parent = row

                local statusBadge = Instance.new("TextLabel")
                statusBadge.Size = UDim2.fromOffset(60, 22)
                statusBadge.Position = UDim2.new(1, -320, 0.5, -11)
                statusBadge.BackgroundColor3 = (scriptEntry.status == "Key") and Theme.KeyTagBg or Theme.NoKeyTagBg
                statusBadge.Text = scriptEntry.status
                statusBadge.Font = Enum.Font.GothamBold
                statusBadge.TextSize = 10
                statusBadge.TextColor3 = Theme.TextPrimary
                statusBadge.Parent = row
                Instance.new("UICorner", statusBadge).CornerRadius = UDim.new(0, 4)

                local resultBadge = Instance.new("TextLabel")
                resultBadge.Size = UDim2.fromOffset(60, 22)
                resultBadge.Position = UDim2.new(1, -252, 0.5, -11)
                resultBadge.BackgroundColor3 = Theme.SuccessGreen
                resultBadge.Text = "Berhasil"
                resultBadge.Font = Enum.Font.GothamBold
                resultBadge.TextSize = 10
                resultBadge.TextColor3 = Theme.TextPrimary
                resultBadge.Parent = row
                Instance.new("UICorner", resultBadge).CornerRadius = UDim.new(0, 4)

                local copyBtn = Instance.new("TextButton")
                copyBtn.Size = UDim2.fromOffset(30, 30)
                copyBtn.Position = UDim2.new(1, -214, 0.5, -15)
                copyBtn.BackgroundColor3 = Theme.CardBg
                copyBtn.Text = ""
                copyBtn.Font = Enum.Font.GothamBold
                copyBtn.TextSize = 13
                copyBtn.TextColor3 = Theme.TextSecondary
                copyBtn.AutoButtonColor = false
                copyBtn.Parent = row
                Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 6)
                copyBtn.MouseButton1Click:Connect(function()
                    if setclipboard then setclipboard(scriptEntry.url) end
                end)

                local runBtn = Instance.new("TextButton")
                runBtn.Size = UDim2.fromOffset(96, 30)
                runBtn.Position = UDim2.new(1, -104, 0.5, -15)
                runBtn.BackgroundColor3 = Theme.ExecuteBtn
                runBtn.Text = "▶ EXECUTE"
                runBtn.Font = Enum.Font.GothamBold
                runBtn.TextSize = 11
                runBtn.TextColor3 = Theme.TextPrimary
                runBtn.AutoButtonColor = false
                runBtn.Parent = row
                Instance.new("UICorner", runBtn).CornerRadius = UDim.new(0, 6)
                runBtn.MouseButton1Click:Connect(function() ExecuteScript(scriptEntry.name, scriptEntry.status, scriptEntry.url) end)
            end
        end
        ScriptScroll.CanvasPosition = Vector2.new(0, 0)
        return

    -- [ CUSTOM SCRIPT TAB ]
    elseif category.type == "custom_script" then
        FilterContainer.Visible = false
        SearchBox.Visible = false
        AddScriptBtn.Visible = false
        ContentLabel.Text = "Tambahkan Script"

        local descLabel = Instance.new("TextLabel")
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextSize = 11
        descLabel.TextColor3 = Theme.TextMuted
        descLabel.BackgroundTransparency = 1
        descLabel.Size = UDim2.new(1, 0, 0, 16)
        descLabel.Position = UDim2.new(0, 0, 0, 20)
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Text = "Masukkan nama, key (jika ada) dan link loadstring script."
        descLabel.Parent = ContentHeader

        local ListLayout = Instance.new("UIListLayout")
        ListLayout.Padding = UDim.new(0, 10)
        ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ListLayout.Parent = ScriptScroll

        -- Input Area with labels
        local inputArea = Instance.new("Frame")
        inputArea.Size = UDim2.new(1, 0, 0, 70)
        inputArea.BackgroundColor3 = Theme.CardBg
        inputArea.LayoutOrder = 1
        inputArea.Parent = ScriptScroll
        Instance.new("UICorner", inputArea).CornerRadius = UDim.new(0, 8)
        Instance.new("UIStroke", inputArea).Color = Theme.BorderColor

        -- Name Input
        local nameLabel2 = Instance.new("TextLabel")
        nameLabel2.Font = Enum.Font.GothamBold
        nameLabel2.TextSize = 10
        nameLabel2.TextColor3 = Theme.TextSecondary
        nameLabel2.BackgroundTransparency = 1
        nameLabel2.Size = UDim2.fromOffset(180, 14)
        nameLabel2.Position = UDim2.new(0, 12, 0, 8)
        nameLabel2.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel2.Text = "Nama Script"
        nameLabel2.Parent = inputArea

        local nameInput = Instance.new("TextBox")
        nameInput.Size = UDim2.fromOffset(180, 30)
        nameInput.Position = UDim2.new(0, 12, 0, 26)
        nameInput.BackgroundColor3 = Theme.InputBg
        nameInput.PlaceholderText = "Masukkan nama script..."
        nameInput.PlaceholderColor3 = Theme.TextMuted
        nameInput.TextColor3 = Theme.TextPrimary
        nameInput.Font = Enum.Font.Gotham
        nameInput.TextSize = 11
        nameInput.ClearTextOnFocus = false
        nameInput.Parent = inputArea
        Instance.new("UICorner", nameInput).CornerRadius = UDim.new(0, 6)
        Instance.new("UIPadding", nameInput).PaddingLeft = UDim.new(0, 10)

        -- Status Dropdown
        local statusLabel2 = Instance.new("TextLabel")
        statusLabel2.Font = Enum.Font.GothamBold
        statusLabel2.TextSize = 10
        statusLabel2.TextColor3 = Theme.TextSecondary
        statusLabel2.BackgroundTransparency = 1
        statusLabel2.Size = UDim2.fromOffset(130, 14)
        statusLabel2.Position = UDim2.new(0, 204, 0, 8)
        statusLabel2.TextXAlignment = Enum.TextXAlignment.Left
        statusLabel2.Text = "KEY / NO KEY"
        statusLabel2.Parent = inputArea

        local statusToggle = Instance.new("TextButton")
        statusToggle.Size = UDim2.fromOffset(130, 30)
        statusToggle.Position = UDim2.new(0, 204, 0, 26)
        statusToggle.BackgroundColor3 = Theme.NoKeyTagBg
        statusToggle.Text = "No Key"
        statusToggle.Font = Enum.Font.GothamBold
        statusToggle.TextSize = 11
        statusToggle.TextColor3 = Theme.TextPrimary
        statusToggle.AutoButtonColor = false
        statusToggle.Parent = inputArea
        Instance.new("UICorner", statusToggle).CornerRadius = UDim.new(0, 6)

        local currentStatus = "No Key"
        statusToggle.MouseButton1Click:Connect(function()
            if currentStatus == "No Key" then
                currentStatus = "Key"
                statusToggle.Text = "Key"
                statusToggle.BackgroundColor3 = Theme.KeyTagBg
            else
                currentStatus = "No Key"
                statusToggle.Text = "No Key"
                statusToggle.BackgroundColor3 = Theme.NoKeyTagBg
            end
        end)

        -- URL Input
        local urlLabel2 = Instance.new("TextLabel")
        urlLabel2.Font = Enum.Font.GothamBold
        urlLabel2.TextSize = 10
        urlLabel2.TextColor3 = Theme.TextSecondary
        urlLabel2.BackgroundTransparency = 1
        urlLabel2.Size = UDim2.fromOffset(200, 14)
        urlLabel2.Position = UDim2.new(0, 346, 0, 8)
        urlLabel2.TextXAlignment = Enum.TextXAlignment.Left
        urlLabel2.Text = "Link Loadstring"
        urlLabel2.Parent = inputArea

        local urlInput = Instance.new("TextBox")
        urlInput.Size = UDim2.fromOffset(280, 30)
        urlInput.Position = UDim2.new(0, 346, 0, 26)
        urlInput.BackgroundColor3 = Theme.InputBg
        urlInput.PlaceholderText = "Masukkan link loadstring..."
        urlInput.PlaceholderColor3 = Theme.TextMuted
        urlInput.TextColor3 = Theme.TextPrimary
        urlInput.Font = Enum.Font.Gotham
        urlInput.TextSize = 11
        urlInput.ClearTextOnFocus = false
        urlInput.Parent = inputArea
        Instance.new("UICorner", urlInput).CornerRadius = UDim.new(0, 6)
        Instance.new("UIPadding", urlInput).PaddingLeft = UDim.new(0, 10)

        local addBtn = Instance.new("TextButton")
        addBtn.Size = UDim2.fromOffset(80, 30)
        addBtn.Position = UDim2.new(0, 638, 0, 26)
        addBtn.BackgroundColor3 = Theme.AccentIndigo
        addBtn.Text = "+ ADD"
        addBtn.Font = Enum.Font.GothamBold
        addBtn.TextSize = 12
        addBtn.TextColor3 = Theme.TextPrimary
        addBtn.AutoButtonColor = false
        addBtn.Parent = inputArea
        Instance.new("UICorner", addBtn).CornerRadius = UDim.new(0, 6)

        addBtn.MouseButton1Click:Connect(function()
            local name = string.gsub(nameInput.Text, "^%s*(.-)%s*$", "%1")
            local url = string.gsub(urlInput.Text, "^%s*(.-)%s*$", "%1")
            if name == "" or url == "" then
                nameInput.PlaceholderText = "Nama wajib!"
                urlInput.PlaceholderText = "Link wajib!"
                task.delay(1.5, function()
                    nameInput.PlaceholderText = "Masukkan nama script..."
                    urlInput.PlaceholderText = "Masukkan link loadstring..."
                end)
                return
            end
            table.insert(CustomScriptsList, 1, { name = name, status = currentStatus, url = url, id = name .. "|" .. url })
            SaveData()
            nameInput.Text = ""
            urlInput.Text = ""
            RenderContent(categoryIndex)
        end)

        -- Saved Section Header
        local savedHeader = Instance.new("Frame")
        savedHeader.Size = UDim2.new(1, 0, 0, 24)
        savedHeader.BackgroundTransparency = 1
        savedHeader.LayoutOrder = 2
        savedHeader.Parent = ScriptScroll

        local savedTitle = Instance.new("TextLabel")
        savedTitle.Font = Enum.Font.GothamBold
        savedTitle.TextSize = 13
        savedTitle.TextColor3 = Theme.TextPrimary
        savedTitle.BackgroundTransparency = 1
        savedTitle.Size = UDim2.new(1, 0, 0, 18)
        savedTitle.Position = UDim2.new(0, 0, 0, 0)
        savedTitle.TextXAlignment = Enum.TextXAlignment.Left
        savedTitle.Text = "Script yang Tersimpan"
        savedTitle.Parent = savedHeader

        -- Custom Scripts List
        if #category.scripts == 0 then
            local empty = Instance.new("TextLabel")
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 11
            empty.TextColor3 = Theme.TextMuted
            empty.BackgroundTransparency = 1
            empty.Size = UDim2.new(1, 0, 0, 50)
            empty.Text = "Belum ada script custom. Tambahkan di atas."
            empty.Parent = ScriptScroll
        else
            for i, scriptEntry in ipairs(category.scripts) do
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 60)
                row.BackgroundColor3 = Theme.CardBg
                row.LayoutOrder = 3 + i
                row.Parent = ScriptScroll
                Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

                local iconBg = Instance.new("Frame")
                iconBg.Size = UDim2.fromOffset(36, 36)
                iconBg.Position = UDim2.new(0, 12, 0.5, -18)
                iconBg.BackgroundColor3 = Theme.IconBg
                iconBg.Parent = row
                Instance.new("UICorner", iconBg).CornerRadius = UDim.new(1, 0)
                local iconLbl = Instance.new("TextLabel")
                iconLbl.Size = UDim2.new(1, 0, 1, 0)
                iconLbl.BackgroundTransparency = 1
                iconLbl.Font = Enum.Font.GothamBold
                iconLbl.TextSize = 18
                iconLbl.Text = IconMap[GetRowIcon(i)] or "⚡"
                iconLbl.TextColor3 = Theme.TextPrimary
                iconLbl.Parent = iconBg

                local nameLabel3 = Instance.new("TextLabel")
                nameLabel3.Font = Enum.Font.GothamBold
                nameLabel3.TextSize = 13
                nameLabel3.TextColor3 = Theme.TextPrimary
                nameLabel3.BackgroundTransparency = 1
                nameLabel3.Size = UDim2.new(1, -380, 0, 18)
                nameLabel3.Position = UDim2.new(0, 56, 0, 8)
                nameLabel3.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel3.TextTruncate = Enum.TextTruncate.AtEnd
                nameLabel3.Text = scriptEntry.name
                nameLabel3.Parent = row

                local urlLabel3 = Instance.new("TextLabel")
                urlLabel3.Font = Enum.Font.Gotham
                urlLabel3.TextSize = 10
                urlLabel3.TextColor3 = Theme.TextMuted
                urlLabel3.BackgroundTransparency = 1
                urlLabel3.Size = UDim2.new(1, -380, 0, 14)
                urlLabel3.Position = UDim2.new(0, 56, 0, 28)
                urlLabel3.TextXAlignment = Enum.TextXAlignment.Left
                urlLabel3.TextTruncate = Enum.TextTruncate.AtEnd
                urlLabel3.Text = string.sub(scriptEntry.url, 1, 55) .. (string.len(scriptEntry.url) > 55 and "..." or "")
                urlLabel3.Parent = row

                local statusBadge = Instance.new("TextLabel")
                statusBadge.Size = UDim2.fromOffset(60, 22)
                statusBadge.Position = UDim2.new(1, -320, 0.5, -11)
                statusBadge.BackgroundColor3 = (scriptEntry.status == "Key") and Theme.KeyTagBg or Theme.NoKeyTagBg
                statusBadge.Text = scriptEntry.status
                statusBadge.Font = Enum.Font.GothamBold
                statusBadge.TextSize = 10
                statusBadge.TextColor3 = Theme.TextPrimary
                statusBadge.Parent = row
                Instance.new("UICorner", statusBadge).CornerRadius = UDim.new(0, 4)

                local favBtn = Instance.new("TextButton")
                favBtn.Size = UDim2.fromOffset(30, 30)
                favBtn.Position = UDim2.new(1, -278, 0.5, -15)
                favBtn.BackgroundColor3 = Theme.CardBg
                favBtn.Text = FavoriteList[scriptEntry.id] and "★" or "☆"
                favBtn.Font = Enum.Font.GothamBold
                favBtn.TextSize = 15
                favBtn.TextColor3 = FavoriteList[scriptEntry.id] and Theme.GoldBadge or Theme.TextSecondary
                favBtn.AutoButtonColor = false
                favBtn.Parent = row
                Instance.new("UICorner", favBtn).CornerRadius = UDim.new(0, 6)
                favBtn.MouseButton1Click:Connect(function()
                    if FavoriteList[scriptEntry.id] then FavoriteList[scriptEntry.id] = nil; favBtn.Text = "☆"; favBtn.TextColor3 = Theme.TextSecondary
                    else FavoriteList[scriptEntry.id] = true; favBtn.Text = "★"; favBtn.TextColor3 = Theme.GoldBadge end
                    SaveData()
                end)

                local copyBtn = Instance.new("TextButton")
                copyBtn.Size = UDim2.fromOffset(30, 30)
                copyBtn.Position = UDim2.new(1, -240, 0.5, -15)
                copyBtn.BackgroundColor3 = Theme.CardBg
                copyBtn.Text = "📋"
                copyBtn.Font = Enum.Font.GothamBold
                copyBtn.TextSize = 13
                copyBtn.TextColor3 = Theme.TextSecondary
                copyBtn.AutoButtonColor = false
                copyBtn.Parent = row
                Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 6)
                copyBtn.MouseButton1Click:Connect(function()
                    if setclipboard then setclipboard(scriptEntry.url) end
                end)

                local runBtn = Instance.new("TextButton")
                runBtn.Size = UDim2.fromOffset(96, 30)
                runBtn.Position = UDim2.new(1, -202, 0.5, -15)
                runBtn.BackgroundColor3 = Theme.ExecuteBtn
                runBtn.Text = "▶ EXECUTE"
                runBtn.Font = Enum.Font.GothamBold
                runBtn.TextSize = 11
                runBtn.TextColor3 = Theme.TextPrimary
                runBtn.AutoButtonColor = false
                runBtn.Parent = row
                Instance.new("UICorner", runBtn).CornerRadius = UDim.new(0, 6)
                runBtn.MouseButton1Click:Connect(function() ExecuteScript(scriptEntry.name, scriptEntry.status, scriptEntry.url) end)

                -- DELETE BUTTON (X)
                local delBtn = Instance.new("TextButton")
                delBtn.Size = UDim2.fromOffset(30, 30)
                delBtn.Position = UDim2.new(1, -104, 0.5, -15)
                delBtn.BackgroundColor3 = Theme.CardBg
                delBtn.Text = "✕"
                delBtn.Font = Enum.Font.GothamBold
                delBtn.TextSize = 12
                delBtn.TextColor3 = Theme.TextSecondary
                delBtn.AutoButtonColor = false
                delBtn.Parent = row
                Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 6)
                delBtn.MouseButton1Click:Connect(function()
                    for idx, s in ipairs(CustomScriptsList) do
                        if s.id == scriptEntry.id then
                            table.remove(CustomScriptsList, idx)
                            if FavoriteList[s.id] then FavoriteList[s.id] = nil end
                            SaveData()
                            RenderContent(categoryIndex)
                            break
                        end
                    end
                end)
            end
        end
        ScriptScroll.CanvasPosition = Vector2.new(0, 0)
        return

    -- [ FAVORITE TAB ]
    elseif category.key == "Favorite" then
        FilterContainer.Visible = false
        SearchBox.Visible = false
        AddScriptBtn.Visible = false
        ContentLabel.Text = "Script Favorit"

        local descLabel = Instance.new("TextLabel")
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextSize = 11
        descLabel.TextColor3 = Theme.TextMuted
        descLabel.BackgroundTransparency = 1
        descLabel.Size = UDim2.new(1, -110, 0, 16)
        descLabel.Position = UDim2.new(0, 0, 0, 20)
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Text = "Script yang kamu tandai sebagai favorit."
        descLabel.Parent = ContentHeader

        local clearAllBtn = Instance.new("TextButton")
        clearAllBtn.Size = UDim2.fromOffset(100, 26)
        clearAllBtn.Position = UDim2.new(1, -100, 0, 20)
        clearAllBtn.BackgroundColor3 = Theme.DangerRed
        clearAllBtn.Text = "🗑 Hapus Semua"
        clearAllBtn.Font = Enum.Font.GothamBold
        clearAllBtn.TextSize = 10
        clearAllBtn.TextColor3 = Theme.TextPrimary
        clearAllBtn.AutoButtonColor = false
        clearAllBtn.Parent = ContentHeader
        Instance.new("UICorner", clearAllBtn).CornerRadius = UDim.new(0, 6)
        clearAllBtn.MouseButton1Click:Connect(function()
            FavoriteList = {}
            SaveData()
            RefreshFavoritesData()
            Categories[2].scripts = FavoriteScriptsData
            RenderContent(categoryIndex)
        end)

        local ListLayout = Instance.new("UIListLayout")
        ListLayout.Padding = UDim.new(0, 8)
        ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ListLayout.Parent = ScriptScroll

        if #category.scripts == 0 then
            local empty = Instance.new("TextLabel")
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 12
            empty.TextColor3 = Theme.TextMuted
            empty.BackgroundTransparency = 1
            empty.Size = UDim2.new(1, 0, 0, 50)
            empty.Text = "Belum ada script favorit."
            empty.Parent = ScriptScroll
        else
            for i, scriptEntry in ipairs(category.scripts) do
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 60)
                row.BackgroundColor3 = Theme.CardBg
                row.LayoutOrder = i
                row.Parent = ScriptScroll
                Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

                local iconBg = Instance.new("Frame")
                iconBg.Size = UDim2.fromOffset(36, 36)
                iconBg.Position = UDim2.new(0, 12, 0.5, -18)
                iconBg.BackgroundColor3 = Theme.IconBg
                iconBg.Parent = row
                Instance.new("UICorner", iconBg).CornerRadius = UDim.new(1, 0)
                local iconLbl = Instance.new("TextLabel")
                iconLbl.Size = UDim2.new(1, 0, 1, 0)
                iconLbl.BackgroundTransparency = 1
                iconLbl.Font = Enum.Font.GothamBold
                iconLbl.TextSize = 18
                iconLbl.Text = IconMap[GetRowIcon(i)] or "⭐"
                iconLbl.TextColor3 = Theme.TextPrimary
                iconLbl.Parent = iconBg

                local nameLabel4 = Instance.new("TextLabel")
                nameLabel4.Font = Enum.Font.GothamBold
                nameLabel4.TextSize = 13
                nameLabel4.TextColor3 = Theme.TextPrimary
                nameLabel4.BackgroundTransparency = 1
                nameLabel4.Size = UDim2.new(1, -340, 0, 18)
                nameLabel4.Position = UDim2.new(0, 56, 0, 8)
                nameLabel4.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel4.TextTruncate = Enum.TextTruncate.AtEnd
                nameLabel4.Text = scriptEntry.name
                nameLabel4.Parent = row

                local descLabel2 = Instance.new("TextLabel")
                descLabel2.Font = Enum.Font.Gotham
                descLabel2.TextSize = 10
                descLabel2.TextColor3 = Theme.TextMuted
                descLabel2.BackgroundTransparency = 1
                descLabel2.Size = UDim2.new(1, -340, 0, 14)
                descLabel2.Position = UDim2.new(0, 56, 0, 28)
                descLabel2.TextXAlignment = Enum.TextXAlignment.Left
                descLabel2.TextTruncate = Enum.TextTruncate.AtEnd
                descLabel2.Text = "Script favorit kamu"
                descLabel2.Parent = row

                local statusBadge = Instance.new("TextLabel")
                statusBadge.Size = UDim2.fromOffset(60, 22)
                statusBadge.Position = UDim2.new(1, -320, 0.5, -11)
                statusBadge.BackgroundColor3 = (scriptEntry.status == "Key") and Theme.KeyTagBg or Theme.NoKeyTagBg
                statusBadge.Text = scriptEntry.status
                statusBadge.Font = Enum.Font.GothamBold
                statusBadge.TextSize = 10
                statusBadge.TextColor3 = Theme.TextPrimary
                statusBadge.Parent = row
                Instance.new("UICorner", statusBadge).CornerRadius = UDim.new(0, 4)

                local favBtn = Instance.new("TextButton")
                favBtn.Size = UDim2.fromOffset(30, 30)
                favBtn.Position = UDim2.new(1, -278, 0.5, -15)
                favBtn.BackgroundColor3 = Theme.CardBg
                favBtn.Text = "★"
                favBtn.Font = Enum.Font.GothamBold
                favBtn.TextSize = 15
                favBtn.TextColor3 = Theme.GoldBadge
                favBtn.AutoButtonColor = false
                favBtn.Parent = row
                Instance.new("UICorner", favBtn).CornerRadius = UDim.new(0, 6)

                local copyBtn = Instance.new("TextButton")
                copyBtn.Size = UDim2.fromOffset(30, 30)
                copyBtn.Position = UDim2.new(1, -240, 0.5, -15)
                copyBtn.BackgroundColor3 = Theme.CardBg
                copyBtn.Text = "📋"
                copyBtn.Font = Enum.Font.GothamBold
                copyBtn.TextSize = 13
                copyBtn.TextColor3 = Theme.TextSecondary
                copyBtn.AutoButtonColor = false
                copyBtn.Parent = row
                Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 6)
                copyBtn.MouseButton1Click:Connect(function()
                    if setclipboard then setclipboard(scriptEntry.url) end
                end)

                local runBtn = Instance.new("TextButton")
                runBtn.Size = UDim2.fromOffset(96, 30)
                runBtn.Position = UDim2.new(1, -202, 0.5, -15)
                runBtn.BackgroundColor3 = Theme.ExecuteBtn
                runBtn.Text = "▶ EXECUTE"
                runBtn.Font = Enum.Font.GothamBold
                runBtn.TextSize = 11
                runBtn.TextColor3 = Theme.TextPrimary
                runBtn.AutoButtonColor = false
                runBtn.Parent = row
                Instance.new("UICorner", runBtn).CornerRadius = UDim.new(0, 6)
                runBtn.MouseButton1Click:Connect(function() ExecuteScript(scriptEntry.name, scriptEntry.status, scriptEntry.url) end)

                local delBtn = Instance.new("TextButton")
                delBtn.Size = UDim2.fromOffset(30, 30)
                delBtn.Position = UDim2.new(1, -104, 0.5, -15)
                delBtn.BackgroundColor3 = Theme.CardBg
                delBtn.Text = "✕"
                delBtn.Font = Enum.Font.GothamBold
                delBtn.TextSize = 12
                delBtn.TextColor3 = Theme.TextSecondary
                delBtn.AutoButtonColor = false
                delBtn.Parent = row
                Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 6)
                delBtn.MouseButton1Click:Connect(function()
                    local fKeyId = scriptEntry.name .. "|" .. scriptEntry.url
                    FavoriteList[fKeyId] = nil
                    SaveData()
                    RefreshFavoritesData()
                    Categories[2].scripts = FavoriteScriptsData
                    RenderContent(categoryIndex)
                end)
            end
        end
        ScriptScroll.CanvasPosition = Vector2.new(0, 0)
        return

    -- [ SETTINGS TAB ]
    elseif category.type == "settings" then
        FilterContainer.Visible = false
        SearchBox.Visible = false
        AddScriptBtn.Visible = false
        ContentLabel.Text = "Settings"

        local ListLayout = Instance.new("UIListLayout")
        ListLayout.Padding = UDim.new(0, 8)
        ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ListLayout.Parent = ScriptScroll

        local settingCard = Instance.new("Frame")
        settingCard.Size = UDim2.new(1, 0, 0, 50)
        settingCard.BackgroundColor3 = Theme.CardBg
        settingCard.LayoutOrder = 1
        settingCard.Parent = ScriptScroll
        Instance.new("UICorner", settingCard).CornerRadius = UDim.new(0, 8)

        local settingText = Instance.new("TextLabel")
        settingText.Font = Enum.Font.GothamBold
        settingText.TextSize = 12
        settingText.TextColor3 = Theme.TextPrimary
        settingText.BackgroundTransparency = 1
        settingText.Size = UDim2.new(1, -20, 1, 0)
        settingText.Position = UDim2.new(0, 12, 0, 0)
        settingText.TextXAlignment = Enum.TextXAlignment.Left
        settingText.Text = "️ Settings - Coming Soon"
        settingText.Parent = settingCard

        ScriptScroll.CanvasPosition = Vector2.new(0, 0)
        return
    end

    -- [ DEFAULT SCRIPT LIST TAB ]
    FilterContainer.Visible = true
    SearchBox.Visible = true
    AddScriptBtn.Visible = true

    local ListLayout = Instance.new("UIListLayout")
    ListLayout.Padding = UDim.new(0, 8)
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Parent = ScriptScroll

    local searchText = string.lower(SearchBox.Text)
    local filteredScripts = {}

    for _, scriptEntry in ipairs(category.scripts) do
        local matchesFilter = false
        if activeFilter == "ALL" then matchesFilter = true
        elseif activeFilter == "Key" then matchesFilter = (scriptEntry.status == "Key")
        elseif activeFilter == "No Key" then matchesFilter = (scriptEntry.status == "No Key")
        elseif activeFilter == "Recommended" then matchesFilter = (scriptEntry.recommended == true)
        end

        local matchesSearch = (searchText == "") or (string.find(string.lower(scriptEntry.name), searchText, 1, true) ~= nil)

        if matchesFilter and matchesSearch then table.insert(filteredScripts, scriptEntry) end
    end

    local filterTag = ""
    if activeFilter == "Key" then filterTag = " KEY"
    elseif activeFilter == "No Key" then filterTag = " NO KEY"
    elseif activeFilter == "Recommended" then filterTag = " RECOMMENDED" end
    ContentLabel.Text = string.upper(category.name) .. " -- " .. #filteredScripts .. filterTag .. " SCRIPTS"

    if #filteredScripts == 0 then
        local empty = Instance.new("TextLabel")
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 12
        empty.TextColor3 = Theme.TextMuted
        empty.BackgroundTransparency = 1
        empty.Size = UDim2.new(1, 0, 0, 50)
        empty.Text = "Tidak ada script yang cocok."
        empty.Parent = ScriptScroll
        return
    end

    for i, scriptEntry in ipairs(filteredScripts) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 56)
        row.BackgroundColor3 = Theme.CardBg
        row.LayoutOrder = i
        row.Parent = ScriptScroll
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

        local iconBg = Instance.new("Frame")
        iconBg.Size = UDim2.fromOffset(36, 36)
        iconBg.Position = UDim2.new(0, 12, 0.5, -18)
        iconBg.BackgroundColor3 = Theme.IconBg
        iconBg.Parent = row
        Instance.new("UICorner", iconBg).CornerRadius = UDim.new(1, 0)
        local iconLbl = Instance.new("TextLabel")
        iconLbl.Size = UDim2.new(1, 0, 1, 0)
        iconLbl.BackgroundTransparency = 1
        iconLbl.Font = Enum.Font.GothamBold
        iconLbl.TextSize = 18
        iconLbl.Text = IconMap[GetRowIcon(i)] or "🥚"
        iconLbl.TextColor3 = Theme.TextPrimary
        iconLbl.Parent = iconBg

        local nameLabel5 = Instance.new("TextLabel")
        nameLabel5.Font = Enum.Font.GothamBold
        nameLabel5.TextSize = 13
        nameLabel5.TextColor3 = Theme.TextPrimary
        nameLabel5.BackgroundTransparency = 1
        nameLabel5.Size = UDim2.new(1, -320, 0, 18)
        nameLabel5.Position = UDim2.new(0, 56, 0, 8)
        nameLabel5.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel5.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel5.Text = scriptEntry.name
        nameLabel5.Parent = row

        local descLabel3 = Instance.new("TextLabel")
        descLabel3.Font = Enum.Font.Gotham
        descLabel3.TextSize = 10
        descLabel3.TextColor3 = Theme.TextMuted
        descLabel3.BackgroundTransparency = 1
        descLabel3.Size = UDim2.new(1, -320, 0, 14)
        descLabel3.Position = UDim2.new(0, 56, 0, 28)
        descLabel3.TextXAlignment = Enum.TextXAlignment.Left
        descLabel3.TextTruncate = Enum.TextTruncate.AtEnd
        descLabel3.Text = "Auto ambil egg + tele + drop + ulang."
        descLabel3.Parent = row

        local statusBadge = Instance.new("TextLabel")
        statusBadge.Size = UDim2.fromOffset(60, 22)
        statusBadge.Position = UDim2.new(1, -240, 0.5, -11)
        statusBadge.BackgroundColor3 = (scriptEntry.status == "Key") and Theme.KeyTagBg or Theme.NoKeyTagBg
        statusBadge.Text = scriptEntry.status
        statusBadge.Font = Enum.Font.GothamBold
        statusBadge.TextSize = 10
        statusBadge.TextColor3 = Theme.TextPrimary
        statusBadge.Parent = row
        Instance.new("UICorner", statusBadge).CornerRadius = UDim.new(0, 4)

        local favBtn = Instance.new("TextButton")
        favBtn.Size = UDim2.fromOffset(30, 30)
        favBtn.Position = UDim2.new(1, -198, 0.5, -15)
        favBtn.BackgroundColor3 = Theme.CardBg
        local fKeyId = scriptEntry.name .. "|" .. scriptEntry.url
        favBtn.Text = FavoriteList[fKeyId] and "★" or "☆"
        favBtn.Font = Enum.Font.GothamBold
        favBtn.TextSize = 15
        favBtn.TextColor3 = FavoriteList[fKeyId] and Theme.GoldBadge or Theme.TextSecondary
        favBtn.AutoButtonColor = false
        favBtn.Parent = row
        Instance.new("UICorner", favBtn).CornerRadius = UDim.new(0, 6)
        favBtn.MouseButton1Click:Connect(function()
            if FavoriteList[fKeyId] then FavoriteList[fKeyId] = nil; favBtn.Text = "☆"; favBtn.TextColor3 = Theme.TextSecondary
            else FavoriteList[fKeyId] = true; favBtn.Text = "★"; favBtn.TextColor3 = Theme.GoldBadge end
            SaveData(); RefreshFavoritesData(); Categories[2].scripts = FavoriteScriptsData
        end)

        local runBtn = Instance.new("TextButton")
        runBtn.Size = UDim2.fromOffset(96, 30)
        runBtn.Position = UDim2.new(1, -160, 0.5, -15)
        runBtn.BackgroundColor3 = Theme.ExecuteBtn
        runBtn.Text = "▶ EXECUTE"
        runBtn.Font = Enum.Font.GothamBold
        runBtn.TextSize = 11
        runBtn.TextColor3 = Theme.TextPrimary
        runBtn.AutoButtonColor = false
        runBtn.Parent = row
        Instance.new("UICorner", runBtn).CornerRadius = UDim.new(0, 6)
        runBtn.MouseEnter:Connect(function() TweenService:Create(runBtn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.AccentIndigo }):Play() end)
        runBtn.MouseLeave:Connect(function() TweenService:Create(runBtn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.ExecuteBtn }):Play() end)
        runBtn.MouseButton1Click:Connect(function() ExecuteScript(scriptEntry.name, scriptEntry.status, scriptEntry.url) end)

        local copyBtn = Instance.new("TextButton")
        copyBtn.Size = UDim2.fromOffset(30, 30)
        copyBtn.Position = UDim2.new(1, -104, 0.5, -15)
        copyBtn.BackgroundColor3 = Theme.CardBg
        copyBtn.Text = "📋"
        copyBtn.Font = Enum.Font.GothamBold
        copyBtn.TextSize = 13
        copyBtn.TextColor3 = Theme.TextSecondary
        copyBtn.AutoButtonColor = false
        copyBtn.Parent = row
        Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 6)
        copyBtn.MouseButton1Click:Connect(function()
            if setclipboard then setclipboard(scriptEntry.url) end
            copyBtn.TextColor3 = Theme.AccentIndigo
            task.delay(1, function() if copyBtn then copyBtn.TextColor3 = Theme.TextSecondary end end)
        end)
    end

    ScriptScroll.CanvasPosition = Vector2.new(0, 0)
end

-- [ FILTER TABS ]
local filterDefs = {
    { id = "ALL", text = "All" },
    { id = "Key", text = "Key" },
    { id = "No Key", text = "No Key" },
    { id = "Recommended", text = "Recommended" }
}

for _, fDef in ipairs(filterDefs) do
    local fBtn = Instance.new("TextButton")
    fBtn.Size = UDim2.fromOffset(80, 26)
    fBtn.BackgroundColor3 = (activeFilter == fDef.id) and Theme.AccentIndigo or Theme.CardBg
    fBtn.Text = fDef.text
    fBtn.Font = Enum.Font.GothamBold
    fBtn.TextSize = 11
    fBtn.TextColor3 = (activeFilter == fDef.id) and Theme.TextPrimary or Theme.TextSecondary
    fBtn.AutoButtonColor = false
    fBtn.Parent = FilterContainer
    Instance.new("UICorner", fBtn).CornerRadius = UDim.new(0, 6)
    filterButtons[fDef.id] = fBtn

    fBtn.MouseButton1Click:Connect(function()
        activeFilter = fDef.id
        for id, btn in pairs(filterButtons) do
            local isActive = (id == activeFilter)
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = isActive and Theme.AccentIndigo or Theme.CardBg,
                TextColor3 = isActive and Theme.TextPrimary or Theme.TextSecondary
            }):Play()
        end
        RenderContent(activeCategoryIndex)
    end)
end

SearchBox:GetPropertyChangedSignal("Text"):Connect(function() RenderContent(activeCategoryIndex) end)

-- [ SIDEBAR TABS ]
local sidebarTabButtons = {}

local function SetActiveCategory(index)
    activeCategoryIndex = index
    RefreshFavoritesData()
    Categories[2].scripts = FavoriteScriptsData

    for i, btnData in ipairs(sidebarTabButtons) do
        local isActive = (i == index)
        TweenService:Create(btnData.frame, TweenInfo.new(0.15), {
            BackgroundColor3 = isActive and Theme.AccentIndigo or Theme.CardBg
        }):Play()
        btnData.label.TextColor3 = isActive and Theme.TextPrimary or Theme.TextSecondary
        btnData.icon.TextColor3 = isActive and Theme.TextPrimary or Theme.TextSecondary

        if isActive and Categories[i].hasNotification then
            Categories[i].hasNotification = false
            if btnData.notifBadge then
                TweenService:Create(btnData.notifBadge, TweenInfo.new(0.15), { Size = UDim2.fromOffset(0, 0) }):Play()
                task.delay(0.15, function() if btnData.notifBadge then btnData.notifBadge:Destroy() end end)
            end
        end
    end
    RenderContent(index)
end

RenderSidebarTabs = function()
    for _, child in ipairs(Sidebar:GetChildren()) do
        if not child:IsA("UIListLayout") then child:Destroy() end
    end
    sidebarTabButtons = {}

    local iconTexts = {
        egg = "", star = "⭐", clock = "", plus = "➕",
        info = "ℹ️", bell = "", settings = "⚙️"
    }

    for i, category in ipairs(Categories) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, -16, 0, 38)
        tabBtn.BackgroundColor3 = (i == activeCategoryIndex) and Theme.AccentIndigo or Theme.CardBg
        tabBtn.Text = ""
        tabBtn.AutoButtonColor = false
        tabBtn.LayoutOrder = i
        tabBtn.Parent = Sidebar
        Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 8)

        local iconLabel = Instance.new("TextLabel")
        iconLabel.Font = Enum.Font.GothamBold
        iconLabel.TextSize = 15
        iconLabel.TextColor3 = (i == activeCategoryIndex) and Theme.TextPrimary or Theme.TextSecondary
        iconLabel.BackgroundTransparency = 1
        iconLabel.Size = UDim2.fromOffset(22, 22)
        iconLabel.Position = UDim2.new(0, 10, 0.5, -11)
        iconLabel.TextXAlignment = Enum.TextXAlignment.Center
        iconLabel.Text = iconTexts[category.icon] or "️"
        iconLabel.Parent = tabBtn

        local label = Instance.new("TextLabel")
        label.Font = Enum.Font.GothamBold
        label.TextSize = 11
        label.TextColor3 = (i == activeCategoryIndex) and Theme.TextPrimary or Theme.TextSecondary
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, -44, 1, 0)
        label.Position = UDim2.new(0, 38, 0, 0)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextWrapped = true
        label.Text = category.name
        label.Parent = tabBtn

        local notifBadge = nil
        if category.hasNotification then
            notifBadge = Instance.new("Frame")
            notifBadge.Size = UDim2.fromOffset(7, 7)
            notifBadge.AnchorPoint = Vector2.new(1, 0.5)
            notifBadge.Position = UDim2.new(1, -8, 0.5, 0)
            notifBadge.BackgroundColor3 = Theme.DotRed
            notifBadge.BorderSizePixel = 0
            notifBadge.Parent = tabBtn
            Instance.new("UICorner", notifBadge).CornerRadius = UDim.new(1, 0)
        end

        table.insert(sidebarTabButtons, { frame = tabBtn, label = label, icon = iconLabel, notifBadge = notifBadge })

        tabBtn.MouseButton1Click:Connect(function() SetActiveCategory(i) end)
    end
end

RenderSidebarTabs()
RenderContent(activeCategoryIndex)

-- [ STATUS BAR ]
local StatusBar = Instance.new("Frame")
StatusBar.Size = UDim2.new(1, 0, 0, 22)
StatusBar.Position = UDim2.new(0, 0, 1, -22)
StatusBar.BackgroundTransparency = 1
StatusBar.Parent = MainFrame

local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.fromOffset(8, 8)
StatusDot.Position = UDim2.new(0, 14, 0.5, -4)
StatusDot.BackgroundColor3 = Theme.DotGreen
StatusDot.BorderSizePixel = 0
StatusDot.Parent = StatusBar
Instance.new("UICorner", StatusDot).CornerRadius = UDim.new(1, 0)

local StatusText = Instance.new("TextLabel")
StatusText.Font = Enum.Font.Gotham
StatusText.TextSize = 10
StatusText.TextColor3 = Theme.TextSecondary
StatusText.BackgroundTransparency = 1
StatusText.Size = UDim2.new(0, 60, 1, 0)
StatusText.Position = UDim2.new(0, 28, 0, 0)
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.Text = "Ready"
StatusText.Parent = StatusBar

-- [ DRAG SYSTEM ]
local isDragging = false
local dragStartPos = Vector3.new()
local startFramePos = UDim2.new()
local currentDragInput = nil

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStartPos = input.Position
        startFramePos = MainFrame.Position
        currentDragInput = input
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input == currentDragInput or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
        currentDragInput = nil
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input == currentDragInput or input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStartPos
        MainFrame.Position = UDim2.new(
            startFramePos.X.Scale, startFramePos.X.Offset + delta.X,
            startFramePos.Y.Scale, startFramePos.Y.Offset + delta.Y
        )
    end
end)

-- [ RESIZE ]
local ResizeHandle = Instance.new("TextButton")
ResizeHandle.Size = UDim2.fromOffset(18, 18)
ResizeHandle.AnchorPoint = Vector2.new(1, 1)
ResizeHandle.Position = UDim2.new(1, 0, 1, 0)
ResizeHandle.BackgroundColor3 = Theme.AccentIndigo
ResizeHandle.Text = "◢"
ResizeHandle.Font = Enum.Font.GothamBold
ResizeHandle.TextSize = 9
ResizeHandle.TextColor3 = Theme.TextPrimary
ResizeHandle.AutoButtonColor = false
ResizeHandle.Parent = MainFrame
Instance.new("UICorner", ResizeHandle).CornerRadius = UDim.new(0, 4)

local isResizing = false
local resizeStartPos = Vector3.new()
local startSize = UDim2.new()

ResizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isResizing = true
        resizeStartPos = input.Position
        startSize = MainFrame.Size
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isResizing = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isResizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - resizeStartPos
        local newWidth = math.clamp(startSize.X.Offset + delta.X, 720, 1000)
        local newHeight = math.clamp(startSize.Y.Offset + delta.Y, 440, 700)
        MainFrame.Size = UDim2.fromOffset(newWidth, newHeight)
    end
end)

-- [ FLOATING BUTTON ]
local FloatingBtn = Instance.new("TextButton")
FloatingBtn.Size = UDim2.fromOffset(50, 50)
FloatingBtn.AnchorPoint = Vector2.new(0, 0.5)
FloatingBtn.Position = UDim2.new(0, 20, 0.4, 0)
FloatingBtn.BackgroundColor3 = Theme.Background
FloatingBtn.BorderSizePixel = 0
FloatingBtn.Visible = false
FloatingBtn.Active = true
FloatingBtn.Text = ""
FloatingBtn.Parent = ScreenGui
Instance.new("UICorner", FloatingBtn).CornerRadius = UDim.new(0, 12)
local FloatingStroke = Instance.new("UIStroke")
FloatingStroke.Color = Theme.AccentIndigo
FloatingStroke.Thickness = 2
FloatingStroke.Parent = FloatingBtn

local FloatingLogo = CreateFLogo(UDim2.fromOffset(26, 26), -12)
FloatingLogo.Position = UDim2.new(0.5, -13, 0.5, -13)
FloatingLogo.Parent = FloatingBtn

local FloatingScale = Instance.new("UIScale")
FloatingScale.Scale = 1
FloatingScale.Parent = FloatingBtn

local floatDragging = false
local floatDragStart = Vector3.new()
local floatStartPos = UDim2.new()
local floatInputObj = nil

FloatingBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        floatDragging = true
        floatDragStart = input.Position
        floatStartPos = FloatingBtn.Position
        floatInputObj = input
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input == floatInputObj or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        floatDragging = false
        floatInputObj = nil
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if floatDragging and (input == floatInputObj or input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - floatDragStart
        FloatingBtn.Position = UDim2.new(
            floatStartPos.X.Scale, floatStartPos.X.Offset + delta.X,
            floatStartPos.Y.Scale, floatStartPos.Y.Offset + delta.Y
        )
    end
end)

local function ToggleMainUI(show)
    if show then
        MainFrame.Size = UDim2.fromOffset(820, 500)
        MainFrame.Visible = true
        MainScale.Scale = 0
        TweenService:Create(FloatingScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0 }):Play()
        TweenService:Create(MainScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
        task.delay(0.12, function() FloatingBtn.Visible = false end)
    else
        TweenService:Create(MainScale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0 }):Play()
        task.delay(0.16, function()
            MainFrame.Visible = false
            FloatingBtn.Visible = true
            FloatingScale.Scale = 0
            TweenService:Create(FloatingScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
        end)
    end
end

FloatingBtn.MouseButton1Click:Connect(function() ToggleMainUI(true) end)

local isMinimized = false

CreateHeaderButton("−", function()
    isMinimized = not isMinimized
    if isMinimized then
        TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(820, 56) }):Play()
    else
        TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(820, 500) }):Play()
    end
end)

CreateHeaderButton("×", function() ToggleMainUI(false) end)

-- [ BOOT SCREEN ]
local BootScreen = Instance.new("CanvasGroup")
BootScreen.Size = UDim2.fromOffset(300, 140)
BootScreen.AnchorPoint = Vector2.new(0.5, 0.5)
BootScreen.Position = UDim2.fromScale(0.5, 0.5)
BootScreen.BackgroundColor3 = Theme.Background
BootScreen.GroupTransparency = 0
BootScreen.ZIndex = 100
BootScreen.Parent = ScreenGui
Instance.new("UICorner", BootScreen).CornerRadius = UDim.new(0, 10)
local BootStroke = Instance.new("UIStroke")
BootStroke.Color = Theme.BorderColor
BootStroke.Thickness = 1
BootStroke.Parent = BootScreen

local BootLogo = CreateFLogo(UDim2.new(0, 36, 0, 36), -12)
BootLogo.Position = UDim2.new(0.5, -18, 0, 20)
BootLogo.Parent = BootScreen

local BootTitle = Instance.new("TextLabel")
BootTitle.Font = Enum.Font.GothamBold
BootTitle.TextSize = 18
BootTitle.TextColor3 = Theme.TextPrimary
BootTitle.BackgroundTransparency = 1
BootTitle.Size = UDim2.new(1, -20, 0, 24)
BootTitle.Position = UDim2.new(0, 10, 0, 64)
BootTitle.RichText = true
BootTitle.Text = "leon4951 <font color=\"rgb(99, 102, 241)\">Hub</font>"
BootTitle.Parent = BootScreen

local BootSubText = Instance.new("TextLabel")
BootSubText.Font = Enum.Font.Gotham
BootSubText.TextSize = 11
BootSubText.TextColor3 = Theme.TextSecondary
BootSubText.BackgroundTransparency = 1
BootSubText.Size = UDim2.new(1, -20, 0, 16)
BootSubText.Position = UDim2.new(0, 10, 0, 90)
BootSubText.Text = "Loading..."
BootSubText.Parent = BootScreen

local BootTrack = Instance.new("Frame")
BootTrack.Size = UDim2.new(1, -40, 0, 5)
BootTrack.Position = UDim2.new(0, 20, 1, -30)
BootTrack.BackgroundColor3 = Theme.CardBg
BootTrack.BorderSizePixel = 0
BootTrack.Parent = BootScreen
Instance.new("UICorner", BootTrack).CornerRadius = UDim.new(1, 0)

local BootFill = Instance.new("Frame")
BootFill.Size = UDim2.new(0, 0, 1, 0)
BootFill.BackgroundColor3 = Theme.AccentIndigo
BootFill.BorderSizePixel = 0
BootFill.Parent = BootTrack
Instance.new("UICorner", BootFill).CornerRadius = UDim.new(1, 0)

local BootPercentLabel = Instance.new("TextLabel")
BootPercentLabel.Font = Enum.Font.GothamBold
BootPercentLabel.TextSize = 11
BootPercentLabel.TextColor3 = Theme.TextPrimary
BootPercentLabel.BackgroundTransparency = 1
BootPercentLabel.TextXAlignment = Enum.TextXAlignment.Center
BootPercentLabel.Size = UDim2.new(1, 0, 0, 16)
BootPercentLabel.Position = UDim2.new(0, 0, 1, -48)
BootPercentLabel.Text = "0%"
BootPercentLabel.Parent = BootScreen

local BootStatuses = {
    { 0.00, "Initializing..." },
    { 0.20, "Loading UI Components..." },
    { 0.40, "Filtering Script Database..." },
    { 0.65, "Preparing Categories..." },
    { 0.85, "Finalizing UI..." },
}

local bootDuration = 2.0
local bootStartTime = os.clock()
local bootConn

bootConn = RunService.Heartbeat:Connect(function()
    local elapsed = os.clock() - bootStartTime
    local pct = math.clamp(elapsed / bootDuration, 0, 1)
    BootFill.Size = UDim2.new(pct, 0, 1, 0)
    BootPercentLabel.Text = math.floor(pct * 100) .. "%"
    for _, status in ipairs(BootStatuses) do
        if pct >= status[1] then BootSubText.Text = status[2] end
    end
    if pct >= 1 then
        bootConn:Disconnect()
        bootConn = nil
        BootSubText.Text = "✓ Ready"
        task.spawn(function()
            task.wait(0.4)
            TweenService:Create(BootScreen, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { GroupTransparency = 1 }):Play()
            task.delay(0.25, function()
                BootScreen:Destroy()
                MainFrame.Visible = true
                MainScale.Scale = 0
                TweenService:Create(MainScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
            end)
        end)
    end
end)