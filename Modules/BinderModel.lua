local _, ns = ...

-- Pure data behind the binder: which cards a zone page shows, filters,
-- search and paging. The frame (Modules/UI/BinderFrame.lua) only draws it.

local type, ipairs, floor, max, min = type, ipairs, math.floor, math.max, math.min

local BinderModel = {}
ns.BinderModel = BinderModel

BinderModel.FILTERS = { "all", "owned", "missing", "duplicates" }
local VALID_FILTERS = { all = true, owned = true, missing = true, duplicates = true }
BinderModel.SEARCH_MAX_LENGTH = 40

---Normalizes search box text: trimmed, lowercased, at most SEARCH_MAX_LENGTH
---bytes. It is only ever used as a plain substring (never a Lua pattern).
---@param text any
---@return string
function BinderModel.normalizeSearch(text)
  if type(text) ~= "string" then return "" end
  text = text:match("^%s*(.-)%s*$"):lower()
  if #text > BinderModel.SEARCH_MAX_LENGTH then text = text:sub(1, BinderModel.SEARCH_MAX_LENGTH) end
  return text
end

local function passesFilter(filter, copies)
  if filter == "owned" then return copies > 0 end
  if filter == "missing" then return copies == 0 end
  if filter == "duplicates" then return copies > 1 end
  return true
end

