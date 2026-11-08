local mocks = require("wow_mocks")

-- Smoke tests for the frames with a permissive CreateFrame stub: every method
-- exists and records what matters. They catch nil references and logic errors
-- in the UI code, not wrong WoW API names (that needs the game).

local function stubObject()
  local obj = { scripts = {}, shown = false }
  return setmetatable(obj, { __index = function(_, key)
    if key == "SetScript" then return function(self, name, fn) self.scripts[name] = fn end end
    if key == "Show" then return function(self) self.shown = true end end
    if key == "Hide" then return function(self) self.shown = false end end
    if key == "IsShown" or key == "IsVisible" then return function(self) return self.shown end end
    if key == "SetShown" then return function(self, v) self.shown = v and true or false end end
    if key == "SetText" then return function(self, v) self.text = v end end
    if key == "SetPoint" then return function(self, ...) self.point = { ... } end end
    if key == "SetTexture" then return function(self, v) self.texture = v; self.textureCalls = (rawget(self, "textureCalls") or 0) + 1 end end
    if key == "GetText" then return function(self) return self.text or "" end end
    if key == "SetEnabled" then return function(self, v) self.enabled = v end end
    if key:match("^Create") then return function() return stubObject() end end
    return function() end
  end })
end

describe("UI frames", function()
  local ns, char

  before_each(function()
    mocks.reset()
    ns = mocks.newNamespace()
    _G.CreateFrame = function() return stubObject() end
    _G.UIParent = stubObject()
    _G.UISpecialFrames = {}
    _G.tinsert = table.insert
    _G.C_Map = { GetMapInfo = function(id) return { name = "Zone "..id, mapType = 3, parentMapID = 1415 } end }
    for _, file in ipairs({
      "Utils/Wow.lua", "Modules/Config.lua", "Modules/Zone.lua", "Modules/StepTracker.lua", "Modules/Packs.lua",
      "Modules/Cards.lua", "Modules/Collection.lua", "Modules/Tags.lua", "Modules/Reveal.lua", "Modules/BinderModel.lua",
      "Modules/Slash.lua", "Modules/Sound.lua", "Modules/Walker.lua", "Modules/UI/Draw.lua", "Modules/UI/Window.lua", "Modules/UI/CardWidget.lua", "Modules/UI/CardDetail.lua",
      "Modules/UI/RevealFrame.lua", "Modules/UI/BinderFrame.lua", "Modules/Opener.lua",
      "Data/EasternKingdoms/ElwynnForest.lua", "Data/EasternKingdoms/Westfall.lua",
    }) do
      mocks.loadSource(file, ns)
    end
    char = {
      stats = { yards = 0 }, progress = { total = 0, byZone = {} }, packs = {},
      collection = {}, newCards = {}, tags = {}, pinned = {},
    }
    ns.GetDB = function() return { char = char, global = { settings = { sound = true } } } end
  end)

  after_each(function()
    _G.CreateFrame, _G.UIParent, _G.UISpecialFrames, _G.tinsert, _G.C_Map = nil, nil, nil, nil, nil
  end)

  describe("reveal", function()
    local function open()
      local result = ns.Collection.openNext(char, function() return 1 end, function() return nil end, ns.Config)
      ns.RevealFrame.show(result, "Zone 1429", function() end, function() return #char.packs end)
      return result
    end

    it("shows the cards face down, then flips one on click", function()
      char.packs = { { zoneMapID = 1429, earnedAt = 1 } }
      open()
      local frame, widgets = ns.RevealFrame._debug()
      assert.is_true(frame.shown)
      assert.equals("?", widgets[1].back.text)
      widgets[2].scripts.OnClick()
      assert.equals("Young Wolf", widgets[2].name.text)
      assert.equals("?", widgets[1].back.text)
    end)

    it("reveals all and offers the next pack only when one is left", function()
      char.packs = { { zoneMapID = 1429, earnedAt = 1 }, { zoneMapID = 1436, earnedAt = 2 } }
      open()
      local frame = ns.RevealFrame._debug()
      assert.is_true(frame.revealAll.shown)
      assert.is_false(frame.openNext.shown)
      frame.revealAll.scripts.OnClick()
      assert.is_false(frame.revealAll.shown)
      assert.is_true(frame.openNext.shown)
    end)

    it("shows the card art, and a halo only on Epic and Legendary cards", function()
      char.packs = { { zoneMapID = 1429, earnedAt = 1 } }
      local result = ns.Collection.openNext(char, function(n) return n end, function() return nil end, ns.Config)
      ns.RevealFrame.show(result, "Zone 1429", function() end, function() return 0 end)
      local frame, widgets = ns.RevealFrame._debug()
      frame.revealAll.scripts.OnClick()
      assert.equals("Hogger", widgets[1].name.text)
      assert.is_true(widgets[1].halo.shown)

      char.packs = { { zoneMapID = 1429, earnedAt = 2 } }
      open()
      frame.revealAll.scripts.OnClick()
      assert.equals("Young Wolf", widgets[1].name.text)
      assert.is_false(widgets[1].halo.shown)
    end)

    it("hides art and halo on a face-down Legendary card, and finishes on Reveal all", function()
      char.packs = { { zoneMapID = 1429, earnedAt = 1 } }
      local result = ns.Collection.openNext(char, function(n) return n end, function() return nil end, ns.Config)
      ns.RevealFrame.show(result, "Zone 1429", function() end, function() return 0 end)
      local frame, widgets, state = ns.RevealFrame._debug()
      assert.is_false(widgets[1].icon.shown)
      assert.is_false(widgets[1].halo.shown)
      assert.is_false(widgets[1].name.shown)
      frame.revealAll.scripts.OnClick()
      assert.is_true(ns.Reveal.isDone(state))
      assert.equals("Interface\\Icons\\INV_Misc_Head_Gnoll_01", widgets[1].icon.texture)
      assert.is_true(widgets[1].halo.shown)

      -- Next pack reuses the widget: the Legendary face must not stay visible.
      char.packs = { { zoneMapID = 1429, earnedAt = 2 } }
      result = ns.Collection.openNext(char, function() return 1 end, function() return nil end, ns.Config)
      ns.RevealFrame.show(result, "Zone 1429", function() end, function() return 0 end)
      assert.is_false(widgets[1].halo.shown)
      assert.is_false(widgets[1].icon.shown)
      assert.is_false(widgets[1].name.shown)
      assert.equals("?", widgets[1].back.text)
    end)

    it("opens the detail window on a second click, not before the flip", function()
      char.packs = { { zoneMapID = 1429, earnedAt = 1 } }
      local result = ns.Collection.openNext(char, function() return 1 end, function() return nil end, ns.Config)
      ns.RevealFrame.show(result, "Zone 1429", function() end, function() return 0 end,
        function(id) return char.collection[id] end)
      local _, widgets = ns.RevealFrame._debug()
      widgets[1].scripts.OnClick()
      assert.is_nil(ns.CardDetail._debug())
      widgets[1].scripts.OnClick()
      local detail, big, flavor, owned = ns.CardDetail._debug()
      assert.is_true(detail.shown)
      assert.equals("Young Wolf", detail.title.text)
      assert.equals("Young Wolf", big.name.text)
      assert.equals("Its howl is more of a squeak, but the pack still listens.", flavor.text)
      assert.equals("Copies owned: 4", owned.text)
    end)

    it("flips a face-down card without opening the detail, even once the window exists", function()
      char.packs = { { zoneMapID = 1429, earnedAt = 1 } }
      local result = ns.Collection.openNext(char, function() return 1 end, function() return nil end, ns.Config)
      ns.RevealFrame.show(result, "Zone 1429", function() end, function() return 0 end)
      local _, widgets, state = ns.RevealFrame._debug()
      widgets[1].scripts.OnClick()
      widgets[1].scripts.OnClick()
      local detail, _, _, owned = ns.CardDetail._debug()
      assert.is_false(owned.shown) -- no copiesOf given: no count line
      ns.CardDetail.hide()
      widgets[2].scripts.OnClick()
      assert.is_true(state.revealed[2])
      assert.is_false(detail.shown)
    end)

    it("plays no new-card sound: a pack of new cards revealed all at once plays one flip", function()
      local played = {}
      _G.SOUNDKIT = { LOOT_WINDOW_COIN_SOUND = 9, UI_BONUS_LOOT_ROLL_END = 8, IG_ABILITY_PAGE_TURN = 2 }
      _G.PlaySound = function(kit) played[#played + 1] = kit end
      char.packs = { { zoneMapID = 1429, earnedAt = 1 } }
      local result = open()
      assert.is_true(result.firstTime[result.cardIDs[1]])
      local frame = ns.RevealFrame._debug()
      frame.revealAll.scripts.OnClick()
      _G.SOUNDKIT, _G.PlaySound = nil, nil
      assert.same({ 2 }, played)
    end)

    it("plays the flip, not a new-card sound, when clicking a card owned for the first time", function()
      local played = {}
      _G.SOUNDKIT = { LOOT_WINDOW_COIN_SOUND = 9, UI_BONUS_LOOT_ROLL_END = 8, IG_ABILITY_PAGE_TURN = 2 }
      _G.PlaySound = function(kit) played[#played + 1] = kit end
      char.packs = { { zoneMapID = 1429, earnedAt = 1 } }
      open()
      local _, widgets = ns.RevealFrame._debug()
      widgets[1].scripts.OnClick()
      _G.SOUNDKIT, _G.PlaySound = nil, nil
      assert.same({ 2 }, played)
    end)

    it("marks first-time cards as New on the face", function()
      char.packs = { { zoneMapID = 1429, earnedAt = 1 } }
      open()
      local frame, widgets = ns.RevealFrame._debug()
      frame.revealAll.scripts.OnClick()
      assert.equals("New!", widgets[1].newTag.text)
    end)

    it("goes through /wd open and falls back to chat if the frame errors", function()
      char.packs = { { zoneMapID = 1429, earnedAt = 1 } }
      local printed = {}
      local originalPrint = _G.print
      _G.print = function(msg) printed[#printed + 1] = tostring(msg) end
      ns.RevealFrame.show = function() error("frame broke") end
      ns.Slash.dispatch("open")
      _G.print = originalPrint
      assert.equals(0, #char.packs)
      assert.equals(5, #printed)
    end)
  end)

  describe("failures", function()
    local printed, originalPrint

    before_each(function()
      printed = {}
      originalPrint = _G.print
      _G.print = function(msg) printed[#printed + 1] = tostring(msg) end
    end)

    after_each(function()
      _G.print = originalPrint
    end)

    it("prints the cards to chat when the RevealFrame module is missing", function()
      char.packs = { { zoneMapID = 1429, earnedAt = 1 } }
      ns.RevealFrame = nil
      ns.Slash.dispatch("open")
      assert.equals(0, #char.packs)
      assert.equals(5, #printed)
    end)

    it("falls back to chat on every open after the reveal frame fails to build", function()
      char.packs = { { zoneMapID = 1429, earnedAt = 1 }, { zoneMapID = 1436, earnedAt = 2 } }
      ns.CardWidget.create = function() error("no template") end
      ns.Slash.dispatch("open")
      ns.Slash.dispatch("open")
      assert.equals(0, #char.packs)
      assert.equals(10, #printed)
    end)

    it("hands a caught error to the client error handler", function()
      local caught
      _G.geterrorhandler = function() return function(err) caught = err end end
      ns.RevealFrame = nil
      char.packs = { { zoneMapID = 1429, earnedAt = 1 } }
      ns.Slash.dispatch("open")
      _G.geterrorhandler = nil
      assert.truthy(caught)
    end)

    it("reports the binder failure when the BinderFrame module is missing", function()
      local said = {}
      ns.print = function(msg) said[#said + 1] = msg end
      ns.BinderFrame = nil
      ns.Slash.dispatch("binder")
      assert.equals("The binder could not open. Use /wd cards.", said[1])
    end)

    it("hides the binder and keeps New flags when drawing fails after a good build", function()
      char.collection = { ["1429:young_wolf"] = 1 }
      char.newCards = { ["1429:young_wolf"] = true }
      local said = {}
      ns.print = function(msg) said[#said + 1] = msg end
      ns.CardWidget.showCard = function() error("draw failed") end
      ns.Slash.dispatch("binder")
      local frame = ns.BinderFrame._debug()
      assert.is_false(frame.shown)
      assert.same({ ["1429:young_wolf"] = true }, char.newCards)
      assert.equals(1, #said)
    end)

    it("hides the reveal frame and prints the new pack when drawing fails after a shown pack", function()
      char.packs = { { zoneMapID = 1429, earnedAt = 1 }, { zoneMapID = 1436, earnedAt = 2 } }
      ns.Slash.dispatch("open")
      local frame = ns.RevealFrame._debug()
      assert.is_true(frame.shown)
      ns.CardWidget.showBack = function() error("draw failed") end
      ns.Slash.dispatch("open")
      assert.is_false(frame.shown)
      assert.equals(0, #char.packs)
      assert.equals(5, #printed)
    end)

    it("keeps New flags when the binder fails to build after its card widgets", function()
      char.collection = { ["1429:young_wolf"] = 1 }
      char.newCards = { ["1429:young_wolf"] = true }
      local said = {}
      ns.print = function(msg) said[#said + 1] = msg end
      local button = ns.Window.button
      ns.Window.button = function(parent, label, width)
        if label == "<" then error("no template") end
        return button(parent, label, width)
      end
      ns.Slash.dispatch("binder")
      ns.Slash.dispatch("binder")
      assert.same({ ["1429:young_wolf"] = true }, char.newCards)
      assert.equals(2, #said)
      local frame = ns.BinderFrame._debug()
      assert.is_false(frame.shown)
    end)
  end)

  describe("binder", function()
    it("does not show a missing card's name in a slot that held an owned card", function()
      char.collection = { ["1429:young_wolf"] = 1 }
      ns.BinderFrame.toggle()
      local frame, widgets = ns.BinderFrame._debug()
      assert.equals("Young Wolf", widgets[1].name.text)
      -- Missing filter: the first slot now holds a missing card.
      local _, _, _, view = ns.BinderFrame._debug()
      view.filter = "missing"
      frame.search.scripts.OnTextChanged(frame.search) -- re-render
      assert.is_false(widgets[1].name.shown)
      assert.equals("?", widgets[1].back.text)
    end)

    it("hides a Legendary card's art, name and halo when its slot turns into a missing card", function()
      char.collection = { ["1429:hogger"] = 1 }
      ns.BinderFrame.toggle()
      local frame, widgets, _, view = ns.BinderFrame._debug()
      view.rarity = 5
      frame.search.scripts.OnTextChanged(frame.search)
      assert.equals("Hogger", widgets[1].name.text)
      assert.is_true(widgets[1].halo.shown)
      local calls = widgets[1].icon.textureCalls

      view.rarity, view.filter = nil, "missing"
      frame.search.scripts.OnTextChanged(frame.search)
      assert.is_false(widgets[1].icon.shown)
      assert.is_false(widgets[1].name.shown)
      assert.is_false(widgets[1].halo.shown)
      assert.equals(calls, widgets[1].icon.textureCalls)
    end)

    it("opens the detail of an owned card on click, and nothing for a missing card", function()
      char.collection = { ["1429:young_wolf"] = 3 }
      ns.BinderFrame.toggle()
      local _, widgets = ns.BinderFrame._debug()
      widgets[2].scripts.OnClick(widgets[2]) -- missing Stonetusk Boar
      assert.is_nil(ns.CardDetail._debug())
      widgets[1].scripts.OnClick(widgets[1])
      local detail, _, flavor, owned = ns.CardDetail._debug()
      assert.is_true(detail.shown)
      assert.equals("Young Wolf", detail.title.text)
      assert.equals("Its howl is more of a squeak, but the pack still listens.", flavor.text)
      assert.equals("Copies owned: 3", owned.text)
    end)

    it("does not open a missing or empty slot once the detail window exists", function()
      char.collection = { ["1429:young_wolf"] = 1 }
      ns.BinderFrame.toggle()
      local frame, widgets, _, view = ns.BinderFrame._debug()
      widgets[1].scripts.OnClick(widgets[1])
      local detail = ns.CardDetail._debug()
      ns.CardDetail.hide()

      view.filter = "missing" -- slot 1 now holds a missing card
      frame.search.scripts.OnTextChanged(frame.search)
      widgets[1].scripts.OnClick(widgets[1])
      assert.is_false(detail.shown)
      assert.equals("Young Wolf", detail.title.text)

      view.filter = "duplicates" -- no duplicates: every slot is empty
      frame.search.scripts.OnTextChanged(frame.search)
      widgets[1].scripts.OnClick(widgets[1])
      assert.is_false(detail.shown)
    end)

    it("shows the copies line only for a whole positive count", function()
      local hogger = ns.Cards.get("1429:hogger")
      for _, bad in ipairs({ 0, -1, 1.5, 0 / 0, math.huge, "3|cffff0000x|r" }) do
        ns.CardDetail.show(hogger, 2) -- a visible line first: a bad value must hide it
        ns.CardDetail.show(hogger, bad)
        local _, _, _, owned = ns.CardDetail._debug()
        assert.is_false(owned.shown, tostring(bad))
      end
      ns.CardDetail.show(hogger, nil)
      assert.is_false(select(4, ns.CardDetail._debug()).shown)
      ns.CardDetail.show(hogger, 2)
      assert.equals("Copies owned: 2", select(4, ns.CardDetail._debug()).text)
    end)

    describe("tags and pins", function()
      local function openDetail()
        char.collection = { ["1429:young_wolf"] = 1, ["1429:stonetusk_boar"] = 1 }
        ns.BinderFrame.toggle()
        local frame, widgets, _, view = ns.BinderFrame._debug()
        widgets[2].scripts.OnClick(widgets[2]) -- Stonetusk Boar
        local _, _, _, _, controls = ns.CardDetail._debug()
        return frame, widgets, view, controls
      end

      it("pins a card from the detail window and shows it first with a Pinned label", function()
        local _, widgets, _, controls = openDetail()
        assert.equals("Pin", controls.pin.text)
        controls.pin.scripts.OnClick()
        assert.same({ ["1429:stonetusk_boar"] = true }, char.pinned)
        assert.equals("Unpin", controls.pin.text)
        assert.equals("Stonetusk Boar", widgets[1].name.text)
        assert.equals("Pinned", widgets[1].pinTag.text)
        assert.is_true(widgets[1].pinTag.shown)
        assert.is_false(widgets[2].pinTag.shown)
      end)

      it("adds a typed tag, refuses a bad one, and removes it with its chip", function()
        local _, _, _, controls = openDetail()
        controls.input.text = "  Deck FEU "
        controls.input.scripts.OnEnterPressed(controls.input)
        assert.same({ ["1429:stonetusk_boar"] = { ["deck feu"] = true } }, char.tags)
        assert.equals("deck feu  x", controls.chips[1].text)
        assert.equals("", controls.input.text)

        local said = {}
        ns.print = function(msg) said[#said + 1] = msg end
        controls.input.text = "|cffff0000x"
        controls.input.scripts.OnEnterPressed(controls.input)
        assert.equals(1, #said)
        assert.same({ ["1429:stonetusk_boar"] = { ["deck feu"] = true } }, char.tags)

        controls.chips[1].scripts.OnClick(controls.chips[1])
        assert.same({}, char.tags)
        assert.is_false(controls.chips[1].shown)
      end)

      it("refuses #trade typed in the tag box", function()
        local _, _, _, controls = openDetail()
        local said = {}
        ns.print = function(msg) said[#said + 1] = msg end
        controls.input.text = "#trade"
        controls.input.scripts.OnEnterPressed(controls.input)
        assert.same({}, char.tags)
        assert.equals(1, #said)
      end)

      it("marks a card For trade and filters the binder by that tag", function()
        local frame, widgets, view, controls = openDetail()
        controls.trade.scripts.OnClick()
        assert.equals("Not for trade", controls.trade.text)
        frame.tag.scripts.OnClick()
        assert.equals(ns.Tags.TRADE, view.tag)
        assert.equals("For trade", frame.tag.text)
        assert.equals("Stonetusk Boar", widgets[1].name.text)
        assert.is_false(widgets[2].shown)
      end)

      it("hides the tag controls for a card that is not owned", function()
        ns.CardDetail.show(ns.Cards.get("1429:hogger"), nil)
        local _, _, _, _, controls = ns.CardDetail._debug()
        assert.is_false(controls.pin.shown)
        assert.is_false(controls.input.shown)
      end)

      it("shows a player tag with pipes escaped on the filter button", function()
        char.collection = { ["1429:young_wolf"] = 1 }
        char.tags = { ["1429:young_wolf"] = { ["a|b"] = true } } -- slipped past the sanitizer
        ns.BinderFrame.toggle()
        local frame = ns.BinderFrame._debug()
        frame.tag.scripts.OnClick() -- For trade
        frame.tag.scripts.OnClick() -- a|b
        assert.equals("a||b", frame.tag.text)
      end)
    end)

    it("keeps the pager below the last card row", function()
      ns.BinderFrame.toggle()
      local frame, widgets = ns.BinderFrame._debug()
      local lastRowTop = -widgets[9].point[3] -- TOPLEFT x, y
      local lastRowBottom = lastRowTop + ns.CardWidget.HEIGHT
      local pagerTop = -frame.prev.point[3]
      assert.is_true(pagerTop >= lastRowBottom + 12, "pager overlaps the cards")
    end)

    it("escapes hostile zone names on the buttons and the reveal subtitle", function()
      _G.C_Map = { GetMapInfo = function() return { name = "|cffff0000Evil|r |TInterface\\x:0|t\nnext" } end }
      ns.BinderFrame.toggle()
      local _, _, zoneButtons = ns.BinderFrame._debug()
      assert.truthy(zoneButtons[1].text:find("||cffff0000Evil||r ||TInterface\\x:0||t next", 1, true))
      assert.is_nil(zoneButtons[1].text:find("\n", 1, true))

      char.packs = { { zoneMapID = 1429, earnedAt = 1 } }
      ns.Slash.dispatch("open")
      local reveal = ns.RevealFrame._debug()
      assert.truthy(reveal.subtitle.text:find("||cffff0000Evil||r", 1, true))
    end)

    it("never displays the search text", function()
      char.collection = { ["1429:young_wolf"] = 1 }
      ns.BinderFrame.toggle()
      local frame, widgets, zoneButtons = ns.BinderFrame._debug()
      frame.search.text = "wolf<script>alert(1)</script>|Hitem:1|h[x]|h"
      frame.search.scripts.OnTextChanged(frame.search)
      for _, w in ipairs(widgets) do
        for _, fs in ipairs({ w.name, w.kind, w.rarityLabel, w.attack, w.defense, w.newTag, w.copies, w.back, w.backLabel }) do
          assert.is_nil(tostring(fs.text):find("script", 1, true))
        end
      end
      for _, b in ipairs(zoneButtons) do assert.is_nil(tostring(b.text):find("script", 1, true)) end
      assert.is_false(widgets[1].shown)
    end)

    it("shows owned cards face up, missing ones as silhouettes, and clears New", function()
      char.collection = { ["1429:young_wolf"] = 2 }
      char.newCards = { ["1429:young_wolf"] = true }
      ns.BinderFrame.toggle()
      local frame, widgets, zoneButtons, view = ns.BinderFrame._debug()
      assert.is_true(frame.shown)
      assert.equals(1429, view.zoneMapID)
      assert.equals("Young Wolf", widgets[1].name.text)
      assert.equals("x2", widgets[1].copies.text)
      assert.equals("New!", widgets[1].newTag.text)
      assert.equals("?", widgets[2].back.text)
      assert.same({}, char.newCards)
      assert.equals("Zone 1429  1/16", zoneButtons[1].text)
    end)

    it("switches zone, filters, pages and searches without errors", function()
      char.collection = { ["1436:moonbrook"] = 1 }
      ns.BinderFrame.toggle()
      local frame, widgets, zoneButtons, view = ns.BinderFrame._debug()
      zoneButtons[2].scripts.OnClick(zoneButtons[2])
      assert.equals(1436, view.zoneMapID)
      frame.next.scripts.OnClick()
      assert.equals(2, view.page)
      frame.rarity.scripts.OnClick()
      assert.equals(1, view.rarity)
      for _ = 1, 5 do frame.rarity.scripts.OnClick() end -- 2, 3, 4, 5, back to all
      assert.is_nil(view.rarity)
      frame.search.text = "MOON"
      frame.search.scripts.OnTextChanged(frame.search)
      assert.equals("Moonbrook", widgets[1].name.text)
      assert.is_false(widgets[2].shown)
    end)

    it("closes on a second toggle", function()
      ns.BinderFrame.toggle()
      ns.BinderFrame.toggle()
      local frame = ns.BinderFrame._debug()
      assert.is_false(frame.shown)
    end)
  end)
end)
