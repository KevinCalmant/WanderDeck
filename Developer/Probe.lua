local _, ns = ...

-- Developer-only (excluded from releases by .pkgmeta). Reports which position,
-- map and movement APIs work on this client, so StepTracker can be designed
-- against observed behaviour rather than guesses. Every API call is looked up
-- by name in an injected environment and run under pcall: a missing or
-- throwing API is a result, not a crash.

local type, pcall, select, tostring = type, pcall, select, tostring
local format, floor, sqrt = string.format, math.floor, math.sqrt
local tinsert, tremove = table.insert, table.remove

local Probe = {}
ns.Probe = Probe

local LABEL_PATTERN = "^[%w_%-]+$"
local LABEL_MAX_LENGTH = 24
local MAX_SAVED_RUNS = 20
local MAX_MAP_CHAIN = 10
local WATCH_SECONDS = 10

---Validates the optional run label typed after `/wd probe`.
---@param text any
---@return string|nil label nil when rejected
function Probe.sanitizeLabel(text)
  if type(text) ~= "string" then return nil end
  if text == "" then return "default" end
  if #text > LABEL_MAX_LENGTH then return nil end
  if not text:match(LABEL_PATTERN) then return nil end
  return text
end

---Makes text safe for one chat line: "||" is a literal pipe in WoW chat, so
---|c, |T and |H codes are shown instead of rendered; line breaks are escaped.
---@param text string
---@return string
function Probe.escapeChat(text)
  local escaped = text:gsub("\r", "\\r"):gsub("\n", "\\n"):gsub("|", "||")
  return escaped
end

---Renders one API return value for chat and SavedVariables. A secret value is
---never passed to tostring or format.
---@param value any
---@param isSecret fun(value: any): boolean
---@return string
function Probe.describe(value, isSecret)
  if isSecret(value) then return "<secret>" end
  local valueType = type(value)
  if valueType == "nil" then return "nil" end
  if valueType == "number" then
    if value == floor(value) then return tostring(value) end
    return format("%.3f", value)
  end
  if valueType == "string" then
    -- Lua 5.1's %q keeps a raw newline after the backslash: make it "\n".
    local quoted = format("%q", value):gsub("\\\n", "\\n")
    return Probe.escapeChat(quoted)
  end
  if valueType == "boolean" then return tostring(value) end
  return "<"..valueType..">"
end

local function lookup(env, path)
  local node = env
  for part in path:gmatch("[^%.]+") do
    if type(node) ~= "table" then return nil end
    node = node[part]
  end
  return node
end

local function pack(...)
  return { n = select("#", ...), ... }
end

---Calls `env[path](...)` safely.
---@return string status "ok", "missing" or "error"
---@return table results packed return values on "ok", { [1] = message } on "error"
function Probe.call(env, path, ...)
  local fn = lookup(env, path)
  if type(fn) ~= "function" then return "missing", { n = 0 } end
  local packed = pack(pcall(fn, ...))
  if not packed[1] then return "error", { n = 1, Probe.escapeChat(tostring(packed[2])) } end
  local results = { n = packed.n - 1 }
  for i = 2, packed.n do results[i - 1] = packed[i] end
  return "ok", results
end

local function describeAll(results, isSecret)
  if results.n == 0 then return "(no value)" end
  local parts = {}
  for i = 1, results.n do parts[i] = Probe.describe(results[i], isSecret) end
  return table.concat(parts, ", ")
end

local function callLine(env, isSecret, path, ...)
  local status, results = Probe.call(env, path, ...)
  if status == "missing" then return path..": MISSING" end
  if status == "error" then return path..": ERROR "..results[1] end
  return path..": "..describeAll(results, isSecret)
end

local function presenceLine(env, path)
  return path..": "..(type(lookup(env, path)) == "function" and "present" or "MISSING")
end

---A plain (non-secret) number, or nil.
local function plainNumber(value, isSecret)
  if isSecret(value) or type(value) ~= "number" then return nil end
  return value
end

