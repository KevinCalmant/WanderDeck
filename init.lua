local _, ns = ...
_G.WanderDeck = ns

-- Missing translations fall back to the English key.
ns.L = setmetatable({}, { __index = function(_, key) return key end })

ns.CHAT_PREFIX = "|cff33ccffWanderDeck|r"

---Prints one chat line with the addon prefix.
---@param msg any
function ns.print(msg)
  print(ns.CHAT_PREFIX..": "..tostring(msg))
end
