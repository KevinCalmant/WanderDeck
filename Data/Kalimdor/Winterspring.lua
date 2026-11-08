local _, ns = ...

-- Winterspring: hand-written signature cards. uiMapID 1452 from the Classic table of
-- https://warcraft.wiki.gg/wiki/UiMapID; Kalimdor 1414. Not yet probed on Forever.
-- Sources in docs/research/05-northern-kalimdor.md. Icons from the validated list.
ns.Cards.registerZone({
  zoneMapID = 1452,
  continentMapID = 1414,
  cards = {
    { id = "1452:high_chief_winterfall", kind = "elite", rarity = 5, name = "High Chief Winterfall", icon = "INV_Misc_Head_Tauren_01",
      flavor = "An elite furbolg chief, hunted by quest at level 59." },
    { id = "1452:mazthoril", kind = "place", rarity = 4, name = "Mazthoril", icon = "Spell_Frost_FrostArmor02",
      flavor = "A ruined site flagged as an elite area." },
    { id = "1452:haleh", kind = "npc", rarity = 4, name = "Haleh", icon = "Spell_Fire_Incinerate",
      flavor = "A matron who sends adventurers into dragon lairs." },
    { id = "1452:donova_snowden", kind = "npc", rarity = 3, name = "Donova Snowden", icon = "Spell_Frost_Frostbolt02",
      flavor = "A level 50 quest giver who points you at Winterfall." },
    { id = "1452:rivern_frostwind", kind = "npc", rarity = 3, name = "Rivern Frostwind", icon = "Ability_Hunter_Pet_Cat",
      flavor = "A trainer who cares for frostsaber pets." },
    { id = "1452:everlook", kind = "place", rarity = 2, name = "Everlook", icon = "INV_Misc_Coin_01",
      flavor = "A goblin trading town, the capital of the snows." },
    { id = "1452:starfall_village", kind = "place", rarity = 2, name = "Starfall Village", icon = "Spell_Nature_StarFall",
      flavor = "A night elf settlement among the pines." },
    { id = "1452:frostsaber", kind = "creature", rarity = 1, name = "Frostsaber", icon = "Ability_Hunter_Pet_Cat",
      flavor = "A big cat of the snows, level 56 or so." },
    { id = "1452:ice_thistle_yeti", kind = "creature", rarity = 1, name = "Ice Thistle Yeti", icon = "Spell_Frost_FrostArmor02",
      flavor = "A yeti of the Ice Thistle Hills." },
  },
})
