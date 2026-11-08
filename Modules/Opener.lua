local _, ns = ...

-- Shell for /wd open and /wd cards. Chat output for now; the reveal frame and
-- the binder UI come later (docs/FEATURES.md sections 3 and 4).

local L = ns.L
local Config, Cards, Collection, Zone, Wow, Walker = ns.Config, ns.Cards, ns.Collection, ns.Zone, ns.Wow, ns.Walker

local Opener = {}
ns.Opener = Opener

local function continentOf(zoneMapID)
  local getMapInfo = C_Map and C_Map.GetMapInfo
  if type(getMapInfo) ~= "function" then return nil end
  local ok, id = pcall(Zone.continentOf, zoneMapID, getMapInfo, Wow.isSecret)
  return ok and id or nil
end

---One chat line for a card: colored name, rarity, attack/defense, New tag.
---Card text comes from Data/ and the locale files, not from the game.
---@param card table registered card
---@param isNew boolean
---@return string
function Opener.cardLine(card, isNew)
  local line = "|c"..Cards.RARITY_COLORS[card.rarity]..L[card.name].."|r"
    .." ["..L[Cards.RARITY_NAMES[card.rarity]].."] "
    ..card.attack.."/"..card.defense
  if isNew then line = line.." |cff00ff00"..L["New!"].."|r" end
  return line
end

local function handleOpen()
  local db = ns.GetDB()
  if not db then return end
  local result, reason = Collection.openNext(db.char, math.random, continentOf, Config)
  if not result then
    ns.print(reason == "no-pack" and L["No pack to open. Keep walking!"] or L["No cards available for this pack."])
    return
  end
  ns.print(L["Pack from"].." "..Walker.zoneName(result.pack.zoneMapID)..":")
  for _, id in ipairs(result.cardIDs) do
    print("  "..Opener.cardLine(Cards.get(id), result.firstTime[id]))
  end
  ns.print(L["Unopened packs:"].." "..#db.char.packs)
end

local function handleCards()
  local db = ns.GetDB()
  if not db then return end
  local collection = db.char.collection
  local ownedAll, totalAll = 0, 0
  for _, zoneMapID in ipairs(Cards.zoneIDs()) do
    local owned, total = Collection.progress(collection, Cards.zoneCards(zoneMapID))
    ownedAll, totalAll = ownedAll + owned, totalAll + total
    print("  "..Walker.zoneName(zoneMapID)..": "..owned.." / "..total)
  end
  ns.print(L["Collection:"].." "..ownedAll.." / "..totalAll)
end

ns.Slash.register({
  name = "open",
  usage = "open",
  help = L["Open your oldest pack"],
  handler = handleOpen,
})

ns.Slash.register({
  name = "cards",
  usage = "cards",
  help = L["Show collection progress per zone"],
  handler = handleCards,
})
