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

---Which Sound.KEYS exist in this client's SOUNDKIT table.
---@param env table _G or a test stub
---@return string[] lines
function Art.soundLines(env)
  local lines = {}
  local kit = type(env.SOUNDKIT) == "table" and env.SOUNDKIT or {}
  local events = {}
  for event in pairs(ns.Sound.KEYS) do events[#events + 1] = event end
  table.sort(events)
  for _, event in ipairs(events) do
    local parts = {}
    for _, name in ipairs(ns.Sound.KEYS[event]) do
      parts[#parts + 1] = name.." "..(type(kit[name]) == "number" and "present" or "MISSING")
    end
    lines[#lines + 1] = event..": "..table.concat(parts, ", ")
  end
  return lines
end

if ns.Slash then
  ns.Slash.register({
    name = "sounds",
    usage = "sounds",
    help = "Developer: check which card sounds exist on this client",
    handler = function()
      for _, line in ipairs(Art.soundLines(_G)) do print("  "..line) end
    end,
  })

  ns.Slash.register({
    name = "art",
    usage = "art",
    help = "Developer: show every card's icon to spot missing ones",
    handler = handleArt,
  })
end
