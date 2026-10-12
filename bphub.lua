if not game:IsLoaded() then
    game.Loaded:Wait()
end
function LPH_NO_VIRTUALIZE(callback)
    return callback
end

local BPUI_LIB = loadstring(game:HttpGet("https://raw.githubusercontent.com/bypasshubpremium/BPUINEW/main/BPUI.lua"))()

local function makeCfg(name, defaults)
    local hs = game:GetService("HttpService")
    local folder = "BPHUB"
    local path = folder .. "/" .. name .. ".json"
    local function deepCopy(t)
        if type(t) ~= "table" then
            return t
        end
        local o = {}
        for k, v in pairs(t) do
            o[k] = deepCopy(v)
        end
        return o
    end
    local function fill(dst, src)
        for k in pairs(dst) do
            dst[k] = nil
        end
        for k, v in pairs(src) do
            dst[k] = deepCopy(v)
        end
    end
    local function merge(dst, src)
        for k, v in pairs(src) do
            local d = dst[k]
            if type(d) == "table" and type(v) == "table" then
                if next(d) == nil or d[1] ~= nil then
                    fill(d, v)
                else
                    merge(d, v)
                end
            elseif d == nil or type(d) == type(v) then
                dst[k] = deepCopy(v)
            end
        end
    end
    local function assign(dst, src)
        for k in pairs(dst) do
            if src[k] == nil then
                dst[k] = nil
            end
        end
        for k, v in pairs(src) do
            local d = dst[k]
            if type(d) == "table" and type(v) == "table" then
                if next(v) ~= nil and v[1] == nil then
                    assign(d, v)
                else
                    fill(d, v)
                end
            else
                dst[k] = deepCopy(v)
            end
        end
    end
    local function profilePath(p)
        return folder .. "/" .. name .. "_profile_" .. p .. ".json"
    end
    local data = deepCopy(defaults)
    pcall(function()
        if readfile and (not isfile or isfile(path)) then
            local saved = hs:JSONDecode(readfile(path))
            if type(saved) == "table" then
                merge(data, saved)
            end
        end
    end)
    local function write()
        pcall(function()
            if writefile then
                if isfolder and not isfolder(folder) then
                    makefolder(folder)
                end
                writefile(path, hs:JSONEncode(data))
            end
        end)
    end
    local lastChange, pending = 0, false
    return {
        data = data,
        save = function()
            lastChange = os.clock()
            if pending then
                return
            end
            pending = true
            task.spawn(function()
                repeat
                    task.wait(0.5)
                until os.clock() - lastChange >= 0.5
                pending = false
                write()
            end)
        end,
        flush = write,
        saveAs = function(p)
            if not writefile then
                return false, "this executor cannot write files"
            end
            return pcall(function()
                if isfolder and not isfolder(folder) then
                    makefolder(folder)
                end
                writefile(profilePath(p), hs:JSONEncode(data))
            end)
        end,
        loadFrom = function(p)
            if not readfile then
                return false, "this executor cannot read files"
            end
            local ok, err = pcall(function()
                local saved = hs:JSONDecode(readfile(profilePath(p)))
                if type(saved) ~= "table" then
                    error("the profile file is not valid")
                end
                assign(data, defaults)
                merge(data, saved)
            end)
            if ok then
                write()
            end
            return ok, err
        end,
        reset = function()
            assign(data, defaults)
            write()
        end,
        profiles = function()
            local out = {}
            pcall(function()
                for _, f in ipairs(listfiles(folder)) do
                    local p = tostring(f):match(name .. "_profile_(.+)%.json$")
                    if p then
                        out[#out + 1] = p
                    end
                end
            end)
            table.sort(out)
            return out
        end,
        delete = function(p)
            if not delfile then
                return false, "this executor cannot delete files"
            end
            return pcall(delfile, profilePath(p))
        end,
    }
end

local H = {
    gs = function(n)
        return game:GetService(n)
    end,
    hum = function(p)
        local c = p and p.Character
        return c and c:FindFirstChildOfClass("Humanoid")
    end,
    cfg = makeCfg,
    task = function(fn, interval, initial_delay)
        local stopped = false
        task.spawn(function()
            if initial_delay and initial_delay > 0 then
                task.wait(initial_delay)
            end
            while not stopped do
                pcall(fn)
                if stopped or not interval or interval <= 0 then
                    break
                end
                task.wait(interval)
            end
        end)
        return {
            stop = function()
                stopped = true
            end,
        }
    end,
}

do
    local services = {}
    H.gs = function(name)
        local service = services[name]
        if not service then
            service = game:GetService(name)
            services[name] = service
        end
        return service
    end
end

H.ui = BPUI_LIB
H.numberUnits = { { 1e15, "Q" }, { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }

do
    local _orig = BPUI_LIB.Notify
    BPUI_LIB.Notify = function(self, ...)
        local args = table.pack(...)
        task.spawn(function()
            pcall(_orig, self, table.unpack(args, 1, args.n))
        end)
    end
end

local win
local BPUI = H.ui
local lp = H.gs("Players").LocalPlayer
local rep = H.gs("ReplicatedStorage")
local rs = H.gs("RunService")

local EggState, PlotState, Assets, GuardCfgs, Remotes, Save, EggRecords, AssetEarnings, SlotIdentity
pcall(function()
    EggState = require(rep.Client.EggState)
end)
pcall(function()
    PlotState = require(rep.Client.PlotState)
end)
pcall(function()
    Assets = require(rep.Data.Assets)
end)
pcall(function()
    GuardCfgs = require(rep.Data.Guards)
end)
pcall(function()
    Remotes = require(rep.Shared.Remotes)
end)
pcall(function()
    Save = require(rep.Shared.Save)
end)
pcall(function()
    EggRecords = require(rep.Shared.Util.EggRecords)
end)
pcall(function()
    AssetEarnings = require(rep.Shared.Util.AssetEarnings)
end)
pcall(function()
    SlotIdentity = require(rep.Shared.Util.AreaEggSlotIdentity)
end)
local TreadmillUtil, SpeedPowerProjection
pcall(function()
    TreadmillUtil = require(rep.Shared.Util.TreadmillUtil)
end)
pcall(function()
    SpeedPowerProjection = require(rep.Client.SpeedPowerProjection)
end)

local NET
pcall(function()
    NET = rep.Packages.Networking
end)
local UIS = H.gs("UserInputService")

local C = H.cfg("stealanegg", {
    steal = {
        maxSteals = 0,
        notify = true,
        highlight = true,
        relay = false,
        trainIdle = true,
        travel = "Walk",
        returnSpeed = "Max",
        notifyFail = true,
        onCancel = "Drop Egg",
    },
    mults = {},
    train = { on = false },
    keys = { best = "F6", cancel = "F7", safe = "F4", safeMoved = false },
    misc = {
        antiAfk = true,
        hopMode = "Random",
        autoRejoin = false,
        autoLoad = false,
        scriptFile = "stealanegg.lua",
        fpsCap = 0,
        no3d = false,
    },
    auto = {
        place = false,
        hatch = false,
        sellEggs = false,
        sellPets = false,
        equip = false,
        favorite = false,
        upgradeBase = false,
        upgradeTreadmill = false,
        bossShop = false,
        fuse = false,
        claimIndex = false,
        rift = false,
        riftReroll = false,
        mastery = false,
        trail = false,
        lvdTeam = false,
        lvdClaim = false,
    },
    trail = { keep = 0 },
    hook = { url = "", rare = false, minRarity = "", steal = false },
    sell = {
        limit = 0,
        eggLimit = 0,
        petLimit = 0,
        keepMutated = true,
        keepRarity = "",
        keepRift = true,
        eggRule = "Value",
        petRule = "Value",
        neverCats = {},
        keepIndex = true,
        keepMatch = "",
    },
    hatch = { minRarity = "", minValue = 0, specific = {}, mutMode = "Any", match = "", rift = false },
    place = { minRarity = "", order = "Highest Value", minValue = 0, cats = {}, rift = false },
    fav = {
        minRarity = "",
        minValue = 0,
        rule = "Rarity And Value",
        muts = {},
        species = {},
        match = "",
        equipped = false,
        unfavEquipped = false,
    },
    esp = {
        eggs = false,
        guards = false,
        range = 30000,
        players = false,
        useFilter = true,
        traps = false,
        appearance = {
            textSize = 11,
            width = 230,
            offset = 0,
            font = "GothamBold",
            backgroundTransparency = 0.25,
            outlineTransparency = 0.65,
            alwaysOnTop = true,
            showDistance = true,
            showArea = true,
            showRarity = true,
            showRate = true,
            showDetails = true,
            displayNames = true,
            statusColors = true,
            maxLabels = 80,
            scanInterval = 0.25,
            renderInterval = 0,
            colors = {
                background = "0C0E14",
                egg = "54E0FF",
                guard = "FFAA3C",
                trap = "FF78DC",
                player = "FFC850",
                safe = "6EFF8C",
                warning = "FFD250",
                danger = "FF5F5F",
            },
        },
    },
    player = {
        noclip = false,
        infjump = false,
        antiRagdoll = false,
        instantPrompts = false,
        invisible = false,
        antiTrap = false,
    },
    fuse = {
        keepBest = 1,
        includeEquipped = false,
        skipMutated = true,
        maxRarity = "",
        priority = "Lowest Value First",
        ejectPartial = true,
    },
    rift = { skipMutated = true },
    boss = { autoEnter = false, shopItems = {}, keepTokens = 0 },
    events = { lvd = false, scramble = false, sammy = false, lvdMode = "All", lvdTeam = "Random" },
    farm = { awayAuto = false },
    ui = { closed = {}, animations = true },
    filter = {
        minRate = 0,
        maxRate = 0,
        maxDist = 0,
        areas = {},
        cats = {},
        rarities = {},
        muts = {},
        onlyMutated = false,
        noMutation = false,
        sortBy = "Highest Rate",
        deliverableOnly = true,
        showAll = false,
        riftOnly = false,
        indexMissing = false,
        includeDropped = false,
    },
})
local cfg = C.data

local conns = {}
local espWarn = false

local state = {
    running = false,
    mode = nil,
    token = 0,
    selectedUid = nil,
    rows = {},
    destroyed = false,
    phase = "Idle",
    noclipConn = nil,
    infJumpConn = nil,
    bossConn = nil,
    lvdConn = nil,
    scramConn = nil,
    sammyConn = nil,
    awayConn = nil,
    bossLbl = nil,
    playerESPConn = nil,
}
local Feat = {}
function Feat.ui(fn)
    task.spawn(pcall, fn)
end

function Feat.pruneConns()
    local count = #conns
    local writeIndex = 1
    for readIndex = 1, count do
        local connection = conns[readIndex]
        local ok, live = pcall(function()
            return connection.Connected
        end)
        if not ok or live ~= false then
            conns[writeIndex] = connection
            writeIndex += 1
        end
    end
    for i = writeIndex, count do
        conns[i] = nil
    end
end

local function getAreas()
    local root = workspace:FindFirstChild("__OBJECTS") or workspace:FindFirstChild("World")
    return root and root:FindFirstChild("Areas")
end

local GuardEscapeRequirement, GuardEscapePrediction, AreaEggCycle, TreadmillsData
pcall(function()
    GuardEscapeRequirement = require(rep.Shared.Modules.GuardAreas.GuardEscapeRequirement)
end)
pcall(function()
    GuardEscapePrediction = require(rep.Shared.Modules.GuardAreas.GuardEscapePrediction)
end)
pcall(function()
    AreaEggCycle = require(rep.Shared.Util.AreaEggCycle)
end)
pcall(function()
    TreadmillsData = require(rep.Data.Treadmills)
end)

Feat.RARITY_RANKS = {
    Common = 1,
    Uncommon = 2,
    Rare = 3,
    Epic = 4,
    Legendary = 5,
    Mythic = 6,
    Cosmic = 7,
    Secret = 8,
    Eternal = 9,
    Divine = 10,
}
pcall(function()
    for _, d in pairs(Assets.Directory) do
        local r = type(d) == "table" and d.Rarity
        if type(r) == "table" and type(r.Rank) == "number" then
            if type(r.DisplayName) == "string" then
                Feat.RARITY_RANKS[r.DisplayName] = r.Rank
            end
            if type(r._id) == "string" then
                Feat.RARITY_RANKS[r._id] = r.Rank
            end
        end
    end
end)
Feat.RARITY_OPTS_ALL =
    { "Any", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Cosmic", "Secret", "Eternal", "Divine" }

local function shortNum(n)
    n = tonumber(n) or 0
    for _, u in ipairs(H.numberUnits) do
        if n >= u[1] then
            return string.format("%.2f%s", n / u[1], u[2])
        end
    end
    return tostring(math.floor(n))
end

function Feat.parseAmount(s)
    s = tostring(s or ""):gsub("[%s,%$]", ""):upper()
    if s == "" then
        return 0
    end
    local num, suf = s:match("^([%d%.]+)([KMBTQ]?)$")
    local n = tonumber(num)
    if not n then
        return nil
    end
    local mult = ({ K = 1e3, M = 1e6, B = 1e9, T = 1e12, Q = 1e15 })[suf] or 1
    return mult > 1 and math.floor(n * mult + 0.5) or n
end

function Feat.fmtAmount(n)
    n = tonumber(n) or 0
    local s = shortNum(n)
    if Feat.parseAmount(s) == n then
        return s
    end
    return n == math.floor(n) and string.format("%.0f", n) or tostring(n)
end

local function fmtDuration(sec)
    sec = math.max(0, math.floor(tonumber(sec) or 0))
    if sec >= 3600 then
        return string.format("%dh %02dm", sec // 3600, (sec % 3600) // 60)
    end
    if sec >= 60 then
        return string.format("%dm %02ds", sec // 60, sec % 60)
    end
    return sec .. "s"
end

local function charParts()
    local chr = lp.Character
    if not chr then
        return nil, nil, nil
    end
    local root = chr:FindFirstChild("HumanoidRootPart")
    local hum = chr:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then
        return nil, nil, nil
    end
    return chr, root, hum
end

local function active(token)
    return state.running and state.token == token and not state.destroyed
end

state.log = {}
local function logRun(msg)
    table.insert(state.log, 1, os.date("%H:%M:%S") .. "  " .. tostring(msg))
    while #state.log > 60 do
        table.remove(state.log)
    end
    if state.onLog then
        pcall(state.onLog)
    end
end

local function setStatus(txt)
    state.phase = txt
    local lbl = state.statusLabel
    if lbl then
        Feat.ui(function()
            lbl:Set(txt)
        end)
    end
end

local function fieldRecord(uid)
    if not uid or not EggState then
        return nil
    end
    local ok, rec = pcall(EggState.ReadFieldEgg, uid)
    return ok and rec or nil
end

local function eggPosition(record)
    if not record then
        return nil
    end
    local recPos = (record.BoundsCFrame and record.BoundsCFrame.Position)
        or (record.BottomCFrame and record.BottomCFrame.Position)
    local folder = workspace:FindFirstChild("AreaEggSlotsClient")
    local model = folder and folder:FindFirstChild(record.Uid)
    local hitbox = model and model:FindFirstChild("Hitbox")
    if hitbox and hitbox:IsA("BasePart") and (not recPos or (hitbox.Position - recPos).Magnitude <= 20) then
        return hitbox.Position
    end
    return recPos
end

local function isAvailable(rec)
    return rec ~= nil and (rec.State == "Slot" or rec.State == "Dropped")
end

local function separationLine()
    local a = getAreas()
    return a and a:FindFirstChild("SeparationLine")
end

local function guardArea(areaId)
    local a = getAreas()
    local ga = a and a:FindFirstChild("GuardAreas")
    return ga and ga:FindFirstChild(areaId)
end

local function guardRootOf(areaId)
    local area = guardArea(areaId)
    local g = area and area:FindFirstChild("Guard")
    return g and g:FindFirstChild("HumanoidRootPart"), g
end

local function guardStateOf(areaId)
    local _, g = guardRootOf(areaId)
    return g and g:GetAttribute("GuardState")
end

local function guardBaseSpeed(areaId)
    local sp
    pcall(function()
        local Areas = require(rep.Data.Areas)
        local a = Areas.Directory[areaId]
        local gc = a and GuardCfgs.Directory[a.GuardId]
        sp = gc and tonumber(gc.WalkSpeed)
    end)
    return sp
end

local function guardLiveSpeed(areaId)
    local base = guardBaseSpeed(areaId) or 0
    local _, g = guardRootOf(areaId)
    local gh = g and g:FindFirstChildOfClass("Humanoid")
    local ws = gh and tonumber(gh.WalkSpeed) or 0
    return math.max(ws, base), base
end

local function xz(a, b)
    return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function chasingGuards(root)
    local out = {}
    local a = getAreas()
    local ga = a and a:FindFirstChild("GuardAreas")
    if not ga or not root then
        return out
    end
    local me = tostring(lp.UserId)
    for _, area in ipairs(ga:GetChildren()) do
        local g = area:FindFirstChild("Guard")
        local gr = g and g:FindFirstChild("HumanoidRootPart")
        if gr and g:GetAttribute("TargetPlayer") == me then
            out[#out + 1] =
                { area = area.Name, speed = (guardLiveSpeed(area.Name)), dist = xz(gr.Position, root.Position) }
        end
    end
    return out
end

local function boundsMinX(areaId)
    local area = guardArea(areaId)
    local b = area and area:FindFirstChild("Bounds")
    if not b then
        return nil
    end
    local half, minX = b.Size / 2, math.huge
    for _, sx in ipairs({ -1, 1 }) do
        for _, sz in ipairs({ -1, 1 }) do
            minX = math.min(minX, (b.CFrame * Vector3.new(sx * half.X, 0, sz * half.Z)).X)
        end
    end
    return minX
end

state.multByCat = type(cfg.mults) == "table" and cfg.mults or {}
cfg.mults = state.multByCat
local function powerWalkSpeed()
    local ws
    pcall(function()
        ws = TreadmillUtil.SpeedPowerToWalkSpeed(SpeedPowerProjection.ReadProjected())
    end)
    return (type(ws) == "number" and ws > 0) and ws or 16
end

local function baseWalkSpeed()
    local ws = powerWalkSpeed()
    local fw = state.freeWalk
    if fw and fw > ws and fw <= ws * 1.3 then
        ws = fw
    end
    return ws
end

local function multForEgg(rec)
    if state.carry and rec and state.carry.uid == rec.Uid and state.carry.mult then
        return state.carry.mult
    end
    return (rec and state.multByCat[rec.AssetCategory]) or 0.96
end

local function allowedCarrySpeed(mult)
    return baseWalkSpeed() * (mult or 0.96) * 0.985
end

local function speedPowerFor(ws)
    local ok, sp = pcall(TreadmillUtil.WalkSpeedToSpeedPower, ws)
    return (ok and type(sp) == "number") and sp or nil
end

local function currentSpeedPower()
    local sp
    pcall(function()
        sp = SpeedPowerProjection.ReadProjected()
    end)
    return tonumber(sp) or 0
end

local function eggVerdict(rec, wakePenalty)
    local info = {}
    if not rec then
        return "error", info
    end
    if not GuardEscapePrediction or not GuardEscapeRequirement then
        if not state.escWarned then
            state.escWarned = true
            logRun("Escape check unavailable (game modules missing): eggs count as not deliverable")
            BPUI:Notify({
                Title = "Steal",
                Content = "Escape check broke after a game update. Auto Best is paused.",
                Type = "Warning",
                Duration = 6,
            })
        end
        return "error", info
    end
    local area = guardArea(rec.AreaId)
    if not area then
        local a = getAreas()
        local ga = a and a:FindFirstChild("GuardAreas")
        if ga and #ga:GetChildren() > 0 then
            return "noguard", info
        end
        return "error", info
    end
    local gRoot = guardRootOf(rec.AreaId)
    local line = separationLine()
    local bounds = area:FindFirstChild("Bounds")
    if not (gRoot and line and bounds) then
        return "error", info
    end
    local ok, p = pcall(GuardEscapeRequirement.BuildPathParameters, area, gRoot.Position, line)
    if not ok or type(p) ~= "table" then
        return "error", info
    end
    local pos = (rec.BottomCFrame and rec.BottomCFrame.Position) or eggPosition(rec)
    if not pos then
        return "error", info
    end
    p.PlayerStartPosition = pos
    local okE, exitD =
        pcall(GuardEscapePrediction.ResolveExitDistance, bounds.CFrame, bounds.Size, pos, p.ExitDirection)
    p.ExitDistance = (okE and type(exitD) == "number") and exitD or 0
    local mult = multForEgg(rec)
    local carry = allowedCarrySpeed(mult)
    p.PlayerWalkSpeed = carry
    local okR, r = pcall(GuardEscapePrediction.Resolve, p)
    if not okR or type(r) ~= "table" then
        return "error", info
    end
    local gs = guardStateOf(rec.AreaId)
    local penalty = wakePenalty
    if penalty == nil then
        penalty = (gs == "Chasing" or gs == "ReturningHome" or gs == "RetrievingEgg") and 0.63 or 0
    end
    local margin = (r.CatchTime or math.huge) - (r.ExitTime or 0) - penalty
    local denom = mult * 0.985
    local okReq, reqCarry = pcall(GuardEscapePrediction.ResolvePlayerWalkSpeedRequirement, p, 1)
    info.margin, info.outcome, info.carry, info.mult = margin, r.Outcome, carry, mult
    info.guardBase, info.guardState, info.hit = p.BaseGuardWalkSpeed, gs, p.HitDistance
    info.needCleanWS = p.BaseGuardWalkSpeed * 1.01 / denom
    info.needRelayWS = (okReq and type(reqCarry) == "number") and (reqCarry * 1.03 / denom) or nil
    info.needCleanSP = speedPowerFor(info.needCleanWS)
    info.needRelaySP = info.needRelayWS and speedPowerFor(info.needRelayWS) or nil
    local class
    if carry > p.BaseGuardWalkSpeed * 1.01 and r.Outcome ~= "Caught" then
        class = "clean"
    elseif r.Outcome ~= "Caught" and margin >= 0.3 then
        class = "relay"
    elseif rec.State == "Dropped" and p.ExitDistance == 0 then
        class = "relay"
    else
        class = "blocked"
    end
    info.class = class
    return class, info
end

local function verdictAllowed(class)
    if class == "clean" or class == "noguard" then
        return true
    end
    if cfg.filter.deliverableOnly == false then
        return true
    end
    return class == "relay" and cfg.steal.relay == true
end

function Feat.stealClassOk(class)
    if class == "clean" or class == "noguard" then
        return true
    end
    return class == "relay" and cfg.steal.relay == true
end

function Feat.stealBusy()
    return state.inRun == true or (state.running and not (state.mode == "best" and state.bestIdle))
end

local controlsRef
local function setUserControls(on)
    if not controlsRef then
        pcall(function()
            local ps = lp:FindFirstChildOfClass("PlayerScripts")
            local pm = ps and ps:FindFirstChild("PlayerModule")
            if pm then
                controlsRef = require(pm):GetControls()
            end
        end)
    end
    if controlsRef then
        pcall(function()
            if on then
                controlsRef:Enable()
            else
                controlsRef:Disable()
            end
        end)
    end
end

local function releaseControls()
    if state.running or state.trainWalking or state.manualWalk then
        return
    end
    setUserControls(true)
end

local function stopMoving()
    local _, _, hum = charParts()
    if hum then
        pcall(function()
            hum:Move(Vector3.zero, false)
        end)
    end
end

function Feat.isTrapped()
    local chr = lp.Character
    local t = chr ~= nil and chr:GetAttribute("IsTrapped") == true
    if t then
        state.trappedAt = os.clock()
    end
    return t
end

function Feat.trapSteer(pos, dir, speed)
    local parts = Feat.trapParts
    if not parts or not state.carry or next(parts) == nil then
        return dir
    end
    local look = math.max(12, (speed or 16) * 0.6)
    local push = Vector3.zero
    for hb in pairs(parts) do
        if hb.Parent then
            local to = Vector3.new(hb.Position.X - pos.X, 0, hb.Position.Z - pos.Z)
            local along = to:Dot(dir)
            local rr = math.max(hb.Size.X, hb.Size.Z) / 2 + 3
            if along > -rr and along < look then
                local lat = to - dir * along
                if lat.Magnitude < rr then
                    local away = lat.Magnitude > 0.2 and -lat.Unit or Vector3.new(-dir.Z, 0, dir.X)
                    push += away * (2 * (rr - lat.Magnitude) / rr)
                end
            end
        else
            parts[hb] = nil
        end
    end
    if push.Magnitude < 1e-3 then
        return dir
    end
    local out = dir + push
    return out.Magnitude > 1e-3 and out.Unit or dir
end

local function walkTo(dest, token, opts)
    opts = opts or {}
    local still = opts.stillFn or active
    local tol = opts.tol or 3
    local deadline = os.clock() + (opts.timeout or 120)
    local lastPos, lastProg, lastJump = nil, os.clock(), 0
    local beltSince
    if opts.stillFn == nil then
        setUserControls(false)
    end
    while still(token) do
        if Feat.isTrapped() then
            stopMoving()
            local tw = os.clock()
            while still(token) and Feat.isTrapped() and os.clock() - tw < 10 do
                task.wait(0.2)
            end
            deadline += os.clock() - tw
            lastPos, lastProg = nil, os.clock()
        end
        local _, root, hum = charParts()
        if state.beltId ~= nil and not opts.allowOnBelt then
            local onIt = Feat.onTreadmill and Feat.onTreadmill()
            if onIt == false then
                state.beltId = nil
                beltSince = nil
            else
                beltSince = beltSince or os.clock()
                if os.clock() - beltSince > 6 then
                    stopMoving()
                    return false, "on treadmill"
                end
                Feat.doffTreadmill()
            end
        else
            beltSince = nil
        end
        if root and hum then
            local target = dest
            if type(dest) == "function" then
                target = dest()
            end
            if not target then
                stopMoving()
                return false, "no destination"
            end
            local flat = Vector3.new(target.X - root.Position.X, 0, target.Z - root.Position.Z)
            if flat.Magnitude <= tol then
                stopMoving()
                return true
            end
            if opts.onStep then
                local why = opts.onStep(root, hum)
                if why then
                    stopMoving()
                    return false, why
                end
            end
            local want = opts.speedFn and opts.speedFn() or hum.WalkSpeed
            if not opts.noBrake then
                want = math.min(want, math.max(8, 16 * math.sqrt(flat.Magnitude)))
            end
            local mag = hum.WalkSpeed > 0 and math.clamp(want / hum.WalkSpeed, 0.05, 1) or 1
            hum:Move(Feat.trapSteer(root.Position, flat.Unit, want) * mag, false)
            if not lastPos or (root.Position - lastPos).Magnitude > 2 then
                lastPos, lastProg = root.Position, os.clock()
            elseif not opts.noJump and os.clock() - lastProg > 1.2 and os.clock() - lastJump > 1.5 then
                hum.Jump = true
                lastJump = os.clock()
            end
            if os.clock() > deadline then
                stopMoving()
                return false, "timeout"
            end
        end
        rs.Heartbeat:Wait()
    end
    stopMoving()
    return false, "cancelled"
end

function Feat.doffTreadmill()
    if os.clock() - (state.doffAt or 0) < 0.8 then
        return
    end
    state.doffAt = os.clock()
    local rf = NET and NET:FindFirstChild("RF/Treadmill/AskDoff")
    if rf then
        task.spawn(pcall, rf.InvokeServer, rf)
    end
end

local function leaveTreadmill(maxT)
    if state.beltId == nil then
        return true
    end
    local t0 = os.clock()
    while state.beltId ~= nil and os.clock() - t0 < (maxT or 4) do
        Feat.doffTreadmill()
        task.wait(0.3)
        if state.beltId ~= nil and Feat.onTreadmill and Feat.onTreadmill() == false then
            state.beltId = nil
        end
    end
    return state.beltId == nil
end

state.claims, state.lastClaimAt, state.lastFailAt, state.correctionAt = {}, 0, 0, 0
state.cooldownUntil = 0
state.skipUntil = {}
if EggState then
    pcall(function()
        table.insert(
            conns,
            EggState.CarryChanged:Connect(function(p)
                if type(p) ~= "table" then
                    return
                end
                if p.IsCarrying then
                    local m = tonumber(p.SpeedMultiplier) or 0.96
                    state.carry = {
                        uid = p.Uid,
                        mult = m,
                        area = p.AreaId,
                        cat = p.AssetCategory,
                        guardDisabled = p.GuardDisabled == true,
                        at = os.clock(),
                    }
                    if p.AssetCategory and state.multByCat[p.AssetCategory] ~= m then
                        state.multByCat[p.AssetCategory] = m
                        C.save()
                    end
                else
                    state.carry = nil
                end
            end)
        )
        table.insert(
            conns,
            EggState.FieldClaimed:Connect(function(p)
                state.lastClaimAt = os.clock()
                state.lastClaimCat = type(p) == "table" and p.AssetCategory or nil
            end)
        )
        table.insert(
            conns,
            EggState.FieldGone:Connect(function(uid)
                if type(uid) == "string" then
                    state.claims[uid] = os.clock()
                end
            end)
        )
    end)
end
do
    local function remote(path)
        return NET and NET:FindFirstChild(path)
    end
    local toast = remote("RE/Toasts/Line")
    if toast then
        table.insert(
            conns,
            toast.OnClientEvent:Connect(function(p)
                local body = type(p) == "table" and p.Body or p
                if type(body) == "string" and body:find("Delivery failed") then
                    state.lastFailAt = os.clock()
                end
            end)
        )
    end
    local function onCorrection(kind)
        state.correctionAt = os.clock()
        logRun("Server correction: " .. kind)
    end
    local function payloadHas(v, needle, depth)
        depth = depth or 0
        local t = typeof(v)
        if t == "string" then
            return v:find(needle, 1, true) ~= nil
        end
        if t == "buffer" then
            local ok, str = pcall(buffer.tostring, v)
            return ok and str:find(needle, 1, true) ~= nil
        end
        if t == "table" and depth < 4 then
            for k, x in pairs(v) do
                if payloadHas(k, needle, depth + 1) or payloadHas(x, needle, depth + 1) then
                    return true
                end
            end
        end
        return false
    end
    local refresh = remote("RE/RigSync/Refresh")
    if refresh then
        table.insert(
            conns,
            refresh.OnClientEvent:Connect(function(...)
                local args = { ... }
                if
                    payloadHas(args, "Relocate")
                    and state.beltId == nil
                    and not (Feat.onTreadmill and Feat.onTreadmill())
                then
                    onCorrection("Relocate")
                end
                if payloadHas(args, "BeginRagdoll") or payloadHas(args, "BeginImpulse") then
                    state.impulseAt = os.clock()
                end
            end)
        )
    end
    local belt = remote("RE/Treadmill/AssignedBeltShifted")
    if belt then
        table.insert(
            conns,
            belt.OnClientEvent:Connect(function(id)
                state.beltId = id
                state.beltAt = os.clock()
            end)
        )
    end
    pcall(function()
        for _, m in ipairs(H.gs("CollectionService"):GetTagged("ActiveTreadmill")) do
            local id = m:GetAttribute("ActiveTreadmillId")
            if id ~= nil then
                state.beltId = id
                state.beltAt = os.clock()
                break
            end
        end
    end)
    local corr = remote("RE/RigSync/CorrectionBegan")
    if corr then
        table.insert(
            conns,
            corr.OnClientEvent:Connect(function()
                onCorrection("CorrectionBegan")
            end)
        )
    end
end

local function claimSeen(uid, since, cat)
    if state.claims[uid] and state.claims[uid] >= since then
        return true
    end
    if state.lastClaimAt >= since and (not cat or not state.lastClaimCat or state.lastClaimCat == cat) then
        return true
    end
    local r = fieldRecord(uid)
    return r ~= nil and r.State == "Claimed"
end

local function waitGuardSleep(areaId, token, maxT)
    local t0 = os.clock()
    while active(token) and os.clock() - t0 < maxT do
        local gs = guardStateOf(areaId)
        if gs == nil or gs == "Sleeping" then
            return true
        end
        task.wait(0.2)
    end
    return false
end

local function holdDuration(uid)
    local d
    pcall(function()
        local folder = workspace:FindFirstChild("AreaEggSlotsClient")
        local model = folder and folder:FindFirstChild(uid)
        local prompt = model and model:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            d = prompt.HoldDuration
        end
    end)
    if type(d) == "number" and d > 0 then
        return d + 0.1
    end
    local fast = workspace:GetAttribute("FastEggPickupTime")
    if type(fast) == "number" and fast > 0 then
        return fast + 0.1
    end
    return fast and 0.35 or 1.3
end

local function pickup(uid, token, since)
    local denials, backoff, arrivedAt = 0, 0.4, nil
    local deadline = os.clock() + 150
    while active(token) do
        if os.clock() > deadline then
            stopMoving()
            return false, "pickup timeout"
        end
        local rec = fieldRecord(uid)
        if not rec then
            return false, "egg is gone"
        end
        if rec.State == "Carried" and rec.CarrierUserId == lp.UserId then
            return true
        end
        if not isAvailable(rec) then
            return false, "egg was taken (" .. tostring(rec.State) .. ")"
        end
        local _, root = charParts()
        local pos = eggPosition(rec)
        if root and pos then
            if xz(root.Position, pos) > 4.5 or math.abs(root.Position.Y - pos.Y) > 20 then
                arrivedAt = nil
                local ok, why = walkTo(
                    function()
                        local r = fieldRecord(uid)
                        return r and eggPosition(r)
                    end,
                    token,
                    {
                        tol = 2.5,
                        timeout = 120,
                        onStep = function()
                            if not isAvailable(fieldRecord(uid)) then
                                return "taken"
                            end
                            if state.correctionAt > (since or state.runStartedAt or 0) then
                                return "correction"
                            end
                        end,
                    }
                )
                if not ok then
                    return false, why or "could not reach the egg"
                end
            else
                stopMoving()
                arrivedAt = arrivedAt or os.clock()
                if os.clock() - arrivedAt >= holdDuration(uid) then
                    local slotKey
                    pcall(function()
                        if SlotIdentity.LooksLikeFirstAreaUid and SlotIdentity.LooksLikeFirstAreaUid(uid) then
                            slotKey = SlotIdentity.SlotKey(rec.AreaId, rec.NestId)
                        end
                    end)
                    local ok, accepted, reason = pcall(EggState.CarryFieldEgg, uid, slotKey)
                    if ok and accepted then
                        if active(token) then
                            return true
                        end
                        local tw = os.clock()
                        while not state.carry and os.clock() - tw < 1 do
                            task.wait(0.05)
                        end
                        Feat.cancelCarry()
                        return false, "cancelled"
                    end
                    denials += 1
                    logRun("Pickup denied: " .. tostring(ok and reason or accepted))
                    if denials >= 6 then
                        return false, "pickup denied: " .. tostring(ok and reason or accepted)
                    end
                    task.wait(backoff)
                    backoff = math.min(backoff * 2, 1.6)
                    arrivedAt = os.clock()
                end
            end
        end
        task.wait(0.05)
    end
    return false, "cancelled"
end

local function ragdollEnd()
    return tonumber(lp:GetAttribute("RagdollEndTime")) or 0
end

local function carryHome(uid, token, startRec)
    local line = separationLine()
    if not line then
        return false, "safe line not found"
    end
    local areaId, cat = startRec.AreaId, startRec.AssetCategory
    local minX = boundsMinX(areaId)
    local _, vInfo = eggVerdict(startRec)
    local hitD = vInfo.hit or 7
    local since, legs, corrections = os.clock(), 1, 0
    local lineZ = line.Position.Z
    local gBase = vInfo.guardBase or 150
    local function relayLead()
        local rtt = 0.2
        pcall(function()
            rtt = math.clamp(lp:GetNetworkPing() * 2, 0.08, 0.6)
        end)
        local _, _, hum = charParts()
        local carry = hum and hum.WalkSpeed or 150
        return hitD + gBase * (rtt + 0.12) + math.max(gBase - carry, 0) * 0.3
    end
    local function guardGoneHome()
        if waitGuardSleep(areaId, token, 20) then
            return true
        end
        local g = guardRootOf(areaId)
        local _, r2 = charParts()
        return g ~= nil and r2 ~= nil and xz(g.Position, r2.Position) > 400
    end
    local function dest()
        local _, root = charParts()
        local z = root and math.clamp(root.Position.Z, lineZ - 60, lineZ + 60) or lineZ
        return Vector3.new(line.Position.X - 14, 0, z)
    end
    local function carrySpeedNow()
        local _, _, hum = charParts()
        local allowed = allowedCarrySpeed((state.carry and state.carry.mult) or state.multByCat[cat] or 0.96)
        local v = hum and math.min(allowed, hum.WalkSpeed) or allowed
        local mode = cfg.steal.returnSpeed
        if mode == "Match Guard" or mode == "Just Above Guard" then
            local _, root = charParts()
            if root then
                local need, danger = math.max((guardLiveSpeed(areaId)), gBase), false
                for _, c in ipairs(chasingGuards(root)) do
                    need = math.max(need, c.speed)
                    if c.dist <= hitD + 15 then
                        danger = true
                    end
                end
                if not danger then
                    v = math.min(v, need * 1.03 + 2)
                end
            end
        end
        return v
    end
    local function awaitClaim(maxT)
        local t0 = os.clock()
        while os.clock() - t0 < maxT do
            if claimSeen(uid, since, cat) then
                return true
            end
            if state.lastFailAt > since then
                return false, "Delivery failed (egg returned to nest)"
            end
            local r = fieldRecord(uid)
            if r and (r.State == "Slot" or r.State == "GuardCarried") then
                return false, "egg returned to its nest"
            end
            if r and r.State == "Dropped" then
                return false, "rejected at the line"
            end
            if not r and state.claims[uid] then
                return true
            end
            task.wait(0.1)
        end
        return false, "no claim after crossing"
    end
    while active(token) do
        local ok, why = walkTo(dest, token, {
            tol = 4,
            timeout = 240,
            speedFn = carrySpeedNow,
            noBrake = true,
            onStep = function(root)
                if claimSeen(uid, since, cat) then
                    return "claimed"
                end
                if root.Position.X < line.Position.X - 10 then
                    return "crossed"
                end
                if state.lastFailAt > since then
                    return "failed"
                end
                if state.correctionAt > since then
                    return "correction"
                end
                local r = fieldRecord(uid)
                if r and (r.State ~= "Carried" or r.CarrierUserId ~= lp.UserId) then
                    return "lost"
                end
                if cfg.steal.relay and minX and root.Position.X < minX - 10 then
                    local g = guardRootOf(areaId)
                    if g and guardStateOf(areaId) == "Chasing" and xz(g.Position, root.Position) <= relayLead() then
                        return "relay"
                    end
                end
            end,
        })
        if ok or why == "claimed" or why == "crossed" then
            local okC, whyC = awaitClaim(8)
            if okC or whyC ~= "rejected at the line" or state.retriedLine then
                return okC, whyC
            end
            state.retriedLine = true
            logRun("Delivery rejected at the line, picking the egg up once more")
            local tw = os.clock()
            while active(token) and os.clock() - tw < 1.5 do
                task.wait(0.1)
            end
            local okP, whyP = pickup(uid, token, os.clock())
            if not okP then
                return false, "re-pick at the line failed: " .. tostring(whyP)
            end
            since = os.clock()
        elseif why == "failed" then
            return false, "Delivery failed (egg returned to nest)"
        elseif why == "correction" then
            corrections += 1
            if corrections > 3 then
                return false, "server correction"
            end
            stopMoving()
            local tc = os.clock()
            while active(token) and os.clock() - tc < 0.75 do
                task.wait(0.05)
            end
            since = math.max(since, state.correctionAt)
        elseif why == "relay" then
            if legs >= 8 then
                return false, "too many relay legs"
            end
            local _, root = charParts()
            logRun(string.format("Relay leg %d: dropping at X=%d", legs, root and math.floor(root.Position.X) or 0))
            stopMoving()
            pcall(EggState.DropFieldEgg, "PlayerRequest")
            task.wait(0.35)
            local r = fieldRecord(uid)
            if not r or r.State ~= "Dropped" then
                return false, "relay drop failed (" .. tostring(r and r.State) .. ")"
            end
            setStatus(string.format("Relay leg %d: waiting for the guard to go home", legs))
            if not guardGoneHome() then
                return false, "guard never went home"
            end
            local okP, whyP = pickup(uid, token, os.clock())
            if not okP then
                return false, "relay re-pick failed: " .. tostring(whyP)
            end
            legs += 1
            setStatus(string.format("Carrying home (leg %d)", legs))
        elseif why == "lost" then
            local r = fieldRecord(uid)
            local p = r and eggPosition(r)
            if cfg.steal.relay and legs < 8 and r and r.State == "Dropped" and p and minX and p.X < minX - 5 then
                logRun(string.format("Hit outside the area at X=%d, re-picking", math.floor(p.X)))
                while
                    active(token)
                    and (tonumber(lp:GetAttribute("RagdollEndTime")) or 0) > workspace:GetServerTimeNow()
                do
                    task.wait(0.1)
                end
                if not guardGoneHome() then
                    return false, "guard never went home"
                end
                local okP, whyP = pickup(uid, token, os.clock())
                if not okP then
                    return false, "re-pick after hit failed: " .. tostring(whyP)
                end
                legs += 1
            else
                return false, "egg lost (" .. tostring(r and r.State or "gone") .. ")"
            end
        else
            return false, why or "cancelled"
        end
    end
    return false, "cancelled"
end

local function finish(msg)
    state.running = false
    state.mode = nil
    state.bestIdle = false
    state.token += 1
    stopMoving()
    releaseControls()
    setStatus(msg)
    if state.toggle then
        Feat.ui(function()
            state.toggle:Set(false, true)
        end)
    end
    if state.bestTog then
        Feat.ui(function()
            state.bestTog:Set(false, true)
        end)
    end
end

function Feat.recoverCarry(token, t0)
    if not state.carry then
        task.wait(0.3)
    end
    local trapped = (state.trappedAt or 0) >= (t0 or 0) or Feat.isTrapped()
    if trapped or not state.carry or not active(token) then
        return trapped, false
    end
    local cr = fieldRecord(state.carry.uid)
    local delivered = false
    if cr and cr.State == "Carried" and cr.CarrierUserId == lp.UserId then
        logRun("Still carrying after a failure, finishing the carry")
        setStatus("Still carrying the egg, finishing the carry")
        state.inRun = true
        local okC, done = pcall(carryHome, state.carry.uid, token, cr)
        state.inRun = false
        delivered = okC and done == true
        if not delivered and state.carry and active(token) then
            pcall(EggState.DropFieldEgg, "PlayerRequest")
        end
    end
    return false, delivered
end

local function run(token, targetUid)
    if not active(token) then
        return false
    end
    state.runStartedAt = os.clock()
    state.retriedLine = false
    local rec = fieldRecord(targetUid)
    if not isAvailable(rec) then
        error("LOST: the egg is no longer available")
    end
    local allowedFn = state.mode == "best" and Feat.stealClassOk or verdictAllowed
    local class, info = eggVerdict(rec)
    if not allowedFn(class) then
        if class == "error" then
            error(rec.AreaId .. " egg is not deliverable: the escape check failed")
        end
        error(
            string.format(
                "%s egg is not deliverable at your speed (needs %s SpeedPower)",
                rec.AreaId,
                shortNum(info.needCleanSP or 0)
            )
        )
    end
    if AreaEggCycle then
        local now = workspace:GetServerTimeNow()
        local okN, night = pcall(AreaEggCycle.IsNightPhase, now)
        if okN and night == true then
            error("WAIT: night phase, eggs are resetting")
        end
        local okS, left = pcall(AreaEggCycle.SecondsUntilReset, now)
        local pos = eggPosition(rec)
        local _, root = charParts()
        if okS and type(left) == "number" and left >= 0 and pos and root then
            local est = xz(root.Position, pos) / math.max(powerWalkSpeed(), 16)
                + math.max(pos.X - 552, 0) / math.max(allowedCarrySpeed(info.mult), 16)
                + 6
            if left < est then
                error(string.format("WAIT: egg reset in %ds", math.floor(left)))
            end
        end
    end

    if not leaveTreadmill(4) then
        error("WAIT: could not leave the treadmill")
    end
    if not active(token) then
        return false
    end
    setStatus("Getting the " .. rec.AreaId .. " egg")
    local okP, whyP = pickup(targetUid, token)
    if not okP then
        if not active(token) then
            return false
        end
        local w = tostring(whyP)
        if w == "taken" or w:find("^egg is gone") or w:find("^egg was taken") then
            error("LOST: " .. w)
        end
        error("Pickup failed: " .. w)
    end

    local pickedAt = os.clock()
    local waitCarry = os.clock()
    while active(token) and not (state.carry and state.carry.uid == targetUid) and os.clock() - waitCarry < 1 do
        task.wait(0.05)
    end
    if not active(token) then
        local tw = os.clock()
        while not state.carry and os.clock() - tw < 1 do
            task.wait(0.05)
        end
        Feat.cancelCarry()
        return false
    end
    local carried = fieldRecord(targetUid) or rec
    local mult = (state.carry and state.carry.mult) or 0.96
    local cls2 = eggVerdict(carried, (os.clock() - pickedAt) + 0.1)
    logRun(
        string.format(
            "Picked %s egg, carry x%.2f, %.0f studs/s, verdict %s",
            carried.AreaId,
            mult,
            allowedCarrySpeed(mult),
            cls2
        )
    )
    if not allowedFn(cls2) and not (state.carry and state.carry.uid == targetUid and state.carry.guardDisabled) then
        pcall(EggState.DropFieldEgg, "PlayerRequest")
        error(string.format("The guard would catch you with this egg (carry x%.2f), dropped it back", mult))
    end

    if not active(token) then
        return false
    end
    setStatus(string.format("2/3 Carrying home at %d studs/s", math.floor(allowedCarrySpeed(mult))))
    local okH, whyH = carryHome(targetUid, token, carried)
    if not okH then
        if not active(token) then
            return false
        end
        error(whyH or "delivery failed")
    end
    setStatus("3/3 Delivered")
    return true
end

local function displayRate(rec)
    local item = {
        Category = rec.AssetCategory,
        Mutations = rec.Mutations or {},
        BaseMutation = rec.BaseMutation,
        Scale = rec.AssetScale,
    }
    local ok, rate = pcall(AssetEarnings.RatePerSecond, item)
    if ok and type(rate) == "number" then
        return rate
    end
    local config = Assets.Directory[rec.AssetCategory]
    return config and config.EarningRate or 0
end

local function eggCatName(rec)
    local config = Assets and Assets.Directory and Assets.Directory[rec.AssetCategory]
    return (config and config.Egg and config.Egg.DisplayName) or (config and config.DisplayName) or rec.AssetCategory
end

function Feat.petName(rec)
    local config = Assets and Assets.Directory and Assets.Directory[rec.AssetCategory]
    local pet = config and config.DisplayName
    if type(pet) ~= "string" or pet == "" or pet == eggCatName(rec) then
        return nil
    end
    return pet
end

function Feat.eggTitle(rec)
    local pet = Feat.petName(rec)
    return eggCatName(rec) .. (pet and (" (" .. pet .. ")") or "")
end

function Feat.mutLabel(id)
    if Feat.MutMod == nil then
        local ok, M = pcall(function()
            return require(rep.Shared.Modules.Mutations)
        end)
        Feat.MutMod = ok and type(M) == "table" and M or false
    end
    local ok, l = pcall(function()
        return Feat.MutMod and Feat.MutMod.LabelOf(id)
    end)
    return (ok and type(l) == "string" and l ~= "") and l or tostring(id)
end

local function labelFor(rec)
    return string.format("%s / $%s/s", Feat.eggTitle(rec), shortNum(displayRate(rec)))
end

local function asList(v)
    return type(v) == "table" and v or {}
end

local function inList(tbl, val)
    if type(tbl) ~= "table" or #tbl == 0 then
        return true
    end
    for _, v in ipairs(tbl) do
        if v == val then
            return true
        end
    end
    return false
end

local function eggRarity(rec)
    local config = Assets and Assets.Directory and Assets.Directory[rec.AssetCategory]
    local r = config and config.Rarity
    if type(r) == "table" then
        return r.DisplayName or r._id or "Unknown", r.Rank or 0
    end
    return "Unknown", 0
end

local function anyInList(tbl, vals)
    if type(tbl) ~= "table" or #tbl == 0 then
        return true
    end
    for _, v in ipairs(vals) do
        if inList(tbl, v) then
            return true
        end
    end
    return false
end

function Feat.eggTypes()
    if Feat.typeCache then
        return Feat.typeCache
    end
    local list = {}
    pcall(function()
        for id, conf in pairs(Assets.Directory) do
            if type(id) == "string" and type(conf) == "table" and conf.Egg then
                local rec = { AssetCategory = id }
                local rar, rank = eggRarity(rec)
                local pet = type(conf.DisplayName) == "string" and conf.DisplayName or id
                list[#list + 1] = {
                    id = id,
                    rank = rank,
                    egg = eggCatName(rec),
                    label = string.format("%s [%s]", Feat.eggTitle(rec), rar),
                    petLabel = string.format("%s [%s]", pet, rar),
                }
            end
        end
    end)
    table.sort(list, function(a, b)
        if a.rank ~= b.rank then
            return a.rank > b.rank
        end
        return a.label < b.label
    end)
    for _, key in ipairs({ "label", "petLabel" }) do
        local count = {}
        for _, t in ipairs(list) do
            count[t[key]] = (count[t[key]] or 0) + 1
        end
        for _, t in ipairs(list) do
            if count[t[key]] > 1 then
                t[key] = t[key] .. " {" .. t.id .. "}"
            end
        end
    end
    if #list > 0 then
        Feat.typeCache = list
    end
    return list
end

function Feat.catIds(saved)
    local dir = Assets and Assets.Directory
    local out, seen = {}, {}
    for _, v in ipairs(asList(saved)) do
        if type(dir) ~= "table" or dir[v] ~= nil then
            if not seen[v] then
                seen[v] = true
                out[#out + 1] = v
            end
        else
            for _, t in ipairs(Feat.eggTypes()) do
                if (t.egg == v or t.label == v) and not seen[t.id] then
                    seen[t.id] = true
                    out[#out + 1] = t.id
                end
            end
        end
    end
    return out
end
pcall(function()
    local old = table.concat(asList(cfg.filter.cats), "\0")
    cfg.filter.cats = Feat.catIds(cfg.filter.cats)
    if table.concat(cfg.filter.cats, "\0") ~= old then
        C.save()
    end
end)

function Feat.nameMatch(text, cat)
    text = tostring(text or "")
    if not text:find("%S") then
        return nil
    end
    local conf = cat and Assets and Assets.Directory and Assets.Directory[cat]
    local hay = string.lower(
        tostring(cat)
            .. "|"
            .. tostring(conf and conf.DisplayName or "")
            .. "|"
            .. tostring(conf and type(conf.Egg) == "table" and conf.Egg.DisplayName or "")
    )
    for word in text:gmatch("[^,]+") do
        word = word:match("^%s*(.-)%s*$"):lower()
        if word ~= "" and hay:find(word, 1, true) then
            return true
        end
    end
    return false
end

function Feat.riftSet()
    local sv = Save and (Save.Peek or Save.Get)
    local save = sv and sv()
    local reqs = type(save) == "table" and type(save.Rift) == "table" and save.Rift.Requirements
    if type(reqs) ~= "table" then
        return nil
    end
    local set = {}
    for _, v in pairs(reqs) do
        set[v] = true
    end
    return set
end

function Feat.indexSet()
    local sv = Save and (Save.Peek or Save.Get)
    local save = sv and sv()
    return type(save) == "table" and type(save.Index) == "table" and save.Index or nil
end

function Feat.isRiftEgg(rec, set)
    set = set or Feat.riftSet()
    return set ~= nil and rec ~= nil and set[rec.AssetCategory] == true
end

function Feat.isIndexMissingEgg(rec, idx)
    idx = idx or Feat.indexSet()
    return idx ~= nil and rec ~= nil and idx[rec.AssetCategory] ~= true
end

state.areaNeeds = {}
local function refreshEggs(quiet)
    local f = cfg.filter or {}
    local fMinRate = tonumber(f.minRate) or 0
    local fMaxRate = tonumber(f.maxRate) or 0
    local fMaxDist = tonumber(f.maxDist) or 0
    local fAreas = type(f.areas) == "table" and f.areas or {}
    local fCats = type(f.cats) == "table" and f.cats or {}
    local fRarity = type(f.rarities) == "table" and f.rarities or {}
    local fMuts = type(f.muts) == "table" and f.muts or {}
    local fMutated = f.onlyMutated == true
    local fNoMut = f.noMutation == true
    local riftSet = f.riftOnly == true and Feat.riftSet() or nil
    local idxSet = f.indexMissing == true and Feat.indexSet() or nil
    local _, myRoot = charParts()
    local myPos = myRoot and myRoot.Position
    local rows, needs, einfo = {}, {}, {}
    local okR, all = pcall(function()
        return EggState.ReadFieldEggs().Records
    end)
    for _, rec in ipairs(okR and all or {}) do
        local pos = isAvailable(rec) and eggPosition(rec)
        if pos then
            local class, info = eggVerdict(rec)
            local n = needs[rec.AreaId]
            if info.needCleanSP and (not n or info.needCleanSP < n.clean) then
                needs[rec.AreaId] = { clean = info.needCleanSP, relay = info.needRelaySP or info.needCleanSP }
            end
            local muts = type(rec.Mutations) == "table" and rec.Mutations or {}
            local rarName, rarRank = eggRarity(rec)
            local rate = displayRate(rec)
            local dist = myPos and (pos - myPos).Magnitude or 0
            local passes = inList(fAreas, rec.AreaId)
                and inList(fCats, rec.AssetCategory)
                and inList(fRarity, rarName)
                and rate >= fMinRate
                and (fMaxRate <= 0 or rate <= fMaxRate)
                and (fMaxDist <= 0 or dist <= fMaxDist)
                and (not fMutated or #muts > 0)
                and (not fNoMut or #muts == 0)
                and (#fMuts == 0 or anyInList(fMuts, muts))
                and (rec.State == "Slot" or f.includeDropped == true)
                and (f.riftOnly ~= true or Feat.isRiftEgg(rec, riftSet or {}))
                and (f.indexMissing ~= true or (idxSet ~= nil and Feat.isIndexMissingEgg(rec, idxSet)))
            einfo[rec.Uid] = { passes = passes, class = class, rate = rate, rarity = rarName }
            if f.showAll == true or (passes and verdictAllowed(class)) then
                table.insert(rows, {
                    uid = rec.Uid,
                    label = labelFor(rec),
                    rate = rate,
                    dist = dist,
                    rank = rarRank,
                    rarity = rarName,
                    area = rec.AreaId,
                    cat = eggCatName(rec),
                    title = Feat.eggTitle(rec),
                    class = class,
                    margin = info.margin,
                    passes = passes,
                })
            end
        end
    end
    state.areaNeeds = needs
    state.eggInfo, state.eggInfoAt = einfo, os.clock()
    local sortBy = f.sortBy or "Highest Rate"
    table.sort(rows, function(a, b)
        if sortBy == "Nearest" then
            return a.dist < b.dist
        end
        if sortBy == "Rarity" and a.rank ~= b.rank then
            return a.rank > b.rank
        end
        if sortBy == "Lowest Rate" then
            return a.rate < b.rate
        end
        return a.rate > b.rate
    end)
    state.rows = rows
    if not quiet and not state.running then
        if (f.riftOnly == true and not riftSet) or (f.indexMissing == true and not idxSet) then
            setStatus("Rift / Index data unavailable, those filters show nothing")
        else
            local deliverable = 0
            for _, r in ipairs(rows) do
                if Feat.stealClassOk(r.class) then
                    deliverable += 1
                end
            end
            setStatus(string.format("%d eggs listed (%d deliverable)", #rows, deliverable))
        end
    end
    return rows
end

local function fieldEggFilterLists()
    local ok, recs = pcall(function()
        return EggState.ReadFieldEggs().Records
    end)
    local areaSet, areas, onField = {}, {}, {}
    local function addArea(a)
        if type(a) == "string" and not areaSet[a] then
            areaSet[a] = true
            areas[#areas + 1] = a
        end
    end
    for _, rec in ipairs(ok and recs or {}) do
        addArea(rec.AreaId)
        if type(rec.AssetCategory) == "string" then
            onField[rec.AssetCategory] = true
        end
    end
    pcall(function()
        for id, a in pairs(require(rep.Data.Areas).Directory) do
            if type(a) == "table" and a.GuardId ~= nil then
                addArea(id)
            end
        end
    end)
    table.sort(areas)
    local cats, rest, byLabel, labelOf = {}, {}, {}, {}
    for _, t in ipairs(Feat.eggTypes()) do
        local l = onField[t.id] and (t.label .. "  (on field)") or t.label
        byLabel[l], byLabel[t.label], labelOf[t.id] = t.id, t.id, l
        table.insert(onField[t.id] and cats or rest, l)
    end
    table.move(rest, 1, #rest, #cats + 1, cats)
    Feat.catByLabel, Feat.catLabelOf = byLabel, labelOf
    return areas, cats
end

state.stats =
    { ok = 0, fail = 0, gained = 0, totalTime = 0, bestRate = 0, bestLabel = nil, startedAt = os.clock(), runCount = 0 }

local function recordSteal(success, label, rate, secs)
    local s = state.stats
    if success then
        s.ok += 1
        s.runCount += 1
        s.gained += rate or 0
        s.totalTime += secs or 0
        if (rate or 0) > s.bestRate then
            s.bestRate = rate or 0
            s.bestLabel = label
        end
        if cfg.steal.notify then
            BPUI:Notify({
                Title = "Stolen!",
                Content = (label or "Egg") .. string.format(" (%.0fs)", secs or 0),
                Type = "Success",
                Duration = 3,
            })
        end
        if cfg.hook.steal and Feat.onStolen then
            pcall(Feat.onStolen, label, rate, secs)
        end
    else
        s.fail += 1
    end
    if state.onStats then
        pcall(state.onStats)
    end
end

function Feat.notifyFail(title, msg)
    if cfg.steal.notifyFail == false then
        return
    end
    BPUI:Notify({ Title = title, Content = msg, Type = "Warning", Duration = 5 })
end

local function firstLine(err)
    local s = tostring(err)
    s = s:match("^[^\n]+") or s
    return (s:gsub("^.-:%d+: ", ""))
end

local function start()
    if state.running or state.destroyed then
        return false
    end
    if not state.selectedUid then
        setStatus("Select a Target Egg first")
        return false
    end
    local target = fieldRecord(state.selectedUid)
    if not isAvailable(target) then
        setStatus("Selected egg is no longer available")
        return false
    end
    local class, info = eggVerdict(target)
    if not verdictAllowed(class) then
        setStatus(
            class == "error" and ("Not deliverable: the escape check failed for this " .. target.AreaId .. " egg")
                or string.format(
                    "Not deliverable: %s needs %s SpeedPower (you have %s)",
                    target.AreaId,
                    shortNum(info.needCleanSP or 0),
                    shortNum(currentSpeedPower())
                )
        )
        if state.toggle then
            Feat.ui(function()
                state.toggle:Set(false, true)
            end)
        end
        return false
    end
    state.running = true
    state.mode = "single"
    state.token += 1
    state.walkToken += 1
    if state.trainPauseUntil == math.huge then
        state.trainPauseUntil = 0
    end
    setUserControls(false)
    local token = state.token
    local targetUid = state.selectedUid
    if state.toggle then
        Feat.ui(function()
            state.toggle:Set(true, true)
        end)
    end
    local tLabel, tRate, t0 = labelFor(target), displayRate(target), os.clock()
    task.spawn(function()
        state.inRun = true
        local ok, result = pcall(run, token, targetUid)
        state.inRun = false
        if active(token) then
            local msg = not ok and firstLine(result) or ""
            local isWait = msg:find("^WAIT: ") ~= nil
            local isLost = msg:find("^LOST: ") ~= nil
            if not isWait and not isLost then
                recordSteal(ok and result == true, tLabel, tRate, os.clock() - t0)
            end
            if ok and result then
                logRun("Delivered " .. tLabel)
                finish("Complete: egg delivered")
            else
                local why = ok and "interrupted"
                    or (msg:gsub("^WAIT: ", ""):gsub("^LOST: ", "taken by another player, "))
                local trapped, delivered = Feat.recoverCarry(token, t0)
                if not active(token) then
                    return
                end
                if trapped then
                    why = "trapped by a player trap (" .. why .. ")"
                end
                if delivered then
                    why = why .. ", the egg was still delivered"
                end
                logRun("Failed: " .. why)
                finish("Stopped: " .. why)
                Feat.notifyFail("Single Steal", "Stopped: " .. why)
                if not isWait then
                    Feat.walkHomeIfInField()
                end
            end
        end
    end)
    return true
end

state.spSamples = {}
local function treadmillPart()
    local slot
    pcall(function()
        slot = PlotState.ResolveLocalSlot()
    end)
    local plots = workspace:FindFirstChild("Plots")
    local plot = plots and slot and plots:FindFirstChild(tostring(slot))
    local tb = plot and plot:FindFirstChild("TreadmillBottom")
    return (tb and tb:IsA("BasePart")) and tb or nil
end

local function onTreadmill()
    local tb = treadmillPart()
    local _, root = charParts()
    if not (tb and root) then
        return false
    end
    local rel = tb.CFrame:PointToObjectSpace(root.Position)
    return math.abs(rel.X) <= tb.Size.X / 2 + 1 and math.abs(rel.Z) <= tb.Size.Z / 2 + 1 and rel.Y > -2 and rel.Y < 10
end
Feat.onTreadmill = function()
    if not treadmillPart() then
        return nil
    end
    return onTreadmill()
end

local function sampleSpeedPower()
    local sp
    pcall(function()
        sp = Save.Peek().SpeedPower
    end)
    sp = tonumber(sp) or currentSpeedPower()
    local now = os.clock()
    local s = state.spSamples
    s[#s + 1] = { t = now, sp = sp }
    while #s > 2 and now - s[1].t > 120 do
        table.remove(s, 1)
    end
    return sp
end

state.sampler = H.task(function()
    local _, _, hum = charParts()
    if hum and not state.carry then
        state.freeWalk = hum.WalkSpeed
    end
    sampleSpeedPower()
    local now = os.clock()
    for uid, t in pairs(state.claims) do
        if now - t > 60 then
            state.claims[uid] = nil
        end
    end
    Feat.pruneConns()
end, 2, 1)

local function trainingRate()
    local s = state.spSamples
    if #s < 2 then
        return 0
    end
    local a, b = s[1], s[#s]
    if b.t - a.t < 5 then
        return 0
    end
    return math.max(0, (b.sp - a.sp) / (b.t - a.t))
end

local function goTrain(token, stillFn)
    local tb = treadmillPart()
    if not tb then
        return false, "treadmill not found"
    end
    if state.beltId ~= nil or onTreadmill() then
        stopMoving()
        return true
    end
    local ok, why = walkTo(
        function()
            local t = treadmillPart()
            return t and t.Position
        end,
        token,
        {
            tol = 1.5,
            timeout = 90,
            noJump = true,
            stillFn = stillFn,
            onStep = function()
                if onTreadmill() then
                    return "onbelt"
                end
            end,
        }
    )
    stopMoving()
    if why == "onbelt" or why == "on treadmill" then
        return true
    end
    return ok, why
end

local function nextTreadmillTier()
    local level, list
    pcall(function()
        level = Save.Peek().TreadmillUpgradeLevel
    end)
    pcall(function()
        list = TreadmillsData.GetOrdered()
    end)
    if type(level) ~= "number" or type(list) ~= "table" then
        return nil
    end
    return list[level + 1], list[level]
end

local function money()
    local m
    pcall(function()
        m = Save.Peek().Money
    end)
    return tonumber(m) or 0
end

function Feat.pickBest(useSkip)
    local cands, now = {}, os.clock()
    for _, row in ipairs(state.rows) do
        if row.passes and Feat.stealClassOk(row.class) and not (useSkip and (state.skipUntil[row.uid] or 0) > now) then
            cands[#cands + 1] = row
        end
    end
    table.sort(cands, function(a, b)
        if a.rate ~= b.rate then
            return a.rate > b.rate
        end
        return (a.margin or 0) > (b.margin or 0)
    end)
    for _, row in ipairs(cands) do
        local rec = fieldRecord(row.uid)
        if rec and isAvailable(rec) then
            if row.class == "clean" or row.class == "noguard" or guardStateOf(row.area) == "Sleeping" then
                return row
            end
        end
    end
    return nil
end

local function startBest()
    if state.running or state.destroyed then
        return false
    end
    state.running = true
    state.mode = "best"
    state.token += 1
    state.stats.runCount = 0
    state.walkToken += 1
    state.cooldownUntil = 0
    state.skipUntil = {}
    state.bestIdle = false
    if state.trainPauseUntil == math.huge then
        state.trainPauseUntil = 0
    end
    setUserControls(false)
    local token = state.token
    if state.bestTog then
        Feat.ui(function()
            state.bestTog:Set(true, true)
        end)
    end
    task.spawn(function()
        local okLoop, errLoop = pcall(function()
            local fails, failedUids = 0, {}
            local function idle(secs, step)
                state.bestIdle = true
                local tw = os.clock()
                while active(token) and os.clock() - tw < secs do
                    task.wait(step or 0.5)
                end
            end
            local function reclaim()
                state.bestIdle = false
                local tc = os.clock()
                while active(token) and state.manualWalk == "collector" and os.clock() - tc < 2 do
                    task.wait(0.05)
                end
                return not (
                    state.bossEntering
                    or lp:GetAttribute("InBossArena")
                    or os.clock() < (state.bestHoldUntil or 0)
                )
            end
            while active(token) do
                if lp:GetAttribute("InBossArena") or os.clock() < (state.bestHoldUntil or 0) then
                    setStatus("Auto Best: paused while you are in the boss arena")
                    idle(2)
                elseif state.cooldownUntil > os.clock() then
                    setStatus(string.format("Auto Best: cooling down %ds", math.ceil(state.cooldownUntil - os.clock())))
                    idle(1)
                else
                    refreshEggs(true)
                    local best = Feat.pickBest(true)
                    if not best then
                        if cfg.steal.trainIdle and os.clock() >= (state.trainPauseUntil or 0) then
                            setStatus("Auto Best: no deliverable egg, training speed")
                            if reclaim() then
                                goTrain(token)
                                idle(20)
                            else
                                idle(2)
                            end
                        else
                            setStatus("Auto Best: no deliverable egg, waiting")
                            idle(5, 0.25)
                        end
                    elseif not reclaim() then
                        idle(2)
                    else
                        state.selectedUid = best.uid
                        if Feat.updateEggDrop then
                            pcall(Feat.updateEggDrop)
                        end
                        setStatus("Auto Best: " .. best.label)
                        local t0 = os.clock()
                        state.inRun = true
                        local ok, result = pcall(run, token, best.uid)
                        state.inRun = false
                        if not active(token) then
                            break
                        end
                        local msg = not ok and firstLine(result) or ""
                        local waitWhy = msg:match("^WAIT: (.+)")
                        local lostWhy = msg:match("^LOST: (.+)")
                        if waitWhy then
                            setStatus("Auto Best: " .. waitWhy)
                            idle(12)
                        elseif lostWhy then
                            state.skipUntil[best.uid] = os.clock() + 30
                            logRun("Lost the race for " .. best.label .. " (" .. lostWhy .. "), picking the next egg")
                            setStatus("Auto Best: egg taken by someone else, picking the next one")
                        else
                            recordSteal(ok and result == true, best.label, best.rate, os.clock() - t0)
                            if ok and result then
                                fails, failedUids = 0, {}
                                logRun("Delivered " .. best.label)
                                local limit = tonumber(cfg.steal.maxSteals) or 0
                                if limit > 0 and state.stats.runCount >= limit then
                                    local doneMsg = string.format("Auto Best: done, %d steals", state.stats.runCount)
                                    finish(doneMsg)
                                    if cfg.steal.notify then
                                        BPUI:Notify({
                                            Title = "Auto Best",
                                            Content = doneMsg,
                                            Type = "Success",
                                            Duration = 5,
                                        })
                                    end
                                    break
                                end
                                setStatus("Auto Best: delivered, finding next target")
                            else
                                stopMoving()
                                local trapped = Feat.recoverCarry(token, t0)
                                if not active(token) then
                                    break
                                end
                                local why = ok and "interrupted" or msg
                                if trapped then
                                    logRun("Trapped by a player trap (" .. why .. "), waiting for the release")
                                    setStatus("Auto Best: trapped, waiting for the release")
                                    local tt = os.clock()
                                    while active(token) and Feat.isTrapped() and os.clock() - tt < 10 do
                                        task.wait(0.25)
                                    end
                                    state.cooldownUntil = os.clock() + 2
                                else
                                    local long = why:find("pickup denied")
                                        or why:find("not deliverable")
                                        or why:find("would catch you")
                                    state.skipUntil[best.uid] = os.clock() + (long and 300 or 90)
                                    if not failedUids[best.uid] then
                                        failedUids[best.uid] = true
                                        fails += 1
                                    end
                                    logRun("Failed: " .. why)
                                    if why:find("correction") then
                                        local again = os.clock() - (state.lastCorrFail or -1e9) < 180
                                        state.lastCorrFail = os.clock()
                                        state.cooldownUntil = os.clock() + (again and 45 or 15)
                                    else
                                        state.cooldownUntil = os.clock() + math.min(10 * fails, 45)
                                    end
                                    if fails >= 4 then
                                        local stopMsg = "Auto Best stopped after 4 failed eggs in a row: " .. why
                                        finish(stopMsg)
                                        Feat.notifyFail("Auto Best", stopMsg)
                                        break
                                    end
                                    Feat.notifyFail("Auto Best", "Failed on " .. best.label .. ": " .. why)
                                    setStatus("Auto Best: " .. why)
                                end
                            end
                        end
                    end
                    task.wait(0.5)
                end
            end
        end)
        state.bestIdle = false
        if not okLoop and active(token) then
            logRun("Auto Best error: " .. firstLine(errLoop))
            finish("Stopped: internal error")
            Feat.cancelCarry()
            Feat.notifyFail("Auto Best", "Stopped: internal error (see Misc > Debug > Run Log)")
        end
    end)
    return true
end

state.walkToken = 0
local function walkAnywhere(pos, label, holdTrain)
    if state.running then
        BPUI:Notify({ Title = "Walk", Content = "Stop the steal first", Type = "Warning", Duration = 2 })
        return
    end
    if not pos then
        BPUI:Notify({ Title = "Walk", Content = tostring(label) .. " not found", Type = "Warning", Duration = 2 })
        return
    end
    state.walkToken += 1
    state.collectorToken = (state.collectorToken or 0) + 1
    state.collectPauseUntil = math.max(state.collectPauseUntil or 0, os.clock() + 6)
    if holdTrain and cfg.train.on then
        if state.trainPauseUntil ~= math.huge then
            BPUI:Notify({
                Title = "Auto Train",
                Content = "Paused. Toggle Auto Train to resume.",
                Type = "Info",
                Duration = 5,
            })
        end
        state.trainPauseUntil = math.huge
    end
    local my = state.walkToken
    task.spawn(function()
        leaveTreadmill(4)
        if state.walkToken ~= my or state.running then
            return
        end
        state.manualWalk = my
        setStatus("Walking to " .. label)
        setUserControls(false)
        local _, root, hum = charParts()
        local dist = root and (pos - root.Position).Magnitude or 0
        local ok = walkTo(pos, my, {
            tol = 4,
            timeout = math.max(60, dist / math.max(hum and hum.WalkSpeed or 16, 16) * 1.5 + 20),
            stillFn = function(t)
                return state.walkToken == t and not state.destroyed and not state.running
            end,
        })
        if state.manualWalk == my then
            state.manualWalk = nil
        end
        if holdTrain then
            state.collectPauseUntil = math.max(state.collectPauseUntil or 0, os.clock() + 30)
        end
        releaseControls()
        if not state.running then
            setStatus(ok and ("Arrived: " .. label) or ("Walk stopped: " .. label))
        end
    end)
end

local function safeZonePoint()
    local line = separationLine()
    local _, root = charParts()
    if not line then
        return nil
    end
    local z = root and math.clamp(root.Position.Z, line.Position.Z - 60, line.Position.Z + 60) or line.Position.Z
    return Vector3.new(line.Position.X - 14, 0, z)
end

function Feat.cancelCarry()
    local mode = cfg.steal.onCancel
    if mode == "Keep Carrying" or not state.carry then
        return
    end
    local uid = state.carry.uid
    local r = fieldRecord(uid)
    if not (r and r.State == "Carried" and r.CarrierUserId == lp.UserId) then
        return
    end
    if state.cancelDropUid == uid and os.clock() - (state.cancelDropAt or 0) < 2 then
        return
    end
    state.cancelDropUid, state.cancelDropAt = uid, os.clock()
    task.spawn(function()
        pcall(EggState.DropFieldEgg, "PlayerRequest")
    end)
    logRun("Cancelled while carrying: dropped the egg")
    if mode == "Drop Egg + Walk to Safe Zone" then
        task.delay(0.4, function()
            if not state.running and not state.destroyed then
                walkAnywhere(safeZonePoint(), "Safe Zone")
            end
        end)
    end
end

function Feat.walkHomeIfInField()
    local line = separationLine()
    local _, root = charParts()
    if line and root and root.Position.X > line.Position.X - 10 and not state.running then
        walkAnywhere(safeZonePoint(), "Safe Zone")
    end
end

local autoConns = {}
Feat.autoBusy = {}
local function autoLoop(name, interval, fn)
    if autoConns[name] then
        autoConns[name].stop()
        autoConns[name] = nil
    end
    autoConns[name] = H.task(function()
        if not cfg.auto[name] or state.destroyed or Feat.autoBusy[name] then
            return
        end
        Feat.autoBusy[name] = true
        pcall(fn)
        Feat.autoBusy[name] = nil
    end, interval, 0.1)
end

function Feat.stopAuto(name)
    if autoConns[name] then
        autoConns[name].stop()
        autoConns[name] = nil
    end
end

function Feat.ownedEgg(uid, sv)
    local raw = sv and sv.EggInventory and sv.EggInventory[uid]
    if not raw then
        return nil
    end
    local okD, egg = pcall(EggRecords.Decode, raw)
    if not (okD and type(egg) == "table") then
        return nil
    end
    local cat = egg.AssetCategory or raw.AssetCategory
    if cat == nil then
        return nil
    end
    local _, rank = eggRarity({ AssetCategory = cat })
    local okR, rate = pcall(function()
        return AssetEarnings.RatePerSecond(EggRecords.ToAssetItemData(egg))
    end)
    local muts = egg.Mutations or raw.Mutations
    return {
        cat = cat,
        rank = rank,
        rate = okR and tonumber(rate) or nil,
        mutated = (type(muts) == "table" and #muts > 0) or (egg.BaseMutation or raw.BaseMutation) ~= nil,
    }
end

function Feat.hatchFilterOn()
    local h = cfg.hatch
    return (Feat.RARITY_RANKS[h.minRarity] or 0) > 0
        or (tonumber(h.minValue) or 0) > 0
        or #asList(h.specific) > 0
        or (h.mutMode or "Any") ~= "Any"
        or Feat.nameMatch(h.match, "") ~= nil
end

function Feat.passesHatch(e, rift)
    if not Feat.hatchFilterOn() then
        return true
    end
    if not e then
        return false
    end
    if rift and rift[e.cat] then
        return true
    end
    local h = cfg.hatch
    if e.rank < (Feat.RARITY_RANKS[h.minRarity] or 0) then
        return false
    end
    local minVal = tonumber(h.minValue) or 0
    if minVal > 0 and (e.rate == nil or e.rate < minVal) then
        return false
    end
    local spec = asList(h.specific)
    if #spec > 0 and not table.find(spec, e.cat) then
        return false
    end
    if h.mutMode == "Mutated Only" and not e.mutated then
        return false
    end
    if h.mutMode == "Unmutated Only" and e.mutated then
        return false
    end
    return Feat.nameMatch(h.match, e.cat) ~= false
end

function Feat.maxPlaced()
    if not Feat.MAX_PLACED then
        local ok, n = pcall(function()
            return require(rep.Shared.Flags.GameplayBalance).EggInventory.MAX_PLACED_EGGS
        end)
        Feat.MAX_PLACED = ok and tonumber(n) or 30
    end
    return Feat.MAX_PLACED
end

function Feat.autoPlace()
    local plot = PlotState.ResolvePlot()
    local area = plot and plot.PetArea
    local center = plot and plot.CenterPoint
    if not area or not center then
        return
    end
    local eggs = EggState.ReadOwnerEggs(lp.UserId) or {}
    local placed, unplaced = {}, {}
    for uid, egg in pairs(eggs) do
        if egg.Placement and egg.Placement.LocalCFrame then
            table.insert(placed, (center.CFrame * egg.Placement.LocalCFrame).Position)
        else
            table.insert(unplaced, uid)
        end
    end
    if #unplaced == 0 then
        return
    end
    if #placed >= Feat.maxPlaced() then
        if not state.plotFullWarned then
            state.plotFullWarned = true
            local msg = string.format("Your plot is full (%d eggs), Auto Place waits for a hatch.", #placed)
            if cfg.auto.hatch and Feat.hatchFilterOn() then
                msg = msg
                    .. " Placed eggs below the Hatch filter never hatch: pick them up in the game or lower the filter."
            end
            logRun("Auto Place: " .. msg)
            BPUI:Notify({ Title = "Auto Place", Content = msg, Type = "Warning", Duration = 6 })
        end
        return
    end
    state.plotFullWarned = nil
    local getSave = Save and (Save.Peek or Save.Get)
    local sv = getSave and getSave()
    local p = cfg.place
    local minPlaceRank = Feat.RARITY_RANKS[p.minRarity] or 0
    local minPlaceVal = tonumber(p.minValue) or 0
    local onlyCats = asList(p.cats)
    local useHatch = cfg.auto.hatch and Feat.hatchFilterOn()
    local rift = (p.rift == true or (useHatch and cfg.hatch.rift == true)) and Feat.riftSet() or nil
    local hatchRift = cfg.hatch.rift == true and rift or nil
    local filtered = useHatch or minPlaceRank > 0 or minPlaceVal > 0 or #onlyCats > 0
    local cands = {}
    for _, u in ipairs(unplaced) do
        local e = Feat.ownedEgg(u, sv)
        local first = e ~= nil and p.rift == true and rift ~= nil and rift[e.cat] == true
        local ok = e == nil and not filtered
        if e then
            ok = first
                or (
                    e.rank >= minPlaceRank
                    and (minPlaceVal <= 0 or (e.rate or 0) >= minPlaceVal)
                    and (#onlyCats == 0 or table.find(onlyCats, e.cat) ~= nil)
                )
            if ok and useHatch and not Feat.passesHatch(e, hatchRift) then
                ok = false
            end
        end
        if ok then
            cands[#cands + 1] = { uid = u, rate = e and (e.rate or 0) or -1, rank = e and e.rank or -1, first = first }
        end
    end
    if #cands == 0 then
        return
    end
    local order = p.order or "Highest Value"
    table.sort(cands, function(a, b)
        if a.first ~= b.first then
            return a.first
        end
        if (a.rate < 0) ~= (b.rate < 0) then
            return b.rate < 0
        end
        if order == "Rarity" and a.rank ~= b.rank then
            return a.rank > b.rank
        end
        if a.rate ~= b.rate then
            if order == "Lowest Value" then
                return a.rate < b.rate
            end
            return a.rate > b.rate
        end
        return a.uid < b.uid
    end)
    local uid = cands[1].uid
    local candidates = {}
    for x = -area.Size.X / 2 + 4, area.Size.X / 2 - 4, 5 do
        for z = -area.Size.Z / 2 + 4, area.Size.Z / 2 - 4, 5 do
            local world = (area.CFrame * CFrame.new(x, 0.025, z)).Position
            local clear = true
            for _, p2 in ipairs(placed) do
                if (Vector3.new(world.X, 0, world.Z) - Vector3.new(p2.X, 0, p2.Z)).Magnitude < 5 then
                    clear = false
                    break
                end
            end
            if clear then
                table.insert(candidates, world)
            end
        end
    end
    if #candidates == 0 then
        return
    end
    if (state.placeBackoffUntil or 0) > os.clock() then
        return
    end
    local cursor = state.placeCursor or 1
    for attempt = 1, math.min(3, #candidates) do
        if not cfg.auto.place then
            return
        end
        local idx = (cursor + attempt - 2) % #candidates + 1
        local localCF = center.CFrame:ToObjectSpace(CFrame.new(candidates[idx]))
        local ok, success = pcall(EggState.PlantEgg, uid, localCF)
        if ok and success then
            state.placeCursor = idx + 1
            return
        end
        task.wait(0.15)
    end
    state.placeCursor = (cursor + 3 - 1) % #candidates + 1
    state.placeBackoffUntil = os.clock() + 60
end

function Feat.autoHatch()
    local eggs = EggState.ReadOwnerEggs(lp.UserId) or {}
    local getSave = Save and (Save.Peek or Save.Get)
    local sv = getSave and getSave() or nil
    if not sv and Feat.hatchFilterOn() then
        return
    end
    local rift = cfg.hatch.rift == true and Feat.riftSet() or nil
    local ready = {}
    for uid in pairs(eggs) do
        if EggState.IsReadyToHatch(uid) then
            local e = sv and Feat.ownedEgg(uid, sv)
            if Feat.passesHatch(e, rift) then
                ready[#ready + 1] = { uid = uid, first = e and rift and rift[e.cat] == true or false }
            end
        end
    end
    table.sort(ready, function(a, b)
        return a.first and not b.first
    end)
    for _, r in ipairs(ready) do
        if not cfg.auto.hatch or state.destroyed then
            return
        end
        local began = EggState.BeginHatch(r.uid)
        if not began then
            return
        end
        for attempt = 1, 6 do
            task.wait(attempt == 1 and 0.5 or 1)
            local finished = EggState.FinishHatch(r.uid)
            if finished then
                break
            end
        end
    end
end

function Feat.autoSell(kind)
    local s = cfg.sell
    local pets = kind == "sellPets"
    local limit = tonumber(pets and s.petLimit or s.eggLimit) or 0
    local keepRank = Feat.RARITY_RANKS[s.keepRarity] or 0
    local byRarity = (pets and s.petRule or s.eggRule) == "Rarity"
    if byRarity then
        if keepRank <= 1 then
            return 0, "the Rarity rule needs 'Never Sell Rarity' set above Common"
        end
    elseif limit <= 0 then
        return 0, "no sell limit set"
    end
    local getSave = Save and (Save.Peek or Save.Get)
    local save = getSave and getSave()
    if not save then
        return 0, "save data not ready"
    end
    local idx = s.keepIndex ~= false and type(save.Index) == "table" and save.Index or nil
    if s.keepIndex ~= false and not idx then
        return 0, "Index data not ready"
    end
    local equipped, never = {}, {}
    for _, uid in ipairs(save.EquippedAssets or {}) do
        equipped[uid] = true
    end
    for _, id in ipairs(asList(s.neverCats)) do
        never[id] = true
    end
    local rift = s.keepRift ~= false and Feat.riftSet() or {}
    local function keep(cat, muts, base)
        if cat == nil then
            return true
        end
        if s.keepMutated ~= false and ((type(muts) == "table" and #muts > 0) or base ~= nil) then
            return true
        end
        if keepRank > 0 and select(2, eggRarity({ AssetCategory = cat })) >= keepRank then
            return true
        end
        if rift[cat] == true or never[cat] or (idx and idx[cat] ~= true) then
            return true
        end
        return Feat.nameMatch(s.keepMatch, cat) == true
    end
    local function sellable(ok, rate)
        return byRarity or (ok and tonumber(rate) ~= nil and rate <= limit)
    end
    local selected = {}
    if pets then
        for uid, raw in pairs(save.Inventory or {}) do
            if
                not equipped[uid]
                and not raw.IsFavorite
                and not raw.InFuse
                and not keep(raw.Category, raw.Mutations, raw.BaseMutation)
            then
                if sellable(pcall(AssetEarnings.RatePerSecond, raw)) then
                    table.insert(selected, uid)
                end
            end
        end
    else
        for uid, raw in pairs(save.EggInventory or {}) do
            if raw.Placement == nil then
                local ok, egg = pcall(EggRecords.Decode, raw)
                if
                    ok
                    and type(egg) == "table"
                    and not keep(
                        egg.AssetCategory or raw.AssetCategory,
                        egg.Mutations or raw.Mutations,
                        egg.BaseMutation or raw.BaseMutation
                    )
                then
                    if
                        sellable(pcall(function()
                            return AssetEarnings.RatePerSecond(EggRecords.ToAssetItemData(egg))
                        end))
                    then
                        table.insert(selected, uid)
                    end
                end
            end
        end
    end
    if #selected == 0 then
        return 0, nil
    end
    for i = 1, #selected, 512 do
        local chunk = table.move(selected, i, math.min(i + 511, #selected), 1, {})
        pcall(function()
            Remotes.PetSatchel.SellSelection:FireServer({ Assets = pets and chunk or {}, Eggs = pets and {} or chunk })
        end)
    end
    task.wait(1.5)
    local after = getSave and getSave()
    local bag = type(after) == "table" and (pets and after.Inventory or after.EggInventory) or nil
    local gone = 0
    for _, uid in ipairs(selected) do
        if type(bag) == "table" and bag[uid] == nil then
            gone += 1
        end
    end
    if gone > 0 then
        logRun(string.format("Auto Sell: sold %d of %d %s", gone, #selected, pets and "pets" or "eggs"))
    end
    return gone, gone < #selected and string.format("the server kept %d of %d", #selected - gone, #selected) or nil
end

function Feat.sellTick(kind)
    local _, why = Feat.autoSell(kind)
    state.sellWhy = state.sellWhy or {}
    if why and why ~= state.sellWhy[kind] then
        logRun("Auto Sell " .. (kind == "sellPets" and "Pets" or "Eggs") .. ": " .. why)
    end
    state.sellWhy[kind] = why
end

function Feat.rarityList()
    local byId, list = {}, {}
    pcall(function()
        for _, d in pairs(Assets.Directory) do
            local r = type(d) == "table" and d.Rarity
            if type(r) == "table" and type(r._id) == "string" and not byId[r._id] then
                byId[r._id] = true
                list[#list + 1] = {
                    id = r._id,
                    name = type(r.DisplayName) == "string" and r.DisplayName or r._id,
                    rank = tonumber(r.Rank) or 0,
                }
            end
        end
    end)
    table.sort(list, function(a, b)
        if a.rank ~= b.rank then
            return a.rank < b.rank
        end
        return a.name < b.name
    end)
    return list
end

function Feat.setGameAutoSell(ids)
    local rf = Remotes and Remotes.Haul and Remotes.Haul.WriteAutoSell
    if not rf then
        return false, "Auto Sell remote not found"
    end
    local map = {}
    for _, id in ipairs(ids) do
        map[id] = true
    end
    local okP, ok, res = pcall(function()
        return rf:InvokeServer(map)
    end)
    if not okP then
        return false, firstLine(ok)
    end
    if not ok then
        return false, tostring(res or "the server refused")
    end
    return true, res
end

function Feat.autoEquip()
    pcall(function()
        Remotes.Haul.WearBest:InvokeServer()
    end)
end

local function cancel()
    if state.running then
        finish("Cancelled")
        Feat.cancelCarry()
    end
    state.walkToken += 1
    state.collectorToken = (state.collectorToken or 0) + 1
    state.collectPauseUntil = os.clock() + 15
    state.manualWalk = nil
    state.trainPauseUntil = os.clock() + 5
    stopMoving()
    releaseControls()
end

function Feat.stopWalk()
    state.walkToken += 1
    state.collectorToken = (state.collectorToken or 0) + 1
    state.collectPauseUntil = os.clock() + 15
    if state.running then
        return
    end
    local held = cfg.train.on == true
    if held then
        state.trainPauseUntil = math.huge
    end
    state.manualWalk = nil
    stopMoving()
    releaseControls()
    setStatus(held and "Walk stopped (Auto Train paused, toggle it to resume)" or "Walk stopped")
end

function Feat.userCancel(msg)
    cancel()
    local trainWasOn = cfg.train.on == true
    if trainWasOn then
        cfg.train.on = false
        state.trainToken = (state.trainToken or 0) + 1
        if state.trainTog then
            Feat.ui(function()
                state.trainTog:Set(false, true)
            end)
        end
        C.save()
    end
    setStatus((msg or "Cancelled") .. (trainWasOn and " (Auto Train turned off)" or ""))
end

function Feat.guiParent()
    local gp = Feat._guiParent
    if gp and gp.Parent then
        return gp
    end
    local okH, h = pcall(function()
        return gethui and gethui()
    end)
    if okH and typeof(h) == "Instance" then
        gp = h
    else
        gp = game:GetService("CoreGui")
    end
    Feat._guiParent = gp
    return gp
end

local Esp = { nodes = {}, pool = {}, want = {}, list = {}, cursor = 1, dirty = true, scanAt = 0, infoBusy = false }
Feat.Esp = Esp

Esp.defaults = {
    textSize = 11,
    width = 230,
    offset = 0,
    font = "GothamBold",
    backgroundTransparency = 0.25,
    outlineTransparency = 0.65,
    alwaysOnTop = true,
    showDistance = true,
    showArea = true,
    showRarity = true,
    showRate = true,
    showDetails = true,
    displayNames = true,
    statusColors = true,
    maxLabels = 80,
    scanInterval = 0.25,
    renderInterval = 0,
    colors = {
        background = "0C0E14",
        egg = "54E0FF",
        guard = "FFAA3C",
        trap = "FF78DC",
        player = "FFC850",
        safe = "6EFF8C",
        warning = "FFD250",
        danger = "FF5F5F",
    },
}
function Esp.normalizeOptions()
    if type(cfg.esp.appearance) ~= "table" then
        cfg.esp.appearance = {}
    end
    local options = cfg.esp.appearance
    for key, value in pairs(Esp.defaults) do
        if key ~= "colors" and type(options[key]) ~= type(value) then
            options[key] = value
        end
    end
    if type(options.colors) ~= "table" then
        options.colors = {}
    end
    for key, value in pairs(Esp.defaults.colors) do
        if type(options.colors[key]) ~= "string" then
            options.colors[key] = value
        end
    end
    return options
end
Esp.normalizeOptions()
Esp.styleRevision = 0
Esp.renderAt = 0
Esp.fonts = {
    GothamBold = Enum.Font.GothamBold,
    Gotham = Enum.Font.Gotham,
    SourceSans = Enum.Font.SourceSans,
    Code = Enum.Font.Code,
}
function Esp.number(key, fallback, minimum, maximum)
    local value = tonumber(cfg.esp.appearance[key])
    if not value or value ~= value then
        value = fallback
    end
    return math.clamp(value, minimum, maximum)
end
function Esp.hex(value)
    if type(value) ~= "string" then
        return nil
    end
    return value:match("^%s*#?(%x%x%x%x%x%x)%s*$")
end
function Esp.color(key, fallback)
    if Esp.paletteRevision ~= Esp.styleRevision then
        Esp.palette = {}
        Esp.paletteRevision = Esp.styleRevision
    end
    if not Esp.palette[key] then
        local hex = Esp.hex(cfg.esp.appearance.colors[key])
        Esp.palette[key] = hex
                and Color3.fromRGB(
                    tonumber(hex:sub(1, 2), 16),
                    tonumber(hex:sub(3, 4), 16),
                    tonumber(hex:sub(5, 6), 16)
                )
            or fallback
    end
    return Esp.palette[key]
end
function Esp.changed()
    Esp.styleRevision += 1
    Esp.dirty = true
    Esp.renderAt = 0
    C.save()
end
function Esp.head(name, area, distance)
    local options = cfg.esp.appearance
    local text = name
    if area and options.showArea ~= false then
        text ..= " | " .. tostring(area)
    end
    if options.showDistance ~= false then
        text ..= " | " .. tostring(distance) .. " st"
    end
    return text
end
local ESP_BG = Color3.fromRGB(12, 14, 20)
local C_CYAN, C_GREEN, C_YELLOW, C_RED =
    Color3.fromRGB(84, 224, 255),
    Color3.fromRGB(110, 255, 140),
    Color3.fromRGB(255, 210, 80),
    Color3.fromRGB(255, 95, 95)
local C_ORANGE, C_PINK, C_GOLD, C_PURPLE =
    Color3.fromRGB(255, 170, 60),
    Color3.fromRGB(255, 120, 220),
    Color3.fromRGB(255, 200, 80),
    Color3.fromRGB(200, 140, 255)
local C_CARRY = Color3.fromRGB(255, 110, 70)
local OFF_EGG, OFF_GUARD, OFF_TRAP, OFF_PLR =
    Vector3.new(0, 2.6, 0), Vector3.new(0, 3, 0), Vector3.new(0, 2.5, 0), Vector3.new(0, 3, 0)

local function espAny()
    return cfg.esp.eggs or cfg.esp.guards or cfg.esp.traps or cfg.esp.players
end

local function espFolder()
    local playerGui = lp:FindFirstChildOfClass("PlayerGui")
    if not playerGui then
        error("ESP: PlayerGui is not ready")
    end
    local folder = Esp.folder
    if not folder or folder.Parent ~= playerGui then
        folder = Instance.new("Folder")
        folder.Name = "BPHUB_ESP"
        folder.Parent = playerGui
        Esp.folder = folder
        for _, node in pairs(Esp.nodes) do
            if node.gui.Parent then
                node.gui.Parent = folder
            end
        end
        for _, node in ipairs(Esp.pool) do
            if node.gui.Parent then
                node.gui.Parent = folder
            end
        end
    end
    return folder
end

function Esp.worldAnchor(node, position)
    if not Esp.anchors or not Esp.anchors:IsDescendantOf(workspace) then
        local folder = Instance.new("Folder")
        folder.Name = "BPHUB_ESP_Anchors"
        folder.Parent = workspace
        Esp.anchors = folder
    end
    local anchor = node.anchor
    if not anchor or not anchor:IsDescendantOf(workspace) then
        anchor = Instance.new("Part")
        anchor.Name = "ESPAnchor"
        anchor.Anchored = true
        anchor.CanCollide = false
        anchor.CanTouch = false
        anchor.CanQuery = false
        anchor.CastShadow = false
        anchor.Transparency = 1
        anchor.Size = Vector3.new(0.1, 0.1, 0.1)
        anchor.Parent = Esp.anchors
        node.anchor = anchor
    end
    anchor.Position = position
    return anchor
end

local function newNode()
    local n = table.remove(Esp.pool)
    if n then
        if n.gui:IsDescendantOf(game) then
            return n
        end
        pcall(function()
            n.gui:Destroy()
            if n.anchor then
                n.anchor:Destroy()
                n.anchor = nil
            end
        end)
    end
    local gui = Instance.new("BillboardGui")
    gui.Name = "ESPLabel"
    gui.AlwaysOnTop = true
    gui.MaxDistance = math.huge
    gui.LightInfluence = 0
    gui.ClipsDescendants = false
    gui.Enabled = false
    gui.Size = UDim2.fromOffset(230, 24)
    pcall(function()
        gui.ResetOnSpawn = false
    end)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.fromScale(1, 1)
    lbl.BackgroundColor3 = ESP_BG
    lbl.BackgroundTransparency = 0.25
    lbl.BorderSizePixel = 0
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextStrokeTransparency = 0.65
    lbl.TextTruncate = Enum.TextTruncate.AtEnd
    lbl.Parent = gui
    Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 6)
    gui.Parent = espFolder()
    return { gui = gui, label = lbl }
end

local function freeNode(n)
    pcall(function()
        n.gui.Enabled = false
        n.gui.Adornee = nil
    end)
    n.ad, n.off, n.text, n.color, n.h, n.width, n.styleRevision = nil, nil, nil, nil, nil, nil, nil
    if n.gui:IsDescendantOf(game) and #Esp.pool < 60 then
        Esp.pool[#Esp.pool + 1] = n
    else
        pcall(function()
            n.gui:Destroy()
            if n.anchor then
                n.anchor:Destroy()
                n.anchor = nil
            end
        end)
    end
end

local function apply(n, ad, off, text, color, h)
    local gui = n.gui
    local options = cfg.esp.appearance
    local textSize = Esp.number("textSize", 11, 8, 28)
    local width = math.floor(Esp.number("width", 230, 120, 500) * textSize / 11)
    local opacity = Esp.number("opacity", 100, 0, 100) / 100
    if n.styleRevision ~= Esp.styleRevision then
        gui.AlwaysOnTop = options.alwaysOnTop ~= false
        n.label.TextSize = textSize
        n.label.Font = Esp.fonts[options.font] or Enum.Font.GothamBold
        n.label.BackgroundColor3 = Esp.color("background", ESP_BG)
        n.label.TextTransparency = 1 - opacity
        n.label.BackgroundTransparency = 1 - (1 - Esp.number("backgroundTransparency", 0.25, 0, 1)) * opacity
        n.label.TextStrokeTransparency = 1 - (1 - Esp.number("outlineTransparency", 0.65, 0, 1)) * opacity
        n.extraOffset = Vector3.new(0, Esp.number("offset", 0, -10, 20), 0)
        n.styleRevision = Esp.styleRevision
    end
    off += n.extraOffset
    h = text:find("\n", 1, true) and (textSize * 2 + 16) or (textSize + 13)
    if n.ad ~= ad then
        gui.Adornee = ad
        n.ad = ad
    end
    if n.off ~= off then
        gui.StudsOffsetWorldSpace = off
        n.off = off
    end
    if n.text ~= text then
        n.label.Text = text
        n.text = text
    end
    if Esp.hex(cfg.esp.appearance.colors.text) then
        color = Esp.color("text", color)
    end
    if n.color ~= color then
        n.label.TextColor3 = color
        n.color = color
    end
    if n.h ~= h or n.width ~= width then
        gui.Size = UDim2.fromOffset(width + (text:find("\n", 1, true) and 10 or 0), h)
        n.h, n.width = h, width
    end
    if not gui.Enabled then
        gui.Enabled = true
    end
end

local function rd(d)
    if d < 100 then
        return math.floor(d + 0.5)
    end
    return math.floor(d / 5 + 0.5) * 5
end

local function render(n, src, me)
    local kind = src.kind
    if kind == "egg" then
        local rec = src.rec
        local ei = state.eggInfo and state.eggInfo[rec.Uid] or src.ei
        local d = me and (src.pos - me).Magnitude or src.d
        local text = Esp.head(Feat.eggTitle(rec), rec.AreaId, rd(d))
        local options = cfg.esp.appearance
        if ei then
            local details = {}
            if options.showRarity ~= false then
                details[#details + 1] = tostring(ei.rarity)
            end
            if options.showRate ~= false then
                details[#details + 1] = "$" .. shortNum(ei.rate) .. "/s"
            end
            if options.showDetails ~= false then
                details[#details + 1] = string.upper(tostring(ei.class))
            end
            if #details > 0 then
                text ..= "\n" .. table.concat(details, " | ")
            end
        end
        local cl = ei and ei.class
        local color = Esp.color("egg", C_CYAN)
        if options.statusColors ~= false then
            color = ((cl == "clean" or cl == "noguard") and Esp.color("safe", C_GREEN))
                or (cl == "relay" and Esp.color("warning", C_YELLOW))
                or (cl == "blocked" and Esp.color("danger", C_RED))
                or color
        end
        if src.hb and src.hb.Parent then
            apply(n, src.hb, OFF_EGG, text, color, ei and 38 or 24)
        else
            apply(n, Esp.worldAnchor(n, src.pos), OFF_EGG, text, color, ei and 38 or 24)
        end
    elseif kind == "guard" then
        local g, gRoot = src.g, src.root
        if not gRoot.Parent then
            return
        end
        local gState = tostring(g:GetAttribute("GuardState") or "?")
        local target = g:GetAttribute("TargetPlayer")
        local d = me and (gRoot.Position - me).Magnitude or src.d
        local name = "Guard"
        if cfg.esp.appearance.showDetails ~= false then
            name ..= " | " .. string.upper(gState)
            if type(target) == "string" and target ~= "" then
                name ..= " > " .. target
            end
        end
        local text = Esp.head(name, src.area, rd(d))
        local color = Esp.color("guard", C_ORANGE)
        if cfg.esp.appearance.statusColors ~= false then
            color = (gState == "Sleeping" and Esp.color("safe", C_GREEN))
                or (gState == "Chasing" and Esp.color("danger", C_RED))
                or color
        end
        apply(n, gRoot, OFF_GUARD, text, color, 24)
    elseif kind == "trap" then
        local t = src.part
        if not t.Parent then
            return
        end
        local owner = t:GetAttribute("Owner")
        local mine = owner == lp.Name
        local d = me and (t.Position - me).Magnitude or src.d
        local name = "Trap"
        if cfg.esp.appearance.showDetails ~= false then
            name ..= " | " .. (mine and "yours" or tostring(owner or "?"))
            if t:GetAttribute("TrapActive") == true then
                name ..= " | TRIGGERED"
            end
        end
        local color = Esp.color("trap", C_PINK)
        if mine and cfg.esp.appearance.statusColors ~= false then
            color = Esp.color("safe", C_GREEN)
        end
        apply(n, t, OFF_TRAP, Esp.head(name, nil, rd(d)), color, 24)
    elseif kind == "player" then
        local pRoot = src.root
        if not pRoot.Parent then
            return
        end
        local d = me and (pRoot.Position - me).Magnitude or src.d
        local rec, trapped = src.rec, src.chr:GetAttribute("IsTrapped") == true
        local extra = {}
        if rec and cfg.esp.appearance.showDetails ~= false then
            local okT, title = pcall(Feat.eggTitle, rec)
            local okR, rate = pcall(displayRate, rec)
            extra[#extra + 1] =
                string.format("CARRYING %s $%s/s", okT and tostring(title) or "egg", shortNum(okR and rate or 0))
        end
        if trapped and cfg.esp.appearance.showDetails ~= false then
            extra[#extra + 1] = "TRAPPED"
        end
        local name = cfg.esp.appearance.displayNames ~= false and src.p.DisplayName or src.p.Name
        local text = Esp.head(name, nil, rd(d)) .. (#extra > 0 and ("\n" .. table.concat(extra, " | ")) or "")
        local color = Esp.color("player", C_GOLD)
        if cfg.esp.appearance.statusColors ~= false then
            color = (trapped and C_PURPLE) or (rec and C_CARRY) or color
        end
        apply(n, pRoot, OFF_PLR, text, color, #extra > 0 and 38 or 24)
    end
end

function Esp.basicApply(n, ad, off, text, color, h)
    local gui = n.gui
    if n.ad ~= ad then
        gui.Adornee = ad
        n.ad = ad
    end
    if n.off ~= off then
        gui.StudsOffsetWorldSpace = off
        n.off = off
    end
    if n.text ~= text then
        n.label.Text = text
        n.text = text
    end
    if Esp.hex(cfg.esp.appearance.colors.text) then
        color = Esp.color("text", color)
    end
    if n.color ~= color then
        n.label.TextColor3 = color
        n.color = color
    end
    if n.h ~= h then
        gui.Size = UDim2.fromOffset(h > 26 and 240 or 230, h)
        n.h = h
    end
    if not gui.Enabled then
        gui.Enabled = true
    end
end

function Esp.basicRender(n, src, me)
    local kind = src.kind
    if kind == "egg" then
        local rec = src.rec
        local ei = state.eggInfo and state.eggInfo[rec.Uid] or src.ei
        local d = me and (src.pos - me).Magnitude or src.d
        local text = string.format("%s | %s | %d st", Feat.eggTitle(rec), tostring(rec.AreaId), rd(d))
        if ei then
            text = text
                .. string.format(
                    "\n%s | $%s/s | %s",
                    tostring(ei.rarity),
                    shortNum(ei.rate),
                    string.upper(tostring(ei.class))
                )
        end
        local cl = ei and ei.class
        local color = ((cl == "clean" or cl == "noguard") and C_GREEN)
            or (cl == "relay" and C_YELLOW)
            or (cl == "blocked" and C_RED)
            or C_CYAN
        if src.hb and src.hb.Parent then
            Esp.basicApply(n, src.hb, OFF_EGG, text, color, ei and 38 or 24)
        else
            Esp.basicApply(n, Esp.worldAnchor(n, src.pos), OFF_EGG, text, color, ei and 38 or 24)
        end
    elseif kind == "guard" then
        local g, gRoot = src.g, src.root
        if not gRoot.Parent then
            return
        end
        local gState = tostring(g:GetAttribute("GuardState") or "?")
        local target = g:GetAttribute("TargetPlayer")
        local d = me and (gRoot.Position - me).Magnitude or src.d
        local text = string.format(
            "Guard | %s | %s%s | %d st",
            src.area,
            string.upper(gState),
            (type(target) == "string" and target ~= "") and (" > " .. target) or "",
            rd(d)
        )
        local color = (gState == "Sleeping" and C_GREEN) or (gState == "Chasing" and C_RED) or C_ORANGE
        Esp.basicApply(n, gRoot, OFF_GUARD, text, color, 24)
    elseif kind == "trap" then
        local t = src.part
        if not t.Parent then
            return
        end
        local owner = t:GetAttribute("Owner")
        local mine = owner == lp.Name
        local d = me and (t.Position - me).Magnitude or src.d
        local text = string.format(
            "Trap | %s%s | %d st",
            mine and "yours" or tostring(owner or "?"),
            t:GetAttribute("TrapActive") == true and " | TRIGGERED" or "",
            rd(d)
        )
        Esp.basicApply(n, t, OFF_TRAP, text, mine and C_GREEN or C_PINK, 24)
    elseif kind == "player" then
        local pRoot = src.root
        if not pRoot.Parent then
            return
        end
        local d = me and (pRoot.Position - me).Magnitude or src.d
        local rec, trapped = src.rec, src.chr:GetAttribute("IsTrapped") == true
        local extra = {}
        if rec then
            local okT, title = pcall(Feat.eggTitle, rec)
            local okR, rate = pcall(displayRate, rec)
            extra[#extra + 1] =
                string.format("CARRYING %s $%s/s", okT and tostring(title) or "egg", shortNum(okR and rate or 0))
        end
        if trapped then
            extra[#extra + 1] = "TRAPPED"
        end
        local text = string.format("%s | %d st", src.p.DisplayName, rd(d))
            .. (#extra > 0 and ("\n" .. table.concat(extra, " | ")) or "")
        Esp.basicApply(
            n,
            pRoot,
            OFF_PLR,
            text,
            (trapped and C_PURPLE) or (rec and C_CARRY) or C_GOLD,
            #extra > 0 and 38 or 24
        )
    end
end

function Esp.reportError(stage, message)
    local text = stage .. ": " .. tostring(message)
    Esp.lastError = text
    local now = os.clock()
    if text ~= Esp.reportedError or now - (Esp.errorAt or 0) >= 10 then
        Esp.reportedError, Esp.errorAt = text, now
        warn("[BPHUB ESP] " .. text)
        logRun("ESP error: " .. text)
    end
end
function Esp.renderNode(node, source, position)
    local ok, err = pcall(render, node, source, position)
    if ok then
        return true
    end
    Esp.reportError("Custom label", err)
    node.styleRevision, node.width = nil, nil
    local fallbackOk, fallbackError = pcall(Esp.basicRender, node, source, position)
    if not fallbackOk then
        Esp.reportError("Basic label", fallbackError)
    end
    return fallbackOk
end

local function collect()
    local _, root = charParts()
    if not root then
        return
    end
    local me = root.Position
    local range = cfg.esp.range
    local want, cand = {}, {}
    local function add(key, src, pos)
        local d = (pos - me).Magnitude
        if d > range then
            return
        end
        src.d, src.pos = d, pos
        want[key] = src
        cand[#cand + 1] = key
    end
    local recs = {}
    if cfg.esp.eggs or cfg.esp.players then
        local ok, r = pcall(function()
            return EggState.ReadFieldEggs().Records
        end)
        if ok and type(r) == "table" then
            recs = r
        end
    end
    if cfg.esp.eggs then
        local age = os.clock() - (state.eggInfoAt or 0)
        if not Esp.infoBusy and (age > 10 or (Esp.eggEvt and age > 2)) then
            Esp.infoBusy, Esp.eggEvt = true, false
            task.spawn(function()
                pcall(refreshEggs, true)
                Esp.infoBusy = false
            end)
        end
        local einfo = state.eggInfo or {}
        local folder = workspace:FindFirstChild("AreaEggSlotsClient")
        for _, rec in ipairs(recs) do
            local ei = einfo[rec.Uid]
            if
                isAvailable(rec)
                and (cfg.esp.useFilter == false or state.eggInfoAt == nil or (ei ~= nil and ei.passes))
            then
                local pos = eggPosition(rec)
                if pos then
                    local model = folder and folder:FindFirstChild(rec.Uid)
                    local hb = model and model:FindFirstChild("Hitbox")
                    if hb and not (hb:IsA("BasePart") and (hb.Position - pos).Magnitude < 0.5) then
                        hb = nil
                    end
                    add("egg:" .. rec.Uid, { kind = "egg", rec = rec, ei = ei, hb = hb }, pos)
                end
            end
        end
    end
    if cfg.esp.guards then
        local areas3 = getAreas()
        local gAreas = areas3 and areas3:FindFirstChild("GuardAreas")
        if gAreas then
            for _, area in ipairs(gAreas:GetChildren()) do
                local g = area:FindFirstChild("Guard")
                local gRoot = g and g:FindFirstChild("HumanoidRootPart")
                if gRoot then
                    add(
                        "guard:" .. area.Name,
                        { kind = "guard", g = g, root = gRoot, area = area.Name },
                        gRoot.Position
                    )
                end
            end
        end
    end
    if cfg.esp.traps then
        Feat.trapKeys = Feat.trapKeys or setmetatable({}, { __mode = "k" })
        for _, t in ipairs(H.gs("CollectionService"):GetTagged("PlacedTrap")) do
            if t:IsA("BasePart") then
                local id = Feat.trapKeys[t]
                if not id then
                    Feat.trapSeq = (Feat.trapSeq or 0) + 1
                    id = Feat.trapSeq
                    Feat.trapKeys[t] = id
                end
                add("trap:" .. id, { kind = "trap", part = t }, t.Position)
            end
        end
    end
    if cfg.esp.players then
        local carried = {}
        for _, rec in ipairs(recs) do
            if rec.State == "Carried" and rec.CarrierUserId ~= nil then
                carried[rec.CarrierUserId] = rec
            end
        end
        for _, p in ipairs(H.gs("Players"):GetPlayers()) do
            local chr = p ~= lp and p.Character
            local pRoot = chr and chr:FindFirstChild("HumanoidRootPart")
            if pRoot then
                add(
                    "plr:" .. p.UserId,
                    { kind = "player", p = p, chr = chr, root = pRoot, rec = carried[p.UserId] },
                    pRoot.Position
                )
            end
        end
    end
    local maxLabels = math.floor(Esp.number("maxLabels", 80, 10, 200))
    if #cand > maxLabels then
        table.sort(cand, function(a, b)
            return want[a].d < want[b].d
        end)
        for i = #cand, maxLabels + 1, -1 do
            want[cand[i]] = nil
            cand[i] = nil
        end
    end
    Esp.want, Esp.list = want, cand
end

local function espSync(me)
    espFolder()
    local want = Esp.want
    for key, node in pairs(Esp.nodes) do
        if not want[key] or not node.gui:IsDescendantOf(game) then
            freeNode(node)
            Esp.nodes[key] = nil
        end
    end
    for _, key in ipairs(Esp.list) do
        if not Esp.nodes[key] and want[key] then
            local node = newNode()
            Esp.nodes[key] = node
            Esp.renderNode(node, want[key], me)
        end
    end
end

local function espGui(me, sync)
    if sync then
        espSync(me)
    end
    local list = Esp.list
    local n = #list
    if n == 0 then
        return
    end
    for _ = 1, math.min(n, math.max(8, math.ceil(n / 6))) do
        if Esp.cursor > n then
            Esp.cursor = 1
        end
        local key = list[Esp.cursor]
        Esp.cursor += 1
        local node, src = Esp.nodes[key], Esp.want[key]
        if node and src then
            Esp.renderNode(node, src, me)
        end
    end
end

local function espStep()
    if state.destroyed then
        return
    end
    local _, root = charParts()
    local me = root and root.Position
    local now = os.clock()
    local sync = false
    if (Esp.dirty and now - Esp.scanAt > 0.05) or now - Esp.scanAt > Esp.number("scanInterval", 0.25, 0.05, 2) then
        Esp.dirty = false
        Esp.scanAt = now
        local ok, err = pcall(collect)
        if not ok then
            Esp.reportError("Collect", err)
        end
        sync = true
    end
    if not sync and #Esp.list == 0 then
        return
    end
    if not sync and now - Esp.renderAt < Esp.number("renderInterval", 0, 0, 0.5) then
        return
    end
    Esp.renderAt = now
    local ok, err = pcall(espGui, me, sync)
    if not ok then
        Esp.reportError("Update", err)
    end
end

local function espDirty()
    Esp.dirty = true
end
local function espEggDirty()
    Esp.dirty = true
    Esp.eggEvt = true
end

local function startEsp()
    Esp.normalizeOptions()
    Esp.dirty, Esp.scanAt, Esp.renderAt = true, 0, 0
    if Esp.conn and Esp.conn.Connected then
        return
    end
    if Esp.conn then
        Esp.conn:Disconnect()
        Esp.conn = nil
    end
    Esp.conn = rs.Heartbeat:Connect(espStep)
    table.insert(conns, Esp.conn)
    local sigs = {}
    if EggState then
        for _, name in ipairs({
            "FieldShifted",
            "FieldGone",
            "FieldClaimed",
            "FieldRefreshed",
            "SnapshotRefreshed",
            "CarryChanged",
        }) do
            local s = EggState[name]
            if s then
                pcall(function()
                    sigs[#sigs + 1] = s:Connect(espEggDirty)
                end)
            end
        end
    end
    pcall(function()
        local cs = H.gs("CollectionService")
        sigs[#sigs + 1] = cs:GetInstanceAddedSignal("PlacedTrap"):Connect(espDirty)
        sigs[#sigs + 1] = cs:GetInstanceRemovedSignal("PlacedTrap"):Connect(espDirty)
    end)
    pcall(function()
        local plrs = H.gs("Players")
        sigs[#sigs + 1] = plrs.PlayerAdded:Connect(espDirty)
        sigs[#sigs + 1] = plrs.PlayerRemoving:Connect(espDirty)
    end)
    Esp.sigs = sigs
    for _, c in ipairs(sigs) do
        table.insert(conns, c)
    end
end

local function stopEsp(force)
    if not force and espAny() then
        Esp.dirty = true
        return
    end
    if Esp.conn then
        Esp.conn:Disconnect()
        Esp.conn = nil
    end
    for _, c in ipairs(Esp.sigs or {}) do
        pcall(function()
            c:Disconnect()
        end)
    end
    Esp.sigs = nil
    for key, node in pairs(Esp.nodes) do
        pcall(function()
            node.gui:Destroy()
        end)
        Esp.nodes[key] = nil
    end
    for _, node in ipairs(Esp.pool) do
        pcall(function()
            node.gui:Destroy()
        end)
    end
    table.clear(Esp.pool)
    if Esp.anchors then
        Esp.anchors:Destroy()
        Esp.anchors = nil
    end
    Esp.want, Esp.list, Esp.cursor = {}, {}, 1
    if Esp.folder then
        pcall(function()
            Esp.folder:Destroy()
        end)
        Esp.folder = nil
    end
end

local function updateEsp()
    Esp.dirty = true
end

local function netRF(p)
    return NET and NET:FindFirstChild("RF/" .. p)
end
local function netRE(p)
    return NET and NET:FindFirstChild("RE/" .. p)
end

function Feat.setNoclip(on)
    local wasOn = state.noclipConn ~= nil
    for _, key in ipairs({ "noclipConn", "noclipAddedConn", "noclipRemovedConn", "noclipCharacterConn" }) do
        local connection = state[key]
        if connection then
            connection:Disconnect()
            state[key] = nil
        end
    end
    state.noclipParts = nil
    if not on then
        if wasOn and state.noclipOrig then
            for part, old in pairs(state.noclipOrig) do
                if part.Parent then
                    pcall(function()
                        part.CanCollide = old
                    end)
                end
            end
        end
        state.noclipOrig = nil
        return
    end

    state.noclipOrig = state.noclipOrig or setmetatable({}, { __mode = "k" })
    local currentCharacter
    local parts = {}
    state.noclipParts = parts

    local function track(part)
        if part:IsA("BasePart") then
            parts[part] = true
            if state.noclipOrig[part] == nil then
                state.noclipOrig[part] = part.CanCollide
            end
        end
    end

    local function bind(character)
        if state.noclipAddedConn then
            state.noclipAddedConn:Disconnect()
            state.noclipAddedConn = nil
        end
        if state.noclipRemovedConn then
            state.noclipRemovedConn:Disconnect()
            state.noclipRemovedConn = nil
        end
        table.clear(parts)
        currentCharacter = character
        if not character then
            return
        end
        state.noclipAddedConn = character.DescendantAdded:Connect(track)
        state.noclipRemovedConn = character.DescendantRemoving:Connect(function(part)
            parts[part] = nil
        end)
        for _, part in ipairs(character:GetDescendants()) do
            track(part)
        end
    end

    bind(lp.Character)
    state.noclipCharacterConn = lp.CharacterAdded:Connect(bind)
    state.noclipConn = rs.Stepped:Connect(function()
        if lp.Character ~= currentCharacter then
            bind(lp.Character)
        end
        for part in pairs(parts) do
            if part.Parent then
                if part.CanCollide then
                    part.CanCollide = false
                end
            else
                parts[part] = nil
            end
        end
    end)
    table.insert(conns, state.noclipConn)
    table.insert(conns, state.noclipCharacterConn)
end

function Feat.setInfJump(on)
    if state.infJumpConn then
        state.infJumpConn:Disconnect()
        state.infJumpConn = nil
    end
    if not on then
        return
    end
    state.infJumpConn = UIS.JumpRequest:Connect(function()
        local now = os.clock()
        local held = now - (state.infJumpLast or 0) < 0.15
        state.infJumpLast = now
        if held then
            return
        end
        local chr = lp.Character
        local hum = chr and chr:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 and hum:GetState() == Enum.HumanoidStateType.Freefall then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
    table.insert(conns, state.infJumpConn)
end

function Feat.setAntiRagdoll(on)
    if state.antiRagdollConn then
        state.antiRagdollConn:Disconnect()
        state.antiRagdollConn = nil
    end
    if not on then
        return
    end
    local el, limpSince, doneFor = 0, nil, nil
    state.antiRagdollConn = rs.Heartbeat:Connect(function(dt)
        el += dt
        if el < 0.25 then
            return
        end
        el = 0
        local chr = lp.Character
        local hum = chr and chr:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 or hum:GetState() ~= Enum.HumanoidStateType.Physics or Feat.isTrapped() then
            limpSince = nil
            return
        end
        limpSince = limpSince or os.clock()
        local ends = ragdollEnd()
        if
            ends > 0
            and doneFor ~= ends
            and workspace:GetServerTimeNow() > ends + 0.75
            and os.clock() - limpSince > 1
        then
            limpSince, doneFor = nil, ends
            local okR, Rag = pcall(function()
                return require(rep.Shared.Modules.Ragdoll)
            end)
            if not (okR and type(Rag) == "table" and pcall(Rag.ClearClientRagdoll, chr)) then
                pcall(function()
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end)
            end
            logRun("Ragdoll Recovery: stood up after the ragdoll window")
        end
    end)
    table.insert(conns, state.antiRagdollConn)
end

function Feat.setInstantPrompts(on)
    if not on then
        if state.promptConn then
            state.promptConn:Disconnect()
            state.promptConn = nil
        end
        for _, c in pairs(state.promptWatch or {}) do
            pcall(function()
                c:Disconnect()
            end)
        end
        state.promptWatch = nil
        for p, orig in pairs(state.promptOrig or {}) do
            if p.Parent then
                pcall(function()
                    p.HoldDuration = orig
                end)
            end
        end
        state.promptOrig = nil
        return
    end
    if state.promptConn then
        return
    end
    state.promptOrig = setmetatable({}, { __mode = "k" })
    state.promptWatch = setmetatable({}, { __mode = "k" })
    local function patchOne(p)
        if not p:IsA("ProximityPrompt") or not state.promptWatch or state.promptWatch[p] then
            return
        end
        state.promptOrig[p] = p.HoldDuration
        pcall(function()
            p.HoldDuration = 0
        end)
        state.promptWatch[p] = p:GetPropertyChangedSignal("HoldDuration"):Connect(function()
            if state.promptOrig and p.HoldDuration ~= 0 then
                state.promptOrig[p] = p.HoldDuration
                pcall(function()
                    p.HoldDuration = 0
                end)
            end
        end)
    end
    for _, p in ipairs(workspace:GetDescendants()) do
        patchOne(p)
    end
    state.promptConn = workspace.DescendantAdded:Connect(patchOne)
    table.insert(conns, state.promptConn)
end

function Feat.setInvisible(on)
    if not on then
        if state.invisConn then
            state.invisConn:Disconnect()
            state.invisConn = nil
        end
        if state.invisAddConn then
            state.invisAddConn:Disconnect()
            state.invisAddConn = nil
        end
        for p, orig in pairs(state.invisOrig or {}) do
            if p.Parent then
                pcall(function()
                    p.Transparency = orig
                end)
            end
        end
        state.invisOrig = nil
        return
    end
    if state.invisConn then
        return
    end
    state.invisOrig = setmetatable({}, { __mode = "k" })
    local function hide(p)
        if
            state.invisOrig
            and (p:IsA("BasePart") or p:IsA("Decal"))
            and state.invisOrig[p] == nil
            and p.Transparency < 1
        then
            state.invisOrig[p] = p.Transparency
            pcall(function()
                p.Transparency = 1
            end)
        end
    end
    local function bind(chr)
        if state.invisAddConn then
            state.invisAddConn:Disconnect()
            state.invisAddConn = nil
        end
        if not chr then
            return
        end
        for _, p in ipairs(chr:GetDescendants()) do
            hide(p)
        end
        state.invisAddConn = chr.DescendantAdded:Connect(hide)
        table.insert(conns, state.invisAddConn)
    end
    bind(lp.Character)
    state.invisConn = lp.CharacterAdded:Connect(function(chr)
        task.wait(0.15)
        if state.invisConn then
            bind(chr)
        end
    end)
    table.insert(conns, state.invisConn)
end

function Feat.setAntiTrap(on)
    if not on then
        if state.antiTrapConn then
            state.antiTrapConn:Disconnect()
            state.antiTrapConn = nil
        end
        for p, orig in pairs(state.trapOrig or {}) do
            if p.Parent then
                pcall(function()
                    p.CanTouch = orig
                end)
            end
        end
        state.trapOrig = nil
        Feat.trapParts = nil
        return
    end
    if state.antiTrapConn then
        return
    end
    state.trapOrig = setmetatable({}, { __mode = "k" })
    Feat.trapParts = setmetatable({}, { __mode = "k" })
    local function track(inst)
        if inst.Name ~= "Hitbox" or not inst:IsA("BasePart") or not Feat.trapParts or not state.trapOrig then
            return
        end
        local trap = inst.Parent
        local owner = trap and trap:GetAttribute("Owner")
        if owner == nil or owner == lp.Name then
            return
        end
        Feat.trapParts[inst] = true
        for _, p in ipairs({ inst, trap }) do
            if p:IsA("BasePart") and state.trapOrig[p] == nil then
                state.trapOrig[p] = p.CanTouch
                pcall(function()
                    p.CanTouch = false
                end)
            end
        end
    end
    local root = workspace:FindFirstChild("Transient") or workspace
    for _, d in ipairs(root:GetDescendants()) do
        track(d)
    end
    state.antiTrapConn = root.DescendantAdded:Connect(function(d)
        if d.Name == "Hitbox" then
            task.defer(track, d)
        end
    end)
    table.insert(conns, state.antiTrapConn)
end

function Feat.hopServer()
    if state.hopping then
        return
    end
    state.hopping = true
    local ts, hs = H.gs("TeleportService"), H.gs("HttpService")
    local list, cursor = {}, nil
    local order = cfg.misc.hopMode == "Most Players" and "Desc" or "Asc"
    for _ = 1, 3 do
        local url = "https://games.roblox.com/v1/games/"
            .. game.PlaceId
            .. "/servers/Public?sortOrder="
            .. order
            .. "&excludeFullGames=true&limit=100"
            .. (cursor and ("&cursor=" .. cursor) or "")
        local okG, raw = pcall(game.HttpGet, game, url)
        local okD, d = false, nil
        if okG then
            okD, d = pcall(hs.JSONDecode, hs, raw)
        end
        if not (okD and type(d) == "table" and type(d.data) == "table") then
            break
        end
        for _, s in ipairs(d.data) do
            local playing, maxP = tonumber(s.playing), tonumber(s.maxPlayers)
            if type(s.id) == "string" and s.id ~= game.JobId and playing and maxP and playing < maxP then
                list[#list + 1] = { id = s.id, playing = playing }
            end
        end
        cursor = d.nextPageCursor
        if type(cursor) ~= "string" or #list >= 40 then
            break
        end
    end
    if #list == 0 then
        state.hopping = false
        BPUI:Notify({ Title = "Server Hop", Content = "No free server found", Type = "Warning", Duration = 4 })
        return
    end
    local mode = cfg.misc.hopMode
    if mode == "Fewest Players" then
        table.sort(list, function(a, b)
            return a.playing < b.playing
        end)
    elseif mode == "Most Players" then
        table.sort(list, function(a, b)
            return a.playing > b.playing
        end)
    else
        for i = #list, 2, -1 do
            local j = math.random(1, i)
            list[i], list[j] = list[j], list[i]
        end
    end
    local failed = false
    local conn = ts.TeleportInitFailed:Connect(function(plr)
        if plr == lp then
            failed = true
        end
    end)
    table.insert(conns, conn)
    for i = 1, math.min(3, #list) do
        if state.destroyed then
            break
        end
        failed = false
        BPUI:Notify({
            Title = "Server Hop",
            Content = string.format("Joining a server with %d players...", list[i].playing),
            Type = "Info",
            Duration = 3,
        })
        if pcall(function()
            ts:TeleportToPlaceInstance(game.PlaceId, list[i].id, lp)
        end) then
            local t0 = os.clock()
            while not failed and not state.destroyed and os.clock() - t0 < 12 do
                task.wait(0.25)
            end
            if not failed then
                break
            end
        end
        logRun("Server Hop: teleport to " .. list[i].id:sub(1, 8) .. " failed, trying the next server")
    end
    pcall(function()
        conn:Disconnect()
    end)
    state.hopping = false
    if failed then
        BPUI:Notify({ Title = "Server Hop", Content = "Teleport failed", Type = "Error", Duration = 4 })
    end
end

function Feat.rejoin()
    local ts = H.gs("TeleportService")
    if state.hopping then
        BPUI:Notify({ Title = "Rejoin", Content = "Already hopping", Type = "Warning", Duration = 3 })
        return
    end
    if #H.gs("Players"):GetPlayers() <= 1 or game.JobId == "" then
        BPUI:Notify({ Title = "Rejoin", Content = "Server is empty, joining another...", Type = "Info", Duration = 3 })
        pcall(function()
            ts:Teleport(game.PlaceId, lp)
        end)
        return
    end
    state.hopping = true
    local failed, why = false, nil
    local conn = ts.TeleportInitFailed:Connect(function(plr, _, msg)
        if plr == lp then
            failed, why = true, msg
        end
    end)
    BPUI:Notify({ Title = "Rejoin", Content = "Rejoining this server...", Type = "Info", Duration = 3 })
    local okT, err = pcall(function()
        ts:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp)
    end)
    if okT then
        local t0 = os.clock()
        while not failed and not state.destroyed and os.clock() - t0 < 10 do
            task.wait(0.25)
        end
    end
    pcall(function()
        conn:Disconnect()
    end)
    state.hopping = false
    if state.destroyed or (okT and not failed) then
        return
    end
    local reason = okT and tostring(why or "the server is full or closed") or firstLine(err)
    BPUI:Notify({
        Title = "Rejoin",
        Content = "Could not rejoin this server (" .. reason .. "), joining another one",
        Type = "Warning",
        Duration = 4,
    })
    pcall(function()
        ts:Teleport(game.PlaceId, lp)
    end)
end

function Feat.setAutoRejoin(on)
    if state.rejoinConn then
        state.rejoinConn:Disconnect()
        state.rejoinConn = nil
    end
    if state.rejoinConn2 then
        state.rejoinConn2:Disconnect()
        state.rejoinConn2 = nil
    end
    if not on then
        return
    end
    local gs = H.gs("GuiService")
    local function trigger(msg)
        if state.destroyed or state.rejoining or state.hopping or not cfg.misc.autoRejoin then
            return
        end
        local okC, code = pcall(function()
            return gs:GetErrorCode()
        end)
        if (okC and tostring(code):find("Teleport")) or tostring(msg):lower():find("teleport") then
            return
        end
        state.rejoining = true
        logRun("Auto Rejoin: disconnected (" .. firstLine(msg) .. ")")
        task.spawn(Feat.rejoinLoop)
    end
    state.rejoinConn = gs.ErrorMessageChanged:Connect(function(msg)
        if type(msg) == "string" and msg ~= "" then
            trigger(msg)
        end
    end)
    table.insert(conns, state.rejoinConn)
    pcall(function()
        local overlay = H.gs("CoreGui"):FindFirstChild("RobloxPromptGui")
        overlay = overlay and overlay:FindFirstChild("promptOverlay")
        if overlay then
            state.rejoinConn2 = overlay.ChildAdded:Connect(function(c)
                if c.Name == "ErrorPrompt" then
                    task.wait(0.5)
                    local okM, m = pcall(function()
                        return gs:GetErrorMessage()
                    end)
                    trigger(okM and type(m) == "string" and m ~= "" and m or "error prompt")
                end
            end)
            table.insert(conns, state.rejoinConn2)
        end
    end)
end

function Feat.rejoinLoop()
    local ts = H.gs("TeleportService")
    local failed = false
    local conn = ts.TeleportInitFailed:Connect(function(plr)
        if plr == lp then
            failed = true
        end
    end)
    local gap, tries = 5, 0
    while cfg.misc.autoRejoin and not state.destroyed do
        task.wait(gap)
        if not cfg.misc.autoRejoin or state.destroyed then
            break
        end
        tries += 1
        failed = false
        if tries == 1 and game.JobId ~= "" then
            pcall(function()
                ts:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp)
            end)
        else
            pcall(function()
                ts:Teleport(game.PlaceId, lp)
            end)
        end
        local t0 = os.clock()
        while not failed and not state.destroyed and os.clock() - t0 < 15 do
            task.wait(0.5)
        end
        gap = math.min(gap * 2, 60)
    end
    pcall(function()
        conn:Disconnect()
    end)
    state.rejoining = false
end

function Feat.joinJob(id)
    id = tostring(id or ""):gsub("%s", "")
    local function say(txt, kind)
        BPUI:Notify({ Title = "Join Job ID", Content = txt, Type = kind or "Warning", Duration = 4 })
    end
    if not id:match("^%x+%-%x+%-%x+%-%x+%-%x+$") then
        say("Paste a Job ID first (format xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)")
        return
    end
    if id == game.JobId then
        say("You are already in this server", "Info")
        return
    end
    if state.hopping then
        say("Already hopping")
        return
    end
    state.hopping = true
    local ts = H.gs("TeleportService")
    local failed, why = false, nil
    local conn = ts.TeleportInitFailed:Connect(function(plr, _, msg)
        if plr == lp then
            failed, why = true, msg
        end
    end)
    say("Joining server " .. id:sub(1, 8) .. "...", "Info")
    local okT, err = pcall(function()
        ts:TeleportToPlaceInstance(game.PlaceId, id, lp)
    end)
    if okT then
        local t0 = os.clock()
        while not failed and not state.destroyed and os.clock() - t0 < 15 do
            task.wait(0.25)
        end
    end
    pcall(function()
        conn:Disconnect()
    end)
    state.hopping = false
    if not okT then
        say("Teleport failed: " .. firstLine(err), "Error")
    elseif failed then
        say("Could not join: " .. tostring(why or "the server is full or closed"), "Error")
    end
end

function Feat.scriptPath()
    local p = tostring(cfg.misc.scriptFile or ""):gsub("^%s+", ""):gsub("%s+$", "")
    return p ~= "" and p or "stealanegg.lua"
end

function Feat.readScript()
    local p = Feat.scriptPath()
    local okF, exists = pcall(function()
        return type(isfile) == "function" and isfile(p)
    end)
    if not (okF and exists) then
        return nil, "File not found in the executor workspace: " .. p
    end
    local okR, src = pcall(readfile, p)
    if not okR or type(src) ~= "string" or #src == 0 then
        return nil, "Could not read " .. p
    end
    local fn, err = loadstring(src)
    if not fn then
        return nil, "The file has an error: " .. tostring(err)
    end
    return fn
end

function Feat.queueFn()
    local E = (getgenv and getgenv()) or _G
    local q = (type(E.syn) == "table" and E.syn.queue_on_teleport)
        or E.queue_on_teleport
        or E.queueonteleport
        or (type(queue_on_teleport) == "function" and queue_on_teleport)
        or nil
    return type(q) == "function" and q or nil
end

function Feat.queueLoad()
    if state.loadQueued or not cfg.misc.autoLoad or state.destroyed then
        return
    end
    local q = Feat.queueFn()
    if not q then
        return
    end
    local code = table.concat({
        "if not game:IsLoaded() then game.Loaded:Wait() end",
        "task.wait(8)",
        "local E = (getgenv and getgenv()) or _G",
        "if E.__BPHUB_SAE_UNLOAD or E.__BPHUB_AUTOLOADED then return end",
        "local p = " .. string.format("%q", Feat.scriptPath()),
        "if not (isfile and isfile(p)) then return end",
        "E.__BPHUB_AUTOLOADED = true",
        "loadstring(readfile(p))()",
    }, "\n")
    if pcall(q, code) then
        state.loadQueued = true
        logRun("Auto Load: the script will load again in the next server")
    end
end

function Feat.setAutoLoad(on)
    if state.autoLoadConn then
        state.autoLoadConn:Disconnect()
        state.autoLoadConn = nil
    end
    if not on then
        return
    end
    state.autoLoadConn = lp.OnTeleport:Connect(function(st)
        if st == Enum.TeleportState.Started or st == Enum.TeleportState.InProgress then
            Feat.queueLoad()
        elseif st == Enum.TeleportState.Failed then
            state.loadQueued = false
        end
    end)
    table.insert(conns, state.autoLoadConn)
end

function Feat.claimIndex(manual)
    local function say(txt, kind)
        if manual == true then
            BPUI:Notify({ Title = "Index", Content = txt, Type = kind or "Info", Duration = 3 })
        end
    end
    local rf = Remotes and Remotes.Codex and Remotes.Codex.AskRedeemAll
    if not rf then
        say("Index remote not found", "Warning")
        return
    end
    local getSave = Save and (Save.Peek or Save.Get)
    local save = getSave and getSave()
    if type(save) == "table" and type(save.Index) == "table" then
        local claimed = type(save.IndexClaimedCategories) == "table" and save.IndexClaimedCategories or {}
        local pending = 0
        for cat, has in pairs(save.Index) do
            if has and claimed[cat] ~= true then
                pending += 1
            end
        end
        if pending == 0 then
            say("Nothing to claim")
            return
        end
    end
    local okP, ok, err = pcall(function()
        return rf:InvokeServer()
    end)
    if okP and ok == true then
        state.indexLastWhy = nil
        logRun("Index: claimed all rewards")
        say("Claimed all Index rewards", "Success")
        return
    end
    local why = okP and tostring(err or "nothing to claim") or firstLine(ok)
    if manual == true or why ~= state.indexLastWhy then
        logRun("Index: claim failed: " .. why)
    end
    state.indexLastWhy = why
    say("Claim failed: " .. why, "Warning")
end

function Feat.claimGroupReward()
    local rf = Remotes and Remotes.GroupPerk and Remotes.GroupPerk.RedeemPerk
    if not rf then
        return false, "Group reward remote not found"
    end
    local getSave = Save and (Save.Peek or Save.Get)
    local save = getSave and getSave()
    if type(save) ~= "table" then
        return false, "Save data not ready"
    end
    if save.ClaimedGroupReward == true then
        return false, "Already claimed"
    end
    local okK, K = pcall(function()
        return require(rep.Shared.Globals.Constants)
    end)
    local gid = okK and type(K) == "table" and tonumber(K.GROUP_ID)
    if not gid then
        return false, "Group id not found"
    end
    local okM, member = pcall(function()
        return lp:IsInGroupAsync(gid)
    end)
    if not okM then
        okM, member = pcall(function()
            return lp:IsInGroup(gid)
        end)
    end
    if not okM then
        return false, "Could not check your group membership"
    end
    if not member then
        return false, "Join the game's Roblox group first (the reward is for members only)"
    end
    local okP, ok, msg, sp = pcall(function()
        return rf:InvokeServer(true)
    end)
    if okP and ok == true then
        logRun("Group reward claimed")
        return true, "Group reward claimed" .. (tonumber(sp) and (" (+" .. shortNum(sp) .. " SpeedPower)") or "")
    end
    return false, okP and tostring(msg or "the server refused") or firstLine(ok)
end

function Feat.useConsumable()
    local function say(txt, kind)
        BPUI:Notify({ Title = "Fractured Crystal", Content = txt, Type = kind or "Warning", Duration = 4 })
    end
    local rf = Remotes and Remotes.BossMastery and Remotes.BossMastery.AskUseMutationConsumable
    if not rf then
        say("Mutation remote not found")
        return
    end
    local getSave = Save and (Save.Peek or Save.Get)
    local save = getSave and getSave()
    local bm = save and save.BossMastery
    if (bm and tonumber(bm.MutationConsumables) or 0) <= 0 then
        say("You have no Fractured Crystals")
        return
    end
    local chr, _, hum = charParts()
    if not hum then
        say("No character")
        return
    end
    local tool
    for _, holder in ipairs({ chr, lp:FindFirstChildOfClass("Backpack") }) do
        for _, c in ipairs(holder and holder:GetChildren() or {}) do
            if
                c:IsA("Tool")
                and c:GetAttribute("ItemType") == "MutationConsumable"
                and (c:GetAttribute("MutationId") or "Boss") == "Boss"
            then
                tool = c
                break
            end
        end
        if tool then
            break
        end
    end
    if not tool then
        say("The Fractured Crystal tool is not in your backpack")
        return
    end
    local best, bestRate, bestEgg
    local okE, eggs = pcall(EggState.ReadOwnerEggs, lp.UserId)
    for uid, egg in pairs(okE and type(eggs) == "table" and eggs or {}) do
        if type(egg) == "table" and egg.Placement and egg.AssetCategory then
            local muts = type(egg.Mutations) == "table" and egg.Mutations or {}
            if not table.find(muts, "Boss") and egg.BaseMutation ~= "Boss" then
                local r = displayRate(egg)
                if not bestRate or r > bestRate then
                    best, bestRate, bestEgg = uid, r, egg
                end
            end
        end
    end
    if not best then
        say("No placed egg to mutate: place an egg on your plot first")
        return
    end
    local prev = chr:FindFirstChildOfClass("Tool")
    if prev ~= tool then
        pcall(function()
            hum:EquipTool(tool)
        end)
        task.wait(0.4)
    end
    local okI, res = pcall(function()
        return rf:InvokeServer(best)
    end)
    if prev ~= tool then
        pcall(function()
            if prev and prev.Parent then
                hum:EquipTool(prev)
            else
                hum:UnequipTools()
            end
        end)
    end
    if not okI or type(res) ~= "table" then
        say("The server did not answer, try again", "Error")
        return
    end
    if not res.Success then
        say(tostring(res.Message or "The crystal could not be used"))
        return
    end
    local label = labelFor(bestEgg)
    if res.Mutated then
        say("Fractured mutation applied to " .. label, "Success")
    else
        say("The roll failed on " .. label .. " (the crystal was used)", "Info")
    end
    logRun("Fractured Crystal on " .. label .. ": " .. (res.Mutated and "mutated" or "roll failed"))
end

function Feat.bossShopProducts()
    local list = {}
    local okBM, BM = pcall(function()
        return require(rep.Data.BossMastery)
    end)
    if okBM and type(BM) == "table" and type(BM.ShopProducts) == "table" then
        for _, p in ipairs(BM.ShopProducts) do
            if type(p) == "table" and p.Id ~= nil then
                list[#list + 1] = { id = p.Id, name = tostring(p.DisplayName or p.Id), price = tonumber(p.Price) }
            end
        end
    end
    return list
end

function Feat.bossTokens()
    local getSave = Save and (Save.Peek or Save.Get)
    local ok, save = pcall(function()
        return getSave and getSave()
    end)
    return ok and type(save) == "table" and tonumber(save.BossTokens) or nil
end

function Feat.autoBossShop(manual)
    local rf = Remotes and Remotes.BossMastery and Remotes.BossMastery.AskBuyShopItem
    if not rf then
        return 0, "Boss shop remote not found"
    end
    local selectedItems = asList(cfg.boss.shopItems)
    if #selectedItems == 0 then
        return 0, "no item selected"
    end
    local tokens = Feat.bossTokens()
    if not tokens then
        return 0, "save data not ready"
    end
    local byId = {}
    for _, p in ipairs(Feat.bossShopProducts()) do
        byId[p.id] = p
    end
    local keep = math.max(0, math.floor(tonumber(cfg.boss.keepTokens) or 0))
    local bought, why = 0, nil
    for _, itemId in ipairs(selectedItems) do
        local p = byId[itemId]
        local name = p and p.name or tostring(itemId)
        local price = p and p.price
        if not price then
            why = name .. " is not in the shop list"
        elseif tokens < price then
            why = string.format("%s costs %d tokens, you have %d", name, price, tokens)
        elseif tokens - price < keep then
            why = string.format("%s costs %d tokens and you keep %d (you have %d)", name, price, keep, tokens)
        else
            local okP, success, msg = pcall(function()
                return rf:InvokeServer(itemId)
            end)
            if okP and success == true then
                tokens -= price
                bought += 1
                logRun("Boss Shop: bought " .. name)
            else
                why = name .. ": " .. (okP and tostring(msg or "the server refused") or firstLine(success))
                if manual or why ~= state.shopLastWhy then
                    logRun("Boss Shop: " .. why)
                end
            end
        end
    end
    state.shopLastWhy = why
    return bought, why
end

function Feat.claimMastery(manual)
    local rf = Remotes and Remotes.BossMastery and Remotes.BossMastery.AskClaimMilestone
    if not rf then
        return 0, "Mastery remote not found"
    end
    local okBM, BM = pcall(function()
        return require(rep.Data.BossMastery)
    end)
    if not (okBM and type(BM) == "table" and type(BM.Milestones) == "table") then
        return 0, "Mastery data not found"
    end
    local getSave = Save and (Save.Peek or Save.Get)
    local save = getSave and getSave()
    local bm = type(save) == "table" and save.BossMastery
    if type(bm) ~= "table" then
        return 0, "save data not ready"
    end
    local claimed = type(bm.ClaimedMilestoneIds) == "table" and bm.ClaimedMilestoneIds or {}
    local mastery = tonumber(bm.Mastery) or 0
    local ids = {}
    for _, m in ipairs(BM.Milestones) do
        local okK, kills = pcall(BM.GetMilestoneKills, m)
        if okK and tonumber(kills) and mastery >= kills and not claimed[m.Id] then
            ids[#ids + 1] = m.Id
        end
    end
    local okF, final = pcall(BM.FinalMilestone)
    local okC, extra = pcall(BM.ClaimableInfiniteCount, bm)
    if BM.InfiniteMilestoneId and okF and type(final) == "table" and claimed[final.Id] and okC then
        for _ = 1, math.min(tonumber(extra) or 0, 5) do
            ids[#ids + 1] = BM.InfiniteMilestoneId
        end
    end
    if #ids == 0 then
        return 0, "nothing to claim"
    end
    local n, why = 0, nil
    for _, id in ipairs(ids) do
        if state.destroyed or (not manual and not cfg.auto.mastery) then
            break
        end
        local okP, ok, msg = pcall(function()
            return rf:InvokeServer(id)
        end)
        if okP and ok then
            n += 1
            logRun("Boss Mastery: claimed " .. tostring(id))
        else
            why = tostring(id) .. ": " .. (okP and tostring(msg or "the server refused") or firstLine(ok))
            if manual or why ~= state.masteryLastWhy then
                logRun("Boss Mastery: " .. why)
            end
            break
        end
        task.wait(0.5)
    end
    state.masteryLastWhy = why
    return n, why
end

function Feat.favRules()
    local f = cfg.fav
    local r = {
        rank = Feat.RARITY_RANKS[f.minRarity] or 0,
        val = tonumber(f.minValue) or 0,
        orMode = f.rule == "Rarity Or Value",
        muts = {},
        species = {},
        match = f.match,
    }
    for _, id in ipairs(asList(f.muts)) do
        r.muts[id] = true
    end
    for _, id in ipairs(asList(f.species)) do
        r.species[id] = true
    end
    r.hasRule = r.rank > 0
        or r.val > 0
        or next(r.muts) ~= nil
        or next(r.species) ~= nil
        or Feat.nameMatch(r.match, "") ~= nil
        or f.equipped == true
    return r
end

function Feat.favWanted(raw, r)
    local cat = raw.Category
    if r.species[cat] or Feat.nameMatch(r.match, cat) == true then
        return true
    end
    if next(r.muts) ~= nil then
        if raw.BaseMutation ~= nil and r.muts[raw.BaseMutation] then
            return true
        end
        for _, m in ipairs(type(raw.Mutations) == "table" and raw.Mutations or {}) do
            if r.muts[m] then
                return true
            end
        end
    end
    if r.rank == 0 and r.val <= 0 then
        return false
    end
    local _, rank = eggRarity({ AssetCategory = cat })
    local byRank = r.rank > 0 and rank >= r.rank
    local byVal = false
    if r.val > 0 then
        local okR, rate = pcall(AssetEarnings.RatePerSecond, raw)
        byVal = okR and tonumber(rate) ~= nil and rate >= r.val
    end
    if r.orMode then
        return byRank or byVal
    end
    return (r.rank == 0 or byRank) and (r.val <= 0 or byVal)
end

function Feat.autoFavorite(manual)
    if not Remotes or not Remotes.PetSatchel then
        return 0, "Pet remotes not found"
    end
    local getSave = Save and (Save.Peek or Save.Get)
    local save = getSave and getSave()
    if not save then
        return 0, "Save data not ready"
    end
    local r, f = Feat.favRules(), cfg.fav
    local unfav = not manual and f.unfavEquipped == true and f.equipped ~= true
    if not manual and not r.hasRule and not unfav then
        if not state.favWarned then
            state.favWarned = true
            BPUI:Notify({
                Title = "Auto Favorite",
                Content = "Set a favorite rule first",
                Type = "Warning",
                Duration = 4,
            })
        end
        return 0, "no filter set"
    end
    local equipped = {}
    for _, uid in ipairs(save.EquippedAssets or {}) do
        equipped[uid] = true
    end
    local sent, unsent = {}, {}
    for uid, raw in pairs(save.Inventory or {}) do
        if state.destroyed or (not manual and not cfg.auto.favorite) then
            break
        end
        if type(raw) == "table" and not raw.InFuse then
            local want
            if not raw.IsFavorite then
                if
                    (manual and not r.hasRule)
                    or (f.equipped == true and equipped[uid] == true)
                    or Feat.favWanted(raw, r)
                then
                    want = true
                end
            elseif unfav and equipped[uid] and not Feat.favWanted(raw, r) then
                want = false
            end
            if
                want ~= nil
                and pcall(function()
                    Remotes.PetSatchel.WriteFavourite:FireServer(uid, want)
                end)
            then
                table.insert(want and sent or unsent, uid)
                task.wait(0.12)
            end
        end
    end
    if #sent == 0 and #unsent == 0 then
        return 0
    end
    task.wait(1.5)
    local after = getSave and getSave()
    local inv = type(after) == "table" and after.Inventory or {}
    local n, un = 0, 0
    for _, uid in ipairs(sent) do
        if type(inv[uid]) == "table" and inv[uid].IsFavorite then
            n += 1
        end
    end
    for _, uid in ipairs(unsent) do
        if type(inv[uid]) == "table" and not inv[uid].IsFavorite then
            un += 1
        end
    end
    if n > 0 then
        logRun(string.format("Auto Favorite: %d of %d pets favorited", n, #sent))
    end
    if un > 0 then
        logRun(string.format("Auto Favorite: %d equipped pet(s) unfavorited", un))
    end
    return n, #sent
end

function Feat.autoUpgradeBase()
    if not Remotes or not Remotes.Homestead then
        return false, "Base remote not found"
    end
    local okBases, Bases = pcall(function()
        return require(rep.Data.Bases)
    end)
    if not okBases then
        return false, "Base data not found"
    end
    local getSave = Save and (Save.Peek or Save.Get)
    local save = getSave and getSave()
    if not save then
        return false, "Save data not ready"
    end
    local currentLevel = tonumber(save.BaseUpgradeLevel) or 0
    local nextTier = Bases.BASES and Bases.BASES[currentLevel + 1]
    if not nextTier then
        return false, "Max level"
    end
    local cost = tonumber(nextTier.Cost) or math.huge
    if money() < cost then
        return false, "Not enough money (need $" .. shortNum(cost) .. ")"
    end
    if not pcall(function()
        Remotes.Homestead.AskBaseTierRaise:FireServer()
    end) then
        return false, "The request failed"
    end
    local t0 = os.clock()
    repeat
        task.wait(0.25)
        local s = getSave()
        if type(s) == "table" and (tonumber(s.BaseUpgradeLevel) or 0) > currentLevel then
            logRun("Base upgraded to tier " .. (currentLevel + 1) .. " ($" .. shortNum(cost) .. ")")
            return true, "Upgraded to tier " .. (currentLevel + 1)
        end
    until os.clock() - t0 > 3
    return false, "The server did not upgrade the base"
end

function Feat.autoUpgradeTreadmill()
    local nextT, curT = nextTreadmillTier()
    if not nextT then
        return false, curT and "Max level" or "Treadmill data not ready"
    end
    local price = tonumber(nextT.Price) or math.huge
    local name = tostring(nextT.DisplayName or nextT._id)
    if money() < price then
        return false, "Not enough money (need $" .. shortNum(price) .. ")"
    end
    local okP, res = pcall(function()
        return require(rep.Controllers.GUI.TreadmillUpgradeController.Client).RequestCashUpgrade()
    end)
    if okP and res == true then
        logRun("Treadmill upgraded: " .. name)
        return true, "Upgraded to " .. name
    end
    return false, okP and "The server refused the upgrade" or ("The upgrade failed: " .. firstLine(res))
end

function Feat.trailInfo()
    if Feat.TrailsData == nil then
        local ok, T = pcall(function()
            return require(rep.Data.Trails)
        end)
        Feat.TrailsData = ok and type(T) == "table" and type(T.Directory) == "table" and T or false
    end
    local T = Feat.TrailsData
    local getSave = Save and (Save.Peek or Save.Get)
    local okS, save = pcall(function()
        return getSave and getSave()
    end)
    if not T or not okS or type(save) ~= "table" or type(save.TrailInventory) ~= "table" then
        return nil
    end
    local owned = save.TrailInventory
    local info = { dir = T.Directory, equipped = save.EquippedTrail, best = nil, bestMult = 0 }
    for id, has in pairs(owned) do
        local t = T.Directory[id]
        local m = has == true and type(t) == "table" and tonumber(t.SpeedMultiplier)
        if m and m > info.bestMult then
            info.best, info.bestMult = id, m
        end
    end
    for id, t in pairs(T.Directory) do
        local price, m = type(t) == "table" and tonumber(t.Price), type(t) == "table" and tonumber(t.SpeedMultiplier)
        if
            price
            and m
            and owned[id] ~= true
            and t.DisplayInShop ~= false
            and m > info.bestMult
            and (not info.nextPrice or price < info.nextPrice)
        then
            info.nextId, info.nextPrice = id, price
        end
    end
    return info
end

function Feat.trailName(info, id)
    local t = id and info.dir[id]
    return type(t) == "table" and tostring(t.DisplayName or id) or tostring(id or "none")
end

function Feat.autoTrail(manual)
    local tw = Remotes and Remotes.Trailwear
    if not (tw and tw.AskPurchase and tw.AskChoose) then
        return false, "Trail remotes not found"
    end
    if not manual and Feat.stealBusy() then
        return false, "waiting for the steal to end"
    end
    local info = Feat.trailInfo()
    if not info then
        return false, "Trail data not ready"
    end
    local ok, msg, key = false, nil, nil
    if info.nextId then
        local name = Feat.trailName(info, info.nextId)
        local keep = math.max(0, tonumber(cfg.trail.keep) or 0)
        if money() - info.nextPrice < keep then
            msg = string.format(
                "%s costs $%s (you have $%s, keeping $%s)",
                name,
                shortNum(info.nextPrice),
                shortNum(money()),
                shortNum(keep)
            )
            key = "money:" .. tostring(info.nextId)
        else
            local okP, done, why = pcall(function()
                return tw.AskPurchase:InvokeServer(info.nextId)
            end)
            if okP and done then
                ok, msg = true, "Bought " .. name
                logRun("Trail bought: " .. name .. " ($" .. shortNum(info.nextPrice) .. ")")
                info.best = info.nextId
            else
                msg = name .. ": " .. (okP and tostring(why or "the server refused") or firstLine(done))
            end
        end
    else
        msg = "You own the fastest shop trail"
    end
    if info.best and info.equipped ~= info.best then
        local name = Feat.trailName(info, info.best)
        local okP, done, why = pcall(function()
            return tw.AskChoose:InvokeServer(info.best)
        end)
        if okP and done then
            local bought = ok
            ok = true
            msg = bought and (msg .. ", now wearing it") or ("Now wearing " .. name .. (msg and (". " .. msg) or ""))
            logRun("Trail equipped: " .. name)
        else
            local eq = "Equip " .. name .. ": " .. (okP and tostring(why or "the server refused") or firstLine(done))
            msg = (msg and (msg .. ". ") or "") .. eq
            key = key and (key .. "|" .. eq)
        end
    end
    local dk = key or msg
    if not manual and dk ~= state.trailLastWhy and not ok then
        logRun("Auto Trail: " .. tostring(msg))
    end
    state.trailLastWhy = dk
    return ok, msg
end

function Feat.trailLine()
    local info = Feat.trailInfo()
    if not info then
        return nil
    end
    local cur = info.equipped and info.dir[info.equipped]
    local line = string.format(
        "Trail: %s (x%s)",
        Feat.trailName(info, info.equipped),
        tostring(type(cur) == "table" and cur.SpeedMultiplier or 1)
    )
    if info.nextId then
        line = line
            .. string.format(
                " | next: %s (x%s) $%s",
                Feat.trailName(info, info.nextId),
                tostring(info.dir[info.nextId].SpeedMultiplier),
                shortNum(info.nextPrice)
            )
    end
    return line
end

function Feat.autoFuse(manual)
    local F = Remotes and Remotes.Fusery
    if not F then
        return 0, "Fuse remotes not found"
    end
    if state.fuseBusy then
        return 0, "a fuse run is already in progress"
    end
    state.fuseBusy = true
    local ok, n, why = pcall(Feat.fuseRun, F, manual)
    state.fuseBusy = false
    if not ok then
        n, why = 0, firstLine(n)
    end
    if not manual and why and why ~= state.fuseLastWhy then
        logRun("Auto Fuse: " .. why)
    end
    state.fuseLastWhy = why
    return n, why
end

function Feat.fuseRun(F, manual)
    local function live()
        return not state.destroyed and (manual or cfg.auto.fuse)
    end
    local function inv(rf, ...)
        local n, a = select("#", ...), { ... }
        local okC, r1, r2 = pcall(function()
            return rf:InvokeServer(table.unpack(a, 1, n))
        end)
        if not okC then
            return false, firstLine(r1)
        end
        return r1, r2
    end
    local getSave = Save and (Save.Peek or Save.Get)
    local function snap()
        local s = getSave and getSave()
        return type(s) == "table" and s or nil
    end
    local save = snap()
    if not save then
        return 0, "save data not ready"
    end
    if save.FusionEggReward ~= false and save.FusionEggReward ~= nil then
        local r1, r2 = inv(F.FinishReveal)
        if not r1 then
            return 0, "could not collect the pending fused egg: " .. tostring(r2)
        end
        logRun("Auto Fuse: collected a pending fused egg")
        task.wait(1)
        save = snap() or save
    end
    if save.FusionLocked then
        return 0, "the fuse machine is busy"
    end
    local slots = type(save.FusionSlots) == "table" and save.FusionSlots or {}
    local inMachine = {}
    for _, uid in pairs(slots) do
        if type(uid) == "string" then
            inMachine[#inMachine + 1] = uid
        end
    end
    if #inMachine > 0 and live() then
        if cfg.fuse.ejectPartial == false then
            return 0,
                string.format("the fuse machine holds %d leftover pet(s) (Eject Incomplete Slots is off)", #inMachine)
        end
        for _, uid in ipairs(inMachine) do
            local r1, r2 = inv(F.EjectPet, uid)
            if not r1 then
                return 0, "could not take a leftover pet out of the machine: " .. tostring(r2 or "no reason given")
            end
            task.wait(0.15)
        end
        logRun("Auto Fuse: took " .. #inMachine .. " leftover pet(s) out of the machine")
        task.wait(0.5)
        save = snap() or save
        slots = type(save.FusionSlots) == "table" and save.FusionSlots or {}
    end
    if next(slots) ~= nil then
        return 0, "the fuse machine already has pets loaded"
    end
    local Kernel, AssetItems, EggsT
    pcall(function()
        Kernel = require(rep.Shared.Util.FuseKernel)
    end)
    pcall(function()
        AssetItems = require(rep.Shared.Util.AssetItems)
    end)
    pcall(function()
        EggsT = require(rep.Shared.Types.Eggs)
    end)
    local maxEggs = EggsT and tonumber(EggsT.MAX_INVENTORY) or 115
    local incEq = cfg.fuse.includeEquipped == true
    local keepBest = math.max(1, tonumber(cfg.fuse.keepBest) or 1)
    local equipped = {}
    for _, uid in ipairs(save.EquippedAssets or {}) do
        equipped[uid] = true
    end
    local rift = Feat.riftSet() or {}
    local maxRank = Feat.RARITY_RANKS[cfg.fuse.maxRarity] or 0
    local skipMut = cfg.fuse.skipMutated ~= false
    local groups, skippedEq = {}, 0
    for uid, raw in pairs(save.Inventory or {}) do
        local cat = type(raw) == "table" and raw.Category
        local conf = cat and Assets and Assets.Directory[cat]
        if
            type(uid) == "string"
            and conf
            and not conf.CannotFuse
            and not raw.IsFavorite
            and not raw.InFuse
            and raw.CreatorTemporary ~= true
            and not rift[cat]
            and not (skipMut and (raw.BaseMutation ~= nil or (type(raw.Mutations) == "table" and #raw.Mutations > 0)))
            and (maxRank == 0 or select(2, eggRarity({ AssetCategory = cat })) <= maxRank)
        then
            if equipped[uid] and not incEq then
                skippedEq += 1
            else
                local okR, rate = pcall(AssetEarnings.RatePerSecond, raw)
                groups[cat] = groups[cat] or {}
                table.insert(groups[cat], { uid = uid, raw = raw, rate = okR and tonumber(rate) or 0 })
            end
        end
    end
    local order = {}
    for cat, pets in pairs(groups) do
        table.sort(pets, function(a, b)
            return a.rate > b.rate
        end)
        local extras = {}
        for i = keepBest + 1, #pets do
            extras[#extras + 1] = pets[i]
        end
        if #extras >= 3 then
            order[#order + 1] = { cat = cat, extras = extras, low = extras[#extras].rate }
        end
    end
    local byDup = cfg.fuse.priority == "Most Duplicates First"
    table.sort(order, function(a, b)
        if byDup and #a.extras ~= #b.extras then
            return #a.extras > #b.extras
        end
        if a.low ~= b.low then
            return a.low < b.low
        end
        return a.cat < b.cat
    end)
    local fused, why = 0, nil
    for _, g in ipairs(order) do
        local cat, extras = g.cat, g.extras
        while #extras >= 3 and live() do
            local trio = { table.remove(extras), table.remove(extras), table.remove(extras) }
            local cur = snap() or save
            local eggN = 0
            for _ in pairs(cur.EggInventory or {}) do
                eggN += 1
            end
            if eggN >= maxEggs then
                return fused, "your egg inventory is full"
            end
            if Kernel and AssetItems then
                local okP, price = pcall(function()
                    return Kernel.PriceFor({
                        AssetItems.Decode(trio[1].raw),
                        AssetItems.Decode(trio[2].raw),
                        AssetItems.Decode(trio[3].raw),
                    })
                end)
                if okP and tonumber(price) and money() < price then
                    return fused, "not enough money for a fuse ($" .. shortNum(price) .. ")"
                end
            end
            if cur.FusionInfoAcknowledged == false then
                inv(F.ConfirmBriefing)
            end
            local loaded = {}
            for _, pet in ipairs(trio) do
                if not live() then
                    why = "stopped"
                    break
                end
                local r1, r2 = inv(F.LoadPet, pet.uid, incEq)
                if not r1 then
                    why = "the server refused a pet: " .. tostring(r2 or "no reason given")
                    break
                end
                loaded[#loaded + 1] = pet.uid
                task.wait(0.25)
            end
            local began = false
            if #loaded == 3 then
                local r1, r2 = inv(F.BeginFuse)
                if r1 then
                    began = true
                else
                    why = "the server refused the fuse: " .. tostring(r2 or "no reason given")
                end
            end
            if not began then
                for _, uid in ipairs(loaded) do
                    inv(F.EjectPet, uid)
                    task.wait(0.15)
                end
                return fused, why
            end
            task.wait(2.5)
            local r1, r2 = inv(F.FinishReveal)
            if not r1 then
                return fused,
                    "the fused egg was not granted yet: "
                        .. tostring(r2 or "no reason given")
                        .. " (the next run collects it)"
            end
            fused += 1
            logRun("Auto Fuse: fused 3 " .. tostring(cat) .. " pets into an egg")
            task.wait(0.5)
        end
    end
    if fused > 0 then
        return fused
    end
    return 0,
        (skippedEq > 0 and not incEq) and "no 3 spare pets of one type (equipped pets are skipped)"
            or "no 3 spare pets of one type"
end

function Feat.petLabelOf(cat)
    local conf = Assets and Assets.Directory and Assets.Directory[cat]
    return tostring(conf and conf.DisplayName or cat)
end

function Feat.riftPick(reqs, save)
    local Kernel
    pcall(function()
        Kernel = require(rep.Shared.Util.FuseKernel)
    end)
    local equipped = {}
    for _, uid in ipairs(save.EquippedAssets or {}) do
        equipped[uid] = true
    end
    local skipMut = cfg.rift.skipMutated ~= false
    local picked, used, missing = {}, {}, {}
    for i, cat in ipairs(reqs) do
        local best, bestRate
        for uid, raw in pairs(save.Inventory or {}) do
            if
                type(raw) == "table"
                and raw.Category == cat
                and not used[uid]
                and not equipped[uid]
                and not raw.IsFavorite
                and not raw.InFuse
                and not (
                    skipMut and (raw.BaseMutation ~= nil or (type(raw.Mutations) == "table" and #raw.Mutations > 0))
                )
            then
                local okE, elig = true, true
                if Kernel and Kernel.MayEnterRift then
                    okE, elig = pcall(Kernel.MayEnterRift, uid, raw)
                end
                if okE and elig == true then
                    local okR, rate = pcall(AssetEarnings.RatePerSecond, raw)
                    rate = okR and tonumber(rate) or math.huge
                    if not bestRate or rate < bestRate then
                        best, bestRate = uid, rate
                    end
                end
            end
        end
        if best then
            picked[i] = best
            used[best] = true
        else
            missing[#missing + 1] = cat
        end
    end
    return picked, missing
end

function Feat.riftStep(manual, mode, expect)
    local R = Remotes and Remotes.Rift
    if not (R and R.AskState and R.AskTradeIn and R.AskFinishReveal and R.AskRefresh) then
        return false, "Rift remotes not found"
    end
    local okE, Elig = pcall(function()
        return require(rep.Shared.Util.RiftEligibility)
    end)
    if okE and type(Elig) == "table" and type(Elig.IsFeatureLive) == "function" then
        local okL, isLive = pcall(Elig.IsFeatureLive)
        if okL and isLive == false then
            return false, "the Rift is closed right now"
        end
    end
    local getSave = Save and (Save.Peek or Save.Get)
    local function riftSave()
        local s = getSave and getSave()
        return type(s) == "table" and s or nil
    end
    local function names(cats)
        local t = {}
        for _, c in ipairs(cats) do
            t[#t + 1] = Feat.petLabelOf(c)
        end
        return table.concat(t, ", ")
    end
    local save = riftSave()
    if not save then
        return false, "save data not ready"
    end
    local rsv = type(save.Rift) == "table" and save.Rift or {}
    local reqs = rsv.Requirements
    if type(reqs) ~= "table" or #reqs < 3 then
        return false, "the Rift has no recipe right now"
    end
    local picked, missing = Feat.riftPick(reqs, save)
    local want = {}
    if mode == "reroll" then
        for _, c in ipairs(missing) do
            want[c] = true
        end
        for _, raw in pairs(next(want) and save.Inventory or {}) do
            if type(raw) == "table" and raw.Category then
                want[raw.Category] = nil
            end
        end
        for uid in pairs(next(want) and save.EggInventory or {}) do
            local e = Feat.ownedEgg(uid, save)
            if e then
                want[e.cat] = nil
            end
        end
        local okF, recs = pcall(function()
            return EggState.ReadFieldEggs().Records
        end)
        for _, rec in ipairs(next(want) and okF and recs or {}) do
            want[rec.AssetCategory] = nil
        end
        if next(want) == nil then
            return false, nil
        end
    elseif #missing > 0 and not rsv.PendingReward then
        return false, "no spare pet for: " .. names(missing)
    end
    local okS, st = pcall(function()
        return R.AskState:InvokeServer()
    end)
    if not okS or type(st) ~= "table" then
        return false, "Rift state unavailable"
    end
    if st.Unlocked == false then
        return false, "the Rift is locked for you"
    end
    if st.PendingReward or rsv.PendingReward then
        pcall(function()
            return R.AskFinishReveal:InvokeServer()
        end)
        task.wait(1)
        local s2 = riftSave()
        if s2 and type(s2.Rift) == "table" and s2.Rift.PendingReward then
            return false, "the last Rift egg could not be collected yet"
        end
        logRun("Rift: collected a pending Rift egg")
    end
    if mode == "reroll" then
        local free = tonumber(st.FreeRefreshesRemaining) or 0
        if free <= 0 then
            return false, "no free reroll left today"
        end
        if not manual and not cfg.auto.riftReroll then
            return false, "stopped"
        end
        local okP, r1, r2 = pcall(function()
            return R.AskRefresh:InvokeServer()
        end)
        if not okP then
            return false, "reroll failed: " .. firstLine(r1)
        end
        if r1 ~= true then
            return false, "reroll refused: " .. tostring(r2 or "no reason given")
        end
        local lost = {}
        for c in pairs(want) do
            lost[#lost + 1] = c
        end
        logRun("Rift: rerolled the recipe (could not get " .. names(lost) .. ")")
        return true, "recipe rerolled"
    end
    local sreq = st.Requirements
    if type(sreq) == "table" and #sreq >= 3 and (sreq[1] ~= reqs[1] or sreq[2] ~= reqs[2] or sreq[3] ~= reqs[3]) then
        reqs = sreq
        picked, missing = Feat.riftPick(reqs, riftSave() or save)
    end
    if #missing > 0 then
        return false, "no spare pet for: " .. names(missing)
    end
    if expect and (picked[1] ~= expect[1] or picked[2] ~= expect[2] or picked[3] ~= expect[3]) then
        return false, "the recipe or your pets changed, press Sacrifice Now again"
    end
    if not manual and not cfg.auto.rift then
        return false, "stopped"
    end
    local okT, r1, r2 = pcall(function()
        return R.AskTradeIn:InvokeServer({ picked[1], picked[2], picked[3] })
    end)
    if not okT then
        return false, "the trade-in failed: " .. firstLine(r1)
    end
    if r1 ~= true then
        return false, "the Rift refused the trade: " .. tostring(r2 or "no reason given")
    end
    logRun("Rift: sacrificed " .. names({ reqs[1], reqs[2], reqs[3] }))
    task.wait(1.5)
    pcall(function()
        return R.AskFinishReveal:InvokeServer()
    end)
    task.wait(1)
    local after = riftSave()
    if after and type(after.Rift) == "table" and after.Rift.PendingReward then
        return true, "traded; the Rift egg is collected on the next run"
    end
    return true, "traded 3 pets for a Rift egg"
end

function Feat.riftRun(manual, mode, expect)
    if state.riftBusy then
        return false, "a Rift run is already in progress"
    end
    state.riftBusy = true
    local ok, done, why = pcall(Feat.riftStep, manual, mode or "trade", expect)
    state.riftBusy = false
    if not ok then
        done, why = false, firstLine(done)
    end
    if not manual and why and why ~= state.riftLastWhy then
        logRun("Rift: " .. why)
    end
    state.riftLastWhy = why
    return done, why
end

local function tpToArea(areaId)
    local area = guardArea(areaId)
    local b = area and area:FindFirstChild("Bounds")
    local minX = boundsMinX(areaId)
    local pos = (b and minX) and Vector3.new(minX - 6, b.Position.Y, b.Position.Z) or nil
    walkAnywhere(pos, areaId, true)
end

local function tpToOwnPlot()
    local ok, plot = pcall(PlotState.ResolvePlot)
    plot = ok and plot or nil
    local cf = plot and (plot.RespawnPointCFrame or (plot.CenterPoint and plot.CenterPoint.CFrame))
    walkAnywhere(cf and cf.Position, "My Plot", true)
end

local function tpToMachine(name)
    local objs = workspace:FindFirstChild("__OBJECTS") or workspace:FindFirstChild("World")
    local m = objs and objs:FindFirstChild("Machines") and objs.Machines:FindFirstChild(name)
    local pos
    if m then
        pcall(function()
            pos = m:GetPivot().Position
        end)
    end
    walkAnywhere(pos, name, true)
end

function Feat.bossFlag(name)
    if Feat.BossFlags == nil then
        local ok, F = pcall(function()
            return require(rep.Shared.Flags.BossEventFlags)
        end)
        Feat.BossFlags = ok and type(F) == "table" and F or false
    end
    local f = Feat.BossFlags and Feat.BossFlags[name]
    if f == nil then
        return nil
    end
    local ok, v = pcall(function()
        return f:Get()
    end)
    if ok then
        return v
    end
    return nil
end

function Feat.bossWindow()
    if Feat.BossData == nil then
        local ok, D = pcall(function()
            return require(rep.Data.BossEvent)
        end)
        Feat.BossData = ok and type(D) == "table" and D or false
    end
    if not Feat.BossData then
        return nil
    end
    local ok, w = pcall(Feat.BossData.CurrentWindow, tonumber(Feat.bossFlag("WindowDurationSeconds")) or 330)
    return ok and type(w) == "table" and w or nil
end

function Feat.tryEnterBoss()
    if lp:GetAttribute("InBossArena") then
        return true
    end
    if Feat.bossFlag("Enabled") == false then
        return false, "the boss event is turned off in the game"
    end
    local w = Feat.bossWindow()
    if w and not w.Open then
        return false, "the arena is closed (opens in " .. fmtDuration(w.OpensAt - workspace:GetServerTimeNow()) .. ")"
    end
    local rf = netRF("BossEvent/AskEnter")
    if not rf then
        return false, "enter remote not found"
    end
    local okC, r1, r2 = pcall(function()
        return rf:InvokeServer()
    end)
    if not okC then
        return false, firstLine(r1)
    end
    local t0 = os.clock()
    while os.clock() - t0 < 3 do
        if lp:GetAttribute("InBossArena") then
            return true
        end
        task.wait(0.2)
    end
    local msg = (type(r2) == "string" and r2 ~= "" and r2) or (type(r1) == "string" and r1 ~= "" and r1)
    return false, msg or "the server did not move you into the arena"
end

function Feat.autoEnterBoss(w)
    if lp:GetAttribute("InBossArena") then
        state.bossEnteredFor = w.ClosesAt
        return
    end
    if state.bossEnteredFor == w.ClosesAt or state.bossEntering or Feat.stealBusy() or state.carry then
        return
    end
    if state.bossRetryFor == w.ClosesAt and os.clock() < (state.bossRetryAt or 0) then
        return
    end
    state.bossEntering = true
    if state.running then
        state.bestHoldUntil = os.clock() + 8
    end
    task.spawn(function()
        local okT, ok, why = pcall(Feat.tryEnterBoss)
        state.bossEntering = false
        if okT and ok then
            state.bossEnteredFor = w.ClosesAt
            logRun("Boss: entered the arena")
            return
        end
        why = okT and tostring(why) or firstLine(ok)
        state.bossDelay = state.bossRetryFor == w.ClosesAt and math.min((state.bossDelay or 10) * 2, 60) or 10
        state.bossRetryFor, state.bossRetryAt = w.ClosesAt, os.clock() + state.bossDelay
        logRun(string.format("Boss: could not enter (%s), retrying in %ds", why, state.bossDelay))
    end)
end

function Feat.updateBossLabel()
    local w = Feat.bossWindow()
    local now = workspace:GetServerTimeNow()
    local txt
    if Feat.bossFlag("Enabled") == false then
        txt = "Boss event is turned off in the game right now"
    elseif not w then
        txt = "Boss status unavailable"
    elseif w.Open then
        txt = "OPEN | Closes in " .. fmtDuration(w.ClosesAt - now)
        if cfg.boss.autoEnter then
            Feat.autoEnterBoss(w)
        end
    else
        txt = "CLOSED | Opens in " .. fmtDuration(w.OpensAt - now)
    end
    if lp:GetAttribute("InBossArena") then
        txt = txt .. " | You are in the arena"
    end
    if state.bossLbl then
        Feat.ui(function()
            state.bossLbl:Set(txt)
        end)
    end
    local tokens = Feat.bossTokens()
    if state.bossTokLbl then
        Feat.ui(function()
            state.bossTokLbl:Set("Boss Tokens: " .. (tokens and tostring(tokens) or "?"))
        end)
    end
end

function Feat.startBossTrack()
    if state.bossConn then
        return
    end
    state.bossConn = H.task(function()
        pcall(Feat.updateBossLabel)
    end, 1, 0)
end

function Feat.stopBossTrack()
    if state.bossConn then
        state.bossConn.stop()
        state.bossConn = nil
    end
end

pcall(function()
    Feat.LvdData = require(rep.Data.LightVsDarkness)
end)
pcall(function()
    Feat.SammyData = require(rep.Data.SammyEvent)
end)

Feat.groundParams = RaycastParams.new()
Feat.groundParams.FilterType = Enum.RaycastFilterType.Exclude
function Feat.groundAt(x, z, fallbackY)
    Feat.groundParams.FilterDescendantsInstances = { lp.Character }
    local hit = workspace:Raycast(Vector3.new(x, 2000, z), Vector3.new(0, -4000, 0), Feat.groundParams)
    return hit and hit.Position.Y or fallbackY
end

function Feat.collectorsBusy(owner)
    return Feat.stealBusy()
        or state.carry ~= nil
        or (state.manualWalk ~= nil and state.manualWalk ~= "collector")
        or (owner ~= nil and state.collectorOwner ~= nil and state.collectorOwner ~= owner and (state.manualWalk == "collector" or os.clock() - (state.collectorAt or 0) < 3))
        or os.clock() < (state.collectPauseUntil or 0)
        or lp:GetAttribute("InBossArena") == true
        or os.clock() - (state.correctionAt or 0) < 30
end

function Feat.tpTo(pos, owner, isActive, tol)
    if Feat.collectorsBusy(owner) then
        return false, "busy"
    end
    local gy = Feat.groundAt(pos.X, pos.Z, pos.Y)
    if math.abs(pos.Y - gy) > 8 then
        return false, "air"
    end
    local tok = state.collectorToken or 0
    state.collectorOwner, state.collectorAt = owner, os.clock()
    state.trainPauseUntil = math.max(state.trainPauseUntil or 0, os.clock() + 30)
    local tw = os.clock()
    while state.trainWalking and os.clock() - tw < 2 do
        task.wait(0.1)
    end
    if state.trainWalking or (state.beltId ~= nil and not leaveTreadmill(4)) then
        return false, "busy"
    end
    if Feat.collectorsBusy(owner) or (state.collectorToken or 0) ~= tok then
        return false, "busy"
    end
    state.manualWalk = "collector"
    setUserControls(false)
    local okW, ok = pcall(walkTo, Vector3.new(pos.X, gy, pos.Z), 0, {
        tol = tol or 3,
        timeout = 20,
        stillFn = function()
            return not state.destroyed
                and (state.collectorToken or 0) == tok
                and (not isActive or isActive())
                and not Feat.stealBusy()
                and state.carry == nil
                and state.manualWalk == "collector"
        end,
    })
    if state.manualWalk == "collector" then
        state.manualWalk = nil
    end
    state.collectorAt = os.clock()
    releaseControls()
    if okW and ok == true then
        return true
    end
    return false, "failed"
end

function Feat.collectorLoop(label, isActive, pass, wake)
    task.spawn(function()
        local lastErr
        while isActive() do
            local ok, secs = pcall(pass)
            if not ok then
                local msg = firstLine(secs)
                if msg ~= lastErr then
                    lastErr = msg
                    logRun(label .. " error: " .. msg)
                end
                secs = 5
            end
            local t0 = os.clock()
            repeat
                task.wait(0.25)
            until not isActive() or os.clock() - t0 >= (tonumber(secs) or 2) or (wake and wake())
        end
    end)
end

Feat.liveEnds = {}
function Feat.watchLiveEvents()
    if Feat.liveWatch then
        return
    end
    local began, ended = netRE("LiveEvents/Began"), netRE("LiveEvents/Ended")
    if not (began and ended) then
        return
    end
    Feat.liveWatch = true
    table.insert(
        conns,
        began.OnClientEvent:Connect(function(name, dur)
            if type(name) == "string" and type(dur) == "number" then
                Feat.liveEnds[name] = workspace:GetServerTimeNow() + dur
            end
        end)
    )
    table.insert(
        conns,
        ended.OnClientEvent:Connect(function(name)
            if type(name) == "string" then
                Feat.liveEnds[name] = nil
            end
        end)
    )
    Feat.liveKnown = true
end

function Feat.liveRunning(name)
    local e = Feat.liveEnds[name]
    if e ~= nil and e > workspace:GetServerTimeNow() then
        return true
    end
    if Feat.liveKnown then
        return false
    end
    return nil
end

function Feat.waveTracker(reCollected, reRespawned, reSpawned)
    local t = { wave = nil, done = {}, dirty = true }
    local cs = {}
    if reCollected then
        cs[#cs + 1] = reCollected.OnClientEvent:Connect(function(w, zone, id)
            if w ~= t.wave or zone == nil or id == nil then
                return
            end
            t.done[zone] = t.done[zone] or {}
            t.done[zone][id] = true
        end)
    end
    if reRespawned then
        cs[#cs + 1] = reRespawned.OnClientEvent:Connect(function(w, zone, id)
            if w == t.wave and t.done[zone] and id ~= nil then
                t.done[zone][id] = nil
            end
            t.dirty = true
        end)
    end
    for _, re in ipairs(reSpawned or {}) do
        cs[#cs + 1] = re.OnClientEvent:Connect(function()
            t.dirty = true
        end)
    end
    for _, c in ipairs(cs) do
        table.insert(conns, c)
    end
    function t.stop()
        for _, c in ipairs(cs) do
            pcall(function()
                c:Disconnect()
            end)
        end
    end
    return t
end

function Feat.collectZoneWave(isActive, fetch, decode, re, label, tr)
    tr.dirty = false
    local waveId, zones, collected = fetch()
    if type(waveId) ~= "number" or type(zones) ~= "table" then
        return 0, 0
    end
    if tr.wave ~= waveId then
        tr.wave, tr.done, tr.tries = waveId, {}, {}
    end
    local done, tries = tr.done, tr.tries or {}
    tr.tries = tries
    for zone, ids in pairs(type(collected) == "table" and collected or {}) do
        done[zone] = done[zone] or {}
        for _, id in ipairs(type(ids) == "table" and ids or {}) do
            done[zone][id] = true
        end
    end
    local open = {}
    for zone, buf in pairs(zones) do
        local ok, points = pcall(decode, buf)
        if ok and type(points) == "table" then
            for id, p in ipairs(points) do
                if not (done[zone] and done[zone][id]) and (tries[zone .. ":" .. id] or 0) < 3 then
                    open[#open + 1] = { zone = zone, id = id, pos = Vector3.new(p.X, p.Y, p.Z) }
                end
            end
        end
    end
    local n, air = 0, 0
    while #open > 0 and isActive() do
        local _, root = charParts()
        local bi, bd = 1, math.huge
        if root then
            for i, o in ipairs(open) do
                local d = xz(o.pos, root.Position)
                if d < bd then
                    bi, bd = i, d
                end
            end
        end
        local o = table.remove(open, bi)
        if not (done[o.zone] and done[o.zone][o.id]) then
            local ok, why = Feat.tpTo(o.pos, label, isActive)
            local key = o.zone .. ":" .. o.id
            if ok or why == "failed" then
                tries[key] = (tries[key] or 0) + 1
            end
            if ok then
                task.wait(0.05)
                pcall(function()
                    re:FireServer(waveId, o.zone, o.id)
                end)
                n += 1
                task.wait(0.03)
            elseif why == "air" then
                air += 1
            elseif why == "busy" then
                break
            end
        end
    end
    if n > 0 then
        setStatus(string.format("%s: collected %d", label, n))
    end
    if air > 0 and n == 0 and not state.running then
        setStatus(string.format("%s: %d point(s) are up in the air, out of walking reach", label, air))
    end
    return n, air
end

function Feat.collectPowerUps(isActive, re, rf, label)
    local ok, batchId, items = pcall(function()
        return rf:InvokeServer()
    end)
    if not ok or type(batchId) ~= "number" or type(items) ~= "table" then
        return 0
    end
    local now = workspace:GetServerTimeNow()
    local _, root = charParts()
    local n = 0
    for _, it in pairs(items) do
        if not isActive() then
            break
        end
        if type(it) == "table" and it.Id ~= nil and it.X and it.Z and (not it.LandAt or it.LandAt <= now) then
            local y = Feat.groundAt(it.X, it.Z, root and root.Position.Y or 50)
            local okT, why = Feat.tpTo(Vector3.new(it.X, y + 3, it.Z), label, isActive)
            if okT then
                task.wait(0.06)
                pcall(function()
                    re:FireServer(batchId, it.Id)
                end)
                n += 1
            elseif why == "busy" then
                break
            end
        end
    end
    return n
end

function Feat.lvdTeamOk()
    return type(lp:GetAttribute("LvdTeam")) == "string"
end

function Feat.startLVD()
    if state.lvdConn then
        return
    end
    Feat.watchLiveEvents()
    local reRing = netRE("LightVsDarkness/AskCollectRing")
    local rePow = netRE("LightVsDarkness/AskCollectPowerUp")
    local rfRings = netRF("LightVsDarkness/FetchRings")
    local rfPow = netRF("LightVsDarkness/FetchPowerUps")
    local tr = Feat.waveTracker(
        netRE("LightVsDarkness/RingCollected"),
        netRE("LightVsDarkness/RingRespawned"),
        { netRE("LightVsDarkness/RingsSpawned"), netRE("LightVsDarkness/PowerUpsDropped") }
    )
    local alive = true
    local function isActive()
        return alive and not state.destroyed
    end
    state.lvdConn = {
        Disconnect = function()
            alive = false
            tr.stop()
        end,
    }
    local warned, backoff = false, 2
    Feat.collectorLoop("LvD", isActive, function()
        if Feat.collectorsBusy("LvD") then
            return 1
        end
        if Feat.liveRunning("LightVsDarkness") == false then
            backoff = 2
            return 3
        end
        if not Feat.lvdTeamOk() then
            if not warned and Feat.liveRunning("LightVsDarkness") == true then
                setStatus(
                    cfg.auto.lvdTeam and "LvD: joining a team..."
                        or "LvD: pick a team first (or turn on Auto Pick Team)"
                )
                warned = true
            end
            return 3
        end
        warned = false
        tr.dirty = false
        local mode = cfg.events.lvdMode or "All"
        local got = 0
        if mode ~= "Powers Only" and reRing and rfRings and Feat.LvdData then
            got += Feat.collectZoneWave(isActive, function()
                local ok, w, _, z, c = pcall(function()
                    return rfRings:InvokeServer()
                end)
                if ok then
                    return w, z, c
                end
            end, Feat.LvdData.DecodeRings, reRing, "LvD", tr)
        end
        if mode ~= "Rings Only" and rePow and rfPow then
            got += Feat.collectPowerUps(isActive, rePow, rfPow, "LvD")
        end
        if got > 0 then
            backoff = 2
            return 0.5
        end
        backoff = math.min(backoff * 2, 20)
        return backoff
    end, function()
        return tr.dirty
    end)
end

function Feat.stopLVD()
    if state.lvdConn then
        state.lvdConn:Disconnect()
        state.lvdConn = nil
    end
end

function Feat.lvdRemote(name)
    local ok, r = pcall(function()
        return Remotes.LightVsDarkness[name]
    end)
    return (ok and r) or netRE("LightVsDarkness/" .. name)
end

function Feat.lvdPickTeam()
    Feat.watchLiveEvents()
    if Feat.lvdTeamOk() or Feat.liveRunning("LightVsDarkness") ~= true then
        return
    end
    if os.clock() < (state.lvdTeamRetry or 0) then
        return
    end
    local re = Feat.lvdRemote("AskSelectTeam")
    if not re then
        return
    end
    local team = cfg.events.lvdTeam
    if team ~= "Light" and team ~= "Darkness" then
        team = "Random"
    end
    state.lvdTeamRetry = os.clock() + 15
    pcall(function()
        re:FireServer(team)
    end)
    local t0 = os.clock()
    while os.clock() - t0 < 4 and not Feat.lvdTeamOk() do
        task.wait(0.25)
    end
    if Feat.lvdTeamOk() then
        logRun("LvD: joined team " .. tostring(lp:GetAttribute("LvdTeam")))
    else
        logRun("LvD: team request (" .. team .. ") not accepted yet, retrying in 15 s")
    end
end

function Feat.lvdClaimMilestones(manual)
    local D = Feat.LvdData
    local re = Feat.lvdRemote("AskClaimMilestone")
    if not (D and type(D.MILESTONES) == "table" and type(D.MilestoneAttribute) == "function" and re) then
        return 0, "LvD data or remote not found"
    end
    if not Feat.lvdTeamOk() then
        return 0, "join a team first"
    end
    local rings = tonumber(lp:GetAttribute("LvdRingsCollected")) or 0
    local n, why = 0, nil
    for i, m in ipairs(D.MILESTONES) do
        if state.destroyed or (not manual and not cfg.auto.lvdClaim) then
            break
        end
        local okA, attr = pcall(D.MilestoneAttribute, i)
        local need = type(m) == "table" and tonumber(m.Rings)
        if okA and type(attr) == "string" and need and rings >= need and lp:GetAttribute(attr) ~= true then
            pcall(function()
                re:FireServer(i)
            end)
            local t0 = os.clock()
            while os.clock() - t0 < 3 and lp:GetAttribute(attr) ~= true do
                task.wait(0.25)
            end
            if lp:GetAttribute(attr) == true then
                n += 1
                logRun(string.format("LvD: claimed milestone %d (%s)", i, tostring(m.Reward or "reward")))
            else
                why = string.format("milestone %d was not confirmed by the server", i)
                if manual or why ~= state.lvdClaimWhy then
                    logRun("LvD: " .. why)
                end
                break
            end
        end
    end
    state.lvdClaimWhy = why
    if n == 0 and not why then
        why = string.format("nothing to claim (%d rings)", rings)
    end
    return n, why
end

function Feat.startScramble()
    if state.scramConn then
        return
    end
    local re = netRE("Scramble/Collect")
    local reDrops = netRE("Scramble/Drops")
    local reRem = netRE("Scramble/RemoveDrops")
    if not (re and reDrops) then
        BPUI:Notify({ Title = "Scramble", Content = "Scramble remotes not found", Type = "Warning", Duration = 3 })
        return
    end
    local magnetSecs = 0.52
    pcall(function()
        magnetSecs = tonumber(require(rep.Shared.Util.ScramblePickupMotion).MagnetSeconds) or magnetSecs
    end)
    local drops = {}
    local c1 = reDrops.OnClientEvent:Connect(function(list)
        if type(list) ~= "table" then
            return
        end
        for _, d in pairs(list) do
            if
                type(d) == "table"
                and d.Id ~= nil
                and typeof(d.Origin) == "Vector3"
                and (d.OwnerUserId == nil or d.OwnerUserId == lp.UserId)
            then
                drops[d.Id] = d
            end
        end
    end)
    local c2 = reRem
        and reRem.OnClientEvent:Connect(function(ids)
            if type(ids) ~= "table" then
                return
            end
            for _, id in pairs(ids) do
                drops[id] = nil
            end
        end)
    local alive = true
    local function isActive()
        return alive and not state.destroyed
    end
    state.scramConn = {
        Disconnect = function()
            alive = false
            pcall(function()
                c1:Disconnect()
            end)
            if c2 then
                pcall(function()
                    c2:Disconnect()
                end)
            end
        end,
    }
    local function collect(list)
        local ids = {}
        for _, d in ipairs(list) do
            if #ids >= 8 then
                break
            end
            d._tries = (d._tries or 0) + 1
            d._next = os.clock() + 1
            ids[#ids + 1] = d.Id
        end
        if #ids > 0 then
            pcall(function()
                re:FireServer(ids)
            end)
        end
        return #ids
    end
    Feat.collectorLoop("Scramble", isActive, function()
        local now = workspace:GetServerTimeNow()
        local magnet, walk = {}, {}
        for id, d in pairs(drops) do
            if (d.ExpiresAt and d.ExpiresAt <= now) or (d._tries or 0) >= 4 then
                drops[id] = nil
            elseif (not d.CollectAfter or d.CollectAfter <= now) and os.clock() >= (d._next or 0) then
                if d.MagnetAt and d.OwnerUserId == lp.UserId then
                    if now >= d.MagnetAt + magnetSecs then
                        magnet[#magnet + 1] = d
                    end
                else
                    walk[#walk + 1] = d
                end
            end
        end
        local fired = collect(magnet) > 0
        if #walk > 0 and not Feat.collectorsBusy("Scramble") then
            local function landAt(d)
                return typeof(d.Position) == "Vector3" and d.Position or d.Origin
            end
            local _, root = charParts()
            if root then
                table.sort(walk, function(a, b)
                    return xz(landAt(a), root.Position) < xz(landAt(b), root.Position)
                end)
            end
            local d = walk[1]
            local r = tonumber(d.Radius) or 0
            local ok, why = Feat.tpTo(landAt(d), "Scramble", isActive, math.max(1, r > 0 and r * 0.5 or 2))
            if ok then
                task.wait(0.05)
                local _, root2 = charParts()
                local near = { d }
                for _, o in ipairs(walk) do
                    if o ~= d and root2 and (root2.Position - landAt(o)).Magnitude <= (tonumber(o.Radius) or 0) then
                        near[#near + 1] = o
                    end
                end
                fired = collect(near) > 0 or fired
            elseif why == "air" then
                d._tries = 4
            elseif why == "failed" then
                d._tries = (d._tries or 0) + 1
            end
        end
        return fired and 0.25 or 0.4
    end)
end

function Feat.stopScramble()
    if state.scramConn then
        state.scramConn:Disconnect()
        state.scramConn = nil
    end
end

function Feat.startSammy()
    if state.sammyConn then
        return
    end
    Feat.watchLiveEvents()
    local re = netRE("SammyEvent/AskCollectPickup")
    local rf = netRF("SammyEvent/FetchPickups")
    local tr = Feat.waveTracker(
        netRE("SammyEvent/PickupCollected"),
        netRE("SammyEvent/PickupRespawned"),
        { netRE("SammyEvent/PickupsSpawned") }
    )
    local alive = true
    local function isActive()
        return alive and not state.destroyed
    end
    state.sammyConn = {
        Disconnect = function()
            alive = false
            tr.stop()
        end,
    }
    local backoff = 2
    Feat.collectorLoop("Sammy", isActive, function()
        if not (re and rf and Feat.SammyData) or Feat.collectorsBusy("Sammy") then
            return 2
        end
        if Feat.liveRunning("SammyEvent") == false then
            backoff = 2
            return 3
        end
        local got = Feat.collectZoneWave(isActive, function()
            local ok, w, z, c = pcall(function()
                return rf:InvokeServer()
            end)
            if ok then
                return w, z, c
            end
        end, Feat.SammyData.DecodePickups, re, "Sammy", tr)
        if got > 0 then
            backoff = 2
            return 0.5
        end
        backoff = math.min(backoff * 2, 20)
        return backoff
    end, function()
        return tr.dirty
    end)
end

function Feat.stopSammy()
    if state.sammyConn then
        state.sammyConn:Disconnect()
        state.sammyConn = nil
    end
end

function Feat.collectAwayEarnings()
    local AE = Remotes and Remotes.AwayEarnings
    local rfSum = AE and AE.FetchSummary or netRF("AwayEarnings/FetchSummary")
    local rfCol = AE and AE.AskCollect or netRF("AwayEarnings/AskCollect")
    if not rfCol then
        return false, "Offline income remote not found"
    end
    local claimable
    if rfSum then
        local okS, s = pcall(function()
            return rfSum:InvokeServer()
        end)
        if okS and type(s) == "table" then
            claimable = tonumber(s.ClaimableAmount)
        end
    end
    if claimable == nil then
        pcall(function()
            claimable = tonumber(Save.Peek().PendingOfflineMoney)
        end)
    end
    if not claimable or claimable <= 0 then
        return false, "No pending offline income"
    end
    local okC, ok, msg, res = pcall(function()
        return rfCol:InvokeServer({ Kind = "Claim" })
    end)
    if okC and ok == true and type(res) == "table" then
        BPUI:Notify({
            Title = "Offline Income",
            Content = "Collected $" .. shortNum(res.AwardedAmount or claimable),
            Type = "Success",
            Duration = 3,
        })
        logRun("Offline Income: collected $" .. shortNum(res.AwardedAmount or claimable))
        state.awayLastWhy = nil
        return true
    end
    local why = not okC and firstLine(ok)
        or (type(msg) == "string" and msg ~= "" and msg)
        or "the server refused the claim (walking over the money pile on your plot also claims it)"
    if why ~= state.awayLastWhy then
        logRun("Offline Income: " .. why)
    end
    state.awayLastWhy = why
    return false, why
end

function Feat.startAwayEarnings()
    if state.awayConn then
        return
    end
    local el = 0
    state.awayConn = rs.Heartbeat:Connect(function(dt)
        el += dt
        if el < 60 then
            return
        end
        el = 0
        if cfg.farm.awayAuto then
            pcall(Feat.collectAwayEarnings)
        end
    end)
    table.insert(conns, state.awayConn)
end

function Feat.startPlayerEsp()
    startEsp()
end
function Feat.stopPlayerEsp()
    stopEsp()
end

function Feat.setFpsCap(n)
    n = math.floor(tonumber(n) or 0)
    if type(setfpscap) ~= "function" then
        return false, "This executor cannot cap the FPS"
    end
    if n > 0 then
        if state.fpsOrig == nil then
            local E = (getgenv and getgenv()) or _G
            local okG, cur = pcall(function()
                return E.getfpscap and E.getfpscap()
            end)
            state.fpsOrig = okG and tonumber(cur) or 60
        end
        if pcall(setfpscap, math.max(5, n)) then
            return true
        end
        return false, "setfpscap failed"
    end
    if state.fpsOrig ~= nil then
        pcall(setfpscap, state.fpsOrig)
        state.fpsOrig = nil
    end
    return true
end

function Feat.set3d(off)
    if off then
        if pcall(function()
            rs:Set3dRenderingEnabled(false)
        end) then
            state.no3d = true
            return true
        end
        return false, "3D rendering cannot be turned off here"
    end
    if state.no3d then
        pcall(function()
            rs:Set3dRenderingEnabled(true)
        end)
        state.no3d = nil
    end
    return true
end

Feat.hookQueue = {}
function Feat.httpRequest()
    local E = (getgenv and getgenv()) or _G
    local r = E.request
        or E.http_request
        or (type(E.syn) == "table" and E.syn.request)
        or (type(E.http) == "table" and E.http.request)
        or (type(E.fluxus) == "table" and E.fluxus.request)
        or (type(request) == "function" and request)
        or (type(http_request) == "function" and http_request)
        or nil
    return type(r) == "function" and r or nil
end

function Feat.hookValid(url)
    url = tostring(url or "")
    for _, host in ipairs({ "discord%.com", "ptb%.discord%.com", "canary%.discord%.com", "discordapp%.com" }) do
        if url:match("^https://" .. host .. "/api/webhooks/%d+/[%w_%-]+") then
            return true
        end
    end
    return false
end

function Feat.hookPost(content)
    local url = cfg.hook.url
    if not Feat.hookValid(url) then
        return false, "no valid webhook URL is set"
    end
    local req = Feat.httpRequest()
    if not req then
        return false, "this executor has no HTTP request function"
    end
    local body = H.gs("HttpService")
        :JSONEncode({ username = "BPHUB", content = string.sub(tostring(content), 1, 1900) })
    local ok, res =
        pcall(req, { Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body })
    if not ok then
        return false, "the request failed"
    end
    local code = type(res) == "table" and tonumber(res.StatusCode) or nil
    if code and code >= 200 and code < 300 then
        return true, "HTTP " .. code
    end
    if not code then
        return false, "no answer from Discord"
    end
    return false,
        "HTTP "
            .. code
            .. (
                (code == 429 and " (rate limited)")
                or ((code == 401 or code == 404) and " (check the webhook URL)")
                or ""
            )
end

function Feat.hookSend(content)
    if not Feat.hookValid(cfg.hook.url) then
        return
    end
    local q = Feat.hookQueue
    if #q >= 10 then
        table.remove(q, 1)
    end
    q[#q + 1] = content
    if Feat.hookBusy then
        return
    end
    Feat.hookBusy = true
    task.spawn(function()
        while #q > 0 and not state.destroyed do
            local okP, ok, why = pcall(Feat.hookPost, table.remove(q, 1))
            if not okP then
                ok, why = false, firstLine(ok)
            end
            if not ok and why ~= state.hookLastWhy then
                logRun("Webhook: " .. tostring(why))
            end
            state.hookLastWhy = not ok and why or nil
            task.wait(3)
        end
        Feat.hookBusy = false
    end)
end

function Feat.onStolen(label, rate, secs)
    Feat.hookSend(
        string.format(
            "Stolen: %s ($%s/s) in %ds. This session: %d stolen, +$%s/s.",
            tostring(label or "egg"),
            shortNum(rate or 0),
            math.floor(tonumber(secs) or 0),
            state.stats.ok,
            shortNum(state.stats.gained)
        )
    )
end

Feat.rare = { list = {} }
function Feat.cleanText(s)
    return (tostring(s or ""):gsub("<[^>]+>", ""))
end

function Feat.setRare(p, live)
    if type(p) ~= "table" or type(p.RareSpawns) ~= "table" then
        return
    end
    local period = tonumber(p.PeriodIndex)
    if period and Feat.rare.period and period <= Feat.rare.period then
        return
    end
    Feat.rare = { list = p.RareSpawns, period = period, dayStartsAt = tonumber(p.DayStartsAt) }
    if not (live and cfg.hook.rare) then
        return
    end
    local minRank = Feat.RARITY_RANKS[cfg.hook.minRarity] or 0
    local lines = {}
    for _, s in ipairs(p.RareSpawns) do
        if type(s) == "table" and (Feat.RARITY_RANKS[s.RarityId] or 0) >= minRank then
            lines[#lines + 1] = string.format("%s: %s", tostring(s.RarityId), Feat.cleanText(s.Message))
        end
    end
    if #lines > 0 then
        local eta = Feat.rare.dayStartsAt and Feat.rare.dayStartsAt - workspace:GetServerTimeNow()
        Feat.hookSend(
            "Rare egg spawn announced"
                .. ((eta and eta > 0) and (" (spawns in " .. fmtDuration(eta) .. ")") or "")
                .. ":\n"
                .. table.concat(lines, "\n")
        )
    end
end

function Feat.watchRare()
    if Feat.rareWatch or not EggState then
        return
    end
    Feat.rareWatch = true
    pcall(function()
        table.insert(
            conns,
            EggState.RarityRevealed:Connect(function(p)
                pcall(Feat.setRare, p, true)
            end)
        )
    end)
end

function Feat.predictorText()
    local now = workspace:GetServerTimeNow()
    local lines = {}
    if AreaEggCycle then
        local okN, night = pcall(AreaEggCycle.IsNightPhase, now)
        local okS, left = pcall(AreaEggCycle.SecondsUntilReset, now)
        if okN and night == true then
            lines[#lines + 1] = "Night phase: the field eggs are resetting now"
        elseif okS and type(left) == "number" then
            lines[#lines + 1] = "Next egg reset in " .. fmtDuration(left)
        end
    end
    if #lines == 0 then
        lines[1] = "Egg reset timer: not available"
    end
    local r = Feat.rare
    if #r.list > 0 then
        local eta = r.dayStartsAt and r.dayStartsAt - now
        lines[#lines + 1] = "Announced rare spawns"
            .. ((eta and eta > 0) and (" (they spawn in " .. fmtDuration(eta) .. ")") or "")
            .. ":"
        for _, s in ipairs(r.list) do
            if type(s) == "table" then
                local rec = fieldRecord(s.EggUid)
                local where = (isAvailable(rec) and (" | on the field: " .. tostring(rec.AreaId)))
                    or ((rec and rec.State == "Carried") and " | being carried")
                    or ""
                lines[#lines + 1] = string.format("  %s: %s%s", tostring(s.RarityId), Feat.cleanText(s.Message), where)
            end
        end
    else
        lines[#lines + 1] =
            "No rare spawn announced this cycle yet. The game announces them before a reset (also in chat)."
    end
    return table.concat(lines, "\n")
end

function Feat.liveStatusText()
    local now = workspace:GetServerTimeNow()
    local parts = {}
    for name, e in pairs(Feat.liveEnds) do
        if e > now then
            parts[#parts + 1] = string.format("%s (%s left)", (name:gsub("(%l)(%u)", "%1 %2")), fmtDuration(e - now))
        end
    end
    table.sort(parts)
    if #parts > 0 then
        return "Running: " .. table.concat(parts, ", ")
    end
    if Feat.liveKnown then
        return "No live event right now"
    end
    return "Live event status: waiting for the game"
end

function Feat.loadGuards()
    cfg.steal.travel = "Walk"
    cfg.player.noclip, cfg.player.infjump = false, false
    cfg.auto.fuse, cfg.auto.rift = false, false
end

function Feat.reloadScript()
    task.spawn(function()
        local fn, why = Feat.readScript()
        if not fn then
            BPUI:Notify({ Title = "Reload", Content = why, Type = "Error", Duration = 5 })
            return
        end
        local E = (getgenv and getgenv()) or _G
        if type(E.__BPHUB_SAE_UNLOAD) == "function" then
            pcall(E.__BPHUB_SAE_UNLOAD)
        end
        task.wait(0.3)
        pcall(fn)
    end)
end

local genv = (getgenv and getgenv()) or _G
if type(genv.__BPHUB_SAE_UNLOAD) == "function" then
    pcall(genv.__BPHUB_SAE_UNLOAD)
end
local stopAllRef
do
    local tweenService = H.gs("TweenService")
    local motion = { scales = {}, tweens = {}, pages = {}, connections = {}, generation = 0, stopped = false }
    Feat.motion = motion
    local presets = {
        hover = { 0.12, Enum.EasingStyle.Quad },
        press = { 0.08, Enum.EasingStyle.Quad },
        release = { 0.22, Enum.EasingStyle.Back },
        page = { 0.24, Enum.EasingStyle.Quint },
        standard = { 0.22, Enum.EasingStyle.Quint },
        ripple = { 0.40, Enum.EasingStyle.Quint },
    }
    local originalMotion = {}
    if type(BPUI_LIB.Motion) == "table" then
        for name in pairs(presets) do
            originalMotion[name] = BPUI_LIB.Motion[name]
        end
    end
    function Feat.revealSection(section, delayTime)
        if motion.stopped or cfg.ui.animations == false then
            return
        end
        local scale = motion.scales[section]
        local holder = section._holder
        if not scale or not holder or not holder.Parent or not holder.Visible then
            return
        end
        local generation = motion.generation
        local entry = motion.pages[section._motionPage]
        local pageToken = entry and entry.token
        task.delay(delayTime or 0, function()
            if motion.stopped or cfg.ui.animations == false or generation ~= motion.generation then
                return
            end
            if entry and (entry.token ~= pageToken or not section._motionPage.Visible) then
                return
            end
            if not scale.Parent or not holder.Parent or not holder.Visible then
                return
            end
            if motion.tweens[scale] then
                motion.tweens[scale]:Cancel()
            end
            scale.Scale = 0.98
            local tween = tweenService:Create(
                scale,
                TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                { Scale = 1 }
            )
            motion.tweens[scale] = tween
            tween:Play()
        end)
    end
    function Feat.bindSectionMotion(section, tab)
        if type(section) ~= "table" or not section._holder or not tab._page then
            return
        end
        local holder, page = section._holder, tab._page
        local scale = Instance.new("UIScale")
        scale.Name = "BPHUBSectionReveal"
        scale.Scale = 1
        scale.Parent = holder
        motion.scales[section] = scale
        section._motionPage = page
        local entry = motion.pages[page]
        if not entry then
            entry = { sections = {}, token = 0 }
            motion.pages[page] = entry
            motion.connections[#motion.connections + 1] = page:GetPropertyChangedSignal("Visible"):Connect(function()
                entry.token += 1
                for index, current in ipairs(entry.sections) do
                    local currentScale = motion.scales[current]
                    if currentScale and motion.tweens[currentScale] then
                        motion.tweens[currentScale]:Cancel()
                    end
                    if currentScale then
                        currentScale.Scale = 1
                    end
                    if page.Visible then
                        Feat.revealSection(current, math.min(index - 1, 6) * 0.025)
                    end
                end
            end)
        end
        entry.sections[#entry.sections + 1] = section
        if page.Visible then
            Feat.revealSection(section, 0.05)
        end
    end
    function Feat.setUiAnimations(enabled)
        cfg.ui.animations = enabled == true
        motion.generation += 1
        for scale, tween in pairs(motion.tweens) do
            tween:Cancel()
            if scale.Parent then
                scale.Scale = 1
            end
        end
        table.clear(motion.tweens)
        if type(BPUI_LIB.Motion) == "table" then
            for name, preset in pairs(presets) do
                if originalMotion[name] then
                    BPUI_LIB.Motion[name] = cfg.ui.animations
                            and TweenInfo.new(preset[1], preset[2], Enum.EasingDirection.Out)
                        or originalMotion[name]
                end
            end
        end
    end
    function Feat.stopUiAnimations()
        if motion.stopped then
            return
        end
        local preference = cfg.ui.animations
        Feat.setUiAnimations(false)
        cfg.ui.animations = preference
        motion.stopped = true
        for _, connection in ipairs(motion.connections) do
            connection:Disconnect()
        end
        for _, scale in pairs(motion.scales) do
            if scale.Parent then
                scale.Scale = 1
                scale:Destroy()
            end
        end
        table.clear(motion.connections)
        table.clear(motion.scales)
        table.clear(motion.pages)
    end
    Feat.setUiAnimations(cfg.ui.animations ~= false)
end

Feat.sections = {}
function Feat.sec(tab, name)
    if type(cfg.ui) ~= "table" then
        cfg.ui = {}
    end
    if type(cfg.ui.closed) ~= "table" then
        cfg.ui.closed = {}
    end
    local key = tostring(name)
    local s = tab:CreateSection({ Name = name, Collapsible = true, Open = cfg.ui.closed[key] ~= true })
    if type(s) == "table" and s._collapsible then
        local setOpen = s.SetOpen
        s.SetOpen = function(self, v)
            setOpen(self, v)
            cfg.ui.closed[key] = (not v) or nil
            if v and Feat.motion then
                Feat.revealSection(self, 0)
            end
            C.save()
        end
        Feat.sections[#Feat.sections + 1] = s
    end
    if Feat.motion then
        pcall(Feat.bindSectionMotion, s, tab)
    end
    return s
end

win = BPUI_LIB:CreateWindow({
    Title = "BPHUB",
    Subtitle = "Steal An Egg",
    Theme = "Void",
    Accent = Color3.fromRGB(255, 190, 70),
    ConfigFolder = "BPHUB",
    Size = UDim2.new(0, 840, 0, 580),
    Search = true,
    ShowConfig = false,
    AutoLoad = false,
    ConfirmClose = true,
    OnDestroy = function()
        if stopAllRef then
            stopAllRef()
        end
    end,
})
H.win = win

function Feat.twoCol(sa, sb)
    local ha, hb = sa and sa._holder, sb and sb._holder
    local page = ha and ha.Parent
    if not (hb and page and hb.Parent == page) then
        return
    end
    local row = Instance.new("Frame")
    row.Name = "TwoColRow"
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 0)
    row.AutomaticSize = Enum.AutomaticSize.Y
    row.LayoutOrder = ha.LayoutOrder
    local hl = Instance.new("UIListLayout")
    hl.FillDirection = Enum.FillDirection.Horizontal
    hl.SortOrder = Enum.SortOrder.LayoutOrder
    hl.Padding = UDim.new(0, 6)
    hl.VerticalAlignment = Enum.VerticalAlignment.Top
    hl.Parent = row
    for i, h in ipairs({ ha, hb }) do
        h.LayoutOrder = i
        h.Size = UDim2.new(0.5, -3, 0, 0)
        h.AutomaticSize = Enum.AutomaticSize.Y
        h.Parent = row
    end
    row.Parent = page
end

function Feat.amountInput(sec, name, get, set, onChange, desc)
    local el
    el = sec:AddInput({
        Name = name,
        Description = desc,
        Default = Feat.fmtAmount(get()),
        Placeholder = "e.g. 1.5M",
        Callback = function(v)
            local n = Feat.parseAmount(v)
            if not n then
                BPUI:Notify({
                    Title = name,
                    Content = "Not an amount: " .. tostring(v) .. " (examples: 5000, 250K, 1.5M, 2B)",
                    Type = "Warning",
                    Duration = 4,
                })
                local back = Feat.fmtAmount(get())
                Feat.ui(function()
                    el:Set(back, true)
                end)
                return
            end
            set(math.max(0, n))
            C.save()
            if onChange then
                onChange()
            end
        end,
    })
    return el
end

function Feat.rarityDrop(sec, name, get, set, desc)
    local cur = get()
    return sec:AddDropdown({
        Name = name,
        Description = desc,
        Options = Feat.RARITY_OPTS_ALL,
        Default = (cur == nil or cur == "" or cur == "Any") and "Any" or cur,
        Callback = function(v)
            set((v == nil or v == "Any") and "" or v)
            C.save()
        end,
    })
end

function Feat.typeDrop(sec, name, key, get, set, desc)
    local opts, byLabel, byId = {}, {}, {}
    for _, t in ipairs(Feat.eggTypes()) do
        opts[#opts + 1] = t[key]
        byLabel[t[key]] = t.id
        byId[t.id] = t[key]
    end
    local cur = {}
    for _, id in ipairs(asList(get())) do
        if not byId[id] then
            opts[#opts + 1] = id
            byLabel[id] = id
            byId[id] = id
        end
        cur[#cur + 1] = byId[id]
    end
    return sec:AddDropdown({
        Name = name,
        Description = desc,
        Options = opts,
        Default = cur,
        Multi = true,
        Searchable = true,
        Callback = function(v)
            local ids = {}
            for _, l in ipairs(asList(v)) do
                ids[#ids + 1] = byLabel[l] or l
            end
            set(ids)
            C.save()
        end,
    })
end

function Feat.confirm(title, content, yesText, fn, style)
    Feat.ui(function()
        local ok = pcall(function()
            win:Dialog({
                Title = title,
                Content = content,
                Buttons = { { Text = "Cancel" }, { Text = yesText, Style = style or "Danger", Callback = fn } },
            })
        end)
        if not ok then
            task.spawn(fn)
        end
    end)
end

local farmGrp = win:CreateGroup({ Name = "Farm", Icon = "dollar-sign", Open = true })
local stealTab = farmGrp:CreateTab({ Name = "Steal", Icon = "target" })
local filterTab = farmGrp:CreateTab({ Name = "Filter", Icon = "filter" })
local optTab = farmGrp:CreateTab({ Name = "Options", Icon = "sliders" })
local autoTab = farmGrp:CreateTab({ Name = "Auto", Icon = "zap" })
local evTab = farmGrp:CreateTab({ Name = "Events", Icon = "star" })
local farmTab = farmGrp:CreateTab({ Name = "Train", Icon = "trending-up" })
local visGrp = win:CreateGroup({ Name = "Visuals", Icon = "eye", Open = false })
local espTab = visGrp:CreateTab({ Name = "ESP", Icon = "eye" })
local miscGrp = win:CreateGroup({ Name = "Misc", Icon = "user", Open = false })
local playerTab = miscGrp:CreateTab({ Name = "Player", Icon = "user" })
local dbgTab = miscGrp:CreateTab({ Name = "Debug", Icon = "terminal" })
local tpTab = miscGrp:CreateTab({ Name = "Navigate", Icon = "navigation" })
local cfgTab = filterTab

local stealSec = Feat.sec(stealTab, "Steal")
local statusLbl = stealSec:AddLabel("Idle")
state.statusLabel = statusLbl

pcall(function()
    state.toggle = stealSec:AddToggle({
        Name = "Single Steal",
        Default = false,
        Callback = function(v)
            if v then
                if not start() and state.mode ~= "single" and state.toggle then
                    Feat.ui(function()
                        state.toggle:Set(false, true)
                    end)
                end
            elseif state.running and state.mode == "single" then
                finish("Cancelled")
                Feat.cancelCarry()
            end
        end,
    })
    state.bestTog = stealSec:AddToggle({
        Name = "Auto Best",
        Default = false,
        Description = "grabs the best $/s egg you can bring home",
        Callback = function(v)
            if v then
                if not startBest() and state.mode ~= "best" and state.bestTog then
                    Feat.ui(function()
                        state.bestTog:Set(false, true)
                    end)
                end
            elseif state.running and state.mode == "best" then
                finish("Cancelled")
                Feat.cancelCarry()
            end
        end,
    })
    stealSec:AddButton({
        Name = "Walk to Safe Zone",
        Callback = function()
            walkAnywhere(safeZonePoint(), "Safe Zone")
        end,
    })
    stealSec:AddButton({
        Name = "Cancel / Stop",
        Description = "stops stealing, walking and training",
        Callback = function()
            Feat.userCancel("Cancelled")
        end,
    })
end)

local eggSec = Feat.sec(stealTab, "Egg Selection")
pcall(Feat.twoCol, stealSec, eggSec)
local selLbl = eggSec:AddLabel("Selected: none")
state.selLabel = selLbl
local function updateSelLabel()
    if state.selLabel then
        local rec = state.selectedUid and fieldRecord(state.selectedUid)
        local txt = rec and labelFor(rec) or (state.selectedUid and "egg is gone" or "none")
        local sl = state.selLabel
        Feat.ui(function()
            sl:Set("Selected: " .. txt)
        end)
    end
end

local eggMap = {}
local eggDrop
local function updateEggDrop()
    eggMap = {}
    local opts, selKey = {}, nil
    for _, row in ipairs(state.rows) do
        local base = string.format(
            "%s  $%s/s  [%s]",
            row.title or row.cat or "?",
            shortNum(row.rate),
            string.upper(row.class or "?")
        )
        local key, n = base, 1
        while eggMap[key] do
            n += 1
            key = base .. " #" .. n
        end
        eggMap[key] = row.uid
        opts[#opts + 1] = key
        if row.uid == state.selectedUid then
            selKey = key
        end
    end
    if not selKey and not state.running then
        state.selectedUid = state.rows[1] and state.rows[1].uid or nil
        selKey = opts[1]
    end
    if #opts == 0 then
        opts[1] = "none"
    end
    updateSelLabel()
    if eggDrop then
        local sig = table.concat(opts, "\n")
        task.spawn(function()
            local ok, err = pcall(function()
                if sig ~= Feat.eggDropSig then
                    Feat.eggDropSig = sig
                    eggDrop:Refresh(opts)
                end
                eggDrop:Set(selKey or "none", true)
            end)
            if not ok then
                logRun("Dropdown update error: " .. tostring(err))
            end
        end)
    end
end
Feat.updateEggDrop = updateEggDrop

eggDrop = eggSec:AddDropdown({
    Name = "Select Egg",
    Options = { "none" },
    Default = "none",
    Searchable = true,
    Callback = function(v)
        state.selectedUid = eggMap[v]
        updateSelLabel()
    end,
})

eggSec:AddButton({
    Name = "Refresh Eggs",
    Callback = function()
        refreshEggs()
        updateEggDrop()
        BPUI:Notify({ Title = "Eggs", Content = #state.rows .. " listed", Type = "Info", Duration = 2 })
    end,
})
eggSec:AddButton({
    Name = "Force Full Sync (all areas)",
    Callback = function()
        if state.inRun then
            BPUI:Notify({ Title = "Synced", Content = "Wait for the steal to finish", Type = "Warning", Duration = 3 })
            return
        end
        pcall(EggState.SyncFieldEggs)
        local ok, all = pcall(function()
            return EggState.ReadFieldEggs().Records
        end)
        local total = ok and #all or 0
        local available = 0
        if ok then
            for _, rec in ipairs(all) do
                if isAvailable(rec) then
                    available += 1
                end
            end
        end
        refreshEggs()
        updateEggDrop()
        BPUI:Notify({
            Title = "Synced",
            Content = string.format("%d total records, %d available, %d pass filter", total, available, #state.rows),
            Type = "Info",
            Duration = 5,
        })
    end,
})
eggSec:AddButton({
    Name = "Select Best Egg",
    Description = "picks the best one you can actually deliver",
    Callback = function()
        refreshEggs(true)
        local row = Feat.pickBest(false)
        if row then
            state.selectedUid = row.uid
        end
        updateEggDrop()
        if row then
            BPUI:Notify({ Title = "Selected", Content = row.label, Type = "Success", Duration = 3 })
            return
        end
        BPUI:Notify({ Title = "No egg", Content = "No stealable egg found", Type = "Warning", Duration = 3 })
    end,
})
autoConns._eggList = H.task(function()
    if state.inRun or state.destroyed or not win or not win._visible or win._minimized then
        return
    end
    if eggDrop and eggDrop._open then
        return
    end
    refreshEggs(true)
    updateEggDrop()
end, 8, 5)

do
    local function fmtNum(n)
        n = math.floor((tonumber(n) or 0) + 0.5)
        local s = tostring(n)
        local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
        return (out:gsub("^,", ""))
    end
    local function fmtTime(sec)
        sec = math.floor(sec or 0)
        return string.format("%02d:%02d:%02d", sec // 3600, (sec % 3600) // 60, sec % 60)
    end

    local targetSec = Feat.sec(stealTab, "Target")
    local targetPara = targetSec:AddParagraph({ Title = "Target", Content = "No egg selected" })
    local targetHl
    local function clearHighlight()
        local h = targetHl
        targetHl = nil
        if h then
            Feat.ui(function()
                if h.inst then
                    h.inst:Destroy()
                end
            end)
        end
    end
    state.clearHighlight = clearHighlight
    local function syncHighlight(uid)
        if not cfg.steal.highlight or not uid then
            clearHighlight()
            return
        end
        local folder = workspace:FindFirstChild("AreaEggSlotsClient")
        local model = folder and folder:FindFirstChild(uid)
        if not model then
            clearHighlight()
            return
        end
        if targetHl and targetHl.adornee == model then
            return
        end
        clearHighlight()
        local box = { adornee = model }
        targetHl = box
        Feat.ui(function()
            if targetHl ~= box then
                return
            end
            local hl = Instance.new("Highlight")
            hl.FillColor = Color3.fromRGB(84, 224, 255)
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            hl.FillTransparency = 0.55
            hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Adornee = model
            hl.Parent = Feat.guiParent()
            box.inst = hl
        end)
    end
    local function targetText()
        local uid = state.selectedUid
        local rec = uid and fieldRecord(uid)
        syncHighlight(rec and uid)
        if not rec then
            return uid and "Selected egg is gone (taken, delivered or reset)" or "No egg selected"
        end
        local rarName = eggRarity(rec)
        local mutNames = {}
        for i, m in ipairs(type(rec.Mutations) == "table" and rec.Mutations or {}) do
            mutNames[i] = Feat.mutLabel(m)
        end
        local muts = #mutNames > 0 and table.concat(mutNames, ", ") or "None"
        local pos = eggPosition(rec)
        local _, root = charParts()
        local dist = (pos and root) and math.floor((pos - root.Position).Magnitude) or 0
        local class, v = eggVerdict(rec)
        local deliverTxt
        if class == "clean" then
            deliverTxt = "CLEAN - the guard can't catch you"
        elseif class == "relay" then
            deliverTxt = string.format(
                "RELAY - escapes the area (%.1fs margin), needs Relay Mode%s",
                v.margin or 0,
                cfg.steal.relay and "" or " (off)"
            )
        elseif class == "blocked" then
            local need = (cfg.steal.relay and v.needRelaySP and v.needRelaySP < (v.needCleanSP or math.huge))
                    and v.needRelaySP
                or v.needCleanSP
            local rate = trainingRate()
            local eta = (need and rate > 0) and ("  ETA " .. fmtDuration((need - currentSpeedPower()) / rate)) or ""
            deliverTxt = string.format(
                "BLOCKED - needs %s SpeedPower (you: %s)%s",
                shortNum(need or 0),
                shortNum(currentSpeedPower()),
                eta
            )
        elseif class == "noguard" then
            deliverTxt = "NO GUARD - nothing can catch you"
        else
            deliverTxt = "UNKNOWN - the escape check failed, Auto Best skips this egg"
        end
        local live, base = guardLiveSpeed(rec.AreaId)
        return string.format(
            "%s\nRarity: %s  |  Rate: $%s/s\nArea: %s  |  %s  |  %d studs\nMutations: %s\nYou: %d studs/s carrying (x%.2f)  |  Guard: base %d, now %d, %s\n%s",
            Feat.eggTitle(rec),
            rarName,
            fmtNum(displayRate(rec)),
            rec.AreaId,
            rec.State,
            dist,
            muts,
            math.floor(v.carry or 0),
            v.mult or 0.96,
            math.floor(base or v.guardBase or 0),
            math.floor(live or 0),
            tostring(v.guardState or "?"),
            deliverTxt
        )
    end

    local statsSec = Feat.sec(optTab, "Session Stats")
    local statsPara = statsSec:AddParagraph({ Title = "Stats", Content = "No steals yet" })
    local function statsText()
        local s = state.stats
        local total = s.ok + s.fail
        return string.format(
            "Stolen: %d  |  Failed: %d  |  Success: %d%%\nGained: +$%s/s  |  Avg time: %.1fs\nBest: %s\nSession: %s",
            s.ok,
            s.fail,
            total > 0 and math.floor(s.ok / total * 100 + 0.5) or 0,
            fmtNum(s.gained),
            s.ok > 0 and s.totalTime / s.ok or 0,
            s.bestLabel or "-",
            fmtTime(os.clock() - s.startedAt)
        )
    end
    local function refreshPanels()
        local okS, st = pcall(statsText)
        local okT, tt = pcall(targetText)
        Feat.ui(function()
            if okS then
                statsPara:Set(st)
            end
            if okT then
                targetPara:Set(tt)
            end
        end)
    end
    state.onStats = function()
        task.spawn(refreshPanels)
    end
    statsSec:AddButton({
        Name = "Reset Stats",
        Callback = function()
            local s = state.stats
            s.ok, s.fail, s.gained, s.totalTime, s.bestRate, s.bestLabel = 0, 0, 0, 0, 0, nil
            s.startedAt = os.clock()
            state.onStats()
        end,
    })
    autoConns._panels = H.task(refreshPanels, 1, 0.5)

    local optSec = Feat.sec(optTab, "Steal Options")
    pcall(Feat.twoCol, statsSec, optSec)
    optSec:AddInput({
        Name = "Stop After N Steals",
        Default = tostring(cfg.steal.maxSteals or 0),
        Placeholder = "0",
        Numeric = true,
        Callback = function(v)
            cfg.steal.maxSteals = math.max(0, math.floor(tonumber(v) or 0))
            C.save()
        end,
    })
    optSec:AddToggle({
        Name = "Notify on Steal",
        Default = cfg.steal.notify ~= false,
        Callback = function(v)
            cfg.steal.notify = v
            C.save()
        end,
    })
    optSec:AddToggle({
        Name = "Notify on Failure",
        Default = cfg.steal.notifyFail ~= false,
        Description = "pings you when a steal fails",
        Callback = function(v)
            cfg.steal.notifyFail = v
            C.save()
        end,
    })
    optSec:AddDropdown({
        Name = "On Cancel While Carrying",
        Description = "what happens to the egg you're holding",
        Options = { "Drop Egg", "Drop Egg + Walk to Safe Zone", "Keep Carrying" },
        Default = cfg.steal.onCancel or "Drop Egg",
        Callback = function(v)
            cfg.steal.onCancel = v or "Drop Egg"
            C.save()
        end,
    })
    optSec:AddToggle({
        Name = "Highlight Target Egg",
        Default = cfg.steal.highlight ~= false,
        Callback = function(v)
            cfg.steal.highlight = v
            C.save()
            if not v then
                clearHighlight()
            end
        end,
    })
    if cfg.steal.returnSpeed == "Just Above Guard" then
        cfg.steal.returnSpeed = "Match Guard"
    end
    optSec:AddDropdown({
        Name = "Return Speed",
        Options = { "Max", "Match Guard" },
        Default = cfg.steal.returnSpeed or "Max",
        Callback = function(v)
            cfg.steal.returnSpeed = v or "Max"
            C.save()
        end,
    })
    optSec:AddToggle({
        Name = "Relay Mode",
        Default = cfg.steal.relay == true,
        Callback = function(v)
            cfg.steal.relay = v
            C.save()
        end,
    })
    optSec:AddToggle({
        Name = "Train While Waiting",
        Default = cfg.steal.trainIdle ~= false,
        Callback = function(v)
            cfg.steal.trainIdle = v
            C.save()
        end,
    })

    local keySec = Feat.sec(optTab, "Hotkeys")
    local function saveKey(slot)
        return function(k)
            cfg.keys[slot] = typeof(k) == "EnumItem" and k.Name or ""
            C.save()
        end
    end
    if not cfg.keys.safeMoved then
        if cfg.keys.safe == "F8" then
            cfg.keys.safe = "F4"
        end
        cfg.keys.safeMoved = true
        C.save()
    end
    keySec:AddKeybind({
        Name = "Toggle Auto Best",
        Default = cfg.keys.best,
        Mode = "Press",
        OnChanged = saveKey("best"),
        Callback = function()
            if state.running and state.mode == "best" then
                finish("Auto Best stopped")
                Feat.cancelCarry()
            elseif not state.running then
                startBest()
            end
        end,
    })
    keySec:AddKeybind({
        Name = "Cancel / Stop",
        Default = cfg.keys.cancel,
        Mode = "Press",
        OnChanged = saveKey("cancel"),
        Callback = function()
            Feat.userCancel("Cancelled")
        end,
    })
    keySec:AddKeybind({
        Name = "Walk to Safe Zone",
        Default = cfg.keys.safe,
        Mode = "Press",
        OnChanged = saveKey("safe"),
        Callback = function()
            walkAnywhere(safeZonePoint(), "Safe Zone")
        end,
    })
end
do
    local RARITY_OPTS =
        { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Cosmic", "Secret", "Eternal", "Divine" }
    local MUTATION_OPTS = { "Golden", "Silver", "Rainbow", "Boss", "Scrambled", "Monstrous", "Sakura", "GreatBloom" }
    pcall(function()
        local M = require(rep.Shared.Modules.Mutations)
        local ids = type(M.Ids) == "function" and M.Ids() or M.Ids
        if type(ids) == "table" then
            local list = {}
            for k, v in pairs(ids) do
                list[#list + 1] = tostring(type(k) == "number" and v or k)
            end
            if #list > 0 then
                table.sort(list)
                MUTATION_OPTS = list
            end
        end
    end)
    local mutByLabel = {}
    for i, id in ipairs(MUTATION_OPTS) do
        local l = Feat.mutLabel(id)
        mutByLabel[l] = id
        MUTATION_OPTS[i] = l
    end
    table.sort(MUTATION_OPTS)
    Feat.mutOpts, Feat.mutByLabel = MUTATION_OPTS, mutByLabel

    local filterSec = Feat.sec(cfgTab, "Egg Filter")
    local areaDrop, catDrop, rarDrop, mutDrop, sortDrop, minIn, maxIn, distIn, mutModeDrop

    local function applyFilterNow()
        refreshEggs(true)
        updateEggDrop()
    end
    function Feat.applyFilterSoon()
        Feat.filterGen = (Feat.filterGen or 0) + 1
        local gen = Feat.filterGen
        task.delay(0.3, function()
            if gen == Feat.filterGen and not state.destroyed then
                applyFilterNow()
            end
        end)
    end

    sortDrop = filterSec:AddDropdown({
        Name = "Sort By",
        Options = { "Highest Rate", "Lowest Rate", "Rarity", "Nearest" },
        Description = "just sorts the list",
        Default = cfg.filter.sortBy or "Highest Rate",
        Callback = function(v)
            cfg.filter.sortBy = v or "Highest Rate"
            C.save()
            Feat.applyFilterSoon()
        end,
    })

    minIn = Feat.amountInput(filterSec, "Min Rate ($/s)", function()
        return cfg.filter.minRate
    end, function(n)
        cfg.filter.minRate = n
    end, Feat.applyFilterSoon)
    maxIn = Feat.amountInput(filterSec, "Max Rate ($/s)", function()
        return cfg.filter.maxRate
    end, function(n)
        cfg.filter.maxRate = n
    end, Feat.applyFilterSoon)
    distIn = filterSec:AddInput({
        Name = "Max Distance (studs)",
        Default = tostring(cfg.filter.maxDist or 0),
        Placeholder = "0",
        Numeric = true,
        Callback = function(v)
            cfg.filter.maxDist = tonumber(v) or 0
            C.save()
            Feat.applyFilterSoon()
        end,
    })

    areaDrop = filterSec:AddDropdown({
        Name = "Areas",
        Options = {},
        Default = {},
        Multi = true,
        Callback = function(v)
            cfg.filter.areas = asList(v)
            C.save()
            Feat.applyFilterSoon()
        end,
    })
    catDrop = filterSec:AddDropdown({
        Name = "Egg Types",
        Options = {},
        Default = {},
        Multi = true,
        Searchable = true,
        Description = "stuff on the field shows up first",
        Callback = function(v)
            local ids = {}
            for _, l in ipairs(asList(v)) do
                ids[#ids + 1] = (Feat.catByLabel or {})[l] or l
            end
            cfg.filter.cats = ids
            C.save()
            Feat.applyFilterSoon()
        end,
    })
    rarDrop = filterSec:AddDropdown({
        Name = "Rarities",
        Options = RARITY_OPTS,
        Default = asList(cfg.filter.rarities),
        Multi = true,
        Callback = function(v)
            cfg.filter.rarities = asList(v)
            C.save()
            Feat.applyFilterSoon()
        end,
    })
    if cfg.filter.onlyMutated and cfg.filter.noMutation then
        cfg.filter.onlyMutated, cfg.filter.noMutation = false, false
    end
    if cfg.filter.noMutation then
        cfg.filter.muts = {}
    end
    mutModeDrop = filterSec:AddDropdown({
        Name = "Mutation",
        Options = { "Any", "Mutated Only", "Unmutated Only" },
        Default = (cfg.filter.onlyMutated and "Mutated Only") or (cfg.filter.noMutation and "Unmutated Only") or "Any",
        Callback = function(v)
            cfg.filter.onlyMutated = v == "Mutated Only"
            cfg.filter.noMutation = v == "Unmutated Only"
            if cfg.filter.noMutation and #asList(cfg.filter.muts) > 0 then
                cfg.filter.muts = {}
                task.spawn(function()
                    pcall(function()
                        mutDrop:Set({}, true)
                    end)
                end)
            end
            C.save()
            Feat.applyFilterSoon()
        end,
    })
    mutDrop = filterSec:AddDropdown({
        Name = "Mutations",
        Options = MUTATION_OPTS,
        Default = (function()
            local t = {}
            for _, id in ipairs(asList(cfg.filter.muts)) do
                t[#t + 1] = Feat.mutLabel(id)
            end
            return t
        end)(),
        Multi = true,
        Callback = function(v)
            local ids = {}
            for _, l in ipairs(asList(v)) do
                ids[#ids + 1] = mutByLabel[l] or l
            end
            cfg.filter.muts = ids
            if #ids > 0 and cfg.filter.noMutation then
                cfg.filter.noMutation = false
                task.spawn(function()
                    pcall(function()
                        mutModeDrop:Set("Any", true)
                    end)
                end)
            end
            C.save()
            Feat.applyFilterSoon()
        end,
    })

    local filterSec2 = Feat.sec(cfgTab, "Flags")
    pcall(Feat.twoCol, filterSec, filterSec2)
    local fTogs = {}
    local function flag(key, name, desc)
        fTogs[key] = filterSec2:AddToggle({
            Name = name,
            Description = desc,
            Default = cfg.filter[key] == true,
            Callback = function(v)
                cfg.filter[key] = v
                C.save()
                Feat.applyFilterSoon()
            end,
        })
    end
    flag("includeDropped", "Include Dropped Eggs")
    flag(
        "deliverableOnly",
        "Only Deliverable Eggs",
        "Off: the list also shows eggs the guard would catch you with. Auto Best still skips them."
    )
    flag(
        "showAll",
        "Show ALL Eggs",
        "Only changes the list. Auto Best still skips blocked eggs and eggs your filters exclude."
    )
    flag("riftOnly", "Rift Recipe Eggs Only")
    flag("indexMissing", "Index Missing Only")

    local function reloadFilterLists(notify)
        local areas, cats = fieldEggFilterLists()
        for _, a in ipairs(asList(cfg.filter.areas)) do
            if not table.find(areas, a) then
                areas[#areas + 1] = a
            end
        end
        local sel = {}
        for _, id in ipairs(asList(cfg.filter.cats)) do
            local l = Feat.catLabelOf[id]
            if not l then
                l = id
                cats[#cats + 1] = id
                Feat.catByLabel[id] = id
            end
            sel[#sel + 1] = l
        end
        task.spawn(function()
            if areaDrop then
                pcall(function()
                    areaDrop:Refresh(areas)
                    areaDrop:Set(asList(cfg.filter.areas), true)
                end)
            end
            if catDrop then
                pcall(function()
                    catDrop:Refresh(cats)
                    catDrop:Set(sel, true)
                end)
            end
        end)
        if notify then
            BPUI:Notify({
                Title = "Filter",
                Content = #areas .. " areas, " .. #cats .. " egg types loaded",
                Type = "Info",
                Duration = 2,
            })
        end
    end

    filterSec2:AddButton({
        Name = "Apply Filters",
        Description = "reload the list",
        Callback = function()
            applyFilterNow()
            BPUI:Notify({ Title = "Filter", Content = #state.rows .. " eggs match", Type = "Info", Duration = 2 })
        end,
    })
    filterSec2:AddButton({
        Name = "Reload Area / Type Lists",
        Callback = function()
            reloadFilterLists(true)
        end,
    })
    filterSec2:AddButton({
        Name = "Clear All Filters",
        Callback = function()
            local f = cfg.filter
            f.areas, f.cats, f.rarities, f.muts = {}, {}, {}, {}
            f.minRate, f.maxRate, f.maxDist = 0, 0, 0
            f.onlyMutated, f.noMutation, f.sortBy = false, false, "Highest Rate"
            f.includeDropped, f.deliverableOnly, f.showAll, f.riftOnly, f.indexMissing =
                false, true, false, false, false
            C.save()
            task.spawn(function()
                for _, d in ipairs({ areaDrop, catDrop, rarDrop, mutDrop }) do
                    pcall(function()
                        d:Set({}, true)
                    end)
                end
                for _, i in ipairs({ minIn, maxIn, distIn }) do
                    pcall(function()
                        i:Set("0", true)
                    end)
                end
                pcall(function()
                    sortDrop:Set("Highest Rate", true)
                end)
                pcall(function()
                    mutModeDrop:Set("Any", true)
                end)
                for key, t in pairs(fTogs) do
                    pcall(function()
                        t:Set(f[key] == true, true)
                    end)
                end
                applyFilterNow()
            end)
            BPUI:Notify({ Title = "Filter", Content = "All filters cleared", Type = "Info", Duration = 2 })
        end,
    })

    task.spawn(function()
        task.wait(1)
        applyFilterNow()
        reloadFilterLists(false)
    end)
end
do
    local placeSec = Feat.sec(autoTab, "Auto Place")
    placeSec:AddToggle({
        Name = "Auto Place Eggs",
        Default = cfg.auto.place,
        Description = "best eggs go down first",
        Callback = function(v)
            cfg.auto.place = v
            C.save()
            if v then
                autoLoop("place", 4, Feat.autoPlace)
            else
                Feat.stopAuto("place")
            end
        end,
    })
    placeSec:AddDropdown({
        Name = "Place Egg Order",
        Options = { "Highest Value", "Lowest Value", "Rarity" },
        Default = cfg.place.order or "Highest Value",
        Callback = function(v)
            cfg.place.order = v or "Highest Value"
            C.save()
        end,
    })
    Feat.rarityDrop(placeSec, "Place Min Rarity", function()
        return cfg.place.minRarity
    end, function(v)
        cfg.place.minRarity = v
    end)
    Feat.amountInput(placeSec, "Place Min Value ($/s)", function()
        return cfg.place.minValue
    end, function(n)
        cfg.place.minValue = n
    end, nil, "Eggs below this rate stay in your inventory. 0 = no limit.")
    Feat.typeDrop(placeSec, "Place Only These Eggs", "label", function()
        return cfg.place.cats
    end, function(ids)
        cfg.place.cats = ids
    end, "Empty = every type.")
    placeSec:AddToggle({
        Name = "Place Rift Recipe Eggs First",
        Default = cfg.place.rift == true,
        Description = "rift recipe eggs first, ignores filters",
        Callback = function(v)
            cfg.place.rift = v
            C.save()
        end,
    })

    local hatchSec = Feat.sec(autoTab, "Auto Hatch")
    pcall(Feat.twoCol, placeSec, hatchSec)
    hatchSec:AddToggle({
        Name = "Auto Hatch Eggs",
        Default = cfg.auto.hatch,
        Description = "skips eggs it can't read",
        Callback = function(v)
            cfg.auto.hatch = v
            C.save()
            if v then
                autoLoop("hatch", 4, Feat.autoHatch)
            else
                Feat.stopAuto("hatch")
            end
        end,
    })
    Feat.rarityDrop(hatchSec, "Hatch Min Rarity", function()
        return cfg.hatch.minRarity
    end, function(v)
        cfg.hatch.minRarity = v
    end)
    Feat.amountInput(hatchSec, "Hatch Min Value ($/s)", function()
        return cfg.hatch.minValue
    end, function(n)
        cfg.hatch.minValue = n
    end)
    Feat.typeDrop(hatchSec, "Hatch Specific Eggs", "label", function()
        return cfg.hatch.specific
    end, function(ids)
        cfg.hatch.specific = ids
    end, "Only these types hatch. Empty = every type.")
    hatchSec:AddDropdown({
        Name = "Hatch Mutation",
        Options = { "Any", "Mutated Only", "Unmutated Only" },
        Default = cfg.hatch.mutMode or "Any",
        Callback = function(v)
            cfg.hatch.mutMode = v or "Any"
            C.save()
        end,
    })
    hatchSec:AddInput({
        Name = "Hatch Names Matching",
        Default = tostring(cfg.hatch.match or ""),
        Placeholder = "e.g. dragon, gecko",
        Description = "split with commas, leave empty for all",
        Callback = function(v)
            cfg.hatch.match = tostring(v or "")
            C.save()
        end,
    })
    hatchSec:AddToggle({
        Name = "Hatch Rift Recipe Eggs",
        Default = cfg.hatch.rift == true,
        Description = "rift recipe eggs hatch first",
        Callback = function(v)
            cfg.hatch.rift = v
            C.save()
        end,
    })

    local sellSec = Feat.sec(autoTab, "Auto Sell")
    if (tonumber(cfg.sell.limit) or 0) > 0 then
        if (tonumber(cfg.sell.eggLimit) or 0) <= 0 then
            cfg.sell.eggLimit = cfg.sell.limit
        end
        if (tonumber(cfg.sell.petLimit) or 0) <= 0 then
            cfg.sell.petLimit = cfg.sell.limit
        end
        cfg.sell.limit = 0
        C.save()
    end
    local ruleDesc =
        "Value: sells at or below the $/s limit. Rarity: sells everything below 'Never Sell Rarity', whatever its value."
    sellSec:AddDropdown({
        Name = "Sell Egg Rule",
        Options = { "Value", "Rarity" },
        Default = cfg.sell.eggRule or "Value",
        Description = ruleDesc,
        Callback = function(v)
            cfg.sell.eggRule = v or "Value"
            C.save()
        end,
    })
    Feat.amountInput(sellSec, "Sell Eggs Below ($/s)", function()
        return cfg.sell.eggLimit
    end, function(n)
        cfg.sell.eggLimit = n
    end, nil, "Auto Sell Eggs sells unplaced eggs at or below this rate. 0 = sell nothing.")
    sellSec:AddDropdown({
        Name = "Sell Pet Rule",
        Options = { "Value", "Rarity" },
        Default = cfg.sell.petRule or "Value",
        Description = ruleDesc,
        Callback = function(v)
            cfg.sell.petRule = v or "Value"
            C.save()
        end,
    })
    Feat.amountInput(sellSec, "Sell Pets Below ($/s)", function()
        return cfg.sell.petLimit
    end, function(n)
        cfg.sell.petLimit = n
    end, nil, "Auto Sell Pets sells pets at or below this rate. 0 = sell nothing.")
    Feat.rarityDrop(sellSec, "Never Sell Rarity (and above)", function()
        return cfg.sell.keepRarity
    end, function(v)
        cfg.sell.keepRarity = v
    end)
    sellSec:AddToggle({
        Name = "Keep Mutated (Pets & Eggs)",
        Default = cfg.sell.keepMutated ~= false,
        Callback = function(v)
            cfg.sell.keepMutated = v
            C.save()
        end,
    })
    sellSec:AddToggle({
        Name = "Keep Rift Recipe Pets & Eggs",
        Default = cfg.sell.keepRift ~= false,
        Callback = function(v)
            cfg.sell.keepRift = v
            C.save()
        end,
    })
    sellSec:AddToggle({
        Name = "Keep Index-Missing Pets & Eggs",
        Default = cfg.sell.keepIndex ~= false,
        Description = "won't sell stuff you haven't indexed yet",
        Callback = function(v)
            cfg.sell.keepIndex = v
            C.save()
        end,
    })
    Feat.typeDrop(sellSec, "Blacklist Sell Eggs", "label", function()
        return cfg.sell.neverCats
    end, function(ids)
        cfg.sell.neverCats = ids
    end, "These types are never sold, as eggs or as pets.")
    sellSec:AddInput({
        Name = "Never Sell Names Matching",
        Default = tostring(cfg.sell.keepMatch or ""),
        Placeholder = "e.g. dragon, gecko",
        Description = "names it'll never sell, split with commas",
        Callback = function(v)
            cfg.sell.keepMatch = tostring(v or "")
            C.save()
        end,
    })
    sellSec:AddToggle({
        Name = "Auto Sell Eggs",
        Default = cfg.auto.sellEggs,
        Callback = function(v)
            cfg.auto.sellEggs = v
            C.save()
            if v then
                autoLoop("sellEggs", 6, function()
                    Feat.sellTick("sellEggs")
                end)
            else
                Feat.stopAuto("sellEggs")
            end
        end,
    })
    sellSec:AddToggle({
        Name = "Auto Sell Pets",
        Default = cfg.auto.sellPets,
        Callback = function(v)
            cfg.auto.sellPets = v
            C.save()
            if v then
                autoLoop("sellPets", 6, function()
                    Feat.sellTick("sellPets")
                end)
            else
                Feat.stopAuto("sellPets")
            end
        end,
    })
    do
        local rars = Feat.rarityList()
        local opts, idOf, nameOf = {}, {}, {}
        for _, r in ipairs(rars) do
            opts[#opts + 1] = r.name
            idOf[r.name] = r.id
            nameOf[r.id] = r.name
        end
        local function current()
            local getSave = Save and (Save.Peek or Save.Get)
            local s = getSave and getSave()
            local t = {}
            for id, on in pairs(type(s) == "table" and type(s.AutoSellRarities) == "table" and s.AutoSellRarities or {}) do
                if on and nameOf[id] then
                    t[#t + 1] = nameOf[id]
                end
            end
            return t
        end
        local drop
        drop = sellSec:AddDropdown({
            Name = "Game Auto-Sell Rarities",
            Options = opts,
            Default = current(),
            Multi = true,
            Description = "uses the game's built in auto sell",
            Callback = function(v)
                local ids = {}
                for _, l in ipairs(asList(v)) do
                    ids[#ids + 1] = idOf[l] or l
                end
                task.spawn(function()
                    local ok, res = Feat.setGameAutoSell(ids)
                    if ok then
                        BPUI:Notify({
                            Title = "Game Auto-Sell",
                            Content = #ids > 0 and ("Saved: " .. table.concat(asList(v), ", ")) or "Turned off",
                            Type = "Success",
                            Duration = 3,
                        })
                    else
                        BPUI:Notify({
                            Title = "Game Auto-Sell",
                            Content = "Not saved: " .. tostring(res),
                            Type = "Warning",
                            Duration = 4,
                        })
                        task.wait(0.5)
                        local cur = current()
                        Feat.ui(function()
                            drop:Set(cur, true)
                        end)
                    end
                end)
            end,
        })
        task.delay(3, function()
            if not state.destroyed then
                local cur = current()
                Feat.ui(function()
                    drop:Set(cur, true)
                end)
            end
        end)
    end

    local favSec = Feat.sec(autoTab, "Pets")
    favSec:AddToggle({
        Name = "Auto Equip Best",
        Default = cfg.auto.equip,
        Callback = function(v)
            cfg.auto.equip = v
            C.save()
            if v then
                autoLoop("equip", 15, Feat.autoEquip)
            else
                Feat.stopAuto("equip")
            end
        end,
    })
    favSec:AddToggle({
        Name = "Auto Favorite Pets",
        Default = cfg.auto.favorite == true,
        Description = "set a rule below first",
        Callback = function(v)
            cfg.auto.favorite = v
            C.save()
            state.favWarned = nil
            if v then
                autoLoop("favorite", 10, Feat.autoFavorite)
            else
                Feat.stopAuto("favorite")
            end
        end,
    })
    favSec:AddDropdown({
        Name = "Favorite Rule",
        Options = { "Rarity And Value", "Rarity Or Value" },
        Default = cfg.fav.rule or "Rarity And Value",
        Description = "how the rarity + value rules mix",
        Callback = function(v)
            cfg.fav.rule = v or "Rarity And Value"
            C.save()
        end,
    })
    Feat.rarityDrop(favSec, "Min Rarity to Favorite", function()
        return cfg.fav.minRarity
    end, function(v)
        cfg.fav.minRarity = v
    end)
    Feat.amountInput(favSec, "Min Value to Favorite ($/s)", function()
        return cfg.fav.minValue
    end, function(n)
        cfg.fav.minValue = n
    end)
    favSec:AddDropdown({
        Name = "Favorite Mutations",
        Options = Feat.mutOpts or {},
        Multi = true,
        Default = (function()
            local t = {}
            for _, id in ipairs(asList(cfg.fav.muts)) do
                t[#t + 1] = Feat.mutLabel(id)
            end
            return t
        end)(),
        Callback = function(v)
            local ids = {}
            for _, l in ipairs(asList(v)) do
                ids[#ids + 1] = (Feat.mutByLabel or {})[l] or l
            end
            cfg.fav.muts = ids
            C.save()
        end,
    })
    Feat.typeDrop(favSec, "Always Favorite Species", "petLabel", function()
        return cfg.fav.species
    end, function(ids)
        cfg.fav.species = ids
    end)
    favSec:AddInput({
        Name = "Always Favorite Names Matching",
        Default = tostring(cfg.fav.match or ""),
        Placeholder = "e.g. dragon, gecko",
        Description = "split with commas",
        Callback = function(v)
            cfg.fav.match = tostring(v or "")
            C.save()
        end,
    })
    do
        local favEqTog, unfavEqTog
        favEqTog = favSec:AddToggle({
            Name = "Auto Favorite Equipped",
            Default = cfg.fav.equipped == true,
            Description = "favs your equipped pets too",
            Callback = function(v)
                cfg.fav.equipped = v
                C.save()
                if v and cfg.fav.unfavEquipped then
                    cfg.fav.unfavEquipped = false
                    C.save()
                    task.spawn(function()
                        pcall(function()
                            unfavEqTog:Set(false, true)
                        end)
                    end)
                end
            end,
        })
        unfavEqTog = favSec:AddToggle({
            Name = "Auto UnFavorite Equipped",
            Default = cfg.fav.unfavEquipped == true and cfg.fav.equipped ~= true,
            Description = "unfavs equipped pets that don't match",
            Callback = function(v)
                cfg.fav.unfavEquipped = v
                C.save()
                if v and cfg.fav.equipped then
                    cfg.fav.equipped = false
                    C.save()
                    task.spawn(function()
                        pcall(function()
                            favEqTog:Set(false, true)
                        end)
                    end)
                end
            end,
        })
    end
    favSec:AddButton({
        Name = "Favorite Now",
        Description = "favs pets that match your rules",
        Callback = function()
            task.spawn(function()
                local n, why = Feat.autoFavorite(true)
                local txt = (type(why) == "string" and why)
                    or (type(why) == "number" and string.format("%d of %d pets favorited", n, why))
                    or "No pet matches the filters"
                BPUI:Notify({ Title = "Favorite", Content = txt, Type = n > 0 and "Success" or "Info", Duration = 3 })
            end)
        end,
    })

    local indexSec = Feat.sec(autoTab, "Rewards")
    indexSec:AddToggle({
        Name = "Auto Claim Index",
        Default = cfg.auto.claimIndex == true,
        Description = "checks every 60s",
        Callback = function(v)
            cfg.auto.claimIndex = v
            C.save()
            if v then
                autoLoop("claimIndex", 60, Feat.claimIndex)
            else
                Feat.stopAuto("claimIndex")
            end
        end,
    })
    indexSec:AddButton({
        Name = "Claim Index Rewards",
        Callback = function()
            task.spawn(Feat.claimIndex, true)
        end,
    })
    indexSec:AddButton({
        Name = "Claim Group Reward",
        Description = "one time reward, you need to be in the group",
        Callback = function()
            task.spawn(function()
                local okT, ok, msg = pcall(Feat.claimGroupReward)
                if not okT then
                    ok, msg = false, firstLine(ok)
                end
                BPUI:Notify({
                    Title = "Group Reward",
                    Content = tostring(msg),
                    Type = ok and "Success" or "Warning",
                    Duration = 4,
                })
            end)
        end,
    })

    local upgSec = Feat.sec(autoTab, "Auto Upgrade")
    pcall(Feat.twoCol, indexSec, upgSec)
    upgSec:AddToggle({
        Name = "Auto Upgrade Base",
        Default = cfg.auto.upgradeBase == true,
        Callback = function(v)
            cfg.auto.upgradeBase = v
            C.save()
            if v then
                autoLoop("upgradeBase", 30, Feat.autoUpgradeBase)
            else
                Feat.stopAuto("upgradeBase")
            end
        end,
    })
    upgSec:AddToggle({
        Name = "Auto Upgrade Treadmill",
        Default = cfg.auto.upgradeTreadmill == true,
        Callback = function(v)
            cfg.auto.upgradeTreadmill = v
            C.save()
            if v then
                autoLoop("upgradeTreadmill", 30, Feat.autoUpgradeTreadmill)
            else
                Feat.stopAuto("upgradeTreadmill")
            end
        end,
    })
    upgSec:AddButton({
        Name = "Upgrade Base Now",
        Callback = function()
            task.spawn(function()
                local ok, msg = Feat.autoUpgradeBase()
                BPUI:Notify({
                    Title = "Base",
                    Content = tostring(msg),
                    Type = ok and "Success" or "Warning",
                    Duration = 3,
                })
            end)
        end,
    })
    upgSec:AddButton({
        Name = "Upgrade Treadmill Now",
        Callback = function()
            task.spawn(function()
                local ok, msg = Feat.autoUpgradeTreadmill()
                BPUI:Notify({
                    Title = "Treadmill",
                    Content = tostring(msg),
                    Type = ok and "Success" or "Warning",
                    Duration = 3,
                })
            end)
        end,
    })

    local fuseSec = Feat.sec(autoTab, "Auto Fuse Machine")
    if cfg.auto.fuse then
        cfg.auto.fuse = false
        C.save()
    end
    fuseSec:AddToggle({
        Name = "Auto Fuse Pets",
        Default = false,
        Description = "fuses 3 spares of the same pet, turns off on rejoin",
        Callback = function(v)
            cfg.auto.fuse = v
            C.save()
            if v then
                autoLoop("fuse", 20, Feat.autoFuse)
            else
                Feat.stopAuto("fuse")
            end
        end,
    })
    fuseSec:AddSlider({
        Name = "Keep Best N Pets (per type)",
        Min = 1,
        Max = 10,
        Default = tonumber(cfg.fuse and cfg.fuse.keepBest) or 1,
        Increment = 1,
        Callback = function(v)
            cfg.fuse = cfg.fuse or {}
            cfg.fuse.keepBest = v
            C.save()
        end,
    })
    fuseSec:AddToggle({
        Name = "Include Equipped Pets",
        Default = cfg.fuse.includeEquipped == true,
        Description = "leave off to keep equipped pets safe",
        Callback = function(v)
            cfg.fuse.includeEquipped = v
            C.save()
        end,
    })
    fuseSec:AddToggle({
        Name = "Skip Mutated Pets",
        Default = cfg.fuse.skipMutated ~= false,
        Description = "mutated pets stay out",
        Callback = function(v)
            cfg.fuse.skipMutated = v
            C.save()
        end,
    })
    Feat.rarityDrop(fuseSec, "Max Rarity To Fuse", function()
        return cfg.fuse.maxRarity
    end, function(v)
        cfg.fuse.maxRarity = v
    end, "Pets above this rarity are never fused. Any = no limit.")
    fuseSec:AddDropdown({
        Name = "Fuse Priority",
        Options = { "Lowest Value First", "Most Duplicates First" },
        Default = cfg.fuse.priority or "Lowest Value First",
        Description = "what gets fused first",
        Callback = function(v)
            cfg.fuse.priority = v or "Lowest Value First"
            C.save()
        end,
    })
    fuseSec:AddToggle({
        Name = "Eject Incomplete Slots",
        Default = cfg.fuse.ejectPartial ~= false,
        Description = "takes back leftovers before fusing",
        Callback = function(v)
            cfg.fuse.ejectPartial = v
            C.save()
        end,
    })
    fuseSec:AddButton({
        Name = "Fuse Now",
        Description = "walk over if it says you're too far",
        Callback = function()
            task.spawn(function()
                local n, why = Feat.autoFuse(true)
                local txt = n > 0
                        and (string.format("Fused %d time(s)", n) .. (why and (", then stopped: " .. why) or ""))
                    or ("Nothing fused: " .. tostring(why or "no reason"))
                BPUI:Notify({ Title = "Fuse", Content = txt, Type = n > 0 and "Success" or "Warning", Duration = 5 })
            end)
        end,
    })

    do
        local riftSec = Feat.sec(autoTab, "Rift")
        local riftLbl = riftSec:AddLabel("Recipe: loading...")
        if cfg.auto.rift then
            cfg.auto.rift = false
            C.save()
        end
        riftSec:AddToggle({
            Name = "Auto Rift Sacrifice",
            Default = false,
            Description = "trades recipe pets for a rift egg, turns off on rejoin",
            Callback = function(v)
                cfg.auto.rift = v
                C.save()
                if v then
                    autoLoop("rift", 30, function()
                        Feat.riftRun(false, "trade")
                    end)
                else
                    Feat.stopAuto("rift")
                end
            end,
        })
        riftSec:AddToggle({
            Name = "Auto Reroll Rift Recipe (free only)",
            Default = cfg.auto.riftReroll == true,
            Description = "free daily reroll only, never spends robux",
            Callback = function(v)
                cfg.auto.riftReroll = v
                C.save()
                if v then
                    autoLoop("riftReroll", 60, function()
                        Feat.riftRun(false, "reroll")
                    end)
                else
                    Feat.stopAuto("riftReroll")
                end
            end,
        })
        riftSec:AddToggle({
            Name = "Skip Mutated Pets",
            Default = cfg.rift.skipMutated ~= false,
            Description = "mutated pets stay out",
            Callback = function(v)
                cfg.rift.skipMutated = v
                C.save()
            end,
        })
        riftSec:AddButton({
            Name = "Sacrifice Now",
            Description = "confirms first",
            Callback = function()
                local function go(expect)
                    task.spawn(function()
                        local ok, why = Feat.riftRun(true, "trade", expect)
                        BPUI:Notify({
                            Title = "Rift",
                            Content = tostring(why or (ok and "Done" or "Nothing to do")),
                            Type = ok and "Success" or "Warning",
                            Duration = 5,
                        })
                    end)
                end
                local getSave = Save and (Save.Peek or Save.Get)
                local s = getSave and getSave()
                local reqs = type(s) == "table" and type(s.Rift) == "table" and s.Rift.Requirements
                local okP, picked, missing
                if type(reqs) == "table" and #reqs >= 3 then
                    okP, picked, missing = pcall(Feat.riftPick, reqs, s)
                end
                if not okP or #missing > 0 or not (picked[1] and picked[2] and picked[3]) then
                    go({})
                    return
                end
                local parts = {}
                for i = 1, 3 do
                    local okR, rate = pcall(AssetEarnings.RatePerSecond, s.Inventory and s.Inventory[picked[i]])
                    rate = okR and tonumber(rate)
                    parts[i] = Feat.petLabelOf(reqs[i]) .. (rate and (" ($" .. shortNum(rate) .. "/s)") or "")
                end
                Feat.confirm(
                    "Rift sacrifice",
                    "Trade " .. table.concat(parts, ", ") .. " for a Rift egg? This cannot be undone.",
                    "Sacrifice",
                    function()
                        go(picked)
                    end
                )
            end,
        })
        autoConns._riftLbl = H.task(function()
            local getSave = Save and (Save.Peek or Save.Get)
            local s = getSave and getSave()
            local reqs = type(s) == "table" and type(s.Rift) == "table" and s.Rift.Requirements
            local txt = "Recipe: unknown (save not ready)"
            if type(reqs) == "table" and #reqs > 0 then
                local picked = Feat.riftPick(reqs, s)
                local have, names = 0, {}
                for i, c in ipairs(reqs) do
                    names[#names + 1] = Feat.petLabelOf(c)
                    if picked[i] then
                        have += 1
                    end
                end
                txt = string.format("Recipe: %s  (spare pets: %d/%d)", table.concat(names, ", "), have, #reqs)
            elseif type(reqs) == "table" then
                txt = "Recipe: none right now"
            end
            Feat.ui(function()
                riftLbl:Set(txt)
            end)
        end, 5, 1)
    end
end
local espSec = Feat.sec(espTab, "ESP")
espSec:AddToggle({
    Name = "Egg ESP",
    Default = cfg.esp.eggs,
    Description = "green safe, yellow relay, red you get caught",
    Callback = function(v)
        cfg.esp.eggs = v
        C.save()
        if v then
            startEsp()
            return
        end
        if not cfg.esp.guards and not cfg.esp.traps then
            stopEsp()
            return
        end
        pcall(updateEsp)
    end,
})
espSec:AddToggle({
    Name = "ESP uses Egg Filter",
    Default = cfg.esp.useFilter ~= false,
    Description = "only shows what passes your filter",
    Callback = function(v)
        cfg.esp.useFilter = v
        C.save()
        if cfg.esp.eggs then
            pcall(updateEsp)
        end
    end,
})
espSec:AddToggle({
    Name = "Guard ESP",
    Default = cfg.esp.guards,
    Description = "green sleeping, red chasing",
    Callback = function(v)
        cfg.esp.guards = v
        C.save()
        if v then
            startEsp()
            return
        end
        if not cfg.esp.eggs and not cfg.esp.traps then
            stopEsp()
            return
        end
        pcall(updateEsp)
    end,
})
espSec:AddToggle({
    Name = "Trap ESP",
    Default = cfg.esp.traps == true,
    Description = "traps + who placed them",
    Callback = function(v)
        cfg.esp.traps = v
        C.save()
        if v then
            startEsp()
            return
        end
        if not cfg.esp.eggs and not cfg.esp.guards then
            stopEsp()
            return
        end
        pcall(updateEsp)
    end,
})
espSec:AddToggle({
    Name = "Player ESP",
    Default = cfg.esp.players,
    Description = "shows who's carrying or stuck in a trap",
    Callback = function(v)
        cfg.esp.players = v
        C.save()
        if v then
            Feat.startPlayerEsp()
        else
            Feat.stopPlayerEsp()
        end
    end,
})
espSec:AddSlider({
    Name = "ESP Range",
    Min = 100,
    Max = 30000,
    Default = cfg.esp.range,
    Increment = 50,
    Callback = function(v)
        cfg.esp.range = v
        C.save()
    end,
})

espSec:AddButton({
    Name = "Refresh ESP",
    Description = "rescan and rebuild labels",
    Callback = function()
        Esp.normalizeOptions()
        stopEsp(true)
        Esp.lastError, Esp.reportedError, Esp.errorAt = nil, nil, nil
        Esp.styleRevision += 1
        if espAny() then
            startEsp()
        end
    end,
})
espSec:AddButton({
    Name = "ESP Diagnostics",
    Callback = function()
        local created, enabled, anchored, inPlayerGui = 0, 0, 0, 0
        local playerGui = lp:FindFirstChildOfClass("PlayerGui")
        for _, node in pairs(Esp.nodes) do
            created += 1
            if node.gui.Enabled then
                enabled += 1
            end
            if node.gui.Adornee and node.gui.Adornee:IsDescendantOf(workspace) then
                anchored += 1
            end
            if playerGui and node.gui:IsDescendantOf(playerGui) then
                inPlayerGui += 1
            end
        end
        local text = "Enabled: "
            .. tostring(espAny())
            .. " | Heartbeat: "
            .. tostring(Esp.conn and Esp.conn.Connected == true)
            .. " | Matching labels: "
            .. tostring(#Esp.list)
            .. " | Egg filter: "
            .. tostring(cfg.esp.useFilter ~= false)
        text ..= string.format(
            "\nCreated: %d | Enabled: %d | Targets: %d | In PlayerGui: %d",
            created,
            enabled,
            anchored,
            inPlayerGui
        )
        if Esp.lastError then
            text ..= "\n" .. Esp.lastError
        end
        if #Esp.list == 0 and cfg.esp.eggs and cfg.esp.useFilter ~= false then
            text ..= "\nTry disabling 'ESP uses Egg Filter' to show all available eggs."
        end
        warn("[BPHUB ESP] " .. text)
        logRun("ESP diagnostics: " .. text)
        BPUI:Notify({ Title = "ESP Diagnostics", Content = text, Type = "Info", Duration = 10 })
    end,
})

do
    espSec:AddSlider({
        Name = "ESP Size",
        Min = 8,
        Max = 28,
        Increment = 1,
        Default = cfg.esp.appearance.textSize,
        Callback = function(value)
            cfg.esp.appearance.textSize = math.clamp(tonumber(value) or 11, 8, 28)
            Esp.changed()
        end,
    })
    espSec:AddSlider({
        Name = "ESP Opacity",
        Min = 0,
        Max = 100,
        Increment = 5,
        Default = Esp.number("opacity", 100, 0, 100),
        Description = "0 = hidden, 100 = fully visible",
        Callback = function(value)
            cfg.esp.appearance.opacity = math.clamp(tonumber(value) or 100, 0, 100)
            Esp.changed()
        end,
    })
    local colorInput
    colorInput = espSec:AddInput({
        Name = "ESP Color",
        Default = "#" .. (cfg.esp.appearance.colors.text or cfg.esp.appearance.colors.egg),
        Placeholder = "#RRGGBB",
        Description = "one color for all labels; blank restores status colors",
        Callback = function(value)
            if type(value) == "string" and value:match("^%s*$") then
                cfg.esp.appearance.colors.text = nil
                Esp.changed()
                return
            end
            local hex = Esp.hex(value)
            if not hex then
                BPUI:Notify({
                    Title = "ESP Color",
                    Content = "Use a color such as #54E0FF.",
                    Type = "Warning",
                    Duration = 3,
                })
                if colorInput then
                    Feat.ui(function()
                        colorInput:Set(
                            cfg.esp.appearance.colors.text and ("#" .. cfg.esp.appearance.colors.text) or "",
                            true
                        )
                    end)
                end
                return
            end
            cfg.esp.appearance.colors.text = hex:upper()
            Esp.changed()
        end,
    })
end

do
    local logSec = Feat.sec(dbgTab, "Run Log")
    local logPara = logSec:AddParagraph({ Title = "Log", Content = "Nothing yet" })
    state.onLog = function()
        task.spawn(function()
            local lines = {}
            for i = 1, math.min(14, #state.log) do
                lines[i] = state.log[i]
            end
            local body = #lines > 0 and table.concat(lines, "\n") or "Nothing yet"
            Feat.ui(function()
                logPara:Set(body)
            end)
        end)
    end
    state.onLog()
    logSec:AddButton({
        Name = "Clear Log",
        Callback = function()
            table.clear(state.log)
            state.onLog()
        end,
    })
    logSec:AddButton({
        Name = "Unload Hub",
        Description = "stops everything and closes",
        Callback = function()
            if type(genv.__BPHUB_SAE_UNLOAD) == "function" then
                genv.__BPHUB_SAE_UNLOAD()
            end
        end,
    })

    local dbgSec = Feat.sec(dbgTab, "Remotes")
    pcall(Feat.twoCol, logSec, dbgSec)
    local function writeDump(path, lines, what)
        local ok, err = false, "this executor cannot write files"
        if writefile then
            ok, err = pcall(function()
                if isfolder and makefolder and not isfolder("BPHUB") then
                    makefolder("BPHUB")
                end
                writefile(path, table.concat(lines, "\n"))
            end)
        end
        BPUI:Notify({
            Title = "Dump",
            Content = ok and string.format("Saved %d %s to %s", #lines, what, path)
                or ("Dump failed: " .. firstLine(err)),
            Type = ok and "Success" or "Error",
            Duration = 4,
        })
    end
    dbgSec:AddButton({
        Name = "Dump Remotes",
        Callback = function()
            local out = {}
            for _, v in rep:GetDescendants() do
                if v:IsA("BaseRemoteEvent") or v:IsA("RemoteFunction") then
                    out[#out + 1] = v.ClassName .. "  " .. v:GetFullName()
                end
            end
            writeDump("BPHUB/remotes_" .. game.PlaceId .. ".txt", out, "remotes")
        end,
    })
    dbgSec:AddButton({
        Name = "Dump Eggs",
        Callback = function()
            local ok, out = pcall(function()
                EggState.SyncFieldEggs()
                local lines = {}
                for _, rec in ipairs(EggState.ReadFieldEggs().Records) do
                    local pos = eggPosition(rec)
                    lines[#lines + 1] = string.format(
                        "%s | %s | %s | pos=%s",
                        rec.Uid:sub(1, 12),
                        rec.AreaId,
                        rec.State,
                        pos and tostring(pos) or "nil"
                    )
                end
                return lines
            end)
            if not ok then
                BPUI:Notify({
                    Title = "Dump",
                    Content = "Dump failed: " .. firstLine(out),
                    Type = "Error",
                    Duration = 4,
                })
                return
            end
            writeDump("BPHUB/eggs_" .. game.PlaceId .. ".txt", out, "egg records")
        end,
    })
    dbgSec:AddButton({
        Name = "Refresh + Print Best",
        Callback = function()
            local rows = refreshEggs(true)
            for i = 1, math.min(5, #rows) do
                logRun(
                    string.format(
                        "#%d [%s] %s | %s",
                        i,
                        string.upper(rows[i].class or "?"),
                        rows[i].area,
                        rows[i].label
                    )
                )
            end
            BPUI:Notify({ Title = "Eggs", Content = #rows .. " available", Type = "Info", Duration = 3 })
        end,
    })
end
do
    local pMoveSec = Feat.sec(playerTab, "Movement")
    if cfg.player.noclip or cfg.player.infjump then
        cfg.player.noclip, cfg.player.infjump = false, false
        C.save()
    end
    pMoveSec:AddToggle({
        Name = "Noclip",
        Default = false,
        Description = "turns off on rejoin",
        Callback = function(v)
            cfg.player.noclip = v
            C.save()
            Feat.setNoclip(v)
        end,
    })
    pMoveSec:AddToggle({
        Name = "Infinite Jump",
        Default = false,
        Description = "turns off on rejoin",
        Callback = function(v)
            cfg.player.infjump = v
            C.save()
            Feat.setInfJump(v)
        end,
    })
    local afkOff = {}
    local function afkGc()
        local E = (getgenv and getgenv()) or _G
        local f = E.getconnections or E.get_signal_cons
        return type(f) == "function" and f or nil
    end
    local function setAntiAfk(on)
        for _, c in ipairs(afkOff) do
            pcall(function()
                c:Enable()
            end)
        end
        table.clear(afkOff)
        if not on then
            return
        end
        local gc = afkGc()
        if not gc then
            return
        end
        pcall(function()
            for _, c in ipairs(gc(lp.Idled)) do
                if pcall(function()
                    c:Disable()
                end) then
                    afkOff[#afkOff + 1] = c
                end
            end
        end)
    end
    state.setAntiAfk = setAntiAfk
    pMoveSec:AddToggle({
        Name = "Anti-AFK",
        Default = cfg.misc.antiAfk ~= false,
        Description = "no more 20 min idle kick",
        Callback = function(v)
            cfg.misc.antiAfk = v
            C.save()
            setAntiAfk(v)
        end,
    })
end
do
    local exploitSec = Feat.sec(playerTab, "Exploit")
    pcall(Feat.twoCol, pMoveSec, exploitSec)
    exploitSec:AddToggle({
        Name = "Ragdoll Recovery",
        Default = cfg.player.antiRagdoll == true,
        Description = "stands you back up after a ragdoll",
        Callback = function(v)
            cfg.player.antiRagdoll = v
            C.save()
            Feat.setAntiRagdoll(v)
        end,
    })
    exploitSec:AddToggle({
        Name = "Instant Prompts",
        Default = cfg.player.instantPrompts == true,
        Description = "no hold time when you press prompts",
        Callback = function(v)
            cfg.player.instantPrompts = v
            C.save()
            Feat.setInstantPrompts(v)
        end,
    })
    exploitSec:AddToggle({
        Name = "Invisible",
        Default = cfg.player.invisible == true,
        Description = "only you see it",
        Callback = function(v)
            cfg.player.invisible = v
            C.save()
            Feat.setInvisible(v)
        end,
    })
    exploitSec:AddToggle({
        Name = "Anti Trap",
        Default = cfg.player.antiTrap == true,
        Description = "walks around traps while carrying",
        Callback = function(v)
            cfg.player.antiTrap = v
            C.save()
            Feat.setAntiTrap(v)
        end,
    })
    local serverSec = Feat.sec(playerTab, "Server")
    serverSec:AddDropdown({
        Name = "Hop Mode",
        Options = { "Random", "Fewest Players", "Most Players" },
        Default = cfg.misc.hopMode or "Random",
        Callback = function(v)
            cfg.misc.hopMode = v or "Random"
            C.save()
        end,
    })
    serverSec:AddButton({
        Name = "Hop Server",
        Callback = function()
            task.spawn(Feat.hopServer)
        end,
    })
    serverSec:AddButton({
        Name = "Rejoin",
        Description = "same server",
        Callback = function()
            task.spawn(Feat.rejoin)
        end,
    })
    serverSec:AddToggle({
        Name = "Auto Rejoin on Disconnect",
        Default = cfg.misc.autoRejoin == true,
        Description = "rejoins if you get disconnected",
        Callback = function(v)
            cfg.misc.autoRejoin = v
            C.save()
            Feat.setAutoRejoin(v)
        end,
    })
    local qSupported = Feat.queueFn() ~= nil
    serverSec:AddToggle({
        Name = "Auto Load Script",
        Default = cfg.misc.autoLoad == true,
        Description = qSupported
                and "Loads the script file below again after any teleport: Hop, Rejoin, Join Job ID, Auto Rejoin or the game's own idle move."
            or "This executor has no queue_on_teleport, so the script cannot load itself after a teleport.",
        Callback = function(v)
            cfg.misc.autoLoad = v
            C.save()
            Feat.setAutoLoad(v)
            if v and not qSupported then
                BPUI:Notify({
                    Title = "Auto Load",
                    Content = "Your executor can't queue scripts",
                    Type = "Warning",
                    Duration = 4,
                })
            elseif v then
                local fn, why = Feat.readScript()
                if not fn then
                    BPUI:Notify({ Title = "Auto Load", Content = why, Type = "Warning", Duration = 5 })
                end
            end
        end,
    })
    serverSec:AddInput({
        Name = "Script File (workspace)",
        Default = Feat.scriptPath(),
        Placeholder = "stealanegg.lua",
        Description = "file name in your workspace folder",
        Callback = function(v)
            cfg.misc.scriptFile = tostring(v or "")
            C.save()
            state.loadQueued = false
            local fn, why = Feat.readScript()
            BPUI:Notify({
                Title = "Script File",
                Content = fn and ("Found " .. Feat.scriptPath()) or why,
                Type = fn and "Success" or "Warning",
                Duration = 4,
            })
        end,
    })
    serverSec:AddLabel("Job ID: " .. (game.JobId ~= "" and game.JobId or "none"))
    serverSec:AddButton({
        Name = "Copy Job ID",
        Callback = function()
            local E = (getgenv and getgenv()) or _G
            local clip = E.setclipboard or E.toclipboard or (type(setclipboard) == "function" and setclipboard) or nil
            local ok = type(clip) == "function" and game.JobId ~= "" and pcall(clip, game.JobId)
            BPUI:Notify({
                Title = "Job ID",
                Content = ok and "Copied the current Job ID" or "This executor cannot copy to the clipboard",
                Type = ok and "Success" or "Warning",
                Duration = 3,
            })
        end,
    })
    local jobText = ""
    serverSec:AddInput({
        Name = "Job ID to Join",
        Default = "",
        Placeholder = "paste a Job ID",
        Callback = function(v)
            jobText = tostring(v or "")
        end,
    })
    serverSec:AddButton({
        Name = "Join Job ID",
        Description = "joins the job id above",
        Callback = function()
            task.spawn(Feat.joinJob, jobText)
        end,
    })

    local perfSec = Feat.sec(playerTab, "Performance")
    pcall(Feat.twoCol, serverSec, perfSec)
    local fpsOk = type(setfpscap) == "function"
    perfSec:AddInput({
        Name = "FPS Cap",
        Default = tostring(math.floor(tonumber(cfg.misc.fpsCap) or 0)),
        Placeholder = "0 = off",
        Numeric = true,
        Description = fpsOk
                and "Limits the frame rate to save CPU/GPU while farming (5 or more). 0 turns it off and restores your previous cap."
            or "This executor has no setfpscap.",
        Callback = function(v)
            local n = math.max(0, math.floor(tonumber(v) or 0))
            if n > 0 and n < 5 then
                n = 5
            end
            cfg.misc.fpsCap = n
            C.save()
            local ok, why = Feat.setFpsCap(n)
            if not ok then
                BPUI:Notify({ Title = "FPS Cap", Content = tostring(why), Type = "Warning", Duration = 3 })
            end
        end,
    })
    if fpsOk and (tonumber(cfg.misc.fpsCap) or 0) > 0 then
        Feat.setFpsCap(cfg.misc.fpsCap)
    end
    perfSec:AddToggle({
        Name = "Disable 3D Rendering",
        Default = cfg.misc.no3d == true,
        Description = "black screen, big fps boost",
        Callback = function(v)
            cfg.misc.no3d = v
            C.save()
            local ok, why = Feat.set3d(v)
            if not ok then
                BPUI:Notify({ Title = "Performance", Content = tostring(why), Type = "Warning", Duration = 3 })
            end
        end,
    })
end
do
    local areaTpSec = Feat.sec(tpTab, "Walk To Area")
    local tpAreas = {
        "Forest",
        "Lake",
        "Desert",
        "Jungle",
        "Snow",
        "Volcano",
        "Abyss Ocean",
        "Prehistoric",
        "Cosmic",
        "Cherry Blossom",
        "Titan Temple",
        "Light Dark",
    }
    local tpAreaDrop = areaTpSec:AddDropdown({
        Name = "Select Area",
        Options = tpAreas,
        Default = "Forest",
        Callback = function() end,
    })
    areaTpSec:AddButton({
        Name = "Walk to Area",
        Callback = function()
            tpToArea(tpAreaDrop and tpAreaDrop:Get() or "Forest")
        end,
    })
    areaTpSec:AddButton({
        Name = "Stop Walking",
        Description = "stops walking, steals keep running",
        Callback = function()
            Feat.stopWalk()
        end,
    })
    local plotTpSec = Feat.sec(tpTab, "Plot / Machine")
    pcall(Feat.twoCol, areaTpSec, plotTpSec)
    plotTpSec:AddButton({ Name = "My Plot", Callback = tpToOwnPlot })
    plotTpSec:AddButton({
        Name = "Rift Machine",
        Callback = function()
            tpToMachine("RiftMachine")
        end,
    })
    plotTpSec:AddButton({
        Name = "Fuse Machine",
        Callback = function()
            tpToMachine("FuseMachine")
        end,
    })
end
do
    local liveSec = Feat.sec(evTab, "Live Events")
    local liveLbl = liveSec:AddLabel("Live event status: waiting for the game")
    pcall(Feat.watchLiveEvents)
    autoConns._liveLbl = H.task(function()
        if state.destroyed then
            return
        end
        local okL, lt = pcall(Feat.liveStatusText)
        if okL then
            Feat.ui(function()
                liveLbl:Set(lt)
            end)
        end
    end, 2, 0.5)
    local predSec = Feat.sec(evTab, "Egg Predictor")
    pcall(Feat.twoCol, liveSec, predSec)
    local predPara = predSec:AddParagraph({ Title = "Egg Spawns", Content = "Loading..." })
    Feat.watchRare()
    autoConns._predict = H.task(function()
        if state.destroyed or not win or not win._visible or win._minimized then
            return
        end
        local okP, pt = pcall(Feat.predictorText)
        if okP then
            Feat.ui(function()
                predPara:Set(pt)
            end)
        end
    end, 1, 0.5)
end
do
    local bossSec = Feat.sec(evTab, "Boss Event")
    state.bossLbl = bossSec:AddLabel("Loading status...")
    bossSec:AddToggle({
        Name = "Auto Boss Enter",
        Default = cfg.boss.autoEnter,
        Description = "enters as soon as it opens",
        Callback = function(v)
            cfg.boss.autoEnter = v
            C.save()
            state.bossRetryAt = 0
        end,
    })
    bossSec:AddButton({
        Name = "Manual Boss Enter",
        Callback = function()
            task.spawn(function()
                local okT, ok, why = pcall(Feat.tryEnterBoss)
                if not okT then
                    ok, why = false, firstLine(ok)
                end
                BPUI:Notify({
                    Title = "Boss",
                    Content = ok and "You are in the boss arena" or ("Could not enter: " .. tostring(why)),
                    Type = ok and "Success" or "Warning",
                    Duration = 4,
                })
            end)
        end,
    })
    bossSec:AddButton({
        Name = "Use Fractured Crystal (best placed egg)",
        Description = "uses one on your best placed egg",
        Callback = function()
            task.spawn(Feat.useConsumable)
        end,
    })
    bossSec:AddToggle({
        Name = "Auto Claim Mastery Rewards",
        Default = cfg.auto.mastery == true,
        Description = "checks every 60s",
        Callback = function(v)
            cfg.auto.mastery = v
            C.save()
            if v then
                autoLoop("mastery", 60, Feat.claimMastery)
            else
                Feat.stopAuto("mastery")
            end
        end,
    })
    bossSec:AddButton({
        Name = "Claim Mastery Rewards",
        Callback = function()
            task.spawn(function()
                local n, why = Feat.claimMastery(true)
                local txt = n > 0
                        and (string.format("Claimed %d reward(s)", n) .. (why and (", then stopped: " .. why) or ""))
                    or ("Nothing claimed: " .. tostring(why or "no reason given"))
                BPUI:Notify({
                    Title = "Boss Mastery",
                    Content = txt,
                    Type = n > 0 and "Success" or "Info",
                    Duration = 4,
                })
            end)
        end,
    })
    local bossShopSec = Feat.sec(evTab, "Boss Shop")
    pcall(Feat.twoCol, bossSec, bossShopSec)
    state.bossTokLbl = bossShopSec:AddLabel("Boss Tokens: ?")
    local shopLabel, shopId, shopOpts = {}, {}, {}
    for _, p in ipairs(Feat.bossShopProducts()) do
        local l = string.format("%s (%s tokens)", p.name, p.price and tostring(p.price) or "?")
        shopLabel[p.id], shopId[l] = l, p.id
        shopOpts[#shopOpts + 1] = l
    end
    if #shopOpts == 0 then
        for _, id in ipairs({ "CashBooster", "SpeedBoost", "TreadmillBooster", "MutationConsumable" }) do
            shopLabel[id], shopId[id] = id, id
            shopOpts[#shopOpts + 1] = id
        end
    end
    bossShopSec:AddDropdown({
        Name = "Items to Buy",
        Options = shopOpts,
        Default = (function()
            local t = {}
            for _, id in ipairs(asList(cfg.boss.shopItems)) do
                t[#t + 1] = shopLabel[id] or id
            end
            return t
        end)(),
        Multi = true,
        Callback = function(v)
            local ids = {}
            for _, l in ipairs(asList(v)) do
                ids[#ids + 1] = shopId[l] or l
            end
            cfg.boss.shopItems = ids
            C.save()
        end,
    })
    bossShopSec:AddInput({
        Name = "Keep Boss Tokens",
        Default = tostring(tonumber(cfg.boss.keepTokens) or 0),
        Placeholder = "0",
        Numeric = true,
        Description = "keeps at least this many",
        Callback = function(v)
            cfg.boss.keepTokens = math.max(0, math.floor(tonumber(v) or 0))
            C.save()
        end,
    })
    bossShopSec:AddToggle({
        Name = "Auto Buy Boss Shop",
        Default = cfg.auto.bossShop == true,
        Description = "buys what you picked every 60s",
        Callback = function(v)
            cfg.auto.bossShop = v
            C.save()
            if v then
                autoLoop("bossShop", 60, Feat.autoBossShop)
            else
                Feat.stopAuto("bossShop")
            end
        end,
    })
    bossShopSec:AddButton({
        Name = "Buy Selected Items Now",
        Callback = function()
            task.spawn(function()
                local n, why = Feat.autoBossShop(true)
                local txt = n > 0
                        and (string.format("Bought %d item(s)", n) .. (why and (". Not bought: " .. why) or ""))
                    or ("Nothing bought: " .. tostring(why or "no reason given"))
                BPUI:Notify({
                    Title = "Boss Shop",
                    Content = txt,
                    Type = n > 0 and "Success" or "Warning",
                    Duration = 5,
                })
                pcall(Feat.updateBossLabel)
            end)
        end,
    })
    Feat.startBossTrack()
end
do
    local lvdSec = Feat.sec(evTab, "Light vs Dark")
    lvdSec:AddToggle({
        Name = "Auto Collect",
        Default = cfg.events.lvd,
        Description = "grabs rings and power ups",
        Callback = function(v)
            cfg.events.lvd = v
            C.save()
            if v then
                Feat.startLVD()
            else
                Feat.stopLVD()
            end
        end,
    })
    lvdSec:AddDropdown({
        Name = "Collect Mode",
        Options = { "All", "Rings Only", "Powers Only" },
        Default = cfg.events.lvdMode or "All",
        Callback = function(v)
            cfg.events.lvdMode = v
            C.save()
        end,
    })
    lvdSec:AddDropdown({
        Name = "Team",
        Options = { "Random", "Light", "Darkness" },
        Default = cfg.events.lvdTeam or "Random",
        Callback = function(v)
            cfg.events.lvdTeam = v or "Random"
            C.save()
        end,
    })
    lvdSec:AddToggle({
        Name = "Auto Pick Team",
        Default = cfg.auto.lvdTeam == true,
        Description = "joins the team you picked",
        Callback = function(v)
            cfg.auto.lvdTeam = v
            C.save()
            if v then
                autoLoop("lvdTeam", 5, Feat.lvdPickTeam)
            else
                Feat.stopAuto("lvdTeam")
            end
        end,
    })
    lvdSec:AddToggle({
        Name = "Auto Claim Milestones",
        Default = cfg.auto.lvdClaim == true,
        Description = "claims milestones when ready",
        Callback = function(v)
            cfg.auto.lvdClaim = v
            C.save()
            if v then
                autoLoop("lvdClaim", 10, Feat.lvdClaimMilestones)
            else
                Feat.stopAuto("lvdClaim")
            end
        end,
    })
    lvdSec:AddButton({
        Name = "Claim Milestones Now",
        Callback = function()
            task.spawn(function()
                local okT, n, why = pcall(Feat.lvdClaimMilestones, true)
                if not okT then
                    n, why = 0, firstLine(n)
                end
                local txt = n > 0
                        and (string.format("Claimed %d milestone(s)", n) .. (why and (", then stopped: " .. why) or ""))
                    or ("Nothing claimed: " .. tostring(why or "no reason given"))
                BPUI:Notify({
                    Title = "LvD Milestones",
                    Content = txt,
                    Type = n > 0 and "Success" or "Info",
                    Duration = 4,
                })
            end)
        end,
    })
    lvdSec:AddButton({
        Name = "Check Score",
        Callback = function()
            task.spawn(function()
                local rf = netRF("LightVsDarkness/FetchScore")
                if not rf then
                    BPUI:Notify({
                        Title = "LvD Score",
                        Content = "Score remote not found",
                        Type = "Warning",
                        Duration = 3,
                    })
                    return
                end
                local ok, light, dark = pcall(function()
                    return rf:InvokeServer()
                end)
                local txt
                if ok and type(light) == "number" and type(dark) == "number" then
                    txt = string.format(
                        "Light: %s  |  Darkness: %s  |  Your team: %s",
                        shortNum(light),
                        shortNum(dark),
                        tostring(lp:GetAttribute("LvdTeam") or "none")
                    )
                elseif ok then
                    txt = "No score yet (the event is not running)"
                else
                    txt = "Failed: " .. firstLine(light)
                end
                BPUI:Notify({ Title = "LvD Score", Content = txt, Type = "Info", Duration = 5 })
            end)
        end,
    })
    local scramSec = Feat.sec(evTab, "Dr. Scramble")
    scramSec:AddToggle({
        Name = "Auto Collect Drops",
        Default = cfg.events.scramble,
        Description = "grabs your drops",
        Callback = function(v)
            cfg.events.scramble = v
            C.save()
            if v then
                Feat.startScramble()
            else
                Feat.stopScramble()
            end
        end,
    })
    local sammySec = Feat.sec(evTab, "Sammy Event")
    pcall(Feat.twoCol, scramSec, sammySec)
    sammySec:AddToggle({
        Name = "Auto Collect Pickups",
        Default = cfg.events.sammy,
        Description = "grabs event pickups",
        Callback = function(v)
            cfg.events.sammy = v
            C.save()
            if v then
                Feat.startSammy()
            else
                Feat.stopSammy()
            end
        end,
    })
    local monstSec = Feat.sec(evTab, "Monster Event")
    local function monstSay(txt, kind)
        BPUI:Notify({ Title = "Monster Event", Content = txt, Type = kind or "Info", Duration = 4 })
    end
    monstSec:AddButton({
        Name = "Check Monster Wins",
        Callback = function()
            task.spawn(function()
                local rf = netRF("MonsterEvent/GetWins")
                if not rf then
                    monstSay("Monster Event remotes not found", "Warning")
                    return
                end
                local ok, w = pcall(function()
                    return rf:InvokeServer()
                end)
                monstSay(
                    ok and ("Wins: " .. tostring(tonumber(w) or 0)) or ("Failed: " .. firstLine(w)),
                    ok and "Info" or "Warning"
                )
            end)
        end,
    })
    monstSec:AddButton({
        Name = "Monster Event TP",
        Description = "only works while the event is on",
        Callback = function()
            task.spawn(function()
                Feat.watchLiveEvents()
                if Feat.liveRunning("MonsterEvent") == false or not workspace:FindFirstChild("MonsterEventMap") then
                    monstSay("The Monster Event is not running", "Warning")
                    return
                end
                local rf = netRF("MonsterEvent/RequestTeleport")
                if not rf then
                    monstSay("Monster Event remotes not found", "Warning")
                    return
                end
                local ok, r1, r2 = pcall(function()
                    return rf:InvokeServer()
                end)
                if ok and r1 ~= false then
                    monstSay("Teleport requested" .. (r1 ~= nil and (" (server: " .. tostring(r1) .. ")") or ""))
                else
                    monstSay(
                        "Teleport refused: " .. (ok and tostring(r2 or "no reason given") or firstLine(r1)),
                        "Warning"
                    )
                end
            end)
        end,
    })
end
do
    local trainSec = Feat.sec(farmTab, "Speed Training")
    local trainPara = trainSec:AddParagraph({ Title = "Speed", Content = "Loading..." })
    local AREA_ORDER = {
        "Forest",
        "Lake",
        "Desert",
        "Jungle",
        "Snow",
        "Volcano",
        "Abyss Ocean",
        "Prehistoric",
        "Cosmic",
        "Cherry Blossom",
        "Titan Temple",
        "Light Dark",
    }
    local function trainText()
        local sp, rate = currentSpeedPower(), trainingRate()
        local lines = {
            string.format(
                "SpeedPower: %s  |  Walk: %d  |  Training: +%s/s",
                shortNum(sp),
                math.floor(baseWalkSpeed()),
                shortNum(rate)
            ),
        }
        local locked = 0
        for _, a in ipairs(AREA_ORDER) do
            local n = state.areaNeeds[a]
            if n and sp < (n.clean or 0) then
                locked += 1
                if cfg.steal.relay and sp >= (n.relay or math.huge) then
                    lines[#lines + 1] = string.format("%s: RELAY ok, clean at %s", a, shortNum(n.clean))
                else
                    local need = cfg.steal.relay and n.relay or n.clean
                    local eta = rate > 0 and fmtDuration((need - sp) / rate) or "stand on treadmill for ETA"
                    lines[#lines + 1] = string.format("%s: needs %s (%s)", a, shortNum(need), eta)
                end
            end
        end
        if next(state.areaNeeds) == nil then
            lines[#lines + 1] = "Area requirements: no egg data yet (they appear once the egg list loads)"
            if os.clock() - (state.needsTry or 0) > 15 and not state.inRun then
                state.needsTry = os.clock()
                task.spawn(refreshEggs, true, true)
            end
        elseif locked == 0 then
            lines[#lines + 1] = "Every area with eggs is CLEAN at your speed"
        end
        local nextT = nextTreadmillTier()
        if nextT then
            lines[#lines + 1] = string.format(
                "Next treadmill: %s (x%s) $%s, you have $%s",
                tostring(nextT.DisplayName or nextT._id),
                tostring(nextT.SpeedMultiplier),
                shortNum(nextT.Price),
                shortNum(money())
            )
        end
        local okL, tl = pcall(Feat.trailLine)
        if okL and tl then
            lines[#lines + 1] = tl
        end
        lines[#lines + 1] = onTreadmill() and "Status: on treadmill" or "Status: not on treadmill"
        if cfg.train.on and state.trainPauseUntil == math.huge then
            lines[#lines + 1] = "Auto Train is paused after a manual walk: turn it off and on to resume"
        end
        return table.concat(lines, "\n")
    end
    autoConns._train = H.task(function()
        local okT, tt = pcall(trainText)
        if okT then
            Feat.ui(function()
                trainPara:Set(tt)
            end)
        end
    end, 2, 1)

    state.trainToken = 0
    local function startTraining()
        state.trainToken += 1
        local my = state.trainToken
        task.spawn(function()
            local function paused()
                return state.running
                    or state.manualWalk ~= nil
                    or os.clock() < (state.trainPauseUntil or 0)
                    or lp:GetAttribute("InBossArena") == true
            end
            local function still(t)
                return state.trainToken == t and cfg.train.on and not state.destroyed and not paused()
            end
            while state.trainToken == my and cfg.train.on and not state.destroyed do
                if not paused() and state.beltId == nil and not onTreadmill() then
                    setStatus("Auto Train: walking to treadmill")
                    state.trainWalking = true
                    setUserControls(false)
                    local okW, ok, why = pcall(goTrain, my, still)
                    state.trainWalking = false
                    releaseControls()
                    if not okW then
                        ok, why = false, firstLine(ok)
                    end
                    if ok then
                        setStatus("Auto Train: training")
                    elseif why ~= "cancelled" then
                        logRun("Auto Train: " .. tostring(why))
                    end
                end
                task.wait(2)
            end
        end)
    end
    state.trainTog = trainSec:AddToggle({
        Name = "Auto Train",
        Default = cfg.train.on == true,
        Callback = function(v)
            cfg.train.on = v
            C.save()
            if state.trainPauseUntil == math.huge then
                state.trainPauseUntil = 0
            end
            if v then
                startTraining()
            else
                state.trainToken += 1
                stopMoving()
            end
        end,
    })
    trainSec:AddButton({
        Name = "Buy Next Treadmill",
        Callback = function()
            task.spawn(function()
                local ok, msg = Feat.autoUpgradeTreadmill()
                BPUI:Notify({
                    Title = "Treadmill",
                    Content = tostring(msg),
                    Type = ok and "Success" or "Warning",
                    Duration = 3,
                })
            end)
        end,
    })

    local trailSec = Feat.sec(farmTab, "Trails")
    pcall(Feat.twoCol, trainSec, trailSec)
    trailSec:AddToggle({
        Name = "Auto Buy Trail",
        Default = cfg.auto.trail == true,
        Description = "buys + equips the next trail",
        Callback = function(v)
            cfg.auto.trail = v
            C.save()
            if v then
                autoLoop("trail", 30, Feat.autoTrail)
            else
                Feat.stopAuto("trail")
            end
        end,
    })
    Feat.amountInput(trailSec, "Keep Money", function()
        return cfg.trail.keep
    end, function(n)
        cfg.trail.keep = n
    end, nil, "Auto Buy Trail never takes your money below this amount.")
    trailSec:AddButton({
        Name = "Buy / Wear Best Trail Now",
        Callback = function()
            task.spawn(function()
                local okT, ok, msg = pcall(Feat.autoTrail, true)
                if not okT then
                    ok, msg = false, firstLine(ok)
                end
                BPUI:Notify({
                    Title = "Trail",
                    Content = tostring(msg),
                    Type = ok and "Success" or "Info",
                    Duration = 4,
                })
            end)
        end,
    })
end
do
    local awaySec = Feat.sec(farmTab, "Offline Income")
    awaySec:AddToggle({
        Name = "Auto Collect (60s)",
        Default = cfg.farm.awayAuto,
        Callback = function(v)
            cfg.farm.awayAuto = v
            C.save()
            if v then
                Feat.startAwayEarnings()
            elseif state.awayConn then
                state.awayConn:Disconnect()
                state.awayConn = nil
            end
        end,
    })
    awaySec:AddButton({
        Name = "Collect Now",
        Callback = function()
            task.spawn(function()
                local ok, why = Feat.collectAwayEarnings()
                if not ok then
                    BPUI:Notify({ Title = "Offline Income", Content = tostring(why), Type = "Warning", Duration = 4 })
                end
            end)
        end,
    })
end

do
    local confTab = miscGrp:CreateTab({ Name = "Config", Icon = "settings" })
    local profSec = Feat.sec(confTab, "Profiles")
    profSec:AddToggle({
        Name = "Extra UI Animations",
        Default = cfg.ui.animations ~= false,
        Description = "gentle section reveals and smoother interaction timing",
        Callback = function(enabled)
            Feat.setUiAnimations(enabled)
            C.save()
        end,
    })
    profSec:AddParagraph({
        Title = "Profiles",
        Content = "Settings save automatically. Reload after loading a profile.",
    })
    local profName, profDrop = "", nil
    local function profOpts()
        local l = C.profiles()
        if #l == 0 then
            l = { "(none)" }
        end
        return l
    end
    local function profRefresh(sel)
        if profDrop then
            pcall(function()
                profDrop:Refresh(profOpts())
                if sel then
                    profDrop:Set(sel, true)
                end
            end)
        end
    end
    local function say(txt, kind)
        BPUI:Notify({ Title = "Profiles", Content = txt, Type = kind or "Warning", Duration = 4 })
    end
    local function keepLearned(fn)
        local learned = {}
        for k, v in pairs(state.multByCat or {}) do
            learned[k] = v
        end
        local ok, err = fn()
        if type(cfg.mults) ~= "table" then
            cfg.mults = {}
        end
        for k, v in pairs(learned) do
            if cfg.mults[k] == nil then
                cfg.mults[k] = v
            end
        end
        state.multByCat = cfg.mults
        return ok, err
    end
    profSec:AddInput({
        Name = "Profile Name",
        Default = "",
        Placeholder = "e.g. farm",
        MaxLength = 32,
        Callback = function(v)
            profName = tostring(v or "")
        end,
    })
    profSec:AddButton({
        Name = "Save Profile",
        Callback = function()
            local p = profName:gsub("[^%w _%-]", ""):gsub("^%s+", ""):gsub("%s+$", "")
            if p == "" then
                say("Type a profile name first (letters, numbers, space, - and _)")
                return
            end
            local url = cfg.hook.url
            cfg.hook.url = ""
            local ok, err = C.saveAs(p)
            cfg.hook.url = url
            if not ok then
                say("Save failed: " .. firstLine(err), "Error")
                return
            end
            profRefresh(p)
            say("Saved profile '" .. p .. "'", "Success")
        end,
    })
    profDrop =
        profSec:AddDropdown({ Name = "Saved Profiles", Options = profOpts(), Default = nil, Callback = function() end })
    profSec:AddButton({
        Name = "Refresh List",
        Callback = function()
            profRefresh()
        end,
    })
    profSec:AddButton({
        Name = "Load Profile",
        Callback = function()
            local p = profDrop and profDrop:Get()
            if not p or p == "(none)" then
                say("Select a saved profile first")
                return
            end
            local url = cfg.hook.url
            local ok, err = keepLearned(function()
                return C.loadFrom(p)
            end)
            if not ok then
                say("Load failed: " .. firstLine(err), "Error")
                return
            end
            if not Feat.hookValid(cfg.hook.url) then
                cfg.hook.url = url
            end
            Feat.loadGuards()
            C.flush()
            local shown = pcall(function()
                win:Dialog({
                    Title = "Profile loaded",
                    Content = "'"
                        .. p
                        .. "' is loaded and saved. Reload the script now so every toggle and feature uses it?",
                    Buttons = {
                        { Text = "Later" },
                        { Text = "Reload Now", Style = "Accent", Callback = Feat.reloadScript },
                    },
                })
            end)
            if not shown then
                say("Profile '" .. p .. "' loaded. Press Reload Script so every toggle uses it.", "Success")
            end
        end,
    })
    profSec:AddButton({
        Name = "Delete Profile",
        Callback = function()
            local p = profDrop and profDrop:Get()
            if not p or p == "(none)" then
                say("Select a saved profile first")
                return
            end
            Feat.confirm(
                "Delete profile",
                "Delete the profile '" .. p .. "'? This cannot be undone.",
                "Delete",
                function()
                    local ok, err = C.delete(p)
                    if not ok then
                        say("Delete failed: " .. firstLine(err), "Error")
                        return
                    end
                    profRefresh()
                    say("Deleted profile '" .. p .. "'", "Success")
                end
            )
        end,
    })
    profSec:AddButton({
        Name = "Reset To Defaults",
        Callback = function()
            Feat.confirm(
                "Reset settings",
                "Reset every setting of this script to its default? Your profiles are kept.",
                "Reset",
                function()
                    local url = cfg.hook.url
                    keepLearned(function()
                        C.reset()
                        return true
                    end)
                    cfg.hook.url = url
                    C.flush()
                    local shown = pcall(function()
                        win:Dialog({
                            Title = "Settings reset",
                            Content = "Reload the script now?",
                            Buttons = {
                                { Text = "Later" },
                                { Text = "Reload Now", Style = "Accent", Callback = Feat.reloadScript },
                            },
                        })
                    end)
                    if not shown then
                        say("Settings reset. Press Reload Script so every toggle shows it.", "Success")
                    end
                end
            )
        end,
    })
    profSec:AddButton({ Name = "Reload Script", Description = "reruns the script", Callback = Feat.reloadScript })

    profSec:AddButton({
        Name = "Collapse All Sections",
        Description = "or just click any section title",
        Callback = function()
            for _, sec in ipairs(Feat.sections) do
                pcall(sec.SetOpen, sec, false)
            end
        end,
    })
    profSec:AddButton({
        Name = "Expand All Sections",
        Callback = function()
            for _, sec in ipairs(Feat.sections) do
                pcall(sec.SetOpen, sec, true)
            end
        end,
    })

    local hookSec = Feat.sec(confTab, "Discord Webhook")
    pcall(Feat.twoCol, profSec, hookSec)
    local function masked()
        return Feat.hookValid(cfg.hook.url) and "(saved, hidden)" or ""
    end
    local urlBox
    urlBox = hookSec:AddInput({
        Name = "Webhook URL",
        Default = masked(),
        Placeholder = "https://discord.com/api/webhooks/...",
        Description = "clear it to remove",
        Callback = function(v)
            v = tostring(v or ""):gsub("^%s+", ""):gsub("%s+$", "")
            if v == "(saved, hidden)" then
                return
            end
            v = v:gsub("^%(saved, hidden%)%s*", "")
            if v == "" then
                cfg.hook.url = ""
                C.save()
                BPUI:Notify({ Title = "Webhook", Content = "Webhook URL removed", Type = "Info", Duration = 3 })
                return
            end
            if not Feat.hookValid(v) then
                BPUI:Notify({ Title = "Webhook", Content = "Not a Discord webhook URL", Type = "Warning", Duration = 4 })
                Feat.ui(function()
                    urlBox:Set(masked(), true)
                end)
                return
            end
            cfg.hook.url = v
            C.save()
            Feat.ui(function()
                urlBox:Set(masked(), true)
            end)
            BPUI:Notify({ Title = "Webhook", Content = "Webhook URL saved", Type = "Success", Duration = 3 })
        end,
    })
    hookSec:AddToggle({
        Name = "Notify on Rare Egg Spawn",
        Default = cfg.hook.rare == true,
        Description = "rare spawns at or above the rarity below",
        Callback = function(v)
            cfg.hook.rare = v
            C.save()
        end,
    })
    Feat.rarityDrop(hookSec, "Rare Spawn Min Rarity", function()
        return cfg.hook.minRarity
    end, function(v)
        cfg.hook.minRarity = v
    end, "Any = every announced rare spawn.")
    hookSec:AddToggle({
        Name = "Notify on Steal Success",
        Default = cfg.hook.steal == true,
        Description = "every egg you deliver",
        Callback = function(v)
            cfg.hook.steal = v
            C.save()
        end,
    })
    hookSec:AddButton({
        Name = "Test Webhook",
        Callback = function()
            if Feat.hookBusy or os.clock() - (state.hookTestAt or 0) < 3 then
                BPUI:Notify({ Title = "Webhook", Content = "Wait a bit", Type = "Warning", Duration = 3 })
                return
            end
            state.hookTestAt = math.huge
            task.spawn(function()
                local okP, ok, why = pcall(Feat.hookPost, "BPHUB test message from Steal An Egg")
                state.hookTestAt = os.clock()
                if not okP then
                    ok, why = false, firstLine(ok)
                end
                BPUI:Notify({
                    Title = "Webhook",
                    Content = ok and ("Test sent (" .. tostring(why) .. ")") or ("Test failed: " .. tostring(why)),
                    Type = ok and "Success" or "Error",
                    Duration = 4,
                })
            end)
        end,
    })
end

BPUI:Notify({ Title = "Steal An Egg", Content = "Module loaded", Type = "Success", Duration = 3 })

local function stop_all()
    if state.destroyed then
        return
    end
    state.destroyed = true
    if Feat.motion then
        Feat.stopUiAnimations()
    end
    cancel()
    state.trainToken = (state.trainToken or 0) + 1
    if state.sampler then
        pcall(function()
            state.sampler.stop()
        end)
    end
    for _, j in pairs(autoConns) do
        pcall(function()
            j.stop()
        end)
    end
    autoConns = {}
    Feat.setAntiRagdoll(false)
    Feat.setInstantPrompts(false)
    Feat.setInvisible(false)
    Feat.setAntiTrap(false)
    Feat.setAutoRejoin(false)
    Feat.setAutoLoad(false)
    pcall(Feat.setFpsCap, 0)
    pcall(Feat.set3d, false)
    stopEsp(true)
    Feat.setNoclip(false)
    Feat.setInfJump(false)
    Feat.stopBossTrack()
    Feat.stopLVD()
    Feat.stopScramble()
    Feat.stopSammy()
    if state.clearHighlight then
        state.clearHighlight()
    end
    for _, c in conns do
        pcall(function()
            c:Disconnect()
        end)
    end
    conns = {}
    C.flush()
end

stopAllRef = stop_all
genv.__BPHUB_SAE_API = {
    state = state,
    cfg = cfg,
    start = start,
    startBest = startBest,
    cancel = cancel,
    refreshEggs = refreshEggs,
    fieldRecord = fieldRecord,
    updateEggDrop = updateEggDrop,
    eggVerdict = eggVerdict,
    allowedCarrySpeed = allowedCarrySpeed,
    baseWalkSpeed = baseWalkSpeed,
    trainingRate = trainingRate,
    onTreadmill = onTreadmill,
    logRun = logRun,
    Feat = Feat,
}
genv.__BPHUB_SAE_UNLOAD = function()
    stop_all()
    pcall(function()
        win:Destroy()
    end)
end

return { stop = stop_all }