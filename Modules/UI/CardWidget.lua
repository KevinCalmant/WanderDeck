local _, ns = ...

-- One card on screen: face up, face down (reveal) or a silhouette (missing
-- from the binder). Text comes from Data/ and the locale files only.

local L = ns.L
local Cards = ns.Cards

local CardWidget = {}
ns.CardWidget = CardWidget

CardWidget.WIDTH, CardWidget.HEIGHT = 110, 150

local BACKDROP = {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 14,
  insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

local KIND_LABELS = {
  creature = "Creature", rare = "Rare creature", elite = "Elite", boss = "Boss",
  npc = "Character", place = "Place", quest = "Quest", lore = "Lore",
}

---r, g, b (0-1) of a rarity, from the "aarrggbb" hex in Cards.RARITY_COLORS.
function CardWidget.rarityRGB(rarity)
  local hex = Cards.RARITY_COLORS[rarity] or "ffffffff"
  return tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255, tonumber(hex:sub(7, 8), 16) / 255
end

local function text(widget, font, point, x, y, width)
  local fs = widget:CreateFontString(nil, "OVERLAY", font)
  fs:SetPoint(point, widget, point, x, y)
  if width then
    fs:SetWidth(width)
    fs:SetWordWrap(true)
  end
  return fs
end

---@param parent table frame
---@return table widget Button
function CardWidget.create(parent)
  local w = CreateFrame("Button", nil, parent, "BackdropTemplate")
  w:SetSize(CardWidget.WIDTH, CardWidget.HEIGHT)
  w:SetBackdrop(BACKDROP)

  w.name = text(w, "GameFontNormalSmall", "TOP", 0, -10, CardWidget.WIDTH - 14)
  w.kind = text(w, "GameFontDisableSmall", "TOP", 0, -38)
  w.flavor = text(w, "GameFontHighlightSmall", "CENTER", 0, -6, CardWidget.WIDTH - 18)
  w.flavor:SetJustifyH("CENTER")
  w.stats = text(w, "GameFontNormalSmall", "BOTTOM", 0, 10)
  w.newTag = text(w, "GameFontGreenSmall", "TOPRIGHT", -8, 8)
  w.copies = text(w, "GameFontHighlightSmall", "BOTTOMRIGHT", -8, 10)
  w.back = text(w, "GameFontNormalHuge", "CENTER", 0, 0)
  return w
end

local function hideAll(w)
  for _, fs in ipairs({ w.name, w.kind, w.flavor, w.stats, w.newTag, w.copies, w.back }) do fs:Hide() end
end

---Face up.
---@param opts table|nil { copies = number, isNew = boolean }
function CardWidget.showCard(w, card, opts)
  opts = opts or {}
  hideAll(w)
  local r, g, b = CardWidget.rarityRGB(card.rarity)
  w:SetBackdropColor(0.08, 0.08, 0.1, 0.95)
  w:SetBackdropBorderColor(r, g, b, 1)

  w.name:SetText(L[card.name])
  w.name:SetTextColor(r, g, b)
  w.kind:SetText(L[KIND_LABELS[card.kind] or ""].." - "..L[Cards.RARITY_NAMES[card.rarity]])
  w.flavor:SetText(L[card.flavor])
  w.stats:SetText(L["ATK"].." "..card.attack.."   "..L["DEF"].." "..card.defense)
  for _, fs in ipairs({ w.name, w.kind, w.flavor, w.stats }) do fs:Show() end

  if opts.isNew then
    w.newTag:SetText(L["New!"])
    w.newTag:Show()
  end
  if opts.copies and opts.copies > 1 then
    w.copies:SetText("x"..opts.copies)
    w.copies:Show()
  end
  w:Show()
end

---Face down, before a reveal.
function CardWidget.showBack(w)
  hideAll(w)
  w:SetBackdropColor(0.15, 0.1, 0.05, 0.95)
  w:SetBackdropBorderColor(0.8, 0.65, 0.3, 1)
  w.back:SetText("?")
  w.back:Show()
  w:Show()
end

---A card the player does not own: rarity frame, no name or text.
function CardWidget.showMissing(w, card)
  hideAll(w)
  local r, g, b = CardWidget.rarityRGB(card.rarity)
  w:SetBackdropColor(0.03, 0.03, 0.03, 0.9)
  w:SetBackdropBorderColor(r * 0.5, g * 0.5, b * 0.5, 0.8)
  w.back:SetText("?")
  w.back:Show()
  w.kind:SetText(L[Cards.RARITY_NAMES[card.rarity]])
  w.kind:Show()
  w:Show()
end
