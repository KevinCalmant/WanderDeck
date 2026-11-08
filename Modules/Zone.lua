local _, ns = ...

local type, assert = type, assert

-- Enum.UIMapType: Cosmic 0, World 1, Continent 2, Zone 3, Dungeon 4, Micro 5, Orphan 6.
local UIMapType = (Enum and Enum.UIMapType) or {}
local MAP_TYPE_CONTINENT = UIMapType.Continent or 2
local MAP_TYPE_ZONE = UIMapType.Zone or 3

-- Guards against a malformed or cyclic parent chain.
local MAX_DEPTH = 10

local isMapID = ns.Utils.isMapID

---A plain map ID, or nil when `value` is secret or not a valid map ID. The
---secret check runs first: a secret number reports type "number" but throws on compare.
local function plainMapID(value, isSecret)
  if isSecret(value) or not isMapID(value) then return nil end
  return value
end

---A plain number, or nil when `value` is secret or not a number.
local function plainNumber(value, isSecret)
  if isSecret(value) or type(value) ~= "number" then return nil end
  return value
end

---Walks up the map tree from `mapID` to the zone-level map. Subzones,
---micro-dungeons and floors roll up to their zone; continents and above have
---no zone. Any secret value on the way yields nil.
---@param mapID number|nil uiMapID, e.g. from C_Map.GetBestMapForUnit
---@param getMapInfo fun(mapID: number): table|nil C_Map.GetMapInfo or a stub
---@param isSecret? fun(value: any): boolean defaults to Wow.isSecret, so a caller that omits it still honours the client's secret check
---@return number|nil zoneMapID
local function resolve(mapID, getMapInfo, isSecret)
  isSecret = isSecret or (ns.Wow and ns.Wow.isSecret)
  assert(type(isSecret) == "function", "Zone.resolve needs an isSecret function")
  local current = plainMapID(mapID, isSecret)
  if not current or type(getMapInfo) ~= "function" then return nil end

  for _ = 1, MAX_DEPTH do
    local info = getMapInfo(current)
    if isSecret(info) or type(info) ~= "table" then return nil end

    local mapType = plainNumber(info.mapType, isSecret)
    if not mapType then return nil end
    if mapType == MAP_TYPE_ZONE then return current end
    if mapType <= MAP_TYPE_CONTINENT then return nil end

    local parent = plainMapID(info.parentMapID, isSecret)
    if not parent or parent == current then return nil end
    current = parent
  end
  return nil
end

ns.Zone = {
  resolve = resolve,
  MAP_TYPE_ZONE = MAP_TYPE_ZONE,
}
