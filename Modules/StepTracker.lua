local _, ns = ...

local type, sqrt = type, math.sqrt

---@class MovementSample
---@field time number seconds (GetTime)
---@field x number|nil yards, from UnitPosition
---@field y number|nil yards, from UnitPosition
---@field instanceID number|nil UnitPosition's 4th value (continent or instance)
---@field zoneMapID number|nil zone-level uiMapID
---@field blocked string|nil why this sample cannot count (taxi, mounted, ...)

---Yards walked between two samples, or nil and the reason the delta does not
---count. Only plain numbers reach here: Wow.readMovementSample turns secret or
---missing values into `blocked`.
---@param prev MovementSample|nil previous countable sample
---@param cur MovementSample
---@param config table ns.Config
---@return number|nil yards
---@return string|nil reason
local function measure(prev, cur, config)
  if type(cur) ~= "table" then return nil, "no-sample" end
  if cur.blocked then return nil, cur.blocked end
  if type(prev) ~= "table" then return nil, "first" end
  if prev.instanceID ~= cur.instanceID then return nil, "instance-changed" end
  if prev.zoneMapID ~= cur.zoneMapID then return nil, "zone-changed" end

  local dt = cur.time - prev.time
  if not (dt > 0) then return nil, "no-time" end
  if dt > config.MAX_SAMPLE_GAP then return nil, "stale" end

  local dx, dy = cur.x - prev.x, cur.y - prev.y
  local yards = sqrt(dx * dx + dy * dy)
  if yards ~= yards then return nil, "no-position" end -- NaN
  if yards > config.MAX_FOOT_SPEED * dt then return nil, "too-fast" end
  return yards, nil
end

ns.StepTracker = {
  measure = measure,
}
