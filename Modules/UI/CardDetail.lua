local _, ns = ...

-- Detail window: one card shown large, with its flavor text and copy count.
-- Opened by clicking an owned card in the binder or a revealed card in the
-- pack opening. Only owned or just-revealed cards reach it, so it never shows
-- a missing card. For an owned card it also manages pin, For trade and the
-- player's tags (Tags module).

local L = ns.L
local CardWidget, Window, Draw, Tags = ns.CardWidget, ns.Window, ns.Draw, ns.Tags
local C = Draw.COLORS

local CardDetail = {}
ns.CardDetail = CardDetail

local SCALE = 1.6
local WIDTH = math.floor(CardWidget.WIDTH * SCALE) + 80
local CARD_TOP = 52
local FLAVOR_TOP = CARD_TOP + CardWidget.HEIGHT * SCALE + 14
local CONTROLS_TOP = FLAVOR_TOP + 52

local frame, big, flavor, owned
local controls = {}
local current -- { card, onChange }

local function char()
  local db = ns.GetDB and ns.GetDB()
  return db and db.char
end

local TAG_ERRORS = {
  invalid = "Tags are short (24 letters, fewer with accents), without pipes or invisible characters, and cannot start with #.",
  ["card-full"] = "A card can have up to 5 tags.",
  ["too-many-tags"] = "You can use up to 20 different tags.",
}

local function renderControls()
  local c = char()
  local card = current and current.card
  local show = c ~= nil and card ~= nil and (c.collection[card.id] or 0) > 0
  for _, part in ipairs(controls.all) do part:SetShown(show) end
  if not show then return end

  controls.pin:SetText(c.pinned[card.id] and L["Unpin"] or L["Pin"])
  controls.trade:SetText(Tags.has(c.tags, card.id, Tags.TRADE) and L["Not for trade"] or L["For trade"])
  local cardTags = Tags.of(c.tags, card.id)
  for i, chip in ipairs(controls.chips) do
    local tag = cardTags[i]
    chip.tagValue = tag
    if tag then
      chip:SetText(Tags.display(tag).."  x")
      chip:Show()
    else
      chip:Hide()
    end
  end
end

local function changed()
  renderControls()
  if current and current.onChange then current.onChange() end
end

local function build()
  -- Height: pin/trade row, three rows of tag chips, hint, input, copies line.
  frame = Window.create("WanderDeckCardDetail", "", WIDTH, CONTROLS_TOP + 175)
  frame:SetFrameStrata("FULLSCREEN_DIALOG")

  big = CardWidget.create(frame)
  big:SetScale(SCALE)
  -- Offsets of a scaled child are in its own (scaled) units.
  big:SetPoint("TOP", frame, "TOP", 0, -CARD_TOP / SCALE)

  flavor = Draw.text(frame, "GameFontHighlight", C.parchment)
  flavor:SetPoint("TOP", frame, "TOP", 0, -FLAVOR_TOP)
  flavor:SetWidth(WIDTH - 50)
  flavor:SetJustifyH("CENTER")
  flavor:SetWordWrap(true)

  owned = Draw.text(frame, "GameFontDisableSmall", C.muted)
  owned:SetPoint("BOTTOM", 0, 14)

  controls.pin = Window.button(frame, "", 110)
  controls.pin:SetPoint("TOPLEFT", 25, -CONTROLS_TOP)
  controls.pin:SetScript("OnClick", function()
    local c = char()
    if c and current then
      Tags.togglePin(c.pinned, current.card.id)
      changed()
    end
  end)

  controls.trade = Window.button(frame, "", 110)
  controls.trade:SetPoint("TOPRIGHT", -25, -CONTROLS_TOP)
  controls.trade:SetScript("OnClick", function()
    local c = char()
    if c and current then
      Tags.toggleTrade(c.tags, current.card.id)
      changed()
    end
  end)

  -- Tag chips: click one to remove that tag.
  controls.chips = {}
  for i = 1, Tags.MAX_PER_CARD do
    local chip = Window.button(frame, "", (WIDTH - 60) / 2)
    local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
    chip:SetPoint("TOPLEFT", 25 + col * ((WIDTH - 60) / 2 + 10), -(CONTROLS_TOP + 28 + row * 24))
    chip:SetScript("OnClick", function(self)
      local c = char()
      if c and current and self.tagValue then
        Tags.remove(c.tags, current.card.id, self.tagValue)
        changed()
      end
    end)
    controls.chips[i] = chip
  end

  controls.input = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
  controls.input:SetSize(WIDTH - 60, 20)
  controls.input:SetPoint("BOTTOM", 0, 34)
  controls.input:SetAutoFocus(false)
  controls.input:SetMaxLetters(Tags.MAX_LENGTH)
  controls.input:SetScript("OnEnterPressed", function(self)
    local c = char()
    if c and current then
      local ok, reason = Tags.add(c.tags, current.card.id, self:GetText())
      if ok then
        self:SetText("")
        changed()
      else
        ns.print(L[TAG_ERRORS[reason] or TAG_ERRORS.invalid])
      end
    end
    self:ClearFocus()
  end)
  controls.input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

  controls.hint = Draw.text(frame, "GameFontDisableSmall", C.muted)
  controls.hint:SetPoint("BOTTOM", controls.input, "TOP", 0, 2)
  controls.hint:SetText(L["Add a tag (Enter)"])

  controls.all = { controls.pin, controls.trade, controls.input, controls.hint }
  for _, chip in ipairs(controls.chips) do controls.all[#controls.all + 1] = chip end
end

---Test hook: the frame, the large card, the flavor text, the copies line and the controls.
function CardDetail._debug() return frame, big, flavor, owned, controls end

---@param card table registered card
---@param copies number|nil copies owned (shown when a whole positive number)
---@param opts table|nil { onChange = fun() } called after a pin or tag change
function CardDetail.show(card, copies, opts)
  if not frame then build() end
  current = { card = card, onChange = opts and opts.onChange }
  frame.title:SetText(ns.CardText.name(card))
  frame.title:SetTextColor(CardWidget.rarityRGB(card.rarity))
  CardWidget.showCard(big, card)
  flavor:SetText(L[card.flavor])
  -- Only a whole positive count is shown (anything else hides the line).
  if type(copies) == "number" and copies >= 1 and copies == math.floor(copies) and copies < math.huge then
    owned:SetText(L["Copies owned:"].." "..copies)
    owned:Show()
  else
    owned:Hide()
  end
  renderControls()
  frame:Show()
  frame:Raise()
end

function CardDetail.hide()
  if frame then frame:Hide() end
end
