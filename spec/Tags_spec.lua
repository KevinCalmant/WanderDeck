local mocks = require("wow_mocks")

describe("Tags", function()
  local Tags

  before_each(function()
    mocks.reset()
    local ns = mocks.newNamespace()
    mocks.loadSource("Modules/Tags.lua", ns)
    Tags = ns.Tags
  end)

  describe("normalize", function()
    it("trims, collapses spaces and lowercases", function()
      assert.equals("deck feu", Tags.normalize("  Deck   FEU "))
    end)

    it("keeps accented letters", function()
      assert.equals("épique", Tags.normalize("épique"))
    end)

    it("accepts exactly 24 bytes and refuses 25", function()
      assert.equals(string.rep("a", 24), Tags.normalize(string.rep("a", 24)))
      assert.is_nil(Tags.normalize(string.rep("a", 25)))
    end)

    it("refuses empty, chat codes, control characters, the reserved prefix and non-strings", function()
      for _, bad in ipairs({
        "", "   ", "|cffff0000red|r", "deck|Hitem:1|h", "a\nb", "a\0b", "a\tb", "deck\n", "#trade", "#x",
        " #x", 5, nil, {},
        "deck<script>|r",
      }) do
        assert.is_nil(Tags.normalize(bad), tostring(bad))
      end
    end)

    it("refuses CR, DEL and invisible or direction-changing Unicode", function()
      for _, bad in ipairs({
        "a\rb", "a\127b",
        "a\194\160b",     -- U+00A0 no-break space
        "a\226\128\139b", -- U+200B zero-width space
        "a\226\128\174b", -- U+202E right-to-left override
        "a\226\129\160b", -- U+2060 word joiner
        "\239\187\191a",  -- U+FEFF BOM
      }) do
        assert.is_nil(Tags.normalize(bad))
      end
    end)

    it("counts bytes: 12 accented letters fit, 13 do not", function()
      assert.equals(string.rep("é", 12), Tags.normalize(string.rep("é", 12)))
      assert.is_nil(Tags.normalize(string.rep("é", 13)))
    end)

    it("keeps markup that is harmless in a FontString as plain text", function()
      assert.equals("<script>x</script>", Tags.normalize("<script>x</script>"))
    end)
  end)

  describe("add and remove", function()
    it("adds a normalized tag once", function()
      local tags = {}
      assert.is_true(Tags.add(tags, "10:a", " Feu "))
      assert.is_true(Tags.add(tags, "10:a", "feu"))
      assert.same({ "feu" }, Tags.of(tags, "10:a"))
    end)

    it("refuses the reserved For trade tag typed as text", function()
      local tags = {}
      local ok, reason = Tags.add(tags, "10:a", Tags.TRADE)
      assert.is_false(ok)
      assert.equals("invalid", reason)
      assert.same({}, tags)
    end)

    it("refuses an invalid tag with a reason", function()
      local ok, reason = Tags.add({}, "10:a", "|cff")
      assert.is_false(ok)
      assert.equals("invalid", reason)
    end)

    it("caps tags per card", function()
      local tags = {}
      for i = 1, Tags.MAX_PER_CARD do assert.is_true(Tags.add(tags, "10:a", "t"..i)) end
      local ok, reason = Tags.add(tags, "10:a", "one more")
      assert.is_false(ok)
      assert.equals("card-full", reason)
    end)

    it("caps distinct tags but allows reusing an existing one", function()
      local tags = {}
      for i = 1, Tags.MAX_DISTINCT do assert.is_true(Tags.add(tags, "10:c"..i, "t"..i)) end
      local ok, reason = Tags.add(tags, "10:x", "new")
      assert.is_false(ok)
      assert.equals("too-many-tags", reason)
      assert.is_true(Tags.add(tags, "10:x", "t1"))
    end)

    it("removes a tag and drops the empty card entry", function()
      local tags = {}
      Tags.add(tags, "10:a", "feu")
      Tags.remove(tags, "10:a", "feu")
      assert.same({}, tags)
    end)

    it("keeps For trade out of the player tag lists and limits", function()
      local tags = {}
      for i = 1, Tags.MAX_PER_CARD do Tags.add(tags, "10:a", "t"..i) end
      assert.is_true(Tags.toggleTrade(tags, "10:a"))
      assert.is_true(Tags.has(tags, "10:a", Tags.TRADE))
      assert.equals(Tags.MAX_PER_CARD, #Tags.of(tags, "10:a"))
      for _, tag in ipairs(Tags.all(tags)) do assert.not_equals(Tags.TRADE, tag) end
      assert.is_false(Tags.toggleTrade(tags, "10:a"))
      assert.is_false(Tags.has(tags, "10:a", Tags.TRADE))
    end)
  end)

  describe("pins", function()
    it("toggles", function()
      local pinned = {}
      assert.is_true(Tags.togglePin(pinned, "10:a"))
      assert.is_false(Tags.togglePin(pinned, "10:a"))
      assert.same({}, pinned)
    end)
  end)

  describe("display", function()
    it("doubles pipes", function()
      assert.equals("a||cb", Tags.display("a|cb"))
    end)
  end)

  describe("sanitize", function()
    local KNOWN = { ["10:a"] = true, ["10:b"] = true }
    local function isKnown(id) return KNOWN[id] end

    it("creates missing or wrong-type tables", function()
      local char = { tags = 5, pinned = "x" }
      Tags.sanitize(char, isKnown, true)
      assert.same({}, char.tags)
      assert.same({}, char.pinned)
    end)

    it("drops unknown cards, invalid tags and non-true flags", function()
      local char = {
        tags = {
          ["10:a"] = { feu = true, ["|cffred"] = true, ["#nope"] = true, Upper = true, bad = "yes", [Tags.TRADE] = true },
          ["99:ghost"] = { feu = true },
          ["10:b"] = "x",
        },
        pinned = { ["10:a"] = true, ["10:b"] = "yes", ["99:ghost"] = true },
      }
      Tags.sanitize(char, isKnown, true)
      assert.same({ ["10:a"] = { feu = true, [Tags.TRADE] = true } }, char.tags)
      assert.same({ ["10:a"] = true }, char.pinned)
    end)

    it("keeps unknown card IDs when Data did not finish loading", function()
      local char = { tags = { ["99:ghost"] = { feu = true } }, pinned = { ["99:ghost"] = true } }
      Tags.sanitize(char, isKnown, false)
      assert.same({ ["99:ghost"] = { feu = true } }, char.tags)
      assert.same({ ["99:ghost"] = true }, char.pinned)
    end)

    it("drops overlong, multi-line, numeric and empty tag entries", function()
      local char = { tags = {
        ["10:a"] = { [string.rep("a", 25)] = true, ["a\nb"] = true, [5] = true, ok = true },
        ["10:b"] = {},
      } }
      Tags.sanitize(char, isKnown, true)
      assert.same({ ["10:a"] = { ok = true } }, char.tags)
    end)

    it("enforces the distinct cap across cards", function()
      local tags = {}
      for i = 1, 30 do tags["k"..i] = { ["t"..i] = true } end
      local known = function(id) return type(id) == "string" end
      local char = { tags = tags }
      Tags.sanitize(char, known, true)
      assert.equals(Tags.MAX_DISTINCT, #Tags.all(char.tags))
    end)

    it("drops non-string and overlong unknown card IDs even when Data did not load", function()
      local char = {
        tags = { [5] = { a = true }, [string.rep("x", 65)] = { a = true } },
        pinned = { [5] = true, [true] = true },
      }
      Tags.sanitize(char, isKnown, false)
      assert.same({}, char.tags)
      assert.same({}, char.pinned)
    end)

    it("enforces the per-card and distinct limits on a hand-edited save", function()
      local cardTags = {}
      for i = 1, 30 do cardTags["t"..i] = true end
      local char = { tags = { ["10:a"] = cardTags } }
      Tags.sanitize(char, isKnown, true)
      assert.equals(Tags.MAX_PER_CARD, #Tags.of(char.tags, "10:a"))
    end)
  end)
end)
