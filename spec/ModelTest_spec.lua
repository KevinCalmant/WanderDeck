local mocks = require("wow_mocks")

describe("ModelTest", function()
  local ns

  before_each(function()
    mocks.reset()
    ns = mocks.newNamespace()
    mocks.loadSource("Utils/Wow.lua", ns)
    mocks.loadSource("Modules/Cards.lua", ns)
    mocks.loadAllData(ns)
    mocks.loadSource("Modules/Slash.lua", ns)
    ns.print = function() end
    mocks.loadSource("Developer/ModelTest.lua", ns)
  end)

  describe("parse", function()
    it("reads an npcID or a displayID", function()
      assert.same({ mode = "npc", id = 299 }, ns.ModelTest.parse("299"))
      assert.same({ mode = "npc", id = 299 }, ns.ModelTest.parse("  299 "))
      assert.same({ mode = "display", id = 1234 }, ns.ModelTest.parse("display 1234"))
    end)

    it("refuses anything that is not one plain ID", function()
      for _, bad in ipairs({
        "", " ", "0", "-5", "1.5", "abc", "299abc", "abc299", "299 300", "<script>alert(1)</script>",
        "299<script>", "display", "display -1", "display 12 34", "display x", "1234567890",
        "99999999999999999999", "299|cffff0000", "display 299\n300",
        "display 299<script>alert(1)</script>", "display <script>", "display 299|cffff0000",
        "<script>display 299", "xdisplay 299", "display299",
      }) do
        assert.is_nil(ns.ModelTest.parse(bad), bad)
      end
      assert.is_nil(ns.ModelTest.parse(nil))
    end)
  end)

  describe("chat lines", function()
    after_each(function() _G.issecretvalue = nil end)

    local function model(get) return { GetModelFileID = get } end

    it("reports a loaded model file", function()
      assert.equals("  at once: loaded, model file 123", ns.ModelTest.reportLine("at once", model(function() return 123 end)))
    end)

    it("reports no model on a missing, throwing, secret or invalid file ID", function()
      _G.issecretvalue = function(v) return v == 777 end
      for _, get in ipairs({
        function() return nil end, function() error("x") end, function() return 777 end,
        function() return 0 end, function() return -1 end, function() return "123" end,
      }) do
        assert.equals("  t: no model", ns.ModelTest.reportLine("t", model(get)))
      end
    end)

    it("escapes chat codes in a client error", function()
      assert.equals("  error: Evil||cffff0000Red||r||Hitem:1||h",
        ns.ModelTest.errorLine("Evil|cffff0000Red|r|Hitem:1|h"))
    end)
  end)

  it("finds the card holding an npcID", function()
    local card = ns.ModelTest.findCard(644, ns.Cards.zoneIDs(), ns.Cards.zoneCards)
    assert.equals("1436:npc_644", card.id)
    assert.is_nil(ns.ModelTest.findCard(999999, ns.Cards.zoneIDs(), ns.Cards.zoneCards))
  end)
end)
