local mocks = require("wow_mocks")

describe("CardText", function()
  local ns, CardText

  local function card(fields)
    local c = { id = "10:a", name = "Linen Cloth", icon = "INV_Misc_Bag_08" }
    for k, v in pairs(fields or {}) do c[k] = v end
    return c
  end

  before_each(function()
    mocks.reset()
    ns = mocks.newNamespace()
    ns.L["Linen Cloth"] = "Linen Cloth (data)"
    mocks.loadSource("Utils/Wow.lua", ns)
    mocks.loadSource("Modules/Cards.lua", ns)
    mocks.loadSource("Modules/CardText.lua", ns)
    CardText = ns.CardText
  end)

  describe("name", function()
    it("uses the data name for a card without a game ID", function()
      assert.equals("Linen Cloth (data)", CardText.name(card(), {}))
    end)

    it("falls back to the English name when a translation is not clean text", function()
      for _, bad in ipairs({ "Mineur kobold\226", "\226\128\174Mineur", "Mineur\194\133", " " }) do
        ns.L["Linen Cloth"] = bad
        assert.equals("Linen Cloth", CardText.name(card(), {}))
      end
      -- A pipe is escaped, not refused, like client text.
      ns.L["Linen Cloth"] = "a|cffff0000b"
      assert.equals("a||cffff0000b", CardText.name(card(), {}))
    end)

    it("uses the client's item, quest and area names", function()
      local env = {
        C_Item = { GetItemNameByID = function(id) return id == 2589 and "Étoffe de lin" or nil end },
        C_QuestLog = { GetTitleForQuestID = function(id) return id == 176 and "Avis de recherche : Lardeur" or nil end },
        C_Map = { GetAreaInfo = function(id) return id == 87 and "Comté-de-l'Or" or nil end },
      }
      assert.equals("Étoffe de lin", CardText.name(card({ itemID = 2589 }), env))
      assert.equals("Avis de recherche : Lardeur", CardText.name(card({ questID = 176 }), env))
      assert.equals("Comté-de-l'Or", CardText.name(card({ areaID = 87 }), env))
    end)

    it("asks the client to load an item that is not cached and falls back meanwhile", function()
      local requested
      local env = { C_Item = {
        GetItemNameByID = function() return nil end,
        RequestLoadItemDataByID = function(id) requested = id end,
      } }
      assert.equals("Linen Cloth (data)", CardText.name(card({ itemID = 2589 }), env))
      assert.equals(2589, requested)
    end)

    it("falls back on a missing API, a throwing API, a secret, an empty, long or multi-line name", function()
      local secret = mocks.newSecret()
      mocks.installSecrets({ secret })
      for _, getName in ipairs({
        function() error("restricted") end,
        function() return secret end,
        function() return "" end,
        function() return string.rep("a", 65) end,
        function() return "line\nbreak" end,
        function() return 42 end,
      }) do
        local env = { C_Item = { GetItemNameByID = getName } }
        assert.equals("Linen Cloth (data)", CardText.name(card({ itemID = 2589 }), env))
      end
      assert.equals("Linen Cloth (data)", CardText.name(card({ itemID = 2589 }), {}))
      assert.equals("Linen Cloth (data)", CardText.name(card({ questID = 176 }), { C_QuestLog = 5 }))
    end)

    it("shows a generated NPC card's French name in a French client", function()
      _G.GetLocale = function() return "frFR" end
      local fr = mocks.newNamespace()
      mocks.loadLocales(fr)
      mocks.loadSource("Utils/Wow.lua", fr)
      mocks.loadSource("Modules/Cards.lua", fr)
      mocks.loadSource("Modules/CardText.lua", fr)
      mocks.loadAllData(fr)
      local kam = fr.Cards.get("1429:npc_1666")
      assert.equals(1666, kam.npcID)
      assert.equals("Kam Furie-du-fond", fr.CardText.name(kam, {}))
      -- A generated quest card falls back to its French title while the
      -- client has not cached the quest.
      local quest
      for _, c in ipairs(fr.Cards.zoneCards(1429)) do
        if c.questID and rawget(fr.L, c.name) then quest = c break end
      end
      assert.equals(rawget(fr.L, quest.name), fr.CardText.name(quest, { C_QuestLog = {
        GetTitleForQuestID = function() return nil end,
      } }))
      -- An English client keeps the English name.
      _G.GetLocale = function() return "enUS" end
      local en = mocks.newNamespace()
      mocks.loadLocales(en)
      mocks.loadSource("Utils/Wow.lua", en)
      mocks.loadSource("Modules/Cards.lua", en)
      mocks.loadSource("Modules/CardText.lua", en)
      mocks.loadAllData(en)
      assert.equals("Kam Deepfury", en.CardText.name(en.Cards.get("1429:npc_1666"), {}))
    end)

    it("escapes chat codes in a client name", function()
      local env = { C_Map = { GetAreaInfo = function() return "Evil|cffff0000Red|r" end } }
      assert.equals("Evil||cffff0000Red||r", CardText.name(card({ areaID = 87 }), env))
    end)

    it("escapes every escape code shape", function()
      local cases = {
        ["A|TInterface\\Icons\\X:0|tB"] = "A||TInterface\\Icons\\X:0||tB",
        ["|Hitem:1|h[x]|h"] = "||Hitem:1||h[x]||h",
        ["a|nb"] = "a||nb",
        ["abc|"] = "abc||",
        ["a||b"] = "a||||b",
      }
      for input, expected in pairs(cases) do
        local env = { C_Map = { GetAreaInfo = function() return input end } }
        assert.equals(expected, CardText.name(card({ areaID = 87 }), env))
      end
    end)

    it("falls back on blank, control, malformed UTF-8, invisible or bidi names", function()
      for _, bad in ipairs({
        " ", "   ", "a\0b", "a\rb", "a\tb", "a\127b",
        "\240ab|cffff0000X", "abc\226", "\192\175", "a\226\128\174b", "a\194\133b", "a\194\160b",
      }) do
        local env = { C_Map = { GetAreaInfo = function() return bad end } }
        assert.equals("Linen Cloth (data)", CardText.name(card({ areaID = 87 }), env))
      end
    end)

    it("accepts accented and CJK names and the 64-byte boundary", function()
      for _, good in ipairs({ "Étoffe de lin", "亚麻布", string.rep("a", 64), string.rep("é", 32) }) do
        local env = { C_Map = { GetAreaInfo = function() return good end } }
        assert.equals(good, CardText.name(card({ areaID = 87 }), env))
      end
      local env = { C_Map = { GetAreaInfo = function() return string.rep("é", 33) end } }
      assert.equals("Linen Cloth (data)", CardText.name(card({ areaID = 87 }), env))
    end)

    it("checks secrets before any other check, even for a string secret", function()
      _G.issecretvalue = function(v) return v == "SECRET" end
      local env = { C_QuestLog = { GetTitleForQuestID = function() return "SECRET" end } }
      assert.equals("Linen Cloth (data)", CardText.name(card({ questID = 176 }), env))
    end)

    it("falls back when the quest or area API throws or returns a secret", function()
      local secret = mocks.newSecret()
      mocks.installSecrets({ secret })
      for _, fn in ipairs({ function() error("x") end, function() return secret end }) do
        assert.equals("Linen Cloth (data)", CardText.name(card({ questID = 176 }), { C_QuestLog = { GetTitleForQuestID = fn } }))
        assert.equals("Linen Cloth (data)", CardText.name(card({ areaID = 87 }), { C_Map = { GetAreaInfo = fn } }))
      end
    end)

    it("requests an uncached item only once per session, and survives a throwing request", function()
      local requests = 0
      local env = { C_Item = {
        GetItemNameByID = function() return nil end,
        RequestLoadItemDataByID = function() requests = requests + 1 end,
      } }
      CardText.name(card({ itemID = 4242 }), env)
      CardText.name(card({ itemID = 4242 }), env)
      assert.equals(1, requests)
      env.C_Item.RequestLoadItemDataByID = function() error("x") end
      assert.equals("Linen Cloth (data)", CardText.name(card({ itemID = 4343 }), env))
    end)
  end)

  describe("flavor", function()
    it("uses the card's own flavor when it has one", function()
      ns.L["Hand-written."] = "Écrit à la main."
      assert.equals("Écrit à la main.", CardText.flavor(card({ flavor = "Hand-written." })))
    end)

    it("falls back to the English flavor when the translation is not clean text", function()
      for _, bad in ipairs({
        "Valid\ntext",
        "Valid \226\128\174text", "Valid\194\160text", string.rep("a", 201), "   ", "",
      }) do
        ns.L["Hand-written."] = bad
        assert.equals("Hand-written.", CardText.flavor(card({ flavor = "Hand-written." })), bad)
      end
    end)

    it("doubles every | of a translation so color codes and links show as plain text", function()
      ns.L["Hand-written."] = "Valid text|cff00ff00x"
      assert.equals("Valid text||cff00ff00x", CardText.flavor(card({ flavor = "Hand-written." })))
      ns.L["Hand-written."] = "|Hitem:1|h[x]|hValid text"
      assert.equals("||Hitem:1||h[x]||hValid text", CardText.flavor(card({ flavor = "Hand-written." })))
    end)

    it("shows a markup-looking translation as plain text, never as an escape code", function()
      ns.L["Hand-written."] = "<script>alert(1)</script>"
      assert.equals("<script>alert(1)</script>", CardText.flavor(card({ flavor = "Hand-written." })))
      ns.L["Hand-written."] = string.rep("a", 200)
      assert.equals(string.rep("a", 200), CardText.flavor(card({ flavor = "Hand-written." })))
    end)

    it("translates every creature type into French", function()
      _G.GetLocale = function() return "frFR" end
      local fr = mocks.newNamespace()
      mocks.loadLocales(fr)
      for creatureType in pairs(ns.Cards.CREATURE_TYPES) do
        assert.is_string(rawget(fr.L, creatureType), creatureType)
      end
      assert.equals("Niveau", rawget(fr.L, "Level"))
    end)

    it("builds one from level and creature type", function()
      assert.equals("Level 5 · Beast", CardText.flavor(card({ level = 5, creatureType = "Beast" })))
      assert.equals("Level 12", CardText.flavor(card({ level = 12 })))
      assert.equals("", CardText.flavor(card()))
    end)
  end)

  describe("onItemDataLoaded", function()
    local function request(itemID)
      CardText.name(card({ itemID = itemID }), { C_Item = {
        GetItemNameByID = function() return nil end,
        RequestLoadItemDataByID = function() end,
      } })
    end

    it("ignores items this addon never requested, and failed loads", function()
      local refreshes = 0
      local refresh = function() refreshes = refreshes + 1 end
      assert.is_false(CardText.onItemDataLoaded(9999, true, nil, refresh))
      request(2589)
      assert.is_false(CardText.onItemDataLoaded(2589, false, nil, refresh))
      assert.equals(0, refreshes)
      assert.is_true(CardText.onItemDataLoaded(2589, true, nil, refresh))
      assert.equals(1, refreshes)
    end)

    it("ignores secret event arguments and recovers from a failing timer", function()
      request(2589)
      local refreshes = 0
      local refresh = function() refreshes = refreshes + 1 end
      _G.issecretvalue = function(v) return v == 2589 end
      assert.is_false(CardText.onItemDataLoaded(2589, true, nil, refresh))
      _G.issecretvalue = function(v) return v == true end -- secret success flag
      assert.is_false(CardText.onItemDataLoaded(2589, true, nil, refresh))
      assert.equals(0, refreshes)
      _G.issecretvalue = nil
      assert.is_false(CardText.onItemDataLoaded(2589, true, function() error("timer") end, refresh))
      assert.is_true(CardText.onItemDataLoaded(2589, true, nil, refresh))
      assert.equals(1, refreshes)
    end)

    it("merges a burst of loads into one refresh on the next frame", function()
      request(2589)
      request(2590)
      local scheduled, refreshes = {}, 0
      local after = function(_, fn) scheduled[#scheduled + 1] = fn end
      local refresh = function() refreshes = refreshes + 1 end
      CardText.onItemDataLoaded(2589, true, after, refresh)
      CardText.onItemDataLoaded(2590, true, after, refresh)
      CardText.onItemDataLoaded(2589, true, after, refresh)
      assert.equals(1, #scheduled)
      scheduled[1]()
      assert.equals(1, refreshes)
      CardText.onItemDataLoaded(2590, true, after, refresh)
      assert.equals(2, #scheduled)
    end)
  end)

  describe("isCleanText", function()
    it("refuses UTF-8 that only looks valid once a sequence is removed, overlongs, surrogates and > U+10FFFF", function()
      for _, bad in ipairs({
        "\194\228\184\173\128", "a\226\240\144\128\128\128\128b",
        "\224\128\160", "\237\160\128", "\244\144\128\128",
        "a\194\173b", "a\227\133\164b", "a\239\184\143b", "a\243\160\128\129b", "a\225\160\142b",
      }) do
        assert.is_false(ns.Utils.isCleanText(bad))
      end
    end)

    it("refuses blank-looking and invisible characters outside the format blocks", function()
      for _, bad in ipairs({
        "Lar\205\143deur",           -- U+034F
        "\226\160\128",              -- U+2800 alone
        "Lar\225\133\159deur", "Lar\225\133\160deur", "Lar\239\190\160deur", -- Hangul fillers
        "Lar\225\158\180deur", "Lar\225\158\181deur", -- U+17B4-17B5
        "Lar\225\160\139deur", "Lar\225\160\141deur", -- U+180B, U+180D
        "Lar\243\160\132\128deur", "Lar\243\160\135\175deur", -- U+E0100, U+E01EF
        "Lar\216\156deur",           -- U+061C
        "Lar\225\160\143deur",       -- U+180F
        "Lar\240\155\178\160deur", "Lar\240\155\178\163deur", -- U+1BCA0, U+1BCA3
        "Lar\240\157\133\179deur", "Lar\240\157\133\186deur", -- U+1D173, U+1D17A
      }) do
        assert.is_false(ns.Utils.isCleanText(bad), bad)
      end
    end)

    it("still accepts the letters next to those ranges", function()
      -- U+034E, U+1161 (Hangul vowel), U+2801 (braille dot), Korean syllable,
      -- U+180A, U+17B3, U+17B6, U+FFA1, U+E00FF, U+061B, U+1BC9F, U+1D172,
      -- U+1D17B, Cyrillic Ж.
      for _, good in ipairs({
        "a\205\142b", "\225\133\161", "\226\160\129", "\234\176\128",
        "\225\160\138", "\225\158\179", "\225\158\182", "\239\190\161", "\243\160\131\191", "\216\155",
        "\240\155\178\159", "\240\157\133\178", "\240\157\133\187", "\208\150",
      }) do
        assert.is_true(ns.Utils.isCleanText(good), good)
      end
    end)

    it("accepts accented, CJK and emoji-plane text", function()
      for _, good in ipairs({ "Étoffe de lin", "亚麻布", "Mère Croc", "a\240\159\144\186b" }) do
        assert.is_true(ns.Utils.isCleanText(good), good)
      end
    end)
  end)

  describe("modelNpcID", function()
    local on = { CARD_MODELS = true }

    it("gives the npcID of every creature-like kind", function()
      for _, kind in ipairs({ "creature", "rare", "elite", "boss", "npc" }) do
        assert.equals(299, CardText.modelNpcID(card({ kind = kind, npcID = 299 }), on), kind)
      end
    end)

    it("keeps the icon for places, quests, items, lore and unknown kinds", function()
      for _, kind in ipairs({ "place", "quest", "item", "lore", "dragon", nil }) do
        assert.is_nil(CardText.modelNpcID(card({ kind = kind, npcID = 299 }), on), tostring(kind))
      end
    end)

    it("keeps the icon without a valid npcID", function()
      for _, bad in ipairs({ false, 0, -1, 1.5, 0 / 0, math.huge, 2 ^ 31, "299", "<script>", {} }) do
        assert.is_nil(CardText.modelNpcID(card({ kind = "creature", npcID = bad }), on), tostring(bad))
      end
      assert.is_nil(CardText.modelNpcID(card({ kind = "creature" }), on))
    end)

    it("keeps the icon when models are switched off", function()
      assert.is_nil(CardText.modelNpcID(card({ kind = "creature", npcID = 299 }), { CARD_MODELS = false }))
    end)
  end)

  describe("modelNpcID", function()
    local on = { CARD_MODELS = true }

    it("gives the npcID of every creature-like kind", function()
      for _, kind in ipairs({ "creature", "rare", "elite", "boss", "npc" }) do
        assert.equals(299, CardText.modelNpcID(card({ kind = kind, npcID = 299 }), on), kind)
      end
    end)

    it("keeps the icon for places, quests, items, lore and unknown kinds", function()
      for _, kind in ipairs({ "place", "quest", "item", "lore", "dragon" }) do
        assert.is_nil(CardText.modelNpcID(card({ kind = kind, npcID = 299 }), on), kind)
      end
      assert.is_nil(CardText.modelNpcID(card({ npcID = 299 }), on))
    end)

    it("keeps the icon without a valid npcID", function()
      for _, bad in ipairs({ false, 0, -1, 1.5, 0 / 0, math.huge, 2 ^ 31, "299", "<script>", {} }) do
        assert.is_nil(CardText.modelNpcID(card({ kind = "creature", npcID = bad }), on), tostring(bad))
      end
      assert.is_nil(CardText.modelNpcID(card({ kind = "creature" }), on))
    end)

    it("keeps the icon when models are switched off", function()
      assert.is_nil(CardText.modelNpcID(card({ kind = "creature", npcID = 299 }), { CARD_MODELS = false }))
    end)
  end)

  describe("icon", function()
    it("uses the client's item icon file ID", function()
      local env = { C_Item = { GetItemIconByID = function() return 132889 end } }
      assert.equals(132889, CardText.icon(card({ itemID = 2589 }), env))
    end)

    it("falls back to the data icon on a missing, throwing, secret or invalid file ID", function()
      _G.issecretvalue = function(v) return v == 777 end
      for _, getIcon in ipairs({
        function() error("x") end, function() return nil end, function() return 777 end,
        function() return 0 end, function() return -5 end, function() return 1.5 end,
        function() return 0 / 0 end, function() return math.huge end, function() return 2 ^ 31 end,
        function() return "Interface\\Icons\\X" end,
      }) do
        local env = { C_Item = { GetItemIconByID = getIcon } }
        assert.equals("Interface\\Icons\\INV_Misc_Bag_08", CardText.icon(card({ itemID = 2589 }), env))
      end
    end)

    it("uses the data icon for a card without an itemID", function()
      assert.equals("Interface\\Icons\\INV_Misc_Bag_08", CardText.icon(card({ questID = 176 }), {}))
    end)
  end)
end)
