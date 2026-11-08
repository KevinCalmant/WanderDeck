local _, ns = ...

local pairs = pairs
local isFiniteNonNegative, isMapID = ns.Utils.isFiniteNonNegative, ns.Utils.isMapID

local function isFinitePositive(n)
  return isFiniteNonNegative(n) and n > 0
end

---Zone with the most yards in `byZone`. Ties go to `currentZone`, else to the
---lowest uiMapID, so the result never depends on table iteration order.
---@param byZone table<number, number>
---@param currentZone number
---@return number zoneMapID
local function majorityZone(byZone, currentZone)
  local best, bestYards = nil, -1
  for zone, yards in pairs(byZone) do
    if not isMapID(zone) or not isFiniteNonNegative(yards) then
      -- skip: only sanitized shares compete
    elseif yards > bestYards
      or (yards == bestYards and (zone == currentZone or (best ~= currentZone and zone < best))) then
      best, bestYards = zone, yards
    end
  end
  return best or currentZone
end

---Adds walked yards to the pack progress and returns the zone of the pack
---earned, if any. At most one pack per call: a delta is a fraction of a pack,
---and a hand-edited total must not loop.
---@param progress table char.progress: { total = yards, byZone = { [zoneMapID] = yards } }
---@param zoneMapID number zone the yards were walked in
---@param yards number
---@param config table ns.Config
---@return number|nil earnedZoneMapID
local function addDistance(progress, zoneMapID, yards, config)
  if not isFinitePositive(yards) or not isMapID(zoneMapID) then return nil end

  progress.byZone[zoneMapID] = (progress.byZone[zoneMapID] or 0) + yards
  progress.total = progress.total + yards

  local packYards = config.STEPS_PER_PACK * config.YARDS_PER_STEP
  if progress.total < packYards then return nil end

  local earned = majorityZone(progress.byZone, zoneMapID)
  local overflow = progress.total - packYards
  if overflow > packYards then overflow = 0 end -- corrupt total: start over
  progress.byZone = {}
  if overflow > 0 then progress.byZone[zoneMapID] = overflow end
  progress.total = overflow
  return earned
end

---Appends a pack unless the character already holds the maximum.
---@param packs table char.packs list
---@param pack table { zoneMapID, earnedAt }
---@param maxUnopened number
---@return boolean stored
local function store(packs, pack, maxUnopened)
  if not (#packs < maxUnopened) then return false end
  packs[#packs + 1] = pack
  return true
end

---Whole steps for a distance.
---@param yards number
---@param config table ns.Config
---@return number
local function toSteps(yards, config)
  return math.floor(yards / config.YARDS_PER_STEP)
end

ns.Packs = {
  majorityZone = majorityZone,
  addDistance = addDistance,
  store = store,
  toSteps = toSteps,
}
