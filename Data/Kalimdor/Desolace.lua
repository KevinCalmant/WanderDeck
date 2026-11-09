local _, ns = ...

-- Desolace, with its dungeons folded in. uiMapID 1443 from the Classic UiMapID table
-- (warcraft.wiki.gg/wiki/UiMapID); Kalimdor 1414 from memory. Not yet probed on Forever.
-- Candidates and sources: docs/research/06-central-southern-kalimdor.md.
ns.Cards.registerZone({
  zoneMapID = 1443,
  continentMapID = 1414,
  cards = {
    { id = "1443:princess_theradras", kind = "boss", rarity = 4, name = "Princess Theradras", icon = "Spell_Nature_Earthquake",
      flavor = "The ruler of the valley, waiting at the bottom of her cavern." },
    { id = "1443:celebras_the_cursed", kind = "boss", rarity = 4, name = "Celebras the Cursed", icon = "Spell_Nature_ProtectionformNature",
      flavor = "A corrupted keeper who guards the Wicked Grotto." },
    { id = "1443:noxxion", kind = "boss", rarity = 4, name = "Noxxion", icon = "Spell_Nature_Regenerate",
      flavor = "The boss who festers in the Foulspore Cavern." },
    { id = "1443:maraudon", kind = "place", rarity = 3, name = "Maraudon", icon = "Spell_Nature_Earthquake",
      flavor = "A cave complex sacred to the centaur, deep in the Valley of Spears." },
    { id = "1443:rexxar", kind = "npc", rarity = 5, name = "Rexxar", icon = "Ability_Hunter_Pet_Bear",
      flavor = "A wandering champion who travels with his bear Misha." },
    { id = "1443:hissperak", kind = "rare", rarity = 3, name = "Hissperak", icon = "Ability_Hunter_Pet_Scorpid",
      flavor = "A rare of the dry valley that most adventurers only hear about." },
    { id = "1443:shadowprey_village", kind = "place", rarity = 2, name = "Shadowprey Village", icon = "INV_Misc_Head_Murloc_01",
      flavor = "A fishing village on the coast, always fighting off the murlocs." },
    { id = "1443:kodo_graveyard", kind = "place", rarity = 2, name = "Kodo Graveyard", icon = "INV_Misc_Bone_HumanSkull_01",
      flavor = "A bone-strewn resting ground where restless spirits linger." },
    { id = "1443:satyr", kind = "creature", rarity = 1, name = "Satyr", icon = "Spell_Shadow_SummonImp",
      flavor = "A demonic raider from the camps near Mannoroc and Sargeron." },
    { id = "1443:centaur", kind = "creature", rarity = 1, name = "Centaur", icon = "INV_Misc_Horn_01",
      flavor = "Kolkar and Magram warriors who fight each other across the valleys." },
  },
})