---Cards of one zone as binder entries, rarest first (data order within a
---rarity).
---@param cards table[] Cards.zoneCards(zoneMapID)
---@param collection table<string, number>
---@param newCards table<string, boolean>
---@param opts table|nil { filter = "all"|"owned"|"missing"|"duplicates", rarity = 1-5|nil, search = string, localize = fun(key): string, tags = char.tags, tag = string|nil, pinned = char.pinned }
---@return table[] entries { card, copies, isNew, pinned }, pinned cards first
function BinderModel.entries(cards, collection, newCards, opts)
  opts = opts or {}
  local filter = VALID_FILTERS[opts.filter] and opts.filter or "all"
  local search = BinderModel.normalizeSearch(opts.search)
  local localize = opts.localize or function(key) return key end
  -- Display name used for search (CardText.name in game, so a client-supplied
  -- item or quest name is searchable too).
  local nameOf = opts.nameOf or function(card) return localize(card.name) end
  local tags, pinned = opts.tags or {}, opts.pinned or {}

  local pinnedEntries, others = {}, {}
  local order = {}
  for index, card in ipairs(cards) do
    order[card] = index
    local copies = collection[card.id] or 0
    local keep = passesFilter(filter, copies)
      and (opts.rarity == nil or card.rarity == opts.rarity)
    if keep and search ~= "" then
      -- Missing cards are silhouettes: searching must not reveal their names.
      keep = copies > 0 and nameOf(card):lower():find(search, 1, true) ~= nil
    end
    if keep and opts.tag ~= nil then
      -- Tags only make sense on owned cards.
      keep = copies > 0 and ns.Tags.has(tags, card.id, opts.tag)
    end
    if keep then
      local isPinned = copies > 0 and pinned[card.id] == true
      local entry = { card = card, copies = copies, isNew = newCards[card.id] == true, pinned = isPinned }
      local list = isPinned and pinnedEntries or others
      list[#list + 1] = entry
    end
  end
  -- Rarest first, data order within a rarity (table.sort is not stable).
  local function rarerFirst(a, b)
    local ra, rb = tonumber(a.card.rarity) or 0, tonumber(b.card.rarity) or 0
    if ra ~= rb then return ra > rb end
    return order[a.card] < order[b.card]
  end
  table.sort(pinnedEntries, rarerFirst)
  table.sort(others, rarerFirst)
  for _, entry in ipairs(others) do pinnedEntries[#pinnedEntries + 1] = entry end
  return pinnedEntries
end

---Tag filter choices for the binder, in cycle order: none, For trade, then
---player tags sorted.
---@param tags table char.tags
---@return table[] { tag = string|nil }
function BinderModel.tagChoices(tags)
  local choices = { { tag = nil }, { tag = ns.Tags.TRADE } }
  for _, tag in ipairs(ns.Tags.all(tags)) do choices[#choices + 1] = { tag = tag } end
  return choices
end

---Next tag filter after `current` (wraps to none; an unknown tag restarts).
function BinderModel.nextTag(tags, current)
  local choices = BinderModel.tagChoices(tags)
  for i, choice in ipairs(choices) do
    if choice.tag == current then
      return (choices[i + 1] or choices[1]).tag
    end
  end
  return nil
end

---One page of entries.
---@param entries table[]
---@param page any requested page; clamped to 1..pageCount
---@param perPage number
---@return table[] slice, number page, number pageCount
function BinderModel.page(entries, page, perPage)
  local pageCount = max(1, floor((#entries + perPage - 1) / perPage))
  if type(page) ~= "number" or page ~= page then page = 1 end
  page = min(max(floor(page), 1), pageCount)
  local slice = {}
  for i = (page - 1) * perPage + 1, min(page * perPage, #entries) do
    slice[#slice + 1] = entries[i]
  end
  return slice, page, pageCount
end

---Clears the New flag of the owned cards on screen, once they have been shown.
---@param newCards table<string, boolean>
---@param shown table[] entries from BinderModel.page
function BinderModel.markSeen(newCards, shown)
  for _, entry in ipairs(shown) do
    if entry.isNew and entry.copies > 0 then newCards[entry.card.id] = nil end
  end
end

---Zones for the binder's side list with their completion, grouped by
---continent (lowest continent uiMapID first), then by display name.
---@param zoneIDs number[] Cards.zoneIDs()
---@param cardsOf fun(zoneMapID: number): table[] Cards.zoneCards
---@param collection table<string, number>
---@param opts table|nil { continentOf = fun(id): number|nil, nameOf = fun(id): string }
---@return table[] { zoneMapID, continentMapID, name, owned, total }
function BinderModel.zoneList(zoneIDs, cardsOf, collection, opts)
  opts = opts or {}
  local list = {}
  for _, zoneMapID in ipairs(zoneIDs) do
    local owned, total = ns.Collection.progress(collection, cardsOf(zoneMapID))
    local continent = opts.continentOf and opts.continentOf(zoneMapID)
    local name = opts.nameOf and opts.nameOf(zoneMapID)
    list[#list + 1] = {
      zoneMapID = zoneMapID, owned = owned, total = total,
      continentMapID = type(continent) == "number" and continent or 0,
      name = type(name) == "string" and name:find("%S") and name or tostring(zoneMapID),
    }
  end
  table.sort(list, function(a, b)
    if a.continentMapID ~= b.continentMapID then return a.continentMapID < b.continentMapID end
    if a.name ~= b.name then return a.name < b.name end
    return a.zoneMapID < b.zoneMapID
  end)
  return list
end

---Splits the zone list into pages of at most perPage zones, never mixing
---two continents on one page.
---@param list table[] from BinderModel.zoneList (sorted by continent)
---@param perPage number
---@return table[] pages { continentMapID, zones = { ... } }
function BinderModel.zonePages(list, perPage)
  perPage = math.max(1, math.floor(tonumber(perPage) or 1))
  local pages, current = {}, nil
  for _, zone in ipairs(list) do
    if not current or current.continentMapID ~= zone.continentMapID or #current.zones >= perPage then
      current = { continentMapID = zone.continentMapID, zones = {} }
      pages[#pages + 1] = current
    end
    current.zones[#current.zones + 1] = zone
  end
  return pages
end

---Index of the page that lists zoneMapID, or 1.
---@param pages table[] from BinderModel.zonePages
---@param zoneMapID number|nil
---@return number
function BinderModel.pageOfZone(pages, zoneMapID)
  for i, page in ipairs(pages) do
    for _, zone in ipairs(page.zones) do
      if zone.zoneMapID == zoneMapID then return i end
    end
  end
  return 1
end
