local mocks = require("wow_mocks")

-- Dungeon cards use their loading screen as card art: data validation,
-- the shipped mapping, the crop, the card widget and /wd loadscreens.

local DUNGEONS = {
  "1411:ragefire_chasm", "1413:razorfen_downs", "1413:razorfen_kraul", "1413:wailing_caverns",
  "1418:uldaman", "1420:scarlet_monastery", "1421:shadowfang_keep", "1422:scholomance",
  "1423:stratholme", "1428:blackrock_depths", "1428:blackrock_spire", "1435:temple_of_atalhakkar",
  "1436:the_deadmines", "1440:blackfathom_deeps", "1443:maraudon", "1444:dire_maul", "1446:zulfarrak",
}

local function place(loadScreen)
  return { id = "10:a", kind = "place", rarity = 4, name = "Dungeon", loadScreen = loadScreen }
end

describe("loading screen art", function()
  local ns

  before_each(function()
    mocks.reset()
    ns = mocks.newNamespace()
    mocks.loadSource("Modules/Cards.lua", ns)
  end)

  local function register(c)
    return pcall(ns.Cards.registerZone, { zoneMapID = 10, continentMapID = 1, cards = { c } })
  end

  describe("validation", function()
    it("accepts a file name or a file ID, and no loading screen", function()
      assert.is_true(register(place("LoadScreenDeadmines")))
      assert.equals("Interface\\Glues\\LoadingScreens\\LoadScreenDeadmines", ns.Cards.loadScreenPath(ns.Cards.get("10:a")))
      mocks.reset()
      ns = mocks.newNamespace()
      mocks.loadSource("Modules/Cards.lua", ns)
      assert.is_true(register(place(526205)))
      assert.equals(526205, ns.Cards.loadScreenPath(ns.Cards.get("10:a")))
    end)

    it("has no loading screen path for a card without one", function()
      assert.is_true(register(place(nil)))
      assert.is_nil(ns.Cards.loadScreenPath(ns.Cards.get("10:a")))
    end)

    it("accepts a name of exactly 64 characters", function()
      assert.is_true(register(place(string.rep("a", 64))))
    end)

    it("rejects anything that is not a plain file name or a positive whole file ID", function()
      for _, bad in ipairs({
        "", " ", string.rep("a", 65), "a b", "../LoadScreenDeadmines", "..\\LoadScreenDeadmines",
        "Interface\\Glues\\LoadingScreens\\LoadScreenDeadmines", "Interface/Icons/x", "x.blp",
        "LoadScreenDeadmines|cffff0000x", "|TInterface\\x:0|tLoadScreenDeadmines", "LoadScreenDeadmines:20|t",
        "<script>alert(1)</script>", "LoadScreenDeadmines<script>alert(1)</script>", "<script>LoadScreenDeadmines",
        "LoadScreenDeadmines\n", "a\0b", "LoadScreenDeadmines..", 0, -1, 1.5, -1.5, 0 / 0, math.huge, -math.huge, 2 ^ 31, true, {},
      }) do
        local ok, err = register(place(bad))
        assert.is_false(ok, tostring(bad))
        assert.matches("loadScreen", err, 1, true)
      end
    end)
  end)

  describe("shipped data", function()
    it("gives each dungeon place card a loading screen, and no other card one", function()
      mocks.loadAllData(ns)
      local found = {}
      for _, zoneMapID in ipairs(ns.Cards.zoneIDs()) do
        for _, c in ipairs(ns.Cards.zoneCards(zoneMapID)) do
          if c.loadScreen then
            assert.equals("place", c.kind, c.id)
            found[#found + 1] = c.id
          end
        end
      end
      table.sort(found)
      assert.same(DUNGEONS, found)
    end)
  end)
end)

-- Permissive frame stub (as in UI_spec): textures record their texture and
-- answer GetTextureFileID from a per-test resolver.
local resolve
local function stub()
  local obj = { shown = false, scripts = {} }
  return setmetatable(obj, { __index = function(_, key)
    if key == "Show" then return function(self) self.shown = true end end
    if key == "Hide" then return function(self) self.shown = false end end
    if key == "IsShown" or key == "IsVisible" then return function(self) return self.shown end end
    if key == "SetScript" then return function(self, name, fn) self.scripts[name] = fn end end
    if key == "SetTexture" then return function(self, v) self.texture = v end end
    if key == "SetTexCoord" then return function(self, ...) self.texCoord = { ... } end end
    if key == "GetTextureFileID" then return function(self) return resolve(self.texture) end end
    if key:match("^Create") then return function() return stub() end end
    return function() end
  end })
end

describe("loading screen card widget", function()
  local ns, w

  local function dungeon(fields)
    local c = { id = "1436:the_deadmines", kind = "place", rarity = 4, name = "The Deadmines",
      icon = "INV_Misc_Bomb_02", loadScreen = "LoadScreenDeadmines", attack = 1, defense = 1 }
    for k, v in pairs(fields or {}) do c[k] = v end
    return c
  end

  before_each(function()
    mocks.reset()
    ns = mocks.newNamespace()
    _G.CreateFrame = function() return stub() end
    for _, file in ipairs({ "Utils/Wow.lua", "Modules/Config.lua", "Modules/Cards.lua", "Modules/CardText.lua",
      "Modules/UI/Draw.lua", "Modules/UI/CardWidget.lua" }) do
      mocks.loadSource(file, ns)
    end
    resolve = function(path) return path == "Interface\\Glues\\LoadingScreens\\LoadScreenDeadmines" and 526205 or nil end
    w = ns.CardWidget.create(stub())
  end)

  after_each(function() _G.CreateFrame, _G.C_Timer = nil, nil end)

  it("crops without stretching: top and bottom of a narrower image, sides of a wider one", function()
    assert.same({ 0, 1, 0.25, 0.75 }, { ns.CardWidget.cropTexCoord(1, 2, 1) })
    assert.same({ 0.25, 0.75, 0, 1 }, { ns.CardWidget.cropTexCoord(2, 1, 1) })
    assert.same({ 0, 1, 0, 1 }, { ns.CardWidget.cropTexCoord(1, 4, 4) })
  end)

  it("crops the screen to the art panel", function()
    -- 4:3 into 108 x 78: about 3 % cut from the top and the bottom.
    local l, r, t, b = unpack(w.loadScreen.texCoord)
    assert.same({ 0, 1 }, { l, r })
    assert.is_true(math.abs(t - (1 - (4 / 3) / (108 / 78)) / 2) < 1e-9)
    assert.is_true(math.abs(1 - b - t) < 1e-9)
  end)

  it("shows the loading screen over the icon once the client resolves it", function()
    ns.CardWidget.showCard(w, dungeon())
    assert.is_true(w.loadScreen.shown)
    assert.is_false(w.icon.shown)
  end)

  it("takes a file ID as is", function()
    resolve = function(v) return v end
    ns.CardWidget.showCard(w, dungeon({ loadScreen = 526205 }))
    assert.equals(526205, w.loadScreen.texture)
    assert.is_true(w.loadScreen.shown)
  end)

  it("keeps the icon when the file is missing, secret, odd or the getter throws", function()
    local secret = mocks.newSecret()
    mocks.installSecrets({ secret })
    for _, r in ipairs({
      function() return nil end, function() return 0 end, function() return -1 end, function() return "526205" end,
      function() return 1.5 end, function() error("x") end, function() return secret end,
      function() return 0 / 0 end, function() return math.huge end, function() return -math.huge end,
      function() return 2 ^ 31 end,
    }) do
      resolve = r
      ns.CardWidget.showCard(w, dungeon())
      assert.is_false(w.loadScreen.shown)
      assert.is_true(w.icon.shown)
    end
  end)

  it("keeps the icon on a card without a loading screen, and hides the screen of the previous card", function()
    ns.CardWidget.showCard(w, dungeon())
    ns.CardWidget.showCard(w, dungeon({ loadScreen = false }))
    assert.is_false(w.loadScreen.shown)
    assert.is_true(w.icon.shown)
    ns.CardWidget.showCard(w, dungeon())
    ns.CardWidget.showBack(w)
    assert.is_false(w.loadScreen.shown)
  end)

  it("keeps the 3D model for a creature card", function()
    ns.CardWidget.showCard(w, dungeon({ kind = "boss", npcID = 639 }))
    assert.is_false(w.loadScreen.shown)
    assert.is_true(w.model.shown)
  end)

  describe("/wd loadscreens", function()
    before_each(function()
      mocks.loadAllData(ns)
      mocks.loadSource("Modules/Slash.lua", ns)
      mocks.loadSource("Developer/LoadScreenTest.lua", ns)
    end)

    it("lists the dungeon cards", function()
      local cards = ns.LoadScreenTest.cards(ns.Cards.zoneIDs(), ns.Cards.zoneCards)
      assert.equals(#DUNGEONS, #cards)
      for _, c in ipairs(cards) do assert.is_not_nil(c.loadScreen) end
    end)

    it("reports the resolved file, or MISSING", function()
      local c = ns.Cards.get("1436:the_deadmines")
      assert.equals("  1436:the_deadmines  LoadScreenDeadmines  file 526205", ns.LoadScreenTest.reportLine(c, true, 526205))
      local secret = mocks.newSecret()
      mocks.installSecrets({ secret })
      for _, args in ipairs({ { true, nil }, { true, 0 }, { true, "1" }, { false, "error" }, { true, secret },
        { true, -1 }, { true, 1.5 }, { true, 0 / 0 }, { true, math.huge }, { true, -math.huge }, { true, 2 ^ 31 } }) do
        assert.equals("  1436:the_deadmines  LoadScreenDeadmines  MISSING", ns.LoadScreenTest.reportLine(c, args[1], args[2]))
      end
    end)
  end)
end)
