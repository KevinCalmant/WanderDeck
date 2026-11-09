local _, ns = ...

-- Card registry (filled by Data/*.lua), zone pools with fallbacks, rarity
-- rolls and card stats. Pure: randomness is injected as rng(n) -> 1..n.

local type, pairs, ipairs, assert, tostring, tonumber = type, pairs, ipairs, assert, tostring, tonumber
local isMapID = ns.Utils.isMapID

local Cards = {}
ns.Cards = Cards

-- Rarity reuses WoW item quality numbers so ITEM_QUALITY_COLORS lines up.
Cards.RARITY = { COMMON = 1, UNCOMMON = 2, RARE = 3, EPIC = 4, LEGENDARY = 5 }
Cards.RARITY_NAMES = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }
-- Standard WoW quality colors, kept here so chat output needs no client table.
Cards.RARITY_COLORS = { "ffffffff", "ff1eff00", "ff0070dd", "ffa335ee", "ffff8000" }

-- Base attack and defense per kind; rarity adds the same bonus to both.
local KIND_STATS = {
  creature = { 2, 1 },
  rare = { 4, 3 },
  elite = { 5, 4 },
  boss = { 7, 6 },
  npc = { 2, 4 },
  place = { 1, 5 },
  quest = { 3, 3 },
  item = { 3, 2 },
  lore = { 6, 6 },
}
-- Optional game IDs on a card: the client then supplies the localized name
-- (and, for items, the icon) through CardText.
local REF_FIELDS = { "itemID", "questID", "areaID" }
local RARITY_BONUS = { 0, 1, 2, 4, 6 }
-- Card art: an icon file name under Interface\Icons (no path, no extension).
local ICON_PATTERN = "^[A-Za-z0-9_]+$"
local ICON_MAX_LENGTH = 64
-- Art used when a card has no icon of its own (local: validated like card
-- icons at registration, never changed at run time).
local KIND_ICONS = {
  creature = "INV_Misc_QuestionMark", rare = "INV_Misc_QuestionMark", elite = "INV_Misc_QuestionMark",
  boss = "INV_Misc_QuestionMark", npc = "INV_Misc_QuestionMark", place = "INV_Misc_Map_01",
  quest = "INV_Misc_Note_01", lore = "INV_Misc_Book_09", item = "INV_Misc_Bag_08",
}
Cards.ICON_PREFIX = "Interface\\Icons\\"
-- Dungeon card art: the dungeon's loading screen, as a file name under
-- Interface\Glues\LoadingScreens (same characters as icons) or a file ID.
Cards.LOAD_SCREEN_PREFIX = "Interface\\Glues\\LoadingScreens\\"
local ID_PATTERN = "^([1-9]%d*):[a-z0-9_]+$"
local ID_MAX_LENGTH = 64
local NAME_MAX_LENGTH = 64
local FLAVOR_MAX_LENGTH = 200

local validateAll    -- defined below, used by registerZone and addCards
local byID = {}       -- [cardID] = card
local zones = {}      -- [zoneMapID] = { continentMapID, cards = { card, ... } }

local CREATURE_TYPES = {
  Beast = true, Humanoid = true, Undead = true, Demon = true, Elemental = true,
  Dragonkin = true, Giant = true, Mechanical = true, Critter = true,
}
Cards.CREATURE_TYPES = CREATURE_TYPES
local MAX_LEVEL = 63

---Validates one card and returns its registered form. A malformed entry is a
---developer error and fails loudly.
local function validateCard(card, zoneMapID, i, seen)
  local where = "card #"..i.." of zone "..zoneMapID
  assert(type(card) == "table", where..": must be a table")
  assert(type(card.id) == "string" and #card.id <= ID_MAX_LENGTH, where..": id must be a string of at most "..ID_MAX_LENGTH.." chars")
  local prefix = card.id:match(ID_PATTERN)
  assert(prefix and tonumber(prefix) == zoneMapID, where..": id must be '<zoneMapID>:<slug>'")
  assert(not byID[card.id] and not seen[card.id], "duplicate card id: "..card.id)
  assert(KIND_STATS[card.kind], where..": unknown kind")
  assert(RARITY_BONUS[card.rarity], where..": rarity must be 1-5")
  -- Card text reaches FontStrings and chat: no "|" codes, no control
  -- characters, bounded length, and a name that is not blank.
  -- Same text rules as client strings (Utils.isCleanText): data may be
  -- generated from an external database.
  assert(type(card.name) == "string" and card.name:find("%S") and #card.name <= NAME_MAX_LENGTH
    and not card.name:find("|", 1, true) and ns.Utils.isCleanText(card.name),
    where..": name must be 1-"..NAME_MAX_LENGTH.." chars of clean UTF-8, no | or control characters")
  -- Flavor is optional: without it, CardText builds one from level and type.
  assert(card.flavor == nil or (type(card.flavor) == "string" and #card.flavor <= FLAVOR_MAX_LENGTH
    and not card.flavor:find("|", 1, true) and ns.Utils.isCleanText(card.flavor)),
    where..": flavor must be at most "..FLAVOR_MAX_LENGTH.." chars of clean UTF-8, no | or control characters")
  -- The resolved icon (the card's own, or its kind's default) is checked, so
  -- a kind without a default fails here rather than at display time.
  local icon = card.icon
  if icon == nil then icon = KIND_ICONS[card.kind] end
  assert(type(icon) == "string" and #icon <= ICON_MAX_LENGTH and icon:match(ICON_PATTERN),
    where..": icon must be an Interface\\Icons file name (letters, digits, _)")
  local loadScreen = card.loadScreen
  assert(loadScreen == nil or isMapID(loadScreen) or (type(loadScreen) == "string"
    and #loadScreen <= ICON_MAX_LENGTH and loadScreen:match(ICON_PATTERN) ~= nil),
    where..": loadScreen must be a file name under Interface\\Glues\\LoadingScreens (letters, digits, _) or a file ID")
  local refs = 0
  for _, field in ipairs(REF_FIELDS) do
    if card[field] ~= nil then
      assert(isMapID(card[field]), where..": "..field.." must be a positive whole number")
      refs = refs + 1
    end
  end
  assert(refs <= 1, where..": at most one of itemID, questID, areaID")
  assert(card.npcID == nil or isMapID(card.npcID), where..": npcID must be a positive whole number")
  assert(card.level == nil or (isMapID(card.level) and card.level <= MAX_LEVEL), where..": level must be 1-"..MAX_LEVEL)
  assert(card.creatureType == nil or CREATURE_TYPES[card.creatureType] == true, where..": unknown creatureType")
  seen[card.id] = true

  local registered = {
    id = card.id, zoneMapID = zoneMapID, kind = card.kind, rarity = card.rarity,
    name = card.name, flavor = card.flavor, icon = icon, loadScreen = loadScreen,
    itemID = card.itemID, questID = card.questID, areaID = card.areaID,
    npcID = card.npcID, level = card.level, creatureType = card.creatureType,
  }
  registered.attack, registered.defense = Cards.stats(card.kind, card.rarity)
  return registered
end

---Validates a list of cards; returns them registered, or fails without
---registering any.
function validateAll(zoneMapID, cards)
  local seen, out = {}, {}
  for i, card in ipairs(cards) do out[i] = validateCard(card, zoneMapID, i, seen) end
  return out
end

---Registers one zone's cards. Called by Data files at load; a malformed entry
---is a developer error and fails loudly.
---@param zone table { zoneMapID, continentMapID, cards = { { id, kind, rarity, name, flavor }, ... } }
function Cards.registerZone(zone)
  assert(type(zone) == "table" and isMapID(zone.zoneMapID), "zone needs a zoneMapID")
  assert(isMapID(zone.continentMapID), "zone needs a continentMapID")
  assert(not zones[zone.zoneMapID], "zone registered twice: "..tostring(zone.zoneMapID))
  assert(type(zone.cards) == "table" and #zone.cards > 0, "zone needs cards")

  local entry = { continentMapID = zone.continentMapID, cards = validateAll(zone.zoneMapID, zone.cards) }
  for _, registered in ipairs(entry.cards) do byID[registered.id] = registered end
  zones[zone.zoneMapID] = entry
end

local batches = {} -- ["<zoneMapID>:<batch>"] = true once a batch registered

---Adds a named batch of cards to a zone already registered (generated card
---files call this after the zone's hand-written file). Same validation, all
---or nothing. Data/Loaded.lua lists the expected batches: a batch that fails
---or is missing keeps Data from counting as loaded, so saved cards of that
---batch are never deleted.
---@param zoneMapID number
---@param cards table[]
---@param batch string lowercase letters, digits, _ (e.g. "generated")
function Cards.addCards(zoneMapID, cards, batch)
  assert(isMapID(zoneMapID) and zones[zoneMapID], "addCards needs a registered zone: "..tostring(zoneMapID))
  assert(type(cards) == "table" and #cards > 0, "addCards needs cards")
  assert(type(batch) == "string" and #batch <= 32 and batch:match("^[a-z0-9_]+$"), "addCards needs a batch name")
  local key = zoneMapID..":"..batch
  assert(not batches[key], "batch added twice: "..key)
  local added = validateAll(zoneMapID, cards)
  local list = zones[zoneMapID].cards
  for _, registered in ipairs(added) do
    byID[registered.id] = registered
    list[#list + 1] = registered
  end
  batches[key] = true
end

local zoneParents = {} -- [childMapID] = outdoor zone uiMapID

---Folds a city or other non-outdoor map into the outdoor zone around it, for
---cards and packs: walking in Stormwind counts for Elwynn Forest. One level
---only: a parent cannot itself be folded. Called by Data/ZoneGroups.lua.
---@param childMapID number e.g. Stormwind City
---@param parentMapID number e.g. Elwynn Forest
function Cards.foldZone(childMapID, parentMapID)
  assert(isMapID(childMapID) and isMapID(parentMapID), "foldZone needs two map IDs")
  assert(childMapID ~= parentMapID, "a zone cannot fold into itself")
  assert(not zoneParents[childMapID], "zone folded twice: "..childMapID)
  assert(not zoneParents[parentMapID], "parent is itself folded: "..parentMapID)
  for _, parent in pairs(zoneParents) do
    assert(parent ~= childMapID, "child is already a parent: "..childMapID)
  end
  zoneParents[childMapID] = parentMapID
end

---The zone whose cards and packs a map belongs to: its fold parent, or itself.
---@param zoneMapID any
---@return any
function Cards.cardZone(zoneMapID)
  return zoneParents[zoneMapID] or zoneMapID
end

---Called by Data/Loaded.lua with every zone Data/ ships. The client keeps
---loading files after one errors, so reaching Loaded.lua proves nothing:
---Data counts as loaded only when every expected zone registered. Until then,
---saved card IDs the registry does not know may belong to a failed file and
---must not be deleted.
---@param expectedZones number[]
---@param expectedBatches string[]|nil "<zoneMapID>:<batch>" keys of addCards batches
---@return boolean loaded
function Cards.markLoaded(expectedZones, expectedBatches)
  for _, zoneMapID in ipairs(expectedZones) do
    if not zones[zoneMapID] then return false end
  end
  for _, key in ipairs(expectedBatches or {}) do
    if not batches[key] then return false end
  end
  Cards.dataLoaded = true
  return true
end

---"<zoneMapID>:<batch>" keys of every batch added, sorted. For tests.
function Cards.batchKeys()
  local keys = {}
  for key in pairs(batches) do keys[#keys + 1] = key end
  table.sort(keys)
  return keys
end

---@param kind string
---@param rarity number 1-5
---@return number attack, number defense
function Cards.stats(kind, rarity)
  local base, bonus = KIND_STATS[kind], RARITY_BONUS[rarity]
  return base[1] + bonus, base[2] + bonus
end

---Kinds a card can have (KIND_STATS keys), sorted. For tests and tools.
function Cards.kinds()
  local kinds = {}
  for kind in pairs(KIND_STATS) do kinds[#kinds + 1] = kind end
  table.sort(kinds)
  return kinds
end

---Full texture path of a card's art.
---@param card table registered card
---@return string
function Cards.iconPath(card)
  return Cards.ICON_PREFIX..card.icon
end

---Texture of a card's loading screen art (a file ID or a full path), or nil.
---@param card table registered card
---@return number|string|nil
function Cards.loadScreenPath(card)
  local file = card.loadScreen
  if type(file) == "string" then return Cards.LOAD_SCREEN_PREFIX..file end
  return file
end

---@param cardID any
---@return table|nil card
function Cards.get(cardID)
  if type(cardID) ~= "string" then return nil end
  return byID[cardID]
end

---Zones that have cards, sorted by uiMapID.
---@return number[]
function Cards.zoneIDs()
  local ids = {}
  for id in pairs(zones) do ids[#ids + 1] = id end
  table.sort(ids)
  return ids
end

---Continent uiMapID of a registered zone, or nil.
---@param zoneMapID number
---@return number|nil
function Cards.continentOf(zoneMapID)
  local zone = zones[zoneMapID]
  return zone and zone.continentMapID
end

---Cards of one zone, in data order.
---@return table[]
function Cards.zoneCards(zoneMapID)
  local zone = zones[zoneMapID]
  return zone and zone.cards or {}
end

local function newPool(level)
  return { level = level, size = 0, byRarity = { {}, {}, {}, {}, {} } }
end

local function addToPool(pool, cards)
  for _, card in ipairs(cards) do
    local bucket = pool.byRarity[card.rarity]
    bucket[#bucket + 1] = card
    pool.size = pool.size + 1
  end
end

---Pool a pack from `zoneMapID` draws from: the zone's cards; else every card
---of its continent; else every card. `level` says which one was used.
---@param zoneMapID number
---@param continentMapID number|nil
---@return table pool { level = "zone"|"continent"|"all", size, byRarity }
function Cards.poolFor(zoneMapID, continentMapID)
  if zones[zoneMapID] then
    local pool = newPool("zone")
    addToPool(pool, zones[zoneMapID].cards)
    return pool
  end
  if continentMapID then
    local pool = newPool("continent")
    for _, id in ipairs(Cards.zoneIDs()) do
      if zones[id].continentMapID == continentMapID then addToPool(pool, zones[id].cards) end
    end
    if pool.size > 0 then return pool end
  end
  local pool = newPool("all")
  for _, id in ipairs(Cards.zoneIDs()) do addToPool(pool, zones[id].cards) end
  return pool
end

---Rolls a rarity from integer weights, only among rarities >= minRarity.
---@param weights number[] index = rarity
---@param minRarity number
---@param rng fun(n: number): number
---@return number|nil rarity nil when no weight is left
function Cards.rollRarity(weights, minRarity, rng)
  local total = 0
  for rarity = minRarity, 5 do total = total + (weights[rarity] or 0) end
  -- math.random(n) truncates n: a total below 1 would call math.random(0).
  if not (total >= 1) then return nil end
  local roll = rng(total)
  for rarity = minRarity, 5 do
    roll = roll - (weights[rarity] or 0)
    if roll <= 0 then return rarity end
  end
  return 5
end

---Closest rarity the pool has: the rolled one, else lower ones, else higher
---ones (never below `minRarity`).
local function availableRarity(pool, rarity, minRarity)
  for r = rarity, minRarity, -1 do
    if #pool.byRarity[r] > 0 then return r end
  end
  for r = rarity + 1, 5 do
    if #pool.byRarity[r] > 0 then return r end
  end
  return nil
end

-- Missing-card protection: with NEW_CARD_BIAS percent chance, a draw picks
-- among the cards of the rolled rarity the player does not own yet (and has
-- not drawn earlier in this pack), so a large zone stays completable.
local function drawCard(pool, minRarity, config, rng, isOwned, drawn)
  local rarity = Cards.rollRarity(config.RARITY_WEIGHTS, minRarity, rng)
  if not rarity then return nil end
  rarity = availableRarity(pool, rarity, minRarity)
  if not rarity then return nil end
  local bucket = pool.byRarity[rarity]
  local bias = config.NEW_CARD_BIAS
  if isOwned and type(bias) == "number" and bias > 0 then
    local missing = {}
    for _, card in ipairs(bucket) do
      if not isOwned(card.id) and not drawn[card.id] then missing[#missing + 1] = card end
    end
    if #missing > 0 and rng(100) <= bias then return missing[rng(#missing)] end
  end
  return bucket[rng(#bucket)]
end

---Rolls the cards of one pack. If no card reaches GUARANTEED_RARITY, the last
---card is re-rolled among rarities at or above it (when the pool has any).
---@param pool table from Cards.poolFor
---@param rng fun(n: number): number e.g. math.random
---@param config table ns.Config
---@param isOwned fun(cardID: string): boolean|nil enables the missing-card protection
---@return string[] cardIDs empty when the pool is empty
function Cards.openPack(pool, rng, config, isOwned)
  local ids, drawn = {}, {}
  if pool.size == 0 or not (config.CARDS_PER_PACK >= 1) then return ids end
  local best = 0
  for i = 1, config.CARDS_PER_PACK do
    local card = drawCard(pool, 1, config, rng, isOwned, drawn)
    if not card then return {} end -- degenerate weights: no pack rather than an error
    ids[i] = card.id
    drawn[card.id] = true
    if card.rarity > best then best = card.rarity end
  end
  local guaranteed = config.GUARANTEED_RARITY
  if RARITY_BONUS[guaranteed] and best < guaranteed then
    local card = drawCard(pool, guaranteed, config, rng, isOwned, drawn)
    if card then ids[#ids] = card.id end
  end
  return ids
end

---Test helper: forgets every registered zone.
function Cards._reset()
  byID, zones, zoneParents, batches = {}, {}, {}, {}
  Cards.dataLoaded = nil
end
