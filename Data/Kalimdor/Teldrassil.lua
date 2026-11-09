local _, ns = ...

-- Teldrassil, with Darnassus folded in. uiMapID 1438 from the Classic UiMapID
-- table (warcraft.wiki.gg); Kalimdor 1414 from memory. Not yet probed on
-- Forever. Sources in docs/research/05-northern-kalimdor.md. Icons unverified:
-- /wd art.
ns.Cards.registerZone({
  zoneMapID = 1438,
  continentMapID = 1414,
  cards = {
    { id = "1438:nightsaber", kind = "creature", rarity = 1, name = "Nightsaber", npcID = 2042, icon = "Ability_Hunter_Pet_Cat",
      flavor = "Silent paws on the bark of the great tree." },
    { id = "1438:timberling", kind = "creature", rarity = 1, name = "Timberling", npcID = 2022, icon = "Spell_Nature_ProtectionformNature",
      flavor = "A sapling that decided to walk." },
    { id = "1438:webwood_spider", kind = "creature", rarity = 1, name = "Webwood Spider", npcID = 1986, icon = "Ability_Hunter_Pet_Spider",
      flavor = "It spins where the young elves train." },
    { id = "1438:grell", kind = "creature", rarity = 1, name = "Grell", npcID = 1988, icon = "Spell_Shadow_SummonImp",
      flavor = "Small, green, and up to no good." },
    { id = "1438:strigid_owl", kind = "creature", rarity = 1, name = "Strigid Owl", npcID = 1995, icon = "Ability_Hunter_Pet_Owl",
      flavor = "It watches from the branches, and it judges." },
    { id = "1438:shadowglen", kind = "place", rarity = 2, name = "Shadowglen", icon = "Spell_Nature_StarFall", areaID = 188,
      flavor = "A quiet glade where night elves first awaken." },
    { id = "1438:dolanaar", kind = "place", rarity = 2, name = "Dolanaar", icon = "Spell_Nature_Tranquility", areaID = 186,
      flavor = "Moonwells and patient druids under the canopy." },
    { id = "1438:gnarlpine_hold", kind = "place", rarity = 2, name = "Gnarlpine Hold", icon = "Spell_Shadow_Curse", areaID = 261,
      flavor = "The furbolgs here lost their way." },
    { id = "1438:darnassus", kind = "place", rarity = 2, name = "Darnassus", icon = "Spell_Nature_MoonGlow", areaID = 1657,
      flavor = "A capital of temples high in the branches." },
    { id = "1438:tallonkai_swiftroot", kind = "npc", rarity = 2, name = "Tallonkai Swiftroot", npcID = 3567, icon = "Ability_Druid_CatForm",
      flavor = "A druid with no patience for corruption." },
    { id = "1438:denalan", kind = "npc", rarity = 2, name = "Denalan", npcID = 2080, icon = "Spell_Nature_Rejuvenation",
      flavor = "He studies the sickness spreading through the roots." },
    { id = "1438:blackmoss_the_fetid", kind = "rare", rarity = 3, name = "Blackmoss the Fetid", npcID = 3535, icon = "Spell_Nature_Regenerate",
      flavor = "A rotting timberling by the quiet lake." },
    { id = "1438:fandral_staghelm", kind = "npc", rarity = 5, name = "Fandral Staghelm", npcID = 15382, icon = "Ability_Druid_TravelForm",
      flavor = "The Archdruid who planted the world tree." },
    { id = "1438:tyrande_whisperwind", kind = "lore", rarity = 5, name = "Tyrande Whisperwind", npcID = 7999, icon = "Spell_Holy_ElunesGrace",
      flavor = "High Priestess of Elune, guardian of her people." },
  },
})
