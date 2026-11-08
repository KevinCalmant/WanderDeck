local _, ns = ...

-- Developer-only (excluded from releases). /wd fx opens the pack window on a
-- fake pack of real cards so the reveal effects can be watched at will. The
-- fake pack is never saved: no collection, New flag or pack count changes.

local RevealTest = {}
ns.RevealTest = RevealTest

RevealTest.MODES = {
  mix = { 1, 2, 3, 4, 5 },
  epic = { 4, 4, 4, 4, 4 },
  legendary = { 5, 5, 5, 5, 5 },
}

---Card IDs for a fake pack: for each wanted rarity, the next registered card
---of that rarity (zones in ID order, cards in data order), cycling when a
---rarity has fewer cards than asked. Unknown modes fall back to "mix".
---@param mode string|nil "mix", "epic" or "legendary"
---@param zoneIDs number[] Cards.zoneIDs()
---@param cardsOf fun(zoneMapID: number): table[] Cards.zoneCards
---@return string[] cardIDs
function RevealTest.pick(mode, zoneIDs, cardsOf)
  local rarities = RevealTest.MODES[mode] or RevealTest.MODES.mix
  local byRarity = {}
  for _, zoneMapID in ipairs(zoneIDs) do
    for _, card in ipairs(cardsOf(zoneMapID)) do
      local list = byRarity[card.rarity] or {}
      list[#list + 1] = card.id
      byRarity[card.rarity] = list
    end
  end
  local used, ids = {}, {}
  for _, rarity in ipairs(rarities) do
    local list = byRarity[rarity]
    if list then
      used[rarity] = (used[rarity] or 0) % #list + 1
      ids[#ids + 1] = list[used[rarity]]
    end
  end
  return ids
end

local function handleFx(rest)
  local mode = (rest or ""):lower()
  if not RevealTest.MODES[mode] then mode = "mix" end
  local ids = RevealTest.pick(mode, ns.Cards.zoneIDs(), ns.Cards.zoneCards)
  if #ids == 0 then
    ns.print("No cards loaded.")
    return
  end
  local function again() handleFx(mode) end
  ns.RevealFrame.show({ cardIDs = ids, firstTime = {} }, "Test ("..mode..")", again,
    function() return 1 end, function() return nil end)
end

if ns.Slash then
  ns.Slash.register({
    name = "fx",
    usage = "fx [mix||epic||legendary]",
    help = "Developer: open a fake pack (not saved) to watch the reveal effects",
    handler = handleFx,
  })
end
