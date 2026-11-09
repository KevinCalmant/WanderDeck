local _, ns = ...

-- One card on screen in the "illustrated" style: gold frame, title bar with a
-- rarity gem, art panel, flavor text and attack/defense medallions. Face up,
-- face down (reveal) or a silhouette (missing from the binder). Text comes
-- from Data/ and the locale files only; art is a game icon, or the creature's
-- 3D model for creature cards with an npcID (the icon shows until it loads).

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
  npc = "Character", place = "Place", quest = "Quest", item = "Item", lore = "Lore",
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

-- Reveal effects for Epic (4) and Legendary (5) cards, played once when the
-- card flips in a pack: a rarity-colored burst swells out from behind the
-- card, sparks fly outward, a light band sweeps across the face and the card
-- pops. Legendary is bigger and slower and adds rays turning behind the card.
local FX = {
  [4] = { burst = 1.6, duration = 0.8, sparks = 8, spread = 80, sweeps = 1, rays = false, pop = 1.08 },
  [5] = { burst = 2.1, duration = 1.3, sparks = 14, spread = 120, sweeps = 2, rays = true, pop = 1.14 },
}
CardWidget.FX = FX
local MAX_SPARKS, RAY_COUNT = 14, 4

local function fade(group, region, from, to, duration, delay)
  local a = group:CreateAnimation("Alpha")
  a:SetTarget(region)
  a:SetFromAlpha(from)
  a:SetToAlpha(to)
  a:SetDuration(duration)
  a:SetStartDelay(delay or 0)
  return a
end

local function scale(group, region, x, duration, delay)
  local s = group:CreateAnimation("Scale")
  s:SetTarget(region)
  s:SetScale(x, x)
  s:SetDuration(duration)
  s:SetStartDelay(delay or 0)
  s:SetOrigin("CENTER", 0, 0)
  return s
end

local function buildFxGroup(w, fx, parts)
  local g = w:CreateAnimationGroup()
  local d = fx.duration
  -- Burst: flash in, swell, fade.
  fade(g, parts.burst, 0, 0.9, 0.1, 0.15)
  fade(g, parts.burst, 0.9, 0, d * 0.7, 0.25)
  scale(g, parts.burst, fx.burst, d * 0.8, 0.15)
  -- Sparks: from the centre outward on a circle, fading as they go.
  for i = 1, fx.sparks do
    local spark = parts.sparks[i]
    local angle = (i - 1) * 2 * math.pi / fx.sparks
    local t = g:CreateAnimation("Translation")
    t:SetTarget(spark)
    t:SetOffset(math.cos(angle) * fx.spread, math.sin(angle) * fx.spread)
    t:SetDuration(d * 0.7)
    t:SetStartDelay(0.18)
    t:SetSmoothing("OUT")
    fade(g, spark, 0, 1, 0.05, 0.18)
    fade(g, spark, 1, 0, d * 0.6, 0.3)
  end
  -- Light band sweeping left to right across the face, once or twice.
  for pass = 1, fx.sweeps do
    local delay = 0.2 + (pass - 1) * 0.45
    local t = g:CreateAnimation("Translation")
    t:SetTarget(parts.shine)
    t:SetOffset(W + 60, 0)
    t:SetDuration(0.4)
    t:SetStartDelay(delay)
    fade(g, parts.shine, 0, 0.7, 0.08, delay)
    fade(g, parts.shine, 0.7, 0, 0.12, delay + 0.28)
  end
  -- Rays turning behind the card (Legendary).
  if fx.rays then
    for _, ray in ipairs(parts.rays) do
      local r = g:CreateAnimation("Rotation")
      r:SetTarget(ray)
      r:SetDegrees(-60)
      r:SetDuration(d)
      r:SetStartDelay(0.15)
      r:SetOrigin("CENTER", 0, 0)
      fade(g, ray, 0, 0.55, 0.2, 0.15)
      fade(g, ray, 0.55, 0, d * 0.5, 0.15 + d * 0.5)
    end
  end
  -- Pop: the card grows a little right after the flip, then settles.
  scale(g, w, fx.pop, 0.12, 0.18)
  scale(g, w, 1 / fx.pop, 0.16, 0.3)
  return g
end

