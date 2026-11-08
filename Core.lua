local addonName, ns = ...

local Slash = ns.Slash
local Schema = ns.Schema

local defaultSavedVars = {
  global = {
    schemaVersion = Schema.CURRENT_VERSION,
  },
  char = {},
}

local db

---@return table|nil AceDB object, nil before ADDON_LOADED
function ns.GetDB() return db end

local eventFrame = CreateFrame("Frame")

eventFrame:SetScript("OnEvent", function(self, event, loadedAddon)
  if event == "ADDON_LOADED" and loadedAddon == addonName then
    -- A hand-edited file can leave a non-table here; AceDB expects a table or nil.
    if type(_G.WanderDeckDB) ~= "table" then _G.WanderDeckDB = nil end
    db = LibStub("AceDB-3.0"):New("WanderDeckDB", defaultSavedVars, true)
    if Schema.sanitizeGlobal(db.global) == "newer" then
      ns.print("Saved data comes from a newer WanderDeck version; update the addon.")
    end
    self:UnregisterEvent("ADDON_LOADED")
  end
end)

eventFrame:RegisterEvent("ADDON_LOADED")

_G.SLASH_WANDERDECK1 = "/wanderdeck"
_G.SLASH_WANDERDECK2 = "/wd"
_G.SlashCmdList.WANDERDECK = Slash.dispatch
