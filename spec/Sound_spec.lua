local mocks = require("wow_mocks")

describe("Sound", function()
  local ns, Sound, played, env

  before_each(function()
    mocks.reset()
    ns = mocks.newNamespace()
    mocks.loadSource("Modules/Slash.lua", ns)
    mocks.loadSource("Modules/Sound.lua", ns)
    mocks.loadSource("Modules/Cards.lua", ns)
    mocks.loadSource("Developer/Art.lua", ns)
    Sound = ns.Sound
    played = {}
    env = {
      SOUNDKIT = { IG_BACKPACK_OPEN = 1, IG_ABILITY_PAGE_TURN = 2, UI_EPICLOOT_TOAST = 3 },
      PlaySound = function(kit) played[#played + 1] = kit end,
    }
    ns.GetDB = function() return { global = { settings = { sound = true } } } end
  end)

  it("maps rarities to events", function()
    assert.same({ "flip", "flip", "flip", "epic", "legendary" },
      { Sound.eventForRarity(1), Sound.eventForRarity(2), Sound.eventForRarity(3), Sound.eventForRarity(4), Sound.eventForRarity(5) })
  end)

  it("plays a known sound", function()
    assert.is_true(Sound.play("open", env))
    assert.same({ 1 }, played)
  end)

  it("skips a sound the client does not have", function()
    assert.is_false(Sound.play("legendary", env))
    assert.is_false(Sound.play("unknown-event", env))
    assert.is_false(Sound.play("open", {}))
    assert.same({}, played)
  end)

  it("stays silent when muted", function()
    ns.GetDB = function() return { global = { settings = { sound = false } } } end
    assert.is_false(Sound.play("open", env))
    assert.same({}, played)
  end)

  it("skips a SOUNDKIT entry that is not a number, or a SOUNDKIT that is not a table", function()
    assert.is_false(Sound.play("open", { SOUNDKIT = { IG_BACKPACK_OPEN = "1" }, PlaySound = env.PlaySound }))
    assert.is_false(Sound.play("open", { SOUNDKIT = "x", PlaySound = env.PlaySound }))
    assert.same({}, played)
  end)

  it("plays when settings are not loaded yet or sound is unset", function()
    ns.GetDB = function() return nil end
    assert.is_true(Sound.play("open", env))
    ns.GetDB = function() return { global = { settings = {} } } end
    assert.is_true(Sound.play("open", env))
  end)

  it("survives a throwing PlaySound", function()
    env.PlaySound = function() error("blocked") end
    assert.is_false(Sound.play("open", env))
  end)

  it("plays only the best rarity on Reveal all", function()
    Sound.playBest({ 1, 4, 2 }, env)
    assert.same({ 3 }, played)
    assert.is_false(Sound.playBest({}, env))
  end)

  it("lists present and missing sound names for /wd sounds", function()
    local lines = ns.Art.soundLines(env)
    assert.same({
      "epic: UI_EPICLOOT_TOAST present",
      "flip: IG_ABILITY_PAGE_TURN present",
      "legendary: UI_LEGENDARY_LOOT_TOAST MISSING",
      "open: IG_BACKPACK_OPEN present",
    }, lines)
  end)

  it("toggles sounds with /wd sound", function()
    local settings = { sound = true }
    ns.GetDB = function() return { global = { settings = settings } } end
    ns.Slash.dispatch("sound")
    assert.is_false(settings.sound)
    ns.Slash.dispatch("sound")
    assert.is_true(settings.sound)
  end)
end)
