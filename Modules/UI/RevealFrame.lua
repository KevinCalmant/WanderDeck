local _, ns = ...

-- Pack opening: the cards start face down; click one to flip it, or Reveal
-- all. The pack is already saved when this frame opens (Collection.openNext).

local L = ns.L
local Cards, CardWidget, Reveal, Window = ns.Cards, ns.CardWidget, ns.Reveal, ns.Window

local RevealFrame = {}
ns.RevealFrame = RevealFrame

local GAP = 10
local MAX_CARDS = 5

local frame, widgets, state, onOpenNext

local function render()
  for i, w in ipairs(widgets) do
    local id = state and state.cardIDs[i]
    local card = id and Cards.get(id)
    if not card then
      w:Hide()
    elseif state.revealed[i] then
      CardWidget.showCard(w, card, { isNew = state.firstTime[id] })
    else
      CardWidget.showBack(w)
    end
  end
  local done = state and Reveal.isDone(state)
  frame.revealAll:SetShown(not done)
  local packsLeft = RevealFrame.packsLeft and RevealFrame.packsLeft() or 0
  frame.openNext:SetShown(done and packsLeft > 0)
  frame.openNext:SetText(L["Open next"].." ("..packsLeft..")")
end

local function build()
  local width = MAX_CARDS * CardWidget.WIDTH + (MAX_CARDS - 1) * GAP + 50
  frame = Window.create("WanderDeckReveal", L["Pack opening"], width, CardWidget.HEIGHT + 120)
  frame.subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.subtitle:SetPoint("TOP", 0, -40)

  widgets = {}
  for i = 1, MAX_CARDS do
    local w = CardWidget.create(frame)
    w:SetPoint("TOPLEFT", 25 + (i - 1) * (CardWidget.WIDTH + GAP), -62)
    w:SetScript("OnClick", function()
      if state and Reveal.flip(state, i) then render() end
    end)
    widgets[i] = w
  end

  frame.revealAll = Window.button(frame, L["Reveal all"], 120)
  frame.revealAll:SetPoint("BOTTOM", 0, 18)
  frame.revealAll:SetScript("OnClick", function()
    if state then Reveal.flipAll(state) render() end
  end)

  frame.openNext = Window.button(frame, L["Open next"], 140)
  frame.openNext:SetPoint("BOTTOM", 0, 18)
  frame.openNext:SetScript("OnClick", function()
    if onOpenNext then onOpenNext() end
  end)
end

---Test hook: the frame, card widgets and reveal state.
function RevealFrame._debug() return frame, widgets, state end

local broken

---Shows a freshly opened pack face down.
---@param result table from Collection.openNext
---@param zoneName string already escaped for display
---@param openNext fun() opens the next pack
---@param packsLeft fun(): number
function RevealFrame.show(result, zoneName, openNext, packsLeft)
  if broken then error("WanderDeck reveal frame failed to build earlier", 0) end
  if not frame then
    local ok, err = pcall(build)
    if not ok then
      broken = true
      if frame then frame:Hide() end
      error(err, 0)
    end
  end
  state = Reveal.new(result.cardIDs, result.firstTime)
  onOpenNext, RevealFrame.packsLeft = openNext, packsLeft
  local ok, err = pcall(function()
    frame.subtitle:SetText(L["Pack from"].." "..zoneName)
    render()
  end)
  if not ok then
    frame:Hide()
    error(err, 0)
  end
  frame:Show()
end
