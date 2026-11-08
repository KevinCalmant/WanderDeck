local mocks = require("wow_mocks")

describe("RevealTest", function()
  local ns, shown

  before_each(function()
    mocks.reset()
    ns = mocks.newNamespace()
    mocks.loadSource("Modules/Cards.lua", ns)
    mocks.loadAllData(ns)
    mocks.loadSource("Modules/Slash.lua", ns)
    shown = nil
    ns.RevealFrame = { show = function(...) shown = { ... } end }
    ns.print = function() end
    mocks.loadSource("Developer/RevealTest.lua", ns)
  end)

  local function rarities(ids)
    local out = {}
    for i, id in ipairs(ids) do out[i] = ns.Cards.get(id).rarity end
    return out
  end

  it("picks one card of each rarity for mix, five Epics for epic, five Legendaries for legendary", function()
    local pick = function(mode) return ns.RevealTest.pick(mode, ns.Cards.zoneIDs(), ns.Cards.zoneCards) end
    assert.same({ 1, 2, 3, 4, 5 }, rarities(pick("mix")))
    assert.same({ 4, 4, 4, 4, 4 }, rarities(pick("epic")))
    assert.same({ 5, 5, 5, 5, 5 }, rarities(pick("legendary")))
  end)

  it("uses different cards when the rarity has enough of them", function()
    local ids = ns.RevealTest.pick("legendary", ns.Cards.zoneIDs(), ns.Cards.zoneCards)
    local seen = {}
    for _, id in ipairs(ids) do
      assert.is_nil(seen[id], id)
      seen[id] = true
    end
  end)

  it("falls back to mix for an unknown or hostile mode and cycles a short rarity", function()
    local cards = { { id = "1:a", rarity = 5 } }
    assert.same({ "1:a", "1:a", "1:a", "1:a", "1:a" },
      ns.RevealTest.pick("legendary", { 1 }, function() return cards end))
    assert.same({ "1:a" }, ns.RevealTest.pick("<script>|cff", { 1 }, function() return cards end))
    assert.same({}, ns.RevealTest.pick(nil, {}, function() return {} end))
  end)

  it("opens the pack window without touching saved data, and never shows the typed mode", function()
    local db = { char = { collection = {}, newCards = {}, packs = {} } }
    ns.GetDB = function() return db end
    ns.Slash.dispatch("fx |cffff0000evil|r")
    assert.truthy(shown)
    local result, subtitle = shown[1], shown[2]
    assert.equals(5, #result.cardIDs)
    assert.same({}, result.firstTime)
    assert.equals("Test (mix)", subtitle)
    assert.same({ collection = {}, newCards = {}, packs = {} }, db.char)

    ns.Slash.dispatch("fx EPIC")
    assert.equals("Test (epic)", shown[2])
    assert.same({ 4, 4, 4, 4, 4 }, rarities(shown[1].cardIDs))
  end)

  it("falls back to mix for an empty mode or a valid mode with a payload glued to it", function()
    for _, rest in ipairs({
      "", "    ", "epic<script>alert(1)</script>", "<script>alert(1)</script>epic",
      "legendary|r", "epic |cffff0000x", string.rep("e", 300),
    }) do
      shown = nil
      ns.Slash.dispatch("fx "..rest)
      assert.equals("Test (mix)", shown[2], rest)
    end
  end)

  it("opens a new fake pack in the same mode from Open next", function()
    ns.Slash.dispatch("fx legendary")
    local openNext = shown[3]
    shown = nil
    openNext()
    assert.equals("Test (legendary)", shown[2])
  end)
end)
