"""Unit tests for scripts/generate-cards.py: hostile dump values must never
reach the generated Lua. Run from the repo root:

    python3 -I scripts/test_generate_cards.py
"""
import importlib.util
import os
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
SPEC = importlib.util.spec_from_file_location("generate_cards", os.path.join(HERE, "generate-cards.py"))
gen = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(gen)


def card(**overrides):
    c = {"id": "1429:npc_299", "kind": "creature", "rarity": 1, "name": "Young Wolf",
         "icon": "Ability_Hunter_Pet_Wolf", "entry": 299, "level": 2, "creatureType": "Beast"}
    c.update(overrides)
    return c


class CleanName(unittest.TestCase):
    def test_accepts_plain_names(self):
        for name in ["Hogger", "Mother Fang", "Kam's Walking Stick", "a" * 64, 'A "quoted" name']:
            self.assertTrue(gen.clean_name(name), name)

    def test_refuses_hostile_or_malformed_names(self):
        for name in [
            "", "   ", " Hogger", "Hogger ", "a" * 65,
            "Hogger\n", "Hogger\r\n", "Hog\0ger", "Hog\x1aer", "Hog\tger",
            "Hogger|cffff0000x|r", "|Hitem:1|h", "|TInterface\\x:0|t",
            "Ragnarosé", "Ragnaros�", None, 5,
        ]:
            self.assertFalse(gen.clean_name(name), repr(name))


class LuaString(unittest.TestCase):
    def test_escapes_quotes_and_backslashes(self):
        self.assertEqual(gen.lua_string('Hogger"); os.exit() --'), '"Hogger\\"); os.exit() --"')
        self.assertEqual(gen.lua_string('Hogger\\" .. x .. "'), '"Hogger\\\\\\" .. x .. \\""')
        self.assertEqual(gen.lua_string("]]--"), '"]]--"')

    def test_refuses_text_that_is_not_clean(self):
        for text in ["Evil\n", "a|cff", "", "Écorcheur"]:
            with self.assertRaises(ValueError):
                gen.lua_string(text)


# 64 bytes: "é" is 2 bytes in UTF-8.
FR_64 = "é" * 32
HOSTILE_FRENCH = [
    "Lardeur|cffff0000x|r", "|Hitem:1|h[x]|h", "a|", "Lardeur\n", "Lar\rdeur", "Lar\0deur", "Lar\tdeur",
    "‮Lardeur", "Lardeur‮", "Lar deur", "Faim !", "Lar​deur", "Lar‍deur",
    "Lar⁠deur", "﻿Lardeur", "Lar�deur", "Lar\u0085deur", "Lar­deur", "Lar\U000e0041deur",
    "Larㅤdeur", "Lar️deur", "Lar deur", "Lar　deur", "Lardeur", "Lar\ud800deur",
    FR_64 + "a", "a" * 65, "", "   ", " Lardeur", "Lardeur ", None, 5, b"Lardeur",
    # Invisible or blank-looking characters outside the categories a deny-list
    # would catch: combining grapheme joiner, braille blank, Hangul fillers,
    # Mongolian and supplementary variation selectors, Khmer inherent vowels.
    "Lar͏deur", "⠀", "⠀⠀", "Larᅟdeur", "Larᅠdeur", "Larﾠdeur",
    "Lar᠋deur", "Lar\U000e0100deur", "Lar឴deur",
    # Stacked combining marks ("Zalgo"), and a lone combining accent.
    "a" + "́" * 20, "Lardeuŕ́", "́",
    # Look-alikes and letters French names never use.
    "Lardеur", "Lardeur™", "Lar×deur", "가",
]


