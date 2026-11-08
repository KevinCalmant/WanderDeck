local _, ns = ...

-- Flat drawing helpers. Everything is drawn with SetColorTexture, so the UI
-- needs no texture files of its own; only card art loads a game icon.

local Draw = {}
ns.Draw = Draw

-- Style C palette (r, g, b in 0-1).
Draw.COLORS = {
  gold = { 0.79, 0.64, 0.29 },
  goldText = { 1, 0.81, 0.42 },
  body = { 0.23, 0.16, 0.08 },
  inner = { 0.11, 0.08, 0.05 },
  titleBar = { 0.16, 0.12, 0.06 },
  art = { 0.29, 0.23, 0.13 },
  parchment = { 0.90, 0.84, 0.71 },
  muted = { 0.62, 0.58, 0.50 },
  attack = { 0.54, 0.16, 0.10 },
  defense = { 0.12, 0.29, 0.48 },
  window = { 0.08, 0.07, 0.05 },
}

---A solid rectangle texture.
---@param parent table frame
---@param layer string draw layer
---@param color number[] { r, g, b }
---@param alpha number|nil
function Draw.rect(parent, layer, color, alpha)
  local t = parent:CreateTexture(nil, layer)
  t:SetColorTexture(color[1], color[2], color[3], alpha or 1)
  return t
end

---Four edge textures forming a border, `inset` pixels inside `parent`.
---@return table border { top, bottom, left, right, setColor = fun(r, g, b, a) }
function Draw.border(parent, layer, color, thickness, inset)
  inset = inset or 0
  local border = {}
  for _, side in ipairs({ "top", "bottom", "left", "right" }) do
    border[side] = Draw.rect(parent, layer, color)
  end
  border.top:SetPoint("TOPLEFT", inset, -inset)
  border.top:SetPoint("TOPRIGHT", -inset, -inset)
  border.top:SetHeight(thickness)
  border.bottom:SetPoint("BOTTOMLEFT", inset, inset)
  border.bottom:SetPoint("BOTTOMRIGHT", -inset, inset)
  border.bottom:SetHeight(thickness)
  border.left:SetPoint("TOPLEFT", inset, -inset)
  border.left:SetPoint("BOTTOMLEFT", inset, inset)
  border.left:SetWidth(thickness)
  border.right:SetPoint("TOPRIGHT", -inset, -inset)
  border.right:SetPoint("BOTTOMRIGHT", -inset, inset)
  border.right:SetWidth(thickness)
  function border.setColor(r, g, b, a)
    for _, side in ipairs({ "top", "bottom", "left", "right" }) do border[side]:SetColorTexture(r, g, b, a or 1) end
  end
  return border
end

---A font string with a color.
function Draw.text(parent, font, color)
  local fs = parent:CreateFontString(nil, "OVERLAY", font)
  if color then fs:SetTextColor(color[1], color[2], color[3]) end
  return fs
end
