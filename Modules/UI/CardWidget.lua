local _, ns = ...

-- One card on screen in the "illustrated" style: gold frame, title bar with a
-- rarity gem, art panel, flavor text and attack/defense medallions. Face up,
-- face down (reveal) or a silhouette (missing from the binder). Text comes
-- from Data/ and the locale files only; art is a game icon.

local L = ns.L
local Cards, Draw = ns.Cards, ns.Draw
local C = Draw.COLORS

local CardWidget = {}
ns.CardWidget = CardWidget

CardWidget.WIDTH, CardWidget.HEIGHT = 120, 165
local W, H = CardWidget.WIDTH, CardWidget.HEIGHT
local ROUND_MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"

local KIND_LABELS = {
  creature = "Creature", rare = "Rare creature", elite = "Elite", boss = "Boss",
  npc = "Character", place = "Place", quest = "Quest", lore = "Lore",
}

---r, g, b (0-1) of a rarity, from the "aarrggbb" hex in Cards.RARITY_COLORS.
function CardWidget.rarityRGB(rarity)
  local hex = Cards.RARITY_COLORS[rarity] or "ffffffff"
  return tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255, tonumber(hex:sub(7, 8), 16) / 255
end

---Localized kind of a card ("Créature rare", "Lieu", ...).
function CardWidget.kindLabel(card)
  return L[KIND_LABELS[card.kind] or ""]
end

local function setShown(parts, shown)
  for _, part in ipairs(parts) do
    if shown then part:Show() else part:Hide() end
  end
end

