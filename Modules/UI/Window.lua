local _, ns = ...

-- Shared window chrome in the illustrated style: dark panel, double gold
-- border, gold title, flat gold buttons. Movable, closed by Escape.

local Draw = ns.Draw
local C = Draw.COLORS

local Window = {}
ns.Window = Window

---@param globalName string unique frame name, required for Escape to close it
---@param title string already localized
---@param width number
---@param height number
---@return table frame
function Window.create(globalName, title, width, height)
  local f = CreateFrame("Frame", globalName, UIParent)
  f:SetSize(width, height)
  f:SetPoint("CENTER")
  f:SetFrameStrata("DIALOG")
  f:SetToplevel(true)
  f:EnableMouse(true)
  f:SetMovable(true)
  f:SetClampedToScreen(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)

  local bg = Draw.rect(f, "BACKGROUND", C.window, 0.96)
  bg:SetAllPoints()
  Draw.border(f, "BORDER", C.gold, 2, 0)
  Draw.border(f, "BORDER", C.gold, 1, 5)

  f.title = Draw.text(f, "GameFontNormalLarge", C.goldText)
  f.title:SetPoint("TOP", 0, -16)
  f.title:SetText(title)
  local rule = Draw.rect(f, "ARTWORK", C.gold, 0.6)
  rule:SetPoint("TOPLEFT", 20, -38)
  rule:SetPoint("TOPRIGHT", -20, -38)
  rule:SetHeight(1)

  -- The template's own OnClick goes through HideUIPanel, which is meant for
  -- Blizzard-managed panels and raises a Lua error on an addon window in the
  -- modern client: replace it with a plain Hide.
  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -6, -6)
  close:SetScript("OnClick", function() f:Hide() end)
  f.closeButton = close

  tinsert(UISpecialFrames, globalName)
  f:Hide()
  return f
end

---A flat button: dark fill, gold outline, gold text; brighter on hover. A
---disabled button marks the current choice (white text).
function Window.button(parent, label, width)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(width or 100, 22)
  local fill = Draw.rect(b, "BACKGROUND", C.titleBar)
  fill:SetAllPoints()
  Draw.border(b, "BORDER", C.gold, 1, 0)
  local hover = Draw.rect(b, "HIGHLIGHT", C.gold, 0.18)
  hover:SetAllPoints()

  local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  fs:SetPoint("CENTER")
  b:SetFontString(fs)
  b:SetNormalFontObject("GameFontNormalSmall")
  b:SetDisabledFontObject("GameFontHighlightSmall")
  b:SetText(label)
  return b
end
