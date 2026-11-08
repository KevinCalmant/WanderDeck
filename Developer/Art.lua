local _, ns = ...

-- Developer-only (excluded from releases). /wd art prints every card with its
-- icon inline, so a missing icon (empty or green square) on this client shows
-- at a glance. Icon names are validated in Cards.registerZone (letters,
-- digits, _), so the inline texture code cannot carry anything else.

local Art = {}
ns.Art = Art

---One chat line: inline icon, card ID and icon name.
---@param card table registered card
---@return string
function Art.line(card)
  return "|T"..ns.Cards.iconPath(card)..":20:20|t "..card.id.."  ("..card.icon..")"
end

local function handleArt()
  local count = 0
  for _, zoneMapID in ipairs(ns.Cards.zoneIDs()) do
    for _, card in ipairs(ns.Cards.zoneCards(zoneMapID)) do
      print("  "..Art.line(card))
      count = count + 1
    end
  end
  ns.print(count.." cards. An empty or green square means that icon does not exist on this client.")
end

if ns.Slash then
  ns.Slash.register({
    name = "art",
    usage = "art",
    help = "Developer: show every card's icon to spot missing ones",
    handler = handleArt,
  })
end
