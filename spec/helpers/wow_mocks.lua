-- Minimal stubs for the slice of the WoW runtime the pure modules touch.
-- Extend as more modules come under test.

local M = {}

---Fresh addon namespace shaped like init.lua's, with a recording print.
---@return table ns, table printed list of printed strings
function M.newNamespace()
  local printed = {}
  local ns = {
    L = setmetatable({}, { __index = function(_, key) return key end }),
    print = function(msg) printed[#printed + 1] = tostring(msg) end,
  }
  -- Utils/General.lua is pure and loaded first by the client: preload it.
  local chunk = assert(loadfile("Utils/General.lua"))
  chunk("WanderDeck", ns)
  return ns, printed
end

---Resets the WoW globals the modules read, so each test starts clean.
function M.reset()
  _G.issecretvalue = nil
  _G.Enum = nil
  _G.GetLocale = function() return "enUS" end
end

---Runs an addon file the way the client does: with (addonName, ns) as varargs.
---@param relPath string repo-relative path
---@param ns table namespace from newNamespace
---@return table ns
function M.loadSource(relPath, ns)
  local chunk, err = loadfile(relPath)
  assert(chunk, err)
  chunk("WanderDeck", ns)
  return ns
end

---A stand-in for a Midnight secret value: any use besides passing it around
---(tostring, comparison, math, indexing) raises, like the real client.
function M.newSecret()
  local function boom() error("attempt to use a secret value", 2) end
  return setmetatable({}, {
    __tostring = boom, __eq = boom, __lt = boom, __le = boom,
    __add = boom, __sub = boom, __concat = boom, __len = boom,
    __index = boom, __newindex = boom, __call = boom,
  })
end

---Installs a global issecretvalue that recognises secrets from newSecret.
---@param secrets table[] values to treat as secret
function M.installSecrets(secrets)
  local set = {}
  for _, s in ipairs(secrets) do set[s] = true end
  _G.issecretvalue = function(v) return set[v] == true end
end

return M
