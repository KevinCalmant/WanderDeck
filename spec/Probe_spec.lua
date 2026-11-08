local mocks = require("wow_mocks")

local function vector(x, y)
  return { GetXY = function() return x, y end }
end

---A client where every probed API works and returns plain values.
local function fullEnv()
  local maps = {
    [1429] = { name = "Elwynn Forest", mapType = 3, parentMapID = 13 },
    [13] = { name = "Eastern Kingdoms", mapType = 2, parentMapID = 947 },
    [947] = { name = "Azeroth", mapType = 1, parentMapID = 0 },
  }
  local function yes() return true end
  local function no() return false end
  return {
    GetBuildInfo = function() return "1.60.1", "70500", "Nov 4 2026", 16001 end,
    WOW_PROJECT_ID = 99,
    issecretvalue = function() return false end,
    UnitPosition = function() return -8913.5, 554.25, 0, 0 end,
    C_Map = {
      GetBestMapForUnit = function() return 1429 end,
      GetMapInfo = function(id) return maps[id] end,
      GetPlayerMapPosition = function() return vector(0.4, 0.6) end,
      GetWorldPosFromMapPos = function() return 0, vector(-8913.5, 554.25) end,
    },
    GetUnitSpeed = function() return 7, 7, 4.5, 4.722 end,
    UnitOnTaxi = no, IsMounted = no, IsFlying = no, UnitInVehicle = no,
    UnitIsDeadOrGhost = no, IsIndoors = no, InCombatLockdown = no,
    IsInInstance = function() return false, "none" end,
    C_ChatInfo = { RegisterAddonMessagePrefix = yes, SendAddonMessage = yes },
    C_Timer = { NewTicker = yes },
    Settings = { RegisterProxySetting = yes },
    C_AddOns = { GetAddOnMetadata = yes },
  }
end

