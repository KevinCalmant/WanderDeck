local _, ns = ...

-- Display name and icon of a card. A card with an itemID, questID or areaID
-- takes its name from the client (already in the player's language) and an
-- item card takes its real icon; anything missing, secret or odd falls back
-- to the card's own localized name and icon from Data/.

local type, pcall = type, pcall

local CardText = {}
ns.CardText = CardText

local NAME_MAX_LENGTH = 64

-- Items already asked for this session: an item that never loads (bad ID)
-- is not requested again on every render.
local requested = {}

---Client text made safe for a FontString or chat line, or nil: not secret,
---a string with a non-space, at most NAME_MAX_LENGTH bytes, well-formed
---UTF-8 without control or invisible characters; then "|" is doubled.
local function clientText(value)
  if ns.Wow.isSecret(value) or type(value) ~= "string" then return nil end
  if not value:find("%S") or #value > NAME_MAX_LENGTH or not ns.Utils.isCleanText(value) then return nil end
  return (value:gsub("|", "||"))
end

local function clientName(card, env)
  if card.itemID then
    local C_Item = env.C_Item
    if type(C_Item) ~= "table" or type(C_Item.GetItemNameByID) ~= "function" then return nil end
    local name = C_Item.GetItemNameByID(card.itemID)
    -- Not cached yet: ask the client once to load it (ITEM_DATA_LOAD_RESULT
    -- then refreshes the UI).
    if name == nil and not requested[card.itemID] and type(C_Item.RequestLoadItemDataByID) == "function" then
      requested[card.itemID] = true
      C_Item.RequestLoadItemDataByID(card.itemID)
    end
    return name
  elseif card.questID then
    local C_QuestLog = env.C_QuestLog
    if type(C_QuestLog) ~= "table" or type(C_QuestLog.GetTitleForQuestID) ~= "function" then return nil end
    return C_QuestLog.GetTitleForQuestID(card.questID)
  elseif card.areaID then
    local C_Map = env.C_Map
    if type(C_Map) ~= "table" or type(C_Map.GetAreaInfo) ~= "function" then return nil end
    return C_Map.GetAreaInfo(card.areaID)
  end
  return nil
end

---True when CardText asked the client for this item.
function CardText.wasRequested(itemID)
  return requested[itemID] == true
end

local refreshPending = false

---Handles ITEM_DATA_LOAD_RESULT: the event fires for every item the client
---loads (bags, loot, other addons), so only a successful load of an item this
---addon requested triggers a refresh, and a burst of them refreshes once.
---@param itemID any
---@param success any
---@param after fun(delay: number, fn: fun())|nil C_Timer.After
---@param refresh fun() ns.refreshUI
---@return boolean scheduled
function CardText.onItemDataLoaded(itemID, success, after, refresh)
  local isSecret = ns.Wow.isSecret
  if isSecret(itemID) or isSecret(success) then return false end
  if success ~= true or not CardText.wasRequested(itemID) then return false end
  if refreshPending then return false end
  if type(after) ~= "function" then
    refresh()
    return true
  end
  refreshPending = true
  local ok = pcall(after, 0, function()
    refreshPending = false
    refresh()
  end)
  -- A timer that fails must not block refreshes for the rest of the session.
  if not ok then refreshPending = false end
  return ok
end

---Name to display for a card.
---@param card table registered card
---@param env table|nil _G or a test stub
---@return string
function CardText.name(card, env)
  local ok, name = pcall(clientName, card, env or _G)
  -- A translation goes through the same checks as client text; a bad one
  -- falls back to the validated English name.
  return (ok and clientText(name)) or clientText(ns.L[card.name]) or card.name
end

---Flavor text for a card: its own (localized) text, or one built from its
---facts for generated cards, e.g. "Level 5 · Beast" ("Niveau 5 · Bête").
---@param card table registered card
---@return string
function CardText.flavor(card)
  local L = ns.L
  if card.flavor then return L[card.flavor] end
  local parts = {}
  if card.level then parts[#parts + 1] = L["Level"].." "..card.level end
  if card.creatureType then parts[#parts + 1] = L[card.creatureType] end
  return table.concat(parts, " · ")
end

---Texture for a card's art: the client's item icon (a file ID) for an item
---card when available, else the card's Interface\Icons path.
---@return number|string
function CardText.icon(card, env)
  env = env or _G
  if card.itemID then
    local C_Item = env.C_Item
    local ok, fileID = pcall(function()
      if type(C_Item) == "table" and type(C_Item.GetItemIconByID) == "function" then
        return C_Item.GetItemIconByID(card.itemID)
      end
    end)
    if ok and not ns.Wow.isSecret(fileID) and ns.Utils.isMapID(fileID) then return fileID end
  end
  return ns.Cards.iconPath(card)
end
