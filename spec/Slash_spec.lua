local mocks = require("wow_mocks")

describe("Slash", function()
  local Slash, printed, globalPrinted, originalPrint

  before_each(function()
    mocks.reset()
    local ns
    ns, printed = mocks.newNamespace()
    globalPrinted = {}
    originalPrint = _G.print
    _G.print = function(msg) globalPrinted[#globalPrinted + 1] = tostring(msg) end
    mocks.loadSource("Modules/Slash.lua", ns)
    Slash = ns.Slash
  end)

  after_each(function()
    _G.print = originalPrint
  end)

  local function allOutput()
    local out = {}
    for _, l in ipairs(printed) do out[#out + 1] = l end
    for _, l in ipairs(globalPrinted) do out[#out + 1] = l end
    return table.concat(out, "\n")
  end

  describe("parse", function()
    it("splits the command word from the trimmed rest", function()
      assert.same({ "probe", "taxi run" }, { Slash.parse("  probe   taxi run  ") })
    end)

    it("lowercases the command word only", function()
      assert.same({ "probe", "Taxi" }, { Slash.parse("PROBE Taxi") })
    end)

    it("returns empty strings for empty or non-string input", function()
      assert.same({ "", "" }, { Slash.parse("") })
      assert.same({ "", "" }, { Slash.parse("   ") })
      assert.same({ "", "" }, { Slash.parse(nil) })
      assert.same({ "", "" }, { Slash.parse(42) })
    end)
  end)

  describe("dispatch", function()
    it("runs the matching handler with the rest", function()
      local received
      Slash.register({ name = "probe", usage = "probe", help = "", handler = function(rest) received = rest end })
      assert.is_true(Slash.dispatch("probe taxi"))
      assert.equals("taxi", received)
    end)

    it("prints the help for an empty command", function()
      assert.is_false(Slash.dispatch(""))
      assert.matches("Commands:", allOutput(), 1, true)
    end)

    it("prints the help for an unknown command without echoing the input", function()
      assert.is_false(Slash.dispatch("<script>alert(1)</script> |TInterface\\Icons\\x:64|t"))
      local output = allOutput()
      assert.matches("Commands:", output, 1, true)
      assert.is_nil(output:find("<script>", 1, true))
      assert.is_nil(output:find("|T", 1, true))
    end)

    it("rejects a known command with a suffix glued on", function()
      local called = false
      Slash.register({ name = "probe", usage = "probe", help = "", handler = function() called = true end })
      assert.is_false(Slash.dispatch("probe<script>"))
      assert.is_false(called)
    end)

    it("does not resolve names through table internals", function()
      assert.is_false(Slash.dispatch("__index"))
    end)

    it("handles very long input", function()
      assert.is_false(Slash.dispatch(string.rep("a", 10000)))
    end)
  end)

  describe("register", function()
    local function noop() end

    it("rejects names that are not lowercase words", function()
      assert.has_error(function() Slash.register({ name = "Probe", handler = noop }) end)
      assert.has_error(function() Slash.register({ name = "pro be", handler = noop }) end)
      assert.has_error(function() Slash.register({ name = "", handler = noop }) end)
      assert.has_error(function() Slash.register({ name = "x;y", handler = noop }) end)
    end)

    it("rejects a missing handler", function()
      assert.has_error(function() Slash.register({ name = "probe" }) end)
    end)

    it("rejects a duplicate name", function()
      Slash.register({ name = "probe", handler = noop })
      assert.has_error(function() Slash.register({ name = "probe", handler = noop }) end)
    end)
  end)
end)
