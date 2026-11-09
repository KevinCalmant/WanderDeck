local _, ns = ...

-- Ashenvale: hand-written signature cards. uiMapID 1440 from the Classic table of
-- https://warcraft.wiki.gg/wiki/UiMapID; Kalimdor 1414. Not yet probed on Forever.
-- Sources in docs/research/05-northern-kalimdor.md. Icons from the validated list.
ns.Cards.registerZone({
  zoneMapID = 1440,
  continentMapID = 1414,
  cards = {
    { id = "1440:akumai", kind = "boss", rarity = 5, name = "Aku'mai", npcID = 4829, icon = "Spell_Nature_Cyclone",
      flavor = "The giant hydra waiting at the end of the flooded temple." },
    { id = "1440:blackfathom_deeps", kind = "place", rarity = 4, name = "Blackfathom Deeps", icon = "Spell_Frost_FrostArmor02", areaID = 2797,
      flavor = "A flooded temple dungeon at the Zoram Strand." },
    { id = "1440:ghamoo_ra", kind = "boss", rarity = 3, name = "Ghamoo-Ra", npcID = 4887, icon = "Ability_Warrior_DefensiveStance",
      flavor = "A giant turtle, first boss of the drowned temple." },
    { id = "1440:geltharis", kind = "npc", rarity = 3, name = "Geltharis", npcID = 4619, icon = "INV_Misc_Head_Dwarf_01",
      flavor = "A named level 32 figure of the Ashenvale woods." },
    { id = "1440:prince_raze", kind = "rare", rarity = 3, name = "Prince Raze", npcID = 10647, icon = "Spell_Shadow_SummonImp",
      flavor = "A rare with a title far too big for him." },
    { id = "1440:astranaar", kind = "place", rarity = 2, name = "Astranaar", icon = "INV_Misc_Gear_01", areaID = 415,
      flavor = "The night elf town and main hub of the forest." },
    { id = "1440:zoramgar_outpost", kind = "place", rarity = 2, name = "Zoram'gar Outpost", icon = "INV_BannerPVP_01", areaID = 2897,
      flavor = "A Horde outpost near the dungeon entrance." },
    { id = "1440:thistlefur_totemic", kind = "creature", rarity = 1, name = "Thistlefur Totemic", npcID = 3922, icon = "Spell_Nature_LightningShield",
      flavor = "A furbolg spellcaster chanting under the trees." },
    { id = "1440:satyr", kind = "creature", rarity = 1, name = "Satyr", npcID = 3758, icon = "Spell_Shadow_SummonImp",
      flavor = "A demon-tainted, horned raider of the forest." },
  },
})
