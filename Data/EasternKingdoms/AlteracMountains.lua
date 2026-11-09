local _, ns = ...

-- Alterac Mountains. uiMapID 1416 from the Classic UiMapID table (warcraft.wiki.gg); not yet
-- probed on Forever. Candidates and sources in docs/research/03-tirisfal-to-plaguelands.md
-- Icons from the list validated in game.
ns.Cards.registerZone({
  zoneMapID = 1416,
  continentMapID = 1415,
  cards = {
    { id = "1416:dalaran_crater", kind = "place", rarity = 5, name = "Dalaran Crater", icon = "Spell_Frost_Frostbolt02",
      flavor = "A wide crater where a city of mages once stood." },
    { id = "1416:alterac_valley", kind = "place", rarity = 4, name = "Alterac Valley", icon = "INV_BannerPVP_01", areaID = 2839,
      flavor = "A northern valley where two armies fight for the pass." },
    { id = "1416:warmaster_laggrond", kind = "npc", rarity = 4, name = "Warmaster Laggrond", npcID = 13840, icon = "Ability_Warrior_WarCry",
      flavor = "A Horde war leader tied to the fight in the valley." },
    { id = "1416:narillasanz", kind = "rare", rarity = 3, name = "Narillasanz", npcID = 2447, icon = "Spell_Frost_FrostArmor02",
      flavor = "The one rare listed for these cold mountains." },
    { id = "1416:lord_jorach_ravenholdt", kind = "npc", rarity = 4, name = "Lord Jorach Ravenholdt", npcID = 6768, icon = "Ability_Rogue_Ambush",
      flavor = "The master of a rogue house that prefers the shadows." },
    { id = "1416:ravenholdt_manor", kind = "place", rarity = 3, name = "Ravenholdt Manor", icon = "Ability_Rogue_Ambush", areaID = 3486,
      flavor = "A hideout where rogues trade secrets and blades." },
    { id = "1416:ruins_of_alterac", kind = "place", rarity = 2, name = "Ruins of Alterac", icon = "INV_Misc_Gear_01", areaID = 281,
      flavor = "The wrecked capital of a fallen kingdom." },
    { id = "1416:crushridge_hold", kind = "place", rarity = 2, name = "Crushridge Hold", icon = "INV_Misc_Head_Gnoll_01", areaID = 282,
      flavor = "An ogre stronghold cut into the rock." },
    { id = "1416:yeti", kind = "creature", rarity = 1, name = "Yeti", npcID = 2250, icon = "Ability_Hunter_Pet_Bear",
      flavor = "A snow ape that rules the high slopes." },
    { id = "1416:mountain_lion", kind = "creature", rarity = 1, name = "Mountain Lion", npcID = 2406, icon = "Ability_Hunter_Pet_Cat",
      flavor = "An alpine hunter with quiet paws." },
    { id = "1416:archmage_ansirem_runeweaver", kind = "npc", rarity = 4, name = "Archmage Ansirem Runeweaver", npcID = 2543, icon = "Spell_Frost_Frostbolt02",
      flavor = "A Dalaran archmage who stayed by the crater, still searching for his lost daughter." },
  },
})
