local _, ns = ...

local type = type

---True when the client marks `value` as a Midnight secret value. Comparing,
---doing math on, indexing or using a secret as a table key throws, so check
---every unit- or map-derived value with this before using it.
---@param value any
---@return boolean
local function isSecret(value)
  if type(issecretvalue) ~= "function" then return false end
  return issecretvalue(value) and true or false
end

ns.Wow = {
  isSecret = isSecret,
}
