local _, ns = ...

-- Silithus, with its dungeons folded in. uiMapID 1451 from the Classic UiMapID table
-- (warcraft.wiki.gg/wiki/UiMapID); Kalimdor 1414 from memory. Not yet probed on Forever.
-- Candidates and sources: docs/research/06-central-southern-kalimdor.md.
ns.Cards.registerZone({
  zoneMapID = 1451,
  continentMapID = 1414,
  cards = {
    { id = "1451:prince_thunderaan", kind = "boss", rarity = 5, name = "Prince Thunderaan", npcID = 14435, icon = "Spell_Nature_Cyclone",
      flavor = "The wind lord that a Highlord's mission aims to confront." },
    { id = "1451:cenarion_hold", kind = "place", rarity = 4, name = "Cenarion Hold", icon = "Spell_Nature_Tranquility", areaID = 3425,
      flavor = "The major settlement of the Cenarion Circle in the sands." },
    { id = "1451:hiveashi", kind = "place", rarity = 4, name = "Hive'Ashi", icon = "Ability_Hunter_Pet_Spider", areaID = 2742,
      flavor = "One of the silithid hives that crawl across the desert." },
    { id = "1451:brann_bronzebeard", kind = "npc", rarity = 5, name = "Brann Bronzebeard", icon = "INV_Misc_Head_Dwarf_01",
      flavor = "A famous explorer whose whereabouts are unknown." },
    { id = "1451:rex_ashil", kind = "rare", rarity = 3, name = "Rex Ashil", npcID = 14475, icon = "Spell_Nature_Cyclone",
      flavor = "A rare of the dunes, named only in old spawn lists." },
    { id = "1451:setis", kind = "rare", rarity = 3, name = "Setis", npcID = 14471, icon = "Ability_Hunter_Pet_Scorpid",
      flavor = "A rare of the dunes that hunters hope to find." },
    { id = "1451:bronzebeard_encampment", kind = "place", rarity = 2, name = "Bronzebeard Encampment", icon = "Trade_Mining", areaID = 3427,
      flavor = "A dwarven dig camp in the middle of the sands." },
    { id = "1451:twilights_run", kind = "place", rarity = 2, name = "Twilight's Run", icon = "Spell_Shadow_Twilight", areaID = 3446,
      flavor = "A contested subzone listed on the zone page." },
    { id = "1451:silithid", kind = "creature", rarity = 1, name = "Silithid", npcID = 11728, icon = "Ability_Hunter_Pet_Scorpid",
      flavor = "An insectoid creature that swarms over the desert." },
    { id = "1451:air_elemental", kind = "creature", rarity = 1, name = "Air Elemental", npcID = 11744, icon = "Spell_Nature_Cyclone",
      flavor = "A wind spirit drifting over the sand." },
  },
})
