local _, ns = ...

-- Westfall. uiMapID 1436 confirmed by /wd probe on Forever. Names are English
-- localization keys; flavor text is original.
-- Rarity: 1 Common, 2 Uncommon, 3 Rare, 4 Epic, 5 Legendary.
-- icon: an Interface\Icons file name, unverified on Forever (check with /wd art).
ns.Cards.registerZone({
  zoneMapID = 1436,
  continentMapID = 1415,
  cards = {
    { id = "1436:harvest_watcher", kind = "creature", rarity = 1, name = "Harvest Watcher", npcID = 114, icon = "INV_Misc_Gear_01",
      flavor = "The scarecrow now guards the fields for someone else." },
    { id = "1436:fleshripper", kind = "creature", rarity = 1, name = "Fleshripper", npcID = 1109, icon = "Ability_Hunter_Pet_Vulture",
      flavor = "Circles patiently above the dry plains." },
    { id = "1436:riverpaw_gnoll", kind = "creature", rarity = 1, name = "Riverpaw Gnoll", npcID = 117, icon = "INV_Misc_Head_Gnoll_01",
      flavor = "The Riverpaw roam far beyond their river." },
    { id = "1436:defias_trapper", kind = "creature", rarity = 1, name = "Defias Trapper", npcID = 504, icon = "INV_Misc_Bandana_03",
      flavor = "Sets snares along the roads at dusk." },
    { id = "1436:dust_devil", kind = "creature", rarity = 1, name = "Dust Devil", npcID = 832, icon = "Spell_Nature_Cyclone",
      flavor = "A whirl of sand that remembers being wind." },
    { id = "1436:sentinel_hill", kind = "place", rarity = 2, name = "Sentinel Hill", icon = "Ability_Warrior_DefensiveStance", areaID = 108,
      flavor = "The People's Militia holds the line from this hill." },
    { id = "1436:moonbrook", kind = "place", rarity = 2, name = "Moonbrook", icon = "Spell_Shadow_Twilight", areaID = 20,
      flavor = "A town left to the Defias." },
    { id = "1436:saldeans_farm", kind = "place", rarity = 2, name = "Saldean's Farm", icon = "INV_Misc_Food_Wheat_01", areaID = 107,
      flavor = "Still standing, still farming, still hoping." },
    { id = "1436:jangolode_mine", kind = "place", rarity = 2, name = "Jangolode Mine", icon = "Trade_Mining", areaID = 111,
      flavor = "A quiet entrance, busy shadows." },
    { id = "1436:gryan_stoutmantle", kind = "npc", rarity = 5, name = "Gryan Stoutmantle", npcID = 234, icon = "Ability_Warrior_BattleShout",
      flavor = "Founder of the People's Militia, stubborn as stone." },
    { id = "1436:foe_reaper_4000", kind = "rare", rarity = 3, name = "Foe Reaper 4000", npcID = 573, icon = "INV_Misc_Gear_01",
      flavor = "A harvest golem that reaps more than wheat." },
    { id = "1436:leprithus", kind = "rare", rarity = 3, name = "Leprithus", npcID = 572, icon = "Spell_Shadow_RaiseDead",
      flavor = "Rises from the soil when night falls on Westfall." },
    { id = "1436:old_murk_eye", kind = "elite", rarity = 4, name = "Old Murk-Eye", npcID = 391, icon = "INV_Misc_Head_Murloc_01",
      flavor = "The oldest murloc on the coast, and the grumpiest." },
    { id = "1436:the_deadmines", kind = "place", rarity = 4, name = "The Deadmines", icon = "INV_Misc_Bomb_02", loadScreen = "LoadScreenDeadmines", areaID = 1581,
      flavor = "Beneath Moonbrook, a ship waits in the dark." },
    { id = "1436:edwin_vancleef", kind = "boss", rarity = 5, name = "Edwin VanCleef", npcID = 639, icon = "Ability_Rogue_Ambush",
      flavor = "The stonemason who became the Defias kingpin." },
  },
})
