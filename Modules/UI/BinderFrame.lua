local _, ns = ...

-- The binder: zones on the left with their completion, the selected zone's
-- cards on the right as a 3x3 grid. Filters, rarity, search and paging come
-- from BinderModel; owned cards shown here lose their New flag.

local L = ns.L
local Cards, CardWidget, BinderModel, Window, Walker = ns.Cards, ns.CardWidget, ns.BinderModel, ns.Window, ns.Walker

local BinderFrame = {}
ns.BinderFrame = BinderFrame

local COLUMNS, ROWS = 3, 3
local PER_PAGE = COLUMNS * ROWS
local GAP = 8
local LIST_WIDTH = 180
local MAX_ZONE_BUTTONS = 14
local FILTER_LABELS = { all = "All", owned = "Owned", missing = "Missing", duplicates = "Duplicates" }

local frame, widgets, zoneButtons, filterButtons
local view = { zoneMapID = nil, filter = "all", rarity = nil, tag = nil, search = "", page = 1 }

local function tagLabel(tag)
  if tag == nil then return L["All tags"] end
  if tag == ns.Tags.TRADE then return L["For trade"] end
  return ns.Tags.display(tag)
end

local function char()
  local db = ns.GetDB()
  return db and db.char
end

local function render()
  local c = char()
  if not c then return end

  local zones = BinderModel.zoneList(Cards.zoneIDs(), Cards.zoneCards, c.collection)
  if not view.zoneMapID and zones[1] then view.zoneMapID = zones[1].zoneMapID end
  for i, button in ipairs(zoneButtons) do
    local zone = zones[i]
    if zone then
      button.zoneMapID = zone.zoneMapID
      button:SetText(Walker.zoneName(zone.zoneMapID).."  "..zone.owned.."/"..zone.total)
      button:SetEnabled(zone.zoneMapID ~= view.zoneMapID)
      button:Show()
    else
      button:Hide()
    end
  end

  for key, button in pairs(filterButtons) do button:SetEnabled(key ~= view.filter) end
  frame.rarity:SetText(view.rarity and L[Cards.RARITY_NAMES[view.rarity]] or L["All rarities"])
  -- A tag removed since it was chosen falls back to all tags.
  if view.tag ~= nil and view.tag ~= ns.Tags.TRADE then
    local stillUsed = false
    for _, tag in ipairs(ns.Tags.all(c.tags)) do
      if tag == view.tag then stillUsed = true break end
    end
    if not stillUsed then view.tag = nil end
  end
  frame.tag:SetText(tagLabel(view.tag))

  local entries = BinderModel.entries(Cards.zoneCards(view.zoneMapID), c.collection, c.newCards, {
    filter = view.filter, rarity = view.rarity, search = view.search,
    localize = function(key) return L[key] end,
    nameOf = function(card) return ns.CardText.name(card) end,
    tags = c.tags, tag = view.tag, pinned = c.pinned,
  })
  local shown, page, pageCount = BinderModel.page(entries, view.page, PER_PAGE)
  view.page = page

  for i, w in ipairs(widgets) do
    local entry = shown[i]
    w.entry = entry
    if not entry then
      w:Hide()
    elseif entry.copies > 0 then
      CardWidget.showCard(w, entry.card, { copies = entry.copies, isNew = entry.isNew, pinned = entry.pinned })
    else
      CardWidget.showMissing(w, entry.card)
    end
  end
  frame.pageText:SetText(page.." / "..pageCount)
  frame.prev:SetEnabled(page > 1)
  frame.next:SetEnabled(page < pageCount)
  frame.empty:SetShown(#shown == 0)

  -- Last, and only while the frame is visible (IsVisible is false with the UI
  -- hidden by Alt+Z): a card loses its New tag once the player could see it.
  if frame:IsVisible() then BinderModel.markSeen(c.newCards, shown) end
end

local GRID_TOP = 114
-- Rows get 6 extra pixels so a card's New tag never overlaps the card above.
local ROW_STEP = CardWidget.HEIGHT + GAP + 6
local PAGER_GAP = 18
local PAGER_HEIGHT = 22

local function build()
  local gridWidth = COLUMNS * CardWidget.WIDTH + (COLUMNS - 1) * GAP
  local gridHeight = (ROWS - 1) * ROW_STEP + CardWidget.HEIGHT
  local pagerTop = GRID_TOP + gridHeight + PAGER_GAP
  frame = Window.create("WanderDeckBinder", L["Binder"], LIST_WIDTH + gridWidth + 70, pagerTop + PAGER_HEIGHT + 22)

  zoneButtons = {}
  for i = 1, MAX_ZONE_BUTTONS do
    local b = Window.button(frame, "", LIST_WIDTH)
    b:SetPoint("TOPLEFT", 20, -50 - (i - 1) * 26)
    b:SetScript("OnClick", function(self)
      view.zoneMapID, view.page = self.zoneMapID, 1
      render()
    end)
    zoneButtons[i] = b
  end

  local left = LIST_WIDTH + 40
  filterButtons = {}
  local x = left
  for _, key in ipairs(BinderModel.FILTERS) do
    local b = Window.button(frame, L[FILTER_LABELS[key]], 84)
    b:SetPoint("TOPLEFT", x, -46)
    b:SetScript("OnClick", function()
      view.filter, view.page = key, 1
      render()
    end)
    filterButtons[key] = b
    x = x + 88
  end

  frame.rarity = Window.button(frame, "", 120)
  frame.rarity:SetPoint("TOPLEFT", left, -72)
  frame.rarity:SetScript("OnClick", function()
    -- Cycles All -> Common -> ... -> Legendary -> All.
    if view.rarity == nil then view.rarity = 1 elseif view.rarity >= 5 then view.rarity = nil else view.rarity = view.rarity + 1 end
    view.page = 1
    render()
  end)

  frame.tag = Window.button(frame, "", 120)
  frame.tag:SetPoint("TOPLEFT", left + 128, -72)
  frame.tag:SetScript("OnClick", function()
    local c = char()
    if not c then return end
    view.tag, view.page = BinderModel.nextTag(c.tags, view.tag), 1
    render()
  end)

  frame.search = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
  frame.search:SetSize(112, 20)
  frame.search:SetPoint("TOPLEFT", left + 262, -73)
  frame.search:SetAutoFocus(false)
  frame.search:SetMaxLetters(BinderModel.SEARCH_MAX_LENGTH)
  frame.search:SetScript("OnTextChanged", function(self)
    view.search, view.page = self:GetText(), 1
    render()
  end)
  frame.search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

  widgets = {}
  for i = 1, PER_PAGE do
    local col, row = (i - 1) % COLUMNS, math.floor((i - 1) / COLUMNS)
    local w = CardWidget.create(frame)
    w:SetPoint("TOPLEFT", left + col * (CardWidget.WIDTH + GAP), -GRID_TOP - row * ROW_STEP)
    -- Owned cards open the detail window; missing cards stay silhouettes.
    w:SetScript("OnClick", function(self)
      local entry = self.entry
      if type(entry) == "table" and entry.copies > 0 then
        ns.CardDetail.show(entry.card, entry.copies, { onChange = function() pcall(render) end })
      end
    end)
    widgets[i] = w
  end

  frame.empty = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  frame.empty:SetPoint("TOPLEFT", left, -130)
  frame.empty:SetText(L["No cards match."])

  -- Pager row, PAGER_GAP below the last card row.
  frame.prev = Window.button(frame, "<", 40)
  frame.prev:SetPoint("TOPLEFT", left, -pagerTop)
  frame.prev:SetScript("OnClick", function() view.page = view.page - 1 render() end)
  frame.next = Window.button(frame, ">", 40)
  frame.next:SetPoint("TOPLEFT", left + gridWidth - 40, -pagerTop)
  frame.next:SetScript("OnClick", function() view.page = view.page + 1 render() end)
  frame.pageText = ns.Draw.text(frame, "GameFontHighlight", ns.Draw.COLORS.parchment)
  frame.pageText:SetPoint("TOP", frame, "TOPLEFT", left + gridWidth / 2, -pagerTop - 4)
end

---Redraws the binder if it is open (e.g. once an item card's name loads).
function BinderFrame.refreshIfShown()
  if frame and frame:IsShown() then render() end
end

---Test hook: the frame, card widgets, zone buttons and view state.
function BinderFrame._debug() return frame, widgets, zoneButtons, view end

local broken

---Builds the frame once. A build that fails partway marks the binder broken
---instead of leaving a half-built frame that later calls would draw into.
local function ensureBuilt()
  if broken then error("WanderDeck binder failed to build earlier", 0) end
  if frame then return end
  local ok, err = pcall(build)
  if not ok then
    broken = true
    if frame then frame:Hide() end
    error(err, 0)
  end
end

function BinderFrame.toggle()
  if not char() then return end
  ensureBuilt()
  if frame:IsShown() then
    frame:Hide()
    return
  end
  frame:Show()
  local ok, err = pcall(render)
  if not ok then
    frame:Hide()
    error(err, 0)
  end
end
