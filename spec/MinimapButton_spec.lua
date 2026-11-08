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

  it("puts the button on the edge of a minimap of any size", function()
    assert.equals(80, MinimapButton.radiusFor(140))
    assert.equals(109, MinimapButton.radiusFor(198))
  end)

  it("falls back to a fixed radius for a missing or odd width", function()
    for _, bad in ipairs({ "nil", 0, -5, 0 / 0, math.huge, "140" }) do
      assert.equals(80, MinimapButton.radiusFor(bad ~= "nil" and bad or nil), tostring(bad))
    end
  end)

  it("falls back for a secret width without comparing it", function()
    _G.issecretvalue = function(v) return v == 198 end
    assert.equals(80, MinimapButton.radiusFor(198))
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

  describe("built button", function()
    local function stub()
      local obj = { shown = false }
      return setmetatable(obj, { __index = function(_, key)
        if key == "Show" then return function(self) self.shown = true end end
        if key == "Hide" then return function(self) self.shown = false end end
        if key == "SetShown" then return function(self, v) self.shown = v and true or false end end
        if key == "SetText" then return function(self, v) self.text = v end end
        if key == "SetPoint" then return function(self, ...) self.point = { ... } end end
        if key == "GetFrameLevel" then return function() return 1 end end
        if key:match("^Create") then return function() return stub() end end
        return function() end
      end })
    end

    local packs

    before_each(function()
      _G.CreateFrame = function() return stub() end
      packs = {}
      ns.GetDB = function()
        return { global = { settings = { minimapAngle = 0, minimapHidden = false } }, char = { packs = packs } }
      end
    end)

    after_each(function()
      _G.CreateFrame, _G.Minimap = nil, nil
    end)

    local function withWidth(getWidth)
      _G.Minimap = { GetWidth = getWidth }
      MinimapButton.init()
      return MinimapButton._debug()
    end

    it("places the button on the edge of the minimap", function()
      local button = withWidth(function() return 198 end)
      assert.same({ "CENTER", _G.Minimap, "CENTER", 109, 0 }, button.point)
    end)

    it("falls back to radius 80 when the width throws, is NaN or is secret", function()
      _G.issecretvalue = function(v) return v == 198 end
      for _, getWidth in ipairs({
        function() error("no anchor") end,
        function() return 0 / 0 end,
        function() return 198 end, -- secret
      }) do
        local previous = MinimapButton._debug()
        if previous then previous.point = nil end -- each case must set its own offset
        local button = withWidth(getWidth)
        assert.same({ "CENTER", _G.Minimap, "CENTER", 80, 0 }, button.point)
      end
    end)

    it("shows the pack count only when there are packs", function()
      local button = withWidth(function() return 140 end)
      assert.is_false(button.badge.shown)
      assert.is_false(button.badgeBg.shown)
      packs[1] = {}
      MinimapButton.refresh()
      assert.equals(1, button.badge.text)
      assert.is_true(button.badge.shown)
      for i = 2, 20 do packs[i] = {} end
      MinimapButton.refresh()
      assert.equals(20, button.badge.text)
      assert.is_true(button.badge.shown)
      for i = 1, 20 do packs[i] = nil end
      MinimapButton.refresh()
      assert.is_false(button.badge.shown) -- hidden again, not just never shown
      assert.is_false(button.badgeBg.shown)
    end)
  end)

  it("toggles visibility with /wd minimap", function()
    local settings = { minimapHidden = false, minimapAngle = 220 }
    ns.GetDB = function() return { global = { settings = settings }, char = { packs = {} } } end
    ns.Slash.dispatch("minimap")
    assert.is_true(settings.minimapHidden)
  end)
end)
