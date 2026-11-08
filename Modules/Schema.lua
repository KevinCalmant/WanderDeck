local _, ns = ...

local type, floor = type, math.floor

-- Bump with a migration step for every SavedVariables layout change.
local CURRENT_VERSION = 1

---Sanitizes the account-wide saved data in place. SavedVariables are a
---user-editable file: every value is checked before use.
---@param global table AceDB `db.global`
---@return string status "ok", "repaired" (bad version reset) or "newer" (saved by a newer addon version; left untouched)
local function sanitizeGlobal(global)
  local version = global.schemaVersion
  if type(version) ~= "number" or version ~= floor(version) or version < 1 then
    global.schemaVersion = CURRENT_VERSION
    return "repaired"
  end
  if version > CURRENT_VERSION then return "newer" end
  return "ok"
end

ns.Schema = {
  CURRENT_VERSION = CURRENT_VERSION,
  sanitizeGlobal = sanitizeGlobal,
}
