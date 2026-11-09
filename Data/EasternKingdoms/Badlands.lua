local _, ns = ...

-- Badlands. uiMapID 1418 from the Classic UiMapID table (warcraft.wiki.gg); not yet
-- probed on Forever. Candidates and sources in docs/research/02-dun-morogh-to-burning-steppes.md
-- Icons from the list validated in game.
ns.Cards.registerZone({
  zoneMapID = 1418,
  continentMapID = 1415,
  cards = {
    { id = "1418:archaedas", kind = "boss", rarity = 5, name = "Archaedas", npcID = 2748, icon = "Spell_Nature_Earthquake",
      flavor = "An ancient stone guardian that wakes only when disturbed." },
    { id = "1418:uldaman", kind = "place", rarity = 4, name = "Uldaman", icon = "INV_Misc_Bone_HumanSkull_01", areaID = 1517,
      flavor = "A buried vault whose last guardian waits in the depths." },
    { id = "1418:barnabus", kind = "rare", rarity = 4, name = "Barnabus", npcID = 2753, icon = "Spell_Nature_Earthquake",
      flavor = "A big stone brute that shakes the ground as it walks." },
    { id = "1418:zaricotl", kind = "rare", rarity = 3, name = "Zaricotl", npcID = 2931, icon = "INV_Misc_Bone_HumanSkull_01",
      flavor = "A rare wanderer of the Badlands, hard to find and harder to forget." },
    { id = "1418:broken_tooth", kind = "rare", rarity = 3, name = "Broken Tooth", npcID = 2850, icon = "Ability_Hunter_Pet_Wolf",
      flavor = "One chipped fang has not made it any less dangerous." },
    { id = "1418:elder_crag_coyote", kind = "creature", rarity = 2, name = "Elder Crag Coyote", npcID = 2729, icon = "Ability_Hunter_Pet_Wolf",
      flavor = "Older, meaner and wiser than its younger pack mates." },
    { id = "1418:dustbelcher_lord", kind = "creature", rarity = 2, name = "Dustbelcher Lord", npcID = 2719, icon = "INV_Misc_Head_Gnoll_01",
      flavor = "An ogre chief that rules over a dusty crowd." },
    { id = "1418:rock_elemental", kind = "creature", rarity = 1, name = "Rock Elemental", npcID = 92, icon = "Spell_Nature_Earthquake",
      flavor = "A walking pile of rubble with a bad temper." },
    { id = "1418:buzzard", kind = "creature", rarity = 1, name = "Buzzard", npcID = 2830, icon = "Ability_Hunter_Pet_Vulture",
      flavor = "It circles overhead and waits for the weary." },
    { id = "1418:crag_coyote", kind = "creature", rarity = 1, name = "Crag Coyote", npcID = 2727, icon = "Ability_Hunter_Pet_Wolf",
      flavor = "A scavenger that is never far from a fresh trail." },
  },
})
