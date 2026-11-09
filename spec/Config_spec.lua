local mocks = require("wow_mocks")

describe("Config", function()
  local Config

  before_each(function()
    mocks.reset()
    local ns = mocks.newNamespace()
    mocks.loadSource("Modules/Config.lua", ns)
    Config = ns.Config
  end)

  -- Chance that a pack of CARDS_PER_PACK cards holds at least one card of
  -- this rarity, from the per-card weights (the Uncommon guarantee only
  -- re-rolls packs of Commons, so it barely moves these numbers).
  local function perPack(rarity)
    local total = 0
    for _, w in ipairs(Config.RARITY_WEIGHTS) do total = total + w end
    local perCard = Config.RARITY_WEIGHTS[rarity] / total
    return 1 - (1 - perCard) ^ Config.CARDS_PER_PACK
  end

  it("gives an Epic to about 1 pack in 10 and a Legendary to about 1 in 40", function()
    assert.is_true(perPack(4) > 0.09 and perPack(4) < 0.11, tostring(perPack(4)))
    assert.is_true(perPack(5) > 0.02 and perPack(5) < 0.03, tostring(perPack(5)))
  end)

  it("uses whole positive weights, rarer ones never heavier", function()
    assert.equals(5, #Config.RARITY_WEIGHTS)
    for rarity, w in ipairs(Config.RARITY_WEIGHTS) do
      assert.is_true(w >= 1 and w % 1 == 0, tostring(rarity))
      if rarity > 1 then assert.is_true(w <= Config.RARITY_WEIGHTS[rarity - 1], tostring(rarity)) end
    end
  end)
end)
