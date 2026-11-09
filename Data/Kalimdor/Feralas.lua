local _, ns = ...

-- Feralas, with its dungeons folded in. uiMapID 1444 from the Classic UiMapID table
-- (warcraft.wiki.gg/wiki/UiMapID); Kalimdor 1414 from memory. Not yet probed on Forever.
-- Candidates and sources: docs/research/06-central-southern-kalimdor.md.
ns.Cards.registerZone({
  zoneMapID = 1444,
  continentMapID = 1414,
  cards = {
    { id = "1444:general_shandris_feathermoon", kind = "npc", rarity = 5, name = "General Shandris Feathermoon", npcID = 3936, icon = "Spell_Nature_MoonGlow",
      flavor = "The night elf general who defends the fortress on the island." },
    { id = "1444:alzzin_the_wildshaper", kind = "boss", rarity = 4, name = "Alzzin the Wildshaper", npcID = 11492, icon = "Spell_Nature_Rejuvenation",
      flavor = "A satyr boss who rules the eastern wing of Dire Maul." },
    { id = "1444:prince_tortheldrin", kind = "boss", rarity = 4, name = "Prince Tortheldrin", npcID = 11486, icon = "Spell_Shadow_ShadowWordPain",
      flavor = "A hostile elven noble who holds the western wing of Dire Maul." },
    { id = "1444:dire_maul", kind = "place", rarity = 3, name = "Dire Maul", icon = "INV_Sword_04", loadScreen = "LoadScreenDireMaul", areaID = 2577,
      flavor = "A ruined elven city that now serves as a dungeon in Feralas." },
    { id = "1444:king_gordok", kind = "boss", rarity = 4, name = "King Gordok", npcID = 11501, icon = "INV_Misc_Bandana_03",
      flavor = "The ogre ruler of the northern wing of Dire Maul." },
    { id = "1444:lady_szallah", kind = "rare", rarity = 3, name = "Lady Szallah", npcID = 5343, icon = "Ability_Hunter_Pet_Cat",
      flavor = "A rare of the jungle, listed among the zone's elusive spawns." },
    { id = "1444:camp_mojache", kind = "place", rarity = 2, name = "Camp Mojache", icon = "INV_Misc_Head_Tauren_01", areaID = 1099,
      flavor = "A tauren camp in the jungle of the western part of the zone." },
    { id = "1444:feathermoon_stronghold", kind = "place", rarity = 2, name = "Feathermoon Stronghold", icon = "Spell_Holy_ElunesGrace", areaID = 1116,
      flavor = "A night elf island fortress watching over the coast." },
    { id = "1444:gorilla", kind = "creature", rarity = 1, name = "Gorilla", npcID = 5260, icon = "Ability_Hunter_Pet_Bear",
      flavor = "A jungle ape that roams the green hills." },
    { id = "1444:yeti", kind = "creature", rarity = 1, name = "Yeti", npcID = 5292, icon = "Ability_Hunter_Pet_Bear",
      flavor = "A shaggy beast of the high ground, white and heavy." },
  },
})