class FrenchProblem(unittest.TestCase):
    def test_accepts_french_names(self):
        for text in ["Lardeur", "Écorcheur des Mortemines", "Vol’jin", "MacKinley « Loup des mers »",
                     "Gnoll Rivepatte", 'Le "Roi"', "a\\b", "Œil", FR_64, "a" * 64,
                     "Ÿ", "Naïve – « Hé » … — c’est", "ÀÂÇÈÉÊËÎÏÔÙÛÜàâçèéêëîïôùûüÿæÆ"]:
            self.assertIsNone(gen.french_problem(text), repr(text))

    def test_accepts_every_character_of_the_shipped_french_files(self):
        # The allow-list must not drop a name already shipped or curated.
        import glob
        repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        for path in glob.glob(os.path.join(repo, "Locales", "frFR*.lua")):
            with open(path, encoding="utf-8") as handle:
                for ch in set(handle.read()):
                    if ord(ch) > 0x7F:
                        self.assertIn(ch, gen.FR_ALLOWED_NON_ASCII, "%s U+%04X" % (os.path.basename(path), ord(ch)))

    def test_refuses_hostile_values(self):
        for text in HOSTILE_FRENCH:
            self.assertIsNotNone(gen.french_problem(text), repr(text))

    def test_names_the_reason(self):
        self.assertEqual("contains |", gen.french_problem("a|cff"))
        self.assertEqual("control character", gen.french_problem("a\nb"))
        self.assertEqual("character outside the French set", gen.french_problem("a‮b"))
        self.assertEqual("character outside the French set", gen.french_problem("⠀"))
        self.assertEqual("longer than 64 bytes", gen.french_problem(FR_64 + "a"))
        self.assertEqual("blank", gen.french_problem(" "))
        self.assertEqual("missing", gen.french_problem(None))


class NormalizeFrench(unittest.TestCase):
    def test_turns_no_break_spaces_into_plain_spaces(self):
        self.assertEqual("Terre !", gen.normalize_french("Terre !"))
        self.assertEqual("« Hé »", gen.normalize_french("« Hé »"))
        self.assertIsNone(gen.french_problem(gen.normalize_french("Un gyro... quoi ?")))

    def test_composes_a_base_letter_and_its_combining_accent(self):
        self.assertEqual("Écorcheur", gen.normalize_french("Écorcheur"))
        self.assertIsNone(gen.french_problem(gen.normalize_french("Écorcheur")))
        # NFC composes one accent at most; the stacked rest is still refused.
        self.assertIsNotNone(gen.french_problem(gen.normalize_french("e" + "́" * 3)))

    def test_nfc_singletons_are_checked_after_normalizing(self):
        # U+212A KELVIN SIGN and U+037E GREEK QUESTION MARK map to ASCII.
        self.assertEqual("K;", gen.normalize_french("K;"))
        self.assertIsNone(gen.french_problem(gen.normalize_french("K;")))
        self.assertIsNotNone(gen.french_problem("K"))

    def test_leaves_other_hostile_characters_for_french_problem(self):
        for bad in ["a​b", "a‮b", "a|cffb", "a\nb", " Terre"]:
            self.assertIsNotNone(gen.french_problem(gen.normalize_french(bad)), repr(bad))
        self.assertIsNone(gen.normalize_french(None))


class LuaStringFr(unittest.TestCase):
    def test_escapes_quotes_and_backslashes_and_keeps_utf8(self):
        self.assertEqual('"Le \\"Roi\\" \\\\ é"', gen.lua_string_fr('Le "Roi" \\ é'))
        self.assertEqual('"x\\"); os.exit() --"', gen.lua_string_fr('x"); os.exit() --'))
        self.assertEqual('"]]--"', gen.lua_string_fr("]]--"))

    def test_refuses_hostile_values(self):
        for text in HOSTILE_FRENCH:
            with self.assertRaises(ValueError, msg=repr(text)):
                gen.lua_string_fr(text)


def fr_tables(npc=None, quest=None, item=None):
    return {"npc": npc or {}, "quest": quest or {}, "item": item or {}}


