local mocks = require("wow_mocks")

local CONFIG = { MAX_FOOT_SPEED = 14, MAX_SAMPLE_GAP = 2 }

local function sample(overrides)
  local s = { time = 10, x = 0, y = 0, instanceID = 0, zoneMapID = 1436 }
  for k, v in pairs(overrides or {}) do s[k] = v end
  return s
end

describe("StepTracker.measure", function()
  local measure

  before_each(function()
    mocks.reset()
    local ns = mocks.newNamespace()
    mocks.loadSource("Modules/StepTracker.lua", ns)
    measure = ns.StepTracker.measure
  end)

  local function check(prev, cur, expectedYards, expectedReason)
    local yards, reason = measure(prev, cur, CONFIG)
    assert.equals(expectedYards, yards)
    assert.equals(expectedReason, reason)
  end

  it("measures a walked distance", function()
    check(sample(), sample({ time = 11, x = 3, y = 4 }), 5, nil)
  end)

  it("needs a previous sample", function()
    check(nil, sample(), nil, "first")
  end)

  it("reports the blocking reason of the current sample", function()
    for _, reason in ipairs({ "taxi", "mounted", "instance", "dead", "vehicle", "secret", "no-position", "no-zone", "missing-api" }) do
      check(sample(), sample({ time = 11, x = 1, blocked = reason }), nil, reason)
    end
  end)

  it("discards a continent or instance change", function()
    check(sample(), sample({ time = 11, x = 1, instanceID = 1 }), nil, "instance-changed")
  end)

  it("discards a zone change", function()
    check(sample(), sample({ time = 11, x = 1, zoneMapID = 1429 }), nil, "zone-changed")
  end)

  it("discards a sample with no elapsed time", function()
    check(sample(), sample({ x = 1 }), nil, "no-time")
    check(sample(), sample({ time = 9, x = 1 }), nil, "no-time")
    check(sample(), sample({ time = 0 / 0, x = 1 }), nil, "no-time")
  end)

  it("accepts a delta exactly at the speed cap", function()
    check(sample(), sample({ time = 11, x = 14 }), 14, nil)
  end)

  it("discards a delta above the speed cap (teleport, portal)", function()
    check(sample(), sample({ time = 11, x = 14.01 }), nil, "too-fast")
    check(sample(), sample({ time = 10.5, x = 2000, y = -500 }), nil, "too-fast")
  end)

  it("discards a NaN distance", function()
    check(sample(), sample({ time = 11, x = 0 / 0 }), nil, "no-position")
    check(sample({ x = math.huge }), sample({ time = 11, x = math.huge }), nil, "no-position")
  end)

  it("discards an infinite jump", function()
    check(sample(), sample({ time = 11, x = math.huge }), nil, "too-fast")
  end)

  it("discards a delta after a gap longer than MAX_SAMPLE_GAP (same-zone teleport behind a loading screen)", function()
    check(sample(), sample({ time = 30, x = 200 }), nil, "stale")
    check(sample(), sample({ time = 12.01, x = 1 }), nil, "stale")
  end)

  it("accepts a delta at exactly MAX_SAMPLE_GAP", function()
    check(sample(), sample({ time = 12, x = 20 }), 20, nil)
  end)

  it("returns zero yards when standing still", function()
    check(sample(), sample({ time = 11 }), 0, nil)
  end)

  it("refuses a missing current sample", function()
    check(sample(), nil, nil, "no-sample")
  end)
end)
