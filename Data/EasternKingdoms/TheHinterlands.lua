local _, ns = ...

-- The Hinterlands. uiMapID 1425 from the Classic UiMapID table (warcraft.wiki.gg); not yet
-- probed on Forever. Candidates and sources in docs/research/03-tirisfal-to-plaguelands.md
-- Icons from the list validated in game.
ns.Cards.registerZone({
  zoneMapID = 1425,
  continentMapID = 1415,
  cards = {
    { id = "1425:falstad_wildhammer", kind = "npc", rarity = 5, name = "Falstad Wildhammer", icon = "INV_Misc_Head_Dwarf_01",
      flavor = "The Wildhammer leader who rules from Aerie Peak." },
    { id = "1425:vile_priestess_hexx", kind = "elite", rarity = 4, name = "Vile Priestess Hexx", icon = "Spell_Shadow_ShadowWordPain",
      flavor = "A Vilebranch priestess in the heart of the troll city." },
    { id = "1425:highlord_kruul", kind = "elite", rarity = 4, name = "Highlord Kruul", icon = "Spell_Shadow_SummonImp",
      flavor = "A demon lord whose name carries a lot of fear." },
    { id = "1425:jintha_alor", kind = "place", rarity = 3, name = "Jintha'Alor", icon = "INV_Misc_Head_Troll_01", areaID = 354,
      flavor = "A Vilebranch city where elite guards roam." },
    { id = "1425:primal_torntusk", kind = "npc", rarity = 3, name = "Primal Torntusk", icon = "INV_Misc_Head_Troll_01",
      flavor = "A Revantusk troll figure with a proud voice." },
    { id = "1425:aerie_peak", kind = "place", rarity = 2, name = "Aerie Peak", icon = "Ability_Druid_TravelForm", areaID = 348,
      flavor = "The Wildhammer home perched on a mountain." },
    { id = "1425:revantusk_village", kind = "place", rarity = 2, name = "Revantusk Village", icon = "INV_Misc_Horn_01", areaID = 3317,
      flavor = "A forest troll village in the green hills." },
    { id = "1425:wildkin", kind = "creature", rarity = 1, name = "Wildkin", icon = "Ability_Hunter_Pet_Owl",
      flavor = "An owl-like beast with an odd sense of balance." },
    { id = "1425:gryphon", kind = "creature", rarity = 1, name = "Gryphon", icon = "Ability_Hunter_Pet_Owl",
      flavor = "A highland native, famous as a Wildhammer mount." },
    { id = "1425:mountain_giant", kind = "creature", rarity = 1, name = "Mountain Giant", icon = "Spell_Nature_Earthquake",
      flavor = "A large giant that shakes the hills as it walks." },
  },
})
