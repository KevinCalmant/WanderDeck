local _, ns = ...

-- Blasted Lands signature cards. uiMapID 1419 from the Classic UiMapID table
-- (warcraft.wiki.gg), as listed in the "## uiMapIDs" table of the research note;
-- not yet probed on Forever. Candidates and sources: docs/research/04-southern-eastern-kingdoms.md.
-- Icons are from the validated list.
ns.Cards.registerZone({
  zoneMapID = 1419,
  continentMapID = 1415,
  cards = {
    { id = "1419:lord_kazzak", kind = "boss", rarity = 5, name = "Lord Kazzak", npcID = 12397, icon = "Spell_Shadow_SummonImp",
      flavor = "The demon lord whose shadow lies over the whole wasteland." },
    { id = "1419:the_dark_portal", kind = "place", rarity = 4, name = "The Dark Portal", icon = "Spell_Shadow_Twilight", areaID = 72,
      flavor = "A gateway to another world, held by demons." },
    { id = "1419:teremus_the_devourer", kind = "boss", rarity = 4, name = "Teremus the Devourer", npcID = 7846, icon = "Spell_Fire_Volcano",
      flavor = "A black dragon that a small group can still bring down." },
    { id = "1419:archmage_allistarj", kind = "npc", rarity = 3, name = "Archmage Allistarj", npcID = 7666, icon = "Spell_Holy_HolySmite",
      flavor = "A named mage found out here in the wastes." },
    { id = "1419:grunter", kind = "rare", rarity = 3, name = "Grunter", npcID = 8303, icon = "Ability_Hunter_Pet_Boar",
      flavor = "A rare boar with a bad temper." },
    { id = "1419:spiteflayer", kind = "rare", rarity = 3, name = "Spiteflayer", npcID = 8299, icon = "Ability_Hunter_Pet_Vulture",
      flavor = "A rare carrion bird circling above the dust." },
    { id = "1419:nethergarde_keep", kind = "place", rarity = 2, name = "Nethergarde Keep", icon = "INV_Shield_06", areaID = 1438,
      flavor = "The Alliance fort and the only settlement out here." },
    { id = "1419:dreadmaul_hold", kind = "place", rarity = 2, name = "Dreadmaul Hold", icon = "INV_Misc_Head_Gnoll_01", areaID = 1437,
      flavor = "An ogre stronghold in the south, ruled by brute force." },
    { id = "1419:basilisk", kind = "creature", rarity = 1, name = "Basilisk", npcID = 5990, icon = "Ability_Hunter_Pet_Scorpid",
      flavor = "Stone-eyed lizards crawling over the scorched ground." },
    { id = "1419:dreadmaul_ogre", kind = "creature", rarity = 1, name = "Dreadmaul Ogre", npcID = 5974, icon = "Ability_ThunderClap",
      flavor = "An ogre that serves Grol the Destroyer." },
  },
})
