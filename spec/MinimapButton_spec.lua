local mocks = require("wow_mocks")

describe("MinimapButton", function()
  local ns, MinimapButton

  before_each(function()
    mocks.reset()
    ns = mocks.newNamespace()
    for _, file in ipairs({
      "Utils/Wow.lua", "Modules/Config.lua", "Modules/Packs.lua", "Modules/Slash.lua", "Modules/UI/Draw.lua", "Modules/UI/MinimapButton.lua",
    }) do
      mocks.loadSource(file, ns)
    end
    MinimapButton = ns.MinimapButton
  end)

  local function close(a, b) return math.abs(a - b) < 1e-9 end

  it("turns an angle into an offset and back", function()
    for _, angle in ipairs({ 0, 45, 90, 180, 220, 359 }) do
      local x, y = MinimapButton.offsetFor(angle, 80)
      assert.is_true(close(MinimapButton.angleFor(x, y), angle) or close(MinimapButton.angleFor(x, y), angle % 360), tostring(angle))
    end
  end)

  it("returns angles from 0 to 360", function()
    local angle = MinimapButton.angleFor(0, -1)
    assert.is_true(close(angle, 270))
  end)

  it("builds tooltip lines from progress", function()
    local char = { progress = { total = 512.7 }, packs = { {}, {} } }
    local lines = MinimapButton.tooltipLines(char, { STEPS_PER_PACK = 2000, YARDS_PER_STEP = 1, MAX_UNOPENED_PACKS = 20 })
    assert.equals("Next pack: 512 / 2000", lines[1])
    assert.equals("Unopened packs: 2 / 20", lines[2])
  end)

  describe("drag", function()
    local settings
    local function env(center, cursor, scale)
      return {
        Minimap = {
          GetCenter = function() return center[1], center[2] end,
          GetEffectiveScale = function() return scale end,
        },
        GetCursorPosition = function() return cursor[1], cursor[2] end,
      }
    end

    before_each(function()
      settings = { minimapAngle = 220, minimapHidden = false }
      ns.GetDB = function() return { global = { settings = settings }, char = { packs = {} } } end
    end)

    it("saves the angle of the cursor around the minimap", function()
      MinimapButton.onDragUpdate(env({ 100, 100 }, { 100, 200 }, 1))
      assert.is_true(close(settings.minimapAngle, 90))
    end)

    it("ignores a frame with a missing center, zero scale or odd values", function()
      for _, e in ipairs({
        env({ nil, nil }, { 100, 200 }, 1),
        env({ 100, 100 }, { 100, 200 }, 0),
        env({ 100, 100 }, { 0 / 0, 200 }, 1),
        env({ 100, 100 }, { math.huge, math.huge }, 1),
        env({ 100, 100 }, { "100", 200 }, 1),
      }) do
        assert.has_no.errors(function() MinimapButton.onDragUpdate(e) end)
        assert.equals(220, settings.minimapAngle)
      end
    end)

    it("ignores secret cursor values", function()
      _G.issecretvalue = function(v) return v == 200 end
      MinimapButton.onDragUpdate(env({ 100, 100 }, { 100, 200 }, 1))
      assert.equals(220, settings.minimapAngle)
    end)
  end)

  it("toggles visibility with /wd minimap", function()
    local settings = { minimapHidden = false, minimapAngle = 220 }
    ns.GetDB = function() return { global = { settings = settings }, char = { packs = {} } } end
    ns.Slash.dispatch("minimap")
    assert.is_true(settings.minimapHidden)
  end)
end)