class FrenchNames(unittest.TestCase):
    def test_generated_cards_take_their_source_name(self):
        cards = [card(), {"id": "1429:quest_7", "name": "Kobold Camp Cleanup", "questID": 7},
                 {"id": "1429:item_2933", "name": "Seal of Wrynn", "itemID": 2933}]
        names, stats = gen.french_names(cards, [], {}, fr_tables(
            npc={299: "Jeune loup"}, quest={7: "Nettoyage du camp kobold"}, item={2933: "Sceau de Wrynn"}), set())
        self.assertEqual({"Young Wolf": "Jeune loup", "Kobold Camp Cleanup": "Nettoyage du camp kobold",
                          "Seal of Wrynn": "Sceau de Wrynn"}, names)
        self.assertEqual(1, stats["generated npc: written"])

    def test_a_refused_value_is_skipped_counted_and_never_written(self):
        for bad in HOSTILE_FRENCH:
            names, stats = gen.french_names([card()], [], {}, fr_tables(npc={299: bad}), set())
            self.assertEqual({}, names, repr(bad))
            self.assertEqual(1, sum(n for reason, n in stats.items() if "written" not in reason), repr(bad))
            self.assertNotIn("Young Wolf", gen.render_french(names))

    def test_an_english_key_that_is_not_clean_ascii_is_skipped(self):
        creatures = {1: "Evil|cffff0000", 2: "Écorcheur", 3: "a" * 65}
        fr = fr_tables(npc={1: "Mal", 2: "Écorcheur fr", 3: "Long"})
        hand = [("creature", "Evil|cffff0000"), ("creature", "Écorcheur"), ("creature", "a" * 65)]
        names, stats = gen.french_names([], hand, creatures, fr, set())
        self.assertEqual({}, names)
        self.assertEqual(3, stats["hand-written: English key not clean ASCII"])

    def test_lowest_id_wins_when_sources_disagree(self):
        cards = [card(id="1429:npc_300", entry=300), card()]
        names, stats = gen.french_names(cards, [], {}, fr_tables(npc={299: "Jeune loup", 300: "Louveteau"}), set())
        self.assertEqual("Jeune loup", names["Young Wolf"])
        self.assertEqual(1, stats["generated: sources disagree, lowest ID taken"])

    def test_hand_written_creatures_match_one_name_or_agreeing_entries(self):
        creatures = {448: "Hogger", 1: "Mother Fang", 2: "Mother Fang", 3: "Twin", 4: "Twin", 5: "Moonbrook"}
        fr = fr_tables(npc={448: "Lardeur", 1: "Mère Croc", 2: "Mère Croc", 3: "Jumeau", 4: "Jumelle",
                            5: "Ruisselune"})
        hand = [("elite", "Hogger"), ("rare", "Mother Fang"), ("npc", "Twin"), ("place", "Moonbrook"),
                ("creature", "Nobody")]
        names, stats = gen.french_names([], hand, creatures, fr, set())
        self.assertEqual({"Hogger": "Lardeur", "Mother Fang": "Mère Croc"}, names)
        self.assertEqual(1, stats["hand-written: entries disagree, skipped"])
        self.assertEqual(1, stats["hand-written: no creature with this name"])

    def test_names_already_in_locales_or_unchanged_are_left_out(self):
        names, stats = gen.french_names([card(), card(id="1429:npc_6", entry=6, name="Hogger")], [], {},
                                        fr_tables(npc={299: "Jeune loup", 6: "Hogger"}), {"Young Wolf"})
        self.assertEqual({}, names)
        self.assertEqual(1, stats["generated npc: already in Locales"])
        self.assertEqual(1, stats["generated npc: same as English"])


class RenderFrench(unittest.TestCase):
    def test_sorted_with_the_locale_guard_first(self):
        text = gen.render_french({"Young Wolf": "Jeune loup", '"Sea Wolf" MacKinley': "MacKinley « Loup des mers »"})
        lines = text.split("\n")
        self.assertEqual(["local _, ns = ...", 'if GetLocale() ~= "frFR" then return end', "local L = ns.L"], lines[:3])
        body = [line for line in lines if line.startswith("L[")]
        self.assertEqual(['L["\\"Sea Wolf\\" MacKinley"] = "MacKinley « Loup des mers »"',
                          'L["Young Wolf"] = "Jeune loup"'], body)

    def test_refuses_a_hostile_value_or_key(self):
        with self.assertRaises(ValueError):
            gen.render_french({"Young Wolf": "Jeune\nloup"})
        with self.assertRaises(ValueError):
            gen.render_french({"Young\nWolf": "Jeune loup"})


class ExistingLocaleKeys(unittest.TestCase):
    def test_reads_every_locale_file_but_the_generated_one(self):
        import tempfile
        with tempfile.TemporaryDirectory() as repo:
            os.makedirs(os.path.join(repo, "Locales"))
            for name, text in [("enUS.lua", 'L["Level"] = "Level"\n'),
                               ("frFR.lua", 'L["Hogger"] = "Lardeur"\nL["Say \\"hi\\""] = "x"\n'),
                               ("frFR_Generated.lua", 'L["Young Wolf"] = "Jeune loup"\n')]:
                with open(os.path.join(repo, "Locales", name), "w") as handle:
                    handle.write(text)
            self.assertEqual({"Level", "Hogger", 'Say "hi"'}, gen.existing_locale_keys(repo))


