local mocks = require("wow_mocks")

describe("Schema.sanitizeRoot", function()
  local Schema

  before_each(function()
    mocks.reset()
    local ns = mocks.newNamespace()
    mocks.loadSource("Modules/Schema.lua", ns)
    Schema = ns.Schema
  end)

  it("drops a root that is not a table", function()
    for _, bad in ipairs({ 5, "x", true }) do
      assert.is_nil(Schema.sanitizeRoot(bad))
    end
    assert.is_nil(Schema.sanitizeRoot(nil))
  end)

  it("drops sections of the wrong type", function()
    local sv = Schema.sanitizeRoot({ global = 5, char = "x", profileKeys = 5, profiles = true, namespaces = 1 })
    assert.same({}, sv)
  end)

  it("drops keyed entries of the wrong type and keeps valid ones", function()
    local sv = Schema.sanitizeRoot({
      char = { ["Bad - Realm"] = 5, ["Good - Realm"] = { steps = 1 } },
      profileKeys = { ["Bad - Realm"] = {}, ["Good - Realm"] = "Default" },
      profiles = { Broken = "x", Default = {} },
    })
    assert.same({ ["Good - Realm"] = { steps = 1 } }, sv.char)
    assert.same({ ["Good - Realm"] = "Default" }, sv.profileKeys)
    assert.same({ Default = {} }, sv.profiles)
  end)

  it("checks exactly the sections AceDB-3.0 Release-r981 reads", function()
    local expected = {
      "char", "class", "faction", "factionrealm", "factionrealmregion", "global", "locale",
      "namespaces", "profile", "profileKeys", "profiles", "race", "realm",
    }
    local actual = {}
    for key in pairs(Schema.SECTIONS) do actual[#actual + 1] = key end
    table.sort(actual)
    assert.same(expected, actual)
  end)

  it("drops a wrong-type value for every AceDB section", function()
    for section, entryType in pairs(Schema.SECTIONS) do
      for _, bad in ipairs({ 5, "x", true }) do
        assert.same({}, Schema.sanitizeRoot({ [section] = bad }), section)
      end
      if entryType then
        local wrong = entryType == "table" and 5 or {}
        local right = entryType == "table" and {} or "Default"
        local sv = Schema.sanitizeRoot({ [section] = { bad = wrong, good = right } })
        assert.same({ good = right }, sv[section], section)
      end
    end
  end)

  it("drops profile and factionrealmregion values AceDB's logout handler would choke on", function()
    assert.same({}, Schema.sanitizeRoot({ profile = 5, factionrealmregion = "x" }))
    local sv = Schema.sanitizeRoot({ factionrealmregion = { a = 1, b = {} } })
    assert.same({ b = {} }, sv.factionrealmregion)
  end)

  it("sanitizes each namespace as a nested root", function()
    local sv = Schema.sanitizeRoot({ namespaces = { Foo = { char = 5, profileKeys = { X = {} } }, Bar = 5 } })
    assert.same({ namespaces = { Foo = { profileKeys = {} } } }, sv)
  end)

  it("does not recurse into namespaces of a namespace", function()
    local inner = { char = 5 }
    local sv = Schema.sanitizeRoot({ namespaces = { Foo = { namespaces = { Deep = inner } } } })
    assert.equals(inner, sv.namespaces.Foo.namespaces.Deep)
    assert.equals(5, inner.char)
  end)

  it("removes many bad entries interleaved with good ones in one pass", function()
    local char = {}
    for i = 1, 50 do
      char["bad"..i] = i
      char["good"..i] = { i = i }
    end
    local sv = Schema.sanitizeRoot({ char = char })
    local count = 0
    for key, value in pairs(sv.char) do
      count = count + 1
      assert.matches("^good", key)
      assert.is_table(value)
    end
    assert.equals(50, count)
  end)

  it("keeps a valid global and unknown top-level keys", function()
    local sv = Schema.sanitizeRoot({ global = { schemaVersion = 1 }, other = 5 })
    assert.same({ global = { schemaVersion = 1 }, other = 5 }, sv)
  end)
end)

describe("Schema.sanitizeChar", function()
  local Schema

  before_each(function()
    mocks.reset()
    local ns = mocks.newNamespace()
    mocks.loadSource("Modules/Schema.lua", ns)
    Schema = ns.Schema
  end)

  it("creates missing sections", function()
    local char = {}
    Schema.sanitizeChar(char, 20)
    assert.same({ stats = { yards = 0 }, progress = { total = 0, byZone = {} }, packs = {} }, char)
  end)

  it("replaces sections of the wrong type", function()
    local char = { stats = 5, progress = "x", packs = true }
    Schema.sanitizeChar(char, 20)
    assert.same({ stats = { yards = 0 }, progress = { total = 0, byZone = {} }, packs = {} }, char)
  end)

  it("resets bad lifetime yards", function()
    for _, bad in ipairs({ -1, 0 / 0, math.huge, "5", {} }) do
      local char = { stats = { yards = bad } }
      Schema.sanitizeChar(char, 20)
      assert.equals(0, char.stats.yards)
    end
  end)

  it("drops bad zone shares and recomputes the total", function()
    local char = { progress = { total = 1e9, byZone = {
      [1436] = 40, [1429] = 10.5,
      [0] = 5, [-3] = 5, [1.5] = 5, ["1436"] = 5,
      [12] = -1, [13] = 0 / 0, [14] = math.huge, [15] = "7",
    } } }
    Schema.sanitizeChar(char, 20)
    assert.same({ [1436] = 40, [1429] = 10.5 }, char.progress.byZone)
    assert.equals(50.5, char.progress.total)
  end)

  it("keeps valid packs, drops invalid ones and copies only known fields", function()
    local char = { packs = {
      { zoneMapID = 1436, earnedAt = 100, extra = "<script>" },
      { zoneMapID = "1436", earnedAt = 100 },
      { zoneMapID = 1.5, earnedAt = 100 },
      { zoneMapID = 1436, earnedAt = -1 },
      "pack",
      { zoneMapID = 1429, earnedAt = 200 },
    } }
    Schema.sanitizeChar(char, 20)
    assert.same({ { zoneMapID = 1436, earnedAt = 100 }, { zoneMapID = 1429, earnedAt = 200 } }, char.packs)
  end)

  it("drops zero shares, out-of-range map IDs and non-number keys", function()
    local char = { progress = { byZone = {
      [1436] = 10, [1429] = 0, [2 ^ 31] = 5, [1e300] = 5, [true] = 5, [{}] = 5,
    } } }
    Schema.sanitizeChar(char, 20)
    assert.same({ [1436] = 10 }, char.progress.byZone)
    assert.equals(10, char.progress.total)
  end)

  it("resets shares past MAX_ZONE_SHARES", function()
    local byZone = {}
    for i = 1, Schema.MAX_ZONE_SHARES + 1 do byZone[i] = 1 end
    local char = { progress = { byZone = byZone } }
    Schema.sanitizeChar(char, 20)
    assert.same({}, char.progress.byZone)
    assert.equals(0, char.progress.total)
  end)

  it("keeps exactly MAX_ZONE_SHARES shares", function()
    local byZone = {}
    for i = 1, Schema.MAX_ZONE_SHARES do byZone[i] = 1 end
    local char = { progress = { byZone = byZone } }
    Schema.sanitizeChar(char, 20)
    assert.equals(Schema.MAX_ZONE_SHARES, char.progress.total)
  end)

  it("resets shares whose sum overflows", function()
    local char = { progress = { byZone = { [1] = 1e308, [2] = 1e308 } } }
    Schema.sanitizeChar(char, 20)
    assert.same({}, char.progress.byZone)
    assert.equals(0, char.progress.total)
  end)

  it("drops packs with out-of-range IDs or timestamps", function()
    local char = { packs = {
      { zoneMapID = 1e300, earnedAt = 1 },
      { zoneMapID = 2 ^ 31, earnedAt = 1 },
      { zoneMapID = 1436, earnedAt = 1e300 },
      { zoneMapID = 1436, earnedAt = 0 / 0 },
      { zoneMapID = 1436, earnedAt = 1794158614 },
    } }
    Schema.sanitizeChar(char, 20)
    assert.same({ { zoneMapID = 1436, earnedAt = 1794158614 } }, char.packs)
  end)

  it("keeps a timestamp at MAX_TIMESTAMP and drops one above it", function()
    local char = { packs = {
      { zoneMapID = 1, earnedAt = Schema.MAX_TIMESTAMP },
      { zoneMapID = 2, earnedAt = Schema.MAX_TIMESTAMP + 1 },
    } }
    Schema.sanitizeChar(char, 20)
    assert.same({ { zoneMapID = 1, earnedAt = Schema.MAX_TIMESTAMP } }, char.packs)
  end)

  it("reads packs as a sequence, ignoring holes and named keys", function()
    local char = { packs = {
      [1] = { zoneMapID = 1, earnedAt = 1 },
      [3] = { zoneMapID = 3, earnedAt = 3 },
      a = { zoneMapID = 4, earnedAt = 4 },
    } }
    Schema.sanitizeChar(char, 20)
    assert.same({ { zoneMapID = 1, earnedAt = 1 } }, char.packs)
  end)

  it("does not let invalid packs use up the limit", function()
    local char = { packs = { "bad", "bad", { zoneMapID = 1, earnedAt = 1 }, { zoneMapID = 2, earnedAt = 2 } } }
    Schema.sanitizeChar(char, 2)
    assert.equals(2, #char.packs)
  end)

  it("trims packs to the limit", function()
    local packs = {}
    for i = 1, 30 do packs[i] = { zoneMapID = i, earnedAt = i } end
    local char = { packs = packs }
    Schema.sanitizeChar(char, 20)
    assert.equals(20, #char.packs)
    assert.equals(20, char.packs[20].zoneMapID)
  end)
end)

describe("Schema.sanitizeCollection", function()
  local Schema
  local KNOWN = { ["1436:moonbrook"] = true, ["1429:hogger"] = true }
  local function isKnown(id) return KNOWN[id] end

  before_each(function()
    mocks.reset()
    local ns = mocks.newNamespace()
    mocks.loadSource("Modules/Schema.lua", ns)
    Schema = ns.Schema
  end)

  local function sanitize(char, maxCopies, dataLoaded)
    if dataLoaded == nil then dataLoaded = true end
    Schema.sanitizeCollection(char, isKnown, maxCopies, dataLoaded)
  end

  it("keeps unknown string IDs when Data did not finish loading", function()
    local char = { collection = {
      ["1429:hogger"] = 1, ["1429:princess"] = 2,
      [""] = 1, [string.rep("a", 65)] = 1, [1436] = 1, [true] = 1,
    } }
    sanitize(char, 999, false)
    assert.same({ ["1429:hogger"] = 1, ["1429:princess"] = 2 }, char.collection)
  end)

  it("keeps copy-count checks when Data did not finish loading", function()
    local char = { collection = { ["1429:princess"] = 0, ["1429:x"] = 1.5 } }
    sanitize(char, 999, false)
    assert.same({}, char.collection)
  end)

  it("creates missing or wrong-type tables", function()
    local char = { collection = 5, newCards = "x" }
    sanitize(char, 999)
    assert.same({}, char.collection)
    assert.same({}, char.newCards)
  end)

  it("drops unknown card IDs, including known IDs with junk glued on", function()
    local char = { collection = {
      ["1436:moonbrook"] = 2, ["9999:fake"] = 1, ["1436:moonbrook<script>"] = 1,
      [" 1429:hogger"] = 1, ["<script>1436:moonbrook"] = 1, [""] = 1, [string.rep("a", 500)] = 1,
      [1436] = 1, [true] = 1,
    } }
    sanitize(char, 999)
    assert.same({ ["1436:moonbrook"] = 2 }, char.collection)
  end)

  it("drops counts that are not whole numbers of at least 1", function()
    for _, bad in ipairs({ 0, -1, 1.5, 0 / 0, math.huge, "2", true, {} }) do
      local char = { collection = { ["1429:hogger"] = bad } }
      sanitize(char, 999)
      assert.same({}, char.collection)
    end
  end)

  it("keeps a count at maxCopies and caps one above it", function()
    local char = { collection = { ["1429:hogger"] = 999, ["1436:moonbrook"] = 1000 } }
    sanitize(char, 999)
    assert.same({ ["1429:hogger"] = 999, ["1436:moonbrook"] = 999 }, char.collection)
  end)

  it("drops the New flag of a card whose count was invalid", function()
    local char = { collection = { ["1429:hogger"] = 0 }, newCards = { ["1429:hogger"] = true } }
    sanitize(char, 999)
    assert.same({}, char.newCards)
  end)

  it("keeps New flags only for owned cards with the value true", function()
    local char = {
      collection = { ["1429:hogger"] = 1, ["1436:moonbrook"] = 1 },
      newCards = { ["1429:hogger"] = true, ["1436:moonbrook"] = "yes", ["9999:fake"] = true },
    }
    sanitize(char, 999)
    assert.same({ ["1429:hogger"] = true }, char.newCards)
  end)
end)

describe("Schema.sanitizeGlobal", function()
  local Schema

  before_each(function()
    mocks.reset()
    local ns = mocks.newNamespace()
    mocks.loadSource("Modules/Schema.lua", ns)
    Schema = ns.Schema
  end)

  it("keeps the current version", function()
    local global = { schemaVersion = Schema.CURRENT_VERSION }
    assert.equals("ok", Schema.sanitizeGlobal(global))
    assert.equals(Schema.CURRENT_VERSION, global.schemaVersion)
  end)

  it("repairs a missing, string, negative, zero or fractional version", function()
    for _, bad in ipairs({ "nil", "1", -1, 0, 1.5 }) do
      local global = { schemaVersion = bad ~= "nil" and bad or nil }
      assert.equals("repaired", Schema.sanitizeGlobal(global))
      assert.equals(Schema.CURRENT_VERSION, global.schemaVersion)
    end
  end)

  it("repairs NaN, infinities, booleans and tables", function()
    for _, bad in ipairs({ 0 / 0, math.huge, -math.huge, true, {} }) do
      local global = { schemaVersion = bad }
      assert.equals("repaired", Schema.sanitizeGlobal(global))
      assert.equals(Schema.CURRENT_VERSION, global.schemaVersion)
    end
  end)

  it("reports a non-table global as invalid without throwing", function()
    for _, bad in ipairs({ 5, "x", true }) do
      assert.equals("invalid", Schema.sanitizeGlobal(bad))
    end
  end)

  it("treats a huge finite version as newer and keeps it", function()
    local global = { schemaVersion = 1e308 }
    assert.equals("newer", Schema.sanitizeGlobal(global))
    assert.equals(1e308, global.schemaVersion)
  end)

  it("reports a newer version and leaves the data untouched", function()
    local global = { schemaVersion = Schema.CURRENT_VERSION + 1, other = "kept" }
    assert.equals("newer", Schema.sanitizeGlobal(global))
    assert.equals(Schema.CURRENT_VERSION + 1, global.schemaVersion)
    assert.equals("kept", global.other)
  end)
end)
