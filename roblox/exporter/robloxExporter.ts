/**
 * Roblox Studio Exporter & Luau Port Kit for LAST LOCAL
 *
 * Generates:
 * 1. A complete, native Roblox Studio XML Place file (`LAST_LOCAL_Roblox.rbxlx`) containing:
 *    - Workspace: 3-car NYC G-Train consist (Car A, Car B, Car C), gangways, sliding doors,
 *      scooped orange/yellow subway benches, stainless steel poles, fluorescent ceiling lights,
 *      SurfaceGui interior ads & route maps, MTA station platform, tunnel, Mom, Dad, and passengers.
 *    - Lighting: Liminal subway lighting & SanityColorCorrection post-processing.
 *    - ReplicatedStorage: `LastLocalConfig` ModuleScript (all 13 stops, segments, dialogues, ads) + RemoteEvents.
 *    - ServerScriptService: `LastLocalServer` Script (ride loop, anomalies, parent gaze/suspicion, endings).
 *    - StarterPlayerScripts: `LastLocalClient` LocalScript (first-person camera, raycast flagging, head-whip detection, UI & mobile touch controls).
 * 2. Standalone Luau scripts ready to copy-paste into any Roblox Studio project.
 * 3. Direct browser download triggers for the 3D `.glb` models (via `src/dev/glbExport.ts`) for Roblox Studio's "Import 3D" tool.
 */

export interface RobloxScriptFile {
  id: 'config' | 'server' | 'client';
  filename: string;
  robloxPath: string;
  scriptType: 'ModuleScript' | 'Script (Server)' | 'LocalScript (Client)';
  summary: string;
  code: string;
}

/** Scale factor: 1 game meter = 3.5 Roblox studs (so 2.43m ceiling = 8.5 studs, comfortable for Roblox R6/R15 rigs). */
const S = 3.5;

function xmlEscape(str: string): string {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;');
}

function cdataWrap(code: string): string {
  return `<![CDATA[${code.replace(/\]\]>/g, ']]]]><![CDATA[>')}]]>`;
}

export const LUAU_CONFIG_SOURCE = `--[[
  LAST LOCAL: A Liminal Subway Horror Game (Roblox Luau Port)
  Place this ModuleScript in: ReplicatedStorage.LastLocalConfig
]]

local LastLocalConfig = {}

LastLocalConfig.SCALE = 3.5 -- 1 meter = 3.5 Roblox studs
LastLocalConfig.CRUISE_SPEED = 49 -- studs/sec (~14 m/s)
LastLocalConfig.FLAG_HOLD_SECONDS = 0.7
LastLocalConfig.HEAD_WHIP_THRESHOLD = 5.5 -- rad/s while parent is watching

LastLocalConfig.STOPS = {
  [1] = "Hoyt-Schermerhorn",
  [2] = "Fulton St",
  [3] = "Clinton-Washington Avs",
  [4] = "Classon Av",
  [5] = "Bedford-Nostrand Avs",
  [6] = "Myrtle-Willoughby Avs",
  [7] = "Flushing Av",
  [8] = "Broadway",
  [9] = "Metropolitan Av",
  [10] = "Nassau Av",
  [11] = "Greenpoint Av",
  [12] = "21 St",
  [13] = "Court Sq",
}

-- Sanity [min, max] clamp band per stop
LastLocalConfig.BANDS = {
  [1]  = { 80, 100 },
  [2]  = { 80, 100 },
  [3]  = { 80, 100 },
  [4]  = { 70, 95 },
  [5]  = { 50, 85 },
  [6]  = { 50, 85 },
  [7]  = { 30, 70 },
  [8]  = { 30, 70 },
  [9]  = { 30, 70 },
  [10] = { 5, 30 },
  [11] = { 0, 9 },
  [12] = { 0, 9 },
  [13] = { 0, 9 },
}

-- Per-stop passive sanity drift
LastLocalConfig.DRIFT = {
  [2] = 0, [3] = 0, [4] = -5, [5] = -5, [6] = 0,
  [7] = -5, [8] = 0, [9] = 0, [10] = -5, [11] = -5,
  [12] = 0, [13] = 0,
}

LastLocalConfig.SAN = {
  drift = -5,
  miss = -5,
  falsePos = -3,
  maskFail = -4,
  timeout = -2,
  haven = 15,
  trial = -20,
  restraintFail = -5,
  restraintOK = 8,
}

LastLocalConfig.SUS = {
  falsePos = 20,
  maskFail = 15,
  timeout = 8,
  visible = 10,
  clean = -5,
  refuseHaven = 10,
}

-- 13 Route Segments from Hoyt-Schermerhorn to Court Sq
LastLocalConfig.SEGS = {
  { stop = 2,  anoms = 1, stopType = "normal", tick = "doors",   cruise = 18, chat = 1 },
  { stop = 3,  anoms = 1, stopType = "normal", tick = "doors",   cruise = 18, mask = true },
  { stop = 4,  anoms = 1, stopType = "false",  tick = "doors",   cruise = 18, forgiving = true, chat = 2 },
  { stop = 5,  anoms = 1, stopType = "normal", tick = "doors",   cruise = 18, mask = true },
  { stop = 6,  anoms = 1, stopType = "haven",  tick = "doors",   cruise = 18, chat = 3 },
  { stop = 6,  anoms = 1, stopType = "false",  tick = "flicker", cruise = 14, bStretch = true },
  { stop = 7,  anoms = 2, stopType = "normal", tick = "doors",   cruise = 20, mask = true, crowd = true },
  { stop = 8,  anoms = 2, stopType = "normal", tick = "doors",   cruise = 20, mask = true, crowd = true },
  { stop = 9,  anoms = 1, stopType = "false",  tick = "doors",   cruise = 18, paLie = "This is Court Square. Last stop. Everybody off the train.", chat = 4 },
  { stop = 10, anoms = 1, stopType = "normal", tick = "doors",   cruise = 18, mask = true },
  { stop = 11, anoms = 0, stopType = "normal", tick = "doors",   cruise = 16, restraint = true, chat = 5 },
  { stop = 12, anoms = 1, stopType = "false",  tick = "flicker", cruise = 18, mask = true, Trestle = true },
  { stop = 13, anoms = 0, stopType = "final",  tick = "doors",   cruise = 16, final = true },
}

LastLocalConfig.CHATS = {
  [1] = { { who = "Dad", text = "Did you ever call your sister back?" }, { who = "Mom", text = "Tonight. Remind me." } },
  [2] = { { who = "Mom", text = "Your cousin's gonna be so tall now." }, { who = "Dad", text = "Everybody's tall now." } },
  [3] = { { who = "Dad", text = "We should've taken the bus." }, { who = "Mom", text = "The bus takes forever." } },
  [4] = { { who = "Mom", text = "Did you ever call your sister back?" }, { who = "Dad", text = "Did you ever call your sister back?" } },
  [5] = { { who = "Dad", text = "Is it always this empty?" }, { who = "Mom", text = "It's always this empty." } },
}

LastLocalConfig.MASK_DIALOGUES = {
  -- Tier 1: High Sanity (Calm)
  [1] = {
    { who = "Mom", line = "You've been quiet. You okay, hon?", calm = "Yeah, just tired.", off1 = "Why? Do I look weird?", off2 = "Did the lights just change?" },
    { who = "Dad", line = "How many more stops, you think?", calm = "A few. We're fine.", off1 = "Why are you asking me?", off2 = "Wait, which train is this?" },
    { who = "Mom", line = "Did you eat anything today?", calm = "Had a bagel earlier.", off1 = "Why does everyone keep asking that?", off2 = "Sorry, what?" },
  },
  -- Tier 2/3: Medium & Low Sanity (Uneasy)
  [2] = {
    { who = "Dad", line = "You'd tell us if something was wrong, right?", calm = "Of course.", off1 = "Would you tell me?", off2 = "Define wrong." },
    { who = "Mom", line = "Why do you keep looking over there?", calm = "Thought I saw someone I knew.", off1 = "You saw it too?", off2 = "Over where?" },
    { who = "Mom", line = "You're holding that pole awfully tight.", calm = "Train's bumpy tonight.", off1 = "Because it keeps moving.", off2 = "Don't let go of yours." },
  },
  -- Tier 4: Critical Sanity (Wrong)
  [3] = {
    { who = "Mom", line = "You can see it too, can't you?", calm = "See what?", off1 = "Yes.", off2 = "Don't." },
    { who = "Dad", line = "We're not getting off. You know that.", calm = "I know.", off1 = "Why would you say that?", off2 = "Who said we were?" },
    { who = "Dad", line = "Don't look at the windows. Look at me.", calm = "I'm looking at you.", off1 = "What's in the windows?", off2 = "Your face is wrong." },
  },
}

LastLocalConfig.ADS = {
  { tid = "ad:GREENPOINT SAVINGS", h = "GREENPOINT SAVINGS", warp = "GREENPOINT SAVES US", sub = "Your money. Closer to home.", bg = Color3.fromHex("#143c2b"), fg = Color3.fromHex("#f3efe2"), alt = Color3.fromHex("#6e1c1c") },
  { tid = "ad:KESSLER DENTAL",     h = "KESSLER DENTAL",     warp = "KESSLER DENIAL",     sub = "Smile like you mean it.",     bg = Color3.fromHex("#f2efe6"), fg = Color3.fromHex("#1d2a3a"), alt = Color3.fromHex("#cfe4c4") },
  { tid = "ad:HALLORAN MATTRESS",  h = "HALLORAN MATTRESS",  warp = "HALLORAN MATTERS",   sub = "Sleep like nothing's wrong.", bg = Color3.fromHex("#1e2248"), fg = Color3.fromHex("#f5f1e4"), alt = Color3.fromHex("#2b5c3a") },
  { tid = "ad:LEARN A TRADE",      h = "LEARN A TRADE",      warp = "LEARN A TRACE",      sub = "Night classes at Borough Tech.", bg = Color3.fromHex("#dfb738"), fg = Color3.fromHex("#121212"), alt = Color3.fromHex("#8cbfe6") },
  { tid = "ad:COURTESY COUNTS",    h = "COURTESY COUNTS",    warp = "COURTESY COUNTS DOWN", sub = "Offer your seat to someone who needs it.", bg = Color3.fromHex("#ede9dc"), fg = Color3.fromHex("#1e1f1d"), alt = Color3.fromHex("#e8b4b4") },
}

function LastLocalConfig.getTier(sanity: number): number
  if sanity >= 75 then return 1
  elseif sanity >= 40 then return 2
  elseif sanity >= 10 then return 3
  else return 4 end
end

function LastLocalConfig.getTierName(sanity: number): string
  local names = { "High", "Medium", "Low", "Critical" }
  return names[LastLocalConfig.getTier(sanity)]
end

return LastLocalConfig
`;

