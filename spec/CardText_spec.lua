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

    it("accepts accented, CJK and emoji-plane text", function()
      for _, good in ipairs({ "Étoffe de lin", "亚麻布", "Mère Croc", "a\240\159\144\186b" }) do
        assert.is_true(ns.Utils.isCleanText(good), good)
      end
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
