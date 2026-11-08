local _, ns = ...

-- Shell: samples the player's position on a ticker, feeds StepTracker and
-- Packs, and writes the character's progress to SavedVariables.

local L = ns.L
local Config, StepTracker, Packs, Wow, Utils = ns.Config, ns.StepTracker, ns.Packs, ns.Wow, ns.Utils

local Walker = {}
ns.Walker = Walker

-- Lines /wd status prints for the current pack's zone shares.
local MAX_STATUS_ZONES = 10

local ticker
local lastSample -- last countable sample; nil after a blocked one
local failures = 0

local function serverTime()
  local ok, now = pcall(GetServerTime)
  if ok and not Wow.isSecret(now) and Utils.isFiniteNonNegative(now) then return now end
  return 0
end

local function step(char)
  local sample = Wow.readMovementSample(_G)
  -- Cities count for the zone around them, so walking out of Stormwind into
  -- Elwynn is one continuous walk, not a zone change.
  if sample.zoneMapID then sample.zoneMapID = ns.Cards.cardZone(sample.zoneMapID) end
  local yards = StepTracker.measure(lastSample, sample, Config)
  lastSample = (not sample.blocked) and sample or nil
  if not yards or yards <= 0 then return end

  char.stats.yards = char.stats.yards + yards

  local earnedZone = Packs.addDistance(char.progress, sample.zoneMapID, yards, Config)
  if not earnedZone then return end
  if Packs.store(char.packs, { zoneMapID = earnedZone, earnedAt = serverTime() }, Config.MAX_UNOPENED_PACKS) then
    ns.print(L["You earned a pack!"].." ("..#char.packs..")")
    if ns.refreshUI then ns.refreshUI() end
  else
    ns.print(L["Pack limit reached: open some packs to earn more."])
  end
end

---One sampling step. The whole body runs under pcall: an unexpected client
---value skips the tick, and repeated failures stop the ticker instead of
---raising an error every SAMPLE_INTERVAL.
function Walker.tick()
  local db = ns.GetDB()
  if not db then return end
  local ok = pcall(step, db.char)
  if ok then
    failures = 0
    return
  end
  lastSample = nil
  failures = failures + 1
  if failures >= Config.MAX_TICK_FAILURES then
    Walker.stop()
    ns.print(L["Step tracking stopped after repeated errors. /reload to retry."])
  end
end

function Walker.start()
  if ticker then return end
  lastSample, failures = nil, 0
  ticker = C_Timer.NewTicker(Config.SAMPLE_INTERVAL, Walker.tick)
end

function Walker.stop()
  if ticker then ticker:Cancel() end
  ticker, lastSample = nil, nil
end

---Localized zone name for chat, with WoW chat codes escaped; the map ID when
---the name is unavailable, secret or the lookup throws.
---@param zoneMapID number
---@return string
function Walker.zoneName(zoneMapID)
  local getMapInfo = C_Map and C_Map.GetMapInfo
  if type(getMapInfo) ~= "function" then return tostring(zoneMapID) end
  local ok, info = pcall(getMapInfo, zoneMapID)
  if not ok or Wow.isSecret(info) or type(info) ~= "table" then return tostring(zoneMapID) end
  local name = info.name
  if Wow.isSecret(name) or type(name) ~= "string" then return tostring(zoneMapID) end
  return (name:gsub("|", "||"):gsub("[\r\n]", " "))
end

local function handleStatus()
  local db = ns.GetDB()
  if not db then return end
  local char = db.char
  ns.print(L["Steps walked:"].." "..Packs.toSteps(char.stats.yards, Config))
  ns.print(L["Next pack:"].." "..Packs.toSteps(char.progress.total, Config).." / "..Config.STEPS_PER_PACK)
  local shown = 0
  for zone, yards in pairs(char.progress.byZone) do
    if shown >= MAX_STATUS_ZONES then break end
    shown = shown + 1
    print("  "..Walker.zoneName(zone)..": "..Packs.toSteps(yards, Config))
  end
  ns.print(L["Unopened packs:"].." "..#char.packs.." / "..Config.MAX_UNOPENED_PACKS)
end

ns.Slash.register({
  name = "status",
  usage = "status",
  help = L["Show steps and pack progress"],
  handler = handleStatus,
})