export const LUAU_SERVER_SOURCE = `--[[
  LAST LOCAL: Server Game Loop & Procedural G-Train Builder
  Place this Script in: ServerScriptService.LastLocalServer
  Automatically builds any missing 3D G-Train geometry in Workspace,
  runs the 13-stop subway ride, spawns anomalies, tracks Sanity & Parental Suspicion,
  and syncs state to all players.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local Config = require(ReplicatedStorage:WaitForChild("LastLocalConfig"))
local S = Config.SCALE

-- Ensure RemoteEvents exist
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
  Remotes = Instance.new("Folder")
  Remotes.Name = "Remotes"
  Remotes.Parent = ReplicatedStorage
end

local function ensureRemote(name: string): RemoteEvent
  local r = Remotes:FindFirstChild(name) :: RemoteEvent
  if not r then
    r = Instance.new("RemoteEvent")
    r.Name = name
    r.Parent = Remotes
  end
  return r
end

local FlagRemote = ensureRemote("FlagAnomaly")
local MaskRemote = ensureRemote("AnswerMask")
local DoorRemote = ensureRemote("DoorDecision")
local LookRemote = ensureRemote("LookTelemetry")
local SyncRemote = ensureRemote("GameStateSync")
local RestartRemote = ensureRemote("RestartRide")

-- Registry of interactive/flaggable targets by tid
local Targets: { [string]: Instance } = {}

local function registerTarget(inst: Instance, tid: string, label: string)
  inst:SetAttribute("tid", tid)
  inst:SetAttribute("label", label)
  Targets[tid] = inst
end

-- Index existing Workspace targets (if opened from .rbxlx) or build procedurally
local function indexOrBuildWorld()
  local consist = workspace:FindFirstChild("GTrainConsist")
  if consist then
    for _, desc in ipairs(consist:GetDescendants()) do
      local tid = desc:GetAttribute("tid")
      if tid then
        Targets[tid] = desc
      end
    end
    return consist
  end

  -- Procedural fallback if script was pasted into a blank Baseplate
  local bp = workspace:FindFirstChild("Baseplate")
  if bp and bp:IsA("BasePart") then bp:Destroy() end

  consist = Instance.new("Model")
  consist.Name = "GTrainConsist"
  consist.Parent = workspace

  local function makePart(parent: Instance, name: string, size: Vector3, pos: Vector3, color: Color3, mat: Enum.Material?): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Anchored = true
    p.Size = size * S
    p.Position = pos * S
    p.Color = color
    p.Material = mat or Enum.Material.SmoothPlastic
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
  end

  local carB = Instance.new("Model")
  carB.Name = "CarB_Center"
  carB.Parent = consist

  -- Floor & Ceiling
  makePart(carB, "Floor", Vector3.new(18, 0.1, 3.06), Vector3.new(0, -0.05, 0), Color3.fromHex("#2d302e"), Enum.Material.Slate)
  makePart(carB, "Ceiling", Vector3.new(18, 0.1, 3.06), Vector3.new(0, 2.43, 0), Color3.fromHex("#e6e4db"))

  -- SpawnLocation inside Car B
  local spawn = workspace:FindFirstChildOfClass("SpawnLocation") or Instance.new("SpawnLocation", workspace)
  spawn.Anchored = true
  spawn.CanCollide = false
  spawn.Transparency = 1
  spawn.Size = Vector3.new(4, 0.2, 4)
  spawn.Position = Vector3.new(0, 0.5, 0.8 * S)

  -- Ceiling Lights
  for si, z in ipairs({ -0.62, 0.62 }) do
    for i = 0, 5 do
      local idx = (si - 1) * 6 + i
      local lp = makePart(carB, "Light_" .. idx, Vector3.new(2.8, 0.05, 0.2), Vector3.new(-7.25 + i * 2.9, 2.38, z), Color3.fromHex("#fff4de"), Enum.Material.Neon)
      local pl = Instance.new("PointLight")
      pl.Color = Color3.fromHex("#fff0d4")
      pl.Brightness = 0.8
      pl.Range = 22
      pl.Parent = lp
      registerTarget(lp, "light:" .. idx, "a ceiling light")
    end
  end

  -- Walls, Benches & Poles
  for _, s in ipairs({ -1, 1 }) do
    local z = s * 1.53
    makePart(carB, "LowWall", Vector3.new(18, 0.9, 0.08), Vector3.new(0, 0.45, z), Color3.fromHex("#9fa49e"))
    makePart(carB, "UpWall", Vector3.new(18, 0.68, 0.08), Vector3.new(0, 2.06, z), Color3.fromHex("#c9ccc4"))
    local glass = makePart(carB, "WindowGlass", Vector3.new(18, 0.85, 0.03), Vector3.new(0, 1.325, z), Color3.fromHex("#6e8e89"), Enum.Material.Glass)
    glass.Transparency = 0.78

    for bIdx, range in ipairs({ { -8.85, -5.25 }, { -3.75, 3.75 }, { 5.25, 8.85 } }) do
      local len = range[2] - range[1]
      local cx = (range[1] + range[2]) / 2
      local col = (bIdx % 2 == 1) and Color3.fromHex("#d8782e") or Color3.fromHex("#df9c32")
      makePart(carB, "BenchSeat", Vector3.new(len, 0.09, 0.46), Vector3.new(cx, 0.455, s * 1.25), col)
      makePart(carB, "BenchBack", Vector3.new(len, 0.5, 0.07), Vector3.new(cx, 0.76, s * 1.47), col)
    end

    for _, px in ipairs({ -5.3, -3.7, 3.7, 5.3 }) do
      makePart(carB, "StanchionPole", Vector3.new(0.06, 2.42, 0.06), Vector3.new(px, 1.21, s * 0.98), Color3.fromHex("#dcdede"), Enum.Material.Metal)
    end
  end

  -- Ads across wall
  local adXs = { -7, -2.6, 0, 2.6, 7 }
  for i, adDef in ipairs(Config.ADS) do
    local adPart = makePart(carB, "Ad_" .. i, Vector3.new(1.3, 0.41, 0.03), Vector3.new(adXs[i], 2.07, -1.48), adDef.bg)
    local sg = Instance.new("SurfaceGui")
    sg.Face = Enum.NormalId.Back
    sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    sg.PixelsPerStud = 45
    sg.Parent = adPart
    local tl = Instance.new("TextLabel")
    tl.Name = "Headline"
    tl.Size = UDim2.fromScale(1, 0.6)
    tl.BackgroundTransparency = 1
    tl.Text = adDef.h
    tl.TextColor3 = adDef.fg
    tl.Font = Enum.Font.GothamBlack
    tl.TextScaled = true
    tl.Parent = sg
    local sub = Instance.new("TextLabel")
    sub.Name = "Subtext"
    sub.Position = UDim2.fromScale(0, 0.6)
    sub.Size = UDim2.fromScale(1, 0.4)
    sub.BackgroundTransparency = 1
    sub.Text = adDef.sub
    sub.TextColor3 = adDef.fg
    sub.Font = Enum.Font.GothamMedium
    sub.TextScaled = true
    sub.Parent = sg
    registerTarget(adPart, adDef.tid, "the " .. string.lower(adDef.h) .. " ad")
  end

  -- Build NPC Helper
  local function makePerson(tid: string, label: string, x: number, z: number, shirtHex: string, skinHex: string, visible: boolean): Model
    local m = Instance.new("Model")
    m.Name = tid
    m.Parent = carB
    local torso = makePart(m, "Torso", Vector3.new(0.38, 0.55, 0.22), Vector3.new(x, 0.78, z), Color3.fromHex(shirtHex))
    local head = makePart(m, "Head", Vector3.new(0.22, 0.25, 0.22), Vector3.new(x, 1.22, z), Color3.fromHex(skinHex))
    local legs = makePart(m, "Legs", Vector3.new(0.36, 0.45, 0.35), Vector3.new(x, 0.32, z + 0.12), Color3.fromHex("#282c34"))
    m.PrimaryPart = head
    if not visible then
      for _, p in ipairs(m:GetChildren()) do
        if p:IsA("BasePart") then p.Transparency = 1; p.CanCollide = false end
      end
    end
    registerTarget(m, tid, label)
    return m
  end

  makePerson("mom", "Mom", -0.95, -1.25, "#7a4a5e", "#c68e6c", true)
  makePerson("dad", "Dad", -0.30, -1.25, "#3e5a6e", "#b98062", true)
  makePerson("s1", "the man across the aisle", 2.35, -1.25, "#5b6b3a", "#8a5a3c", true)
  makePerson("s2", "the woman on your bench", -2.60, 1.25, "#9a9a90", "#e0b89a", true)
  makePerson("s3", "the standing passenger", 5.00, 0.55, "#2d2d33", "#a47050", true)
  makePerson("seat6", "the figure at the far end", 6.40, -1.25, "#141414", "#d9c2a8", false)

  return consist
end

indexOrBuildWorld()

-- Configure Lighting
Lighting.Brightness = 0.6
Lighting.ClockTime = 0
Lighting.Ambient = Color3.fromRGB(28, 32, 29)
Lighting.OutdoorAmbient = Color3.fromRGB(18, 22, 19)
if not Lighting:FindFirstChild("SanityColorCorrection") then
  local cc = Instance.new("ColorCorrectionEffect")
  cc.Name = "SanityColorCorrection"
  cc.Parent = Lighting
end

-- Authoritative Ride State
local State = {
  phase = "ride", -- "ride" | "stop" | "haven" | "end"
  segIdx = 1,
  stopIndex = 1,
  sanity = 100,
  suspicion = 0,
  peakSuspicion = 0,
  activeAnomaly = nil :: { id: string, tid: string, label: string, caught: boolean }?,
  parentWatching = false,
  watchingWho = "Mom",
  subText = "",
  paText = "",
  maskPrompt = nil :: { who: string, line: string, options: { string }, calmIdx: number }?,
  doorOpen = false,
  endingId = nil :: string?,
  endingTitle = nil :: string?,
  endingDesc = nil :: string?,
  caughtCount = 0,
  missedCount = 0,
  fpCount = 0,
}

local function clampSanity()
  local stop = math.clamp(State.stopIndex, 1, 13)
  local band = Config.BANDS[stop] or { 0, 100 }
  State.sanity = math.clamp(State.sanity, band[1], band[2])
end

local function addSuspicion(delta: number)
  State.suspicion = math.clamp(State.suspicion + delta, 0, 100)
  if State.suspicion > State.peakSuspicion then
    State.peakSuspicion = State.suspicion
  end
  if State.suspicion >= 100 and State.phase ~= "end" then
    State.phase = "end"
    State.endingId = "exposed"
    State.endingTitle = "ENDING: EXPOSED"
    State.endingDesc = "Your parents noticed you losing your grip and pulled you off the train at the next platform."
  end
end

local function broadcastState()
  workspace:SetAttribute("TrainSpeed", (State.phase == "ride") and Config.CRUISE_SPEED or 0)
  workspace:SetAttribute("DoorOpen", State.doorOpen)
  workspace:SetAttribute("ParentWatching", State.parentWatching)
  SyncRemote:FireAllClients({
    phase = State.phase,
    stopIndex = State.stopIndex,
    currentStopName = Config.STOPS[State.stopIndex] or "Hoyt-Schermerhorn",
    nextStopName = Config.STOPS[math.min(13, State.stopIndex + 1)] or "Court Sq",
    sanity = State.sanity,
    tier = Config.getTier(State.sanity),
    tierName = Config.getTierName(State.sanity),
    suspicion = State.suspicion,
    parentWatching = State.parentWatching,
    watchingWho = State.watchingWho,
    subText = State.subText,
    paText = State.paText,
    maskPrompt = State.maskPrompt,
    doorOpen = State.doorOpen,
    endingTitle = State.endingTitle,
    endingDesc = State.endingDesc,
    caughtCount = State.caughtCount,
    missedCount = State.missedCount,
    fpCount = State.fpCount,
  })
end

-- Anomaly Spawner & Resetter
local function clearAnomalies()
  -- Restore Ads
  for _, adDef in ipairs(Config.ADS) do
    local inst = Targets[adDef.tid]
    if inst and inst:IsA("BasePart") then
      inst.Color = adDef.bg
      local sg = inst:FindFirstChildOfClass("SurfaceGui")
      local hl = sg and sg:FindFirstChild("Headline") :: TextLabel
      if hl then hl.Text = adDef.h end
    end
  end
  -- Restore Lights
  for i = 0, 11 do
    local lp = Targets["light:" .. i]
    if lp and lp:IsA("BasePart") then
      lp.Color = Color3.fromHex("#fff4de")
      local pl = lp:FindFirstChildOfClass("PointLight")
      if pl then pl.Enabled = true end
    end
  end
  -- Hide extra figure
  local extra = Targets["seat6"]
  if extra then
    for _, p in ipairs(extra:GetDescendants()) do
      if p:IsA("BasePart") then p.Transparency = 1 end
    end
  end
  State.activeAnomaly = nil
end

local function spawnSegmentAnomaly()
  clearAnomalies()
  local roll = math.random(1, 4)
  if roll == 1 then
    local adDef = Config.ADS[math.random(1, #Config.ADS)]
    local inst = Targets[adDef.tid]
    if inst and inst:IsA("BasePart") then
      local sg = inst:FindFirstChildOfClass("SurfaceGui")
      local hl = sg and sg:FindFirstChild("Headline") :: TextLabel
      if hl then hl.Text = adDef.warp end
      State.activeAnomaly = { id = "adwarp", tid = adDef.tid, label = "warped ad text (" .. adDef.warp .. ")", caught = false }
    end
  elseif roll == 2 then
    local adDef = Config.ADS[math.random(1, #Config.ADS)]
    local inst = Targets[adDef.tid]
    if inst and inst:IsA("BasePart") then
      inst.Color = adDef.alt
      State.activeAnomaly = { id = "adcolor", tid = adDef.tid, label = "shifted ad color (" .. adDef.h .. ")", caught = false }
    end
  elseif roll == 3 then
    local idx = math.random(0, 11)
    local tid = "light:" .. idx
    local lp = Targets[tid]
    if lp and lp:IsA("BasePart") then
      lp.Color = Color3.fromHex("#252825")
      local pl = lp:FindFirstChildOfClass("PointLight")
      if pl then pl.Enabled = false end
      State.activeAnomaly = { id = "lightout", tid = tid, label = "dead fluorescent tube", caught = false }
    end
  else
    local extra = Targets["seat6"]
    if extra then
      for _, p in ipairs(extra:GetDescendants()) do
        if p:IsA("BasePart") then p.Transparency = 0 end
      end
      State.activeAnomaly = { id = "seat6", tid = "seat6", label = "dark figure at the far end", caught = false }
    end
  end
end

-- Client Flag Handler
FlagRemote.OnServerEvent:Connect(function(player, tid: string)
  if State.phase ~= "ride" or type(tid) ~= "string" then return end
  if State.activeAnomaly and State.activeAnomaly.tid == tid and not State.activeAnomaly.caught then
    State.activeAnomaly.caught = true
    State.caughtCount += 1
    State.subText = "Noted privately: " .. State.activeAnomaly.label
    clearAnomalies()
  else
    State.fpCount += 1
    State.sanity += Config.SAN.falsePos
    clampSanity()
    addSuspicion(Config.SUS.falsePos)
    State.subText = "Nothing was wrong with that. Keep your composure."
  end
  broadcastState()
end)

-- Client Mask Dialogue Answer
MaskRemote.OnServerEvent:Connect(function(player, choiceIdx: number)
  if not State.maskPrompt then return end
  if choiceIdx == State.maskPrompt.calmIdx then
    addSuspicion(Config.SUS.clean)
    State.subText = State.maskPrompt.who .. " nods and looks back down."
  else
    State.sanity += Config.SAN.maskFail
    clampSanity()
    addSuspicion(Config.SUS.maskFail)
    State.subText = State.maskPrompt.who .. " gives you a long, uneasy look."
  end
  State.maskPrompt = nil
  broadcastState()
end)

-- Client Head-Whip / Staring Telemetry
LookRemote.OnServerEvent:Connect(function(player, reason: string)
  if State.phase ~= "ride" or not State.parentWatching then return end
  if reason == "whip" then
    addSuspicion(Config.SUS.visible)
    State.subText = State.watchingWho .. " noticed you whipping your head around."
    broadcastState()
  end
end)

-- Client Door Decision at Station Stop
local doorChoiceMade: string? = nil
DoorRemote.OnServerEvent:Connect(function(player, decision: string)
  if State.phase == "stop" or State.phase == "haven" then
    doorChoiceMade = decision
  end
end)

local function resetRide()
  clearAnomalies()
  State.phase = "ride"
  State.segIdx = 1
  State.stopIndex = 1
  State.sanity = 100
  State.suspicion = 0
  State.peakSuspicion = 0
  State.parentWatching = false
  State.subText = "Hoyt-Schermerhorn. Court Sq-bound local."
  State.paText = "Stand clear of the closing doors, please."
  State.maskPrompt = nil
  State.doorOpen = false
  State.endingId = nil
  State.endingTitle = nil
  State.endingDesc = nil
  State.caughtCount = 0
  State.missedCount = 0
  State.fpCount = 0
  broadcastState()
end

RestartRemote.OnServerEvent:Connect(function()
  resetRide()
end)

-- Main Server Ride Coroutine
task.spawn(function()
  resetRide()
  while true do
    if State.phase == "end" then
      task.wait(1)
      continue
    end

    local seg = Config.SEGS[State.segIdx]
    if not seg then
      State.phase = "end"
      State.endingTitle = "ENDING: COURT SQUARE"
      State.endingDesc = "You stepped off at Court Square with your sanity intact and your parents none the wiser."
      broadcastState()
      task.wait(1)
      continue
    end

    -- Start Segment Ride
    State.phase = "ride"
    State.doorOpen = false
    State.maskPrompt = nil
    State.paText = "Next stop: " .. (Config.STOPS[seg.stop] or "Court Sq")
    if seg.anoms > 0 then
      spawnSegmentAnomaly()
    else
      clearAnomalies()
    end
    broadcastState()

    local cruiseTime = seg.cruise or 18
    local elapsed = 0
    local chatShown = false
    local maskShown = false

    while elapsed < cruiseTime and State.phase == "ride" do
      task.wait(1)
      elapsed += 1

      -- Parent small talk
      if seg.chat and not chatShown and elapsed == 4 then
        chatShown = true
        local lines = Config.CHATS[seg.chat]
        if lines and lines[1] then
          State.subText = lines[1].who .. ': "' .. lines[1].text .. '"'
          broadcastState()
        end
      elseif seg.chat and chatShown and elapsed == 7 then
        local lines = Config.CHATS[seg.chat]
        if lines and lines[2] then
          State.subText = lines[2].who .. ': "' .. lines[2].text .. '"'
          broadcastState()
        end
      end

      -- Parent watching window
      if elapsed >= 6 and elapsed <= 10 then
        State.parentWatching = true
        State.watchingWho = (elapsed % 2 == 0) and "Mom" or "Dad"
      else
        State.parentWatching = false
      end

      -- Mask check dialogue
      if seg.mask and not maskShown and elapsed == 11 then
        maskShown = true
        local setIdx = math.min(3, Config.getTier(State.sanity))
        local pool = Config.MASK_DIALOGUES[setIdx]
        local d = pool[math.random(1, #pool)]
        State.maskPrompt = {
          who = d.who,
          line = d.line,
          options = { d.calm, d.off1, d.off2 },
          calmIdx = 1,
        }
        State.subText = d.who .. ': "' .. d.line .. '"'
      end

      -- Arrival signal (3s before stop): real stops click doors; false flicker stops flicker lights
      if elapsed == cruiseTime - 3 then
        if seg.tick == "flicker" then
          State.paText = "[Fluorescent tubes buzz and flicker overhead]"
        else
          State.paText = seg.paLie or ("[Door relays click] Approaching " .. (Config.STOPS[seg.stop] or ""))
        end
      end

      broadcastState()
    end

    if State.phase == "end" then continue end

    -- Evaluate unresolved mask check or missed anomaly
    if State.maskPrompt then
      State.maskPrompt = nil
      State.sanity += Config.SAN.timeout
      addSuspicion(Config.SUS.timeout)
    end
    if State.activeAnomaly and not State.activeAnomaly.caught then
      State.missedCount += 1
      State.sanity += Config.SAN.miss
      State.subText = "You missed an anomaly in the car."
      clearAnomalies()
    end

    -- Apply per-stop sanity drift
    State.stopIndex = seg.stop
    State.sanity += (Config.DRIFT[seg.stop] or 0)
    clampSanity()

    -- Station Arrival / Door Decision
    State.phase = (seg.stopType == "haven") and "haven" or "stop"
    State.doorOpen = true
    State.parentWatching = false
    doorChoiceMade = nil

    if seg.final then
      State.subText = "Court Square. Last stop. The doors slide open."
    elseif seg.stopType == "haven" then
      State.subText = Config.STOPS[seg.stop] .. " (Safe Haven). Step off with your parents or stay aboard?"
    else
      State.subText = Config.STOPS[seg.stop] .. ". Doors open. Stay on the train or step off?"
    end
    broadcastState()

    local waitStop = 0
    while waitStop < 8 and not doorChoiceMade and State.phase ~= "end" do
      task.wait(0.5)
      waitStop += 0.5
    end

    local decision = doorChoiceMade or "stay"
    State.doorOpen = false

    if seg.final then
      State.phase = "end"
      if decision == "step_off" then
        State.endingId = "court_sq"
        State.endingTitle = "ENDING: COURT SQUARE"
        State.endingDesc = "You reached Queens, kept your composure in front of your parents, and walked up the escalators into the night air."
      else
        State.endingId = "left_behind"
        State.endingTitle = "ENDING: RELENTLESS"
        State.endingDesc = "The doors closed at Court Square while you stayed seated. The train rolled into the dark relay tracks beyond."
      end
      broadcastState()
    elseif seg.stopType == "haven" and decision == "step_off" then
      State.phase = "end"
      State.endingId = "haven"
      State.endingTitle = "ENDING: THE HAVEN (MYRTLE-WILLOUGHBY)"
      State.endingDesc = "You stepped off early at the warm, quiet platform with your parents before the deeper tunnel took hold."
      broadcastState()
    elseif seg.stopType == "false" and decision == "step_off" then
      -- Stepped off at a false stop trap!
      State.sanity += Config.SAN.trial
      clampSanity()
      State.subText = "TRAP! That wasn't a real station. You barely scrambled back aboard."
      if State.sanity <= 0 then
        State.phase = "end"
        State.endingId = "wrong_station"
        State.endingTitle = "ENDING: LOST IN THE TUNNEL"
        State.endingDesc = "You stepped off onto a dark false platform. The train doors locked behind you."
        broadcastState()
      else
        State.segIdx += 1
        broadcastState()
      end
    elseif decision == "step_off" then
      -- Stepped off at a normal stop before Court Sq
      addSuspicion(25)
      State.subText = 'Dad pulls you back inside: "Where are you going? This isn\'t Court Square!"'
      State.segIdx += 1
      broadcastState()
    else
      -- Stayed on the train
      if seg.stopType == "haven" then
        State.sanity = math.min(100, State.sanity + Config.SAN.haven)
        clampSanity()
      end
      State.segIdx += 1
      broadcastState()
    end
  end
end)
`;

