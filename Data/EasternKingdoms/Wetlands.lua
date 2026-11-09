local _, ns = ...

-- Wetlands. uiMapID 1437 from the Classic UiMapID table (warcraft.wiki.gg); not yet
-- probed on Forever. Candidates and sources in docs/research/02-dun-morogh-to-burning-steppes.md
-- Icons from the list validated in game.
ns.Cards.registerZone({
  zoneMapID = 1437,
  continentMapID = 1415,
  cards = {
    { id = "1437:grim_batol", kind = "place", rarity = 5, name = "Grim Batol", icon = "Spell_Fire_Volcano",
      flavor = "A dragon stronghold that no sane traveler approaches." },
    { id = "1437:dragonmaw_gates", kind = "place", rarity = 4, name = "Dragonmaw Gates", icon = "INV_Misc_Head_Troll_01",
      flavor = "Orc banners rise over a gate held by the Dragonmaw." },
    { id = "1437:dragonmaw_battlemaster", kind = "rare", rarity = 4, name = "Dragonmaw Battlemaster", icon = "Ability_Warrior_BattleShout",
      flavor = "A veteran orc fighter who leads from the front." },
    { id = "1437:captain_stoutfist", kind = "npc", rarity = 5, name = "Captain Stoutfist", icon = "INV_Shield_06",
      flavor = "An Ironforge officer holding the line against the Dragonmaw." },
    { id = "1437:leech_widow", kind = "rare", rarity = 3, name = "Leech Widow", icon = "Ability_Hunter_Pet_Spider",
      flavor = "A swamp spider that drains more than it should." },
    { id = "1437:menethil_harbor", kind = "place", rarity = 2, name = "Menethil Harbor", icon = "INV_Drink_05",
      flavor = "The port town where ships arrive from across the sea." },
    { id = "1437:rhag_garmason", kind = "npc", rarity = 4, name = "Rhag Garmason", icon = "INV_Misc_Head_Dwarf_01",
      flavor = "A dwarf from Dun Modr who wants his town back." },
    { id = "1437:mottled_raptor", kind = "creature", rarity = 1, name = "Mottled Raptor", icon = "Ability_Hunter_Pet_TallStrider",
      flavor = "Quick on its feet and quicker to attack." },
    { id = "1437:bluegill_warrior", kind = "creature", rarity = 1, name = "Bluegill Warrior", icon = "INV_Misc_Head_Murloc_01",
      flavor = "A murloc who takes the fight seriously." },
    { id = "1437:fen_creeper", kind = "creature", rarity = 1, name = "Fen Creeper", icon = "Spell_Nature_ProtectionformNature",
      flavor = "Something slow and soggy crawls out of the fen." },
  },
})
