local mocks = require("wow_mocks")

describe("Reveal", function()
  local Reveal

  before_each(function()
    mocks.reset()
    local ns = mocks.newNamespace()
    mocks.loadSource("Modules/Reveal.lua", ns)
    Reveal = ns.Reveal
  end)

  it("starts with every card face down", function()
    local state = Reveal.new({ "a", "b" }, {})
    assert.is_false(Reveal.isDone(state))
    assert.same({}, state.revealed)
  end)

  it("flips cards in any order and finishes when all are up", function()
    local state = Reveal.new({ "a", "b" }, {})
    assert.is_true(Reveal.flip(state, 2))
    assert.is_false(Reveal.isDone(state))
    assert.is_true(Reveal.flip(state, 1))
    assert.is_true(Reveal.isDone(state))
  end)

  it("does not count a card twice", function()
    local state = Reveal.new({ "a", "b" }, {})
    Reveal.flip(state, 1)
    assert.is_false(Reveal.flip(state, 1))
    assert.is_false(Reveal.isDone(state))
  end)

  it("ignores invalid indexes", function()
    local state = Reveal.new({ "a", "b" }, {})
    for _, bad in ipairs({ 0, 3, -1, 1.5, 0 / 0, "1", nil }) do
      assert.is_false(Reveal.flip(state, bad))
    end
    assert.equals(0, state.count)
  end)

  it("flips everything at once", function()
    local state = Reveal.new({ "a", "b", "c" }, {})
    Reveal.flip(state, 2)
    Reveal.flipAll(state)
    assert.is_true(Reveal.isDone(state))
    assert.equals(3, state.count)
  end)
end)