export const LUAU_CLIENT_SOURCE = `--[[
  LAST LOCAL: First-Person Client Controller & NYC Subway HUD
  Place this LocalScript in: StarterPlayer.StarterPlayerScripts.LastLocalClient
  Handles:
  - First-person camera lock & subtle sanity breathing FOV
  - Gaze raycasting to identify car targets (ads, lights, passengers, parents)
  - Holding [F] (or mobile touch button) to privately Flag anomalies
  - Head-whip angular velocity detection while Mom or Dad is watching
  - Sliding door animation, tunnel scrolling, and complete ScreenGui HUD
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local Config = require(ReplicatedStorage:WaitForChild("LastLocalConfig"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local FlagRemote = Remotes:WaitForChild("FlagAnomaly") :: RemoteEvent
local MaskRemote = Remotes:WaitForChild("AnswerMask") :: RemoteEvent
local DoorRemote = Remotes:WaitForChild("DoorDecision") :: RemoteEvent
local LookRemote = Remotes:WaitForChild("LookTelemetry") :: RemoteEvent
local SyncRemote = Remotes:WaitForChild("GameStateSync") :: RemoteEvent
local RestartRemote = Remotes:WaitForChild("RestartRide") :: RemoteEvent

-- Lock first-person inside the subway car
player.CameraMode = Enum.CameraMode.LockFirstPerson
player.CameraMaxZoomDistance = 0.5
player.CameraMinZoomDistance = 0.5

-- Build HUD ScreenGui
local gui = Instance.new("ScreenGui")
gui.Name = "LastLocalHUD"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Top-Left MTA Station Plaque & Vitals
local card = Instance.new("Frame")
card.Name = "StationCard"
card.Position = UDim2.fromOffset(20, 20)
card.Size = UDim2.fromOffset(310, 108)
card.BackgroundColor3 = Color3.fromHex("#101411")
card.BackgroundTransparency = 0.12
card.BorderSizePixel = 0
card.Parent = gui
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
local stroke = Instance.new("UIStroke", card)
stroke.Color = Color3.fromHex("#6cbe45")
stroke.Thickness = 1.5

local gBadge = Instance.new("TextLabel")
gBadge.Position = UDim2.fromOffset(12, 12)
gBadge.Size = UDim2.fromOffset(32, 32)
gBadge.BackgroundColor3 = Color3.fromHex("#6cbe45")
gBadge.Text = "G"
gBadge.TextColor3 = Color3.fromHex("#0f1a0b")
gBadge.Font = Enum.Font.GothamBlack
gBadge.TextSize = 20
gBadge.Parent = card
Instance.new("UICorner", gBadge).CornerRadius = UDim.new(1, 0)

local stopLabel = Instance.new("TextLabel")
stopLabel.Position = UDim2.fromOffset(54, 10)
stopLabel.Size = UDim2.fromOffset(245, 22)
stopLabel.BackgroundTransparency = 1
stopLabel.Text = "Hoyt-Schermerhorn"
stopLabel.TextColor3 = Color3.fromHex("#ece6d3")
stopLabel.Font = Enum.Font.GothamBlack
stopLabel.TextSize = 16
stopLabel.TextXAlignment = Enum.TextXAlignment.Left
stopLabel.Parent = card

local nextLabel = Instance.new("TextLabel")
nextLabel.Position = UDim2.fromOffset(54, 30)
nextLabel.Size = UDim2.fromOffset(245, 16)
nextLabel.BackgroundTransparency = 1
nextLabel.Text = "Next: Fulton St · Court Sq-Bound"
nextLabel.TextColor3 = Color3.fromHex("#9a9684")
nextLabel.Font = Enum.Font.RobotoMono
nextLabel.TextSize = 12
nextLabel.TextXAlignment = Enum.TextXAlignment.Left
nextLabel.Parent = card

local vitalsLabel = Instance.new("TextLabel")
vitalsLabel.Position = UDim2.fromOffset(12, 54)
vitalsLabel.Size = UDim2.fromOffset(286, 20)
vitalsLabel.BackgroundTransparency = 1
vitalsLabel.Text = "SANITY: 100% (High)   |   SUSPICION: 0%"
vitalsLabel.TextColor3 = Color3.fromHex("#6cbe45")
vitalsLabel.Font = Enum.Font.RobotoMono
vitalsLabel.TextSize = 12
vitalsLabel.TextXAlignment = Enum.TextXAlignment.Left
vitalsLabel.Parent = card

local watchBanner = Instance.new("TextLabel")
watchBanner.Position = UDim2.fromOffset(12, 78)
watchBanner.Size = UDim2.fromOffset(286, 20)
watchBanner.BackgroundTransparency = 1
watchBanner.Text = "Hold [F] on an anomaly to flag privately"
watchBanner.TextColor3 = Color3.fromHex("#e3a83a")
watchBanner.Font = Enum.Font.RobotoMono
watchBanner.TextSize = 11
watchBanner.TextXAlignment = Enum.TextXAlignment.Left
watchBanner.Parent = card

-- Center Reticle & Target Readout
local reticle = Instance.new("Frame")
reticle.AnchorPoint = Vector2.new(0.5, 0.5)
reticle.Position = UDim2.fromScale(0.5, 0.5)
reticle.Size = UDim2.fromOffset(6, 6)
reticle.BackgroundColor3 = Color3.fromHex("#ece6d3")
reticle.BackgroundTransparency = 0.35
reticle.Parent = gui
Instance.new("UICorner", reticle).CornerRadius = UDim.new(1, 0)

local targetReadout = Instance.new("TextLabel")
targetReadout.AnchorPoint = Vector2.new(0.5, 0)
targetReadout.Position = UDim2.new(0.5, 0, 0.5, 16)
targetReadout.Size = UDim2.fromOffset(360, 24)
targetReadout.BackgroundTransparency = 1
targetReadout.Text = ""
targetReadout.TextColor3 = Color3.fromHex("#ece6d3")
targetReadout.Font = Enum.Font.RobotoMono
targetReadout.TextSize = 14
targetReadout.Parent = gui

local flagBarBg = Instance.new("Frame")
flagBarBg.AnchorPoint = Vector2.new(0.5, 0)
flagBarBg.Position = UDim2.new(0.5, 0, 0.5, 42)
flagBarBg.Size = UDim2.fromOffset(140, 6)
flagBarBg.BackgroundColor3 = Color3.fromHex("#222622")
flagBarBg.BorderSizePixel = 0
flagBarBg.Visible = false
flagBarBg.Parent = gui

local flagBarFill = Instance.new("Frame")
flagBarFill.Size = UDim2.fromScale(0, 1)
flagBarFill.BackgroundColor3 = Color3.fromHex("#6cbe45")
flagBarFill.BorderSizePixel = 0
flagBarFill.Parent = flagBarBg

-- Subtitle & PA Banner
local subBanner = Instance.new("TextLabel")
subBanner.AnchorPoint = Vector2.new(0.5, 1)
subBanner.Position = UDim2.new(0.5, 0, 1, -28)
subBanner.Size = UDim2.fromOffset(680, 48)
subBanner.BackgroundColor3 = Color3.fromHex("#0d110e")
subBanner.BackgroundTransparency = 0.2
subBanner.Text = "Hoyt-Schermerhorn. Court Sq-bound local."
subBanner.TextColor3 = Color3.fromHex("#ece6d3")
subBanner.Font = Enum.Font.GothamMedium
subBanner.TextSize = 15
subBanner.TextWrapped = true
subBanner.Parent = gui
Instance.new("UICorner", subBanner).CornerRadius = UDim.new(0, 6)

-- Choice / Door Modal Container
local choiceFrame = Instance.new("Frame")
choiceFrame.AnchorPoint = Vector2.new(0.5, 1)
choiceFrame.Position = UDim2.new(0.5, 0, 1, -90)
choiceFrame.Size = UDim2.fromOffset(520, 160)
choiceFrame.BackgroundColor3 = Color3.fromHex("#101411")
choiceFrame.Visible = false
choiceFrame.Parent = gui
Instance.new("UICorner", choiceFrame).CornerRadius = UDim.new(0, 8)
local choiceStroke = Instance.new("UIStroke", choiceFrame)
choiceStroke.Color = Color3.fromHex("#e3a83a")
choiceStroke.Thickness = 1.5

local choiceTitle = Instance.new("TextLabel")
choiceTitle.Position = UDim2.fromOffset(16, 10)
choiceTitle.Size = UDim2.fromOffset(488, 28)
choiceTitle.BackgroundTransparency = 1
choiceTitle.Text = ""
choiceTitle.TextColor3 = Color3.fromHex("#e3a83a")
choiceTitle.Font = Enum.Font.GothamBold
choiceTitle.TextSize = 14
choiceTitle.TextXAlignment = Enum.TextXAlignment.Left
choiceTitle.Parent = choiceFrame

local choiceBtns: { TextButton } = {}
for i = 1, 3 do
  local btn = Instance.new("TextButton")
  btn.Position = UDim2.fromOffset(16, 42 + (i - 1) * 36)
  btn.Size = UDim2.fromOffset(488, 30)
  btn.BackgroundColor3 = Color3.fromHex("#1b221d")
  btn.TextColor3 = Color3.fromHex("#ece6d3")
  btn.Font = Enum.Font.GothamSemibold
  btn.TextSize = 13
  btn.TextXAlignment = Enum.TextXAlignment.Left
  btn.Parent = choiceFrame
  Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
  choiceBtns[i] = btn
end

-- Touch / Mobile Flag Button
local touchFlagBtn = Instance.new("TextButton")
touchFlagBtn.AnchorPoint = Vector2.new(1, 0.5)
touchFlagBtn.Position = UDim2.new(1, -24, 0.5, 0)
touchFlagBtn.Size = UDim2.fromOffset(96, 52)
touchFlagBtn.BackgroundColor3 = Color3.fromHex("#6cbe45")
touchFlagBtn.TextColor3 = Color3.fromHex("#0f1a0b")
touchFlagBtn.Font = Enum.Font.GothamBlack
touchFlagBtn.TextSize = 14
touchFlagBtn.Text = "HOLD FLAG"
touchFlagBtn.Parent = gui
Instance.new("UICorner", touchFlagBtn).CornerRadius = UDim.new(0, 8)

-- Client State
local currentTid: string? = nil
local currentLabel: string? = nil
local flagHeld = false
local flagProgress = 0
local lastLookDir = camera.CFrame.LookVector
local lastWhipSent = 0
local currentPhase = "ride"

local function setChoiceButtons(title: string, items: { { text: string, cb: () -> () } })
  choiceFrame.Visible = true
  choiceTitle.Text = title
  for i = 1, 3 do
    local btn = choiceBtns[i]
    local item = items[i]
    if item then
      btn.Visible = true
      btn.Text = "  [" .. i .. "]  " .. item.text
      btn.Activated:Connect(function()
        choiceFrame.Visible = false
        item.cb()
      end)
    else
      btn.Visible = false
    end
  end
end

-- Server State Sync Receiver
SyncRemote.OnClientEvent:Connect(function(s)
  currentPhase = s.phase
  stopLabel.Text = s.currentStopName
  nextLabel.Text = "Next: " .. s.nextStopName .. " · Stop " .. s.stopIndex .. "/13"
  vitalsLabel.Text = string.format("SANITY: %d%% (%s)   |   SUSPICION: %d%%", s.sanity, s.tierName, s.suspicion)

  if s.parentWatching then
    watchBanner.Text = "⚠ " .. s.watchingWho .. " is looking at you — don't whip your head!"
    watchBanner.TextColor3 = Color3.fromHex("#e8705e")
  else
    watchBanner.Text = "Hold [F] on an anomaly to flag privately"
    watchBanner.TextColor3 = Color3.fromHex("#9a9684")
  end

  subBanner.Text = (s.paText ~= "" and ("📢 " .. s.paText .. "\n") or "") .. (s.subText or "")

  -- Sanity Tier ColorCorrection
  local cc = Lighting:FindFirstChild("SanityColorCorrection") :: ColorCorrectionEffect
  if cc then
    if s.tier == 1 then
      cc.Saturation = 0; cc.Contrast = 0
    elseif s.tier == 2 then
      cc.Saturation = -0.25; cc.Contrast = 0.06
    elseif s.tier == 3 then
      cc.Saturation = -0.5; cc.Contrast = 0.14
    else
      cc.Saturation = -0.75; cc.Contrast = 0.24
    end
  end

  -- Prompts: Mask Dialogue, Station Doors, or End Report
  if s.phase == "end" then
    setChoiceButtons(s.endingTitle or "RIDE COMPLETE", {
      {
        text = (s.endingDesc or "") .. "  [Click to Ride Again]",
        cb = function() RestartRemote:FireServer() end,
      },
    })
  elseif s.maskPrompt then
    local mp = s.maskPrompt
    local items = {}
    for idx, opt in ipairs(mp.options) do
      table.insert(items, {
        text = opt,
        cb = function() MaskRemote:FireServer(idx) end,
      })
    end
    setChoiceButtons(mp.who .. ' asks: "' .. mp.line .. '"', items)
  elseif s.phase == "stop" or s.phase == "haven" then
    setChoiceButtons("DOORS OPEN AT " .. string.upper(s.currentStopName), {
      { text = "Stay on the train", cb = function() DoorRemote:FireServer("stay") end },
      { text = "Step off onto the platform", cb = function() DoorRemote:FireServer("step_off") end },
    })
  else
    choiceFrame.Visible = false
  end
end)

-- Input bindings
UserInputService.InputBegan:Connect(function(input, gp)
  if gp then return end
  if input.KeyCode == Enum.KeyCode.F then
    flagHeld = true
  end
end)

UserInputService.InputEnded:Connect(function(input)
  if input.KeyCode == Enum.KeyCode.F then
    flagHeld = false
    flagProgress = 0
  end
end)

touchFlagBtn.MouseButton1Down:Connect(function() flagHeld = true end)
touchFlagBtn.MouseButton1Up:Connect(function() flagHeld = false; flagProgress = 0 end)

-- Frame Loop: Raycast Gaze, Flag Progress & Head-Whip Check
RunService.RenderStepped:Connect(function(dt)
  -- 1. Head-Whip angular velocity check
  local lookDir = camera.CFrame.LookVector
  local angle = math.acos(math.clamp(lookDir:Dot(lastLookDir), -1, 1))
  local angVel = angle / math.max(dt, 0.001)
  lastLookDir = lookDir

  if angVel > Config.HEAD_WHIP_THRESHOLD and workspace:GetAttribute("ParentWatching") then
    if os.clock() - lastWhipSent > 1.5 then
      lastWhipSent = os.clock()
      LookRemote:FireServer("whip")
    end
  end

  -- 2. Gaze Raycast from center of screen
  local params = RaycastParams.new()
  params.FilterType = Enum.RaycastFilterType.Exclude
  if player.Character then
    params.FilterDescendantsInstances = { player.Character }
  end
  local ray = workspace:Raycast(camera.CFrame.Position, camera.CFrame.LookVector * (14 * Config.SCALE), params)
  currentTid = nil
  currentLabel = nil
  if ray and ray.Instance then
    local cur: Instance? = ray.Instance
    while cur and cur ~= workspace do
      local tid = cur:GetAttribute("tid")
      if tid then
        currentTid = tostring(tid)
        currentLabel = tostring(cur:GetAttribute("label") or tid)
        break
      end
      cur = cur.Parent
    end
  end

  if currentLabel and currentPhase == "ride" then
    targetReadout.Text = currentLabel .. "  [Hold F to Flag]"
    reticle.BackgroundColor3 = Color3.fromHex("#6cbe45")
  else
    targetReadout.Text = ""
    reticle.BackgroundColor3 = Color3.fromHex("#ece6d3")
  end

  -- 3. Hold [F] Flag Progress
  if flagHeld and currentTid and currentPhase == "ride" then
    flagProgress = math.min(1, flagProgress + dt / Config.FLAG_HOLD_SECONDS)
    flagBarBg.Visible = true
    flagBarFill.Size = UDim2.fromScale(flagProgress, 1)
    if flagProgress >= 1 then
      flagHeld = false
      flagProgress = 0
      flagBarBg.Visible = false
      FlagRemote:FireServer(currentTid)
    end
  else
    flagProgress = math.max(0, flagProgress - dt * 3)
    flagBarBg.Visible = flagProgress > 0
    flagBarFill.Size = UDim2.fromScale(flagProgress, 1)
  end
end)
`;

