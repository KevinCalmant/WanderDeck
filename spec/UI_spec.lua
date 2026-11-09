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
  local ns, char, account

  -- The Legendary a pack of Elwynn holds when every roll returns its upper
  -- bound: the last one in data order.
  local function lastLegendary()
    local last
    for _, c in ipairs(ns.Cards.zoneCards(1429)) do
      if c.rarity == 5 then last = c end
    end
    return last
  end

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
      "Modules/Cards.lua", "Modules/CardText.lua", "Modules/Collection.lua", "Modules/Tags.lua", "Modules/Reveal.lua", "Modules/BinderModel.lua",
      "Modules/Slash.lua", "Modules/Sound.lua", "Modules/Walker.lua", "Modules/UI/Draw.lua", "Modules/UI/Window.lua", "Modules/UI/CardWidget.lua", "Modules/UI/CardDetail.lua",
      "Modules/UI/RevealFrame.lua", "Modules/UI/BinderFrame.lua", "Modules/Opener.lua",
      "Data/EasternKingdoms/ElwynnForest.lua", "Data/EasternKingdoms/Westfall.lua",
    }) do
      mocks.loadSource(file, ns)
    end
    char = { stats = { yards = 0 }, progress = { total = 0, byZone = {} }, packs = {} }
    -- The collection is account-wide: it lives in db.global.
    account = { settings = { sound = true }, collection = {}, newCards = {}, tags = {}, pinned = {} }
    ns.GetDB = function() return { char = char, global = account } end
  end)

  after_each(function()
    _G.CreateFrame, _G.UIParent, _G.UISpecialFrames, _G.tinsert, _G.C_Map = nil, nil, nil, nil, nil
  end)

  describe("reveal", function()
    local function open()
      local result = ns.Collection.openNext(char, account,function() return 1 end, function() return nil end, ns.Config)
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
      -- Missing-card protection: the pack holds distinct new cards in data order.
      assert.equals("Stonetusk Boar", widgets[2].name.text)
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
      local result = ns.Collection.openNext(char, account,function(n) return n end, function() return nil end, ns.Config)
      ns.RevealFrame.show(result, "Zone 1429", function() end, function() return 0 end)
      local frame, widgets = ns.RevealFrame._debug()
      frame.revealAll.scripts.OnClick()
      assert.equals(lastLegendary().name, widgets[1].name.text)
      assert.is_true(widgets[1].halo.shown)

      char.packs = { { zoneMapID = 1429, earnedAt = 2 } }
      open()
      frame.revealAll.scripts.OnClick()
      assert.equals("Young Wolf", widgets[1].name.text)
      assert.is_false(widgets[1].halo.shown)
    end)

    describe("Epic and Legendary reveal effects", function()
      local function spy(widget)
        local played = {}
        for rarity, group in pairs(widget.revealFx.groups) do
          rawset(group, "Play", function() played[#played + 1] = rarity end)
          rawset(group, "Stop", function() played[#played + 1] = "stop" end)
        end
        return played
      end

      it("plays the Legendary effect when a Legendary card flips, in its rarity color", function()
        char.packs = { { zoneMapID = 1429, earnedAt = 1 } }
        local result = ns.Collection.openNext(char, account,function(n) return n end, function() return nil end, ns.Config)
        ns.RevealFrame.show(result, "Zone 1429", function() end, function() return 0 end)
        local _, widgets = ns.RevealFrame._debug()
        local played = spy(widgets[1])
        local colors = {}
        rawset(widgets[1].revealFx.burst, "SetColorTexture", function(_, r, g, b) colors = { r, g, b } end)
        widgets[1].scripts.OnClick()
        assert.equals(lastLegendary().name, widgets[1].name.text)
        assert.equals(5, played[#played])
        assert.same({ ns.CardWidget.rarityRGB(5) }, colors)
      end)

      it("plays no effect for a card below Epic", function()
        char.packs = { { zoneMapID = 1429, earnedAt = 1 } }
        open()
        local _, widgets = ns.RevealFrame._debug()
        local played = spy(widgets[1])
        widgets[1].scripts.OnClick()
        assert.equals("Young Wolf", widgets[1].name.text)
        for _, p in ipairs(played) do assert.equals("stop", p) end
      end)

      it("plays the Epic effect with Reveal all, and stops it when the widget shows the next pack", function()
        ns.Cards.registerZone({ zoneMapID = 1, continentMapID = 1415, cards = {
          { id = "1:epic", kind = "boss", rarity = 4, name = "Epic Boss", flavor = "" },
        } })
        local epic = ns.Cards.get("1:epic")
        local _, widgets = ns.RevealFrame._debug()
        if not widgets then
          char.packs = { { zoneMapID = 1429, earnedAt = 1 } }
          open()
          _, widgets = ns.RevealFrame._debug()
        end
        local played = spy(widgets[2])
        assert.is_true(ns.CardWidget.flip(widgets[2], epic, {}))
        assert.equals(4, played[#played])
        ns.CardWidget.showBack(widgets[2])
        assert.equals("stop", played[#played])
      end)

      it("keeps the effects off the binder: its widgets have none and flip returns false", function()
        local w = ns.CardWidget.create(_G.UIParent)
        assert.is_nil(rawget(w, "revealFx"))
        ns.Cards.registerZone({ zoneMapID = 2, continentMapID = 1415, cards = {
          { id = "2:legend", kind = "boss", rarity = 5, name = "Legend", flavor = "" },
        } })
        assert.is_false(ns.CardWidget.flip(w, ns.Cards.get("2:legend"), {}))
      end)

      it("plays an effect only for rarity 4 and 5, and never errors on a bad rarity", function()
        local w = ns.CardWidget.create(_G.UIParent, { revealFx = true })
        local played = spy(w)
        for _, rarity in ipairs({ 1, 2, 3, 6, 0, -1, 4.5 }) do
          local card = { id = "x", kind = "boss", rarity = rarity, name = "X", icon = "INV_Misc_Coin_01", attack = 1, defense = 1 }
          assert.is_false(ns.CardWidget.flip(w, card, {}), tostring(rarity))
        end
        for _, p in ipairs(played) do assert.equals("stop", p) end
        for _, rarity in ipairs({ 4, 5 }) do
          local card = { id = "x", kind = "boss", rarity = rarity, name = "X", icon = "INV_Misc_Coin_01", attack = 1, defense = 1 }
          assert.is_true(ns.CardWidget.flip(w, card, {}))
          assert.equals(rarity, played[#played])
        end
      end)

      it("still flips the card when the client cannot build the effects", function()
        ns.Cards.registerZone({ zoneMapID = 3, continentMapID = 1415, cards = {
          { id = "3:legend", kind = "boss", rarity = 5, name = "Legend", flavor = "" },
        } })
        for _, missing in ipairs({ "CreateAnimationGroup", "SetClipsChildren", "SetRotation" }) do
          _G.CreateFrame = function()
            local obj = stubObject()
            rawset(obj, missing, function() error(missing.." unavailable") end)
            rawset(obj, "CreateTexture", function()
              local t = stubObject()
              rawset(t, missing, function() error(missing.." unavailable") end)
              return t
            end)
            return obj
          end
          local w = ns.CardWidget.create(_G.UIParent, { revealFx = true })
          assert.is_nil(rawget(w, "revealFx"), missing)
          -- A real frame has no flipAnim/haloAnim when their pcall failed; the
          -- permissive stub would answer with a function instead.
          if rawget(w, "flipAnim") == nil then rawset(w, "flipAnim", false) end
          if rawget(w, "haloAnim") == nil then rawset(w, "haloAnim", false) end
          assert.is_false(ns.CardWidget.flip(w, ns.Cards.get("3:legend"), {}), missing)
          assert.equals("Legend", w.name.text)
          ns.CardWidget.showBack(w)
          assert.equals("?", w.back.text)
        end
      end)

      it("defines a stronger effect for Legendary than for Epic", function()
        local epic, legendary = ns.CardWidget.FX[4], ns.CardWidget.FX[5]
        assert.is_true(legendary.burst > epic.burst and legendary.sparks > epic.sparks)
        assert.is_true(legendary.rays and not epic.rays)
      end)
    end)

    it("hides art and halo on a face-down Legendary card, and finishes on Reveal all", function()
      char.packs = { { zoneMapID = 1429, earnedAt = 1 } }
      local result = ns.Collection.openNext(char, account,function(n) return n end, function() return nil end, ns.Config)
      ns.RevealFrame.show(result, "Zone 1429", function() end, function() return 0 end)
      local frame, widgets, state = ns.RevealFrame._debug()
      assert.is_false(widgets[1].icon.shown)
      assert.is_false(widgets[1].halo.shown)
      assert.is_false(widgets[1].name.shown)
      frame.revealAll.scripts.OnClick()
      assert.is_true(ns.Reveal.isDone(state))
      assert.equals("Interface\\Icons\\"..lastLegendary().icon, widgets[1].icon.texture)
      assert.is_true(widgets[1].halo.shown)

      -- Next pack reuses the widget: the Legendary face must not stay visible.
      char.packs = { { zoneMapID = 1429, earnedAt = 2 } }
      result = ns.Collection.openNext(char, account,function() return 1 end, function() return nil end, ns.Config)
      ns.RevealFrame.show(result, "Zone 1429", function() end, function() return 0 end)
      assert.is_false(widgets[1].halo.shown)
      assert.is_false(widgets[1].icon.shown)
      assert.is_false(widgets[1].name.shown)
      assert.equals("?", widgets[1].back.text)
    end)

    it("opens the detail window on a second click, not before the flip", function()
      char.packs = { { zoneMapID = 1429, earnedAt = 1 } }
      local result = ns.Collection.openNext(char, account,function() return 1 end, function() return nil end, ns.Config)
      ns.RevealFrame.show(result, "Zone 1429", function() end, function() return 0 end,
        function(id) return account.collection[id] end)
      local _, widgets = ns.RevealFrame._debug()
      widgets[1].scripts.OnClick()
      assert.is_nil(ns.CardDetail._debug())
      widgets[1].scripts.OnClick()
      local detail, big, flavor, owned = ns.CardDetail._debug()
      assert.is_true(detail.shown)
      assert.equals("Young Wolf", detail.title.text)
      assert.equals("Young Wolf", big.name.text)
      assert.equals("Its howl is more of a squeak, but the pack still listens.", flavor.text)
      assert.equals("Copies owned: 1", owned.text)
    end)

    it("flips a face-down card without opening the detail, even once the window exists", function()
      char.packs = { { zoneMapID = 1429, earnedAt = 1 } }
      local result = ns.Collection.openNext(char, account,function() return 1 end, function() return nil end, ns.Config)
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

    describe("close button", function()
      before_each(function()
        _G.HideUIPanel = function() error("HideUIPanel must not be used") end
      end)

      after_each(function()
        _G.HideUIPanel = nil
      end)

      it("closes the window without HideUIPanel", function()
        char.packs = { { zoneMapID = 1429, earnedAt = 1 } }
        open()
        local frame = ns.RevealFrame._debug()
        assert.is_true(frame.shown)
        assert.has_no.errors(function() frame.closeButton.scripts.OnClick() end)
        assert.is_false(frame.shown)
      end)

      it("keeps every card when closed mid-reveal, and the next pack opens face down", function()
        char.packs = { { zoneMapID = 1429, earnedAt = 1 }, { zoneMapID = 1436, earnedAt = 2 } }
        local result = open()
        local frame, widgets = ns.RevealFrame._debug()
        widgets[1].scripts.OnClick() -- flip one, leave four face down
        frame.closeButton.scripts.OnClick()
        for _, id in ipairs(result.cardIDs) do assert.is_true((account.collection[id] or 0) > 0, id) end
        for id in pairs(result.firstTime) do assert.is_true(account.newCards[id], id) end
        assert.equals(1, #char.packs)

        open()
        local _, _, state = ns.RevealFrame._debug()
        assert.equals(0, state.count)
        assert.equals("?", widgets[1].back.text)
      end)
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
      account.collection = { ["1429:young_wolf"] = 1 }
      account.newCards = { ["1429:young_wolf"] = true }
      local said = {}
      ns.print = function(msg) said[#said + 1] = msg end
      ns.CardWidget.showCard = function() error("draw failed") end
      ns.CardWidget.showMissing = function() error("draw failed") end
      ns.Slash.dispatch("binder")
      local frame = ns.BinderFrame._debug()
      assert.is_false(frame.shown)
      assert.same({ ["1429:young_wolf"] = true }, account.newCards)
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
      account.collection = { ["1429:young_wolf"] = 1 }
      account.newCards = { ["1429:young_wolf"] = true }
      local said = {}
      ns.print = function(msg) said[#said + 1] = msg end
      local button = ns.Window.button
      ns.Window.button = function(parent, label, width)
        if label == "<" then error("no template") end
        return button(parent, label, width)
      end
      ns.Slash.dispatch("binder")
      ns.Slash.dispatch("binder")
      assert.same({ ["1429:young_wolf"] = true }, account.newCards)
      assert.equals(2, #said)
      local frame = ns.BinderFrame._debug()
      assert.is_false(frame.shown)
    end)
  end)

  describe("card art model", function()
    local models, w, timers

    local function creature(fields)
      local c = { id = "1429:npc_299", kind = "creature", rarity = 1, name = "Young Wolf",
        icon = "INV_Misc_Bag_08", npcID = 299, attack = 1, defense = 1 }
      for k, v in pairs(fields or {}) do c[k] = v end
      return c
    end

    before_each(function()
      models = {}
      _G.CreateFrame = function(frameType)
        local o = stubObject()
        if frameType == "PlayerModel" then
          models[#models + 1] = o
          o.loads = 0
          o.SetCreature = function(self, id) self.creature = id; self.fileID = self.cachedFileID; self.loads = self.loads + 1 end
          -- false, not nil: the stub answers unset keys with a function.
          o.ClearModel = function(self) self.creature, self.fileID = false, false end
          o.GetModelFileID = function(self) return self.fileID end
          -- Like the client, OnShow fires when the model becomes visible:
          -- at once when its parent is visible, else when the parent opens.
          o.parentVisible = true
          o.Show = function(self)
            local was = self.shown
            self.shown = true
            if not was and self.parentVisible and self.scripts.OnShow then self.scripts.OnShow(self) end
          end
          o.Hide = function(self)
            local was = self.shown
            self.shown = false
            if was and self.scripts.OnHide then self.scripts.OnHide(self) end
          end
          o.IsVisible = function(self) return self.shown and self.parentVisible end
        end
        return o
      end
      timers = {}
      _G.C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end }
      w = ns.CardWidget.create(_G.UIParent)
    end)

    after_each(function() _G.issecretvalue, _G.C_Timer = nil, nil end)

    it("loads the model only once the card is visible, then again on the next frame", function()
      local m = models[1]
      m.parentVisible = false
      ns.CardWidget.showCard(w, creature())
      assert.equals(0, m.loads)
      -- The window opens: the model becomes visible.
      m.parentVisible = true
      m.scripts.OnShow(m)
      assert.equals(1, m.loads)
      assert.equals(299, m.creature)
      timers[#timers]()
      assert.equals(2, m.loads)
    end)

    it("skips a next-frame reload for a card the slot no longer shows", function()
      local m = models[1]
      ns.CardWidget.showCard(w, creature())
      local stale = timers[#timers]
      ns.CardWidget.showCard(w, creature({ kind = "place" }))
      stale()
      assert.is_false(m.creature)
      ns.CardWidget.showCard(w, creature({ npcID = 300 }))
      stale()
      assert.equals(1, m.loads - 1) -- the 300 load only, not a reload of 299
      assert.equals(300, m.creature)
    end)

    it("still shows the model on a client without C_Timer", function()
      _G.C_Timer = nil
      ns.CardWidget.showCard(w, creature())
      assert.equals(299, models[1].creature)
    end)

    it("frees the model when the card is hidden", function()
      local m = models[1]
      ns.CardWidget.showCard(w, creature())
      m:Hide()
      assert.is_false(m.creature)
    end)

    it("shows the creature's model and keeps the icon until it loads", function()
      ns.CardWidget.showCard(w, creature())
      local m = models[1]
      assert.is_true(m.shown)
      assert.equals(299, m.creature)
      assert.is_true(w.icon.shown)
      m.fileID = 123
      m.scripts.OnModelLoaded(m)
      assert.is_false(w.icon.shown)
    end)

    it("hides the icon at once when the model is cached", function()
      models[1].cachedFileID = 123
      ns.CardWidget.showCard(w, creature())
      assert.is_false(w.icon.shown)
    end)

    it("keeps the icon for a place card and a card without npcID", function()
      for _, c in ipairs({ creature({ kind = "place", areaID = 108 }), creature({ npcID = false }) }) do
        ns.CardWidget.showCard(w, c)
        assert.is_false(models[1].shown)
        assert.is_true(w.icon.shown)
      end
    end)

    it("keeps the icon when the model file ID is missing, secret or not a number", function()
      _G.issecretvalue = function(v) return v == 777 end
      for _, fileID in ipairs({ 777, 0, -1, "123" }) do
        ns.CardWidget.showCard(w, creature())
        models[1].fileID = fileID
        models[1].scripts.OnModelLoaded(models[1])
        assert.is_true(w.icon.shown, tostring(fileID))
      end
    end)

    it("keeps the icon when the model API throws", function()
      models[1].SetCreature = function() error("no creature") end
      ns.CardWidget.showCard(w, creature())
      assert.is_false(models[1].shown)
      assert.is_true(w.icon.shown)
    end)

    it("hides the model face down and missing, and ignores a late load for another card", function()
      ns.CardWidget.showCard(w, creature())
      ns.CardWidget.showBack(w)
      assert.is_false(models[1].shown)
      ns.CardWidget.showCard(w, creature())
      ns.CardWidget.showMissing(w, creature())
      assert.is_false(models[1].shown)
      -- The model finishes loading after the slot switched to a place card.
      ns.CardWidget.showCard(w, creature({ kind = "place" }))
      models[1].fileID = 123
      models[1].scripts.OnModelLoaded(models[1])
      assert.is_true(w.icon.shown)
    end)

    it("shows no model when models are switched off", function()
      ns.Config.CARD_MODELS = false
      ns.CardWidget.showCard(w, creature())
      ns.Config.CARD_MODELS = true
      assert.is_false(models[1].shown)
      assert.is_true(w.icon.shown)
    end)

    it("shows only the solo card's model, keeps others hidden on re-render, then restores them", function()
      local other = ns.CardWidget.create(_G.UIParent)
      ns.CardWidget.showCard(w, creature())
      ns.CardWidget.showCard(other, creature({ npcID = 300 }))
      models[1].cachedFileID = 123
      ns.CardWidget.soloModel(other)
      assert.is_false(models[1].shown)
      assert.is_false(models[1].creature)
      assert.is_true(w.icon.shown)
      assert.is_true(models[2].shown)
      -- The binder re-renders behind the detail window (pin, tag).
      ns.CardWidget.showCard(w, creature())
      assert.is_false(models[1].shown)
      ns.CardWidget.soloModel(nil)
      assert.is_true(models[1].shown)
      assert.equals(299, models[1].creature)
      assert.is_true(models[2].shown)
    end)

    it("hides the cards' models behind the detail window while it is open", function()
      ns.CardWidget.showCard(w, creature())
      ns.CardDetail.show(creature({ npcID = 300 }), 1)
      local detail = ns.CardDetail._debug()
      assert.is_false(models[1].shown)
      assert.equals(300, models[2].creature)
      detail.scripts.OnHide(detail)
      assert.is_true(models[1].shown)
    end)
  end)

  describe("binder", function()
    -- Cards show rarest first; these tests look at Elwynn's Commons (Young
    -- Wolf, then Stonetusk Boar), so they open the binder on rarity 1.
    local function openCommons()
      ns.BinderFrame.toggle()
      local frame, _, _, view = ns.BinderFrame._debug()
      view.rarity = 1
      frame.search.scripts.OnTextChanged(frame.search) -- re-render
    end

    it("does not show a missing card's name in a slot that held an owned card", function()
      account.collection = { ["1429:young_wolf"] = 1 }
      openCommons()
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
      account.collection = { ["1429:hogger"] = 1 }
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
      account.collection = { ["1429:young_wolf"] = 3 }
      openCommons()
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
      account.collection = { ["1429:young_wolf"] = 1 }
      openCommons()
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
        account.collection = { ["1429:young_wolf"] = 1, ["1429:stonetusk_boar"] = 1 }
        openCommons()
        local frame, widgets, _, view = ns.BinderFrame._debug()
        widgets[2].scripts.OnClick(widgets[2]) -- Stonetusk Boar
        local _, _, _, _, controls = ns.CardDetail._debug()
        return frame, widgets, view, controls
      end

      it("pins a card from the detail window and shows it first with a Pinned label", function()
        local _, widgets, _, controls = openDetail()
        assert.equals("Pin", controls.pin.text)
        controls.pin.scripts.OnClick()
        assert.same({ ["1429:stonetusk_boar"] = true }, account.pinned)
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
        assert.same({ ["1429:stonetusk_boar"] = { ["deck feu"] = true } }, account.tags)
        assert.equals("deck feu  x", controls.chips[1].text)
        assert.equals("", controls.input.text)

        local said = {}
        ns.print = function(msg) said[#said + 1] = msg end
        controls.input.text = "|cffff0000x"
        controls.input.scripts.OnEnterPressed(controls.input)
        assert.equals(1, #said)
        assert.same({ ["1429:stonetusk_boar"] = { ["deck feu"] = true } }, account.tags)

        controls.chips[1].scripts.OnClick(controls.chips[1])
        assert.same({}, account.tags)
        assert.is_false(controls.chips[1].shown)
      end)

      it("refuses #trade typed in the tag box", function()
        local _, _, _, controls = openDetail()
        local said = {}
        ns.print = function(msg) said[#said + 1] = msg end
        controls.input.text = "#trade"
        controls.input.scripts.OnEnterPressed(controls.input)
        assert.same({}, account.tags)
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
        account.collection = { ["1429:young_wolf"] = 1 }
        account.tags = { ["1429:young_wolf"] = { ["a|b"] = true } } -- slipped past the sanitizer
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
      local frame = ns.BinderFrame._debug()
      assert.truthy(frame.zonePageText.text:find("||cffff0000Evil||r", 1, true))
      assert.is_nil(frame.zonePageText.text:find("\n", 1, true))

      char.packs = { { zoneMapID = 1429, earnedAt = 1 } }
      ns.Slash.dispatch("open")
      local reveal = ns.RevealFrame._debug()
      assert.truthy(reveal.subtitle.text:find("||cffff0000Evil||r", 1, true))
    end)

    it("never displays the search text", function()
      account.collection = { ["1429:young_wolf"] = 1 }
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
      account.collection = { ["1429:young_wolf"] = 2 }
      account.newCards = { ["1429:young_wolf"] = true }
      openCommons()
      local frame, widgets, zoneButtons, view = ns.BinderFrame._debug()
      assert.is_true(frame.shown)
      assert.equals(1429, view.zoneMapID)
      assert.equals("Young Wolf", widgets[1].name.text)
      assert.equals("x2", widgets[1].copies.text)
      assert.equals("New!", widgets[1].newTag.text)
      assert.equals("?", widgets[2].back.text)
      assert.same({}, account.newCards)
      assert.equals("Zone 1429  1/"..#ns.Cards.zoneCards(1429), zoneButtons[1].text)
    end)

    it("opens with no registered zone without error", function()
      ns.Cards.zoneIDs = function() return {} end
      ns.BinderFrame.toggle()
      local frame, _, zoneButtons = ns.BinderFrame._debug()
      assert.is_true(frame.shown)
      assert.equals("1 / 0", frame.zonePageText.text)
      assert.is_false(frame.zonePrev.enabled)
      assert.is_false(frame.zoneNext.enabled)
      for _, b in ipairs(zoneButtons) do assert.is_false(b.shown) end
    end)

    it("clamps a stale zone page and starts on the selected zone's page when reopened", function()
      ns.BinderFrame.toggle()
      local frame, _, zoneButtons, view = ns.BinderFrame._debug()
      for _, stale in ipairs({ 99, -5 }) do
        view.zonePage = stale
        frame.search.scripts.OnTextChanged(frame.search) -- re-render
        assert.equals(1, view.zonePage)
        assert.equals(1429, zoneButtons[1].zoneMapID)
        assert.is_true(zoneButtons[1].shown)
      end
      view.zonePage = 7
      ns.BinderFrame.toggle()
      ns.BinderFrame.toggle()
      assert.equals(1, view.zonePage)
    end)

    it("lists all 40 shipped zones, one continent per zone page", function()
      -- Elwynn and Westfall are loaded by before_each; add every other Data file.
      local xml = assert(io.open("Data/load_data.xml")):read("*a")
      for file in xml:gmatch('<Script file="([^"]+)"') do
        if file ~= "Loaded.lua" and file ~= "EasternKingdoms\\ElwynnForest.lua" and file ~= "EasternKingdoms\\Westfall.lua" then
          mocks.loadSource("Data/"..file:gsub("\\", "/"), ns)
        end
      end
      ns.BinderFrame.toggle()
      local frame, _, zoneButtons, view = ns.BinderFrame._debug()
      local seen, continents = {}, {}
      local function collect()
        continents[#continents + 1] = frame.zonePageText.text
        for _, b in ipairs(zoneButtons) do
          if b.shown ~= false and b.zoneMapID then
            assert.is_nil(seen[b.zoneMapID], "zone listed twice: "..b.zoneMapID)
            seen[b.zoneMapID] = ns.Cards.continentOf(b.zoneMapID)
          end
        end
      end
      collect()
      assert.is_false(frame.zonePrev.enabled)
      while frame.zoneNext.enabled do
        frame.zoneNext.scripts.OnClick()
        collect()
      end
      local count = 0
      for _ in pairs(seen) do count = count + 1 end
      assert.equals(40, count)
      assert.same({ "Zone 1414", "Zone 1415" }, continents)
      -- Paging the list keeps the selected zone; picking one there selects it.
      local selected = view.zoneMapID
      assert.equals(1414, ns.Cards.continentOf(selected))
      zoneButtons[1].scripts.OnClick(zoneButtons[1])
      assert.equals(1415, ns.Cards.continentOf(view.zoneMapID))
      frame.zonePrev.scripts.OnClick()
      assert.is_false(frame.zonePrev.enabled)
      assert.equals(1415, ns.Cards.continentOf(view.zoneMapID))
    end)

    it("switches zone, filters, pages and searches without errors", function()
      account.collection = { ["1436:moonbrook"] = 1 }
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

    it("closes the binder and the detail window with their close buttons, without HideUIPanel", function()
      _G.HideUIPanel = function() error("HideUIPanel must not be used") end
      local ok, err = pcall(function()
        account.collection = { ["1429:young_wolf"] = 1 }
        openCommons()
        local frame, widgets = ns.BinderFrame._debug()
        assert.is_true(frame.shown)
        widgets[1].scripts.OnClick(widgets[1])
        local detail = ns.CardDetail._debug()
        assert.is_true(detail.shown)
        detail.closeButton.scripts.OnClick()
        assert.is_false(detail.shown)
        frame.closeButton.scripts.OnClick()
        assert.is_false(frame.shown)
      end)
      _G.HideUIPanel = nil
      assert(ok, err)
    end)

    it("closes on a second toggle", function()
      ns.BinderFrame.toggle()
      ns.BinderFrame.toggle()
      local frame = ns.BinderFrame._debug()
      assert.is_false(frame.shown)
    end)
  end)
end)