class CheckCard(unittest.TestCase):
    def test_accepts_a_valid_card(self):
        gen.check_card(card())
        gen.check_card({"id": "1429:item_2933", "kind": "item", "rarity": 3, "name": "Seal of Wrynn",
                        "icon": "INV_Misc_Bag_08", "itemID": 2933})

    def test_aborts_on_bad_ids_levels_rarities_and_names(self):
        for bad in [
            card(entry=0), card(entry=-5), card(entry=1.5), card(entry="12"), card(entry=True),
            card(entry=2 ** 31), card(level=0), card(level=64), card(level=None),
            card(rarity=5), card(rarity=0), card(name="Hogger\n"), card(name="<x>|cff"),
            {"id": "1429:quest_1", "kind": "quest", "rarity": 2, "name": "Q", "icon": "INV_Misc_Note_01",
             "questID": -1},
            {"id": "1429:item_1", "kind": "item", "rarity": 2, "name": "I", "icon": "INV_Misc_Bag_08",
             "itemID": 644.5},
        ]:
            with self.assertRaises(SystemExit, msg=repr(bad)):
                gen.check_card(bad)


class RarityOverrides(unittest.TestCase):
    def setUp(self):
        self.saved = dict(gen.RARITY_OVERRIDES)
        gen.RARITY_OVERRIDES.clear()

    def tearDown(self):
        gen.RARITY_OVERRIDES.clear()
        gen.RARITY_OVERRIDES.update(self.saved)

    def test_legendary_only_for_a_curated_card(self):
        with self.assertRaises(SystemExit):
            gen.check_card(card(rarity=5))
        gen.RARITY_OVERRIDES["1429:npc_299"] = 5
        gen.check_card(card(rarity=5))
        with self.assertRaises(SystemExit):
            gen.check_card(card(id="1429:npc_300", entry=300, rarity=5))

    def test_refuses_bool_and_out_of_range_rarities_even_when_curated(self):
        gen.RARITY_OVERRIDES["1429:npc_299"] = 5
        for bad in [True, 6, 0, "5", 4.5]:
            with self.assertRaises(SystemExit, msg=repr(bad)):
                gen.check_card(card(rarity=bad))

    def test_applies_after_selection_without_changing_ids(self):
        gen.RARITY_OVERRIDES["1429:npc_299"] = 4
        out = {1429: ([card(), card(id="1429:npc_300", entry=300)], 0, 2)}
        gen.apply_rarity_overrides(out)
        self.assertEqual([4, 1], [c["rarity"] for c in out[1429][0]])
        self.assertEqual(["1429:npc_299", "1429:npc_300"], [c["id"] for c in out[1429][0]])

    def test_stops_when_a_curated_card_is_not_generated(self):
        gen.RARITY_OVERRIDES["1429:npc_999"] = 5
        with self.assertRaises(SystemExit):
            gen.apply_rarity_overrides({1429: ([card()], 0, 1)})


class Render(unittest.TestCase):
    def test_render_refuses_a_bad_card(self):
        zone = next(iter(gen.ZONES))
        with self.assertRaises(SystemExit):
            gen.render(zone, [card(id="%d:npc_1" % zone, entry=-1)])

    def test_render_output_has_one_line_per_card(self):
        zone = next(iter(gen.ZONES))
        text = gen.render(zone, [card(id="%d:npc_299" % zone, name='Odd "Wolf" \\ name')])
        body = [line for line in text.splitlines() if line.startswith("  { ")]
        self.assertEqual(1, len(body))
        self.assertIn('name = "Odd \\"Wolf\\" \\\\ name"', body[0])


