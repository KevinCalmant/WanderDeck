local mocks = require("wow_mocks")

describe("Art", function()
  local ns

  before_each(function()
    mocks.reset()
    ns = mocks.newNamespace()
    mocks.loadSource("Modules/Cards.lua", ns)
    mocks.loadAllData(ns)
    mocks.loadSource("Developer/Art.lua", ns)
  end)

  it("prints the icon inline with the card ID", function()
    assert.equals("|TInterface\\Icons\\INV_Misc_Head_Gnoll_01:20:20|t 1429:hogger  (INV_Misc_Head_Gnoll_01)",
      ns.Art.line(ns.Cards.get("1429:hogger")))
  end)

  it("puts exactly one texture escape on every line", function()
    for _, zoneMapID in ipairs(ns.Cards.zoneIDs()) do
      for _, card in ipairs(ns.Cards.zoneCards(zoneMapID)) do
        local line = ns.Art.line(card)
        local _, opens = line:gsub("|T", "")
        local _, closes = line:gsub("|t", "")
        local _, pipes = line:gsub("|", "")
        assert.same({ 1, 1, 2 }, { opens, closes, pipes }, card.id)
      end
    end
  end)

  it("gives every shipped card its own icon", function()
    for _, zoneMapID in ipairs(ns.Cards.zoneIDs()) do
      for _, card in ipairs(ns.Cards.zoneCards(zoneMapID)) do
        assert.not_equals("INV_Misc_QuestionMark", card.icon, card.id)
      end
    end
  end)
end)
