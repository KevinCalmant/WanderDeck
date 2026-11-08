local mocks = require("wow_mocks")

describe("Wow.isSecret", function()
  local Wow

  before_each(function()
    mocks.reset()
    local ns = mocks.newNamespace()
    mocks.loadSource("Utils/Wow.lua", ns)
    Wow = ns.Wow
  end)

  it("returns false when the client has no issecretvalue", function()
    assert.is_false(Wow.isSecret(12))
  end)

  it("returns true for a value the client marks secret", function()
    local secret = mocks.newSecret()
    mocks.installSecrets({ secret })
    assert.is_true(Wow.isSecret(secret))
  end)

  it("returns false for a plain value", function()
    mocks.installSecrets({})
    assert.is_false(Wow.isSecret(12))
    assert.is_false(Wow.isSecret(nil))
  end)

  it("always returns a boolean", function()
    _G.issecretvalue = function() return 1 end
    assert.equals(true, Wow.isSecret("x"))
    _G.issecretvalue = function() return nil end
    assert.equals(false, Wow.isSecret("x"))
  end)
end)
