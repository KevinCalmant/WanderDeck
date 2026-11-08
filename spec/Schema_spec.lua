local mocks = require("wow_mocks")

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

  it("reports a newer version and leaves the data untouched", function()
    local global = { schemaVersion = Schema.CURRENT_VERSION + 1, other = "kept" }
    assert.equals("newer", Schema.sanitizeGlobal(global))
    assert.equals(Schema.CURRENT_VERSION + 1, global.schemaVersion)
    assert.equals("kept", global.other)
  end)
end)
