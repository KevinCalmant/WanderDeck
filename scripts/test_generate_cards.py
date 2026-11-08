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


if __name__ == "__main__":
    unittest.main()
