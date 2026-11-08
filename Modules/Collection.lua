local _, ns = ...

-- Pure collection updates. char.collection = { [cardID] = copies },
-- char.newCards = { [cardID] = true } until the card is seen in the binder.

local ipairs = ipairs

local Collection = {}
ns.Collection = Collection

---Adds one copy of each card. A card owned for the first time is flagged new.
---@param collection table<string, number>
---@param newCards table<string, boolean>
---@param cardIDs string[]
---@param maxCopies number
---@return table<string, boolean> firstTime cards this call added for the first time
function Collection.add(collection, newCards, cardIDs, maxCopies)
  local firstTime = {}
  for _, id in ipairs(cardIDs) do
    local copies = collection[id] or 0
    if copies == 0 then
      newCards[id] = true
      firstTime[id] = true
    end
    if copies < maxCopies then collection[id] = copies + 1 end
  end
  return firstTime
end

---Owned and total distinct cards among `cards`.
---@param collection table<string, number>
---@param cards table[] e.g. Cards.zoneCards(zoneMapID)
---@return number owned, number total
function Collection.progress(collection, cards)
  local owned = 0
  for _, card in ipairs(cards) do
    if (collection[card.id] or 0) > 0 then owned = owned + 1 end
  end
  return owned, #cards
end

---Opens the oldest unopened pack: rolls its cards, adds them to the
---collection and removes the pack, all before anything is shown, so a
---/reload mid-reveal loses nothing.
---@param char table db.char
---@param rng fun(n: number): number
---@param continentOf fun(zoneMapID: number): number|nil
---@param config table ns.Config
---@return table|nil result { pack, cardIDs, firstTime } or nil
---@return string|nil reason "no-pack" or "empty-pool"
function Collection.openNext(char, rng, continentOf, config)
  local pack = char.packs[1]
  if not pack then return nil, "no-pack" end
  -- Packs saved before a city was folded still open as their outdoor zone.
  local zoneMapID = ns.Cards.cardZone(pack.zoneMapID)
  local pool = ns.Cards.poolFor(zoneMapID, continentOf(zoneMapID))
  local cardIDs = ns.Cards.openPack(pool, rng, config)
  if #cardIDs == 0 then return nil, "empty-pool" end
  table.remove(char.packs, 1)
  local firstTime = Collection.add(char.collection, char.newCards, cardIDs, config.MAX_COPIES)
  return { pack = pack, zoneMapID = zoneMapID, cardIDs = cardIDs, firstTime = firstTime, poolLevel = pool.level }, nil
end
