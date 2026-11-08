local addonName, ns = ...

local Slash = ns.Slash
local Schema = ns.Schema
local Config = ns.Config
local Walker = ns.Walker

local defaultSavedVars = {
  global = {
    schemaVersion = Schema.CURRENT_VERSION,
  },
  char = {
    stats = { yards = 0 },
    progress = { total = 0, byZone = {} },
    packs = {},
  },
}

local db

---@return table|nil AceDB object, nil before ADDON_LOADED
function ns.GetDB() return db end

local eventFrame = CreateFrame("Frame")

eventFrame:SetScript("OnEvent", function(self, event, loadedAddon)
  if event == "ADDON_LOADED" and loadedAddon == addonName then
    _G.WanderDeckDB = Schema.sanitizeRoot(_G.WanderDeckDB)
    db = LibStub("AceDB-3.0"):New("WanderDeckDB", defaultSavedVars, true)
    if Schema.sanitizeGlobal(db.global) == "newer" then
      ns.print("Saved data comes from a newer WanderDeck version; update the addon.")
    end
    Schema.sanitizeChar(db.char, Config.MAX_UNOPENED_PACKS)
    self:UnregisterEvent("ADDON_LOADED")
    Walker.start()
  end
end)

eventFrame:RegisterEvent("ADDON_LOADED")

_G.SLASH_WANDERDECK1 = "/wanderdeck"
_G.SLASH_WANDERDECK2 = "/wd"
_G.SlashCmdList.WANDERDECK = Slash.dispatch
