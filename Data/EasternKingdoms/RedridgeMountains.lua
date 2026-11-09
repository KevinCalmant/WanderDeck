local _, ns = ...

-- Redridge Mountains signature cards. uiMapID 1433 from the Classic UiMapID table
-- (warcraft.wiki.gg), as listed in the "## uiMapIDs" table of the research note;
-- not yet probed on Forever. Candidates and sources: docs/research/01-elwynn-to-stranglethorn.md.
-- Icons are from the validated list.
ns.Cards.registerZone({
  zoneMapID = 1433,
  continentMapID = 1415,
  cards = {
    { id = "1433:magistrate_solomon", kind = "npc", rarity = 5, name = "Magistrate Solomon", npcID = 344, icon = "Spell_Holy_SealOfMight",
      flavor = "Every errand in Lakeshire ends at his desk sooner or later." },
    { id = "1433:blackrock_sentry", kind = "elite", rarity = 4, name = "Blackrock Sentry", npcID = 4065, icon = "Ability_Warrior_DefensiveStance",
      flavor = "An orc guard who does not take kindly to visitors." },
    { id = "1433:renders_valley", kind = "place", rarity = 4, name = "Render's Valley", icon = "Spell_Fire_Incinerate", areaID = 997,
      flavor = "A dark valley where the Blackrock orcs have dug in." },
    { id = "1433:boulderheart", kind = "rare", rarity = 3, name = "Boulderheart", npcID = 14273, icon = "Spell_Nature_Earthquake",
      flavor = "A rare giant with a heart of rock and no manners." },
    { id = "1433:rohh_the_silent", kind = "rare", rarity = 3, name = "Rohh the Silent", npcID = 947, icon = "Ability_Hunter_Pet_Wolf",
      flavor = "True to his name: he never announces himself." },
    { id = "1433:lakeshire", kind = "place", rarity = 2, name = "Lakeshire", icon = "INV_Drink_05", areaID = 69,
      flavor = "The lakeside town every traveler passes through." },
    { id = "1433:three_corners", kind = "place", rarity = 2, name = "Three Corners", icon = "INV_BannerPVP_01", areaID = 1002,
      flavor = "A crossroads outpost with Tower Watch keeping an eye on it." },
    { id = "1433:redridge_brute", kind = "creature", rarity = 1, name = "Redridge Brute", npcID = 426, icon = "Ability_Hunter_Pet_Bear",
      flavor = "A heavy gnoll who hits first and asks nothing." },
    { id = "1433:redridge_alpha", kind = "creature", rarity = 1, name = "Redridge Alpha", npcID = 445, icon = "INV_Misc_Head_Gnoll_01",
      flavor = "The pack leader, and the pack knows it." },
  },
})
