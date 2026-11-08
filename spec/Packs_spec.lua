local mocks = require("wow_mocks")

-- 100 yards per pack keeps the numbers readable.
local CONFIG = { STEPS_PER_PACK = 100, YARDS_PER_STEP = 1 }

local function newProgress() return { total = 0, byZone = {} } end

describe("Packs", function()
  local Packs

  before_each(function()
    mocks.reset()
    local ns = mocks.newNamespace()
    mocks.loadSource("Modules/Packs.lua", ns)
    Packs = ns.Packs
  end)

  describe("majorityZone", function()
    it("picks the zone with the most yards", function()
      assert.equals(2, Packs.majorityZone({ [1] = 10, [2] = 60, [3] = 30 }, 3))
    end)

    it("gives a tie to the current zone", function()
      assert.equals(3, Packs.majorityZone({ [1] = 50, [3] = 50 }, 3))
      assert.equals(1, Packs.majorityZone({ [1] = 50, [3] = 50 }, 1))
    end)

    it("gives a tie without the current zone to the lowest map ID", function()
      assert.equals(4, Packs.majorityZone({ [9] = 50, [4] = 50, [7] = 50, [1] = 10 }, 1))
    end)

    it("ignores unsanitized shares", function()
      assert.equals(2, Packs.majorityZone({ [1] = 0 / 0, [2] = 5, [3] = -1, [1.5] = 99, [4] = "50" }, 9))
    end)

    it("falls back to the current zone when nothing was walked", function()
      assert.equals(5, Packs.majorityZone({}, 5))
    end)
  end)

  describe("addDistance", function()
    it("accumulates below the threshold without earning", function()
      local progress = newProgress()
      assert.is_nil(Packs.addDistance(progress, 1, 40, CONFIG))
      assert.is_nil(Packs.addDistance(progress, 2, 30, CONFIG))
      assert.equals(70, progress.total)
      assert.same({ [1] = 40, [2] = 30 }, progress.byZone)
    end)

    it("earns the pack for the majority zone, not the zone of the last step", function()
      local progress = newProgress()
      Packs.addDistance(progress, 1, 95, CONFIG)
      assert.equals(1, Packs.addDistance(progress, 2, 10, CONFIG))
    end)

    it("credits the overflow to the current zone and clears the rest", function()
      local progress = newProgress()
      Packs.addDistance(progress, 1, 95, CONFIG)
      Packs.addDistance(progress, 2, 10, CONFIG)
      assert.equals(5, progress.total)
      assert.same({ [2] = 5 }, progress.byZone)
    end)

    it("earns at exactly the threshold with no overflow", function()
      local progress = newProgress()
      assert.equals(1, Packs.addDistance(progress, 1, 100, CONFIG))
      assert.equals(0, progress.total)
      assert.same({}, progress.byZone)
    end)

    it("earns at most one pack per call and resets a corrupt total", function()
      local progress = { total = 1e9, byZone = { [1] = 1e9 } }
      assert.equals(1, Packs.addDistance(progress, 2, 1, CONFIG))
      assert.equals(0, progress.total)
      assert.same({}, progress.byZone)
    end)

    it("ignores zero, negative, NaN and infinite distances", function()
      local progress = newProgress()
      for _, bad in ipairs({ 0, -5, 0 / 0, math.huge, "10" }) do
        assert.is_nil(Packs.addDistance(progress, 1, bad, CONFIG))
      end
      assert.equals(0, progress.total)
      assert.same({}, progress.byZone)
    end)

    it("ignores a zone that is not a map ID", function()
      local progress = newProgress()
      for _, bad in ipairs({ "nil", "1436", 0 / 0, 0, -1, 1.5, 2 ^ 31, math.huge }) do
        assert.is_nil(Packs.addDistance(progress, bad ~= "nil" and bad or nil, 10, CONFIG))
      end
      assert.equals(0, progress.total)
      assert.same({}, progress.byZone)
    end)

    it("uses YARDS_PER_STEP for the threshold", function()
      local progress = newProgress()
      local config = { STEPS_PER_PACK = 100, YARDS_PER_STEP = 2 }
      assert.is_nil(Packs.addDistance(progress, 1, 150, config))
      assert.equals(1, Packs.addDistance(progress, 1, 50, config))
    end)
  end)

  describe("store", function()
    it("adds packs up to the limit and refuses the next", function()
      local packs = {}
      assert.is_true(Packs.store(packs, { zoneMapID = 1 }, 2))
      assert.is_true(Packs.store(packs, { zoneMapID = 2 }, 2))
      assert.is_false(Packs.store(packs, { zoneMapID = 3 }, 2))
      assert.equals(2, #packs)
    end)

    it("stores nothing with a limit of 0 or NaN", function()
      assert.is_false(Packs.store({}, { zoneMapID = 1 }, 0))
      assert.is_false(Packs.store({}, { zoneMapID = 1 }, 0 / 0))
    end)
  end)

  describe("toSteps", function()
    it("rounds down to whole steps", function()
      assert.equals(12, Packs.toSteps(12.9, { YARDS_PER_STEP = 1 }))
      assert.equals(6, Packs.toSteps(12.9, { YARDS_PER_STEP = 2 }))
    end)
  end)
end)
