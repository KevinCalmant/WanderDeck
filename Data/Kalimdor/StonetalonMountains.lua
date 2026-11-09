local _, ns = ...

-- StonetalonMountains: hand-written signature cards. uiMapID 1442 from the Classic table of
-- https://warcraft.wiki.gg/wiki/UiMapID; Kalimdor 1414. Not yet probed on Forever.
-- Sources in docs/research/05-northern-kalimdor.md. Icons from the validated list.
ns.Cards.registerZone({
  zoneMapID = 1442,
  continentMapID = 1414,
  cards = {
    { id = "1442:kaya_flathoof", kind = "npc", rarity = 5, name = "Kaya Flathoof", npcID = 11856, icon = "Ability_Hunter_Pet_TallStrider",
      flavor = "A centaur whose trek to Camp Aparaje needs a bodyguard." },
    { id = "1442:the_talon_den", kind = "place", rarity = 4, name = "The Talon Den", icon = "Ability_Hunter_Pet_Vulture", areaID = 468,
      flavor = "A micro-dungeon hidden among the zone's subareas." },
    { id = "1442:gerenzo_wrenchwhistle", kind = "npc", rarity = 4, name = "Gerenzo Wrenchwhistle", npcID = 4202, icon = "INV_Misc_Head_Gnome_01",
      flavor = "The leprous gnome leading the Venture Company team." },
    { id = "1442:braelyn_firehand", kind = "npc", rarity = 3, name = "Braelyn Firehand", npcID = 4198, icon = "Spell_Fire_Incinerate",
      flavor = "A recruiter rallying Sun Rock Retreat against the dryads." },
    { id = "1442:protect_kaya", kind = "quest", rarity = 3, name = "Protect Kaya", icon = "INV_Shield_06",
      flavor = "An escort quest, with all the stress that implies." },
    { id = "1442:sun_rock_retreat", kind = "place", rarity = 2, name = "Sun Rock Retreat", icon = "Ability_Hunter_Pet_Boar", areaID = 460,
      flavor = "A tauren camp clinging to the mountainside." },
    { id = "1442:windshear_crag", kind = "place", rarity = 2, name = "Windshear Crag", icon = "Trade_Mining", areaID = 461,
      flavor = "A goblin-infested crag with a mine in it." },
    { id = "1442:harpy", kind = "creature", rarity = 1, name = "Harpy", npcID = 4022, icon = "Ability_Hunter_Pet_Vulture",
      flavor = "A winged raider nesting on the crags." },
    { id = "1442:wyvern", kind = "creature", rarity = 1, name = "Wyvern", npcID = 4012, icon = "Ability_Hunter_Pet_Vulture",
      flavor = "A winged predator hunting above the peaks." },
  },
})