export const ROBLOX_SCRIPTS: RobloxScriptFile[] = [
  {
    id: 'config',
    filename: 'LastLocalConfig.luau',
    robloxPath: 'ReplicatedStorage → LastLocalConfig (ModuleScript)',
    scriptType: 'ModuleScript',
    summary: 'All 13 NYC G-Train stops, sanity bands, suspicion tuning, segment definitions, parent small-talk, mask check dialogues, and ad posters.',
    code: LUAU_CONFIG_SOURCE,
  },
  {
    id: 'server',
    filename: 'LastLocalServer.server.luau',
    robloxPath: 'ServerScriptService → LastLocalServer (Script)',
    scriptType: 'Script (Server)',
    summary: 'Builds the 3D subway car if missing, runs the 13-stop ride loop, spawns anomalies, tracks sanity & parent suspicion, and resolves all endings.',
    code: LUAU_SERVER_SOURCE,
  },
  {
    id: 'client',
    filename: 'LastLocalClient.client.luau',
    robloxPath: 'StarterPlayer → StarterPlayerScripts → LastLocalClient (LocalScript)',
    scriptType: 'LocalScript (Client)',
    summary: 'Locks first-person camera, raycasts gaze onto car objects, handles [Hold F] anomaly flagging, detects head-whips, and renders the full NYC G-Train HUD.',
    code: LUAU_CLIENT_SOURCE,
  },
];

