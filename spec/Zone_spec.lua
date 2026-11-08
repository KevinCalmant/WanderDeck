local mocks = require("wow_mocks")

-- Map tree used by the tests: 1 Cosmic > 13 Continent > 37 Zone > 9001 Micro > 9002 Floor.
local MAPS = {
  [1] = { mapType = 0, parentMapID = 0 },
  [13] = { mapType = 2, parentMapID = 1 },
  [37] = { mapType = 3, parentMapID = 13 },
  [9001] = { mapType = 5, parentMapID = 37 },
  [9002] = { mapType = 4, parentMapID = 9001 },
  [500] = { mapType = 6, parentMapID = 501 }, -- orphan pair forming a cycle
  [501] = { mapType = 6, parentMapID = 500 },
  [600] = { mapType = 5, parentMapID = 600 }, -- parent is itself
  [700] = { mapType = 5 },                    -- no parent
  [800] = { parentMapID = 37 },               -- no mapType
}

local function getMapInfo(mapID) return MAPS[mapID] end

describe("Zone.resolve", function()
  local Zone

  before_each(function()
    mocks.reset()
    local ns = mocks.newNamespace()
    mocks.loadSource("Utils/Wow.lua", ns)
    mocks.loadSource("Modules/Zone.lua", ns)
    Zone = ns.Zone
  end)

  it("defaults to the client's secret check when isSecret is omitted", function()
    _G.issecretvalue = function(v) return v == 9001 end
    assert.is_nil(Zone.resolve(9001, getMapInfo))
  end)

  it("refuses to run without any secret check", function()
    local ns = mocks.newNamespace()
    mocks.loadSource("Modules/Zone.lua", ns)
    local ok, err = pcall(ns.Zone.resolve, 37, getMapInfo)
    assert.is_false(ok)
    assert.matches("Zone.resolve needs an isSecret function", err, 1, true)
  end)

  it("refuses a truthy isSecret that is not a function", function()
    for _, bad in ipairs({ true, {}, "x" }) do
      local ok, err = pcall(Zone.resolve, 37, getMapInfo, bad)
      assert.is_false(ok)
      assert.matches("Zone.resolve needs an isSecret function", err, 1, true)
    end
  end)

  it("returns a zone map unchanged", function()
    assert.equals(37, Zone.resolve(37, getMapInfo))
  end)

  it("rolls a micro map up to its zone", function()
    assert.equals(37, Zone.resolve(9001, getMapInfo))
  end)

  it("rolls a nested floor up through several levels", function()
    assert.equals(37, Zone.resolve(9002, getMapInfo))
  end)

  it("returns nil for a continent", function()
    assert.is_nil(Zone.resolve(13, getMapInfo))
  end)

  it("returns nil for an unknown map", function()
    assert.is_nil(Zone.resolve(424242, getMapInfo))
  end)

  it("returns nil for a map ID that is not a positive int32 integer", function()
    for _, bad in ipairs({ "nil", "37", 0 / 0, 0, -37, 37.5, 2 ^ 31, math.huge }) do
      assert.is_nil(Zone.resolve(bad ~= "nil" and bad or nil, getMapInfo))
    end
  end)

  it("returns nil without a map info function", function()
    assert.is_nil(Zone.resolve(37, nil))
  end)

  it("stops on a parent cycle", function()
    assert.is_nil(Zone.resolve(500, getMapInfo))
  end)

  it("stops when a map is its own parent", function()
    assert.is_nil(Zone.resolve(600, getMapInfo))
  end)

  it("stops when a map has no parent", function()
    assert.is_nil(Zone.resolve(700, getMapInfo))
  end)

  it("stops on a parent that is not a positive int32 integer, without looking it up", function()
    for _, bad in ipairs({ 0, 0 / 0, 37.5, 2 ^ 31, math.huge, "37" }) do
      local calls = 0
      local function lookup(id)
        calls = calls + 1
        if id == 1 then return { mapType = 5, parentMapID = bad } end
        return MAPS[id]
      end
      assert.is_nil(Zone.resolve(1, lookup))
      assert.equals(1, calls)
    end
  end)

  it("stops when a map has no mapType", function()
    assert.is_nil(Zone.resolve(800, getMapInfo))
  end)

  -- The real client's secret numbers report type "number"; flag plain numbers
  -- as secret so the type check cannot hide a missing secret guard.
  local function secretNumbers(...)
    local set = {}
    for _, n in ipairs({ ... }) do set[n] = true end
    return function(v) return type(v) == "number" and set[v] == true end
  end

  it("returns nil for a secret map ID without reading map info", function()
    local calls = 0
    local function counting(id) calls = calls + 1 return MAPS[id] end
    assert.is_nil(Zone.resolve(9001, counting, secretNumbers(9001)))
    assert.equals(0, calls)
  end)

  it("returns nil for a secret mapType", function()
    local maps = { [1] = { mapType = 777, parentMapID = 37 } }
    assert.is_nil(Zone.resolve(1, function(id) return maps[id] end, secretNumbers(777)))
  end)

  it("returns nil for a secret parentMapID", function()
    local maps = { [1] = { mapType = 5, parentMapID = 778 }, [778] = { mapType = 3 } }
    assert.is_nil(Zone.resolve(1, function(id) return maps[id] end, secretNumbers(778)))
  end)

  it("returns nil for secret map info", function()
    local secretInfo = MAPS[37]
    assert.is_nil(Zone.resolve(37, getMapInfo, function(v) return v == secretInfo end))
  end)

  it("uses Enum.UIMapType when the client provides it", function()
    _G.Enum = { UIMapType = { Continent = 20, Zone = 30 } }
    local ns = mocks.newNamespace()
    mocks.loadSource("Utils/Wow.lua", ns)
    mocks.loadSource("Modules/Zone.lua", ns)
    local custom = { [1] = { mapType = 30, parentMapID = 2 } }
    assert.equals(1, ns.Zone.resolve(1, function(id) return custom[id] end))
  end)
end)
