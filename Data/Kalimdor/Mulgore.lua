local _, ns = ...

-- Mulgore, with Thunder Bluff folded in. uiMapID 1412 from the Classic
-- UiMapID table (warcraft.wiki.gg); Kalimdor 1414 from memory. Not yet probed
-- on Forever. Sources in docs/research/06-central-southern-kalimdor.md.
-- Icons unverified: /wd art.
ns.Cards.registerZone({
  zoneMapID = 1412,
  continentMapID = 1414,
  cards = {
    { id = "1412:plainstrider", kind = "creature", rarity = 1, name = "Plainstrider", icon = "Ability_Hunter_Pet_TallStrider",
      flavor = "Long legs, short temper, endless grass." },
    { id = "1412:prairie_wolf", kind = "creature", rarity = 1, name = "Prairie Wolf", icon = "Ability_Hunter_Pet_Wolf",
      flavor = "It follows the herds and waits." },
    { id = "1412:bristleback_quilboar", kind = "creature", rarity = 1, name = "Bristleback Quilboar", icon = "INV_Misc_Head_Quillboar_01",
      flavor = "Quills up, and camped too close to the village." },
    { id = "1412:battleboar", kind = "creature", rarity = 1, name = "Battleboar", icon = "Ability_Hunter_Pet_Boar",
      flavor = "Young tauren learn to hunt on these." },
    { id = "1412:mountain_cougar", kind = "creature", rarity = 1, name = "Mountain Cougar", icon = "Ability_Hunter_Pet_Cat",
      flavor = "It hunts from the ridges above the plains." },
    { id = "1412:camp_narache", kind = "place", rarity = 2, name = "Camp Narache", icon = "INV_Misc_Pelt_Wolf_01",
      flavor = "Tents and drums where young tauren begin." },
    { id = "1412:bloodhoof_village", kind = "place", rarity = 2, name = "Bloodhoof Village", icon = "INV_Misc_Horn_01",
      flavor = "Smoke, totems, and a welcome for travelers." },
    { id = "1412:baeldun_digsite", kind = "place", rarity = 2, name = "Bael'dun Digsite", icon = "Trade_Mining",
      flavor = "Dwarves digging where they were not invited." },
    { id = "1412:venture_co_mine", kind = "place", rarity = 2, name = "Venture Co. Mine", icon = "Trade_Mining",
      flavor = "Goblins drilling into sacred ground." },
    { id = "1412:chief_hawkwind", kind = "npc", rarity = 4, name = "Chief Hawkwind", icon = "Ability_Warrior_BattleShout",
      flavor = "He sends the young out to prove themselves." },
    { id = "1412:mull_thunderhorn", kind = "npc", rarity = 2, name = "Mull Thunderhorn", icon = "Spell_Nature_MagicImmunity",
      flavor = "He keeps the wells of Mulgore clean." },
    { id = "1412:baine_bloodhoof", kind = "npc", rarity = 4, name = "Baine Bloodhoof", icon = "INV_Misc_Head_Tauren_01",
      flavor = "The chieftain's son, already a leader." },
    { id = "1412:the_rake", kind = "rare", rarity = 3, name = "The Rake", icon = "Ability_Hunter_Pet_Cat",
      flavor = "A lone lion the hunters talk about." },
    { id = "1412:thunder_bluff", kind = "place", rarity = 4, name = "Thunder Bluff", icon = "Ability_ThunderClap",
      flavor = "A city on the mesas, joined by rope bridges." },
    { id = "1412:cairne_bloodhoof", kind = "lore", rarity = 5, name = "Cairne Bloodhoof", icon = "INV_Misc_Head_Tauren_01",
      flavor = "The High Chieftain, wise and slow to anger." },
    { id = "1412:magatha_grimtotem", kind = "npc", rarity = 4, name = "Magatha Grimtotem", icon = "INV_Misc_Head_Tauren_01",
      flavor = "Cunning Grimtotem matriarch on Elder Rise, long a rival of Cairne for the tauren's leadership." },
    { id = "1412:hamuul_runetotem", kind = "npc", rarity = 4, name = "Hamuul Runetotem", icon = "Spell_Nature_Regenerate",
      flavor = "Archdruid of Thunder Bluff, taught by Malfurion himself and a leader of the tauren druids." },
  },
})