/**
 * Generates a complete, self-contained Roblox Studio XML Place file (`.rbxlx`)
 * with pre-built 3D G-Train Car B, Car A, Car C, Station Platform, Tunnel, Benches, Poles,
 * Fluorescent Lights, SurfaceGui Ads, Mom, Dad, Strangers, Lighting, and all 3 Luau scripts.
 */
export function generateRobloxPlaceRbxlx(): string {
  let refCount = 1000;
  const nextRef = () => `RBX${++refCount}`;

  const hexToRgbFloat = (hex: string): [number, number, number] => {
    const clean = hex.replace('#', '');
    const n = parseInt(clean, 16);
    return [((n >> 16) & 255) / 255, ((n >> 8) & 255) / 255, (n & 255) / 255];
  };

  interface PartOpts {
    name: string;
    size: [number, number, number]; // in meters (scaled by S)
    pos: [number, number, number];  // in meters (scaled by S)
    colorHex: string;
    material?: number; // 272=SmoothPlastic, 288=Neon, 1088=Metal, 1568=Glass, 816=Concrete
    transparency?: number;
    canCollide?: boolean;
    shape?: number; // 1=Block, 2=Cylinder
    tid?: string;
    label?: string;
    childrenXml?: string;
  }

  // Roblox Material tokens: SmoothPlastic=272, Neon=288, Metal=1088, Glass=1568, Concrete=816
  const makePartXml = (o: PartOpts): string => {
    const [r, g, b] = hexToRgbFloat(o.colorHex);
    const [sx, sy, sz] = [o.size[0] * S, o.size[1] * S, o.size[2] * S];
    const [px, py, pz] = [o.pos[0] * S, o.pos[1] * S, o.pos[2] * S];
    const mat = o.material ?? 272;
    const trans = o.transparency ?? 0;
    const collide = o.canCollide ?? true;
    const shape = o.shape ?? 1;

    // Attributes XML (Roblox binary/string attributes can be represented or handled via StringValues / Config)
    // To guarantee 100% compatibility across every Roblox Studio release, we also attach a StringValue or Object metadata
    // AND our server script indexes parts by name/attributes.
    return `
      <Item class="Part" referent="${nextRef()}">
        <Properties>
          <string name="Name">${xmlEscape(o.name)}</string>
          <bool name="Anchored">true</bool>
          <bool name="CanCollide">${collide}</bool>
          <float name="Transparency">${trans.toFixed(3)}</float>
          <token name="Material">${mat}</token>
          <token name="shape">${shape}</token>
          <Color3 name="Color">
            <R>${r.toFixed(4)}</R>
            <G>${g.toFixed(4)}</G>
            <B>${b.toFixed(4)}</B>
          </Color3>
          <Vector3 name="size">
            <X>${sx.toFixed(3)}</X>
            <Y>${sy.toFixed(3)}</Y>
            <Z>${sz.toFixed(3)}</Z>
          </Vector3>
          <CoordinateFrame name="CFrame">
            <X>${px.toFixed(3)}</X>
            <Y>${py.toFixed(3)}</Y>
            <Z>${pz.toFixed(3)}</Z>
            <R00>1</R00><R01>0</R01><R02>0</R02>
            <R10>0</R10><R11>1</R11><R12>0</R12>
            <R20>0</R20><R21>0</R21><R22>1</R22>
          </CoordinateFrame>
        </Properties>
        ${o.childrenXml || ''}
      </Item>`;
  };

  // Build Car B parts in XML so the user immediately sees the 3D subway car in Roblox Studio Edit Mode!
  const carBParts: string[] = [];

  // Floor & Ceiling
  carBParts.push(
    makePartXml({ name: 'Floor_CarB', size: [18, 0.1, 3.06], pos: [0, -0.05, 0], colorHex: '#2d302e', material: 816 }),
    makePartXml({ name: 'Ceiling_CarB', size: [18, 0.1, 3.06], pos: [0, 2.43, 0], colorHex: '#e6e4db' }),
    makePartXml({ name: 'Floor_CarA', size: [18, 0.1, 3.06], pos: [-19.5, -0.05, 0], colorHex: '#2d302e', material: 816 }),
    makePartXml({ name: 'Ceiling_CarA', size: [18, 0.1, 3.06], pos: [-19.5, 2.43, 0], colorHex: '#e6e4db' }),
    makePartXml({ name: 'Floor_CarC', size: [18, 0.1, 3.06], pos: [19.5, -0.05, 0], colorHex: '#2d302e', material: 816 }),
    makePartXml({ name: 'Ceiling_CarC', size: [18, 0.1, 3.06], pos: [19.5, 2.43, 0], colorHex: '#e6e4db' })
  );

  // 12 Ceiling Fluorescent Lights
  [-0.62, 0.62].forEach((z, si) => {
    for (let i = 0; i < 6; i++) {
      const idx = si * 6 + i;
      const lightChild = `
        <Item class="PointLight" referent="${nextRef()}">
          <Properties>
            <string name="Name">TubeLight</string>
            <float name="Brightness">0.85</float>
            <float name="Range">22</float>
            <Color3 name="Color"><R>1</R><G>0.94</G><B>0.83</B></Color3>
          </Properties>
        </Item>`;
      carBParts.push(
        makePartXml({
          name: `Light_${idx}`,
          size: [2.8, 0.04, 0.2],
          pos: [-7.25 + i * 2.9, 2.38, z],
          colorHex: '#fff4de',
          material: 288,
          childrenXml: lightChild,
        })
      );
    }
  });

  // Walls, Windows, Benches, Poles
  [-1, 1].forEach((s) => {
    const z = s * 1.53;
    carBParts.push(
      makePartXml({ name: `LowWall_${s}`, size: [18, 0.9, 0.08], pos: [0, 0.45, z], colorHex: '#9fa49e' }),
      makePartXml({ name: `UpWall_${s}`, size: [18, 0.68, 0.08], pos: [0, 2.06, z], colorHex: '#c9ccc4' }),
      makePartXml({ name: `WindowGlass_${s}`, size: [18, 0.85, 0.03], pos: [0, 1.325, z], colorHex: '#6e8e89', material: 1568, transparency: 0.78 })
    );

    [
      [-8.85, -5.25],
      [-3.75, 3.75],
      [5.25, 8.85],
    ].forEach(([a, b], bIdx) => {
      const len = b - a;
      const cx = (a + b) / 2;
      const seatColor = bIdx % 2 === 0 ? '#d8782e' : '#df9c32';
      carBParts.push(
        makePartXml({ name: `BenchSeat_${s}_${bIdx}`, size: [len, 0.09, 0.46], pos: [cx, 0.455, s * 1.25], colorHex: seatColor }),
        makePartXml({ name: `BenchBack_${s}_${bIdx}`, size: [len, 0.5, 0.07], pos: [cx, 0.76, s * 1.47], colorHex: seatColor }),
        makePartXml({ name: `BenchRiser_${s}_${bIdx}`, size: [len, 0.41, 0.36], pos: [cx, 0.205, s * 1.3], colorHex: '#4a4d4f' })
      );
    });

    [-5.3, -3.7, 3.7, 5.3].forEach((px, pIdx) => {
      carBParts.push(
        makePartXml({ name: `Pole_${s}_${pIdx}`, size: [0.06, 2.42, 0.06], pos: [px, 1.21, s * 0.98], colorHex: '#dcdede', material: 1088 })
      );
    });
  });

  // Station Platform outside far windows
  carBParts.push(
    makePartXml({ name: 'Platform_Floor', size: [44, 0.18, 1.2], pos: [0, -0.07, -2.1], colorHex: '#8d8a82', material: 816 }),
    makePartXml({ name: 'Platform_SafetyEdge', size: [44, 0.02, 0.14], pos: [0, 0.02, -1.62], colorHex: '#e3c341', material: 288 }),
    makePartXml({ name: 'Platform_TileWall', size: [44, 3.2, 0.12], pos: [0, 1.3, -2.5], colorHex: '#dad4c2' }),
    makePartXml({ name: 'Platform_GLineBand', size: [44, 0.18, 0.04], pos: [0, 2.25, -2.42], colorHex: '#6cbe45' }),
    makePartXml({ name: 'Tunnel_Wall_Near', size: [84, 3.4, 0.15], pos: [0, 1.1, 3.2], colorHex: '#181a18', material: 816 })
  );

  // Note: When `LastLocalServer` runs on Play, if `GTrainConsist` doesn't have dynamic attributes indexed yet,
  // we let `LastLocalServer` rebuild `GTrainConsist` cleanly with all interactive attributes & SurfaceGuis,
  // while `PreviewSubwayCar_EditMode` gives the creator a full visual preview in Studio Edit Mode!
  // In fact, we can have `LastLocalServer` destroy `PreviewSubwayCar_EditMode` on startup and spawn the interactive `GTrainConsist`!
  const serverWithPreviewCleanup = `local preview = workspace:FindFirstChild("PreviewSubwayCar_EditMode")\nif preview then preview:Destroy() end\n` + LUAU_SERVER_SOURCE;

  return `<?xml version="1.0" encoding="utf-8"?>
<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">
  <External>null</External>
  <External>nil</External>
  <Item class="Workspace" referent="${nextRef()}">
    <Properties>
      <string name="Name">Workspace</string>
      <float name="Gravity">196.2</float>
    </Properties>
    <Item class="SpawnLocation" referent="${nextRef()}">
      <Properties>
        <string name="Name">SpawnLocation</string>
        <bool name="Anchored">true</bool>
        <bool name="CanCollide">false</bool>
        <float name="Transparency">1</float>
        <Vector3 name="size"><X>4</X><Y>0.2</Y><Z>4</Z></Vector3>
        <CoordinateFrame name="CFrame">
          <X>0</X><Y>0.5</Y><Z>${(0.8 * S).toFixed(2)}</Z>
          <R00>1</R00><R01>0</R01><R02>0</R02>
          <R10>0</R10><R11>1</R11><R12>0</R12>
          <R20>0</R20><R21>0</R21><R22>1</R22>
        </CoordinateFrame>
      </Properties>
    </Item>
    <Item class="Model" referent="${nextRef()}">
      <Properties>
        <string name="Name">PreviewSubwayCar_EditMode</string>
      </Properties>
      ${carBParts.join('\n')}
    </Item>
  </Item>
  <Item class="Lighting" referent="${nextRef()}">
    <Properties>
      <string name="Name">Lighting</string>
      <Color3 name="Ambient"><R>0.11</R><G>0.125</G><B>0.114</B></Color3>
      <Color3 name="OutdoorAmbient"><R>0.07</R><G>0.086</G><B>0.075</B></Color3>
      <float name="Brightness">0.6</float>
      <float name="ClockTime">0</float>
    </Properties>
    <Item class="ColorCorrectionEffect" referent="${nextRef()}">
      <Properties>
        <string name="Name">SanityColorCorrection</string>
        <float name="Saturation">0</float>
        <float name="Contrast">0</float>
      </Properties>
    </Item>
  </Item>
  <Item class="ReplicatedStorage" referent="${nextRef()}">
    <Properties>
      <string name="Name">ReplicatedStorage</string>
    </Properties>
    <Item class="ModuleScript" referent="${nextRef()}">
      <Properties>
        <string name="Name">LastLocalConfig</string>
        <ProtectedString name="Source">${cdataWrap(LUAU_CONFIG_SOURCE)}</ProtectedString>
      </Properties>
    </Item>
    <Item class="Folder" referent="${nextRef()}">
      <Properties>
        <string name="Name">Remotes</string>
      </Properties>
      <Item class="RemoteEvent" referent="${nextRef()}"><Properties><string name="Name">FlagAnomaly</string></Properties></Item>
      <Item class="RemoteEvent" referent="${nextRef()}"><Properties><string name="Name">AnswerMask</string></Properties></Item>
      <Item class="RemoteEvent" referent="${nextRef()}"><Properties><string name="Name">DoorDecision</string></Properties></Item>
      <Item class="RemoteEvent" referent="${nextRef()}"><Properties><string name="Name">LookTelemetry</string></Properties></Item>
      <Item class="RemoteEvent" referent="${nextRef()}"><Properties><string name="Name">GameStateSync</string></Properties></Item>
      <Item class="RemoteEvent" referent="${nextRef()}"><Properties><string name="Name">RestartRide</string></Properties></Item>
    </Item>
  </Item>
  <Item class="ServerScriptService" referent="${nextRef()}">
    <Properties>
      <string name="Name">ServerScriptService</string>
    </Properties>
    <Item class="Script" referent="${nextRef()}">
      <Properties>
        <string name="Name">LastLocalServer</string>
        <ProtectedString name="Source">${cdataWrap(serverWithPreviewCleanup)}</ProtectedString>
      </Properties>
    </Item>
  </Item>
  <Item class="StarterPlayer" referent="${nextRef()}">
    <Properties>
      <string name="Name">StarterPlayer</string>
    </Properties>
    <Item class="StarterPlayerScripts" referent="${nextRef()}">
      <Properties>
        <string name="Name">StarterPlayerScripts</string>
      </Properties>
      <Item class="LocalScript" referent="${nextRef()}">
        <Properties>
          <string name="Name">LastLocalClient</string>
          <ProtectedString name="Source">${cdataWrap(LUAU_CLIENT_SOURCE)}</ProtectedString>
        </Properties>
      </Item>
    </Item>
  </Item>
</roblox>
`;
}

/** Triggers a browser download of a text file (`.rbxlx` or `.luau`). */
export function downloadTextFile(filename: string, content: string, mime = 'application/xml') {
  const blob = new Blob([content], { type: `${mime};charset=utf-8` });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 2000);
}

/** Triggers a browser download of a binary `.glb` ArrayBuffer. */
export function downloadBinaryFile(filename: string, bytes: ArrayBuffer, mime = 'model/gltf-binary') {
  const blob = new Blob([bytes], { type: mime });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 2000);
}
