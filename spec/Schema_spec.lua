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