class ZoneTables(unittest.TestCase):
    def test_every_zone_has_its_constants(self):
        rect_zones = {r[0] for r in gen.ZONE_RECTS}
        self.assertEqual(40, len(gen.ZONES))
        self.assertEqual(sorted(gen.ZONES), sorted(gen.ZONE_ORDER))
        for zone, (file_name, folder, display) in gen.ZONES.items():
            self.assertIn(zone, rect_zones, display)
            self.assertIn(zone, gen.LEVEL_CAP, display)
            self.assertIn(zone, gen.ZONE_AREAS, display)
            self.assertIn(folder, gen.CONTINENTS, display)
            # File names end up in paths: letters only, no separator or dot.
            self.assertRegex(file_name, r"\A[A-Z][A-Za-z]{2,40}\Z", display)
            self.assertTrue(gen.clean_name(display), display)
            if zone not in gen.FROZEN_ZONES:
                self.assertLessEqual(gen.LEVEL_FLOOR[zone], gen.LEVEL_CAP[zone], display)
                self.assertLessEqual(gen.LEVEL_CAP[zone], 63, display)
        self.assertEqual(len(gen.ZONES), len({v[0].lower() for v in gen.ZONES.values()}))

    def test_dungeons_point_at_shipped_zones_and_raids_are_absent(self):
        for map_id, zone in gen.DUNGEON_MAPS.items():
            self.assertIn(zone, gen.ZONES, map_id)
        # Molten Core, Onyxia, Blackwing Lair, Zul'Gurub, AQ20, AQ40, Naxxramas.
        for raid_map in (409, 249, 469, 309, 509, 531, 533):
            self.assertNotIn(raid_map, gen.DUNGEON_MAPS)
        self.assertEqual(1413, gen.DUNGEON_MAPS[43])   # Wailing Caverns
        self.assertEqual(1428, gen.DUNGEON_MAPS[230])  # Blackrock Depths
        for zone, areas in gen.ZONE_AREAS.items():
            self.assertFalse(areas & gen.SKIPPED_QUEST_AREAS, zone)


class SpawnPlacement(unittest.TestCase):
    def test_zones_of_spawn_agrees_with_zone_of_spawn(self):
        for map_id, x, y in [(0, -10500.0, 1000.0), (0, -9000.0, -100.0), (1, -7000.0, -1500.0),
                             (1, -6600.0, -3000.0), (0, -10400.0, -3300.0), (1, 9900.0, 2300.0)]:
            ranked = gen.zones_of_spawn(map_id, x, y)
            self.assertTrue(ranked, (map_id, x, y))
            self.assertEqual(gen.zone_of_spawn(map_id, x, y), ranked[0])

    def test_cities_dungeons_and_other_maps(self):
        self.assertEqual([1429], gen.zones_of_spawn(0, -8800.0, 600.0))  # Stormwind City
        self.assertEqual([1446], gen.zones_of_spawn(209, 0.0, 0.0))      # Zul'Farrak
        self.assertEqual([], gen.zones_of_spawn(409, 0.0, 0.0))          # Molten Core
        self.assertEqual([], gen.zones_of_spawn(530, 0.0, 0.0))          # Outland
        self.assertIsNone(gen.zone_of_spawn(309, 0.0, 0.0))              # Zul'Gurub

    def test_place_spawn_takes_the_first_zone_whose_window_holds_the_level(self):
        # Thousand Needles (cap 37) then Un'Goro (45-57): a level 51 gorilla.
        self.assertEqual(1449, gen.place_spawn([1441, 1449], 51))
        self.assertEqual(1441, gen.place_spawn([1441, 1449], 30))
        # No window fits, or no level rule: the best candidate.
        self.assertEqual(1441, gen.place_spawn([1441, 1449], 63))
        self.assertEqual(1441, gen.place_spawn([1441, 1449], None))
        self.assertIsNone(gen.place_spawn([], 20))
        # Frozen zones have no floor: a level 1 creature fits Westfall.
        self.assertEqual(1436, gen.place_spawn([1436, 1431], 1))

    def test_assign_homes_keeps_frozen_zones_on_the_old_placement(self):
        from collections import Counter
        legacy = {503: Counter({1436: 2}), 7: Counter({1431: 5})}
        current = {503: Counter({1436: 2, 1431: 6}), 7: Counter({1431: 5}), 9: Counter({1436: 3})}
        homes = gen.assign_homes(legacy, current, frozenset({1436}))
        # 503: Westfall (frozen, old placement) and Duskwood (new placement);
        # 9: best zone is frozen under the new placement only, so no home.
        self.assertEqual([(7, 1431, 5), (503, 1431, 6), (503, 1436, 2)], homes)

    def test_best_zone_breaks_ties_on_the_lowest_map_id(self):
        self.assertEqual((1431, 4), gen.best_zone({1436: 4, 1431: 4, 1433: 1}))


