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
      "Modules/Cards.lua", "Modules/Collection.lua", "Modules/Reveal.lua", "Modules/BinderModel.lua",
      "Modules/Slash.lua", "Modules/Walker.lua", "Modules/UI/Draw.lua", "Modules/UI/Window.lua", "Modules/UI/CardWidget.lua",
      "Modules/UI/RevealFrame.lua", "Modules/UI/BinderFrame.lua", "Modules/Opener.lua",
      "Data/EasternKingdoms/ElwynnForest.lua", "Data/EasternKingdoms/Westfall.lua",
    }) do
      mocks.loadSource(file, ns)
    end
    char = { stats = { yards = 0 }, progress = { total = 0, byZone = {} }, packs = {}, collection = {}, newCards = {} }
    ns.GetDB = function() return { char = char } end
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
        for _, fs in ipairs({ w.name, w.kind, w.flavor, w.attack, w.defense, w.newTag, w.copies, w.back, w.backLabel }) do
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
