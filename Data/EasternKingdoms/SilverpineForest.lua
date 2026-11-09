local _, ns = ...

-- Silverpine Forest. uiMapID 1421 from the Classic UiMapID table (warcraft.wiki.gg); not yet
-- probed on Forever. Candidates and sources in docs/research/03-tirisfal-to-plaguelands.md
-- Icons from the list validated in game.
ns.Cards.registerZone({
  zoneMapID = 1421,
  continentMapID = 1415,
  cards = {
    { id = "1421:archmage_arugal", kind = "boss", rarity = 5, name = "Archmage Arugal", npcID = 4275, icon = "Spell_Shadow_SummonImp",
      flavor = "The wizard whose summoning turned the forest into a hunting ground." },
    { id = "1421:shadowfang_keep", kind = "place", rarity = 4, name = "Shadowfang Keep", icon = "Spell_Shadow_Curse", loadScreen = "LoadScreenShadowfang", areaID = 236,
      flavor = "Arugal's fortress, where howls echo down every hall." },
    { id = "1421:gorefang", kind = "rare", rarity = 4, name = "Gorefang", npcID = 12431, icon = "Ability_Hunter_Pet_Wolf",
      flavor = "A rare beast that stalks the forest paths at night." },
    { id = "1421:high_executor_hadrec", kind = "npc", rarity = 4, name = "High Executor Hadrec", npcID = 1952, icon = "Spell_Shadow_DeathScream",
      flavor = "The Forsaken leader who runs things at the Sepulcher." },
    { id = "1421:apothecary_renferrel", kind = "npc", rarity = 3, name = "Apothecary Renferrel", npcID = 1937, icon = "INV_Drink_05",
      flavor = "A Forsaken alchemist always short of a certain ingredient." },
    { id = "1421:the_sepulcher", kind = "place", rarity = 2, name = "The Sepulcher", icon = "Spell_Shadow_GatherShadows", areaID = 228,
      flavor = "A Forsaken outpost and the hub of the forest." },
    { id = "1421:pyrewood_village", kind = "place", rarity = 2, name = "Pyrewood Village", icon = "Spell_Shadow_Twilight", areaID = 204,
      flavor = "A village that changes after dusk." },
    { id = "1421:worgen", kind = "creature", rarity = 1, name = "Worgen", npcID = 1769, icon = "Ability_Druid_CatForm",
      flavor = "Cursed wolf-men who prowl between the pines." },
    { id = "1421:worg", kind = "creature", rarity = 1, name = "Worg", npcID = 1765, icon = "Ability_Hunter_Pet_Wolf",
      flavor = "A large wild wolf with a big appetite." },
  },
})
