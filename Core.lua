local addonName, ns = ...

local Slash = ns.Slash
local Schema = ns.Schema
local Config = ns.Config
local Walker = ns.Walker

local defaultSavedVars = {
  global = {
    schemaVersion = Schema.CURRENT_VERSION,
    settings = { sound = true, minimapHidden = false, minimapAngle = Schema.DEFAULT_MINIMAP_ANGLE },
  },
  char = {
    stats = { yards = 0 },
    progress = { total = 0, byZone = {} },
    packs = {},
    collection = {},
    newCards = {},
    tags = {},
    pinned = {},
  },
}

local db

---@return table|nil AceDB object, nil before ADDON_LOADED
function ns.GetDB() return db end

---Refreshes the UI parts that show pack counts (minimap badge). Safe to call
---any time; a missing or failing part is skipped.
function ns.refreshUI()
  if ns.MinimapButton and ns.MinimapButton.refresh then pcall(ns.MinimapButton.refresh) end
end

local eventFrame = CreateFrame("Frame")

eventFrame:SetScript("OnEvent", function(self, event, loadedAddon)
  if event == "ADDON_LOADED" and loadedAddon == addonName then
    _G.WanderDeckDB = Schema.sanitizeRoot(_G.WanderDeckDB)
    db = LibStub("AceDB-3.0"):New("WanderDeckDB", defaultSavedVars, true)
    if Schema.sanitizeGlobal(db.global) == "newer" then
      ns.print("Saved data comes from a newer WanderDeck version; update the addon.")
    end
    Schema.sanitizeSettings(db.global)
    Schema.sanitizeChar(db.char, Config.MAX_UNOPENED_PACKS)
    local dataLoaded = ns.Cards.dataLoaded == true
    Schema.sanitizeCollection(db.char, ns.Cards.get, Config.MAX_COPIES, dataLoaded)
    ns.Tags.sanitize(db.char, ns.Cards.get, dataLoaded)
    self:UnregisterEvent("ADDON_LOADED")
    Walker.start()
    if ns.MinimapButton then pcall(ns.MinimapButton.init) end
  end
end)

eventFrame:RegisterEvent("ADDON_LOADED")

_G.SLASH_WANDERDECK1 = "/wanderdeck"
_G.SLASH_WANDERDECK2 = "/wd"
_G.SlashCmdList.WANDERDECK = Slash.dispatch
