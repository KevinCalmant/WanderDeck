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

---Cards of one zone as binder entries, in data order.
---@param cards table[] Cards.zoneCards(zoneMapID)
---@param collection table<string, number>
---@param newCards table<string, boolean>
---@param opts table|nil { filter = "all"|"owned"|"missing"|"duplicates", rarity = 1-5|nil, search = string, localize = fun(key): string }
---@return table[] entries { card, copies, isNew }
function BinderModel.entries(cards, collection, newCards, opts)
  opts = opts or {}
  local filter = VALID_FILTERS[opts.filter] and opts.filter or "all"
  local search = BinderModel.normalizeSearch(opts.search)
  local localize = opts.localize or function(key) return key end

  local result = {}
  for _, card in ipairs(cards) do
    local copies = collection[card.id] or 0
    local keep = passesFilter(filter, copies)
      and (opts.rarity == nil or card.rarity == opts.rarity)
    if keep and search ~= "" then
      -- Missing cards are silhouettes: searching must not reveal their names.
      keep = copies > 0 and localize(card.name):lower():find(search, 1, true) ~= nil
    end
    if keep then
      result[#result + 1] = { card = card, copies = copies, isNew = newCards[card.id] == true }
    end
  end
  return result
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

---Zones for the binder's side list with their completion.
---@param zoneIDs number[] Cards.zoneIDs()
---@param cardsOf fun(zoneMapID: number): table[] Cards.zoneCards
---@param collection table<string, number>
---@return table[] { zoneMapID, owned, total }
function BinderModel.zoneList(zoneIDs, cardsOf, collection)
  local list = {}
  for _, zoneMapID in ipairs(zoneIDs) do
    local owned, total = ns.Collection.progress(collection, cardsOf(zoneMapID))
    list[#list + 1] = { zoneMapID = zoneMapID, owned = owned, total = total }
  end
  return list
end