-- Optional like the flip: on a client without these APIs the card simply
-- flips. Every part starts at alpha 0 and returns to it once the group ends.
local function buildRevealFx(w)
  local ok, fx = pcall(function()
    local parts = { sparks = {}, rays = {} }
    parts.burst = w:CreateTexture(nil, "BACKGROUND", nil, -7)
    parts.burst:SetPoint("CENTER")
    parts.burst:SetSize(W + 16, H + 16)
    for i = 1, RAY_COUNT do
      local ray = w:CreateTexture(nil, "BACKGROUND", nil, -8)
      ray:SetPoint("CENTER")
      ray:SetSize(W * 2.6, 5)
      ray:SetRotation((i - 1) * math.pi / RAY_COUNT)
      parts.rays[i] = ray
    end
    for i = 1, MAX_SPARKS do
      local spark = w:CreateTexture(nil, "OVERLAY", nil, 7)
      spark:SetPoint("CENTER")
      spark:SetSize(5, 5)
      parts.sparks[i] = spark
    end
    -- The band is clipped to the card so it never shows outside the frame.
    local clip = CreateFrame("Frame", nil, w)
    clip:SetAllPoints()
    clip:SetClipsChildren(true)
    parts.shine = clip:CreateTexture(nil, "OVERLAY", nil, 7)
    parts.shine:SetSize(20, H * 1.6)
    parts.shine:SetPoint("CENTER", clip, "LEFT", -30, 0)
    parts.shine:SetRotation(math.rad(18))
    parts.shine:SetColorTexture(1, 1, 1, 1)
    parts.colored = { parts.burst }
    for _, r in ipairs(parts.rays) do parts.colored[#parts.colored + 1] = r end
    for _, s in ipairs(parts.sparks) do parts.colored[#parts.colored + 1] = s end
    for _, region in ipairs(parts.colored) do region:SetAlpha(0) end
    parts.shine:SetAlpha(0)
    parts.groups = { [4] = buildFxGroup(w, FX[4], parts), [5] = buildFxGroup(w, FX[5], parts) }
    return parts
  end)
  if ok then w.revealFx = fx end
end

local function stopRevealFx(w)
  if type(w.revealFx) ~= "table" then return end
  for _, group in pairs(w.revealFx.groups) do group:Stop() end
end

-- The 3D model sits over the art panel. The icon under it stays visible until
-- the client reports a loaded model, so an unknown or uncached creature (or a
-- client without PlayerModel) still shows the icon.
local function modelLoaded(model)
  local ok, fileID = pcall(model.GetModelFileID, model)
  return ok and not ns.Wow.isSecret(fileID) and type(fileID) == "number" and fileID > 0
end

local function onModelLoaded(w)
  if not (w.modelNpcID and w.model:IsShown()) then return end
  pcall(w.model.SetPortraitZoom, w.model, ns.Config.CARD_MODEL_ZOOM)
  if modelLoaded(w.model) then w.icon:Hide() end
end

local hideModel

-- Loads the card's creature into the model frame. Called when the model
-- becomes visible and again on the next frame: a model set in the same frame
-- as its window opens (the binder renders right after Show) gets no camera,
-- since the frame has no laid-out size yet, and draws nothing.
local function applyModel(w)
  local m, npcID = w.model, w.modelNpcID
  if not (m and npcID) then return end
  local ok = pcall(function()
    m:SetCreature(npcID)
    m:SetPortraitZoom(ns.Config.CARD_MODEL_ZOOM)
  end)
  if not ok then hideModel(w) return end
  -- A cached model may be ready at once, without OnModelLoaded.
  if modelLoaded(m) then w.icon:Hide() end
end

local function applyNextFrame(w)
  if not (type(C_Timer) == "table" and type(C_Timer.After) == "function") then return end
  local token = w.modelToken + 1
  w.modelToken = token
  C_Timer.After(0, function()
    if w.modelToken == token and w.modelNpcID and w.model:IsVisible() then applyModel(w) end
  end)
end

local function buildModel(w, art)
  local ok, model = pcall(function()
    local m = CreateFrame("PlayerModel", nil, w)
    m:SetPoint("TOPLEFT", art, "TOPLEFT", 1, -1)
    m:SetPoint("BOTTOMRIGHT", art, "BOTTOMRIGHT", -1, 1)
    -- Clicks go through to the card button.
    m:EnableMouse(false)
    m:SetScript("OnModelLoaded", function() onModelLoaded(w) end)
    -- Only visible cards hold a model: a closed window frees its models and
    -- reloads them when it opens again.
    m:SetScript("OnShow", function()
      applyModel(w)
      applyNextFrame(w)
    end)
    m:SetScript("OnHide", function(self) pcall(self.ClearModel, self) end)
    m:Hide()
    return m
  end)
  -- Explicit starting values: a frame (or a test stub) may answer unset keys.
  w.modelNpcID, w.modelToken = false, 0
  if ok then w.model = model end
end

hideModel = function(w)
  w.modelNpcID = false
  w.modelToken = w.modelToken + 1
  if w.model then
    w.model:Hide()
    pcall(w.model.ClearModel, w.model)
  end
end

local function showModel(w, card)
  local npcID = ns.CardText.modelNpcID(card)
  if not (w.model and npcID) then return end
  w.modelNpcID = npcID
  -- reset() hid the model, so Show fires OnShow, which loads it, now if the
  -- card is visible, else when its window opens.
  if not pcall(w.model.Show, w.model) then hideModel(w) end
end

---@param parent table frame
---@param opts table|nil { revealFx = true } adds the Epic/Legendary reveal effects
---@return table widget Button
function CardWidget.create(parent, opts)
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
  buildModel(w, art)

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
  if opts and opts.revealFx then buildRevealFx(w) end
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
  stopRevealFx(w)
  hideModel(w)
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

  w.name:SetText(ns.CardText.name(card))
  w.icon:SetTexture(ns.CardText.icon(card))
  w.icon:SetDesaturated(false)
  w.kind:SetText(CardWidget.kindLabel(card))
  w.rarityLabel:SetText(L[Cards.RARITY_NAMES[card.rarity]])
  w.rarityLabel:SetTextColor(r, g, b)
  w.attack:SetText(card.attack)
  w.defense:SetText(card.defense)
  setShown(w.faceParts, true)
  showModel(w, card)

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

---Face up with the flip-in animation (reveal); Epic and Legendary cards also
---play their reveal effects when the widget has them.
---@return boolean played true when a reveal effect started
function CardWidget.flip(w, card, opts)
  CardWidget.showCard(w, card, opts)
  if w.flipAnim then w.flipAnim:Play() end
  local fx = w.revealFx
  local group = type(fx) == "table" and FX[card.rarity] and fx.groups[card.rarity]
  if not group then return false end
  local r, g, b = CardWidget.rarityRGB(card.rarity)
  for _, region in ipairs(fx.colored) do region:SetColorTexture(r, g, b, 1) end
  group:Play()
  return true
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