class Kinds(unittest.TestCase):
    def tpl(self, **kw):
        t = {"rank": 0, "flags_extra": 0, "type": 1, "minlevel": 10, "maxlevel": 11}
        t.update(kw)
        return t

    def test_creature_kind_never_returns_legendary(self):
        cases = [
            (self.tpl(rank=3), False, False, ("boss", 4)),
            (self.tpl(flags_extra=gen.FLAG_EXTRA_DUNGEON_BOSS), False, False, ("boss", 4)),
            (self.tpl(), False, True, ("boss", 4)),
            (self.tpl(rank=1), False, False, ("elite", 3)),
            (self.tpl(rank=4), False, False, ("rare", 3)),
            (self.tpl(), True, False, ("npc", 1)),
            (self.tpl(type=8), True, False, ("creature", 1)),  # quest-giving critter
            (self.tpl(), False, False, ("creature", 1)),
        ]
        for t, npc, boss, want in cases:
            self.assertEqual(want, gen.creature_kind(t, npc, boss), (t, npc, boss))

    def test_creature_level_rounds_half_up(self):
        self.assertEqual(11, gen.creature_level(self.tpl()))
        self.assertEqual(60, gen.creature_level(self.tpl(minlevel=60, maxlevel=60)))

    def test_frozen_zones_only_see_frozen_dungeons(self):
        self.assertNotIn(718, gen.group_dungeon_areas(1412))  # Wailing Caverns from Mulgore
        self.assertIn(2437, gen.group_dungeon_areas(1411))    # Ragefire Chasm in Durotar
        self.assertIn(718, gen.group_dungeon_areas(1413))


class CrossZone(unittest.TestCase):
    def test_card_ref(self):
        self.assertEqual(("npc", 299), gen.card_ref(card()))
        self.assertEqual(("quest", 7), gen.card_ref({"id": "1:quest_7", "questID": 7}))
        self.assertEqual(("item", 9), gen.card_ref({"id": "1:item_9", "itemID": 9}))
        with self.assertRaises(ValueError):
            gen.card_ref({"id": "1:x"})

    def test_taken_by_other_zone_matches_ids_and_names_without_case(self):
        c = card()
        self.assertTrue(gen.taken_by_other_zone(c, {("npc", 299)}, set()))
        self.assertTrue(gen.taken_by_other_zone(c, set(), {"young wolf"}))
        self.assertFalse(gen.taken_by_other_zone(c, {("quest", 299)}, {"young wolf "}))


class HandWritten(unittest.TestCase):
    def setUp(self):
        import tempfile
        self.tmp = tempfile.TemporaryDirectory()
        self.repo = self.tmp.name
        os.makedirs(os.path.join(self.repo, "Data", "Kalimdor"))

    def tearDown(self):
        self.tmp.cleanup()

    def write(self, name, text):
        with open(os.path.join(self.repo, "Data", "Kalimdor", name), "w", encoding="utf-8") as h:
            h.write(text)

    def test_missing_file_warns_and_counts_no_card(self):
        warnings = []
        names, count, ids = gen.hand_written_names(self.repo, 1449, warn=warnings.append)
        self.assertEqual((set(), 0, set()), (names, count, ids))
        self.assertEqual(1, len(warnings))
        self.assertIn("UngoroCrater", warnings[0])
        self.assertIsNone(gen.hand_written_path(os.path.join(self.repo, "nowhere"), 1449))

    def test_file_name_matches_without_case(self):
        self.write("UnGoroCrater.lua", 'cards = {\n  { id = "1449:larkorwi", name = "Lar\'korwi" },\n'
                   '  { id = "1449:npc_6499", name = "Ironhide \\"Devil\\" saur" },\n}\n')
        names, count, ids = gen.hand_written_names(self.repo, 1449)
        self.assertEqual(2, count)
        self.assertEqual({"1449:larkorwi", "1449:npc_6499"}, ids)
        self.assertIn("lar'korwi", names)
        self.assertIn('ironhide \\"devil\\" saur', names)

    def test_a_directory_or_a_prefixed_name_is_not_the_zone_file(self):
        os.makedirs(os.path.join(self.repo, "Data", "Kalimdor", "UngoroCrater.lua"))
        self.write("UngoroCrater.lua.bak", 'cards = { { id = "1449:x", name = "X" } }')
        self.write("xUngoroCrater.lua", 'cards = { { id = "1449:y", name = "Y" } }')
        self.assertIsNone(gen.hand_written_path(self.repo, 1449))


