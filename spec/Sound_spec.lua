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

  it("has no new-card sound event", function()
    assert.is_nil(Sound.KEYS.new)
    assert.is_false(Sound.play("new", env))
    assert.same({}, played)
  end)

  it("plays nothing on Reveal all when muted", function()
    ns.GetDB = function() return { global = { settings = { sound = false } } } end
    assert.is_false(Sound.playBest({ 5, 4 }, env))
    assert.same({}, played)
  end)

  it("handles odd rarities without error", function()
    for _, rarity in ipairs({ 0, 6, "5", -1 }) do
      assert.equals("flip", Sound.eventForRarity(rarity))
    end
    assert.is_false(Sound.playBest({ "5", {}, 0, 0 / 0 }, env))
    assert.same({}, played)
    assert.is_true(Sound.playBest({ math.huge }, env))
    assert.same({ 2 }, played)
  end)

  describe("candidate names (pack earned)", function()
    it("uses the first candidate name the client has", function()
      env.SOUNDKIT.LOOT_WINDOW_COIN_SOUND, env.SOUNDKIT.PUT_DOWN_SMALL_CHAIN = 9, 8
      Sound.play("earn", env)
      assert.same({ 9 }, played)
    end)

    it("falls back past a first name that is missing or not a number", function()
      env.SOUNDKIT.PUT_DOWN_SMALL_CHAIN = 8
      for _, bad in ipairs({ false, "9", {} }) do
        played = {}
        env.SOUNDKIT.LOOT_WINDOW_COIN_SOUND = bad or nil
        Sound.play("earn", env)
        assert.same({ 8 }, played)
      end
    end)

    it("skips the sound when no candidate exists", function()
      assert.is_false(Sound.play("earn", env))
      assert.same({}, played)
    end)
  end)

  it("lists present and missing sound names for /wd sounds", function()
    local lines = ns.Art.soundLines(env)
    assert.same({
      "earn: LOOT_WINDOW_COIN_SOUND MISSING, PUT_DOWN_SMALL_CHAIN MISSING",
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
