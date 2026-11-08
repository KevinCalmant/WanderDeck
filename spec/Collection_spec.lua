local mocks = require("wow_mocks")

local CONFIG = { CARDS_PER_PACK = 3, RARITY_WEIGHTS = { 60, 25, 10, 4, 1 }, GUARANTEED_RARITY = 2, MAX_COPIES = 3 }

local function lowest(_) return 1 end

describe("Collection", function()
  local ns, Collection

  before_each(function()
    mocks.reset()
    ns = mocks.newNamespace()
    mocks.loadSource("Modules/Cards.lua", ns)
    mocks.loadSource("Modules/Collection.lua", ns)
    Collection = ns.Collection
    ns.Cards.registerZone({ zoneMapID = 10, continentMapID = 1, cards = {
      { id = "10:c", kind = "creature", rarity = 1, name = "C", flavor = "" },
      { id = "10:u", kind = "place", rarity = 2, name = "U", flavor = "" },
    } })
  end)

  describe("add", function()
    it("counts copies and flags first-time cards as new", function()
      local collection, newCards = {}, {}
      local first = Collection.add(collection, newCards, { "10:c", "10:c", "10:u" }, 99)
      assert.same({ ["10:c"] = 2, ["10:u"] = 1 }, collection)
      assert.same({ ["10:c"] = true, ["10:u"] = true }, newCards)
      assert.same({ ["10:c"] = true, ["10:u"] = true }, first)
    end)

    it("does not flag a card already owned", function()
      local collection, newCards = { ["10:c"] = 1 }, {}
      local first = Collection.add(collection, newCards, { "10:c" }, 99)
      assert.same({}, newCards)
      assert.same({}, first)
    end)

    it("caps copies at maxCopies", function()
      local collection = { ["10:c"] = 3 }
      Collection.add(collection, {}, { "10:c", "10:c" }, 3)
      assert.equals(3, collection["10:c"])
    end)
  end)

  describe("progress", function()
    it("counts distinct owned cards", function()
      local owned, total = Collection.progress({ ["10:c"] = 4 }, ns.Cards.zoneCards(10))
      assert.same({ 1, 2 }, { owned, total })
    end)
  end)

  describe("openNext", function()
    local function newChar(packs)
      return { packs = packs, collection = {}, newCards = {} }
    end
    local function noContinent() return nil end

    it("opens the oldest pack, stores its cards and removes it", function()
      local char = newChar({ { zoneMapID = 10, earnedAt = 1 }, { zoneMapID = 10, earnedAt = 2 } })
      local result = Collection.openNext(char, lowest, noContinent, CONFIG)
      assert.equals(1, result.pack.earnedAt)
      assert.same({ "10:c", "10:c", "10:u" }, result.cardIDs)
      assert.same({ ["10:c"] = 2, ["10:u"] = 1 }, char.collection)
      assert.same({ { zoneMapID = 10, earnedAt = 2 } }, char.packs)
      assert.equals("zone", result.poolLevel)
    end)

    it("reports no pack", function()
      local result, reason = Collection.openNext(newChar({}), lowest, noContinent, CONFIG)
      assert.is_nil(result)
      assert.equals("no-pack", reason)
    end)

    it("uses the continent fallback for a zone without data", function()
      local char = newChar({ { zoneMapID = 99, earnedAt = 1 } })
      local result = Collection.openNext(char, lowest, function() return 1 end, CONFIG)
      assert.equals("continent", result.poolLevel)
    end)

    it("uses every card when the continent is unknown to Data", function()
      local char = newChar({ { zoneMapID = 99, earnedAt = 1 } })
      local result = Collection.openNext(char, lowest, function() return 77 end, CONFIG)
      assert.equals("all", result.poolLevel)
    end)

    it("works with an rng that returns its maximum", function()
      local char = newChar({ { zoneMapID = 10, earnedAt = 1 } })
      local result = Collection.openNext(char, function(n) return n end, noContinent, CONFIG)
      assert.same({ "10:u", "10:u", "10:u" }, result.cardIDs)
    end)

    it("keeps the pack when no card exists at all", function()
      mocks.reset()
      ns = mocks.newNamespace()
      mocks.loadSource("Modules/Cards.lua", ns)
      mocks.loadSource("Modules/Collection.lua", ns)
      local char = newChar({ { zoneMapID = 99, earnedAt = 1 } })
      local result, reason = ns.Collection.openNext(char, lowest, noContinent, CONFIG)
      assert.is_nil(result)
      assert.equals("empty-pool", reason)
      assert.equals(1, #char.packs)
    end)
  end)
end)