-- A round medallion with a number on it. The round mask is optional: without
-- it the medallion is a square, which still reads fine.
local function medallion(w, color, point, x)
  local disc = Draw.rect(w, "ARTWORK", color)
  disc:SetSize(22, 22)
  disc:SetPoint(point, x, 8)
  pcall(function()
    local mask = w:CreateMaskTexture()
    mask:SetTexture(ROUND_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(disc)
    disc:AddMaskTexture(mask)
  end)
  local value = Draw.text(w, "GameFontHighlightSmall")
  value:SetPoint("CENTER", disc, "CENTER", 0, 0)
  return disc, value
end

-- Flip-in: the card opens from a thin sliver to full width. Optional: on a
-- client without the animation API the card simply appears.
local function buildAnimations(w)
  pcall(function()
    local flip = w:CreateAnimationGroup()
    local scale = flip:CreateAnimation("Scale")
    scale:SetScaleFrom(0.05, 1)
    scale:SetScaleTo(1, 1)
    scale:SetDuration(0.18)
    scale:SetOrigin("CENTER", 0, 0)
    w.flipAnim = flip

    local pulse = w.halo and w:CreateAnimationGroup()
    if pulse then
      local alpha = pulse:CreateAnimation("Alpha")
      alpha:SetTarget(w.halo)
      alpha:SetFromAlpha(0.25)
      alpha:SetToAlpha(0.85)
      alpha:SetDuration(0.9)
      pulse:SetLooping("BOUNCE")
      w.haloAnim = pulse
    end
  end)
end

---@param parent table frame
---@return table widget Button
function CardWidget.create(parent)
  local w = CreateFrame("Button", nil, parent)
  w:SetSize(W, H)

  -- Halo behind Epic and Legendary cards.
  w.halo = Draw.rect(w, "BACKGROUND", C.gold, 0)
  w.halo:SetPoint("TOPLEFT", -5, 5)
  w.halo:SetPoint("BOTTOMRIGHT", 5, -5)

  -- Frame: gold outer border, dark inner panel with a rarity-colored edge.
  w.body = Draw.rect(w, "BORDER", C.body)
  w.body:SetAllPoints()
  w.goldBorder = Draw.border(w, "ARTWORK", C.gold, 2, 0)
  w.inner = Draw.rect(w, "ARTWORK", C.inner)
  w.inner:SetPoint("TOPLEFT", 4, -4)
  w.inner:SetPoint("BOTTOMRIGHT", -4, 4)
  w.rarityBorder = Draw.border(w, "ARTWORK", C.gold, 1, 4)

  -- Face up.
  local titleBar = Draw.rect(w, "ARTWORK", C.titleBar)
  titleBar:SetPoint("TOPLEFT", 5, -5)
  titleBar:SetPoint("TOPRIGHT", -5, -5)
  titleBar:SetHeight(18)
  local titleLine = Draw.rect(w, "ARTWORK", C.gold)
  titleLine:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT")
  titleLine:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT")
  titleLine:SetHeight(1)

  w.name = Draw.text(w, "GameFontNormalSmall", C.goldText)
  w.name:SetPoint("LEFT", titleBar, "LEFT", 4, 0)
  w.name:SetWidth(W - 32)
  w.name:SetJustifyH("LEFT")
  w.name:SetWordWrap(false)

  w.gem = Draw.rect(w, "OVERLAY", C.gold)
  w.gem:SetSize(8, 8)
  w.gem:SetPoint("RIGHT", titleBar, "RIGHT", -5, 0)

  local art = Draw.rect(w, "ARTWORK", C.art)
  art:SetPoint("TOPLEFT", 5, -24)
  art:SetPoint("TOPRIGHT", -5, -24)
  art:SetHeight(80)
  local artLine = Draw.rect(w, "ARTWORK", C.gold)
  artLine:SetPoint("TOPLEFT", art, "BOTTOMLEFT")
  artLine:SetPoint("TOPRIGHT", art, "BOTTOMRIGHT")
  artLine:SetHeight(1)

  w.icon = w:CreateTexture(nil, "OVERLAY")
  w.icon:SetSize(62, 62)
  w.icon:SetPoint("CENTER", art, "CENTER", 0, 0)
  w.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

  -- Kind and rarity on two short lines, so long French labels fit. The
  -- flavor text lives in the detail window (CardDetail), not on the card.
  w.kind = Draw.text(w, "GameFontDisableSmall", C.muted)
  w.kind:SetPoint("TOP", art, "BOTTOM", 0, -5)
  w.rarityLabel = Draw.text(w, "GameFontDisableSmall", C.muted)
  w.rarityLabel:SetPoint("TOP", w.kind, "BOTTOM", 0, -2)

  local atkDisc, atk = medallion(w, C.attack, "BOTTOMLEFT", 8)
  local defDisc, def = medallion(w, C.defense, "BOTTOMRIGHT", -8)
  w.attack, w.defense = atk, def

  w.copies = Draw.text(w, "GameFontHighlightSmall", C.parchment)
  w.copies:SetPoint("BOTTOM", 0, 12)

  w.newTag = Draw.text(w, "GameFontGreenSmall")
  w.newTag:SetPoint("BOTTOMLEFT", w, "TOPLEFT", 2, 1)
  w.pinTag = Draw.text(w, "GameFontNormalSmall", C.goldText)
  w.pinTag:SetPoint("BOTTOMRIGHT", w, "TOPRIGHT", -2, 1)

  w.faceParts = { titleBar, titleLine, w.name, w.gem, art, artLine, w.icon, w.kind, w.rarityLabel, atkDisc, atk, defDisc, def }

  -- Face down / silhouette.
  local backPanel = Draw.rect(w, "ARTWORK", C.titleBar)
  backPanel:SetPoint("TOPLEFT", 5, -5)
  backPanel:SetPoint("BOTTOMRIGHT", -5, 5)
  local backBorder = Draw.border(w, "OVERLAY", C.gold, 1, 10)
  w.back = Draw.text(w, "GameFontNormalHuge", C.goldText)
  w.back:SetPoint("CENTER", 0, 4)
  w.backLabel = Draw.text(w, "GameFontNormalSmall", C.gold)
  w.backLabel:SetPoint("BOTTOM", 0, 18)
  w.backParts = { backPanel, backBorder.top, backBorder.bottom, backBorder.left, backBorder.right, w.back, w.backLabel }

  buildAnimations(w)
  return w
end

local function setHalo(w, rarity)
  if rarity and rarity >= 4 then
    local r, g, b = CardWidget.rarityRGB(rarity)
    w.halo:SetColorTexture(r, g, b, 0.6)
    w.halo:Show()
    if w.haloAnim then w.haloAnim:Play() end
  else
    if w.haloAnim then w.haloAnim:Stop() end
    w.halo:Hide()
  end
end

local function reset(w)
  setShown(w.faceParts, false)
  setShown(w.backParts, false)
  w.copies:Hide()
  w.newTag:Hide()
  w.pinTag:Hide()
  w.goldBorder.setColor(C.gold[1], C.gold[2], C.gold[3], 1)
end

---Face up.
---@param opts table|nil { copies = number, isNew = boolean, pinned = boolean }
function CardWidget.showCard(w, card, opts)
  opts = opts or {}
  reset(w)
  local r, g, b = CardWidget.rarityRGB(card.rarity)
  w.rarityBorder.setColor(r, g, b, 1)
  w.gem:SetColorTexture(r, g, b, 1)

  w.name:SetText(L[card.name])
  w.icon:SetTexture(Cards.iconPath(card))
  w.icon:SetDesaturated(false)
  w.kind:SetText(CardWidget.kindLabel(card))
  w.rarityLabel:SetText(L[Cards.RARITY_NAMES[card.rarity]])
  w.rarityLabel:SetTextColor(r, g, b)
  w.attack:SetText(card.attack)
  w.defense:SetText(card.defense)
  setShown(w.faceParts, true)

  if opts.isNew then
    w.newTag:SetText(L["New!"])
    w.newTag:Show()
  end
  if opts.pinned then
    w.pinTag:SetText(L["Pinned"])
    w.pinTag:Show()
  end
  if opts.copies and opts.copies > 1 then
    w.copies:SetText("x"..opts.copies)
    w.copies:Show()
  end
  setHalo(w, card.rarity)
  w:Show()
end

---Face up with the flip-in animation (reveal).
function CardWidget.flip(w, card, opts)
  CardWidget.showCard(w, card, opts)
  if w.flipAnim then w.flipAnim:Play() end
end

---Face down, before a reveal.
function CardWidget.showBack(w)
  reset(w)
  setHalo(w, nil)
  w.rarityBorder.setColor(C.gold[1], C.gold[2], C.gold[3], 1)
  w.back:SetText("?")
  w.backLabel:SetText("WanderDeck")
  setShown(w.backParts, true)
  w:Show()
end

---A card the player does not own: dimmed frame in its rarity color, no name,
---no art, no text.
function CardWidget.showMissing(w, card)
  reset(w)
  setHalo(w, nil)
  local r, g, b = CardWidget.rarityRGB(card.rarity)
  w.rarityBorder.setColor(r * 0.5, g * 0.5, b * 0.5, 0.9)
  w.goldBorder.setColor(C.gold[1] * 0.45, C.gold[2] * 0.45, C.gold[3] * 0.45, 1)
  w.back:SetText("?")
  w.backLabel:SetText(L[Cards.RARITY_NAMES[card.rarity]])
  setShown(w.backParts, true)
  w:Show()
end
