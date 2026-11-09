local _, ns = ...

-- SavedVariables layout migrations, run on the raw `WanderDeckDB` root after
-- Schema.sanitizeRoot and before AceDB reads it. Each step only moves and
-- merges data; the Schema and Tags sanitizers still run on the result.
--
-- Version 2 (user decision, 2026-11-09): the card collection is account-wide.
-- Owned cards, copies, New flags, tags and pins move from every character
-- (`char["Name - Realm"]`) to `global`; packs, steps and per-zone progress
-- stay per character. Copies are summed and capped at MAX_COPIES; New flags,
-- pins and tags are unions (Tags.sanitize then applies the tag limits).

local type, pairs, ipairs, sort, floor, min = type, pairs, ipairs, table.sort, math.floor, math.min
local Schema, Tags = ns.Schema, ns.Tags
local isFiniteNonNegative = ns.Utils.isFiniteNonNegative

local Migration = {}
ns.Migration = Migration

-- The per-character keys version 2 moved to `global`.
Migration.ACCOUNT_KEYS = { "collection", "newCards", "tags", "pinned" }

-- Same bound as Schema's unknown-ID rule and Cards.lua's ID length.
local MAX_CARD_ID_LENGTH = 64

local function isCardID(id)
  return type(id) == "string" and id ~= "" and #id <= MAX_CARD_ID_LENGTH
end

local function isWholeCount(copies)
  return isFiniteNonNegative(copies) and copies >= 1 and copies == floor(copies)
end

-- String keys of a table, sorted, so merges do not depend on pairs() order.
local function sortedKeys(tbl, accept)
  local keys = {}
  for key in pairs(tbl) do
    if accept(key) then keys[#keys + 1] = key end
  end
  sort(keys)
  return keys
end

local function isString(key) return type(key) == "string" end

---Adds the copies of `from` to `into`, capped at maxCopies. Unknown card IDs
---are kept: deleting them is Schema.sanitizeCollection's job, which knows
---whether every Data file loaded.
---@param into table<string, number>
---@param from any a saved collection
---@param maxCopies number
function Migration.mergeCollection(into, from, maxCopies)
  if type(from) ~= "table" then return end
  for cardID, copies in pairs(from) do
    if isCardID(cardID) and isWholeCount(copies) then
      into[cardID] = min((into[cardID] or 0) + min(copies, maxCopies), maxCopies)
    end
  end
end

---Union of `[cardID] = true` flags (New flags, pins).
---@param into table<string, boolean>
---@param from any
function Migration.mergeFlags(into, from)
  if type(from) ~= "table" then return end
  for cardID, flag in pairs(from) do
    if flag == true and isCardID(cardID) then into[cardID] = true end
  end
end

---Union of the valid saved tags. The per-card and distinct limits are left to
---Tags.sanitize, which applies them after it dropped unknown cards: counting
---tags of removed cards here would crowd out tags of real ones.
---@param into table<string, table<string, boolean>>
---@param from any
function Migration.mergeTags(into, from)
  if type(from) ~= "table" then return end
  for cardID, cardTags in pairs(from) do
    if isCardID(cardID) and type(cardTags) == "table" then
      for tag, flag in pairs(cardTags) do
        if flag == true and type(tag) == "string" and (tag == Tags.TRADE or Tags.normalize(tag) == tag) then
          into[cardID] = into[cardID] or {}
          into[cardID][tag] = true
        end
      end
    end
  end
end

-- True when a character still holds one of the keys version 2 moved, e.g.
-- cards opened while an older addon version was loaded.
local function charsHoldAccountKeys(sv)
  if type(sv.char) ~= "table" then return false end
  for key, char in pairs(sv.char) do
    if type(key) == "string" and type(char) == "table" then
      for _, accountKey in ipairs(Migration.ACCOUNT_KEYS) do
        if char[accountKey] ~= nil then return true end
      end
    end
  end
  return false
end

-- Version 1 -> 2: merges every character's collection into `global`, then
-- removes it from the characters. The merge only builds new tables; the saved
-- data is changed after it succeeded, in plain assignments that cannot throw,
-- so an error leaves the save exactly as it was.
local function toV2(sv, maxCopies)
  local global = type(sv.global) == "table" and sv.global or {}
  local merged = { collection = {}, newCards = {}, tags = {}, pinned = {} }
  -- `global` comes first: a save already at version 2 whose version number was
  -- lost merges its own account collection back unchanged.
  local sources = { global }
  local chars = {}
  if type(sv.char) == "table" then
    for _, key in ipairs(sortedKeys(sv.char, isString)) do
      if type(sv.char[key]) == "table" then chars[#chars + 1] = sv.char[key] end
    end
  end
  for _, char in ipairs(chars) do sources[#sources + 1] = char end
  for _, source in ipairs(sources) do
    Migration.mergeCollection(merged.collection, source.collection, maxCopies)
    Migration.mergeFlags(merged.newCards, source.newCards)
    Migration.mergeFlags(merged.pinned, source.pinned)
    Migration.mergeTags(merged.tags, source.tags)
  end

  sv.global = global
  for _, key in ipairs(Migration.ACCOUNT_KEYS) do global[key] = merged[key] end
  global.schemaVersion = 2
  for _, char in ipairs(chars) do
    for _, key in ipairs(Migration.ACCOUNT_KEYS) do char[key] = nil end
  end
end

---Brings a raw SavedVariables root to Schema.CURRENT_VERSION. A missing
---version means version 1: AceDB stripped `schemaVersion = 1` on logout
---because it equaled the old default. An invalid version is also treated as
---version 1; every step is safe to run again on migrated data. A version 2
---save whose characters hold collection keys again (the addon was rolled back
---and packs were opened meanwhile) is merged again, so those cards show up.
---@param sv table|nil the root returned by Schema.sanitizeRoot
---@param maxCopies number Config.MAX_COPIES
---@return string status "fresh" (no save), "current", "newer" (left untouched) or "migrated"
function Migration.run(sv, maxCopies)
  if type(sv) ~= "table" then return "fresh" end
  local version = type(sv.global) == "table" and sv.global.schemaVersion or nil
  if not Schema.isValidVersion(version) then version = 1 end
  if version > Schema.CURRENT_VERSION then return "newer" end
  if version < 2 or charsHoldAccountKeys(sv) then
    toV2(sv, maxCopies)
    return "migrated"
  end
  return "current"
end
