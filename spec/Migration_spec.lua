local mocks = require("wow_mocks")

local MAX_COPIES = 999

local function deepCopy(value)
  if type(value) ~= "table" then return value end
  local copy = {}
  for k, v in pairs(value) do copy[deepCopy(k)] = deepCopy(v) end
  return copy
end

describe("Migration", function()
  local ns, Migration, Schema, Tags

  before_each(function()
    mocks.reset()
    ns = mocks.newNamespace()
    for _, file in ipairs({ "Modules/Schema.lua", "Modules/Cards.lua", "Modules/Tags.lua", "Modules/Migration.lua" }) do
      mocks.loadSource(file, ns)
    end
    Migration, Schema, Tags = ns.Migration, ns.Schema, ns.Tags
  end)

  -- A version 1 save as AceDB writes it: `schemaVersion = 1` equaled the old
  -- default, so it was stripped on logout.
  local function v1Save()
    return {
      global = { settings = { sound = false } },
      char = {
        ["Alice - Realm"] = {
          stats = { yards = 120 }, progress = { total = 20, byZone = { [1429] = 20 } },
          packs = { { zoneMapID = 1429, earnedAt = 5 } },
          collection = { ["1429:hogger"] = 2, ["1429:wolf"] = 1 },
          newCards = { ["1429:wolf"] = true },
          tags = { ["1429:hogger"] = { deck = true, [Tags.TRADE] = true } },
          pinned = { ["1429:hogger"] = true },
        },
        ["Bob - Realm"] = {
          stats = { yards = 7 }, progress = { total = 7, byZone = { [1436] = 7 } }, packs = {},
          collection = { ["1429:hogger"] = 3, ["1436:moonbrook"] = 1 },
          newCards = { ["1436:moonbrook"] = true },
          tags = { ["1436:moonbrook"] = { quest = true } },
          pinned = { ["1436:moonbrook"] = true },
        },
      },
    }
  end

  describe("run", function()
    it("does nothing without a save", function()
      assert.equals("fresh", Migration.run(nil, MAX_COPIES))
    end)

    it("merges every character's collection into the account", function()
      local sv = v1Save()
      assert.equals("migrated", Migration.run(sv, MAX_COPIES))
      assert.equals(2, sv.global.schemaVersion)
      assert.same({ ["1429:hogger"] = 5, ["1429:wolf"] = 1, ["1436:moonbrook"] = 1 }, sv.global.collection)
      assert.same({ ["1429:wolf"] = true, ["1436:moonbrook"] = true }, sv.global.newCards)
      assert.same({ ["1429:hogger"] = true, ["1436:moonbrook"] = true }, sv.global.pinned)
      assert.same({
        ["1429:hogger"] = { deck = true, [Tags.TRADE] = true },
        ["1436:moonbrook"] = { quest = true },
      }, sv.global.tags)
      assert.same({ sound = false }, sv.global.settings)
    end)

    it("keeps packs, steps and progress per character and removes their collection", function()
      local sv = v1Save()
      Migration.run(sv, MAX_COPIES)
      assert.same({
        stats = { yards = 120 }, progress = { total = 20, byZone = { [1429] = 20 } },
        packs = { { zoneMapID = 1429, earnedAt = 5 } },
      }, sv.char["Alice - Realm"])
      assert.same({ stats = { yards = 7 }, progress = { total = 7, byZone = { [1436] = 7 } }, packs = {} },
        sv.char["Bob - Realm"])
    end)

    it("creates the account section when AceDB stripped it", function()
      local sv = { char = { ["Alice - Realm"] = { collection = { ["1429:wolf"] = 4 } } } }
      assert.equals("migrated", Migration.run(sv, MAX_COPIES))
      assert.same({ ["1429:wolf"] = 4 }, sv.global.collection)
      assert.equals(2, sv.global.schemaVersion)
    end)

    it("migrates a save with no character", function()
      local sv = { global = {} }
      assert.equals("migrated", Migration.run(sv, MAX_COPIES))
      assert.same({ schemaVersion = 2, collection = {}, newCards = {}, tags = {}, pinned = {} }, sv.global)
    end)

    it("leaves a current save untouched", function()
      local sv = v1Save()
      Migration.run(sv, MAX_COPIES)
      local before = deepCopy(sv)
      assert.equals("current", Migration.run(sv, MAX_COPIES))
      assert.same(before, sv)
    end)

    it("merges again cards a character got while an older addon version was loaded", function()
      local sv = { global = { schemaVersion = 2, collection = { a = 1 }, newCards = {}, tags = {}, pinned = {} },
        char = { ["Alice - Realm"] = { packs = {}, collection = { a = 2, b = 1 }, newCards = { b = true } } } }
      sv.char["Alice - Realm"].tags = { b = { deck = true } }
      sv.char["Alice - Realm"].pinned = { b = true }
      assert.equals("migrated", Migration.run(sv, MAX_COPIES))
      assert.same({ a = 3, b = 1 }, sv.global.collection)
      assert.same({ b = true }, sv.global.newCards)
      assert.same({ b = { deck = true } }, sv.global.tags)
      assert.same({ b = true }, sv.global.pinned)
      assert.same({ packs = {} }, sv.char["Alice - Realm"])
      -- The next load does not count those copies twice.
      assert.equals("current", Migration.run(sv, MAX_COPIES))
      assert.same({ a = 3, b = 1 }, sv.global.collection)
    end)

    it("merges a wrong-typed leftover key once, then stays current", function()
      local sv = { global = { schemaVersion = 2, collection = { a = 1 } },
        char = { ["Alice - Realm"] = { collection = false } } }
      assert.equals("migrated", Migration.run(sv, MAX_COPIES))
      assert.same({}, sv.char["Alice - Realm"])
      assert.equals("current", Migration.run(sv, MAX_COPIES))
      assert.same({ a = 1 }, sv.global.collection)
    end)

    it("does not re-merge on every load for a character under a non-string key", function()
      local sv = { global = { schemaVersion = 2, collection = { a = 1 } },
        char = { [1] = { collection = { a = 5 } } } }
      local before = deepCopy(sv)
      assert.equals("current", Migration.run(sv, MAX_COPIES))
      assert.same(before, sv)
    end)

    it("migrates a save with an explicit version 1", function()
      local sv = v1Save()
      sv.global.schemaVersion = 1
      assert.equals("migrated", Migration.run(sv, MAX_COPIES))
      assert.equals(5, sv.global.collection["1429:hogger"])
    end)

    it("leaves a save from a newer addon version untouched", function()
      local sv = v1Save()
      sv.global.schemaVersion = 3
      local before = deepCopy(sv)
      assert.equals("newer", Migration.run(sv, MAX_COPIES))
      assert.same(before, sv)
    end)

    it("treats an invalid version as version 1", function()
      for _, bad in ipairs({ 0 / 0, math.huge, -math.huge, -1, 0, 1.5, "2", true, {} }) do
        local sv = v1Save()
        sv.global.schemaVersion = bad
        assert.equals("migrated", Migration.run(sv, MAX_COPIES), tostring(bad))
        assert.equals(5, sv.global.collection["1429:hogger"], tostring(bad))
        assert.equals(2, sv.global.schemaVersion)
      end
    end)

    it("gives the same result when it runs again on migrated data", function()
      local sv = v1Save()
      Migration.run(sv, MAX_COPIES)
      local once = deepCopy(sv)
      sv.global.schemaVersion = nil -- version lost: the save is migrated again
      Migration.run(sv, MAX_COPIES)
      assert.same(once, sv)
    end)

    it("changes nothing when the merge throws", function()
      local sv = v1Save()
      local before = deepCopy(sv)
      Tags.normalize = function() error("boom") end
      assert.has_error(function() Migration.run(sv, MAX_COPIES) end)
      assert.same(before, sv)
    end)

    it("skips characters under a non-string key and leaves them as they were", function()
      local odd = { collection = { ["1429:wolf"] = 1 } }
      local sv = { char = { [1] = odd, ["Alice - Realm"] = { collection = { ["1429:hogger"] = 1 } } } }
      Migration.run(sv, MAX_COPIES)
      assert.same({ ["1429:hogger"] = 1 }, sv.global.collection)
      assert.same({ collection = { ["1429:wolf"] = 1 } }, odd)
    end)

    it("ignores character sections of the wrong type", function()
      local sv = { char = { ["Alice - Realm"] = {
        collection = 5, newCards = "x", tags = true, pinned = 1,
      }, ["Bob - Realm"] = { collection = { ["1429:wolf"] = 2 } } } }
      Migration.run(sv, MAX_COPIES)
      assert.same({ ["1429:wolf"] = 2 }, sv.global.collection)
      assert.same({}, sv.global.newCards)
      assert.same({}, sv.global.tags)
      assert.same({}, sv.global.pinned)
      assert.same({}, sv.char["Alice - Realm"])
    end)
  end)

  describe("mergeCollection", function()
    it("sums copies and caps them at MAX_COPIES", function()
      local into = {}
      Migration.mergeCollection(into, { a = 600, b = 1 }, MAX_COPIES)
      Migration.mergeCollection(into, { a = 600, b = 2 }, MAX_COPIES)
      assert.same({ a = MAX_COPIES, b = 3 }, into)
    end)

    it("caps a huge count instead of overflowing", function()
      local into = {}
      Migration.mergeCollection(into, { a = 1e308, b = 2 ^ 53 }, MAX_COPIES)
      Migration.mergeCollection(into, { a = 1e308 }, MAX_COPIES)
      assert.same({ a = MAX_COPIES, b = MAX_COPIES }, into)
    end)

    it("drops counts that are not whole positive numbers", function()
      local into = {}
      Migration.mergeCollection(into, {
        nan = 0 / 0, inf = math.huge, ninf = -math.huge, neg = -1, zero = 0, half = 1.5,
        str = "5", bool = true, tbl = {}, ok = 1,
      }, MAX_COPIES)
      assert.same({ ok = 1 }, into)
    end)

    it("drops card IDs that are not short non-empty strings", function()
      local into = {}
      Migration.mergeCollection(into, {
        [1] = 1, [true] = 1, [""] = 1, [string.rep("x", 65)] = 1, [string.rep("x", 64)] = 1,
      }, MAX_COPIES)
      assert.same({ [string.rep("x", 64)] = 1 }, into)
    end)

    it("ignores a source that is not a table", function()
      local into = { a = 1 }
      for _, bad in ipairs({ 5, "x", true }) do Migration.mergeCollection(into, bad, MAX_COPIES) end
      Migration.mergeCollection(into, nil, MAX_COPIES)
      assert.same({ a = 1 }, into)
    end)
  end)

  describe("mergeFlags", function()
    it("keeps only true flags on valid card IDs", function()
      local into = {}
      Migration.mergeFlags(into, {
        a = true, b = false, c = 1, d = "true", [""] = true, [5] = true, [string.rep("x", 65)] = true,
      })
      Migration.mergeFlags(into, { e = true })
      assert.same({ a = true, e = true }, into)
    end)
  end)

  describe("mergeTags", function()
    it("refuses tags a player could not type", function()
      local into = {}
      Migration.mergeTags(into, { card = {
        ["a|b"] = true, ["#x"] = true, ["<script>alert(1)</script>"] = true, ["tab\there"] = true,
        ["new\nline"] = true, [string.rep("t", 25)] = true, ["UPPER"] = true, [" pad"] = true,
        [""] = true, nottrue = 1, [5] = true, ok = true,
      } })
      -- "<script>alert(1)</script>" is 25 bytes: refused by length, never rendered.
      assert.same({ card = { ok = true } }, into)
    end)

    it("keeps the For trade tag", function()
      local into = {}
      Migration.mergeTags(into, { card = { [Tags.TRADE] = true } })
      assert.same({ card = { [Tags.TRADE] = true } }, into)
    end)

    it("keeps a short markup-like tag verbatim: a FontString renders no HTML", function()
      local into = {}
      Migration.mergeTags(into, { card = { ["<b>x</b>"] = true, ["ok<script>"] = true } })
      assert.same({ card = { ["<b>x</b>"] = true, ["ok<script>"] = true } }, into)
      assert.equals("ok<script>", Tags.display("ok<script>"))
    end)

    it("leaves the tag limits to Tags.sanitize", function()
      local into = {}
      Migration.mergeTags(into, { card = { a = true, b = true, c = true } })
      Migration.mergeTags(into, { card = { d = true, e = true, f = true } })
      assert.equals(6, #Tags.of(into, "card"))
    end)

    it("skips card tags of the wrong type and invalid card IDs", function()
      local into = {}
      Migration.mergeTags(into, {
        a = 5, b = "x", c = { ok = true },
        [1] = { ok = true }, [true] = { ok = true }, [""] = { ok = true }, [string.rep("x", 65)] = { ok = true },
      })
      assert.same({ c = { ok = true } }, into)
    end)
  end)

  describe("with the sanitizers", function()
    local function known(id) return id == "1429:hogger" or id == "1429:wolf" end

    local function load(sv, dataLoaded)
      Migration.run(sv, MAX_COPIES)
      Schema.sanitizeCollection(sv.global, known, MAX_COPIES, dataLoaded)
      Tags.sanitize(sv.global, known, dataLoaded)
      return sv.global
    end

    local function hostileSave()
      return { char = {
        ["Alice - Realm"] = {
          collection = { ["1429:hogger"] = 1, ["1429:<script>alert(1)</script>"] = 3, ["1429:hogger|cffff0000"] = 2 },
          newCards = { ["1429:<script>alert(1)</script>"] = true },
          tags = { ["1429:<script>alert(1)</script>"] = { x = true } },
          pinned = { ["1429:hogger|cffff0000"] = true },
        },
        ["Bob - Realm"] = { collection = { ["1429:wolf"] = 0 / 0, ["1429:hogger"] = 1e308 } },
      } }
    end

    it("drops unknown and hostile card IDs once every Data file loaded", function()
      local global = load(hostileSave(), true)
      assert.same({ ["1429:hogger"] = MAX_COPIES }, global.collection)
      assert.same({}, global.newCards)
      assert.same({}, global.tags)
      assert.same({}, global.pinned)
    end)

    it("keeps unknown card IDs when a Data file failed, so no card is lost", function()
      local global = load(hostileSave(), false)
      assert.same({
        ["1429:hogger"] = MAX_COPIES, ["1429:<script>alert(1)</script>"] = 3, ["1429:hogger|cffff0000"] = 2,
      }, global.collection)
      assert.same({ ["1429:<script>alert(1)</script>"] = true }, global.newCards)
      assert.same({ ["1429:<script>alert(1)</script>"] = { x = true } }, global.tags)
      assert.same({ ["1429:hogger|cffff0000"] = true }, global.pinned)
    end)

    it("keeps a known card's tag when removed cards hold MAX_DISTINCT tags", function()
      local removed = {}
      for i = 1, Tags.MAX_DISTINCT do removed["1429:<gone" .. i] = { ["t" .. i] = true } end
      local sv = { char = {
        ["Alice - Realm"] = { collection = { ["1429:<gone1"] = 1 }, tags = removed },
        ["Bob - Realm"] = { collection = { ["1429:hogger"] = 1 }, tags = { ["1429:hogger"] = { deck = true } } },
      } }
      local global = load(sv, true)
      assert.same({ ["1429:hogger"] = { deck = true } }, global.tags)
    end)

    it("applies the tag limits after the merge", function()
      local sv = { char = {
        ["Alice - Realm"] = { collection = { ["1429:hogger"] = 1 }, tags = { ["1429:hogger"] = { a = true, b = true, c = true } } },
        ["Bob - Realm"] = { tags = { ["1429:hogger"] = { d = true, e = true, f = true } } },
      } }
      local global = load(sv, true)
      assert.equals(Tags.MAX_PER_CARD, #Tags.of(global.tags, "1429:hogger"))
    end)

    it("drops a whitespace card ID once Data loaded", function()
      local global = load({ char = { ["Alice - Realm"] = { collection = { [" "] = 1, ["1429:wolf"] = 1 } } } }, true)
      assert.same({ ["1429:wolf"] = 1 }, global.collection)
    end)
  end)
end)
