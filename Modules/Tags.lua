local _, ns = ...

-- Pure player tags and pins on cards.
-- Account-wide (db.global), like the collection:
-- tags   = { [cardID] = { [tag] = true } }  player tags, plus TRADE
-- pinned = { [cardID] = true }              pinned to the top of the binder
-- Tag text is typed by the player: it is normalized and validated here, and
-- only ever displayed with chat codes escaped (see Tags.display).

local type, pairs, ipairs, sort = type, pairs, ipairs, table.sort

local Tags = {}
ns.Tags = Tags

-- Built-in "For trade" tag. Player tags cannot start with "#", so it cannot
-- be typed.
Tags.TRADE = "#trade"
Tags.MAX_LENGTH = 24
Tags.MAX_PER_CARD = 5
Tags.MAX_DISTINCT = 20

-- UTF-8 byte patterns: U+00A0, U+2000-U+200F, U+2028-U+202F, U+2060-U+206F, U+FEFF.
local INVISIBLE_PATTERNS = {
  "\194\160",
  "\226\128[\128-\143]",
  "\226\128[\168-\175]",
  "\226\129[\160-\175]",
  "\239\187\191",
}

---Normalizes a tag typed by the player: trimmed, inner whitespace collapsed,
---lowercased (ASCII), 1..MAX_LENGTH bytes, no control characters, no "|" (WoW
---chat/escape codes) and not starting with "#" (reserved).
---@param text any
---@return string|nil tag nil when refused
function Tags.normalize(text)
  if type(text) ~= "string" then return nil end
  -- Control characters (newline, tab, NUL...) and "|" are refused before any
  -- whitespace folding, so a newline is never turned into a space.
  if text:find("[%c|]") then return nil end
  -- Invisible or direction-changing Unicode (no-break space, zero-width and
  -- bidi marks, word joiners, BOM): they would make two tags look the same.
  for _, invisible in ipairs(INVISIBLE_PATTERNS) do
    if text:find(invisible) then return nil end
  end
  text = text:gsub(" +", " "):match("^ ?(.-) ?$"):lower()
  if text == "" or #text > Tags.MAX_LENGTH then return nil end
  if text:sub(1, 1) == "#" then return nil end
  return text
end

local function isTag(tag)
  return tag == Tags.TRADE or Tags.normalize(tag) == tag
end

---Every distinct tag in use, player tags sorted, TRADE excluded.
---@param tags table char.tags
---@return string[]
function Tags.all(tags)
  local seen, list = {}, {}
  for _, cardTags in pairs(tags) do
    for tag in pairs(cardTags) do
      if tag ~= Tags.TRADE and not seen[tag] then
        seen[tag] = true
        list[#list + 1] = tag
      end
    end
  end
  sort(list)
  return list
end

---Player tags of one card, sorted (TRADE excluded).
function Tags.of(tags, cardID)
  local list = {}
  for tag in pairs(tags[cardID] or {}) do
    if tag ~= Tags.TRADE then list[#list + 1] = tag end
  end
  sort(list)
  return list
end

---@return boolean
function Tags.has(tags, cardID, tag)
  return tags[cardID] ~= nil and tags[cardID][tag] == true
end

local function setTag(tags, cardID, tag)
  local cardTags = tags[cardID]
  if not cardTags then
    cardTags = {}
    tags[cardID] = cardTags
  end
  cardTags[tag] = true
end

---Adds a tag typed by the player to a card. Player text only: the reserved
---TRADE tag is set through toggleTrade, never through here.
---@return boolean added
---@return string|nil reason "invalid", "card-full" or "too-many-tags"
function Tags.add(tags, cardID, text)
  local tag = Tags.normalize(text)
  if not tag then return false, "invalid" end
  if Tags.has(tags, cardID, tag) then return true end
  if #Tags.of(tags, cardID) >= Tags.MAX_PER_CARD then return false, "card-full" end
  local known = false
  local all = Tags.all(tags)
  for _, existing in ipairs(all) do
    if existing == tag then known = true break end
  end
  if not known and #all >= Tags.MAX_DISTINCT then return false, "too-many-tags" end
  setTag(tags, cardID, tag)
  return true
end

function Tags.remove(tags, cardID, tag)
  local cardTags = tags[cardID]
  if not cardTags then return end
  cardTags[tag] = nil
  if next(cardTags) == nil then tags[cardID] = nil end
end

---Toggles the For trade tag.
---@return boolean nowTagged
function Tags.toggleTrade(tags, cardID)
  if Tags.has(tags, cardID, Tags.TRADE) then
    Tags.remove(tags, cardID, Tags.TRADE)
    return false
  end
  setTag(tags, cardID, Tags.TRADE)
  return true
end

---Toggles a pin.
---@return boolean nowPinned
function Tags.togglePin(pinned, cardID)
  if pinned[cardID] then
    pinned[cardID] = nil
    return false
  end
  pinned[cardID] = true
  return true
end

---A tag made safe for a FontString: "|" is doubled. normalize() already
---refuses "|", so this only matters for a hand-edited save that slipped by.
function Tags.display(tag)
  return (tostring(tag):gsub("|", "||"))
end

---Sanitizes tags and pinned from SavedVariables in place: known cards only,
---valid tags only, and the per-card and distinct limits.
---@param char table db.global (named char before schema version 2)
---@param isKnownCard fun(cardID: any): any
---@param dataLoaded boolean unknown IDs are deleted only when Data loaded fully
function Tags.sanitize(char, isKnownCard, dataLoaded)
  local function keepCard(cardID)
    if isKnownCard(cardID) then return true end
    return not dataLoaded and type(cardID) == "string" and cardID ~= "" and #cardID <= 64
  end

  if type(char.tags) ~= "table" then char.tags = {} end
  local distinct = {}
  local distinctCount = 0
  for cardID, cardTags in pairs(char.tags) do
    if not keepCard(cardID) or type(cardTags) ~= "table" then
      char.tags[cardID] = nil
    else
      local count = 0
      for tag, flag in pairs(cardTags) do
        local ok = flag == true and type(tag) == "string" and isTag(tag)
        if ok and tag ~= Tags.TRADE then
          if count >= Tags.MAX_PER_CARD then
            ok = false
          elseif not distinct[tag] then
            if distinctCount >= Tags.MAX_DISTINCT then
              ok = false
            else
              distinct[tag] = true
              distinctCount = distinctCount + 1
            end
          end
          if ok then count = count + 1 end
        end
        if not ok then cardTags[tag] = nil end
      end
      if next(cardTags) == nil then char.tags[cardID] = nil end
    end
  end

  if type(char.pinned) ~= "table" then char.pinned = {} end
  for cardID, flag in pairs(char.pinned) do
    if flag ~= true or not keepCard(cardID) then char.pinned[cardID] = nil end
  end
end
