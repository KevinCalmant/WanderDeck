local mocks = require("wow_mocks")

local CONFIG = { CARDS_PER_PACK = 5, RARITY_WEIGHTS = { 60, 25, 10, 4, 1 }, GUARANTEED_RARITY = 2 }

local function always(value) return function(n) return math.min(value, n) end end
local function lowest(_) return 1 end
local function highest(n) return n end

local function card(id, rarity, kind)
  return { id = id, kind = kind or "creature", rarity = rarity, name = id, flavor = "" }
end

describe("Cards", function()
  local Cards

  before_each(function()
    mocks.reset()
    local ns = mocks.newNamespace()
    mocks.loadSource("Modules/Cards.lua", ns)
    Cards = ns.Cards
  end)

  describe("registerZone", function()
    it("registers cards with derived stats", function()
      Cards.registerZone({ zoneMapID = 10, continentMapID = 1, cards = { card("10:a", 1), card("10:b", 5, "boss") } })
      local a = Cards.get("10:a")
      assert.equals(10, a.zoneMapID)
      assert.same({ 2, 1 }, { a.attack, a.defense })
      assert.same({ 13, 12 }, { Cards.get("10:b").attack, Cards.get("10:b").defense })
    end)

    it("copies only known fields", function()
      local c = card("10:a", 1)
      c.extra = "x"
      Cards.registerZone({ zoneMapID = 10, continentMapID = 1, cards = { c } })
      assert.is_nil(Cards.get("10:a").extra)
    end)

    local function rejects(zone)
      assert.has_error(function() Cards.registerZone(zone) end)
    end

    it("rejects a zone without valid map IDs or cards", function()
      rejects({ zoneMapID = 0, continentMapID = 1, cards = { card("0:a", 1) } })
      rejects({ zoneMapID = 10, continentMapID = 1.5, cards = { card("10:a", 1) } })
      rejects({ zoneMapID = 10, continentMapID = 1, cards = {} })
      rejects("zone")
    end)

    it("rejects malformed card IDs, including valid IDs with junk glued on", function()
      for _, bad in ipairs({
        "a", "10:", "10:A", "10:a b", "11:a", "10:a<script>", " 10:a", "10:a\n", 10,
        "<script>10:a", "<script>alert(1)</script>", "", "010:a", "10:../a", "10:a/b", "10:a|r",
        "10:"..string.rep("a", 62),
      }) do
        mocks.reset()
        local ns = mocks.newNamespace()
        mocks.loadSource("Modules/Cards.lua", ns)
        local c = card("10:a", 1)
        c.id = bad
        assert.has_error(function() ns.Cards.registerZone({ zoneMapID = 10, continentMapID = 1, cards = { c } }) end, nil, tostring(bad))
      end
    end)

    it("rejects unknown kinds, rarities and missing text", function()
      local function zoneWith(c) return { zoneMapID = 10, continentMapID = 1, cards = { c } } end
      local c = card("10:a", 1, "dragon")
      rejects(zoneWith(c))
      for _, rarity in ipairs({ 0, 6, 1.5, "1" }) do rejects(zoneWith(card("10:a", rarity))) end
      c = card("10:a", 1); c.name = ""; rejects(zoneWith(c))
      c = card("10:a", 1); c.flavor = nil; rejects(zoneWith(c))
    end)

    it("rejects names and flavor with chat codes, control characters, blanks or excess length", function()
      local function zoneWith(c) return { zoneMapID = 10, continentMapID = 1, cards = { c } } end
      for _, badName in ipairs({ "   ", "<x>|cffff0000Evil|r", "Hogger\n", "a\0b", "a\rb", "a\tb", string.rep("a", 65) }) do
        local c = card("10:a", 1)
        c.name = badName
        rejects(zoneWith(c))
      end
      for _, badFlavor in ipairs({ "line|r", "two\nlines", string.rep("a", 201) }) do
        local c = card("10:a", 1)
        c.flavor = badFlavor
        rejects(zoneWith(c))
      end
    end)

    it("accepts a 64-character name and a 200-character flavor", function()
      local c = card("10:a", 1)
      c.name, c.flavor = string.rep("a", 64), string.rep("b", 200)
      Cards.registerZone({ zoneMapID = 10, continentMapID = 1, cards = { c } })
      assert.truthy(Cards.get("10:a"))
    end)

    it("accepts an ID at exactly 64 characters", function()
      Cards.registerZone({ zoneMapID = 10, continentMapID = 1, cards = { card("10:"..string.rep("a", 61), 1) } })
      assert.truthy(Cards.get("10:"..string.rep("a", 61)))
    end)

    it("registers nothing from a zone with one invalid card", function()
      local bad = card("10:b", 9)
      assert.has_error(function()
        Cards.registerZone({ zoneMapID = 10, continentMapID = 1, cards = { card("10:a", 1), bad } })
      end)
      assert.is_nil(Cards.get("10:a"))
      assert.same({}, Cards.zoneIDs())
    end)

    it("uses the card icon, or the kind's icon when there is none", function()
      local withIcon = card("10:a", 1)
      withIcon.icon = "Ability_Hunter_Pet_Wolf"
      Cards.registerZone({ zoneMapID = 10, continentMapID = 1, cards = { withIcon, card("10:b", 1, "place") } })
      assert.equals("Interface\\Icons\\Ability_Hunter_Pet_Wolf", Cards.iconPath(Cards.get("10:a")))
      assert.equals("Interface\\Icons\\INV_Misc_Map_01", Cards.iconPath(Cards.get("10:b")))
    end)

    it("rejects icons that are not a plain file name", function()
      for _, bad in ipairs({
        "", " ", "a b", "../x", "a/b", "Interface\\Icons\\x", "x|T", "x:20|t", "x.blp", string.rep("a", 65), 5, true,
        "<script>alert(1)</script>", "INV_Misc_Map_01<script>alert(1)</script>",
        "INV_Misc_Map_01|t|cffff0000x", "|TInterface\\x:0|tINV_Misc_Map_01", "INV_Misc_Map_01\n", "a\0b",
      }) do
        local c = card("10:a", 1)
        c.icon = bad
        local ok, err = pcall(Cards.registerZone, { zoneMapID = 10, continentMapID = 1, cards = { c } })
        assert.is_false(ok, tostring(bad))
        assert.matches("icon", err, 1, true)
      end
    end)

    it("accepts an icon name of exactly 64 characters", function()
      local c = card("10:a", 1)
      c.icon = string.rep("a", 64)
      Cards.registerZone({ zoneMapID = 10, continentMapID = 1, cards = { c } })
      assert.equals(string.rep("a", 64), Cards.get("10:a").icon)
    end)

    it("gives every kind a valid default icon", function()
      local cards = {}
      for i, kind in ipairs(Cards.kinds()) do cards[i] = card("10:k"..i, 1, kind) end
      Cards.registerZone({ zoneMapID = 10, continentMapID = 1, cards = cards })
      for i in ipairs(cards) do
        assert.matches("^[A-Za-z0-9_]+$", Cards.get("10:k"..i).icon)
      end
    end)

    it("rejects duplicate IDs and zones", function()
      Cards.registerZone({ zoneMapID = 10, continentMapID = 1, cards = { card("10:a", 1) } })
      rejects({ zoneMapID = 10, continentMapID = 1, cards = { card("10:b", 1) } })
      rejects({ zoneMapID = 11, continentMapID = 1, cards = { card("11:a", 1), card("11:a", 1) } })
    end)
  end)

  describe("foldZone", function()
    it("maps a city to its outdoor zone and leaves other zones alone", function()
      Cards.foldZone(1453, 1429)
      assert.equals(1429, Cards.cardZone(1453))
      assert.equals(1429, Cards.cardZone(1429))
      assert.equals(1436, Cards.cardZone(1436))
      assert.is_nil(Cards.cardZone(nil))
    end)

    it("rejects bad IDs, self folds, duplicates and chains", function()
      for _, bad in ipairs({ { 0, 1 }, { 1, 0 }, { 1.5, 2 }, { "1453", 1429 }, { 0 / 0, 1 } }) do
        assert.has_error(function() Cards.foldZone(bad[1], bad[2]) end)
      end
      assert.has_error(function() Cards.foldZone(5, 5) end)
      Cards.foldZone(1453, 1429)
      assert.has_error(function() Cards.foldZone(1453, 1436) end) -- folded twice
      assert.has_error(function() Cards.foldZone(1429, 9) end)    -- parent folded
      assert.has_error(function() Cards.foldZone(7, 1453) end)    -- parent is a folded child
    end)
  end)

  describe("get", function()
    it("returns nil for unknown or non-string IDs", function()
      assert.is_nil(Cards.get("10:a"))
      assert.is_nil(Cards.get(nil))
      assert.is_nil(Cards.get({}))
    end)
  end)

  describe("poolFor", function()
    before_each(function()
      Cards.registerZone({ zoneMapID = 10, continentMapID = 1, cards = { card("10:a", 1) } })
      Cards.registerZone({ zoneMapID = 11, continentMapID = 1, cards = { card("11:a", 2) } })
      Cards.registerZone({ zoneMapID = 20, continentMapID = 2, cards = { card("20:a", 3) } })
    end)

    it("uses the zone's cards when the zone has data", function()
      local pool = Cards.poolFor(10, 1)
      assert.equals("zone", pool.level)
      assert.equals(1, pool.size)
    end)

    it("falls back to the continent's cards", function()
      local pool = Cards.poolFor(99, 1)
      assert.equals("continent", pool.level)
      assert.equals(2, pool.size)
    end)

    it("falls back to every card without a known continent", function()
      assert.equals("all", Cards.poolFor(99, nil).level)
      assert.equals("all", Cards.poolFor(99, 77).level)
      assert.equals(3, Cards.poolFor(99, 77).size)
    end)
  end)

  describe("rollRarity", function()
    it("maps the roll onto cumulative weights", function()
      local weights = CONFIG.RARITY_WEIGHTS
      assert.equals(1, Cards.rollRarity(weights, 1, always(60)))
      assert.equals(2, Cards.rollRarity(weights, 1, always(61)))
      assert.equals(4, Cards.rollRarity(weights, 1, always(99)))
      assert.equals(5, Cards.rollRarity(weights, 1, highest))
    end)

    it("only rolls at or above the minimum rarity", function()
      assert.equals(2, Cards.rollRarity(CONFIG.RARITY_WEIGHTS, 2, lowest))
    end)

    it("returns nil when no weight is left", function()
      assert.is_nil(Cards.rollRarity({ 1, 0, 0, 0, 0 }, 2, lowest))
    end)

    it("returns nil when the weights sum below 1 (math.random(0) would throw)", function()
      assert.is_nil(Cards.rollRarity({ 0.5, 0, 0, 0, 0 }, 1, function() error("rng called") end))
      assert.is_nil(Cards.rollRarity({ 0 / 0, 0, 0, 0, 0 }, 1, function() error("rng called") end))
    end)
  end)

  describe("openPack", function()
    it("returns CARDS_PER_PACK cards from the pool", function()
      Cards.registerZone({ zoneMapID = 10, continentMapID = 1, cards = {
        card("10:c", 1), card("10:u", 2), card("10:r", 3), card("10:e", 4), card("10:l", 5),
      } })
      local ids = Cards.openPack(Cards.poolFor(10), highest, CONFIG)
      assert.same({ "10:l", "10:l", "10:l", "10:l", "10:l" }, ids)
    end)

    it("upgrades the last card when no card reaches the guaranteed rarity", function()
      Cards.registerZone({ zoneMapID = 10, continentMapID = 1, cards = { card("10:c", 1), card("10:u", 2) } })
      local ids = Cards.openPack(Cards.poolFor(10), lowest, CONFIG)
      assert.same({ "10:c", "10:c", "10:c", "10:c", "10:u" }, ids)
    end)

    it("keeps an all-common pack when the pool has nothing better", function()
      Cards.registerZone({ zoneMapID = 10, continentMapID = 1, cards = { card("10:c", 1) } })
      assert.same({ "10:c", "10:c", "10:c", "10:c", "10:c" }, Cards.openPack(Cards.poolFor(10), lowest, CONFIG))
    end)

    it("steps down to the closest lower rarity the pool has, then up", function()
      Cards.registerZone({ zoneMapID = 10, continentMapID = 1, cards = { card("10:u", 2) } })
      Cards.registerZone({ zoneMapID = 11, continentMapID = 1, cards = { card("11:e", 4) } })
      assert.equals("10:u", Cards.openPack(Cards.poolFor(10), highest, CONFIG)[1])
      assert.equals("11:e", Cards.openPack(Cards.poolFor(11), lowest, CONFIG)[1])
    end)

    it("returns nothing instead of failing on degenerate config", function()
      Cards.registerZone({ zoneMapID = 10, continentMapID = 1, cards = { card("10:c", 1) } })
      local pool = Cards.poolFor(10)
      assert.same({}, Cards.openPack(pool, lowest, { CARDS_PER_PACK = 5, RARITY_WEIGHTS = { 0, 0, 0, 0, 0 }, GUARANTEED_RARITY = 2 }))
      assert.same({}, Cards.openPack(pool, lowest, { CARDS_PER_PACK = 0, RARITY_WEIGHTS = CONFIG.RARITY_WEIGHTS, GUARANTEED_RARITY = 2 }))
      assert.same({}, Cards.openPack(pool, lowest, { CARDS_PER_PACK = 0 / 0, RARITY_WEIGHTS = CONFIG.RARITY_WEIGHTS, GUARANTEED_RARITY = 2 }))
    end)

    it("skips the guarantee when GUARANTEED_RARITY is not 1-5", function()
      Cards.registerZone({ zoneMapID = 10, continentMapID = 1, cards = { card("10:c", 1), card("10:u", 2) } })
      local config = { CARDS_PER_PACK = 2, RARITY_WEIGHTS = CONFIG.RARITY_WEIGHTS, GUARANTEED_RARITY = 9 }
      assert.same({ "10:c", "10:c" }, Cards.openPack(Cards.poolFor(10), lowest, config))
    end)

    it("returns nothing for an empty pool", function()
      assert.same({}, Cards.openPack(Cards.poolFor(10), lowest, CONFIG))
    end)
  end)
end)