class RemovedIds(unittest.TestCase):
    OLD = ('local _, ns = ...\n'
           'ns.Cards.addCards(1436, {\n'
           '  { id = "1436:npc_503", kind = "rare", rarity = 3, name = "Lord Malathrom" },\n'
           '  { id = "1436:quest_7", kind = "quest", rarity = 2, name = "Q" },\n'
           '}, "generated")\n')

    def test_reports_ids_the_new_cards_drop(self):
        self.assertEqual(["1436:npc_503"], gen.removed_ids(self.OLD, [{"id": "1436:quest_7"}]))

    def test_accepts_kept_and_added_ids(self):
        self.assertEqual([], gen.removed_ids(self.OLD, [
            {"id": "1436:npc_503"}, {"id": "1436:quest_7"}, {"id": "1436:item_9"}]))

    def test_still_sees_ids_of_a_reformatted_file(self):
        for text in ['\t{ id = "1436:npc_503" }', '    {id="1436:npc_503"}', '{\n  id = "1436:npc_503",\n}',
                     "{ id = '1436:npc_503' }", '{ ["id"] = "1436:npc_503" }', "{ ['id']='1436:npc_503' }",
                     '{ id = [[1436:npc_503]] }']:
            self.assertEqual(["1436:npc_503"], gen.removed_ids(text, []), repr(text))

    def test_does_not_mistake_a_creature_id_field_for_a_card_id(self):
        self.assertEqual([], gen.removed_ids('  { id = "1436:npc_503", npcID = 503 }', [{"id": "1436:npc_503"}]))


    def test_a_name_ending_in_id_fails_closed_without_hiding_the_real_id(self):
        text = '  { id = "1436:npc_503", name = "Squid id =", icon = "X" }'
        gone = gen.removed_ids(text, [{"id": "1436:npc_503"}])
        self.assertNotIn("1436:npc_503", gone)
        self.assertTrue(gone)  # the fake match makes main() refuse, never lose a card


class MainRefusal(unittest.TestCase):
    """main() must refuse before writing anything when a shipped card ID would go."""

    def setUp(self):
        import sys
        import tempfile
        self.tmp = tempfile.TemporaryDirectory()
        self.repo = self.tmp.name
        os.makedirs(os.path.join(self.repo, "Data", "Generated"))
        with open(os.path.join(self.repo, "Data", "Loaded.lua"), "w") as handle:
            handle.write('ns.Cards.EXPECTED_BATCHES = { "1436:generated" }\n')
        self.real_build, self.real_argv = gen.build, sys.argv
        gen.build = lambda sql, repo, report: {z: ([], 0, 0) for z in gen.ZONE_ORDER}

    def tearDown(self):
        import sys
        gen.build, sys.argv = self.real_build, self.real_argv
        self.tmp.cleanup()

    def run_main(self, *flags):
        import sys
        sys.argv = ["generate-cards.py", "unused-sql", "--repo", self.repo] + list(flags)
        gen.main()

    def generated(self):
        return sorted(os.listdir(os.path.join(self.repo, "Data", "Generated")))

    def test_refuses_when_a_shipped_zone_file_is_missing(self):
        with self.assertRaises(SystemExit):
            self.run_main()
        self.assertEqual([], self.generated())

    def test_refuses_when_an_id_would_disappear_and_writes_nothing(self):
        path = os.path.join(self.repo, "Data", "Generated", "Westfall.lua")
        with open(path, "w") as handle:
            handle.write('  { id = "1436:npc_503", name = "Lord Malathrom" },\n')
        with self.assertRaises(SystemExit):
            self.run_main()
        self.assertEqual(["Westfall.lua"], self.generated())
        with open(path) as handle:
            self.assertIn("1436:npc_503", handle.read())

    def test_writes_with_allow_removed_ids(self):
        self.run_main("--allow-removed-ids")
        self.assertEqual(len(gen.ZONE_ORDER), len(self.generated()))

    def test_refusal_writes_no_locale_file_either(self):
        with self.assertRaises(SystemExit):
            self.run_main("--locale-folder", "unused-locale")
        self.assertFalse(os.path.exists(os.path.join(self.repo, "Locales")))


