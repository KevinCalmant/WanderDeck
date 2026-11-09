local _, ns = ...

-- Developer-only (excluded from releases). /wd loadscreens shows every
-- dungeon card's loading screen, whole and uncropped, in a test window and
-- prints the file ID the client resolved for each, to check the paths in
-- Data/ (and the 4:3 aspect in Config.LOAD_SCREEN_ASPECT) on Forever.

local LoadScreenTest = {}
ns.LoadScreenTest = LoadScreenTest

local COLUMNS, CELL_W, CELL_H, LABEL_H, PAD = 5, 160, 120, 14, 8

---Registered cards with a loading screen, in zone then data order.
---@param zoneIDs number[] Cards.zoneIDs()
---@param cardsOf fun(zoneMapID: number): table[] Cards.zoneCards
---@return table[] cards
function LoadScreenTest.cards(zoneIDs, cardsOf)
  local out = {}
  for _, zoneMapID in ipairs(zoneIDs) do
    for _, card in ipairs(cardsOf(zoneMapID)) do
      if card.loadScreen then out[#out + 1] = card end
    end
  end
  return out
end

---Chat line for one card: the file ID the client resolved, or MISSING when
---the getter threw or returned a secret, a non-number or a non-positive value.
---Card IDs and loadScreen values are validated in Cards.registerZone.
---@param card table registered card
---@param ok boolean pcall status of SetTexture + GetTextureFileID
---@param fileID any
---@return string
function LoadScreenTest.reportLine(card, ok, fileID)
  local found = ok and not ns.Wow.isSecret(fileID) and ns.Utils.isMapID(fileID)
  return "  "..card.id.."  "..tostring(card.loadScreen).."  "..(found and ("file "..fileID) or "MISSING")
end

local frame

local function getFrame(count)
  if frame then return frame end
  local rows = math.ceil(count / COLUMNS)
  frame = CreateFrame("Frame", nil, UIParent)
  frame:SetSize(COLUMNS * (CELL_W + PAD) + PAD, rows * (CELL_H + LABEL_H + PAD) + PAD + 24)
  frame:SetPoint("CENTER")
  frame:SetFrameStrata("DIALOG")
  local bg = frame:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.05, 0.05, 0.08, 0.95)
  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOP", 0, -6)
  title:SetText("Loading screens")
  local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT")
  frame.cells = {}
  return frame
end

local function cell(i)
  local c = frame.cells[i]
  if c then return c end
  local col, row = (i - 1) % COLUMNS, math.floor((i - 1) / COLUMNS)
  local x, y = PAD + col * (CELL_W + PAD), -(24 + row * (CELL_H + LABEL_H + PAD))
  c = { tex = frame:CreateTexture(nil, "ARTWORK"), label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall") }
  c.tex:SetSize(CELL_W, CELL_H)
  c.tex:SetPoint("TOPLEFT", x, y)
  c.label:SetPoint("TOPLEFT", c.tex, "BOTTOMLEFT", 0, -1)
  c.label:SetWidth(CELL_W)
  c.label:SetWordWrap(false)
  frame.cells[i] = c
  return c
end

local function handleLoadScreens()
  local cards = LoadScreenTest.cards(ns.Cards.zoneIDs(), ns.Cards.zoneCards)
  getFrame(#cards)
  for i, card in ipairs(cards) do
    local c = cell(i)
    local ok, fileID = pcall(function()
      c.tex:SetTexture(ns.Cards.loadScreenPath(card))
      return c.tex:GetTextureFileID()
    end)
    c.label:SetText(ns.CardText.name(card))
    print(LoadScreenTest.reportLine(card, ok, fileID))
  end
  frame:Show()
  ns.print(#cards.." dungeon cards. MISSING keeps the icon on that card; send the file IDs of the others.")
end

if ns.Slash then
  ns.Slash.register({
    name = "loadscreens",
    usage = "loadscreens",
    help = "Developer: show the dungeon cards' loading screens",
    handler = handleLoadScreens,
  })
end
