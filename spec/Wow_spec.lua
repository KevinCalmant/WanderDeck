local mocks = require("wow_mocks")

describe("Wow.isSecret", function()
  local Wow

  before_each(function()
    mocks.reset()
    local ns = mocks.newNamespace()
    mocks.loadSource("Utils/Wow.lua", ns)
    Wow = ns.Wow
  end)

  it("returns false when the client has no issecretvalue", function()
    assert.is_false(Wow.isSecret(12))
  end)

  it("returns true for a value the client marks secret", function()
    local secret = mocks.newSecret()
    mocks.installSecrets({ secret })
    assert.is_true(Wow.isSecret(secret))
  end)

  it("returns false for a plain value", function()
    mocks.installSecrets({})
    assert.is_false(Wow.isSecret(12))
    assert.is_false(Wow.isSecret(nil))
  end)

  describe("readMovementSample", function()
    local ns

    before_each(function()
      mocks.reset()
      ns = mocks.newNamespace()
      mocks.loadSource("Utils/Wow.lua", ns)
      mocks.loadSource("Modules/Zone.lua", ns)
      Wow = ns.Wow
    end)

    -- Westfall, on foot, outdoors: the situation /wd probe recorded.
    local function outdoorEnv()
      local maps = { [1436] = { mapType = 3, parentMapID = 1415 } }
      local function no() return false end
      return {
        GetTime = function() return 42 end,
        UnitIsDeadOrGhost = no, UnitOnTaxi = no, UnitInVehicle = no, IsMounted = no,
        IsInInstance = function() return false, "none" end,
        UnitPosition = function() return -11275.9, 1684.7, 0, 0 end,
        C_Map = {
          GetBestMapForUnit = function() return 1436 end,
          GetMapInfo = function(id) return maps[id] end,
        },
      }
    end

    it("returns a countable sample outdoors on foot", function()
      local s = Wow.readMovementSample(outdoorEnv())
      assert.same({ time = 42, x = 1684.7, y = -11275.9, instanceID = 0, zoneMapID = 1436 }, s)
    end)

    it("blocks with the reason of each active flag", function()
      local cases = {
        UnitIsDeadOrGhost = "dead", UnitOnTaxi = "taxi", UnitInVehicle = "vehicle",
        IsMounted = "mounted", IsInInstance = "instance",
      }
      for api, reason in pairs(cases) do
        local env = outdoorEnv()
        env[api] = function() return true end
        assert.equals(reason, Wow.readMovementSample(env).blocked, api)
      end
    end)

    it("blocks on a secret flag without testing its truth", function()
      local secret = mocks.newSecret()
      mocks.installSecrets({ secret })
      local env = outdoorEnv()
      env.IsMounted = function() return secret end
      assert.equals("secret", Wow.readMovementSample(env).blocked)
    end)

    it("blocks on a secret value from each flag API", function()
      for _, api in ipairs({ "UnitIsDeadOrGhost", "UnitOnTaxi", "UnitInVehicle", "IsMounted", "IsInInstance" }) do
        local secret = mocks.newSecret()
        mocks.installSecrets({ secret })
        local env = outdoorEnv()
        env[api] = function() return secret end
        assert.equals("secret", Wow.readMovementSample(env).blocked, api)
      end
    end)

    it("blocks on a secret plain boolean (secret booleans report a normal type)", function()
      _G.issecretvalue = function(v) return v == false end
      assert.equals("secret", Wow.readMovementSample(outdoorEnv()).blocked)
    end)

    it("blocks on a secret, nil, NaN or missing time", function()
      _G.issecretvalue = function(v) return v == 42 end
      assert.equals("no-time", Wow.readMovementSample(outdoorEnv()).blocked)
      _G.issecretvalue = nil
      local env = outdoorEnv()
      env.GetTime = function() return nil end
      assert.equals("no-time", Wow.readMovementSample(env).blocked)
      env.GetTime = function() return 0 / 0 end
      assert.equals("no-time", Wow.readMovementSample(env).blocked)
      env.GetTime = nil
      assert.equals("no-time", Wow.readMovementSample(env).blocked)
    end)

    it("blocks on a secret y or instanceID", function()
      _G.issecretvalue = function(v) return v == -11275.9 end
      assert.equals("no-position", Wow.readMovementSample(outdoorEnv()).blocked)
      local env = outdoorEnv()
      env.UnitPosition = function() return -11275.9, 1684.7, 0, 777 end
      _G.issecretvalue = function(v) return v == 777 end
      assert.equals("no-position", Wow.readMovementSample(env).blocked)
    end)

    it("blocks when a flag API is missing", function()
      local env = outdoorEnv()
      env.UnitOnTaxi = nil
      assert.equals("missing-api", Wow.readMovementSample(env).blocked)
    end)

    it("blocks on a secret, nil or missing position", function()
      _G.issecretvalue = function(v) return v == 1684.7 end
      assert.equals("no-position", Wow.readMovementSample(outdoorEnv()).blocked)
      _G.issecretvalue = nil

      local env = outdoorEnv()
      env.UnitPosition = function() return nil end
      assert.equals("no-position", Wow.readMovementSample(env).blocked)

      env.UnitPosition = nil
      assert.equals("missing-api", Wow.readMovementSample(env).blocked)
    end)

    it("blocks when the zone cannot be resolved", function()
      local env = outdoorEnv()
      env.C_Map.GetBestMapForUnit = function() return nil end
      assert.equals("no-zone", Wow.readMovementSample(env).blocked)
    end)

    it("blocks on a secret map ID", function()
      _G.issecretvalue = function(v) return v == 1436 end
      assert.equals("no-zone", Wow.readMovementSample(outdoorEnv()).blocked)
    end)

    it("blocks when C_Map is missing", function()
      local env = outdoorEnv()
      env.C_Map = nil
      assert.equals("missing-api", Wow.readMovementSample(env).blocked)
    end)
  end)

  it("always returns a boolean", function()
    _G.issecretvalue = function() return 1 end
    assert.equals(true, Wow.isSecret("x"))
    _G.issecretvalue = function() return nil end
    assert.equals(false, Wow.isSecret("x"))
  end)
end)
