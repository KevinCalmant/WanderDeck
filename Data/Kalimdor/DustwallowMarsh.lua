local _, ns = ...

-- Dustwallow Marsh, with its dungeons folded in. uiMapID 1445 from the Classic UiMapID table
-- (warcraft.wiki.gg/wiki/UiMapID); Kalimdor 1414 from memory. Not yet probed on Forever.
-- Candidates and sources: docs/research/06-central-southern-kalimdor.md.
ns.Cards.registerZone({
  zoneMapID = 1445,
  continentMapID = 1414,
  cards = {
    { id = "1445:jaina_proudmoore", kind = "npc", rarity = 5, name = "Jaina Proudmoore", icon = "Spell_Frost_FrostArmor02",
      flavor = "The lady of Theramore, ruling an Alliance port in the middle of Horde land." },
    { id = "1445:alcaz_island", kind = "place", rarity = 4, name = "Alcaz Island", icon = "Spell_Shadow_Twilight",
      flavor = "A small island off the coast, dangerous enough to count as a dungeon." },
    { id = "1445:drogoth_the_roamer", kind = "rare", rarity = 4, name = "Drogoth the Roamer", icon = "Spell_Shadow_DeathCoil",
      flavor = "A rare that wanders the marsh and rarely stays in one place." },
    { id = "1445:overlord_mokmorokk", kind = "npc", rarity = 4, name = "Overlord Mok'Morokk", icon = "INV_Misc_Head_Troll_01",
      flavor = "The Brackenwall chief, who wants help against the black dragons." },
    { id = "1445:darkmist_widow", kind = "rare", rarity = 3, name = "Darkmist Widow", icon = "Ability_Hunter_Pet_Spider",
      flavor = "A rare spider that lurks in the marsh mist." },
    { id = "1445:lord_angler", kind = "rare", rarity = 3, name = "Lord Angler", icon = "Ability_Hunter_Pet_Boar",
      flavor = "A rare catch of the marsh, whose name speaks of fishing." },
    { id = "1445:theramore_isle", kind = "place", rarity = 2, name = "Theramore Isle", icon = "INV_BannerPVP_01",
      flavor = "An Alliance port city standing in Horde territory." },
    { id = "1445:brackenwall_village", kind = "place", rarity = 2, name = "Brackenwall Village", icon = "Ability_Warrior_WarCry",
      flavor = "An orc village that hands out the Brood of Onyxia quest." },
    { id = "1445:crocolisk", kind = "creature", rarity = 1, name = "Crocolisk", icon = "Ability_Hunter_Pet_Boar",
      flavor = "A marsh reptile that lies in wait in the shallows." },
  },
})
