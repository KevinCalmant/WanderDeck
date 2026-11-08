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

  describe("new cards", function()
    before_each(function()
      env.SOUNDKIT.LOOT_WINDOW_COIN_SOUND = 9
    end)

    it("plays the loot sound for a card owned for the first time", function()
      assert.equals("new", Sound.eventFor(1, true))
      assert.is_true(Sound.play(Sound.eventFor(2, true), env))
      assert.same({ 9 }, played)
    end)

    it("plays the plain flip for a card already owned", function()
      Sound.play(Sound.eventFor(2, false), env)
      assert.same({ 2 }, played)
    end)

    it("keeps the Epic and Legendary sounds for new cards of those rarities", function()
      assert.equals("epic", Sound.eventFor(4, true))
      assert.equals("legendary", Sound.eventFor(5, true))
    end)

    it("uses the first candidate name the client has", function()
      env.SOUNDKIT.UI_BONUS_LOOT_ROLL_END = 8
      Sound.play("new", env)
      assert.same({ 8 }, played)
    end)

    it("falls back past a first name that is not a number", function()
      for _, bad in ipairs({ "8", {} }) do
        played = {}
        env.SOUNDKIT.UI_BONUS_LOOT_ROLL_END = bad
        Sound.play("new", env)
        assert.same({ 9 }, played)
      end
    end)

    it("plays nothing on Reveal all when muted, or with nothing revealed", function()
      ns.GetDB = function() return { global = { settings = { sound = false } } } end
      assert.is_false(Sound.playReveal({ { rarity = 5, isNew = true } }, env))
      ns.GetDB = function() return { global = { settings = { sound = true } } } end
      assert.is_false(Sound.playReveal({}, env))
      assert.same({}, played)
    end)

    it("handles odd rarities without error", function()
      for _, rarity in ipairs({ 0, 6, "5" }) do
        assert.equals("new", Sound.eventFor(rarity, true))
        assert.equals("flip", Sound.eventFor(rarity, false))
      end
    end)

    it("skips the sound when no candidate exists", function()
      env.SOUNDKIT.LOOT_WINDOW_COIN_SOUND = nil
      assert.is_false(Sound.play("new", env))
      assert.same({}, played)
    end)

    it("stays silent when muted", function()
      ns.GetDB = function() return { global = { settings = { sound = false } } } end
      assert.is_false(Sound.play("new", env))
      assert.same({}, played)
    end)

    it("plays one sound on Reveal all, new card over a plain flip, Epic over a new card", function()
      Sound.playReveal({ { rarity = 1 }, { rarity = 2, isNew = true }, { rarity = 1, isNew = true } }, env)
      assert.same({ 9 }, played)
      played = {}
      env.PlaySound = function(kit) played[#played + 1] = kit end
      Sound.playReveal({ { rarity = 2, isNew = true }, { rarity = 4 } }, env)
      assert.same({ 3 }, played)
    end)
  end)

  it("lists present and missing sound names for /wd sounds", function()
    local lines = ns.Art.soundLines(env)
    assert.same({
      "epic: UI_EPICLOOT_TOAST present",
      "flip: IG_ABILITY_PAGE_TURN present",
      "legendary: UI_LEGENDARY_LOOT_TOAST MISSING",
      "new: UI_BONUS_LOOT_ROLL_END MISSING, LOOT_WINDOW_COIN_SOUND MISSING",
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
