local mocks = require("wow_mocks")

describe("Walker", function()
  local ns, Walker, printed, cancelled

  before_each(function()
    mocks.reset()
    ns, printed = mocks.newNamespace()
    for _, file in ipairs({
      "Utils/Wow.lua", "Modules/Config.lua", "Modules/Zone.lua", "Modules/StepTracker.lua",
      "Modules/Packs.lua", "Modules/Slash.lua", "Modules/Walker.lua",
    }) do
      mocks.loadSource(file, ns)
    end
    Walker = ns.Walker
    cancelled = false
    _G.C_Timer = { NewTicker = function() return { Cancel = function() cancelled = true end } end }
    _G.C_Map = nil
  end)

  after_each(function()
    _G.C_Timer, _G.C_Map = nil, nil
  end)

  describe("zoneName", function()
    local function withName(name)
      _G.C_Map = { GetMapInfo = function() return { name = name } end }
    end

    it("returns the zone name", function()
      withName("Marche de l'Ouest")
      assert.equals("Marche de l'Ouest", Walker.zoneName(1436))
    end)

    it("escapes chat codes and line breaks", function()
      withName("Westfall|cffff0000Evil|r |TInterface\\Icons\\x:0|t |Hitem:1|h[x]|h\nnext")
      local name = Walker.zoneName(1436)
      assert.equals("Westfall||cffff0000Evil||r ||TInterface\\Icons\\x:0||t ||Hitem:1||h[x]||h next", name)
      assert.is_nil(name:find("[^|]|[cTHrth]"))
    end)

    it("falls back to the map ID when info is missing, wrong or secret", function()
      _G.C_Map = { GetMapInfo = function() return nil end }
      assert.equals("1436", Walker.zoneName(1436))
      _G.C_Map = { GetMapInfo = function() return "x" end }
      assert.equals("1436", Walker.zoneName(1436))
      withName(42)
      assert.equals("1436", Walker.zoneName(1436))
      local secret = mocks.newSecret()
      mocks.installSecrets({ secret })
      withName(secret)
      assert.equals("1436", Walker.zoneName(1436))
    end)

    it("falls back to the map ID when the lookup throws or C_Map is missing", function()
      _G.C_Map = { GetMapInfo = function() error("bad argument") end }
      assert.equals("1436", Walker.zoneName(1436))
      _G.C_Map = nil
      assert.equals("1436", Walker.zoneName(1436))
    end)
  end)

  describe("/wd status", function()
    local lines, originalPrint

    before_each(function()
      lines = {}
      originalPrint = _G.print
      _G.print = function(msg) lines[#lines + 1] = tostring(msg) end
    end)

    after_each(function()
      _G.print = originalPrint
    end)

    it("lists at most 10 zone shares, with escaped names", function()
      local byZone = {}
      for i = 1, 30 do byZone[i] = 1 end
      ns.GetDB = function()
        return { char = { stats = { yards = 30 }, progress = { total = 30, byZone = byZone }, packs = {} } }
      end
      _G.C_Map = { GetMapInfo = function() return { name = "|cffff0000Evil|r" } end }
      ns.Slash.dispatch("status")
      assert.equals(10, #lines)
      for _, line in ipairs(lines) do
        assert.truthy(line:find("||cffff0000Evil||r", 1, true))
      end
    end)
  end)

  describe("tick", function()
    local char

    before_each(function()
      char = { stats = { yards = 0 }, progress = { total = 0, byZone = {} }, packs = {} }
      ns.GetDB = function() return { char = char } end
    end)

    it("stops the ticker after MAX_TICK_FAILURES consecutive errors", function()
      ns.Wow.readMovementSample = function() error("client change") end
      Walker.start()
      for _ = 1, ns.Config.MAX_TICK_FAILURES - 1 do Walker.tick() end
      assert.is_false(cancelled)
      Walker.tick()
      assert.is_true(cancelled)
      assert.matches("Step tracking stopped", printed[#printed], 1, true)
    end)

    it("does not measure across a failed tick", function()
      local calls = 0
      ns.Wow.readMovementSample = function()
        calls = calls + 1
        if calls == 1 then return { time = 1, x = 0, y = 0, instanceID = 0, zoneMapID = 1436 } end
        if calls == 2 then error("transient") end
        return { time = 1.5, x = 5, y = 0, instanceID = 0, zoneMapID = 1436 }
      end
      Walker.start()
      Walker.tick()
      Walker.tick()
      Walker.tick()
      assert.equals(0, char.stats.yards)
      Walker.stop()
    end)

    it("resets the failure count after a good tick", function()
      local fail = true
      ns.Wow.readMovementSample = function()
        if fail then error("transient") end
        return { time = 1, blocked = "mounted" }
      end
      Walker.start()
      for _ = 1, ns.Config.MAX_TICK_FAILURES - 1 do Walker.tick() end
      fail = false
      Walker.tick()
      fail = true
      for _ = 1, ns.Config.MAX_TICK_FAILURES - 1 do Walker.tick() end
      assert.is_false(cancelled)
      Walker.stop()
    end)

    it("counts walked yards and earns a pack with a valid timestamp", function()
      local samples = {
        { time = 1, x = 0, y = 0, instanceID = 0, zoneMapID = 1436 },
        { time = 2, x = 10, y = 0, instanceID = 0, zoneMapID = 1436 },
      }
      local i = 0
      ns.Wow.readMovementSample = function() i = i + 1 return samples[i] end
      ns.Config.STEPS_PER_PACK, ns.Config.YARDS_PER_STEP = 10, 1
      _G.GetServerTime = function() return 1794158614 end
      Walker.start()
      Walker.tick()
      Walker.tick()
      assert.equals(10, char.stats.yards)
      assert.same({ { zoneMapID = 1436, earnedAt = 1794158614 } }, char.packs)
      Walker.stop()
      _G.GetServerTime = nil
    end)

    it("stores 0 as the timestamp when GetServerTime is secret or throws", function()
      local secret = mocks.newSecret()
      mocks.installSecrets({ secret })
      for _, serverTime in ipairs({ function() return secret end, function() error("x") end }) do
        char.packs = {}
        local samples = {
          { time = 1, x = 0, y = 0, instanceID = 0, zoneMapID = 1436 },
          { time = 2, x = 10, y = 0, instanceID = 0, zoneMapID = 1436 },
        }
        local i = 0
        ns.Wow.readMovementSample = function() i = i + 1 return samples[i] end
        ns.Config.STEPS_PER_PACK, ns.Config.YARDS_PER_STEP = 10, 1
        _G.GetServerTime = serverTime
        Walker.start()
        Walker.tick()
        Walker.tick()
        assert.equals(0, char.packs[1].earnedAt)
        Walker.stop()
      end
      _G.GetServerTime = nil
    end)
  end)
end)
