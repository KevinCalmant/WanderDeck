local _, ns = ...

-- Developer-only (excluded from releases). /wd model <npcID> shows one
-- creature's 3D model in a test window and reports whether the client loaded
-- it, to check the card-art models on Forever: SetCreature (what cards use)
-- or, with "display", SetDisplayInfo. A card with that npcID is named too.

local ModelTest = {}
ns.ModelTest = ModelTest

local MAX_DIGITS = 9
local CHECK_DELAYS = { 0.5, 2, 5 }

---Parses the command arguments: "<npcID>" or "display <displayID>". Only
---digits, one ID, 1-9 digits, at least 1; anything else is nil.
---@param rest string|nil text after "model"
---@return table|nil { mode = "npc"|"display", id = number }
function ModelTest.parse(rest)
  if type(rest) ~= "string" then return nil end
  local mode, digits = "npc", rest:match("^%s*(%d+)%s*$")
  if not digits then
    mode, digits = "display", rest:match("^%s*display%s+(%d+)%s*$")
  end
  if not digits or #digits > MAX_DIGITS then return nil end
  local id = tonumber(digits)
  if not ns.Utils.isMapID(id) then return nil end
  return { mode = mode, id = id }
end

---The registered card with this npcID, or nil.
---@param npcID number
---@param zoneIDs number[] Cards.zoneIDs()
---@param cardsOf fun(zoneMapID: number): table[] Cards.zoneCards
---@return table|nil card
function ModelTest.findCard(npcID, zoneIDs, cardsOf)
  for _, zoneMapID in ipairs(zoneIDs) do
    for _, card in ipairs(cardsOf(zoneMapID)) do
      if card.npcID == npcID then return card end
    end
  end
  return nil
end

---Chat line for a model check: the loaded model file, or "no model" when the
---getter throws or returns a secret, a non-number or a non-positive value.
---@param label string
---@param model table PlayerModel
---@return string
function ModelTest.reportLine(label, model)
  local ok, fileID = pcall(model.GetModelFileID, model)
  if ok and not ns.Wow.isSecret(fileID) and type(fileID) == "number" and fileID > 0 then
    return "  "..label..": loaded, model file "..fileID
  end
  return "  "..label..": no model"
end

---Chat line for a client error, with "|" escaped so it prints as text.
---@param err any
---@return string
function ModelTest.errorLine(err)
  return "  error: "..(tostring(err):gsub("|", "||"))
end

local frame, model

local function report(label)
  print(ModelTest.reportLine(label, model))
end

local function getFrame()
  if frame then return frame end
  frame = CreateFrame("Frame", nil, UIParent)
  frame:SetSize(240, 260)
  frame:SetPoint("CENTER")
  frame:SetFrameStrata("DIALOG")
  local bg = frame:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.05, 0.05, 0.08, 0.95)
  frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.title:SetPoint("TOP", 0, -8)
  local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT")
  model = CreateFrame("PlayerModel", nil, frame)
  model:SetPoint("TOPLEFT", 10, -30)
  model:SetPoint("BOTTOMRIGHT", -10, 10)
  model:SetScript("OnModelLoaded", function() report("OnModelLoaded") end)
  return frame
end

local function handleModel(rest)
  local args = ModelTest.parse(rest)
  if not args then
    ns.print("Usage: /wd model <npcID> or /wd model display <displayID>")
    return
  end
  getFrame()
  local card = args.mode == "npc" and ModelTest.findCard(args.id, ns.Cards.zoneIDs(), ns.Cards.zoneCards)
  frame.title:SetText((args.mode == "npc" and "npcID " or "displayID ")..args.id)
  ns.print("Model test, "..args.mode.." "..args.id..(card and (", card "..card.id) or ""))
  model:ClearModel()
  local ok, err = pcall(function()
    if args.mode == "npc" then model:SetCreature(args.id) else model:SetDisplayInfo(args.id) end
    model:SetPortraitZoom(ns.Config.CARD_MODEL_ZOOM)
  end)
  if not ok then print(ModelTest.errorLine(err)) end
  frame:Show()
  report("at once")
  for _, delay in ipairs(CHECK_DELAYS) do
    C_Timer.After(delay, function() if frame:IsShown() then report("after "..delay.." s") end end)
  end
end

if ns.Slash then
  ns.Slash.register({
    name = "model",
    usage = "model <npcID> | model display <displayID>",
    help = "Developer: show a creature's 3D model and whether it loads",
    handler = handleModel,
  })
end