local function mapLines(env, isSecret, lines)
  local status, results = Probe.call(env, "C_Map.GetBestMapForUnit", "player")
  local mapID = status == "ok" and plainNumber(results[1], isSecret) or nil
  lines[#lines + 1] = "C_Map.GetBestMapForUnit: "..(status == "ok" and describeAll(results, isSecret) or status:upper())
  if not mapID then return end

  -- Parent chain, so the zone resolution can be checked by eye.
  local current = mapID
  for depth = 1, MAX_MAP_CHAIN do
    local infoStatus, infoResults = Probe.call(env, "C_Map.GetMapInfo", current)
    local info = infoStatus == "ok" and infoResults[1] or nil
    if isSecret(info) or type(info) ~= "table" then
      lines[#lines + 1] = "  map["..depth.."] "..current..": "..(infoStatus == "ok" and Probe.describe(info, isSecret) or infoStatus:upper())
      break
    end
    lines[#lines + 1] = format("  map[%d] %s name=%s mapType=%s parent=%s", depth, tostring(current),
      Probe.describe(info.name, isSecret), Probe.describe(info.mapType, isSecret), Probe.describe(info.parentMapID, isSecret))
    local parent = plainNumber(info.parentMapID, isSecret)
    if not parent or parent == 0 or parent == current then break end
    current = parent
  end

  local getMapInfo = lookup(env, "C_Map.GetMapInfo")
  local ok, zone = pcall(ns.Zone.resolve, mapID, type(getMapInfo) == "function" and getMapInfo or nil, isSecret)
  lines[#lines + 1] = "Zone.resolve: "..(ok and Probe.describe(zone, isSecret) or "ERROR "..Probe.escapeChat(tostring(zone)))

  local posStatus, posResults = Probe.call(env, "C_Map.GetPlayerMapPosition", mapID, "player")
  local position = posStatus == "ok" and posResults[1] or nil
  if posStatus ~= "ok" or isSecret(position) or type(position) ~= "table" or type(position.GetXY) ~= "function" then
    lines[#lines + 1] = "C_Map.GetPlayerMapPosition: "..(posStatus == "ok" and describeAll(posResults, isSecret) or posStatus:upper())
    return
  end
  local okXY, x, y = pcall(position.GetXY, position)
  lines[#lines + 1] = "C_Map.GetPlayerMapPosition: "..(okXY and (Probe.describe(x, isSecret)..", "..Probe.describe(y, isSecret)) or "ERROR "..Probe.escapeChat(tostring(x)))

  local worldStatus, worldResults = Probe.call(env, "C_Map.GetWorldPosFromMapPos", mapID, position)
  local worldPos = worldStatus == "ok" and worldResults[2] or nil
  if worldStatus == "ok" and not isSecret(worldPos) and type(worldPos) == "table" and type(worldPos.GetXY) == "function" then
    local okWorld, wx, wy = pcall(worldPos.GetXY, worldPos)
    lines[#lines + 1] = "C_Map.GetWorldPosFromMapPos: continent="..Probe.describe(worldResults[1], isSecret)
      ..(okWorld and (" pos="..Probe.describe(wx, isSecret)..", "..Probe.describe(wy, isSecret)) or " ERROR "..Probe.escapeChat(tostring(wx)))
  else
    lines[#lines + 1] = "C_Map.GetWorldPosFromMapPos: "..(worldStatus == "ok" and describeAll(worldResults, isSecret) or worldStatus:upper())
  end
end

---Runs every check once.
---@param env table the global environment (_G) or a test stub
---@param isSecret fun(value: any): boolean
---@return string[] lines
function Probe.collect(env, isSecret)
  local lines = {}
  lines[#lines + 1] = callLine(env, isSecret, "GetBuildInfo")
  lines[#lines + 1] = "WOW_PROJECT_ID: "..Probe.describe(env.WOW_PROJECT_ID, isSecret)
  lines[#lines + 1] = presenceLine(env, "issecretvalue")

  lines[#lines + 1] = callLine(env, isSecret, "UnitPosition", "player")
  mapLines(env, isSecret, lines)

  lines[#lines + 1] = callLine(env, isSecret, "GetUnitSpeed", "player")
  lines[#lines + 1] = callLine(env, isSecret, "UnitOnTaxi", "player")
  lines[#lines + 1] = callLine(env, isSecret, "IsMounted")
  lines[#lines + 1] = callLine(env, isSecret, "IsFlying")
  lines[#lines + 1] = callLine(env, isSecret, "UnitInVehicle", "player")
  lines[#lines + 1] = callLine(env, isSecret, "UnitIsDeadOrGhost", "player")
  lines[#lines + 1] = callLine(env, isSecret, "IsIndoors")
  lines[#lines + 1] = callLine(env, isSecret, "IsInInstance")
  lines[#lines + 1] = callLine(env, isSecret, "InCombatLockdown")

  lines[#lines + 1] = presenceLine(env, "C_ChatInfo.RegisterAddonMessagePrefix")
  lines[#lines + 1] = presenceLine(env, "C_ChatInfo.SendAddonMessage")
  lines[#lines + 1] = presenceLine(env, "C_Timer.NewTicker")
  lines[#lines + 1] = presenceLine(env, "Settings.RegisterProxySetting")
  lines[#lines + 1] = presenceLine(env, "C_AddOns.GetAddOnMetadata")
  return lines
end

---Straight-line distance between two plain-number points.
function Probe.distance(x1, y1, x2, y2)
  local dx, dy = x2 - x1, y2 - y1
  return sqrt(dx * dx + dy * dy)
end

---Appends a run to `store` and drops the oldest runs past `maxRuns`.
---@param store table list kept in SavedVariables
---@param entry table { label, time, lines }
---@param maxRuns number|nil defaults to MAX_SAVED_RUNS
---@return boolean saved false when `store` is not a list
function Probe.save(store, entry, maxRuns)
  if type(store) ~= "table" then return false end
  maxRuns = maxRuns or MAX_SAVED_RUNS
  tinsert(store, entry)
  while #store > maxRuns do tremove(store, 1) end
  return true
end

-- ============ in-game wiring ============

local function probeStore()
  local db = ns.GetDB and ns.GetDB()
  if not db then return nil end
  -- SavedVariables are user-editable: replace anything that is not a list.
  if type(db.global.probes) ~= "table" then db.global.probes = {} end
  return db.global.probes
end

local function saveRun(label, lines)
  local store = probeStore()
  if not store then return end
  Probe.save(store, { label = label, time = GetServerTime and GetServerTime() or 0, lines = lines })
end

local function printLines(title, lines)
  ns.print(title)
  for _, line in ipairs(lines) do print("  "..line) end
end

local function readLabel(rest)
  local label = Probe.sanitizeLabel(rest)
  if not label then
    ns.print("Label must be 1-"..LABEL_MAX_LENGTH.." letters, digits, - or _.")
  end
  return label
end

local function handleProbe(rest)
  local label = readLabel(rest)
  if not label then return end
  local lines = Probe.collect(_G, ns.Wow.isSecret)
  printLines("probe '"..label.."'", lines)
  saveRun(label, lines)
  ns.print("Saved in WTF/Account/<account>/SavedVariables/WanderDeck.lua after /reload or logout.")
end

local function watchSample(isSecret)
  local status, results = Probe.call(_G, "UnitPosition", "player")
  if status ~= "ok" then return nil, nil, "UnitPosition "..status:upper() end
  local y, x = results[1], results[2]
  if isSecret(y) or isSecret(x) then return nil, nil, "UnitPosition <secret>" end
  if type(x) ~= "number" or type(y) ~= "number" then return nil, nil, "UnitPosition nil" end
  return x, y, nil
end

local function handleWatch(rest)
  local label = readLabel(rest)
  if not label then return end
  if not (C_Timer and C_Timer.NewTicker) then
    ns.print("C_Timer.NewTicker is missing.")
    return
  end

  local isSecret = ns.Wow.isSecret
  local lines = {}
  local lastX, lastY = watchSample(isSecret)
  local tick = 0
  ns.print("watch '"..label.."': walk for "..WATCH_SECONDS.." seconds.")

  C_Timer.NewTicker(1, function()
    tick = tick + 1
    local x, y, problem = watchSample(isSecret)
    local speedStatus, speed = Probe.call(_G, "GetUnitSpeed", "player")
    local speedText = speedStatus == "ok" and Probe.describe(speed[1], isSecret) or speedStatus:upper()
    local line
    if problem then
      line = format("t=%ds %s speed=%s", tick, problem, speedText)
    elseif lastX then
      line = format("t=%ds moved=%.2f yd speed=%s", tick, Probe.distance(lastX, lastY, x, y), speedText)
    else
      line = format("t=%ds first sample speed=%s", tick, speedText)
    end
    lastX, lastY = x, y
    lines[#lines + 1] = line
    print("  "..line)
    if tick == WATCH_SECONDS then saveRun("watch-"..label, lines) end
  end, WATCH_SECONDS)
end

if ns.Slash then
  ns.Slash.register({
    name = "probe",
    usage = "probe [label]",
    help = "Developer: report position, map and movement APIs",
    handler = handleProbe,
  })
  ns.Slash.register({
    name = "watch",
    usage = "watch [label]",
    help = "Developer: sample UnitPosition every second for 10 s",
    handler = handleWatch,
  })
end
