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
        for text in ["Evil\n", "a|cff", ""]:
            with self.assertRaises(ValueError):
                gen.lua_string(text)


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
        for text in ['\t{ id = "1436:npc_503" }', '    {id="1436:npc_503"}', '{\n  id = "1436:npc_503",\n}']:
            self.assertEqual(["1436:npc_503"], gen.removed_ids(text, []), repr(text))

    def test_does_not_mistake_a_creature_id_field_for_a_card_id(self):
        self.assertEqual([], gen.removed_ids('  { id = "1436:npc_503", npcID = 503 }', [{"id": "1436:npc_503"}]))


class ShippedZones(unittest.TestCase):
    def test_reads_the_generated_batches_of_loaded_lua(self):
        text = 'ns.Cards.EXPECTED_BATCHES = {\n  "1411:generated", "1436:generated",\n}\n'
        self.assertEqual({1411, 1436}, gen.shipped_zones(text))

    def test_ignores_other_batches_and_zone_lists(self):
        self.assertEqual(set(), gen.shipped_zones('EXPECTED_ZONES = { 1411 }\n"1411:extra"'))


if __name__ == "__main__":
    unittest.main()
