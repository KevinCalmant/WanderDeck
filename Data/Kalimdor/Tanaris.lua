local _, ns = ...

-- Tanaris, with its dungeons folded in. uiMapID 1446 from the Classic UiMapID table
-- (warcraft.wiki.gg/wiki/UiMapID); Kalimdor 1414 from memory. Not yet probed on Forever.
-- Candidates and sources: docs/research/06-central-southern-kalimdor.md.
ns.Cards.registerZone({
  zoneMapID = 1446,
  continentMapID = 1414,
  cards = {
    { id = "1446:chief_ukorz_sandscalp", kind = "boss", rarity = 4, name = "Chief Ukorz Sandscalp", icon = "INV_Misc_Head_Troll_01",
      flavor = "The troll chief who waits at the end of the sunken city." },
    { id = "1446:gahzrilla", kind = "boss", rarity = 4, name = "Gahz'rilla", icon = "Ability_Hunter_Pet_Scorpid",
      flavor = "A boss you can face before or after the pyramid event." },
    { id = "1446:hydromancer_velratha", kind = "boss", rarity = 4, name = "Hydromancer Velratha", icon = "Spell_Frost_Frostbolt02",
      flavor = "A caster listed on the Zul'Farrak roster of bosses." },
    { id = "1446:zulfarrak", kind = "place", rarity = 3, name = "Zul'Farrak", icon = "INV_Misc_Head_Troll_01",
      flavor = "A sand troll city that doubles as a dungeon at Sandsorrow Watch." },
    { id = "1446:cyclok_the_mad", kind = "rare", rarity = 3, name = "Cyclok the Mad", icon = "Spell_Nature_LightningShield",
      flavor = "A rare of the dunes that you do not meet by chance." },
    { id = "1446:caverns_of_time", kind = "place", rarity = 3, name = "Caverns of Time", icon = "Spell_Holy_Resurrection",
      flavor = "A cave complex of the bronze dragonflight in the middle of the desert." },
    { id = "1446:gadgetzan", kind = "place", rarity = 2, name = "Gadgetzan", icon = "INV_Misc_Coin_01",
      flavor = "A neutral goblin city run by the Steamwheedle Cartel." },
    { id = "1446:steamwheedle_port", kind = "place", rarity = 2, name = "Steamwheedle Port", icon = "INV_Drink_05",
      flavor = "A goblin port settlement on the coast." },
    { id = "1446:scorpid", kind = "creature", rarity = 1, name = "Scorpid", icon = "Ability_Hunter_Pet_Scorpid",
      flavor = "An armored stinger of the dunes." },
    { id = "1446:hyena", kind = "creature", rarity = 1, name = "Hyena", icon = "Ability_Hunter_Pet_Wolf",
      flavor = "A scavenger that hunts in packs across the desert." },
  },
})
