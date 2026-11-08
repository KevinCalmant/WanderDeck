local _, ns = ...

-- Shared window chrome: a movable backdrop frame with a title and a close
-- button, closed by Escape.

local Window = {}
ns.Window = Window

local BACKDROP = {
  bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
  tile = true, tileSize = 32, edgeSize = 32,
  insets = { left = 11, right = 12, top = 12, bottom = 11 },
}

---@param globalName string unique frame name, required for Escape to close it
---@param title string already localized
---@param width number
---@param height number
---@return table frame
function Window.create(globalName, title, width, height)
  local f = CreateFrame("Frame", globalName, UIParent, "BackdropTemplate")
  f:SetSize(width, height)
  f:SetPoint("CENTER")
  f:SetBackdrop(BACKDROP)
  f:SetFrameStrata("DIALOG")
  f:SetToplevel(true)
  f:EnableMouse(true)
  f:SetMovable(true)
  f:SetClampedToScreen(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)

  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  f.title:SetPoint("TOP", 0, -18)
  f.title:SetText(title)

  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -6, -6)

  tinsert(UISpecialFrames, globalName)
  f:Hide()
  return f
end

---A standard red button.
function Window.button(parent, label, width)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(width or 100, 22)
  b:SetText(label)
  return b
end
