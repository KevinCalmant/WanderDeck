local _, ns = ...

-- Minimap button: left-click opens the binder, right-click opens the next
-- pack, drag moves it around the minimap. A badge shows unopened packs; the
-- tooltip shows progress to the next pack. Settings live in
-- db.global.settings (minimapAngle, minimapHidden), sanitized at load.

local L = ns.L
local Draw = ns.Draw
local C = Draw.COLORS

local MinimapButton = {}
ns.MinimapButton = MinimapButton

local SIZE = 31
local RADIUS = 80
local ICON = "Interface\\Icons\\INV_Misc_Book_09"

---Offset from the minimap center for an angle in degrees.
---@return number x, number y
function MinimapButton.offsetFor(angle, radius)
  local rad = math.rad(angle)
  return math.cos(rad) * radius, math.sin(rad) * radius
end

---Angle in degrees (0 to 360) of a point relative to the minimap center.
function MinimapButton.angleFor(dx, dy)
  local angle = math.deg(math.atan2(dy, dx))
  if angle < 0 then angle = angle + 360 end
  return angle
end

---Tooltip lines for the current progress (pure, for tests).
---@param char table db.char
---@param config table ns.Config
---@return string[]
function MinimapButton.tooltipLines(char, config)
  return {
    L["Next pack:"].." "..ns.Packs.toSteps(char.progress.total, config).." / "..config.STEPS_PER_PACK,
    L["Unopened packs:"].." "..#char.packs.." / "..config.MAX_UNOPENED_PACKS,
    L["Left-click: binder"],
    L["Right-click: open a pack"],
    L["Drag: move this button"],
  }
end

local button

local function settings()
  local db = ns.GetDB()
  return db and db.global.settings
end

local function place()
  local s = settings()
  if not (button and s) then return end
  local x, y = MinimapButton.offsetFor(s.minimapAngle, RADIUS)
  button:ClearAllPoints()
  button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function plain(value)
  return type(value) == "number" and not ns.Wow.isSecret(value) and ns.Utils.isFiniteNonNegative(math.abs(value))
end

---Drag step: follows the cursor around the minimap. Every client value is
---checked (number, not secret, finite; scale > 0), and only an angle from 0 to
---360 is saved, so a missing anchor or odd value skips the frame.
---@param env table|nil _G or a test stub
function MinimapButton.onDragUpdate(env)
  env = env or _G
  local s = settings()
  local minimap = env.Minimap
  if not (s and minimap and type(env.GetCursorPosition) == "function") then return end
  local mx, my = minimap:GetCenter()
  local cx, cy = env.GetCursorPosition()
  local scale = minimap:GetEffectiveScale()
  if not (plain(mx) and plain(my) and plain(cx) and plain(cy) and plain(scale) and scale > 0) then return end
  local angle = MinimapButton.angleFor(cx / scale - mx, cy / scale - my)
  if not (ns.Utils.isFiniteNonNegative(angle) and angle <= 360) then return end
  s.minimapAngle = angle
  place()
end

local function onDragUpdate() MinimapButton.onDragUpdate() end

local function showTooltip(self)
  local db = ns.GetDB()
  if not db then return end
  GameTooltip:SetOwner(self, "ANCHOR_LEFT")
  GameTooltip:SetText("WanderDeck")
  for _, line in ipairs(MinimapButton.tooltipLines(db.char, ns.Config)) do
    GameTooltip:AddLine(line, 1, 1, 1)
  end
  GameTooltip:Show()
end

local function build()
  button = CreateFrame("Button", "WanderDeckMinimapButton", Minimap)
  button:SetSize(SIZE, SIZE)
  button:SetFrameStrata("MEDIUM")
  button:SetFrameLevel(8)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button:RegisterForDrag("LeftButton")

  local icon = button:CreateTexture(nil, "ARTWORK")
  icon:SetSize(20, 20)
  icon:SetPoint("CENTER", 0, 1)
  icon:SetTexture(ICON)
  icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  local border = button:CreateTexture(nil, "OVERLAY")
  border:SetSize(53, 53)
  border:SetPoint("TOPLEFT")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  button.badgeBg = Draw.rect(button, "OVERLAY", C.attack)
  button.badgeBg:SetSize(14, 14)
  button.badgeBg:SetPoint("BOTTOMRIGHT", 2, -2)
  button.badge = Draw.text(button, "GameFontHighlightSmall")
  button.badge:SetPoint("CENTER", button.badgeBg, "CENTER", 0, 0)

  button:SetScript("OnClick", function(_, mouseButton)
    if mouseButton == "RightButton" then
      ns.Slash.dispatch("open")
    else
      ns.Slash.dispatch("binder")
    end
  end)
  button:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", onDragUpdate) end)
  button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
  button:SetScript("OnEnter", showTooltip)
  button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

---Updates the badge and visibility from saved data.
function MinimapButton.refresh()
  local db = ns.GetDB()
  if not (button and db) then return end
  local s = db.global.settings
  if s.minimapHidden then button:Hide() return end
  local packs = #db.char.packs
  button.badge:SetText(packs)
  button.badge:SetShown(packs > 0)
  button.badgeBg:SetShown(packs > 0)
  place()
  button:Show()
end

---Builds the button once saved data is loaded (Core calls this).
function MinimapButton.init()
  if not button then build() end
  MinimapButton.refresh()
end

---Test hook.
function MinimapButton._debug() return button end

ns.Slash.register({
  name = "minimap",
  usage = "minimap",
  help = L["Show or hide the minimap button"],
  handler = function()
    local s = settings()
    if not s then return end
    s.minimapHidden = not s.minimapHidden
    MinimapButton.refresh()
  end,
})