def sql_dump(table, columns, rows):
    """A minimal AzerothCore-style dump: CREATE TABLE, then one INSERT."""
    def value(v):
        return str(v) if isinstance(v, int) else "'" + v.replace("\\", "\\\\").replace("'", "\\'") + "'"
    create = "CREATE TABLE `%s` (\n%s\n) ENGINE=InnoDB;\n" % (
        table, ",\n".join("  `%s` text" % c for c in columns))
    values = ",".join("(" + ",".join(value(v) for v in row) + ")" for row in rows)
    return create + "INSERT INTO `%s` VALUES %s;\n" % (table, values)


class MainLocale(unittest.TestCase):
    """main() --locale-folder writes Locales/frFR_Generated.lua from the dumps,
    and a hostile value in a dump never reaches it."""

    def setUp(self):
        import sys
        import tempfile
        self.tmp = tempfile.TemporaryDirectory()
        self.repo = os.path.join(self.tmp.name, "repo")
        self.sql = os.path.join(self.tmp.name, "sql")
        os.makedirs(os.path.join(self.repo, "Data", "Generated"))
        os.makedirs(self.sql)
        dumps = {
            "creature_template": (["entry", "name"], [(299, "Young Wolf"), (300, "Evil Wolf")]),
            "creature_template_locale": (["entry", "locale", "Name"], [
                (299, "deDE", "Junger Wolf"), (299, "frFR", "Jeune loup"),
                (300, "frFR", "Loup|cffff0000 rouge|r")]),
            "quest_template_locale": (["ID", "locale", "Title"], [
                (7, "frFR", "Faim\u00a0!"), (8, "frFR", "Soif\u200b!")]),
            "item_template_locale": (["ID", "locale", "Name"], [(2933, "frFR", 'Sceau "de" Wrynn\\')]),
        }
        for table, (columns, rows) in dumps.items():
            with open(os.path.join(self.sql, table + ".sql"), "w", encoding="utf-8") as handle:
                handle.write(sql_dump(table, columns, rows))
        cards = [card(id="1436:npc_299"), card(id="1436:npc_300", entry=300, name="Evil Wolf"),
                 {"id": "1436:quest_7", "kind": "quest", "rarity": 2, "name": "Hungry!",
                  "icon": "INV_Misc_Note_01", "questID": 7, "level": 5},
                 {"id": "1436:quest_8", "kind": "quest", "rarity": 2, "name": "Thirsty!",
                  "icon": "INV_Misc_Note_01", "questID": 8, "level": 5},
                 {"id": "1436:item_2933", "kind": "item", "rarity": 3, "name": "Seal of Wrynn",
                  "icon": "INV_Misc_Bag_08", "itemID": 2933}]
        self.real_build, self.real_argv = gen.build, sys.argv
        gen.build = lambda sql, repo, report: {z: (cards if z == 1436 else [], 0, 0) for z in gen.ZONE_ORDER}

    def tearDown(self):
        import sys
        gen.build, sys.argv = self.real_build, self.real_argv
        self.tmp.cleanup()

    def test_writes_clean_french_names_only(self):
        import sys
        sys.argv = ["generate-cards.py", self.sql, "--repo", self.repo, "--locale-folder", self.sql]
        gen.main()
        with open(os.path.join(self.repo, "Locales", "frFR_Generated.lua"), encoding="utf-8") as handle:
            text = handle.read()
        body = [line for line in text.split("\n") if line.startswith("L[")]
        # The no-break space of "Faim !" becomes a plain space; the zero-width
        # space of the second title refuses it.
        self.assertEqual(['L["Hungry!"] = "Faim !"', 'L["Seal of Wrynn"] = "Sceau \\"de\\" Wrynn\\\\"',
                          'L["Young Wolf"] = "Jeune loup"'], body)
        for absent in ("Evil Wolf", "|", "Thirsty", "\u00a0", "\u200b", "Junger"):
            self.assertNotIn(absent, text)


class ShippedZones(unittest.TestCase):
    def test_reads_the_generated_batches_of_loaded_lua(self):
        text = 'ns.Cards.EXPECTED_BATCHES = {\n  "1411:generated", "1436:generated",\n}\n'
        self.assertEqual({1411, 1436}, gen.shipped_zones(text))

    def test_ignores_other_batches_and_zone_lists(self):
        self.assertEqual(set(), gen.shipped_zones('EXPECTED_ZONES = { 1411 }\n"1411:extra"'))


if __name__ == "__main__":
    unittest.main()