local function findLine(lines, prefix)
  for _, line in ipairs(lines) do
    if line:sub(1, #prefix) == prefix then return line end
  end
  return nil
end

describe("Probe", function()
  local Probe, Wow

  before_each(function()
    mocks.reset()
    local ns = mocks.newNamespace()
    mocks.loadSource("Utils/Wow.lua", ns)
    mocks.loadSource("Modules/Zone.lua", ns)
    mocks.loadSource("Developer/Probe.lua", ns)
    Probe, Wow = ns.Probe, ns.Wow
  end)

  describe("sanitizeLabel", function()
    it("defaults an empty label", function()
      assert.equals("default", Probe.sanitizeLabel(""))
    end)

    it("accepts letters, digits, dash and underscore", function()
      assert.equals("taxi_run-2", Probe.sanitizeLabel("taxi_run-2"))
    end)

    it("accepts exactly 24 characters", function()
      assert.equals(string.rep("a", 24), Probe.sanitizeLabel(string.rep("a", 24)))
    end)

    it("rejects 25 characters", function()
      assert.is_nil(Probe.sanitizeLabel(string.rep("a", 25)))
    end)

    it("rejects markup", function()
      assert.is_nil(Probe.sanitizeLabel("<script>"))
    end)

    it("rejects a valid label with a payload appended or prepended", function()
      assert.is_nil(Probe.sanitizeLabel("taxi<script>"))
      assert.is_nil(Probe.sanitizeLabel("<script>taxi"))
      assert.is_nil(Probe.sanitizeLabel("taxi|cffff0000"))
      assert.is_nil(Probe.sanitizeLabel("taxi\nrun"))
      assert.is_nil(Probe.sanitizeLabel("taxi run"))
    end)

    it("rejects whitespace, paths, quotes, separators and format codes", function()
      for _, bad in ipairs({ "   ", "\t", "../x", "a/b", "a'b", 'a"b', "a;b", "a#b", "${x}", "%s" }) do
        assert.is_nil(Probe.sanitizeLabel(bad), bad)
      end
    end)

    it("rejects non-ASCII and control bytes", function()
      assert.is_nil(Probe.sanitizeLabel("forêt"))
      assert.is_nil(Probe.sanitizeLabel("a\0b"))
    end)

    it("rejects non-strings", function()
      assert.is_nil(Probe.sanitizeLabel(nil))
      assert.is_nil(Probe.sanitizeLabel(12))
    end)
  end)

  describe("describe", function()
    it("renders a secret without touching it", function()
      local secret = mocks.newSecret()
      mocks.installSecrets({ secret })
      assert.equals("<secret>", Probe.describe(secret, Wow.isSecret))
    end)

    it("renders plain values", function()
      local isSecret = Wow.isSecret
      assert.equals("nil", Probe.describe(nil, isSecret))
      assert.equals("12", Probe.describe(12, isSecret))
      assert.equals("1.500", Probe.describe(1.5, isSecret))
      assert.equals('"Elwynn"', Probe.describe("Elwynn", isSecret))
      assert.equals("true", Probe.describe(true, isSecret))
      assert.equals("<table>", Probe.describe({}, isSecret))
    end)

    it("escapes newlines in strings", function()
      assert.equals('"a\\nb"', Probe.describe("a\nb", Wow.isSecret))
      assert.equals('"a\\rb"', Probe.describe("a\rb", Wow.isSecret))
    end)

    it("escapes a pipe next to a backslash or newline in either order", function()
      assert.equals('"\\\\||"', Probe.describe("\\|", Wow.isSecret))
      assert.equals('"||\\n"', Probe.describe("|\n", Wow.isSecret))
    end)

    it("renders NaN and infinity without crashing", function()
      assert.is_string(Probe.describe(0 / 0, Wow.isSecret))
      assert.is_string(Probe.describe(math.huge, Wow.isSecret))
    end)

    it("escapes WoW chat codes in strings", function()
      assert.equals('"||cffff0000red||r ||TInterface\\\\x:0||t"', Probe.describe("|cffff0000red|r |TInterface\\x:0|t", Wow.isSecret))
    end)
  end)

  describe("call", function()
    it("reports a missing API", function()
      assert.equals("missing", (Probe.call({}, "C_Map.GetBestMapForUnit")))
    end)

    it("reports a missing namespace without indexing nil", function()
      assert.equals("missing", (Probe.call({ C_Map = 5 }, "C_Map.GetBestMapForUnit")))
    end)

    it("reports a throwing API", function()
      local status, results = Probe.call({ F = function() error("blocked") end }, "F")
      assert.equals("error", status)
      assert.matches("blocked", results[1])
    end)

    it("escapes chat codes and line breaks in error messages", function()
      local env = { F = function() error("|cffff0000x|r|Hitem:1|h[a]|h\nb", 0) end }
      local _, results = Probe.call(env, "F")
      assert.truthy(results[1]:find("||c", 1, true))
      assert.truthy(results[1]:find("||H", 1, true))
      assert.is_nil(results[1]:find("[^|]|H"))
      assert.is_nil(results[1]:find("\n", 1, true))
    end)

    it("keeps nil return values in the middle", function()
      local status, results = Probe.call({ F = function() return 1, nil, 3 end }, "F")
      assert.equals("ok", status)
      assert.equals(3, results.n)
      assert.equals(3, results[3])
    end)
  end)

  describe("collect", function()
    it("reports every API on a working client", function()
      local lines = Probe.collect(fullEnv(), Wow.isSecret)
      assert.equals('GetBuildInfo: "1.60.1", "70500", "Nov 4 2026", 16001', lines[1])
      assert.equals("UnitPosition: -8913.500, 554.250, 0, 0", findLine(lines, "UnitPosition"))
      assert.equals("Zone.resolve: 1429", findLine(lines, "Zone.resolve"))
      assert.equals("C_Map.GetPlayerMapPosition: 0.400, 0.600", findLine(lines, "C_Map.GetPlayerMapPosition"))
      assert.equals("C_Map.GetWorldPosFromMapPos: continent=0 pos=-8913.500, 554.250", findLine(lines, "C_Map.GetWorldPosFromMapPos"))
      assert.equals('IsInInstance: false, "none"', findLine(lines, "IsInInstance"))
      assert.equals("C_ChatInfo.SendAddonMessage: present", findLine(lines, "C_ChatInfo.SendAddonMessage"))
      assert.truthy(findLine(lines, '  map[2] 13 name="Eastern Kingdoms" mapType=2 parent=947'))
    end)

    it("reports MISSING for every API on an empty client", function()
      local lines = Probe.collect({}, Wow.isSecret)
      assert.equals("GetBuildInfo: MISSING", lines[1])
      assert.equals("UnitPosition: MISSING", findLine(lines, "UnitPosition"))
      assert.equals("C_Map.GetBestMapForUnit: MISSING", findLine(lines, "C_Map.GetBestMapForUnit"))
      assert.is_nil(findLine(lines, "Zone.resolve"))
    end)

    it("reports an API that throws instead of crashing", function()
      local env = fullEnv()
      env.UnitPosition = function() error("restricted") end
      local line = findLine(Probe.collect(env, Wow.isSecret), "UnitPosition")
      assert.matches("^UnitPosition: ERROR .*restricted", line)
    end)

    it("marks secret positions and never uses them", function()
      local sy, sx = mocks.newSecret(), mocks.newSecret()
      mocks.installSecrets({ sy, sx })
      local env = fullEnv()
      env.UnitPosition = function() return sy, sx, 0, 0 end
      local line = findLine(Probe.collect(env, Wow.isSecret), "UnitPosition")
      assert.equals("UnitPosition: <secret>, <secret>, 0, 0", line)
    end)

    it("skips the map chain when the map ID is secret", function()
      local secretMap = mocks.newSecret()
      mocks.installSecrets({ secretMap })
      local env = fullEnv()
      env.C_Map.GetBestMapForUnit = function() return secretMap end
      local lines = Probe.collect(env, Wow.isSecret)
      assert.equals("C_Map.GetBestMapForUnit: <secret>", findLine(lines, "C_Map.GetBestMapForUnit"))
      assert.is_nil(findLine(lines, "Zone.resolve"))
    end)

    it("survives secret map info fields", function()
      local secretType = mocks.newSecret()
      mocks.installSecrets({ secretType })
      local env = fullEnv()
      env.C_Map.GetMapInfo = function() return { name = "x", mapType = secretType, parentMapID = 0 } end
      local lines = Probe.collect(env, Wow.isSecret)
      assert.truthy(findLine(lines, '  map[1] 1429 name="x" mapType=<secret> parent=0'))
      -- The real client throws on comparing a secret number (ERROR); the mock
      -- secret is a table, so Zone.resolve rejects it by type (nil). Either way
      -- the probe must report a line instead of crashing.
      assert.truthy(findLine(lines, "Zone.resolve: "))
    end)

    it("reports a nil map position (instances)", function()
      local env = fullEnv()
      env.C_Map.GetPlayerMapPosition = function() return nil end
      local line = findLine(Probe.collect(env, Wow.isSecret), "C_Map.GetPlayerMapPosition")
      assert.equals("C_Map.GetPlayerMapPosition: nil", line)
    end)
  end)

  describe("distance", function()
    it("measures a 3-4-5 triangle", function()
      assert.equals(5, Probe.distance(0, 0, 3, 4))
    end)
  end)

  describe("save", function()
    it("keeps only the newest runs", function()
      local store = {}
      for i = 1, 5 do Probe.save(store, { label = "run"..i }, 3) end
      assert.equals(3, #store)
      assert.equals("run3", store[1].label)
      assert.equals("run5", store[3].label)
    end)

    it("refuses a store that is not a list", function()
      for _, bad in ipairs({ "x", 5, true }) do
        assert.is_false(Probe.save(bad, { label = "run" }))
      end
    end)
  end)
end)
