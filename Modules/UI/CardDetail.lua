local _, ns = ...

-- Detail window: one card shown large, with its flavor text and copy count.
-- Opened by clicking an owned card in the binder or a revealed card in the
-- pack opening. Only owned or just-revealed cards reach it, so it never shows
-- a missing card.

local L = ns.L
local CardWidget, Window, Draw = ns.CardWidget, ns.Window, ns.Draw
local C = Draw.COLORS

local CardDetail = {}
ns.CardDetail = CardDetail

local SCALE = 1.6
local WIDTH = math.floor(CardWidget.WIDTH * SCALE) + 80
local CARD_TOP = 52

local frame, big, flavor, owned

local function build()
  frame = Window.create("WanderDeckCardDetail", "", WIDTH, CARD_TOP + CardWidget.HEIGHT * SCALE + 130)
  frame:SetFrameStrata("FULLSCREEN_DIALOG")

  big = CardWidget.create(frame)
  big:SetScale(SCALE)
  -- Offsets of a scaled child are in its own (scaled) units.
  big:SetPoint("TOP", frame, "TOP", 0, -CARD_TOP / SCALE)

  flavor = Draw.text(frame, "GameFontHighlight", C.parchment)
  flavor:SetPoint("TOP", frame, "TOP", 0, -(CARD_TOP + CardWidget.HEIGHT * SCALE + 18))
  flavor:SetWidth(WIDTH - 50)
  flavor:SetJustifyH("CENTER")
  flavor:SetWordWrap(true)

  owned = Draw.text(frame, "GameFontDisableSmall", C.muted)
  owned:SetPoint("BOTTOM", 0, 18)
end

---Test hook: the frame, the large card and the flavor text.
function CardDetail._debug() return frame, big, flavor, owned end

---@param card table registered card
---@param copies number|nil copies owned (shown when > 0)
function CardDetail.show(card, copies)
  if not frame then build() end
  frame.title:SetText(L[card.name])
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
  frame:Show()
  frame:Raise()
end

function CardDetail.hide()
  if frame then frame:Hide() end
end
