local mocks = require("wow_mocks")

local function card(id, rarity, name)
  return { id = id, rarity = rarity, name = name or id }
end

local CARDS = {
  card("10:a", 1, "Young Wolf"),
  card("10:b", 2, "Goldshire"),
  card("10:c", 3, "Mother Fang"),
  card("10:d", 5, "Hogger"),
}

describe("BinderModel", function()
  local ns, BinderModel

  before_each(function()
    mocks.reset()
    ns = mocks.newNamespace()
    mocks.loadSource("Modules/Cards.lua", ns)
    mocks.loadSource("Modules/Collection.lua", ns)
    mocks.loadSource("Modules/Tags.lua", ns)
    mocks.loadSource("Modules/BinderModel.lua", ns)
    BinderModel = ns.BinderModel
  end)

  local function ids(entries)
    local out = {}
    for i, e in ipairs(entries) do out[i] = e.card.id end
    return out
  end

  describe("normalizeSearch", function()
    it("trims and lowercases", function()
      assert.equals("hog", BinderModel.normalizeSearch("  HoG  "))
    end)

    it("caps the length", function()
      assert.equals(BinderModel.SEARCH_MAX_LENGTH, #BinderModel.normalizeSearch(string.rep("a", 500)))
    end)

    it("turns non-strings into an empty search", function()
      assert.equals("", BinderModel.normalizeSearch(nil))
      assert.equals("", BinderModel.normalizeSearch(5))
    end)
  end)

  describe("entries", function()
    local collection = { ["10:a"] = 1, ["10:c"] = 3 }

    it("lists every card rarest first by default", function()
      assert.same({ "10:d", "10:c", "10:b", "10:a" }, ids(BinderModel.entries(CARDS, collection, {})))
    end)

    it("keeps data order within a rarity, even for many cards", function()
      local many = {}
      for i = 1, 40 do many[i] = card("10:x"..i, i % 2 + 1) end
      local out = ids(BinderModel.entries(many, {}, {}))
      local expected = {}
      for i = 1, 40 do if i % 2 == 1 then expected[#expected + 1] = "10:x"..i end end
      for i = 1, 40 do if i % 2 == 0 then expected[#expected + 1] = "10:x"..i end end
      assert.same(expected, out)
    end)

    it("filters owned, missing and duplicates", function()
      assert.same({ "10:c", "10:a" }, ids(BinderModel.entries(CARDS, collection, {}, { filter = "owned" })))
      assert.same({ "10:d", "10:b" }, ids(BinderModel.entries(CARDS, collection, {}, { filter = "missing" })))
      assert.same({ "10:c" }, ids(BinderModel.entries(CARDS, collection, {}, { filter = "duplicates" })))
    end)

    it("treats an unknown filter as all", function()
      assert.equals(4, #BinderModel.entries(CARDS, collection, {}, { filter = "<script>" }))
    end)

    it("filters by rarity", function()
      assert.same({ "10:c" }, ids(BinderModel.entries(CARDS, collection, {}, { rarity = 3 })))
    end)

    it("searches owned card names as plain text, case-insensitive", function()
      assert.same({ "10:a" }, ids(BinderModel.entries(CARDS, collection, {}, { search = "WOLF" })))
    end)

    it("does not reveal missing cards through search", function()
      assert.same({}, ids(BinderModel.entries(CARDS, collection, {}, { search = "hogger" })))
    end)

    it("treats pattern characters as plain text", function()
      for _, pattern in ipairs({ "%a", ".", "[", "(", "%", "^Young", "f$" }) do
        assert.has_no.errors(function() BinderModel.entries(CARDS, collection, {}, { search = pattern }) end)
      end
      assert.same({}, ids(BinderModel.entries(CARDS, collection, {}, { search = "." })))
    end)

    it("returns nothing for payloads glued to a valid owned name", function()
      for _, payload in ipairs({
        "wolf<script>alert(1)</script>", "<script>", "young|cffff0000wolf|r", "|Hitem:1|h[x]|h",
        "wolf%", "wolf[", "%",
      }) do
        assert.same({}, ids(BinderModel.entries(CARDS, collection, {}, { search = payload })), payload)
      end
    end)

    it("treats a whitespace-only search as empty, missing cards stay silhouettes", function()
      for _, blank in ipairs({ "   ", "\t\n" }) do
        local entries = BinderModel.entries(CARDS, collection, {}, { search = blank })
        assert.equals(4, #entries)
      end
    end)

    it("handles an over-long multi-byte search without revealing missing cards", function()
      local search = string.rep("é", 40)
      assert.has_no.errors(function() BinderModel.entries(CARDS, collection, {}, { search = search }) end)
      assert.is_true(#BinderModel.normalizeSearch(search) <= BinderModel.SEARCH_MAX_LENGTH)
      assert.same({}, ids(BinderModel.entries(CARDS, collection, {}, { search = search })))
    end)

    it("does not find a missing card by its localized name, even with the missing filter", function()
      local localize = function(key) return key == "Hogger" and "Lardeur" or key end
      assert.same({}, ids(BinderModel.entries(CARDS, collection, {}, { search = "lardeur", filter = "missing", localize = localize })))
    end)

    it("searches the localized name", function()
      local localize = function(key) return key == "Mother Fang" and "Mère Croc" or key end
      assert.same({ "10:c" }, ids(BinderModel.entries(CARDS, collection, {}, { search = "croc", localize = localize })))
    end)

    it("puts pinned owned cards first, rarest first within each group", function()
      local pinned = { ["10:a"] = true, ["10:b"] = true } -- 10:b is missing: ignored
      local entries = BinderModel.entries(CARDS, collection, {}, { pinned = pinned })
      assert.same({ "10:a", "10:d", "10:c", "10:b" }, ids(entries))
      assert.is_true(entries[1].pinned)
      assert.is_false(entries[2].pinned)
    end)

    it("filters by tag, owned cards only", function()
      local tags = { ["10:a"] = { feu = true }, ["10:b"] = { feu = true }, ["10:c"] = { [ns.Tags.TRADE] = true } }
      assert.same({ "10:a" }, ids(BinderModel.entries(CARDS, collection, {}, { tags = tags, tag = "feu" })))
      assert.same({ "10:c" }, ids(BinderModel.entries(CARDS, collection, {}, { tags = tags, tag = ns.Tags.TRADE })))
      assert.same({}, ids(BinderModel.entries(CARDS, collection, {}, { tags = tags, tag = "nope" })))
    end)

    it("carries copies and the New flag", function()
      local entries = BinderModel.entries(CARDS, collection, { ["10:c"] = true }, { filter = "owned" })
      assert.same({ 3, 1 }, { entries[1].copies, entries[2].copies })
      assert.same({ true, false }, { entries[1].isNew, entries[2].isNew })
    end)
  end)

  describe("page", function()
    local entries = {}
    for i = 1, 10 do entries[i] = i end

    it("slices pages", function()
      local slice, page, count = BinderModel.page(entries, 2, 9)
      assert.same({ 10 }, slice)
      assert.same({ 2, 2 }, { page, count })
    end)

    it("clamps the page and handles bad input", function()
      for _, bad in ipairs({ 0, -5, 99, 0 / 0, "2", nil, 1.7 }) do
        local _, page = BinderModel.page(entries, bad, 9)
        assert.is_true(page == 1 or page == 2, tostring(bad))
      end
      assert.equals(2, select(2, BinderModel.page(entries, 99, 9)))
    end)

    it("has one empty page for no entries", function()
      local slice, page, count = BinderModel.page({}, 1, 9)
      assert.same({}, slice)
      assert.same({ 1, 1 }, { page, count })
    end)
  end)

  describe("tag cycle", function()
    it("goes none, For trade, player tags, then back to none", function()
      local tags = { ["10:a"] = { zeta = true, alpha = true } }
      local seq, current = {}, nil
      for _ = 1, 5 do
        current = BinderModel.nextTag(tags, current)
        seq[#seq + 1] = tostring(current)
      end
      assert.same({ ns.Tags.TRADE, "alpha", "zeta", "nil", ns.Tags.TRADE }, seq)
    end)

    it("restarts on an unknown tag", function()
      assert.is_nil(BinderModel.nextTag({}, "gone"))
    end)
  end)

  describe("markSeen", function()
    it("clears New only for owned cards shown", function()
      local newCards = { ["10:a"] = true, ["10:c"] = true }
      BinderModel.markSeen(newCards, {
        { card = CARDS[1], copies = 1, isNew = true },
        { card = CARDS[2], copies = 0, isNew = false },
      })
      assert.same({ ["10:c"] = true }, newCards)
    end)

    it("keeps the flag of a New entry with no copies", function()
      local newCards = { ["10:b"] = true }
      BinderModel.markSeen(newCards, { { card = CARDS[2], copies = 0, isNew = true } })
      assert.same({ ["10:b"] = true }, newCards)
    end)
  end)

  describe("zoneList", function()
    it("reports completion per zone", function()
      ns.Cards.registerZone({ zoneMapID = 10, continentMapID = 1, cards = {
        { id = "10:a", kind = "creature", rarity = 1, name = "A", flavor = "" },
        { id = "10:b", kind = "creature", rarity = 1, name = "B", flavor = "" },
      } })
      local list = BinderModel.zoneList(ns.Cards.zoneIDs(), ns.Cards.zoneCards, { ["10:a"] = 2 })
      assert.same({ { zoneMapID = 10, continentMapID = 0, name = "10", owned = 1, total = 2 } }, list)
    end)

    it("sorts by continent, then by name, then by ID", function()
      local continents = { [1] = 1415, [2] = 1414, [3] = 1415, [4] = 1415 }
      local names = { [1] = "Westfall", [2] = "Durotar", [3] = "Elwynn", [4] = "Elwynn" }
      local list = BinderModel.zoneList({ 1, 2, 3, 4 }, function() return {} end, {}, {
        continentOf = function(id) return continents[id] end,
        nameOf = function(id) return names[id] end,
      })
      local order = {}
      for i, z in ipairs(list) do order[i] = z.zoneMapID end
      assert.same({ 2, 3, 4, 1 }, order)
    end)

    it("ignores a continent or name of the wrong type", function()
      local list = BinderModel.zoneList({ 7 }, function() return {} end, {}, {
        continentOf = function() return "1415" end, nameOf = function() return { "x" } end,
      })
      assert.equals(0, list[1].continentMapID)
      assert.equals("7", list[1].name)
    end)
  end)

  describe("zonePages", function()
    local function zones(spec)
      local list = {}
      for _, z in ipairs(spec) do list[#list + 1] = { zoneMapID = z[1], continentMapID = z[2] } end
      return list
    end

    it("never mixes two continents on one page and caps each page", function()
      local pages = BinderModel.zonePages(zones({ { 1, 1414 }, { 2, 1414 }, { 3, 1414 }, { 4, 1415 } }), 2)
      assert.equals(3, #pages)
      assert.same({ 1414, 1414, 1415 }, { pages[1].continentMapID, pages[2].continentMapID, pages[3].continentMapID })
      assert.same({ 2, 1, 1 }, { #pages[1].zones, #pages[2].zones, #pages[3].zones })
    end)

    it("treats a bad page size as 1 and an empty list as no page", function()
      assert.equals(2, #BinderModel.zonePages(zones({ { 1, 1 }, { 2, 1 } }), 0))
      assert.equals(2, #BinderModel.zonePages(zones({ { 1, 1 }, { 2, 1 } }), "x"))
      assert.same({}, BinderModel.zonePages({}, 10))
    end)

    it("finds the page of a zone, or page 1", function()
      local pages = BinderModel.zonePages(zones({ { 1, 1414 }, { 2, 1415 } }), 10)
      assert.equals(2, BinderModel.pageOfZone(pages, 2))
      assert.equals(1, BinderModel.pageOfZone(pages, 99))
      assert.equals(1, BinderModel.pageOfZone(pages, nil))
    end)
  end)
end)
