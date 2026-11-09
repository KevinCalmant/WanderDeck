local _, ns = ...

-- Burning Steppes signature cards. uiMapID 1428 from the Classic UiMapID table
-- (warcraft.wiki.gg), as listed in the "## uiMapIDs" table of the research note;
-- not yet probed on Forever. Candidates and sources: docs/research/02-dun-morogh-to-burning-steppes.md.
-- Icons are from the validated list.
ns.Cards.registerZone({
  zoneMapID = 1428,
  continentMapID = 1415,
  cards = {
    { id = "1428:emperor_dagran_thaurissan", kind = "boss", rarity = 5, name = "Emperor Dagran Thaurissan", npcID = 9019, icon = "Spell_Fire_Volcano",
      flavor = "The Dark Iron ruler on the throne at the bottom of the mountain." },
    { id = "1428:warchief_rend_blackhand", kind = "boss", rarity = 5, name = "Warchief Rend Blackhand", npcID = 10429, icon = "INV_Sword_04",
      flavor = "The orc warchief waiting at the top of the Spire." },
    { id = "1428:hematos", kind = "elite", rarity = 4, name = "Hematos", npcID = 8976, icon = "Ability_Hunter_Pet_Scorpid",
      flavor = "A level 60 rare elite that haunts the red steppe." },
    { id = "1428:bannok_grimaxe", kind = "rare", rarity = 3, name = "Bannok Grimaxe", npcID = 9596, icon = "INV_Weapon_Bow_02",
      flavor = "A rare elite fighter inside the Spire." },
    { id = "1428:gruklash", kind = "rare", rarity = 3, name = "Gruklash", npcID = 8979, icon = "Ability_Warrior_BattleShout",
      flavor = "A rare level 59 brute of the burning steppe." },
    { id = "1428:grark_lorkrub", kind = "npc", rarity = 3, name = "Grark Lorkrub", npcID = 9520, icon = "INV_Misc_Head_Troll_01",
      flavor = "A captive orc tied to a quest from Searing Gorge." },
    { id = "1428:blackrock_depths", kind = "place", rarity = 2, name = "Blackrock Depths", icon = "Spell_Fire_Volcano", loadScreen = "LoadScreenBlackrockDepths", areaID = 1584,
      flavor = "A dungeon of Dark Iron halls inside Blackrock Mountain." },
    { id = "1428:blackrock_spire", kind = "place", rarity = 2, name = "Blackrock Spire", icon = "INV_Misc_Gear_01", loadScreen = "LoadScreenBlackrockSpire", areaID = 1583,
      flavor = "A dungeon rising through the mountain's upper halls." },
    { id = "1428:ember_worg", kind = "creature", rarity = 1, name = "Ember Worg", npcID = 9690, icon = "Ability_Hunter_Pet_Wolf",
      flavor = "A wolf-type beast with coals under its fur." },
    { id = "1428:flamescale_broodling", kind = "creature", rarity = 1, name = "Flamescale Broodling", npcID = 7049, icon = "Spell_Fire_Incinerate",
      flavor = "A drakeling of the red brood, small but hot." },
  },
})
