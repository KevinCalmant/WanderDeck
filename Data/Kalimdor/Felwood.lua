local _, ns = ...

-- Felwood: hand-written signature cards. uiMapID 1448 from the Classic table of
-- https://warcraft.wiki.gg/wiki/UiMapID; Kalimdor 1414. Not yet probed on Forever.
-- Sources in docs/research/05-northern-kalimdor.md. Icons from the validated list.
ns.Cards.registerZone({
  zoneMapID = 1448,
  continentMapID = 1414,
  cards = {
    { id = "1448:lord_banehollow", kind = "npc", rarity = 5, name = "Lord Banehollow", icon = "Spell_Shadow_RaiseDead",
      flavor = "A Shadow Council lord found deep in Shadow Hold." },
    { id = "1448:jaedenar", kind = "place", rarity = 4, name = "Jaedenar", icon = "Spell_Shadow_AnimateDead",
      flavor = "A demon-cult stronghold in the tainted woods." },
    { id = "1448:shadow_hold", kind = "place", rarity = 4, name = "Shadow Hold", icon = "Spell_Shadow_Curse",
      flavor = "The Shadow Council base where Lord Banehollow lurks." },
    { id = "1448:immolatus", kind = "rare", rarity = 3, name = "Immolatus", icon = "Spell_Fire_Volcano",
      flavor = "A fire rare that smolders in the blighted forest." },
    { id = "1448:dessecus", kind = "rare", rarity = 3, name = "Dessecus", icon = "Spell_Shadow_DeathScream",
      flavor = "A rare that haunts the blighted woods." },
    { id = "1448:timbermaw_hold", kind = "place", rarity = 2, name = "Timbermaw Hold", icon = "Ability_Hunter_Pet_Bear",
      flavor = "A furbolg refuge on the northern edge of the woods." },
    { id = "1448:emerald_sanctuary", kind = "place", rarity = 2, name = "Emerald Sanctuary", icon = "Spell_Nature_Rejuvenation",
      flavor = "A night elf refuge in the south." },
    { id = "1448:felbeast", kind = "creature", rarity = 1, name = "Felbeast", icon = "Ability_Hunter_Pet_Wolf",
      flavor = "A demon-twisted hound prowling the tainted woods." },
    { id = "1448:corrupted_furbolg", kind = "creature", rarity = 1, name = "Corrupted Furbolg", icon = "Ability_Hunter_Pet_Bear",
      flavor = "A furbolg warped by the fel taint." },
  },
})
