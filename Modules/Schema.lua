local _, ns = ...

local type, pairs, ipairs, floor, huge = type, pairs, ipairs, math.floor, math.huge

-- Bump with a migration step for every SavedVariables layout change.
local CURRENT_VERSION = 1

-- Every key AceDB-3.0 reads from the saved-variable root: the sections of its
-- `keyTbl` plus profiles, profileKeys and namespaces. Its PLAYER_LOGOUT
-- handler runs pairs() on each section and next() on each entry, for every
-- AceDB addon in one loop, so one bad value here breaks other addons' saves.
-- Value: the type each entry of the section must have (nil = only the section
-- itself is checked). Checked against Ace3 Release-r981; recheck on upgrade.
local SECTIONS = {
  global = false,
  profile = "table",
  profiles = "table",
  profileKeys = "string",
  namespaces = "table",
  char = "table",
  realm = "table",
  class = "table",
  race = "table",
  faction = "table",
  factionrealm = "table",
  factionrealmregion = "table",
  locale = "table",
}

local sanitizeRoot

local function sanitizeSections(sv, isNamespace)
  for key, entryType in pairs(SECTIONS) do
    local section = sv[key]
    if section ~= nil and type(section) ~= "table" then
      sv[key] = nil
    elseif section ~= nil and entryType then
      for entryKey, value in pairs(section) do
        if type(value) ~= entryType then
          section[entryKey] = nil
        elseif key == "namespaces" and not isNamespace then
          -- Each namespace is a full nested root; AceDB does not nest further.
          sanitizeRoot(value, true)
        end
      end
    end
  end
end

---Sanitizes the raw SavedVariables root before AceDB reads it. SavedVariables
---are a user-editable file: a section or entry of the wrong type is dropped so
---AceDB recreates it from defaults instead of throwing.
---@param sv any the raw `WanderDeckDB` global
---@param isNamespace? boolean internal: sanitizing a namespace root
---@return table|nil sv nil when the root itself is not a table
function sanitizeRoot(sv, isNamespace)
  if type(sv) ~= "table" then return nil end
  sanitizeSections(sv, isNamespace)
  return sv
end

local function isValidVersion(version)
  return type(version) == "number"
    and version == version -- NaN
    and version ~= huge and version ~= -huge
    and version == floor(version)
    and version >= 1
end

---Sanitizes the account-wide saved data in place.
---@param global table AceDB `db.global`
---@return string status "ok", "repaired" (bad version reset), "newer" (saved by a newer addon version; left untouched) or "invalid" (not a table)
local function sanitizeGlobal(global)
  if type(global) ~= "table" then return "invalid" end
  local version = global.schemaVersion
  if not isValidVersion(version) then
    global.schemaVersion = CURRENT_VERSION
    return "repaired"
  end
  if version > CURRENT_VERSION then return "newer" end
  return "ok"
end

local isFiniteNonNegative, isMapID = ns.Utils.isFiniteNonNegative, ns.Utils.isMapID

-- A pack's share lists the zones walked since the last pack; real play stays
-- far below this. A larger (hand-edited) share is reset.
local MAX_ZONE_SHARES = 64
-- Upper bound for a stored server time (seconds since epoch, 32-bit).
local MAX_TIMESTAMP = 4294967295

local function sanitizeShares(progress)
  if type(progress.byZone) ~= "table" then progress.byZone = {} end
  local total, count = 0, 0
  for zone, yards in pairs(progress.byZone) do
    if isMapID(zone) and isFiniteNonNegative(yards) and yards > 0 then
      total, count = total + yards, count + 1
    else
      progress.byZone[zone] = nil
    end
  end
  if count > MAX_ZONE_SHARES or total == huge then
    progress.byZone, total = {}, 0
  end
  progress.total = total
end

---Sanitizes the character's walking data in place: stats, pack progress and
---unopened packs. Invalid entries are dropped; the progress total is
---recomputed from the per-zone shares instead of trusting the stored value.
---@param char table AceDB `db.char`
---@param maxPacks number Config.MAX_UNOPENED_PACKS
local function sanitizeChar(char, maxPacks)
  if type(char.stats) ~= "table" then char.stats = {} end
  if not isFiniteNonNegative(char.stats.yards) then char.stats.yards = 0 end

  if type(char.progress) ~= "table" then char.progress = {} end
  sanitizeShares(char.progress)

  local kept = {}
  if type(char.packs) == "table" then
    for _, pack in ipairs(char.packs) do
      if #kept >= maxPacks then break end
      if type(pack) == "table" and isMapID(pack.zoneMapID)
        and isFiniteNonNegative(pack.earnedAt) and pack.earnedAt <= MAX_TIMESTAMP then
        kept[#kept + 1] = { zoneMapID = pack.zoneMapID, earnedAt = pack.earnedAt }
      end
    end
  end
  char.packs = kept
end

ns.Schema = {
  sanitizeChar = sanitizeChar,
  MAX_ZONE_SHARES = MAX_ZONE_SHARES,
  MAX_TIMESTAMP = MAX_TIMESTAMP,
  CURRENT_VERSION = CURRENT_VERSION,
  SECTIONS = SECTIONS,
  sanitizeRoot = function(sv) return sanitizeRoot(sv, false) end,
  sanitizeGlobal = sanitizeGlobal,
}