describe("Data", function()
  local ns

  before_each(function()
    mocks.reset()
    ns = mocks.newNamespace()
    mocks.loadSource("Modules/Cards.lua", ns)
    mocks.loadAllData(ns)
  end)

  it("folds every city into a shipped zone and never registers a city as a zone", function()
    assert.equals(1429, ns.Cards.cardZone(1453)) -- Stormwind -> Elwynn
    assert.equals(1426, ns.Cards.cardZone(1455)) -- Ironforge -> Dun Morogh
    assert.equals(1438, ns.Cards.cardZone(1457)) -- Darnassus -> Teldrassil
    assert.equals(1411, ns.Cards.cardZone(1454)) -- Orgrimmar -> Durotar
    assert.equals(1420, ns.Cards.cardZone(1458)) -- Undercity -> Tirisfal
    assert.equals(1412, ns.Cards.cardZone(1456)) -- Thunder Bluff -> Mulgore
    for _, zoneMapID in ipairs(ns.Cards.zoneIDs()) do
      assert.equals(zoneMapID, ns.Cards.cardZone(zoneMapID), "a registered zone must not be folded")
    end
  end)

  it("registers the two first zones and the five starting zones", function()
    assert.same({ 1411, 1412, 1420, 1426, 1429, 1436, 1438 }, ns.Cards.zoneIDs())
  end)

  it("translates every card's flavor text into French", function()
    _G.GetLocale = function() return "frFR" end
    local fr = mocks.newNamespace()
    mocks.loadSource("Locales/enUS.lua", fr)
    mocks.loadSource("Locales/frFR.lua", fr)
    for _, zoneMapID in ipairs(ns.Cards.zoneIDs()) do
      for _, c in ipairs(ns.Cards.zoneCards(zoneMapID)) do
        assert.is_string(rawget(fr.L, c.flavor), c.id)
      end
    end
  end)

  it("folds cities only into zones that ship cards", function()
    local zones = {}
    for _, id in ipairs(ns.Cards.zoneIDs()) do zones[id] = true end
    for _, city in ipairs({ 1453, 1455, 1457, 1454, 1458, 1456 }) do
      assert.is_true(zones[ns.Cards.cardZone(city)] == true, tostring(city))
    end
  end)

  it("ships 11 to 20 cards per zone", function()
    for _, zoneMapID in ipairs(ns.Cards.zoneIDs()) do
      local count = #ns.Cards.zoneCards(zoneMapID)
      assert.is_true(count >= 11 and count <= 20, zoneMapID..": "..count)
    end
  end)

  it("gives every zone at least one card of each rarity", function()
    for _, zoneMapID in ipairs(ns.Cards.zoneIDs()) do
      local seen = {}
      for _, c in ipairs(ns.Cards.zoneCards(zoneMapID)) do seen[c.rarity] = true end
      for rarity = 1, 5 do assert.is_true(seen[rarity] == true, zoneMapID..": rarity "..rarity) end
    end
  end)

  it("is marked loaded once Data/Loaded.lua runs after every zone registered", function()
    assert.is_nil(ns.Cards.dataLoaded)
    mocks.loadSource("Data/Loaded.lua", ns)
    assert.is_true(ns.Cards.dataLoaded)
  end)

  it("lists exactly the zones the Data files register", function()
    mocks.loadSource("Data/Loaded.lua", ns)
    local expected = {}
    for _, id in ipairs(ns.Cards.EXPECTED_ZONES) do expected[#expected + 1] = id end
    table.sort(expected)
    assert.same(ns.Cards.zoneIDs(), expected)
  end)

  it("lists every zone that the files in load_data.xml register", function()
    mocks.reset()
    local fresh = mocks.newNamespace()
    mocks.loadSource("Modules/Cards.lua", fresh)
    local xml = assert(io.open("Data/load_data.xml")):read("*a")
    local files = {}
    for file in xml:gmatch('<Script file="([^"]+)"') do files[#files + 1] = file end
    assert.equals("Loaded.lua", files[#files], "Loaded.lua must be last in load_data.xml")
    for _, file in ipairs(files) do
      mocks.loadSource("Data/"..file:gsub("\\", "/"), fresh)
    end
    local expected = {}
    for _, id in ipairs(fresh.Cards.EXPECTED_ZONES) do expected[#expected + 1] = id end
    table.sort(expected)
    assert.same(fresh.Cards.zoneIDs(), expected)
    assert.is_true(fresh.Cards.dataLoaded)
  end)

  it("stays not loaded when a Data file failed before Loaded.lua", function()
    mocks.reset()
    local partial = mocks.newNamespace()
    mocks.loadSource("Modules/Cards.lua", partial)
    -- ElwynnForest.lua "failed": only Westfall registered, then Loaded.lua runs.
    mocks.loadSource("Data/EasternKingdoms/Westfall.lua", partial)
    mocks.loadSource("Data/Loaded.lua", partial)
    assert.is_nil(partial.Cards.dataLoaded)
  end)

  it("stays not loaded when a Data file throws mid-zone", function()
    mocks.reset()
    local partial = mocks.newNamespace()
    mocks.loadSource("Modules/Cards.lua", partial)
    assert.has_error(function()
      partial.Cards.registerZone({ zoneMapID = 1429, continentMapID = 1415, cards = {
        { id = "1429:hogger", kind = "elite", rarity = 5, name = "Hogger", flavor = "" },
        { id = "1429:typo", kind = "dragon", rarity = 1, name = "Typo", flavor = "" },
      } })
    end)
    mocks.loadSource("Data/EasternKingdoms/Westfall.lua", partial)
    mocks.loadSource("Data/Loaded.lua", partial)
    assert.is_nil(partial.Cards.dataLoaded)
  end)

  it("keeps every English and French locale string free of chat escape codes", function()
    for _, locale in ipairs({ "enUS", "frFR" }) do
      _G.GetLocale = function() return locale end
      local localeNS = mocks.newNamespace()
      mocks.loadSource("Locales/enUS.lua", localeNS)
      mocks.loadSource("Locales/frFR.lua", localeNS)
      for key, value in pairs(localeNS.L) do
        assert.is_nil(value:find("|", 1, true), locale..": "..key)
        assert.is_nil(value:find("%c"), locale..": control character in "..key)
        assert.is_true(#value <= 200, locale..": too long: "..key)
      end
    end
  end)

  it("keeps card text free of chat escape codes", function()
    for _, zoneMapID in ipairs(ns.Cards.zoneIDs()) do
      for _, c in ipairs(ns.Cards.zoneCards(zoneMapID)) do
        assert.is_nil(c.name:find("|", 1, true), c.id)
        assert.is_nil(c.flavor:find("|", 1, true), c.id)
      end
    end
  end)
end)
