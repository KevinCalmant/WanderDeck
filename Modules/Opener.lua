local _, ns = ...

-- Shell for /wd open, /wd binder and /wd cards. Opening shows the reveal
-- frame; if the frame fails to build, the cards go to chat instead.

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

---Hands a caught UI error to the client's error handler (the Lua error frame
---or BugSack), so a fallback still leaves a trace to debug.
function Opener.reportError(err)
  local get = _G.geterrorhandler
  local handler = type(get) == "function" and get()
  if type(handler) == "function" then pcall(handler, err) end
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

local function printResult(result, zoneName, packsLeft)
  ns.print(L["Pack from"].." "..zoneName..":")
  for _, id in ipairs(result.cardIDs) do
    print("  "..Opener.cardLine(Cards.get(id), result.firstTime[id]))
  end
  ns.print(L["Unopened packs:"].." "..packsLeft)
end

local handleOpen

local function packsLeft()
  local db = ns.GetDB()
  return db and #db.char.packs or 0
end

handleOpen = function()
  local db = ns.GetDB()
  if not db then return end
  -- The pack is consumed and its cards saved here, before any display.
  local result, reason = Collection.openNext(db.char, math.random, continentOf, Config)
  if not result then
    ns.print(reason == "no-pack" and L["No pack to open. Keep walking!"] or L["No cards available for this pack."])
    return
  end
  local zoneName = Walker.zoneName(result.pack.zoneMapID)
  -- The closure keeps a missing RevealFrame module inside the protection.
  local function copiesOf(cardID)
    local current = ns.GetDB()
    return current and current.char.collection[cardID]
  end
  local ok, err = pcall(function() return ns.RevealFrame.show(result, zoneName, handleOpen, packsLeft, copiesOf) end)
  if not ok then
    Opener.reportError(err)
    printResult(result, zoneName, packsLeft())
  end
end

local function handleBinder()
  local ok, err = pcall(function() return ns.BinderFrame.toggle() end)
  if not ok then
    Opener.reportError(err)
    ns.print(L["The binder could not open. Use /wd cards."])
  end
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
  name = "binder",
  usage = "binder",
  help = L["Open or close the binder"],
  handler = handleBinder,
})

ns.Slash.register({
  name = "cards",
  usage = "cards",
  help = L["Show collection progress per zone"],
  handler = handleCards,
})
