local addonName, ns = ...

local Slash = ns.Slash
local Schema = ns.Schema
local Config = ns.Config
local Walker = ns.Walker
local Migration = ns.Migration

local defaultSavedVars = {
  -- No schemaVersion default: AceDB strips a value equal to its default on
  -- logout, which would hide the version from the next migration.
  global = {
    settings = { sound = true, minimapHidden = false, minimapAngle = Schema.DEFAULT_MINIMAP_ANGLE },
    -- The card collection is account-wide (schema version 2).
    collection = {},
    newCards = {},
    tags = {},
    pinned = {},
  },
  -- Walking stays per character: steps, pack progress, unopened packs.
  char = {
    stats = { yards = 0 },
    progress = { total = 0, byZone = {} },
    packs = {},
  },
}

local db

---@return table|nil AceDB object, nil before ADDON_LOADED
function ns.GetDB() return db end

---Refreshes the UI parts that show pack counts (minimap badge). Safe to call
---any time; a missing or failing part is skipped.
function ns.refreshUI()
  if ns.MinimapButton and ns.MinimapButton.refresh then pcall(ns.MinimapButton.refresh) end
  if ns.BinderFrame and ns.BinderFrame.refreshIfShown then pcall(ns.BinderFrame.refreshIfShown) end
end

local eventFrame = CreateFrame("Frame")

eventFrame:SetScript("OnEvent", function(self, event, arg1, arg2)
  if event == "ITEM_DATA_LOAD_RESULT" then
    -- One of our item cards may have just loaded (arg1 = itemID, arg2 = success).
    ns.CardText.onItemDataLoaded(arg1, arg2, C_Timer and C_Timer.After, ns.refreshUI)
  elseif event == "ADDON_LOADED" and arg1 == addonName then
    local sv = Schema.sanitizeRoot(_G.WanderDeckDB)
    -- Before AceDB: the merge reads every character, not only this one.
    Migration.run(sv, Config.MAX_COPIES)
    _G.WanderDeckDB = sv
    db = LibStub("AceDB-3.0"):New("WanderDeckDB", defaultSavedVars, true)
    if Schema.sanitizeGlobal(db.global) == "newer" then
      ns.print("Saved data comes from a newer WanderDeck version; update the addon.")
    end
    Schema.sanitizeSettings(db.global)
    Schema.sanitizeChar(db.char, Config.MAX_UNOPENED_PACKS)
    local dataLoaded = ns.Cards.dataLoaded == true
    Schema.sanitizeCollection(db.global, ns.Cards.get, Config.MAX_COPIES, dataLoaded)
    ns.Tags.sanitize(db.global, ns.Cards.get, dataLoaded)
    self:UnregisterEvent("ADDON_LOADED")
    Walker.start()
    if ns.MinimapButton then pcall(ns.MinimapButton.init) end
  end
end)

eventFrame:RegisterEvent("ADDON_LOADED")
-- Optional: a client without this event simply keeps the fallback name until
-- the next redraw.
pcall(eventFrame.RegisterEvent, eventFrame, "ITEM_DATA_LOAD_RESULT")

_G.SLASH_WANDERDECK1 = "/wanderdeck"
_G.SLASH_WANDERDECK2 = "/wd"
_G.SlashCmdList.WANDERDECK = Slash.dispatch
