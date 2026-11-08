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

---A plain number, or nil when secret or not a number.
local function plainNumber(value)
  if isSecret(value) or type(value) ~= "number" then return nil end
  return value
end

---Reads one boolean movement flag. Returns true, false, or the reason it
---cannot be trusted ("missing-api", "secret"). A secret boolean cannot even be
---tested for truth, so the secret check runs first.
local function readFlag(env, name, ...)
  local fn = env[name]
  if type(fn) ~= "function" then return "missing-api" end
  local value = fn(...)
  if isSecret(value) then return "secret" end
  return value and true or false
end

-- Checked in order; the first that is not false blocks the sample.
local FLAGS = {
  { name = "UnitIsDeadOrGhost", unit = true, reason = "dead" },
  { name = "UnitOnTaxi", unit = true, reason = "taxi" },
  { name = "UnitInVehicle", unit = true, reason = "vehicle" },
  { name = "IsMounted", reason = "mounted" },
  { name = "IsInInstance", reason = "instance" },
}

---Samples the player's position and the conditions that stop steps from
---counting (see CLAUDE.md, Domain rules). Only walking outdoors counts.
---@param env table _G or a test stub
---@return MovementSample
local function readMovementSample(env)
  local now = type(env.GetTime) == "function" and plainNumber(env.GetTime()) or nil
  local sample = { time = now }
  if not now or now ~= now then sample.blocked = "no-time" return sample end

  for _, flag in ipairs(FLAGS) do
    local value
    if flag.unit then value = readFlag(env, flag.name, "player") else value = readFlag(env, flag.name) end
    if value == true then sample.blocked = flag.reason return sample end
    if value ~= false then sample.blocked = value return sample end
  end

  if type(env.UnitPosition) ~= "function" then sample.blocked = "missing-api" return sample end
  local y, x, _, instanceID = env.UnitPosition("player")
  y, x, instanceID = plainNumber(y), plainNumber(x), plainNumber(instanceID)
  if not (x and y and instanceID) then sample.blocked = "no-position" return sample end
  sample.x, sample.y, sample.instanceID = x, y, instanceID

  local C_Map = env.C_Map
  if type(C_Map) ~= "table" or type(C_Map.GetBestMapForUnit) ~= "function" then
    sample.blocked = "missing-api"
    return sample
  end
  sample.zoneMapID = ns.Zone.resolve(C_Map.GetBestMapForUnit("player"), C_Map.GetMapInfo, isSecret)
  if not sample.zoneMapID then sample.blocked = "no-zone" end
  return sample
end

ns.Wow = {
  isSecret = isSecret,
  readMovementSample = readMovementSample,
}
